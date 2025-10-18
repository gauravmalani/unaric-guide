/////////////////////////////////////////////////////////////////////////////////////////////////////
// GENERATES POST-INSTALL DATA:
// AN IMPLEMENTATION OF THE INTERFACE REQUIRED TO CREATE THE REQUIRED RECORDS IN CLIENT
// ORGS AS IMPROVED HELP IS INSTALLED
//
// NB: most of this code is fired by button clicks - not automatically on install.
// SEE ALSO apex classes: SeedHelpSettingsBatch, SeedConfigFromUserDocQueueable, SeedDocsQueueable and UpdateValueSetQueueable
//
// TO DO: rationalise / de-duplicate code contained here, swapping out for calls to the above classes. 
//
// Martin Little for Improved Apps
// November 2012
/////////////////////////////////////////////////////////////////////////////////////////////////////

global with sharing class zInstallHandler implements InstallHandler {
    
    public String Diags {get; set;}
    
    // Create the required settings and records on installation
    global void onInstall(InstallContext context) {
        // Set the isInstalling flag to true in the custom setting
        iahelp__OnInstall__c installSetting = iahelp__OnInstall__c.getOrgDefaults();
        if (installSetting == null) {
            installSetting = new iahelp__OnInstall__c();
        }
        installSetting.iahelp__isInstalling__c = true;
        upsert installSetting;
        
        try {
            
            if(!Test.isRunningTest()){
                
                SeedHelpSettingsBatch batch = new SeedHelpSettingsBatch();
                Database.executeBatch(batch, 1);
                System.enqueueJob(new SeedConfigFromUserDocQueueable());  
            }
            
            // Can't do this here - as we're not allowed to use other classes that include With Sharing:
            // Our settings routine, of necessity, has these...
            //seedHelpSettings();
            
            // Instead, send an email advising ueer of next steps and with a link to settings page
            string Subject = 'Your Improved Help installation - Next Steps';
            string msgPlain = '';
            string msgHTML = '';
            PageReference P;
            
            
            // Get plain and HTML message texts from static resources
            // (Tests do not support this)
            if ( ! Test.isRunningTest()) {
                
                
                msgPlain += 'Thanks for installing Improved Help!';
                msgPlain += 'If you haven\'t done so already, now is a good time to review our "Help for Improved Help" documentation. ';
                msgPlain += 'To do this, please visit the "Welcome" page of the "Improved Help for Lightning" app. ';
                
                msgPlain += 'Note that tailored help is available for your role - whether Help Author, Help Administrator or Salesforce Sys Admin. ';
                msgPlain += 'If you need further assistance, please don\'t hesitate to contact support@improvedapps.com - Enjoy your day!';
                
                
                msgHTML += '<div style="font-family: verdana;">';
                msgHTML += '<div style="color: #004080; font-size: 30px; border-bottom: solid 1px; text-align: center; margin-bottom: 20px; padding-bottom: 5px;">';
                msgHTML += 'Thanks for installing Improved Help!';
                msgHTML += '</div>';
                
                msgHTML += '<b>If you haven\'t done so already, now is a good time to review our "Help for Improved Help" documentation.</b>';
                msgHTML += '<br/><br/>';
                
                msgHTML += 'To do this, please visit the ';
                msgHTML += '<a href="{Root}/lightning/n/iahelp__Welcome">';
                msgHTML += '"Welcome" page of the "Improved Help for Lightning" app.';
                msgHTML += '</a><br/><br/>';
                
                msgHTML += 'Note that tailored help is available for your role - whether Help Author, Help Administrator or Salesforce Sys Admin.';
                msgHTML += '<br/><br/>';
                msgHTML += 'If you need further assistance, please don\'t hesitate to contact ';
                msgHTML += '<a href="mailto:support@improvedapps.com" title="Contact Unaric Improved Apps Support...">';
                msgHTML += 'support@improvedapps.com';
                msgHTML += '</a>';
                msgHTML += '<br/><br/>';
                msgHTML += '<b>Enjoy your day!</b>';
                
                msgHTML += '</div>';
                
                
                // For the HTML message, parse out certain tokens
                msgHTML = msgHTML.replaceAll('\\{Root\\}', URL.getOrgDomainURL().toExternalForm());
            }
            
            generateEmail (Subject, msgPlain, msgHTML, context.installerID());
            
            Diags = 'Post install scripts processed';
        } catch (exception e) {
            Diags = 'Error running Improved Help Post-installation scripts: ' + e.getMessage();   
        }
        
        return;
    }
    
    
    // Routine to actually create settings
    public void seedHelpSettings() {
        // Execution of create settings via batch
        if (!Test.isRunningTest()) {
            SeedHelpSettingsBatch batch = new SeedHelpSettingsBatch();
            Database.executeBatch(batch, 1);
        }
    }
    
    
    
    // Populate the 'customer css' configuration item from 'model' CSS resource, if not already present
    public Boolean seedCSSTextFromFile () {
        
        map<string, string> mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false);    
        ServiceSecurity sS = new ServiceSecurity();
        Boolean[] UPs = sS.UserPermissions();
        
        Diags = '';
        
        if (UPs[2] == false) {
            Diags = mapGlbLocs.get('MessageNoRights');
            return false;
        }
        
        ConfigurationItem__c CI = ControllerSettings.getCustomerCSSData();
        
        // If we find this record, there is no need to act: create it if not
        if (CI == null) {
            
            string strTemp = '';
            try {
                PageReference P = new PageReference('/resource/iahelp__IHResources/css/help_customer_lux.css');
                
                strTemp = P.getContent().toString();              
            } catch (exception ex) {}
            
            
            CI = new ConfigurationItem__c();
            
            CI.ActionCode__c = 'GetCustomerCSS';
            CI.Description__c = 'This record stores customer styling data and is not used as a clickable action';
            CI.DisplayGrouping__c = 'N/A';
            CI.DisplayOrder__c = 0;
            CI.HasDivider__c = false;
            CI.IconClass__c  = 'fa-cog';
            CI.IconContent__c = '';
            CI.Label__c = 'Settings data only';
            CI.NegotiateToolbarLevel__c = 0;
            CI.PermissionLevel__c = 1;
            CI.SkipImportOverwrite__c = true;
            CI.SkipExport__c = true;
            CI.SupportingControls__c = strTemp;
            CI.TipText__c = 'NOT FOR USE AS A CLICKABLE';
            CI.ToggleActiveMarker__c = '';
            CI.ToggleNext__c = 0;
            CI.TogglePrev__c = 0;
            CI.ToolClass__c = '';
            CI.ToolContext__c = '[Hidden]';
            CI.ToolFilter__c = 0; 
            CI.Type__c = 'ConfigurationData';
            
            upsert CI;
            Diags += 'Customer CSS data created... ';
            
        } else {
            Diags += 'Customer CSS data retrieved... ';
        }
        
        
        return true;
        
    }
    
    
    // Routine to create help topics and reading lists from an XML string passed to it
    // (eg the contents of a file in our static resources or SF document)
    public Boolean seedDocumentation (String sXML) {
        
        Boolean retVal;
        Diags = '';
        integer currentRow = 0;         // For diagnostics about row number that caused any issues encountered
        string currentObject = '';      // Ditto - object being processed
        
        // Prepare to send success/issues email, as this is the only reliable means to get info to the caller:
        // Content is finalised on success / failure below as return value is set...
        string mailSubject = '';
        string msgP = '';
        string msgH = '';
        string CRP = String.fromCharArray(new List<integer>{10,13});
        string CRH = '<br/>';
        
        
        //For internationalisation of diagnostics etc
        map<string, string> mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false); 
        
        try {
            //--------------------------------------------------------------------------------------
            // Ensure user has permissions before continuing: Admin required...
            //--------------------------------------------------------------------------------------
            
            ServiceSecurity sS = new ServiceSecurity();
            Boolean[] UPs = sS.UserPermissions();
            // user permission is not present
            //  create help topics and reading lists from an XML string passed to it in post install script context.
            
            if (UPs[2] == false) {
                Diags = mapGlbLocs.get('MessageNoRights');
                return false;
            }
            
            //--------------------------------------------------------------------------------------
            // Additional declarations
            //--------------------------------------------------------------------------------------
            
            // For XML reading
            String sInfo;
            XMLStreamReader reader;
            
            // Incoming Help Topic details
            HelpTopic__c Hlp;
            HelpTopicTemplate__c HT;
            String HTID;
            String HTMasterTopicIdentifier;
            String HTName;
            String HTSummary;           
            String HTKeyword;            
            String HTDescription;
            String isDefault;
            HelpTopic__c HomeHT;
            String HTImageHeight;
            String HTImageWidth;
            String HTImageALTText;
            String HTImageCaption;
            String HTImageTitle;
            String HTImageURL;
            String HTVideoHeight;
            String HTVideoWidth;
            String HTVideoCaption;
            String HTVideoTitle;
            String HTVideoURL;
            String HTActive;
            String HTCalloutHeight;
            String HTCalloutMediaChoice;
            String HTCalloutTemplate;
            String HTHeightBeforeScrolling;
            String HTHelpTopicStatus;           
            String HTLightningTemplate;            
            String HTSalesforceHelpURL;
            String HTVisibility;
            String HTCustomStyle;
            String HTHVS;
            String HTShowReferringRelationships;
            String HTGuidedLayout;
            String HTGuidedRecord;
            String HTGuidedElement;
            String HTGuideStepMode;
            String HTGuideCallout;
            String HTShowReadMoreLink;
            String HTTemplate;
            Integer TopicCount = 0;
            
            // Incoming Help Relationship details
            HelpRelationship__c Rel;
            String RefT;
            String RelT;
            String sTag;
            String RelOrder;
            Integer RelCount = 0;
            
            // Incoming Reading List details
            HelpReadingList__c RL;
            String RLName;
            String RLSummary;
            String RLDescription;
            String[] RLFeaturedUntilParts;
            String RLStatus;
            Integer RLCount = 0;
            
            // Incoming Reading List Entry details
            HelpReadingListEntry__c RLE;
            String RLERL;
            String RLEHT;
            String DRow;
            String DCol;
            Integer RLECount = 0;
            
            // Incoming Resource details
            HelpResource__c HR;
            String HRID;
            String HRURL;
            Integer HRCount = 0;
            
            // Incoming Help Topic Resource details
            HelpTopicResource__c HTR;
            String HTRHR;
            String HTRHT;
            Integer HTRCount = 0;
            
            // Incoming Help filter and criterion details
            HelpFilter__c HF;
            String HFIdent;
            HelpFilterCriterion__c HFC;
            Integer HFCount = 0;
            Integer HFCCount = 0;
            
            // Incoming Helped Page Layout details
            HelpedPageLayout__c HPL;
            String HPLIdent;
            Integer HPLCount = 0;
            
            // Incoming Helped Element details
            HelpedElement__c HE;
            String HEDataDrivenFilter;
            Integer HECount = 0;
            
            // Author configurations logged count
            Integer AuthCCount = 0;
            
            
            // Working string
            String temp;
            
            
            // For getting default Help Topic details
            ControllerHelpContent cH = new ControllerHelpContent();
            HelpTopic__c defaultTopic;
            
            // Maps of incoming Ids to resultant objects record Ids
            Map<String, HelpTopic__c> mHTIDs = new Map<String, HelpTopic__c>();         
            Map<String, HelpReadingList__c> mRLIDs = new Map<String, HelpReadingList__c>();
            Map<String, HelpResource__c> mHRIDs = new Map<String, HelpResource__c>();
            
            Map<String, HelpFilter__c> mHFs = new Map<String, HelpFilter__c>();
            
            Map<String, HelpedPageLayout__c> mHPLs = new Map<String, HelpedPageLayout__c>();
            
            
            // Maps of existing improved help records (and the records and criteria required to build them)
            String Crit;
            HelpTopicTemplate__c[] Ts;
            HelpTopicTemplate__c[] TsLUX;
            SemanticTag__c[] sTags;         
            HelpTopic__c[] ExistingHTs;
            HelpRelationship__c[] ExistingRels;
            HelpReadingList__c[] ExistingRLs;
            HelpReadingListEntry__c[] ExistingRLEs;
            HelpResource__c[] ExistingRes;
            HelpTopicResource__c[] ExistingHRs;  
            
            HelpFilter__c[] ExistingHFs;
            HelpFilterCriterion__c[] ExistingHFCs;               
            
            HelpedPageLayout__c[] ExistingHPLs;
            HelpedElement__c[] ExistingHEs;
            
            Map<String, String> mTs = new Map<String, String>();
            Map<String, String> mTsLUX = new Map<String, String>();
            Map<String, SemanticTag__c> mSTags = new Map<String, SemanticTag__c>();
            Map<String, HelpTopic__c> mExistingHTs = new Map<String, HelpTopic__c>();
            Map<String, HelpRelationship__c> mExistingRels = new Map<String, HelpRelationship__c>();
            Map<String, HelpReadingList__c> mExistingRLs = new Map<String, HelpReadingList__c>();
            Map<String, HelpReadingListEntry__c> mExistingRLEs = new Map<String, HelpReadingListEntry__c>();
            Map<String, HelpResource__c> mExistingRes = new Map<String, HelpResource__c>();
            Map<String, HelpTopicResource__c> mExistingHRs = new Map<String, HelpTopicResource__c>();
            
            Map<String, HelpFilter__c> mExistingHFs = new Map<String, HelpFilter__c>();
            Map<String, HelpFilterCriterion__c> mExistingHFCs = new Map<String, HelpFilterCriterion__c>();
            
            Map<String, HelpedPageLayout__c> mExistingHPLs = new Map<String, HelpedPageLayout__c>();
            Map<String, HelpedElement__c> mExistingHEs = new Map<String, HelpedElement__c>();
            
            
            // Records we actually end up upserting
            HelpTopic__c[] UpsertHTs = new HelpTopic__c[]{};
                HelpRelationship__c[] UpsertRels = new HelpRelationship__c[]{};
                    HelpReadingList__c[] UpsertRLs = new HelpReadingList__c[]{};
                        HelpReadingListEntry__c[] UpsertRLEs = new HelpReadingListEntry__c[]{};
                            HelpResource__c[] UpsertRes = new HelpResource__c[]{};
                                HelpTopicResource__c[] UpsertHRs = new HelpTopicResource__c[]{};
                                    
                                    HelpFilter__c[] UpsertHFs = new HelpFilter__c[]{};
                                        HelpFilterCriterion__c[] UpsertHFCs = new HelpFilterCriterion__c[]{};      
                                            
                                            HelpedPageLayout__c[] UpsertHPLs = new HelpedPageLayout__c[]{};
                                                HelpedElement__c[] UpsertHEs = new HelpedElement__c[]{};
                                                    
                                                    
                                                    // Control variables to stop multiple attempted upserts
                                                    boolean upsertedHTs = false;
            boolean upsertedRels = false;
            boolean upsertedRLs = false;
            boolean upsertedRLEs = false;
            boolean upsertedRes = false;
            boolean upsertedHTRs = false;
            
            boolean upsertedHFs = false;
            boolean upsertedHFCs = false;
            
            boolean upsertedHPLs = false;
            boolean upsertedHEs = false;
            
            
            // Variables involved in map seek operations
            boolean seekByNS;
            string HEID;
            string HEP;
            string HEV;
            string HEF;
            string HEDDF;
            string D1 = ControllerSettings.D1;
            
            
            //--------------------------------------------------------------------------------------
            // Initialisation
            //--------------------------------------------------------------------------------------
            
            // Load the XML into a reader
            reader = new XMLStreamReader(sXML);
            
            
            // Get a copy of a help topic with default values we can use to populate any new records
            defaultTopic = cH.getDefaultHelpTopic();
            
            
            // Get ALL template records and load them into maps for later use         
            // Full and callout types
            Ts = [SELECT Id, PageURL__c FROM HelpTopicTemplate__c WHERE CreatedDate <= TODAY AND TemplateType__c != 'Lightning Viewer'];
            for (HelpTopicTemplate__c Temps : Ts) {
                mTs.put(Temps.PageURL__c, Temps.Id);  
                Diags += 'Added template "' + Temps.PageURL__c + '" to map under Id "' + Temps.Id +'"... ';             
            }
            // Lightning types
            TsLUX = [SELECT Id, Name FROM HelpTopicTemplate__c WHERE CreatedDate <= TODAY AND TemplateType__c = 'Lightning Viewer'];
            for (HelpTopicTemplate__c Temps : TsLUX) {
                mTsLUX.put(Temps.Name, Temps.Id);  
                Diags += 'Added LUX template "' + Temps.Name + '" to map under Id "' + Temps.Id +'"... ';             
            }
            
            
            // Ditto Semantic Tags (Relationship Types)
            sTags = [SELECT Id, Name FROM SemanticTag__c LIMIT 1000];           
            for (SemanticTag__c ST : sTags) {
                mSTags.put(ST.Name, ST);
            }
            
            /*
// ToDo: IDEALLY, WE WOULD NOT ATTEMPT TO ACCESS ALL RECORDS IN THE QUERIES THAT FOLLOW!
// INSTEAD, WE'D FILTER TO THOSE BEING UPLOADED...I.E., 
// Get any existing objects that MIGHT match those that are in the XML:
// We can only filter reliably by a single criteria, so do that: there will be false 
// positives in the records produced, so we put full criteria from each record into 
// a map that we check later in the code...

// Help Topics:
Crit = getObjectCriteria(sXML, 'HelpTopic', 'Name');
ExistingHTs = Database.query('SELECT Id, Name, Summary__c FROM HelpTopic__c WHERE Name IN(' + Crit + ')');
*/
            
            ExistingHTs = [SELECT Id, Name, Summary__c, MasterTopicIdentifier__c FROM HelpTopic__c WHERE CreatedDate <= TODAY];
            for (HelpTopic__c Topic : ExistingHTs) {
                
                // File existing help topics by Master Topic Identifier, if available,
                // or (as pre 1.43) name plus summary if not...
                
                if (Topic.MasterTopicIdentifier__c != '' && Topic.MasterTopicIdentifier__c != null) {
                    mExistingHTs.put(Topic.MasterTopicIdentifier__c, Topic);  
                } else {
                    mExistingHTs.put(Topic.Name + Topic.Summary__c, Topic);  
                }
            }
            
            
            // Ditto Help Relationships
            ExistingRels = [SELECT ReferringTopic__c, RelatedHelpTopic__c, SemanticTag__c, Order__c FROM HelpRelationship__c WHERE CreatedDate <= TODAY];
            for (HelpRelationship__c HRel : ExistingRels) {
                mExistingRels.put(HRel.ReferringTopic__c + '' + HRel.RelatedHelpTopic__c + '' + HRel.SemanticTag__c, HRel);  
            }
            
            // Ditto Help Reading Lists
            ExistingRLs = [SELECT Id, Name, Summary__c FROM HelpReadingList__c WHERE CreatedDate <= TODAY];
            for (HelpReadingList__c RLs : ExistingRLs) {
                mExistingRLs.put(RLs.Name + RLs.Summary__c, RLs);  
            }
            
            // Ditto Help Reading List Entries
            ExistingRLEs = [SELECT Id, HelpReadingList__c, HelpTopic__c FROM HelpReadingListEntry__c WHERE CreatedDate <= TODAY];
            for (HelpReadingListEntry__c RLEs : ExistingRLEs) {
                mExistingRLEs.put(RLEs.HelpReadingList__c + '' + RLEs.HelpTopic__c, RLEs);  
            }
            
            // Ditto Resources
            ExistingRes = [SELECT ResourceURL__c FROM HelpResource__c WHERE CreatedDate <= TODAY];
            for (HelpResource__c Ress : ExistingRes) {
                mExistingRes.put(Ress.ResourceURL__c, Ress);  
            }
            
            // Ditto Help Topic Resources
            ExistingHRs = [SELECT Id, HelpResource__c, HelpTopic__c FROM HelpTopicResource__c WHERE CreatedDate <= TODAY];
            for (HelpTopicResource__c HRs : ExistingHRs) {
                mExistingHRs.put(HRs.HelpResource__c + '' + HRs.HelpTopic__c, HRs);  
            }
            
            
            // Ditto Help Filters
            ExistingHFs = [SELECT Id, FilterIdentifier__c FROM HelpFilter__c WHERE CreatedDate <= TODAY];
            for (HelpFilter__c HFs : ExistingHFs) {
                mExistingHFs.put(HFs.FilterIdentifier__c, HFs);
            }
            
            // Ditto Help Filter Criteria
            ExistingHFCs = [SELECT HelpFilter__c, CriterionNumber__c FROM HelpFilterCriterion__c WHERE CreatedDate <= TODAY];
            for (HelpFilterCriterion__c HFCs : ExistingHFCs) {
                mExistingHFCs.put(HFCs.HelpFilter__c + D1 + HFCs.CriterionNumber__c, HFCs);
            }            
            
            // Ditto Helped Page Layouts
            ExistingHPLs = [SELECT Id, PageLayoutIdentifier__c FROM HelpedPageLayout__c WHERE CreatedDate <= TODAY];
            for (HelpedPageLayout__c HPs : ExistingHPLs) {
                mExistingHPLs.put(HPs.PageLayoutIdentifier__c, HPs);
            }
            
            // Ditto Helped Elements
            ExistingHEs = [SELECT Id, HelpedPageLayout__c, Identifier__c, Parameters__c, Visibility__c, HelpFilter__c, DataDrivenFilter__c FROM HelpedElement__c WHERE CreatedDate <= TODAY];
            for (HelpedElement__c HEs : ExistingHEs) {
                
                // As our XML will contain only empty strings for non-values, parse out nulls in this map
                HEID = HEs.Identifier__c;
                if (HEID == null) {HEID = '';}
                
                HEP = HEs.Parameters__c;
                if (HEP == null) {HEP = '';}
                
                HEV = HEs.Visibility__c;
                if (HEV == null) {HEV = '';}
                
                HEF = HEs.HelpFilter__c;
                if (HEF == null) {HEF = '';}
                
                HEDDF = HEs.DataDrivenFilter__c;
                if (HEDDF == null) {HEDDF = '';}
                
                
                mExistingHEs.put(HEs.HelpedPageLayout__c + D1 + HEID + D1 + HEP + D1 + HEV + D1 + HEF + D1 + HEDDF, HEs);
            }
            
            
            
            // Loop around XML tags
            Diags += 'Looping to obtain topics... ';
            
            while(reader.hasNext()) {
                
                //--------------------------------------------------------------------------------------
                // XML Processing: <HelpTopic>
                //--------------------------------------------------------------------------------------
                if (reader.getEventType() + ':' + reader.getLocalName() == 'START_ELEMENT:HelpTopic') {
                    
                    currentObject = 'Help Topics';
                    currentRow += 1;
                    
                    // ... get the tag attributes we need...
                    HTID = reader.getAttributeValue(null, 'Id');
                    HTMasterTopicIdentifier = reader.getAttributeValue(null, 'MasterTopicIdentifier');
                    HTName = reader.getAttributeValue(null, 'Name');
                    HTSummary = reader.getAttributeValue(null, 'Summary');                    
                    HTKeyword = reader.getAttributeValue(null, 'Keyword');
                    isDefault = reader.getAttributeValue(null, 'Default');
                    HTActive = reader.getAttributeValue(null, 'Active');
                    HTCalloutHeight = reader.getAttributeValue(null, 'CalloutHeight');
                    HTCalloutMediaChoice = reader.getAttributeValue(null, 'CalloutMediaChoice');
                    HTCalloutTemplate = reader.getAttributeValue(null, 'CalloutTemplate');
                    HTHeightBeforeScrolling = reader.getAttributeValue(null, 'HeightBeforeScrolling');
                    HTHelpTopicStatus = reader.getAttributeValue(null, 'HelpTopicStatus');
                    HTSalesforceHelpURL = reader.getAttributeValue(null, 'SalesforceHelpURL');
                    
                    HTVisibility = reader.getAttributeValue(null, 'Visibility');
                    HTCustomStyle = reader.getAttributeValue(null, 'CustomStyle');
                    HTShowReferringRelationships = reader.getAttributeValue(null, 'ShowReferringRelationships');
                    
                    HTHVS = reader.getAttributeValue(null, 'HelpVoteSet');
                    
                    HTGuidedLayout = reader.getAttributeValue(null, 'GuidedLayout');
                    HTGuidedRecord = reader.getAttributeValue(null, 'GuidedRecord');
                    HTGuidedElement = reader.getAttributeValue(null, 'GuidedElement');
                    HTGuideStepMode = reader.getAttributeValue(null, 'GuideStepMode');
                    HTGuideCallout = reader.getAttributeValue(null, 'GuideCallout');
                    
                    HTShowReadMoreLink = reader.getAttributeValue(null, 'ShowReadMoreLink');
                    HTTemplate = reader.getAttributeValue(null, 'Template');
                    HTLightningTemplate = reader.getAttributeValue(null, 'LightningTemplate');
                    
                    Diags += 'Got basic topic details: continuing to image... ';
                    
                    // ... then process image details
                    while (reader.getEventType() + ':' + reader.getLocalName() != 'START_ELEMENT:HelpTopicImage') {
                        reader.next();                          
                    }
                    
                    HTImageHeight = reader.getAttributeValue(null, 'Height');
                    HTImageWidth = reader.getAttributeValue(null, 'Width');
                    HTImageALTText = reader.getAttributeValue(null, 'ALTText');
                    HTImageCaption = reader.getAttributeValue(null, 'Caption');
                    HTImageTitle = reader.getAttributeValue(null, 'Title');
                    HTImageURL = reader.getAttributeValue(null, 'URL');
                    
                    Diags += 'Got image details: continuing to video... ';                      
                    
                    // ... then process video details
                    while (reader.getEventType() + ':' + reader.getLocalName() != 'START_ELEMENT:HelpTopicVideo') {
                        reader.next();                          
                    }
                    
                    HTVideoHeight = reader.getAttributeValue(null, 'Height');
                    HTVideoWidth = reader.getAttributeValue(null, 'Width');
                    HTVideoCaption = reader.getAttributeValue(null, 'Caption');
                    HTVideoTitle = reader.getAttributeValue(null, 'Title');
                    HTVideoURL = reader.getAttributeValue(null, 'URL');
                    
                    Diags += 'Got video details: continuing to description... ';
                    
                    // ... then move to the body of the topic
                    reader.next();
                    HTDescription = '';
                    
                    // For this, we need to loop around what may be multiple (HTML) tags
                    // of rich markup - until we reach the closing topic tag
                    while(reader.hasNext()) {
                        
                        // Bail if we've found the close topic tag
                        if (reader.getEventType() + ':' + reader.getLocalName() == 'END_ELEMENT:HelpTopic') {
                            break;
                        }
                        
                        // Otherwise, scrape the content
                        if (reader.getEventType() == XmlTag.CHARACTERS) {
                            HTDescription += reader.getText();  
                        } else if (reader.getEventType() == XmlTag.START_ELEMENT) {
                            
                            HTDescription += '<' + reader.getLocalName() + ' ';
                            
                            // Process particular HTML elements of interest here...
                            if (reader.getLocalName().toUpperCase() == 'A' ) {
                                
                                // Anchors: get href, target, title, class
                                if (reader.getAttributeValue(null, 'href') != null) {HTDescription += 'href="' + reader.getAttributeValue(null, 'href') + '" ';}
                                if (reader.getAttributeValue(null, 'target') != null) {HTDescription += 'target="' + reader.getAttributeValue(null, 'target') + '" ';}
                                if (reader.getAttributeValue(null, 'title') != null) {HTDescription += 'title="' + reader.getAttributeValue(null, 'title') + '" ';}
                                if (reader.getAttributeValue(null, 'class') != null) {HTDescription += 'class="' + reader.getAttributeValue(null, 'class') + '" ';}
                                
                            }
                            
                            if (reader.getLocalName().toUpperCase() == 'IMG' ) {
                                
                                // Images: get src, alt, title, width, height, style, class
                                if (reader.getAttributeValue(null, 'src') != null) {HTDescription += 'src="' + reader.getAttributeValue(null, 'src') + '" ';}
                                if (reader.getAttributeValue(null, 'alt') != null) {HTDescription += 'alt="' + reader.getAttributeValue(null, 'alt') + '" ';}
                                if (reader.getAttributeValue(null, 'title') != null) {HTDescription += 'title="' + reader.getAttributeValue(null, 'title') + '" ';}
                                if (reader.getAttributeValue(null, 'width') != null) {HTDescription += 'width="' + reader.getAttributeValue(null, 'width') + '" ';}
                                if (reader.getAttributeValue(null, 'height') != null) {HTDescription += 'height="' + reader.getAttributeValue(null, 'height') + '" ';}
                                if (reader.getAttributeValue(null, 'style') != null) {HTDescription += 'style="' + reader.getAttributeValue(null, 'style') + '" ';}
                                if (reader.getAttributeValue(null, 'class') != null) {HTDescription += 'class="' + reader.getAttributeValue(null, 'class') + '" ';}
                            }
                            
                            HTDescription += '>';
                            
                            
                            
                        } else if (reader.getEventType() == XmlTag.END_ELEMENT) {
                            HTDescription += '</' + reader.getLocalName() + '>';
                        } else {
                            HTDescription += '^';
                        }
                        
                        Diags += 'Looping at description for ' + TopicCount + ' (' + reader.getEventType() + ':' + reader.getLocalName() + ') ... ';
                        
                        reader.next();
                    }
                    
                    
                    Diags += 'Got topic details for ' + TopicCount + '... ';
                    
                    
                    // ... then create and populate a Help Topic:
                    // If we have the topic already, (as added to a map above), use it,
                    // otherwise create a new topic (a clone of the default):
                    
                    // Existing topics will have been indexed by Master Topic Identifier, if in use,
                    // or (as pre 1.43) name plus summary otherwise...
                    
                    if (HTMasterTopicIdentifier != '') {
                        if (mExistingHTs.get(HTMasterTopicIdentifier) != null) {
                            Hlp = mExistingHTs.get(HTMasterTopicIdentifier);
                            seekByNS = false;
                            
                        } else {
                            seekByNS = true;
                        }
                        
                    } else {
                        seekByNS = true;    
                    }
                    
                    if (seekByNS == true) {
                        if (mExistingHTs.get(HTName + HTSummary) != null) {
                            Hlp = mExistingHTs.get(HTName + HTSummary);
                        } else {
                            Hlp = cH.clone(defaultTopic);
                            
                            // Note the fact that we required a new topic here
                            TopicCount += 1;
                        }   
                    }
                    
                    
                    Hlp.MasterTopicIdentifier__c = HTMasterTopicIdentifier;
                    Hlp.Name = HTName;
                    Hlp.Summary__c = HTSummary;                    
                    Hlp.Keyword__c = HTKeyword;
                    Hlp.Description__c = HTDescription;
                    
                    Hlp.ImageHeight__c = Integer.valueOf(HTImageHeight);
                    Hlp.ImageWidth__c = Integer.valueOf(HTImageWidth);      
                    Hlp.ImageALTText__c = HTImageALTText;
                    Hlp.ImageCaption__c = HTImageCaption;
                    Hlp.ImageTitle__c = HTImageTitle;
                    Hlp.ImageURL__c = HTImageURL;
                    
                    Hlp.VideoHeight__c = Integer.valueOf(HTVideoHeight);
                    Hlp.VideoWidth__c = Integer.valueOf(HTVideoWidth);
                    Hlp.VideoCaption__c = HTVideoCaption;
                    Hlp.VideoTitle__c = HTVideoTitle;
                    Hlp.VideoURL__c = HTVideoURL;
                    
                    // Templates are passed in by their identifying Page URL (classic type) or Name (Lightning) because
                    // we cannot know the ID of the template records in this routine.
                    // This being the case, we need to look up the template IDs here... 
                    Diags += 'Template "' + HTTemplate + '" equates to "' + mTs.get(HTTemplate) + '"... ';
                    Diags += 'Callout Template "' + HTCalloutTemplate + '" equates to "' + mTs.get(HTCalloutTemplate) + '"... ';
                    Diags += 'Lightning Template "' + HTLightningTemplate + '" equates to "' + mTsLUX.get(HTLightningTemplate) + '"... ';
                    
                    // If templates not found via lookup, leave at default values
                    if (mTs.get(HTTemplate) != null) {Hlp.Template__c =  mTs.get(HTTemplate);}
                    if (mTs.get(HTCalloutTemplate) != null) {Hlp.CalloutTemplate__c =  mTs.get(HTCalloutTemplate);}                  
                    if (mTsLUX.get(HTLightningTemplate) != null) {Hlp.LightningTemplate__c =  mTsLUX.get(HTLightningTemplate);}
                    
                    Hlp.HeightBeforeScrolling__c = Integer.valueOf(HTHeightBeforeScrolling);
                    Hlp.CalloutHeight__c = Integer.valueOf(HTCalloutHeight);
                    Hlp.CalloutMediaChoice__c = HTCalloutMediaChoice;
                    
                    
                    if (HTActive.toUpperCase() == 'TRUE') {
                        Hlp.Active__c = true;
                    } else {
                        Hlp.Active__c = false;
                    }
                    
                    if (HTShowReadMoreLink.toUpperCase() == 'TRUE') {
                        Hlp.ShowReadMoreLink__c = true;
                    } else {
                        Hlp.ShowReadMoreLink__c = false;
                    }
                    
                    Hlp.HelpTopicStatus__c = HTHelpTopicStatus;
                    Hlp.SalesforceHelpURL__c = HTSalesforceHelpURL;
                    
                    
                    Hlp.Visibility__c = HTVisibility;
                    Hlp.CustomStyle__c = HTCustomStyle;
                    Hlp.ShowReferringRelationships__c = Boolean.valueOf(HTShowReferringRelationships);
                    
                    
                    // Take Vote set as provided - bearing in mind only an ID can be provided
                    if (HTHVS != null && HTHVS != '') {
                        Hlp.HelpVoteSet__c = HTHVS;
                    } else {
                        Hlp.HelpVoteSet__c = null;
                    }
                    
                    // Cannot do these at present as we cannot know required lookups...                     
                    //Hlp.GuidedLayout__c;
                    //Hlp.GuidedElement__c;
                    Hlp.GuidedRecord__c = HTGuidedRecord;                   
                    Hlp.GuideStepMode__c = HTGuideStepMode;
                    
                    if (HTGuideCallout.toUpperCase() == 'TRUE') {
                        Hlp.GuideCallout__c = true;
                    } else {
                        Hlp.GuideCallout__c = false;
                    }
                    
                    
                    // If topic is marked as default in XML, keep track of this
                    if (isDefault == 'true') {
                        HomeHT = Hlp;
                    }
                    
                    
                    // Store this help topic object against the id originally provided in the XML
                    mHTIDs.put(HTID, Hlp);
                    
                    // Add this record to the set we intend to upsert
                    UpsertHTs.add(Hlp);
                    
                    // Diags can re-set here - otherwise the text will get enormous...
                    Diags = 'Prepared topic ' + UpsertHTs.size() + '... ';
                }
                
                
                //--------------------------------------------------------------------------------------
                // XML Processing: <HelpRelationships> = Upsert Topics
                //--------------------------------------------------------------------------------------
                if (reader.getEventType() + ':' + reader.getLocalName() == 'START_ELEMENT:HelpRelationships') {
                    
                    // At this point, you've processed all help topic tags, so upsert the resultant records
                    // and complete related processing
                    if (upsertedHTs == false){
                        upsertedHTs = true;                    
                        upsert UpsertHTs;
                        
                        // Diags can re-set here - otherwise the text will get enormous...                  
                        Diags = 'Upserted ' + UpsertHTs.size() + ' Help Topics of which ' + TopicCount + ' were new records... ';                       
                        Diags += 'Continuing to Help Relationships... ';
                        currentRow = 0;
                    }
                    
                    
                    // If any topic was marked in the XML as default and there isn't one in place, mark it as default
                    if (HomeHT != null) {
                        IASetIHOrg__c IAS = ControllerSettings.getSettings();                   
                        if (IAS.DefaultHelpTopic__c == '' || IAS.DefaultHelpTopic__c == null) {
                            IAS.DefaultHelpTopic__c = HomeHT.Id;
                            update IAS;                 
                        }
                    }               
                }
                
                
                //--------------------------------------------------------------------------------------
                // XML Processing: <HelpRelationship>
                //--------------------------------------------------------------------------------------
                if (reader.getEventType() + ':' + reader.getLocalName() == 'START_ELEMENT:HelpRelationship') {
                    
                    currentObject = 'Help Relationships';
                    currentRow += 1;
                    
                    // ... get the tag attributes we need...
                    // Look up the related topic Ids in the maps created above
                    RefT = mHTIDs.get(reader.getAttributeValue(null, 'ReferringTopic')).Id; 
                    RelT = mHTIDs.get(reader.getAttributeValue(null, 'RelatedHelpTopic')).Id;
                    
                    // Look up to ID of the requested Semantic Tag / Relationship type:
                    // NB: as this field is relatively new (v1.35), we need to handle XML that may not contain it,
                    // so as not to invalidate content packs produced in earlier versions...
                    
                    string theSTag = reader.getAttributeValue(null, 'SemanticTag');                     
                    if (theSTag == null) {
                        theSTag = 'Relative';
                    }
                    sTag = mSTags.get(theSTag).Id;
                    //Diags += 'Relationship Type "' + theSTag + '" maps to: ' + sTag + '... ';
                    
                    RelOrder = reader.getAttributeValue(null, 'Order');                   
                    if (RelOrder == '' || RelOrder + '' == 'null' || RelOrder == null) {RelOrder = '0';}
                    
                    
                    // ... then create and populate a new Relationship
                    if (mExistingRels.get(RefT + RelT + sTag) != null) {
                        
                        // If we find a relationship that looks similar (same relatives and semantics) we CAN permit a change in order ONLY
                        Rel = mExistingRels.get(RefT + RelT + sTag);
                        Rel.Order__c = Integer.valueOf(RelOrder);
                        UpsertRels.add(Rel);
                        
                    } else {
                        Rel = new HelpRelationship__c();
                        Rel.ReferringTopic__c = RefT;
                        Rel.RelatedHelpTopic__c = RelT; 
                        
                        if (sTag != '') {Rel.SemanticTag__c = sTag;}                
                        
                        Rel.Order__c = Integer.valueOf(RelOrder);
                        
                        // Note the fact that we required a new help relationship here
                        RelCount += 1;
                        
                        // Add this record to the set we intend to upsert
                        UpsertRels.add(Rel);
                        
                    }
                    
                }
                
                //--------------------------------------------------------------------------------------
                // XML Processing: <HelpReadingLists> = Upsert Relations
                //--------------------------------------------------------------------------------------                
                if (reader.getEventType() + ':' + reader.getLocalName() == 'START_ELEMENT:HelpReadingLists') {
                    
                    // At this point, you've processed all help relationship tags, so upsert the resultant records
                    // and complete related processing
                    if (upsertedRels == false){
                        upsertedRels = true;                    
                        upsert UpsertRels;
                        
                        // Diags can re-set here - otherwise the text will get enormous...                                          
                        Diags = 'Upserted ' + UpsertRels.size() + ' Help Relationships of which ' + RelCount + ' were new records... ';                                         
                        Diags += 'Continuing to Help Reading Lists... ';
                        currentRow = 0;
                    }
                    
                }
                
                
                //--------------------------------------------------------------------------------------
                // XML Processing: <HelpReadingList>
                //--------------------------------------------------------------------------------------
                if (reader.getEventType() + ':' + reader.getLocalName() == 'START_ELEMENT:HelpReadingList') {
                    
                    currentObject = 'Reading Lists';
                    currentRow += 1;
                    
                    // ... get the tag attributes we need...
                    RLName = reader.getAttributeValue(null, 'Name');
                    RLSummary = reader.getAttributeValue(null, 'Summary');
                    RLDescription = reader.getAttributeValue(null, 'Description');
                    RLStatus = reader.getAttributeValue(null, 'Status');
                    
                    // NB: date in XML is in the form d.m.y
                    RLFeaturedUntilParts = reader.getAttributeValue(null, 'FeaturedUntil').split('\\.');
                    
                    // ... then create and populate a new Reading List
                    if (mExistingRLs.get(RLName + RLSummary) != null) {
                        RL = mExistingRLs.get(RLName + RLSummary);
                    } else {
                        RL = new HelpReadingList__c();
                        
                        // Note the fact that we required a new topic here
                        RLCount += 1;
                    }
                    
                    RL.Name = RLName;
                    RL.Summary__c = RLSummary;
                    
                    // Description is parsed into XML with rich text (<, >) "escaped"
                    RLDescription = RLDescription.replace('&lt;', '<');
                    RLDescription = RLDescription.replace('&gt;', '>');
                    
                    RL.Description__c = RLDescription;
                    
                    if (RLFeaturedUntilParts.size() == 3) {
                        RL.FeaturedUntil__c = date.newInstance(integer.valueOf(RLFeaturedUntilParts[2]), integer.valueOf(RLFeaturedUntilParts[1]), integer.valueOf(RLFeaturedUntilParts[0]));
                    } else {
                        // Leave featured until blank
                    }
                    
                    
                    RL.ReadingListStatus__c = RLStatus;
                    
                    RL.ReadingListType__c = reader.getAttributeValue(null, 'ReadingListType');
                    
                    RL.LightningPresentationStyle__c = reader.getAttributeValue(null, 'LightningPresentationStyle');
                    
                    // Store this reading list object against the id originally provided in the XML
                    mRLIDs.put(reader.getAttributeValue(null, 'Id'), RL);
                    
                    // Add this record to the set we intend to upsert
                    UpsertRLs.add(RL);
                    
                    // Diags can re-set here - otherwise the text will get enormous...
                    Diags = 'Prepared Reading List ' + UpsertRLs.size()  + '... ';                      
                }
                
                
                //--------------------------------------------------------------------------------------
                // XML Processing: <HelpReadingListEntry> = Upsert Reading Lists & Process Entries
                //--------------------------------------------------------------------------------------
                if (reader.getEventType() + ':' + reader.getLocalName() == 'START_ELEMENT:HelpReadingListEntry') {
                    
                    
                    // At this point, you've processed all Reading List tags, so upsert the resultant records
                    // and complete related processing
                    if (upsertedRLs == false){
                        upsertedRLs = true;                    
                        upsert UpsertRLs;
                        
                        // Diags can re-set here - otherwise the text will get enormous...                      
                        Diags = 'Upserted ' + UpsertRLs.size() + ' Help Reading Lists of which ' + RLCount + ' were new records... ';
                        Diags += 'Continuing to Reading List Entries... ';
                        currentRow = 0;                     
                    }
                    
                    currentObject = 'Reading List Entries';
                    currentRow += 1;
                    
                    // ... get the tag attributes we need...
                    // Look up the Help Topic and Reading List Ids in the maps created above
                    RLERL = mRLIDs.get(reader.getAttributeValue(null, 'HelpReadingList')).Id;
                    RLEHT = mHTIDs.get(reader.getAttributeValue(null, 'HelpTopic')).Id;
                    
                    // ... then create and populate a new Reading List
                    if (mExistingRLEs.get(RLERL + RLEHT) != null) {
                        RLE = mExistingRLEs.get(RLERL + RLEHT);
                    } else {
                        // NB: if you found an existing RL Entry, all you can amend is the reading order,
                        // so these fields only get updated in here...
                        RLE = new HelpReadingListEntry__c();                
                        RLE.HelpReadingList__c = RLERL;
                        RLE.HelpTopic__c = RLEHT;
                        
                        // Note the fact that we required a new topic here
                        RLECount += 1;
                    }
                    
                    RLE.ReadingOrder__c = integer.valueOf(reader.getAttributeValue(null, 'ReadingOrder'));
                    
                    // Added 1.52
                    DRow = reader.getAttributeValue(null, 'DisplayRow');                   
                    if (DRow == '' || DRow + '' == 'null' || DRow == null) {DRow = '0';}
                    
                    DCol = reader.getAttributeValue(null, 'DisplayColumn');                   
                    if (DCol == '' || DCol + '' == 'null' || DCol == null) {DCol = '0';}
                    
                    RLE.DisplayRow__c = Integer.valueOf(DRow);
                    RLE.DisplayColumn__c = Integer.valueOf(DCol);
                    RLE.NavigationType__c = reader.getAttributeValue(null, 'NavigationType');
                    RLE.NavigationDetails__c = reader.getAttributeValue(null, 'NavigationDetails');
                    
                    
                    
                    
                    // Add this record to the set we intend to upsert
                    UpsertRLEs.add(RLE);
                    
                    // Diags can re-set here - otherwise the text will get enormous...
                    Diags = 'Upserted Reading List Entry ' +  UpsertRLEs.size() + '... ';                   
                }
                
                
                //--------------------------------------------------------------------------------------
                // XML Processing: <HelpResources> = upsert Reading List Entries
                //--------------------------------------------------------------------------------------
                if (reader.getEventType() + ':' + reader.getLocalName() == 'START_ELEMENT:HelpResources') {
                    
                    // At this point, you've processed all Reading List tags, so upsert the resultant records
                    // and complete related processing
                    if (upsertedRLEs == false){
                        upsertedRLEs = true;                    
                        upsert UpsertRLEs;
                        
                        // Diags can re-set here - otherwise the text will get enormous...                      
                        Diags = 'Upserted ' + UpsertRLEs.size() + ' Reading List Entries of which ' + RLECount + ' were new records... ';
                        Diags += 'Continuing to Help Resources... ';
                        currentRow = 0;                     
                    }
                    
                }
                
                
                //--------------------------------------------------------------------------------------
                // XML Processing: <HelpResource>
                //--------------------------------------------------------------------------------------
                if (reader.getEventType() + ':' + reader.getLocalName() == 'START_ELEMENT:HelpResource') {
                    
                    currentObject = 'Help Resources';
                    currentRow += 1;
                    
                    // ... get the tag attributes we need...
                    HRID = reader.getAttributeValue(null, 'Id');
                    HRURL = reader.getAttributeValue(null, 'URL');
                    
                    // ... then create and populate a new Resource
                    if (mExistingRes.get(HRURL) != null) {
                        HR = mExistingRes.get(HRURL);
                    } else {
                        HR = new HelpResource__c();
                        
                        // Note the fact that we required a new topic here
                        HRCount += 1;
                    }
                    
                    
                    HR.Name = reader.getAttributeValue(null, 'Name');
                    HR.Summary__c = reader.getAttributeValue(null, 'Summary');
                    HR.Location__c = reader.getAttributeValue(null, 'Location');
                    HR.ResourceType__c = reader.getAttributeValue(null, 'ResourceType');
                    HR.ResourceURL__c = HRURL;
                    
                    
                    // Store this resource object against the id originally provided in the XML
                    mHRIDs.put(HRID, HR);
                    
                    // Add this record to the set we intend to upsert
                    UpsertRes.add(HR);
                    
                    // Diags can re-set here - otherwise the text will get enormous...
                    Diags = 'Prepared Resource ' + UpsertRes.size()  + '... ';                                          
                }
                
                
                //--------------------------------------------------------------------------------------
                // XML Processing: <HelpTopicResource> = upsert Resources & Process Help Topic Resources
                //--------------------------------------------------------------------------------------
                if (reader.getEventType() + ':' + reader.getLocalName() == 'START_ELEMENT:HelpTopicResource') {
                    
                    
                    // At this point, you've processed all Resource tags, so upsert the resultant records
                    // and complete related processing
                    if (upsertedRes == false){
                        upsertedRes = true;                    
                        upsert UpsertRes;
                        
                        // Diags can re-set here - otherwise the text will get enormous...                      
                        Diags = 'Upserted ' + UpsertRes.size() + ' Resources of which ' + HRCount + ' were new records... ';
                        Diags += 'Continuing to Help Topic Resources... ';
                        currentRow = 0;                     
                    }
                    
                    currentObject = 'Help Topic Resources';
                    currentRow += 1;
                    
                    // ... get the tag attributes we need...
                    // Look up the Help Topic and Resource Ids in the maps created above
                    HTRHR = mHRIDs.get(reader.getAttributeValue(null, 'HelpResource')).Id;
                    HTRHT = mHTIDs.get(reader.getAttributeValue(null, 'HelpTopic')).Id;
                    
                    // ... then create and populate a new Help Topic Resource
                    if (mExistingHRs.get(HTRHR + HTRHT) != null) {
                        HTR = mExistingHRs.get(HTRHR + HTRHT);
                    } else {
                        // NB: if you found an existing HT Resource, all you can amend is the notes,
                        // so these fields only get updated in here...
                        HTR = new HelpTopicResource__c();               
                        HTR.HelpResource__c = HTRHR;
                        HTR.HelpTopic__c = HTRHT;                       
                        
                        // Note the fact that we required a new topic here
                        HTRCount += 1;
                    }
                    
                    HTR.UsageNotes__c = reader.getAttributeValue(null, 'UsageNotes');                                       
                    
                    // Add this record to the set we intend to upsert
                    UpsertHRs.add(HTR);
                    
                    // Diags can re-set here - otherwise the text will get enormous...
                    Diags = 'Prepared Help Topic Resource ' + UpsertHRs.size()  + '... ';                                       
                }
                
                //--------------------------------------------------------------------------------------
                // XML Processing: </HelpResources> = upsert Help Topic Resources
                //--------------------------------------------------------------------------------------
                if (reader.getEventType() + ':' + reader.getLocalName() == 'END_ELEMENT:HelpResources') {
                    
                    // At this point, you've processed all Topic Resource tags, so upsert the resultant records
                    // and complete related processing
                    if (upsertedHTRs == false){
                        upsertedHTRs = true;                    
                        upsert UpsertHRs;
                        
                        // Diags can re-set here - otherwise the text will get enormous...                      
                        Diags = 'Upserted ' + UpsertHRs.size() + ' Help Topic Resources of which ' + HTRCount + ' were new records... ';                    
                        Diags += 'Continuing to Help Filters... ';
                        currentRow = 0;
                    }
                    
                }
                
                
                
                //--------------------------------------------------------------------------------------
                // XML Processing: <HelpFilter>
                //--------------------------------------------------------------------------------------
                if (reader.getEventType() + ':' + reader.getLocalName() == 'START_ELEMENT:HelpFilter') {
                    
                    currentObject = 'Help Filters';
                    currentRow += 1;
                    
                    // Get the XML-stated filter identifier
                    HFIdent = reader.getAttributeValue(null, 'FilterIdentifier');
                    
                    
                    // Create or identify a Help Fiilter object
                    if (mExistingHFs.get(HFIdent) != null) {
                        HF = mExistingHFs.get(HFIdent);
                    } else {
                        HF = new HelpFilter__c();
                        HF.FilterIdentifier__c = HFIdent;
                        
                        // Note the fact that we required a new helped page layout here
                        HFCount += 1;
                    }
                    
                    // Populate the object
                    HF.FilterLogic__c = reader.getAttributeValue(null, 'FilterLogic');
                    HF.FilteredObject__c = reader.getAttributeValue(null, 'FilteredObject');
                    HF.FilteredObjectIdentifier__c = reader.getAttributeValue(null, 'FilteredObjectIdentifier');
                    
                    
                    // Store this Filter object against the id originally provided in the XML
                    mHFs.put(reader.getAttributeValue(null, 'Id'), HF);
                    
                    // Add this record to the set we intend to upsert
                    UpsertHFs.add(HF);
                    
                }
                
                
                //--------------------------------------------------------------------------------------
                // XML Processing: </HelpFilters> = upsert Help Filters
                //--------------------------------------------------------------------------------------
                if (reader.getEventType() + ':' + reader.getLocalName() == 'END_ELEMENT:HelpFilters') {
                    
                    // At this point, you've processed all Filter tags, so upsert the resultant records
                    // and complete related processing
                    if (upsertedHFs == false){
                        upsertedHFs = true;                    
                        upsert UpsertHFs;
                        
                        // Diags can re-set here - otherwise the text will get enormous...                      
                        Diags = 'Upserted ' + UpsertHFs.size() + ' Help Filters of which ' + HFCount + ' were new records... ';                    
                        Diags += 'Continuing to Help Filter Criteria... ';
                        currentRow = 0;
                    }
                    
                }
                
                
                //--------------------------------------------------------------------------------------
                // XML Processing: <HelpFilterCriterion>
                //--------------------------------------------------------------------------------------
                if (reader.getEventType() + ':' + reader.getLocalName() == 'START_ELEMENT:HelpFilterCriterion') {
                    
                    currentObject = 'Help Filter Criteria';
                    currentRow += 1;
                    
                    
                    // Create or locate a Help Filter Criterion record
                    HFIdent = mHFs.get(reader.getAttributeValue(null, 'HelpFilter')).Id;
                    
                    Diags += 'About to search exising filter criteria for: ' + HFIdent + reader.getAttributeValue(null, 'CriterionNumber');
                    
                    if (mExistingHFCs.get(HFIdent + D1 + reader.getAttributeValue(null, 'CriterionNumber')) != null) {
                        HFC = mExistingHFCs.get(HFIdent + D1 + reader.getAttributeValue(null, 'CriterionNumber'));
                        
                    } else {
                        HFC = new HelpFilterCriterion__c(); 
                        HFC.HelpFilter__c = HFIdent;               
                        HFC.CriterionNumber__c = integer.valueOf(reader.getAttributeValue(null, 'CriterionNumber'));
                        
                        // Note the fact that we required a new criterion here
                        HFCCount += 1;
                    }
                    
                    
                    // Populate the record
                    HFC.Name = reader.getAttributeValue(null, 'Name');
                    HFC.FilteredField__c = reader.getAttributeValue(null, 'FilteredField');
                    HFC.FilteredFieldType__c = reader.getAttributeValue(null, 'FilteredFieldType');
                    HFC.Operator__c = reader.getAttributeValue(null, 'Operator');
                    HFC.FilterValue__c = reader.getAttributeValue(null, 'FilterValue');
                    
                    
                    // Add this record to the set we intend to upsert
                    UpsertHFCs.add(HFC);
                    
                }
                
                
                //--------------------------------------------------------------------------------------
                // XML Processing: </HelpFilterCriteria> = upsert Help Filter Criteria
                //--------------------------------------------------------------------------------------
                if (reader.getEventType() + ':' + reader.getLocalName() == 'END_ELEMENT:HelpFilterCriteria') {
                    
                    // At this point, you've processed all Filter Criteria tags, so upsert the resultant records
                    // and complete related processing
                    if (upsertedHFCs == false){
                        upsertedHFCs = true;                    
                        upsert UpsertHFCs;
                        
                        // Diags can re-set here - otherwise the text will get enormous...                      
                        Diags = 'Upserted ' + UpsertHFCs.size() + ' Help Filter Criteria of which ' + HFCCount + ' were new records... ';                    
                        Diags += 'Continuing to Helped Page Layouts... ';
                        currentRow = 0;
                    }
                    
                }
                
                
                
                //--------------------------------------------------------------------------------------
                // XML Processing: <HelpedPageLayout>
                //--------------------------------------------------------------------------------------
                if (reader.getEventType() + ':' + reader.getLocalName() == 'START_ELEMENT:HelpedPageLayout') {
                    
                    currentObject = 'Helped Page Layouts';
                    currentRow += 1;
                    
                    
                    // Get the XML-stated layout identifier
                    HPLIdent = reader.getAttributeValue(null, 'PageLayoutIdentifier');
                    
                    // In the case of Helped Page Layouts, the identifier in the XML will, of necessity, be
                    // the NAME of the relevant object (as source Org cannot know the object Id
                    // in the destination Org) OR it will be an Apex page name.
                    // In the latter case, we can take the Ident as is, but for "Standard" layouts
                    // we must look up the correct object id from meta data
                    if (reader.getAttributeValue(null, 'PageType').toUpperCase() == 'STANDARD') {
                        HPLIdent = ServiceSchema.getObjectIdByName(HPLIdent);
                    }
                    
                    // ... then create and populate a new Helped Page Layout
                    if (mExistingHPLs.get(HPLIdent) != null) {
                        HPL = mExistingHPLs.get(HPLIdent);
                    } else {
                        HPL = new HelpedPageLayout__c();
                        HPL.PageLayoutIdentifier__c = HPLIdent;
                        
                        // Note the fact that we required a new helped page layout here
                        HPLCount += 1;
                    }
                    
                    // Use the incoming layout name
                    HPL.Name = reader.getAttributeValue(null, 'Name');                      
                    HPL.PageType__c= reader.getAttributeValue(null, 'PageType');
                    HPL.AllowComments__c = Boolean.valueOf(reader.getAttributeValue(null, 'AllowComments'));
                    
                    
                    temp = reader.getAttributeValue(null, 'RehookTimes');
                    if (temp == null || temp == '') {
                        HPL.RehookTimes__c = 0;
                        
                    } else {
                        HPL.RehookTimes__c = integer.valueOf(temp);
                    }                   
                    
                    temp = reader.getAttributeValue(null, 'RehookInterval');
                    if (temp == null || temp == '') {
                        HPL.RehookInterval__c = 0;
                        
                    } else {
                        HPL.RehookInterval__c = integer.valueOf(temp);
                    }
                    
                    
                    // Store this Layout object against the id originally provided in the XML
                    mHPLs.put(reader.getAttributeValue(null, 'Id'), HPL);
                    
                    // Add this record to the set we intend to upsert
                    UpsertHPLs.add(HPL);
                    
                }
                
                
                //--------------------------------------------------------------------------------------
                // XML Processing: </HelpedPageLayouts> = upsert Helped Page Layouts
                //--------------------------------------------------------------------------------------
                if (reader.getEventType() + ':' + reader.getLocalName() == 'END_ELEMENT:HelpedPageLayouts') {
                    
                    // At this point, you've processed all HPL tags, so upsert the resultant records
                    if (upsertedHPLs == false){
                        upsertedHPLs = true;                    
                        upsert UpsertHPLs;
                        
                        // Diags can re-set here - otherwise the text will get enormous...                      
                        Diags = 'Upserted ' + UpsertHPLs.size() + ' Helped Page Layouts of which ' + HPLCount + ' were new records... ';                    
                        Diags += 'Continuing to Helped Elements... ';
                        currentRow = 0;                     
                    }
                    
                }
                
                
                //--------------------------------------------------------------------------------------
                // XML Processing: <HelpedElement>
                //--------------------------------------------------------------------------------------
                if (reader.getEventType() + ':' + reader.getLocalName() == 'START_ELEMENT:HelpedElement') {
                    
                    currentObject = 'Helped Elements';
                    currentRow += 1;
                    
                    // ... get the tag attributes we need from the maps of new elements created above
                    HPLIdent = mHPLs.get(reader.getAttributeValue(null, 'HelpedPageLayout')).Id;
                    Diags += 'About to search exising elements for: ' + HPLIdent + reader.getAttributeValue(null, 'Identifier') + reader.getAttributeValue(null, 'Visibility');
                    
                    HTID = mHTIDs.get(reader.getAttributeValue(null, 'HelpTopic')).Id;                      
                    Diags += ' (HT=' + HTID + ')... ';
                    
                    
                    HEF = reader.getAttributeValue(null, 'HelpFilter');
                    if (HEF == null) {HEF = '';}                   
                    if (HEF != '') {
                        HEF = mHFs.get(HEF).Id;
                    }
                    
                    
                    // DDF string will have been "escaped" in XML
                    HEDataDrivenFilter = reader.getAttributeValue(null, 'DataDrivenFilter');
                    HEDataDrivenFilter = HEDataDrivenFilter.replace('&lt;', '<');
                    HEDataDrivenFilter = HEDataDrivenFilter.replace('&gt;', '>');
                    
                    
                    // ... then create and populate a new Help Element
                    if (mExistingHEs.get(HPLIdent + D1 + reader.getAttributeValue(null, 'Identifier') + D1 + reader.getAttributeValue(null, 'Parameters') + D1 + reader.getAttributeValue(null, 'Visibility') + D1 + HEF + D1 + HEDataDrivenFilter) != null) {
                        HE = mExistingHEs.get(HPLIdent + D1 + reader.getAttributeValue(null, 'Identifier') + D1 + reader.getAttributeValue(null, 'Parameters') + D1 + reader.getAttributeValue(null, 'Visibility') + D1 + HEF + D1 + HEDataDrivenFilter);
                    } else {
                        HE = new HelpedElement__c();                
                        
                        // Note the fact that we required a new element here
                        HECount += 1;
                    }
                    
                    HE.HelpedPageLayout__c = HPLIdent;                                          
                    HE.HelpTopic__c = HTID;                                         
                    
                    HE.Name = reader.getAttributeValue(null, 'Name');
                    HE.ElementType__c = reader.getAttributeValue(null, 'ElementType');                                          
                    HE.Identifier__c = reader.getAttributeValue(null, 'Identifier');                                        
                    HE.Visibility__c = reader.getAttributeValue(null, 'Visibility');
                    
                    
                    if (HEF != '') {
                        HE.HelpFilter__c = HEF;                     
                    }
                    
                    // Filter will have been "escaped" in XML
                    /*                    
HEDataDrivenFilter = reader.getAttributeValue(null, 'DataDrivenFilter');
HEDataDrivenFilter = HEDataDrivenFilter.replace('&lt;', '<');
HEDataDrivenFilter = HEDataDrivenFilter.replace('&gt;', '>');
*/                    
                    
                    HE.DataDrivenFilter__c = HEDataDrivenFilter;
                    
                    HE.UseForNew__c = Boolean.valueOf(reader.getAttributeValue(null, 'UseForNew'));
                    HE.Parameters__c = reader.getAttributeValue(null, 'Parameters');                                        
                    
                    
                    // Add this record to the set we intend to upsert
                    UpsertHEs.add(HE);
                    
                    // Diags can re-set here - otherwise the text will get enormous...
                    Diags = 'Prepared Helped Element ' + UpsertHEs.size()  + '... ';                                        
                    
                }
                
                
                //--------------------------------------------------------------------------------------
                // XML Processing: </HelpedElements> = upsert Helped Elements
                //--------------------------------------------------------------------------------------
                if (reader.getEventType() + ':' + reader.getLocalName() == 'END_ELEMENT:HelpedElements') {
                    
                    // At this point, you've processed all Helped Element tags, so upsert the resultant records
                    if (upsertedHEs == false){
                        upsertedHEs = true;                    
                        upsert UpsertHEs;
                        
                        // Diags can re-set here - otherwise the text will get enormous...
                        Diags = 'Upserted ' + UpsertHEs.size() + ' Helped Elements of which ' + HECount + ' were new records... ';
                        Diags += 'Continuing to Author Configurations... ';
                        currentRow = 0;                     
                    }
                    
                }
                
                
                //--------------------------------------------------------------------------------------
                // XML Processing: <AuthorConfiguration>
                //--------------------------------------------------------------------------------------
                if (reader.getEventType() + ':' + reader.getLocalName() == 'START_ELEMENT:AuthorConfiguration') {
                    
                    // These are handled differently as they are always treated as overwrites (act of recording them
                    // deletes any prior configs for the same component) plus we have a dedicated method for processing...
                    
                    currentObject = 'Author Configurations';
                    currentRow += 1;
                    
                    string CID = reader.getAttributeValue(null, 'LightningComponentId');
                    
                    // Check for specified help topic in list of those created above
                    
                    // With author configurations, we need to be parsing out supplied topic IDs and replacing
                    // with the actual IDs we've created above. However, the config instructions may include 
                    // other attribute settings, so we need to separate things out here...
                    // Look for attribute name/value pair (NVP) separator:
                    
                    string paramsIn = reader.getAttributeValue(null, 'DefaultHelpTopic');
                    string paramsOut;
                    list<string> NVPs;
                    list<string> NVP;
                    string remainder = '';
                    integer i;
                    
                    Diags += 'For component ' + CID + ' requested Author Configuration is: ' + paramsIn + '... ';                    
                    
                    HTID = '';
                    /*                    
if (paramsIn.indexOf('^') != -1) {
NVPs = paramsIn.split('\\^');

for (i=0; i<NVPs.size(); i++) {
if (NVPs[i].startsWith('HelpRecordId')) {
NVP = NVPs[i].split('\\~');
HTID = mHTIDs.get(NVP[1]).Id;
} else {
remainder += NVPs[i] + '^';
}
}
} else {
// If no NVP delimiter found, assume we have a topic ID
HTID = mHTIDs.get(paramsIn).Id; 
}


// Cut final NVP delimiter from non-HTID attribute string
if (remainder.length() > 0) {
remainder = remainder.substring(0, remainder.length() -1);
}


if (HTID == '') {
paramsOut = remainder;
} else {
if (remainder == '') {
paramsOut = 'HelpRecordId~' + HTID;
} else {
paramsOut = 'HelpRecordId~' + HTID + '^' + remainder;
}
}
*/
                    
                    
                    // Author configuration parameters could be:
                    // {Id}
                    // {Param Name}~{Param Value}
                    // {Param Name}~{Param Value}^{Param Name}~{Param Value}
                    
                    // ... where:
                    // {Id} is a help record ID (may or may not be a topic)
                    // {Param Value} may or may not be an {Id}
                    
                    integer valIdx;
                    string paramName;
                    string paramVal;
                    
                    NVPs = paramsIn.split('\\^');
                    paramsOut = '';
                    
                    
                    for (i=0; i<NVPs.size(); i++) {
                        
                        NVP = NVPs[i].split('\\~');
                        
                        if (NVP.size() > 1) {
                            valIdx = 1;
                            paramName = NVP[0] + '~';
                        } else {
                            valIdx = 0;
                            
                            // If no parameter name supplied, assume help record ID
                            paramName = 'HelpRecordId~';
                        }
                        
                        Diags += 'Param name: ' +   paramName + '... ';
                        Diags += 'Value index: ' +  valIdx + '... ';
                        
                        try {
                            paramVal = mHTIDs.get(NVP[valIdx]).Id;
                        } catch (exception exc){
                            paramVal = null;
                        } 
                        
                        try {
                            if (paramVal == null) {paramVal = mRLIDs.get(NVP[valIdx]).Id;}
                        } catch (exception exc){
                            paramVal = null;
                        }
                        
                        if (paramVal == null) {paramVal = NVP[valIdx];}
                        
                        Diags += 'Param value: ' +  paramVal + '... ';
                        
                        
                        paramsOut += paramName + paramVal + '^';
                    }
                    
                    
                    // Cut final NVP delimiter from output string
                    if (paramsOut.length() > 0) {
                        paramsOut = paramsOut.substring(0, paramsOut.length() -1);
                    }
                    
                    
                    
                    ControllerLUXOps.logAuthorConfig(CID, paramsOut);
                    AuthCCount += 1;
                }
                
                
                //--------------------------------------------------------------------------------------
                // XML Processing: </AuthorConfiguration> 
                //--------------------------------------------------------------------------------------
                if (reader.getEventType() + ':' + reader.getLocalName() == 'END_ELEMENT:AuthorConfigurations') {
                    // Nothing to do here becuase the calls for each author config have upserted as required
                }
                
                
                reader.next();
            }
            
            // If we get here, use email to pass out success message
            String sAdded =  mapGlbLocs.get('MessageGenericAdded');
            String sNewRec = mapGlbLocs.get('MessageGenericNewRecords');
            String sEdited = mapGlbLocs.get('MessageGenericEdited');
            
            Diags = sEdited + ' ' + (UpsertHTs.size() - TopicCount) + ' Help Topic(s). ' + sAdded + ' ' + TopicCount + ' ' + sNewRec + '. ';
            Diags += '\n\n' + sEdited + ' ' + (UpsertRels.size() - RelCount) + ' Relationship(s). ' + sAdded + ' ' + RelCount + ' ' + sNewRec + '. ';
            Diags += '\n\n' + sEdited + ' ' + (UpsertRLs.size() - RLCount) + ' Reading List(s). ' + sAdded + ' ' + RLCount + ' ' + sNewRec + '. ';
            Diags += '\n\n' + sEdited + ' ' + (UpsertRLEs.size() - RLECount) + ' Reading List Entrie(s). ' + sAdded + ' ' + RLECount + ' ' + sNewRec + '. ';            
            Diags += '\n\n' + sEdited + ' ' + (UpsertRes.size() - HRCount) + ' Resource(s). ' + sAdded + ' ' + HRCount + ' ' + sNewRec + '. ';
            Diags += '\n\n' + sEdited + ' ' + (UpsertHRs.size() - HTRCount) + ' Help Topic Resource(s). ' + sAdded + ' ' + HTRCount + ' ' + sNewRec + '. ';             
            
            Diags += '\n\n' + sEdited + ' ' + (UpsertHFs.size() - HFCount) + ' Help Filter(s). ' + sAdded + ' ' + HFCount + ' ' + sNewRec + '. ';             
            Diags += '\n\n' + sEdited + ' ' + (UpsertHFCs.size() - HFCCount) + ' Help Filter Criteria. ' + sAdded + ' ' + HFCCount + ' ' + sNewRec + '. ';             
            
            Diags += '\n\n' + sEdited + ' ' + (UpsertHPLs.size() - HPLCount) + ' Helped Page Layout(s). ' + sAdded + ' ' + HPLCount + ' ' + sNewRec + '. ';
            Diags += '\n\n' + sEdited + ' ' + (UpsertHEs.size() - HECount) + ' Helped Element(s). ' + sAdded + ' ' + HECount + ' ' + sNewRec + '. ';
            
            Diags += '\n\n\n\n' + AuthCCount + ' Author Configuration(s) were logged.';
            
            mailSubject = 'Improved Help: content uploaded successfully into Org: ' + UserInfo.getOrganizationName();
            
            msgP += 'Improved Help content upload completed successfully, as follows: ' + CRP + CRP;
            msgP += Diags;
            msgP = msgP.replaceAll('\n\n', CRP);
            
            msgH += '<b>Improved Help content upload completed successfully, as follows:</b>' + CRH + CRH;
            msgH += Diags;
            msgH = msgH.replaceAll('\n\n', CRH);
            
            retVal = true;
            
        } catch (exception e) {
            
            mailSubject = 'Improved Help: error uploading content into Org: ' + UserInfo.getOrganizationName();
            
            msgP = mapGlbLocs.get('MessageGenericError') + '.' + CRP;
            msgP += 'A recent request to upload a Help content pack encountered errors and could not complete successfully. Please see the diagnostics below for more information and, if you are unable to resolve these issues, please reply to this email for further assistance.' + CRP + CRP;
            msgP += 'Uploader was processing: ' + currentObject + CRP;
            msgP += 'Record number: ' + currentRow + CRP;
            msgP += e.getMessage() + CRP;
            msgP += Diags;
            
            msgH = '<u>' + mapGlbLocs.get('MessageGenericError') + '</u>.' + CRH;
            msgH += '<i>A recent request to upload a Help content pack encountered errors and could not complete successfully. Please see the diagnostics below for more information and, if you are unable to resolve these issues, please reply to this email for further assistance.</i>' + CRH + CRH;
            msgH += '<b>Uploader was processing:</b> ' + currentObject + CRH;
            msgH += '<b>Record number:</b> ' + currentRow + CRH;
            msgH += e.getMessage() + CRH;
            msgH += Diags;
            
            Diags = msgP;
            
            retVal = false;
        }
        
        // Success or failure, send email report...        
        generateEmail(mailSubject, msgP, msgH, null);
        
        // ... and return success to caller (though this is superfluous for ASynch ops)            
        return retVal;
    }
    
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // ROUTINES FOR DUMPING DATA OUT FROM ORG TO ORG
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    
    public HelpTopic__c[] xlTopics {get;set;}
    public HelpRelationship__c[] xlRelationships {get; set;}
    public HelpReadingList__c[] xlReadingLists {get; set;}
    public HelpReadingListEntry__c[] xlReadingListEntries {get; set;}
    public HelpResource__c[] xlResources {get; set;}
    public HelpTopicResource__c[] xlHelpTopicResources {get; set;}
    
    public HelpFilter__c[] xlHelpFilters {get; set;}
    public HelpFilterCriterion__c[] xlHelpFilterCriteria {get; set;}
    
    public HelpedPageLayout__c[] xlHelpedPageLayouts {get; set;}
    public HelpedElement__c[] xlHelpedElements {get; set;}
    
    
    // XML application type headers   
    public String ioHeaderXL {
        get {
            String strHeader = '';
            strHeader += '<?xml version="1.0"?>';
            strHeader += '<?mso-application progid="Excel.Sheet"?>';
            return strHeader;
        }
    }
    
    public String ioHeaderDoc {
        get {
            String strHeader = '';
            strHeader += '<?xml version="1.0"?>';
            strHeader += '<?mso-application progid="Word.Document"?>';
            return strHeader;
        }
    }
    
    
    public String ioHeaderPPT {
        get {
            String strHeader = '';
            strHeader += '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>';
            strHeader += '<?mso-application progid="PowerPoint.Show"?>';
            return strHeader;
        }
    }
    
    
    // Return a string representing all configuration tools in JSON format:
    // v1.40+ : skips records that represent local metadata (type = ConfigurationData)
    // and any items marked for local use only (SkipExport = true)
    public String ioDataConfigJSON {
        get {
            
            //1.39.n+ : do NOT include types, as their content does not represent clickables and is, in 
            // any case, specific to the org one is in...
            List<ConfigurationItem__c> LXTs = [SELECT Id, Name, ActionCode__c, Description__c,
                                               DisplayGrouping__c, DisplayOrder__c, HasDivider__c,
                                               IconClass__c, IconContent__c, Label__c, 
                                               NegotiateToolbarLevel__c,
                                               PermissionLevel__c, SupportingControls__c, 
                                               SkipExport__c, SkipImportOverwrite__c,
                                               TipText__c, ToggleActiveMarker__c,
                                               ToggleNext__c, TogglePrev__c, ToolClass__c, 
                                               ToolContext__c, ToolFilter__c, Type__c  
                                               
                                               FROM ConfigurationItem__c 
                                               WHERE Type__c != 'ConfigurationData'
                                               AND SkipExport__c = false
                                               LIMIT 5000
                                              ];
            
            return JSON.serialize(LXTs);
        }
    }
    
    
    // Return a string representing all interactions in JSON format
    public String ioDataInteractionsJSON {
        get {
            List<HelpInteraction__c> HIs = [SELECT Id, Name, CreatedDate, CreatedById, 
                                            iahelp__HelpInteractionType__c, iahelp__Context__c, iahelp__Description__c,
                                            iahelp__HelpTopic__c, 
                                            iahelp__HelpedElement__c, iahelp__HelpedPageLayout__c, 
                                            iahelp__HelpReadingList__c, 
                                            iahelp__HelpResource__c, 
                                            iahelp__HelpVoteOption__c
                                            
                                            FROM iahelp__HelpInteraction__c
                                            ORDER BY CreatedDate DESC
                                            LIMIT 10000];
            
            
            // Ensure nulls are included in output
            ServiceSchema sS = new ServiceSchema();
            string objId = ServiceSchema.getObjectIdByName('iahelp__HelpInteraction__c');
            Schema.DescribeSObjectResult sObj = sS.getObjectDetails(objId);
            
            // For the object, get its fields and set any blanks
            Map<String, Schema.SObjectField> FMap = sObj.Fields.getMap();
            object objVal;
            /*
for (HelpInteraction__c HI : HIs) {
for (string FKey : FMap.keySet()){    
try {
// Mere act of getting each field is a null check
objVal = HI.get(FMap.get(FKey));

if (objVal == null) {
HI.put(FKey, null);                     
}

} catch (exception ex) {
}
}                           
}                    
*/            
            
            return JSON.serialize(HIs);
        }
    }
    
    
    // Dump an individual reading list or help topic to word in Open XML format
    public String ioDataDoc {
        get {
            String strHeader = '';
            String RLID;
            String HTID;
            
            // Check user has *some* help access            
            ServiceSecurity Security = new ServiceSecurity();
            Boolean[] UPs = Security.UserPermissions();
            
            
            try {
                RLID = ServiceSecurity.getQueryParameter('RLID', 2);
                HTID = ServiceSecurity.getQueryParameter('HTID', 2);
                
                
                // Static part of the document - package structure definition            
                strHeader += '<pkg:part pkg:name="/_rels/.rels" pkg:contentType="application/vnd.openxmlformats-package.relationships+xml">';
                strHeader += '<pkg:xmlData>';
                strHeader += '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">';
                strHeader += '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>';
                strHeader += '</Relationships>';
                strHeader += '</pkg:xmlData>';
                strHeader += '</pkg:part>';
                
                strHeader += '<pkg:part pkg:name="/word/_rels/document.xml.rels" pkg:contentType="application/vnd.openxmlformats-package.relationships+xml" pkg:padding="256">';
                strHeader += '<pkg:xmlData>';
                strHeader += '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>';
                strHeader += '</Relationships></pkg:xmlData></pkg:part>';
                
                // Document body definition
                strHeader += '<pkg:part pkg:name="/word/document.xml" pkg:contentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml">';
                strHeader += '<pkg:xmlData>';
                strHeader += '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" >';
                strHeader += '<w:body>';
                
                
                // Treat lack of any permissions as a problem (as we must check FLS).
                // So: no Help Permission Set assisnments at all = same effect as no subscription...            
                if (! (UPs[0] || UPs[1] || UPs[2] || UPs[3])) {
                    strHeader += '<w:p>';
                    strHeader += '<w:pPr><w:pStyle w:val="Heading1"/></w:pPr>';
                    strHeader += '<w:r><w:t>';
                    strHeader += 'Permission denied';
                    strHeader +='</w:t></w:r>';
                    strHeader += '</w:p>';              
                    
                    
                } else {
                    // If permissions are in play, add the topic-driven document content
                    if (RLID != '') {
                        HelpReadingListEntry__c[] RLEs = [SELECT Id, ReadingOrder__c, 
                                                          HelpTopic__r.Name, HelpTopic__r.Summary__c, HelpTopic__r.Description__c,
                                                          HelpReadingList__r.Name, HelpReadingList__r.Summary__c, HelpReadingList__r.Description__c
                                                          FROM HelpReadingListEntry__c
                                                          WHERE HelpReadingList__c=:RLID
                                                          ORDER BY ReadingOrder__c];
                        
                        
                        for (HelpReadingListEntry__c RLE : RLEs) {
                            
                            //Reaing list info - but only add this once!
                            
                            if (RLE.ReadingOrder__c == 0) {
                                strHeader += '<w:p>';
                                strHeader += '<w:pPr><w:pStyle w:val="Heading1"/></w:pPr>';
                                strHeader += '<w:r><w:t>';
                                strHeader += string.escapeSingleQuotes(XMLEscape(getInnerText(RLE.HelpReadingList__r.Name)));
                                strHeader +='</w:t></w:r>';
                                strHeader += '</w:p>';              
                                
                                strHeader += '<w:p>';
                                strHeader += '<w:r><w:t>';
                                strHeader += string.escapeSingleQuotes(XMLEscape(getInnerText(RLE.HelpReadingList__r.Summary__c)));
                                strHeader +='</w:t></w:r>';
                                strHeader += '</w:p>';              
                                
                                strHeader += '<w:p>';
                                strHeader += '<w:r><w:t>';
                                strHeader += string.escapeSingleQuotes(XMLEscape(getInnerText(RLE.HelpReadingList__r.Description__c)));
                                strHeader +='</w:t></w:r>';
                                strHeader += '</w:p>';                                          
                            }
                            
                            // Entry info                   
                            strHeader += '<w:p>';
                            strHeader += '<w:pPr><w:pStyle w:val="Heading2"/></w:pPr>';
                            strHeader += '<w:r><w:t>';
                            strHeader += string.escapeSingleQuotes(XMLEscape(getInnerText(RLE.HelpTopic__r.Name)));
                            strHeader +='</w:t></w:r>';
                            strHeader += '</w:p>';              
                            
                            strHeader += '<w:p>';
                            strHeader += '<w:r><w:t>';
                            strHeader += string.escapeSingleQuotes(XMLEscape(getInnerText(RLE.HelpTopic__r.Summary__c)));
                            strHeader +='</w:t></w:r>';
                            strHeader += '</w:p>';              
                            
                            strHeader += '<w:p>';
                            strHeader += '<w:r><w:t>';
                            strHeader += string.escapeSingleQuotes(XMLEscape(getInnerText(RLE.HelpTopic__r.Description__c)));
                            strHeader +='</w:t></w:r>';
                            strHeader += '</w:p>';              
                            
                        }
                        
                    }
                    
                    if (HTID != '') {
                        HelpTopic__c HT = [SELECT Id, Name, Summary__c, Description__c
                                           FROM HelpTopic__c
                                           WHERE Id=:HTID];
                        
                        strHeader += '<w:p>';
                        strHeader += '<w:pPr><w:pStyle w:val="Heading1"/></w:pPr>';
                        strHeader += '<w:r><w:t>';
                        strHeader += string.escapeSingleQuotes(XMLEscape(getInnerText(HT.Name)));
                        strHeader +='</w:t></w:r>';
                        strHeader += '</w:p>';              
                        
                        strHeader += '<w:p>';
                        strHeader += '<w:r><w:t>';
                        strHeader += string.escapeSingleQuotes(XMLEscape(getInnerText(HT.Summary__c)));
                        strHeader +='</w:t></w:r>';
                        strHeader += '</w:p>';              
                        
                        strHeader += '<w:p>';
                        strHeader += '<w:r><w:t>';
                        strHeader += string.escapeSingleQuotes(XMLEscape(getInnerText(HT.Description__c)));
                        strHeader +='</w:t></w:r>';
                        strHeader += '</w:p>';              
                        
                    }
                    
                }
                
                
                // Document closure
                strHeader += '</w:body>';
                strHeader += '</w:document>';
                strHeader += '</pkg:xmlData>';
                strHeader += '</pkg:part>';
                
                
                // Styles definition block
                strHeader += '<pkg:part pkg:name="/word/styles.xml" pkg:contentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml">';
                strHeader += '<pkg:xmlData>';
                strHeader += '<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" >';
                strHeader += '<w:style w:type="paragraph" w:styleId="Heading1"><w:name w:val="heading 1"/><w:basedOn w:val="Normal"/>';
                strHeader += '<w:rPr><w:rFonts w:asciiTheme="majorHAnsi" w:eastAsiaTheme="majorEastAsia" w:hAnsiTheme="majorHAnsi" w:cstheme="majorBidi"/><w:color w:val="2E74B5" w:themeColor="accent1" w:themeShade="BF"/><w:sz w:val="32"/><w:szCs w:val="32"/></w:rPr>';
                strHeader += '</w:style>';
                strHeader += '<w:style w:type="paragraph" w:styleId="Heading2"><w:name w:val="heading 2"/><w:basedOn w:val="Normal"/>';
                strHeader += '<w:rPr><w:rFonts w:asciiTheme="majorHAnsi" w:eastAsiaTheme="majorEastAsia" w:hAnsiTheme="majorHAnsi" w:cstheme="majorBidi"/><w:color w:val="2E74B5" w:themeColor="accent1" w:themeShade="BF"/><w:sz w:val="24"/><w:szCs w:val="24"/></w:rPr>';
                strHeader += '</w:style>';
                strHeader += '</w:styles></pkg:xmlData></pkg:part>';
                
                
            } catch (exception e) {
                strHeader = 'Error exporting Help content to WordprocessingML format: ' + e.getMessage();
            }
            
            
            return strHeader;
        }
    }
    
    
    // Dump out a Reading list to slides in OpenXML format
    public String ioDataPPT {
        get {
            String strHeader = '';
            String RLID;
            Integer IdRoot = 50000;
            
            try {
                
                // Check user has *some* help access            
                ServiceSecurity Security = new ServiceSecurity();
                Boolean[] UPs = Security.UserPermissions();
                
                // Treat lack of any permissions as a problem (as we must check FLS).
                // So: no Help Permission Set assisnments at all = same effect as no subscription...            
                if (! (UPs[0] || UPs[1] || UPs[2] || UPs[3])) {
                    return '';
                }
                
                
                RLID = ServiceSecurity.getQueryParameter('RLID', 2);
                
                HelpReadingListEntry__c[] RLEs = [SELECT Id, ReadingOrder__c,
                                                  HelpTopic__r.Name, HelpTopic__r.Summary__c, HelpTopic__r.Description__c
                                                  FROM HelpReadingListEntry__c
                                                  WHERE HelpReadingList__c=:RLID
                                                  ORDER BY ReadingOrder__c];
                
                // Global presentation definition             
                strHeader += '<pkg:part pkg:name="/_rels/.rels" pkg:contentType="application/vnd.openxmlformats-package.relationships+xml">';
                strHeader += '<pkg:xmlData>';
                strHeader += '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">';
                strHeader += '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="ppt/presentation.xml"/>';
                strHeader += '</Relationships>';
                strHeader += '</pkg:xmlData>';
                strHeader += '</pkg:part>';
                
                // Show and its RELS
                strHeader += '<pkg:part pkg:name="/ppt/presentation.xml" pkg:contentType="application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml">';
                strHeader += '<pkg:xmlData>';
                strHeader += '<p:presentation xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">';
                strHeader += '<p:sldMasterIdLst><p:sldMasterId r:id="rId1"/></p:sldMasterIdLst>';
                
                // Add a slide to the show's list for each RLE
                strHeader += '<p:sldIdLst>';
                for (HelpReadingListEntry__c RLE : RLEs) {
                    strHeader += '<p:sldId id="' + (IdRoot + RLE.ReadingOrder__c) + '" r:id="rId' + (IdRoot + RLE.ReadingOrder__c) + '"/>';
                }                               
                strHeader += '</p:sldIdLst>';
                
                strHeader += '<p:sldSz cx="12192000" cy="6858000"/><p:notesSz cx="6858000" cy="9144000"/>';
                strHeader += '</p:presentation>';
                strHeader += '</pkg:xmlData>';
                strHeader += '</pkg:part>';
                
                strHeader += '<pkg:part pkg:name="/ppt/_rels/presentation.xml.rels" pkg:contentType="application/vnd.openxmlformats-package.relationships+xml">';
                strHeader += '<pkg:xmlData>';
                strHeader += '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">';
                
                // Add a slide relationship for each RLE                
                for (HelpReadingListEntry__c RLE : RLEs) {
                    strHeader += '<Relationship Id="rId' + (IdRoot + RLE.ReadingOrder__c) + '" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="slides/slide' + RLE.ReadingOrder__c + '.xml"/>';
                }                               
                
                strHeader += '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" Target="slideMasters/slideMaster1.xml"/>';
                strHeader += '<Relationship Id="rId5" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme" Target="theme/theme1.xml"/>';
                strHeader += '</Relationships>';
                strHeader += '</pkg:xmlData>';
                strHeader += '</pkg:part>';
                
                
                // Now add the topic-driven slides and their RELS
                for (HelpReadingListEntry__c RLE : RLEs) {
                    
                    strHeader += '<pkg:part pkg:name="/ppt/slides/slide' + RLE.ReadingOrder__c + '.xml" pkg:contentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml">';
                    strHeader += '<pkg:xmlData>';
                    strHeader += '<p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">';                  
                    strHeader += '<p:cSld><p:spTree><p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr>';
                    
                    strHeader += '<p:sp><p:nvSpPr><p:cNvPr id="2" name=""/><p:cNvSpPr><a:spLocks /></p:cNvSpPr><p:nvPr><p:ph/></p:nvPr></p:nvSpPr><p:spPr/>';
                    strHeader += '<p:txBody><a:bodyPr/><a:p><a:r><a:t>' + string.escapeSingleQuotes(XMLEscape(getInnerText(RLE.HelpTopic__r.Name))) + '</a:t></a:r></a:p></p:txBody>';
                    strHeader += '</p:sp>';
                    
                    strHeader += '<p:sp><p:nvSpPr><p:cNvPr id="3" name=""/><p:cNvSpPr><a:spLocks /></p:cNvSpPr><p:nvPr><p:ph idx="1"/></p:nvPr></p:nvSpPr><p:spPr/>';
                    strHeader += '<p:txBody><a:bodyPr/><a:lstStyle/><a:p><a:r><a:t>' + string.escapeSingleQuotes(XMLEscape(getInnerText(RLE.HelpTopic__r.Summary__c))) + '</a:t></a:r></a:p></p:txBody>';
                    strHeader += '</p:sp>';
                    
                    strHeader += '</p:spTree></p:cSld>';
                    strHeader += '</p:sld>';
                    strHeader += '</pkg:xmlData>';
                    strHeader += '</pkg:part>';
                    
                    strHeader += '<pkg:part pkg:name="/ppt/slides/_rels/slide' + RLE.ReadingOrder__c + '.xml.rels" pkg:contentType="application/vnd.openxmlformats-package.relationships+xml">';
                    strHeader += '<pkg:xmlData>';
                    strHeader += '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">';
                    strHeader += '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout2.xml"/>';
                    strHeader += '</Relationships>';
                    strHeader += '</pkg:xmlData>';
                    strHeader += '</pkg:part>';
                    
                }
                
                // Slide layout and its RELS
                
                strHeader += '<pkg:part pkg:name="/ppt/slideLayouts/slideLayout2.xml" pkg:contentType="application/vnd.openxmlformats-officedocument.presentationml.slideLayout+xml">';
                strHeader += '<pkg:xmlData>';
                strHeader += '<p:sldLayout type="obj" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">';             
                strHeader += '<p:cSld><p:spTree>';
                strHeader += '<p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr>';
                strHeader += '<p:sp><p:nvSpPr><p:cNvPr id="2" name=""/><p:cNvSpPr><a:spLocks/></p:cNvSpPr><p:nvPr><p:ph type="title"/></p:nvPr></p:nvSpPr><p:spPr/><p:txBody><a:bodyPr/><a:lstStyle/><a:p><a:r><a:t>Title</a:t></a:r></a:p></p:txBody></p:sp>';
                strHeader += '<p:sp><p:nvSpPr><p:cNvPr id="3" name=""/><p:cNvSpPr><a:spLocks/></p:cNvSpPr><p:nvPr><p:ph idx="1"/></p:nvPr></p:nvSpPr><p:spPr/><p:txBody><a:bodyPr/><a:lstStyle/><a:p><a:pPr lvl="0"/><a:r><a:t>Text</a:t></a:r></a:p></p:txBody></p:sp>';
                strHeader += '</p:spTree></p:cSld>';
                strHeader += '</p:sldLayout>';
                strHeader += '</pkg:xmlData>';
                strHeader += '</pkg:part>';
                
                strHeader += '<pkg:part pkg:name="/ppt/slideLayouts/_rels/slideLayout2.xml.rels" pkg:contentType="application/vnd.openxmlformats-package.relationships+xml">';
                strHeader += '<pkg:xmlData>';
                strHeader += '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">';
                strHeader += '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" Target="../slideMasters/slideMaster1.xml"/>';
                strHeader += '</Relationships>';
                strHeader += '</pkg:xmlData>';
                strHeader += '</pkg:part>';
                
                
                // The Master referenced by the Layout
                
                strHeader += '<pkg:part pkg:name="/ppt/slideMasters/slideMaster1.xml" pkg:contentType="application/vnd.openxmlformats-officedocument.presentationml.slideMaster+xml">';
                strHeader += '<pkg:xmlData>';
                strHeader += '<p:sldMaster xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">';
                
                strHeader += '<p:cSld><p:bg><p:bgRef idx="1001"><a:schemeClr val="bg1"/></p:bgRef></p:bg><p:spTree>';
                strHeader += '<p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr>';
                strHeader += '<p:sp><p:nvSpPr><p:cNvPr id="2" name=""/><p:cNvSpPr></p:cNvSpPr><p:nvPr><p:ph type="title"/></p:nvPr></p:nvSpPr><p:spPr><a:xfrm><a:off x="838200" y="365125"/><a:ext cx="10515600" cy="1325563"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></p:spPr><p:txBody><a:bodyPr vert="horz" lIns="91440" tIns="45720" rIns="91440" bIns="45720" rtlCol="0" anchor="ctr"><a:normAutofit/></a:bodyPr><a:p><a:r><a:t>Title</a:t></a:r></a:p></p:txBody></p:sp>';
                strHeader += '<p:sp><p:nvSpPr><p:cNvPr id="3" name=""/><p:cNvSpPr></p:cNvSpPr><p:nvPr><p:ph type="body" idx="1"/></p:nvPr></p:nvSpPr><p:spPr><a:xfrm><a:off x="838200" y="1825625"/><a:ext cx="10515600" cy="4351338"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></p:spPr><p:txBody><a:bodyPr vert="horz" lIns="91440" tIns="45720" rIns="91440" bIns="45720" rtlCol="0"><a:normAutofit/></a:bodyPr><a:p><a:pPr lvl="0"/><a:r><a:t>Text</a:t></a:r></a:p></p:txBody></p:sp>';
                strHeader += '</p:spTree></p:cSld>';
                
                strHeader += '<p:clrMap bg1="lt1" tx1="dk1" bg2="lt2" tx2="dk2" accent1="accent1" accent2="accent2" accent3="accent3" accent4="accent4" accent5="accent5" accent6="accent6" hlink="hlink" folHlink="folHlink"/>';
                strHeader += '<p:sldLayoutIdLst><p:sldLayoutId id="2147483650" r:id="rId2"/></p:sldLayoutIdLst>';
                
                strHeader += '</p:sldMaster>';
                strHeader += '</pkg:xmlData>';
                strHeader += '</pkg:part>';
                
                
                strHeader += '<pkg:part pkg:name="/ppt/slideMasters/_rels/slideMaster1.xml.rels" pkg:contentType="application/vnd.openxmlformats-package.relationships+xml">';
                strHeader += '<pkg:xmlData>';
                strHeader += '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">';
                strHeader += '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout2.xml"/>';
                strHeader += '<Relationship Id="rId12" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme" Target="../theme/theme1.xml"/>';                
                strHeader += '</Relationships>';
                strHeader += '</pkg:xmlData>';
                strHeader += '</pkg:part>';
                
                
                // The Theme referenced by the Master
                
                strHeader += '<pkg:part pkg:name="/ppt/theme/theme1.xml" pkg:contentType="application/vnd.openxmlformats-officedocument.theme+xml">';
                strHeader += '<pkg:xmlData>';
                strHeader += '<a:theme name="Office Theme" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"><a:themeElements>';
                
                strHeader += '<a:clrScheme name="">';
                strHeader += '<a:dk1><a:sysClr val="windowText" lastClr="000000"/></a:dk1><a:lt1><a:sysClr val="window" lastClr="FFFFFF"/></a:lt1><a:dk2><a:srgbClr val="44546A"/></a:dk2><a:lt2><a:srgbClr val="E7E6E6"/></a:lt2><a:accent1><a:srgbClr val="5B9BD5"/></a:accent1><a:accent2><a:srgbClr val="ED7D31"/></a:accent2><a:accent3><a:srgbClr val="A5A5A5"/></a:accent3><a:accent4><a:srgbClr val="FFC000"/></a:accent4><a:accent5><a:srgbClr val="4472C4"/></a:accent5><a:accent6><a:srgbClr val="70AD47"/></a:accent6><a:hlink><a:srgbClr val="0563C1"/></a:hlink><a:folHlink><a:srgbClr val="954F72"/></a:folHlink>';
                strHeader += '</a:clrScheme>';
                
                strHeader += '<a:fontScheme name="">';
                strHeader += '<a:majorFont><a:latin typeface=""/><a:ea typeface=""/><a:cs typeface=""/></a:majorFont><a:minorFont><a:latin typeface=""/><a:ea typeface=""/><a:cs typeface=""/></a:minorFont>';
                strHeader += '</a:fontScheme>';
                
                strHeader += '<a:fmtScheme name="">';
                strHeader += '<a:fillStyleLst><a:solidFill></a:solidFill><a:solidFill></a:solidFill><a:solidFill></a:solidFill></a:fillStyleLst><a:lnStyleLst><a:ln></a:ln><a:ln></a:ln><a:ln></a:ln></a:lnStyleLst><a:effectStyleLst><a:effectStyle><a:effectLst/></a:effectStyle><a:effectStyle><a:effectLst/></a:effectStyle><a:effectStyle><a:effectLst/></a:effectStyle></a:effectStyleLst><a:bgFillStyleLst><a:solidFill><a:schemeClr val="phClr"/></a:solidFill><a:solidFill><a:schemeClr val="phClr"/></a:solidFill><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:bgFillStyleLst>';
                strHeader += '</a:fmtScheme>';
                
                strHeader += '</a:themeElements></a:theme>';
                strHeader += '</pkg:xmlData>';
                strHeader += '</pkg:part>';
                
            } catch (exception e) {
                strHeader = 'Error exporting Help content to slideshow format: ' + e.getMessage();
            }
            
            
            return strHeader;
        }
    }
    
    
    // Export the same kinds of Help content as would be sent to Excel but as a series of JSON files:
    // This routine is capable of higher record numbers: Excel uses the default 'ExportRows' value of 1k
    // per table whereas this can be set higher (5k has worked)
    public string ExportDataJSONDoc() {
        
        // Diagnostics strings, including return value and messgaes for confirmatory email
        string retVal = '';
        string msgP = '';
        string msgH = '';
        string CRP = String.fromCharArray(new List<integer>{10,13});
        string CRH = '<br/>';
        integer rowCount;
        
        // Folder in which to produce downloads, plus document object to produce and details of its name
        Folder Fld;
        Document Doc;
        string docName;
        string docDesc;
        
        // DISABLING FOR THIS RELEASE
        /*        
// The records - as produced in nested calls - to download
string[] objs = new string[]{'HelpTopic', 'HelpRelationship', 'HelpReadingList', 'HelpReadingListEntry', 'HelpResource', 'HelpTopicResource', 'HelpedPageLayout', 'HelpedElement'};

// JSON string version of records thus produced, plus processing variables for marshalling this to document body
string J;    
string Block;
integer startPos = 0;
integer endPos;
integer blockSize = 3000000;


try {

docDesc = 'Help content export run: ' + datetime.now().format('dd-MMM-yyyy H:mm:ss');

// Locate the folder to house export docs
Fld = [SELECT Id FROM Folder WHERE Name='Improved Help Documents'];


// Set export of data parameters then obtain data
ExportSkipXMLChecks = true;
xlGetExportData();


// As there will be many export files and a varying number, delete them all here for convenience
try {
Document[] Docs = [SELECT Id FROM Document WHERE Name LIKE 'HelpExportJSON_%' AND FolderId=:Fld.Id];
delete Docs;
} catch (exception ex) {}


for (string objName : objs) {

// Get the JSON version of the current object in array of those to download
J = JSONGetExportData(objName);

// Loop WITHIN each object to create multiple download docs
// if JSON length stands to take individual item over max record size...

msgP += 'Processing ' + objName + ': JSON length=' + J.length() + CRP;
msgH += 'Processing ' + objName + ': JSON length=' + J.length() + CRH;

for (startPos=0; startPos < J.length(); startPos += blockSize) {

docName = 'HelpExportJSON_' + objName + '_' + ((startPos + blockSize) / blockSize);

Doc = new Document();
Doc.Name = docName;
Doc.FolderId = Fld.Id;
Doc.Type = 'json';
Doc.ContentType = 'text/json';


try {

endPos = startPos + blockSize;
if (J.length() < endPos) {endPos = J.length();}
Block = J.substring(startPos,endPos);

Doc.Body = Blob.valueOf(Block); 
Doc.Description = docDesc;        
upsert Doc;

msgP += 'Produced document ' + Doc.Id + CRP;
msgH += 'Produced document ' + Doc.Id + CRH;

retVal += Doc.Id + ',';

} catch (exception ex) {
retVal += ' - Error! ' + ex.getMessage();           
}
}


if (objName == 'HelpTopic') {
rowCount = xlTopics.size();
}
if (objName == 'HelpRelationship') {
rowCount = xlRelationships.size();
}
if (objName == 'HelpReadingList') {
rowCount = xlReadingLists.size();
}
if (objName == 'HelpReadingListEntry') {
rowCount = xlReadingListEntries.size();
}
if (objName == 'HelpResource') {
rowCount = xlResources.size();
}
if (objName == 'HelpTopicResource') {
rowCount = xlHelpTopicResources.size();
}
if (objName == 'HelpedElement') {
rowCount = xlHelpedElements.size();
}
if (objName == 'HelpedPageLayout') {
rowCount = xlHelpedPageLayouts.size();
}


msgP += 'Total records: ' + rowCount + CRP + CRP;
msgH += 'Total records: ' + rowCount + CRH + CRH;

}

} catch (exception e) {
retVal = 'No folder or basic export error';
}


// Send email confirming results of activity and return
msgP = 'Improved Help content download proceeded as follows:' + CRP + CRP + msgP;
msgH = '<b>Improved Help content download proceeded as follows:</b>' + CRH + CRH + msgH;

generateEmail('Improved Help: JSON download report: ' + UserInfo.getOrganizationName(), msgP, msgH, null);
*/
        
        return retVal;
    }
    
    
    // Support function for processing individual help records collection, from the several ususally
    // exported to Excel, to JSON
    private string JSONGetExportData(string HelpObject) {
        
        string retVal = '';
        
        try {
            if (HelpObject == 'HelpTopic') {
                retVal = JSON.serialize(xlTopics);
            }
            if (HelpObject == 'HelpRelationship') {
                retVal = JSON.serialize(xlRelationships);
            }
            if (HelpObject == 'HelpReadingList') {
                retVal = JSON.serialize(xlReadingLists);
            }
            if (HelpObject == 'HelpReadingListEntry') {
                retVal = JSON.serialize(xlReadingListEntries);
            }
            if (HelpObject == 'HelpResource') {
                retVal = JSON.serialize(xlResources);
            }
            if (HelpObject == 'HelpTopicResource') {
                retVal = JSON.serialize(xlHelpTopicResources);
            }
            if (HelpObject == 'HelpedPageLayout') {
                retVal = JSON.serialize(xlHelpedPageLayouts);
            }
            if (HelpObject == 'HelpedElement') {
                retVal = JSON.serialize(xlHelpedElements);
            }
            
        } catch (exception e) { 
            retVal = e.getMessage();    
        }
        
        return retVal;
    }
    
    
    // Populate collections of Improved Help objects for export to Excel:
    // Supporting comma separated list of HTIDs, defining the scope of any Help content export  
    // Supporting max rows to export (will default inline in exporter to 1000 if not set)
    // Supporting instructions to skip parsing of help description rich text etc into an XML-safe format
    global string ExportScope {get; set;}
    global integer ExportRows {get; set;}
    global boolean ExportSkipXMLChecks {get; set;}
    
    global void xlGetExportData() {
        try {
            
            // Check user has *some* help access            
            ServiceSecurity Security = new ServiceSecurity();
            Boolean[] UPs = Security.UserPermissions();
            
            // Flag indicating that filter is in play controlling records being output
            Boolean Scoped = false;
            
            // Treat lack of any permissions as a problem (as we must check FLS).
            // So: no Help Permission Set assisnments at all = same effect as no subscription...            
            if (! (UPs[0] || UPs[1] || UPs[2] || UPs[3])) {
                return;
            }
            
            
            // Default our export row limit if required
            if (ExportRows == null) {
                ExportRows = 1000;
            }
            
            
            // Scope limiting variables:
            string strSOQLHTs;                                              // SOQL to derive...
            map<id,HelpTopic__c> exportHTs = new map<id, HelpTopic__c>();   // ... map of Help Topics, defined by incoming scoping Help Topic IDs
            map<string, string> exportRLs = new map<string, string>();      // Reading Lists featuring these topics
            map<string, string> exportHPLs = new map<string, string>();     // Page Layouts featuring these topics
            
            map<string, string> exportHFs = new map<string, string>();     // Help filters referenced by elements on these HPLs
            
            try {
                
                // Limit our download scope to specified topics, if provided
                strSOQLHTs = 'SELECT Id FROM HelpTopic__c';
                
                // If we're in an APEX / page scenario, export scope can be taken from request parameters
                boolean ApexPageExists = ServiceSecurity.ApexPageExists();
                
                if (ApexPageExists) {
                    // Don't replace scope provided directly via member data
                    if (ExportScope == '' || ExportScope == null) {
                        ExportScope = ServiceSecurity.getQueryParameter('Scope', 2);
                    }
                } 
                
                
                if (ExportScope != '' && ExportScope != null) {
                    
                    string[] HTIDs = ExportScope.split(',');
                    
                    strSOQLHTs += ' WHERE Id IN(';
                    for (string HTID : HTIDs) {
                        strSOQLHTs += '\'' + HTID + '\',';
                    }
                    strSOQLHTs = strSOQLHTs.substring(0, strSOQLHTs.length() - 1);
                    strSOQLHTs += ')';
                    
                    // Note the fact that a filter is being used
                    Scoped = true;
                    
                }
                
                
                // Queries are impacted by whether or not filters are in play:
                // Do not build 'ID IN' -type clauses un-necessarily                 
                if (Scoped == true) {                
                    try {
                        HelpTopic__c[] ExpHTs = database.query(strSOQLHTs);
                        for(HelpTopic__c ExpHT : ExpHTs) {
                            exportHTs.put(ExpHT.Id, ExpHT);
                        }
                        
                    } catch (exception exc) {}
                }
                
                
                // Get help topics for export
                if (Scoped == true) {                
                    xlTopics = [SELECT
                                Id, Name, Summary__c, MasterTopicIdentifier__c, Description__c, 
                                Keyword__c,                                    
                                CalloutHeight__c, CalloutMediaChoice__c, CalloutTemplate__r.PageURL__c,
                                HeightBeforeScrolling__c, Template__r.PageURL__c, 
                                LightningTemplate__r.Name, 
                                SalesforceHelpURL__c, 
                                ShowReferringRelationships__c, ShowReadMoreLink__c, HelpTopicStatus__c, Visibility__c, Active__c, CustomStyle__c,  
                                GuidedLayout__c, GuidedRecord__c, GuidedElement__c, GuideStepMode__c, GuideCallout__c,   
                                HelpVoteSet__c,                 
                                ImageHeight__c, ImageWidth__c, ImageCaption__c, ImageTitle__c, ImageURL__c, ImageALTText__c,
                                VideoHeight__c, VideoWidth__c, VideoCaption__c, VideoTitle__c, VideoURL__c
                                FROM HelpTopic__c
                                WHERE id IN :exportHTs.keySet()
                                LIMIT :ExportRows]; 
                    
                } else {
                    xlTopics = [SELECT
                                Id, Name, Summary__c, MasterTopicIdentifier__c, Description__c, 
                                Keyword__c,                                    
                                CalloutHeight__c, CalloutMediaChoice__c, CalloutTemplate__r.PageURL__c,
                                HeightBeforeScrolling__c, Template__r.PageURL__c, 
                                LightningTemplate__r.Name, 
                                SalesforceHelpURL__c, 
                                ShowReferringRelationships__c, ShowReadMoreLink__c, HelpTopicStatus__c, Visibility__c, Active__c, CustomStyle__c,  
                                GuidedLayout__c, GuidedRecord__c, GuidedElement__c, GuideStepMode__c, GuideCallout__c,   
                                HelpVoteSet__c,                 
                                ImageHeight__c, ImageWidth__c, ImageCaption__c, ImageTitle__c, ImageURL__c, ImageALTText__c,
                                VideoHeight__c, VideoWidth__c, VideoCaption__c, VideoTitle__c, VideoURL__c
                                FROM HelpTopic__c
                                LIMIT :ExportRows]; 
                }
                
                // Avoid XML issues by encoding rich text fields that may contain tags:
                // As this is time consuming etc., do this only if we're producing XML output
                // (need not do this when processing to JSON)
                if (ExportSkipXMLChecks != true) {
                    for(HelpTopic__c HT : xlTopics) {
                        
                        try {                   
                            HT.Description__c = HT.Description__c.replace('<br>', '<br/>');
                            HT.Description__c = EncodingUtil.urlEncode(HT.Description__c, 'UTF-8'); 
                        } catch (exception e) {
                            HT.Description__c = '';
                        }
                        
                        HT.Name = XMLEscape(HT.Name); 
                        HT.Summary__c = XMLEscape(HT.Summary__c);
                        HT.MasterTopicIdentifier__c = XMLEscape(HT.MasterTopicIdentifier__c);
                        HT.SalesforceHelpURL__c = XMLEscape(HT.SalesforceHelpURL__c);
                        HT.HelpTopicStatus__c = XMLEscape(HT.HelpTopicStatus__c);
                        HT.Visibility__c = XMLEscape(HT.Visibility__c);
                        HT.CustomStyle__c = XMLEscape(HT.CustomStyle__c);
                        HT.GuidedRecord__c = XMLEscape(HT.GuidedRecord__c);
                        HT.ImageCaption__c = XMLEscape(HT.ImageCaption__c);
                        HT.ImageTitle__c = XMLEscape(HT.ImageTitle__c);
                        HT.ImageURL__c = XMLEscape(HT.ImageURL__c);
                        HT.ImageALTText__c = XMLEscape(HT.ImageALTText__c);
                        HT.VideoCaption__c = XMLEscape(HT.VideoCaption__c);
                        HT.VideoTitle__c = XMLEscape(HT.VideoTitle__c);
                        HT.VideoURL__c = XMLEscape(HT.VideoURL__c);
                        
                    }
                }                                            
                
            } catch (exception ex){}
            
            
            // Ditto help relationships
            try {
                if (Scoped == true) {               
                    xlRelationships = [SELECT ReferringTopic__c, RelatedHelpTopic__c, SemanticTag__r.Name, Order__c
                                       FROM HelpRelationship__c
                                       WHERE ReferringTopic__c IN :exportHTs.keySet()
                                       OR RelatedHelpTopic__c IN :exportHTs.keySet()                           
                                       LIMIT :ExportRows];
                } else {
                    xlRelationships = [SELECT ReferringTopic__c, RelatedHelpTopic__c, SemanticTag__r.Name, Order__c
                                       FROM HelpRelationship__c
                                       LIMIT :ExportRows];
                }
            } catch (exception ex){}
            
            
            // Ditto RL Entries
            try {
                if (Scoped == true) {
                    xlReadingListEntries = [SELECT HelpReadingList__c, HelpTopic__c, ReadingOrder__c,
                                            DisplayRow__c, DisplayColumn__c, NavigationType__c, NavigationDetails__c
                                            FROM HelpReadingListEntry__c
                                            WHERE HelpTopic__c IN :exportHTs.keySet()                           
                                            LIMIT :ExportRows];
                } else {
                    xlReadingListEntries = [SELECT HelpReadingList__c, HelpTopic__c, ReadingOrder__c,
                                            DisplayRow__c, DisplayColumn__c, NavigationType__c, NavigationDetails__c
                                            FROM HelpReadingListEntry__c
                                            LIMIT :ExportRows];
                }   
            } catch (exception ex){}
            
            
            // Ditto reading lists (scoping clause not direectly applicable here)          
            try {
                // These are limited by RL entries (featuring export scope topics) found above...
                for (HelpReadingListEntry__c RLE : xlReadingListEntries) {
                    if (exportRLs.containsKey(RLE.HelpReadingList__c) == false) {
                        exportRLs.put(RLE.HelpReadingList__c, RLE.HelpReadingList__c);
                    }
                }               
                
                xlReadingLists = [SELECT Id, Name, Summary__c, Description__c, FeaturedUntil__c, ReadingListStatus__c, ReadingListType__c
                                  , LightningPresentationStyle__c                
                                  FROM HelpReadingList__c
                                  WHERE Id IN :exportRLs.keySet()                         
                                  LIMIT :ExportRows];                
                
                // Avoid XML issues by encoding rich text fields that may contain tags
                for(HelpReadingList__c RL : xlReadingLists) {
                    
                    try {                   
                        RL.Description__c = RL.Description__c.replace('<br>', '<br/>');
                        RL.Description__c = EncodingUtil.urlEncode(RL.Description__c, 'UTF-8'); 
                        
                        RL.Name = XMLEscape(RL.Name);
                        RL.Summary__c = XMLEscape(RL.Summary__c);
                        RL.ReadingListStatus__c = XMLEscape(RL.ReadingListStatus__c);
                        
                    } catch (exception e) {
                        RL.Description__c = '';
                    }
                    
                }
            } catch (exception ex){}
            
            
            // Ditto Resources - these are NOT filtered
            try {
                xlResources = [SELECT Id, Name, Summary__c, Location__c, ResourceType__c, ResourceURL__c
                               FROM HelpResource__c
                               LIMIT :ExportRows];
            } catch (exception ex){}
            
            for (HelpResource__c R : xlResources) {
                R.Name = XMLEscape(R.Name);
                R.Summary__c = XMLEscape(R.Summary__c);
                R.Location__c = XMLEscape(R.Location__c);
                R.ResourceType__c = XMLEscape(R.ResourceType__c);
                R.ResourceURL__c = XMLEscape(R.ResourceURL__c);
            }
            
            // Ditto Help Topic Resources - these ARE filtered
            try {
                if (Scoped == true) {               
                    xlHelpTopicResources = [SELECT HelpResource__c, HelpTopic__c, UsageNotes__c
                                            FROM HelpTopicResource__c
                                            WHERE HelpTopic__c IN :exportHTs.keySet()                           
                                            LIMIT :ExportRows];
                } else {
                    xlHelpTopicResources = [SELECT HelpResource__c, HelpTopic__c, UsageNotes__c
                                            FROM HelpTopicResource__c
                                            LIMIT :ExportRows];
                }   
            } catch (exception ex){}
            
            for (HelpTopicResource__c HTR : xlHelpTopicResources){  
                HTR.UsageNotes__c = XMLEscape(HTR.UsageNotes__c);
            }
            
            // Ditto Helped Elements
            try{
                if (Scoped == true) {               
                    xlHelpedElements = [SELECT HelpedPageLayout__c, ElementType__c, HelpTopic__c, Name, Identifier__c, Visibility__c, HelpFilter__c, DataDrivenFilter__c, UseForNew__c, Parameters__c
                                        FROM HelpedElement__c
                                        WHERE HelpTopic__c IN :exportHTs.keySet()                                                       
                                        LIMIT :ExportRows];
                } else {
                    xlHelpedElements = [SELECT HelpedPageLayout__c, ElementType__c, HelpTopic__c, Name, Identifier__c, Visibility__c, HelpFilter__c, DataDrivenFilter__c, UseForNew__c, Parameters__c
                                        FROM HelpedElement__c
                                        LIMIT :ExportRows];
                }
            } catch (exception ex){}
            
            for (HelpedElement__c HE : xlHelpedElements) {
                HE.Name = XMLEscape(HE.Name);
                HE.DataDrivenFilter__c = XMLEscape(HE.DataDrivenFilter__c);
                
                if (exportHFs.containsKey(HE.HelpFilter__c) == false) {               
                    exportHFs.put(HE.HelpFilter__c, HE.HelpFilter__c);
                }           
            }
            
            
            // Ditto Helped Page Layouts
            try {
                // These are limited by Elements (featuring Export scope topics) found above
                for (HelpedElement__c HE : xlHelpedElements) {
                    if (exportHPLs.containsKey(HE.HelpedPageLayout__c) == false) {
                        exportHPLs.put(HE.HelpedPageLayout__c, HE.HelpedPageLayout__c);
                    }
                }               
                
                xlHelpedPageLayouts = [SELECT Id, Name, PageLayoutIdentifier__c, PageType__c, AllowComments__c, RehookTimes__c, RehookInterval__c
                                       FROM HelpedPageLayout__c
                                       WHERE Id IN :exportHPLs.keySet()                            
                                       LIMIT :ExportRows];
            } catch (exception ex){}
            
            for (HelpedPageLayout__c HPL : xlHelpedPageLayouts) {
                HPL.Name = XMLEscape(HPL.Name);
            }    
            
            
            
            // Ditto Help Filters
            try{
                if (Scoped == true) {               
                    xlHelpFilters = [SELECT Id, FilterIdentifier__c, FilterLogic__c, FilteredObject__c, FilteredObjectIdentifier__c
                                     FROM HelpFilter__c
                                     WHERE Id IN :exportHFs.keySet()                                                       
                                     LIMIT :ExportRows];
                } else {
                    xlHelpFilters = [SELECT Id, FilterIdentifier__c, FilterLogic__c, FilteredObject__c, FilteredObjectIdentifier__c
                                     FROM HelpFilter__c
                                     LIMIT :ExportRows];
                }
            } catch (exception ex){}
            
            for (HelpFilter__c HF : xlHelpFilters) {
                HF.FilterIdentifier__c = XMLEscape(HF.FilterIdentifier__c);
                HF.FilterLogic__c = XMLEscape(HF.FilterLogic__c);
                HF.FilteredObject__c = XMLEscape(HF.FilteredObject__c);
                HF.FilteredObjectIdentifier__c = XMLEscape(HF.FilteredObjectIdentifier__c);
            }
            
            
            
            // Ditto Help Filter Criteria
            try{
                if (Scoped == true) {               
                    xlHelpFilterCriteria = [SELECT HelpFilter__c, Name, CriterionNumber__c, FilteredField__c, FilteredFieldType__c, Operator__c, FilterValue__c
                                            FROM HelpFilterCriterion__c
                                            WHERE HelpFilter__c IN :exportHFs.keySet()                                                       
                                            LIMIT :ExportRows];
                } else {
                    xlHelpFilterCriteria = [SELECT HelpFilter__c, Name, CriterionNumber__c, FilteredField__c, FilteredFieldType__c, Operator__c, FilterValue__c
                                            FROM HelpFilterCriterion__c
                                            LIMIT :ExportRows];
                }
            } catch (exception ex){}
            
            for (HelpFilter__c HF : xlHelpFilters) {
                HF.FilterIdentifier__c = XMLEscape(HF.FilterIdentifier__c);
                HF.FilterLogic__c = XMLEscape(HF.FilterLogic__c);
                HF.FilteredObject__c = XMLEscape(HF.FilteredObject__c);
                HF.FilteredObjectIdentifier__c = XMLEscape(HF.FilteredObjectIdentifier__c);
            }
            
            
        } catch (exception e) {         
        }
        
        return;
    }
    
    
    
    // Strip HTML / XML tags from a string (not >, < as such - only <tags>) 
    public String getInnerText(String markup){
        if (markup == null) {markup = '';}
        string retVal;
        Pattern P = Pattern.compile('(<([^>]+)>)');     
        retVal = P.matcher(markup).replaceAll('');      
        return retVal;
    }   
    
    
    // Agressive stripping of XML risk characters - beyond what can be allowed in XML 
    // (e.g., these characters could be legitimate in comments etc.)
    // However, we don't need these for the purposes of this class, so just remove
    public String XMLEscape (string markup) {
        if (markup == null) {markup = '';}
        string retVal = markup;
        retVal = retVal.replaceAll('<', '&lt;');
        retVal = retVal.replaceAll('>', '&gt;');
        return retVal;      
    }
    
    
    // Cue export to Excel by visiting the XL Export page
    public PageReference cueXLExport() {
        return new PageReference('/apex/iahelp__IHExportXL');
    }
    
    // Cue export of RL to Word by visiting the Word Export page and specifying RLID
    public String exportRLID {get; set;}    
    public List<selectOption> getRLists () {
        List<SelectOption> options = new List<SelectOption>();
        
        try {
            for (HelpReadingList__c Temp : 
                 [SELECT Id, Name 
                  FROM HelpReadingList__c
                  ORDER BY Name
                  LIMIT 1000 
                 ]
                ) 
            {
                options.add(new SelectOption(Temp.Id, Temp.Name));
            }
            
        } catch (exception e) {                
        }
        
        return options;
    }
    
    public PageReference cueWordExportRL() {
        return new PageReference('/apex/iahelp__IHExportDoc?RLID=' + exportRLID);
    }
    
    
    // Cue export of RL to PPT by visiting the Powerpoint Export page and specifying RLID
    public PageReference cuePPTExportRL() {
        return new PageReference('/apex/iahelp__IHExportPPT?RLID=' + exportRLID);
    }
    
    
    // Cue export of individual topic to Word by visiting the Word Export page and specifying HTID
    public String exportHTID {get; set;}
    public PageReference cueWordExportHT() {
        return new PageReference('/apex/iahelp__IHExportDoc?HTID=' + exportHTID);
    }
    
    
    // Send an email to the logged in user - e.g., confirming successful completion of an asynch process
    public void generateEmail (string Subject, string msgPlain, string msgHTML, string UID) {
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses;     
        
        try {
            if (UID == null) {
                UID = UserInfo.getUserId();
            }
            
            User activeUser = [SELECT Email, Username FROM User WHERE Id = :UID LIMIT 1];
            String userEmail = activeUser.Email;
            String usrname = activeUser.Username;
            
            toAddresses = new String[] { userEmail };
                
                // Append username and userId to the email bodies
                msgPlain += '\n\nUsername: ' + usrname + '\nUser ID: ' + UID;
            msgHTML += '<br/><br/><strong>Username:</strong> ' + usrname + '<br/><strong>User ID:</strong> ' + UID;
        } catch (exception ex) {}
        
        mail.setToAddresses(toAddresses);
        
        mail.setReplyTo('support@improvedapps.com');
        mail.setSenderDisplayName('Improved Apps Support');
        mail.setSubject(Subject);
        mail.setPlainTextBody(msgPlain);
        mail.setHtmlBody(msgHTML);
        
        
        // To avoid potential limits issue, don't actually send the email if we're in a test situation
        if (! Test.isRunningTest()) {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }  
}