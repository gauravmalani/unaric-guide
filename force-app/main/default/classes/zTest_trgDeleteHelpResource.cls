@isTest

/////////////////////////////////////////////////////////////////////////////////////////////////////
// TEST CASES FOR THE DELETE RESOURCE TRIGGER (trgDeleteHelpResource)
//
// Martin Little for Improved Apps
// September 2013
/////////////////////////////////////////////////////////////////////////////////////////////////////


private class zTest_trgDeleteHelpResource {

    static testMethod void BeforeDelete() {
        
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        // Create a topic
        HelpTopic__c HT = DG.getHelpTopic('Test');
        insert HT;
        
        // Create a resource
        HelpResource__c HR = DG.getHelpResource('Test');
        insert HR;
        
        // Create a topic resource
        HelpTopicResource__c HTR = DG.getHelpTopicResource(HR, HT);
        insert HTR;
        
        Test.startTest();
        
            
            try {
                // Seek the topic resource
                HTR = [SELECT Id FROM HelpTopicResource__c WHERE HelpResource__c =:HR.Id AND HelpTopic__c = :HT.Id];
                
                // We SHOULD end up here as the record exists
                // so continue...
                
            } catch (exception e) {
                system.assertEquals(1, 2);
            }
            
            try {
                // Delete the resource
                delete HR;

                // Seek the topic resource again
                HTR = [SELECT Id FROM HelpTopicResource__c WHERE HelpResource__c =:HR.Id AND HelpTopic__c = :HT.Id];
                
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