/////////////////////////////////////////////////////////////////////////////////////////////////////
// CODE FOR WIRING IMPROVED HELP INTO PAGES (E.G. CONSOLE TABS) WHERE NO SIDEBAR COMPONENT IS PRESENT.
// TO DO THE WIRING, ADD A CUSTOM BUTTON OR LINK TO THE PAGE (THIS IS AN ABSOLUTE MINIMUM) WITH
// CODE TO CREATE A REFERENCE TO THIS SCRIPT, I.E:
/*
	var scr = document.createElement('script');
	scr.setAttribute('src', '[VF Root]/resource/iahelp__IHResources/js/jsConsole.js');
	document.getElementsByTagName('head')[0].appendChild(scr);
*/
// ... where [VF Root] is the Visualforce host address visible when visiting the Tools page
//
// THIS SCRIPT THEN ADDS REFERENCES TO ALL OTHER REQUIRED ITEMS, AS OUR STANDARD QAM WOULD DO:
// THE MAIN ASPECT OF THIS IS THE FINAL ADDITION OF THE IHSettings DIV, WHICH GETS THE RESULTS
// OF THE VF CALLBACK TO OBTAIN SETTINGS AND HOOK HELP.
//
// IN ADDITION, IF DESIRED THIS SCRIPT CAN BE USED TO LAUNCH A GUIDE FROM THE CONSOLE.
// IN THESE CASES, ALL HOOKING NEEDS TO BE CUED, THEN ADDITIONAL GUIDE SETTINGS SOUGHT
// AND PLACED, AS WITH A STANDARD PAGE, INTO A HIDDEN GUIDE STEP INFO DIV.
// TO DO THIS, ADD THE FOLLOWING LINE TO THE ABOVE SCRIPT:
/*
 	window.setTimeout("CueGuide('[Guide Id]')", [n]);
*/
//
// ... where ...
//			[Guide Id] is the SF record ID of the desired Guide (Reading List)
//			[n]	is the number of milliseconds to wait before attempting to launch the guide.
//
// A delay is required in order to allow hooking to take place and all scripts to be added.
//
// Martin Little for Improved Apps
// August 2013
// Copyright (c.) Improved Apps Limited 2013. All Rights Reserved.
/////////////////////////////////////////////////////////////////////////////////////////////////////

"use strict";

var IHjsConResURL;
var IHjsConScript;
var IHjsConLink;
var IHjsConDiv;
var IHjsConDivs;
var IHjsConRoot;			    // VF root - passed when this is known in an org but cannot easily be derived due to MyDomain etc.
var IHjsCommunityDomain;		// Root path of community etc (where alias URL / domain means "standard" SF address may not be present)
var IHjsCommunityPrefix;		// Community prefix - to override any failure by SF API to deliver this
var IHjsWorker;					// Working string


var CustomTips = false;			// Set to true to allow local custom callout handling (see insertion point in jsToggleHelp.DoVFTip).


////////////////////////////////////////////////////////////////////////

IHjsConRoot = '';
IHjsCommunityDomain = '';
IHjsCommunityPrefix = '';

IHjsConDivs = document.getElementsByTagName("div");

for (var i = 0; i < IHjsConDivs.length; i++) {
	if (IHjsConDivs[i].className == 'sidebarModuleBody') {

		// Found a sidebar component
		IHjsWorker = IHjsConDivs[i].textContent;
		if (IHjsWorker + '' == 'undefined') {IHjsWorker = IHjsConDivs[i].innerText;}
		
		if (IHjsWorker.substring(0, 5) == '{http') {
		
			// Found our VF root component: get path & hide component where relevant
			// (don't try to hide parent node if we're part of a community / VF page etc:
			// only hide if we're part of classic sidebar).
			IHjsConRoot = IHjsWorker.substring(1, IHjsWorker.length - 1);
			
			if (IHjsConDivs[i].parentNode) {
				if (IHjsConDivs[i].parentNode.className.indexOf('sidebarModule') != -1) {
					IHjsConDivs[i].parentNode.style.display = 'none';
				}
			}
		
		} else {
			//IHjsConRoot = '';
		}
	}
	IHjsWorker = '';
	
	
	if (IHjsConDivs[i].id == 'IAIHCommunityDomain') {
		IHjsWorker = IHjsConDivs[i].textContent;
		if (IHjsWorker + '' == 'undefined') {IHjsWorker = IHjsConDivs[i].innerText;}		
		IHjsCommunityDomain = '&CommunityDomain=' + IHjsWorker.substring(1, IHjsWorker.length - 1);
	}

	if (IHjsConDivs[i].id == 'IAIHCommunityPrefix') {
		IHjsWorker = IHjsConDivs[i].textContent;
		if (IHjsWorker + '' == 'undefined') {IHjsWorker = IHjsConDivs[i].innerText;}		
		IHjsCommunityPrefix = '&CommunityPrefix=' + IHjsWorker.substring(1, IHjsWorker.length - 1);	
	}

}


////////////////////////////////////////////////////////////////////////


try {

	// Only add these items once:
	// 1.24: look for settings div, not main CSS
	
	if (document.getElementById('IAIHSettings') + '' == 'null') {
		
	// POTENTIAL TO CHECK BY OTHER MEANS, IN CASE SETTINGS DIV NEEDS TO BE CREATED ELSEWHERE...
	//if (document.getElementById('IAIHSettings') + '' == 'null' || document.getElementById('BrandCSS') + '' == 'null') {
		
		
		// Add stylesheets:
		// Don't add customer stylesheet if it's already present:
		//		- In console, it won't be, so we add
		//		- In classic, it will be (it's in QAM markup, but awaiting source setting from ClientSettingsLoader)	
		if (document.getElementById('BrandCSS') + '' == 'null') {
			IHjsConLink = document.createElement('link');
			IHjsConLink.setAttribute('rel', 'stylesheet');
			IHjsConLink.setAttribute('type', 'text/css');
			IHjsConLink.setAttribute('id', 'BrandCSS');
			document.getElementsByTagName('head')[0].appendChild(IHjsConLink);
		}

		IHjsConResURL = IHjsConRoot + '/resource/iahelp__IHResources/css/help_main.css';
		IHjsConLink = document.createElement('link');
		IHjsConLink.setAttribute('rel', 'stylesheet');
		IHjsConLink.setAttribute('type', 'text/css');
		IHjsConLink.setAttribute('id', 'MainCSS');
		IHjsConLink.setAttribute('href', IHjsConResURL);
		document.getElementsByTagName('head')[0].appendChild(IHjsConLink);

		IHjsConResURL = IHjsConRoot + '/resource/iahelp__IHResources/css/LUXApp40.css';
		IHjsConLink = document.createElement('link');
		IHjsConLink.setAttribute('rel', 'stylesheet');
		IHjsConLink.setAttribute('type', 'text/css');
		IHjsConLink.setAttribute('id', 'LUXCSS');
		IHjsConLink.setAttribute('href', IHjsConResURL);
		document.getElementsByTagName('head')[0].appendChild(IHjsConLink);
		
		
		// Add script references
		IHjsConResURL = IHjsConRoot + '/resource/iahelp__IHResources/lib/jquery/3.6.0/jquery-3.6.0.min.js';
		IHjsConScript = document.createElement('script');
		IHjsConScript.setAttribute('src', IHjsConResURL);
		document.getElementsByTagName('head')[0].appendChild(IHjsConScript);
		
		IHjsConResURL = IHjsConRoot + '/resource/iahelp__IHResources/lib/CryptoJSv312AES/aes.js';
		IHjsConScript = document.createElement('script');
		IHjsConScript.setAttribute('src', IHjsConResURL);
		document.getElementsByTagName('head')[0].appendChild(IHjsConScript);		
		
		IHjsConResURL = IHjsConRoot + '/resource/iahelp__IHResources/js/jsSettings.js';
		IHjsConScript = document.createElement('script');
		IHjsConScript.setAttribute('src', IHjsConResURL);
		document.getElementsByTagName('head')[0].appendChild(IHjsConScript);
		
		IHjsConResURL = IHjsConRoot + '/resource/iahelp__IHResources/js/jsToggleHelp.js';
		IHjsConScript = document.createElement('script');
		IHjsConScript.setAttribute('src', IHjsConResURL);
		document.getElementsByTagName('head')[0].appendChild(IHjsConScript);
		
		IHjsConResURL = IHjsConRoot + '/resource/iahelp__IHResources/js/jsQAMenu.js';
		IHjsConScript = document.createElement('script');
		IHjsConScript.setAttribute('src', IHjsConResURL);
		document.getElementsByTagName('head')[0].appendChild(IHjsConScript);
		
		IHjsConResURL = IHjsConRoot + '/resource/iahelp__IHResources/js/jsWebToolTips.js';
		IHjsConScript = document.createElement('script');
		IHjsConScript.setAttribute('src', IHjsConResURL);
		document.getElementsByTagName('head')[0].appendChild(IHjsConScript);
		
		IHjsConResURL = IHjsConRoot + '/resource/iahelp__IHResources/js/jsCalloutHost.js';
		IHjsConScript = document.createElement('script');
		IHjsConScript.setAttribute('src', IHjsConResURL);
		document.getElementsByTagName('head')[0].appendChild(IHjsConScript);

		IHjsConResURL = IHjsConRoot + '/resource/iahelp__IHResources/js/jsCommunities.js';
		IHjsConScript = document.createElement('script');
		IHjsConScript.setAttribute('src', IHjsConResURL);
		document.getElementsByTagName('head')[0].appendChild(IHjsConScript);

		IHjsConResURL = IHjsConRoot + '/resource/iahelp__IHResources/js/jsGuides.js';
		IHjsConScript = document.createElement('script');
		IHjsConScript.setAttribute('src', IHjsConResURL);
		document.getElementsByTagName('head')[0].appendChild(IHjsConScript);

		
		// Add settings DIV if required
		if (document.getElementById('IAIHSettings') + '' == 'null') {
			IHjsConDiv = document.createElement('div');
			IHjsConDiv.setAttribute('style', 'display: none; border: 1px dotted currentColor; width: 100%;');
			
			// Note: cannot internationalise this at this stage...
			IHjsConDiv.innerHTML = '<span class="IHError">Help can be configured by visiting the Help Settings tab of the Improved Help app.</span>';			
			
			IHjsConDiv.setAttribute('id', 'IAIHSettings');			
			document.getElementsByTagName('body')[0].appendChild(IHjsConDiv);
		}
		
		
		// Add a script to this page that will return info retrieved via a VF page
		// into the settings DIV, above...
		window.setTimeout("buildSettings()", 5); 
		
	}
	
	
	
} catch (e) {
	//alert ('Please click again to complete the Improved Help preparation process...');
}


// Standard call to cue help on a console page
function buildSettings() {

	try {		
		// Make sure we have all the scripts we need
		try {
			
			if (IHjsConRoot == '') {
				IHjsConRoot = IHQAMenu.getVFRoot(document.URL);
			}

			// This call only adds a QAM if not already present:
			// NB: we do NOT want this in console scenarios (where VF QAM will be present)
			// NB: isConsolePage defined in jsQAMenu
			if (IHQAMenu.isConsolePage == false) {addQAM();}

			
			// Add script to get settings from VF page call
			IHjsConResURL = IHjsConRoot + "/apex/iahelp__IHQAMSettings?callback=ClientSettingsLoader&Referer=" + getSafeURL(document.URL) + IHjsCommunityDomain + IHjsCommunityPrefix;

			IHjsConScript = document.createElement('script');
			IHjsConScript.setAttribute('src', IHjsConResURL);		
			document.getElementById('IAIHSettings').appendChild(IHjsConScript);

			/*
			// ----------------------------------------------------------------------------
					// OPTION to Get settings via web services call, should this ever be needed:
					// See remarked function: ControllerIHQAMSettings.HelpSettings 
					var Settings = document.getElementById('IAIHSettings').innerHTML;
					
					//Back out marshalling character replacements
					var D0 = '{D0}';
					var D1 = '{D1}';
					var D2 = '{D2}';
					
					var D0R = String.fromCharCode(6);
					var D1R = String.fromCharCode(7);
					var D2R = String.fromCharCode(5);
					
					Settings = Settings.split(D0).join(D0R);
					Settings = Settings.split(D1).join(D1R);
					Settings = Settings.split(D2).join(D2R);
					
					ClientSettingsLoader(Settings);
			// ----------------------------------------------------------------------------
			*/
			
		} catch (e) {
			window.setTimeout("buildSettings()", 500);
		}
		
	} catch (e) {
		//alert ('Sorry: there was an error preparing Improved Help: ' + e);		
	}
	
	return;
}


// Wrapper to CueGuide for pages where help hooks have not already been included (e.g., by separate Show Help type button).
function HookAndCueGuide(GID, RLType) {

	try {
		var x = $IAIHj;
		
		if (x + '' == 'undefined') {
			$IAIHj = jQuery.noConflict();
			window.setTimeout("HookAndCueGuide('" + GID + "', " + RLType + ")", 500);
		
		} else {
			// Inform guide code of community paths discovered above, then call forth the guide
			IHGuides.setCommunityPaths(IHjsConRoot, IHjsCommunityDomain, IHjsCommunityPrefix);			
			IHGuides.CueGuide(GID, RLType);
		}
	
	} catch (e) {
		window.setTimeout("HookAndCueGuide('" + GID + "', " + RLType + ")", 500);
	}

}


// Add the contents of the QAM via code (as opposed to a VF page or sidebar component) where required
function addQAM() {

	try {		
		// Only do this if a QAM has not already been added by other means
		// NOTE: internationalisation and LUX-mode appearence switching handled via jsQAMenu.SetupQAM
		if (document.getElementById('IHQAM') + '' == 'null') {
			
			var s = '<div style="position: fixed;" id="IHQAM"><div id="IAIHQAMBody" class="QAMBody"><div style="display: none;" id="QAMRowHome" class="QAMRow" title="[QAMTipRowHome]" onclick="javascript:IHQAMenu.showHelpHome()"><div class="QAMCellL"><div class="IHIcon16 IHIconHelpHome"></div></div><div class="QAMCellR">[QAMRowHome]</div></div><div class="QAMRow" title="[QAMTipRowSearch]" onclick="javascript:IHQAMenu.showHelp(event)"><div class="QAMCellL"><div class="IHIcon16 IHIconSearchHelp"></div></div><div class="QAMCellR">[QAMRowSearch]</div></div><div class="QAMRow" title="[QAMTipRowBookmarks]" onclick="javascript:IHQAMenu.showBookmarks(event);"><div class="QAMCellL"><div class="IHIcon16 IHIconBookmarkList"></div></div><div class="QAMCellR">[QAMRowBookmarks]</div></div><div style="display: none;" id="QAMRowComment" class="QAMRow" title="[QAMTipRowComment]" onclick="javascript:IHQAMenu.pageComment(event);"><div class="QAMCellL"><div class="IHIcon16 IHIconComment"></div></div><div class="QAMCellR">[QAMRowComment]</div></div>';
			s += '<div style="display: none;" id="QAMRowGuides"><div class="QAMSpacer"></div><div class="QAMRow" title="[QAMTipRowGuides]" onclick="javascript:IHQAMenu.toggleGuideListing(event);"><div class="QAMCellL"> <div class="IHIcon16 IHIconGuide"></div></div><div class="QAMCellR">[QAMRowGuides]</div></div>';
			s += '<div class="" id="QAMGuideListing" style="display: none;">LIST GOES HERE...</div>';
			s += '<div class="QAMRow" id="QAMGuideStepInfo" style="display: none;"></div></div>';
			s += '<div style="display: none;" id="QAMConfigurationTools"><div class="QAMSpacer"></div><div class="QAMSectionTitle">[QAMAdviceLabelMode]</div><div id="QAMRowModeSave" class="QAMRow Active" disabled="" title="[QAMTipRowView]" onclick="javascript:configurePage(\'Saved\', event);"><div class="QAMCellL"> <div class="IHIcon16 IHIconModeView"></div></div><div class="QAMCellR">[QAMRowView]</div></div> <div id="QAMRowModeHelp" class="QAMRow" title="[QAMTipRowHelpEnable]" onclick="javascript:configurePage(\'Configure\', event);"><div class="QAMCellL"> <div class="IHIcon16 IHIconHelpEnable"></div></div><div class="QAMCellR">[QAMRowHelpEnable]</div></div> <div id="QAMRowModeReCon" class="QAMRow" title="[QAMTipRowReconfigure]" onclick="javascript:configurePage(\'Recon\', event);"><div class="QAMCellL"> <div class="IHIcon16 IHIconEdit"></div></div><div class="QAMCellR">[QAMRowReconfigure]</div></div>';
			s += '<div id="QAMRowModeGEnable" class="QAMRow Deprecated" title="[QAMTipRowGuideEnable]" onclick="javascript:configurePage(\'GEnableEntry\', event);"><div class="QAMCellL"> <div class="IHIcon16 IHIconGuideEnable"></div></div><div class="QAMCellR">[QAMRowGuideEnable]</div></div> <div id="QAMRowModeStat" class="QAMRow" title="[QAMTipRowAnalyse]" onclick="javascript:configurePage(\'Stats\', event);"><div class="QAMCellL"> <div class="IHIcon16 IHIconModeAnalyse"></div></div><div class="QAMCellR">[QAMRowAnalyse]</div></div> </div><div id="QAMRowModeConf" class="QAMRow" style="display: none;" title="[QAMTipRowSettings]" onclick="javascript:IHQAMenu.showSettings();"><div class="QAMSpacer"></div><div class="QAMCellL"><div class="IHIcon16 IHIconSettings"></div></div><div class="QAMCellR">[QAMRowSettings]</div></div>  </div>  <a id="QAMHandleLink" title="[QAMTipHandle]" onclick="javascript:IHQAMenu.moveQAM();" href="javascript:void(0)"><div class="QAMHandleShadow"><div id="IAIHQAMHandle" class="QAMHandleClosed"><div class="QAMHandleIcon IHIcon20"></div></div></div> </a></div><div id="IAIHOversubscribed" style="display: none;"></div>';

			var dv = document.createElement('div');
			dv.innerHTML = s;		
			document.getElementsByTagName('body')[0].appendChild(dv);			
		}		
		
	}  catch (e) {
		//alert('addQAM error: ' + e);
	}

	return;
}

