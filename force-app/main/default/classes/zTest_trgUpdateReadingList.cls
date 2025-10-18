@isTest

/////////////////////////////////////////////////////////////////////////////////////////////////////
// TEST CASES FOR THE HELPED UPDATE READING LIST TRIGGER (trgUpdateReadingList)
//
// Martin Little for Improved Apps
// December 2014
/////////////////////////////////////////////////////////////////////////////////////////////////////


private class zTest_trgUpdateReadingList {

    static testMethod void BeforeUpdate() {
        
        // Create a RL
        zTest_DataGenerator DG = new zTest_DataGenerator();        
        HelpReadingList__c RL= DG.getHelpReadingList('TestRL');        
        insert RL; 
        
        Test.startTest();
            // Update RL with featured date in past - not allowed
            RL.FeaturedUntil__c = Date.today() - 1 ;
            upsert RL;          
            //system.assert(RL.FeaturedUntil__c == null);
            
            // Update RL with featured date in future - OK
            RL.FeaturedUntil__c = Date.today() + 1;
            upsert RL;
            system.assert(RL.FeaturedUntil__c == Date.today() + 1);
            
        Test.stopTest();
        
        return;

    }
}