@isTest

/////////////////////////////////////////////////////////////////////////////////////////////////////
// TEST CASES FOR THE HELP READING LIST ENTRY DELETE TRIGGER (trgDeleteHelpReadingListEntry)
//
// Martin Little for Improved Apps
// January 2015
/////////////////////////////////////////////////////////////////////////////////////////////////////


private class zTest_trgDeleteHelpReadingListEntry {

    static testMethod void BeforeDelete() {
        
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        // We want to test renumbering of RLEs: 
        // Create HTs
        HelpTopic__c HT1 = DG.getHelpTopic('HT1');
        insert HT1;

        HelpTopic__c HT2 = DG.getHelpTopic('HT2');
        insert HT2;

        HelpTopic__c HT3 = DG.getHelpTopic('HT3');
        insert HT3;
        
        
        // Create RL with required RLEs
        HelpReadingList__c RL1 = DG.getHelpReadingList('RL1');
        insert RL1;
        
        HelpReadingListEntry__c RLE1 = DG.getHelpReadingListEntry(RL1.Id, HT1.Id);
        RLE1.ReadingOrder__c = 0;
        insert RLE1;

        HelpReadingListEntry__c RLE2 = DG.getHelpReadingListEntry(RL1.Id, HT2.Id);
        RLE2.ReadingOrder__c = 1;
        insert RLE2;

        HelpReadingListEntry__c RLE3 = DG.getHelpReadingListEntry(RL1.Id, HT3.Id);
        RLE3.ReadingOrder__c = 2;
        insert RLE3;
        
        Test.startTest();
            // Delete 2nd entry and check 3rd -> 2nd
            delete RLE2;
            try {
                HelpReadingListEntry__c RLETest = [SELECT Id, ReadingOrder__c FROM HelpReadingListEntry__c WHERE Id = :RLE3.Id];
                // If we reach here, we failed:
                system.assertEquals(1, RLETest.ReadingOrder__c);
                                
            } catch (exception e) {
                // We should not reach here
                system.assert(1==2);
            }
            
            
        Test.stopTest();
        
    }
}