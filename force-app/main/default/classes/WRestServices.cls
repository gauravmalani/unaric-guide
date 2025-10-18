/////////////////////////////////////////////////////////////////////////////////////////////////////
// REST WEB SERVICE EXPOSING KEY FEATURES OF IMPROVED HELP'S SF LOGIC TO REST CLIENTS
// DESIGN PRINCIPLES APPLICABLE TO THIS SERVICE:
//
//      - This class should act as a wrapper to others, rather than implementing complex business logic
//      - Request paths are relative to: https://ihdev-dev-ed.my.salesforce.com/services/apexrest/
//      -       eg: https://ihdev-dev-ed.my.salesforce.com/services/apexrest/HelpSettings/
//
// Martin Little for Improved Apps
// June 2021
/////////////////////////////////////////////////////////////////////////////////////////////////////

@RestResource(urlMapping='/HelpSettings/*')
global with sharing class WRestServices {


    @HttpGet
    global static string getHelpSettings() {
        
        string retVal;

        try {
            map<string, string> Parms = RestContext.request.params;       
            ControllerSettings cS = new ControllerSettings();   
            
            // Seems webservice strings strip out unprintables - so we'll have to replace them here
            String D0 = String.fromCharArray(new List<integer>{6});
            string D0R = '{D0}';
            string D1R = '{D1}';
            string D2R = '{D2}';
            
            retVal = cS.getIHSettings(Parms.get('IHContext'));     
              
            retVal = retVal.replaceAll(D0, D0R);
            retVal = retVal.replaceAll(ControllerSettings.D1, D1R);
            retVal = retVal.replaceAll(ControllerSettings.D2, D2R);
            
            
        } catch (exception ex) {
            retVal = 'ERROR: ' + ex.getMessage() + ': ' + retVal;
        }
        
        return retVal;      

    }
    
    
    
    @HttpPost
    global static string getHelpTopic(string HTID) {

        string retVal;
        
        try {
            ControllerHelpContent CH = new ControllerHelpContent(true);
            
            // We don't want to call GetHelp as this is rather "weighty" for our needs:
            // Instead, just get the required topic in these cases
            CH.getTopicViaHTID(HTID, false);            
            
            retVal = JSON.serialize(CH.Hlp);
            
        } catch (exception ex) {
            retVal = 'ERROR: ' + ex.getMessage() + ': ' + retVal;
        }
        
        return retVal;      
        
    }
       
    
}