@isTest

/////////////////////////////////////////////////////////////////////////////////////////////////////
// TEST CASES FOR THE HELP TOPIC DELETE TRIGGER (trgDeleteHelpTopic)
//
// Martin Little for Improved Apps
// September 2013
/////////////////////////////////////////////////////////////////////////////////////////////////////


private class zTest_trgDeleteHelpTopic {

    static testMethod void BeforeDelete() {
        
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        // Create a topic
        HelpTopic__c HT = DG.getHelpTopic('Test');
        insert HT;
        
        // Create a bookmark
        HelpBookmark__c HB = DG.getHelpBookmark(HT.Id);
        insert HB;
                
        Test.startTest();
        
            
            try {
                // Seek the bookmark
                HB = [SELECT Id FROM HelpBookmark__c WHERE HelpTopic__c = :HT.Id];
                
                // We SHOULD end up here as the record exists
                // so continue...
                
            } catch (exception e) {
                system.assertEquals(1, 2);
            }
            
            try {
                // Delete the help topic
                delete HT;

                // Seek the bookmark again
                HB = [SELECT Id FROM HelpBookmark__c WHERE HelpTopic__c = :HT.Id];
                
                // We should NOT end up here as the record should NOT exist
                // so fail if we do
                system.assertEquals(1, 3);
                
            } catch (exception e) {
                system.assertEquals(1, 1);
            }
            

        Test.stopTest();
        
        return;
    }

}