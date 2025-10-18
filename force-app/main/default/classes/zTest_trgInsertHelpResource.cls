@isTest

/////////////////////////////////////////////////////////////////////////////////////////////////////
// TEST CASES FOR THE INSERT HELP RESOURCE TRIGGER (trgInsertHelpResource)
//
// Martin Little for Improved Apps
// December 2014
/////////////////////////////////////////////////////////////////////////////////////////////////////


private class zTest_trgInsertHelpResource {

    static testMethod void BeforeInsert() {
        
        // Create 1 resource with a protocol and 1x without
        zTest_DataGenerator DG = new zTest_DataGenerator();
        HelpResource__c HR1 = DG.getHelpResource('Test Resource'); 
        HR1.ResourceURL__c = 'www.NoSuch.com';
        insert HR1;
        
        HelpResource__c HR2 = DG.getHelpResource('Test Resource'); 
        HR2.ResourceURL__c = 'ftp://NoSuch.com';
        insert HR2;

        Test.startTest();
            // Check that http gets pre-pended if not present
            //system.assertEquals('www.NoSuch.com', HR1.ResourceURL__c);
            
            // Check that protocols, if present, are left intact
            system.assertEquals('ftp://NoSuch.com', HR2.ResourceURL__c);
            
        Test.stopTest();
        
        return;
    }
}