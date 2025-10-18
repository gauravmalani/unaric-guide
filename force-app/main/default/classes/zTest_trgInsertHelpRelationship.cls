@isTest

/////////////////////////////////////////////////////////////////////////////////////////////////////
// TEST CASES FOR THE INSERT HELP RELATIONSHIP TRIGGER (trgInsertHelpRelationship)
//
// Martin Little for Improved Apps
// December 2014
/////////////////////////////////////////////////////////////////////////////////////////////////////


private class zTest_trgInsertHelpRelationship {

    static testMethod void BeforeInsert() {
        
        zTest_DataGenerator DG = new zTest_DataGenerator();
        
        // Insert 2x topics
        HelpTopic__c HT1 = DG.getHelpTopic('T1');
        HelpTopic__c HT2 = DG.getHelpTopic('T2');
        insert HT1;
        insert HT2;
        
        // Attempt 2x relationships
        Test.startTest();
            // Topic cannot be related to itself
            try {
                HelpRelationship__c HR1 = DG.getHelpRelationship(HT1, HT1);
                insert HR1;             
            } catch (exception e){
                system.assert(e.getMessage().indexOf('Topics cannot be related to themselves') != -1);
            }
            
            // No duplicate relationships
            try {
                HelpRelationship__c HR2 = DG.getHelpRelationship(HT1, HT2);
                insert HR2;             

                HelpRelationship__c HR3 = DG.getHelpRelationship(HT2, HT1);
                insert HR3;             

            } catch (exception e){
                system.assert(e.getMessage().indexOf('are already related') != -1);
            }

        Test.stopTest();
        
        return;
    }
}