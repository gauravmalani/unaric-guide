/////////////////////////////////////////////////////////////////////////////////////////////////////
// CONTROLLER CLASS FOR PAGES SEEKING TO OFFER USERS THE CHANCE TO CONFIRM THEIR ACTIONS 
// BEFORE THEY ARE COMMITTED
//
// Martin Little for Improved Apps
// August 2013
/////////////////////////////////////////////////////////////////////////////////////////////////////


public with sharing class ControllerConfirmActions {

    // Global settings info
    public static String getBrandCSS() {return ControllerSettings.getSettings().BrandCSS__c;}
    public static String getD1() {return ControllerSettings.D1;}
    public static String getD2() {return ControllerSettings.D2;}

    // For UI localisations /multi language support (labels, messages etc)
    private map<string, string>mapDlgLocs;
    private map<string, string>mapGlbLocs;
    private map<string, string>mapWSVLocs;
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

    public String Diags {get; set;}                             // Diagnostics messages 
    public String Opts {get; set;}                              // Controls visibility of certain page options
    public String Params {get; set;}                            // Parameters controlling selected option
    public Boolean optionalFeaturesSave {get; set;}             // Control availability of "Save" option
    
    // FOR OPTION 1 - Confirm Help Enabling Activity
    public String HPLName {get; set;}                           //
    public String HPLId {get; set;}                             // Featured SF object
    public String GuideId {get; set;}                           // 1.39+ : record of Guide in play when in (LUX) GE scenarios
    public Boolean HPLIsNew {get; set;}                         // 
    public ControllerSearch.SearchResult[] elemsC {get; set;}   // Helped Elements to create
    public ControllerSearch.SearchResult[] elemsD {get; set;}   // Helped Elements to delete
        
    private Boolean[] Perms;
    private String callerPageURL;
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Private utility functions
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    
    // Setup member data etc
    public void initialise () {
        
        try {
            // Note user permissions
            ServiceSecurity Security = new ServiceSecurity();        
            Perms = Security.UserPermissions();         
            
            // Get localisation information (field labels etc):
            // We need a mix of "global", "branding" and cross screen labels and those which are screen specific.
            // The latter depends on the page being served...
            ControllerSettings cS = new ControllerSettings();

            mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false); 
            mapBrdLocs = ServiceLocalisation.getDialogueLocalisations('Branding', false);
            if (Test.isRunningTest()) {
                // Page address will not be "real" if we're in test mode, so hard wire dialogue name in these cases
                mapDlgLocs = ServiceLocalisation.getDialogueLocalisations('iahelp__IHConfirmActions', false);
            } else {
                mapDlgLocs = ServiceLocalisation.getDialogueLocalisations(cS.SFObjId(Url.getCurrentRequestUrl().toExternalForm()), true);
            }

            // We also borrow some localisations from Web Services, with which we work closely...
            mapWSVLocs = ServiceLocalisation.getDialogueLocalisations('WServices', false);

            
            Diags = '';
            HPLIsNew = true;
            optionalFeaturesSave = false;
            elemsC = new ControllerSearch.SearchResult[]{};
            elemsD = new ControllerSearch.SearchResult[]{};
                        
        } catch (exception e) {         
        }

        return;
    }
    
    
    // Extract query parameters from incoming URL
    private void getQueryParms() {
                
        Opts = ServiceSecurity.getQueryParameter('Opts', 2);

        Params = ApexPages.currentPage().getParameters().get('Params');
        if(Params == null) {Params = '';}
        
        Params = EncodingUtil.urlDecode(Params, 'UTF-8');
        
        return;
    }
    
    
    // Obtain details of Reading List, if available, from its id
    private HelpReadingList__c getRLFromId(String RLID) {
        
        HelpReadingList__c HRL;
        
        try {
            HRL = [SELECT Id, Name FROM HelpReadingList__c WHERE Id = :RLID];
                                                       
        } catch (exception f) {
            // Do nothing here...
        }
                            
        return HRL;
    }

    
    // Obtain details of Helped Page Layout, if available, from its layout identifier
    private HelpedPageLayout__c getHPLFromId(String PgId) {
        
        HelpedPageLayout__c HPL;
        
        try {
            HelpedPageLayout__c[] HP = [SELECT Id, Name, PageLayoutIdentifier__c FROM HelpedPageLayout__c WHERE PageLayoutIdentifier__c = :PgId];
            
            // This may return 1+ layouts - as SOQL is case insensitive - so we need to check we find
            // exactly the one we're after...
            for (HelpedPageLayout__c L : HP) {
                if (L.PageLayoutIdentifier__c.equals(PgId) == true) {
                    HPL = L;
                    break;                  
                }
            }
            
            // Note the fact that this was an existing layout
            HPLIsNew = false;
                                           
        } catch (exception f) {
            // Do nothing here - create layout below...
        }
                    
        if (HPL == null) {   
             
            // If there's no hepled page layout yet, we need to create one here...
            HPL = new HelpedPageLayout__c();
            Schema.Describesobjectresult objInfo;
            ServiceSchema sS = new ServiceSchema();
            
            // We want the name of our new layout to be that of the underlying
            // SF standard or custom object if we can
            objInfo = sS.getObjectDetails(PgId);
            
            if (objInfo == null) {
                HPL.Name = mapWSVLocs.get('ValueDraftLayout') + ' ' + PgId;                         
            } else {
                HPL.Name = objInfo.getLabelPlural() + ' ' + mapWSVLocs.get('ValueLayout');                          
            }
            
            HPL.PageLayoutIdentifier__c = PgId;
            HPL.PageType__c = 'Standard';
            
            // Note the fact that layout was new...
            if (objInfo == null) {
                HPLIsNew = true;
            }
                            
        }
        
        return HPL;
    }
    
    
    // Returns an integer reflecting the number of records referencing the given record ID (excluding record itself):
    //  n = number of referring records
    // -1 = processing error.
    private Integer RefCount (String RecordId) {
        
        Integer retVal = 0;
        HelpedElement__c[] HEs;
        HelpReadinglistEntry__c[] RLEs;
        HelpRelationship__c[] HRs;
        
        try {
            
            // Conduct searches seeking the given ID
            try {
                HEs = [SELECT Id FROM HelpedElement__c WHERE HelpTopic__c = :RecordId];
                retVal += HEs.size();
            } catch (exception e) {}
            
            try {
                RLEs = [SELECT Id FROM HelpReadinglistEntry__c WHERE HelpTopic__c = :RecordId];
                retVal += RLEs.size();
            } catch (exception e) {}

            try {
                HRs = [SELECT Id FROM HelpRelationship__c WHERE ReferringTopic__c = :RecordId OR RelatedHelpTopic__c = :RecordId];
                retVal += HRs.size();
            } catch (exception e) {}
            
        } catch (exception e) {
            retVal = -1;
            Diags = e.getMessage();
        }
        

        return retVal;
    }
    
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Public interface
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    
    // Page entry point - Show list of actions to user for confirmation
    public PageReference showActions() {
        
        Integer i;                          // For looping
        Boolean globalFailure = false;      // Flag indicating Save should be disabled
                        
                        
        // Initialise member data               
        initialise();
        getQueryParms();
        
        
        // Treat lack of any permissions as a problem (as we must check FLS).
        // So: no Help Permission Set assisnments at all = same effect as no subscription...            
        if (! (Perms[0] || Perms[1] || Perms[2] || Perms[3])) {
            Diags = mapGlbLocs.get('MessageNoPermissions');
            optionalFeaturesSave = false;
            return null;
        } 
        
        
        // If operation = 1: Confirm Help Enabling Actions...
        if (Opts == '1') {
            
            String[] Ps;                // "Params" query parameter split into basic array
            String[] eC;                // From this, split array of elements to be created
            String[] tC;                // From this, split array of their types
            String[] eD;                // From this, split array of elements to be deleted
            String[] tD;                // From this, split array of their types
            String nullMarker = '|';    // Value representing no value supplied - eg no elems to be helped
            String DisableDelete;       // Flag indicating element's help topic cannot be deleted
            ControllerSettings cS = new ControllerSettings();
            ControllerSearch.SearchResult sR;
            HelpedPageLayout__c HPL;
            HelpedElement__c[] HEs;
            String HTID;
            
            
            // Check user has permissions to carry out this operation
            if (!Perms[1] && !Perms[2]) {
                // You do not have the permissions required to carry out this operation
                Diags = mapGlbLocs.get('MessageNoRights');
                return null;
            } 
            
            // Parameters should be in the form:
            // [Help Enabled Page URL][D2]
            // ["D1" delimited string of elements to be helped][D2]
            // ["D1" delimited string of types of the above][D2]
            // ["D1" delimited string of elements to be un-helped][D2]
            // ["D1" delimited string of types of the above][D2]
            
            
            if (Params != '') {
                
                Ps = Params.split(getD2());
                
                if (Ps.size() != 5) {
                    // The parameters required for confirming Help Enabling activity were not supplied in the correct format
                    Diags = mapGlbLocs.get('MessageBadParameters');
                    
                } else {
                    
                    // Note incoming helped page URL
                    callerPageURL = Ps[0];
                    
                    // Derive SF object ID from this
                    HPLId = cS.SFObjId(callerPageURL);
                    
                    // Check whether or not this exists (NB: call sets HPLIsNew as reqd)
                    HPL = getHPLFromId(HPLId);
                    HPLName = HPL.Name;                    

                    eC = Ps[1].split(getD1());
                    tC = Ps[2].split(getD1());
                    eD = Ps[3].split(getD1());
                    tD = Ps[4].split(getD1());
                    
                    if (eC.size() != tC.size() || eD.size() != tD.size()) {
                        // The parameters required for confirming Help Enabling activity were not supplied in the correct format
                        Diags = mapGlbLocs.get('MessageBadParameters');
                        
                    } else {
                        // Loop around elements to be created / deleted as garnered from URL params
                        // adding to collections of these to present to user as we go
                        
                        // CREATES
                        for (i = 0; i < eC.size(); i++) {      
                            
                            // Ignore cases depicting "no value supplied"
                            if (eC[i] != nullMarker) {
                                sR = new ControllerSearch.SearchResult();
                                
                                // Id is used by confirm page to hold Id of
                                // any existing help topic to associate (blank = new topic)
                                sR.Id = '';             
                                sR.Name = eC[i]; 
                                sR.Link = 'true';
                                sR.Summary = tC[i];
                                elemsC.add(sR);                         
                            }                   
                        }
    
                        // DELETES
                        for (i = 0; i < eD.size(); i++) {                           

                            // Ignore cases depicting "no value supplied"
                            if (eD[i] != nullMarker) {
                                
                                // If the element has been identified as "help for this page"
                                // the underlying identifier will be the record type's object identifier:
                                // I.e., HPL identifier
                                String EID = eD[i];

                                if(tD[i].toUpperCase() == 'PAGE HELP LINK') {
                                    EID = HPL.PageLayoutIdentifier__c;
                                }                               
                                
                                // Get helped element HTIDs for use by confirms page
                                try {
                                    HEs = [SELECT HelpTopic__c, Visibility__c, DataDrivenFilter__c 
                                            FROM HelpedElement__c 
                                            WHERE HelpedPageLayout__c = :HPL.Id
                                            AND Identifier__c = :EID];

                                    for (HelpedElement__c HE : HEs) {
                                        
                                        sR = new ControllerSearch.SearchResult();
                                        
                                        // Id is used by confirm page to signify whether or
                                        // not to delete related help topic
                                        sR.Id = 'False';
                                        sR.Link = 'true';                                       
                                        HTID = HE.HelpTopic__c;
                                        
                                        // Work out whether this topic may be deleted:
                                        // NB: to allow deletes, there should be precisely 1 referring record
                                        // (the helped element being listed here)
                                        if (RefCount(HE.HelpTopic__c) == 1) {
                                            DisableDelete = '0';
                                        } else {
                                            DisableDelete = '1';
                                        }   
                                        
                                        
                                        // Place helped element Id into the name field...
                                        sR.Name = HE.Id + getD1();


                                        // ...plus naming details that differentiate element contexts
                                        sR.Name += eD[i] + ' ('; 
                                        if (HE.Visibility__c != null) {
                                            sR.Name += HE.Visibility__c;
                                        } else {
                                            sR.Name += '-';
                                        }
                                        
                                        sR.Name += ':';
                                        
                                        if (HE.DataDrivenFilter__c != null) {
                                            sR.Name += ' ' + HE.DataDrivenFilter__c;
                                        } else {
                                            sR.Name += '-';
                                        }

                                        sR.Name += ')';

                                                                            
                                        // Use summary to store deletability, HTID, element type...
                                        sR.Summary = DisableDelete + getD2() + HTID + getD1() + tD[i];
                                        elemsD.add(sR);                         
                                    }
                                                                        
                                } catch (exception e) {
                                    // Setup "safe" values for this element result record
                                    sR = new ControllerSearch.SearchResult();
                                    
                                    // Id is used by confirm page to signify whether or
                                    // not to delete related help topic
                                    sR.Id = 'False';
                                    sR.Link = 'true';
                                    HTID = '';
                                    DisableDelete = '1';

                                    // Add error information into item name
                                    sR.Name = getD1() + mapGlbLocs.get('MessageGenericError') + ' - ' + e.getMessage();

                                    // Force save button to be disabled
                                    globalFailure = true;

                                    // Use summary to store deletability, HTID and summary text
                                    sR.Summary = DisableDelete + getD2() + HTID + getD1() + tD[i];
                                    elemsD.add(sR);                         
                                }
                            }                   
                        }
                        
                        // If you reach this point, Saving can be made available
                        // provided there have been no issues with individual helped elements
                        optionalFeaturesSave = !globalFailure;      
                                        
                                        
                    }   // End if element name & type counts match                                          
                }   // End if &Params supplied in correct format (5 delimited parts)
                
            } else {
                // The parameters required for confirming Help Enabling activity were not supplied in the correct format (none specified)
                Diags = mapGlbLocs.get('MessageBadParameters');
            }
            
        }   // End Option 1 - Help Enable confirmation
        

        // If Operation = 2: Confirm Guide Enabling actions
        if (Opts == '2') {

            String[] Recs;              // "Params" query parameter split into array of step records
            String[] Rec;               // An individual record split into fields
            Cookie ck;                  // For cookie manipulation
            ControllerSearch.SearchResult sR;
            
            
            // Value into which "%" is parsed in URL (See jsToggleHelp.saveHelper)
            String pctChar = String.fromCharArray(new List<integer>{6});        
            
            
            // Check user has permissions to carry out this operation
            if (!Perms[1] && !Perms[2]) {
                Diags = mapGlbLocs.get('MessageNoRights');
                return null;
            } 
            
            // Check we got parameters in URL
            if (Params != '') {
                
                // Retrieve details of the Guide being enabled from cookie (set on entry
                // to GE mode via the search results dialogue)
                ck = ApexPages.currentPage().getCookies().get('IHSelectedRL');

                if (ck == null) {
                    // If there is no cookie, use default values for member data
                    HPLName = mapWSVLocs.get('MessageErrorNoGuideDetails');                 
                    globalFailure = true;
                    
                } else {
                    // If cookie is present, use it to populate our member data
                    HelpReadingList__c HRL = getRLFromId(String.valueOf(ck.getValue()));
                    
                    if (HRL != null) {
                        HPLName = HRL.Name;

                    } else {
                        // If we don't get a Guide (reading list) it may be because
                        // the user wanted a new one...

                        if (String.valueOf(ck.getValue()) != 'NEW') {
                            // If this is NOT so, there is an issue
                            HPLName = mapWSVLocs.get('MessageErrorNoGuideDetails');
                            globalFailure = true;
                            
                        } else {
                            // If this WAS the case, note this and continue
                            HPLName = mapWSVLocs.get('ValueDraftGuide');
                            
                        } // End if cookie specified NEW guide
                    } // End if Guide record was located
                    
                    
                    if (globalFailure == false) {
                        
                        // Delete the "selected" RL cookie and place details in a "saving" cookie:
                        // this can be spotted by save routine, but will mean that confirms dlg itself
                        // is not in GE mode, and GE mode does not persist on any closure 
                        // (with or without save being done)

                        ck = new Cookie('IHSavingRL', String.valueOf(ck.getValue()), null, -1, false);
                        ApexPages.currentPage().setCookies(new Cookie[]{ck});
                        
                        ck = new Cookie('IHSelectedRL', 'SAVED', null, 1, false);
                        ApexPages.currentPage().setCookies(new Cookie[]{ck});                                   
                        

                        // Loop through records to show step info
                        Recs = Params.split(getD2());
                        for (String R : Recs) {

                            // Parameters within each step record should be in the form:
                            // RLE ID [D1] Step name [D1] Step Summary [D1] Step Order [D1] Element Id [D1] Element Type [D1] Dirt status [D2]
                            Rec = R.split(getD1());
        
                            // "%" characters get special treatment in transporting as urlDecode
                            // (see getQueryParms) has issues otherwise. See jsToggleHelp.saveHelper,
                            // which encodes values as required on placing them in the "cache", whose content
                            // is then packaged via jsToggleHelp.getConfirmGEActionsURL into our URL
                            
                            Rec[1] = Rec[1].replace(pctChar, '%');  // Step name
                            Rec[2] = Rec[2].replace(pctChar, '%');  // Step summary
                            Rec[4] = Rec[4].replace(pctChar, '%');  // Element Id
        
        
                            if (Rec.size() != 7) {
                                // Ensure each step record is as expected
                                Diags = mapGlbLocs.get('MessageBadParameters');
                                globalFailure = true;
                                
                            } else {
                                // Add a result for each incoming step record 
                                sR = new ControllerSearch.SearchResult();
                                                                
                                // Use summary for RLE Id, Element Type, step summary, order and dirty flag 
                                // Use link for confirm check box                                                               
                                sR.Id = Rec[4];
                                sR.Name = Rec[1];                               
                                sR.Summary = Rec[0] + getD1() + Rec[5] + getD1() + Rec[2] + getD1() + Rec[3] + getD1() + Rec[6];
                                sR.Link = 'true';
                                
                                // Separate step records into those to be added/edited and those to be
                                // deleted: there is a "dirty" flag in each step record that gives
                                // us this information...
                                
                                if (Rec[6] == 'D') {
                                    elemsD.add(sR);
                                } else {
                                    elemsC.add(sR);
                                }

                            }
                        }                       
                    } // End if no failure getting selected guide info          
                }
                
                
                // If you reach this point, Saving can be made available
                // provided there have been no issues
                optionalFeaturesSave = !globalFailure;      
                
                
            } else {
                // In Opt=2 / GE mode, if no params are provided, this means no changes
                // were made. In these cases, we want to clear the GE mode (selected RL) cookie
                // so that next screen refresh will take us out of guide enabling, plus redirect to 
                // a message screen advising that no changes were made
                
                ck = new Cookie('IHSelectedRL', 'SAVED', null, 1, false);
                ApexPages.currentPage().setCookies(new Cookie[]{ck});   
                
                // Use community path, if relevant, in any URLs returned below...
                String RootUrl = ControllerSettings.getCommunityRoot();
                if (RootUrl == '') {
                    RootUrl = URL.getOrgDomainURL().toExternalForm();
                }                           
                return new PageReference(RootUrl + '/apex/iahelp__IHMessage?Diags=' + mapWSVLocs.get('MessageNoChangesToGuide'));
                
            }   // End Option 2 - Guide Enable confirmation

        }

        return null;
    }


    // Required to expose caller URL to wrapping clients that do not wish to initialise via a "Show Actions" call or similar
    public void setCPURL (string U) {
        ControllerSettings cS = new ControllerSettings();
        this.callerPageURL = U;
        this.HPLId = cS.SFObjId(this.callerPageURL);
    }


    // Save any changes marked as confirmed
    public PageReference saveChanges() {
        
        Boolean isError = false;
        Diags = '';
        
        try {
            
            // Check permissions:
            Perms = null;
            ServiceSecurity Security = new ServiceSecurity();             
            Perms = Security.UserPermissions();                     
            
            
            // Action to take depends on specified confirmation Option
            
            // Help Enable confirmation
            if (Opts == '1') {
                
                // Check rights
                if (!Perms[1] && !Perms[2]) {
                    // You do not have the permissions required to carry out this operation
                    Diags = mapGlbLocs.get('MessageNoRights');

                } else {
                    
                    // Arrays of helped element info to be sent to create / delete calls
                    String[] HEIDs = new String[]{};
                    String[] URLs = new String[]{};
                    String[] eTypes = new String[]{};
                    String[] HTIDs = new String[]{};
                    
                    
                    // Loop around elements to be created...
                    for (ControllerSearch.SearchResult sR : elemsC) {
                        
                        // Only create elements still checked for creation
                        if (sR.Link == 'true') {

                            // NB: we need to look out for "page help" as we can't 
                            // use the name in the search result/shown on screen ("Help for this Page")
                            // as the identifier - which in these cases needs to be 
                            // the helped page layout identifier...

                            if (sR.Summary.toUpperCase() == 'PAGE HELP LINK') {                             
                                HEIDs.add(HPLId);
                                URLs.add(callerPageURL);
                                eTypes.add(sR.Summary);
                                HTIDs.add(sR.Id);                                                               

                            } else {
                                HEIDs.add(sR.Name);
                                URLs.add(callerPageURL);
                                eTypes.add(sR.Summary);
                                HTIDs.add(sR.Id);                                                               
                            }
                                                        
                        }
                    }
                    
                    Diags = WServices.createHelpedElements(HEIDs, URLs, eTypes, HTIDs);
                    if (Diags != '') Diags += '\n\n';


                    // Loop around elements to be deleted...
                    HEIDs = new String[]{};
                    URLs = new String[]{};
                    String[] delHTIDs = new String[]{};
                    
                    
                    for (ControllerSearch.SearchResult sR : elemsD) {
                        
                        if (sR.Link == 'true') {
                            
                            // Rem: summary & name search result fields contain various pieces of information 
                            // in delimited form: see showActions for details
                            
                            String[] Sumry = sR.Summary.split(getD1());
                            String[] NParts = sR.Name.split(getD1());
                            
                            HEIDs.add(NParts[0]);
                            URLs.add(callerPageURL);
                                                    
                            // Delete the related help topic, if we were asked to do so                         
                            if (sR.Id == 'true') {                              
                                Sumry = Sumry[0].split(getD2());
                                delHTIDs.add(Sumry[1]);                         
                            } else {
                                delHTIDs.add('');
                            }                           
                        }
                    }
                                        
                    Diags += WServices.deleteHelpedElements(HEIDs, delHTIDs);   
                    
                    
                }   // User had rights
            }   // End Option 1 - Help Enable
            
            
            // Guide Enable confirmation
            if (Opts == '2') {

                // Arrays of guide step info to be sent to upsert call
                String[] RLEIds = new String[]{};
                String[] PgIds = new String[]{};
                String[] ElemIds = new String[]{};
                String[] ElemTypes = new String[]{};
                String[] StepNames = new String[]{};
                String[] StepSummaries = new String[]{};
                String[] StepOrders = new String[]{};
                String[] StepImages = new String[]{};
                String[] StepVideos = new String[]{};
                boolean hasSteps = false;                  
                Cookie ck;
                String PgId;
                String GID;

                // Control switch for LUX/non- use. 
                boolean ApexPageExists = ServiceSecurity.ApexPageExists();               
               
                if (ApexPageExists) {                
                    // In these cases, we should have been passed an additional query string parameter
                    // which we'll need below...
                    PgId = ServiceSecurity.getQueryParameter('HPL', 2);
                    
                } else {
                    // In these cases, LUX caller should have set Caller Page URL via setCPURL - which notes related object code
                    PgId = this.HPLId;
                }                
                Diags = 'CCA Page Identifier is: '  + PgId + '... '; 
                

                // Check rights
                if (!Perms[1] && !Perms[2]) {
                    Diags = mapGlbLocs.get('MessageNoRights');
                    
                } else {
                    
                    // Get the ID of the Guide into which steps are to be upserted
                    if (ApexPageExists) { 
                        
                        // In VF scenarios, this means examining a cookie
                        ck = ApexPages.currentPage().getCookies().get('IHSavingRL');
                        if (ck == null) {
                            // If there is no cookie, we cannot proceed
                            Diags = mapWSVLocs.get('MessageErrorNoGuideDetails');
                            return null;
                        } else {
                            GID = String.valueOf(ck.getValue());
                        }                  
    
                    } else {
                        // In LUX this means examining additional member data that caller should have set
                        GID = this.GuideId;
                        if (GID == '' || GID == null) {
                            Diags = mapWSVLocs.get('MessageErrorNoGuideDetails');
                            return null;        
                        }
                    }                 
                    Diags += 'Guide to enable is: ' + GID + '... ';
                    
    
                    // 1.22 (amended 1.23) - only insert the new Guide if at least one of the steps is checked for creation
                    for (ControllerSearch.SearchResult sR : elemsC) {
                        if (sR.Link == 'true') {
                            hasSteps = true;
                            break;
                        }
                    }                       
    
                    
                    // If we're creating a new Guide, we need to create and record this here
                    if (GID == 'NEW') {
                        HelpReadingList__c HRL = new HelpReadingList__c();
                        HRL.Name = mapWSVLocs.get('ValueDraftGuide');
                        HRL.Summary__c = mapWSVLocs.get('ValueDraftGuideSummary');
                        HRL.ReadingListType__c = 'Linear Guide';
                        HRL.ReadingListStatus__c = 'New';
                        

                        if (hasSteps == true) {
                            insert HRL; 
                            GID = HRL.Id;                            

                            // Place Guide ID back into our public member data
                            this.GuideId = GID;

                            If (ApexPageExists) {                        
                                // Place Guide ID back in cookie
                                ck = new Cookie('IHSavingRL', GID, null, -1, false);
                                ApexPages.currentPage().setCookies(new Cookie[]{ck});
                            
                                // We'll also need to record this somewhere it will persist
                                // so it can be picked up by the RL viewer window when it opens at
                                // the end of guide enabling activity.
                                // (Selected RL MUST be deleted below so we don't re-enter GE mode)
                                Cookie ckNew = new Cookie('IHNewestGuide', HRL.Id, null, -1, false);
                                ApexPages.currentPage().setCookies(new Cookie[]{ckNew});
                            }                                                    
                        }                   
                    }


                    if (hasSteps == true) {
                    
                        // Loop around steps to be DELETED...
                        for (ControllerSearch.SearchResult sR : elemsD) {
                            
                            // Only delete elements still checked for creation
                            if (sR.Link == 'true') {
                                
                                // Summary is in the form:
                                // RLEId [D1] Element Type [D1] Summary [D1] Order (see showActions)
                                String[] sum = sR.Summary.split(getD1());                           
    
                                // Create arrays for use in upsert call
                                RLEIds.add(sum[0]);
                            }                           
                        }
                    
                        // Now do the guide step deletes
                        Diags += WServices.deleteGuideSteps(RLEIds);
                    
                    
                        // Empty parameter arrays prior to continuing
                        RLEIds.clear();
                    
                    
                        // Loop around steps to be UPSERTED...
                        for (ControllerSearch.SearchResult sR : elemsC) {
                            
                            // Only create elements still checked for creation
                            if (sR.Link == 'true') {
                                
                                // (See showActions): Summary is in the form:
                                // RLEId [D1] Element Type [D1] Summary [D1] Order 
                                
                                // v1.39+ LUX only: summary may have 2 additional parameters tacked on:
                                // RLEId [D1] Element Type [D1] Summary [D1] Order [D1] Image URL [D1] Video URL
                                
                                String[] sum = sR.Summary.split(getD1());                           
    
                                // Create arrays for use in upsert call
                                RLEIds.add(sum[0]);
                                PgIds.add(PgId);
                                ElemIds.add(sR.Id);
                                ElemTypes.add(sum[1]);
                                StepNames.add(sR.Name);
                                StepSummaries.add(sum[2]);
                                StepOrders.add(sum[3]);     
                                
                                if (sum.size() > 4) {
                                    StepImages.add(sum[4]);
                                    StepVideos.add(sum[5]);
                                }                            
                            }
                        }
                    
                        // Now do the guide step upserts
                        Diags += WServices.upsertGuideSteps(GID, RLEIds, PgIds, ElemIds, ElemTypes, StepNames, StepSummaries, StepOrders);
                    
                    
                        // Having made all required modifications, we should re-number steps
                        HelpReadingListEntry__c[] RLEs = [SELECT Id, ReadingOrder__c 
                                                            FROM HelpReadingListEntry__c 
                                                            WHERE HelpReadingList__c = :GID
                                                            ORDER BY ReadingOrder__c];
                        integer i = 0;
                    
                        for (HelpReadingListEntry__c RLE : RLEs) {
                            RLE.ReadingOrder__c = i;
                            i += 1;
                        }
                        
                        upsert RLEs;
                
                        
                    }   // End if steps were to be upserted             
                }   // End if user has authoring permissions
                
                                
                // Remove the saving Guide (RL) cookie if it still exists
                if (ApexPageExists) {                
                    ck = new Cookie('IHSavingRL', 'SAVED', null, 1, false);
                    ApexPages.currentPage().setCookies(new Cookie[]{ck});                                   
                }                
                
            }   // End Option 2 - Guide Enable
            
        } catch (exception e) {
            Diags += mapGlbLocs.get('MessageGenericError') + ' (Save Changes) - ' + e.getMessage();
            isError = true;
        }
        

        // Only allow save once
        optionalFeaturesSave = false;
        
        if (isError == false) {Diags += '\n\n' + mapGlbLocs.get('MessageRefreshForChangesAutomatic');}
        
        return null;
    }

}