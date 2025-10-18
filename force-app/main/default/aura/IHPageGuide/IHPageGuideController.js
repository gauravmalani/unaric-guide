({
	
	// Setup component definitions and grid column sizing from design parameters in readiness for use
    Init : function(cmp, event, helper) {
    
    	var act = cmp.get("c.getGlobals");
    	var Rs = [];
    	var Cs = [];
    	var i;
    	var i;    	
    	var RC = cmp.get("v.RowCount");
    	var CC = parseInt(cmp.get("v.ColCount"));
    	
    	
    	// Set up overlay grid data that can be iterated in mark-up based on requested number of rows and columns
    	for (i=0; i<RC; i++) {
    		Rs.push('R' + i);
    	}
    	for (i=0; i<CC; i++) {
    		Cs.push('C' + i);
    	}
    	
    	cmp.set("v.CurrentStep", -1);
    	cmp.set("v.Rows", Rs);
    	cmp.set("v.Cols", Cs);
    	cmp.set("v.ColTwelfths", 12 / CC);


    	// Setup the steps in the guide
    	helper.setupGuide(cmp, helper);   
    	
    	
    	// Obtain global settings (internationalisations, branding etc.)
    	act.setCallback(helper, function (response, cmp) {               
			if (response.getState() === "SUCCESS") {
						
		        try {
					helper.processTools(response, cmp, false);
					console.log('IH Pege Guide - globals processed');
					
		        } catch (e) {
		            console.log('IH Pege Guide - Error processing the following globals return value (' + e + '): ' + response.getReturnValue());
		        }
		
			}	// End if Globals call response successful
    	});
    	$A.enqueueAction(act);	

	},
	
	
	// Setup row height from design paramters and rendered height and toggle overall visibility
	showGuide: function (cmp, event, helper) {
				
		console.log('IH Page Guide - Show Guide - Entry...');
		
		var utilityAPI = cmp.find("UtilityBar");
		var grid = cmp.find("grid");

		helper.toggleGrid(cmp, event, helper);		
		cmp.set("v.GridVisible", ! $A.util.hasClass(grid, 'slds-hide'));


		// If we're in a utility bar, pop it open
		try {
			if(utilityAPI + '' != 'undefined'){
				utilityAPI.openUtility();
			} else {
				utilityAPI = cmp.getSuper().find("UtilityBar");
				if(utilityAPI + '' != 'undefined'){
					utilityAPI.openUtility();
				}
			}
		} catch (e){
			console.log('IH Page Guide - utility bar automation error: ' + e);
		}

		
		if (cmp.get("v.CurrentStep") == -1) {
			helper.setStep(cmp, event, helper);
		}
	},
	
	
	// If in design mode, mark cells that already feature in the guide
	finaliseGrid : function (cmp, event, helper) {
		
		if (cmp.get("v.DesignMode") == true) {
		
			var cells = cmp.find("GridCellLabel");
			var positions = cmp.get("v.Positions");
			var cellId;
			
			positions = positions.split(',');
			cells.forEach(function (c){
				cellId = c.getElement().id;
				
				positions.forEach(function (p){
					if (cellId == p) {
						$A.util.addClass(c, "Guided");
					}
				});
			});
			
		}
	},
	
	
	// Toggle visibility of design grid
	toggleDesign: function (cmp, event, helper) {

		var grid = cmp.find("grid");
		
		// Ensure grid is setup and 'on'
		helper.toggleGrid(cmp, event, helper);
		$A.util.removeClass(grid, 'slds-hide');
		
		// Toggle grid lines visibility
		$A.util.toggleClass(grid, 'DesignMode');
		
		// Toggle design mode itself
		cmp.set("v.DesignMode", ! cmp.get("v.DesignMode"));
		
	},
	
	
	// Switch a grid cell into design mode
	toggleHighlight : function (cmp, event, helper) {
		helper.toggleHighlight(cmp, event);
	},
	
	
	// Navigate to the next step in a page walk through (delegated)
	setStep : function (cmp, event, helper) {
		helper.setStep(cmp, event, helper);	
	},


    // Handle pass-throughs from ourself and others
    handlePassThroughs : function (cmp, event, helper) {
    
        var act = event.getParam("ActionCode");
        var parms = event.getParam("Parameters");
    	var D1 = '^';
        var src = event.getParam("SourceComponent");
		

		// Launch guide in response to external passthrough
		if (src == cmp.get("v.ListensTo")) {
			switch (act) {
				
				case 'CueContextHelp' :
					cmp.showGuide(cmp, event, helper);
					break;
			}
		}

		
		// DRAFT: Guide enable mode support / search for topic to feature at a given step
		if (src == cmp.get("v.ComponentId") + '_SearchList') {
		
			switch (act) {
			
				case 'GEModeSelectStepTopic' :

					// Extract the ID of the selected topic
					parms = parms.split(D1);
					var HTID = parms[0];
					
					// Add this position and this topic to the guide
					//var topics = cmp.get("v.Topics");
					//var positions = cmp.get("v.Positions");
					
					topics += ',' + HTID;
					positions += ',' + cmp.get("v.CurrentDesignCell");
					
					cmp.set("v.Topics", topics);
					cmp.set("v.Positions", positions);
					
					helper.setupGuide(cmp, helper);
				
					break;
			}
		}
		
	},
	
	
	// Close the guide being viewed
	closeGuide : function (cmp, event, helper) {
		
		// Closure will occur if we attempt to move to a step that
		// is beyond the end of the current guide:
		// We set beyond the end, to show this is manual closure
		// (so avoiding 'you've finished the guide' message)
		var CDefs = cmp.get("v.CDefs");
		cmp.set("v.CurrentStep", CDefs.length + 10);
		helper.setStep(cmp, event, helper);
	},
		
})