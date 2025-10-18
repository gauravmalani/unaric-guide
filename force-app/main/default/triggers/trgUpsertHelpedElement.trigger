/* 
Set a flag to assist with reports on Helped Element records 
when the element has a data driven filter defined
*/

trigger trgUpsertHelpedElement on iahelp__HelpedElement__c (before insert, before update) {
    
    try {
        for (HelpedElement__c newHE : trigger.new) {
            newHE.HasDDF__c = (newHE.DataDrivenFilter__c != '' && newHE.DataDrivenFilter__c != null);
        }
        
    } catch (exception e) {
        
    }
    
}