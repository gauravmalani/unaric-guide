/////////////////////////////////////////////////////////////////////////////////////////////////////
// Implemented this batch class to automate the initialse settings button,
// to be executed from post install script present in zInstallHandler
//
// Gaurav Patil for Unaric
// April 2025
/////////////////////////////////////////////////////////////////////////////////////////////////////


global class SeedHelpSettingsBatch implements Database.Batchable<Integer>, Database.Stateful {
    
    // Sections to process
    private List<String> sections = new List<String>{'templates', 'votes', 'tags', 'noise','metadata', 'cacheObjects', 'settings'};
        public String Diags = '';
    Map<String, String> mapGlbLocs;
    
    global Iterable<Integer> start(Database.BatchableContext bc) {
        
        System.debug('Starting Batch - Pre-processing initialization...');
        
        // Load Global Localisations
        mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false);
        
        // Permissions Check
        ServiceSecurity sS = new ServiceSecurity();
        Boolean[] UPs = sS.UserPermissions();
        
        if (UPs[2] == false) {
            Diags = mapGlbLocs.get('MessageNoRights');
            System.debug('No Admin Rights: ' + Diags);
            return new List<Integer>(); 
        }
        
        Diags += 'Initialization completed successfully. ';
        
        // this is for test class 
        if (Test.isRunningTest()) {
            return new List<Integer>{0, 1,2,3,6}; // only one section
                }
        return new List<Integer>{0, 1, 2, 3,4,5,6};
            }
    
    global void execute(Database.BatchableContext bc, List<Integer> scope) {
        for (Integer index : scope) {
            if (index < sections.size()) {
                processSection(sections[index]);
            }
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        //abort any existing Clear_InstallFlag_Job to uncheck the oninstall custom setiing.
        String jobName = 'Clear_InstallFlag_Job';
        //query any existing scheduled job with the same name
        List<CronTrigger> existingJobs = [
            SELECT Id, CronJobDetail.Name, CronJobDetailId
            FROM CronTrigger
            WHERE CronJobDetail.Name = :jobName
        ];
        
        // If any jobs found, try to abort them
        if (existingJobs != null && !existingJobs.isEmpty()) {
            for (CronTrigger job : existingJobs) {
                try {
                    if (job.Id != null) {
                        System.abortJob(job.Id);
                    }else {
                        System.debug('Job ID is null. Cannot abort this job.');
                    }
                } catch (Exception innerAbortEx) {
                    System.debug('Could not abort job with ID ' + job.Id + ': ' + innerAbortEx.getMessage());
                }
            }
        } else {
            System.debug('No existing scheduled jobs found to abort.');
        }
        //Schedule job to clear custom setting oninstall
        // String jobName = 'Clear_InstallFlag_Job';
        Datetime dt = System.now().addMinutes(3);
        Integer minute = dt.minute();
        Integer hour = dt.hour();
        Integer day = dt.day();
        Integer month = dt.month();
        
        // Cron format: "Seconds Minutes Hours Day-of-month Month Day-of-week"
        String cronExp = '0 ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ?';
        System.schedule(jobName, cronExp, new iahelp.ClearInstallFlagSchedulable());
        system.debug('Create settings batch is completed');      
    }
    
    public void processSection(String section) {
        switch on section {
            when 'metadata' {
                
                handleMetadata();
            }
            when 'cacheObjects' {
                
                handleCacheObjects();
            }
            
            when 'templates' {
                createTemplates();
            }
            when 'votes' {
                createVoteSets();
            }
            when 'tags' {
                createSemanticTags();
            }
            when 'noise' {
                createNoiseWords();
            }
            when 'settings' {
                createGlobalSettings();
            }
            
        }
    }
    
    // 💡 Individual section methods
    public static boolean handleMetadata() {
        ServiceSecurity sS = new ServiceSecurity();
        Boolean[] UPs = sS.UserPermissions();
        Map<String, String> mapGlbLocs;
        String Diags = '';
        if (UPs[2] == false) {
            Diags = mapGlbLocs.get('MessageNoRights');
            return false;
        }else{
            
            Diags += 'Obtaining custom object metadata... ';
            System.enqueueJob(new SeedDocsQueueable('handleMetadata', null));
            
            // 1.41.24+ Object details (letter code to API name mappings etc) for ALL objects:
            // We want to cache this as it can be a slow call in orgs with lots of objects defined. We do
            // this here so that the (potentially lengthy) call to process this can run asynchronously and
            // so that the information can be refreshed as and when desired. See also ServiceSchema.getObjectDetails,
            // which uses this cache where available but will attempt a similar (but synchronous) call to obtain it
            // on the fly if need be...
            
            System.debug(Diags);
            return true;              
        }
        
    }
    
    public static boolean handleCacheObjects() {
        
        ServiceSecurity sS = new ServiceSecurity();
        Boolean[] UPs = sS.UserPermissions();
        Map<String, String> mapGlbLocs;
        String Diags = '';
        
        if (UPs[2] == false) {
            Diags = mapGlbLocs.get('MessageNoRights');
            return false;
        }else{
            Diags += 'Obtaining votes... ';
            
            //ServiceSchema.CacheObjectDetails();
            System.enqueueJob(new SeedDocsQueueable('cacheObjects', null));
            System.debug('1');
            return true;
        }
        
    }
    
    public static boolean createTemplates() {
        
        HelpTopicTemplate__c HT;
        List<HelpTopicTemplate__c> HTTs = new List<HelpTopicTemplate__c>();
        String defCmp;
        String defC;
        String defF;
        String Diags = '';
        Map<String, String> mapGlbLocs;
        
        ServiceSecurity sS = new ServiceSecurity();
        Boolean[] UPs = sS.UserPermissions();
        
        if (UPs[2] == false) {
            Diags = mapGlbLocs.get('MessageNoRights');
            return false;
        }else{
            
            Diags += 'About to create templates... ';
            
            
            
            /*
======================================
CALLOUTS
======================================
*/
            
            // CalloutSummaryOnly
            try {
                HT = [SELECT Id, Name, Description__c, PageURL__c, TemplateType__c, DefaultHeight__c 
                      FROM HelpTopicTemplate__c 
                      WHERE PageURL__c = 'CalloutSummaryOnly' OR PageURL__c = 'iahelp__CalloutSummaryOnly' LIMIT 1];
            } catch (exception e) {
                HT = new HelpTopicTemplate__c();                
            }
            
            HT.Name = 'Summary Only';
            HT.Description__c = 'A basic Help Topic callout template featuring Summary text plus a link to full topic details';
            HT.PageURL__c = 'iahelp__CalloutSummaryOnly';
            HT.TemplateType__c = 'Callout';
            HT.DefaultHeight__c = 70;
            
            try {
                // upsert HT;
                Database.upsert(HT, false);
            } catch (exception e) {
                Diags += 'Failed upserting Callout Summary Only... ';
            }
            
            // Note default callout template ID
            defC = HT.Id;
            
            // CalloutHelpResources
            try {
                HT = [SELECT Id, Name, Description__c, PageURL__c, TemplateType__c, DefaultHeight__c 
                      FROM HelpTopicTemplate__c 
                      WHERE PageURL__c = 'CalloutHelpResources' OR PageURL__c = 'iahelp__CalloutHelpResources' LIMIT 1];
            } catch (exception e) {
                HT = new HelpTopicTemplate__c();                
            }
            
            HT.Name = 'Help Resources';
            HT.Description__c = 'Callout Template listing Help Resources in table form';
            HT.PageURL__c = 'iahelp__CalloutHelpResources';
            HT.TemplateType__c = 'Callout';
            HT.DefaultHeight__c = 220;
            HTTs.add(HT);
            
            // CalloutReadingLists
            try {
                HT = [SELECT Id, Name, Description__c, PageURL__c, TemplateType__c, DefaultHeight__c 
                      FROM HelpTopicTemplate__c 
                      WHERE PageURL__c = 'CalloutReadingLists' OR PageURL__c = 'iahelp__CalloutReadingLists' LIMIT 1];
            } catch (exception e) {
                HT = new HelpTopicTemplate__c();                
            }
            
            HT.Name = 'Reading Lists';
            HT.Description__c = 'Callout template with reading lists in gallery or "playbook" form. Topic-specific Image or Video previews are shown, as selected in Topic "Preview Media"';
            HT.PageURL__c = 'iahelp__CalloutReadingLists';
            HT.TemplateType__c = 'Callout';
            HT.DefaultHeight__c = 335;
            HTTs.add(HT);
            
            // CalloutTopicDetails
            try {
                HT = [SELECT Id, Name, Description__c, PageURL__c, TemplateType__c, DefaultHeight__c 
                      FROM HelpTopicTemplate__c 
                      WHERE PageURL__c = 'CalloutTopicDetails' OR PageURL__c = 'iahelp__CalloutTopicDetails' LIMIT 1];
            } catch (exception e) {
                HT = new HelpTopicTemplate__c();                
            }
            
            HT.Name = 'Topic Details';
            HT.Description__c = 'Two column Callout template with Help Topic Summary, Description and Image or Video, (as selected in the Help Topic`s `Preview Media`) at a fixed size';
            HT.PageURL__c = 'iahelp__CalloutTopicDetails';
            HT.TemplateType__c = 'Callout';
            HT.DefaultHeight__c = 220;
            HTTs.add(HT);
            
            // CalloutTopicDetails2 (media at left)
            try {
                HT = [SELECT Id, Name, Description__c, PageURL__c, TemplateType__c, DefaultHeight__c 
                      FROM HelpTopicTemplate__c 
                      WHERE PageURL__c = 'CalloutTopicDetails2' OR PageURL__c = 'iahelp__CalloutTopicDetails2' LIMIT 1];
            } catch (exception e) {
                HT = new HelpTopicTemplate__c();                
            }
            
            HT.Name = 'Topic Details (Media left)';
            HT.Description__c = 'Two column Callout template with Help Topic Summary, Description and Image or Video, (as selected in the Help Topic`s `Preview Media`) to the left  at a fixed size';
            HT.PageURL__c = 'iahelp__CalloutTopicDetails2';
            HT.TemplateType__c = 'Callout';
            HT.DefaultHeight__c = 220;
            HTTs.add(HT);
            
            // CalloutTopicDetailsScaled (scaled media)
            try {
                HT = [SELECT Id, Name, Description__c, PageURL__c, TemplateType__c, DefaultHeight__c 
                      FROM HelpTopicTemplate__c 
                      WHERE PageURL__c = 'CalloutTopicDetailsScaled' OR PageURL__c = 'iahelp__CalloutTopicDetailsScaled' LIMIT 1];
            } catch (exception e) {
                HT = new HelpTopicTemplate__c();                
            }
            
            HT.Name = 'Topic Details (scaled media)';
            HT.Description__c = 'Two column Callout template with Help Topic Summary, Description and Image or Video, (as selected in the Help Topic`s `Preview Media`), sized as per Topic settings';
            HT.PageURL__c = 'iahelp__CalloutTopicDetailsScaled';
            HT.TemplateType__c = 'Callout';
            HT.DefaultHeight__c = 300;
            HTTs.add(HT);
            
            // CalloutTopicText
            try {
                HT = [SELECT Id, Name, Description__c, PageURL__c, TemplateType__c, DefaultHeight__c 
                      FROM HelpTopicTemplate__c 
                      WHERE PageURL__c = 'CalloutTopicText' OR PageURL__c = 'iahelp__CalloutTopicText' LIMIT 1];
            } catch (exception e) {
                HT = new HelpTopicTemplate__c();                
            }
            
            HT.Name = 'Topic Text';
            HT.Description__c = 'Single column Callout template with Help Topic Summary & Description';
            HT.PageURL__c = 'iahelp__CalloutTopicText';
            HT.TemplateType__c = 'Callout';
            HT.DefaultHeight__c = 220;
            HTTs.add(HT);
            
            // CalloutFilterListing
            try {
                HT = [SELECT Id, Name, Description__c, PageURL__c, TemplateType__c, DefaultHeight__c 
                      FROM HelpTopicTemplate__c 
                      WHERE PageURL__c = 'CalloutFilterListing' OR PageURL__c = 'iahelp__CalloutFilterListing' LIMIT 1];
            } catch (exception e) {
                HT = new HelpTopicTemplate__c();                
            }
            
            HT.Name = 'Filterable Relatives';
            HT.Description__c = 'Presents a Topic and its relatives in a rapidly filterable listing, allowing users to select information most of interest';
            HT.PageURL__c = 'iahelp__CalloutFilterListing';
            HT.TemplateType__c = 'Callout';
            HT.DefaultHeight__c = 400;
            HTTs.add(HT);           
            
            // CalloutAllMedia
            try {
                HT = [SELECT Id, Name, Description__c, PageURL__c, TemplateType__c, DefaultHeight__c 
                      FROM HelpTopicTemplate__c 
                      WHERE PageURL__c = 'CalloutAllMedia' OR PageURL__c = 'iahelp__CalloutAllMedia' LIMIT 1];
            } catch (exception e) {
                HT = new HelpTopicTemplate__c();                
            }
            
            HT.Name = 'All Media (media left)';
            HT.Description__c = 'Callout template with Help Topic Summary, Description and both Image and Video to the left of Topic text';
            HT.PageURL__c = 'iahelp__CalloutAllMedia';
            HT.TemplateType__c = 'Callout';
            HT.DefaultHeight__c = 400;
            
            HTTs.add(HT);
            
            // CalloutFullWidthMedia
            try {
                HT = [SELECT Id, Name, Description__c, PageURL__c, TemplateType__c, DefaultHeight__c 
                      FROM HelpTopicTemplate__c 
                      WHERE PageURL__c = 'CalloutFullWidthMedia' OR PageURL__c = 'iahelp__CalloutFullWidthMedia' LIMIT 1];
            } catch (exception e) {
                HT = new HelpTopicTemplate__c();                
            }
            
            HT.Name = 'Full Size Media';
            HT.Description__c = 'Callout template showing Topic callout media (Image or Video) sized to fill available space';
            HT.PageURL__c = 'iahelp__CalloutFullWidthMedia';
            HT.TemplateType__c = 'Callout';
            HT.DefaultHeight__c = 400;
            HTTs.add(HT);
            
            // CalloutRelatedHelp
            try {
                HT = [SELECT Id, Name, Description__c, PageURL__c, TemplateType__c, DefaultHeight__c 
                      FROM HelpTopicTemplate__c 
                      WHERE PageURL__c = 'CalloutRelatedHelp' OR PageURL__c = 'iahelp__CalloutRelatedHelp' LIMIT 1];
            } catch (exception e) {
                HT = new HelpTopicTemplate__c();                
            }
            
            HT.Name = 'Related Topic Details';
            HT.Description__c = 'Callout template showing mini-callouts for each Related Help Topic';
            HT.PageURL__c = 'iahelp__CalloutRelatedHelp';
            HT.TemplateType__c = 'Callout';
            HT.DefaultHeight__c = 400;
            HTTs.add(HT);
            
            // CalloutPopover ("Einstein" flavour)
            try {
                HT = [SELECT Id, Name, Description__c, PageURL__c, TemplateType__c, DefaultHeight__c 
                      FROM HelpTopicTemplate__c 
                      WHERE PageURL__c = 'CalloutPopover' OR PageURL__c = 'iahelp__CalloutPopover' LIMIT 1];
            } catch (exception e) {
                HT = new HelpTopicTemplate__c();                
            }
            
            HT.Name = 'Lightning Popover';
            HT.Description__c = 'A Lightning-styled callout featuring Topic Name in the header with Topic Image at a fixed height, plus Topic Summary and Description in the body';
            HT.PageURL__c = 'iahelp__CalloutPopover';
            HT.TemplateType__c = 'Callout';
            HT.DefaultHeight__c = 300;
            HTTs.add(HT);
            
            /*
======================================
FULL TOPIC TEMPLATES (CLASSIC VF)
======================================
*/
            
            // TemplateHorMediaDesc
            try {
                HT = [SELECT Id, Name, Description__c, PageURL__c, TemplateType__c, DefaultHeight__c 
                      FROM HelpTopicTemplate__c 
                      WHERE PageURL__c = 'Template2ColMediaText' OR PageURL__c = 'iahelp__Template2ColMediaText' LIMIT 1];
            } catch (exception e) {
                HT = new HelpTopicTemplate__c();                
            }
            
            HT.Name = 'Image / Video left of Text';
            HT.Description__c = 'Shows Help Topic fields (if not blank) in 2 columns: \n1) Summary \n2) Image and/or Video plus Detail';
            HT.PageURL__c = 'iahelp__Template2ColMediaText';
            HT.TemplateType__c = 'Full Topic';
            HT.DefaultHeight__c = 400;
            HTTs.add(HT);
            
            // TemplateHorDescMedia
            try {
                HT = [SELECT Id, Name, Description__c, PageURL__c, TemplateType__c, DefaultHeight__c 
                      FROM HelpTopicTemplate__c 
                      WHERE PageURL__c = 'Template2ColTextMedia' OR PageURL__c = 'iahelp__Template2ColTextMedia' LIMIT 1];
            } catch (exception e) {
                HT = new HelpTopicTemplate__c();                
            }
            
            HT.Name = 'Image / Video right of Text';
            HT.Description__c = 'Shows Help Topic fields (if not blank) in 2 columns: \n1) Summary \n2) Detail plus Image and/or Video';
            HT.PageURL__c = 'iahelp__Template2ColTextMedia';
            HT.TemplateType__c = 'Full Topic';
            HT.DefaultHeight__c = 400;
            HTTs.add(HT);
            
            // TemplateVertDescMedia
            try {
                HT = [SELECT Id, Name, Description__c, PageURL__c, TemplateType__c, DefaultHeight__c 
                      FROM HelpTopicTemplate__c 
                      WHERE PageURL__c = 'Template2RowTextMedia' OR PageURL__c = 'iahelp__Template2RowTextMedia' LIMIT 1];
            } catch (exception e) {
                HT = new HelpTopicTemplate__c();                
            }
            
            HT.Name = 'Image / Video below Text';
            HT.Description__c = 'Shows Help Topic fields (if not blank): \n1) Summary \n2) Detail \n3) Image and/or Video';
            HT.PageURL__c = 'iahelp__Template2RowTextMedia';
            HT.TemplateType__c = 'Full Topic';
            HT.DefaultHeight__c = 400;
            
            // We need template ID here, so do an upsert...
            try {
                //upsert HT;
                Database.upsert(HT, false);
            } catch (exception e) {
                Diags += 'Failed upserting Template Image Video below Text... ';
            }
            
            
            // Note default full template ID
            defF = HT.Id;
            
            // TemplateVertImgDescVid
            try {
                HT = [SELECT Id, Name, Description__c, PageURL__c, TemplateType__c, DefaultHeight__c 
                      FROM HelpTopicTemplate__c 
                      WHERE PageURL__c = 'Template3RowImageTextVideo' OR PageURL__c = 'iahelp__Template3RowImageTextVideo' LIMIT 1];
            } catch (exception e) {
                HT = new HelpTopicTemplate__c();                
            }
            
            HT.Name = 'Image Banner above Text and Video';
            HT.Description__c = 'Shows Help Topic fields (if not blank): \n1) Summary \n2) Image \n3) Detail \n4) Video';
            HT.PageURL__c = 'iahelp__Template3RowImageTextVideo';
            HT.TemplateType__c = 'Full Topic';
            HT.DefaultHeight__c = 400;
            HTTs.add(HT);
            
            // TemplateVertMediaDesc
            try {
                HT = [SELECT Id, Name, Description__c, PageURL__c, TemplateType__c, DefaultHeight__c 
                      FROM HelpTopicTemplate__c 
                      WHERE PageURL__c = 'Template2RowMediaText' OR PageURL__c = 'iahelp__Template2RowMediaText' LIMIT 1];
            } catch (exception e) {
                HT = new HelpTopicTemplate__c();                
            }
            
            HT.Name = 'Image / Video above Text';
            HT.Description__c = 'Shows Help Topic fields (if not blank): \n1) Summary \n2) Image and/or Video \n3) Detail';
            HT.PageURL__c = 'iahelp__Template2RowMediaText';
            HT.TemplateType__c = 'Full Topic';
            HT.DefaultHeight__c = 400;
            HTTs.add(HT);           
            
            // Template2ColLUXTreeDetails
            try {
                HT = [SELECT Id, Name, Description__c, PageURL__c, TemplateType__c, DefaultHeight__c 
                      FROM HelpTopicTemplate__c 
                      WHERE PageURL__c = 'Template2ColLUXTreeDetails' OR PageURL__c = 'iahelp__Template2ColLUXTreeDetails' LIMIT 1];
            } catch (exception e) {
                HT = new HelpTopicTemplate__c();                
            }
            
            HT.Name = 'Tree Viewer and Topic Details';
            HT.Description__c = 'Shows selected Topic as Root Node of a Tree View plus selected Topic Details';
            HT.PageURL__c = 'iahelp__Template2ColLUXTreeDetails';
            HT.TemplateType__c = 'Full Topic';
            HT.DefaultHeight__c = 600;
            HTTs.add(HT);
            
            /*
======================================
FULL TOPIC TEMPLATES (CUSTOM LUX)
======================================
*/
            
            // Summary Bubble - page guide style popover (custom layout as opposed to VF page)
            try {
                HT = [SELECT Id, Name, Description__c, PageURL__c, TemplateType__c, DefaultHeight__c 
                      FROM HelpTopicTemplate__c 
                      WHERE PageURL__c = 'iahelp__Summary__c^Field^slds-text-heading_medium slds-text-align_center slds-box slds-theme_shade slds-theme_inverse|iahelp__Desription__c^Field^' LIMIT 1];
            } catch (exception e) {
                HT = new HelpTopicTemplate__c();                
            }
            
            HT.Name = 'Summary Bubble';
            HT.Description__c = 'A simple template presenting Summary text only in a popup-like style suited to use in page guides';
            HT.PageURL__c = 'iahelp__Summary__c^Field^slds-text-heading_medium slds-text-align_center slds-box slds-theme_shade slds-theme_inverse|iahelp__Desription__c^Field^';
            HT.TemplateType__c = 'Full Topic';
            HT.DefaultHeight__c = 600;
            HTTs.add(HT);
            
            
            // Full width image - as used by entries in the carousel RL on welcome tab of the help app
            try {
                HT = [SELECT Id, Name, Description__c, PageURL__c, TemplateType__c, DefaultHeight__c 
                      FROM HelpTopicTemplate__c 
                      WHERE PageURL__c = 'iahelp__ImageURL__c^Image^IHFullWidth|iahelp__Description__c^Field^' LIMIT 1];
            } catch (exception e) {
                HT = new HelpTopicTemplate__c();                
            }
            
            HT.Name = 'Full Width Image';
            HT.Description__c = 'Topic image classed with full width marker above description';
            HT.PageURL__c = 'iahelp__ImageURL__c^Image^IHFullWidth|iahelp__Description__c^Field^';
            HT.TemplateType__c = 'Full Topic';
            HT.DefaultHeight__c = 600;
            HTTs.add(HT);
            
            
            // SPECIAL: Hide from Reading Lists
            try {
                HT = [SELECT Id, Name, Description__c, PageURL__c, TemplateType__c, DefaultHeight__c 
                      FROM HelpTopicTemplate__c 
                      WHERE PageURL__c = '[HideRLE]' LIMIT 1];
            } catch (exception e) {
                HT = new HelpTopicTemplate__c();                
            }
            
            HT.Name = '[Hide from Reading List Viewers]';
            HT.Description__c = 'Topic presents as normal in Topic viewers but will be hidden as a reading list entry';
            HT.PageURL__c = '[HideRLE]';
            HT.TemplateType__c = 'Full Topic';
            HT.DefaultHeight__c = 300;
            HTTs.add(HT);
            
            /*
======================================
LIGHTNING VIEWER (SUB COMPONENT) TEMPLATES
======================================
*/
            
            // Child help
            defCmp = 'iahelp:IHList~SuppressHeader¬true|SuppressFooter¬true|MaxListingTools¬0|Height¬-1|CardConfig¬ChildHelp|CalloutOption¬Topic Selected Event Only';         
            try {
                HT = [SELECT Id, Name, Description__c, PageURL__c, TemplateType__c, DefaultHeight__c 
                      FROM HelpTopicTemplate__c 
                      WHERE PageURL__c = :defCmp LIMIT 1];
            } catch (exception e) {
                HT = new HelpTopicTemplate__c();                
            }
            HT.Name = 'Child Help List';
            HT.Description__c = 'Displays listing of the Topic\'s children';
            HT.PageURL__c = defCmp;
            HT.TemplateType__c = 'Lightning Viewer';
            HT.DefaultHeight__c = 300;
            HTTs.add(HT);
            
            // Only Related Help Added in version 1.56
            defCmp = 'iahelp:IHList~SuppressHeader¬true|SuppressFooter¬true|MaxListingTools¬0|Height¬-1|CardConfig¬Only Related Help|CalloutOption¬Topic Selected Event Only';         
            try {
                HT = [SELECT Id, Name, Description__c, PageURL__c, TemplateType__c, DefaultHeight__c 
                      FROM HelpTopicTemplate__c 
                      WHERE PageURL__c = :defCmp LIMIT 1];
            } catch (exception e) {
                HT = new HelpTopicTemplate__c();                
            }
            HT.Name = 'Only Related Help List';
            HT.Description__c = 'Displays Listing of only Related Help Topics';
            HT.PageURL__c = defCmp;
            HT.TemplateType__c = 'Lightning Viewer';
            HT.DefaultHeight__c = 300;
            HTTs.add(HT);
            
            // Related help
            defCmp = 'iahelp:IHList~SuppressHeader¬false|SuppressFooter¬true|MaxListingTools¬0|Height¬-1|CardConfig¬RelatedHelp|CalloutOption¬Topic Selected Event Only';          
            try {
                HT = [SELECT Id, Name, Description__c, PageURL__c, TemplateType__c, DefaultHeight__c 
                      FROM HelpTopicTemplate__c 
                      WHERE PageURL__c = :defCmp LIMIT 1];
            } catch (exception e) {
                HT = new HelpTopicTemplate__c();                
            }
            HT.Name = 'Related Help List';
            HT.Description__c = 'Displays the Topic\'s Related Help listing';
            HT.PageURL__c = defCmp;
            HT.TemplateType__c = 'Lightning Viewer';
            HT.DefaultHeight__c = 300;
            HTTs.add(HT);
            
            // Related help (Tiles)
            defCmp = 'iahelp:IHList~SuppressHeader¬true|SuppressFooter¬true|MaxListingTools¬0|Height¬-1|CardConfig¬RelatedHelp|CalloutOption¬Topic Selected Event Only|ListingStyle¬Tile|ListingTileSize¬Smallest';            
            try {
                HT = [SELECT Id, Name, Description__c, PageURL__c, TemplateType__c, DefaultHeight__c 
                      FROM HelpTopicTemplate__c 
                      WHERE PageURL__c = :defCmp LIMIT 1];
            } catch (exception e) {
                HT = new HelpTopicTemplate__c();                
            }
            HT.Name = 'Related Help Tiles';
            HT.Description__c = 'Displays the Topic\'s Related Help listing in tile format';
            HT.PageURL__c = defCmp;
            HT.TemplateType__c = 'Lightning Viewer';
            HT.DefaultHeight__c = 300;
            HTTs.add(HT);
            
            // Related reading lists
            defCmp = 'iahelp:IHList~SuppressHeader¬false|SuppressFooter¬true|MaxListingTools¬0|Height¬-1|CardConfig¬UnfeaturedReadingLists|ComponentId¬RLsLuxTemplate|recordId¬{!HelpRecordId}';          
            try {
                HT = [SELECT Id, Name, Description__c, PageURL__c, TemplateType__c, DefaultHeight__c 
                      FROM HelpTopicTemplate__c 
                      WHERE PageURL__c = :defCmp LIMIT 1];
            } catch (exception e) {
                HT = new HelpTopicTemplate__c();                
            }
            HT.Name = 'Related Reading Lists';
            HT.Description__c = 'Displays the Topic\'s related Reading Lists';
            HT.PageURL__c = defCmp;
            HT.TemplateType__c = 'Lightning Viewer';
            HT.DefaultHeight__c = 300;
            HTTs.add(HT);
            
            // Related resources
            defCmp = 'iahelp:IHList~SuppressHeader¬false|SuppressFooter¬true|MaxListingTools¬0|Height¬-1|CardConfig¬Resources|ComponentId¬ResLuxTemplate|recordId¬{!HelpRecordId}';         
            try {
                HT = [SELECT Id, Name, Description__c, PageURL__c, TemplateType__c, DefaultHeight__c 
                      FROM HelpTopicTemplate__c 
                      WHERE PageURL__c = :defCmp LIMIT 1];
            } catch (exception e) {
                HT = new HelpTopicTemplate__c();                
            }
            HT.Name = 'Related Resources';
            HT.Description__c = 'Displays the Topic\'s related Resources';
            HT.PageURL__c = defCmp;
            HT.TemplateType__c = 'Lightning Viewer';
            HT.DefaultHeight__c = 300;
            HTTs.add(HT);
            
            
            
            // Related resource tiles
            defCmp = 'iahelp:IHList~SuppressHeader¬true|SuppressFooter¬true|MaxListingTools¬0|Height¬-1|CardConfig¬Resources|CalloutOption¬Topic Selected Event Only|ListingStyle¬Tile|ListingTileSize¬Small|recordId¬{!HelpRecordId}';         
            try {
                HT = [SELECT Id, Name, Description__c, PageURL__c, TemplateType__c, DefaultHeight__c 
                      FROM HelpTopicTemplate__c 
                      WHERE PageURL__c = :defCmp LIMIT 1];
            } catch (exception e) {
                HT = new HelpTopicTemplate__c();                
            }
            HT.Name = 'Related Resource Tiles';
            HT.Description__c = 'Displays the Topic\'s Related Resource listing in tile format';
            HT.PageURL__c = defCmp;
            HT.TemplateType__c = 'Lightning Viewer';
            HT.DefaultHeight__c = 300;
            HTTs.add(HT);
            
            
            
            // Flow launcher
            defCmp = 'iahelp:IHFlowLauncher~theFlowName¬[CONTEXT]|recordId¬{!Parent.recordIdOrOwn}';         
            try {
                HT = [SELECT Id, Name, Description__c, PageURL__c, TemplateType__c, DefaultHeight__c 
                      FROM HelpTopicTemplate__c 
                      WHERE PageURL__c = :defCmp LIMIT 1];
            } catch (exception e) {
                HT = new HelpTopicTemplate__c();                
            }
            HT.Name = 'Flow Launcher';
            HT.Description__c = 'Presents a list of Flows available in the current Help Context: the user can select one to launch.';
            HT.PageURL__c = defCmp;
            HT.TemplateType__c = 'Lightning Viewer';
            HT.DefaultHeight__c = 300;
            HTTs.add(HT);
            
            // Related tabs of Topic Details
            defCmp = 'iahelp:IHTabs~HelpRecordId¬{!HelpRecordId}|NodeIconStyle¬None|TemplateActionCode¬TabsOf_IHDetail';         
            try {
                HT = [SELECT Id, Name, Description__c, PageURL__c, TemplateType__c, DefaultHeight__c 
                      FROM HelpTopicTemplate__c 
                      WHERE PageURL__c = :defCmp LIMIT 1];
            } catch (exception e) {
                HT = new HelpTopicTemplate__c();                
            }
            HT.Name = 'Child Help Tabs: Topic Viewers';
            HT.Description__c = 'Displays each of the Topic\'s children as a tab containing a Topic Viewer.';
            HT.PageURL__c = defCmp;
            HT.TemplateType__c = 'Lightning Viewer';
            HT.DefaultHeight__c = 300;
            HTTs.add(HT);
            
            // Related tabs of Reading List Viewers
            defCmp = 'iahelp:IHTabs~HelpRecordId¬{!HelpRecordId}|TemplateActionCode¬TabsOf_IHRLViewer|ListCardConfig¬Reading Lists';         
            try {
                HT = [SELECT Id, Name, Description__c, PageURL__c, TemplateType__c, DefaultHeight__c 
                      FROM HelpTopicTemplate__c 
                      WHERE PageURL__c = :defCmp LIMIT 1];
            } catch (exception e) {
                HT = new HelpTopicTemplate__c();                
            }
            HT.Name = 'Child Help Tabs: Reading Lists';
            HT.Description__c = 'Displays each of the Topic\'s related Reading Lists on a tab containing a Reading List Viewer.';
            HT.PageURL__c = defCmp;
            HT.TemplateType__c = 'Lightning Viewer';
            HT.DefaultHeight__c = 300;
            HTTs.add(HT);
            
            
            
            // Open Help Index
            defCmp = 'iahelp:IHPosDetect~PositioningRole¬Help Button|HelpRecordId¬{!Parent.recordIdOrOwn}|PositioningGroup¬IHLUXApp_UtilBar_URLParams';         
            try {
                HT = [SELECT Id, Name, Description__c, PageURL__c, TemplateType__c, DefaultHeight__c 
                      FROM HelpTopicTemplate__c 
                      WHERE PageURL__c = :defCmp LIMIT 1];
            } catch (exception e) {
                HT = new HelpTopicTemplate__c();                
            }
            HT.Name = 'Open Help Index Button';
            HT.Description__c = 'Shows a Position Detector in the Help Button role that will open the Help for Improved Help App Help Index';
            HT.PageURL__c = defCmp;
            HT.TemplateType__c = 'Lightning Viewer';
            HT.DefaultHeight__c = 300;
            HTTs.add(HT);
            
            
            //upsert(HTTs);
            Database.upsert(HTTs, false);
            
            Diags +='Templates created... ';
            
        }
        
        return true;
    }
    
    public static boolean createVoteSets() {
        
        String Diags = '';
        Map<String, String> mapGlbLocs;
        HelpVoteSet__c HVS;
        HelpVoteOption__c HVO;
        ServiceSecurity sS = new ServiceSecurity();
        Boolean[] UPs = sS.UserPermissions();
        
        if (UPs[2] == false) {
            Diags = mapGlbLocs.get('MessageNoRights');
            Diags += 'Failed creating Vote Sets / Options records: ';
            return false;
        } else{
            Diags += 'Continuing to Vote Sets and Options... ';
            // Improved Help Smileys
            try {
                HVS = [SELECT Id 
                       FROM HelpVoteSet__c 
                       WHERE Name = 'Improved Help Smileys' AND ImageClass__c = '/resource/iahelp__IHResources/img/IconFaceHappyBlue.png' AND QuestionText__c = 'Rate this...'];
            } catch (exception e) {
                HVS = new HelpVoteSet__c();             
            }
            
            HVS.Name = 'Improved Help Smileys';
            HVS.ImageClass__c = '/resource/iahelp__IHResources/img/IconFaceHappyBlue.png';
            HVS.QuestionText__c = 'Rate this...';
            
            try {
                upsert HVS;
                
                try {
                    HVO = [SELECT Id 
                           FROM HelpVoteOption__c 
                           WHERE HelpVoteSet__c = :HVS.Id AND Name = 'Very useful'];
                } catch (exception e) {
                    HVO = new HelpVoteOption__c();              
                    HVO.HelpVoteSet__c = HVS.Id;
                }
                
                HVO.DisplayOrder__c = 1;
                HVO.Name = 'Very useful';
                HVO.Category__c = 'Positive';
                HVO.ImageClass__c = '/resource/iahelp__IHResources/img/IconFaceHappy.png';
                HVO.OptionLabel__c = '';
                
                try {
                    upsert HVO;
                } catch (exception d) {
                    Diags += 'Failed upserting Help Vote Option for Set ' + HVS.Name + '... ';
                }
                
                
                try {
                    HVO = [SELECT Id 
                           FROM HelpVoteOption__c 
                           WHERE HelpVoteSet__c = :HVS.Id AND Name = 'OK'];
                } catch (exception e) {
                    HVO = new HelpVoteOption__c();              
                    HVO.HelpVoteSet__c = HVS.Id;
                }
                
                HVO.DisplayOrder__c = 2;
                HVO.Name = 'OK';
                HVO.Category__c = 'Neutral';                
                HVO.ImageClass__c = '/resource/iahelp__IHResources/img/IconFaceNeutral.png';
                HVO.OptionLabel__c = '';
                
                try {
                    upsert HVO;
                } catch (exception d) {
                    Diags += 'Failed upserting Help Vote Option for Set ' + HVS.Name + '... ';
                }
                
                
                try {
                    HVO = [SELECT Id 
                           FROM HelpVoteOption__c 
                           WHERE HelpVoteSet__c = :HVS.Id AND Name = 'Not helpful'];
                } catch (exception e) {
                    HVO = new HelpVoteOption__c();              
                    HVO.HelpVoteSet__c = HVS.Id;
                }
                
                HVO.DisplayOrder__c = 3;
                HVO.Name = 'Not helpful';
                HVO.Category__c = 'Negative';                
                HVO.ImageClass__c = '/resource/iahelp__IHResources/img/IconFaceSad.png';
                HVO.OptionLabel__c = '';
                
                try {
                    upsert HVO;
                } catch (exception d) {
                    Diags += 'Failed upserting Help Vote Option for Set ' + HVS.Name + '... ';
                }
                
            } catch (exception e) {
                Diags += 'Failed upserting Help Vote Set: ' + e.getMessage() + '... ';
            }
            
            
            Diags +='Vote Sets created... ';
            
            return true;
        } 
        
    }
    
    public static boolean createSemanticTags() {
        
        String Diags = '';
        String defST;
        SemanticTag__c STag;
        List<SemanticTag__c> STags = new List<SemanticTag__c>();
        Map<String, String> mapGlbLocs;
        
        ServiceSecurity sS = new ServiceSecurity();
        Boolean[] UPs = sS.UserPermissions();
        if (UPs[2] == false) {
            Diags = mapGlbLocs.get('MessageNoRights');
            Diags +=  'Failed creating Semantic Tags: ';
            return false;
        } else{
            Diags += 'Continuing to Semantic Tags... ';
            // Relative
            try {
                STag = [SELECT Id 
                        FROM SemanticTag__c 
                        WHERE Name = 'Relative'];
            } catch (exception e) {
                STag = new SemanticTag__c();                
            }
            
            STag.Name = 'Relative';
            STag.Tag__c = 'Is related to';
            STag.CollectiveTag__c = 'Relatives';
            STag.Obverse__c = 'Is related to';
            STag.ShortObverse__c = 'Relative';
            STag.CollectiveObverse__c = 'Relatives';
            
            try {
                upsert STag;
                
                // Note this as the default semantic tag:
                defST = STag.Id;
                
            } catch (exception e) {
                Diags += 'Failed upserting Semantic Tag "Relative"... ';
            }           
            
            // Parent
            try {
                STag = [SELECT Id 
                        FROM SemanticTag__c 
                        WHERE Name = 'Parent'];
            } catch (exception e) {
                STag = new SemanticTag__c();                
            }
            
            STag.Name = 'Parent';
            STag.Tag__c = 'Is a parent of';
            STag.CollectiveTag__c = 'Parents';
            STag.Obverse__c = 'Is a child of';
            STag.ShortObverse__c = 'Child';
            STag.CollectiveObverse__c = 'Children';
            
            STags.add(STag);
            
            
            // Member
            try {
                STag = [SELECT Id 
                        FROM SemanticTag__c 
                        WHERE Name = 'Member'];
            } catch (exception e) {
                STag = new SemanticTag__c();                
            }
            
            STag.Name = 'Member';
            STag.Tag__c = 'Has member';
            STag.CollectiveTag__c = 'Members';
            STag.Obverse__c = 'Is a member of';
            STag.ShortObverse__c = 'Is a';
            STag.CollectiveObverse__c = 'Are';
            
            STags.add(STag);
            
            
            // Translation
            try {
                STag = [SELECT Id 
                        FROM SemanticTag__c 
                        WHERE Name = 'Translation'];
            } catch (exception e) {
                STag = new SemanticTag__c();                
            }
            
            STag.Name = 'Translation';
            STag.Tag__c = 'Translates to';
            STag.CollectiveTag__c = 'Translations';
            STag.Obverse__c = 'Is a translation of';
            STag.ShortObverse__c = 'Translates';
            STag.CollectiveObverse__c = 'Translations of';
            
            STags.add(STag);
            
            try {
                upsert STags;
            } catch (exception e) {
                Diags += 'Failed upserting Semantic Tags: ' + e.getMessage() + '... ';
            }
            
            Diags +='Semantic Tags created... ';
            return true;
        } 
    }
    
    public static boolean createNoiseWords() {
        
        String Diags = '';
        Map<String, String> mapGlbLocs;
        ServiceSecurity sS = new ServiceSecurity();
        Boolean[] UPs = sS.UserPermissions();
        
        if (UPs[2] == false) {
            Diags = mapGlbLocs.get('MessageNoRights');
            Diags +=  'Failed creating NoiseWords: ';
            return false;
        }else{
            Diags += 'Continuing to Noise Words... ';
            
            string NW = 'a,about,after,ago,all,almost,along,already,also,although,always,am,amid,amoung,an,and,another,any,are,as,at,away,b,back,be,because,been,before,being,between,both,but,by,c,came,can,can’t,come,could,couldn\'t,d,did,didn\'t,do,does,down,e,each,eight,eighteen,eighty,eleven,else,every,everything,f,fifteen,fifty,five,for,forty,four,fourteen,from,g,get,go,going,got,h,had,has,have,he,her,here,him,himself,his,how,however,hundred,I,if,in,inside,into,is,it,its,it\'s,itself,j,just,k,l,like,m,make,many,me,meanwhile,might,mightn\'t,million,mine,more,most,much,must,mustn\'t,my,n,never,nine,ninety,no,not,now,o,of,ok,on,one,only,or,other,our,ours,ourselves,out,outside,over,p,perhaps,r,said,same,say,see,seven,seventeen,seventy,shall,shant,she,should,shouldn\'t,since,six,sixteen,sixty,so,some,still,such,take,ten,than,that,that\'s,the,their,theirs,them,then,there,there\'s,these,they,thing,thirteen,thirty,this,those,thousand,three,through,to,too,twelve,twenty,two,u,under,unless,until,up,us,use,v,very,w,want,was,way,we,well,were,what,whatever,whatsoever,when,where,whereas,whereby,wherever,which,while,whilst,who,whoever,whose,why,will,with,within,without,won\'t,would,wouldn\'t,x,y,yet,you,your,you\'re,yours,yourself,yourselves,z';
            string[] NWs = NW.split(',');
            string NWSOQL = 'SELECT id FROM NoiseWords__c WHERE Name IN(';
            NoiseWords__c[] ExistingNWords;
            NoiseWords__c[] NWords = new NoiseWords__c[]{};
                NoiseWords__c NWord;
            
            for (string W : NWs) {
                
                NWSOQL += '\'' + string.escapeSingleQuotes(W) + '\',';
                
                NWord = new NoiseWords__c();
                NWord.name = W;
                NWords.add(NWord);
            }
            
            NWSOQL = NWSOQL.substring(0, NWSOQL.length() - 1);
            NWSOQL += ')';
            
            ExistingNWords = database.query(NWSOQL);
            delete ExistingNWords;
            
            upsert NWords;
            
            return true;
        }
        
    }
    
    public static boolean createGlobalSettings() {
        
        ServiceSecurity sS = new ServiceSecurity();
        Boolean[] UPs = sS.UserPermissions();
        String Diags = '';
        Map<String, String> mapGlbLocs =  ServiceLocalisation.getDialogueLocalisations('Globals', false);
        
        if (UPs[2] == false) {
            Diags = mapGlbLocs.get('MessageNoRights');
            Diags +=  'Failed creating Global Settings: ';
            return false;
        } else{
            
            Diags += 'Continuing to settings... ';
            
            // Create an instance of global settings:
            // NB: this has to wait until we've inserted the templates correctly, as these feature here!        
            
            IASetIHOrg__c EnabledElements = IASetIHOrg__c.getInstance('EnabledElements'); 
            
            if (EnabledElements == null) {
                EnabledElements = new IASetIHOrg__c(Name = 'EnabledElements');      
                Diags += 'No settings were found: new instance created... ';
            } else {
                Diags += 'Existing settings object found... ';
            }
            
            // v1.21 - In all cases, retain any existing settings the Org may have created
            
            // Set default vote set 'Improved Help Smileys'
            if(EnabledElements.DefaultVoteSet__c == null) {
                try {
                    HelpVoteSet__c HVS = [SELECT Id FROM HelpVoteSet__c 
                                          WHERE Name = 'Improved Help Smileys' LIMIT 1];
                    EnabledElements.DefaultVoteSet__c = HVS.Id;
                    Diags += 'Default vote set in settings was null, so now set to: ' + EnabledElements.DefaultVoteSet__c + '... ';
                } catch(Exception e) {
                    system.debug('Error'+e);
                    Diags += 'Vote Set missing. Run createVoteSets() first. ';
                }
                
            } else {
                Diags += 'Default vote set in settings was NOT null: ' + EnabledElements.DefaultVoteSet__c + '... ';
            }
            
            // Set default help topic full and callout templates
            if(EnabledElements.DefaultHelpCalloutTemplate__c == null) {
                try {
                    HelpTopicTemplate__c  HT = [SELECT Id FROM HelpTopicTemplate__c 
                                                WHERE PageURL__c = 'iahelp__CalloutSummaryOnly' LIMIT 1];
                    EnabledElements.DefaultHelpCalloutTemplate__c = HT.Id;   
                    Diags += 'Default callout in settings was null, so now set to: ' + EnabledElements.DefaultHelpCalloutTemplate__c + '... ';
                } catch(Exception e) {
                    system.debug('Error'+e);
                    Diags += 'Default callout in settings was NOT null: ' + EnabledElements.DefaultHelpCalloutTemplate__c + '... ';
                }
            } else{
                Diags += 'Default callout in settings was NOT null: ' + EnabledElements.DefaultHelpCalloutTemplate__c + '... ';
            }
            
            if(EnabledElements.DefaultHelpTopicTemplate__c == null) {
                try {
                    HelpTopicTemplate__c  HT = [SELECT Id FROM HelpTopicTemplate__c 
                                                WHERE PageURL__c = 'iahelp__Template2RowTextMedia' LIMIT 1];
                    system.debug('defF'+HT.Id);
                    EnabledElements.DefaultHelpTopicTemplate__c = HT.Id; 
                    Diags += 'Default template in settings was null, so now set to: ' + EnabledElements.DefaultHelpTopicTemplate__c + '...';
                } catch(Exception e) {
                    Diags += 'Full template missing. Run createTemplates() first. ';
                    system.debug('Error'+e);
                }
                
            } else {
                Diags += 'Default template in settings was NOT null: ' + EnabledElements.DefaultHelpTopicTemplate__c + '... ';  
            }           
            
            // We also need to set up the customer CSS reference...
            if(EnabledElements.BrandCSS__c == null) {EnabledElements.BrandCSS__c = URL.getOrgDomainURL().toExternalForm() + '/resource/iahelp__IHResources/css/help_customer.css';}            
            
            // ... And other mandatory elements...
            //if(EnabledElements.BrandIHTooltip__c == null) {EnabledElements.BrandIHTooltip__c = 'Click for Help...';}
            //if(EnabledElements.UserAdviceCommentLogged__c == null) {EnabledElements.UserAdviceCommentLogged__c = 'Your comment has been logged';}           
            
            // We must also populate the Capek (^) separated list of the 3 character Salesforce codes 
            // representing key Improved Help objects: as we may add to this list, we ALWAYS reset this
            EnabledElements.SFObjectIds__c = ControllerSettings.getSFObjectIds();           
            
            // Elements added in 1.14
            //if(EnabledElements.AllocatedSeats__c == null) {EnabledElements.AllocatedSeats__c = 0;}
            //if(EnabledElements.UserAdviceCommentLogged__c == null || EnabledElements.UserAdviceCommentLogged__c == '') {EnabledElements.UserAdviceCommentLogged__c = 'Your comment has been logged';}
            
            // Elements added in 1.15
            if(EnabledElements.CalloutClosureBehaviour__c == null || EnabledElements.CalloutClosureBehaviour__c == '') {EnabledElements.CalloutClosureBehaviour__c = '1';}
            if(EnabledElements.EnableImprovedButtonHelp__c == null) {EnabledElements.EnableImprovedButtonHelp__c = true;}
            if(EnabledElements.EnableImprovedLinkHelp__c == null) {EnabledElements.EnableImprovedLinkHelp__c = true;}
            //if(EnabledElements.DefaultGuideTemplate__c == null) {EnabledElements.DefaultGuideTemplate__c = defF;}
            if(EnabledElements.DefaultVisibility__c == null) {EnabledElements.DefaultVisibility__c = '';}
            
            // Elements added in 1.16
            if(EnabledElements.RLShowNextPrev__c == null) {EnabledElements.RLShowNextPrev__c = true;}
            if(EnabledElements.AllowLayoutComments__c == null) {EnabledElements.AllowLayoutComments__c = true;}
            if(EnabledElements.ConsoleResourceLinkTarget__c == null || EnabledElements.ConsoleResourceLinkTarget__c == '') {EnabledElements.ConsoleResourceLinkTarget__c = '1';}
            
            // Elements added in 1.17
            if(EnabledElements.ShowReferringTopics__c == null) {EnabledElements.ShowReferringTopics__c = true;}                     
            if(EnabledElements.ShowGuidesLinks__c == null || EnabledElements.ShowGuidesLinks__c == '') {EnabledElements.ShowGuidesLinks__c = '0';}
            
            if(EnabledElements.CustomStyles__c == null || EnabledElements.CustomStyles__c == '') {              
                string styles = 'HouseLEXBrand, DemoHelpChanged, LUXRed, LUXAmber, LUXGreen, LUXLightBlue, LUXDarkBlue, LUXLightGrey, LUXDarkGrey';
                styles += ', Flowchart, FlowchartStart, FlowchartStop, FlowchartDecision, FlowchartProcess, FlowchartSubProcess';               
                EnabledElements.CustomStyles__c = styles;
            }                        
            
            if(EnabledElements.SFPod__c == null || EnabledElements.SFPod__c == '') {
                
                // We should be requesting this from a VF page, so should be able to get
                // the pod name from the current page address
                string P;
                
                try {
                    P = url.getCurrentRequestUrl().getHost();   
                    
                    if (p.lastIndexOf('iahelp.') == -1) {
                        P = P.substring(0, P.indexOf('.'));
                    } else {
                        P = P.substring(p.lastIndexOf('iahelp.') + 7);
                        P = P.replace('.visual.force.com', '');                     
                    }                               
                    
                    if (P.length() > 4) {
                        P = 'Err!';
                    }
                    
                } catch (exception e) {
                    P = 'Err!';
                }
                
                Diags += 'Request URL is: ' + url.getCurrentRequestUrl().toExternalForm() + '... ';
                Diags += 'Derived Salesforce pod: ' + P + '... ';
                
                EnabledElements.SFPod__c = P;
            }
            
            // Elements added in 1.20
            if(EnabledElements.EnableImprovedSectionHelp__c == null) {EnabledElements.EnableImprovedSectionHelp__c = true;}                     
            
            
            // Elements added in 1.21
            if(EnabledElements.EnableImprovedRecordTitleHelp__c == null) {EnabledElements.EnableImprovedRecordTitleHelp__c = true;}                     
            if(EnabledElements.UpdateMarkerHours__c == null) {EnabledElements.UpdateMarkerHours__c = 0;}
            if(EnabledElements.EnableExportDocHT__c == null) {EnabledElements.EnableExportDocHT__c = true;}                     
            if(EnabledElements.EnableExportDocRL__c == null) {EnabledElements.EnableExportDocRL__c = true;}                     
            if(EnabledElements.EnableExportXL__c == null) {EnabledElements.EnableExportXL__c = true;}                       
            
            
            // Elements added in 1.23
            if(EnabledElements.TrackDaysVotes__c == null) {EnabledElements.TrackDaysVotes__c = 30;}
            // Default this to true - it should be the exception that one needs to alter this
            EnabledElements.jQNCMode__c = 'true';
            
            
            // Elements added in 1.24
            if(EnabledElements.DoLoginChecks__c == null) {EnabledElements.DoLoginChecks__c = true;}                                 
            
            
            // Elements added in 1.29
            if(EnabledElements.TrackDaysLUXOps__c == null) {EnabledElements.TrackDaysLUXOps__c = 30;}
            
            
            // Elements added in 1.32
            if(EnabledElements.DebugMode__c == null) {EnabledElements.DebugMode__c = false;}                                    
            
            
            // Elements added in 1.34
            if(EnabledElements.BrandUXOption__c == null) {EnabledElements.BrandUXOption__c = '3';}
            
            
            // Elements added in 1.35
            if(EnabledElements.DefaultRelationshipSemanticTag__c == null) {
                try {
                    SemanticTag__c STag = [SELECT Id FROM SemanticTag__c 
                                           WHERE Name = 'Relative' LIMIT 1];
                    system.debug('defst helptopic template'+STag.Id);
                    EnabledElements.DefaultRelationshipSemanticTag__c = STag.Id; // 
                } catch(Exception e) {
                    system.debug('Error'+e);
                    Diags += 'Semantic tag missing. Run createSemanticTags() first. ';
                }
            }
            
            // Need to default this to the Improved Help documents folder
            if(EnabledElements.ImageUploadFolder__c == null) {          
                try {
                    Folder Fld = [SELECT Id FROM Folder WHERE Name='Improved Help Documents'];
                    EnabledElements.ImageUploadFolder__c = Fld.Id;
                    
                } catch (Exception e) {
                    Diags += 'Error locating the Improved Help Documents folder... ';
                }
            }
            
            // Elements added in 1.50
            if(EnabledElements.DefaultHelpTopicTreeProvider__c == null) { 
                EnabledElements.DefaultHelpTopicTreeProvider__c = 'ServiceIHTrees.TNSHelpTopics';
            }            
            
            // Elements added in 1.51
            if(EnabledElements.RaisePlatformEvents__c == null) { 
                EnabledElements.RaisePlatformEvents__c = true;
            } 
            
            // Elements added in 1.55
            if(EnabledElements.Location_Tracking__c == null) { 
                EnabledElements.Location_Tracking__c = false;
            } 
            
            if(EnabledElements.Geo_Timeout__c == null) { 
                EnabledElements.Geo_Timeout__c = 3000;
            } 
            
            if(EnabledElements.Geo_EnableHighAccuracy__c == null) { 
                EnabledElements.Geo_EnableHighAccuracy__c = false;
            }  
            
            // Branding amendments - 1.51: if not set, use our branding colours
            if(EnabledElements.BrandColour1__c == null) {EnabledElements.BrandColour1__c = 'E1ECFF';}
            if(EnabledElements.BrandColour1Text__c == null) {EnabledElements.BrandColour1Text__c = 'Light';}
            if(EnabledElements.BrandColour2__c == null) {EnabledElements.BrandColour2__c = 'E1ECFF';}
            if(EnabledElements.BrandColour3__c == null) {EnabledElements.BrandColour3__c = 'FFFFFF';}
            if(EnabledElements.BrandColour4__c == null) {EnabledElements.BrandColour4__c = '009EED';}
            if(EnabledElements.BrandColour5__c == null) {EnabledElements.BrandColour5__c = '13235B';}
            if(EnabledElements.BrandColour6__c == null) {EnabledElements.BrandColour6__c = '13235B';}
            if(EnabledElements.BrandColour7__c == null) {EnabledElements.BrandColour7__c = '13235B';}         
            if(EnabledElements.BrandColour8__c == null) {EnabledElements.BrandColour8__c = '009EED';}
            
            // try{
            upsert EnabledElements;
            system.debug('Enabled Elements upsert');
            //  }catch(Exception e){
            //    System.debug('Error in upsert EnabledElements: ' + e.getMessage());
            //    System.debug('An error occurred during the upsert EnabledElements:: ' + e);
            //   System.debug('An error occurred during the upsert EnabledElements: - getCause: ' + e.getCause());
            //  System.debug('An error occurred during the upsert EnabledElements: - getLineNumber: ' + e.getLineNumber());
            //  System.debug('An error occurred during the upsert EnabledElements: - getMessage: ' + e.getMessage());
            //  System.debug('An error occurred during the upsert EnabledElements: - getStackTraceString: ' + e.getStackTraceString());
            // System.debug('An error occurred during the upsert EnabledElements: - getTypeName: ' + e.getTypeName());
            //  }
            
            
            
            // v1.42: Create key help topics here for LUX layouts and set defaults for related components
            Diags += 'Launching Apex job to create authoring Help materials... ';
            //     ControllerSettings.seedDocsFromUserDocAS('/resource/iahelp__IHResources/doc/HelpForHelpLUXApp.xml');
            System.enqueueJob(new SeedDocsQueueable('settings', '/resource/iahelp__IHResources/doc/HelpForHelpLUXApp.xml'));
            
            // Add a configuration tool record to hold details of whitelisted web domains
            Diags += 'Checking whitelisted domain information... ';
            
            ConfigurationItem__c CI = ControllerSettings.getWhitelistedDomainsData();
            
            // If we find this record, there is no need to act: create it if not
            if (CI == null) {
                CI = new ConfigurationItem__c();
                
                CI.ActionCode__c = 'GetWhitelistedDomains';
                CI.Description__c = 'This record stores data about the domains at which Help is to be made available and is not used as a clickable action';
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
                CI.SupportingControls__c = '';
                CI.TipText__c = 'NOT FOR USE AS A CLICKABLE';
                CI.ToggleActiveMarker__c = '';
                CI.ToggleNext__c = 0;
                CI.TogglePrev__c = 0;
                CI.ToolClass__c = '';
                CI.ToolContext__c = '[Hidden]';
                CI.ToolFilter__c = 0; 
                CI.Type__c = 'ConfigurationData';
                
                upsert CI;
                Diags += 'Whitelist created... ';
                
            } else {
                Diags += 'Whitelist retrieved... ';
            }
            
            // If we get here, we can re-set Diags
            Diags += 'Settings initialisation completed';
            
            return true;
        }
        
    }
    
    
}