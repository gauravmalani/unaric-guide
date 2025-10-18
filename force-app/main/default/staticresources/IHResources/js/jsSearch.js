/////////////////////////////////////////////////////////////////////////////////////////////////////
// UTILITIES TO SUPPORT HELP SEARCHES
//
// Martin Little for Improved Apps
// July 2012
// Copyright (c.) Improved Apps Limited 2012. All Rights Reserved.
/////////////////////////////////////////////////////////////////////////////////////////////////////

"use strict";

(function(IHSearch, $, undefined) {

// --------------------------------------------------------------------------------------------------
// Reports result of an operation (e.g., to add/delete a relative) then re-searches based on last criteria 
// --------------------------------------------------------------------------------------------------
	IHSearch.reportStatusThenSearch = function (msg) {
		alert(msg);
		this.doSearch();
		return;
	}

	
// --------------------------------------------------------------------------------------------------
// For cueing help search page as popup
// --------------------------------------------------------------------------------------------------
	IHSearch.doSearchPopup = function (evt) {

		var T = encodeURI(document.getElementById('txtSearchTerm').value);
		var U = IHSettings[SFURL] + '/apex/iahelp__IHSearchResults?Term=' + T;
		var cT = IHQAMenu.isConsolePage;
		
		
		try {
			// If we're a console page, add parameter to the search screen reflecting this
			// such that results will be sent to a console tab.
			// Also, send search results themselves to a console tab
			if (cT == true) {
				// NB: this is a parameter that SF seems to use for console tabs: 
				// c.f. ControllerSettings.isConsolePage 
				U += '&isdtp=IHAdded';						
				IHQAMenu.openPrimaryTab(U, 'Search Help');
							
			} else {
				IHWebToolTips.DoTips('dfrm', U, '7', 200, 355, evt);
			}
			
		} catch (e) {
			var Msg = Internationalise('[QAMMessageGenericError]');
			alert (Msg + ' - (doSearchPopup) ' + e);
		}
		
		return;
	}
	

// --------------------------------------------------------------------------------------------------
// For cueing help search results to same page
// --------------------------------------------------------------------------------------------------
	IHSearch.doSearch = function () {
		// Get the search term
		var T = encodeURIComponent(document.getElementById('txtSearchTerm').value);
		var S = '';
		var objId = '';

		// Get the search option, where in use
		if (document.getElementById('optsSearch') + '' != 'null'){
			S = document.getElementById('optsSearch');
			S = S.options[S.selectedIndex].value;		
			
			// Where search options are used, we must also keep track of the objId parameter
			// as this is required by some search options
			objId = this.getURLParam('objId');
		}
		
		// Add this to our URL - but make sure we remove any existing term first...
		var U = document.URL;
		if (U.indexOf('&Term=') != -1) {
			U = U.substring(0, U.indexOf('&Term='));
			U += '&Term=' + T;
		}
		
		if (U.indexOf('?Term=') != -1) {
			U = U.substring(0, U.indexOf('?Term='));
			U += '?Term=' + T;
		}
		
		if (U.indexOf('Term=') == -1) {
			if (U.indexOf('?') == -1) {
				U += '?Term=' + T;
			} else {
				U += '&Term=' + T;
			}
		}

		// If search options are in use, amend request accordingly
		if(S != '') {
			U += '&Srch=' + S;
			U += '&objId=' + objId;
		}

		console.log('IHSearch.doSearch - navigating to: ' + U);
		document.location = U;
		
		return;
	}

	
// --------------------------------------------------------------------------------------------------
// Check search term text field and blank its contents if these are the default term
// --------------------------------------------------------------------------------------------------
	IHSearch.checkSearchTerm = function (elem) {
	
		if (elem.value == '[Enter search term]') {
			elem.value = '';
		} 
				
		// Also, select the whole of the text
		elem.select();
				
		return;  
	}


// --------------------------------------------------------------------------------------------------
// Handle enter key behaviour: 
// --------------------------------------------------------------------------------------------------
	IHSearch.checkEnter = function (mode, evt) {
    
    	var key = (evt.which) ? evt.which : evt.keyCode;
    	
    	if (key == 13) {
    		    		
        	// If Enter is pressed, act based on context:
    		
    		// If this is from the IH1 QAM Search widget...
    		if (mode.toUpperCase() == 'IH1QAMSEARCH') {
    			// Cue on page search code
    			cueSearch();
    			return false;
    		}
    		
    		// If this was within some other recognised search widget...
    		if (document.activeElement.id == 'txtSearchTerm') {
    			
    			
    			// Enter key in search intercepted to run a search rather than form post:
    			// Exact mode of showing results depends on parameters passed...
    			if (mode.toUpperCase() == 'POPUP') {
    				
    	    		// If we're in Firefox, looks like we'll have to abandon all Enter key
    	    		// behaviour as we can't seem to return "false" if we do anything
    	    		// first (such as show the search popup)
    				
    				// As the risk of non-return only affects the tools page, where there may
    				// have been edits, we can limit this bail behaviour to this popup case...
    	    		if (navigator.userAgent.indexOf('Firefox') != -1) {
    	    			return false;
    	    		}
    				
        			this.doSearchPopup();
    			} else {
        			this.doSearch();    				
    			}
    			
    			return false;
    			
    			
    		} else {
    			// If Enter pressed outside of search, ignore it
    			return false;
    			
    		}
    		
    	} else {
    		// All other keys pass thru OK
    		return true;
    	}
    	
    }	
	
    
// --------------------------------------------------------------------------------------------------
// Extract URL parameters: 
// --------------------------------------------------------------------------------------------------
	IHSearch.getURLParam = function (name) {
		try {
			var results = new RegExp('[?&]' + name + '=([^&#]*)').exec(window.location.href);

			return results[1] || 0;
		} catch (e) {
			return null;
		}
	}							


}(window.IHSearch = window.IHSearch || {}));

	