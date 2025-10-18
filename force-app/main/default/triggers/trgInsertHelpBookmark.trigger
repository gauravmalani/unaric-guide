trigger trgInsertHelpBookmark on iahelp__HelpBookmark__c (before insert, before update) {

    // Prevent duplicate bookmarks
    try {
        
        Map<String, HelpBookmark__c> bmkMap = new Map<String, HelpBookmark__c>();
        
        // Put proposed new bookmarks in a map
        for (HelpBookmark__c newBmk : trigger.new) {
            bmkMap.put(newBmk.HelpTopic__c, newBmk);
        }
        
        // Get any existing bookmarks for the help topics referenced in the new bookmarks
        HelpBookmark__c[] existingBmk = [SELECT Id, HelpTopic__c, OwnerId 
                                    FROM HelpBookmark__c 
                                    WHERE HelpTopic__c IN :bmkMap.KeySet()];
        
        
        // For each existing Bookmark, check whether its owner is the same as that of the proposed bookmark
        for (HelpBookmark__c existing : existingBmk) {
            
            HelpBookmark__c newBmk = bmkMap.get(existing.HelpTopic__c);
            
            if (newBmk != null) {               
                if (newBmk.OwnerId == existing.OwnerId) {
                    // Fail if so...
                    newBmk.addError ('You have already bookmarked this Help Topic');
                }
            }
        }           
        
        
    } catch (exception e) {
        
    }
    
}