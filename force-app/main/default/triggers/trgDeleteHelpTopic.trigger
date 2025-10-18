trigger trgDeleteHelpTopic on HelpTopic__c (before delete) {
    
    // NB: The following are deleted through master/detail relationships:
    // Relationships - but only where deleted topic is REFERRING
    // Topic Resources
    // Reading List Entries (BUT SEE ALSO BELOW!)
    
    try {
        
        // Deleting help topic deletes its bookmarks...
        HelpBookmark__c[] Bmks = [SELECT Id 
                                FROM HelpBookmark__c 
                                WHERE HelpTopic__c IN :Trigger.oldMap.keySet()];                                    
        delete Bmks;
        
        // ... and interactions
        HelpInteraction__c[] HIs = [SELECT Id
                                FROM HelpInteraction__c
                                WHERE HelpTopic__c IN :Trigger.oldMap.keySet()];
        delete HIs;
                                
        
        // ... and Relationships where deleted topic is RELATED
        HelpRelationship__c[] HRs = [SELECT Id
                                FROM HelpRelationship__c
                                WHERE RelatedHelpTopic__c IN :Trigger.oldMap.keySet()];
                                
        delete HRs;
        
        
        // Whilst RLEs will be deleted by master detail, we need to explicitly fire RLE re-ordering here as MD does NOT cascade to triggers!
        try {
            HelpReadingListEntry__c[] RLEs = [SELECT Id, HelpTopic__r.GuidedRecord__c
                                FROM HelpReadingListEntry__c
                                WHERE HelpTopic__c IN :Trigger.oldMap.keySet()
                                ORDER BY ReadingOrder__c];
                                                    
            // See RLE trigger - this will cause re-numbering                   
            delete RLEs;
            
        } catch (exception ex) {
            
        }
        
        
    } catch (exception e) {
        
    }
                                    
}