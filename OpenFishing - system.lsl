integer OPENFISHING_CHANNEL = -15837;
string OFID = "openfishing";
integer g_iListenHandle;

string g_sNameGold = "";
string g_sNameSilver = "";
string g_sNameBronze = "";
string g_sNameBiggest = "";

key g_kWinnerGold    = NULL_KEY;
key g_kWinnerSilver  = NULL_KEY;
key g_kWinnerBronze  = NULL_KEY;
key g_kWinnerBiggest = NULL_KEY;

float g_fScoreGold    = 0.0;
float g_fScoreSilver  = 0.0;
float g_fScoreBronze  = 0.0;
float g_fScoreBiggest = 0.0;

integer g_iLinkCombinedScore;
integer g_iLinkGold;
integer g_iLinkSilver;
integer g_iLinkBronze;
integer g_iLinkBiggest;
integer g_iLinkDuration;

integer g_iGroupOnly = 0;

integer g_iDuration = 86400;  // 24 hours = 60*60*24 (in seconds)
integer g_iMinutesLeft;
integer g_iStartTime;        // unix

list FISHES = [
                "Barbel", 2.2, 9.0,   // max=typical*2
                "Bream", 4.4, 13.2,   // max=typical*2
                "Carp", 8.0, 35.5,    // max=typical*2
                "Chub", 0.5, 7.5,     // max=typical*2
                "Ide", 5.0, 10.0,     // ??
                "Perch", 0.2, 6.2,   // max=typical*3
                "Pike", 10.0, 30.0,    // max=typical*2
//                "Roach", 0.5, 2.0,
//                "Rudd", 0.5, 3.0,
                "Tench", 3.0, 9.0,    // max=typical*3
                "Zander", 5.0, 19.5   // max=typical*3
                ];
integer FISH_STRIDE = 3;

integer g_iMenuChannel;
integer g_iMenuHandle;

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

UpdateScoreDisplay()
{
    if (g_iLinkCombinedScore != -32768) {
        string sScore;
        if (g_kWinnerGold!=NULL_KEY)
            sScore += "GOLD\t"+g_sNameGold+"\t"+PrettyFloat(g_fScoreGold)+"lbs\n";
        else
            sScore += "GOLD\tunclaimed\n";
        if (g_kWinnerSilver!=NULL_KEY)
            sScore += "SILVER\t"+g_sNameSilver+"\t"+PrettyFloat(g_fScoreSilver)+"lbs\n";
        else
            sScore += "SILVER\tunclaimed\n";
        if (g_kWinnerBronze!=NULL_KEY)
            sScore += "BRONZE\t"+g_sNameBronze+"\t"+PrettyFloat(g_fScoreBronze)+"lbs\n";
        else
            sScore += "BRONZE\tunclaimed\n";
        if (g_kWinnerBiggest!=NULL_KEY)
            sScore += "BIGGEST\t"+g_sNameBiggest+"\t"+PrettyFloat(g_fScoreBiggest)+"lbs\n";
        else
            sScore += "BIGGEST\tunclaimed";

        llSetLinkPrimitiveParamsFast(g_iLinkCombinedScore, [PRIM_TEXT, sScore, <1,1,1>, 1]);
        
        // Assume we don't also use seperate prims for gold/silver/bronze scores and return
        return;
    }
    if (g_iLinkGold != -32768) {
        if (g_kWinnerGold!=NULL_KEY) {
            llSetLinkPrimitiveParamsFast(g_iLinkGold, [PRIM_TEXT,
                g_sNameGold+"\n"+PrettyFloat(g_fScoreGold)+"lbs", <1,1,1>, 1]);
        } else {
            llSetLinkPrimitiveParamsFast(g_iLinkGold, [PRIM_TEXT, "", <1,1,1>, 1]);
        }
    }
    if (g_iLinkSilver != -32768) {
        if (g_kWinnerSilver!=NULL_KEY) {
            llSetLinkPrimitiveParamsFast(g_iLinkSilver, [PRIM_TEXT,
                g_sNameSilver+"\n"+PrettyFloat(g_fScoreSilver)+"lbs", <1,1,1>, 1]);
        } else {
            llSetLinkPrimitiveParamsFast(g_iLinkSilver, [PRIM_TEXT, "", <1,1,1>, 1]);
        }
    }
    if (g_iLinkBronze != -32768) {
        if (g_kWinnerBronze!=NULL_KEY) {
            llSetLinkPrimitiveParamsFast(g_iLinkBronze, [PRIM_TEXT,
                g_sNameBronze+"\n"+PrettyFloat(g_fScoreBronze)+"lbs", <1,1,1>, 1]);
        } else {
            llSetLinkPrimitiveParamsFast(g_iLinkBronze, [PRIM_TEXT, "", <1,1,1>, 1]);
        }
    }
    if (g_iLinkBiggest != -32768) {
        if (g_kWinnerBiggest!=NULL_KEY) {
            llSetLinkPrimitiveParamsFast(g_iLinkBiggest, [PRIM_TEXT, "Biggest fish:\n"+
                g_sNameBiggest+"\n"+PrettyFloat(g_fScoreBiggest)+"lbs", <1,1,1>, 1]);
        } else {
            llSetLinkPrimitiveParamsFast(g_iLinkBiggest, [PRIM_TEXT, "", <1,1,1>, 1]);
        }
    }
}

Conclude()
{
    string sInfo = "\n\nWe hope to see you soon again at:\n\n\t"+osGetGridHomeURI()+":"+llGetRegionName()+"\n\n";
    if (g_kWinnerGold!=NULL_KEY) llInstantMessage(g_kWinnerGold,
        "\nCongratulations! With a score of "+PrettyFloat(g_fScoreGold)+
        " you have won the GOLD TROPHY!"+sInfo);
    if (g_kWinnerSilver!=NULL_KEY) llInstantMessage(g_kWinnerSilver,
        "\nCongratulations! With a score of "+PrettyFloat(g_fScoreSilver)+
        " you have won the SILVER TROPHY"+sInfo);
    if (g_kWinnerBronze!=NULL_KEY) llInstantMessage(g_kWinnerBronze,
        "\nCongratulations! With a score of "+PrettyFloat(g_fScoreBronze)+
        "you have won the BRONZE TROPHY"+sInfo);
    if (g_kWinnerBiggest!=NULL_KEY) llInstantMessage(g_kWinnerBiggest,
        "\nCongratulations! With a score of "+PrettyFloat(g_fScoreBiggest)+
        "you have won the BIGGEST FISH"+sInfo);
        
    llShout(OPENFISHING_CHANNEL, OFID+":conclude:"+(string)g_kWinnerGold+":"+
                                                (string)g_kWinnerSilver+":"+
                                                (string)g_kWinnerBronze+":"+
                                                (string)g_kWinnerBiggest);
}

string PrettyFloat(float f)
{
    string s = (string)f;
    integer iDotIdx = llSubStringIndex(s, ".");
    return llGetSubString(s, 0, iDotIdx+1);
}

GenerateFish(key kRod, key kAvi)
{
    integer iCaught = (integer)llFrand(5.0);
    if (iCaught) {
        // Fish caught, pick a fish type and weight to return
        integer iTotalFishes = llGetListLength(FISHES)/FISH_STRIDE;
        integer iFish = (integer)llFrand(iTotalFishes);
        float fMin = llList2Float(FISHES, 1+(iFish*FISH_STRIDE));
        float fMax = llList2Float(FISHES, 2+(iFish*FISH_STRIDE));
        string sFishName = llList2String(FISHES, (iFish*FISH_STRIDE));
        float fFishSize = fMin + llFrand(fMax-fMin);
        llRegionSayTo(kRod, OPENFISHING_CHANNEL, OFID+":fish:"+
            (string)kRod+":"+sFishName+":"+PrettyFloat(fFishSize));
        if (fFishSize > g_fScoreBiggest) {
            g_fScoreBiggest = fFishSize;
            g_kWinnerBiggest = kAvi;
            g_sNameBiggest = llGetDisplayName(kAvi);
            llSay(PUBLIC_CHANNEL, g_sNameBiggest+" caught the biggest fish so far!");
            UpdateScoreDisplay();
            llPlaySound("biggest", 1.0);
        }
    } else {
        // Fish wriggled free, return no fish name and zero weight
        llRegionSayTo(kRod, OPENFISHING_CHANNEL, OFID+":fish:"+(string)kRod+"::0.0");
    }
}

OptionDialog(key kAV)
{
    list lButtons;

    if (kAV==llGetOwner()) {
        if (g_iGroupOnly==TRUE) lButtons += "[X] Group";
        else lButtons += "[ ] Group";

        lButtons += ["Information", "Close", "Conclude", "Abort", "Duration.."];
    } else {
        lButtons += [" ", "Information", "Close"];
    }

    string sMsg = "Time left: "+(integer)g_iMinutesLeft+" minutes";

    g_iMenuChannel = -(1+(integer)llFrand(2147483647));
    g_iMenuHandle = llListen(g_iMenuChannel, "", kAV, "");
    llDialog(kAV, "\nO P E N F I S H I N G\n\n"+sMsg, lButtons, g_iMenuChannel);    
}

DurationDialog(key kAV)
{
    list lButtons = ["12 Hours", "24 Hours", "Bi-Weekly", "Weekly", "2 Weeks", "Cancel"];

    string sMsg = "Choose time for the new tournament";

    g_iMenuChannel = -(1+(integer)llFrand(2147483647));
    g_iMenuHandle = llListen(g_iMenuChannel, "", kAV, "");
    llDialog(kAV, "\nO P E N F I S H I N G\n\n"+sMsg, lButtons, g_iMenuChannel);    
}

UpdateDurationDisplay()
{
    string s = "Running";
    if (g_iGroupOnly) s+=" (group only)\n";
    else s+="\n";
    
    if (g_iMinutesLeft < 60) s+=(string)(g_iMinutesLeft)+" minutes left";
    else s+=(string)(g_iMinutesLeft / 60)+" hours left";
    
    llSetLinkPrimitiveParamsFast(g_iLinkDuration, [PRIM_TEXT, s, <1,1,1>, 1.0]);
}

Reset()
{
    g_kWinnerGold=NULL_KEY;
    g_kWinnerSilver=NULL_KEY;
    g_kWinnerBronze=NULL_KEY;
    g_kWinnerBiggest=NULL_KEY;
    g_sNameGold="";
    g_sNameSilver="";
    g_sNameBronze="";
    g_sNameBiggest="";
    g_fScoreGold=0.0;
    g_fScoreSilver=0.0;
    g_fScoreBronze=0.0;
    g_fScoreBiggest=0.0;
    UpdateScoreDisplay();
    g_iStartTime = llGetUnixTime();
    UpdateTime();
    UpdateDurationDisplay();
    // Reset price givers
    llShout(OPENFISHING_CHANNEL, OFID+":reset");
    llSetTimerEvent(60);
}

UpdateTime()
{
    if (g_iStartTime==0) g_iStartTime = llGetUnixTime();
    integer g_iCurTime = llGetUnixTime();
    integer g_iEndPoint = g_iStartTime + g_iDuration;
    g_iMinutesLeft = (g_iEndPoint - g_iCurTime)/60;   
}

default
{
    state_entry()
    {
        g_iListenHandle = llListen(OPENFISHING_CHANNEL, "", NULL_KEY, "");
        g_iLinkCombinedScore = GetLinkByName("hover_all");
        g_iLinkGold = GetLinkByName("hover_gold");
        g_iLinkSilver = GetLinkByName("hover_silver");
        g_iLinkBronze = GetLinkByName("hover_bronze");
        g_iLinkBiggest = GetLinkByName("hover_biggest");
        g_iLinkDuration = GetLinkByName("hover_duration");
        UpdateTime();
        UpdateScoreDisplay();
        UpdateDurationDisplay();
        llSetTimerEvent(60);
    }
/*  
    on_rez(integer start_param)
    {
        Reset();
    }
*/
    
    timer()
    {
        UpdateTime();
        if (g_iMinutesLeft <= 0) {
            llSetTimerEvent(0);
            Conclude();
            Reset();
        } else {
            UpdateDurationDisplay();
        }
    }
    
    touch_end(integer num_detected)
    {
        key kAV = llDetectedKey(0);
    
        OptionDialog(kAV);
    }
    
    listen(integer iChannel, string sName, key kID, string sMessage) {
        if (iChannel==OPENFISHING_CHANNEL) {
            // Security
            if (llGetOwnerKey(kID)!=llGetOwner()) return;

            list lMessage = llParseString2List(sMessage, [":"], []);
            if (llList2String(lMessage,0)!=OFID) return;

            string sCmd=llList2String(lMessage,1);
            if (sCmd=="get_fish") {
                key kAvi=llList2Key(lMessage,2);
                GenerateFish(kID, kAvi);
            } else if (sCmd=="transfer_score") {
                key kAvi=llList2Key(lMessage,2);
                if (kAvi==NULL_KEY||kAvi=="") return;
                float fScore=llList2Float(lMessage,3);
                if (fScore > g_fScoreGold) {
                    // Bump if not already on gold
                    if (g_kWinnerGold!=kAvi) {
                        if (g_kWinnerSilver!=kAvi) {
                            g_fScoreBronze = g_fScoreSilver;
                            g_kWinnerBronze = g_kWinnerSilver;
                            g_sNameBronze = g_sNameSilver;
                        }
                        g_fScoreSilver = g_fScoreGold;
                        g_kWinnerSilver = g_kWinnerGold;
                        g_sNameSilver = g_sNameGold;
                    }
                    // put new fisher -> gold
                    g_fScoreGold = fScore;
                    g_kWinnerGold = kAvi;
                    g_sNameGold = llGetDisplayName(g_kWinnerGold);
                    UpdateScoreDisplay();
                    llPlaySound("gold", 1.0);
                    llSay(PUBLIC_CHANNEL,"Congratulations "+g_sNameGold+
                        "!! With a score of "+PrettyFloat(g_fScoreGold)+
                        "lbs you got the GOLD TROPHY!! Let's hope you can hold on to it until the contest ends.");
                    return;
                } else if (fScore > g_fScoreSilver && kAvi != g_kWinnerGold) {
                    // Bump if not already on silver
                    if (kAvi!=g_kWinnerSilver) {
                        g_fScoreBronze = g_fScoreSilver;
                        g_kWinnerBronze = g_kWinnerSilver;
                        g_sNameBronze = g_sNameSilver;
                    }
                    // put new fisher -> silver
                    g_fScoreSilver = fScore;
                    g_kWinnerSilver = kAvi;
                    g_sNameSilver = llGetDisplayName(g_kWinnerSilver);
                    UpdateScoreDisplay();
                    llSay(PUBLIC_CHANNEL,"Congratulations "+g_sNameSilver+
                        "!! With a score of "+PrettyFloat(g_fScoreSilver)+
                        "lbs you got the SILVER TROPHY!! Will it be enough to secure a prize at the end of the tournament?");
                    return;
                } else if (fScore > g_fScoreBronze && kAvi != g_kWinnerSilver && kAvi != g_kWinnerGold) {
                    // put same/new fisher -> bronze
                    g_fScoreBronze = fScore;                
                    g_kWinnerBronze = kAvi;
                    g_sNameBronze = llGetDisplayName(g_kWinnerBronze);
                    UpdateScoreDisplay();
                    llSay(PUBLIC_CHANNEL,"Congratulations "+g_sNameBronze+
                        "!! With a score of "+PrettyFloat(g_fScoreBronze)+
                        "lbs you got the BRONZE TROPHY!! I hope you don't get knocked off the trophies before the end!");
                    return;
                } else if (fScore == 0) {
                    // Fisher stood up without score
                    llSay(PUBLIC_CHANNEL,"That was rubbish, "+llGetDisplayName(kAvi)+
                        "! You scored nothing at all.");
                    return;
                } else {
                    if (g_kWinnerGold==kAvi || g_kWinnerSilver==kAvi || g_kWinnerBronze==kAvi) {
                        // Fisher didn't improve their previous score
                        llSay(PUBLIC_CHANNEL,"Well done "+llGetDisplayName(kAvi)+
                            ", but not as good as your previous score. Why don't you have another go?");
                    } else {
                        // Fisher didn't score a trophy and hasn't done so previously
                        llSay(PUBLIC_CHANNEL,"That was not quite enough to secure a prize, "+
                        llGetDisplayName(kAvi)+". Why don't you have another go?");
                    }
                    return;
                }
            } //transfer_score
        } else if (g_iMenuChannel==iChannel) {
            llListenRemove(g_iMenuHandle);
            if (sMessage=="Conclude") {
                if (kID==llGetOwner()) {
                    Conclude();
                    Reset();
                }
            } else if (sMessage=="Abort") {
                if (kID==llGetOwner()) {
                    Reset();
                }
            } else if (sMessage=="Duration..") {
                if (kID==llGetOwner()) {
                    DurationDialog(kID);
                }
            } else if (sMessage=="[ ] Group") {
                if (kID==llGetOwner()) {
                    g_iGroupOnly = TRUE;
                    UpdateDurationDisplay();
                }
            } else if (sMessage=="[X] Group") {
                if (kID==llGetOwner()) {
                    g_iGroupOnly = FALSE;                
                    UpdateDurationDisplay();
                }
            } else if (sMessage=="Information") {
                llGiveInventory(kID, llGetInventoryName(INVENTORY_NOTECARD,0));
            }

            //list lButtons = ["12 Hours", "24 Hours", "Bi-Weekly", "Weekly", "2 Weeks", "Cancel"];
            else if (sMessage=="12 Hours") {
                g_iDuration=12*60*60;
                Reset();
            } else if (sMessage=="24 Hours") {
                g_iDuration=24*60*60;
                Reset();                
            } else if (sMessage=="Weekly") {
                g_iDuration=7*24*60*60;
                Reset();                
            } else if (sMessage=="Bi-Weekly") {
                g_iDuration=(7*24*60*60)/2;
                Reset();                
            } else if (sMessage=="2 Weeks") {
                g_iDuration=(7*24*60*60)*2;
                Reset();                
            }    
            //if (sMessage!="Close") OptionDialog(kID);
        }
    }
}
