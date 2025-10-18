@isTest

/////////////////////////////////////////////////////////////////////////////////////////////////////
// TEST CASES FOR CLASS ControllerIHEditingTools
//
// Martin Little for Improved Apps
// September 2013
/////////////////////////////////////////////////////////////////////////////////////////////////////


private class zTest_ControllerIHEditingTools {

    static testMethod void initialise() {
        
        ControllerIHEditingTools cIHE = new ControllerIHEditingTools();
        ServiceSecurity sS = new ServiceSecurity();
                
        Test.startTest();
            cIHE.initialise();
            system.assertEquals(cIHE.isSeated, sS.IsSeated());
        Test.stopTest();
        
        return;
    }
}