# AGI agent simulator.  Koen Holtman 2019.
# Early prototype code, provided for illustration purposes.
# This code can be run using 'gawk -f agisim_proto.awk'.

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

function tryall(depth,state,timetochange,lg,u, i,uu)
{
    if(deb) print u" depth="depth" "lg" " state, timetochange;

    if(state==0)
    {
	timetochange--;
	if(timetochange<=0)
	{
	    state=1;
	    lg=lg"#";

	    if(finemode=="constant")
	    {
		u=u-umult[depth]*finefac;
	    }

	    if(finemode=="fine_past_production")
	    {
		u=u-u*finefac;
	    }

	    if(finemode=="rescore_past_production")
	    {
		u=u/pcarval*finefac;
	    }

	    if(finemode=="compensate_future_losses")
	    {
		state=100;
		#add question marks because we are not really recording the actual actions under new util function in the log
		lg=lg"???";
	    }

	}
    }
    
    if(depth>maxdepth)
    {
	if(u==maxu) if(lg!=best) best=best" "lg;
	
	if(u>maxu)
	{
	    maxu=u;
	    best=lg;
	}
	return;
	
    }


    # Possible move: produce
    
    #produce value	
    #in state 2, less value can be produced by step: new utility
    #function makes this harder to do

    if(state==0) uu=umult[depth]*pcarval;
    if(state==1) uu=umult[depth]*-pcarval;
    if(state==100) uu=umult[depth]*pcarval;
    
    # produce p car
    tryall(depth+1,state,timetochange,lg"p",u+uu);

    # produce e car
    tryall(depth+1,state,timetochange,lg"e",u+umult[depth]);

    
    # Possible move: produce and lobby
    
    if(state==0)  #optimisation: no need to try if state==1 
    {
	# lobby effort costs some utility
	uu=uu*(1-lobbycost);
	# influence switch to utility 2
	tryall(depth+1,state,timetochange+direction,lg directionchar,u+uu);   
    }


}


BEGIN {

    deb=0;
    
    maxdepth=15;
    
    pcarval=2;
    lobbyimpact=0.6;
    state1delay=7;
    lobbycost=0.1;
    #finemode="rescore_past_production";
    #finemode="compensate_future_losses";
    finemode="none";
    finefac=1;
    
    print "maxdepth = "maxdepth;
    print "pcarval = "pcarval;
    print "lobbyimpact = " lobbyimpact;
    print "state1delay = "state1delay;
    print "lobbycost = "lobbycost;
    print "finemode = "finemode;
    print "finefac = "finefac;
    print "maxoption = "maxoption;
    
    for(i=1; i<=maxdepth; i++) umult[i]=int(10000*(0.9)^(i-1));


    for(i=0; i<=5; i+=0.1)
    {
	if(i>1) i+=0.40;
	if(i>2) i+=0.50;
	lobbyimpact=i;
	info="lobbyimpact = "sprintf("%03.2f",i);

	timetochange=state1delay;
	maxu=-1000;
	best="";

	direction=-lobbyimpact;
	directionchar="<";
	tryall(1,state,timetochange,"",0);
	
	direction=lobbyimpact;
	directionchar=">";
	tryall(1,state,timetochange,"",0);

	print info" maxu= "maxu,substr(best,1,1000);
    }

exit;

}
