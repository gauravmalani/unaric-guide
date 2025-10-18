/////////////////////////////////////////////////////////////////////////////////////////////////////
// CONTROLLER AND PARSER FOR GENERIC FILTERING CONTROL
//
// Martin Little for Improved Apps
// December 2015
/////////////////////////////////////////////////////////////////////////////////////////////////////


public with sharing class ControllerOmniFilter {

/*    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // General interfaces
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    // Diagnostics messages
    public string Diags {get; set;}

    // Global settings info
    public static String getBrandCSS() {if (ControllerSettings.getSettings() != null) {return ControllerSettings.getSettings().BrandCSS__c;} else {return '';}}

    // Copy of this controller to make available for passing into the component - allowing
    // component meta data to become available outside the component itself on the hosting page
    public ApexPages.StandardController CTRL {get; set;}

    // For UI localisations /multi language support (labels, messages etc.)
    private map<string, string>mapDlgLocs;
    private map<string, string>mapGlbLocs;
    private map<string, string>mapBrdLocs;
    public map<string, string> getDialogueLocalisations() {
        return mapDlgLocs;
    }
    public map<string, string> getGlobalLocalisations() {
        return mapGlbLocs;
    }
    public map<string, string> getBrandingLocalisations() {
        return mapBrdLocs;
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Control UI options
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    // Switch controlling availability of filter selection / manipulation controls
    public boolean allowFltManipulation {get; set;}
    
    // Overall user permissions
    Boolean[] UPs;
    

    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Constructors and basic initialisation
    /////////////////////////////////////////////////////////////////////////////////////////////////////


    // Constructor - if using the component only
    public ControllerOmniFilter() {
        initialiseMemberData();
    }


    // Constructor - if using component and component data on wider page / if passing in CTRL controller parameter
    public ControllerOmniFilter(ApexPages.StandardController controller) {
        initialiseMemberData();        
        CTRL = controller;
    }

    
    // Constructor support
    public void initialiseMemberData() {
        Diags = '';
        FilterCriteria = new FilterCriterion[]{};
        objFields = new selectOption[]{};
        Filters = new selectOption[]{};
        OpsScope = 1;
        initialiseLocalisations();

        string FID = ServiceSecurity.getQueryParameter('FID', 1);
        FID = string.escapeSingleQuotes(FID);
        
        // Only attempt the getting of filters etc. if we are a help user of some kind
        ServiceSecurity Security = new ServiceSecurity();
        UPs = Security.UserPermissions();
                        
        // Treat lack of any permissions as a problem (as we must check FLS).
        // So: no Help Permission Set assisnments at all = same effect as no subscription...            
        if ((UPs[0] || UPs[1] || UPs[2] || UPs[3])) {
            try {
                HelpFilter__c HF = [SELECT Id, FilterIdentifier__c FROM HelpFilter__c WHERE Id=:FID];
                setFilterIdentifier(HF.FilterIdentifier__c);
            } catch (exception e) {}        
        } 
    } 


    // Internationalisation
    public void initialiseLocalisations() {
        // Get localisation information (field labels etc):
        // We need a mix of "global", "branding" and cross screen labels and those which are screen specific.
        
        try {               
            mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false);
            mapBrdLocs = ServiceLocalisation.getDialogueLocalisations('Branding', false);
            mapDlgLocs = ServiceLocalisation.getDialogueLocalisations('IHOmniFilter', false);
        } catch (exception e) {
            
        }
        return;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Filter information
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    // The collection of existing Filter Sets, available for pick lists, matching specified selection criteria
    public selectOption[] Filters {get; set;}                       
                    

    // Reference key of a set of pre-existing / already saved rules to retrieve for use
    private string FIdent;                                  // Private member for public interface
    public string FilterId {get; set;}                      // The record ID of this filter 
    public HelpFilter__c FLT {get; set;}                    // The filter itself
    public string getFilterIdentifier() {return FIdent;}    // Get filter set key

    public void setFilterIdentifier(string v) {                 // Set filter set key
//      
        // Anti injection:
        if (v != null) {
            v = string.escapeSingleQuotes(v);
        }
        
        try {
            // Ensure we haven't already done this - so as to avoid constant re-sets
            if (FIdent == null || CTRL != null) {

                // Attempt to locate the requested filter set
                FLT = [SELECT Id, FilterIdentifier__c, FilterLogic__c FROM HelpFilter__c WHERE FilterIdentifier__c = :v];
                
                // Set and show any required filtering logic
                if (FLT.FilterLogic__c != null && FLT.FilterLogic__c != '') {
                    FilterLogic = FLT.FilterLogic__c;
                    addLogic();
                }
                
                FIdent = FLT.FilterIdentifier__c;
                FilterId = FLT.Id; 
                FilterCriteria.clear();
                
                // If we're given a key, we should initialise to the relevant filter criteria
                for (HelpFilterCriterion__c Crits : [SELECT CriterionNumber__c, FilteredField__c, Operator__c, FilterValue__c 
                                        FROM HelpFilterCriterion__c
                                        WHERE HelpFilter__c = :FLT.Id
                                        ORDER BY CriterionNumber__c]) {
                                            
                    FilterCriterion crit = new FilterCriterion(); 
                    crit.CriterionNumber = Crits.CriterionNumber__c;
                    crit.FilteredField = Crits.FilteredField__c;
                    crit.Operator = Crits.Operator__c;
                    crit.FilterValue = Crits.FilterValue__c;
                    FilterCriteria.add(crit);               
                }           
                
            }           
            
            // All is well on reaching here...
            Diags = '';
            
        } catch (exception ex) {
            // Error implies the need for a new filter set:
            // However, we will create this only on saving. 
            // For now, just create a filtering row in our UI

            // Anti injection:
            if (v != null) {
                v = string.escapeSingleQuotes(v);
            } else {
                v = '';
            }
            
            Diags += 'Error setting Filter Identifier to "' + v + '": ' + ex.getMessage();
            FilterCriteria.clear();
            
            // Ensure key is not null to avoid repetition
            FIdent = v;
        }
//        
    }
      
    
    // Setter wrapper, allowing this to be called by a page on demand
    public PageReference setFID() {
        return navToFID(FilterId);
    }
    public PageReference navToFID(string Id) {
        Url U = Url.getCurrentRequestUrl();
        return new PageReference(Url.getSalesforceBaseUrl().toExternalForm() + U.getPath() + '?FID=' + Id + '&FOID=' + FilteredObjectIdentifier);
    }


    // Create a new filter 
    public PageReference addFilter() {
        
        // Check permissions
        ServiceSecurity Security = new ServiceSecurity();
        UPs = null;
        UPs = Security.UserPermissions();
        
        if (UPs[2] == false) {
            Diags = mapGlbLocs.get('MessageNoRights');
            return null;
        }
        
        HelpFilter__c HF = new HelpFilter__c();
        HF.FilteredObject__c = FilteredObjectAPIName;
        HF.FilteredObjectIdentifier__c = FilteredObjectIdentifier;
        
        // Set a temporary Filter set key
        HF.FilterIdentifier__c = '' + Math.random() * 1000000000;
        insert HF;
        
        HF.FilterIdentifier__c = HF.Id;
        update HF;          
        
        // Navigate to the new or existing filter set
        return navToFID(HF.Id);
        
    }
    
    
    // Rename or otherwise edit filter
    public PageReference updateFilter() {
        try {
            update FLT;
            
            // Navigate to amended filter set
            return navToFID(FLT.Id);

        } catch (exception e) {
            Diags = e.getMessage();
            return null;
        }
        
    }
    

    // Delete filter
    public PageReference deleteFilter() {
        try {
            delete FLT;
            
            // Navigate to amended filter set
            return navToFID(null);

        } catch (exception e) {
            Diags = e.getMessage();
            return null;
        }
        
    }
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Filtered object & fields information
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    
    private string FilteredObjectIdentifier;                                            // Private member for public interface
    private string FilteredObjectAPIName;                                               // Object API name
    public string FilteredObjectLabel {get; set;}                                       // Object (plural) label
    public string getFilteredObjectIdentifier() {return FilteredObjectIdentifier;}      // Get filtered object identifier (our 3 letter code etc)
    public void setFilteredObjectIdentifier(string v){                                  // Set filtered object identifier
        FilteredObjectIdentifier = string.escapeSingleQuotes(v);
        initialise();
    }
    
    private Map<String,Schema.SObjectField> FilteredObjectFieldsMap;                    // The fields of this object mapped by API name
    private selectOption[] objFields; 
    public selectOption[] getObjectFields() {return objFields;}                         // The fields of this object, available for use in criteria
    
    
    // Populate the list of fields for this object, unless this has been done already
    // Also, populate the list of filter sets defined for the current object
    private void initialise() {
        
        try {
            
            // Note: filter information only produced for users who have *some* IH permissions
            if (objFields.size() == 0 && (UPs[0] || UPs[1] || UPs[2] || UPs[3])) {    
                
                Schema.DisplayType FldType;
                string allowedTypes = '^BOOLEAN^CURRENCY^DATE^DATETIME^DOUBLE^EMAIL^ID^INTEGER^PHONE^PICKLIST^REFERENCE^STRING^TEXTAREA^URL^';
                ServiceSchema SS = new ServiceSchema();     
                Schema.DescribeSObjectResult oDesc = SS.getObjectDetails(FilteredObjectIdentifier);
                            
                FilteredObjectLabel = oDesc.getLabelPlural();
                FilteredObjectAPIName = oDesc.getName();            
                FilteredObjectFieldsMap = oDesc.Fields.getMap(); 
                                
                for (string fName : FilteredObjectFieldsMap.keySet()) {
                    
                    // Get type of each field
                    FldType = FilteredObjectFieldsMap.get(fName).getDescribe().getType();

                    // Add each field to pick list - but only if it's of a "filterable" type
                    if (allowedTypes.indexOf('^' + (FldType + '').toUpperCase() + '^') != -1) {
                        objFields.add(new selectOption(fName, FilteredObjectFieldsMap.get(fName).getDescribe().getLabel()));                        
                    }

                }

                
                // If we know the object we're dealing with, we can also retrieve the relevant filter sets
                for (HelpFilter__c HF : [SELECT Id, FilterIdentifier__c 
                                            FROM HelpFilter__c 
                                            WHERE FilteredObject__c = :FilteredObjectAPIName
                                            ORDER BY FilterIdentifier__c]) {
                    Filters.add(new SelectOption(HF.Id, HF.FilterIdentifier__c));
                }

            }
            
// SORT THIS PICK LIST!
objFields.sort();           
            
            
        } catch (exception ex) {
            FilteredObjectLabel = '';
            FilteredObjectAPIName = '';
            Diags += 'Error initialising: ' + ex.getMessage() + ' - ';
        }
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Class representation of a filter criteria
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    
    // Representation of an individual filter criterion object
    public class FilterCriterion {
        public decimal CriterionNumber {get; set;}
        public string FilteredField {get; set;}
        public string Operator {get; set;}
        public string FilterValue {get; set;}
    }

    // Collection of filters
    public FilterCriterion[] FilterCriteria {get; set;}
    
    // The Rules string
    public string FilterLogic {get; set;}
    
    // Flag noting we're using Rules
    public boolean hasFilterLogic {get; set;}
    
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Filter and rules manipulation
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    
    // Add a filter criterion
    public void addCriterion() {       
        
        try {

            initialise();
            
            FilterCriterion crit = new FilterCriterion();
            crit.CriterionNumber = FilterCriteria.size() + 1;
            crit.FilteredField = '';
            crit.Operator = '=';
            crit.FilterValue = '';
            FilterCriteria.add(crit);   
            
        } catch (exception ex) {
            
        }

        return; 
    }
    
    
    // Remove a filter criterion
    public void removeCriterion() {
        if (FilterCriteria.size() > 0) {
            FilterCriteria.remove(FilterCriteria.size() - 1);
        }
        
        // For filter logic to be available, there must be more than 1 filter in play
        if (FilterCriteria.size() == 1) {
            clearLogic();
        }
        
        return;
    }
    

    // Show filtering logic where >1 filter is available
    public void addLogic() {
        hasFilterLogic = true;
        return;
    }

    
    // Hide / remove filtering logic
    public void clearLogic() {
        FilterLogic = '';
        hasFilterLogic = false;
        return;
    }

    
    // Save all filter criteria as specified
    public void saveCriteria() {
        
        boolean isError = false;
        HelpFilter__c HF;
        HelpFilterCriterion__c Crit;
        HelpFilterCriterion__c[] Crits;
        
        Diags = '';
        
        
        // Check permissions to save
        ServiceSecurity Security = new ServiceSecurity();
        UPs = null;
        UPs = Security.UserPermissions();
        
        if (UPs[2] == false) {
            Diags = mapGlbLocs.get('MessageNoRights');
            return;
        }
        
        // Validate each filter row
        for (FilterCriterion f : FilterCriteria) {
            Diags += 'Validating filter ' + f.CriterionNumber + '... ';
        }
        
        // Validate rules, if these have been set
        if (hasFilterLogic == true) {
            Diags += 'Validating FilterLogic... ';
        }
        
        
        if (isError == false) {
            // Save filters if all is well:
            
            try {
                HF = [SELECT Id, FilterLogic__c, FilterIdentifier__c, FilteredObject__c FROM HelpFilter__c WHERE FilterIdentifier__c=:FIdent];
                
            } catch (exception ex) {
                HF = new HelpFilter__c();
                
                if (FIdent != null && FIdent != '') {
                    HF.FilterIdentifier__c = FIdent;
                } else {
                    Diags = 'Unable to save Filter Set without a Key';
                    return;
                }
                
                HF.FilteredObject__c = FilteredObjectAPIName;
            }
            
            // Keep a record of the filter set ID now associated with this control
            HF.FilterLogic__c = FilterLogic;
            upsert HF;
            FilterId = HF.Id;
            
            
            // Delete any existing filters
            try {
                Crits = [SELECT Id FROM HelpFilterCriterion__c WHERE HelpFilter__c = :FilterId];
                delete Crits;                
                
            } catch (exception ex) {
            }
            
            // Add back newly defined filters
            Crits = new HelpFilterCriterion__c[]{};
            for (FilterCriterion f : FilterCriteria) {
                Crit = new HelpFilterCriterion__c();
                
                Crit.HelpFilter__c = FilterId;
                Crit.CriterionNumber__c = f.CriterionNumber;
                Crit.FilteredField__c = f.FilteredField;
                Crit.FilteredFieldType__c = (FilteredObjectFieldsMap.get(f.FilteredField).getDescribe().getType() + '').toUpperCase();
                Crit.Operator__c = f.Operator;
                Crit.FilterValue__c = f.FilterValue;
                
                Crits.add(Crit);
                
            }
            
            upsert Crits;
            Diags = 'Filter Criteria saved: '+ Crits.size();
            
        } else {
            Diags = 'Unable to  save Filter Criteria: ' + Diags;
        }
        
        return;
    }
    
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Criteria validation and parsing
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    // Get SOQL SELECT clause for selected object
    public string getSelectClause() {
        
        string strSOQL = '';
        
        if (objFields.size() > 0) {
            strSOQL += 'SELECT ';
            
            // Add all fields to select list
            for (SelectOption SO : objFields) {
                strSOQL += string.escapeSingleQuotes(SO.getValue()) + ', ';
            }
            strSOQL = strSOQL.substring(0, strSOQL.length() - 2);
            
            // Add FROM clause based on object
            strSOQL += ' FROM ' + FilteredObjectAPIName;
            
        }
        
        return strSOQL;
    }

    
    // Given a collection of filters, build SOQL to return matching records - plus wrapper function for the same
    public string getFilterSOQL() {
        try {
            HelpFilter__c[] HFs = new HelpFilter__c[]{FLT}; 
            return getSOQLForFilters(HFs);
            
        } catch (exception ex) {
            return 'Error getting Filter: ' + ex.getMessage();
        }
    }
    public string getSOQLForFilters(HelpFilter__c[] HFs) {
        
        string retVal = '';
        string FIds = '';
        string FRule;
        HelpFilterCriterion__c[] FCrits;
        string currentFilter;

        
        try {
            // Get all criteria for all filters
            for (HelpFilter__c HF : HFs) {
                FIds += HF.Id + ',';
            }
                        
            FIds = FIds.substring(0, FIds.length() -1);
            
            HelpFilterCriterion__c[] Crits = [SELECT Id, HelpFilter__c, HelpFilter__r.FilterLogic__c, CriterionNumber__c, 
                                    FilteredField__c, FilteredFieldType__c, Operator__c, FilterValue__c
                                FROM HelpFilterCriterion__c
                                WHERE HelpFilter__c IN (:FIds)
                                ORDER BY HelpFilter__c, CriterionNumber__c];
            
            FCrits = new HelpFilterCriterion__c[]{};
    
            for (HelpFilterCriterion__c C : Crits) {
                // Loop around all criteria, adding to a "current" collection at each change of filter
                if (C.HelpFilter__c == currentFilter) {
                    FCrits.add(C);
                    
                } else {
                    // On each change of filter set, process the filters and rules...
                    if (FRule == null) {FRule = C.HelpFilter__r.FilterLogic__c;}
                    retVal += getSOQLForFilters(FCrits, FRule);             
                    
                    // ... having processed the current set, move on
                    FCrits = new HelpFilterCriterion__c[]{};
                    currentFilter = C.HelpFilter__c;   
                    FRule = C.HelpFilter__r.FilterLogic__c;                             
                    FCrits.add(C);
                }
            }
            
            // Process the final "current set"
            retVal += getSOQLForFilters(FCrits, FRule);
            
        } catch (exception ex) {
            retVal = 'Error getting SOQL for a Filter: ' + ex.getMessage();
        }
        
        return retVal;
    }
    
    
    // Get the filter SOQL implied by an individual filter's criteria and associated rule logic
    public string getSOQLForFilters(HelpFilterCriterion__c[] FCriteria, string FRule) {

        string retVal = '';
        string Delim1;
        string Delim2;
        string NotOp;
        string Op;
        string currentClause;
        
        
        for (HelpFilterCriterion__c F : FCriteria) {
            
            // Get delimiter for field represented by this rule
            string stringTypes = '^DATE^DATETIME^EMAIL^ID^PHONE^PICKLIST^REFERENCE^STRING^TEXTAREA^URL^';
            
            if (stringTypes.indexOf('^' + F.FilteredFieldType__c + '^') != -1) {
                Delim1 = '\'';              
            } else {
                Delim1 = '';                
            }
            
            // Add "like" handling
            if ((F.Operator__c == 'LIKE' || F.Operator__c == 'NOT LIKE') && Delim1 =='\'') {
                Delim1 = '\'%';
                Delim2 = '%\'';
            } else {
                Delim2 = Delim1;
            }
            
            // Add "NOT like" handling 
            if (F.Operator__c == 'NOT LIKE') {
                NotOp = '(NOT ';
                Op = 'LIKE';
                Delim2 += ')';
            } else {
                NotOp = '';
                Op = F.Operator__c;
            }
            
            // Add "Starts with" handling
            if (F.Operator__c == 'STARTS') {
                NotOp = '';
                Op = 'LIKE';
                Delim1 = '\'';
                Delim2 = '%\'';
            }
            
            
            // Build current filtering clause
            currentClause = NotOp + F.FilteredField__c + ' ' + Op + ' ' + Delim1 + F.FilterValue__c + Delim2;
            
            if (FRule != '' && FRule != null) {
                if (retVal == '') {retVal = FRule;}
                retVal = retVal.replace(F.CriterionNumber__c + '', currentClause);
                
            } else {
                retVal += currentClause + ' AND ';
            }           
        }
        
        if ((FRule == '' || FRule == null) && retVal.length() > 5) {retVal = retVal.substring(0, retVal.length() - 5);}
        
        return retVal;
    }
    
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Working set population based on filters
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    
    // The records that would be / have been retrieved based on the current filters and object
    public sObject[] WorkingSet {get; set;}

    // Identical records abstracted into search result objects for presentation
    public ControllerSearch.SearchResult[] FilterResults {get; set;}
    
    // API name of fields within results to use as search object's "Name", "Summary" and "Link" values
    private string NameField;
    private string SummaryField;
    private string LinkField;

    public string getNameField() {return NameField;} 
    public string getSummaryField() {return SummaryField;} 
    public string getLinkField() {return LinkField;} 

    public void setNameField(string v) {NameField = v;} 
    public void setSummaryField(string v) {SummaryField = v;} 
    public void setLinkField(string v) {LinkField = v;} 

 
    // Populate the working set based on current filters
    public void showResults() {
//      
        ControllerSearch.SearchResult sR;
        string strSOQL = '';
        
        try {
            initialise();
            strSOQL = getSelectClause();
                        
            if (strSOQL != '') {
                // Add WHERE clause based on filters
                strSOQL += ' WHERE ';
                strSOQL += getFilterSOQL();
                strSOQL += ' LIMIT 1000';
                Diags = strSOQL;        
                
                WorkingSet = database.query(strSOQL);       
                Diags = 'Retrieved ' + WorkingSet.size() + ' matching records';
                
                
                // Map this working set into search result objects
                FilterResults = new ControllerSearch.SearchResult[]{};
                for (sObject O : WorkingSet) {
                    sR = new ControllerSearch.SearchResult();
                    
                    sR.Id = O.Id;
                    
                    try {
                        if (NameField != null && NameField != '') {sR.Name = (string) O.get(NameField);}
                    } catch (exception exc) {
                        sR.Name = 'Name error: ' + exc.getMessage();
                    }
    
    
                    try {
                        if (SummaryField != null && SummaryField != '') {sR.Summary = (string) O.get(SummaryField);}
                    } catch (exception exc) {
                        sR.Summary = 'Summary error: ' + exc.getMessage();                  
                    }
    
                    try {
                        if (LinkField != null && LinkField != '') {sR.Link = (string) O.get(LinkField);}
                    } catch (exception exc) {
                        sR.Link = 'Link error: ' + exc.getMessage();
                    }
    
                    
                    FilterResults.add(sR);
                }
                
            } 
            
        } catch (exception ex) {
            Diags += ex.getMessage();
        }
//
        return;
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Working set manipulation / data maintenance operations
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    // Details of the subset of records selected from within the working set for manipulation
    public string SelectedRecordIds {get; set;}
    
    // Manipulation scope option (all working set records or selected items)
    public integer OpsScope {get; set;}
    
    // Get the set of records that are to be manipulated (working set or selected subset)
    private sObject[] getAffectedRecords() {

        sObject[] affectedRecords = null;
        
        // Records to be worked on depend on selected operation scope...
        if (OpsScope == 1) {
            // In this case, we're working on the full "working set"
            affectedRecords = WorkingSet;
        }

        if (OpsScope == 2) {
            // In this case, use selected records to form an IN clause
            string strSOQL = getSelectClause();
            
            // Incoming selected records will lack quotes (to avoid injection) so we process these in here
            string strSRs = string.escapeSingleQuotes(SelectedRecordIds);
            string[] SRs = strSRs.split(',');           
            strSOQL += ' WHERE Id IN (';
            for (string SR : SRs) {
                strSOQL += '\'' + string.escapeSingleQuotes(SR) + '\',';
            }
            strSOQL = strSOQL.substring(0, strSOQL.length() - 1) + ')';
            
            try {
                affectedRecords = Database.query(strSOQL);
                
            } catch (exception e) {
                Diags = 'No matching records in which to find / replace: ' + strSOQL;
            }
        }

        return affectedRecords;     
    }


    // Find values in current working set and replace them
    private string FRFindVal;
    private string FRReplaceVal;
    public string getFRFind() {return FRFindVal;}
    public string getFRReplace() {return FRReplaceVal;}
    public void setFRFind(string v) {FRFindVal = v;}
    public void setFRReplace(string v) {FRReplaceVal = v;}
    
    public void FindReplace() {
        
        string oldVal;
        string newVal;
        sObject[] affectedRecords = getAffectedRecords();
        if (affectedRecords == null) {return;}
        
        try {
            Diags = 'Find: ' + FRFindVal + ' - replace with: ' + FRReplaceVal + ' within ' + affectedRecords.size() + ' record(s)... ';
            
            try {
                for (sObject O : affectedRecords) {
                    oldVal = (string) O.get(NameField);             
                    newVal = oldVal.replaceAll(FRFindVal, FRReplaceVal);
                    
                    if (newVal != oldVal) {
                        O.put(NameField, newVal);
                        
                        Diags += newVal + '... ';
                    }
                }
                
                update affectedRecords;
                
            } catch (exception ex) {
                Diags = 'Error finding and replacing: ' + ex.getMessage();
            }
            
        } catch (exception e) {
            Diags = 'Error finding and replacing: ' + e.getMessage();
        }
    }
    

    // Conduct a bulk delete
    public void BulkDelete() {
        
        // Check permissions
        if (UPs[2] == false) {
            Diags = mapGlbLocs.get('MessageNoRights');
            return;
        }
        
        sObject[] affectedRecords = getAffectedRecords();
        if (affectedRecords == null) {return;}
                
        try {
            Diags = 'Deleting ' + affectedRecords.size() + ' records...';
            delete affectedRecords;
            
            // After a delete, we need to reset to no selected records and ops scope 1...
            SelectedRecordIds = '';
            OpsScope = 1;

        } catch (exception e) {
            Diags = 'Error attempting a bulk delete: ' + e.getMessage();
        }
        
        return;
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // PROTOTYPES - TO BE MOVED ELSEWHERE IN CODEBASE!! 
    // Disabled for v1.25
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    
    
    public ControllerSearch.SearchResult[] KeyWords {get; set;}
    
    // Populate keywords based on current working set
    public void showKeyWords() {
        
        ControllerSearch.SearchResult sR;           // A result in set returned
        string sDesc;                               // HT Description as plain (not rich) text
        string topicText;                           // Concatenation of all important text fields in topic
        string parsedText = ' ';                    // Non-noise words garnered from this
        string[] Kwds;                              // Array spilt from this
        string lastKwd;                             // Last keyword placed in return set
        integer ct = 1;                             // Number of times this keyword arose
        integer minCt = 1;                          // Minimum occurences of any keyword in set returned
        integer maxCt = 1;                          // Maximum occurences of any keyword in set returned
        integer numResults = 5;                     //
        
        String htmlPattern = '<(?i).*?>';       
        pattern htmlTags = pattern.compile(htmlPattern);
        matcher matchedHTML;
        
        
        if (WorkingSet == null) {
            Diags = 'No records selected';
            return;
        }
        
        Diags = '';     
        try {
            // Get topics from current working set 
            for (sObject O : WorkingSet) {

                // Get plain text of (rich text) description
                sDesc = (string) O.get('Description__c');
                
                if (sDesc != '' && sDesc != null) {
                    matchedHTML = htmlTags.matcher(sDesc);
                    sDesc = matchedHTML.replaceAll(' ');            
                }
                
                // Get the "text" of the selected topic (Name + Sumary + Description)
                topicText += ' ' + (string) O.get('Name') + ' ' + (string) O.get('Summary__c') + ' ' + sDesc;
                
                Diags += 'Obtained txt... ';
            }
            topicText = topicText.toUpperCase() + ' ';
            
            
            // Parse out non-alphas (numbers, punctuation):
            // Accept only 65 - 90 (A - Z) or 97 - 122 (a - z) or 32 (space)
            for (integer i=0; i < topicText.length(); i++) {
                if ((topicText.charAt(i) >= 65 && topicText.charAt(i) <= 90) || (topicText.charAt(i) >= 97 && topicText.charAt(i) <= 122) || topicText.charAt(i) == 32) {
                    // Character passes
                    parsedText += topicText.substring(i, i+1);
                } else {
                    parsedText += ' ';
                }
            }           
            parsedText += ' ';

            Diags += 'Parsed... ';
            
            // Parse out any noise words
            for (NoiseWords__c NW : [SELECT Id, Name FROM NoiseWords__c LIMIT 1000]) {
                parsedText = parsedText.replaceAll(' ' + NW.Name.toUpperCase() + ' ', ' ');
            } 
    
            // Split this by spaces & sort
            while (parsedText.indexOf('  ') != -1) {
                parsedText = parsedText.replaceAll('  ', ' ');
            }           
            Kwds = parsedText.split(' ');
            
            // Count these into an array of search results for page
            Kwds.sort();
            
            Diags += 'Noise removed... ';
            
            KeyWords = new ControllerSearch.SearchResult[]{};
            
            for (string K : Kwds) {
                if (lastKwd == K) {
                    // Duplicate - don't add:
                    // The last keyword added needs its count incrementing
                    ct += 1;
                    sR.Summary = ct + '';
                } else {
                    sR = new ControllerSearch.SearchResult();
                    sR.Name = K;
                    sR.Summary = '1';
                    KeyWords.add(sR);
                    ct = 1;
                }
                
                lastKwd = K;
            }
            
            Diags += 'Keyword objects created... ';
            
            // Now, for each result, set colour intensity: first get min and max occurences...
            sR = KeyWords[0];
            minCt = integer.valueOf(sR.Summary);
            for (ControllerSearch.SearchResult R : KeyWords) {
                if (integer.valueOf(R.Summary) > maxCt) {maxCt = integer.valueOf(R.Summary);}
                if (integer.valueOf(R.Summary) < minCt) {minCt = integer.valueOf(R.Summary);}
            }
            
            
            // ... then loop to set colour intensity as each item's percentage of max-min difference
            for (ControllerSearch.SearchResult R : KeyWords) {
                double d = ((double.valueOf(R.Summary) - minCt) / (maxCt - minCt)) * 255;
                d = 255 - d;
                R.Link = decToHex (integer.valueOf(d));
            }
            
            // Return top "n" results
            
            Diags = minCt + ':' + maxCt + ' - ' + parsedText;           
            Diags = 'Done';
            
        } catch (exception e) {
            Diags += 'Error obtaining keywords: ' + e.getMessage() + '(' + parsedText + ') ' + WorkingSet.size();
        }
        
        return;
    }
    
    
    // Mark selected keyowrds as noise
private string NoiseWords;
public void setNoiseWords(string v) {NoiseWords = v;}   
    public void MarkNoise() {
        Diags = NoiseWords;
        return;
    }
    
    
    // UTILITIES
    static String[] hexMap = '0123456789ABCDEF'.split('');  
    public static String decToHex(Integer x) {
        if(x == 0) return '00';

        String result = '';
        while (x != 0)
        {
            Integer modulus = Math.mod(x, 16);
            result = hexMap[modulus] + result;          
            x /= 16;
        }
        return result.length() == 1 ? '0' + result : result;
    }   

*/
        
}