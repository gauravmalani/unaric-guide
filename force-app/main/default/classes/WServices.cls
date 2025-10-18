/////////////////////////////////////////////////////////////////////////////////////////////////////
// SOAP WEB SERVICE EXPOSING KEY FEATURES OF IMPROVED HELP'S SF LOGIC TO JAVASCRIPT (CLIENT SIDE) CALLS
//
// DESIGN PRINCIPLES APPLICABLE TO THIS SERVICE:
//
//      - This class should act as a wrapper to others, rather than implementing complex business logic
//      - Use IsAllowed (in turn, wraps the IH Security service) where required to secure operations
//      - Return diagnostics messages containing outcomes
//      - Use static strings to hold commonly used messages (for ease of internationalisation etc)
//
// Martin Little for Improved Apps
// June 2012
/////////////////////////////////////////////////////////////////////////////////////////////////////

global with sharing class WServices {


    // For certain advice messages
    private static map<string, string> mapDlgLocs = ServiceLocalisation.getDialogueLocalisations('WServices', false); 
    private static String sMsgNoRights = ServiceLocalisation.getDialogueLocalisations('Globals', false).get('MessageNoRights');
    private static String sMsgBadParms = ServiceLocalisation.getDialogueLocalisations('Globals', false).get('MessageBadParameters');
    private static String sMsgError = ServiceLocalisation.getDialogueLocalisations('Globals', false).get('MessageGenericError');
    private static string Diags = '';
    private static string DiagsBasic = '';

        
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Manipulate individual topic / element / guide step records
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    
    // For deleting helped elements ("unhelping") via configuration toolset
    // NB: PageURL parameter deprecated: required but no longer in use!
    WebService static String deleteHelpedElement (String HEID, String PageURL) {

        String retVal;
        HelpedElement__c HE;
        ServiceSecurity Security = new ServiceSecurity();

        try {
                        
            HE = [SELECT Id, Name FROM HelpedElement__c WHERE Id=:HEID];
            
            // Delete it if permissions allow
            if (Security.IsAllowed(ServiceSecurity.KnownSecureOperations.AdministerHelp) == true || Security.IsAllowed(ServiceSecurity.KnownSecureOperations.EditHelp) == true) {
                delete HE;
                retVal = mapDlgLocs.get('MessageDeletedHelpedElements') + '"' + HE.Name + '"';
                
            } else {
                retVal = sMsgNoRights;
            }
            
        } catch (exception e) {
            retVal = sMsgError + ' (Delete Helped Element) - ' + e.getMessage();
        }
                
        return retVal;
    }
    
    
    // Creates a new helped element associated with an existing help topic
    public static String createHelpedElement(String HEID, String PageURL, String ElemType, String HTID) {

        String retVal = '';
        ControllerSettings cS = new ControllerSettings();
        String PgId = cS.SFObjId(PageURL);        
        
        getHelpedElement(PgId, HEID, ElemType, HTID);
        retVal = DiagsBasic;

        // Return diagnostics
        return retVal;
    }
    
    
    // Delete a step from a Guide (e.g., via Guide enable mode)
    public static String deleteGuideStep(String RLEId) {
        
        string retVal = '';
        HelpReadingListEntry__c RLE;
        ServiceSecurity Security = new ServiceSecurity();
        

        try {
            if (Security.IsAllowed(ServiceSecurity.KnownSecureOperations.AdministerHelp) == true || Security.IsAllowed(ServiceSecurity.KnownSecureOperations.EditHelp) == true) {

                RLE = [SELECT Id FROM HelpReadingListEntry__c WHERE Id = :RLEId];
                delete RLE;
                
            } else {
                retVal = sMsgNoRights;
            }
            
        } catch (exception e) {
            retVal = sMsgError + ' (Delete Guide Step) - ' + e.getMessage();
        }
                        
        return retVal;
    }
    
    
    // Add a step to a guide (and any required help topic / helped element):
    // Parameters as follows:
    //
    //      GuideId     = Id of the Guide (RL) into which to upsert a step
    //      RLEId       = Id of RL Entry to be updated (if not found, a new RLE is created)
    //      ElemId      = Element identifier for HE associated with guide step
    //      ElemType    = Type for HE associated with guide step
    //      PgId        = Identifier for HPL associated with this element
    //      StepName    = Help topic name for HT associated with RLE (NOT the Helped Element's topic)
    //      StepSummary = Summary as above
    //      StepOrder   = Reading Order for RLE
    //
    // Returns a message confirming actions taken or any issues
    public static String upsertGuideStep(String GuideId, String RLEId, String PgId, String ElemId, String ElemType, String StepName, String StepSummary, String StepOrder) {
        
        String retVal = '';
        HelpReadingListEntry__c RLE;
        HelpTopic__c HT;
        ServiceSecurity Security = new ServiceSecurity();
        Boolean[] Perms = Security.UserPermissions();
        HelpedElement__c HE;

        
        try {
            // Remove the selected Guide (RL) cookie
            Cookie ck = new Cookie('IHSelectedRL', 'SAVED', null, 1, false);
            ApexPages.currentPage().setCookies(new Cookie[]{ck});                                   
            
            
            if (Perms[1] == true || Perms[2] == true) {
                
                try {
                    RLE = [SELECT Id, ReadingOrder__c, HelpTopic__c
                            FROM HelpReadingListEntry__c 
                            WHERE HelpReadingList__c = :GuideId
                            AND Id = :RLEId];
                    
                    HT = [SELECT Id, Name, Summary__c
                            FROM HelpTopic__c
                            WHERE Id = :RLE.HelpTopic__c];
                    
                    retVal = mapDlgLocs.get('MessageAddingStep') + StepName + '... ';
                    
                } catch (exception e) {
                    // If entry is not found, create it here:               
                    // To do this, we must first create a help topic...
                    ControllerHelpContent cH = new ControllerHelpContent();
                    HT = cH.getDefaultHelpTopic();
                    
                    
                    // In newly added guides, we'll have added some steps that we need 
                    // to intercept here and treat in a special way: we can spot these
                    // by the helped element identifiers in use 
                    // (see jsToggleHelp.HookGEMode)...
                    
                    if (RLEId == 'IHAddedWelcome') {
                        HT.GuideStepMode__c = 'Local';
                        retVal = mapDlgLocs.get('MessageAddedStepWelcome') + ' - ';
                        
                    } else if (RLEId == 'IHAddedSelect') {                      
                        // For the select step, we need the "select a record" step to have a context set:
                        // This should be the listview screen for whatever object was in play
                        // when Guide Enabling was being done
                        HT.GuidedRecord__c = PgId + '/o';
                        HT.GuideStepMode__c = 'Automatic';                      
                        
                        retVal = mapDlgLocs.get('MessageAddedStepRecordSelection') + ' - ';
                        
                    } else {
                        // In general, by definition step mode is Manual (but author can amend later)
                        HT.GuideStepMode__c = 'Manual';             
                        
                    }                           
                    
                    
                    insert HT;
                    
                    // Now set RLE to point to this guide and topic
                    RLE = new HelpReadingListEntry__c();
                    RLE.HelpReadingList__c = GuideId;
                    RLE.HelpTopic__c = HT.Id;
                    
                    retVal += mapDlgLocs.get('MessageAddingStep') + StepName + '... ';
                }
                
                HT.Name = StepName;
                HT.Summary__c = StepSummary;
                
                // We need to check here whether a guided element exists for the relevant item:
                // In doing so, we need to check page ID: the one we were passed is the page
                // we were on when enabling - BUT any existing RLEs will have the correct
                // page ident - which could be the same, or may be from some other object that 
                // is involed elsewhere in this guide...
                
                try {
                    HelpReadingListEntry__c RLEnt = [SELECT HelpTopic__r.GuidedLayout__r.PageLayoutIdentifier__c FROM HelpReadingListEntry__c WHERE Id = :RLEId];
                    PgId = RLEnt.HelpTopic__r.GuidedLayout__r.PageLayoutIdentifier__c;
                    
                } catch (exception e) {
                    // The RLEId passed in does not represent an existing RL Entry, probably
                    // because we're adding a new one: so, do nothing here (keeping page ID as passed in) 
                }
                
                
                // Blank will create a new HT - not what we want
                // HT.Id is NOT right - as this is the step's topic - not that of any existing element                              
                // So: we pass "existing" as HTID, to advise routine to use the existing element's HTID if possible
                HE = getHelpedElement(PgId, ElemId, ElemType, 'Existing');                              
                
                HT.GuidedElement__c = HE.Id;
                HT.GuidedLayout__c = HE.HelpedPageLayout__c;
                
                
                upsert HT;
                
                RLE.ReadingOrder__c = decimal.valueOf(StepOrder);
                upsert RLE;
                
            } else {
                retVal = sMsgNoRights;
            }
            
        } catch (exception e) {
            retVal = sMsgError + ' (Upsert Guide Step) - ' + e.getMessage();
        }
        
        return retVal;
    }
    

    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Manipulate collections of topics / elements / guide steps via single calls
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    
    
    // Add multiple steps to a guide (and any required help topics / helped elements):
    // Parameters as follows:
    //
    //      GuideId         = Id of the Guide (RL) into which to upsert a step
    //      RLEIds          = Ids of RL Entries to be updated (if not found, a new RLE is created)
    //      ElemIds         = Element identifiers for HEs associated with guide steps
    //      ElemTypes       = Types for each HE associated with each guide step
    //      PgIds           = Identifiers for HPLs associated with each element
    //      StepNames       = Help topic names for HTs associated with each RLE (NOT the Helped Element topics)
    //      StepSummaries   = Summaries as above
    //      StepOrders      = Reading Orders for each RLE
    //
    // Returns a message confirming actions taken or any issues
    public static String upsertGuideSteps(String GuideId, String[] RLEIds, String[] PgIds, String[] ElemIds, String[] ElemTypes, String[] StepNames, String[] StepSummaries, String[] StepOrders) {

        String retVal = '';

        HelpReadingListEntry__c RLE;
        HelpTopic__c HT;
        HelpTopic__c defHT = null;      
        HelpedElement__c HE;

        HelpReadingListEntry__c[] ExistingRLEs = new HelpReadingListEntry__c[]{};
        HelpReadingListEntry__c[] RLEs = new HelpReadingListEntry__c[]{};
        HelpTopic__c[] HTs = new HelpTopic__c[]{};
        HelpedElement__c[] HEs = new HelpedElement__c[]{};
        
        Integer i;
        Integer j;
        String strSOQL;
        ServiceSecurity Security = new ServiceSecurity();
        ControllerHelpContent cH = new ControllerHelpContent();        
        Boolean[] Perms = Security.UserPermissions();

        boolean ApexPageExists = ServiceSecurity.ApexPageExists();
        
        try {
            // Remove the selected Guide (RL) cookie, where relevant
            if (ApexPageExists) {            
                Cookie ck = new Cookie('IHSelectedRL', 'SAVED', null, 1, false);
                ApexPages.currentPage().setCookies(new Cookie[]{ck});                                   
            }
                        
            
            // Permissions required
            if (Perms[1] == true || Perms[2] == true) {

                // Ensure incoming parameters are in the correct format
                if (RLEIds.size() == PgIds.size() && RLEIds.size() == ElemIDs.size() 
                    && RLEIds.size() == ElemTypes.size() && RLEIds.size() == StepNames.size() 
                    && RLEIds.size() == StepSummaries.size() && RLEIds.size() == StepOrders.size()) {
                    

                    // Loop around incoming RLEs / Guide entries to build selection criteria
                    strSOQL =  'SELECT Id, ReadingOrder__c, HelpTopic__c ';
                    strSOQL += 'FROM HelpReadingListEntry__c '; 
                    strSOQL += 'WHERE HelpReadingList__c = \'' + string.escapeSingleQuotes(GuideId) + '\' ';
                    strSOQL += 'AND Id IN (';

                    for (i=0; i < RLEIds.size(); i++) {
                        
                        // New elements won't have correct (any) Ids - so ignore
                        // these for the purposes of our SOQL: they'll have been 
                        // marked as "new" by the guiding process (see jsToggleHelp.showHelper
                        // and jsToggleHelp.HookGEMode).
                        if (RLEIds[i].startsWith('*') == false) {
                            strSOQL += '\'' + string.escapeSingleQuotes(RLEIds[i]) + '\',';                         
                        } else {
                            // Having ignored the element, we can remove the new marker
                            RLEIds[i] = string.escapeSingleQuotes(RLEIds[i].substring(1));
                        }
                    }
                    
                    // Check there was at least 1 existing element: if this is NOT the case,
                    // SOQL we've built will end with the "(" that opened the IN clause.
                    // If no existing elements, don't bother to make existing elements...
                    if (!strSOQL.endsWith('(')) {
                        strSOQL = strSOQL.substring(0, strSOQL.length() - 1);
                        strSOQL = strSOQL + ')';                        
                        ExistingRLEs = database.query(strSOQL);
                    }


                    // Loop around incoming RLEs / Guide entries to create/update records as reqd
                    for (i=0; i < RLEIds.size(); i++) {
                        
                        RLE = null;
                        
                        // See if we found RLE above
                        for (j=0; j < ExistingRLEs.size(); j++) {
                            try {
                                if (ExistingRLEs[j].Id == RLEIds[i]) {
                                    RLE = ExistingRLEs[j];
                                    break;
                                }
                            } catch (exception e) {}
                        }
                                                
                        if (RLE != null) {
                            
                            retVal += mapDlgLocs.get('MessageUpdatingStep') + ' ' + StepNames[i] + '... ';

                            // Get the associated help topic
                            HT = [SELECT Id, Name, Summary__c
                                    FROM HelpTopic__c
                                    WHERE Id = :RLE.HelpTopic__c];
                                                        
                        } else {
                            // If entry is not found, create it here:               
                            // To do this, we must first create a help topic...
                            // NB: to save SOQL, we only get this once then clone
                            if (defHT == null) {
                                defHT = cH.getDefaultHelpTopic();
                            }
                            HT = defHT.clone();
                                                                                    
                            // In newly added guides, we'll have added some steps that we need 
                            // to intercept here and treat in a special way: we can spot these
                            // by the helped element identifiers in use 
                            // (see jsToggleHelp.HookGEMode)...
                            
                            if (RLEIds[i] == 'IHAddedWelcome') {
                                HT.GuideStepMode__c = 'Local';
                                retVal += mapDlgLocs.get('MessageAddedStepWelcome') + ' - ';
                                
                            } else if (RLEIds[i] == 'IHAddedSelect') {                      
                                // For the select step, we need the "select a record" step to have a context set:
                                // This should be the listview screen for whatever object was in play
                                // when Guide Enabling was being done
                                HT.GuidedRecord__c = PgIds[i] + '/o';
                                HT.GuideStepMode__c = 'Automatic';                      
                                
                                retVal += mapDlgLocs.get('MessageAddedStepRecordSelection') + ' - ';
                                
                            } else {
                                // In general, by definition step mode is Manual (but author can amend later)
                                HT.GuideStepMode__c = 'Manual';             
                                retVal += mapDlgLocs.get('MessageAddingStep') + ' ' + StepNames[i] + '... ';
                            }                           
                            
                            
                            insert HT;
                            
                            // Now set RLE to point to this guide and topic
                            RLE = new HelpReadingListEntry__c();
                            RLE.HelpReadingList__c = GuideId;
                            RLE.HelpTopic__c = HT.Id;
                            
                        }
                        
                        HT.Name = StepNames[i];
                        HT.Summary__c = StepSummaries[i];
                                            
                        // We need to check here whether a guided element exists for the relevant item:
                        // In doing so, we need to check page ID: the one we were passed is the page
                        // we were on when enabling - BUT any existing RLEs will have the correct
                        // page ident - which could be the same, or may be from some other object that 
                        // is involed elsewhere in this guide...
                        
                        try {
                            HelpReadingListEntry__c RLEnt = [SELECT HelpTopic__r.GuidedLayout__r.PageLayoutIdentifier__c FROM HelpReadingListEntry__c WHERE Id = :RLEIds[i]];
                            PgIds[i] = RLEnt.HelpTopic__r.GuidedLayout__r.PageLayoutIdentifier__c;
                            
                        } catch (exception e) {
                            // The RLEId passed in does not represent an existing RL Entry, probably
                            // because we're adding a new one: so, do nothing here (keeping page ID as passed in) 
                        }
                        
                        HTs.add(HT);
                        
                        RLE.ReadingOrder__c = decimal.valueOf(StepOrders[i]);
                        RLEs.add(RLE);
                                            
                    }   // End for i - loop around incoming RLEs
                    
  
                    // Get any / all existing HEs relating to the guide steps (RLEs) being upserted:
                    // Note: in our case:
                    //      Where step involves existing HE, HE will be returned pointing to its help topic (a piece of existing embedded help)
                    //      Where step is on previously unhelped element, new HE and topic are created
                    // IE: we never supply the HTID for any new element (HTIDs parameter is null)
                    
                    HEs = getHelpedElements(PgIds, ElemIds, ElemTypes, null, null);
                    
                    
                    // Above call should have returned 1 HE per guide step HT, in the same order:
                    // So, here we loop to set guide related fields on step topics
                    for (i=0; i < HEs.size(); i++) {
                        HTs[i].GuidedElement__c = HEs[i].Id;
                        HTs[i].GuidedLayout__c = HEs[i].HelpedPageLayout__c;    
                    }
                    
                    // Update topics and RLEs: (HEs will have been created / amended as required by getHelpedElements)          
                    upsert HTs;
                    upsert RLEs;
                            
                    
                } else {
                    retVal = sMsgBadParms;                  
                }   // End if parameters in correct format
                
            } else {
                retVal = sMsgNoRights;
            }   // End if user had rights
            
        } catch (exception e) {
            retVal += sMsgError + ' (Upsert Guide Steps) - ' + e.getMessage();
            retVal += ' - ' + Diags;
        }
        
        return retVal;
        
    }
    
    
    // Delete multiple guide steps
    public static String deleteGuideSteps(String[] RLEIds) {
        
        String retVal = '';
        
        Integer i;
        String strSOQL;
        ServiceSecurity Security = new ServiceSecurity();
        Boolean[] Perms = Security.UserPermissions();
        HelpReadingListEntry__c[] ExistingRLEs;
        HelpTopic__c[] RLEHTs;
        
        boolean ApexPageExists = ServiceSecurity.ApexPageExists();        
        
        try {                    
            // Remove the selected Guide (RL) cookie, where relevant
            if (ApexPageExists) {            
                Cookie ck = new Cookie('IHSelectedRL', 'SAVED', null, 1, false);
                ApexPages.currentPage().setCookies(new Cookie[]{ck});                                   
            }      
                 
            
            // Permissions required
            if (Perms[1] == true || Perms[2] == true) {
                
                // Loop around incoming RLEs / Guide entries to get details of their help topics
                strSOQL =  'SELECT Id, HelpTopic__c ';
                strSOQL += 'FROM HelpReadingListEntry__c '; 
                strSOQL += 'WHERE Id IN (';

                for (i=0; i < RLEIds.size(); i++) {                     
                    strSOQL += '\'' + string.escapeSingleQuotes(RLEIds[i]) + '\',';                         
                }
                    
                // Check there was at least 1 existing element: if this is NOT the case,
                // SOQL we've built will end with the "(" that opened the IN clause.
                if (!strSOQL.endsWith('(')) {
                    strSOQL = strSOQL.substring(0, strSOQL.length() - 1);
                    strSOQL = strSOQL + ')';                        
                    ExistingRLEs = database.query(strSOQL);
                    
                    // Now loop to create delete SOQL for the related help topics:
                    // Deleting the topics will delete the RLEs...

                    strSOQL =  'SELECT Id ';
                    strSOQL += 'FROM HelpTopic__c '; 
                    strSOQL += 'WHERE Id IN (';

                    for (HelpReadingListEntry__c RLE : ExistingRLEs) {
                        strSOQL += '\'' + RLE.HelpTopic__c + '\',';                         
                    }
                    
                    if (!strSOQL.endsWith('(')) {
                        strSOQL = strSOQL.substring(0, strSOQL.length() - 1);
                        strSOQL = strSOQL + ')';                        
                        RLEHTs = database.query(strSOQL);
                                    
                        i = RLEHTs.size();
                        delete RLEHTs;                      
                        retVal = mapDlgLocs.get('MessageDeletedGuideSteps') + ' (' + i + ')... ';
                    }
                }
                
                
            } else {
                retVal = sMsgNoRights;
            }   // End if user had rights
                
        } catch (exception e) {
            retVal += sMsgError + ' (Delete Guide Steps) - ' + e.getMessage();
            retVal += ' - ' + Diags;            
        }
        
        return retVal;
        
    }
    

    // Add multiple helped elements
    public static String createHelpedElements(String[] HEIDs, String[] URLs, String[] eTypes, String[] HTIDs) {
        
        String retVal;
        String[] PgIds = new String[]{};
        Boolean[] ApexFlags = new Boolean[]{};
        ControllerSettings cS = new ControllerSettings();

        try {
            // This is exactly the same as creating guided helped elements, so we can use that call here:
            // The only difference is that we may be passing in the IDs of certain topics to use 
            // (where user has help enabled but said use an existing topic for the new element). 
            // Also, we need to generate the page layout identifiers to use in this call from the incoming URL:
            
            for (String U : URLs) {
                PgIds.add(cS.SFObjId(U));
                
                // Note in each case whether this was an apex page address
                ApexFlags.add(U.toUpperCase().indexOf('/APEX/') != -1);
            }
            
            getHelpedElements(PgIds, HEIDs, eTypes, HTIDs, ApexFlags);
            retVal = DiagsBasic;
            
        } catch (exception ex) {
            retVal = sMsgError + ' (Create Helped Elements) - ' + ex.getMessage() + ' - ' + DiagsBasic;
        }
        
        return retVal;
    }
    
    
    // Delete multiple helped elements
    public static string deleteHelpedElements(String[] HEIDs, String[] delHTs) {
        
        ServiceSecurity Security = new ServiceSecurity();
        String retVal = '';
        HelpedElement__c[] HEs;
        HelpTopic__c[] HTs;
        String strSOQL;
        Integer i;
        
        try {

            // Delete only if permissions allow
            if (Security.IsAllowed(ServiceSecurity.KnownSecureOperations.AdministerHelp) == true || Security.IsAllowed(ServiceSecurity.KnownSecureOperations.EditHelp) == true) {
                
                // Delete the helped elements
                strSOQL = 'SELECT Id FROM HelpedElement__c WHERE Id IN(';               
                for(String HEID : HEIDs) {
                    strSOQL += '\'' + string.escapeSingleQuotes(HEID) + '\',';
                }
                
                // Continue only if at least 1 HE was to be deleted...
                if (strSOQL.endsWith(',')) {
                    strSOQL = strSOQL.substring(0, strSOQL.length() -1);
                    strSOQL += ')';
                                  
                    HEs = Database.Query(strSOQL);
                    i = HEs.size();
                    delete HEs;
                    retVal = mapDlgLocs.get('MessageDeletedHelpedElements') + ' (' + i + ') ';

                    // Delete any related help topics where this was requested
                    strSOQL = 'SELECT Id FROM HelpTopic__c WHERE Id IN(';               
                    for(String HTID : delHTs) {
                        if (HTID != '') {
                            strSOQL += '\'' + string.escapeSingleQuotes(HTID) + '\',';
                        }
                    }
    

                    // Continue only if at least 1 related HT was to be deleted...
                    if (strSOQL.endsWith(',')) {
                        strSOQL = strSOQL.substring(0, strSOQL.length() -1);
                        strSOQL += ')';
                                      
                        HTs = Database.Query(strSOQL);
                        i = HTs.size();
                        delete HTs;
                        retVal += mapDlgLocs.get('MessageDeletedHelpTopics') + ' (' + i + ') ';
                    }
                }
                                
            } else {
                retVal = sMsgNoRights;
            }
            
            
        } catch (exception ex) {
            retVal = sMsgError + ' (Delete Helped Elements) - ' + ex.getMessage() + ' - ' + retVal;
        }
        
        return retVal;
    }

    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // DEPRECATED / STUB ONLY
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    
     webService static String createHelpTopic(String HEID, String PageURL, String ElemType) {
        return 'Help\'s "Create Help Topic" function has been deprecated: please use Create Helped Element instead';
     }
    
  

    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // PRIVATE UTILITY FUNCTIONS
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    // Returns any helped element matching the one specified by incoming parameters, being:
    //
    //      PgId        = Identifier (NOT Id) of a page layout
    //      HEID        = Identifier (NOT Id) of a helped element
    //      ElemType    = Element type (for newly created elements)
    //      HTID        = Help Topic Id for newly created element: blank -> creates new topic
    //
    // Creates a new HE if none found and returns this
    private static HelpedElement__c getHelpedElement(String PgId, String HEID, String ElemType, String HTID) {

        HelpedElement__c[] HEs;
        HelpedElement__c HE;
        HelpedPageLayout__c HPL;
        HelpTopic__c HT;
        HelpTopicTemplate__c HTT;
        ServiceSecurity Security = new ServiceSecurity();

        Diags = '';
        DiagsBasic = '';
        
        try {
            // Check rights before proceeding
            Boolean[] UPs = Security.UserPermissions();
            
            if (UPs[1] == false && UPs[2] == false) {
                Diags = sMsgNoRights;
                DiagsBasic = Diags;
                return null;
            }
            
            // Get or create the required helped elements (and page layout)
            try {
                // Check whether there is already a helped element for this identifier
                HEs = [SELECT Id, HelpTopic__c, HelpedPageLayout__r.PageLayoutIdentifier__c 
                        FROM HelpedElement__c 
                        WHERE Identifier__c = :HEID 
                        //AND HelpedPageLayout__r.PageLayoutIdentifier__c = :PgId
                        ];
                
                Diags += '\nAt least 1 element matching "' + HEID + '" exists for layout ' +PgId;
                
                // This may return 1+ elements - as SOQL is case insensitive - so we need to check we find
                // exactly the one we're after...
                for (HelpedElement__c H : HEs) {
                    if (H.HelpedPageLayout__r.PageLayoutIdentifier__c.equals(PgId) == true) {
                        Diags += '\nExact Helped element found';                    
                        HE = H;                 
                        break;                  
                    }
                }
                
                
                // Check that we have HE by this stage with a test that will throw an error 
                // if it fails (sending us to the create helped element routine)
                Diags += '\nFound Helped Element ' + HE.Id + ' for identifier ' + HEID;
                    
                    
            } catch (exception e) {

                // No matching element existed: create helped element here
                HE = new HelpedElement__c();
                
                HE.Name = '' + HEID;
                HE.Identifier__c = HEID;
                HE.ElementType__c = ElemType;
                
                // We need to set the element's helped page layout to the one we're on:
                // Get the current page's object identifier and look this up in layouts
                Diags += '\nLooking for page layout ID ' + PgId;
                    
                try {
                    HelpedPageLayout__c[] HP = [SELECT Id, PageLayoutIdentifier__c FROM HelpedPageLayout__c WHERE PageLayoutIdentifier__c = :PgId];
                    
                    // This may return 1+ layouts - as SOQL is case insensitive - so we need to check we find
                    // exactly the one we're after...
                    for (HelpedPageLayout__c L : HP) {
                        if (L.PageLayoutIdentifier__c.equals(PgId) == true) {
                            HPL = L;
                            break;                  
                        }
                    }
                    
                    
                } catch (exception f) {
                    // Do nothing here - create layout below...
                }
                    
                if (HPL == null) {   
                     
                    // If there's no hepled page layout yet, we need to create one here...
                    Diags += '\nAttempting to add a new Helped Page Layout';
                    
                    HPL = new HelpedPageLayout__c();
                    Schema.Describesobjectresult objInfo;
                    ServiceSchema sS = new ServiceSchema();
                    
                    // We want the name of our new layout to be that of the underlying
                    // SF standard or custom object if we can
                    objInfo = sS.getObjectDetails(PgId);
                    
                    if (objInfo == null) {
                        HPL.Name = mapDlgLocs.get('ValueDraftLayout') + ' ' + PgId;
                    } else {
                        HPL.Name = objInfo.getLabelPlural() + ' ' + mapDlgLocs.get('ValueLayout');                          
                    }
                    
                    HPL.PageLayoutIdentifier__c = PgId;
                    HPL.PageType__c = 'Standard';
                    
                    // Set commenting rights per global settings
                    HPL.AllowComments__c = ControllerSettings.getSettings().AllowLayoutComments__c;
                    
                    insert HPL;     
                    
                    // Note this in our return value...
                    if (objInfo == null) {
                        Diags = mapDlgLocs.get('MessageAddedPageLayout') + ' ' + PgId;
                    } else {
                        Diags = mapDlgLocs.get('MessageAddedPageLayout') + ' ' + objInfo.getLabelPlural();
                    }
                                    
                }

                HE.HelpedPageLayout__c = HPL.Id;                                        
            }
                
                                
            // Associate this with a help topic or create a new one:
            // If we're passed the word "Existing" as HTID, attempt to leave HE's topic as is
            if (HTID.toUpperCase() == 'EXISTING') {
                try {
                    HTID = HE.HelpTopic__c;
                } catch (exception e) {
                    HTID = '';
                }
            } 
            
            // If, having tried the above, we still have no HTID, create a new topic
            if (HTID == '' || HTID == null) {
                ControllerHelpContent cH = new ControllerHelpContent();
                HT = cH.getDefaultHelpTopic();
                
                // The only field we override here is Name (default states we're unbound)
                HT.Name = HEID + ' ' + mapDlgLocs.get('ValueDraftHelp');
                HT.Summary__c = HEID + ' - ' + HT.Summary__c;
                  
                insert HT;                                                            
                HE.HelpTopic__c = HT.Id;
                Diags += '\nNo Topic ID was specified for association, new Topic therefore inserted for ' + HEID;
                DiagsBasic += '\n' + mapDlgLocs.get('MessageAddedHelpedElementAndTopic') + ' ' + HEID;
                    
                    
            } else {
                // If we were given a help topic id, check it exists
                try {
                    HT = [SELECT Id FROM HelpTopic__c WHERE Id = :HTID];
                    HE.HelpTopic__c = HTID;
                    Diags += '\nSpecific Topic ID was specified for association: Topic located and associated.';
                    DiagsBasic += '\n' + mapDlgLocs.get('MessageAddedHelpedElementExistingTopic') + ' ' + HEID;
                        
                    } catch (exception f) {
                        DiagsBasic = sMsgError + ' - ' + mapDlgLocs.get('MessageTopicDoesNotExist') + ' ';
                        DiagsBasic += ' - ' + Diags;
                    }
                
            }
                
            // Only now can we save changes to our helped element, having created topic
            upsert HE;
                
                
        } catch (exception ex) {
            DiagsBasic = sMsgError + ' (Get Helped Element) - ';
            DiagsBasic += ex.getMessage();
            DiagsBasic += ' - ' + Diags;            
        }
                    
        // Return any created helped element
        return HE;
    }
 
 
 
    // Returns list of helped elements matching incoming parameters, being:
    //
    //      PgIds       = Identifiers (NOT Ids) of associated page layouts
    //      HEIDs       = Identifiers (NOT Ids) of desired helped elements
    //      ElemTypes   = Element types (for newly created elements)
    //      HTIDs       = Ids of Help Topics to associate with elements
    //      ApexFlags   = true where associated layout is thought to be a VF page (APEX address)
    //
    // Creates new HEs if none found and returns these.
    // Where HE is created, associated Help Topic will be:
    //      - As set by HTIDs, where an ID is supplied at the relevant index
    //      - A newly created topic where HTIDs is blank at the relevant index or HTIDs is null
    
    private static HelpedElement__c[] getHelpedElements(String[] PgIds, String[] HEIDs, String[] ElemTypes, String[] HTIDs, Boolean[] ApexFlags) {
        
        Integer i;
        HelpTopic__c defHT = null;
        HelpedElement__c[] CandidateHEs = new HelpedElement__c[]{};
        HelpedElement__c[] ExistingHEs = new HelpedElement__c[]{};
        HelpedElement__c[] ReturnHEs = new HelpedElement__c[]{};
        HelpedElement__c HE;
        HelpedPageLayout__c[] ExistingHPLs;
        HelpedPageLayout__c HPL;
        String strSOQL;
        Schema.Describesobjectresult objInfo;
        ServiceSchema sS = new ServiceSchema();
        ServiceSecurity Security = new ServiceSecurity();
        ControllerHelpContent cH = new ControllerHelpContent();
        String safeElemId;
        
        Diags = '';
        DiagsBasic = '';
        
        
        try {
            
            //--------------------------------------------------------------------------------------
            // Ensure user has permissions before continuing
            //--------------------------------------------------------------------------------------            
            Boolean[] UPs = Security.UserPermissions();
            
            if (UPs[1] == false && UPs[2] == false) {
                Diags = sMsgNoRights;
                DiagsBasic = Diags;
                return returnHEs;
            }
            
            
            // Build SOQL to get any existing HPLs
            strSOQL = 'SELECT ID, PageLayoutIdentifier__c ';
            strSOQL += 'FROM HelpedPageLayout__c ';
            strSOQL += 'WHERE PageLayoutIdentifier__c IN (';
            
            for (i=0; i < PgIds.size(); i++) {
                strSOQL += '\'' + string.escapeSingleQuotes(PgIds[i]) + '\',';
            }
            
            if (!strSOQL.endsWith('(')) {
                strSOQL = strSOQL.substring(0, strSOQL.length() - 1);
                strSOQL = strSOQL + ')';
                
                Diags = 'getHelpedElements: attempting to locate related layouts with SOQL: ' + strSOQL + '... ';                       
                ExistingHPLs = database.query(strSOQL);             
                Diags += 'Located ' + ExistingHPLs.size() + ' layouts... ';
                
            } else {
                Diags = 'getHelpedElements: no layout information provided: layouts not sought... ';
            }
            
            
            // Build SOQL to get any existing HEs
            strSOQL = 'SELECT Id, HelpTopic__c, ElementType__c, Identifier__c, HelpedPageLayout__r.PageLayoutIdentifier__c ';       
            strSOQL += 'FROM HelpedElement__c ';
            strSOQL += 'WHERE Identifier__c IN (';
            
            for (i=0; i < HEIDs.size(); i++) {
                
                // In using element identifiers, we need to escape out single quotes...
                safeElemId = string.escapeSingleQuotes(HEIDs[i]);               
                
                strSOQL += '\'' + safeElemId + '\',';
            }
            
            if (!strSOQL.endsWith('(')) {
                strSOQL = strSOQL.substring(0, strSOQL.length() - 1);
                strSOQL = strSOQL + ')';
                
                Diags += 'Attempting to locate elements with SOQL: ' + strSOQL + '... ';                        
                CandidateHEs = database.query(strSOQL);
                Diags += 'Located ' + CandidateHEs.size() + ' elements... ';                        

            } else {
                Diags += 'No element information provided: elements not sought... ';                        
            }
                        

            // SOQL is case insensitive, so we need to check each of the candidates retrieved above
            // to ensure they're an exact match of the desired page and element identifiers
            for (HelpedElement__c H : CandidateHEs) {
                for (i=0; i < PgIds.size(); i++) {
                    if (H.HelpedPageLayout__r.PageLayoutIdentifier__c != null) {
                        if (H.HelpedPageLayout__r.PageLayoutIdentifier__c.equals(PgIds[i])) {
                            ExistingHEs.add(H);
                        }
                    }
                }
            }
            
            Diags += 'Of the candidate elements, ' + ExistingHEs.size() + ' were exact matches... ';
            
            // Now that we have a reliable list of any matches, loop through incoming HEIDs 
            // and add any new HE that might be required, having checked against the existing ones
            for (i=0; i < HEIDs.size(); i++) {
                
                HE = null;
                for (HelpedElement__c H : ExistingHEs) {                    
                    if (HEIDs[i].equals(H.Identifier__c) 
                    && PgIds[i].equals(H.HelpedPageLayout__r.PageLayoutIdentifier__c)
                    && ElemTypes[i] == H.ElementType__c) {
                        HE = H;
                        break;
                    }
                }           
                
                
                if (HE == null) {                   
                    Diags += 'No match found for element "' + HEIDs[i] + '": creating new element... ';
                    DiagsBasic += mapDlgLocs.get('MessageAddingElement') + ' "' + HEIDs[i] + '" ';
                    
                    // No matching element found, so create it here
                    HE = new HelpedElement__c();
                    
                    HE.Name = '' + HEIDs[i];
                    HE.Identifier__c = HEIDs[i];
                    HE.ElementType__c = ElemTypes[i];
                    
                    // Look for page layout required for this element in the set we already have
                    HPL = null;
                    for (HelpedPageLayout__c L : ExistingHPLs) {
                        if (L.PageLayoutIdentifier__c.equals(PgIds[i])) {
                            HPL = L;
                            Diags += 'Existing page layout used for this element... ';
                            break;
                        }
                    }
                    
                    if (HPL == null) {
                        // If layout not found, create one here and add it to the existing set
                        HPL = new HelpedPageLayout__c();
                        objInfo = null;
                        
                        // We want the name of our new layout to be that of the underlying
                        // SF standard or custom object if we can
                        objInfo = sS.getObjectDetails(PgIds[i]);
                        

                        // 1.21: we need to work out whether to use a standard or VF page layout                        
                        if (objInfo == null) {
                            HPL.Name = mapDlgLocs.get('ValueDraftLayout') + ' ' + PgIds[i];
                            
                            // If we can't get schema details, this may be a VF page: in these cases, we
                            // should also have been told by the caller that "/APEX/" occurred in the URL...
                            if (ApexFlags != null) {
                                if (ApexFlags[i] == true) {
                                    HPL.PageType__c = 'Visual Force';
                                } else {
                                    HPL.PageType__c = 'Standard';                           
                                }                                           
                            } else {
                                HPL.PageType__c = 'Standard';
                            }             
                            
                        } else {
                            HPL.Name = objInfo.getLabelPlural() + ' ' + mapDlgLocs.get('ValueLayout');                          
                            HPL.PageType__c = 'Standard';
                        }
                        
                        HPL.PageLayoutIdentifier__c = PgIds[i];

                        
                        // Set commenting rights per global settings
                        HPL.AllowComments__c = ControllerSettings.getSettings().AllowLayoutComments__c;
                        
                        insert HPL;
                        ExistingHPLs.add (HPL);
                        Diags += 'New layout added for this element... ';
                        
                    }   // End if HPL = null
                    
                    HE.HelpedPageLayout__c = HPL.Id;    
                    

                    // When supplying new helped elements, we need to consider the associated help topic:
                    // Caller has the option to supply the ID of an existing topic via HTIDs parameter.                     
                    if (HTIDs != null) {
                        if (HTIDs[i] != '') {
                            HE.HelpTopic__c = HTIDs[i];
                            Diags += 'Help Topic ' + HE.HelpTopic__c + ' will be used for element ' + HEIDs[i] + '... ';
                            DiagsBasic += ' - ' + mapDlgLocs.get('MessageElementWithExistingTopic') + '\n';
                        }
                    }
                    
                    // If no HTID is supplied, add a help topic for this helped element:
                    if (HE.HelpTopic__c == null) {

                        Diags += 'A new Help Topic will be cloned from the default for this Helped Element... ';

                        // NB: to save SOQL, we only get this once then clone
                        if (defHT == null) {
                            defHT = cH.getDefaultHelpTopic();
                        }
                        HelpTopic__c HT = defHT.clone();

                    
                        // The only field we override here is Name (default states we're unbound)
                        HT.Name = HEIDs[i] + ' ' + mapDlgLocs.get('ValueDraftHelp');
                        HT.Summary__c = HEIDs[i] + ' - ' + HT.Summary__c;
                        
  
                        insert HT;                                                            
                        
                        HE.HelpTopic__c = HT.Id;                        
                        Diags += 'New topic created for ' + HEIDs[i] + '... ';                      
                        DiagsBasic += ' - ' + mapDlgLocs.get('MessageElementWithNewTopic') + '\n';
                    }
    
                    
                    upsert HE;
                    Diags += 'Element ' + HEIDs[i] + ' upserted... ';
                    
                }   // End if HE = null 
                
                
                Diags += 'Adding element "' + HEIDs[i] + '" to return collection... ';              
                returnHEs.add(HE);  
                            
            }   // End for i - loop around incoming Elem Ids
                        
        } catch (exception ex) {
            DiagsBasic = sMsgError + ' (Get Helped Elements) - ';
            DiagsBasic += ex.getMessage();
            DiagsBasic += ' - ' + Diags;
        }
        
        return returnHEs;
    }
 
    
}