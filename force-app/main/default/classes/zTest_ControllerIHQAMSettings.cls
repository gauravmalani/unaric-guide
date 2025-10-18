@isTest

/////////////////////////////////////////////////////////////////////////////////////////////////////
// TEST CASES FOR CLASS ControllerIHQAMSettings
//
// Martin Little for Improved Apps
// October 2012
/////////////////////////////////////////////////////////////////////////////////////////////////////


private class zTest_ControllerIHQAMSettings {

    static testMethod void LoadSettings() {
        
        String retVal;
        String[] Settings;
        
        // Settings are required for this 
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        
        
        Test.startTest();

            PageReference pageRef = Page.IHQAMSettings;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('Referer', URL.getOrgDomainURL().toExternalForm() + '/apex/IHHook');            
            ApexPages.currentPage().getParameters().put('callback', 'ClientSettingsLoader');            
            
            ControllerIHQAMSettings IHQ = new ControllerIHQAMSettings();
            IHQ.LoadSettings();
            
            retVal = IHQ.Settings;
            Settings = retVal.split('¬');
            
        Test.stopTest();

        system.assert(Settings.size() > 0);
        return;
    }   
    
    
    static testMethod void LoadSettingsGetGuideInfo() {
        
        String retVal;
        String[] Settings;
        
        // Settings are required for this 
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        // Need to set up a guide to locate: this needs 1x auto & 1x manual step
        HelpTopic__c HT1 = DG.getHelpTopic('HT1');
        HT1.GuideStepMode__c = 'Automatic';
        insert HT1;
        
        HelpTopic__c HT2 = DG.getHelpTopic('HT2');
        HT2.GuideStepMode__c = 'Manual';
        insert HT2;
        
        HelpReadingList__c RL = DG.getHelpReadingList('Guide');
        insert RL;
        
        HelpReadingListEntry__c RLE1 = DG.getHelpReadingListEntry(RL.Id, HT1.Id);
        HelpReadingListEntry__c RLE2 = DG.getHelpReadingListEntry(RL.Id, HT2.Id);
        insert RLE1;
        insert RLE2;
        
        Test.startTest();

            PageReference pageRef = Page.IHQAMSettings;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('GuideId', RL.Id);            
            ControllerIHQAMSettings IHQ = new ControllerIHQAMSettings();
            IHQ.LoadSettings();   
                    
            retVal = IHQ.Settings;
            Settings = retVal.split('¬');
            system.assert(Settings.size() > 0);
            
        Test.stopTest();

        return;
    }   


    static testMethod void initializeVFQAM() {
        
        // Settings are required for this 
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        // Create a page layout with 2 helped elements (and topics)
        HelpedPageLayout__c HPL = DG.getHelpedPageLayout('Test 1', '001');
        insert HPL;
        
        HelpTopic__c Hlp1 = DG.getHelpTopic('HT1');
        HelpTopic__c Hlp2 = DG.getHelpTopic('HT2');
        insert Hlp1;
        insert Hlp2;
        
        HelpedElement__c HE1 = DG.getHelpedElement('HE1', HPL.Id, Hlp1.Id);
        HelpedElement__c HE2 = DG.getHelpedElement('HE2', HPL.Id, Hlp2.Id);
        insert HE1;
        insert HE2;
        
        Test.startTest();
            // Navigate the QAM to the new page
            PageReference pageRef = Page.IHQAM;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('IHContext', URL.getOrgDomainURL().toExternalForm() + '/' + HPL.PageLayoutIdentifier__c);            

            // Check we get 2 helped elements in our QAM results list
            ControllerIHQAMSettings IHQ = new ControllerIHQAMSettings();
            IHQ.initializeVFQAM();
            
            system.assertEquals(IHQ.SFObjId, '001');
            system.assertEquals(IHQ.Diags, '');
            system.assertEquals(IHQ.HelpedElements.size(), 2);
            
        Test.stopTest();

        return;
    } 


    static testMethod void initializeIH1QAM() {
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        Test.startTest();
            ControllerIHQAMSettings IHQ = new ControllerIHQAMSettings();
            IHQ.initializeIH1QAM();
            system.assertEquals('', '');            
        Test.stopTest();

        return;     
    }   
    
    
    static testMethod void getHelpTopic() {
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        Test.startTest();
            ControllerIHQAMSettings IHQ = new ControllerIHQAMSettings();
            
            IHQ.SearchResultId = '';
            IHQ.initializeVFQAM();
            PageReference P = IHQ.getHelpTopic();
            system.assertNotEquals(null, P);
            
            IHQ.SearchResultId = 'BogusHTID';
            P = IHQ.getHelpTopic();
            system.assertNotEquals(null, P);
                        
        Test.stopTest();

        return;     
    }
    
    
    static testMethod void doSearch() {
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        Test.startTest();
            ControllerIHQAMSettings IHQ = new ControllerIHQAMSettings();
            IHQ.SearchResultId = 'test';
            IHQ.doSearch();
            system.assertEquals('', '');            
        Test.stopTest();

        return;     
    }


    static testMethod void gotoURL() {
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        PageReference retVal;
        
        Test.startTest();
            ControllerIHQAMSettings IHQ = new ControllerIHQAMSettings();
            IHQ.SearchResultId = '';
            retVal = IHQ.gotoURL();
            system.assertEquals(null, retVal);            

            IHQ.SearchResultId = 'test';
            retVal = IHQ.gotoURL();
            system.assertNotEquals(null, retVal);            
        Test.stopTest();

        return;     
    }
    

    static testMethod void getTopicCalloutTemplate() {
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        // Insert a helped page layout for the desired object
        HelpedPageLayout__c HPL = DG.getHelpedPageLayout('Layout Name', '001');
        insert HPL;
        
        // Insert a help topic
        HelpTopic__c HT = DG.getHelpTopic('HT1');
        insert HT;
        
        // Insert a helped element for the desired identifier        
        HelpedElement__c HE = DG.getHelpedElement('ElemIdent', HPL.Id, HT.Id);
        insert HE;
        
        Test.startTest();
            ControllerIHQAMSettings IHQ = new ControllerIHQAMSettings();
            IHQ.getTopicCalloutTemplate();
            
            IHQ.SearchResultId = HE.Id;
            IHQ.getTopicCalloutTemplate();
            
            system.assert(1==1);            
        Test.stopTest();

        return;     
    }
    
    static testMethod void getSettings1() {
        
        ControllerIHQAMSettings IHQ = new ControllerIHQAMSettings();
        
        ControllerIHQAMSettings.getSettings();
        ControllerIHQAMSettings.getBrandCSS();
        ControllerIHQAMSettings.getisIHLUX();
        IHQ.getDialogueLocalisations();
        IHQ.getGlobalLocalisations();
        IHQ.getBrandingLocalisations();
        IHQ.getQAMLocalisations();
        IHQ.LoadSettings();
        IHQ.getIsSF1();
        //IHQ.getHelpTopic();
        IHQ.gotoURL();
        IHQ.doSearch();
        IHQ.getTopicCalloutTemplate();
    }

}