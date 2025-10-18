@isTest

/////////////////////////////////////////////////////////////////////////////////////////////////////
// TEST CASES FOR CLASS ControllerOmniFilter
//
// Martin Little for Improved Apps
// January 2016
/////////////////////////////////////////////////////////////////////////////////////////////////////


private class zTest_ControllerOmniFilter {

/*
    static testMethod void setFilterIdentifier() {
        
        zTest_DataGenerator DG = new zTest_DataGenerator();
        ControllerOmniFilter cOF = new ControllerOmniFilter();
        
        
        // We'll need a filter set for this
        HelpFilter__c FLT = DG.getHelpFilter('Account', '001', '1 OR 2', 'FSKey');
        insert FLT;
        
        HelpFilterCriterion__c C1 = DG.getHelpFilterCriterion(FLT, 1, 'FField', 'string', '=', 'AAA');
        insert C1; 
        HelpFilterCriterion__c C2 = DG.getHelpFilterCriterion(FLT, 2, 'FField', 'string', '=', 'BBB');
        insert C2; 
        
        
        Test.startTest();
            // Set non-existent key, testing error trap
            cOF.setFilterIdentifier('a01error');
System.assert(!cOF.Diags.startsWith('Error setting Filter Identifier'));

            // Set good key (with set logic)
            cOF.setFilterIdentifier(FLT.FilterIdentifier__c);
            System.assertEquals(cOF.Diags, '');

        Test.stopTest();
    
        return;             
    }
    

    static testMethod void addFilter() {

        ControllerOmniFilter cOF = new ControllerOmniFilter();

        Test.startTest();
            // Filtered object ID for account, as specified for filter set above
            cOF.setFilteredObjectIdentifier('001');
            cOF.addFilter();
            System.assertEquals('', '');            
        Test.stopTest();
        
        return;
    }
    

    static testMethod void setFilteredObjectIdentifier() {

        zTest_DataGenerator DG = new zTest_DataGenerator();
        ControllerOmniFilter cOF = new ControllerOmniFilter();
        
        
        // We'll need a filter set for this - to test retrieval of filter sets
        HelpFilter__c FLT = DG.getHelpFilter('Account', '001', '1 OR 2', 'FSKey');
        insert FLT;
        
        HelpFilterCriterion__c C1 = DG.getHelpFilterCriterion(FLT, 1, 'FField', 'string', '=', 'AAA');
        insert C1; 
        HelpFilterCriterion__c C2 = DG.getHelpFilterCriterion(FLT, 2, 'FField', 'string', '=', 'BBB');
        insert C2; 
        
        
        Test.startTest();
            // Filtered object ID for account, as specified for filter set above
            cOF.setFilteredObjectIdentifier('001');
            System.assertEquals(cOF.Diags, '');         
        Test.stopTest();
    
        return;             
    }
    
    
    static testMethod void saveCriteria() {

        // Create a filter set and filters
        zTest_DataGenerator DG = new zTest_DataGenerator();
        ControllerOmniFilter cOF = new ControllerOmniFilter();
        
        HelpFilter__c FLT = DG.getHelpFilter('Account', '001', '1 OR 2', 'FSKey');
        insert FLT;
        
        HelpFilterCriterion__c C1 = DG.getHelpFilterCriterion(FLT, 1, 'name', 'STRING', '=', 'AAA');
        insert C1; 
        HelpFilterCriterion__c C2 = DG.getHelpFilterCriterion(FLT, 2, 'name', 'STRING', '=', 'BBB');
        insert C2; 

        // Filtered object ID for account, as specified for filter set above
        cOF.setFilteredObjectIdentifier('001');
        
        // Set omni filter to use this
        cOF.setFilterIdentifier('FSKey');
        
        Test.startTest();   
            cOF.saveCriteria();
System.assert(!cOF.Diags.startsWith('Filter Criteria saved'));          
        Test.stopTest();
        
        return;     
    }
    
    
    static testMethod void showResults() {
        
        // Create a filter set and filters
        zTest_DataGenerator DG = new zTest_DataGenerator();
        ControllerOmniFilter cOF = new ControllerOmniFilter();
        
        HelpFilter__c FLT = DG.getHelpFilter('Account', '001', '1 OR 2', 'FSKey');
        insert FLT;
        
        HelpFilterCriterion__c C1 = DG.getHelpFilterCriterion(FLT, 1, 'name', 'STRING', '=', 'AAA');
        insert C1; 
        HelpFilterCriterion__c C2 = DG.getHelpFilterCriterion(FLT, 2, 'name', 'STRING', '=', 'BBB');
        insert C2; 

        // Filtered object ID for account, as specified for filter set above
        cOF.setFilteredObjectIdentifier('001');
        
        // Set omni filter to use this
        cOF.setFilterIdentifier('FSKey');
        
        Test.startTest();   
            cOF.showResults();
System.assert(!cOF.Diags.startsWith('Retrieved '));         
        Test.stopTest();
        
        return;     
    }
    
    
    static testMethod void FindReplace() {
        // Ops 1 - all
        // Ops 2 - selected items

        // Create a filter set and filters
        zTest_DataGenerator DG = new zTest_DataGenerator();
        ControllerOmniFilter cOF = new ControllerOmniFilter();
        
        HelpFilter__c FLT = DG.getHelpFilter('Account', '001', '1 OR 2', 'FSKey');
        insert FLT;
        
        HelpFilterCriterion__c C1 = DG.getHelpFilterCriterion(FLT, 1, 'name', 'STRING', '=', 'AAA');
        insert C1; 
        HelpFilterCriterion__c C2 = DG.getHelpFilterCriterion(FLT, 2, 'name', 'STRING', '=', 'BBB');
        insert C2; 

        // Filtered object ID for account, as specified for filter set above
        cOF.setFilteredObjectIdentifier('001');
        
        // Set omni filter to use this
        cOF.setFilterIdentifier('FSKey');
        
        Test.startTest();
            cOF.showResults();
            cOF.setFRFind('AAA');
            cOF.setFRReplace('ZZZ');
            cOF.FindReplace();
            
System.assert(!cOF.Diags.startsWith('Find: '));         
        Test.stopTest();
        
        return;     
    }
    
    
    static testMethod void BulkDelete() {
        // Ops 1 - all
        // Ops 2 - selected items

        // Create a filter set and filters
        zTest_DataGenerator DG = new zTest_DataGenerator();
        ControllerOmniFilter cOF = new ControllerOmniFilter();
        
        HelpFilter__c FLT = DG.getHelpFilter('Account', '001', '1 OR 2', 'FSKey');
        insert FLT;
        
        HelpFilterCriterion__c C1 = DG.getHelpFilterCriterion(FLT, 1, 'name', 'STRING', '=', 'AAA');
        insert C1; 
        HelpFilterCriterion__c C2 = DG.getHelpFilterCriterion(FLT, 2, 'name', 'STRING', '=', 'BBB');
        insert C2; 

        // Filtered object ID for account, as specified for filter set above
        cOF.setFilteredObjectIdentifier('001');
        
        // Set omni filter to use this
        cOF.setFilterIdentifier('FSKey');
        
        Test.startTest();
            cOF.showResults();
            cOF.BulkDelete();
            
System.assert(!cOF.Diags.startsWith('Deleting '));          
        Test.stopTest();
        
        return;     
    }
    
 
    static testMethod void updateFilter() {
        
        // Create a filter set and filters
        zTest_DataGenerator DG = new zTest_DataGenerator();
        ControllerOmniFilter cOF = new ControllerOmniFilter();
        
        HelpFilter__c FLT = DG.getHelpFilter('Account', '001', '1 OR 2', 'FSKey');
        insert FLT;
        
        HelpFilterCriterion__c C1 = DG.getHelpFilterCriterion(FLT, 1, 'name', 'STRING', '=', 'AAA');
        insert C1; 
        HelpFilterCriterion__c C2 = DG.getHelpFilterCriterion(FLT, 2, 'name', 'STRING', '=', 'BBB');
        insert C2; 

        // Filtered object ID for account, as specified for filter set above
        cOF.setFilteredObjectIdentifier('001');
        
        // Set omni filter to use this
        cOF.setFilterIdentifier('FSKey');
        
        
        Test.startTest();
            cOF.updateFilter();
System.assertNotEquals('', cOF.Diags);          
        Test.stopTest();
        
        return;             
    }
 
    static testMethod void deleteFilter() {
        // Create a filter set and filters
        zTest_DataGenerator DG = new zTest_DataGenerator();
        ControllerOmniFilter cOF = new ControllerOmniFilter();
        
        HelpFilter__c FLT = DG.getHelpFilter('Account', '001', '1 OR 2', 'FSKey');
        insert FLT;
        
        HelpFilterCriterion__c C1 = DG.getHelpFilterCriterion(FLT, 1, 'name', 'STRING', '=', 'AAA');
        insert C1; 
        HelpFilterCriterion__c C2 = DG.getHelpFilterCriterion(FLT, 2, 'name', 'STRING', '=', 'BBB');
        insert C2; 

        // Filtered object ID for account, as specified for filter set above
        cOF.setFilteredObjectIdentifier('001');
        
        // Set omni filter to use this
        cOF.setFilterIdentifier('FSKey');
        
        
        Test.startTest();
            cOF.deleteFilter();
System.assertNotEquals('', cOF.Diags);          
        Test.stopTest();
        
        return;             
    }
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // PROTOTYPES - TO BE MOVED ELSEWHERE IN CODEBASE!! 
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    static testMethod void showKeyWords() {
        
        // Create a filter set and filters
        zTest_DataGenerator DG = new zTest_DataGenerator();
        ControllerOmniFilter cOF = new ControllerOmniFilter();

        HelpTopic__c HT = DG.getHelpTopic('TopicName');
        insert HT;
        
        String objIdent = HT.Id;
        HelpFilter__c FLT = DG.getHelpFilter('HelpTopic__c', objIdent.substring(0,3), '', 'FSKey');
        insert FLT;
        
        HelpFilterCriterion__c C1 = DG.getHelpFilterCriterion(FLT, 1, 'name', 'STRING', '>', 'A');
        insert C1; 

        // Filtered object ID for account, as specified for filter set above
        cOF.setFilteredObjectIdentifier(objIdent.substring(0,3));
        
        // Set omni filter to use this
        cOF.setFilterIdentifier('FSKey');
        
        Test.startTest();
        
            // No results set should cause trapped error
            cOF.showKeyWords();
            System.assert(cOF.Diags.startsWith('No records '));                     
            
            // Show results and continue
            cOF.showResults();
            cOF.showKeyWords();
System.assertNotEquals(cOF.Diags, 'Done');          
        Test.stopTest();
        
        return;     
    }



    static testMethod void otherTemp() {
        
        
        // Create a filter set and filters
        zTest_DataGenerator DG = new zTest_DataGenerator();
        ControllerOmniFilter cOF = new ControllerOmniFilter();

        HelpTopic__c HT = DG.getHelpTopic('TopicName');
        insert HT;
        
        String objIdent = HT.Id;
        HelpFilter__c FLT = DG.getHelpFilter('HelpTopic__c', objIdent.substring(0,3), '', 'FSKey');
        insert FLT;
        
        HelpFilterCriterion__c C1 = DG.getHelpFilterCriterion(FLT, 1, 'name', 'STRING', '>', 'A');
        insert C1; 

        // Filtered object ID for account, as specified for filter set above
        cOF.setFilteredObjectIdentifier(objIdent.substring(0,3));
        
        // Set omni filter to use this
        cOF.setFilterIdentifier('FSKey');
        
            
        Test.startTest();
            cOF.FLT = FLT;
            cOF.addCriterion();
            cOF.addLogic();
            cOF.clearLogic();
            cOF.removeCriterion();
            cOF.getSelectClause();
            cOF.getFilterSOQL();
            
            system.assertEquals(cOF.FilteredObjectLabel, 'Help Topics');
        Test.stopTest();
        
        return;     
        
    }

*/

}