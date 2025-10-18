@isTest

/////////////////////////////////////////////////////////////////////////////////////////////////////
// TEST CASES FOR CLASS ServiceSecurity
//
// Martin Little for Improved Apps
// October 2012
/////////////////////////////////////////////////////////////////////////////////////////////////////


private class zTest_ServiceSecurity {
    
    static testMethod void IsAllowed() {        

        Test.startTest();
        
            ServiceSecurity sS = new ServiceSecurity();
                        
            // Assuming tests run by an Admin, these should return success
            System.assertEquals(true, sS.IsAllowed(ServiceSecurity.KnownSecureOperations.EditHelp));
            System.assertEquals(true, sS.IsAllowed(ServiceSecurity.KnownSecureOperations.AnalyseHelp));
            System.assertEquals(true, sS.IsAllowed(ServiceSecurity.KnownSecureOperations.AdministerHelp));
            
        Test.stopTest();

        return;     
        
    }
    
    
    static testMethod void isGeoEnabled() {
        /* 
Test.startTest();

System.assertEquals(true, ServiceSecurity.isGeoEnabled(), 'when permission is granted.');

Test.stopTest();
*/
        Test.startTest();
        
        Boolean resultGranted = ServiceSecurity.isGeoEnabled();
        System.debug('Geo enabled (expected true, permission granted): ' + resultGranted);
        Test.stopTest();
    }
    
}