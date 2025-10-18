trigger trgInsertHelpTopicResource on iahelp__HelpTopicResource__c (before insert) {

    try {
        
        // Do not allow duplicate Help Topic Resourcs:
        // Get any existing Help Topic Resource records featuring the same Resources as the new records
        
        Map<String, HelpTopicResource__c> resMap = new Map<String, HelpTopicResource__c>();
        
        for (HelpTopicResource__c newHTR : trigger.new) {
            resMap.put(newHTR.HelpResource__c, newHTR);
        }
        
        HelpTopicResource__c[] existingHTR = [SELECT Id, HelpResource__c, HelpTopic__c 
                                    FROM HelpTopicResource__c 
                                    WHERE HelpResource__c IN :resMap.KeySet()];
        
        // For each of these Help Topic Resource records, check whether they also feature 
        // same Help Topic as incoming
        
        for (HelpTopicResource__c existing : existingHTR) {
            
            HelpTopicResource__c newHTR = resMap.get(existing.HelpResource__c);
            
            if (newHTR != null) {               
                if (newHTR.HelpTopic__c == existing.HelpTopic__c) {
                    // Error
                    newHTR.addError ('The selected Help Resource is already associated with this Help Topic');
                }
            }
        }
        
    } catch (exception e) {
        
    }
    
}