/////////////////////////////////////////////////////////////////////////////////////////////////////
// SUPPORT UTILITIES FOR PAGES INTENDED FOR USE IN SF1 (I.E., THE IH1UX)
//
// Martin Little for Improved Apps
// January 2014
// Copyright (c.) Improved Apps Limited 2014. All Rights Reserved.
/////////////////////////////////////////////////////////////////////////////////////////////////////

"use strict";

(function(IHIH1UX, $, undefined) {
	
// --------------------------------------------------------------------------------------------------
// Show / hide listing details
// --------------------------------------------------------------------------------------------------
	IHIH1UX.toggleDetails = function (EC) {
		
		console.log('IHIH1UX.toggleDetails - entry... ');
		
		if (EC == 'Expand') {
			console.log('IHIH1UX.toggleDetails - expanding... ');
			
			$IAIHj(".IH1ListItemFirstLine,.IH1ListItemLine").show();
			$IAIHj(".IH1ListItemLabel").show();
			$IAIHj(".IH1ViewMode").removeClass('IHIconExpandIH1').addClass('IHIconCollapseIH1');
			$IAIHj(".IH1ListItem.Collapsed").removeClass('Collapsed');
		} else {
			console.log('IHIH1UX.toggleDetails - collapsing... ');

			$IAIHj(".IH1ListItemFirstLine,.IH1ListItemLine").hide();
			$IAIHj(".IH1ListItemLabel").hide();
			$IAIHj(".IH1ViewMode").removeClass('IHIconCollapseIH1').addClass('IHIconExpandIH1');
			$IAIHj(".IH1ListItem").addClass('Collapsed');
		}
	  
		// Store user's selected state in a cookie
		IHSetCookie('IH1ViewMode', EC, 5);
	  
		return;
	}
	 
}(window.IHIH1UX = window.IHIH1UX || {}, jQuery));

