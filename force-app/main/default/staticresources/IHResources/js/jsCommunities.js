/////////////////////////////////////////////////////////////////////////////////////////////////////
// UTILITIES REQUIRED FOR VF PAGES THAT ARE TO FEATURE IN SF COMMUNITIES
//
// jQuery is required, so clients must include references to the packaged libraries.
//
// Martin Little for Improved Apps
// July 2015
// Copyright (c.) Improved Apps Limited 2015. All Rights Reserved.
/////////////////////////////////////////////////////////////////////////////////////////////////////

"use strict";

(function(IHCommunities, $, undefined) {

	
	IHCommunities.IAIHCPrefix;
	var IAIHCommunityInitLoops = 0;
	
// --------------------------------------------------------------------------------------------------
// Amend CSS defined image paths for communities, where relevant
//
// NOTE: clients of this script must set the value of IAIHCPrefix 
// after script inclusion, e.g:
//
// IAIHCPrefix = "{!$Site.Prefix}";
// IAIHCPrefix = IHSettings[CPrefix];
//
// This function should then be called from an appropriate point on the client page.
// Specify the number of times to attempt this initialisation (numReps).
// --------------------------------------------------------------------------------------------------
	
	IHCommunities.IAIHInitialiseForCommunities = function (numReps) {
	    
    	console.log('IHCommunities.IAIHInitialiseForCommunities - entry');

		// Note that number of times initialisation is run
    	IAIHCommunityInitLoops += 1;

		if ($IAIHj + '' == 'undefined') {
			console.log('IHCommunities.IAIHInitialiseForCommunities - $IAIHj undefined - creating...');			
			$IAIHj = jQuery.noConflict(true);
		}
    		    
	    if (IHCommunities.IAIHCPrefix == null) {IHCommunities.IAIHCPrefix = '';}
	    if (IHCommunities.IAIHCPrefix != '') {

	    	console.log('IHCommunities.IAIHInitialiseForCommunities - community prefix is "' + IHCommunities.IAIHCPrefix + '"');
	    	
	    	var bg;
		    var dvs = $IAIHj("[class*='IHHelped'],[class*='IHIcon'],[class*='IHBranded'],[class='IHClickHelper']");
	    	
	    	// Process general items (icons, helped elements etc)
	    	$IAIHj.each(dvs, function(idx, val) {
	    		
	    		try {
		            bg = $IAIHj(dvs[idx]).css('background');
		            if (bg.indexOf('/' + IHCommunities.IAIHCPrefix + '/resource/') == -1 && bg.indexOf('/resource/') != -1) {
			            bg = bg.replace('/resource/', '/' + IHCommunities.IAIHCPrefix + '/resource/');
			            $IAIHj(dvs[idx]).css('background', bg);	            	
		            }	    			
	    		} catch (e) {}
	    		
	    		
	    		try {	    			
		            bg = $IAIHj(dvs[idx]).css('background-image');
		            if (bg.indexOf('/' + IHCommunities.IAIHCPrefix + '/resource/') == -1 && bg.indexOf('/resource/') != -1) {
			            bg = bg.replace('/resource/', '/' + IHCommunities.IAIHCPrefix + '/resource/');
			            $IAIHj(dvs[idx]).css('background-image', bg);	            	
		            }	    			
	    		} catch (e) {}
	            
	            
		    	try {
			    	bg = $IAIHj(dvs[idx]).attr('src');
			    	if (bg.indexOf('/' + IHCommunities.IAIHCPrefix + '/resource/') == -1 && bg.indexOf('/resource/') != -1) {
			            bg = bg.replace('/resource/', '/' + IHCommunities.IAIHCPrefix + '/resource/');
				    	bg = $IAIHj(dvs[idx]).attr('src', bg);	    	
			    	}
		    	} catch (e) {}
	            
	        });
	    		    	
	    }
	    
	    // In an effort to ensure images were present / ready when adjustments occurred, set a timeout to call this 
	    // function again (as many times as caller requests).
	    if (IAIHCommunityInitLoops < numReps) {
	    	window.setTimeout("IHCommunities.IAIHInitialiseForCommunities()", 1000);
	    }
	    
	    return;
    };
    
}(window.IHCommunities = window.IHCommunities || {}, jQuery));
