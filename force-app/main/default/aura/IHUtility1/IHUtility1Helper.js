({

	// Set sub-component column widths in response to design parameter
	setCols : function (cmp) {
	
		// NB: deal with parameter values as may be passed in LUX Out scenarios: 
		// In these, we will not be able to pass '%' as part of a parameter value, as 
		// this will not be allowed (even if escaped) in a web / URL scenario:
		// Instead, column split can be passed WITHOUT '%' in these cases...
		
		// Split does not apply in single column mode:
		if (cmp.get("v.FormFactor") == 'Single Column') {
    		cmp.set("v.Col1Cols", '12');
    		cmp.set("v.Col2Cols", '12');

		} else {
	    	switch (cmp.get("v.ColumnRatio")) {
	    		case '33' :
	    		case '33%' :
	    			cmp.set("v.Col1Cols", "4");
	    			cmp.set("v.Col2Cols", "8");
	    			break;
	
	    		case '40' :
	    		case '40%' :
	    			cmp.set("v.Col1Cols", "5");
	    			cmp.set("v.Col2Cols", "7");
	    			break;
	    			
	    		case '50' :
	    		case '50%' :
	    			cmp.set("v.Col1Cols", "6");
	    			cmp.set("v.Col2Cols", "6");
	    			break;	    			
	
				default :
	    			cmp.set("v.Col1Cols", "6");
	    			cmp.set("v.Col2Cols", "6");
	    			break;
			}
		}
		
			
    },

    
})