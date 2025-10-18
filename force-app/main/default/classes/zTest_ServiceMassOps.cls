@isTest

/////////////////////////////////////////////////////////////////////////////////////////////////////
// TEST CASES FOR CLASS ServiceMassOps
//
// Martin Little for Improved Apps
// October 2012
/////////////////////////////////////////////////////////////////////////////////////////////////////


private class zTest_ServiceMassOps {

    static testMethod void myUnitTest() {
                
        String q = 'SELECT Id, HeightBeforeScrolling__c FROM HelpTopic__c';
        String f = 'HeightBeforeScrolling__c';
        Decimal v = 100;
        
        ServiceMassOps SMO = new ServiceMassOps(q);
        SMO = null;
        SMO = new ServiceMassOps(q, f, v);
        
        Id batchInstanceId = Database.executeBatch(SMO);        

        
        Test.startTest();
            System.assertEquals('', SMO.Diags);
        Test.stopTest();
        
        return;         
    }
}