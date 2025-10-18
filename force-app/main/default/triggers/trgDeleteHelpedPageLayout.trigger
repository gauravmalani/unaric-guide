trigger trgDeleteHelpedPageLayout on iahelp__HelpedPageLayout__c (before delete) {

    try {
        // Deleting page layout deletes its elements
        HelpedElement__c[] HEs = [SELECT Id
                                    FROM HelpedElement__c
                                    WHERE HelpedPageLayout__c IN :Trigger.oldMap.keySet()];
        delete HEs;   
        
        
        // 1.20: Deleting page layout blanks any Help Topic "Step Layout" fields that refer to it
        HelpTopic__c[] HTs = [SELECT Id, GuidedLayout__c
                                    FROM HelpTopic__c
                                    WHERE GuidedLayout__c IN :Trigger.oldMap.keySet()];
        
        for (HelpTopic__c HT : HTs) {
            try {
                HT.GuidedLayout__c = null;
            } catch (exception tx) {
                Trigger.oldMap.get(HT.GuidedLayout__c).addError('Unexpected error deleting a Helped Page Layout: ' + tx.getMessage());
            }
        }
        upsert HTs;                            
        
    } catch (exception e) {
    }

}