/////////////////////////////////////////////////////////////////////////////////////////////////////
// FUNCTIONS FOR ENABLING IMPROVED HELP ON SF AND VF PAGES
//
// NB: These functions rely on making calls to those in the jsWebToolTips and jsQAMenu JS static resources
// NB: They also rely on settings variables provided by jsSettings.
// NB: They also rely on SF APEX wrapper scripts (Connection.js & Apex.js)
// NB: They also rely on jQuery (as does jsWebToolTips)
//
// Martin Little for Improved Apps
// May 2012
// Copyright (c.) Improved Apps Limited 2012. All Rights Reserved.
/////////////////////////////////////////////////////////////////////////////////////////////////////

"use strict";

// --------------------------------------------------------------------------------------------------
// Shared variables
// --------------------------------------------------------------------------------------------------
	var HElems = null;				// Helped elements (from settings) split into array
	var theCurrentMode = 'Saved';	// Page's current operating mode, eg stats, config etc (cf configurePage)
	var IHVIP = '';					// ID of any helped element that is to be "Viewed in Place"
	var IHVIPPrompt = '';			// Prompt message to show when showing a VIP
	var IHVIPBody = '';				// LUX-style only: Body text to show when showing a VIP
	var IHVIPImage = '';			// LUX-style only: URL of image to show when showing a VIP
	var IHVIPVideo = '';			// LUX-style only: URL of video to show when showing a VIP
	var IHVIPType = '';				// Helped element type of the VIP element
	var IHVIPShowCallout = 'true';	// Defines whether to show callout as part of a VIP
	var IHVIPRLType = 0;			// The type of any reading list involved in cueing an AwaitVIP step 
	var IHVIPTimeStamp;				// The time at which the last immediate VIP was called (see LogVIPs)
	var iVIP = 0;                   // ID of the timer process in use for showing VIP elements
	var awaitVIPId;					// Any logged await VIP instructions
	var GSIdsMap;					// Array of guide step (RLE) Ids mapped to helped element identifiers
	var currentLocalStep = 1;		// Current step number in a set of local steps within a Guide
	var totalLocalSteps = 1;		// Total number of steps within the same
	var activeGEnableElement;		// The helpable element that is currently the subject of Guide Enabling activity (GE prompt visible)
	
// --------------------------------------------------------------------------------------------------
// Utilities
// --------------------------------------------------------------------------------------------------
	function stringTrim(someText) {
		return someText.replace(/(?:(?:^|\n)\s+|\s+(?:$|\n))/g,'').replace(/\s+/g,' ');
	}


// --------------------------------------------------------------------------------------------------
// Call hooking for all helpable elements on a given page. 
// This is the "entry point" function that pages should call in order to IH-enable themselves
// --------------------------------------------------------------------------------------------------
	function HookHelp () {
		
		var e;				// for looping
		var c;				// collections of HTML elements of various kinds being checked for help-ability
		
		
		// Make tip frames: various functions may require this, even if page is not help enabled...
		MakeTipFrame('tfrm');	// For callouts
		MakeTipFrame('dfrm');	// For dialogues

 
		// The callout frame should NOT have a high z-index (unlike the dialogue)
		document.getElementById('tfrm').style.zIndex = '0';
		

		// Get all potentially helpable elements
		c = null;
		c = GetHelpableElements('');


		// Remove any helped, VIP, stats or helpable mode styling and behaviour from these elements
		for (e = 0; e < c.length; e ++) {
			c[e].className = c[e].className.replace('IHHelpedSFElement', '');
			c[e].className = c[e].className.replace('IHHelpedSFElementError', '');
			c[e].className = c[e].className.replace('IHHelpedVFElement', '');
			c[e].className = c[e].className.replace('IHHelpStats', '');
			c[e].className = c[e].className.replace('HelpableSFElement', '');
			c[e].className = c[e].className.replace('GuidableSFElement', '');
			c[e].className = c[e].className.replace('IHVIP', '');
			c[e].className = stringTrim(c[e].className);
			
			// Click behaviour should NOT be removed for buttons!!
			if (c[e].tagName.toUpperCase() != 'INPUT') {
				c[e].onclick = '';		
			}
		}
		
		// Remove all "click helper" inserted clickables
		$IAIHj('[id$=ClickHelper]').remove();								
		

		try {
			// HELP ENABLE 'SIGNATURE' / LOCALLY SPECIFIED HOOKABLES
			if (1==1) {
				HookElementType('Signatures');
			}

			// HELP ENABLE HELP & TRAINING PORTAL LINK
			if (IHSettings[doP] == 'true') {
				HookElementType('HTPortalLinks');
			}

			// HELP ENABLE PAGE-LEVEL HELP 
			if (IHSettings[doP] == 'true') {
				HookElementType('Pages');
			}

			// HELP ENABLE RECORD TITLES
			if (IHSettings[doE] == 'true') {
				HookElementType('RecordTitles');
			}			

			// HELP ENABLE DETAILS AREA SECTION HEADINGS
			if (IHSettings[doD] == 'true') {
				HookElementType('DetailAreas');
			}			
			
			// HELP ENABLE CUSTOM SECTION HEADINGS
			if (IHSettings[doC] == 'true') {
				HookElementType('CustomAreas');
			}
			
			// HELP ENABLE RELATED LIST SECTION HEADINGS
			if (IHSettings[doR] == 'true') {
				HookElementType('RListTitles');
			}
		
			// HELP ENABLE RELATED LIST COLUMNS
			if (IHSettings[doT] == 'true') {
				HookElementType('RListColumns');
			}

			// HELP ENABLE RELATED LIST OBJECT-LEVEL HELP 
			if (IHSettings[doO] == 'true') {
				HookElementType('RListObjects');
			}												

			// HELP ENABLE FORM FIELD LABELS
			if (IHSettings[doF] == 'true') {
				HookElementType('Fields');
			}

			// HELP ENABLE SALESFORCE STANDARD BUTTONS
			if (IHSettings[doB] == 'true') {
				HookElementType('SFButtons');
			}

			//HELP ENABLE SALESFORCE MENU BUTTONS
			if (IHSettings[doB] == 'true') {
				HookElementType('SFMenuButtons');
			}
			
			//HELP ENABLE CUSTOM LINKS
			if (IHSettings[doL] == 'true') {
				HookElementType('CustomLinks');
			}

			// HELP ENABLE VISUAL FORCE PAGE ELEMENTS:
			// POTENTIALLY HELPABLE THINGS ARE DIVs CLASSED AS "Helpable":
			// IF AN AUTHOR ADDS HELP FOR AN INSTANCE OF THIS, WE MARK IT AS "IHHelpedVFElement" IN VIEW MODE.
			// NB: THERE IS NO CONCEPT OF WHAT'S WHAT - FIELD LABELS VS SECTION HEADINGS ETC
			if (1 == 1) {
				HookElementType('VFPages');
			}
					

// v1.41+ : deprecating as part of ramp down of classic guides			
/*			
			// If guides exist for this page, respond to settings about how to display them:
			// NB: Guides link appears, where required, regardless of whether page help to be hooked
			// NB: (1.18 - for IE8) Links only appear if client is guide-capable.
			if (IHSettings[GuidesExist] == 'true' && isGuideCompatible() == true) {

				switch (IHSettings[GuidesLinksOption]) {
					case '0':
						// No links beyond QAM:
						// No need to act here - see jsQAMenu.setupQAM
						break;

					case '1':
						// QAM + On page link									
						if ($IAIHj('#IHGuidesLink').length == 0) {
							var Ps = GetHelpableElements('Pages');										
							$IAIHj(Ps[0]).parent().before('<span id="IHGuidesLink" style="cursor: pointer;" title="' + Internationalise('[QAMTipRowGuides]') + '" onclick="javascript:IHQAMenu.showGuides(event);">' + Internationalise('[QAMRowGuides]') + ' |</span>');
						}
						
						break;

					case '2':
						// QAM + custom button
						if ($IAIHj('#IHGuidesButton').length == 0) {							
							if ($IAIHj('#topButtonRow').length == 1) {
								$IAIHj('#topButtonRow').append('<div style="display: inline;"><input id="IHGuidesButton" class="IHGuidesButton" type="button" title="' + Internationalise('[QAMTipRowGuides]') + '" onclick="javascript:IHQAMenu.showGuides(event);" /></div>');																
							}							
						}
						
						break;					
				}							
			}
*/			
			
			// Mark all DDF failed elements
			c = null;
			c = GetHelpableElements('');

			for (e = 0; e < c.length; e++) {				
				if (IHSettings[FDetails].indexOf(settingsD2 + getElementIdString(c[e]) + settingsD1) != -1) {
					$IAIHj(c[e]).addClass('IHDDFFailElement');					
					c[e].onclick = ShowError;					
				}
			}


		} catch (ex) {
			//alert('Error attempting to hook Improved Help: ' + e + '\nAdditional diagnostics:\n\n' + Diags);
		}

		return;
	}


// --------------------------------------------------------------------------------------------------
// Hook improved help onto all helpable elements of a given type
// --------------------------------------------------------------------------------------------------
	function HookElementType(elemType) {
		
		var e;				// for looping
		var c;				// collections of HTML elements of various kinds being checked for help-ability
		var HAF;			// For results of calls to HelpAvailableFor
		var CalloutDetails;	// For checking details of any topic-specific custom style to associate with an element
		var CDs;			// As above
		var sCSS;			// The style name derived with the above
		var s1;				// For string comparisons
		var s2;				// For string comparisons
	
		
		// Get all potentially helpable elements of the requested type
		c = GetHelpableElements(elemType);

		
		// Loop through these
		for (e = 0; e < c.length; e ++) {
	
			// Note the fact that helpable elements exist
			hasHelpableElements = true;

			
			// Check there is a suitable helped element before help enabling
			HAF = HelpAvailableFor(c[e]);

			
			// Page help needs its own handling
			if (elemType == 'Pages') {
				if (HAF >= 1) {
					
					var x = c[e].parentNode;
					x.href='#';
					
					// Disable any previously added (Stats mode) behaviours
					x.onclick = '';
	
					// If there's any config issue, give clues that this is the case
					if (HAF == 2) {
						// NB: moved onclick to SPAN and NOT the parent link (x) itself, as it's the span we 
						// create that gets hooked etc elsewhere and using x here would cause events on >1 thing!
						x.innerHTML = '<span class="helpLink" onclick="javascript:ShowError()"><div class="IHPageHelpLink IHHelpedSFElement IHHelpedSFElementError">' + Internationalise('[QAMButtonPageHelpLink]') + '</div></span>';
						
					} else {
						var pgId = getElementIdString(c[e]);
	
						// Locate this element in callout settings and look for any custom CSS to apply
						CalloutDetails = getCalloutDetails(pgId) + '';
						CDs = CalloutDetails.split(String.fromCharCode(7));
						sCSS = CDs[3];						
						if(sCSS != '' && sCSS + '' != 'null') {
							sCSS = ' ' +sCSS;
						}
						
						var U = IHSettings[SFURL];						
						U += '/apex/iahelp__' + IHSettings[PortalPage] + '?HPL=' + pgId + '&ElemId=' + pgId;
						$IAIHj(x).html('<span class="helpLink"><a title="' + Internationalise('[QAMTitleHelpedElement]').split("'").join('') + '" target="_Blank" href=' + U + '><div class="IHPageHelpLink IHHelpedSFElement' + sCSS + '">' + Internationalise('[QAMButtonPageHelpLink]') + '</div></a></span>');
					}
											
				}						
			} // End handling for PAGE type help
			
			
			// All other element types have relatively common handling
			if (elemType != 'Pages') {
				if (HAF == 1) {
					
					// Locate this element in callout settings and look for any custom CSS to apply
					CalloutDetails = getCalloutDetails(getElementIdString(c[e])) + '';
					CDs = CalloutDetails.split(String.fromCharCode(7));
					sCSS = CDs[3];					
					if (sCSS != '' && sCSS + '' != 'null'){
						$IAIHj(c[e]).addClass(sCSS);
						
						// "Updated" class is also shipped via callout details: we don't want this applied
						// to added clickables and certain others, so remove it from them (in case it was added) here...
						// In these cases, the class is added to the related items in line below
						if (elemType == 'SFButtons' || elemType == 'SFMenuButtons' || elemType == 'CustomLinks' || elemType == 'HTPortalLinks') {	
							$IAIHj(c[e]).removeClass('IHCollateralUpdated');							
						}
					}						
					
					
					// Click behaviour depends on element type
		    		switch (elemType) {
		    		
		    			case 'HTPortalLinks':
							var U = IHSettings[SFURL];
							U += '/apex/iahelp__' + IHSettings[PortalPage] + '?HPL=' + IHSettings[SFObjId] + '&ElemId=' + getElementIdString(c[e]);
							c[e].href = U;
							c[e].target = '_blank';
							$IAIHj(c[e]).html('<div class="IHPageHelpLink IHHelpedSFElement' + sCSS + '">' + Internationalise('[QAMButtonHelpPortalLink]') + '</div>');
		    				break;
		    			
						case 'RListTitles':
							c[e].onclick = DoSectionTip;    				
							break;
		
						case 'RListColumns':
							c[e].onclick = DoRLColTip;    				
							break;
		
						case 'RListObjects':
							// Specialised handling required here:
							// Be sure to trim the inner text / link label:
							// Otherwise, we may get issues with the helped element id requiring trailing "+" etc...					
		
							c[e].innerHTML = stringTrim(getInnerText(c[e]));					
							c[e].onclick = DoRLObjTip;    				
							break;

						case 'RecordTitles':
						case 'Signatures':
							c[e].onclick = DoVFTip;    	
							
							// Mark these with "snap to element" styling (as used in some VF elements) so
							// callout has a mouse-independent position
							$IAIHj(c[e]).addClass('IHSnapToElement');
	
							// For record titles, mark element as a non-VF type (required to differentiation in certain circumstances)
							if (elemType == 'RecordTitles') {
								$IAIHj(c[e]).addClass('IHHelpedPositioned');
							}							
							
							// In addition, add the additional style class marked for this element (or default if none specified)
							try {
								CalloutDetails = SignatureAttribute(c[e]);
								
								if (CalloutDetails != '') {
									CDs = CalloutDetails.split(settingsD2);
								
									if (CDs.length == 4) {
										if (CDs[3] != 'null') {
											$IAIHj(c[e]).addClass(CDs[3]);
										} else {
											$IAIHj(c[e]).addClass('HelpableR_50');
										}		
									} else {
										$IAIHj(c[e]).addClass('HelpableR_50');
									}	
								} else {
									$IAIHj(c[e]).addClass('HelpableR_50');	
								}
								
							} catch (e) {
								alert('(HookElementType) - ' + e);
							}						
							
							break;
							
						case 'DetailAreas':
							c[e].onclick = DoDetailsTip;    				
							break;
		
						case 'CustomAreas':
							c[e].onclick = DoCustomSectionTip;    				

							// Mark these with "snap to element" styling (as used in some VF elements) so
							// callout has a mouse-independent position
							$IAIHj(c[e]).addClass('IHSnapToElement');

							break;
		
						case 'SFButtons':
						case 'SFMenuButtons':
						case 'CustomLinks':
							// For buttons, we don't want to hijack the click (as this does something else!)
							// Nor do we want a permanent mouseover (as this is irritating!)
							// So: add our own clickable to offer help.
							// NB: we only want to add this once - so remove any existing instances first (above)
							
							var s = getElementIdString(c[e]);
							s = s.split(' ').join(settingsD1);						
							s += settingsD1 + e;
							
							// Note we add custom style (including collateral updated marker) to clickable here...
							if(sCSS + '' == 'null') {sCSS = '';}
							if(sCSS != '') {sCSS = ' ' + sCSS;}
							$IAIHj(c[e]).before('<input id="' + s + 'ClickHelper" type="button" class="IHClickHelper' + sCSS + '" title="' + Internationalise('[QAMTitleHelpedElement]').split("'").join('') + '" onclick="javascript:DoButtonTip(this, \'' + s + '\');">');
							c[e].id = s;
							
							// Futures: Ideally, we also need to add a listener to the helper's subject (the button/link that we're helping)
							// to spot if it is hidden: when in-line editing is used, SF editing buttons will disappear,
							// so our helpers must too (don't want them left behind as looks odd etc)
							
							break;

						case 'VFPages':
							c[e].onclick = DoVFTip;    				
		    				break;
	
						default:
							// EG: field labels
							c[e].onclick = DoFieldTip;
							break;
		    		}
		    				
		    				
					// Set helped class - so we can marked helped elements
					if (elemType == 'VFPages') {
						c[e].className += (c[e].className == '' ? 'IHHelpedVFElement' : ' IHHelpedVFElement');
					} else {
						c[e].className += (c[e].className == '' ? 'IHHelpedSFElement' : ' IHHelpedSFElement');
					}
					
					
					// Set helped tool tip per global settings
					c[e].title = Internationalise('[QAMTitleHelpedElement]');
							

					// If this is the VIP element, arrange to show its help					
					s1 = stringTrim(getElementIdString(c[e]).toUpperCase());
					s2 = stringTrim(IHVIP.toUpperCase());

					// Useful debugging
					//alert('HookElementType - VIP marking:\n\n' + s1 + '\n' + s2 + '\n' + IHVIP);					
					
					if (s1 == s2 && IHVIP != '') {
								
						// To do this, mark the element with a special class...
						c[e].className += ' IHVIP';
						
						// ... then set up a timed function to open the tip:
						// Only do this if this has not already been cued at some point
						if (iVIP == 0) {iVIP = window.setTimeout("DoVIP()", 2000);}
					}
				}
				
				// If there's any config issue, give clues that this is the case
				if (HAF == 2) {
					
					// Special handling for certain types:
					if (elemType == 'RListObjects') {
						c[e].innerHTML = stringTrim(getInnerText(c[e]));
					}

					
					// Handling of items requiring "click helpers" slightly different
					if (elemType == 'SFButtons' || elemType == 'SFMenuButtons' || elemType == 'CustomLinks') {

						var s = getElementIdString(c[e]);
						s = s.split(' ').join(settingsD1);						
						s += settingsD1 + e;
						
						$IAIHj(c[e]).before('<input id="' + s + 'ClickHelper" type="button" class="IHClickHelper IHHelpedSFElementError" onclick="javascript:ShowError();">');
												
						// We still want "helped" styling on the element itself
						c[e].className += (c[e].className == '' ? 'IHHelpedSFElement' : ' IHHelpedSFElement');
						
					}  else {
						c[e].onclick = ShowError;
						c[e].className += (c[e].className == '' ? 'IHHelpedSFElement IHHelpedSFElementError' : ' IHHelpedSFElement IHHelpedSFElementError');						
					}
					
				}
				
			} // End handling of type != Page
			
		} // End loop around helpables / e

		return true;
	}

	
// --------------------------------------------------------------------------------------------------
// Function to show a helped element (reconfigure) dialogue
// --------------------------------------------------------------------------------------------------
	function DoReconHelpedElement(evt) {
		
		var i;
		var EFound = false;

	    try {    
			if(!evt) evt = window.event;
	    	var elem = evt.target||evt.srcElement;
	    	
	    	// Get the relevant identification string for the element that fired the tip event
	    	var id = getElementIdString(elem);
			
	    	// If we get a blank id from this, it might be because the event was fired
			// by a "helper" button, whose ID will not be the identifier of a helped element.
			// So: look for any associated element
			if (id == '') {				

				id = elem.id.replace('ClickHelper', '').split(settingsD1).join(' ');
				
				// The above will work for custom links, whose id is in the form:
				// [Report[D1]Link[D1]Text]ClickHelper
				
				// Buttons, however, have an index number to deal with upper/lower button bars, i.e:
				// [ButtonText][D1][index]ClickHelper
				
				// There will NOT be a helped element matching this - so 
				// we must check local helped elements to see that the id we now have exists: if not, 
				// cut the final "word" from the HE identifier (the index number)
				
				for (i=0; i<HElems.length; i++) {
					if (HElems[i] == id.toUpperCase()) {
						EFound = true;
						break;
					}
				}
				
				if (EFound == false) {
					id = id.substring(0, id.lastIndexOf(' '));
				}
				
			}
			
			// We also need to deal with page help: if we encounter this,
			// the helped element will have been saved with page layout id / SFObjId as the identifier
			if (id.toUpperCase() == Internationalise('[QAMButtonPageHelpLink]').toUpperCase()) {
				id = IHSettings[SFObjId];
			}
			
			// v1.35+ : This call is used in CLASSIC only - so mandate classic UX (IHLUX=false regardless of branding UX options)
			var U = IHSettings[SFURL] + '/apex/iahelp__IHHelpedElement?IHLUX=false&ElemId=' + encodeURIComponent(id) + '&HPL=' + IHSettings[SFObjId] + '&Mode=Edit';

			// Dialogue format may need to change depending on client QAM: for standard
			// QAM we can do a tip, for VF QAM we need to make a separate dialogue window
			if (document.location.href.toUpperCase().indexOf('/APEX/IHQAM') == -1 && document.location.href.toUpperCase().indexOf('/APEX/IAHELP__IHQAM') == -1) {
				IHWebToolTips.DoTips("dfrm", U, "7", 600, 460, evt);				
			} else {
				IHQAMenu.DoVFQAMDialogue(U, 600, 440, 'IHQAMDialogue', evt);
			}
			
	    	
	    } catch (e) {
	    	alert(Internationalise('[QAMMessageGenericError]') + ' - (Reconfigure Helped Element) ' + e);
	    }
	}
	
// --------------------------------------------------------------------------------------------------
// Function hooked to elements with config OR data driven filter issues (instead of standard tip cueing mechanisms)
// --------------------------------------------------------------------------------------------------	
	function ShowError(evt) {
		
		if(!evt) evt = window.event;
    	var elem = evt.target||evt.srcElement;
    	var msg;

		
		// Offer the use the option of reviewing the broken element
		if (theCurrentMode.toUpperCase() != 'RECON') {
			
			// In most modes, offer the option of viewing the issue:
			// Offering message varies by context
			if ($IAIHj(elem).hasClass('IHDDFFailElement')) {
				msg = Internationalise('[QAMMessageDDFNotMatched]');
			} else {
				msg = Internationalise('[QAMMessageElementConfigurationIssue]');
			}			
			
			if (confirm(msg)) {
				DoReconHelpedElement(evt);
			}		

		} else {
			// In reconfigure mode, we may as well just show the dialogue immediately
			DoReconHelpedElement(evt);
		}

		return;
	}

		
// --------------------------------------------------------------------------------------------------
// Respond to a "local" VIP instruction (from a Guide link in the QAM)
// --------------------------------------------------------------------------------------------------	
	function cueVIP(VIPId, ElemType, HTID, VPrompt, ShowCallout, StepDivId, VBodyText, VImage, VVideo) {

		// Incoming VIPId **might** need processing to decode escaping of various kinds...
		VIPId = stringTrim(decodeURI(VIPId));
		VIPId = VIPId.split('&amp;').join('&');

		IHVIP = VIPId;
		IHVIPPrompt = decodeURI(VPrompt);
		IHVIPBody = decodeURI(VBodyText);
		IHVIPImage = decodeURI(VImage);
		IHVIPVideo = decodeURI(VVideo);
		IHVIPType = ElemType;
		IHVIPShowCallout = ShowCallout;
		HookHelp();
		

		// Remove all "selected" guide step markings
		$IAIHj('.GuideStep').removeClass('Current');
				
		DoVIP();
		IHVIP = '';

		
		// 1.42 - DEPRECATING AS CLASSIC GE MODE ALREADY REMOVED
/*
		try {
			
			// Send a message back to the Guide window to say we've changed step locally / manually:
			// If we're in an iframe, send the same message back to parent page
			// Message is in the form:
			// 		[Guide Step Help Topic Id]^[Page URL / Context]
			//
			// For the context, we only want the "base" address, not the query string 
					
			if (self != top) {
				top.postMessage('GSHTID=' + HTID + '^' + document.URL.replace(document.location.search, ''), '*');				
			} else {
				
				var msgGSHTID = document.URL;
				msgGSHTID = msgGSHTID.replace(document.location.search, '');
				msgGSHTID = 'GSHTID=' + HTID + '^' + msgGSHTID;
				
				if (window.opener) {
					//prompt('cueVIP: posting GSHTID to opener:', msgGSHTID);
					window.opener.postMessage(msgGSHTID, '*');
				}

			}
			
		} catch (e) {
			alert(Internationalise([QAMMessageGenericError]) + ' - (Cue View in Place) ' + e);
		}
*/
		
		// Add "selected" marking to the step that was clicked
		$IAIHj(document.getElementById(StepDivId)).addClass('Current');		
		
		// Also add a "clicked" marking (will not get removed until page refresh)
		$IAIHj(document.getElementById(StepDivId)).addClass('Clicked');		
		
		
		return;
	}

	
// --------------------------------------------------------------------------------------------------
// Note the need to act on any incoming "View in Place" instructions (given via URL parameters)
// --------------------------------------------------------------------------------------------------
	function LogVIPs() {

		var qs;
		var i;
		var D1 = String.fromCharCode(7);
		
		
		// Initialise await VIP settings
		awaitVIPId = '';
		
		try {
			IHSetCookie('IHQAMAwait', '', 1);
		} catch (e) {			
		}
		

		try {
			if (location.search.length > 0) {
				qs = location.search.substring(1).split('&');
	  
				for (i=0; i<qs.length; i++) {
					  				
					// Look for IH Helped Element identifier parameter (IHVIP) in query string
					if (qs[i].length > 6){
						if (qs[i].substring(0,6).toUpperCase() == 'IHVIP=') {
			
							// If found, note the element to be viewed in place in a global variable
							var IHV = decodeURI(qs[i].substring(6));
														
							IHV = IHV.split(D1);						
							IHVIP = IHV[0];
							
							// Also note helped element type
							IHVIPType = IHV[1];   
							IHVIPType = IHVIPType.replace('+', ' ');
							
							// Also, log a cookie to state that a VIP step is in play 
							IHVIPTimeStamp = getTimeStamp();
							IHSetCookie('IHQAMVIP', IHVIPTimeStamp + settingsD1 + document.location.href, 1);
							
							break;
						}
					}
					
					
					// Add activity here to look for any "Await VIP" instructions:
					if (qs[i].length > 9){
	
						if (qs[i].substring(0,9).toUpperCase() == 'AWAITVIP=') {
	
							// If found, note the element to be viewed in place in a global variable
							// AND set a cookie to show we're in "await" mode:
							// This cookie contains material that can be used to populate
							// VIP instructions for use elsewhere (e.g., the QAM can produce 
							// links from this)
							awaitVIPId = decodeURI(qs[i].substring(9));
							IHSetCookie('IHQAMAwait', awaitVIPId, 1);
									
							// Also, log a cookie to state that a VIP step is in play 
							IHVIPTimeStamp = getTimeStamp();
							IHSetCookie('IHQAMVIP', IHVIPTimeStamp + settingsD1 + document.location.href, 1);
							
							break;
						}
					}
					
					
					// Make a note of Guide (reading list) type if this has been passed 
					if (qs[i].length > 7){
						if (qs[i].substring(0,7).toUpperCase() == 'RLTYPE=') {
							IHVIPRLType = qs[i];
							IHVIPRLType = IHVIPRLType.toUpperCase().replace('RLTYPE=', '');
						}
					}				
	
				} 	// End of loop around query params
			}	// End if address had a query string

			
			// Set up a timer process to check whether VIP cookie has been superceded - 
			// implying that a more "recent" VIP (Guide Step) has been opened:
			// Only do this if "necessary" - i.e., if:
			// - VIP cookie exists
			// - it is "relevant" because it was put in place by current or referrer document
			var ck = readCookie('IHQAMVIP');
			if (ck != null) {
				ck = ck.split(settingsD1);

				if (ck[1] == document.location.href || ck[1] == document.referrer) {
					//alert('VIP Cookie IS for me - timer being set...\n\n' + document.location.href);
					IHVIPTimeStamp = ck[0];
					window.setInterval("checkVIP()", 1000);						
				} else {
					//alert('VIP Cookie NOT for me\n\n' + ck[1] + '\n\n' + document.location.href + '\n\n' + document.referrer);
				}
				
			} else {
				//alert('No VIP cookie');
			}				

			
		} catch (e) {
			//alert('Error responding to View in Place instructions: ' + e);
		}

		
		return;
	}	
		
	
// --------------------------------------------------------------------------------------------------
// Timed process that checks whether VIP instruction cookie has been updated (and closes
// the current window if so, on the assumption that it's a guide step which 
// is no longer the active step)
// --------------------------------------------------------------------------------------------------		
	function checkVIP() {
		var ts = readCookie('IHQAMVIP');
		ts = ts.split(settingsD1);
		ts = ts[0];
		if (ts != IHVIPTimeStamp) {
			window.close();
		}
		return;
	}
	
	
// --------------------------------------------------------------------------------------------------
// Call a View in Place for any element marked (via IHVIP class) as requiring this
// --------------------------------------------------------------------------------------------------		
	function DoVIP() {
		var e;
		var y;
		var yAdj;
		var cName;
		var c = document.getElementsByTagName("body")[0].getElementsByTagName("*");		
		var dP = document.getElementById('IHPrompt');
		var LUXGuideMode = IHSettings[BrandUXOption];
		var promptPosInfo;
		
		// NB: setting can be one of several that indicate LUX flavour guides are to be used		
		if (LUXGuideMode > '1') {LUXGuideMode = true;} else {LUXGuideMode = false;}

		
		// Find ANY element marked as VIP
		for (e = 0; e < c.length; e ++) {	
			
			cName = c[e].className + '';
			if (cName.indexOf(' IHVIP') != -1) {

				// Note position of this element
				y = $IAIHj('.IHVIP').position();
				

				// Show the prompt bubble if prompt text has been supplied
				if (dP + '' != 'null') {
					promptPosInfo = showPrompt(c[e]);
				}
				
				// If callout is to be shown for this step, show this: to do this,
				// call the handler that would be called by a "standard" helped element viewing attempt	
				
				if (IHVIPShowCallout == 'true') {
					var s;
					var i = 0;
					var clickHelper = null;

					// For buttons & links, we need to take special measures
					if (IHVIPType == 'Button') {						
						// Buttons have an INDEX value - we can only deal with the 1st of these we encounter:
						s = getElementIdString(c[e]);					
						s = s.split(' ').join(settingsD1);
						
						while (i < 100 && clickHelper + '' == 'null') {
							clickHelper = document.getElementById(s + settingsD1 + i + 'ClickHelper');
							i += 1;
						}

						DoButtonTip(clickHelper, s + settingsD1 + (i-1));
						
					} else if (IHVIPType == 'Custom Link') {	
						s = getElementIdString(c[e]);					
						s = s.split(' ').join('_');
						clickHelper = document.getElementById(s + 'ClickHelper');
						DoButtonTip(clickHelper, s);
						
					} else {
						c[e].click();					
					}
				}
								
				// Hide the list of guide steps, where visible, in classic only
				// (Note that in LUX this is not necessary as step list is embedded in prompt)				
				if (LUXGuideMode == false) {
					hideStepList();
				}
				

				// Remove VIP marking
				c[e].className = c[e].className.replace(' IHVIP', '');
				
				
				// Scroll to the relevant part of the screen (position of VIP element)
				try {
					// In "classic", we should be the top window / not framed:
					// If we're not top, assume we're in console mode.
					// In console, we need the scroll position to move up a little
					
					// v1.35: amendments to scroll position to account for LUX guides:
					// Scroll is based on reported prompt position (captured from call to showPrompt, above).
					// Scroll to prompt position - but if prompt is below helpable, scroll up a little further
					// to ensure that it, too, is in view	
					
					//promptPosInfo = promptPosInfo.split('\\^');					
					promptPosInfo = promptPosInfo.split('^');	

					yAdj = promptPosInfo[0];
					if (promptPosInfo[1] == 'Below'){yAdj -= 30;} 
					
					if (self == top) {
						IHWebToolTips.moveScroll(yAdj);
					}else {
						IHWebToolTips.moveScroll(yAdj - 50);
					}				

				} catch (e) {					
				}
				
				
				
				// Clear any VIP timer that called this
				window.clearTimeout(iVIP);
				
				break;
			}
		}	
		
		return;
	}
	

// --------------------------------------------------------------------------------------------------
// Wrapper function allowing elements that are enabled via click event, not an anchor link, to call DT
// --------------------------------------------------------------------------------------------------
	function DoFieldTip(evt) {	

		try {
			var cIdx = 0;			
			if(!evt) evt = window.event;
			var elem = evt.target || evt.srcElement;
			
			// Field tips can be styled as left or right arrowed call outs: 
			// This depends on the column index of the clicked item...
			do {
				if (elem.tagName.toUpperCase() == 'TD' || elem.tagName.toUpperCase() == 'TH') {
					cIdx = elem.cellIndex;
				}
			
				elem = elem.parentNode;
			}
			while (elem.tagName.toUpperCase() != 'TABLE');
				
			
			if (cIdx == 0) {
				//DT('TL1', evt);
				DT('TL0', evt);
			} else {
				DT('TR1', evt);
			}
			
		} catch (ex) {
			alert(Internationalise('[QAMMessageGenericError]') + ' - (Do Field Tip) ' + ex);
		}
	
		return;
	}
	

// --------------------------------------------------------------------------------------------------
// Wrapper functions allowing helped buttons to call DT
// --------------------------------------------------------------------------------------------------	
	function DoButtonTip(clickHelper, elemId) {

		var elem = document.getElementById(elemId);		

		try {
			// Temporarily attach mouse over event to incoming button element
			elem.onmouseover = DoBtnTip;
			
			// Fire this event - so we have an evt to send
			$IAIHj(elem).trigger('mouseover');
			
			// Remove the mouse over code
			elem.onmouseover='';
			
			// With buttons, use helper re-click to hide the tip:
			// Only do this, however, if global settings require it. Note that
			// mouse out of tip behaviour will be set by DoTips
			if (IHSettings[CCloseType] != '2') {
				clickHelper.onclick = ST;
			}
			
		} catch (e) {
			// In case there were any issues, remove the mouse over handler
			if (elem) {
				elem.onmouseover='';
			}
		}
		
		return;
	}
	
	function DoBtnTip(evt) {
		DT('', evt);
		return;
	}
		
	
// --------------------------------------------------------------------------------------------------
// Wrapper function allowing elements that are enabled via click event, not an anchor link, to call DT
// --------------------------------------------------------------------------------------------------
	function DoSectionTip(evt) {
		if(!evt) evt = window.event;		
		DT('TipR', evt);
		return;
	}


// --------------------------------------------------------------------------------------------------
// Wrapper function allowing elements that are enabled via click event, not an anchor link, to call DT
// --------------------------------------------------------------------------------------------------
	function DoCustomSectionTip(evt) {
		if(!evt) evt = window.event;		
		DT('TipCS', evt);
		return;
	}
	
	
// --------------------------------------------------------------------------------------------------
// Wrapper function allowing elements that are enabled via click event, not an anchor link, to call DT
// --------------------------------------------------------------------------------------------------
	function DoRLObjTip(evt) {
		if(!evt) evt = window.event;		
		DT('TipL', evt);
		return;
	}


// --------------------------------------------------------------------------------------------------
// Wrapper function allowing elements that are enabled via click event, not an anchor link, to call DT
// --------------------------------------------------------------------------------------------------
	function DoRLColTip(evt) {
		if(!evt) evt = window.event;		
		DT('', evt);
		return;
	}

			
// --------------------------------------------------------------------------------------------------
// Wrapper function allowing elements that are enabled via click event, not an anchor link, to call DT
// --------------------------------------------------------------------------------------------------
	function DoDetailsTip(evt) {
		if(!evt) evt = window.event;		
		DT('TL0', evt);
		return;
	}


// --------------------------------------------------------------------------------------------------
// Wrapper function allowing elements on VF pages to call DT on click
// --------------------------------------------------------------------------------------------------
	function DoVFTip(evt) {
		if(!evt) evt = window.event;	
		var elem = evt.target||evt.srcElement;	    			    		    	

		
		// Insertion point for locally defined, custom handling of embedded help callouts
		// See variable definition in jsConsole
		try {
			if (CustomTips == true) {
				DoCustomTip(elem);
				return;
			}			
		} catch (e) {}
		
		
		// VF tip type may or may not be specified by page author:
		// Look at element class name to check
					
		if (elem.className.indexOf('HelpableL_') != -1) {
			DT('TipVL', evt);
			
		} else if (elem.className.indexOf('HelpableR_') != -1) {
			DT('TipVR', evt);

		} else if (elem.className.indexOf('HelpableToDiv_') != -1) {
			DT('TipVD', evt);

		} else if (elem.className.indexOf('HelpableLUXField') != -1) {
			// Lightning fields need to set nubbin position - just as classic fields do in DoFieldTip.
			// In DoFieldTip / classic, this can be done by examining cell position in table.
			// For LUX, we'll have to make an assumption based on left co-ordinate of bounding rectangle of element...
			
			try {
				if (elem.getBoundingClientRect().x < 50) {
					DT('TipLUXTL0', evt);				
				} else {
					DT('TipLUXTR1', evt);				
				}
				
			} catch (e) {
				// IE may not support this
				DT('TipW', evt);							
			}
			
		} else {
			DT('TipW', evt);			
		}
		
		return;
	}


// --------------------------------------------------------------------------------------------------
// Wrapper function allowing page help to call shows statistics 
// --------------------------------------------------------------------------------------------------
	function DoPageStats(evt) {
	
		var id;	
	
	    try {    
			if(!evt) evt = window.event;
	    	var elem = evt.target||evt.srcElement;	    	
	    	
	    	MakeTipFrame('tfrm');
	    	    	    	    	
	    	// The relevant identification string is the page object ID
			IHWebToolTips.DoTips('tfrm', IHSettings[SFURL] + '/apex/iahelp__IHStats?HPL=' + IHSettings[SFObjId], "1", 50, 125, evt);

			// We should respond to callout closure behaviour as set in global settings:
			// See also jsWebToolTips.DoTips, which responds to the same setting 
			// as regards the tip itself (not the helped element) setting mouse out as required.
			// See also DT for read mode
			setClosureBehaviourForElem(elem);
			
	    } catch (e) {
	    }
		return;
	}


// --------------------------------------------------------------------------------------------------
// Wrapper functions allowing helped buttons to call shows statistics 
// --------------------------------------------------------------------------------------------------
	function DoButtonStats(evt) {
		
		var clickHelper;
		var elem;		
		var elemId;		// ID of helped page element related to clicked helper button
		
    	clickHelper = evt.target||evt.srcElement;	    			
		elemId = clickHelper.id.replace('ClickHelper' , '');
		
		// Temporarily attach mouse over event to incoming button element
		elem = document.getElementById(elemId);
		elem.onmouseover = DoBtnStats;
		
		// Fire this event - so we have an evt to send
		$IAIHj(elem).trigger('mouseover');
		
		// Remove the mouse over code
		elem.onmouseover='';

		// With buttons, use helper re-click to hide the tip:
		// Only do this, however, if global settings require it. Note that
		// mouse out of tip behaviour will be set by DoTips
		if (IHSettings[CCloseType] != '2') {
			clickHelper.onclick = ST;
		}
	    
		return;
	}
	
	// Support func for DoButtonStats...
	function DoBtnStats(evt) {
		
		var id;	
		
	    try {    
			if(!evt) evt = window.event;
	    	
	    	MakeTipFrame('tfrm');
	    	    	    	    	
	    	// Get the relevant identification string for the element that fired the tip event
	    	var elem = evt.target||evt.srcElement;	    	
			id = getElementIdString(elem);    	

	    	// Show stats tip
			IHWebToolTips.DoTips('tfrm', IHSettings[SFURL] + '/apex/iahelp__IHStats?ElemID=' + encodeURIComponent(id) + '&HPL=' + IHSettings[SFObjId], "3", 150, 125, evt);
	

			// We should respond to callout closure behaviour as set in global settings:
			// See also jsWebToolTips.DoTips, which responds to the same setting 
			// as regards the tip itself (not the helped element) setting mouse out as required.
			// See also DT for read mode
			setClosureBehaviourForElem(elem);

			
	    } catch (e) {
	    }
		
		return
	}
	
// --------------------------------------------------------------------------------------------------
// Wrapper function allowing elements (except page help) to call shows statistics 
// --------------------------------------------------------------------------------------------------
	function DoFieldStats(evt) {
	
		var id;
		var elem;
		
	
	    try {    
			if(!evt) evt = window.event;
	    	elem = evt.target||evt.srcElement;	    	

			// Handle "nested" elements that may cause multiple events (as they bubble up the chain).
			// Examples include SF field labels where standard help is present and certain
			// field types when editing an SF record.
		    if ($IAIHj(elem).parent().hasClass('IHHelpedSFElement') || $IAIHj(elem).parent().hasClass('IHHelpStats')){
		    	
		    	// In these cases, "click" the parent of the nested element and cancel our operations
			    $IAIHj(elem).parent().click();
			    return;
		    }
			
			
	    	MakeTipFrame('tfrm');
	    	    	    	    	
	    	// Get the relevant identification string for the element that fired the tip event
			id = getElementIdString(elem);    	

			
	    	// Show stats tip: Most use the same tip format, but there are exceptions:			
			if ($IAIHj(elem).parent().hasClass('pbSubheader') || $IAIHj(elem).hasClass('pageType') || SignatureAttribute(elem) != ''){
				// Custom section headings: these aren't in tables, so cannot use "added row" style tips
				// Ditto record titles
				IHWebToolTips.DoTips('tfrm', IHSettings[SFURL] + '/apex/iahelp__IHStats?ElemID=' + encodeURIComponent(id) + '&HPL=' + IHSettings[SFObjId], "2", IHSettings[CWidth], 125, evt);
				
			} else {
				IHWebToolTips.DoTips('tfrm', IHSettings[SFURL] + '/apex/iahelp__IHStats?ElemID=' + encodeURIComponent(id) + '&HPL=' + IHSettings[SFObjId], "3", 150, 125, evt);
			}
			
	

			// We should respond to callout closure behaviour as set in global settings:
			// See also jsWebToolTips.DoTips, which responds to the same setting 
			// as regards the tip itself (not the helped element) setting mouse out as required.
			// See also DT for read mode
			setClosureBehaviourForElem(elem);

			
	    } catch (e) {
	    }
		return;
	}


// --------------------------------------------------------------------------------------------------
// Help enabled page elements call this function in order to show a piece of improved help
// --------------------------------------------------------------------------------------------------
	function DT(elemType, evt) {
	
		var id;
		var elem;
		var CalloutDetails;
		var CDs;
		var objId;


	    try {
	    	// Note some parameters for use in URLs below
			objId = IHSettings[SFObjId];
			
			// Create the iframe in which to show callouts
	    	MakeTipFrame('tfrm');

	    	
			// Get the relevant identification string for the element that fired the tip event
			if(!evt) evt = window.event;
			elem = evt.target||evt.srcElement;	    			    		    	
			id = getElementIdString(elem);
			

			// Handle "nested" elements that may cause multiple events (as they bubble up the chain).
			// Examples include SF field labels where standard help is present and certain
			// field types when editing an SF record.
		    if ($IAIHj(elem).parent().hasClass('IHHelpedSFElement') || $IAIHj(elem).parent().hasClass('IHHelpStats') || $IAIHj(elem).parent().hasClass('IHHelpedVFElement')){
		    	// In these cases, "click" the parent of the nested element and cancel our operations
			    $IAIHj(elem).parent().click();
			    return;
		    }
			
					    
	    	// Get details of the callout to use with this element
	    	CalloutDetails = getCalloutDetails(id) + '';

	    	//alert('DT: callout details for "' + id + '" as follows:\n\n' + CalloutDetails);	    		    	

	    	CDs = CalloutDetails.split(String.fromCharCode(7));
	    	
	        // Create a tip with style to suit stated element type:
	    	if (readCookie('IHActiveCallout') == id && document.getElementById('tfrm').style.display != 'none') {	    		
		    	// Don't bother to act if tip is already in view - as specified by cookie
	    		
	    	} else {
	    		
	    		var Callout = getTemplateAddress(CDs[0]);	    		
	    		var IHC = encodeURIComponent(document.location.href);
	    		var isCt = '';
	    		var cT = IHQAMenu.isConsolePage;

	    		if (cT == true) {
	    			
	    			// Add parameter to the search screen reflecting this
	    			// such that results will be sent to a console tab
	    			// NB: this is a parameter that SF seems to use for console tabs: 
	    			// c.f. ControllerSettings.isConsolePage 
	    			isCt = '&isdtp=IHAdded';
	    		}
	    		

	    		// 1.23 - for internationalisation and increased robustness, replaced "escape" with "encodeURI" call throughout the following:
	    		switch (elemType) {
					case 'TipL':					
						IHWebToolTips.DoTips('tfrm', Callout + '?ElemID=' + encodeURIComponent(id) + '&HPL=' + encodeURIComponent(objId) + '&ActiveId=' + CDs[2] + '&elemType=TR0' + isCt + '&IHContext=' + IHC, '3', IHSettings[CWidth], CDs[1], evt);
						break;
						
					case 'TipVL':					
						// Extract the required width from custom class name
						var W = elem.className.substring(elem.className.indexOf('HelpableL_') + 10);
						if (W.indexOf(' ') != -1) {
							W = W.substring(0, W.indexOf(' '));
						}

						IHWebToolTips.DoTips('tfrm', Callout + '?ElemID=' + encodeURIComponent(id) + '&HPL=' + encodeURIComponent(objId) + '&ActiveId=' + CDs[2] + '&elemType=TR0' + isCt + '&IHContext=' + IHC, '8', W, CDs[1], evt);
						break;

					case 'TipR':
						IHWebToolTips.DoTips('tfrm', Callout + '?ElemID=' + encodeURIComponent(id) + '&HPL=' + encodeURIComponent(objId) + '&ActiveId=' + CDs[2] + '&elemType=TL0' + isCt + '&IHContext=' + IHC, '3', IHSettings[CWidth], CDs[1], evt);
						break;
			
					case 'TipVR':			
						// Extract the required width from custom class name
						var W = elem.className.substring(elem.className.indexOf('HelpableR_') + 10);
						if (W.indexOf(' ') != -1) {
							W = W.substring(0, W.indexOf(' '));
						}
						
						IHWebToolTips.DoTips('tfrm', Callout + '?ElemID=' + encodeURIComponent(id) + '&HPL=' + encodeURIComponent(objId) + '&ActiveId=' + CDs[2] + '&elemType=TL0' + isCt + '&IHContext=' + IHC, '2', W, CDs[1], evt);
						break;

					case 'TipCS':			
						IHWebToolTips.DoTips('tfrm', Callout + '?ElemID=' + encodeURIComponent(id) + '&HPL=' + encodeURIComponent(objId) + '&ActiveId=' + CDs[2] + '&elemType=TL0' + isCt + '&IHContext=' + IHC, '2', IHSettings[CWidth], CDs[1], evt);
						break;
						
					case 'TipVD':									
						IHWebToolTips.DoTips('tfrm', Callout + '?ElemID=' + encodeURIComponent(id) + '&HPL=' + encodeURIComponent(objId) + '&ActiveId=' + CDs[2] + '&elemType=T0' + isCt + '&IHContext=' + IHC, '9', 0, CDs[1], evt);
						break;
						
					case 'TipW':
						IHWebToolTips.DoTips('tfrm', Callout + '?ElemID=' + encodeURIComponent(id) + '&HPL=' + encodeURIComponent(objId) + '&ActiveId=' + CDs[2] + '&elemType=T0' + isCt + '&IHContext=' + IHC, '6', 150, CDs[1], evt);
						break;
						
					case 'TipLUXTL0':
						// Lightning field tips - left column
						IHWebToolTips.DoTips('tfrm', Callout + '?ElemID=' + encodeURIComponent(id) + '&HPL=' + encodeURIComponent(objId) + '&ActiveId=' + CDs[2] + '&elemType=TL0' + isCt + '&IHContext=' + IHC, '6', 150, CDs[1], evt);
						break;

					case 'TipLUXTR1':
						// Lightning field tips - right column
						IHWebToolTips.DoTips('tfrm', Callout + '?ElemID=' + encodeURIComponent(id) + '&HPL=' + encodeURIComponent(objId) + '&ActiveId=' + CDs[2] + '&elemType=TR1' + isCt + '&IHContext=' + IHC, '6', 150, CDs[1], evt);
						break;

					default:
						IHWebToolTips.DoTips('tfrm', Callout + '?ElemID=' + encodeURIComponent(id) + '&HPL=' + encodeURIComponent(objId) + '&ActiveId=' + CDs[2] + '&elemType=' + elemType + isCt + '&IHContext=' + IHC, '3', 300, CDs[1], evt);
						break;
				}	    		
	    	}
	    	

			// Set a cookie to record the Id of the active tip
	    	try {
				IHSetCookie('IHActiveCallout', id, 1);	    		
	    	} catch (e) {	    		
	    	}

						
			// We should respond to callout closure behaviour as set in global settings:
			// See also DoTips, which responds to the same setting 
			// as regards the tip itself (not the helped element) setting mouse out as required.
			// See also DoFieldStats / DoPageStats for stats mode
			
			// NB: must not do this for buttons
			if (elem.tagName.toUpperCase() != 'INPUT') {
				setClosureBehaviourForElem(elem);
			}
			
			
	    } catch (e) {
	    	//alert('DT Error: ' + e);
	    }
	                
	    return;
	}


// --------------------------------------------------------------------------------------------------
// Gets the correct VF address to a help template: authors should have marked their template records with a URL in the form namespace.page
// --------------------------------------------------------------------------------------------------
	function getTemplateAddress(TemplatePageURL) {
		var retVal;
    	var PageParts;
    	var Pg = TemplatePageURL;
		
    	
		try {
    		retVal = IHSettings[SFURL];

    		if(TemplatePageURL.indexOf('.') != -1){
    			PageParts = TemplatePageURL.split('.');
    			retVal = retVal.replace(IHSettings[NameSpace], PageParts[0]);
    			Pg = PageParts[1];
    		} 
    		
    		retVal += '/apex/' + Pg;
			
		} catch (e) {
			
		}
		
		return retVal;
	}
		
	
// --------------------------------------------------------------------------------------------------
// Dialogues call this function to stop showing / hide their improved help 
// --------------------------------------------------------------------------------------------------
	function STDlg() {
		IHWebToolTips.StopTips('dfrm');
	    IHWebToolTips.StopTips('IHDialogueWrapper');
		ST();
		return;
	}
	
	
// --------------------------------------------------------------------------------------------------
// Help-enabled page elements call this function to stop showing / hide their improved help 
// --------------------------------------------------------------------------------------------------
	function ST() {

	    IHWebToolTips.StopTips('tfrm');
	    
	    // If any dialogue closure operation requires us to re-navigate, do this here
	    var U = readCookie('IHReNav');

	    if (U != '' && U + '' != 'null') {

	    	// Reset cookie to show we have dealt with need to navigate
	    	IHSetCookie('IHReNav', '', 1);

	    	// Renavigate
			if (window.location.href == U) {
				location.reload(true);
			} else {
		    	window.location.href = U;
			}
	    	
	    }
	    
	    // In order to enable "toggling" of help by clicking helped element (rather than just
	    // mousing out to close help) we re-hook help here: however, we only want to do this
	    // if we're NOT in help enable mode - as hooking will revert us to Saved, so would interfere
	    // with operations in help enable...
	    	    
	    // Note the current mode
	    var M = theCurrentMode.toUpperCase();
	    
	    if (M == 'SAVED' || M == 'STATS') {
	    	HookHelp();

	    	// Hooking will place us back in "Saved" mode - so reset Stats mode here if required
	    	if (M == 'STATS') {
	    		// We need to artificially re-set mode to "Saved" so config routine will
	    		// actually fire (or it will think requested = current mode and stop)
	    		theCurrentMode = 'Saved';
	    		configurePage('Stats');
	    	}
	    }
	    
	    return;
	}


// --------------------------------------------------------------------------------------------------
// Set tip closure behaviour for a helped element (NOT tip frame) based on global settings
// --------------------------------------------------------------------------------------------------
	function setClosureBehaviourForElem(elem) {

		// If we set the calling element's click event to stop tips, the effect
		// of this is to provide a "toggle" on the clicked element to show/hide help
		// instead of / in addition to mouse out (useful for tablets / touch devices 
		// that don't have mouse out).
		// NB: onclick is re-set as required by ST - which re-hooks help
		
		if (IHSettings[CCloseType] == '1') {
			// Close on element toggle only - NO mouse out behaviour
			elem.onclick = ST;
		}
		
		if (IHSettings[CCloseType] == '2') {
			// Close on mouse out only - NO toggle behaviour
		}

		if (IHSettings[CCloseType] == '3') {
			// Close on mouse out or element toggle
			elem.onclick = ST;
		}

		return;
	}
	
// --------------------------------------------------------------------------------------------------
// Set tip closure behaviour for tip frame itself (NOT helped element) based on global settings
// --------------------------------------------------------------------------------------------------
	function setClosureBehaviourForTip(tip) {
		
		// Here we set mouse out behaviour on tip if required:
		// We don't have access to the clicked element - so toggle on this is set 
		// in DT if required...
		
		if (IHSettings[CCloseType] == '1') {
			// Close on element toggle only - NO mouse out behaviour
			tip.onmouseout = '';
		}
		
		if (IHSettings[CCloseType] == '2') {
			// Close on mouse out
			tip.onmouseout = ST;
		}

		if (IHSettings[CCloseType] == '3') {
			// Close on mouse out or element toggle
			tip.onmouseout = ST;
		}
		
	}

	
	
// --------------------------------------------------------------------------------------------------
// Creates an IFRAME in which improved help can be shown, if this doesn't already exist
// plus an associated "click to close" button. Provide the desired frame ID.
// Also creates related "Guide" / VIP highlight and prompt furniture
// --------------------------------------------------------------------------------------------------
	function MakeTipFrame(TFID) {
	
		var x = document.getElementById(TFID);
		var TF;
		var eDiv;
		var eMkup;
		var LUXGuideMode = IHSettings[BrandUXOption];
		
		// NB: setting can be one of several that indicate LUX flavour guides are to be used		
		if (LUXGuideMode > '1') {LUXGuideMode = true;} else {LUXGuideMode = false;}
		
		
		if (x + '' == 'null') {	
			
		    TF = document.createElement("iframe");
		    TF.id = TFID;
		    TF.style.display = 'none';
		    TF.style.zIndex = '70001';
		    TF.frameBorder = '0';
		    TF.scrolling = 'no';			
		    TF.allowTransparency='true';
		    
		    document.body.appendChild(TF);
		    
			// ADD A "CLICK TO CLOSE (IFRAME)" BUTTON
		    // NB: if we're showing click to close, it means we're closing a DIALOGUE (dfrm).
		    // So: we cue a wrapper that closes dfrm (as well as tfrm)...

		    if (document.getElementById('IHDialogueWrapper') + '' == 'null') {
				eDiv = document.createElement("div");
				eMkup = '<div id="IHDialogueCloser" title="' + Internationalise('[QAMTitleButtonClose]') + '" class="IHIcon IHIconClose" style="z-index: 80000;" onclick="javascript:STDlg();" ></div>';
			
				eDiv.id = 'IHDialogueWrapper';
				eDiv.innerHTML = eMkup;
				eDiv.style.display = 'none';
		    	eDiv.style.zIndex = '70000';
		    	
				document.body.appendChild(eDiv);	
		    }

		    
		    // Add guide furniture
		    if (document.getElementById('IHPrompt') + '' == 'null') {
		    			    	
		    	// Prompt - which is built according to global branding options / classic or LUX flavour...
				eDiv = document.createElement("div");
				eDiv.innerHTML = getGuidePopover(LUXGuideMode, false);
				if (LUXGuideMode == true) {eDiv.className = 'IHLUX';}
				eDiv.id = 'IHPrompt';
				eDiv.style.display = 'none';
				document.body.appendChild(eDiv);		    	
		    	
				
		    	// Step List
				eDiv = document.createElement("div");
				eMkup = 'Steps';
				eDiv.id = 'IHStepList';
				eDiv.innerHTML = eMkup;
				eDiv.style.display = 'none';

				// Step list positioning within the DOM is dependent on whether we're in LUX mode
				if (LUXGuideMode == false) {
					document.body.appendChild(eDiv);		
				} else {
					eDiv.className = 'IHLUX';
					document.getElementById('LuxModeStepList').appendChild(eDiv);		
				}			
				

				// Guide enable mode helper
				eDiv = document.createElement("div");
				eDiv.id = 'IHGEHelper';
		    	eDiv.style.zIndex = '70000';	    	

				eMkup =  '<table>';
				eMkup += '<tr><td colspan="2">';
				eMkup += '<div title="' + Internationalise('[QAMTitleButtonSaveStep]') + '" style="float: right; cursor: pointer;" class="IHIcon IHIconClose" onclick="javascript:hideHelper();"></div>';
				eMkup += '<div title="' + Internationalise('[QAMTitleButtonDeleteStep]') + '" style="float: right; cursor: pointer; padding-right: 3px;" class="IHIcon IHIconDelete" onclick="javascript:RemoveGuideStep();"></div>';
				eMkup += '</td></tr>';
				eMkup += '<tr><td>Name:</td><td><input id="IHGEStepName" type="text" onchange="javascript:setHelperDirty(\'E\');"/></td></tr>';
				eMkup += '<tr><td>Summary:</td><td><input id="IHGEStepSummary" type="text" onchange="javascript:setHelperDirty(\'E\');"/></td></tr>';
				eMkup += '<tr><td>Order:</td><td><select id="IHGEStepOrder" onchange="javascript:setHelperDirty(\'E\');"></select></td></tr>';				
				eMkup += '</table>';
				eMkup += '<input id="IHGEElemId" type="hidden" style="background-color: red;" />';				
				eMkup += '<input id="IHGERLEId" type="hidden" style="background-color: blue;" />';				
				eMkup += '<input id="IHGEElemType" type="hidden" style="background-color: green;" />';				
				eMkup += '<input id="IHGEDirty" type="hidden" style="background-color: yellow;" />';				
				
				eDiv.innerHTML = eMkup;
				eDiv.style.display = 'none';
				document.body.appendChild(eDiv);		
		    }

		    
		    // Add a "waiting" (login check) DIV...
		    if (document.getElementById('IHTipPending') + '' == 'null') {
				eDiv = document.createElement("div");
				
				// 1.29: strict mode does not allow style to be set in IE - use class instead
				//eDiv.style='display: none; background: url(/resource/iahelp__IHResources/img/loading.gif); background-repeat: no-repeat; background-position: center;';
				eDiv.className = 'IAIHWaiting IHHidden';
				
                eDiv.id = 'IHTipPending';
				document.body.appendChild(eDiv);		
		    }
		    
		}
			
		return;
	}

	
// --------------------------------------------------------------------------------------------------
// Returns the mark up (inner HTML) to use for a guide prompt, based on options passed in call
// --------------------------------------------------------------------------------------------------	
	function getGuidePopover(LUXGuideMode, ShowBody) {
		
		var eMkup = '';
		
		if (LUXGuideMode == false) {
			// Return classic prompt:
			// NB: No internationalisation in following line as the prompt ultimately comes from help topic			
			eMkup = '<div id="PromptMessage" style="float: left; margin-right: 10px;">Prompt Message</div>';
			
			eMkup += '<div title="' + Internationalise('[QAMTitleButtonClosePrompt]') + '" style="float: right; cursor: pointer; margin-top: 3px; margin-left: 2px;" class="IHIcon IHIconClose" onclick="javascript:hideLinearPrompt();"></div>';				
			eMkup += '<div id="IHStepListIcon" title="' + Internationalise('[QAMTitleButtonShowNonLinearSteps]') + '" style="float: right; cursor: pointer;" onclick="javascript:showStepList(this)"></div>';
			eMkup += '<div id="IHNextStepIcon" title="' + Internationalise('[QAMTitleButtonGotoNextStep]') + '" style="float: right; cursor: pointer;" onclick="javascript:showNextStep();"></div>';
			
		} else {
			// Return LUX popover
			eMkup += '<div class="slds-scope">';
			
			// Popover container
			eMkup += '<section id="PromptPopover" class="slds-popover slds-popover_walkthrough" ';
			eMkup += 'role="dialog"';
			eMkup += 'aria-describedby="PromptMessage"';
			eMkup += 'aria-labelledby="PromptMessage">';
			
			// Close button
			eMkup += '<button class="slds-button slds-button_icon slds-button_icon-small slds-float_right slds-popover__close slds-button_icon-inverse" ';
			eMkup += 'onclick="javascript:hideLinearPrompt();" '
			eMkup += 'title="' + Internationalise('[QAMTitleButtonClose]') + '">';
			
			// 1.37 - not easy to get this to appear in classic: switch to a simple cross...
			//eMkup += '<i class="fa fa-times" aria-hidden="true"></i>';
			eMkup += '<span style="font-size: 1.8em;">&#735</span>';
			
			eMkup += '<span class="slds-assistive-text">' + Internationalise('[QAMTitleButtonClose]') + '</span>';
			eMkup += '</button>';
			
			// Header text
			eMkup += '<header class="slds-popover__header slds-p-vertical_medium">';
			eMkup += '<h2 id="PromptMessage" class="slds-text-heading_medium">';
			eMkup += 'HEADER TEXT SET BY STEP';			
			eMkup += '</h2>';
			eMkup += '</header>';
			
			// Body area - text, image and video
			if (ShowBody == true) {
				eMkup += '<div id="PromptBody" class="slds-popover__body">';
			} else {
				eMkup += '<div id="PromptBody" class="slds-popover__body slds-hide">';				
			}
			eMkup += '<div id="PromptBodyText" class="slds-hide"></div>';
			eMkup += '<img id="PromptImage" class="slds-hide" style="height: 150px; padding-top: 5px;"  src="" />';
			eMkup += '<div id="PromptVideo" class="slds-hide" style="padding-top: 5px;"></div>';			
			eMkup += '</div>';
			
			// Footer opening and text
			eMkup += '<footer class="slds-popover__footer">';
			eMkup += '<div id="IHNextStepIcon" class="slds-grid slds-grid_vertical-align-center">';
			eMkup += '<span id="IHFooterText" class="slds-text-title">';
			eMkup += 'FOOTER TEXT EG STEP NUM';
			eMkup += '</span>';
			
			// Footer nav - linear (button)
			eMkup += '<button class="slds-button slds-button_brand slds-col_bump-left" ';
			eMkup += 'title="' + Internationalise('[QAMTitleButtonGotoNextStep]') + '" ';
			eMkup += 'onclick="javascript:showNextStep();">';
			eMkup += Internationalise('[QAMButtonGotoNextStep]');
			eMkup += '</button>';
			eMkup += '</div>';
						
			// Footer nav - non-linear (step list)
			eMkup += '<div class="slds-form-element">';
			
			eMkup += '<label class="slds-form-element__label slds-assistive-text" for="stepList">';
			eMkup += 'Assistive Field Label';			
			eMkup += '</label>';
			
			eMkup += '<div id="LuxModeStepList" class="slds-form-element__control">';
			eMkup += '</div>';
			
			eMkup += '</div>';
			eMkup += '</footer>';
			eMkup += '</section>';

			eMkup += '</div>';			
		}
		
		return eMkup;
	}
	
	
	
	
// --------------------------------------------------------------------------------------------------
// Returns the helped element type of a given element
// --------------------------------------------------------------------------------------------------
	function getElementType(elem){
		
		var typ = 'TBA';
		var i;
		var elems;
		
		try {
						
			if (typ == 'TBA') {
				elems = null;
				elems = GetHelpableElements('FIELDS');
				for (i = 0; i < elems.length; i++) {
					if (elem == elems[i]) {
						typ = 'Field';
						break;
					}
				}
			}
			
			if (typ == 'TBA') {
				elems = null;
				elems = GetHelpableElements('DETAILAREAS');
				for (i = 0; i < elems.length; i++) {
					if (elem == elems[i]) {
						typ = 'Detail Section Label';
						break;
					}
				}
			}

			if (typ == 'TBA') {
				elems = null;
				elems = GetHelpableElements('RECORDTITLES');
				for (i = 0; i < elems.length; i++) {
					if (elem == elems[i]) {
						typ = 'Record Title';
						break;
					}
				}
			}

			if (typ == 'TBA') {
				elems = null;
				elems = GetHelpableElements('CUSTOMAREAS');
				for (i = 0; i < elems.length; i++) {
					if (elem == elems[i]) {
						typ = 'Custom Section Label';
						break;
					}
				}
			}

			if (typ == 'TBA') {
				elems = null;
				elems = GetHelpableElements('RLISTTITLES');
				for (i = 0; i < elems.length; i++) {
					if (elem == elems[i]) {
						typ = 'Related List Label';
						break;
					}
				}
			}
			
			if (typ == 'TBA') {
				elems = null;
				elems = GetHelpableElements('RLISTCOLUMNS');
				for (i = 0; i < elems.length; i++) {
					if (elem == elems[i]) {
						typ = 'Related List Column Label';
						break;
					}
				}
			}
			
			if (typ == 'TBA') {
				elems = null;
				elems = GetHelpableElements('RLISTOBJECTS');
				for (i = 0; i < elems.length; i++) {
					// Check here is more involved as the clicked item is likely to be a child
					// of the helpable element					
					if (elems[i].innerHTML.indexOf(elem.innerHTML) != -1 && elem.innerHTML != '') {
						typ = 'Related List Help Link';
						break;
					}
				}
			}
			
			if (typ == 'TBA') {
				elems = null;
				elems = GetHelpableElements('SFBUTTONS');
				for (i = 0; i < elems.length; i++) {
					if (elem == elems[i]) {
						typ = 'Button';
						break;
					}
				}
			}
			
			if (typ == 'TBA') {
				elems = null;
				elems = GetHelpableElements('SFMENUBUTTONS');
				for (i = 0; i < elems.length; i++) {
					if (elem == elems[i]) {
						typ = 'Button';
						break;
					}
				}
			}
			
			if (typ == 'TBA') {
				elems = null;
				elems = GetHelpableElements('CUSTOMLINKS');
				for (i = 0; i < elems.length; i++) {
					if (elem == elems[i]) {
						typ = 'Custom Link';
						break;
					}
				}
			}
			
			if (typ == 'TBA') {
				elems = null;
				elems = GetHelpableElements('VFPAGES');
				for (i = 0; i < elems.length; i++) {
					if (elem == elems[i]) {
						typ = 'Visualforce Element';
						break;
					}
				}
			}
			
			if (typ == 'TBA') {
				elems = null;
				elems = GetHelpableElements('SIGNATURES');
				for (i = 0; i < elems.length; i++) {
					if (elem == elems[i]) {
						typ = 'Signature Element';
						break;
					}
				}
			}
			
		} catch (e) {
			typ = 'Err!';
		}
		
		return typ;
		
	}	
	
	
	// --------------------------------------------------------------------------------------------------
	// Check whether an element is of a "signature" type - i.e., it
	// is identifiable via a customer entered "signature" as opposed to one of IH's pre-set "known" helpables:
	// If this is a signature element, we return the attribute that should be used as the
	// element identifier
	// --------------------------------------------------------------------------------------------------
	function SignatureAttribute(elem) {

		var retVal = '';
		var knownSigs;
		var sig;
		var sigElems;
		var i;
		var j;
		var sDefs;
		
		
		// Get the list of known signature elements (from settings):
		// See ControllerSettings.getSignatures for format...
		sDefs = IHSettings[SigDetails];
		
		try {
			if (sDefs != '') {
				knownSigs = sDefs.split(settingsD1);
								
				for (i = 0; i < knownSigs.length; i++) {
					
					// Use the list of known signatures to get all elements of each type in turn
					sig = knownSigs[i].split(settingsD2);
					sigElems = $IAIHj(sig[0]);				

					// If current element matches any of those we find, we have a sig element, so return signature details
					for (j = 0; j < sigElems.length; j++) {
						if (sigElems[j] == elem) {
							retVal = knownSigs[i];
							break;
						}
					}
				}				
			}
			
		} catch (e) {
			//alert('Error processing Helped Element signatures: ' + e);
			retVal = '';
		}
			
		return retVal;
	}
	
	
	// --------------------------------------------------------------------------------------------------
	// Gets the relevant identification string to use to identify a given page element
	//
	// elem			= the page element for which an ID is sought
	//
	// Returns an id string
	// --------------------------------------------------------------------------------------------------
	function getElementIdString(elem) {
		
		
		try {			

			var retVal = '';
			var sAttr = SignatureAttribute(elem);			
			
			// For VF page elements only, we take the markup ID itself UNLESS a Signature is in play:
			// NOTE: VF positioning tags used in some non-VF circumstances (e.g., record titles), so check also
			// for additional class that marks these out...
			if (sAttr == '' 
					&& ($IAIHj(elem).hasClass('Helpable') || elem.className.indexOf('HelpableL_') != -1 || elem.className.indexOf('HelpableR_') != -1 || elem.className.indexOf('HelpableToDiv_') != -1)
					&& $IAIHj(elem).hasClass('IHHelpedPositioned') == false) {
				retVal = elem.id;
				return retVal;
			}
			
	
			// For "signature" helpable elements, we take the value of the attribute defined with the signature record as the identifier 			
			if (sAttr != ''){
				
				//alert('getElementIdString - sig attr: ' + sAttr);				
				
				// If signature element details were found, these will be in the form:
				// [Signature] {d2} [Identifier] {d2} [Identifier Type] {d1}
				// SEE ALSO: ControllerSettings.getSignatures
				sAttr = sAttr.split(settingsD2);

				switch (sAttr[2]) {
					case 'Property':
						retVal = stringTrim($IAIHj(elem).prop(sAttr[1]));
						return retVal;
						break;
						
					case 'Attribute':
						retVal = stringTrim($IAIHj(elem).attr(sAttr[1]));
						return retVal;
						break;
						
					case 'Text':
						retVal = stringTrim($IAIHj(elem).text());
						return retVal;
						break;
						
					case 'Html':
						retVal = stringTrim($IAIHj(elem).html());
						return retVal;
						break;
				}				
			}

			
			// Otherwise, we may have to strip out further mark up to get the id:
			// This varies depending on the element being help enabled...
			if (typeof(elem.className) != 'undefined') {
				
				if (elem.className == 'helpLink') {
					// Page level help:
					// In this case, the ID is the page object
					retVal = IHSettings[SFObjId];
	
				} else if (elem.className == 'help') {
					// Help for page objects:			
					// In this case, we'll manipulate the span as a whole, but the helped element
					// identifier is contained in a child span, class = 'linkSpan' (if presently unhelped)
					// or, is the inner text if helped...
					
					var x = elem.getElementsByTagName("span");
					
					if (x.length > 0) {
						retVal = x[0].innerHTML;
					} else {
						retVal = getInnerText(elem);
					}

				} else if (elem.tagName.toUpperCase() == 'INPUT' && elem.className.indexOf('btn') != -1) {
					// SF standard / custom buttons:
					// Return button name - but as this is minimal and could feature elsewhere,
					// add further identification to it...
					
					// If button has been added "stand alone" as apex:commandButton, name of
					// HE we need will not just be the name - we'll need to cut off the dynamic aspects.
					// If full name contains ":", cut all before this
					if (elem.name.indexOf(':') != -1) {
						retVal = 'Salesforce ' + elem.name.substring(elem.name.lastIndexOf(':') + 1) + ' button';
					} else {
						retVal = 'Salesforce ' + elem.name + ' button';
					}

				} else if (elem.className.indexOf('labelCol') != -1) {
					// SF field labels:
					// These can contain multiple tags (e.g., hidden "max length counters" etc):
					// We only want the text of the associated label if there is one
					var x = elem.getElementsByTagName("label");
					
					if (x.length > 0) {
						retVal = getInnerText(x[0]);
					} else {
						retVal = getInnerText(elem);
					}			
					
				} else {						
					retVal = getInnerText(elem);						
				}
				
			} else {
				retVal = getInnerText(elem);

			}
			
			
			// Remove any "required mark" from this, manifested as HTML or inner text
			retVal = retVal.replace ('<span class="requiredMark">*</span> ', '');
			if (retVal.substring(0,1) == '*') {
				retVal = retVal.substring(1);
			}
				
	
			// If standard help is present strip this
			if (retVal.toUpperCase().indexOf('SFDCPAGE.SETHELP') != -1) {
				retVal = retVal.substring(0, retVal.toUpperCase().indexOf('SFDCPAGE.SETHELP'));
			}
			
			
			// Remove any leading / trailing spaces
			retVal = stringTrim(retVal);
			return retVal;


		} catch (ex) {
			//alert('getElementIdString ERROR: ' + ex);
			return '';
		}
				
	}


// --------------------------------------------------------------------------------------------------
// Shield our code from browser specific implementations of element's innerText implementations
// --------------------------------------------------------------------------------------------------
	function getInnerText(elem) {
		
		var retVal;
		
		try {
			retVal = $IAIHj(elem).text();

		} catch (ex) {
			retVal = '';
		}
		
		return retVal;
	}
	
	
// --------------------------------------------------------------------------------------------------
// Place the current page in one of several operating modes known to improved help
// --------------------------------------------------------------------------------------------------
	function configurePage(mode, evt) {
		
		var f;		// for looping
		var e;		// for looping
		var t;		// tables
		var c;		// collections of HTML elements of various kinds being checked for help-ability
		var U = '';	// dialogue addresses (URLs)
	
		
		try {
			
			if(!evt) evt = window.event;			
			
			// We should act if there's been a loss of session (logout, timeout):
			// check session here and if it's not valid, advise user to refresh / login.
			var checkS = IHWebToolTips.checkSessionState(document.URL);		
			if (checkS == 0) {
				alert(Internationalise('[QAMMessageLoggedOut]'));
				return;
			}
	
		
			// Only continue if we're not already in the stated mode.
			if (theCurrentMode.toUpperCase() == mode.toUpperCase()) {
				return;
			}
			
			// Also, only allow transitions through SAVED mode (not direct from one form of config to another)
			if (theCurrentMode.toUpperCase() != 'SAVED' && mode.toUpperCase() != 'SAVED') {
				return;
			}
	
			
			var bdy = document.getElementsByTagName('body');
			bdy = bdy[0];
			
					
			if (mode.toUpperCase() == 'SAVED') {
				//----------------------------------------------------------------------------------------								
				// If we're saving, run routine to respond to any config actions by showing confirm page:
				// NB: this also re-hooks help, taking care of the page furniture to show help enabled elements
				//----------------------------------------------------------------------------------------
				
				if (theCurrentMode.toUpperCase() == 'CONFIGURE') {
					U = getConfirmHEActionsURL();
					
					// If we've been passed IHContext, pass this on to confirm dialogue
					var IHCXT;
					try {
						IHCXT = new RegExp('[?&]IHContext=([^&#]*)').exec(window.location.href);
					
						IHCXT = IHCXT[1] || 0;
					} catch (e) {
						IHCXT = null;
					}
					
					if (IHCXT != null && U != '') {
						U += '&IHContext=' + IHCXT;
					}

				}
				if (theCurrentMode.toUpperCase() == 'GENABLE')   {					
					// Save any open guide enabling helper...
					hideHelper();
					U = getConfirmGEActionsURL();
				}
				

				if (U != '') {

					// Set a cookie to advise dialogue closure routine (ST) that
					// a page refresh will be required on exit
					IHSetCookie('IHReNav', document.location.href, 1);

					HookHelp();

					// Re-set body as a whole (to lose any mode wallpaper).
					bdy.className = bdy.className.replace('IHHelpEnableMode', '');
					bdy.className = bdy.className.replace('IHAnalyseMode', '');
					bdy.className = bdy.className.replace('IHReconfigureMode', '');
					bdy.className = bdy.className.replace('IHGuideEnableMode', '');
					bdy.className = bdy.className.replace('IHBranded', '');
					bdy.className = stringTrim(bdy.className);

					theCurrentMode = mode;	

					IHQAMenu.SetupQAM(mode);
				
					IHWebToolTips.DoTips("dfrm", U, "7", 500, 400, evt);	
					return;
					
				} else {
					// If no change has been made, we'll still need to refresh the page
					// to deal with buttons, whose function will have been changed to allow
					// enabling, and cannot otherwise be restored:
					
					location.reload(true);
				}
								
				HookHelp();

	
			} else {
				//-------------------------------------------------------------				
				// If not saving, we need to re-set page furniture to suit mode
				//-------------------------------------------------------------				
	
				// First, visual cues if we're in help enable mode...
				if (mode.toUpperCase() == 'CONFIGURE') {
					
					// Wallpaper for the page as a whole
					bdy.className += (bdy.className == '' ? 'IHHelpEnableMode' : ' IHHelpEnableMode');
					
					// Plus, additional clues on each helpable element
					c = null;
					c = GetHelpableElements('');
									
					for (e = 0; e < c.length; e ++) {
						c[e].className += (c[e].className == '' ? 'HelpableSFElement' : ' HelpableSFElement');
					}
				}
	
	
				// Visual cues if we're in stats mode...
				if (mode.toUpperCase() == 'STATS') {
					
					// Wallpaper for the page as a whole
					if (bdy.className.indexOf('IHAnalyseMode') == -1) {
						bdy.className += (bdy.className == '' ? 'IHAnalyseMode' : ' IHAnalyseMode');					
					}
				}
				

				// Visual cues if we're in reconfigure mode...
				if (mode.toUpperCase() == 'RECON') {
					
					// Wallpaper for the page as a whole
					if (bdy.className.indexOf('IHReconfigureMode') == -1) {
						bdy.className += (bdy.className == '' ? 'IHReconfigureMode' : ' IHReconfigureMode');					
					}
				}
				
				
				// If ENTERING Guide enable mode (QAM alone does this) ...
				if (mode.toUpperCase() == 'GENABLEENTRY') {
					
/*					
					// Show RL (Guide) selection dialogue
					U = IHSettings[SFURL] + '/apex/iahelp__IHSearchResults?Opts=8&Term=*';
					
					IHWebToolTips.DoTips("dfrm", U, "7", 600, 440, evt);
					
					// Set a cookie to advise dialogue closure routine (ST) that
					// a page refresh will be required on exit
					IHSetCookie('IHReNav', document.location.href, 1);
*/
					
// v1.41+ : deprecating classic GE mode: issue advisory message only
// (Note re-purposing of otherwise deprecated guide translation code)					
alert(Internationalise('[QAMMessageGuideLostContext]'));					

// Take no further action / do NOT actually change mode
return;

					
				}
				

				// If we have ENTERED Guide enable mode (settings loader spots GE params) set Visual cues 
				if (mode.toUpperCase() == 'GENABLE') {

					// Wallpaper for the page as a whole:
					// NB: as guide enabling ops span VF and SF pages, we only want this
					// wallpaper set on the VF page itself...
					if (document.location.href.toUpperCase().indexOf('VISUAL.FORCE.COM/APEX/') == -1) {
						if (bdy.className.indexOf('IHGuideEnableMode') == -1) {
							bdy.className += (bdy.className == '' ? 'IHGuideEnableMode' : ' IHGuideEnableMode');					
						}
					} 
					
					// Plus, additional clues on each guidable element
					// NB: we DON'T want this on page help - so remove here
					c = null;
					c = GetHelpableElements('');
									
					for (e = 0; e < c.length; e ++) {
						c[e].className += (c[e].className == '' ? 'GuidableSFElement' : ' GuidableSFElement');
					}					
					c = null;
					c = GetHelpableElements('Pages');
									
					for (e = 0; e < c.length; e ++) {
						c[e].className = c[e].className.replace('GuidableSFElement', '');
					}


					// Also, clear any guide enabling cache
					cacheClear();		
					
					// In these cases, we can assume there are helpable elements
					// because otherwise we could not have entered GEnableEntry mode 
					// (QAM rows for mode switching would have been hidden)
					hasHelpableElements = true;
					
					// Mark elements that are already in the Guide
					HookGEMode();
				}
				
				
				//--------------------------------------------
				// NOW CONFIGURE INDIVIDUAL SCREEN ELEMENTS
				//--------------------------------------------				

				// LOCALLY DEFINED "SIGNATURE" HELPABLES
				configureElementType('Signatures', mode);
				
				// HELP AND TRAINING PORTAL LINK
				configureElementType('HTPortalLinks', mode);

				// PAGE LEVEL HELP
				configureElementType('Pages', mode);
				
				// RECORD TITLES
				configureElementType('RecordTitles', mode);			
				
				// DETAIL AREA SECTION HEADINGS
				configureElementType('DetailAreas', mode);

				// CUSTOM SECTION HEADINGS
				configureElementType('CustomAreas', mode);
				
				// RELATED LIST SECTION HEADINGS
				configureElementType('RListTitles', mode);
	
				// RELATED LIST OBJECT HELP
				configureElementType('RListObjects', mode);
							
				// RELATED LIST COLUMNS
				configureElementType('RListColumns', mode);
				
				// FORM FIELD LABELS
				configureElementType('Fields', mode);
				
				// VF Elements
				configureElementType('VFPages', mode);
						
				// STANDARD AND CUSTOM SF BUTTONS
				configureElementType('SFButtons', mode);

				// SF MENU BUTTONS
				configureElementType('SFMenuButtons', mode);

				// CUSTOM LINKS
				configureElementType('CustomLinks', mode);
				
				
				// All elements: if they're DDF fails (ie., helped element already exists but is not
				// shown on current record) we need to disable activities whilst in most modes.
				if (mode.toUpperCase() != 'SAVED' && mode.toUpperCase() != 'RECON' && mode.toUpperCase() != 'STATS') {
					
					c = null;
					c = GetHelpableElements('');
					
					for (e = 0; e < c.length; e ++) {
						t = getElementIdString(c[e]);
						
						// For help enable mode, we should revert to showing helped element dialogue
						if (mode.toUpperCase() == 'CONFIGURE') {
							if ($IAIHj(c[e]).hasClass('IHDDFFailElement')) {
								c[e].onclick = ShowError;					
							}
						}
						
						// For guide enablemode, we must disable all activity
						if (mode.toUpperCase() == 'GENABLE') {
							if ($IAIHj(c[e]).hasClass('IHDDFFailElement')) {
								c[e].onclick = '';					
							}
						}
					}
				}
				
				
				// In all modes other than saved, we're adding a background to the page, which may need adjustment
				// for communities use: so, add our "branded" marker here and call community handler...
				$IAIHj(bdy).addClass('IHBranded');
				try {
					IHCommunities.IAIHInitialiseForCommunities();
				} catch (e) {}
				
				
			} 	// End if mode is NOT saved
			
		} catch (e) {
			alert(Internationalise('[QAMMessageGenericError]') + ' - (Configure Page) ' + e);
		}
		
	
		// Enable / disable relevant QAM items
		IHQAMenu.SetupQAM(mode);
	
		
		// If using standard QAM, hide the quick access menu on setting mode...
		if (document.URL.toUpperCase().indexOf('/APEX/IHQAM') == -1) {
			if(document.getElementById('IHQAM').style.right == '0px') {
				IHQAMenu.moveQAM();							
			}
		}

		
		theCurrentMode = mode;
		return;
	}

	
// --------------------------------------------------------------------------------------------------
// Place individual groups of helped elements into the requested operating mode
// --------------------------------------------------------------------------------------------------
	function configureElementType(elemType, mode) {

		var e;					// for looping
		var c;					// collections of HTML elements of various kinds being checked for help-ability
		var s;					// For use obtaining control id strings
		var id;					// Identifier of a helped element
		var CalloutDetails;		// Callout details string for a given helped element
		var CDs;				// Above split into an array
		
		
		// Get all potentially helpable elements of the requested type
		c = GetHelpableElements(elemType);
	
		
		// Loop through these
		for (e = 0; e < c.length; e ++) {
			
			// In all cases, unless we're in read mode ...
			if (mode != 'Saved') {
				
				// We don't want "New" flags on elements
				$IAIHj(c[e]).removeClass('IHCollateralUpdated');

				// We don't want standard hyperlinking behaviour - unless set by ourselves elsewhere
				if ($IAIHj(c[e]).attr('href') + '' != 'undefined') {
					$IAIHj(c[e]).attr('href', 'javascript:void(0);');
					$IAIHj(c[e]).attr('target', '');
				}
				
				// Ditto for page help links...
				if (elemType == 'Pages') {
					$IAIHj(c[e].parentNode).attr('href', 'javascript:void(0);');
					$IAIHj(c[e].parentNode).attr('target', '');					
					$IAIHj(c[e]).find('a').attr('href', 'javascript:void(0);');
					$IAIHj(c[e]).find('a').attr('target', '');					
				}
			}
			

			// Remaining behaviour depends on element type
    		switch (elemType) {

    			case 'HTPortalLinks':
    			case 'Pages':
				case 'RecordTitles':
				case 'DetailAreas':
				case 'CustomAreas':
				case 'RListTitles':
				case 'RListColumns':
				case 'RListObjects':
    			case 'Fields':
				case 'VFPages':
				case 'Signatures':
					
					// For configure mode, highlight element on click, but only
					// if there is a legitimate field name
					if (getElementIdString(c[e]) != '') {
						if (mode.toUpperCase() == 'CONFIGURE') {
							c[e].onclick = toggleHighlight;
						}
					}					
					
					// For re-configure mode, prepare to show helped element screen...
					if (mode.toUpperCase() == 'RECON') {

						// ... but only for helped elements
						if (HelpAvailableFor(c[e]) == 1) {
							c[e].onclick = DoReconHelpedElement;	
							
							// Also, add recon styling
							$IAIHj(c[e]).addClass('IHHelpRecon');
														
							// In reconfigure mode, add extra visual clues if data driven filters are in play and
							// there is >1 HE record defined for a given element: this will have been recorded
							// in callout details...
			
							// NB: most callout details are stored with direct identifier, but page help will have been
							// tagged with object identifier for the page
							if (elemType == 'Pages') {
								id = IHSettings[SFObjId];
							} else {
								id = getElementIdString(c[e]);
							}
							
					    	CalloutDetails = getCalloutDetails(id) + '';
					    	CDs = CalloutDetails.split(String.fromCharCode(7));
		
					    	// If there is more than 1 helped element for this helpable...
					    	if (CDs[4] != '0') {					    		
					    		
					    		// Add a class to mark the fact there's >1 HE: we offer 1 - 4 then 5+ as available markings...
					    		var numClass = (parseInt(CDs[4]) < 5 ? CDs[4] : '5');					    							    		
					    		$IAIHj(c[e]).removeClass('IHHelpedSFElement').addClass('IHHelpedSFElementX' + numClass);
					    		
					    		// For page help, also manipulate child help div
					    		$IAIHj(c[e]).find('div').removeClass('IHPageHelpLink').addClass('IHHelpedSFElementX' + numClass);
					    	}
					    	
						}
					}					
					
					// For stats mode, prepare to show stats... 
					if (mode.toUpperCase() == 'STATS') {
						
						// ... but only for helped elements (or those with DDF fails)
						if (HelpAvailableFor(c[e]) == 1 || $IAIHj(c[e]).hasClass('IHDDFFailElement')) {
				
							// Add help stats styling throughout:							
							// Page level behviour differs slightly from the rest
							if (elemType == 'Pages') {

								// As these are hyperlinks, we need to make slightly different amendments
								var x = c[e].parentNode;
								x.innerHTML = '<span class="helpLink"><div class="IHPageHelpLink IHHelpStats">' + Internationalise('[QAMButtonPageHelpLink]') + '</div></span>';
								x.onclick = DoPageStats;					
								
							} else {
								
								$IAIHj(c[e]).removeClass('IHHelpedSFElement').addClass('IHHelpStats');
								c[e].onclick = DoFieldStats;			
							}
							
						}												 
					}

					// For Guide enable mode, offer guide config controls:	
					// However, this is NOT relevant for page help as this cannot be shown as a guide step / viewed in place
					if (mode.toUpperCase() == 'GENABLE' && elemType != 'Pages') {
						c[e].onclick = LogGuideStep;
					}
										
    				break;
    				
				case 'SFButtons':
				case 'SFMenuButtons':
				case 'CustomLinks':

					// For configure mode, highlight element on click, but only
					// if there is a legitimate field name
					if (getElementIdString(c[e]) != '') {
						if (mode.toUpperCase() == 'CONFIGURE') {
							c[e].onclick = toggleHighlight;
							c[e].onmouseover = '';
							
							// For non-menu SF buttons, we need to change type from "submit" (or they'll post their form!)
							if (elemType == 'SFButtons') {
								c[e].type = 'button';
							}
						}
					}					
					
					
					// For re-configure mode, prepare to show helped element screen...
					if (mode.toUpperCase() == 'RECON') {
												
						// ... but only for helped elements
						if (HelpAvailableFor(c[e]) == 1) {

							s = c[e].id + 'ClickHelper';							
							s = document.getElementById(s);							
							
							if (s + '' != 'null') {
								s.onclick = DoReconHelpedElement;	
								
								// Also, add recon styling:
								$IAIHj(s).addClass('IHHelpRecon');

								// In reconfigure mode, add extra visual clues if data driven filters are in play and
								// there is >1 HE record defined for a given element: this will have been recorded
								// in callout details...
				
								id = getElementIdString(c[e]);								
						    	CalloutDetails = getCalloutDetails(id) + '';
						    	CDs = CalloutDetails.split(String.fromCharCode(7));
			
						    	// If there is more than 1 helped element for this helpable...
						    	if (CDs[4] != '0') {					    		
						    		
						    		// Add a class to mark the fact there's >1 HE: we offer 1 - 4 then 5+ as available markings...
						    		var numClass = (parseInt(CDs[4]) < 5 ? CDs[4] : '5');
									$IAIHj(s).removeClass('IHHelpedSFElement').addClass('IHHelpedSFElementX' + numClass);
						    	}
							}							
						}
					}
					
					
					// For stats mode, prepare to show stats... 
					if (mode.toUpperCase() == 'STATS') {
						
						// ... but only for helped elements
						if (HelpAvailableFor(c[e]) == 1 || $IAIHj(c[e]).hasClass('IHDDFFailElement')) {
							
							s = c[e].id + 'ClickHelper';							
							s = document.getElementById(s);
							
							if (s + '' != 'null') {							
								// Make it cue stats								
								s.onclick = DoButtonStats;

								// Change its style
								$IAIHj(s).removeClass('IHClickHelper').addClass('IHHelpStats');
							}							
						}												 
					}


					// For Guide enable mode, offer guide config controls:	
					if (mode.toUpperCase() == 'GENABLE') {
						
						// However, we don't want this with buttons on the VF screens used as part of the guide enabling process
						if (elemType == 'SFButtons') {
							if (document.location.href.toUpperCase().indexOf('/APEX/IHSEARCHRESULTS') == -1 && document.location.href.toUpperCase().indexOf('/APEX/IAHELP__IHSEARCHRESULTS') == -1) {
								// NB: when editing a SF record, we need to change type from "submit"... 
								c[e].type='button';
								c[e].onclick = LogGuideStep;
							}							
							
						} else {
							c[e].onclick = LogGuideStep;
						}
					}

					break;
					
				default:
					// Shouldn't get in here
					break;
				
    		} // End switch by type			
		} // End loop around helped elements of requested type
		
		return true;
	}
	
	
// --------------------------------------------------------------------------------------------------
// Switches "active for new help topic" highlight on and off for a given clicked element 
// --------------------------------------------------------------------------------------------------
	function toggleHighlight(evt) {
	
		if(!evt) evt = window.event;	
		var elem = evt.target||evt.srcElement;

		// Check which state the element is in and proceed accordingly:		
		// Unmarked -> ToBeHelped
		if (elem.className.indexOf('ToBeHelped') == -1        && 
			elem.className.indexOf('ToBeUnhelped') == -1      &&
			elem.className.indexOf('IHHelpedVFElement') == -1 &&
			elem.className.indexOf('IHHelpedSFElement') == -1
			) {
			
			
			// Need a check in here to deal with cases where, for field labels,
			// standard SF help is present: 
			// If element is a span with an ID ending "_help", this is the case.
			// Ignore these cases (get user to click the containing table cell)
			
			if (elem.tagName.toUpperCase() == 'SPAN') {
				if (elem.id.indexOf('_help') != -1) {
					return;
				}
			}
			
			
			// Ditto menu button inner spans
			if (elem.tagName.toUpperCase() == 'SPAN') {
				if (elem.className.indexOf('menuButtonLabel') != -1) {
					return;
				}
			}
			

			elem.className += (elem.className == '' ? 'ToBeHelped' : ' ToBeHelped');
			
			return;
		}
		
		// ToBeHelped -> Unmarked
		if (elem.className.indexOf('ToBeHelped') != -1) {	
			elem.className = elem.className.replace('ToBeHelped', '');
			elem.className = stringTrim(elem.className);
			return;
		}
		

		// Helped -> ToBeUnhelped
		if ((elem.className.indexOf('IHHelpedSFElement') != -1 || 
				elem.className.indexOf('IHHelpedVFElement') != -1 ||
				elem.innerHTML.indexOf('IHHelpedSFElement') != -1 ||
				elem.innerHTML.indexOf('IHHelpedVFElement') != -1) &&
			(elem.className.indexOf('ToBeUnhelped') == -1 && 
			elem.innerHTML.indexOf('ToBeUnhelped') == -1)			
			) {
			
			// NB: deal with any element that is helped but marked as having errors...
			elem.className = elem.className.replace('IHHelpedSFElementError', 'IHHSFEEXX');
			elem.innerHTML = elem.innerHTML.replace('IHHelpedSFElementError', 'IHHSFEEXX');			
			elem.className = elem.className.replace('IHHelpedSFElement', '');
			elem.innerHTML = elem.innerHTML.replace('IHHelpedSFElement', '');
			elem.className = elem.className.replace('IHHSFEEXX', 'IHHelpedSFElementError');
			elem.innerHTML = elem.innerHTML.replace('IHHSFEEXX', 'IHHelpedSFElementError');
			
			elem.className += (elem.className == '' ? 'ToBeUnhelped' : ' ToBeUnhelped');						
			elem.className = stringTrim(elem.className);
			
			return;
		}	

		
		// ToBeUnhelped -> Helped
		if (elem.className.indexOf('ToBeUnhelped') != -1) {
			elem.className = elem.className.replace('ToBeUnhelped', '');

			if ($IAIHj(elem).hasClass('Helpable') || elem.className.indexOf('HelpableL_') != -1 || elem.className.indexOf('HelpableR_') != -1 || elem.className.indexOf('HelpableToDiv_') != -1) {
				elem.className += (elem.className == '' ? 'IHHelpedVFElement' : ' IHHelpedVFElement');
			} else {
				elem.className += (elem.className == '' ? 'IHHelpedSFElement' : ' IHHelpedSFElement');				
			}
			
			elem.className = stringTrim(elem.className);
			return;
		}
	}


// --------------------------------------------------------------------------------------------------
// Iterates through page elements and places any highlighted for help topics into a return array
// See GetHelpableElements for legal values of elemType 
// --------------------------------------------------------------------------------------------------
	function getElemsToBeHelped (elemType) {
	
		var f;	// for looping
		var e;	// for looping
		var t;	// tables
		var c;	// collections of HTML elements of various kinds being checked for help-ability
		var elems = new Array();

		
		c = null;
		c = GetHelpableElements(elemType);
		
		for (e = 0; e < c.length; e ++) {
				
			if (c[e].className.indexOf(' ToBeHelped') != -1 
				|| c[e].className.indexOf(' ToBeUnhelped') != -1
				|| c[e].innerHTML.indexOf(' ToBeHelped') != -1 
				|| c[e].innerHTML.indexOf(' ToBeUnhelped') != -1) {
				
				// If so, add this element to an array to return 
				elems[elems.length]= c[e];
			}					
		}
		
		
		return elems;
	}

	
// --------------------------------------------------------------------------------------------------
// Returns the URL to a confirm actions screen prompting user whether or not to save changes made 
// in "Guide Enable" mode: if no changes were made, returns URL to screen with params={blank} 
// --------------------------------------------------------------------------------------------------
	function getConfirmGEActionsURL() {
		
		var retVal = '';
		
		try {
			// There should be some step info in the cache: if it's empty, just bail...
			if (cacheSize() > 0) {
				
				// Cache will contain all steps (new, existing, edited, deleted):
				// We only need confirm those which have changed - which should have non-blank "dirty" flags
				var Params = '';				
				var Steps = cacheGetAll().split(settingsD2);
				var Step;
				var i;
				
				for(i = 0; i < Steps.length; i++) {
					Step = Steps[i].split(settingsD1);
					
					// If step is added, edited or deleted, send it to the confirms page
					if (Step[6] == 'A' || Step[6] == 'E' || Step[6] == 'D') {
						
						// IE seems to have trouble with char code 5 passed as such in this circumstance
						// so let's translate it directly here to "%05"
						Params += encodeURIComponent(Steps[i]) + '%05'; //settingsD2;
						
					}
				}
								
				retVal = IHSettings[SFURL] + '/apex/iahelp__IHConfirmActions?Opts=2&HPL=' + IHSettings[SFObjId] + '&Params=' + Params;							
				
			}
			
		} catch (e) {
			alert(Internationalise('[QAMMessageGenericError]') + ' (Get Confirm GE Actions URL) - ' + e);			
		}
		
		return retVal;
	}
	

// --------------------------------------------------------------------------------------------------
// Returns the URL to a confirm actions screen prompting user whether or not to save changes made 
// to help in "configure" mode: if no changes were made, returns an empty string 
// --------------------------------------------------------------------------------------------------
	function getConfirmHEActionsURL() {
		
		var elems; 
		var allElems = new Array();
		var EID;
		var retVal = '';
		var i;

		// Use unprintable characters for delimiters
		var D1 = String.fromCharCode(7);			// "inner" - within a single element
		var D2 = String.fromCharCode(5);			// "outer" - between elements
		var nullMarker = '|';						// A value to present when no elems are present
		
		var eC = '';				// Elements to be created
		var eD = '';				// Their element types
		var tC = '';				// Elements to be deleted
		var tD = '';				// Their element types
							
		
		try {
			// Get each type of element to be helped: load each in turn into an array of arrays
			// with element 1 = the element and element 0 = the type of helped element to create (if reqd)

			elems = getElemsToBeHelped('Signatures');
			for (i=0; i < elems.length; i++) {
				allElems[allElems.length] = new Array('Signature Element', elems[i]);
			}
			
			elems = getElemsToBeHelped('HTPortalLinks');
			for (i=0; i < elems.length; i++) {
				allElems[allElems.length] = new Array('Help and Training Link', elems[i]);
			}
	
			elems = getElemsToBeHelped('Pages');
			for (i=0; i < elems.length; i++) {
				allElems[allElems.length] = new Array('Page Help Link', elems[i]);
			}
	
			elems = getElemsToBeHelped('RecordTitles');
			for (i=0; i < elems.length; i++) {
				allElems[allElems.length] = new Array('Record Title', elems[i]);
			}

			elems = getElemsToBeHelped('DetailAreas');
			for (i=0; i < elems.length; i++) {
				allElems[allElems.length] = new Array('Detail Section Label', elems[i]);
			}

			elems = getElemsToBeHelped('CustomAreas');
			for (i=0; i < elems.length; i++) {
				allElems[allElems.length] = new Array('Custom Section Label', elems[i]);
			}
						
			elems = getElemsToBeHelped('RListTitles');
			for (i=0; i < elems.length; i++) {
				allElems[allElems.length] = new Array('Related List Label', elems[i]);
			}
	
			elems = getElemsToBeHelped('RListObjects');
			for (i=0; i < elems.length; i++) {
				allElems[allElems.length] = new Array('Related List Help Link', elems[i]);
			}
	
			elems = getElemsToBeHelped('RListColumns');
			for (i=0; i < elems.length; i++) {
				allElems[allElems.length] = new Array('Related List Column Label', elems[i]);
			}
			
			elems = getElemsToBeHelped('Fields');
			for (i=0; i < elems.length; i++) {
				allElems[allElems.length] = new Array('Field', elems[i]);
			}
			
			elems = getElemsToBeHelped('SFButtons');
			for (i=0; i < elems.length; i++) {
				allElems[allElems.length] = new Array('Button', elems[i]);
			}
					
			elems = getElemsToBeHelped('SFMenuButtons');
			for (i=0; i < elems.length; i++) {
				allElems[allElems.length] = new Array('Button', elems[i]);
			}
			
			elems = getElemsToBeHelped('CustomLinks');
			for (i=0; i < elems.length; i++) {
				allElems[allElems.length] = new Array('Custom Link', elems[i]);
			}
			
			elems = getElemsToBeHelped('VFPages');
			for (i=0; i < elems.length; i++) {
				allElems[allElems.length] = new Array('Visualforce Element', elems[i]);
			}
			
			// Only continue if some elements are marked for a change of state...
			if (allElems.length > 0) {
								
				// Prepare base address of confirms page:
				// NB: we don't want any query or anchor string with this as it's not part of the fundamental
				// layout and, in any case, can cause issues...
				
				retVal = document.location.href;
				retVal = retVal.replace(document.location.hash, '');
				if (retVal.substring(retVal.length - 1) == '#') {retVal = retVal.substring(0, retVal.length - 1);}
				retVal = IHSettings[SFURL] + '/apex/iahelp__IHConfirmActions?Opts=1&Params=' + retVal.replace(document.location.search, '');			

				
				// Loop for each element marked for change... 
				for (i=0; i < allElems.length; i++) {
					
					// Set the ID to use when locating / creating the element:
					// Source varies by page furniture type
					if (allElems[i][0] == 'Page Help Link') {
						EID = IHSettings[SFObjId];
					} else {
						EID = getElementIdString(allElems[i][1]);
					}
										
					// Build parameter list to send to confirms page
					// Add any new topics
					if (allElems[i][1].className.indexOf(' ToBeHelped') != -1 || 
						allElems[i][1].innerHTML.indexOf(' ToBeHelped') != -1
						) {		
						
						eC += encodeURIComponent(getElementIdString(allElems[i][1])) + D1;
						tC += allElems[i][0] + D1;
					}
					
					// Remove any specified topics
					if (allElems[i][1].className.indexOf(' ToBeUnhelped') != -1 || 
						allElems[i][1].innerHTML.indexOf(' ToBeUnhelped') != -1
						) {		
						
						eD += encodeURIComponent(getElementIdString(allElems[i][1])) + D1;
						tD += allElems[i][0] + D1;						
					}
	
					
					// Regardless of whether changes were saved at user request, take any added highlights off...
					allElems[i][1].className = allElems[i][1].className.replace(' ToBeHelped', '');
					allElems[i][1].className = allElems[i][1].className.replace(' ToBeUnhelped', '');
					allElems[i][1].innerHTML = allElems[i][1].innerHTML.replace(' ToBeHelped', '');
					allElems[i][1].innerHTML = allElems[i][1].innerHTML.replace(' ToBeUnhelped', '');
					
					
				}	// End elems loop
				
				
				// Cut final delimiters -  and ensure we always pass SOMETHING for each parameter
				if (eC.length > 0) {eC = eC.substring(0, eC.length - 1);}
				if (eC.length == 0) {eC = nullMarker;}
				
				if (tC.length > 0) {tC = tC.substring(0, tC.length - 1);} 
				if (tC.length == 0) {tC = nullMarker;}
				
				if (eD.length > 0) {eD = eD.substring(0, eD.length - 1);} 
				if (eD.length == 0) {eD = nullMarker;}
				
				if (tD.length > 0) {tD = tD.substring(0, tD.length - 1);} 
				if (tD.length == 0) {tD = nullMarker;}

				// Add parameters to base URL				
				retVal += encodeURI(D2 + eC + D2 + tC + D2 + eD + D2 + tD);
			}
			
		} catch (e) {
			alert(Internationalise('[QAMMessageGenericError]') + ' (Get Confirm HE Actions URL) - ' + e);			
		}
		
		return retVal; 
	}
		
	
// --------------------------------------------------------------------------------------------------
// Checks whether an individual page element (as opposed to an element type) has associated help
// See also:
// 		- GetOrgSettings (which checks which type of element should be enabled)
//
// Expects:
//		- elem: a page element
//
// Returns:
//		- 0 = no help available for this element
//		- 1 = help is available and functional for this element
//		- 2 = helped element exists but associated topic has issues
// --------------------------------------------------------------------------------------------------
	function HelpAvailableFor (elem) {
	
		var elemId;
		var i;
		var retVal = 0;
		var CDs;
		var d1 = String.fromCharCode(7);
		var d2 = String.fromCharCode(5);
		var cd1;
		var cd2;
				
		try {
			// Make a call to get helped elements on this page - but only do this once:
			// I.e., if we've been called before on this page, don't repeat the call...
			if (IHSettings[HEs] == null) {
				GetOrgSettings();	
			}
			
			if (HElems == null) {		
				// NB: see ControllerSettings.getHelpedElements for delimiter
				IHSettings[HEs] = IHSettings[HEs].toUpperCase();			
				HElems = IHSettings[HEs].split(d1);
				
				for (i=0; i<HElems.length; i++) {
					HElems[i] = stringTrim(HElems[i]);					
				}			
			}
			
			
			// Get the identifier applicable to page element we were passed
			elemId = getElementIdString(elem).toUpperCase();			
			elemId = stringTrim(elemId);

	
			// If for any reason we get a blank ID, we cannot match this 
			// (no helped elements will, per the above split, always give a 
			// single, empty string array element in these cases)
			
			if (elemId != '') {
				// Loop around helped elements to see if our ID is there
				for (i=0; i<HElems.length; i++) {	
					if (HElems[i] == elemId) {	
						
						// We've found the element - but we should check that its callout
						// details (and thus its topic) were located correctly
						CDs = IHSettings[CDetails].split(d1);
						
						// If we cannot find details or they're null, there's an issue
						if (CDs.length < i+1) {
							retVal = 2;
						} else {
							CDs = CDs[i];
							CDs = CDs.split(d2);							
							cd1 = CDs[1] + '';
							cd2 = CDs[2] + '';
							
							if(cd1.toUpperCase() == 'NULL' || cd2.toUpperCase() == 'NULL') {
								retVal = 2;
							} else {
								
								// Otherwise, we can return success
								retVal = 1;							
							}
						}
						
						break;
					}
				}
			}
			
		} catch (e) {
			//alert ('Error checking availability of Improved Help: ' + e);
		}
			
		return retVal;
	}


// --------------------------------------------------------------------------------------------------
// Returns details of callout to use with a given helped element in a delimited string format
// --------------------------------------------------------------------------------------------------
	function getCalloutDetails(HEIdent) {
		
		var s = '';
		var safeDetails = 'IAHELP__CALLOUTSUMMARYONLY' + String.fromCharCode(7) + '55' + String.fromCharCode(7) + '' + String.fromCharCode(7) + '' + String.fromCharCode(7) + '0';

		var i;
		var test;
    	var CalloutDetails;

		try {
			test = HEIdent + String.fromCharCode(5);	    	
			CalloutDetails = IHSettings[CDetails];
	    	
	    	// NB: see ControllerSettings.GetCalloutDetails for delimiter ({d1}, {d2}) info
	    	// That gives a string in the form:
	    	// Element Identifier {d2} Template {d2} Height {d2} Active HE Id {d2} Topic custom CSS {d2} DFF Count [{d1} etc]		
			// From this, look up the required element
			
			var CDs = CalloutDetails.split(String.fromCharCode(7));
			
			for (i=0; i<CDs.length; i++) {
				
				if (CDs[i].length > test.length) {
					if (CDs[i].substring(0, test.length) == test) {
						var parms = CDs[i].split(String.fromCharCode(5));
						s = parms[1] + String.fromCharCode(7) + parms[2] + String.fromCharCode(7) + parms[3] + String.fromCharCode(7) + parms[4] + String.fromCharCode(7) + parms[5];
					}
				}
			}
			
			
			// If for any reason we can't find information for the requested identifier, adopt a default set of details:
			if (s == '') {
				s = safeDetails;			
			}
			
			
		} catch (e) {
			// On error, default to a "safe" value
			s = safeDetails;			
		}
				
		return s;
	}


// --------------------------------------------------------------------------------------------------
// Tests the current SF page and returns a value indicating whether it's an editing or viewing type
// --------------------------------------------------------------------------------------------------
	function CheckPageType () {
		
		//Look for the editPage form that should be present if data is being manipulated...	
		var x = document.getElementById('editPage');
		
		if (x + '' == 'null') {
			return 0;	// Reading
		} else {
			return 1;	// Editing
		}
	}


// --------------------------------------------------------------------------------------------------
// Returns collections of page elements that are amenable to hooking with Improved Help
// Specify the type of helpable element sought (elemType).
// These are:
//
//		- 'Fields' 			= Form field labels 
//		- 'Pages'			= Page level help links
//		- 'DetailAreas'		= Details / editing form area label
//		- 'RListObjects'	= Related list object help
//		- 'RListTitles'		= Related list titles
//		- 'RListColumns'	= Related list column headings
//		- 'VFPages'			= (Suitably marked) Visual Force page elements 
//		- 'CustomAreas'		= Custom section header labels
//		- ''				= Pass an empty string to get all element types
// --------------------------------------------------------------------------------------------------
	function GetHelpableElements (elemType) {
	
		var f;		// for looping
		var e;		// for looping
		var t;		// tables
		var c;		// collections of HTML elements of various kinds being checked for help-ability
		var getAll;  
		var retVal = new Array();	// Array of helpable elements of the selected type to return
		
		
		if (elemType == '') {
			getAll = true;
		} else {
			getAll = false;
		}
	
	
		try {
			// FORM FIELD LABELS
			if ((elemType.toUpperCase() == 'FIELDS' || getAll == true) && IHSettings[doF] == 'true') {
				
				// Find all tables
				t = document.getElementsByTagName("table");
				
				// For each table, check whether it's a "detailList" type			
				for (f = 0; f < t.length; f++) {				
					if (t[f].className == 'detailList') {

						// If if is, for each cell, check whether it's a "labelCol"
						c = t[f].getElementsByTagName("td");
						
						for (e = 0; e < c.length; e ++) {
							
							if (c[e].className.indexOf('labelCol') != -1) {

								// Return this - but ignore blank labelled (i.e., empty) columns...
								if (getElementIdString(c[e]) != '') {
									retVal[retVal.length] = c[e];									
								}
							}
						}
						
						// Apex tags in stand-alone use (on VF pages) may render field labels
						// into TH tags - not TDs, so add these to the helpable field type elements
						c = t[f].getElementsByTagName("th");
						
						for (e = 0; e < c.length; e ++) {
							
							if (c[e].className.indexOf('labelCol') != -1) {

								// Return this - but ignore blank labelled (i.e., empty) columns...
								if (getElementIdString(c[e]) != '') {
									retVal[retVal.length] = c[e];									
								}
							}
						}
					}
				}
				
				
				// v1.32.2+ : add support for fields within dependent pick list dialogues...
				c = $IAIHj('#InlineEditDialogContent * .labelCol');
				
				for(f = 0; f < c.length; f++){
					retVal[retVal.length] = c[f];
				}					

/*				
// v1.38+: also add LUX field labels to avoid need for signature
c = $IAIHj('span.slds-form-element__label');

for(f = 0; f < c.length; f++){
	retVal[retVal.length] = c[f];
}					
*/														
			}


			// "SIGNATURE" ITEMS
			if (elemType.toUpperCase() == 'SIGNATURES' || getAll == true) {
				
				var sDefs = IHSettings[SigDetails];
				var knownSigs;
				var sig;

				if (sDefs != '') {
					knownSigs = sDefs.split(settingsD1);

					for (e = 0; e < knownSigs.length; e++) {
							
						// Use the list of known signatures to get all elements of each type in turn
						sig = knownSigs[e].split(settingsD2);
						c = $IAIHj(sig[0]);
						
						for(f = 0; f < c.length; f++){
							retVal[retVal.length] = c[f];
						}					
					}
				}				
			}
			
			
			// HELP AND TRAINING PORTAL LINK
			if ((elemType.toUpperCase() == 'HTPORTALLINKS' || getAll == true) && IHSettings[doP] == 'true') {
				c = $IAIHj('a.brandZeronaryFgr');
				for(e = 0; e < c.length; e++){
					retVal[retVal.length] = c[e];
				}
			}

			// PAGE-LEVEL HELP 
			if ((elemType.toUpperCase() == 'PAGES' || getAll == true) && IHSettings[doP] == 'true') {
				c = $IAIHj('span.helpLink');
				for(e = 0; e < c.length; e++){
					retVal[retVal.length] = c[e];
				}
			}

			// RECORD TITLES
			if ((elemType.toUpperCase() == 'RECORDTITLES' || getAll == true) && IHSettings[doE] == 'true') {
				c = $IAIHj('h1.pageType');
				for(e = 0; e < c.length; e++){
					retVal[retVal.length] = c[e];
				}
			}			

			// DETAILS AREA SECTION HEADINGS
			if ((elemType.toUpperCase() == 'DETAILAREAS' || getAll == true) && IHSettings[doD] == 'true') {
				c = $IAIHj('h2.mainTitle');
				for(e = 0; e < c.length; e++){
					retVal[retVal.length] = c[e];
				}
			}			
			
			// CUSTOM SECTION HEADER LABELS
			if ((elemType.toUpperCase() == 'CUSTOMAREAS' || getAll == true) && IHSettings[doC] == 'true') {
				c = $IAIHj('div.pbSubheader > h3');
				for(e = 0; e < c.length; e++){
					retVal[retVal.length] = c[e];
				}
			}			
			
			// RELATED LIST SECTION TITLES
			if ((elemType.toUpperCase() == 'RLISTTITLES' || getAll == true) && IHSettings[doR] == 'true') {
				c = $IAIHj('td.pbTitle > h3');
				for(e = 0; e < c.length; e++){
					retVal[retVal.length] = c[e];
				}
			}
			
			// RELATED LIST OBJECT-LEVEL HELP
			if ((elemType.toUpperCase() == 'RLISTOBJECTS' || getAll == true) && IHSettings[doO] == 'true') {
				c = $IAIHj('span.help');
				for(e = 0; e < c.length; e++){
					retVal[retVal.length] = c[e];
				}
			}

			// RELATED LIST COLUMN HEADINGS
			if ((elemType.toUpperCase() == 'RLISTCOLUMNS' || getAll == true) && IHSettings[doT] == 'true') {
				c = $IAIHj('th.zen-deemphasize');
				for(e = 0; e < c.length; e++){
					retVal[retVal.length] = c[e];
				}
			}
			
			// STANDARD AND CUSTOM SF STANDARD BUTTONS
			if ((elemType.toUpperCase() == 'SFBUTTONS' || getAll == true) && IHSettings[doB] == 'true') {
				c = $IAIHj('input.btn');
				for(e = 0; e < c.length; e++){
					retVal[retVal.length] = c[e];
				}
			}			
			
			// SF MENU BUTTONS
			if ((elemType.toUpperCase() == 'SFMENUBUTTONS' || getAll == true) && IHSettings[doB] == 'true') {
				c = $IAIHj('td#topButtonRow div.menuButtonButton, td#bottomButtonRow div.menuButtonButton, [id^="topButtonRow"] div.menuButtonButton, [id^="bottomButtonRow"] div.menuButtonButton');
				for(e = 0; e < c.length; e++){
					retVal[retVal.length] = c[e];
				}
			}					
			
			// CUSTOM LINKS
			if ((elemType.toUpperCase() == 'CUSTOMLINKS' || getAll == true) && IHSettings[doL] == 'true') {
				c = $IAIHj('table.customLinks a');
				for(e = 0; e < c.length; e++){
					retVal[retVal.length] = c[e];
				}
			}			
			
			// HELP ENABLE VISUAL FORCE PAGE ELEMENTS:
			// POTENTIALLY HELPABLE THINGS ARE DIVs CLASSED AS "Helpable":
			// IF AN AUTHOR ADDS HELP FOR AN INSTANCE OF THIS, WE MARK IT AS "IHHelpedElement" IN VIEW MODE.
			// NB: THERE IS NO CONCEPT OF WHAT'S WHAT - FIELD LABELS VS SECTION HEADINGS ETC

			if (elemType.toUpperCase() == 'VFPAGES' || getAll == true) {
				
				// 1.21: improving VF helpabled selector as the original code (below) 
				// returns only elements whose class STARTS with certain tags OR has class Helpable.
				// We want has class Helpable OR has class starting with Helpable in ANY part of class(es) string...
				//c = $IAIHj('.Helpable, [class^=HelpableL_], [class^=HelpableR_], [class^=HelpableToDiv_]');

				$IAIHj.expr[':'].hasIAVFClass = function(obj){
					return (/\bHelpable/).test(obj.className);
				};
				
				c = $IAIHj(':hasIAVFClass');
				
				for(e = 0; e < c.length; e++){
					retVal[retVal.length] = c[e];
				}
			}


		} catch (Ex) {
			//alert('GetHelpableElements - ERROR: ' + Ex);
		}
		
		return retVal;
	}


// --------------------------------------------------------------------------------------------------
// Show visual highlighting around helped element when in VIP / guided mode. Return info about this
// --------------------------------------------------------------------------------------------------
	function showPrompt(elem){
		
		// Note whether we're in LUX style
		var LUXGuideMode = IHSettings[BrandUXOption];
		
		// NB: setting can be one of several that indicate LUX flavour guides are to be used		
		if (LUXGuideMode > '1') {LUXGuideMode = true;} else {LUXGuideMode = false;}
		
        // Establish Helped Element position & size:
		var HDR = 0;
		var ElementPos = $IAIHj(elem).offset();
        var ElementH = $IAIHj(elem).outerHeight();
        var ElementW = $IAIHj(elem).outerWidth();
        
        
        // Calculate Focus coordinates & size, accommodating border & spacing 
        var FocusY = ElementPos.top -3 + HDR;
        var FocusX = ElementPos.left +10; 
        var FocusH = ElementH + 4;
        var FocusW = ElementW + 4;
        
        var promptPos;				// Above or below element
        var promptTop = FocusY;		// Prompt top / Y coordinate


        // Show / hide prompt body text & media as required before further size-based positioning calculations
        // NB: available in LUX mode only
        if (LUXGuideMode == true) {
        	// Body area as a whole is shown / hidden depending on there being at least one body element to show
        	if ((IHVIPImage != '' && IHVIPImage + '' != 'null') || (IHVIPVideo != '' && IHVIPVideo + '' != 'null') || (IHVIPBody != '' && IHVIPBody != 'NEW')) {
            	$IAIHj('#PromptBody').removeClass('slds-hide');        		
        	} else {
            	$IAIHj('#PromptBody').addClass('slds-hide');        		
        	}
        	
            // NB: in order to offer some flexibility, if summary is set to "new" it will be ignored (as we can't set
        	// summary to a blank value)
        	document.getElementById('PromptBodyText').innerHTML = IHVIPBody;
            if (IHVIPBody != '' && IHVIPBody.toUpperCase() != 'NEW') {
            	$IAIHj('#PromptBodyText').removeClass('slds-hide');
            } else {
            	$IAIHj('#PromptBodyText').addClass('slds-hide');
            }

            if (IHVIPImage != '' && IHVIPImage + '' != 'null') {
            	document.getElementById('PromptImage').src = IHVIPImage;
            	$IAIHj('#PromptImage').removeClass('slds-hide');
            } else {
            	$IAIHj('#PromptImage').addClass('slds-hide');
            }
        
            if (IHVIPVideo != '' && IHVIPVideo + '' != 'null') {
            	document.getElementById('PromptVideo').innerHTML = '<iframe id="PromptVideoIframe" style="width: 100%;" frameborder="0" src="' + IHVIPVideo + '" />';
            	$IAIHj('#PromptVideo').removeClass('slds-hide');
            } else {
            	$IAIHj('#PromptVideo').addClass('slds-hide');
            }
        
        }
        
        
        // Position prompt: style varies automatically based on element position
        if (FocusY < $IAIHj('#IHPrompt').height() + 20) {        	
        	// Prompt below helped element:
	    	promptPos = 'Below';
	    	promptTop = FocusY + FocusH + 10;

	    	$IAIHj('#IHPrompt').removeClass('PromptTop').addClass('PromptBottom');
	    	$IAIHj('#PromptPopover').removeClass('slds-nubbin_bottom-left').addClass('slds-nubbin_top-left');
	    	$IAIHj('#IHPrompt').css('left', FocusX).css('top', promptTop);        	
        	
	    	
        } else {
	        // Prompt above helped element:
        	promptPos = 'Above';
        	promptTop = FocusY - $IAIHj('#IHPrompt').height() - 10;
        	
	    	$IAIHj('#IHPrompt').removeClass('PromptBottom').addClass('PromptTop');
	    	$IAIHj('#PromptPopover').removeClass('slds-nubbin_top-left').addClass('slds-nubbin_bottom-left');
	    	$IAIHj('#IHPrompt').css('left', FocusX).css('top', promptTop);        	
        }
        
        
        // Show only the "next" or "step list toggle" icons, appropriate to guide type
        if (IHVIPRLType == 1) {
        	// If linear, hide step list
        	$IAIHj('#IHStepListIcon').hide();
        	
        	// Also, set prompt footer text (applies to LUX-types only)
			$IAIHj('#IHFooterText').text(Internationalise('[QAMAdviceLabelGuideStepCounter1]') + ' ' + currentLocalStep + ' ' + Internationalise('[QAMAdviceLabelGuideStepCounter2]')+ ' ' + totalLocalSteps);
        	
        } else {
        	// If non-linear, hide next icon
        	$IAIHj('#IHNextStepIcon').hide();        	
        }

                    	
        // Remove all previous focus cues
        $IAIHj('*').removeClass('IHHighlight');
        
        // Add focus to required element
        $IAIHj(elem).addClass('IHHighlight');
        
        
        // Render prompt element if prompt text has been provided
        if (IHVIPPrompt != '') {
        	document.getElementById('PromptMessage').innerHTML = IHVIPPrompt;
	        $IAIHj('#IHPrompt').delay(500).show();
        }
        
		return promptTop + '^' + promptPos;
	}


// --------------------------------------------------------------------------------------------------
// Function to show a selected step in a non-linear Guide:
// 		- stepInfo is a delimited set of step data for a given guide step, ultimately from ControllerIHQAMSettings.getGuideInfo
//		- Delim is the delimiter used to concatenate these
// --------------------------------------------------------------------------------------------------
	function showStep(stepInfo, Delim) {
		try {
			var VIP = stepInfo.split(Delim);
			var elemId;
			
			if (VIP[0] != '') {
				VIP[0] = encodeURI(VIP[0]);
				elemId = 'GSM' + VIP[0].split(' ').join('_');

				cueVIP(VIP[0], VIP[1], VIP[2], encodeURI(VIP[3]), VIP[4], elemId, VIP[5], VIP[6], VIP[7]);
			}
			
		} catch (e) {
			alert('(Show Step) - ' + e);			
		}
	}
	
// --------------------------------------------------------------------------------------------------
// Function to show the next step in a linear Guide
// --------------------------------------------------------------------------------------------------
	function showNextStep() {
		try {
			
			// Get the parameters for the required step by looking in the step menu:
			// See QAM code for how step menu is built.
			// Each step has visible details (for non-linear use in a step menu) plus
			// hidden details of each VIP parameter in index numbered divs...
			
			var VIPId = document.getElementById('GSMVIPId' + currentLocalStep).innerHTML;
			var ElemType = document.getElementById('GSMElemType' + currentLocalStep).innerHTML;
			var HTID = document.getElementById('GSMHTID' + currentLocalStep).innerHTML;
			var VPrompt = document.getElementById('GSMVPrompt' + currentLocalStep).innerHTML;
			var ShowCallout = document.getElementById('GSMShowCallout' + currentLocalStep).innerHTML;
			var StepDivId = document.getElementById('GSMStepDivId' + currentLocalStep).innerHTML;
			var VBodyText = document.getElementById('GSMVBodyText' + currentLocalStep).innerHTML;
			var VImage = document.getElementById('GSMVImage' + currentLocalStep).innerHTML;
			var VVideo = document.getElementById('GSMVVideo' + currentLocalStep).innerHTML;
			
			
			// Hide any active step callout
			$IAIHj('#tfrm').hide();
	        
	        // Use same call to show VIP that non-linear menu would use
			cueVIP(VIPId, ElemType, HTID, VPrompt, ShowCallout, StepDivId, VBodyText, VImage, VVideo);
			
			// Increment the current linear step number
			currentLocalStep += 1;
						
        	// Set prompt footer text (applies to LUX-types only)
			$IAIHj('#IHFooterText').text(Internationalise('[QAMAdviceLabelGuideStepCounter1]') + ' ' + currentLocalStep + ' ' + Internationalise('[QAMAdviceLabelGuideStepCounter2]')+ ' ' + totalLocalSteps);
			
		} catch (e){
			//alert('showNextStep ERROR at step ' + currentLocalStep + ': ' + e);

			// Hide active step and prompt
	        $IAIHj('#IHPrompt').hide();
	        $IAIHj('#tfrm').hide();

			// Gone beyond step count...
	        // Offer to close step window - but only where applicable: this means where there is a 
	        // related guide window. If this guide was "cued" using CueGuide (as in non-sidebar / button driven / console
	        // type scenarios) step window is user's UI so should never be closed!
	        if (window.opener) {
	        	
	        	// Message for buttons needs to be slightly different	        	
				var ElemType = document.getElementById('GSMElemType' + (currentLocalStep - 1)).innerHTML;
				
	        	if (ElemType == 'Button') {
	        		alert(Internationalise('[QAMMessageGuideStepsCompletedGuidance]'));
	        		
	        	} else {
	        		if(confirm(Internationalise('[QAMMessageGuideStepsCompletedOfferClose]'))) {
				        window.close();
					} else {
						alert(Internationalise('[QAMMessageGuideStepsCompletedManualClose]'));
					}	        	}
	        	
	        } else {
	        	alert(Internationalise('[QAMMessageGuideStepsCompleted]'));
	        }
	        

		}
		
		return;
	}
	
// --------------------------------------------------------------------------------------------------
// Function to open StepList when StepList icon in Guide / VIP Prompt clicked
// --------------------------------------------------------------------------------------------------
    function showStepList(elem) {
    
        // Determine Prompt position & size
        var PromptPos = $IAIHj(elem).offset();
        var PromptH = $IAIHj(elem).outerHeight();
        var PromptW = $IAIHj(elem).outerWidth();	        
    
        // Calculate StepList coordinates (for now, always on right of Focus)
        var StepListX = PromptPos.left - 20;
        var StepListY = PromptPos.top + 10;
       
        
        // Get the contents of the step list
        var Lst = document.getElementById('QAMGuideStepInfo').innerHTML;
        
        
        if (Lst == '') {
            // If there is no step list advice, tell the user this
        	alert(Internationalise('[QAMMessageGuideNoStepInfo]'));

        } else {
        	
        	// If we found a Step list, we only want to load it ONCE:
        	if (Lst != 'MOVED') {
                document.getElementById('IHStepList').innerHTML = Lst;
        		document.getElementById('QAMGuideStepInfo').innerHTML = 'MOVED';
        	}
        	
	        // Otherwise, position StepList & hide any active callout
	        $IAIHj('#IHStepList').css('left', StepListX).css('top', StepListY);
	        $IAIHj('#tfrm').hide('slow');
	        
	        // Show / hide step list on a toggle
	        if ($IAIHj('#IHStepList').is(':visible')) {
		        $IAIHj('#IHStepList').hide('slow'); 
	        } else {
		        $IAIHj('#IHStepList').show('slow'); 
	        }
        	
        }
        
        return
    } 

    
// --------------------------------------------------------------------------------------------------
// Hide guide mode step list
// --------------------------------------------------------------------------------------------------
    function hideStepList() {
        $IAIHj('#IHStepList').hide('slow');    	
    	return;
    }
    

// --------------------------------------------------------------------------------------------------
// Hide guide mode linear prompt
// --------------------------------------------------------------------------------------------------
	function hideLinearPrompt() {
		hideStepList();
	    $IAIHj('#IHPrompt').hide('slow');    	
		return;
	}
    
    
// --------------------------------------------------------------------------------------------------
// Mark a helpable element for inclusion in a Guide
// --------------------------------------------------------------------------------------------------   
    function LogGuideStep(evt) {
    	    	
		if(!evt) evt = window.event;
		var elem = evt.target||evt.srcElement;	    			    		    	
		var id = getElementIdString(elem);
		var typ;

		
		// Work out which kind of helped element has been clicked
		typ = getElementType(elem);

		
    	// Mark with a class the elements being added to the Guide
		if (elem.className.indexOf('ToBeGuided') == -1) {
			elem.className += (elem.className == '' ? 'ToBeGuided' : ' ToBeGuided');
			elem.className = stringTrim(elem.className);				
		}
		
    	// When adding a step, show a tool window popup allowing configuration		
		showHelper(elem, id, typ);
		
		// Note which element has the tool window open
		activeGEnableElement = elem;
		
    	return;
    }    
    
    
// --------------------------------------------------------------------------------------------------
// Delete a step logged for addition to a guide:
// NB: this should only be called by the tool window itself!
// --------------------------------------------------------------------------------------------------
    function RemoveGuideStep() {

    	var elemId = document.getElementById('IHGEElemId').value;
    	var sDir = document.getElementById('IHGEDirty');

    	// If a step is new ("A"dded) we can remove it altogether from the cache
    	// so it never reaches the confirms screen. If, however, it was an existing
    	// step (dirty marker = "E"dited or blank/unaltered) we need to send it
    	// to the confirms screen marked for deletion...
    	
    	if (sDir.value == 'A') {
	    	// Hide tool dialogue
	    	hideHelper();
	
	    	// Remove the step's entry from the cache
	    	cacheDelete(elemId);
	    	
    	} else {
    		// Mark for deletion
    		setHelperDirty('D');
    		
    		// Hide tool dialogue
	    	hideHelper();
    	}
    	
    	
    	
    	// Having removed an element, we need to (sort by step number and) renumber
    	//cacheSortAndRenumber(3);
    	
    	// Remove guide enable styling from the affected element: this should be
    	// the one that is currently registered as having the tool window open
    	activeGEnableElement.className = activeGEnableElement.className.replace('ToBeGuided', '');
		elem.className = stringTrim(elem.className);				
    	
		return;
    }
    
// --------------------------------------------------------------------------------------------------
// Show a tools/popup dialogue to allow Guide Step-related data entry
// --------------------------------------------------------------------------------------------------
    function showHelper(elem, id, typ) {
    	
        // Establish Helped Element position & size:
		// NB: take SF page header into account...
		var HDR = $IAIHj('.bPageHeader').outerHeight();		
        var ElementPos = $IAIHj(elem).position();
        var ElementH = $IAIHj(elem).outerHeight();
        var ElementW = $IAIHj(elem).outerWidth();
        var cElem;
        var selOrder;
        var opts;
        var i;
        var RLEId = '';
        var IdMap;
		var temp;
        
        
		if(HDR + '' == 'undefined') {HDR = 0;} 
		
		
		try {
			// Hide any existing helper
	    	hideHelper();

	        // Position the guide enable mode helper 
	    	$IAIHj('#IHGEHelper').css('left', ElementPos.left).css('top', ElementPos.top + 30 + HDR).css('position', 'absolute');
	
	    	// Retrieve contents of the dialogue from cache & populate:
	    	// To do this, we need to look up the key used to store elements in the cache
	    	// in the map of helped element identifiers (which is what we have from the clicking)
	    	// to Guide Step (RLE) Ids. Mapping is in the form:
	    	//
	    	// Element Identifier [D1] RLEId
	    	// (see HookGEMode)

	    	for (i = 0; i < GSIdsMap.length; i++) {
	    		
	    		IdMap = GSIdsMap[i].split(settingsD1);
	    		
	    		if (IdMap[0] == id) {
	    			RLEId = IdMap[1];
	    			break;
	    		}
	    	}

	    	//alert('showHelper: about to cacheGet for RLEId=' + RLEId);

	    	cElem = cacheGet(RLEId);
	    	
	    	// Cache may contain more than 1 matching element: 
	    	//if so, we need to differentiate by element type
	    	if (cElem.length > 1) {
	    		
	    		for (i = 0; i < cElem.length; i++) {
	    			temp = cElem[i].split(settingsD1);
	    			if (temp[5] == typ) {
	    				cElem = cElem[i];
	    				break
	    			}
	    		}
	    	} else {
	    		cElem = cElem[0];
	    		
	    		// If only 1 element was in the cache, check it is of the right element type
	    		if (cElem + '' != 'undefined') {
	    			temp = cElem.split(settingsD1);
	    			if (temp[5] != typ) {
	    				cElem = null;
	    			}	    			    			
	    		} else {
	    			cElem = null;
	    		}
	    	}
	    	
	    	    	
	    	if (cElem == null) {
	    		// If there's nothing in the cache, set up some default values, including the 
	    		// element type passed in as part of the call to this function
	    		
				// Elements are:
				// 0=RLEID, 1=name, 2=summary, 3=step order, 4=?, 5=elem type, 6=dirty status (here, "A"dded)
				
				// Mark RLE Id as being "new" so upsert code (see WServices) can spot new items
				cElem = new Array('*' + id, id, '', cacheSize(), id, typ, 'A');
				
				// These will be saved to the cache below - but we also need to 
				// add a record to the Elem Id to RLE Id mapping array
				GSIdsMap.push(id + settingsD1 + id);
	    		
	    	} else {
	    		cElem = cElem.split(settingsD1);
	    	}
	    	
	    	// Set step name and summary
	    	document.getElementById('IHGEStepName').value = cElem[1];
	    	document.getElementById('IHGEStepSummary').value = cElem[2];
	    	
	    	
	    	// Create select options as required depending on the number of steps in play
	    	selOrder = document.getElementById('IHGEStepOrder');
	    		    	
	    	for (i = 0; i < cacheSize() + 1; i++) {
	    		opts += '<option value="' + i + '"';
	    		if (i == cacheSize()) {
	    			opts += ' selected';
	    		}	    		
	    		opts += '>' + i + '</option>';
	    	}
	    	
	    	selOrder.innerHTML = opts;
	    	selOrder.value = cElem[3];

	    	
	    	// Store the identifier of the element we're working on...
	    	document.getElementById('IHGEElemId').value = id;
	    	
	    	// ... as well as the RL entry ID, if known...
	    	document.getElementById('IHGERLEId').value = cElem[0];
	    	
	    	// ... and the element type...
	    	document.getElementById('IHGEElemType').value = cElem[5];	    	
	    	
	    	// ... and the dirty flag:
	    	// Retrieve this from the values returned from cache - but we must consider what 
	    	// to do with deletes: if cache has "D" marked, this in effect means an existing 
	    	// element was to be deleted (as any element "A"dded then subsequently deleted
	    	// will have been removed altogether from cache). For existing elements, we're
	    	// effectively EDITING them (if they were deleted - then we add them back) so
	    	// use the "E"dit marker in these cases
	    	
	    	if (cElem[6] == 'D') {
		    	document.getElementById('IHGEDirty').value = 'E';
	    	} else if (cElem[6] + '' == 'undefined') {
		    	document.getElementById('IHGEDirty').value = '';	    		
	    	} else {
		    	document.getElementById('IHGEDirty').value = cElem[6];	    	
	    	}
	    	
	    	
	    	// Show the populated dialogue
	        $IAIHj('#IHGEHelper').show();
	        
	    	// Save contents of the dialogue in the cache
	    	if (saveHelper() != true) {
	    		alert(Internationalise('[QAMMessageGenericError]') + ' (Saving)');
	    	}
	    	
		} catch (e) {
			alert(Internationalise('[QAMMessageGenericError]') + ' (Show Helper) - ' + e);
		}

    	
    	return;
    }

    
// --------------------------------------------------------------------------------------------------
// Hide any visible Guide Step-enabling tools dialogue
// --------------------------------------------------------------------------------------------------
    function hideHelper() {
    	
    	// Save contents of the dialogue in the cache
    	if (saveHelper() != true) {
    		alert(Internationalise('[QAMMessageGenericError]') + ' (Hide Helper)');
    		return;
    	}
    	    	
    	// Hide the dialogue
    	$IAIHj('#IHGEHelper').hide();
    	
    	// Clear its contents
    	document.getElementById('IHGEStepName').value = '';
    	document.getElementById('IHGEStepSummary').value = '';
    	document.getElementById('IHGEStepOrder').value = '';    	
    	document.getElementById('IHGEElemId').value = '';
    	document.getElementById('IHGERLEId').value = '';
    	document.getElementById('IHGEElemType').value = '';
    	    	
    	return;
    }
    

// --------------------------------------------------------------------------------------------------
// Mark the current helper dialogue as containing edited or deletable data:
// Pass the marker you wish to apply ("A"dded, "E"dited, "D"eleted item)
// --------------------------------------------------------------------------------------------------
    function setHelperDirty(val) {
    	var sDir = document.getElementById('IHGEDirty');
    	
    	// If an item is marked as "Added", we needn't update this to "Edited" as a user edits
    	if (sDir.value == 'A' && val == 'E') {return;}
    	
    	sDir.value = val;
    }
    
// --------------------------------------------------------------------------------------------------
// Save the current values on the Guide Step-enabling tools dialogue
// --------------------------------------------------------------------------------------------------
     function saveHelper() {

     	var id;
    	var v;
    	var nullMarker = 'NEW';					// Value to use for new record fields
    	
    	
    	var sNam = document.getElementById('IHGEStepName').value;
    	var sSmr = document.getElementById('IHGEStepSummary').value;
    	var sOrd = document.getElementById('IHGEStepOrder').value;
    	var sRLE = document.getElementById('IHGERLEId').value;
    	var sEID = document.getElementById('IHGEElemId').value;
    	var sTyp = document.getElementById('IHGEElemType').value;
    	var sDir = document.getElementById('IHGEDirty').value;
    	
    	if (sNam == '') {sNam = nullMarker;}
    	if (sSmr == '') {sSmr = nullMarker;}
    	if (sOrd == '') {sOrd = '0';}
    	if (sRLE == '') {sRLE = nullMarker;}
    	if (sEID == '') {sEID = nullMarker;}    	
    	if (sTyp == '') {sEID = nullMarker;}    	
    	if (sDir == '') {} // No need to act here: empty implies unedited    	
    	
    	try {
    		
    		// Cache web-escapes the values it's given. 
    		// GetConfirmGEActionsURL uses these values as "param" part of URL query to confirms page.
    		// ControllerConfirmActions.getQueryParms web un-escapes this.
    		// HOWEVER: there are issues with raw percent characters, so replace these
    		// in the fields where they might occur...
    		
	    	v =  sNam.split('%').join(settingsPct) + settingsD1;
	    	v += sSmr.split('%').join(settingsPct) + settingsD1;
	    	v += sOrd + settingsD1;
	    	v += sEID.split('%').join(settingsPct) + settingsD1;
	    	v += sTyp + settingsD1;
	    	v += sDir;
	    	id = sRLE.split('%').join(settingsPct);
	    	
	    	// Do not save if the element id is per null marker: this
	    	// should only happen when a new step / element is first clicked.
	    	// This can be ignored because as the helper is shown for the 1st time, 
	    	// it should set Element Id to the identifier of the clicked element
	    	// (so it WON'T be the null marker)

	    	if (id != nullMarker) {cachePut(id, v);}
	    	return true;

    	} catch (e) {
			alert(Internationalise('[QAMMessageGenericError]') + ' (Save Helper) - ' + e);
    		return false;
    	}
    	
     }
     
     
// --------------------------------------------------------------------------------------------------
// When Guide enabling, mark those elements that are already in the selected Guide
// --------------------------------------------------------------------------------------------------
     function HookGEMode() {
    	 
    	 var Recs;		// Collection of "callout details" settings
    	 var Rec;		// A single "row" in this collection
    	 var i;			// For looping
    	 var j;			// For looping
    	 var c;			// A collection of helpable screen elements
    	 var GEIds; 	// Identifiers of screen elements featured in selected guide
    	 var Nams;		// Step names for the same
    	 var Srys;		// Step Summaries for the same
    	 var Ords;		// Step orders for the same
    	 var Typs;		// Element types for the elements in GEIds
    	 var RLEIds;	// Ids of Reading List Entry records representing the steps
    	 var Dirts;		// Dirty flags for each record
    	 var elemId;	// Identifier of a screen element
    	 var v;			// Cache value to store about a guided element
    	 var U;			// URL of guide popup to show on exit
    	 
    	 
    	 try {
 			// As we're not hooking using HookHelp, we need to add the tip
 			// frame (and thus tools helper dialogue) here
 			MakeTipFrame('dfrm');
 			
 			// The callout details settings element should have been populated with 
 			// the guide elements featuring on this page (see ControllerSettings.getHelpedElementRecords
 			// which spots the guide enable cookie and populates the helped elements setting accordingly)
 			// So: split this value out and loop to hook elements
 			
 			// Setting format (see ControllerSettings.getCalloutDetails)
 			//Identifier{D2}Element Type{D2}Step Name{D2}Step Summary{D2}Order{D2}RLEId{D2}{D1}
 			
 			// In a new guide, there won't be any settings as there are no existing steps: 			
 			if(IHSettings[CDetails] == '') {
 				
	 			// We should spot this here and, as we can only add "manual" steps, add preceding setup steps:
 				// NB: these do not need helped elements (so have no element type)
 				var strNew = '';
 				
 				// - Welcome step
 				strNew += 'IHAddedWelcome' + settingsD2;
				strNew += 'Non Element-bound step' + settingsD2;
				strNew += Internationalise('[QAMValueWelcomeStepName]') + settingsD2;
				strNew += Internationalise('[QAMValueWelcomeStepSummary]') + settingsD2;
 				strNew += '0' + settingsD2;
 				strNew += '*IHAddedWelcome' + settingsD2; 
 				strNew += 'A' + settingsD1;
 				 				
	 			// - Record selection step
 				strNew += 'IHAddedSelect' + settingsD2;
				strNew += 'Non Element-bound step' + settingsD2;
				strNew += Internationalise('[QAMValueSelectRecordStepName]') + settingsD2;
				strNew += Internationalise('[QAMValueSelectRecordStepSummary]') + settingsD2;
 				strNew += '1' + settingsD2;
 				strNew += '*IHAddedSelect' + settingsD2;
 				strNew += 'A' + settingsD1;
 				 				
 				IHSettings[CDetails] = strNew;
 			}
 			
 			Recs     = IHSettings[CDetails].split(settingsD1);
 			GEIds    = IHSettings[CDetails].split(settingsD1);
 			Typs     = IHSettings[CDetails].split(settingsD1);
 			Nams     = IHSettings[CDetails].split(settingsD1);
 			Srys     = IHSettings[CDetails].split(settingsD1);
 			Ords     = IHSettings[CDetails].split(settingsD1);
 			RLEIds   = IHSettings[CDetails].split(settingsD1);
 			Dirts    = IHSettings[CDetails].split(settingsD1);
 			GSIdsMap = IHSettings[CDetails].split(settingsD1);
 			
 			for (i=0; i<Recs.length; i++) {
 				Rec = Recs[i].split(settingsD2); 				
 				GEIds[i]  = Rec[0];
	 			Typs[i]   = Rec[1];
	 			Nams[i]   = Rec[2];
	 			Srys[i]   = Rec[3];
	 			Ords[i]   = Rec[4];
	 			RLEIds[i] = Rec[5];
	 			Dirts[i]  = Rec[6];
 			}
 			
 			// Now we need to add styling to these elements
			c = null;
			c = GetHelpableElements('');


			// Loop through each control...
			for (i = 0; i < c.length; i++) {
				elemId = getElementIdString(c[i]);
				
				// For each, loop through guided elements to see if any match
				for (j = 0; j < GEIds.length; j++) {
					
					// Create a cache record of the current guide step settings:
					// NB: do this for ALL steps, regardless of whether we can
					// match them on this screen...
					
					if (RLEIds[j] + '' != 'undefined') {
				    	v =  Nams[j] + settingsD1;
				    	v += Srys[j] + settingsD1;
				    	v += Ords[j] + settingsD1;					
				    	v += GEIds[j]+ settingsD1;
				    	v += Typs[j] + settingsD1;
				    	v += Dirts[j];	
				    	
				    	// NOTE: we store elements in the cache using reading list entry id!
				    	// Remember that not all guide steps will feature a helped element (e.g., local steps)
				    	// so they won't have element identifiers. Also, elements may be used more than
				    	// once in a guide. For the cache, we need a unique, non-blank key - so only
				    	// the reading list entry id can provide this...
				    	cachePut(RLEIds[j].split('%').join(settingsPct), v.split('%').join(settingsPct));
				    	
				    	// HOWEVER: when an on-screen element is clicked, all it can know is its element identifier!
				    	// SO: we need to store a map of element identifiers to RLE Ids (cache entries):
				    	GSIdsMap[j] = GEIds[j] + settingsD1 + RLEIds[j];						
					}
			    	
					
					if (elemId == GEIds[j]) {
						
						// If screen element matches / is one from the guide, style it
						c[i].className += (c[i].className == '' ? 'ToBeGuided' : ' ToBeGuided');
						c[i].className = stringTrim(c[i].className);					
						
						break;
					}
				}
			}
			
			
			// Set a cookie to advise post-GE SF page to open Guide window on correct guide:
			// NB: in guide enable mode, settings cache should have been populated with
			// the ID of the guide in use...
			U = IHSettings[SFURL] + '/apex/iahelp__IHReadingListViewer?Opts=Guide&RLID=' + IHSettings[SettingsCache] + '&IHContext=' + document.location.href;
			IHSetCookie('IHSelectedGuide', U, 1);
 			
 			    		
    	 } catch (e) {
    		 alert(Internationalise('[QAMMessageGenericError]') + ' (Hook GE Mode) - ' + e);
    	 }
    	 
    	 return;

     }
