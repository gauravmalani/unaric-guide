@isTest

/////////////////////////////////////////////////////////////////////////////////////////////////////
// TEST CASES FOR THE HELP TOPIC RESOURCE INSERT TRIGGER (trgInsertHelpTopicResource)
//
// Martin Little for Improved Apps
// September 2013
/////////////////////////////////////////////////////////////////////////////////////////////////////


private class zTest_trgInsertHelpTopicResource {

    static testMethod void BeforeInsert() {

        zTest_DataGenerator DG = new zTest_DataGenerator();

        Test.startTest();
            // Creation of 2x identical help topic resources should fire all lines of code
            HelpTopic__c HT = DG.getHelpTopic('TestTopic');
            insert HT;
            
            HelpResource__c HR = DG.getHelpResource('R1');
            insert HR;
            
            HelpTopicResource__c HTR1 = DG.getHelpTopicResource(HR, HT);
            insert HTR1;
            
            HelpTopicResource__c HTR2 = DG.getHelpTopicResource(HR, HT);
            try {
                insert HTR2;            
            } catch (exception e) {
                system.assert(e.getMessage().indexOf('The selected Help Resource is already associated with this Help Topic') != -1);
            }
        Test.stopTest();
        
        return;
    }
}