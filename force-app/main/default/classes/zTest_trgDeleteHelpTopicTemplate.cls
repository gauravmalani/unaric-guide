@isTest

/////////////////////////////////////////////////////////////////////////////////////////////////////
// TEST CASES FOR THE DELETE TEMPLATE TRIGGER (trgDeleteHelpTopicTemplate)
//
// Martin Little for Improved Apps
// September 2013
/////////////////////////////////////////////////////////////////////////////////////////////////////


private class zTest_trgDeleteHelpTopicTemplate {

    static testMethod void BeforeDelete() {
        
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        // Create a full template
        HelpTopicTemplate__c TF = DG.getHelpTopicTemplate('TestFull', 'TemplateFull');
        TF.TemplateType__c = 'Full Topic';
        insert TF;

        // Create a topic that uses this as template
        HelpTopic__c HTF = DG.getHelpTopic('TopicFull');
        HTF.Template__c = TF.Id;
        insert HTF;
        
        // Create a callout template
        HelpTopicTemplate__c TC = DG.getHelpTopicTemplate('TestCall', 'TemplateCall');
        TC.TemplateType__c = 'Callout';
        insert TC;

        // Create a topic that uses this as callout
        HelpTopic__c HTC = DG.getHelpTopic('TopicCall');
        HTC.CalloutTemplate__c = TC.Id;
        insert HTC;
                
        Test.startTest();
            
            // Attempt to delete template full
            try {
                delete TF;              
                // Should not wind up here - fail
                system.assertEquals(1, 2);
                
            } catch (exception e) {
                // Should wind up in here - continue
            }
            
            
            // Delete the relevant topic and try again
            try {
                delete HTF;
                delete TF;
            } catch (exception e) {
                // Should NOT now wind up here - fail
                system.assertEquals(1, 3);
                
            }


            // Attempt to delete template callout
            try {
                delete TC;              
                // Should not wind up here - fail
                system.assertEquals(1, 4);
                
            } catch (exception e) {
                // Should wind up in here - continue
            }
            
            
            // Delete the relevant topic and try again
            try {
                delete HTC;
                delete TC;
            } catch (exception e) {
                // Should NOT now wind up here - fail
                system.assertEquals(1, 5);
                
            }
            
        Test.stopTest();
        
        return;
    }
}