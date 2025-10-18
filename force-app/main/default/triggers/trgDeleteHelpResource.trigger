trigger trgDeleteHelpResource on iahelp__HelpResource__c (before delete) {

    // NB: The following are deleted through master/detail relationships:
    // Topic Resources
    
    try {
        // Deleting resource deletes its interactions
        HelpInteraction__c[] HIs = [SELECT Id
                                  FROM HelpInteraction__c
                                  WHERE HelpResource__c IN :Trigger.oldMap.keySet()];
        delete HIs;                                
        
    } catch (exception e) {
        
    }

}