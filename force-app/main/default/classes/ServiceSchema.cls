/////////////////////////////////////////////////////////////////////////////////////////////////////
// CLASS FOR INTROSPECTION OF THE SF ORG SCHEMA AND ITS OBJECTS
//
// Martin Little for Improved Apps
// January 2013
/////////////////////////////////////////////////////////////////////////////////////////////////////

public with sharing class ServiceSchema {  
    
    public String Diags {get; set;}                         // Diagnostics to return to clients
    

   
    // Proxy class that can be used to store the results of multiple REST calls
    // (i.e., the resulting objects de-serialised from JSON) 
    public class JSONCollectionProxy {
        public list<Object> records = new list<Object>();  //Used in 'getWeblinkDetails' method for json parsing
    }
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // OBJECT SCHEMA CALLS 
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    
    //---------------------------------------------------------------------------------------------------
    // Retrieve details of all objects in the current Org
    //---------------------------------------------------------------------------------------------------
    public Schema.DescribeSObjectResult[] getAllObjects () {
        
        Schema.DescribeSObjectResult[] results;
        Schema.DescribeSObjectResult r;
        Map<String, Schema.SObjectType> gd;
        String[] objTypes = new String[]{};
            Schema.SObjectType target;
        Integer i;
        
        // For diagnostics translations
        map<string, string> mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false); 
        
        try {           
            
            Diags = '';
            
            gd = Schema.getGlobalDescribe();
            results = new Schema.DescribeSObjectResult[]{};
                
                // Load global describe keys into an array
                for (String fieldName: gd.keySet()) {
                    objTypes.add(fieldname);  
                }
            
            
            // Loop around keys to see whether any have ID matching that entered
            for (i=0; i<objTypes.size(); i++) {
                target = gd.get(objTypes[i]);
                
                Diags += 'At ' + i + '... ';
                
                if (target != null) {
                    
                    r = target.getDescribe();
                    
                    Diags += 'Get describe null? '; 
                    Diags += r == null; 
                    Diags += '... ';
                    Diags += 'Prefix for this is: ' + r.getKeyPrefix() + '... ';
                    Diags += 'Name is: ' + r.getName() + '... ';
                    
                    if (r != null) {
                        results.add(r);
                    } 
                }
            }
            
            Diags = '';
            
        } catch (exception e) {
            Diags += mapGlbLocs.get('MessageGenericError') + ' - ' + e.getMessage() + ' - ' + Diags;
        }
        
        return results;
    }
    
    
    //---------------------------------------------------------------------------------------------------
    // Get the 3 character prefix for an object based on its name
    //---------------------------------------------------------------------------------------------------
    public static String getObjectIdByName (String objName) {
        
        String retVal;
        
        try {
            // v1.31 performance enhancements - avoid getGlobalDescribe
            List<String> objNames = new List<String>();         
            objNames.add(objName);
            
            List<DescribeSObjectResult> rs;
            rs = Schema.describeSObjects(objNames);
            retVal = rs[0].getKeyPrefix();                          
            
        } catch (exception e) {
            retVal = '';
        }
        
        return retVal;
    }
    
    
    //---------------------------------------------------------------------------------------------------
    // Get an object based on its name
    //---------------------------------------------------------------------------------------------------
    public static Schema.DescribeSObjectResult getObjectDetailsByName (String objName) {
        
        Schema.DescribeSObjectResult retVal;
        
        try {
            // v1.31 performance enhancements - avoid getGlobalDescribe
            List<String> objNames = new List<String>();         
            objNames.add(objName);
            
            List<DescribeSObjectResult> rs;
            rs = Schema.describeSObjects(objNames);
            retVal = rs[0];                          
            
        } catch (exception e) {
            retVal = null;
        }
        
        return retVal;
    }
    
    //---------------------------------------------------------------------------------------------------
    // Obtain and cache 3-letter code to object API name mappings for all objects in config item records via an asynchronous job
    //---------------------------------------------------------------------------------------------------
    @future
    public static void CacheObjectDetails () {
        
        string objJSON;
        map<string, string> mapObjs;
        Map<String, Schema.SObjectType> gd;
        
        try {     
            gd = Schema.getGlobalDescribe();
            
            // If we don't have this data already, map, serialize and store it: we want a map of non-null 3-letter codes to object API names
            mapObjs = new map<string,string>(); 
            
            for(Schema.SObjectType stype : gd.values()){
                Schema.DescribeSObjectResult r = stype.getDescribe();
                
                // Only store a mapping if the object has a 3-letter code
                if (r != null) {
                    String prefix = r.getKeyPrefix();
                    
                    if (prefix != null) {
                        
                        // SF do not guarantee that these will all be unique - so we need to error trap
                        // as we attempt to add to the map as duplicate keys are not allowed
                        try {
                            mapObjs.put(prefix, stype + '');
                        } catch (exception ex) {
                            // Do nothing if there are duplicates - hopefully rare edge cases
                        }
                    }
                }
            }   
            
            objJSON = JSON.serialize(mapObjs);
            ControllerSettings.chunkAndStoreMetadata(objJSON, 'GetObjectDetails');
            
            
        } catch (exception e) {
        }
        
        return;
    }
    
    
    //---------------------------------------------------------------------------------------------------
    // Retrieve various types of information about an object with the specified 3 character prefix
    //---------------------------------------------------------------------------------------------------
    public string objJSON {get; set;}
    public map<string, string> mapObjs;
    public Schema.DescribeSObjectResult getObjectDetails (String objId) {
        
        Schema.DescribeSObjectResult retVal;
        Map<String, Schema.SObjectType> gd;
        
        try {     
            gd = Schema.getGlobalDescribe();
            
            // Get object lookup data from configuration items if we have it:
            // Check we haven't retrieved it already (as this costs SOQL)
            if (objJSON == '' || objJSON == null) {
                objJSON = ControllerSettings.getStoredMetadata('GetObjectDetails');
            }
            
            if (objJSON == '') {                                    
                // If we don't have this data already, map, serialize and store it: we want a map of non-null 3-letter codes to object API names
                mapObjs = new map<string,string>(); 
                
                for(Schema.SObjectType stype : gd.values()){
                    Schema.DescribeSObjectResult r = stype.getDescribe();
                    
                    // Only store a mapping if the object has a 3-letter code
                    if (r != null) {
                        String prefix = r.getKeyPrefix();
                        
                        if (prefix != null) {
                            
                            // SF do not guarantee that these will all be unique - so we need to error trap
                            // as we attempt to add to the map as duplicate keys are not allowed
                            try {
                                mapObjs.put(prefix, stype + '');
                            } catch (exception ex) {
                                // Do nothing if there are duplicates - hopefully rare edge cases
                            }
                        }
                    }
                }   
                
                objJSON = JSON.serialize(mapObjs);
                ControllerSettings.chunkAndStoreMetadata(objJSON, 'GetObjectDetails');
                
            } else {
                // If we've already stored the object lookup data, convert it to a map if not already done
                if (mapObjs == null) {      
                    mapObjs = (map<string,string>) JSON.deserialize(objJSON, map<string,string>.class);
                }
            }        
            
            
            // Having done this, obtain the required data 
            string objName = mapObjs.get(objId);
            retVal = gd.get(objName).getDescribe(); 
            
            
        } catch (exception e) {
            try {
                map<string, string> mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false);
                Diags += mapGlbLocs.get('MessageGenericError') + ' - ' + e.getMessage() + ' - ' + objId;
            } catch (exception ex) {
                Diags += 'ERROR: - ' + e.getMessage() + ' - ' + objId;
            }
        }
        
        return retVal;
    }
    
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // LAYOUT METADATA CALLS
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    
    //---------------------------------------------------------------------------------------------------
    // Returns a boolean indicating whether REST operations are possible (a proxy for whether a remote 
    // site record exists in the org)
    //---------------------------------------------------------------------------------------------------
    public static boolean restTest() {
        
        boolean retVal;
        string MetadataJSON = '';
        
        try {
            MetadataJSON = toolingAPISOQL('SELECT id, url from weblink'); 
            retVal = true;
            
        } catch (exception e) {
            MetadataJSON = e.getMessage();
            retVal = false;
        }
        
        return retVal;
    }
    
    
    
    //---------------------------------------------------------------------------------------------------
    // Underlying metadata query / call handlers
    //---------------------------------------------------------------------------------------------------
    private static final string APIVersion = 'v53.0';
    
    
    // Underlying REST API call handler
    public static String restGet(String endPoint, String method, String sid) {
        Http h = new Http();
        HttpRequest hr = new HttpRequest();
        hr.setHeader('Authorization', 'Bearer ' + sid);
        hr.setTimeout(60000);
        hr.setEndpoint(endPoint);
        hr.setMethod(method);
        HttpResponse r = h.send(hr);
        return r.getBody();
    }
    
    // Make a tooling API REST query returning JSON by specifying a SOQL query string
    public static String toolingAPISOQL(String query) {
        String baseURL = URL.getOrgDomainURL().toExternalForm();
        return restGet( baseURL + '/services/data/' + APIVersion + '/tooling/query?q='+ (query.replace(' ', '+')), 'GET', UserInfo.getSessionId());
    } 
    
    // Make a tooling API REST query returning JSON by providing a query ID (cursor)
    private static String toolingAPIQueryId(String qid) {
        String baseURL = URL.getOrgDomainURL().toExternalForm();
        qid=qid.split('query')[1];
        system.debug('qid '+qid);
        return restGet( baseURL + '/services/data/' + APIVersion + '/tooling/query'+qid, 'GET', UserInfo.getSessionId());
    }
    
    // Make a REST call returning JSON to obtain page layout custom section information for a named object
    private static String UIAPISOQL(String ObjectAPIName) {
        
        String baseURL = URL.getOrgDomainURL().toExternalForm();
        Schema.DescribeSObjectResult sObj;
        List<Schema.RecordTypeInfo> RTIs;
        boolean hasRecordTypes;
        
        
        string retVal = '';
        
        try {
            // 1.42.18+ : extending to deal with record types, as original call was returning 'default' layout's section data only:
            // FOR EACH TYPE, REQUEST INCLUDING ?recordTypeId=x     
            // ...then concatenate results
            sObj = ServiceSchema.getObjectDetailsByName(ObjectAPIName);
            
            if (sObj != null) {
                RTIs = sObj.getRecordTypeInfos();
                hasRecordTypes = RTIs.size() > 1;
                
                if (! hasRecordTypes) {
                    // No types - just get layout custom section info by object name
                    retVal = restGet( baseURL + '/services/data/' + APIVersion + '/ui-api/layout/' + ObjectAPIName, 'GET', UserInfo.getSessionId());
                    
                } else {
                    // Types in play: iterate to get layout custom section info type by type
                    retVal = '[';
                    
                    for (Schema.RecordTypeInfo typ : RTIs) {
                        
                        retVal += restGet( baseURL + '/services/data/' + APIVersion + '/ui-api/layout/' + ObjectAPIName + '?recordTypeId=' + typ.getRecordTypeId(), 'GET', UserInfo.getSessionId());
                        retVal += ',';
                    }
                    
                    retVal = retVal.substring(0, retVal.length() -1);
                    retVal += ']';
                }
                
                
            } else {
                // Unknown object API name supplied
            }
            
        } catch (exception e) {
            // General error
        }
        
        return retVal;
        
    } 
    
    
    //---------------------------------------------------------------------------------------------------
    // Retrieve and store details of ALL custom links in the current org
    //---------------------------------------------------------------------------------------------------
    public static string getWeblinkDetails() {
        
        //  string MetadataJSON = toolingAPISOQL('SELECT id, url from weblink');
        //  return ControllerSettings.chunkAndStoreMetadata(MetadataJSON, 'GetWeblinkDetails');  
        
        // Make an initial call to obtain weblinks: this may or may not return all items
        string MetadataJSON = toolingAPISOQL('SELECT id, url from weblink');
        system.debug(MetadataJSON);
        Map<String,Object> parsedjson = (Map<String,Object>) JSON.deserializeUntyped(MetadataJSON);
        Map<String,Object> parsedjson2 = parsedjson;
        
        // Note how many records were returned by the above call
        integer size = (integer)parsedjson.get('size');
        
        // Also note the details of any query cursor (a query ID)
        string queryCursor = parsedjson.get('nextRecordsUrl')+'';
        
        
        // Parse the JSON from the initial weblink call into a list of objects
        list<Object> recs = new list<Object>();
        recs = (list<Object>)parsedjson.get('records');     
        
        
        // Pump these objects into a class for later re-serialising to JSON
        JSONCollectionProxy recordlist = new JSONCollectionProxy();
        for(Object rec : recs){
            recordlist.records.add(rec);
        }
        
        integer i=1;
        // Loop while query results state there are more records to be obtained
        while(parsedjson.get('done')+''=='false' && i<100){
            i++;
            // Use the last-specified query cursor to obtain available records
            MetadataJSON = toolingAPIQueryId(queryCursor);
            
            // Store these, as above, in output objects/records collection
            parsedjson = (Map<String,Object>) JSON.deserializeUntyped(MetadataJSON);
            recs = (list<Object>)parsedjson.get('records');
            for(Object rec : recs){
                system.debug(rec);
                recordlist.records.add(rec);
            }
            
            // Check for the next cursor at which to query
            queryCursor = parsedjson.get('nextRecordsUrl')+'';
        }
        
        // Once the REST queries state all records have been obtained (done = true), serialise our
        // collection, as stored in the proxy, and chunk this into configuration items
        return ControllerSettings.chunkAndStoreMetadata(json.serialize(recordlist), 'GetWeblinkDetails');
        
    }
    
    
    //---------------------------------------------------------------------------------------------------
    // Get JSON representing granular content of page layouts for a given object by API name
    //---------------------------------------------------------------------------------------------------
    public static String getLayoutContentForObject(string ObjectAPIName) {
        
        string retVal;
        
        try {
            retVal = UIAPISOQL(ObjectAPIName);
            
        } catch (exception e) {
            retVal = 'Error (Get Layout Content for Object "' + ObjectAPIName + '"): ' + e.getMessage();
        }
        
        return retVal;
    }
    
    
    //---------------------------------------------------------------------------------------------------
    // Get layout assignments for a given object type, as inferred from recordId.
    // This call checks for existence of record types on the relevant object:
    // If there are types, the call returns layouts for the current type only.
    
    // Optionally, the call can be filtered to return the layouts for the calling user's profile only: 
    // If filterToCurrentProfile is false, layout assignments for all profiles for the object represented by recordId are returned.
    
    // Similarly, optionally filter by the record type of the record passed in, returning layouts for that type only as opposed
    // to all layouts applicable to the record's object.
    //---------------------------------------------------------------------------------------------------
    public static String getProfileLayoutsByRecordId(string recordId, boolean filterToCurrentProfile, boolean filterToCurrentRType) {
        
        string retVal = '';     
        ServiceSchema svsS = new ServiceSchema();
        Schema.DescribeSObjectResult sObj;
        string oName;
        string oNS;
        sObject obj;
        string RTyp;
        List<Schema.RecordTypeInfo> RTIs;
        boolean hasRecordTypes;
        string strQ = '';
        string APIResult;
        
        
        try {
            // Check whether record types are in play
            sObj = svsS.getObjectDetails(recordId.subString(0,3)); 
            
            // If we don't get an object for the record ID, we have a problem
            if (sObj == null) {
                retVal = 'Error (Get Profile Layout by Record ID): failed getting object information for record ' + recordId;
                
            } else {
                
                // Obtain correct "name" to use in queries: for standard object, it's just the object name
                oName = sObj.getName();        
                
                // Not so, however, custom objects: for these we need to get the ID of the custom object definition (a metadata API record)...
                if (oName.endsWith('__c')) {
                    try {
                        
                        // Chop the __c as custom object info is not stored with this: 
                        // Tooling API's CustomObject.DeveloperName excludes __c suffix - as it's custom objects that we're querying! 
                        
                        oName = oName.substring(0, oName.length() - 3);
                        
                        /*
It's imperative we get the name of the object "right" for the purposes of the following query:
This means: we want the developer name WITHOUT any namespace, 
however (1.41.28+) we still need namespace to query reliably

Unfortunately, object Local Names, whilst stripped of namespace in the orgs in which they are developed, are
still fully qualified once deployed (so no difference between getName and getLocalName!)

Fortunately, we know the following (from SF advice on creating objects):
"The Object Name must not contain two consecutive underscores"

SO: if we still have a double underscore, it means we have namespace__objectname
*/                      
                        
                        if (oName.indexOf('__') != -1) {
                            string[] objNameParts = oName.split('__');
                            oNS = objNameParts[0];
                            oName = objNameParts[1];
                            
                        } else {
                            oNS = '';
                            oName = oName;
                        }
                        
                        strQ =  'SELECT Id FROM CustomObject ';
                        strQ += 'WHERE DeveloperName = \'' + oName + '\' ';
                        
                        // v1.42.8+ : turns out that 'history' objects for custom objects have their own
                        // custom object records, which will be identical in all but Description from the 
                        // perspective of the tooling API (which cannot reach other differentiators, such as object full name):
                        // SO: we must filter these records out here
                        
                        strQ += 'AND Description != \'Historical Data for ' + oName + '\' '; 
                        strQ += 'AND NamespacePrefix = \'' + oNS + '\'';
                        
                        APIResult = toolingAPISOQL(strQ);
                        
                        
                        // If this returned a record, we need to use the ID...
                        JSONParser parser = JSON.createParser(APIResult);
                        
                        while (parser.nextToken() != null) {
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'Id')) {
                                parser.nextToken();
                                oName = parser.getText();
                            }
                        }                       
                        
                    } catch (exception e) {}
                    APIResult = '';
                    
                }   
                
                // Check whether record types are in play
                RTIs = sObj.getRecordTypeInfos();
                hasRecordTypes = RTIs.size() > 1;
                
                if (hasRecordTypes && filterToCurrentRType == true) {
                    // If so, and filter by record type was requested, query with record type                
                    try {
                        
                        // Here, we need the fully qualified name of the object whose record type ID is sought   
                        strQ = 'SELECT RecordTypeId  FROM ' + sObj.getName() + ' WHERE id = \'' + recordId + '\'';
                        
                        obj = database.query(strQ);
                        RTyp = '' + obj.get('RecordTypeId');
                    } catch (exception e) {}
                    
                    
                    // Adjust for records which, despite object having a type, do not have an ID stored against them
                    if (RTyp == null || RTyp + '' == 'null') {
                        strQ = 'SELECT LayoutId, Layout.Name, ProfileId, RecordTypeId, TableEnumOrId FROM ProfileLayout WHERE TableEnumOrId = \'' + oName + '\'  AND RecordTypeId = null';      
                    } else {
                        strQ = 'SELECT LayoutId, Layout.Name, ProfileId, RecordTypeId, TableEnumOrId FROM ProfileLayout WHERE TableEnumOrId = \'' + oName + '\'  AND RecordTypeId = \'' + RTyp + '\'';  
                    }                           
                    if (filterToCurrentProfile == true) {
                        strQ += ' AND ProfileId = \'' + UserInfo.getProfileId() + '\'';
                    }       
                    
                    APIResult = toolingAPISOQL(strQ);
                    
                } else {
                    // If not, query by profile and object alone
                    strQ = 'SELECT LayoutId, Layout.Name, ProfileId, RecordTypeId, TableEnumOrId FROM ProfileLayout WHERE TableEnumOrId = \'' + oName + '\'';
                    if (filterToCurrentProfile == true) {
                        strQ += ' AND ProfileId = \'' + UserInfo.getProfileId() + '\'';
                    }       
                    
                    APIResult = toolingAPISOQL(strQ);     
                    
                }
                
                
                // Additional check for PersonAccounts:
                // Record Id and object name are identical / will not appear different (indeed the object name IS account)
                // but the metadata query has to be run with PersonAccount as the table name.
                // So: if we've attempted Account and received no results, try with PersonAccount:
                
                if (oName == 'Account' && APIResult.indexOf('"size":0') != -1 ) {
                    strQ = strQ.replace('WHERE TableEnumOrId = \'Account\'', 'WHERE TableEnumOrId = \'PersonAccount\'');
                    APIResult = toolingAPISOQL(strQ); 
                }                              
                
                
                retVal = APIResult;
                retVal = retVal.subString(retVal.indexOf('['));
                retVal = retVal.substring(0, retVal.length() - 1);
                
            }
            
        } catch (exception e) {
            retVal = 'Error (Get Profile Layout by Record ID for record "' + recordId + '"): ' + e + ': Query used was: ' + strQ + ': Additional diagnostics: ' + svsS.Diags;
        }
        
        
        // Return details
        return retVal;
    }
    
    
    //---------------------------------------------------------------------------------------------------
    // Get layout name for a record type: This call assumes there ARE record types for the relevant object
    //---------------------------------------------------------------------------------------------------
    public static String getLayoutNameByRecordTypeId(Id recordTypeId) {
        String body = toolingAPISOQL('SELECT Layout.Name FROM ProfileLayout WHERE ProfileId = \'' + UserInfo.getProfileId() + '\' AND RecordTypeId = \'' + recordTypeId + '\'');
        String name = body.substringBetween('"Name":"', '"');
        return name;
    }
    
    
    //---------------------------------------------------------------------------------------------------
    // Attempt to return ALL metadata layout records (not 100% reliable as not all may be returned)
    //---------------------------------------------------------------------------------------------------
    public static String getAllProfileLayouts() {
        
        // 1.39.11: adding (ostensibly pointless) non-filtering where clause, as without
        // this touch we don't seem to get all records!
        String retVal = toolingAPISOQL('SELECT LayoutId, Layout.Name, ProfileId, RecordTypeId, TableEnumOrId FROM ProfileLayout WHERE RecordTypeId = null OR RecordTypeId != null');
        system.debug(retVal);
        retVal = retVal.subString(retVal.indexOf('['));
        retVal = retVal.substring(0, retVal.length() - 1);
        return retVal;
    }
    
    
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // WRAPPERS TO LAYOUT METADATA CALLS - FOR BULK / BATCH OPS
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    
    //---------------------------------------------------------------------------------------------------
    // Cue an asynchronous job to obtain requested layout metadata (pass object 3 letter codes list)
    //---------------------------------------------------------------------------------------------------
    @future(callout=true)
    public static void BatchGetLAMetadata (string[] ObjectIDs) { 
        string localDiags = '';
        ServiceInteractions svsI = new ServiceInteractions();
        
        try {
            string missingLayout;
            string allLayouts = '';
            string chunkResult;
            integer i;
            JSONParser parser;
            ConfigurationItem__c[] CIs;
            integer count;          
            
            
            localDiags += 'Get Layout Metadata: entry with objects: ' + ObjectIDs + '... ';
            
            
            for (i=0; i < ObjectIDs.size(); i++) {
                // Request metadata for ALL types applicable to the current record's object
                
                localDiags += 'Seeking layout metadata for ' + ObjectIDs[i] + '... ';
                missingLayout = ServiceSchema.getProfileLayoutsByRecordId(ObjectIDs[i], false, false);
                
                // Append this JSON to those records - but only if missing layout info is valid JSON
                try {
                    // This should only succeed if JSON is valid
                    parser = JSON.createParser(missingLayout);
                    parser.nextToken();
                    
                    if (missingLayout.indexOf('"errorCode"') == -1) {
                        // Need additional checks here to make sure we don't store error messages
                        // as opposed to layout info!
                        allLayouts = ControllerLUXOps.concatenateJSON(missingLayout, allLayouts);
                        
                    } else {
                        localDiags += 'Error: invalid JSON layout metadata for: ' + ObjectIDs[i] + ': ' +  missingLayout;
                        svsI.logInteraction(3, localDiags, '', null, null, null, null, null);
                        return;
                    }
                    
                } catch (exception ex) {
                    localDiags += 'Error: JSON unparsable for : ' + ObjectIDs[i] + ': ' +  missingLayout;
                    svsI.logInteraction(3, localDiags, '', null, null, null, null, null);                    
                    return;
                }
                
            }
            
            
            // Delete any existing data
            try {    
                CIs = [SELECT Id FROM ConfigurationItem__c WHERE ActionCode__c = 'GetSFPageLayouts'];
                count = CIs.size();
                delete CIs;             
                localDiags += 'Deleted ' + count + ' Page Layout Assignment records... ';
                
                
            } catch (exception e) {     
                localDiags += 'Error: failed deleting existing metadata: ' + e.getMessage();       
                svsI.logInteraction(3, localDiags, '', null, null, null, null, null);
                return;
            }
            
            
            
            // Save the new data                
            chunkResult = ControllerSettings.chunkAndStoreMetadata(allLayouts, 'GetSFPageLayouts');
            
            if (chunkResult == '') {
                // All is well
                localDiags += 'Metadata obtained and stored for ' + ObjectIDs.size() + ' objects... ';
                localDiags = 'SUCCESS: ' + localDiags;
                
            } else {
                localDiags += 'Error: Metadata obtained but failed to store';
                svsI.logInteraction(3, localDiags, '', null, null, null, null, null);
                return;
            }
            
            
            // Log an interaction recording details of operation success
            svsI.logInteraction(5, localDiags, '', null, null, null, null, null);
            
            // Log an additional interaction recording the objects which were sought in this operation
            svsI.logInteraction(22, ObjectIds.toString(), '', null, null, null, null, null);
            
        } catch (exception e) {     
            localDiags += 'Unexpected error creating metadata: ' + e.getMessage();    
            svsI.logInteraction(3, localDiags, '', null, null, null, null, null);   
        }
        
        return;
    }
    
    
    
    //---------------------------------------------------------------------------------------------------
    // Cue an asynchronous job to obtain requested custom section metadata (pass an object 3 letter code)
    //---------------------------------------------------------------------------------------------------
    @future(callout=true)
    public static void BatchGetCSMetadata (string ObjectID) { 
        
        string localDiags = '';
        string MDJSON1;
        boolean validJSON;
        boolean isError = false;
        string chunkResult;
        ServiceInteractions svsI = new ServiceInteractions();
        ConfigurationItem__c[] CIs;
        string ActionCode;
        integer count;          
        string objJSON;
        map<string,string> mapObjs;
        
        
        try {
            localDiags += 'Get custom section metadata - entry... ';
            
            // Obtain the list of objects in the current org
            objJSON = ControllerSettings.getStoredMetadata('GetObjectDetails');
            mapObjs = (map<string,string>) JSON.deserialize(objJSON, map<string,string>.class);   
            
            
            try {
                ActionCode = 'GetLayoutContentForObject_' + ObjectID;
                CIs = [SELECT Id FROM ConfigurationItem__c WHERE ActionCode__c = :ActionCode];
                count = CIs.size();
                delete CIs;             
                localDiags += 'Deleted ' + count + ' Custom Section Layout Content records... ';
            } catch (exception ex) {}
            
            
            ObjectID = mapObjs.get(ObjectID);
            localDiags += 'Seeking layout content for ' + ObjectID + '... ';
            
            MDJSON1 = ServiceSchema.getLayoutContentForObject(ObjectID);
            
            if (MDJSON1.length() > 1 && MDJSON1.indexOf('"errorCode"') == -1) {
                // Need additional checks here to make sure we don't store error messages
                // as opposed to layout info!
                validJSON = true;
            }
            
            if (validJSON == true) {
                chunkResult = ControllerSettings.chunkAndStoreMetadata(MDJSON1, 'GetLayoutContentForObject_' + ObjectID);
                
                if (chunkResult == '') {
                    // All is well
                    localDiags += 'Done... ';
                    
                } else {
                    localDiags += 'Error storing results of layout content metadata call for ' + ObjectID + ' - ' + chunkResult;
                    isError = true;
                }
                
            } else {
                localDiags += 'Error in layout content metadata call for ' + ObjectID + ' - bad JSON - ' + MDJSON1;
                isError = true;
            }
            
            
            if (! isError) {
                localDiags = 'SUCCESS: ' + localDiags;
                svsI.logInteraction(5, localDiags, '', null, null, null, null, null);     
                
            } else {
                svsI.logInteraction(3, localDiags, '', null, null, null, null, null);
            }           
            
            
            
        } catch (exception e) {
            localDiags += 'Error obtaining custom section metadata: ' + e.getMessage() + '... ';
            svsI.logInteraction(3, localDiags, '', null, null, null, null, null);
        }
        
        return;
    }
    
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // CUSTOM OBJECT METADATA (AS OPPOSED TO SCHEMA) CALLS
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    
    //---------------------------------------------------------------------------------------------------
    // Get the metadata object ID of a named custom object (i.e., the value that will appear for it in ProfileLayout.TableOrEnumId)    
    // NB: CustomObjectAPIName is API name without namespace
    // This version queries metadata via tooling API to obtain the ID
    //---------------------------------------------------------------------------------------------------
    /*
public static String getCustomObjectIdFromAPI(string CustomObjectAPIName) {

string retVal;

// We are likely to want to query with an API name, but tooling API stores object data without name suffixes
// (as object name, NOT object API name)
string CustomObjectName = CustomObjectAPIName;

try {       
if (CustomObjectName.endsWith('__c')) {CustomObjectName = CustomObjectName.substring(0, CustomObjectName.length() - 3);} 
retVal = toolingAPISOQL('SELECT Id FROM CustomObject WHERE DeveloperName = \'' + CustomObjectName + '\'');

if (retVal.substringBetween('"Id":"', '"') != null) {
retVal = retVal.substringBetween('"Id":"', '"');
}

} catch (exception e) {
retVal = '';
}

return retVal;
}
*/
    
    
    //---------------------------------------------------------------------------------------------------
    // Get the metadata object ID of a named custom object (i.e., the value that will appear for it in ProfileLayout.TableOrEnumId)    
    // NB: CustomObjectAPIName is API name without namespace
    // This version queries supplied metadata JSON (as previsouly obtained via API) to locate the ID
    // NB: 1.54.8+ : in rare cases (sometimes where object has history tracking enabled) there may be more than 1
    // match for Object API name - in which case we return a comma separated list of IDs, not simply the 1 matching one
    //---------------------------------------------------------------------------------------------------
    public static String getCustomObjectIdFromJSON(string CustomObjectAPIName, string MDJSON) {
        
        string retVal = '';
        
        try {
            // We are likely to want to query with an API name, but tooling API stores object data without name suffixes
            // (as object name, NOT object API name)
            string CustomObjectName = CustomObjectAPIName;
            string oName;
            string oNS;
            
            if (CustomObjectName.endsWith('__c')) {CustomObjectName = CustomObjectName.substring(0, CustomObjectName.length() - 3);}
            
            /*
            It's imperative we get the name of the object "right" for the purposes of the following lookup:
            This means: we want the name WITHOUT any namespace.
            Unfortunately, object Local Names, whilst stripped of namespace in the orgs in which they are developed, are
            still fully qualified once deployed (so no difference between getName and getLocalName!)
            
            Fortunately, we know the following (from SF advice on creating objects):
            "The Object Name must not contain two consecutive underscores"
            
            SO: if we still have a double underscore, remove this and the preceding namespace...
            */                      
            
            if (CustomObjectName.indexOf('__') != -1) {
                
                string[] objNameParts = CustomObjectName.split('__');
                oNS = objNameParts[0];
                oName = objNameParts[1];
                
            } else {
                oNS = '';
                oName = CustomObjectName;
            }         
            
            JSONParser parser = JSON.createParser(MDJSON);
            string currentId;
            string currentObjName;   
            string currentNS;
            
            
            // Loop through the JSON
            while (parser.nextToken() != null) {
                
                // Reset located keys at start of each record in the JSON
                if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                    
                    // If, however, we found the desired object info in the previous record, return this...
                    if (currentObjName != null && currentNS != null) {
//retVal = currentId;
//break;

retVal += currentId + ',';
currentObjName = null;
currentId = null;  
currentNS = null;                     

                    } else {
                        currentObjName = null;
                        currentId = null;  
                        currentNS = null;                     
                    }
                }
                
                
                // Examine any field name we come across in the JSON
                if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
                    
                    // If we find an ID, store this
                    if (parser.getText() == 'Id') {
                        parser.nextValue();
                        currentId = parser.getText();
                    }
                    
                    // If we find the developer name of an object, check whether it's the one we want
                    if (parser.getText() == 'DeveloperName') {
                        parser.nextValue();
                        
                        if (parser.getText() == oName) {
                            // If it is the one we want, store its name as a marker that we found the desired JSON record
                            currentObjName = parser.getText();
                            
                        } else {
                            currentObjName = null;
                        }
                    }
                    
                    
                    if (parser.getText() == 'NamespacePrefix') {
                        parser.nextValue();
                        
                        if (parser.getText() == oNS || (oNS == '' && parser.getText() + '' == 'null')) {
                            // If it is the one we want, store its name as a marker that we found the desired JSON record
                            currentNS = parser.getText();
                            
                        } else {
                            currentNS = null;
                        }
                    }
                    
                }
            }
            
            
            // In case the item we found happened to be the very last entry in the JSON
            if (currentObjName != null && currentNS != null) {
//retVal = currentId;             
retVal += currentId + ',';             
            }

if (retVal.indexOf(',') != -1) {
    retVal = retVal.substring(0, retVal.length()-1);
}
            
            
        } catch (exception e) {
            retVal = '';
        }
        
        return retVal;
    }
    
    
    //---------------------------------------------------------------------------------------------------
    // Get the metadata object JSON for ALL custom objects in the current org
    //---------------------------------------------------------------------------------------------------
    public static string getCustomObjects() {
        
        string retVal;
        
        try {       
            retVal = toolingAPISOQL('SELECT Id, DeveloperName, NamespacePrefix FROM CustomObject ORDER BY DeveloperName');
            
        } catch (exception e) {
            retVal = 'Error (Get Custom Object Metadata): ' + e.getMessage();
        }
        
        return retVal;
        
    }
    
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // APP / TAB METADATA CALLS
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    
    //---------------------------------------------------------------------------------------------------
    // Get a list of all apps
    //---------------------------------------------------------------------------------------------------
    public static string getAppListing() {
        string retVal;
        
        try {       
            retVal = toolingAPISOQL('SELECT Id, Label, Description, namespacePrefix, UiType FROM CustomApplication');
            
        } catch (exception e) {
            retVal = 'Error (Get App Listing): ' + e.getMessage();
        }
        
        return retVal;
        
    }
    
    
    //---------------------------------------------------------------------------------------------------
    // Get the tabs within a specified app
    //---------------------------------------------------------------------------------------------------
    public static string getTabListing(string AppId) {
        string retVal;
        
        try {       
            retVal = toolingAPISOQL('SELECT metadata, Id, Label, namespacePrefix FROM CustomApplication WHERE Id =\'' + AppId + '\'');
            
        } catch (exception e) {
            retVal = 'Error (Get Tab Listing): ' + e.getMessage();
        }
        
        return retVal;
        
    }
    
    
    //---------------------------------------------------------------------------------------------------
    // Get ALL known tabs
    //---------------------------------------------------------------------------------------------------
    public static string getAllTabs() {
        string retVal;
        
        try {       
            String baseURL = URL.getOrgDomainURL().toExternalForm();
            retVal = restGet( baseURL + '/services/data/' + APIVersion + '/tabs', 'GET', UserInfo.getSessionId());  
            
        } catch (exception e) {
            retVal = 'Error (Get Tab Listing): ' + e.getMessage();
        }
        
        return retVal;
        
    }
    
    //---------------------------------------------------------------------------------------------------
    // For a given object, populate a given field's picklist values
    //---------------------------------------------------------------------------------------------------
    // NB: as this was primarily designed for configuration item processing as the product initialises,
    // JSON strings of config item records to create / delete can also be supplied: if these strings
    // are empty, no record upserts are made.
    //
    // ObjAPIName : API Name of object whose pick list(s) are to be populated
    // PickListInfo : map, each of whose elements is a field API name mapped to picklist values to add to said field
    
    @future(callout=true)
    public static void UpdateValueSet(string ObjAPIName , map<string,string> PickListInfo , String LXTsDelStr , String LXTsOutStr){
        
        List<String> ServiceMessage = new List<String>();           // List Of error messages which will fire in the run.
        map<string,string> finalMap = new map<string,string>();     // Final map contains all the ValueSets.
        map<string,object> Ids;
        Map<String,String> NewValueSetMapForCustomNotific = new Map<String,String>(); 
        List<String> StatusCode = new List<String>();               // List of final status code for sending Notification one by one.
        List<String> NotfTitle = new List<String>();                // List of custom notification body.
        List<String> UpdatedValueSet = new List<String>();          // List of all the new ValueSet added. 
        
        EntityDefinition  ObjectId;                                 // Getting the Object Id (For Custom object we will get Id and for Standard Rec we will get Object name).
         
        
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
                        String GetBodyFieldId = restGet(URL.getOrgDomainURL().toExternalForm() +soqlQuery, 'GET', System.UserInfo.getSessionId());
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
                        String GetBodyOldValueset = restGet(EndPoint, 'GET', System.UserInfo.getSessionId());
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