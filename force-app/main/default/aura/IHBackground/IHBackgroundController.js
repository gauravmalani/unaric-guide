({

	Init : function(cmp, event, helper) {

		// Set styling options from user selections
		var optS = cmp.get("v.styleSize");
		var optR = cmp.get("v.styleRepeat");
		var optP = cmp.get("v.stylePosition");
		var optW = cmp.get("v.styleWidth");
		
		var classes = '';
		
		switch (optS) {
			case 'Stretch to fill':
				classes += 'SizeFill ';
				break;

			case 'Original size':
				classes += 'SizeOriginal ';
				break;
		}
		
		switch (optR) {
			case 'None':
				classes += 'RepeatNone ';
				break;

			case 'Horizontal':
				classes += 'RepeatHorizontal ';
				break;

			case 'Vertical':
				classes += 'RepeatVertical ';
				break;

			case 'Both':
				classes += 'RepeatBoth ';
				break;
		}

		switch (optP) {
			case 'Fixed':
				classes += 'PositionFixed ';
				break;

			case 'Scrolling':
				classes += 'PositionScrolling ';
				break;
		}
		
		cmp.set("v.styleClasses", classes);
		
		// Size image container as a whole to column width 
		var checkInterval = cmp.get("v.checkInterval");
		
		// Don't attempt resize if sizing option is 100% screen width, or we're told not to bother
		if (optW == 'Containing column') {
			if (checkInterval > 0) {
				window.setInterval(
				    $A.getCallback(function() {	            	
		            	helper.setSize(cmp, helper);
				    }), checkInterval
				);
			}
			
		} else {
			cmp.set("v.Width", '100%');
		}

	},
	
	    
})