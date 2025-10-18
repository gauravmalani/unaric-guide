/////////////////////////////////////////////////////////////////////////////////////////////////////
// Implemented this queueable class to automate initialise settings button,
// by converting @future methods from ServiceSchema.cacheObjectDetails and ControllerSettings.seedDocsFromUserDocAS
//
// Gaurav Patil for Unaric
// April 2025
/////////////////////////////////////////////////////////////////////////////////////////////////////


global class SeedDocsQueueable implements Queueable, Database.AllowsCallouts {
    
    private String actionType;
    private String xPath;
    public String Diags = '';
    private map<string, string>mapGlbLocs;
    
    
    // Constructor to handle multiple actions
    global SeedDocsQueueable(String actionType, String xPath) {
        this.actionType = actionType;
        this.xPath = xPath;
    }
    
    // Queueable Execution Method
    global void execute(QueueableContext context) {
        if (actionType == 'settings') {
            seedDocsFromUserDocAS(xPath);
        } else if (actionType == 'cacheObjects') {
            cacheObjectDetails();
        }
        else if (actionType == 'handleMetadata') {
            handleMetadata();
        }
    }
    
    
    public void seedDocsFromUserDocAS(String XPath) {
        ControllerSettings CS;
        try {
            CS = new ControllerSettings();  
            CS.seedDocumentation(XPath);
        } catch (exception e) {
            if (CS != null) {
                system.debug('Error running Help content upload (seedDocsFromUserDocAS): ' + e.getMessage() + ': ' + CS.Diags);        
            } else {
                system.debug('Error running Help content upload (seedDocsFromUserDocAS): ' + e.getMessage());        
            }
        }
    }
    
    public void handleMetadata() { 
        string mData = ServiceSchema.getCustomObjects();
        if (mData.startsWith('Error')) {
            Diags += 'Failed obtaining custom object metadata for this org: ' + mData + '... ';     
            
        }
        else {
            string chunkResult = ControllerSettings.chunkAndStoreMetadata(mData, 'GetCustomObjectMetadata');
            
            if (chunkResult == '') {
                // All is well
                Diags += 'Custom object metadata obtained... ';             
            }
            else {
                Diags += 'Failed storing custom object metadata for this org: ' + chunkResult + '... ';     
            }
            
        }
        
    }
    
    
    public static void cacheObjectDetails() {
        string objJSON;
        map<string, string> mapObjs = new map<string, string>();
        Map<String, Schema.SObjectType> gd;
        
        try {
            gd = Schema.getGlobalDescribe();
            
            for (Schema.SObjectType stype : gd.values()) {
                Schema.DescribeSObjectResult r = stype.getDescribe();
                
                if (r != null) {
                    String prefix = r.getKeyPrefix();
                    
                    if (prefix != null) {
                        // Add mapping if no duplicates
                        try {
                            mapObjs.put(prefix, stype + '');
                        } catch (Exception ex) {
                            // Ignore duplicate errors
                        }
                    }
                }
            }
            
            objJSON = JSON.serialize(mapObjs);
            ControllerSettings.chunkAndStoreMetadata(objJSON, 'GetObjectDetails');
            
        } catch (Exception e) {
            System.debug('Error in cacheObjectDetails: ' + e.getMessage());
        }
    }
}