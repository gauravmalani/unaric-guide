/////////////////////////////////////////////////////////////////////////////////////////////////////
// CONTROLLER CLASS FOR THE COMMON EDITING CONTROLS INCLUDE PAGE, IHEditingTools
//
// Martin Little for Improved Apps
// August 2013
/////////////////////////////////////////////////////////////////////////////////////////////////////

public with sharing class ControllerIHEditingTools {
    
    public Boolean isUser {get; set;}
    public Boolean isAuthor {get; set;}
    public Boolean isAdministrator {get; set;}
    public Boolean isAnalysis {get; set;}
    public Boolean isSeated {get; set;}
    
    // For UI localisations /multi language support (labels, messages etc)
    private map<string, string>mapGlbLocs;
    public map<string, string> getGlobalLocalisations() {
        return mapGlbLocs;
    }
    
    
    // Initialisation checks user permissions and makes these available
    // NB: cannot put this in constructor, as this will not be called in an INCLUDE situation
    public void initialise() {
        
        ServiceSecurity sS = new ServiceSecurity();
        Boolean[] Perms = sS.UserPermissions();
        
        isUser = Perms[0];
        isAuthor = Perms[1];
        isAdministrator = Perms[2];
        isAnalysis = Perms[3];
        
        isSeated = sS.IsSeated();

        // Get localisation information (field labels etc):
        mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false);                 
        return;
    }
    
}