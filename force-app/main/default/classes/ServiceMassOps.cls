/////////////////////////////////////////////////////////////////////////////////////////////////////
// CLASS FOR MASS UPDATING OF DATA USING BATCH API OPERATIONS 
//
// Martin Little for Improved Apps
// February 2013
/////////////////////////////////////////////////////////////////////////////////////////////////////

public with sharing class ServiceMassOps implements  Database.Batchable<sObject> {
    

    public final String Query;          // Data seletion query: the records to be affected
    public final String Field;          // In updates, the field to amend
    public final Decimal Value;         // In updates, the value to set

    public String Diags {get; set;}

    private String Op;                  // The type of data operation being performed
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Client entry points
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    
    // This constructor performs a bulk delete
    public ServiceMassOps(String q) {
        Diags = '';
        Query = q;      
        Op = 'Delete';
    }


    // This constructor performs a mass update
    public ServiceMassOps(String q, String f, Decimal v){
        Diags = '';
        Query = q; 
        Field = f;
        Value = v;
        Op = 'Update';
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Batchable implementation
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(Query);
    }


    public void execute(Database.BatchableContext BC, 
                       List<sObject> scope){
        try {
            if (scope.size() > 0) {

                Schema.SObjectType token = scope[0].Id.getSObjectType();
                Schema.DescribeSObjectResult dr = token.getDescribe();
                String objName = dr.getName();
    
                if (Op == 'Update') {
                    // Check user's update permissions on this object
                    if (Schema.getGlobalDescribe().get(objName).getDescribe().isUpdateable()) {
                        for(Sobject s : scope){
                            s.put(Field,Value);                 
                        }
                        update scope;                   
                    } else {
                        Diags = 'Error: access denied';
                    }
                }
                
                if (Op == 'Delete') {
                    // Check user's delete permissions on this object
                    if (Schema.getGlobalDescribe().get(objName).getDescribe().isDeletable()) {
                       delete scope;   
                       system.debug('delete1 scope ran successfully------------'+scope.size());
                       system.debug('print scope-----'+scope); 
                    } else {
                        Diags = 'Error: access denied';
                    }
                }
                
            }
            
        } catch (exception e) {
            Diags = e.getMessage();
        }
    }


    public void finish(Database.BatchableContext BC){

    }

}