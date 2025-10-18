trigger trgInsertHelpReadingListEntry on iahelp__HelpReadingListEntry__c (before insert) {
    
    try {
        
        // Do not allow duplicate entries on a given reading list:
        // Get any existing entries featuring the same help topics as the new records
        
        Map<String, HelpReadingListEntry__c> rleMap = new Map<String, HelpReadingListEntry__c>();
        
        for (HelpReadingListEntry__c newRLE : trigger.new) {
            rleMap.put(newRLE.HelpTopic__c, newRLE);
        }
        
        HelpReadingListEntry__c[] existingRLE = [SELECT Id, HelpReadingList__c, HelpTopic__c 
                                    FROM HelpReadingListEntry__c 
                                    WHERE HelpTopic__c IN :rleMap.KeySet()];
        
        // For each of these Reading List Entry records, check whether they also feature 
        // same Help Reading List as incoming
        
        for (HelpReadingListEntry__c existing : existingRLE) {
            
            HelpReadingListEntry__c newRLE = rleMap.get(existing.HelpTopic__c);
            
            if (newRLE != null) {               
                if (newRLE.HelpReadingList__c == existing.HelpReadingList__c) {
                    // Error
                    newRLE.addError ('The selected Help Topic is already associated with this Reading List');
                }
            }
        }           
            
        
    } catch (exception e) {
        
    }
    
}