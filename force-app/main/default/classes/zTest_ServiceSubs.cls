@isTest

/////////////////////////////////////////////////////////////////////////////////////////////////////
// TEST CASES FOR CLASS ServiceSubs
//
// Martin Little for Improved Apps
// February 2013
/////////////////////////////////////////////////////////////////////////////////////////////////////


private class zTest_ServiceSubs {

    static testMethod void getLicenseInfo() {
        
        ServiceSubs.LicenseInfo LI;
        
        // 1.28.1+ : subscription file not required as of this release
        /*
        zTest_DataGenerator DG = new zTest_DataGenerator();
        Document d = DG.getSubscriptionDoc();
        insert d;
        */
        
        Test.startTest();
            LI = ServiceSubs.getLicenseInfo('Improved Help Documents', null);                                   
        Test.stopTest();

        System.assertEquals('OK', LI.Status); 
        return;             
    }
}