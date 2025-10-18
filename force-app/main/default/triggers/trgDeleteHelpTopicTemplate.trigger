trigger trgDeleteHelpTopicTemplate on iahelp__HelpTopicTemplate__c (before delete) {

    try {
        // Do not allow deletion where template is in use
        for (HelpTopic__c HT : [SELECT CalloutTemplate__c 
                                FROM HelpTopic__c 
                                WHERE CalloutTemplate__c IN :Trigger.oldMap.keySet()]) {
            
            Trigger.oldMap.get(HT.CalloutTemplate__c).addError('Record cannot be deleted as it is in use as a Callout Template.');
        }
        
        for (HelpTopic__c HT : [SELECT Template__c 
                                FROM HelpTopic__c 
                                WHERE Template__c IN :Trigger.oldMap.keySet()]) {
            
            Trigger.oldMap.get(HT.Template__c).addError('Record cannot be deleted as it is in use as a Full Topic Template.');
        }
        
    } catch (exception e) {
        
    }

}