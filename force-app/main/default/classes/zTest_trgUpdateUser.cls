@isTest

/////////////////////////////////////////////////////////////////////////////////////////////////////
// TEST CASES FOR THE USER UPDATE TRIGGER (trgUpdateUser)
//
// Martin Little for Improved Apps
// April 2013
/////////////////////////////////////////////////////////////////////////////////////////////////////


private class zTest_trgUpdateUser {

// 1.28.1+ TRIGGER NO LONGER IN USE AS LICENSING HANDLED BY LMA

/*
    static testMethod void AfterInsert() {
        
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        // Create a user
        User U1 = [SELECT LanguageLocaleKey, TimezoneSidKey, LocaleSidKey, EmailEncodingKey
                    FROM User WHERE Id = :UserInfo.getUserId()];
        User U = new User();
        U.FirstName = 'FN';
        U.LastName = 'LN';
        U.Alias = 'AL';
        U.UserName = '1@2.zzz';
        U.Email = '1@2.zzz';
        U.ProfileId = UserInfo.getProfileId();
        U.LanguageLocaleKey = U1.LanguageLocaleKey;
        U.TimezoneSidKey = U1.TimezoneSidKey;
        U.LocaleSidKey = U1.LocaleSidKey;
        U.EmailEncodingKey = U1.EmailEncodingKey;
        
        
        insert U;
        
        Test.startTest();
            
            // Note the number of help users
            Decimal D = ControllerSettings.getSettings().AllocatedSeats__c;
            
            // Amend user to be an IH user
            U.iahelp__ImprovedHelpUserType__c = 'Help Administrator';
            update U;
            
            // Check user count setting
            System.assertEquals(ControllerSettings.getSettings().AllocatedSeats__c, D + 1);
            
        Test.stopTest();
        
        return; 
        
    }
*/

}