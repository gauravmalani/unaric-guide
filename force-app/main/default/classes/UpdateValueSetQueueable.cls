/////////////////////////////////////////////////////////////////////////////////////////////////////
// Implemented to automate the upsert config tools button and 
// replacing the @future method serviceschema.updatevalueset.
//
// Gaurav Patil for Unaric
// April 2025
/////////////////////////////////////////////////////////////////////////////////////////////////////


global class UpdateValueSetQueueable implements Queueable, Database.AllowsCallouts {
    
    private String ObjAPIName;
    private Map<String, String> PickListInfo;
    private String LXTsDelStr;
    private String LXTsOutStr;
 private static final string APIVersion = 'v53.0';
    global UpdateValueSetQueueable(String ObjAPIName, Map<String, String> PickListInfo, String LXTsDelStr, String LXTsOutStr) {
        this.ObjAPIName = ObjAPIName;
        this.PickListInfo = PickListInfo;
        this.LXTsDelStr = LXTsDelStr;
        this.LXTsOutStr = LXTsOutStr;
    }

    global void execute(QueueableContext context) {
  List<String> ServiceMessage = new List<String>();           // List Of error messages which will fire in the run.
        map<string,string> finalMap = new map<string,string>();     // Final map contains all the ValueSets.
        map<string,object> Ids;
        Map<String,String> NewValueSetMapForCustomNotific = new Map<String,String>(); 
        List<String> StatusCode = new List<String>();               // List of final status code for sending Notification one by one.
        List<String> NotfTitle = new List<String>();                // List of custom notification body.
        List<String> UpdatedValueSet = new List<String>();          // List of all the new ValueSet added. 
        
        EntityDefinition  ObjectId;                                 // Getting the Object Id (For Custom object we will get Id and for Standard Rec we will get Object name).
         System.debug('inside futureeee>>>>>>>>>>>>>>>>..');
        
        try{
            // Fetching object Id from  EntityDefinition.
            ObjectId = [SELECT DurableId FROM EntityDefinition WHERE QualifiedApiName =: ObjAPIName];  
        }catch(Exception e){
            ServiceMessage.add(String.valueOf(e));
            System.debug('Error'+e);
        }
        
        // Proceed only if we located the object whose pick lists are to be populated
        if(ObjectId != null){//Checking for ObjectId is not null.
            
            if(!String.isBlank(String.valueOf(ObjectId.DurableId))){//Checking for Object Id is not null.
                
                try{   
                    //Get the Fields of the Object using Schema.    
                    Map<String, Schema.SObjectField> FieldsMap = Schema.getGlobalDescribe().get(ObjAPIName).getDescribe().Fields.getMap();
                    
                    //Checking for the field Data type and for repeat valueSets.      
                    for(Schema.SObjectField field : FieldsMap.values()){
                        
                        // checking for the picklist api name and also check for picklist field present in the PickListInfo map.
                        if(PickListInfo.keySet().contains(string.valueOf(field)) == true && string.valueOf(field.getDescribe().getType()) == 'PICKLIST'){
                            list<string> NewValueSet = PickListInfo.get(string.valueOf(field)).split(',');//Spliting the value string by comma seperated value set given in the initial MAP.
                            System.debug('Valueset : '+NewValueSet);
                            for( Schema.PicklistEntry pickListVal : field.getDescribe().getPicklistValues()){//Iterating over picklist field value set which are currently present in the picklist field.
                                if(NewValueSet.contains(pickListVal.getLabel()) == true){//Checking for picklist ApiName in pickListVal list, Is they are alrady present in the Picklist value set.
                                    System.debug('Label : '+pickListVal.getLabel());
                                    NewValueSet.remove(NewValueSet.indexOf(pickListVal.getLabel()));//remove the duplicate value.   
                                }
                            }
                            String StringOfNewValueSet = String.join( NewValueSet, ',');
                            finalMap.put(string.valueOf(field.getDescribe().getName()),StringOfNewValueSet);//Putting keys as object api name(local name without name space) and value as valueset string seperate by comma. 
                                 System.debug('inside futureeee>>>>>>>>>>>>>>>>..');
                        }
                    }   
                }catch(Exception e){
                    ServiceMessage.add(String.valueOf(e));
                    System.debug('ERROR :'+e);
                }
                
                // Creating the Body for new added picklist value set.
                for(string NewPickList : finalMap.keySet()){
                    if(!String.isBlank(finalMap.get(NewPickList)) == true){
                        list<string> ValueSetList =  finalMap.get(NewPickList).split(',');//create the list from the comma seperated string.  
                        string NewValueSetBody = ''; //Making the body of new value set.
                        if(ValueSetList.size() > 0){//Checking for the size of ValueSetList if the new value set is not given.
                             
                            String NewUpdateValueSet = ''; // adding the new value set.
                            for(integer i = 0 ; i <  ValueSetList.size() ; i++){
                                NewUpdateValueSet += ValueSetList[i]+' ,'; // Adding the new values in body string.
                                NewValueSetMapForCustomNotific.put(NewPickList,NewUpdateValueSet);
                                NewValueSetBody += '{"color": null,"default": false,"description": "This is a new value","isActive": true,"label": "'+ValueSetList[i]+'","urls": null,"valueName":"'+ValueSetList[i]+'"}'; //Format of the body 
                                NewValueSetBody +=   ValueSetList.size()-1 > i ? ',':''; //To delete the last extra "," from the body string.                                                                              //to patch new value sets. 
                            }   
                        }
                        finalMap.put(NewPickList,NewValueSetBody);//MAP of picklist apiname as key and new value set payload body as values.
                        
                    }  
                }
            }   
            
            for(string pickAPI : finalMap.keySet()){
               system.debug('Check For New Value Set : '+!String.isBlank(finalMap.get(pickAPI)));
                if(!String.isBlank(finalMap.get(pickAPI)) == true ){
                   
                    try{
                         //Query the fields Id using tooling Api.
                        string soqlQuery = '/services/data/'+APIVersion+'/tooling/query?q=SELECT+Id,+DeveloperName,+TableEnumOrId+FROM+CustomField+WHERE+TableEnumOrId+=+\''+ObjectId.DurableId+'\'+AND+DeveloperName+=+\''+pickAPI.removeEnd('__c').replace('iahelp__', '')+'\'';
                        system.debug('Tooling query link'+soqlQuery);
                        
                        //Call out for getting picklist field Id.
                        String GetBodyFieldId = ServiceSchema.restGet(URL.getOrgDomainURL().toExternalForm() +soqlQuery, 'GET', System.UserInfo.getSessionId());
                        system.debug('body '+GetBodyFieldId);
                        
                        //Parsing the JSON body.
                        map<string,object>  ResponseMAP = (map<string,object>)JSON.deserializeUntyped(GetBodyFieldId);
                        string Id = string.valueOf(ResponseMAP.get('records')).replaceAll('()','');
                        list<object> records = (list<object>)ResponseMAP.get('records');
                        Ids =  (map<string,object>)records[0];// Field Id.
                    }catch(Exception e){
                        ServiceMessage.add(String.valueOf(e));
                        System.debug('Error '+e);
                    }
                    
                    try{
                        //Api call for fetching old value set. 
                        String EndPoint = URL.getOrgDomainURL().toExternalForm() +'/services/data/'+APIVersion+'/tooling/sobjects/CustomField/'+Ids.get('Id')+'';
                        String GetBodyOldValueset = ServiceSchema.restGet(EndPoint, 'GET', System.UserInfo.getSessionId());
                        system.debug('GetBodyOldValueset::- '+GetBodyOldValueset);
                        
                        //Parsing the JSON Body.
                        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(GetBodyOldValueset);
                        Map<String, Object> Metadata = (Map<String, Object>)response.get('Metadata');
                        Map<string, Object> valuesetMap = (Map<string, Object>)Metadata.get('valueSet'); 
                        Map<string, Object> valueSetDefinition = (Map<string, Object>)valuesetMap.get('valueSetDefinition');
                        list<Object> value = (list<Object>)valueSetDefinition.get('value');//Old valueSet.
                        
                        //Adding up old and new value set.
                        String OldValueSet = ''; // old ValueSets Body.
                        for(integer i = 0 ; i <  value.size() ; i++){
                            map<string,object> oldValues  = (map<string,object>)value[i];
                            string color = String.isBlank(String.valueOf(oldValues.get('color'))) ? null : '"'+oldValues.get('color')+'"';//Getting the Color parameter of value set.
                            String description = String.isBlank(String.valueOf(oldValues.get('description'))) ? null : '"'+oldValues.get('description')+'"';//Getting the description of the old ValueSet.
                            
                            OldValueSet +=  '{"color":' +color+',';
                            OldValueSet +=  '"default":'+oldValues.get('default')+',';
                            OldValueSet +=  '"description":'+description+',';
                            OldValueSet +=  '"isActive":true,';
                            OldValueSet +=  '"label":"'+oldValues.get('label')+'",';
                            OldValueSet +=  '"urls":'+oldValues.get('urls')+',';
                            OldValueSet +=  '"valueName":"'+oldValues.get('valueName')+'"}';
                            OldValueSet +=   value.size()-1 > i ? ',': '';
                        }   
                        
                        // New body JSON string.
                        string UpdatedBody = '{ "Metadata":{ "description": "'+Metadata.get('description')+'", "label": "'+Metadata.get('label')+'", "type": "Picklist", "valueSet":{ "valueSetDefinition":{ "sorted": false, "value": ['+OldValueSet +','+ finalMap.get(pickAPI)+']}}},"FullName":"'+ObjAPIName+'.'+pickAPI+'"}';
                        system.debug('BODY'+UpdatedBody);
                        //Insert the Picklist value.
                        HttpRequest req3 = new HttpRequest();
                        req3.setEndpoint(URL.getOrgDomainURL().toExternalForm()+'/services/data/'+APIVersion+'/tooling/sobjects/CustomField/'+Ids.get('Id')+'');
                        req3.setMethod('PATCH');
                        req3.setHeader('Authorization', 'Bearer ' + System.UserInfo.getSessionId());
                        req3.setHeader('Content-Type', 'application/json');
                        req3.setBody(UpdatedBody);
                        Http http3 = new Http();
                        HttpResponse res3 = http3.send(req3);
                        system.debug('res::- '+res3.getBody());
                        system.debug('status code : '+res3.getStatusCode());
                        
                        //Adding the response to the lists for firing custom notifications.
                        StatusCode.add(String.valueOf(res3.getStatusCode()));
                        UpdatedValueSet.add(String.valueOf(NewValueSetMapForCustomNotific.get(pickAPI)+' valueset are added'));
                        NotfTitle.add(STRING.valueOf(Metadata.get('label')+' Field is updated on '+ObjAPIName));
                        
                    }Catch(Exception e){
                        ServiceMessage.add(String.valueOf(e));
                        System.debug('Error '+e);
                    }
                }else{
                    
                }
            }
            
            for(integer i = 0 ; i<StatusCode.size() ; i++){
                try{
                    if(StatusCode[i] == '204'){
                        //Custom Notification will get fired when all the picklist valueset are getting updated.    
                        //Sending Custom Notifications.
                        ServiceMessenger SM = new ServiceMessenger(NotfTitle[i] ,UpdatedValueSet[i],'notifPicklistValuesUpdated');
                                 System.debug('inside futureeee>>>>>>>>>>>>>>>>..');
                    }  
                }catch(Exception ex){
                    system.debug(ex); 
                }
            }
            //If there are any error messages.
            if(ServiceMessage.size() > 0){
                for(String Err : ServiceMessage){
                    new ServiceMessenger( Err ,'Error','notifPicklistValuesUpdated');
                } 
            }
        }
        try{
            // Upsert ConfigurationItems Records(Upsert all the Configuration Items Records irrespective of picklist valuesets are updated or not).         
            // Parse the JSON Configuration Item String to List of Configuration Item Records.              
            // Only do this if config item data is supplied
            if (LXTsOutStr != '' && LXTsDelStr != '') {     
                   
                List<ConfigurationItem__c> LXTsOut = (List<ConfigurationItem__c>) JSON.deserialize(LXTsOutStr, List<ConfigurationItem__c>.class); 
                List<ConfigurationItem__c> LXTsDel = (List<ConfigurationItem__c>) JSON.deserialize(LXTsDelStr, List<ConfigurationItem__c>.class);
                    
                // Delete existing config tools, create the new ones.    
                insert LXTsOut;
                delete LXTsDel; 
                 
                new ServiceMessenger('ConfigurationItems are upto date' ,'All the ConfigurationItems are Updated','notifPicklistValuesUpdated');    
            }
            
        } catch(Exception Ex){
            new ServiceMessenger(String.valueOf(Ex) ,'Error','notifPicklistValuesUpdated');
            System.debug('Error: '+Ex);
        }
        
    }  
    
    

}