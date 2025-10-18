@isTest
 
/////////////////////////////////////////////////////////////////////////////////////////////////////
// TEST CASES FOR CLASS ControllerRListInfo
// SEE ALSO zTest_ControllerRListInfoReports
//
// Martin Little for Improved Apps
// October 2012
/////////////////////////////////////////////////////////////////////////////////////////////////////


private class zTest_ControllerRListInfo {
    
    
    // Test that lack of query string on controller fails gracefully
    static testMethod void getReadingListNoQry() {

        // Settings are required for this 
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;

        Test.startTest();
        
            ControllerRListInfo RLIC = new ControllerRListInfo();
            RLIC.getReadingList();
            ControllerRListInfo.getBrandCSS();
            RLIC.getDialogueLocalisations();
            RLIC.getBrandingLocalisations();
            ControllerRListInfo.getEnableExportDoc();
            RLIC.viewHistory();
        
        Test.stopTest();

        System.assertEquals(RLIC.getGlobalLocalisations().get('MessageGenericError'), RLIC.getRList().ListName);
        
        return;
    }
        
    
    // Test getting reading list with a valid list ID
    static testMethod void getReadingList() {
        
        // Settings are required for this 
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;

        HelpReadingList__c RL = DG.getHelpReadingList('Test Reading List');
        insert RL;
        
        PageReference pageRef = Page.IHReadingListProperties;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('RLIST', RL.Id);
        
        Test.startTest();
        
            ControllerRListInfo RLIC = new ControllerRListInfo();
            RLIC.getReadingList();
        
        Test.stopTest();
        
        System.assertEquals('', RLIC.Diags);
        //System.assertEquals('Test Reading List', RLIC.getRList().ListName);
        
        
        return;
    } 


    static testMethod void createAndLink() {

        // Settings are required for this 
        zTest_DataGenerator DG = new zTest_DataGenerator();                                                      
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        
        // Create a help topic 
        HelpTopic__c Hlp = DG.getHelpTopic('Test');
        insert Hlp;
        
        // And a reading list
        HelpReadingList__c HRL = DG.getHelpReadingList('Test Reading List');

        Test.startTest();
        
            
            // We need to specify help topic via URL and also manually set the reading list to use
            // (usually a function of SF extension consrtructor)
            PageReference pageRef = Page.IHReadingListProperties;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('HTID', Hlp.Id);            
            ApexPages.currentPage().getParameters().put('Mode', 'NEW');            

            ControllerRListInfo RLIC = new ControllerRListInfo(new ApexPages.Standardcontroller(HRL));

            RLIC.createAndLink();
            
            System.assertEquals('New Reading List created containing the current Help Topic', RLIC.Diags);
            
        Test.stopTest();
        return;     
    }


    static testMethod void createAndNew() {

        // Settings are required for this 
        zTest_DataGenerator DG = new zTest_DataGenerator();                                                      
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        
        // Create a help topic 
        HelpTopic__c Hlp = DG.getHelpTopic('Test');
        insert Hlp;
        
        // And a reading list
        HelpReadingList__c HRL = DG.getHelpReadingList('Test Reading List');
        

        Test.startTest();
        
            
            // We need to specify help topic via URL and also manually set the reading list to use
            // (usually a function of SF extension consrtructor)
            PageReference pageRef = Page.IHReadingListProperties;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('Mode', 'NEW');            

            ControllerRListInfo RLIC = new ControllerRListInfo(new ApexPages.Standardcontroller(HRL));

            // We'll need to set help topic name and summary, as they would be on the form...
            RLIC.fld1 = 'Topic Name';
            RLIC.fld2 = 'Topic Summary';
            RLIC.createAndNew();            
            System.assertEquals('New Reading List and Topic created', RLIC.Diags.substring(0, 34));
            
        Test.stopTest();
        return;     
    }


    static testMethod void saveReadingList() {
        
        // Settings are required for this 
        zTest_DataGenerator DG = new zTest_DataGenerator();                                                      
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        
        // Create a help topic 
        HelpTopic__c Hlp = DG.getHelpTopic('Test');
        insert Hlp;
        
        // And a reading list
        HelpReadingList__c HRL = DG.getHelpReadingList('Test Reading List');
        insert HRL;
        

        Test.startTest();
        
            
            // We need to specify help topic via URL and also manually set the reading list to use
            // (usually a function of SF extension consrtructor)
            PageReference pageRef = Page.IHReadingListProperties;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('HTID', Hlp.Id);            
            ApexPages.currentPage().getParameters().put('Mode', 'EDIT');            

            ControllerRListInfo RLIC = new ControllerRListInfo(new ApexPages.Standardcontroller(HRL));

            // Amend the reading list, then save it
            HRL.Name = 'Amended RL';
            RLIC.saveReadingList();
            
            System.assertEquals('Changes saved', RLIC.Diags);
            
        Test.stopTest();
        return;     
    }
    
    
    static testMethod void deleteReadingList() {
        
        // Settings are required for this 
        zTest_DataGenerator DG = new zTest_DataGenerator();                                                      
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        
        // Create a help topic 
        HelpTopic__c Hlp = DG.getHelpTopic('Test');
        insert Hlp;
        
        // And a reading list
        HelpReadingList__c HRL = DG.getHelpReadingList('Test Reading List');
        insert HRL;
        

        Test.startTest();
        
            // We need to specify help topic via URL and also manually set the reading list to use
            // (usually a function of SF extension consrtructor)
            PageReference pageRef = Page.IHReadingListProperties;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('HTID', Hlp.Id);            
            ApexPages.currentPage().getParameters().put('Mode', 'EDIT');            

            ControllerRListInfo RLIC = new ControllerRListInfo(new ApexPages.Standardcontroller(HRL));

            // Delete the reading list
            RLIC.deleteReadingList();            
           // System.assertEquals('', RLIC.Diags);


            // And a guide type reading list
            HRL = DG.getHelpReadingList('Test Reading List');
            HRL.ReadingListType__c = 'Linear Guide';
            insert HRL;

            HelpReadingListEntry__c RLE = DG.getHelpReadingListEntry(HRL.Id, Hlp.Id);
            insert RLE;

            pageRef = Page.IHReadingListProperties;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('HTID', Hlp.Id);            
            ApexPages.currentPage().getParameters().put('Mode', 'EDIT');            

            RLIC = new ControllerRListInfo(new ApexPages.Standardcontroller(HRL));
            RLIC.deleteReadingList();            
            System.assertEquals(-1, RLIC.Diags.toUpperCase().indexOf('ERROR'));
            
        Test.stopTest();
        return;     
    }
    
    

    static testMethod void backToSFAndNavModes() {
        
        // Settings are required for this 
        zTest_DataGenerator DG = new zTest_DataGenerator();                                                      
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        
        // Create a help topic 
        HelpTopic__c Hlp = DG.getHelpTopic('Test');
        insert Hlp;
        
        // And a reading list
        HelpReadingList__c HRL = DG.getHelpReadingList('Test Reading List');
        insert HRL;
        
        // Note RL Id
        String RLID = HRL.Id;

        Test.startTest();
        
            
            // We need to specify help topic via URL and also manually set the reading list to use
            // (usually a function of SF extension consrtructor)
            PageReference pageRef = Page.IHReadingListProperties;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('HTID', Hlp.Id);            
            ApexPages.currentPage().getParameters().put('Mode', 'EDIT');            

            ControllerRListInfo RLIC = new ControllerRListInfo(new ApexPages.Standardcontroller(HRL));

            // Attempt to return to SF and check we are given a suitable page ref
            pageRef = RLIC.backToSF();
            System.assertEquals(URL.getOrgDomainURL().toExternalForm() + '/' + RLID.substring(0,3), pageRef.getUrl());

            pageRef = RLIC.navToAddMode();
            pageRef = RLIC.navToEditMode();
            pageRef = RLIC.cancelReadingListChanges();
            
        Test.stopTest();
        return;     
    }
     
    
}