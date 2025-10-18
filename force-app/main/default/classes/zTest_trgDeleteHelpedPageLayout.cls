@isTest

/////////////////////////////////////////////////////////////////////////////////////////////////////
// TEST CASES FOR THE HELPED PAGE LAYOUT DELETE TRIGGER (trgDeleteHelpedPageLayout)
//
// Martin Little for Improved Apps
// September 2013
/////////////////////////////////////////////////////////////////////////////////////////////////////


private class zTest_trgDeleteHelpedPageLayout {

    static testMethod void BeforeDelete() {
        
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        // Create a topic
        HelpTopic__c HT = DG.getHelpTopic('Test');
        insert HT;
        
        // Create a layout
        HelpedPageLayout__c HPL = DG.getHelpedPageLayout('TestL', '001');
        insert HPL;
        
        // Create a helped element
        HelpedElement__c HE = DG.getHelpedElement('Field0', HPL.Id, HT.Id);
        insert HE;
        
        // Set the topic to use the above layout as its guided layout
        HT.GuidedLayout__c = HPL.Id;
        upsert HT;
        
        Test.startTest();
        
            
            try {
                // Seek the element
                HE = [SELECT Id FROM HelpedElement__c WHERE Identifier__c ='Field0'];
                
                // We SHOULD end up here as the element exists
                // so continue...
                
            } catch (exception e) {
                system.assertEquals(1, 2);
            }
            
            try {
                // Delete the layout
                delete HPL;

                // Seek the element again
                HE = [SELECT Id FROM HelpedElement__c WHERE Identifier__c ='Field0'];
                
                // We should NOT end up here as the element should NOT exist
                // so fail if we do
                system.assertEquals(1, 3);
                
            } catch (exception e) {
                system.assertEquals(1, 1);
            }
            
            // Help Topic's guided layout should have been blanked out by the trigger as layout no longer exists
            //system.assertEquals(null, HT.GuidedLayout__c);

        Test.stopTest();
        
        return;
    }

}