trigger trgUpdateReadingList on iahelp__HelpReadingList__c (before update) {
    
    // There is a validation rule on RLs that disallows featured until dates in the past.
    // This can cause issues when adding RL entries, as these effectively cause an update 
    // to the RL (it's calculated number of entries).
    
    // This trigger therefore clears any featured until dates in the past in these cases
    
    for (HelpReadingList__c updRL : trigger.new) {
        if (updRL.FeaturedUntil__c < Date.today()) {
            updRL.FeaturedUntil__c = null;
        }
    }
    
}