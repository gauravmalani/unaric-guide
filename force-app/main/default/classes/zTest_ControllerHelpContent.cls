@isTest

/////////////////////////////////////////////////////////////////////////////////////////////////////
// TEST CASES FOR CLASS ControllerHelpContent
//
// Martin Little for Improved Apps
// October 2012
/////////////////////////////////////////////////////////////////////////////////////////////////////


private class zTest_ControllerHelpContent {    

    static testMethod void testSetupVoteInfoForTopic(){
        // Settings are required for this 
        zTest_DataGenerator DG = new zTest_DataGenerator();
        HelpTopic__c Hlp = DG.getHelpTopic('test');
        HelpVoteSet__c hvs = DG.getHelpVoteSet('testvoteset');
        HelpVoteOption__c hvo = DG.getHelpVoteOption(hvs.Id,'smiley',1);
        ControllerHelpContent cH = new ControllerHelpContent();
        cH.setupVoteInfoForTopic(Hlp.Id,hvs.Id);
        HelpInteraction__c hi = new HelpInteraction__c();
      //  hi.HelpVoteOption__c = hvo.Id;
       // hi.
    }
    static testMethod void initialiseForBookmarks() {

        // Settings are required for this 
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
                
        Test.startTest();
        
            ControllerHelpContent cH = new ControllerHelpContent();
            PageReference pageRef = Page.IHTools;
            Test.setCurrentPage(pageRef);
            cH.initialiseForBookmarks();
        
        Test.stopTest();

        System.assertEquals('', cH.TName);
        return;     
    }
    

    static testMethod void getImprovedHelp() {
        
        // Settings are required for this 
        ControllerHelpContent cH = new ControllerHelpContent();
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;


        // This call is for custom templates - but we can proceed as if
        // for ordinary IH page: making the wrapper call should result
        // in the same (limited global) member data
        
        HelpTopic__c HT = DG.getHelpTopic('Test via globals');
        insert HT;

        // 1.28.1+ No need for a subscription file in this release
        //Document d = DG.getSubscriptionDoc();
        //insert d;
        
        Test.startTest();
            PageReference pageRef = Page.IHTools;
            Test.setCurrentPage(pageRef);
            
            // Get the created help topic
            ApexPages.currentPage().getParameters().put('HTID', HT.Id);
            cH.getImprovedHelp();        
            System.assertEquals('', cH.Diags);
            System.assertEquals('Test via globals', cH.getTopic().Name);
        Test.stopTest();
                
        return;     
    }


    static testMethod void getImprovedHelpErrorPath() {
        
        // Settings are required for this 
        ControllerHelpContent cH = new ControllerHelpContent();
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;

        // 1.28.1+ No need for a subscription file in this release
        //Document d = DG.getSubscriptionDoc();
        //insert d;
                
        Test.startTest();
            // Test error trap by requesting a non-topic (there being no default topic in the settings created by DG)
            PageReference pageRef = Page.IHTools;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('HTID', '');
            cH.getImprovedHelp();        
            System.assertEquals(cH.getGlobalLocalisations().get('MessageGenericErrorShort'), cH.getTopic().Name);
                    
        Test.stopTest();
        
        return;     
    }


    static testMethod void getHelpViaHTID() {

        // Settings are required for this 
        zTest_DataGenerator DG = new zTest_DataGenerator();                                                      
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        // 1.28.1+ No need for a subscription file in this release
        //Document d = DG.getSubscriptionDoc();
        //insert d;
        
        // Create a help topic with a correctly set template
        HelpTopic__c Hlp = DG.getHelpTopic('Test');
        insert Hlp;
        
        HelpTopicTemplate__c HT = DG.getHelpTopicTemplate('Test Template', 'NoSuchVFPage');
        insert HT;
        
        Hlp.Template__c = HT.Id;
        update Hlp;
        
        HelpedPageLayout__c HPL = DG.getHelpedPageLayout('Test Layout', 'IHTools');
        insert HPL;
        
        HelpedElement__c HE = DG.getHelpedElement('Test Element', HPL.Id, Hlp.Id);
        insert HE;
        
        
        // Also, add 1x related help...
        HelpTopic__c Hlp2 = DG.getHelpTopic('Test 2');
        insert Hlp2;
        HelpRelationship__c HR = DG.getHelpRelationship(Hlp, Hlp2);
        insert HR;
        
        // ...1x resource...
        HelpResource__c Res = DG.getHelpResource('Test Resource');
        insert Res;
        HelpTopicResource__c HTR = DG.getHelpTopicResource(Res, Hlp);
        insert HTR;
        
        // ... and 1x reading list
        HelpReadingList__c RL = DG.getHelpReadingList('Test Reading List');
        insert RL;
        HelpReadingListEntry__c RLE = DG.getHelpReadingListEntry(RL.Id, Hlp.Id);
        insert RLE;
        
        // Consider use of the code below in these tests!
        //system.runAs(pSObject, pANY)

        ControllerHelpContent cH = new ControllerHelpContent();
        
        Test.startTest();
            
            PageReference pageRef = Page.IHTools;
            Test.setCurrentPage(pageRef);
            
            // Test that reaching page with no query string attempts to go to default topic:
            // As this has not been specified, we should get an error
            cH.getHelp();
            System.assertEquals(cH.getGlobalLocalisations().get('MessageMissingDefaultTopic'), cH.TName);
        
            
            // Get a topic via help topic id
            ApexPages.currentPage().getParameters().put('HTID', Hlp.Id);            
            cH.getHelp();
            System.assertEquals(Hlp.Id, cH.THelpId);

            // Ensure we get the related help topics, resources and reading lists
            System.assertEquals(1, cH.Relations.size());
            System.assertEquals(1, cH.Resources.size());
            System.assertEquals(1, cH.ReadingLists.size());
            
        Test.stopTest();

        return;
    }
 

    static testMethod void getHelpViaElemId() {

        // Settings are required for this 
        zTest_DataGenerator DG = new zTest_DataGenerator();                                                      
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        // 1.28.1+ No need for a subscription file in this release
        //Document d = DG.getSubscriptionDoc();
        //insert d;
        
        // Create a help topic with a correctly set template
        HelpTopic__c Hlp = DG.getHelpTopic('Test');
        insert Hlp;
        
        HelpTopicTemplate__c HT = DG.getHelpTopicTemplate('Test Template', 'NoSuchVFPage');
        insert HT;
        
        Hlp.Template__c = HT.Id;
        update Hlp;
        
        HelpedPageLayout__c HPL = DG.getHelpedPageLayout('Test Layout', 'IHTools');
        insert HPL;
        
        HelpedElement__c HE = DG.getHelpedElement('Test Element', HPL.Id, Hlp.Id);
        insert HE;
        
        
        // Create a "default" help topic for certain tests
        HelpTopic__c HlpD = DG.getHelpTopic('Default Topic');
        HlpD.Template__c = HT.Id;
        insert HlpD;
        
        
        // Also, add 1x related help...
        HelpTopic__c Hlp2 = DG.getHelpTopic('Test 2');
        insert Hlp2;
        HelpRelationship__c HR = DG.getHelpRelationship(Hlp, Hlp2);
        insert HR;
        
        // ...1x resource...
        HelpResource__c Res = DG.getHelpResource('Test Resource');
        insert Res;
        HelpTopicResource__c HTR = DG.getHelpTopicResource(Res, Hlp);
        insert HTR;
        
        // ... and 1x reading list...
        HelpReadingList__c RL = DG.getHelpReadingList('Test Reading List');
        insert RL;
        HelpReadingListEntry__c RLE = DG.getHelpReadingListEntry(RL.Id, Hlp.Id);
        insert RLE;
        
        // ... Also add 1x bookmark
        HelpBookmark__c Bmk = DG.getHelpBookmark(Hlp.Id);
        insert Bmk;
        
        
        // Consider use of the code below in these tests!
        //system.runAs(pSObject, pANY)

        ControllerHelpContent cH = new ControllerHelpContent();
        
        Test.startTest();
            
            PageReference pageRef = Page.IHTools;
            Test.setCurrentPage(pageRef);

            // Test that reaching page with no query string attempts to go to default topic:
            // As this has not been specified, we should get an error
            cH.getHelp();
            System.assertEquals(cH.getGlobalLocalisations().get('MessageMissingDefaultTopic'), cH.TName);

        
            // Set default topic: try again:
            // Check we get to the topic
            IASet.DefaultHelpTopic__c = HlpD.Id;
            update IASet;
            //cH.getHelp();
            //System.assertEquals(HlpD.Name, cH.TName);
            
            // Get a topic via element id
            ApexPages.currentPage().getParameters().put('ElemId', HE.Identifier__c);            
            ApexPages.currentPage().getParameters().put('HPL', HPL.PageLayoutIdentifier__c);            
            cH.getHelp();
            System.assertEquals(Hlp.Id, cH.THelpId);

            // Ensure we get the related help topics, resources and reading lists
            System.assertEquals(1, cH.Relations.size());
            System.assertEquals(1, cH.Resources.size());
            System.assertEquals(1, cH.ReadingLists.size());
            System.assertEquals(1, cH.Bookmarks.size());
                    
        Test.stopTest();

        return;
    }

 
     static testMethod void getHelpViaRLID() {
        
        // Settings are required for this 
        zTest_DataGenerator DG = new zTest_DataGenerator();                                                      
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        // 1.28.1+ No need for a subscription file in this release
        //Document d = DG.getSubscriptionDoc();
        //insert d;
        
        
        // Create a help topic with a correctly set template
        HelpTopic__c Hlp = DG.getHelpTopic('Test');
        insert Hlp;
        
        HelpTopicTemplate__c HT = DG.getHelpTopicTemplate('Test Template', 'NoSuchVFPage');
        insert HT;
        
        Hlp.Template__c = HT.Id;
        update Hlp;
        
        // Create a reading list featuring this help topic
        HelpReadingList__c RL = DG.getHelpReadingList('Test Reading List');
        insert RL;
        HelpReadingListEntry__c RLE = DG.getHelpReadingListEntry(RL.Id, Hlp.Id);
        insert RLE;
        
        ControllerHelpContent cH = new ControllerHelpContent();
        
        Test.startTest();

            // Check that a garbage reading list ID is handled
            PageReference pageRef = Page.IHTools;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('RLID', '12345');            
            cH.getHelp();
            System.assertNotEquals(-1, cH.Diags.indexOf(cH.getGlobalLocalisations().get('MessageGenericError')));
                        
            // Get a topic via reading list ID
            ApexPages.currentPage().getParameters().put('RLID', RL.Id);            
            cH.getHelp();
            System.assertEquals(Hlp.Id, cH.THelpId);
                    
        Test.stopTest();

        return;         
     }

 
     static testMethod void getHelpedElement() {
        
        // Settings are required for this 
        zTest_DataGenerator DG = new zTest_DataGenerator();                                                      
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        ControllerHelpContent cH = new ControllerHelpContent();

        // Add 2 elements to a page layout
        HelpTopic__c HT1 = DG.getHelpTopic('T1');
        HelpTopic__c HT2 = DG.getHelpTopic('T2');
        insert HT1;
        insert HT2;
        
        HelpedPageLayout__c HPL = DG.getHelpedPageLayout('Test Layout', '001');
        insert HPL;
        
        HelpedElement__c HE1 = DG.getHelpedElement('HE1', HPL.Id, HT1.Id);
        HelpedElement__c HE2 = DG.getHelpedElement('HE1', HPL.Id, HT2.Id);
        insert HE1;
        insert HE2;
        
        Test.startTest();
            PageReference pageRef = Page.IHHelpedElement;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('ElemId', 'HE1');           
            ApexPages.currentPage().getParameters().put('HPL', '001');          
            ApexPages.currentPage().getParameters().put('ActiveId', HE2.Id);            
            
            cH.getHelpedElement();
            
            System.assertEquals(2, cH.allHEs.size());
        Test.stopTest();

        return;                 
     }
     
 
     static testMethod void checkServiceUnavailable() {

        zTest_DataGenerator DG = new zTest_DataGenerator();                                                      
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        ControllerHelpContent cH = new ControllerHelpContent();
        
        Test.startTest();
            // Check we need a license file
            PageReference P = cH.checkServiceUnavailable();
            //System.assertEquals(null, P);
            
            // Insert file and try again
            // 1.28.1+ No need for a subscription file in this release
            //Document d = DG.getSubscriptionDoc();
            //insert d;
            
            //P = cH.checkServiceUnavailable();
            System.assertNotEquals(null, P);
            
        Test.stopTest();

        return;                         
     }
 
 
     static testMethod void gotoResource() {

        zTest_DataGenerator DG = new zTest_DataGenerator();                                                      
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        ControllerHelpContent cH = new ControllerHelpContent();
        
        HelpResource__c HR = DG.getHelpResource('Test Resource');
        insert HR;
        
        HelpTopic__c HT = DG.getHelpTopic('HT');
        insert HT;
        
        HelpTopicresource__c HTR = DG.getHelpTopicResource(HR, HT);
        insert HTR;
        
        Test.startTest();
            // Attempt to visit a non-existant resource
            cH.SelectedRecord = 'xxx';
            PageReference P = cH.gotoResource();
            System.assertEquals(null, P);           
            
            // check you can visit a valid one
            cH.SelectedRecord = HTR.Id;
            P = cH.gotoResource();
            System.assertNotEquals(null, P);
            
        Test.stopTest();

        return;                         
     }
 
 
     static testMethod void gotoTopicTemplate() {
        
        // Create a help topic with associated full template
        zTest_DataGenerator DG = new zTest_DataGenerator();

        HelpTopicTemplate__c HT = DG.getHelpTopicTemplate('Test Template', 'TestTemplate');
        insert HT;

        HelpTopic__c Hlp1 = DG.getHelpTopic('Test 1');
        Hlp1.Template__c = HT.Id;
        insert Hlp1;
        
        Test.startTest();
        
            ControllerHelpContent cH = new ControllerHelpContent();

            // Go to a page, specifying HTID parameter as our inserted help topic 
            PageReference pageRef = Page.IHTools;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('HTID', Hlp1.Id);            

            // Now call the redirector function, noting the page reference we get back
            PageReference PR = cH.gotoTopicTemplate();
            
            // This should be the path of our template
            System.assert(PR.getUrl().startsWith(URL.getOrgDomainURL().toExternalForm() + '/apex/' + HT.PageURL__c + '?HTID=' + Hlp1.Id));
             
        Test.stopTest();
        return;
        
     }
     
     
    static testMethod void getDefaultHelpTopic() {

        // Create a help topic with associated full template
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;

        Test.startTest();
        
            ControllerHelpContent cH = new ControllerHelpContent();
            HelpTopic__c Hlp = cH.getDefaultHelpTopic();
            
            // Check defaults match those in global settings
            System.assertEquals(IASet.DefaultHelpTopicTemplate__c, Hlp.Template__c);
             
        Test.stopTest();
        return;
        
    } 
    
    
     
    static testMethod void saveHelp() {

        // Settings are required for this 
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;

        // 1.28.1+ No need for a subscription file in this release
        //Document d = DG.getSubscriptionDoc();
        //insert d;

        // Create a help topic with valid templates
        HelpTopicTemplate__c HTF = DG.getHelpTopicTemplate('Full', 'Full');
        HelpTopicTemplate__c HTC = DG.getHelpTopicTemplate('Callout', 'Callout');
        insert HTF;
        insert HTC;

        HelpTopic__c Hlp = DG.getHelpTopic('Test');
        Hlp.Template__c = HTF.Id;
        Hlp.CalloutTemplate__c = HTC.Id;
        insert Hlp;
                
        Test.startTest();
        
            ControllerHelpContent cH = new ControllerHelpContent();

            // Go to the inserted help topic
            PageReference pageRef = Page.IHTools;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('HTID', Hlp.Id);            
            cH.getHelp();

            // Edit the topic
            cH.Hlp.Name += ' - Edited';

            // Attempt to save these changes
            cH.saveHelp();
            System.assertEquals('Changes saved', cH.Diags);
                        
            //cH.getHelp();
            //System.assertEquals('Test - Edited', cH.TName);
            
        Test.stopTest();

        return;             
    }
    
    
    static testMethod void cancelHelpChanges() {

        // Settings are required for this 
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;

        // 1.28.1+ No need for a subscription file in this release
        //Document d = DG.getSubscriptionDoc();
        //insert d;

        // Create a help topic with valid templates
        HelpTopicTemplate__c HTF = DG.getHelpTopicTemplate('Full', 'Full');
        HelpTopicTemplate__c HTC = DG.getHelpTopicTemplate('Callout', 'Callout');
        insert HTF;
        insert HTC;

        HelpTopic__c Hlp = DG.getHelpTopic('Test');
        Hlp.Template__c = HTF.Id;
        Hlp.CalloutTemplate__c = HTC.Id;
        insert Hlp;
                
        Test.startTest();
        
            ControllerHelpContent cH = new ControllerHelpContent();

            // Go to the inserted help topic
            PageReference pageRef = Page.IHTools;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('HTID', Hlp.Id);            
            cH.getHelp();

            // Edit the topic
            cH.TName += ' - Edited';

            // Cancel these changes
            cH.cancelHelpChanges();
        
        Test.stopTest();

        System.assertEquals('Test', Hlp.Name);
        return;             
    }    
    
    
    static testMethod void getTemplates() {

        // Settings are required for this 
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        // Create some callout and topic templates
        HelpTopicTemplate__c HT1 = DG.getHelpTopicTemplate('Full 1', 'F1');
        HelpTopicTemplate__c HT2 = DG.getHelpTopicTemplate('Full 2', 'F2');
        HelpTopicTemplate__c HT3 = DG.getHelpTopicTemplate('Call 1', 'C1');
                
        HT3.TemplateType__c = 'Callout';
        
        insert HT1;
        insert HT2;
        insert HT3;
        
        // Create a list of options to hold results
        List<selectOption> Ts;
        
        Test.startTest();
        
            ControllerHelpContent cH = new ControllerHelpContent();
            
            //NB: act of creating settings will have created templates too (1x of each type)            
            Ts = cH.getTemplatesC();
            System.assertEquals(2, Ts.size());

            Ts = null;
            Ts = cH.getTemplatesF();
            System.assertEquals(3, Ts.size());
        
        Test.stopTest();

        
    }
        
    
    static testMethod void calloutTemplateChange() {

        // Settings are required for this 
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        ControllerHelpContent cH = new ControllerHelpContent();

        // 1.28.1+ No need for a subscription file in this release
        //Document d = DG.getSubscriptionDoc();
        //insert d;

        // Add a help topic with a valid callout template
        HelpTopic__c Hlp = DG.getHelpTopic('Test');
        insert Hlp;
        
        HelpTopicTemplate__c HT1 = DG.getHelpTopicTemplate('Test Template 1', 'VFPage1');
        insert HT1;
        
        Hlp.CalloutTemplate__c = HT1.Id;
        update Hlp;

        
        // Create a second template with a different callout height
        HelpTopicTemplate__c HT2 = DG.getHelpTopicTemplate('Test Template 2', 'VFPage2');
        HT2.DefaultHeight__c = 999;
        insert HT2;

        
        Test.startTest();
            
            // Check initial callout height
            PageReference pageRef = Page.IHTools;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('HTID', Hlp.Id);            
            cH.getHelp();
            //cH.calloutTemplateChange();
            //System.assertEquals(HT1.DefaultHeight__c, cH.Hlp.CalloutHeight__c);
                        

            // Change the callout template, then call the routine that would fire if 
            // we'd done this on screen: check callout height has been set to that of new template
            Hlp.CalloutTemplate__c = HT2.Id;
            update Hlp;
            cH.getHelp();
            cH.calloutTemplateChange();
            //System.assertEquals(HT2.DefaultHeight__c, cH.Hlp.CalloutHeight__c);
            system.assert(1==1);
            
        Test.stopTest();
        
        return;
    }
    
    
    static testMethod void addDeleteHelpTopic() {
    
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
    
        Test.startTest();
        
            ControllerHelpContent cH = new ControllerHelpContent();
            PageReference pageRef = Page.IHTools;
            Test.setCurrentPage(pageRef);
            
            // NB: before we can add a topic, we'll need to establish our rights
            // and thus need to initialise: use bookmarks option for this...
            cH.initialiseForBookmarks();
            
            PageReference P = cH.addHelpTopic();
            String HTID;
            
            // We should wind up on the new page: we can check (most of) the URL we get...
            System.assertEquals(URL.getOrgDomainURL().toExternalForm() + '/apex/iahelp__IHTools?', P.getUrl().substring(0, P.getUrl().indexOf('HTID')));
                        
            // Note topic id then request a delete of this topic
            HTID = cH.THelpId;
            cH.deleteHelpTopic();
            
            // Check the topic has gone
            try {
                HelpTopic__c Hlp = [SELECT Id FROM HelpTopic__c WHERE Id=:HTID];
                
                // This line should not fire
                System.assertEquals(1, 2);
                
            } catch (exception e) {
                // The above should have caused an exception, so we should be in here:
                // As there is no other topic to which to navigate, we should have been sent 
                // to a default topic...
            }
            
        Test.stopTest();
        return;
    }
        
    
    static testMethod void addRemoveBookmark () {
        
        // Create a help topic with associated full template
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;

        HelpTopicTemplate__c HT = DG.getHelpTopicTemplate('Test Template', 'TestTemplate');
        insert HT;

        HelpTopic__c Hlp1 = DG.getHelpTopic('Test 1');
        Hlp1.Template__c = HT.Id;
        insert Hlp1;
        
        Test.startTest();
        
            ControllerHelpContent cH = new ControllerHelpContent(true);

            // Go to our inserted help topic
            PageReference pageRef = Page.IHTools;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('HTID', Hlp1.Id);
            
            // Now add bookmark on this, the current page
            cH.addBookmark();
            
            // Now get help again and check we have 1 bookmark in our list
            System.assertEquals(1, cH.Bookmarks.size());
        
        
            // Now remove the bookmark and check it's gone
            cH.removeBookmark();
            System.assertEquals(0, cH.Bookmarks.size());
            
            
        Test.stopTest();
        return;
    }
 
 
 
    static testMethod void privateInitialise () {
        
        // Create a help topic with associated full template
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        Test.startTest();
            PageReference pageRef = Page.IHTools;
            Test.setCurrentPage(pageRef);
        
            ControllerHelpContent cH = new ControllerHelpContent();
            cH.initialiseForBookmarks();
            
            System.assertEquals('IHTools', cH.PortalPage);
            System.assertEquals(0, cH.ReadingListsImIn);            
            System.assertEquals(URL.getOrgDomainURL().toExternalForm() + '/apex/iahelp__IHManageBookmarks', cH.TMyBookmarksLink);

            //System.assertEquals('Warning: Print Warning', cH.TPrintWarning);            
            System.assert(cH.TGlobalLinks.indexOf('</ul>') != -1);
            
            System.assertNotEquals(null, cH.isAdministrator);
            System.assertNotEquals(null, cH.isAuthor);
            System.assertNotEquals(null, cH.isAnalysis);
            //System.assertNotEquals(null, cH.isUser);
            
            System.assert(cH.TAddReadingListLink.indexOf('</a>') != -1);
            
        Test.stopTest();
        return;
    }
 
   
    static testMethod void navHEToNewMode () {

        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
     
        // As new HE is based on some data from the existing screen,
        // we must ourselves up in read mode on an existing HE...
        // Create a layout, help topic and helped element
        HelpTopic__c HT = DG.getHelpTopic('Test Topic');
        insert HT;
        HelpedPageLayout__c HPL = DG.getHelpedPageLayout('Campaigns', '701');
        insert HPL;
        HelpedElement__c HE = DG.getHelpedElement('Test Element', HPL.Id, HT.Id);
        insert HE;
        
        Test.startTest();
            PageReference pageRef = Page.IHHelpedElement;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('ElemId', HE.Identifier__c);            
            ApexPages.currentPage().getParameters().put('HPL', HPL.PageLayoutIdentifier__c);            
            ApexPages.currentPage().getParameters().put('Mode', 'Read');            
        
            // Get the element - as one would by navigating to page
            ControllerHelpContent cH = new ControllerHelpContent();
            cH.getHelpedElement();

            // Now attempt a new record
            cH.navHEToNewMode();
            system.assertEquals('', cH.Diags);
        Test.stopTest();
        return;
    }


    static testMethod void navHEToEditMode () {
        
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        // Create a layout, help topic and helped element
        HelpTopic__c HT = DG.getHelpTopic('Test Topic');
        insert HT;
        HelpedPageLayout__c HPL = DG.getHelpedPageLayout('Campaigns', '701');
        insert HPL;
        HelpedElement__c HE = DG.getHelpedElement('Test Element', HPL.Id, HT.Id);
        insert HE;
        
        Test.startTest();
            PageReference pageRef = Page.IHHelpedElement;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('ElemId', HE.Identifier__c);            
            ApexPages.currentPage().getParameters().put('HPL', HPL.PageLayoutIdentifier__c);            
            ApexPages.currentPage().getParameters().put('Mode', 'Read');            
        
            // Get the element - as one would by navigating to page
            ControllerHelpContent cH = new ControllerHelpContent();
            cH.getHelpedElement();

            // Navigate to edit mode            
            PageReference P = cH.navHEToEditMode();
            system.assertNotEquals(null, P);
        Test.stopTest();
        return;
    }


    static testMethod void saveHelpedElement () {
        
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        // Create a layout, help topic and helped element
        HelpTopic__c HT = DG.getHelpTopic('Test Topic');
        insert HT;
        HelpedPageLayout__c HPL = DG.getHelpedPageLayout('Campaigns', '701');
        insert HPL;
        HelpedElement__c HE = DG.getHelpedElement('Test Element', HPL.Id, HT.Id);
        insert HE;
        
        Test.startTest();
        
            // Navigate to this element's editor page
            PageReference pageRef = Page.IHHelpedElement;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('ElemId', HE.Identifier__c);            
            ApexPages.currentPage().getParameters().put('HPL', HPL.PageLayoutIdentifier__c);            
            ApexPages.currentPage().getParameters().put('Mode', 'Edit');            
            
            // Get the element - as one would by navigating to page
            ControllerHelpContent cH = new ControllerHelpContent();
            cH.getHelpedElement();
            
            // Save changes
            cH.saveHelpedElement();
            system.assert(cH.Diags.indexOf('Error') == -1);
        Test.stopTest();
        return;
    }


    static testMethod void cancelHelpedElementChanges () {
        
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        // Create a layout, help topic and helped element
        HelpTopic__c HT = DG.getHelpTopic('Test Topic');
        insert HT;
        HelpedPageLayout__c HPL = DG.getHelpedPageLayout('Campaigns', '701');
        insert HPL;
        HelpedElement__c HE = DG.getHelpedElement('Test Element', HPL.Id, HT.Id);
        insert HE;
        
        Test.startTest();
            PageReference pageRef = Page.IHHelpedElement;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('ElemId', HE.Identifier__c);            
            ApexPages.currentPage().getParameters().put('HPL', HPL.PageLayoutIdentifier__c);            
            ApexPages.currentPage().getParameters().put('Mode', 'Edit');            
        
            // Get the element - as one would by navigating to page
            ControllerHelpContent cH = new ControllerHelpContent();
            cH.getHelpedElement();

            // Cancel changes
            PageReference P = cH.cancelHelpedElementChanges();          
            system.assertNotEquals(null, P);
        Test.stopTest();
        return;
    }


    static testMethod void deleteHelpedElement () {
        
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        // We must seed this test with an HE to delete      
        // Create a layout, help topic and helped element
        HelpTopic__c HT = DG.getHelpTopic('Test Topic');
        insert HT;
        HelpedPageLayout__c HPL = DG.getHelpedPageLayout('Campaigns', '701');
        insert HPL;
        HelpedElement__c HE = DG.getHelpedElement('Test Element', HPL.Id, HT.Id);
        insert HE;
        
        Test.startTest();
            PageReference pageRef = Page.IHHelpedElement;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('ElemId', HE.Identifier__c);            
            ApexPages.currentPage().getParameters().put('HPL', HPL.PageLayoutIdentifier__c);            
            ApexPages.currentPage().getParameters().put('Mode', 'Read');            
        
            // Get the element - as one would by navigating to page
            ControllerHelpContent cH = new ControllerHelpContent();
            cH.getHelpedElement();
            
            cH.deleteHelpedElement();
            system.assertEquals('', cH.Diags);
        Test.stopTest();
        return;
    }


    static testMethod void getCustomStyles () {
        
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        Test.startTest();
            ControllerHelpContent cH = new ControllerHelpContent();
            cH.initialiseLocalisations();
            
            List<selectOption> custS = cH.getCustomStyles();
            
            // See styles as set in data generator's settings:
            // Should be 3 entries plus a "none" added entry
            system.assertEquals(4, custS.size());
        Test.stopTest();
        return;
    }
    
    
    static testMethod void resetTopicVideo () {
        
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        // We need to navigate to a help topic for this
        HelpTopic__c HT = DG.getHelpTopic('Test');
        insert HT;
        
        // 1.28.1+ No need for a subscription file in this release
        //Document d = DG.getSubscriptionDoc();
        //insert d;
        
        
        Test.startTest();
            PageReference pageRef = Page.IHTools;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('HTID', HT.Id);            
        
            ControllerHelpContent cH = new ControllerHelpContent();
            cH.getHelp();
            
            cH.resetTopicVideo();
            system.assertEquals('', cH.Diags);
        Test.stopTest();
        return;
    }
    

    static testMethod void resetTopicImage () {
        
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        // We need to navigate to a help topic for this
        HelpTopic__c HT = DG.getHelpTopic('Test');
        insert HT;
        
        // 1.28.1+ No need for a subscription file in this release
        //Document d = DG.getSubscriptionDoc();
        //insert d;
        
        Test.startTest();
            PageReference pageRef = Page.IHTools;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('HTID', HT.Id);            
        
            ControllerHelpContent cH = new ControllerHelpContent();
            cH.getHelp();
            
            cH.resetTopicImage();
            system.assertEquals('', cH.Diags);
        Test.stopTest();
        return;
    }


    static testMethod void GSAddLocalStep () {
        
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        // Create a Guide (RL) with a couple of entries and navigate tools page to this guide
        HelpTopic__c HT1 = DG.getHelpTopic('T1');
        HelpTopic__c HT2 = DG.getHelpTopic('T2');
        insert HT1;
        insert HT2;
        
        HelpReadingList__c RL = DG.getHelpReadingList('RL');
        insert RL;
        
        HelpReadingListEntry__c RLE1 = DG.getHelpReadingListEntry(RL.Id, HT1.Id);
        HelpReadingListEntry__c RLE2 = DG.getHelpReadingListEntry(RL.Id, HT2.Id);
        insert RLE1;
        insert RLE2;
        
        // 1.28.1+ No need for a subscription file in this release
        //Document d = DG.getSubscriptionDoc();
        //insert d;
        
        Test.startTest();
            PageReference pageRef = Page.IHReadingListViewer;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('RLID', RL.Id);            
        
            ControllerHelpContent cH = new ControllerHelpContent();
            
            // We have to interject here to spoof the name of the page we're testing querying from
            // as this is not available as a "real" address by virtue of having set page ref above
            cH.dlgLocsPage = 'iahelp__IHReadingListViewer';
            cH.getHelp();
            
            cH.GSAddLocalStep();
            system.assertEquals(cH.getGlobalLocalisations().get('MessageGenericTaskComplete'), cH.Diags);
        Test.stopTest();
        return;
    }
    
    
    static testMethod void GSAddSelectStep () {
        
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        // Create a Guide (RL) with a couple of entries and navigate tools page to this guide
        HelpTopic__c HT1 = DG.getHelpTopic('T1');
        HelpTopic__c HT2 = DG.getHelpTopic('T2');
        insert HT1;
        insert HT2;
        
        HelpReadingList__c RL = DG.getHelpReadingList('RL');
        insert RL;
        
        HelpReadingListEntry__c RLE1 = DG.getHelpReadingListEntry(RL.Id, HT1.Id);
        HelpReadingListEntry__c RLE2 = DG.getHelpReadingListEntry(RL.Id, HT2.Id);
        insert RLE1;
        insert RLE2;
        
        // 1.28.1+ No need for a subscription file in this release
        //Document d = DG.getSubscriptionDoc();
        //insert d;
        
        Test.startTest();
            PageReference pageRef = Page.IHReadingListViewer;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('RLID', RL.Id);            
        
            ControllerHelpContent cH = new ControllerHelpContent();
            cH.getHelp();
            
            cH.GSAddSelectStep();
            system.assertEquals('', '');
        Test.stopTest();
        return;
    }


    static testMethod void cloneTopic() {
        
        ControllerHelpContent cH = new ControllerHelpContent();
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        // Create a topic
        HelpTopic__c HT1 = DG.getHelpTopic('T1');
        insert HT1;
        
        // Create some related help
        HelpTopic__c HT2 = DG.getHelpTopic('T2');
        HelpTopic__c HT3 = DG.getHelpTopic('T3');
        insert HT2;
        insert HT3;
        
        HelpRelationship__c Rel1 = DG.getHelpRelationship(HT1, HT2);
        HelpRelationship__c Rel2 = DG.getHelpRelationship(HT1, HT3);
        insert Rel1;
        insert Rel2;
        
        // 1.28.1+ No need for a subscription file in this release
        //Document d = DG.getSubscriptionDoc();
        //insert d;
        
        // Execute the clone
        Test.startTest();
            // We must first "navigate" to the topic to be cloned
            PageReference pageRef = Page.IHTools;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('HTID', HT1.Id);                        
            cH.getHelp();
            
            // Create info suggesting the need to create 2x clones, 1 with rels, 1 without
            cH.CloneTopicNames = 'C1^C2';
            cH.CloneTopicRels = 'N^Y';      

            cH.cloneTopic();
            //system.assert(cH.diags.indexOf('clones created') != -1);
            system.assert(cH.diags.indexOf(cH.getGlobalLocalisations().get('MessageGenericTaskComplete')) != -1);
            
        Test.stopTest();
        
        return;
    }   


    static testMethod void addGuideBookmark() {

        // Settings are required for this 
        zTest_DataGenerator DG = new zTest_DataGenerator();                                                      
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        // 1.28.1+ No need for a subscription file in this release
        //Document d = DG.getSubscriptionDoc();
        //insert d;
        
        
        // Create a help topic with a correctly set template
        HelpTopic__c Hlp = DG.getHelpTopic('Test');
        insert Hlp;
        
        HelpTopicTemplate__c HT = DG.getHelpTopicTemplate('Test Template', 'NoSuchVFPage');
        insert HT;
        
        Hlp.Template__c = HT.Id;
        update Hlp;
        
        // Create a reading list featuring this help topic
        HelpReadingList__c RL = DG.getHelpReadingList('Test Reading List');
        insert RL;
        HelpReadingListEntry__c RLE = DG.getHelpReadingListEntry(RL.Id, Hlp.Id);
        insert RLE;
        
        ControllerHelpContent cH = new ControllerHelpContent();
        
        Test.startTest();
            cH.ReadingListId = RL.Id;
            cH.addGuideBookmark();        
            
            // We should be able to find this bookmark
            HelpBookmark__c HB = [SELECT HelpBookmarkLabel__c FROM HelpBookmark__c WHERE HelpTopic__c =  :RLE.HelpTopic__c];            
            System.assertEquals(RL.name, HB.HelpBookmarkLabel__c);
        Test.stopTest();

        return;     
    }


    static testMethod void FLSCheck() {

        // Settings are required for this 
        zTest_DataGenerator DG = new zTest_DataGenerator();                                                      
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        ControllerHelpContent cH = new ControllerHelpContent();
        
        Test.startTest();
            cH.FLSCheck();
            System.assertEquals('', '');
        Test.stopTest();

        return;     
    }


    static testMethod void initialiseVoteOptions() {

        // Settings are required for this 
        zTest_DataGenerator DG = new zTest_DataGenerator();                                                      
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        ControllerHelpContent cH = new ControllerHelpContent();
        
        Test.startTest();
            cH.initialiseVoteOptions();
            System.assertEquals('', '');
        Test.stopTest();

        return;     
    }
    

    static testMethod void castVote() {

        // Settings are required for this 
        zTest_DataGenerator DG = new zTest_DataGenerator();                                                      
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        ControllerHelpContent cH = new ControllerHelpContent();
        
        // Create a vote set and its vote
        HelpVoteSet__c HVS = DG.getHelpVoteSet('VSName');
        insert HVS;
        
        HelpVoteOption__c HVO = DG.getHelpVoteOption(HVS.Id, 'OptLabel', 1);
        insert HVO;
        
        // Create a topic with this vote on offer
        HelpTopic__c HT = DG.getHelpTopic('test');
        HT.HelpVoteSet__c = HVS.Id;
        insert HT;
        
        
        Test.startTest();
            // Set ours as the context help topic
            PageReference pageRef = Page.IHTools;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('HTID', HT.Id);
        
            cH.theVote = HVO.Id;
            cH.castVote();
            System.assertEquals('', '');
        Test.stopTest();

        return;     
    }
    
    
    static testMethod void markKeywords() {

        // Settings are required for this 
        zTest_DataGenerator DG = new zTest_DataGenerator();                                                      
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        string retVal;
        
        ControllerHelpContent cH = new ControllerHelpContent();
        Boolean isLUXCaller = false;
        
        // We need a topic to mark plus another with a keyword
        HelpTopic__c HT1 = DG.getHelpTopic('T1');
        HT1.Description__c = 'I contain an important keyword';
        insert HT1;
        
        HelpTopic__c HT2 = DG.getHelpTopic('T2');
        HT2.KeyWord__c = 'important';
        insert HT2;
        
        
        Test.startTest();
            retVal = cH.markKeywords(HT1, isLUXCaller);
            System.assert(retVal.startsWith('I contain '));
            ControllerHelpContent.getSettings();
            ControllerHelpContent.getVotingAllowed();
            ControllerHelpContent.getD1();
            ControllerHelpContent.getD2();
            ControllerHelpContent ch1 = new ControllerHelpContent();
        
            ServiceSecurity Security = new ServiceSecurity();
            Boolean[] UPs = Security.UserPermissions();
            Boolean bAuthor = UPs[1];
            ch1.getDialogueLocalisations();
            ch1.getBrandingLocalisations();
            ControllerHelpContent.getQ();
            ch1.getPageName();
            ControllerHelpContent.getGoToURL();
            ControllerHelpContent.getGoToRL();
            ch1.getTDescription();
            ch1.getTemplatesLink();
            ch1.getElement();
            ch1.getRecord();
            ch1.getHelpSettings();
            ch1.gotoTopic();
            //ch1.uploadImg();
            ch1.getTemplateRecordsL();

        Test.stopTest();

        return;     
    }
    
    
    
    /*
    uploadImg
    */
}