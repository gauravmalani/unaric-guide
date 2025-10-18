/////////////////////////////////////////////////////////////////////////////////////////////////////
// PAGE CONTROLLER CLASS FOR VF PAGES THAT ARE TO BE USED TO DISPLAY HelpTopic-CENTRIC INFORMATION
//
// Martin Little for Improved Apps
// May 2012
/////////////////////////////////////////////////////////////////////////////////////////////////////


global with sharing class ControllerHelpContent {
    
    // Required so that test scripts can instruct this class (in the absense of a "real" url) the 
    // page whose dialogue localisations are sought
    public string dlgLocsPage {get; set;}
        
    // Global settings info 
    public static IASetIHOrg__c getSettings() {return ControllerSettings.getSettings();}
    
    // ... including (v1.41.32) wrappers to avoid issues with nulls if critical update disables permissions
    public static boolean getVotingAllowed() {return ControllerSettings.getSettings().TrackDaysVotes__c > 0;}

    public static String getBrandCSS() {if (ControllerSettings.getSettings() != null) {return ControllerSettings.getSettings().BrandCSS__c;} else {return '';}}
    public static String getD1() {return ControllerSettings.D1;}
    public static String getD2() {return ControllerSettings.D2;}
    

    // For UI localisations /multi language support (labels, messages etc.)
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

    // For providing quotation marks in JS code
    public static String getQ() {return '\'';}
        
    // URL information from request / query string:
    public string getPageName() {
        string[] DInfo = ControllerSettings.getDomainInfo(URL.getCurrentRequestUrl().toExternalForm());
        String CPrefix = DInfo[1];
        if (CPrefix != '') {CPrefix = '/' + CPrefix;}
        return URL.getCurrentRequestUrl().getPath().replace(CPrefix + '/apex/', '');
    }
    public static String getGoToURL() {if (ApexPages.currentPage().getParameters().get('GoTo') == null) {return '';} else {return ensureProtocol(ApexPages.currentPage().getParameters().get('GoTo'));}}  
    public static String getGoToRL() {if (ApexPages.currentPage().getParameters().get('GoToRL') == null) {return '';} else {return ensureProtocol(ApexPages.currentPage().getParameters().get('GoToRL'));}}  
    public static String getIHContext() {if (ApexPages.currentPage().getParameters().get('IHContext') == null) {return '';} else {return ensureProtocol(ApexPages.currentPage().getParameters().get('IHContext'));}}  

    // Help Topic and related SF objects
    public HelpTopic__c Hlp {get; set;}                     // The Help Topic related to this Helped Element
    public HelpedElement__c HE {get; set;}                  // The Helped Element represented on this page
    public HelpedElement__c[] allHEs {get; set;}            // All HE records for a particular Helped Element across data filter / visibility contexts
                
    // Basic topic details
    public String THelpId {get; set; }                      // SF Id of the Help Topic object
    public String TName { get; set; }                       // Help topic name

    private string TDesc;                                   // Help topic full text - with vulnerable tags parsed out
    public String getTDescription() {
        string strRet = TDesc;
        if (strRet == null) {strRet = '';}
        string repT = '(?i)<script';
        strRet = strRet.replaceAll(repT, '&lt;script');
        return strRet;
    }         

    public String TSummary { get; set; }                    // Users manually entered precis (Summary)
    public String TLayout {get; set; }                      // Generated URL to help topic when displayed in desired template
    public Decimal THeight { get; set; }                    // Height at which to show topic    
    public String ReviewDate {get; set;}                    // Date on which the content of the topic may require review
    public String CustomStyle {get; set;}                   // CSS class name to apply to this topic, if any
        
    // Image data
    public String TImage {get; set; }                       // Main image associated with Help Topic (Thumbnail)
    public String TImageURL {get; set; }                    // As above, but just the URL - not full image tag
    public String TImageTitle {get; set; }                  // Title to display with image (ImageTitle)
    public String TImageCaption {get; set; }                // Caption to display with image (ImageCaption)
    public Decimal TImageWidth {get; set; }                 // Width at which to display image
    public Decimal TImageHeight {get; set; }                // Height at which to display image
        
    // Video data
    private final String defaultVURL = '-';                 // A "safe" default video URL to send to templates (avoiding IE CSP issues with blanks)
    public String TVURL {get; set; }                        // URL of video associated with Topic (Video_URL)
    public Decimal TVWidth {get; set; }                     // Width of player (Video_Player_Width)
    public Decimal TVHeight {get; set; }                    // Height of player (Video_Player_Height)
    public String TVTitle {get; set;}                       // Title to display with video (VideoTitle)
    public String TVCaption {get; set;}                     // Caption to display with video (VideoCaption)
    
    // Preferred media data for preview/callout situations
    public String TPreviewMedia {get; set;}                 // URL (only) to image or video
    public String TPreviewMediaTitle {get; set;}            // Image or video title
    public String TPreviewMediaCaption {get; set;}          // Image or video caption
    public Decimal TPreviewMediaAR {get; set;}              // Aspect ratio of selected media (W / H)
    public Boolean THasMedia {get; set;}                    // True when any media caption, title or URL is set

    // Important generated links
    public String TRootLink {get; set;}                     // The base SF address
    public String TRetryLink {get; set;}                        // Referring page address
    public String TMoreLink { get; set; }                   // Link to more help info - delivered via tools page
    public String TMoreLinkHref { get; set; }               // Elements of the above
    public String TMoreLinkOnclick { get; set; }            // Elements of the above
    public String TMoreLinkTitle { get; set; }              // Elements of the above
    public String TMoreLinkText { get; set; }               // Elements of the above
    public String TAdminLink {get; set; }                   // DEFUNCT: Link to admin options for this help topic (e.g., edit it or its element)
    public String TEditModeLink {get; set;}                 // Link to toggle into IH in-line edit mode
    public String TInteractionsLink {get; set; }            // Generated link to page where help interactions can be managed
    public String TViewElementsLink {get; set;}             // Generated link to View Helped Elements dialogue
    public String TCommentLink {get; set; }                 // Generated link to page where a comment on this topic can be logged
    public String TBookmarkLink {get; set; }                // Generated link to page where a bookmark to this topic can be created
    public String TSFHelpLink {get; set; }                  // Link to sales force help     
    public String TSFEditingLinks {get; set;}               // Links to edit topic via standard SF page
    public String THelpHomeLink {get; set;}                 // Help topics home / search page link
    public String TMyBookmarksLink {get; set;}              // My Bookmarks listing page
    public String TCalloutPreviewLink {get; set;}           // Link to see topic as it would appear in its callout template
    public String TAddRelatedHelpLink {get; set;}           // Link allowing addition of related help topics
    public String TAddReadingListLink {get; set;}           // Link allowing addition of a reading list
    public String TAddToReadingListLink {get; set;}         // Link allowing addition of current topic to a RL
    public String TAddRelatedResourceLink {get; set;}       // Link allowing addition of a new Related resource
    public String TAddHelpTopicLink {get; set;}             // Link allowing addition of a new Help Topic
    public String TDeleteHelpTopicLink {get; set;}          // Link allowing deletion of the current Help Topic
    public String THistoryLink {get; set;}                  // Link to topic history reports
    public String THistoryReportId {get;set;}               // ID of this report (for manually constructed links)
    public String TStatsLink {get; set;}                    // Link to Stats report for the current topic
    public String TVoteSetsLink {get; set;}                 // Link to Vote Sets records
    
    // Link to list of Help Topic Templates
    public String getTemplatesLink() {

        String retVal;
        
        try {
            retVal = TRootLink;
            String[] SFOIDs = ControllerSettings.getSFObjectIds().split('\\^');        
            retVal += '/' + SFOIDs[3];
            
        } catch (exception e) {
            retVal = '#';
        }
        
        return retVal;
    }

    // Global config items inc Page branding
    public String TGlobalLinks {get; set;}                  // Globally defined links (those set in org settings)
    public String TBrandTitle {get; set;}                   // Globally defined topic page brand text
    public String TBrandSubTitle {get; set;}                // As above, for sub title
    public String TBrandImage {get; set;}                   // As above, for logo
    //public String TPrintWarning {get; set;}                 // Warning text re shelf life of printed topics

    // Related lists
    public ServiceIHLists.BookmarkListItem[] Bookmarks {get; set; }             // Current user's list of Help Bookmarks
    public ServiceIHLists.RelatedHelpListItem[] Relations {get; set; }          // Current topic's related topics
    public ServiceIHLists.RelatedResourcesListItem[] Resources {get; set;}      // Current topic's related resources
    public ServiceIHLists.ReadingList[] ReadingLists {get; set; }               // Current topic's reading lists
    public Integer ReadingListsImIn {get; set;}                                 // Count of RLs that feature the current topic
    public String ReadingListId {get; set;}                                     // Id of any featured reading list
        
    // Conditional formatting
    public String TBookmarkTool {get; set;}                                     // Add / remove bookmark link    
    public Boolean BmkExists {get; set;}                                        // True if current topic has been bookmarked
    public String TCSSClass {get; set; }                                        // CSS style to apply to topic area (passed in query string)
    public String LUXNubbinClass {get; set;}                                    // SLDS-ready Class name derived from above for nubbin positioning  
    public String TEditorClass {get; set;}                                      // Controls visibility of editor panel
    public String ContentType {get; set;}                                       // Can be set in some cases to send help content to (eg) Word
        
    // Other misc variables
    public ServiceInteractions svsI {get; set;}                     // Instance of a class that can log help interactions
    public ServiceSecurity Security;                                // Instance of a class for checking permissions etc
    public String UserText { get; set; }                            // For accepting input text (comments etc) from the user
    public String MessageClass { get; set; }                        // CSS class to apply to name / summary text (can indicate errors etc)
    public String Diags {get; set;}                                 // Diagnostics messages 
    public String Opts {get; set;}                                  // Controls visibility of optional features for some client pages
    public String Mode {get; set;}                                  // Mode for editing controls
    public String CloneTopicNames {get; set;}                       // Names for new topics created by cloning the current one
    public String CloneTopicRels {get; set;}                        // Y = clone relations when creating clones, N = clone topic only
    public List<Schema.FieldSetMember> CustomFields {get; set;}     // List of Topic custom fields local Org has included in a field set called "Custom"
        
    // 1.43+ : note this is now global, allowing for use via custom callouts etc.
    global String SelectedRecord {get; set;}                        // For times (eg visit resource) when we need to note record selected for an op
            
        
    // Vars to store user's security settings
    public Boolean isAnalysis {
        get {
            if (Security == null) {Security = new ServiceSecurity();}
            return Security.UserPermissions()[3];
        }
    }
    public Boolean isAuthor {
        get {
            if (Security == null) {Security = new ServiceSecurity();}
            return Security.UserPermissions()[1];
        }
    }
    public Boolean isAdministrator {
        get {
            if (Security == null) {Security = new ServiceSecurity();}
            return Security.UserPermissions()[2];
        }
    }
    public Boolean isSeated {get; set;}

    // Vars reflecting the type of UX we are using
    // cf ControllerSettings.getPortalPageName and ControllerIHQAMSettings.isIHLUX - as these have their own variant logic

    public Boolean isConsolePage {get; set;}             // True if viewing via an SF console component
    public Boolean isIH1UX {get; set;}                   // True if param passed to indicate viewing via the SF1 UX   
    public Boolean isIHLUX {get; set;}                   // True if param passed to indicate viewing via the Lightning UX
    public Boolean isLUXCaller {get; set;}               // True if param passed OR no apex current page exists - regardless of URL. 
                                                         // LUX component override (as opposed to VF portal) used for topic views if true
                                                             
    public String PortalPage {get; set;}                 // The VF page to use as the Tools/Portal page
    public Boolean CalloutMode {get; set;}               // Defines whether we're viewing as a popout VF QAM (designed to show "embedded" callouts)

    // Vote options available via the vote set associated with this topic, plus a vote being cast
    public HelpVoteOption__c[] VoteOptions {get; set;}
    public String theVote {get; set;}

    // Private control vars and constants
    private String LicenseIssue;
    private final String NameSpace = 'iahelp';
        

    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Private utility functions
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // General
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    
    // Validates a URL string, ensuring it begins with a valid protocol (http or https)
    private static string ensureProtocol(string U) {
        string retVal = U;      
        if (retVal == null) retVal = '';
        
        try {
            if (! (retVal.toUpperCase().startsWith('HTTP://') || retVal.toUpperCase().startsWith('HTTPS://'))) {
                
                // 1.37.2: Merely tacking on HTTP etc. prevents use of (legitimate) relative URLs!
                //retVal = 'https://' + retVal;
                retVal = Url.getOrgDomainURL().toExternalForm() + retVal;
            }
        } catch (exception e) {         
        }
        
        return retVal;
    }


   // Look for any Key words featured in the topic and turn these into links
    public string markKeywords (HelpTopic__c theHT, Boolean isLUXCaller) {
        
        string retVal = theHT.Description__c;

        // If topic has no description, just return
        if (retVal == null) {return '';}
        
        list<String> keywordList = new list<String>();                 // Keyword with space each side - to ensure search for whole word only
        String PortalPage;              // The Help Portal to use (IHTools or other - depending on UX options)
        String AnchorText;              // Actual keyword sought
        String AnchorTitle = '';        // Title to use with an anchor
        integer idx;                    // Position within text of "current" match of sought keyword
        string p1;                      // Working string / pre anchor text
        string p2;                      // Working string / after anchor text
        integer i;                      // For looping
        integer safetyLatch=0;            // Max number of parsing loops within a topic (to prevent infinte loop fails)
        integer idxOpenA;               // Position of an anchor open tag
        integer idxCloseA;              // Position of an anchor close tag
        boolean withinTag;              // True if, on basis of above, current match position is within an existing tag
        HelpTopic__c kwdHT;             //
        string KWPattern;               //
        pattern KWDs;                   //
        matcher matchedContent;         //              
        integer lastMatch = 0;          //
        string inVal = theHT.Description__c;
        string UCVal;  
        integer cnt = 0;
        map<string,list<String>> mapOfKeywordVsTopicId = new map<string,list<String>>();
        
        // Additional items needed when disambiguating multiple keyword matches
        if (mapGlbLocs == null) {
            mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false);
        }
        string AlertTitle = mapGlbLocs.get('TitleMoreInformation');
        string AlertMessage = mapGlbLocs.get('TitleSubtitleDisambiguation');
        string AlertImage = '/resource/iahelp__IHREsources/img/grabs/cogs.png';
        string DisambiguationLinkTip = mapGlbLocs.get('TipDisambiguationLink');
        
        try {
            ControllerHelpContent cs = new ControllerHelpContent();
            PortalPage = ControllerSettings.getPortalPageName(cs.isIH1UX);
            
            // Get an upper case version of the description to case-desensitize
            UCVal = theHT.Description__c.toUpperCase();  


            List<HelpTopic__c> lstHT = [SELECT Id, Summary__c, Keyword__c 
                                                FROM HelpTopic__c 
                                                WHERE Keyword__c != '' AND Keyword__c != null
                                                AND Id != :theHT.Id
                                                ORDER BY KeywordPhraseLength__c, Keyword__c 
                                                LIMIT 10000];
            
                                                
           for (integer j=0; j<lstHT.size(); j++) { 
               HelpTopic__c ht = lstHT[j];
               system.debug('ht '+ht);
               list<String> keywordLst = new list<String>();
               keywordLst = ht.iahelp__Keyword__c.split(',');
               for(string keyword : keywordLst){ 
                 system.debug('keyword '+keyword);
                 if(mapOfKeywordVsTopicId.containsKey(keyword)){
                    mapOfKeywordVsTopicId.get(keyword).add(ht.Id);
                 }
                 else{
                    mapOfKeywordVsTopicId.put(keyword,new list<String>());
                    mapOfKeywordVsTopicId.get(keyword).add(ht.Id);
                 }
                   system.debug('keyword '+mapOfKeywordVsTopicId.get(keyword));
               }
           }
       
            integer flag=0;                                                                             
            for (i=0; i<lstHT.size(); i++) {
                flag=0;
                kwdHT = lstHT[i];
                keywordList = kwdHT.Keyword__c.split(',');
                for(String keyword : keywordList){
                    system.debug(mapOfKeywordVsTopicId.get(keyword));
                
                String Anchor='';
                AnchorText = keyword;
                system.debug('AnchorText'+AnchorText);
                
                AnchorTitle = kwdHT.Summary__c.remove('\'');
                AnchorTitle = AnchorTitle.replaceAll('â€œ', '');
                AnchorTitle = AnchorTitle.replaceAll('â€', '');
                AnchorTitle=' '+AnchorTitle;
                system.debug('AnchorTitle'+AnchorTitle);

                String tempAnchorText = AnchorText.toLowerCase();
                tempAnchorText = tempAnchorText.trim();
                AnchorTitle = AnchorTitle.toLowerCase().replaceAll(tempAnchorText, '[' + tempAnchorText.toUpperCase() + ']');                
                system.debug('AnchorTitle'+AnchorTitle);
                String retVal1=retVal;
               
             
                //Introduced case-insensitive regex ((?i))
                String temp = '[^\\w<>](?i)' + AnchorText + '[^\\w]<>|(?i)' + AnchorText + '[^\\w<>]';
                Pattern pattern = Pattern.compile(temp);
                   
            
                system.debug('Checking for ' + keyword);
                system.debug(' pattern size() '+(pattern.split(retVal)).size());
                system.debug('AnchorTitle----------------------------- '+AnchorTitle);
                String[] arr=retVal.split(temp);
               
                if(arr.size() >1){                                                                  
                  
                    // Anchors need to take community root into account
                    string CRoot = ControllerSettings.getCommunityPrefix(); 
                    if (CRoot != '') {CRoot = '/' + CRoot;}
                       
                        if (isLUXCaller == false) {
                            if(mapOfKeywordVsTopicId.get(keyword).size()==1) {
                                Anchor = '<a class="IHKeyword" target="_blank" title="' + AnchorTitle + '" href="/apex/iahelp__' + PortalPage + '?HTID=' + kwdHT.Id + '">';
                            } else {
                                Anchor = '<a class="IHKeyword" title="' + 'This keyword is associated with multiple topics.' + '" href=""">';
                            }
                            
                        } else {
                                if(mapOfKeywordVsTopicId.get(keyword).size()==1){
                                    Anchor = ' <a class="IHKeyword" target="_blank" title="' + AnchorTitle + '" href="' + CRoot + '/' + kwdHT.Id + '">';
                                
                                } else {
                                    String baseURL = string.valueOf(System.URL.getOrgDomainURL());
                                    baseURL = baseURL.substringAfter('=');
                                    baseURL =baseURL.replaceAll(']', '');

                                    String componentDef = 'iahelp:IHList~SuppressHeader¬true|SuppressFooter¬true|MaxListingTools¬0|Height¬-1|CardConfig¬Disambiguation|sObjectName¬' + keyword + '|CalloutOption¬Topic Selected Event Only';   

                                    AnchorTitle = DisambiguationLinkTip;

                                    baseURL += '/lightning/cmp/iahelp__IHAlert?iahelp__title=' + AlertTitle  + ' ' + keyword;
                                    baseURL += '&iahelp__Message=' + AlertMessage  + ' ' + keyword;
                                    baseURL += '&iahelp__Image=' + AlertImage;
                                    baseURL += '&iahelp__componentDef=' + componentDef;
                                    baseURL += '&iahelp__ToolContext=DisambiguationList';
                                        
                                    system.debug('baseURL=='+baseURL);
                                    
                                    Anchor = '<a class="IHKeyword" target="_blank" title="' + AnchorTitle + '" href="'+baseURL+'">';
                                    system.debug('Anchor='+Anchor);
                                }
                        }
                        Anchor += keyword + '</a>';
                   
                                 
                    integer b=0,c=0;
                    string str='';
                        
                   while(b < (arr.size()-1)){
                        integer e = retVal.indexOfIgnoreCase(arr[b]);
                        c = retVal.indexOfIgnoreCase(keyword,e+arr[b].length());
                        integer t = retVal.indexOf('</a>',c);
                        integer u = retVal.indexOf('<a',c);
                        
                       if(t!=-1 && (u==-1 || (u!=-1 && u>t))) {
                           str+=arr[b]+keyword;
                           integer d=retVal.charAt(c+keyword.length());
                           str+=String.fromCharArray( new List<integer> {d});
                           ++b;
                           
                       } else {
                            System.debug( ' c '+c+'  '+retVal.length()+' '+keyword.length());
                            
                            //To prevent replacement of actual test with keywords
                            string getActualAnchorText = retVal.substring(c,c+keyword.length());
                            system.debug(' getActualAnchorText - '+getActualAnchorText);
                            Anchor = Anchor.replace(keyword,getActualAnchorText);
                            system.debug('Anchor---------------'+Anchor);
          
                            integer d = retVal.charAt(c-1);
                           
                            str+=arr[b] + Anchor; 
                            system.debug('string----------------'+str);
                            
                            Anchor = Anchor.replace(getActualAnchorText,keyword);
                            d = retVal.charAt(c+keyword.length());
                            str += String.fromCharArray( new List<integer> {d});

                            System.debug('arr[b] ' +arr[b]);
                            ++b; 
                       }
                    } 
                    str+=arr[b];
                    if (str!=null) {
                        retVal=str;
                    }
                       
                    safetyLatch += 1;
                                          
                } // IF
                System.debug(' retVal -'+retVal);  
              // Keyword / i loop 
            }
             
            }                   
        } catch (exception e) {
            
//ControllerHelpContent cs = new ControllerHelpContent();
//retVal = cs.mapGlbLocs.get('MessageGenericError') + ' - '  + e.getMessage() + ': Seeking keyword ' + i + ' (' + AnchorText + '): ' + retVal;

retVal = theHT.Description__c;
retVal += ' - ERROR (keyword parser) - '  + e.getMessage() + ': Seeking keyword ' + i + ' (' + AnchorText + '): ' + retVal;
            
        }
        
        System.debug(' retVal : '+retVal);
        return retVal;
    }    
 

    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Initialisation
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    // Function to populate our helped element member data. This is both the collection of
    // helped elements (allHEs) that match given Element and Layout identifiers (NOT Ids)
    // plus a specific (active) helped element: if ActiveElement is passed, this is the Id (NOT identifier)
    // of the HE record to make "current"       
    public Boolean getElementsViaEID(String EID, String HPL, String ActiveElement){
                
        try {                
            HelpedElement__c[] HEs;
                
            HEs = [SELECT Id, Name, HelpTopic__c, HelpedPageLayout__c, ElementType__c, Identifier__c, Visibility__c, DataDrivenFilter__c, UseForNew__c,
                                            HelpedPageLayout__r.PageLayoutIdentifier__c, HelpedPageLayout__r.Name,
                                            HelpTopic__r.Name 
                    FROM HelpedElement__c 
                    WHERE Identifier__c = :EID
                    AND HelpedPageLayout__r.PageLayoutIdentifier__c = :HPL];
                        
                        
            // This may return 1+ elements - as SOQL is case insensitive - so we need to check we find
            // exactly the one we're after...
            for (HelpedElement__c H : HEs) {
                if (H.HelpedPageLayout__r.PageLayoutIdentifier__c.equals(HPL) == true) {
                                        
                    if (ActiveElement == '') {
                        HE = H;
                    } else {
                        if (ActiveElement == H.Id) {
                            HE = H;                                                 
                        }
                    }
                    allHEs.add(H);                                  
                }
            }
                        
                        
            if (HE == null) {
                Diags += mapGlbLocs.get('MessageErrorNoMatchingRecord') + ' (Get Elements via EID) ';
                return false;
                    
            } else {
                return true;                            
            }
                        
        } catch (exception e) {
            Diags += mapGlbLocs.get('MessageGenericError') + ' - '  + e.getMessage() + ' - ';
            return false;
        }               
    }


    // Function to populate our member data on the basis of a lookup from a Reading List ID
    private Boolean getTopicViaRLID(String RLID, Boolean ExcludeInactiveTopics){
                
        try {
            // Look up the first available Reading List Entry applicable to the incoming RL identifier:
                
            HelpReadingListEntry__c RLE = [SELECT HelpTopic__c 
                            FROM HelpReadingListEntry__c 
                            WHERE HelpReadingList__c = :RLID
                            ORDER BY ReadingOrder__c
                            LIMIT 1];
                        
            // Use this to get help topic
            return getTopicViaHTID(RLE.HelpTopic__c, ExcludeInactiveTopics);
                                        
        } catch (exception e) {
            // Suitable entry not found
            Diags += mapGlbLocs.get('MessageGenericError') + ' (Get Topic via RLID) - '  + e.getMessage() + ' - ';
            return false;
        }
                        
    } 


    // Function to populate our member data on the basis of a lookup from a Helped Element ID
    private Boolean getTopicViaEID(String EID, Boolean ExcludeInactiveTopics){
                
        try {
            // Look up Helped Element applicable to the incoming page element identifier:
            // NB: we need to take the requesting page into account when doing this:
            // the same Identifier (a page element hook, NOT a HelpedElement__c.Id)
            // can crop up on more than one layout...
                                        
            String HPL = ServiceSecurity.getQueryParameter('HPL', 2);               

            // There may also be more than 1 element with this identifier logged for the layout
            // differentiated by visibility/data filter, so if we were passed a specific "current"
            // element id, use this...
            String ActiveHE = ServiceSecurity.getQueryParameter('ActiveId', 2);                     
                        
                        
            if (getElementsViaEID (EID, HPL, ActiveHE) == false) {                                
                Diags += mapGlbLocs.get('MessageGenericError') + ' (Get Topic via EID: ' + EID + '/' + HPL + ') - ';
                return false;
            }                       
                        
                        
            // Use element to get help topic
            return getTopicViaHTID(HE.HelpTopic__c, ExcludeInactiveTopics);
                                        
        } catch (exception e) {
            // No helped element matching ID passed by event
            Diags += mapGlbLocs.get('MessageGenericError') + ' (Get Topic via EID) - ' + e.getMessage() + '... ';
            return false;
        }                
    } 
    
    
    // Function to populate our member data on the basis of a lookup from a Help Topic ID
    public Boolean getTopicViaHTID(String HTID, Boolean ExcludeInactiveTopics){

        String strSOQLHlp = '';
        Boolean bAct1 = true;
        Boolean bAct2 = ExcludeInactiveTopics;


        try {
            // Get Help Topic specified by HTID:
            // Filter by Active flag for end users...             
            strSOQLHlp = getHelpTopicSelectSOQL();            
            
            strSOQLHlp += 'WHERE (Id = \''+ string.escapeSingleQuotes(HTID) + '\' ';
            strSOQLHlp += 'OR ' + NameSpace + '__MasterTopicIdentifier__c = \''+ string.escapeSingleQuotes(HTID) + '\') ';
            strSOQLHlp += 'AND (Active__c = ' + bAct1  + ' OR Active__c = ' + bAct2 + ') ';
            strSOQLHlp += 'LIMIT 1';
                        
            Hlp = database.query(strSOQLHlp);
                                
        } catch (exception e) {         
            // If we failed above, try a search of master topic identifer only,
            // as this may be plain text (so SOQL including it in record ID will fail)
            
            try {
                strSOQLHlp = getHelpTopicSelectSOQL();            

// Adjust HTID in case 'MTID:' marker is present
if (HTID.toUpperCase().startsWith('MTID:')) {HTID = HTID.substring(5);}
                
                strSOQLHlp += 'WHERE ' + NameSpace + '__MasterTopicIdentifier__c = \''+ string.escapeSingleQuotes(HTID) + '\' ';
                strSOQLHlp += 'AND (Active__c = ' + bAct1  + ' OR Active__c = ' + bAct2 + ') ';
                strSOQLHlp += 'LIMIT 1';
                            
                Hlp = database.query(strSOQLHlp);
                
            } catch (exception ex) {
                // No Help Topic matching ID passed by event:
                // Look for the "default" help topic specified in global settings - 
                // but only if this wasn't already the topic we were seeking            
                
                String defId = ControllerSettings.getSettings().DefaultHelpTopic__c;
                
                if (defId != HTID && defId != null && defId != '') {
                    return getTopicViaHTID(defId, ExcludeInactiveTopics);
                    
                } else {
                    return false;                   
                }
                
            }       
        }                
        return true;
        
    }
    
    
    // Provides the SOQL 'SELECT' clause required to obtain full details of a help topic including any custom fields
    public string getHelpTopicSelectSOQL() {
        
        String strSOQLHlp = '';
        
        try {
            List<Schema.FieldSetMember> CustomFlds;           
            Map<String, Schema.FieldSet> FsMap = Schema.SObjectType.HelpTopic__c.fieldSets.getMap();
            set<String> standardFields = new set<String>{};            
            
            CustomFields = null;
            
                        
            // In getting help, we want all the necessary "standard" fields that we ship in the product...
            standardFields.add('Id');
            standardFields.add('Name');
            standardFields.add(NameSpace + '__Description__c');
            standardFields.add(NameSpace + '__DescriptionText1__c');
            standardFields.add(NameSpace + '__DescriptionText2__c');
            standardFields.add(NameSpace + '__DescriptionText3__c');
            standardFields.add(NameSpace + '__DescriptionText4__c');
            standardFields.add(NameSpace + '__DescriptionText5__c');

            standardFields.add(NameSpace + '__Summary__c');
            standardFields.add(NameSpace + '__MasterTopicIdentifier__c');
            standardFields.add(NameSpace + '__Keyword__c');
            standardFields.add('CreatedBy.Name');
            standardFields.add('CreatedDate');
            standardFields.add('LastModifiedBy.Name');
            standardFields.add('LastModifiedDate');
                        
            standardFields.add(NameSpace + '__Thumbnail__c');
            standardFields.add(NameSpace + '__CalloutMediaChoice__c');
            standardFields.add(NameSpace + '__CustomStyle__c');
            standardFields.add(NameSpace + '__HelpVoteSet__c');
            standardFields.add(NameSpace + '__HelpVoteSet__r.' + NameSpace + '__QuestionText__c');
            standardFields.add(NameSpace + '__HelpVoteSet__r.' + NameSpace + '__ImageClass__c');
            standardFields.add(NameSpace + '__HelpVoteSet__r.' + NameSpace + '__ImagePreview__c');
            
            standardFields.add(NameSpace + '__ImageTitle__c');
            standardFields.add(NameSpace + '__ImageCaption__c');
            standardFields.add(NameSpace + '__ImageURL__c');
            standardFields.add(NameSpace + '__ImageALTText__c');
            standardFields.add(NameSpace + '__ImageWidth__c');
            standardFields.add(NameSpace + '__ImageHeight__c');
            
            standardFields.add(NameSpace + '__VideoURL__c');
            standardFields.add(NameSpace + '__VideoWidth__c');
            standardFields.add(NameSpace + '__VideoHeight__c');
            standardFields.add(NameSpace + '__VideoTitle__c');
            standardFields.add(NameSpace + '__VideoCaption__c');
            
            standardFields.add(NameSpace + '__CalloutTemplate__c');
            standardFields.add(NameSpace + '__CalloutTemplate__r.' + NameSpace + '__PageURL__c');
            standardFields.add(NameSpace + '__CalloutHeight__c');

            standardFields.add(NameSpace + '__Template__c'); 
            standardFields.add(NameSpace + '__Template__r.' + NameSpace + '__PageURL__c');
            standardFields.add(NameSpace + '__Template__r.Name');
            
            standardFields.add(NameSpace + '__HeightBeforeScrolling__c'); 

            standardFields.add(NameSpace + '__LightningTemplate__c'); 
            standardFields.add(NameSpace + '__LightningTemplate__r.' + NameSpace + '__PageURL__c');

            standardFields.add(NameSpace + '__SalesforceHelpURL__c');
            standardFields.add(NameSpace + '__Active__c');
            standardFields.add(NameSpace + '__ShowReadMoreLink__c');
            standardFields.add(NameSpace + '__ShowReferringRelationships__c');
            standardFields.add(NameSpace + '__HelpTopicStatus__c');
            standardFields.add(NameSpace + '__Visibility__c');

            standardFields.add(NameSpace + '__GuidedLayout__c');
            standardFields.add(NameSpace + '__GuidedRecord__c');
            standardFields.add(NameSpace + '__GuidedElement__c');
            standardFields.add(NameSpace + '__GuideStepMode__c');
            standardFields.add(NameSpace + '__GuideCallout__c');
            standardFields.add(NameSpace + '__GuidedLayout__r.' + NameSpace + '__PageLayoutIdentifier__c');             
                        
                        
            strSOQLHlp = 'SELECT ';
            for(String s : standardFields) {
                strSOQLHlp += s + ', ';
            }
                    
            // Also, we want to add any local, custom help fields via field sets
            for (String fsName : FsMap.keyset()) {
                
                // We only want fields in the field set we expect - which should be called "Custom"
                if (fsName == NameSpace +'__Custom' || fsName == 'Custom' || fsName.toUpperCase().endsWith('__CUSTOM')) {
                        
                    // Loop through each field that has been added to this field set
                    CustomFlds = SObjectType.HelpTopic__c.FieldSets.getMap().get(fsName).getFields();
                    for (Schema.FieldSetMember f : CustomFlds) {
                                                
                        // We only want fields added to this that are not standard fields already featured on other tabs
                        if (standardFields.contains(f.getFieldPath()) == false) {
                            strSOQLHlp += f.getFieldPath() + ', ';
                            if (CustomFields == null) {CustomFields = new List<Schema.FieldSetMember> {};}
                            CustomFields.add(f);
                        }
                    }
                                
                    break;                          
                }
            }                                   
            strSOQLHlp = strSOQLHlp.substring(0, strSOQLHlp.length() - 2);
                        
            strSOQLHlp += ' FROM HelpTopic__c ';
                        
                                
        } catch (exception e) { 
            strSOQLHlp = '';
        }                
        return strSOQLHlp;
        
    }
    

    // Sets default values for the controller's member data
    private Boolean initialiseTopic() {
           
        String IH1PageName;
        String RootUrl;
        integer isError = 0;
        String temp;
        boolean ApexPageExists = ServiceSecurity.ApexPageExists();
                
        try {
                        
            // Get localisation information (field labels etc):
            initialiseLocalisations();
            
            // Check here that we got maps of localisations: if we haven't for any reason, best to trap the error 
            // here, as pages attempting to use them fall over un-gracefully otherwise!
            
            if (mapDlgLocs == null) {
                // No localisations = error
                isError = 1;
            } else if (mapDlgLocs.get('Error') != null) {
                // Specifically inserted error = error
                isError = 2;
            } else if (mapDlgLocs.size() == 0) {
                // No items = error (if there are none for the current page, initialisation should
                // have spotted this and inserted a single, informational localisation)
                isError = 3;
            }


            if (isError != 0) {
                Diags = 'Localisation error: dialogue sought was ' + dlgLocsPage + ': ';
                if (mapDlgLocs == null) {
                    Diags += 'This returned NULL';
                } else {
                    Diags += 'Num. Localiations returned: ' + mapDlgLocs.size();
                }           
                Diags += ' - ' + mapDlgLocs.get('Error');
                Diags += ' - (' + isError + ')';
                TRetryLink = ApexPages.currentPage().getHeaders().get('Referer');
                return false;
            }               


            // We should check we get a settings object here: if not, we have a problem and should stop
            if (ControllerSettings.getSettings() == null) {
                return false;
            }
                                            
            // Get the name of the IH1UX portal page name for certain tests
            IH1PageName = ControllerSettings.getPortalPageName(true);
                
            // Note any incoming Diags messages             
            Diags = ServiceSecurity.getQueryParameter('Diags', 0);
   
            // Extract Mode from request
            Mode = ServiceSecurity.getQueryParameter('Mode', 2);
   
            // Derive content type from incoming parameters
            if (ServiceSecurity.getQueryParameter('ContentType', 2) == '1') {
                ContentType = 'application/msword';
            } else {
                ContentType = '';
            }
                
            // Note whether we're in console mode
            isConsolePage = ControllerSettings.isConsolePage();  
            
            // Note which UX variant we're using:
            // NOTE: skip for lightning (where there is no current page)
            if (ApexPageExists) {
                
                // Salesforce1 UX - can be per direct "orders" in URL or by looking at page name:
                // We also need to check for certain SF-type URLs (as we're overriding these)
                if (ApexPages.currentPage().getParameters().get('IH1UX') == 'true' || ApexPages.currentPage().getUrl().indexOf('/apex/' + NameSpace + '__' + IH1PageName) != -1) {
                    isIH1UX = true;
                } else {
                    isIH1UX = false;
                }                               
                
                // Lightning UX: - can be per direct "orders" in URL or via global setting:
                // If a direct instruction to switch LUX OFF is given, this should be respected / take precidence
                if ((ApexPages.currentPage().getParameters().get('IHLUX') == 'true' || ControllerSettings.getSettings().BrandUXOption__c == '3') 
                            && ApexPages.currentPage().getParameters().get('IHLUX') != 'false' ) {
                    isIHLUX = true;
                } else {
                    isIHLUX = false;
                }        
                
                // Lightning topic portal override: use LUX component instead regardless of callout branding if true
                if (ApexPages.currentPage().getParameters().get('LUXCaller') == 'true') {
                    isLUXCaller = true;
                } else {
                    isLUXCaller = false;
                }                  

                if (ApexPages.currentPage().getParameters().get('save_new') != null){
                    // This is a sign of adding
                    Mode = 'NEW';
                                                        
                } else if (ApexPages.currentPage().getParameters().get('retURL') != null) {
                    // This is a sign of editing
                    Mode = 'EDIT';
                }

            } else {
                isIH1UX = false;                
                isIHLUX = false;
                
                // If there's no current page object, assume we have a non-classic caller (i.e., LUX):
                // We consider this, below, separately from branding (URL-specified) options
                isLUXCaller = true;
            }

            PortalPage = ControllerSettings.getPortalPageName(isIH1UX);
            
            
            // Note whether we're being called via a popped out QAM (in Callout Mode)
            // NOTE: skip for lightning (where there is no current page)
            if (ApexPageExists) {
                temp = ApexPages.currentPage().getParameters().get('CalloutMode');
                if (temp == null) {
                    CalloutMode = false;
                } else {
                    if (temp.toUpperCase() == 'TRUE') {
                        CalloutMode = true;
                    } else {
                        CalloutMode = false;
                    }
                }
            } else {
                CalloutMode = false;                
            }   
                                     
                
            // Editor is hidden unless we're told otherwise
            TEditorClass = 'IHHidden';
                
                
            // Set topic basics
            TName = '';
            TDesc = '';
            TSummary = ''; 
            TLayout = '';
            THeight = 50;
            TInteractionsLink = '';
            TViewElementsLink = '';
            TCommentLink = '#';
            TBookmarkLink = '#';
            TMoreLink = '';
            TAdminLink = '';
            TEditModeLink = '';
            TImage = '';
            TImageURL = '';
            TImageTitle = '';
            TImageCaption = '';
            TImageWidth = 0;
            TImageHeight = 0;
            TVURL = '';
            TVWidth = 0;
            TVHeight = 0;
            ReviewDate = datetime.now().format();
            TVTitle = '';
            TVCaption = '';
            TCSSClass = '';
            TPreviewMedia = '';
            TPreviewMediaTitle = '';
            TPreviewMediaCaption = '';
            TPreviewMediaAR = 1;
            THasMedia = false;
            TSFHelpLink = '';
            TSFEditingLinks = '';
            TCalloutPreviewLink = '#';
            TAddRelatedHelpLink = '';
            TAddRelatedResourceLink = '';
            TAddHelpTopicLink = '';
            TDeleteHelpTopicLink = '';
            TAddToReadingListLink = '';
            THistoryLink = '';
            MessageClass = '';
            ReadingListsImIn = 0;
                
                
            // Initialise our collections
            Relations = new ServiceIHLists.RelatedHelpListItem[]{};
            ReadingLists = new ServiceIHLists.ReadingList[]{};
            Resources = new ServiceIHLists.RelatedResourcesListItem[]{};
            allHEs = new HelpedElement__c[]{};


            // Set globally used objects    
            svsI = new ServiceInteractions();
            Security = new ServiceSecurity();
                        
                        
            // NOTE: skip for lightning (where there is no current page)
            if (ApexPageExists) {
                // Set up search options
                ControllerSearch.SearchOptions Options = new ControllerSearch.SearchOptions();  
                UserText = Options.Term;
                    
                // Use community path, if relevant              
                RootUrl = ControllerSettings.getCommunityRoot();
                
            } else {
                UserText = '';
                RootUrl = '';
            }
                        
            
            if (RootUrl == '') {
                RootUrl = URL.getOrgDomainURL().toExternalForm();
            }
            TRootLink = RootUrl;
            THelpHomeLink = RootUrl + '/apex/iahelp__IHSearchResults';
            TMyBookmarksLink = RootUrl + '/apex/iahelp__IHManageBookmarks';
            
            try {
                TVoteSetsLink = RootUrl;
                String[] SFOIDs = ControllerSettings.getSFObjectIds().split('\\^');        
                TVoteSetsLink += '/' + SFOIDs[5];
                
            } catch (exception e) {
                TVoteSetsLink = '#';
            }
                                    

            // Get rights here so we can set options below...   
            Boolean[] UPs = Security.UserPermissions();
            Boolean bUser = UPs[0];
            Boolean bAuthor = UPs[1];
            Boolean bAdministrator = UPs[2];
            Boolean bAnalysis = UPs[3];
            
            // Treat lack of any permissions as a problem (as we must check FLS).
            // So: no Help Permission Set assisnments at all = same effect as no subscription...            
            if (! (bUser || bAnalysis || bAuthor || bAdministrator)) {
                isSeated = false;
                Diags = mapGlbLocs.get('MessageNoPermissions');
                return false;
                
            } else {
                isSeated = Security.isSeated();
            } 
                        
                        
            // Similarly, setup global links:
            // NB: to be shown, each need URL and link text to be set...
            TGlobalLinks = '<ul id="IHQuickLinks">';
            if (ControllerSettings.getSettings().QuickLink1__c != null && ControllerSettings.getSettings().QuickText1__c != null) {
                if (ControllerSettings.getSettings().QuickTip1__c != null) {
                    TGlobalLinks += '<li/><a target="Qlink" title="' + ControllerSettings.getSettings().QuickTip1__c + '" href="' + ControllerSettings.getSettings().QuickLink1__c + '">' + ControllerSettings.getSettings().QuickText1__c + '</a>';                   
                } else {
                    TGlobalLinks += '<li/><a target="Qlink" title="' + mapGlbLocs.get('TipGoto') + ' ' + ControllerSettings.getSettings().QuickText1__c + '" href="' + ControllerSettings.getSettings().QuickLink1__c + '">' + ControllerSettings.getSettings().QuickText1__c + '</a>';                   
                }
            }

            if (ControllerSettings.getSettings().QuickLink2__c != null && ControllerSettings.getSettings().QuickText2__c != null) {
                if (ControllerSettings.getSettings().QuickTip2__c != null) {
                    TGlobalLinks += '<li/><a target="Qlink" title="' + ControllerSettings.getSettings().QuickTip2__c + '" href="' + ControllerSettings.getSettings().QuickLink2__c + '">' + ControllerSettings.getSettings().QuickText2__c + '</a>';
                } else {
                    TGlobalLinks += '<li/><a target="Qlink" title="' + mapGlbLocs.get('TipGoto') + ' ' + ControllerSettings.getSettings().QuickText2__c + '" href="' + ControllerSettings.getSettings().QuickLink2__c + '">' + ControllerSettings.getSettings().QuickText2__c + '</a>';                   
                }
            }
                
            if (ControllerSettings.getSettings().QuickLink3__c != null && ControllerSettings.getSettings().QuickText3__c != null) {
                if (ControllerSettings.getSettings().QuickTip3__c != null) {
                    TGlobalLinks += '<li/><a target="Qlink" title="' + ControllerSettings.getSettings().QuickTip3__c + '" href="' + ControllerSettings.getSettings().QuickLink3__c + '">' + ControllerSettings.getSettings().QuickText3__c + '</a>';
                } else {
                    TGlobalLinks += '<li/><a target="Qlink" title="' + mapGlbLocs.get('TipGoto') + ' ' + ControllerSettings.getSettings().QuickText3__c + '" href="' + ControllerSettings.getSettings().QuickLink3__c + '">' + ControllerSettings.getSettings().QuickText3__c + '</a>';                   
                }
            }
            
            if (ControllerSettings.getSettings().QuickLink4__c != null && ControllerSettings.getSettings().QuickText4__c != null) {
                if (ControllerSettings.getSettings().QuickTip4__c != null) {
                    TGlobalLinks += '<li/><a target="Qlink" title="' + ControllerSettings.getSettings().QuickTip4__c + '" href="' + ControllerSettings.getSettings().QuickLink4__c + '">' + ControllerSettings.getSettings().QuickText4__c + '</a>';
                } else {
                    TGlobalLinks += '<li/><a target="Qlink" title="' + mapGlbLocs.get('TipGoto') + ' ' + ControllerSettings.getSettings().QuickText4__c + '" href="' + ControllerSettings.getSettings().QuickLink4__c + '">' + ControllerSettings.getSettings().QuickText4__c + '</a>';                   
                }
            }

            if (ControllerSettings.getSettings().QuickLink5__c != null && ControllerSettings.getSettings().QuickText5__c != null) {
                if (ControllerSettings.getSettings().QuickTip5__c != null) {
                    TGlobalLinks += '<li/><a target="Qlink" title="' + ControllerSettings.getSettings().QuickTip5__c + '" href="' + ControllerSettings.getSettings().QuickLink5__c + '">' + ControllerSettings.getSettings().QuickText5__c + '</a>';
                } else {
                    TGlobalLinks += '<li/><a target="Qlink" title="' + mapGlbLocs.get('TipGoto') + ' ' + ControllerSettings.getSettings().QuickText5__c + '" href="' + ControllerSettings.getSettings().QuickLink5__c + '">' + ControllerSettings.getSettings().QuickText5__c + '</a>';                   
                }
            }
        
            // Global links editing available to admins only
            if (bAdministrator) {
                TGlobalLinks  += '<li/><a target="Qlink" title="' + mapGlbLocs.get('TipButtonConfigureSettings') + '" href="' + RootUrl + '/apex/iahelp__IHManageSettings?Cat=QuickLinks"><div class="IHIcon IHIconSettings"></div></a>';
            }
                
            // Always close the global links unordered list
            TGlobalLinks += '</ul>';
                

            // Setup help page branding elements and other elements from global settings
            if (ControllerSettings.getSettings().BrandTitle__c != null) {
                TBrandTitle  = ControllerSettings.getSettings().BrandTitle__c;                  
            }
            if (ControllerSettings.getSettings().BrandSubTitle__c != null) {
                TBrandSubTitle  = ControllerSettings.getSettings().BrandSubTitle__c;                    
            }
            if (ControllerSettings.getSettings().BrandImage__c != null) {
                TBrandImage  = ControllerSettings.getSettings().BrandImage__c;                  
            }
            
/*
            if (ControllerSettings.getSettings().UserAdvicePrintShelfLife__c != null) {
                TPrintWarning  = ControllerSettings.getSettings().UserAdvicePrintShelfLife__c;                  
            }
*/
                
            // Certain editing links available to admins or authors only
            if (bAuthor || bAdministrator) {
                TEditModeLink = '<a title="' + mapGlbLocs.get('TipButtonEditTopic') + '" href="javascript:IHEditHelp.ToggleEditMode();"><div class="IHIcon IHIconEdit"></div></a>';
                
                // NB: this link can be set here to allow add RL - but NOT including add & link option
                // (which requires the HTID parameter). HTID is added elsewhere once topic is known
                ServiceIHLists.ReadingList RL = new ServiceIHLists.ReadingList();
                String Q = '\'';
                TAddReadingListLink = '<a href="#" title="' + mapGlbLocs.get('TipButtonCreateRL') + '" onclick="javascript:IHWebToolTips.DoTips(' + Q + 'dfrm' + Q + ', ' + Q + RL.NewLink + Q + ', ' + Q + '7' + Q + ', 200, 585, event);">';
                TAddReadingListLink += '<div class="IHIcon IHIconAdd"></div></a>';
                
            } else {
                TEditModeLink = '';
                TAddReadingListLink = '';
            }
                                                
            MessageClass = '';
                
        } catch (exception e) {
            return false;
        }    
                                

        return true;
    } 


    // Get the current users (potentially updated) set of bookmarks
    public Boolean initialiseBookmarks (Boolean showName, Boolean showSummary) {

        try {
            BmkExists = false;
    
            Bookmarks = null;
            Bookmarks = new ServiceIHLists.BookmarkListItem[]{};
            String UID = UserInfo.getUserId();

            // Make schema calls if the caller hasn't done so to check FLS
            if (showName == null) {
                showName = Schema.sObjectType.HelpTopic__c.fields.Name.isAccessible();
            }
            
            if (showSummary == null) {
                showSummary = Schema.sObjectType.HelpTopic__c.fields.Summary__c.isAccessible();
            }
                    
                    
            for (HelpBookmark__c Bmk : 
                [SELECT Id, HelpTopic__c, TopicURL__c, HelpBookmarkLabel__c,
                HelpTopic__r.Name, HelpTopic__r.Summary__c
                FROM HelpBookmark__c 
                WHERE OwnerId = :UID
                ORDER BY HelpTopic__r.Name])
                {
                    Bookmarks.add(New ServiceIHLists.BookmarkListItem(Bmk, showName, showSummary));
            }

                    
            // Existence or otherwise of help topic in bookmark list affects ability
            // to add and remove bookmarks for this page - thus also the relevant icons...
            for (ServiceIHLists.BookmarkListItem Bmk : Bookmarks) {
                if (Bmk.HTID == THelpId) {                                              
                    //This page has been bookmarked: note this and bail
                    BmkExists = true;
                    break;
                }
            }


            if (mapGlbLocs != null) {
                if (BmkExists == true) {                                    
                    // Remove bookmark tool required
                    TBookmarkTool = '<a href="#" onclick="javascript:removeBmk();"><div title="' + mapGlbLocs.get('TipButtonRemoveBookmark') + '" class="IHIcon IHIconBookmarkRemove"></div></a>';
                    
                } else {
                    // Add bookmark tool required
                    TBookmarkTool = '<a href="#" onclick="javascript:addBmk();"><div title="' + mapGlbLocs.get('AdviceLabelAddBookmark') + '" class="IHIcon IHIconBookmarkAdd"></div></a>';
                }               
            }                                                

                
        } catch (exception e) {
            return false;
        }

        return true;
    }



    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Public Initialisation and constructors
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    // Constructor used when SF calls pages using this class as a controller EXTENSION
    public ControllerHelpContent (ApexPages.StandardController stdController) {
            
        Diags = 'Page instantiated via standard controller... ';
        
        THelpId = ServiceSecurity.getQueryParameter('id', 2);           
        if (THelpId == '') {THelpId = ServiceSecurity.getQueryParameter('HTID', 2);}
        
        Diags += 'THelpId set to ' + THelpId + '... ';          
    }


    // Constructor for certain LUX ops
    public ControllerHelpContent (boolean doInitialise) {
        if (doInitialise) {
            initialiseTopic();
        }
    }


    // Constructor used when VF pages use this class as a CONTROLLER
    global ControllerHelpContent () {
        THelpId = null;
    }
    
    

    // Wrapped initialisation routine for Bookmarks pages
    public void initialiseForBookmarks () {
        
        try {
            if (initialiseTopic() == false ) {
                return;
            }
                
            if (initialiseBookmarks(null, null) == false) {
                return;
            }
                
        } catch (exception e) {
            return;
        }

        return;
    }


    // Minimal initialisation for access to internationalised labels etc
    public void initialiseLocalisations() {
        // Get localisation information (field labels etc):
        // We need a mix of "global", "branding" and cross screen labels and those which are screen specific.
        // The latter depends on the page being served...
        
        try {
            ControllerSettings cS = new ControllerSettings();
            set<string> DlgLocPages = new set<string>();
            string theDlg = cS.SFObjId(Url.getCurrentRequestUrl().toExternalForm());
            string theDlgTest = theDlg;
                
            mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false); 
            mapBrdLocs = ServiceLocalisation.getDialogueLocalisations('Branding', false);
            
            // Only bother to seek dialogue localisations if we're on a page that uses them:
            // This is important because otherwise we will not know whether lack of localisations 
            // returned means there was a problem or it's just a page for which none exist
            
            DlgLocPages.add('CalloutReadingLists');
            DlgLocPages.add('IH1QAM');
            DlgLocPages.add('IH1Tools');
            DlgLocPages.add('IHComment');
            DlgLocPages.add('IHConfirmActions');
            DlgLocPages.add('IHEditingToolsTopic');
            DlgLocPages.add('IHHelpedElement');
            DlgLocPages.add('IHManageReadingList');
            DlgLocPages.add('IHManageSettings');
            DlgLocPages.add('IHPreviewCallout');
            DlgLocPages.add('IHReadingListProperties');
            DlgLocPages.add('IHReadingListViewer');
            DlgLocPages.add('IHSearchResults');
            DlgLocPages.add('IHStats');
            DlgLocPages.add('IHTools');
            DlgLocPages.add('TemplatePrintable');
            
            string[] DInfo = ControllerSettings.getDomainInfo(URL.getCurrentRequestUrl().toExternalForm());
            if (DInfo[1] != '') {theDlgTest = theDlgTest.replace(DInfo[1] + '/', '');}
                        
            if (Test.isRunningTest()) {
                // Page address will not be "real" if we're in test mode, so hard wire dialogue name in these cases
                if (dlgLocsPage == '' || dlgLocsPage == null) {
                    mapDlgLocs = ServiceLocalisation.getDialogueLocalisations('iahelp__IHTools', false);
                } else {
                    mapDlgLocs = ServiceLocalisation.getDialogueLocalisations(dlgLocsPage, true);
                }
            } else {
                if (DlgLocPages.contains(theDlgTest) == false && DlgLocPages.contains(theDlgTest.replace('iahelp__', '')) == false ) {
                    mapDlgLocs = new map<string,string>();
                    mapDlgLocs.put('Info', 'Current page (' + theDlgTest + ') has no dialogue localisations - none being sought...');
                    
                } else {
                    dlgLocsPage = theDlg;
                    mapDlgLocs = ServiceLocalisation.getDialogueLocalisations(dlgLocsPage, true);
                }
            }
                        
            Diags = '';
            
        } catch (exception e) {

        }
        
        return;     
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Globally available / wrapper interfaces (for custom local templates): 
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    
    // cf gotoResource - which is global in support of custom templates from v1.43+
    // Ditto SelectedRecord
    
    // Class to represent the aspects of the selected help topic we want to make available
    global class HTInfo {
        
        // Topic fields         
        public String Id {get; set;}
        public String Name {get; set;}
        public String Summary {get; set;}
        public String Description {get; set;}
        public String SalesforceHelpURL {get; set;}
        public String CustomStyle {get; set;}
        public Decimal CalloutHeight {get; set;}

        // Derivative values
        public String ReviewDate {get; set;}
        public String Image {get; set;}
        public String Video {get; set;}
                
        // Additional items from member data
        //public String MoreLink {get; set;}
        //public String CommentLink {get; set;}
        //public String BookmarkLink {get; set;}
        //public String StatsLink {get; set;}

        // Related items lists
        public ServiceIHLists.RelatedHelpListItem[] Relations {get; set;}           // Current topic's related topics
        public ServiceIHLists.RelatedResourcesListItem[] Resources {get; set;}      // Current topic's related resources
        public ServiceIHLists.ReadingList[] ReadingLists {get; set;}                // Current topic's reading lists
                    
        public HTInfo(){}
    }
    
    // Likewise, a class to expose elements of the Helped Element
    global class HEInfo {       
        public String Name {get; set;}
        public String Identifier {get; set;}
        public String ElementType {get; set;}
        public HEInfo(){}
    }
    
    // Likewise, a class to expose elements of the record being viewed
    global class RecordInfo {
        public String Id {get; set;}
        public RecordInfo(){}
    }
    
    // Likewise, settings information
    global class IHSettingsInfo {
        public String BrandCSS {get; set;}
        public IHSettingsInfo(){}
    }
    
    // Instances of our wrapper classes to expose to templates
    private HTInfo theHTInfo;
    global HTInfo getTopic() {return theHTInfo;}
    private HEInfo theHEInfo;
    global HEInfo getElement() {return theHEInfo;}
    private RecordInfo theRecord;
    global RecordInfo getRecord() {return theRecord;}
    private IHSettingsInfo theSettings;
    global IHSettingsInfo getHelpSettings() {return theSettings;}
    
    
    // The action to be called by customer topic templates to obtain topic/element/record info
    global void getImprovedHelp() {
                
        system.Url U;
                                
        try {
            // Do the usuals to get help
            getHelp();
            
            // Populate a topic object for use by clients
            theHTInfo = new HTInfo();
            theHTInfo.Id = Hlp.Id;
            theHTInfo.Name = Hlp.Name;
            theHTInfo.Summary = Hlp.Summary__c;
            theHTInfo.Description = Hlp.Description__c;
            theHTInfo.SalesforceHelpURL = Hlp.SalesforceHelpURL__c;
            theHTInfo.CustomStyle = Hlp.CustomStyle__c;
            theHTInfo.CalloutHeight = Hlp.CalloutHeight__c;    
            theHTInfo.ReviewDate = this.ReviewDate;  
            
            // Ditto related lists         
            theHTInfo.Relations = this.Relations;            
            theHTInfo.Resources = this.Resources;
            theHTInfo.ReadingLists = this.ReadingLists;
                    
            // Read more cannot be made available in console as this would require dependencies
            // that custom template author could not easily supply
            /*
            if (isConsolePage == false) {
                theHTInfo.MoreLink = this.TMoreLink;                    
            } else {
                theHTInfo.MoreLink = '';
            }
            
            theHTInfo.CommentLink = this.TCommentLink;
            theHTInfo.BookmarkLink = this.TBookmarkLink;
                    
            // Stats link is rights-dependent
            if (isAnalysis) {
                theHTInfo.StatsLink = this.TStatsLink;
            } else {
                theHTInfo.StatsLink = '';
            }
            */
                        
            theHTInfo.Image = this.TImage;
                
            if (this.TVURL == '' || this.TVURL == null || this.TVURL == 'null'|| this.TVURL == defaultVURL) {
                theHTInfo.Video = '';
            } else {
                theHTInfo.Video = '<iframe frameborder="0" style="width: ' + this.TVWidth + 'px; height: ' + this.TVHeight + 'px;" src="' + this.TVURL + '"></iframe>';
            }
                                        
            // Populate an element object if we have one
            theHEInfo = new HEInfo();
                        
            if (HE != null) {
                theHEInfo.Name = HE.Name;
                theHEInfo.Identifier = HE.Identifier__c;
                theHEInfo.ElementType = HE.ElementType__c;
            } else {
                theHEInfo.Name = '';
                theHEInfo.Identifier = '';              
                theHEInfo.ElementType = '';     
            }
                        
                        
            // Populate record info, if we have a record
            theRecord = new RecordInfo();
                                        
            theRecord.Id = ServiceSecurity.getQueryParameter('IHContext', 0);
            if (theRecord.Id != '') {
                try {
                    U = new System.Url(theRecord.Id);
                    theRecord.Id = U.getPath().substring(1, 16);                    
                } catch (exception e) {
                    theRecord.Id = '';                              
                }
            }
                        
                        
            // Populate settings
            theSettings = new IHSettingsInfo();
            theSettings.BrandCSS = getBrandCSS();
                        
        } catch (exception e) {
            theHTInfo = new HTInfo();
            theHTInfo.Name = mapGlbLocs.get('MessageGenericErrorShort');
            theHTInfo.Summary = mapGlbLocs.get('MessageGenericError');
            theHTInfo.Description = '';
            theHTInfo.SalesforceHelpURL = '';
            theHTInfo.CustomStyle = '';
            theHTInfo.CalloutHeight = 0;
            theHTInfo.Image = '';
            theHTInfo.Video = '';
            //theHTInfo.MoreLink = '';
            //theHTInfo.CommentLink = '';
            //theHTInfo.BookmarkLink = '';
            //theHTInfo.StatsLink = '';

            theHTInfo.Relations = new ServiceIHLists.RelatedHelpListItem[]{};            
            theHTInfo.Resources = new ServiceIHLists.RelatedResourcesListItem[]{};
            theHTInfo.ReadingLists = new ServiceIHLists.ReadingList[]{};

            theHEInfo = new HEInfo();
            theHEInfo.Name = '';
            theHEInfo.Identifier = '';              
            theHEInfo.ElementType = '';                             

            theRecord = new RecordInfo();
            theRecord.Id = '';
            
            theSettings = new IHSettingsInfo();
            theSettings.BrandCSS = '';                      
        }
        return;
    }

    
    // FLS checking diagnostics 
    global pageReference FLSCheck() {
        
        ServiceSecurity sS = new ServiceSecurity();
        Boolean[] Ps = sS.UserPermissions();    
        Boolean B = sS.meetsFLSRequirements(ServiceSecurity.KnownSecureOperations.AdministerHelp);
        
        String s = 'Helped User: ' + Ps[0] + ' - Help Analyst: ' + Ps[3] + ' - Help Author: ' + Ps[1] + ' - Help Administrator: ' + Ps[2];      
        Diags = s + ' >>>>>>>>>>>>> ' + sS.Diags; 
        
        return null;
    }



    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Entry points: 
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    // Function to furnish a client page with a helped element from identifier & layout supplied in query
    public PageReference getHelpedElement() {
                
        try {
            // Use community path, if relevant, in any URLs returned below...
            String RootUrl = ControllerSettings.getCommunityRoot();
            if (RootUrl == '') {
                RootUrl = URL.getOrgDomainURL().toExternalForm();
            }
                        
            // This routine should initialise member data, but if it fails it suggests there's
            // a problem with help settings, so we must fail gracefully...
            if (initialiseTopic() == false) {
                return new PageReference(RootUrl + '/apex/iahelp__IHServiceUnavailable');                   
            }


            // Get localisation information (field labels etc)
            ControllerSettings cS = new ControllerSettings();
            if (Test.isRunningTest()) {
                // Page address will not be "real" if we're in test mode, so hard wire dialogue name in these cases
                mapDlgLocs = ServiceLocalisation.getDialogueLocalisations('iahelp__IHTools', false);
            } else {
                mapDlgLocs = ServiceLocalisation.getDialogueLocalisations(cS.SFObjId(Url.getCurrentRequestUrl().toExternalForm()), true);
            }

                        
            // Extract element and page layout identifiers from request
            String EID = ServiceSecurity.getQueryParameter('ElemId', 1);
            String HPL = ServiceSecurity.getQueryParameter('HPL', 2);
            String ActiveHE = ServiceSecurity.getQueryParameter('ActiveId', 2);

            // Use these to get helped page layout
            if (getElementsViaEID (EID, HPL, ActiveHE) == false) {
                                
                // If this fails, assume it's because there are no matching elements - perhaps
                // because these have been deleted in re-configure mode. In these cases, re-direct
                // to an advice message screen     
                
                // NB: Only Helped Elements Maintenance screen uses this call, so translation is logged 
                // against that dialogue, not globally (IHHelpedElement)                     
                String Msg = mapDlgLocs.get('MessageNoElementsToReconfigure');
                Msg = EncodingUtil.urlEncode(Msg, 'UTF-8');
                return new PageReference(RootUrl + '/apex/iahelp__IHMessage?Diags=' + Msg);                         

            } else {
                //Diags = '';                           
            }                       
                        
        } catch (exception e) {
            Diags += mapGlbLocs.get('MessageGenericError') + ' - ' + e.getMessage() + '... ';                        
        }
                
        return null;
    }


    // VF pages acting as Help Topic Templates should call this as their ACTION
    public PageReference getHelp() {
       
        // Use community path, if relevant, in any URLs returned below...
        String RootUrl = ControllerSettings.getCommunityRoot();
        if (RootUrl == '') {
            RootUrl = URL.getOrgDomainURL().toExternalForm();
        }
        

        // Setup our member data
        if (initialiseTopic() == false) {
            // Return diagnostics if we've been given any
            if (Diags != '') {
                return new PageReference(RootUrl + '/apex/iahelp__IHMessage?Diags=' + Diags);                   
            } else {
                return new PageReference(RootUrl + '/apex/iahelp__IHServiceUnavailable');                                   
            }
        }
        
        
        // Establish user permissions
        Boolean[] UPs = Security.UserPermissions();
        Boolean bUser = UPs[0];
        Boolean bAuthor = UPs[1];
        Boolean bAdministrator = UPs[2];
        Boolean bAnalysis = UPs[3];
        
                
        // This will have detected mode: if we're in NEW mode, we need to add a new record 
        // and return that...
        if (Mode == 'NEW'){
            return addHelpTopic();
        }
        
        
        String Msg = '';
        Integer i;        
        String EID = '';
        String RLID = '';
        String HTID = this.THelpId;
        String Q = '\'';
        DateTime dat;
        Boolean ExcludeInactiveTopics = !(bAdministrator || bAuthor);
        
        
        // Specific localisations beyond global, local and branding (some of which happen to be shared with the portal)
        map<string, string> mapToolsLocs = ServiceLocalisation.getDialogueLocalisations('iahelp__IHTools', false);
        
        
        // Check our subscription is in order: we'll get redirected here to 
        // "Service Unavailable" page if not...
        PageReference pRef = checkSubscriptionStatus();
        if (pRef != null) {
            return pRef;
        }
        
        
        Diags += 'Topic initialised... ';        
        
                
        if (
            ServiceSecurity.getQueryParameter('ElemId', 1) == ''
            && ServiceSecurity.getQueryParameter('RLID', 2) == ''
            && ServiceSecurity.getQueryParameter('HTID', 2) == ''
            && (HTID == '' || HTID == null)
            ) {        
            // No parameters specified:
            // v.1.12: rather than treat this as an error, navigate to the default topic.
            // To do this, set up a bogus HTID and continue (bogus / invalid HTID is 
            // handled elsewhere)
            
            HTID = 'zzz';       
            Diags += 'Required parameters not specified: amended HTID to bogus value... ';
        } 
                        
        Diags += 'Query parameters exist... ';
                
                
        // Get the key query string parameters        
        EID = ServiceSecurity.getQueryParameter('ElemId', 1);        
        RLID = ServiceSecurity.getQueryParameter('RLID', 2);
        
        // If the reading list is "NEW", this means it's just been created (e.g., by means of 
        // guide enabling activity) in which case, the actual ID will be in a further cookie...

        if (RLID == 'NEW') {
            Cookie ckNew = ApexPages.currentPage().getCookies().get('IHNewestGuide');
            if (ckNew != null) {
                RLID = String.valueOf(ckNew.getValue());
            }
        }

        
        // Note any featured reading list in our member data
        ReadingListId = RLID;


        // Only attempt to get HTID from query if this hasn't already been set
        // by virtue of a standard SF page being sent to us with an "id" 
        // (which will be a Help Topic ID and will have been set via THelpId in extension constructor)
        if (HTID == null) {
            HTID = ServiceSecurity.getQueryParameter('HTID', 2);
        }
        

        // Set "classic" nubbin positioning class
        TCSSClass = ServiceSecurity.getQueryParameter('ElemType', 0);

        // Set SLDS nubbin class name on the basis of the above
        // Initial default:
        LUXNubbinClass = '';
        
        // NO NUBBIN
        if (TCSSClass == 'T0') {
            LUXNubbinClass = '';
        }
        
        // TOP NUBBINS
        if (TCSSClass == 'TL0') {
            LUXNubbinClass = 'slds-nubbin_top-left';
        }
        if (TCSSClass == 'TL1') {
            LUXNubbinClass = 'slds-nubbin_top';
        }
        if (TCSSClass == 'TR1') {
            LUXNubbinClass = 'slds-nubbin_top';
        }
        if (TCSSClass == 'TR0') {
            LUXNubbinClass = 'slds-nubbin_top-right';
        }
        
        // BOTTOM NUBBINS
        if (TCSSClass == 'BL') {
            LUXNubbinClass = 'slds-nubbin_bottom-left';
        }
        if (TCSSClass == 'B') {
            LUXNubbinClass = 'slds-nubbin_bottom';
        }
        if (TCSSClass == 'BR') {
            LUXNubbinClass = 'slds-nubbin_bottom-right';
        }
        
        // LEFT NUBBINS
        if (TCSSClass == 'LT') {
            LUXNubbinClass = 'slds-nubbin_left-top';
        }
        if (TCSSClass == 'L') {
            LUXNubbinClass = 'slds-nubbin_left';
        }
        if (TCSSClass == 'LB') {
            LUXNubbinClass = 'slds-nubbin_left-bottom';
        }
        
        // RIGHT NUBBINS
        if (TCSSClass == 'RT') {
            LUXNubbinClass = 'slds-nubbin_right-top';
        }
        if (TCSSClass == 'R') {
            LUXNubbinClass = 'slds-nubbin_right';
        }
        if (TCSSClass == 'RB') {
            LUXNubbinClass = 'slds-nubbin_right-bottom';
        }
        

        // Certain client pages can have optional switches to control behaviour
        Opts = ServiceSecurity.getQueryParameter('Opts', 2);
        if(Opts == '') {Opts = '0';}

        Diags += 'Query parameters analysed (HTID=' + HTID + ': EID=' + EID + ': RLID=' + RLID + ': Opts=' + Opts + ')... ';

        // Use the specified reading list to get a help topic if need be:
        // "Need be" is when a help topic is NOT specified
        //if (RLID != '') {
        if (RLID != '' && HTID == '') {        
            if (getTopicViaRLID(RLID, ExcludeInactiveTopics) == false) {
                Msg = mapGlbLocs.get('MessageErrorNavigatingToRLTopic');
                Diags += Msg;
                TName = Msg;
                TSummary = TName;
                
                svsI.logInteraction (3, 'Error locating a Help Topic for Reading List ' + RLID, getIHContext(), null, null, null, null, null);                                 
                                
                MessageClass = 'IHError';
                return null;
                                        
            } else {
                // Above call should have set this
                HTID = Hlp.Id;
            }
        }
        
        
        if (HTID == '' && EID == '') {
            // Helped element not specified
            TName = mapGlbLocs.get('MessageBadParameters') + ' (HTID + EID = "")';
            TSummary = TName;
            MessageClass = 'IHError';
            Diags += TName;
            return null;
                
        } else {        
            try {
                        
                if (HTID == '') {
                    // If we don't have a topic ID, look it up from the Helped Element
                    Diags += 'Help topic not supplied - looking for helped element ' + EID + '... ';
                    
                    try {
                        
                        if (getTopicViaEID(EID, ExcludeInactiveTopics) == false) {
                            // Helped element not found
                            Msg = mapGlbLocs.get('MessageMissingHelpedElement');
                            TName = Msg;
                            TSummary = TName;
                            
                            svsI.logInteraction (3, 'No Helped Element found matching ' + EID, getIHContext(), null, null, null, null, null);                                 
                            
                            // Admin options on the topic are subject to user rights
                            if (bAuthor || bAdministrator) {
                                TAdminLink = mapGlbLocs.get('MessageGenericErrorShort');                           
                        
                            } else {
                                TAdminLink = '';
                            }
                            
                            
                            MessageClass = 'IHError';
                            return null;
        
                        } else {
                            Diags += 'Got Help Topic via EID ' + EID + '... ';                                    
                        }                              
                                        
                    } catch (exception e) {
                        TName = e.getTypeName() + ': ' + e.getMessage() + ' - ' + Diags;
                        TSummary = TName;
                        MessageClass = 'IHError';
                        Diags += TName;
                        return null;                                    
                    }
                    
                } else {

                    // We were supplied with HTID, so get the help topic from this
                    try {
                        if (getTopicViaHTID(HTID, ExcludeInactiveTopics) == false) {

                            // On failure, log an issue
                            svsI.logInteraction (3, 'Error locating Help Topic ' + HTID, getIHContext(), null, null, null, null, null);                                 
                                
                            // Set topic details to safe values
                            TName = mapGlbLocs.get('MessageMissingDefaultTopic');
                            TSummary = TName;
                            TDesc = '';
                                
                            // Set tools links etc to safe values
                            TAdminLink = '';
                            TCommentLink = 'iahelp__IHComment';     
                            TEditModeLink = '';     
                            
                            MessageClass = 'IHError';
                            Diags = TName;
                                
                            return null;
                                                                        
                        } else {
                            Diags += 'Got Help Topic via HTID ' + HTID + '... ';
                        }
                            
                    } catch (exception e) {
                        TName = e.getTypeName() + ': ' + e.getMessage() + ' - ' + Diags;
                        TSummary = TName;
                        MessageClass = 'IHError';
                        Diags += TName;
                        return null;                                    
                    }
                }                                               
                        
                try {                                   
                    // Set basic details from help topic
                    HTID = Hlp.Id;
                    THelpId = Hlp.Id;  

                    // Ensure we obey SF FLS in all cases...
                    if (Schema.sObjectType.HelpTopic__c.fields.Name.isAccessible()) {
                        TName = Hlp.Name;
                        TName = deTokenize(TName);
                        
                    } else {
                        TName = '';
                    }
                    
                    if (Schema.sObjectType.HelpTopic__c.fields.Description__c.isAccessible()) {     
                        
                        // Deal with meta keyword markup here...
                        TDesc = markKeywords(Hlp, isLUXCaller);                                              

                        // Detokenise...
                        TDesc = deTokenize(TDesc);

                    } else {
                        TDesc = '';
                    }

                    if (Schema.sObjectType.HelpTopic__c.fields.Summary__c.isAccessible()) {
                        TSummary = Hlp.Summary__c; 
                        TSummary = deTokenize(TSummary);
                        
                    } else {
                        TSummary = ''; 
                    }

                    if (Schema.sObjectType.HelpTopic__c.fields.Thumbnail__c.isAccessible()) {
                        TImage = Hlp.Thumbnail__c;
                    } else {
                        TImage = '';
                    }

                    if (Schema.sObjectType.HelpTopic__c.fields.ImageURL__c.isAccessible()) {
                        TImageURL = ensureProtocol(Hlp.ImageURL__c);
                    } else {
                        TImageURL = '';
                    }

                    if (Schema.sObjectType.HelpTopic__c.fields.ImageTitle__c.isAccessible()) {
                        TImageTitle = Hlp.ImageTitle__c;                    
                    } else {
                        TImageTitle = '';                    
                    }

                    if (Schema.sObjectType.HelpTopic__c.fields.ImageCaption__c.isAccessible()) {
                        TImageCaption = Hlp.ImageCaption__c;
                    } else {
                        TImageCaption = '';
                    }

                    if (Schema.sObjectType.HelpTopic__c.fields.ImageWidth__c.isAccessible()) {
                        TImageWidth = Hlp.ImageWidth__c;
                    } else {
                        TImageWidth = 0;
                    }

                    if (Schema.sObjectType.HelpTopic__c.fields.ImageHeight__c.isAccessible()) {
                        TImageHeight = Hlp.ImageHeight__c;
                    } else {
                        TImageHeight = 0;
                    }

                    if (Schema.sObjectType.HelpTopic__c.fields.VideoURL__c.isAccessible()) {
                        // 1.29.3 - Blank URLs can cause security issues (e.g., in IE with CSP):
                        // Set to a "safe" default in these cases
                        TVURL = Hlp.VideoURL__c;
                        if (TVURL == '' || TVURL == null) TVURL = defaultVURL;
                        TVURL = ensureProtocol(TVURL);

                    } else {
                        TVURL = defaultVURL;
                    }

                    if (Schema.sObjectType.HelpTopic__c.fields.VideoWidth__c.isAccessible()) {
                        TVWidth = Hlp.VideoWidth__c;
                    } else {
                        TVWidth = 0;
                    }

                    if (Schema.sObjectType.HelpTopic__c.fields.VideoHeight__c.isAccessible()) {
                        TVHeight = Hlp.VideoHeight__c;
                    } else {
                        TVHeight = 0;
                    }

                    if (Schema.sObjectType.HelpTopic__c.fields.VideoTitle__c.isAccessible()) {
                        TVTitle = Hlp.VideoTitle__c;                 
                    } else {
                        TVTitle = '';                 
                    }
                    
                    if (Schema.sObjectType.HelpTopic__c.fields.VideoCaption__c.isAccessible()) {
                        TVCaption = Hlp.VideoCaption__c;                 
                    } else {
                        TVCaption = '';                 
                    }                                       
                    
                    if (Schema.sObjectType.HelpTopic__c.fields.CustomStyle__c.isAccessible()) {
                        CustomStyle = Hlp.CustomStyle__c; 
                        if (CustomStyle != '' && CustomStyle != null) {CustomStyle = ' ' + CustomStyle;}                
                    } else {
                        CustomStyle = '';                 
                    }
                    
                    
                    // Having set image/video details, above, we can note whether or not
                    // any media information is present
                    THasMedia = (TImageURL != '' && TImageURL != null)
                                        || (TImageCaption != '' && TImageCaption != null)
                                        || (TImageTitle != '' && TImageTitle != null)
                                        || (TVURL != '' && TVURL != null && TVURL != defaultVURL)
                                        || (TVCaption != '' && TVCaption != null)
                                        || (TVTitle != '' && TVTitle != null);
                    
                    
                    // Review date for a topic (which we defaulted to today in initialisation)
                    // is actually topic last modified date plus a number of days (from gloabl settings)
                    dat = Hlp.LastModifiedDate;
                    if (ControllerSettings.getSettings().ReviewWithinDays__c != null) {
                        dat = dat.addDays((Integer) ControllerSettings.getSettings().ReviewWithinDays__c);
                        ReviewDate = dat.format('dd-MMM-yyyy');
                    }

                    // No need to offer help amendment / admin link if all is well
                    TAdminLink = '';
                    
                      
                    // Comment / bookmark available to all
                    TCommentLink = RootUrl + '/apex/iahelp__IHComment?HTID=' + HTID;
                    TBookmarkLink = RootUrl + '/apex/iahelp__IHManageBookmarks?HTID=' + HTID;
                    
                    
                    // SF help link dependent on existence of SF link for this topic
                    if (Schema.sObjectType.HelpTopic__c.fields.SalesforceHelpURL__c.isAccessible()) {
                        if (Hlp.SalesforceHelpURL__c != null) {
                            TSFHelpLink = '<a href="' + Hlp.SalesforceHelpURL__c + '" target="_SFHelp" title="' + mapToolsLocs.get('TipButtonSFHelp') + '"><div class="IHIcon IHIconSalesforceHelp"></div></a>';                                        
                        }
                    }
                    
                    // If SF help is not available, way we show this varies by user role:
                    // Users see nothing, Authors / Admins get a visual clue that SF help not present
                    if (TSFHelpLink == '') {
                        if (bAuthor || bAdministrator) {
                            TSFHelpLink = '<div class="IHIcon IHIconSalesforceHelpNone"></div>';
                        }
                    }
                    
                    
                    // Link to topic history report
                    if (bAuthor || bAdministrator) {
                        try {
                            // 1.24.26: In case an unsuitable license type has been granted Author / Admin permission set,
                            // check here that reports are available to the user...
                            if (Schema.sObjectType.Report.isAccessible() && ServiceSecurity.CanRunReports()) {
                                Report Rpt = [SELECT Id, Name FROM Report  WHERE Name = 'Help Topic: History Drill Thru Report'];
                                THistoryReportId = Rpt.Id;
                                                
                                String s = Hlp.Name;                
                                s = EncodingUtil.urlEncode(s, 'UTF-8');
                                                
                                THistoryLink =  '<a title="' + mapToolsLocs.get('TipButtonTopicHistory') + '" target="_Blank" ';
                                THistoryLink += 'href="' + TRootLink + '/' + THistoryReportId; 
                                THistoryLink += '?pv0=' + s;
                                THistoryLink += '&drilldown=1">';
                                THistoryLink += '<div class="IHIcon IHIconHistory"></div></a>';
                                
                            } else {
                                THistoryLink = '<div class="IHIcon IHIconHistoryUnavailable"></div>';                                                                           
                            }
                                                                                        
                        } catch (exception e) {
                            THistoryLink = '<div class="IHIcon IHIconHistoryUnavailable"></div>';                                                                           
                        }
                    }
                                      
                    Diags += 'Basic topic details set per FLS: continuing to preview media... ';

                                
                    // Set preview media to image or video, per help topic's stated preference:
                    // In either case, we only want this tag formed if URLs have been set correctly.
                    // Where it is set, we also work out media aspect ratio for the convenience of client templates etc
                    if (Hlp.CalloutMediaChoice__c == 'Image') {
                                                
                        if (TImageURL != '' && TImageURL != null) {
                            TPreviewMedia = TImageURL;
                            TPreviewMediaTitle = TImageTitle;
                            TPreviewMediaCaption = TImageCaption;
                                
                            if (Hlp.ImageHeight__c != 0 && Hlp.ImageHeight__c != null && Hlp.ImageWidth__c != 0 && Hlp.ImageWidth__c != null) {
                                TPreviewMediaAR = Hlp.ImageWidth__c / Hlp.ImageHeight__c;                                       
                            } else {
                                TPreviewMediaAR = 1;
                            }
                                                        
                        } else {
                            TPreviewMedia = '';
                            TPreviewMediaTitle = TImageTitle;
                            TPreviewMediaCaption = TImageCaption;
                            TPreviewMediaAR = 1;
                        }                                                
                        
                    } else {
                        if (TVURL != '' && TVURL != null && TVURL != defaultVURL) {
                            TPreviewMedia = TVURL;
                            TPreviewMediaTitle = TVTitle;
                            TPreviewMediaCaption = TVCaption;

                            if (Hlp.VideoHeight__c != 0 && Hlp.VideoHeight__c != null && Hlp.VideoWidth__c != 0 && Hlp.VideoWidth__c != null) {
                                TPreviewMediaAR = Hlp.VideoWidth__c / Hlp.VideoHeight__c;                                       
                            } else {
                                TPreviewMediaAR = 1;
                            }
                                
                        } else {
                            TPreviewMedia = defaultVURL;
                            TPreviewMediaTitle = TVTitle;
                            TPreviewMediaCaption = TVCaption;                               
                            TPreviewMediaAR = 1;
                        }                        
                    }
                    
                    // Set callout preview link by looking up details of specified callout
                    TCalloutPreviewLink = getTemplateAddress(Hlp.CalloutTemplate__r.PageURL__c) + '?' + URL.getCurrentRequestUrl().getQuery();
                    
                                
                    // Now we have a Help Topic we can set up related links:
                    // We want both those this Topic refers to and those referring to it...

                    Diags += 'Set topic details - continuing to related help... ';
                    
                                        
                    // Respect FLS when displaying results
                    Boolean showName = Schema.sObjectType.HelpTopic__c.fields.Name.isAccessible();
                    Boolean showSummary = Schema.sObjectType.HelpTopic__c.fields.Summary__c.isAccessible();
                    Boolean showItemURL = Schema.sObjectType.HelpRelationship__c.fields.RelatedHelpTopic__c.isAccessible();

                    // Note need to filter active topics as appropriate to user.
                    // Also: 1.17: global setting controls whether or not those relating TO (referencing)
                    // the current topic are to show up in the list. This can be overridden for the 
                    // individual topic by its author

                    // 1.28 - hive relative finding to separate function                    
                    HelpRelationship__c[] Rels = getHelpRelationshipsForHT(HTID, ExcludeInactiveTopics);
                    
                    for (HelpRelationship__c Rel : Rels) {
                        Relations.add(New ServiceIHLists.RelatedHelpListItem(Rel, HTID, showName, showSummary, showItemURL, isIH1UX, bAdministrator || bAuthor));
                    }
                    Relations.sort();

                    
                    // Also, set up Reading Lists: 
                    Diags += 'Got related help - continuing to related reading lists... ';


                    // Respect FLS when creating reading lists
                    Boolean showRLName = Schema.sObjectType.HelpReadingList__c.fields.Name.isAccessible();
                    Boolean showRLSummary = Schema.sObjectType.HelpReadingList__c.fields.Summary__c.isAccessible();
                    Boolean showRLDescription = Schema.sObjectType.HelpReadingList__c.fields.Description__c.isAccessible();
                    Boolean showRLEName = showName;
                    Boolean showRLEImageURL = Schema.sObjectType.HelpTopic__c.fields.ImageURL__c.isAccessible();
                    Boolean showRLEVideoURL = Schema.sObjectType.HelpTopic__c.fields.VideoURL__c.isAccessible();

                    // We want any that include the current help topic...
                    // ...plus those that have been marked as featured:                    
                    dat = date.today();  
                    
                    
                    // NB: filtering of entries by Active flag / user rights is delegated
                    // to the reading list itself (ServiceIHLists)
                    // 1.21: HOWEVER: we do filter here to Active RLs only for Helped Users 
                    // 1.28 - hive RLE finding to separate function                    
                    
                    list<string>RLEHTIDs = new list<string>();
                    RLEHTIDs.add(HTID);
                    HelpReadingListEntry__c[] Ents = getHelpReadingListEntriesForHTID(RLEHTIDs, bAuthor);

                    for (HelpReadingListEntry__c Ent : Ents) {
                        
                            // We only want each reading list once, so 
                            // check before adding that we don't have it already
                            Boolean doAdd = true;
                            for (ServiceIHLists.ReadingList RL: ReadingLists) {
                                if (Ent.HelpReadingList__c == RL.RLID) {
                                    doAdd = false;
                                    break;
                                }
                            }
                            
                            if (doAdd == true) {
                                ReadingLists.add(New ServiceIHLists.ReadingList(Ent, showRLName, showRLSummary, showRLDescription, showRLEName, showRLEImageURL, showRLEVideoURL, this.THelpId, isIH1UX, bAdministrator, bAuthor));
                                
                                // Keep count of how many RLs we're actually in: this may not be the same as the number of RLs,
                                // which also includes featured RLs, whether or not the current topic is an entry...
                                if (ReadingLists[ReadingLists.size() - 1].IncludesCurrentTopic == true) {
                                        ReadingListsImIn += 1;
                                }
                            }
                          
                    }

                    // Sort the resulting reading lists
                    ReadingLists.sort();
                                        
                    Diags += 'Got all reading lists - continuing to related resources... ';
                                        
                                        
                    // Also, get related resources
                    Boolean showRRName = Schema.sObjectType.HelpResource__c.fields.Name.isAccessible();
                    Boolean showRRSummary = Schema.sObjectType.HelpResource__c.fields.Summary__c.isAccessible();
                    Boolean showResourceURL = Schema.sObjectType.HelpResource__c.fields.ResourceURL__c.isAccessible();
                    Boolean showPreview = Schema.sObjectType.HelpResource__c.fields.Preview__c.isAccessible();
                    Boolean showPreviewURL = Schema.sObjectType.HelpResource__c.fields.PreviewURL__c.isAccessible();
                    Boolean showLocation = Schema.sObjectType.HelpResource__c.fields.Location__c.isAccessible();
                    Boolean showUsageNotes = Schema.sObjectType.HelpTopicResource__c.fields.UsageNotes__c.isAccessible();
                    
                    // 1.28 - hive resource finding to separate function                    
                    HelpTopicResource__c[] HTRes = getHelpTopicResourcesForHT(HTID);
                    for (HelpTopicResource__c HTR : HTRes) 
                        {
                            Resources.add(New ServiceIHLists.RelatedResourcesListItem(HTR, showRRName, showRRSummary, showResourceURL, showPreview, showPreviewURL, showLocation, showUsageNotes, bAdministrator || bAuthor));
                    }
                                        

                    // Now set up rights-dependent links:
                    // Stats icon available to Analysts only
                    if (bAnalysis) {
                        TStatsLink = ControllerStats.initialiseMoreLink(Hlp);
                        
                        TInteractionsLink = '<a href="' + TStatsLink + '" title="' + mapToolsLocs.get('TipButtonStats') + '" target="_Stats">';
                        TInteractionsLink += '<div class="IHIcon IHIconModeAnalyse"></div></a>';                                              
                    }
                                
                                
                    // Various help editing links available to authors / admins only
                    if (bAuthor || bAdministrator) {
                        String s = ControllerSettings.getSettings().SFObjectIds__c;
                                                                                
                        TSFEditingLinks += '<a title="' + mapToolsLocs.get('TipButtonSFTopicsTab') + '" href="' + TRootLink + '/' + s.substring(0, 3) + '"><div class="IHIcon IHIconTab"></div></a>';
                                        
                        // We only want the view helped elements link visible when there are related elements
                        HelpedElement__c[] ViewEs = [SELECT Id
                                        FROM HelpedElement__c
                                        WHERE HelpTopic__c = :HTID];
                                        
                        if (ViewEs.size() > 0) {
                            TViewElementsLink = '<a href="#" title="' + mapToolsLocs.get('TipButtonViewHelpedElements') + '" onclick="javascript:IHWebToolTips.DoTips(' + Q + 'dfrm' + Q + ', ' + Q + TRootLink + '/apex/iahelp__IHSearchResults?Opts=6&HTID=' + THelpId + Q + ', ' + Q + '7' + Q + ', 600, 440, event);">';
                            TViewElementsLink += '<div class="IHIcon IHIconHelpedElements"></div></a>';
                                
                        } else {
                            TViewElementsLink = '';
                        }

                        TAddRelatedHelpLink = '<a href="#" title="' + mapToolsLocs.get('TipButtonLinkRelatedHelp') + '" onclick="javascript:IHWebToolTips.DoTips(' + Q + 'dfrm' + Q + ', ' + Q + TRootLink + '/apex/iahelp__IHSearchResults?HTID=' + THelpId + '&Opts=1' + Q + ', ' + Q + '7' + Q + ', 200, 478, event);">';
                        TAddRelatedHelpLink += '<div class="IHIcon IHIconLink"></div></a>';

                        TAddRelatedResourceLink = '<a href="#" title="' + mapToolsLocs.get('TipButtonLinkRelatedResource') + '" onclick="javascript:IHWebToolTips.DoTips(' + Q + 'dfrm' + Q + ', ' + Q + TRootLink + '/apex/iahelp__IHSearchResults?HTID=' + THelpId + '&Opts=3' + Q + ', ' + Q + '7' + Q + ', 200, 530, event);">';
                        TAddRelatedResourceLink += '<div class="IHIcon16 IHIconLink"></div></a>';

                        // Add reading list link can now include HTID (to allow Add + Link facility)
                        ServiceIHLists.ReadingList RL = new ServiceIHLists.ReadingList();
                        TAddReadingListLink = '<a href="#" title="' + mapGlbLocs.get('TipButtonCreateRL') + '" onclick="javascript:IHWebToolTips.DoTips(' + Q + 'dfrm' + Q + ', ' + Q + RL.NewLink + '&HTID=' + THelpId + Q + ', ' + Q + '7' + Q + ', 200, 585, event);">';
                        TAddReadingListLink += '<div class="IHIcon IHIconAdd"></div></a>';

                        // We can also add this topic to a reading list
                        TAddToReadingListLink = '<a href="#" title="' + mapToolsLocs.get('TipButtonAddTopicToRL') + '" onclick="javascript:IHWebToolTips.DoTips(' + Q + 'dfrm' + Q + ', ' + Q + TRootLink + '/apex/iahelp__IHSearchResults?HTID=' + THelpId + '&Opts=4' + Q + ', ' + Q + '7' + Q + ', 200, 330, event);">';
                        TAddToReadingListLink += '<div class="IHIcon IHIconEditList"></div></a>';

                        TAddHelpTopicLink = '<div title="' + mapToolsLocs.get('TipButtonAddTopic') + '" class="IHIcon IHIconAdd"></div>';                                         
                        TDeleteHelpTopicLink = '<div title="' + mapToolsLocs.get('TipButtonDeleteTopic') + '" class="IHIcon IHIconDelete"></div>';
                    }
    
                    // Although bookmarks are global to the user and not topic dependent
                    // we set them up here once we have a topic so we know whether or not
                    // the current topic has been bookmarked...
                    initialiseBookmarks(showName, showSummary);


                    // Similarly, although the search page is global, we can now seed it with 
                    // a help topic ID
                    THelpHomeLink += '?HTID=' + HTID;


                } catch (exception e) {
                    // No topic matching that specified in helped element                    
                    svsI.logInteraction (3, 'No topic matching that specified in helped element', getIHContext(), HE.HelpedPageLayout__c, HE.Id, null, null, null);                         

                    Msg = mapGlbLocs.get('MessageMissingDefaultTopic');
                    TName = Msg;
                    TSummary = TName;
                    
                    // Admin options on the topic are subject to user rights
                    if (bAuthor || bAdministrator) {
                        TAdminLink = mapGlbLocs.get('MessageGenericErrorShort');                           
                    } else {
                        TAdminLink = '';
                    }
                    
                    MessageClass = 'IHError';
                    Diags += TName;
                    return null;
                }
 
                try {
                    // Get the template specified by the topic
                    TLayout = getTemplateAddress(Hlp.Template__r.PageURL__c) + '?HTID=' + HTID + '&ElemId=' + EID;

                    
                    // Add passthroughs data-bearing parameteres to this if provided
                    string temp = getPassthroughParameters();
                    if (temp != '') {
                        TLayout += '&' + temp;
                    }
                    
                                                     
                    // Create a hyperlink to a page showing full help details:
                    // NB: for authors / admins, we always show this regardless of state of help topic record
                    // as this allows help authors to edit via the tools page etc.
                    // Users only see this link if Topic states they should...
                    
                    if (Hlp.ShowReadMoreLink__c == true || (bAuthor || bAdministrator)) {

                        String U = RootUrl;
                                           
                        if (isLUXCaller == false) {
                            U += '/apex/' + ControllerSettings.NameSpace + '__' + PortalPage + '?HTID=' + HTID;
                        } else {
                            U = '/' + HTID;
                        }  
                        
                        // We want authors/admins to see the link - but to be aware that they
                        // are the only ones who will do so in cases where "show read more" option is not set.
                        // Also, in either case we must take account of whether or not we're in an SF console tab
                            
                        if (Hlp.ShowReadMoreLink__c == true) {                                                              
                            if (isConsolePage == true) {
                                TMoreLink = '<a title="' + mapGlbLocs.get('TipReadMoreLinkUsers') + '" href="#" onclick="javascript:IHQAMenu.openPrimaryTab (\'' + U + '\', \'' + TName + '\')"><div class="MoreLink">' + mapGlbLocs.get('AdviceLabelReadMoreLink') + '</div></a>';                                            
                                TMoreLinkText = mapGlbLocs.get('AdviceLabelReadMoreLink');
                                TMoreLinkTitle = mapGlbLocs.get('TipReadMoreLinkUsers');
                                TMoreLinkHref = '#';
                                TMoreLinkOnClick = U;
                                            
                            } else {
                                TMoreLink = '<a title="' + mapGlbLocs.get('TipReadMoreLinkUsers') + '" target="_HelpTopic" href="' + U + '"><div class="MoreLink">' + mapGlbLocs.get('AdviceLabelReadMoreLink') + '</div></a>';                           
                                TMoreLinkText = mapGlbLocs.get('AdviceLabelReadMoreLink');
                                TMoreLinkTitle = mapGlbLocs.get('TipReadMoreLinkUsers');
                                TMoreLinkHref = U;
                                TMoreLinkOnclick = '';
                            }
                            
                        } else {
                            if (isConsolePage == true) {
                                TMoreLink = '<a class="Authoring" title="' + mapGlbLocs.get('TipReadMoreLinkAuthors') + '" href="#" onclick="javascript:IHQAMenu.openPrimaryTab (\'' + U + '\', \'' + TName + '\')"><div class="MoreLink">[' + mapGlbLocs.get('AdviceLabelReadMoreLink') + ']</div></a>';
                                TMoreLinkText = '[' + mapGlbLocs.get('AdviceLabelReadMoreLink') + ']';
                                TMoreLinkTitle = mapGlbLocs.get('TipReadMoreLinkAuthors');
                                TMoreLinkHref = '#';
                                TMoreLinkOnclick = U;

                            } else {
                                TMoreLink = '<a class="Authoring" title="' + mapGlbLocs.get('TipReadMoreLinkAuthors') + '" target="_HelpTopic" href="' + U + '"><div class="MoreLink">[' + mapGlbLocs.get('AdviceLabelReadMoreLink') + ']</div></a>';                             
                                TMoreLinkText = '[' + mapGlbLocs.get('AdviceLabelReadMoreLink') + ']';
                                TMoreLinkTitle = mapGlbLocs.get('TipReadMoreLinkAuthors');
                                TMoreLinkHref = U;
                                TMoreLinkOnclick = '';
                            }
                        }
                                                                                                
                    } else {
                        TMoreLink = '';
                        TMoreLinkText = '';
                        TMoreLinkTitle = '';
                        TMoreLinkHref = '';
                        TMoreLinkOnclick = '';
                    }
                    
                    
                    Diags += 'TMoreLink set... ';
                                

                    if (Schema.sObjectType.HelpTopic__c.fields.HeightBeforeScrolling__c.isAccessible()) {
                        if (Hlp.HeightBeforeScrolling__c != null) {
                            THeight = Hlp.HeightBeforeScrolling__c;
                        } else {
                            THeight = 500;                                  
                        }                               

                    } else {
                        THeight = 500;                                  
                    }

                                                                                            
                    // Every time help is used, we should log an interation:
                    // UNLESS we're viewing from the tools page itself as its "child" templates will do the logging.
                    // ALSO: namespace may or may not be present, so check both possibilities throughout...
                    
                    if (URL.getCurrentRequestUrl().toExternalForm().toUpperCase().indexof('/APEX/' + NameSpace.toUpperCase() + '__' + PortalPage.toUpperCase() + '?') == -1
                        && URL.getCurrentRequestUrl().toExternalForm().toUpperCase().indexof('/APEX/' + PortalPage.toUpperCase() + '?') == -1) {
                        
                        // Take note of whether it was a guide that ocassioned this viewing:
                        String AsGuide = ServiceSecurity.getQueryParameter('AsGuide', 2);
                            
                        // Also note which user interface was involved:
                        String UX;
                        if (isIH1UX == true) {UX = ' (SF1)';} else {UX = '';}
                        
                        // This is fundamentally a read, but could be a callout or full page view:
                        // Decision as to which rests with the template being used...

                        if (URL.getCurrentRequestUrl().toExternalForm().toUpperCase().indexof('/APEX/' + NameSpace.toUpperCase() + '__' + Hlp.Template__r.PageURL__c.toUpperCase() + '?') != -1
                            || URL.getCurrentRequestUrl().toExternalForm().toUpperCase().indexof('/APEX/' + Hlp.Template__r.PageURL__c.toUpperCase() + '?') != -1) {
                            // This is the full topic view
                            if (AsGuide != '') {
                                svsI.logInteraction (4, 'Guide Topic Viewed' + UX, getIHContext(), null, null, Hlp.Id, AsGuide, null);                          
                            } else {
                                svsI.logInteraction (4, 'Help Topic Viewed' + UX, getIHContext(), null, null, Hlp.Id, null, null);                          
                            }                               
                                        
                        } else {
                            // This is the callout: preview link on tools page editing panel may look
                            // like a callout view, but there will be no helped element (callout will have been called
                            // via help topic ID) - so we must check for this here... 
                            if (HE != null) {

                                if (AsGuide != '') {
                                    svsI.logInteraction (1, 'Guide Callout Viewed' + UX, getIHContext(), HE.HelpedPageLayout__c, HE.Id, Hlp.Id, AsGuide, null);                          
                                } else {
                                    svsI.logInteraction (1, 'Help Callout Viewed' + UX, getIHContext(), HE.HelpedPageLayout__c, HE.Id, Hlp.Id, null, null);                          
                                }                               

                            } else {
                                svsI.logInteraction (1, 'Help Callout Viewed (Element unknown)' + UX, getIHContext(), null, null, Hlp.Id, null, null);                          
                            }
                            
                        }                                                                                   
                    }                    
                                
                    // To reach this point means there were no issues, so
                    // any diagnostics etc can be dropped
                    Diags = '';
                    
                    // However, if there are any oversubscription issues, we should report these...
                    Diags += LicenseIssue;
                                
                    return null;
                                        
                } catch (exception e) {
                    // No template matching that specified by the help topic
                    svsI.logInteraction (3, 'Error locating the Template specified for this Help Topic: ' + Diags, getIHContext(), null, null, Hlp.Id, null, null);                        
                            
                    Msg = mapGlbLocs.get('MessageMissingTemplate');
                    TName = Hlp.Name + ' : ' + Msg + ' - ' + Diags + ' - ' + e.getMessage();
                    TSummary = TName;
                    
                    // Admin options on the topic are subject to user rights
                    if (bAuthor || bAdministrator) {
                        TAdminLink = mapGlbLocs.get('MessageGenericErrorShort');                           
                    } else {
                        TAdminLink = '';
                    }
                    
                    MessageClass = 'IHError';
                    Diags += TName;
                    return null;                                    
                }                        
                        
            } catch (Exception e) {
                TName = e.getTypeName() + ': ' + e.getMessage() + ' - ' + Diags;
                TSummary = TName;
                MessageClass = 'IHError'; 
                Diags += TName;
                return null;            
            }
                                           
        }       // We got query string
    }
     
     
    // Redirect request when HTID etc is known but template is not, as when topic edit has been done
    public PageReference gotoTopicTemplate() {

        try {
            
            // You should have an HTID: look up the help topic
            String IH1;
            HelpTopic__c Hlp;
            HelpTopicTemplate__c HTT;
            String HTID = ServiceSecurity.getQueryParameter('HTID', 2);
            String showCallout = ServiceSecurity.getQueryParameter('ShowCallout', 2);
            String LXC = ServiceSecurity.getQueryParameter('LUXCaller', 2);
            
            
            // Template to which to redirect can be controlled by incoming page parameters...
            
            if (showCallout == 'true') {                
                // Show the callout template as last saved for this topic
                Hlp = [SELECT CalloutTemplate__c FROM HelpTopic__c WHERE Id = :HTID];
                HTT = [SELECT PageURL__c FROM HelpTopicTemplate__c WHERE Id = :Hlp.CalloutTemplate__c];
                
            } else if (showCallout != '') {
                // Show the topic in the specified callout template
                HTT = [SELECT PageURL__c FROM HelpTopicTemplate__c WHERE Id = :showCallout];
                
            } else {
                // Show the topic in its full template
                Hlp = [SELECT Template__c FROM HelpTopic__c WHERE Id = :HTID];
                HTT = [SELECT PageURL__c FROM HelpTopicTemplate__c WHERE Id = :Hlp.Template__c];
            }
            
                
            // Also may need to pass through IH1UX styling info...
            if (ApexPages.currentPage().getParameters().get('IH1UX') == 'true') {
                IH1 = 'true';
            } else {
                IH1 = 'false';
            }                               
                                
            // Pass through forcing of LUX component override, where specified
            if (LXC == '') {
                LXC = 'false';
            }
            
            // Re-direct to its specified topic template:
            // Get template URL based on its stated page address
            // 1.39.n+ (1.38.): tack on any pass through parameters            
            return new System.Pagereference(getTemplateAddress(HTT.PageURL__c) + '?LUXCaller=' + LXC + '&HTID=' + HTID + '&IH1UX=' + IH1 + '&' + getPassThroughParameters());
                
        } catch (exception e) {
            return null;
        }
        
    }


    // Gets the correct VF address to a help template: authors should have marked their template records with a URL in the form namespace.page
    public String getTemplateAddress(String TemplatePageURL) {

        String retVal;
        String[] PageParts;
        String Pg = TemplatePageURL;
            
        try {
            // Use community path, if relevant
            retVal = ControllerSettings.getCommunityRoot();
            if (retVal == '') {
                retVal = URL.getOrgDomainURL().toExternalForm();
            }
        
            if(TemplatePageURL.indexOf('.') != -1){
                PageParts = TemplatePageURL.split('\\.');
                retVal = retVal.replace(ControllerSettings.NameSpace, PageParts[0]);
                Pg = PageParts[1];
            } 
            
            retVal += '/apex/' + Pg;
                
        } catch (exception e) {
            //retVal = 'Error deriving Help Topic Template web address: ' + e.getMessage();
        }
        
        return retVal;
    }


    // Visit a help resource and note in doing so the fact that this has been done:
    // 1.43+ : note this is now global, allowing for use via custom callouts etc.
    global PageReference gotoResource() {
        
        ServiceInteractions sI = new ServiceInteractions();
        
        try {
                
            // We should have has the selected record parameter set in the mark up for this command:
            // Use this to locate the required resource
            HelpTopicResource__c HTR = [SELECT HelpResource__r.Id, HelpResource__r.Name, HelpResource__r.ResourceURL__c
                                                            FROM HelpTopicResource__c
                                                            WHERE Id = :SelectedRecord];
                                
            // ToDo: we should pass Resource ID (currently via the EID slot) in a better way...
            sI.logInteraction(6, 'Resource "' + HTR.HelpResource__r.Name + '" was viewed with destination ' + HTR.HelpResource__r.ResourceURL__c, getIHContext(), null, HTR.HelpResource__r.Id, THelpId, null, null);

            // 1.39.n+ allow for tokens in URLs
            string U = HTR.HelpResource__r.ResourceURL__c;
            U = deTokenize(U);
                                                
            System.PageReference P = new System.Pagereference(U);
                
            // 1.17: we need to extract any anchor portion of the resource URL and set
            // this specifically on the page reference returned...                  
            if (HTR.HelpResource__r.ResourceURL__c.indexOf('#') != -1) {
                P.setAnchor(HTR.HelpResource__r.ResourceURL__c.subString(HTR.HelpResource__r.ResourceURL__c.indexOf('#') +1));
            }

            return P;
                                
        } catch (exception e) {
            sI.logInteraction(3, 'Error attempting to navigate to Resource "' + SelectedRecord + '": ' + e.getMessage(), getIHContext(), null, null, null, null, null);
            return null;
        }
        
    }


    // Visit a requested help topic using the appropriate portal page
    public PageReference gotoTopic() {
        // Use community path, if relevant
        String RootUrl = ControllerSettings.getCommunityRoot();
        if (RootUrl == '') {
            RootUrl = URL.getOrgDomainURL().toExternalForm();
        }
        
        return new System.Pagereference(RootUrl + '/apex/iahelp__' + PortalPage + '?HTID=' + SelectedRecord + '&IH1UX=' + isIH1UX);
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Handling of pass-through parameters / contextual data
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    // The list of parameters that may be passed through: any others will be ignored
    private static final list<string> passThroughParams = new list<string>{'token0', 'token1', 'token2', 'token3', 'token4', 'token5', 'token6', 'token7', 'token8', 'token9'};


    // Member data providing a URL parameter string (param=val&param=val etc) built from any of the permitted parameters that have been passed
    public string getPassThroughParameters() {
        
        string retVal = '';
        string tVal;
        
        for (string token : passThroughParams) {
            tVal = ServiceSecurity.getQueryParameter(token, 2);
            
            // Skip parameters that have not been supplied
            if (tVal != '') {
                retVal += token + '=' + tVal + '&';
            }
        }
        if (retVal.length() > 0) {
            retVal = retVal.subString(0, retVal.length() - 1);
        }
        
        return retVal;
    }
    

    // Parse a URL (typically one we are generating for "onward" use, e.g., a topic or resource URL, having arrived at a page featuring 
    // passthrough parameters in its request) that includes permitted {!tokens} and replace them with the relevant URL-passed values
    private string deTokenize (string U) {
        
        string retVal = U;
        string tokenVal;    
    
        boolean ApexPageExists = ServiceSecurity.ApexPageExists();
    
        ServiceInteractions sI = new ServiceInteractions();
        string msg = 'Help controller - deTokenize: Incoming value: ' + U + '... ';
        
        if (U == null) {
            // Nothing to detokenize
            
        } else {   
            try {
                // We only get access to URL parameters, it seems, through the APEX page, not via system.URL,
                // which can only parse an existing, known url for these (getQuery returns null from current request)
                if (ApexPageExists) {
                    
                    msg += 'Pass thru params length: ' + passThroughParams.size() + '... ';
                    
                    for (string token : passThroughParams) {                    
                        msg += 'token = "' + token + '"... ';       
                        
                        tokenVal = ServiceSecurity.getQueryParameter(token, 2);
                        msg += 'token value ="' + tokenVal + '"... ';
                                            
                        retVal = retVal.replace('{!' + token + '}', tokenVal);                          
                        msg += 'token val = "' + tokenVal + '"... ';                                    
                    }
                }
                
                
            } catch (exception e) {
                msg += 'ERROR: '+ e.getMessage();
               sI.logInteraction(3, msg, getIHContext(), null, null, null, null, null);
            }
        }
    
        return retVal;
    }    
    

    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // CONTEXTUAL SUPPORT (EG FOR GetHelp)
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    // Get the Help Reading Lists associated with a given Help Topic or Topics
    public HelpReadingListEntry__c[] getHelpReadingListEntriesForHTID(list<string> HTIDs, boolean isAuthor) {

        HelpReadingListEntry__c[] retVal;
        DateTime dat = date.today();        
        
        try {
            retVal = [SELECT HelpTopic__c, ReadingOrder__c, HelpReadingList__c,                     
                                                HelpReadingList__r.Name, HelpReadingList__r.Summary__c, 
                                                HelpReadingList__r.Description__c, HelpReadingList__r.NumberOfEntries__c,
                                                HelpReadingList__r.ReadingListType__c, ReadingListFeaturedUntil__c 
                    FROM HelpReadingListEntry__c 
                    WHERE 
                        (HelpTopic__c IN :HTIDs OR ReadingListFeaturedUntil__c >= :dat.date())
                    AND 
                        (HelpReadingList__r.Active__c = true OR HelpReadingList__r.Active__c = :!isAuthor) 
                    ];

        } catch (exception e) {
            
        }
        
        return retVal;
    }
    

    // Get the Help Resources associated with a given Help Topic
    public HelpTopicResource__c[] getHelpTopicResourcesForHT(string HTID) {
        
        HelpTopicResource__c[] HTR = new HelpTopicResource__c[]{};
        
        try {
            HTR = [SELECT Id, HelpResource__c, UsageNotes__c,
                                                    HelpResource__r.Name, HelpResource__r.ResourceURL__c, HelpResource__r.ResourceType__c,
                                                    HelpResource__r.Preview__c, HelpResource__r.PreviewURL__c, 
                                                    HelpResource__r.Location__c, HelpResource__r.Summary__c
                        FROM HelpTopicResource__c 
                        WHERE HelpTopic__c = :HTID
                        ORDER BY HelpResource__r.Name];
            
        } catch (exception e) {
            
        }
        
        return HTR;
    }     

    
    // Get the Help Topic Relationships associated with a given Help Topic
    public HelpRelationship__c[] getHelpRelationshipsForHT(string HTID, Boolean ExclInactiveTopics) {
        
        HelpRelationship__c[] Rels = new HelpRelationship__c[]{};
        
        try {
            // Get the topic to which we're relating, if this has not already been obtained (as in LUX situations)
            HelpTopic__c HT;
            if (Hlp != null) {
                HT = Hlp;
            } else {
                HT = [SELECT ShowReferringRelationships__c FROM HelpTopic__c WHERE Id = :HTID];
            }
            
            if (ControllerSettings.getSettings().ShowReferringTopics__c == true || HT.ShowReferringRelationships__c == true) {
                Rels = [SELECT ReferringTopic__c, ReferringTopic__r.Name, ReferringTopic__r.Summary__c, ReferringTopic__r.CustomStyle__c, ReferringTopic__r.LastModifiedDate,
                    RelatedHelpTopic__c, RelatedHelpTopic__r.Name, RelatedHelpTopic__r.Summary__c, RelatedHelpTopic__r.CustomStyle__c, RelatedHelpTopic__r.LastModifiedDate, RelatedHelpTopic__r.ShowReadMoreLink__c,
                    SemanticTag__c, SemanticTag__r.Name, SemanticTag__r.Obverse__c,
Order__c                    
                                        FROM HelpRelationship__c 
                    WHERE (ReferringTopic__c = :HTID
                    OR RelatedHelpTopic__c = :HTID)
                    AND (ReferringTopic__r.Active__c = true OR ReferringTopic__r.Active__c = :ExclInactiveTopics)
                    AND (RelatedHelpTopic__r.Active__c = true OR RelatedHelpTopic__r.Active__c = :ExclInactiveTopics)];
                                                    
            } else {                                                
                Rels = [SELECT ReferringTopic__c, ReferringTopic__r.Name, ReferringTopic__r.Summary__c, ReferringTopic__r.CustomStyle__c, ReferringTopic__r.LastModifiedDate,
                    RelatedHelpTopic__c, RelatedHelpTopic__r.Name, RelatedHelpTopic__r.Summary__c, RelatedHelpTopic__r.CustomStyle__c, RelatedHelpTopic__r.LastModifiedDate, RelatedHelpTopic__r.ShowReadMoreLink__c,
                    SemanticTag__c, SemanticTag__r.Name, SemanticTag__r.Obverse__c,
Order__c                    
                                        FROM HelpRelationship__c 
                    WHERE ReferringTopic__c = :HTID
                    AND (ReferringTopic__r.Active__c = true OR ReferringTopic__r.Active__c = :ExclInactiveTopics)
                    AND (RelatedHelpTopic__r.Active__c = true OR RelatedHelpTopic__r.Active__c = :ExclInactiveTopics)];
    
            }
            
        } catch (exception e) {
        } 
        
        return Rels;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // For Helped Element editing
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    // Switch to New mode (Helped Element)
    public PageReference navHEToNewMode () {
        
        try {
            String H;
            
            // Permissions required - Author +
            Boolean[] UPs = Security.UserPermissions();
            Boolean bAuthor = UPs[1];
            Boolean bAdministrator = UPs[2];            
            
            if (bAuthor || bAdministrator) {
                
                // Use community path, if relevant, in Url returned below...
                String RootUrl = ControllerSettings.getCommunityRoot();
                if (RootUrl == '') {
                    RootUrl = URL.getOrgDomainURL().toExternalForm();
                }
                    
                // Create a new helped element, with values based on the current one
                HelpedElement__c newHE = new HelpedElement__c(); 
                newHE.Name = HE.Name + ' (' + mapGlbLocs.get('ValueGenericNew') + ')';
                newHE.Identifier__c = HE.Identifier__c;
                newHE.ElementType__c = HE.ElementType__c;
                newHE.HelpTopic__c = HE.HelpTopic__c;
                newHE.HelpedPageLayout__c = HE.HelpedPageLayout__c;
                newHE.DataDrivenFilter__c = HE.DataDrivenFilter__c;
                newHE.Visibility__c = HE.Visibility__c;
                    
                insert newHE;           
                    
                // Navigate to this new record          
                H = ServiceSecurity.getQueryParameter('HPL', 2);                
                return new PageReference(RootUrl + '/apex/iahelp__IHHelpedElement?ElemId=' + EncodingUtil.urlEncode(newHE.Identifier__c, 'UTF-8') + '&HPL=' + H + '&Mode=New&IHLUX=' + isIHLUX);
                
            } else {
                Diags = mapGlbLocs.get('MessageNoRights');
                return null;                                    
            }

                
        } catch (exception e) {
            Diags = mapGlbLocs.get('MessageGenericError') + ' (Nav HE To New Mode) - ' + e.getMessage();
            return null;                    
        }
        
    }


    // Switch to Edit mode (Helped Element)
    public PageReference navHEToEditMode () {           
        String ActiveHE = ServiceSecurity.getQueryParameter('ActiveId', 2);             
        String H = ServiceSecurity.getQueryParameter('HPL', 2);   
        
        // Use community path, if relevant
        String RootUrl = ControllerSettings.getCommunityRoot();
        if (RootUrl == '') {
            RootUrl = URL.getOrgDomainURL().toExternalForm();
        }
                      
        return new PageReference(RootUrl + '/apex/iahelp__IHHelpedElement?ElemId=' + EncodingUtil.urlEncode(HE.Identifier__c, 'UTF-8') + '&HPL=' + H + '&ActiveId=' + ActiveHE + '&Mode=Edit&IHLUX=' + isIHLUX);
    }
    
    
    // Save changes to a helped element (e.g., made via dialogue when in help reconfig mode)
    public PageReference saveHelpedElement() {
        
        Diags = '';

        try {
            //initialiseTopic();
            
            Boolean[] UPs = Security.UserPermissions();
            Boolean bAuthor = UPs[1];
            Boolean bAdministrator = UPs[2];            
                
            if (bAuthor || bAdministrator) {
                
                // If the current HE has it's "Use for New Records" box checked 
                // we must un-check all others for same element and visibility!
                if (HE.UseForNew__c == true) {
                    HelpedElement__c[] ufnHEs = 
                        [SELECT Id, UseForNew__c
                        FROM HelpedElement__c
                        WHERE HelpedPageLayout__c = :HE.HelpedPageLayout__c
                        AND Identifier__c = :HE.Identifier__c
                        AND Visibility__c = :HE.Visibility__c];
                        
                    for (HelpedElement__c H : ufnHEs) {
                        H.UseForNew__c = false;
                    }
                        
                    HE.UseForNew__c = true;
                    update ufnHEs;
                }
                
                update HE;
                Diags = mapGlbLocs.get('MessageSaved');
                
            } else {
                Diags = mapGlbLocs.get('MessageNoRights');
            }
        } catch (exception e) {
            Diags = mapGlbLocs.get('MessageGenericError') + ' - ' + e.getMessage();
        }
        

        String ActiveHE = ServiceSecurity.getQueryParameter('ActiveId', 2);
        String H = ServiceSecurity.getQueryParameter('HPL', 2);

        // Use community path, if relevant
        String RootUrl = ControllerSettings.getCommunityRoot();
        if (RootUrl == '') {
            RootUrl = URL.getOrgDomainURL().toExternalForm();
        }        
        return new PageReference(RootUrl + '/apex/iahelp__IHHelpedElement?ElemId=' + EncodingUtil.urlEncode(HE.Identifier__c, 'UTF-8') + '&HPL=' + H + '&ActiveID=' + ActiveHE + '&Mode=Read&IHLUX=' + isIHLUX + '&Diags=' + Diags);
    }


    // Cancel changes (Helped Element) and re-nav to unedited page
    public PageReference cancelHelpedElementChanges () {        
        try {
            String ActiveHE = ServiceSecurity.getQueryParameter('ActiveId', 2);
            String H = ServiceSecurity.getQueryParameter('HPL', 2);
            
            // Use community path, if relevant
            String RootUrl = ControllerSettings.getCommunityRoot();
            if (RootUrl == '') {
                RootUrl = URL.getOrgDomainURL().toExternalForm();
            }
            return new PageReference(RootUrl + '/apex/iahelp__IHHelpedElement?ElemId=' + EncodingUtil.urlEncode(HE.Identifier__c, 'UTF-8') + '&HPL=' + H + '&ActiveId=' + ActiveHE + '&Mode=Read&IHLUX=' + isIHLUX);
                
        } catch (exception e) {
            Diags = e.getMessage();
            return null;
        }
    }


    // Delete the current helped element
    public PageReference deleteHelpedElement () {

        String HEIdent;
        String H;
                
        try {           
            Boolean[] UPs = Security.UserPermissions();
            Boolean bAuthor = UPs[1];
            Boolean bAdministrator = UPs[2];
            
            HEIdent = HE.Identifier__c;
                
            // Deletion is subject to rights
            if (bAuthor || bAdministrator) {
                delete HE;
            } else {
                Diags = mapGlbLocs.get('MessageNoRights');
                return null;
            }
        } catch (exception e) {
            Diags = mapGlbLocs.get('MessageGenericError') + ' (Delete Helped Element) - ' + e.getMessage();
            return null;
        }

        // Having deleted, revisit the elements page but with no particular item active 
        H = ServiceSecurity.getQueryParameter('HPL', 2);
        
        // Use community path, if relevant
        String RootUrl = ControllerSettings.getCommunityRoot();
        if (RootUrl == '') {
            RootUrl = URL.getOrgDomainURL().toExternalForm();
        }
        return new PageReference(RootUrl + '/apex/iahelp__IHHelpedElement?ElemId=' + EncodingUtil.urlEncode(HEIdent, 'UTF-8') + '&HPL=' + H + '&Mode=Read&IHLUX=' + isIHLUX);
    }
 
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // For Help Topic editing
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    
    
    // Get a new (unsaved) Help Topic record with appropriate default values
    public HelpTopic__c getDefaultHelpTopic() {
        
        HelpTopic__c HT = new HelpTopic__c();           
        
        try {
                
            HelpTopicTemplate__c HTT;
            
            if (mapGlbLocs == null) {
                mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false);
            }
            
            HT.Name = mapGlbLocs.get('ValueNewTopicName');
            HT.Summary__c = mapGlbLocs.get('ValueNewTopicSummary');
                                
            HT.ImageHeight__c = 0;
            HT.ImageWidth__c = 0;
            HT.ImageCaption__c = '';
            HT.ImageTitle__c = '';
            HT.ImageALTText__c = '';
            
            HT.VideoHeight__c = 0;
            HT.VideoWidth__c = 0;
            HT.VideoCaption__c = '';
            HT.VideoTitle__c = '';          
            HT.ImageURL__c = '';
                
            HT.Template__c = ControllerSettings.getSettings().DefaultHelpTopicTemplate__c;
            HT.CalloutTemplate__c = ControllerSettings.getSettings().DefaultHelpCalloutTemplate__c;
            HT.LightningTemplate__c = null;
            HT.Active__c = ControllerSettings.getSettings().DefaultHelpActiveStatus__c;
            HT.ShowReadMoreLink__c = ControllerSettings.getSettings().DefaultReadMoreOption__c; 
            HT.Visibility__c = ControllerSettings.getSettings().DefaultVisibility__c;
            
            // With vote set, we need to handle 'null' / no vote set value
            if (ControllerSettings.getSettings().DefaultVoteSet__c != '--None--') {
                HT.HelpVoteSet__c = ControllerSettings.getSettings().DefaultVoteSet__c;
            } else {
                HT.HelpVoteSet__c = '';
            }
            
            
            HT.GuidedLayout__c = null;
            HT.GuidedRecord__c = '';
            HT.GuidedElement__c = null;
            HT.GuideStepMode__c = 'Automatic';
            HT.GuideCallout__c = false;
                
                
            // We need to look up default templates to set topic/callout heights
            try {
                HTT = [SELECT DefaultHeight__c FROM HelpTopicTemplate__c WHERE Id = :HT.Template__c];
                HT.HeightBeforeScrolling__c = HTT.DefaultHeight__c;
                
            } catch (exception f) {
                // On fail, default to "safe" value
                HT.HeightBeforeScrolling__c = 400;                  
            }
                    

            try {
                HTT = [SELECT DefaultHeight__c FROM HelpTopicTemplate__c WHERE Id = :HT.CalloutTemplate__c];
                HT.CalloutHeight__c = HTT.DefaultHeight__c;
                
            } catch (exception f) {
                // On fail, default to "safe" value
                HT.CalloutHeight__c = 55;                       
            }
                
        } catch (exception ex) {
                
        }
        
        return HT;
        
    }
    
    
    // Create a copy of an existing help topic record
    public HelpTopic__c clone(HelpTopic__c HT) {
        
        HelpTopic__c Hlp;
        
        try {
            Hlp = new HelpTopic__c();
                        
            Hlp.Name = HT.Name;
            Hlp.Summary__c = HT.Summary__c;
            
            // NOTE: Do NOT clone master topic identifier: 
            // Leave this blank as we don't want / cannot save a duplicate value...
            
            Hlp.SalesforceHelpURL__c = HT.SalesforceHelpURL__c;
            Hlp.CalloutTemplate__c = HT.CalloutTemplate__c;                                        
            Hlp.CalloutHeight__c = HT.CalloutHeight__c;
            Hlp.CalloutMediaChoice__c = HT.CalloutMediaChoice__c;
            Hlp.Template__c = HT.Template__c;
            Hlp.HeightBeforeScrolling__c = HT.HeightBeforeScrolling__c;
            Hlp.LightningTemplate__c = HT.LightningTemplate__c;

            Hlp.Active__c = HT.Active__c;
            Hlp.ShowReadMoreLink__c = HT.ShowReadMoreLink__c;
            Hlp.ShowReferringRelationships__c = HT.ShowReferringRelationships__c;                        
            Hlp.HelpTopicStatus__c = HT.HelpTopicStatus__c;
            Hlp.Visibility__c = HT.Visibility__c;
            Hlp.CustomStyle__c = HT.CustomStyle__c;
            Hlp.HelpVoteSet__c = HT.HelpVoteSet__c;

            Hlp.ImageHeight__c = HT.ImageHeight__c;
            Hlp.ImageWidth__c = HT.ImageWidth__c;           
            Hlp.ImageALTText__c = HT.ImageALTText__c;
            Hlp.ImageCaption__c = HT.ImageCaption__c;
            Hlp.ImageTitle__c = HT.ImageTitle__c;
            Hlp.ImageURL__c = HT.ImageURL__c;

            Hlp.VideoHeight__c = HT.VideoHeight__c;
            Hlp.VideoWidth__c = HT.VideoWidth__c;
            Hlp.VideoCaption__c = HT.VideoCaption__c;
            Hlp.VideoTitle__c = HT.VideoTitle__c;
            Hlp.VideoURL__c = HT.VideoURL__c;
            
            Hlp.GuideStepMode__c  = HT.GuideStepMode__c;
            Hlp.GuidedLayout__c = HT.GuidedLayout__c;
            Hlp.GuidedElement__c = HT.GuidedElement__c;
            Hlp.GuidedRecord__c = HT.GuidedRecord__c;
            Hlp.GuideCallout__c = HT.GuideCallout__c;

            Hlp.Description__c = HT.Description__c;
            
            // NOTE: no need to clone plain text description fields (DescriptionText1 - 5) as trigger will populate these on any save.
            // NOTE: we do NOT clone Keyword field - as this would lead to trigger fail (duplicate keyword in visibility context)
                        
        } catch (exception e) {
            Hlp = null;
        }
        
        return Hlp;
    }
    
    
    // Wrapper allowing cloning of multiple topics via clone tool on tools page
    public PageReference cloneTopic () {
        
        Diags = '';
        
        try {
            
            // Permissions required - Author +
            Boolean[] UPs = Security.UserPermissions();
            Boolean bAuthor = UPs[1];
            Boolean bAdministrator = UPs[2];            
            
            if (bAuthor || bAdministrator) {                
                integer i = 0;
                String[] CNames = CloneTopicNames.split('\\^');
                String[] CRels  = CloneTopicRels.split('\\^');                  
                HelpTopic__c[] HTs = new HelpTopic__c[]{};
                HelpTopic__c HTClone;
                HelpRelationship__c[] Rels = new HelpRelationship__c[]{};
                HelpRelationship__c Rel;                        

                for(String tN : CNames) {
                    if (tN != '') {
                        HTClone = clone(Hlp);
                        HTClone.Name = tN;
                        HTs.add(HTClone);                                       
                    }
                }
                insert HTs;
                            
                for(String tR : CRels) {
                    if (tR != '') {                                 
                        // Add related topics if required
                        if (tR.toUpperCase() == 'Y') {
                            for (ServiceIHLists.RelatedHelpListItem R : Relations) {
                                Rel = new HelpRelationship__c();
                                                            
                                if (R.HR.ReferringTopic__c == Hlp.Id) {
                                    Rel.ReferringTopic__c = HTs[i].Id;
                                    Rel.RelatedHelpTopic__c = R.HR.RelatedHelpTopic__c;
                                } else {
                                    Rel.ReferringTopic__c = R.HR.ReferringTopic__c;
                                    Rel.RelatedHelpTopic__c = HTs[i].Id;
                                }
                                
                                Rel.SemanticTag__c = R.HR.SemanticTag__c;
                                
                                Rels.add(Rel);
                            }
                        }
                    }
                    i += 1;
                }
                
                insert Rels;    
                Diags = mapGlbLocs.get('MessageGenericTaskComplete')  + ' - ' + HTs.size() + ' ' + mapGlbLocs.get('MessageGenericNewRecords') + ' (Topics) + ' + Rels.size() + ' ' + mapGlbLocs.get('MessageGenericNewRecords') + ' (Related Help Topic)';
                
            } else {
                Diags = mapGlbLocs.get('MessageNoRights');
            }           
                                        
        } catch (exception e) {
            Diags = mapGlbLocs.get('MessageGenericError') + ' (Clone Topic) - ' + e.getMessage();
        }

        CloneTopicNames = '';
        CloneTopicRels = '';
                
        return null;
    }
        
    
    // Save changes made to a help topic (e.g., thru editing panel)
    public PageReference saveHelp () {
            
        String retVal = '';
        datetime dt = datetime.now();
        
        try {
            Boolean[] UPs = Security.UserPermissions();
            Boolean bAuthor = UPs[1];
            Boolean bAdministrator = UPs[2];            
            
            if (bAuthor || bAdministrator) {
                
                // Check that choice of callout media "makes sense":
                // If selected option is blank (because the relevant media fields have not been completed)
                // use the other media (if available)
                                
                if(Hlp.CalloutMediaChoice__c == 'Image') {
                    // If image is blank and a video is available, use video
                    if ((Hlp.ImageURL__c == '' || Hlp.ImageURL__c == null) && (Hlp.VideoURL__c != '' && Hlp.VideoURL__c != null)) {
                        Hlp.CalloutMediaChoice__c = 'Video';
                        retVal = mapDlgLocs.get('MessageCalloutMediaSetToVideo') + ' - ';
                    }
                        
                } else {
                    // If video is blank and an image is available, use image
                    if ((Hlp.VideoURL__c == '' || Hlp.VideoURL__c == null) && (Hlp.ImageURL__c != '' && Hlp.ImageURL__c != null)) {
                        Hlp.CalloutMediaChoice__c = 'Image';
                        retVal = mapDlgLocs.get('MessageCalloutMediaSetToImage') + ' - ';
                    }                        
                }
                
                
                // Also, append special parameter to videos to make sure they don't "bleed through" callouts
                if (Hlp.VideoURL__c != '' && Hlp.VideoURL__c != null) {
                        
                    if (Hlp.VideoURL__c.indexOf('wmode=') == -1) {
                            
                        // Need to add the parameter: check for existing parameters...
                        if (Hlp.VideoURL__c.indexOf('?') == -1) {
                            Hlp.VideoURL__c += '?wmode=opaque';
                        } else {
                            Hlp.VideoURL__c += '&wmode=opaque';                                         
                        }
                    }
                }
                
                upsert Hlp;
                
                // Refresh help here (for modified date etc)
                getHelp();
                
                retVal += mapGlbLocs.get('MessageSaved');

            } else {
                retVal = mapGlbLocs.get('MessageNoRights');
            }
                        
        } catch (exception e) {
            retVal = mapGlbLocs.get('MessageGenericError') + ' - ' + e.getMessage();
        }

        Diags = retVal;
        return null;
        
    }


    // Cancel changes (Help Topic) and re-nav to unedited page
    public PageReference cancelHelpChanges () {
        
        // Use community path, if relevant, in Urls returned below...
        String RootUrl = ControllerSettings.getCommunityRoot();
        if (RootUrl == '') {
            RootUrl = URL.getOrgDomainURL().toExternalForm();
        }
        
        // Return address varies depending on whether this is called from a full tools/portal
        // page or via the editing controls page (in guide window)
        if (URL.getCurrentRequestUrl().getFile().startsWith('/apex/' + NameSpace + '__' + PortalPage)) {
            return new PageReference(RootUrl + '/apex/' + NameSpace + '__' + PortalPage + '?HTID=' + Hlp.Id);
        } else {
            return new PageReference(RootUrl + '/apex/' + NameSpace + '__' + 'IHRedirector?HTID=' + Hlp.Id);
        }       
    }


    // For drop down list of Lightning 'templates' - not supported in classic, so no VF select option interface
    public List<HelpTopicTemplate__c> getTemplateRecordsL () {
        List<HelpTopicTemplate__c> HTTs = new List<HelpTopicTemplate__c>();
        try {
            HTTs = [SELECT Id, Name, TemplateType__c, DefaultHeight__c 
                FROM HelpTopicTemplate__c 
                WHERE TemplateType__c = 'Lightning Viewer'
                ORDER BY Name
                ];
        } catch (exception e){}
        
        return HTTs;
    }

        
    // For drop down list of full topic templates
    public List<HelpTopicTemplate__c> getTemplateRecordsF () {
        List<HelpTopicTemplate__c> HTTs = new List<HelpTopicTemplate__c>();
        try {
            HTTs = [SELECT Id, Name, TemplateType__c, DefaultHeight__c, PageURL__c 
                FROM HelpTopicTemplate__c 
                WHERE TemplateType__c = 'Full Topic'
                ORDER BY Name
                ];
        } catch (exception e){}
        
        return HTTs;
    }
    public List<selectOption> getTemplatesF () {
        List<SelectOption> options = new List<SelectOption>();

        try {
            List<HelpTopicTemplate__c> HTTs = getTemplateRecordsF();
            for (HelpTopicTemplate__c Temp : HTTs) {
                options.add(new SelectOption(Temp.Id, Temp.Name));
            }
        } catch (exception e) {                
        }
                        
        return options;
    }


    // For dropdown list of callout topic templates
    public List<HelpTopicTemplate__c> getTemplateRecordsC () {
        List<HelpTopicTemplate__c> HTTs = new List<HelpTopicTemplate__c>();
        try {
            HTTs = [SELECT Id, Name, TemplateType__c, DefaultHeight__c
                FROM HelpTopicTemplate__c 
                WHERE TemplateType__c = 'Callout'
                ORDER BY Name
                ];
        } catch (exception e){}
        
        return HTTs;
    }
    public List<selectOption> getTemplatesC () {
        List<SelectOption> options = new List<SelectOption>();

        try {
            List<HelpTopicTemplate__c> HTTs = getTemplateRecordsC();
            for (HelpTopicTemplate__c Temp : HTTs) {
                options.add(new SelectOption(Temp.Id, Temp.Name));
            }
        } catch (exception e) {                
        }
                        
        return options;
    }


    // For dropdown list of customer (global settings) defined Help Topic styles
    public List<selectOption> getCustomStyles () {
        List<SelectOption> options = new List<SelectOption>();

        try {
            // Always add a "no style" option
            options.add(new SelectOption('', '--' + mapGlbLocs.get('ValueNone') + '--'));
            
            String Stg = ControllerSettings.getSettings().CustomStyles__c;
            Stg = Stg.replace(' ', '');
            if (Stg != '') {
                String[] Stgs = Stg.split(',');
                for (String S: Stgs) {
                    options.add(new SelectOption(S, S));
                }                       
            }
                                
        } catch (exception e) {                
        }
                        
        return options;
    }


    // Amend callout height to reflect selected callout template
    public void calloutTemplateChange () {
                
        // Set callout height according to selected template
        try {
            HelpTopicTemplate__c HT = [SELECT DefaultHeight__c
                    FROM HelpTopicTemplate__c
                    WHERE Id = :Hlp.CalloutTemplate__c];
            
            Hlp.CalloutHeight__c = HT.DefaultHeight__c;
                
        } catch (exception e) {
            // No further action possible in this case
            Diags = mapGlbLocs.get('MessageGenericError') + ' (Callout Template Change) - ' + e.getMessage();
        }
        
        // Re-set to edit mode / editor visible (i.e., not Hidden)
        // To do this, note the fact that callout template has changed:
        // This class has no visual impact but can be picked up in tools page initialise 
        // and used to toggle editing buttons to disabled.
        TEditorClass = 'CALLOUTCHANGE';
        
        return;
    }


    // For blanking video details in a single click
    public void resetTopicVideo() {
            
        try {
            Hlp.VideoHeight__c = 0;
            Hlp.VideoWidth__c = 0;
            Hlp.VideoCaption__c = '';
            Hlp.VideoTitle__c = '';         
            Hlp.VideoURL__c = '';
                    
        } catch (exception e) {                
        }
        return;
    }


    // For blanking image details in a single click
    public void resetTopicImage() {
            
        try {
            Hlp.ImageHeight__c = 0;
            Hlp.ImageWidth__c = 0;
            Hlp.ImageCaption__c = '';
            Hlp.ImageTitle__c = '';
            Hlp.ImageURL__c = '';
            Hlp.ImageALTText__c = '';
                                    
        } catch (exception e) {
        }
        return;
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // For Guide Step editing
    /////////////////////////////////////////////////////////////////////////////////////////////////////
        
    //
    public PageReference GSAddLocalStep() {
                
        HelpReadingListEntry__c[] RLEs;
        HelpReadingListEntry__c RLE;
        HelpTopic__c HT;
                
        try {                        
            Diags = 'Inserting to Guide: ' + ReadingListId + '... ';
                        
            // Check rights
            Boolean[] UPs = Security.UserPermissions();
            Boolean bAuthor = UPs[1];
            
            if (!bAuthor) {
                Diags = mapGlbLocs.get('MessageNoRights');
                return null;
                    
            } else {
                // Retrieve steps currently in the Guide
                RLEs = [SELECT Id FROM HelpReadingListEntry__c WHERE HelpReadingList__c = :ReadingListId];
                                
                // Create a local guide step and related topic for the Guide (RL) being viewed
                HT = getDefaultHelpTopic();
                HT.Name = mapDlgLocs.get('ValueGSNewLocalStepName');
                HT.Summary__c = mapDlgLocs.get('ValueGSNewLocalStepSummary');


                HT.GuideStepMode__c = 'Local';
                insert HT;
                                
                RLE = new HelpReadingListEntry__c();
                RLE.HelpReadingList__c = ReadingListId;
                RLE.HelpTopic__c = HT.Id;
                RLE.ReadingOrder__c = RLEs.size();
                
                insert RLE;
                
                Diags = mapGlbLocs.get('MessageGenericTaskComplete');
                
                return new PageReference(URL.getCurrentRequestUrl().toExternalForm() + '?Opts=Guide&RLID=' + ReadingListId + '&HTID=' + HT.Id);
                                
            }
        } catch (exception e) {
            Diags += mapGlbLocs.get('MessageGenericError') + ' (GS Add Local Step) - ' + e.getMessage();
            return null;
        }               
    }
        
        
    //
    public PageReference GSAddSelectStep() {

        HelpReadingListEntry__c[] RLEs;
        HelpReadingListEntry__c RLE;
        HelpTopic__c HT;
                
        try {
            Diags = '';
                        
            // Check rights
            Boolean[] UPs = Security.UserPermissions();
            Boolean bAuthor = UPs[1];
            
            if (!bAuthor) {
                Diags = mapGlbLocs.get('MessageNoRights');
                return null;
                                
            } else {
                // Retrieve steps currently in the Guide
                RLEs = [SELECT Id FROM HelpReadingListEntry__c WHERE HelpReadingList__c = :ReadingListId];
                                
                // Create a local guide step and related topic for the Guide (RL) being viewed
                HT = getDefaultHelpTopic();

                HT.Name = mapDlgLocs.get('ValueGSNewRecordSelectionStepName');
                HT.Summary__c = mapDlgLocs.get('ValueGSNewRecordSelectionStepSummary');
                HT.GuideStepMode__c = 'Automatic';
                insert HT;
                
                RLE = new HelpReadingListEntry__c();
                RLE.HelpReadingList__c = ReadingListId;
                RLE.HelpTopic__c = HT.Id;
                RLE.ReadingOrder__c = RLEs.size();
                
                insert RLE;
                
                Diags = mapGlbLocs.get('MessageGenericTaskComplete');                 
                return new PageReference(URL.getCurrentRequestUrl().toExternalForm() + '?Opts=Guide&RLID=' + ReadingListId + '&HTID=' + HT.Id);
                                
            }
                        
        } catch (exception e) {
            Diags = mapGlbLocs.get('MessageGenericError') + ' (GS Add Select Step) - ' + e.getMessage();
            return null;
        }               
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Tools page toolbar support functions
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    
    // Add and navigate to a new help topic
    public PageReference addHelpTopic () {
        
        try {
                
            // Adding a topic is subject to rights
            Boolean[] UPs = Security.UserPermissions();
            Boolean bAuthor = UPs[1];
            Boolean bAdministrator = UPs[2];
            
            if (bAuthor || bAdministrator) {
                HelpTopic__c HT = getDefaultHelpTopic();
                insert HT;

                // NB: having added the topic, we're essentially in EDIT mode on new record...
                // Use community path, if relevant
                String RootUrl = ControllerSettings.getCommunityRoot();
                if (RootUrl == '') {
                    RootUrl = URL.getOrgDomainURL().toExternalForm();
                }            
                return new PageReference(RootUrl + '/apex/iahelp__' + PortalPage + '?HTID=' + HT.Id + '&Mode=Edit');
                        
            } else {
                Diags = mapGlbLocs.get('MessageNoRights');
                return null;
            }
                                                                                
        } catch (exception e) {
            Diags = mapGlbLocs.get('MessageGenericError') + ' (Add Help Topic) - ' + e.getMessage();
            return null;
        }        
    }
    
    
    // Delete the current help topic
    public PageReference deleteHelpTopic () {

        try {
            // Deletion is subject to rights
            Boolean[] UPs = Security.UserPermissions();
            Boolean bAuthor = UPs[1];
            Boolean bAdministrator = UPs[2];
            
            if (bAuthor || bAdministrator) {
                delete Hlp;
            } else {
                Diags = mapGlbLocs.get('MessageNoRights');
                return null;
            }
 
               
            // Having deleted the help topic, navigate to the help page on the "default" topic,
            // or, if this is not available, to new "empty" topic
            HelpTopic__c HT;
                
            try {
                String defId = ControllerSettings.getSettings().DefaultHelpTopic__c;
                HT = [SELECT Id FROM HelpTopic__c WHERE Id=:defId];
                        
            } catch (exception e) {
                // If there are no help topics, create 1, save it and go there...
                HT = getDefaultHelpTopic();
                insert HT;
            }
                
            // Use community path, if relevant
            String RootUrl = ControllerSettings.getCommunityRoot();
            if (RootUrl == '') {
                RootUrl = URL.getOrgDomainURL().toExternalForm();
            }
            return new PageReference(RootUrl + '/apex/iahelp__' + PortalPage + '?HTID=' + HT.Id);
                
        } catch (exception e) {
            Diags = mapGlbLocs.get('MessageGenericError') + ' (Delete Help Topic) - ' + e.getMessage();
            return null;
        }
    }
    
    
    // Add a bookmark to the current page:
    // NB: as we must always store a bookmark URL and the bookmarked topic could be viewed via
    // SF classic or SF1 (i.e., may or may not be IH1UX, LUX etc.), the page NAME we store is irrelevant, as
    // the VF page used will depend on viewer's current UX. So, here we stick with storing 
    // the "current" portal page as the name...
    public void addBookmark () {
        
        try {
            // We must be at least a helped user to do this
            if (Security == null) {Security = new ServiceSecurity();}           
            if (Security.UserPermissions()[0] == false) {
                Diags = mapGlbLocs.get('MessageNoRights');
                return;
            }

            HelpBookmark__c HB = new HelpBookmark__c();
            
            String PortalPage = ControllerSettings.getPortalPageName(isIH1UX);
            
            if (Hlp == null) {
                HB.HelpTopic__c = null;
                HB.TopicURL__c = 'iahelp__' + PortalPage + '?HTID=';
            } else {
                HB.HelpTopic__c =  Hlp.Id; 
                
                // Use community path, if relevant
                String RootUrl = ControllerSettings.getCommunityRoot();
                if (RootUrl == '') {
                    RootUrl = URL.getOrgDomainURL().toExternalForm();
                }                                     
                HB.TopicURL__c = RootUrl + '/apex/iahelp__' + PortalPage + '?HTID=' + Hlp.Id;
            }

            insert HB;

            // When we manipulate bookmarks, we need to re-set the list known to this page
            initialiseBookmarks(null, null);
                                        
        } catch (exception e) {
        }     
        return;
    }
    
    
    // Add a bookmark that redirects to a specific guide step (shown in guide window).
    // We use a re-direct for this, as we want the link to open in a new guide window
    // and cannot do this directly via a bookmark listing link
    public void addGuideBookmark () {
                
        try {
            // We must be at least a helped user to do this
            if (Security == null) {Security = new ServiceSecurity();}           
            if (Security.UserPermissions()[0] == false) {
                Diags = mapGlbLocs.get('MessageNoRights');
                return;
            }

            String GotoURL = '';
            HelpBookmark__c HB = new HelpBookmark__c();
            
            // Use community path, if relevant, in Urls produced below...
            String RootUrl = ControllerSettings.getCommunityRoot();
            if (RootUrl == '') {
                RootUrl = URL.getOrgDomainURL().toExternalForm();
            }
            
                
            // In bookmarking a Guide, we only ever want to go to the 1st step:
            HelpReadingListEntry__c RLE = [SELECT HelpTopic__c 
                                            FROM HelpReadingListEntry__c 
                                            WHERE HelpReadingList__c = :ReadingListId
                                            AND ReadingOrder__c = 0];
            HB.HelpTopic__c =  RLE.HelpTopic__c;                      

            GotoURL = RootUrl + '/apex/iahelp__IHReadingListViewer?Opts=Guide';         
            GotoURL += '&RLID=' + ReadingListId;
            GotoURL += '&HTID=' + HB.HelpTopic__c;       
            GotoURL += '&IHContext=null';       
            GotoURL = EncodingUtil.urlEncode(GotoURL, 'UTF-8');
                
            HB.TopicURL__c = RootUrl + '/apex/iahelp__IHWrapper?GoToRL=' + GotoURL;
            
            // Get the name of the Guide (Reading List) being bookmarked
            HelpReadingList__c RL = [Select Id, Name FROM HelpReadingList__c WHERE Id=:ReadingListId];
            HB.HelpBookmarkLabel__c = RL.Name;
        
            insert HB;
          
            // When we manipulate bookmarks, we need to re-set the list known to this page
            initialiseBookmarks(null, null);
                                        
        } catch (exception e) {
            //Diags = e.getMessage();
        }     
        
        return;
    }


    // Remove bookmark from the current page
    public void removeBookmark () {
        try {
            
            // We must be at least a helped user to do this
            if (Security == null) {Security = new ServiceSecurity();}           
            if (Security.UserPermissions()[0] == false) {
                Diags = mapGlbLocs.get('MessageNoRights');
                return;
            }
            
            String UID = UserInfo.getUserId();
            HelpBookmark__c[] HBs = [SELECT Id FROM HelpBookmark__c WHERE HelpTopic__c = :THelpId AND OwnerId = :UID];
            delete HBs;

        } catch (exception e) {
            Diags = 'removeBookmark Error: ' + e.getMessage();          
        }

        // When we manipulate bookmarks, we need to re-set the list known to this page
        initialiseBookmarks(null, null);
        return;
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Utility / security wrapper functions
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    // Check whether the IH subscription is valid and user is allocated a license if required. Redirect to service unavailable if not
    public PageReference checkSubscriptionStatus () {
                
        // Initialise additional status information
        LicenseIssue = '';
                
        // Use community path, if relevant, in Urls returned below...
        String RootUrl = ControllerSettings.getCommunityRoot();
        if (RootUrl == '') {
            RootUrl = URL.getOrgDomainURL().toExternalForm();
        }
        
                
        // Unless Subscription is for unlimited seats, user must have been allocated to a subscription
        if (ServiceSubs.getLicenseInfo('Improved Help Documents', null).NumSeats != 'Unlimited' && isSeated == false) {         
            return new PageReference(RootUrl + '/apex/iahelp__IHServiceUnavailable');                   
        }
        
        
        // Do nothing further here if we don't have the required Subscription
        if (ServiceSubs.getLicenseInfo('Improved Help Documents', null).StatusCode != ServiceSubs.KnownLicenseStatusCodes.OK) {
                
            // The one condition we  tolerate is over subscription - but NOT for free edition:
            // In these cases, continue - but mark output accordingly
            if (ServiceSubs.getLicenseInfo('Improved Help Documents', null).StatusCode == ServiceSubs.KnownLicenseStatusCodes.InsufficientUsers && ServiceSubs.getLicenseInfo('Improved Help Documents', null).LicenseType != 'Free') {
                LicenseIssue = mapGlbLocs.get('MessageInsufficientSubscriptions');
            } else {
                        
                // In all other cases of Subscription issues, fail:
                Diags = mapGlbLocs.get('MessageServiceUnavailableSubscription');

                TName = Diags;
                TSummary = TName;
                        
                // Set all key tools icons to blanks where possible
                TMyBookmarksLink = '';
                TBookmarkTool = '';
                TSFEditingLinks = '';
                TEditModeLink = '';
                TAddHelpTopicLink = '';
                TDeleteHelpTopicLink = '';
                TAddToReadingListLink = '';
                TInteractionsLink = '';
                TViewElementsLink = '';
                TSFHelpLink = '';
                TAddReadingListLink = '';
                        
                MessageClass = 'IHError';
                return new PageReference(RootUrl + '/apex/iahelp__IHServiceUnavailable');                   
            }
        }        
        
        // If we get here (even if there are insufficient subs) we can continue / return a null reference
        return null;            
    }


    // Check whether Help services (remain) unavailable: if available, redirect to Tools page
    public PageReference checkServiceUnavailable() {
        
        try {
                        
            // Setup our member data (required for knowledge of portal page)
            if (initialiseTopic() == false) {
                return null;                    
            }
                        
            ServiceSecurity Security = new ServiceSecurity();
                        
            // Remain unavailable if we've no seat and require one 
            if (ServiceSubs.getLicenseInfo('Improved Help Documents', null).NumSeats != 'Unlimited' && Security.IsSeated() == false
             || (ServiceSubs.getLicenseInfo('Improved Help Documents', null).StatusCode == ServiceSubs.KnownLicenseStatusCodes.InsufficientUsers 
                            && ServiceSubs.getLicenseInfo('Improved Help Documents', null).LicenseType == 'Free')) {
                return null;                    
            }
                        
            // The only other issue we'll tolerate with this is oversubscription:
            // (and NOT if we're free edition - which is thrown out above)
            if (ServiceSubs.getLicenseInfo('Improved Help Documents', null).StatusCode == ServiceSubs.KnownLicenseStatusCodes.OK 
             || ServiceSubs.getLicenseInfo('Improved Help Documents', null).StatusCode == ServiceSubs.KnownLicenseStatusCodes.InsufficientUsers) {
                // If the Subscription is OK, try a redirect to tools page                
                // Use community path, if relevant
                String RootUrl = ControllerSettings.getCommunityRoot();
                if (RootUrl == '') {
                    RootUrl = URL.getOrgDomainURL().toExternalForm();
                }
                return new System.Pagereference(RootUrl + '/apex/iahelp__' + PortalPage);
            }               
                        
        } catch (Exception e) {
        }

        // In error situations or continued Subscription unavailability, stay put...             
        return null;                    
    }
    
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // For presenting vote options and logging related interactions
    /////////////////////////////////////////////////////////////////////////////////////////////////////    
    
    // Obtain the list of available vote options (if any) allowed FOR THE CURRENT TOPIC AND ITS VOTE SET AS SAVED
    public void initialiseVoteOptions() {
        
        try {
            // Required for certain messages
            initialiseLocalisations();
                        
            // Make any vote options available for selection
            VoteOptions = [SELECT Id, HelpVoteSet__c, Name, OptionLabel__c, ImageClass__c, DisplayOrder__c
                            FROM HelpVoteOption__c
                            WHERE HelpVoteSet__c = :Hlp.HelpVoteSet__c
                            ORDER BY DisplayOrder__c];
                            
            // Take note of any vote already cast
            try {
                HelpInteraction__c HI = [SELECT Id, Description__c, HelpVoteOption__c, CreatedDate 
                                        FROM HelpInteraction__c 
                                        WHERE HelpInteractionType__c = 'Vote'
                                        AND CreatedById = :UserInfo.getUserId()
                                        AND HelpTopic__c = :Hlp.Id
                                        ORDER BY CreatedDate DESC
                                        LIMIT 1];
                
                
                // 1.38: no text desired here
                //Diags =  mapGlbLocs.get('AdviceLabelLastVotedOn') + ' ' + HI.CreatedDate;
                Diags = '';
                
                theVote = HI.HelpVoteOption__c;
                
            } catch (exception ex) {
                // 1.38: no text desired here
                //Diags = mapGlbLocs.get('TipVote');
                Diags = '';
            }
             
        } catch (exception e) {
            
        }

        return;
    }
    

// Obtain the list of available vote options (if any) allowed FOR A SPECIFIED TOPIC ASSUMING A SEPCIFIED VOTE SET
public void setupVoteInfoForTopic(string HTID, string HVSID) {
        
        try {
            // Required for certain messages
            initialiseLocalisations();
                        
            // Make any vote options available for selection
            VoteOptions = [SELECT Id, HelpVoteSet__c, Name, OptionLabel__c, ImageClass__c, DisplayOrder__c
                            FROM HelpVoteOption__c
                            WHERE HelpVoteSet__c = :HVSID
                            ORDER BY DisplayOrder__c];
                            
            // Take note of any vote already cast
            try {
                HelpInteraction__c HI = [SELECT Id, Description__c, HelpVoteOption__c, CreatedDate 
                                        FROM HelpInteraction__c 
                                        WHERE HelpInteractionType__c = 'Vote'
                                        AND CreatedById = :UserInfo.getUserId()
                                        AND HelpTopic__c = :HTID
                                        ORDER BY CreatedDate DESC
                                        LIMIT 1];
                
                Diags = '';
                
                theVote = HI.HelpVoteOption__c;
                
            } catch (exception ex) {
                // 1.38: no text desired here
                //Diags = mapGlbLocs.get('TipVote');
                Diags = '';
            }
             
        } catch (exception e) {
            
        }

        return;
    }
    
    
    // Log a "vote" type interaction
    public void castVote() {
        
        String interactionDesc;
        
        try {
            HelpVoteOption__c VO = [SELECT Id, HelpVoteSet__c, Name, OptionLabel__c, ImageClass__c, ImagePreview__c, DisplayOrder__c
                            FROM HelpVoteOption__c
                            WHERE Id = :theVote];
            
            Diags = '';

 
             // Take note of whether it was a guide that ocassioned this viewing:
            String AsGuide = ServiceSecurity.getQueryParameter('AsGuide', 2);
            if (AsGuide == '') {AsGuide = null;}
 
                                    
            // Log a new vote transaction: note, we may or may not have a Helped Element...
            ServiceInteractions sI = new ServiceInteractions();
            
            // Prefer option label for interaction description, but use name if none specified...
            if (VO.OptionLabel__c == '' || VO.OptionLabel__c == null) {
                interactionDesc = VO.Name;
            } else {
                interactionDesc = VO.OptionLabel__c;
            }
            
            if (HE != null) {
                sI.logInteraction(8, interactionDesc, getIHContext(), HE.HelpedPageLayout__c, HE.Id, Hlp.Id, AsGuide, VO.Id);
            } else {
                sI.logInteraction(8, interactionDesc, getIHContext(), null, null, Hlp.Id, AsGuide, VO.Id);
            }
            
                
        } catch (exception e) {
            Diags = e.getMessage(); 
        }
        return;
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // For upload of images to Help Topics
    /////////////////////////////////////////////////////////////////////////////////////////////////////    
    
    public Blob imgFile {get; set;}
    public string imgUrl {get; set;}
    public string imgType {get;set;}
    public string imgName {get;set;}
    
    public void uploadImg () {

        transient Document d;
        string dName;
        string fldId;
        string uploadFolder;
        
        
        // Check rights
        Boolean[] UPs = Security.UserPermissions();
        Boolean bAuthor = UPs[1];
        
        // NB: this is an unusual case where extra rights on top of those in 
        // help permission sets are required by virtue of (rare) direct manipulation
        // of a non-help object (documents)
        if (!bAuthor || ! Schema.SObjectType.Document.isDeletable() || ! Schema.SObjectType.Document.isCreateable()) {
            Diags = mapGlbLocs.get('MessageNoRights'); 
                                                   
         } else {
            // Help topic is required...
            if (Hlp != null) {
                dname = 'Help Image: ' + Hlp.Id;
                    
                // Locate image upload folder
                try {
                    uploadFolder = ControllerSettings.getSettings().ImageUploadFolder__c;
                    Folder fld = [SELECT Id from Folder WHERE Id =:uploadFolder];
                    fldId = fld.Id;
        
                    // Delete existing image (document) associated with current topic
                    try {                    
                        d = [SELECT Id FROM Document WHERE Name = :dName AND FolderId = :fldId];
                        delete d;  
                    } catch (exception ex) {
                        // Not necessarily an issue - may not have been an image file...
                    }
                            
                    // Create a record for the uploaded image file
                    try {
                        d = new Document();
                        d.Name = dName;
                        d.Body = imgFile; 
                        d.FolderId = fldId; 
                        d.Description = imgName;
                        d.Type = imgType;
                        insert d;
                                
                        // Update the current Topic to include the newly uploaded image's URL
                        imgUrl = '/servlet/servlet.FileDownload?file=' + d.id;
                        Hlp.ImageURL__c = imgUrl;
                        if (Hlp.ImageWidth__c == 0) Hlp.ImageWidth__c = 160;
                        if (Hlp.ImageHeight__c == 0) Hlp.ImageHeight__c = 100;
                        upsert Hlp;
                
                        Diags = 'Done';                   
                    } catch (exception exc) {
                        Diags = mapGlbLocs.get('MessageGenericError') + ' (Upload Image / document creation) ' + exc;
                    }
                            
                        
                } catch (exception e) {
                    Diags = mapGlbLocs.get('MessageErrorNoImageFolder');
                }
                    
            } else {
                Diags = mapGlbLocs.get('MessageGenericError') + ' (Upload Image/No Topic)';         
            }
        
        
            imgFile = null;
            d = null;
            
        }   // End if - user has rights
    }
    
    //method for testing Keyword Enhancement  -to be deleted
    @AuraEnabled(cacheable=true)
    public static List<HelpTopic__c> returnReqData(List<String> lstData){
        
        Set<String> setHTId = new Set<String>();
        for (String strId : lstData)
        {
            String varId = strId.replace(' ','');
            setHTId.add(varId);
        }
        system.debug(setHTId);
 
            List<HelpTopic__c> lstHT = [SELECT Id,Name,Summary__c 
                                        FROM HelpTopic__c 
                                        WHERE Id IN: setHTId];
            system.debug('lstHT'+lstHT+'size'+lstHT.size());
            
        return lstHT;
    }
    
       
}