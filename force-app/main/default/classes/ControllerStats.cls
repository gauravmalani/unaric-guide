/////////////////////////////////////////////////////////////////////////////////////////////////////
// PAGE CONTROLLER CLASS FOR VF PAGES THAT REQUIRE STATISTICS ON IH USAGE
//
// Martin Little for Improved Apps
// November 2012
/////////////////////////////////////////////////////////////////////////////////////////////////////


public with sharing class ControllerStats {

    // Global settings info - full URL of customer override stylesheet
    public static String getBrandCSS() {return ControllerSettings.getSettings().BrandCSS__c;}

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


    public String ElemId {get; set;}                    // Id of Helped Element whose stats are sought
    public String HTID {get; set;}                      // Help topic associated with this element
    public String HPL {get; set;}                       // Page layout identifier applicable to ElemId
    public Boolean isIHLUX {get; set;}                  // True if parameter passed to indicate viewing via the Lightning UX
    public String ElemName {get; set;}                  // Name of the same
    public HelpedElement__c[] HEs {get; set;}           // Where multiple matching elements exist, the collection of these
    public String RequestedElemId {get; set;}           // Of these, the Id of the selected element
    public String MoreLink {get; set;}                  // A link to ineraction details
    public Integer NumSummaryViews {get; set;}          // Output of stats data
    public Integer NumFullViews {get; set;}             // Output of stats data
    public Integer NumComments {get; set;}              // Output of stats data
    public Integer NumVotes {get; set;}                 // Output of stats data
    public Integer NumIssues {get; set;}                // Output of stats data
    public String IssuesWarning {get; set;}             // If there are issues, a warning thereof
    public GraphData[] GraphInfo {get;set;}             // Stats data to display on a graph
    public String limitExceedMsg {get; set;}            // Diagnostics message to display if SOQL limits are exceeded in getting stats


    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Known entities around which statistics can be gathered
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    public Enum KnownAnalysisModes {
        ByHelpedElement,
        ByHelpTopic,
        ByPageLayout
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Chart data encapsulation class
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    public class GraphData {

        public String itemName { get; set; }
        public Integer itemValue { get; set; }
        public String itemTip {get; set;}

        public GraphData(String itemName, Integer itemValue) {
            this.itemName = itemName;
            this.itemValue = itemValue;
            
            // This field added v1.15 (summer 13 SF release) to avoid 
            // text overlays appearing on SF pie chart object
            this.itemTip = '.';
        }
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Constructors & Initialisation routines
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    
    // Extracts query parameters from incoming URL
    private void getQueryParms() {
             
        // Attempt to get query parameters, if these exist
        ElemId = ServiceSecurity.getQueryParameter('ElemId', 1);        
        HTID = ServiceSecurity.getQueryParameter('HTID', 2);
        HPL = ServiceSecurity.getQueryParameter('HPL', 2);
        RequestedElemId = ServiceSecurity.getQueryParameter('Id', 2);
        
        // cf ControllerSettings.getPortalPageName and ControllerIHQAMSettings.isIHLUX - as these have their own variant logic:
        // We're only interested in direct instructions - not global settings: we always want to supress certain items in LUX,
        // whether or not branding is swapped, and we also DON'T want to suppress others unless we're told to...
        if (ServiceSecurity.getQueryParameter('IHLUX', 2) == 'true') {
            isIHLUX = true;
        } else {
            isIHLUX = false;
        }                               
                
        return;
    }


    // Initialise member data
    private void initialiseStats() {
        ElemId = '';
        ElemName = '';
        NumSummaryViews = -1;
        NumFullViews = -1;
        NumComments = -1;
        NumVotes = -1;
        NumIssues = -1;
        IssuesWarning = '';
        MoreLink = '';
        limitExceedMsg='';

        
        // Get localisation information (field labels etc):
        // We need a mix of "branding" and cross screen labels and those which are screen specific.
        // The latter depends on the page being served...
        ControllerSettings cS = new ControllerSettings();

        mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false);
        mapBrdLocs = ServiceLocalisation.getDialogueLocalisations('Branding', false);
        if (Test.isRunningTest()) {
            // Page address will not be "real" if we're in test mode, so hard wire dialogue name in these cases 
            mapDlgLocs = ServiceLocalisation.getDialogueLocalisations('iahelp__IHStats', false);
        } else {
            mapDlgLocs = ServiceLocalisation.getDialogueLocalisations(cS.SFObjId(Url.getCurrentRequestUrl().toExternalForm()), true);
        }

        
        GraphInfo = new GraphData[] {};     
    }

    
    // Returns the number of SOQL query rows that remain available for the current request:
    // This is used to avoid situations where large numbers of interactions could result in SOQL limits being exceeded.
    // Returns a positive integer, or zero if row limits have been reached 
    private static Integer getRemainingQueryRows()
    {
        Integer lcount = Limits.getLimitQueryRows() - Limits.getQueryRows();
        return lcount;
    }
    
    
    // Returns a diagnostics string where SOQL limits have been breeched (or empty string if not)
    private static String checkRemainingQueryRows(String limitMsgVar)
    {
        String limitMsg = '';
        if(getRemainingQueryRows() == 0){
            limitMsg = limitMsgVar + '.';
        }
        return limitMsg;
    }

    // Function to actually obtain stats information and related member data
    private void getStatistics() {

        List <HelpInteraction__c> HI;
        String theTopic;
        HelpTopic__c HT;
        HelpedElement__c HE;
        String theElement;
        String Diags;
        Integer i;


        try {
            
            Diags = 'About to get statistics... ';
            
            // Way we get stats depends on what the subject is...
            if (HTID == '' || HTID == null) {
                
                Diags += 'HTID not present: continuing... ';
                                
                if (ElemId != '' && ElemID != null) {               
                    // Element level stats
                    // Get the element specified directly by ID
                    Diags += 'Element Id (' + ElemId + ') was present: seeking element by this and HPL (' + HPL + ')... ';              
                    
                    HEs = [SELECT Id, Identifier__c, HelpTopic__c, Name 
                        FROM HelpedElement__c 
                        WHERE Identifier__c = :ElemId
                        AND HelpedPageLayout__r.PageLayoutIdentifier__c =:HPL];                 
                                    
                } else {
                    // Page level stats
                    // Get the helped element representing the page layout
                    Diags += 'Element Id not present - seeking element as Page Help Link for HPL (' + HPL + ')... ';

                    HEs = [SELECT Id, Identifier__c, HelpTopic__c, Name 
                        FROM HelpedElement__c 
                        WHERE ElementType__c = 'Page Help Link'
                        AND HelpedPageLayout__r.PageLayoutIdentifier__c =:HPL];
                }
                
                
                // If no specific match within possibly multiple elements with a given identifier
                // was specified, take the first match we found to e the requested one
                if (RequestedElemId == '') {
                    RequestedElemId = HEs[0].Id;
                }
                
                // Now locate this element's record from the matches
                for (HelpedElement__c H : HEs) {
                    if (H.Id == RequestedElemId) {
                        HE = H;
                        break;
                    }
                }
                
                                
                theTopic = HE.HelpTopic__c;
                theElement = HE.Id;
                
                try {
                    HT = [SELECT Id,Name FROM HelpTopic__c WHERE Id=:theTopic]; 
                } catch (exception e) {
                    // There may not be a help topic matching the one specified in the element...
                    Diags += 'Help topic was NOT located from the information given in the Helped Element... ';
                }

                if (Schema.sObjectType.HelpedElement__c.fields.Name.isAccessible()) {
                    ElemName = HE.Name;
                } else {
                    ElemName = '';
                }

            } else {
                Diags += 'HTID (' + HTID + ') was present... ';
                theTopic = HTID;
                HT = [SELECT Id,Name FROM HelpTopic__c WHERE Id=:theTopic]; 
                
                if (Schema.sObjectType.HelpTopic__c.fields.Name.isAccessible()) {
                    ElemName = HT.Name;
                } else {
                    ElemName = '';
                }
                
            }
            

            // Get summary view interactions: these are always by topic
            try {
                HI = [SELECT Id FROM HelpInteraction__c 
                        WHERE HelpInteractionType__c = 'Callout'
                        AND HelpTopic__c = :theTopic
                        LIMIT :getRemainingQueryRows()];
                    
                this.NumSummaryViews = HI.size();
                HI.clear();
                
                if (limitExceedMsg == '') {
                    limitExceedMsg = checkRemainingQueryRows('Callout');
                    if (limitExceedMsg != '') {limitExceedMsg = mapDlgLocs.get('AdviceLabelSOQLLimitsExceeded') + ' ' + limitExceedMsg;}
                }
                
            } catch (exception e) {
                this.NumSummaryViews = 0;
            }
            Diags += 'Summary info recorded, continuing... ';
            
            
            // Get full view interactions: these are always by topic
            try {
                HI = [SELECT Id FROM HelpInteraction__c 
                        WHERE HelpInteractionType__c = 'Full Topic'
                        AND HelpTopic__c = :theTopic
                        LIMIT :getRemainingQueryRows()];
                    
                this.NumFullViews = HI.size();
                HI.clear();
                
                if (limitExceedMsg == '') {
                    limitExceedMsg = checkRemainingQueryRows('Full Topic');
                    if (limitExceedMsg != '') {limitExceedMsg = mapDlgLocs.get('AdviceLabelSOQLLimitsExceeded') + ' ' + limitExceedMsg;}
                }
                
            } catch (exception e) {
                this.NumFullViews = 0;
            }
            Diags += 'Full view info recorded, continuing... ';
                

            // Get Vote interactions: these are always by topic
            try {
                HI = [SELECT Id FROM HelpInteraction__c 
                        WHERE HelpInteractionType__c = 'Vote'
                        AND HelpTopic__c = :theTopic 
                        LIMIT :getRemainingQueryRows()];
                    
                this.NumVotes = HI.size();
                HI.clear();
                
                if (limitExceedMsg == '') {
                    limitExceedMsg = checkRemainingQueryRows('Vote');
                    if (limitExceedMsg != '') {limitExceedMsg = mapDlgLocs.get('AdviceLabelSOQLLimitsExceeded') + ' ' + limitExceedMsg;}
                }
                
            } catch (exception e) {
                this.NumVotes = 0;
            }
            Diags += 'Vote info recorded, continuing... ';


            // Get comment interactions
            try {
                if (HTID == '' || HTID == null){
                    
                    if (ElemId == '' || ElemId == null) {
                        // Searching for page level comments
                        HI = [SELECT Id FROM HelpInteraction__c WHERE HelpInteractionType__c = 'Comment'
                            AND HelpedPageLayout__r.PageLayoutIdentifier__c = :HPL 
                            AND (HelpedElement__c = null OR HelpedElement__c = '') 
                            LIMIT :getRemainingQueryRows()];                        
                        
                    } else {
                        // Searching for element level comments - but these are against topic
                        HI = [SELECT Id FROM HelpInteraction__c WHERE HelpInteractionType__c = 'Comment'
                            AND HelpTopic__c = :theTopic 
                            LIMIT :getRemainingQueryRows()];
                        
                    }

                } else {
                    // Searching for topic level comments
                    HI = [SELECT Id FROM HelpInteraction__c WHERE HelpInteractionType__c = 'Comment'
                        AND HelpTopic__c = :theTopic 
                        LIMIT :getRemainingQueryRows()];
                }
                
                    
                this.NumComments = HI.size();
                HI.clear();
                
                if (limitExceedMsg == '') {
                    limitExceedMsg = checkRemainingQueryRows('Comment');
                    if (limitExceedMsg != '') {limitExceedMsg = mapDlgLocs.get('AdviceLabelSOQLLimitsExceeded') + ' ' + limitExceedMsg;}
                }
                
            } catch (exception e) {
                this.NumComments = 0;               
            }
            Diags += 'Comment info recorded, continuing... ';
            
            
            // Get issue interactions
            try {
                if (HTID == ''){
                    
                    // Remember, we may or may not have got a help topic via element...
                    if (HT != null) {
                        HI = [SELECT Id FROM HelpInteraction__c WHERE HelpInteractionType__c = 'Issue'
                            AND (HelpedElement__c = :theElement OR HelpTopic__c = :HT.Id) 
                            LIMIT :getRemainingQueryRows()];
                    } else {
                        HI = [SELECT Id FROM HelpInteraction__c WHERE HelpInteractionType__c = 'Issue'
                            AND HelpedElement__c = :theElement 
                            LIMIT :getRemainingQueryRows()];
                    }
                    
                } else {
                    HI = [SELECT Id FROM HelpInteraction__c WHERE HelpInteractionType__c = 'Issue'
                        AND HelpTopic__c = :theTopic 
                        LIMIT :getRemainingQueryRows()];
                }
                     
                this.NumIssues = HI.size();
                HI.clear();
                
                if (limitExceedMsg == '') {
                    limitExceedMsg = checkRemainingQueryRows('Issue');
                    if (limitExceedMsg != '') {limitExceedMsg = mapDlgLocs.get('AdviceLabelSOQLLimitsExceeded') + ' ' + limitExceedMsg;}
                }
                
            } catch (exception e) {
                this.NumIssues = 0;             
            }
            Diags += 'Issues info recorded, continuing... ';
            
            
            // Add all stats to our collection of graph data elements
            this.GraphInfo.add(new GraphData('Callouts', this.NumSummaryViews));
            this.GraphInfo.add(new GraphData('Topics', this.NumFullViews));
            this.GraphInfo.add(new GraphData('Comments', this.NumComments));
            this.GraphInfo.add(new GraphData('Votes', this.NumVotes));
            
            // NB: we don't want issues on the graph for now
            //this.GraphInfo.add(new GraphData('Issues', this.NumIssues));
            
            // Instead, add an issues warning if any exists
            if (NumIssues > 0){
                IssuesWarning = 'There are configuration issues logged for this item.';
            }
            Diags += 'Graph data set - about to create more link... ';  
  
            this.MoreLink = initialiseMoreLink(HT);          
            Diags += 'More Link set... ';
            
        } catch (exception e) {
            
            // Make issue available via more link...
            this.MoreLink = 'javascript:alert(\'' + string.escapeSingleQuotes(mapGlbLocs.get('MessageGenericError')) + ' - ' + e.getMessage() + ': Diagnostics: ' + Diags + '\')';
        }   
        
        return;
        
    }

    
    // Standard version
    public ControllerStats() {}


    // For use throughout Improved Help where certain stats specific functions are required
    public ControllerStats(KnownAnalysisModes Mode, String SubjectIdentifier) {
        
        try {
            // Initialise member data
            initialiseStats();
            
            // Set data that, if entry point were a page, would come from query string
            if (Mode == KnownAnalysisModes.ByHelpedElement) {
                ElemId = SubjectIdentifier; 
                HTID = '';
                HPL = '';   
            }   
            
            if (Mode == KnownAnalysisModes.ByHelpTopic) {
                HTID = SubjectIdentifier;
                ElemId= '';
                HPL = '';
            }
            
            if (Mode == KnownAnalysisModes.ByPageLayout) {
                HPL = SubjectIdentifier;
                HTID = '';
                ElemId = '';
            }
            
            // Use this to get actual statistics
            getStatistics();
            
        } catch (exception e) {
            // Use issues warning text to show any problems
            IssuesWarning += mapGlbLocs.get('MessageGenericError') + ' - ' + e.getMessage();
            
        }
    }
            
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Entry point for pages using ControllerStats as a page controller
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    public void getStats() {

        try {
            // Initialise our member data
            initialiseStats();
            
            // Take note of our search parameters
            getQueryParms();
    
            // Use these to get actual statistics
            getStatistics();

        } catch (exception e) {
            
            // Use issues warning text to show any problems
            IssuesWarning += mapGlbLocs.get('MessageGenericError') + ' - ' + e.getMessage();
            
        }   
        
        return;
    }
    
    
    // Call for those (such as ControllerHelpContent.getHelp) that just want a link to stats reports, without
    // actually having to generate all stats!
    public static string initialiseMoreLink(HelpTopic__c HT) {
        
        string retVal;
        string reportId; // Added as part of lightning report url fix
        
        try {
            // Set up the link to details report: Use community path, if relevant
            String RootUrl = ControllerSettings.getCommunityRoot();
            if (RootUrl == '') {
                RootUrl = URL.getOrgDomainURL().toExternalForm();
            }           
            retVal = RootUrl; 
            
            
            // We know the name of the report we want: use this to get the id...
            // 1.24.26: In case an unsuitable license type has been granted Author / Admin permission set,
            // check here that reports are available to the user...
            if (Schema.sObjectType.Report.isAccessible() && ServiceSecurity.CanRunReports()) {
                try{
                    Report Rpt = [SELECT Id, Name FROM Report  WHERE DeveloperName = 'Interaction_In_Situ_Drill_Thru_Report'];
                    retVal += '/' + Rpt.Id;
                    }
                    catch(Exception ex){
                        retVal ='';
                    }
                
            } else {
                return '';
            }

            
            // Drill value is the name of the help topic whose stats we're viewing...
            // Remember: we may or may not have a help topic by this stage...
            try {
                // Amended as part of lightning report link fixing - start
                // String s = HT.Name;             
                // s = EncodingUtil.urlEncode(s, 'UTF-8'); 
                system.debug(' ServiceSecurity.getQueryParameter '+ServiceSecurity.getQueryParameter('IHLUX', 2));                
                if(ServiceSecurity.getQueryParameter('IHLUX', 2) == ''){
                    retVal += '?pv0=' + HT.Id;
                }
                else if(ServiceSecurity.getQueryParameter('IHLUX', 2) == 'true'){
                    
                    try{
                            reportId = [SELECT Id, Name FROM Report  WHERE DeveloperName = 'Interaction_InSitu_Drill_Thru_LEX_C3H'].Id;
                            retVal = '/lightning/r/'+reportId+'/view?fv0=' + HT.Id;
                          // system.debug(' retVal'+retVal);
                      }
                      catch(Exception ex){
                        retVal ='';
                      }
                }
                // End
            } catch (exception e) {             
            }
            
            // ...and this is a fixed parameter
            retVal += '&drilldown=1';
            
        } catch (exception e) {
            retVal = 'javascript:alert(\'(Initialise Stats More Link): ' + e.getmessage() + '\')';
        }
        
        return retVal;
    }
    
}