/////////////////////////////////////////////////////////////////////////////////////////////////////
// FUNCTIONS FOR USE WITH GUIDE AND GUIDE STEP WINDOWS
//
// NB: Some of these functions rely on jQuery (to be present via IHHook)
// Also requires jsSettings, jsToggleHelp and jsQAMenu (also via IHHook)
//
// Martin Little for Improved Apps
// July 2013
// Copyright (c.) Improved Apps Limited 2013. All Rights Reserved.
/////////////////////////////////////////////////////////////////////////////////////////////////////

"use strict";

(function(IHGuides, $, undefined) {

//--------------------------------------------------------------------------------------------------
// Sizing coordinates
//--------------------------------------------------------------------------------------------------
	IHGuides.guideStepX;			
	IHGuides.guideStepY;			
	IHGuides.guideStepW;			
	IHGuides.guideStepH;			

//--------------------------------------------------------------------------------------------------
// Consumer page MUST set these variables on initialising
//--------------------------------------------------------------------------------------------------
	IHGuides.TRootLink;
	IHGuides.cxtRequired;
	IHGuides.ReadingListId;
	IHGuides.THelpId;
	IHGuides.TTemplate;
	IHGuides.IHjsGDOpts;
	IHGuides.theToolFrame;

//--------------------------------------------------------------------------------------------------
// Note guide window sizing coordinates
//--------------------------------------------------------------------------------------------------
	IHGuides.initialiseForGuides = function () {
	
		// Set window sizing information for Guide Steps
		var CoOrds = readCookie('IHGuideStepCoOrds');
		
		if (CoOrds != null) {
			CoOrds = CoOrds.split(':');
		} else {
			CoOrds = (window.screenX + window.outerWidth + 1) + ':' + window.screenY + ':700:' + window.outerHeight;
			CoOrds = CoOrds.split(':');
		}
		
		IHGuides.guideStepX = CoOrds[0];
		IHGuides.guideStepY = CoOrds[1];
		IHGuides.guideStepW = CoOrds[2];
		IHGuides.guideStepH = CoOrds[3];
	
		return;			
	}


//--------------------------------------------------------------------------------------------------
// Navigate STEP window to guide step and GUIDE window to step's topic
//--------------------------------------------------------------------------------------------------
	IHGuides.navToGuideStep = function (RList, RListType, GuidedLayout, GuidedRecord, VIPId, VIPOnClick, HTID) {
	
		try {		
			var U;
			var Context;
			var RLType;
			var QSConcat;
			var recId;
	
	
			// Get the calling page URL / Context supplied to this page
			try {
				Context = $IAIHj.urlParam('IHContext');
			} catch (e) {}
			
	
			// Context is essential: bail if we don't have it for some reason:
			if (Context == null) {
				alert(Internationalise('[QAMMessageGuideLostContext]'));
				return;
			}
			
			
			// Refresh step size info from cookie
			IHGuides.initialiseForGuides();
			
			
			// We may need to navigate to a specific record (specified by author) or
			// one based on user's current URL, as passed to this page via IHContext:
					
			if (GuidedRecord != '') {
				// If we are given a Guided Record, we should use that:
				
				// Start by parsing out any tokens
				if (GuidedRecord.indexOf('[ContextRecordId]') != -1) {
					
					// Derive SF record Id from current context
					var sid = SFRecordId(Context);
					
					// Replace token with this
					GuidedRecord = GuidedRecord.split('[ContextRecordId]').join(sid);				
				}
				
				// Then, look for some "special" codes...
				if (GuidedRecord == '/e') {
					
					// Add / edit record:
					if (checkStepContext(Context) == true) {
						// If it is, use the context (URL) supplied
						U = Context + '/e';
						
						// We should also append a "return URL" to this, so SF knows
						// where to navigate user on completion of record amendment activity:
						// We can only do this were context includes a record ID...
						recId = Context;
						if (recId.indexOf('/') != -1 && recId != '/') {recId = recId.substring(Context.lastIndexOf('/') + 1);}
						if (recId.length > 3) {
							U += '?retURL=%2F' + recId;
						}
						
					} else {
						// If not, advise the user they should navigate to a suitable location
						alert(Internationalise('[QAMMessageGuideNavigationRequired]'));
						return;
					}
	
				} else {
					// If not, just take the record as supplied?
	
					// Can't use "document.location.host" as the document is the guide viewer - and that's always in VF land.
					// That's not the same host as will be required for guided SF records: 
					// (happens to work with VF -> Classic SF (automatic redirection) but not so communities)
													
					// SO: Take root from supplied context: this won't always work but should work more often...
					// Make a hyperlink of the context and seek its host name
	
					if (Context != '' && Context + '' != 'null') {
						var anch = document.createElement('a');
						anch.href = Context;
						U = 'https://' + anch.host + '/' + GuidedRecord;
						
					} else {
						U = TRootLink + '/' + GuidedRecord;					
					}
	
				}
			
			} else {
				// If no Guided Record was supplied in the Guide definition (step's help topic)
				// we should check that the supplied context is suited to the Guided layout:
		
				if (checkStepContext(Context) == true) {
					// If it is, use the context (URL) supplied
					U = Context;
					
				} else {
					// If not, advise the user they should navigate to a suitable location
					alert(Internationalise('[QAMMessageGuideNavigationRequired]'));
					return;
				}
			
			}
									
			
			// We'll need to tack on VIP instructions to the page we're going to visit, but these may
			// not be the first query string clause, so work out the concatenator to use here...
			
			if (U.indexOf('?') == -1) {
				QSConcat = '?';
			} else {
				QSConcat = '&';
			}
			
	
			// If we get here, we should advise user in Guide window they need to wait on step window...
			$IAIHj('#IHGuideWorking').show();
			
			
			// Nature of the Guide Step URL varies depending on whether immediate VIP is required:		
			if (VIPOnClick == true) {
				// Immediate
	
				// IE will only permit cross-window comms if "conversation" is initiated from same domain:
				// So, we need to use redirection to move from VF to SF if we're in IE 
				if (isIE()) {
					IHQAMenu.DoDialogue(IHSettings[SFURL] + '/apex/iahelp__IHWrapper?IHContext=' + encodeURIComponent(U + QSConcat + 'IHVIP=' + VIPId), IHGuides.guideStepX, IHGuides.guideStepY, IHGuides.guideStepW, IHGuides.guideStepH, '_GuideStep');						
					
				} else {
					IHQAMenu.DoDialogue(U + QSConcat + 'IHVIP=' + VIPId, IHGuides.guideStepX, IHGuides.guideStepY, IHGuides.guideStepW, IHGuides.guideStepH, '_GuideStep');	
				}		
	
			} else {
			
				// When Await VIP is required, we need to get the Await parameters to send
				// from a hidden DIV where they're placed by page markup (below)
				
				VIPId = stringTrim(document.getElementById(HTID).innerHTML);
				
				// We want to encrypt this set of instructions:
				VIPId = CryptoJS.AES.encrypt(VIPId, "AwaitVIP");    
				VIPId = encodeURI(VIPId);
				
	
				// Also, translate guide (reading list) type into a simple figure for passing to step page
				if (RListType.toUpperCase() == 'LINEAR GUIDE') {
					RLType = 1;
				} else {
					RLType = 2;
				}
				
				// ... then cue step window
				// IE will only permit cross-window comms if "conversation" is initiated from same domain:
				// So, we need to use redirection to move from VF to SF if we're in IE 
				if (isIE()) {
					IHQAMenu.DoDialogue(IHSettings[SFURL] + '/apex/iahelp__IHWrapper?IHContext=' + encodeURIComponent(U + QSConcat + 'RLType=' + RLType + '&AwaitVIP=' + VIPId), IHGuides.guideStepX, IHGuides.guideStepY, IHGuides.guideStepW, IHGuides.guideStepH, '_GuideStep');
								
				} else {
					IHQAMenu.DoDialogue(U + QSConcat + 'RLType=' + RLType + '&AwaitVIP=' + VIPId, IHGuides.guideStepX, IHGuides.guideStepY, IHGuides.guideStepW, IHGuides.guideStepH, '_GuideStep');	
				}
	
			}
			
			
			// Our step HTID is now the topic we were passed.
			// As we're navigating to this, the required context will also change
			GSHTID = HTID;
			IHGuides.cxtRequired = GuidedLayout;
			
		} catch (e) {
			alert(Internationalise('[QAMMessageGenericError]') + ' - (NavToGuideStep) ' + e);
		}
		
		
		return;
	}
	
	
//--------------------------------------------------------------------------------------------------
// Navigate GUIDE window to step's topic:
// Supply Guide (reading list) ID, step (help topic) Id and Context (calling page URL)
//--------------------------------------------------------------------------------------------------
	IHGuides.setStepInfo = function (RList, HTID, Context) {
		
		var x;
		var U;
		
		try {
			var root = IHSettings[SFURL];	
			
			if(Context == '') {
				// Get the calling page URL / Context supplied to this page
				Context = $IAIHj.urlParam('IHContext');				
			}
						
			U = root + '/apex/iahelp__IHReadingListViewer?RLID=' + RList + '&Opts=Guide&HTID=' + HTID + '&IHContext=' + Context;
			
			if (window.location.href != U) {			
				// Take note of the topic we've been told to go to immediately:
				// That way, if a context message etc is sent as we navigate, it will 
				// respond with an updated HTID 
				IHGuides.THelpId = HTID;
	
				//alert('setStepInfo: ' + U);
				window.location.href = U;
			}
	
		} catch (e) {
			alert(Internationalise('[QAMMessageGenericError]') + ' - (setStepInfo) ' + e);
		}
		
		return;			
	}


//--------------------------------------------------------------------------------------------------
//Close all guide windows (expected to be called from the GUIDE window)
//--------------------------------------------------------------------------------------------------
	IHGuides.closeGuideWindows = function () {
	
		// Close step win: to do this, open a new dialogue window on root SF, with "kill" parameter
		// in query string. This will instruct jsSettings code to:
		// 
		// - update the cookie that is checked by the checkVIP timed process running in any other
		//   step window (see LogVIPs): when it sees this has been updated, the step will close itself
		//
		// - close itself
		IHQAMenu.DoDialogue(IHSettings[SFURL] + '/home/home.jsp?IHCloseWindow', 0, 0, 0, 0, '_GuideStep');
		
		// Close current (Guide) win
		window.close();	
		
		return;
	}						


//--------------------------------------------------------------------------------------------------
//Resize the iframe being used to show step tools (topic viewer, editor etc)
//--------------------------------------------------------------------------------------------------
	IHGuides.resizeFrame = function () {
		var h = window.innerHeight;
		var t = $IAIHj('#frmTopic').position().top;		
		$IAIHj('#' + IHGuides.theToolFrame).height(h - t - 10);		
	}


//--------------------------------------------------------------------------------------------------
//Set iframe to show desired Guide / RL tool (topic viewer, editor etc)
//--------------------------------------------------------------------------------------------------
	IHGuides.showRLVTool = function (tool) {
		try {
		
			var frm = document.getElementById(IHGuides.theToolFrame);
			var Root = IHSettings[SFURL];
					
			var theSelectedTool = '';
			
			// We don't want anyone seeing tools to which they're not entitled by virtue of a cookie 
			// left from a previous login - so check access rights here to amend requested tool if required:
			switch (tool.toUpperCase()) {
		
				case "TOPICSTATS":
					// Need to be at least an Analyst
					if (IHSettings[isAnalyst] != 'true' && IHSettings[isAuthor] != 'true' && IHSettings[isAdministrator] != 'true') {tool = ''}
					break;
					
				case "TOPICEDIT":
				case "GUIDEPROPERTIES":
					// Need to be at least an Author
					if (IHSettings[isAuthor] != 'true' && IHSettings[isAdministrator] != 'true') {tool = ''}
					break;
					
				default:
					// Otherwise (View, comment) no need to act
					break;
			}
			
			
			switch (tool.toUpperCase()) {
				
				case "TOPICEDIT":
					frm.src = Root + '/apex/iahelp__IHEditingToolsTopic?HTID=' + IHGuides.THelpId;
					theSelectedTool = 'toolTopicEdit';
					break;
	
				case "TOPICSTATS":
					frm.src = Root + '/apex/iahelp__IHStats?HTID=' + IHGuides.THelpId;
					theSelectedTool = 'toolTopicStats';
					break;
	
				case "TOPICCOMMENT":
					// This needs to switch between Comment and Cancel options (buttons)
					if ($IAIHj('#btnCommentCancel').hasClass('IHHidden')) {
						// Show comment plus cancel button
						frm.src = Root + '/apex/iahelp__IHComment?HTID=' + IHGuides.THelpId + '&IHContext=IHHosted';	
						$IAIHj('#btnCommentShow').addClass('IHHidden');
						$IAIHj('#btnCommentCancel').removeClass('IHHidden');
						
					} else {
						// Show topic plus comment button
						frm.src = Root + '/apex/' + IHGuides.TTemplate + '?HTID=' + IHGuides.THelpId;
						$IAIHj('#btnCommentShow').removeClass('IHHidden');
						$IAIHj('#btnCommentCancel').addClass('IHHidden');
					}
					
					theSelectedTool = 'toolTopicView';
					break;
					
				case "GUIDEPROPERTIES":
					document.location = Root + '/apex/iahelp__IHReadingListProperties?Mode=Edit&Id=' + IHGuides.ReadingListId + '&ShowBack=true&BackURL=' + encodeURIComponent(document.location.href);
					theSelectedTool = 'toolTopicView';
					break;
	
				default:
					
					// v1.33: Only proceed here if frame has been located
					if (frm + '' == 'null') {return;}
					
					// Default to showing the topic template:
					// IE can have trouble with script tag downloads - so sometimes doesn't have toggleHelp functions
					// when they're needed!! Use a (relatively) safe get-out for these cases...
					var tU = getTemplateAddress(IHGuides.TTemplate);
					if (tU + '' == 'undefined') {
						tU = IHGuides.TTemplate;
					}
					
					// 1.21: in these cases, add a switch to show that it is a guide that's calling this help interaction				
					frm.src = tU + '?HTID=' + IHGuides.THelpId + '&AsGuide=' + IHGuides.ReadingListId;
					
					// This should also make "comment" tool visible in all cases
					$IAIHj('#btnCommentShow').removeClass('IHHidden');
					$IAIHj('#btnCommentCancel').addClass('IHHidden');
									
					theSelectedTool = 'toolTopicView';
					break;
			}
			
			// Set a cookie to note which view a user was using:
			// Also, highlight the tool which is in use
			// NB: this does NOT apply when showing guide properties or comments
			if (tool.toUpperCase() != 'GUIDEPROPERTIES' && tool.toUpperCase() != 'TOPICCOMMENT') {
				IHSetCookie('IHRLVSelectedTool', tool, 2);
				
				// Remove all tool highlighting then highlight the required one
				$IAIHj('.RLVTools').removeClass('RLVToolSelected');
				$IAIHj('.' + theSelectedTool).addClass('RLVToolSelected');
			}
			
			
		} catch (e) {
			alert(Internationalise('[QAMMessageGenericError]') + ' - (showRLVTool) ' + e);
		}
		
		return;
	}


//--------------------------------------------------------------------------------------------------
// Show a "share" link for the current guide
//--------------------------------------------------------------------------------------------------
	IHGuides.showShareLink = function () {
		var U = TRootLink;
		var GotoURL = U + '/apex/iahelp__IHReadingListViewer?Opts=Guide';
		GotoURL += '&RLID=' + IHGuides.ReadingListId;
		GotoURL += '&HTID='; // Leave blank - we only ever want to go to 1st step in Guide
		GotoURL += '&IHContext=null';
	
		U += '/apex/iahelp__IHWrapper?GoToRL=' + encodeURIComponent(GotoURL);
		
		window.prompt (Internationalise('[QAMMessageVIPLinkCopyInstructionsGuides]'), U);				
		return;
	}
	
//--------------------------------------------------------------------------------------------------
// Record the size and position of the guide window in a cookie in the form "X:Y:W:H"
//--------------------------------------------------------------------------------------------------
	window.onresize = function (e) {
		
		// Applicable only to guides
		if (IHGuides.IHjsGDOpts == 'Guide') {								
			var CoOrds = window.screenX + ':' + window.screenY + ':' + window.outerWidth + ':' + window.outerHeight;					
			IHSetCookie('IHGuideCoOrds', CoOrds, 30);
			IHGuides.resizeFrame();
		}
	}


//--------------------------------------------------------------------------------------------------
// Respond to messages
//--------------------------------------------------------------------------------------------------
	window.onmessage = function (e) {
	
		try {
			// Message = a particular guide step has become active
			if (e.data.toString().substring(0,7) == 'GSHTID=') {
				
				// Show "working" message shown to user in Guide window - as we'll navigate below and hide this...
				$IAIHj('#IHGuideWorking').show();
		
				// NB: the message content here will include help topic and context info, 
				// so we need to split these parts out
				var params = e.data.toString().substring(7).split('^');
				IHGuides.setStepInfo(IHGuides.ReadingListId, params[0], params[1]);
				
				// Note the topic the guide step is on
				GSHTID = params[0];
		
			}
			
			
			// Message = guide step window has been re-sized
			if (e.data.toString().substring(0,7) == 'GSSize=') {
				IHSetCookie('IHGuideStepCoOrds', e.data.toString().substring(7), 30);				
			}
			
			
			// Message = user has navigated to some new (potentially off-guide) page
			if (e.data.toString().substring(0,6) == 'GSCXT=') {
				
				//alert('jsGuides: received GSCXT\n\n' + e.data.toString().substring(6) + '\n\nat\n\n' + document.location);
		
				// Check the screen layout the user is on is suitable for current guide step
				if (checkStepContext(e.data.toString().substring(6)) == false) {					
		
					// If not, advise the user through visual clues						
					$IAIHj('#IHRLVBody').addClass('IHGuideContextError');
					
					// In these cases, as we're not navigating, we need to clear the "working" marker
					$IAIHj('#IHGuideWorking').hide();
		
				} else {
					// Clear "off-piste" visual cues
					$IAIHj('#IHRLVBody').removeClass('IHGuideContextError');
					
					// If it does match, set this as our context - so we retain it going forward
					if (GSHTID == '') {GSHTID = IHGuides.THelpId;}
		
					var U = IHSettings[SFURL] + '/apex/iahelp__IHReadingListViewer?RLID=' + IHGuides.ReadingListId + '&Opts=Guide&HTID=' + GSHTID + '&IHContext=' + e.data.toString().substring(6);
					
					if (window.location.href != U) {
		
						// Show "working" message shown to user in Guide window - as we'll navigate below and hide this...
						$IAIHj('#IHGuideWorking').show();
						window.location.href = U;
					}
		
				}
			}
			
			
			// Message = some action has completed
			if (e.data.toString().substring(0,16) == 'confirmComplete=') {
				// In our case, this message is sent only by the comments
				// page from its iframe: when this happens, we want to return
				// the user to the help details		
				IHGuides.showRLVTool('');
			}
			
		} catch (e) {
			
		}
		
		return;
	}
	
	
//--------------------------------------------------------------------------------------------------
//One-click Guide cueing calls - moved here from jsConsole v1.32+
//--------------------------------------------------------------------------------------------------

	// Advise guide code of community info / paths, if required
	IHGuides.setCommunityPaths = function (scrRoot, commDomain, commPrefix){
		IHGuideScriptRoot = scrRoot;
		IHGuideCommunityDomain = commDomain;
		IHGuideCommunityPrefix = commPrefix;
	}


//--------------------------------------------------------------------------------------------------
// Call QAM settings VF page, load returned guide info into a helped layout and set a callback to run with the results:
// 1.23 - added ability to specify Guide type Linear = 1, Non-linear = 2)
//--------------------------------------------------------------------------------------------------
	IHGuides.CueGuide = function (GID, RLType) {
		
		var dv;
		var scr;
		var srcURL;
			
		try {
			// Add a Guide info DIV if required
			if (document.getElementById('QAMGuideStepInfo') + '' == 'null') {
				dv = document.createElement('div');
				dv.setAttribute('id', 'QAMGuideStepInfo');
				document.getElementsByTagName('head')[0].appendChild(dv);
			}
			
			// Add crypto script
			srcURL = IHGuideScriptRoot + "/resource/iahelp__IHResources/lib/CryptoJSv312AES/aes.js";
			scr = document.createElement('script');
			scr.setAttribute('src', srcURL);		
			document.getElementById('IAIHSettings').appendChild(scr);
			
			
			// Make additional guide cueing calls
			srcURL = IHGuideScriptRoot + "/apex/iahelp__IHQAMSettings?callback=IHGuides.getGuideInfo&GuideId=" + GID + IHGuideCommunityDomain + IHGuideCommunityPrefix;
			scr = document.createElement('script');
			scr.setAttribute('src', srcURL);		
			document.getElementById('IAIHSettings').appendChild(scr);
			
			
			// Set guide type, or default to linear if not specified: 
			// For definition and usage, see jsToggleHelp and its showPrompt function
			if (RLType + '' != 'undefined') {
				IHVIPRLType = RLType; 
			} else {
				IHVIPRLType = 1; 
			}
			
		} catch (e) {
			alert(Internationalise('[QAMMessageGenericError]') + ' - (CueGuide) ' + e);
		}
		
	}


// --------------------------------------------------------------------------------------------------
// Callback to CueGuide: set cookie indicating guide is requested then re-cue help (which will cause Guide to appear in response)
// --------------------------------------------------------------------------------------------------
	IHGuides.getGuideInfo = function (ResponseFromVFPage) {
			
		try {
			// Response from server should be in the same form as would come to jsGuides.NavToGuideStep
			// from the reading list / guide viewer page, so needs to be encrypted before use (as if
			// it were being sent as an AwaitVIP URL query string)

			var AwaitVIPId = CryptoJS.AES.encrypt(ResponseFromVFPage, "AwaitVIP");
			var IHVIPTimeStamp = getTimeStamp(); 
			var AwaitURL = document.location.href;
			
			// NB: setting can be one of several that indicate LUX flavour guides are to be used		
			var LUXGuideMode = IHSettings[BrandUXOption];
			if (LUXGuideMode > '1') {LUXGuideMode = true;} else {LUXGuideMode = false;}
			
			
			if (document.location.search != '') {
				AwaitURL += '&RLType=1&AwaitVIP=' + AwaitVIPId; 
			} else {
				AwaitURL += '?RLType=1&AwaitVIP=' + AwaitVIPId; 
			}
		
			IHSetCookie('IHQAMAwait', AwaitVIPId, 1); 
			IHSetCookie('IHQAMVIP', IHVIPTimeStamp + settingsD1 + AwaitURL, 1); 
				
			document.getElementById('QAMGuideStepInfo').innerHTML = IHQAMenu.getGuideLinks(AwaitVIPId);

			
			// Populate and show step list if we're in LUX mode for a non-linear Guide:
			// In classic, there's a "show steps" button, but in LUX it's a nav drop down that is always visible
			if (LUXGuideMode == true && IHVIPRLType == 2) {
				showStepList($IAIHj('#IHPrompt'));
			}        	
			
			
			// 1.23 (1.22.2) - to allow (partial) re-runs of guide without a page refresh, we need
			// to re-set step to 1 each time guide is cued
			currentLocalStep = 1;
			
			HookHelp(); 
			IHQAMenu.SetupQAM('Saved');	
			
		} catch (e) {
			// 1.23 - Commenting out to avoid occasional message seen in 1.22.n - where QAMGuideStepInfo (above)
			// seems to be null, so causes message (though guide still works!)
			//alert(Internationalise('[QAMMessageGenericError]') + ' - (getGuideInfo) ' + e);
		}
		
	}

	
// --------------------------------------------------------------------------------------------------
// PRIVATE MEMBERS:
// --------------------------------------------------------------------------------------------------
	
	var GSHTID = '';					// HTID of RL Entry forming current Guide Step
	var IHGuideScriptRoot = '';			// See setCommunityPaths
	var IHGuideCommunityDomain = '';	// See setCommunityPaths
	var IHGuideCommunityPrefix = '';	// See setCommunityPaths
	
	
// --------------------------------------------------------------------------------------------------
//Get the SF record ID featured in a given context
// --------------------------------------------------------------------------------------------------
	function SFRecordId(cxtURL) {
		
		// Turn the URL string into a URI and examine its path...		
		var retVal = document.createElement('a');	
		retVal.href = cxtURL;
		
		if (retVal.pathname.length >= 15) {
			if (retVal.pathname.indexOf('/') == 0) {
				retVal = retVal.pathname.substring(1,16);
			} else {
				retVal = retVal.pathname.substring(0,15);
			}

		} else {
			retVal = '';
		}	

		return retVal;
	}
	

//--------------------------------------------------------------------------------------------------
// Check whether context (step window's page layout) supplied to guide is suited to current step
//--------------------------------------------------------------------------------------------------
	function checkStepContext(cxtURL) {
		
		// Step window's page layout can be derived from its URL:
		// Turn the URL string into a URI and examine its path...		
	
		var cxtSupplied = document.createElement('a');	
		cxtSupplied.href = cxtURL;
		
		// 1.19: some browsers include "/" as part of path, others not: skip this if found
		if (cxtSupplied.pathname.indexOf('/') == 0) {
			cxtSupplied = cxtSupplied.pathname.substring(1,4);
		} else {
			cxtSupplied = cxtSupplied.pathname.substring(0,3);
		}
	
		// The object required is the one referenced by the current help topic
		return cxtSupplied == IHGuides.cxtRequired || IHGuides.cxtRequired == '';
	}


	
}(window.IHGuides = window.IHGuides || {}));			