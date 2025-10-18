@isTest(SeeAllData='true')

/////////////////////////////////////////////////////////////////////////////////////////////////////
// TEST CASES FOR CLASS ControllerRListInfo - REPORTS ONLY
// SEE ALSO zTest_ControllerRListInfo
//
// Martin Little for Improved Apps
// October 2012
/////////////////////////////////////////////////////////////////////////////////////////////////////


// THESE TESTS REQUIRE A SEPARATE CLASS IN ORDER TO ACCESS ALL DATA:
// THIS IS THE ONLY WAY TO GET VISIBILITY OF REPORT RECORDS

private class zTest_ControllerRListInfoReports {
    
    static testMethod void viewHistory() {
        
        ControllerRListInfo cR = new ControllerRListInfo();

        zTest_DataGenerator DG = new zTest_DataGenerator();
        
        //DO NOT ADD SETTINGS - AS IN SEEING ALL DATA THESE WILL EXIST                                                      
        //IASetIHOrg__c IASet = DG.getTestSettings();                                     
        //insert IASet;
        
        
        // Create a help topic 
        HelpTopic__c Hlp = DG.getHelpTopic('Test');
        insert Hlp;
        
        // And a reading list
        HelpReadingList__c HRL = DG.getHelpReadingList('Test Reading List');
        insert HRL;

        // And an entry
        HelpReadingListEntry__c RLE = DG.getHelpReadingListEntry(HRL.Id, Hlp.Id);
        insert RLE;
        
        // NB: REPORT CANNOT BE INSERTED - SO WE HAVE THE ALL DATA DIRECTIVE
        // TO ALLOW US TO SEE THE ACTUAL ONE!       
        
        Test.startTest();

            // Set controller to use this reading list: to do this, we need to "visit" the manage RL page...
            PageReference pageRef = Page.IHManageReadingList;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('RLIST', HRL.Id);                       
            cR.getReadingList();
            
            system.assertEquals(cR.Diags, '');
        
            PageReference P = cR.viewHistory();
            system.assertEquals('', cR.Diags);
        Test.stopTest();
        return;     
    }

}