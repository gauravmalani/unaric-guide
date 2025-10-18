@isTest

/////////////////////////////////////////////////////////////////////////////////////////////////////
// TEST CASES FOR THE READING LIST ENTRY INSERT TRIGGER (trgInsertHelpReadingListEntry)
//
// Martin Little for Improved Apps
// September 2013
/////////////////////////////////////////////////////////////////////////////////////////////////////


private class zTest_trgInsertHelpReadingListEntry {

    static testMethod void BeforeInsert() {
        
        zTest_DataGenerator DG = new zTest_DataGenerator();
        
        Test.startTest();
            // Create 1x HT, 1x RL
            HelpTopic__c HT = DG.getHelpTopic('HT');
            insert HT;
            
            HelpReadingList__c RL = DG.getHelpReadingList('RL');
            insert RL;
            
            // Create RLE for HT
            HelpReadingListEntry__c RLE1 = DG.getHelpReadingListEntry(RL.Id, HT.Id);
            insert RLE1;
            
            // Attempt a duplicate RLE
            HelpReadingListEntry__c RLE2 = DG.getHelpReadingListEntry(RL.Id, HT.Id);
            try {
                insert RLE2;
            } catch (exception e) {
                system.assert(e.getMessage().indexOf('The selected Help Topic is already associated with this Reading List') != -1);
            }
            
        Test.stopTest();
        
        return;
    }
}