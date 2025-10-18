trigger trgInsertHelpRelationship on iahelp__HelpRelationship__c (before insert, before update) {

    try {
        
        // Do not allow duplicate Help Relationships:
        // Get any existing Help Relationships records featuring the same Help Topics as the incoming records
        
        Map<String, HelpRelationship__c> relMap = new Map<String, HelpRelationship__c>();
        
        for (HelpRelationship__c newRel : trigger.new) {
            
            // Default semantic tag to a relationship type of "relative" if none is specified
            if (newRel.SemanticTag__c == null) {
                newRel.SemanticTag__c = ControllerSettings.getSettings().DefaultRelationshipSemanticTag__c;
            }
            
            // Keep a copy of each amended relationship filed under each side of the relationship
            relMap.put(newRel.RelatedHelpTopic__c, newRel);
            relMap.put(newRel.ReferringTopic__c, newRel);
            
            // Topic cannot be related to itself
            if (newRel.RelatedHelpTopic__c == newRel.ReferringTopic__c) {
                newRel.addError('Topics cannot be related to themselves');
            }
        }
        
        HelpRelationship__c[] existingRel = [SELECT Id, ReferringTopic__c, RelatedHelpTopic__c, SemanticTag__c 
                                    FROM HelpRelationship__c 
                                    WHERE ReferringTopic__c IN :relMap.KeySet() 
                                    OR RelatedHelpTopic__c IN :relMap.KeySet()];
        
        // For each of these Help Relationship records, check whether:
        // (Referring = Referring AND Related = Related)
        // OR (Referring = Related AND Related = Referring) 
        
        // 1.35+ : enhance this check to take account of relationship type (semantics)
        // The same 2 Topics can be related in different ways
        
        for (HelpRelationship__c existing : existingRel) {
            
            HelpRelationship__c newRel = relMap.get(existing.ReferringTopic__c);
            HelpRelationship__c oldRel;
            
            if (newRel != null) {
                
                // If incoming Relationships include reference to a Topic already featuring in a Relationship,
                // we need to check whether the incoming Rel has same referrer / related etc as the existing
                
                if ((newRel.ReferringTopic__c == existing.ReferringTopic__c && 
                    newRel.RelatedHelpTopic__c == existing.RelatedHelpTopic__c) 
                    || 
                    (newRel.ReferringTopic__c == existing.RelatedHelpTopic__c && 
                    newRel.RelatedHelpTopic__c == existing.ReferringTopic__c)
                    )
                {
                    // Topics are the same: check relationship type
                    if (newRel.SemanticTag__c == existing.SemanticTag__c) {
                        
                        // If inserting creates a duplicate, this is not allowed                        
                        if (Trigger.isInsert) {
                            newRel.addError ('The selected Help Topics (' + newRel.ReferringTopic__c + ', ' + newRel.RelatedHelpTopic__c + ') are already related in the way proposed: please select other Topics or amend the Relationship Type to insert a new record');
                        }
                        
                        // If editing creates a duplicate, this is also not allowed:
                        // So: semantics and topics cannot change (only order may do so)
                        if (Trigger.isUpdate) { 
                            oldRel = Trigger.oldMap.get(newRel.Id);
                            
                            if (newRel.ReferringTopic__c != oldRel.ReferringTopic__c
                                || newRel.RelatedHelpTopic__c != oldRel.RelatedHelpTopic__c
                                || newRel.SemanticTag__c != oldRel.SemanticTag__c
                            )
                            {
                                newRel.addError ('The selected Help Topics (' + newRel.ReferringTopic__c + ', ' + newRel.RelatedHelpTopic__c + ') are already related in the way proposed: edits are not allowed where they would create duplicate relationships');
                            }
                        }
                        
                    }
                    
                    /*
                    // To allow editing of order field: another check has been added
                    // Topics are the same: check relationship type                     
                    if (newRel.SemanticTag__c == existing.SemanticTag__c && newRel.Order__c == existing.Order__c ) {
                        // Error
                        newRel.addError ('The selected Help Topics are already related in the way proposed: please select other Topics or amend the Relationship Type');
                    }
                    */
                    
                }
            }           
        }
        
        
    } catch (exception e) {
        
    }
}