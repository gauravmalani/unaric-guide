({

	// Obtain list of nudge topics and display one (where required)
	init : function(cmp, event, helper) {	
	
		// Set nudge styling classes based on member data
		var strClass = 'slds-notify slds-theme_alert-texture ';		
		strClass += 'slds-notify_' + cmp.get("v.SelectedStyle") + ' ';
		
		var strPal = cmp.get("v.SelectedPalette");		
		if (strPal == '' || strPal + '' == 'null' || strPal + '' == 'undefined') {
			strPal = 'Info';
		}
		
		strClass += 'slds-theme_' + strPal;		
		cmp.set("v.NudgeClass", 'NudgeArea ' + strClass.toLowerCase());


		// If fixed text has been specified, full initialisation is not required
		if (cmp.get("v.CurrentTName") == '' && cmp.get("v.CurrentTSummary") == '') {
			cmp.set("v.FixedMode", false);
			
		} else {
			// If we are in fixed mode, note this
			cmp.set("v.FixedMode", true);		
		}

		helper.initialise(cmp, event, helper);

    },
	
	
	// Hides the nudge bar (called on close click or automatically as required)
	hideNudge : function(cmp, event, helper) {
		helper.hideNudge(cmp);
	},
	
	
	// Goto the full topic view of the featured item
	navToNudge : function (cmp, event, helper) {
	
		var HTID = cmp.get("v.CurrentHTID");
    	var PortalPage = cmp.get("v.PortalPage");
		var CRoot = cmp.get('v.CommunityRoot');
		
		// If we're in fixed mode, all we need do is close
		if (cmp.get("v.FixedMode") == true) {
			helper.hideNudge(cmp);
			
		} else {
			// Otherwise, show nudge topic if callout option requires this			
			if (cmp.get("v.CalloutOption") == 'Topic Selected Event plus Topic view') {
				
				// If root is 'null', this can be ignored in most cases
				if (CRoot + '' == 'null') {CRoot = '';}
				
				if (CRoot != '') {CRoot = '/' + CRoot;}
		        window.open(CRoot + '/' + HTID);
			}
			
			// Always issue a topic selected message
            var appEvent = $A.get("e.c:selectTopic");
            appEvent.setParams({"RecordId" : HTID});
            appEvent.setParams({"SourceComponent" : cmp.get('v.ComponentId')});
            appEvent.fire();
			
		}
	},
	
	
})