/////////////////////////////////////////////////////////////////////////////////////////////////////
// CLASS FOR CHECKING PERMISSIONS AND CONTROLLING ACCESS
//
// Martin Little for Improved Apps
// July 2012
/////////////////////////////////////////////////////////////////////////////////////////////////////


public with sharing class ServiceSecurity {
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Diagnostics and support  
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    public String Diags {get; set;} 
    public boolean retainDiags {get; set;}
   
    
    
    
    // Wrapper allowing access to FLS diagnostics from VF test page
    public pageReference FLSCheck() {
        retainDiags = true;
        Boolean B = meetsFLSRequirements(KnownSecureOperations.AdministerHelp);
        retainDiags = false;
        return null;
    }
    
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // The set of operations that the security service knows how to vet on behalf of the caller
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    public enum KnownSecureOperations {
        AdministerHelp,
            AnalyseHelp,
            EditHelp,
            UseHelp
            }
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    //Function call used to check whether geo tracking switched on
    //////////////////////////////////////////////////////////////////////////////////////////////////////
     @AuraEnabled(cacheable=true)
    public static Boolean isGeoEnabled(){
        Boolean retVal;
        try {
            // Check if the current user has the 'iahelp.Track_Interaction_Geolocation' custom permission
            if (FeatureManagement.checkPermission('Track_Interaction_Geolocation')) {
                retVal = true;
            } else {
                retVal = false;
            }
        } catch (Exception e) {
            // Default to "safe" position: user does not have this permission
            // Diags = e.getMessage();
            retVal = false;
        }
        return retVal;
    }
    
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Function call used to check whether a given operation is allowed for the current user / context
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    public Boolean IsAllowed(KnownSecureOperations Op) {
        
        try {
            Diags = '';
            //Allow when Package installing via post install script
            if (isInstalling()) {
                return true;
            } else{
                return meetsFLSRequirements(Op);
            }
            
            
        } catch (exception e) {
            // Error - default to not allowed
            Diags = 'Error (IsAllowed): ' + e.getMessage();
            return false;           
        }
        
    }
    
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Returns a flag indicating whether user has been marked with an IH type (& thus counted as a seat)
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    public Boolean IsSeated () {
        Boolean retVal;
        
        try {
            Diags = '';
            
            // Seat assignment is on the basis of whether user has an IH user type marked
            // on their user account...
            String userId = UserInfo.getUserId();
            User U = [SELECT Id, iahelp__ImprovedHelpUserType__c FROM User WHERE Id = :userId];
            retVal = (U.iahelp__ImprovedHelpUserType__c != '' && U.iahelp__ImprovedHelpUserType__c != null);
            
        } catch (exception e) {
            // Default to "safe" position: no seat allocated
            Diags = e.getMessage();
            retVal = false;
        }
        
        return retVal;
    }
    
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Returns a flag indicating whether user has the standard SF "Customise Application" permission
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    public Boolean IsSFCustomiser () {
        Boolean retVal = false;
        String userId = UserInfo.getUserId();
        
        try {
            Diags = '';
            
            User U = [
                SELECT Id 
                FROM User 
                WHERE Profile.PermissionsCustomizeApplication = true
                AND Id = :userId];
            
            // If you get here, the SOQL returned a row, so you have the permission
            retVal = true;
            
        } catch (exception e) {
            // Default to "safe" position: user does not have this permission
            Diags = e.getMessage();
        }
        
        
        // If you don't appear to have the permission at this stage, check via permission set assignments
        // as opposed to rights afforded directly by profile
        if (retVal == false) {
            try { 
                PermissionSetAssignment PSA = [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :userId AND PermissionSet.PermissionsCustomizeApplication = true];
                retVal = true;
                
            } catch (exception e) {
                // Default to "safe" position: user does not have this permission
            }           
        }
        
        
        return retVal;
    }
    
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Returns a flag indicating whether user has rights to run reports
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    public static Boolean CanRunReports () {
        Boolean retVal;
        
        try {            
            String userId = UserInfo.getUserId();
            User U = [
                SELECT Id 
                FROM User 
                WHERE Profile.PermissionsRunReports = true
                AND Id = :userId];
            
            // If you get here, the SOQL returned a row, so you have the permission
            retVal = true;
            
        } catch (exception e) {
            // Default to "safe" position: user does not have this permission
            //Diags = e.getMessage();
            retVal = false;
        }
        
        return retVal;
    }
    
    //checking the custom setting for allowing userpermissions
    public static Boolean isInstalling() {
        iahelp__OnInstall__c setting = iahelp__OnInstall__c.getOrgDefaults();
        return (setting != null && setting.iahelp__isInstalling__c == true);
    }

    

    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Returns a set of boolean flags indicating which effective Help permissions current user has:
    // Elements of return array are:
    //      0 - User
    //      1 - Author
    //      2 - Admin
    //      3 - Analyst
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    
    public Boolean[] UserPermissions () {
        
        String userId;
        Boolean[] retVal = new Boolean[] {false, false, false, false};
            Integer i;
        
        try {
            Diags = '';
            
            if (isInstalling()) {
                return new Boolean[] {true, true, true, true};
                    }
            else{
                retVal[2] = meetsFLSRequirements(KnownSecureOperations.AdministerHelp);
                if (retVal[2] == true) {
                    retVal[0] = true;
                    retVal[1] = true;
                    retVal[3] = true;
                    return retVal;                      
                }
                
                retVal[1] = meetsFLSRequirements(KnownSecureOperations.EditHelp);
                if (retVal[1] == true) {
                    retVal[0] = true;
                    retVal[3] = true;
                    return retVal;                      
                }
                
                retVal[3] = meetsFLSRequirements(KnownSecureOperations.AnalyseHelp);                    
                if (retVal[3] == true) {
                    retVal[0] = true;
                    return retVal;
                }
                
                retVal[0] = meetsFLSRequirements(KnownSecureOperations.UseHelp);
            }
            
            return retVal;
            
            
        } catch (exception e) {
            // Error - default to not allowed
            Diags = e.getMessage();
            retVal = new Boolean[] {false, false, false, false};
                
                }
        
        return retVal;              
        
    }
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Check current user has required FLS for a given permission / Op
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    
    public Boolean meetsFLSRequirements(KnownSecureOperations Op) {
        
        boolean retVal;
        
        Diags = '';
        
        // v.1.31 - adding object level access checks (in addition to existing field checks)
        
        try {
            if (Op == KnownSecureOperations.UseHelp) {
                retVal = true;          
                
                retVal = retVal && Schema.sObjectType.ConfigurationItem__c.fields.Name.isAccessible();
                retVal = retVal && Schema.sObjectType.ConfigurationItem__c.fields.CreatedById.isAccessible();
                retVal = retVal && Schema.sObjectType.ConfigurationItem__c.fields.LastModifiedById.isAccessible();
                retVal = retVal && Schema.sObjectType.ConfigurationItem__c.fields.OwnerId.isAccessible();
                retVal = retVal && Schema.sObjectType.ConfigurationItem__c.fields.ActionCode__c.isAccessible();
                retVal = retVal && Schema.sObjectType.ConfigurationItem__c.fields.Description__c.isAccessible();
                retVal = retVal && Schema.sObjectType.ConfigurationItem__c.fields.DisplayGrouping__c.isAccessible();
                retVal = retVal && Schema.sObjectType.ConfigurationItem__c.fields.DisplayOrder__c.isAccessible();
                retVal = retVal && Schema.sObjectType.ConfigurationItem__c.fields.HasDivider__c.isAccessible();
                retVal = retVal && Schema.sObjectType.ConfigurationItem__c.fields.IconClass__c.isAccessible();
                retVal = retVal && Schema.sObjectType.ConfigurationItem__c.fields.IconContent__c.isAccessible();
                retVal = retVal && Schema.sObjectType.ConfigurationItem__c.fields.Label__c.isAccessible();
                retVal = retVal && Schema.sObjectType.ConfigurationItem__c.fields.MinimumFormFactor__c.isAccessible();
                retVal = retVal && Schema.sObjectType.ConfigurationItem__c.fields.NegotiateToolbarLevel__c.isAccessible();
                retVal = retVal && Schema.sObjectType.ConfigurationItem__c.fields.PermissionLevel__c.isAccessible();
                retVal = retVal && Schema.sObjectType.ConfigurationItem__c.fields.SupportingControls__c.isAccessible();
                retVal = retVal && Schema.sObjectType.ConfigurationItem__c.fields.TipText__c.isAccessible();
                retVal = retVal && Schema.sObjectType.ConfigurationItem__c.fields.ToggleActiveMarker__c.isAccessible();
                retVal = retVal && Schema.sObjectType.ConfigurationItem__c.fields.ToggleNext__c.isAccessible();
                retVal = retVal && Schema.sObjectType.ConfigurationItem__c.fields.TogglePrev__c.isAccessible();
                retVal = retVal && Schema.sObjectType.ConfigurationItem__c.fields.ToolClass__c.isAccessible();
                retVal = retVal && Schema.sObjectType.ConfigurationItem__c.fields.ToolContext__c.isAccessible();
                retVal = retVal && Schema.sObjectType.ConfigurationItem__c.fields.ToolFilter__c.isAccessible();
                retVal = retVal && Schema.sObjectType.ConfigurationItem__c.fields.Type__c.isAccessible();
                Diags += 'FLS User: Configuration Items: ' + retVal + '... ';
                
                retVal = retVal && Schema.sObjectType.HelpBookmark__c.isCreateable();
                retVal = retVal && Schema.sObjectType.HelpBookmark__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpBookmark__c.isDeletable();
                retVal = retVal && Schema.sObjectType.HelpBookmark__c.fields.CreatedById.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpBookmark__c.fields.Name.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpBookmark__c.fields.LastModifiedById.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpBookmark__c.fields.OwnerId.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpBookmark__c.fields.HelpBookmarkLabel__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpBookmark__c.fields.HelpTopic__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpBookmark__c.fields.TopicURL__c.isAccessible();
                Diags += 'FLS User: Help Bookmarks: ' + retVal + '... ';
                
                //implemented in v1.56 
                retVal = retVal && Schema.sObjectType.HelpInteraction__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpInteraction__c.fields.CreatedById.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpInteraction__c.fields.LastModifiedById.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpInteraction__c.fields.Name.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpInteraction__c.fields.OwnerId.isAccessible();  
                
                retVal = retVal && Schema.sObjectType.HelpInteraction__c.fields.Browser__c.isAccessible();
                
                retVal = retVal && Schema.sObjectType.HelpInteraction__c.fields.ComponentId__c.isAccessible();                
                retVal = retVal && Schema.sObjectType.HelpInteraction__c.fields.Context__c.isAccessible();
                
                retVal = retVal && Schema.sObjectType.HelpInteraction__c.fields.ContextLink__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpInteraction__c.fields.ContextObjectLabel__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpInteraction__c.fields.ContextObjectName__c.isAccessible();
                
                //Added v1.55
                retVal = retVal && Schema.sObjectType.HelpInteraction__c.fields.Accuracy__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpInteraction__c.fields.Altitude__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpInteraction__c.fields.Context_List_View_Name__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpInteraction__c.fields.DepartureDate__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpInteraction__c.fields.Geolocation__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpInteraction__c.fields.TimeAtContext__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpInteraction__c.fields.UserAgent__c.isAccessible();
                
                //Added v1.56
                retVal = retVal && Schema.sObjectType.HelpInteraction__c.fields.Record_Name__c.isUpdateable();
                
                
                retVal = retVal && Schema.sObjectType.HelpInteraction__c.fields.CreatedDateTime__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpInteraction__c.fields.Description__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpInteraction__c.fields.HelpedElement__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpInteraction__c.fields.HelpedPageLayout__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpInteraction__c.fields.HelpInteractionType__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpInteraction__c.fields.HelpReadingList__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpInteraction__c.fields.HelpResource__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpInteraction__c.fields.HelpTopic__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpInteraction__c.fields.HelpVoteOption__c.isAccessible();
                
                retVal = retVal && Schema.sObjectType.HelpInteraction__c.fields.HourCreated__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpInteraction__c.fields.Platform__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpInteraction__c.fields.UITheme__c.isAccessible();
                
                Diags += 'FLS User: Help Interactions: ' + retVal + '... ';
                
                retVal = retVal && Schema.sObjectType.HelpReadingList__c.fields.CreatedById.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpReadingList__c.fields.Name.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpReadingList__c.fields.LastModifiedById.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpReadingList__c.fields.OwnerId.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpReadingList__c.fields.Active__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpReadingList__c.fields.Description__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpReadingList__c.fields.FeaturedUntil__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpReadingList__c.fields.LightningPresentationStyle__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpReadingList__c.fields.NumberofEntries__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpReadingList__c.fields.ReadingListStatus__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpReadingList__c.fields.ReadingListType__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpReadingList__c.fields.Summary__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpReadingList__c.fields.Visibility__c.isAccessible();
                Diags += 'FLS User: Help Reading Lists: ' + retVal + '... ';
                
                retVal = retVal && Schema.sObjectType.HelpReadingListEntry__c.fields.CreatedById.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpReadingListEntry__c.fields.DisplayColumn__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpReadingListEntry__c.fields.DisplayRow__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpReadingListEntry__c.fields.Name.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpReadingListEntry__c.fields.LastModifiedById.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpReadingListEntry__c.fields.HelpReadingList__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpReadingListEntry__c.fields.HelpTopic__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpReadingListEntry__c.fields.NavigationDetails__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpReadingListEntry__c.fields.NavigationType__c.isAccessible();                
                retVal = retVal && Schema.sObjectType.HelpReadingListEntry__c.fields.ReadingListFeaturedUntil__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpReadingListEntry__c.fields.ReadingOrder__c.isAccessible();
                Diags += 'FLS User: Reading List Entries: ' + retVal + '... ';
                
                retVal = retVal && Schema.sObjectType.HelpRelationship__c.fields.CreatedById.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpRelationship__c.fields.Name.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpRelationship__c.fields.LastModifiedById.isAccessible();                
                retVal = retVal && Schema.sObjectType.HelpRelationship__c.fields.Order__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpRelationship__c.fields.ReferringTopic__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpRelationship__c.fields.RelatedHelpTopic__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpRelationship__c.fields.SemanticTag__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpRelationship__c.fields.SemanticTagIsBlank__c.isAccessible();
                Diags += 'FLS User: Help Relationships: ' + retVal + '... ';
                
                retVal = retVal && Schema.sObjectType.HelpResource__c.fields.CreatedById.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpResource__c.fields.Name.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpResource__c.fields.LastModifiedById.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpResource__c.fields.OwnerId.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpResource__c.fields.Location__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpResource__c.fields.Preview__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpResource__c.fields.PreviewURL__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpResource__c.fields.RelatedHelpTopics__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpResource__c.fields.ResourceType__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpResource__c.fields.ResourceURL__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpResource__c.fields.Summary__c.isAccessible();
                Diags += 'FLS User: Resources: ' + retVal + '... ';
                
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.CreatedById.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.Name.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.LastModifiedById.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.OwnerId.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.Active__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.CalloutHeight__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.CalloutMediaChoice__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.CalloutTemplate__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.CustomStyle__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.Description__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.DescriptionText1__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.DescriptionText2__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.DescriptionText3__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.DescriptionText4__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.DescriptionText5__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.HeightBeforeScrolling__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.HelpTopicStatus__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.HelpVoteSet__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.ImageALTText__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.ImageCaption__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.ImageHeight__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.ImageListIcon__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.ImageTitle__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.ImageURL__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.ImageWidth__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.Keyword__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.KeywordPhraseLength__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.LightningTemplate__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.MasterTopicIdentifier__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.SalesforceHelpURL__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.GuideCallout__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.ShowReadMoreLink__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.ShowReferringRelationships__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.GuidedRecord__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.GuidedElement__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.GuidedLayout__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.GuideStepMode__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.Summary__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.Template__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.Thumbnail__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.VideoCaption__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.VideoHeight__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.VideoTitle__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.VideoURL__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.VideoWidth__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.ViewInPortalLink__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.Visibility__c.isAccessible();
                Diags += 'FLS User: Topics: ' + retVal + '... ';
                
                retVal = retVal && Schema.sObjectType.HelpTopicResource__c.fields.CreatedById.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopicResource__c.fields.Name.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopicResource__c.fields.LastModifiedById.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopicResource__c.fields.HelpResource__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopicResource__c.fields.HelpTopic__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopicResource__c.fields.UsageNotes__c.isAccessible();
                Diags += 'FLS User: Topic Resources: ' + retVal + '... ';
                
                retVal = retVal && Schema.sObjectType.HelpTopicTemplate__c.fields.CreatedById.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopicTemplate__c.fields.Name.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopicTemplate__c.fields.LastModifiedById.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopicTemplate__c.fields.OwnerId.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopicTemplate__c.fields.DefaultHeight__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopicTemplate__c.fields.Description__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopicTemplate__c.fields.PageURL__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpTopicTemplate__c.fields.TemplateType__c.isAccessible();
                Diags += 'FLS User: Topic Templates: ' + retVal + '... ';
                
                retVal = retVal && Schema.sObjectType.HelpVoteOption__c.fields.CreatedById.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpVoteOption__c.fields.Name.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpVoteOption__c.fields.LastModifiedById.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpVoteOption__c.fields.DisplayOrder__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpVoteOption__c.fields.HelpVoteSet__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpVoteOption__c.fields.ImageClass__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpVoteOption__c.fields.ImagePreview__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpVoteOption__c.fields.OptionColour__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpVoteOption__c.fields.OptionLabel__c.isAccessible();
                Diags += 'FLS User: Vote Options: ' + retVal + '... ';
                
                retVal = retVal && Schema.sObjectType.HelpVoteSet__c.fields.CreatedById.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpVoteSet__c.fields.Name.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpVoteSet__c.fields.LastModifiedById.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpVoteSet__c.fields.OwnerId.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpVoteSet__c.fields.ImageClass__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpVoteSet__c.fields.ImagePreview__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpVoteSet__c.fields.QuestionText__c.isAccessible();
                Diags += 'FLS User: Vote Sets: ' + retVal + '... ';
                
                retVal = retVal && Schema.sObjectType.HelpableSignature__c.fields.CreatedById.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpableSignature__c.fields.Name.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpableSignature__c.fields.LastModifiedById.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpableSignature__c.fields.OwnerId.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpableSignature__c.fields.Description__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpableSignature__c.fields.Domain__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpableSignature__c.fields.HelpStyle__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpableSignature__c.fields.Identifier__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpableSignature__c.fields.IdentifierType__c.isAccessible();
                Diags += 'FLS User: Signatures: ' + retVal + '... ';
                
                retVal = retVal && Schema.sObjectType.HelpedElement__c.fields.CreatedById.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpedElement__c.fields.Name.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpedElement__c.fields.LastModifiedById.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpedElement__c.fields.OwnerId.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpedElement__c.fields.DataDrivenFilter__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpedElement__c.fields.ElementType__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpedElement__c.fields.HasDDF__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpedElement__c.fields.HelpedPageLayout__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpedElement__c.fields.HelpFilter__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpedElement__c.fields.FilterIdentifier__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpedElement__c.fields.HelpTopic__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpedElement__c.fields.Identifier__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpedElement__c.fields.Parameters__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpedElement__c.fields.UseForNew__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpedElement__c.fields.Visibility__c.isAccessible();
                Diags += 'FLS User: Helped Elements: ' + retVal + '... ';
                
                retVal = retVal && Schema.sObjectType.HelpFilter__c.fields.CreatedById.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpFilter__c.fields.Name.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpFilter__c.fields.LastModifiedById.isAccessible();             
                retVal = retVal && Schema.sObjectType.HelpFilter__c.fields.OwnerId.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpFilter__c.fields.FilteredObject__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpFilter__c.fields.FilteredObjectIdentifier__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpFilter__c.fields.FilterIdentifier__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpFilter__c.fields.FilterLogic__c.isAccessible();
                Diags += 'FLS User: Help Filters: ' + retVal + '... ';
                
                retVal = retVal && Schema.sObjectType.HelpFilterCriterion__c.fields.CreatedById.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpFilterCriterion__c.fields.Name.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpFilterCriterion__c.fields.LastModifiedById.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpFilterCriterion__c.fields.HelpFilter__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpFilterCriterion__c.fields.CriterionNumber__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpFilterCriterion__c.fields.FilteredField__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpFilterCriterion__c.fields.FilteredFieldType__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpFilterCriterion__c.fields.FilterValue__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpFilterCriterion__c.fields.Operator__c.isAccessible();
                Diags += 'FLS User: Filter Criteria: ' + retVal + '... ';
                
                retVal = retVal && Schema.sObjectType.HelpedPageLayout__c.fields.CreatedById.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpedPageLayout__c.fields.Name.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpedPageLayout__c.fields.LastModifiedById.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpedPageLayout__c.fields.OwnerId.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpedPageLayout__c.fields.AllowComments__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpedPageLayout__c.fields.PageLayoutIdentifier__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpedPageLayout__c.fields.PageType__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpedPageLayout__c.fields.RehookInterval__c.isAccessible();
                retVal = retVal && Schema.sObjectType.HelpedPageLayout__c.fields.RehookTimes__c.isAccessible();
                Diags += 'FLS User: Helped Page Layouts: ' + retVal + '... ';
                
                retVal = retVal && Schema.sObjectType.iahelp__LWC_Aura_Interaction_Event__e.isCreateable();
                Diags += 'FLS User: Platform Events: ' + retVal + '... ';
                
                retVal = retVal && Schema.sObjectType.SemanticTag__c.fields.Name.isAccessible();
                retVal = retVal && Schema.sObjectType.SemanticTag__c.fields.CollectiveObverse__c.isAccessible();
                retVal = retVal && Schema.sObjectType.SemanticTag__c.fields.CollectiveTag__c.isAccessible();
                retVal = retVal && Schema.sObjectType.SemanticTag__c.fields.Obverse__c.isAccessible();
                retVal = retVal && Schema.sObjectType.SemanticTag__c.fields.ShortObverse__c.isAccessible();
                retVal = retVal && Schema.sObjectType.SemanticTag__c.fields.Tag__c.isAccessible();
                Diags += 'FLS User: Semantic Tags: ' + retVal + '... ';
                
                if (retVal == true) {Diags = 'FLS User: OK... ';}
                
                
            } else if (Op == KnownSecureOperations.AnalyseHelp) {
                Diags += 'FLS Analyst: About to check Helped User settings... ';                
                retVal = meetsFLSRequirements(KnownSecureOperations.UseHelp);               
                if (retVal == true) {Diags = 'FLS Analyst: User OK... ';}
                
                // v1.31.1: As we no longer check Permission Sets, we need to add an arbitrary additional 
                // permission (which makes no difference as we don't have CRUD edit at object level)
                // to differentiate Help Analysts from Users...
                
                //V1.56 this is No longer a differentiator Users need this permission.
                //  retVal = retVal && Schema.sObjectType.HelpInteraction__c.fields.Description__c.isUpdateable();
                
                // v1.41 - additional needs
                retVal = retVal && Schema.sObjectType.HelpInteraction__c.fields.HelpVoteOptionCategory__c.isAccessible();
                
                //Added a new permission as a differentiator for the Analyst:
                retVal = retVal && Schema.sObjectType.HelpInteraction__c.fields.iahelp__Context__c.isUpdateable();
                
                Diags += 'FLS Analyst: Help Interactions: ' + retVal + '... ';
                
                if (retVal == true) {Diags = 'FLS Analyst: OK... ';}
                
                
            } else if (Op == KnownSecureOperations.EditHelp) {
                Diags += 'FLS Author: About to check Analyst settings... ';
                retVal = meetsFLSRequirements(KnownSecureOperations.AnalyseHelp);
                if (retVal == true) {Diags = 'FLS Author: Analyst OK... ';}
                
                retVal = retVal && Schema.sObjectType.ConfigurationItem__c.isCreateable();
                retVal = retVal && Schema.sObjectType.ConfigurationItem__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.ConfigurationItem__c.isDeletable();
                
                retVal = retVal && Schema.sObjectType.ConfigurationItem__c.fields.OwnerId.isUpdateable();
                retVal = retVal && Schema.sObjectType.ConfigurationItem__c.fields.ActionCode__c.isUpdateable();               
                retVal = retVal && Schema.sObjectType.ConfigurationItem__c.fields.Description__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.ConfigurationItem__c.fields.DisplayGrouping__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.ConfigurationItem__c.fields.DisplayOrder__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.ConfigurationItem__c.fields.HasDivider__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.ConfigurationItem__c.fields.IconClass__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.ConfigurationItem__c.fields.IconContent__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.ConfigurationItem__c.fields.Label__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.ConfigurationItem__c.fields.MinimumFormFactor__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.ConfigurationItem__c.fields.NegotiateToolbarLevel__c.isUpdateable();              
                retVal = retVal && Schema.sObjectType.ConfigurationItem__c.fields.PermissionLevel__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.ConfigurationItem__c.fields.SupportingControls__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.ConfigurationItem__c.fields.TipText__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.ConfigurationItem__c.fields.ToggleActiveMarker__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.ConfigurationItem__c.fields.ToggleNext__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.ConfigurationItem__c.fields.TogglePrev__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.ConfigurationItem__c.fields.ToolClass__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.ConfigurationItem__c.fields.ToolContext__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.ConfigurationItem__c.fields.ToolFilter__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.ConfigurationItem__c.fields.Type__c.isUpdateable();
                
                Diags += 'FLS Author: Configuration Items: ' + retVal + '... ';
                
                retVal = retVal && Schema.sObjectType.HelpReadingList__c.isCreateable();
                retVal = retVal && Schema.sObjectType.HelpReadingList__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpReadingList__c.isDeletable();
                retVal = retVal && Schema.sObjectType.HelpReadingList__c.fields.Name.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpReadingList__c.fields.Active__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpReadingList__c.fields.Description__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpReadingList__c.fields.FeaturedUntil__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpReadingList__c.fields.LightningPresentationStyle__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpReadingList__c.fields.ReadingListStatus__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpReadingList__c.fields.ReadingListType__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpReadingList__c.fields.Summary__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpReadingList__c.fields.Visibility__c.isUpdateable();
                Diags += 'FLS Author: Reading Lists: ' + retVal + '... ';
                
                retVal = retVal && Schema.sObjectType.HelpReadingListEntry__c.isCreateable();
                retVal = retVal && Schema.sObjectType.HelpReadingListEntry__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpReadingListEntry__c.isDeletable();               
                retVal = retVal && Schema.sObjectType.HelpReadingListEntry__c.fields.DisplayColumn__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpReadingListEntry__c.fields.DisplayRow__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpReadingListEntry__c.fields.NavigationDetails__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpReadingListEntry__c.fields.NavigationType__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpReadingListEntry__c.fields.ReadingOrder__c.isUpdateable();
                Diags += 'FLS Author: Reading List Entries: ' + retVal + '... ';
                
                
                retVal = retVal && Schema.sObjectType.HelpRelationship__c.isCreateable();
                retVal = retVal && Schema.sObjectType.HelpRelationship__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpRelationship__c.isDeletable();
                retVal = retVal && Schema.sObjectType.HelpRelationship__c.fields.Order__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpRelationship__c.fields.RelatedHelpTopic__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpRelationship__c.fields.SemanticTag__c.isUpdateable();             
                Diags += 'FLS Author: Help Relationships: ' + retVal + '... ';
                
                retVal = retVal && Schema.sObjectType.HelpResource__c.isCreateable();
                retVal = retVal && Schema.sObjectType.HelpResource__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpResource__c.isDeletable();
                retVal = retVal && Schema.sObjectType.HelpResource__c.fields.Name.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpResource__c.fields.Location__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpResource__c.fields.ResourceType__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpResource__c.fields.ResourceURL__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpResource__c.fields.Summary__c.isUpdateable();
                Diags += 'FLS Author: Resources: ' + retVal + '... ';
                
                
                retVal = retVal && Schema.sObjectType.HelpTopic__c.isCreateable();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.isDeletable();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.Name.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.Active__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.CalloutHeight__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.CalloutMediaChoice__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.CalloutTemplate__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.CustomStyle__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.Description__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.DescriptionText1__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.DescriptionText2__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.DescriptionText3__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.DescriptionText4__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.DescriptionText5__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.HeightBeforeScrolling__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.HelpTopicStatus__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.HelpVoteSet__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.ImageALTText__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.ImageCaption__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.ImageHeight__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.ImageTitle__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.ImageURL__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.ImageWidth__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.Keyword__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.LightningTemplate__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.MasterTopicIdentifier__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.SalesforceHelpURL__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.GuideCallout__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.ShowReadMoreLink__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.ShowReferringRelationships__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.GuidedRecord__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.GuidedElement__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.GuidedLayout__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.GuideStepMode__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.Summary__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.Template__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.VideoCaption__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.VideoHeight__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.VideoTitle__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.VideoURL__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.VideoWidth__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpTopic__c.fields.Visibility__c.isUpdateable();
                Diags += 'FLS Author: Topics: ' + retVal + '... ';
                
                
                retVal = retVal && Schema.sObjectType.HelpTopicResource__c.isCreateable();
                retVal = retVal && Schema.sObjectType.HelpTopicResource__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpTopicResource__c.isDeletable();
                retVal = retVal && Schema.sObjectType.HelpTopicResource__c.fields.UsageNotes__c.isUpdateable();
                Diags += 'FLS Author: Topic Resources: ' + retVal + '... ';
                
                retVal = retVal && Schema.sObjectType.HelpTopicTemplate__c.isCreateable();
                retVal = retVal && Schema.sObjectType.HelpTopicTemplate__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpTopicTemplate__c.isDeletable();
                retVal = retVal && Schema.sObjectType.HelpTopicTemplate__c.fields.Name.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpTopicTemplate__c.fields.DefaultHeight__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpTopicTemplate__c.fields.Description__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpTopicTemplate__c.fields.PageURL__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpTopicTemplate__c.fields.TemplateType__c.isUpdateable();
                Diags += 'FLS Author: Templates: ' + retVal + '... ';
                
                retVal = retVal && Schema.sObjectType.HelpVoteOption__c.isCreateable();
                retVal = retVal && Schema.sObjectType.HelpVoteOption__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpVoteOption__c.isDeletable();
                retVal = retVal && Schema.sObjectType.HelpVoteOption__c.fields.Name.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpVoteOption__c.fields.DisplayOrder__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpVoteOption__c.fields.ImageClass__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpVoteOption__c.fields.OptionColour__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpVoteOption__c.fields.OptionLabel__c.isUpdateable();
                Diags += 'FLS Author: Vote Options: ' + retVal + '... ';
                
                retVal = retVal && Schema.sObjectType.HelpVoteSet__c.isCreateable();
                retVal = retVal && Schema.sObjectType.HelpVoteSet__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpVoteSet__c.isDeletable();
                retVal = retVal && Schema.sObjectType.HelpVoteSet__c.fields.Name.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpVoteSet__c.fields.ImageClass__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpVoteSet__c.fields.QuestionText__c.isUpdateable();
                Diags += 'FLS Author: Vote Sets: ' + retVal + '... ';
                
                retVal = retVal && Schema.sObjectType.HelpedElement__c.isCreateable();
                retVal = retVal && Schema.sObjectType.HelpedElement__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpedElement__c.isDeletable();
                retVal = retVal && Schema.sObjectType.HelpedElement__c.fields.Name.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpedElement__c.fields.DataDrivenFilter__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpedElement__c.fields.ElementType__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpedElement__c.fields.HelpedPageLayout__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpedElement__c.fields.HelpTopic__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpedElement__c.fields.Identifier__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpedElement__c.fields.Parameters__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpedElement__c.fields.UseForNew__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpedElement__c.fields.Visibility__c.isUpdateable();
                Diags += 'FLS Author: Helped Elements: ' + retVal + '... ';
                
                retVal = retVal && Schema.sObjectType.HelpFilter__c.isCreateable();
                retVal = retVal && Schema.sObjectType.HelpFilter__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpFilter__c.isDeletable();
                retVal = retVal && Schema.sObjectType.HelpFilter__c.fields.FilteredObject__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpFilter__c.fields.FilteredObjectIdentifier__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpFilter__c.fields.FilterIdentifier__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpFilter__c.fields.FilterLogic__c.isUpdateable();
                Diags += 'FLS Author: Help Filters: ' + retVal + '... ';
                
                retVal = retVal && Schema.sObjectType.HelpFilterCriterion__c.isCreateable();
                retVal = retVal && Schema.sObjectType.HelpFilterCriterion__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpFilterCriterion__c.isDeletable();
                retVal = retVal && Schema.sObjectType.HelpFilterCriterion__c.fields.Name.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpFilterCriterion__c.fields.CriterionNumber__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpFilterCriterion__c.fields.FilteredField__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpFilterCriterion__c.fields.FilteredFieldType__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpFilterCriterion__c.fields.FilterValue__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpFilterCriterion__c.fields.Operator__c.isUpdateable();
                Diags += 'FLS Author: Filter Criteria: ' + retVal + '... ';
                
                retVal = retVal && Schema.sObjectType.HelpedPageLayout__c.isCreateable();
                retVal = retVal && Schema.sObjectType.HelpedPageLayout__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpedPageLayout__c.isDeletable();
                retVal = retVal && Schema.sObjectType.HelpedPageLayout__c.fields.Name.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpedPageLayout__c.fields.AllowComments__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpedPageLayout__c.fields.PageLayoutIdentifier__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpedPageLayout__c.fields.PageType__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpedPageLayout__c.fields.RehookInterval__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpedPageLayout__c.fields.RehookTimes__c.isUpdateable();
                Diags += 'FLS Author: Helped Page Layouts: ' + retVal + '... ';
                
                if (retVal == true) {Diags = 'FLS Author: OK... ';}
                
                
            } else if (Op == KnownSecureOperations.AdministerHelp){
                Diags += 'FLS Administrator: About to check Author settings... ';
                retVal = meetsFLSRequirements(KnownSecureOperations.EditHelp);
                if (retVal == true) {Diags = 'FLS Administator: Author OK... ';}
                
                retVal = retVal && Schema.sObjectType.IASetIHOrg__c.isCreateable();
                retVal = retVal && Schema.sObjectType.IASetIHOrg__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.IASetIHOrg__c.isDeletable();
                Diags += 'FLS Administrator: Global Settings: ' + retVal + '... ';
                
                //v1.56 No longer a differentiator 
               // retVal = retVal && Schema.sObjectType.HelpInteraction__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpInteraction__c.isDeletable();
                Diags += 'FLS Administrator: Help Interactions: ' + retVal + '... ';
                
                retVal = retVal && Schema.sObjectType.HelpableSignature__c.isCreateable();
                retVal = retVal && Schema.sObjectType.HelpableSignature__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpableSignature__c.isDeletable();
                retVal = retVal && Schema.sObjectType.HelpableSignature__c.fields.Name.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpableSignature__c.fields.Description__c.isUpdateable();                
                retVal = retVal && Schema.sObjectType.HelpableSignature__c.fields.Domain__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpableSignature__c.fields.HelpStyle__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpableSignature__c.fields.Identifier__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.HelpableSignature__c.fields.IdentifierType__c.isUpdateable();
                Diags += 'FLS Administrator: Signatures: ' + retVal + '... ';
                
                retVal = retVal && Schema.sObjectType.NoiseWords__c.isCreateable();
                retVal = retVal && Schema.sObjectType.NoiseWords__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.NoiseWords__c.fields.CreatedById.isAccessible();
                retVal = retVal && Schema.sObjectType.NoiseWords__c.fields.Name.isUpdateable();
                retVal = retVal && Schema.sObjectType.NoiseWords__c.fields.LastModifiedById.isAccessible();
                retVal = retVal && Schema.sObjectType.NoiseWords__c.fields.OwnerId.isUpdateable();
                Diags += 'FLS Administrator: Noise Words: ' + retVal + '... ';                      
                
                retVal = retVal && Schema.sObjectType.SemanticTag__c.isCreateable();
                retVal = retVal && Schema.sObjectType.SemanticTag__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.SemanticTag__c.isDeletable();
                retVal = retVal && Schema.sObjectType.SemanticTag__c.fields.Name.isUpdateable();
                retVal = retVal && Schema.sObjectType.SemanticTag__c.fields.CollectiveObverse__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.SemanticTag__c.fields.CollectiveTag__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.SemanticTag__c.fields.Obverse__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.SemanticTag__c.fields.ShortObverse__c.isUpdateable();
                retVal = retVal && Schema.sObjectType.SemanticTag__c.fields.Tag__c.isUpdateable();
                
                Diags += 'FLS Administrator: Semantic Tag: ' + retVal + '... ';
                
                if (retVal == true) {Diags = 'FLS Administrator: OK... ';}      
                
            } else {
                // Unknown op - default to not allowed
                retVal = false;         
            }
            
        } catch (exception e) {
            // Error - default to not allowed
            Diags += e.getMessage();
            retVal = false;         
        }
        
        // Clear diagnostics unless we're instructed to keep them
        if (retVal == true && retainDiags != true) {Diags = '';}
        return retVal;              
        
    }
    
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Returns a value confirming whether we are in a VF scenario, so ApexPages object exists:
    // This will not be the case where certain LUX ops call wrapped controller methods etc.
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    public static boolean ApexPageExists() {
        
        boolean retVal;
        
        try {
            retVal = ApexPages.currentPage() != null && ApexPages.currentPage() + '' != 'System.PageReference[null]';
        } catch (exception e) {
            retVal = false;
        }
        
        return retVal;
    }
    
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Function return a safely escaped parameter from a URL query string
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    public static String getQueryParameter (String Param, Integer Opt) {
        
        String retVal;
        String NS = 'iahelp__';
        
        
        try {
            // We can only offer this service where an apex page exists
            if (ApexPageExists() == false) {
                retVal = '';
                
            } else {
                retVal = ApexPages.currentPage().getParameters().get(Param);
                if (retVal == null) {
                    // Try tacking on namespace to parameter name
                    retVal = ApexPages.currentPage().getParameters().get(NS + Param);
                    
                }
                if (retVal == null) {retVal = '';}
                
                
                // Basic escaping
                if (Opt == 0) {
                    //retVal = ApexPages.currentPage().getParameters().get(Param);
                    //if (retVal == null) {retVal = '';}
                    
                    retVal = retVal.escapeHtml4();          
                    
                    // Whilst we don't want "<" scripts, we can tolerate ampersands
                    retVal = retVal.replace('&amp;', '&');  
                }
                
                // Standard
                if (Opt == 1) {
                    //retVal = ApexPages.currentPage().getParameters().get(Param);
                    //if (retVal == null) {retVal = '';}    
                    
                    // No further processing requested          
                }
                
                // Agressive
                if (Opt == 2) {
                    
                    //retVal = ApexPages.currentPage().getParameters().get(Param);                   
                    //if (retVal == null) {retVal = '';}
                    
                    retVal = retVal.replace('\'', '');  
                    retVal = retVal.replace('"', '');   
                    retVal = retVal.replace('<', '');   
                    retVal = retVal.replace('>', '');
                    
                }
                
            }
            
        } catch (exception e) {
            retVal = '';
        }
        
        return retVal;
    }
    
}