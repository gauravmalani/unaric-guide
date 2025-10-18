/////////////////////////////////////////////////////////////////////////////////////////////////////
// CLASSES OFFERING DATA SOURCES FOR LISTS THAT ARE SHARED ACROSS IH PAGES / CONTEXTS
// AND WHICH TYPICALLY INVOLVE JOINS AND / OR OTHER COMPLEX BEHAVIOURS
//
// Martin Little for Improved Apps
// August 2012
/////////////////////////////////////////////////////////////////////////////////////////////////////


global with sharing class ServiceIHLists {

    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // ADDED TO AVOID TEST COVERAGE BUG ONLY
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    public String topLevelClassReflector() {
        return 'OK';
    }



    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // For UI localisations /multi language support (labels, messages etc)
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    private static map<string, string>mapDlgLocs;
    private static map<string, string>mapGlbLocs;
    public static map<string, string> getDialogueLocalisations() {
        if (mapDlgLocs == null) {
            mapDlgLocs = ServiceLocalisation.getDialogueLocalisations('ServiceIHLists', false); 
        }
        return mapDlgLocs; 
    }
    public static map<string, string> getGlobalLocalisations() {
        if (mapGlbLocs == null) {
            mapGlbLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false);    
        }
        return mapGlbLocs;
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // EXTENSION ACTION INTERFACES
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    global interface ExtensionProvider {
        ExtensionActionResult doAction (string ActionCode, string IHContext, string Params);
    }
    
    global class ExtensionActionResult {
        
        global boolean CompletedSuccessfully {get;set;}
        global string CompletionMessage {get;set;}
        global string PostActionNavigationDef {get;set;}
        
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // TREE SUPPORT INTERFACES
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    global interface TreeNodeSupplier {
        List<ServiceIHLists.ListingItem> getTreeNodes (string rootNode, integer maxLevels);
    }
    
    global enum KnownTreeOps {
        JITFetching,
        NodeOrdering 
    }
    
    global interface TreeOpsSupplier extends TreeNodeSupplier {
        List<KnownTreeOps> SupportedOperations();
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // CLASS REPRESENTING LISTING ITEMS (AS OPPOSED TO LUX TOOLS) IN LUX SCENARIOS
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    
    // For obtaining a listing item intended to serve as (current) record metadata,
    // as opposed to an actual listing row... 
    public static ListingItem getMetadataListingItem() {
        ListingItem LI = new ListingItem();
        LI.ActionCode = '[RecordMetadata]';
        return LI;
    }
    
    global class ListingItem  implements Comparable {
        
        global string Id {get; set;}            // Id of the record underlying this listing (the abstracted SF object)
        global string MasterId {get; set;}            // Cross org, master identifier
        global string Label {get; set;}         // A text label to display with this row
        global string Title {get; set;}         // Tip text for the same
        global string Icon {get; set;}          // An icon to display with this row
        global string IconLabel {get; set;}     // A text label for the same
        global string IconTitle {get; set;}     // Tip text for the same
        global string StyleClass {get; set;}    // CSS class to apply to the row as a whole
        global string ActionCode {get; set;}    // A message to pass to handling code when listing is clicked
        global string Parameters {get; set;}    // Additional parameters to pass with click info
        global string RowState {get; set;}      // Initial state of this row (e.g., bookmarked, updated, locked)                        
        global string Cols {get; set;}          // If provided, defines label text to use to produce multiple columns in a listing
        global string SupportedDrops {get;set;} // The object types (3 letter codes), if any, that can be dropped onto a given listing item in D&D
        global string SortValue {get; set;}     // Value to use for sorting nodes
        

        // Comparable interface implementation (for sorting)
        global Integer compareTo(Object compareTo) {
            
            // We want related help sorted alphabetically.
            
            try {
                ListingItem compLI = (ListingItem)compareTo;
                String thisSortName;
                String compSortName;

                if (SortValue != '' && SortValue != null && SortValue + '' != 'undefined' && SortValue + '' != 'null') {
                    // Use node's specified sort order, if supplied
                    thisSortName = SortValue;
                    compSortName = compLI.SortValue;
                    
                } else {
                    // Otherwise, default to sorting by node label
                    thisSortName = Label;
                    compSortName = compLI.Label;
                }
                                
                if (thisSortName == compSortName) return 0;
                if (thisSortName > compSortName) return 1;
                return -1;  
                
            } catch (exception e) {
                return 0;
            }
        }       
        
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // A class encapsulating the functionality required of a Help Reading List
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    public class ReadingList implements Comparable {

        public String Diags {get; set;}                     // Diagnostics / messages to user
        public String RLID {get; set;}                      // The ID of the reading list being viewed
        public String Mover {get; set;}                     // ID of a reading list entry that is being manipulated

        public String PrevURL {get; set;}                   // Link to move to previous topic in list ("<" feature)
        public String PrevName {get; set;}                  // Title of previous link - e.g, "Previous topic (name)"
        public String PrevClass {get; set;}                 // Defines whether "<" is enabled or disabled per position in list

        public String ListURL {get; set;}                   // Link to popup details about the Reading List
        public String ListName {get; set;}                  // The name of the Reading List
        public String ListSummary {get; set;}               // The summary text for the Reading List
        public String ListDescription {get; set;}           // The full Reading List description
        public String ListCSSClass {get; set;}              // (Additional) CSS class to apply to list - eg, featured or not

        public String NextURL {get; set;}                   // Link to move to next topic in list (">" feature)
        public String NextName {get; set;}                  // Title of next link - e.g, "Next topic (name)"
        public String NextClass {get; set;}                 // Defines whether ">" is enabled or disabled per position in list
        
        private String nSlides;
        public String getNavSlides() {return nSlides;}      // "Lozenges" for navigation to any topic in the list
        
        private String nGallery;
        public String getNavGallery() {return nGallery;}    // Similar to above but in pictorial preview form
        
        private String n1UX;
        public String getNavIH1UX() {return n1UX;}          // Navigation tool suited to SF1 UX
        public SelectOption[] RLEOptions {get; set;}        // Select options for a drop down of RL entries
        
        public String NavList {get; set;}                   // Navigation as list of RLEs as hyperlinks
        public String EditEntriesLink {get; set;}           // Link to page where list entries can be edited
        public String EditPropertiesLink {get; set;}        // Link to page where the list's details can be edited
        public String NewLink {get; set;}                   // Link for adding a new reading list
        public String NewEntryLink {get; set;}              // Link for adding a new entry to this reading list
        
        public RLEntry[] Entries {get; set;}                // The set of entries in the Reading List
                
        public Boolean IncludesCurrentTopic {get; set;}     // Flag indicating that current help topic is featured in this RL

                
        /////////////////////////////////////////////////////////////////////////////////////////////////////
        // Constructors & Initialisation
        /////////////////////////////////////////////////////////////////////////////////////////////////////
        

        // Initialise / set basic values
        private void initialise (ReadingList RL, Boolean isAuthor, Boolean isAdministrator) {
                                    
            this.Diags = '';
            this.Mover = '';
            this.PrevURL = '';
            this.PrevName = '';
            this.PrevClass = '';
            this.ListURL = '';
            this.ListName = '';
            this.ListSummary = '';
            this.ListDescription = '';
            this.ListCSSClass = '';
            this.NextURL = '';
            this.NextName = '';
            this.NextClass = '';
            nSlides = '';
            nGallery = '';
            n1UX = '';
            this.RLEOptions = new SelectOption[] {};
            this.NavList = '';
            this.EditEntriesLink = '';
            this.EditPropertiesLink = '';
            
            
            // Set to false initially: we only discover if there is an "Active" topic in building later...
            this.IncludesCurrentTopic = false;
            
            // Use community path, if relevant, in paths below...
            String RootUrl = ControllerSettings.getCommunityRoot();
            if (RootUrl == '') {
                RootUrl = URL.getOrgDomainURL().toExternalForm();
            }       
            
            
            // Ability to add reading lists and reading list entries is for authors and admins only
            if (isAdministrator || isAuthor){
                
                String Q = '\'';    
                String U = RootUrl + '/apex/iahelp__IHReadingListProperties?Mode=New';
                this.NewLink = U;
                
                this.NewEntryLink = '<a href="' + RootUrl + '/apex/iahelp__IHSearchResults?RLID=' + this.RLID + '&Opts=2" title="' + ServiceIHLists.getGlobalLocalisations().get('TipGenericAdd') + '">';
                this.NewEntryLink += '<div class="IHIcon32 IHIdle IHIconLink"></div></a>';
                
            } else {
                this.NewLink = '';
                this.NewEntryLink = '';
                
            }
            
            return;
        }
        
        
        // Constructor for basic/minimal ops
        public ReadingList() {
            ServiceSecurity Security = new ServiceSecurity();
            Boolean[] UPs = Security.UserPermissions();
            initialise(this, UPs[2], UPs[1]);
        }
        

        // Constructor for getting a reading list from its ID
        public ReadingList (String LstId) {
                        
            HelpReadingListEntry__c Ent;
            ReadingList RL;

            ServiceSecurity Security = new ServiceSecurity();
            Boolean[] UPs = Security.UserPermissions();

            Boolean showRLName = Schema.sObjectType.HelpReadingList__c.fields.Name.isAccessible();
            Boolean showRLSummary = Schema.sObjectType.HelpReadingList__c.fields.Summary__c.isAccessible();
            Boolean showRLDescription = Schema.sObjectType.HelpReadingList__c.fields.Description__c.isAccessible();
            Boolean showRLEName = Schema.sObjectType.HelpTopic__c.fields.Name.isAccessible();
            Boolean showRLEImageURL = Schema.sObjectType.HelpTopic__c.fields.ImageURL__c.isAccessible();
            Boolean showRLEVideoURL = Schema.sObjectType.HelpTopic__c.fields.VideoURL__c.isAccessible();
            
            
            try {
                                
                // Get a single entry in the requested reading list
                Ent = [SELECT Id, HelpTopic__c, ReadingOrder__c, HelpReadingList__c,                     
                            HelpReadingList__r.Name, HelpReadingList__r.Summary__c, 
                            HelpReadingList__r.Description__c, HelpReadingList__r.NumberOfEntries__c,
                            ReadingListFeaturedUntil__c                    
                
                        FROM HelpReadingListEntry__c
                        WHERE HelpReadingList__c = :LstId
                        LIMIT 1];

                // Use this, via our other constructor, to get a full reading list:
                // NB: if this constructor is used, we don't know the current help topic, so pass null...
                // NB: if this constructor is used, we're not in SF1, so can hard wire tools page version to classic
                Boolean isIH1UX = false;
                RL = new ReadingList (Ent, showRLName, showRLSummary, showRLDescription, showRLEName, showRLEImageURL, showRLEVideoURL, null, isIH1UX, UPs[2], UPs[1]);
                
                this.RLID = RL.RLID;
                
                this.PrevURL = RL.PrevURL;
                this.PrevName = RL.PrevName;
                this.PrevClass = RL.PrevClass;
        
                this.ListURL = RL.ListURL;
                this.ListName = RL.ListName;
                this.ListSummary = RL.ListSummary;
                this.ListDescription = RL.ListDescription;
                this.ListCSSClass = RL.ListCSSClass;
        
                this.NextURL = RL.NextURL;
                this.NextName = RL.NextName;
                this.NextClass = RL.NextClass;
        
                // NB: with the Nav slides in this case, we don't want to show an active item...
                nSlides = RL.getNavSlides();
                nGallery = RL.getNavGallery();
                n1UX = RL.getNavIH1UX();
                
                this.NavList = RL.NavList;
                this.EditEntriesLink = RL.EditEntriesLink;
                this.EditPropertiesLink = RL.EditPropertiesLink;
                this.NewLink = RL.NewLink;
                this.NewEntryLink = RL.NewEntryLink;
                                
                this.Entries = RL.Entries;
                
            } catch (exception e) {
                
                // On error, give this list object some basic diagnostics
                initialise (this, UPs[2], UPs[1]);
                RLID = LstId;
                this.ListName = ServiceIHLists.getGlobalLocalisations().get('MessageGenericError');
                this.ListSummary =  ServiceIHLists.getGlobalLocalisations().get('MessageGenericError') + ' - ' + e.getMessage();
                this.ListSummary +=' - Id: ' + LstId;
                                
            }
        }
        
        // Constructor for use when building reading list from one of its entries:
        // This version needs a set of booleans that reflect FLS for the relevant attributes
        // plus, if known/relevant, the help topic featured on the current page
        // (this affects setting of the "active" lozenge in nav slides)
        // plus details of Admin / Author rights
        public ReadingList (HelpReadingListEntry__c Ent, Boolean showRLName, Boolean showRLSummary, Boolean showRLDescription, Boolean showRLEName, Boolean showRLEImageURL, Boolean showRLEVideoURL, String CurrentHTID, Boolean isIH1UX, Boolean isAdministrator, Boolean isAuthor) {
                        
            HelpReadingList__c Lst;
            HelpReadingListEntry__c[] Ents;
            HelpReadingListEntry__c NearEnt;
            HelpReadingListEntry__c CurrentEnt = null;          
            DateTime dat = date.today();
            Boolean ExcludeInactiveTopics;
            String NavSlideTemplate;
            String TopicName;
            Decimal wRatio;                                             // Ratio of media W:H as set in topic 
            Decimal cHeight = 0;                                        // Callout height in use (active topic's)
            Decimal itemPadFacor = 0.15;                                // Controls additional padding around items
            Integer wTotal = 0;                                         // Total width of all gallery items
            Integer maxLinkWidth = 160;                                 // Maximum width allowed for item link text


            // Note the version of the Tools / Portal page UI to use (in links etc below)
            String PortalPage = ControllerSettings.getPortalPageName(isIH1UX);

            // Use community path, if relevant, in Urls below...
            String RootUrl = ControllerSettings.getCommunityRoot();
            if (RootUrl == '') {
                RootUrl = URL.getOrgDomainURL().toExternalForm();
            }       

                                    
            try {
                
                // Set out basic member data
                this.RLID = Ent.HelpReadingList__c;
                initialise(this, isAdministrator, isAuthor);       
                ExcludeInactiveTopics = !(isAdministrator || isAuthor);
                                           
                Diags = 'Reading List initialised... ';
 
                if (showRLName) {
                    ListName = Ent.HelpReadingList__r.Name;
                } else {
                    ListName = '';
                }
 
                if (showRLSummary) {
                    ListSummary = Ent.HelpReadingList__r.Summary__c;
                } else {
                    ListSummary = '';
                }
 
                if (showRLDescription) {
                    ListDescription = Ent.HelpReadingList__r.Description__c;
                } else {
                    ListDescription = '';
                }
 
                if (Ent.ReadingListFeaturedUntil__c >= dat.date()) {
                    ListCSSClass = 'Featured';
                } else {
                    ListCSSClass = '';
                }

                                
                ListURL = 'javascript:IHWebToolTips.DoTips("dfrm", "' + RootUrl + '/apex/iahelp__IHReadingListProperties?Id=' + this.RLID + '&HTID=' + CurrentHTID + '&Mode=Read", "7", 200, 590, event)';
    
                Diags += 'Basic list properties set, continuing to Entries... ';
                
                // Set up navigation "slides" by getting the other Entries in the list
                // to which the entry supplied belongs:
                Entries = new RLEntry[]{};
                
                // NB: we must filter here by Active flag on topics per user permissions...
                Ents = [
                    SELECT Id, HelpTopic__c, ReadingOrder__c,
                        HelpReadingList__c, HelpReadingList__r.ReadingListType__c, 
                        HelpTopic__r.Name, HelpTopic__r.Summary__c,  
                        HelpTopic__r.CalloutHeight__c, HelpTopic__r.CalloutMediaChoice__c, HelpTopic__r.ShowReadMoreLink__c,
                        HelpTopic__r.ImageURL__c, HelpTopic__r.ImageWidth__c, HelpTopic__r.ImageHeight__c,
                        HelpTopic__r.VideoURL__c, HelpTopic__r.VideoWidth__c, HelpTopic__r.VideoHeight__c,
                        HelpTopic__r.GuidedLayout__c, HelpTopic__r.GuidedRecord__c, HelpTopic__r.GuidedElement__c, HelpTopic__r.GuideStepMode__c, HelpTopic__r.GuideCallout__c,
                        HelpTopic__r.GuidedLayout__r.PageLayoutIdentifier__c,
                        HelpTopic__r.GuidedElement__r.Identifier__c, HelpTopic__r.GuidedElement__r.ElementType__c
                    FROM HelpReadingListEntry__c
                    WHERE HelpReadingList__c = :this.RLID 
                    AND (HelpTopic__r.Active__c = true OR HelpTopic__r.Active__c = :ExcludeInactiveTopics)
                    ORDER BY ReadingOrder__c
                ];

                Diags += 'Retrieved ' + Ents.size() + ' entries: building navigation tools... ';
                
                
                // Initialise navigations...
                nSlides = '';
                n1UX = '<select id="IH1ReadingListNavTool" class="IH1Input" onchange="javascript:cueTopic();">';
                NavList = '<ul id="IH1ReadingListNavList">';

                
                // ... and the image gallery, whose outermost container is a "viewport" for the whole...
                nGallery = '<div class="ReadingListGallery" style="height: 100%; width: 100%; overflow-x: auto; overflow-y: hidden;">';

                // ... "beneath" which is a "filmstrip" that can scroll from  side to side "under" the viewport:
                // NB: set width of this to a placeholder to be replaced when required size has been calculated
                nGallery += '<div class="ReadingListFilmstrip" style="height: 100%; width: RLFilmstripWidth;">';

                
                // Get the "active" topic's callout height: we'll need this for sizing various things.
                // We take a fraction of the stated callout height, as this is the portion that
                // will be occupied by an image in a gallery presentation (on the filmstrip)
                for (HelpReadingListEntry__c LE: Ents) {
                    if (LE.HelpTopic__c == CurrentHTID){
                        cHeight = LE.HelpTopic__r.CalloutHeight__c;
                        cHeight = math.round(cHeight * 0.3);
                        break;
                    }
                }


                Diags += 'Active topic adjusted callout height set to ' + cHeight + '... ';
               
                
                // Now loop to create nav gallery and slides
                for (HelpReadingListEntry__c LE: Ents) {
                    
                    // Get a topic name to use in multiple pieces of markup, below, that respects SF FLS
                    if (showRLEName) {
                        TopicName = LE.HelpTopic__r.Name;
                    } else {
                        TopicName = '[Topic]';
                    }
                    
                                        
                    Diags += 'Processing Entry ' + TopicName +'... ';
                    
                                        
                    // Both active and inactive gallery slides have many common features, so build these here...
                    NavSlideTemplate  = '<div class="GalleryMediaContainer" style="height: 80%; width: 100%;">';

                    // With the gallery we need to use the underlying help topic's preferred preview media:  
                    // this may be its image or video...
                    if (LE.HelpTopic__r.CalloutMediaChoice__c == 'Image') {                     
                        
                        Diags += 'Media choice is image... ';               
                        
                        if (showRLEImageURL) {
                            
                            // Check chosen media exists: 
                            if (LE.HelpTopic__r.ImageURL__c == '' || LE.HelpTopic__r.ImageURL__c == null) {
                                // Display "missing media" message if not...
                                // NB: assumption is that this is 1:1 aspect ratio!
                                NavSlideTemplate += '<div class="GalleryMediaPayload" style="height: 100%; width: ' + cHeight + 'px; margin: auto;">';
                                NavSlideTemplate += '<img src="../resource/iahelp__IHResources/img/ImgMediaMissing.png" style="height: 100%; width: 100%;" />';
                                NavSlideTemplate += '</div>';                                                   

                                // Keep track of total width...
                                if (cHeight < maxLinkWidth) {
                                    wTotal += maxLinkWidth + math.round(cHeight * itemPadFacor);        
                                } else {
                                    wTotal += math.round(cHeight) + math.round(cHeight * itemPadFacor);         
                                }                           
                        
                            } else {
                                // Continue to display media: work out the correct width to use.
                                // This is the ratio of image W to H: if H not set, use 1
                                if (LE.HelpTopic__r.ImageHeight__c == 0 || LE.HelpTopic__r.ImageHeight__c == null || LE.HelpTopic__r.ImageWidth__c == 0 || LE.HelpTopic__r.ImageWidth__c == null) {
                                    wRatio = 1;                                 
                                } else {
                                    wRatio = LE.HelpTopic__r.ImageWidth__c / LE.HelpTopic__r.ImageHeight__c;
                                }
                                                                
                                NavSlideTemplate += '<a target="_Blank" title="' + ServiceIHLists.getGlobalLocalisations().get('TipViewImageLink') + '" href="' + LE.HelpTopic__r.ImageURL__c + '">';
                                NavSlideTemplate += '<div class="GalleryMediaPayload" style="height: 100%; width: ' + math.round(wRatio * cHeight) + 'px; margin: auto;">';
                                NavSlideTemplate += '<img src="' + LE.HelpTopic__r.ImageURL__c + '" style="height: 100%; width: 100%;" />';
                                NavSlideTemplate += '</div></a>';                                                   

                                // Keep track of total width... 
                                if (math.round(wRatio * cHeight) < maxLinkWidth) {
                                    wTotal += maxLinkWidth + math.round(cHeight * itemPadFacor);        
                                } else {
                                    wTotal += math.round(wRatio * cHeight) + math.round(cHeight * itemPadFacor);
                                }                           

                            }
                            
                        } else {
                            NavSlideTemplate += '';                     
                        }
                        
                    } else {

                        Diags += 'Media choice is video... ';               

                        if (showRLEVideoURL) {
                            
                            // Check chosen media exists: 
                            if (LE.HelpTopic__r.VideoURL__c == '' || LE.HelpTopic__r.VideoURL__c == null) {
                                // Display "missing media" message if not...
                                // NB: assumption is that this is 1:1 aspect ratio!
                                NavSlideTemplate += '<div class="GalleryMediaPayload" style="height: 100%; width: ' + cHeight + 'px; margin: auto; ">';
                                NavSlideTemplate += '<img src="../resource/iahelp__IHResources/img/ImgMediaMissing.png" style="height: 100%; width: 100%;" />';
                                NavSlideTemplate += '</div>';                                                   

                                // Keep track of total width...
                                if (cHeight < maxLinkWidth) {
                                    wTotal += maxLinkWidth + math.round(cHeight * itemPadFacor);        
                                } else {
                                    wTotal += math.round(cHeight) + math.round(cHeight * itemPadFacor);         
                                }                           

                                
                            } else {
                                // Continue to display media: work out the correct width to use.
                                // This is the ratio of video W to H: if H not set, use 1
                                if (LE.HelpTopic__r.VideoHeight__c == 0 || LE.HelpTopic__r.VideoHeight__c == null || LE.HelpTopic__r.VideoWidth__c == 0 || LE.HelpTopic__r.VideoWidth__c == null) {
                                    wRatio = 1;                                 
                                } else {
                                    wRatio = LE.HelpTopic__r.VideoWidth__c / LE.HelpTopic__r.VideoHeight__c;
                                }

                                NavSlideTemplate += '<div class="GalleryMediaPayload" style="height: 100%; width: ' + math.round(wRatio * cHeight) + 'px; margin: auto;">';
                                NavSlideTemplate += '<iframe src="' + LE.HelpTopic__r.VideoURL__c + '" style="height: 100%; width: 100%;" frameborder="0" ></iframe>';                              
                                NavSlideTemplate += '</div>';                                                   

                                // Keep track of total width... 
                                if (math.round(wRatio * cHeight) < maxLinkWidth) {
                                    wTotal += maxLinkWidth + math.round(cHeight * itemPadFacor);        
                                } else {
                                    wTotal += math.round(wRatio * cHeight) + math.round(cHeight * itemPadFacor);
                                }                           
                            }

                        } else {
                            NavSlideTemplate += '';                     
                        }
                    }
                    
                    
                    NavSlideTemplate += '</div>';   // Close GalleryMediaPayload
                                        

                    // We only want the topic name text to be a hyperlink (to the Tools page) in cases 
                    // where the Topic Author has specified that the "more" link should be available...
                    NavSlideTemplate += '<div class="GalleryLink" style="height: 25%; max-width: ' + maxLinkWidth + 'px; margin: auto; text-align: center; overflow: hidden; " >';

                    if (LE.HelpTopic__r.ShowReadMoreLink__c == true || (isAdministrator || isAuthor)) {
                        
                        String U = RootUrl + '/apex/iahelp__' + PortalPage + '?HTID=' + LE.HelpTopic__c;
                        Boolean isConsolePage = ControllerSettings.isConsolePage();
                        
                        // Admins always see the read more link, but are advised that users will not:
                        // Also, read more link varies depending on whether this is a console situation
                        
                        if (LE.HelpTopic__r.ShowReadMoreLink__c == false) {
                            if (isConsolePage == true) {
                                NavSlideTemplate += '<a class="Authoring" title="' + ServiceIHLists.getGlobalLocalisations().get('TipReadMoreLinkAuthors') + '" href="#" onclick="javascript:IHQAMenu.openPrimaryTab (\'' + U + '\', \'' + TopicName + '\')">[';                                                                
                            } else {
                                NavSlideTemplate += '<a class="Authoring" target="_Blank" title="' + ServiceIHLists.getGlobalLocalisations().get('TipReadMoreLinkAuthors') + '" href="' + U + '">[';                                
                            }
                            
                        } else {
                            if (isConsolePage == true) {
                                NavSlideTemplate += '<a title="' + ServiceIHLists.getGlobalLocalisations().get('TipGoto') + ' ' + TopicName + '" href="#" onclick="javascript:IHQAMenu.openPrimaryTab (\'' + U + '\', \'' + TopicName + '\')">';                                
                            } else {
                                NavSlideTemplate += '<a target="_Blank" title="' + ServiceIHLists.getGlobalLocalisations().get('TipGoto') + ' ' + TopicName + '" href="' + U + '">';
                            }                           
                        }
                        
                    }
                    
                    NavSlideTemplate += TopicName;
                    
                    if (LE.HelpTopic__r.ShowReadMoreLink__c == true || (isAdministrator || isAuthor)) {
                        if (LE.HelpTopic__r.ShowReadMoreLink__c == false) {
                            NavSlideTemplate += ']</a>';                            
                        } else {
                            NavSlideTemplate += '</a>';                         
                        }
                    }


                    NavSlideTemplate += '</div>';   // Close GalleryLink
                    NavSlideTemplate += '</div>';   // Close GalleryMediaContainer



                    if (LE.HelpTopic__c == CurrentHTID){ 
                        // If this is the "active" entry (the current topic) mark it accordingly
                        nSlides += '<div title="[' + ServiceIHLists.getGlobalLocalisations().get('TipButtonNavCurrentTopic') + ']" class="IHIcon IHIconEntryActive"></div>';
                        
                        nGallery += '<div class="GalleryItem Active" style="height: 86%; width: auto; float: left; ">';
                        nGallery += NavSlideTemplate;
                        
                        // Also, take a note of this current entry record
                        CurrentEnt = LE;
                        
                        // Also, note the fact that we have a current record
                        IncludesCurrentTopic = true;
                        
                    } else {                        
                        // If not, show "standard" entry information                        
                        nSlides +='<a title="' + ServiceIHLists.getGlobalLocalisations().get('TipGoto') + ' ' + TopicName + '" href="' + RootUrl + '/apex/iahelp__' + PortalPage + '?HTID=' + LE.HelpTopic__c + '">';
                        nSlides += '<div class="IHIcon IHIconEntryInactive"></div>';
                        nSlides += '</a>';

                        // If slide is not active, just add the slide...
                        nGallery += '<div class="GalleryItem" style="height: 86%; width: auto; float: left; ">';
                        nGallery += NavSlideTemplate;
                    }
                    
                    
                    // Add a select OPTION for each RL entry when in IH1 UX, plus a list item for 
                    // expanded / list type nav view
                    n1UX += '<option value="' + LE.HelpTopic__c + '"';
                    NavList += '<li id="IHRLE' + LE.HelpTopic__c + '"';
                    if (LE.HelpTopic__c == CurrentHTID){
                        n1UX += ' selected';
                        NavList += ' class="Active"';
                    }
                    n1UX += '>' + TopicName + '</option>';
                    
                    
                    // Also add individual select options for any desired apex select control for the same RL entries
                    RLEOptions.add(new SelectOption(LE.HelpTopic__r.Id, LE.HelpTopic__r.Name));
                    
                    
                    NavList += '><a href="#topic' + LE.HelpTopic__c + '" name="topic' + LE.HelpTopic__c + '" onclick="javascript:cueTopicL(\'' + LE.HelpTopic__c + '\')">' + TopicName + '</a></li>';
                    
                    // As we build the nav slides, keep a collection of the actual reading list entries
                    RLEntry RLE = new RLEntry(LE, TopicName, isAdministrator, isAuthor);                    
                    Entries.add(RLE);
                    
                    
                } // End FOR : Reading List Entries / LE
                
                
                
                // Replace filmstrip placeholder width with the actual required value, as calculated above
                nGallery = nGallery.replace('RLFilmstripWidth', String.valueOf(wTotal) + 'px;');
                
                // Close the filmstrip
                nGallery += '</div>';
                
                // Close the gallery as a whole
                nGallery += '</div>';
                                
                // Close IH1 UX Nav tools
                n1UX += '</select>';
                NavList += '</ul>';
                
                
                Diags += 'Navigation tools built: continuing to editing links... ';
                
                // Also, set up links for editing this reading list's entries and properties:
                // NB: these are based on access rights...
                
                String Q = '\'';

                if (isAdministrator || isAuthor){
                    EditPropertiesLink = '<a href="#" title="' + ServiceIHLists.getGlobalLocalisations().get('TipGenericEdit') + '" onclick="javascript:IHWebToolTips.DoTips(' + Q + 'dfrm' + Q + ', ' + Q + RootUrl + '/apex/iahelp__IHReadingListProperties?Id=' + this.RLID + '&Mode=Edit' + Q + ', ' + Q + '7' + Q + ', 200, 548, event);"><div class="IHIcon IHIconEdit"></div></a>';
                    EditEntriesLink = '<a title="' + ServiceIHLists.getGlobalLocalisations().get('TipGenericEdit') + '" href="#" onclick="javascript:IHWebToolTips.DoTips(' + Q + 'dfrm' + Q + ', ' + Q + RootUrl + '/apex/iahelp__IHManageReadingList?RList=' + this.RLID + Q + ', ' + Q + '7' + Q + ', 200, 470, event);"><div class="IHIcon IHIconEditList"></div></a>';
                } else {
                    EditPropertiesLink = '';
                    EditEntriesLink = '';
                }
                
                
                                                                
            } catch (exception e) {
                ListName = ServiceIHLists.getGlobalLocalisations().get('MessageGenericError');
                ListSummary = e.getTypeName() + ' - ' + e.getMessage() + ' - ' + Diags;
                ListURL = 'javascript:alert("'+ ListSummary + '");';
            }
                        
                        
            Diags += 'and previous link... ';
            
            // Do not provide a rendering of this if global settings have turned this off
            if (ControllerSettings.getSettings().RLShowNextPrev__c == false ) {
                PrevURL = '#';
                PrevName = '';
                PrevClass = '';
                
            } else {
                // Get the previous help topic
                // NB: both next & previous links rely on there being a known "current" help topic
                // (cannot take this to be the entry/Ent that called this constructor)
                if (CurrentEnt != null) {
                    if (CurrentEnt.ReadingOrder__c > 0) {
                        try {
                            // To do this, get the closest previous entry in this reading list
                            // NB: this is the last entry of lower reading order we find                        
                            for (HelpReadingListEntry__c LE: Ents) {
                                if (LE.readingOrder__c <= CurrentEnt.ReadingOrder__c - 1) {
                                    NearEnt = LE;
                                }
                            }
                                                                    
                            // Now set previous link etc accordingly
                            if (NearEnt != null) {
                                PrevURL = RootUrl + '/apex/iahelp__' + PortalPage + '?HTID=' + NearEnt.HelpTopic__c;
                                
                                if (showRLEName) {
                                    PrevName = ServiceIHLists.getDialogueLocalisations().get('TipNavPrevious') + ' (' + NearEnt.HelpTopic__r.Name + ')';
                                } else {
                                    PrevName = ServiceIHLists.getDialogueLocalisations().get('TipNavPrevious');
                                }
                                
                                PrevClass = 'IHIcon IHIconNavPrevious';
                                
                            } else {
                                PrevURL = '#';
                                PrevName = ServiceIHLists.getDialogueLocalisations().get('TipNavPreviousUnavailable');
                                PrevClass = 'IHIcon IHIconNavFirst';                            
                            }
                                                
                        } catch (exception e) {
                            PrevURL = '#';
                            PrevName = e.getTypeName() + ': ' + e.getMessage();
                            PrevClass = 'IHIcon IHIconNavFirst';                                
                            ListName = 'Error!';
                            ListSummary = e.getTypeName() + ': ' + e.getMessage() + ': Diagnostics: ' + Diags;
                                
                        }
                                        
                    } else {
                        PrevURL = '#';
                        PrevName = ServiceIHLists.getDialogueLocalisations().get('TipNavPreviousUnavailable');
                        PrevClass = 'IHIcon IHIconNavFirst';
                    }
                    
                } else {
                    PrevURL = '#';
                    PrevName = ServiceIHLists.getDialogueLocalisations().get('TipNavPreviousUnavailable');
                    PrevClass = 'IHIcon IHIconNavFirst';                
                }
            }
                                    
            
            Diags += 'and next link... ';
            
            
            // Do not provide a rendering of this if global settings have turned this off
            if (ControllerSettings.getSettings().RLShowNextPrev__c == false ) {
                NextURL = '#';
                NextName = '';
                NextClass = '';
                
            } else {
                // Get the next help topic
                if (CurrentEnt != null) {
    
                    try {
                        // To do this, get the next entry in this reading list:
                        // NB: this is the first entry of higher reading order we find
                        NearEnt = null;
                        
                        for (HelpReadingListEntry__c LE: Ents) {
                            if (LE.readingOrder__c >= CurrentEnt.ReadingOrder__c + 1) {
                                NearEnt = LE;
                                break;
                            }
                        }                    
                                            
                        // Now set next link etc accordingly
                        if (NearEnt != null) {
                            NextURL = RootUrl + '/apex/iahelp__' + PortalPage + '?HTID=' + NearEnt.HelpTopic__c;
                            
                            if (showRLEName) {
                                NextName = ServiceIHLists.getDialogueLocalisations().get('TipNavNext') + ' (' + NearEnt.HelpTopic__r.Name + ')';                    
                            } else {
                                NextName = ServiceIHLists.getDialogueLocalisations().get('TipNavNext');                    
                            }
                            
                            NextClass = 'IHIcon IHIconNavNext';
                            
                        } else {
                            NextURL = '#';
                            NextName = ServiceIHLists.getDialogueLocalisations().get('TipNavNextUnavailable');
                            NextClass = 'IHIcon IHIconNavLast';                                         
                        }
                                                                    
                    } catch (exception e) {
                        NextURL = '#';
                        NextName = e.getTypeName() + ': ' + e.getMessage() + ': Diagnostics: ' + Diags;
                        NextClass = 'IHIcon IHIconNavLast';                                 
                    }
        
                    
                } else {
                    NextURL = '#';
                    NextName = ServiceIHLists.getDialogueLocalisations().get('TipNavNextUnavailable');
                    NextClass = 'IHIcon IHIconNavLast';             
                }
            }
            
            
        }
    
        
        /////////////////////////////////////////////////////////////////////////////////////////////////////
        // Comparable interface implementation (for sorting)
        /////////////////////////////////////////////////////////////////////////////////////////////////////
        public Integer compareTo(Object compareTo) {
            
            // We want reading lists sorted such that featured items are first,
            // with all items then sorted alphabetically.
            // So: tack a "0" on the front of the name of featured lists
            // and "1" on the front of others, then calculate the sort...
            
            try {
                ReadingList compRL = (ReadingList)compareTo;
                String thisSortName = ListName;
                String compSortName = compRL.ListName;
                
                
                if (ListCSSClass == 'Featured') {
                    thisSortName = '0' + thisSortName;
                } else {
                    thisSortName = '1' + thisSortName;
                }
                
                if (compRL.ListCSSClass == 'Featured') {
                    compSortName = '0' + compSortName;
                } else {
                    compSortName = '1' + compSortName;
                }
                
                if (thisSortName == compSortName) return 0;
                if (thisSortName > compSortName) return 1;
                return -1;  
                
            } catch (exception e) {
                return 0;
            }
        }

        
        /////////////////////////////////////////////////////////////////////////////////////////////////////
        // Reading list entry manipulation functions
        /////////////////////////////////////////////////////////////////////////////////////////////////////       

        // To move a reading list entry up the list
        public PageReference moveUp () {

            ServiceSecurity Security = new ServiceSecurity();
            Integer i;
            Integer MoverOldPos = -1;
                        
            try {
                
                // Use community path, if relevant, in Urls below...
                String RootUrl = ControllerSettings.getCommunityRoot();
                if (RootUrl == '') {
                    RootUrl = URL.getOrgDomainURL().toExternalForm();
                }       
                

                // Reading list manipulation subject to admin / author rights
                if (Security.IsAllowed(ServiceSecurity.KnownSecureOperations.AdministerHelp) || Security.IsAllowed(ServiceSecurity.KnownSecureOperations.EditHelp)){
                    
                    // Iterate through our entries
                    for (i=0; i<Entries.size(); i++) {
                        
                        // Renumber entries as we go with "sensible" values (matching their actual position)
                        Entries[i].EntryRecord.ReadingOrder__c = i;
                        update Entries[i].EntryRecord;
                        
                        // In doing this, note the position of the one with the requested ID (Mover)                
                        if (Entries[i].EntryRecord.Id == Mover) {
                            MoverOldPos = i;
                        }
                    }
    
                    // Now re-order the two relevant items, where required
                    if (MoverOldPos > 0) {
                        Entries[MoverOldPos].EntryRecord.ReadingOrder__c = MoverOldPos - 1;
                        update Entries[MoverOldPos].EntryRecord;
    
                        Entries[MoverOldPos - 1].EntryRecord.ReadingOrder__c = MoverOldPos;
                        update Entries[MoverOldPos - 1].EntryRecord;                    
                    } 
                    
                    Diags = ServiceIHLists.getGlobalLocalisations().get('MessageGenericTaskComplete');
                    return new ApexPages.Pagereference(RootUrl + '/apex/iahelp__IHManageReadingList?RList=' + RLID);
                    
                } else {
                    Diags = ServiceIHLists.getGlobalLocalisations().get('MessageNoRights');
                    return null;
                }
                
                
            } catch (exception e) {
                Diags = e.getMessage();
                return null;
            }           
            
        }
        

        // To move a reading list entry down the list
        public PageReference moveDown () {

            ServiceSecurity Security = new ServiceSecurity();
            Integer i;
            Integer MoverOldPos = -1;
            PageReference PRef = null;
            
            try {
                
                // Use community path, if relevant, in Urls returned below...
                String RootUrl = ControllerSettings.getCommunityRoot();
                if (RootUrl == '') {
                    RootUrl = URL.getOrgDomainURL().toExternalForm();
                }       
                

                // Reading list manipulation subject to admin / author rights
                if (Security.IsAllowed(ServiceSecurity.KnownSecureOperations.AdministerHelp) || Security.IsAllowed(ServiceSecurity.KnownSecureOperations.EditHelp)){

                    // Iterate through our entries
                    for (i=0; i<Entries.size(); i++) {
                        
                        // Renumber entries as we go with "sensible" values (matching their actual position)
                        Entries[i].EntryRecord.ReadingOrder__c = i;
                        update Entries[i].EntryRecord;
                        
                        // In doing this, note the position of the one with the requested ID (Mover)                
                        if (Entries[i].EntryRecord.Id == Mover) {
                            MoverOldPos = i;
                        }
                    }
    
                    // Now re-order the two relevant items, where required
                    if (MoverOldPos < Entries.size()-1) {
                        Entries[MoverOldPos].EntryRecord.ReadingOrder__c = MoverOldPos + 1;
                        update Entries[MoverOldPos].EntryRecord;
    
                        Entries[MoverOldPos + 1].EntryRecord.ReadingOrder__c = MoverOldPos;
                        update Entries[MoverOldPos + 1].EntryRecord;                    
                    } 
                    
                    Diags = ServiceIHLists.getGlobalLocalisations().get('MessageGenericTaskComplete');
                    PRef = new ApexPages.Pagereference(RootUrl + '/apex/iahelp__IHManageReadingList?RList=' + RLID);
                
                } else {
                    Diags = ServiceIHLists.getGlobalLocalisations().get('MessageNoRights');
                }
                
            } catch (exception e) {
                Diags = e.getMessage();
            }           

            return PRef;
        }
        
        
        // To add a reading list entry
        public String addItem(String HTID, String RLID) {
            
            ServiceSecurity Security = new ServiceSecurity();
            String retVal;
            
            try {

                // Reading list manipulation subject to admin / author rights
                if (Security.IsAllowed(ServiceSecurity.KnownSecureOperations.AdministerHelp) || Security.IsAllowed(ServiceSecurity.KnownSecureOperations.EditHelp)){

                    // Set our RLID member if not already done
                    if (this.RLID == '' || this.RLID == null || this.RLID + '' == 'undefined') {
                        this.RLID = RLID;
                    }
                    
                    HelpReadingListEntry__c RLE = new HelpReadingListEntry__c();
                    
                    // Get the requested reading list, so we know the number of entries
                    HelpReadingList__c RL = [SELECT NumberOfEntries__c FROM HelpReadingList__c WHERE Id=:RLID];
                    
                    RLE.HelpReadingList__c = RLID;
                    RLE.HelpTopic__c = HTID;                    
                    RLE.ReadingOrder__c = RL.NumberOfEntries__c;
                    
                    insert RLE;
                    retVal = ServiceIHLists.getDialogueLocalisations().get('MessageAddedRLEntry');

                } else {
                    retVal = ServiceIHLists.getGlobalLocalisations().get('MessageNoRights');
                    //return null;
                }
                
            } catch (exception e) {
                retVal = ServiceIHLists.getGlobalLocalisations().get('MessageGenericError') + ' - ' + e.getMessage();
            }
            
            Diags = retVal;
            return retVal;
        }       
        

        // To delete a reading list entry
        public PageReference deleteItem() {
            
            ServiceSecurity Security = new ServiceSecurity();
            String retVal;
            PageReference PRef = null;
            Integer numDeletes = 0;
            Integer i;
            
            try {
                // Use community path, if relevant, in Urls returned below...
                String RootUrl = ControllerSettings.getCommunityRoot();
                if (RootUrl == '') {
                    RootUrl = URL.getOrgDomainURL().toExternalForm();
                }       

                // Reading list manipulation subject to admin / author rights
                if (Security.IsAllowed(ServiceSecurity.KnownSecureOperations.AdministerHelp) || Security.IsAllowed(ServiceSecurity.KnownSecureOperations.EditHelp)){
                    HelpReadingListEntry__c RLE = [SELECT Id, HelpReadingList__c FROM HelpReadingListEntry__c WHERE Id=:Mover];
                    
                    // Set our RLID member if not already done
                    if (this.RLID == '' || this.RLID == null || this.RLID + '' == 'undefined') {
                        this.RLID = RLE.HelpReadingList__c;
                    }

                    
                    // NB: Renumbering / re-ordering of remaining RLEs now handled by RLE delete trigger
                    delete RLE;

                                        
                    retVal = ServiceIHLists.getDialogueLocalisations().get('MessageDeletedRLEntry') + ' ' + Mover;
                    PRef = new ApexPages.Pagereference(RootUrl + '/apex/iahelp__IHManageReadingList?RList=' + RLID);
                    
                } else {
                    retVal = ServiceIHLists.getGlobalLocalisations().get('MessageNoRights');
                }
                                
            } catch (exception e) {
                retVal = e.getMessage();
            }
            
            Diags = retVal;
            return PRef;
        }

    }
    
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Class encapsulating the features our reading list entries require:
    // This includes aspects of the reading list entry itself and its related help topic
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    public class RLEntry {
        
        public HelpReadingListEntry__c EntryRecord {get; set;}
        public String EntryName {get; set;}
        public String MoveUpIcon {get; set;}
        public String MoveDownIcon {get; set;}
        public String DeleteIcon {get; set;}
        
        
        public RLEntry (HelpReadingListEntry__c RLE, String EName, Boolean isAdministrator, Boolean isAuthor) {
            
            this.EntryRecord = RLE;
            this.EntryName = EName;
            
            // Reading list manipulation subject to admin / author rights
            if (isAdministrator || isAuthor){
                MoveUpIcon = '<div class="IHIcon IHIconNavUp"></div>';
                MoveDownIcon = '<div class="IHIcon IHIconNavDown"></div>';
                DeleteIcon = '<div class="IHIcon IHIconUnlink"></div>';
                
            } else {
                MoveUpIcon = '';
                MoveDownIcon = '';
                DeleteIcon = '';
                
            }
            
        }
        
    }
    


    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // A class encapsulating the functionality required of Related Help Topics
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    public class RelatedHelpListItem implements Comparable {
                
        public String HRID {get; set;}
        public String Name {get; set;}
        public String Summary {get; set;}
        
public integer Order {get;set;}
        
        public String ItemURL {get; set;}
        public String RelItemHTID {get; set;}
        public String RClass {get; set;}
        public String DeleteIcon {get; set;}
        public String Diags {get; set;}
        
        public HelpRelationship__c HR {get; set;}
                   
        // Full, standard constructor
        public RelatedHelpListItem (HelpRelationship__c Rel, String CurrentHTID, Boolean showName, Boolean showSummary, Boolean showItemURL, Boolean isIH1UX, Boolean showDeleteIcon){
                        
            HRID = Rel.Id;
            HR = Rel;
            String PortalPage;
            
try {
    Order = integer.valueOf(HR.Order__c);
    if (Order == null) {
        Order = 0;
    }
} catch (exception e) {
    Order = 0;
}           
                        
            try {
                
                // Use community path, if relevant, in Urls below...
                String RootUrl = ControllerSettings.getCommunityRoot();
                if (RootUrl == '') {
                    RootUrl = URL.getOrgDomainURL().toExternalForm();
                }                       
                
                // Page on which to show related help depends on whether we're in SF1
                PortalPage = ControllerSettings.getPortalPageName(isIH1UX);

                
                // Set our member data from incoming related help record
                if (CurrentHTID == Rel.ReferringTopic__c) {
                    // Refers to / source
                    RClass = 'IHIcon IHIconRelatedFromHere';                    
                    RelItemHTID = Rel.RelatedHelpTopic__c;
                    
                    if (showItemURL) {
                        ItemURL = RootUrl + '/apex/iahelp__' + PortalPage + '?HTID=' + Rel.RelatedHelpTopic__c;
                    } else {
                        ItemURL = '#';
                    }

                    if (showName) {
                        Name = Rel.RelatedHelpTopic__r.Name;
                    } else {
                        Name = '';
                    }

                    if (showSummary) {
                        Summary = Rel.RelatedHelpTopic__r.Summary__c;
                    } else {
                        Summary = '';
                    }
                    
                    
                } else {
                    // Referred from / destination
                    RClass = 'IHIcon IHIconRelatedToHere';
                    RelItemHTID = Rel.ReferringTopic__c;
                    
                    if (Schema.sObjectType.HelpRelationship__c.fields.ReferringTopic__c.isAccessible()) {
                        ItemURL = RootUrl + '/apex/iahelp__' + PortalPage + '?HTID=' + Rel.ReferringTopic__c;
                    } else {
                        ItemURL = '#';
                    }

                    if (showName) {
                        Name = Rel.ReferringTopic__r.Name;
                    } else {
                        Name = '';
                    }

                    if (showSummary) {
                        Summary = Rel.ReferringTopic__r.Summary__c;
                    } else {
                        Summary = '';
                    }
                    
                }


                // Ability to manipulate related help is dependent on author / admin rights
                if (showDeleteIcon) {
                    DeleteIcon = '<div class="IHIcon IHIconUnlink"></div>';
                                                                            
                } else {
                    DeleteIcon = '';
                }
                
                Diags = ServiceIHLists.getDialogueLocalisations().get('MessageAddedRelatedHelp');
                                                                                                    
            } catch (exception e) {
                Name = 'Error!';
                Summary = e.getMessage(); 
                Diags = Summary;            
            }
        }

        
        
        // Deletes the Help Relationship record specified by the ID passed in
        public PageReference deleteItem() {
            
            String retVal;
            ServiceSecurity Security = new ServiceSecurity();
            
            try {
                if (Security.IsAllowed(ServiceSecurity.KnownSecureOperations.AdministerHelp) || Security.IsAllowed(ServiceSecurity.KnownSecureOperations.EditHelp)) {
                    HelpRelationship__c HR = [SELECT Id FROM HelpRelationship__c WHERE Id=:HRID];
                    delete HR;
                    retVal = ServiceIHLists.getDialogueLocalisations().get('MessageDeletedRelatedHelp') + ' ' + HRID;
                    
                } else {
                    retVal = ServiceIHLists.getGlobalLocalisations().get('MessageNoRights');
                }
                
            } catch (exception e) {
                retVal = e.getMessage();
            }
            
            Diags = retVal;
            return null;
        }


        // Comparable interface implementation (for sorting)
        public Integer compareTo(Object compareTo) {
            
            // We want related help sorted alphabetically.
// TO DO: TAKE ACCOUNT (OPTIONALLY?) OF INTEGER ORDER HERE - AS OPPOSED TO STRICT ALPHA SORT...
            
            try {
                RelatedHelpListItem compRH = (RelatedHelpListItem)compareTo;
                String thisSortName = Name;
                String compSortName = compRH.Name;
                                
                if (thisSortName == compSortName) return 0;
                if (thisSortName > compSortName) return 1;
                return -1;  
                
            } catch (exception e) {
                return 0;
            }
        }
        
    }



    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // A class encapsulating the functionality required of Related Help Resources
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    public class RelatedResourcesListItem {

        public String Diags {get; set;}        
        public String HTRID {get; set;}

        public String Name {get; set;}
        public String ResourceURL {get; set;}
        public String Preview {get; set;}
        public String PreviewURL {get; set;}
        public String Location {get; set;}
        public String Summary {get; set;}
        public String UsageNotes {get; set;}

        public String DeleteIcon {get; set;}
        public String EditIcon {get; set;}

        
        public RelatedResourcesListItem (HelpTopicResource__c HTR, Boolean showName, Boolean showSummary, Boolean showResourceURL, Boolean showPreview, Boolean showPreviewURL, Boolean showLocation, Boolean showUsageNotes, Boolean showDeleteIcon){
                                                                                                
            try {
                String RID = HTR.HelpResource__c;
                
                // Set our member data from incoming resource details
                HTRID = HTR.Id;
                
                if (showUsageNotes) {
                    UsageNotes = HTR.UsageNotes__c;
                } else {
                    UsageNotes = '';
                }

                if (showName) {
                    Name = HTR.HelpResource__r.Name;
                } else {
                    Name = '';
                }

                if (showResourceURL) {
                    ResourceURL = HTR.HelpResource__r.ResourceURL__c;
                } else {
                    ResourceURL = '#';
                }

                if (showPreview) {
                    Preview = HTR.HelpResource__r.Preview__c;
                } else {
                    Preview = '';
                }

                if (showPreviewURL) {
                    PreviewURL = HTR.HelpResource__r.PreviewURL__c;
                } else {
                    PreviewURL = '#';
                }

                if (showLocation) {
                    Location = HTR.HelpResource__r.Location__c;
                } else {
                    Location = '';
                }

                if (showSummary) {
                    Summary = HTR.HelpResource__r.Summary__c;
                } else {
                    Summary = '';
                }
                
                
                // Ability to manipulate related resources is dependent on author / admin rights
                if (showDeleteIcon) {
                    // Use community path, if relevant
                    String RootUrl = ControllerSettings.getCommunityRoot();
                    if (RootUrl == '') {
                        RootUrl = URL.getOrgDomainURL().toExternalForm();
                    }       
                    
                    this.DeleteIcon = '<div class="IHIcon IHIconUnlink"></div>';    
                    this.EditIcon = '<a title="' + ServiceIHLists.getGlobalLocalisations().get('TipButtonEditResourceNotes') + '" target="_Blank" href="' + RootUrl + '/' + HTR.Id + '/e"><div class="IHIcon IHIconEdit"></div></a>';                                                                       
                } else {
                    DeleteIcon = '';
                    this.EditIcon = '';
                }

            } catch (exception e) {
                Name = 'Error!';
                ResourceURL = '#';
                Preview = 'BROKEN RESOURCE';
                PreviewURL = '#';
                Location = '';
                Summary = e.getMessage();             
                DeleteIcon = '';
                EditIcon = '';
            }
        }
        
        
        // Deletes the Related Help Resource record specified by the ID passed in
        public PageReference deleteItem() {
            
            String retVal;
            ServiceSecurity Security = new ServiceSecurity();
            
            try {
                if (Security.IsAllowed(ServiceSecurity.KnownSecureOperations.AdministerHelp) || Security.IsAllowed(ServiceSecurity.KnownSecureOperations.EditHelp)) {
                    HelpTopicResource__c HTR = [SELECT Id FROM HelpTopicResource__c WHERE Id=:HTRID];
                    delete HTR;
                    retVal = ServiceIHLists.getDialogueLocalisations().get('MessageDeletedRelatedResource') + ' ' + HTRID;
                    
                } else {
                    retVal = ServiceIHLists.getGlobalLocalisations().get('MessageNoRights');
                }
                
            } catch (exception e) {
                retVal = e.getMessage();
            }
            
            Diags = retVal;
            return null;
        }
        
                
    } 



    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // A class encapsulating the functionality required of Bookmarks
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    public class BookmarkListItem {
                
        public String Name {get; set;}
        public String Summary {get; set;}
        public String ItemURL {get; set;}
        public String HTID {get; set;}
                
        public BookmarkListItem (HelpBookmark__c Bmk, Boolean showName, Boolean showSummary){
            
            if (Schema.sObjectType.HelpBookmark__c.fields.TopicURL__c.isAccessible()) {
                ItemURL = Bmk.TopicURL__c ;
            } else {
                ItemURL = '#';
            }
            
            
            // Look up the help topic to get its name and summary
            try {
                HTID = Bmk.HelpTopic__c; 
                
                if (showName) {
                    
                    // Prefer the bookmark label, if supplied
                    if (Bmk.HelpBookmarkLabel__c != null && Bmk.HelpBookmarkLabel__c != '') {
                        Name = Bmk.HelpBookmarkLabel__c;
                    } else {
                        Name = Bmk.HelpTopic__r.Name;                       
                    }
                    
                } else {
                    Name = '';
                }
                
                if (showSummary) {
                    Summary = Bmk.HelpTopic__r.Summary__c;
                } else {
                    Summary = '';
                }
                
                    
            } catch (exception e) {
                Name = 'Error!';
                Summary = e.getMessage();
                //Summary = 'Related topic no longer exists';             
            }                       
        }
    }

}