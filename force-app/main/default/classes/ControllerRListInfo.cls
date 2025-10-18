/////////////////////////////////////////////////////////////////////////////////////////////////////
// PAGE CONTROLLER CLASS FOR VF PAGES THAT NEED TO INTERACT WITH OR DISPLAY DETAILS OF READING LISTS
//
// Martin Little for Improved Apps
// August 2012
/////////////////////////////////////////////////////////////////////////////////////////////////////


public with sharing class ControllerRListInfo {
    
    public Boolean DisableOpts {get; set;}                  // Should the "Link" feature be available?
    public String HTID {get; set;}                          // Help topic, if specified, to which Rl can be linked
    public String Diags {get; set;}                         // For status messages etc
    public String fld1 {get; set;}                          // For capture of various pieces of data via forms
    public String fld2 {get; set;}                          // For capture of various pieces of data via forms
    public String fld3 {get; set;}                          // For capture of various pieces of data via forms
    public String DialogueTitle {get; set;}                 // Mode-sensitive title to display at head of screens using this controller
    public Boolean optionalFeaturesRead {get; set;}         // Control visibility of read-only properties
    public Boolean optionalFeaturesNew {get; set;}          // Control visibility of "Add" options
    public Boolean optionalFeaturesEdit {get; set;}         // Control visibility of "Edit" options
    public Boolean optionalFeaturesBack {get; set;}         // Control visibility of "Back to SF" link
    public Boolean optionalFeaturesHistory {get; set;}      // Control visibility of "History" report link
    public Boolean isLightBox {get; set;}                   // Switches screen display style to lighboxed dialogue
    public String Mode {get; set;}                          // Mode for editing controls
    public Boolean isUserOnly {get; set;}                   // True if user is NOT an admin / author / analyst
    public Boolean isNotUser {get; set;}                    // True is user has NO IH permissions
    
    public Boolean isIHLUX {get; set;}                      // True if parameter passed to indicate viewing via the Lightning UX
    public String PortalPage {get; set;}                    // The VF page to use as the Tools/Portal page
    
    
    // Global settings info - full URL of customer override stylesheet
    public static String getBrandCSS() {return ControllerSettings.getSettings().BrandCSS__c;}

    // Global settings info - allow export of RL to word processor format
    public static Boolean getEnableExportDoc() {return ControllerSettings.getSettings().EnableExportDocRL__c;}

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

    // A reading list that is being managed via our services code
    private ServiceIHLists.ReadingList RL;
    public ServiceIHLists.ReadingList getRList() { return RL; }
        
    // A reading list that is being managed as a SF object passed from standard controller
    private HelpReadingList__c HRL;
    
    
    private ServiceSecurity Security;
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Constructors
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    
    // For use in Lightning scenarios
    public ControllerRListInfo (string RLID) {
        try {
            HRL = [SELECT Id, ReadingListType__c FROM HelpReadingList__c WHERE Id=:RLID];
        } catch (exception e) {}
    }
    

    // Constructor required when this class is CONTROLLER, not extension
    public ControllerRListInfo () {
        initialise();
    }


    // Constructor used when SF calls pages using this class as a controller EXTENSION
    public ControllerRListInfo (ApexPages.StandardController stdController) {
        
        // Keep an internal copy of the incoming reading list object
        try {
            HRL = (HelpReadingList__c)stdController.getRecord();
                        
        } catch (exception e) {
            // No existing reading list specified (e.g., "new" mode)
        }
                
        // Initialise other values
        initialise();
    }

    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // For the manipulation and display of reading lists
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    private void initialise() {
        
        try {
            Security = new ServiceSecurity();
            
            Boolean[] Perms = Security.UserPermissions();   
            Boolean isUser = Perms[0];
            Boolean isAuthor = Perms[1];
            Boolean isAdministrator = Perms[2];
            Boolean isAnalysis = Perms[3];
            String showBack;
            String BackURL;
            
            // Get localisation information (field labels etc)
            ControllerSettings cS = new ControllerSettings();
            mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false); 
            mapBrdLocs = ServiceLocalisation.getDialogueLocalisations('Branding', false);
            if (Test.isRunningTest()) {
                // Page address will not be "real" if we're in test mode, so hard wire dialogue name in these cases
                mapDlgLocs = ServiceLocalisation.getDialogueLocalisations('iahelp__IHReadingListProperties', false);
            } else {
                mapDlgLocs = ServiceLocalisation.getDialogueLocalisations(cS.SFObjId(Url.getCurrentRequestUrl().toExternalForm()), true);
            }

            
            // NB: for the purposes of this controller, we need to know that someone is ONLY
            // a user (and not an author /admin etc) rather than the usual confirmation 
            // that someone merely has the HelpedUser permission set        
            isUserOnly = !isAnalysis && !isAuthor && !isAdministrator;          
            
            // Following setting tells more accurately that we're not a user AT ALL!
            isNotUser = !isUser && !isAnalysis && !isAuthor && !isAdministrator;            
            
            
            // Initialise all features to "safe" mode (i.e., read style)
            optionalFeaturesRead = true;
            optionalFeaturesEdit = false;
            optionalFeaturesNew = false;                
            optionalFeaturesBack = false;
            isLightBox = false;             
            DisableOpts = true;
            
            
            // Note incoming operational parameters
            HTID = ServiceSecurity.getQueryParameter('HTID', 2);
            Mode = ServiceSecurity.getQueryParameter('Mode', 2);
            showBack = ServiceSecurity.getQueryParameter('ShowBack', 2);
            Diags = ServiceSecurity.getQueryParameter('Diags', 0);  
            BackURL = ApexPages.currentPage().getParameters().get('BackURL');

            if (ApexPages.currentPage().getParameters().get('LightBox') == 'true') {isLightBox = true;}
            if (ApexPages.currentPage().getParameters().get('IHLUX') == 'true') {isIHLUX = true;} else {isIHLUX = false;}
            
            // Respond to global settings for LUX/classic - but ignore SF1 (IH1UX) here...
            PortalPage = ControllerSettings.getPortalPageName(false);

            // If mode was not set, assume this was a link from SF:
            if (Mode != null) {Mode = Mode.toUpperCase();}
            if (Mode != 'READ'  && Mode != 'EDIT' && Mode != 'NEW') {
                
                Mode = 'READ';
                
                // This implies "Back" link should be visible
                optionalFeaturesBack = true;
                showBack = 'true';
                
                // Also implies we should display in a "lighboxed" style
                isLightbox = true;
            }

            
            // Also, show back link if specifically instructed
            if (showBack == 'true') {
                optionalFeaturesBack = true;
                
                // In doing this, record the back URL in a cookie so we get back reliably:
                // NB - only do this if there isn't already a value in place (as this
                // should get removed on use and may not be sent with every query string)
                Cookie ck = ApexPages.currentPage().getCookies().get('IHBackURL');
                if (ck == null && BackURL != '' && BackURL != null) {
                    ck = new Cookie('IHBackURL', BackURL, null, -1, false);
                    ApexPages.currentPage().setCookies(new Cookie[]{ck});                                                       
                }
            }
            
            
            // We also need to check for certain SF-type URLs (as we're overriding these)
            if (ApexPages.currentPage().getParameters().get('save_new') != null){
                // This is a sign of adding
                Mode = 'NEW';
            } else if (ApexPages.currentPage().getParameters().get('retURL') != null) {
                // This is a sign of editing
                Mode = 'EDIT';
            }
            
            
            // Set report link visibility according to user rights
            // (But see also NEW mode, below)
            optionalFeaturesHistory = isAdministrator || isAuthor;
            
            
            // Set screen title and other options according to mode
            if (Mode == 'READ'){
                DialogueTitle = mapDlgLocs.get('TitleDialogueTitleRead');   
                if (HRL != null) {DialogueTitle += ': ' + HRL.Name;}            
                
                // We want only basic details visible
                optionalFeaturesRead = true;
                optionalFeaturesEdit = false;
                optionalFeaturesNew = false;
            }
            

            if (Mode == 'EDIT'){
                DialogueTitle = mapDlgLocs.get('TitleDialogueTitleEdit');   
                if (HRL != null) {DialogueTitle += ': ' + HRL.Name;}            
                
                // Availability dependent on user rights
                if (isAdministrator || isAuthor) {

                    // Allow edits but hide New links
                    optionalFeaturesRead = false;
                    optionalFeaturesEdit = true;
                    optionalFeaturesNew = false;

                } else {
                    Diags = mapGlbLocs.get('MessageNoRights');
                    Mode = 'READ';          
                }
            }


            if (Mode == 'NEW'){
                DialogueTitle = mapDlgLocs.get('TitleDialogueTitleNew');    
                
                // Availability dependent on user rights
                if (isAdministrator || isAuthor) {

                    // Availability of the "Create and Link" function/button requires HTID to be specified
                    if (HTID == null || HTID == 'null' || HTID == '') {
                        HTID = '';
                        DisableOpts = true;
                    } else {
                        DisableOpts = false;
                    }
    
                    // Show New links - but also edit fields (these will be used differently / initially blank)
                    optionalFeaturesRead = false;
                    optionalFeaturesEdit = true;
                    optionalFeaturesNew = true;
                    
                    // No history is available when creating a new RL
                    optionalFeaturesHistory = false;
                    
                    // Default owner to current user
                    HRL.OwnerId = UserInfo.getUserId();

                } else {
                    Diags = mapGlbLocs.get('MessageNoRights');
                    Mode = 'READ';          
                }
            }

            
        } catch (exception e) {
            Diags = mapGlbLocs.get('MessageGenericError') + ' - ' + e.getMessage();
            Mode = 'READ';          
        }
                
    }   



// A version of create and link for Lightning / non-VF page parameter driven scenarios
public string createAndLinkFromLUX(string HTID) {
    
    string retVal;
    
    try {
        
        // Check user rights before allowing creation
        if (!Security.IsAllowed(ServiceSecurity.KnownSecureOperations.AdministerHelp) && !Security.IsAllowed(ServiceSecurity.KnownSecureOperations.EditHelp)) {
            retVal = mapGlbLocs.get('MessageNoRights');
            
        } else {        
            
            // Create a new reading list with minimal details
            HRL = new HelpReadingList__c(); 
            HRL.Name = 'New Reading List';
            HRL.Summary__c = '';
            HRL.ReadingListType__c = 'Reading List';
            insert HRL;
            
            // Add entry for specified topic
            HelpReadingListEntry__c RLE = new HelpReadingListEntry__c();
            RLE.HelpReadingList__c = HRL.Id;
            RLE.HelpTopic__c = HTID;
            RLE.ReadingOrder__c = 0;
            
            insert RLE;
            
            retVal = HRL.Id;
        }
        
    } catch (exception e) {
        retVal = mapGlbLocs.get('MessageGenericError') + ' (Create and Link Reading List to Topic "' + HTID + '")- ' + e.getMessage();
        
        try {
            delete HRL;
        } catch (exception ex){}
    }
    
    return retVal;
}




    // Create a new reading list and link it to the specified (current) help topic
    public PageReference createAndLink() {
        
        String U;

        // Use community path, if relevant, in any URLs returned below...
        String RootUrl = ControllerSettings.getCommunityRoot();
        if (RootUrl == '') {
            RootUrl = URL.getOrgDomainURL().toExternalForm();
        }

        
        try {
            // Check user has rights
            if (!Security.IsAllowed(ServiceSecurity.KnownSecureOperations.AdministerHelp) && !Security.IsAllowed(ServiceSecurity.KnownSecureOperations.EditHelp)) {
                Diags = mapGlbLocs.get('MessageNoRights');
                return null;
                
            } else {
            
                // Save the incoming reading list
                insert HRL;
                
                // Link specified topic to this list
                HelpReadingListEntry__c RLE = new HelpReadingListEntry__c();
                RLE.ReadingOrder__c = 0;
                RLE.HelpTopic__c = HTID;
                RLE.HelpReadingList__c = HRL.Id;
                
                insert RLE;
                Diags = mapDlgLocs.get('MessageCreateAndLink');
                
                
                // Redirect RL properties to edit mode on newly created item 
                U = RootUrl + '/apex/iahelp__IHReadingListProperties?Id=' + HRL.Id  + '&IHLUX=' + isIHLUX + '&Mode=Read&Diags=' + Diags + '&ShowBack=' + OptionalFeaturesBack + '&LightBox=' + isLightBox;
                return new System.Pagereference(U);
                
            }
            
        } catch (exception e) {
            Diags = mapGlbLocs.get('MessageGenericError') + ' - ' + e.getMessage();
            return null;
        }
    }
    
    
    
    // Create a new reading list and link it to a new help topic
    public PageReference createAndNew() {
        
        String U;
        
        // Use community path, if relevant, in any URLs returned below...
        String RootUrl = ControllerSettings.getCommunityRoot();
        if (RootUrl == '') {
            RootUrl = URL.getOrgDomainURL().toExternalForm();
        }

        
        try {
            // Check user has rights
            if (!Security.IsAllowed(ServiceSecurity.KnownSecureOperations.AdministerHelp) && !Security.IsAllowed(ServiceSecurity.KnownSecureOperations.EditHelp)) {
                Diags = mapGlbLocs.get('MessageNoRights');
                return null;
                
            } else {
            
                // Create a new help topic: use our "help topic controller" to do this:
                ControllerHelpContent cH = new ControllerHelpContent();
                HelpTopic__c Hlp = cH.getDefaultHelpTopic();
                Hlp.Name = fld1;
                Hlp.Summary__c = fld2;
                insert Hlp;
                
                // Save the incoming reading list
                insert HRL;
                
                // Link the new topic to this list
                HelpReadingListEntry__c RLE = new HelpReadingListEntry__c();
                RLE.ReadingOrder__c = 0;
                RLE.HelpTopic__c = Hlp.Id;
                RLE.HelpReadingList__c = HRL.Id;
                insert RLE;

                Diags = mapDlgLocs.get('MessageCreateAndNew');

                // Redirect RL properties to edit mode on newly created item 
                U = RootUrl + '/apex/iahelp__IHReadingListProperties?Id=' + HRL.Id + '&IHLUX=' + isIHLUX + '&Mode=Read&Diags=' + Diags + '&ShowBack=' + OptionalFeaturesBack + '&LightBox=' + isLightBox;
                return new System.Pagereference(U);
                
            }
            
        } catch (exception e) {
            // Cater for the most common errors
            String S = e.getMessage();
            if(S.indexOf('REQUIRED_FIELD_MISSING') != -1) {
                Diags = mapDlgLocs.get('MessageCreateAndNewError');
            } else {
                Diags = mapGlbLocs.get('MessageGenericError') + ' - ' + e.getMessage();
            }
            
            return null;
        }
        
    }
    
    
    // Switch to Add mode
    public PageReference navToAddMode () {
        // Use community path, if relevant
        String RootUrl = ControllerSettings.getCommunityRoot();
        if (RootUrl == '') {
            RootUrl = URL.getOrgDomainURL().toExternalForm();
        }       
        return new PageReference(RootUrl + '/apex/iahelp__IHReadingListProperties?Mode=New&HTID=' + HTID + '&IHLUX=' + isIHLUX + '&ShowBack=' + optionalFeaturesBack + '&LightBox=' + isLightBox);            
    }


    // Switch to Edit mode
    public PageReference navToEditMode () {
        // Use community path, if relevant
        String RootUrl = ControllerSettings.getCommunityRoot();
        if (RootUrl == '') {
            RootUrl = URL.getOrgDomainURL().toExternalForm();
        }       
        return new PageReference(RootUrl + '/apex/iahelp__IHReadingListProperties?Id=' + HRL.Id + '&Mode=Edit&HTID=' + HTID + '&IHLUX=' + isIHLUX + '&ShowBack=' + optionalFeaturesBack + '&LightBox=' + isLightBox);         
    }
    
    
    // Save changes when in edit mode
    public PageReference saveReadingList() {

        // Use community path, if relevant
        String RootUrl = ControllerSettings.getCommunityRoot();
        if (RootUrl == '') {
            RootUrl = URL.getOrgDomainURL().toExternalForm();
        }       
        
        try {
            // Ensure permissions are as required
            Boolean[] Perms = Security.UserPermissions();
            if (! Perms[1] && ! Perms[2]) {
                Diags = mapGlbLocs.get('MessageNoRights');
                return null;
            }
            
            
            // Ensure we have an RL type
            if (HRL.ReadingListType__c == '' || HRL.ReadingListType__c == null) {
                HRL.ReadingListType__c = 'Reading List';
            }
            
            update HRL; 
            Diags = mapGlbLocs.get('MessageSaved');

            return new PageReference(RootUrl + '/apex/iahelp__IHReadingListProperties?Id=' + HRL.Id + '&Mode=Read&HTID=' + HTID + '&IHLUX=' + isIHLUX + '&Diags=' + Diags  + '&ShowBack=' + optionalFeaturesBack + '&LightBox=' + isLightBox);            
                    
        } catch (exception e) {
            Diags = mapGlbLocs.get('MessageGenericError') + ' - ' + e.getMessage();
            return null;
        }
        
    }


    // Cancel changes and re-nav to unedited page
    public PageReference cancelReadingListChanges () {
        // Use community path, if relevant
        String RootUrl = ControllerSettings.getCommunityRoot();
        if (RootUrl == '') {
            RootUrl = URL.getOrgDomainURL().toExternalForm();
        }       
        return new PageReference(RootUrl + '/apex/iahelp__IHReadingListProperties?Id=' + HRL.Id + '&Mode=Read&HTID=' + HTID + '&IHLUX=' + isIHLUX + '&ShowBack=' + optionalFeaturesBack + '&LightBox=' + isLightBox);            
    }


    // Delete the current reading list
    public PageReference deleteReadingList() {
                
        try {           
            // Ensure permissions are as required:
            // NB: in LUX we won't have initialised, so check we have a security object / create if required
            if (Security == null) {
                Security = new ServiceSecurity();
            }
            Boolean[] Perms = Security.UserPermissions();   
            Boolean isAuthor = Perms[1];
            
            if (!isAuthor) {
                Diags = mapGlbLocs.get('MessageNoRights');
                return null;
            }
            
            
            // Deleting RL will delete entries (by master detail) but we should also delete any 
            // HTs used by deleted RLEs that have no other references (Helped Elements or other RLEs)
            // This is ONLY the case for guide-type RLs
            
            if (HRL.ReadingListType__c == 'Linear Guide' ||HRL.ReadingListType__c == 'Non-Linear Guide') {

                Diags += 'Guide encountered, building HT checking criteria... ';                    

                String strCrit = '';
                String strSOQLHTs  = 'SELECT Id FROM HelpTopic__c WHERE ';
                HelpedElement__c[] refHEs;
                HelpReadingListEntry__c[] refRLEs;
                HelpTopic__c[] delHTs;


                // Get all RLE HTs
                HelpReadingListEntry__c[] delRLEs = [SELECT Id, HelpReadingList__c, HelpTopic__c
                                                    FROM HelpReadingListEntry__c 
                                                    WHERE HelpReadingList__c =: HRL.Id];

                // Build selection criteria to look for matches
                for (HelpReadingListEntry__c RLE : delRLEs) {                           
                    strCrit += '\'' + RLE.HelpTopic__c + '\',';
                }                       
                strCrit = strCrit.subString(0, strCrit.length() - 1);
                strSOQLHTs += 'Id IN (' + strCrit + ') AND Id NOT IN (';
                    

                // Is the topic referenced by each entry in use by any helped element?
                refHEs = database.query('SELECT Id, HelpTopic__c FROM HelpedElement__c WHERE HelpTopic__c IN (' + strCrit + ')');
                    
                // Matches must be added to list of those to retain
                for (HelpedElement__c HE : refHEs) {
                    strSOQLHTs += '\'' + HE.HelpTopic__c + '\',';
                }
                        
                if (refHEs.size() > 0) {
                    strSOQLHTs = strSOQLHTs.subString(0, strSOQLHTs.length() - 1);
                    Diags += 'At least 1 HE referencing RLE help topics were found... ';
                } else {
                    strSOQLHTs += '\'\'';                       
                    Diags += 'NO HEs referencing RLE help topics were found... ';
                }
                strSOQLHTs += ') AND Id NOT IN (';
                    
                Diags += 'Helped Element matches considered, continuing... ';


                // Is the topic referenced by each entry in use by any other RL (as an RLE)?
                // Use criteria to retieve referencing RLEs: we want details of ANY RLE apart from the current one:
                // We don't even care if it's another step in the same RL...

                refRLEs = database.query('SELECT Id, HelpTopic__c FROM HelpReadingListEntry__c WHERE HelpTopic__c IN (' + strCrit + ') AND HelpReadingList__c != \'' + HRL.Id + '\'');

                Diags += 'refRLEs size = ' + refRLEs.size() + ', continuing... ';                       
    
                for (HelpReadingListEntry__c E : refRLEs) {
                    strSOQLHTs += '\'' + E.HelpTopic__c + '\',';
                }
                if (refRLEs.size() > 0) {
                    strSOQLHTs = strSOQLHTs.subString(0, strSOQLHTs.length() - 1);
                    Diags += 'At least 1 RLE using same help topic was found... ';
                } else {
                    strSOQLHTs += '\'\'';                               
                    Diags += 'NO RLEs using same help topics were found... ';
                }
                strSOQLHTs += ')';
                
                Diags += 'Other RLs considered, continuing... ';
                    
                
                // Locate and delete any required HTs here...
                try {                   
                    delHTs = database.query(strSOQLHTs);
                    Diags += delHTs.size() + ' HTs to delete were found using criteria: ' + strSOQLHTs;
        
                    delete delHTs;
                    
                } catch (exception exc) {
                    // Attempt no HT deletes
                    Diags += 'Error attempting to delete HTs potentially related to a deleted RLE using criteria: ' + strSOQLHTs + '... ' + exc.getMessage() + '... ';
                }
            }   // End if this RL is a Guide
                
            
            // Now we can delete the RL itself.. 
            delete HRL;

            // Use community path, if relevant, in Urls returned below...
            String RootUrl = ControllerSettings.getCommunityRoot();
            if (RootUrl == '') {
                RootUrl = URL.getOrgDomainURL().toExternalForm();
            }       

            // Re-set diags before returning
            Diags = '';

            if (URL.getCurrentRequestUrl().toExternalForm().toUpperCase().indexOf('IHREADINGLISTPROPERTIES') != -1) {
                // If delete is requested from RL properties page, we can re-nav to "New" mode          
                return new PageReference(RootUrl + '/apex/iahelp__IHReadingListProperties?Mode=New&HTID=' + HTID + '&IHLUX=' + isIHLUX + '&ShowBack=' + optionalFeaturesBack + '&LightBox=' + isLightBox);               

            } else {
                // If not (e.g., from RL entries tab) we nav to entries page with no RL specified
                return new PageReference(RootUrl + '/apex/iahelp__IHManageReadingList');                
            } 

        } catch (exception e) {
            if (mapGlbLocs == null) {
                mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false); 
            }
            Diags = mapGlbLocs.get('MessageGenericError') + ' - ' + e.getMessage();
            return new pagereference('/apex/iahelp__IHMessage?Diags=' + Diags);
        }       
    }
    
    
    // Offer a route back to Salesforce if a user is view RL info having clicked a SF RL record
    public PageReference backToSF() {
        
        String U;

        // Use community path, if relevant
        String RootUrl = ControllerSettings.getCommunityRoot();
        if (RootUrl == '') {
            RootUrl = URL.getOrgDomainURL().toExternalForm();
        }       

        
        try {
            // If a back URL was specified, use it
            Cookie ck = ApexPages.currentPage().getCookies().get('IHBackURL');
            if (ck != null) {
                U = String.valueOf(ck.getValue());
                
                // Remove back URL cookie
                ck = new Cookie('IHBackURL', '', null, 1, false);
                ApexPages.currentPage().setCookies(new Cookie[]{ck});                                   
                
            } else {            
                String RLObjId = HRL.Id;
                RLObjId = RLObjId.substring(0,3);
                U = RootUrl + '/' + RLObjId;
            }
            
        } catch (exception e) {
            U = RootUrl;
        }
        
        return new PageReference(U);
    }
    
    
    // Show the Reading List History report
    public PageReference viewHistory() {
        String U;
        
        // Use community path, if relevant
        String RootUrl = ControllerSettings.getCommunityRoot();
        if (RootUrl == '') {
            RootUrl = URL.getOrgDomainURL().toExternalForm();
        }       
        
        try {
            // Check user has rights
            if (!Security.IsAllowed(ServiceSecurity.KnownSecureOperations.AdministerHelp) && !Security.IsAllowed(ServiceSecurity.KnownSecureOperations.EditHelp)) {
                Diags = mapGlbLocs.get('MessageNoRights');
                return null;
                
            } else {
                // 1.24.26: In case an unsuitable license type has been granted Author / Admin permission set,
                // check here that reports are available to the user...
                if (Schema.sObjectType.Report.isAccessible() && ServiceSecurity.CanRunReports()) {
                    Report Rpt = [SELECT Id, Name FROM Report  WHERE Name = 'Reading List: History Drill Thru Report'];
                    
                    String s = HRL.Name;                
                    s = EncodingUtil.urlEncode(s, 'UTF-8');
                    
                    U = RootUrl + '/' + Rpt.Id; 
                    U += '?pv0=' + s;
                    U += '&drilldown=1';                                                                
                    
                } else {
                    Diags = mapGlbLocs.get('MessageNoRights');
                    return null;
                }
            }
            
        } catch (exception e) {
            Diags = mapGlbLocs.get('MessageGenericError') + ' - ' + e.getMessage();
            return null;            
        }
        
        return new PageReference(U);        
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // For manipulation and display of reading list ENTRIES (delegated thru RList)
    /////////////////////////////////////////////////////////////////////////////////////////////////////

        
    // Entry point for the reading list management page - creates the desired reading list     
    public void getReadingList () {                   
        try {       
            
            // We should have been "initialised" at this point (see constructors)
            // so we can respond to a complete lack of IH permissions
            if (isNotUser) {
                Diags = mapGlbLocs.get('MessageNoPermissions');
                                
            } else {
                // Get the requested Reading List ID from our query string
                String LstId = ServiceSecurity.getQueryParameter('RLIST', 2);
                if(LstId == '') {LstId = '-1';}    
                                                
                // Use this to instantiate our reading list member data             
                RL = new ServiceIHLists.ReadingList(LstId);       
                
                // Use this to set RL object data in case we need it
                HRL = [SELECT Id, Name, ReadingListType__c FROM HelpReadingList__c WHERE Id=:RL.RLID];
            }
                                
                            
        } catch (exception e) {             
            Diags = e.getMessage();         
        }            
        
        return;     
    } 


    // The  reading list entry being manipulated - pass through to our reading list instance
    public String getclrMover ()            {if (RL != null) {return RL.Mover;} else {return null;}}
    public void   setclrMover(String value) {if (RL != null) {RL.Mover = value;}return;}
    
}