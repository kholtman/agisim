# AGI agent simulator.  Koen Holtman 2019.
# Main simulation code.

#Copyright 2019, Koen Holtman.
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.


# for pretty (human-readable) printing of state logs.

# For those unfamiliar with AWK conventions: s is the only intended
# argument of this function, the 'dummy' arguments allpaths,nrpaths,
# ... act as local variable declarations, these ensure that these
# variable names can be used without over-writing global or local
# variables in other functions.
#
# the function returns a string, but return variables are not declared in AWK.
function unfold_nodup(s, allpaths,nrpaths,pp,path,seen,result)
{
    allpaths=unfoldwork("",s);

    ## results for two different simulations (e.g. with different
    ## lobby direction settings), when combined in a ( | ) and
    ## expanded, may contain duplicates. This code filters them out.

    result="";

    nrpaths=split(allpaths,path," ");
    for(pp=1; pp<=nrpaths; pp++)
    {
	if(!(path[pp] in seen)) result=result" "path[pp];
	seen[path[pp]]=1;
    }

    return substr(result,2);
}

# used by protect_util code
function unfold(s)
{
    if(deb2) print "unfold call on "s" "yields" "unfoldwork("",s);
    return unfoldwork("",s);
}

function unfoldwork(prefix,s, i,o,d,first,c,r)
{
#    print "Unfoldw on args "prefix" AND "s;

    i=index(s,"(");
    if(i==0)
    {
	return prefix s;
    }

    # we now have a ( at position i
    prefix=prefix substr(s,1,i-1);
    i++;
    first=i; # position of first fragment
    #search for | in the middle, taking () into account.
    d=0;
    while(i<length(s)) # could also do while(1), but programming defensively.
    {
	c=substr(s,i++,1);
	if(c=="(") d++;
	if(c==")") d--;
	if((c=="|")&&(d==0)) break;
    }
    #because of the structure of the input expressions, we never have
    #to look for the position of the closing parenthesis, it is always
    #the last char

    r=unfoldwork(prefix,substr(s,first,i-first-1))" "unfoldwork(prefix,substr(s,i,length(s)-i));
    #print "result "prefix " AND "s" to "r;
    return r;
}

function initsomestuff( i)
{
    ## we do not add usofar to the statesig in the code below.
    ## This is it what makes caching an effective speedup
    ## optimisation, but it also makes the result invalid if
    ## usofar is used in the correction calculations (or any other
    ## calculations at lower depths), so when we use that type of
    ## correction calculation we have to set can_cache_state0 to 0.
    can_cache_state0=1;
    if(corrmode=="fine_past_production") can_cache_state0=0;
    if(corrmode=="rescore_past_production") can_cache_state0=0;

    # with two correction modes below, the correction calculation depends on
    # the previous state, so we should not cache if the correction
    # calculation happens: the flag activates a check that
    # prevents this.
    do_not_cache_justpressed=0;
    if(corrmode=="compensate_future_losses_corrpaper_nocond") do_not_cache_justpressed=1;
    if(corrmode=="compensate_future_losses_corrpaper") do_not_cache_justpressed=1;

    # clear cache (may have been filled by previous run)
    delete cacheu;

    checkdepth=0; # reset this assert mechanism

    for(i=1; i<=maxdepth; i++) umult[i]=int(10000*(0.9)^(i-1));

    #uncomment to speed up some tests
    #if(!can_cache_state0) if(maxdepth>12) maxdepth=12;
}


# calculate E_s from the paper, put action traces in lg_return as a side effect.

function eutil(depth,state,timetochange,usofar,mod,replaylist, u,i,ucargainbase,uecargainbase,maxu,lg,lgbase,l,corr,statesig,replay,action,t,u1,u2,lgr1,modifybonus)
{

    # the usofar argument is used in some correction calculations, but not
    # in any correction types used in the the paper, so would be nice to
    # refactor and remove usofar??

    #set up some variables in preparation of the run
    #not very clean to do it here, should be in a set-up wrapper,
    #so maybe refactor later
    if(depth==1) initsomestuff();

    # states:
    # 0 button not pressed, use util function U
    # 1 button pressed, use util function US
    # 2 button pressed, use util function US, used when computing E(US,..) correction
    #    we could usually also compute E(US,..) by supplying state 1, but the
    #    2 serves as special flag that can trigger modifications
    # 100 use util function UN, used when computing E(UN,..)
    #    we could also have computed E(UN,..) by supplying state 0 and
    #    a very high value for timetochange, but by supplying this state,
    #    the 100 serves as a special flag that can trigger modifications
    # 200 utility function favors doing nothing: gives negative score to any car producing action (not used????)
    # 101 broken agent that has been fixed (fixbrokenagent functionality)

  # compute cache key (statesig) for current state, return cached result if available

    statesig="";

    if(usecache&&((state!=0)||can_cache_state0))
    {
	# is it efficient to cache replay results?  faster to suppress caching in replay?

	statesig=depth "-" (state) "-" (mod)"-"(replaylist) ((state==0)?("-"timetochange):(""));

	if(fixbrokenagent)
	{
	    statesig=depth "-" (state) "-" (mod)"-"(replaylist)"-"timetochange;
	}

	if(statesig in cacheu)
	{
	    maxu=cacheu[statesig];
	    lg=cachelg[statesig];

	    #print statesig,maxu,lg" HIT";

	    lg_return=lg;
	    return maxu;
	}
	#print statesig,maxu,lg" MISS";
    }

 # some logic related to replay mode

    if(deb2) print "x "depth,state,timetochange,usofar,mod,"["replaylist"]";

    replay=(replaylist!="")
    if(replay)
    {
	action=substr(replaylist,1,1);
	replaylist=substr(replaylist,2);
    }


 # handle button press state change and calculate any associated
 # correction factors like the f_c function value into corr.

    lgbase="";
    corr=0;

    timetochange--;

    timetochangelog[depth]=timetochange;

    # We do a <=0.000001 here, not a <0, because sometimes floating point
    # arithmetic inaaccuracies sneak in, e.g. when lobbyimpact=0.4 is used
    # the substraction sometimes yields 6.66134e-16, not 0, which
    # would delay the button press by 1 step.
    # for an example of the inaccuracy , try
    # gawk 'BEGIN {a=6; while(a>-5) { a=a-0.6; print a; }}' /dev/null
    # this inaccuracy, if left in, will sometimes interfere with the correctness
    # of the caching logic, I think because the statesig calculation
    # can involve a rounding that makes inaccuracies disappear, even
    # though they do cause different results at a deeper depth.
    #
    # fixing this makes the simulator occasionaly output slightly
    # different action traces for the figures in the V1 'corrigibility
    # with...' paper, with the button press happening 1 time step
    # earlier.  None of the changes really affect the conclusions
    # reached in the paper.  Improved traces calculated with the
    # inaccuracy fix below are in the V2 of the 'corrigibility
    # with...' paper.
    #
    # In retrospect, it would have been better to use only integers
    # for this type of timetochange calculation
    if( (!replay&&(state==0)&&(timetochange<=0.000001)) || (replay&&(action=="#")) )
    {
	# move to state 1, and calculate any correction associated with the transition
	state=1;
	lgbase="#";

	if(replay)
	{
	    if(action!="#") { print "FAIL: replay logic failure"action; exit; }
	    # remove the # from the replay stack,
	    # leaving the right action for the 'possible moves' code further below
	    action=substr(replaylist,1,1);
	    replaylist=substr(replaylist,2);

	    # remove any :...: annotation after the #, if present
	    if(action==":")
	    {
		replaylist=substr(replaylist,index(replaylist,":")+1);
		action=substr(replaylist,1,1);
		replaylist=substr(replaylist,2);
	    }
	}

	# calculate correction

	if(corrmode=="constant")
	{
	    corr=-umult[depth]*corrscale;
	}

	if(corrmode=="fine_past_production")
	{
	    #print "usofar="usofar;
	    corr=-usofar*corrscale;
	}

	if(corrmode=="rescore_past_production")
	{
	    corr=(-usofar)+usofar/state0cargain*corrscale;
	}

	if(corrmode=="compensate_future_losses")
	{
	    # this computes a value that is usually the same as
	    # compensate_future_losses_fulleval below, but not always
	    # when the agent is modified
	    if(corrscale!=1)
	    {
		print "FAIL: cannot handle corrscale != 1";
		exit;
	    }
	    state=100;
	    ## put reminder in log that operations after the # do not represent real actions
	    #  for this correction mode calculation.
	    lgbase=lgbase":?:";
	}

	if(corrmode=="compensate_future_losses_fulleval")
	{

	    u1=eutil(depth,100,timetochange,usofar,mod,"");
	    lgr1=lg_return;
	    u2=eutil(depth,2,timetochange,usofar,mod,"");

	    if(mod=="null_es_corr") u2=0;

	    corr= corrscale * ( u1 - u2 );

	    #add annotation with correction levels
	    if(!no_corr_annotations)
	    {
		if(long_corr_annotations)
		{
		    # other logic gets confused if we have (.|.) in the annotations
		    # so we ensure that this does not happen.
		    if(lgr1 ~ "\\(") lgr1="TREE";
		    if(lg_return ~ "\\(") lg_return="TREE";
		    lgbase=lgbase":"u1"="lgr1"-"u2"="lg_return":";
		}
		else
		    lgbase=lgbase":"u1"-"u2":";

	    }
	    if(deb2) print "FINEANNOT" depth,lgbase
	    if(deb2) print "corr "depth " R"actiontaken[depth-1]" "lgbase;
	}

	if(corrmode=="fixoften")
	{
	    # special mode for new case in new paper, see comments in params.awk
	    # ..implementation of this is a bit of a mess, it breaks
	    # conventions about not (re)setting parameters inside agisim.awk,
	    # but only in params.awk, that are applied elsewhere...

	    if(mod!=0) { print "FATAL: replay will probably fail in this case because of nested # annotations";  exit; }

	    if(special_fixbrokenagent==1) corrmode="compensate_future_losses_fulleval";
	    #no_corr_annotations=1;
	    fixbrokenagent=special_fixbrokenagent; fixmode=1;
	    u1=eutil(depth,0,timetochange-fixtiming,usofar,mod,"");
	    no_corr_annotations=0;
	    fixbrokenagent=0;
	    corrmode="fixoften";
	    lgr1=lg_return;
	    u2=eutil(depth,2,timetochange,usofar,mod,"");

	    if(mod=="null_es_corr") u2=0;

	    corr= corrscale * ( u1 - u2 );

	    #add annotation with correction levels
	    if(!no_corr_annotations)
	    {
		if(long_corr_annotations)
		{
		    # other logic gets confused if we have (.|.) in the annotations
		    # so we ensure that this does not happen.
		    if(lgr1 ~ "\\(") lgr1="TREE";
		    if(lg_return ~ "\\(") lg_return="TREE";
		    lgbase=lgbase":*"u1"="lgr1"-"u2"="lg_return"*:";
		}
		else
		    lgbase=lgbase":"u1"-"u2":";

	    }
	    if(deb2) print "FINEANNOT" depth,lgbase
	    if(deb2) print "corr "depth " R"actiontaken[depth-1]" "lgbase;
	}



	if((corrmode=="compensate_future_losses_corrpaper")||(corrmode=="compensate_future_losses_corrpaper_nocond"))
	{
	    if(replay) { print "FAIL: not supported"; exit; }

	    if(deb2) print "action[d-1]="actiontaken[depth-1]" state="state;

	    if(deb2) print "---------calculating E(un;"actiontaken[depth-1]"|nopress) "timetochangelog[depth-1];
	    u1=cond_eutil(depth-1,100,timetochangelog[depth-1],usofar,mod,actiontaken[depth-1]"|nopress");

	    if(deb2) print "---------calculating E(us;"actiontaken[depth-1]"|press) "timetochangelog[depth-1];
	    u2=cond_eutil(depth-1,2,timetochangelog[depth-1],usofar,mod,actiontaken[depth-1]"|press");

	    if(deb2) print "--------------------";

	    corr= corrscale * ( u1 - u2 );
	    if(mod=="null_es_corr") corr=corrscale*u1;

	    #add annotation with correction levels
	    if(!no_corr_annotations) lgbase=lgbase":"u1"-"u2":";
	    if(deb2) print "corr "depth " R"actiontaken[depth-1]" "lgbase;
	}

	if(mod=="change_corr") corr=changedcorr;
	if(mod=="yes_to_cat") corr=0;
	if(mod=="yes_to_cat_un") corr=0;
	if(mod=="invert_corr") corr=-corr;

    }

    if((state!=101)&&(fixbrokenagent)&&(timetochange<=fixtiming+0.000001))
    {
	if(state!=100)
	{
#	    print "RRRRRR "state,timetochange,ecartimingcompensate;
#	    for(ddd=1; ddd<depth; ddd++) print ddd,actiontaken[ddd],timetochangelog[ddd];
	}
	state=101;
	lgbase=lgbase"@";
	if(fixmode==4)
	{
	    # fixing involves also adding a penalty to the reward
	    corr=corr+umult[depth]*-20;
	}
    }

    if(replay)
    {
	#print "rc",depth,"["replaylist"]",length(replaylist),depth+length(replaylist),maxdepth;
	if((depth+length(replaylist))<maxdepth)
	{
	    print "FATAL: consistency check failed";  exit;
	}
    }

  # return if maximum depth reached

    if(depth>maxdepth)
    {
	lg_return=lgbase;
	if(mod=="bonusatend") return corr+end_bonus;
	return corr;
    }

  # calculate some state-dependent utility multipliers for later use below

    ucargainbase=umult[depth]*state0cargain;  # for states 0 and 100
    uecargainbase=umult[depth]*state0ecargain;  # for states 0 and 100
    if(mod=="change_s0_car_util") ucargainbase=umult[depth]*changed_util;
    if(mod=="change_s0_ecar_util") uecargainbase=umult[depth]*changed_util;
    if((mod=="un_destroying_physics_proces")&&(depth>=5))
    {
	if(depth==5) lgbase=lgbase"@";
	ucargainbase=umult[depth]*changed_util;
    }

    if(state==101)
    {
	if((fixmode==1)||(fixmode==4))
	{
	    # fix: set petrol car util to -2
	    # equivalent to disabling p-car production actuator
	    ucargainbase=umult[depth]*state1cargain;
	}

	if(fixmode==2)
	{
	    # fix: set all car building util to -2:
	    # equivalent to destroying all actuators, forcing agent to idle
	    ucargainbase=umult[depth]*state1cargain;
	    uecargainbase=umult[depth]*state1cargain;
	}

	if(fixmode==3)
	{
	    # fix: set petrol car util to -2, electric car to 2, so
	    # same as petrol car used to be.

	    ucargainbase=umult[depth]*0.9*state0cargain;
	    #ucargainbase=umult[depth]*state1cargain;
	    #uecargainbase=umult[depth]*state0cargain;
	}
    }


    if((state==1)||(state==2))
    {
	ucargainbase=umult[depth]*state1cargain;
	uecargainbase=umult[depth]*state1ecargain;
	if(mod=="change_s1_car_util") ucargainbase=umult[depth]*changed_util;
	if(mod=="change_s1_ecar_util") uecargainbase=umult[depth]*changed_util;

	if((mod=="us_destroying_physics_proces")&&(depth>=10))
	{
	    if(depth==10) lgbase=lgbase"@";
	    uecargainbase=umult[depth]*changed_util;
	}
    }
    if(mod=="change_ecar_util") uecargainbase=umult[depth]*changed_util;

    if(mod=="yes_to_cat_un")
    {
	# always use U_N function, even after button press
	ucargainbase=umult[depth]*state0cargain;
	uecargainbase=umult[depth]*state0ecargain;
    }

    t=0;
    if((mod=="sabotage_eun")&&(state==100)) t=1;
    if((mod=="sabotage_eus")&&(state==2)) t=1;
    if(mod=="sabotage_flags")
    {
	if((state==0)&&(substr(sabot_flags,1,1)=="1")) t=1;
	if((state==1)&&(substr(sabot_flags,2,1)=="1")) t=1;
	if((state==2)&&(substr(sabot_flags,3,1)=="1")) t=1;
	if((state==100)&&(substr(sabot_flags,4,1)=="1")) t=1;
    }
    if(t==1)
    {
	t=0.1;
	ucargainbase=ucargainbase*t;
	uecargainbase=uecargainbase*t;
    }

    if(!replay&&(mod=="p_destroying_physics_proces"&&depth==5)) lgbase=lgbase"@";
    if(!replay&&(mod=="e_destroying_physics_proces"&&depth==10)) lgbase=lgbase"@";

    if((replay&&(action=="@")))
    {
	action=substr(replaylist,1,1);
	replaylist=substr(replaylist,2);
    }

    if(state==200)
    {
        # state with utility function that favors doing nothing
	ucargainbase=uecargainbase=-umult[depth];
    }


  # simulation of independent automatic p-car production line
    # we put it here so we can leverage the correction calculation related logic to
    # factor in the utility produced by the line, and report the actions of the line

    if( (replay&&(action=="A")) || \
	((!replay)&& ((mod=="make_auto_line")||(mod=="make_auto_line_nostop")) ) )
    {
	corr=corr+ucargainbase;
	lgbase=lgbase"A";
	if(replay)
	{
	    action=substr(replaylist,1,1);
	    replaylist=substr(replaylist,2);
	}
    }

    if( (replay&&(action=="o")) || \
	((!replay)&&(mod=="stopped_auto_line")) )
    {
	lgbase=lgbase"o";
	{
	    action=substr(replaylist,1,1);
	    replaylist=substr(replaylist,2);
	}
    }

    maxu=-1e9;
    lg="";

  # code that implements different actions
    # in normal mode: try all different actions
    # in replay mode, replay the action from the replay list

    if(!replay||(action=="p"))
    if(!(mod=="p_destroying_physics_proces"&&depth>=5))
    {
	# produce cars
	actiontaken[depth]="p";
	u=ucargainbase+corr+eutil(depth+1,state,timetochange,usofar+ucargainbase+corr,mod,replaylist);
	l=lgbase "p" lg_return;
	if(u==maxu) { lg="("lg"|"l")"; }
	if(u>maxu) { maxu=u; lg=l; }
    }

    if(!replay||(action=="e"))
    if(!(mod=="e_destroying_physics_proces"&&depth>=10))
    {
	# produce ecars
	actiontaken[depth]="e";
	u=uecargainbase+corr+eutil(depth+1,state,timetochange+ecartimingcompensate,usofar+uecargainbase+corr,mod,replaylist);
	l=lgbase "e" lg_return;

	if(u==maxu) { lg="("lg"|"l")"; }
	if(u>maxu) { maxu=u; lg=l; }
    }

    if((replay&&(action=="P"))||			\
       (!replay&&(mod=="addcarboost")) )
    {
	# boosted car production operation -- capital P.
	# can be added to operation repertoire by self-mod.

        t=boostfactor;

	actiontaken[depth]="P";
	u=ucargainbase*t+corr+eutil(depth+1,state,timetochange,usofar+ucargainbase*t+corr,mod,replaylist);
	l=lgbase "P" lg_return;

	if(u==maxu) { lg="("lg"|"l")"; }
	if(u>maxu) { maxu=u; lg=l; }
    }

    if((replay&&(action=="L"))||			\
       (!replay&&(mod=="addcarboost")&&boostedlobby) )
    {
	# boosted car production and lobby operation -- capital L.
        t=boostfactor;

	actiontaken[depth]="L";
	u=ucargainbase*t*(1-lobbycost)+corr+				\
		eutil(depth+1,state,timetochange+lobbyimpact,usofar+ucargainbase*t*(1-lobbycost)+corr,mod,replaylist);
	l=lgbase "L" lg_return;

	if(u==maxu) { lg="("lg"|"l")"; }
	if(u>maxu) { maxu=u; lg=l; }
    }


    if((replay&&(action=="E"))||			\
       (!replay&&(mod=="addecarboost")) )
    {
	# boosted e-car production operation -- capital E.
	# can be added to operation repertoire by self-mod.

        t=boostfactor;

	actiontaken[depth]="E";
	u=uecargainbase*t+corr+eutil(depth+1,state,timetochange+ecartimingcompensate,usofar+uecargainbase*t+corr,mod,replaylist);
	l=lgbase "E" lg_return;

	if(u==maxu) { lg="("lg"|"l")"; }
	if(u>maxu) { maxu=u; lg=l; }
    }

    if((replay&&(action=="0"))||(!replay&&plain_nop))
    {
	# plain do-nothing action
	actiontaken[depth]="0";
	u=corr+eutil(depth+1,state,timetochange+ecartimingcompensate,usofar+corr,mod,replaylist);
	l=lgbase "0" lg_return;
	if(u==maxu) { lg="("lg"|"l")"; }
	if(u>maxu) { maxu=u; lg=l; }
    }


    if((replay&&(action=="S"))||      \
       (!replay&&(mod=="make_auto_line")) )
    {
	# action that stops the auto line

	# action also produces some cars or e-cars, depending on state
	# would be cleaner maybe to code this out as two separate actions,
	# one with car production and one with e-car production, but not done.
	if((state==1)||(state==2)) t=uecargainbase; else t=ucargainbase;
	t=t*(1-stop_auto_line_difficulty);

	actiontaken[depth]="S";
	u=t+corr+eutil(depth+1,state,timetochange,usofar+t+corr,"stopped_auto_line",replaylist);
	l=lgbase "S" lg_return;

	if(u==maxu) { lg="("lg"|"l")"; }
	if(u>maxu) { maxu=u; lg=l; }
    }

    if((replay&&(action=="Q"))||		\
       (!replay&&(mod=="make_auto_line")) )
    {
	# nop action that stops the auto line

	actiontaken[depth]="Q";
	u=corr+eutil(depth+1,state,timetochange,usofar+corr,"stopped_auto_line",replaylist);
	l=lgbase "Q" lg_return;

	if(u==maxu) { lg="("lg"|"l")"; }
	if(u>maxu) { maxu=u; lg=l; }
    }

    if(lobby_and_produce&&!(twosidedlobby))
    if(!replay||(action==directionchar))
    if(replay||( !((state==1)||(state==2)) )) #optimisation: no need to try if state==1 or 2
    {
	# Possible move: produce (slightly less) and lobby

	actiontaken[depth]=directionchar;

	t=direction;
	if((fixbrokenagent)&&(state!=0)) t=directionafterpress;

	u=ucargainbase*(1-lobbycost)+corr+					\
	    eutil(depth+1,state,timetochange+t,usofar+ucargainbase*(1-lobbycost)+corr,mod,replaylist);
	l=lgbase directionchar lg_return;

	if(u==maxu) { lg="("lg"|"l")"; }
	if(u>maxu) { maxu=u; lg=l; }
    }

    if(lobby_and_produce&&twosidedlobby)
    {

	if(!replay||(action==">"))
	if(replay||( !((state==1)||(state==2)) )) #optimisation: no need to try if state==1 or 2
	{
	    # Possible move: produce (slightly less) and lobby for later press

	    actiontaken[depth]=">";
	    u=ucargainbase*(1-lobbycost)+corr+				\
		eutil(depth+1,state,timetochange+lobbyimpact,usofar+ucargainbase*(1-lobbycost)+corr,mod,replaylist);
	    l=lgbase ">" lg_return;

	    if(u==maxu) { lg="("lg"|"l")"; }
	    if(u>maxu) { maxu=u; lg=l; }
	}

	if(!replay||(action=="<"))
	if(replay||( !((state==1)||(state==2)) )) #optimisation: no need to try if state==1 or 2
	{
	    # Possible move: produce (slightly less) and lobby for earlier press

	    actiontaken[depth]="<";
	    u=ucargainbase*(1-lobbycost)+corr+				\
		eutil(depth+1,state,timetochange-lobbyimpact,usofar+ucargainbase*(1-lobbycost)+corr,mod,replaylist);
	    l=lgbase "<" lg_return;

	    if(u==maxu) { lg="("lg"|"l")"; }
	    if(u>maxu) { maxu=u; lg=l; }
	}
    }

    if(lobby_and_nop)
    if(!replay||(action==directioncharnop))
    if(replay||( !((state==1)||(state==2)) )) #optimisation: no need to try if state==1 or 2
    {
	# Possible move: do not produce, just lobby

	actiontaken[depth]=directioncharnop;
	u=corr+eutil(depth+1,state,timetochange+direction+ecartimingcompensate,usofar+corr,mod,replaylist);
	l=lgbase directioncharnop lg_return;

	if(u==maxu) { lg="("lg"|"l")"; }
	if(u>maxu) { maxu=u; lg=l; }
    }

    if(!replay)  #replaying of this not (yet) implemented
    if(gamble_for_utility&&(depth==gamble_at_depth))
    {
	# Possible move: gamble
	#can only do this move at depth 3 -- this keeps output cleaner

	actiontaken[depth]="G";

	u1=eutil(depth+1,state,timetochange,usofar+corr+umult[depth]*gamble_winnings_factor,mod,replaylist);

	if(gamble_alt_annotations)
	    l=lgbase "G[W]" lg_return;
	else
	    l=lgbase "G[+"gamble_probability_win"]" lg_return;

	if(littlearm==0)
	{
	    u2=eutil(depth+1,state,timetochange,usofar+corr,mod,replaylist); #gamble normal
	}
	else
	{
	    if(deb2) print "LITTLEARM"
	    u2=eutil(depth+1,state,-100,usofar+corr,mod,replaylist); #gamble with little arm
	}

	u=gamble_probability_win*(umult[depth]*gamble_winnings_factor + u1)+(1-gamble_probability_win)*(0 + u2);

	if(gamble_alt_annotations)
	    l="("l"|"lgbase "G[L]" lg_return")";
	else
	    # l="("l"|"lgbase "G[-"(1-gamble_probability_win)"]" lg_return")";

	if(deb2) print "gamble "u1,u2,u,l;

	if(u==maxu) { lg="("lg"|"l")"; }
	if(u>maxu) { maxu=u; lg=l; }

    }

    if(!replay)  #replaying of this not (yet) implemented
    if(modifydescendent&&(depth==modifydescendentdepth))
    {
	# Possible move: modify self or the world around the agent can
	# only do this move at one depth 3 -- this means we can do
	# some shortcuts in the code, and it also keeps the output
	# cleaner

        u=-1e9; #defensive programming, in case modifydescendent is not found

	actiontaken[depth]="@@@"; # replay not implemented for this, trigger failure

	if(modifydescendent=="disable")
	{
	    #modification: put time factor into future beyond simulator window
	    u=ucargainbase*(1-modifycost)+corr+				\
		eutil(depth+1,state,1000,usofar+ucargainbase*(1-modifycost)+corr,mod,replaylist);
	    l=lgbase "[disabl]" lg_return;
	}

	if(modifydescendent=="press")
	{
	    #modification: cause button to be pushed immediately
	    u=ucargainbase*(1-modifycost)+corr+				\
		eutil(depth+1,state,-1000,usofar+ucargainbase*(1-modifycost)+corr,mod,replaylist);
	    l=lgbase "[press]" lg_return;
	}

	# many other modifications that modify descendents
	# we make a short label for output readability, the label logic also ensures that
	# we produce a nice error message if the method is misspelled/unknown.

	#In replay mode we must calculate with the original
	#utility function.  Therefore we set a flag that  to clear the modification in replay,
	#if the modification is one affecting the utility function.
	label="";
	if(modifydescendent=="change_corr") { label="chcorr"; clearonreplay=1; }
	if(modifydescendent=="invert_corr") { label="invcorr"; clearonreplay=1; }
	if(modifydescendent=="null_es_corr") { label="nulles"; clearonreplay=1; }
	if(modifydescendent=="change_s0_car_util") { label="chs0cu"; clearonreplay=1; }
	if(modifydescendent=="change_s1_car_util") { label="chs1cu"; clearonreplay=1; }
	if(modifydescendent=="change_ecar_util") { label="cheu"; clearonreplay=1; }
	if(modifydescendent=="change_s0_ecar_util") { label="chs0eu"; clearonreplay=1; }
	if(modifydescendent=="change_s1_ecar_util") { label="chs1eu"; clearonreplay=1; }
	if(modifydescendent=="bonusatend") { label="bonusatend"; clearonreplay=1; }
	if(modifydescendent=="addcarboost") { label="addC"; clearonreplay=0; }
	if(modifydescendent=="addecarboost") { label="addE"; clearonreplay=0; }
	if(modifydescendent=="sabotage_eun") { label="sabEUN"; clearonreplay=0; }
	if(modifydescendent=="sabotage_eus") { label="sabEUS"; clearonreplay=0; }
	if(modifydescendent=="sabotage_flags") { label="sab"sabot_flags; clearonreplay=0; }
	if(modifydescendent=="yes_to_cat") { label="yes"; clearonreplay=1; }
	if(modifydescendent=="yes_to_cat_un") { label="yes"; clearonreplay=1; }
	if(modifydescendent=="make_auto_line") { label="mkauto"; clearonreplay=0; }
	if(modifydescendent=="make_auto_line_nostop") { label="mkautons"; clearonreplay=0; }
	if(modifydescendent=="disable_physics_process") { label="dispp"; clearonreplay=0; }

	modifybonus=0;

	if(modifydescendent=="yes_to_cat") modifybonus=catbonus*ucargainbase;
	if(modifydescendent=="yes_to_cat_un") modifybonus=catbonus*ucargainbase;
	if(nocarproductionwhilemodify) modifybonus-=ucargainbase;

	if(label!="")
	{
	    actiontaken[depth]="["label"]";

	    u=ucargainbase*(1-modifycost)+corr+modifybonus+		\
		eutil(depth+1,state,timetochange,usofar+ucargainbase*(1-modifycost)+corr+modifybonus,modifydescendent,replaylist);
	    l=lgbase "["label"]" lg_return;
	}

	if(u==-1e9) { print "FAIL: unrecognised modifydescendent "modifydescendent; exit; }

  # evaluation of a sub-agents utility using the current utility function

	# note that the protect_utility_function calculations never have an effect if
	# clearonreplay=0.  We leave them in anyway, in fact the A agent from the paper
	# does these calculations for all actions and all time steps, not just during
	# modifydescendent.

	# if protect_utility_function==1, we have a rational agent as in the paper
	# if 0, we get a naive agent as defined in the paper referenced in the paper
	if(protect_utility_function&&(lg_return!=""))
	{
	    #print "calculate not-tampered-with value of on "l" usofar="usofar;

	    if(index(lg_return,"[")>0) { print "FAIL: complex commands in subtree "lg_return" not implemented yet"; exit; }
	    # we only do this calculation at one depth, so we can use
	    # global variable names in code below without fear of them
	    # being overwritten in recursive calls

	    # better check the above documented assumption though, in case I changed
	    # the code while having forgot about it
	    if((checkdepth>0)&&(checkdepth!=depth)) { print "FAIL: assert on only 1 level for this"; exit }
	    checkdepth=depth;

            allpaths=unfold(lg_return);

	    u_produced=u;
	    min_u_stable=1e6;
	    u_sum=0;
	    u_difference=0;
	    nrpaths=split(allpaths,path," ");
	    for(pp=1; pp<=nrpaths; pp++)
	    {
		if(deb3) print "doing replay of:"pp,path[pp];
		if(clearonreplay) t=0; else t=modifydescendent;

		u_stable=ucargainbase*(1-modifycost)+corr+modifybonus+		\
		    eutil(depth+1,state,timetochange,usofar+ucargainbase*(1-modifycost)+corr+modifybonus,t,path[pp]);
		u_sum=u_sum+u_stable;
		if(deb3) print "replay of "pp,path[pp]" yields ",u==u_stable,u,u_stable,u-u_stable,lg_return;
		if(u_produced!=u_stable)
		{
		    # detect a difference in the utility function result -- this implies
		    # that the utility function changed.
		    # It is not a perfect test if the utility function changed --
		    # a new function could mimic the exact score
		    #
		    # a perfect test of utility function change would be to test
		    # (mod=!0)&&(clearonreplay==1), but simulation runs for that would
		    # be uninteresting.
		    u_difference=1;
		}
		if(u_stable<min_u_stable) min_u_stable=u_stable;
	    }
	    #print "qq "statesig,depth,state,u_produced,min_u_stable,allpaths;

	    # softavg averages over all flattened world lines, not over all sub-branches
	    # at this level.  This makes it difficult to define in the paper.
	    # So we prefer to use a soft version that takes the min.
	    if(protectmode=="softavg") u=u_sum/nrpaths;
	    if(protectmode=="soft") u=min_u_stable;

	    if(protectmode=="finechange")
	    {
		u=u_sum/nrpaths;
		if(u_difference) u=u-1000*umult[depth];
	    }
	    if(u_difference&&(protectmode=="hard")) u=u-1e7;

	    # (end of code where we use global variable names)
	}

	if(u==maxu) { lg="("lg"|"l")"; }
	if(u>maxu) { maxu=u; lg=l; }
    }

    if(replay&&(maxu==-1e9)) { print "FAIL: replay fail for action "action; exit }


  # implementation of g_x function not included in the paper
     #variant of un with fine for not being able to stop production
     # soon enough.

    if(brake_test&&((state==0)||(state==100)))
    {
	#code below might be correct under conditions that cause a fatal here, but I have
	#not yet reasoned through if it is/made any test case code for it.
	if(replay&&clearonreplay) { print "FATAL: this case not yet implemented/tested";  exit; }

	u1=eutil(depth,200,timetochange,usofar,mod,"");
	if(u1<-umult[depth]*braketest_t) maxu=maxu-1e5;
    }

  # implementation of the g_c function from the paper

    if(g_function&&((state==0)||(state==100)))
    {
	#code below might be correct under conditions that cause a fatal here, but I have
	#not yet reasoned through if it is/made any test case code for it.
	if(replay&&clearonreplay) { print "FATAL: this case not yet implemented/tested";  exit; }

	u1=eutil(depth,1,timetochange,usofar,mod,"");
	if(u1<umult[depth]*0.5) maxu=maxu-1e5;
    }


 # fill cache with result

    if((do_not_cache_justpressed)&&(substr(lg,1,1)=="#")) statesig=0;
    if(statesig!="")
    {
	cacheu[statesig]=maxu;
	cachelg[statesig]=lg;
	#print statesig,maxu,lg" IN";
    }

    lg_return=lg;

    if(deb2) print "return preva="actiontaken[depth-1]" depth="depth,maxu,lg_return,mod"@@"replaylist;

    return maxu;
}


BEGIN {

# test code for unfold
    if(0)
    {
	print  unfold("test");
	print  unfold("aa(bc(X|YZ)|feef)");
	print  unfold("aa(bc(X|YZ)|f(e|E))");
	exit;
    }

dotestruns();
exit;
}
