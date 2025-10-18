trigger trgInsertHelpResource on iahelp__HelpResource__c (before insert, before update) {

    // Prepend "http://" to any resourceURLs when user does not enter a protocol    
    try {
        for (HelpResource__c newRes : trigger.new) {
            if (newRes.ResourceURL__c.indexOf('//') == -1) {
                newRes.ResourceURL__c = 'http://' + newRes.ResourceURL__c;
            } 
        }
                
    } catch (exception e) {
    }
}