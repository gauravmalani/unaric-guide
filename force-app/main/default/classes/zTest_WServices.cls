@isTest

/////////////////////////////////////////////////////////////////////////////////////////////////////
// TEST CASES FOR CLASS WServices
//
// Martin Little for Improved Apps
// October 2012
/////////////////////////////////////////////////////////////////////////////////////////////////////


private class zTest_WServices {
    
    
    static testMethod void deleteHelpedElement() {

        // Create a mock help topic
        zTest_DataGenerator DG = new zTest_DataGenerator();
        HelpTopic__c Hlp1 = DG.getHelpTopic('Test');
        insert Hlp1;
        
        map<string, string> mapDlgLocs = ServiceLocalisation.getDialogueLocalisations('WServices', false); 
        
        // Create a page URL with which to associate elements
        String PageURL = URL.getOrgDomainURL().toExternalForm() + '/a01';
        
        // Create a mock helped page layout
        HelpedPageLayout__c HPL = DG.getHelpedPageLayout('Test Layout', 'a01');
        insert HPL;
        
        // Create a mock helped element associated with this topic and layout
        HelpedElement__c HE = DG.getHelpedElement('Test Helped Field Label', HPL.Id, Hlp1.Id);
        insert HE;

        String retVal;
        
        Test.startTest();
            retVal = WServices.deleteHelpedElement(HE.Id, PageURL);
        Test.stopTest();
        
        system.assertNotEquals(retVal.indexOf(mapDlgLocs.get('MessageDeletedHelpedElements')), -1);

        return;
    }
    
    
    static testMethod void createHelpTopic () {
        string retVal;
        
        Test.startTest();
        
            retVal = WServices.createHelpTopic('', '', '');
            system.assertNotEquals(retVal.indexOf('deprecated'), -1);
            
        Test.stopTest();    
        return;
        
    }
    
    
    static testMethod void createHelpedElement () {
        
        String retVal;
        // Settings are required for this 
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        // Create a page URL with which to associate elements
        String PageURL = URL.getOrgDomainURL().toExternalForm() + '/a01';
        
        // Create a helped page layout record for this URL
        HelpedPageLayout__c HPL = DG.getHelpedPageLayout('Test Layout', 'a01'); 
        insert HPL;
        
        // Create a help topic
        HelpTopic__c Hlp1 = DG.getHelpTopic('Test');
        insert Hlp1;
                
        Test.startTest();
        
            // Test creation when neither element nor topic exist
            retVal = WServices.createHelpedElement('Test field label 1', PageURL, 'Field', Hlp1.Id);
            system.assert(retVal.indexOf('created') != -1);
            
        Test.stopTest();    
        return;
    }
    

    static testMethod void upsertGuideStep () {
        
        String retVal;
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;

        map<string, string> mapDlgLocs = ServiceLocalisation.getDialogueLocalisations('WServices', false);
        
        // Create a new Guide
        HelpReadingList__c HRL = DG.getHelpReadingList('Test Guide');
        insert HRL;
        
        // Add one RLE
        HelpTopic__c HT = DG.getHelpTopic('Test Topic Step 0');
        insert HT;
        HelpReadingListEntry__c RLE = DG.getHelpReadingListEntry(HRL.Id, HT.Id);
        insert RLE;
        
        Test.startTest();
            // NB: call params are:
            // GuideId, RLEId, PgId, ElemId, ElemType, StepName, StepSummary, StepOrder
        
            // Check we can update an existing step
            //system.assert(retVal);
            
            // Check we handle creation of auto welcome steps
            retVal = WServices.upsertGuideStep(HRL.Id, 'IHAddedWelcome', '001', 'Test Field 1', 'Field', 'SName1', 'SSummary1', '1');
            system.assert(retVal.startsWith(mapDlgLocs.get('MessageAddedStepWelcome')));
            
            // Check we handle creation of auto step selection steps
            retVal = WServices.upsertGuideStep(HRL.Id, 'IHAddedSelect', '001', 'Test Field 2', 'Field', 'SName2', 'SSummary2', '2');
            system.assert(retVal.startsWith(mapDlgLocs.get('MessageAddedStepRecordSelection')));
            
            // Check we can add a completely new step
            retVal = WServices.upsertGuideStep(HRL.Id, 'NEWRLE', '001', 'Test Field 3', 'Field', 'SName3', 'SSummary3', '3');
            system.assert(retVal.startsWith(mapDlgLocs.get('MessageAddingStep')));
            
        Test.stopTest();    
        return;     
    }
    
    
    static testMethod void deleteGuideStep () {
        
        String retVal;
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        
        // Create a guide and a step (and topic)
        HelpTopic__c HT = DG.getHelpTopic('Test HT');
        insert HT;
        
        HelpReadingList__c RL = DG.getHelpReadingList('Test RL');
        insert RL;
        
        HelpReadingListEntry__c RLE = DG.getHelpReadingListEntry(RL.Id, HT.Id);
        insert RLE;
        
        Test.startTest();
            retVal = WServices.deleteGuideStep(RLE.Id);
            system.assertEquals('', retVal);
            
        Test.stopTest();    
        return;             
    }
    
 
     static testMethod void upsertGuideSteps () {
        
        String retVal;
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        // Create a new Guide
        HelpReadingList__c HRL = DG.getHelpReadingList('Test Guide');
        insert HRL;
        
        string[] RLEIds = new string[]{'*Test RLE'};
        string[] PgIds = new string[]{'001'};
        string[] ElemIds = new string[]{'Elem1'};
        string[] ElemTypes = new string[]{'Field'};
        string[] StepNames = new string[]{'Step1'};
        string[] StepSummaries = new string[]{'Step1 Sum'};
        string[] StepOrders = new string[]{'0'};
                
        Test.startTest();
            // NB: call params are:
            // GuideId, RLEIds, PgIds, ElemIds, ElemTypes, StepNames, StepSummaries, StepOrders                 
            retVal = WServices.upsertGuideSteps(HRL.Id, RLEIds, PgIds, ElemIds, ElemTypes, StepNames, StepSummaries, StepOrders);
            system.assert(retVal.indexOf('Error') == -1);
            WRestServices.getHelpSettings();
            HelpTopic__c HT = DG.getHelpTopic('T1');
            insert HT;
            WRestServices.getHelpTopic(HT.Id);
        Test.stopTest();    
        return;     
    }
 
    
}