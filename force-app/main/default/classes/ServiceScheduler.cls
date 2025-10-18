/////////////////////////////////////////////////////////////////////////////////////////////////////
// CLASS FOR MANIPULATING SCHEDULED TASKS
//
// Martin Little for Improved Apps
// September 2012
/////////////////////////////////////////////////////////////////////////////////////////////////////


global with sharing class ServiceScheduler implements Schedulable {
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Known operations plus constructor wiring to control launching of the same
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    
    // The set of operations we know how to schedule
    global enum KnownSchedulableTasks {
        RetentionSchedules
    }
    
    
    // Constructor mandates specification of the operation to be scheduled, plus allows for the
    // provision of any supporting parameters that may be required
    private KnownSchedulableTasks theTask;
    private object Params;
    global ServiceScheduler(KnownSchedulableTasks Task, object Parameters) {
        theTask = Task; 
        Params = Parameters;
    }
    

    // Schedulable implementation - which cues the operation specified in our constructor
    global void execute(SchedulableContext SC) {
        
        if (theTask == KnownSchedulableTasks.RetentionSchedules) {
            // Process retention schedules
            RetentionSchedules R = new RetentionSchedules();
        }   
        
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Help interaction retention schedule processing
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    public class RetentionSchedules {
        
        public String Msg {get; set;}
        public RetentionSchedules () {
            
            DateTime minDat;
            Integer dAgo; 
            String HIs;
            string mDate;
            
            Msg = 'Processing retention schedules for Help Interactions: ';
                        
            // Check user has permissions: this is not necessarily a Help PS given right, so check directly...
            if (! Schema.sObjectType.HelpInteraction__c.isDeletable()) {
                Msg += 'Error: the current user does not have the rights to delete interactions... ';

            } else {
                // Delete Help Interation records in line with global settings for retention            
                try {
                    dAgo = (Integer) ControllerSettings.getSettings().TrackDaysCallouts__c;
                    minDat = date.today();
                    minDat = minDat.addDays(dAgo * -1); 
                    mDate = minDat.format('yyyy-MM-dd');              
                    HIs = 'SELECT Id FROM HelpInteraction__c WHERE HelpInteractionType__c = \'Callout\' AND DAY_ONLY(LastModifiedDate) < '+mDate;
                    system.debug('HIs-----'+HIs);
                    ServiceMassOps sm=new ServiceMassOps(HIs);
                    Database.executeBatch(sm,2000);
                    
                } catch (exception e) {
                    Msg += 'Error attempting to delete Callout View Interactions: ' + e.getMessage() + '... ';
                }
    
    
               try {
                    dAgo = (Integer) ControllerSettings.getSettings().TrackDaysTopics__c;
                    minDat = date.today();
                    minDat = minDat.addDays(dAgo * -1); 
                    mDate = minDat.format('yyyy-MM-dd');
                    HIs = 'SELECT Id FROM HelpInteraction__c WHERE HelpInteractionType__c = \'Full Topic\' AND DAY_ONLY(LastModifiedDate) < '+mDate;               
                    
                    ServiceMassOps sm=new ServiceMassOps(HIs);
                    Database.executeBatch(sm,2000);
                    
                } catch (exception e) {
                    Msg += 'Error attempting to delete Full Topic View Interactions: ' + e.getMessage() + '... ';
                }
    
    
             try {
                    dAgo = (Integer) ControllerSettings.getSettings().TrackDaysComments__c;
                    minDat = date.today();
                    minDat = minDat.addDays(dAgo * -1);  
                    mDate = minDat.format('yyyy-MM-dd');
                    HIs = 'SELECT Id FROM HelpInteraction__c WHERE HelpInteractionType__c = \'Comment\' AND DAY_ONLY(LastModifiedDate) < '+mDate;              
                    
                    ServiceMassOps sm=new ServiceMassOps(HIs);
                    Database.executeBatch(sm,2000);                    
                    
                } catch (exception e) {
                    Msg += 'Error attempting to delete Comment Interactions: ' + e.getMessage() + '... ';
                }
    
    
                try {
                    dAgo = (Integer) ControllerSettings.getSettings().TrackDaysVotes__c;
                    minDat = date.today();
                    minDat = minDat.addDays(dAgo * -1); 
                    mDate = minDat.format('yyyy-MM-dd');
                    HIs = 'SELECT Id FROM HelpInteraction__c WHERE HelpInteractionType__c = \'Vote\' AND DAY_ONLY(LastModifiedDate) < '+mDate;             
                    
                    ServiceMassOps sm=new ServiceMassOps(HIs);
                    Database.executeBatch(sm,2000);
                    
                } catch (exception e) {
                    Msg += 'Error attempting to delete Vote Interactions: ' + e.getMessage() + '... ';
                }
    
                
                try {
                    dAgo = (Integer) ControllerSettings.getSettings().TrackDaysErrors__c;
                    minDat = date.today();
                    minDat = minDat.addDays(dAgo * -1);   
                    mDate = minDat.format('yyyy-MM-dd');
                    HIs = 'SELECT Id FROM HelpInteraction__c WHERE HelpInteractionType__c = \'Issue\' AND DAY_ONLY(LastModifiedDate) < '+mDate;                
                   
                    ServiceMassOps sm=new ServiceMassOps(HIs);
                    Database.executeBatch(sm,2000);
                    
                } catch (exception e) {
                    Msg += 'Error attempting to delete Issues: ' + e.getMessage() + '... ';
                }   
        
    
                try {
                    dAgo = (Integer) ControllerSettings.getSettings().TrackDaysResources__c;
                    minDat = date.today();
                    minDat = minDat.addDays(dAgo * -1); 
                    mDate = minDat.format('yyyy-MM-dd');
                    HIs = 'SELECT Id FROM HelpInteraction__c WHERE HelpInteractionType__c = \'Resource\' AND DAY_ONLY(LastModifiedDate) < '+mDate;             
                    
                    ServiceMassOps sm=new ServiceMassOps(HIs);
                    Database.executeBatch(sm,2000);
                    
                } catch (exception e) {
                    Msg += 'Error attempting to delete Resource View Interactions: ' + e.getMessage() + '... ';
                }   
    
    
                try {
                    dAgo = (Integer) ControllerSettings.getSettings().TrackDaysSearches__c;
                    minDat = date.today();
                    minDat = minDat.addDays(dAgo * -1);  
                    mDate = minDat.format('yyyy-MM-dd');
                    HIs = 'SELECT Id FROM HelpInteraction__c WHERE HelpInteractionType__c = \'Search\' AND DAY_ONLY(LastModifiedDate) < '+mDate;              
                   
                    ServiceMassOps sm=new ServiceMassOps(HIs);
                    Database.executeBatch(sm,2000);
                    
                } catch (exception e) {
                    Msg += 'Error attempting to delete Search Interactions: ' + e.getMessage() + '... ';
                }   
                
                
               try {
                    dAgo = (Integer) ControllerSettings.getSettings().TrackDaysLUXOps__c;
                    minDat = date.today();
                    minDat = minDat.addDays(dAgo * -1);   
                    mDate = minDat.format('yyyy-MM-dd');
                    HIs = 'SELECT Id FROM HelpInteraction__c WHERE HelpInteractionType__c = \'System\' AND DAY_ONLY(LastModifiedDate) < '+mDate;             
                  
                    ServiceMassOps sm=new ServiceMassOps(HIs);
                    Database.executeBatch(sm,2000);
                   
                } catch (exception e) {
                    Msg += 'Error attempting to delete System Interactions: ' + e.getMessage() + '... ';
                }  
                
                try {
                    dAgo = (Integer) ControllerSettings.getSettings().TrackDaysTopics__c;
                    minDat = date.today();
                    minDat = minDat.addDays(dAgo * -1);  
                    mDate = minDat.format('yyyy-MM-dd');
                    HIs = 'SELECT Id FROM HelpInteraction__c WHERE HelpInteractionType__c = \'Tree Node\' AND DAY_ONLY(LastModifiedDate) < '+mDate;               
                   
                    ServiceMassOps sm=new ServiceMassOps(HIs);
                    Database.executeBatch(sm,2000);
                    
                } catch (exception e) {
                    Msg += 'Error attempting to delete Tree Node Interactions: ' + e.getMessage() + '... ';
                }   
    
                
                try {
                    dAgo = (Integer) ControllerSettings.getSettings().TrackDaysLUXOps__c;
                    minDat = date.today();
                    minDat = minDat.addDays(dAgo * -1); 
                    mDate = minDat.format('yyyy-MM-dd');
                    HIs = 'SELECT Id FROM HelpInteraction__c WHERE HelpInteractionType__c = \'Personal Field Selection\' AND DAY_ONLY(LastModifiedDate) < '+mDate;              
                   
                    ServiceMassOps sm=new ServiceMassOps(HIs);
                    Database.executeBatch(sm,2000);
                    
                } catch (exception e) {
                    Msg += 'Error attempting to delete Personal Field Selection Interactions: ' + e.getMessage() + '... ';
                }   
     
                
                try {
                    dAgo = (Integer) ControllerSettings.getSettings().TrackDaysLUXOps__c;
                    minDat = date.today();
                    minDat = minDat.addDays(dAgo * -1);    
                    mDate = minDat.format('yyyy-MM-dd');
                    HIs = 'SELECT Id FROM HelpInteraction__c WHERE HelpInteractionType__c = \'Personal Form Visibility\' AND DAY_ONLY(LastModifiedDate) < '+mDate;               
                 
                    ServiceMassOps sm=new ServiceMassOps(HIs);
                    Database.executeBatch(sm,2000);
                    
                } catch (exception e) {
                    Msg += 'Error attempting to delete Personal Form Visibility Interactions: ' + e.getMessage() + '... ';
                }   
    
                
                try {
                    dAgo = (Integer) ControllerSettings.getSettings().TrackDaysLUXOps__c;
                    minDat = date.today();
                    minDat = minDat.addDays(dAgo * -1);  
                    mDate = minDat.format('yyyy-MM-dd');
                    HIs = 'SELECT Id FROM HelpInteraction__c WHERE HelpInteractionType__c = \'Display Density\' AND DAY_ONLY(LastModifiedDate) < '+mDate;               
                 
                    ServiceMassOps sm=new ServiceMassOps(HIs);
                    Database.executeBatch(sm,2000);
                    
                } catch (exception e) {
                    Msg += 'Error attempting to delete Display Density Interactions: ' + e.getMessage() + '... ';
                }   
    
                
                try {
                    dAgo = (Integer) ControllerSettings.getSettings().TrackDaysLUXOps__c;
                    minDat = date.today();
                    minDat = minDat.addDays(dAgo * -1);  
                    mDate = minDat.format('yyyy-MM-dd');
                    HIs = 'SELECT Id FROM HelpInteraction__c WHERE HelpInteractionType__c = \'Form Section Toggle\' AND DAY_ONLY(LastModifiedDate) < '+mDate;              
                   
                    ServiceMassOps sm=new ServiceMassOps(HIs);
                    Database.executeBatch(sm,2000);
                    
                } catch (exception e) {
                    Msg += 'Error attempting to delete Form Section Toggle Interactions: ' + e.getMessage() + '... ';
                }   
     
                
               try {
                    dAgo = (Integer) ControllerSettings.getSettings().TrackDaysLUXOps__c;
                    minDat = date.today();
                    minDat = minDat.addDays(dAgo * -1);  
                    mDate = minDat.format('yyyy-MM-dd');
                    HIs = 'SELECT Id FROM HelpInteraction__c WHERE HelpInteractionType__c = \'Position Detector Context Log\' AND DAY_ONLY(LastModifiedDate) < '+mDate;               
                 
                    ServiceMassOps sm=new ServiceMassOps(HIs);
                    Database.executeBatch(sm,2000);
                    
                } catch (exception e) {
                    Msg += 'Error attempting to delete Position Detector Context Log: ' + e.getMessage() + '... ';
                }   

                try {
                    dAgo = (Integer) ControllerSettings.getSettings().TrackDaysLUXOps__c;
                    minDat = date.today();
                    minDat = minDat.addDays(dAgo * -1);
                    mDate = minDat.format('yyyy-MM-dd');
                    HIs = 'SELECT Id FROM HelpInteraction__c WHERE HelpInteractionType__c = \'Nudge Displayed\' AND DAY_ONLY(LastModifiedDate) < '+mDate;               
                 
                    ServiceMassOps sm=new ServiceMassOps(HIs);
                    Database.executeBatch(sm,2000);
                    
                } catch (exception e) {
                    Msg += 'Error attempting to delete Topic featured in nudge component: ' + e.getMessage() + '... ';
                }

                try {
                    dAgo = (Integer) ControllerSettings.getSettings().TrackDaysLUXOps__c;
                    minDat = date.today();
                    minDat = minDat.addDays(dAgo * -1);    
                    mDate = minDat.format('yyyy-MM-dd');
                    HIs = 'SELECT Id FROM HelpInteraction__c WHERE HelpInteractionType__c = \'Guide Prompt Viewed\' AND DAY_ONLY(LastModifiedDate) < '+mDate;               
                  
                    ServiceMassOps sm=new ServiceMassOps(HIs);
                    Database.executeBatch(sm,2000);
                    
                } catch (exception e) {
                    Msg += 'Error attempting to delete LUX Guide prompt viewed: ' + e.getMessage() + '... ';
                }   
 
                try {
                    dAgo = (Integer) ControllerSettings.getSettings().TrackDaysLUXOps__c;
                    minDat = date.today();
                    minDat = minDat.addDays(dAgo * -1);  
                    mDate = minDat.format('yyyy-MM-dd');
                    HIs = 'SELECT Id FROM HelpInteraction__c WHERE HelpInteractionType__c = \'Metadata sought\' AND DAY_ONLY(LastModifiedDate) < '+mDate;             
                
                    ServiceMassOps sm=new ServiceMassOps(HIs);
                    Database.executeBatch(sm,2000);
                    
                } catch (exception e) {
                    Msg += 'Error attempting to delete Metadata sought: ' + e.getMessage() + '... ';
                }   
  
                try {
                    dAgo = (Integer) ControllerSettings.getSettings().TrackDaysLUXOps__c;
                    minDat = date.today();
                    minDat = minDat.addDays(dAgo * -1);  
                    mDate = minDat.format('yyyy-MM-dd');
                    HIs = 'SELECT Id FROM HelpInteraction__c WHERE HelpInteractionType__c = \'Tree Search Completed\' AND DAY_ONLY(LastModifiedDate) < '+mDate;              
                 
                    ServiceMassOps sm=new ServiceMassOps(HIs);
                    Database.executeBatch(sm,2000);
                    
                } catch (exception e) {
                    Msg += 'Error attempting to delete Tree search: ' + e.getMessage() + '... ';
                }   

                try {
                    dAgo = (Integer) ControllerSettings.getSettings().TrackDaysLUXOps__c;
                    minDat = date.today();
                    minDat = minDat.addDays(dAgo * -1);     
                    mDate = minDat.format('yyyy-MM-dd');
                    HIs = 'SELECT Id FROM HelpInteraction__c WHERE HelpInteractionType__c = \'Tree Search Cancelled\' AND DAY_ONLY(LastModifiedDate) < '+mDate;               
                   
                    ServiceMassOps sm=new ServiceMassOps(HIs);
                    Database.executeBatch(sm,2000);
                    
                } catch (exception e) {
                    Msg += 'Error attempting to delete Tree search: ' + e.getMessage() + '... ';
                } 
     
    
                try {
                    dAgo = (Integer) ControllerSettings.getSettings().TrackDaysLUXOps__c;
                    minDat = date.today();
                    minDat = minDat.addDays(dAgo * -1);    
                    mDate = minDat.format('yyyy-MM-dd');
                    HIs = 'SELECT Id FROM HelpInteraction__c WHERE ( HelpInteractionType__c = \'QAM Drag\' OR HelpInteractionType__c = \'LUX List Type\' OR HelpInteractionType__c = \'List Detail Level\' OR HelpInteractionType__c = \'Sticky\') AND DAY_ONLY(LastModifiedDate) < '+mDate;              
                   
                    ServiceMassOps sm=new ServiceMassOps(HIs);
                    Database.executeBatch(sm,2000);
                    
                } catch (exception e) {
                    Msg += 'Error attempting to delete LUX Interactions: ' + e.getMessage() + '... ';
                }   
                
            }
            
            
            // Keep a record of our activities
            ServiceInteractions svsI = new ServiceInteractions();
            svsI.LogInteraction(5, Msg, null, null, null, null, null, null);
            
            return;
        }   
    }
    
    
}