/////////////////////////////////////////////////////////////////////////////////////////////////////
// CONTROLLER CLASS FOR THE IHQAMSettings PAGE, WHICH IS DESIGNED TO PROVIDE DETAILS OF 
// KEY IH SETTINGS CLIENT SIDE VIA A CALLBACK FUNCTION (I.E., WITHOUT THE NEED FOR 
// WEB SERVICE OR OTHER API CALLS). 
//
// ALSO PROVIDES SUPPORT FOR VF VERSIONS OF THE QAM (standard and IH1UX).
//
// Martin Little for Improved Apps
// October 2012
/////////////////////////////////////////////////////////////////////////////////////////////////////

global with sharing class ControllerIHQAMSettings {
                    
    // Diagnostics messages to end users
    public String Diags {get; set;}
        
    // For the VF QAM, the set of helped elements on the current page
    public SearchResultQAM[] HelpedElements {get; set;}


    // Global settings info
    public static IASetIHOrg__c getSettings() {return ControllerSettings.getSettings();}
    public static String getBrandCSS() {if (ControllerSettings.getSettings() != null) {return ControllerSettings.getSettings().BrandCSS__c;} else {return '';}}

    // True if parameter passed to indicate viewing via the Lightning UX
    // cf ControllerHelpContent.isIHLUX and ControllerIHQAMSettings.isIHLUX - as these have their own variant logic
    // cf jsQAMenu.SetupQAM which effectively apes this logic for use in the script-embedded QAM
    public static Boolean getisIHLUX() {
        try {
            if (ControllerSettings.getSettings().BrandUXOption__c == '3') {
                return true;
            } else {
                return false;
            }           
        } catch (exception e) {
            return false;
        }
    }                             

    // The settings string that is made available to client applications 
    // (by inclusion on a vf page in plain text form - see IHQAMSettings page)
    public string Settings {get; set;}
    

    // For UI localisations /multi language support (labels, messages etc)
    private map<string, string>mapDlgLocs;
    private map<string, string>mapGlbLocs;
    private map<string, string>mapBrdLocs;
    private map<string, string>mapQAMLocs;
    public map<string, string> getDialogueLocalisations() {
        return mapDlgLocs;
    }
    public map<string, string> getGlobalLocalisations() {
        return mapGlbLocs;
    }
    public map<string, string> getBrandingLocalisations() {
        return mapBrdLocs;
    }
    public map<string, string> getQAMLocalisations() {
        return mapQAMLocs;
    }


    // For the VF QAM, split certain elements of this out:
    public string BrandIHTooltip {get; set;}                // The global settings specified help tool tip
    public String HPLID {get; set;}                         // ID of helped page layout to which QAM has been related
    public String HPLName {get; set;}                       // Name of this layout
    public Boolean AllowComments {get; set;}                // Comments allowed on this layout?
    public Boolean GuidesExist {get; set;}                  // Guides exist for this layout?
    public Boolean DefaultHTSet {get; set;}                 // Default help topic (home page) set?
    public String SFURL {get; set;}                         // SF Root address
    public String SFObjId {get; set;}                       // Featured SF object       
    public String SFObjPluralName {get;set;}                // Featured SF object's name (plural form)
        
    // Helped Elements that fail DDF criteria in current context (set via calls to ControllerSettings.getHelpedElementRecords)
    public HelpedElement__c[] failedHEs;

    // Provide knowledge of permissions to clients
    public Boolean isUser {get; set;}
    public Boolean isAnalyst {get; set;}
    public Boolean isAuthor {get; set;}
    public Boolean isAdministrator {get; set;}
        
    // Defines whether we're viewing via an SF console component
    public Boolean isConsolePage {get; set;}
    
    // Defines whether we're viewing as a popout VF QAM (designed to show "embedded" callouts)
    public Boolean CalloutMode {get; set;}
    
    
    // Additional items for IH1UX / SF1 QAM
    public String SearchResultId {get; set;}
    public String SelectedQAMTab {get; set;}
    public ControllerHelpContent cH {get; set;}
    public ControllerSearch cS {get; set;}
    public string RecordId {get; set;}                      // The SF1 context, passed from publisher action as "id" parameter    
        

    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Constructors
    /////////////////////////////////////////////////////////////////////////////////////////////////////
        
    // When used as a Controller - e.g., VF QAMS
    global ControllerIHQAMSettings() {
        LoadSettings();
    }
        
    // When used as an extension - or required for VF pages created for Mobile Cards
    public ControllerIHQAMSettings(ApexPages.StandardController stdController) {
        LoadSettings();
    }
    
    // When used via Aura and minimal / no additional setup activity is desired
    public ControllerIHQAMSettings(Boolean isAura) {}
        
        
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // For IHQAMSettings Page - settings initialisation
    /////////////////////////////////////////////////////////////////////////////////////////////////////
        
    // Populates the Settings string
    public void LoadSettings () {

        try {
            // IHQAMSettings expects the URL of the calling page plus the name
            // of a callback function that is to be used to place settings into a page element:
            // For guides, there is also a guide id parameter.
            // Retrieve these parameters (from query string) here...
            String retVal;
            ControllerSettings cS = new ControllerSettings();                       
            String callerPageURL = ApexPages.currentPage().getParameters().get('Referer');                  
            String callbackFunc = ServiceSecurity.getQueryParameter('callback', 0);                 
            String GuideId = ServiceSecurity.getQueryParameter('GuideId', 2);

            Settings = callbackFunc + '(\'zzz\');';

            // Get localisation information (field labels etc):
            // For help pages, we need a mix of "global", "branding" and cross screen labels and those which are screen specific.
            // The latter depends on the page being served...

            mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false); 
            mapBrdLocs = ServiceLocalisation.getDialogueLocalisations('Branding', false);
            mapQAMLocs = ServiceLocalisation.getDialogueLocalisations('ClientSide', false);
            if (Test.isRunningTest()) {
                // Page address will not be "real" if we're in test mode, so hard wire dialogue name in these cases
                mapDlgLocs = ServiceLocalisation.getDialogueLocalisations('', false);
            } else {
                mapDlgLocs = ServiceLocalisation.getDialogueLocalisations(cS.SFObjId(Url.getCurrentRequestUrl().toExternalForm()), true);
            }


            // Note whether we're in console mode
            isConsolePage = ControllerSettings.isConsolePage();
            

            // Settings to return vary by whether or not a guide has been requested:
            if (GuideId != '') {    
                // Make a call available (to console clients) for immediate cueing of guide steps for a specified guide                 
                retVal = getGuideInfo(GuideId, ControllerSettings.D1, ControllerSettings.D2);

            } else {
                // Make a call to actually obtain the desired settings information as a delimited string
                // Place this string in a suitable (javascript) format for return to the page
                retVal = cS.getIHSettings(callerPageURL); 
            }
                        
            // NB: As settings are returned to a JS callback function, we need to remove any quotes...
            Settings = Settings.replace('zzz', string.escapeSingleQuotes(retVal));
                        
                        
        } catch (exception e) {
            // NB: no attempt at localisation here - too risky
            Settings = 'An error occurred attempting to retrieve Help settings: ' + e.getMessage();                      
        }
                                
        return;
    }
        

    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // FOR CUEING GUIDES DIRECTLY (WITHOUT SELECT GUIDE DLG) AS WITH CONSOLE
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    private String getGuideInfo (String GuideId, String delimVal, String delimRow) {
                
        String retVal = '';
        HelpReadingListEntry__c prevRLE = null;
                
        try {
            // We need to seek the relevant guide steps, then for each return data in the correct format.
            // IMPORTANT:
            // PARAMETERS HERE MUST BE KEPT IN THE FORMAT USED BY THE READING LIST VIEWER PAGE AND AS EXPECTED
            // BY jsGuides.NavToGuideStep AND jsQAMenu.getGuideLinks:
            // I.E:
            //              VIP Identifier{delim 1}
            //              Element Type{delim 1}
            //              Guide Step HTID{delim 1}
            //              Prompt text{delim 1}
            //              Show Callout{delim 2}etc...
                        
            // Get all steps in the requested guide
            HelpReadingListEntry__c[] RLEs = [SELECT Id, HelpTopic__c,
                                                        HelpTopic__r.Name, HelpTopic__r.Summary__c, HelpTopic__r.ImageURL__c, HelpTopic__r.VideoURL__c,
                                                        HelpTopic__r.GuideCallout__c, HelpTopic__r.GuideStepMode__c,
                                                        HelpTopic__r.GuidedElement__r.Identifier__c, HelpTopic__r.GuidedElement__r.ElementType__c
                                                FROM HelpReadingListEntry__c
                                                WHERE HelpReadingList__c = :GuideId
                                                ORDER BY ReadingOrder__c];
                        
            // Loop through these to find the first set of manual steps
            for (HelpReadingListEntry__c RLE : RLEs) {
                                
                // To log any (MANUAL) step, we must have a previous (AUTOMATIC) step
                if (prevRLE != null) {
                                        
                    if (RLE.HelpTopic__r.GuideStepMode__c == 'Manual') {
                                                                                                
                        // Log details of the current Manual step
                        retVal += RLE.HelpTopic__r.GuidedElement__r.Identifier__c + delimVal;
                        retVal += RLE.HelpTopic__r.GuidedElement__r.ElementType__c + delimVal;
                        retVal += RLE.HelpTopic__c + delimVal;
                        retVal += RLE.HelpTopic__r.Name + delimVal;
                        retVal += RLE.HelpTopic__r.GuideCallout__c + delimVal;
                        retVal += RLE.HelpTopic__r.Summary__c.replace('"', '&quot;') + delimVal;
                        retVal += RLE.HelpTopic__r.ImageURL__c + delimVal;
                        retVal += RLE.HelpTopic__r.VideoURL__c + delimRow;
                                                                                                
                    } else {
                        prevRLE = null;
                    }                                        
                }
                                
                // If step is automatic, note for next iteration through loop
                if (RLE.HelpTopic__r.GuideStepMode__c == 'Automatic') {
                    prevRLE = RLE;                                  
                }
            }
            
            // v1.41+ : To ensure "new" LUX-created guides can work in classic:
            // These guides will not have an initial automatic step: if one was not found in the above,
            // loop again to create guide info regardless
            if (retVal == '') {
                for (HelpReadingListEntry__c RLE : RLEs) {
                    retVal += RLE.HelpTopic__r.GuidedElement__r.Identifier__c + delimVal;
                    retVal += RLE.HelpTopic__r.GuidedElement__r.ElementType__c + delimVal;
                    retVal += RLE.HelpTopic__c + delimVal;
                    retVal += RLE.HelpTopic__r.Name + delimVal;
                    retVal += RLE.HelpTopic__r.GuideCallout__c + delimVal;
                    retVal += RLE.HelpTopic__r.Summary__c.replace('"', '&quot;') + delimVal;
                    retVal += RLE.HelpTopic__r.ImageURL__c + delimVal;
                    retVal += RLE.HelpTopic__r.VideoURL__c + delimRow;
                }
            }            
                        
        } catch (exception e) {
            //retVal = 'Error obtaining Guide Step information: ' + e.getMessage();
            retVal = mapGlbLocs.get('MessageGenericError') + ' - ' + e.getMessage(); 
        }
        
        return retVal;                
    }
        

    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // ORIGINALLY FOR STANDARD VF QAM (NOW USED BY SF1 AND NOT STANDARD QAM)
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    // Extends the functionality of search results
    public class SearchResultQAM implements Comparable {
            
        public ControllerSearch.SearchResult Result {get; set;}
        public HelpedElement__c Element {get; set;}
                
        public SearchResultQAM (ControllerSearch.SearchResult sR, HelpedElement__c HE) {
            this.Result = sR;
            this.Element = HE;
        }
                
        // Comparable interface implementation (for sorting)
        public Integer compareTo(Object compareTo) {
            try {
                SearchResultQAM compSRQ = (SearchResultQAM)compareTo;
                String thisSortName = this.Element.Identifier__c;
                String compSortName = compSRQ.Element.Identifier__c;
                                                            
                if (thisSortName == compSortName) return 0;
                if (thisSortName > compSortName) return 1;
                return -1;  
                            
            } catch (exception e) {
                return 0;
            }                       
        }                
    }


    // Populates the Helped Elements collection for standard VF QAM
    public void initializeVFQAM () {
        
        Diags = 'initializeVFQAM: entry... ';

// Slightly slow - are localisations reqd here?        
ControllerSettings cS = new ControllerSettings();

        ServiceSecurity sS = new ServiceSecurity();     // Perf OK
        ServiceSchema sSc = new ServiceSchema();        // Perf OK
        Schema.DescribeSObjectResult objDesc;
        Boolean[] UPs;
        String callerPageURL;
        String HPLIdent;
        HelpTopic__c HT;
        HelpedElement__c[] HEs;
        Boolean showName;
        Boolean showSummary;
        ControllerSearch.SearchResult sR;
        String RootUrl;
        String temp;
        URL U;


        // 1.28 - switch to handle LUX situations (where there will not be an Apex page)
        if (ApexPages.currentPage() == null) {
            CalloutMode = false;

            //Diags += 'Non-apex mode... ';
            
            // LUX parameters should have been used prior to call to pass context info
            // 1.33.7 - LUX params may already include a page root, so only add one if required
            if (LUXParams.startsWith('http')) {
                callerPageURL = LUXParams;          
            } else {
                callerPageURL = URL.getOrgDomainURL().toExternalForm() + '/' + LUXParams;              
            }          

            // 1.39+ : If we've been passed an object ID (not a full record ID) we don't have a record:
            // we can contextualise, but must respond differently (e.g., assume a new record / respond to "use for new" flag etc), 
            // so set record ID accordingly
            
            if (LUXParams.length() > 3) {
                
                // We need record ID to be JUST a record ID - without any community prefix:
                if (! LUXParams.startsWith('http') && LUXParams.indexOf('/') != -1) {
                    RecordId = LUXParams.substring(LUXParams.indexOf('/') + 1);
                } else {
                    RecordId = LUXParams;
                }
            }

            //Diags += 'Record ID set to: ' + RecordId + '... ';
                    
        } else {
            // Note whether we're being used in popped out style to show embedded callouts
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
    
            Diags += 'CalloutMode=' + CalloutMode + '... ';


            // Use community path, if relevant, in any URLs returned below...
            RootUrl = ControllerSettings.getCommunityRoot();
            if (RootUrl == '') {
                RootUrl = URL.getOrgDomainURL().toExternalForm();
                Diags += 'Community not found - root URL=' + RootUrl + '... ';              
            }
    

            // 1.24: Prefer SF context info if passed to us (e.g., to a VF page in SF sidebar VF component, e.g., sidebar QAM):
            // However, we require more than just a "root" address (see need for record ID etc below), so if we don't
            // get this from SFDC, look for an IH context...
            callerPageURL = ApexPages.currentPage().getParameters().get('sfdcIFrameOrigin');                    
            if (callerPageURL != null) {
                Diags += 'sfdc origin=' + callerPageURL + '... ';               
                U = new System.Url(callerPageURL);
                if (U.getPath().length() == 0) {
                    callerPageURL = null;
                }
                                                                        
            } else {
                Diags += 'sfdc origin not present... ';             
            }
            
            
            if (callerPageURL == null) {
                callerPageURL = ApexPages.currentPage().getParameters().get('IHContext');               
                Diags += 'IH Context was sought: returned=' + callerPageURL + '... ';               
            }
            
            if (callerPageURL == null) {    
                Diags += 'Caller page NOT ascertained, seeking record id... ';              
                        
                // Take context from "id" parameter if this is provided (e.g., SF1 scenarios):
                // In these cases, the record ID will be the same value
                callerPageURL = ServiceSecurity.getQueryParameter('id', 2);                        
                RecordId = callerPageURL;
                Diags += 'RecordId=' + RecordId + '... ';               
                        
                if (callerPageURL != null) {
                    // This will be a record ID only, so re-factor this as required
                    callerPageURL = RootUrl + '/' + callerPageURL;
                        
                } else {
                    // If no caller supplied, adopt a "safe" default                        
                    callerPageURL = RootUrl + '/home/home.jsp';                         
                }
                Diags += 'Caller page now set to: ' + callerPageURL + '... ';               
                
                                                                    
            } else {
                Diags += 'Caller page WAS ascertained: ' + callerPageURL + '... ';              
                
                // If we have a context parameter, we need to extract any SF record ID from this:
                // We can only do this for SF pages - and we can only assume record ID is the path
                U = new System.Url(callerPageURL);
                if (U.getHost().toUpperCase().indexOf('SALESFORCE.COM') != -1) {
                    RecordId = U.getPath().substring(1);
                }         
                Diags += 'RecordId now set to: ' + RecordId + '... ';               
                                                      
            }
                
    
        }   // End if ApexPages object present / this is NOT a LUX page

        //Diags += 'callerPageURL set to: ' + callerPageURL + '... ';

        try {
            // Note SF base URL
            SFURL = RootUrl;
                    
            // Initialise our set of search results
            HelpedElements = new SearchResultQAM[]{};
  
            // Check subscription before continuing?
            // This is effectively handled by the QAM markup, which includes the
            // standard calls to get settings (JS) which in turn show subscription 
            // diagnostics etc as required.
                        
            // Ensure any topics listed respect FLS:
            showName = Schema.sObjectType.HelpTopic__c.fields.Name.isAccessible();
            showSummary = Schema.sObjectType.HelpTopic__c.fields.Summary__c.isAccessible();


// CAN WE AVOID THIS / PREVENT DUPLICATION?
// Also that we obey user permission sets...
UPs = sS.UserPermissions();

            // ...note granular rights in doing this
            isUser = UPs[0];
            isAuthor = UPs[1];
            isAdministrator = UPs[2];
            isAnalyst = UPs[3];
            

            
            // Treat lack of any permissions as a problem (as we must check FLS).
            // So: no Help Permission Set assisnments at all = same effect as no subscription...            
            if (! (isUser || isAnalyst || isAuthor || isAdministrator)) {
                // Just return in these cases
                return;
            } 
                        
            // Use the hosting SF page URL passed to  the VF QAM to get Helped Page Layout identifier                       
            Diags += 'Caller Page URL was: "' + callerPageURL + '"... ';                                
            HPLIdent = cS.SFObjId(callerPageURL);                   
            Diags += 'Layout Identifier was: ' + HPLIdent + '... ';

//system.debug('---------------------------------------------' + Diags);

            // Initialise layout identifier (can be reset below - but
            // we want a value here in case no elements found)
            SFObjId = HPLIdent;


            // Use this incoming object/layout ID to get object name
            try {

// THIS CALL IS VERY INEFFFICIENT IN LARGE, COMPLEX ORGS - HENCE FAILURES IN SOME AT THIS POINT (?)
// THIS MEMBER DATA IS ONLY SET HERE AND ONLY USED FOR A COUPLE OF LABELS (PAGE HELP IN LUX, + IH1QAM):
// EITHER AMEND THIS CALL OR DO AWAY WITH THIS LABEL...

// Fix here, then fix 1.41 patch version (currently hard-wired...)
                
                objDesc = sSc.getObjectDetails(SFObjId); 
                SFObjPluralName = objDesc.getLabelPlural();
                    
            } catch (exception exc) {
                SFObjPluralName = '[Page Object]';                              
            }
                        
            // Use this to check whether comments allowed, and also to 
            // note the name of the helped page layout
            try {
                Diags += 'Seeking HPL... ';
                
                HelpedPageLayout__c HPL = [SELECT Id, Name, AllowComments__c 
                                            FROM HelpedPageLayout__c 
                                            WHERE PageLayoutIdentifier__c = :SFObjId];

                Diags += 'HPL "' + HPL.Id + '" obtained... ';                            
                AllowComments = HPL.AllowComments__c;   
                HPLName = HPL.Name;             
                            
            } catch (exception e) {
                AllowComments = false;
                HPLName = '[Unknown Page]';
                Diags += 'No HPL found... ';                
            }
            
                        
            // From this, get helped elements
            HEs = cS.getHelpedElementRecords(HPLIdent, RecordId, !(UPs[1] || UPs[2]));

            Diags += 'Helped Elements sought from Settings Controller: ';
            if (HEs != null) {
                Diags += HEs.size() + ' elements returned... ';
            } else {
                Diags += 'NO elements returned - Settings Diags: ' + cS.Diags + '... ';
            }


            // Keep a copy of failed elements too
            failedHEs = cS.failedHEs;


            for (HelpedElement__c HE : HEs) {
                // From these, get the help topics from the relevant helped elements
                // and use these to add search results
                try {
                                                
                    // Store the ID of the Page Layout object represented by these elements
                    // for potential client-side use
                    HPLID = HE.HelpedPageLayout__c;
                                                
                    // Ditto the layout's identifier
                    SFObjId = HE.HelpedPageLayout__r.PageLayoutIdentifier__c;
                                                
                    sR = new ControllerSearch.SearchResult(null, HE, showName, showSummary);
                        
                    // Here, we need to modify the search result to respect the setting of
                    // the "Show Read More Link" flag:                                                                                                 
                    if (HE.HelpTopic__r.ShowReadMoreLink__c == false) {
                        if (!(UPs[1] || UPs[2])) {
                            // For non-admins, the link should not be available
                            sR.Link = '';
                                
                        } else {
                            // For admins, there should be a visual clue about read more status
                            sR.Name = '[' + sR.Name + ']';
                        }
                    }
                                                
                    // We also must respond to any problematic helped elements:
                    // Whilst end users will have been "shielded" from these (as
                    // call to settings to get helped elems removes them in these cases)
                    // admins will see the element and should be advised that it has issues...                                                
                    if (HE.HelpTopic__r == null) {
                        sR.Name = '';
                        sR.Link = 'javascript:ShowError(event);';
                    }
                                                
                    HelpedElements.add (new SearchResultQAM(sR, HE));
                                                                                                
                } catch (exception e) {
                }
            }
                        
            HelpedElements.sort();
                        
                        
            // Having got the helped elements, get the customer specified tool tip to go with them
            if (ControllerSettings.getSettings() != null) {
                //if (ControllerSettings.getSettings().BrandIHTooltip__c != null) {
                //    BrandIHTooltip = String.escapeSingleQuotes(ControllerSettings.getSettings().BrandIHTooltip__c);                 
                //} else {
                    BrandIHTooltip = '';                    
                //}
                    
            } else {
                // If there's no settings object, show the "base" error message                         
                Diags = mapGlbLocs.get('MessageServiceUnavailableConfiguration');
                return;
            }
                        
            // Note whether Guides exist for the current page layout
            GuidesExist = ControllerSettings.guidesExist(HPLIdent, isAuthor || isAdministrator);
                        
            // Note certain other global settings
            DefaultHTSet = (ControllerSettings.getSettings().DefaultHelpTopic__c != '' && ControllerSettings.getSettings().DefaultHelpTopic__c != null);
                        
            // If you get here, all is well so reset Diags...
            Diags =  '';

        } catch (exception e) {
            Diags = e.getMessage() + ' - (Initialising VF QAM) - ' + Diags;
        }
                
        return;
        
    }
        
        
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // EXTENDED FUNCTIONALITY FOR IH1UX / SF1 QAM
    /////////////////////////////////////////////////////////////////////////////////////////////////////
        
    // Determine if the current page request is via SF1 app or not: 
    // Note we'll accept SF's parameters or our own to make this judgement 
    public Boolean getIsSF1(){
        if(ServiceSecurity.getQueryParameter('sfdcIFrameHost', 0) != '' ||
            ServiceSecurity.getQueryParameter('sfdcIFrameOrigin', 0) != '' ||
            ApexPages.currentPage().getParameters().get('isdtp') == 'p1' ||
            (ApexPages.currentPage().getParameters().get('retURL') != null && ApexPages.currentPage().getParameters().get('retURL').contains('projectone')) ||
            ApexPages.currentPage().getParameters().get('IH1UX') == 'true' 
        ){
            return true;
        } else {
            return false;
        }
    }       
        
        
    // Action to show a help topic selected in the QAMs list of helped elements
    public PageReference getHelpTopic() {
        
        String U;

        // Use community path, if relevant, in any URLs returned below...
        String RootUrl = ControllerSettings.getCommunityRoot();
        if (RootUrl == '') {
            RootUrl = URL.getOrgDomainURL().toExternalForm();
        }
                            
        // We use IH1Tools if we're launching via IH1QAM - see initialisation of CalloutMode setting.
        // If we're using IH1QAM in "callout" / popped out mode (i.e., sidebar/ IHLauncher), we want to show the topic in a non-SF1 portal
        // Do not assume portal is IHTools
        String PortalPage = ControllerSettings.getPortalPageName(! CalloutMode);

        if (SearchResultId=='') {
            U = RootUrl + '/apex/' + PortalPage;                     
        } else {
            U = RootUrl + '/apex/' + PortalPage + '?HTID=' + SearchResultId;                      
        }
        
        return new PageReference(U);
        
    }
       
        
    // Action to go to a specified URL (as SF1 doesn't seem to like navigating to named browser
    // and will not provide "back" buttons in all cases to enable user to return from web to SF1)
    public PageReference gotoURL() {
        String U;

        // Use community path, if relevant, in any URLs returned below...
        String RootUrl = ControllerSettings.getCommunityRoot();
        if (RootUrl == '') {
            RootUrl = URL.getOrgDomainURL().toExternalForm();
        }
                            
        if (SearchResultId=='') {
            return null;                    
        } else {
            U = RootUrl + '/apex/iahelp__IHWrapper?IHContext=' + SearchResultId;                        
        }
        
        return new PageReference(U);
    }
        
        
    // Initialise QAM listings (other than usual elements list, e.g., bookmarks)
    public PageReference initializeIH1QAM () {
        
        String RootUrl = '';

        try {
            // Check we have a valid subscription: redirect to service unavailable (as returned from help controller) if not
            cH = new ControllerHelpContent();                       
            PageReference pRef = cH.checkSubscriptionStatus();
            if (pRef != null) {
                return pRef;
            }                       
                        
            // If subscription is OK, we can continue to get help for the current QAM context...
            initializeVFQAM();

            
            // In addition, IH1QAM has some additional settings (for popped out / Callout Mode)
            theSBQAMItemTitle = mapGlbLocs.get('AdviceLabelSelectTopic');
            theSBQAMItemCS = '';
            
            
            // Use community path, if relevant
            RootUrl = ControllerSettings.getCommunityRoot();
            if (RootUrl == '') {
                RootUrl = URL.getOrgDomainURL().toExternalForm();
            }               

            
            // The above act will have checked for initialised settings, or will have recorded an 
            // error in diags if these were not set: if this is encountered, redirect to message page
            if (Diags == mapGlbLocs.get('MessageServiceUnavailableConfiguration')) {                
                return new PageReference(RootUrl + '/apex/iahelp__IHServiceUnavailable');
            }
            

            // Treat lack of any permissions as a problem (as we must check FLS).
            // So: no Help Permission Set assisnments at all = same effect as no subscription...            
            if (! (isUser || isAnalyst || isAuthor || isAdministrator)) {
                return new PageReference(RootUrl + '/apex/iahelp__IHServiceUnavailable');
            } 
                                    

            // Get list of bookmarks
            cH.initialiseForBookmarks();
                        
            // Initialise search but don't run 
            cS = new ControllerSearch();
            ApexPages.currentPage().getParameters().put('Term', SearchResultId);
            cS.showSearchResults();
            
            // In these instances, a help listing is the selected tab: this may be for full 
            // topics or callouts, depending on whether or not we're popped out / in callout mode...
            if (CalloutMode == false) {
                SelectedQAMTab = 'PanelHelpList';
            } else {
                SelectedQAMTab = 'PanelCalloutList';
            }

        } catch (exception e) {
        }
                
        return null;    
                
    }
        
        
    // Conduct a search
    public void doSearch() {
            
        try {
            // Get search results
            cS = new ControllerSearch();
            ApexPages.currentPage().getParameters().put('Term', SearchResultId);
            cS.showSearchResults();

            // In these instances, Help search is the selected tab
            SelectedQAMTab = 'PanelHelpSearch';
                        
        } catch (exception e) {
        }
            
        return;
        
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Extension for Sidebar QAM
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    
    // The URL of the iframe displaying the selected callout etc.
    public string theSBQAMItem {get; set;}
    public string theSBQAMItemTitle {get; set;}
    public string theSBQAMItemCS {get; set;}
    
    // Get the callout template address to use with a selected item
    public void getTopicCalloutTemplate() {
        
        // Get the topic that was clicked
        try {
            HelpedElement__c HE = [SELECT Id, Name, HelpTopic__c FROM HelpedElement__c WHERE Id=:SearchResultId];
            HelpTopic__c HT = [SELECT Id, CustomStyle__c, CalloutTemplate__r.PageURL__c FROM HelpTopic__c WHERE Id=:HE.HelpTopic__c];
            
            cH = new ControllerHelpContent();
            theSBQAMItem = cH.getTemplateAddress(HT.CalloutTemplate__r.PageURL__c) + '?CalloutMode=true&HTID=' + HT.Id;
            theSBQAMItemTitle = HE.Name;
            theSBQAMItemCS = HT.CustomStyle__c;
            
        } catch (exception e) {   
            cH = new ControllerHelpContent();      
            theSBQAMItem = cH.getTemplateAddress('CalloutSummaryOnly');
            theSBQAMItemTitle = '[Help Home]';
            theSBQAMItemCS = '';
        }
        
        return;
    }
    
    
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Lightning component support
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    
    // Provides a way for LUX component calls to pass information in to Apex calls
    public string LUXParams {get; set;}
    



    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Potential to obtain settings via web services instead of VF page, should we ever need:
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    /*
    webservice static string HelpSettings(string Referer) {
        ControllerSettings cS = new ControllerSettings();   
        
        // Seems webservice strings strip out unprintables - so we'll have to replace them here - sigh!
        string retVal;
        String D0 = String.fromCharArray(new List<integer>{6});
        string D0R = '{D0}';
        string D1R = '{D1}';
        string D2R = '{D2}';
        
        try {
            retVal = cS.getIHSettings(Referer);     
            
            retVal = retVal.replaceAll(D0, D0R);
            retVal = retVal.replaceAll(ControllerSettings.D1, D1R);
            retVal = retVal.replaceAll(ControllerSettings.D2, D2R);
            
        } catch (exception ex) {
            retVal = 'ERROR: ' + ex.getMessage() + ': ' + retVal;
        }
        
        return retVal;      
    }
    */


    /*
    POTENTIAL SIDEBAR LINK FOR THE ABOVE:
    
        {!REQUIRESCRIPT('/soap/ajax/47.0/connection.js')}
        {!REQUIRESCRIPT('/soap/ajax/47.0/apex.js')}
        
        var Settings = sforce.apex.execute("iahelp.ControllerIHQAMSettings", "HelpSettings", {Referer:document.location.href});
        
        
        var IHjsConDiv = document.getElementById('IAIHSettings');
        if (IHjsConDiv + '' == 'null') {
        
            IHjsConDiv = document.createElement('div');
            IHjsConDiv.setAttribute('style', 'border: 1px dotted currentColor; width: 100%;');
            IHjsConDiv.setAttribute('id', 'IAIHSettings');
            IHjsConDiv.innerHTML = Settings;
            IHjsConDiv.style.display = 'block';
        
            document.getElementsByTagName('body')[0].appendChild(IHjsConDiv);
        
            IHjsConDiv = document.createElement('script');
            IHjsConDiv.setAttribute('src', '/resource/iahelp__IHResources/js/jsConsole.js');
            document.getElementsByTagName('head')[0].appendChild(IHjsConDiv);
        
        }   
    
    */
    
}