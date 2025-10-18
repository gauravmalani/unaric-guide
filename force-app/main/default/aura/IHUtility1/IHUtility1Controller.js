({

    // Set certain sub-component data that is derived from, as opposed to directly linked to, incoming design parameters 
    init : function (cmp, event, helper) {
    
    	// Differentiate tree and topic tool contexts - unless default has been requested
    	if (cmp.get("v.ToolContext") == '[DEFAULT]') {
			cmp.set("v.ToolContextTree", cmp.get("v.ToolContext"));
			cmp.set("v.ToolContextTopic", cmp.get("v.ToolContext"));
    	} else {
			cmp.set("v.ToolContextTree", cmp.get("v.ToolContext") + '_Tree');
			cmp.set("v.ToolContextTopic", cmp.get("v.ToolContext") + '_Topic');
    	} 


		// Amends to take account of spaces / lack thereof in design parameters passed via URL
		if (cmp.get("v.FormFactor") == 'SingleColumn') {
			cmp.set("v.FormFactor", 'Single Column');
		}

    
	    // Write changes to the combined component's root node to 
	    // member data that the individual sub-components can use: this acts as a 'one way valve',
	    // so that changes made in sub components (who may use the root for different purposes) do not
	    // cross contaminate
    	cmp.set("v.RootNodeTree", cmp.get("v.RootNode"));
    	cmp.set("v.RootNodeTopic", cmp.get("v.RootNode"));
    	
    	// Also ensure layout column widths are set
    	helper.setCols(cmp);


    	// Hide topic viewer initially if in single column form factor
    	if (cmp.get("v.FormFactor") == 'Single Column') {
    		cmp.set("v.HideTopic", true);
    	}
    	
    	// Make our underlying tree and topic viewer components available via member data
    	cmp.set("v.Tree", cmp.find("UtilTree"));
    	cmp.set("v.Topic", cmp.find("UtilTopic"));

    },
    
    
    // Placeholder: Handle pass-throughs - whilst individual components respond, this one may need to act itself in some cases
    handlePassThroughs : function (cmp, event, helper) {
    	
        var act = event.getParam("ActionCode");
        var parms = event.getParam("Parameters");
        var src = event.getParam("SourceComponent");
        
		// Respond to context change events issued by position detector:
		// Our tree cannot simply listen to PD, as PD issues record selects that
		// tree should NOT handle in some cases (and would if it were listening)
		// SO: we must pass the message on here...

        if (src == cmp.get("v.PDPositioningGroup")) {
        	switch (act) {
        		case 'ContextChange' :
					// Re-raise the pass through, but with a modified source that
					// we can safely ask tree to listen to
					
					var appEvent = $A.get("e.c:evtPassThrough");
					appEvent.setParams({"SourceComponent": cmp.get("v.PDPositioningGroup") + '_ParentUtility'});
					appEvent.setParams({"ActionCode": "ContextChange"});
					appEvent.setParams({"Parameters": parms});
					appEvent.fire();

        			break;
			}
		}
		

		// Switch back to tree having viewed a topic in single column form factor mode		
		if (act == 'BackToTree' && src == cmp.get("v.PDPositioningGroup") + '_Topic' && cmp.get("v.FormFactor") == 'Single Column') {
			cmp.set("v.HideTopic", true);
			cmp.set("v.HideTree", false);
		}
		
    },
    
    
	// Set sub-component column widths in response to design parameter (delegated)
	setCols : function (cmp, event, helper) {
		helper.setCols(cmp);
    },
    
    
	// Respond to the "select" event (if we're listening to the source component)
    selectRecord : function (cmp, event, helper) {
        
        var theRecord = event.getParam("RecordId");
        var cxt = cmp.get('v.ToolContext');
        //var aCode = cmp.get('v.ActionCode');
        var theSource = event.getParam("SourceComponent");
        var listensTo = cmp.get('v.PDListensTo');
        var i;
       

		// If selection is from our own tree view and we're in 'single column' form factor display mode,
		// hide our tree and show topic viewer

		if (theSource == cmp.get("v.PDPositioningGroup") + '_Tree' && cmp.get("v.FormFactor") == 'Single Column') {

			// Avoid swapping to topic when first spinning up in single column mode: we want
			// to start by showing the tree - until user selects a tree node
			var numSelects = cmp.get("v.NumTopicSelects");

			if (numSelects > 0) {
				cmp.set("v.HideTree", true);
				cmp.set("v.HideTopic", false);
			}		

			numSelects += 1;
			cmp.set("v.NumTopicSelects", numSelects);
		}

       
        // More broadly, only respond to events we wish to tie to
        var doResponse = false;
        
        try {
	        if (listensTo != '' && listensTo + '' != 'null') {
	        	// Listens To member data can be specified as a comma separated list
	        	listensTo = listensTo.split(' ').join('');
	            listensTo = listensTo.split(',');
	            
	            for (i=0; i<listensTo.length; i++) {
	                if (theSource == listensTo[i]) {
	                    doResponse = true;
	                    break;
	                }
	            }
	        }

        } catch (e) {
        	// Fail safe
        	doResponse = false;
        }
        
        
        if (doResponse == true) {
        
        	// It we're in the utility bar and settings mandate it, pop utility bar open
        	if (cmp.get("v.PopUtilityBar") == true) {
        	
				// If we're in a utility bar, pop it open
				try {

					var x;
					x = window.setInterval($A.getCallback(function() {

try {					
						var utilityAPI = cmp.find("UtilityBar");
						
						var marker = cmp.find("UtilTreeContainer").getElement();
						var YMarker = marker.getBoundingClientRect().top;
							        	
						if (YMarker == 0) {
							if(utilityAPI + '' != 'undefined'){
								utilityAPI.openUtility();
							}
							window.clearInterval(x);
						}
} catch (e) {}						
						
					}), 1000);

					
				} catch (e){
					console.log(e);				
				}
        	
        	}
        }

	},
    

})