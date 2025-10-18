/////////////////////////////////////////////////////////////////////////////////////////////////////
// CLASS FOR LOGGING HELP INTERACTIONS: CAN BE CALLED AS A PAGE CONTROLLER OR VIA INSTANCE/OBJECT CODE
//
// Martin Little for Improved Apps
// May 2012
/////////////////////////////////////////////////////////////////////////////////////////////////////

public with sharing class ServiceInteractions {
    
    //Enum created for logging Geolocation interactions for App analytics.
    public enum CustomGeoInteraction {
        GEOLOCATION, // For geolocation-based interactions
           NO_GEOLOCATION }
    //Enum created for Logging App Analytics Custom Interactions for all types of Help Interactions
    public enum InteractionType {
        CALLOUT,
            COMMENT,
            ISSUE,
            FULL_TOPIC,
            SYSTEM_GENERATED_MESSAGE,
            RESOURCE,
            SEARCH,
            VOTE,
            QAM_DRAG,
            LIST_DETAIL_LEVEL,
            LUX_LIST_TYPE,
            STICKY,
            READING_LIST_ENTRY,
            TREE_NODE,
            PERSONAL_FIELD_SELECTION,
            PERSONAL_FORM_VISIBILITY,
            DISPLAY_DENSITY,
            FORM_SECTION_TOGGLE,
            POSITION_DETECTOR_CONTEXT_LOG,
            NUDGE_DISPLAYED,
            GUIDE_PROMPT_VIEWED,
            METADATA_SOUGHT,
            TREE_SEARCH_COMPLETED,
            TREE_SEARCH_CANCELLED,
            HELP_REQUEST
            }
    //Mapping each HIType with enum values.
    private static Map<String, InteractionType> hitypeToEnumMap = new Map<String, InteractionType>{
        'Callout' => InteractionType.CALLOUT,
            'Comment' => InteractionType.COMMENT,
            'Issue' => InteractionType.ISSUE,
            'Full Topic' => InteractionType.FULL_TOPIC,
            'System' => InteractionType.SYSTEM_GENERATED_MESSAGE,
            'Resource' => InteractionType.RESOURCE,
            'Search' => InteractionType.SEARCH,
            'Vote' => InteractionType.VOTE,
            'QAM Drag' => InteractionType.QAM_DRAG,
            'List Detail Level' => InteractionType.LIST_DETAIL_LEVEL,
            'LUX List Type' => InteractionType.LUX_LIST_TYPE,
            'Sticky' => InteractionType.STICKY,
            'Reading List Entry' => InteractionType.READING_LIST_ENTRY,
            'Tree Node' => InteractionType.TREE_NODE,
            'Personal Field Selection' => InteractionType.PERSONAL_FIELD_SELECTION,
            'Personal Form Visibility' => InteractionType.PERSONAL_FORM_VISIBILITY,
            'Display Density' => InteractionType.DISPLAY_DENSITY,
            'Form Section Toggle' => InteractionType.FORM_SECTION_TOGGLE,
            'Position Detector Context Log' => InteractionType.POSITION_DETECTOR_CONTEXT_LOG,
            'Nudge Displayed' => InteractionType.NUDGE_DISPLAYED,
            'Guide Prompt Viewed' => InteractionType.GUIDE_PROMPT_VIEWED,
            'Metadata sought' => InteractionType.METADATA_SOUGHT,
            'Tree Search Completed' => InteractionType.TREE_SEARCH_COMPLETED,
            'Tree Search Cancelled' => InteractionType.TREE_SEARCH_CANCELLED,
            'Help Request' => InteractionType.HELP_REQUEST
            };

//public ControllerLUXOps.DescriptionWrapper eventParamMap; 
public ControllerLUXOps.GeolocationWrapper restParamMap;     
    public String Diags { get; set;}
   
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Log various kinds of interaction:
    // 
    // EXPECTS:
    // iTyp - one of various known interaction types:
    //       0 = Add message to platform event bus only (no interaction record)
    //       1 = Callout
    //       2 = Comment
    //       3 = Issue
    //       4 = (Full) Topic Read
    //       5 = System generated messages
    //       6 = Resource viewed
    //       7 = Search (List based) conducted
    //       8 = Vote
    //       9 = QAM Handle positioned
    //      10 = Listing Expanded / Collapsed 
    //      11 = LUX Listing type requested
    //      12 = Logging of an individual sticky note
    //      13 = Reading List Entry viewed
    //      14 - Tree Node clicked
    //      15 - Personal field selection (for 'my form' data form defintion)
    //      16 - Personal form visibility
    //      17 - Display Density (LUX auto form etc.)
    //      18 - Autoform section expand / collapse
    //      19 - Position Detector Context Log
    //      20 - Nudge displayed to user
    //      21 - LUX Guide prompt viewed (Guide topic viewed)
    //      22 - (Layout) metadata request log (containing details of object for which metadata was sought)   
    //      23 - Search (Tree based) conducted
    //      24 - Search (Tree based) cancelled
    //      25 - Help Request (logged vvia position detector in Help Request role)
    
    
    // NB: the "Sticky (Archived)" interaction represents an UPDATE to an existing interation (of type Sticky) ONLY
    // so cannot be directly logged: logic elsewhere effects this update.
    
    //
    // Description  - Full descriptive text for the interaction
    // IHContext    - Record / URL in play when interaction logged (where known)
    // PLID         - A page layout record ID
    // EID          - An Entity record ID
    // HTID         - A Help Topic record ID
    // RLID         - A Reading List (or Guide) ID
    // VOptId       - A vote option ID (the vote being cast)
    //
    // RETURNS:
    // True if successful: otherwise false. Sets diagnostics text in Diags
    /////////////////////////////////////////////////////////////////////////////////////////////////////   
    
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////   
    // REM: CHANGES TO INTERACTION TYPES HERE (NEW TYPES OR AMENDMENTS TO TYPE NAMES)
    // MAY CALL FOR CHANGES TO:
    //      - Global settings (# days to retain interactions)
    //      - Global settings page (to record the same)
    //      - Scheduler - deletion per retention schedule
    //      - Test data generator (correct population of global settings for tests)
    //      - Stats controller
    /////////////////////////////////////////////////////////////////////////////////////////////////////   
    
    public Boolean logInteraction (Integer iTyp, String Description, String IHContext, String PLID, String EID, String HTID, String RLID, String VOptID) {   
        Double latitude;
        Double longitude;
        String logContextURL;
        Double altitude;
        Double accuracy;
        String userAgent;
   
        try{
        system.debug('inside service interaction latitude '+Double.ValueOf(restParamMap.latitude) +' longitude '+Double.ValueOf(restParamMap.longitude)+' logContextURL '+String.ValueOf(restParamMap.contextURL) + ' userAgent '+String.ValueOf(restParamMap.userAgent));
        latitude = Double.ValueOf(restParamMap.latitude);
        longitude = Double.ValueOf(restParamMap.longitude);
        altitude = Double.ValueOf(restParamMap.altitude);
        accuracy = Double.ValueOf(restParamMap.accuracy); 
        userAgent = String.valueof(restParamMap.userAgent);
        logContextURL = String.valueof(restParamMap.contextURL);  

            
        system.debug('inside service interaction Context URL '+logContextURL); 
        system.debug('inside service interaction userAgent '+userAgent); 
        //Clearing the resPeramMap for new logging of latitude and longitude.    
        //restParamMap.clear();    
        }catch(Exception EX){
            system.debug('inside service interaction ERROR '+EX.getMessage());
        }
        
        // For diagnostics translations
        map<string, string> mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false);
        
        ServiceSecurity Security = new ServiceSecurity();
        IASetIHOrg__c settings;
        id IHContextId;
        string objectName;
        string contextUrl; 
        string objectLabel;
        boolean orgMetricsDue = false;
        date orgMetricsLastLogged;
        String HIType;
        String ComponentId = '';
        Boolean doTrack = false;
        HelpInteraction__c HI;
        string D1 = '\\^';
    
     

        try {
            integer iEd = ServiceSubs.getFPIValue('iL2SProductOptions1');           // Product edition
            Boolean[] UPs = Security.UserPermissions();
            Boolean bUser = UPs[0];


            // Record key metrics for the current org in feature parameters:
            // Do this regardless of product edition as we always want these stats.
            // However, only do this periodically
            try {
                orgMetricsLastLogged = ServiceSubs.getFPDValue('dS2LMetricsLogged');    
                orgMetricsDue = orgMetricsLastLogged.daysBetween(Date.today()) > 0; 
                
                try {
                    AsyncApexJob FutureJobs = [SELECT Id, Status, 
                                               JobItemsProcessed, 
                                               JobType ,MethodName, 
                                               TotalJobItems, NumberOfErrors
                                               FROM AsyncApexJob WHERE  
                                               Status = 'Processing' AND 
                                               JobType = 'Future' AND  
                                               MethodName = 'recordOrgMetrics' limit 1];  
                                               
                   // If we reach here, job to record org metrics is already running:
                   // Take no action / do not create another job
                   
                } catch(Exception Ex) {     
                    // Org metrics update job is NOT running:
                    // Continue / create the job if stats update is due...
                    if (orgMetricsDue) {
                        ServiceSubs.recordOrgMetrics();
                    }
                }
            } catch  (exception ex) {}


            // Check product edition: interactions can only be logged by certain of these           
            if (iEd == 0) {
                // Product is off - take no action
                return true;
                    
            } else if (iEd == 1) {
                // Usage tracker only - allow only position detector context logs
                // and (as of 1.55) help requests
                if (iTyp != 19 && iTyp != 25) {
                    return true;
                }
                    
            } else {
                // Continue
            }


            // Check rights
            if (!bUser) {
                this.Diags = mapGlbLocs.get('MessageNoRights');
                return false;
                                    
            } else {

                // Speacial, non-help interaction-based handling for type zero (platform event only):
                if (iTyp == 0) {
                
                    //Define List to capture data in Platform Event
                    List<iahelp__LWC_Aura_Interaction_Event__e> eventList = new List<iahelp__LWC_Aura_Interaction_Event__e>();
                    iahelp__LWC_Aura_Interaction_Event__e messageEvent = new iahelp__LWC_Aura_Interaction_Event__e();
                
                    system.debug('platformevent:  '+ eventList.size());
                
                    try {
                        // Set event data                       
                        // 'Mark' the platform event with the 'identifier' provided by the calling component
                        messageEvent.iahelp__Parameters__c = Description;
                        messageEvent.iahelp__Filter__c = IHContext;
                        eventList.add(messageEvent);

                    } catch(exception e){
                        return false;
                    }
                    
                    // Only raise platform events where global settings speicfy this
                    settings = IASetIHOrg__c.getOrgDefaults();
                    if(eventList.size() > 0 && settings.RaisePlatformEvents__c){
                        EventBus.publish(eventList);     
                    }
                    
                    // Proceed no further in these cases
                    return true;
                }

            
                // Check whether the given interaction type is being tracked as we set it...
                if (iTyp == 1) { 
                    HIType = 'Callout';
                    doTrack = (Integer) ControllerSettings.getSettings().TrackDaysCallouts__c > 0;
                    
                } else if (iTyp == 2) {
                    HIType = 'Comment';
                    doTrack = (Integer) ControllerSettings.getSettings().TrackDaysComments__c > 0;
    
                } else if (iTyp == 3) {
                    HIType = 'Issue';           
                    doTrack = (Integer) ControllerSettings.getSettings().TrackDaysErrors__c > 0;
    
                } else if (iTyp == 4) {
                    HIType = 'Full Topic';          
                    doTrack = (Integer) ControllerSettings.getSettings().TrackDaysTopics__c > 0;
    
                } else if (iTyp == 5) {
                    HIType = 'System';          
                    doTrack = true;
    
                } else if (iTyp == 6) {
                    HIType = 'Resource';            
                    doTrack = (Integer) ControllerSettings.getSettings().TrackDaysResources__c > 0;
    
                } else if (iTyp == 7) {
                    HIType = 'Search';          
                    doTrack = (Integer) ControllerSettings.getSettings().TrackDaysSearches__c > 0;
    
                } else if (iTyp == 8) {
                    HIType = 'Vote';            
                    doTrack = (Integer) ControllerSettings.getSettings().TrackDaysVotes__c > 0;
    
                } else if (iTyp == 9) {
                    HIType = 'QAM Drag';            
                    doTrack = (Integer) ControllerSettings.getSettings().TrackDaysLUXOps__c > 0;
    
                } else if (iTyp == 10) {
                    HIType = 'List Detail Level';           
                    doTrack = (Integer) ControllerSettings.getSettings().TrackDaysLUXOps__c > 0;
    
                } else if (iTyp == 11) {
                    HIType = 'LUX List Type';           
                    doTrack = (Integer) ControllerSettings.getSettings().TrackDaysLUXOps__c > 0;
    
                } else if (iTyp == 12) {
                    HIType = 'Sticky';          
                    doTrack = (Integer) ControllerSettings.getSettings().TrackDaysLUXOps__c > 0;
    
                } else if (iTyp == 13) {
                    // RLE tracking controlled by Full Topic setting...
                    HIType = 'Reading List Entry';          
                    doTrack = (Integer) ControllerSettings.getSettings().TrackDaysTopics__c > 0;
    
                } else if (iTyp == 14) {
                    // Tree node tracking controlled by Full Topic setting...
                    HIType = 'Tree Node';           
                    doTrack = (Integer) ControllerSettings.getSettings().TrackDaysTopics__c > 0;
    
                } else if (iTyp == 15) {
                    // Data form definition / personal field selection...
                    HIType = 'Personal Field Selection';           
                    doTrack = (Integer) ControllerSettings.getSettings().TrackDaysLUXOps__c > 0;
    
                } else if (iTyp == 16) {
                    // Data form definition / personal field selection...
                    HIType = 'Personal Form Visibility';           
                    doTrack = (Integer) ControllerSettings.getSettings().TrackDaysLUXOps__c > 0;
    
                } else if (iTyp == 17) {
                    // Auto form display density...
                    HIType = 'Display Density';           
                    doTrack = (Integer) ControllerSettings.getSettings().TrackDaysLUXOps__c > 0;
    
                } else if (iTyp == 18) {
                    // Auto form section toggle expand/collapse...
                    HIType = 'Form Section Toggle';           
                    doTrack = (Integer) ControllerSettings.getSettings().TrackDaysLUXOps__c > 0;
                    
                    // In these cases, we want the interactions to be "singletons" per user per context,
                    // so delete any existing interactions before re-creating below
                    
                    try {
                        HelpInteraction__c[] FSTs = [SELECT Id 
                                                        FROM HelpInteraction__c 
                                                        WHERE HelpInteractionType__c = :HIType
                                                        AND Context__c = :IHContext
                                                        AND OwnerId = :UserInfo.getUserId()
                                                        ];
                        delete FSTs;     
                    } catch (exception ex) {}
    
                } else if (iTyp == 19) {
                    // Position Detector Context Log...
                    HIType = 'Position Detector Context Log';  
                    
                    // Split component ID and requested context
                    String[] parms = Description.split(D1);
                    System.debug('parms==>'+parms[0]);
                    try {
                        Description = parms[0];
                        ComponentId = parms[1];
                    } catch (exception ex) {}

                             
                    doTrack = (Integer) ControllerSettings.getSettings().TrackDaysLUXOps__c > 0;
    
                } else if (iTyp == 20) {
                    // Topic featured in nudge component...
                    HIType = 'Nudge Displayed';           
                    doTrack = (Integer) ControllerSettings.getSettings().TrackDaysLUXOps__c > 0;
                    
                    // Split incoming context info into component ID and record context
                    String[] parms = IHContext.split(D1);
                    
                    try {
                        ComponentId = parms[0];
                        IHContext = parms[1];                        
                        if (IHContext + '' == 'null') {IHContext = '';}
                    } catch (exception ex) {}
                    
    
                } else if (iTyp == 21) {
                    // LUX Guide prompt viewed...
                    HIType = 'Guide Prompt Viewed';           
                    doTrack = (Integer) ControllerSettings.getSettings().TrackDaysLUXOps__c > 0;
    
                } else if (iTyp == 22) {
                    // Metadata sought...
                    HIType = 'Metadata sought';           
                    doTrack = (Integer) ControllerSettings.getSettings().TrackDaysLUXOps__c > 0;
                    
                    // In these cases, we want the interactions to be "singletons" per org,
                    // so delete any existing interactions before re-creating below
                    
                    try {
                        HelpInteraction__c[] MInts = [SELECT Id 
                                                        FROM HelpInteraction__c 
                                                        WHERE HelpInteractionType__c = :HIType
                                                        ];
                        delete MInts;     
                    } catch (exception ex) {}
                    
                } else if (iTyp == 23) {
                    // Tree search completed
                    HIType = 'Tree Search Completed';           
                    doTrack = (Integer) ControllerSettings.getSettings().TrackDaysLUXOps__c > 0;
                
                } else if (iTyp == 24) {
                    // Tree search cancelled
                    HIType = 'Tree Search Cancelled';           
                    doTrack = (Integer) ControllerSettings.getSettings().TrackDaysLUXOps__c > 0;
                                               
                } else if(iTyp == 25){
                    // IHPosDetect help request role.
                    HIType = 'Help Request';
                    
                    // Description is in fact component ID
                    ComponentId = Description;
                    
                    // Now set a fixed description
                    Description = 'User requested help for the specified context';
                    
                    doTrack = true;
                
                } else {
                    // If interaction is unknown type, we cannot log it - so bail here
                    this.Diags = mapGlbLocs.get('MessageInteractionUnknownType') + ' (' + iTyp + ')';  
                    return false;
                }
        
    
                if (doTrack == true) {  
                    
// At this point, for certain product editions, only allow 
// summaries of interactions: if there are more than a certain number of interactions
// of a given type, delete the granular records and replace with a single summary record

integer iMaxInteractionsAllowed;
boolean doSummary = false;
HelpInteraction__c[] granularInts;

// Count existing items here to see if summary required
if (iEd == 1) {
    
    /*
    iMaxInteractionsAllowed = 100;
    
    granularInts = [SELECT Id 
            FROM HelpInteraction__c 
            WHERE HelpInteractionType__c = :HIType];
                
    doSummary = granularInts.size() > iMaxInteractionsAllowed;
    */
}

                    
if (doSummary = true) {
    
    // Summaries existing records
    
    // Delete existing records
    // delete granularInts;
    
    // Add single summary record
}
                                                
                    HI = new HelpInteraction__c();  
                    HI.HelpInteractionType__c = HIType;
                    HI.Description__c = Description;
                    HI.Context__c = IHContext; 
                    HI.ComponentId__c = ComponentId; 
                    HI.HelpedPageLayout__c = PLID;
                    system.debug('logInteraction HIType==>'+HIType);
                    system.debug('logInteraction Description==>'+Description);

                    
                    // ToDo: For Resource type interactions, the element ID (for now) is the Resoure
                    if (iTyp == 6) {
                        HI.HelpResource__c = EID;
                    } else {
                        HI.HelpedElement__c = EID;                  
                    }
                    
                    HI.HelpTopic__c = HTID;
                    HI.HelpReadingList__c = RLID;
                    HI.HelpVoteOption__c = VOptId;
                   
                    // Obtain context object information if IHContext allows this 
                    try {   
                        IHContextId = HI.Context__c;
                        contextUrl = string.valueOf(URL.getOrgDomainURL().toExternalForm());
                        if(IHContext != null && IHContext != ''){
                            try{
                            //IHContext contains Id.    
                            objectName = string.valueOf(IHContextId.getsobjecttype());
                            objectLabel = IHContextId.getSObjectType().getDescribe().getLabel();
                            }catch(Exception ex){
                                //IHContext contains Name(Mainly in list view) for logging interaction.
                                system.debug('ERROR '+ex.getMessage());
                            }
                        } else {
                            objectName = '[Unknown]';
                            objectLabel = ''; 
                        }
                        
                    } catch (exception ex) {                        
                        objectName = '[Unknown]';
                        objectLabel = '';
                        
                        try{
                            
                        //IHContext contains Name(Mainly in list view) for logging interaction.
                        String objectAPIName = IHContext.removeStart('__LUX__');
                        SObjectType objectAPIType = Schema.getGlobalDescribe().get(objectAPIName);
                        String objectLabelName = (String)objectAPIType.getDescribe().getLabel();
                            
                        objectLabel = objectLabelName;
                        objectName = objectAPIName;
                        }catch(Exception error){
                            system.debug('ERROR '+error.getMessage());
                        }
                    }
                    HI.ContextObjectName__c = objectName;
                    HI.ContextObjectLabel__c = objectLabel;
                    
                    if(IHContextId + '' != 'null'){
                        HI.iahelp__ContextLink__c = contextUrl + '/' + IHContextId;
                    } else {
                        
                        if(logContextURL != null){
                        HI.iahelp__ContextLink__c = string.valueOf(URL.getOrgDomainURL().toExternalForm())+logContextURL;
                        }else{
                        HI.iahelp__ContextLink__c = '';   
                        }
                    }
                
                    //Testing code.(Needs review)
                    //if(HI.iahelp__ContextLink__c != ''){
                      // HI.iahelp__ContextLink__c = contextUrl+'/'+logContextURL; 
                    //}
                    
                    // Derive user's platform information from login history:
                    // NB: no access checks in security service as there is no direct means to add object access via permission sets.
                    // NB: no access checks here as (nonetheless) users by SFDC design have access to their own login history
                    id CurrentUser = UserInfo.getUserId();
                    
                    try {
                        LoginHistory CurrentUserData = [SELECT Id, UserId, LoginTime, LoginType, LoginUrl, Browser, Platform, Status, Application, CountryIso 
                                                    FROM LoginHistory  
                                                    WHERE UserId =:CurrentUser 
                                                    AND (LoginType = 'Application' OR LoginType LIKE 'Remote Access%')                                                     
                                                    ORDER BY LoginTime Desc limit 1];

// REMAINING ISSUES:
// * How to obtain user's CURRENT experience (not the one associated with their last login, which may not be where they're creating interactions)
//      - EG: user logs in in windows, them on mobile, but is now operating back at their desktop (so we should log windows, not last login / mobile)

/*
select id, loginhistoryid, parentid, sessiontype, sourceip, usersid, iscurrent from authsession where usersid = '005d0000000jQB3AAM' order by iscurrent desc
*/

                        HI.UITheme__c = CurrentUserData.Application;        
                        HI.Browser__c = CurrentUserData.Browser;            
                        HI.Platform__c = CurrentUserData.Platform;
                    
                    } catch (exception ex) {
                        // Shouldn't arrive here, but if so do nothing with affected interaction fields
                    }

                    // Before insertion, check FLS: Here, we'll use a direct check as this
                    // is more streamlined than using our security service (which is likely
                    // to have been checked elsewhere by this point in any case)...
                  
                    
                    if (Schema.sObjectType.HelpInteraction__c.isCreateable()) {
                        Map<String,String> URLKeyVal = new Map<String,String>();
                        try{
                            //Log user geo location.
                            HI.iahelp__Geolocation__Latitude__s = latitude;
                            HI.iahelp__Geolocation__Longitude__s = longitude;
                            HI.iahelp__Accuracy__c = accuracy;  
                            HI.iahelp__Altitude__c = altitude;
                            HI.iahelp__UserAgent__c = userAgent;
                            
                            system.debug( ' latitude inside serviceinteractions ' +HI.iahelp__Geolocation__Latitude__s +' longitude '+HI.iahelp__Geolocation__Longitude__s+' HI.iahelp__Accuracy__c '+HI.iahelp__Accuracy__c+' HI.iahelp__Altitude__c '+HI.iahelp__Altitude__c+'   HI.iahelp__UserAgent__c = userAgent;'+  HI.iahelp__UserAgent__c );
                            try{ 
                                System.debug('logContextURL>>>>>>>>>>>>>>>>>>>>'+logContextURL);
                                String listViewName = getContextListViewName(String.valueOf(URL.getOrgDomainURL().toExternalForm()) + logContextURL);
                                System.debug('Returned ListView Name: ' + listViewName);
                                if (String.isNotBlank(listViewName)) {
                                    HI.iahelp__Context_List_View_Name__c = listViewName;
                                }
                            }catch(Exception ex){
                                system.debug('The URL does not contain filtername '+ ex.getMessage());
                            }   
                        }catch(Exception ex){
                            System.debug('ERROR '+ex.getMessage());
                        }
                        insert HI;          
                        this.Diags = HI.id;   
                        
                            //Log Geolocation interactions for app analytics.
                        if (HI.iahelp__Geolocation__Latitude__s != null && 
                            HI.iahelp__Geolocation__Longitude__s != null) {
                                
                                System.debug('Geolocation data found: Latitude = ' + HI.iahelp__Geolocation__Latitude__s + 
                                             ', Longitude = ' + HI.iahelp__Geolocation__Longitude__s);
                                try {
                                    System.debug('Attempting to log geolocation interaction for record ID: ' + HI.Id);
                                    IsvPartners.AppAnalytics.logCustomInteraction(CustomGeoInteraction.GEOLOCATION,HI.Id);
                                    System.debug('Custom interaction logged successfully.');
                                } catch(Exception e) {
                                    System.debug('Geolocation interaction logging failed: ' + e.getMessage());
                                }
                            } else {
                                System.debug('Geolocation data is missing.');
                                try {
                                    IsvPartners.AppAnalytics.logCustomInteraction(CustomGeoInteraction.NO_GEOLOCATION, HI.Id);
                                    System.debug('"No Geo Location" interaction logged successfully.');
                                } catch (Exception e) {
                                    System.debug('Failed to log "No Geo Location" interaction: ' + e.getMessage());
                                }
                            } 
                        
                        // Log All types of Help interaction for App Analytics 
                        InteractionType interactionType = hitypeToEnumMap.get(HIType);
                        System.debug('InteractionType found: ' + interactionType); 
                        if (interactionType != null) {
                            IsvPartners.AppAnalytics.logCustomInteraction(interactionType);
                            System.debug('logCustomInteraction method called for InteractionType: ' + interactionType);
                        } else {
                            System.debug('No InteractionType mapping found for HIType: ' + HIType);
                        }
                    }
                    
                } else {
                    this.Diags = mapGlbLocs.get('MessageInteractionUntrackedType');
                    return false;
                }
            } 
                
        } catch (exception e) {
            this.Diags = mapGlbLocs.get('MessageGenericError') + ' - ' + e.getMessage();
            return false;
        }
        
        return true;
        
    }
    
    /////////////////////////////////////////////////////////////////////////////////////////////
    // Populate “Context List View Name”
    /////////////////////////////////////////////////////////////////////////////////////////////
    
    public static String getContextListViewName(String logContextURL) {
        if (String.isNotBlank(logContextURL)) {
            try {
                // Extract the query string (everything after '?')
                Integer questionMarkIndex = logContextURL.indexOf('?');
                if (questionMarkIndex != -1 && questionMarkIndex < logContextURL.length() - 1) {
                    String queryString = logContextURL.substring(questionMarkIndex + 1);
                    
                    // Create a PageReference with the query string
                    PageReference ref = new PageReference('/?' + queryString);
                    Map<String, String> parameters = ref.getParameters();
                    
                    // Get the 'filterName' parameter
                    String filterName = parameters.get('filterName');
                    if (String.isBlank(filterName)) {
                        return ''; // return empty string if filterName is not present
                    }
                    
                    // Extract actual DeveloperName if needed
                    if (filterName.contains('__')) {
                        filterName = filterName.split('__')[1];
                    }
                    
                    // Query the ListView with the DeveloperName
                    List<ListView> views = [
                        SELECT Name FROM ListView 
                        WHERE DeveloperName = :filterName
                        LIMIT 1
                    ];
                    if (!views.isEmpty()) {
                        return views[0].Name;
                    }
                }
            } catch (Exception ex) {
                System.debug('ERROR in getContextListViewName: ' + ex.getMessage());
            }
        }
        
        return ''; // Return empty string if not found
    }


    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Schedule operation of the Retention process
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    public Boolean startRetention () {
                
        // For diagnostics translations
        map<string, string> mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false);

        try {
            
            ServiceScheduler S = new ServiceScheduler(ServiceScheduler.KnownSchedulableTasks.RetentionSchedules, null);
            
            // Secs 
            // Mins 
            // Hours 
            // Day (1-31)
            // Month (1-12)
            // Weekday (1 Sun - 7 Sat)
            // Year
            String sch = '0 10 18 * * ?'; 
            system.schedule('Help Interactions Retention Schedule', sch, S);
            this.Diags = 'Done';
            
        } catch (exception e) {
            this.Diags = mapGlbLocs.get('MessageGenericError') + ' - ' + e.getMessage();
            return false;
        }
        
        return true;
    }

}