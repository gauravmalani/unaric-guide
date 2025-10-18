trigger trgUpdateUser on User (after insert, after update) {
    
// 1.28.1+ TRIGGER NO LONGER IN USE AS LICENSING HANDLED BY LMA

    /*
    try {
        
        // Keep track of the number of users allocated to IH subscriptions
        try {
            IASetIHOrg__c IASet = ControllerSettings.getSettings();
            integer subsUsed;
                    
            subsUsed = [SELECT COUNT()
                    FROM User
                    WHERE (iahelp__ImprovedHelpUserType__c != '' AND iahelp__ImprovedHelpUserType__c != null) 
                    ];

            // Update subs used (store in settings)
            IASet.AllocatedSeats__c = subsUsed;
            update IASet;
                        
        } catch (exception f) {
        }
        
    } catch (exception e) {
    }
    */
}