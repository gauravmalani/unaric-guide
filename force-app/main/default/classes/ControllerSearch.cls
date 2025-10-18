/////////////////////////////////////////////////////////////////////////////////////////////////////
// PAGE CONTROLLER CLASS FOR SEARCH AND SEARCH RESULTS PAGES
//
// Martin Little for Improved Apps
// August 2012
/////////////////////////////////////////////////////////////////////////////////////////////////////


public with sharing class ControllerSearch {

    // Global settings info
    public static String getBrandCSS() {return ControllerSettings.getSettings().BrandCSS__c;}
    public static String getD1() {return ControllerSettings.D1;}
    public static String getD2() {return ControllerSettings.D2;}

    // For UI localisations /multi language support (labels, messages etc)
    private map<string, string>mapDlgLocs;
    private map<string, string>mapGlbLocs;
    private map<string, string>mapBrdLocs;
    public map<string, string> getDialogueLocalisations() {
        return mapDlgLocs;
    }
    public map<string, string> getGlobalLocalisations() {
        return mapGlbLocs;
    }
    public map<string, string> getBrandingLocalisations() {
        return mapBrdLocs;
    }

    // Elements set through query string parameters
    public String Term {get; set;}                                                  // The keyword a user searched for
    public String HTID {get; set;}                                                  // Help topic, if any, occasioning search (from query)
    public String RLID {get; set;}                                                  // Reading list as above
    public String objId {get; set;}                                                 // SF object as above
    public String Opts {get; set;}                                                  // Controls visibility of certain search page options
    public String UserSort {get; set;}                                              // To accept sort order selected by user
    public String callerPageURL {get; set;}                                         // Context (URL) from which page is called
    public Boolean isIHLUX {get; set;}                                              // True if parameter passed to indicate viewing via the Lightning UX

    public SearchOptions Options {get; set;}                                        // User's help search terms & options
    public SearchResult[] PageHelp {get; set;}                                      // Topic listing for page level help
    public SearchResult[] FieldHelp {get; set;}                                     // Topic listing for field level help
    public String SearchResultId{get; set;}                                         // Id of topic selected when manipulating related help etc
    public String DefaultSearchResult {get; set;}                                   // URL of result to show on arrival at results
    public String Diags {get; set;}                                                 // For passing messages to user etc
    public Boolean IsError {get; set;}                                              // Controls access to features based on search results  
    public String AddRelativeLink {get; set;}                                       // Link to add searched topic as related to current topic

    public String fld1 {get; set;}                                                  // For capture of various pieces of data via forms
    public String fld2 {get; set;}                                                  // For capture of various pieces of data via forms
    public String fld3 {get; set;}                                                  // For capture of various pieces of data via forms
    public String fld4 {get; set;}                                                  // For capture of various pieces of data via forms
    public String fld5 {get; set;}                                                  // For capture of various pieces of data via forms

    // Style sheet class labels for controlling visibility of certain optional page features
    public String OptionalFeatures1Class {get; set;}                                // Ability to add related help
    public String OptionalFeatures2Class {get; set;}                                // Ability to add selected topic to current reading list
    public String OptionalFeatures3Class {get; set;}                                // Ability to add related help resource
    public String OptionalFeatures4Class {get; set;}                                // Ability to add current help topic to selected reading list 
    public String OptionalFeatures7Class {get; set;}                                // Ability to "select" a help topic / obtain its ID
    public String OptionalFeatures8Class {get; set;}                                // Ability to add a new Guide for enable mode
    public Boolean OptionalFeatures1Rendered {get; set;}                            
    public Boolean OptionalFeatures2Rendered {get; set;}                            
    public Boolean OptionalFeatures3Rendered {get; set;}                            
    public Boolean OptionalFeatures4Rendered {get; set;}                            
    public Boolean OptionalFeatures7Rendered {get; set;}                            
    public Boolean OptionalFeatures8Rendered {get; set;}                            

    // The default wording to display in the keyword search box if a user has entered no text
    // and there's no default from previous searches / cookies
    private static String DST = '[Enter search term]';
    public static String getDefaultSearchTerm() { return DST; }
    
    
    // For keeping track of permissions internally
    private Boolean isAuthor;
    private Boolean isAdministrator;
    
    
    // Records whether we're on an Apex page (required in checks of EG cookies / query parameters)
    private Boolean ApexPageExists;
        
        
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Initialisation routines
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    // Minimal initialisation
    public ControllerSearch() {
        mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false);
    }


    // Ensures GUI reflects user's recent search choices and rights
    private void initialise () {
        
        // Note whether or not we're on an Apex page (this information is required elsewhere e.g., when examining query parameters)
        ApexPageExists = ServiceSecurity.ApexPageExists();

        // Get localisation information (field labels etc):
        // We need a mix of "global", "branding" and cross screen labels and those which are screen specific.
        // The latter depends on the page being served...
        ControllerSettings cS = new ControllerSettings();
        
        mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false);
        mapBrdLocs = ServiceLocalisation.getDialogueLocalisations('Branding', false);
        
        
        if (Test.isRunningTest()) { 
            // Page address will not be "real" if we're in test mode, so hard wire dialogue name in these cases
            mapDlgLocs = ServiceLocalisation.getDialogueLocalisations('iahelp__IHSearchResults', false);
        } else {
            mapDlgLocs = ServiceLocalisation.getDialogueLocalisations(cS.SFObjId(Url.getCurrentRequestUrl().toExternalForm()), true);
        }
                            
        // Take note of our search parameters
        getQueryParms();
                
        // Create a search options object and use this to initialise our GUI
        Options = new SearchOptions();  
                
        // Initialise other key member data
        Diags='';
        
        // Until we know we have some search results...
        IsError = true;
                                        
        return;
    }


    // Extracts query parameters from incoming URL
    private void getQueryParms() {
        
        ServiceSecurity Security = new ServiceSecurity();        
        Boolean[] Perms;
                
        
        // Take note of the current user's security permissions
        Perms = Security.UserPermissions();
        isAuthor = Perms[1];
        isAdministrator = Perms[2];
        
        
        // Initialise member data:
        
        //v1.33+ : Note that we could be in a situation where member data is not coming from a URL (e.g., LUX)
        // so control for this here: assumption is if we're called from LUX, there's no Apex page, whereas if there
        // is an Apex page, we should supply params via URL...
        if (ApexPageExists) {
            
            // Help topic featured on calling page, if any
            HTID = ServiceSecurity.getQueryParameter('HTID', 2);
            if(HTID == '') {HTID = '-1';}
    
            // Search term
            //Term = ApexPages.currentPage().getParameters().get('Term');
            Term = ServiceSecurity.getQueryParameter('Term', 1);
            if(Term == null) {Term = '';}
                    
            // Reading List featured on calling page, if any
            RLID = ServiceSecurity.getQueryParameter('RLID', 2);
                    
            // For calls at page level (i.e., from an SF page), object ID of featured SF object
            objId = ServiceSecurity.getQueryParameter('ObjId', 2);
            if(objId == '') {objId = '-1';}
            
            // Context (URL) from which this page was called (important in cases such as Guide search results)
            callerPageURL = ServiceSecurity.getQueryParameter('IHContext', 0);
            
            // Addition search / sort options
            UserSort = ServiceSecurity.getQueryParameter('Srch', 2);
            // Switch controlling visibility of optional page features:
            // Initialise to hidden: only show if option specified and user has appropriate permissions                                    
            Opts = ServiceSecurity.getQueryParameter('Opts', 2);
            
            // LUX treatment (for VF page look & feel etc.)
            isIHLUX = ServiceSecurity.getQueryParameter('IHLUX', 2) == 'true';
                  
        } else {
            // Absence of VF page implies LUX
            isIHLUX = true;
        }     
        
        
        if(Opts == '') {Opts = '0';}
        

        if (Opts == '1' && (Perms[1] || Perms[2])) {
            OptionalFeatures1Class = '';
            OptionalFeatures1Rendered = true;
        } else {
            OptionalFeatures1Class = 'IHHidden';
            OptionalFeatures1Rendered = false;
        }

        if (Opts == '2' && (Perms[1] || Perms[2])) {
            OptionalFeatures2Class = '';
            OptionalFeatures2Rendered = true;
        } else {
            OptionalFeatures2Class = 'IHHidden';
            OptionalFeatures2Rendered = false;
        }               
                
        if (Opts == '3' && (Perms[1] || Perms[2])) {
            OptionalFeatures3Class = '';
            OptionalFeatures3Rendered = true;
        } else {
            OptionalFeatures3Class = 'IHHidden';
            OptionalFeatures3Rendered = false;
        }               

        if (Opts == '4' && (Perms[1] || Perms[2])) {
            OptionalFeatures4Class = '';
            OptionalFeatures4Rendered = true;
        } else {
            OptionalFeatures4Class = 'IHHidden';
            OptionalFeatures4Rendered = false;
        }       

        if (Opts == '7' && (Perms[1] || Perms[2])) {
            OptionalFeatures7Class = '';
            OptionalFeatures7Rendered = true;
        } else {
            OptionalFeatures7Class = 'IHHidden';
            OptionalFeatures7Rendered = false;
        }       

        if (Opts == '8' && (Perms[1] || Perms[2])) {
            OptionalFeatures8Class = '';
            OptionalFeatures8Rendered = true;
        } else {
            OptionalFeatures8Class = 'IHHidden';
            OptionalFeatures8Rendered = false;
        }       


        // Note any selected search results (e.g., a Guide selected for Guide Enable mode)
        Cookie ck;
        if (ApexPageExists) {
            ck = ApexPages.currentPage().getCookies().get('IHSelectedRL');
        }
        if (ck != null) {               
            SearchResultId = String.valueOf(ck.getValue());         
        }

        return;
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Entry point for a search results page - displays results of user's search
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    public void showSearchResults() {

        String sTerm = '';
        String objClause = '';
        ServiceInteractions sI = new ServiceInteractions();
        ServiceSecurity Security = new ServiceSecurity();
        Boolean[] Perms;
        Boolean showHName;
        Boolean showHSummary;
        Boolean showRName;
        Boolean showRSummary;
        Boolean showRURL;
        Boolean showRLName;
        Boolean showRLSummary;
        Integer numResults;
        String theHPL = null;
        String theHT = null;
        String excl;
        String[] exIds;
        Boolean bAdd;

        try {
            // We should begin by initialising the search results GUI, just as on a basic search page
            initialise();
                                
            // Take note of the current user's security permissions
            Perms = Security.UserPermissions();
            
            
            // Now instantiate our results lists ...
            PageHelp = new SearchResult[]{};
            FieldHelp = new SearchResult[]{};


            // Treat lack of any permissions as a problem (as we must check FLS).
            // So: no Help Permission Set assisnments at all = same effect as no subscription...            
            if (! (Perms[0] || Perms[1] || Perms[2] || Perms[3])) {
                Diags = mapGlbLocs.get('MessageNoPermissions');
                return;
            } 
            

            // Also, take note of various field level security (FLS) permissions
            showHName = Schema.sObjectType.HelpTopic__c.fields.Name.isAccessible();
            showHSummary = Schema.sObjectType.HelpTopic__c.fields.Summary__c.isAccessible();
            showRName = Schema.sObjectType.HelpResource__c.fields.Name.isAccessible();
            showRSummary = Schema.sObjectType.HelpResource__c.fields.Summary__c.isAccessible();
            showRURL = Schema.sObjectType.HelpResource__c.fields.ResourceURL__c.isAccessible();
            showRLName = Schema.sObjectType.HelpReadingList__c.fields.Name.isAccessible();
            showRLSummary = Schema.sObjectType.HelpReadingList__c.fields.Summary__c.isAccessible();
                
                
            // If search term is null, set this to the default
            if (Term == '' || Term == null) {
                sTerm = DST;
            } else {
                
                // We need to act in the same way as SF searching - so:
                // "%" to be treated as a literal
                // "*" to be the wildcard (to act as SOQL %)
                // "?" to act for any single character (to act as SOQL _)
                
                sTerm = Term;
                sTerm = sTerm.replace('%', '\\%');
                sTerm = sTerm.replace('*', '%');
                sTerm = sTerm.replace('?', '_');
                
                sTerm = '%' + sTerm + '%';       
            }
            Diags += 'Term was ' + sTerm + '... ';
            

            // First, Page Level:
    
            // These will be for any topic referenced by a helped element of type "page" (not field level etc)
            // whose identifier (i.e., the 3 letter SF object code) is per the current context:
            // The search page may or may not have been supplied with this 3 letter object ID...
                
            if (objId == '-1') {
                // If search page was NOT supplied with an object ID, 
                // we need to look this up from the topic's helped element's page layout
                try {

                    for (HelpedElement__c HE :
                    [SELECT HelpedPageLayout__c
                    FROM HelpedElement__c
                    WHERE HelpTopic__c = :HTID]
                    )
                    {                                                                               
                        // For each Helped Page Layout, get the Featured Object
                        for (HelpedPageLayout__c HPL :
                        [SELECT PageLayoutIdentifier__c
                        FROM HelpedPageLayout__c
                        WHERE Id = :HE.HelpedPageLayout__c]
                        ){
                            // Build these Featured Object records into a SOQL clause (Identifier = x OR Identifier = y etc)
                            objClause += HPL.PageLayoutIdentifier__c + ' OR Identifier__c=';                                                                
                        }
                                                
                        // Finalise the clause:
                        if (objClause != '') {
                            // If we found some Helped Page Layouts, and thus object IDs, remove final 'OR'
                            objClause = objClause.substring(0, objClause.length() - 18);
                                
                        } else {
                            // If not, set the clase to an 'exclude all' value
                            objClause = '-1';
                                
                        }
                                                
                    }
                                
                } catch (exception e) {
                    // If there were any errors with this, all we can do is set a "safe" selection clause
                    objClause = '-1';                       
                }             
                                        
            } else {
                // If we were given an object ID, use this to form the SOQL clause
                objClause = objId;
            }
            Diags += 'ObjId dealt with... ';
        
        
            // If we're linking to existing resources...
            if (Opts == '3') {
                Diags += 'Option 3 - link to resource... ';

                // NB: Here, as we're linking rather than just searching for any resource,
                // we need to exclude those to which we're already linked, so build
                // an exclusion clause here...
                excl = '';
                
                for (HelpTopicResource__c HTR : 
                [SELECT HelpResource__c
                FROM HelpTopicResource__c
                WHERE HelpTopic__c = :HTID]
                )
                {
                    excl += HTR.HelpResource__c + ',';
                }
                                        
                // Cut final comma and split
                if (excl.length() > 0) {
                    excl = excl.substring(0, excl.length()-1);
                    exIds = excl.split(',');
                } else {
                    exIds = null;
                }
                                
                for (HelpResource__c Res : 
                [SELECT Id, Name, Summary__c, ResourceURL__c 
                FROM HelpResource__c 
                WHERE Name Like :sTerm OR Summary__c Like :sTerm
                ORDER BY Name]
                ) 
                {
                    // Only add the resource if it's not on our excludes list...
                    bAdd = true;    
                    if (exIds != null){
                        for (String ex : exIds) {
                            if (Res.Id == ex) {
                                bAdd = false;
                                break;
                            }
                        }
                    }                       

                    if (bAdd == true) {
                        FieldHelp.add(New SearchResult(Res, showRName, showRSummary, showRURL));
                    }
                }

            }   // End if opts = 3 (Resources)


            // If we're linking to existing reading list...
            if (Opts == '4' || Opts == '8') {
                Diags += 'Option 4 or 8 - link to RL or select RL... ';
                
                // NB: if we're linking rather than just searching for any RL,
                // we need to exclude those to which we're already linked, so build
                // an exclusion clause here...
                excl = '';
                
                for (HelpReadingListEntry__c RLE : 
                [SELECT HelpReadingList__c
                FROM HelpReadingListEntry__c
                WHERE HelpTopic__c = :HTID]
                )
                {
                    excl += RLE.HelpReadingList__c + ',';
                }
                                        
                // Cut final comma and split
                if (excl.length() > 0) {
                    excl = excl.substring(0, excl.length()-1);
                    exIds = excl.split(',');
                } else {
                    exIds = null;
                }
                                
                for (HelpReadingList__c HRL : 
                [SELECT Id, Name, Summary__c, ReadingListType__c 
                FROM HelpReadingList__c 
                WHERE Name Like :sTerm OR Summary__c Like :sTerm
                ORDER BY Name]
                ) 
                {
                    bAdd = true;

                    // Option 4 - add to existing RL: 
                    // Only add the result if it's not on our excludes list...                   
                    if (Opts == '4') {
                        if (exIds != null){
                            for (String ex : exIds) {
                                if (HRL.Id == ex) {
                                    bAdd = false;
                                    break;
                                }
                            }
                        }                                               
                    }   
                    
                    // Option 8 - select RL:
                    // Only show Guides in this view 
                    if (Opts == '8') {
                        if (HRL.ReadingListType__c == 'Reading List' || HRL.ReadingListType__c == null) {
                            bAdd = false;
                        }
                    }

                    if (bAdd == true) {
                        FieldHelp.add(New SearchResult(HRL, showRLName, showRLSummary, False));
                    }
                }
                
            }   // End if Opts = 4 (Reading List)
            
            
            // If we're searching for Guides...
            if (Opts == '5') {
                Diags += 'Option 5 - search Guides... ';

                excl = '';
                                                
                // We want RLs whose first non-local step is for the current page layout:
                // I.e., guides that start from where we are - NOT all those that include a 
                // step featuring the current layout:
                
                // 1.17: Expanded search options,but also we only want RLs of a guide type
                
                // 1.22: Also, respect the "Active" flag for RLs (as reqd by user role)
                // Note use of Optional features rendering flag as proxy for author/admin permissions...
                
                HelpReadingListEntry__c[] RLEs = new HelpReadingListEntry__c[]{};
                try {
                    
                    if (Term == '') {sTerm = '*';}
                    if (UserSort == '' || UserSort == null) {UserSort = '3';}
                    
                    if (UserSort == '1') {
                        // Show all guides
                        RLEs = 
                        [SELECT HelpReadingList__c, ReadingOrder__c, HelpTopic__r.GuidedLayout__r.PageLayoutIdentifier__c, HelpTopic__r.GuideStepMode__c
                        FROM HelpReadingListEntry__c
                        WHERE (HelpReadingList__r.Name LIKE :sTerm OR HelpReadingList__r.Summary__c LIKE :sTerm)
                        AND (HelpReadingList__r.ReadingListType__c = 'Linear Guide' OR HelpReadingList__r.ReadingListType__c = 'Non-Linear Guide')
                        AND (HelpReadingList__r.Active__c = true OR HelpReadingList__r.Active__c = :!(isAuthor || isAdministrator))                          
                        ];
                    }

                    if (UserSort == '2') {
                        // Show Guides I own
                        RLEs = 
                        [SELECT HelpReadingList__c, ReadingOrder__c, HelpTopic__r.GuidedLayout__r.PageLayoutIdentifier__c, HelpTopic__r.GuideStepMode__c
                        FROM HelpReadingListEntry__c
                        WHERE HelpReadingList__r.Owner.Id = :UserInfo.getUserId()
                        AND (HelpReadingList__r.Name LIKE :sTerm OR HelpReadingList__r.Summary__c LIKE :sTerm)                      
                        AND (HelpReadingList__r.ReadingListType__c = 'Linear Guide' OR HelpReadingList__r.ReadingListType__c = 'Non-Linear Guide') 
                        AND (HelpReadingList__r.Active__c = true OR HelpReadingList__r.Active__c = :!(isAuthor || isAdministrator))                          
                        ];                      
                    }

                    if (UserSort == '3') {
                        // Show Guides for this page
                        RLEs = 
                        [SELECT HelpReadingList__c, ReadingOrder__c, HelpTopic__r.GuidedLayout__r.PageLayoutIdentifier__c, HelpTopic__r.GuideStepMode__c
                        FROM HelpReadingListEntry__c
                        WHERE HelpTopic__r.GuidedLayout__r.PageLayoutIdentifier__c = :objId
                        AND (HelpReadingList__r.Name LIKE :sTerm OR HelpReadingList__r.Summary__c LIKE :sTerm)                      
                        AND (HelpReadingList__r.ReadingListType__c = 'Linear Guide' OR HelpReadingList__r.ReadingListType__c = 'Non-Linear Guide') 
                        AND (HelpReadingList__r.Active__c = true OR HelpReadingList__r.Active__c = :!(isAuthor || isAdministrator))                          
                        ];                      
                    }
                    
                } catch (exception e) {     
                }
                
                for (HelpReadingListEntry__c RLE : RLEs)
                {
                    
                    if (excl.indexOf(RLE.HelpReadingList__c + ',') == -1) {
                            
                        // See if there's an entry in this RL that is NOT local,
                        // has a lower reading order and is not for the current layout
                        HelpReadingListEntry__c[] RLE2 = [
                            SELECT Id
                            FROM HelpReadingListEntry__c
                            WHERE HelpReadingList__c = :RLE.HelpReadingList__c
                            AND ReadingOrder__c < :RLE.ReadingOrder__c
                            AND HelpTopic__r.GuideStepMode__c != 'Local'
                            AND HelpTopic__r.GuidedLayout__r.PageLayoutIdentifier__c != :objId
                        ];
                            
                        if (RLE2.size() > 0) {
                            // If there is such an entry, this Guide should NOT feature in results
                            // list as it does not effectively "start" from where we are
                            Diags += 'RL ' + RLE.HelpReadingList__c + ' has non local step with lower order than ' + RLE.ReadingOrder__c + ' not for layout ' + objId + '... ';
                            
                        } else {
                            // There is no such entry - so we DO want to show this guide
                            Diags += 'No match in RL ' + RLE.HelpReadingList__c + ' for non local step with lower order than ' + RLE.ReadingOrder__c + ' not for layout ' + objId + '... ';
                            
                            HelpReadingList__c HRL = [
                                SELECT Id, Name, Summary__c, ReadingListType__c
                                FROM HelpReadingList__c 
                                WHERE Id=:RLE.HelpReadingList__c
                            ];
                                
                            FieldHelp.add(New SearchResult(HRL, showRLName, showRLSummary, True));  
                            
                            // Note the fact this Guide is in our list - so we don't add it more than once                      
                            excl += RLE.HelpReadingList__c + ',';
                                
                        }
                    }   
                } 

                // Having added search results, we want to tack on our SF record context for cases where 
                // the Guide author has not specified a particular record for the step, so intends the user 
                // to run the guide from the record they are on...
                for (SearchResult FH: FieldHelp) {
                    FH.Link += '&IHContext=' + this.callerPageURL;
                }
                            
                
            }   // End if Opts = 5 (Guides)
            
            
            // If we're showing Helped Elements for a given Topic
            if (Opts == '6') {
                Diags += 'Option 6 - search for Elements referencing Topic... ';
                
                for (HelpedElement__c HE :
                [SELECT Name, ElementType__c, Identifier__c, DataDrivenFilter__c, HelpedPageLayout__r.Name, HelpedPageLayout__r.PageLayoutIdentifier__c
                FROM HelpedElement__c
                WHERE HelpTopic__c = :HTID]
                )
                {
                    FieldHelp.add(New SearchResult(HE));                                                                              
                }
            }   // End if Opts = 6 (Helped elements for topic)
            
            
            if (Opts == '0' || Opts == '1' || Opts == '2' || Opts == '7') {
                Diags += 'Option 1, 2, 7 or none (0)... ';                  
                
                // If search option is 1 or 2, we are relating help topics to something:
                // In either case, we need to build an exclude list to avoid showing results
                // that, if added to relations, would be duplicates
                                    
                excl = '';                                

                if (Opts == '1') {
                    Diags += 'Option 1 - Add related help... ';
                                        
                    // For option 1, exclusions are existing related help topics:
                    // "Related" means any where current topic is listed as referring...
                                        
                    for (HelpRelationship__c HR : 
                    [SELECT RelatedHelpTopic__c
                    FROM HelpRelationship__c
                    WHERE ReferringTopic__c = :HTID]
                    )
                    {
                        excl += HR.RelatedHelpTopic__c + ',';
                    }                                       
    
                    // ... or related ...
                    for (HelpRelationship__c HR : 
                    [SELECT ReferringTopic__c
                    FROM HelpRelationship__c
                    WHERE RelatedHelpTopic__c = :HTID]
                    )
                    {
                        excl += HR.ReferringTopic__c + ',';
                    }                               
                                        
                    // ... and we don't want to relate the topic to itself...
                    excl += HTID + ',';
                }

                                
                // For option 2, exclusions are exising reading list entries
                if (Opts == '2') {
                    Diags += 'Option 2 - Add to current Reading List... ';
                                        
                    for (HelpReadingListEntry__c RLE : 
                    [SELECT HelpTopic__c
                    FROM HelpReadingListEntry__c
                    WHERE HelpReadingList__c = :RLID]
                    )
                    {
                        excl += RLE.HelpTopic__c + ',';
                    }                                       
                }
                                    

                // Cut final comma and split
                if (excl.length() > 0) {
                    excl = excl.substring(0, excl.length()-1);
                    exIds = excl.split(',');
                } else {
                    exIds = null;
                }
                                
                                
                // We should now have a SOQL clause we can use to obtain relevant helped elements
                for (HelpedElement__c HE :
                [SELECT HelpedPageLayout__c, HelpTopic__c, HelpTopic__r.Name, HelpTopic__r.Summary__c, HelpTopic__r.Active__c
                FROM HelpedElement__c
                WHERE ElementType__c = 'Page Help Link' AND (Identifier__c=:objClause)]
                )
                {
                    // For each element, add page help using the helped element's help topic ID:
                    if (Perms[1] || Perms[2]) {

                        // Authors / Admins get all results
                        PageHelp.add(New SearchResult(null, HE, showHName, showHSummary));                                                                              
                                                
                    } else {
                        // End users only get to see Active help topics
                        if (HE.HelpTopic__r.Active__c == true) {
                                PageHelp.add(New SearchResult(null, HE, showHName, showHSummary));
                        }
                    }
                }
                        
                        
                // Next, get any Field Level help appropriate to the search term...
                for (HelpTopic__c pH : 
                [SELECT Id, Name, Summary__c, Active__c 
                FROM HelpTopic__c 

                WHERE Name Like :sTerm OR Summary__c Like :sTerm 
                OR ImageCaption__c Like :sTerm OR ImageTitle__c Like :sTerm OR VideoCaption__c Like :sTerm OR VideoTitle__c Like :sTerm
                OR DescriptionText1__c Like :sTerm
                OR DescriptionText2__c Like :sTerm
                OR DescriptionText3__c Like :sTerm
                OR DescriptionText4__c Like :sTerm
                OR DescriptionText5__c Like :sTerm

                ORDER BY Name
                LIMIT 1000]
                ) 
                {
                    // Only add the topic if it's not on our excludes list...
                    bAdd = true;
                            
                    if (exIds != null){
                        for (String ex : exIds) {
                            if (pH.Id == ex) {
                                bAdd = false;
                                break;
                            }
                        }                                       
                    }
    
                    if (bAdd == true) {
                        if (Perms[1] || Perms[2]) {

                            // Authors / Admins get all results
                            FieldHelp.add(New SearchResult(pH, null, showHName, showHSummary));
                                                    
                        } else {
                            // End users only get to see Active help topics
                            if (pH.Active__c == true) {
                                FieldHelp.add(New SearchResult(pH, null, showHName, showHSummary));
                            }
                        }
                                                        
                    }
                
                }   
                                
                                
                // Set default help (the one to display on arrival at the results page):
                // to the first of the Page Level topics
                if (PageHelp.size() > 0) {
                    SearchResult defaultR = PageHelp[0];
                    DefaultSearchResult = defaultR.Link; 
                        
                } else {
                    // If no Page help available, try field help
                    if (FieldHelp.size() > 0) {
                        SearchResult defaultR = FieldHelp[0];
                        DefaultSearchResult = defaultR.Link; 
                    } else {
                        DefaultSearchResult = '';                       
                    }
                }
                                        
            } // Option 0, 1, 2 or 7 - Help Topic related ops.  
                        
            Diags += 'Options processed... ';
                        
                                        
            // Availability of certain controls is based on there being some search results
            IsError = DefaultSearchResult == '';
                    
    
            // Set the new cookie for the page
            Cookie SO = new Cookie('IAIHSearchOptions', 'Term=' + Term + ';Sort=' + UserSort, null, -1, false);

            // v1.33+ Deal with LUX situations where there is no Apex current page...
            if (ApexPageExists) {
                ApexPages.currentPage().setCookies(new Cookie[]{SO});           
            }
                
                
            // Log an interration about this search - but only if term was non-blank
            if (Term != '') {
                numResults = PageHelp.size() + FieldHelp.size();
                sI.logInteraction(7, Term, callerPageURL, theHPL, null, theHT, null, null);
            }
            
            // If we get here, we can re-set Diags...
            Diags = '';
            
                        
        } catch (exception e) {
            Diags = mapGlbLocs.get('MessageGenericError') + ' - ' + e.getMessage() + ' - ' + Diags;    
        }
        
        
        return;
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Class to encapsulate user's recent search choices and options
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    public class SearchOptions {
                
        public String Term {get; set;}
        public String SortOption {get; set;}
                
                
        // Retrieve options from cookie IAIHSearchOptions
        public SearchOptions () {
                        
            // Look for the cookie...
            Cookie SO;
            boolean ApexPageExists = ServiceSecurity.ApexPageExists();
            
            if (ApexPageExists) {
                SO = ApexPages.currentPage().getCookies().get('IAIHSearchOptions');
            }
        
        
            if (SO == null) {
                // If there is no cookie, use default values for member data
                Term = getDefaultSearchTerm();
                SortOption = '';
                
            } else {
                // If cookie is present, use it to populate our member data
                String val;
                String[] Opts;
                Integer i;
                String currentOpt;
                String currentVal;
                
                val = String.valueOf(SO.getValue());
                
                // Cookie value is in the form parm=value[;parm=value] etc.
                // So: split the cookie value by semi colon...
                Opts = val.split(';');
                
                // Then split each resulting name / value pair by equals...
                for (i=0; i<Opts.size(); i++) {
                    if (Opts[i].indexOf('=') != -1){
                        currentOpt = Opts[i].substring(0, Opts[i].indexOf('='));
                        currentVal = Opts[i].substring(Opts[i].indexOf('=')+1);                                 
                    } else {
                        currentOpt = '';
                    }
                    
                    // Examine each available element and use it to fill the appropriate member data
                    if (currentOpt == 'Term') {
                        Term = currentVal;
                    }
                    
                    if (currentOpt == 'Sort') {
                        SortOption = currentVal;
                    }
                    
                }
            }                       
        }               
    }



    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Classes to offer data sources for lists, where joins over SF objects are required
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    public class SearchResult {

        public String Id {get; set;}
        public String Name {get; set;}
        public String Link {get; set;}
        public String Summary {get; set;}
        
        // Specifics when searching for Guides (opt 5)
        public HelpReadingList__c RList {get; set;}
            
        // Specifics when searching for helped elements (opt 6)
        public String VIPLink {get; set;}
        public HelpedElement__c HelpedE {get; set;}
            
        
        // Constructor for building search results on the fly from strings
        public SearchResult () {
        }
        
        
        // Constructor when search is for a Resource
        public SearchResult (HelpResource__c HR, Boolean showName, Boolean showSummary, Boolean showURL){
            
            try {
                Id = HR.Id;
                    
                if (showName) {
                    Name = HR.Name;
                } else {
                    Name = '';
                }
                    
                if (showSummary) {
                    Summary = HR.Summary__c;
                } else {
                    Summary = '';
                }
    
                if (showURL) {
                    
                    // v1.11: we don't want, for now, to link to the resource itself,
                    // Rather we want to point the help editor to the resource record in SF...

                    // 1.23: use community address, where required
                    Link = ControllerSettings.getCommunityRoot();
                    if (Link == '') {
                        Link = URL.getOrgDomainURL().toExternalForm();
                    }                   
                    Link += '/' + HR.Id;
                    
                } else {
                    Link = '';
                }
                
            } catch (exception e) {
                Id = '';
                Name = 'Error!';
                Summary = e.getMessage();
            }
            
        }
            
        
        // Constructor when search is for a Helped Element (via Topic ID)
        public SearchResult (HelpedElement__c HE) {

            String Exemplar;
            ServiceSchema sS = new ServiceSchema();
            List<sObject> L;
            
            try {
                
                this.Name = HE.Name;
                this.HelpedE = HE;
                
                // Get name of the object represented on the page layout
                Schema.DescribeSObjectResult r = sS.getObjectDetails(HE.HelpedPageLayout__r.PageLayoutIdentifier__c);
                
                // Get a record of this type we can use as an exemplar
                if (r != null) {
                    L = Database.query('SELECT Id FROM ' + r.getName() + ' LIMIT 1');
                    Exemplar = L[0].Id;
                    
                } else {
                    // If the page layout doesn't involve an object identifier (e.g., a JSP or home page)
                    // all we can do is use the page layout id itself
                    Exemplar = HE.HelpedPageLayout__r.PageLayoutIdentifier__c;
                }
                
                
                // Insert the ID of this record into the required VIP URL
                // 1.23: use community address, where required
                VIPLink = ControllerSettings.getCommunityRoot();    
                if (VIPLink == '') {    
                    VIPLink = URL.getOrgDomainURL().toExternalForm();
                }                   
                
                VIPLink += '/' + Exemplar + '?IHVIP=' + system.Encodingutil.urlEncode(HE.Identifier__c, 'UTF-8').replace('+', '%20') + '%07' + HE.ElementType__c;

                // NB: ASPECTS OF SUMMARY ARE NOT INTERNATIONALISED HERE AS WE HAVE NO ACCESS TO 
                // PARENT CLASS STATIC MEMBER DATA FOR LOCALISATIONS AND ADDING REFS HERE WOULD BE COSTLY
                // IN TERMS OF LOOPED GETTING OF MAPS: ALSO, SUMMARY TEXT NOT CURRENTLY IN USE FOR OPT=6 / HELPED ELEMENT SEARCH:
                // SEE MARK UP OF SEARFCH RESULTS PAGE FOR DETAILS (THESE USE DIALOGUE LOCALISATIONS FROM THIS CONTROLLER / OUR CONTAINER CLASS)
                                
                // Summary in these cases features link to view Helped Element in place...
                this.Summary =  '<a target="_Blank" title="" href="' + VIPLink + '"><div style="float: right; margin: 2px 5px 0px 0px;" class="IHIcon16 IHIconModeView"></div></a>';
                
                // ... plus element type icon...
                this.Summary += '<div style="float: left; margin: 2px 5px 2px 0px;" title="' + HE.ElementType__c + '" class="IHIcon16 IHIcon' + HE.ElementType__c.replace(' ', '') + '"></div>';
                
                // ... plus element / layout name etc
                this.Summary += '<div style="float: left; padding-top: 4px;">Layout ' + HE.HelpedPageLayout__r.Name  + ': ' + HE.Identifier__c; 
                
                // ... plus data driven filter details
                if (HE.DataDrivenFilter__c == null) {
                    this.Summary += ': [-]</div>';
                } else {
                    this.Summary += ': F = \'' + HE.DataDrivenFilter__c + '\'</div>';
                }
                
                
                // Actual element link is to element maintenance screen
                
                // 1.23: use community address, where required
                this.Link = ControllerSettings.getCommunityRoot();
                if (this.Link == '') {
                    this.Link = URL.getOrgDomainURL().toExternalForm();
                }                   
                
                this.Link += '/apex/iahelp__IHHelpedElement?ElemId=' + system.Encodingutil.urlEncode(HE.Identifier__c, 'UTF-8') + '&HPL=' + HE.HelpedPageLayout__r.PageLayoutIdentifier__c + '&Mode=Read';
                
            } catch (exception e) {
                Name = 'Error!';
                Link = '#';
                Summary = e.getMessage();                           
            }
        }
            
        // Constructor when search is for a Topic (via Element ID or Topic ID)
        public SearchResult (HelpTopic__c HT, HelpedElement__c HE, Boolean showName, Boolean showSummary){
                        
            String HTID;
            // Do not assume portal is IHTools
            String PortalPage = ControllerSettings.getPortalPageName(false);
                        
            try {
                
                // Populate our member data: precise means of doing this
                // depends on the type of result record provided to us
                if (HT == null) {
                        
                    // Helped Element supplied                      
                    HTID = HE.HelpTopic__c;
                    Id = HE.HelpTopic__c;
                        
                    if (showName) {
                        Name = HE.HelpTopic__r.Name;
                    } else {
                        Name = '';
                    }

                    if (showSummary) {
                        Summary = HE.HelpTopic__r.Summary__c;
                    } else {
                        Summary = '';
                    }
                                                
                } else {
                        
                    // Help Topic supplied
                    HTID = HT.Id;
                    Id = HT.Id;
                        
                    if (showName) {
                        Name = HT.Name;
                    } else {
                        Name = '';
                    }

                    if (showSummary) {
                        Summary = HT.Summary__c;
                    } else {
                        Summary = '';
                    }                   
                        
                }

                // 1.23: use community address, where required
                Link = ControllerSettings.getCommunityRoot();
                if (Link == '') {
                    Link = URL.getOrgDomainURL().toExternalForm();
                }                   

                Link += '/apex/iahelp__' + PortalPage + '?HTID=' + HTID;
                                                                                    
            } catch (exception e) {
                Name = 'Error!';
                Link = '#';
                Summary = e.getMessage();             
            }
        }
        

        // Constructor when search is for a Reading List
        public SearchResult (HelpReadingList__c HRL, Boolean showName, Boolean showSummary, Boolean AsGuide){
            
            try {
                // Do not assume portal is IHTools              
                String PortalPage = ControllerSettings.getPortalPageName(false);
                
                Id = HRL.Id;
                this.RList = HRL;
                
                
                if (showName) {
                    Name = HRL.Name;
                } else {
                    Name = '';
                }
                    
                if (showSummary) {
                    Summary = HRL.Summary__c;
                } else {
                    Summary = '';
                }

                // Link for a reading list depends on whether we intend to view as a Guide.
                if (AsGuide == false) {
                    // Orinarily, we should get a link to first topic:
                    // We supply reading list ID here, help controller does the re-direct
                    
                    // 1.23: use community address, where required
                    Link = ControllerSettings.getCommunityRoot();
                    if (Link == '') {
                        Link = URL.getOrgDomainURL().toExternalForm();
                    }                   
                    
                    Link += '/apex/iahelp__' + PortalPage + '?RLID=' + HRL.Id;
                    
                } else {
                    // For Guides, we go to RL viewer in Guide mode:

                    // 1.23: use community address, where required
                    Link = ControllerSettings.getCommunityRoot();
                    if (Link == '') {
                        Link = URL.getOrgDomainURL().toExternalForm();
                    }                   
                    
                    Link += '/apex/iahelp__IHReadingListViewer?Opts=Guide&RLID=' + HRL.Id;
                }
                 
                
                
            } catch (exception e) {
                Name = 'Error!';
                Link = '#';
                Summary = e.getMessage();
            }
        }
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Guide related functions
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    // Take note of the Guide (Reading List) selected in the search dialogue for later use
    public PageReference selectReadingList () {
        
        try {
            // Set a cookie (available to VF domain later) recording the selected reading list
            Cookie ck = new Cookie('IHSelectedRL', SearchResultId, null, -1, false);
            ApexPages.currentPage().setCookies(new Cookie[]{ck});                                   
            
            // 1.21: we cannot pass Diags and reliably enable repeat searches: see Search results page
            // for presentation of Diags, on the basis of mode = 8 (Guide/RL select) and a selection having been made...
            //Diags = 'Your selection has been noted: please close this dialogue to continue.';
            
        } catch (exception e) {
            Diags = mapGlbLocs.get('MessageGenericError') + ' (Select Reading List) - ' + e.getMessage();
            
            // If there is an error, we can force diags by not returning a full page ref
            SearchResultId = null;
            return null;
        }
        
        // To retain all the parameters in use, pass back a populated page ref      
        String s = URL.getCurrentRequestUrl().toExternalForm() + '?Opts=8&Term=' + Term;
        return new PageReference(s);
        
    }
    
    
    // Record the fact that a new guide is to be created through guide enable mode
    public PageReference enableNewGuide () {
        try {
            // Here, we want to record the fact that a new Guide is to be created:
            // It is for the post-confirmation dialogue process (i.e., ControllerConfirmActions.saveChanges)
            // to actually create this guide. 
            // Therefore, here we simply record "NEW" in the appropriate guide enable cookie...
            SearchResultId = 'NEW';
            return selectReadingList();
            
        } catch (exception e) {
            
        }
        
        return null;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Related help / reading list manipulation functions
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    
    // Adds a new related resource record (relating selected, EXISTING Resource to the current Help Topic)
    public PageReference addRelatedResource () {
                
        String retVal;
        ServiceSecurity Security = new ServiceSecurity();

        // Initialise to no error
        IsError = false;
                                
        try {
                        
            if (Security.IsAllowed(ServiceSecurity.KnownSecureOperations.EditHelp) == true) {
                                
                HelpTopicResource__c HTR = new HelpTopicResource__c();
                HelpResource__c HR = [SELECT Name, Summary__c FROM HelpResource__c WHERE Id=:SearchResultId];
                HelpTopic__c Hlp = [SELECT Name FROM HelpTopic__c WHERE Id=:HTID];
                
                HTR.HelpResource__c = SearchResultId;
                HTR.HelpTopic__c = HTID;
                HTR.UsageNotes__c = '' + HR.Summary__c;
                
                // Avoid 'untidy' summary / title text
                if (HTR.UsageNotes__c == 'null') {HTR.UsageNotes__c = '';}
                
                insert HTR;
                
                retVal = mapGlbLocs.get('MessageGenericTaskComplete');
                    
            } else {
                retVal = mapGlbLocs.get('MessageNoRights');
                IsError = true;
                
            }               
                        
        } catch (exception e) {
            // Cater for the most common errors
            String S = e.getMessage();
            if(S.indexOf('REQUIRED_FIELD_MISSING') != -1) {
                retVal = mapDlgLocs.get('MessageCreateAndRelateOpt3Error');
            } else {
                retVal = mapGlbLocs.get('MessageGenericError') + ' ' + S;
            }
                        
            IsError = true;
        }
                
        Diags = retVal;
        return null;
    }
    
    
    // Adds a NEW Help Resource then relates it to the current Help Topic
    public PageReference createRelatedResource() {

        String retVal;
        ServiceSecurity Security = new ServiceSecurity();

        // Initialise to no error
        IsError = false;
                                
        try {
                
            if (Security.IsAllowed(ServiceSecurity.KnownSecureOperations.EditHelp) == true) {
                    
                // Create a new resource
                HelpResource__c HR = new HelpResource__c();
                
                // Set name as user wanted it
                HR.Name = fld1;
                HR.Summary__c = fld2;
                HR.ResourceURL__c = fld3;
                HR.ResourceType__c = fld4;
                HR.Location__c = fld5;
                
                
                // Save this, then set it as the "search result"
                insert HR;
                SearchResultId = HR.Id; 
                
                // Now proceed as if linking an existing topic
                addRelatedResource();
                retVal = Diags;
                    
            } else {
                retVal = mapGlbLocs.get('MessageNoRights');
                IsError = true;
                    
            }               
                
        } catch (exception e) {
            // Cater for the most common errors
            String S = e.getMessage();
            if(S.indexOf('REQUIRED_FIELD_MISSING') != -1) {
                retVal = mapDlgLocs.get('MessageCreateAndRelateOpt3Error');
            } else {
                retVal = mapGlbLocs.get('MessageGenericError') + ' ' + S;
            }
            
            IsError = true;
        }
                
        Diags = retVal;
        return null;
    }

    
    // Adds a new related help record (relating selected help topic to the current one)
    public PageReference addRelatedHelp () {
                
        String retVal;
        ServiceSecurity Security = new ServiceSecurity();
        
        // Initialise to no error
        IsError = false;
                                
        try {
                        
            if (Security.IsAllowed(ServiceSecurity.KnownSecureOperations.EditHelp) == true) {
                HelpRelationship__c HR = new HelpRelationship__c();                     
                HelpTopic__c Hlp1 = [SELECT Name FROM HelpTopic__c WHERE Id=:HTID];
                HelpTopic__c Hlp2 = [SELECT Id, Name FROM HelpTopic__c WHERE Id=:SearchResultId];
                
                
                HR.ReferringTopic__c = HTID;
                HR.RelatedHelpTopic__c = SearchResultId;
                
                // Default the relationship in these cases to type (semantic tag) = "Relative"
                HR.SemanticTag__c = ControllerSettings.getSettings().DefaultRelationshipSemanticTag__c;
                
                insert HR;
                
                retVal = mapGlbLocs.get('MessageGenericTaskComplete');
                    
            } else {
                retVal = mapGlbLocs.get('MessageNoRights');
                IsError = true;
                    
            }               
                        
        } catch (exception e) {         
            // Cater for the most common errors
            String S = e.getMessage();
            if(S.indexOf('REQUIRED_FIELD_MISSING') != -1) {
                retVal = mapDlgLocs.get('MessageCreateAndRelateOpt1Error');
            } else {
                retVal = mapGlbLocs.get('MessageGenericError') + ' - ' + S;
            }

            IsError = true;
        }
                
        Diags = retVal;
        return null;
    }


    // Adds a new Help Topic then relates it to the current one
    public PageReference createRelatedHelp() {
                
        String retVal;
        ServiceSecurity Security = new ServiceSecurity();
                                
        try {
                        
            if (Security.IsAllowed(ServiceSecurity.KnownSecureOperations.EditHelp) == true) {

                // Create a new topic
                ControllerHelpContent cH = new ControllerHelpContent();
                HelpTopic__c Hlp = cH.getDefaultHelpTopic();
                                
                // Set name as user wanted it
                Hlp.Name = fld1;
                Hlp.Summary__c = fld2;
                
                // Save this, then set it as the "search result"
                insert Hlp;
                SearchResultId = Hlp.Id; 
                
                // Now proceed as if linking an existing topic
                addRelatedHelp();
                retVal = Diags;
                
            } else {
                retVal = mapGlbLocs.get('MessageNoRights');
                    
            }               
                
        } catch (exception e) {
            
            // Cater for the most common errors
            String S = e.getMessage();
            if(S.indexOf('REQUIRED_FIELD_MISSING') != -1) {
                retVal = mapDlgLocs.get('MessageCreateAndRelateOpt1Error');
            } else {
                retVal = mapGlbLocs.get('MessageGenericError') + ' ' + S;
            }
        }
                
        Diags = retVal;                
        return null;
    }


    // Adds the specified (existing) Help Topic to the current Reading List
    public PageReference addRLEntry() {
            
        String retVal;
        ServiceIHLists.ReadingList RL = new ServiceIHLists.ReadingList();
        ServiceSecurity Security = new ServiceSecurity();
        
        // Initialise to no error
        IsError = false;
        
        try {
            if (Security.IsAllowed(ServiceSecurity.KnownSecureOperations.EditHelp) == true) {
                retVal = RL.addItem(SearchResultId, RLID);                

                // Success message here is list service's message, not one of ours or a global...
                // I.e., "Reading List Entry added successfully" or similar...
                IsError =!(retVal == ServiceLocalisation.getDialogueLocalisations('ServiceIHLists', false).get('MessageAddedRLEntry'));
                
            } else {
                retVal = mapGlbLocs.get('MessageNoRights');
                IsError = true;
            }
                
        } catch (exception e) {
            retVal = mapGlbLocs.get('MessageGenericError') + ' - ' + e.getMessage();
            IsError = true;
        }
        
        Diags = retVal;
        return null;
    }

        
    // Creates a new Help Topic then adds this to the current Reading List
    public PageReference createRLEntry() {
            
        String retVal;
        ServiceSecurity Security = new ServiceSecurity();
            
        // Initialise to no error
        IsError = false;
            
        try {
            if (Security.IsAllowed(ServiceSecurity.KnownSecureOperations.EditHelp) == true) {
                    
                // Create a new topic
                ControllerHelpContent cH = new ControllerHelpContent();
                HelpTopic__c Hlp = cH.getDefaultHelpTopic();
                
                // Set name as user wanted it
                Hlp.Name = fld1;
                Hlp.Summary__c = fld2;
                
                // Save this, then set it as the "search result"
                insert Hlp;
                SearchResultId = Hlp.Id; 
                
                // Now proceed as if linking an existing topic
                addRLEntry();
                retVal = Diags + ' (' + Hlp.Name + ')';
                    
            } else {
                retVal = mapGlbLocs.get('MessageNoRights');
                IsError = true;
            }
            
        } catch (exception e) {
            // Cater for the most common errors
            String S = e.getMessage();
            if(S.indexOf('REQUIRED_FIELD_MISSING') != -1) {
                retVal = mapDlgLocs.get('MessageCreateAndRelateOpt2Error');
            } else {
                retVal = mapGlbLocs.get('MessageGenericError') + ' - ' + S;
            }
            
            IsError = true;
        }
        
        Diags = retVal;
        return null;            
    }


    // Adds the current help topic to a searched for and selected reading list
    public PageReference addTopicToRL() {

        String retVal;
        ServiceIHLists.ReadingList RL = new ServiceIHLists.ReadingList();
        ServiceSecurity Security = new ServiceSecurity();
        
        // Initialise to no error
        IsError = false;
        
        try {
            if (Security.IsAllowed(ServiceSecurity.KnownSecureOperations.EditHelp) == true) {
                
                // Search result is a reading list ID;
                // We need to add this to the page's current help topic             
                retVal = RL.addItem(HTID, SearchResultId);                

                // Success message here is list service's message, not one of ours or a global...
                // I.e., "Reading List Entry added successfully" or similar...
                IsError =!(retVal == ServiceLocalisation.getDialogueLocalisations('ServiceIHLists', false).get('MessageAddedRLEntry'));
                
                
            } else {
                retVal = mapGlbLocs.get('MessageNoRights');
                IsError = true;
            }
            
            
        } catch (exception e) {
            retVal = mapGlbLocs.get('MessageGenericError') + ' - ' + e.getMessage();
            IsError = true;
        }
        
        Diags = retVal;
        return null;            
    }    
}