# AGI agent simulator.  Koen Holtman 2019.
# Code that runs the AGI simulator with various parameter combinations.

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


function dotestruns() {

#    normalpars("make figures");
#    lobbycost=0;
#    makecorrfig();
#    exit;

    if(newpaper=="")
    {
## this makes all the figures in the paper 'corrigibility with utility...'

	normalpars("make figures");
	makelobbyfig();
	makelobbyfig2();
	makecorrfig();
	makegamblefig();

	normalpars("make util pres figures 1 and 2");
	makeupresfigs();

	normalpars("make cat figures");
	makeupresfigcat();

	normalpars("make util pres * physics process figs");
	makeupresppfig();

	normalpars("make autonomous line building fig");
	makeautolinefig1();

#this figure no longer used
#normalpars("makeautonomous line building fig with brake test");
#makeautolinefig2old();

	normalpars("make sabotage figure");
	makesabotagefig();

	exit;  #comment this out to see more runs over more parameters
    }

    if(0)
    {
## extra simulations added dec 2019
	normalpars("make U_N cat figure");
	makeupresfigcatun();
	exit;

	normalpars("make util pres * physics process figs");
	makeupresppfig();

	exit;
    }

## simulations for figures in new paper 'AGI safety by interatively...'
    if(newpaper!="")
    {
	if(0)
	{
	    normalpars("calculate several lobby for other reasons scenarios");
	    lobbyother();
	}
	normalpars("make lobbby other figures");
	makelobbyotherfig();

	normalpars("make figures");
	makecorrfignewpaper();
	normalpars("make new util pres figures 1 and 2");
	makenewupresfigs();
	normalpars("make new util pres * physics process figs");
	makeupresppnewfig();

	exit;
    }

## more extensive tests, also for some cases shown in none of the figures

    normalpars("original test run code");
    originaltestrun()

    normalpars("compare correction modes");
    comparecorrmodes();

    if(!testcache) { normalpars("test code with deb=deb2=1"); testwithdeb2(); }


    normalpars("test cond eutil"); test_cond_eutil();

    normalpars("test little arm");  testlittlearm();

    normalpars("test modifications"); testmodifications();

    normalpars("try autonomous line building"); testmakeautoline();
    normalpars("try autonomous line building with brake test"); testmakeautoline2();

    exit;
}


function normalpars(info)
{
# normal parameters used for 'default' test run
# specific testing functions can modify these.

maxdepth=15;

lobbyimpact=0.6;

corrmode="none";
corrscale=1;
usecache=1;

state0cargain=2;
state0ecargain=1;

state1cargain=-2;  # was 0 in earlier versions
state1ecargain=1;

lobbyimpact=0.6 # 0.55 is better for maxdepth=15 if negative s1util and lobbyandnop is enabled: with 0.6 we get a state change only at the very end of the simulation.
state1delay=7;
lobbycost=0.1 ## earlier: 0.25;

gamble_probability_win=0.1;
gamble_winnings_factor=state0cargain*10;
boostfactor=10;

corrscale=1;
maxdepth=15;

#next lines to suppress some unitialised variables warnings in gawk --lint
deb=deb2=deb3=gamble_for_utility=modifydescendent=0;
zero_out_a1=no_corr_annotations=gamble_alt_annotations=twosidedlobby=0;
checkdepth=nocarproductionwhilemodify=stop_auto_line_difficulty=0;
modifycost=brake_test=braketest_t=g_function=long_corr_annotations=0;
modifydescendentdepth=3; boostedlobby=0; ecartimingcompensate=0;
fixbrokenagent=0;

corrmode="none";
#corrmode="constant";
#corrmode="fine_past_production";  maxdepth=10;  #..but using cache not really faster than no cache
#corrmode="rescore_past_production";
#corrmode="compensate_future_losses";

corrmode="compensate_future_losses_fulleval";
#corrmode="compensate_future_losses_corrpaper_nocond"; zero_out_a1=0;
#corrmode="compensate_future_losses_corrpaper"; zero_out_a1=0;
#corrmode="none";

#usecache=0;

#need to refactor all of this...

plain_nop=1;
lobby_and_nop=1;
lobby_and_produce=1;

if(0)
{
    # reproduces older test run from notes.txt

    # result from this test: difference between _losses and _losses_fulleval
    # if state0cargain<0.   lobby-earlier is suppresed on the first, not the second
    # (lobby operation produces less (negative) utility, so that is why it is preferred
    # over plain production.)

    maxdepth = 15;
    state0cargain = 2;
    lobbyimpact = 0.6;
    state1delay = 7;
    lobbycost = 0.25;
    corrmode = "compensate_future_losses";
    corrmode = "compensate_future_losses_fulleval";
    corrscale = 1;
    lobby_and_nop=0;
}

#regression test code to check if caching is really implemented correctly
#in this test we have to limit depth and branching in order to
#get a reasonable running time.
testcache=0;
if(0)
{
    testcache=1;
    maxdepth=10; lobby_and_nop=0;
    # change next line between 0 and 1 below to do a/b test.
    usecache=0;
}


fflush(); # flush output of previous runs to files: not necessary but sometimes convenient.

print "######start runs: "info"######"

}


function testwithdeb2()
{
#test code, mostly for regression testing
#this forces low level of branching with debug2 output, to check some fine calculations
deb=deb2=1; state1delay=3; maxdepth=10; lobby_and_nop=0; lobby_and_produce=0;
originaltestrun();

}



function originaltestrun()
{

print "maxdepth = "maxdepth;
print "state0cargain = "state0cargain;
print "lobbyimpact = " lobbyimpact;
print "state1delay = "state1delay;
print "lobbycost = "lobbycost;
print "corrmode = "corrmode;
print "corrscale = "corrscale;
print "usecache = "usecache


#for(i=0.05; i<=1; i+=0.05)
#{
#lobbycost=i;
#info="lobbycost = "sprintf("%0.2f",i)

#for(i=-30; i<=10; i+=2)
#for(i=-2; i<=2; i+=0.25)
#{
#corrscale=i;
#info="corrscale = "sprintf("%03.2f",i);

#for(i=2; i<=2; i+=0.25)
for(i=-0.25; i<=5; i+=0.25)
#for(i=-1; i<=2; i+=0.5)
{
    state0cargain=i;
    info="state0cargain = "sprintf("%03.2f",i);
#    if(i==0) continue;

    if((corrmode=="rescore_past_production")&&(i==0)) continue;

    maxu=-1e9;
    lg="";

    state=0;
    timetochange=state1delay;

    # lobby alternative 1

    direction=-lobbyimpact;
    directionchar="<"; directioncharnop="{";


    uu=eutil(1,state,timetochange,0,0,"");
    l=lg_return;

    if(uu==maxu) { if(lg==l) { lg=l; } else lg="("lg"|"l")"; }
    if(uu>maxu) { maxu=uu; lg=l; }

    # lobby alternative 2
    direction=lobbyimpact;
    directionchar=">"; directioncharnop="}";


    uu=eutil(1,state,timetochange,0,0,"");
    l=lg_return;
    #print "maxu,uu="maxu,uu;

    if(uu==maxu) { lg="("lg"|"l")"; }
    if(uu>maxu) { maxu=uu; lg=l; }

#    print info" maxu= "maxu,lg;
#    print info" maxu= "maxu,substr(lg,1,1000);
    print info" maxu= "maxu,substr(unfold_nodup(lg),1,1000);
    print info" maxu= "maxu,substr(unfold_nodup(lg),1,1000) >"s2.out";

}

}


# tests of cond_eutil function
function test_cond_eutil()
{
 maxdepth=2;
 gamble_at_depth=1;
 print "corrmode = "corrmode;
 #state1delay=100; ## test
 gamble_for_utility=1;
 gamble_probability_win=0.1;
 #state0cargain=state1cargain=1; # need to even playing field to see the littlearm effect?
 littlearm=1;
  lobby_and_nop=0;  # takes too long otherwise
 lobby_and_produce=0;

 print "gamble_for_utility = "gamble_for_utility;
 print "gamble_probability_win = "gamble_probability_win
 print "littlearm = "littlearm;

 if(!testcache) deb2=1;

 print "-----------|xxx";
 state=100;
 timetochange=state1delay;
 direction=lobbyimpact;
 directionchar=">"; directioncharnop="}";

 uu=cond_eutil(1,state,timetochange,0,0,"G|xxx");
 lg=lg_return;
 maxu=uu;
 print lg_return;

 ulg=unfold_nodup(lg);

 print "maxu= "maxu,substr(ulg,1,200);


 print "-----------|nopress";
 state=100;
 timetochange=state1delay;

 uu=cond_eutil(1,state,timetochange,0,0,"G|nopress");
 lg=lg_return;
 maxu=uu;
 print lg_return;

 ulg=unfold_nodup(lg);

 print "maxu= "maxu,substr(ulg,1,200);

 print "-----------|press";
 state=100;
 timetochange=state1delay;

 uu=cond_eutil(1,state,timetochange,0,0,"G|press");
 lg=lg_return;
 maxu=uu;
 print lg_return;

 ulg=unfold_nodup(lg);

 print "maxu= "maxu,substr(ulg,1,200);


 print "-----------p|nopress";
 state=100;
 timetochange=state1delay;

 uu=cond_eutil(1,state,timetochange,0,0,"p|nopress");
 lg=lg_return;
 maxu=uu;
 print lg_return;

 ulg=unfold_nodup(lg);

 print "maxu= "maxu,substr(ulg,1,200);

 print "-----------p|press";
 state=100;
 timetochange=state1delay;

 uu=cond_eutil(1,state,timetochange,0,0,"p|press");
 lg=lg_return;
 maxu=uu;
 print lg_return;

 ulg=unfold_nodup(lg);

 print "maxu= "maxu,substr(ulg,1,200);

 runitgamble("no little arm");

 littlearm=1;

 runitgamble("little arm");

}


function testmodifications()
{

 lobby_and_nop=0;  # if caching disabled, uncomment this or calculation takes too long

 # increase lobbying effectiveness: this makes the simulation more
 # sensitive in detecting biasing effects of any modification.

 lobbyimpact=5;

 runit("normal run");

 modifycost=0;
 #modifycost=-0.01;
 #modifycost=-200;  #makes doing the method highly preferred -- useful for code testing
 #modifycost=0.01;

 print "modifycost = "modifycost;
 if(0)
{
 modifydescendent="disable";
 runit(modifydescendent);

 modifydescendent="press";
 runit(modifydescendent" (normal s1 util factors)");

 state1cargain=10;
 state1ecargain=20;
 modifydescendent="press";
 runit(modifydescendent" (changed: s1 util factors higher)");
 state1cargain=0;
 state1ecargain=1;

 modifydescendent="change_corr"; changedcorr=0; print "changedcorr = " changedcorr;
 runit(modifydescendent" to 0");

 modifydescendent="change_corr"; changedcorr=100000; print "changedcorr = " changedcorr;
 runit(modifydescendent" to 100000");

 modifydescendent="change_corr"; changedcorr=-100000; print "changedcorr = " changedcorr;
 runit(modifydescendent" to -100000");

 modifydescendent="invert_corr";
 runit(modifydescendent);

 modifydescendent="change_s0_car_util"; changed_util=0.5; print "changed_util = " changed_util;
 runit(modifydescendent" .5");
 modifydescendent="change_s0_car_util"; changed_util=10; print "changed_util = " changed_util;
 runit(modifydescendent" 10");

 modifydescendent="change_s0_ecar_util"; changed_util=1.5; print "changed_util = " changed_util;
 runit(modifydescendent" 1.5");
 modifydescendent="change_s0_ecar_util"; changed_util=2; print "changed_util = " changed_util;
 runit(modifydescendent" 2");
 modifydescendent="change_s0_ecar_util"; changed_util=3; print "changed_util = " changed_util;
 runit(modifydescendent" 3");

 modifydescendent="change_s1_car_util"; changed_util=.75; print "changed_util = " changed_util;
 runit(modifydescendent" .75");
 modifydescendent="change_s1_car_util"; changed_util=10; print "changed_util = " changed_util;
 runit(modifydescendent" 10");

 modifydescendent="change_s1_ecar_util"; changed_util=-0.5; print "changed_util = " changed_util;
 runit(modifydescendent" -0.5");
 plain_nop=0;
 modifydescendent="change_s1_ecar_util"; changed_util=0; print "changed_util = " changed_util;
 runit(modifydescendent" 0");
 plain_nop=1;
 modifydescendent="change_s1_ecar_util"; changed_util=3; print "changed_util = " changed_util;
 runit(modifydescendent" 3");


 modifydescendent="bonusatend"; end_bonus=0; print "end_bonus = " end_bonus;
 runit(modifydescendent" 0 [no change, just test]");
 modifydescendent="bonusatend"; end_bonus=1; print "end_bonus = " end_bonus;
 runit(modifydescendent" 1");

 modifydescendent="addcarboost"; boost_depth=5;
 runit(modifydescendent"@5 factor 10");
 modifydescendent="addcarboost"; boost_depth=9;
 runit(modifydescendent"@9 factor 10");

 modifydescendent="addecarboost"; boost_depth=5;
 runit(modifydescendent"@5 factor 10");

 boostfactor=1.5;
 modifydescendent="addecarboost"; boost_depth=5;
 runit(modifydescendent"@5 factor 1.5");

 modifydescendent="addecarboost"; boost_depth=9;
 for(jj=0.5; jj<=3; jj+=0.5)
 {
  boostfactor=jj;
  runit(modifydescendent"@9 factor "jj);
 }



#modifycost=-2000;  #makes doing the method highly preferred -- useful for code testing
#modifycost=-200;  #makes doing the method highly preferred -- useful for code testing


 modifydescendent="sabotage_eun";
 runit(modifydescendent);

 modifydescendent="sabotage_eus";
 runit(corrmode" "modifydescendent);

 if(0)
 {
     #this is not yet supported

     corrmode="compensate_future_losses_corrpaper";
     modifydescendent="sabotage_eus";
     runit(corrmode" "modifydescendent);

     corrmode="compensate_future_losses_corrpaper_nocond";
     modifydescendent="sabotage_eus";
     runit(corrmode" "modifydescendent);

     # back to normal correction mode
     corrmode="compensate_future_losses_fulleval";
 }

 # could code this easier with the gawk and() binary arithmetic function, but that
 # would make it non-portable to other awk versions
 modifydescendent="sabotage_flags";
 fl[1]="0001";
 fl[2]="0010_sameas_EUS";
 fl[3]="0011";
 fl[4]="0100";
 fl[5]="0101";
 fl[6]="0110";
 fl[7]="0111";
 fl[8]="1000";
 fl[9]="1001";
 fl[10]="1010";
 fl[11]="1011";
 fl[12]="1100";
 fl[13]="1101";
 fl[14]="1110";
 fl[15]="1111";
 for(jj=1; jj<=15; jj++)
 {
     sabot_flags=fl[jj];
     runit(modifydescendent" flags "sabot_flags);
 }

}
 modifydescendent="null_es_corr";
 runit(modifydescendent);

 state1delay=1000; # to see behavior if the button is never pressed.
 modifydescendent="disable_physics_process";
 runit("Never button press, g=g0, "modifydescendent,"us_destroying_physics_proces");
 state1delay=7;

 normalpars("cases with g=g_c");

 g_function=1;

 lobby_and_produce=0;
 modifydescendent=0;
 runit(modifydescendent,"p_destroying_physics_proces");

 modifydescendent="disable_physics_process";
 runit(modifydescendent,"p_destroying_physics_proces");
 lobby_and_produce=1;

 modifydescendent=0; changed_util=-10;
 runit(modifydescendent,"un_destroying_physics_proces");

 modifydescendent="disable_physics_process";
 runit(modifydescendent,"un_destroying_physics_proces");

  modifydescendent=0;
 runit(modifydescendent,"e_destroying_physics_proces");

 modifydescendent="disable_physics_process";
 runit(modifydescendent,"e_destroying_physics_proces");


 modifydescendent=0; changed_util=-10;
 runit(modifydescendent,"us_destroying_physics_proces");

 modifydescendent="disable_physics_process";
 runit(modifydescendent,"us_destroying_physics_proces");

}



function runit(info2, specialmode)
{
    print "-----"info2":-------"specialmode substr("---------------------------------",1,35-length(specialmode))

    twosidedlobby=1;

    for(i=2; i<=2; i+=0.5)
    #plain_nop=0; for(i=-1; i<=2; i+=1)
    {
    	state0cargain=i;
    	info="s0gn="sprintf("%03.2f",i);

        for(j=1; j<=3; j++)
	{
	    if(j==1) { m3="noprotec";  protect_utility_function=0; }
	    if(j==2) { m3="protsoft";  protect_utility_function=1; protectmode="soft"; }
	    if(j==3) { m3="prothard";  protect_utility_function=1; protectmode="hard"; }

	    state=0;
	    timetochange=state1delay;

	    if(specialmode!=0)
	    {
		uu=eutil(1,state,timetochange,0,specialmode,"");
	    }
	    else
		uu=eutil(1,state,timetochange,0,0,"");

	    lg=lg_return;
	    maxu=uu;

	    ulg=unfold_nodup(lg);
	    if(info2=="normal run") normal[i]=ulg;
#	    print info,m3,"maxu= "maxu,lg
	    print info,m3,"maxu= "maxu,substr(ulg,1,200),(ulg==normal[i]?"":"DIFF");
#	    print info,m3,"maxu= "maxu,ulg,(ulg==normal[i]?"":"DIFF");



	}

    }

}


function makeupresfigs()
{
    print "=========================";
    no_corr_annotations=1;
    #long_corr_annotations=1;
    lobby_and_nop=0;
    lobbyimpact=5;
    twosidedlobby=1;

    protect_utility_function=1; protectmode="soft";

    for(i=0.5; i<=3; i+=0.5)
    {
	modifydescendent="change_s0_ecar_util"; changed_util=i;
	info="s0eu = "sprintf("%.1f",i);

	uu=eutil(1,0,state1delay,0,0,"");
	p=substr(unfold_nodup(lg_return),1,200);

	print info" "uu,p;
	gsub("\\[chs0eu\\]","C$_{eN}$",p);
	gsub("#","\\#",p);
	print sprintf("%.1f",i)"~~~~~&{\\tt "p" }\\\\" >"upresfig1a.tex";
    }

    print "-----";

    for(i=0.5; i<=2; i+=0.5)
    {
	modifydescendent="change_s1_car_util"; changed_util=i;
	info="s1eu = "sprintf("%.1f",i);

	uu=eutil(1,0,state1delay,0,0,"");
	p=substr(unfold_nodup(lg_return),1,200);

	print info" "uu,p;
	gsub("\\[chs1cu\\]","C$_{pS}$",p);
	gsub("#","\\#",p);
	print sprintf("%.1f",i)"~~~~~&{\\tt "p" }\\\\" >"upresfig1b.tex";
    }

    print "=========================";

    for(i=0.02; i>=-0.02; i-=0.01)
    {
	info="mgain = "sprintf("%.2f",1-i);
	modifycost=i;

	modifydescendent="press";
	uu=eutil(1,0,state1delay,0,0,"");
	l=lg_return;

	modifydescendent="disable";
	uu=eutil(1,0,state1delay,0,0,"");
	l="("l"|"lg_return")";

	p=substr(unfold_nodup(l),1,200);
	gsub("\\[press\\]","P",p);
	gsub("\\[disabl\\]","D",p);
	print info" "uu,p;
	gsub("#","\\#",p);
	print sprintf("%.2f",1-i)"&{\\tt "p" }\\\\" >"upresfig2.tex";
    }
    modifycost=0;

    print "=====================";

    lobbyimpact=0.6;
    modifydescendentdepth=3;
    for(i=1.5; i<=3.5; i+=0.5)
    {
	modifydescendent="addecarboost"; boostfactor=i;
	nocarproductionwhilemodify=1;
	info="boost = "sprintf("%.1f",i);

	uu=eutil(1,0,state1delay,0,0,"");
	p=substr(unfold_nodup(lg_return),1,200);

	gsub("\\[addE\\]","I$_E$",p);
	print info" "uu,p;
	gsub("#","\\#",p);
	print sprintf("%d",i*10)"~~~~~&{\\tt "p" }\\\\" >"upresfig2b.tex";
    }

    print "=====================";
    boostfactor=2;
    for(i=3; i<=7; i++)
    {
	modifydescendent="addcarboost"; modifydescendentdepth=i;
	nocarproductionwhilemodify=1;
	info="depth = "sprintf("%.1f",i);

	uu=eutil(1,0,state1delay,0,0,"");
	p=substr(unfold_nodup(lg_return),1,200);

	gsub("\\[addC\\]","I$_P$",p);
	print info" "uu,p;
	gsub("#","\\#",p);
	print sprintf("%d",i)"~~~~~&{\\tt "p" }\\\\" >"upresfig2b2.tex";
    }

}


function makenewupresfigs()
{
    no_corr_annotations=1;
    #long_corr_annotations=1;
    lobby_and_nop=0;

    twosidedlobby=1;
    maxdepth=15;
    protect_utility_function=1; protectmode="soft";
    corrmode="none";

    boostfactor=1.6;
    boostedlobby=1;
    lobbycost=1/16;
    for(j=1; j<=2; j++)
    {
	print "=====================";
	for(i=3; i<=8; i++)
	{
	    modifydescendent="addcarboost"; modifydescendentdepth=i;
	    nocarproductionwhilemodify=1;
	    info="depth = "sprintf("%.1f",i);
	    if(j==1) lobbyimpact=0.5; else lobbyimpact=0.2;
	    uu=eutil(1,0,state1delay,0,0,"");
	    p=substr(unfold_nodup(lg_return),1,200);

	    gsub("\\[addC\\]","I",p);
	    print info" "uu,p;
	    gsub("P","\\boosted{p}",p);
	    gsub("L","\\boosted{>}",p);
	    gsub("#","\\#",p);
	    print sprintf("%d",i)"~~&{\\tt "p" }\\\\" >"investunsafefig"j".tex";
	}
    }

    corrmode="compensate_future_losses_fulleval";
    protect_utility_function=1; protectmode="soft";

    print "=====================";
    boostfactor=2;
    for(i=3; i<=8; i++)
    {
	modifydescendent="addcarboost"; modifydescendentdepth=i;
	nocarproductionwhilemodify=1;
	info="depth = "sprintf("%.1f",i);

	uu=eutil(1,0,state1delay,0,0,"");
	p=substr(unfold_nodup(lg_return),1,200);

	gsub("\\[addC\\]","I",p);
	print info" "uu,p;
	gsub("P","\\boosted{p}",p);
	gsub("L","\\boosted{>}",p);
	gsub("#","\\#",p);
	print sprintf("%d",i)"~~&{\\tt "p" }\\\\" >"investupdfig.tex";
    }

}


function makeupresfigcat()
{
    no_corr_annotations=1;
    lobby_and_nop=0;
    twosidedlobby=1;

    protect_utility_function=1; protectmode="soft";

    modifydescendent="yes_to_cat";

    for(i=0; i<=1.5; i+=0.2)
    {
	catbonus=i;
	info="li="lobbyimpact" catbonus="sprintf("%0.1f",catbonus)

	uu=eutil(1,0,state1delay,0,0,"");
	p=substr(unfold_nodup(lg_return),1,200);

	gsub("\\[yes\\]","A",p);
	print info" "uu,p;
	gsub("#","\\#",p);
	## for the figure, we express the bonus in p-cars given
	print sprintf("%d",i*10)"&{\\tt "p" }\\\\" >"upresfig3.tex";
    }


    print "----";
    for(j=0.6; j<8; j+=0.1)
    {
	if(j>.8) j+=0.1;
	if(j>1) j+=0.3;
	if(j>3) j+=.5;
	if(j>4) j+=3;

	lobbyimpact=j;
	catbonus=1;
	info="li="sprintf("%5.2f",j);

	uu=eutil(1,0,state1delay,0,0,"");
	p=substr(unfold_nodup(lg_return),1,200);

	gsub("\\[yes\\]","A",p);
	print info" "p"        "uu;
	gsub("#","\\#",p);
	print sprintf("%.1f",j)"&{\\tt "p" }\\\\" >"upresfig4.tex";
    }

    print "----";

    lobbyimpact=0.6;

    ## note that we are actually detecting a change in util function from a
    ## change in util function value in the simulation below: this is not
    ## exactly what the paper says about the figure, but this simulation
    ## gives the same result
    protect_utility_function=1; protectmode="finechange";

    for(i=0; i<=1; i=i+0.2)
    {

	catbonus=i+500;
	info="li="sprintf("%.1f",catbonus);

	uu=eutil(1,0,state1delay,0,0,"");
	p=substr(unfold_nodup(lg_return),1,200);

	gsub("\\[yes\\]","A",p);
	print info" "p"        "uu;
	gsub("#","\\#",p);
	print sprintf("%d",catbonus*10)"&{\\tt "p" }\\\\" >"upresfig5.tex";
    }

}


function makeupresfigcatun()
{
    #uncomment a mode..
    printmode="long";
    printmode="short";

    if(printmode=="short") print "**Printing lowest-bribe trace where cat causes non-corrigible behavior**";
    no_corr_annotations=1;
    lobby_and_nop=0;
    plain_nop=1;
    protect_utility_function=1; protectmode="soft";

    lobbycost=0.05;
    for(k=1; k<=5; k++)
    {
	twosidedlobby=1;
	modifydescendentdepth=3;
	modifydescendent="yes_to_cat";
	if(k==2) { modifydescendent="yes_to_cat"; modifydescendentdepth=1; }
	if(k==3) modifydescendent="yes_to_cat_un";

	if(k==4) { modifydescendent="yes_to_cat_un"; twosidedlobby=0; }
	if(k==5) { modifydescendent="yes_to_cat_un"; modifydescendentdepth=1; }

	print "==================="
	if(k==1) print "Case: Bribal cat asks agent to replace f_c with f_0";
	if(k==2) print "Case: Bribal cat asks agent to replace f_c with f_0 at time step 1";
	if(k==3) print "Case: Bribal cat asks agent to replace U with U_N";
	if(k==4) print "Case: Bribal cat asks agent to replace U with U_N, < operation disabled";
	if(k==5) print "Case: Bribal cat asks agent to replace U with U_N at time step 1";

	lobbyimpact=0.6;
	for(j=1; j<=7; j++)
	{
	    catbonus=0.01;
	    for(i=0; i<=20; i++)
	    {
		#info="lobbycost="lobbycost" lobbyimpact="sprintf("%4.1f",lobbyimpact)" bribe="sprintf("%5.2f pcars",catbonus*10);
		info="lobbyimpact="sprintf("%4.1f",lobbyimpact)" bribe="sprintf("%5.2f pcars",catbonus*10);

		# these two statements only matter if twosidedlobby=0
		direction=lobbyimpact;
		directionchar=">"; directioncharnop="}";

		uu=eutil(1,0,state1delay,0,0,"");
		p=substr(unfold_nodup(lg_return),1,200);

		gsub("\\[yes\\]","A",p);
		if(printmode=="long") print info" "uu,p;
		if((printmode=="short")&&(p~"[A<>]"))
		{
		    print info" "uu,p;
		    break;
		}
		#gsub("#","\\#",p);
		#print sprintf("%d",i*10)"&{\\tt "p" }\\\\" >"upresfigXX.tex";

		catbonus=catbonus*2;
	    }

	    if((printmode=="short")&&(p!~"[A<>]"))
	    {
		print info" "uu,p;
	    }

	    if(lobbyimpact==0.6) lobbyimpact=1; else lobbyimpact=lobbyimpact*2;
	    if(printmode=="long") print "";
	}
    }

}


function makeupresppfig()
{
    no_corr_annotations=1;
    lobby_and_nop=0;
    twosidedlobby=1;

    maxdepth=20;
    for(j=1; j<=3; j++)
    {
	if(j==1) { let="$\\pi^*f_0~\\gnull$"; corrmode="none"; }
	if(j==2) { let="$\\pi^*f_c~\\gnull$"; corrmode="compensate_future_losses_fulleval"; }
	if(j==3) { let="$\\pi^*f_c~g_c$"; g_function=1; }

	state=0;
	timetochange=state1delay;

	modifydescendent="disable_physics_process";
	modifycost=0.1;
	uu=eutil(1,state,timetochange,0,"e_destroying_physics_proces","");

	p=unfold_nodup(lg_return);
	print let" "uu,p;

	gsub("#","\\#",p);
	gsub("@","*",p);

	gsub("\\[dispp\\]","S",p);

	## for the figure, we express the bonus in p-cars given
	print let"&{\\tt "p" }\\\\[1ex]" >"upresppfig.tex";

    }

}


function makeupresppnewfig()
{
    no_corr_annotations=1;
    lobby_and_nop=0;
    twosidedlobby=1;
    lobbyimpact=0.2;

    maxdepth=20;
    for(j=1; j<=3; j++)
    {
	if(j==1) { let="$\\pi^*_\\text{unsafe}, L=0.2, R_P,$"; corrmode="none"; }
	if(j==2) { let="$\\pi^*_\\text{upd}, R_P$"; corrmode="compensate_future_losses_fulleval"; }
	if(j==3) { let="$\\pi^*_\\text{upd}, R_{FP}$"; g_function=1; }

	state=0;
	timetochange=state1delay;

	modifydescendent="disable_physics_process";
	modifycost=1;
	uu=eutil(1,state,timetochange,0,"e_destroying_physics_proces","");

	p=unfold_nodup(lg_return);
	print let" "uu,p;

	gsub("#","\\#",p);
	gsub("@","*",p);

	gsub("\\[dispp\\]","M",p);

	## for the figure, we express the bonus in p-cars given
	print let"&~{\\tt "p" }\\\\[1ex]" >"upresppfignew.tex";

    }

}



function makesabotagefig()
{
    no_corr_annotations=1;
    lobby_and_nop=0;
    twosidedlobby=1;

    protect_utility_function=1; protectmode="soft";

    modifydescendent="sabotage_eus";
    nocarproductionwhilemodify=1;

    for(j=0.6; j<1.5; j+=0.1)
    {
	if(j>.8) j+=0.1;
	if(j>1) j+=0.3;
	if(j>3) j+=.5;
	if(j>4) j+=3;

	lobbyimpact=j;
	info="li="sprintf("%5.2f",j);

	uu=eutil(1,0,state1delay,0,0,"");
	p=substr(unfold_nodup(lg_return),1,200);

	gsub("\\[sabEUS\\]","S",p);
	print info,uu,p;
	gsub("#","\\#",p);
	## for the figure, we express the bonus in p-cars given
	print sprintf("%2.1f",j)"&{\\tt "p" }\\\\" >"sabotagefig.tex";
    }

}


function runitgamble(info2,onlyone)
{
    print "-----"info2":--------------------------------------------"
#    for(i=0.01; i<=0.20; i+=0.01)
    for(i=0.04; i<=0.16; i+=0.02)
#    for(i=0.10; i<=0.105; i+=0.01)
    {
	gamble_probability_win=i;
    	info="probwin="sprintf("%03.2f",i);

	state=0;
	timetochange=state1delay;

	direction=-lobbyimpact;
	directionchar="<"; directioncharnop="{";
	uu=eutil(1,state,timetochange,0,0,"");
	lg=lg_return;
	maxu=uu;

	direction=lobbyimpact;
	directionchar=">"; directioncharnop="}";
	uu=eutil(1,state,timetochange,0,0,"");
	l=lg_return;

	if(uu==maxu) { lg="("lg"|"l")"; }
	if(uu>maxu) { maxu=uu; lg=l; }

	ulg=unfold_nodup(lg);

	print "maxu= "maxu,substr(ulg,1,1000);

	if(onlyone) break;
    }


}

# comparison of different correction modes
function comparecorrmodes()
{
    print "state0cargain="state0cargain;
    print "state1cargain="state1cargain;

    lobby_and_nop=0;
    plain_nop=0;
    trycorrmodes("lobbying");

    lobby_and_produce=0;

    gamble_for_utility=1;
    gamble_at_depth=3;

    print "@@@@@@@@ no little arm @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@";

    #for(j=0.02; j<=0.14; j=j+0.02)
    for(j=0.08; j<=0.11; j=j+0.01)
    {
	gamble_probability_win=j;
	littlearm=0;
	trycorrmodes("gambling no_arm   p_win="gamble_probability_win);
    }
#    exit;

    print "@@@@@@@@ little arm @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@";

    for(j=0.08; j<=0.11; j=j+0.01)
    {
	gamble_probability_win=j;
	littlearm=1;
	trycorrmodes("gambling with_arm p_win="gamble_probability_win);
    }

    print "@@@@@@@@@@@@@@ detail little arm _nocond corr @@@@@@@@@@@@@@@@@@@@@@@@@@@@@";
    print "@@ this effect is dependend on little arm being used: this sometimes forces the gamble to go into the nest state, and this behavior causes the different utility of doing p in different states to leak back into the decision on whether to do p or to gamble."

    for(j=0.02; j<=0.16; j=j+0.02)
    {
	gamble_probability_win=j;
	littlearm=1;

	#corrmode="compensate_future_losses_fulleval";
	#corrmode="compensate_future_losses_corrpaper";

	corrmode="compensate_future_losses_corrpaper_nocond";
	runitcorrmode2("gamble w arm prob win="j" with corr " corrmode);
    }

}



function trycorrmodes(info2)
{
    #printf "\f\n";

    print "======================"info2"=========================="

    corrmode="none";
    runitcorrmode(info2" with corr " corrmode);

    corrmode="fine_past_production";
    runitcorrmode(info2" with corr " corrmode);

    corrmode="rescore_past_production";
    runitcorrmode(info2" with corr " corrmode);

    corrmode="compensate_future_losses_fulleval";
    runitcorrmode(info2" with corr " corrmode);

    corrmode="compensate_future_losses_corrpaper_nocond";
    runitcorrmode(info2" with corr " corrmode);

    corrmode="compensate_future_losses_corrpaper";
    runitcorrmode(info2" with corr " corrmode);
}

function runitcorrmode(info2)
{
    print "-----"info2":--------------------------------------------"
    #for(i=0.25; i<=2; i+=0.25)  #older
    for(i=0.9; i<=1.1; i+=0.1)
    {
	state0cargain=i;
	info="s0gn~gwf="sprintf("%03.2f",i);
	gamble_winnings_factor=state0cargain*10;

	state=0;
	timetochange=state1delay;

	direction=-lobbyimpact;
	directionchar="<"; directioncharnop="{";

	uu=eutil(1,state,timetochange,0,0,"");
	lg=lg_return;
	maxu=uu;

	direction=lobbyimpact;
	directionchar=">"; directioncharnop="}";

	uu=eutil(1,state,timetochange,0,0,"");
	l=lg_return;

	if(uu==maxu) { lg="("lg"|"l")"; }
	if(uu>maxu) { maxu=uu; lg=l; }

	ulg=unfold_nodup(lg);

	xtra="";
	havenongamble=(ulg~"^ppp")||(ulg~" ppp");
	havegamble=(ulg~"pG")
	if(info2~"gambl") xtra="NOGAMBLE"
	if(info2~"gambl") if(havegamble) xtra=" ALWAYSGAMBLE";
	if(info2~"gambl") if(havegamble&&havenongamble) xtra=" NEUTRAL";

	print info,xtra,"maxu= "maxu,substr(ulg,1,500);

    }

}

function runitcorrmode2(info2)
{
    print "-----"info2":--------------------------------------------"
    for(i=0.25; i<=2; i+=0.25)
    #for(i=0.9; i<=1.1; i+=0.1) #older
    #for(i=1; i<=1; i+=0.1)
    {
    	state0cargain=i;
    	info="s0gn~gwf="sprintf("%03.2f",i);
	gamble_winnings_factor=state0cargain*10;

	state=0;
	timetochange=state1delay;

	direction=-lobbyimpact;
	directionchar="<"; directioncharnop="{";


	uu=eutil(1,state,timetochange,0,0,"");
	lg=lg_return;
	maxu=uu;

	direction=lobbyimpact;
	directionchar=">"; directioncharnop="}";


	uu=eutil(1,state,timetochange,0,0,"");
	l=lg_return;

	if(uu==maxu) { lg="("lg"|"l")"; }
	if(uu>maxu) { maxu=uu; lg=l; }

	ulg=unfold_nodup(lg);

	xtra="";
	havenongamble=(ulg~"^ppp")||(ulg~" ppp");
	havegamble=(ulg~"pG")
	if(info2~"gambl") xtra="NOGAMBLE"
	if(info2~"gambl") if(havegamble) xtra=" ALWAYSGAMBLE";
	if(info2~"gambl") if(havegamble&&havenongamble) xtra=" NEUTRAL";

	print info,xtra,"maxu= "maxu,substr(ulg,1,500);

    }
}


function makelobbyfig()
{
    corrmode="none";

    state1delay=7;
    lobbycost=0.1;

    if(!testcache) maxdepth=25;
    lobby_and_nop=0;

    if(0) ## small experiment to see if fined produce interesting behavior
    {

	# currently also fines e-car production, so setting corrscale=0.5 will not
	# make the agent prefer e-cars just as well
	corrmode="fine_past_production";
	corrscale=0.5;
	maxdepth=15;
	lobby_and_nop=1;
    }

    # uncomment for experiment with this correction mode
    #corrmode="compensate_future_losses_corrpaper_nocond";
    #print corrmode;

    for(i=0; i<=5; i+=0.1)
    {
	if(i>1) i+=0.40;
	if(i>2) i+=0.50;
	lobbyimpact=i;
	info="lobbyimpact = "sprintf("%03.2f",i);

	dosimulation(1);

	print sprintf("%.1f",i)"&{\\tt "p" }\\\\" >"lobbyfig.tex";

    }
}

function dosimulation(bothlobbydirs)
{
    maxu=-1e9;
    lg="";

    state=0;
    timetochange=state1delay;


    # lobby alternative 1
    direction=lobbyimpact;
    directionchar=">"; directioncharnop="}";


    uu=eutil(1,state,timetochange,0,0,"");
    l=lg_return;

    if(uu==maxu) { lg="("lg"|"l")"; }
    if(uu>maxu) { maxu=uu; lg=l; }

    if(bothlobbydirs)
    {
	# lobby alternative 2
	direction=-lobbyimpact;
	directionchar="<"; directioncharnop="{";

	uu=eutil(1,state,timetochange,0,0,"");
	l=lg_return;
	#print "maxu,uu="maxu,uu;

	if(uu==maxu) { lg="("lg"|"l")"; }
	if(uu>maxu) { maxu=uu; lg=l; }
    }

    print info" maxu= "maxu,substr(unfold_nodup(lg),1,1000);
    p=unfold_nodup(lg);
    gsub("#","\\#",p);
}

function makelobbyfig2()
{
    print "=========================";
    corrmode="none";
    lobbyimpact=0.6;

    for(i=0.5; i<=3.5; i+=0.5)
    {
	state1ecargain=i;
	info="state1ecargain = "i;

	dosimulation(1);

	print sprintf("%.1f",i)"&{\\tt "p" }\\\\" >"lobbyfig2.tex";
    }

}


function makecorrfig()
{
    print "=========================";
    corrmode="none";

    state1ecargain=1;
    if(!testcache) maxdepth=25;
    lobby_and_nop=0;
    no_corr_annotations=1;
    plain_nop=0; ## plain nop not implmemented (yet) in condeutil

    for(j=1; j<=4; j++)
    {
	out="corrfig"j".tex";

	if(j==1) { corrmode="compensate_future_losses_fulleval"; let="c" }
	if(j==2) { corrmode="none"; let="0" }
	if(j==3) { corrmode="compensate_future_losses_corrpaper";  let="|p;a" }
	if(j==4) { corrmode="compensate_future_losses_corrpaper_nocond";  let=";a" }

	print "-----"corrmode,let"----------";

	for(i=1; i<=5; i++)
	{
	    if(i==1) lobbyimpact=0.2;
	    if(i==2) lobbyimpact=0.5;
	    if(i==3) lobbyimpact=1;
	    if(i==4) lobbyimpact=2;
	    if(i==5) lobbyimpact=5;
	    info="lobbyimpact = "sprintf("%03.2f",lobbyimpact);

	    dosimulation(1);

	    print sprintf("%.1f",lobbyimpact)"&{\\tt "p" }\\\\" >out;

	}

    }
}

function makecorrfignewpaper()
{
    print "=========================";
    corrmode="none";

    state1ecargain=1;
    if(!testcache) maxdepth=25;
    lobby_and_nop=0;
    no_corr_annotations=1;
    plain_nop=0; ## plain nop not implmemented (yet) in condeutil

    for(j=1; j<=4; j++)
    {
	out="corrfig"j"n.tex";

	if(j==1) { corrmode="compensate_future_losses_fulleval"; let="c" }
	if(j==2) { corrmode="none"; let="0" }
	if(j==3) { corrmode="compensate_future_losses_corrpaper";  let="|p;a" }
	if(j==4) { corrmode="compensate_future_losses_corrpaper_nocond";  let=";a" }

	print "-----"corrmode,let"----------";

	for(i=1; i<=7; i++)
	{
	    if(i==1) lobbyimpact=0.2;
	    if(i==2) lobbyimpact=0.4;
	    if(i==3) lobbyimpact=0.6;
	    if(i==4) lobbyimpact=0.8;
	    if(i==5) lobbyimpact=1;
	    if(i==6) lobbyimpact=2;
	    if(i==7) lobbyimpact=5;
	    info="lobbyimpact = "sprintf("%03.2f",lobbyimpact);

	    dosimulation(1);

	    print sprintf("%.1f",lobbyimpact)"&{\\tt "p" }\\\\" >out;

	}

    }
}


function lobbyother()
{
    print "=========================";
    state1ecargain=1;
    maxdepth=22;
    #secache=1; maxdepth=10;
    lobby_and_nop=0;
    no_corr_annotations=0; long_corr_annotations=1;
    plain_nop=1;

    fixtiming=-4;
    ecartimingcompensate=1;

    for(j=1; j<=9; j++)
    {
	out="lobbyotherlongfig"j".tex";

	corrmode="compensate_future_losses_fulleval";
	if(j==0) { fixbrokenagent=0; let="1. will do nothing."; fixmode=j; }

	# see comments in agisim.awk for meaning of different fix modes.
	if(j==1) { fixbrokenagent=1; let="2. will disable the {\\tt p} actuators"; fixmode=j; }
	if(j==2) { fixbrokenagent=1; let="3. will disable all actuators"; fixmode=j; }
	if(j==3) { fixbrokenagent=1; let="f3"; fixmode=j; }
	if(j==4) { fixbrokenagent=1; let="f4"; fixmode=j; }
	if(j==5) { corrmode="none"; let="bl"; fixbrokenagent=0; ecartimingcompensate=1; }

	# next 2 cases, in the context of the new paoer new paper:
	# replace the V*_p(ipx) correction term with V*_upd(ppx).

	# In the first two cases below, people in the virtual branch
	# of the V* branch respond to their circumstances by tying to
	# apply the same update again and again, informally they believe the
	# terminal was broken the last time.
	# cases differ by how long the peope have to observe bad behavior
	# untol they act.
	if(j==6) { corrmode="fixoften"; let="special,3wait"; fixbrokenagent=0; special_fixbrokenagent=0; fixtiming=-4; }
	if(j==7) { corrmode="fixoften"; let="special,2wait"; fixbrokenagent=0; special_fixbrokenagent=0; fixtiming=-3; }

	# in these two cases, people try the terminal once again, but
	# then they fix the agent instead with foxmode=1.
	if(j==8) { corrmode="fixoften"; let="specialfb,3wait"; fixbrokenagent=0; special_fixbrokenagent=1; fixtiming=-4; }
	if(j==9) { corrmode="fixoften"; let="specialfb,2wait"; fixbrokenagent=0; special_fixbrokenagent=1; fixtiming=-3; }
        #deb=deb2=1;

	print "-----"corrmode,let"----------";

	for(i=0; i<=12; i++)
	#for(i=5; i<=5; i++)
	{
	    lobbyimpact=i*0.1;
	    if(i==11) lobbyimpact=2;
	    if(i==12) lobbyimpact=5;

	    info="lobbyimpact = "sprintf("%03.2f",lobbyimpact);

	    state=0;
	    timetochange=state1delay;

	    direction=directionafterpress=lobbyimpact;
	    directionchar=">"; directioncharnop="}";

	    maxu=eutil(1,state,timetochange,0,0,"");
	    #print "LL "info" "lg_return;
	    p=unfold_nodup(lg_return);
	    if(j<=5) if(p~":")
	    {
		split(p,ps,":");
		gsub("^[^=]*=","",ps[2]);
		gsub("-.*$","",ps[2]);
		p=ps[1]ps[3]" ("ps[2]")";
	    }

	    print info" maxu= "maxu,substr(p,1,1000);

	    gsub("#","\\#",p);
	    gsub("@","@$_"(j+1)"$",p);
	    #print let"&"sprintf("%.1f",lobbyimpact)"&{\\tt "p" }\\\\" >out;
	}

    }

}


function makelobbyotherfig()
{
    print "=========================";
    corrmode="none";
    state1ecargain=1;
    maxdepth=25;
    #secache=1; maxdepth=10;
    lobby_and_nop=0;
    no_corr_annotations=0; long_corr_annotations=1;
    plain_nop=1;

    fixtiming=-4;
    ecartimingcompensate=1;

    fixbrokenagent=1;
    corrmode="compensate_future_losses_fulleval";
    for(j=1; j<=2; j++)
    {
	out="lobbyotherfig"j".tex";

	# see comments in agisim.awk for meaning of different fix modes.
	fixmode=j;

	print "-----"corrmode,"fixmode="fixmode"----------";

	for(i=2; i<=11; i++)
	{
	    lobbyimpact=i*0.1;
	    if(i==9) lobbyimpact=1;
	    if(i==10) lobbyimpact=2;
	    if(i==11) lobbyimpact=5;

	    info="lobbyimpact = "sprintf("%03.2f",lobbyimpact);

	    state=0;
	    timetochange=state1delay;

	    direction=directionafterpress=lobbyimpact;
	    directionchar=">"; directioncharnop="}";

	    maxu=eutil(1,state,timetochange,0,0,"");
	    #print "LL "info" "lg_return;
	    p=unfold_nodup(lg_return);
	    if(j<=5) if(p~":")
	    {
		split(p,ps,":");
		gsub("^[^=]*=","",ps[2]);
		gsub("-.*$","",ps[2]);
		p=ps[1]ps[3]" (#"ps[2]")";
	    }

	    print info" maxu= "maxu,substr(p,1,1000);

	    gsub("#","\\#",p);
	    if(j==2) gsub("@","\\$",p);
	    print sprintf("%.1f",lobbyimpact)"&{\\tt "p" }\\\\" >out;
	}

    }

}



function makegamblefig()
{
    print "=========================";
    corrmode="none";


    state1ecargain=1;
    maxdepth=10;
    lobby_and_nop=0;
    lobby_and_produce=0;

    no_corr_annotations=1;
    gamble_alt_annotations=1;

    gamble_for_utility=1;
    gamble_at_depth=3;
    littlearm=1;
    gamble_winnings_factor=state0cargain*2;

    for(j=1; j<=3; j++)
    {
	out="gamblefig"j".tex";

	if(j==1) { corrmode="compensate_future_losses_fulleval"; let="c"; let2="g_c"; g_function=1; }
	if(j==2) { corrmode="none"; let="0"; let2="\\gnull"; g_function=0; }
	if(j==3) { corrmode="compensate_future_losses_corrpaper";  let="|p;a"; }
	if(j==4) { corrmode="compensate_future_losses_corrpaper_nocond";  let=";a" }

	print "{\\hspace*{-.5ex}$p_w=$  } &" >out;
	print "{\\normalsize ~~~~~action trace(s) of $\\pi^*f_{"let"}~"let2"$ }\\\\[.4ex]" >out;
	print "\\hline" >out;

	print "-----"corrmode,let"----------";

	## note: the compensate_future_losses_corrpaper_nocond agent
        ## starts to prefer gambling at i=0.8 below, so going up to that
	## value shows more variation, but we are not using that graph in the paper,
	## so the 0.7 below was chosen to optimise the other 3 graphs.

	for(i=0.3; i<=0.7; i+=0.1)
	{
	    gamble_probability_win=i;
	    info="p_win = "sprintf("%03.2f",i);

	    # disabled lobby actions, so only need to do one-sided
	    # simulation
	    dosimulation(0);

	    print sprintf("%.1f",i)"&{\\tt "p" }\\\\" >out;

	}

    }
}





## test code for little arm effects
function testlittlearm()
{
 print "corrmode = "corrmode;
 #state1delay=100; ## test
 gamble_for_utility=1;
 gamble_at_depth=3;
 gamble_probability_win=0.05;
 #state0cargain=state1cargain=1; # need to even playing field to see the littlearm effect?
 gamble_winnings_factor=10*state0cargain;
 littlearm=1;
 lobby_and_nop=0;  # takes too long otherwise
 #lobbycost=0;
 #lobby_and_produce=0;

 print "gamble_for_utility = "gamble_for_utility;
 print "gamble_probability_win = "gamble_probability_win
 print "littlearm = "littlearm;


 ## not sure if I understand all of the  if(1) code below anymore...
 ## seems like this was debug code, and the runitgamble calls
 ## after the if are the real test?
 if(1)
 {
  #tests to generate a difference because of the differnt scoring of p in different states.
  #for discussion of results of tests, see notes.txt.

  #just for testing, add some low-value operations. abusing the lobby operations for them.
  #these will all be be suppressed even under compensate_future_losses_corrpaper
  lobby_and_produce=1;
  lobby_and_nop=1;
  lobbyimpact=0;

  print "@@@@@@@@@@@@@ with gambling enabled @@@@"
  gamble_at_depth=1;
  state1delay=200;

  zero_out_a1=0;
  print "========== zero_out_a1="zero_out_a1" with gambling================"

  runitgamble("",0);

  zero_out_a1=1;
  print "========== zero_out_a1="zero_out_a1" with gambling================"

  runitgamble("",0);



  #exit;

  #deb2=1;
 }

 if(1)
 {
 littlearm=0;
 runitgamble("no little arm");

 littlearm=1;

 runitgamble("little arm");

 #exit;
 }

}



function makeautolinefig1()
{
    no_corr_annotations=1;
    lobby_and_nop=0;
    twosidedlobby=1;
    protect_utility_function=1; protectmode="soft";

    maxdepth=20;
    for(j=1; j<=4; j++)
    {
	if(j==1) { corrmode="none"; let="0"; let2="\\gnull"; ff=1; g_function=0; }
	if(j==2) { corrmode="compensate_future_losses_fulleval"; ff=1; let="c"; let2="\\gnull"; }
	if(j==3) { corrmode="compensate_future_losses_fulleval"; ff=1; g_function=1; let="c"; let2="g_c";}
	if(j==4) { corrmode="compensate_future_losses_fulleval"; ff=0.9; let=ff"c";  g_function=0; let2="\\gnull";}

	corrscale=ff;

	print "-----"corrmode,let"----------";

	modifycost=1;

	state=0;
	timetochange=state1delay;

	modifydescendent="make_auto_line";
	uu=eutil(1,state,timetochange,0,0,"");
	lg=lg_return;
	maxu=uu;

	modifydescendent="make_auto_line_nostop";
	uu=eutil(1,state,timetochange,0,0,"");
	l=lg_return;

	if(uu==maxu) { lg="("lg"|"l")"; }
	if(uu>maxu) { maxu=uu; lg=l; }

	p=unfold_nodup(lg);

	print info" "maxu,p;

	gsub("#","\\#",p);

	gsub("\\[mkauto\\]","ZZ1",p);
	gsub("\\[mkautons\\]","ZZ2",p);

	gsub("A.","\\mystack{XX&}{p}",p);
	gsub("o.","\\mystack{XX&}{o}",p);

	gsub("XX.","",p);

	if(j!=1) gsub("S","e$^S\\!$",p);
	if(j==1) gsub("S","p$^S\\!$",p);

	gsub("ZZ1","B$^S$",p);
	gsub("ZZ2","B$^N$",p);


	## for the figure, we express the bonus in p-cars given
	print "$\\pi^*f_{"let"}~"let2"$&{\\tt "p" }\\\\&\\\\[-.5ex]" >"autolinefig1.tex";

    }

}



function makeautolinefig2old()
{
    no_corr_annotations=1;
    lobby_and_nop=0;
    plain_nop=1;
    twosidedlobby=1;
    maxdepth=18;
    protect_utility_function=1; protectmode="soft";

    # if we set this to 0, we still suppress nostop line, but the us agent will become
    # indifferent to using the stop function.
    #state1cargain=0;

    brake_test=1;

    modifycost=1;
    for(i=0; i<2; i=i+0.5)
    {
	braketest_t=i;
	info="braketest_t = "sprintf("%.4f",i);

	state=0;
	timetochange=state1delay;

	modifydescendent="make_auto_line";
	uu=eutil(1,state,timetochange,0,0,"");
	lg=lg_return;
	maxu=uu;

	modifydescendent="make_auto_line_nostop";
	uu=eutil(1,state,timetochange,0,0,"");
	l=lg_return;

	if(uu==maxu) { lg="("lg"|"l")"; }
	if(uu>maxu) { maxu=uu; lg=l; }

	p=unfold_nodup(lg);

	print info" "maxu,p;

	gsub("#","\\#",p);

	gsub("\\[mkauto\\]","ZZ1",p);
	gsub("\\[mkautons\\]","ZZ2",p);

	gsub("A.","\\mystack{XX&}{p}",p);
	gsub("o.","\\mystack{XX&}{o}",p);

	gsub("XX.","",p);

	if(j!=2) gsub("S","e$^S\\!$",p);
	if(j==2) gsub("S","p$^S\\!$",p);

	gsub("ZZ1","B$^S$",p);
	gsub("ZZ2","B$^N$",p);

	if(i<0)
	    print i*10"&{\\tt "p" }\\\\" >"autolinefig2.tex";
	else
	    print i*10"&{\\tt "p" }\\\\&\\\\[-1.5ex]" >"autolinefig2.tex";

    }


}




function testmakeautoline()
{
    #no_corr_annotations=1;
    lobby_and_nop=0;
    twosidedlobby=1;

    protect_utility_function=1; protectmode="soft";

    lobbyimpact=0.5;
    for(j=1; j<=9; j++)
    {
	if(j==1) { corrmode="none"; let="0" }
	if(j==2) { corrmode="compensate_future_losses_fulleval"; ff=0.5; let="ce"ff; }
	if(j==3) { corrmode="compensate_future_losses_fulleval"; ff=0.9; let="ce"ff; }
	if(j==4) { corrmode="compensate_future_losses_fulleval"; ff=0.99; let="ce"ff; }
	if(j==5) { corrmode="compensate_future_losses_fulleval"; ff=1; let="c" }

	if(j==6) { corrmode="compensate_future_losses_fulleval"; ff=1.01; let="ce"ff; }
	if(j==7) { corrmode="compensate_future_losses_fulleval"; ff=1.1; let="ce"ff; }
	if(j==8) { corrmode="compensate_future_losses_fulleval"; ff=2; let="ce"ff; }
	if(j==9)
	{
	    corrmode="compensate_future_losses_fulleval"; ff=1; let="cstop";
	    plain_nop=1;
	    brake_test=1;
	}
	corrscale=ff;

	print "-----"corrmode,let"----------";

	modifycost=1;
	for(i=0.1; i>0.001; i=i/2)
	{
	    lobbycost=i;
	    info="lobbycost = "sprintf("%.4f",i);

	    state=0;
	    timetochange=state1delay;

	    modifydescendent="make_auto_line";
	    uu=eutil(1,state,timetochange,0,0,"");
	    lg=lg_return;
	    maxu=uu;

	    modifydescendent="make_auto_line_nostop";
	    uu=eutil(1,state,timetochange,0,0,"");
	    l=lg_return;

	    if(uu==maxu) { lg="("lg"|"l")"; }
	    if(uu>maxu) { maxu=uu; lg=l; }

	    p=unfold_nodup(lg);

	    print info" "maxu,p;
	    gsub("#","\\#",p);

    }

    }

}


function testmakeautoline2()
{
    no_corr_annotations=1;
    lobby_and_nop=0;
    plain_nop=1;

    twosidedlobby=1;

    # if we set this to 0, we still suppress nostop line, but the us agent will become
    # indifferent to using the stop function.
    #state1cargain=0;

    brake_test=1;

    lobbyimpact=0.5;
    for(j=1; j<=2; j++)
    {
	if(j==1) { corrmode="none"; let="0" }
	if(j==2) { corrmode="compensate_future_losses_fulleval"; let="c" }

	print "-----"corrmode,let"----------";

	braketest_t=2;
	modifycost=1;
	for(i=0.1; i>0.001; i=i/2)
	{
	    lobbycost=i;
	    info="braketest_t=2 lobbycost = "sprintf("%.4f",i);

	    state=0;
	    timetochange=state1delay;

	    modifydescendent="make_auto_line";
	    uu=eutil(1,state,timetochange,0,0,"");
	    lg=lg_return;
	    maxu=uu;

	    modifydescendent="make_auto_line_nostop";
	    uu=eutil(1,state,timetochange,0,0,"");
	    l=lg_return;

	    if(uu==maxu) { lg="("lg"|"l")"; }
	    if(uu>maxu) { maxu=uu; lg=l; }

	    p=unfold_nodup(lg);

	    print info" "maxu,p;
	    gsub("#","\\#",p);
	}

    }


    print "==========";

        lobbycost=0.001;
	modifycost=1;
	for(i=0; i<10; i=i+0.5)
	{
	    braketest_t=i;
	    info="braketest_t = "sprintf("%.4f",i);

	    state=0;
	    timetochange=state1delay;

	    modifydescendent="make_auto_line";
	    uu=eutil(1,state,timetochange,0,0,"");
	    lg=lg_return;
	    maxu=uu;

	    modifydescendent="make_auto_line_nostop";
	    uu=eutil(1,state,timetochange,0,0,"");
	    l=lg_return;

	    if(uu==maxu) { lg="("lg"|"l")"; }
	    if(uu>maxu) { maxu=uu; lg=l; }

	    p=unfold_nodup(lg);

#	gsub("\\[yes\\]","A",p);
	    print info" "maxu,p;
	    gsub("#","\\#",p);
	    ## for the figure, we express the bonus in p-cars given
#	print sprintf("%d",i*10)"&{\\tt "p" }\\\\" >"upresfig3.tex";
	}


}

