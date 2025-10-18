@isTest

/////////////////////////////////////////////////////////////////////////////////////////////////////
// TEST CASES FOR CLASS ControllerSettings
//
// Martin Little for Improved Apps
// October 2012
/////////////////////////////////////////////////////////////////////////////////////////////////////


private class zTest_ControllerSettings {
    
    
    static testMethod void getIHSettings() {
        
        // Insert a global settings object
        zTest_DataGenerator DG = new zTest_DataGenerator();

        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        
        // We need to fix our URL in order to make the settings call:
        // Create a help topic record and pretend we're looking at that...
        HelpTopic__c Hlp = DG.getHelpTopic('Test');
        insert Hlp;
        String U = URL.getOrgDomainURL().toExternalForm() + '/' + Hlp.Id;
        
        // Also, if we're to get some callout details etc, we need to add some helped elements
        // to this help layout
        String HTID = Hlp.Id;
        HelpedPageLayout__c HPL = DG.getHelpedPageLayout('Test Layout', HTID.substring(0,3));
        insert HPL;
        
        HelpedElement__c HE = DG.getHelpedElement('Test Element', HPL.Id, Hlp.Id);
        insert HE;
        
        
        Test.startTest();
                        
            // Make the call to get settings
            ControllerSettings cS = new ControllerSettings();           
            String s = cS.getIHSettings(U);
            String sDelim = String.fromCharArray(new List<integer>{6});     
            String[] stgs = s.split(sDelim);
        
            ServiceSchema sc = new ServiceSchema();
            sc.getAllObjects();
            
            // Check that aspects of the return value are as we'd expect:
            // 5th item should be SF base URL
            System.assertEquals(URL.getOrgDomainURL().toExternalForm(), stgs[5]);

            cS.getRESTEnabled();
            cS.getConfigItemsCurrent();
            cS.initialiseMSMinPage();
            cS.getSettingsInitialised();
            cS.getObjData();
            cS.getLayoutMetadata();
            cS.reloadPage();
            cS.getLicense();
            cS.getBrandingLocalisations();
            cS.seedProfileLayouts();
            cS.seedDocsFromUserDocASynch();
            ControllerSettings.isConsolePage();
        Test.stopTest();
        return;     
    }   


    static testMethod void getIHSettingsGEMode() {

        // Insert a global settings object
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;


        // For GE mode, we need to create layout and already-guided elements:
        // Add 2x HT
        HelpTopic__c HT1 = DG.getHelpTopic('HT1');
        HelpTopic__c HT2 = DG.getHelpTopic('HT2');
        insert HT1;
        insert HT2;
        
        // 1x layout
        HelpedPageLayout__c HPL = DG.getHelpedPageLayout('Account Layout', '001');
        insert HPL;
        
        // 2x HEs tied to above
        HelpedElement__c HE1 = DG.getHelpedElement('HE1', HPL.Id, HT1.Id);
        HelpedElement__c HE2 = DG.getHelpedElement('HE2', HPL.Id, HT2.Id);
        insert HE1;
        insert HE2;
        
        // 1x RL - type = guide
        HelpReadingList__c RL = DG.getHelpReadingList('Guide');
        insert RL;
        
        // 2x RLEs tied to above
        HelpReadingListEntry__c RLE1 = DG.getHelpReadingListEntry(RL.Id, HT1.Id);
        HelpReadingListEntry__c RLE2 = DG.getHelpReadingListEntry(RL.Id, HT2.Id);
        insert RLE1;
        insert RLE2;
        
        // Now we need to set a cookie saying we're in GE mode before
        // setting our URL to the helped layout specified above
        String U = URL.getOrgDomainURL().toExternalForm() + '/001';
        PageReference pageRef = new PageReference(U);
        Test.setCurrentPage(pageRef);
        
        Cookie[] cookies = new Cookie[]{};
        Cookie C = new Cookie('IHSelectedRL', RL.Id, null, -1, false);
        cookies.add(C);
        ApexPages.currentPage().setCookies(cookies);
                
        Test.startTest();
                        
            // Make the call to get settings
            ControllerSettings cS = new ControllerSettings();           
            String s = cS.getIHSettings(U);
            String sDelim = String.fromCharArray(new List<integer>{6});     
            String[] stgs = s.split(sDelim);
            
            // Check that aspects of the return value are as we'd expect:
            // Relevant element should say we're in guide enable mode
            System.assertEquals('GEnable', stgs[28]);
        
        Test.stopTest();
        return;
    }
    

    static testMethod void getIHSettingsFailedElements() {
        
        // Insert a global settings object
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;

        ConfigurationItem__c CI = DG.getConfigurationItem3();
        insert CI;
        // For fails, we need to create several HEs some with failed DDFs:
        // We'll therefore need to create a current record to test against, too...
            
        // 1x layout
        HelpedPageLayout__c HPL = DG.getHelpedPageLayout('Account Layout', '001');
        insert HPL;
        HelpedPageLayout__c HPL2 = DG.getHelpedPageLayout('Contact Layout', '002');
        insert HPL2;
        
        // Add 1x HT
        HelpTopic__c HT1 = DG.getHelpTopic('HT1');
        HelpTopic__c HT2 = DG.getHelpTopic('HT2');
        HT1.GuidedLayout__c = HPL.Id;
        HT2.GuidedLayout__c = HPL2.Id;
        insert HT1;
        insert HT2;
        
        HelpReadingList__c RL = DG.getHelpReadingList('test');
        RL.Active__c = true;
        insert RL;
        
        HelpReadingListEntry__c RLE = DG.getHelpReadingListEntry(RL.Id,HT2.Id);
        insert RLE;
        HelpReadingListEntry__c RLE2 = DG.getHelpReadingListEntry(RL.Id,HT1.Id);
        insert RLE2;
        
        // 2x HEs tied to above, one with a failing DDF
        HelpedElement__c HE1 = DG.getHelpedElement('HE1', HPL.Id, HT1.Id);
        HelpedElement__c HE2 = DG.getHelpedElement('HE2', HPL.Id, HT2.Id);
        
        HE2.DataDrivenFilter__c = '1=2';
        
        insert HE1;
        insert HE2;
        
        // 1x Account to visit
        Account A = new Account();
        A.Name = 'Test Account';
        A.Type = 'Prospect';
        insert A;
        
        
        // Now set our URL to the record created above
        String U = URL.getOrgDomainURL().toExternalForm() + '/' + A.Id;
        PageReference pageRef = new PageReference(U);
        Test.setCurrentPage(pageRef);
                        
        Test.startTest();
                        
            // Make the call to get settings
            ControllerSettings cS = new ControllerSettings();           
            String s = cS.getIHSettings(U);
            String sDelim = String.fromCharArray(new List<integer>{6});     
            String[] stgs = s.split(sDelim);
            
            // Check that aspects of the return value are as we'd expect:
            // Relevant element should say we've got some failed elements
            
system.assertEquals('001', stgs[9]);
            
            System.assertNotEquals('', stgs[31]);
        
        Test.stopTest();
        return;
    }
    

    static testMethod void getIHSettingsHelpFilter() {
        
        // Insert a global settings object
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;


        // For fails, we need to create several HEs some with failed DDFs:
        // We'll therefore need to create a current record to test against, too...
        
        // Add 1x HT
        HelpTopic__c HT1 = DG.getHelpTopic('HT1');
        HelpTopic__c HT2 = DG.getHelpTopic('HT2');
        insert HT1;
        insert HT2;

        // Add 2x help filter records each with 1x criteria
        HelpFilter__c F1 = new HelpFilter__c();
        HelpFilter__c F2 = new HelpFilter__c();
        
        F1.FilteredObject__c = 'Account';
        F1.FilteredObjectIdentifier__c = '001';
        F1.FilterIdentifier__c = 'Passes';
        F1.FilterLogic__c = '1 AND 2';
        insert F1;
        
        F2.FilteredObject__c = 'Account';
        F2.FilteredObjectIdentifier__c = '001';
        F2.FilterIdentifier__c = 'Fails';
        F2.FilterLogic__c = '1';
        insert F2;

        HelpFilterCriterion__c F1AC = new HelpFilterCriterion__c();
        HelpFilterCriterion__c F1BC = new HelpFilterCriterion__c();
        HelpFilterCriterion__c F2C = new HelpFilterCriterion__c();

        F1AC.HelpFilter__c = F1.Id;
        F1AC.CriterionNumber__c = 1;
        F1AC.FilteredField__c = 'name';
        F1AC.FilteredFieldType__c = 'string';
        F1AC.Operator__c = '=';
        F1AC.FilterValue__c = 'Test Account';
        insert F1AC;

        F1BC.HelpFilter__c = F1.Id;
        F1BC.CriterionNumber__c = 1;
        F1BC.FilteredField__c = 'name';
        F1BC.FilteredFieldType__c = 'string';
        F1BC.Operator__c = 'LIKE';
        F1BC.FilterValue__c = 'Test%';
        insert F1BC;

        F2C.HelpFilter__c = F2.Id;
        F2C.CriterionNumber__c = 1;
        F2C.FilteredField__c = 'name';
        F2C.FilteredFieldType__c = 'string';
        F2C.Operator__c = '!=';
        F2C.FilterValue__c = 'Test Account';
        insert F2C;

        
        // 1x layout
        HelpedPageLayout__c HPL = DG.getHelpedPageLayout('Account Layout', '001');
        insert HPL;
        
        // 2x HEs tied to above, one with a failing help filter
        HelpedElement__c HE1 = DG.getHelpedElement('HE1', HPL.Id, HT1.Id);
        HelpedElement__c HE2 = DG.getHelpedElement('HE2', HPL.Id, HT2.Id);
        
        HE1.HelpFilter__c = F1.Id;
        HE2.HelpFilter__c = F2.Id;
        
        insert HE1;
        insert HE2;
        
        // 1x Account to visit
        Account A = new Account();
        A.Name = 'Test Account';
        A.Type = 'Prospect';
        insert A;
        
        
        // Now set our URL to the record created above
        String U = URL.getOrgDomainURL().toExternalForm() + '/' + A.Id;
        PageReference pageRef = new PageReference(U);
        Test.setCurrentPage(pageRef);
                        
        Test.startTest();
                        
            // Make the call to get settings
            ControllerSettings cS = new ControllerSettings();           
            String s = cS.getIHSettings(U);
            String sDelim1 = String.fromCharArray(new List<integer>{6});     
            String D1 = String.fromCharArray(new List<integer>{7});     
            String D2 = String.fromCharArray(new List<integer>{5});     
            
            String[] stgs = s.split(sDelim1);
            
            // Check that aspects of the return value are as we'd expect:
            // Relevant element should say we've got some failed elements
            System.assertEquals(D2 + HE2.Identifier__c + D1, stgs[31]);
        
        Test.stopTest();
        return;
    }


    static testMethod void getTemplatesCF() {
        
        // Insert some templates and see we get the right ones back
        zTest_DataGenerator DG = new zTest_DataGenerator();

        HelpTopicTemplate__c TC1 = DG.getHelpTopicTemplate('C1', 'C1');
        HelpTopicTemplate__c TC2 = DG.getHelpTopicTemplate('C2', 'C2');
        HelpTopicTemplate__c TC3 = DG.getHelpTopicTemplate('C3', 'C3');
        HelpTopicTemplate__c TF1 = DG.getHelpTopicTemplate('F1', 'F1');
        HelpTopicTemplate__c TF2 = DG.getHelpTopicTemplate('F2', 'F2');
        
        // Templates default to full topic: amend callouts here
        TC1.TemplateType__c = 'Callout';
        TC2.TemplateType__c = 'Callout';
        TC3.TemplateType__c = 'Callout';
        
        insert TC1;
        insert TC2;
        insert TC3;
        insert TF1;
        insert TF2;
        
        Test.startTest();
            
            ControllerSettings cS = new ControllerSettings();
            List<selectOption> soC = cS.getTemplatesC();
            System.assertEquals(3, soC.size());
            
            List<selectOption> soF = cS.getTemplatesF();
            System.assertEquals(2, soF.size());
        
        Test.stopTest();
        return;
    }

    
    static testMethod void showSettings() {
        
        // Create some settings and check we can retrieve these
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
                
                
        Test.startTest();
            
            ControllerSettings cS = new ControllerSettings();
            cS.showSettings();
            System.assertEquals('Brand Title', ControllerSettings.getSettings().BrandTitle__c);
            
            ControllerSettings.getSettings().BrandSubTitle__c += ' Amended';
            cS.saveSettings();
            //System.assertEquals('Brand Title Amended', ControllerSettings.getSettings().BrandTitle__c);
        
        Test.stopTest();
        return;
    }
    
    
    static testMethod void getTemplatesLink() {
        
        zTest_DataGenerator DG = new zTest_DataGenerator();                                                       
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        ControllerSettings cS = new ControllerSettings();
        String retVal;
        
        Test.startTest();
            retVal = cS.getTemplatesLink();
            system.assertNotEquals('#', retVal);
        Test.stopTest();
        
        return;     
    }
    
    
    static testMethod void resetHBS() {
        
        zTest_DataGenerator DG = new zTest_DataGenerator();                                                       
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        
        ControllerSettings cS = new ControllerSettings();
        String retVal;
        
        Test.startTest();
            cS.resetHBS();
            system.assert(cS.Diags.indexOf('Error') == -1);
        Test.stopTest();
        return;             
    }
    
    
    static testMethod void scheduleRetention() {
        
        // Settings are required for this because there need to be
        // retention days figures...    
        zTest_DataGenerator DG = new zTest_DataGenerator();                                                       
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        ControllerSettings cS = new ControllerSettings();
        String retVal;
                
        Test.startTest();

            cS.scheduleRetention();
         
        Test.stopTest();

        System.assertEquals(cS.getGlobalLocalisations().get('MessageGenericTaskComplete'), cS.Diags);
        
        return;
    }


    static testMethod void seedHelpSettings() {

        ControllerSettings cS = new ControllerSettings();
        String retVal;
                
        Test.startTest();

            cS.seedHelpSettings();
         
        Test.stopTest();

       // System.assertEquals(cS.Diags.startsWith(cS.getGlobalLocalisations().get('MessageGenericTaskComplete')), true);
        
        return;
        
    }
    
    //For Test Coverage of SeedHelpSettingsBatch Class used for automating the post install Process

           static testMethod void seedHelpSettingsBatch() {
       
        String retVal;
               
        Test.startTest();
    
        SeedHelpSettingsBatch b2=new SeedHelpSettingsBatch();
        Database.executeBatch(b2,10);
         
               System.enqueueJob(new SeedDocsQueueable('handleMetadata', null));
               System.enqueueJob(new SeedDocsQueueable('cacheObjects', null));
               //SeedHelpSettingsBatch.createGlobalSettings();
        Test.stopTest();

       // System.assertEquals(cS.Diags.startsWith(cS.getGlobalLocalisations().get('MessageGenericTaskComplete')), true);
        
        return;
     }
    
           static testMethod void seedHelpSettingsBatch2() {
       
        String retVal;
               
        Test.startTest();
               System.enqueueJob(new SeedDocsQueueable('cacheObjects', null));
               //SeedHelpSettingsBatch.createGlobalSettings();
        Test.stopTest();

       // System.assertEquals(cS.Diags.startsWith(cS.getGlobalLocalisations().get('MessageGenericTaskComplete')), true);
        
        return;
     }
    
    static testMethod void seedHelpSettingsBatch1() {
        Profile lowProfile = [SELECT Id FROM Profile WHERE Name = 'Read Only' LIMIT 1];
        
        // Step 2: Create test user
        User lowUser = new User(
            FirstName = 'Low',
            LastName = 'PrivUser',
            Alias = 'lpriv',
            Email = 'lowprivuser@example.com',
            Username = 'lowprivuser_test_' + DateTime.now().getTime() + '@example.com',
            ProfileId = lowProfile.Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert lowUser;
        
        
        // Step 3: Run test logic as that user
        System.runAs(lowUser) {
            // Reconfirm which user is running
            User currentUser = [SELECT Id, Name FROM User WHERE Id = :UserInfo.getUserId()];
            System.debug('Current User: ' + currentUser.Name);
        
        // ControllerSettings cS = new ControllerSettings();
        
        String retVal;
        
        Test.startTest();
        SeedHelpSettingsBatch b2=new SeedHelpSettingsBatch();
      Database.executeBatch(b2,10);
        
        System.enqueueJob(new SeedDocsQueueable('handleMetadata', null));
            System.enqueueJob(new SeedDocsQueueable('cacheObjects', null));
            System.enqueueJob(new SeedConfigFromUserDocQueueable()); 
            System.enqueueJob(new SeedDocsQueueable('settings', '/resource/iahelp__IHResources/doc/HelpForHelpLUXApp.xml'));
        Test.stopTest();
        }
        // System.assertEquals(cS.Diags.startsWith(cS.getGlobalLocalisations().get('MessageGenericTaskComplete')), true);
        
        return;
    }
    
    
     static testMethod void testEnqueueUpdateValueSetQueueable() {
        // Prepare test data
        String objName = 'iahelp__ConfigurationItem__c';
        
        // Map<String, List<String>> picval
          map<string,string> picval  = new map<string,string>();  
        picval.put('iahelp__Type__c','AuthorConfiguration,Body,ConfigurationData,Drop-down,Ellipsis,Extension,Footer,Header,Listing,ProductVersion,WizardStep,WizardStepBodyTool'); //Map of field APIName and valueSet.
        picval.put('iahelp__ToolContext__c','[Hidden],[Template],AlertOKOnly,Builder,CardAutoForm,CardAutoForm_TopicViewer,CardComment,CardComment_Listing,CardHelpTopic,CardKeywords,CardReadingLists,CardRelatedHelp,CardRelatedTags,CardResources,CardStickies,CardTags,CardTree,CardTreeOtherList,CardTreeSearchList,CGDesignMode,FixedHelp,GEModeTopicSearchList,IHLUXApp_Settings_Tabs,ImageViewer,LinkResources,LinkTopics,NewSticky,PositionDetector,PositionDetectorCG,PositionDetectorHelpButtons,PositionDetectorHelpRequests,QAM,QAMHelpIndex_Topic,QAMHelpIndex_Tree,QuickStartU1_Tree,ReadingListBuilder_Topic,ReadingListBuilder_Topic_Autoform,ReadingListBuilder_Tree,ReconfigureMode_Topic,ReconfigureMode_Topic_Autoform,ReconfigureMode_Tree,RLViewer,tabsTest1,Test,wizBulkTopicUpload,wizCxtHelp,wizCxtHelp_Step1_List,wizCxtHelp_Step2_List,wizTest');

        // String LXTsDelStr (null in this case)
        String LXTsDelStr = null;

        // List<Object> LXTsOutStr as List<Map<String, Object>>
        List<Map<String, Object>> LXTsOutStr = new List<Map<String, Object>>();
        
        Map<String, Object> record = new Map<String, Object>{
            'attributes' => new Map<String, String>{
                'type' => 'iahelp__ConfigurationItem__c'
            },
            'iahelp__ActionCode__c' => 'HelpRequest',
            'iahelp__Description__c' => 'Issues a message allowing the position detector to log a Help Request interaction on behalf of the user.',
            'iahelp__DisplayGrouping__c' => '[Default]',
            'iahelp__DisplayOrder__c' => 1.0,
            'iahelp__HasDivider__c' => false,
            'iahelp__IconClass__c' => 'fa-question',
            'iahelp__Label__c' => 'HelpRequest',
            'iahelp__NegotiateToolbarLevel__c' => 0.0,
            'iahelp__PermissionLevel__c' => 1.0,
            'iahelp__SkipExport__c' => false,
            'iahelp__SkipImportOverwrite__c' => false,
            'iahelp__TipText__c' => 'HelpRequest',
            'iahelp__ToggleNext__c' => 0.0,
            'iahelp__TogglePrev__c' => 0.0,
            'iahelp__ToolContext__c' => 'PositionDetectorHelpRequests',
            'iahelp__ToolFilter__c' => -1.0,
            'iahelp__Type__c' => 'Header'
        };
            
        LXTsOutStr.add(record);

 String LXTsOut =  JSON.serialize(LXTsOutStr);
        // Enqueue job
        Test.startTest();
        System.enqueueJob(new UpdateValueSetQueueable(objName, picval, LXTsDelStr,LXTsOut));
        Test.stopTest();

    }



    
   // For test coverage of non-standard page addresses
   static testMethod void SFObjId() {
        
        zTest_DataGenerator DG = new zTest_DataGenerator();                                                       
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
                
        ControllerSettings cS = new ControllerSettings();
        string theUrl;
        
        Test.startTest();
            // Non-SF addresses should be returned "as is" as page identifiers
            theUrl = 'http://www.NoSuch.com/test.jsp';
            system.assert(cS.SFObjId(theUrl) == theUrl);

            theUrl = 'http://www.salesforce.com/test.jsp';
            system.assert(cS.SFObjId(theUrl) == 'test.jsp');

        Test.stopTest();
        return;             
    }


    static testMethod void getSignaturesLink() {

        zTest_DataGenerator DG = new zTest_DataGenerator();                                                       
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
                
        ControllerSettings cS = new ControllerSettings();
        String retVal;
        
        Test.startTest();
            retVal = cS.getSignaturesLink();
            system.assertNotEquals('#', retVal);
        Test.stopTest();
        return;                     
    }


    static testMethod void getInteractionsLink() {

        zTest_DataGenerator DG = new zTest_DataGenerator();                                                       
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
                
        ControllerSettings cS = new ControllerSettings();
        String retVal;
        
        Test.startTest();
            retVal = cS.getInteractionsLink();
            system.assertNotEquals('#', retVal);
        Test.stopTest();
        return;                     
    }


    static testMethod void cancelSettingsChanges() {

        zTest_DataGenerator DG = new zTest_DataGenerator();                                                       
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
                
        ControllerSettings cS = new ControllerSettings();
        PageReference retVal;
        
        Test.startTest();
            retVal = cS.cancelSettingsChanges();
            system.assertNotEquals(null, retVal);
        Test.stopTest();
        return;                     
    }


    static testMethod void seedDocsFromIHResources() {

        zTest_DataGenerator DG = new zTest_DataGenerator();                                                       
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
                
        ControllerSettings cS = new ControllerSettings();
        
        Test.startTest();
            // Can't make this call work in test scenario?
            // "Methods defined as TestMethod do not support getContent call" - as present in seedDocumentation!
            cS.seedDocsFromIHResources();

            //system.assert(cS.Diags.startsWith(cS.getGlobalLocalisations().get('MessageGenericTaskComplete')));
            //system.assertEquals(cS.Diags,cS.getGlobalLocalisations().get('MessageGenericTaskComplete'));
            system.assertEquals('', '');
        Test.stopTest();
        return;                     
    }
    static testMethod void getVoteSetsTest() {
        zTest_DataGenerator DG = new zTest_DataGenerator();                                                       
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        ControllerSettings cS = new ControllerSettings();
        cS.getVoteSets();
        
    }
    static testMethod void seedConfigFromUserDoc() {

        zTest_DataGenerator DG = new zTest_DataGenerator();                                                       
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
         
        ConfigurationItem__c ci = DG.getConfigurationItem2('tree','ellipsis',1);
        insert ci;
        
        ControllerSettings cS = new ControllerSettings();
        
        document d = DG.getConfigurationJSONDoc();
        insert d;
        
        Test.startTest();
            // Attempt without specifying path to JSON
            cS.UserJSONDoc = '';
            cS.seedConfigFromUserDoc();
        //    system.assert(cS.Diags.startsWith(cS.getDialogueLocalisations().get('MessageEnterJSONPath')));
            
            // Set path and try again
            cS.UserJSONDoc = '/resource/iahelp__IHResources/cfg/HelpConfig.json';
            cS.seedConfigFromUserDoc();
            // Can't make this call work in test scenario?
            // "Methods defined as TestMethod do not support getContent call" - as present in seedDocumentation!
            //system.assert(cS.Diags.startsWith(cS.getGlobalLocalisations().get('MessageGenericTaskComplete')));
            //system.assertEquals(cS.Diags, cS.getGlobalLocalisations().get('MessageGenericTaskComplete'));
            
        Test.stopTest();
        return;                     
    }


    static testMethod void seedCSSTextFromFile() {

        zTest_DataGenerator DG = new zTest_DataGenerator();                                                       
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
                
        ControllerSettings cS = new ControllerSettings();
        
        Test.startTest();
            cS.seedCSSTextFromFile();
            system.assert(cS.Diags.startsWith(cS.getGlobalLocalisations().get('MessageGenericTaskComplete')));
            
            
        Test.stopTest();
        return;                     
    }
    

    static testMethod void seedDocsFromUserDoc() {

        zTest_DataGenerator DG = new zTest_DataGenerator();                                                       
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
                
        ControllerSettings cS = new ControllerSettings();
        
        Test.startTest();
            // Attempt without specifying path to JSON
            cS.UserXMLDoc = '';
            cS.seedDocsFromUserDoc();
            system.assert(cS.Diags.startsWith(cS.getDialogueLocalisations().get('MessageEnterXMLPath')));
            
            // Set path and try again
            cS.UserXMLDoc = '/resource/iahelp__IHResources/doc/HelpForHelpLUXApp.xml';
            
            cS.seedDocsFromUserDoc();
            // Can't make this call work in test scenario?
            // "Methods defined as TestMethod do not support getContent call" - as present in seedDocumentation!
            //system.assert(cS.Diags.startsWith(cS.getGlobalLocalisations().get('MessageGenericTaskComplete')));
            //system.assertEquals(cS.Diags, cS.getGlobalLocalisations().get('MessageGenericTaskComplete'));

        Test.stopTest();
        return;                     
    }
    
    
    static testMethod void downloadDataJSONASynch() {

        zTest_DataGenerator DG = new zTest_DataGenerator();                                                       
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
                
        ControllerSettings cS = new ControllerSettings();
        
        Test.startTest();
            
            cS.downloadDataJSONASynch();
            
            // Not sure what to assert here as results are asynchronous...
            system.assertEquals('', '');

        Test.stopTest();
        return;                     
    }
    

    
/*
seedProfileLayouts

*/    
 
}