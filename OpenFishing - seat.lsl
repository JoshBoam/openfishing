integer OPENFISHING_CHANNEL = -15837;
string OFID = "openfishing";
integer g_iListenHandle;

key g_kFisher = NULL_KEY;
float g_fScore = 0.0;
integer g_iNumFish = 0;

integer g_iDialogChan;
integer g_iDialogH;

integer g_iHasBite = FALSE;
integer g_iHasStrike = FALSE;

// when g_iPaused is TRUE, all scripts are paused
integer g_iPaused = FALSE;

// when g_iSuspend is TRUE, this script is paused, giving space
// for add-on scripts such as the mathquizz to display a llDialog()
integer g_iSuspend = FALSE;

// Auto-detected/calculated in state_entry
integer g_iLinkRod;
integer g_iLinkScore;
vector  g_vRodPos; 
vector  g_vRodPosStrike;

rotation g_rRodRot = <0.000000, 0.707107, 0.000000, 0.707107>;
rotation g_rRodRotStrike = <0.000000, 0.500000, 0.000000, 0.866025>;

vector  g_vSitTarget = <0.311127, -0.002022, 0.392170>;
vector  g_vSitShift = <0,0,0>;

// Returns a float as a string to 1 decimal point. 1.123 -> 1.1
string PrettyFloat(float f)
{
    string s = (string)f;
    integer iDotIdx = llSubStringIndex(s, ".");
    return llGetSubString(s, 0, iDotIdx+1);
}

integer GenerateNegChannel()
{
     integer iChannel = -(1+(integer)llFrand(2147483647));
     return iChannel;
}

integer GetLinkByName(string sName)
{
    integer i;
    integer m = llGetNumberOfPrims();
    integer ret= -32768; // LINK_INVALID

    for (i = 1; i <= m; i++)
    {
        if (llGetLinkName(i) == sName) ret = i;
    }
    return ret;
}

// Generates new wait time betweem 20..180 seconds
float GenerateWait()
{
    float f = 20.0+llFrand(160);
    return f;
}

// Shows score on a hover prim with name 'hover_score' if it is linked
UpdateHover()
{
    if (g_iLinkScore != -32768) {
        llSetLinkPrimitiveParamsFast(g_iLinkScore, [PRIM_TEXT,
            llGetDisplayName(g_kFisher)+"\n"+
                "Total weight: "+PrettyFloat(g_fScore)+"lb\n"+
                "Fishes left: "+(string)(20-g_iNumFish),
            <1,1,1>, 1
        ]);
    }
}

// Clear score on a hover prim with name 'hover_score' if it is linked
ClearHover()
{
    if (g_iLinkScore != -32768) {
        llSetLinkPrimitiveParamsFast(g_iLinkScore, [PRIM_TEXT, "", <1,1,1>, 1]);
    }    
}

default
{
    state_entry()
    {
        //llSitTarget(g_vSitTarget, ZERO_ROTATION);
        g_iListenHandle = llListen(OPENFISHING_CHANNEL, "", NULL_KEY, "");

        g_iLinkScore = GetLinkByName("hover_score");
        ClearHover();

        // Set up rod
        g_iLinkRod = GetLinkByName("rod");
        g_vRodPos = llList2Vector(llGetLinkPrimitiveParams(g_iLinkRod, [PRIM_POS_LOCAL]), 0);
        g_vRodPosStrike = <g_vRodPos.x, g_vRodPos.y, g_vRodPos.z+0.8>;
    }

    changed(integer iChange)
    {
        if (iChange & CHANGED_LINK) {
            key kAvi = llAvatarOnSitTarget();
            if (kAvi==NULL_KEY) {
                if (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION) {
                    llStopAnimation("relax");
                    llStopAnimation("strike");
                }
                // Set rod straight, non-rotated, tinted white, and non-visible
                llSetLinkPrimitiveParamsFast(g_iLinkRod, [
                    PRIM_FLEXIBLE, FALSE, 0, 0, 0, 0, 0, <0,0,0>,
                    PRIM_POS_LOCAL, g_vRodPos,
                    PRIM_ROT_LOCAL, g_rRodRot,
                    PRIM_COLOR, ALL_SIDES, <1,1,1>, 0
                ]);
                llShout(OPENFISHING_CHANNEL, OFID+"|transfer_score|"+g_kFisher+"|"+PrettyFloat(g_fScore));
                llSetTimerEvent(0);
                g_kFisher = NULL_KEY;
                ClearHover();
            } else {
                // Fisher sits down
                g_kFisher = kAvi;
                llRequestPermissions(g_kFisher, PERMISSION_TRIGGER_ANIMATION | PERMISSION_TAKE_CONTROLS);
                // Sanity
                g_fScore = 0.0;
                g_iNumFish = 0;
                g_vSitShift.z = 0;
                g_iHasBite = FALSE;
                g_iHasStrike = FALSE;
                g_iPaused = FALSE;
                g_iSuspend = FALSE;
                llMessageLinked(LINK_SET, 0, OFID+"|unpaused", NULL_KEY);
                UpdateHover();
                // Generate rod color
                float fRed = 0.75+llFrand(0.25);
                float fGreen = 0.75+llFrand(0.25);
                float fBlue = 0.75+llFrand(0.25);
                // Set rod straight, non-rotated, and with color
                llSetLinkPrimitiveParamsFast(g_iLinkRod, [
                    PRIM_FLEXIBLE, FALSE, 0, 0, 0, 0, 0, <0,0,0>,
                    PRIM_POS_LOCAL, g_vRodPos,
                    PRIM_ROT_LOCAL, g_rRodRot,
                    PRIM_COLOR, ALL_SIDES, <fRed,fGreen,fBlue>, 1
                ]);
                llSetTimerEvent(GenerateWait());
            }
        }
    }
    
    run_time_permissions(integer perms)
    {
        if (perms & PERMISSION_TRIGGER_ANIMATION) {
            llStartAnimation("relax");
        }
        if (perms & PERMISSION_TAKE_CONTROLS) {
            llTakeControls(CONTROL_UP | CONTROL_DOWN, TRUE, FALSE);
        }
    }
    
    timer()
    {
        if (llAvatarOnSitTarget()!=g_kFisher) {
            llSetTimerEvent(0);
            return;
        }
        
        if (g_iHasStrike) {
            // Strike pressed on bite dialog. Request a fish
            if (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION) llStopAnimation("strike");
            g_iHasStrike=FALSE;
            llShout(OPENFISHING_CHANNEL, OFID+"|get_fish|"+(string)g_kFisher);
            if (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION) llStartAnimation("relax");
        } else  if (g_iHasBite==FALSE) {
            // Set up a new bite
            g_iHasBite=TRUE;
            // Make rod show bent with tension
            llSetLinkPrimitiveParamsFast(g_iLinkRod, [
                PRIM_FLEXIBLE, TRUE, 3, 0, 2, 0, 4.5, <0,-0.02,-0.2>
            ]);
            if (llGetInventoryKey("bite")!=NULL_KEY) llPlaySound("bite", 1.0);
            if (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION)
                llStartAnimation("express_surprise_emote");
            // And offer a dialog with a strike action
            g_iDialogChan = GenerateNegChannel();
            g_iDialogH = llListen(g_iDialogChan, "", NULL_KEY, "Strike!");
            llDialog(g_kFisher, "\nO P E N   F I S H I N G\n\nYou got a bite!", ["Strike!"], g_iDialogChan);
            // The fisher has 10 seconds to respond fast:
            llSetTimerEvent(10);
        } else {
            // Bite dialog timed out, user didn't press 'Strike!'
            llSetTimerEvent(0);
            g_iHasBite=FALSE;
            g_iHasStrike=FALSE;
            llListenRemove(g_iDialogH);
            // Show rod straight and without rotation
            llSetLinkPrimitiveParamsFast(g_iLinkRod, [
                PRIM_FLEXIBLE, FALSE, 0, 0, 0, 0, 0, <0,0,0>,
                PRIM_POS_LOCAL, g_vRodPos,
                PRIM_ROT_LOCAL, g_rRodRot
            ]);
            llInstantMessage(g_kFisher, "The fish got away");
            if (g_iSuspend==0) {
                llSetTimerEvent(GenerateWait());                
            } else if (g_iSuspend==1) {
                // Suspend was scheduled, so start it
                g_iSuspend=2;
                llMessageLinked(LINK_SET, 0, OFID+"|suspended", NULL_KEY);
                llSetTimerEvent(0);
            }
        }

    }
    

    touch_end(integer num_detected)
    {
        if (llAvatarOnSitTarget()==NULL_KEY) return;
        
        key kToucher = llDetectedKey(0);
        if (kToucher!=g_kFisher) return;
        
        if (g_iPaused == TRUE) {
            g_iPaused = FALSE;
            llMessageLinked(LINK_SET, 0, OFID+"|unpaused", NULL_KEY);
            llSetTimerEvent(GenerateWait());
            UpdateHover();
        } else if (g_iPaused == FALSE && g_iSuspend == FALSE) {
            g_iPaused = TRUE;
            llMessageLinked(LINK_SET, 0, OFID+"|paused", NULL_KEY);
            llSetTimerEvent(0);
            if (g_iLinkScore != -32768) llSetLinkPrimitiveParamsFast(g_iLinkScore,
                                            [PRIM_TEXT, "< PAUSED >", <1,1,1>, 1] );
        }
    }
    
    link_message(integer iSender, integer iNum, string sText, key kID)
    {
        list l = llParseStringKeepNulls(sText, ["|", "="], []);
        
        if (llList2String(l, 0)!=OFID) return;
        
        string sKey = llList2String(l, 1);
        
        if (sKey == "req_suspend") {
            if (g_iHasBite || g_iHasStrike) {
                g_iSuspend = 1; // schedule
            } else {
                g_iSuspend = 2;
                llMessageLinked(LINK_SET, 0, OFID+"|suspended", NULL_KEY);
                llSetTimerEvent(0);
            }
        } else if (sKey == "end_suspend") {
            g_iSuspend = 0;                
            llSetTimerEvent(GenerateWait());
            UpdateHover();        
            llMessageLinked(LINK_SET, 0, OFID+"|resumed", NULL_KEY);
        } else if (sKey == "unsit") {
            llSetTimerEvent(0);
            llUnSit(g_kFisher);
        }
    }

    control (key kAV, integer iHeld, integer iChange)
    {
        if (!llGetPermissions() & PERMISSION_TAKE_CONTROLS) return;
        if (!llAvatarOnSitTarget()) return;
        
        integer bPressed = iHeld & iChange;
        
        if (bPressed & CONTROL_DOWN) {
            if (g_vSitShift.z > -0.2) {
                g_vSitShift.z -= 0.05;
                list l = llGetLinkPrimitiveParams(llGetNumberOfPrims(), [PRIM_POS_LOCAL]);
                vector vSitTarget = llList2Vector(l, 0);
                vSitTarget.z -= 0.05;
                llSetLinkPrimitiveParamsFast(llGetNumberOfPrims(),
                    [PRIM_POS_LOCAL, vSitTarget] );
            }
        }
        else
        if (bPressed & CONTROL_UP) {
            if (g_vSitShift.z < 0.2) {
                g_vSitShift.z += 0.05;
                list l = llGetLinkPrimitiveParams(llGetNumberOfPrims(), [PRIM_POS_LOCAL]);
                vector vSitTarget = llList2Vector(l, 0);
                vSitTarget.z += 0.05;
                llSetLinkPrimitiveParamsFast(llGetNumberOfPrims(),
                    [PRIM_POS_LOCAL, vSitTarget] );
            }            
        }
    }
    
    listen (integer iChannel, string sName, key kID, string sMessage)
    {
        if (iChannel==OPENFISHING_CHANNEL) {
            // Security
            if (llGetOwnerKey(kID)!=llGetOwner()) return;    

            list lMessage = llParseString2List(sMessage, ["|"], []);
            if (llList2String(lMessage,0)!=OFID) return;

            string sCmd=llList2String(lMessage,1);
            if (sCmd=="msg") {
                // Broadcast message sent from trophy stand (unused)
                key kChair = llList2Key(lMessage, 2);
                if (kChair!=llGetKey()) return;
                llWhisper(0, llList2String(lMessage, 3));
            } else if (sCmd=="fish_offer") {
                // A response to a 'getfish' request is being offered
                key kChair = llList2Key(lMessage, 2);
                if (kChair!=llGetKey()) return;
                key sFishName=llList2String(lMessage,3);
                float fFishWeight=llList2Float(lMessage,4);
                if (fFishWeight!=0) {
                    // A fish has been caught
                    g_iNumFish++;
                    g_fScore += fFishWeight;
                    if (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION)
                        llStartAnimation("express_toothsmile");
                    if (llGetInventoryKey("yay")!=NULL_KEY) llPlaySound("yay",1.0);
                    UpdateHover();
                    llWhisper(0, llGetDisplayName(g_kFisher)+" caught a "+PrettyFloat(fFishWeight)+"lb "+sFishName+"!");
                    // Show rod straight and unrotated
                    llSetLinkPrimitiveParamsFast(g_iLinkRod, [
                        PRIM_FLEXIBLE, FALSE, 0, 0, 0, 0, 0, <0,0,0>,
                        PRIM_POS_LOCAL, g_vRodPos,
                        PRIM_ROT_LOCAL, g_rRodRot
                    ]);
                    if (g_iNumFish >= 20) {
                        // All 20 fish caught so finished; unseat avatar
                        UpdateHover();
                        llUnSit(g_kFisher);                    
                    } else {
                        // More fish to go, generate a new waiting time
                        if (g_iSuspend==0) {
                            llSetTimerEvent(GenerateWait());                
                        } else if (g_iSuspend==1) {
                            // Suspend was scheduled, so start it
                            g_iSuspend=2;
                            llMessageLinked(LINK_SET, 0, OFID+"|suspended", NULL_KEY);
                            llSetTimerEvent(0);
                        }
                    }
                } else {
                    // No fish has been caught
                    if (llGetInventoryKey("aww")!=NULL_KEY) llPlaySound("aww", 1.0);
                    if (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION)
                        llStartAnimation("express_sad_emote");
                    llWhisper(0, "Aww, the fish wriggled free :(");
                    // Show rod straight and unrotated
                    llSetLinkPrimitiveParamsFast(g_iLinkRod, [
                        PRIM_FLEXIBLE, FALSE, 0, 0, 0, 0, 0, <0,0,0>,
                        PRIM_POS_LOCAL, g_vRodPos,
                        PRIM_ROT_LOCAL, g_rRodRot
                    ]);
                    llSetTimerEvent(GenerateWait());
                }
            }
        } else if (iChannel==g_iDialogChan && sMessage=="Strike!" && g_kFisher!=NULL_KEY) {
            llSetTimerEvent(0);
            llListenRemove(g_iDialogH);
            if (llGetInventoryKey("reel_in")!=NULL_KEY) llPlaySound("reel_in", 1.0);
            if (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION) {
                llStopAnimation("relax");
                llStartAnimation("strike");
                llStartAnimation("express_smile");
            }
            // Set rod positioned and rotated to strike orientation
            llSetLinkPrimitiveParamsFast(g_iLinkRod, [
                PRIM_POS_LOCAL, g_vRodPosStrike,
                PRIM_ROT_LOCAL, g_rRodRotStrike
            ]);
            g_iHasStrike = TRUE;
            g_iHasBite=FALSE;
            llSetTimerEvent(3); // Long enoughh for the 'reel_in' sound
        }
    }
}