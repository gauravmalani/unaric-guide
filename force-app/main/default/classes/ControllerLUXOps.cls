/////////////////////////////////////////////////////////////////////////////////////////////////////
// WRAPPER SERVICES FOR LUX COMPONENTS
//
// Martin Little for Improved Apps
// November 2016
/////////////////////////////////////////////////////////////////////////////////////////////////////

global with sharing class ControllerLUXOps {
    
/////////////////////////////////////////////////////////////////////////////////////////////////////
// EXPERIMENTAL CODE - NOT IN USE
/////////////////////////////////////////////////////////////////////////////////////////////////////


@AuraEnabled
public static string relationBuilderSave (string SubjectId, string RelativesJSON) {
    
    string retVal = '';
    
    try {
        
        List<ServiceIHLists.ListingItem> LIs;
        
        if (RelativesJSON != '') {
            LIs = (List<ServiceIHLists.ListingItem>) JSON.deserialize(RelativesJSON, List<ServiceIHLists.ListingItem>.class);
        } else {
            LIs = new List<ServiceIHLists.ListingItem>();
        }
        
        retVal = 'Server action: save relatives of "' + SubjectId + '" (' + LIs.size() + ' items) - to do...';
        
    } catch (exception e) {
        retVal = 'Error saving relationships (relationBuilderSave): ' + e.getMessage();
    }
    
    return retVal;
}


// POSSIBLE MATRIX / FLEXIBLE GRID COMPONENT
@AuraEnabled
public static string getMatrix (string XObject, string XField) {
    
    string retVal = '';
    NameValuePair NVP;
    NameValuePair[] NVPs = new NameValuePair[]{};

    ServiceIHLists.ListingItem[] LIs = new ServiceIHLists.ListingItem[]{};
    ServiceIHLists.ListingItem LI;
    HelpTopic__c[] HTs;
    string strSOQL;
    
    try {
        
        // Get the pick list values representing matrix 'X' dimension / columns
        Schema.DescribeSObjectResult sObjX = ServiceSchema.getObjectDetailsByName (XObject);
        map<string,Schema.SObjectField> flds = sObjX.fields.getMap();
        Schema.DescribeFieldResult fieldResult = flds.get(XField).getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        for( Schema.PicklistEntry pickListVal : ple){
            NVP = new NameValuePair('MatrixColumnLabels', pickListVal.getLabel() , pickListVal.getValue());
            NVPs.add(NVP);
        }    
        retVal = concatenateJSON(retVal, JSON.serialize(NVPs));
        
        
        // Get the topic object detais representing the 'Y' dimension / rows 
        /*
        string tagFilterInfo = 'a000W00000rEuNQQA0^a000W00000rEuNQQA0^ALL';
        ControllerIHQAMSettings cIHQ = new ControllerIHQAMSettings(true);
        retVal = concatenateJSON(retVal, getTaggedItems (cIHQ, tagFilterInfo));
        */
        
        strSOQL = 'SELECT Id, Name, Summary__c, CustomStyle__c, ' + XField + ' FROM HelpTopic__c ';
        strSOQL += 'WHERE ' + XField + ' != \'New\' AND ' + XField + ' != null LIMIT 20';
        sObject SO;     
        HTs = database.query(strSOQL);      
        for (HelpTopic__c HT : HTs) {
            LI = new ServiceIHLists.ListingItem();
            
            LI.Id = HT.Id;
            LI.Label = HT.Name;
            LI.Title = HT.Summary__c;   
            LI.StyleClass = HT.CustomStyle__c;                                              
            LI.Icon = '';
            LI.IconLabel = '';
            LI.IconTitle = '';
            
            SO = HT;
            LI.ActionCode = '' + SO.get(XField);
            
            LIs.add(LI);
        }
        
        retVal = concatenateJSON(retVal, JSON.serialize(LIs));
        
    } catch (exception e) {
        retVal = 'getMatrix - error: ' + e.getMessage();
    }
    
    return retVal;
}
    
    
    

    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Wrapper / control value classes
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    // For use in marshalling (e.g.) select options whose values are not otherwise tied to sObject records
    public class NameValuePair {
        
        public NameValuePair(string VS, string N, string V) {
            this.ValueSet = VS;
            this.Name = N;
            this.Value = V;
        }
        public string Name {get; set;}
        public string Value {get; set;}
        public string ValueSet {get; set;}      // "Set" to which this value belongs (e.g "target" select control)
    }
    
    
    // For sending custom field info to LUX help topic detail view:
    // The class extends the custom field by adding details of its underlying value for a specified record
    public class CustomFieldInfo {
        
        public CustomFieldInfo(Schema.FieldSetMember CF, sObject Rec){
            this.CustomField = CF;
            this.Val = Rec.get(CF.fieldPath);
        }       
        public Schema.FieldSetMember CustomField {get; set;}
        public object Val {get; set;}
    }

    // For Autoform component / layout building
    public class IALayout {
        public list<IALayoutSection> Sections {get; set;}
        public IALayout() {
            Sections = new IALayoutSection[]{};
        }
    }
    public class IALayoutSection {
        public Metadata.LayoutSection Section {get; set;}
        public list<IALayoutRow> Rows {get; set;}
        public boolean Expanded {get; set;}                
        public integer ColumnCount {get; set;}
        public string ItemClass {get; set;}        
        public boolean HasRows {get; set;}
        
        // Marker asserting that layout contains only system read only fields (c.f. IALayoutItem)
        public boolean SROOnly {get; set;}
        public IALayoutSection() {
            Rows = new IALayoutRow[]{};
            
            // 'Safe' defaults...
            SROOnly = false;
            Expanded = false;
            ColumnCount = 2;   
            HasRows = true; 
            ItemClass = '';
        }
    }
    public class IALayoutRow {
        public string Id {get; set;}
        public list<IALayoutItem> Items {get; set;}
        public string ItemClass {get; set;}
        
        public IALayoutRow() {
            Items = new IALayoutItem[]{};
            ItemClass = '';
        }
    }
    public class IALayoutItem {
        public Metadata.LayoutItem Item {get; set;}
        public string FieldLabel {get; set;}
        public string StyleClass {get; set;}            // This CSS class is for (eg) topic custom style
        public string ItemClass {get; set;}             // This CSS class is for additional 'utility' style marks
        public boolean HelpAvailable {get; set;}
        public boolean isDirty {get; set;}
        public HelpTopic__c Topic {get; set;}
        public HelpedElement__c Element {get; set;}
        
        // True for certain system fields which are always read only, even if layout 
        // designed by org's admin states otherwise
        public boolean SpecialReadOnly {get; set;}

        // Holds result of 'isUpdateable' call for the field underlying this LayoutItem at SCHEMA level, as opposed to 
        // its 'behavior' member, which describes only the 'read only' flag on the field on the particular LAYOUT  
        public boolean SchemaUpdateable {get; set;}

        
        // Derivative editability values for conveniece / necessity in LWC mark-up:     
        public boolean IsEditable {get; set;}               // Is item an editable field? (item behavior not r/o, schema crud editable, special r/o = false)
        public boolean IsEditableLocally {get; set;}        // Slot to hold locally calculated editability:
                                                            // = IsEditable + local autoform settings allow edits

        
        public IALayoutItem() {
            isDirty = false;  
            ItemClass = '';          
        }
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // PROVISION FOR EXTENSION TOOLS (DEFINED VIA CONFIGURATION ITEM RECORDS)
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    @AuraEnabled
    public static string doExtensionAction (string providerClassName, string ActionCode, string IHContext, string Params) {
        
        string retVal;
        ServiceIHLists.ExtensionProvider XP;
        ServiceIHLists.ExtensionActionResult XR;
        
        try {       
            Type t = Type.forName(providerClassName); 
            XP = (ServiceIHLists.ExtensionProvider)t.newInstance();         
            XR = XP.doAction(ActionCode, IHContext, Params);        
            retVal = JSON.serialize(XR);
            
        } catch (exception e) {
            XR = new ServiceIHLists.ExtensionActionResult();        
            XR.CompletedSuccessfully = false;
            XR.CompletionMessage = 'Error processing custom extension action (Provider = ' + providerClassName + ', Action = ' + ActionCode + ', Context = ' + IHContext + ', Parameters = '+ Params + '): ' + e.getMessage();
            retVal = JSON.serialize(XR);        
        }
        
        return retVal;
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Author configuration, Personalisation and stats / interactions support
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    // Pin a Reading List for the current component by leveraging existing author-config pipeline
    // Params encoding pattern reused from Topic Viewer "Pin Topic":
    // ToolContext=RLViewer|ActionCode=PinnedRL|Value={rlId}
    @AuraEnabled
    public static String pinReadingList(String ComponentId, String rlId) {
        try {
            if (String.isBlank(ComponentId) || String.isBlank(rlId)) {
                return 'Error (Pin Reading List): ComponentId and rlId are required';
            }
            // Build Params string consistent with existing logAuthorConfig usage
            // Use caret (^) and tilde (~) separator convention used throughout ControllerLUXOps
            // For Author config records, SupportingControls__c stores Params verbatim
            String params = 'HelpRecordId~' + rlId;
            return ControllerLUXOps.logAuthorConfig(ComponentId, params);
        } catch (Exception e) {
            return 'Error (Pin Reading List): ' + e.getMessage();
        }
    }

    // Obtain any author-specified LUX component configuration information
    // with which to override the default settings provided by page authors 
    @AuraEnabled
    global static string getAuthorConfig(string ComponentId) {
        
        ConfigurationItem__c CI;
        string retVal = '';
        
        try {
            CI = [SELECT SupportingControls__c
                    FROM ConfigurationItem__c
                    WHERE Type__c = 'AuthorConfiguration'
                    AND ActionCode__c = :ComponentId 
                    ORDER BY CreatedDate DESC
                    LIMIT 1];
                    
            retVal = CI.SupportingControls__c;
            
        } catch (exception e) {}
        
        return retVal;
    }
    
    
    // Log an author configuration activity
    @AuraEnabled
    global static string logAuthorConfig(string ComponentId, string Params) {
        
        string retVal;
        ConfigurationItem__c CI;
        ConfigurationItem__c[] CIs;
       // ServiceSecurity sS = new ServiceSecurity();
        
        try {           
             
            ServiceSecurity sS = new ServiceSecurity();
            
            Boolean isAllowed = sS.IsAllowed(ServiceSecurity.KnownSecureOperations.EditHelp);
            
            if (!isAllowed) {
                Map<String, String> mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false);
                retVal = mapGlbLocs.get('MessageNoRights');              
            } else  {
                // These operations require a the component to have an identifier, as otherwise
                // it would be impossible to know which component's configuration was to be controlled
                if (ComponentId == '' || ComponentId == null || ComponentId + '' == 'undefined') {
                    retVal = 'Unable to log Author Configuration data: the component for which configuration was to be set requires a Component ID.';    
                    
                } else {
                    try {               
                        // Delete any existing configuration items holding author configurations for the specified component
                        CIs = [SELECT Id
                               FROM ConfigurationItem__c 
                               WHERE Type__c = 'AuthorConfiguration' 
                               AND ActionCode__c = :ComponentId];
                        
                        delete CIs;
                        
                    } catch (exception ex) {}
                    
                    CI = new ConfigurationItem__c();        
                    
                    CI.ActionCode__c = ComponentId;
                    CI.Description__c = 'This record stores author-generated settings for Lightning components and does not represent a clickable.';  
                    CI.IconClass__c = 'fa-cog';
                    CI.Label__c = 'Author-specified component settings only';
                    CI.TipText__c = 'NOT FOR USE AS A CLICKABLE';
                    CI.DisplayGrouping__c = 'N/A';
                    CI.DisplayOrder__c = 1;
                    CI.HasDivider__c = false;
                    CI.IconContent__c = '';
                    CI.NegotiateToolbarLevel__c = 0;
                    CI.PermissionLevel__c = 1;      
                    CI.SkipImportOverwrite__c = true;
                    CI.SkipExport__c = true;
                    
                    CI.SupportingControls__c = Params;
                    
                    CI.ToggleActiveMarker__c = '';
                    CI.ToggleNext__c = 0;
                    CI.TogglePrev__c = 0;
                    CI.ToolClass__c = '';
                    CI.ToolContext__c = '[Hidden]';
                    CI.ToolFilter__c = 0;
                    CI.Type__c = 'AuthorConfiguration';
                        System.debug('Log Author congif : ' +CI);
                    upsert CI;
                    retVal = '';
                    
                    
                }   // End if component had an identifier                           
            }   // End if user had authoring rights
            
            
        } catch (exception e) {
            retVal = 'ERR! (Log Author Configurations): ' + e.getMessage();
        }
        
        return retVal;
    } 
   

  
    //Integer iTyp, String Description, String IHContext, 

    public class GeolocationWrapper{
    @AuraEnabled
    public Decimal latitude { get; set; }
    @AuraEnabled    
    public Decimal longitude { get; set; }
    @AuraEnabled    
    public Decimal accuracy { get; set; }
    @AuraEnabled    
    public Decimal altitude { get; set; }
    @AuraEnabled
    public string userAgent {get; set;}
    @AuraEnabled    
    public String contextURL { get; set; }
    } 
    
    @AuraEnabled 
    public static string logHelpInteractions(Integer iTyp, String Description, String IHContext, String restInteractionParam, String HTID){
        GeolocationWrapper geoData;
        Try{
            geoData = (GeolocationWrapper)JSON.deserialize(restInteractionParam , GeolocationWrapper.class);
          }catch(Exception ex){
            system.debug('ERROR '+ex.getMessage());
         }
        //Here we spliting the IHContext perameter by unprintiable character 7(ASKI val).
        //the actual value of IHContext will be at zero'th index and coordintes will be at first index.
        //after that we passing the actual value to "IHContext" for previous functioning of the below code without any interuption.
        //and the geo-coordinates will be deserialize to "lat" and "long" value.  
        /*string D7 = String.fromCharArray(new List<integer>{7});
        String position = '';
        String logContextURL = '';
        try{
         System.debug('IHContext With coordintes '+IHContext);   
         position =  IHContext.split(D7)[1];  
         String actualIHContext = IHContext.split(D7)[0];
         logContextURL = IHContext.split(D7)[2];  
         IHContext = actualIHContext;
         System.debug('Actual IHContext without coordinates'+IHContext);
        }catch(Exception ex){
         system.debug('ERROR '+ex.getMessage());
        }*/
        
        //Map<String,Object> restParam;
        /*try{
            //restParam = (Map<String,Object>)JSON.deserializeUntyped(restInteractionParam);
        }catch(Exception ex){
            system.debug('ERROR '+ex.getMessage());
        }*/
        
        // THINK:
        //      QAM drag means we have list / QAM context
        //      List expand / collapse likewise
        //      No record (Topic, RL etc) implied        
        //      Handle exceptions in-line...
        
        String PLID = null;
        String EID = null;
       // String HTID = null;
        String RLID = null;
        String VOptID = null;
        string retVal;
        ServiceInteractions svsI = new ServiceInteractions();
        
        
        // Resource viewed
        if (iTyp == 6) {
            // We only do this from related resource listings, where context should be the related topic
            // In addition, we need to record resource ID:
            // Get this info from the context passed in, which should be in form: 
            // Topic (whose relatives were listed) ^ Help Topic Resource ID (that was clicked)
            
            string[] cxt = IHContext.split('\\^');          
            HTID = cxt[0];
            system.debug('resource Viewed cxt'+ cxt);
           // We are supplied with help topic resource ID - not resource - so obtain the latter here 
           string HTRID = cxt[1];
           HelpTopicResource__c HTR = [SELECT HelpResource__c, HelpResource__r.Name FROM HelpTopicResource__c WHERE Id = :HTRID];
           
           // NB: interactions service for now uses entity ID for obtaining resource ID!
           EID = HTR.HelpResource__c;
           
           // Replace help topic resource id in description with its name
           Description = Description.replace(HTRID, HTR.HelpResource__r.Name);
           
           // Also, we ultimately only want to store the topic id as our context
           IHContext = cxt[0];
        }
        
        // Vote cast
        if (iTyp == 8) {
            // In addition to Description and type passed in, we need to record:
            // iahelp__Context__c = tree (where relevant) in the context of which this vote was cast
            // iahelp__HelpTopic__c = topic voted on
            // iahelp__HelpVoteOption__c = the vote that was cast
            
            // Get this info from the context passed in
            string[] cxt = IHContext.split('\\^');
            
            IHContext = cxt[0];
            HTID = cxt[1];
            VOptID = cxt[2];
        }
        
        // Sticky interaction: derive HPL info from context
        if (iTyp == 12) {
            
            // Context should be one of: null, blank text, 'undefined', an Object name (fixed help) or a record ID
            // We can only act on the last two
            
            if (IHContext != '' && IHContext + '' != 'undefined' && IHContext != null && IHContext + '' != 'null') {
                
                string oCode;
                HelpedPageLayout__c HPL;
                
                // Try a call by name
                oCode = ServiceSchema.getObjectIdByName (IHContext);
                
                // If this fails, assume we have a record ID, so try with that
                if (oCode == '' && IHContext.length() > 3) {
                    oCode = IHContext.substring(0,3);
                }
                
                try {
                    HPL = [SELECT Id FROM HelpedPageLayout__c WHERE PageLayoutIdentifier__c = :oCode];
                    PLID = HPL.Id;
                } catch (exception ex) {}
            }
            
        }        
        
        // Reading List Entry viewed
        if (iTyp == 13) {
            HTID = Description;
            RLID = IHContext;
            Description = 'Help Topic Viewed (as Reading List Entry)';
            IHContext = '';
        }
        
        // Tree Node clicked
        if (iTyp == 14) {
            
            // HTID can only be set if we're on a topic-focussed tree
            string HTCode = ServiceSchema.getObjectIdByName('iahelp__HelpTopic__c');
            if (Description.startsWith(HTCode)) {
                HTID = Description;             
            }
            Description = 'Tree Node Clicked';
        }
                
        // Nudge displayed to user
        if (iTyp == 20) {

            // In addition to Description and type passed in, we need to record:
            // iahelp__ComponentId__c = component that displayed the nudge
            // iahelp__HelpTopic__c = topic that was featured if not a fixed message nudge
            // iahelp__Context__c = the record, if any, in play on the screen where the nudge occurred
            
            // Get this info from the context passed in
            string[] cxt = IHContext.split('\\^');
            
            IHContext = cxt[0] + '^' + cxt[2];
            HTID = cxt[1];
            if (HTID == 'NULL') {HTID = null;}     
                   
        }
        
        // LUX Guide Prompt viewed
        if (iTyp == 21) {
            // In addition to Description and type passed in, we need to record:
            // Guide containing the step viewed
            // Topic that was featured
            
            // Get this info from the context passed in
            string[] cxt = IHContext.split('\\^');
            
            IHContext = cxt[0];
            RLID = cxt[1];
            if (RLID == 'NULL') {RLID = null;}            
            HTID = cxt[2];
            if (HTID == 'NULL') {HTID = null;}            
        }
        
        // Tree search completed
        if (iTyp == 23) {
            // Help topic should be recorded - i.e., the search result clicked
            // Get this info from the context passed in: this should be in the form: 
            // tree root ^ search listing topic ID
            
            string[] cxt = IHContext.split('\\^');
            
            IHContext = cxt[0];
            HTID = cxt[1];
            if (HTID == 'NULL') {HTID = null;}            
        }
        
        // Tree search cancelled
        if (iTyp == 24) {
            // Context is the root - nothing further required
        }
        
        // PosDetect request help role.
        if(iTyp == 25){
            // Nothing further required
        }

        try {
            //Re-concatinate the IH-Context with position coordinates is because to pass the position coordinates to "logInteraction" 
            //to log the coordinates into geo-coordinates field which is in helpInteraction object while keeping logInteraction signatures as it is. 
            //IHContext = IHContext+D7+position+D7+logContextURL;
            try{
            svsI.restParamMap =  geoData;
            }catch(Exception EX){
                System.debug('ERROR '+EX.getMessage());
            }
            if (svsI.logInteraction (iTyp, Description, IHContext, PLID, EID, HTID, RLID, VOptID) == true) {
                
                //Bind Current Log interaction record Id with the return message for 19  types only  
                retVal = 'MessageGenericTaskComplete'+((iTyp==19)? '__'+svsI.Diags:'');
            }
            
        } catch (exception e) {
            retVal = 'Unexpected error logging LUX interaction: ' + e.getMessage();
        }

        return retVal;    
    }

       
    // Wrapper for "direct" (LUX-related) interaction logging:
    // REM: classic interactions often logged via embedded calls in other, wrapped classic code
    @AuraEnabled
    global static string logLUXInteraction(Integer iTyp, String Description, String IHContext ) {
        
        //Here we spliting the IHContext perameter by unprintiable character 7(ASKI val).
        //the actual value of IHContext will be at zero'th index and coordintes will be at first index.
        //after that we passing the actual value to "IHContext" for previous functioning of the below code without any interuption.
        //and the geo-coordinates will be deserialize to "lat" and "long" value.  
        //string D7 = String.fromCharArray(new List<integer>{7});
        //String position = '';
        //String logContextURL = '';
        //try{   
         //position =  IHContext.split(D7)[1];  
         //String actualIHContext = IHContext.split(D7)[0];
         //logContextURL = IHContext.split(D7)[2];  
         //IHContext = actualIHContext;
         //System.debug('Actual IHContext without coordinates'+IHContext);
        //}catch(Exception ex){
         //system.debug('ERROR '+ex.getMessage());
        //}
        
        // THINK:
        //      QAM drag means we have list / QAM context
        //      List expand / collapse likewise
        //      No record (Topic, RL etc) implied        
        //      Handle exceptions in-line...
        
        String PLID = null;
        String EID = null;
        String HTID = null;
        String RLID = null;
        String VOptID = null;
        string retVal;
        ServiceInteractions svsI = new ServiceInteractions();
        
        
        // Resource viewed
        if (iTyp == 6) {
            // We only do this from related resource listings, where context should be the related topic
            // In addition, we need to record resource ID:
            // Get this info from the context passed in, which should be in form: 
            // Topic (whose relatives were listed) ^ Help Topic Resource ID (that was clicked)
            
            string[] cxt = IHContext.split('\\^');
            system.debug('cxt==>'+ cxt);
            HTID = cxt[0];
            system.debug('HTID==>'+ HTID);
            
            
            // We are supplied with help topic resource ID - not resource - so obtain the latter here 
            string HTRID = cxt[1];
            HelpTopicResource__c HTR = [SELECT HelpResource__c, HelpResource__r.Name FROM HelpTopicResource__c WHERE Id = :HTRID];
            
            // NB: interactions service for now uses entity ID for obtaining resource ID!
            EID = HTR.HelpResource__c;
            
            // Replace help topic resource id in description with its name
            Description = Description.replace(HTRID, HTR.HelpResource__r.Name);
            
            // Also, we ultimately only want to store the topic id as our context
            IHContext = cxt[0];
        }
        
        // Vote cast
        if (iTyp == 8) {
            // In addition to Description and type passed in, we need to record:
            // iahelp__Context__c = tree (where relevant) in the context of which this vote was cast
            // iahelp__HelpTopic__c = topic voted on
            // iahelp__HelpVoteOption__c = the vote that was cast
            
            // Get this info from the context passed in
            string[] cxt = IHContext.split('\\^');
            
            IHContext = cxt[0];
            HTID = cxt[1];
            VOptID = cxt[2];
        }
        
        // Sticky interaction: derive HPL info from context
        if (iTyp == 12) {
            
            // Context should be one of: null, blank text, 'undefined', an Object name (fixed help) or a record ID
            // We can only act on the last two
            
            if (IHContext != '' && IHContext + '' != 'undefined' && IHContext != null && IHContext + '' != 'null') {
                
                string oCode;
                HelpedPageLayout__c HPL;
                
                // Try a call by name
                oCode = ServiceSchema.getObjectIdByName (IHContext);
                
                // If this fails, assume we have a record ID, so try with that
                if (oCode == '' && IHContext.length() > 3) {
                    oCode = IHContext.substring(0,3);
                }
                
                try {
                    HPL = [SELECT Id FROM HelpedPageLayout__c WHERE PageLayoutIdentifier__c = :oCode];
                    PLID = HPL.Id;
                } catch (exception ex) {}
            }
            
        }        
        
        // Reading List Entry viewed
        if (iTyp == 13) {
            HTID = Description;
            RLID = IHContext;
            Description = 'Help Topic Viewed (as Reading List Entry)';
            IHContext = '';
        }
        
        // Tree Node clicked
        if (iTyp == 14) {
            
            // HTID can only be set if we're on a topic-focussed tree
            string HTCode = ServiceSchema.getObjectIdByName('iahelp__HelpTopic__c');
            if (Description.startsWith(HTCode)) {
                HTID = Description;             
            }
            Description = 'Tree Node Clicked';
        }
                
        // Nudge displayed to user
        if (iTyp == 20) {

            // In addition to Description and type passed in, we need to record:
            // iahelp__ComponentId__c = component that displayed the nudge
            // iahelp__HelpTopic__c = topic that was featured if not a fixed message nudge
            // iahelp__Context__c = the record, if any, in play on the screen where the nudge occurred
            
            // Get this info from the context passed in
            string[] cxt = IHContext.split('\\^');
            
            IHContext = cxt[0] + '^' + cxt[2];
            HTID = cxt[1];
            if (HTID == 'NULL') {HTID = null;}     
                   
        }
        
        // LUX Guide Prompt viewed
        if (iTyp == 21) {
            // In addition to Description and type passed in, we need to record:
            // Guide containing the step viewed
            // Topic that was featured
            
            // Get this info from the context passed in
            string[] cxt = IHContext.split('\\^');
            
            IHContext = cxt[0];
            RLID = cxt[1];
            if (RLID == 'NULL') {RLID = null;}            
            HTID = cxt[2];
            if (HTID == 'NULL') {HTID = null;}            
        }
        
        // Tree search completed
        if (iTyp == 23) {
            // Help topic should be recorded - i.e., the search result clicked
            // Get this info from the context passed in: this should be in the form: 
            // tree root ^ search listing topic ID
            
            string[] cxt = IHContext.split('\\^');
            
            IHContext = cxt[0];
            HTID = cxt[1];
            if (HTID == 'NULL') {HTID = null;}            
        }
        
        // Tree search cancelled
        if (iTyp == 24) {
            // Context is the root - nothing further required
        }
        
        // PosDetect request help role.
        if(iTyp == 25){
            // Nothing further required
        }

        try {
            //Re-concatinate the IH-Context with position coordinates is because to pass the position coordinates to "logInteraction" 
            //to log the coordinates into geo-coordinates field which is in helpInteraction object while keeping logInteraction signatures as it is. 
            //IHContext = IHContext+D7+position+D7+logContextURL;
            
           
            
            if (svsI.logInteraction (iTyp, Description, IHContext, PLID, EID, HTID, RLID, VOptID) == true) {
                
                
                //Bind Current Log interaction record Id with the return message for 19  types only  
                retVal = 'MessageGenericTaskComplete'+((iTyp==19)? '__'+svsI.Diags:'');

                
            } else {
                retVal = 'Error logging LUX interaction: ' + svsI.Diags;
            }
            
        } catch (exception e) {
            retVal = 'Unexpected error logging LUX interaction: ' + e.getMessage();
        }
        
        return retVal;      
    }
    
    
    // JSON wrapper for returning personalisation info to LUX pages
    @AuraEnabled
    global static string getPersonalisations(string IHContext) {
        string retVal;
        
        try {
            // Only return personalisations if these are being tracked
            if (ControllerSettings.getSettings().TrackDaysLUXOps__c > 0) {
                retVal = JSON.serialize(getPersonalisationInteractions(IHContext));
            } else {
                retVal = '';
            }
            
            // Also, tack on global settings
            iahelp__IASetIHOrg__c GS = ControllerSettings.getSettings();
            retVal = concatenateJSON(retVal, JSON.serialize(GS));            
            
        } catch (exception e) {
            retVal = '';
        }
        
        return retVal;
    }
    

    // Obtain a user's personal settings (sizing, positioning, expanded/collapsed state etc.)
    // Helper function returning interaction data used elsewhere for wrapped aura calls
    private static HelpInteraction__c[] getPersonalisationInteractions(string IHContext) {
        
        HelpInteraction__c[] HIs = new HelpInteraction__c[]{};
        HelpInteraction__c HI;
        
        try {
            HI = [SELECT Id, HelpInteractionType__c, Description__c
                    FROM HelpInteraction__c
                    WHERE HelpInteractionType__c = 'QAM Drag'
                    AND OwnerId = :UserInfo.getUserId()
                    ORDER BY CreatedDate DESC
                    LIMIT 1];
            HIs.add(HI);
            
        } catch (exception e) {}
        
        try {
            HI = [SELECT Id, HelpInteractionType__c, Description__c
                    FROM HelpInteraction__c
                    WHERE HelpInteractionType__c = 'List Detail Level'
                    AND OwnerId = :UserInfo.getUserId()
                    ORDER BY CreatedDate DESC
                    LIMIT 1];
                                        
            HIs.add(HI);
        } catch (exception e) {}

        try {
            HI = [SELECT Id, HelpInteractionType__c, Description__c
                    FROM HelpInteraction__c
                    WHERE HelpInteractionType__c = 'LUX List Type'
                    AND OwnerId = :UserInfo.getUserId()
                    ORDER BY CreatedDate DESC
                    LIMIT 1];
                                        
            HIs.add(HI);
        } catch (exception e) {}
        
        try {
            HI = [SELECT Id, HelpInteractionType__c, Description__c
                    FROM HelpInteraction__c
                    WHERE HelpInteractionType__c = 'Display Density'
                    AND OwnerId = :UserInfo.getUserId()
                    ORDER BY CreatedDate DESC
                    LIMIT 1];
                                        
            HIs.add(HI);
        } catch (exception e) {}

        try {
            string CXT;
            
            // Supplied context may be an object name or record ID: try to discern this here
            CXT = ServiceSchema.getObjectIdByName(IHContext);
            if (CXT == '') {
                CXT = IHContext;
                if (CXT.length() > 2) {
                    CXT = CXT.substring(0,3);
                }
            }
            
            HI = [SELECT Id, HelpInteractionType__c, Description__c
                    FROM HelpInteraction__c
                    WHERE HelpInteractionType__c = 'Personal Form Visibility'
                    AND Context__c = :CXT
                    AND OwnerId = :UserInfo.getUserId()
                    ORDER BY CreatedDate DESC
                    LIMIT 1];
            HIs.add(HI);
            
        } catch (exception e) {}
        
        return HIs;
    }


    // Obtain a user's preferred form fields / 'my form' info for a given context
    @AuraEnabled
    global static string getPersonalFormDef(string IHContext) {

        string retVal;
        ServiceIHLists.ListingItem[] LIs = new ServiceIHLists.ListingItem[]{};
        ServiceIHLists.ListingItem LI;

        Schema.DescribeSObjectResult sObj;
        Map<String, Schema.SObjectField> FMap;  
        Schema.DescribeFieldResult Fld;
        string OName;
        string OLabel;
        string fList;
        string[] flds;    
        ServiceSchema svsS = new ServiceSchema();
        integer i = 1;
    
        
        try {
            // Get the user's personal form definition for current context
            HelpInteraction__c HI = getPersonalForm(IHContext);
            if (HI != null) {
                // From this, get the applicable object code & list of selected fields
                fList = HI.Description__c;   
                
                // Note, user may have selected NO fields, so need to trap for this here...
                if (fList != null) {
                    flds = fList.split('\\^');
                }
            }
        
            // Get object info based on its prefix
            sObj = svsS.getObjectDetails(IHContext);    
            OName = sObj.getName();
            OLabel = sObj.getLabel();
         
        
            // Listing items are ALL AVAILABLE FIELDS - marked with whether they're mandatory and / or in use    
            // Get all its fields
            FMap = sObj.Fields.getMap();
            
            for (string FKey : FMap.keySet()){   
                Fld = FMap.get(FKey).getDescribe();
                
                // Only return rows for fields that can be edited:
                // NB: admins only should be defining forms! They have maximum editability - hence the 
                // "updateable" test should pass for them: if an admin cannot edit, no-one can, so field 
                // should not be on a form...
                if (Fld.isCalculated() == false && Fld.isAutoNumber() == false && Fld.isUpdateable() == true) {
                    
                    LI = new ServiceIHLists.ListingItem();
                    
                    LI.Id = Fld.getName();
                    LI.Icon = '';
                    LI.IconLabel = '';
                    LI.IconTitle = '';
                    LI.Label = Fld.getLabel();
                    LI.Title = '';                                     
                    LI.ActionCode = '';
                    LI.Parameters = '0';                    
                    LI.StyleClass = '';
                    
                    // If current field from schema is marked as in use from form definition, mark it as such
                    LI.RowState = '';
                    
                    i = 1;
                    if (flds != null) {
                        for (string F : flds) {
                            if (F == Fld.getName()) {
                                LI.RowState = 'SELECTED';
                                
                                // We need to get selected fields in the correct order - so note that here...
                                LI.Parameters = '' + i;
                                break;
                            }
                            i += 1;
                        }
                    }
                    
                    LIs.add(LI);
                } 
            }
            
        
            // Listing items now have parameters = 0 for non-selected,
            // parameters > 0 (in order) for the selected: in order to present selected fields
            // in the correct order, pre-pend this ordinal here: list items are sorted below, 
            // and ordinal can be removed by form component upon receipt...
            for (ServiceIHLists.ListingItem L : LIs) {
                L.Label = L.Parameters.leftPad(5, '0') + ' ' + L.Label;         
            }
            
            retVal = JSON.serialize(LIs);
            
        } catch (exception e) {
            retVal = 'Error (Get Personal Form Definition): ' + e.getMessage();
        }
        
        return retVal;
    }

    
    // Get the interaction that defines the current user's preferred form fields / 'my form'
    private static HelpInteraction__c getPersonalForm(string IHContext) {
        
        HelpInteraction__c HI = null;
        
        try {
            // Only return personalisations if these are being tracked
            if (ControllerSettings.getSettings().TrackDaysLUXOps__c > 0) {
                
                // Note that form defs are contextualised to object type (not record etc.)
                HI = [SELECT Id, HelpInteractionType__c, Description__c
                        FROM HelpInteraction__c
                        WHERE HelpInteractionType__c = 'Personal Field Selection'
                        AND OwnerId = :UserInfo.getUserId()
                        AND Context__c = :IHContext
                        ORDER BY CreatedDate DESC
                        LIMIT 1];
            }
        
        } catch (exception ex) {
            // Do nothing: no definitions to retrieve
        }    
        
        return HI;  
    }
    
    
    // Get the interaction that traps details of a user's choice of form section expended / collapsed state
    private static HelpInteraction__c getFormSectionStatus(string IHContext) {
        
        HelpInteraction__c HI = null;
        
        try {
            // Only return personalisations if these are being tracked
            if (ControllerSettings.getSettings().TrackDaysLUXOps__c > 0) {
                
                // Note that form defs are contextualised to object type (not record etc.)
                HI = [SELECT Id, HelpInteractionType__c, Description__c
                        FROM HelpInteraction__c
                        WHERE HelpInteractionType__c = 'Form Section Toggle'
                        AND OwnerId = :UserInfo.getUserId()
                        AND Context__c = :IHContext
                        ORDER BY CreatedDate DESC
                        LIMIT 1];
            }
        
        } catch (exception ex) {
            // Do nothing: no definitions to retrieve
        }    
        
        return HI;  
    }
        
        
    // Mark Stickies relating to a given context (for the current user) as "archived", to remove them
    // from user listings (but not from the store of interactions)
    @AuraEnabled
    global static string archiveSticky(string IHContext) {
        string retVal;

        ServiceSecurity sS = new ServiceSecurity();
        
        try {           
            // Check rights before any data amendments
            if (! sS.IsAllowed(ServiceSecurity.KnownSecureOperations.UseHelp)) {
                map<string, string> mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false);
                retVal = mapGlbLocs.get('MessageNoRights');              
                                
            } else {
                // Locate all stickies in the specified context:
                // NOTE: this IS a specific record context, unlike where we retrieve all stickies, which looks to 
                // locate latest sticky version for a given object derived from a record ID...
                HelpInteraction__c[] HIs = [SELECT Id, HelpInteractionType__c
                                    FROM HelpInteraction__c
                                    WHERE HelpInteractionType__c = 'Sticky'
                                    AND OwnerId = :UserInfo.getUserId()
                                    AND Context__c = :IHContext
                                ];
                                
                for (HelpInteraction__c HI : HIs) {
                                    
                    // Mark all of them (not just the most recent) as "archived"
                    HI.HelpInteractionType__c = 'Sticky (Archived)';
                } 
                
                upsert HIs;
                retVal = '';
            }
            
        } catch (exception e) {
            retVal = 'Error (Archive Sticky): ' + e.getMessage();
        }
        
        return retVal;
    }
    

    // JSON wrapper for returning interaction/votes info to LUX pages featuring trees
    @AuraEnabled
    global static string getTreeVotes(string RootNode) {
        
        string retVal;
        HelpInteraction__c[] HIs;
        NameValuePair[] NVPs = new NameValuePair[]{};
        Id lastHT;
        system.debug('RootNode='+RootNode);          
                            
        try {
            // Get all "relevant" help interactions, then loop to pick the most recent vote for each topic 
            HIs = [SELECT HelpTopic__c, HelpVoteOption__r.OptionColour__c, CreatedDateTime__c 
                        FROM HelpInteraction__c 
                        WHERE HelpInteractionType__c = 'Vote' 
                        AND iahelp__Context__c = :RootNode 
                        AND CreatedById = :UserInfo.getUserId()
                        ORDER BY HelpTopic__c, CreatedDateTime__c DESC 
                        LIMIT 10000];
            system.debug('Queried HIs'+HIs);
                    
                    
            for (HelpInteraction__c HI : HIs) {             
                
                if (lastHT != HI.HelpTopic__c) {
                    system.debug('HI.HelpVoteOption__r.OptionColour__c '+HI.HelpVoteOption__r.OptionColour__c+'  '+HI.HelpVoteOption__c);
                    NVPs.add(new NameValuePair('Votes', HI.HelpTopic__c, HI.HelpVoteOption__r.OptionColour__c));
                    lastHT = HI.HelpTopic__c;
                }
                
            }    
            system.debug('NVPs after Loop'+NVPs);
            
            // Return votes as a collection of name / value pairs
            retVal = JSON.serialize(NVPs);
            system.debug('retVal 12'+retVal);
            
        } catch (exception e) {
            retVal = 'Err! ' + e.getMessage();
        }
        
        return retVal;
        
    }

    
    // JSON wrapper for returning interaction/stats info to LUX pages featuring trees
    @AuraEnabled
    global static string getTreeStats(string RootNode) {
        string retVal;
        NameValuePair[] NVPs = new NameValuePair[]{};
        AggregateResult[] treeNodeInteractions;
                    
        
        try {
            treeNodeInteractions = [SELECT HelpTopic__c Topic, COUNT(HelpTopicId__c) CT
                FROM HelpInteraction__c
                WHERE HelpInteractionType__c = 'Tree Node'
                AND Context__c = :RootNode
                GROUP BY HelpTopic__c
                LIMIT 10000];
                    
            for (AggregateResult AR : treeNodeInteractions) {
                NVPs.add(new NameValuePair('InteractionCounts', (string) AR.get('Topic'), '' + AR.get('CT')));
            }
            
            // Return stats as a collection of name / value pairs
            retVal = JSON.serialize(NVPs);
            
        } catch (exception e) {
            retVal = 'Err! ' + e.getMessage();
        }
        
        return retVal;
    }
    
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Semantics & tagging
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    // Gets topics within a defined collection that have a given tag set on them (are RELATIVES of that tag - NOT its members)
    // tagFilterInfo parameter defines the tags to match and the "pool" of topics to search within, as follows:
    //      [Root ID - the ID of a topic to which all must be related] [Delimiter]
    //      [Delimited List of tag topic IDs] [Delimiter]
    //          NOTE: 
    //          * if comma separated, this indicates "show items with these tags" (some or all - see below)
    //          * if colon separated, this indicates "show untagged items" and list includes all tags in the specified pool
    //      [Match mode - "ALL" to return only items with all filter tags, "ANY" to return items with any matching tag]

    private static string getTaggedItems (ControllerIHQAMSettings cIHQ, string tagFilterInfo) {
        
        string retVal;
        string localDiags = ''; 
        ServiceIHLists.ListingItem[] LIs = new ServiceIHLists.ListingItem[]{};
        ServiceIHLists.ListingItem LI;
        SemanticTag__c sTagR;
        SemanticTag__c sTagP;
        HelpRelationship__c[] poolMembers = new HelpRelationship__c[]{};
        HelpRelationship__c poolMember;
        HelpRelationship__c[] tagMembers;
        
        map<id,HelpRelationship__c> poolKeys = new map<id,HelpRelationship__c>();
        map<string,string> tagKeys = new map<string,string>();
        map<string,string> tagMemberKeys = new map<string,string>();
        map<id,ControllerIHQAMSettings.SearchResultQAM> SRKeys = new map<id,ControllerIHQAMSettings.SearchResultQAM> ();
        ControllerIHQAMSettings.SearchResultQAM SRQ;
        
        NameValuePair NVP;
        
        string D1 = '^';
        string[] parms = tagFilterInfo.split('\\^');
        string RootNode;
        string[] tagIds;
        string theMode;
        integer i;
        boolean filterPoolToTags = false;
        integer filterPoolToUnTagged = -1;
        boolean filteringFixedContext = false;
        boolean listingQualifies;
        
        
        if (tagFilterInfo.indexOf(D1) != -1) {
            RootNode = parms[0];
            theMode = parms[2];
            
            if (parms[1] != '') {
                // If parameters include a tag or tags to filter to, note the fact that we must filter
                filterPoolToTags = true;

                // Put all specified tags into a keys map for later SOQL ops etc.
                tagIds = parms[1].split(',');
                for (i=0; i < tagIds.size(); i++) {
                    
                    // Special treatment for the "untagged items" option:
                    if (tagIds[i].indexOf(':') != -1) {
                        // Don't note in keys - as this value cannot be used in SOQL: 
                        // Instead just note the need to include the un-tagged
                        filterPoolToUnTagged = i;
                    } else {
                        tagKeys.put(tagIds[i], tagIds[i]);
                    }
                }   
            }
            
        } else {
            // If instructions are not delimited, aim is to obtain all topics simply tagged with a single item 
            RootNode = tagFilterInfo;
        }
        
        try {        
            // Obtain details of the "relationship" tag that defines semantic tagging plus parent type                  
            sTagR = [SELECT Id FROM SemanticTag__c WHERE Name = 'Relative'];
            sTagP = [SELECT Id FROM SemanticTag__c WHERE Name = 'Parent'];
                        
                        
            // Note the keys of any context helped elements, discovered by caller and passed to us, in case these are needed later... 
            if (cIHQ.HelpedElements != null) {
                localDiags += 'IHQAM controller elements not null: looping to note element keys... ';                       
                
                for (ControllerIHQAMSettings.SearchResultQAM SR : cIHQ.HelpedElements) {
                    if (SRKeys.get(SR.Element.HelpTopic__c) == null) {
                        SRKeys.put(SR.Element.HelpTopic__c, SR);
                    }
                }
                
                localDiags += 'SRKeys contains ' + SRKeys.size() + ' element keys... ';                     
            }
                        
                        
            localDiags += 'Continuing to consider pool... ';
                        
            // Obtain any topics related to the specified pool / root: only bother if a pool is specified
            if (RootNode != '') {
                
                localDiags += 'Root node is present (' + RootNode + ')... ';
                
                // Need to deal here with several types of "pool": this may be based on a TAG...
                //      - e.g., from topics tagged "competitors" select those also tagged with "Lightning ready"   
                // ... or FIXED...
                //      - e.g., from topics in fixed context "Account" select those tagged with "Financially critical"
                //
                // In FIXED cases, specified root node will be the API name of an object (NOT record ID of a tag pool):
                // We can test for this by attempting to get schema code: if this fails (returns blank), we have a record ID (ordinary tag root):
                
                if (ServiceSchema.getObjectIdByName(RootNode) != '') {
                    
                    // Note the fact that a fixed context is in play...
                    localDiags += 'Filtering a FIXED context (' + RootNode + ')... ';
                    filteringFixedContext = true;                       
                    
                    // If we are filtering a fixed context, pre-processing will have occurred in GetTools - which calls this operation:
                    // This will have resulted in candidate helped elements being identified via calls to QAM settings object
                    // as passed to this function...
                    
                    // Loop around any helped elements discovered earlier / as passed in via QAM Settings object,
                    // getting topic IDs from these as they constitute the required pool: 
                    
                    if (cIHQ.HelpedElements != null) {
                        localDiags += 'Looping around IHQAM controller elements to create pseudo relation pool members... ';                        
                        
                        for (ControllerIHQAMSettings.SearchResultQAM SR : cIHQ.HelpedElements) {
                            
                            // Produce some "mock" relationship records from these elements (don't save at any point) 
                            //so we can use them just as other "real" relationships in the remainder of this call 
                            poolMember = new HelpRelationship__c();
                            poolMember.SemanticTag__c = sTagR.Id;
                            poolMember.ReferringTopic__c = SR.Element.HelpTopic__c;
                            poolMembers.add(poolMember);
                        }
                    }

                } else {
                    // Ordinary root...
                    localDiags += 'Filtering a TAG context (' + RootNode + ')... ';
                    
                    poolMembers = [SELECT Id, SemanticTag__c,
                                            RelatedHelpTopic__c, RelatedHelpTopic__r.Name, RelatedHelpTopic__r.Summary__c, 
                                            ReferringTopic__c, ReferringTopic__r.Name, ReferringTopic__r.Summary__c,
                                            RelatedHelpTopic__r.CustomStyle__c, ReferringTopic__r.CustomStyle__c
                                        FROM HelpRelationship__c
                                        WHERE (SemanticTag__c = :sTagR.Id
                                        AND RelatedHelpTopic__c = :RootNode)
                                        
                                        OR (SemanticTag__c = :sTagP.Id
                                        AND ReferringTopic__c = :RootNode)
                                        
                                        ORDER BY ReferringTopic__r.Name];
                }
                
                // Place IDs of these pool members into a map for SOQL filtering:
                // Source field varies for "parent" and "relative" type relations
                for (HelpRelationship__c HR : poolMembers) {
                    
                    if (HR.SemanticTag__c == sTagR.Id) {
                        if (poolKeys.get(HR.ReferringTopic__c) == null) {
                            poolKeys.put(HR.ReferringTopic__c, HR);
                        }                   
                    }
                    
                    if (HR.SemanticTag__c == sTagP.Id) {
                        if (poolKeys.get(HR.RelatedHelpTopic__c) == null) {
                            poolKeys.put(HR.RelatedHelpTopic__c, HR);
                        }                   
                    }
                    
                }
                localDiags += 'Pool contains ' + poolKeys.size() + ' related topics... ';
                
            }   // End if root node non-blank


            localDiags += 'Pool considered: continuing to consider specified filtering tags... ';
            
            // Of the pool members (where relevant), we want the topics that also match any specified tagging criteria
            try {
                if (RootNode != '') {

                    localDiags += 'Obtaining tagged members... ';
                    
                    // If we're to find the un-tagged, we must adjust members here...
                    if (filterPoolToUnTagged != -1) {

                        localDiags += 'We are filtering to un-tagged... ';

                        // To locate the un-tagged, we need to obtain all tags in the pool being considered: these are the ones specified 
                        // in the tag key located above:
                        string[] allTagKeys = tagIds[filterPoolToUnTagged].split(':');
                        tagKeys.clear();
                        for (i=0; i < allTagKeys.size(); i++) {
                            tagKeys.put(allTagKeys[i], allTagKeys[i]);
                        }

                        localDiags += 'Un-tagged option cloud contains ' + tagKeys.size() + ' keys to test for... ';
                    }
                    
                    tagMembers = [SELECT Id, RelatedHelpTopic__r.Name, ReferringTopic__c, ReferringTopic__r.Name, ReferringTopic__r.Summary__c, ReferringTopic__r.CustomStyle__c
                                                FROM HelpRelationship__c
                                                WHERE SemanticTag__c = :sTagR.Id
                                                AND ReferringTopic__c IN :poolKeys.keySet()
                                                AND RelatedHelpTopic__c IN :tagKeys.keySet()
                                                ORDER BY ReferringTopic__r.Name];

                    localDiags += 'There were ' + tagKeys.size() + ' tag keys to match and this returned ' + tagMembers.size() + ' matching/related topics within POOL... ';
                    
                } else {
                    tagMembers = [SELECT Id, RelatedHelpTopic__r.Name, ReferringTopic__c, ReferringTopic__r.Name, ReferringTopic__r.Summary__c, ReferringTopic__r.CustomStyle__c
                                                FROM HelpRelationship__c
                                                WHERE SemanticTag__c = :sTagR.Id
                                                AND RelatedHelpTopic__c IN :tagKeys.keySet()
                                                ORDER BY ReferringTopic__r.Name];                   

                    localDiags += 'Root Node (pool) was blank, there were ' + tagKeys.size() + ' tag keys to match, so tagMembers contains ' + tagMembers.size() + ' matching/related topics across ALL help data... ';
                }
                                            
                // Get keys of all members we arrive at - the list of topic IDs that have at least 1 of the desired tags
                for (HelpRelationship__c HR : tagMembers) {
                    if (tagMemberKeys.get(HR.ReferringTopic__c) == null) {
                        tagMemberKeys.put(HR.ReferringTopic__c, HR.ReferringTopic__c);
                    }
                }
                localDiags += 'Tag member unique topic count is ' + tagMemberKeys.size() + ' keys... ';

                
                // Ultimate membership of the tagged items to return varies depending on tag mode:
                if (theMode == 'ALL') {
                    
                    localDiags += 'Tag matching mode is ALL - checking... ';
                    
                    // In mode = ALL, we only want to add items that meet all tags: 
                    // Loop around specified tags checking that tag members found above meet all ...
                    
                    // tagMembers = all HTs related to at least 1 of the desired tags
                    // tagKeys = the desired tags
                    // tagMemberKeys = list of each unique HT from members

                    // Get the count of total tags set on each topic that matches any tag
                    AggregateResult[] membershipCounts = [SELECT ReferringTopic__c TaggedMember, COUNT(Id) CT
                                                            FROM HelpRelationship__c
                                                            WHERE SemanticTag__c = :sTagR.Id
                                                            AND RelatedHelpTopic__c IN :tagKeys.keySet()
                                                            AND ReferringTopic__c IN :tagMemberKeys.keySet()
                                                            GROUP BY ReferringTopic__c];                    
                    
                    // Each tag member key should have n entries in tagMembers, where n is the number of tagKeys (exactly 1 relation per tag)
                    for (AggregateResult AR : membershipCounts) {
                        if (AR.get('CT') != tagKeys.size()) {
                            // If count not correct, remove current member from tag members
                            tagMemberKeys.remove((string) AR.get('TaggedMember'));
                        }
                    } 
                    
                    localDiags += 'tagMemberKeys adjusted to remove any failing to match all desired tags: now contains ' + tagMemberKeys.size() + ' keys... ';
                    
                }
                
                
                // Adjust results if "un-tagged" items are to be included
                if (filterPoolToUnTagged != -1) {

                    localDiags += 'Untagged items are desired: obtaining counts... ';

                    AggregateResult[] membershipCounts = [SELECT ReferringTopic__c TaggedMember, COUNT(Id) CT
                                                            FROM HelpRelationship__c
                                                            WHERE SemanticTag__c = :sTagR.Id
                                                            AND RelatedHelpTopic__c IN :tagKeys.keySet()
                                                            AND ReferringTopic__c IN :tagMemberKeys.keySet()
                                                            GROUP BY ReferringTopic__c];        
                                                                        
                    localDiags += 'Membership counts contains ' + membershipCounts.size() + ' aggregated, non-zero counts... ';

                    for (AggregateResult AR : membershipCounts) {
                        
                        // Each entry in the counts of tags is a result to EXCLUDE - because
                        // it has at least 1 tag and we want only the untagged
                        poolKeys.remove((string) AR.get('TaggedMember'));
                    } 
                }
                localDiags += 'After removing tagged items if un-tagged only desired, poolKeys contains ' + poolKeys.size() + ' keys... ';
                
            } catch (exception ex) {
                return 'Error getting tag members: ' + ex.getMessage() + ': ' + localDiags;                             
            }   


            localDiags += 'Continuing to produce listing items to return... ';
            
            if (RootNode != '') {   
                localDiags += 'Pool (RootNode) was specified - checking for qualified pool members... ';
                
                listingQualifies = true;
                for (HelpRelationship__c HR : poolMembers){ 
                    
                    // "Qualification" (rules for inclusion on list) vary depending on parameters in play
                    if (filterPoolToUnTagged != -1) {
                        // Show un-tagged items: the tagged are removed from the pool above
                        listingQualifies = poolKeys.get(HR.ReferringTopic__c) != null || poolKeys.get(HR.RelatedHelpTopic__c) != null;
                    } else {
                        // General cases
                        listingQualifies = filterPoolToTags == false || tagMemberKeys.get(HR.ReferringTopic__c) != null || tagMemberKeys.get(HR.RelatedHelpTopic__c) != null;
                    }

                    if (listingQualifies) { 
                        LI = new ServiceIHLists.ListingItem();
                        
                        if (HR.SemanticTag__c == sTagR.Id) {
                            LI.Id = HR.ReferringTopic__c;
                            
                            // At this point, we may or may not have a fixed originial context (i.e., list in Fixed mode) in play:
                            // See above: where filtering of a previously fixed context occurs, we use Relative relations/Semantic tag
                            // and will have noted this fact in the following flag:
                            if (filteringFixedContext) {
                                
                                // In these cases, we've created pseudo relationship records (because we need a loop around relationships here)
                                // based on the helped elements that matched the original fixed contexts: as these pseudo relationships
                                // don't contain all the info we need for a listing, retrieve this - based on the topic key we did store - 
                                // from a map created at the same time...
                                
                                SRQ = SRKeys.get(HR.ReferringTopic__c);
                                if (SRQ != null) {
                                    LI.Label = SRQ.Result.Name;
                                    LI.Title = SRQ.Result.Summary;                      
                                    LI.Parameters = SRQ.Element.HelpTopic__r.CalloutHeight__c + '^' + SRQ.Element.HelpTopic__r.CalloutTemplate__r.PageURL__c + '^' 
                                            +  SRQ.Element.Identifier__c + '^' + SRQ.Element.HelpedPageLayout__r.PageLayoutIdentifier__c + '^' 
                                            + SRQ.Element.Id;  
                                } else {
                                    LI.Label = HR.ReferringTopic__c;
                                    LI.Title = 'FILTERED FIXED CONTEXT - Error obtaining full item details...';                                                         
                                }                 

                            } else {
                                LI.Label = HR.ReferringTopic__r.Name;
                                LI.Title = HR.ReferringTopic__r.Summary__c;     
                                LI.StyleClass = HR.ReferringTopic__r.CustomStyle__c;                                                
                            }

                        } else {
                            LI.Id = HR.RelatedHelpTopic__c;
                            LI.Label = HR.RelatedHelpTopic__r.Name;
                            LI.Title = HR.RelatedHelpTopic__r.Summary__c;   
                            LI.StyleClass = HR.RelatedHelpTopic__r.CustomStyle__c;                                              
                        }
                        
                        LI.Icon = '';
                        LI.IconLabel = '';
                        LI.IconTitle = '';
                        LI.ActionCode = 'TagClick';
                                        
                        LIs.add(LI);                
                    }             
                }
                
            } else {
                // If no pool was specified, and we just want all items that have the required tags...
                localDiags += 'Pool (RootNode) NOT specified - adding ALL tag members... ';
                
                // Check variable
                boolean noElementsAvailable = false;

map<string,HelpRelationship__c> mapRels = new map<string,HelpRelationship__c>();
                
                for (HelpRelationship__c HR : tagMembers){ 

// Add a check here to ensure we add only unique members (no duplicates based on same referring - i.e., tagged - topic
// haing been marked with >1 tag). Use listingQualifies to note this

if (mapRels.get(HR.ReferringTopic__c) == null) {
    listingQualifies = true;
    mapRels.put(HR.ReferringTopic__c, HR);
} else {
    listingQualifies = false;   
}

                    
                    if (listingQualifies) {
                        LI = new ServiceIHLists.ListingItem();
                        
                        LI.Id = HR.ReferringTopic__c;
                        LI.Label = HR.ReferringTopic__r.Name;
                        LI.Title = HR.ReferringTopic__r.Summary__c;                     
                        
                        LI.Icon = '';
                        LI.IconLabel = '';
                        LI.IconTitle = '';
    
                        // Attempt to use IHQAM Settings context keys here for callout info - but this may not be available
                        SRQ = SRKeys.get(HR.ReferringTopic__c);
                        if (SRQ != null) {
                            LI.Parameters = SRQ.Element.HelpTopic__r.CalloutHeight__c + '^' + SRQ.Element.HelpTopic__r.CalloutTemplate__r.PageURL__c + '^' 
                                    +  SRQ.Element.Identifier__c + '^' + SRQ.Element.HelpedPageLayout__r.PageLayoutIdentifier__c + '^' 
                                    + SRQ.Element.Id;                       
                        } else {
                            // Note the fact that further work will be required to deal with this
                            noElementsAvailable = true; 
                        }
    
                        LI.StyleClass = HR.ReferringTopic__r.CustomStyle__c;
                        LI.ActionCode = 'TagClick';
                                        
                        LIs.add(LI);  
                    }              
                }
                
                
                if (noElementsAvailable) {

                    try {
                        // Seek topic-specified HEIGHT - caller can use this in conjuntion with IHRedirector (which 
                        // obviates the need for the remaining details)
                        HelpTopic__c[] memberTopics = [SELECT Id, CalloutHeight__c FROM HelpTopic__c WHERE Id IN :tagMemberKeys.keySet()];
                        map<Id, HelpTopic__c> memHTMap = new map<Id, HelpTopic__c> (memberTopics);
                                                
                        // Now loop around listing items again to retrofit callout heights to parameters
                        for (ServiceIHLists.ListingItem L : LIs) {
                            HelpTopic__c memHT = memHTMap.get(L.Id); 
                            if (memHT != null) {
                                L.Parameters = '' + memHT.CalloutHeight__c;
                            }
                        }
                        
                    } catch (exception ex){}
                    
                }
                
                
            }   // End if pool specified                            

            localDiags += 'Final results are ' + LIs.size() + ' listing items... ';
            LIs.sort();
            retVal = JSON.serialize(LIs);
            
            
            // Tack on details of the root tag for which we were asked to retrieve members - for use as card title
            if (poolMembers.size() > 0) {
                if (poolMembers[0].SemanticTag__c == sTagR.Id) {
                    NVP = new NameValuePair('CardTitle', 'Title', poolMembers[0].RelatedHelpTopic__r.Name);
                } else {
                    NVP = new NameValuePair('CardTitle', 'Title', poolMembers[0].ReferringTopic__r.Name);
                }
                retVal = concatenateJSON(retVal, JSON.serialize(NVP));
            }      

        } catch (exception e) {
            retVal = 'Error: (LUX Get Tagged Items) ' + e.getMessage() + ': ' + localDiags;
        }
        
        return retVal;
    }

    
    // Creates a pool (help topic) with the suggeted name containing member topics with the suggested names
    @AuraEnabled
    global static string createTagPool (string PoolName, string[] PoolMembers) {
        
        string retVal;
        ServiceSecurity sS = new ServiceSecurity();
        ControllerHelpContent cH = new ControllerHelpContent(false);
        HelpTopic__c PoolTopic;
        HelpTopic__c MemberTopic;
        HelpTopic__c[] MemberTopics = new HelpTopic__c[]{};
        string addTagReturnCode;
        string[] objIds = ControllerSettings.getSettings().SFObjectIds__c.split('\\^');
        string HTCode = objIds[0];
        
        
        try {
            // Operation is only allowed for those with user rights
            if (sS.IsAllowed(ServiceSecurity.KnownSecureOperations.EditHelp)) {
            
                // Create a pool topic, ensuring name is within sizing bounds
                if (PoolName.length() > 80) {
                    PoolName = PoolName.substring(0,80);
                }
                
                PoolTopic = cH.getDefaultHelpTopic();
                PoolTopic.Name = PoolName;
                insert PoolTopic;
            
                // Create pool member topics: allow naming failures in outlier cases here
                // as abbreviating could result in undesired tags...
                for (string PM : PoolMembers) {
                    
                    // We may or may not have been supplied with an actual member topics 
                    // (as opposed to names and summaries for new topics to be created)
                    
                    if (PM.startsWith(HTCode)) {
                        // If topic name looks like a topic ID, see if we can locate it
                        // and, if we do, use it
                        MemberTopic = [SELECT Id FROM HelpTopic__c WHERE Id=:PM];
                        
                    } else {
                        // New topic: create from default
                        MemberTopic = cH.getDefaultHelpTopic();
                        MemberTopic.Name = PM.replaceAll('_', ' ');                     
                    }
                    
                    MemberTopics.add(MemberTopic);
                }           
                upsert MemberTopics;
                
                // Create member relationships
                for (HelpTopic__c Mem : MemberTopics) {
                    
                    // In doing so, pass special "no context" instruction - avoiding usual behaviour of GetTools etc...
                    addTagReturnCode = addMemberTag (PoolTopic.Id, Mem.Id, '[NoContext]');
                    
                    // Fail if any tag insertion is unsuccessful
                    if (addTagReturnCode == null || addTagReturnCode.indexOf('Error') != -1) {
                        retVal = 'Error: (Create Tag Pool) ' + addTagReturnCode;
                        return retVal;
                    }
                }
                
                // Return the ID of the pool topic
                retVal = PoolTopic.Id;
                
            } else {
                map<string, string> mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false);
                retVal = mapGlbLocs.get('MessageNoRights');             
            }
            
        } catch (exception e) {
            retVal = 'Error: (Create Tag Pool) ' + e.getMessage();
        }
        
        return retVal;
    }
    
    
    // Return a listing of all the tag pools (help topics with "member" relatives) that have been defined
    @AuraEnabled
    global static string getTagPools () {
        
        string retVal;
        HelpTopic__c[] PoolTopics;
        AggregateResult[] MemberTopics;
        map<Id,Id> MemberKeys = new map<Id,Id>();
        ServiceIHLists.ListingItem[] LIs = new ServiceIHLists.ListingItem[]{};
        ServiceIHLists.ListingItem LI;
        SemanticTag__c sTagM;
        
        
        try {
            // Obtain details of the "member" tag that defines semantic tagging                     
            sTagM = [SELECT Id FROM SemanticTag__c WHERE Name = 'Member'];
            
            // Obtain all member relations
            MemberTopics = [SELECT ReferringTopic__c Topic
                            FROM HelpRelationship__c
                            WHERE SemanticTag__c = :sTagM.Id
                            GROUP BY ReferringTopic__c
                            LIMIT 10000
                            ];
                        
                    
            for (AggregateResult AR : MemberTopics) {
                MemberKeys.put((Id) AR.get('Topic'), (Id) AR.get('Topic'));
            }
            
            
            // Obtain list of all topics referenced in "member" relationships
            PoolTopics = [SELECT Id, Name, Summary__c
                            FROM HelpTopic__c
                            WHERE Id IN :MemberKeys.keySet()
                            ORDER BY NAME
                            ];
         
            // Convert these into listings to return
            for (HelpTopic__c PT : PoolTopics) {
                
                LI = new ServiceIHLists.ListingItem();
                
                LI.Id = PT.Id;
                LI.Label = PT.Name;
                LI.Title = PT.Summary__c;
                LI.Icon = '';
                LI.IconLabel = '';
                LI.IconTitle = '';
                LI.Parameters = '';
                LI.ActionCode = 'TagPoolSelected';     
                LI.StyleClass = '';
                
                LIs.add(LI);                
            }
            
            retVal = JSON.serialize(LIs);           
            
        } catch (exception e) {
            retVal = 'Error: (Get Tag Pools) ' + e.getMessage();
        }
        
        return retVal;
    }
    
    
    // Gets all the tags of root tag (its Members) marked with whether or not they are set on a particular topic (HTID):
    // This is typically used by our tagging LUX control in Associate mode - to show which tags are available / in use.
    @AuraEnabled
    global static string getTags (string HTID, string rootTag) {
        
        string retVal;
        ServiceIHLists.ListingItem[] LIs = new ServiceIHLists.ListingItem[]{};
        ServiceIHLists.ListingItem LI;
        SemanticTag__c sTagM;
        SemanticTag__c sTagR;
        HelpRelationship__c[] rootMembers;
        HelpRelationship__c[] existingMemberships;
        map<id,HelpRelationship__c> rmKeys = new map<id,HelpRelationship__c>();
        NameValuePair NVP;
        
        // Set up a recency limit so recently amended items can be amended below
        string recencyMarker = 'IHTagTopicUpdated';
        DateTime dTRecenyLimit = DateTime.now().addHours(Integer.valueOf(ControllerSettings.getSettings().UpdateMarkerHours__c) * -1);
        map<string,string> mapDlgLocs = ServiceLocalisation.getDialogueLocalisations('LUXComponents', false);
        
        
        try {        
            // Obtain details of the "member" tag that defines semantic tagging                     
            sTagM = [SELECT Id FROM SemanticTag__c WHERE Name = 'Member'];
            
            // Ditto basic relationships semantic tag
            sTagR = [SELECT Id FROM SemanticTag__c WHERE Name = 'Relative'];
            
            // Obtain members of the requested root tag
            rootMembers = [SELECT Id, ReferringTopic__r.Name, RelatedHelpTopic__r.Id, RelatedHelpTopic__r.Name, 
                                RelatedHelpTopic__r.Summary__c, RelatedHelpTopic__r.LastModifiedDate        
                                                FROM HelpRelationship__c
                                                WHERE ReferringTopic__c = :rootTag
                                                AND SemanticTag__c = :sTagM.Id
                                                ORDER BY RelatedHelpTopic__r.Name];
            
            // Obtain any relationships current topic has with these members
            for (HelpRelationship__c HR : rootMembers) {
                rmKeys.put(HR.RelatedHelpTopic__r.Id, HR);
            }
            
            existingMemberships = [SELECT Id, RelatedHelpTopic__c
                                        FROM HelpRelationship__c
                                        WHERE ReferringTopic__c = :HTID
                                        AND SemanticTag__c = :sTagR.Id
                                        AND RelatedHelpTopic__c IN :rmKeys.keySet()];
            
            rmKeys.clear();
            for (HelpRelationship__c HR : existingMemberships) {
                rmKeys.put(HR.RelatedHelpTopic__c, HR);
            }
            
            for (HelpRelationship__c HR : rootMembers){              
                                
                LI = new ServiceIHLists.ListingItem();
                
                LI.Id = HR.RelatedHelpTopic__r.Id;
                LI.Label = HR.RelatedHelpTopic__r.Name;
                LI.Title = HR.RelatedHelpTopic__r.Summary__c;
                LI.Icon = '';
                LI.IconLabel = '';
                LI.IconTitle = '';
                LI.Parameters = '';
                
                // Tags don't have a "dynamic" action from a configuration tool: their (tag toggling) purpose
                // is fixed in the Tag LUX control that processes clicks...
                LI.ActionCode = 'NOT_USED';     
                
                // Vary styling based on whether current topic has this tag
                if (rmKeys.get(LI.Id) != null) {
                    LI.StyleClass = 'IATool Tagged';
                    
                } else {
                    LI.StyleClass = 'IATool UnTagged';
                }
                
                // Add recency marker where relevant
                if (HR.RelatedHelpTopic__r.LastModifiedDate > dTRecenyLimit) {
                    LI.StyleClass += ' ' + recencyMarker;
                    LI.Title = '** ' + mapDlgLocs.get('AdviceLabelModified') + ' ** ' + LI.Title;
                }
                
                LIs.add(LI);                
            }

            retVal = JSON.serialize(LIs);
            
            
            // Tack on details of the root tag for which we were asked to retrieve members - for use in card title
            if (rootMembers.size() > 0) {
                NVP = new NameValuePair('CardTitle', 'Title', rootMembers[0].ReferringTopic__r.Name);
                retVal = concatenateJSON(retVal, JSON.serialize(NVP));
            } else {
                // If pool has no tags, try to use the name of the pool itself as a title               
                try {
                    HelpTopic__c HT = [SELECT Name FROM HelpTopic__c WHERE Id = :rootTag];
                    NVP = new NameValuePair('CardTitle', 'Title', HT.Name);
                    retVal = concatenateJSON(retVal, JSON.serialize(NVP));

                } catch (exception ex) {}
            }     

        } catch (exception e) {
            retVal = 'Error: (LUX Get Tags)' + e.getMessage();
        }
        
        return retVal;
    }


    // Add a topic, Member, to a tag pool defined by topic Root, then return to ToolContext:
    // To skip return to a particular context and simply return having created the member tag, pass a ToolContext of '[NoContext]'
    @AuraEnabled
    global static string addMemberTag (string root, string member, string ToolContext) {
        
        ServiceSecurity sS = new ServiceSecurity();
        string retVal;
        SemanticTag__c sTagM;
        HelpRelationship__c HR;
        
        
        try {                           
            sTagM = [SELECT Id FROM SemanticTag__c WHERE Name = 'Member'];

            
            try {
                // Operation is only allowed for those with user rights
                if (sS.IsAllowed(ServiceSecurity.KnownSecureOperations.EditHelp)) {
                    
                    // Create the tag   
                    HR = new HelpRelationship__c();
                    HR.ReferringTopic__c = root;
                    HR.RelatedHelpTopic__c = member;
                    HR.SemanticTag__c = sTagM.Id;
                    upsert HR;
                }
                
                
            } catch (exception ex) {
                // Do nothing here: probably just that selected topic is already a member
                // so relationship already exists...
            }
            
            // Now return the updated tag cloud - unless we were aksed not to do so
            if (ToolContext == '[NoContext]') {
                retVal = HR.Id;
            } else {
                retVal = getTools(ToolContext, 'GetTags', member, '', root, false);
            }
            
            
        } catch (exception e) {
            retVal = 'Error: (LUX Add Member Tag) ' + e.getMessage();
        }
        
        return retVal;
    }


    // Remove a topic, Member, from a tag pool defined by topic Root, then return to ToolContext:
    // To skip return to a particular context and simply return having removed the member tag, pass a ToolContext of '[NoContext]'
    // If deleteMember is true, delete the underlying topic as well as the member relationship
    // If deleteRoot is true, delete the topic that defines the tag pool
    @AuraEnabled
    global static string removeMemberTag (string root, string member, boolean deleteMember, boolean deleteRoot, string ToolContext) {
        
        ServiceSecurity sS = new ServiceSecurity();
        string retVal;
        SemanticTag__c sTagM;
        HelpRelationship__c HR;
        HelpTopic__c HT;
        
        
        try {                           
            sTagM = [SELECT Id FROM SemanticTag__c WHERE Name = 'Member'];

            
            try {
                // Operation is only allowed for those with user rights
                if (sS.IsAllowed(ServiceSecurity.KnownSecureOperations.EditHelp)) {
                    
                    HR = [SELECT Id FROM HelpRelationship__c 
                            WHERE ReferringTopic__c = :root
                            AND RelatedHelpTopic__c = :member
                            AND SemanticTag__c = :sTagM.Id];
                    
                    delete HR;
                    
                    if (deleteMember == true) {
                        HT = [SELECT Id FROM HelpTopic__c WHERE Id = :member];
                        delete HT;
                    }
                    
                    if (deleteRoot == true) {
                        HT = [SELECT Id FROM HelpTopic__c WHERE Id = :root];
                        delete HT;
                    }
                }
                
                
            } catch (exception ex) {
                // Do nothing here: probably just that selected topic is already a member
                // so relationship already exists...
            }
            
            // Now return the updated tag cloud - unless we were aksed not to do so
            if (ToolContext == '[NoContext]') {
                retVal = '';
            } else {
                retVal = getTools(ToolContext, 'GetTags', member, '', root, false);
            }
            
            
        } catch (exception e) {
            retVal = 'Error: (LUX Add Member Tag) ' + e.getMessage();
        }
        
        return retVal;
    }


    // Toggle the tag TagId on topic HTID to state tagged
    @AuraEnabled
    global static string toggleTag (string HTID, string tagId, boolean tagged, string ToolContext) {
        
        ServiceSecurity sS = new ServiceSecurity();
        string retVal;
        SemanticTag__c sTagM;
        SemanticTag__c sTagR;
        string rootTag;
        
        
        try {                           
            sTagM = [SELECT Id FROM SemanticTag__c WHERE Name = 'Member'];
            sTagR = [SELECT Id FROM SemanticTag__c WHERE Name = 'Relative'];
            
            try {

                // Get the root tag of which the requested tag is a member
                HelpRelationship__c HR = [SELECT ReferringTopic__c 
                                            FROM HelpRelationship__c 
                                            WHERE RelatedHelpTopic__c = :tagId
                                            AND SemanticTag__c = :sTagM.Id];
                
                rootTag = HR.ReferringTopic__c;
                
                // Operation is only allowed for those with user rights
                if (sS.IsAllowed(ServiceSecurity.KnownSecureOperations.EditHelp)) {
                    
                    if (tagged == true) {
                        // Create the tag   
                        HR = new HelpRelationship__c();
                        HR.ReferringTopic__c = HTID;
                        HR.RelatedHelpTopic__c = tagId;
                        HR.SemanticTag__c = sTagR.Id;
                        
                        upsert HR;
                                        
                    } else {
                        // Delete the tag
                        HR = [SELECT Id
                                    FROM HelpRelationship__c
                                    WHERE ReferringTopic__c = :HTID
                                    AND RelatedHelpTopic__c = :tagId
                                    AND SemanticTag__c = :sTagR.Id];
                        delete HR;
                    }
                    
                }
                
                // Now return the updated tag cloud
                retVal = getTools(ToolContext, 'GetTags', HTID, '', rootTag, false);
        
                
            } catch (exception ex) {
                retVal = 'Error: (LUX Get Tags) - Tag to ' + tagged + ' - ' + ex.getMessage();
            }
            
        } catch (exception e) {
            retVal = 'Error: (LUX Get Tags) ' + e.getMessage();
        }
        
        return retVal;
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Topic creation / editing controls (see also D&D support)
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    // Get topic only - no additional info
    @AuraEnabled
    global static string getTopicViaHTID(string HTID) {
        
        string retVal;
        
        try {
            ControllerHelpContent CH = new ControllerHelpContent(true);
                
            // We don't want to call GetHelp as this is rather "weighty" for our needs:
            // Instead, just get the required topic in these cases
            CH.getTopicViaHTID(HTID, false);        
            retVal = JSON.serialize(CH.Hlp); 
            
        } catch (exception e) {
            retVal = 'Error obtaining Help Topic "' + HTID + '": ' + e.getMessage();
        }
        
        return retVal;
    }

    
    // Delete multiple topics at once   
    @AuraEnabled
    global static string deleteTopics (string topicJSON) {
        string retVal = '';
        
        try {
            // Requires author permissions
            ServiceSecurity Security = new ServiceSecurity(); 
            Boolean[] Perms = Security.UserPermissions();
            
            if (! Perms[1] && ! Perms[2]) {
                map<string, string> mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false);
                retVal = mapGlbLocs.get('MessageNoRights');
                
            } else {
                List<HelpTopic__c> HTs = (List<HelpTopic__c>) JSON.deserialize(topicJSON, List<HelpTopic__c>.class);
                
                delete HTs;
                retVal = '';
            }
        
        } catch (exception e) {
            retVal = 'Error (LUX Delete Topics): ' + e.getMessage();
        }
        
        return retVal;
    }
    
    
    // Save multiple amended topics at once
    @AuraEnabled
    global static string saveTopics (string topicJSON) {
        string retVal = '';
        
        try {
            
            // Requires author permissions
            ServiceSecurity Security = new ServiceSecurity(); 
            Boolean[] Perms = Security.UserPermissions();
            
            if (! Perms[1] && ! Perms[2]) {
                map<string, string> mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false);
                retVal = mapGlbLocs.get('MessageNoRights');
                
            } else {
                List<HelpTopic__c> HTs = (List<HelpTopic__c>) JSON.deserialize(topicJSON, List<HelpTopic__c>.class);
                ServiceIHLists.ListingItem LI;
                ServiceIHLists.ListingItem[] LIs = new ServiceIHLists.ListingItem[]{};
                
                upsert HTs;
                
                for (HelpTopic__c HT : HTs) {
                    
                    LI = new ServiceIHLists.ListingItem();
            
                    LI.Id = HT.Id;
                                        
                    // In these cases, use icon label to hold Element Type -> class on listings controls
                    LI.Icon = 'fa-question';
                    LI.IconLabel = '';
                    LI.IconTitle = '';
                    LI.Label = HT.Name;
                    LI.Title = HT.Summary__c;                                     
                    LI.ActionCode = 'HelpCallout';
                    LI.Parameters = '';                    
                    LI.StyleClass = '';
                    LI.RowState = '';
    
                    LIs.add(LI);
                }
                
                retVal = JSON.serialize(LIs);
            }
            
        } catch (exception e) {
            retVal = 'Error (LUX Save Topics): ' + e.getMessage();
        }
        
        return retVal;
        
    }
    
    
    // Wrapper to existing method for getting a default / blank topic
    @AuraEnabled
    global static string getDefaultTopic () {
        
        string retVal;
        ServiceSecurity sS = new ServiceSecurity();
        map<string,string> mapGlbLocs;
                
        try {
            // Operation is only allowed for those with user rights
            mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false);
            
            if (sS.IsAllowed(ServiceSecurity.KnownSecureOperations.EditHelp)) {         
                ControllerHelpContent CH = new ControllerHelpContent(true);
                HelpTopic__c HT = cH.getDefaultHelpTopic();
                retVal = JSON.serialize(HT);
                
            } else {
                retVal = mapGlbLocs.get('MessageNoRights');             
            }
            
        } catch (exception e) {
            retVal = 'Error (LUX get Default Topic): ' + e.getMessage();
        }
        
        return retVal;
    }
    

    // Wrapper to existing Clone Topic method   
    @AuraEnabled
    global static string cloneTopic (string HTID, string cloneNames, string cloneRels) {
        string retVal;
        
        try {
            ControllerHelpContent CH = new ControllerHelpContent(true);
            
            // We don't want to call GetHelp as this is rather "weighty" for our needs:
            // Instead, just get the required topic in these cases
            CH.getTopicViaHTID(HTID, false);
            
            CH.CloneTopicNames = cloneNames;
            CH.CloneTopicRels = cloneRels;
            CH.cloneTopic();

            retVal = CH.Diags;
            
        } catch (exception e) {
            retVal = 'Error (LUX Clone Topic): ' + e.getMessage();
        }
        return retVal;
    }

        
    // Wrapper to get topic editing pick lists (templates, custom styles, visibility, vote sets, page layouts)
    @AuraEnabled
    global static string getTopicEditingControls () {
        string retVal;
        
        try {
            ControllerHelpContent CH = new ControllerHelpContent(true);
            NameValuePair[] optsStyle = new NameValuePair[]{};
            NameValuePair[] optsVisibility = new NameValuePair[]{};
            HelpVoteSet__c[] VS = new HelpVoteSet__c[]{};
            HelpedPageLayout__c[] HPLs = new HelpedPageLayout__c[]{};

            // Callout, Full & Lightning templates
            retVal = getTemplatesC();
            retVal = concatenateJSON(retVal, getTemplatesF());
            retVal = concatenateJSON(retVal, getTemplatesL());
            
            // For custom styles, first get the "traditional" select options:
            // These are not sObject lookup records, so use a simple class to represent them.
            // Note that controller help already adds a "blank" no selection value for us...
            for (SelectOption Opt : CH.getCustomStyles()) {
                optsStyle.add(new NameValuePair('CustomStyles', Opt.getLabel(), Opt.getValue()));
            }           
            retVal = concatenateJSON(retVal, JSON.serialize(optsStyle));
            
            // Visibility settings: here we need to add our own blank value
            optsVisibility.add(new NameValuePair('Visibilities', '--None--', null));
            
            Schema.DescribeFieldResult fieldResult = HelpTopic__c.Visibility__c.getDescribe();          
            for(Schema.PicklistEntry f : fieldResult.getPicklistValues()) {
                optsVisibility.add(new NameValuePair('Visibilities', f.getLabel(), f.getValue()));
            }       
            
            retVal = concatenateJSON(retVal, JSON.serialize(optsVisibility));
            
            // Help Vote Sets
            try {
                // Add a "blank" / no selection item so "none" can be selected
                HelpVoteSet__c V = new HelpVoteSet__c();
                V.Id = null;
                V.Name = '--None--';
                V.QuestionText__c = '- - -';
                V.ImageClass__c = '';               
                VS.add(V);
                                
                for (HelpVoteSet__c HVS : [SELECT Id, Name, QuestionText__c, ImageClass__c FROM HelpVoteSet__c ORDER BY Name]) {
                    VS.add (HVS);
                }
                                
                retVal = concatenateJSON(retVal, JSON.serialize(VS));
                
            } catch (exception ex){}
                    

            // Helped Page Layouts
            try {
                // Add a "blank" / no selection item so "none" can be selected
                HelpedPageLayout__c HPL = new HelpedPageLayout__c();
                HPL.Id = null;
                HPL.Name = '--None--';              
                HPLs.add(HPL);              
                
                for (HelpedPageLayout__c PL : [SELECT Id, Name FROM HelpedPageLayout__c ORDER BY Name]) {
                    HPLs.add (PL);
                }
                                
                retVal = concatenateJSON(retVal, JSON.serialize(HPLs));
                
            } catch (exception ex){}

            
        } catch (exception e) {
            retVal = 'Error getting Topic editing tools: ' + e.getMessage();
        }
        return retVal;
    }

    // Wrappers for Topic Editor pick lists
    @AuraEnabled 
    global static string getTemplatesC () {
        string retVal;
        try {
            ControllerHelpContent CH = new ControllerHelpContent();
            List<HelpTopicTemplate__c> HTTs = CH.getTemplateRecordsC();
            retVal = JSON.serialize(HTTs);
        } catch (exception e) { 
            retVal = '';
        }
        return retVal;      
    }
    @AuraEnabled 
    global static string getTemplatesF () {
        string retVal;
        try {
            ControllerHelpContent CH = new ControllerHelpContent();
            List<HelpTopicTemplate__c> HTTs = CH.getTemplateRecordsF();
            retVal = JSON.serialize(HTTs);
        } catch (exception e) {
            retVal = '';
        }
        return retVal;      
    }
    @AuraEnabled 
    global static string getTemplatesL () {
        string retVal;
        try {
            ControllerHelpContent CH = new ControllerHelpContent();
            List<HelpTopicTemplate__c> HTTs = CH.getTemplateRecordsL();
            
            // Add a "blank" / no selection item so "none" can be selected
            HelpTopicTemplate__c HTT = new HelpTopicTemplate__c();
            HTT.Id = null;
            HTT.TemplateType__c = 'Lightning Viewer';
            HTT.Name = '--Standard Topic Details--';
            
            HTTs.add(HTT);
            
            retVal = JSON.serialize(HTTs);
        } catch (exception e) {
            retVal = '';
        }
        return retVal;      
    }
    @AuraEnabled 
    global static string getElementsForLayout (string LayoutId) {
        string retVal;
        try {
            HelpedElement__c[] Elems = new HelpedElement__c[]{};

            // Add a "blank" / no selection item so "none" can be selected
            HelpedElement__c HE = new HelpedElement__c();
            HE.Id = null;
            HE.Name = '--None--';              
            Elems.add(HE);              
            
            for(HelpedElement__c El : [SELECT Id, Name 
                        FROM HelpedElement__c
                        WHERE HelpedPageLayout__c = :LayoutId
                        ORDER BY Name]) {
                   Elems.add(El);       
            }
            
            retVal = JSON.serialize(Elems);
        } catch (exception e) {
            retVal = '';
        }
        return retVal;      
    }
    

    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Topic 'layout design mode' support
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    
    // Get the list of fields (API names and labels) applicable to a particular object (e.g., Topics - whose
    // attributes we may wish to position on a layout)
    @AuraEnabled
    global static string getFieldList (string ObjectAPIName) {
        string retVal;
        try {
            NameValuePair NVP;
            NameValuePair[] NVPs = new NameValuePair[]{};
            Schema.DescribeFieldResult DFR;     
            Schema.DescribeSObjectResult R = ServiceSchema.getObjectDetailsByName (ObjectAPIName);
            Map<String, Schema.SObjectField> fieldMap = R.fields.getMap();
    
            for (string F : fieldMap.keySet()) {
                DFR = fieldMap.get(F).getDescribe();
                NVP = new NameValuePair('FieldList', DFR.getName(), DFR.getLabel());
                NVPs.add(NVP);
            }       
    
            retVal = JSON.serialize(NVPs);
            
        } catch (exception e) {
            retVal = '';
        }
        return retVal;      
    }
    
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Wrappers for bookmarking ops:
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    // Context parameters are to re-establish LUX component screen furniture after bookmarking Op:
    // Params should be the ID of the Topic to bookmark / un-bookmark
    @AuraEnabled
    global static string addBookmark (string ToolContext, string ActionCode, string IHContext, string Params) {
        string retVal;
        
        try {
            // To add a bookmark, we first need to obtain the relevant help topic
            ControllerHelpContent CH = new ControllerHelpContent(true);
            
            // We don't want to call GetHelp as this is rather "weighty" for our needs:
            // Instead, just get the required topic in these cases
            CH.getTopicViaHTID(Params, false);
            
            // This should set Hlp - so we can bookmark it...
            CH.addBookmark();
            
            system.debug('addBookmark - ActionCode: ' + ActionCode + ': Params: ' + Params);
            
            // Re-process tools on completion, to ensure (e.g.) bookmarked state is updated
            retVal = getTools(ToolContext, ActionCode, IHContext, '', Params, false);
            
        } catch (exception e) {
            retVal = 'Error adding a Bookmark: ' + e.getMessage();
        } 
        return retVal;
    }
    
    @AuraEnabled
    global static string removeBookmark (string ToolContext, string ActionCode, string IHContext, string Params) {
        string retVal;
        
        try {

            // To remove a bookmark, we first need to obtain the relevant help topic
            ControllerHelpContent CH = new ControllerHelpContent(true);
            
            // We don't want to call GetHelp as this is rather "weighty" for our needs:
            // Instead, just get the required topic in these cases
            CH.getTopicViaHTID(Params, false);
            
            // This should set Hlp: we need to set topic id member data before removal in this case
            CH.THelpId = CH.Hlp.Id;
            CH.removeBookmark();
            
            // Re-process tools on completion, to ensure (e.g.) bookmarked state is updated
            retVal = getTools(ToolContext, ActionCode, IHContext, '', Params, false);
            
        } catch (exception e) {
            retVal = 'Error removing a Bookmark: ' + e.getMessage();
        }   
        return retVal;  
    }
    

    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Help / Guide Enable support
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    // Add a new reading list featuring a specified topic as its only entry
    @AuraEnabled
    global static string addReadingList (string HTID) {
        
        string retVal;
        map<string,string> mapDlgLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false);   
           
        try {
            
            // Delegate to reading list controller logic
            ControllerRListInfo cRL = new ControllerRListInfo();
            retVal = cRL.createAndLinkFromLUX(HTID);
                           
        } catch (exception e) {
            retVal += 'Error (Add Reading List): ' + e.getMessage();
        }
        
        return retVal;
        
    }
    
    
    // add an independent reading list record for creating new record via list view
    @AuraEnabled
    public static String addStandaloneReadingList() {
        try {
            iahelp__HelpReadingList__c rl = new iahelp__HelpReadingList__c();
            rl.Name = 'New Reading List';
            insert rl;
            return rl.Id;
        } catch (Exception e) {
            return 'Error: ' + e.getMessage();
        }
    }


    // Delete the specified reading list / guide
    @AuraEnabled
    global static string deleteReadingList (string RLID) {
        
        string retVal = 'RLID=' + RLID + '... ';
        map<string,string> mapDlgLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false);   
        
        retVal +='Locs OK... ';
        
        try {
            // Use LUX-flavour constructor, which is differentiated by passing of RLID
            ControllerRListInfo cRL = new ControllerRListInfo(RLID);
            
            retVal += 'cRL OK... ';
            
            // Attempt the delete
            cRL.deleteReadingList();
            
            retVal += 'cRL delete done... ';
            
            // We're not interested in return value, but can examine diags, which should be blank if successful
            if (cRL.Diags == '') {
                retVal += mapDlgLocs.get('MessageGenericTaskComplete');
            } else {
                retVal += mapDlgLocs.get('MessageGenericError') + ' (Delete Reading List): ' + cRL.Diags;
            }
            
        } catch (exception e) {
            retVal += 'Error (Delete Reading List): ' + e.getMessage();
        }
        
        return retVal;
        
    }
    

    // Get the steps currently defined for a guide
    @AuraEnabled
    global static string getGuideSteps (string GuideId) {
        
        string retVal;
        
        try {
            ControllerSettings cS = new ControllerSettings();
            HelpReadingListEntry__c[] RLEs = cS.getGuideSteps(GuideId);
            
            // As the JSON serialiser skips apparently blank fields, we need to specifically set empty values to "null"     
            for (HelpReadingListEntry__c RLE : RLEs) {
                if (RLE.iahelp__HelpTopic__r.Name == null) {RLE.iahelp__HelpTopic__r.Name = null;}
                if (RLE.iahelp__HelpTopic__r.iahelp__Summary__c == null) {RLE.iahelp__HelpTopic__r.iahelp__Summary__c = null;}
                if (RLE.iahelp__HelpTopic__r.iahelp__ImageURL__c == null) {RLE.iahelp__HelpTopic__r.iahelp__ImageURL__c = null;}
                if (RLE.iahelp__HelpTopic__r.iahelp__VideoURL__c == null) {RLE.iahelp__HelpTopic__r.iahelp__VideoURL__c = null;}
                if (RLE.iahelp__HelpTopic__r.iahelp__GuideStepMode__c == null) {RLE.iahelp__HelpTopic__r.iahelp__GuideStepMode__c = null;}
                if (RLE.iahelp__HelpTopic__r.iahelp__GuidedRecord__c == null) {RLE.iahelp__HelpTopic__r.iahelp__GuidedRecord__c = null;}
                if (RLE.iahelp__HelpTopic__r.iahelp__GuideCallout__c == null) {RLE.iahelp__HelpTopic__r.iahelp__GuideCallout__c = null;}
            }   

            retVal = JSON.serialize(RLEs);
            
        } catch (exception e) {
            retVal = 'Error (Get Guide Steps)' + e.getMessage();
        }
        
        return retVal;
    }


    // Wrapper for ControllerConfirmActions / save amendments to HEs or Guides
    @AuraEnabled
    global static string CCASaveChanges (string oCode, string Opts, string[] elemsC, string[] elemsD, string GuideId) {
                
        string retVal;
        string localDiags = '';
        ControllerConfirmActions CCA = new ControllerConfirmActions();
        ControllerSearch.SearchResult[] srC = new  ControllerSearch.SearchResult[]{};
        ControllerSearch.SearchResult[] srD = new  ControllerSearch.SearchResult[]{};
        ControllerSearch.SearchResult sR;
        string D1 = ControllerSettings.D1;
        string D2 = ControllerSettings.D2;
        string[] parms;
        string callerPageURL = Url.getOrgDomainURL().toExternalForm() + '/' + oCode;
        
        
        try {
            // We need to "initialise" the controller (for internationalisations etc). This would 
            // traditionally have happened as part of VF page controller lifecycle (always show actions before save changes)
            // but we must do this manually here, then set controller options as required
            CCA.initialise();
            CCA.setCPURL (callerPageURL);
            CCA.Opts = Opts;
            
            // Act according to specified option...
            if (Opts == '1') {
                
                // Help enabling:
                // Build list of elements to create and supply these to controller
                for (string eC : elemsC) {
                    
                    // Incoming element creation instructions will be in the form:
                    // Identifier [D1] Element Type [D1] Topic ID (if a topic is to be re-used)
                    parms = eC.split(D1);
                    localDiags = 'parms length: ' + parms.size() + '... ';
                    
                    sR = new ControllerSearch.SearchResult();

                    if (parms[2] + '' != 'null') {
                        sR.Id = parms[2];                   // existing HTID
                    } else {
                        sR.Id = '';
                    }
                    localDiags += 'sR.id set... ';
                    
                    sR.Name = parms[0];                 // elem ident
                    sR.Link = 'true';                   // always true - confirm creation
                    sR.Summary = parms[1];              // element type
                    
                    srC.add(sR);
                    localDiags += 'all sR items set... ';
                }
                
                CCA.elemsC = srC;
                localDiags += 'CCA elemsC set... ';
                
                
                // Build list of elements to delete and supply these to controller
                for (string eD : elemsD) {
                    
                    // Incoming element deleting instructions will be in the form:
                    // Identifier [D1] Topic ID (if a topic is to be deleted)
                    parms = eD.split(D1);
                    sR = new ControllerSearch.SearchResult();
                    
                    if (parms[1] + '' != 'null') {
                        sR.Id = 'true';                                     // delete related topic (stringy boolean)
                    } else {
                        sR.Id = 'false';                                    // DO NOT delete related topic (stringy boolean)
                    }
                    
                    sR.Name = parms[0] + D1;                                // elem ident [d1]
                    sR.Link = 'true';                                       // always true - confirm deletion
                    sR.Summary = 'null' + D2 + parms[1] + D1 + 'null';      // HTID to delete info: null [d2] HTID [d1] null
                    
                    srD.add(sR);                                        
                }
                
                CCA.elemsD = srD;
                localDiags += 'CCA elemsD set... ';
                
                
                // Fire saving and return resulting diagnostics
                CCA.saveChanges();
                retVal = CCA.Diags;
                
                
            } else if (Opts == '2') {
                
                // Guide enabling:
                // Build list of elements to create and supply these to controller
                for (string eC : elemsC) {
                    
                    // Incoming step creation instructions will be in the form:
                    // RLEId [D1] Element identifier [D1] Step Name [D1] Step Summary [D1] Step Order [D1] Step Image [D1] Step Video
                    parms = eC.split(D1);
                    localDiags = 'parms length: ' + parms.size() + '... ';
                    
                    sR = new ControllerSearch.SearchResult();
                
                    sR.Link = 'true';                   // always true - confirm creation
                    
                    sR.Id = parms[1];
                    sR.Name = parms[2];
                    
                    // NB: we must default summary text if this is not supplied (as underlying RLE.HT__r will require this / blank not allowed)
                    // We default to the value that our guide prompts IGNORE - so that it is possible to have a step featuring header text
                    // only, whilst respecting the mandatory status of topic summary...
                    if (parms[3] == null || parms[3] == '') {
                        sR.Summary = parms[0] + D1 + 'Field' + D1 + 'NEW' + D1 + parms[4]; // + D1 + parms[5] + D1 + parms[6];
                    } else {
                        sR.Summary = parms[0] + D1 + 'Field' + D1 + parms[3] + D1 + parms[4]; // + D1 + parms[5] + D1 + parms[6];
                    }
                    
                    srC.add(sR);
                    localDiags += 'all sR items set... ';
                }
                
                CCA.elemsC = srC;
                localDiags += 'CCA elemsC set... ';
                
                
                // Build list of elements to delete and supply these to controller
                for (string eD : elemsD) {
                    
                    // Incoming element deleting instructions will be a simple array of RLE Ids to delete 
                    sR = new ControllerSearch.SearchResult();
                    
                    sR.Link = 'true';                                       // always true - confirm deletion
                    
                    // Summary expected by CCA is expected to be a split by D1 - with only the 1st element (RLE Id) used...
                    sR.Summary =  eD + D1 + 'Field';
                    
                    srD.add(sR);                                        
                }
                
                CCA.elemsD = srD;
                localDiags += 'CCA elemsD set... ';
                
                
                // Specify the guide being dealt with as well as steps to create / delete, then fire saving and return resulting diagnostics    
                CCA.GuideId = GuideId;
                CCA.saveChanges();
                retVal = CCA.Diags;             
                
                // Need to get the ID of any new guide: this should have been placed back
                // into controller's member data: tack this on to return value
                retVal += ' [' + CCA.GuideId + ']';
                 
                
            } else {
                retVal = 'Error (CCA Save changes): option not supported (' + Opts + ')';
            }
            
        } catch (exception e) {
            retVal = 'Error (CCA Save changes): ' + e.getMessage() + ' : ' + localDiags + ' : ' + CCA.Diags;
        }
        
        return retVal;
    }


    // Wrapper for WServices / save amendments to HEs (basic version / no topic re-use etc)
    @AuraEnabled 
    global static string SaveHEChanges(string IHContext, String ElemsToCreate, String ElemsToDelete, string Delimiter) {
        
        // heids = identifiers
        // urls = url that can resolve to sfobjid
        // etypes = 'Field'
        // htids = null (new topics)
        String[] URLs = new String[]{};
        String[] eTypes = new String[]{};
        String[] HEIDs;
        String[] delHTs;
        String U = URL.getOrgDomainURL().toExternalForm() + '/' + IHContext;
        String T = 'Field';
        
        HEIDs = ElemsToCreate.split(Delimiter);
        if (HEIDs.size() > 0) {
            for (string s : HEIDs) {
                URLs.add (U);
                eTypes.add (T);
            }
            WServices.createHelpedElements(HEIDs, URLs, eTypes, null);
        }
        
        HEIDs = ElemsToDelete.split(Delimiter);
        if (HEIDs.size() > 0) {
            WServices.deleteHelpedElements(HEIDs, delHTs);
        }
        

        // Assuming no issues to this point, continune as if retrieving help
        return getTools('QAM', 'AllHelp', IHContext, '', null, false);
                
    }
    
    
    // Get information about the helped elements that could be created for a given "context" (approximation of layout):
    // IHContext = LUX record ID, ObjectName = LUX object name
    @AuraEnabled
    global static string getHelpableElements(string IHContext, string ObjectName) {
        
        string retVal;
        string objId;
        ServiceSchema sS = new ServiceSchema();
        Schema.DescribeFieldResult Fld;
        String ExistingElementId;
        ControllerIHQAMSettings cIHQ;
        List<ServiceIHLists.ListingItem> LIs = new List<ServiceIHLists.ListingItem> ();
        ServiceIHLists.ListingItem LI;
        ConfigurationItem__c[] LXTs = new ConfigurationItem__c[]{};
        ConfigurationItem__c LXT;
    
        try {
            // In these cases, we want to "hard wire" some non-contextual configuration tools:
            // On entering Help Enable mode, these are Save and Cancel changes...
            
            LXT = new ConfigurationItem__c();
            LXT.ActionCode__c = 'HelpEnableModeSave';
            LXT.DisplayOrder__c = 1;
            LXT.DisplayGrouping__c = '[Default]';
            LXT.HasDivider__c = false;
            LXT.ToggleNext__c = 0;
            LXT.TogglePrev__c = 0;
            LXT.Label__c = 'ButtonSave';
            LXT.TipText__c = 'ButtonSave';
            LXT.ToolClass__c = '';
            LXT.IconClass__c = 'fa-check';
            LXT.IconContent__c = '';
            LXT.ToolContext__c = '';
            LXT.Type__c = 'Footer';
            LXT.ToolFilter__c = 0;
            LXT.PermissionLevel__c = 4;         
            LXTs.add(LXT);
            
            LXT = new ConfigurationItem__c();
            LXT.ActionCode__c = 'HelpEnableModeCancel';
            LXT.DisplayOrder__c = 1;
            LXT.DisplayGrouping__c = '[Default]';
            LXT.HasDivider__c = false;
            LXT.ToggleNext__c = 0;
            LXT.TogglePrev__c = 0;
            LXT.Label__c = 'ButtonCancel';
            LXT.TipText__c = 'GenericCancel';
            LXT.ToolClass__c = '';
            LXT.IconClass__c = 'fa-times';
            LXT.IconContent__c = '';
            LXT.ToolContext__c = '';
            LXT.Type__c = 'Footer';
            LXT.ToolFilter__c = 0;
            LXT.PermissionLevel__c = 4;         
            LXTs.add(LXT);
            
            retVal = JSON.serialize(LXTs);
            
            
            // Get the schema object representing the current context/object
            objId = ServiceSchema.getObjectIdByName(ObjectName);
            Schema.DescribeSObjectResult sObj = sS.getObjectDetails(objId);
            
            // For the object, get its fields
            Map<String, Schema.SObjectField> FMap = sObj.Fields.getMap();
            
            // Get the set of elements already in existence for this context
            // (Initialising should populate Helped Elements member data)
            cIHQ = new ControllerIHQAMSettings(true);
            cIHQ.LUXParams = IHContext;
            cIHQ.initializeIH1QAM();
                        
            // For each of its fields, check whether we have a helped element (fields only)
            // on this layout representing it
            for (string FKey : FMap.keySet()){              
                
                Fld = FMap.get(FKey).getDescribe();
                ExistingElementId = '';
                
                if (cIHQ.HelpedElements != null) {
                    for (ControllerIHQAMSettings.SearchResultQAM SR : cIHQ.HelpedElements) {
                        if (SR.Element.Identifier__c.equals(Fld.getLabel())) {
                            ExistingElementId = SR.Element.Id;
                            break;
                        }
                    } 
                }
                
                // For each field, add a Listing Item, with meta data reflecting whether or not matching element exists
                LI = new ServiceIHLists.ListingItem();

                LI.Label = Fld.getLabel();
                LI.Icon = 'fa-puzzle-piece';
                LI.IconLabel = '';
                LI.IconTitle = '';
                LI.Parameters = '';
                
                if (ExistingElementId != '') {
                    LI.Id = ExistingElementId;
                    LI.Title = '';
                    LI.StyleClass = 'IATool Delete';
                    LI.ActionCode = 'HelpedElementDelete';
                    
                } else {
                    LI.Id = Fld.getLabel();
                    LI.Title = '';
                    LI.StyleClass = 'IATool Add';
                    LI.ActionCode = 'HelpedElementAdd';
                }
                
                LIs.add(LI);                
            }
            
            // Sort whatever elements we found then add their JSON to results   
            LIs.sort();         
            retVal = concatenateJSON(retVal, JSON.serialize(LIs));
            
            
            // Add required internationalisations
            NameValuePair NVP;
            map<string,string> mapDlgLocs = ServiceLocalisation.getDialogueLocalisations('LUXComponents', false);            
            for (string trans : mapDlgLocs.keyset()) {
                NVP = new NameValuePair('Internationalisations', trans, mapDlgLocs.get(trans));
                retVal = concatenateJSON(retVal, JSON.serialize(NVP));              
            }
            
            mapDlgLocs = null;
            mapDlgLocs = ServiceLocalisation.getDialogueLocalisations('iahelp__IHConfirmActions', false);            
            for (string trans : mapDlgLocs.keyset()) {
                NVP = new NameValuePair('Internationalisations', trans, mapDlgLocs.get(trans));
                retVal = concatenateJSON(retVal, JSON.serialize(NVP));              
            }
            
            mapDlgLocs = null;
            mapDlgLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false);            
            for (string trans : mapDlgLocs.keyset()) {
                NVP = new NameValuePair('Internationalisations', trans, mapDlgLocs.get(trans));
                retVal = concatenateJSON(retVal, JSON.serialize(NVP));              
            }

                        
        } catch (exception e) {
            retVal = 'Error obtaining Helped Elements: ' + e.getMessage();
        }
        
        return retVal;
    }
    
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Main card configuration / tool and data retrieval utilities
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    // Call to return just a unique identifier for a component
    @AuraEnabled
    global static string getGUID () {
        Blob bRadix = Crypto.GenerateAESKey(128);
        return EncodingUtil.ConvertTohex(bRadix);
    }
    

    // Potentially performance enhancing call to obtain (cachable) largely invariant data outside of other routine calls
    @AuraEnabled(cacheable=true)
    global static string getGlobals () {
        
        string retVal;
        NameValuePair NVP;                                  // For returning certain data not suited to listings
        NameValuePair[] NVPs = new NameValuePair[]{};       // Collection of the above for more efficient processing to JSON
        string strTemp;
        string timeStamps = getTimeStamp() + 'getGlobals - entry... ';
        
        ServiceSecurity sS = new ServiceSecurity();
        boolean[] UPs = sS.UserPermissions();
                
                    
        try {
            
            // Tack on global settings
            iahelp__IASetIHOrg__c GS = ControllerSettings.getSettings();
            retVal = concatenateJSON(retVal, JSON.serialize(GS));
            

            // Also, tack on the name of the portal page in play (may or may not be IHTools, IHToolsLUX etc.)    
            // NB: for now, hard wire the assumption here that SF1 is NOT an option        
            strTemp = '';
            strTemp = ControllerSettings.getPortalPageName(false);        
            NVP = new NameValuePair('PortalPage', 'PortalPage', strTemp);
            NVPs.add(NVP);            

            
            // Also, tack on details of the styles in the custom CSS as a style text block
            strTemp = '';
            ConfigurationItem__c CICustomerCSS = ControllerSettings.getCustomerCSSData();
            
            if (CICustomerCSS != null) {
                strTemp = CICustomerCSS.SupportingControls__c;
                
            } else {
                // Revert to CSS file if no configuration data present
                try {
                    PageReference P = new PageReference(ControllerSettings.getSettings().BrandCSS__c);
                    strTemp = P.getContent().toString();              
                } catch (exception ex) {}   
            }
            
            NVP = new NameValuePair('BrandCSS', 'BrandCSS', strTemp);
            NVPs.add(NVP);            
            

            // Also tack on internationalisations: note that there is considerable overlap with IHTools
            // (for IHDetail / topic editor) so we include translations for that directly. Ditto Globals

            map<string,string> mapDlgLocs = ServiceLocalisation.getDialogueLocalisations('LUXComponents', false);            
            for (string trans : mapDlgLocs.keyset()) {
                NVP = new NameValuePair('Internationalisations', trans, mapDlgLocs.get(trans));
                NVPs.add(NVP);            
            }

            mapDlgLocs = null;
            mapDlgLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false);            
            for (string trans : mapDlgLocs.keyset()) {
                NVP = new NameValuePair('Internationalisations', trans, mapDlgLocs.get(trans));
                NVPs.add(NVP);            
            }

            mapDlgLocs = null;
            mapDlgLocs = ServiceLocalisation.getDialogueLocalisations('Branding', false);            
            for (string trans : mapDlgLocs.keyset()) {
                NVP = new NameValuePair('Internationalisations', trans, mapDlgLocs.get(trans));
                NVPs.add(NVP);            
            }

            mapDlgLocs = null;
            mapDlgLocs = ServiceLocalisation.getDialogueLocalisations('ClientSide', false);            
            for (string trans : mapDlgLocs.keyset()) {
                NVP = new NameValuePair('Internationalisations', trans, mapDlgLocs.get(trans));
                NVPs.add(NVP);            
            }
                       
            mapDlgLocs = null;
            mapDlgLocs = ServiceLocalisation.getDialogueLocalisations('iahelp__IHConfirmActions', false);            
            for (string trans : mapDlgLocs.keyset()) {
                NVP = new NameValuePair('Internationalisations', trans, mapDlgLocs.get(trans));
                NVPs.add(NVP);            
            }

            mapDlgLocs = null;
            mapDlgLocs = ServiceLocalisation.getDialogueLocalisations('iahelp__IHSearchResults', false);            
            for (string trans : mapDlgLocs.keyset()) {
                NVP = new NameValuePair('Internationalisations', trans, mapDlgLocs.get(trans));
                NVPs.add(NVP);            
            }

            mapDlgLocs = null;
            mapDlgLocs = ServiceLocalisation.getDialogueLocalisations('iahelp__IHTools', false);            
            for (string trans : mapDlgLocs.keyset()) {
                NVP = new NameValuePair('Internationalisations', trans, mapDlgLocs.get(trans));
                NVPs.add(NVP);            
            }
            
            
            // Also, tack on permissions info
            NVP = new NameValuePair('Permissions', 'isUser', '' + UPs[0]);
            NVPs.add(NVP);            
            
            NVP = new NameValuePair('Permissions', 'isAnalyst', '' + UPs[3]);
            NVPs.add(NVP);            

            NVP = new NameValuePair('Permissions', 'isAuthor', '' + UPs[1]);
            NVPs.add(NVP);            

            NVP = new NameValuePair('Permissions', 'isAdministrator', '' + UPs[2]);
            NVPs.add(NVP);            
            
            
            // Also, tack on key object type data
            map<string,string> KnownRecordTypes = getKnownRecordTypes();
            for (string typ : KnownRecordTypes.keySet()) {
                NVP = new NameValuePair('ConfigToolFilterInfo', typ, KnownRecordTypes.get(typ));
                NVPs.add(NVP);            
            }
            
            
            // Set a 'working' card title
            NVP = new NameValuePair('CardTitle', 'CardTitle', ' ');
            NVPs.add(NVP);            
                       
            retVal = concatenateJSON(retVal, JSON.serialize(NVPs));
            
        } catch (exception e) {
            retVal = 'Error (Get Globals): ' +  e.getMessage();
        }
        
        return retVal;
    }


    // Calls for re-obtaining configuration tools and related internationalisations only where context changes / requires this
    @AuraEnabled
    global static string getClickablesJSON(string ToolContext, string ActionCode, string IHContext, integer userPermLevel) {

        string retVal = '';
        map<string,string> mapDlgLocs;
        NameValuePair NVP;
        NameValuePair[] NVPs = new NameValuePair[]{};
        
        try {
            List<ConfigurationItem__c> LXTs = getClickables (ToolContext, ActionCode, IHContext, userPermLevel);
            retVal = JSON.serialize(LXTs);
            
            // Tack translations on to clickables
            mapDlgLocs = ServiceLocalisation.getDialogueLocalisations('LUXComponents', false);            
            for (string trans : mapDlgLocs.keyset()) {
                NVP = new NameValuePair('Internationalisations', trans, mapDlgLocs.get(trans));
                NVPs.add(NVP); 
                
            }
           
            mapDlgLocs = null;
            mapDlgLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false);            
            for (string trans : mapDlgLocs.keyset()) {
                NVP = new NameValuePair('Internationalisations', trans, mapDlgLocs.get(trans));
                NVPs.add(NVP);
                
            }
            
            mapDlgLocs = null;
            mapDlgLocs = ServiceLocalisation.getDialogueLocalisations('ClientSide', false);            
            for (string trans : mapDlgLocs.keyset()) {
                NVP = new NameValuePair('Internationalisations', trans, mapDlgLocs.get(trans));
                NVPs.add(NVP);
                
            }
            

            // Tack bookmarked info onto this if relevant
            if (IHContext + '' != 'null' && IHContext + '' != 'undefined') {
                if (IHContext.length() == 15 || IHContext.length() == 18) {
                    string[] keyTypes = ControllerSettings.getSettings().SFObjectIds__c.split('\\^');
            
                    if (IHContext.startsWith(keyTypes[0])) {
                        ServiceIHLists.ListingItem LI = ServiceIHLists.getMetadataListingItem();                   
                        
                        try {
                            // Note we use the topic ID from our help controller here rather than taking params as supplied, 
                            // in case params were null and thus a default topic of some kind is in play...
                            HelpBookmark__c Bmk = [SELECT Id FROM HelpBookmark__c WHERE OwnerId = :UserInfo.getUserId() AND HelpTopic__c = :IHContext];
                                                            
                            // Reaching this point means bookmark exists: note this
                            LI.RowState = 'Bookmarked';
                                            
                        } catch (exception ex) {
                            LI.RowState = 'NotBookmarked';
                        }
                        
                        retVal = concatenateJSON(retVal, JSON.serialize(LI));
                        
                    }       
                }
            }
            
            
            retVal = concatenateJSON(retVal, JSON.serialize(NVPs));
            
        } catch (exception e){}
        
        return retVal;
    }
    private static List<ConfigurationItem__c> getClickables (string ToolContext, string ActionCode, string IHContext, integer userPermLevel) {
        
        List<ConfigurationItem__c> CandidateLXTs;                                       // A configuration tool / clickable definition
        List<ConfigurationItem__c> LXTs = new List<ConfigurationItem__c> ();            // Collection of the same, ultimately returned via JSON
        integer theBit = -1;
        string theBinary;
        integer iProductEdition;                                                        // Product edition information
        
        
        try {
            // Check product edition information
            iProductEdition = ServiceSubs.getFPIValue('iL2SProductOptions1');
            if (iProductEdition == 0) {
                // Product is 'off' - return no tools
                return LXTs;
            }
            
            // Get tools to show - taking user permissions into account
            CandidateLXTs = [SELECT Id, ActionCode__c, 
                                DisplayOrder__c, DisplayGrouping__c, HasDivider__c, 
                                ToggleNext__c, TogglePrev__c, ToggleActiveMarker__c,
                                Label__c, TipText__c, Description__c,
                                ToolClass__c, IconClass__c, IconContent__c, 
                                ToolContext__c, Type__c, SupportingControls__c,
                                ToolFilter__c, PermissionLevel__c, NegotiateToolbarLevel__c,
                                MinimumFormFactor__c,
                                SkipImportOverwrite__c, SkipExport__c
                                
                    FROM ConfigurationItem__c 
                    WHERE ToolContext__c = :ToolContext 
                    AND PermissionLevel__c <= :userPermLevel
                    ORDER BY DisplayOrder__c
                    LIMIT 1000];

            
            System.debug('CandidateLXTs===='+CandidateLXTs[0].MinimumFormFactor__c);
    
                        
            // Check each candidate tool against incoming list context
            // Least Significant Bit = 1 (NOT zero)
                
            if (ActionCode == 'QuickLinks') {theBit = 999;}     // Unlikely to need tools for these as they're globally defined?
            if (ActionCode == 'AllHelp') {theBit = 1;}
            if (ActionCode == 'HelpTopic') {theBit = 1;}
            if (ActionCode == 'FixedHelp') {theBit = 1;}
            if (ActionCode == 'PopularHelp') {theBit = 1;}
            if (ActionCode == 'Keywords') {theBit = 1;}
            if (ActionCode == 'HelpBookmarks') {theBit = 2;}
            if (ActionCode == 'ReadingLists' || ActionCode == 'ReadingListsXF' || ActionCode == 'ReadingListEntries') {theBit = 3;}
            if (ActionCode == 'ShowReadingLists') {theBit = 3;}
            if (ActionCode == 'AllResources') {theBit = 4;}
            if (ActionCode == 'AllRelatedHelp') {theBit = 5;}
            if (ActionCode == 'Search') {theBit = 6;}
            if (ActionCode == 'Stickies' || ActionCode == 'NewSticky') {theBit = 7;}            
            if (ActionCode == 'Guides') {theBit = 8;}         
                
                
            // Tree Nodes are a special case, as the Tree may feature different types of data 
            // (So we cannot assume the action code or context of itself implies the record type, as elsewhere)
            // Thus, in these cases we must leave it to the ROWS to decide - as the tree is rendered...
                
            if (ActionCode == 'TreeNodes') {
                // Do nothing with bit value - retain default of -1:

            } else if (ActionCode == 'CGDesignAttributes') {
                // In this case, we are seeking the design attributes that can be specified
                // for a component that is to be built by component generator: we are in the
                // generator's design mode and are seeking the attributes to populate UX controls
                // (pick lists) used to select the items to set as part of the generators 'ComponentDef' string...
                
                // In this case, the bit required is the one specified by IHContext: the calling lightning component
                // will have set this to one of the following:
                
                /*
                Autoform            = 1
                Detail              = 2
                Flow Launcher       = 3
                Image Viewer        = 4
                List                = 5
                RL Viewer           = 6
                Tabs                = 7
                Tree                = 8
                Utility 1           = 9
                */
                
                // As elsewhere, individual configuration items are marked with a tool filter acting as a bit switch specifying
                // the component(s) from the above list to which they apply...
                
                theBit = integer.valueOf(IHContext);        
              
            } else {
    
                // If bit not covered above, seek it via known record types
                if (theBit == -1) {
                    map<string,string> recTypeBits = getKnownRecordTypes(); 
                    string objId = IHContext;
                    
                    if (objId.length() > 2) {
                        objId = objId.subString(0,3);
                    }
                
                    for (string K : recTypeBits.keySet()){
                        if (recTypeBits.get(K) == objId) {
                            theBit = integer.valueOf(K);
                        }   
                    }
                    
                }
            }
                
                            
            for (ConfigurationItem__c LX : CandidateLXTs) {

                 
                // To avoid issues with JSON parser skipping null values
                if (LX.ToolClass__c == null) {LX.ToolClass__c = '';}

    
                // Only do this for certain LUX tool types
                if (LX.Type__c == 'Listing' || LX.Type__c == 'Header' || LX.Type__c == 'Body' || ActionCode == 'CGDesignAttributes') {
                        
                    // Look for special code here, "set" above, and "pass" all tools 
                    // if this is present: control itself must differentiate...
                    if (LX.ToolFilter__c >= 0 && theBit >= 0) {
    
                        // Translate the "filter" value (integer) of this tool into a binary string
                        theBinary = DecToBin(LX.ToolFilter__c);
                            
                        // Check the appropriate "bit" is set: only add the tool if so (and list context is known / bit is set)
                        if (theBinary.length() >= theBit  && theBit != -1) {
                             
                            if (theBinary.substring(theBinary.length() - theBit, theBinary.length() - theBit + 1) == '1') {
                                LXTs.add(LX);
                            }                   
                        }
                            
                    } else {
                        // Negative filter number = "always show"
                        LXTs.add(LX);
                    }
                        
                } else {
                    // For non-filtered tools, just add candidate to final list / no filtering required
                    LXTs.add(LX);
                }
                    
            }   // End candidates loop
                
        } catch (exception e) {}
        
        return LXTs;    
    }
    
    
    // Obtain the tools and records / listings suited to a specified context and additional parameters:
    // Return value is concatenated JSON, representing the following records in this order:
    
    // - Configuration tools suited to context, if any
    // - Requested individual record, or list of records
    // - Global settings data
    // - Personalisation settings
    // - Community Root info (as name value pair)
    // - Portal page name (as name value pair)
    // - Customer stylesheet contents (as name value pair)
    // - Internationalisations (as name value pair)
    // - Permissions settings
    // - Record type information - for matching config tool data to tree nodes (as name value pair)
    
    // IN ADDITION - FOR THE HelpTopic ACTION ONLY:
    // - Help Vote Options (applicable to the Vote Set for the Topic)
    
    //PASS:
    //      ToolContext:        A context defining the selection of configuraiton tools to include in return value
    //      ActionCode:         Specific action being requested
    //      IHContext:          Help context - e.g., a record or layout identified in play
    //      ClientComponentId:  Component ID of the specific calling component - allowing differentiation by page layout / component instance
    //      Params:             Optional, additional action-specific parameters 
    //      SkipGlobals:        True to avoid obtaining readily cached data, eg internationalisations, which can be obtained via a 
    //                              (cacheable) call to getGlobals, so improving performance
    
    @AuraEnabled
    global static string getTools(string ToolContext, string ActionCode, string IHContext, string ClientComponentId, string Params, boolean SkipGlobals) {
        
        string retVal = '';                                                             // Overall, concatenated object JSON to return
        string localDiags = '';                                                         // Local, intermediate diagnostics in case of error
        string timeStamps;                                                              // Timed diagnostics / always returned via a NVP
        
        try {
            System.debug('ActionCode : ' + ActionCode);
            List<ConfigurationItem__c> LXTs = new List<ConfigurationItem__c> ();            // Collection of the same, ultimately returned via JSON
            ServiceIHLists.ListingItem LI;                                                  // A listing item being returned, ultimately via JSON
            List<ServiceIHLists.ListingItem> LIs = new List<ServiceIHLists.ListingItem> (); // Collection of the same for efficient JSON parsing
            string AuthorCfgParams = '';                                                    // Parameters supplied via author config interactions
            boolean IHCXTSuppliedBlank = false;                                             // Denotes that no context was supplied so was defaulted in this call
            boolean AuthorCfgApplied = false;                                               // Denotes that author config overrides were applied to results returned
            string strTemp;                                                                 // Working string
            NameValuePair NVP;                                                              // For returning certain data not suited to listings
            NameValuePair[] NVPs = new NameValuePair[]{};                                   // Collection of the above for more efficient processing to JSON
            integer userPermLevel = 0;                                                      // Similar filter based on user permissions
            map<string,string> mapDlgLocs;                                                  // For internationalisations
            

            localDiags += 'Basic vars set... ';
            timeStamps = getTimeStamp() + 'getTools - entry with action code: "' + ActionCode + '" for client "' + ClientComponentId + '" with Context "' + IHContext + '", Tool Context "' + ToolContext + '" and Parameters "' + Params + '"... ';

            ControllerIHQAMSettings cIHQ = new ControllerIHQAMSettings(true);
            ControllerHelpContent cH = new ControllerHelpContent(false);       
            string CRoot = ControllerSettings.getCommunityPrefix();        
                    
            localDiags += 'CRoot set to "' + CRoot + '"... ';
            timeStamps += getTimeStamp() + 'getTools - CRoot set to "' + CRoot + '"... ';
            
            
            // Set up a recency limit so recently amended items can be amended below
            string recencyMarker = 'IHCollateralUpdated';
            DateTime dTRecenyLimit = DateTime.now().addHours(Integer.valueOf(ControllerSettings.getSettings().UpdateMarkerHours__c) * -1);

            localDiags += 'Recency calculated... ';


            // If we've been supplied with a specific caller component identifier, check for and store
            // any author+ supplied configuration parameters, as logged via a special interation type
            if (ClientComponentId != '' && ClientComponentId != null && ClientComponentId + '' != 'undefined') {
                AuthorCfgParams = getAuthorConfig(ClientComponentId);
                timeStamps += getTimeStamp() + 'getTools - Author config parameters were: "' + AuthorCfgParams + '"... ';
            } else {
                timeStamps += getTimeStamp() + 'getTools - Author config NOT in use... ';
            }
        
        
            // Set Help context to that requested:
            // If no context supplied, attempt contextualising to default help topic
            if (IHContext == null || IHContext == '') {
                IHContext = ControllerSettings.getSettings().DefaultHelpTopic__c;
                
                // In case default topic has not been set...
                if (IHContext == null) {
                    IHContext = '';
                }
                
                // Note the fact that a blank context was supplied and has been re-set here
                IHCXTSuppliedBlank = true;
            }


            // Produce a listing of topics that feature a particular term as a keyword - to allow
            // users to select (disambiguate) the particular context that interests them            
            if (ActionCode == 'Disambiguation') {
                
                string keyword = IHContext;
                string str = 'select id from iahelp__HelpTopic__c where iahelp__keyword__c = \''+keyword+'\' or (iahelp__keyword__c like \''+keyword+',%\') or (iahelp__keyword__c like \'%,'+keyword+'\') or iahelp__keyword__c like \'%,'+keyword+',%\'';
        
                for(HelpTopic__c HT : database.query(str)){

                    //If current user is help user then bring only active topics, else bring all topics including inactive ones
                    ch.getTopicViaHTID(HT.id,false);
                    
                    LI = new ServiceIHLists.ListingItem();
                    LI.ActionCode = 'DisambiguationItem';
                    LI.Id = ch.hlp.Id;
                    LI.label = ch.hlp.Name;
                    LI.Title = ch.hlp.summary__c;
                    LIs.add(LI);
                }
            }
            
                        
            // If action is "Fixed Help", context will not have come from SF record context but will be an object name 
            // selected by page author - so we need to translate that to something usable: we need to 3 letter code.
            if (ActionCode == 'FixedHelp') {

                // If we were provided with author overrides, check for help topic ID amoung them
                // and use in preference to default tree root (i.e., if we weren't asked for specific topic)
                if (AuthorCfgParams != '' && IHCXTSuppliedBlank == true) {
                    
                    try {
                        string[] cfgPs = AuthorCfgParams.split('\\^');
                        string[] cfgP;
                        
                        for (string P : cfgPs) {
                            cfgP = P.split('\\~');
                            if (cfgP[0] == 'sObjectName') {
                                IHContext = cfgP[1];
                                AuthorCfgApplied = true;
                            }
                        }
                    } catch (exception ex) {}
                    
                }
                
                IHContext = ServiceSchema.getObjectIdByName(IHContext);
            }
            
            
            // If action is "GetForm" (auto-form operations) context passed will be a record ID if viewing or editing
            // but will be (perforce) an object name if adding a new record (as this will not yet have an ID)
            if (ActionCode == 'GetForm') {
                
                // If (and only if) supplied context is an object name, we must translate it to object 3 letter code:
                // We can check by comparing to the parameters passed, the first of which is always object name
                string[] parms = Params.split('\\^');
                if (parms[0] == IHContext) {
                    IHContext = ServiceSchema.getObjectIdByName(IHContext);
                }
            }


            // If action is "All Help", context will be a record ID (allowing contextualisation to that).
            // If what we have does not look like just a record id, take action here...
            if (IHContext.startsWith('http')) {
                ControllerSettings cS = new ControllerSettings();
                IHContext = cS.SFObjId(IHContext);
            }

            
            // If action is "Get Tagged Items", context will be capek delimited tagging info, with first element POSSIBLY being
            // an object API name - if the original context was fixed and it is the fixed context that is being further tag-filtered:         
            if (ActionCode == 'GetTaggedItems') {
                if (IHContext.indexOf('^') != -1) {
                    string[] parms = IHContext.split('\\^'); 
                    IHContext = ServiceSchema.getObjectIdByName(parms[0]);
                }
            }
            
            
            // If we were provided with author overrides, check for reading list ID amoung them
            // and use in preference to default (i.e., if we weren't asked for specific reading list)                
            if (ActionCode == 'ReadingListEntries') {
                if (AuthorCfgParams != '' && (IHCXTSuppliedBlank == true || IHContext == '[None]')) {
                
                    try {
                        string[] cfgPs = AuthorCfgParams.split('\\^');
                        string[] cfgP;
                                    
                        for (string P : cfgPs) {
                            cfgP = P.split('\\~');
                            if (cfgP[0] == 'HelpRecordId') {
                                IHContext = cfgP[1];
                                AuthorCfgApplied = true;
                            }
                        }
                    } catch (exception ex) {}   
                }                
            }            
            
            localDiags += 'IHContext set to "' + IHContext + '"... ';            
            timeStamps += getTimeStamp() + 'getTools - IHContext set to "' + IHContext + '"... ';

            // v1.37: need to take community root into consideration here...                        
            if (CRoot != '') {
                cIHQ.LUXParams = CRoot + '/' + IHContext;
            } else {
                cIHQ.LUXParams = IHContext;
            }

            if (ActionCode == 'ShowReadingLists') {
                localDiags += 'Processing All Reading Lists... ';
                
                // Check user permission - Authors only (level 4+)
                ServiceSecurity Security = new ServiceSecurity();
                Boolean[] Perms = Security.UserPermissions();
                
                if (!Perms[3]) {
                    // User is not Author - return empty
                    localDiags += 'User not Author - no access. ';
                } else {
                    // Query ALL reading lists
                    List<iahelp__HelpReadingList__c> allRLs = [
                        SELECT Id, Name
                        FROM iahelp__HelpReadingList__c
                        ORDER BY LastModifiedDate DESC
                        LIMIT 500
                    ];
                    
                    localDiags += 'Found ' + allRLs.size() + ' reading lists. ';
                    
                    // Format each reading list as a ListingItem
                    for (iahelp__HelpReadingList__c rl : allRLs) {
                        LI = new ServiceIHLists.ListingItem();
                        LI.Id = rl.Id;
                        LI.Label = rl.Name;
                        //LI.Title = (rl.iahelp__Summary__c != null) ? rl.iahelp__Summary__c : '';
                        LI.Icon = 'fa-list-ol';
                        LI.IconTitle = '';
                        LI.StyleClass = '';
                        LI.IconLabel = '';
                        LI.ActionCode = 'RL_SELECT_FOR_VIEW';
                        LI.Parameters = rl.Name.escapeHtml4();
                        LI.RowState = '';
                        
                        LIs.add(LI);
                    }
                    
                    localDiags += 'Added ' + LIs.size() + ' items to list. ';
                }
            }

            // v1.41+ : performance enhancements - don't initialie QAM settings unless necessary
            if (ActionCode == 'HelpTopic') {
                ServiceSecurity sS = new ServiceSecurity();
                boolean[] UPs = sS.UserPermissions();
            
                if (UPs[0]) userPermLevel += 1; // User
                if (UPs[3]) userPermLevel += 2; // Analyst
                if (UPs[1]) userPermLevel += 4; // Author
                if (UPs[2]) userPermLevel += 8; // Admin
                
                cIHQ.isUser = UPs[0];
                cIHQ.isAnalyst = UPs[3];
                cIHQ.isAuthor = UPs[1];
                cIHQ.isAdministrator = UPs[2];
                
                timeStamps += getTimeStamp() + 'getTools - permissions set via Security... ';   
                
            } else {
                cIHQ.initializeIH1QAM();
                                        
                localDiags += 'cIHQ initialised... ';            
                localDiags += 'cIHQ Diags: ' + cIHQ.Diags + '... ';
                timeStamps += getTimeStamp() + 'getTools - IHQS initialised... ';
                if (cIHQ.HelpedElements != null) {
                    timeStamps += getTimeStamp() + 'getTools - IHQS Helped Elements size: ' + cIHQ.HelpedElements.size() + '... ';
                } else {
                    timeStamps += getTimeStamp() + 'getTools - IHQS Helped Elements was NULL... ';
                }
                timeStamps += getTimeStamp() + 'getTools - IHQS Diagnostics: ' + cIHQ.Diags + '... ';

            
                // Translate help permissions into an integer we can use to filter tools
                if (cIHQ.isUser) userPermLevel += 1;
                if (cIHQ.isAnalyst) userPermLevel += 2;
                if (cIHQ.isAuthor) userPermLevel += 4;
                if (cIHQ.isAdministrator) userPermLevel += 8;
            }

            localDiags += 'Permission levels checked... ';
            
            
            // Get the clickables / tools applicable to the current context / user
            LXTs = getClickables(ToolContext, ActionCode, IHContext, userPermLevel);                        
            localDiags += 'LXTs filtered - serializing... ';                                
            retVal = JSON.serialize(LXTs);
            localDiags += 'LXTs serialized - continuing to process Action Code... ';
            timeStamps += getTimeStamp() + 'getTools - LXTs bit-filtered to ' + LXTs.size() + ' items and serialized - continuing to action code "' + ActionCode + '"... ';


            if (ActionCode == 'AppListing') {
                
                string Apps = ControllerSettings.getStoredMetadata('GetAppListing');
                JSONParser parser = JSON.createParser(Apps);
                
                // Loop through the JSON
                while (parser.nextToken() != null) {
                            
                            
                    // Examine any field name we come across in the JSON
                    if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
                                
                        if (parser.getText() == 'Id') {
                            
                            // Add previous listing, if present:
                            // NB: for this release, return LUX type apps only (based on listing item code setting icon)
                            if (LI != null && LI.Icon == 'fa-bolt') {                   
                                LIs.add(LI);
                            }
                            
                            LI = new ServiceIHLists.ListingItem();
                            LI.ActionCode = 'HelpCallout';
                            
                            parser.nextValue();
                            LI.Id = parser.getText();
                        }
                                                    
                        if (parser.getText() == 'Label') {
                            parser.nextValue();
                            LI.Label = parser.getText();
                        }
            
                        if (parser.getText() == 'Description') {
                            parser.nextValue();
                            LI.Title = parser.getText();
                            if (LI.Title + '' == 'null') {LI.Title = '-';}
                        }
            
                        if (parser.getText() == 'UiType') {
                            parser.nextValue();
                            if (parser.getText() == 'Lightning') {
                                LI.Icon = 'fa-bolt';
                            } else {
                                LI.Icon = 'fa-cog';                 
                            }
                        }
                                                    
                    }
            
                }
            
                // Add the final listing, if present:
                // NB: for this release, return LUX type apps only (based on listing item code setting icon)
                if (LI != null) {  
                    if (LI.Icon == 'fa-bolt') {
                        LIs.add(LI);
                    }               
                }
                
            }
            
            
            if (ActionCode == 'TabListing') {
                
                // Get simple info about tabs in the requested app
                string AppTabs = ControllerSettings.getStoredMetadata('GetTabListing_' + IHContext);    
                
                // Get detailed info about all tabs
                string AllTabs = ControllerSettings.getStoredMetadata('GetTabListing'); 
                
                // As it's easier to manipulate these in JS, just return these items via name value pairs
                NVP = new NameValuePair('TabsJSON', 'SelectedApp', AppTabs);
                NVPs.add(NVP);
                
                NVP = new NameValuePair('TabsJSON', 'AllTabs', AllTabs);
                NVPs.add(NVP);
                    
            }



            // IN MOST CASES - Tack listing records JSON on to tools JSON:
            // However, see also below...

            if (ActionCode == 'GetWizard') {
                // Tools are all we need - there are no data rows 
                // (aside from those fetched by featured components - fetched by them as required in their own calls)
            }


            // Get the fields associated with a specified object layout from SF metadata
            if (ActionCode == 'GetForm') {

                timeStamps += getTimeStamp() + 'getTools - GetForm action... ';
            
                Schema.DescribeSObjectResult sObj;          // Object for which we want a data form
                Map<String, Schema.SObjectField> FMap;      // Map of its fields
                Schema.SObjectField FObj;                   // A field object from the map
                Schema.DescribeFieldResult Fld;             // The describe object for this field
                string OCode;                               // 3-letter code for desired object
                string OName;                               // It's API name
                string OLabel;                              // It's label
                string LayoutName = '';                     // (Derived) metadata API name of desired layout (of the 1+ that may exist for object)
                ServiceSchema svsS = new ServiceSchema();   // Schema class to obtain many of the above

                // Markers controlling whether or not to add items to layout data returned
                boolean isField;                            // True if the current item is a field (not a blank or custom section etc)
                boolean isAccessible;                       // True if CRUD rights allow access to the current field item
                boolean rowHasRealItems;                    // True if current layout row contains at least 1 accessible, real item
                                
                IALayout IAL = new IALayout();              // SF layout data transformed into a utility class to return
                IALayoutSection[] Sects = new IALayoutSection[]{};  // Sections within this
                IALayoutSection Sect;                       // A section in the layout
                IALayoutRow[] IARs;                         // Rows within sections
                IALayoutRow IAR;                            // A row
                IALayoutItem IALI;                          // Layhout items within rows
                integer r;                                  // For iterating rows
                integer c;                                  // For iterating columns
                integer bump;                               // For use in processing blank fields / spaces in columns
                Metadata.LayoutColumn Col;                  // A column in the SF layout (we re-structure our return to rows)
                integer maxItemCount;                       // Tracker value: number  of items in the "longest" column in a layout section
                string formMode;                            // For use in controlling returned form elements
                
                
                // Get the applicable object code & list of selected fields:
                // Parameters supplied for this action code should be:
                // Object Name [Delimiter] Layout API Name [Delimiter] Data mode
            
                localDiags += 'GetForm action - Parameters supplied: ' + Params + '... ';
                
                string[] Parms = Params.split('\\^');       
                localDiags += 'GetForm action - first param is ' + Parms[0] + '... ';
                OCode = ServiceSchema.getObjectIdByName(Parms[0]); 
                formMode = Parms[2];
            
                    
                // Get object info based on its prefix
                sObj = svsS.getObjectDetails(OCode);    
                OName = sObj.getName();
                OLabel = sObj.getLabel();
                FMap = sObj.Fields.getMap();
            
                localDiags += 'GetForm action - object is ' + OName + '... ';


                // Use layout name, if given, or derive a default
                if (Parms.size() > 1) {
                    if (Parms[1] != '' && Parms[1] != null) {
                        LayoutName = Parms[1];
                    }
                }


                // Otherwise, revert to using an assumed default layout name                
                if (LayoutName == '') {
                    LayoutName = OName + '-' + OName + ' Layout';
                }
                            
                localDiags += 'GetForm action - layout is ' + LayoutName + '... ';

            
                // GET LAYOUT NAME FROM WSDL - OR PROJECT .LAYOUT XML FILES
                // LAYOUT NAMES ARE WEB ESCAPED - EG Opportunity-Opportunity-Opportunity %28Support%29 Layout
                // NB: Any failure here appears to cause an untrappable error!!               
                List<Metadata.Metadata> layouts;
                
                layouts = Metadata.Operations.retrieve(Metadata.MetadataType.Layout, new List<String> {LayoutName});
                localDiags += 'Layouts retrieved: ' + layouts.size() + '... ';


                // If this doesn't return any data we need to attempt action:
                // If object has a namespace, tack this in front of layout if required
                
                if (layouts.size() == 0) {
                    
                    string NS = '';
                    string strippedOName = OName;
                    string[] LNParts;
                    
                    // Namespace can be derived from object API name
                    if (strippedOName.endsWith('__c')) {strippedOName = strippedOName.substring(0, strippedOName.length() - 3);}
                    if (strippedOName.indexOf('__') != -1) {
                        NS = strippedOName.substring(0, strippedOName.indexOf('__'));
                    }
                    
                    // Object names never contain hyphens, so we can use this to split and re-create name
                    LNParts = LayoutName.split('-');
                    LayoutName = LNParts[0] + '-' + NS + '__' + LNParts[1];
                    
                    layouts = Metadata.Operations.retrieve(Metadata.MetadataType.Layout, new List<String> {LayoutName});
                    localDiags += 'GetForm action - 2nd attempt ' + LayoutName + '... ';
                    localDiags += 'Layouts retrieved: ' + layouts.size() + '... ';
                }
                

                // Special handling for Person Accounts:
                // If we have no layout and object supplied is Account, this may be a person account.
                // Whilst these are standard objects and have no apparent namespace (so above will have had no impact)
                // there actually is one in play (c2g) which we need to apply to obtain layout content...
                if (layouts.size() == 0 && OName == 'Account') {
                    
                    string NS = 'c2g';                          // This appears to be the real person account namespace, though SF do not show this in setup
                    LayoutName = Parms[1];                      // Amend the supplied layout name
                    string[] LNParts = LayoutName.split('-');
                    LayoutName = LNParts[0] + '-' + NS + '__' + LNParts[1]; 
                    
                    layouts = Metadata.Operations.retrieve(Metadata.MetadataType.Layout, new List<String> {LayoutName});
                    localDiags += 'GetForm action - 3rd attempt ' + LayoutName + '... ';
                    localDiags += 'Layouts retrieved: ' + layouts.size() + '... ';  
                    
                    if (layouts.size() == 0) {
                        LayoutName = 'PersonAccount-' + NS + '__' + LNParts[1]; 
                        layouts = Metadata.Operations.retrieve(Metadata.MetadataType.Layout, new List<String> {LayoutName});
                        localDiags += 'GetForm action - 4th attempt ' + LayoutName + '... ';
                        localDiags += 'Layouts retrieved: ' + layouts.size() + '... ';          
                    }
                }                


                // Set layout name (to return, below) to that actually discovered
                Metadata.Layout layoutMd = (Metadata.Layout)layouts.get(0);
                LayoutName = layoutMd.fullName;
            
                // Translate the layout info into a format that is based on ROWS so we can layout forms correctly
                localDiags += 'About to process layout metadata... ';
                
                // Get any record of user's choice of form section toggling
                HelpInteraction__c FSS = getFormSectionStatus(OCode);
                string[] SectionToggles = null;
                string[] SectionToggle;
                if (FSS != null) {
                    if (FSS.Description__c != null) {
                        SectionToggles = FSS.Description__c.split(ControllerSettings.D1);
                    }
                }

                
                for (Metadata.LayoutSection LS : layoutMd.layoutSections) {
                    Sect = new IALayoutSection();
                    
                    // Initialise section to a state that assumes it contains only system / special read only fields:
                    // As "ordinary" fields are discovered in the section, below, this will be re-set if required
                    Sect.SROOnly = true;

                    // Set section to collapsed unless there is a user interaction to say otherwise
                    try {
                        if (SectionToggles != null) {
                            for (string ST : SectionToggles) {
                                SectionToggle = ST.split(ControllerSettings.D2);
                                
                                if (SectionToggle[0] == LS.label) {
                                    if (SectionToggle[1] == 'true') {
                                        Sect.Expanded = true;
                                    } else {
                                        Sect.Expanded = false;
                                    }
                                    break;
                                }
                            }
                            
                        } else {
                            // If there's no toggle data from the user, set all sections to 
                            // the setting requested by the autoform component as a default
                            string[] Ps = Params.split('\\^');
                            string SectionState = Ps[4];
                            
                            if (SectionState == 'Collapsed') {
                                Sect.Expanded = false;
                            } else {
                                Sect.Expanded = true;
                            }   
                    
                        }
                        
                    } catch (exception exc) {
                        Sect.Expanded = false;
                    }
                        
                    IARs = new IALayoutRow[]{};
                    
                    
                    // Take note, for rendering convenience, of the number of columns in the section
                    localDiags += 'Section ' + LS.label + ' has ' + LS.layoutColumns.size() + ' columns... ';
                    Sect.ColumnCount = LS.layoutColumns.size();
                    
                    
                    // We need to iterate around the column that has most items:
                    // Note that blanks / spaces WILL appear (field=null, emptySpace=true) BUT only if added / up
                    // to the last item in the column
                    maxItemCount = 0;
                    Col = null;
                    for (Metadata.LayoutColumn LC : LS.layoutColumns) {
                        if (LC.layoutItems != null) {
                            if (LC.layoutItems.size() > maxItemCount) {
                                maxItemCount = LC.layoutItems.size();
                                Col = LC;
                            }
                        }
                        
                        localDiags += 'Column items: ' + LC.layoutItems + '------------------------------------------';
                    }
                    
                    
                    if (Col != null) {
                        for (r=0; r<Col.layoutItems.size(); r++) {
                            
                            // Add a row for each item in the "longest" column (as all cols have same # of rows)
                            IAR = new IALayoutRow();
                            
                            // Row identifier based on its section title plus index number
                            if (LS.label + '' != 'null') {
                                IAR.Id = LS.label.replace(' ', '') + '_Row' + r;
                            } else {
                                IAR.Id = 'null_Row' + r;
                            }                    


                            // Initialise row to containing no renderable items until we discover otherwise
                            rowHasRealItems = false;                                            

                            for (c=0; c<LS.layoutColumns.size(); c++) {
                                if (LS.layoutColumns[c].layoutItems != null) {
                                    if (LS.layoutColumns[c].layoutItems.size() > r) {
            
                                        /*
                                        In the row, add an item for each column
                                        NOTE: "read only" for item behviour means read only as specifically set by layout owner: NOT
                                        necessarily the same as read only in effect on arrival at the page (e.g., record owner is always read only
                                        even when editing a record). R/O fields as set by layout owner do NOT feature on edit views, so
                                        if such fields are encountered, do NOT add them if we're editing...
                                        */                                      
                                        if (LS.layoutColumns[c].layoutItems[r].behavior != Metadata.UiBehavior.Readonly || formMode.toUpperCase() == 'VIEW') {
            
                                            IALI = new IALayoutItem();
                                            IALI.Item = LS.layoutColumns[c].layoutItems[r];
                                            IALI.HelpAvailable = false;


                                            // Initialise current item markers to being an un-accessible, non-field until we know otherwise
                                            isField = false;  
                                            isAccessible = false;                                          


                                            if (LS.layoutColumns[c].layoutItems[r].field != null) {
            
                                                // Attempt to get the layout-referenced field by the name in row metadata:
                                                // NB: also record field label info in case we need "identifier" as well as API name client-side

                                                // Note the fact that this item is a field
                                                isField = true;

                                                Fld = null;                                                
                                                FObj = FMap.get(LS.layoutColumns[c].layoutItems[r].field);
                                                
                                                // NB: if field is not accessible (e.g., visible = false in field setup)
                                                // FObj WILL be null at this stage - we are not given a field object (sObjectField)...

                                                if (FObj != null) {
                                                    Fld = FObj.getDescribe();
                                                    if (Fld != null) {
                                                        IALI.Item.field = Fld.getName();    
                                                        IALI.FieldLabel = Fld.getLabel();

                                                        // Note whether CRUD makes this field accessible to the user                                                        
                                                        isAccessible = Fld.isAccessible();       
                                                    }
                                                    
                                                } else {
                                                    // If we can't find the field mentioned in the layout by name, this
                                                    // may be because layout metadata does not seem to have namespaces in
                                                    // front of field names: therefore, attempt here to find such fields
                                                    for (Schema.SObjectField F : FMap.values()) {
                                                        Fld = F.getDescribe();
                                                        if (Fld.getLocalName() == LS.layoutColumns[c].layoutItems[r].field) {
                                                            IALI.Item.field = Fld.getName();
                                                            IALI.FieldLabel = Fld.getLabel();   

                                                            // Note whether CRUD makes this field accessible to the user                                                        
                                                            isAccessible = Fld.isAccessible();       
                                                            
                                                            break;                              
                                                        }
                                                    }
                                                }        
                                                
                                                                                
                                                // Having obtained the field - including namespace where relevant - check whether 
                                                // it features in the list of known helped elements for the current context
                                                // (i.e., whether help is available) 
                                                if (cIHQ.HelpedElements != null) {
                                                    for (ControllerIHQAMSettings.SearchResultQAM SR : cIHQ.HelpedElements) {
                                                        
                                                        if (Fld != null) {
                                                            if (SR.Element.Identifier__c == IALI.FieldLabel) {
                                                                
                                                                // If help is available, note some additional details - e.g., custom style
                                                                IALI.HelpAvailable = true;
                                                                IALI.Element = SR.Element;

                                                                // Need to add any error styling here
                                                                if (SR.Element.HelpTopic__c == null) {
                                                                    // If topic is null, we have a configuration issue - so mark this in the
                                                                    // same way we would in "classic" pages
                                                                    IALI.StyleClass = 'IHHelpedSFElementError';
                
                                                                } else {
                                                                    IALI.StyleClass = SR.Element.HelpTopic__r.CustomStyle__c;
                                                                    IALI.Topic = SR.Element.HelpTopic__r;
                                                                }                                                       
                                                                break;
                                                            }
                                                        }
                                                    }
                                                }
                                                
                                                // Deal with DDF fails: only mark these for Authors+
                                                if (cIHQ.failedHEs != null && (cIHQ.isAuthor || cIHQ.isAdministrator)) {
                                                    for (HelpedElement__c HE : cIHQ.failedHEs) {
                                                        if (HE.Identifier__c == IALI.FieldLabel) {
                                                            
                                                            // We only want to mark DDF fail if NO element matched:
                                                            // (The fails are ALL non-matches, even if another element for the same helpable met DDF)
                                                            // ControllerSettings' helped elements collection will only contain DDF passes - and will have marked the
                                                            // relevsnt form element as having help available (above). So: if help is available for the
                                                            // current form element, ignore any DDF fail elements, as we already have help... 
                                                            if (IALI.HelpAvailable == false) {
                                                                IALI.HelpAvailable = true;
                                                                IALI.StyleClass = 'IHDDFFailElement';
                                                            }   
                                                        }
                                                    }
                                                }                                                
                                                
                                            }   // End if section / column / item's field != null

                                            
                                            // Certain special fields must be marked as read only
                                            if (IALI.Item.field == 'RecordTypeId' 
                                                    || IALI.Item.field == 'LastModifiedById' || IALI.Item.field == 'CreatedById'
                                                    || IALI.Item.field == 'LastModifiedDate' || IALI.Item.field == 'CreatedDate'
                                                    || IALI.Item.customLink != null) {
                                                IALI.SpecialReadOnly = true;
                                            } else {
                                                IALI.SpecialReadOnly = false;
                                                
                                                // Note the fact that a given section contains anything other than special R/O fields
                                                Sect.SROOnly = false;
                                            }


                                            // Note whether this field is updatable at the SCHEMA - as opposed to the LAYOUT level
                                            if (Fld != null) {
                                                
                                                // Start by obtaining schema updatability info for the current field
                                                IALI.SchemaUpdateable = Fld.isUpdateable(); 
                                            
                                                // However, special handling is required for composite fields: for example,
                                                // 'Mailing Address' itself is never updatable - only its component parts. 
                                                // So: If we encounter (potential) composite fields, investigate further...
                                                    
                                                if (Fld.getType().name().toUpperCase() == 'ADDRESS') {
                                            
                                                    // For addresses, obtain field representing the "street" line and use this 
                                                    // as an analogue for the whole
                                                    
                                                    try {
                                                        string FName = LS.layoutColumns[c].layoutItems[r].field;
                                                        FName = FName.replace('Address', 'Street');
                                                        FObj = FMap.get(FName);
                                                        Fld = FObj.getDescribe();
                                                        IALI.SchemaUpdateable = Fld.isUpdateable(); 
                                                        
                                                    } catch (exception ex) {
                                                        // Leave editability as per the already-obtained general setting
                                                    }
                                                }
                                                
                                                
                                                // For composite name fields, all we can do is respond to a field called 'Name'
                                                try {
                                                    if (LS.layoutColumns[c].layoutItems[r].field.toUpperCase() == 'NAME') {
                                                    
                                                        // In these cases, is there a field on the object called 'LastName'?    
                                                        // If so, we will assume this is a composite name and respond to editability of surname
                                                
                                                        FObj = FMap.get('LastName');
                                                        Fld = FObj.getDescribe();
                                                        IALI.SchemaUpdateable = Fld.isUpdateable(); 
                                                    }
                                                
                                                } catch (exception ex) {
                                                    // Leave editability as per the already-obtained general setting
                                                }
                                                
                                            
                                            } else {
                                                // 'Safe' default: this attribute largely is used for the availability of editing pencil, so
                                                // a false positive here will not make illegal edits possible
                                                IALI.SchemaUpdateable = true;   
                                            }
                                            
                                            
                                            // Do not add items representing fields which are not accessible: otherwise, a
                                            // section may look like it should be shown (becuase it has items) when in fact
                                            // it is empty from the user's point of view (as even if the item is added here,
                                            // SFDC will correctly render it as a blank)...    
                                                        
                                            if ((isField == true && isAccessible == true) || isField == false) {
                                                
                                                // If adding the item, set composite editability values for convenience / LWC necessity
                                                try {
                                                    IALI.IsEditable = IALI.Item.behavior != Metadata.UiBehavior.Readonly && IALI.SchemaUpdateable == true && IALI.SpecialReadOnly == false && IALI.Item.field != null;
                                                    IALI.IsEditableLocally = IALI.IsEditable;
                                                } catch (exception eIALI) {
                                                    IALI.IsEditable = false;
                                                    IALI.IsEditableLocally = false;
                                                }
                                                
                                                IAR.Items.add(IALI);
                                                rowHasRealItems = true;
                                            } else {
                                                IAR.Items.add(null);
                                            }    
                                                                
                                                                        
                                        } else {
                                            // Form mode is edit and item is read only
                                            IAR.Items.add(null);
                                        }
                                    } else {
                                        // Currrent columns items have been iterated (has fewer items than Col)
                                        IAR.Items.add(null);
                                    }
                                } else {
                                    // Current columns items is null
                                    IAR.Items.add(null);                    
                                }
                                
                            }   // End loop around columns in each row


                            // Only add rows that contain some non-null (real) items                            
                            if (rowHasRealItems == true) {
                                IARs.add(IAR);
                            }

                        }   // Loop around rows

                        localDiags += 'Section data processed - about to adjust item positioning...';
                        
                        // Need to loop through again here to bump the positions of fields - moving  them "up" a row
                        // in cases where a read only item was encountered...
                        for (c=0; c<LS.layoutColumns.size(); c++) {
                            for (r=0; r < IARs.size() - 1; r++) {
                                
                                if (IARs[r].Items[c] == null) {
                                    // Bump all items up
                                    for (bump = r; bump < IARs.size() - 1; bump++) {
                                        IARs[bump].Items[c] = IARs[bump+1].Items[c];
                                    }
                                    IARs[IARs.size()-1].Items[c] = null;
                                }
                            }
                        }
                        
                    }
                    
                    Sect.Section = LS;
                    Sect.Rows = IARs; 
                    
                    // Take note, for rendering convenience, of whether the section has any rows
                    Sect.HasRows = IARs.size() > 0;                    
                        
                    Sects.add(Sect);
                }   // End loop around Layout Sections
                
                
                // Return our layout definition object
                IAL.Sections = Sects;
                retVal = concatenateJSON(retVal, JSON.serialize(IAL));
            
            
                // Also, add details of "my form" / user's preferred / selected fields  
                HelpInteraction__c HI = getPersonalForm(OCode);
                if (HI != null) {
                    NVP = new NameValuePair('MyForm', 'Fields', HI.Description__c);
                    retVal = concatenateJSON(retVal, JSON.serialize(NVP));              
                }
                
                    
                // Add a SINGLE listing item, too, to hold details of the object to which the form applies ...
                LI = ServiceIHLists.getMetadataListingItem();        
                LI.Id = OCode;        
                LI.RowState = OName;
                LI.Label = OLabel;
                LI.Title = LayoutName; // OLabel + ' (' + OName + ')';
                
                // ... including CRUD info
                LI.Parameters = '' + sObj.isUpdateable();
                LIs.add(LI);       
                
                timeStamps += getTimeStamp() + 'getTools - GetForm action processed... ';
            }
            
            
            if (ActionCode == 'AllHelp' || ActionCode == 'FixedHelp' || ActionCode == 'PopularHelp') {
                
                Boolean doAdd;

                try {
                    if (cIHQ.HelpedElements != null) {
                        
                        // For keeping the full data of 'qualifying' helped elements for some ops
                        HelpedElement__c[] HEsOut = new HelpedElement__c[]{};
                        
                        // For popular help, get a list of the most popular topics (most interactions)
                        AggregateResult[] popularTopics;
                        if (ActionCode == 'PopularHelp') {
                                            
                            try {
                                popularTopics = [SELECT HelpTopic__c Topic, COUNT(HelpTopicId__c) CT
                                    FROM HelpInteraction__c
                                    WHERE HelpInteractionType__c = 'Callout'
                                    AND HelpedPageLayout__c = :cIHQ.HelpedElements[0].Element.HelpedPageLayout__c
                                    GROUP BY HelpTopic__c
                                    ORDER BY COUNT(HelpTopicId__c) DESC
                                    LIMIT 10];
                            } catch (exception ex) {}
                        }
                        
                        
                        // We need to get existing help bookmarks here - as we need to mark elements
                        // with whether or not user has bookmaked them                      
                        Boolean bmkInfoOK = cIHQ.cH.initialiseBookmarks(false, false);
                        localDiags += 'cIHQ Bookmarks initialised... ';   
                                                    
                                                    
                        for (ControllerIHQAMSettings.SearchResultQAM SR : cIHQ.HelpedElements) {
                                                    
                            // 1.31.3: if a Help Topic is referenced by multiple Helped Elements,
                            // we only want the Topic listed ONCE: so check ID here
                            // against those already in our listing items...                            
                            
                            doAdd = true;
                            for (ServiceIHLists.ListingItem L : LIs) {
                                if (SR.Result.Id == L.Id) {
                                    doAdd = false;
                                    break;
                                }
                            }
                            

                            // If we're after the most popular topics, filter to this here
                            if (ActionCode == 'PopularHelp') {
                                if (popularTopics != null) {
                                    doAdd = false;
                                    for (AggregateResult AR : popularTopics) {
                                        if (SR.Element.HelpTopic__r.Id == AR.get('Topic')) {
                                            doAdd = true;
                                            break;
                                        }
                                    }
                                }
                            }
                            

                            
                            if (doAdd == true) {

            // Avoid JSON parser null issues
            try{
                if (SR.Element.HelpTopic__r.Keyword__c == null) {SR.Element.HelpTopic__r.Keyword__c = '';}
            } catch (exception exc) {
                
        }   

                                
                                // Add a listing item plus keep the full helped element
                                HEsOut.add(SR.Element);                             
                                LI = new ServiceIHLists.ListingItem();
                                
                                LI.Id = SR.Result.Id;
                                
                                // In these cases, use icon label to hold Element Type -> class on listings controls
                                LI.Icon = 'fa-question';
                                LI.IconLabel = SR.Element.ElementType__c.replaceAll(' ', '');

                                LI.IconTitle = '';
                                LI.RowState = '';
                                
                                if (SR.Element.HelpTopic__c == null) {
                                    // If topic is null, we have a configuration issue - so mark this in the
                                    // same way we would in "classic" pages
                                    
                                    LI.Label = SR.Element.Name + ' - Configuration Issues';
                                    LI.Title = 'There are issues with the configuration of this Helped Element. Click for details';                                     
                                    LI.ActionCode = 'ConfigurationIssue';
                                    LI.Parameters = SR.Element.Identifier__c + '^' + SR.Element.HelpedPageLayout__r.PageLayoutIdentifier__c;                    
                                    
                                    LI.StyleClass = 'IHHelpedSFElementError';

                                } else {
                                    // Otherwise, retrieve details of listing from Topic
                                    // Listing row labelling details vary according to component parameters
                                    if (params == 'Element Name - Topic Name') {
                                        LI.Label = SR.Element.Name + ' - ' + SR.Result.Name;
                                    } else if (params == 'Topic Name (Element Type)') {
                                        LI.Label = SR.Result.Name + ' (' + SR.Element.ElementType__c + ')';
                                    } else {
                                        // Default to topic name only
                                        LI.Label = SR.Result.Name;
                                    }


                                    LI.Title = SR.Result.Summary;                               
                                    LI.ActionCode = 'HelpCallout';
                                    LI.Parameters = SR.Element.HelpTopic__r.CalloutHeight__c + '^' + SR.Element.HelpTopic__r.CalloutTemplate__r.PageURL__c + '^' 
                                                +  SR.Element.Identifier__c + '^' + SR.Element.HelpedPageLayout__r.PageLayoutIdentifier__c + '^' 
                                                + SR.Element.Id;                    

                                    // Add any custom style, plus recency marker where relevant
                                    LI.StyleClass = SR.Element.HelpTopic__r.CustomStyle__c;
                                    if (SR.Element.HelpTopic__r.LastModifiedDate > dTRecenyLimit) {LI.StyleClass += ' ' + recencyMarker;}
                                    
                                    
                                    // Add an indication of whether or not the topic underlying this element is bookmarked or not
                                    if (bmkInfoOK) {
                                        for (ServiceIHLists.BookmarkListItem Bmk : cIHQ.cH.Bookmarks) {
                                            LI.RowState = 'NotBookmarked';
                                            if (Bmk.HTID == SR.Result.Id) {
                                                LI.RowState = 'Bookmarked';
                                                break;
                                            }
                                        }
                                    }
                                    
                                }
                                
                                LIs.add(LI);
                                
                            }   // End if we should add / not a duplicate
                        }   // End loop around Controller Settings Helped Elements
                        localDiags += 'cIHQ Helped Elements loop complete... ';                                                    
                        
                        
                        // We also need to add any DDF fails, as this mode is the equivalent of showing all help for a page
                        // i.e., the hooked elements on a page in toto...
                        // Only do this if user has the rights to see such elements
                        
                        if (cIHQ.isAuthor || cIHQ.isAdministrator){

                            if (cIHQ.failedHEs != null) {
                                
                                for (HelpedElement__c HE : cIHQ.failedHEs) {
                                    
                                    // In any DDF situation, there may always be 1x successful HE and Nx unsuccessful ones for the same element.
                                    // failedHEs contains ALL failing HE records, but we only want to return those where NO HE record for the same
                                    // element was a pass...            
                                    
                                    doAdd = true;
                                    for (ControllerIHQAMSettings.SearchResultQAM SR : cIHQ.HelpedElements) {
                                        if (HE.Identifier__c == SR.Element.Identifier__c) {
                                            doAdd = false;
                                            break;
                                        }
                                    }
                                    
                                    if (doAdd) {
                                        
                                        // Add a listing item plus keep the full helped element
                                        HEsOut.add(HE);                                     
                                        LI = new ServiceIHLists.ListingItem();
        
                                        LI.Id = HE.HelpTopic__r.Id;
                                    
                                        // In these cases, use icon label to hold Element Type -> class on listings controls
                                        LI.Icon = 'fa-question';
                                        LI.IconLabel = HE.ElementType__c.replaceAll(' ', '');

                                        LI.IconTitle = '';
                                        LI.Label = HE.HelpTopic__r.Name;
                                        LI.Title = 'This element is helped but data driven filters do not match the current record. Click for details';                                     
                                        LI.ActionCode = 'ConfigurationIssue';
                                        LI.Parameters = HE.Identifier__c + '^' + HE.HelpedPageLayout__r.PageLayoutIdentifier__c;                    
                                        LI.StyleClass = 'IHDDFFailElement';
                                        LI.RowState = '';
                                        
                                        LIs.add(LI);
                                    }
                                }
                            }
                        }

                        // Add a name value pair holding HE JSON: this can be used as a source of cached
                        // full help topic data to improve performance when navigating lists etc.
                        NVP = new NameValuePair('HelpedElements', 'HelpedElements', '' + JSON.serialize(HEsOut));
                        NVPs.add(NVP);    
                        

                    } else {
                        retVal = 'No Helped Elements. Additional diagnostics: ' + cIHQ.Diags;
                    }
                    
                } catch (exception ex) {
                    retVal = 'Error processing All/Fixed/Popular Help: ' + ex.getMessage() + ': Additional diagnostics: ' + cIHQ.Diags;
                }

            }


            if (ActionCode == 'GetTags' || ActionCode == 'GetTagsForNudge') {

                // If we were provided with author overrides, check for help topic ID amoung them
                // and use in preference page author specified parameters (i.e., if we weren't asked for specific topic)
                if (AuthorCfgParams != '' && Params == '') {
                    
                    try {
                        string[] cfgPs = AuthorCfgParams.split('\\^');
                        string[] cfgP;
                        
                        for (string P : cfgPs) {
                            cfgP = P.split('\\~');
                            if (cfgP[0] == 'HelpRecordId') {
                                Params = cfgP[1];
                                AuthorCfgApplied = true;
                            }
                        }
                    } catch (exception ex) {}
                    
                }    
                
                
                // Don't look for pool topics (i.e., the 'tags') if nudge is a fixed message
                if (Params != '[None]') {
                    retVal = concatenateJSON(retVal, getTags(IHContext, Params));   
                }                           
                
                
                // If returning a pool of tags for use in a nudge, also return info
                // about the number of times the component has displayed an item to them
                if (ActionCode == 'GetTagsForNudge') {
                    integer timesNudged;
                    
                    try { 
                        // 'Tool context' supplied in the action should be the period in hours over which
                        // to look for nudge interactions that may have been logged 
                        integer numHours = integer.valueOf(ToolContext);
                        
                        Datetime dT = Datetime.now();
                        dT = dT.addHours(numHours * -1);

        // v1.54.10+ : Nudge component ID is now stored in Component ID field - not context!
                                        
                        HelpInteraction__c[] Nudges = [SELECT Id
                            FROM HelpInteraction__c
                            WHERE HelpInteractionType__c = 'Nudge Displayed'
        //AND Context__c = :ClientComponentId
        AND ComponentId__c = :ClientComponentId
                            AND OwnerId = :UserInfo.getUserId()
                            AND CreatedDate > :dT
                            LIMIT 500
                            ];
                            
                        timesNudged = Nudges.size();

        timeStamps += getTimeStamp() + 'getTools - GetTagsForNudge (' + ClientComponentId + ') nudged ' + timesNudged + ' times in the past ' + numHours + ' hours... ';

                            
                    } catch (exception ex) {                        
                        timesNudged = 0;

        timeStamps += getTimeStamp() + 'getTools - GetTagsForNudge (' + ClientComponentId + ') error: ' + ex.getMessage() + '... ';
                        
                    }
                    
                    NVP = new NameValuePair('TimesNudged', 'TimesNudged', timesNudged + '');
                    NVPs.add(NVP);                  
                }                
            }
            
            
            if (ActionCode == 'GetTaggedItems') {
                
                // If we were provided with author overrides, check for help topic ID amoung them
                // and use in preference page author specified parameters (i.e., if we weren't asked for specific topic)
                if (AuthorCfgParams != '' && Params == '') {
                    
                    try {
                        string[] cfgPs = AuthorCfgParams.split('\\^');
                        string[] cfgP;
                        
                        for (string P : cfgPs) {
                            cfgP = P.split('\\~');
                            if (cfgP[0] == 'HelpRecordId') {
                                Params = cfgP[1];
                                AuthorCfgApplied = true;
                            }
                        }
                    } catch (exception ex) {}
                    
                }                               
                retVal = concatenateJSON(retVal, getTaggedItems(cIHQ, Params)); 
            }


            if (ActionCode == 'Search') {
                
                string HTIDClause = '';
                string[] HTIDs;
                string[] parms;
                string searchTerm;
                string strSearchSOQL;
                HelpTopic__c[] HTs1;
                HelpTopic__c[] HTs2;
                HelpTopic__c[] HTResults = new HelpTopic__c[]{};
                
                
                // Incoming parameters will be a keyword, plus a CSV of the IDs of any previous search result topics
                // that user wants to retain on a further round of searching, in the form:
                // [Search Term] [Delimiter] [IDs CSV]
                parms = Params.split(ControllerSettings.D1);
                
                // Adjust search term to maximise flexibility (LIKE)
                // 1.41.11+  : amending to deal with wildcards, as in classic / search controller
                //searchTerm = '%' + parms[0] + '%';
                
                // We need to act in the same way as SF searching - so:
                // "%" to be treated as a literal
                // "*" to be the wildcard (to act as SOQL %)
                // "?" to act for any single character (to act as SOQL _)
                
                string sTerm = parms[0];
                if (sTerm == null) {sTerm = '';}


                // Log a Search interaction - with the supplied term prior to adjustments for wildcards
                try {
                    logLUXInteraction(7, sTerm, IHContext);
                } catch (exception ex) {}

                
                sTerm = sTerm.replace('%', '\\%');
                sTerm = sTerm.replace('*', '%');
                sTerm = sTerm.replace('?', '_');
                
                sTerm = '%' + sTerm + '%';       
                
                searchTerm = sTerm;              

                
                // Process IDs into an "IN" clause
                if (parms.size() > 1) {
                    HTIDs = parms[1].split(',');
                    for (string H : HTIDs) {
                        HTIDClause += '\'' + H + '\',';
                    }
                    if (HTIDClause.length() > 0) {
                        HTIDClause = HTIDClause.substring(0, HTIDClause.length() - 1);
                    } else {
                        HTIDClause = '\'\'';
                    }
                    
                } else {
                    HTIDClause = '\'\'';
                }
                                
                Boolean bmkInfoOK = cIHQ.cH.initialiseBookmarks(false, false);

                // Get items matching selections                     
                // NOTE: we're having to do this via DB query as we otherwise cannot include multiple HTIDs via an "IN" clause for "selected" items
                //strSearchSOQL = 'SELECT Id, Name, iahelp__Summary__c, CustomStyle__c, iahelp__CalloutHeight__c, iahelp__CalloutTemplate__r.iahelp__PageURL__c, LastModifiedDate ';
                //strSearchSOQL +='FROM iahelp__HelpTopic__c ';

                    strSearchSOQL = cH.getHelpTopicSelectSOQL();

                strSearchSOQL +='WHERE Id IN (' + HTIDClause + ') ';
                        
                HTs1 = database.query(strSearchSOQL);

                // Get items matching search term (limited to 1000 rows) - and, to avoid duplicates, not including "selected" IDs
                //strSearchSOQL = 'SELECT Id, Name, iahelp__Summary__c, CustomStyle__c, iahelp__CalloutHeight__c, iahelp__CalloutTemplate__r.iahelp__PageURL__c, LastModifiedDate ';
                //strSearchSOQL +='FROM iahelp__HelpTopic__c ';

                strSearchSOQL = cH.getHelpTopicSelectSOQL();

                strSearchSOQL +='WHERE (Name LIKE \'' + searchTerm + '\' ';
                strSearchSOQL +='OR iahelp__Summary__c LIKE \'' + searchTerm + '\' ';               
                strSearchSOQL +='OR iahelp__DescriptionText1__c LIKE \'' + searchTerm + '\' ';
                strSearchSOQL +='OR iahelp__DescriptionText2__c LIKE \'' + searchTerm + '\' ';
                strSearchSOQL +='OR iahelp__DescriptionText3__c LIKE \'' + searchTerm + '\' ';
                strSearchSOQL +='OR iahelp__DescriptionText4__c LIKE \'' + searchTerm + '\' ';
                strSearchSOQL +='OR iahelp__DescriptionText5__c LIKE \'' + searchTerm + '\') ';
                strSearchSOQL +='AND Id NOT IN (' + HTIDClause + ') ';
                
                // NEED TO CHECK FOR INACTIVE TOPICS HERE / RESPECT USER PERMS!
                boolean bAct = userPermLevel < 2;
                strSearchSOQL += 'AND (Active__c = true OR Active__c = ' + bAct + ') ';
                strSearchSOQL +='LIMIT 1000';
                        
                HTs2 = database.query(strSearchSOQL);
                                
                // Combine both sets of topics to produce output
                // Try/Catch avoids duplicates across our 2 HT lists
                for (HelpTopic__c H : HTs1) {
                    try {
                        HTResults.add(H);
                    } catch (exception exc) {}
                }

                for (HelpTopic__c H : HTs2) {
                    try {
                        HTResults.add(H);
                    } catch (exception exc) {}
                }
                
                for (iahelp__HelpTopic__c HT : HTResults) {                             
                    LI = new ServiceIHLists.ListingItem();
                    LI.Id = HT.Id;
                    LI.Label = HT.Name;
                    LI.Title = HT.iahelp__Summary__c;
                    LI.Icon = 'fa-search';
                    LI.IconLabel = '';
                    LI.IconTitle = 'Search Results';
                    
                    // Add any custom style, plus recency marker where relevant
                    LI.StyleClass = HT.CustomStyle__c;
                    if (HT.LastModifiedDate > dTRecenyLimit) {LI.StyleClass += ' ' + recencyMarker;}
                    
                    // NB: Search results launch to full topic views (as in classic): there may not be 
                    // a helped element, so we cannot log a callout topic view (which requires this).
                    // SO: we differentiate the action code here (treat as portal view)
                    LI.ActionCode = 'ViewInPortal';
                    LI.Parameters = HT.iahelp__CalloutHeight__c + '^' + HT.iahelp__CalloutTemplate__r.iahelp__PageURL__c;

                    // Add an indication of whether or not the topic underlying this element is bookmarked or not
                    if (bmkInfoOK) {
                        for (ServiceIHLists.BookmarkListItem Bmk : cIHQ.cH.Bookmarks) {
                            LI.RowState = 'NotBookmarked';
                            if (Bmk.HTID == HT.Id) {
                                LI.RowState = 'Bookmarked';
                                break;
                            }
                        }
                    }

                    LIs.add(LI);
                }
                
        NVP = new NameValuePair('HelpTopics', 'HelpTopics', '' + JSON.serialize(HTResults));
        NVPs.add(NVP);    
                        
            }



            if (ActionCode == 'SearchResources' || ActionCode == 'SearchRelatedHelp') {
            
                string sTerm = Params;
                if (sTerm == null) {sTerm = '';}
            
            
                sTerm = sTerm.replace('%', '\\%');
                sTerm = sTerm.replace('*', '%');
                sTerm = sTerm.replace('?', '_');
                            
                
                timeStamps += getTimeStamp() + 'getTools - Searching for: "' + sTerm + '" with context "' + IHContext + '"... ';
                
                ControllerSearch CS = new ControllerSearch();
                CS.Term = sTerm;
                CS.HTID = IHContext;
                
                if (ActionCode == 'SearchResources') {  
                    CS.Opts = '3';
                } else {
                    CS.Opts = '1';
                }   
                CS.showSearchResults();
                
                for (ControllerSearch.SearchResult SR : CS.FieldHelp) {
                    LI = new ServiceIHLists.ListingItem();
                    
                    LI.Id = SR.Id;
                    LI.Label = SR.Name;                        
                    LI.Title = SR.Summary;   
                    LI.Icon = 'fa-map-signs';            
                    
                    if (ActionCode == 'SearchResources') {
                            LI.ActionCode = 'Resource';                     
                    } else {
                        LI.ActionCode = '';                  
                    }   
                
                    LI.Parameters = SR.Link; 
                            
                    LIs.add(LI);
                }
                
            }



            if (ActionCode == 'HelpBookmarks') {
                if (cH.initialiseBookmarks(true, true) == true) {
                    for (ServiceIHLists.BookmarkListItem Bmk : cH.Bookmarks) {
                        LI = new ServiceIHLists.ListingItem();
                        
                        LI.Id = Bmk.HTID;
                        LI.Label = Bmk.Name;                        
                        LI.Title = Bmk.Summary;                     
                        LI.Icon = '';
                        LI.IconLabel = '';
                        LI.IconTitle = '';
                        LI.StyleClass = '';
                        LI.ActionCode = 'HelpBookmark';     
                        LI.Parameters = Bmk.ItemURL;         

                        // Bookmarks, by definition, are already bookmarked!
                        LI.RowState = 'Bookmarked';

                        LIs.add(LI);
                    }
                }
            }



            if (ActionCode == 'Keywords') {
                
                // Produce a glossary type listing of topics that form keywords in the org.
                // As ever, only active topics may be returned to non-Authors.
                
                ServiceSecurity sS = new ServiceSecurity();
                boolean[] UPs = sS.UserPermissions();
                boolean act = ! UPs[1];
                        
                for (HelpTopic__c HT : [SELECT Id, Name, Summary__c, Keyword__c
                                        FROM HelpTopic__c
                                        WHERE Keyword__c != ''
                                        AND (Active__c = true OR Active__c = :act) 
                                        ]) {
                    LI = new ServiceIHLists.ListingItem();
                                    
                    LI.Id = HT.Id;
                    LI.Label = HT.Keyword__c;                        
                    LI.Title = '(' + HT.Name + ') ' + HT.Summary__c;                     
                    LI.Icon = 'fa-key';
                    LI.IconLabel = '';
                    LI.IconTitle = '';
                    LI.StyleClass = '';
                    LI.ActionCode = 'HelpCallout';     
                    LI.Parameters = '';         
                    LI.RowState = '';
            
                    LIs.add(LI);
                }
                
            }


            if (ActionCode == 'QuickLinks') {
                
                if (ControllerSettings.getSettings().QuickLink1__c != null && ControllerSettings.getSettings().QuickText1__c != null) {
                    LI = new ServiceIHLists.ListingItem();

                    if (ControllerSettings.getSettings().QuickTip1__c != null) {
                        LI.Title = ControllerSettings.getSettings().QuickTip1__c;
                    } else {
                        //LI.Title = mapGlbLocs.get('TipGoto') + ' ' + ControllerSettings.getSettings().QuickText1__c;                   
                        LI.Title = 'Goto: ' + ControllerSettings.getSettings().QuickText1__c;                   
                    }

                    LI.Id = ControllerSettings.getSettings().QuickLink1__c;
                    LI.Label = ControllerSettings.getSettings().QuickText1__c;
                    LI.Icon = '';
                    LI.IconLabel = '';
                    LI.IconTitle = '';
                    LI.StyleClass = '';
                    LI.ActionCode = 'QuickLink';        
                    LI.Parameters = '';
                    LI.RowState = '';           

                    LIs.add(LI);
                }

                if (ControllerSettings.getSettings().QuickLink2__c != null && ControllerSettings.getSettings().QuickText2__c != null) {
                    LI = new ServiceIHLists.ListingItem();

                    if (ControllerSettings.getSettings().QuickTip2__c != null) {
                        LI.Title = ControllerSettings.getSettings().QuickTip2__c;
                    } else {
                        //LI.Title = mapGlbLocs.get('TipGoto') + ' ' + ControllerSettings.getSettings().QuickText2__c;                   
                        LI.Title = 'Goto: ' + ControllerSettings.getSettings().QuickText2__c;                   
                    }

                    LI.Id = ControllerSettings.getSettings().QuickLink2__c;
                    LI.Label = ControllerSettings.getSettings().QuickText2__c;
                    LI.Icon = '';
                    LI.IconLabel = '';
                    LI.IconTitle = '';
                    LI.StyleClass = '';
                    LI.ActionCode = 'QuickLink';        
                    LI.Parameters = '';         
                    LI.RowState = '';           

                    LIs.add(LI);
                }
                
                if (ControllerSettings.getSettings().QuickLink3__c != null && ControllerSettings.getSettings().QuickText3__c != null) {
                    LI = new ServiceIHLists.ListingItem();

                    if (ControllerSettings.getSettings().QuickTip3__c != null) {
                        LI.Title = ControllerSettings.getSettings().QuickTip3__c;
                    } else {
                        //LI.Title = mapGlbLocs.get('TipGoto') + ' ' + ControllerSettings.getSettings().QuickText3__c;                   
                        LI.Title = 'Goto: ' + ControllerSettings.getSettings().QuickText3__c;                   
                    }

                    LI.Id = ControllerSettings.getSettings().QuickLink3__c;
                    LI.Label = ControllerSettings.getSettings().QuickText3__c;
                    LI.Icon = '';
                    LI.IconLabel = '';
                    LI.IconTitle = '';
                    LI.StyleClass = '';
                    LI.ActionCode = 'QuickLink';        
                    LI.Parameters = '';         
                    LI.RowState = '';           

                    LIs.add(LI);
                }
                
                if (ControllerSettings.getSettings().QuickLink4__c != null && ControllerSettings.getSettings().QuickText4__c != null) {
                    LI = new ServiceIHLists.ListingItem();

                    if (ControllerSettings.getSettings().QuickTip4__c != null) {
                        LI.Title = ControllerSettings.getSettings().QuickTip4__c;
                    } else {
                        //LI.Title = mapGlbLocs.get('TipGoto') + ' ' + ControllerSettings.getSettings().QuickText4__c;                   
                        LI.Title = 'Goto: ' + ControllerSettings.getSettings().QuickText4__c;                   
                    }

                    LI.Id = ControllerSettings.getSettings().QuickLink4__c;
                    LI.Label = ControllerSettings.getSettings().QuickText4__c;
                    LI.Icon = '';
                    LI.IconLabel = '';
                    LI.IconTitle = '';
                    LI.StyleClass = '';
                    LI.ActionCode = 'QuickLink';        
                    LI.Parameters = '';         
                    LI.RowState = '';           

                    LIs.add(LI);
                }
                
                if (ControllerSettings.getSettings().QuickLink5__c != null && ControllerSettings.getSettings().QuickText5__c != null) {
                    LI = new ServiceIHLists.ListingItem();

                    if (ControllerSettings.getSettings().QuickTip5__c != null) {
                        LI.Title = ControllerSettings.getSettings().QuickTip5__c;
                    } else {
                        //LI.Title = mapGlbLocs.get('TipGoto') + ' ' + ControllerSettings.getSettings().QuickText5__c;                   
                        LI.Title = 'Goto: ' + ControllerSettings.getSettings().QuickText5__c;                   
                    }

                    LI.Id = ControllerSettings.getSettings().QuickLink5__c;
                    LI.Label = ControllerSettings.getSettings().QuickText5__c;
                    LI.Icon = '';
                    LI.IconLabel = '';
                    LI.IconTitle = '';
                    LI.StyleClass = '';
                    LI.ActionCode = 'QuickLink';        
                    LI.Parameters = '';         
                    LI.RowState = '';           

                    LIs.add(LI);
                }
            }
            

            if (ActionCode == 'Guides') {
                
                // Use search controller logic here, as Guide selection is moderately involved
                ControllerSearch cS = new ControllerSearch();
                
                cS.Opts = '5';              // Search for Guides
                cS.Term = '*';              // Return all matches (as if entering '*' into search dialogue)
                cS.objId = cIHQ.SFObjId;    // Settings should have been initialised above, thus should "know" object we seek from supplied IHContext
                cS.ShowSearchResults();     // This call should populate results (FieldHelp member data) to iterate into our own listing class items...

                for (ControllerSearch.SearchResult SR : cS.FieldHelp) {

                    LI = new ServiceIHLists.ListingItem();

                    LI.Id = SR.Id;
                    LI.Label = SR.Name;
                    LI.Title = SR.Summary;
                    LI.Icon = 'fa-list-ol';
                    LI.IconTitle = '';
                    LI.StyleClass = '';
                    LI.IconLabel = '';
                    LI.ActionCode = 'Guide';      
                                
                    // Pass back the name and type of guide              
                    LI.Parameters = LI.Label + '^';                 
                    if (SR.RList.ReadingListType__c == 'Linear Guide') {
                        LI.Parameters += '1';
                    } else {
                        LI.Parameters += '2';                       
                    }   
                        
                    LI.RowState = '';           

                    LIs.add(LI);
                }
                
            }

            
            // NOTE on RL-related action codes:
            // "ReadingLists"       = list of all RLs relevant to current context
            // "ReadingList"        = client-side action code to show RL viewer (e.g., VF page)
            // "ReadingListEntries" = list of all ENTRIES for a given RL
            // "RListEntry"         = client-side action code to show individual RL entry

        // "AllReadingLists" = ALL RLs matching a search term by name
        if (ActionCode == 'AllReadingLists') {
            
            localDiags += 'About to obtain ALL Reading Lists matching search term... ';
            
            string[] parms;
            parms = Params.split(ControllerSettings.D1);
            string sTerm = parms[0];

            if (sTerm == null) {sTerm = '';}
            sTerm = '%' + sTerm + '%';
            
            HelpReadingList__c[] RLs = [
                SELECT Id, Name, Summary__c
                FROM HelpReadingList__c
                WHERE Name LIKE :sTerm OR Summary__c LIKE :sTerm
                LIMIT 1000
            ];
            
            
            for (HelpReadingList__c RL : RLs) {
                LI = new ServiceIHLists.ListingItem();
                                
                LI.Id = RL.id;
                LI.Label = RL.Name;
                LI.Title = RL.Summary__c;
                LI.Icon = 'fa-list-ol';
                LI.IconTitle = '';
                LI.StyleClass = '';
                LI.IconLabel = '';
                LI.ActionCode = 'ReadingList';   
                                
                // Put escaped copy of RL name into parameters for convenience             
                LI.Parameters = RL.Name.escapeHtml4();         
                                
                LI.RowState = '';           

                LIs.add(LI);
            }
        }

            if (ActionCode == 'ReadingLists' || ActionCode == 'ReadingListsXF') {
                localDiags += 'About to process Reading Lists... ';
                
                // This action varies by TOOL context:
                HelpReadingListEntry__c[] Ents;

                
                // If we're on a stand-alone card of various kinds, or are seeking template tools:
                // We want RLs relating to the current help topic
                if (ToolContext == 'CardReadingLists' || ToolContext == 'CardRelatedHelp' || ToolContext == '[Template]') {
                    list<string> HTIDs = new list<string>();
                    HTIDs.add(IHContext);
                    Ents = cH.getHelpReadingListEntriesForHTID(HTIDs, cIHQ.isAuthor);
                }


                // If we're on the QAM:
                // Get all RLs that feature on the current layout:
                // This means any RL that includes a topic featured in any HE for this context
                if (ToolContext == 'QAM') {
                    list<string>RLEHTIDs = new list<string>();
                    
                    if (cIHQ.HelpedElements != null) {
                        for (ControllerIHQAMSettings.SearchResultQAM SR : cIHQ.HelpedElements) {
                            RLEHTIDs.add(SR.Element.HelpTopic__c);      
                        }
                    } else {
                        RLEHTIDs.add(IHContext);
                    }
                    Ents = cH.getHelpReadingListEntriesForHTID(RLEHTIDs, cIHQ.isAuthor);
                }                

                
                for (HelpReadingListEntry__c Ent : Ents) {
                        
                    // We only want each reading list once, so 
                    // check before adding that we don't have it already:
                    // v1.37: we also only want RLs! NOT Guides of any type!
                    Boolean doAdd = true;
                    for (ServiceIHLists.ListingItem L: LIs) {
                        if (Ent.HelpReadingList__c == L.Id || Ent.HelpReadingList__r.ReadingListType__c != 'Reading List') {
                            doAdd = false;
                            break;
                        }
                    }

                    // v1.42: if asked to do so, exclude featured items (altogether as of this release)
                    if (ActionCode == 'ReadingListsXF' && Ent.ReadingListFeaturedUntil__c != null) {
                        doAdd = false;
                    }
                    
                    if (doAdd == true) {
                        LI = new ServiceIHLists.ListingItem();
                        LI.Id = Ent.HelpReadingList__c;
                        LI.Label = Ent.HelpReadingList__r.Name;
                        LI.Title = Ent.HelpReadingList__r.Summary__c;
                        
                        if (Ent.ReadingListFeaturedUntil__c != null) {
                            LI.Icon = 'fa-bullseye';
                            LI.IconTitle = 'FEATURED!';
                            LI.StyleClass = 'FeaturedListItem';
                        } else {
                            LI.Icon = 'fa-list-ol';
                            LI.IconTitle = '';
                            LI.StyleClass = '';
                        }

                        LI.IconLabel = '';
                        LI.ActionCode = 'ReadingList';   
                            
                        // Put escaped copy of RL name into parameters for convenience             
                        LI.Parameters = Ent.HelpReadingList__r.Name.escapeHtml4();         
                        
                        LI.RowState = '';           

                        LIs.add(LI);
                    }
                }   
            }


            if (ActionCode == 'AllResources') {
                
                // If we were provided with author overrides, check for help topic ID amoung them
                // and use in preference to default (i.e., if we weren't asked for specific topic to which to relate)                
                if (AuthorCfgParams != '' && (IHCXTSuppliedBlank == true || IHContext == '[None]')) {

                    try {
                        string[] cfgPs = AuthorCfgParams.split('\\^');
                        string[] cfgP;
                        
                        for (string P : cfgPs) {
                            cfgP = P.split('\\~');
                            if (cfgP[0] == 'HelpRecordId') {
                                IHContext = cfgP[1];
                                AuthorCfgApplied = true;
                            }
                        }
                    } catch (exception ex) {}   
                }                
                HelpTopicResource__c[] HTRes = cH.getHelpTopicResourcesForHT(IHContext);
                

                for (HelpTopicResource__c HTR : HTRes) {

                    LI = new ServiceIHLists.ListingItem();
                    LI.Id = HTR.Id;
                    
                    LI.Label = HTR.HelpResource__r.Name;
                    LI.Title = HTR.UsageNotes__c;

                    // Icon is a function of resource type
                    if (HTR.HelpResource__r.ResourceType__c == 'Document') {
                        LI.Icon = 'fa-file-text';
                    } else if (HTR.HelpResource__r.ResourceType__c == 'Video') {
                        LI.Icon = 'fa-file-video-o';
                    } else if (HTR.HelpResource__r.ResourceType__c == 'Image') {
                        LI.Icon = 'fa-image';
                    } else if (HTR.HelpResource__r.ResourceType__c == 'Web-page') {
                        LI.Icon = 'fa-external-link';
                    } else {
                        LI.Icon = 'fa-map-signs';
                    }
                    
                    LI.IconLabel = HTR.HelpResource__r.Location__c;
                    LI.IconTitle = HTR.HelpResource__r.ResourceType__c;
                    LI.StyleClass = '';

                    LI.ActionCode = 'Resource';                 
                    LI.Parameters = HTR.HelpResource__r.ResourceURL__c;         
                    LI.RowState = '';           

                    LIs.add(LI);
                }
            }
            

            if (ActionCode == 'CommentsAll' 
                || ActionCode == 'CommentsHPLs'
                || ActionCode == 'CommentsRLs'
                || ActionCode == 'CommentsTopics'
            ){
                    
                list<iahelp__HelpInteraction__c> newHelpInteractionList = new list<iahelp__HelpInteraction__c>();
                string querystring = 'SELECT iahelp__Description__c ,CreatedDateTime__c,Id,';
                querystring += ' HelpTopic__r.Name, ';
                querystring += ' HelpReadingList__r.Name,';
                querystring += ' HelpedPageLayout__r.Name, HelpedPageLayout__r.iahelp__PageLayoutIdentifier__c';
                querystring += ' FROM iahelp__HelpInteraction__c';
                querystring += ' WHERE HelpInteractionType__c = \'Comment\' AND  CreatedById = \'' +UserInfo.getUserId()+'\'';

                if (ActionCode == 'CommentsHPLs') {
                    querystring += ' AND HelpedPageLayout__c != null';
                }
                
                if (ActionCode == 'CommentsTopics') {
                    querystring += ' AND HelpTopic__c != null';
                }
                
                if (ActionCode == 'CommentsRLs') {
                    querystring += ' AND HelpReadingList__c != null';
                }
                
                querystring += ' ORDER BY CreatedDate DESC limit 100';
                
                List<HelpInteraction__c> sobjhelpTopicsList = database.query(querystring);
                
                for (HelpInteraction__c HR : sobjhelpTopicsList) { 
                    LI = new ServiceIHLists.ListingItem();
                    LI.Id = HR.Id;
                    LI.Label = HR.Description__c; 
                    LI.ActionCode = 'DisplayCommentDetails';
                    LI.Parameters = JSON.Serialize(HR) +'^'+HR.CreatedDateTime__c.format('dd-MMM-yy');
                    LIs.add(LI);                   
                }
                
            }



            if (ActionCode == 'HelpComments') {
                
                //Comments option as used in QAM
                
                string lastId;
                string HTIDs = '';
                string HPL = '';
                string strSQL;
                
                
                // Note every topic referenced in elements on the current layout
                if (cIHQ.HelpedElements != null) {
                    for (ControllerIHQAMSettings.SearchResultQAM SR : cIHQ.HelpedElements) {
                        HPL = SR.Element.HelpedPageLayout__c;
                        if (SR.Element.HelpTopic__c != null) HTIDs += '\'' + SR.Element.HelpTopic__c + '\',';
                    }
                }

                if (HTIDs.length() > 0) HTIDs = HTIDs.substring(0, HTIDs.length() -1);
                
                strSQL = 'SELECT Id, HelpInteractionType__c, Description__c, CreatedDateTime__c, HelpTopic__c, HelpTopic__r.Name, HelpTopic__r.CreatedBy.Name, HelpedPageLayout__c, HelpedPageLayout__r.Name ';
                strSQL += 'FROM iahelp__HelpInteraction__c ';
                strSQL += 'WHERE HelpInteractionType__c = \'Comment\' ';
                strSQL += 'AND CreatedById = \'' + UserInfo.getUserId() + '\' ';
                strSQL += 'AND (HelpedPageLayout__c = \'' + HPL + '\' OR HelpTopic__c IN(' + HTIDs + ')) '; 
                strSQL += 'ORDER BY HelpTopic__r.Name, CreatedDateTime__c DESC ';
                strSQL += 'LIMIT 100';

                for (HelpInteraction__c HR : database.query(strSQL)) { 
                    
                    LI = new ServiceIHLists.ListingItem();
                    LI.Id = HR.Id;
                    
                    if (HR.HelpTopic__r.Name == '' || HR.HelpTopic__r.Name == null) {
                        if (HR.HelpedPageLayout__c != lastId) {
                            LI.Label = 'LAYOUT: ' + HR.HelpedPageLayout__r.Name;
                        } else {
                            LI.Label = '';
                        }
                        lastId = HR.HelpedPageLayout__c;

                    } else {
                        if (HR.HelpTopic__c != lastId) {
                            LI.Label = 'TOPIC: ' + HR.HelpTopic__r.Name + ' (created by ' + HR.HelpTopic__r.CreatedBy.Name + ')';
                        } else {
                            LI.Label = '';                          
                        }
                        lastId = HR.HelpTopic__c;
                    }
                    

                    LI.Title = '>> ' + HR.CreatedDateTime__c.format('dd-MMM-yy') + ': ' + HR.Description__c;
                    LI.Icon = 'fa-image';
                    LI.IconLabel = '';
                    LI.IconTitle = '';
                    LI.StyleClass = '';
                    LI.ActionCode = 'CommentInteraction';                   
                    LI.Parameters = '';         
                    LI.RowState = '';           

                    LIs.add(LI);
                }
            }


            if (ActionCode == 'Stickies') {
                
                // Get exitsing stickies LIST for the current user for the current help context
                try {
                    
                    // Try to get all notes for the context's object, rather than the specific object record, where relevant
                    string IHC = IHContext;
                    ServiceSchema svsS = new ServiceSchema();
                    string allIds = '';
                    Schema.DescribeSObjectResult objDesc;
                    string objName;                 
                    string strSOQL;
                    sObject[] results;
                    sObject result;                 
                    map<id,sObject> mapIds = new map<id,sObject>();
                    
                    if (IHC.length() > 2) {
                        IHC = IHC.substring(0,3);                       
                        objDesc = svsS.getObjectDetails(IHC);
                        
                        if (objDesc == null) {
                            // If object code unrecognised, revert to full context
                            IHC = IHContext;
                            objName = '';
                        } else {
                            // If object is recognised, note its name
                            objName = objDesc.getName();
                        }
                    }
                    IHC += '%';
                    
                    // Only return stickies if these are being tracked
                    if (ControllerSettings.getSettings().TrackDaysLUXOps__c > 0) {
                        
                        for (HelpInteraction__c HI : [SELECT Id, HelpInteractionType__c, Context__c, Description__c, CreatedDate
                                FROM HelpInteraction__c
                                WHERE HelpInteractionType__c = 'Sticky'
                                AND OwnerId = :UserInfo.getUserId()
                                AND Context__c LIKE :IHC
                                ORDER BY Context__c, iahelp__CreatedDateTime__c DESC
                            ]) {
                                
                            // Only add the latest note for each matching context (i.e., any given record)
                            if (allIds.indexOf(HI.Context__c) == -1) {
                                
                                LI = new ServiceIHLists.ListingItem();
                                LI.Id = HI.Id;
                                
                                LI.Label = HI.CreatedDate.format('d MMM yy');
                                
                                // Deal with blank note text
                                if (HI.Description__c + '' != 'null') {
                                    LI.Title = HI.CreatedDate.format('HH:mm') + ' - ' + HI.Description__c;
                                } else {
                                    LI.Title = HI.CreatedDate.format('HH:mm') + ' - ';
                                }
                                
                                String br = String.fromCharArray(new List<integer>{10});
                                LI.Title = LI.Title.replace(br, '<br/>');
                                
                                if (LI.Label.length() > 80) {
                                    LI.Label = LI.Label.substring(0, 80) + '...';
                                }
                                
                                LI.Icon = 'fa-sticky-note-o';
                                LI.IconLabel = '';
                                LI.IconTitle = '';
                                
                                // Style notes applicable to current context record, if found, so they stand out...
                                if (HI.Context__c == IHContext) {
                                    LI.StyleClass = 'SelectedRecord';
                                } else {
                                    LI.StyleClass = '';
                                }

                                LI.ActionCode = 'Sticky';                   
                                LI.Parameters = HI.Context__c;         
                                LI.RowState = '';           
            
                                LIs.add(LI);    
                                                            
                                allIds += '\'' + HI.Context__c + '\', ';
                            }
                        }     
                        
                        
                        // Loop again through the listing items to look up name of referenced record, where relevant                        
                        if (allIds.length() > 1 && objName != ' ') {                            
                            allIds = allIds.substring(0, allIds.length() -2);
                            
                            strSOQL = 'SELECT Id, Name FROM ' + objName + ' ';
                            strSOQL += 'WHERE Id IN (' + allIds + ')';
                            results = database.query(strSOQL);
                            
                            for (sObject O : results) {
                                mapIds.put(O.Id, O);
                            }
                            
                            for (ServiceIHLists.ListingItem L : LIs) {
                                
                                result = mapIds.get(L.Parameters);
                                if (result != null) {
                                    L.Label += ': ' + result.get('Name');
                                }
                            }
                        }
                                                                    
                    }
                                        
                } catch (exception ex) {
                    return 'STICKIES: ' + ex.getMessage();
                }
            }




            if (ActionCode == 'AllRelatedHelp' || ActionCode == 'ChildHelp' || ActionCode == 'OnlyRelatedHelp') {

                ServiceIHLists.RelatedHelpListItem[] Relations = new ServiceIHLists.RelatedHelpListItem[]{};
            
                // Get the relationship records
                HelpRelationship__c[] Rels = cH.getHelpRelationshipsForHT(IHContext, !(cIHQ.isAuthor || cIHQ.isAdministrator));
            
                // Process relationships based on the ActionCode
                for (HelpRelationship__c HR : Rels) {
                    if (ActionCode == 'ChildHelp') {
                        // Include only relations with type = Parent
                        if (HR.SemanticTag__r.Name == 'Parent' && HR.ReferringTopic__c == IHContext) {
                            Relations.add(new ServiceIHLists.RelatedHelpListItem(HR, IHContext, true, true, true, false, cIHQ.isAuthor || cIHQ.isAdministrator));
                        }
                    } else if (ActionCode == 'OnlyRelatedHelp') {
                        // Exclude relations with type = Parent
                        if (HR.SemanticTag__r.Name != 'Parent') {
                            Relations.add(new ServiceIHLists.RelatedHelpListItem(HR, IHContext, true, true, true, false, cIHQ.isAuthor || cIHQ.isAdministrator));
                        }
                    } else {
                        Relations.add(new ServiceIHLists.RelatedHelpListItem(HR, IHContext, true, true, true, false, cIHQ.isAuthor || cIHQ.isAdministrator));
                    }
                }
                Relations.sort();
            
                // Iterate the search result objects to create listing items
                for (ServiceIHLists.RelatedHelpListItem HR : Relations) {
                    LI = new ServiceIHLists.ListingItem();
                    LI.Label = HR.Name;
                    LI.Title = HR.Summary;
                    LI.ActionCode = 'RelatedHelp';
                    if (IHContext == HR.HR.ReferringTopic__c) {
                        // Refers to / source
                        LI.Icon = 'fa-arrow-up fa-rotate-45';
                        LI.IconLabel = '';
                        LI.IconTitle = '';
                        LI.Id = HR.HR.RelatedHelpTopic__r.Id;
                        LI.Parameters = 'REL';
            
                        // Add any custom style, plus recency marker where relevant
                        LI.StyleClass = HR.HR.RelatedHelpTopic__r.CustomStyle__c;
                        if (HR.HR.RelatedHelpTopic__r.LastModifiedDate > dTRecenyLimit) {
                            LI.StyleClass += ' ' + recencyMarker;
                        }
                    } else {
                        // Referred from / destination
                        LI.Icon = 'fa-arrow-right fa-rotate-45';
                        LI.IconLabel = '';
                        LI.IconTitle = '';
                        LI.Id = HR.HR.ReferringTopic__r.Id;
                        LI.Parameters = 'REF';
            
                        // Add any custom style, plus recency marker where relevant
                        LI.StyleClass = HR.HR.ReferringTopic__r.CustomStyle__c;
                        if (HR.HR.ReferringTopic__r.LastModifiedDate > dTRecenyLimit) {
                            LI.StyleClass += ' ' + recencyMarker;
                        }
                    }
                    system.debug(LI.RowState);
                    LI.RowState = '';
                    LIs.add(LI);
                }
            
                // Create List of iahelp__HelpBookmark__c which are related to current User
                Set<Id> helpTopicIds = new Set<Id>();
                List<iahelp__HelpBookmark__c> lstBmk = [SELECT Id, Name, OwnerId, iahelp__HelpTopic__c 
                                                        FROM iahelp__HelpBookmark__c 
                                                        WHERE OwnerId = :UserInfo.getUserId()];
                                                        
                system.debug('lstBmk=='+lstBmk);
                system.debug('LIs=='+LIs);
                for (iahelp__HelpBookmark__c bmkObj : lstBmk) {
                    helpTopicIds.add(bmkObj.iahelp__HelpTopic__c);
                }
                system.debug('helpTopicIds='+helpTopicIds);
            
                for (ServiceIHLists.ListingItem l : LIs) {
                    if (helpTopicIds.contains(l.Id)) {
                        l.RowState = 'Bookmarked';
                    } else {
                        l.RowState = 'NotBookmarked';
                    }
                }
            }

            
            /*
            /////////////////////////////////////////////////
            if (ActionCode == 'AllRelatedHelp' || ActionCode == 'ChildHelp') {
                
                ServiceIHLists.RelatedHelpListItem[] Relations = new ServiceIHLists.RelatedHelpListItem[]{};

                // Get the relationship records
                HelpRelationship__c[] Rels = cH.getHelpRelationshipsForHT(IHContext, !(cIHQ.isAuthor || cIHQ.isAdministrator));
                
                // Use these to create search result objects, just as we would on the tools page,
                // as these contain the required to / from logic and can be sorted
                for (HelpRelationship__c HR : Rels) {
                    
                    // For child help, return only relations of type = parent
                    if (ActionCode == 'ChildHelp') {
                        if (HR.SemanticTag__r.Name == 'Parent' && HR.ReferringTopic__c == IHContext) {
                            Relations.add(New ServiceIHLists.RelatedHelpListItem(HR, IHContext, true, true, true, false, cIHQ.isAuthor || cIHQ.isAdministrator));
                        }
                    } else {
                        Relations.add(New ServiceIHLists.RelatedHelpListItem(HR, IHContext, true, true, true, false, cIHQ.isAuthor || cIHQ.isAdministrator));
                    }                   
                }
                Relations.sort();
                
                
                // Now iterate the search result objects to create our listing items
                for (ServiceIHLists.RelatedHelpListItem HR : Relations) {
                    LI = new ServiceIHLists.ListingItem();
                    
                    LI.Label = HR.Name;                   
                    LI.Title = HR.Summary;


                    // In these cases, use our listing columns to offer some info about the nature of the relationship:
                    // Each column is D1 delimited
                    // Within each column, value is:
                    // Label [D2] Tool tip

        /*
        SUPPRESS FOR 1.43.0
        */

        /*                  
                    if (HR.HR.SemanticTag__c != null) {
                        // Column label = semantic name
                        LI.Cols = HR.HR.SemanticTag__r.Name;
                        LI.Cols += ControllerSettings.D2;
                        
                        // Column tip = full relationship details
                        LI.Cols += '\"' + HR.Name + '\" -- ' + HR.HR.SemanticTag__r.Obverse__c + ' -- \"' + HR.HR.ReferringTopic__r.Name + '\"'; 
                        
                    } else {
                        LI.Cols = '-' + ControllerSettings.D2 + '-';
                    }
        ///////////////////////////////////////                
                    
                    
                    LI.ActionCode = 'RelatedHelp';

                    if (IHContext == HR.HR.ReferringTopic__c) {
                        // Refers to / source                   
                        LI.Icon = 'fa-arrow-up fa-rotate-45';
                        LI.IconLabel = '';
                        LI.IconTitle = '';
                        LI.Id = HR.HR.RelatedHelpTopic__r.Id;
                        LI.Parameters = 'REL';
                        
                        // Add any custom style, plus recency marker where relevant         
                        LI.StyleClass = HR.HR.RelatedHelpTopic__r.CustomStyle__c;
                        if (HR.HR.RelatedHelpTopic__r.LastModifiedDate > dTRecenyLimit) {LI.StyleClass += ' ' + recencyMarker;}                                               

                    }  else {
                        // Referred from / destination
                        LI.Icon = 'fa-arrow-right fa-rotate-45';
                        LI.IconLabel = '';
                        LI.IconTitle = '';
                        LI.Id = HR.HR.ReferringTopic__r.Id;         
                        LI.Parameters = 'REF';         
                        
                        // Add any custom style, plus recency marker where relevant
                        LI.StyleClass = HR.HR.ReferringTopic__r.CustomStyle__c;
                        if (HR.HR.ReferringTopic__r.LastModifiedDate > dTRecenyLimit) {LI.StyleClass += ' ' + recencyMarker;}
                        
                        
                    }

                    
                    
                    //LI.Id = LI.Parameters;
                    system.debug(LI.RowState);
                    LI.RowState = '';
                    LIs.add(LI);
                }
                //Create List of iahelp__HelpBookmark__c which are related to current User
                Set <Id> helpTopicIds = new Set <Id>();
                List <iahelp__HelpBookmark__c> lstBmk = [SELECT Id, Name, OwnerId, iahelp__HelpTopic__c 
                                                            FROM iahelp__HelpBookmark__c 
                                                            where OwnerId = :UserInfo.getUserId()];
                system.debug('lstBmk=='+lstBmk);
                system.debug('LIs=='+LIs);
                
                for(iahelp__HelpBookmark__c bmkObj : lstBmk) {
                    helpTopicIds.add(bmkObj.iahelp__HelpTopic__c);
                }
                
                system.debug('helpTopicIds='+helpTopicIds);
                
                for(ServiceIHLists.ListingItem l : LIs) {
                    
                    if(helpTopicIds.contains(l.Id)) {
                        l.RowState = 'Bookmarked';
                    } else {
                        l.RowState = 'NotBookmarked';
                    }
                    
                }   
            }
                */
            
            
            if (ActionCode == 'TreeNodes') {

                localDiags += 'Action = TreeNodes... ';
                timeStamps += getTimeStamp() + 'getTools - TreeNodes action... ';  
                

                // We may need, subject to parameters (Maximum Depth) to limit the iterations of children we process:
                // Parameters passed also include details (optionally) of "TreeNodeSupplier" implementation to use to build our tree 
                string[] Ps = Params.split('\\^');
                integer levelsMax = integer.valueOf(Ps[0]);
                ServiceIHLists.TreeNodeSupplier TNS;
                string providerClassName = Ps[1];
                integer levelsProcessed = 0;


                // Node source depends on context whose tree we're asked to supply and / or specified provider              
                // HERE WE SHOULD USE THE USER-SPECIFIED IMPLEMENTATION, IF SPECIFIED
                // ALLOWING USE OF LOCAL TREE NODE PROVIDERS IF DESIRED...

                if (providerClassName == '' || providerClassName == null || providerClassName + '' == 'undefined') {

                    if (IHContext.startsWith(ServiceSchema.getObjectIdByName('iahelp__HelpTopic__c'))) {           
                        
                        // v1.50: for help topics, two providers are now available (fixed alpha sorting or user specified order)
                        // Use the default provider specified in global settings:
                        providerClassName = ControllerSettings.getSettings().DefaultHelpTopicTreeProvider__c;
                        
                    
                    } else if (IHContext.startsWith(ServiceSchema.getObjectIdByName('iahelp__HelpReadingList__c'))) {
                        providerClassName = 'ServiceIHTrees.TNSReadingLists';

                    } else if (IHContext.startsWith(ServiceSchema.getObjectIdByName('iahelp__HelpedPageLayout__c'))) {                
                        providerClassName = 'ServiceIHTrees.TNSHelpedPageLayouts';
                    } else {
                        // Default to topic provider if topic provider is blank and there's no default root node (IHContext)
                        // v1.50: for help topics, two providers are now available (fixed alpha sorting or user specified order)
                        // Use the default provider specified in global settings:
                        providerClassName = ControllerSettings.getSettings().DefaultHelpTopicTreeProvider__c;
                        
                        // Default of last resort
                        if (providerClassName == '' || providerClassName + '' == 'null' || providerClassName == null || providerClassName + '' == 'undefined') {
                            providerClassName = 'ServiceIHTrees.TNSHelpTopics';
                        }
                    }
                }    
                
                localDiags += 'Provider will be: ' + providerClassName + '... ';
                timeStamps += getTimeStamp() + 'getTools - Provider will be: ' + providerClassName + '... ';                       
                                
                try {
                    Type t = Type.forName(providerClassName); 
                    TNS = (ServiceIHLists.TreeNodeSupplier)t.newInstance(); 


                    /*
                    Check whether this provider offers extended capabilities
                    or simply the 'base' (historical) tree interface
                    */
                    
                    if (TNS instanceOf ServiceIHLists.TreeOpsSupplier) {
                        
                        ServiceIHLists.TreeOpsSupplier TOps = (ServiceIHLists.TreeOpsSupplier) TNS;
                        
                        // Check capabilities
                        ServiceIHLists.KnownTreeOps[] Ops = TOps.SupportedOperations();
                        
                        // Where capabilities exist, pass info about these back
                        for (ServiceIHLists.KnownTreeOps Op : Ops) {
                            if (Op == ServiceIHLists.KnownTreeOps.JITFetching) {
                                NVP = new NameValuePair('SupportedTreeOps', 'JITFetching', 'true');
                                NVPs.add(NVP);      
                            }
                    
                            if (Op == ServiceIHLists.KnownTreeOps.NodeOrdering) {
                                NVP = new NameValuePair('SupportedTreeOps', 'NodeOrdering', 'true');
                                NVPs.add(NVP);      
                            }
                    
                        }
                        
                    }

                    
                    // If we were provided with author overrides, check for help topic ID amoung them
                    // and use in preference to default tree root (i.e., if we weren't asked for specific topic)
                    // NB: this overrides the '[None]' option too
                    if (AuthorCfgParams != '' && (IHCXTSuppliedBlank == true || IHContext == '[None]')) {
                        
                        try {
                            string[] cfgPs = AuthorCfgParams.split('\\^');
                            string[] cfgP;
                            
                            for (string P : cfgPs) {
                                cfgP = P.split('\\~');
                                
                                // Take root node parameter in preference to Help Record Id (which, if also
                                // supplied, should be used as the selected topic)
                                if (cfgP[0] == 'RootNode') {
                                    IHContext = cfgP[1];
                                    AuthorCfgApplied = true;
                                }
                                
                                
                                if (cfgP[0] == 'HelpRecordId' && AuthorCfgApplied == false) {
                                    IHContext = cfgP[1];
                                    AuthorCfgApplied = true;
                                }
                            }
                        } catch (exception ex) {}
                        
                    }
                    LIs = TNS.getTreeNodes(IHContext, levelsMax);
                    
        // Iterating through list of tree nodes and checking if branches are in bookmarked list or not:
        // Only attempt to log bookmarked status in this way for topic-based tree providers

        /*
        DISABLING FOR PRESENT AS THIS IS NOT REQUIRED IN ORDER TO MAKE BOOKMARKING TOOL CORRECTLY OPERATIONAL
        ON TOPIC VIEWER WITH TREE AS CACHE SOURCE (CALL TO getClickablesJSON WHEN NAVIGATING CACHE HANDLES THIS ISSUE)
        AND ADDITION OF STATE MARKERS HERE CAUSES ISSUES WITH ACTIVE MARKER FILTERS ON TOOLS - EG TreeShowPeers
        */


        /*
        if (providerClassName == 'ServiceIHTrees.TNSHelpTopics' || providerClassName == 'ServiceIHTrees.TNSHelpTopicsOrdered') {
            
            //Create List of iahelp__HelpBookmark__c which are related to current User
            Set <Id> helpTopicIds = new Set <Id>();
            List <iahelp__HelpBookmark__c> lstBmk = [SELECT Id, Name, OwnerId, iahelp__HelpTopic__c 
                                                    FROM iahelp__HelpBookmark__c 
                                                    where OwnerId = :UserInfo.getUserId()];
            for(iahelp__HelpBookmark__c bmkObj : lstBmk) {
                helpTopicIds.add(bmkObj.iahelp__HelpTopic__c);
            }
            
            for(ServiceIHLists.ListingItem l : LIs) {
                
                if(helpTopicIds.contains(l.Id)) {
                    l.RowState += ' Bookmarked';
                } else {
                    l.RowState += ' NotBookmarked';
                }
                
            }   
        }           
        */                    

                    /*
                    FOR CASES WHERE LISTING ITEM ID IS A TOPIC: USE THESE TO GET FULL TOPIC DETAILS 
                    AND APPEND TO OUR RETURN VALUE
                    */
                    
                    string strSOQLHlp = cH.getHelpTopicSelectSOQL();    
                    string inClause = '';
                    HelpTopic__c[] NodeTopics;
                    
                    for (ServiceIHLists.ListingItem L : LIs) {
                        inClause += '\'' + L.Id + '\',';
                    }        
                    if (inClause.length() > 0) {inClause = inClause.subString(0, inClause.length() - 1);} 
                                        
                    strSOQLHlp += 'WHERE Id IN (' + inClause + ')';
                    try {
                        NodeTopics = database.query(strSOQLHlp);
                        
                        // If we get topics, return info about them
                        NVP = new NameValuePair('HelpTopics', 'HelpTopics', '' + JSON.serialize(NodeTopics));
                        NVPs.add(NVP);    
                        
                        
                    } catch (exception ex) {}

                    // Add some additional internationalisations that may crop up with certain tree providers
                    mapDlgLocs = ServiceLocalisation.getDialogueLocalisations('iahelp__IHManageReadingList', false);            
                    for (string trans : mapDlgLocs.keyset()) {
                        NVP = new NameValuePair('Internationalisations', trans, mapDlgLocs.get(trans));
                        NVPs.add(NVP);            
                    }

                    
                } catch (exception e){
                    retVal = 'Tree Provider Error (' + providerClassName + ') ' + e.getMessage();
                    return retVal;
                }

                localDiags += 'TreeNodes processed by provider - continuing... ';
                timeStamps += getTimeStamp() + 'getTools - TreeNodes processed by provider - continuing... ';                                
            }
            
            
            // Before proceeding, reset help controller as we'll need to be logging interactions...
            cH = new ControllerHelpContent(true);


            // GENERALLY add listing items on to tools: HOWEVER if we're returning
            // a single record (for a "details" situation) tack on that record - NOT 
            // abstracted listing items...
            
            if (ActionCode != 'HelpTopic' && ActionCode != 'NewSticky') {
                
                // Sort whatever list items we found then add their JSON to results 
                if (LIs.size() >0) {
                    
                    // We don't want to sort stickies, as label is in a date format that won't suit sorting...
                    if (ActionCode != 'Stickies') {
                        LIs.sort();
                    }
                                                
                    retVal = concatenateJSON(retVal, JSON.serialize(LIs));

                } else {
                    // For RLEs / Reading List Viewer, we don't use listing items as such...                    
                    if (ActionCode == 'ReadingListEntries') {

                        HelpReadingListEntry__c[] Ents = [
                            SELECT Id, HelpTopic__c, ReadingOrder__c, 
                                DisplayRow__c, DisplayColumn__c, NavigationType__c, NavigationDetails__c,                             
                                HelpReadingList__r.Name,
                                HelpReadingList__r.Summary__c,  
                                HelpReadingList__r.LightningPresentationStyle__c,                                                             
                                HelpTopic__r.Name, HelpTopic__r.Summary__c, HelpTopic__r.Description__c,
                                HelpTopic__r.ImageURL__c, HelpTopic__r.ImageTitle__c, HelpTopic__r.ImageWidth__c, HelpTopic__r.ImageHeight__c,
                                HelpTopic__r.VideoURL__c, HelpTopic__r.VideoTitle__c, HelpTopic__r.VideoWidth__c, HelpTopic__r.VideoHeight__c,
                                HelpTopic__r.iahelp__Template__r.iahelp__PageURL__c,
                                HelpTopic__r.CalloutMediaChoice__c
                                
                            FROM HelpReadingListEntry__c
                            WHERE HelpReadingList__c = :IHContext
                            ORDER BY ReadingOrder__c];
                                                            
                        retVal = concatenateJSON(retVal, JSON.serialize(Ents));             
                    }

                }

                
            } else {

                if (ActionCode == 'NewSticky') {
                    // Get a single (new or existing) sticky for data entry in the current context
                    HelpInteraction__c HI;
                    
                    try {
                        // Attempt to get existing sticky
                        HI = [SELECT Id, HelpInteractionType__c, Description__c, CreatedDate
                            FROM HelpInteraction__c
                            WHERE HelpInteractionType__c = 'Sticky'
                            AND OwnerId = :UserInfo.getUserId()
                            AND Context__c = :IHContext
                            ORDER BY CreatedDate DESC
                        LIMIT 1];

                        strTemp = JSON.serialize(HI);            
                        
                    } catch (exception ex) {
                        
                        // No existing sticky - create and return a new one
                        cH.svsI.logInteraction (12, '', IHContext, null, null, null, null, null);    
                        
                        // Get the interaction just created
                        try {
                            HI = [SELECT Id, HelpInteractionType__c, Description__c, CreatedDate
                                FROM HelpInteraction__c
                                WHERE Id = :cH.svsI.Diags
                                ];
                            
                            strTemp = JSON.serialize(HI); 
                                        
                        } catch (exception exc) {
                            // If getting the sticky failed, do nothing further
                        }    
                    }

                    retVal = concatenateJSON(retVal, strTemp);
                } 


                if (ActionCode == 'HelpTopic') {
                    timeStamps += getTimeStamp() + 'getTools - HelpTopic action... ';

                    
                    // Get and return the single requested help topic
                    object[] helpInfo = new object[]{};            
                    
                    
                    // If we were provided with author overrides, check for help topic ID amoung them
                    // and use in preference to default topic (i.e., if we weren't asked for specific topic):
                    // NB: this overrides the '[None]' option too               
                    if (AuthorCfgParams != '' && (Params == '' || Params == '[None]')) {
                        
                        try {
                            string[] cfgPs = AuthorCfgParams.split('\\^');
                            string[] cfgP;
                            
                            for (string P : cfgPs) {
                                cfgP = P.split('\\~');
                                if (cfgP[0] == 'HelpRecordId') {
                                    Params = cfgP[1];
                                    AuthorCfgApplied = true;
                                }
                            }
                        } catch (exception ex) {}
                        
                    }
                    

                    // 1.39+: Do not seek a topic if we're told to start "blank" / pending some other selection
                    if (Params != '[None]') {                    

                        // We don't want to call GetHelp as this is rather "weighty" for our needs:
                        // Instead, just get the required topic in these cases:
                        // Respect user permissions on active / inactive topics...

                        cH.getTopicViaHTID(Params, userPermLevel < 2);


                        // As the JSON serialiser skips apparently blank fields, we need to specifically set empty values to "null"
                        ServiceSchema sS = new ServiceSchema();
                        string objId = ServiceSchema.getObjectIdByName('iahelp__HelpTopic__c');
                        
                        // v1.41 - performance enhancements
                        //Schema.DescribeSObjectResult sObj = sS.getObjectDetails(objId);
                        Schema.DescribeSObjectResult sObj = ServiceSchema.getObjectDetailsByName('iahelp__HelpTopic__c');
                                    
                        // For the object, get its fields and set any blanks
                        Map<String, Schema.SObjectField> FMap = sObj.Fields.getMap();
                        object objVal;
                        
                        for (string FKey : FMap.keySet()){    
                            try {
                                // Mere act of getting each field is a null check
                                objVal = cH.Hlp.get(FMap.get(FKey));
                                
                                if (objVal == null) {
                                    cH.Hlp.put(FKey, null);                     
                                }
            
                            } catch (exception ex) {
                                // Exception means field not present at all: skip
                            }
                        }            

                        helpInfo.add(cH.Hlp);
                    }                    

                    // Only engage in further topic processing if we found a record successfully                     
                    if (cH.Hlp != null) {    
                                        
                        // Log an interaction about this full topic view
                        string CXT = IHContext;
                        
                        timeStamps += getTimeStamp() + 'getTools - Action code "' + ActionCode + '": about to log Help Topic interaction for component "' + ClientComponentId + '"... ';                        
                        
                        // Commenting as of release version 1.55 to avoid duplicate logging of full topic interaction
                        
                        // cH.svsI.logInteraction (4, 'Help Topic Viewed (LEX)', CXT, null, null, cH.Hlp.Id, null, null);
                            
                
                        // Also return details of any custom fields            
                        if (cH.CustomFields != null) {
                            for (Schema.FieldSetMember CF : cH.CustomFields) {
                                    
                                // Also, as we can't directly reference the custom fields in the current record we send to LUX
                                // (e.g., {!v.CurrentRecord.get(field name)} is not allowed) we need to load these
                                // fields into our own custom object that we can reference: we will pack field info plus
                                // values from the help topic sought into these items...
        
                                helpInfo.add(new CustomFieldInfo(CF, (sObject) cH.Hlp));
                            }
                        }
                        strTemp = JSON.serialize(helpInfo);            
                        retVal = concatenateJSON(retVal, strTemp);
                            
                        
                        // Add a SINGLE listing item, too, to hold meta data: in this case, details of bookmarked status 
                        LI = ServiceIHLists.getMetadataListingItem();                   
        
                        try {
                            // Note we use the topic ID from our help controller here rather than taking params as supplied, 
                            // in case params were null and thus a default topic of some kind is in play...
                            HelpBookmark__c Bmk = [SELECT Id FROM HelpBookmark__c WHERE OwnerId = :UserInfo.getUserId() AND HelpTopic__c = :cH.Hlp.Id];
                                            
                            // Reaching this point means bookmark exists: note this
                            LI.RowState = 'Bookmarked';
                            
                        } catch (exception ex) {
                            LI.RowState = 'NotBookmarked';
                        }
        
                        LIs.add(LI);
                        retVal = concatenateJSON(retVal, JSON.serialize(LIs));

                        
                        // Add a Name / Value pair item to hold a keyword-parsed copy of topic description
                        strTemp = '';

                        timeStamps += getTimeStamp() + 'getTools - HelpTopic action marking keywords... ';                        
                        strTemp = cH.markKeywords(cH.Hlp, true); 
                        timeStamps += getTimeStamp() + 'getTools - HelpTopic action - keywords marked... ';
                                    
                                                            
                        NVP = new NameValuePair('ParsedContent', 'HelpTopicDescription', strTemp);
                        retVal = concatenateJSON(retVal, JSON.serialize(NVP));


                    } //End if found Topic OK      
                    
                    timeStamps += getTimeStamp() + 'getTools - HelpTopic action processed... ';
                                    
                } // End if action = HelpTopic
            } // End if action = HelpTopic OR NewSticky      
            
            
            // Also, tack on global settings
            if (SkipGlobals != true) {
                iahelp__IASetIHOrg__c GS = ControllerSettings.getSettings();
                retVal = concatenateJSON(retVal, JSON.serialize(GS));
            }            

            // Also, tack on personal settings - but only if these are being tracked
            if (ControllerSettings.getSettings().TrackDaysLUXOps__c > 0) {
                HelpInteraction__c[] HIs = getPersonalisationInteractions(IHContext);
                retVal = concatenateJSON(retVal, JSON.serialize(HIs));
            }
            
            
            // Also, tack on details of any Community Root (located above)    
            NVP = new NameValuePair('CommunityRoot', 'CommunityRoot', CRoot);
            NVPs.add(NVP);    
                    

            // Also, tack on a marker specifying that an author override is in play, if this is the case
            // and user needs to know this...
            if (AuthorCfgApplied == true && cIHQ.isAuthor == true) {
                NVP = new NameValuePair('AuthorOverrides', 'AuthorOverrides', 'true');
                NVPs.add(NVP);    
            }


            // Also, tack on the actual author config settings - so that client code
            // can respond to it if need be
            if (AuthorCfgParams != '') {
                NVP = new NameValuePair('AuthorOverrides', 'OverrideParams', AuthorCfgParams);
                NVPs.add(NVP);    
            }

            
            // Tack on additional, common settings - if not already got from cache / globals options
            if (SkipGlobals != true) {
                                
                // Also, tack on the name of the portal page in play (may or may not be IHTools, IHToolsLUX etc.)    
                // NB: for now, hard wire the assumption here that SF1 is NOT an option     
                strTemp = '';
                strTemp = ControllerSettings.getPortalPageName(false);        
                NVP = new NameValuePair('PortalPage', 'PortalPage', strTemp);
                NVPs.add(NVP);            

                
                // Also, tack on details of the styles in the custom CSS as a style text block
                strTemp = '';
                ConfigurationItem__c CICustomerCSS = ControllerSettings.getCustomerCSSData();
                
                if (CICustomerCSS != null) {
                    strTemp = CICustomerCSS.SupportingControls__c;
                    
                } else {
                    // Revert to CSS file if no configuration data present
                    try {
                        PageReference P = new PageReference(ControllerSettings.getSettings().BrandCSS__c);
                        strTemp = P.getContent().toString();              
                    } catch (exception ex) {}   
                }
                
                NVP = new NameValuePair('BrandCSS', 'BrandCSS', strTemp);
                NVPs.add(NVP);            
                
                
                // Also tack on internationalisations: note that there is considerable overlap with IHTools
                // (for IHDetail / topic editor) so we include translations for that directly. Ditto Globals

                mapDlgLocs = ServiceLocalisation.getDialogueLocalisations('LUXComponents', false);            
                for (string trans : mapDlgLocs.keyset()) {
                    NVP = new NameValuePair('Internationalisations', trans, mapDlgLocs.get(trans));
                    NVPs.add(NVP);            
                }


                // Set a card title for some special cases
                if (ActionCode == 'CommentsAll' 
                    || ActionCode == 'CommentsHPLs'
                    || ActionCode == 'CommentsRLs'
                    || ActionCode == 'CommentsTopics'
                ){
                    NVP = new NameValuePair('CardTitle', 'Title', mapDlgLocs.get('Title' + ActionCode));    
                    NVPs.add(NVP);  
                }


                mapDlgLocs = null;
                mapDlgLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false);            
                for (string trans : mapDlgLocs.keyset()) {
                    NVP = new NameValuePair('Internationalisations', trans, mapDlgLocs.get(trans));
                    NVPs.add(NVP);            
                }


                // Set a card title for some special cases
                if(ActionCode == 'SearchResources'){
                    NVP = new NameValuePair('CardTitle', 'Title', mapDlgLocs.get('TitleResources'));    
                    NVPs.add(NVP);  
                }
                

                mapDlgLocs = null;
                mapDlgLocs = ServiceLocalisation.getDialogueLocalisations('Branding', false);            
                for (string trans : mapDlgLocs.keyset()) {
                    NVP = new NameValuePair('Internationalisations', trans, mapDlgLocs.get(trans));
                    NVPs.add(NVP);            
                }

                mapDlgLocs = null;
                mapDlgLocs = ServiceLocalisation.getDialogueLocalisations('ClientSide', false);            
                for (string trans : mapDlgLocs.keyset()) {
                    NVP = new NameValuePair('Internationalisations', trans, mapDlgLocs.get(trans));
                    NVPs.add(NVP);            
                }


                // Set a card title for some special cases
                if(ActionCode == 'SearchRelatedHelp'){
                    NVP = new NameValuePair('CardTitle', 'Title', mapDlgLocs.get('[QAMTipRowSearch]')); 
                    NVPs.add(NVP);  
                }

                            
                mapDlgLocs = null;
                mapDlgLocs = ServiceLocalisation.getDialogueLocalisations('iahelp__IHConfirmActions', false);            
                for (string trans : mapDlgLocs.keyset()) {
                    NVP = new NameValuePair('Internationalisations', trans, mapDlgLocs.get(trans));
                    NVPs.add(NVP);            
                }

                mapDlgLocs = null;
                mapDlgLocs = ServiceLocalisation.getDialogueLocalisations('iahelp__IHSearchResults', false);            
                for (string trans : mapDlgLocs.keyset()) {
                    NVP = new NameValuePair('Internationalisations', trans, mapDlgLocs.get(trans));
                    NVPs.add(NVP);            
                }

                mapDlgLocs = null;
                mapDlgLocs = ServiceLocalisation.getDialogueLocalisations('iahelp__IHTools', false);            
                for (string trans : mapDlgLocs.keyset()) {
                    NVP = new NameValuePair('Internationalisations', trans, mapDlgLocs.get(trans));
                    NVPs.add(NVP);            
                }
                
                
                // Also, tack on permissions info
                NVP = new NameValuePair('Permissions', 'isUser', '' + cIHQ.isUser);
                NVPs.add(NVP);            
                
                NVP = new NameValuePair('Permissions', 'isAnalyst', '' + cIHQ.isAnalyst);
                NVPs.add(NVP);            

                NVP = new NameValuePair('Permissions', 'isAuthor', '' + cIHQ.isAuthor);
                NVPs.add(NVP);            

                NVP = new NameValuePair('Permissions', 'isAdministrator', '' + cIHQ.isAdministrator);
                NVPs.add(NVP);            
                

                // Also, tack on session ID: it's up to component whether or not to adopt this copy
                // (usually yes - unless the UniqueIdent member data of the card has already been set)
                String GUID = getGUID();            
                NVP = new NameValuePair('Identifiers', 'UniqueId', GUID);
                NVPs.add(NVP);            

                
                // Also, tack on key object type data
                map<string,string> KnownRecordTypes = getKnownRecordTypes();
                for (string typ : KnownRecordTypes.keySet()) {
                    NVP = new NameValuePair('ConfigToolFilterInfo', typ, KnownRecordTypes.get(typ));
                    NVPs.add(NVP);            
                }
                
            }
            

            // Tack on edition licensing / FMA option info
            try {
                // Edition
                integer iEd = ServiceSubs.getFPIValue('iL2SProductOptions1');
                
                NVP = new NameValuePair('EditionInfo', 'Edition', '' + iEd);
                NVPs.add(NVP);              

                // Is brand suppression allowed
                boolean BSup = ServiceSubs.getFPBValue('bL2SBrandingSuppressPoweredBy');
                
                if (BSup == true) {
                    NVP = new NameValuePair('BrandingInfo', 'BrandSuppressed', 'true');
                    NVPs.add(NVP);              
                }
                
            } catch (exception exc) {}
                                        
            
            // Tack on Vote Options if retrieving a single Help Topic
            if (ActionCode == 'HelpTopic') {
                cH.initialiseVoteOptions();
                
                if (cH.VoteOptions != null) {
                    retVal = concatenateJSON(retVal, JSON.serialize(cH.VoteOptions)); 
                    
                    // Also, tack on details of any last vote cast
                    NVP = new NameValuePair('VoteInfo', 'theVote', cH.theVote);
                    NVPs.add(NVP);            
                }
            }
                /*if(ActionCode == 'checkUserGeolocationAccess'){
                iahelp__IASetIHOrg__c GS = ControllerSettings.getSettings();
                retVal = concatenateJSON(retVal, JSON.serialize(GS));
                
            }*/

            retVal = concatenateJSON(retVal, JSON.serialize(NVPs));

            timeStamps += getTimeStamp() + 'getTools - all other items appended - returning... ';
            NVP = new NameValuePair('PerformanceInfo', 'timeStamps', timeStamps);
            retVal = concatenateJSON(retVal, JSON.serialize(NVP));              
            
            
            Boolean CheckUserGeoLocationAccess = ServiceSecurity.isGeoEnabled();
            NVP = new NameValuePair('Permissions', 'isGeoEnabled', '' + CheckUserGeoLocationAccess);
            NVPs.add(NVP);
            retVal = concatenateJSON(retVal, JSON.serialize(NVPs));
            
        } catch (exception e) {  
            try {             
                retVal = 'Error processing tools: ' + e.getMessage() + ' - Additional diagnostics: ' + localDiags + ' - Server diagnostics: ' + timeStamps;
            } catch (exception ex) {retVal = 'Error processing tools: error in error handler';}            
        }
        
        return retVal;
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Lightning Out support
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    public static string getHookMode() {
        string s = ServiceSecurity.getQueryParameter('HookMode', 2);
        if (s == '1') {
            return '1';
        } else if (s == '2') {
            return '2';
        } else if (s == '3') {
            return '3';
        } else {
            return '0';
        }
    }
    
    public static boolean getHideHeader() {
        string s = ServiceSecurity.getQueryParameter('HideHeader', 2);
        if (s == '') {s = 'true';}
        return s == 'true';
    }
    
    public static boolean getHideSidebar() {
        string s = ServiceSecurity.getQueryParameter('HideSidebar', 2);
        if (s == '') {s = 'true';}
        return s == 'true';
    }

    public static boolean getHideButtons() {
        string s = ServiceSecurity.getQueryParameter('HideButtons', 2);
        if (s == '') {s = 'true';}
        return s == 'true';
    }
    
    public static boolean getEditMode() {
        string s = ServiceSecurity.getQueryParameter('Comp', 2);
        if (s == 'recordEdit') {s = 'true';}
        return s == 'true';
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Tree Support
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    // This method is used to fetch child nodes related to a particular node (i.e., provide Just In Time / JIT fetching):
    // Supply root node (IHContext) plus parameters of: max depth ^ tree provider
    @AuraEnabled
    global static string getSubTree(string IHContext, string Params) {
        
        string retVal = '';
        string[] Ps = Params.split('\\^');
        integer levelsMax = integer.valueOf(Ps[0]);
        ServiceIHLists.TreeNodeSupplier TNS;
        string providerClassName = Ps[1];
        
        
        // Node source depends on context whose tree we're asked to supply and / or specified provider              
        // HERE WE SHOULD USE THE USER-SPECIFIED IMPLEMENTATION, IF SPECIFIED
        // ALLOWING USE OF LOCAL TREE NODE PROVIDERS IF DESIRED...

        if (providerClassName == '' || providerClassName == null || providerClassName + '' == 'undefined') {

            if (IHContext.startsWith(ServiceSchema.getObjectIdByName('iahelp__HelpTopic__c'))) {           
                        
                // v1.50: for help topics, two providers are now available (fixed alpha sorting or user specified order)
                // Use the default provider specified in global settings:
                providerClassName = ControllerSettings.getSettings().DefaultHelpTopicTreeProvider__c;
                        
                    
             } else if (IHContext.startsWith(ServiceSchema.getObjectIdByName('iahelp__HelpReadingList__c'))) {
                        providerClassName = 'ServiceIHTrees.TNSReadingLists';
    
             } else if (IHContext.startsWith(ServiceSchema.getObjectIdByName('iahelp__HelpedPageLayout__c'))) {                
                        providerClassName = 'ServiceIHTrees.TNSHelpedPageLayouts';
             } else {
             // Default to topic provider if topic provider is blank and there's no default root node (IHContext)
             // v1.50: for help topics, two providers are now available (fixed alpha sorting or user specified order)
             // Use the default provider specified in global settings:
                providerClassName = ControllerSettings.getSettings().DefaultHelpTopicTreeProvider__c;
                        
                // Default of last resort
                if (providerClassName == '' || providerClassName + '' == 'null' || providerClassName == null || providerClassName + '' == 'undefined') {
                        providerClassName = 'ServiceIHTrees.TNSHelpTopics';
                }
             }
        } 
        
        try {
            Type t = Type.forName(providerClassName); 
            TNS = (ServiceIHLists.TreeNodeSupplier)t.newInstance(); 
            List<ServiceIHLists.ListingItem> LIs = new List<ServiceIHLists.ListingItem> ();
            LIs = TNS.getTreeNodes(IHContext, levelsMax);
            retVal = JSON.serialize(LIs);
            
            for(ServiceIHLists.ListingItem l : LIs) {
                system.debug('l==>'+l);
            }

        } catch (exception e){ 
            system.debug(' getSubTree - Error occured: ' + e);
            retVal = '';
        }
        
        return retVal;
    }

    
    // Get the root help topic ID for a given help context, as derived from helped page layout / element data:
    // IHContext passed in is assumed to be a record ID or a client-side identified object / page name - not a full path
    @AuraEnabled
    global static string getRootTopicForContext (string IHContext) {
        
        string retVal = '';
        string SFO;
        ControllerSettings cS;
        HelpedPageLayout__c HPL;
        HelpedElement__c[] candidateHEs;
        HelpedElement__c[] HEs;
        string RootIdentifier = 'ContextTreeRoot';
        
        try {
            // Get the identifier for the context received
            cS = new ControllerSettings();
            SFO = cS.SFObjId(URL.getOrgDomainURL().toExternalForm() + '/' + IHContext);
            
            if (SFO != 'Err!') {                
                // Get the helped page layout for this identifier
                HPL = [SELECT Id FROM HelpedPageLayout__c WHERE PageLayoutIdentifier__c = :SFO];

                // Get any context root elements for this layout:
                // If there's more than 1, apply DDF...
                candidateHEs = [SELECT Id, Identifier__c, HelpFilter__c, DataDrivenFilter__c, UseForNew__c, HelpTopic__c FROM HelpedElement__c WHERE HelpedPageLayout__c = :HPL.Id AND Identifier__c = :RootIdentifier];
                HEs = ControllerSettings.getDDFMatches(IHContext, candidateHEs);
                
                if (HEs.size() == 1) {
                    retVal = HEs[0].HelpTopic__c;   
                } else {
                    retVal = '';
                }
            }
            
            
        } catch (exception e) {
            // On failure, return no root
            retVal = '';
        }
        
        return retVal;
    }    
    
    
    // Get direct descendents of a given tree node
    @AuraEnabled
    global static string treeGetChildNodes (string Node, string Provider) {
        
        string retVal = '';
        Schema.DescribeSObjectResult sObj;
        Map<String, Schema.SObjectField> FMap;          
        Schema.DescribeFieldResult Fld;
        ServiceSchema svsS = new ServiceSchema();
        ServiceIHLists.ListingItem[] LIs = new ServiceIHLists.ListingItem[]{};
        ServiceIHLists.ListingItem LI;
        
        try {
            
            // Currently, only available for schema provider
            if (Provider == 'ServiceIHTrees.TNSOrgSchema') {
                
                // Get the object implied by the node                
                // For the object, add its fields
                sObj = svsS.getObjectDetails(Node);
                FMap = sObj.Fields.getMap();
                        
                for (string FKey : FMap.keySet()){   
                    
                    Fld = FMap.get(FKey).getDescribe();
                    LI = new ServiceIHLists.ListingItem();
                                
                    LI.Label = Fld.getLabel() + ' (' + Fld.getName() + ')';
                    LI.Title = '';
                    LI.ActionCode = '';
                    LI.Icon = 'fa-bars';
                    LI.IconLabel = '';
                    LI.IconTitle = '';
                    LI.Parameters = Node;         
                    LI.StyleClass = '';
                    LI.Id = '' + FKey;
                    LI.RowState = '';           
            
                    LIs.add(LI);
                }   
                            
            } else {

                // Get children applicable to clicked node type
                string[] keyTypes = ControllerSettings.getSettings().SFObjectIds__c.split('\\^');
                
                // Known types:
                // 0 = Topics
                // 1 = RLs
                // 2 = Resources
                // 3 = Topic templates
                // 4 = Signatures
                // 5 = Help vote sets
                // 6 = Interactions

                if (keyTypes[0] != 'ERR!') {
                    
                    if (Node.startsWith(keyTypes[0])) {     
                        // We have a topic: return related resources        
                        for (HelpTopicResource__c HTR : [SELECT Id, UsageNotes__c, HelpResource__c, HelpResource__r.Name 
                                                            FROM HelpTopicResource__c 
                                                            WHERE HelpTopic__c = :Node]) {
                
                            LI = new ServiceIHLists.ListingItem();
                                        
                            LI.Label = HTR.HelpResource__r.Name;
                            LI.Title = HTR.UsageNotes__c;
                            LI.ActionCode = 'TreeGetChildNodes';
                            LI.Icon = 'fa-map-signs';
                            LI.IconLabel = '';
                            LI.IconTitle = '';
                            LI.Parameters = Node;         
                            LI.StyleClass = '';
                            LI.Id = HTR.HelpResource__c;
                            LI.RowState = '';           
                    
                            LIs.add(LI);                            
                        }
                        
                        // Also return RLs
                        ControllerHelpContent cH = new ControllerHelpContent();
                        cH.THelpId = Node;
                        cH.getHelp();
                        List<ServiceIHLists.ListingItem> ChildLIs;

                        ServiceIHLists.TreeNodeSupplier TNSRLs = new ServiceIHTrees.TNSReadingLists();
                        
                        for (ServiceIHLists.ReadingList RL : cH.ReadingLists) {
                            // For each reading list, use RL node supplier to get its entries
                            ChildLIs = TNSRLs.getTreeNodes(RL.RLID, 0);
                            
                            // Amend the 'root' node to make it a child of the requesting node
                            ChildLIs.remove(0);
                            ChildLIs[0].Parameters = Node;
                            
                            // Add the reading list and its nodes to our output
                            LIs.addAll(ChildLIs);
                        }
                        
                        
                        // Also return HPLs
                        ServiceIHLists.TreeNodeSupplier TNSHPLs = new ServiceIHTrees.TNSHelpedPageLayouts();
                        
                        for (HelpedElement__c HE : [SELECT Id
                                                        FROM HelpedElement__c
                                                        WHERE HelpTopic__c = :Node]) {
                            // For each reading list, use RL node supplier to get its entries
                            ChildLIs = TNSHPLs.getTreeNodes(HE.Id, 0);
                            
                            // Amend the 'root' node to make it a child of the requesting node
                            ChildLIs[0].Parameters = Node;
                            
                            // Add the reading list and its nodes to our output
                            LIs.addAll(ChildLIs);
                        }
                        
                        
                        
                        
                    } else if (Node.startsWith(keyTypes[1])) {
                        // We have a RL: return its RLE topics:
                        // Use RL tree provider to do this
                        ServiceIHLists.TreeNodeSupplier TNSRLs = new ServiceIHTrees.TNSReadingLists();                  
                        LIs = TNSRLs.getTreeNodes(Node, 0);
                            
                        // Amend the 'root' node to make it a child of the requesting node
                        LIs[0].Parameters = Node;
                                            
                        
                    } else if (Node.startsWith(keyTypes[2])) {
                        // We have a resource: return related topics                        
                        for (HelpTopicResource__c HTR : [SELECT Id, HelpTopic__c, HelpTopic__r.Name, HelpTopic__r.Summary__c 
                                                            FROM HelpTopicResource__c 
                                                            WHERE HelpResource__c = :Node
                                                            LIMIT 50]) {
                
                            LI = new ServiceIHLists.ListingItem();
                                        
                            LI.Label = HTR.HelpTopic__r.Name;
                            LI.Title = HTR.HelpTopic__r.Summary__c;
                            LI.ActionCode = 'TreeGetChildNodes';
                            LI.Icon = 'fa-question';
                            LI.IconLabel = '';
                            LI.IconTitle = '';
                            LI.Parameters = Node;         
                            LI.StyleClass = '';
                            LI.Id = HTR.HelpTopic__c;
                            LI.RowState = '';           
                    
                            LIs.add(LI);                            
                        }   
                            
                    } else {
                        // Unknown node type
                        retVal = 'Error (treeGetChildNodes): unknown node type (' + Node + ')';         
                    }
                } else {
                    // Types error
                    retVal = 'Error (treeGetChildNodes): unable to obtain node type information';         
                }               
            }
            
            
            // Return nodes (listing items) unless an error has been set
            if (retVal == '') {retVal = JSON.serialize(LIs);}
            
        } catch (exception e) {
            retVal = 'Unexpected error (treeGetChildNodes): (' + Provider  + ': ' + Node + ') ' + e.getMessage();         
        }
        
        return retVal;
    }
    
    
    // Obtain object three letter code information together with tool bit numbers
    // applicable to them, for use when filtering configuration items
    public static map<string,string> getKnownRecordTypes() {
        
        map<string,string> retVal = new map<string,string>();
        
        try {
    
            string typeCode;
            
            // Config tools are marked with a "tool filter" integer value.
            // Translated to a binary string, this provides a set of bit switches of the types to which they're applicable.
            // Here, we record the object ID codes for these types (which listing rows should have in their IDs)
            // against the relevant bits. 
            // E.g., if Bit 2 is "on" (1) in the binary version of the config tool's filter, it is applicable to bookmarks.
        
            typeCode = ServiceSchema.getObjectIdByName('iahelp__HelpTopic__c');
            retVal.put('1', typeCode);      // Topics
            
            typeCode = ServiceSchema.getObjectIdByName('iahelp__HelpBookmark__c');
            retVal.put('2', typeCode);      // Bookmarks
            
            typeCode = ServiceSchema.getObjectIdByName('iahelp__HelpReadingList__c');
            retVal.put('3', typeCode);      // RLs OR RLEs
            
            typeCode = ServiceSchema.getObjectIdByName('iahelp__HelpTopicResource__c');
            retVal.put('4', typeCode);      // HTRs
            
            typeCode = ServiceSchema.getObjectIdByName('iahelp__HelpRelationship__c');
            retVal.put('5', typeCode);      // Rels

/*
            typeCode = ServiceSchema.getObjectIdByName('__c');
            retVal.put('6', typeCode);      // Search results
            
            typeCode = ServiceSchema.getObjectIdByName('__c');
            retVal.put('7', typeCode);      // Stickies
                    
            typeCode = ServiceSchema.getObjectIdByName('__c');
            retVal.put('8', typeCode);      // Guides
*/        

            typeCode = ServiceSchema.getObjectIdByName('iahelp__HelpedElement__c');
            retVal.put('9', typeCode);      // Helped elements
            
            typeCode = ServiceSchema.getObjectIdByName('iahelp__HelpedPageLayout__c');
            retVal.put('10', typeCode);      // HPLs
            
            typeCode = ServiceSchema.getObjectIdByName('iahelp__HelpFilter__c');
            retVal.put('11', typeCode);      // Help Filters
            
            typeCode = ServiceSchema.getObjectIdByName('iahelp__HelpFilterCriterion__c');
            retVal.put('12', typeCode);      // Help filter criteria

            typeCode = ServiceSchema.getObjectIdByName('iahelp__HelpResource__c');
            retVal.put('13', typeCode);      // Help resources
            
        } catch (exception e) {}
        
        return retVal;
    }

        
    // Move a node's position on a tree - by amending its parent Help Relationship
    @AuraEnabled
    global static string reparentTreeNode(string OldReferring, string NewReferring, string Related) {

        string retVal = '';
        string relType;
        SemanticTag__c sTag;
        boolean[] perms;
        ServiceSecurity sS = new ServiceSecurity();
        map<string,string> mapGlbLocs;
        
        
        try {
            // Check permissions
            perms = sS.UserPermissions();
            mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false);
            
            // Operation available to Authors+ only
            if (perms[1] == true) {

                // Locate the ID value for the "parent"-type semantic tag / relationship type
                sTag = [SELECT Id FROM SemanticTag__c WHERE Name = 'Parent'];
    
                // Armed with this, locate the relationship that defines the current position of the given node on the tree
                HelpRelationship__c HR = [SELECT Id FROM HelpRelationship__c
                                            WHERE ReferringTopic__c = :oldReferring
                                            AND RelatedHelpTopic__c = :Related
                                            AND SemanticTag__c = :sTag.Id];
        
                // To effect the move, we must delete the existing relationship and insert a new one
                delete HR;
                
                retVal = 'Existing relationship deleted - proceeding to create new parent relationship... ';
                
                HR = new HelpRelationship__c();
                HR.ReferringTopic__c = NewReferring;
                HR.RelatedHelpTopic__c = Related;
                HR.SemanticTag__c = sTag.Id;
                insert HR;
                
                retVal = '';
                
            } else {
                retVal = mapGlbLocs.get('MessageNoRights');
            }
            
        } catch (exception e) {
            retVal += 'Error amending Tree Node Parent: ' + e.getMessage() + ' - Diagnostics: Old: ' + OldReferring + ' New: ' + NewReferring + ' Related: ' + Related;
        }
        
        return retVal;
        
    }
    

    // Move a node's order on a tree - by amending its parent Help Relationship    
    @AuraEnabled
    global static string reOrderTreeNodes (string OldReferring, string NewReferring, string Related, integer pos) {
        
        string retVal;
        list<HelpRelationship__c> HRs;
        boolean[] perms;        
        ServiceSecurity sS = new ServiceSecurity();
        map<string,string> mapGlbLocs;
        
        
        try {
            // Check permissions
            perms = sS.UserPermissions();
            mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false);
            
            // Operation available to Authors+ only
            if (perms[1] == true) {
        
        
                if(OldReferring != NewReferring){
                    string ret = ControllerLUXOps.reparentTreeNode(OldReferring, NewReferring, Related);
                    if(ret!=''){
                        return ret;
                    }
                }   
                    
                // Locate the ID value for the "parent"-type semantic tag / relationship type
                SemanticTag__c sTag = [SELECT Id FROM SemanticTag__c WHERE Name = 'Parent'];
            
                // Armed with this, locate all children of the new parent proposed for the moving node
                HRs = [SELECT Id, RelatedHelpTopic__c,ReferringTopic__c,RelatedHelpTopic__r.name,SemanticTag__c,Order__c FROM HelpRelationship__c
                                                    WHERE ReferringTopic__c = :NewReferring
                                                    AND SemanticTag__c = :sTag.Id ORDER BY RelatedHelpTopic__r.name];
                
                if (pos!=null) {
                    
                    list<HelpRelationship__c> newHRs = new list<HelpRelationship__c>();
                    integer nullcount=0;
                    for(HelpRelationship__c HR : HRs){
                        if(HR.Order__c==null){
                            HR.Order__c = nullcount;
                            nullcount++;
                        }
                        if(pos <= HR.Order__c && HR.RelatedHelpTopic__c != Related ){
                            HR.Order__c = HR.Order__c + 1;
                            newHRs.add(HR);
                        }
                        if(HR.RelatedHelpTopic__c == Related ){
                            HR.Order__c = pos;
                            newHRs.add(HR);
                        }
                    }
                    if(newHRs.size()>0){
                       update newHRs;
                    }
                
                    //reassign order values to help relationship records
                    HRs = [SELECT Id, RelatedHelpTopic__c,ReferringTopic__c,RelatedHelpTopic__r.name,SemanticTag__c,Order__c FROM HelpRelationship__c
                                                        WHERE ReferringTopic__c = :NewReferring
                                                        AND SemanticTag__c = :sTag.Id ORDER BY Order__c ASC];
                    list<HelpRelationship__c> newHRs2 = new list<HelpRelationship__c>();
                        integer counter=0;
                    for(HelpRelationship__c HR : HRs){
                        HR.Order__c = counter;
                        newHRs2.add(HR);
                        counter++;
                    }
                    if(newHRs2.size()>0){
                       update newHRs2;
                    }
                }
                retVal = '';
                
            } else {
                retVal = mapGlbLocs.get('MessageNoRights');             
            }
            
        } catch (exception e) {
            retVal += 'Error amending Tree Node Order: ' + e.getMessage() + ' - Diagnostics: Old: ' + OldReferring + ' New: ' + NewReferring + ' Related: ' + Related + ' Order: ' + pos;
        } 
        
        return retVal;
    }   
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Related list maintenance
    /////////////////////////////////////////////////////////////////////////////////////////////////////


     
    // Set usage notes for a newly created and related help topic resource:
    // Return empty string on success or error message on issue
    @AuraEnabled
    global static string setUsageNotesForNewHTR(string HTID, string HRID) {
        
        string retVal = '';
        boolean[] perms;
        ServiceSecurity sS = new ServiceSecurity();
        map<string,string> mapGlbLocs;

        
        try {
            // Check permissions
            perms = sS.UserPermissions();
            mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false); 
            
            // Operation available to Authors+ only
            if (perms[1] == true) {
                
                // Locate the Help Topic Resource record
                HelpTopicResource__c HTR = [
                        SELECT Id, HelpResource__r.Summary__c, UsageNotes__c
                        FROM HelpTopicResource__c
                        WHERE HelpTopic__c = :HTID
                        AND HelpResource__c = :HRID
                        LIMIT 1
                        ];
                
                HTR.UsageNotes__c = HTR.HelpResource__r.Summary__c;
                update HTR;

                retVal = '';
                
            } else {
                retVal = mapGlbLocs.get('MessageNoRights');
            }
                        
        } catch (exception e) {
            retVal = mapGlbLocs.get('MessageGenericError') + ': ' + e.getMessage();
        }
        
        return retVal;
        
    }
    
     
    // Delete a Help Relationship to order - e.g., for a peer or child tree node
    @AuraEnabled
    global static string deleteRelationship(string Referring, string Related, string RelationType) {

        string retVal = '';
        string relType;
        SemanticTag__c sTag;
        boolean[] perms;
        ServiceSecurity sS = new ServiceSecurity();
        map<string,string> mapGlbLocs;

        
        try {
            // Check permissions
            perms = sS.UserPermissions();
            mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false); 
            
            // Operation available to Authors+ only
            if (perms[1] == true) {
                
                sTag = [SELECT Id FROM SemanticTag__c WHERE Name = :RelationType];
                HelpRelationship__c HR;
                
                // If incoming relationship type is "Relative", we need to deal with the fact that
                // this is the default and (in the past) may not have been set, with a blank
                // relationship type equating to this
                if (RelationType == 'Relative') {
                    HR = [SELECT Id FROM HelpRelationship__c
                                                WHERE ReferringTopic__c = :Referring
                                                AND RelatedHelpTopic__c = :Related
                                                AND (SemanticTag__c = :sTag.Id
                                                OR SemanticTagIsBlank__c = true)];
                    
                } else {
                    HR = [SELECT Id FROM HelpRelationship__c
                                                WHERE ReferringTopic__c = :Referring
                                                AND RelatedHelpTopic__c = :Related
                                                AND SemanticTag__c = :sTag.Id];
                }
    
                
                delete HR;
                retVal = 'Relationship deleted';
                
            } else {
                retVal = mapGlbLocs.get('MessageNoRights');
            }
                        
        } catch (exception e) {
            retVal = mapGlbLocs.get('MessageGenericError') + ': ' + e.getMessage() + ' - Ref: ' + Referring + ' - Rel: ' + Related;
        }
        
        return retVal;
        
    }
    
        
    // Create a relationship to order - e.g., for a peer or child tree node:
    // NOTE: "Relationship" can mean Help Relationship (if parent and child are topics)
    // OR other types (e.g., a reading list entry if parent is a reading list)
    @AuraEnabled
    global static string createRelationship(string Referring, string Related, string RelationType) {
        
        string retVal = '';
        string relType;
        SemanticTag__c sTag;
        boolean[] perms;
        ServiceSecurity sS = new ServiceSecurity();
        map<string,string> mapGlbLocs;
        map<string,string> KnownRecordTypes = getKnownRecordTypes();

        
        try {
            // Check permissions
            perms = sS.UserPermissions();
            mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false); 
            
            // Operation available to Authors+ only
            if (perms[1] == true) {
                
                // Nature of the relationship to create depends on referring (parent) record type
                if (Referring.substring(0,3) == KnownRecordTypes.get('3')) {
                    // Parent is a reading list: add an entry to the end of the reading list representing child
                    
                    HelpReadingListEntry__c[] RLEs = [SELECT Id from HelpReadingListEntry__c WHERE HelpReadingList__c = :Referring]; 
                    HelpReadingListEntry__c RLE = new HelpReadingListEntry__c();
                    
                    RLE.HelpReadingList__c = Referring;
                    RLE.HelpTopic__c = Related;
                    RLE.ReadingOrder__c = RLEs.size();
                    
                    insert RLE;
                    retVal = RLE.Id;
                    
                } else {  
                    // Parent is assumed to be a help topic: add a helpl relationship           
                    HelpRelationship__c HR = new HelpRelationship__c();
                    HR.ReferringTopic__c = Referring;
                    HR.RelatedHelpTopic__c = Related;
                    
                    sTag = [SELECT Id FROM SemanticTag__c WHERE Name = :RelationType];
                    HR.SemanticTag__c = sTag.Id;
                    
                    insert HR;
                    retVal = HR.Id;
                }
                
            } else {
                retVal = mapGlbLocs.get('MessageNoRights');
            }
        } catch (exception e) {
            retVal = e.getMessage();
        }
        
        return retVal;
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Crumb support
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    // Class allowing listing items to be grouped into crumb trails, so they can be JSON marshalled to crumb component
    public class CrumbTrail {
        public ServiceIHLists.ListingItem[] Crumbs;
        
        public CrumbTrail(ServiceIHLists.ListingItem[] LIs) {
            this.Crumbs = LIs;
        }
        
        public CrumbTrail() {}
    }
    

    // Get "paths" to "top" parent node for a given record
    @AuraEnabled
    global static string getCrumbs(string HelpRecordId) {
        
        string retVal;
        CrumbTrail[] CTs = new CrumbTrail[]{};
        CrumbTrail CT;
        List<ServiceIHLists.ListingItem> LIs;
        List<ServiceIHLists.ListingItem> LIsOrdered;
        ServiceIHLists.ListingItem LI;
        integer i;
        HelpRelationship__c[] HRs = new HelpRelationship__c[]{};
        HelpRelationship__c HR;        
        string parentId = '';
        string lastChildTopic = '';
        HelpRelationship__c topRel = null;
        
        // Control var noting whether at least 1 parent of record passed in existed
        boolean loneRecord = true;                  
        
        try {
            // Get all parents of the record passed in          
            for (HelpRelationship__c Parent : [SELECT ReferringTopic__c, ReferringTopic__r.Name, ReferringTopic__r.Summary__c, 
                                RelatedHelpTopic__c, RelatedHelpTopic__r.Name, RelatedHelpTopic__r.Summary__c
                            FROM HelpRelationship__c
                            WHERE RelatedHelpTopic__c = :HelpRecordId
                            AND SemanticTag__r.Name = 'Parent']) {
                                
                // If we've entered this loop, at least one parent exists, so note this
                loneRecord = false;
                                                
                // For each parent, we'll add a crumb trail:
                // Before doing this, get all that trail's crumbs
                LIs = new List<ServiceIHLists.ListingItem> ();
                parentId = Parent.ReferringTopic__c;
                                

                // At the first level up the crumb trail, add an item for the node represented by incoming record itself
                LI = new ServiceIHLists.ListingItem();
                LI.Id = Parent.RelatedHelpTopic__c;
                LI.Label = Parent.RelatedHelpTopic__r.Name;                        
                LI.Title = Parent.RelatedHelpTopic__r.Summary__c;                     
                LIs.add(LI);

                // Add the current parent
                LI = new ServiceIHLists.ListingItem();
                LI.Id = Parent.ReferringTopic__c;
                LI.Label = Parent.ReferringTopic__r.Name;                        
                LI.Title = Parent.ReferringTopic__r.Summary__c;                     
                LIs.add(LI);

                do {
                    
                    // Now seek parent's parents
                    try {

                        HRs = [SELECT ReferringTopic__c, ReferringTopic__r.Name, ReferringTopic__r.Summary__c, 
                                RelatedHelpTopic__c, RelatedHelpTopic__r.Name, RelatedHelpTopic__r.Summary__c
                            FROM HelpRelationship__c
                            WHERE RelatedHelpTopic__c = :parentId
                            AND SemanticTag__r.Name = 'Parent'
                            ];

                        // Add the current parent
                        LI = new ServiceIHLists.ListingItem();
                        
                        if (HRs.size() > 1) {
                            // Indicate multiple paths and 'force' further investigation on any click
                            // by effectively requesting path from affected child 
                            
                            LI.Id = parentId;
                            LI.Label = '[...]';   
                            
                            LI.Title = '';
                            for (HelpRelationship__c Rel : HRs) {
                                LI.Title += Rel.ReferringTopic__r.Name + ', ';
                            }
                            LI.Title = LI.Title.substring(0, LI.Title.length() - 2);
                            LI.Title += '...';
                                                 
                            LIs.add(LI);
                            
                            // Force stop here...
                            parentId = '';
                            
                            
                        } else {
                            // Carry on as normal
                            LI.Id = HR.ReferringTopic__c;
                            LI.Label = HR.ReferringTopic__r.Name;                        
                            LI.Title = HR.ReferringTopic__r.Summary__c;                     
                            LIs.add(LI);
                            
                            parentId = HR.ReferringTopic__c;
                        }


                        
                    } catch (exception ex) {
                        parentId = '';
                    }               
                
                } while (parentId != '' && parentId != null);
                                
                // Listing items will be in the reverse order to that needed, so correct that here:
                LIsOrdered = new List<ServiceIHLists.ListingItem> ();
                for (i = LIs.size() -1; i>=0; i--) {
                    LIsOrdered.add(LIs[i]);
                }
                                
                CT = new CrumbTrail(LIsOrdered);
                CTs.add(CT);
                                
            }
            
            
            // If we were passed an 'orphan' record / top of a crumb trail / record with no parent,
            // we should return a trail containing just the record passed in (a trail with a single crumb)
            if (loneRecord == true) {
                LIsOrdered = new List<ServiceIHLists.ListingItem> ();
                
                LI = new ServiceIHLists.ListingItem();
                
                LI.Id = HelpRecordId;
                
                // Retrieve this topic's name and summary
                try {
                    HelpTopic__c HT = [SELECT Name, Summary__c FROM HelpTopic__c WHERE Id = :HelpRecordId];
                    LI.Label = HT.Name;                        
                    LI.Title = HT.Summary__c;                                     
                    
                } catch (exception ex) {
                    // If retrieval fails, note this in the crumb returned
                    LI.Label = 'Err!';                        
                    LI.Title = 'Topic "' + HelpRecordId + '" not found: ' + ex.getMessage();                                     
                }
                                
                LIsOrdered.add(LI);
                CT = new CrumbTrail(LIsOrdered);
                CTs.add(CT);
            }
            
            retVal = JSON.serialize(CTs);
            
        } catch (exception e) {
            retVal = 'Error processing crumbs - ' + e.getMessage();
        }
        
        return retVal;
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Drag & Drop Ops
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    
    // Create a new topic from a D&D operation
    @AuraEnabled
    global static string dropNewTopic(string TopicContent) {
        string retVal;
        string TInfo = '';
        string[] TWords;
        integer i = 0;
        
        try {
            // Permissions required - Author +
            ServiceSecurity Security = new ServiceSecurity(); 
            Boolean[] Perms = Security.UserPermissions();
            
            if (! Perms[1] && ! Perms[2]) {
                map<string, string> mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false);
                retVal = mapGlbLocs.get('MessageNoRights');
                
            } else {
                ControllerHelpContent cH = new ControllerHelpContent(true);
    
                // Create a new topic, set its description to the content supplied and save it...
                HelpTopic__c HT = cH.getDefaultHelpTopic();
                HT.Description__c = TopicContent;
                
                // Set topic name to first few words, if supplied
                // If supplied text is blank, leave as is...
                if (TopicContent != '') {
                
                    TWords = TopicContent.split(' ');
                    while (TInfo.length() < 60 && TInfo.indexOf('. ') == -1 && i <= TWords.size() - 1) {
                        TInfo += TWords[i] + ' ';
                        i++;
                    }
                    if (TInfo.length() > 80) {
                        TInfo = TInfo.subString(0, 80);
                    }
                    HT.Name = TInfo;
                }
                
                // Set Topic summary to something based on the supplied text:
                // If supplied text is blank, leave as is...
                if (TopicContent != '') {
                    
                    TInfo = TopicContent;
                    while (TInfo.indexOf('  ') != -1) {
                        TInfo = TInfo.replace('  ', ' ');
                    }
                    if (TInfo.length() > 255) {
                        TInfo = TInfo.subString(0, 254);
                    }
                    HT.Summary__c = TInfo;
                }
                
                insert HT;
                retVal = HT.Id;                         
            }
            
        } catch (exception e) {
            retVal = 'Error (dropNewTopic): ' + e.getMessage();
        }
        
        return retVal;
    }
    
    
    // Get details of a dropped object from its ID
    @AuraEnabled 
    global static string getDroppedDetails (string dropId) {
        string retVal;
        
        try {
            
            // Details depend on object type: get known types from settings
            string[] SFObjIds = ControllerSettings.getSFObjectIds().split('\\^');
            
            // Return value should be ID code for:
            // Topics, RL, Resource, Template, Signature, VoteSet, Interaction
            
            if (dropId.substring(0,3) == SFObjIds[0]) {
                HelpTopic__c HT = [SELECT Id, Name FROM HelpTopic__c WHERE Id=:dropId];             
                retVal = HT.Name;
            } else {
                retVal = dropId.substring(0,4) + ': ' + SFObjIds[0];
            }
                                     
        } catch (exception e) {
            retVal = 'Error (getDroppedDetails): ' + e.getMessage();
        }
        
        return retVal;
        
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Schema and metadata ops
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    
    
    // Get the name of an object from its record ID (wrapper to schema methods)
    @AuraEnabled
    global static string getObjectName(string RecordId) {
        string retVal;
        
        try {
            ServiceSchema svsS = new ServiceSchema();
            Schema.DescribeSObjectResult obj = svsS.getObjectDetails(RecordId.substring(0,3));
            retVal = obj.getLocalName();
            
        } catch (exception e) {
            retVal = '';
        }
        
        return retVal;
    }
    
    
    // Return the default record type ID for a given object type
    @AuraEnabled 
    global static string getDefaultRecordTypeId (string ObjectAPIName) {
        
        string retVal = 'NULL';
        
        try {
            Schema.DescribeSObjectResult obj;
            obj = ServiceSchema.getObjectDetailsByName(ObjectAPIName);
    
            List<Schema.RecordTypeInfo> RTIs;
            RTIs = obj.getRecordTypeInfos();
    
            for (Schema.RecordTypeInfo R : RTIs) {
                if (R.isDefaultRecordTypeMapping() == true) {
                    retVal = R.getRecordTypeId();
                }
            }
            
            
            // Check for 'master' record type ID - which in fact means no record type is in play
            // (but SFDC make it look like it is!!)
            if (retVal == '012000000000000AAA') {
                retVal = '';
            }
            
        } catch (exception e) {}
        
        return retVal;
    
    }
    
    
    // Return the record type ID value for a given record, if any, given its schema object
    public static string getRecordTypeId (string RecordId, Schema.DescribeSObjectResult obj) {
        
        string RTyp;
        List<Schema.RecordTypeInfo> RTIs;
        string strSOQL;
        sObject rec;
        
        RTyp = 'NULL';
        
        // Derive object from record ID: we should have been supplied with this, if not a record type
        if (obj != null) {
            
            RTIs = obj.getRecordTypeInfos();
            
            if (RTIs.size() > 1) {              
                // Record types are in play: query to get the type in play for the current record
                try {
                    strSOQL = 'SELECT RecordTypeId FROM ' + obj.getName() + ' WHERE Id=\'' + RecordId + '\'';
                    rec = database.query(strSOQL);
                    
                    RTyp = (string) rec.get('RecordTypeId');
                    RTyp = RTyp.substring(0, 15);
                    
                } catch (exception ex) {}
                
            } else {
                // Only a single record type (Master) is in play
            }
        }

        // Conduct a final check on record type: if, for any reason, it is null
        // make sure we return it as a string - to avoid JSON parser issues
        if (RTyp == null) {
            RTyp = 'NULL';
        }
    
        return RTyp;
    }
    
    
    // Get (custom) object information for a given record from its record ID (API name plus TableEnumOrId for custom objects)   
    // RETURNS NVPs as follows:
    // CustomObjectAPIName
    // CustomObjectId - if record ID is that of a custom object 
    // RecordTypeId
    
    @AuraEnabled
    global static string getObjectInfo(string RecordId) {

        string retVal;
        string objId;
        ServiceSchema sS = new ServiceSchema();
        Schema.DescribeSObjectResult obj;       
        NameValuePair NVP;
        
        try {
            
            if (RecordId != '' && RecordId != null) {
                if (RecordId.length() > 2) {
                    objId = RecordId.subString(0,3);
                    obj = sS.getObjectDetails(objId);
                }
            }
            
            // If we're dealing with a custom object, include its object ID, as this will be
            // the "TableEnumOrId" to seek in layout metadata
            if (obj != null) {
    
                NVP = new NameValuePair('LayoutSearchKeys', 'CustomObjectAPIName',  obj.getName());
                retVal = concatenateJSON(retVal, JSON.serialize(NVP));
    
                if (obj.getName().endsWith('__c')) {
                    
                    // As elsewhere when looking for layout metadata, we cannot engage in queries from a LUX 
                    // endpoint, so we need to locate this data in pre-obtained list of custom objects and their IDs...
                    // Note that we must call this with the object name minus namespace...
                    string CustomObjects = ControllerSettings.getStoredMetadata('GetCustomObjectMetadata');
                    string CustomObjectId = ServiceSchema.getCustomObjectIdFromJSON(obj.getName(), CustomObjects);
            
                    NVP = new NameValuePair('LayoutSearchKeys', 'CustomObjectId',  CustomObjectId);
                    retVal = concatenateJSON(retVal, JSON.serialize(NVP));  
                }
            }

            // Tack on record type            
            string RTyp = getRecordTypeId (RecordId, obj);       
            NVP = new NameValuePair('LayoutSearchKeys', 'RecordTypeId',  RTyp);
            retVal = concatenateJSON(retVal, JSON.serialize(NVP));
                            
        } catch (exception e) {
            retVal = 'Error (Get Object Info): ' + e.getMessage();
        }
        
        return retVal;
        
    }
        
    
    // Get stored JSON of SF layout info for a specified record and record type 
    // RETURNS NVPs as follows:
    // UserProfile
    // RecordTypeId
    // CustomObjectAPIName
    // CustomObjectId - if record ID is that of a custom object 
    // Internationalisations
    // THEN:
    // Returns layout metadata from cache
    
    @AuraEnabled
    global static string getStoredProfileLayouts(string RecordTypeId, string RecordId, string ObjectName) {
        
        string retVal;
        NameValuePair NVP;
        string RTyp;
        string DefaultRTyp;
        string objId;
        ServiceSchema sS = new ServiceSchema();
        Schema.DescribeSObjectResult obj;
        
        // In providing layout data, we'll also need to tack on knowledge of:
        //      - Current user's profile
        //      - Record type, where relevant
        //      - Internationalisations, in case of errors...
        
        
        // PROFILE
        NVP = new NameValuePair('LayoutSearchKeys', 'UserProfile',  userinfo.getProfileId().subString(0,15));
        retVal = JSON.serialize(NVP);        
        
        
        if (RecordId != '' && RecordId != null) {
            // If we have a record ID, use that to get object details
            if (RecordId.length() > 2) {
                objId = RecordId.subString(0,3);
                obj = sS.getObjectDetails(objId);
            }
            
        } else {
            // Otherwise, use the object name we were given
            obj = ServiceSchema.getObjectDetailsByName(ObjectName);
        }
        
        
        // RECORD TYPE        
        if (RecordTypeId != '' && RecordTypeId != null && RecordTypeId + '' != 'null') {
            // We should keep incoming record type if we were given it, returning it as is:
            RTyp = RecordTypeId;
            
        } else {
            // IF THIS WAS EMPTY CHECK WHETHER OBJECT TYPE HAS A RECORD TYPE AND GET IT FOR THE SPECIFIED RECORD:
            // This will return "NULL" if there are no types or no record is supplied
            RTyp = getRecordTypeId (RecordId, obj);                      
        }
               
        NVP = new NameValuePair('LayoutSearchKeys', 'RecordTypeId',  RTyp);
        retVal = concatenateJSON(retVal, JSON.serialize(NVP));
        
        
        // In case it should be needed, tack on default record type ID of the current object
        // (in addition to that located above applicable to the current record, if known)
        DefaultRTyp = getDefaultRecordTypeId(ObjectName);
        NVP = new NameValuePair('LayoutSearchKeys', 'DefaultRecordTypeId',  DefaultRTyp);
        retVal = concatenateJSON(retVal, JSON.serialize(NVP));
        

        // If we're dealing with a custom object, include its object ID, as this will be
        // the "TableEnumOrId" to seek in layout metadata
        
        if (obj != null) {

            NVP = new NameValuePair('LayoutSearchKeys', 'CustomObjectAPIName',  obj.getName());
            retVal = concatenateJSON(retVal, JSON.serialize(NVP));

            if (obj.getName().endsWith('__c')) {
                
                // As elsewhere when looking for layout metadata, we cannot engage in queries from a LUX 
                // endpoint, so we need to locate this data in pre-obtained list of custom objects and their IDs...
                // Note that we must call this with the object name minus namespace...
                string CustomObjects = ControllerSettings.getStoredMetadata('GetCustomObjectMetadata');
                string CustomObjectId = ServiceSchema.getCustomObjectIdFromJSON(obj.getName(), CustomObjects);
        
                NVP = new NameValuePair('LayoutSearchKeys', 'CustomObjectId',  CustomObjectId);
                retVal = concatenateJSON(retVal, JSON.serialize(NVP));  
            }
        }

        
        // INTERNATIONALISATIONS
        map<string,string> mapDlgLocs = ServiceLocalisation.getDialogueLocalisations('MetadataOps', false);            
        for (string trans : mapDlgLocs.keyset()) {
            NVP = new NameValuePair('Internationalisations', trans, mapDlgLocs.get(trans));
            retVal = concatenateJSON(retVal, JSON.serialize(NVP));              
        }
        
        // Finally, the actual layout info
        retVal = concatenateJSON(retVal, ControllerSettings.getStoredMetadata('GetSFPageLayouts'));     
        return retVal;
    }    


    // Return JSON for ALL profile layout assignments currently known
    @AuraEnabled
    global static string getAllStoredProfileLayouts() {
        
        string retVal;
        
        try {
            retVal = ControllerSettings.getStoredMetadata('GetSFPageLayouts');
        } catch (exception e) {
            retVal = 'Error (Get All Stored Profile Layouts): ' + e.getMessage();
        }
        
        return retVal;
    }


    // Get the stored JSON representing granular content of page layouts for a given object by API name
    @AuraEnabled
    global static string getLayoutContentForObject(string ObjectAPIName) {
        
        string retVal;
        
        try {
            retVal = ControllerSettings.getStoredMetadata('GetLayoutContentForObject_' + ObjectAPIName);
            
        } catch (exception e) {
            retVal = 'Error (Get Layout Content for Object "' + ObjectAPIName + '"): ' + e.getMessage();
        }
        
        return retVal;
    }
    
    
    // Get the actual URL underlying a SF custom URL record, as specified by its ID
    @AuraEnabled
    global static string getWeblinkDetails() {
        
        string retVal;
        
        try {
            retVal = ControllerSettings.getStoredMetadata('GetWeblinkDetails');
            
        } catch (exception e) {
            retVal = '';
        }
        
        return retVal;
    }

    
    // Wrapper to store amended copies of metadata
    @AuraEnabled
    global static string chunkAndStoreMetadata (string MetadataJSON, string MetadataType) {
        
        string retVal;
        
        try {
            retVal = ControllerSettings.chunkAndStoreMetadata(MetadataJSON, MetadataType);
        } catch (exception e) {
            retVal = 'Error (Chunk and Store Metadata): ' + e.getMessage();
        }
        
        return retVal;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Wizard-specific actions
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    
    // Create contextual help for the specified SF App and (comma separated list of) Tabs:
    // This consists of:
    //      - A topic for the app to act as root
    //      - A helped page layout for each tab (identifier = tab object name)
    //      - A helped page layout for record details layouts the tab's type (identifier = tab object's 3 letter code)
    //      - A context tree root helped element for each of these layouts, pointing to...
    //      - A help topic for the same
    //      - Parent relationships, placing all tabs on a tree with the app topic as the root
    
    @AuraEnabled
    global static string createHelpCxts (string appName, string appTabs) {        
       
        string retVal;
        
        ControllerHelpContent cH = new ControllerHelpContent(true);
        ServiceSecurity sS = new ServiceSecurity();
        map<string, string> mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false);
           
        string HTName;
        string HTSummary;
        string HTRootSummary = 'Context Help for the ' + appName + ' App';

        string[] aTabs = appTabs.split(',');

        HelpTopic__c RootHT;
        HelpTopic__c RecordHT;        
        HelpTopic__c HT;
        HelpTopic__c[] AllHTs = new HelpTopic__c[]{};
        map<string, HelpTopic__c> TabHTs = new map<string, HelpTopic__c>();
        map<string, HelpTopic__c> RecordLayoutHTs = new map<string, HelpTopic__c>();
        
        SemanticTag__c ParentSTag;
        HelpRelationship__c Rel;
        HelpRelationship__c[] AllRels = new HelpRelationship__c[]{};
        
        HelpedPageLayout__c HPL;
        HelpedPageLayout__c[] AllHPLs = new HelpedPageLayout__c[]{};
        map<string, HelpedPageLayout__c> TabHPLs = new map<string, HelpedPageLayout__c>();
        map<string, HelpedPageLayout__c> RecordLayoutHPLs = new map<string, HelpedPageLayout__c>();
        
        HelpedElement__c HE;
        HelpedElement__c[] AllHEs = new HelpedElement__c[]{};
        string RootIdentifier = 'ContextTreeRoot';
        
        integer i;
        boolean isObjectTabHPL;  
        Schema.DescribeSObjectResult sObj;
        Schema.DescribeSObjectResult[] sObjs = new Schema.DescribeSObjectResult[]{};
        
        
        // Check user rights
        if (sS.IsAllowed(ServiceSecurity.KnownSecureOperations.AdministerHelp) == false) {
            return mapGlbLocs.get('MessageNoRights');
        }
        
        try {            
            // Get the 'Parent' semantic tag - required later
            try {
                ParentSTag = [SELECT Id FROM SemanticTag__c WHERE Name = 'Parent'];
            } catch (exception ex) {
                return mapGlbLocs.get('MessageGenericError') + ' (Create Help Contexts): failed obtaining details of the semantics required to construct a Tree of Help Topics';
            }
            
            
            // Parse out the marker 'standard-' that may occur at the start of API tab names:
            // These will not feature in encountered identifiers and are not useful in topic names etc
            for (i=0; i<aTabs.size(); i++) {
                if (aTabs[i].startsWith('standard-')) {
                    aTabs[i] = aTabs[i].substring(9);
                }
            }        

            
            // Create (upsert) a root topic, named for the app being helped
            try {
                RootHT = [SELECT Id, Name, Summary__c FROM HelpTopic__c WHERE Name = :appName AND Summary__c = :HTRootSummary LIMIT 1];             
            } catch (exception ex) {
                RootHT = cH.getDefaultHelpTopic();
            }
            
            RootHT.Name = appName;
            RootHT.Summary__c = HTRootSummary;

            upsert RootHT;


            // Create a topic for each selected tab to be helped
            for (i = 0; i < aTabs.size(); i++) {

                // Reset control variable
                isObjectTabHPL = false;

                // Do not do this for 'home' as we'll use the root topic
                if (aTabs[i] != 'home') {
                    
                    // Incoming tab may represent an object or a layout name:
                    // Try object and, if that fails, assume a layout name...               
                    try {
                        // If this is a tab representing an object, as opposed to a LEX page layout, note this fact
                        sObj = ServiceSchema.getObjectDetailsByName(aTabs[i]);
                        HTName = sObj.getLabelPlural() + ' Tab';
                        sObjs.add(sObj);          
                        isObjectTabHPL = true;              
    
                    } catch (exception ex) {
                        // If tab is a page layout, that will be the name of help topic(s) we create
                        HTName = aTabs[i];
                    }
    
                    HTSummary = 'Context Help for ' + HTName;
    
                    
                    try {
                        HT = [SELECT Id, Name, Summary__c FROM HelpTopic__c WHERE Name = :HTName AND Summary__c = :HTSummary LIMIT 1];             
                    } catch (exception ex) {
                        HT = cH.getDefaultHelpTopic();
                    }
                
                    HT.Name = HTName;
                    HT.Summary__c = HTSummary;
                    
                    AllHTs.add(HT);
                    TabHTs.put(aTabs[i], HT);                 
                    
                    
                    // Also, if current tab represents an object (not a page layout) 
                    // create a topic to use in a context root helped element for each record detail layout
                    if (isObjectTabHPL) {
                    
                        HTName = sObj.getLabelPlural();
                        HTSummary = 'Context Help for ' + HTName + ' Records';
                        
                        try {
                            HT = [SELECT Id, Name, Summary__c FROM HelpTopic__c WHERE Name = :HTName AND Summary__c = :HTSummary LIMIT 1];             
                        } catch (exception ex) {
                            HT = cH.getDefaultHelpTopic();
                        }
                    
                        HT.Name = HTName;
                        HT.Summary__c = HTSummary;
                        
                        AllHTs.add(HT);
                        RecordLayoutHTs.put(sObj.getKeyPrefix(), HT);                 
                        
                    }                 
                }   // End if not Home tab               
            }   // End loop i around each wizard selected tab
                       
            upsert(AllHTs);
            
            
            // Create relations between object tab topics and root to create a tree
            for (i = 0; i < aTabs.size(); i++) {
                
                try {
                    // Get the tab topic added for the current tab
                    HT = TabHTs.get(aTabs[i]);
                    
                    // Use this to create the relationship
                    if (HT != null) {
                        Rel = [SELECT Id 
                                FROM HelpRelationship__c 
                                WHERE ReferringTopic__c = :RootHT.Id
                                AND RelatedHelpTopic__c = :HT.Id
                                AND SemanticTag__c = :ParentSTag.Id];
                        
                        // If we find the relationship, do nothing as we cannot update it
                    }
                        
                } catch (exception ex) {
                    Rel = new HelpRelationship__c();
                    Rel.ReferringTopic__c = RootHT.Id;
                    Rel.RelatedHelpTopic__c = HT.Id;         
                    Rel.SemanticTag__c = ParentSTag.Id;
                    AllRels.add(Rel);
                }
                
            }
            
            
            // Similarly, create relations between record detail layout topics and relevant tab topic
            for (i = 0; i < sObjs.size(); i++) {
                try {
                    // Get the tab topic added for the current record detail layout
                    RecordHT = RecordLayoutHTs.get(sObjs[i].getKeyPrefix());
            
                    HT = TabHTs.get(sObjs[i].getName());
                    if (HT == null) {HT = TabHTs.get(sObjs[i].getLocalName());}
            
            
                    // Use this to create the relationship
                    if (HT != null) {
                        Rel = [SELECT Id 
                                FROM HelpRelationship__c 
                                WHERE ReferringTopic__c = :HT.Id
                                AND RelatedHelpTopic__c = :RecordHT.Id
                                AND SemanticTag__c = :ParentSTag.Id];
                        
                        // If we find the relationship, do nothing as we cannot update it
                    }
                    
                } catch (exception ex) {
            
                    Rel = new HelpRelationship__c();
                    Rel.ReferringTopic__c = HT.Id;
                    Rel.RelatedHelpTopic__c = RecordHT.Id;         
                    Rel.SemanticTag__c = ParentSTag.Id;
                    AllRels.add(Rel);
                    
                }    
            }     
       
            upsert AllRels;
            
            
            // Create a HPL for each wizard selected tab
            for (i = 0; i < aTabs.size(); i++) {
                try {
                    HPL = [SELECT Name, PageLayoutIdentifier__c 
                                FROM HelpedPageLayout__c
                                WHERE PageLayoutIdentifier__c = :aTabs[i]
                                LIMIT 1];
                } catch (exception ex) {
                    HPL = new HelpedPageLayout__c();
                }
                
                HPL.Name = 'Tab Layout: ' + aTabs[i];
                HPL.PageLayoutIdentifier__c = aTabs[i];
                AllHPLs.add(HPL);
                TabHPLs.put(aTabs[i], HPL);

            }

            // Also, create HPL for records of tab's type - i.e., a layout for 
            // the object's three letter code (record details layout) as well as for the object name (tab)
            for (i = 0; i < sObjs.size(); i++) {
                try {
                    HPL = [SELECT Name, PageLayoutIdentifier__c 
                                FROM HelpedPageLayout__c
                                WHERE PageLayoutIdentifier__c = :sObjs[i].getKeyPrefix()
                                LIMIT 1];
                } catch (exception ex) {
                    HPL = new HelpedPageLayout__c();
                }
                                
                HPL.Name = sObjs[i].getLabelPlural() + ' Layout';
                HPL.PageLayoutIdentifier__c = sObjs[i].getKeyPrefix();
                AllHPLs.add(HPL);
                RecordLayoutHPLs.put(sObjs[i].getKeyPrefix(), HPL);
            
            }

            upsert AllHPLs;
            
            
            // Create a ContextRoot HE for each wizard selected tab
            for (i = 0; i < aTabs.size(); i++) {
                
                // Get the tab topic added for the current tab:
                // Note special handling as above for 'root' home page
                if (aTabs[i] != 'home') {
                    HT = TabHTs.get(aTabs[i]);
                } else {
                    HT = RootHT;
                }
                
                HPL = TabHPLs.get(aTabs[i]);
                
                // Use this to create the relationship
                if (HT != null && HPL != null) {

                    try {
                        HE = [SELECT Name, HelpedPageLayout__c, Identifier__c, HelpTopic__c 
                                FROM HelpedElement__c 
                                WHERE HelpedPageLayout__c = :HPL.Id
                                AND Identifier__c = :RootIdentifier
                                LIMIT 1];
                    } catch (exception ex) {
                        HE = new HelpedElement__c();
                    }
                    
                    HE.Name = 'Tree Contextualisation Element';
                    HE.HelpedPageLayout__c = HPL.Id;
                    HE.Identifier__c = RootIdentifier;
                    
                    // In the case of the 'home' tab, use the root node
                    if (aTabs[i] == 'home') {
                        HE.HelpTopic__c = RootHT.Id;
                    } else {
                        HE.HelpTopic__c = HT.Id;
                    }
                    
                    AllHEs.add(HE);
                }
                
            }


            // Also create a context root HE for each record detail HPL
            for (i = 0; i < sObjs.size(); i++) {    
                try {
                    
                    HT = RecordLayoutHTs.get(sObjs[i].getKeyPrefix());
                    HPL = RecordLayoutHPLs.get(sObjs[i].getKeyPrefix());
                    
                    HE = [SELECT Name, HelpedPageLayout__c, Identifier__c, HelpTopic__c 
                            FROM HelpedElement__c 
                            WHERE HelpedPageLayout__c = :HPL.Id
                            AND Identifier__c = :RootIdentifier
                            LIMIT 1];
                } catch (exception ex) {
                    HE = new HelpedElement__c();
                }
                
                HE.Name = 'Tree Contextualisation Element';
                HE.HelpedPageLayout__c = HPL.Id;
                HE.Identifier__c = RootIdentifier;
                HE.HelpTopic__c = HT.Id;
            
                AllHEs.add(HE);    
            }                                

            upsert AllHEs;
            

            // Report back to the user the ID of the root node topic created, so it can be used in Utility1
            retVal = RootHT.Id;
            
        } catch (exception e) {
            retVal = mapGlbLocs.get('MessageGenericError') + ' (Create Help Contexts): ' + e.getMessage();
        }
        
        return retVal;
    }



    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Reading List Builder ops
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    // Move a reading list entry (Subject) to a desired reading order position
    @AuraEnabled
    global static string moveReadingListEntry (string SubjectId, integer newPos) {
    
        string retVal = '';   
        ServiceSecurity sS = new ServiceSecurity();
    
        try {
            // These operations are reserved for Authors +
            if (! sS.IsAllowed(ServiceSecurity.KnownSecureOperations.EditHelp)) {
                map<string, string> mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false);
                retVal = 'Error (addReadingListEntry): ' + mapGlbLocs.get('MessageNoRights');              
                                
            } else {        
                // Get all RLEs in RL to which supplied RLE belongs, ordered as currently specified
                HelpReadingListEntry__c Ent = [SELECT Id, ReadingOrder__c, HelpReadingList__c, HelpTopic__r.Name FROM HelpReadingListEntry__c WHERE Id = :SubjectId];
                HelpReadingListEntry__c[] RLEs = [SELECT Id, ReadingOrder__c
                                                    FROM HelpReadingListEntry__c
                                                    WHERE HelpReadingList__c = :Ent.HelpReadingList__c];
    
                // Loop through entries to re-set their positions
                for (HelpReadingListEntry__c RLE : RLEs) {
                    if (RLE.Id == SubjectId) {
                        // If entry is mover, set to new position
                        RLE.ReadingOrder__c = newPos;
    
                    } else {    
                        if (newPos < Ent.ReadingOrder__c) {
                            // If move was 'up' to a numerically lower position...
                            //retVal += 'Subject is moving UP from ' + Ent.ReadingOrder__c + ': Entry ' + RLE.Id + ' is at position ' + RLE.ReadingOrder__c;
                    
                            if (RLE.ReadingOrder__c >= newPos && RLE.ReadingOrder__c < Ent.ReadingOrder__c) {
                                // If entry's order is below mover's NEW position, leave as is:
                                // If greater or equal to NEW position, but less than OLD position, increment
                                RLE.ReadingOrder__c = RLE.ReadingOrder__c + 1;
        
                                //retVal += 'Entry ' + RLE.Id + ' moved to ' + RLE.ReadingOrder__c + '... ';                
                            }
                
                        } else {
                            // If move was 'down' to a numerically higher position...
                            //retVal += 'Subject is moving DOWN from ' + Ent.ReadingOrder__c + ': Entry ' + RLE.Id + ' is at position ' + RLE.ReadingOrder__c;
        
                            if (RLE.ReadingOrder__c > Ent.ReadingOrder__c && RLE.ReadingOrder__c <= newPos) {
                                // If entry's order is below mover's OLD position, leave as is:
                                // If greater than OLD position, but less or equal to NEW position, decrement
                                RLE.ReadingOrder__c = RLE.ReadingOrder__c - 1;
                        
                                //retVal += 'Entry ' + RLE.Id + ' moved to ' + RLE.ReadingOrder__c + '... ';                
                            }
                        }       
                    }
                    
                }   // End RLE loop
    
                update RLEs;
                retVal += 'Moved entry "' + Ent.HelpTopic__r.Name + '" (' + SubjectId + ') to position ' + newPos;  
                    
            }   // End if permissions allow move
            
        } catch (exception e) {
            retVal = 'Error (addReadingListEntry): ' + e.getMessage();
        }
    
        return retVal;
    }


    // Add an entry and new topic to the reading list represented by subject ID
    @AuraEnabled
    global static string addReadingListEntry (string SubjectId) {
    
        string retVal;   
        ServiceSecurity sS = new ServiceSecurity();
    
        try {
            // These operations are reserved for Authors +
            if (! sS.IsAllowed(ServiceSecurity.KnownSecureOperations.EditHelp)) {
                map<string, string> mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false);
                retVal = 'Error (addReadingListEntry): ' + mapGlbLocs.get('MessageNoRights');              
                                
            } else {        
                ControllerHelpContent CH = new ControllerHelpContent(true);
                ServiceIHLists.ReadingList RL = new ServiceIHLists.ReadingList();
                
                HelpTopic__c HT = CH.getDefaultHelpTopic();
                insert HT;
                
                // Return value from this call should be a success message:
                retVal = RL.addItem(HT.Id, SubjectId);
                
                // If it is such a message (and not an error), return the ID of the added topic
                retVal = HT.Id;
                
            }
            
        } catch (exception e) {
            retVal = 'Error (addReadingListEntry): ' + e.getMessage();
        }
    
        return retVal;
    }
    
    
    // Delete the reading list entry represented by subject ID
    @AuraEnabled
    global static string deleteReadingListEntry (string SubjectId) {
    
        string retVal;   
        ServiceSecurity sS = new ServiceSecurity();
    
        try {
            // These operations are reserved for Authors +
            if (! sS.IsAllowed(ServiceSecurity.KnownSecureOperations.EditHelp)) {
                map<string, string> mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false);
                retVal = 'Error (deleteReadingListEntry): ' + mapGlbLocs.get('MessageNoRights');              
                                
            } else {
                // Create a reading list service class and advise it of the entry to be deleted
                ServiceIHLists.ReadingList RL = new ServiceIHLists.ReadingList();
                RL.Mover = SubjectId;
                            
                // Result of delete call should be a page reference (redundant here): null return
                // value indicates error
                if (RL.deleteItem() == null) {
                    retval = 'Error (deleteReadingListEntry): a call to the Reading Lists service to delete entry "' + SubjectId + '" failed';
                
                } else {
                    // If we succeed, we need to return the reading list ID, so calling control can navigate 
                    // to that record, thus refreshing the UI: although we do not know / specify reading list ID
                    // at the outset, act of deleting an entry should ensure that this has been set in the RL service...
                    retVal = RL.RLID;
                }
    
            }
            
        } catch (exception e) {
            retVal = 'Error (deleteReadingListEntry): ' + e.getMessage();
        }
    
        return retVal;
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Reconfigure mode / DDF manipulation ops
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    // Duplicate the helped element identified by the supplied subject ID, supplying a cloned topic in doing so
    @AuraEnabled
    global static string cloneHelpedElement(string SubjectId) {
        
        string retVal;   
        HelpTopic__c CloneeT; 
        HelpTopic__c CloneT;
        HelpedElement__c CloneeE;
        HelpedElement__c CloneE;
        ServiceSecurity sS = new ServiceSecurity();
        ControllerHelpContent CH = new ControllerHelpContent(true);
        
            
        try {
            // These operations are reserved for Authors +
            if (! sS.IsAllowed(ServiceSecurity.KnownSecureOperations.EditHelp)) {
                map<string, string> mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false);
                retVal = 'Error (cloneHelpedElement): ' + mapGlbLocs.get('MessageNoRights');              
                                
            } else {
                
                // Obtain details of the element to clone
                CloneeE = [SELECT DataDrivenFilter__c, ElementType__c, HelpFilter__c, HelpTopic__c, Name, HelpedPageLayout__c, Identifier__c, Parameters__c, Visibility__c
                            FROM HelpedElement__c
                            WHERE Id = :SubjectId];
                
                // Obtain the help topic associated with this element
                if (CH.getTopicViaHTID(CloneeE.HelpTopic__c, false) == true) {
                
                    // Clone the topic, amending name for clarity
                    CloneT = CH.clone(CH.Hlp);
                    CloneT.Name += ' (Copy)';
                    insert CloneT;
                    
                    // Clone the element, referencing the cloned topic
                    CloneE = new HelpedElement__c();
                    
                    CloneE.DataDrivenFilter__c = CloneeE.DataDrivenFilter__c;
                    CloneE.ElementType__c = CloneeE.ElementType__c;
                    CloneE.HelpFilter__c = CloneeE.HelpFilter__c;
                    CloneE.HelpTopic__c = CloneT.Id;
                    CloneE.Name = CloneeE.Name + ' (Copy)';
                    CloneE.HelpedPageLayout__c = CloneeE.HelpedPageLayout__c;
                    CloneE.Identifier__c = CloneeE.Identifier__c;
                    CloneE.Parameters__c = CloneeE.Parameters__c;
                    CloneE.Visibility__c = CloneeE.Visibility__c;
                    
                    insert CloneE;
                    
                    retVal = CloneE.Id;
                    
                } else {
                    // Error cloning topic
                    retVal = 'Error (cloneHelpedElement): error cloning source Helped Element\'s Help Topic';
                }
            }
                    
        } catch (exception e) {
            retVal = 'Error (cloneHelpedElement): ' + e.getMessage();
        }
    
        return retVal;
    }
    
    
    // Delete the helped element identified by the supplied subject ID
    @AuraEnabled
    global static string deleteHelpedElement(string SubjectId) {
        
        string retVal;    
        HelpedElement__c HE;
        string HPL;
        ServiceSecurity sS = new ServiceSecurity();
            
        try {
            // These operations are reserved for Authors +
            if (! sS.IsAllowed(ServiceSecurity.KnownSecureOperations.EditHelp)) {
                map<string, string> mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false);
                retVal = 'Error (deleteHelpedElement): ' + mapGlbLocs.get('MessageNoRights');              
                                
            } else {
                HE = [SELECT Id, HelpedPageLayout__c FROM HelpedElement__c WHERE Id = :SubjectId];
                
                // Note the helped page layout in play: we'll return this on sucessful deletion 
                // as a sign of completion (no point returning deleted ID etc)
                HPL = HE.HelpedPageLayout__c;
                
                delete HE;
                retVal = HPL;
            }
                    
        } catch (exception e) {
            retVal = 'Error (deleteHelpedElement): ' + e.getMessage();
        }
    
        return retVal;
    }
    
    
    // Add a help filter to the helped element identified by the supplied subject ID
    @AuraEnabled
    global static string addHelpFilter(string SubjectId) {
        
        string retVal;    
        HelpedElement__c HE;
        HelpedPageLayout__c HPL;
        HelpFilter__c Flt;
        string FIdent;
        integer IdentMaxLen = 100;
        ServiceSecurity sS = new ServiceSecurity();
        ServiceSchema svsS = new ServiceSchema();
        Schema.DescribeSObjectResult obj;
            
        try {
            // These operations are reserved for Authors +
            if (! sS.IsAllowed(ServiceSecurity.KnownSecureOperations.EditHelp)) {
                map<string, string> mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false);
                retVal = 'Error (AddHelpFilter): ' + mapGlbLocs.get('MessageNoRights');              
                                
            } else {
                HE = [SELECT Id, Name, HelpFilter__c, HelpedPageLayout__c
                            FROM HelpedElement__c
                            WHERE Id = :SubjectId];
                
                HPL = [SELECT Id, PageLayoutIdentifier__c
                            FROM HelpedPageLayout__c
                            WHERE Id = :HE.HelpedPageLayout__c];
                
                obj = svsS.getObjectDetails (HPL.PageLayoutIdentifier__c);
                
                Flt = new HelpFilter__c();  
                
                FIdent = 'Draft Filter: ' + obj.getLabelPlural() + ' (' + HE.Name + ')';
                if (FIdent.length() > IdentMaxLen) {FIdent = FIdent.substring(0, IdentMaxLen - 3) + '...';}                 
                Flt.FilterIdentifier__c = FIdent;
                
                Flt.FilterLogic__c = '1';
                Flt.FilteredObject__c = obj.getName();
                Flt.FilteredObjectIdentifier__c = HPL.PageLayoutIdentifier__c;                      
                insert Flt;
                
                HE.HelpFilter__c = Flt.Id;
                update HE;
                
                retVal = Flt.Id;
            }
                    
        } catch (exception e) {
            retVal = 'Error (AddHelpFilter): ' + e.getMessage();
        }
    
        return retVal;
    }
    
    
    // Delete the help filter identified by the supplied subject ID
    @AuraEnabled
    global static string deleteHelpFilter(string SubjectId) {
        
        string retVal;
        HelpFilter__c Flt;
        HelpedPageLayout__c HPL;
        ServiceSecurity sS = new ServiceSecurity();
            
        try {
            // These operations are reserved for Authors +
            if (! sS.IsAllowed(ServiceSecurity.KnownSecureOperations.EditHelp)) {
                map<string, string> mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false);
                retVal = 'Error (deleteHelpFilter): ' + mapGlbLocs.get('MessageNoRights');              
                                
            } else {
                Flt = [SELECT Id, FilteredObjectIdentifier__c FROM HelpFilter__c WHERE Id = :SubjectId];
                
                // Note the helped page layout identifier in play on the filter and use this to locate HPL: 
                // we'll return HPL Id on sucessful deletion as a sign of completion (no point returning deleted ID etc)
                HPL = [SELECT Id FROM HelpedPageLayout__c WHERE PageLayoutIdentifier__c = :Flt.FilteredObjectIdentifier__c];
                
                delete Flt;
                retVal = HPL.Id;
            }
                    
        } catch (exception e) {
            retVal = 'Error (deleteHelpFilter): ' + e.getMessage();
        }
    
        return retVal;
    }
    
    
    // Add a help filter criterion to the help filter identified by the supplied subject ID
    @AuraEnabled
    global static string addFilterCriterion(string SubjectId) {
        
        string retVal;    
        HelpFilterCriterion__c[] ExistingCriteria;
        HelpFilterCriterion__c FltC;
        ServiceSecurity sS = new ServiceSecurity();
            
        try {
            // These operations are reserved for Authors +
            if (! sS.IsAllowed(ServiceSecurity.KnownSecureOperations.EditHelp)) {
                map<string, string> mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false);
                retVal = 'Error (addFilterCriterion): ' + mapGlbLocs.get('MessageNoRights');              
                                
            } else {            
                ExistingCriteria = [SELECT Id FROM HelpFilterCriterion__c WHERE HelpFilter__c = :SubjectId];
                
                FltC = new HelpFilterCriterion__c();        
                FltC.HelpFilter__c = SubjectId;
                FltC.CriterionNumber__c = ExistingCriteria.size() + 1;
                FltC.FilteredField__c = 'name';
                FltC.FilteredFieldType__c = 'string';
                FltC.Operator__c = 'LIKE';
                FltC.FilterValue__c = '%';
                insert FltC;
                
                retVal = FltC.Id;
            }
                    
        } catch (exception e) {
            retVal = 'Error (addFilterCriterion): ' + e.getMessage();
        }
    
        return retVal;
    }
    
    
    // Delete the help filter criterion identified by the supplied subject ID
    @AuraEnabled
    global static string deleteFilterCriterion(string SubjectId) {
        
        string retVal;
        HelpFilterCriterion__c FltC;
        string Flt;
        ServiceSecurity sS = new ServiceSecurity();
            
        try {
            // These operations are reserved for Authors +
            if (! sS.IsAllowed(ServiceSecurity.KnownSecureOperations.EditHelp)) {
                map<string, string> mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false);
                retVal = 'Error (deleteFilterCriterion): ' + mapGlbLocs.get('MessageNoRights');              
                                
            } else {
                FltC = [SELECT Id, HelpFilter__c FROM HelpFilterCriterion__c WHERE Id = :SubjectId];
    
                // Note the filter in play on the criterion: 
                // we'll return filter Id on sucessful deletion as a sign of completion (no point returning deleted ID etc)
                Flt = FltC.HelpFilter__c;
                
                delete FltC;
                retVal = Flt;
            }
                    
        } catch (exception e) {
            retVal = 'Error (deleteFilterCriterion): ' + e.getMessage();
        }
    
        return retVal;
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Other
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    // Safely add JSON strings together
    public static string concatenateJSON (string s1, string s2) {
        string retVal;
        
        //if (s1 == '' || s1 == null || s1 == '[]') {return s2;}
        //if (s2 == '' || s2 == null || s2 == '[]') {return s1;}


        if (s1 == '' || s1 == null || s1 == '[]') {
            s1 = '';
        }
        if (s2 == '' || s2 == null || s2 == '[]') {
            s2 = '';
        }

        
        if (s1.startsWith('[')) {
            s1 = s1.substring(1, s1.length() - 1);
        }
        
        if (s1.endsWith(']')) {
            s1 = s1.substring(0, s1.length() - 1);
        }
        
        
        if (s2.startsWith('[')) {
            s2 = s2.substring(1, s2.length() - 1);
        }
        
        if (s2.endsWith(']')) {
            s2 = s2.substring(0, s2.length() - 1);
        }

        
        //retVal = '[' + s1 + ',' + s2 + ']';
        retVal = '[';
        
        if (s1 == '') {
            retVal += s2;
            
        } else {
            retVal += s1;
            
            if (s2 != '') {
                retVal += ',' + s2;
            }           
        }
                
        
        retVal += ']';
        
        
        return retVal;
    }   


    // Get vote options and user's vote for a given topic
    @AuraEnabled
    global static string getVoteInfoForTopic(string HTID, string HVSID) {
        
        string retVal;
        
        try {
            ControllerHelpContent cH = new ControllerHelpContent(false);
            NameValuePair NVP;
            
            cH.setupVoteInfoForTopic(HTID, HVSID);
    
            if (cH.VoteOptions != null) {
                retVal = JSON.serialize(cH.VoteOptions); 
                
                // Also, tack on details of any last vote cast
                NVP = new NameValuePair('VoteInfo', 'theVote', cH.theVote);
                retVal = concatenateJSON(retVal, JSON.serialize(NVP));
            }
            
            
        } catch (exception e) {
            retVal = '';
        }
        
        return retVal;
    }


    // Get vote options and user's vote for a given topic, plus keyword parsed topic description and custom field info
    @AuraEnabled
    global static string getAdditionalInfoForTopic(string HTID) {
        
        string retVal;
        
        try {
            ControllerHelpContent cH = new ControllerHelpContent(false);
            NameValuePair NVP;
            NameValuePair[] NVPs = new NameValuePair[]{};
            String strTemp='';  
    
            // Get the single requested help topic
            cH.getTopicViaHTID(HTID,false);
            object[] helpInfo = new object[]{}; 
            helpInfo.add(cH.Hlp);
            
            if (cH.Hlp != null) {                                
                // Return details of any custom fields            
                if (cH.CustomFields != null) {
                    for (Schema.FieldSetMember CF : cH.CustomFields) {
                            
                        // Also, as we can't directly reference the custom fields in the current record we send to LUX
                        // (e.g., {!v.CurrentRecord.get(field name)} is not allowed) we need to load these
                        // fields into our own custom object that we can reference: we will pack field info plus
                        // values from the help topic sought into these items...
    
                        helpInfo.add(new CustomFieldInfo(CF, (sObject) cH.Hlp));
                    }
                }
    
                strTemp = JSON.serialize(helpInfo);            
                retVal = concatenateJSON(retVal, strTemp);
                            
            }
            
            // Now obtain vote info
            cH.initialiseVoteOptions();
                    
            if (cH.VoteOptions != null) {
                retVal = concatenateJSON(retVal, JSON.serialize(cH.VoteOptions)); 
                
                // Also, tack on details of any last vote cast
                NVP = new NameValuePair('VoteInfo', 'theVote', cH.theVote);
                NVPs.add(NVP);            
            }
                        
            // Add a Name / Value pair item to hold a keyword-parsed copy of topic description
            strTemp = '';
            strTemp = cH.markKeywords(cH.Hlp, true); 

            
// EXPERIMENTAL CODE: THIS IS NOT CONNECTED WITH THE CASE-INSENSITIVE BUG IN MARK KEYWORDS...
//if (strTemp + '' == 'null') {strTemp = '';}
strTemp = strTemp.replace('[HelpCue--', '<div class="HelpCue">');           
strTemp = strTemp.replace('--HelpCue]', '</div>');          
            
            NVP = new NameValuePair('ParsedContent', 'HelpTopicDescription', strTemp);
            NVPs.add(NVP);
            retVal = concatenateJSON(retVal, JSON.serialize(NVPs));
            
            
        } catch (exception e) {
            retVal = '';
        }
        
        return retVal;
    }
    

    // Get details of flows, defined in helped elements with DDF as required, that have been highlighted
    // as being of use / interest in a particular help context. 
    @AuraEnabled
    global static string getContextFlows (string IHContext) {
        
        string retVal = '';
        ControllerSettings cS;
        string SFO;
        HelpedPageLayout__c HPL;
        HelpedElement__c[] CandidateHEs;
        HelpedElement__c[] HEs;
        
        try {
            cS = new ControllerSettings();
            SFO = cS.SFObjId(URL.getOrgDomainURL().toExternalForm() + '/' + IHContext);
                
            if (SFO != 'Err!') {                
                // Get the helped page layout for this identifier
                HPL = [SELECT Id FROM HelpedPageLayout__c WHERE PageLayoutIdentifier__c = :SFO];
    
                // Get any context root elements for this layout:
                // If there's more than 1, apply DDF...
                candidateHEs = [SELECT Id, Name, Identifier__c, HelpFilter__c, DataDrivenFilter__c, UseForNew__c, Parameters__c, HelpTopic__c 
                                    FROM HelpedElement__c 
                                    WHERE HelpedPageLayout__c = :HPL.Id 
                                    AND ElementType__c = 'Contextual Flow'];
                                    
                HEs = ControllerSettings.getDDFMatches(IHContext, candidateHEs);
                
                retVal = JSON.serialize(HEs);                   
            }           
        } catch (exception e) {}
        
        
        try{        
            // Add internationalisations
            NameValuePair NVP;
            map<string,string> mapDlgLocs = ServiceLocalisation.getDialogueLocalisations('IHFlowLauncher', false);            
            for (string trans : mapDlgLocs.keyset()) {
                NVP = new NameValuePair('Internationalisations', trans, mapDlgLocs.get(trans));
                retVal = concatenateJSON(retVal, JSON.serialize(NVP));              
            }       
        } catch (exception e) {}
        
        
        return retVal;
    }


    // Wrapper to ServiceSchema and other API ops that can only be called from a VF context:
    // Op1 = Get profile layout assignments for a given record (current record's type only)
    // Op2 = Get custom section metadata (links, VF pages etc) for a given object by API name
    // Op3 = Get profile layout assignments for a given record (all types applicable to current record's object type)
    // Op4 = Get details of Apps in the current org
    // Op5 = Get basic details of the Tabs in a particular App, plus full details of ALL tabs
    // Op6 = Get weblink details (the actual URLs used by the items in custom link sections)
    
    public string LUXOpDiags {get; set;}    
    public void LUXOpHandler() {
        
        // For diagnostics messages
        map<string, string> mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false); 
        map<string, string> mapDlgLocs = ServiceLocalisation.getDialogueLocalisations('IHLUXOpHandler', false); 
        string MDJSON1;
        string MDJSON2;
        string chunkResult;
        string Op;
        string IHContext;
        boolean validJSON = false;
                
        try {
            // Action to take depends on operation we're asked to perform
            Op = ServiceSecurity.getQueryParameter('Op', 2);
            IHContext = ServiceSecurity.getQueryParameter('IHContext', 2);
           
            if (Op == '1' || Op == '3') {
                // Get profile layout assignment details for a given record

                string RecordId;
                string missingLayout;
                string knownLayouts;
                string allLayouts;
                
                
                // Note the record ID we've been asked to investigate 
                RecordId = ServiceSecurity.getQueryParameter('recordId', 2);
                
                // Get the layout JSON for this record:
                // Differentiate call here to get layout metadata for specific type of current record or ALL types for current record's object
                if (Op == '1') {
                    // Request metadata only for the current record's record type
                    missingLayout = ServiceSchema.getProfileLayoutsByRecordId(RecordId, false, true);
                    
                } else {
                    // Request metadata for ALL types applicable to the current record's object
                    missingLayout = ServiceSchema.getProfileLayoutsByRecordId(RecordId, false, false);
                }
                
                
                // Get all the remaining JSON stored in our existing cache of layout info (configuration items / type = configuration data)
                knownLayouts = ControllerSettings.getStoredMetadata('GetSFPageLayouts');

                // Append this JSON to those records - but only if missing layout info is valid JSON
                try {
                    // This should only succeed if JSON is valid
                    JSONParser parser = JSON.createParser(missingLayout);
                    parser.nextToken();
                    
                    if (missingLayout.indexOf('"errorCode"') == -1) {
                        // Need additional checks here to make sure we don't store error messages
                        // as opposed to layout info!
                        validJSON = true;
                    }
                    
                } catch (exception ex) {}
                
                if (validJSON == true) {
                    
                    // Save the totality
                    allLayouts = concatenateJSON(missingLayout, knownLayouts);
                    chunkResult = ControllerSettings.chunkAndStoreMetadata(allLayouts, 'GetSFPageLayouts');
                    
                    if (chunkResult == '') {
                        // All is well
                        LUXOpDiags = mapGlbLocs.get('MessageLayoutMetadataObtained');               
                    } else {
                        LUXOpDiags = mapGlbLocs.get('MessageGenericError') + ' (LUX Operations Handler: Get Layout for Record) - ' + chunkResult;
                    }
                    
                } else {
                    LUXOpDiags = mapGlbLocs.get('MessageGenericError') + ' - ' + mapDlgLocs.get('MessageOp1Error') + ' (Profile ID: ' + UserInfo.getProfileId() + '): ' + missingLayout;
                }
                
            }
            

            if (Op == '2') {
                // Get Layout content / custom section metadata for an object by API name
            
                // Note the object we've been asked to investigate 
                string ObjectAPIName = ServiceSecurity.getQueryParameter('ObjectAPIName', 2);
                MDJSON1 = ServiceSchema.getLayoutContentForObject(ObjectAPIName);
                
                if (MDJSON1.indexOf('"errorCode"') == -1) {
                    // Need additional checks here to make sure we don't store error messages
                    // as opposed to layout info!
                    validJSON = true;
                }
                
                if (validJSON == true) {
                    chunkResult = ControllerSettings.chunkAndStoreMetadata(MDJSON1, 'GetLayoutContentForObject_' + ObjectAPIName);
                
                    if (chunkResult == '') {
                        // All is well
                        LUXOpDiags = mapGlbLocs.get('MessageLayoutMetadataObtained');               
                        
                    } else {
                        LUXOpDiags = mapGlbLocs.get('MessageGenericError') + ' (LUX Operations Handler: Get Layout Content For Object - storing results) - ' + chunkResult;
                    }
                    
                } else {
                    LUXOpDiags = mapGlbLocs.get('MessageGenericError') + ' (LUX Operations Handler: Get Layout Content For Object - bad JSON) - ' + MDJSON1;
                }
            
            }
            
            
            if (Op == '4') {
                // Get details of Apps in the current org and store in config items
                MDJSON1 = ServiceSchema.getAppListing();
                
                if (MDJSON1.indexOf('"errorCode"') == -1) {
                    validJSON = true;
                }
                
                if (validJSON == true) {
                    chunkResult = chunkAndStoreMetadata (MDJSON1, 'GetAppListing');

                    if (chunkResult == '') {
                        // All is well
                        LUXOpDiags =  mapDlgLocs.get('MessageAppDataObtained');               
                    } else {
                        LUXOpDiags = mapGlbLocs.get('MessageGenericError') + ' (LUX Operations Handler: Get App metadata - storing results) - ' + chunkResult;
                    }
                    
                } else {
                    LUXOpDiags = mapGlbLocs.get('MessageGenericError') + ' (LUX Operations Handler: Get App metadata - bad JSON) - ' + MDJSON1;
                }
            }


            if (Op == '5') {
                // Get details of tab API names in a particular App, plus full details of all tab objects
                MDJSON1 = ServiceSchema.getTabListing(IHContext);
                MDJSON2 = ServiceSchema.getAllTabs();
                
                if (MDJSON1.indexOf('"errorCode"') == -1 && MDJSON2.indexOf('"errorCode"') == -1) {
                    validJSON = true;
                }
                
                if (validJSON == true) {
                    chunkResult = chunkAndStoreMetadata (MDJSON1, 'GetTabListing_' + IHContext);
                    if (chunkResult == '') {
                        // All is well
                        LUXOpDiags = mapDlgLocs.get('MessageThisTabDataObtained');               
                    } else {
                        LUXOpDiags = mapGlbLocs.get('MessageGenericError') + ' (LUX Operations Handler: Get tabs metadata - storing results) - ' + chunkResult;
                    }

                    chunkResult = chunkAndStoreMetadata (MDJSON2, 'GetTabListing');
                    if (chunkResult == '') {
                        // All is well
                        LUXOpDiags += '... ' + mapDlgLocs.get('MessageAllTabDataObtained') + '... ';               
                    } else {
                        LUXOpDiags += mapGlbLocs.get('MessageGenericError') + ' (LUX Operations Handler: Get ALL tabs metadata - storing results) - ' + chunkResult;
                    }
                    
                } else {
                    LUXOpDiags = mapGlbLocs.get('MessageGenericError') + ' (LUX Operations Handler: Get tabs metadata - bad JSON) === ' + MDJSON1 +  ' === ' + MDJSON2;
                }
            }
            
            
            if (Op == '6') {
                // Get weblink details (URLs used by custom links in custom link page sections)
                chunkResult = ServiceSchema.getWeblinkDetails();
                if (chunkResult == '') {
                    LUXOpDiags = mapGlbLocs.get('MessageLayoutMetadataObtained');               
                } else {
                    LUXOpDiags = mapGlbLocs.get('MessageGenericError') + ' (LUX Operations Handler: Get custom link URLs) - ' + chunkResult;
                }
            }
        
        } catch (exception e) {
            LUXOpDiags = mapGlbLocs.get('MessageGenericError') + ' (LUX Operations Handler) - ' + e.getMessage();
        }
                        
    }   
    
    
    // Get help topic (ID) plus callout details applicable to a given object / field API name combination:
    // Return value is in the form: 
    // [Topic ID] [Delimiter] [Callout page name] [Delimiter] [Callout Height] [Delimiter] [Element identifier]
    
    @AuraEnabled
    global static string getCalloutDetailsForAPIField (string ObjectPrefix, string FName) {
        
        string retVal = '';
        Schema.DescribeSObjectResult sObj;
        Map<String, Schema.SObjectField> FMap;  
        Schema.DescribeFieldResult Fld;
        string FLabel = '';
        string D1 = '^';
        
        try {
            // Get object info based on its prefix
            ServiceSchema svsS = new ServiceSchema();
            sObj = svsS.getObjectDetails(ObjectPrefix);
        
            
            // Get the label text for the specified field based on its name
            FMap = sObj.Fields.getMap();
            for (string FKey : FMap.keySet()){   
                Fld = FMap.get(FKey).getDescribe();
                
                if (Fld.getName() == FName) {
                    FLabel = Fld.getLabel(); 
                    break;
                }
            }
            
            // Get all helped elements known for this object
            ControllerIHQAMSettings cIHQ = new ControllerIHQAMSettings(true);
            cIHQ.LUXParams = ObjectPrefix;          
            cIHQ.initializeIH1QAM();  
            
            // Loop through elements to find the one matching the field label derived above
            if (cIHQ.HelpedElements != null) {          
                for (ControllerIHQAMSettings.SearchResultQAM SR : cIHQ.HelpedElements) {
                    if (SR.Element.Identifier__c == FLabel) {
                        retVal = SR.Element.HelpTopic__c + D1;                      
                        retVal += SR.Element.HelpTopic__r.CalloutTemplate__r.PageURL__c + D1;
                        retVal += SR.Element.HelpTopic__r.CalloutHeight__c + D1;
                        retVal += SR.Element.Identifier__c;
                        break;
                    }
                }    
                        
            } else {
                retVal = '';
            }
            
        } catch (exception e) {
            retVal = 'Error (Get Topic ID By Field Name) - ' + e.getMessage();
        }
        
        return retVal;
    }


    // Expose customer CSS
    @AuraEnabled
    global static string getBrandCSS() {
        return ControllerHelpContent.getBrandCSS();
    }
    
    
    // Expose Vote Sets link
    @AuraEnabled
    global static string TVoteSetsLink() {
        ControllerHelpContent CH = new ControllerHelpContent(true);
        return CH.TVoteSetsLink;
    }
    
    
    // Expose Community prefix
    @AuraEnabled
    global static string getCommunityPrefix() {
        string retVal = '';
        try {
            retVal = ControllerSettings.getCommunityPrefix();
        } catch (exception e) {}
        return retVal;
    }


    // Save changes to a Help Topic
    @AuraEnabled
    global static string saveRecord(string objectJSON) {
        string retVal;
        
        try {
            ControllerHelpContent cH = new ControllerHelpContent();

            // Turn the incoming topic JSON into an object record
            HelpTopic__c HT = (HelpTopic__c) JSON.deserialize(objectJSON, HelpTopic__c.class);
            
            // Save changes
            
            cH.Hlp = HT;
            cH.initialiseForBookmarks();    // Runs initialise topic, which is otherwise private
            
            cH.saveHelp();
                        
            retVal = cH.Diags;
                                     
        } catch (exception e) {
            retVal = 'Error: ' + e.getMessage();
        }
        
        return retVal;
    }
    
    
    // Delete a Help Topic
    @AuraEnabled
    global static string deleteTopic(string HelpTopicId) {
        string retVal;
        
        try {
            ControllerHelpContent cH = new ControllerHelpContent();
            
            // Get the referenced Help Topic
            HelpTopic__c HT = [SELECT Id FROM HelpTopic__c WHERE Id=:HelpTopicId];

            cH.Hlp = HT;
            cH.initialiseForBookmarks();    // Runs initialise topic, which is otherwise private
            cH.deleteHelpTopic();
                        
            retVal = cH.Diags;
                                     
        } catch (exception e) {
            retVal = 'Error: ' + e.getMessage();
        }
        
        return retVal;
    }
    
    
    // Delete a Related Help Resource
    @AuraEnabled
    global static string deleteHelpTopicResource(string HTRID) {

        string retVal = '';
        boolean[] perms;
        ServiceSecurity sS = new ServiceSecurity();
        map<string,string> mapGlbLocs;

        
        try {
            // Check permissions
            perms = sS.UserPermissions();
            mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false); 
            
            // Operation available to Authors+ only
            if (perms[1] == true) {

                HelpTopicResource__c HTR = [SELECT Id FROM HelpTopicResource__c WHERE Id=:HTRID];
                delete HTR;
                retVal = 'Help Topic Resource deleted';
                
            } else {
                retVal = mapGlbLocs.get('MessageNoRights');
            }
                        
        } catch (exception e) {
            retVal = 'Error (Delete Help Topic Resource): ' + e.getMessage();
        }
        
        return retVal;
        
    }
    
    
    // Create a related help topic 
    @AuraEnabled
    global static string createRelatedHelp(string ReferringHTID, string RelatedHTID) {
    
        string retVal = '';
        boolean[] perms;
        ServiceSecurity sS = new ServiceSecurity();
        ControllerSearch CS = new ControllerSearch();
        map<string,string> mapGlbLocs;
    
            
        try {
            // Check permissions
            perms = sS.UserPermissions();
            mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false); 
            
            // Operation available to Authors+ only
            if (perms[1] == true) {
                
                CS.HTID = ReferringHTID;
                CS.SearchResultId = RelatedHTID;
                CS.addRelatedHelp();
                
                retVal = CS.Diags;
                    
            } else {
                retVal = mapGlbLocs.get('MessageNoRights');
            }
                            
        } catch (exception e) {
            retVal = 'Error (Create Related Help - Link Topic ' + RelatedHTID + ' to ' + ReferringHTID + '): ' + e.getMessage();
        }
        
        return retVal;
        
    }
    
@AuraEnabled
global static string addExistingTopictoRL(string ReferringHTID, string RelatedHTID) {
    string retVal;
    ServiceSecurity sS = new ServiceSecurity();
    
    try {
        // Check if user has permission
        if (!sS.IsAllowed(ServiceSecurity.KnownSecureOperations.EditHelp)) {
            map<string, string> mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false);
            return 'Error (addExistingTopictoRL): ' + mapGlbLocs.get('MessageNoRights');
        }
        
        // Use the existing ServiceIHLists.ReadingList functionality
        ServiceIHLists.ReadingList RL = new ServiceIHLists.ReadingList();
        
        // Add the existing topic to the reading list
        // ReferringHTID is the reading list/subject and RelatedHTID is the topic to add
        retVal = RL.addItem(RelatedHTID, ReferringHTID);
        
        // Return success message or the result from the reading list operation
        return retVal;
        
    } catch (Exception e) {
        return 'Error (addExistingTopictoRL): ' + e.getMessage();
    }
}

    
    // Create a resource, then a help topic resource
    @AuraEnabled
    global static string createAndLinkHelpResource(string HTID) {
    
        string retVal = '';
        
        
        boolean[] perms;
        ServiceSecurity sS = new ServiceSecurity();
        ControllerSearch CS = new ControllerSearch();
        map<string,string> mapGlbLocs;
    
            
        try {
            // Check permissions
            perms = sS.UserPermissions();
            mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false); 
            
            // Operation available to Authors+ only
            if (perms[1] == true) {
                
                CS.HTID = HTID;

                CS.fld1 = 'NEW RESOURCE';               //Name
                CS.fld2 = '';                           // Summary
                CS.fld3 = 'https://www.example.com';    // URL
                CS.fld4 = '';                           // Type
                CS.fld5= '';                            // Location
                
                CS.createRelatedResource();
                
                // Search result should have been set to new resource ID
                retVal = CS.SearchResultId;
                    
            } else {
                retVal = mapGlbLocs.get('MessageNoRights');
            }
                            
        } catch (exception e) {
            retVal = 'Error (Create and Link Help Resource - Topic = ' + HTID + '): ' + e.getMessage();
        }
        
        
        return retVal;
        
    }
    

    // Create a help topic resource for a specified, existing resource
    @AuraEnabled
    global static string createHelpTopicResource(string HTID, string ResourceId) {
    
        string retVal = '';
        boolean[] perms;
        ServiceSecurity sS = new ServiceSecurity();
        ControllerSearch CS = new ControllerSearch();
        map<string,string> mapGlbLocs;
    
            
        try {
            // Check permissions
            perms = sS.UserPermissions();
            mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false); 
            
            // Operation available to Authors+ only
            if (perms[1] == true) {
                
                CS.HTID = HTID;
                CS.SearchResultId = ResourceId;
                CS.addRelatedResource();
                
                retVal = CS.Diags;
                    
            } else {
                retVal = mapGlbLocs.get('MessageNoRights');
            }
                            
        } catch (exception e) {
            retVal = 'Error (Create Help Topic Resource - Topic = ' + HTID + ' : Resource = ' + ResourceId + '): ' + e.getMessage();
        }
        
        return retVal;
        
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Keyword analysis
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    //This method is used to make call to SuggestKeywords class methods.
    //This is used in IHKeywords component to suggestKeywords from input text

    //      - InputText, QualityThreshold, MaxPhraseLength = to pass to analysers - see interface definition
    //      - DesiredAnalysers = comma separated list of class names of analysers to user - see pseudocode in wrapper 
    //      - OperationMode = synchronous or asynchronous
    
    @AuraEnabled
    public static string getKeywords(String InputText, integer QualityThreshold, integer MaxPhraseLength, string DesiredAnalysers, string OperationMode){ 

        string retVal = '';
        
        if(OperationMode == 'asynchronous'){      
                  
            //Generating GUID for filtering PF events
            string GUID = ControllerLUXOps.getGUID(); 
            
            // Checking if Platform Event is allowed or not from Help Settings page
            iahelp__IASetIHOrg__c PFEventCheck = iahelp__IASetIHOrg__c.getValues('EnabledElements');
            system.debug('PFEventCheck.iahelp__RaisePlatformEvents__c  '+PFEventCheck.iahelp__RaisePlatformEvents__c);
            
            if(PFEventCheck.iahelp__RaisePlatformEvents__c){
                
                // Use intelligence service to launch asynchronous job to analyse input text:
                // Pass it the GUID so platform event issued on completion can be marked with this
                ServiceIntelligence.asynchAnalyser(InputText, QualityThreshold, MaxPhraseLength, DesiredAnalysers, GUID);                       
                
                map<string,string> mapDlgLocs = ServiceLocalisation.getDialogueLocalisations('iahelp__IHManageSettings', false);
                string msg = mapDlgLocs.get('MessageHBSReset');
                
                ServiceIHLists.ListingItem LI = new ServiceIHLists.ListingItem();
                
                // Note that return value includes GUID, allowing one to check for relevant asynch event signalling completion of analysis
                LI.Id = 'ASYNCH';
                LI.MasterId = GUID;
                LI.Label = msg;
                LI.ActionCode = 'SuggestedKeyword';
                LI.Parameters = '999';
                LI.StyleClass = 'asynch job';
                
                retVal = JSON.serialize(LI);
                
            } else {
                // If Platform event is not allowed, asynchronous analysis cannot be undertaken:
                // Report this fact via return value and take no further action
                map<string,string> mapDlgLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false);

                ServiceIHLists.ListingItem LI = new ServiceIHLists.ListingItem();
                
                LI.Id = 'ASYNCH';
                LI.MasterId = GUID;
                LI.Label = mapDlgLocs.get('MessagePlatformEventsRequired');
                LI.ActionCode = 'SuggestedKeyword';
                LI.Parameters = '999';
                LI.StyleClass = 'asynch job';
                
                retVal = JSON.serialize(LI);
            }
            
        } else {
            // If synchronous call requested, ask intelligence service to perform this and return
            retVal = ServiceIntelligence.analyseHelper(InputText, QualityThreshold, MaxPhraseLength, DesiredAnalysers);
        }
        
        return retVal;
    }
    
    
    // Remove noise / irrelevant content from materials to be analysed
    @AuraEnabled
    public static string addToNoiseList(list<string> strlist){        
        
        string returnvalue;
        list<iahelp__NoiseWords__c> addnoiseword = new list<iahelp__NoiseWords__c>();
        
        //Creating list of noise words
        for(string str : strlist){
            iahelp__NoiseWords__c NoiseWords = new iahelp__NoiseWords__c();
            NoiseWords.name = str;
            addnoiseword.add(NoiseWords);
        }
        system.debug('addnoiseword '+addnoiseword);
        Database.SaveResult[] srList = Database.insert(addnoiseword,false);
        
        for (Database.SaveResult sr : srList) {
          
            if (sr.isSuccess()) {
                // Operation was successful, so get the ID of the record that was processed
                 system.debug('get Id :'+sr.getId());
                 returnvalue = 'success';
            } else {
                // Operation failed, so get all errors                
                for(Database.Error err : sr.getErrors()) {
                    System.debug('The following error has occurred.');
                    returnvalue = 'error';
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    return returnvalue;
                }
             }
       }

       return returnvalue;
    }
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Comment component support
    /////////////////////////////////////////////////////////////////////////////////////////////////////
  
    // Call when Aura comment component  loads first time
    @AuraEnabled 
    public static string initialCommentCall(string helptopicid, string RLid , string PLIdentifier){
        
        ControllerComments cc = new ControllerComments();
    
        cc.HelpTopicID = helptopicid; 
        cc.RLVID = RLid;
        cc.PageLayoutID = PLIdentifier;
        cc.IsAura = true; 
        cc.initialise();
        string pagelayoutNameandId = cc.pagelayoutName + ',,'+cc.helpPageLayoutId;
        
        if(cc.HelpTopicName != null){
            return  cc.HelpTopicName;
        }
        else if(cc.RLName != null){
            return  cc.RLName;
        
        }else{
          
            return  pagelayoutNameandId;
        }
      
    } 
    

    // Log a comment 
    @AuraEnabled 
    public static string doLogComment(string userComment, string helptopicid, string RLid, string PLIdentifier , string pageLayOutID){
        
        string retVal = '';
        ControllerComments cc = new ControllerComments(); 

        cc.initialiseForLUX();
        
        if (cc.isError == false) {
            if(helptopicid != null && helptopicid != ''){
                 cc.HelpTopicID = helptopicid;
            }
            if(RLid != null && RLid != ''){
                cc.RLVID = RLid;
            }
        
            if(PLIdentifier != null && PLIdentifier != ''){
               cc.PageLayoutID = pageLayOutID;
            }
            cc.UserText = userComment;
            cc.logComment();
            
            retVal = cc.Diags;
            
        } else {
            // Error initialising
            retVal = 'ERR! ' + cc.DialogueTitle;
        }
        
        return retVal;     
    }
    

    // Get internationalisations for a specified component
    @AuraEnabled
    public static string getInternationalisations(String DlgName){
    
        string retVal = '';
        map<string,string> mapDlgLocs;  
        NameValuePair NVP;
        
        try { 
              mapDlgLocs = ServiceLocalisation.getDialogueLocalisations(DlgName, false);  
                       
              for (string trans : mapDlgLocs.keyset()) {
                 NVP = new NameValuePair('Internationalisations', trans, mapDlgLocs.get(trans));
                 retVal = concatenateJSON(retVal, JSON.serialize(NVP));              
              }
             
        } catch (exception e) {
            retVal = 'Error obtaining translation codes: ' + e.getMessage();
        }

        return retVal;
    }
    
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Detail designer component support
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    
    //This method is getting called from IHDetailDesigner component for storing Custom Layout Definition
    @AuraEnabled
    public static string saveCustomTopicLayout(string HTID, string layoutInfo, string newTemplateName){
        
        boolean[] perms;
        ServiceSecurity sS = new ServiceSecurity();
        iahelp__HelpTopic__c HT;
        iahelp__HelpTopicTemplate__c HTT;
        string retVal = '';
        string HTTID;
        
        
        system.debug('saveCustomTopicLayout method - Help Topic is : ' + HTID);
        
        HT = [select id,iahelp__Template__c from iahelp__HelpTopic__c where id =: HTID];
        HTTID = HT.iahelp__Template__c;
        
        system.debug('Help Topic : ' + HT);
        system.debug('Help Topic Template : ' + HT.iahelp__Template__c);
        
  // try {
         // Check permissions
//       perms = sS.UserPermissions();
       
        if(HTTID != null && HTTID != '' && newTemplateName == ''){
            System.debug('In saveCustomTopicLayout method: modifying existing Topic Template ');
            
            HTT = [SELECT id, Name, iahelp__TemplateType__c, iahelp__PageURL__c FROM iahelp__HelpTopicTemplate__c where id =: HTTID];
            HTT.iahelp__PageURL__c = layoutInfo;
            Database.SaveResult updateResult = Database.update(HTT, false);
            if(updateResult.isSuccess()){
                return '';
                
            } else{
                for(Database.Error err : updateResult.getErrors()) {
                    System.debug('The following error has occurred.');                    
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    retVal += err.getStatusCode() + ': ' + err.getMessage();
                }
                return retVal;
            }
            
        } else {
            System.debug('In saveCustomTopicLayout method...creating new Full Topic Template ');
            
            iahelp__HelpTopicTemplate__c newTopicTemplate = new iahelp__HelpTopicTemplate__c();
            
            newTopicTemplate.Name = newTemplateName;
            newTopicTemplate.iahelp__TemplateType__c = 'Full Topic';
            newTopicTemplate.iahelp__PageURL__c = layoutInfo;
            newTopicTemplate.iahelp__DefaultHeight__c = 600;
            
            Database.SaveResult insertHTT = Database.insert(newTopicTemplate, false);
            system.debug('In saveCustomTopicLayout method checking database operation result :'+insertHTT);
            if(insertHTT.isSuccess()){
                return '';
                
            } else {
                for(Database.Error err : insertHTT.getErrors()) {
                    System.debug('The following error has occurred.');                    
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    retVal += err.getStatusCode() + ': ' + err.getMessage();
                }
                return retVal;
            }
        }
    
    }
    

    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Tabs component support
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    
    // This method is called from IHTabs component to insert and delete tabs
    @AuraEnabled
    public static string SaveTabs(string toolContext , string toolType, string stringifiedCIList ,string newToolContext){ 

        string retVal = '';  
        
        // To save The changes in same toolContext.
        if(string.isEmpty(newToolContext)){  
            system.debug('SaveTabs() method firing!...stringifiedCIList '+stringifiedCIList);
            List<iahelp__ConfigurationItem__c> configItemList;
            // Fetching the ConfigurationItem records
            list<iahelp__ConfigurationItem__c> deleteConfigItemList = [select id from iahelp__ConfigurationItem__c 
                                                                       where iahelp__ToolContext__c =: toolContext and iahelp__Type__c =: toolType];
            if(deleteConfigItemList.size()>0 && deleteConfigItemList!=null){
                try{
                    delete deleteConfigItemList; // Delete existing ConfigurationItem records which meet the given criteria
                }
                catch(exception e){
                    retVal += 'Error deleting ConfigurationItem records : '+e; 
                }
            }
            
            //Preparing to upsert Configuration Item List
            //Deserializing Json string 
            Type idArrType = Type.forName('List<iahelp__ConfigurationItem__c>');
            configItemList = (List<iahelp__ConfigurationItem__c>) JSON.deserialize(stringifiedCIList, idArrType);
            if(configItemList.size() >0 && configItemList!=null){
                try{
                    upsert configItemList; // Insert and update ConfigurationItem records  
                }
                catch(exception e){
                    retVal += 'Error upserting ConfigurationItem records : '+e; 
                }
            }
            
        } else {
            // To create NewToolContext of same TabSet
            system.debug('SaveAsTabs() method firing!...newToolContext '+ newToolContext);

            // Fetching the ConfigurationItem records
            list<iahelp__ConfigurationItem__c> deleteConfigItemList = [select id from iahelp__ConfigurationItem__c 
                                                                       where iahelp__ToolContext__c =: newToolContext and iahelp__Type__c =: toolType];
            
            if(deleteConfigItemList.size()>0 && deleteConfigItemList!=null){
                try{
                    delete deleteConfigItemList; // Delete existing ConfigurationItem records which meet the given criteria
                }
                catch(exception e){
                    retVal += 'Error deleting ConfigurationItem records : '+e; 
                }
            }
            
            list<iahelp__ConfigurationItem__c> listNewConfigItem ;
            //Deserializing Json string 
            Type idArrType = Type.forName('List<iahelp__ConfigurationItem__c>');
            listNewConfigItem = (List<iahelp__ConfigurationItem__c>) JSON.deserialize(stringifiedCIList, idArrType); 
            if(listNewConfigItem.size() > 0 ){
                try{
                    insert listNewConfigItem; // Insert and update ConfigurationItem records  
                }
                catch(exception e){
                    retVal += 'Error upserting ConfigurationItem records : '+e; 
                }  
            }
        }
        
        return retVal;          
    }
    
    
    // This method is used to generate a copy of blank Tab 
    @AuraEnabled
    public static string getNewTab(){
         
        iahelp__ConfigurationItem__c CI = new iahelp__ConfigurationItem__c();
        map<string, string> mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false);
        
        CI.iahelp__ActionCode__c = 'SetTab';
        CI.iahelp__Description__c = 'This item represents the definition of a tab for use in a tabset';
        CI.iahelp__DisplayGrouping__c = '[Default]';
        CI.iahelp__DisplayOrder__c = 1;
        CI.iahelp__HasDivider__c = false;
        CI.iahelp__IconClass__c = 'fa-question';
        CI.iahelp__Label__c = 'Default Tab';
        CI.iahelp__MinimumFormFactor__c = '1 - Small';
        CI.iahelp__NegotiateToolbarLevel__c = 0;
        CI.iahelp__PermissionLevel__c = 1;
        CI.iahelp__SupportingControls__c = 'iahelp:IHDetail~Height¬-2';
        
        CI.iahelp__TipText__c = mapGlbLocs.get('AdviceLabelReadMoreLink');
        
        CI.iahelp__ToolClass__c = '';
        CI.iahelp__ToolContext__c = 'newDefaultTab';
        CI.iahelp__ToolFilter__c = 0;
        CI.iahelp__Type__c = 'WizardStep';
        CI.iahelp__ToggleNext__c = 0;
        CI.iahelp__TogglePrev__c = 0;
        
        return JSON.serialize(CI);
    }
    
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Private utilities
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    // Get a fomatted timestamp (string)
    private static string getTimeStamp() {
        return DateTime.now().format('kk:mm:ss') + ' - ';
    } 
    

    // Translate a number into its binary form  
    @TestVisible
    private static string DecToBin(Decimal Num) {
        string retVal = '';
        integer wrk = 0;
        integer i;

        if (Num <> 0) {
            while (Num > math.pow(2, wrk)) {
                wrk++;
            }
        } else {
            wrk = 0;
        }

        for (i = wrk; i >= 0; i--) {
            if (math.pow(2, i) <= Num) {
                retVal += '1';
                Num -= math.pow(2, i);
            } else {
                if (i <> wrk) {retVal += '0';}
            }           
        }

        return retVal;
    }
    
    //Update departure Time on help interaction record.
    @AuraEnabled
    global static String logLUXDepartureTime(String LogInteractionId){
        String retVal = '';
        iahelp__HelpInteraction__c HI = new iahelp__HelpInteraction__c(Id=LogInteractionId);
        HI.iahelp__DepartureDate__c = Datetime.now();
        
        try{
        update HI;
        retVal = '';     
        }catch(exception ex){
            retVal = 'ERROR :'+ex.getMessage();
            system.debug('ERROR '+ex);
        }
        return retVal;
    }
    
    //Updates the description with event summary and departure time  to help interaction record
    
    @AuraEnabled
    public static String updateInteractionDescription(String interactionId, String newDescription) {
       String retVal = '';
        iahelp__HelpInteraction__c HI = new iahelp__HelpInteraction__c(Id=interactionId);
        HI.iahelp__DepartureDate__c = Datetime.now();
        HI.iahelp__Description__c = newDescription;
        
        try{
        update HI;
        retVal = '';     
        }catch(exception ex){
            retVal = 'ERROR :'+ex.getMessage();
            system.debug('ERROR '+ex);
        }
        return retVal;
    }
	
    
      @AuraEnabled(cacheable=true)
    public static iahelp__IASetIHOrg__c getOrgSettings() {
        // Assuming only one settings record exists
        List<iahelp__IASetIHOrg__c> settings = [
            SELECT Id, iahelp__Geo_Timeout__c, iahelp__Geo_EnableHighAccuracy__c, iahelp__Location_Tracking__c
            FROM iahelp__IASetIHOrg__c
            LIMIT 1
        ];

        if (!settings.isEmpty()) {
            return settings[0];
        }

        // Return null if no settings found
        return null;
    }

    /////////////////////////////////////////////////////////////////////
    //Detail : Chat GPT API call method for zTest1 component (test phase) 
    //Date : 21/May/2024
    /////////////////////////////////////////////////////////////////////
   

}
