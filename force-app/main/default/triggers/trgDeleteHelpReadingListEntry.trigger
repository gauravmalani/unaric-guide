trigger trgDeleteHelpReadingListEntry on iahelp__HelpReadingListEntry__c (before delete) {
    
    // Deleting an entry should renumber remaining RLEs in the relevant RL
    
    Integer iOrd;
    String lastRLID = '';
    String strCrit = '';
    HelpReadingListEntry__c[] delRLEs;  
    HelpReadingListEntry__c[] reOrdRLEs;
    
    try {
        // Get all RLEs from affected RLs (those whose entries are being deleted) - EXCLUDING the deleted entries
        strCrit =  'SELECT Id, HelpReadingList__c, HelpTopic__c, HelpTopic__r.GuidedRecord__c, HelpReadingList__r.Id, HelpReadingList__r.ReadingListType__c ';
        strCrit += 'FROM HelpReadingListEntry__c '; 
        strCrit += 'WHERE Id NOT IN(';
        for (HelpReadingListEntry__c E : trigger.old) {
            strCrit += '\'' + E.Id + '\',';         
        }       
        strCrit = strCrit.subString(0, strCrit.length() - 1);
        strCrit += ') AND HelpReadingList__c IN(';
        for (HelpReadingListEntry__c E : trigger.old) {
            strCrit += '\'' + E.HelpReadingList__c + '\',';         
        }
        strCrit = strCrit.subString(0, strCrit.length() - 1);
        strCrit += ') ORDER BY HelpReadingList__c';
                
        delRLEs = database.query(strCrit);
        reOrdRLEs = new HelpReadingListEntry__c[]{};
        
        for (HelpReadingListEntry__c delRLE : delRLEs) {
            
            if (lastRLID != String.valueOf(delRLE.HelpReadingList__r.Id)) {             
                lastRLID = delRLE.HelpReadingList__r.Id;                                                                        
                iOrd = 0;
                
            } else {
                iOrd += 1;
            }
                                                
            delRLE.ReadingOrder__c = iOrd;                  
            reOrdRLEs.add(delRLE);
            
        }   // Loop around delRLEs - RLEs deleted in this trigger
        
        // Update all amended (re-ordered) RLEs
        update reOrdRLEs;
        
    } catch (exception e) {
    }
    
}