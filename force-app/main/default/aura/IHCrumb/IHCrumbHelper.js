({
    
    // Seek the crumb trail(s) applicable to the current record (HelpRecordId)
	initialiseCrumbs : function (cmp, event) {
		
        var act = cmp.get("c.getCrumbs");
        act.setParams({"HelpRecordId" : cmp.get("v.HelpRecordId")});                       
		console.log('initialiseCrumbs--');
        console.log('IHCrumb initialising crumbs for topic "' + cmp.get('v.HelpRecordId') + '"');

        // Add callback to process returned results
        act.setCallback(this, function (response, cmp){
        	
        	// Parse return value into our crumbs collection
	        var state = response.getState();
	        var obj;
	
	        if (state === "SUCCESS") {
	            try {
					obj = JSON.parse(response.getReturnValue());
	            } catch (e) {
	                cmp.set("v.Diags", "IHCrumb - initialiseCrumbs - Error parsing the following JSON return value (" + e + "): " + response.getReturnValue());
	                return;
	            }
	        	
	        	cmp.set("v.CrumbTrails", obj);

        	} else {
                cmp.set("v.Diags", "IHCrumb - initialiseCrumbs - Error");
        	}
        	
        });
        $A.enqueueAction(act);
	},
	
	
})