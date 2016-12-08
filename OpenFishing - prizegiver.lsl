integer OPENFISHING_CHANNEL = -15837;
string  OFID = "openfishing";
integer g_iListenHandle;

// Read from prizegiver.config
string g_sPrizeGold;
string g_sPrizeSilver;
string g_sPrizeBronze;
string g_sPrizeBiggest;

// If set, displays an additional subtitle
string g_sSubHover;

UpdateHover()
{
    string sHover = "OpenFishing Prizegiver\n";
    if (g_sSubHover!="") sHover+=g_sSubHover+"\n";
    sHover+= " \nGold: "+(string)g_sPrizeGold+"\n"+
             "Silver: "+(string)g_sPrizeSilver+"\n"+
             "Bronze: "+(string)g_sPrizeBronze+"\n"+
             "Biggest catch: "+(string)g_sPrizeBiggest;
             
    llSetText(sHover, <1,1,1>, 1);
}

ParseConfig()
{   
    integer i = 0;
    for(i=1; i<=osGetNumberOfNotecardLines("prizegiver.config"); i++) {
        string line = llStringTrim(osGetNotecardLine("prizegiver.config", i), STRING_TRIM);
        list lPair = llParseString2List(line, ["="], []);
        string sSetting = llList2String(lPair, 0);
        if (llGetSubString(sSetting, 0, 0)!="#" || llGetSubString(sSetting, 0, 0)!="") {
            if (sSetting=="prize_gold") g_sPrizeGold = llStringTrim(llList2String(lPair, 1), STRING_TRIM);
            else if (sSetting=="prize_silver") g_sPrizeSilver = llStringTrim(llList2String(lPair, 1), STRING_TRIM);
            else if (sSetting=="prize_bronze") g_sPrizeBronze = llStringTrim(llList2String(lPair, 1), STRING_TRIM);
            else if (sSetting=="prize_biggest") g_sPrizeBiggest = llStringTrim(llList2String(lPair, 1), STRING_TRIM);
            else if (sSetting=="sub_hover") g_sSubHover = llList2String(lPair, 1);
        }
    }
    
    // Check
    if (llGetInventoryKey(g_sPrizeGold)==NULL_KEY)
        llOwnerSay("Can't find prize for GOLD: "+g_sPrizeGold);
    if (llGetInventoryKey(g_sPrizeSilver)==NULL_KEY)
        llOwnerSay("Can't find prize for SILVER: "+g_sPrizeSilver);
    if (llGetInventoryKey(g_sPrizeBronze)==NULL_KEY)
        llOwnerSay("Can't find prize for BRONZE: "+g_sPrizeBronze);
    if (llGetInventoryKey(g_sPrizeBiggest)==NULL_KEY)
        llOwnerSay("Can't find prize for BIGGEST: "+g_sPrizeBiggest);

    UpdateHover();
}

Init()
{
    ParseConfig();
    UpdateHover();
        
    g_iListenHandle = llListen(OPENFISHING_CHANNEL, "", NULL_KEY, "");
}

key hgName2Key(string sName)
{
    integer idx = llSubStringIndex(sName, " ");
    if (idx == -1) return NULL_KEY;
    string sFirst = llGetSubString(sName, 0, idx-1);
    string sLast = llGetSubString(sName, idx+1, -1);
    return osAvatarName2Key(sFirst, sLast);
}

default
{
    state_entry()
    {
        Init();
    }

    on_rez(integer start_param)
    {
        Init();
    }

    changed(integer what)
    {
        if (what & CHANGED_INVENTORY) {
            ParseConfig();
            UpdateHover();
        }
    }
    
    listen(integer iChannel, string sName, key kID, string sMessage)
    {
        // Security
        if (llGetOwnerKey(kID)!=llGetOwner()) return;
        
        list lMessage = llParseStringKeepNulls(sMessage, ["|"], []);
        if (llList2String(lMessage,0)!=OFID) return;

        string sCmd=llList2String(lMessage,1);
        if (sCmd=="conclude") {
            llSetText("Transferring prizes", <1,1,1>, 1);
            // Message received in the form of:
            // |conclude|string sNameGold|string sNameSilver|string sNameBronze|string sNameBiggest
            key kWinner = hgName2Key(llList2String(lMessage, 2));
            if (kWinner!=NULL_KEY && kWinner!="" && g_sPrizeGold != "") {
                llGiveInventory(kWinner, g_sPrizeGold);
                llInstantMessage(kWinner, "You won "+g_sPrizeGold);
                llSleep(5);            
            }
            kWinner = hgName2Key(llList2String(lMessage, 3));
            if (kWinner!=NULL_KEY && kWinner!="" && g_sPrizeSilver != "") {
                llGiveInventory(kWinner, g_sPrizeSilver);
                llInstantMessage(kWinner, "You won "+g_sPrizeSilver);
                llSleep(5);
            }
            kWinner = hgName2Key(llList2String(lMessage, 4));
            if (kWinner!=NULL_KEY && kWinner!="" && g_sPrizeBronze != "") {
                llGiveInventory(kWinner, g_sPrizeBronze);
                llInstantMessage(kWinner, "You won "+g_sPrizeBronze);
                llSleep(5);
            }
            kWinner = hgName2Key(llList2String(lMessage, 5));
            if (kWinner!=NULL_KEY && kWinner!="" && g_sPrizeBiggest != "") {
                llGiveInventory(kWinner, g_sPrizeBiggest);
                llInstantMessage(kWinner, "You won "+g_sPrizeBiggest);
                llSleep(5);
            }
            UpdateHover();
        } else if (sCmd=="reset") {
            UpdateHover();
        }
    }
    
}