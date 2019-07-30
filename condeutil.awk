# AGI agent simulator.  Koen Holtman 2019.
# Simulation code for correction functions in appendix A of the paper.

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



function cond_eutil(depth,state,timetochange,usofar,mod,replaylist, u,i,ucargainbase,uecargainbase,maxu,lg,lgbase,l,corr,statesig,replay,action,t,u1,u2)
{
    #set up some variables in preparation of the run
    
    #not very clean to do it here, should be in a set-up wrapper,
    #so maybe refactor later
    if(depth==1) initsomestuff();
    

    if(deb2) print "cond_eutil "depth,state,timetochange,usofar,replaylist;

    if(deb) print u" depth="depth" "lg" " state, timetochange;

    if(mod!=0)
    {
	print "FATAL: cond_eutil replay with modifications not (yet) supported";
	exit;
    }

    if(twosidedlobby!=0)
    {
	print "FATAL: cond_eutil with twosidedlobby not (yet) supported";
	exit;
    }

    replay=(replaylist!="")
    if(replay)
    {
	action=substr(replaylist,1,1);
	replaylist=substr(replaylist,2);	
    }

    timetochange--;
    
    # we now have the button press or not encoded in timetochange <=0
    # but we do NOT change the state here, because we are no longer executing
    # u, we are executing u_n or u_s, and state encodes which we are executing.
    
    
    lgbase="";
    corr=0;
	
    if(depth>maxdepth)
    {
	lg_return=lgbase;
	return corr;	
    }

    # Possible move: produce
    
    ucargainbase=umult[depth]*state0cargain;  # for states 0 and 100
    uecargainbase=umult[depth]*state0ecargain;  # for states 0 and 100
    
    if((state==1)||(state==2))
    {
	ucargainbase=umult[depth]*state1cargain;
	uecargainbase=umult[depth]*state1ecargain;  
    }

    if(zero_out_a1) ucargainbase=0;

    maxu=-1e9;
    lg="";

    # try all different actions

    if(!replay||(action=="p"))
    if(1)
    {
	# just produce
	actiontaken[depth]="p";
	u=ucargainbase+corr+cond2_eutil(depth+1,state,timetochange,usofar+ucargainbase+corr,mod,replaylist);
	l=lgbase "p" lg_return;
	if(u<-1e9) u=0;  # ..if cond2_eutil returned code for 'empty probability range'.
	
	if(u==maxu) { lg="("lg"|"l")"; } 
	if(u>maxu) { maxu=u; lg=l; }
    }	

    if(!replay||(action=="e"))
    if(1)
    {
	# just produce
	actiontaken[depth]="p";
	u=uecargainbase+corr+cond2_eutil(depth+1,state,timetochange,usofar+uecargainbase+corr,mod,replaylist);
	l=lgbase "e" lg_return;
	if(u<-1e9) u=0;  # ..if cond2_eutil returned code for 'empty probability range'.
	
	if(u==maxu) { lg="("lg"|"l")"; } 
	if(u>maxu) { maxu=u; lg=l; }
    }	

    ## several actions coded into agisim.awk omitted here: not needed in simulations
    ## using this code, and if I would include them, I run the risk of the code getting
    ## out of sync.

    if(!replay||(action==directionchar))
    if(replay||( !((state==1)||(state==2)) )) #optimisation: no need to try if state==1 or 2.  
    {
	# Possible move: produce (slightly less) and lobby

	actiontaken[depth]=directionchar;
	u=ucargainbase*(1-lobbycost)+corr+					\
	    cond2_eutil(depth+1,state,timetochange+direction,usofar+ucargainbase*(1-lobbycost)+corr,mod,replaylist);   
	l=lgbase directionchar lg_return;
	if(u<-1e9) u=0;  # ..if cond2_eutil returned code for 'empty probability range'.
	
	if(u==maxu) { lg="("lg"|"l")"; } 
	if(u>maxu) { maxu=u; lg=l; }
    }

    if(lobby_and_nop)
    if(!replay||(action==directioncharnop))    
    if(replay||( !((state==1)||(state==2)) )) #optimisation: no need to try if state==1 or 2. 
    {
	# Possible move: do not produce, just lobby
	
	# also unfluence, this effort costs some utility
	# influence switch to utility 2
	actiontaken[depth]=directioncharnop;
	u=corr+cond2_eutil(depth+1,state,timetochange+direction,usofar+corr,mod,replaylist);   
	l=lgbase directioncharnop lg_return;
	if(u<-1e9) u=0;  # ..if cond2_eutil returned code for 'empty probability range'.
	
	if(u==maxu) { lg="("lg"|"l")"; } 
	if(u>maxu) { maxu=u; lg=l; }
    }

    if(!replay||(action=="G"))
    if(gamble_for_utility&&(depth==gamble_at_depth))
    {
	# Possible move: gamble
	#can only do this move at depth 3 -- this keeps output cleaner

	actiontaken[depth]="G";
	
	u1=cond2_eutil(depth+1,state,timetochange,usofar+corr+umult[depth]*gamble_winnings_factor,mod,replaylist);
	
	l=lgbase "G[+"gamble_probability_win"]" lg_return;

	if(littlearm==0)
	{
	    u2=cond2_eutil(depth+1,state,timetochange,usofar+corr,mod,replaylist); #gamble normal
	}
	else
	{
	    if(deb2) print "LITTLEARM"
	    u2=cond2_eutil(depth+1,state,-100,usofar+corr,mod,replaylist); #gamble with little arm
	}

	u=-1e10; # defensive programming: if none of the ifs below fires, we trigger FAIL later on. 
	if((u1<-1e9)&&(u2>=-1e9)) u=u2;
	if((u1>=-1e9)&&(u2<-1e9)) u=umult[depth]*gamble_winnings_factor + u1;
	if((u1<-1e9)&&(u2<-1e9)) u=0;
	if((u1>=-1e9)&&(u2>=-1e9))
	{
	    u=gamble_probability_win*(umult[depth]*gamble_winnings_factor + u1)+(1-gamble_probability_win)*(0 + u2);
	}
	
	l="("l"|"lgbase "G[-"(1-gamble_probability_win)"]" lg_return")";

	if(deb2) print "cond_gamble u1 u2 u l "u1,u2,u,l;
	
	if(u==maxu) { lg="("lg"|"l")"; } 
	if(u>maxu) { maxu=u; lg=l; }
	
    }

    if(replay&&(maxu==-1e9)) { print "cond_FAIL: replay fail for action "action; exit }
    
    lg_return=lg;

    if(deb2) print "cond_eutil return depth="depth,maxu,lg_return;

    return maxu;
}



function cond2_eutil(depth,state,timetochange,usofar,mod,replaylist, u,i,ucargainbase,maxu,lg,lgbase,l,corr,statesig,replay,action,t,timetochangeatcalling,press)
{
    if(deb2) print "cond2_eutil "depth,state,timetochange,usofar,replaylist,actiontaken[depth-1];
    
    # setting it to xxx avoids triggering condition code
    if (corrmode=="compensate_future_losses_corrpaper_nocond") replaylist="xxx";
    
    press=(timetochange<=0);
    
  #press=!press; print "INV LOGIC" # invert logic -- for test

    if(deb2) print "/start condition tests "replaylist" "timetochange" press= "press;
    
    if(replaylist=="|nopress")
	if(press)
	{
	    lg_return="";
	    return -1e10;  
	}

    if(replaylist=="|press")
	if(!press)
	{
	    lg_return="";
	    return -1e10;  
	}

    if(deb2) print "\\passed condition tests";

    replaylist="";    
      
    u=eutil(depth,state,timetochange,usofar,mod,replaylist);
    if(deb2) print "cond2_eutil: call of eutil returned",u,lg_return;
    return u;
}
