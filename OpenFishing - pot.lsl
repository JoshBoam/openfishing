integer OPENFISHING_CHANNEL = -15837;
string  OFID = "openfishing";
integer g_iListenHandle;

integer g_iPrizeTotal;

// Calculated by script
integer g_iPrizeGold;
integer g_iPrizeSilver;
integer g_iPrizeBronze;
integer g_iPrizeBiggest;

// CONFIG FILE
// Percentages; These must add up to 100%
float g_iPercentGold    = 40;
float g_iPercentSilver  = 30;
float g_iPercentBronze  = 20;
float g_iPercentBiggest = 10;

// If 0, don't start a contest with a base prize
integer g_iStartAmount;

integer g_iAllowTopup = FALSE;

// If set, displays an additional subtitle
string g_sSubHover;

string g_sCurrency = " OS";  // Just aestethic. Change to your grid currency.

integer g_iInitialized = FALSE;

UpdateHover()
{
    string sHover = "OpenFishing Pot\n";
    if (g_sSubHover!="") sHover+=g_sSubHover+"\n";
    sHover+= " \nThis round total: "+(string)g_iPrizeTotal+g_sCurrency+"\n \n"+
             "Gold: "+(string)g_iPrizeGold+g_sCurrency+"\n"+
             "Silver: "+(string)g_iPrizeSilver+g_sCurrency+"\n"+
             "Bronze: "+(string)g_iPrizeBronze+g_sCurrency+"\n"+
             "Biggest catch: "+(string)g_iPrizeBiggest+g_sCurrency;
             
    llSetText(sHover, <1,1,1>, 1);
}

CalcPrizes()
{
    g_iPrizeGold = (integer)(((float)g_iPrizeTotal/100)*g_iPercentGold);
    g_iPrizeSilver = (integer)(((float)g_iPrizeTotal/100)*g_iPercentSilver);
    g_iPrizeBronze = (integer)(((float)g_iPrizeTotal/100)*g_iPercentBronze);
    g_iPrizeBiggest = (integer)(((float)g_iPrizeTotal/100)*g_iPercentBiggest);
    
    // Any rounding errors within a 1L negative margin are added to Gold
    integer iTotal = g_iPrizeGold+g_iPrizeSilver+g_iPrizeBronze+g_iPrizeBiggest;
    if (iTotal==(g_iPrizeTotal-1)) g_iPrizeGold += 1;
}

ParseConfig()
{   
    integer i = 0;
    for(i=1; i<=osGetNumberOfNotecardLines("pot.config"); i++) {
        string line = llStringTrim(osGetNotecardLine("pot.config", i), STRING_TRIM);
        list lPair = llParseString2List(line, ["="], []);
        string sSetting = llList2String(lPair, 0);
        if (llGetSubString(sSetting, 0, 0)!="#" || llGetSubString(sSetting, 0, 0)!="") {
            if (sSetting=="prize_gold") g_iPercentGold = llList2Float(lPair, 1);
            else if (sSetting=="prize_silver") g_iPercentSilver = llList2Float(lPair, 1);
            else if (sSetting=="prize_bronze") g_iPercentBronze = llList2Float(lPair, 1);
            else if (sSetting=="prize_biggest") g_iPercentBiggest = llList2Float(lPair, 1);
            else if (sSetting=="start_amount") g_iStartAmount = llList2Integer(lPair, 1);
            else if (sSetting=="sub_hover") g_sSubHover = llList2String(lPair, 1);
            else if (sSetting=="currency") g_sCurrency = " "+llList2String(lPair, 1);
            else if (sSetting=="allow_topup") {
                string sValue=llToLower(llList2String(lPair, 1));
                if (sValue=="true" || sValue=="yes" || sValue=="1") g_iAllowTopup=TRUE;
                else g_iAllowTopup=FALSE;
            }
        }
    }
    
    if ((g_iPercentGold+g_iPercentSilver+g_iPercentBronze+g_iPercentBiggest)!=100) {
        llOwnerSay("Configuration error: the prize percentages for prize_gold, prize_silver, "+
            "prize_bronze and prize_biggest don't add up to 100");
    }
    
    UpdateHover();
}

Reset()
{
    if (g_iStartAmount) g_iPrizeTotal=g_iStartAmount;
    else g_iPrizeTotal=0;
    CalcPrizes();
    UpdateHover();
    if (g_iAllowTopup) {
        llSetPayPrice(10, [1,5,10,20]);
        llSetClickAction(CLICK_ACTION_PAY);
    } else {
        llSetClickAction(CLICK_ACTION_TOUCH);            
    }
}

default
{
    state_entry()
    {
        ParseConfig();
        if (g_iStartAmount && g_iPrizeTotal==0) g_iPrizeTotal = g_iStartAmount;
        CalcPrizes();
        UpdateHover();
        
        g_iListenHandle = llListen(OPENFISHING_CHANNEL, "", NULL_KEY, "");
        
        if (g_iAllowTopup) {
            llSetPayPrice(10, [1,5,10,20]);
            llSetClickAction(CLICK_ACTION_PAY);
        } else {
            llSetClickAction(CLICK_ACTION_TOUCH);            
        }
        
        if ((llGetPermissions() & PERMISSION_DEBIT)==0) llRequestPermissions(llGetOwner(), PERMISSION_DEBIT);
    }
    
    run_time_permissions(integer what)
    {
        if (what & PERMISSION_DEBIT) {
            llOwnerSay("\nPot initialized\n\n"+
                        "Podex: No additional steps required\n"+
                        "OMC: Authorize the object on https://www.virwox.com\n"+
                        "Gloebit: Authorize the object (subscription) on https://www.gloebit.com\n\n");
        }
    }
    
    changed(integer what)
    {
        if (what & CHANGED_INVENTORY) {
            ParseConfig();
            CalcPrizes();
            UpdateHover();
        }
    }
    
    listen(integer iChannel, string sName, key kID, string sMessage)
    {
        // Security
        if (llGetOwnerKey(kID)!=llGetOwner()) return;
        
        list lMessage = llParseString2List(sMessage, [":"], []);
        if (llList2String(lMessage,0)!=OFID) return;

        string sCmd=llList2String(lMessage,1);
        if (sCmd=="conclude") {
            if ((llGetPermissions() & PERMISSION_DEBIT)==0) {
                llOwnerSay("Can't pay out: PERMISSION_DEBIT not granted");
                return;
            }
            llSetClickAction(CLICK_ACTION_TOUCH);
            llSetText("Paying out", <1,1,1>, 1);
            // Message received in the form of:
            // :payout:kGold:kSilver:kBronze:kBiggest
            key kWinner = llList2Key(lMessage, 2);
            if (kWinner!=NULL_KEY && kWinner!="" && g_iPrizeGold > 0) {
                llGiveMoney(kWinner, g_iPrizeGold);
                llInstantMessage(kWinner, "You won "+(string)g_iPrizeGold+g_sCurrency);
            }
            llSleep(5);
            kWinner = llList2Key(lMessage, 3);
            if (kWinner!=NULL_KEY && kWinner!="" && g_iPrizeSilver > 0) {
                llGiveMoney(kWinner, g_iPrizeSilver);
                llInstantMessage(kWinner, "You won "+(string)g_iPrizeSilver+g_sCurrency);
            }
            llSleep(5);
            kWinner = llList2Key(lMessage, 4);
            if (kWinner!=NULL_KEY && kWinner!="" && g_iPrizeBronze > 0) {
                llGiveMoney(kWinner, g_iPrizeBronze);
                llInstantMessage(kWinner, "You won "+(string)g_iPrizeBronze+g_sCurrency);
            }
            llSleep(5);
            kWinner = llList2Key(lMessage, 5);
            if (kWinner!=NULL_KEY && kWinner!="" && g_iPrizeBiggest > 0) {
                llGiveMoney(kWinner, g_iPrizeBiggest);
                llInstantMessage(kWinner, "You won "+(string)g_iPrizeBiggest+g_sCurrency);
            }
            Reset();
        } else if (sCmd=="reset") {
            Reset();
        }
    }
    
    money(key kGiver, integer iAmount) {
        g_iPrizeTotal += iAmount;
        llSay(0, llGetDisplayName(kGiver)+" contributed "+(string)iAmount+g_sCurrency+" to the pot");
        CalcPrizes();
        UpdateHover();
    }
    
}