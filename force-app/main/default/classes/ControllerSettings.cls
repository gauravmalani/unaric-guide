/////////////////////////////////////////////////////////////////////////////////////////////////////
// PAGE CONTROLLER CLASS FOR VF PAGE ON WHICH ORG-WIDE IH SETTINGS ARE MAINTAINED 
//
// Martin Little for Improved Apps
// June 2012
/////////////////////////////////////////////////////////////////////////////////////////////////////

public with sharing class ControllerSettings {
    
    
    /*
============================================================================
*/
    
    public String[] objIDs {get;set;} 
    public String objJSON {get; set;}
    public map<string,string> mapObjs {get; set;}
    public boolean includeHelpObjects {get; set;}
    //public PageReference P;
    //public Blob bInfo;
    // Method that ca be called to refresh the page - eg settings pages (effectively re-checking org status)
    public PageReference reloadPage() {
        return null;
    }
    
    // Return a boolean indicating whether REST ops are enabled (proxy for remote site being in place)
    public boolean getRESTEnabled() {
        return ServiceSchema.restTest();
    }
    
    // Return a boolen indicating whether config item clickables are 'up to date' for the installed product version
    public boolean getConfigItemsCurrent() {
        
        boolean retVal;
        
        try {
            ConfigurationItem__c CI;
            List<ConfigurationItem__c> CIsShipped;
            system.version v = system.requestVersion();
            string vNum;
            
            // What we actually need to check here by way of version is the one that
            // is marked in the config tools we ship: this may not necessarily reflect
            // the latest version (e.g., if nothing has changed in the area of config tools recently).
            // So: here, we load config from shipped tools and check...
            
            PageReference p = new PageReference(UserJSONDoc);
            Blob bInfo = P.getContent();                     
            CIsShipped = (List<ConfigurationItem__c>) JSON.deserialize(bInfo.toString(), List<ConfigurationItem__c>.class);
            
            for (ConfigurationItem__c C : CIsShipped) {
                if (C.Type__c == 'ProductVersion') {
                    vNum = C.ActionCode__c;
                }
            }
            
            
            // Having located the version number specified in the shipped config items, check for this in locally installed records
            CI = [SELECT Id 
                  FROM ConfigurationItem__c 
                  WHERE Type__c = 'ProductVersion'
                  AND ActionCode__c = :vNum];
            
            retVal = true;
            
        } catch (exception e) {
            retVal = false;
        }
        
        return retVal;
    }
    
    // Return a boolean indicating whether Help settings have been initialised
    public boolean getSettingsInitialised() {
        return getSettings() != null;
    }
    
    
    // Initialise key values, including the list of this org's objects
    public void initialiseMSMinPage() {
        
        // Obtain the list of objects in the current org for use in pick lists
        try {
            objJSON = ControllerSettings.getStoredMetadata('GetObjectDetails');
            mapObjs = (map<string,string>) JSON.deserialize(objJSON, map<string,string>.class);   
            
        } catch (exception e) {
            Diags = 'Please initialise settings';
            return;
        }
        
        
        // Obtain details of last collection of metadata that was sought (so we can pre-select these items)
        try {
            ObjIds = new list<string>();
            string previouslySought;
            string[] OIDs;
            
            HelpInteraction__c MInt = [SELECT CreatedDate, Description__c
                                       FROM HelpInteraction__c 
                                       WHERE HelpInteractionType__c = 'Metadata sought'
                                       ORDER BY CreatedDate DESC
                                       LIMIT 1
                                      ]; 
            
            previouslySought = MInt.Description__c;
            
            OIDs = previouslySought.replace('(', '').replace(')', '').replace(' ', '').split(',');
            for (string O : OIDs) {
                objIds.add(O);            
            }
            
            if (getSettingsInitialised() && getConfigItemsCurrent()) {
                updateInstallationStatus();
            }
            
            Diags = 'Last refreshed on: ' + MInt.CreatedDate;
            
        } catch (exception e) {
            // If there's no previous metadata sought information, make no pre-selections / do nothing
            Diags = 'Error selecting previously sought objects: ' + e.getMessage();
        }
        
        
    }
    //update the custom setting record to false after successfull installation.
    private void updateInstallationStatus() {
        iahelp__OnInstall__c onInstall = iahelp__OnInstall__c.getOrgDefaults();
        if (onInstall == null) {
            onInstall = new iahelp__OnInstall__c();
        }
        if (onInstall.iahelp__isInstalling__c != false) {
            onInstall.iahelp__isInstalling__c = false;
            upsert onInstall;
        }
    }
    
    
    
    // Pick list values of this org's objects
    public List<selectOption> getObjData () {
        List<SelectOption> options = new List<SelectOption>();
        List<String> objNamesList = new List<String>();
        string[] optDef;
        
        integer control = 0;
        
        try {
            // Sort objects by name                       
            for (string O : mapObjs.keySet()) {
                
                // We have to limit the number of options to 1000 to avoid VF display issues
                control += 1;
                
                if (control <= 1000) {
                    objNamesList.add(mapObjs.get(O) + '^' + O);                             
                }
            }
            objNamesList.sort();   
            
            // Add sorted object details to select options
            for (string O : objNamesList) {
                optDef = O.split('\\^');
                options.add(new SelectOption(optDef[1], optDef[0] + ' (' + optDef[1] + ')'));
            }
            
            // Advise user if we're only able to show a subset of objects                     
            if (control > 1000) {
                Diags = 'NB: Org contains > 1k objects: only the first 1k are shown';
            }
            
        } catch (exception e) {   
            Diags = e.getMessage();             
        }
        
        return options;
    }
    
    
    // Page-callable wrapper to create metadata via asynch function
    public PageReference getLayoutMetadata() {
        Diags = 'Calling batch job to obtain metadata for objects: ' + objIDs;
        
        // Always add key help objects
        string[] helpObjCodes = new list<string>();
        
        helpObjCodes.add(ServiceSchema.getObjectIdByName('iahelp__HelpTopic__c'));    
        helpObjCodes.add(ServiceSchema.getObjectIdByName('iahelp__HelpedPageLayout__c'));    
        helpObjCodes.add(ServiceSchema.getObjectIdByName('iahelp__HelpedElement__c'));    
        helpObjCodes.add(ServiceSchema.getObjectIdByName('iahelp__HelpFilter__c'));    
        helpObjCodes.add(ServiceSchema.getObjectIdByName('iahelp__HelpFilterCriterion__c'));    
        helpObjCodes.add(ServiceSchema.getObjectIdByName('iahelp__HelpReadingList__c'));    
        helpObjCodes.add(ServiceSchema.getObjectIdByName('iahelp__HelpReadingListEntry__c'));    
        
        
        for (string code : helpObjCodes) {
            if (! objIDs.contains(code)) {objIDs.add(code);}
        }
        
        
        
        ServiceSchema.BatchGetLAMetadata (objIDs);
        
        for (string obj : objIDs) {
            ServiceSchema.BatchGetCSMetadata (obj);
        }
        return null;
    }
    
    
    /*
============================================================================
*/
    
    
    
    
    public String Diags {get; set;}                                 // For passing general info to users
    public String DiagsConfigIssue {get;set;}                       // Special message when settings not found
    public Boolean DisableOpts {get; set;}                          // Controls availability of controls by user rights
    public String selectedCategory {get; set;}                      // The settings area (tab) to highlight on arrival
    public String UserReportLink {get; set;}                        // Link to user report for subscriptions section
    public string theSelectedHelpSeedResource {get; set;}           // Selection from one of several shipped XML resources for seeding help docs
    public String UserXMLDoc {get; set;}                            // User defined XML doc from which to seed help topics
    public String UserJSONDoc {get; set;}                           // User defined JSON doc from which to seed help configuration tools
    public ConfigurationItem__c CIWhitelistedDomains {get; set;}    // Whitelisted help domains, if specified 
    public ConfigurationItem__c CICustomerCSS {get; set;}           // Text of customer CSS, saved as configuration item record 
    
    
    // As well as making them available as a full settings string via getIHSettings,
    // we expose some of the more important elements directly for convenience
    public String SFURL {get; set;}                         // SF base URL
    
    // Settings controller needs access to subscription information
    public ServiceSubs.LicenseInfo getLicense() {return ServiceSubs.getLicenseInfo('Improved Help Documents', null);}
    
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
    
    // Improved Help version information
    public String VersionInfo {get; set;}
    
    // The Improved Help product namespace
    public static final String NameSpace = 'iahelp';
    
    // Unprintable string delimiters for use in certain operations
    public static final string D1 = String.fromCharArray(new List<integer>{7});
    public static final string D2 = String.fromCharArray(new List<integer>{5});
    
    // Helped Elements that fail DDF criteria in current context (only set via getHelpedElementRecords)
    public HelpedElement__c[] failedHEs;
    
    private Boolean HPLExists = false;                      // True if helped page layout exists for current page
    private String HPLID;                                   // ID of the layout, if found   
    private String VFRecordId;                              // Record ID in play when on certain VF layouts - eg LUXOutHost        
    private HelpedElement__c[] HEs;                         // Actual helped element records on current layout
    private String cpURL;                                   // Caller page URL
    
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Public interfaces and entry points
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    
    // Initialise settings in constructor
    // Also, controls access to certain options by user rights
    public ControllerSettings () {
        Diags = '';
        DiagsConfigIssue = '';
        VersionInfo = system.requestVersion().major() + '.' + system.requestVersion().minor();
        theSelectedHelpSeedResource = 'IHHelp.xml';
        UserJSONDoc = '/resource/iahelp__IHResources/cfg/HelpConfig.json';
        ServiceSecurity Security = new ServiceSecurity();
        
        
        // Get localisation information (field labels etc):
        // We need a mix of "global", "branding" and cross screen labels and those which are screen specific.
        // The latter depends on the page being served: however, note that here we cannot
        // use SFObjId to derive page identifier from request URL - so we just hard wire the page name whose 
        // settings we want. The reason for this is that SFObjId needs to know pod, and thus needs Settings.
        // If these have not been initialised, there would be an error and we'd have no localisations returned
        // and thus an error on the settings page itself...
        mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false);
        mapBrdLocs = ServiceLocalisation.getDialogueLocalisations('Branding', false);
        mapDlgLocs = ServiceLocalisation.getDialogueLocalisations('iahelp__IHManageSettings', false); 
        
        
        // Certain buttons etc should only be available to those with IH's Help Admin permission set
        // AND ALSO the SF "Customise Application" profile permission.      
        DisableOpts = ! (Security.IsAllowed(ServiceSecurity.KnownSecureOperations.AdministerHelp) && Security.IsSFCustomiser());
        
        // COMMUNITIES SUPPORT
        SFURL = ControllerSettings.getCommunityRoot(); 
        if (SFURL == '') {
            SFURL = URL.getOrgDomainURL().toExternalForm();
        }
        
        
        // Set up links to certain configuration reports:
        // We know the name of the report we want: use this to get the id...
        try {
            // 1.24.13+  : only attempt this for Help Admins (avoids issues with Communities / Customer Community licensing / ORA-00904 error)
            if (!DisableOpts) {
                Report Rpt = [SELECT Id, Name FROM Report  WHERE Name = 'Help Users: Help Subscription Allocation'];
                UserReportLink = SFURL + '/' + Rpt.Id;
            } else {
                UserReportLink = '';
            }
            
        } catch (exception e) {
            // If we don't find the report, we can't offer the link...
            UserReportLink = '';
        }
        
        
        // Respond to any request from client to show a particular type of setting (tab)
        selectedCategory = ServiceSecurity.getQueryParameter('Cat', 2);
        if (selectedCategory == '') {selectedCategory = ServiceSecurity.getQueryParameter('iahelp__Cat', 2);}
        if (selectedCategory == '') {selectedCategory = 'QuickStart';}
    }
    
    
    // A settings object to retrieve org-wide settings
    private static IASetIHOrg__c IAS = IASetIHOrg__c.getInstance('EnabledElements');
    public static IASetIHOrg__c getSettings() {
        return IAS;
    }
    
    
    @AuraEnabled
    public static string getSettingsJSON() {
        string retVal;
        
        try {
            return JSON.serialize(getSettings());
        } catch (exception ex) {
            retVal = '';
        }
        return retVal;
        
    }   
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Actual settings call and support functions
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    
    // Improved means of returning all IH settings via a single call:
    // Returns a delimited string of settings pertinent to client side IH config decisions
    public String getIHSettings(String callerPageURL) {
        
        String retVal;
        String SFO;
        ServiceSecurity Security = new ServiceSecurity();
        ServiceSubs.LicenseInfo LI; 
        Boolean[] UPs;
        
        // Use an unprintable string for the delimiter of settings values
        String sDelim = String.fromCharArray(new List<integer>{6});
        
        
        try {        
            // Check we're in a domain that allows help before doing anything else: 
            // if not, proceed no further (minimising any unnecessary performance hit)
            
            // v1.38.1 - same fix as elsewhere at 1.38: 
            // (For SF API v41+): attempting construction of a URL without a path results in un-trappable error! 
            // v1.41+ : whitelisted domains list now in a configuration setting
            CIWhitelistedDomains = getWhitelistedDomainsData();
            
            if (CIWhitelistedDomains != null && callerPageURL != '' && callerPageURL != null) {
                if (CIWhitelistedDomains.SupportingControls__c != null) {
                    
                    string[] doms = CIWhitelistedDomains.SupportingControls__c.split(',');
                    boolean pass = false;
                    Url U = new Url(callerPageURL);
                    for (string d : doms) {
                        if (U.getHost() == d.trim() || U.getHost().endsWith('.' + d.trim())) {
                            pass = true;
                        }
                    }
                    
                    if (pass == false) {
                        retVal = 'Help not available in this domain';
                        return retVal;                          
                    }   
                }   
            }
            
            
            // Check licensing and permissions
            LI = ServiceSubs.getLicenseInfo('Improved Help Documents', null);
            UPs = Security.UserPermissions();
            
            
            // Note calling page URL for use elsewhere
            cpURL = callerPageURL;
            
            
            // Treat lack of any permissions as a problem (as we must check FLS).
            // So: no Help Permission Set assisnments at all = same effect as no subscription...            
            if (! (UPs[0] || UPs[1] || UPs[2] || UPs[3])) {
                try {
                    return ServiceLocalisation.getDialogueLocalisations('Globals', false).get('MessageNoPermissions');
                } catch (exception ex) {
                    return '';
                }
            } 
            
            
            // Subscription status code
            retVal = LI.StatusCode.name();
            
            // Subscription status diagnostics
            retVal += sDelim + LI.Status;
            
            // Subscription-allocated seats
            retVal += sDelim + LI.NumSeats;
            
            // Subscription type
            retVal += sDelim + LI.LicenseType;
            
            // Subscription (IH Documents) folder
            retVal += sDelim + ServiceSubs.LicenseFolderId;
            
            // Base SF URL (NB: this is so important, we also provide it as a directly accessible item)
            retVal += sDelim + SFURL;
            
            // SF / VF server pod being used to serve pages
            retVal += sDelim + getSettings().SFPod__c;
            
            // The name / prefix used by the community, if any, a user is visiting
            // NOTE :as this derivation exercise is critical, we use Diags to record our progress
            // here, and return these within settings returned (see below)
            Diags = '';
            DInfo = getDomainInfo(callerPageURL);
            retVal += sDelim + DInfo[1];
            Diags = DInfo[2];
            
            // Name of the Portal page in use (depends on LUX / Classic / SF1 settings etc.)
            // Ignore SF1 for now...
            retVal += sDelim + getPortalPageName(false);
            
            // Id of the SF object featured on the current page
            SFO = SFObjId(callerPageURL);
            retVal += sDelim + SFO;     
            
            
            // Are comments allowed on the layout for this object?
            // Also, has re-hooking been requested?
            try {
                HelpedPageLayout__c HPL = [SELECT Id, AllowComments__c, RehookTimes__c, RehookInterval__c 
                                           FROM HelpedPageLayout__c 
                                           WHERE PageLayoutIdentifier__c = :SFO];
                
                retVal += sDelim + HPL.AllowComments__c;
                
                if (HPL.RehookTimes__c != 0 && HPL.RehookInterval__c != 0 && HPL.RehookTimes__c != null && HPL.RehookInterval__c != null) {
                    retVal += sDelim + HPL.RehookTimes__c + ',' + HPL.RehookInterval__c;            
                } else {
                    retVal += sDelim + '0,0';                           
                }           
                
            } catch (exception e) {
                retVal += sDelim + false;           
                retVal += sDelim + '0,0';           
            }
            
            // IA Improved Help's product name space 
            retVal += sDelim + NameSpace;
            
            // Record of the key SF object Ids used by Improved Help
            retVal += sDelim + getSFObjectIds();
            
            
            // Customer's CSS: in Communities situation, if the path looks "relative" (does not start with a protocol)
            // we should add the community prefix in front of this...
            if (DInfo[1] != '' && getSettings().BrandCSS__c.toUpperCase().startsWith('/')) {
                retVal += sDelim + '/' + DInfo[1] + getSettings().BrandCSS__c;
            } else {
                retVal += sDelim + getSettings().BrandCSS__c;   
            }
            
            
            // Customer's chosen tool tip for helped elements
            //if (getSettings().BrandIHTooltip__c != null) {
            //    retVal += sDelim + String.escapeSingleQuotes(getSettings().BrandIHTooltip__c.replaceAll('"', ''));          
            //} else {
            retVal += sDelim + '';          
            //}
            
            
            // Branding / UX option
            retVal += sDelim + getSettings().BrandUXOption__c;
            
            // Provide improved Page-level help
            retVal += sDelim + getSettings().EnableImprovedPageHelp__c;
            
            // Provide improved help for Objects
            retVal += sDelim + getSettings().EnableImprovedObjectHelp__c;
            
            // Provide improved help for Related lists
            retVal += sDelim + getSettings().EnableImprovedRelatedListHelp__c;
            
            // Provide improved help for Details section headings
            retVal += sDelim + getSettings().EnableImprovedDetailsHelp__c;
            
            // Provide improved help for Field labels
            retVal += sDelim + getSettings().EnableImprovedFieldHelp__c;
            
            // Provide improved help for Table column headings
            retVal += sDelim + getSettings().EnableImprovedTableHelp__c;
            
            // Provide improved help for Buttons
            retVal += sDelim + getSettings().EnableImprovedButtonHelp__c;
            
            // Provide improved help for Links
            retVal += sDelim + getSettings().EnableImprovedLinkHelp__c;
            
            // Provide improved help for Custom Section headings
            retVal += sDelim + getSettings().EnableImprovedSectionHelp__c;
            
            // Provide improved help for Record Title
            retVal += sDelim + getSettings().EnableImprovedRecordTitleHelp__c;
            
            
            // jQuery aliasing (noConflict) option
            if (getSettings().jQNCMode__c == 'true') {
                retVal += sDelim + 'true';
            } else {
                retVal += sDelim + '';
            }
            
            
            // The type of helped element settings being provided below (reflects page mode)
            if (ApexPages.currentPage() != null) {            
                if (ApexPages.currentPage().getCookies().get('IHSelectedRL') != null) {
                    retVal += sDelim + 'GEnable';
                } else {
                    retVal += sDelim + 'Saved';
                }
            } else {
                retVal += sDelim + 'Saved';
            } 
            
            
            // The list of helped elements on the current page
            retVal += sDelim + GetHelpedElements(SFO, !(UPs[1] || UPs[2])).toUpperCase();
            
            // The details of the callouts to use with these
            retVal += sDelim + getCalloutDetails(SFO, !(UPs[1] || UPs[2]));
            
            // Details of elements that failed DDF (note: above calls should have populated this):
            // Only return these to authors / admins
            if (UPs[1] || UPs[2]) {
                retVal += sDelim + getFailedElementDetails();     
            } else {
                retVal += sDelim + '';     
            }
            
            // Details of any known "signatures" for additional helped element types
            retVal += sDelim + getSignatures(callerPageURL);
            
            // The ID of the current page layout (set by the previous calls)
            retVal += sDelim + HPLID;
            
            // The width at which to display certain kinds of callout
            retVal += sDelim + getSettings().CalloutWidth__c;
            
            // Callout closure behaviour (close on element toggle, mouse out etc)
            retVal += sDelim + getSettings().CalloutClosureBehaviour__c;
            
            // Existence or otherwise of a helped page layout for the current page
            retVal += sDelim + this.HPLExists;
            
            // Existence or otherwise of Guides for the current page
            // v1.41+ : expand features to include info about these guides in an additional setting
            //retVal += sDelim + guidesExist(SFO, UPs[1] || UPs[2]);
            
            if (guidesExist(SFO, UPs[1] || UPs[2]) == true) {
                // Guides exist: report this and list them
                retVal += sDelim + 'true';
                
                // Make the list of guides available
                string GList = '';
                string excl = '';
                
                // Use unprintable strings for delimiters
                String sD1 = String.fromCharArray(new List<integer>{7});
                String sD2 = String.fromCharArray(new List<integer>{5});
                
                
                HelpReadingListEntry__c[] RLEs = 
                    [SELECT HelpReadingList__c, HelpReadingList__r.Name, HelpReadingList__r.Summary__c, HelpReadingList__r.ReadingListType__c
                     FROM HelpReadingListEntry__c
                     WHERE HelpTopic__r.GuidedLayout__r.PageLayoutIdentifier__c = :SFO
                     AND (HelpReadingList__r.ReadingListType__c = 'Linear Guide' OR HelpReadingList__r.ReadingListType__c = 'Non-Linear Guide') 
                     AND (HelpReadingList__r.Active__c = true OR HelpReadingList__r.Active__c = :!(UPs[1] || UPs[2]))                          
                    ];    
                
                for (HelpReadingListEntry__c RLE : RLEs){
                    
                    if (excl.indexOf(RLE.HelpReadingList__c + ',') == -1) {
                        
                        /* 1.41.22 - caution for empty strings as summary: attempts to escape these will fail / ref null object error */                    
                        GList += RLE.HelpReadingList__c + sD2; 
                        GList += RLE.HelpReadingList__r.Name.escapeHtml4() + sD2;
                        
                        if (RLE.HelpReadingList__r.Summary__c != null && RLE.HelpReadingList__r.Summary__c != '') {
                            GList += RLE.HelpReadingList__r.Summary__c.escapeHtml4();
                        }
                        GList += sD2;
                        
                        if (RLE.HelpReadingList__r.ReadingListType__c == 'Linear Guide') {
                            GList += '1' + sD1;
                        } else {
                            GList += '2' + sD1;
                        }
                        
                        // Note the fact this Guide is in our list - so we don't add it more than once                      
                        excl += RLE.HelpReadingList__c + ',';           
                    }
                }
                
                retVal += sDelim + GList;
                
                
            } else {
                // No guides (empty listing)
                retVal += sDelim + 'false';
                retVal += sDelim + '* * * NO GUIDES * * *';
                
            }     
            
            
            // Global option re how to display links to available Guides
            retVal += sDelim + getSettings().ShowGuidesLinks__c;
            
            // Setting controlling whether or not to engage in login checks prior to attempting certain operations
            retVal += sDelim + getSettings().DoLoginChecks__c;
            
            
            // Settings cache: can be used to store context/mode-specific info:
            // For now, use this to send details of the selected Guide when in Guide Enable mode...
            if (ApexPages.currentPage() != null) {            
                if (ApexPages.currentPage().getCookies().get('IHSelectedRL') != null) {
                    retVal += sDelim + ApexPages.currentPage().getCookies().get('IHSelectedRL').getValue();
                    
                } else {
                    // Otherwise, use cache to offer layout / SFObjId derivation diagnostics
                    retVal += sDelim + Diags;
                }
            } else {
                retVal += sDelim + Diags;
            }   
            
            
            // Is user an Author?
            retVal += sDelim + UPs[1];
            
            // Is user an Admin?
            retVal += sDelim + UPs[2];
            
            // Is user an Analyst?
            retVal += sDelim + UPs[3];
            
            // Has this user been allocated to an IH subscription?
            retVal += sDelim + Security.IsSeated();
            
            
            // Has a default help topic been set (affecting availability of e.g. QAM home link)?
            retVal += sDelim + (getSettings().DefaultHelpTopic__c != '' && getSettings().DefaultHelpTopic__c != null);
            
            // Add localisation information:
            // Get this from the localisation service...
            map<string, string> mapLocs = ServiceLocalisation.getDialogueLocalisations('ClientSide', false);
            String Locs = '';
            for (String locKey : mapLocs.keySet()) {        
                Locs += locKey + D1 + mapLocs.get(locKey) + D2;
            }
            retVal += sDelim + Locs;
            
        } catch (exception e) {
            retVal = 'Error attempting to retrieve Help settings (Get IH Settings): ' + e.getMessage() + ': Settings retrieved up to the point of failure: ' + retVal;
        }        
        
        return retVal;
    }
    
    
    // Returns a Capek (^) separated list of the 3 character SF codes for key Improved Help objects:
    // The order in which these occur is:
    //      - Help Topics
    //      - Help Reading Lists
    //      - Help Resources
    //      - Help Topic Templates
    //      - Signatures
    //      - Help Vote Sets
    //      - Interactions
    public Static String getSFObjectIds () {
        
        String retVal = '';
        
        try {           
            retVal += ServiceSchema.getObjectIdByName('iahelp__HelpTopic__c') + '^';
            retVal += ServiceSchema.getObjectIdByName('iahelp__HelpReadingList__c') + '^';
            retVal += ServiceSchema.getObjectIdByName('iahelp__HelpResource__c') + '^';
            retVal += ServiceSchema.getObjectIdByName('iahelp__HelpTopicTemplate__c') + '^';
            retVal += ServiceSchema.getObjectIdByName('iahelp__HelpableSignature__c') + '^';
            retVal += ServiceSchema.getObjectIdByName('iahelp__HelpVoteSet__c') + '^';
            retVal += ServiceSchema.getObjectIdByName('iahelp__HelpInteraction__c');
            
        } catch (exception e) {
            retVal = e.getMessage();
        }
        
        return retVal;
    }   
    
    
    // To obtain the object ID featuring on the specified SF page
    public String SFObjId(String PageURL) {
        
        String retVal;
        String CPrefix = '';
        
        // Known address forms:
        //
        // pod.salesforce.com/object id
        // pod.salesforce.com/page path
        // namespace.pod.visual.force.com/apex/PageName
        // domain.force.com/portalOrCommunity/object id
        // domain.force.com/portalOrCommunity/page path
        // Custom Domain/page path
        // Custom Domain/Associated Community/page path
        
        // 1.42+ ADDED
        // Custom Domain/ [No additional community path] - which will return null/object id to differentiate from internal situations
        // __LUX__[page name] - a client-side derivation of path to a Lightning page layout, for cases where object / record ID contexts are not supplied
        
        // 1.36.3 - to cater for Spring 18 Critical Update:
        // "Remove Instance Names From URLs for Visualforce, Community Builder, Site.com Studio, and Content Files"
        // New VF form could be in play:
        
        // OLD
        // domain--namespace.pod.visual.force.com
        // NEW
        // domain--namespace.visualforce.com
        
        
        Diags += 'SFObjId entry with URL: ' + PageURL + '... ';
        
        try {
            // v1.38+ (For SF API v41+): attempting construction of a URL without a path results in un-trappable error!         
            if (PageURL == '' || PageURL == null) {PageURL = 'https://NoPageURLSupplied.com';}          
            
            URL U = new System.Url(PageURL);
            retVal = U.getPath();
            if (retVal == null) {retVal = '';}
            
            
            IASetIHOrg__c theIAS = IASetIHOrg__c.getInstance('EnabledElements');
            String SFPOD = theIAS.SFPod__c;
            
            Diags += 'Host is: ' + U.getHost().toUpperCase() + '... ';
            
            // If this is not a SF, VF or COMMUNITIES address...
            if (U.getHost().toUpperCase().indexOf('SALESFORCE.COM') == -1 
                && U.getHost().toUpperCase().indexOf('VISUAL.FORCE.COM') == -1
                && U.getHost().toUpperCase().indexOf('VISUALFORCE.COM') == -1               
                && U.getHost().toUpperCase().indexOf('.FORCE.COM') == -1) {
                    
                    Diags += 'Non-standard (Force) address... ';
                    
                    // In these cases, it could be that a custom domain / url is in play:
                    if (DInfo == null) {
                        Diags += 'DInfo null - calling getDomainInfo... ';                  
                        DInfo = getDomainInfo(PageURL);
                        Diags += '~~' + DInfo[2] + '~~ ';                   
                    }
                    
                    if (DInfo[0] == 'true') {
                        
                        // The address is a domain, so note any site Community prefix
                        // and continue to process...
                        CPrefix = DInfo[1];
                        Diags += 'DInfo states Domain in play - CPrefix set to "' + CPrefix + '"... ';
                        
                    } else {
                        // If root not in domains table...
                        // The "object" is simply the page address (as we can provide help for external pages via VF QAM etc)
                        Diags += 'DInfo states NO Domain in play - returning PageURL... ';
                        retVal = PageURL;   
                        return retVal;              
                    }
                    
                } else {
                    Diags += 'Standard (Force) address... ';
                    
                    // If address is "standard", we need to check for "standard" community prefix
                    if (DInfo == null) {
                        Diags += 'DInfo null - calling getDomainInfo... ';                  
                        DInfo = getDomainInfo(PageURL);
                        Diags += '~~' + DInfo[2] + '~~ ';                   
                    }
                    CPrefix = DInfo[1];
                    
                    Diags += 'DInfo setting CPrefix "' + CPrefix + '"... ';
                }
            
            
            // v1.42+ : deal with blank community prefixes, which may be encountered as a null string in the path...
            if (retVal.startsWith('/null/') && CPrefix == '') {
                
                // This is possible with communities that have no prefix
                Diags += 'DInfo blank CPrefix encountered as "/null/" in path being examined - setting CPrefix to "null" for purposes of further processing... ';
                CPrefix = 'null';
                
            }
            
            
            // Remove any site/community prefix temporarily from the front of our return value
            if (retVal.startsWith('/' + CPrefix + '/')) {
                retVal = retVal.substring(CPrefix.length() + 1);
            }
            Diags += 'retVal post prefix removal set to "' + retVal  + '"... ';
            
            
            if (retVal.toUpperCase().indexOf('/APEX/') != -1) {
                // If the remaining string at this stage features "Apex", we want the VF page name
                Diags += 'Apex path... ';   
                retVal = retVal.replace('/apex/', '');
                
                // If we're on the LUX Out VF page, the identifier we want may not be the page name:
                // In these cases, if we've been passed a record ID in the form of IHContext, that's what we should use 
                // to get the required object ID
                
                if (retVal.toUpperCase().indexOf('IHLUXOUTHOST') != -1) {
                    
                    Diags += 'Lightning Out scenario (LUXOutHost) detected... ';                    
                    retVal = ServiceSecurity.getQueryParameter('IHContext', 2);
                    if (retVal.length() > 2) {
                        
                        // Uniquely in the case of LUX Out, keep track of IHContext param in full
                        // as well as returning the implied SF object ID:
                        // See also all calls to getHelpedElementRecords, which generally pass "null" as a record ID
                        // but will use this value, if set...
                        VFRecordId = retVal;
                        retVal = retVal.substring(0,3);
                    }
                    
                    Diags += 'IHContext derived identifier set to: "' + retVal + '"... ';
                    
                } else {
                    // For any other VF page, just return the VF page name
                }
                
                
            } else if (retVal.toUpperCase().indexOf('.JSP') != -1 || retVal.toUpperCase().indexOf('.APEXP') != -1 ) {
                // In some cases, we'll be on a SF "utility" page, in which case it should be one of several known types (file extensions)
                // and we want its full path (but not any query parameters)...            
                Diags += 'JSP / ApexP path... ';
                retVal = U.getPath().substring(1);
                
                if (U.getQuery() != null) {
                    retVal = retVal.replace(U.getQuery(), '');
                }
                
                // Remove communities path for now              
                if (CPrefix != '') {
                    retVal = retVal.replace(CPrefix + '/', '');
                }
                
            } else {
                // In some cases, we're not on a JSP - but we're still on a utility page:
                // The only check we can do here is to look for pages whose path does not
                // start with 3x alphanumeric characters followed by "/" or nothing...
                Diags += 'Other path... ';              
                
                if (retVal.length() > 4) {
                    Diags += 'retVal > 4 path... ';
                    
                    // 1.42+ : Is this a LUX page name? If so, it will have been marked as such:
                    // 1.43.4: original logic can fail with certain paths of >4 and <8 characters!
                    //if (retVal.substring(1, 8) == '__LUX__') {
                    
                    if (retVal.startsWith('/__LUX__')) {
                        // Return page name as passed in
                        Diags += 'LUX Page path - returning as is... ';     
                        retVal = retVal.substring(8);
                        
                    }                    
                    else if (retVal.substring(1, 4).isAlphanumeric()) {  
                        
                        Diags += '>4 alpha path... ';   
                        
                        if (retVal.substring(4, 5) == '/') {
                            // 3 chars + "/" at the start = SF object id code 
                            Diags += 'nnn/ : returning 3 letter code... ';                            
                            retVal = retVal.substring(1, 4);
                            
                        } else {
                            
                            if (retVal.substring(1).isAlphanumeric()) {
                                // No non-alphas in path = take SF object id code 
                                Diags += 'NO non-alphas in path (' + retVal.substring(1) + '): returning assumed record 3 letter code... ';                            
                                retVal = retVal.substring(1, 4);
                                
                            } else {
                                Diags += 'Non-alphas in path (' + retVal.substring(1) + '): continuing... ';                                                            
                                if (retVal.length() > 15) {                             
                                    Diags += 'retVal > 15... ';                            
                                    
                                    if (retVal.substring(1, 16).isAlphanumeric()) {
                                        // If there's a 15 char Id followed by something 
                                        // (e.g., edit this record) = take SF object id code
                                        retVal = retVal.substring(1, 4);
                                        
                                    } else {
                                        // Not a 15 char record id = Here we want the whole path (as JSPs)
                                        retVal = U.getPath().substring(1);
                                        
                                        if (U.getQuery() != null) {
                                            retVal = retVal.replace(U.getQuery(), '');
                                        }                                                           
                                        
                                    }                               
                                    
                                } else {
                                    Diags += 'retVal <= 15... ';                            
                                    
                                    // Not a 15 char record id = Here we want the whole path (as JSPs)
                                    retVal = U.getPath().substring(1);
                                    
                                    if (U.getQuery() != null) {
                                        retVal = retVal.replace(U.getQuery(), '');
                                    }                                                           
                                }                           
                            }                       
                        }
                        
                    } else {    
                        // Non-alpha 1st 3 chars = we want the whole path (as JSPs)
                        Diags += '>4 NON alpha path... ';
                        retVal = U.getPath().substring(1);
                        
                        // But remove query and (for now) any Communities part
                        if (U.getQuery() != null) {
                            retVal = retVal.replace(U.getQuery(), '');
                        }
                        
                        if (CPrefix != '') {
                            retVal = retVal.replace(CPrefix + '/', '');
                        }
                        
                    }               
                    
                } else {
                    // 3 chars only = SF object id code
                    Diags += '3 char path... '; 
                    retVal = retVal.substring(1,4);
                }           
            } 
            
            
            // If this was a communities address, add the community path back on
            if (CPrefix != '' && CPrefix != null) {
                Diags += 'Non-blank CPrefix added back for retVal of "' + retVal + '"... '; 
                retVal = CPrefix + '/' + retVal;
            }
            
        } catch (exception e) {
            retVal = 'Err!';
            Diags = 'Error attempting to derive Salesforce Object identifier from URL "' + PageURL + '": ' + e.getMessage() + ': ' + Diags;
        }        
        
        return retVal;
    }
    
    
    // Returns the name of the VF page to use as the Tools / Portal page:
    // This varies depending on SF environment in use (classic, LUX or SF1)
    // cf ControllerHelpContent.isIHLUX and ControllerIHQAMSettings.isIHLUX - as these have their own variant logic
    public static String getPortalPageName(Boolean isIH1UX) {       
        if (isIH1UX == true) {
            return 'IH1Tools';
        } else {
            
            // If not in SF1, we need to respond to global settings - branding / UX
            if (getSettings().BrandUXOption__c == '3') {
                // This is the LUX for Guide Prompts AND portal option
                return 'IHToolsLUX';
            } else {
                return 'IHTools';
            }
        }
    }
    
    
    // Get the RL entries that constitute a guide
    public HelpReadingListEntry__c[] getGuideSteps(string GuideId) {
        
        HelpReadingListEntry__c[] retVal;
        
        try {
            retVal = [SELECT Id, ReadingOrder__c, 
                      HelpReadingList__c,                
                      HelpTopic__r.Id,
                      HelpTopic__r.Name, HelpTopic__r.Summary__c, HelpTopic__r.ImageURL__c, HelpTopic__r.VideoURL__c, 
                      HelpTopic__r.GuideStepMode__c, HelpTopic__r.GuidedRecord__c, HelpTopic__r.GuideCallout__c,
                      HelpTopic__r.GuidedElement__r.Identifier__c, HelpTopic__r.GuidedElement__r.ElementType__c 
                      FROM HelpReadingListEntry__c
                      WHERE HelpReadingList__c = :GuideId
                      ORDER BY ReadingOrder__c];          
        } catch (exception e) {}
        
        return retVal;
    }    
    
    
    // Checks whether Guides exist for the current page
    public static Boolean guidesExist(String pageId, Boolean isAuthor){
        
        Boolean retVal = false;
        String excl = '';
        
        
        // v1.21: If no page identifier is supplied, we cannot offer guide info
        if (pageId == '' || pageId == null) {
            return retVal;
        }
        
        
        try {
            
            // Guides exist if any RL's first non-local step is for the current page layout:
            // I.e., guides that start from where we are - NOT all those that include a 
            // step featuring the current layout...
            
            // 1.22: we only want to include Active guides for helped users
            system.debug('pageId '+pageId);
            system.debug(' RL '+[SELECT HelpTopic__r.GuidedLayout__r.PageLayoutIdentifier__c,HelpReadingList__c, ReadingOrder__c
                                 FROM HelpReadingListEntry__c
                                ]);
            for (HelpReadingListEntry__c RLE :
                 [SELECT HelpReadingList__c, ReadingOrder__c
                  FROM HelpReadingListEntry__c
                  WHERE HelpTopic__r.GuidedLayout__r.PageLayoutIdentifier__c = :pageId
                  AND (HelpReadingList__r.Active__c = true OR HelpReadingList__r.Active__c = :!isAuthor)
                 ]
                )
            {
                system.debug(' excl '+excl);
                system.debug(' RLE.HelpReadingList__c '+RLE.HelpReadingList__c);
                if (excl.indexOf(RLE.HelpReadingList__c + ',') == -1) {
                    
                    // See if there's an entry in this RL that is NOT local,
                    // has a lower reading order and is not for the current layout
                    HelpReadingListEntry__c[] RLE2 = [
                        SELECT Id
                        FROM HelpReadingListEntry__c
                        WHERE HelpReadingList__c = :RLE.HelpReadingList__c
                        AND HelpTopic__r.GuideStepMode__c != 'Local'
                        AND ReadingOrder__c < :RLE.ReadingOrder__c
                        AND HelpTopic__r.GuidedLayout__r.PageLayoutIdentifier__c != :pageId
                    ];
                    
                    if (RLE2.size() > 0) {
                        // If there is such an entry, this Guide should NOT feature in results
                        // list as it does not effectively "start" from where we are
                        
                    } else {
                        // There is no such entry - so we DO want to show this guide
                        retVal = true;
                        
                        // Note the fact this Guide is in our list - so we don't examine it more than once                      
                        excl += RLE.HelpReadingList__c + ',';
                        
                    }
                }   
            } 
            
        } catch (exception e) {
            // Default to safe value - the "as is" value as derived above to date
        }
        
        return retVal;
    }    
    
    
    // To obtain the collection of helped element records featuring on the specified SF page
    private String goodHEIdentifiers;  
    public HelpedElement__c[] getHelpedElementRecords(String pageId, String recordId, Boolean ExcludeInactiveTopics) {
        
        HelpedElement__c[] candidateHEs = null;
        HelpedElement__c[] theHEs = new List<HelpedElement__c>();
        failedHEs = new List<HelpedElement__c>();
        goodHEIdentifiers = '';
        String SFObjectName;
        integer communityOffset = 0;                    // Used in obtaining correct record id (taking community path into account)
        String strSOQL;
        ServiceSchema sS = new ServiceSchema(); 
        Schema.DescribeSObjectResult sR = null;
        URL U;                          
        String currentRecordId = '';
        Boolean addingSFRecord;
        Boolean filterPass;
        
        
        try {           
            if (Diags == null) {
                Diags = '';
            }
            
            // Helped elements in play vary depending on mode:
            Cookie ck;
            
            // Rem: in Aura scenarios, there won't be a current page!
            if (ApexPages.currentPage() != null) {
                ck = ApexPages.currentPage().getCookies().get('IHSelectedRL');              
            }
            if (ck != null) {
                
                String GID = String.valueOf(ck.getValue());
                String GEIds = '';
                String s;
                
                // In Guide Enable mode (recorded in cookie) we want elements mentioned
                // in the help topics that are the steps in the selected guide
                
                // Get the list of referenced helped elements
                HelpReadingListEntry__c[] RLEs = [SELECT HelpTopic__r.GuidedElement__c 
                                                  FROM HelpReadingListEntry__c
                                                  WHERE HelpReadingList__c = :GID
                                                  AND HelpTopic__r.GuidedElement__c != null];
                
                // Use these as selection criteria 
                for (HelpReadingListEntry__c RLE : RLEs) {
                    GEIds += '\'' + RLE.HelpTopic__r.GuidedElement__c + '\',';
                }
                If (GEIds != '') {GEIds = GEIds.substring(0, GEIds.length() - 1);}
                
                
                s =  'SELECT Id, Name, Identifier__c, ElementType__c, DataDrivenFilter__c, ';
                s += 'HelpTopic__r.Name, HelpTopic__r.Summary__c, HelpTopic__r.ShowReadMoreLink__c, ';
                s += 'HelpTopic__r.CalloutHeight__c, HelpTopic__r.CalloutTemplate__c, HelpTopic__r.CalloutTemplate__r.PageURL__c, ';
                s += 'HelpedPageLayout__r.PageLayoutIdentifier__c ';
                s += 'FROM HelpedElement__c ';
                s += 'WHERE Id IN (' + GEIds + ')';
                
                List<HelpedElement__c> results = Database.query(s);
                
                for (HelpedElement__c HE : results) {
                    theHEs.add(HE);
                }
                
                
            } else {
                // Otherwise, look up the page ID in helped page layouts...     
                HelpedPageLayout__c[] HPL = [SELECT Id, PageLayoutIdentifier__c 
                                             FROM HelpedPageLayout__c 
                                             WHERE PageLayoutIdentifier__c = :pageId];
                
                // This may return 1+ layouts - as SOQL is case insensitive - so we need to check we find
                // exactly the one we're after...
                for (HelpedPageLayout__c L : HPL) {
                    if (L.PageLayoutIdentifier__c.equals(pageId) == true) {
                        
                        // Note here the fact that we got a helped page layout
                        HPLID = L.Id;
                        this.HPLExists = true;                  
                        break;                  
                    }
                    
                    else {
                        Diags += '"' + L.PageLayoutIdentifier__c + '" does not equal "' + '"' + pageId + '"... ';
                    }
                }
                
                
                // Then look for this layout ID in helped elements...
                try {
                    
                    candidateHEs = [SELECT Id, Name, Identifier__c, ElementType__c, DataDrivenFilter__c, UseForNew__c,
                                    HelpTopic__r.Name, HelpTopic__r.Summary__c, HelpTopic__r.ShowReadMoreLink__c, HelpTopic__r.CustomStyle__c, 
                                    HelpTopic__r.Description__c,
                                    HelpTopic__r.ImageTitle__c,                                
                                    HelpTopic__r.ImageURL__c,                                
                                    HelpTopic__r.ImageCaption__c,                                
                                    HelpTopic__r.ImageWidth__c,                                
                                    HelpTopic__r.ImageHeight__c,                                
                                    HelpTopic__r.CalloutHeight__c, HelpTopic__r.CalloutTemplate__c, HelpTopic__r.CalloutTemplate__r.PageURL__c,
                                    HelpTopic__r.HelpVoteSet__c,                                
                                    HelpTopic__r.Keyword__c,                                
                                    HelpTopic__r.LastModifiedDate,
                                    HelpedPageLayout__r.PageType__c, HelpedPageLayout__r.PageLayoutIdentifier__c,iahelp__HelpFilter__c,iahelp__HelpFilter__r.iahelp__FilterLogic__c 
                                    FROM HelpedElement__c 
                                    WHERE HelpedPageLayout__c = :HPLID
                                    
                                    // Added for v1.14: we only want to see elements where we have access to the associated topic
                                    AND (HelpTopic__r.Active__c = true OR HelpTopic__r.Active__c = :ExcludeInactiveTopics)
                                    
                                    ORDER BY ElementType__c];
                    
                    
                    // Added for v1.16: we only want to see elements whose data driven filter = true:
                    // So: loop through the candidates to evaluate their filters, adding those that 
                    // pass to our "output" set of elements...                  
                    
                    // We're going to build a SOQL string below, so we need to work out which
                    // object type and record we're dealing with. Source of this information
                    // varies depending on whether we're in SF or VF layout...
                    
                    
                    // 1.24.30: In obtaining record ID, may need to take community paths into account
                    if (DInfo != null) {
                        if (DInfo[1] != '') {
                            // Domains in play: 
                            communityOffset = DInfo[1].length() + 1;
                        }
                    }
                    
                    if (candidateHEs[0].HelpedPageLayout__r.PageType__c == 'Standard') {
                        // In SF, record ID should come in form [root]/[record id]                      
                        try {                        
                            // If we were passed a record id, use it: otherwise, attempt to derive it
                            // NB: we can end up here when on the LUX Out VF Page: special provisions 
                            // are made in SFObjId to note when the page (which would otherwise show as a VF layout)
                            // is in play: if so, note is taken of IH context and layout derived (SF or VF) from that.
                            // As SFObjId code does this, it notes a record ID which will have been passed in (so recordId != null)
                            if (recordId != null) {
                                currentRecordId = recordId;
                            } else {
                                // v1.38.1 - (For SF API v41+): attempting construction of a URL without a path results in un-trappable error! 
                                if (cpURL != '' && cpURL != null) {
                                    U = new System.Url(cpURL);
                                    currentRecordId = U.getPath().substring(1 + communityOffset, 16 + communityOffset);                                 
                                }
                            }
                            sR = sS.getObjectDetails(currentRecordId.subString(0, 3));
                        } catch (exception ex) {}
                        
                    } else {
                        // In VF, record id can only be found via query [root]?Id=[record id]
                        try {
                            // If we were passed a record id, use it: otherwise, attempt to derive it
                            if (recordId != null) {
                                currentRecordId = recordId;
                            } else {
                                // v1.38.1 - (For SF API v41+): attempting construction of a URL without a path results in un-trappable error! 
                                if (cpURL != '' && cpURL != null) {
                                    U = new System.Url(cpURL);
                                    
                                    // NEED TO ALTER THIS TO GET RECORD ID MORE RELIABLY:
                                    // CONSOLE URLs MAY NOT HAVE ID PARAMETER IN THIS POSITION - SO LOOK FOR SPECIFIC QUERY ITEM INSTEAD   
                                    
                                    currentRecordId = U.getQuery().substring(3, 18);                                    
                                }
                            }
                            
                            sR = sS.getObjectDetails(currentRecordId.subString(0, 3));                          
                        } catch (exception ex) {}
                    }
                    
                    
                    // 1.42.12+ : delegating DDF checks to separate function, so it can be shared elsewhere: 
                    // e.g., ControllerLUXOps.getRootTopicForContext
                    Diags += 'Get Helped Element Records: about to seek DDF Matches for record "' + currentRecordId + '" from ' + candidateHEs.size() + ' candidates... ';              
                    theHEs = getDDFMatches(currentRecordId, candidateHEs);
                    Diags += 'Done: ' + theHEs.size() + ' records passed... ';
                    System.debug(' theHEs '+theHEs);
                    
                    // Take note of failed helped elements - those that ARE in candidates and NOT in DDF filtered results
                    for (HelpedElement__c HE : candidateHEs) {
                        
                        filterPass = false;
                        
                        for (HelpedElement__c matchHE : theHEs) {
                            if (HE.Id == matchHE.Id) {
                                filterPass = true;
                            }
                        }
                        
                        if (filterPass == true) {
                            // Keep a note of passed HE identifiers
                            goodHEIdentifiers += D2 + HE.Identifier__c + D1;
                            
                        } else {
                            // Also keep a note of failed elements
                            failedHEs.add(HE);
                        }
                    }
                    
                } catch (exception e) {
                    // Error getting candidate HEs
                }
                
            }   // End if this was NOT GE mode
            
            
        } catch (exception e) {
            
        }
        
        return theHEs;
    }
    
    
    // Applies data driven filters to a given collection of candidate helped elements, given a record ID against which to test
    public static HelpedElement__c[] getDDFMatches (String RecordID, HelpedElement__c[] CandidateHEs) {
        
        system.debug('getDDFMatches - entry... ');
        
        HelpedElement__c[] retVal = new HelpedElement__c[]{};
            id rid; 
        Schema.SObjectType sobjectType;
        String sobjectName;       
        DescribeSObjectResult describeResult;       
        boolean filterPass;
        boolean addingSFRecord;
        string strSOQL;
        string SFObjectName;
        ServiceSchema sS = new ServiceSchema();
        Schema.DescribeSObjectResult sR = null;
        Map<string,string> mapOfFieldAndValues=new Map<string,string>();
        String filterfname;
        String filterfnamelc;
        list<string> filteredfieldNames = new list<string>();
        sObject objRecord;
        map<id,iahelp__HelpFilter__c> mapOfHelpFilter;
        map<id,list<iahelp__HelpFilterCriterion__c>> mapOfHFAndHFC;
        Utilities.FilterEvaluator Evaluator;
        
        
        // If we're not given a record ID, we cannot filter:
        if (RecordID == null || RecordId == '') {
            addingSFRecord = true;
            
        } else {
            addingSFRecord = false;
            
            if (RecordID.length() < 15) {
                return CandidateHEs;
            }
            
            // If record we're given is, in fact, marker for a tab (list view) layout, we cannot filter            
            if (RecordID.startsWith('__LUX__')) {
                return CandidateHEs;
            }
        }
        
        
        try {
            
            // Only attempt to obtain test record if we have one - if we're on a new record, skip...            
            if (addingSFRecord == false) {
                
                system.debug('getDDFMatches - Record ID: ' + RecordID);   
                
                rid = RecordID;
                sobjectType = rid.getSObjectType();
                sobjectName = sobjectType.getDescribe().getName();       
                describeResult = rid.getSObjectType().getDescribe();       
                
                
                for(iahelp__HelpFilter__c obA : [SELECT id,(SELECT iahelp__FilteredField__c FROM iahelp__HelpFilterCriteria__r) FROM iahelp__HelpFilter__c WHERE iahelp__FilteredObject__c =: sobjectName]){                        
                    for(iahelp__HelpFilterCriterion__c b : obA.iahelp__HelpFilterCriteria__r){
                        
                        filterfname = b.iahelp__FilteredField__c;
                        filterfnamelc = filterfname.toLowerCase();
                        
                        if(!filteredfieldNames.contains(filterfnamelc)){
                            filteredfieldNames.add(filterfnamelc);
                            system.debug('inside for filteredfieldNames '+filteredfieldNames);  
                        }
                    }                                                  
                }
                
                try {                
                    if(filteredfieldNames != null){
                        strSOQL = ' SELECT ' + String.join(filteredfieldNames, ',') +' FROM ' + describeResult.getName() + ' Where Id =: RecordID';
                        objRecord = Database.query(strSOQL);
                    }               
                    
                } catch (exception e) {
                    system.debug('getDDFMatches error: ' + e.getMessage());         
                }
                
                system.debug(objRecord);
                system.debug('Record against which to test obtained... ');
                
                // Create an object capable of testing DDF, below:
                Evaluator = new Utilities.FilterEvaluator();
                
                
                // Create a map storing values of all fields on the specified record, for filter checking comparisons
                for(string f:filteredfieldNames){
                    mapOfFieldAndValues.put(string.valueOf(f),string.valueOf(objRecord.get(f)));
                    system.debug(string.valueOf(f)+'  '+string.valueOf(objRecord.get(f)));
                }
                
                
                
                // Create a map with details of all help filters
                mapOfHelpFilter = new map<id,iahelp__HelpFilter__c> ([
                    SELECT Id, Name, iahelp__FilterLogic__c, iahelp__FilterIdentifier__c, iahelp__FilteredObject__c, iahelp__FilteredObjectIdentifier__c 
                    FROM iahelp__HelpFilter__c
                    LIMIT 50000
                ]);
                
                // Create a map with details of each filter criterion in each filter
                mapOfHFAndHFC = new map<id,list<iahelp__HelpFilterCriterion__c>>();
                
                for (iahelp__HelpFilter__c hf : [
                    SELECT id,(
                        SELECT Id, Name, iahelp__HelpFilter__c, iahelp__FilteredField__c, 
                        iahelp__Operator__c, iahelp__CriterionNumber__c, iahelp__FilterValue__c,
                        iahelp__FilteredFieldType__c 
                        FROM iahelp__HelpFilterCriteria__r 
                        ORDER BY iahelp__CriterionNumber__c ASC
                        LIMIT 50000) 
                    FROM iahelp__HelpFilter__c
                    LIMIT 50000]){
                        
                        if(hf.iahelp__HelpFilterCriteria__r!=null){
                            mapOfHFAndHFC.put(hf.id,hf.iahelp__HelpFilterCriteria__r);
                        }
                    }
                
                
                // Obtain the name of the object applicable to the record whose DDF passes are sought:
                // If we weren't passed a record ID, this will legitimately fail, with new records caught separately below
                sR = sS.getObjectDetails(RecordId.subString(0, 3));
                if (sR != null) {
                    SFObjectName = sR.getName();                        
                } else {
                    SFObjectName = '[Unidentified Salesforce object type]';
                }
                
            }   // End if we have a record            
            
            
            // Loop around the candidate helped elements supplied to check their filters
            for (HelpedElement__c HE : CandidateHEs) {
                
                if(HE.iahelp__HelpFilter__c == null){      
                    
                    // NO STRUCTURED FILTER PRESENT                               
                    system.debug('Getting DDF matches - NO structured filter present... ');
                    
                    // If no Help Filter lookup is present on the current helped element, continue 
                    // to check for 'traditional' DDFs...
                    
                    if (HE.DataDrivenFilter__c != null &&  HE.DataDrivenFilter__c != '') {
                        system.debug('Getting DDF matches - Unstructured filter IS present... ');
                        
                        // Only evaluate unstructured filters if we have a record
                        if (addingSFRecord == false) {                      
                            system.debug('Getting DDF matches - unstructured filter is: ' + HE.DataDrivenFilter__c);
                            
                            try {
                                // AT THIS POINT WE WANT TO CHECK CURRENT RECORD MEETS DATA DRIVEN CRITERIA:
                                // NB: For data driven help, there MUST be a record - so there should be an ID...                               
                                // Build SOQL based on object's table name plus record Id plus data filter:
                                // I.e., to pass, THIS RECORD must pass data filter
                                
                                strSOQL = 'SELECT Id FROM ' + SFObjectName + ' WHERE Id=\'' + String.escapeSingleQuotes(RecordId) + '\' AND (' + HE.DataDrivenFilter__c + ')';                      
                                List<sObject> results = database.query(strSOQL);                        
                                filterPass = results.size() == 1;
                                
                            } catch (exception ex) {
                                // On any filtering exception, fail safe and don't add the element
                                // (but do continue to following elements)
                                filterPass = false;
                            }
                            
                        } else {
                            // If we're adding a record, only way filter can pass is if marked as use for new
                            filterPass = HE.UseForNew__c == true;
                        }                        
                        
                    } else { 
                        // No filter (structred or un-structured) in play = pass         
                        system.debug('Getting DDF matches - Neither structured nor unstructured filter present: passing this element... ');                               
                        filterPass = true;
                    }
                    
                    // Added for v1.19 / T-208 / Unfuddle 518:
                    // There is one other cause to pass a particular HE:
                    // [1] when adding objects, there is no SF record (so any filter would fail).
                    // [2] we therefore want a blank filter, but...
                    // [3] a blank filter would always pass, overriding any data drivens when viewing etc.
                    
                    // SO: Keep rules as is for all cases other than new.
                    // If "USE FOR NEW" tick box ticked for this HE and this is a new record, pass
                    
                    if (HE.UseForNew__c == true && addingSFRecord == true) {
                        filterPass = true;
                    }
                    
                    
                    if (filterPass == true) {                            
                        // Add passed HEs and Keep a note of passed HE identifiers
                        retVal.add(HE);
                    }   
                    
                    
                } else {
                    // STRUCTURED FILTER PRESENT
                    
                    filterPass = false;
                    
                    // Only evaluate structured filters if we have a record
                    if (addingSFRecord == false) {         
                        
                        // If a help filter is present, take this in preference to any DDF string:                    
                        system.debug('Getting DDF matches - structured filter present: evaluating... ');
                        
                        list<boolean> criteriaTestResults = new list<boolean>();
                        
                        // Loop around the criteria of the filter selected on the current candidate helped element
                        for(iahelp__HelpFilterCriterion__c obj:mapOfHFAndHFC.get(HE.iahelp__HelpFilter__c)) {
                            
                            // Retrieve the value of the field specified in the criterion from the current record
                            String fieldValue=mapOfFieldAndValues.get(string.valueOf(obj.iahelp__FilteredField__c).toLowerCase());
                            
                            // Note the value specified in the criterion for this field
                            String filterValue=obj.iahelp__FilterValue__c;
                            
                            system.debug('Field sought: ' + obj.iahelp__FilteredField__c);                        
                            system.debug('Value in queried record: '+ fieldValue);
                            
                            
                            // Adjust field values of certain types for ease of comparison
                            if(string.valueOf(obj.iahelp__FilteredFieldType__c).toUpperCase()=='DATE'){
                                fieldValue=(fieldValue.substring(0, 10));
                            }
                            if(fieldValue=='null'){
                                fieldValue='';
                            }
                            
                            // Replace field tokens in filter criteria, where present
                            if(filterValue.startsWith('{')&&filterValue.endsWith('}')){
                                filterValue=mapOfFieldAndValues.get(filterValue.substring(1, filterValue.length()-1));
                            }
                            
                            // Test current record's field value for complaince with specified criteria using comparison utility
                            criteriaTestResults.add(Evaluator.evaluateFilterClause (fieldValue,obj.iahelp__Operator__c, filterValue)); 
                            
                            system.debug(' fieldValue '+ fieldValue);
                            system.debug(' obj.iahelp__FilteredField__c ' + obj.iahelp__FilteredField__c);
                            system.debug(' operator ' + obj.iahelp__Operator__c);
                            system.debug(' FilterValue ' + filterValue);
                            system.debug(' Res ' + criteriaTestResults);
                        }
                        
                        
                        // Now apply the logic specified for the filter as a whole: to do this, use a utility to
                        // parse test result booleans obtained above into the filter logic string and evaluate...
                        if (criteriaTestResults != null || criteriaTestResults.size() > 0) { 
                            
                            if(Evaluator.evaluateFilterLogic(mapOfHelpFilter.get(HE.iahelp__HelpFilter__c).iahelp__FilterLogic__c, criteriaTestResults)){
                                filterPass = true;
                            }
                            
                            system.debug( 'Evaluation: ' + filterPass);
                            
                        } else {
                            filterPass = true;
                        }
                        
                        
                    } else {
                        // If we're adding a record, only way filter can pass is if marked as use for new
                        filterPass = HE.UseForNew__c == true;
                        
                    }
                    
                    
                    // If helped element has met the criteria, record this fact
                    if (filterPass == true){
                        retVal.add(HE);
                        system.debug('getDDFMatches retVal size '+retVal.size()+' HE.iahelp__Identifier__c '+HE.iahelp__Identifier__c);
                    }
                    
                }   // End if Help Filter present on candidate helped element
            }   // End of candidate helped element loop
            
            system.debug('getDDFMatches: matching elements being returned: ' + retVal.size());
            
        } catch (exception e) {
            system.debug('getDDFMatches error: ' + e.getMessage());         
            retVal = null;
        }
        
        return retVal;
        
    }
    
    
    // Returns a delimited list of "signatures" of custom helpable elements applicable to the current domain
    private String getSignatures(String PageURL) {
        
        // We want the return value in the form [Signature] {d2} [Identifier] {d2} [Identifier Type] {d2} [Help Style] {d1}
        
        String retVal = '';
        
        try {           
            // Get the list of signatures applicable to the current page's domain
            // v1.38+ (For SF API v41+): attempting construction of a URL without a path results in un-trappable error!         
            if (PageURL == '' || PageURL == null) {PageURL = 'https://NoPageURLSupplied.com';}          
            
            System.Url U = new System.Url(PageURL);
            String D = U.getHost();         
            
            HelpableSignature__c[] HS = [SELECT Name, Identifier__c, IdentifierType__c, HelpStyle__c
                                         FROM HelpableSignature__c
                                         WHERE Domain__c = :D];
            
            for (HelpableSignature__c S : HS) {
                retVal += S.Name + D2 + S.Identifier__c + D2 + S.IdentifierType__c + D2 + S.HelpStyle__c + D1;
            }
            
            // v1.38: Add some additional, hard-wired "signatures" here for certain known (but relatively new, LUX) types:
            // Field labels:
            retVal += 'span.slds-form-element__label' + D2 + 'text' + D2 + 'Text' + D2 + 'Helpable IHSnapToElement HelpableLUXField' + D1;
            
            // Amended v1.39.9+ for change of LUX page furniture as of Winter 19
            retVal += 'span.test-id__field-label' + D2 + 'text' + D2 + 'Text' + D2 + 'Helpable IHSnapToElement HelpableLUXField' + D1;
            
            
        } catch (exception e) {
            retVal = '';
        }
        
        return retVal;
    } 
    
    
    // Returns a (ASCII CODE 7) delimited list of the Identifier strings of elements that have been helped on a given page 
    private String GetHelpedElements(String pageId, Boolean ExcludeInactiveTopics) {
        
        String retVal = '';
        
        // Use an unprintable string for the delimiter of settings values
        String sDelim = String.fromCharArray(new List<integer>{7});
        
        
        try {   
            
            // Get helped element records - if we haven't already done so
            // v1.34: passing a record ID variable that may have been set (e.g., in LUX Out scenarios):
            // Impact otherwise will be nil (record ID passed in will remain NULL)
            if (HEs == null) {HEs = getHelpedElementRecords(pageId, VFRecordId, ExcludeInactiveTopics);}
            
            try {
                
                for (HelpedElement__c HE : HEs) {
                    // Add each helped element's Id to our return value
                    retVal += HE.Identifier__c + sDelim;
                }
                
                // Cut final capek
                if (retVal.length() > 0) {retVal = retVal.substring(0, retVal.length()-1);}
                
            } catch (exception e) {
                // No helped elements defined for this layout
            }
            
        } catch (exception e) {
            // Error getting elements
        }
        
        return retVal;
    }
    
    
    // For getting details of the callouts to be used on a given page:
    // Returns a delimited string in a form suited to page mode.
    //
    // For Guide enable mode:
    // Identifier {delim 2} Element Type {delim 2} Step Name {delim 2} Step Summary {delim 2} Step Order [{delim 1} etc]
    //
    // In all other cases:
    // Identifier {delim 2} Template {delim 2} Height {delim 2} ActiveId {delim 2} Styles {delim 2} DDF [{delim 1} etc]
    // 
    //      ... where 
    //      {delim 1} = ASCII code 7
    //      {delim 2} = ASCII code 5
    //
    // Identifier   = a helped element identifier (HelpedElement__c.Identifier, NOT Id)
    // Template     = the VF page name to use as the callout template
    // Height       = height in pixels at which to display the callout
    // ActiveId     = (as there may be >1 element with a given Identifier) the Id (NOT Identifier) of the
    //                specific element that matches visibility / data filter for the current SF record
    // Styles       = names of custom CSS style applied to the element's topic (and thus to the element too) plus other marker classes (eg, NEW marker)
    // DDF          = flag indicating whether this element is a peer of others (where data driven filters are in use) 
    
    private String getCalloutDetails(String pageId, Boolean ExcludeInactiveTopics) {
        
        String retVal = '';
        HelpTopicTemplate__c HT;
        //String Diags = '';
        Diags = '';
        String sCSS = '';
        DateTime dTRecenyLimit = DateTime.now().addHours(Integer.valueOf(ControllerSettings.getSettings().UpdateMarkerHours__c) * -1);
        
        
        // Use unprintable strings for delimiters
        String sD1 = String.fromCharArray(new List<integer>{7});
        String sD2 = String.fromCharArray(new List<integer>{5});
        
        
        try {
            
            // Source of "Callout" details varies by mode (reflected in certain cookies)
            Cookie ck;            
            if (ApexPages.currentPage() != null) {            
                ck = ApexPages.currentPage().getCookies().get('IHSelectedRL');
            }
            
            if (ck != null) {
                // In guide enable mode, details are based on the RL entries in the selected guide:
                String GID = String.valueOf(ck.getValue());
                HelpReadingListEntry__c[] RLEs = getGuideSteps(GID);
                
                for (HelpReadingListEntry__c RLE: RLEs) {
                    retVal += RLE.HelpTopic__r.GuidedElement__r.Identifier__c + sD2 + RLE.HelpTopic__r.GuidedElement__r.ElementType__c + sD2 + RLE.HelpTopic__r.Name + sD2 + RLE.HelpTopic__r.Summary__c + sD2 + RLE.ReadingOrder__c + sD2 + RLE.Id + sD1;                  
                }
                
            } else {
                // In all other modes, callout details come from the relevant helped element records:
                // Get these here - if we haven't already done so...
                // v1.34: passing a record ID variable that may have been set (e.g., in LUX Out scenarios):
                // Impact otherwise will be nil (record ID passed in will remain NULL)
                if (HEs == null) {HEs = getHelpedElementRecords(pageId, VFRecordId, ExcludeInactiveTopics);}
                
                
                Diags += 'Getting Callout Details: Got helped elements (page ID: ' + pageId + ', VF Record: ' + VFRecordId + ')... ';
                
                for (HelpedElement__c HE : HEs) {
                    
                    Diags += 'In Help Element loop with HE Callout ' + HE.HelpTopic__r.CalloutTemplate__c + '... ';
                    
                    try {   
                        
                        // The number of HEs to report to the page against each helped element is not about fails: even if multiple
                        // records "pass" their DDFs (because Org has not defined correct mutually exclusive filters etc) we 
                        // want authors to known this when in reconfigure mode. So: report the total HEs for each helped element...
                        Integer numDDFElems = 0;                        
                        
                        // Add up all elements that passed...
                        for (HelpedElement__c HEl : HEs) {
                            if (HEl.Identifier__c == HE.Identifier__c && HEl.ElementType__c == HE.ElementType__c) {
                                numDDFElems += 1;
                            }
                        }                       
                        
                        // Also add any that failed DDF...
                        for (HelpedElement__c FHE : failedHEs) {
                            if (FHE.Identifier__c == HE.Identifier__c && FHE.ElementType__c == HE.ElementType__c) {
                                numDDFElems += 1;
                            }
                        }                       
                        
                        
                        
                        // Set any custom style to apply: this is based on:
                        //      - Help topic custom style, if specified
                        //      - "Newness" flag if required                        
                        sCSS = HE.HelpTopic__r.CustomStyle__c;
                        if (HE.HelpTopic__r.LastModifiedDate > dTRecenyLimit) {
                            sCSS += ' IHCollateralUpdated';
                        }
                        
                        // Now put this information together with other callout details into our return value
                        retVal += HE.Identifier__c + sD2 + HE.HelpTopic__r.CalloutTemplate__r.PageURL__c + sD2 + HE.HelpTopic__r.CalloutHeight__c + sD2 + HE.Id + sD2 + sCSS + sD2 + numDDFElems + sD1;
                        
                    } catch (exception e) {
                        // Default to a safe value: this is the default callout layout
                        try {
                            String deft = ControllerSettings.getSettings().DefaultHelpCalloutTemplate__c;
                            HT = [SELECT PageURL__c FROM HelpTopicTemplate__c WHERE Id = :deft];
                            retVal += HE.Identifier__c + sD2 + HT.PageURL__c + sD2 + '55' + sD2 + HE.Id + sD2 + '' + sD2 + '0' + sD1;
                            
                        } catch (exception f) {
                            retVal += HE.Identifier__c + sD2 + 'iahelp__CalloutSummaryOnly' + sD2 + '55' + sD2 + HE.Id + sD2 + '' +sD2 + '0' + sD1;
                        }                       
                    }           
                    
                } // End for HEs                               
            }   // End if / mode switch
            
            
            
            // Cut final delimiter
            if (retVal.length() > 0) {retVal = retVal.substring(0, retVal.length()-1);}
            
        } catch (exception e) {         
            Diags += e.getMessage();
            retVal = Diags;
            
        }
        
        return retVal;
    }
    
    
    // Returns details of helped elements that failed data driven filters for the current layout
    private String getFailedElementDetails() {
        String retVal = '';
        String fHEs = '';
        
        try {
            for (HelpedElement__c HE : failedHEs) {
                
                // In any DDF situation, there may always be 1x successful HE and Nx unsuccessful ones for the same element.
                // failedHEs contains ALL failing HE records, but we only want to return those where NO HE record for the same
                // element was a pass...            
                if (goodHEIdentifiers.indexOf(D2 + HE.Identifier__c + D1) == -1 && fHEs.indexOf(D2 + HE.Identifier__c + D1) == -1) {
                    retVal += D2 + HE.Identifier__c + D1;               
                    fHEs += D2 + HE.Identifier__c + D1;             
                }
            }
            
        } catch (exception e) {
            retVal = '';
        }
        
        return retVal;
    } 
    
    
    // The list of available callout Help Topic Templates - for drop down lists
    public List<selectOption> getTemplatesC() {
        List<SelectOption> options = new List<SelectOption>();
        
        try {
            for (HelpTopicTemplate__c Temp : 
                 [SELECT Id, Name 
                  FROM HelpTopicTemplate__c 
                  WHERE TemplateType__c = 'Callout'
                 ]
                ) 
            {
                options.add(new SelectOption(Temp.Id, Temp.Name));
            }
            
        } catch (exception e) {
            
        }
        
        return options;
    }
    
    
    // The list of available full Help Topic Templates - for drop down lists
    public List<selectOption> getTemplatesF() {
        List<SelectOption> options = new List<SelectOption>();
        
        try {
            for (HelpTopicTemplate__c Temp : 
                 [SELECT Id, Name 
                  FROM HelpTopicTemplate__c 
                  WHERE TemplateType__c = 'Full Topic'
                 ]
                ) 
            {
                options.add(new SelectOption(Temp.Id, Temp.Name));
            }
            
        } catch (exception e) {
            
        }
        
        return options;
    }
    
    // The list of available vote sets - for drop down lists
    public List<selectOption> getVoteSets() {
        List<SelectOption> options = new List<SelectOption>();
        
        // Add a 'none' option
        options.add(new SelectOption('--None--', '--None--'));
        
        try {
            for (HelpVoteSet__c Temp : 
                 [SELECT Id, Name 
                  FROM HelpVoteSet__c
                  ORDER BY Name
                  LIMIT 1000]
                ) 
            {
                options.add(new SelectOption(Temp.Id, Temp.Name));
            }
            
        } catch (exception e) {}
        
        return options;
    }
    
    
    // Get whitelisted domain info, if this has been created    
    public static ConfigurationItem__c getWhitelistedDomainsData() {
        
        ConfigurationItem__c retVal = null;
        
        try {
            retVal = [SELECT Id, SupportingControls__c
                      FROM ConfigurationItem__c 
                      WHERE Type__c = 'ConfigurationData'
                      AND ActionCode__c = 'GetWhitelistedDomains'
                      LIMIT 1];
            
        } catch (exception e) {
            // Do nothing
        }
        return retVal;
    }    
    
    
    // Get the config item that stores LUX styling (CSS) data, if this has been created    
    public static ConfigurationItem__c getCustomerCSSData() {
        
        ConfigurationItem__c retVal = null;
        
        try {
            retVal = [SELECT Id, SupportingControls__c
                      FROM ConfigurationItem__c 
                      WHERE Type__c = 'ConfigurationData'
                      AND ActionCode__c = 'GetCustomerCSS'
                      LIMIT 1];
            
        } catch (exception e) {
            // Do nothing
        }
        return retVal;
    }    
    
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Manage settings page support
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    
    // Hyperlink to the Help Topic Templates page
    public String getTemplatesLink() {
        
        String retVal;
        
        try {
            retVal = SFURL;
            String[] SFOIDs = getSFObjectIds().split('\\^');        
            retVal += '/' + SFOIDs[3];
            
        } catch (exception e) {
            retVal = '#';
        }
        
        return retVal;
    }
    
    
    // Hyperlink to the Helpable Signatures page
    public String getSignaturesLink() {
        
        String retVal;
        
        try {
            retVal = SFURL;
            String[] SFOIDs = getSFObjectIds().split('\\^');        
            retVal += '/' + SFOIDs[4];
            
        } catch (exception e) {
            retVal = '#';
        }
        
        return retVal;
    }
    
    
    // Hyperlink to the Help Interactions page
    public String getInteractionsLink() {
        
        String retVal;
        
        try {
            retVal = SFURL;
            String[] SFOIDs = getSFObjectIds().split('\\^');        
            retVal += '/' + SFOIDs[6];
            
        } catch (exception e) {
            retVal = '#';
        }
        
        return retVal;
    }
    
    
    // Entry point for settings page: 
    // also, loads settings as currently saved into member data (available via getSettings)
    public void showSettings() {
        
        try {
            
            IASetIHOrg__c IASet = IASetIHOrg__c.getInstance('EnabledElements');
            
            //IAS.AllocatedSeats__c                   = IASet.AllocatedSeats__c;
            
            IAS.EnableImprovedPageHelp__c           = IASet.EnableImprovedPageHelp__c;
            IAS.EnableImprovedObjectHelp__c         = IASet.EnableImprovedObjectHelp__c;
            IAS.EnableImprovedRelatedListHelp__c    = IASet.EnableImprovedRelatedListHelp__c;
            IAS.EnableImprovedDetailsHelp__c        = IASet.EnableImprovedDetailsHelp__c;
            IAS.EnableImprovedFieldHelp__c          = IASet.EnableImprovedFieldHelp__c;
            IAS.EnableImprovedTableHelp__c          = IASet.EnableImprovedTableHelp__c;
            IAS.EnableImprovedButtonHelp__c         = IASet.EnableImprovedButtonHelp__c;
            IAS.EnableImprovedLinkHelp__c           = IASet.EnableImprovedLinkHelp__c;
            IAS.EnableImprovedSectionHelp__c        = IASet.EnableImprovedSectionHelp__c;
            IAS.EnableImprovedRecordTitleHelp__c    = IASet.EnableImprovedRecordTitleHelp__c;
            
            IAS.EnableExportDocHT__c                = IASet.EnableExportDocHT__c;
            IAS.EnableExportDocRL__c                = IASet.EnableExportDocRL__c;
            IAS.EnableExportXL__c                   = IASet.EnableExportXL__c;
            
            IAS.RLShowNextPrev__c                   = IASet.RLShowNextPrev__c;
            IAS.ShowReferringTopics__c              = IASet.ShowReferringTopics__c;
            IAS.ShowGuidesLinks__c                  = IASet.ShowGuidesLinks__c;
            
            IAS.ConsoleResourceLinkTarget__c        = IASet.ConsoleResourceLinkTarget__c;
            
            IAS.QuickLink1__c = IASet.QuickLink1__c;
            IAS.QuickLink2__c = IASet.QuickLink2__c;
            IAS.QuickLink3__c = IASet.QuickLink3__c;
            IAS.QuickLink4__c = IASet.QuickLink4__c;
            IAS.QuickLink5__c = IASet.QuickLink5__c;
            
            IAS.QuickText1__c = IASet.QuickText1__c;
            IAS.QuickText2__c = IASet.QuickText2__c;
            IAS.QuickText3__c = IASet.QuickText3__c;
            IAS.QuickText4__c = IASet.QuickText4__c;
            IAS.QuickText5__c = IASet.QuickText5__c;
            
            IAS.QuickTip1__c = IASet.QuickTip1__c;
            IAS.QuickTip2__c = IASet.QuickTip2__c;
            IAS.QuickTip3__c = IASet.QuickTip3__c;
            IAS.QuickTip4__c = IASet.QuickTip4__c;
            IAS.QuickTip5__c = IASet.QuickTip5__c;
            
            IAS.BrandColour1__c         = IASet.BrandColour1__c;
            IAS.BrandColour1Text__c     = IASet.BrandColour1Text__c;
            IAS.BrandColour2__c         = IASet.BrandColour2__c;
            IAS.BrandColour3__c         = IASet.BrandColour3__c;
            IAS.BrandColour4__c         = IASet.BrandColour4__c;
            
            IAS.BrandTitle__c       = IASet.BrandTitle__c;
            IAS.BrandSubTitle__c    = IASet.BrandSubTitle__c;
            IAS.BrandImage__c       = IASet.BrandImage__c;
            IAS.BrandCSS__c         = IASet.BrandCSS__c;
            //IAS.BrandIHTooltip__c   = IASet.BrandIHTooltip__c;
            IAS.BrandUXOption__c   = IASet.BrandUXOption__c;
            IAS.CustomStyles__c     = IASet.CustomStyles__c;
            
            IAS.TrackDaysCallouts__c = IASet.TrackDaysCallouts__c;
            IAS.TrackDaysTopics__c = IASet.TrackDaysTopics__c;
            IAS.TrackDaysComments__c = IASet.TrackDaysComments__c;
            IAS.TrackDaysErrors__c = IASet.TrackDaysErrors__c;      
            IAS.TrackDaysResources__c = IASet.TrackDaysResources__c;        
            IAS.TrackDaysSearches__c = IASet.TrackDaysSearches__c;      
            IAS.TrackDaysVotes__c = IASet.TrackDaysVotes__c;      
            IAS.TrackDaysLUXOps__c = IASet.TrackDaysLUXOps__c;      
            
            IAS.AllowLayoutComments__c = IASet.AllowLayoutComments__c;
            IAS.DebugMode__c = IASet.DebugMode__c;
            
            IAS.DefaultHelpTopic__c = IASet.DefaultHelpTopic__c;
            IAS.DefaultHelpTopicTemplate__c = IASet.DefaultHelpTopicTemplate__c;
            IAS.DefaultHelpCalloutTemplate__c = IASet.DefaultHelpCalloutTemplate__c;
            //IAS.DefaultGuideTemplate__c = IASet.DefaultGuideTemplate__c;
            IAS.ImageUploadFolder__c = IASet.ImageUploadFolder__c;
            
            IAS.DefaultRelationshipSemanticTag__c = IASet.DefaultRelationshipSemanticTag__c;
            
            IAS.CalloutWidth__c = IASet.CalloutWidth__c;
            IAS.CalloutClosureBehaviour__c = IASet.CalloutClosureBehaviour__c;
            IAS.DefaultHelpActiveStatus__c = IASet.DefaultHelpActiveStatus__c;
            IAS.DefaultReadMoreOption__c = IASet.DefaultReadMoreOption__c;
            IAS.DefaultHelpTopicHBS__c = IASet.DefaultHelpTopicHBS__c;
            IAS.ReviewWithinDays__c = IASet.ReviewWithinDays__c;
            IAS.UpdateMarkerHours__c = IASet.UpdateMarkerHours__c;
            IAS.DefaultVisibility__c = IASet.DefaultVisibility__c;
            
            //IAS.UserAdviceMissingElement__c = IASet.UserAdviceMissingElement__c;
            //IAS.UserAdviceMissingTopic__c = IASet.UserAdviceMissingTopic__c;
            //IAS.UserAdviceMissingTemplate__c = IASet.UserAdviceMissingTemplate__c;
            //IAS.UserAdvicePrintShelfLife__c = IASet.UserAdvicePrintShelfLife__c;
            //IAS.UserAdviceCommentLogged__c = IASet.UserAdviceCommentLogged__c;
            
            IAS.DocumentationInstallationDate__c = IASet.DocumentationInstallationDate__c;
            IAS.DocumentationVersion__c = IASet.DocumentationVersion__c; 
            
            IAS.SFObjectIds__c = IASet.SFObjectIds__c;
            IAS.SFPod__c = IASet.SFPod__c;
            
            
            // Get whitelisting metadata for use in our member data / for display on settings page
            try {
                CIWhitelistedDomains = getWhitelistedDomainsData();
                
            } catch (exception ex) {
                // Do nothing: settings initialisation creates this record if requried 
            }           
            
            // Get the config data holding LUX styling info for use by our member data / display on settings page
            try {
                CICustomerCSS = getCustomerCSSData();
                
            } catch (exception ex) {
                // Do nothing: settings screen offers button to populate this if desired
            }           
            
            
        } catch (exception e) {
            Diags = 'An error occurred attempting to show your Organisation`s global settings. If this is a new installation, you may need to create these: ' + e.getMessage();
            DiagsConfigIssue = mapDlgLocs.get('AdviceLabelSettingsNotInitialised');
        }       
        
        return;
    }
    
    
    // Saves any changes made to settings 
    public void saveSettings() {
        
        String uCheck;
        ServiceSecurity Security = new ServiceSecurity();
        Diags = '';
        
        // Ability to manage settings is based on user rights
        try {
            if (Security.IsAllowed(ServiceSecurity.KnownSecureOperations.AdministerHelp)) {
                
                // Perform certain checks on settings before save:
                // [1] Re-default brand logo if blanked:
                if (IAS.BrandImage__c == '') {
                    IAS.BrandImage__c = '/resource/iahelp__IHResources/img/LogoToolsPage.svg';
                    Diags += mapDlgLocs.get('MessageBrandImageReset') + '... ';
                }
                
                
                // Check that global links are correctly defined:
                uCheck = validateQL(IAS.QuickLink1__c, IAS.QuickText1__c, IAS.QuickTip1__c);
                if (uCheck != '') {
                    Diags = mapDlgLocs.get('MessageQuickLinkError') + ' 1 - ' + uCheck;
                    return;
                }
                
                
                uCheck = validateQL(IAS.QuickLink2__c, IAS.QuickText2__c, IAS.QuickTip2__c);
                if (uCheck != '') {
                    Diags = mapDlgLocs.get('MessageQuickLinkError') + ' 2 - ' + uCheck;
                    return;
                }
                
                uCheck = validateQL(IAS.QuickLink3__c, IAS.QuickText3__c, IAS.QuickTip3__c);
                if (uCheck != '') {
                    Diags = mapDlgLocs.get('MessageQuickLinkError') + ' 3 - ' + uCheck;
                    return;
                }
                
                uCheck = validateQL(IAS.QuickLink4__c, IAS.QuickText4__c, IAS.QuickTip4__c);
                if (uCheck != '') {
                    Diags = mapDlgLocs.get('MessageQuickLinkError') + ' 4 - ' + uCheck;
                    return;
                }
                
                uCheck = validateQL(IAS.QuickLink5__c, IAS.QuickText5__c, IAS.QuickTip5__c);
                if (uCheck != '') {
                    Diags = mapDlgLocs.get('MessageQuickLinkError') + ' 5 - ' + uCheck;
                    return;
                }
                
                
                // Now ensure URLs themselves have protocol attached
                IAS.QuickLink1__c = validateURL(IAS.QuickLink1__c);
                IAS.QuickLink2__c = validateURL(IAS.QuickLink2__c);
                IAS.QuickLink3__c = validateURL(IAS.QuickLink3__c);
                IAS.QuickLink4__c = validateURL(IAS.QuickLink4__c);
                IAS.QuickLink5__c = validateURL(IAS.QuickLink5__c);
                
                
                update IAS;
                
                // Save whitelisting metadata if this was ever initialised / created
                if (CIWhitelistedDomains != null) {
                    upsert CIWhitelistedDomains;
                }
                
                // Save customer Lighttning CSS data if created
                if (CICustomerCSS != null) {
                    upsert CICustomerCSS;
                }
                
                
                Diags += mapGlbLocs.get('MessageSaved');
                
            } else {
                Diags = mapGlbLocs.get('MessageNoRights');
            }
            
        } catch (exception e) {
            Diags = mapGlbLocs.get('MessageGenericError') + ' - ' + e.getMessage();
        }
        
        showSettings();
        return;
    }
    
    
    // Cancels any pending changes to global settings
    public PageReference cancelSettingsChanges() {
        return new PageReference(SFURL + '/apex/iahelp__IHManageSettings');
    }
    
    
    // Resets height before scrolling for all existing help topics to that specified by the user
    public void resetHBS() {
        
        Diags = '';
        
        ServiceSecurity Security = new ServiceSecurity();
        
        try {
            
            // Ability to mass update is based on user rights
            if (Security.IsAllowed(ServiceSecurity.KnownSecureOperations.AdministerHelp) == false && Security.IsAllowed(ServiceSecurity.KnownSecureOperations.EditHelp) == false) {
                Diags = mapGlbLocs.get('MessageNoRights'); 
                
            } else {
                String q = 'SELECT Id FROM HelpTopic__c';
                String f = 'HeightBeforeScrolling__c';
                Decimal v = IAS.DefaultHelpTopicHBS__c;
                
                // Use an instance of our mass updating class to perform this, passing in
                // the selection query to define records, the field to update and the value to set...           
                Id batchInstanceId = Database.executeBatch(new ServiceMassOps(q, f, v));        
                
                // Save the height value entered as part of settings
                saveSettings();             
                Diags += ' - ' + mapDlgLocs.get('MessageHBSReset');               
            }
            
            
        } catch (exception e) {
            Diags = Diags = mapGlbLocs.get('MessageGenericError') + ' - ' + e.getMessage();
        }
        
        return;
    }
    
    
    // Adds interaction retention processing to SF's scheduled tasks
    // NB: this is delegated to InteractionController class...
    public void scheduleRetention() {
        
        String retVal;
        
        ServiceSecurity Security = new ServiceSecurity();
        
        // Ability to schedule retention is based on user rights
        if (Security.IsAllowed(ServiceSecurity.KnownSecureOperations.AdministerHelp) == false) {
            retVal = mapGlbLocs.get('MessageNoRights');
            
        } else {
            try {
                ServiceInteractions svsI = new ServiceInteractions();
                if (svsI.startRetention() == true) {
                    retVal = mapGlbLocs.get('MessageGenericTaskComplete');
                } else {
                    retVal = svsI.Diags;
                }
                
            } catch (exception e) {
                retVal = e.getMessage();
            }
            
        }
        
        Diags = retVal;
        
        return;
    }
    
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // CALLS TO STORE AND RETRIEVE METADATA 
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    
    // Split large blocks of layout config data (string) into chuncks small enough to "fit" in config data records,
    // then replaces any existing such records with the results:
    // Metadata can be of various kinds - ActionCode is used as a differentiator for (eg) layout info vs custom object info
    public static string chunkAndStoreMetadata (string LayoutInfo, string MetadataType) {
        System.debug('LayoutInfo>>>>>>>>>>'+LayoutInfo);
        System.debug('MetadataType>>>>>>>>>>'+MetadataType);
        
        string retVal;
        ConfigurationItem__c[] CIs;
        ConfigurationItem__c CI;
        integer chunkSize = 100000;
        integer chunkNum = 0;
        ServiceSecurity Security = new ServiceSecurity();
        String Diags='';
        
        // Check rights
        Boolean[] UPs = Security.UserPermissions();
        Boolean isAdministrator = UPs[2];
        
        if (!isAdministrator) {
            map<string, string>GlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false);
            Diags = GlbLocs.get('MessageNoRights');
            return null;
            
        } else {  
            try {
                try {               
                    // Delete any existing configuration items holding meta data of the specified type
                    CIs = [SELECT Id, ActionCode__c, Description__c, IconClass__c, IconContent__c, ToolClass__c, Label__c, TipText__c, 
                           DisplayGrouping__c, DisplayOrder__c, HasDivider__c,
                           NegotiateToolbarLevel__c, PermissionLevel__c, SupportingControls__c,
                           ToggleActiveMarker__c, ToggleNext__c, TogglePrev__c,
                           ToolContext__c, ToolFilter__c, Type__c
                           FROM ConfigurationItem__c 
                           WHERE Type__c = 'ConfigurationData'
                           AND ActionCode__c = :MetadataType];
                    
                    delete CIs;
                    
                } catch (exception ex) {}
                
                
                CIs = new ConfigurationItem__c[]{};
                    
                    // Need to split the layout information into chunks small enough to hold in records
                    while (chunkNum * chunkSize < LayoutInfo.length()) {
                        CI = new ConfigurationItem__c();        
                        
                        CI.ActionCode__c = MetadataType;
                        CI.Description__c = 'This record stores data about Salesforce metadata and is not used as a clickable action';  
                        CI.IconClass__c = 'fa-cog';
                        CI.Label__c = 'Metadata only';
                        CI.TipText__c = 'NOT FOR USE AS A CLICKABLE';
                        CI.DisplayGrouping__c = 'N/A';
                        CI.DisplayOrder__c = chunkNum;
                        CI.HasDivider__c = false;
                        CI.IconContent__c = '';
                        CI.NegotiateToolbarLevel__c = 0;
                        CI.PermissionLevel__c = 1;      
                        CI.SkipImportOverwrite__c = true;
                        CI.SkipExport__c = true;
                        
                        if ((chunkNum + 1) * chunkSize < LayoutInfo.length()) {
                            CI.SupportingControls__c = LayoutInfo.subString(chunkNum * chunkSize, (chunkNum + 1) * chunkSize);
                        } else {
                            CI.SupportingControls__c = LayoutInfo.subString(chunkNum * chunkSize, LayoutInfo.length());
                        }
                        
                        CI.ToggleActiveMarker__c = '';
                        CI.ToggleNext__c = 0;
                        CI.TogglePrev__c = 0;
                        CI.ToolClass__c = '';
                        CI.ToolContext__c = '[Hidden]';
                        CI.ToolFilter__c = 0;
                        CI.Type__c = 'ConfigurationData';
                        
                        CIs.add(CI);
                        chunkNum += 1;
                    }
                
                upsert CIs;
                retVal = ''; 
                
            } catch (exception e) {
                retVal = 'ERR! (Chunk and Store Metadata Info): ' + e.getMessage();
            }   
        }  
        return retVal;
    } 
    
    
    // Get our stored details of page layout assignments
    public static string getStoredMetadata(string MetadataType) {
        
        string LayoutInfo = '';
        ConfigurationItem__c[] CIs;
        
        try {
            
            // Concatenate the chunks of layout data from the configuration items that hold them
            for (ConfigurationItem__c CI : [SELECT Id, SupportingControls__c
                                            FROM ConfigurationItem__c 
                                            WHERE Type__c = 'ConfigurationData'
                                            AND ActionCode__c = :MetadataType
                                            ORDER BY DisplayOrder__c]) {
                                                
                                                LayoutInfo += CI.SupportingControls__c;
                                            }
            
        } catch (exception ex) {
        }
        
        return LayoutInfo;
        
    }
    
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // CALLS TO SEED SETTINGS AND METADATA
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    
    // Create the template and other records required to seed an Improved Help installation
    public void seedHelpSettings () {
        
        zInstallHandler zIH;
        
        try {
            
            // NB: cannot secure this by role as roles won't exist on install...
            zIH = new zInstallHandler();
            zIH.seedHelpSettings();
            
            if (zIH.Diags != '') {
                Diags = mapGlbLocs.get('MessageGenericTaskComplete') + ' - ' + zIH.Diags;
            } else {
                Diags = mapGlbLocs.get('MessageGenericTaskComplete');
            }
            
        } catch (exception e) {
            Diags = mapGlbLocs.get('MessageGenericError') + ' - ' + e.getMessage();
        }
        
        return;
    }   
    
    
    // Populate the 'customer css' (lightning styling data) configuration item from 'model' resource (delegated to install handler)
    public void seedCSSTextFromFile () {
        
        zInstallHandler zIH;
        boolean retVal;
        
        try {
            
            // NB: cannot secure this by role as roles won't exist on install...
            zIH = new zInstallHandler();
            retVal = zIH.seedCSSTextFromFile();
            
            if (retVal == true) {
                if (zIH.Diags != '') {
                    Diags = mapGlbLocs.get('MessageGenericTaskComplete') + ' - ' + zIH.Diags;
                } else {
                    Diags = mapGlbLocs.get('MessageGenericTaskComplete');
                }
                
            } else {
                Diags = mapGlbLocs.get('MessageGenericError') + ' - ' + zIH.Diags;
            }
            
        } catch (exception e) {
            Diags = mapGlbLocs.get('MessageGenericError') + ' - ' + e.getMessage();
        }
        
        return;
        
    }  
    
    
    // Seek page layout to profile / record type information and store this in JSON format for later use
    public void seedProfileLayouts () {
        
        string LayoutInfo;
        string chunkResult;
        ConfigurationItem__c[] CIs;
        
        
        try {
            // Get the layout information
            LayoutInfo = ServiceSchema.getAllProfileLayouts();
            
            // Need to split the layout information into chunks small enough to hold in records
            chunkResult = chunkAndStoreMetadata(LayoutInfo, 'GetSFPageLayouts');
            
            if (chunkResult == '') {
                // All is well
                Diags = mapGlbLocs.get('MessageGenericTaskComplete');               
            } else {
                Diags = mapGlbLocs.get('MessageGenericError') + ' - ' + chunkResult;
            }           
            
        } catch (exception e) { 
            Diags = mapGlbLocs.get('MessageGenericError') + ' - ' + e.getMessage();
        }
        
        return;
    }
    
    
    // Create help documentation from an XML SF doc specified by the user
    public void seedDocsFromUserDoc() {
        try {
            if(UserXMLDoc == '') {
                Diags = mapDlgLocs.get('MessageEnterXMLPath');
            } else {
                seedDocumentation(UserXMLDoc);              
            }
        } catch (exception e) {
            Diags = mapGlbLocs.get('MessageGenericError') + ' - ' + e.getMessage();
        }       
        return;     
    }
    
    
    // Create help configuration tools records from a JSON SF doc specified by the user.
    public void seedConfigFromUserDoc() {
        try {
            if(UserJSONDoc == '') {
                Diags = mapDlgLocs.get('MessageEnterJSONPath');
            } else {
                seedConfigurationTools(UserJSONDoc);
            }
        } catch (exception e) {
            Diags = mapGlbLocs.get('MessageGenericError') + ' - ' + e.getMessage();
        }       
        return;     
    }
    
    // Make calls to check picklists in key areas of the Help schema are updated:
    // This call is raised from our config tool creation code (seedConfigurationTools) to ensure the required
    // tool contexts / config item types etc are in play, however we also use this opportunity to seed
    // other pick list values.
    
    public void UpdatePicklistValueSet(List<ConfigurationItem__c> LXTsDel , List<ConfigurationItem__c> LXTsOut){
        
        string objname;                                             // API name of object whose pick lists are to be populated
        map<string,string> picval  = new map<string,string>();      // Map of picklist Field API name to valueset.
        
        // Converting to JSON String because custom parameters are not able to pass to future methods.
        String LXTsDelStr = JSON.serialize(LXTsDel);//Convert the List of ConfigurationItems to JSON string.
        String LXTsOutStr = JSON.serialize(LXTsOut);//Convert the List of ConfigurationItems to JSON string.
        
        // Configuration item pick lists
        objname = 'iahelp__ConfigurationItem__c';         
        picval.put('iahelp__Type__c','AuthorConfiguration,Body,ConfigurationData,Drop-down,Ellipsis,Extension,Footer,Header,Listing,ProductVersion,WizardStep,WizardStepBodyTool'); //Map of field APIName and valueSet.
        picval.put('iahelp__ToolContext__c','[Hidden],[Template],AlertOKOnly,Builder,CardAutoForm,CardAutoForm_TopicViewer,CardComment,CardComment_Listing,CardHelpTopic,CardKeywords,CardReadingLists,CardRelatedHelp,CardRelatedTags,CardResources,CardStickies,CardTags,CardTree,CardTreeOtherList,CardTreeSearchList,CGDesignMode,FixedHelp,GEModeTopicSearchList,IHLUXApp_Settings_Tabs,ImageViewer,LinkResources,LinkTopics,NewSticky,PositionDetector,PositionDetectorCG,PositionDetectorHelpButtons,PositionDetectorHelpRequests,QAM,QAMHelpIndex_Topic,QAMHelpIndex_Tree,QuickStartU1_Tree,ReadingListBuilder_Topic,ReadingListBuilder_Topic_Autoform,ReadingListBuilder_Tree,ReconfigureMode_Topic,ReconfigureMode_Topic_Autoform,ReconfigureMode_Tree,RLViewer,tabsTest1,Test,wizBulkTopicUpload,wizCxtHelp,wizCxtHelp_Step1_List,wizCxtHelp_Step2_List,wizTest');
        ServiceSchema.UpdateValueSet(objname,picval,LXTsDelStr,LXTsOutStr);  
        
        // Only supply config items in first call: no need to keep upserting
        LXTsDelStr = '';
        LXTsOutStr = '';
        
        // Reading List pick lists
        objname = 'iahelp__HelpReadingList__c';         
        picval.put('iahelp__LightningPresentationStyle__c','Adopter,Adopter - Minimal Topic,Adopter - Topic Viewer,Carousel,Standard'); 
        ServiceSchema.UpdateValueSet(objname,picval,LXTsDelStr,LXTsOutStr);  
        
    }     
    
    
    // Create help configuration tool records from the specified JSON file (a resource or document).
    public void seedConfigurationTools (String JSONPath) {
        
        PageReference P;
        Blob bInfo;     
        List<ConfigurationItem__c> LXTsIn;
        List<ConfigurationItem__c> LXTsDel;
        List<ConfigurationItem__c> LXTsOut = new List<ConfigurationItem__c> {};
            ConfigurationItem__c LXT;
        ServiceSecurity Security = new ServiceSecurity();
        try {
            Diags = 'Seeding configuration from file: ' + JSONPath + '... ';
            // Get the JSON from specified file
            P = new PageReference(JSONPath);
            bInfo = P.getContent();    
            Diags += 'Content of document obtained... ';
            // Re-construct configuration records from this
            LXTsIn = (List<ConfigurationItem__c>) JSON.deserialize(bInfo.toString(), List<ConfigurationItem__c>.class); 
            Diags += LXTsIn.size() + ' tools... ';
            // Check rights
            Boolean[] UPs = Security.UserPermissions();
            Boolean bAdministrator = UPs[2];
            
            if (!bAdministrator) {
                Diags = mapGlbLocs.get('MessageNoRights');
                
            } else {
                // Get existing configuration records for deletion:
                // v1.40+ : do NOT delete items marked for retention / locally defined and not to be overwritten
                LXTsDel = [SELECT Id FROM ConfigurationItem__c WHERE SkipImportOverwrite__c = false];
                
                // We cannot keep the IDs and they're not important: so "cross load" the config records into new ones
                for (ConfigurationItem__c L : LXTsIn) {
                    LXT = new ConfigurationItem__c();
                    
                    LXT.ActionCode__c = L.ActionCode__c; 
                    LXT.Description__c = L.Description__c; 
                    LXT.DisplayGrouping__c = L.DisplayGrouping__c; 
                    LXT.DisplayOrder__c = L.DisplayOrder__c; 
                    LXT.HasDivider__c = L.HasDivider__c; 
                    LXT.IconClass__c = L.IconClass__c; 
                    LXT.IconContent__c = L.IconContent__c; 
                    LXT.Label__c = L.Label__c; 
                    LXT.NegotiateToolbarLevel__c = L.NegotiateToolbarLevel__c;              
                    LXT.PermissionLevel__c = L.PermissionLevel__c;
                    LXT.SkipExport__c = L.SkipExport__c;
                    LXT.SkipImportOverwrite__c = L.SkipImportOverwrite__c;
                    LXT.SupportingControls__c = L.SupportingControls__c;
                    LXT.TipText__c = L.TipText__c; 
                    LXT.ToggleActiveMarker__c = L.ToggleActiveMarker__c;
                    LXT.ToggleNext__c = L.ToggleNext__c; 
                    LXT.TogglePrev__c = L.TogglePrev__c; 
                    LXT.ToolClass__c = L.ToolClass__c; 
                    LXT.ToolContext__c = L.ToolContext__c; 
                    LXT.ToolFilter__c = L.ToolFilter__c; 
                    LXT.Type__c = L.Type__c; 
                    
                    LXTsOut.add(LXT);
                }
                // Delete existing config tools and create the new ones.
                // v1.54.n + : Before doing this, make calls to ensure that config item pick lists
                // have the desired values available to them. This is necessary as, without these values, upsert
                // may fail (though we no longer limit to pick list values). Upgrades do not add pick list values
                // so our code needs to see to this manually. 
                // Pass in details of the config items to create / delete so future call can handle these
                // once pick lists are correctly populated:
                
                //insert LXTsOut;
                //delete LXTsDel;                
                
                UpdatePicklistValueSet(LXTsDel , LXTsOut); // Calling to future method for updating the picklist valueSet.
                
                Diags = mapGlbLocs.get('MessageGenericTaskComplete') + ': ' + LXTsOut.size() + ' ' + mapGlbLocs.get('MessageGenericNewRecords');                           
            } 
            
            
        } catch (exception e) {
            Diags = mapGlbLocs.get('MessageGenericError') + ' - ' + e.getMessage();
        }
        
        return;
    }
    
    
    // Create help documentation from the materials shipped with the product
    public void seedDocsFromIHResources() {
        try {
            // Check rights before proceeding
            ServiceSecurity Security = new ServiceSecurity();
            if (Security.IsAllowed(ServiceSecurity.KnownSecureOperations.AdministerHelp)) {
                
                // v.1.30 - allow docs to be sourced from one of several shipped resources
                seedDocumentation('/resource/iahelp__IHResources/doc/' + theSelectedHelpSeedResource);
                
                // Record the date and version of documentation installed
                system.version v = system.requestVersion();
                IAS.DocumentationVersion__c = v.major() + '.' + v.minor();
                IAS.DocumentationInstallationDate__c = Datetime.now();
                update IAS;
                
            }
            
        } catch (exception e) {
            Diags = mapGlbLocs.get('MessageGenericError') + ' - ' + e.getMessage();
        }       
        return;
    }
    
    
    // Seed documentation from user XML, but via an asynchronous call
    public void seedDocsFromUserDocASynch() {
        
        if(UserXMLDoc == '') {
            Diags = mapDlgLocs.get('MessageEnterXMLPath');
        } else {
            ControllerSettings.seedDocsFromUserDocAS(UserXMLDoc);
            
            // Advise user to monitor via Apex jobs (same message as height before scrolling reset)
            Diags = mapDlgLocs.get('MessageHBSReset');
        }       
    }
    @Future(callout=true)    
    public static void seedDocsFromUserDocAS(string XPath) {
        ControllerSettings CS;
        try {
            CS = new ControllerSettings();  
            CS.seedDocumentation(XPath);
            
        } catch (exception e) {
            if (CS != null) {
                system.debug('Error running asynchronous Help content upload (seedDocsFromUserDocAS): ' + e.getMessage() + ': ' + CS.Diags);        
            } else {
                system.debug('Error running asynchronous Help content upload (seedDocsFromUserDocAS): ' + e.getMessage());        
            }
        }
        
    }
    
    
    // Download the Help Content that would be in Excel but via JSON / asynchronous call 
    public void downloadDataJSONASynch() {
        ControllerSettings.downloadDataJSONAS();
    }
    @Future(callout=true)
    public static void downloadDataJSONAS() {
        zInstallHandler zIH = new zInstallHandler();
        
        zIH.ExportRows = 3000;  //10000;
        zIH.ExportDataJSONDoc();
    }    
    
    
    // Create help documentation from the specified XML file (a resource or document)
    public void seedDocumentation (String XMLPath) {
        zInstallHandler zIH;
        PageReference P;
        Blob bInfo;     
        
        try {
            
            // NB: cannot secure this by role as roles won't exist on install...
            zIH = new zInstallHandler();
            
            // Default IH documentation is supplied as XML in the resources zip file:
            // Get the XML from this file in static resource
            p = new PageReference(XMLPath);
            bInfo = P.getContent();                     
            
            if (zIH.seedDocumentation(bInfo.toString()) == true) {
                Diags = mapGlbLocs.get('MessageGenericTaskComplete') + ' - ' + zIH.Diags;               
            } else {
                Diags = mapGlbLocs.get('MessageGenericError') + ' - ' + zIH.Diags;             
            }
            
            
        } catch (exception e) {
            Diags = mapGlbLocs.get('MessageGenericError') + ' - ' + e.getMessage() + ' - ' + zIH.Diags;
        }
        
        
        return;
        
    }
    
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    //COMMUNITIES SUPPORT - ADDRESS DERIVATION FUNCTIONS
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    
    private static ConnectApi.Community getCommunityInfo(){
        
        try {
            String communityId = Network.getNetworkId();
            
            if (communityId!=null) {
                return connectapi.Communities.getCommunity(communityId);
            } else {
                return null;
            }
            
        } catch (exception e) {
            return null;            
        }
    }
    
    
    // Returns [full root]/[community prefix], or empty string if not in a community
    public static string getCommunityRoot() {
        
        try {
            ConnectApi.Community C = getCommunityInfo(); 
            return C.siteUrl;
        } catch (exception e) {
            return '';
        }
    }
    
    
    // Returns [community prefix], or empty string if not in a community
    public static string getCommunityPrefix() {     
        
        string retVal;
        
        try {
            ConnectApi.Community C = getCommunityInfo(); 
            retVal = C.urlPathPrefix;
            
            if (retVal == null || retVal + '' == 'null') {
                retVal = '';
            }
        } catch (exception e) {
            retVal = '';
        }
        
        return retVal;
    }
    
    
    // Returns a string array of domain-related information:
    //      Element 0 = 'true' if the incoming URL features in the domains table, otherwise 'false'
    //      Element 1 = the community prefix for this domain, or an empty string if incoming URL is not part of a domain site
    //      Element 2 = Diagnostics
    private string[] DInfo = null;    
    public static string[] getDomainInfo(string PageURL) {
        
        string CPrefix = '';
        string isDomain = 'false';    
        string D = '';    
        D += 'getDomainInfo: Incoming URL: ' + PageURL + '... ';
        
        try {
            // v1.38+ (For SF API v41+): attempting construction of a URL without a path results in un-trappable error!         
            if (PageURL == '' || PageURL == null) {PageURL = 'https://NoPageURLSupplied.com';}          
            URL U = new System.Url(PageURL);
            
            D += 'U Path: ' + U.getPath() + '... ';
            D += 'U Host: ' + U.getHost() + '... ';
            
            // Is root domain of address in the domains table?
            Domain Dom = [SELECT id FROM Domain WHERE Domain=:U.getHost()];
            isDomain = 'true';
            D += 'Found Domain: ' + Dom.Id + '... ';
            
            // If so, get matching DomainSite records
            try {
                for (DomainSite DS : [SELECT PathPrefix FROM DomainSite WHERE DomainId=:Dom.Id]) {
                    
                    string test = DS.PathPrefix;
                    D += 'Testing U Path against prefix "' + test + '"... ';
                    
                    if (test.endsWith('/s')) {test = test.subString(0, test.length()-2);}
                    
                    // For each path prefix, search for this after domain root
                    if ((U.getPath().startsWith(test + '/') || U.getPath().startsWith('/' + test + '/')) && test != '' && test != null) {
                        // If prefix is present, this is Community Root
                        if (test.startsWith('/')) {
                            CPrefix = test.subString(1);
                        } else {
                            CPrefix = test;
                        }
                        
                        D += 'U Path contains PathPrefix - CPrefix is "' + CPrefix + '"... ';                       
                        break;
                    }
                }
                
            } catch (exception exc) {
                // If no Domain Sites found, no Community Root in play...
                D += 'DomainSites not found... ';                       
            }
            
        } catch (Exception ex) {
            // If root not in domains table, Community Root may still be in play...
            isDomain = 'false';         
            CPrefix = getCommunityPrefix();
            D += 'Domain not found... CPrefix set by getCommunityPrefix to "' + CPrefix + '"... ';          
        }
        
        return new string[] {isDomain, CPrefix, D};
            }
    
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // CONSOLE SUPPORT
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    
    // Advises whether current page is being viewed via an SF console tab page 
    public static Boolean isConsolePage() {
        
        // NOTE: This can ONLY be relied upon when first opening a tab:
        // any navigation on the tab will lose the "isdtp" parameter and
        // will therefore be indistinguishable from any other context: 
        // Clients must make their own arrangements to deal with this issue.
        try {
            // v1.36.5+ : VF override pages viewed from LUX were getting confused by presence of 'isdtp' 
            // into acting as Console and thus hiding any included QAM: need to also check origin param
            // for evidence of a LUX page hosting the override and, if present, proceed as normal (NOT act as Console)
            string LUXO = ApexPages.currentPage().getParameters().get('sfdcIFrameOrigin');
            if (LUXO == null) {LUXO = '';}
            
            return ApexPages.currentPage().getParameters().get('isdtp') != null && LUXO.indexOf('.lightning.force') == -1;
            //return ApexPages.currentPage().getParameters().get('isdtp') != null;
            
        } catch (exception e) {
            return false;
        }
    }
    
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // OTHER UTILITY FUNCTIONS
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    
    // Ensures link URLs have a protocol string attached
    private String validateURL (string uLink) {
        
        String retVal;
        
        try {
            retVal = uLink;         
            if (retVal.indexOf('://') == -1  && (retVal != '' && retVal != null)) {
                retVal = 'http://' + retVal;
            }
            
        } catch (exception e) {
            // On error, return URL as was
            retVal = uLink;
        }
        
        return retVal;
    }
    
    
    // Checks quick link details are suitable
    private String validateQL(String uLink, String uText, String uTip) {
        
        String retVal;
        
        try {
            // Default to OK
            retVal = '';
            
            // If URL is present, text should also be present: 
            if (uLink != '' && uLink != null) {
                if (uText == '' || uText == null) {
                    retVal = mapDlgLocs.get('MessageQuickLinkRequiresLinkText');
                }
            }
            
            // If text is present, URL should also be present:
            if (uText != '' && uText != null) {
                if (uLink == '' || uLink == null) {
                    retVal = mapDlgLocs.get('MessageQuickLinkRequiresURL');
                }
            }
            
            // If Tip is present, URL and link should be present:
            if (uTip != '' && uTip != null) {
                if (uText == '' || uText == null || uLink == '' || uLink == null) {
                    retVal = mapDlgLocs.get('MessageQuickLinkRequiresLinkAndURL');
                } 
            }
            
        } catch (exception e) {
            retVal = mapGlbLocs.get('MessageGenericError') + ' - ' + e.getMessage();
        }
        
        return retVal;
        
    }   
    
}