/////////////////////////////////////////////////////////////////////////////////////////////////////
// FUNCTIONS FOR EDITING HELP TOPICS AND THEIR RELATED ITEMS ETC
//
// NB: Some of these funtions rely on SF APEX wrapper scripts (Connection.js & Apex.js)
//
// Martin Little for Improved Apps
// July 2012
// Copyright (c.) Improved Apps Limited 2012. All Rights Reserved.
/////////////////////////////////////////////////////////////////////////////////////////////////////

"use strict";

(function(IHEditHelp, $, undefined) {
	

// --------------------------------------------------------------------------------------------------
// Show / Hide topic editing tools
// --------------------------------------------------------------------------------------------------
	IHEditHelp.ToggleEditMode = function () {
		
		var E; 
		
		// Show / hide the relevant areas of the screen (editor vs related list panels)
		E = document.getElementById('ToolsEditor');
		ToggleEdit(E);
	
		E = document.getElementById('RelatedHelpTopics');
		ToggleEdit(E);
		
		E = document.getElementById('ReadingLists');
		ToggleEdit(E);
			
		E = document.getElementById('ResourceList');
		ToggleEdit(E);
		
		
		// Enable / disable toolbar tools
		this.ToggleTools();
		
		// 
		IHWebToolTips.StopTips('tfrm');
		
		return;
	}
	
	
// --------------------------------------------------------------------------------------------------
// Enable / disable toolbar items: in edit mode, most icons are irrelevant and should be disabled
// --------------------------------------------------------------------------------------------------
	IHEditHelp.ToggleTools = function () {
		
		var E;
		
		// SF Home:
		// Only toggle this if it's not supposed to be "disabled" - because e.g., we're in the console
		E = document.getElementById('ToolbarIconHome');
		if (E.className.indexOf('Disabled') == -1) {
			ToggleEnabled(E);
		}
	
		// Portal Home:
		// Only toggle this if it's not supposed to be "disabled" - because there's no default help topic
		E = document.getElementById('ToolbarIconHelpHome');
		if (E.className.indexOf('Disabled') == -1) {
			ToggleEnabled(E);
		}
	
		// Bookmarks
		E = document.getElementById('ToolbarIconBookmark');
		ToggleEnabled(E);
	
		// Print
		E = document.getElementById('ToolbarIconPrint');
		ToggleEnabled(E);
	
		// Comment
		E = document.getElementById('ToolbarIconComment');
		ToggleEnabled(E);
		
		// View Helped Elements
		E = document.getElementById('ToolbarIconHelpedElements');
		ToggleEnabled(E);
	
		// SF Tab
		E = document.getElementById('ToolbarIconSFEditing');
		ToggleEnabled(E);
	
		// Clone topic
		E = document.getElementById('ToolbarIconTopicClone');
		ToggleEnabled(E);
	
		// Add topic
		E = document.getElementById('ToolbarIconTopicAdd');
		ToggleEnabled(E);
	
		// Delete topic
		E = document.getElementById('ToolbarIconTopicDelete');
		ToggleEnabled(E);
	
		// Add to RL
		E = document.getElementById('ToolbarIconAddToReadingList');
		ToggleEnabled(E);
	
		// Stats
		E = document.getElementById('ToolbarIconInteractions');
		ToggleEnabled(E);
		
		// History
		E = document.getElementById('ToolbarIconHistory');
		ToggleEnabled(E);
		
		
		return;
	}


// --------------------------------------------------------------------------------------------------
// Give a visual clue that a given item has been clicked
// --------------------------------------------------------------------------------------------------

// Remove standard Salesforce button class
	IHEditHelp.initialiseButtons = function () {
		$IAIHj('.IHIcon24').removeClass('btn');	
		return;
	}

// Add our own clicked / task in progress class
	IHEditHelp.showClicked = function (elem){
		elem.className = elem.className.replace(' IHIdle', ' IHWaiting');
		return;
	}


// --------------------------------------------------------------------------------------------------
// Confirm actions taken after task completion
// --------------------------------------------------------------------------------------------------
	IHEditHelp.confirmComplete = function (elem, msg){
		
		if (elem) {
			elem.className = elem.className.replace(' IHWaiting', ' IHIdle');
		}
		
		// Check for SF errors prior to reporting back status
		var x = passedSFValidation();	
		if (x == true && msg != '') {
			alert(msg);
		}
		
		// Send a message to any opener that we've completed the task in hand	
		try {
			if (self != top) {
				window.parent.postMessage('confirmComplete=' + msg, '*');				
			} else {
				window.opener.postMessage('confirmComplete=' + msg, '*');
			}		
		} catch (e) {
		}
			
		return;
	}
	
	
// --------------------------------------------------------------------------------------------------
// Refresh content (template) area of eg tools page after saving topic edits
// --------------------------------------------------------------------------------------------------
	IHEditHelp.ReNav = function (elem, msg, HelpId) {
	
		var x = document.getElementById('tfrmContent');	
		var y = document.getElementById('HBS');
		var U;
		var root = IHSettings[SFURL];
			
		
		U = root + '/apex/iahelp__IHRedirector?HTID=' + HelpId;
		
		// Re-size template IFrame to topic's height before scrolling
		x.style.height = y.value + 'px';
					
		x.src = U;
		
		// Set to "clean" so we can leave page without unsaved data warning
		this.IHjsEditIsDirty = false;
		
		// Reset visual clues and advise of completion
		this.confirmComplete(elem, msg);
		
		// As there will have been a post back, we need to hook help again on this page (for Orgs that have 
		// defined help for the editor & related lists / our helpable VF elements)
		HookHelp();
		
	
		return;
	}


// --------------------------------------------------------------------------------------------------
// Refresh content (template) area of eg tools page after saving topic edits AND toggle editing off
// --------------------------------------------------------------------------------------------------
	IHEditHelp.ReNavToggle = function (elem, msg, HelpId) {	
	
		this.ReNav(elem, msg, HelpId);
	
		// Check for SF errors prior to reporting back status
		var x = passedSFValidation();	
		if (x == true) {
			this.ToggleEditMode();			
		}
		
		return;
	}


// --------------------------------------------------------------------------------------------------
// For tracking edits and warning of unsaved data
// --------------------------------------------------------------------------------------------------
	IHEditHelp.IHjsEditIsDirty;
	    	
	IHEditHelp.IHjsEditSetDirty = function () {
		this.IHjsEditIsDirty = true; 
	}
	
	IHEditHelp.IHjsEditCheckDirty = function () {		
		if (this.IHjsEditIsDirty == true) {		
			return Internationalise('[QAMMessageDirtyWarning]');
		} else {
			return '';
		}
	}

	
	
// --------------------------------------------------------------------------------------------------
// Check whether any SF validation errors exist on the page
// --------------------------------------------------------------------------------------------------
	function passedSFValidation() {
			
		var retVal = true;
		
		var i;
		var d = document.getElementsByTagName("div");
		
		for (i = 0; i < d.length; i++) {				
			if (d[i].className == 'errorMsg') {
				retVal = false;
				break;
			}
		}
		
		return retVal;
	}


// --------------------------------------------------------------------------------------------------
// Enable / Disable a given page element (icon):
// Element passed in must:
//	 		- Represent an "enabled" element
//			- Have a complementary "disabled" element (id = elem's ID plus "Unavailable") 
// --------------------------------------------------------------------------------------------------
	function ToggleEnabled(elem) {
	
		// This is done by swapping visibility of divs representing enabled and disabled tools...
		var elemD = document.getElementById(elem.id + 'Unavailable')
		ToggleEdit(elem);
		ToggleEdit(elemD);
		
		return;
	}


// --------------------------------------------------------------------------------------------------
// Show / Hide a given page element
// --------------------------------------------------------------------------------------------------
	function ToggleEdit(elem) {
	
		if (elem.className.indexOf('IHHidden') != -1 || elem.className.indexOf(' IHHidden') != -1) {
			elem.className = elem.className.replace(' IHHidden', '');
			elem.className = elem.className.replace('IHHidden', '');
			
		} else {
			elem.className += ' IHHidden';
		}
		
		return;
	}


	
	
}(window.IHEditHelp = window.IHEditHelp || {}));
