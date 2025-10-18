/////////////////////////////////////////////////////////////////////////////////////////////////////
// Implemented this class to be chained with the seedHelpSettingsBatch class
// to automate the initialise settings and upsert config tools button.
//
// Gaurav Patil for Unaric
// April 2025
/////////////////////////////////////////////////////////////////////////////////////////////////////


global class SeedConfigFromUserDocQueueable implements Queueable, Database.AllowsCallouts {
    
    public String jsonDocUrl = '/resource/iahelp__IHResources/cfg/HelpConfig.json';  // Fixed value
    
    public String Diags = '';
    Map<String, String> mapGlbLocs;
    
    global SeedConfigFromUserDocQueueable() {
        
        mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false);
    }
    
    global void execute(QueueableContext context) {
        System.debug('Queueable execution started: Fetching JSON content.');
        
        PageReference P;
        Blob bInfo;     
        List<ConfigurationItem__c> LXTsIn;
        List<ConfigurationItem__c> LXTsDel;
        List<ConfigurationItem__c> LXTsOut = new List<ConfigurationItem__c> {};
            ConfigurationItem__c LXT;
        ServiceSecurity Security = new ServiceSecurity();
        try {
            Diags = 'Seeding configuration from file: ' + jsonDocUrl + '... ';
            // Get the JSON from specified file
            P = new PageReference(jsonDocUrl);
            bInfo = P.getContent();    
            Diags += 'Content of document obtained... ';
            // Re-construct configuration records from this
            LXTsIn = (List<ConfigurationItem__c>) JSON.deserialize(bInfo.toString(), List<ConfigurationItem__c>.class); 
            Diags += LXTsIn.size() + ' tools... ';
            // Check rights
            Boolean[] UPs = Security.UserPermissions();
            Boolean bAdministrator = UPs[2];
            
            if (!bAdministrator) {
                Diags = mapGlbLocs.get('MessageNoRights');
                
                
                
            }
            LXTsDel = [SELECT Id FROM ConfigurationItem__c WHERE SkipImportOverwrite__c = false];
            
            // We cannot keep the IDs and they're not important: so "cross load" the config records into new ones
            for (ConfigurationItem__c L : LXTsIn) {
                LXT = new ConfigurationItem__c();
                
                LXT.ActionCode__c = L.ActionCode__c; 
                LXT.Description__c = L.Description__c; 
                LXT.DisplayGrouping__c = L.DisplayGrouping__c; 
                LXT.DisplayOrder__c = L.DisplayOrder__c; 
                LXT.HasDivider__c = L.HasDivider__c; 
                LXT.IconClass__c = L.IconClass__c; 
                LXT.IconContent__c = L.IconContent__c; 
                LXT.Label__c = L.Label__c; 
                LXT.NegotiateToolbarLevel__c = L.NegotiateToolbarLevel__c;              
                LXT.PermissionLevel__c = L.PermissionLevel__c;
                LXT.SkipExport__c = L.SkipExport__c;
                LXT.SkipImportOverwrite__c = L.SkipImportOverwrite__c;
                LXT.SupportingControls__c = L.SupportingControls__c;
                LXT.TipText__c = L.TipText__c; 
                LXT.ToggleActiveMarker__c = L.ToggleActiveMarker__c;
                LXT.ToggleNext__c = L.ToggleNext__c; 
                LXT.TogglePrev__c = L.TogglePrev__c; 
                LXT.ToolClass__c = L.ToolClass__c; 
                LXT.ToolContext__c = L.ToolContext__c; 
                LXT.ToolFilter__c = L.ToolFilter__c; 
                LXT.Type__c = L.Type__c; 
                
                LXTsOut.add(LXT);
            }
            
            
            string objname;                                             // API name of object whose pick lists are to be populated
            map<string,string> picval  = new map<string,string>();      // Map of picklist Field API name to valueset.
            
            // Converting to JSON String because custom parameters are not able to pass to future methods.
            String LXTsDelStr = JSON.serialize(LXTsDel);//Convert the List of ConfigurationItems to JSON string.
            String LXTsOutStr = JSON.serialize(LXTsOut);//Convert the List of ConfigurationItems to JSON string.
            System.debug('LXTsDelStr>>>>>>>>>>>>>>>>>.1'+LXTsDelStr);
            System.debug('LXTsOutStr>>>>>>>>>>>>>>>>>.1'+LXTsOutStr);
            // Configuration item pick lists
            objname = 'iahelp__ConfigurationItem__c';         
            picval.put('iahelp__Type__c','AuthorConfiguration,Body,ConfigurationData,Drop-down,Ellipsis,Extension,Footer,Header,Listing,ProductVersion,WizardStep,WizardStepBodyTool'); //Map of field APIName and valueSet.
            picval.put('iahelp__ToolContext__c','[Hidden],[Template],AlertOKOnly,Builder,CardAutoForm,CardAutoForm_TopicViewer,CardComment,CardComment_Listing,CardHelpTopic,CardKeywords,CardReadingLists,CardRelatedHelp,CardRelatedTags,CardResources,CardStickies,CardTags,CardTree,CardTreeOtherList,CardTreeSearchList,CGDesignMode,FixedHelp,GEModeTopicSearchList,IHLUXApp_Settings_Tabs,ImageViewer,LinkResources,LinkTopics,NewSticky,PositionDetector,PositionDetectorCG,PositionDetectorHelpButtons,PositionDetectorHelpRequests,QAM,QAMHelpIndex_Topic,QAMHelpIndex_Tree,QuickStartU1_Tree,ReadingListBuilder_Topic,ReadingListBuilder_Topic_Autoform,ReadingListBuilder_Tree,ReconfigureMode_Topic,ReconfigureMode_Topic_Autoform,ReconfigureMode_Tree,RLViewer,tabsTest1,Test,wizBulkTopicUpload,wizCxtHelp,wizCxtHelp_Step1_List,wizCxtHelp_Step2_List,wizTest');
            System.debug('picval>>>>>>>>>>>>>>>>>>>>>>>>1'+picval);
            // ServiceSchema.UpdateValueSet(objname,picval,LXTsDelStr,LXTsOutStr); //presen
            System.enqueueJob(new UpdateValueSetQueueable(objname,picval,LXTsDelStr,LXTsOutStr));
            
            //System.enqueueJob(new UpdateValueSetQueueable(objname,picval,LXTsDelStr,LXTsOutStr));      
            // Only supply config items in first call: no need to keep upserting
            LXTsDelStr = '';
            LXTsOutStr = '';
            System.debug('LXTsDelStr>>>>>>>>>>>>>>>>>.2'+LXTsDelStr);
            System.debug('LXTsOutStr>>>>>>>>>>>>>>>>>.2'+LXTsOutStr);
            System.debug('picval>>>>>>>>>>>>>>>>>>>>>>>>2'+picval);
            // Reading List pick lists
            objname = 'iahelp__HelpReadingList__c';         
            picval.put('iahelp__LightningPresentationStyle__c','Adopter,Adopter - Minimal Topic,Adopter - Topic Viewer,Carousel,Standard'); 
            // System.enqueueJob(new UpdateValueSetQueueable(objname,picval,LXTsDelStr,LXTsOutStr));
            ServiceSchema.UpdateValueSet(objname,picval,LXTsDelStr,LXTsOutStr);                
            Diags = mapGlbLocs.get('MessageGenericTaskComplete') + ': ' + LXTsOut.size() + ' ' + mapGlbLocs.get('MessageGenericNewRecords');  
            
        } catch (exception e) {
            Diags = mapGlbLocs.get('MessageGenericError') + ' - ' + e.getMessage();
        }
        
        
        return;
    }
    
}