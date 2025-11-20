({

    // Set latch allowing URL parameters to be considered on page load only
    // Also, initialise some stencil and sizing settings
    Init: function (cmp, event, helper) {
        
        
        // Latch means HTID instructions etc. can be checked, but will not interfere with
        // subsequent AJAX-type record changes:
        // Typically, c.f., init or doneRendering in inheritor components, where latch is checked, parameters
        // used once only, then latch set to false...
         console.log('Inside Doinit');
        cmp.set("v.CheckURLParams", true);
        console.log('Inside Doinit');
        
        //Added as part of Mobile enhancement: record details of the form factor of the user's screen/device
        var device = $A.get("$Browser.formFactor");
        cmp.set("v.BrowserFormFactor", device);
        
        // Derive form factor numeric value from user's device
        switch (device) {
            case 'PHONE':
                cmp.set('v.FormFactorVal', 1);
                break;
            case 'TABLET':
                cmp.set('v.FormFactorVal', 2);
                break;
            case 'DESKTOP':
                cmp.set('v.FormFactorVal', 3);
                break;
        }
        
        // Number of rows to paint as waiting stencil
        var SRs = [1, 2, 3, 4, 5];
        cmp.set("v.StencilRows", SRs);
        
        // Attempt to use cacheing for performance hard-wired OFF as of this release        
        cmp.set("v.SkipGlobals", false);
        
        
        //Check whether utility bar is in play, as this affects certain positioning / sizing settings
        var UBCheckDelay = cmp.get("v.UtilityBarCheckDelay");
        if (UBCheckDelay < 1000) { UBCheckDelay = 1000; }
        
        window.setTimeout($A.getCallback(function () {
            helper.initialiseUB(cmp, event, helper);
        }), UBCheckDelay);
        
        
        // Setup component sizing / resize logic for some key height params etc.
        console.log('Before Apex call');
       cmp.set("v.SizingTimer", helper.setSizingTimer(cmp, event, helper));
		
    },
  
	// Placeholder for jQuery post-processing
	afterJQ: function (cmp) {

		// Advise child components that scripts are available for use
		var appEvent = $A.get("e.c:evtPassThrough");
		appEvent.setParams({ "SourceComponent": cmp.get("v.ComponentId") });
		appEvent.setParams({ "ActionCode": 'ScriptsAvailable' });
		appEvent.fire();

	},

	// DRAGGABLE TESTS - DISABLED AS AT 1.55
	// REMOVE if not retaining jQ UI
	/*
	afterJQUI : function (cmp, event, helper) {
		helper.setupJQUI(cmp, event, helper);
	},
	*/



	// Show / Hide ellipsis menu
	toggleEllipsisTools: function (cmp, event, helper) {
		console.log('Toggle Ellipsis Tools -------');
		var ctl = cmp.find('toolsEllipsis');
		$A.util.toggleClass(ctl, 'slds-dropdown');
		$A.util.toggleClass(ctl, 'slds-hide');
	},


	// Respond to clicks on our history listing: raise navigation event and hide history
	historyClick: function (cmp, event, helper) {

		var rec = event.currentTarget.id;

		// Before firing topic selection event, we need to set a 'latch' on
		// the component whose history is being used to ensure the component listens:
		// This ensures we always navigate, regardless of whether implementation is listening
		// to 'self' for topic selection events, which would be unusual
		cmp.set("v.ResponseLatch", true);

		var appEvent = $A.get("e.c:selectTopic");
		appEvent.setParams({ "RecordId": rec });
		appEvent.setParams({ "SourceComponent": cmp.get('v.ComponentId') });
		appEvent.fire();

		// Hide history once clicked
		var HC = cmp.find("HistoryContainer");
		$A.util.toggleClass(HC, 'slds-hide');
	},


	// Show / hide drop down menu
	toggleDropDownTools: function (cmp, helper) {
		var ctl = cmp.find('toolsDropDown');

		$A.util.toggleClass(ctl, 'slds-dropdown');
		$A.util.toggleClass(ctl, 'slds-hide');

	},


	// Respond to drop-target events
	dropTargetFire: function (cmp, event, helper) {

		var lst = event.target;
		var theId = lst.id;
		var D1 = cmp.get('v.Delimiter');

		theId = theId.split(D1);

		// Drop "message" (the id of the clickable) is in the form:
		// [Specified support tool ID] [Delimiter] [Action code] 
		switch (theId[1]) {
			case 'DropSearch':
				helper.dropSearch(cmp, event);
				break;

			case 'DropNewTopic':
				helper.dropNewTopic(cmp, event);
				break;

			default:
				// Anything we don't handle at super level we should pass through for sub-component handling
				var appEvent = $A.get("e.c:evtPassThrough");
				appEvent.setParams({ "SourceComponent": cmp.get("v.ComponentId") });
				appEvent.setParams({ "ActionCode": theId[1] });
				appEvent.setParams({ "Parameters": theId[0] });
				appEvent.fire();

				break;

		}

	},


	// Respond to menu item (ellipsis, header or drop down) clicks
	menuItemClick: function (cmp, event, helper) {
		// This event may have been fired directly via a control click, or as a "negotiated" tool click pass-through:    
		// Detect which is in play here and obtain parameters accordingly
		var theId;
		var incomingId;

		try {
			// Only pass-throughs / negotiated tools will have parameters of this kind
			var src = event.getParam("SourceComponent");
			var target = event.getParam("Target");

			// Only handle pass-throughs from sources we recognise
			if (src === 'negQAM') {
				theId = event.getParam("Parameters");

				// If the desired target of this event is not the component responding here, ignore the event
				if (target.get("v.ComponentId") != cmp.get("v.ComponentId")) {
					console.log('IHCard.menuItemClick: event target (' + target.get("v.ComponentId") + ') is not the current component (' + cmp.get("v.ComponentId") + '): ignoring event...');
					return;
				}

				// We'll need values from our own component - NOT the cmp passed in (which is the negotiating tool bar)
				// So: retrieve the target / reference the negotiator passed in
				cmp = target;

			} else {
				return;
			}

		} catch (e) {
			// Hitting error trap means event was fired directly from component tool click, NOT negotiated pass-through
			theId = event.currentTarget.id;
		}


		var D1 = cmp.get('v.Delimiter');
		var CRoot = cmp.get('v.CommunityRoot');

		// If root is 'null', this can be ignored in most cases
		if (CRoot + '' == 'null') { CRoot = ''; }
		if (CRoot != '') { CRoot = '/' + CRoot; }


		var showInPlace = false;
		var globalId = cmp.getGlobalId();
		var cnt = document.getElementById(globalId + 'CalloutContainer');
		var frm = document.getElementById(globalId + 'tfrm');


		// Re-set diagnostics
		helper.clearAdvancedDiags(cmp);
		helper.logAdvancedDiags(cmp, 'IHCard.menuItemClick - entry');


		// Click "message" (the id of the clickable) is in the form:
		// [Menu (tool) type] [Delimiter] [Action code] [Delimiter] [Display Order] [Delimiter] [Toggle Next #]

		// Regardless of the action a click is to fire, we should respond to "chained" / toggling
		// tools. These will have a non-zero "toggle to next tool" value

		try {

			incomingId = theId;
			theId = theId.split(D1);

			if (theId[3] != '0') {

				// We need to hide the clicked item and un-hide its "next"
				var c1id = cmp.get('v.ToolContext') + D1 + theId[0] + D1 + theId[2] + D1 + cmp.get("v.ComponentId");
				var c2id = cmp.get('v.ToolContext') + D1 + theId[0] + D1 + theId[3] + D1 + cmp.get("v.ComponentId");
				var c1;
				var c2;

				// Find the clickables to hide/show: NB - use of 'find' here means we should only affect
				// tools that belong to the component whose item was clicked!
				var clickables = cmp.find('menuClickable');

				if (clickables + '' != 'undefined') {
					clickables.forEach(function (C) {
						if (C.getElement().id == c1id) {
							c1 = C.getElement();
						}
						if (C.getElement().id == c2id) {
							c2 = C.getElement();
						}
					});
				}


				// Classes to apply vary by clickable (tool) type
				if (theId[0] == 'Header') {
					$A.util.removeClass(c1, 'fa-stack');
					$A.util.addClass(c1, 'slds-hide');
					$A.util.addClass(c2, 'fa-stack');
					$A.util.removeClass(c2, 'slds-hide');

				} else if (theId[0] == 'Body') {
					$A.util.addClass(c1, 'slds-hide');
					$A.util.removeClass(c2, 'slds-hide');

				} else {
					$A.util.removeClass(c1, 'toggleOn');
					$A.util.addClass(c1, 'toggleOff');
					$A.util.addClass(c2, 'toggleOn');
					$A.util.removeClass(c2, 'toggleOff');
				}

			}

		} catch (e) {
			console.log('IHCard.menuItemClick - error: ' + e);
		}


		helper.logAdvancedDiags(cmp, 'Incoming action code: ' + theId[1]);


		// Process extension tools here if required
		if (theId[1].toUpperCase().startsWith('EXTENSION^')) {

			// Action code should be in the form: 
			// Extension (fixed, literal text) ^ Implementation class name ^ Action to pass to implementation

			var Args = theId[1].split('^');
			helper.processExtensionAction(cmp, event, helper, Args[1], Args[2], cmp.get("v.IHContext"), cmp.get("v.HelpRecordId"));
			return;
		}


		// If not an extension, continue handling process
		switch (theId[1]) {

			case 'AuthorConfigObject':
			case 'AuthorConfigTopic':
			case 'AuthorConfigTopicPrompted':
			case 'AuthorConfigCG':

				var act = cmp.get("c.logAuthorConfig");
				var Parms;

				if (theId[1] == 'AuthorConfigObject') {
					// If setting an object (eg list in fixed help mode), ask the user the object API name that is desired
					Parms = prompt(helper.Internationalise(cmp, 'MessageEnterObjectName'), '');
					if (Parms == '' || Parms + '' == 'null') { return; }
					Parms = 'sObjectName~' + Parms;

				} else if (theId[1] == 'AuthorConfigTopicPrompted') {
					// If setting topic to one that may not be part of the current context (eg list in tagged items mode), ask for an ID
					Parms = prompt(helper.Internationalise(cmp, 'MessageEnterTopicId'), '');
					if (Parms == '' || Parms + '' == 'null') { return; }
					Parms = 'HelpRecordId~' + Parms;


				} else if (theId[1] == 'AuthorConfigCG') {

					// Saving details of a generated component (eg from position detector in CG role)
					// Obtain the definition from the component generator and save 'as is'
					var CG = cmp.find("theCG");
					if (CG + '' == 'undefined') {
						CG = cmp.getSuper().find("theCG");
					}
					Parms = CG.get("v.ComponentDef");

				} else {
					// Setting config to match the topic currently in the scope of the calling component:
					// The attribute containing this varies by card...

					if (cmp.get("v.IHCardType") == 'Tags') {
						Parms = 'HelpRecordId~' + cmp.get("v.RootNode");
					}
					if (cmp.get("v.IHCardType") == 'Tree') {
						Parms = 'HelpRecordId~' + cmp.get("v.RootNode");
					}
					if (cmp.get("v.IHCardType") == 'Detail') {
						Parms = 'HelpRecordId~' + cmp.get("v.HelpRecordId");
					}
				}

				act.setParams({
					"ComponentId": cmp.get("v.ComponentId"),
					"Params": Parms,
				});

				// Add callback to show returned results
				act.setCallback(helper, function (response, cmp) {
					if (response.getReturnValue() == '') {
						helper.doNudge(cmp, helper.Internationalise(cmp, 'MessageGenericTaskComplete'), helper.Internationalise(cmp, 'MessageRefreshForChangesManual'), 5000);

					} else {
						alert(helper.Internationalise(cmp, 'MessageGenericError') + ': ' + response.getReturnValue());
					}
				});

				// Send action
				$A.enqueueAction(act);
				break;

			case 'AddBookmark':
			case 'RemoveBookmark':
				helper.showSpinner(cmp);

				var act;

				if (theId[1] == 'AddBookmark') {
					act = cmp.get("c.addBookmark");
				} else {
					act = cmp.get("c.removeBookmark");
				}

				act.setParams({
					"ToolContext": cmp.get("v.ToolContext"),
					"ActionCode": cmp.get("v.ActionCode"),
					"IHContext": cmp.get("v.recordId"),
					"Params": cmp.get("v.HelpRecordId")
				});

				// Add callback to show returned results
				act.setCallback(helper, function (response, cmp) {
					helper.processTools(response, cmp);
				});

				// Send action
				$A.enqueueAction(act);
				break;

			case 'AllHelp':
			case 'AllRelatedHelp':
			case 'AllResources':
			case 'Guides':
			case 'HelpBookmarks':
			case 'HelpComments':
			case 'PopularHelp':
			case 'QuickLinks':
			case 'ReadingLists':
			case 'RefreshHelpList':
			case 'Search':
			case 'Stickies':

				var parms;
				var i;

				// In these cases, we're changing the list (server call)
				// so show our "waiting" cues...
				helper.showSpinner(cmp);


				if (theId[1] == 'RefreshHelpList') {
					// Treat refresh requests same as view all Help:
					// CF: IHList - RefreshCurrentList: the action handled here only re-gets
					// the help for the existing context, whereas RefreshCurrentList results in 
					// a complete component re-build, context establishment included...

					theId[1] = 'AllHelp';
				}

				// Retention of "selected" marker for listing rows varies by action
				if (theId[1] == 'Stickies') {
					cmp.set("v.RetainSelectionOnScroll", true);
				} else {
					// Don't override any specific setting to the contrary
					if (cmp.get("v.RetainSelectionOnScroll") != true) {
						cmp.set("v.RetainSelectionOnScroll", false);
					}
				}


				// Re-set (clear) UI filter
				cmp.set('v.UIFilter', 'AllHelp');

				// Set card title as this too should change with list type
				cmp.set("v.Title", helper.Internationalise(cmp, 'Title' + theId[1]));

				// Obtain search parameters, where relevant
				if (theId[1] == 'Search') {

					parms = helper.getHeaderSupportControlValue(cmp, helper, theId[1]);

					// Require at least a single character before conducting a search
					if (parms == '') {
						cmp.set("v.Diags", helper.Internationalise(cmp, 'TipInputTextbox'));
						helper.hideSpinner(cmp);
						return;
					}

					// Topic searches only: add any "retained" (selected) search results to this list and our collection of "selected" rows
					// NOTE: act of toggling a selector and / or re-setting selections on load will have set this
					parms += cmp.get("v.Delimiter");
					parms += cmp.get("v.ListingSelections");

				}


				// If showing all help, set listing row display parameters
				if (theId[1] == 'AllHelp') {
					parms = cmp.get("v.RowLabellingOption");
				}

				// Call action to get required listing
				var act = cmp.get("c.getTools");
				cmp.set("v.ActionCode", theId[1]);


				// Set card config to action in certain cases
				if (theId[1] == 'AllHelp'
					|| theId[1] == 'HelpBookmarks'
					|| theId[1] == 'HelpComments'
					|| theId[1] == 'PopularHelp'
					|| theId[1] == 'QuickLinks'
					|| theId[1] == 'ReadingLists'
					|| theId[1] == 'Search'
					|| theId[1] == 'Stickies'
				) {
					cmp.set("v.CardConfig", theId[1]);
				}

				act.setParams({
					"ToolContext": cmp.get("v.ToolContext"),
					"ActionCode": theId[1],
					"IHContext": cmp.get("v.recordId"),
					"ClientComponentId": cmp.get("v.ComponentId"),
					"Params": parms,
					"SkipGlobals": false,
				});

				// Add callback to process returned results
				act.setCallback(helper, function (response, cmp) {
					helper.processTools(response, cmp);

					// Having got the desired list, log a LUX List interaction       
					helper.logListType(cmp, event, helper, theId[1]);
				});

				// Send action
				helper.logAdvancedDiags(cmp, 'Firing getTools');
				$A.enqueueAction(act);
				break;


			case 'SearchResources':
			case 'SearchRelatedHelp':
				// A list has been asked to conduct a search of one kind or another
				var searchTerm = helper.getHeaderSupportControlValue(cmp, helper, theId[1]);

				// Require at least a single character before conducting a search
				if (searchTerm == '') {
					cmp.set("v.Diags", helper.Internationalise(cmp, 'TipInputTextbox'));
					helper.hideSpinner(cmp);
					return;
				}

				// Take note of the search term that was used
				cmp.set("v.theVote", searchTerm);

				// In these cases, we're changing the list (server call)
				// so show our "waiting" cues...
				helper.showSpinner(cmp);

				var act = cmp.get("c.getTools");

				act.setParams({
					"ToolContext": cmp.get("v.ToolContext"),
					"ActionCode": theId[1],
					"IHContext": cmp.get("v.IHContext"),
					"ClientComponentId": cmp.get("v.ComponentId"),
					"Params": searchTerm,
					"SkipGlobals": false,
				});

				// Add callback to process returned results
				act.setCallback(helper, function (response, cmp) {
					helper.processTools(response, cmp);
				});

				// Send action
				helper.logAdvancedDiags(cmp, 'Firing getTools');
				$A.enqueueAction(act);

				break;

			case 'ButtonHelp':
			case 'CustomLinkHelp':
			case 'FieldHelp':
			case 'PageHelpLinkHelp':
				// In these cases, we want to hide all but the type representing the clicked menu item
				// To do this, we set member data that children will inherit and can use
				// to show / hide items as required
				cmp.set('v.UIFilter', theId[1]);

				// Re-label the card 
				cmp.set("v.Title", helper.Internationalise(cmp, 'Title' + theId[1]));
				cmp.set("v.Diags", helper.Internationalise(cmp, 'AdviceLabelFilteredTo') + ': ' + helper.Internationalise(cmp, 'ToolLabel' + theId[1]));

				break;

			case 'CardGrow':
				// Nudge height of a card up
				var H = cmp.get("v.Height");

				// Only allowed for pixel (not %) heights
				if (cmp.get("v.Height") != -1) {
					cmp.set("v.Height", parseInt(H) + 25);
					break;
				}

			case 'CardShrink':
				// Nudge height of a card down - subject to a minimum height
				if (cmp.get("v.Height") - 25 > 85) {
					cmp.set("v.Height", cmp.get("v.Height") - 25);
				}
				break;

			case 'Comment':
				var src;
				var cxt = cmp.get("v.ToolContext");

				if (cxt == 'QAM') {
					// QAM comment can only be at page layout level
					var objId = cmp.get('v.recordId');
					objId = objId.substring(0, 3);
					src = CRoot + "/apex/iahelp__IHComment?IHLUX=true&PL=" + objId;

				} else if (cxt == 'RLViewer') {
					// Reading list comments
					src = CRoot + "/apex/iahelp__IHComment?IHLUX=true&RLID=" + cmp.get("v.IHContext");

				} else {
					// If on any other card etc., assume we're commenting on a record (topic)
					src = CRoot + "/apex/iahelp__IHComment?IHLUX=true&HTID=" + cmp.get("v.HelpRecordId");

				}

				//helper.doDialogue('LogComment', 'VF', src, null, 150, false, false, false, cmp, true);
				var srcComponent = 'c:IHComment';
				var aMap = {
					"GenRecordId": src,
				};

				helper.doDialogue('LogComment', 'LUX', srcComponent, aMap, 100, false, true, false, cmp, true);
				break;

			case 'GlobalSettings':
				window.open(CRoot + '/apex/iahelp__IHManageSettings');
				break;

			case 'HelpEnableMode':
				// We know our object context, so we should be able to 
				// list object's field names and labels, comparing against 
				// things that are already helped

				var src = 'c:IHList';
				var aMap = {
					"SuppressHeader": "true",
					"Height": 495,
					"ComponentId": "theHelpEnableModeList",
					"Parent": cmp,
					"CardConfig": "HelpEnableMode",
					"IHContext": cmp.get('v.recordId'),
					"sObjectName": cmp.get('v.sObjectName')
				};

				helper.doDialogue('HelpEnableMode', 'LUX', src, aMap, 500, false, false, false, cmp, true);

				break;

			case 'HelpEnableModeCancel':
				// Close dialogue           	
				var appEvent = $A.get("e.c:evtPassThrough");
				appEvent.setParams({ "SourceComponent": cmp.get("v.ComponentId") });
				appEvent.setParams({ "ActionCode": "DialogueRequestClose" });
				appEvent.setParams({ "Parameters": 'ModalContainer' });
				appEvent.fire();

				break;

			case 'HelpEnableModeSave':
				// Get elements marked for creation / deletion
				var eCreate = document.getElementsByClassName('TBHelped');
				var eDelete = document.getElementsByClassName('TBUnhelped');
				var ElemsToCreate = '';
				var ElemsToDelete = '';
				var i;
				var theId;

				// Loop around elements marked for creation / deletion
				// and add their details to delimited string parameters
				for (i = 0; i < eCreate.length; i++) {
					theId = eCreate[i].id.split(D1);
					ElemsToCreate += theId[0] + D1;
				}

				for (i = 0; i < eDelete.length; i++) {
					theId = eDelete[i].id.split(D1);
					ElemsToDelete += theId[0] + D1;
				}

				helper.showSpinner(cmp);

				// Cue save action with these parameters
				var act = cmp.get("c.SaveHEChanges");
				cmp.set("v.ActionCode", 'AllHelp');
				act.setParams({
					"IHContext": cmp.get("v.IHContext"),
					"ElemsToCreate": ElemsToCreate,
					"ElemsToDelete": ElemsToDelete,
					"Delimiter": D1
				});


				// Add callback to close dialogue having saved
				act.setCallback(helper, function (response, cmp) {
					var appEvent = $A.get("e.c:evtPassThrough");
					appEvent.setParams({ "SourceComponent": cmp.get("v.ComponentId") });
					appEvent.setParams({ "ActionCode": "DialogueRequestClose" });
					appEvent.setParams({ "Parameters": 'ModalContainer' });
					appEvent.fire();


					// Also, re-set the list of available help topics, if present
					var QAMList = cmp.get("v.Parent");

					act = QAMList.get("c.getTools");
					QAMList.set("v.ActionCode", "AllHelp");
					QAMList.set("v.CardConfig", "AllHelp");

					act.setParams({
						"ToolContext": QAMList.get("v.ToolContext"),
						"ActionCode": "AllHelp",
						"IHContext": QAMList.get("v.recordId"),
						"ClientComponentId": cmp.get("v.ComponentId"),
						"Params": "",
						"SkipGlobals": false,
					});

					// Add callback to process returned results
					act.setCallback(helper, function (response, QAMList) {
						helper.processTools(response, QAMList);
					});

					// Send list refresh action
					helper.showSpinner(QAMList);
					$A.enqueueAction(act);
				});


				// Send save helped element changes action
				$A.enqueueAction(act);

				break;

			case 'HelpHome':
				// Show help home page
				var defaultTopic = cmp.get("v.GlobalSettings").iahelp__DefaultHelpTopic__c;
				var PortalPage = cmp.get("v.PortalPage");

				if (defaultTopic == '' || defaultTopic == null || CRoot != '') {
					// If default is not available or we're in a community, safest thing to do is to continue with VF option
					window.open(CRoot + '/apex/iahelp__' + PortalPage);

				} else {
					// Where available, use LUX (component) override
					window.open(CRoot + '/' + defaultTopic);
				}

				break;

			case 'NVShowRecorder':
				// Cue NV video recorder (soft coupling / requires installation of NV app)

				var CTool = helper.getConfigToolForAction(cmp, 'Ellipsis', theId[1]);
				var STools;
				var NVParams;
				var RecorderParams;

				if (CTool != null) {

					// Obtain complete parameter string from config items and detokenize
					STools = helper.deTokenize(cmp, CTool.iahelp__SupportingControls__c);

					// Params will be in the form:
					/*
						Playback VF page path ^ 
						Playback page params ^ 
						Video width for Topic ^ 
						Video height for Topic ^ 
						Recorder component namespace ^ 
						Recorder component name ~ 
						Recorder params
					*/

					// ... with Recorder Parameters similar to a wizard component, i.e.:
					// Parameter ¬ Value |

					STools = STools.split('~');
					NVParams = STools[0].split('^');
					RecorderParams = STools[1];

					var U = CRoot + '/apex/iahelp__IHLUXOutHost?NSApp=iahelp&App=appIH';
					U += '&NSComp=' + NVParams[4];
					U += '&Comp=' + NVParams[5];

					RecorderParams = RecorderParams.split('|').join('^').split('¬').join('~');
					U += '&Parms=' + RecorderParams;

					console.log('NV Show Recorder action: ' + U);
					window.open(U, 'NV', 'width=500, height=400, left=250, top=300, menubar=0, resizable=1, status=0, toolbar=0, titlebar=0, location=0');

					// Update current topic's video URL
					var HT = cmp.get("v.CurrentRecord");

					U = NVParams[0];
					U += '?queryObject=iahelp__HelpTopic__c';
					U += '&queryRecordID=' + HT.Id;

					if (NVParams[1] != '') {
						U += '&' + NVParams[1];
					}

					HT.iahelp__VideoURL__c = U;

					// If required, set video width / height
					if (HT.iahelp__VideoWidth__c == 0 && HT.iahelp__VideoHeight__c == 0) {
						HT.iahelp__VideoWidth__c = NVParams[2];
						HT.iahelp__VideoHeight__c = NVParams[3];
					}


					// Save the record immediately: raise a pass-through to do this
					var appEvent = $A.get("e.c:evtPassThrough");
					appEvent.setParams({ "SourceComponent": cmp.get("v.ComponentId") });
					appEvent.setParams({ "ActionCode": 'Save' });
					appEvent.fire();

				} else {
					alert('ERR: configuration details could not be located');
				}

				break;

			case 'NewTopic':
				// Create a new topic then navigate to it:
				// c.f., DropNewTopic action and related helper calls - sadly not quite ideal here...
				var act = cmp.get("c.dropNewTopic");
				var content = "";

				act.setParams({
					"TopicContent": content,
				});

				act.setCallback(this, function (response, cmp) {

					if (response.getState() === "SUCCESS") {
						cmp.set("v.HelpRecordId", response.getReturnValue());

						// On success, open a new window on the new topic, differentiating for communities
						if (CRoot != '') {
							var PortalPage = cmp.get("v.PortalPage");
							window.open(CRoot + '/apex/iahelp__' + PortalPage + '?HTID=' + response.getReturnValue());
						} else {
							window.open(CRoot + '/' + response.getReturnValue());
						}

					} else {
						cmp.set("v.Diags", "ERR!");
					}
				});

				$A.enqueueAction(act);
				break;

			case 'RLExport':
			case 'ListExport':
			case 'TreeExport':
				// We need to send all of the IDs associated with the current (reading) list/tree
				// to the export utility - so it can use these as an export scope: 
				var LIs = cmp.get("v.ListingItems");
				var strScope = '';
				var curRow;

				// For list export, note whether ANY rows are selected
				var selectionCount = $('.IsSelected').length;

				LIs.forEach(function (v) {

					// Precise source of Help Topic ID varies by component type
					if (theId[1] == 'RLExport') {
						// On a reading list viewer, listing item ID is that of an RLE - not the actual HTID
						// that we need - which is in its own member...
						strScope += v.iahelp__HelpTopic__c + ',';

					} else if (theId[1] == 'ListExport') {
						// On a listing, we need to take account of "selections", if made:
						// Selected listing items will have their narrow and wide rows marked as such:
						if ($('#LINarrow_' + v.Id).hasClass('IsSelected') == true || $('#LIWide_' + v.Id).hasClass('IsSelected') == true || selectionCount == 0) {

							// Don't add "broken" element listings (i.e., missing topic)
							if (v.Id + '' != 'null') {
								strScope += v.Id + ',';
							}
						}

					} else {
						// On a tree, it's the ID of the node
						strScope += v.Id + ',';
					}
				})
				if (strScope.length > 0) {
					strScope = strScope.substring(0, strScope.length - 1);
				}

				window.open(CRoot + '/apex/iahelp__IHExportXL?Scope=' + strScope);
				break;

			case 'ReadingListAdd':

				// Add a new readng list (server call) with current topic as its sole entry
				var act = cmp.get("c.addReadingList");
				act.setParams({
					"HTID": cmp.get("v.recordId"),
				});


				// On successful callback, show Utility 1 with Reading List as root                
				act.setCallback(helper, function (response, cmp) {

					var RLID = response.getReturnValue();

					if (RLID.toLowerCase().indexOf('error') == -1) {
						var ttl = helper.Internationalise(cmp, 'TipReadingListAdd');
						var src = 'c:IHUtility1';

						var aMap = {
							"SuppressHeader": false,
							"SuppressFooter": true,
							"TreeSuppressListingTools": false,
							"Height": 520,
							"ComponentId": "theNewRLDialogue",
							"Parent": cmp,
							"ColumnRatio": "33%",
							"RootNode": RLID,
							"ToolContext": "ReadingListBuilder",
							"TreeNodeIconStyle": "Small",
							"MaxListingTools": -1
						};


						// Refresh the listing whose add RL tool was clicked
						cmp.getConcreteComponent().reInitialise();

						// Show RL properties dialogue
						helper.doDialogue(ttl, 'LUX', src, aMap, 540, true, true, false, cmp, false);

					} else {
						alert(RLID);
					}

				});

				$A.enqueueAction(act);
				break;

			case 'NewResourceLink':
				// Create a new resource, link it to the current topic then show a dialogue for the resource

				var act = cmp.get("c.createAndLinkHelpResource");
				act.setParams({
					"HTID": cmp.get("v.IHContext")
				});

				act.setCallback(helper, function (response, cmp) {

					var src = 'c:IHAutoForm';
					var Ttl = 'LinkRelatedResource';
					var rec;
					var isError;

					if (response.getState() == 'SUCCESS') {

						rec = response.getReturnValue();
						isError = rec.indexOf('Error') != -1 || rec == helper.Internationalise(cmp, 'MessageNoRights');

						if (isError == false) {
							// Navigate to the resource that was created and linked

							var aMap = {
								"SuppressHeader": true,
								"SuppressFooter": false,
								"SuppressModeTools": true,
								"SuppressPoweredBy": true,
								"sObjectName": "iahelp__HelpResource__c",
								"LayoutName": "iahelp__HelpResource__c-Help Resource Layout",
								"recordId": rec,
								"DataMode": "Edit",
								"OnSaveAction": "Report only",
								"Height": 600,
								"ComponentId": "theNewRelDialogue",
								"Parent": cmp
							};

							helper.doDialogue(Ttl, 'LUX', src, aMap, 620, false, false, false, cmp, true);

							// Make a note within the dialogue itself of the purpose for which it was summoned
							/*
							try {
								var dlg = cmp.find('theModal');       
								if (dlg + '' == 'undefined') {
										cmp = cmp.getSuper();
										dlg = cmp.find('theModal');
									  
								}	
							
								dlg.set("v.DialogueActionCode", 'NewResourceLink');
								
							} catch (e) {}
							*/

							helper.setDialogueActionCode(cmp, 'NewResourceLink');


						} else {
							// Error creating and linking
							alert(helper.Internationalise(cmp, 'MessageGenericError') + ': ' + rec);
						}

					} else {
						// Error making server call
						alert(helper.Internationalise(cmp, 'MessageGenericError') + ': server call failure');
					}

				});

				// Send action
				$A.enqueueAction(act);


				break;

			case 'SearchHelpTopics':
			//case 'AddReadingListEntries':

				// Show spinner for server call
				helper.showSpinner(cmp);
				
				// Call getTools with new action code
				var act = cmp.get("c.getTools");
				
				act.setParams({
					"ToolContext": cmp.get("v.ToolContext"),
					"ActionCode": "Search",
					"IHContext": cmp.get("v.recordId"),
					"ClientComponentId": cmp.get("v.ComponentId"),
					"Params": '',
					"SkipGlobals": false,
				});
				
				act.setCallback(helper, function (response, cmp) {
					helper.processTools(response, cmp);
					helper.logListType(cmp, event, helper, theId);
				});
				
				$A.enqueueAction(act);
				
				break;

			case 'RelatedHelpLink':
			case 'RelatedResourceLink':
				// Show a modal dialogue allowing user to search for related items and link to the current topic

				var src = 'c:IHList';
				var Ttl;
				var CCfg;
				var TCxt;
				var NDM = helper.Internationalise(cmp, 'AdviceLabelSearchForExistingItem');


				if (theId[1] == 'RelatedHelpLink') {
					Ttl = 'LinkRelatedHelp';
					CCfg = 'SearchRelatedHelp';
					TCxt = 'LinkTopics';

				} else {
					Ttl = 'LinkRelatedResource';
					CCfg = 'SearchResources';
					TCxt = '[DEFAULT]';
				}

				var aMap = {
					"SuppressHeader": false,
					"SuppressFooter": false,
					"SuppressPoweredBy": true,
					"TreeSuppressListingTools": false,
					"Height": 400,
					"CardConfig": CCfg,
					"ToolContext": TCxt,
					"NoDataMessage": NDM,
					"ComponentId": "theNewRelDialogue",
					"IHContext": cmp.get("v.IHContext"),
					"recordId": cmp.get("v.recordId"),
					"Parent": cmp
				};


				helper.setDialogueActionCode(cmp, theId[1]);


				helper.doDialogue(Ttl, 'LUX', src, aMap, 420, false, false, false, cmp, true);

				break;

			case 'ShowLOBuilder':
				// Show the Lightning Out Host in builder mode
				var src = CRoot + "/apex/iahelp__IHLUXOutHost?LOBuilder=true";
				window.open(src);
				break;

			case 'Statistics':
				var src = CRoot + "/apex/iahelp__IHStats?IHLUX=true&HTID=" + cmp.get("v.IHContext");
				helper.doDialogue('Statistics', 'VF', src, null, 145, false, true, false, cmp, true);

				break;

			case 'TaggedHelp':
				// Show items "tagged" for use in the QAM - as per QAM's Listing Tag Filters 
				var act = cmp.get("c.getTools");
				var parms = cmp.get("v.ListingTagFilters");

				helper.showSpinner(cmp);

				cmp.set("v.ActionCode", 'GetTaggedItems');

				act.setParams({
					"ToolContext": cmp.get("v.ToolContext"),
					"ActionCode": cmp.get("v.ActionCode"),
					"IHContext": parms,
					"ClientComponentId": cmp.get("v.ComponentId"),
					"Params": parms,
					"SkipGlobals": false,
				});

				act.setCallback(helper, function (response, cmp) {
					helper.processTools(response, cmp);
				});

				// Send action
				$A.enqueueAction(act);
				break;

			case 'ToggleCardHeader':

				// Toggle header visibility
				cmp.set("v.SuppressHeader", !cmp.get("v.SuppressHeader"));

				// Having done so, we need to re-calculate card body height
				cmp.set("v.H_Header", 0);
				helper.setSizingTimer(cmp, event, helper);
				break;

			case 'ToggleHistory':
				// Show / hide the history navigation area
				helper.toggleHistory(cmp, event, helper);
				break;

			case 'TreeSearch':
				// Filter info should have been placed by logic (see key up handler) into a "filtered" set of nodes:
				// All we need do here is apply this...
				helper.showSpinner(cmp);

				// Straight action here was NOT making spinner visible: timeout
				// seems to be required to force UI update to occur prior to 
				// continuing to process the request...
				window.setTimeout(
					$A.getCallback(function () {

						cmp.set("v.Nodes", cmp.get("v.FilteredNodes"));

						// Matching record count should be in cache, which we use then re-set
						cmp.set("v.Diags", helper.Internationalise(cmp, 'AdviceLabelMatchingItems') + ': ' + cmp.get("v.OpsCache"));
						cmp.set("v.OpsCache", "");

						helper.hideSpinner(cmp);

					}), 100
				);

				break;

			case 'ViewHelpedElements':
				var src = CRoot + "/apex/iahelp__IHSearchResults?IHLUX=true&Opts=6&HTID=" + cmp.get("v.IHContext");
				helper.doDialogue('HelpedElementMaintenance', 'VF', src, null, 400, false, false, false, cmp, true);

				break;

			default:
				// Process extension tools here:
				if (theId[0] === 'Extension') {
					// Not implemented in this release

				} else {
					// Anything we don't handle at super level we should pass through for sub-component handling
					console.log('Option not implemented in SUPER menuItemClick - raising passthrough on behalf of "' + cmp.get("v.ComponentId") + '": Action=' + theId[1]);

					var appEvent = $A.get("e.c:evtPassThrough");
					appEvent.setParams({ "SourceComponent": cmp.get("v.ComponentId") });
					appEvent.setParams({ "ActionCode": theId[1] });
					appEvent.setParams({ "Parameters": incomingId });
					appEvent.fire();
				}
				break;
		}

		// Close menu where relevant
		if (theId[0] == 'Drop-down') {
			helper.toggleDropDownTools(cmp);
		}


		// Hide any callout - unless action has resulted in a callout
		if (showInPlace === true) {
			var y = event.clientY;

			$(cnt).css('top', y + 5);
			$(cnt).css('left', '0px');
			$(cnt).css('width', '100%');

			// (hide momentarily to allow spinner)            
			$A.util.addClass(cnt, 'slds-hide');
			helper.toggleTipBusy(cmp);
			$A.util.removeClass(cnt, 'slds-hide');

		} else {
			// If selected record/context has NOT changed, toggle visibility
			$A.util.addClass(cnt, 'slds-hide');
		}

	},


	// Respond to in-line listing tool clicks
	listingToolClick: function (cmp, event, helper) {

		var lst = event.target;
		var theId = lst.id;
		var D1 = cmp.get('v.Delimiter');
		var CRoot = cmp.get('v.CommunityRoot');
		var globalId = cmp.getGlobalId();
		var cnt = document.getElementById(globalId + 'CalloutContainer');
		var frm = document.getElementById(globalId + 'tfrm');


		// If root is 'null', this can be ignored in most cases
		if (CRoot + '' == 'null') { CRoot = ''; }
		if (CRoot != '') { CRoot = '/' + CRoot; }


		var showInPlace = true;
		var contextualize = false;


		helper.clearAdvancedDiags(cmp);
		helper.logAdvancedDiags(cmp, 'IHCard.listingToolClick - entry');
		console.log('Card - Listing Click: ' + theId);


		// Click "message" (the id of the clickable) is in the form:
		// [Listing record Id] [Delimiter] [Action code] [Delimiter] [Parameters]
		theId = theId.split(D1);


		// Mark selected row - the one against which this click occurred
		helper.setSelectedRow(cmp, theId[0]);


		helper.logAdvancedDiags(cmp, 'Incoming action code: ' + theId[1]);


		// Process extension tools here if required
		if (theId[1].toUpperCase().startsWith('EXTENSION^')) {

			// Action code should be in the form: 
			// Extension (fixed, literal text) ^ Implementation class name ^ Action to pass to implementation

			var Args = theId[1].split('^');
			helper.processExtensionAction(cmp, event, helper, Args[1], Args[2], cmp.get("v.IHContext"), theId[0]);
			return;
		}


		// If not an extension, action to take depends on action code
		switch (theId[1]) {

			case 'AddBookmark':
			case 'RemoveBookmark':


				helper.showSpinner(cmp);
				var act;

				if (theId[1] == 'AddBookmark') {
					act = cmp.get("c.addBookmark");
				} else {
					act = cmp.get("c.removeBookmark");
				}
				console.log('list on click');
				act.setParams({
					"ToolContext": cmp.get("v.ToolContext"),
					"ActionCode": cmp.get("v.ActionCode"),
					"IHContext": cmp.get("v.recordId"),
					"Params": theId[0]

				});

				// Add callback to show returned results
				act.setCallback(helper, function (response, cmp) {
					helper.processTools(response, cmp);
				});

				// Send action
				$A.enqueueAction(act);

				showInPlace = false;
				contextualize = false;
				break;

			case 'ArchiveSticky':
				// Request archival of the current sticky note (i.e., all versions of 
				// stickies for the record to which listing tool is attached)...
				var act = cmp.get("c.archiveSticky");

				act.setParams({
					"IHContext": theId[2]
				});

				// Add callback to show returned results
				act.setCallback(helper, function (response, cmp) {

					// We should expect an empty response if successful
					if (response.getState() != 'SUCCESS') {
						cmp.set("v.Diags", "ERR!");
					} else if (response.getReturnValue() != '') {
						cmp.set("v.Diags", "Error (Archive Sticky): " + response.getReturnValue());
					} else {
						// Re-load list
						cmp.set("v.isInitialised", false);
					}

				});

				// Send action
				$A.enqueueAction(act);

				showInPlace = false;
				contextualize = false;
				break;

			case 'Comment':
				// For listings, by definition assume we're commenting on a record (topic)

				var src = CRoot + "/apex/iahelp__IHComment?IHLUX=true&HTID=" + theId[0];

				//helper.doDialogue('LogComment', 'VF', src, null, 150, false, false, false, cmp, true);

				var srcComponent = 'c:IHComment';
				var aMap = {
					"GenRecordId": src,
				};

				helper.doDialogue('LogComment', 'LUX', srcComponent, aMap, 100, false, true, false, cmp, true);

				showInPlace = false;
				contextualize = false;
				break;

			case 'ConfigurationMode':
			case 'ConfigurationIssue':

				var params = theId[2].split('^');
				var src;
				var D1 = '^';

				// v`.44+ : replacing VF dialogue with Utility 1 based approach

				if (theId[1] == 'ConfigurationMode') {
					// In these cases, the listing item parameters provide element as part of standard help info, i.e:
					// [Callout height] ^ [Callout template URL] ^ [Element identifier] ^ [HPL]

					src = params[3] + D1 + params[2];

				} else {
					// In these cases, the listing item parameters provide failed element info in the form:
					// [Element identifier] ^ [HPL]

					src = params[1] + D1 + params[0];
				}

				var dlgMap = {
					"PDPositioningGroup": cmp.get("v.ComponentId") + '_ReconDlg',
					"Height": 595,
					"ColumnRatio": "33%",
					"SuppressHeaders": true,
					"SuppressFooters": true,
					"ToolContext": "ReconfigureMode",
					"RootNode": src,
					"TreeSuppressListingTools": false,
					"TreeNodeIconStyle": "Small",
					"TreeNodeProvider": "ServiceIHTrees.TNSHelpedPageLayouts"
				};

				helper.doDialogue('HelpedElementMaintenance', 'LUX', 'c:IHUtility1', dlgMap, 600, false, true, false, cmp, true);

				showInPlace = false;
				contextualize = false;
				break;

			case 'EditTopic':
			case 'ViewHere':
				// View full topic or edit it (i.e., show topic in the detail card in appropriate mode)

				var theMode;
				if (theId[1] == 'EditTopic') { theMode = 'Edit' } else { theMode = 'View' }

				var src = 'c:IHDetail';
				var aMap = {
					"HelpRecordId": theId[0],
					"DataMode": theMode,
					"Height": "610"
				};
				helper.doDialogue('EditTopic', 'LUX', src, aMap, 600, false, true, false, cmp, true);

				showInPlace = false;
				contextualize = false;
				break;

			case 'HelpBookmark':
			case 'DisambiguationItem':
				// NB: With bookmarks, Listing Record Id (theId[0]) is Help Topic ID.
				// Parameters (theId[2]) is the bookmark URL...
				if (theId[2] == "" & theId[0] != "") {
					var topicurl = 'https://' + window.location.hostname + '/' + theId[0];
					document.location = topicurl;
				}
				else {
					window.open(theId[2]);
					showInPlace = false;
					contextualize = true;
				}
				break;

			case 'TagClick':
			case 'HelpCallout':
				// NOTE: clicking a tag (in a list, in "tagged items" mode) is essentially the same as showing a callout
				// in cases where a callout is desired (i.e., list's callout option calls for this)
				var calloutOpt;
				var params;
				var Pg;

				// Differentiate communities use of LUX override for now
				var LXC = (CRoot == '') + '';


				// In these cases, the listing item parameters should provide callout info in the form:
				// [Callout height] ^ [Callout template URL] ^ [Element identifier] ^ [HPL] ^ [Element Id]
				try {
					params = theId[2].split('^');

					// Deal with "local" custom templates: with these, we need to remove the "c."
					// namespace (required in classic): see also jsToggleHelp.getTemplateAddress
					Pg = params[1];

					if (Pg.indexOf('.') != -1) {
						Pg = Pg.split('.');
						Pg = Pg[1];
					}

					// If we get here, all is well so we can respond to desired callout option
					calloutOpt = cmp.get("v.CalloutOption");

				} catch (e) {
					// We can only offer callouts where suitable parameters (per the above) have been supplied:
					// If this is not the case, our options are limited...
					// All we can do is use a redirect to arrange for the correct callout - but not properly sized
					if (cmp.get("v.ToolContext") == 'QAM' || cmp.get("v.CalloutOption") == 'Topic Selected Event plus Topic view') {

						// Note that lists of tagged items use Help Record to set tag pool, so
						// the topic clicked / shown in callout is recorded separately in tag record member...
						if ((theId[1] != 'TagClick' && cmp.get("v.HelpRecordId") != theId[0]) || (theId[1] == 'TagClick' && cmp.get("v.TagRecordId") != theId[0])) {


							// We should still have callout height (we hope)
							params = theId[2];
							if (!isNaN(parseInt(params))) {
								$(cnt).css('height', parseInt(params) + 5);
								$(frm).css('height', parseInt(params));
							}

							frm.src = CRoot + "/apex/iahelp__IHRedirector?LUXCaller=" + LXC + "&HTID=" + theId[0] + "&ShowCallout=true";
						}

						contextualize = true;
						break;

					} else {
						// Outwith the QAM, or if a popup callout or no callout was requested, revert to that option
						calloutOpt = 'Topic Selected Event Only';
					}
				}


				switch (calloutOpt) {
					case "Topic Selected Event plus Topic view":

						showInPlace = true;

						$(cnt).css('height', parseInt(params[0]) + 5);
						$(frm).css('height', parseInt(params[0]));

						// Only set frame source if path has actually changed:
						// Note that certain cases (tagged items) will have dealt with callout above
						if (cmp.get("v.HelpRecordId") != theId[0]) {

							// Use Element identifier + HPL to cue topic (as opposed to HTID, which would also work)
							// as this is required to log a callout interaction.
							// Do NOT force LUX look & feel here: it's not essential (as it is with certain otherwise ugly dialogues)
							// and should more logically respond to branding settings

							// Differentiate appearance for callouts from QAM listings, which should fold out to the left / nubbin right
							if (cmp.get("v.ComponentId") == 'theQAM') {
								frm.src = CRoot + "/apex/" + Pg + "?LUXCaller=" + LXC + "&elemType=R&ElemId=" + encodeURI(params[2]) + '&HPL=' + params[3] + '&ActiveId=' + params[4];
							} else {
								frm.src = CRoot + "/apex/" + Pg + "?LUXCaller=" + LXC + "&elemType=T0&ElemId=" + encodeURI(params[2]) + '&HPL=' + params[3] + '&ActiveId=' + params[4];
							}
						}

						break;

					case "Topic Selected Event plus Topic popout":
						// Open selected topic's callout in a popup window
						showInPlace = false;
						var U = CRoot + "/apex/" + Pg + "?LUXCaller=" + LXC + "&ElemId=" + encodeURI(params[2]) + '&HPL=' + params[3] + '&ActiveId=' + params[4];
						window.open(U, 'HelpCallout', 'width=500, height=' + params[0] + ', left=250, top=300, menubar=0, resizable=1, status=0, toolbar=0, titlebar=0, location=0');

						break;

					case "Topic Selected Event Only":
						showInPlace = false;
						break;
				}

				contextualize = true;
				break;

			case 'HelpedElementAdd':
			case 'HelpedElementDelete':
				var elemClass;
				var rowClass;

				if (theId[1] == 'HelpedElementAdd') { elemClass = 'TBHelped'; } else { elemClass = 'TBUnhelped'; }
				if (theId[1] == 'HelpedElementAdd') { rowClass = 'ToBeHelped'; } else { rowClass = 'ToBeUnhelped'; }

				// Mark item to be helped / unhelped and style its row
				$A.util.toggleClass(lst, elemClass);
				$('li').removeClass(rowClass);
				$('li:has(.' + elemClass + ')').addClass(rowClass);

				// Show tally of items to be helped / unhelped
				cmp.set('v.Diags', helper.Internationalise(cmp, 'TitleSubtitleCreatingElements') + ': ' + $('li.ToBeHelped').length + ' - ' + helper.Internationalise(cmp, 'TitleSubtitleDeletingElements') + ': ' + $('li.ToBeUnhelped').length);

				showInPlace = false;
				contextualize = false;
				break;

			case 'OpenContextRecord':
				// Open the Salesforce record associated with the clicked listing in a new tab
				var sObectEvent = $A.get("e.force:navigateToSObject");
				sObectEvent.setParams({
					"recordId": theId[2],
					"slideDevName": "detail"
				});
				sObectEvent.fire();

				showInPlace = false;
				contextualize = false;
				break;

			case 'QuickLink':
				window.open(theId[0]);
				showInPlace = false;
				contextualize = false;
				break;

			case 'RLDelete':
				// Delete the reading list whose tool was clicked
				var proceed = false;
				proceed = confirm(helper.Internationalise(cmp, 'MessageDeleteWarning'));

				if (proceed == true) {

					var act = cmp.get("c.deleteReadingList");
					act.setParams({
						"RLID": theId[0]
					});

					// Add callback to process returned results
					act.setCallback(this, function (response, cmp) {

						// On completion, force re-initialise of guide listing if successful and report any diagnostics
						if (response.getState() == 'SUCCESS') {
							alert(helper.Internationalise(cmp, 'MessageGenericTaskComplete'));

							// This is the result of a listing tool click: with entry deleted,
							// we should refrsh the listing
							cmp.reInitialise();

						} else {
							alert(helper.Internationalise(cmp, 'MessageGenericError'));
						}
					});
					$A.enqueueAction(act);

				}
				break;

			case 'ReadingList':
				// Respond according to callout options set for component BUT
				// also respect the override in these cases
				if (cmp.get("v.CalloutOption") === "Topic Selected Event plus Topic view"
					&& cmp.get("v.CalloutOptionSelectiveOverride") === false) {

					var src = 'c:IHRLViewer';
					var aMap = {
						"HelpRecordId": theId[0],
						"ActionCode": 'ReadingListEntries',
						"ToolContext": 'RLViewer',
						"Height": '640'
					};
					helper.doDialogue('ReadingListViewer', 'LUX', src, aMap, 620, false, false, false, cmp, true);

				}

				// Regardless of callout, DO contextualise (i.e., issue a record select event)
				showInPlace = false;
				contextualize = true;
				break;

			case 'ReadingListDialogue':
				// OBSOLESCENT - USE ReadingList action where possible  
				// As 'ReadingList' action - but forced into VF / iframed dialogue for use in LUXOut which does NOT seem able to 
				// create modals with instantiated components
				var src = CRoot + '/apex/iahelp__IHLUXOutHost?NSApp=iahelp&App=appIH&NSComp=iahelp&Comp=IHRLViewer&Parms=Height~620^HelpRecordId~' + theId[0];
				helper.doDialogue('ReadingListViewer', 'VF', src, null, 620, false, false, false, cmp, true);

				showInPlace = false;
				contextualize = false;
				break;

			case 'ReadingListProperties':
				// Show RL properties dialogue
				var ttl = theId[2];
				var src = 'c:IHUtility1';
				var aMap = {
					"SuppressHeaders": false,
					"SuppressFooters": true,
					"ColumnRatio": "40%",
					"TreeSuppressListingTools": false,
					"TreeDisplayDensity": "Compact",
					"TreeNodeIconStyle": "Small",
					"TreeMaxListingTools": 0,
					"TreeNodeProvider": "ServiceIHTrees.TNSReadingLists",
					"TreeDDAllowed": true,
					"RootNode": theId[0],
					"ToolContext": 'ReadingListBuilder',
					"Height": '560',
					"PDPositioningGroup": "RLPropsU1"
				};

				helper.doDialogue(ttl, 'LUX', src, aMap, 550, true, true, false, cmp, false);

				helper.setDialogueActionCode(cmp, 'ReadingListProperties');


				showInPlace = false;
				contextualize = false;
				break;

			case 'RelatedHelp':
				// Page author can choose whether or not to pop topic to new tab:
				if (cmp.get("v.CalloutOption") === "Topic Selected Event plus Topic view") {
					var PortalPage = cmp.get("v.PortalPage");

					// Differentiate for communities for now
					if (CRoot != '') {
						window.open(CRoot + "/apex/iahelp__" + PortalPage + "?HTID=" + theId[0]);
					} else {
						window.open(CRoot + "/" + theId[0]);
					}
				}

				showInPlace = false;
				contextualize = true;
				break;

			case 'RelatedHelpUnlink':
				if (confirm(helper.Internationalise(cmp, 'MessageDeleteWarning'))) {

					helper.showSpinner(cmp);

					// Our listing does NOT contain the relationship ID - as we're generally interested in the
					// ID of the referenced Topic (as we use this to raise selection events etc.). HOWEVER: this
					// means we need to be sure, in deleting a relationship, that we get the right one! This means
					// getting referring / related IDs round the right way in this case (as there could be 2x "relative"
					// relationships, 1 in each "direction"). 
					// Parameters in listing items are the marker we have defining this:

					var rel;
					var ref;
					var RType = theId[2];

					if (RType == 'REF') {
						// Listing parameter is the referring topic
						rel = cmp.get("v.IHContext");
						ref = theId[0];

					} else {
						rel = theId[0];
						ref = cmp.get("v.IHContext");
					}

					var act = cmp.get("c.deleteRelationship");
					act.setParams({
						"Referring": ref,
						"Related": rel,
						"RelationType": "Relative"
					});

					act.setCallback(this, function (response, cmp) {

						// Remove waiting cues
						helper.hideSpinner(cmp);

						if (response.getState() === "SUCCESS") {

							// (Momentarily) note return in Diags then 
							// re-build list here to reflect removed relative
							cmp.set("v.Diags", helper.Internationalise(cmp, response.getReturnValue()));

							// Reset to the context of the related help topic here
							cmp.set("v.HelpRecordId", '');

							cmp.reInitialise(cmp, event, helper);

						} else {
							cmp.set("v.Diags", "ERR!");
						}
					});

					// Send action
					$A.enqueueAction(act);
				}

				showInPlace = false;
				contextualize = false;
				break;

			case 'RelatedResourceNotes':
				// Open SF standard record editing page for current help topic resource:
				window.open(CRoot + "/" + theId[0] + '/e');
				showInPlace = false;
				contextualize = false;
				break;

			case 'RelatedResourceUnlink':
				if (confirm(helper.Internationalise(cmp, 'MessageDeleteWarning'))) {

					var act = cmp.get("c.deleteHelpTopicResource");
					act.setParams({
						"HTRID": theId[0]
					});

					act.setCallback(this, function (response, cmp) {

						// Remove waiting cues
						helper.hideSpinner(cmp);

						if (response.getState() === "SUCCESS") {

							// (Momentarily) note return in Diags then 
							// re-build list here to reflect removed relative
							cmp.set("v.Diags", helper.Internationalise(cmp, response.getReturnValue()));

							// Reset to the context of the related help topic here
							cmp.set("v.HelpRecordId", '');
							cmp.reInitialise(cmp, event, helper);

						} else {
							cmp.set("v.Diags", "ERR!");
						}
					});

					// Send action
					$A.enqueueAction(act);
				}

				showInPlace = false;
				contextualize = false;
				break;

			case 'Resource':
				window.open(helper.deTokenize(cmp, theId[2]));
				showInPlace = false;
				contextualize = false;

				
				//cmp.find("geoLocation").getCurrentLocation().then((location) => {
					//console.log('position IN Aura latitude ', location.latitude);
					//console.log('position IN Aura longitude ', location.longitude);
					//console.log('position IN Aura altitude ', location.altitude);
					//console.log('position IN Aura accuracy ', location.accuracy);

					//For passing the location coordinates through the pre defined "logLUXInteraction" perameters
					//I am adding the coordinates in key value format to the end of the "IHContext" with a
					//delimeter 'String.fromCharCode(7)'{A unprintable delemeter} which will be then split out when
					//pass to the server method to take out the coordinates and the remaining string will be
					//work as it is previously functioning.

					//var D7 = String.fromCharCode(7);
					//var position = { "latitude": location.latitude, "longitude": location.longitude, "altitude": location.altitude, "accuracy": location.accuracy };


					// Log a resource interaction
					//var act = cmp.get("c.logLUXInteraction");
					
					/*
                var desc = 'Resource "' + theId[0] + '" was viewed from component "' + cmp.get("v.ComponentId") + '" with destination ' + helper.deTokenize(cmp, theId[2]);
                var rec;
                var ihContext = rec + '^' + theId[0];
					rec = cmp.get("v.recordId");
					if (rec == null || rec + '' == 'null') { rec = cmp.get("v.HelpRecordId"); }
		*/
     var escapedId = theId[0];
    var destination = helper.deTokenize(cmp, theId[2]);
	 var desc = `Resource "${escapedId}" was viewed from component "${cmp.get("v.ComponentId")}" with destination ${destination}`;

	console.log('desc==>'+desc);
   var rec = cmp.get("v.recordId");
    if (rec == null || rec + '' == 'null') {
        rec = cmp.get("v.HelpRecordId");
    }
	console.log('ihContext *****');
    var ihContext = `${rec}^${escapedId}`;
	console.log('ihContext *****'+ihContext);

    // Use JSON.stringify to ensure proper escaping
    //desc = JSON.stringify(desc);
                
                
					/*act.setParams({
						"iTyp": "6",
						"Description": desc,
						"IHContext": rec + '^' + theId[0],
					});*/

					// Send action
					//$A.enqueueAction(act);
                     
                     // Log a resource interaction
                     helper.logLUXInteractions(cmp, 6, desc, ihContext).then((response) => {
						//do nothing to response.
					});
				//});
				// // Log a resource interaction
				// var act = cmp.get("c.logLUXInteraction");
				// var desc = 'Resource "' + theId[0] + '" was viewed from component "' + cmp.get("v.ComponentId") + '" with destination ' + helper.deTokenize(cmp, theId[2]);
				// var rec;

				// rec = cmp.get("v.recordId");				
				// if (rec == null || rec + '' == 'null') {rec = cmp.get("v.HelpRecordId");}

				// act.setParams({ 
				// 	"iTyp" : "6",
				// 	"Description" : desc,
				// 	"IHContext" : rec + '^' + theId[0],
				// });                               

				// // Send action
				// $A.enqueueAction(act);

				break;

			case 'SelectTree':
				// Act effectively as tree selector control would
				var provider = '';

				var appEvent = $A.get("e.c:evtPassThrough");
				appEvent.setParams({ "SourceComponent": cmp.get('v.ComponentId') });
				appEvent.setParams({ "ActionCode": "SelectTree" });
				appEvent.setParams({ "Parameters": theId[0] + '^' + provider });
				appEvent.fire();

				break;

			case 'Statistics':
				var src = CRoot + "/apex/iahelp__IHStats?IHLUX=true&HTID=" + theId[0];
				helper.doDialogue('Statistics', 'VF', src, null, 145, false, true, false, cmp, true);

				showInPlace = false;
				contextualize = false;
				break;

			case 'ToggleListingTools':
				// Toggle in-line list tool visibility: listing record ID can be used to identify tools block
				helper.toggleListingTools(cmp, theId[0]);

				showInPlace = false;
				contextualize = false;
				break;

			case 'ToggleSelected':
				// Mark the list row whose tool cued this action as among the collection of those "selected"
				var LI;
				console.log('Toggle selected row: ' + theId[0]);
				LI = document.getElementById('LINarrow_' + theId[0]);
				$A.util.toggleClass(LI, 'IsSelected');
				LI = document.getElementById('LIWide_' + theId[0]);
				$A.util.toggleClass(LI, 'IsSelected');

				// If there are any selected rows, show this on any tools that respond to selections
				helper.markSelectionControlledTools(cmp);

				showInPlace = false;
				contextualize = false;
				break;

			case 'ViewGuideInPortal':
				// Given the RLID of a Guide in a list, open it in properties viewer
				window.open(CRoot + "/apex/iahelp__IHReadingListProperties?Id=" + theId[0]);
				showInPlace = false;
				contextualize = true;
				break;

			case 'ViewInPortal':

				// If we're NOT in the QAM, show the topic on the layout we're on
				if (cmp.get("v.ToolContext") != 'QAM') {

					// To do this, we will simply issue the contextualise message, below,
					// and will NOT open a new window here. However, we must also re-set
					// the action code of the (listing we assume) that issued the view in portal
					// (search listing item click)

					cmp.set("v.ActionCode", "AllRelatedHelp");
					cmp.set("v.Title", helper.Internationalise(cmp, 'Title' + cmp.get('v.ActionCode')));

				} else {

					// If in the QAM, given the HTID of a Topic in a list, open it in portal
					if (CRoot != '') {
						// If we're in a community, safest thing to do is to continue with VF option
						var PortalPage = cmp.get("v.PortalPage");
						window.open(CRoot + "/apex/iahelp__" + PortalPage + "?HTID=" + theId[0]);

					} else {
						// Where available, use LUX (component) override
						window.open(CRoot + '/' + theId[0]);
					}
				}

				showInPlace = false;
				contextualize = true;
				break;

			default:
				console.log(' theId', theId[2]);
				console.log('Option not implemented in SUPER listingToolClick - raising passthrough on behalf of "' + cmp.get("v.ComponentId") + '": Listing Id=' + theId[0] + ': Action=' + theId[1] + ': Parameters=' + theId[0] + '^' + theId[2]);

				// Anything we don't handle at super level we should pass through for sub-component handling
				var appEvent = $A.get("e.c:evtPassThrough");
				appEvent.setParams({ "SourceComponent": cmp.get("v.ComponentId") });
				appEvent.setParams({ "ActionCode": theId[1] });
				appEvent.setParams({ "Parameters": theId[0] + '^' + theId[2] });
				appEvent.fire();

				showInPlace = false;
				contextualize = false;
				break;
		}


		// Having set any required parameters above, show an in-place callout / dialogue if required
		if (showInPlace === true) {
			var y = event.clientY;

			// Differentiate appearance for callouts from QAM listings, which should fold out to the left / nubbin right
			if (cmp.get("v.ComponentId") == 'theQAM') {
				var CB = document.getElementById(globalId + 'CardBody');
				var w = $(CB).css('width');
				var h = $(frm).css('height');

				$(cnt).css('width', '55%');
				$(cnt).css('right', parseInt(w) + 20);


				h = h.replace('px', '');
				h = parseInt(h);
				h = h * 0.5;
				$(cnt).css('top', y - h + 5);

			} else {
				$(cnt).css('left', '0px');
				$(cnt).css('width', '100%');
				$(cnt).css('top', y + 15);
			}


			// If selected record/context HAS changed, always show the callout:
			// Usually, this is a test of help record ID, but in tag mode we need to look elsewhere...
			if ((theId[1] != 'TagClick' && cmp.get("v.HelpRecordId") != theId[0]) || (theId[1] == 'TagClick' && cmp.get("v.TagRecordId") != theId[0])) {

				// To do this, hide momentarily to allow spinner
				$A.util.addClass(cnt, 'slds-hide');
				helper.toggleTipBusy(cmp);
				$A.util.removeClass(cnt, 'slds-hide');

			} else {
				// If selected record/context has NOT changed, toggle visibility:
				// Only toggle closed if helped element 2nd click is supposed to close callouts
				var opt = cmp.get("v.GlobalSettings").iahelp__CalloutClosureBehaviour__c;
				if (opt != '2' || $A.util.hasClass(cnt, 'slds-hide')) {
					$A.util.toggleClass(cnt, 'slds-hide');
				}
			}


			// Having done all of this, mark "selected" row as required
			var LItems = document.querySelectorAll('li.HelpListingItem, tr.HelpListingItem');
			for (var i = 0; i < LItems.length; i++) {
				$A.util.removeClass(LItems[i], 'SelectedRecord');
			}

			// In this context, we only mark row where callout is visible
			if (!$A.util.hasClass(cnt, 'slds-hide')) {
				helper.setSelectedRow(cmp, theId[0]);
			}

		}


		// Also, fire a "record selected" event if required
		if (contextualize === true) {

			// If we were showing in place, only contextualize if in-place frame is now visible
			// (i.e., don't re-contextualize when hiding the popup)
			if (showInPlace === true && $A.util.hasClass(cnt, 'slds-hide')) {
				return;
			}

			console.log('IHCard.listingToolClick - raising contextualizing select topic event on behalf of "' + cmp.get('v.ComponentId') + '": topic is: ' + theId[0]);

			var appEvent = $A.get("e.c:selectTopic");
			appEvent.setParams({ "RecordId": theId[0] });
			appEvent.setParams({ "SourceComponent": cmp.get('v.ComponentId') });
			appEvent.fire();


			// Logging interaction to raise Platform Event
			var message = { ActionCode: theId[1], Parameters: theId[0] + '^' + theId[2], SourceComponent: cmp.get("v.ComponentId") };
			message = JSON.stringify(message);

			//cmp.find("geoLocation").getCurrentLocation().then((location) => {

				//console.log('position IN Aura latitude ', location.latitude);
				//console.log('position IN Aura longitude ', location.longitude);
				//console.log('position IN Aura altitude ', location.altitude);
				//console.log('position IN Aura accuracy ', location.accuracy)

				//For passing the location coordinates through the pre defined "logLUXInteraction" perameters
				//I am adding the coordinates in key value format to the end of the "IHContext" with a
				//delimeter 'String.fromCharCode(7)'{A unprintable delemeter} which will be then split out when
				//pass to the server method to take out the coordinates and the remaining string will be
				//work as it is previously functioning.

				//var D7 = String.fromCharCode(7);
				//var position = { "latitude": location.latitude, "longitude": location.longitude, "altitude": location.altitude, "accuracy": location.accuracy };

				//var act = cmp.get("c.logLUXInteraction");

				/*act.setParams({
					"iTyp": "0",
					"Description": message,
					"IHContext": cmp.get("v.UniqueIdent"), 
				});*/

				/*act.setCallback(this, function (response, cmp) {
					if (response.getState() === 'SUCCESS') {
						// Do nothing if OK
						console.log('IH Card Listing tool click - Platform event raised');
					} else {
						console.log('IH Card Listing tool click - Platform event error!');
					}
				});*/

				// Send action
				//$A.enqueueAction(act);
            
            helper.logLUXInteractions(cmp, 0, message, cmp.get("v.UniqueIdent")).then((response) => {
						//do nothing to response.
						if (response.getState() === 'SUCCESS') {
						// Do nothing if OK
						console.log('IH Card Listing tool click - Platform event raised');
					} else {
						console.log('IH Card Listing tool click - Platform event error!');
					}
					});
			//});

			// var act = cmp.get("c.logLUXInteraction");

			// act.setParams({
			// 	"iTyp": "0",
			// 	"Description": message,
			// 	"IHContext": cmp.get("v.UniqueIdent")
			// });

			// act.setCallback(this, function (response, cmp) {
			// 	if (response.getState() === 'SUCCESS') {
			// 		// Do nothing if OK
			// 		console.log('IH Card Listing tool click - Platform event raised');
			// 	} else {
			// 		console.log('IH Card Listing tool click - Platform event error!');
			// 	}
			// });

			// // Send action
			// $A.enqueueAction(act);
		}


		// Having completed all necessary actions, note the selected listing item:
		// Do NOT do this in certain cases (lists of tagged items), as help record forms part of an original / ongoing context

		if (theId[1] == 'TagClick') {
			// This is a list in "tagged  items" mode - so help topic needs to continue to be that of tag pool:
			// In these cases, record the selected topic separately
			cmp.set("v.TagRecordId", theId[0]);

		} else {
			cmp.set("v.HelpRecordId", theId[0]);
		}

	},


	// Handle pass throughs from sub-components etc.
	handlePassThroughs: function (cmp, event, helper) {
        
		var act = event.getParam("ActionCode");
		var parms = event.getParam("Parameters");
		var src = event.getParam("SourceComponent");
		var ourModal = cmp.find("theModal");

		// Close a modal dialogue in response to its request to do so
		if (act === 'DialogueRequestClose') {

			// Generally, only respond to requests from our own modal
			if (helper.eventIsOurOwn(ourModal, event)) {
				helper.closeDialogue(cmp, parms, helper);
			}

			// Special treatment for QAM help-enable dialogue
			if (helper.eventIsFromOurDialogue(cmp)) {
				helper.closeDialogue(cmp, parms, helper);
			}
		}


		if (helper.eventIsOurOwn(cmp, event)) {

			switch (act) {

				case 'ComponentToolsProcessed':
					// If action is component tools processed and emanates from ourselves, 
					// report card's actual pixel height, in case this is needed by others:
					// NB: this provides an 'initial' sizing: a definitive value can only be 
					// provided on mouse over (handled elsewhere). This being the case, here
					// we do NOT set latch preventing further reporting
					helper.reportRenderedHeight(cmp, event, helper);


					// If action is component tools processed and emanates from ourselves, 
					// we may need to add to our component navigation history: do so here...

					var hist = cmp.get("v.History");		// Existing history
					var rec = cmp.get("v.HelpRecordId");	// Last known record: may not in fact be where we now are!
					var CTs;								// For obtaining tool to toggle display of history, whose details may need amending 
					var HistToolType						// The type (body, header, ellipsis) of the history toggling tool
					var CTsOut = [];						// Amended copy of the appropriate tools
					var i;									// For looping
					var lbl;								// Label to add to history collection (along with record ID)
					var doAdd = true;						// Control variable identifying that an entry should be added to our navigation history



					// If record ID was not set, we cannot add this directly to history
					if (rec == '' || rec == '[None]') {

						// Check whether a record was, in fact, retrieved server side (e.g. author configuration or default page), and use if so
						try {
							if (cmp.get("v.ListingItems")[0] + '' != 'undefined') {
								rec = cmp.get("v.ListingItems")[0].Id;

							} else {
								doAdd = false;
							}
						} catch (e) {
							doAdd = false;
						}
					}


					// Only add a given record to history once
					if (doAdd == true) {
						hist.forEach(function (H) {
							if (H.value == rec) {
								doAdd = false;
							}
						});
					}


					// Add to the history, if we ascertained the need
					if (doAdd == true) {

						// Source of label and id for history listing varies by card implementation type
						switch (cmp.get("v.IHCardType")) {
							case 'List':
								// Label should come from the clicked listing item
								lbl = 'Listing: ' + rec;
								break;

							case 'Detail':
								// Label is the name of the selected topic, assuming topic mode
								if (cmp.get("v.IsHelpTopic") == true) {
									try {
										lbl = cmp.get("v.CurrentRecord").Name;
									} catch (e) {

										try {
											lbl = cmp.get("v.ListingItems")[0].Name
										} catch (ex) {
											lbl = 'Help Topic: ' + rec;
										}
									}
								} else {
									lbl = 'Record: ' + rec;
								}
								break;

							default:
								lbl = 'OTHER: ' + rec;
								break;
						}


						rec = { "label": lbl, "value": rec };
						hist.push(rec);

						// Record the fact that there is some NAVIGABLE history:
						// Only set this member if there is >1 item of history - as the first entry
						// will always be the record we start with (so there's no navigation to offer).
						cmp.set("v.HasHistory", hist.length > 1);

						// In the unique case of history, re-set certain config tools here (as they've already been processed
						// due to the event we're responding to!) If history exists, we need to show a tool to open it:
						// This re-set is only required where history length is 2 - as that is the first time we need to show the tool
						if (hist.length == 2) {

							// Iterate tools to find toggle history item:
							// Note this can only be one of certain types...
							CTs = cmp.get("v.HeaderTools");
							CTs = CTs.concat(cmp.get("v.EllipsisTools"));
							CTs = CTs.concat(cmp.get("v.BodyTools"));

							for (i = 0; i < CTs.length; i++) {
								if (CTs[i].iahelp__ActionCode__c == 'ToggleHistory') {

									// If located, mark it as being suitable to show
									CTs[i].iahelp__ToggleActiveMarker__c = 'ComponentConditionsMatch';

									// Note the type of this tool
									HistToolType = CTs[i].iahelp__Type__c;
									break;
								}
							}

							// Build collection of tools containing only those of the type of the history toggle
							// with the amended history tool
							for (i = 0; i < CTs.length; i++) {
								if (CTs[i].iahelp__Type__c == HistToolType) {
									CTsOut.push(CTs[i]);
								}
							}

							switch (HistToolType) {
								case 'Ellipsis':
									cmp.set("v.EllipsisTools", CTsOut);
									break;

								case 'Header':
									cmp.set("v.HeaderTools", CTsOut);
									break;

								case 'Body':
									cmp.set("v.BodyTools", CTsOut);
									break;
							}

						}

					}

					cmp.set("v.History", hist);
					break;

				case 'ReadingListDialogue':
					// See also 'ReadingList' action

					var RLID = cmp.get("v.recordId");
					var src = 'c:IHRLViewer';
					var aMap = {
						"Height": 620,
						"HelpRecordId": RLID,
					};

					helper.doDialogue('ReadingListViewer', 'LUX', src, aMap, 620, false, false, false, cmp, true);

					break;

				case 'HTShareLink':
					// Show a link that can be used to direct a user to a particular record

					var root = document.location.origin;
					var id;

					// If call came from ellipsis menu, parameters are in the form:
					// type [D1] action code [D1] display order [D1] toggle next

					// If call came from a listing item, parameters are in the form:
					// record id [D2] parameters

					// [D1] (see menuItemClick - passed from markup) is v.Delimiter
					// [D2] (see listingItemClick - hard wired) is '^'

					if (parms.includes('^')) {
						// Listing click: obtain ID from parameters
						var params = parms.split('^');
						id = params[0];

					} else {
						// Ellipsis item click:
						// Record ID will not be present - but is that of the card itself
						id = cmp.get("v.HelpRecordId");
					}

					// Advise user:
					prompt(helper.Internationalise(cmp, 'MessageShareViaURL'), root + '/' + id);
					break;

				case 'TreeShareLink':
					// For trees, we want the link to result in LUX Out Host with U1 showing tree (as there is
					// no override based on [SF Root]/record ID.
					var root = document.location.origin;
					root += '/apex/iahelp__IHLUXOutHost';
					root += '?NSApp=iahelp&App=appIH';
					root += '&NSComp=iahelp&Comp=IHUtility1';
					root += '&Parms=ColumnRatio~33^RootNode~' + cmp.get("v.RootNode");

					// 1.54+ : may need max depth to avoid stack issues!
					// REM: tool may be clicked on a U1, but it's a TREE that has the member data we need!
					root += '^TreeMaxDepth~' + cmp.get("v.MaxDepth");

					prompt(helper.Internationalise(cmp, 'MessageShareViaURL'), root);
					break;

			}

		}

	},


	// (On component mouse over) report (accurate - now fully rendered) component height then latch reporting off:
	// Also handle showing of powered by strapline and related internationalisations
	reportRenderedHeight: function (cmp, event, helper) {
        
		// This is a useful juncture to use to show powered by logo / product strapline:
		// Do NOT show powered by strapline if this has been suppressed 
		try {


			// BRAND SUPPRESSION - as of v1.53, controlled via Feature Management parameters
			// cf Helper.processTools
			if (cmp.get("v.BrandSuppressed") == false) {

				var PB = cmp.find("PoweredBy");
				if (PB + '' != 'undefined' && cmp.get("v.SuppressPoweredBy") == false) {
					$A.util.addClass(PB.getElement(), "IHCardFooterLogoExpanded");

					// Set related internationalisations
					var iCode = 'ProductPoweredBy';
					var PPB = helper.Internationalise(cmp, iCode);

					if (PPB != iCode) {
						cmp.set("v.ProductPoweredBy", PPB);
					}
				}
			}

		} catch (e) { }


		// NB: here, we call the reporting function then set latch to prevent further reporting
		helper.reportRenderedHeight(cmp, event, helper);
		cmp.set("v.RenderedHeightReported", true);
	},


	// Hide product strap-line as and when required (normally, card mouse out)
	hidePoweredBy: function (cmp, event, helper) {
		helper.hidePoweredBy(cmp);
	},


	// 'Permanently' (until refresh) hide product strap-line when moused over to avoid any issues blocking underlying UI
	suppressPoweredBy: function (cmp, event, helper) {
		cmp.set("v.SuppressPoweredBy", true);
	},


	// Respond to click on product strap-line by opening brand website
	gotoPoweredBy: function (cmp, event, helper) {
		var iCode = 'ContactUsLink';
		var U = helper.Internationalise(cmp, iCode);

		// Bail if, for any reason, we don't get the required URL
		if (U == iCode) {
			return;
		}
		window.open(U);
	},


	// Show / hide spinner as required when showing callouts
	toggleTipBusy: function (cmp, event, helper) {
		helper.toggleTipBusy(cmp);
	},


	// Hide callout on mouse out if required
	tipMouseOut: function (cmp, event, helper) {

		var opt = cmp.get("v.GlobalSettings").iahelp__CalloutClosureBehaviour__c;

		// Check required tip closure behaviour:
		// 1 = Close on element toggle only - NO mouse out behaviour
		// 2 = Close on mouse out only - NO toggle behaviour
		// 3 = Close on mouse out or element toggle

		if (opt != '1') {
			helper.hideCallout(cmp);
		}

	},


	// Hide any open tip on scroll (of card body)
	cardBodyScroll: function (cmp, event, helper) {
		helper.hideCallout(cmp);

		// Raise a pass-through to advise child controls where this may be required
		var appEvent = $A.get("e.c:evtPassThrough");
		appEvent.setParams({ "SourceComponent": cmp.get("v.ComponentId") });
		appEvent.setParams({ "ActionCode": "CardBodyScroll" });
		appEvent.setParams({ "Parameters": "" });
		appEvent.fire();
	},


	// Respond to a change in member data by scrolling our card body to the requested position
	setScroll: function (cmp, event, helper) {

		var pos = cmp.get("v.CardBodyScrollPos");
		console.log('setScroll: ' + pos);
		var x = document.getElementById('CardBodyContainer');
		x.scrollTop = pos;
	},


	// Wrapper to allow mark-up events (e.g., close tool click) to hide callouts
	hideCallout: function (cmp, event, helper) {
		helper.hideCallout(cmp);
	},


	// Wrapper enabling public function/method pass-through 
	doDialogue: function (cmp, event, helper) {
		var params = event.getParam('arguments');
		helper.doDialogue(params.dlgTitle, params.dlgType, params.dlgSource, params.dlgAttrs, params.frmHeight, params.allowScroll, params.largeMode, params.showFooter, cmp, params.translateTitle);
	},


	// Offer advanced diagnostics when requested
	reportDiags: function (cmp, event, helper) {

		// Only offer diagnostics when in "debug mode" (per global settings)
		try {
			if (cmp.get("v.GlobalSettings").iahelp__DebugMode__c == true) {
				var msg = cmp.get("v.AdvancedDiags");
				if (msg != '[OK]') {
					msg = msg.split('- - - ').join('\n');
					alert('This Lightning Component reports the following status:\n\n' + msg);
				}
			}

		} catch (e) {
			// Do nothing if debug status cannot be obtained
		}

	},


	// Facilitate filtering (on key press searching)
	HSTTextKeyup: function (cmp, event, helper) {

		var i;
		var j;
		var cnt = 0;
		var strContent;
		var valNew;
		var ctlType;
		var LIs = cmp.get("v.ListingItems");


		// Get the search configuration tool record: assume list search first, then try tree search if needed
		// Note, in either case, the type of search/control in use
		var theSearchConfigTool;
		theSearchConfigTool = helper.getConfigToolForAction(cmp, 'Header', 'Search');
		if (theSearchConfigTool == null) {
			theSearchConfigTool = helper.getConfigToolForAction(cmp, 'Header', 'TreeSearch');
			ctlType = 'TreeSearch';
		} else {
			ctlType = 'Search';
		}


		// Search is on tree / tree search list
		if (theSearchConfigTool == null) {
			theSearchConfigTool = helper.getConfigToolForAction(cmp, 'Header', 'TreeSearchList');
			ctlType = 'Search';
		}


		// Search is on tree / OTHER search list (bookmarks or glossary listings)
		if (theSearchConfigTool == null) {
			theSearchConfigTool = helper.getConfigToolForAction(cmp, 'Header', 'BackToTree');
			ctlType = 'Search';
		}

		// Related items searches on linking lists
		if (theSearchConfigTool == null) {
			theSearchConfigTool = helper.getConfigToolForAction(cmp, 'Header', 'SearchResources');
			ctlType = 'Search';
		}
		if (theSearchConfigTool == null) {
			theSearchConfigTool = helper.getConfigToolForAction(cmp, 'Header', 'SearchRelatedHelp');
			ctlType = 'Search';
		}


		// Cue a full search if enter key is pressed
		if (event.code + '' == 'Enter') {
			// To do this, locate the search tool and fire a click on it
			var D1 = cmp.get('v.Delimiter');
			var x = document.getElementById('Header' + D1 + ctlType + D1 + theSearchConfigTool.iahelp__DisplayOrder__c + D1 + theSearchConfigTool.iahelp__ToggleNext__c);
			try {
				x.click();
			} catch (e) { }
		}


		// From the configuration tool located above, get the support controls applicable to the search tool
		var theSearchSupportControls = helper.getSupportControlsForConfigTool(cmp, theSearchConfigTool);

		// Get the identifier used for search text box: this should be the first (and only) support control.
		// Whatever the config control record states, we need to add our control's unique ID to the control ID...
		var theSearchSupportControlIdent = theSearchSupportControls[0][1];
		theSearchSupportControlIdent += cmp.get("v.UniqueIdent");

		// Temporarily change focus to force search text box value "commit"
		var x = document.getElementById(theSearchSupportControlIdent);
		document.getElementById('FocusPuller').focus();
		x.focus();


		// Now take note of the search / filter text
		valNew = $(x).val().toUpperCase();


		// Filtering mechanism depends on type of control in use
		if (ctlType == 'Search') {

			// Standard list search
			var listStyle = cmp.get("v.ListingStyle");
			var listRows;


			// Loop through our listing item records
			for (i = 0; i < LIs.length; i++) {

				// Get the content that the current listing item displays in a listing,
				// whether narrow or wide format: we look for text matching item label and title...

				strContent = LIs[i].Label + LIs[i].Title;
				strContent = strContent + '';
				strContent = strContent.toUpperCase();

				// Now get any listing row on this screen that is displaying the record whose content we just obtained:
				// Note that there may be more than one of these, as the same record may appear on other components on any given screen...
				listRows = document.getElementsByClassName(LIs[i].Id);

				// Loop through these listing rows
				for (j = 0; j < listRows.length; j++) {

					// Only act on our own rows (those marked in a special data attribute with our component ID)
					if (listRows[j].getAttribute("data-cmpId") == cmp.getGlobalId()) {

						// Filter out (hide) the row if:
						//		Its listing content does not match the search term
						//		AND the row is not selected (ticked) for retention across searches
						if (strContent.indexOf(valNew) == -1 && !$A.util.hasClass(listRows[j], 'IsSelected')) {
							$A.util.addClass(listRows[j], 'slds-hide');

						} else {
							$A.util.removeClass(listRows[j], 'slds-hide');
							cnt += 1;
						}
					}
				}
			}

			cmp.set("v.Diags", valNew + ' - ' + helper.Internationalise(cmp, 'AdviceLabelMatchingItems') + ': ' + cnt);

			helper.clearAdvancedDiags(cmp);
			helper.logAdvancedDiags(cmp, theSearchSupportControlIdent + ':' + x + ':' + valNew + ':' + ctlType);

		} else {
			// Tree search
			var nods = [];
			var idx;
			var styl;

			nods[undefined] = { Label: "Root", items: [] };

			LIs.forEach(function (v) {
				if (v.Label.toUpperCase().indexOf(valNew) != -1 || v.Title.toUpperCase().indexOf(valNew) != -1) {
					styl = 'font-weight: bold; font-style: italic; margin-bottom: 1rem; border-left: dotted 0.3rem #' + cmp.get("v.GlobalSettings.iahelp__BrandColour6__c") + ';';
					cnt += 1;
				} else {
					styl = '';
				}

				nods[v.Id] = { Style: styl, Id: v.Id, ParentId: v.Parameters, Expanded: true, Label: v.Label, Title: v.Title, StyleClass: v.StyleClass, Icon: v.Icon, IconLabel: v.IconLabel, RowState: v.RowState, items: [] };
			});


			// Now loop through nodes again, adding each to the items of its parent
			try {
				LIs.forEach(function (v) {
					idx = v.Parameters;
					if (idx + '' == 'null' || idx == '') { idx = undefined; }
					nods[idx].items.push(nods[v.Id]);
				});
			} catch (e) { }


			// It would appear that the above logic runs relatively quickly - but that the act
			// of setting nodes (and thus, presumably, calling a LUX repaint of some kind)
			// is SLOOOW! So: keep track of the nodes here, but only attempt actual 
			// filter when search tool is clicked

			cmp.set("v.FilteredNodes", nods[undefined].items);

			// Note matching record info & count in cache
			cmp.set("v.OpsCache", '(' + valNew + ') ' + cnt);
		}

	},
        
        handleMessage: function(component, event, helper) {
            if (event) {
                const message = event.getParams();
                
                if (message && message.SourceComponent && message.Parameters && message.ActionCode) {
                    console.log("Aura: Received LMS message in IHCARD →", message);
                    
                    const CmpId = message.SourceComponent;
                    const incomingId = message.Parameters;
                    const actionCode = message.ActionCode;
                    
                    // Check if component is listening for this event 
                    // Note:
                    if (helper.eventBeingListenedTo(component, event) === true) {
                        // Fire selectTopic only if action is CueContextHelp
                        if (actionCode === "CueContextHelp") {
                            var topicEvent = $A.get("e.c:selectTopic");
                            topicEvent.setParams({
                                "RecordId": incomingId,
                                "SourceComponent": CmpId
                            });
                            topicEvent.fire();
                        }else {
                            //Fire default passthrough event (fallback)
                            var fallbackEvent = $A.get("e.c:evtPassThrough");
                            fallbackEvent.setParams({
                                "SourceComponent": CmpId,
                                "ActionCode": actionCode,
                                "Parameters": incomingId
                            });
                            fallbackEvent.fire();
                            
                            console.log("Aura: Fired default passthrough event for unlistened source →", CmpId);
                        }
                    } else {
                        console.warn("Aura: LMS message missing required fields:", message);
                    }
                }
            };
        },


})