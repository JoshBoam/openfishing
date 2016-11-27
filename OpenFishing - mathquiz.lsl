string OFID = "openfishing";
key g_kFisher;

integer g_iChannel;
integer g_iListenH;

integer g_iTimerMode = 0;
integer TIMER_MODE_QUESTION = 0;
integer TIMER_MODE_ANSWER = 1;
float   MIN_QUESTION_TIME = 300.0; // 5 minutes
float   MAX_QUESTION_TIME = 600.0; // 10 minutes
integer ANSWER_TIME = 15;
integer g_iAnswer;
integer NOTICE_OWNER = TRUE;
integer NOTICE_SITTER = TRUE;

integer g_iPaused = FALSE;

integer GenerateNegChannel()
{
     integer iChannel = -(1+(integer)llFrand(2147483647));
     return iChannel;
}

default
{
    state_entry()
    {
    }
    
    changed(integer what)
    {
        if (what & CHANGED_LINK) {
            key kAvi = llAvatarOnSitTarget();
            if (kAvi==NULL_KEY) {
                llSetTimerEvent(0);
                g_kFisher = NULL_KEY;
                llListenRemove(g_iListenH);
            } else {
                g_kFisher = kAvi;
                g_iTimerMode=TIMER_MODE_QUESTION;
                llSetTimerEvent(MIN_QUESTION_TIME+llFrand(MAX_QUESTION_TIME-MIN_QUESTION_TIME));
            }
            g_iPaused = FALSE;
        }
    }
    
    link_message(integer iSender, integer iNum, string sText, key kID)
    {
        list l = llParseString2List(sText, [":", "="], []);
        
        if (llList2String(l, 0)!=OFID) return;
        
        string sCmd = llList2String(l, 1);
        if (sCmd=="paused") {
            integer sVal = llList2Integer(l, 2);
            if (sVal==1) {
                g_iPaused = TRUE;
            } else if (sVal==0) {
                g_iPaused = FALSE;                
            }
        }
    }
    
    timer()
    {    
        if (g_iTimerMode==TIMER_MODE_QUESTION) {
            if (g_iPaused) return;

            llMessageLinked(LINK_SET, 0, OFID+":suspend=1", NULL_KEY);
            // Generate math question and answer
            integer x = (integer)llFrand(16+1);
            integer y = (integer)llFrand(16+1);
            g_iAnswer = x + y;
            string sQuestion = (string)x+" + "+(string)y;
        
            // Generate button list for dialog
            integer i;
            integer iAnswerButton = (integer)llFrand(6);
            list lButtons;
            for (i = 0; i < 6; i++) {
                if (i == iAnswerButton) {
                    lButtons += [(string)g_iAnswer];
                } else {
                    integer iRandom = (integer)llFrand(32+1);
                    lButtons += [(string)iRandom];
                }
            }
            
            g_iChannel = GenerateNegChannel();
            g_iListenH = llListen(g_iChannel, "", NULL_KEY, "");
            llDialog(g_kFisher, "\nO P E N  F I S H I N G\n\nPlease answer the following math question:\n\n"+
                sQuestion, lButtons, g_iChannel);
                
            g_iTimerMode=TIMER_MODE_ANSWER;
            llSetTimerEvent(ANSWER_TIME);
        }
        else
        if (g_iTimerMode==TIMER_MODE_ANSWER) {
            if (NOTICE_SITTER) llInstantMessage(g_kFisher, "You failed to answer the mathquiz in time.");
            if (NOTICE_OWNER) llOwnerSay(llKey2Name(g_kFisher)+" failed to answer the mathquiz in time.");
            llUnSit(g_kFisher); // you could do really mean stuff here, even orbit them.
            
            llListenRemove(g_iListenH);
            g_iTimerMode=TIMER_MODE_QUESTION;
            llSetTimerEvent(0);
            llMessageLinked(LINK_SET, 0, OFID+":suspend=0", NULL_KEY);
        }
    }
    
    listen(integer iChannel, string sName, key kID, string sMessage)
    {
        llListenRemove(g_iListenH);
        g_iTimerMode=TIMER_MODE_QUESTION;
        llSetTimerEvent(0);
        
        llMessageLinked(LINK_SET, 0, OFID+":suspend=0", NULL_KEY);
        
        if ((integer)sMessage==g_iAnswer) {
            if (NOTICE_SITTER) llInstantMessage(g_kFisher, "Correct.");
                
            g_iTimerMode=TIMER_MODE_QUESTION;
            llSetTimerEvent(MIN_QUESTION_TIME+llFrand(MAX_QUESTION_TIME-MIN_QUESTION_TIME));
        } else {
            if (NOTICE_SITTER) llInstantMessage(g_kFisher, "You failed to provide the correct answer.");
            if (NOTICE_OWNER) llOwnerSay(llKey2Name(g_kFisher)+" failed to provide the correct answer.");
            llUnSit(g_kFisher);
        }
    }
}