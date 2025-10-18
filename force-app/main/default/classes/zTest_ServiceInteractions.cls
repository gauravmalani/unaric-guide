@isTest

/////////////////////////////////////////////////////////////////////////////////////////////////////
// TEST CASES FOR CLASS 
//
// Martin Little for Improved Apps
// October 2012
/////////////////////////////////////////////////////////////////////////////////////////////////////


private class zTest_ServiceInteractions {
    
    // Attempt to log each of 5 interaction types, plus an unknown type 
    static testMethod void logInteraction() {

        // Settings are required for this because there need to be
        // retention days figures...    
        zTest_DataGenerator DG = new zTest_DataGenerator();                                                       
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        map<string, string> mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false); 
        
        ServiceInteractions svsI = new ServiceInteractions();
        boolean b;
                
        Test.startTest();
            
            // Tests check for return of an interaction ID...
            b = svsI.LogInteraction(0, 'Test Interaction', 'TestFilter', null, null, null, null, null);
            System.assertEquals(b, true);
            
            svsI.LogInteraction(1, 'Test Interaction', null, null, null, null, null, null);
            System.assertEquals(18, svsI.Diags.length());
         
            svsI.LogInteraction(2, 'Test Interaction', null, null, null, null, null, null);
            System.assertEquals(18, svsI.Diags.length());
         
            svsI.LogInteraction(3, 'Test Interaction', null, null, null, null, null, null);
            System.assertEquals(18, svsI.Diags.length());
         
            svsI.LogInteraction(4, 'Test Interaction', null, null, null, null, null, null);
            System.assertEquals(18, svsI.Diags.length());
         
            svsI.LogInteraction(5, 'Test Interaction', null, null, null, null, null, null);
            System.assertEquals(18, svsI.Diags.length());
         
            svsI.LogInteraction(6, 'Test Interaction', null, null, null, null, null, null);
            System.assertEquals(18, svsI.Diags.length());

            svsI.LogInteraction(7, 'Test Interaction', null, null, null, null, null, null);
            System.assertEquals(18, svsI.Diags.length());

            svsI.LogInteraction(8, 'Test Interaction', null, null, null, null, null, null);
            System.assertEquals(18, svsI.Diags.length());

            svsI.LogInteraction(9, 'Test Interaction', null, null, null, null, null, null);
            System.assertEquals(18, svsI.Diags.length());

            svsI.LogInteraction(10, 'Test Interaction', null, null, null, null, null, null);
            System.assertEquals(18, svsI.Diags.length());

            svsI.LogInteraction(11, 'Test Interaction', null, null, null, null, null, null);
            System.assertEquals(18, svsI.Diags.length());

            svsI.LogInteraction(12, 'Test Interaction', null, null, null, null, null, null);
            System.assertEquals(18, svsI.Diags.length());
        
            svsI.LogInteraction(13, 'Test Interaction', null, null, null, null, null, null);
            System.assertEquals(18, svsI.Diags.length());
        
            svsI.LogInteraction(14, 'Test Interaction', null, null, null, null, null, null);
            System.assertEquals(18, svsI.Diags.length());
        
            svsI.LogInteraction(15, 'Test Interaction', null, null, null, null, null, null);
            System.assertEquals(18, svsI.Diags.length());
        
            svsI.LogInteraction(16, 'Test Interaction', null, null, null, null, null, null);
            System.assertEquals(18, svsI.Diags.length());
        
            svsI.LogInteraction(17, 'Test Interaction', null, null, null, null, null, null);
            System.assertEquals(18, svsI.Diags.length());
        
            svsI.LogInteraction(18, 'Test Interaction', null, null, null, null, null, null);
            System.assertEquals(18, svsI.Diags.length());
        
            svsI.LogInteraction(19, 'Test Interaction', null, null, null, null, null, null);
            System.assertEquals(18, svsI.Diags.length());
        
            svsI.LogInteraction(20, 'Test Interaction', '', null, null, null, null, null);
            System.assertEquals(18, svsI.Diags.length());
        
            svsI.LogInteraction(21, 'Test Interaction', null, null, null, null, null, null);
            System.assertEquals(18, svsI.Diags.length());
        
            svsI.LogInteraction(22, 'Test Interaction', null, null, null, null, null, null);
            System.assertEquals(18, svsI.Diags.length());
        
            svsI.LogInteraction(23, 'Test Interaction', null, null, null, null, null, null);
            System.assertEquals(18, svsI.Diags.length());
        
            svsI.LogInteraction(24, 'Test Interaction', null, null, null, null, null, null);
            System.assertEquals(18, svsI.Diags.length());
        
            svsI.LogInteraction(25, 'Test Interaction', null, null, null, null, null, null);
            System.assertEquals(18, svsI.Diags.length());

            svsI.LogInteraction(-1, 'Test Interaction', null, null, null, null, null, null);
            System.assertEquals(mapGlbLocs.get('MessageInteractionUnknownType') + ' (-1)', svsI.Diags);
         
        Test.stopTest();
        
        return;
                
    }
    
    @isTest
    static void testGetContextListViewName() {
        // Simulate a URL with a filterName that matches an existing list view in your org
        String mockDeveloperName = 'AllAccounts'; // Must exist in your org, or this will return empty
        String logContextURL = '/lightning/o/Account/list?filterName=00B000000000001__' + mockDeveloperName;
        
        Test.startTest();
        String result = ServiceInteractions.getContextListViewName(logContextURL);
        Test.stopTest();
        
        // We can't assert exact output unless that ListView exists in the org.
        System.debug('Result: ' + result);
        
        // But we can assert that the method handles nulls gracefully
        String resultEmpty = ServiceInteractions.getContextListViewName(null);
        System.assertEquals('', resultEmpty);
        
        String resultInvalid = ServiceInteractions.getContextListViewName('/lightning/o/Account/list?somethingElse=value');
        System.assertEquals('', resultInvalid);
    }
    


    
    static testMethod void startRetention() {
        
        // Settings are required for this because there need to be
        // retention days figures...    
        zTest_DataGenerator DG = new zTest_DataGenerator();                                                       
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        ServiceInteractions svsI = new ServiceInteractions();
        Boolean retVal;
                
        Test.startTest();

            retVal = svsI.startRetention();
         
        Test.stopTest();

        System.assertEquals('Done', svsI.Diags);
        
        return;
    }
    
    
}