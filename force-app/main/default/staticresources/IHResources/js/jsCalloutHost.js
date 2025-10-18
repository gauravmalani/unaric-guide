/////////////////////////////////////////////////////////////////////////////////////////////////////
// UTILITIES REQUIRED FOR PAGES (SF AND VF) THAT WISH TO HOST CALLOUTS
//
// Martin Little for Improved Apps
// January 2014
// Copyright (c.) Improved Apps Limited 2014. All Rights Reserved.
/////////////////////////////////////////////////////////////////////////////////////////////////////

"use strict";

(function(IHCalloutHost, $, undefined) {

// --------------------------------------------------------------------------------------------------
// Respond to messages from callouts
// --------------------------------------------------------------------------------------------------
	try {
		window.removeEventListener('message', getVIPLink);
	} catch (e) {}
	try {
		top.removeEventListener('message', getVIPLink);
	} catch (e) {}
	
	try {
		window.detachEvent('onmessage', getVIPLink);
	} catch (e) {}
	try {
		top.detachEvent('onmessage', getVIPLink);
	} catch (e) {}
	

	try {
		
		// This filter is needed to avoid multiple responses to the share link request message:
		// Pages such as tools will have multiple copies of IHHook (1x tools, 1x template, 1x certain dialogue pages)
		// each, therefore, with callout host included: this means multiple listeners to the same message.
		// As the caller cannot know which layout its in / "who" should be listening, we'll just have to settle for
		// only the top window dealing with these requests, even if that's not always the correct page...
		
		if (self == top) {
			if(!window.addEventListener) {
				window.attachEvent("onmessage", getVIPLink);					
			} else {
				window.addEventListener("message", getVIPLink, false);				
			}
						
		} else {
			if(!top.addEventListener) {
				top.attachEvent("onmessage", getVIPLink);					
			} else {
				top.addEventListener("message", getVIPLink, false);				
			}		
		}	
	
	} catch (e) {
		//alert('jsCalloutHost: error in setup: ' + e);
	}


// --------------------------------------------------------------------------------------------------
// Produce a message offering the user a "share" (VIP) link in response to messages
// requesting this from callouts etc.
// --------------------------------------------------------------------------------------------------
	function getVIPLink(e) {
		
		var i;
		var s;
		var qParts;
		var Msg;
	
		
		console.log('IHCalloutHost.getVIPLink - entry... ');
		
		try {
			if (e.data.toString().substring(0,12) == 'copyVIPLink=') {
				if (self == top) {
					var U = document.location.href;
					
					// We need to replace any anchor within the address 
					U = U.replace(document.location.hash, '');
					
					// Also need to remove any existing IHVIP details
					U = U.replace(document.location.search, '');
					s = document.location.search;
	
					if (s.length > 0) {
						s = s.substring(1);					
						qParts = s.split('&');
						for (i=0; i < qParts.length; i++) {
							
							// If we find an IHVIP clause, remove it
							if (qParts[i].substring(0,6).toUpperCase() == 'IHVIP=' || qParts[i].substring(0,9).toUpperCase() == 'AWAITVIP=') {
								// Skip this search clause
								
							} else {
								if (i == 0) {
									U += '?' + qParts[i];
								} else {
									U += '&' + qParts[i];
								}
							}
						}
					}
					
					// Now add the required VIP clause
					if (U.indexOf('?') == -1) {
						U += '?' + e.data.toString().substring(12);
					} else {
						U += '&' + e.data.toString().substring(12);
					}
	
					Msg = Internationalise('[QAMMessageVIPLinkCopyInstructions]');				
					window.prompt (Msg, U);						
				}
				
			}
	
		} catch (ex) {
			Msg = Internationalise('[QAMMessageGenericError]' + ' (Get VIP Link): ' + ex);		
			console.log(Msg);
		}
			
		return false;
	}

	
}(window.IHCalloutHost = window.IHCalloutHost || {}));

