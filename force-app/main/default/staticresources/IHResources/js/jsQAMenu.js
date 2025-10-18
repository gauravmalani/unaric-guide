/////////////////////////////////////////////////////////////////////////////////////////////////////
// FUNCTIONS SUPPORTING THE IMPROVED HELP QUICK ACCESS MENU
//
// NB: These functions rely on making calls to those in the WebToolTips and ToggleHelp JS static resources
// NB: They also rely on settings variables provided by jsSettings.
// NB: They also rely on jQuery and crypto-js libraries: these are included in the QAM itself
// NB: They also rely on SF's console integration library: this MUST be included on pages using jsQAMenu
//
// Martin Little for Improved Apps
// June 2012
// Copyright (c.) Improved Apps Limited 2012. All Rights Reserved.
/////////////////////////////////////////////////////////////////////////////////////////////////////

"use strict";

(function(IHQAMenu, $, undefined) {

// --------------------------------------------------------------------------------------------------
// Boolean specifying that we're in a console situation
// --------------------------------------------------------------------------------------------------

	// NOTE: This can ONLY be relied upon when first opening a tab:
	// any navigation on the tab will "confuse" the API so location 
	// will be indistinguishable from any other context: 
	// Clients must make their own arrangements to deal with this issue.

	IHQAMenu.isConsolePage;
	
	if (typeof sforce != 'undefined') {
		if (!sforce.console) {
			IHQAMenu.isConsolePage = false;
		} else {
			IHQAMenu.isConsolePage = sforce.console.isInConsole();
		}		
	} else {
		// If we don't have library, look for tell-tale query parameters
		if (document.location.search.toUpperCase().indexOf('ISDTP=') != -1) {
			IHQAMenu.isConsolePage = true;
		} else {
			IHQAMenu.isConsolePage = false;
		}
	}
	

// --------------------------------------------------------------------------------------------------
// Open a new console tab
// --------------------------------------------------------------------------------------------------
	IHQAMenu.openPrimaryTab = function (U, tTitle) {
		try {
        	sforce.console.openPrimaryTab(null, U, true, tTitle);
        	
		} catch (e) {
			alert(e);
		}
	}   


// --------------------------------------------------------------------------------------------------
// Send message requesting VIP link for a given element (cf jsCalloutHost)
// --------------------------------------------------------------------------------------------------
	IHQAMenu.requestVIPLink = function (caller, msg) {
		
		if(caller==top) {
			// We really shouldn't show the share link in these cases as it has no meaning
			// (One would just share the URL). However, we can't internationalise this
			// message very easily - without adding additional script (Settings) to all
			// callouts, and making message available in translations.
			// As at 1.23: not thought worth the cost/benefit - just issue no message
			
		} else {
			top.postMessage('copyVIPLink=IHVIP=' + msg, '*');
		}
				
		return;
	}



// --------------------------------------------------------------------------------------------------
// Toggle the visibility (on-screen position) of the quick access menu as its "handle" is activated
// --------------------------------------------------------------------------------------------------
	IHQAMenu.moveQAM = function () {

		var x = document.getElementById('IHQAM');
		var y = document.getElementById('IAIHQAMHandle');
		var z = document.getElementById('QAMHandleLink');

		if (x.style.right == '0px') {
			// QAM currently open - so close
			$IAIHj("#IHQAM").animate({right:'-=148px'}, 'slow');
			y.className = 'QAMHandleClosed';
			z.title = Internationalise('[QAMTipHandle]');
			
			// v1.41+ : Closing QAM should hide available guides sub-menu, where present/open
			try {
				var rowGL = document.getElementById ('QAMGuideListing');			
				rowGL.style.display = 'none';
			} catch (e) {}
			
		} else if (x.style.right == '-148px' || x.style.right == '') {
			// QAM is closed - so open
			$IAIHj("#IHQAM").animate({right:'+=148px'}, 'slow');
			y.className = 'QAMHandleOpen';
			z.title = Internationalise('[QAMTipHandleClose]');
		}
		
		return;
	} 

	
// --------------------------------------------------------------------------------------------------
// Give GUI clues on the QAM suited to the operation being performed
//
// mode			= String indicating one of several known operating modes that the QAM can be in
//
// Returns nothing
// --------------------------------------------------------------------------------------------------	
	IHQAMenu.SetupQAM = function (mode) {
		
		// Embed localisations (translated labels, tips etc) into QAM
		var locs = IHSettings[Localisations];
		var i;
		var locParts;

		// Call Settings function to parse out internationalisation tokens from the QAM
		// Only do this where QAM is present
		var Q     = document.getElementById('IHQAM')
		if (Q + '' != 'null') {

			var theQAM = Q.innerHTML;
			theQAM = Internationalise(theQAM);		
			
			// Having made all translation replacements, re-set the entire contents of the QAM
			Q.innerHTML = theQAM;			
		}
		
		
		// Switch appearance to LUX if required
		if (IHSettings[BrandUXOption] == '3') {
			$IAIHj(Q).addClass('IHLUX');
		}
		
		
		var rowO  = document.getElementById('QAMRowHome');
		var rowM  = document.getElementById('QAMRowComment');
		var rowG  = document.getElementById('QAMRowGuides');
		var rowE  = document.getElementById('QAMRowModeGEnable');
		var rowS  = document.getElementById('QAMRowModeSave');
		var rowH  = document.getElementById('QAMRowModeHelp');
		var rowT  = document.getElementById('QAMRowModeStat');
		var rowC  = document.getElementById('QAMRowModeConf');
		var rowR  = document.getElementById('QAMRowModeReCon');		
		var tools = document.getElementById('QAMConfigurationTools');
		var aVIP  = document.getElementById('QAMGuideStepInfo');
		

		// Add listeners to re-cue help hooking (in case
		// hooking happened too soon - (despite doc ready!) - so not all
		// helpables were present on load
		
		// Do this only where admin has specified this for the layout
		// (requires num times and interval to be set, will be provided comma separated)
		if (IHSettings[RepeatHooking] != '0,0') {
						
			var RH = IHSettings[RepeatHooking].split(',');
			HooksDone = 0;
			HooksMax= RH[0];
			
			IHQAMenu.HookRepeater = window.setInterval("IHQAMenu.doRepeatHook()", RH[1]);
		}
		
		
		// NB: this cookie and IHVIP set as required via HookHelp -> LogVIPs
		var c = readCookie('IHQAMAwait');
		var isGuidePage = (IHVIP != '' && IHVIP != null) || (c != '' && c != null);
		

		// Proceed only where QAM is present
		if (rowO + '' == 'null' || rowM + '' == 'null' || rowS + '' == 'null' || rowH + '' == 'null' || rowT + '' == 'null' || rowC + '' == 'null' || rowR + '' == 'null' || rowE + '' == 'null') {
			return;
		}
		

		// Show home page link only where a default help topic has been specified
		if (IHSettings[defaultHTSet] == 'true') {
			rowO.style.display = 'block';
		} else {
			rowO.style.display = 'none';
		}
		
		
		// Show comments only where there is a helped page layout to comment on and it allows comments
		if (IHSettings[HPLExists] == 'true' && IHSettings[AllowComments] == 'true') {
			rowM.style.display = 'block';
		} else {
			rowM.style.display = 'none';
		}
		
		
		// Show Guides link only if Guides exist for this page and browser supports
		if (IHSettings[GuidesExist] == 'true' && isGuideCompatible() == true) {
			rowG.style.display = 'block';
		} else {
			rowG.style.display = 'none';
		}

		
		// Help Settings visible only to admins
		if (IHSettings[isAdministrator]  == 'true') {
			rowC.style.display = 'block';
		} else {
			rowC.style.display = 'none';
		}
	
		
		// Switch to help-enable mode = admins or authors
		if (IHSettings[isAuthor] == 'true' || IHSettings[isAdministrator]  == 'true') {
			rowH.style.display = 'block';
		} else {
			rowH.style.display = 'none';
		}
		
		
		// Switch to help-reconfigure mode = admins or authors, and only where helped elements exist 
		if ((IHSettings[isAuthor] == 'true' || IHSettings[isAdministrator]  == 'true') && IHSettings[HEs].length > 0) {
			rowR.style.display = 'block';
		} else {
			rowR.style.display = 'none';
		}
		
		
		// Switch to Guide Enable mode = admins or authors plus supported browser
		if ((IHSettings[isAuthor] == 'true' || IHSettings[isAdministrator]  == 'true') && isGuideCompatible() == true) {
			rowE.style.display = 'block';
		} else {
			rowE.style.display = 'none';
		}

		
		// Switch to stats mode = analysts only, and only where helped elements exist to track
		if (IHSettings[isAnalyst] == 'true' && IHSettings[HEs].length > 0) {
			rowT.style.display = 'block';
		} else {
			rowT.style.display = 'none';
		}
		
		
		// Guide step information only required when in "Await VIP" state
		if (c != '' && c != null) {			
			// Store the required step info in a hidden DIV for use elsewhere in step menus
			aVIP.innerHTML = IHQAMenu.getGuideLinks(c);			
		}
		
		
		// 1.42 - DEPRECATING AS CLASSIC GE MODE ALREADY REMOVED
		// If in Guide mode...
/*
		if (1==1) {
						
			// Set hook to record size/position of this window 
			$IAIHj(window).resize(function() {	
				var CoOrds = window.screenX + ':' + window.screenY + ':' + window.outerWidth + ':' + window.outerHeight;
				
				try {					
					if (self != top) {
						top.postMessage('GSSize=' + CoOrds, '*');						
					} else {
						window.opener.postMessage('GSSize=' + CoOrds, '*');
					}
										
				} catch (e) {
				}
				
			});
		}
*/		

		// Now setup whichever elements are visible according to requested mode
		switch (mode.toUpperCase()) {
			case 'CONFIGURE':
				rowH.disabled = true;
				if (rowH.className.indexOf(" Active")== -1) {rowH.className += " Active";}
				rowH.className = rowH.className.replace(" Unavailable", "");			
				
				rowS.disabled = false;
				rowS.className = rowS.className.replace(" Active", "");			
				rowS.className = rowS.className.replace(" Unavailable", "");			
				
				rowT.disabled = true;
				rowT.className = rowT.className.replace(" Active", "");			
				if (rowT.className.indexOf(" Unavailable")== -1) {rowT.className += " Unavailable";}
	
				rowR.disabled = true;
				rowR.className = rowR.className.replace(" Active", "");			
				if (rowR.className.indexOf(" Unavailable")== -1) {rowR.className += " Unavailable";}

				rowE.disabled = true;
				rowE.className = rowE.className.replace(" Active", "");			
				if (rowE.className.indexOf(" Unavailable")== -1) {rowE.className += " Unavailable";}

				break;
				
			case 'RECON':
				rowH.disabled = true;
				rowH.className = rowH.className.replace(" Active", "");
				if (rowH.className.indexOf(" Unavailable")== -1) {rowH.className += " Unavailable";}
				
				rowS.disabled = false;
				rowS.className = rowS.className.replace(" Active", "");			
				rowS.className = rowS.className.replace(" Unavailable", "");			
	
				rowT.disabled = true;			
				rowT.className = rowT.className.replace(" Active", "");
				if (rowT.className.indexOf(" Unavailable")== -1) {rowT.className += " Unavailable";}

				rowR.disabled = true;
				if (rowR.className.indexOf(" Active")== -1) {rowR.className += " Active";}
				rowR.className = rowR.className.replace(" Unavailable", "");			

				rowE.disabled = true;
				rowE.className = rowE.className.replace(" Active", "");			
				if (rowE.className.indexOf(" Unavailable")== -1) {rowE.className += " Unavailable";}

				break;

			case 'SAVED':
				rowH.disabled = false;
				rowH.className = rowH.className.replace(" Active", "");
				rowH.className = rowH.className.replace(" Unavailable", "");			
				
				rowS.disabled = true;
				if (rowS.className.indexOf(" Active")== -1) {rowS.className += " Active"};
				rowS.className = rowS.className.replace(" Unavailable", "");			

				rowT.disabled = false;			
				rowT.className = rowT.className.replace(" Active", "");
				rowT.className = rowT.className.replace(" Unavailable", "");			

				rowR.disabled = false;
				rowR.className = rowR.className.replace(" Active", "");			
				rowR.className = rowR.className.replace(" Unavailable", "");			

				rowE.disabled = false;
				rowE.className = rowE.className.replace(" Active", "");			
				rowE.className = rowE.className.replace(" Unavailable", "");			
				
				break;
				
			case 'STATS':
				rowH.disabled = true;
				rowH.className = rowH.className.replace(" Active", "");
				if (rowH.className.indexOf(" Unavailable")== -1) {rowH.className += " Unavailable";}

				rowS.disabled = false;
				rowS.className = rowS.className.replace(" Active", "");
				rowS.className = rowS.className.replace(" Unavailable", "");			
	
				rowT.disabled = true;			
				if (rowT.className.indexOf(" Active")== -1) {rowT.className += " Active";}
				rowT.className = rowT.className.replace(" Unavailable", "");			

				rowR.disabled = true;
				rowR.className = rowR.className.replace(" Active", "");			
				if (rowR.className.indexOf(" Unavailable")== -1) {rowR.className += " Unavailable";}

				rowE.disabled = true;
				rowE.className = rowE.className.replace(" Active", "");			
				if (rowE.className.indexOf(" Unavailable")== -1) {rowE.className += " Unavailable";}
				
				break;
	
			case 'GENABLE':
			case 'GENABLEENTRY':
				rowH.disabled = true;
				rowH.className = rowH.className.replace(" Active", "");
				if (rowH.className.indexOf(" Unavailable")== -1) {rowH.className += " Unavailable";}

				rowS.disabled = false;
				rowS.className = rowS.className.replace(" Active", "");
				rowS.className = rowS.className.replace(" Unavailable", "");			
	
				rowT.disabled = true;
				rowT.className = rowT.className.replace(" Active", "");			
				if (rowT.className.indexOf(" Unavailable")== -1) {rowT.className += " Unavailable";}

				rowR.disabled = true;
				rowR.className = rowR.className.replace(" Active", "");			
				if (rowR.className.indexOf(" Unavailable")== -1) {rowR.className += " Unavailable";}

				rowE.disabled = true;			
				if (rowE.className.indexOf(" Active")== -1) {rowE.className += " Active";}
				rowE.className = rowE.className.replace(" Unavailable", "");			
				
				break;
	
			default:
				// Do nothing if mode is un-recognised
		}
		
		
		// Now, having shown / hidden / enabled / disabled particular tools, we
		// can show or hide the configuration area as a whole:

		// V1.15: Config items can be used whilst editing SF records (no need for CheckPageType==0).
		// Helpable elements must exist.
		// V1.16: Config items should not be visible if we're viewing a Guide
		if (hasHelpableElements == true && isGuidePage == false) {
			if (IHSettings[isAuthor] == 'true' || IHSettings[isAdministrator] == 'true' || IHSettings[isAnalyst] == 'true') {
				tools.style.display = 'block';
			} else {
				tools.style.display = 'none';
			}
		
		} else {
			tools.style.display = 'none';
		}
			
		
		
		// Changing QAM mode should also hide any tip frame that may be in use.
		// NB: we should not be changing mode on a guide page and stopping tips in these
		// cases would close any first manual step callout (opened by virtue of building the 
		// guide links, above)...
		if (isGuidePage == false) {
			IHWebToolTips.StopTips('tfrm');
		}
		
		
		// Setting up of QAM should also style outer container's height, so that, when closed,
		// the QAM does not overlay or interfere with other page elements
		Q.style.height = '10px';
					
		return;
	}

	
// --------------------------------------------------------------------------------------------------
// Build View In Place QAM links based on Await VIP cookie contents
// NB: cookie format set in IHReadingListViewer page (as query parameter to viewed page -> LogVIPs -> cookie)
// --------------------------------------------------------------------------------------------------
	IHQAMenu.getGuideLinks = function (cookieString) {
		
		var retVal = '';						// Guide step menu to return
		var i;									// For looping
		var VIPs = cookieString;				// Array of VIP step information
		var VIP;								// Array of settings from a single VIPs element
		var D1 = String.fromCharCode(7);		// Delimiter
		var D2 = String.fromCharCode(5);		// Delimiter
		var elemId = '';						// Id to use for a guide step link
		var LastClicked = '';					// Marker for first element in step list
		var HTMSafeStepTitle;					// Guide step title prepared for use in mark up (eg link titles)
		var JSSafeStepTitle;					// Guide step title prepared for use in JS calls

		var JSSafeStepBody;						// Guide step body text prepared for use in JS calls
		var JSSafeStepImage;					// Guide step image URL prepared for use in JS calls
		var JSSafeStepVideo;					// Guide step video URL prepared for use in JS calls
		
		// Note whether we're in LUX mode as far as guides are concerned
		// NB: setting can be one of several that indicate LUX flavour guides are to be used
		var LuxGuideMode = IHSettings[BrandUXOption];
		if (LuxGuideMode > '1') {LuxGuideMode = true;} else {LuxGuideMode = false;}
		
				
		// Decrypt the VIP step info passed from the cookie string
		VIPs = CryptoJS.AES.decrypt(VIPs, "AwaitVIP");
		VIPs = VIPs.toString(CryptoJS.enc.Utf8);		
		VIPs = VIPs.split(D2);
		
		
		try {
			// Note total number of steps in play (defined in jsToggleHelp)
			totalLocalSteps = VIPs.length - 1;
			
			// Make a set of links to each guide step:
			// Format depends on whether we're in classic or LUX mode plus guide type	
			
			if (LuxGuideMode == true && IHVIPRLType == 2) {
				retVal = '<select class="slds-input" onchange="javascript:showStep(this.options[this.selectedIndex].value, \'' + D1 + '\');">'
				for (i=0; i < VIPs.length; i++) {
					
					VIP = VIPs[i].split(D1);
					
					if (VIP[0] != '') {
						VIP[0] = encodeURI(VIP[0]);
						elemId = 'GSM' + VIP[0].split(' ').join('_');
						HTMSafeStepTitle = VIP[3].split('"').join('&quot;');
						retVal += '<option value="' + VIPs[i] + '">' + HTMSafeStepTitle + '</option>';
					}

					// Cue the first VIP 
					if(i==0) {
						try{
							showStep(VIPs[i], D1);
							
						} catch (e){
							alert('(Get Guide Links (cue VIP)) - ' + e);
						}
					}
				
				}
				retVal += '</select>';
				
				
			} else {
				retVal = '<div class="IHPanelBody"><table>';
				
				for (i=0; i < VIPs.length; i++) {
					VIP = VIPs[i].split(D1);
					
					// Initially (until a user clicks elsewhere in step list)
					// mark the first step as "current" - and thus also effectively "clicked"
					if (i==0) {
						LastClicked = ' Current Clicked';
					} else {
						LastClicked = '';
					}
					
					if (VIP[0] != '') {
	
						// We need to escape in case of "odd" characters in elem ids etc
						VIP[0] = encodeURI(VIP[0]);
						elemId = 'GSM' + VIP[0].split(' ').join('_');
						HTMSafeStepTitle = VIP[3].split('"').join('&quot;');
						JSSafeStepTitle = VIP[3].split('\'').join('');

						JSSafeStepBody = VIP[5].split('\'').join('');
						JSSafeStepBody = JSSafeStepBody.split('"').join('&quot;');
						
						JSSafeStepImage = VIP[6].split('\'').join('');
						JSSafeStepVideo = VIP[7].split('\'').join('');
						
						
						// Add a DIV with link to cue this step
						// Step title here used in anchor title, so use web safe version...
						retVal += '<tr><td><div id="' + elemId + '" class="GuideStep Manual' + LastClicked + '"><div class="IHIcon"></div><a title="' + HTMSafeStepTitle + '" href="javascript:void(0);" ';					
	
						// Step title here used as parameter to JS, so use JS Safe version
						retVal += 'onclick="javascript:cueVIP(\'' + VIP[0] + '\', \'' + VIP[1] + '\', \'' + VIP[2] + '\', \'' + encodeURI(JSSafeStepTitle) + '\', \'' + VIP[4] + '\', \'' + elemId + '\', \'' + encodeURI(JSSafeStepBody) + '\', \'' + encodeURI(JSSafeStepImage) + '\', \'' + encodeURI(JSSafeStepVideo) + '\');">'; 
						
						
						retVal += VIP[3]; 
						retVal += '</a></div>';
						
						// Add a hidden DIV with information for this step
						retVal += '<div style="display: none;">';

						retVal += '<div id="GSMVIPId' + i + '">' + VIP[0] + '</div>';
						retVal += '<div id="GSMElemType' + i + '">' + VIP[1] + '</div>';
						retVal += '<div id="GSMHTID' + i + '">' + VIP[2] + '</div>';
						retVal += '<div id="GSMVPrompt' + i + '">' + encodeURI(VIP[3]) + '</div>';
						retVal += '<div id="GSMShowCallout' + i + '">' + VIP[4] + '</div>';
						retVal += '<div id="GSMStepDivId' + i + '">' + elemId + '</div>';
						retVal += '<div id="GSMVBodyText' + i + '">' + VIP[5] + '</div>';
						retVal += '<div id="GSMVImage' + i + '">' + VIP[6] + '</div>';
						retVal += '<div id="GSMVVideo' + i + '">' + VIP[7] + '</div>';
																		
						retVal += '</div>';
						
						retVal += '</td></tr>';	
						
						// Cue the first VIP 
						if(i==0) {
							try{
								cueVIP(VIP[0], VIP[1], VIP[2], encodeURI(VIP[3]), VIP[4], elemId, encodeURI(VIP[5]), encodeURI(VIP[6]), encodeURI(VIP[7]));
								
							} catch (e){
								alert('(Get Guide Links (cue VIP)) - ' + e);
							}
						}

					}
				}
	
				retVal += '</table></div>';
			}
			
			
		} catch (e) {
			retVal = '(Get Guide Links) - ' + e;
		}
		
		return retVal;
	}
	
	
// --------------------------------------------------------------------------------------------------
// QAM Menu item functions: go to settings page
// --------------------------------------------------------------------------------------------------
	IHQAMenu.showSettings = function () { 
		
		var U = IHSettings[SFURL];
		U += '/apex/iahelp__IHManageSettings'; 

		
		// If we're a console page, launch search results screen in console tab
		if (IHQAMenu.isConsolePage == true) {
			
			// Add parameter to the search screen reflecting this
			// such that results will be sent to a console tab
			// NB: this is a parameter that SF seems to use for console tabs: 
			// c.f. ControllerSettings.isConsolePage 
			U += '?isdtp=IHAdded';
			
			IHQAMenu.openPrimaryTab (U, 'Help Settings');
			
		} else {
			// This is required in a new window if we're in the VF QAM
			if (document.URL.toUpperCase().indexOf('/APEX/IHQAM') != -1 || document.URL.toUpperCase().indexOf('/APEX/IAHELP__IHQAM') != -1) {
				window.open(U, '_blank');
				
			} else {
				// Settings required in standard iframe dialogue if in standard QAM				
				document.location = U;
				
				// Close QAM
				IHQAMenu.moveQAM();			
			}

		}
						
		return; 
	} 
 

// --------------------------------------------------------------------------------------------------
// QAM Menu item functions: show search (results) window
// --------------------------------------------------------------------------------------------------
	IHQAMenu.showHelp = function (evt) { 
		
		var U = IHSettings[SFURL];
		var O = IHSettings[SFObjId];
		U += '/apex/iahelp__IHSearchResults?objId=' + O; 
		

		// If we're a console page, launch search results screen in console tab
		if (IHQAMenu.isConsolePage == true) {
			
			// Add parameter to the search screen reflecting this
			// such that results will be sent to a console tab
			// NB: this is a parameter that SF seems to use for console tabs: 
			// c.f. ControllerSettings.isConsolePage 
			U += '&isdtp=IHAdded';
			
			IHQAMenu.openPrimaryTab (U, 'Search Help');
			
		} else {
			// Search required in a browser dialogue if we're in the VF QAM
			if (document.URL.toUpperCase().indexOf('/APEX/IHQAM') != -1 || document.URL.toUpperCase().indexOf('/APEX/IAHELP__IHQAM') != -1) {
				IHQAMenu.DoVFQAMDialogue(U, 500, 355, 'IHQAMDialogue');
				
			} else {
				// Search required in standard iframe dialogue if in standard QAM
				IHWebToolTips.DoTips("dfrm", U, "7", 300, 355, evt);			
	
				// Close QAM
				IHQAMenu.moveQAM();		
			}
			
		}
				
		return; 
	} 
	
	
// --------------------------------------------------------------------------------------------------
// QAM Menu item functions: show available help guides as a clickable list in QAM
// --------------------------------------------------------------------------------------------------	
	
	// Listing clickable
	IHQAMenu.toggleGuideListing = function (evt) { 
		
		var rowGL = document.getElementById ('QAMGuideListing');
		var GInfos = IHSettings[GuidesList];
		var GInfo;
		var GLink;
		var GListing;
		var i;
		
		GInfos = GInfos.split(settingsD1);
		
		GListing = '<ul class="QAMGuideList">';
		
		for (i=0; i<GInfos.length -1; i++) {
			GInfo = GInfos[i].split(settingsD2);
			
			GLink = '<li class="QAMGuideListing" style="cursor: pointer;" onclick="javascript:IHQAMenu.runGuide(\'' + GInfo[0] + '\',' + GInfo[3] + ')" ';
			GLink += 'title="' + GInfo[2] + '">';
			GLink += GInfo[1];
			GLink += '</li>';
			GListing += GLink;
		}
		
		GListing += '</ul>';

		if (rowGL.style.display == 'none') {
			rowGL.innerHTML = GListing;
			rowGL.style.display = 'block';
		} else {
			rowGL.style.display = 'none';
		}
		
		return;
	}
	
	// Wrapper called by the above allowing QAM to be closed on guide listing item click
	IHQAMenu.runGuide = function (GID, Typ) {
		HookAndCueGuide(GID, Typ);
		IHQAMenu.toggleGuideListing();
		IHQAMenu.moveQAM();
	}

// --------------------------------------------------------------------------------------------------
// QAM Menu item functions: [DEPRECATED] show available help guides in a popup (VF) dialogue
// --------------------------------------------------------------------------------------------------
	
    // Function to actually show guides in a fashion appropriate to SF UI type in use
	IHQAMenu.showGuides = function (evt) { 
		
		var U = IHSettings[SFURL];
		var O;
		U += '/apex/iahelp__IHSearchResults?Opts=5&Term=*&Srch=3';
		 
		
		// If we're a console page, launch Guides list (search results) screen in console tab
		if (IHQAMenu.isConsolePage == true) {
			
			// Ensure a primary tab has been selected (so guided object is known)
			if (guideObj == '') {
				alert (Internationalise('[QAMMessageGuidesNotAvailable]'));
				
			} else {
				O = guideObj.substring(0, 3);
				U += '&objId=' + O;
				U += '&IHContext=' + document.URL;	
								
				// Add parameter to the search screen reflecting this
				// such that results will be sent to a console tab
				// NB: this is a parameter that SF seems to use for console tabs: 
				// c.f. ControllerSettings.isConsolePage 
				U += '&isdtp=IHAdded';
				
				IHQAMenu.openPrimaryTab (U, 'Guides');	
				guideObj = '';
			}				
						
		} else {
			
			// If not in console, guide object can be taken direct from our IH settings
			O = IHSettings[SFObjId];
			U += '&objId=' + O + '&IHContext=' + document.URL;
							
			// Guides list required in a browser dialogue if we're in the VF QAM
			if (document.URL.toUpperCase().indexOf('/APEX/IHQAM') != -1 || document.URL.toUpperCase().indexOf('/APEX/IAHELP__IHQAM') != -1) {
				IHQAMenu.DoVFQAMDialogue(U, 500, 355, 'IHQAMDialogue');
			} else {
				
				// Guides list required in dialogue iframe if in standard SF
				IHWebToolTips.DoTips("dfrm", U, "7", 300, 355, evt);			
	
				// Close QAM
				closeQAM();
			}					
		}		
		
		return; 
	} 
	
	
// --------------------------------------------------------------------------------------------------
// QAM Menu item functions: show Help Home Page
// --------------------------------------------------------------------------------------------------
	IHQAMenu.showHelpHome = function () { 
		var U = IHSettings[SFURL];
		
		//NB: use of tools page without specifying HTID etc should result in "default" page, as desired
		U += '/apex/iahelp__' + IHSettings[PortalPage]; 
		
		if (IHQAMenu.isConsolePage == true) {
			// In console situations, open as a new console tab
			IHQAMenu.openPrimaryTab(U, 'Help Home');
			
		} else {
			// In standard situations, use a new window
			window.open(U, '_blank');
			
		}
		
		
		if (document.URL.toUpperCase().indexOf('/APEX/IHQAM') == -1 && document.URL.toUpperCase().indexOf('/APEX/IAHELP__IHQAM') == -1) {
			// Close QAM
			IHQAMenu.moveQAM();			
		}
		
		
		return; 
	} 
	
	
// --------------------------------------------------------------------------------------------------
// QAM Menu item functions: log a comment
// --------------------------------------------------------------------------------------------------
	IHQAMenu.pageComment = function (evt) { 
		
		var U = IHSettings[SFURL];
		var O;
		
		if(!evt) evt = window.event;
		
		// Source of the object / layout info for the current page varies depending on SF GUI in use...		
		if (IHQAMenu.isConsolePage == true) {
			if (guideObj == '') {
				// 1.23: don't bother internationalise this:
				// Situation should not arise in console as Comment link is always hidden on QAM
				// because, in VF page's view of context, there is no helped page layout (i.e., for IHQAM itself)
				//alert ('Please open and select a primary tab to show related guides.');
				return;
				
			} else {
				O = guideObj.substring(0, 3);
			}
			
		} else {
			// In standard UI, our settings have object info
			O = IHSettings[SFObjId];
		}
		
		U += '/apex/iahelp__IHComment?PL=' + O; 
		
		// This is required in a browser dialogue if we're in the VF QAM
		if (document.URL.toUpperCase().indexOf('/APEX/IHQAM') != -1 || document.URL.toUpperCase().indexOf('/APEX/IAHELP__IHQAM') != -1) {
			IHQAMenu.DoVFQAMDialogue(U, 500, 208, 'IHQAMDialogue');
		} else {
			IHWebToolTips.DoTips("dfrm", U, "7", 300, 208, evt);

			// Close QAM
			IHQAMenu.moveQAM();
		}
				
		return; 
	}   
	
	
// --------------------------------------------------------------------------------------------------
// QAM Menu item functions: show bookmarks
// --------------------------------------------------------------------------------------------------
	IHQAMenu.showBookmarks = function (evt) {
		
		var U = IHSettings[SFURL];
		U += '/apex/iahelp__IHManageBookmarks'; 

		
		// If we're a console page, launch dialogue in console tab
		if (IHQAMenu.isConsolePage == true) {
			
			// Add parameter to the search screen reflecting this
			// such that results will be sent to a console tab
			// NB: this is a parameter that SF seems to use for console tabs: 
			// c.f. ControllerSettings.isConsolePage 
			U += '?isdtp=IHAdded';
			
			IHQAMenu.openPrimaryTab (U, 'My Bookmarks');
			
		} else {
			// This is required in a browser dialogue if we're in the VF QAM
			if (document.URL.toUpperCase().indexOf('/APEX/IHQAM') != -1 || document.URL.toUpperCase().indexOf('/APEX/IAHELP__IHQAM') != -1) {
				IHQAMenu.DoVFQAMDialogue(U, 500, 260, 'IHQAMDialogue');
				
			} else {
				// Or standard iframe dialogue if via SF / standard QAM
				IHWebToolTips.DoTips("dfrm", U, "7", 200, 260, evt);		
	
				// Close QAM
				IHQAMenu.moveQAM();
			}

		}		
				
		return; 
	}   
	

// --------------------------------------------------------------------------------------------------
// Utility functions: open a browser window or console primary tab dependent on SF context
// --------------------------------------------------------------------------------------------------
	IHQAMenu.DoTab = function (U, WinName, tTitle) {

		try {
			if (IHQAMenu.isConsolePage == true) {
				// In console situations, open as a new console tab
				IHQAMenu.openPrimaryTab(U, tTitle);
			} else {
				// In standard situations, use a new window
				window.open(U, WinName);
			}
			
		} catch (e) {
			alert('(Do Tab) - ' + e);
		}
		
		return;
	}
	
// --------------------------------------------------------------------------------------------------
// Utility functions: create a "dialogue" browser window positioned per supplied X/Y co-ordinates
// --------------------------------------------------------------------------------------------------
	IHQAMenu.DoDialogue = function (U, X, Y, W, H, WinName) {
		
		var win;	
		//prompt('DoDialogue', 'U=' + U + ': X=' + X + ': Y=' + Y + ': W=' + W + ': H=' + H);				
		
		try {			
			win = window.open(U, WinName, 'width=' + W + ', height=' + H + ', left=' + X + ', top=' + Y + ', menubar=0, resizable=1, status=0, toolbar=0, titlebar=0, location=0');

			// At this stage, window will be open - but at its old size / position if it had been
			// opened previously: so, attempt move/size here...
			
			win.resizeTo(W, H);
			win.moveTo(X, Y);
			win.focus();

		} catch (e) {		
			//alert('DoDialogue error: ' + e);
		}
		
		return win;
	}

	
// --------------------------------------------------------------------------------------------------
// Utility functions: create a "dialogue" browser window positioned per mouse
// --------------------------------------------------------------------------------------------------
	IHQAMenu.DoVFQAMDialogue = function (U, W, H, WinName, evt) {
		
		var T;
		var L;
		var win;
		
		try {
			if(!evt) evt = window.event;
			
			try {
				T = evt.screenY;
				L = evt.screenX + 100;
			} catch (e) {
				T = 100;
				L = 150;
			}
			
			if(T + '' == 'undefined') {
				T=100;
				L=150;
			}
			
			win = window.open(U, WinName, 'width=' + W + ', height=' + H + ', left=' + L + ', top=' + T + ', menubar=0, resizable=1, status=0, toolbar=0, titlebar=0, location=0');

			// At this stage, window will be open - but at its old size / position if it had been
			// opened previously: so, attempt move/size here...
			
			win.resizeTo(W, H + 100);
			win.moveTo(L, T);
			win.focus();

		} catch (e) {			
			//alert('Error attempting to open a dialogue screen: please ensure your browser allows popup windows from this site. ' + e);
		}
		
		return win;
	}

	
// --------------------------------------------------------------------------------------------------
// Derive the correct root address (incl. IH namespace) from a given (SF or VF) URL
// --------------------------------------------------------------------------------------------------
	IHQAMenu.getVFRoot = function (U) {
		
		var retVal = '';
		var root = '';
		var nspace = 'iahelp';
		var pod = '';
		var myDomain = '';
		var protocol = 'https://'
		
	
		try {
			// Chop protocol and any query string from URL to be considered
			root = U;
			root = root.replace(protocol, '');
			if (root.indexOf('?') != -1) {
				root = root.substring(0, root.indexOf('?'));
			}
			
			// Chop off any path beyond host from URL to be considered
			if (root.indexOf('/') != -1) {
				root = root.substring(0, root.indexOf('/'));
			}
			
			// Derive pod from this
			pod = getSFPodFromHostName(root);
		
			// Extract any customer My Domain prefix:
			// VF pages
			if (root.indexOf('--') != -1) {
				myDomain = root.substring(0, root.lastIndexOf('--')+2);
			}
			
			
			// SF page
			if (root.indexOf('my.salesforce.com') != -1) {
				myDomain = root.substring(0, root.indexOf('my.salesforce.com')-1) + '--';

				// Mostly, my domain-type addresses won't feature pod in their addresses 
				// but some sandboxes DO - so remove these from the domain name here
				// (as we add pod below)
				myDomain = myDomain.replace('.' + pod, '');
			}
			
			retVal = protocol + myDomain + nspace + '.' + pod + '.visual.force.com';
			
		} catch (e) {
			retVal = '';
		}
		
		return retVal;
	}


// --------------------------------------------------------------------------------------------------
// PRIVATE MEMBERS:
// --------------------------------------------------------------------------------------------------
	
	
// --------------------------------------------------------------------------------------------------
// Derive the server pod SF is using based on a given SF/VF host name (the URL minus protocol & path).
// This assumes the host name will be in one of a known set of formats:
//
// Most formats contain the pod name:
//
// 	OrgsLocalDomainName.PODX.my.salesforce.com
// 	OrgsLocalDomainName--c.PODX.visual.force.com			
// 	OrgsLocalDomainName--iahelp.PODX.visual.force.com
// 	PODX.salesforce.com
// 	c.PODX.visual.force.com
// 	iahelp.PODX.visual.force.com
//
// This form alone does NOT contain the pod:
//
// 	OrgsLocalDomainName.my.salesforce.com
//
// In this case, pod must be assumed based on a lookup of org id (4th character being identifier of pod)
// --------------------------------------------------------------------------------------------------
	function getSFPodFromHostName(H) {
		
		var retVal = '';
		var i;
		var j;

		try {
			
			if (IHSettings != null) {
				retVal = IHSettings[SFPod];
				
			} else {
				
				// In MOST cases, we can get the pod directly from the Host name				
				// If VF present, pod immediately precedes this...
				retVal = H.toUpperCase();
				
				if (retVal.indexOf('.VISUAL.FORCE.COM') != -1) {					
					j = retVal.indexOf('.VISUAL.FORCE.COM');
					retVal = retVal.replace('.VISUAL.FORCE.COM', '');					
					i = retVal.lastIndexOf('.') + 1;					
					retVal = H.substring(i, j);
				}
				
				// If SF is present, but my. is NOT, pod immediately precedes this...
				else if (retVal.indexOf('.SALESFORCE.COM') != -1 && retVal.indexOf('.MY.SALESFORCE.COM') == -1) {
					j = retVal.indexOf('.SALESFORCE.COM');
					retVal = retVal.replace('.SALESFORCE.COM', '');					
					i = retVal.lastIndexOf('.') + 1;					
					retVal = H.substring(i, j);					
				}
				
				// Failing this, look for the OrgId cookie and lookup pod name
				else {
					i = readCookie('oid');

					if (i==null) {
						retVal = 'ECx!';
					} else {
						retVal = getSFPodFromOID(i);
					}
					
				}
							
				
				// Check all of the above returned a sensible value
				if (retVal.length > 4) {
					retVal = 'E4+!';
				}
				
			}
			
		} catch (e) {
			retVal = e;
		}
		
		return retVal;
	}
	
	
// --------------------------------------------------------------------------------------------------
// Derive SF server pod name from Org's Id - assumed to indicate pod in its 4th character
// --------------------------------------------------------------------------------------------------
	function getSFPodFromOID (oid) {
		
		var retVal;
		var podId;
		
		try {
			podId = oid.substring(3, 4);
			
			switch (podId) {
				case '0': 
					retVal='na0'; 
					break;
					
				case '3': 
					retVal='na1'; 
					break;
					
				case '4': 
					retVal='na2'; 
					break;
					
				case '5': 
					retVal='na3'; 
					break;
					
				case '6': 
					retVal='na4'; 
					break;
					
				case '7': 
					retVal='na5'; 
					break;
					
				case '8': 
					retVal='na6'; 
					break;
					
				case 'A': 
					retVal='na7'; 
					break;
					
				case 'C': 
					retVal='na8'; 
					break;
					
				case 'E': 
					retVal='na9'; 
					break;
					
				case 'F': 
					retVal='na10' ; 
					break;
					
				case 'G': 
					retVal='na11'; 
					break;
					
				case 'U': 
					retVal='na12'; 
					break;
					
				case 'd': 
					retVal='na14'; 
					break;
					
				case '1': 
					retVal='ap0'; 
					break;
					
				case '9': 
					retVal='ap1'; 
					break;
					
				case '2': 
					retVal='eu0'; 
					break;
					
				case 'D': 
					retVal='eu1'; 
					break;
					
				case 'b': 
					retVal='eu2'; 
					break;
					
				case 'T': 
					retVal='cs0'; 
					break;
					
				case 'S': 
					retVal='cs1'; 
					break;
					
				case 'R': 
					retVal='cs2'; 
					break;
					
				case 'Q': 
					retVal='cs3'; 
					break;
					
				case 'P': 
					retVal='cs4'; 
					break;
					
				case 'O': 
					retVal='cs5'; 
					break;
					
				case 'N': 
					retVal='cs6'; 
					break;
					
				case 'M': 
					retVal='cs7'; 
					break;
					
				case 'L': 
					retVal='cs8'; 
					break;
					
				case 'K': 
					retVal='cs9'; 
					break;
					
				case 'J': 
					retVal='cs10'; 
					break;
					
				case 'Z': 
					retVal='cs11'; 
					break;
					
				case 'V': 
					retVal='cs12'; 
					break;
					
				case 'W': 
					retVal='cs13'; 
					break;
					
				case 'c': 
					retVal='cs14'; 
					break;
					
				case 'e': 
					retVal='cs15'; 
					break;
					
				case 'f': 
					retVal='cs16'; 
					break;
					
				case 'g': 
					retVal='cs17'; 
					break;
					
				case 't': 
					retVal='na1'; 
					break;	
				
				default:
					retVal = 'UNKN';
					break;
			}
			
		} catch (e) {
			retVal = '';
		}
		
		return retVal;
	}
	
	
// --------------------------------------------------------------------------------------------------
// CLOSE the quick access menu only - rather than toggling
// --------------------------------------------------------------------------------------------------
	function closeQAM() {
		
		var x = document.getElementById('IHQAM');
		var y = document.getElementById('IAIHQAMHandle');
		var z = document.getElementById('QAMHandleLink');
	
		if (x.style.right == '0px') {
			$IAIHj("#IHQAM").animate({right:'-=148px'}, 'slow');
			y.className = 'QAMHandleClosed';
			z.title = Internationalise('[QAMTipHandle]');
		} 
		
		return;
	} 
		
		
// --------------------------------------------------------------------------------------------------
// For repeat hooking
// --------------------------------------------------------------------------------------------------
	var HooksDone;
	var HooksMax;
	
	IHQAMenu.HookRepeater;
	
	IHQAMenu.doRepeatHook = function () {
		
		try {
			
			// Only re-hook if we're in View mode
			if (theCurrentMode != 'Saved') {
				window.clearTimeout(IHQAMenu.HookRepeater);			
				return;
			}
			
			
			// -1 repeats = keep doing...
			if (HooksMax == -1) {
				HookHelp();
				
			} else {
				HooksDone += 1;
				
				if (HooksDone > HooksMax) {
					// Cancel repeats
					window.clearTimeout(IHQAMenu.HookRepeater);			
				} else {
					HookHelp();			
				}
				
			}
			
		} catch (e) {
			window.clearTimeout(IHQAMenu.HookRepeater);						
		}
		
		return;
	}

	
// --------------------------------------------------------------------------------------------------
// Code required to wire up when in guide mode
// --------------------------------------------------------------------------------------------------
	var guideObj = '';
    var consolePTabListener = function (result) {
    	guideObj = result.objectId;
    };

    try {		
		sforce.console.onFocusedPrimaryTab(consolePTabListener);
    } catch (e) {
    }
	

}(window.IHQAMenu = window.IHQAMenu || {}));		