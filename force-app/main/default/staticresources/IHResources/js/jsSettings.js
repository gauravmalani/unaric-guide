/////////////////////////////////////////////////////////////////////////////////////////////////////
// FUNCTIONS FOR RETRIEVING IH SETTINGS, SUCH AS GLOBAL OPTIONS AND USER SECURITY INFO
//
// Martin Little for Improved Apps
// October 2012
// Copyright (c.) Improved Apps Limited 2012. All Rights Reserved.
/////////////////////////////////////////////////////////////////////////////////////////////////////

"use strict";

// --------------------------------------------------------------------------------------------------
// Delimiter and other characters for use in query strings etc
// --------------------------------------------------------------------------------------------------
	var settingsD1  = String.fromCharCode(7);
	var settingsD2  = String.fromCharCode(5);
	var settingsPct = String.fromCharCode(6);	// Replacement character for "%" to avoid encoding issues


// --------------------------------------------------------------------------------------------------
// Track whether the current page has any potentially helpable elements:
// (If not, some QAM functionality should be disabled)
// --------------------------------------------------------------------------------------------------
	var hasHelpableElements = false;

// --------------------------------------------------------------------------------------------------
// Track whether client browser supports inter-window messaging
// --------------------------------------------------------------------------------------------------
	var supportsPostObject = false;
	(function(){
	    var callback = function(e) {
	        supportsPostObject = (typeof(e.data)!='string');
	    };
	    (window.addEventListener) ?
	        window.addEventListener('message', callback) :
	        window.attachEvent('onmessage', callback);
	    ('postMessage' in window) && window.postMessage({}, '*');
	})();


// PATCH: 1.18.1
// --------------------------------------------------------------------------------------------------
// Pads a number with "base" x leading "padChar"s (assumes a single leading zero if no params passed
// --------------------------------------------------------------------------------------------------	
	Number.prototype.padLeft = function(base, padChar){
	    var  len = (String(base || 10).length - String(this).length) + 1;
	    return len > 0? new Array(len).join(padChar || '0') + this : this;
	}	

	
// --------------------------------------------------------------------------------------------------
// Detect Internet Explorer
// --------------------------------------------------------------------------------------------------	
	function isIE() {
		if (navigator.appName == 'Microsoft Internet Explorer' || (navigator.appName == 'Netscape' && navigator.userAgent.indexOf('Trident/') != -1)){
			return true;
		} else {
			return false;
		}
	}

// --------------------------------------------------------------------------------------------------
// To keep note of Org-wide IH settings
// --------------------------------------------------------------------------------------------------
	var IHSettings = null;		// An array of settings...
	
	// ...and the positions within this array of various items...
	
	var LStatusCode = 0;		// Improved Help License status code 
	var LStatus = 1;			// Improved Help License status diagnostics
	var LSeats = 2;				// Improved Help License number of seats (# or 'Unlimited')
	var LType = 3;				// Improved Help License Type (e.g., Full, Trial, Free)
	var LFolder = 4;			// Improved Help document folder (which should house the license file)
	
	var SFURL = 5;				// The base Salesforce URL
	var SFPod = 6;				// SF server pod (derived from OrgId)
	var CPrefix = 7;			// The name / prefix used by the community, if any, a user is visiting
	var PortalPage = 8;			// Name of the Portal page in use (depends on LUX / Classic / SF1 settings etc.)
	var SFObjId = 9;			// Id of the SF object featured on the current page
	var AllowComments = 10;		// Is commenting allowed for the current layout?
	var RepeatHooking = 11;		// Is repeat hooking required for this layout (used where layouts are long/may not be ready to hook)
	var NameSpace = 12;			// IA Improved Help's product name space 
	var SFObjectIds = 13;		// Capek delimited list of IH's key SF object three letter codes
	var BrandCSS = 14;			// URL to customer's override CSS
	var BrandToolTip = 15;		// Tool tip to use for IH helped elements
	var BrandUXOption = 16;		// Controls UI switching (e.g., to a LUX flavour) in certain cases
	
	var doP = 17;				// Provide improved Page-level help
	var doO = 18;				// Provide improved help for Objects
	var doR = 19;				// Provide improved help for Related lists
	var doD = 20;				// Provide improved help for Details section headings
	var doF = 21;				// Provide improved help for Field labels
	var doT = 22;				// Provide improved help for Table column headings
	var doB = 23;				// Provide improved help for Buttons
	var doL = 24;				// Provide improved help for Links
	var doC = 25;				// Provide improved help for Custom Section headings
	var doE = 26;				// Provide improved help for Record Title text
	
	var jQNCMode = 27;			// Switch controlling whether to use noConflict() or noConflict(true) with jQuery
	
	var HookMode = 28;			// Indication of the type of hooking info returned via HEs / CDetails
	var HEs = 29;				// The list of helped elements on the current page
	var CDetails = 30;			// Details of the callouts to use with each of the above
	var FDetails = 31;			// Details of helped elements existing for current layout but which fail data driven filter
	var SigDetails = 32;		// Details of additional "signatures" that can be helped on (potentially non-SF) pages 
	var HelpedPLID = 33;		// ID of the current Helped Page Layout (if this exists)
	var CWidth = 34;			// Width to use for certain kinds of callout
	var CCloseType = 35;		// Callout closure behaviour (on toggle, mouse out etc)
	var HPLExists = 36;			// Set to true if a helped page layout exists for current page
	var GuidesExist = 37;		// Set to true if any guide(s) exist for current page
	var GuidesList = 38;		// The list of Guides (IDs, Names and Summaries) available for this page	
	var GuidesLinksOption = 39;	// Global setting governing how to display available Guides
	var doLoginChecks = 40 ;	// Switches login checking on or off
	var SettingsCache = 41;		// A setting that can be used to pass additional info to the SF/JS client
	
	var isAuthor = 42;			// To keep track of user permissions 
	var isAdministrator = 43;	// Ditto
	var isAnalyst = 44;			// Ditto
	var isSeated = 45;			// Tracks whether user is allocated to a subscription / seat
	
	var defaultHTSet = 46;		// Has a default help topic been set (affecting availability of e.g. QAM home link)? 

	var Localisations = 47;		// Delimited list of localisation strings for QAM and other client side JS (alerts etc)
	
	// The total number of settings (should max of above positions + 1)
	var numIHSettings = 48;		
	

// --------------------------------------------------------------------------------------------------
// Guide window sizing co-ordinates
// --------------------------------------------------------------------------------------------------
	var guideX;
	var guideY;
	var guideW;
	var guideH;	
		
	
// --------------------------------------------------------------------------------------------------
// Callback function to process settings string retrieved via script sourced as VF page:
// See also:
//		- the IHHook VF include page, which calls this callback for IH enabled VF pages and
//		- the IH home page component, which calls it on behalf of the QAM etc on SF pages.
// --------------------------------------------------------------------------------------------------


	// 1.23 - more robust jQ alias, set below (not globally)
	var $IAIHj;


	function ClientSettingsLoader(ResponseFromVFPage){
		
		var overSubscribed = false;				// Control var: true where Org has exceeded its subscriptions
		var q=document.getElementById('IHQAM');	// The QAM
		var U;
		var XtnRoot = document.getElementById('IAIHChromexSFRoot');

		// Place settings returned from SF server somewhere we can get them
		document.getElementById('IAIHSettings').innerHTML = ResponseFromVFPage;

		// Extract improved help settings from the above
		GetOrgSettings();


		// Hide any browser extension "root"...
		if (XtnRoot + '' != 'null') {
			XtnRoot.style.display = 'none';
		}

		// If the only setting returned is one advising us that help is not available,
		// just hide the settings div and go no further
		if (IHSettings.length == 1) {
			if (IHSettings[0] == 'Help not available in this domain') {
				document.getElementById('IAIHSettings').style.display = 'none';
				
				// Hide the QAM in these cases, too:
				if (q + '' != 'null') {q.style.display = 'none';}
				return;
			}
		}

		
		// Check settings were found: just stop if not...
		if (IHSettings.length != numIHSettings) {
			// If there's an issue, report this in the side bar and stop
			var x = document.getElementById('IAIHSettings').innerHTML;

			// NB: if we fail to get settings, we cannot internationalise, so there's nothing we can do for this message
			document.getElementById('IAIHSettings').innerHTML = 'There was an error retrieving your Improved Help Settings. Please contact support. Click <a href="#" onclick="javascript:alert(\'' + x + '\');">HERE</a> for diagnostics.';
			
			document.getElementById('IAIHSettings').style.display = 'block';
			if(q) {q.style.display = 'none'};
			return;
		}
		
		
        // 1.23 - moved to allow noConflict options to be sought in settings 
		if ($IAIHj + '' == 'undefined') {
			if (IHSettings[jQNCMode] == 'true') {
				$IAIHj = jQuery.noConflict(true);
			} else {
				$IAIHj = jQuery.noConflict();
			}
		}
				
		
		// If license is OK, but licensing is per seat and user doesn't have one, fail "silently"...
		if (IHSettings[LSeats] != 'Unlimited' && IHSettings[isSeated] == 'false' && IHSettings[LStatusCode] == 'OK') {
			
			// "Silently" means: do no hooking and hide sidebar "as is"
			// (thereby hiding QAM etc)
			HideHookingComponent();
			document.getElementById('IAIHSettings').style.display = 'none';
			
			if(q) {q.style.display = 'none'};
			return;
		}
		
		
		// If license is NOT OK...
		if (IHSettings[LStatusCode] != 'OK') {

			// If license states over-subscription...
			if (IHSettings[LStatusCode] == 'InsufficientUsers') {	
				
				// Show the oversubscribed message...
				if (document.getElementById('IAIHOversubscribed')) {
					document.getElementById('IAIHOversubscribed').innerHTML = '<span class="IHError">' + Internationalise('[QAMAdviceLabelSeatAllocationExceeded]') + '<br/><a target="_Settings" href="' + IHSettings[SFURL] + '/apex/IHManageSettings?Cat=Subscription">' + Internationalise('[QAMButtonCheckSubscriptionDetails]') + '</a>.</span>';
					document.getElementById('IAIHOversubscribed').style.display = 'block';
				}
				overSubscribed = true;
				
				// We can tolerate this (continue to hook etc) as long as this is NOT free edition:
				// If it is, we stop here. Also, we should stop at this stage if we're not
				// seated and seat is required
				if (IHSettings[LType] == 'Free' || (IHSettings[LSeats] != 'Unlimited' && IHSettings[isSeated] == 'false')) {
					document.getElementById('IAIHSettings').style.display = 'none';
					if(q) {q.style.display = 'none'};
					return;
				}
				
			} else {
				// If there's an issue, report this in the side bar and stop
				var msg = Internationalise('[QAMAdviceLabelSubscriptionIssue]') + '<p/><p/>';
				msg += IHSettings[LStatus];
				msg += '<p/><p/><a target="_Settings" href="' + IHSettings[SFURL] + '/' + IHSettings[LFolder] + '">' + Internationalise('[QAMButtonSubscriptionFolderLink]') + '</a><p/>';
				
				// Onward link to deal with subscription issue depends on circumstances:
				if (IHSettings[LStatusCode] == 'Error' || IHSettings[LStatusCode] == 'InvalidOrg') {

					// No subscription doc or invalid org = go to fulfilment page
					msg += '<a target="_Blank" href="' + Internationalise('RequestTrialLink') + '">' + Internationalise('[QAMButtonSubscriptionTrialLink]') + '</a>.';
					
				} else {
					
					// Expired subscription = contact us
					msg += '<a target="_Blank" href="' + Internationalise('ContactUsLink') + '">' + Internationalise('[QAMButtonSubscriptionExtendTrialLink]') + '</a>.';
				}
				
				document.getElementById('IAIHSettings').innerHTML = msg;
				document.getElementById('IAIHSettings').style.display = 'block';
				if(q) {q.style.display = 'none'};
				return;
			}			
			
		} 

		
		// Assuming we get this far, take note of any incoming "view in place" instructions
		LogVIPs();
		
		
		// If we're Guide enabling set up Guide Enable mode. Order of events is:
		// QAM caused GE Entry -> search screen -> result click -> set selected RL cookie -> ControllerSettings sets mode
		// NB: do NOT set this mode if we're on the confirmation screen!
		if (IHSettings[HookMode] == 'GEnable' && document.location.href.toUpperCase().indexOf('/APEX/IHCONFIRMACTIONS?') == -1 && document.location.href.toUpperCase().indexOf('/APEX/IAHELP__IHCONFIRMACTIONS?') == -1) {
			configurePage('GEnable');
			
		} else {

			// If we're not guide enabling, just trigger improved help as usual
			HookHelp();			
/*
if (prompt('Continue?', 'Y') != 'Y') {
	return;
}			
*/			
			// Prepare the QAM for "read" mode use
			IHQAMenu.SetupQAM('Saved');

			
			// Show any post-Guide enabling screen: 
			// NB: do NOT do this from VF QAM - as mode switching is not supported
			// and we don't want 2x dialogues being shown if standard and VF QAMs are in use
			// Also, do NOT respond if we're on confirmation screen
			if (document.location.href.toUpperCase().indexOf('/APEX/IHQAM') == -1 && document.location.href.toUpperCase().indexOf('/APEX/IHCONFIRMACTIONS?') == -1
				&& document.location.href.toUpperCase().indexOf('/APEX/IAHELP__IHQAM') == -1 && document.location.href.toUpperCase().indexOf('/APEX/IAHELP__IHCONFIRMACTIONS?') == -1) {
				
				U = readCookie('IHSelectedGuide');
				if (U != null) {
					IHSetCookie('IHSelectedGuide', '', 0);						
					getGuideCoords();
					IHQAMenu.DoDialogue(U, guideX, guideY, guideW, guideH, '_Guide');						
				}				
			}
		}
		
		
		// If we've been instructed to close ourselves, update any (guide related) VIP cookie, 
		// so that any other step windows close themselves through the timed checkVIP process
		if (document.location.href.toUpperCase().indexOf('?IHCLOSEWINDOW') != -1) {
			IHSetCookie('IHQAMVIP', getTimeStamp() + settingsD1 + document.location.href, 1);
			window.close();
		}


		// Setup customer CSS
		if (document.getElementById('BrandCSS')) {
			document.getElementById('BrandCSS').href = IHSettings[BrandCSS];
		}

		// Once this has been done, we should adjust CSS paths in case of communities...
		IHCommunities.IAIHCPrefix = IHSettings[CPrefix];
		IHCommunities.IAIHInitialiseForCommunities(5);


		var U = document.location + '';	
		
		// REM: Console itself (the SF page) does NOT have a QAM - it's provided as a separate VF page...
		if(q || U.indexOf('ShowIHSettings') != -1  || IHQAMenu.isConsolePage) {
			
			// Hide side bar component and place QAM itself in main body of document 
			// (to avoid hiding the QAM with the component!)
			// Only hide side bar if we're NOT oversubscribed - otherwise just hide the settings within it
			if (overSubscribed == false) {
								
				// NB: Include a "back door" here to show settings by passing a query param if desired...
				if (U.indexOf('ShowIHSettings') == -1) {
					
					// 1.20: In case we're not in a sidebar, hide the hooking component itself where required
					// (as well as the settings DIV)
					document.getElementById('IAIHSettings').style.display = 'none';
					
					//prompt('CSL', document.getElementById('IAIHSettings').innerHTML);					
					
					HideHookingComponent();

				} else {
					document.getElementById('IAIHSettings').style.display = 'block';
				}
				
			} else {
				document.getElementById('IAIHSettings').style.display = 'none';
			}


			// Position QAM where present
			if (q) {				
				$IAIHj('#IHQAM').detach();		
				$IAIHj('body').append(q);
			}

		}
				
		// 1.42 - DEPRECATING AS CLASSIC GE MODE ALREADY REMOVED
/*
		// On arrival on any IH-enabled page, send message about location to any "opener" window (eg a guide)
		try {

			if (self != top) {				
				// If we're in an iframe, send message back to parent page to pass on.
				// We only want to do this if we're a guide step window. This means:
				// EITHER we can see (VF to VF) top window name and it is as we expect
				// OR we cannot see it (SF to VF)

				if (top.name == '_GuideStep' || top.name + '' == 'undefined') {
					// We also don't want to do this if we're sidebar QAM or a template: our "location" will
					// always be the same and not very useful...
					if (document.URL.toUpperCase().indexOf('/APEX/') == -1) {
						
						//alert('CSL:\n\n' + document.URL + '\n\nSelf NOT top: posting CXT to TOP');
						top.postMessage('GSCXT=' + document.URL.replace(document.location.search, ''), '*');			
					}
				}	
				
			} else {
				// If we're NOT an iframe, send message direct to opener
				//alert('CSL:\n\n' + document.URL + '\n\nSelf IS top: posting CXT to OPENER');
				window.opener.postMessage('GSCXT=' + document.URL.replace(document.location.search, ''), '*');	

			}
			
		} catch (e) {
			// This can happen in some browsers in cross domain situations - eg
			// access to "name" property of top window is denied:
			// Take this as a sign that we're SF trying to reach VF - so we want to
			// post a message...
			
			//alert('CSL:\n\n' +  document.URL + '\n\nErr - so posting CXT to TOP');			
			top.postMessage('GSCXT=' + document.URL.replace(document.location.search, ''), '*');

		}
*/
		
		return;
	}
	

	
// --------------------------------------------------------------------------------------------------
// Hide any component being used to embed help hooking mechanism (e.g., a sidebar or link)
// --------------------------------------------------------------------------------------------------
	function HideHookingComponent() {
		
		// NB: the settings DIV itself may or may not be embedded in the hooking component
		// (it may have been added by it separately - but not as a direct child)
		
		var l="#IAIHSettings";
		var isIHSB = false;
		
		try {
			if ($IAIHj(l).size() > 0) {
				
				// This will hide any sidebar component if it directly contains the settings div
				// (as in the old sidebar recipe)
				$IAIHj(l).parents(".sidebarModule").hide();				
				
				// Try to find component among sidebars
				$IAIHj(".sidebarModule").each(function() {					
					$IAIHj(this).find('.brandPrimaryFgr').each(function() {
						if ($IAIHj(this).text().match(/^Improved Help Links[.]*/i) != null) {
							isIHSB = true;
						}
					});
					
					if (isIHSB == true) {
						$IAIHj(this).hide();
						isIHSB = false;
					}
				});
				
				// Try to find link amoung custom links
				
				
			}

		} catch (e) {
			//alert('(Hide Hooking Component) - ' + e);
		}
		
		return;
	}
	
	
// --------------------------------------------------------------------------------------------------
// Obtain Org-wide IH settings array from settings string
// --------------------------------------------------------------------------------------------------
	function GetOrgSettings() {
	
		try {
			// NB: this relies on the Help Hook home page component which
			// should have called the script provided by the IHQAMSettings page
			// to populate this element...
			
			var IHSet = document.getElementById('IAIHSettings').innerHTML;	
			
			// Act of putting settings into a DIV (see ClientSettingsLoader) as innerHTML
			// will have HTML encoded things - so need to undo this here...
			IHSet = IHSet.split('&amp;').join('&');
			IHSet = IHSet.split('&AMP;').join('&');

			IHSettings = IHSet.split(String.fromCharCode(6));
			
			return true;
		
		} catch (e) {
			alert('(GetOrgSettings) - ' + e);
			return false;
		}
	}


// --------------------------------------------------------------------------------------------------
// Get guide window sizing information from cookie
// --------------------------------------------------------------------------------------------------
	function getGuideCoords() {
		
		// Set window sizing information for Guide Steps
		var CoOrds = readCookie('IHGuideCoOrds');
		
		if (CoOrds != null) {
			CoOrds = CoOrds.split(':');
		} else {
			CoOrds = '0:0:300:600';
			CoOrds = CoOrds.split(':');
		}
		
		guideX = CoOrds[0];
		guideY = CoOrds[1];
		guideW = CoOrds[2];
		guideH = CoOrds[3];

		return;			
	}
	

// --------------------------------------------------------------------------------------------------
// Function to advise caller whether or not user agent (client browser) is suitable for guides:
// IE8- cannot do inter-window messaging, so cannot be used
// 1.23: Console is NOT Guide compatible in the broad sense: 
// Any particular Guides to be made available via specific buttons or links
// --------------------------------------------------------------------------------------------------
	function isGuideCompatible() {
		if (navigator.appVersion.indexOf("MSIE 5") != -1 
				|| navigator.appVersion.indexOf("MSIE 6") != -1 
				|| navigator.appVersion.indexOf("MSIE 7") != -1 
				|| navigator.appVersion.indexOf("MSIE 8") != -1
				|| IHQAMenu.isConsolePage) {
			return false;
		} else {
			return true;
		}
	}	
	

// --------------------------------------------------------------------------------------------------
// Cookie reader function
// --------------------------------------------------------------------------------------------------
	function readCookie(name) {

		var nameEQ = name + "=";
		var ca = document.cookie.split(';');

		for(var i=0;i < ca.length;i++) {
			var c = ca[i];

			while (c.charAt(0)==' ') c = c.substring(1,c.length);
			if (c.indexOf(nameEQ) == 0) {
				return decodeURI(c.substring(nameEQ.length,c.length));
			}
		}
		return null;
	}
	
	
	
// --------------------------------------------------------------------------------------------------
// Cookie writer function
// --------------------------------------------------------------------------------------------------
	function IHSetCookie(name, value, exdays) {

		try {
			var exdate=new Date();
			exdate.setDate(exdate.getDate() + exdays);
			var c_value = encodeURI(value) + ((exdays==null) ? "" : "; expires="+exdate.toUTCString());
			c_value += "; path=/";
			document.cookie = name + "=" + c_value;
			
		} catch (e) {
			// This can fire in cross-namespace scenarios - seem to get a "toGRMString" error
			// when this isn't even being called!
			// Catch here and leave...
		}
		
		return;
	}	

	
// --------------------------------------------------------------------------------------------------
// Returns a timestamp in the form dd/mm/yyyy hh:mm:ss
// --------------------------------------------------------------------------------------------------	
	function getTimeStamp() {
		var d = new Date();
		var ts;
		
		ts = [d.getDate().padLeft(), (d.getMonth()+1).padLeft(), d.getFullYear().padLeft()].join('/') 
		ts += ' ' + [d.getHours().padLeft(), d.getMinutes().padLeft(), d.getSeconds().padLeft()].join(':');

		return ts;
	}	
	
// --------------------------------------------------------------------------------------------------
// Send a set of values to an IH "cache" cookie, filed under entryId
// --------------------------------------------------------------------------------------------------
	function cachePut(entryId, entryVal) {

		var putVal;
		var ckVals;
		var newVals;
		var valFound = false;
		var i;

		try {

			putVal = entryId + settingsD1 + entryVal;

			// Read the existing cache value
			ckVals = readCookie('IHGECache');

			if (ckVals != null) {

				// Split this into constituent parts
				ckVals = ckVals.split(settingsD2);

				// Check for named entry - edit or create as required
				for (i=0; i < ckVals.length - 1; i++) {

					if(ckVals[i].substring(0, entryId.length + 1) == entryId + settingsD1) {
						ckVals[i] = putVal;
						valFound = true;
						break;
					}
				}
				

				// Re-assemble total cache value 
				newVals = '';
				for (i=0; i < ckVals.length - 1; i++) {
					newVals += ckVals[i] + settingsD2;
				}

				// If the above did not find the requested element in the cache, we need to add it here
				if (valFound == false) {
					newVals += putVal + settingsD2;
				}


			} else {
				newVals = putVal + settingsD2;
			}

			IHSetCookie('IHGECache', newVals, 1);

			return true;

		} catch (e) {
			return false;
		}

	}

	
// --------------------------------------------------------------------------------------------------
// Retrieve the entire IH "cache" (cookie)
// --------------------------------------------------------------------------------------------------	
	function cacheGetAll() {
		return readCookie('IHGECache');
	}
	

// --------------------------------------------------------------------------------------------------
// Retrieve any entries from the IH "cache" cookie that match the specified id
// --------------------------------------------------------------------------------------------------	
	function cacheGet(entryId) {
		var ckVals; 
		var i;
		var retVals = new Array();

		try {

			// Read the existing cache value
			ckVals = readCookie('IHGECache');

			if (ckVals != null) {

				// Split this into constituent parts
				ckVals = ckVals.split(settingsD2);

				// Check for named entry
				for (i=0; i < ckVals.length - 1; i++) {
					
					// In checking, we need to take account of "new" guide steps 
					// (whose cache entries will be prefixed with a * )
					if(ckVals[i].substring(0, entryId.length + 1) == entryId + settingsD1
							|| ckVals[i].substring(0, entryId.length + 2) == '*' + entryId + settingsD1
					) {
						retVals.push(ckVals[i]);
					}
				}
			}

		} catch (e) {
			retVals = null;
		}

		return retVals;
	}
	

// --------------------------------------------------------------------------------------------------
// Remove the named element from the cache
// --------------------------------------------------------------------------------------------------	
	function cacheDelete(entryId) {
		
		var ckVals;
		var newVals;
		var valFound = false;
		var i;

		
		try {

			// Read the existing cache value
			ckVals = readCookie('IHGECache');

			if (ckVals != null) {

				// Split this into constituent parts
				ckVals = ckVals.split(settingsD2);

				// Re-assemble total cache, removing requested entry 
				newVals = '';
				for (i=0; i < ckVals.length - 1; i++) {
					
					// In checking for a value, we need to take account of "standard" cache entry signature
					// as well as "new" (where entry name will be preceded by "*")
					if(ckVals[i].substring(0, entryId.length + 1) != entryId + settingsD1
						&& ckVals[i].substring(0, entryId.length + 2) != '*' + entryId + settingsD1
						) {
						newVals += ckVals[i] + settingsD2;
					}
				}

			} else {
				return true;
			}

			IHSetCookie('IHGECache', newVals, 1);
			return true;

		} catch (e) {
			return false;
		}

	}
	
	
// --------------------------------------------------------------------------------------------------
// Returns the number of elements currently in the cache
// --------------------------------------------------------------------------------------------------	
	function cacheSize() {

		var ckVals; 
		var retVal;

		try {

			// Read the existing cache value
			ckVals = readCookie('IHGECache');

			if (ckVals != null) {

				// Split this into constituent parts and return entry count
				ckVals = ckVals.split(settingsD2);				
				retVal = ckVals.length - 1;
				
			} else {
				retVal = 0;
			}

		} catch (e) {
			retVal = 0;
		}

		return retVal;
		
	}
	
	
// --------------------------------------------------------------------------------------------------
// Sorts cache values by element "n", the ordinal position of an element stored in each cache value.
// This MUST be a numeric field (it will be renumbered starting at 1)
// --------------------------------------------------------------------------------------------------	
	function cacheSortAndRenumber(elemNum) {

		var ckVals;
		var rec;
		var flds;
		var flds2;
		var i;
		var j;
		

		try {

			// Read the existing cache value
			ckVals = readCookie('IHGECache');

			if (ckVals != null) {

				// Split this into constituent "records"
				ckVals = ckVals.split(settingsD2);

				// Loop around these records
				for (i=0; i < ckVals.length - 1; i++) {
					
					// Split each record into its "fields"
					rec = ckVals[i];
					flds = rec.split(settingsD1);
					
					// Reconstruct records, placing the requested field number at the start
					rec = flds[elemNum] + settingsD1;
					
					for (j=0; j<flds.length; j++) {
						if (j != elemNum) {
							rec += flds[j] + settingsD1;
						}
					}
					
					rec = rec.substring(0, rec.length - 1);					
					ckVals[i] = rec;
				}
				
				// Sort the resultant records on this basis
				ckVals.sort();
				
				// Clear the cache
				cacheClear();
				
				// Loop around sorted records to reconstruct
				for (i=0; i < ckVals.length - 1; i++) {

					// Split records into fields once more
					rec = ckVals[i];
					flds = rec.split(settingsD1);
					flds2 = new array('', '', '', '');
					
					// Reconstruct records in "correct" field order 
					for (j=1; j<=elemNum; j++) {
						flds2[j-1] = flds[j];
					}
					flds2[elemNum] = flds[0];
					for (j=elemNum + 1; j<=3; j++) {
						flds2[j] = flds[j];
					}
					
					// Save the results
					cachePut(flds[0], flds[1] + settingsD1 + flds[2] + settingsD1 + flds[3]);

				}
				
				
			}

			return true;
			
		} catch (e) {
			return false;
		}
	}

	
// --------------------------------------------------------------------------------------------------
// Empties the cache completely (by expiring the relevant cookie)
// --------------------------------------------------------------------------------------------------	
	function cacheClear() {
		IHSetCookie('IHGECache', null, 0);
		return;
	}
	
	
// --------------------------------------------------------------------------------------------------
// Replace internationalisation tokens in given content with translated content
// --------------------------------------------------------------------------------------------------	
	function Internationalise(strContent) {
				
		var retVal = strContent;
		
		
		try {
			var locs = IHSettings[Localisations];
			var i;
			var locParts;
	
			// See ControllerSettings.getIHSettings: this packs the string map of localisations
			// into a single string in the form:
			// key(char 7 delimiter)translated value(char 5 delimiter)
	
			if (locs != '') {
				locs = locs.split(String.fromCharCode(5));
				
				for (i=0; i < locs.length; i++) {
					locParts = locs[i].split(String.fromCharCode(7));
					
					if (locParts[1] + '' != 'undefined') {
						retVal = retVal.split(locParts[0]).join(locParts[1]);
					}
				}	
			}
			
		} catch (e) {
			
		}
		
		return retVal;
		
	}
	
	
// --------------------------------------------------------------------------------------------------
// Process a URL for passing as context in "safe" format
// --------------------------------------------------------------------------------------------------	
	function getSafeURL(uIn) {
		var uOut = uIn;
		
		// Remove any (editing related) confirmation token - as that used on the context page
		// will not be accepted by / applicable to the QAM settings page
		uOut = uOut.split('_CONFIRMATIONTOKEN=').join('IHCT=');
		return uOut;
	}
		
		
			