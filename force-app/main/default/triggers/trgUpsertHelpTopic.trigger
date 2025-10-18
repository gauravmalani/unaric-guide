/*
Derive and store plain text version of Topic Description on updates
*/

trigger trgUpsertHelpTopic on iahelp__HelpTopic__c (before insert, before update) {

    try {
        string txtPlain;
        string[] plains;
        integer i;
        Boolean kwdCheckRequired = false;
        HelpTopic__c[] kwdTopics = null;
        map<string,string> mapDlgLocs;

        
        for (HelpTopic__c newHT : trigger.new) {
            
            // Parse out any script tags from description:
            // NB: Our tests suggest script tag are parsed out before reaching trigger code
            newHT.Description__c = newHT.Description__c.replaceAll('<[Ss][Cc][Rr][Ii][Pp][Tt]','SCRIPT');
            
            if(newHT.Description__c !=null){
                        txtPlain = newHT.Description__c;  
            }
            // Copy rich text description to plain text fields
      
            plains = new string[]{'', '', '', '', ''};
            
            if (txtPlain != null) {
             //   txtPlain = txtPlain.replaceAll('<[/a-zAZ0-9]*>','');
             //   Modified to remove HTML tags from Description field
                txtPlain = txtPlain.replaceAll('<([a-zA-Z0-9]*[^<>a-zA-Z0-9]*)*>','');
                for (i=1; i<6; i++) {
                    if (txtPlain.length() > i * 255) {
                        plains[i-1] = txtPlain.substring((i-1) * 255, i * 255);
                    } else {
                        plains[i-1] = txtPlain.substring((i-1) * 255);
                        break;
                    }
                }               
            }
            
            newHT.DescriptionText1__c = plains[0];
            newHT.DescriptionText2__c = plains[1];
            newHT.DescriptionText3__c = plains[2];
            newHT.DescriptionText4__c = plains[3];
            newHT.DescriptionText5__c = plains[4];
                        
        }
                
    } catch (exception e) {
        system.debug('ERROR IN Help Topic Upsert TRIGGER: ' + e.getMessage());
    }
        
}