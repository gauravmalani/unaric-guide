/////////////////////////////////////////////////////////////////////////////////////////////////////
// CONTROLLER CLASS FOR PAGES LOGGING COMMENTS
//
// Martin Little for Improved Apps 
// November 2012
/////////////////////////////////////////////////////////////////////////////////////////////////////

public with sharing class ControllerComments {

    // Global settings info - full URL of customer override stylesheet
    public static String getBrandCSS() {
        String retVal;
        
        if (ControllerSettings.getSettings() != null) {
            retVal = ControllerSettings.getSettings().BrandCSS__c;
        } else {
            retVal = '';
        } 
        return retVal;
    }
    //defining an public attribute to access branding in ControllerLUXops
   // public map<string,string> auraMapBrdLocs;

    // For UI localisations /multi language support (labels, messages etc)
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

    // Derived from request query string:
    public String IHContext {get; set;}                 // To provide the ability to localise CSS style 

    public String UserText {get; set;}                  // The user's comment
    public String DialogueTitle {get; set;}             // Title reflecting what one is commenting on
    public Boolean IsError {get; set;}                  // Control variable disabling certain items
    public String Diags {get; set;}                     // Diagnostics to present to user
    public Boolean isIH1UX {get; set;}                  // True if parameter passed to indicate viewing via the SF1 UX
    public Boolean isIHLUX {get; set;}                  // True if parameter passed to indicate viewing via the Lightning UX

    private String qHTID;                               // Help topic specified in query string
    private String qPL;                                 // Page layout specified in query string
    private String qRLID;                               // Reading List specified in query string
    private String PLID;                                // Ids derived from above
    private String HTID;                                // Ids derived from above
    private String RLID;                                // Ids derived from above
    
public String HelpTopicID;                              // It is used to store help topic Id
public string HelpTopicName;                            // It is used to store help topic Name 
public string RLName;                                   // It is used to store reading list Name
public string PageLayoutID;                             // It is used to store pagelayoutId 
public string pagelayoutName;                           // It is used to store help topic name related to page layout  
public Boolean IsAura;                                  // Flag check for aura call
public String RLVID;                                    // It is used to store reading list Id
public String helpPageLayoutId;                         // 


    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Page entry point - Set up member data, in particular on-screen messages etc
    /////////////////////////////////////////////////////////////////////////////////////////////////////
        
    public void initialise () {
        
        try {
            
            // Initialise to no errors 
            IsError = false;
            Diags = '';
            
            
            // Get incoming parameters
            qHTID = ServiceSecurity.getQueryParameter('HTID', 2); 
            qPL = ServiceSecurity.getQueryParameter('PL', 2);
            qRLID = ServiceSecurity.getQueryParameter('RLID', 2);  
            IHContext = ServiceSecurity.getQueryParameter('IHContext', 0);
           
            /*if (ApexPages.currentPage().getParameters().get('IH1UX') == 'true') {
               
                isIH1UX = true;
            } else {  
                isIH1UX = false;
            }
           
            if (ApexPages.currentPage().getParameters().get('IHLUX') == 'true') {
                isIHLUX = true;
            } else {
                isIHLUX = false;
            }*/

            // Get localisation information (field labels etc)
            ControllerSettings cS = new ControllerSettings();
            mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false);
            
            mapBrdLocs = ServiceLocalisation.getDialogueLocalisations('Branding', false);
         
            if (Test.isRunningTest()) {
                // Page address will not be "real" if we're in test mode, so hard wire dialogue name in these cases
                mapDlgLocs = ServiceLocalisation.getDialogueLocalisations('iahelp__IHComment', false);
            } else {
                mapDlgLocs = ServiceLocalisation.getDialogueLocalisations(cS.SFObjId(Url.getCurrentRequestUrl().toExternalForm()), true);
            }
             
            //when were are giving call from Aura component
            if(IsAura == true){  
      
                mapDlgLocs = ServiceLocalisation.getDialogueLocalisations('iahelp__IHComment', false);
            } 

            
            // Treat lack of any permissions as a problem (as we must check FLS).
            // So: no Help Permission Set assisnments at all = same effect as no subscription...
            ServiceSecurity Security = new ServiceSecurity();           
            Boolean[] UPs = Security.UserPermissions();
                    
            if (! (UPs[0] || UPs[1] || UPs[2] || UPs[3])) {
                Diags = mapGlbLocs.get('MessageNoPermissions');
                IsError = true;
                return;
            } 

            //new code
              if(qHTID == '' || qHTID == null){
                  if(HelpTopicID != null){
                      qHTID = HelpTopicID;
                  }
                
            }
            
            
            if(qRLID == '' || qRLID == null){
                  if(RLVID != null){
                      qRLID = RLVID;
                  }
                
            }
            if(qPL == '' || qPL == null){
                  if(PageLayoutID != null){
                      qPL = PageLayoutID;
                  }
                
            }
           
            // If we have no recognised parameters, disable comments
            if (qPL == '' && qHTID == '' && qRLID == '') {
                
                // Check first that we're not in SF1 - in which case, params come from record ID
                qHTID = ServiceSecurity.getQueryParameter('id', 2);
                if (qHTID == '') {
                    
                    DialogueTitle = mapDlgLocs.get('AdviceLabelFeatureNotAvailable');
                    //Diags = 'Layout / Topic not specified';
                    IsError = true;                 
                }
            }       
            
            
            // If we were given a help topic Id, we can use this directly to log comments:
            // However, we still look it up to get its name
            if (qHTID != '') {          
                HelpTopic__c Hlp = [SELECT Name FROM HelpTopic__c WHERE Id=:qHTID];
                HTID = Hlp.Id;
                PLID = null;
                              
                if (Schema.sObjectType.HelpTopic__c.fields.Name.isAccessible()) {
                    DialogueTitle = mapDlgLocs.get('TitleDialogueSubtitleTopic') + ': ' + Hlp.Name;
     
                } else {
                    DialogueTitle = '';
                }
                
                HelpTopicName = DialogueTitle; 
                
            }
    
    
            // If we were given a page layout, we need to look up its actual object, as we only
            // have a layout identifying string, not the actual SF ID.
            if (qPL != '') {
                HelpedPageLayout__c HPL = [SELECT Id, Name FROM HelpedPageLayout__c WHERE PageLayoutIdentifier__c=:qPL];
            
                HTID = null;
                PLID = HPL.Id;
                helpPageLayoutId = PLID;
           
                if (Schema.sObjectType.HelpedPageLayout__c.fields.Name.isAccessible()) {
                    DialogueTitle = mapGlbLocs.get('TitleDialogueSubtitleLayout') + ': ' + HPL.Name;
                } else {
                    DialogueTitle = '';
                    
                }
                pagelayoutName = DialogueTitle;
            }


            // If we were given a reading list Id, we can use this directly to log comments:
            // However, we still look it up to get its name
            if (qRLID != '') {
          
                HelpReadingList__c RL = [SELECT Id, Name FROM HelpReadingList__c WHERE Id=:qRLID];
                HTID = null;
                PLID = null;
                RLID = RL.Id;
               
                if (Schema.sObjectType.HelpReadingList__c.fields.Name.isAccessible()) {
                    DialogueTitle = mapGlbLocs.get('TitleSubtitleReadingLists') + ': ' + RL.Name;
                } else {
                    DialogueTitle = '';
                }
                RLName = DialogueTitle;
 
            }
         
                        
            return;
            
            
        } catch (exception e) {
       
            DialogueTitle = mapGlbLocs.get('MessageGenericError') + ' - ' + e.getMessage();
           
            //Diags = 'Error occurred when preparing to log a ' + SubjectForUser + ' comment';
            IsError = true;
            return;
        }
        
        
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Entry point / minimal initialisation for Lightning (as opposed to VF page) clients
    /////////////////////////////////////////////////////////////////////////////////////////////////////
        
    public void initialiseForLUX () {
    
        try {
            mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false);
            mapBrdLocs = ServiceLocalisation.getDialogueLocalisations('Branding', false);
            mapDlgLocs = ServiceLocalisation.getDialogueLocalisations('iahelp__IHComment', false);          
    
            ServiceSecurity Security = new ServiceSecurity();           
            Boolean[] UPs = Security.UserPermissions();
                    
            if (! (UPs[0] || UPs[1] || UPs[2] || UPs[3])) {
                Diags = mapGlbLocs.get('MessageNoPermissions');
                IsError = true;
            } else {
                IsError = false;
            }

        } catch (exception e) {
            IsError = true;
        }

        return;     
    } 

    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Log a comment (via the interaction controller class)
    /////////////////////////////////////////////////////////////////////////////////////////////////////
  
    public void logComment() {
        
        if(HelpTopicID != null){
            if(HTID == '' || HTID == null){
               
                HTID = HelpTopicID;
            }
              
            if(qHTID == '' || qHTID == null){
                      qHTID = HelpTopicID;
                      RLID = null;
            }

        }
        
        if(RLVID != null && RLVID != ''){
               if(RLID == '' || RLID == null){
               
                RLID = RLVID;
            }
               if(qRLID == '' || qRLID == null){
              
                      qRLID = RLVID;
                      HTID = null;      
            }

        }
        
        if(PageLayoutID != null){
            if(PLID == '' || PLID == null){
               
                PLID = PageLayoutID;
                
            }
              
            if(qHTID == '' || qHTID == null){
                      qPL = PageLayoutID;
                      RLID = null;
                      HTID = null; 
            }

        }
                       
        ServiceInteractions svsI = new ServiceInteractions();
        
        // Only allow logging when topic or helped element is known
        if (qHTID != '' || qPL != '' || qRLID != '') {
       
            // Only allow logging when a comment is entered
            if (UserText != '' && UserText != null) {
                  
                // NB: it is not possible to log comments against helped elements,
                // so whilst certain interactions may involve them, the relevant parameter
                // in the logging calls below is always null...
                 
                try {
                 /*
                    if (svsI.LogInteraction(2, UserText, null, PLID, null, HTID, RLID, null) == true) {
                        UserText = '';   
                        
                        // Success message comes from translations
                        Diags = mapDlgLocs.get('MessageCommentLogged');
                      
                        IsError = false;
                        
                    } else {
                        Diags = mapGlbLocs.get('MessageGenericError') + ' - ' + svsI.Diags;                 
                        IsError = true;
                        
                    } 
                    */
                      //success message
                      UserText = '';
                      Diags = mapDlgLocs.get('MessageCommentLogged');
                      IsError = false;
                } catch (exception e) {
                    DialogueTitle = mapGlbLocs.get('MessageGenericError') + ' - ' + e.getMessage();
                    //Diags = 'Error occurred when preparing to log a ' + SubjectForUser + ' comment';
                    IsError = true;
                    
                }  
                
            } else {
                // This is recoverable - no need to lock user out...
                Diags = mapDlgLocs.get('MessageCommentFailedBlank');
                IsError = false;
            }
            
        } else {
            // This is not recoverable - lock user out...
            Diags = mapDlgLocs.get('MessageCommentFailedParameters');
            IsError = true;
        }

        return; 
    }
        
        
    

}