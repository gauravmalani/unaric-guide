/////////////////////////////////////////////////////////////////////////////////////////////////////
// CLASS OFFERING INTERNATIONALISATION, LOCALISED BRANDING AND WHITE LABELLING SERVICES
//
// Martin Little for Improved Apps
// March 2015
/////////////////////////////////////////////////////////////////////////////////////////////////////

public with sharing class ServiceLocalisation {
        
    private static Folder Fld;
    private static Document Doc;
    private static boolean LocaleDocExists = true; 
    private static boolean LocaleSRExists = true; 
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // PUBLIC INTERFACE
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    
    // Gets a map of all localisation texts (labels, button text etc) for a given screen (dialogue)
    // in the form of a map of localisable element IDs to the text they should contain 
    public static map<string, string> getDialogueLocalisations(String DlgName, Boolean CheckPrefix) {
        
        map<string, string> mLocs;
        string Locale;
        Blob bInfo;     
        String context;
        String CPrefix;


        try {
            
            // We will have been passed the name of a dialogue - often via settings controller seeking
            // the object ID associated with a particular URL. In communities, this will be
            // in the form "CommunityName/ObjectIdentifier". We cannot know the names of these communities,
            // so we cannot use them as part of our search. Here, then, if the dialogue name passed begins
            // with the name of the current community, remove it:
            
            // v1.25: If we're certain of the name of the dialogue being sought, caller can specify that 
            // this check (costly in SOQL terms) is not required...
            
            if (CheckPrefix == true) {
                string[] DInfo = ControllerSettings.getDomainInfo(URL.getCurrentRequestUrl().toExternalForm());
                CPrefix = DInfo[1];         
    
                if (DlgName.startsWith(CPrefix + '/')) {
                    DlgName = DlgName.substring(CPrefix.length() + 1);
                }               
            }
            
            
            // We use maps to pass label info to localised pages - but these will fail with untrappable errors
            // if the keys sought in page markup are not present in the maps we return. So: we cannot
            // merely fill the map with the values found in some source (a locale specific XML file) in case
            // it is for some reason not fully completed.
            // Instead, we must PRE-FILL the map with default values to ensure all required keys are present
            // then overwrite these where we find translations in the XML...            
            mLocs = getDefaultDialogueLocalisations(DlgName);
            
            
            // If there's no localisations returned, we have a problem
            if (mLocs.size() == 0) {
                mLocs.put('Error', 'No localisations returned for "' + DlgName + '"');
                return mLocs;
            }
            
            // With defaults in place, we can look for translations in locale-specific XML, if it exists:
            try {
                
                // Only bother if we haven't already tried and failed to locate the document
                if (LocaleDocExists != false) {
                    if (Fld == null) {
                        Fld = [SELECT Id FROM Folder WHERE Name='Improved Help Documents'];
                    }
                    
                    mLocs.put('InternationalisationDiagnostics', 'Translation XML folder found');
                    
                    // Look for a translations XML file in this folder
                    Locale = getLocale() + '.xml';
                                
                    if (Doc == null) {
                        Doc = [SELECT Id, Body FROM Document WHERE Name=:Locale AND FolderId=:Fld.Id];
                    }
                    
                    bInfo = doc.Body;
                    mLocs.put('InternationalisationDiagnostics', 'Translation XML file found');
                    LocaleDocExists = true;                 
                }
                
            } catch (exception ex) {
                // In these cases, in order to avoid bothering with SOQL calls in future, we
                // can log the fact that no doc / folder exists, so don't check again
                LocaleDocExists = false;
            }
            

            
            // If translation document cannot be found, seek translations in static resources
            // As with Docs, only bother where we haven't already tried and failed          
            if (Doc == null && LocaleSRExists != false) {
                try {
                    String srName = 'ImprovedHelpLocale_' + getLocale();
                    mLocs.put('InternationalisationDiagnostics', 'Translation Document NOT found - seeking resource ' + srName);

                    StaticResource sr = [SELECT Id, Body FROM StaticResource WHERE Name = :srName LIMIT 1];         
                    bInfo = sr.Body;
                    mLocs.put('InternationalisationDiagnostics', 'Translation Resource found');
                    LocaleSRExists = true;

                } catch (exception ex) {
                    // In these cases, in order to avoid bothering with SOQL calls in future, we
                    // can log the fact that no SR exists, so don't check again
                    LocaleSRExists = false;

                    mLocs.put('InternationalisationDiagnostics', 'Translation SR NOT found - defaults will be returned');

                    // Return defaults if this also fails
                    return mLocs;
                }               
            }
            

            try {
                // If we find it, proceed to read the XML
                Dom.Document DD = new Dom.Document();
                DD.load(bInfo.toString());
                Dom.Xmlnode[] nodes = DD.getRootElement().getChildElements();
                
                
                // If searching for Branding elements
                if (DlgName == 'Branding') {

                    // Only allow branding overrides to authorised instances
                    boolean AllowWhiteLabelling = ServiceSubs.getFPBValue('bL2SBrandingAllowWhiteLabelling');
                    
                    if (AllowWhiteLabelling == true) {                    
                        for (Dom.Xmlnode N : nodes) {
                            
                            // Find "Branding" area...
                            if (N.getName() == 'Branding') {
                                nodes = N.getChildElements();
                                    
                                // ... and return each branding element                         
                                for (Dom.Xmlnode O : nodes) {
                                    
                                    // Only allow replacement of tags we recognise
                                    if (mLocs.get(O.getAttributeValue('Name', '')) != null) {
            
                                        // If override is blank, do not allow it (think - subscription messages etc)
                                        if (O.getAttributeValue('Value', '') != '') {
                                            
                                            // 1.23 - disabled branding for ALL until subscription file is amended to allow this...
                                            // 1.49.n - re-enabled subject to checks above
                                            mLocs.put(O.getAttributeValue('Name', ''), O.getAttributeValue('Value', ''));
                                        }
                                    }
                                }                           
                                break;
                            }
                        }
                    }                    

                } else {
                    // If searching for localisations...
                    for (Dom.Xmlnode N : nodes) {
                        
                        // Find "Localisations" area...
                        if (N.getName() == 'Localisations') {
                            nodes = N.getChildElements();
                            
                            // Within this, find each dialogue "Context" tag...
                            for (Dom.Xmlnode O : nodes) {                               
                                context = O.getAttributeValue('Name', '');
                                
                                // If this represents the dialogue being sought...
                                if (context == DlgName || 'iahelp__' + context == DlgName || (context == 'QAM' && DlgName == 'ClientSide')) {
                                    
                                    // Loop through each of the context's "LocalisationElement" tags to build map to return...
                                    nodes = O.getChildElements();
                                    
                                    for (Dom.Xmlnode D : nodes) {
                                        
                                        
                                        // Only allow replacement of tags we recognise
// 1.54.3+ : Allow for translations for custom lightning component clickables                                                                                
//if (mLocs.get(D.getAttributeValue('Name', '')) != null) {
if (mLocs.get(D.getAttributeValue('Name', '')) != null || context == 'LUXComponents') {
                
                                            // If override is blank, do not allow it (think - subscription messages etc)
                                            if (D.getAttributeValue('Value', '') != '') {
                                                mLocs.put(D.getAttributeValue('Name', ''), D.getAttributeValue('Value', ''));
                                            }
}                           
                           
                                    }
                                    break;
                                    
                                }   // End if context matches dialogue
                            }   // End loop O around dialgue contexts                           
                        }   // End loop N around all doc nodes
                    }   // End if dialogue localisation sought
                }   // End if XML localisation file found
                
            } catch (exception ex) {
            
            }
                    
                        
        } catch (exception e) {
            if (mLocs == null) {mLocs = new map<string, string>();}
            mLocs.clear();
            mLocs.put('Error', e.getMessage());
        }
        
        return mLocs;
    }
    
    

    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // PRIVATE UTILITY FUNCTIONS
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    
    // Return the user's locale
    private static string getLocale() {
        String retVal = '';
        
        try {
            
            // UK -> en_GB
            retVal = UserInfo.getLanguage();
            
        } catch (exception e) {
            
        }
        
        return retVal;
    }
    

    // Return a map filled with default translations for a given screen
    private static map<string,string> getDefaultDialogueLocalisations(String DlgName) {
        map<string, string> mLocs = new map<string, string>();

        if (DlgName == 'Globals') {
            mLocs.put('AdviceLabelAddBookmark', 'Bookmark this Help Topic');
            mLocs.put('AdviceLabelComment', 'Log Comment');
            mLocs.put('AdviceLabelCompactView', 'Click this icon to display Help listings in compact format');
            mLocs.put('AdviceLabelInformation', 'Information');
            mLocs.put('AdviceLabelLastVotedOn', 'You last voted on');
            mLocs.put('AdviceLabelListingName', 'Name:');
            mLocs.put('AdviceLabelListingSummary', 'Summary:');
            mLocs.put('AdviceLabelQAM', 'Quick Access Menu');
            mLocs.put('AdviceLabelQuestionImageNotSet', '[Question Image is blank]');
            mLocs.put('AdviceLabelQuestionTextNotSet', '[Question Text is blank]');
            mLocs.put('AdviceLabelReadMoreLink', 'Read More. . .');
            mLocs.put('AdviceLabelSearchHelp', 'Search Help');
            mLocs.put('AdviceLabelSelected', 'Items selected');            
            mLocs.put('AdviceLabelSelectTopic', 'Please select a Help Topic');
            mLocs.put('AdviceLabelDropHereToSetRoot', 'Drop here to set root…');
            mLocs.put('AdviceLabelWarning', 'Warning:');
            mLocs.put('ButtonCancel', 'Cancel');
            mLocs.put('ButtonCompactView', 'Toggle Compact view');
            mLocs.put('ButtonCopy', 'Copy');           
            mLocs.put('ButtonEnable', 'Enable');
            mLocs.put('ButtonHere', 'here');
            mLocs.put('ButtonFilter', 'Filter');
            mLocs.put('ButtonGotoTemplates', 'View Help Topic Templates');
            mLocs.put('ButtonSave', 'Save');
            mLocs.put('ButtonSearch', 'Search');
            mLocs.put('ToolLabelButtonUpload', 'Upload Image');
            mLocs.put('FieldLabelAvailable', 'Available');
            mLocs.put('FieldLabelCreatedBy', 'Created by');
            mLocs.put('FieldLabelCreatedByDT', 'Date & Time');
            mLocs.put('FieldLabelModifiedBy', 'Modified by');
            mLocs.put('FieldLabelModifiedByDT', 'Date & Time');
            mLocs.put('FieldLabelSelected', 'Selected');            
            mLocs.put('MessageBadParameters', 'The parameters to this service were not supplied in the correct format');
            mLocs.put('MessageCancelWarning', 'Are you sure you wish to cancel all changes made on this screen?');            
            mLocs.put('MessageDeleteMemberTopic', 'Do you wish to delete the Help Topic associated with the tag you are removing from this pool?');
            mLocs.put('MessageDeleteTagPoolTopic', 'Removing the final tag means this will cease to be a pool. Do you wish to delete the Help Topic defining the pool itself?');
            mLocs.put('MessageDeleteWarning', 'Are you sure you wish to delete this item?');           
            mLocs.put('MessageEnterItemName', 'Please confirm or enter a name for this item');            
            mLocs.put('MessageErrorNoImageFolder', 'Image upload folder unspecified or incorrect in Help Global Settings: please contact you Help Administrator');
            mLocs.put('MessageErrorNavigatingToRLTopic', 'Error attempting to navigate to first topic in a Reading List');
            mLocs.put('MessageErrorNoMatchingRecord', 'Records were searched but no match was found');
            mLocs.put('MessageGenericAdded', 'Added');
            mLocs.put('MessageGenericEdited', 'Edited');
            mLocs.put('MessageGenericError', 'We\'re sorry but an error has occurred');
            mLocs.put('MessageGenericErrorShort', 'Error!');
            mLocs.put('MessageGenericNewRecords', 'new records');
            mLocs.put('MessageGenericTaskComplete', 'Done');
            mLocs.put('MessageGuideInNewWindow', 'The requested Guide has been opened in a separate window. If the Guide window has not appeared, please ensure you are not blocking popups from your Salesforce domains (e.g., salesforce.com and visual.force.com)');
            mLocs.put('MessageInsufficientSubscriptions', 'INSUFFICIENT SUBSCRIPTIONS');
            mLocs.put('MessageInteractionUnknownType', 'Unknown Interaction Type');
            mLocs.put('MessageInteractionUntrackedType', 'Help Global Settings state that interactions of the requested type are not currently being tracked');
            mLocs.put('MessageLayoutMetadataObtained', 'It looks like you\'re the first to view helped records of this type in this Salesforce org! Your visit has allowed us to complete some related configuration steps: please refresh this page to continue.');
            mLocs.put('MessageMissingDefaultTopic', 'No Topic matching that specified in Helped Element');
            mLocs.put('MessageMissingHelpedElement', 'No Helped Element found');
            mLocs.put('MessageMissingTemplate', 'Error locating the Template specified for this Help Topic');
            mLocs.put('MessageNoPermissions', 'There would appear to be an issue with your Help permission settings. Please contact your Salesforce Administrator.');
            mLocs.put('MessageNoRights', 'You do not have the rights to complete this operation');
            mLocs.put('MessageOptionNotAllowed', 'The selected option is not authorised for this component');
            mLocs.put('MessagePlatformEventsRequired', 'This operation requires Platform Events to be enabled from the Improved Help Settings page. As these are currently switched off, no action will be taken.');
            mLocs.put('MessageRedirecting', 'Redirecting to Topic Template');
            mLocs.put('MessageRefreshForChangesAutomatic', 'The page you are on will refresh on closing this dialogue to allow you to see your changes.');
            mLocs.put('MessageRefreshForChangesManual', 'Click OK then refresh the main page to see your changes.');
            mLocs.put('MessageRequestLogged', 'Thank you: your request has been logged');            
            mLocs.put('MessageSaved', 'Changes saved');
            mLocs.put('MessageSelectionRequired', 'Action cannot be completed: please check your selections then try again');
            mLocs.put('MessageSaveDialogueChanges', 'Do you wish to save the changes made on this screen?');
            mLocs.put('MessageServiceUnavailableConfiguration', 'There appears to be an issue with the configuration of Help. Please check the Global Settings page for more information.');
            mLocs.put('MessageServiceUnavailableSubscription', 'There appears to be an issue with the subscription for your Org. Please check the relevant Document folder and ensure that it contains a valid, current subscription file.');
            mLocs.put('MessageShareViaURL', 'Please forward the URL shown to share this item');
            mLocs.put('MessageValueRequired', 'Please supply a value');
            mLocs.put('TipButtonAdvancedSettings', 'View advanced settings…');
            mLocs.put('TipButtonClose', 'Click here to close...');
            mLocs.put('TipButtonCompactView', 'Click to Toggle Compact view');
            mLocs.put('TipButtonConfigureSettings', 'Configure Help settings');
            mLocs.put('TipButtonCopy', 'Click to copy…');
            mLocs.put('TipButtonCreateRL', 'Create a new Reading List');
            mLocs.put('TipButtonEditResourceNotes', 'Edit usage notes');
            mLocs.put('TipButtonEditTopic', 'Edit this Help Topic');
            mLocs.put('TipButtonGotoTemplates', 'Go to your Help Topic Template records');
            mLocs.put('TipButtonHelpHome', 'Go to the Help Home Page');
            mLocs.put('TipButtonNavCurrentTopic', 'Current Help Topic');
            mLocs.put('TipButtonOpenBookmarks', 'Open My Help Bookmarks list');
            mLocs.put('TipButtonRemoveBookmark', 'Remove the Bookmark for this Help Topic');
            mLocs.put('TipButtonSave', 'Save the changes made on this screen');
            mLocs.put('TipButtonUploadImage', 'Upload an image and use it for this Topic');
            mLocs.put('TipCueContextHelp', 'Help for this area…');       
            mLocs.put('TipDisambiguationLink', 'This keyword is associated with multiple topics: please click to learn more…');                 
            mLocs.put('TipGenericAdd', 'Add');
            mLocs.put('TipGenericCancel', 'Cancel changes');
            mLocs.put('TipGenericDelete', 'Delete');
            mLocs.put('TipGenericEdit', 'Edit');
            mLocs.put('TipGenericOK', 'OK');
            mLocs.put('TipGlobalQuickLinks', 'View the list of Global Quick Links');
            mLocs.put('TipGoto', 'Go to...');
            mLocs.put('TipHideTools', 'Hide additional Tools');
            mLocs.put('TipHideVotes', 'Hide voting options');
            mLocs.put('TipInputTextbox', 'Enter a search keyword');
            mLocs.put('TipReadMoreLinkAuthors', 'Authors / Admins may read more or edit here. . .');
            mLocs.put('TipReadMoreLinkUsers', 'Click to read more...');
            mLocs.put('TipGenericReorder', 'Re-order');
            mLocs.put('TipTabTools', 'View additional Tools');
            mLocs.put('TipStickiesLink', 'Show My Sticky...');
            mLocs.put('TipShareLink', 'Share this with a Colleague');
            mLocs.put('TipToggleHistory', 'History…');
            mLocs.put('TipViewImageLink', 'Click to see full size');
            mLocs.put('TipVote', 'Cast a vote on this issue');
            mLocs.put('TitleDialogueSubtitleLayout', 'Helped Page');
            mLocs.put('TitleDialogueTitleBookmarks', 'My Help Bookmarks');
            mLocs.put('TitleHelpedElement', 'Click for Improved Help. . .');
            mLocs.put('TitleMoreInformation', 'More information about');            
            mLocs.put('TitleQuickLinks', 'Quick-Links');
            mLocs.put('TitleResources', 'Resources');
            mLocs.put('TitleServiceUnavailable', 'Service Unavailable');
            mLocs.put('TitleSubtitleDisambiguation', 'Please select an item from those shown, each of which contains further information about');            
            mLocs.put('TitleSubtitleReadingLists', 'Reading Lists');
            mLocs.put('TitleSubtitleRelatedHelp', 'Related Help Topics');
            mLocs.put('TitleSubtitleTabTools', 'Help tools & settings');
            mLocs.put('TitleSubtitleTools', 'Tools');
            mLocs.put('ToolLabelGlobalSettings', 'Settings');
            mLocs.put('ToolLabelHelpHome', 'Help Home');                 
            mLocs.put('ToolLabelShareLink', 'Share…');               
            mLocs.put('ValueGenericNew', 'New');
            mLocs.put('ValueNewTopicName', 'DRAFT Help Topic (unbound)');
            mLocs.put('ValueNewTopicSummary', 'Newly added help topic - details pending');
            mLocs.put('ValueNone', 'None');
        }

        if (DlgName == 'Branding') {
            /*
            mLocs.put('ContactUsLink', 'https://improvedapps.com/contact-us/');
            mLocs.put('FAQsLink', '/apex/iahelp__IHLUXOutHost?NSApp=iahelp&App=appIH&NSComp=iahelp&Comp=IHUtility1&Parms=PDPositioningGroup~IHLUXApp_UtilBar^ColumnRatio~40^Height~-2^SuppressHeaders~true^SuppressFooters~true^TreeSuppressListingTools~true^RootNode~[None]');
            mLocs.put('ProductName', 'Improved Help');
            mLocs.put('ProductPoweredBy', 'Powered by Improved Help from Improved Apps Ltd.');
            mLocs.put('ProductStrapline', '...there is an easier way...');
            mLocs.put('ProductSupplier', 'Improved Apps');
            mLocs.put('QuickStartLink', 'https://www.improvedapps.com/improved-help-quick-start/');
            mLocs.put('SupportEmail', 'mailto:support@improvedapps.com');
            */
            
            mLocs.put('ContactUsLink', 'https://www.unaric.com/contact');
            mLocs.put('FAQsLink', 'https://docs.unaric.com/');
            mLocs.put('ProductName', 'Unaric Guide (formerly Improved Help)');
            mLocs.put('ProductPoweredBy', 'Powered by Unaric Guide from Unaric');
            mLocs.put('ProductStrapline', 'The digital adoption platform for Salesforce');
            mLocs.put('ProductSupplier', 'Unaric');
            mLocs.put('QuickStartLink', 'https://www.improvedapps.com/improved-help-quick-start/');
            mLocs.put('SupportEmail', 'mailto:support@improvedapps.com');
                        
        }

        if (DlgName == 'WServices') {
            mLocs.put('MessageAddedHelpedElementAndTopic', 'Helped Element and new Topic created for');
            mLocs.put('MessageAddedHelpedElementExistingTopic', 'Helped Element (associated with requested Topic) created for');
            mLocs.put('MessageAddedPageLayout', 'New Helped Page Layout created for');
            mLocs.put('MessageAddedStepRecordSelection', 'Added an Automatic record selection step');
            mLocs.put('MessageAddedStepWelcome', 'Added a Local welcome step');
            mLocs.put('MessageAddingElement', 'Creating Element');
            mLocs.put('MessageAddingStep', 'Creating new Step');
            mLocs.put('MessageDeletedGuideSteps', 'Guide Step(s) deleted');
            mLocs.put('MessageDeletedHelpTopics', 'Associated Help Topic(s) deleted');
            mLocs.put('MessageDeletedHelpedElements', 'Helped Element(s) deleted');
            mLocs.put('MessageElementWithExistingTopic', 'Element references existing Topic');
            mLocs.put('MessageElementWithNewTopic', 'Element has new Topic');
            mLocs.put('MessageErrorNoGuideDetails', 'ERROR! Unable to obtain details of the Guide being enabled.');
            mLocs.put('MessageNoChangesToGuide', 'No amendments were made to the selected Guide. Please close this dialogue to continue.');
            mLocs.put('MessageTopicDoesNotExist', 'The requested Topic does not exist');
            mLocs.put('MessageUpdatingStep', 'Updating Step');
            mLocs.put('ValueDraftGuide', '[New Guide]');
            mLocs.put('ValueDraftGuideSummary', 'We\'ve added this Guide for you. You can edit its name and this summary text by using the \'Properties\' tool on listings and elsewhere');
            mLocs.put('ValueDraftHelp', '(DRAFT)');
            mLocs.put('ValueDraftLayout', 'DRAFT Layout for object');
            mLocs.put('ValueLayout', 'Layout');         
        }           
        
        if (DlgName == 'Triggers') {
            mLocs.put('MessageErrorDuplicateKeyword', 'The Keyword specified for this Help Topic is already in use within the same sharing (Visibility) context. Please clear or amend the Keyword field.');
        }
        
        if (DlgName == 'MetadataOps') {
            mLocs.put('TitleLayoutMetadataSought', 'Sorry to interrupt…');
        }

        if (DlgName == 'IHFlowLauncher') {
            mLocs.put('AdviceLabelFlowLaunchedLightBox', 'The selected flow was open and run in a dialogue. Please refresh this page if you wish to launch another flow.');
            mLocs.put('AdviceLabelFlowLaunchedNewTab', 'The selected flow has been opened in a new tab. Please refresh this page if you wish to launch another flow.');
            mLocs.put('AdviceLabelNoDataMessage', 'There are no suggested flows for this page');
            mLocs.put('ButtonLaunchFlow', 'Launch');
            mLocs.put('TipButtonCloseFlow', 'Close this flow...');
            mLocs.put('TipButtonLaunchFlow', 'Click to launch the selected flow');
            mLocs.put('TitleSelectFlow', 'Suggestions for this page:');
        }

        if (DlgName == 'LUXComponents') {     
            
            mLocs.put('AdviceLabelDropToSort', 'Drop here to re-order…');           
            mLocs.put('AdviceLabelFilteredTo', 'Filtered To');
            mLocs.put('AdviceLabelGEInstructions', 'Select or add a Guide, then amend the list of its steps, or click on the form to create new ones');
            mLocs.put('AdviceLabelGenericTextPlaceholder', '[Your content here]');            
            mLocs.put('AdviceLabelItemsViewed', 'Items viewed');         
            mLocs.put('AdviceLabelKeywordSentenceMode', 'Sentences containing the selected Keywords:');
            mLocs.put('AdviceLabelMatchingItems', 'Matching Items');
            mLocs.put('AdviceLabelModified', 'Modified');
            mLocs.put('AdviceLabelNewHelpTopicCreated', 'New Help Topic created successfully');
            mLocs.put('AdviceLabelNoPoolMembers', '[Selected pool has no members]');
            mLocs.put('AdviceLabelProperties', 'Properties');
            mLocs.put('AdviceLabelSearchForExistingItem', 'Enter a search term to locate an existing record');            
            mLocs.put('AdviceLabelSteps', 'Steps');
            mLocs.put('AdviceLabelTagMode', 'Filter to records with:');
            mLocs.put('AdviceLabelSelectFields', 'Select and order the fields you wish to feature on your personal data form ("My Form"). If you choose to display My Form by toggling it on, these fields appear at the top of the record for objects of the current type.');
            mLocs.put('AdviceLabelTools', 'Tools');
            mLocs.put('AdviceLabelUnknownListing', '[Unknown Listing Requested]');
            mLocs.put('AdviceLabelWorking', 'Working…');
            mLocs.put('AdviceLabelStatsClicks', 'click(s)');
            mLocs.put('ButtonBack', 'Go Back');
            mLocs.put('ButtonUntaggedItems', '[Un-tagged Items]');            
            mLocs.put('FieldLabelComponentDefinition', 'Component Definition');
            mLocs.put('FieldLabelDisplayType', 'Display Type');
            mLocs.put('FieldLabelLiteralText', 'Literal Text');
            mLocs.put('FieldLabelSource', 'Source');
            mLocs.put('FieldLabelStyleClass', 'Style Class');            
            mLocs.put('FieldLabelMyNotes', 'My Notes for this Record');
            mLocs.put('FieldLabelSaveFormAs', 'Save Form As');
            mLocs.put('FieldLabelTagModeAll', 'ALL of the selected tags set');
            mLocs.put('FieldLabelTagModeAny', 'ANY of the selected tags set');
            mLocs.put('FieldLabelTreePrintIndentationLevel', 'Indentation Level');
            mLocs.put('MessageAddMemberUnavailable', 'No Help Topic selected: no action will be taken');
            mLocs.put('MessageAddMemberTag', 'Do you wish to add the current Help Topic to this Pool?');
            mLocs.put('MessageEnterObjectName', 'Please enter the API Name (case sensitive) of an Object');
            mLocs.put('MessageEnterTopicId', 'Please enter the ID of a Help Topic');
            mLocs.put('MessageErrorNoRecordType', 'The Record Type field must be present on data entry forms when using the Improved Help Autoform to add new records for objects that have a type. Please ask your Salesforce Administrator to add this field to your page layout.');
            mLocs.put('MessageGenericOK', 'OK');
            mLocs.put('MessageHelpIndexRootNotSpecified', 'The Help Index has not been configured for this page');
            mLocs.put('MessageStatsDiags1', 'total clicks on Tree');
            mLocs.put('MessageStatsDiags2', 'The most popular node has received');
            mLocs.put('MessageTreeHoistWarning', 'The item you are expanding is already present on a branch higher up this tree. Are you sure you wish to expand this tree node?');
            mLocs.put('MessageTreeRecursionWarning', 'The item you dropped is already present on a branch higher up this tree. Are you sure you wish to create this circular relationship?');
            mLocs.put('TipAddTagPool', 'Create a new Tag Pool with the current Help Topic as its first member');
            mLocs.put('TipAFRecordDiags', 'View key metadata about the current record');
            mLocs.put('TipAFRefreshMetadata', 'Refresh the metadata that maps layouts to profiles / record types for the CURRENT record type');
            mLocs.put('TipAFRefreshMetadataAllRTypes', 'Refresh the metadata that maps layouts to profiles / record types for ALL record types of the current object type');
            mLocs.put('TipAuthorConfigTopic', 'Set the current Topic as the default for this component on this layout');
            mLocs.put('TipAuthorConfigObject', 'Specify the object to be the default for this component');            
            mLocs.put('TipButtonAddColumn', 'Add a new column');
            mLocs.put('TipButtonAddRow', 'Add a new row');
            mLocs.put('TipButtonDeleteColumn', 'Delete this column');
            mLocs.put('TipButtonDeleteRow', 'Delete this row');            
            mLocs.put('TipButtonSettings', 'Show / hide settings');
            mLocs.put('TipCardGrow', 'Increase the height of this component');
            mLocs.put('TipCardShrink', 'Decrease the height of this component');
            mLocs.put('TipDesignModeOn', 'Enter Design Mode…');            
            mLocs.put('TipHelpRequest', 'Request Help for this feature');            
            mLocs.put('TipMarkAsNoise', 'Add the selected terms to the list of \'noise\' words to be ignored in future analyses of keywords');
            mLocs.put('TipNVShowRecorder', 'Launches the NativeVideo recorder and updates the current Topic\'s video URL to store the results');
            mLocs.put('TipOpenContextRecord', 'Go to the record to which this Note relates');
            mLocs.put('TipArchiveSticky', 'Archive this Note');
            mLocs.put('TipAddMemberTag', 'Add the current Help Topic to this Tag Pool');
            mLocs.put('TipButtonUntaggedItems', 'Show records that have none of the tags in this collection set');
            mLocs.put('TipDataFormEdit', 'Select the fields to show on your personal form');   
            mLocs.put('TipDeleteTopic', 'Delete this Topic');
            mLocs.put('TipGuideDialogue', 'View this in a popup dialogue');
            mLocs.put('TipGuideEnable', 'Enter Guide Enabling Mode');
            mLocs.put('TipHelpIndex', 'View the Help Index');
            mLocs.put('TipHideEmbeddedHelp', 'Hide Embedded Help');
            mLocs.put('TipHideRLDescriptions', 'Hide Reading List Entry description text');
            mLocs.put('TipListExport', 'Export the set of records featured on this component to Excel');
            mLocs.put('TipMyForm', 'Show/hide personally selected fields');         
            mLocs.put('TipReconfigureAddFilter', 'Add Help Filter');
            mLocs.put('TipReconfigureAddFilterCriterion', 'Add Help Filter Criterion');
            mLocs.put('TipReconfigureCloneElement', 'Clone this Helped Element');
            mLocs.put('TipReconfigureDeleteElement', 'Delete this Helped Element');
            mLocs.put('TipReconfigureDeleteFilter', 'Delete this Help Filter');
            mLocs.put('TipReconfigureDeleteFilterCriterion', 'Delete this Help Filter Criterion');
            mLocs.put('TipRelatedHelpLink', 'Link to a Related Help Topic');
            mLocs.put('TipRelatedHelpUnlink', 'Unlink this Related Help Topic');
            mLocs.put('TipRelatedResourceLink', 'Link to a Help Resource');
            mLocs.put('TipRelatedResourceUnlink', 'Remove the link to this Help Resource');
            mLocs.put('TipRelatedResourceNotes', 'Edit usage notes');
            mLocs.put('TipReadingListProperties', 'Reading List Properties');
            mLocs.put('TipReadingListAdd', 'Create a new Reading List');
            mLocs.put('TipReturnToHelpListings', 'Click to go back to the listings of Help available for this page');
            mLocs.put('TipSelectTagPool', 'Select the pool of tags to view');
            mLocs.put('TipSelectTree', 'Select Tree Root');            
            mLocs.put('TipTaggedHelp', 'View Topics tagged as relevant to this page');
            mLocs.put('TipToggleSelected', 'Select / De-select this item');
            mLocs.put('TipToggleSentenceView', 'Show / hide sentences that feature the selected keyword(s)');
            mLocs.put('TipTreePrint', 'Open a printable view of the contents of  this Tree');
            mLocs.put('TipTreeVotes', 'Show Votes cast on this Tree');
            mLocs.put('TipShowRLDescriptions', 'Show Reading List Entry description text');
            mLocs.put('TipRLMediaLarge', 'Show media in large format');
            mLocs.put('TipRLMediaMedium', 'Show media in medium format');
            mLocs.put('TipRLMediaSmall', 'Show media in small format');
            mLocs.put('TipAddBookmark', 'Add Bookmark');
            mLocs.put('TipAllHelp', 'View all Topics for this page');
            mLocs.put('TipButtonBack', 'Return to previous view…');
            mLocs.put('TipButtonHelp', 'View Help for buttons appearing on this page');
            mLocs.put('TipCommentLayout', 'Comment on this Layout');
            mLocs.put('TipCommentRL', 'Comment on this Reading List');
            mLocs.put('TipShowEmbeddedHelp', 'Show Embedded Help');
            mLocs.put('TipShowLOBuilder', 'Show the Improved Help Lightning Out URL Builder tool');
            mLocs.put('TipTreeDeleteNode', 'Delete this Tree Node');
            mLocs.put('TipTreeExport', 'Export the Topics on this Tree and their related records to Excel');
            mLocs.put('TipRLExport', 'Export the Topics in this Reading List and their related records to Excel');
            mLocs.put('TipSynchToContextHT', 'Expand tree controls (if present) to show this record');
            mLocs.put('TipTreeExpandAll', 'Expand all branches of this tree');
            mLocs.put('TipTreeCollapseAll', 'Collapse all branches of this tree');
            mLocs.put('TipTreeAddPeer', 'Add Peer');
            mLocs.put('TipTreeAddChild', 'Add Child');
            mLocs.put('TipTreeShowPeers', 'Show other hierarchies in which this record appears');
            mLocs.put('TipViewGuideInPortal', 'View Guide properties');
            mLocs.put('TipViewInPortal', 'View this item in the Help Portal');
            mLocs.put('TipViewTags', 'View the collection of Topics that form this Tag pool');
            mLocs.put('TipCommentTopic', 'Comment on this Topic');
            mLocs.put('TipDraggable', 'Draggable');
            mLocs.put('TipDropNewTopic', 'Drop text here to create a new Help Topic…');
            mLocs.put('TipDropSearch', 'Drop Here to Search…');
            mLocs.put('TipEdit', 'Edit this item');
            mLocs.put('TipFieldHelp', 'View Help for fields appearing on this page');
            mLocs.put('TipGlobalQuickLinks', 'View the list of Global Quick Links');
            mLocs.put('TipGlobalSettings', 'Configure Help Settings');
            mLocs.put('TipGuides', 'View Guides that explain aspects of this page');
            mLocs.put('TipHelpBookmarks', 'View My Help Bookmarks list');
            mLocs.put('TipHelpEnable', 'Enter Help Enabling Mode');
            mLocs.put('TipHelpHome', 'Go to the Help Home page');
            mLocs.put('TipHideListItemDetails', 'Click to compress this list');
            mLocs.put('TipKeywords', 'Show a glossary listing of the key business terms (Keywords) defined for your organisation');
            mLocs.put('TipLinksHelp', 'View Help for links appearing on this page');
            mLocs.put('TipModalDialogueNarrow', 'Switch to a narrower dialogue window');
            mLocs.put('TipModalDialogueWide', 'Switch to a wider dialogue window');
            mLocs.put('TipMyHelpComments', 'My Comments about this Layout and its Help Topics');
            mLocs.put('TipMyHelpNotes', 'View My Help Notes for this context');
            mLocs.put('TipNewHelpTopic', 'Add a new Help Topic NOT tied to this Helped Page');
            mLocs.put('TipNewNote', 'Create a new Note about the current page');
            mLocs.put('TipNoOp', 'Does nothing - but could e.g. create a Reading List');
            mLocs.put('TipPageHelp', 'View page-level Help');
            mLocs.put('TipPopOut', 'View this in a new window');
            mLocs.put('TipPopularHelp', 'View the most popular Help Topics associated with this page');
            mLocs.put('TipQAMHandleClose', 'Collapse Improved Help Quick Access Menu');
            mLocs.put('TipQAMHandleOpen', 'Expand Help Quick Access Menu');
            mLocs.put('TipReadingLists', 'View Reading Lists that relate to Topics on this page');
            mLocs.put('TipReconfigure', 'Re-configure this item');
            mLocs.put('TipRefreshAppListing', 'Obtain App listing from metadata');
            mLocs.put('TipRefreshTabListing', 'Obtain Tab listing from metadata');
            mLocs.put('TipRefreshHelpList', 'Refresh the data on this component');
            mLocs.put('TipRehomeQAM', 'Reset Quick Access Menu position');
            mLocs.put('TipRelatedListsHelp', 'View Help for related lists on this page');
            mLocs.put('TipRelatedResources', 'View Resources that relate to Topics on this page');
            mLocs.put('TipRelatedHelp', 'View other Help Topics that relate to the ones on this page');
            mLocs.put('TipRemoveBookmark', 'Remove Bookmark');
            mLocs.put('TipSaveNotes', 'Save My Notes');
            mLocs.put('TipSearch', 'Click to Search');
            mLocs.put('TipShowListItemDetails', 'Click to show additional listing information');
            mLocs.put('TipStatistics', 'Click for Statistics about this item');
            mLocs.put('TipSuggestKeywords', 'Suggest Keywords to use for this item on the basis of its content');
            mLocs.put('TipTopicAdd', 'Add a new Topic');
            mLocs.put('TipTopicClone', 'Clone the current Topic');
            mLocs.put('TipTreeAdd', 'Add a new Topic and make it the root of a new Tree');
            mLocs.put('TipTreeStats', 'Show Statistics about clicks on this Tree');
            mLocs.put('TipTreeRefocus', 'Focus Tree on this Node');
            mLocs.put('TipView', 'Return to View mode');
            mLocs.put('TitleAFRefreshMetadata', 'Layout Metadata Refreshed');
            mLocs.put('TitleAppListing', 'Apps in this Org');
            mLocs.put('TitleTabListing', 'Tabs in the Selected App');   
            mLocs.put('TitleAllHelp', 'Help for this Page');
            mLocs.put('TitleAllRelatedHelp', 'Related Help');
            mLocs.put('TitleAllResources', 'Related Resources');
            mLocs.put('TitleButtonHelp', 'Button Help');            
            mLocs.put('TitleCommentsAll', 'Comments - All');
            mLocs.put('TitleCommentsTopics', 'Comments on Help Topics');
            mLocs.put('TitleCommentsRLs', 'Comments on Reading Lists');
            mLocs.put('TitleCommentsHPLs', 'Comments on Helped Page Layouts');
            mLocs.put('ToolLabelCommentsAll', 'Comments - All');
            mLocs.put('ToolLabelCommentsTopics', 'Comments - Topics');
            mLocs.put('ToolLabelCommentsRLs', 'Comments - Reading Lists');
            mLocs.put('ToolLabelCommentsHPLs', 'Comments - Page Layouts');            
            mLocs.put('TitleCustomLinkHelp', 'Links Help');
            mLocs.put('TitleEditTopic', 'Edit Topic');
            mLocs.put('TitleFieldHelp', 'Field Help');
            mLocs.put('TitleFixedHelp', 'Help Topics');
            mLocs.put('TitleGetTaggedItems', 'Tagged Items');
            mLocs.put('TitleGetTags', '[No Tag Pool Selected]');            
            mLocs.put('TitleGuides', 'Guides for this page');
            mLocs.put('TitleHelpComments', 'My Help Comments');
            mLocs.put('TitleHelpBookmarks', 'Help Bookmarks');
            mLocs.put('TitleHelpEnableMode', 'Help Enable Mode');
            mLocs.put('TitleHelpedElementMaintenance', 'Helped Element Maintenance');
            mLocs.put('TitleKeywords', 'Glossary');
            mLocs.put('TitleLinkRelatedHelp', 'Link to a Related Help Topic');
            mLocs.put('TitleLinkRelatedResource', 'Link to a Help Resource');
            mLocs.put('TitleListsHelp', 'Related Lists Help');          
            mLocs.put('TitleLogComment', 'Log Comment');
            mLocs.put('TitleNewSticky', 'My Help Notes');
            mLocs.put('TitleNoTopicSelected', '[No Topic Selected]');
            mLocs.put('TitlePageHelpLinkHelp', 'Page-level Help');
            mLocs.put('TitlePopularHelp', 'Popular Topics');
            mLocs.put('TitleQuickLinks', 'Quick-Links');
            mLocs.put('TitleReadingListViewer', 'Reading List Viewer');
            mLocs.put('TitleReadingListEntries', 'Reading List Viewer');
            mLocs.put('TitleReadingLists', 'Related Reading Lists');
            mLocs.put('TitleReadingListsXF', 'Related Reading Lists');
            mLocs.put('TitleRefreshAppListing', 'Obtaining App/Tab Metadata…');
            mLocs.put('TitleSearch', 'Search Results');
            mLocs.put('TitleSelectFields', 'Select Fields');
            mLocs.put('TitleSelectTagPool', 'Select Tag Pool');            
            mLocs.put('TitleStatistics', 'Statistics');
            mLocs.put('TitleStickies', 'My Help Notes');
            mLocs.put('TitleTabVisible', 'Visible');
            mLocs.put('TitleToolsOnly', '');    // Deliberately blank
            mLocs.put('TitleTreeNodes', 'Tree Search');
            mLocs.put('ToolLabelAuthorConfigTopic', 'Pin Topic');
            mLocs.put('ToolLabelAuthorConfigObject', 'Set Default Object');
            mLocs.put('ToolLabelAddTagPool', 'Add New Pool');
            mLocs.put('ToolLabelKeywords', 'Glossary');
            mLocs.put('ToolLabelTreeAdd', 'Add Tree');
            mLocs.put('ToolLabelAFRecordDiags', 'Record Information');
            mLocs.put('ToolLabelAFRefreshMetadata', 'Refresh Layout Assignment');
            mLocs.put('ToolLabelAFRefreshMetadataAllRTypes', 'Refresh All Layout Assignments');
            mLocs.put('ToolLabelViewHelpedElements', 'View Helped Elements');
            mLocs.put('ToolLabelDataFormEdit', 'Edit My Form');
            mLocs.put('ToolLabelDesignModeOn', 'Design Mode');
            mLocs.put('ToolLabelAddMemberTag', 'Add Member Tag');
            mLocs.put('ToolLabelMarkAsNoise', 'Mark As Noise');           
            mLocs.put('ToolLabelMyForm', 'Toggle My Form');
            mLocs.put('ToolLabelNewResourceLink', 'Link New Resource');           
            mLocs.put('ToolLabelRelatedHelpLink', 'Add Related Help');
            mLocs.put('ToolLabelRefreshCurrentList', 'Refresh List');
            mLocs.put('ToolLabelRelatedResourceLink', 'Link Existing Resource');            
            mLocs.put('ToolLabelTreeExport', 'Export');
            mLocs.put('ToolLabelTreeVotes', 'Show Votes');
            mLocs.put('ToolLabelTreeStats', 'Statistics');
            mLocs.put('ToolLabelTreeExpandAll', 'Expand branches');
            mLocs.put('ToolLabelTreeCollapseAll', 'Collapse branches');
            mLocs.put('ToolLabelDeleteTopic', 'Delete');
            mLocs.put('ToolLabelGuides', 'Guides');
            mLocs.put('ToolLabelHelpIndex', 'Help Index');
            mLocs.put('ToolLabelHideRLDescriptions', 'Hide Descriptions');
            mLocs.put('ToolLabelReturnToHelpListings', 'Return To Help Listings…');
            mLocs.put('ToolLabelShowRLDescriptions', 'Show Descriptions');
            mLocs.put('ToolLabelRLMediaLarge', 'Large Media');
            mLocs.put('ToolLabelRLMediaMedium', 'Medium Media');
            mLocs.put('ToolLabelRLMediaSmall', 'Small Media');
            mLocs.put('ToolLabelAddBookmark', 'Add Bookmark');
            mLocs.put('ToolLabelAllHelp', 'Help for this Page');
            mLocs.put('ToolLabelButtonHelp', 'Button Help');
            mLocs.put('ToolLabelComment', 'Comment');
            mLocs.put('ToolLabelDraggable', 'Draggable');
            mLocs.put('ToolLabelDropNewTopic', 'Drop New Topic');
            mLocs.put('ToolLabelDropSearch', 'Drop Search');
            mLocs.put('ToolLabelEdit', 'Edit');
            mLocs.put('ToolLabelViewTags', 'View Pool in Portal');
            mLocs.put('ToolLabelListExport', 'Export These Records');
            mLocs.put('ToolLabelNVShowRecorder', 'Record Video');
            mLocs.put('ToolLabelSelectTagPool', 'Select Tag Pool');
            mLocs.put('ToolLabelFieldHelp', 'Field Help');
            mLocs.put('ToolLabelGlobalQuickLinks', 'Quick-Links');
            mLocs.put('ToolLabelGlobalSettings', 'Settings');
            mLocs.put('ToolLabelGuideEnable', 'Guide Enable');
            mLocs.put('ToolLabelHelpBookmarks', 'My Help Bookmarks');
            mLocs.put('ToolLabelHelpEnable', 'Help Enable');
            mLocs.put('ToolLabelHelpHome', 'Help Home');            
            mLocs.put('ToolLabelHideListItemDetails', 'Hide List Item Details');
            mLocs.put('ToolLabelLinksHelp', 'Links Help');
            mLocs.put('ToolLabelModalDialogueWide', 'Wide Dialogue');
            mLocs.put('ToolLabelModalDialogueNarrow', 'Narrow Dialogue');
            mLocs.put('ToolLabelMyHelpComments', 'My Help Comments');
            mLocs.put('ToolLabelMyHelpNotes', 'My Help Notes');
            mLocs.put('ToolLabelNewHelpTopic', 'New Help Topic');
            mLocs.put('ToolLabelNewNote', 'New Note');
            mLocs.put('ToolLabelNoOp', 'NoOp');
            mLocs.put('ToolLabelPageHelp', 'Help for');
            mLocs.put('ToolLabelPopOut', 'Pop Out');
            mLocs.put('ToolLabelPopularHelp', 'Popular Topics');
            mLocs.put('ToolLabelReadingLists', 'Reading Lists');
            mLocs.put('ToolLabelRelatedResources', 'Related Resources');
            mLocs.put('ToolLabelRelatedHelp', 'Related Item(s)');
            mLocs.put('ToolLabelReconfigure', 'Re-configure');
            mLocs.put('ToolLabelRehomeQAM', 'Re-home QAM');
            mLocs.put('ToolLabelRelatedListsHelp', 'Related Lists Help');
            mLocs.put('ToolLabelRemoveBookmark', 'Remove Bookmark');
            mLocs.put('ToolLabelShowLOBuilder', 'Lightning Out Builder');
            mLocs.put('ToolLabelSave', 'Save');
            mLocs.put('ToolLabelSearch', 'Search');
            mLocs.put('ToolLabelShowListItemDetails', 'Show List Item Details');
            mLocs.put('ToolLabelStatistics', 'Statistics');
            mLocs.put('ToolLabelTaggedHelp', 'Tagged Help');
            mLocs.put('ToolLabelToggleSentenceView', 'Toggle Sentence View');
            mLocs.put('ToolLabelSuggestKeywords', 'Suggest Keywords');
            mLocs.put('ToolLabelTopicAdd', 'New Help Topic');
            mLocs.put('ToolLabelTopicClone', 'Clone');
            mLocs.put('ToolLabelTreePrint', 'Print…');
            mLocs.put('ToolLabelView', 'View');
            mLocs.put('ToolLabelViewInPortal', 'View in Portal');
        }
                
        if (DlgName == 'ServiceSubs') {
            mLocs.put('ValueSubscriptionDecryptionError', 'Error attempting to decrypt the Subscription file');
            mLocs.put('ValueSubscriptionExpired', 'Subscription has expired');
            mLocs.put('ValueSubscriptionForWrongOrg', 'Subscription is not for the current Org ');
            mLocs.put('ValueSubscriptionGenericError', 'Subscription error');
            mLocs.put('ValueSubscriptionOK', 'OK');
            mLocs.put('ValueSubscriptionSeatsExceeded', 'Subscriptions used exceeds the number available');
            mLocs.put('ValueSubscriptionUnreadable', 'Error attempting to read the Subscription file');
            mLocs.put('ValueSubscriptionNotApplicable', 'For the purposes of the current version of this product, please refer to information listed under Setup | Installed Packages');
        }
        
        if (DlgName == 'ServiceIHLists') {
            mLocs.put('MessageAddedRelatedHelp', 'Related Help List Item created successfully');
            mLocs.put('MessageAddedRLEntry', 'Reading List Entry added successfully');
            mLocs.put('MessageDeletedRelatedHelp', 'Deleted Help Relationship');
            mLocs.put('MessageDeletedRelatedResource', 'Deleted Related Help Resource');
            mLocs.put('MessageDeletedRLEntry', 'Deleted Reading List Entry');
            mLocs.put('TipNavNext', 'Next topic');
            mLocs.put('TipNavNextUnavailable', 'No next topic');            
            mLocs.put('TipNavPrevious', 'Previous topic');
            mLocs.put('TipNavPreviousUnavailable', 'No previous topic');
        }
        
        if (DlgName == 'ClientSide') {          
            mLocs.put('[QAMAdviceLabelGuideStepCounter1]', 'Step');
            mLocs.put('[QAMAdviceLabelGuideStepCounter2]', 'of');
            mLocs.put('[QAMAdviceLabelMode]', 'Select Mode');
            mLocs.put('[QAMAdviceLabelSeatAllocationExceeded]', 'Help seat allocation has been exceeded');
            mLocs.put('[QAMAdviceLabelSubscriptionIssue]', 'There appears to be an issue with the Improved Help subscription for your Org. The subscription service reports the following:');
            mLocs.put('[QAMButtonCheckSubscriptionDetails]', 'Click here to check Subscription details');
            mLocs.put('[QAMButtonGotoNextStep]', 'Next');
            mLocs.put('[QAMButtonHelpPortalLink]', 'Help');
            mLocs.put('[QAMButtonPageHelpLink]', 'Help for this Page');
            mLocs.put('[QAMButtonSubscriptionExtendTrialLink]', 'To extend your subscription, please contact us');
            mLocs.put('[QAMButtonSubscriptionFolderLink]', 'Please check the Help Document folder and ensure that it contains a valid, current subscription file.');
            mLocs.put('[QAMButtonSubscriptionTrialLink]', 'To request a subscription, please visit our Help Trial Subscription page.');
            mLocs.put('[QAMMessageConfirmDeleteRelatedHelp]', 'Are you sure you wish to delete this Related Help Topic?');
            mLocs.put('[QAMMessageDDFNotMatched]', 'This element is helped but data driven filters do not match the current record. Would you like to review the relevant details?');
            mLocs.put('[QAMMessageDirtyWarning]', 'You appear to have edited information on the current page and have yet to save it. If you continue at this stage your changes will be lost.');
            mLocs.put('[QAMMessageElementConfigurationIssue]', 'There are issues with the configuration of this Helped Element. Would you like to review the relevant details?');
            mLocs.put('[QAMMessageGenericError]', 'We\'re sorry but an error has occurred');
            mLocs.put('[QAMMessageGuideLostContext]', 'JOIN US IN LIGHTNING! We\'re deprecating Guide Enable mode in Salesforce classic - because we\'ve made it so much easier in Lightning! If you\'re unable to use the Lightning Experience, it\'s still possible to create Guides by using classic Reading List editing tools. Please contact Support for more information.');
            mLocs.put('[QAMMessageGuideNavigationRequired]', 'Please navigate to a suitable location to continue with this Guide.');
            mLocs.put('[QAMMessageGuideNoStepInfo]', 'No step information available');
            mLocs.put('[QAMMessageGuideStepsCompleted]', 'You have completed the available steps in this Guide.');
            mLocs.put('[QAMMessageGuideStepsCompletedGuidance]', 'You have completed the last Step of this Set. Please see the Guide window for further advice.');
            mLocs.put('[QAMMessageGuideStepsCompletedManualClose]', 'Please see the Guide window for any further Steps and close this window when ready.');
            mLocs.put('[QAMMessageGuideStepsCompletedOfferClose]', 'You have completed the last Step of this Set. Do you wish to close this Step window?');
            mLocs.put('[QAMMessageGuidesNotAvailable]', 'Guides not available from this location');
            mLocs.put('[QAMMessageLoggedOut]', 'Your Salesforce session may have expired. Please refresh this page and log in before continuing.');
            mLocs.put('[QAMMessageVIPLinkCopyInstructions]', 'The link below will open the topic you are viewing \'in place\' on the current record. Please copy to your clipboard for forwarding as required:');
            mLocs.put('[QAMMessageVIPLinkCopyInstructionsGuides]', 'The link below will open the selected Guide on the current record. Please copy to your clipboard for forwarding as required:');
            mLocs.put('[QAMRowAnalyse]', 'Analyse');
            mLocs.put('[QAMRowBookmarks]', 'My Bookmarks');
            mLocs.put('[QAMRowComment]', 'Comment');
            mLocs.put('[QAMRowGuideEnable]', 'Guide-Enable');
            mLocs.put('[QAMRowGuides]', 'Guides');
            mLocs.put('[QAMRowHelpEnable]', 'Help-Enable');
            mLocs.put('[QAMRowHome]', 'Help Home');
            mLocs.put('[QAMRowReconfigure]', 'Re-configure');
            mLocs.put('[QAMRowSearch]', 'Search Help');
            mLocs.put('[QAMRowSettings]', 'Help Settings');
            mLocs.put('[QAMRowView]', 'View');
            mLocs.put('[QAMTipHandle]', 'Expand Help Quick Access Menu');
            mLocs.put('[QAMTipHandleClose]', 'Collapse Improved Help Quick Access Menu');
            mLocs.put('[QAMTipRowHome]', 'Go to Help Home Page');
            mLocs.put('[QAMTipRowAnalyse]', 'View statistics for this page');
            mLocs.put('[QAMTipRowBookmarks]', 'Show My Help Bookmarks list');
            mLocs.put('[QAMTipRowComment]', 'Send a comment to the Help Author for this page');
            mLocs.put('[QAMTipRowGuideEnable]', 'We\'re deprecating this feature: join us in Lightning!');
            mLocs.put('[QAMTipRowGuides]', 'Show Guides for this page');
            mLocs.put('[QAMTipRowHelpEnable]', 'Help-enable this page');
            mLocs.put('[QAMTipRowReconfigure]', 'Re-configure this page');
            mLocs.put('[QAMTipRowSearch]', 'Search for Help Topics');
            mLocs.put('[QAMTipRowSettings]', 'Configure Help settings');
            mLocs.put('[QAMTipRowView]', 'View page as Helped User');
            mLocs.put('[QAMTitleButtonClose]', 'Close dialogue window');
            mLocs.put('[QAMTitleButtonClosePrompt]', 'Close this prompt');
            mLocs.put('[QAMTitleButtonDeleteStep]', 'Delete this step');
            mLocs.put('[QAMTitleButtonGotoNextStep]', 'Go to next step');
            mLocs.put('[QAMTitleButtonSaveStep]', 'Save step settings and close tool window');
            mLocs.put('[QAMTitleButtonShowNonLinearSteps]', 'Show/hide Manual Steps');
            mLocs.put('[QAMTitleHelpedElement]', 'Click for Improved Help. . .');
            mLocs.put('[QAMValueSelectRecordStepName]', 'Please select a record');
            mLocs.put('[QAMValueSelectRecordStepSummary]', 'We\'ve added a record selection step for you and tried to include the relevant Step Context information to ensure the remainder of the Guide you created operates correctly.');
            mLocs.put('[QAMValueWelcomeStepName]', 'Welcome');
            mLocs.put('[QAMValueWelcomeStepSummary]', 'As this is a new Guide, we\'ve added this welcome step and suggest you include something similar to advise users what it aims to achieve. For example, you might want to describe the target audience and/or processes covered by the Guide.');


            // For client side situations, we'll also need branding elements - but we've only got 1 collection to put them in!
            // So: add all of those here too...
            map<string, string> mLocsBrd = getDefaultDialogueLocalisations('Branding');
            
            for (String key : mLocsBrd.keySet()) {
                mLocs.put(key, mLocsBrd.get(key));
            }
        }

        if (DlgName == 'iahelp__IHHelpedElement') {
            mLocs.put('ColumnLabelFilter', 'Filter');
            mLocs.put('ColumnLabelName', 'Name');
            mLocs.put('ColumnLabelUseForNew', 'Use For New?');
            mLocs.put('ColumnLabelVisibility', 'Visibility');
            mLocs.put('FieldLabelDataDrivenFilter', 'Data driven filter');
            mLocs.put('FieldLabelHelpTopic', 'Help Topic');
            mLocs.put('FieldLabelIdentifier', 'Identifier');
            mLocs.put('FieldLabelLayout', 'Layout');
            mLocs.put('FieldLabelName', 'Name');
            mLocs.put('FieldLabelType', 'Type');
            mLocs.put('FieldLabelUseForNew', 'Use For New?');
            mLocs.put('FieldLabelVisibility', 'Visibility');
            mLocs.put('MessageNoElementsToReconfigure', 'No Helped Elements available to reconfigure: please re-enable if required via Help Enable mode');
            mLocs.put('MessageUseForNew', 'Please note that as you have chosen this Helped Element as the one to use when creating new Salesforce records:\n\n\n- It will be displayed when adding new records regardless of the specified data filter;\n\n- The data filter is still relevant when viewing or editing;\n\n- Therefore, if you do NOT wish to show this Element\'s Help Topic when viewing/editing, please ensure you enter a suitable Data Filter.');
            mLocs.put('TipButtonAdd', 'Add Helped Element');
            mLocs.put('TipButtonDelete', 'Delete Helped Element');
            mLocs.put('TipButtonEdit', 'Edit Helped Element');
            mLocs.put('TipButtonSave', 'Save changes to this Helped Element');
            mLocs.put('TipHelpTopicLink', 'Click to view this Topic in a new tab/window');
            mLocs.put('TitleDialogueTitle', 'Helped Element Maintenance');
            mLocs.put('TitleTabFilters', 'Filters');
            mLocs.put('TitleTabGeneral', 'General');
        }
        
        if (DlgName == 'iahelp__IHComment') {
            mLocs.put('AdviceLabelEnterFeedback', 'Please enter your feedback');
            mLocs.put('AdviceLabelFeatureNotAvailable', 'Feature Not Available');
            mLocs.put('ButtonSubmit', 'Submit');
            mLocs.put('MessageCommentFailedBlank', 'You did not type a comment: no action was taken');
            mLocs.put('MessageCommentFailedParameters', 'Required parameters (help topic, reading list or element) not specified: no action was taken');
            mLocs.put('MessageCommentLogged', 'Your comment has been logged');
            mLocs.put('TipButtonSubmit', 'Submit your comment');
            mLocs.put('TitleDialogueSubtitleTopic', 'Help Topic');
            mLocs.put('TitleDialogueTitle', 'Log Comment');
        }       

        if (DlgName == 'iahelp__IHLauncher') {
            mLocs.put('TipButtonSynch', 'Toggle synchronisation: when switched on, Help window refreshes to list available Topics as you navigate.');
        }

        if (DlgName == 'IHLUXOpHandler') {
            mLocs.put('MessageOp1Error', 'Improved Help may not yet have been configured with information about the page layout to use for the current record type and user profile');          
            mLocs.put('MessageAppDataObtained', 'App data obtained: please close this message to continue');
            mLocs.put('MessageThisTabDataObtained', 'Tabs data obtained: please close this message to continue');
            mLocs.put('MessageAllTabDataObtained', 'App Tab mapping data obtained: please close this message to continue');
        }

        if (DlgName == 'iahelp__IHReadingListProperties') {
            mLocs.put('AdviceLabelCreateAndLink', 'Create new Reading List with the current Help Topic as its first Reading List Entry');
            mLocs.put('AdviceLabelCreateAndNew', 'Define basic Help Topic properties for the first Entry of the new Reading List');
            mLocs.put('ButtonCreateAndLink', 'Create');
            mLocs.put('ButtonCreateAndNew', 'Create');
            mLocs.put('FieldLabelActive', 'Active');
            mLocs.put('FieldLabelDescription', 'Description');
            mLocs.put('FieldLabelFeaturedUntil', 'Featured until');
            mLocs.put('FieldLabelName', 'Name');
            mLocs.put('FieldLabelNewHTName', 'New Help Topic Name');
            mLocs.put('FieldLabelNewHTSummary', 'Summary');
            mLocs.put('FieldLabelOwner', 'Owner');
            mLocs.put('FieldLabelStatus', 'Status');
            mLocs.put('FieldLabelSummary', 'Summary');
            mLocs.put('FieldLabelType', 'Type');
            mLocs.put('FieldLabelVisibility', 'Visibility');
            mLocs.put('MessageCreateAndLink', 'New Reading List created containing the current Help Topic');
            mLocs.put('MessageCreateAndNew', 'New Reading List and Topic created');
            mLocs.put('MessageCreateAndNewError', 'Error attempting to create a new Reading List: please ensure you have a suitable Name and Summary completed for your Help Topic');
            mLocs.put('TipButtonAdd', 'Add a new Reading List');
            mLocs.put('TipButtonCreateAndLink', 'Create a new Reading List and add the current Help Topic as its first Entry');
            mLocs.put('TipButtonCreateAndNew', 'Create new Reading List, Help Topic and Reading List Entry');
            mLocs.put('TipButtonDelete', 'Delete this Reading List');
            mLocs.put('TipButtonEdit', 'Edit this Reading List');
            mLocs.put('TipButtonExportToWord', 'Export this Reading List to Word');
            mLocs.put('TipButtonSave', 'Save changes to this Reading List');
            mLocs.put('TipButtonViewHistory', 'View Reading List History');
            mLocs.put('TipLinkBack', 'Return to standard Salesforce page');
            mLocs.put('TitleDialogueSubtitleCreateAndLinkTab', 'Create and Link');
            mLocs.put('TitleDialogueSubtitleCreateAndNewTab', 'Create and New');
            mLocs.put('TitleDialogueSubtitleRLEntriesTab', 'Reading List Entries');
            mLocs.put('TitleDialogueSubtitleRLPropertiesTab', 'Reading List Properties');
            mLocs.put('TitleDialogueTitleEdit', 'Edit Reading List Properties');
            mLocs.put('TitleDialogueTitleNew', 'Create New Reading List');
            mLocs.put('TitleDialogueTitleRead', 'Reading List Properties');
        }       

        if (DlgName == 'iahelp__IHManageReadingList') {
            mLocs.put('AdviceLabelRLNotFound', 'The requested Reading List could not be found. If you\'ve just deleted the last entry in a Reading List, please close this dialogue to continue.');
            mLocs.put('MessageConfirmDeleteEntryAndRL', 'Deleting the last Reading List Entry will also delete this Reading List. Do you wish to proceed?');
            mLocs.put('TipbtnAddRLEntries', 'Add Reading List Entry');
            mLocs.put('TipDeleteEntry', 'Delete Entry');
            mLocs.put('TipDeleteEntryAndRL', 'Delete Entry and Reading List');
            mLocs.put('TipGotoTopic', 'Go to this Help Topic');
            mLocs.put('TipMoveEntryDown', 'Move Entry Down');
            mLocs.put('TipMoveEntryUp', 'Move Entry Up');
            mLocs.put('TitleDialogueTitle', 'Manage Reading List Entries');
        }
        
        if (DlgName == 'iahelp__CalloutReadingLists') {
            mLocs.put('AdviceLabelReadingListCounter1', 'Reading List');
            mLocs.put('AdviceLabelReadingListCounter2', 'of');
            mLocs.put('TipRLSelectorButton', 'Show next Reading List');
        }
        
        if (DlgName == 'iahelp__IHPreviewCallout') {
            mLocs.put('AdviceLabelMain', 'Below is a Callout preview, showing how this Help Topic (as last saved/quick-saved from the editor panel) will appear in situ, on the Helped Page Layout. (For clarity, any Callout speech bubble \'tail\' is omitted in this preview.) The red-bordered outer container shows the space that Help makes available within the Helped Page Layout, for this particular Callout. It has a default height, set by the choice of  Callout Template, but this can be adjusted by changing the Help Topic\'s Callout Height in the Help Tools Page Editor panel.');
            mLocs.put('TitleDialogueTitle', 'Callout Preview of Help Topic');
        }

        if (DlgName == 'iahelp__IHStats') {
            mLocs.put('AdviceLabelCalloutViews', 'Callout views');
            mLocs.put('AdviceLabelFullTopicViews', 'Full Topic views');
            mLocs.put('AdviceLabelLinkInteractionReport', 'Open a detailed report for this Help Topic. . .');          
            mLocs.put('AdviceLabelSOQLLimitsExceeded', 'NB: the number of interactions exceeds that shown - please see Reports for more accurate figures. Querying limits were reached examining type:');       
            mLocs.put('AdviceLabelUserComments', 'User Comments');
            mLocs.put('AdviceLabelVotes', 'Votes');
            mLocs.put('TipLinkInteractionReport', 'See details of these interactions');
            mLocs.put('TipLinkSelectElement', 'See statistics for matching element');
            mLocs.put('TitleDialogueSubtitle', 'Statistics for');
            mLocs.put('TitleDialogueTitle', 'Topic Statistics');
        }

        if (DlgName == 'iahelp__IHSearchResults') {
            mLocs.put('AdviceLabelResultsFor', 'Results for');
            mLocs.put('ButtonCreateAndRelate', 'Create and Link');
            mLocs.put('ButtonGuideAuthoringTips', 'Authoring tips for creating Guides');
            mLocs.put('ColumnLabelHEInfo', 'Helped Page Layout : Helped Element : Data-driven Filter');
            mLocs.put('ColumnLabelHelpedElementName', 'Helped Element Name');
            mLocs.put('FieldLabelContainingKeyword', 'containing keyword');
            mLocs.put('FieldLabelNewHTName', 'New Help Topic Name');
            mLocs.put('FieldLabelNewHTSummary', 'Summary');
            mLocs.put('FieldLabelNewResourceLocation', 'Location');
            mLocs.put('FieldLabelNewResourceName', 'New Resource Name');
            mLocs.put('FieldLabelNewResourceSummary', 'Summary');
            mLocs.put('FieldLabelNewResourceType', 'Resource Type');
            mLocs.put('FieldLabelNewResourceURL', 'Resource URL');
            mLocs.put('FieldLabelShow', 'Show');
            mLocs.put('MessageCopyTopicID', 'Please copy the Topic ID below then return to the confirmation screen and paste it into the relevant Topic ID field (we will attempt to do this for you)');
            mLocs.put('MessageCreateAndRelateOpt1Error', 'Error attempting to add a Related Help Topic: please ensure you have a suitable Help Topic Name and Summary completed for your new Help Topic');
            mLocs.put('MessageCreateAndRelateOpt2Error', 'Error attempting to create and relate a Reading List Entry: please ensure you have a suitable Help Topic Name and Summary completed for your new Help Topic');
            mLocs.put('MessageCreateAndRelateOpt3Error', 'Error attempting to add a related Resource: please ensure you have a suitable Name, Location and URL completed for your new Resource');
            mLocs.put('MessageRecordSelected', 'Your selection has been noted: please close this dialogue to continue.');
            mLocs.put('TipButtonCreateAndRelateOpt1', 'Create a new Help Topic and relate it to the one you are currently viewing');
            mLocs.put('TipButtonCreateAndRelateOpt2', 'Create a new Help Topic and add it to the current Reading List');
            mLocs.put('TipButtonCreateAndRelateOpt3', 'Create a new Help Resource and relate it to the Help Topic you are currently viewing');
            mLocs.put('TipButtonCreateNewGuide', 'Create steps for a new Guide');
            mLocs.put('TipButtonGuideAuthoringTips', 'Follow this link for hints and tips, dos and don\'ts for using Help Guides');
            mLocs.put('TipButtonSearch', 'Click to search for matching records');
            mLocs.put('TipClickToCreateGuideSteps', 'Create Steps for this Guide');
            mLocs.put('TipClickToLaunchGuide', 'Click to launch this Guide');
            mLocs.put('TipClickToOpen', 'Click to open this record');
            mLocs.put('TipClickToVIP', 'Click to view this Element in place');
            mLocs.put('TipLinkBackOpt2', 'Return to Reading List Entries screen');
            mLocs.put('TipLinkResourceToCurrentTopic', 'Link this Help Resource to the Help Topic you are currently viewing');
            mLocs.put('TipLinkRLToCurrentTopic', 'Add the current Help Topic to this Reading List');
            mLocs.put('TipLinkTopicToCurrentRL', 'Add this Help Topic to the Reading List you are currently viewing');
            mLocs.put('TipLinkTopicToCurrentTopic', 'Link this Help Topic to the one you are currently viewing');
            mLocs.put('TipSelectTopic', 'Select this Help Topic');
            mLocs.put('TitleDialogueSubtitleOpt1', 'Create & Link New Related Help Topic');
            mLocs.put('TitleDialogueSubtitleOpt2', 'Create & Link New Help Topic as a Reading List Entry');
            mLocs.put('TitleDialogueSubtitleOpt3', 'Create & Link New Help Resource');
            mLocs.put('TitleDialogueTitleOpt0', 'Search Results');
            mLocs.put('TitleDialogueTitleOpt5', 'Available Guides');
            mLocs.put('TitleDialogueTitleOpt6', 'Helped Elements referencing this Topic');
            mLocs.put('TitleDialogueTitleOpt8', 'Please select a Guide to continue');
            mLocs.put('ValueAllGuides', 'All Guides');
            mLocs.put('ValueComponentFilter', 'Filter');
            mLocs.put('ValueComponentLayout', 'Layout');
            mLocs.put('ValueComponentUnfiltered', 'Unfiltered');
            mLocs.put('ValueDocument', 'Document');
            mLocs.put('ValueGuidesForThisPage', 'Guides for this page');
            mLocs.put('ValueGuidesIOwn', 'Guides I own');
            mLocs.put('ValueImage', 'Image');
            mLocs.put('ValueVideo', 'Video');
            mLocs.put('ValueWebPage', 'Web-page');
        }

        if (DlgName == 'iahelp__IHReadingListViewer') {
            mLocs.put('AdviceLabelNoEntriesAvailable', 'The requested Guide / Reading List does not appear to be available: this may be because it does not contain any entries to which you have access. Please contact your Help Administrator for more information.');
            mLocs.put('ButtonCancelComment', 'Cancel Comment');
            mLocs.put('ButtonViewInPortal', 'View in Portal');
            mLocs.put('TipButtonAddComment', 'Add a comment about this');
            mLocs.put('TipButtonBookmarkGuide', 'Bookmark this Guide');
            mLocs.put('TipButtonCancelComment', 'Cancel commenting');
            mLocs.put('TipButtonCloseGuideWindows', 'Close all Guide windows');
            mLocs.put('TipButtonEditGuideProperties', 'Edit Guide Properties');
            mLocs.put('TipButtonEditStepTopic', 'Edit Step Topic');
            mLocs.put('TipButtonHelpForGuideWindow', 'Help for the Guide Viewer Window');
            mLocs.put('TipButtonPerformOperation', 'Perform the selected operation');
            mLocs.put('TipButtonShareGuide', 'Share this Guide with a Colleague');
            mLocs.put('TipButtonUnBookmarkGuide', 'Remove the Bookmark for this Guide');
            mLocs.put('TipButtonViewInPortal', 'View the selected Help Topic in the Help Portal');
            mLocs.put('TipButtonViewStepStatistics', 'View Step Statistics');
            mLocs.put('TipButtonViewStepTopic', 'View Step Topic');
            mLocs.put('TipLinkBackIH1', 'Go back to the Help Portal');
            mLocs.put('TitleDialogueTitleGuides', 'Guide');
            mLocs.put('TitleDialogueTitleIH1', 'Reading List');
            mLocs.put('ValueAddLocalStep', 'Add Local step');
            mLocs.put('ValueAddRecordSelectionStep', 'Add record selection step');
            mLocs.put('ValueGSNewLocalStepName', 'New Local Step');
            mLocs.put('ValueGSNewLocalStepSummary', 'Please use the \'Edit Step Topic\' tool to amend this text as required');
            mLocs.put('ValueGSNewRecordSelectionStepName', 'Please select a record');
            mLocs.put('ValueGSNewRecordSelectionStepSummary', 'Please use the \'Edit Step Topic\' tool to amend this text as required and set Step Context to enable record selection');
            mLocs.put('ValueSelectAction', 'Select action to perform');
        }

        if (DlgName == 'iahelp__IHTools' || DlgName == 'iahelp__IHEditingToolsTopic') {
            mLocs.put('AdviceLabelGuideSettings', 'Please note: The settings on this tab apply only to Topics that form part of a Guide and have no bearing on Help delivery in any other circumstances.');
            mLocs.put('ButtonGotoVoteSets', 'Maintain Vote Sets');
            mLocs.put('ButtonPreviewCallout', 'Preview Callout as Saved');
            mLocs.put('ButtonPreviewCalloutAsEdited', 'Preview Callout as Edited');
            mLocs.put('ButtonResetImage', 'Reset Image');
            mLocs.put('ButtonResetVideo', 'Reset Video');
            mLocs.put('FieldLabelActive', 'Active?');
            mLocs.put('FieldLabelCalloutHeight', 'Callout Height');
            mLocs.put('FieldLabelCalloutMediaChoice', 'Callout Media Choice');
            mLocs.put('FieldLabelCalloutTemplate', 'Callout Template');
            mLocs.put('FieldLabelCustomStyle', 'Custom Style');
            mLocs.put('FieldLabelFullTemplate', 'Full Template');
            mLocs.put('FieldLabelHeightBeforeScrolling', 'Height Before Scrolling');
            mLocs.put('FieldLabelImageALTText', 'Image ALT Text');
            mLocs.put('FieldLabelImageCaption', 'Image Caption');
            mLocs.put('FieldLabelImageHeight', 'Image Height');
            mLocs.put('FieldLabelImageTitle', 'Image Title');
            mLocs.put('FieldLabelImageURL', 'Image URL');
            mLocs.put('FieldLabelImageWidth', 'Image Width');
            mLocs.put('FieldLabelKeywords', 'Keywords');
            mLocs.put('FieldLabelLightningTemplate', 'Lightning Topic Viewer Template');
            mLocs.put('FieldLabelMasterTopicIdentifier', 'Master Topic Identifier');
            mLocs.put('FieldLabelName', 'Name');
            mLocs.put('FieldLabelSFHelpURL', 'Salesforce Help URL');
            mLocs.put('FieldLabelShowCallout', 'Show Callout?');
            mLocs.put('FieldLabelShowReadMore', 'Show Read More Link?');
            mLocs.put('FieldLabelShowReferringTopics', 'Show Referring Topics?');
            mLocs.put('FieldLabelStatus', 'Help Topic Status');
            mLocs.put('FieldLabelStepContext', 'Step Context');
            mLocs.put('FieldLabelStepElement', 'Step Element');
            mLocs.put('FieldLabelStepLayout', 'Step Layout');
            mLocs.put('FieldLabelStepMode', 'Step Mode');
            mLocs.put('FieldLabelSummary', 'Summary');
            mLocs.put('FieldLabelVideoCaption', 'Video Caption');
            mLocs.put('FieldLabelVideoHeight', 'Video Height');
            mLocs.put('FieldLabelVideoTitle', 'Video Title');
            mLocs.put('FieldLabelVideoURL', 'Video URL');
            mLocs.put('FieldLabelVideoWidth', 'Video Width');
            mLocs.put('FieldLabelVisibility', 'Visibility');
            mLocs.put('FieldLabelVoteInfo', 'Vote Set');
            mLocs.put('FieldLabelVoteInfoSetImg', 'Vote Set Image');
            mLocs.put('FieldLabelVoteInfoSetText', 'Vote Question Text');
            mLocs.put('MessageCalloutMediaSetToImage', 'Callout media set to image as video not defined');
            mLocs.put('MessageCalloutMediaSetToVideo', 'Callout media set to video as image not defined');
            mLocs.put('MessageCloneTopicNames', 'Please enter a name for each clone Topic');
            mLocs.put('MessageCloneTopicNumber', 'How many clones do you wish to create?');
            mLocs.put('MessageCloneTopicRelationships', 'Do you wish to copy associated relationships for this clone (Y = Yes)?');
            mLocs.put('MessageConfirmUnlink', 'Are you sure you wish to unlink this item?');
            mLocs.put('TipButtonAddTopic', 'Add a new Help Topic NOT tied to any Helped Page Layout');
            mLocs.put('TipButtonAddTopicToRL', 'Add this Topic to an existing Reading List');
            mLocs.put('TipButtonCancel', 'Cancel all changes and return to viewing mode');
            mLocs.put('TipButtonClone', 'Clone the current Help Topic');
            mLocs.put('TipButtonComment', 'Add a comment on this Help Topic for its Author');
            mLocs.put('TipButtonFullSizeImage', 'Click to see full size media...');            
            mLocs.put('TipButtonGotoVoteSets', 'View and Edit Vote Set Information');
            mLocs.put('TipButtonDeleteTopic', 'Delete this Help Topic');
            mLocs.put('TipButtonLinkRelatedHelp', 'Link to a Related Help Topic');
            mLocs.put('TipButtonLinkRelatedResource', 'Link to a Help Resource');
            mLocs.put('TipButtonPopoutRL', 'View this Reading List in a separate browser window');
            mLocs.put('TipButtonPreviewCallout', 'View this Help Topic in a new window in the last saved Callout');
            mLocs.put('TipButtonPreviewCalloutAsEdited', 'View this Topic here in the currently selected Callout');
            mLocs.put('TipButtonPrintTopic', 'Open printable view'); 
            mLocs.put('TipButtonQuickSave', 'Quick-Save changes and continue in topic editing mode');
            mLocs.put('TipButtonResetImage', 'Clear all image fields');
            mLocs.put('TipButtonResetVideo', 'Clear all video fields');
            mLocs.put('TipButtonSave', 'Save changes and return to viewing mode');
            mLocs.put('TipButtonSFHelp', 'SalesForce help for this topic');
            mLocs.put('TipButtonSFHome', 'My Salesforce Home Page');
            mLocs.put('TipButtonSFTopicsTab', 'Jump to the Salesforce Help Topics tab');
            mLocs.put('TipButtonStats', 'Go to Stats Page');
            mLocs.put('TipButtonTopicHistory', 'View Topic History');
            mLocs.put('TipButtonUnlinkRelatedHelp', 'Unlink this Related Help Topic');
            mLocs.put('TipButtonUnlinkRelatedResource', 'Remove the link to this Help Resource');
            mLocs.put('TipButtonViewHelpedElements', 'View Helped Elements');
            mLocs.put('TitleSubtitleRelatedResources', 'External Help Resources');
            mLocs.put('TitleTabCustom', 'Custom');
            mLocs.put('TitleTabGeneral', 'General');
            mLocs.put('TitleTabGuides', 'Guides');
            mLocs.put('TitleTabImage', 'Image');
            mLocs.put('TitleTabStatus', 'Status');
            mLocs.put('TitleTabText', 'Text');
            mLocs.put('TitleTabVideo', 'Video');
            mLocs.put('ValueMediaChoiceImage', 'Image');
            mLocs.put('ValueMediaChoiceVideo', 'Video');
            mLocs.put('ValueTopicStatusApproved', 'Approved');
            mLocs.put('ValueTopicStatusDrafted', 'Drafted');
            mLocs.put('ValueTopicStatusNew', 'New');
            mLocs.put('ValueTopicStatusObsolete', 'Obsolete');
            mLocs.put('ValueTopicStatusPublished', 'Published');
            mLocs.put('ValueTopicStatusSubmittedforApproval', 'Submitted for Approval');
            mLocs.put('ValueTopicStatusSuspended', 'Suspended');
        }
        
        if (DlgName == 'iahelp__IH1Tools') {
            mLocs.put('AdviceLabelBookmark', 'Click this icon to add or remove a Bookmark');
            mLocs.put('AdviceLabelCommentOnTopic', 'Please enter your feedback concerning the current Help Topic');
            mLocs.put('AdviceLabelResourceLocation', 'Location');
            mLocs.put('AdviceLabelResourceUsage', 'Usage');
            mLocs.put('TipButtonViewReadingList', 'View this Reading List');
            mLocs.put('TipTabGoBack', 'Go back to the Help Quick Access Menu');
            mLocs.put('TipTabRelatedHelp', 'View Related Help Topics');
            mLocs.put('TipTabRelatedReadingLists', 'View Related Help Reading Lists');
            mLocs.put('TipTabRelatedResources', 'View Related Help Resources');
            mLocs.put('TipTabTopicDetails', 'View details of the current Help Topic');
            mLocs.put('TitleSubtitleGoingBack', 'Going Back. . .');
            mLocs.put('TitleSubtitleRelatedTopics', 'Related Topics');
            mLocs.put('TitleSubtitleResources', 'Resources');
            mLocs.put('TitleSubtitleTabRelatedReadingLists', 'Related reading lists');
            mLocs.put('TitleSubtitleTabRelatedResources', 'Related resources (opens your browser)');
            mLocs.put('TitleSubtitleTabTopicDetails', 'Selected help topic details');
            mLocs.put('TitleSubtitleTopicDetails', 'Topic Details');
        }       

        if (DlgName == 'iahelp__IH1QAM') {
            mLocs.put('AdviceLabelCommnetOnLayout', 'Please enter your feedback concerning the Topics listed for this Page');
            mLocs.put('AdviceLabelListingDetails', 'Details:');
            mLocs.put('AdviceLabelListingLink', 'Link:');
            mLocs.put('AdviceLabelShowingHelpFor', 'Showing help for');
            mLocs.put('ButtonFilterToButtons', 'Buttons');
            mLocs.put('ButtonFilterToEverything', 'Everything');
            mLocs.put('ButtonFilterToFields', 'Fields');
            mLocs.put('ButtonFilterToLinks', 'Links');
            mLocs.put('ButtonFilterToRelatedLists', 'Related Lists');
            mLocs.put('TipButtonSearch', 'Search for Help Topics by keyword');
            mLocs.put('TipButtonViewTopic', 'View this Help Topic');
            mLocs.put('TipTabHelpForCurrentPage', 'Help Topics for the current Page');
            mLocs.put('TipTabQuickLinks', 'View Help Quick Links');
            mLocs.put('TipTabSearch', 'Search for Help Topics');
            mLocs.put('TitleSubtitleTabBookmarks', 'Bookmarks');
            mLocs.put('TitleSubtitleTabQuickLinks', 'Quick-Links');
            mLocs.put('TitleTabQuickLinks', 'Global help links');
        }

        if (DlgName == 'iahelp__IHConfirmActions') {
            mLocs.put('ColumnLabelDeleteAssociatedTopic', 'Delete associated Help Topic?');
            mLocs.put('ColumnLabelUseExistingTopic', 'To re-use an existing Help Topic, enter its ID');
            mLocs.put('TipButtonCheckToDelete', 'Check to delete step');
            mLocs.put('TipButtonCheckToDeleteTopic', 'Check to delete the Help Topic associated with this Element');
            mLocs.put('TipButtonCheckToEdit', 'Check to update step');
            mLocs.put('TipButtonCheckToHelp', 'Check to help enable');
            mLocs.put('TipButtonCheckToUnhelp', 'Check to un-help');
            mLocs.put('TipButtonSave', 'Save changes as confirmed on this screen');
            mLocs.put('TipButtonSearchForTopic', 'Search for an existing Help Topic to open with this new Element');
            mLocs.put('TipElementType', 'Element type:');
            mLocs.put('TipExistingTopicId', 'Existing Help Topic (ID) to open with this Helped Element');
            mLocs.put('TitleDialogueSubtitleGuide', 'Guide');
            mLocs.put('TitleDialogueTitle', 'Please confirm your actions');
            mLocs.put('TitleSubtitleCreatingElements', 'Helped Elements to be created');
            mLocs.put('TitleSubtitleDeleteSteps', 'DELETE the Guide Steps checked below');
            mLocs.put('TitleSubtitleDeletingElements', 'Helped Elements to be deleted');
            mLocs.put('TitleSubtitleEditSteps', 'ADD / EDIT the Guide Steps checked below');
        }

        if (DlgName == 'iahelp__IHManageSettings') {     
            mLocs.put('AdviceLabelBaselineDocsAbout', 'Help content takes the form of Salesforce records. We offer here a baseline set of Helped User / Help Author documentation in the form of Topics, Reading Lists and related Resources. All documentation is editable by Help Authors / Administrators. Once initialised you are free to adapt or delete any of this content. In addition, certain Lightning tools (buttons etc) are defined in further Salesforce records known as Configuration Items.');
            mLocs.put('AdviceLabelBaselineDocsOverwrite', 'This will overwrite any changes you may have made to our baseline documentation.');
            mLocs.put('AdviceLabelBaselineDocsVersion', 'Last installed documentation version:');
            mLocs.put('AdviceLabelBrandingHelpLink', 'For more information on Branding and styling overrides, see our online');
            mLocs.put('AdviceLabelButtonGotoSubscription', 'To upgrade or update your Subscription, replace ');
            mLocs.put('AdviceLabelButtonRequestSubscription', 'To request a subscription, please');
            mLocs.put('AdviceLabelBrandingColours', 'The following settings can be used to specify brand colours to apply to the Help Portal, Embedded Help panels and individual Help Topics when viewed via Lightning components or callouts whose Custom Style is set to "HouseLEXBrand". The colours should be specified in web "HEX" format (i.e., 6-alphanumeric character RGB codes). Leave these values blank to retain default colours.');
            mLocs.put('AdviceLabelBrandingUXOption', 'This setting hones the appearance of a sub-set of Help features, such as Guide Step Prompts');
            mLocs.put('AdviceLabelCompassAbout', 'The Compass is Improved Help\'s exciting new utility for curating Help information and gaining new insights into content, usage patterns and the relationships between information. To visit the beta version of this tool, please click ');
            mLocs.put('AdviceLabelConsoleAbout', 'This tab relates to the behaviour of Help when used within Salesforce Console applications. As of this release, there are no settings applicable to this context.');
            mLocs.put('AdviceLabelConsoleHelpEnableLink', 'For advice about how to include Help on Console pages');
            mLocs.put('AdviceLabelConsoleSpring14', 'Following changes to the way external links behave (to prevent the risk of clickjacking), it is no longer possible to open Help Resources as Console tabs. Help Resources are still supported but will open in fresh browser tabs / windows.');
            mLocs.put('AdviceLabelContentPacks', 'We also provide optional free Help Content Packs that you can install and adapt as you see fit. These are available ');
            mLocs.put('AdviceLabelDownloadXLS', 'You can download your Help records to an Excel file that can be used to populate our XML creation spreadsheet. The resulting XML can then be uploaded to another help-enabled Org by following the procedure outlined above. Note: export is limited to a maximum of 1000 records of each Help object type. ');
            mLocs.put('AdviceLabelEnableRLExportToWord', 'Enable export of Reading Lists to word processing formats');
            mLocs.put('AdviceLabelEnableTopicExportToWord', 'Enable export of Help Topics to word processing formats');
            mLocs.put('AdviceLabelExperimentalFeaturesAbout', 'This tab controls the availability of certain advanced features of Help. These features are offered "as is" and may be subject to revision or removal in future releases.');
            mLocs.put('AdviceLabelExportExcel', 'Enable export of Help records to spreadsheet format');
            mLocs.put('AdviceLabelExportExcelAbout', 'Check the box below to allow Help Administrators to download the majority of Help data to Excel in a format readily suited to our XML import utility. The resulting XML can be uploaded to one or more target Orgs.');
            mLocs.put('AdviceLabelExportFacilities', 'Check the boxes below to display tools in the Help Portal and related dialogues that enable download of help content in Office Open XML and similar formats suited to use by popular desktop productivity packages.');
            mLocs.put('AdviceLabelFAQs', 'For answers to common product-related queries, please see');
            mLocs.put('AdviceLabelFeedbackMessagesAbout', 'This tab allows local overrides for the feedback messages provided to Helped Users in various circumstances.');
            mLocs.put('AdviceLabelHelpEnablingAbout', 'Various types of specific elements on a page can be marked as \'hooks\' into Help Topics. This tab controls which of these potential Helped Elements are to be \'Help-able\' in the org. These help-able elements can then be selected by Help Authors or Help Administrators to create formal Helped Elements which link to specific Help Topics. Creation of Helped Elements and Helped Page Layouts is achieved by accessing the page in \'Help-Enable\' mode from the Help Quick Access Menu. NOTE: Only users with Help Author or Help Administrator Permissions will see Help-Enable mode as an option in the Help Quick Access Menu. The Help Quick Access Menu is only visible for Users whose Profile is associated with a Home Page Layout that has been Help-Enabled with the Help Home Page Component. (See the Initial Setup tab for more details)');
            mLocs.put('AdviceLabelHelpTopicsAbout', 'This tab sets default values for Help Topic records and controls related callout behaviour.');
            mLocs.put('AdviceLabelInitialiseProfileLayouts', 'Click the button to obtain and store key information (metadata) about the page layout assignments by role and record type that have been configured in this org. Obtaining this essential information \'costs\' an API call, so for maximum efficiency Improved Help keeps its own copy of this data for use on certain help-enabled screens. NOTE: these API calls require a remote site to be added for the Visualforce domain of this page: search for \'Remote Site Settings\' in Setup, then click the ADD button to add a record allowing this site to make API calls.');
            mLocs.put('AdviceLabelInitialiseSettings', 'Click the button below during initial configuration to create your Org\'s Help Settings');
            mLocs.put('AdviceLabelInteractionsLink', 'Your Org\'s Interactions records can be found');
            mLocs.put('AdviceLabelInteractionsDownloadLink', 'and downloaded');
            mLocs.put('AdviceLabelDownloadConfig', 'You can download your configuration records to a text file. The resulting JSON can then be uploaded to another help-enabled Org by following the procedure outlined above.');
            mLocs.put('AdviceLabelLoadXML', 'You can bulk upload Help Content and Helped Page configuration data using specially formatted XML files using the button below: see help or contact us for more information.');
            mLocs.put('AdviceLabelQuickLinksAbout', 'This tab controls the display of global help \'Quick-Links\' in the Header area of the Help Portal. For each Quick-Link, add the full URL, Link Text (the label to display) and any Tool-tip to be revealed on a hover.');
            mLocs.put('AdviceLabelQuickStart', 'Configuration of Help is a simple process, involving the Help-Enabling of Profiles, Users and Page Layouts - to allow Authors to create content and Helped Users to provide feedback.');
            mLocs.put('AdviceLabelQuickStartLink', 'For a  a step-by-step walk-through of the few steps needed to configure Help, please refer to this');
            mLocs.put('AdviceLabelRelatedContentAbout', 'This tab controls the appearence of the various related topic listings included on the Portal page and elsewhere.');
            mLocs.put('AdviceLabelRemoteSiteURL', 'Remote Site for metadata API access');
            mLocs.put('AdviceLabelRefreshLayoutMetadata', 'Embedding Help with Autoform? Select the relevant helped objects to obtain the layout assignment metadata that Autoforms need...');
            mLocs.put('ButtonRefreshLayoutMetadata', 'Refresh Layout Metadata');
            mLocs.put('AdviceLabelSelectGuideLinkOption', 'When Guides are available on a given Salesforce page');
            mLocs.put('AdviceLabelSetHBS', 'Set the height before scrolling for all existing help topics to (pixels)  ');
            mLocs.put('AdviceLabelSettingsNotInitialised', 'Please click the button to initialise your Organisation\'s Help global settings.');
            mLocs.put('AdviceLabelShowNextPrevious', 'Show Next/Previous Links');
            mLocs.put('AdviceLabelShowNextPreviousAbout', 'When viewing Reading Lists from the Help Portal or popout Reading List Viewer window');
            mLocs.put('AdviceLabelShowReferringTopics', 'Also list Help Topics that refer TO the current Help Topic');
            mLocs.put('AdviceLabelShowReferringTopicsAbout', 'If a Help Author links FROM a Help Topic to others, these Related Topics are always visible in the Help Portal.');
            mLocs.put('AdviceLabelSignaturesAbout', 'Signatures have been developed to vastly expand the reach, power and flexibility of Help. Rather than relying on the presence of a limited set of known helpable elements (which are defined by recognised patterns of tags in page mark-up), Signatures allow Orgs/ISVs to define their own patterns such that Help will look for them and allow them to be hooked. They take the form of standard Salesforce custom object records that define mark-up patterns which, within the context of a particular web domain, represent helpable pieces of screen furniture. Signatures for the relevant domain are provided to pages as part of the Hook\'s request for known helpables data. As a result of this, the elements defined by the Signatures can be hooked in the same way as the standard Salesforce and Visualforce helpables. If you wish to use Signatures, please contact us for further information.');
            mLocs.put('AdviceLabelSignaturesLink', 'Your Org\'s Signature records can be found');
            mLocs.put('AdviceLabelSubscriptionAbout', 'The details of your Help Subscription are as follows');
            mLocs.put('AdviceLabelSupportGeneral', 'Need help? We\'d love to hear from you. For general enquiries, please');
            mLocs.put('AdviceLabelSupportTechnical', 'For technical assistance, please email');
            mLocs.put('AdviceLabelTrackingAbout', 'This tab controls the logging history period for Help Interactions of different types are retained for reporting purposes. Interaction records older than the thresholds set below will be deleted automatically, once Scheduled Maintenance has been set (by clicking the Schedule Maintenance button). Set the required Logging History by Interaction Type in Days (choose \'0\' days to disable Interaction logging where reporting is not required).');
            mLocs.put('AdviceLabelUnlimitedUsers', 'Please note: as you are covered for unlimited users, you need not allocate individual users to subscriptions.');
            mLocs.put('AdviceLabelUploadDownloadConfig', 'Certain Help clickables, such as menu items and tools offered on helped Lightning pages, can be defined using configuration records. You can download to, and upload from documents in JSON format here.');
            mLocs.put('AdviceLabelWhitelisting', 'Improved Help can be made available to non-Salesforce web sites using a combination of Help Signatures and our optional browser extensions. In these scenarios, if Help is to appear on certain web sites only, enter a comma separated list of their domains (without protocols, e.g., "example.com" or "subdomain.example.com"). NOTE: leave this field blank where browser extensions are not in use or to have help appear on all sites.');
            mLocs.put('ButtonBrandingHelpLink', 'Branding Settings Guide');
            mLocs.put('ButtonConsoleHelpEnableLink', 'please visit our website');
            mLocs.put('ButtonDownloadConfig', 'Download JSON');
            mLocs.put('ButtonDownloadXLS', 'Export to Excel');
            mLocs.put('ButtonFAQs', 'Help for Improved Help');           
            mLocs.put('ButtonGotoSubscription', 'this Document');
            mLocs.put('ButtonInitialiseProfileLayouts', 'Get Layout Metadata');
            mLocs.put('ButtonInitialiseSettings', 'Initialise Settings');
            mLocs.put('ButtonInstallDocumentation', '(Re)install Documentation');
            mLocs.put('ButtonManageUsers', 'Manage your users (requires Manage Users System Permissions)');
            mLocs.put('ButtonQuickStartLink', 'Quick-start Guide');
            mLocs.put('ButtonRequestSubscription', 'visit our pricing page');
            mLocs.put('ButtonScheduleMaintenance', 'Schedule Maintenance');
            mLocs.put('ButtonSetHBS', 'Set Height');
            mLocs.put('ButtonSupportGeneral', 'contact us');
            mLocs.put('ButtonUpsertConfig', 'Upsert Configuration Tools');
            mLocs.put('ButtonUpsertDocumentation', 'Upsert Documentation');
            mLocs.put('ButtonViewUserReports', 'View user reports');
            mLocs.put('ColumnLabelLink', 'Link');
            mLocs.put('ColumnLabelLinkText', 'Link Text');
            mLocs.put('ColumnLabelTip', 'Tip');
            mLocs.put('ColumnLabelURL', 'URL');
            mLocs.put('FieldLabelAllowCommentsByDefault', 'Allow Layout Comments by default?');
            mLocs.put('FieldLabelRaisePlatformEvents', 'Raise Platform Events');
mLocs.put('FieldLabelLocationTracking', 'Allow Geolocation Tracking');  
mLocs.put('FieldLabelGeoTimeout', 'Geolocation Timeout (milliseconds)');  
mLocs.put('FieldLabelGeoEnableHighAccuracy', 'Enable High Geolocation Accuracy');           
            mLocs.put('FieldLabelBrandColour1', 'Light theme: Lightning Component Body Colour');
            mLocs.put('FieldLabelBrandColour1Text', 'Default theme');
            mLocs.put('FieldLabelBrandColour2', 'Dark theme: Lightning Component Body Colour');
            mLocs.put('FieldLabelBrandColour3', 'All themes: Embedded Component Body Colour');
            mLocs.put('FieldLabelBrandColour4', 'Light theme: Lightning Component Header Colour');
            mLocs.put('FieldLabelBrandColour5', 'Dark theme: Lightning Component Header Colour');
            mLocs.put('FieldLabelBrandColour6', 'All themes: Font Colour');
            mLocs.put('FieldLabelBrandColour7', 'Light theme: Highlight Colour');
            mLocs.put('FieldLabelBrandColour8', 'Dark theme: Highlight Colour');
            mLocs.put('FieldLabelBrandingCustomStyles', 'Custom Styles');
            mLocs.put('FieldLabelBrandingCustomerCSS', 'Customer Stylesheet URL (Classic)');
            mLocs.put('FieldLabelBrandingCustomerCSSLUX', 'Customer Stylesheet Data (Lightning)');
            mLocs.put('FieldLabelBrandingHelpedElementToolTip', 'The tool tip to use for Helped Elements is now defined in the relevant Help Localisation file(s).');
            mLocs.put('FieldLabelBrandingLogo', 'Help Portal Logo');
            mLocs.put('FieldLabelBrandingSlogan', 'Help Portal Slogan');
            mLocs.put('FieldLabelBrandingTitle', 'Help Portal Title');
            mLocs.put('FieldLabelBrandingUXOption', 'User Experience');
            mLocs.put('FieldLabelCalloutClosureBehaviour', 'Callout Closure Behaviour');
            mLocs.put('FieldLabelCalloutTemplate', 'Callout Template');
            mLocs.put('FieldLabelCalloutWidth', 'Callout Width (%)');
            mLocs.put('FieldLabelCallouts', 'Callouts');
            mLocs.put('FieldLabelCommentLogged', 'The\'Comment Logged Successfully\' message is now defined in the relevant Help Localisation file(s).');
            mLocs.put('FieldLabelComments', 'Comments');
            mLocs.put('FieldLabelConfigurationIssues', 'Configuration Issues');
            mLocs.put('FieldLabelCreateAsActive', 'Create as Active?');
            mLocs.put('FieldLabelDaysToReview', 'Days from Topic modification to review');
            mLocs.put('FieldLabelDebugMode', 'Enable Debug Messages');
            mLocs.put('FieldLabelDefaultHelpTopic', 'Default Help Topic');
            mLocs.put('FieldLabelDefaultHelpTopicTreeProvider', 'Default Node Sort Order for Help Topic Trees');
            mLocs.put('FieldLabelDefaultVisibility', 'Default Visibility');
            mLocs.put('FieldLabelDefaultVoteSet', 'Default Vote Set');         
            mLocs.put('FieldLabelDoLoginChecks', 'Perform login checks prior to opening Help Callouts');
            mLocs.put('FieldLabelExpiryDate', 'Expiry Date');
            mLocs.put('FieldLabelFullTemplate', 'Full Template');
            mLocs.put('FieldLabelGuidesTemplate', 'Guides Template');
            mLocs.put('FieldLabelHelpEnableButtons', 'Buttons');
            mLocs.put('FieldLabelHelpEnableCustomLinks', 'Custom Links');
            mLocs.put('FieldLabelHelpEnableCustomSectionHeadings', 'Custom Section Headings');
            mLocs.put('FieldLabelHelpEnableFieldLabels', 'Field Labels');
            mLocs.put('FieldLabelHelpEnablePageHelp', 'Help for this Page / Help and Training Portal links');
            mLocs.put('FieldLabelHelpEnableRecordDetailSectionLabel', 'Record Detail Section Label');
            mLocs.put('FieldLabelHelpEnableRecordTitle', 'Record Title');
            mLocs.put('FieldLabelHelpEnableRelatedListColumnLabels', 'Related List Column Labels');
            mLocs.put('FieldLabelHelpEnableRelatedListLabels', 'Related List Labels');
            mLocs.put('FieldLabelHelpEnableRelatedListObjectHelpLinks', 'Related List Object Help Links');
            mLocs.put('FieldLabelHelpResourceViews', 'Help Resource Views');
            mLocs.put('FieldLabelImageUploadFolder', 'Document Folder (ID) to use for uploaded Help Topic Images');
            mLocs.put('FieldLabelHoursAmended', 'Hours from Topic modification to retain \'Amended\' styling');
            mLocs.put('FieldLabelLUXOps', 'Lightning Interactions');
            mLocs.put('FieldLabelMissingDefaultTopic', 'The\'Missing / Inactive Default Help Topic\' message is now defined in the relevant Help Localisation file(s).');
            mLocs.put('FieldLabelMissingHelpedElement', 'The\'Missing Helped Element\' message is now defined in the relevant Help Localisation file(s).');
            mLocs.put('FieldLabelMissingTemplate', 'The\'Missing Help Template\' message is now defined in the relevant Help Localisation file(s).');
            mLocs.put('FieldLabelOrganisation', 'Organisation');
            mLocs.put('FieldLabelProduct', 'Product');
            mLocs.put('FieldLabelResetHeight', 'Reset height before scrolling');
            mLocs.put('FieldLabelSalesforceServerPod', 'Salesforce Server Pod');
            mLocs.put('FieldLabelSearches', 'Searches');
            mLocs.put('FieldLabelSeatsAllocated', 'Seats - Allocated');
            mLocs.put('FieldLabelSeatsRemaining', 'Seats - Remaining');
            mLocs.put('FieldLabelSeatsTotal', 'Seats - Total');
            mLocs.put('FieldLabelShelfLifeWarning', 'Printed content \'Shelf-life\' warning');
            mLocs.put('FieldLabelShowReadMore', 'Show "Read More" links?');
            mLocs.put('FieldLabelSubscriptionNumber', 'Subscription Number');
            mLocs.put('FieldLabelSubscriptionStatus', 'Subscription Status');
            mLocs.put('FieldLabelSubscriptionType', 'Subscription Type');
            mLocs.put('FieldLabelTopics', 'Topics, Tree Nodes and Reading List Entries');
            mLocs.put('FieldLabelVersion', 'Version');
            mLocs.put('FieldLabelVotes', 'Votes');
            mLocs.put('MessageBrandImageReset', 'Brand Image re-set to default');
            mLocs.put('MessageCreateRemoteSite', 'Done: Please click the link below, then paste the contents of your clipboard into the "Remote Site URL" field of a new Remote Site record.');
            mLocs.put('MessageEnterJSONPath', 'Please enter the path to your JSON data file');
            mLocs.put('MessageEnterXMLPath', 'Please enter the path to your XML data file');
            mLocs.put('MessageHBSReset', 'Your request is being processed. This action may take some time to complete and can be monitored via the Salesforce "Apex Jobs" Setup page');
            mLocs.put('MessageQuickLinkError', 'Warning: settings not saved due to error in Quick Link ');
            mLocs.put('MessageQuickLinkRequiresLinkAndURL', 'You must specify both link text and URL for Quick Links where a tip has been entered');
            mLocs.put('MessageQuickLinkRequiresLinkText', 'You must specify link text where a Quick Link URL has been entered');
            mLocs.put('MessageQuickLinkRequiresURL', 'You must specify the URL where Quick Link Text has been entered');
            mLocs.put('TipButtonBrandingHelpLink', 'Visit our Branding Settings page');
            mLocs.put('TipButtonCancel', 'Undo any pending changes to Global Settings');
            mLocs.put('TipButtonCompass', 'Click to show the Improved Help Compass');
            mLocs.put('TipButtonContentPacks', 'Click to visit our Content Packs page');
            mLocs.put('TipButtonCreateRemoteSite', 'Click to open Remote Site settings for this Org');
            mLocs.put('TipButtonDownloadConfig', 'Export configuration data to a JSON file');
            mLocs.put('TipButtonDownloadXLS', 'Export help records to Excel');
            mLocs.put('TipButtonGotoSubscription', 'View your Subscription Document');
            mLocs.put('TipButtonHelpableSignatures', 'View Helpable Signature records');
            mLocs.put('TipButtonInitialiseProfileLayouts', 'Click to obtain and store metadata about layout assignments in this org');
            mLocs.put('TipButtonInitialiseSettings', 'Click to initialise help settings');
            mLocs.put('TipButtonInstallDocumentation', '(Re)install baseline help documentation');
            mLocs.put('TipButtonInteractions', 'View Help Interactions records');
            mLocs.put('TipButtonInteractionsDownload', 'Download Help Interactions records');
            mLocs.put('TipButtonManageUsers', 'View listings of (Helped) users');
            mLocs.put('TipButtonRefreshLayoutMetadata', 'Click this button to create an asynchronous Apex Job which will obtain layout assignment and custom section metadata for use by Autoform components');
            mLocs.put('TipButtonRequestSubscription', 'Visit our website to obtain a new Subscription document');
            mLocs.put('TipButtonSave', 'Save any changes made to Global Settings');
            mLocs.put('TipButtonScheduleMaintenance', 'Create a Salesforce scheduled job to delete old interation records');
            mLocs.put('TipButtonSetHBS', 'Resets topic Height Before Scrolling to the value specified for all existing Help Topics with immediate effect');
            mLocs.put('TipButtonSupportGeneral', 'Get in touch with us');
            mLocs.put('TipButtonSupportTechnical', 'Send an email to our Technical Support team');
            mLocs.put('TipButtonUpsertConfig', 'Click to create help configuration records from the specified JSON file');
            mLocs.put('TipButtonUpsertDocumentation', 'Click to create help records from the specified XML file');
            mLocs.put('TipButttonViewUserReports', 'View Subscription Allocation report');
            mLocs.put('TipDoLoginChecks', 'If checked, Improved Help will check the user remains logged in to Salesforce prior to attempting to open callouts or help dialogues');
            mLocs.put('TipFieldBrandingCustomStyles', 'Comma separated list of CSS style names that can be applied to Help Topics: these styles should be defined in the Customer Stylesheet (CSS) file rerefenced above');
            mLocs.put('TipFieldBrandingCustomerCSS', 'Sets the location of the stylesheet that controls local branding of the Help user experience, such as colours & icons, in pre-Lightning environments');
            mLocs.put('TipBrandingCustomerCSSLUX', 'Click the button below to enable advanced styling for the Lightning Experience. This enhances performance and simplifies branding options.');
            mLocs.put('TipFieldBrandingHelpedElementToolTip', 'Enter the text you wish to appear when users hover over Helped Elements.');
            mLocs.put('TipFieldBrandingLogo', 'Sets the Help Portal\'s logo. This image needs to be available on a publicly accessible URL and ideally in PNG format with a transparent background and 16:9 aspect ratio, to sit well in the 200px x 112px container.');
            mLocs.put('TipFieldBrandingSlogan', 'Enter your preferred wording for slogan that appears beneath the main Title on the Help Portal.');
            mLocs.put('TipFieldBrandingTitle', 'Enter your preferred wording for the main Title that appear at the head of the Help Portal.');
            mLocs.put('TipHelpEnableButtons', 'Allows activation of standard & custom Buttons as Helped Elements, linked to associated Help Topics');
            mLocs.put('TipHelpEnableCustomLinks', 'Allows activation of custom links as Helped Elements, linked to associated Help Topics');
            mLocs.put('TipHelpEnableCustomSectionHeadings', 'Allows activation of Custom Section Heading labels as Helped Elements, linked to associated Help Topics');
            mLocs.put('TipHelpEnableFieldLabels', 'Allows activation of Field Labels as clickable Helped Elements, linked to associated Help Topics');
            mLocs.put('TipHelpEnablePageHelp', 'Allows diversion of the \'Help for this Page\' link to an Help Topic, rather than the standard Salesforce link. This in turn allows locally defined Help for custom objects (or heavily customised standard objects). Useful Salesforce Help links can then be added \'behind\' the linked Help Topic, as Related Help Resources, set in context through Help Topic-specific Resource Usage Notes');
            mLocs.put('TipHelpEnableRecordDetailSectionLabel', 'Allows linking of the standard Record Detail section label to an object-wide Help Topic (which will appears automatically on all Page Layouts under the parent standard or custom object)');
            mLocs.put('TipHelpEnableRecordTitle', 'Allows linking of standard Record title text to a Help Topic');
            mLocs.put('TipHelpEnableRelatedListColumnLabels', 'Allows activation of Related List Column Labels as clickable Helped Elements, linked to associated Help Topics');
            mLocs.put('TipHelpEnableRelatedListLabels', 'Allows activation of Related List labels as clickable Helped Elements, linked to associated Help Topics');
            mLocs.put('TipHelpEnableRelatedListObjectHelpLinks', 'Allows diversion of Related List Object links to an Help Topic, rather than the standard Salesforce link. This in turn allows locally defined Help for custom objects (or heavily customised standard objects). Useful Salesforce Help links can then be added \'behind\' the linked Help Topic, as Related Help Resources, set in context through Help Topic-specific Resource Usage Notes.');
            mLocs.put('TipInputTextboxJSONPath', 'Enter the full path to the Salesforce document containing your JSON data');
            mLocs.put('TipInputTextboxXMLPath', 'Enter the full path to the Salesforce document containing your XML data');
            mLocs.put('TipQuickStartLink', 'Online Quick Start Guide');
            mLocs.put('TipTipButtonFAQs', 'Launch Help for Improved Help in a new tab...');
            mLocs.put('TitleBranding', 'Branding Options');
            mLocs.put('TitleConsole', 'Console Options');
            mLocs.put('TitleConsoleHelpEnableLink', 'How to set up Improved Console Help');
            mLocs.put('TitleCreateRemoteSite', 'Start Here!');
            mLocs.put('TitleDialogueTitle', 'Global Settings');
            mLocs.put('TitleDocumentation', 'Help Content and Configuration Records');
            mLocs.put('TitleExperimentalFeatures', 'Enable optional advanced product features');
            mLocs.put('TitleFeedbackMessages', 'Help Feedback Messages');
            mLocs.put('TitleHelpEnabling', 'Select what can be \'Help-able\' on Helped Page Layouts');
            mLocs.put('TitleHelpTopics', 'Help Topic Management Options');
            mLocs.put('TitleInitialisationComplete', 'Congratulations, Digital Adopter! Looks like you\'re all set!');
            mLocs.put('TitleQuickLinks', 'Portal Quick-Links Setup');
            mLocs.put('TitleQuickStart', 'Quick-Start Guide');
            mLocs.put('TitleRelatedContent', 'Related Content Options');
            mLocs.put('TitleSubscription', 'Product Subscription Information');
            mLocs.put('TitleSubtitleCompass', 'Improved Help Compass');
            mLocs.put('TitleSubtitleConsoleHelpEnable', 'Help Enabling Console Pages');
            mLocs.put('TitleSubtitleConsoleSpring14', 'Changes for Spring 14 Compatibility');
            mLocs.put('TitleSubtitleCreateRemoteSite1', 'Please click the image below to create a Salesforce Remote Site record with the following Remote Site URL:');
            mLocs.put('TitleSubtitleCreateRemoteSite2', 'Be assured that the Remote Site does not cause any data to leave your org and is required only to allow Improved Help to access the Salesforce Metadata API.');
            mLocs.put('TitleSubtitleDocumentationDownloadXLS', 'Download Help Records');
            mLocs.put('TitleSubtitleDocumentationFAQs', 'Help for Improved Help');
            mLocs.put('TitleSubtitleDocumentationInitialise', 'Initialise Help Documentation');
            mLocs.put('TitleSubtitleDocumentationLoadXML', 'Load XML from this location');
            mLocs.put('TitleSubtitleDocumentationReinstallDocs', 'Click the button to (re)install Help Documentation');
            mLocs.put('TitleSubtitleDocumentationSupport', 'Support');
            mLocs.put('TitleSubtitleDocumentationUploadAdditionalHelp', 'Upload Additional Help');
            mLocs.put('TitleSubtitleDownloadConfig', 'Download Configuration Items');
            mLocs.put('TitleSubtitleExportFacilities', 'Content Export Facilities');
            mLocs.put('TitleSubtitleGuides', 'Guides');
            mLocs.put('TitleSubtitleInitialisationComplete', 'You may need to wait a short while and refresh this page to see Help content');
            mLocs.put('TitleSubtitleInitialiseProfileLayouts', 'Get Profile Layout Metadata');
            mLocs.put('TitleSubtitleInitialiseSettings', 'Initialise Global Help Settings');
            mLocs.put('TitleSubtitleSignatures', 'Helpable Signatures');
            mLocs.put('TitleSubtitleUploadConfig', 'Load configuation JSON from this location');
            mLocs.put('TitleSubtitleUploadDownloadConfig', 'Upload Configuration Items');
            mLocs.put('TitleSubtitleUsers', 'Help User Information');
            mLocs.put('TitleTabBranding', 'Branding');
            mLocs.put('TitleTabConsole', 'Console');
            mLocs.put('TitleTabDocumentation', 'Data Migration');
            mLocs.put('TitleTabExperimentalFeatures', 'Advanced Features');
            mLocs.put('TitleTabFeedbackMessages', 'Feedback Messages');
            mLocs.put('TitleTabHelpEnabling', 'Help-Enabling');
            mLocs.put('TitleTabHelpTopics', 'Help Topics');
            mLocs.put('TitleTabQuickLinks', 'Quick-Links');
            mLocs.put('TitleTabQuickStart', 'Quick-Start');
            mLocs.put('TitleTabRelatedContent', 'Related Content');
            mLocs.put('TitleTabSubscription', 'Subscription');
            mLocs.put('TitleTabTracking', 'Tracking');
            mLocs.put('TitleTracking', 'Help Interaction Tracking Options');
            mLocs.put('TitleWhitelisting', 'Help Domain Whitelisting');
            mLocs.put('ValueAuthorsSortOrder', 'Author-specified sort order');
            mLocs.put('ValueClose2ndClick', 'Close on Helped Element 2nd Click');
            mLocs.put('ValueCloseEither', 'Close on mouse out or 2nd Click');
            mLocs.put('ValueCloseMouseOut', 'Close on mouse out of Callout');
            mLocs.put('ValueFixedSortOrder', 'Fixed alphabetical sort order');
            mLocs.put('ValueGuideLinksQAMAndButton', 'Add Guides custom button plus Menu link');
            mLocs.put('ValueGuideLinksQAMAndPage', 'Add Guides link to page and Menu');
            mLocs.put('ValueGuideLinksQAMOnly', 'Add Guides link to Quick Access Menu only');
        }
        
        if (DlgName == 'iahelp__TemplatePrintable') {
            mLocs.put('AdviceLabelPrintShelfLife', 'Warning: The accuracy of printed information is not guaranteed. Always refer to online Help if in any doubt.');
            mLocs.put('AdviceLabelTopicReviewDeadline', 'Topic scheduled review deadline');
            mLocs.put('AdviceLabelViewInPortal', 'For updated information, please visit');
            mLocs.put('TipViewInPortal', 'View in Portal');
            mLocs.put('AdviceLabelExportAs', 'Export Topic as');
            mLocs.put('ButtonExportAsHTML', 'HTML (includes media)');
            mLocs.put('TipButtonExportAsHTML', 'Click to download Topic as HTML file');
            mLocs.put('ButtonExportAsXML', 'XML (text only)');
            mLocs.put('TipButtonExportAsXML', 'Click to download Topic as Office-compatible XML file');
        }
        
        if (DlgName == 'IHOmniFilter') {
            mLocs.put('AdviceLabelAnd', 'AND');
            mLocs.put('TitleDialogueTitle', 'Filtering');
            mLocs.put('ColumnLabelField', 'Field');
            mLocs.put('ColumnLabelOperator', 'Operator');
            mLocs.put('ColumnLabelValue', 'Value');
            mLocs.put('ButtonAddRow', 'Add Row');
            mLocs.put('ButtonRemoveRow', 'Remove Row');
            mLocs.put('ButtonSave', 'Save');
            mLocs.put('ButtonNew', 'New');
            mLocs.put('ButtonRename', 'Rename');
            mLocs.put('ButtonDelete', 'Delete');
            mLocs.put('FieldLabelSelectSet', 'Select Filter Set');
            mLocs.put('ButtonAddLogic', 'Add Filter Logic');
            mLocs.put('ButtonClearLogic', 'Clear Filter Logic');
            mLocs.put('FieldLabelLogic', 'Filter Logic');
        }
        
        // Component generator when in design mode        
        if (DlgName == 'CGDesignMode') {
            mLocs.put('AdviceLabelCGStep1', 'Select the component you wish to generate');
            mLocs.put('AdviceLabelCGStep2', 'Add attributes and set their values');
            mLocs.put('AdviceLabelCGStep3', 'Click the button to generate component definition instructions');
            mLocs.put('ButtonGenerate', 'Generate');
            mLocs.put('TipAttrAdd', 'Add a design attribute setting');
            mLocs.put('TipAttrDelete', 'Delete this design attribute');
            mLocs.put('TitleSubtitleCGStep3', 'You can also edit the definition by hand if desired');    
            mLocs.put('TipCueContextHelp', 'Help for this area…');       
        }        
        
        return mLocs;
    }
    
}