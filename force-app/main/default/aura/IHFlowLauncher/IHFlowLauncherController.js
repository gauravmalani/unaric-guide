({
	
	// Use incoming flow name and optional flow parameters to launch the desired flow or prompt user for info
	init : function (cmp, event, helper) {
	
		try {
			// Set operational mode
			if (cmp.get("v.theFlowName") == '[CONTEXT]') {
			
				// If we need to prompt for a flow, obtain available options
				cmp.set("v.OpMode", 'Prompt');
				
				var act = cmp.get("c.getContextFlows");				
		        act.setParams({ 
		        	"IHContext" : cmp.get("v.recordId"), 
		        });                       
                
		        // Add callback to process returned results
		        act.setCallback(helper, function (response, cmp){
		        	
		        	var obj;
		        	var LIs = [];
		        	var opt;
		        	var opts = [];
		        	var i;
		        	
		        	if (response.getState() === "SUCCESS") {
		        	
			            try {
							obj = JSON.parse(response.getReturnValue());
			            } catch (e) {
			            	helper.handleError("v.Diags", "Error parsing the following return value (" + e + "): " + response.getReturnValue());
			                return false;
			            }
			
			            // We may have been returned zero or more tools and zero or more listing records.
			            // If there are >1 total items, we have a collection to iterate. 
			            // If there are 0 items, we've nothing to do.
			            // If there is exactly 1 item (could be a tool or a listing record), we need
			            // to load this into an array in order for the loop that follows to work...
			            if ('' + obj.length === 'undefined') {
			                obj = new Array(obj);
			            }


						// We don't have a complex set of return values to process, but we 
						// do need to differentiate internationalisations
						for (i = 0; i<obj.length; i++) {
							if (obj[i].ValueSet == 'Internationalisations') {
								
								if (obj[i].Name == 'AdviceLabelFlowLaunchedLightBox') {cmp.set('v.AdviceLabelFlowLaunchedLightBox', obj[i].Value);}
								if (obj[i].Name == 'AdviceLabelFlowLaunchedNewTab') {cmp.set('v.AdviceLabelFlowLaunchedNewTab', obj[i].Value);}
								if (obj[i].Name == 'AdviceLabelNoDataMessage') {cmp.set('v.NoDataMessage', obj[i].Value);}
								if (obj[i].Name == 'ButtonLaunchFlow') {cmp.set('v.ButtonOK', obj[i].Value);}
								if (obj[i].Name == 'TipButtonCloseFlow') {cmp.set('v.TipButtonCloseFlow', obj[i].Value);}
								if (obj[i].Name == 'TipButtonLaunchFlow') {cmp.set('v.TipButtonOK', obj[i].Value);}
								if (obj[i].Name == 'TitleSelectFlow') {cmp.set('v.Title', obj[i].Value);}
							
							} else {
								// If not an internationalisation, item is a Listing Item (flow selection option)
								LIs.push(obj[i]);
							}
						}
						cmp.set("v.ListingItems", LIs);

			            
			            // Make radio options from the listing items
			            LIs.forEach(function (L) {			            
			            	opt = {label: L.Name, value: L.iahelp__Identifier__c};
			            	opts.push(opt);				
			            
			            });
			            
			            cmp.set("v.FlowRadioOptions", opts);
			            
		        	} else {
		        		helper.handleError('Error calling Salesforce servers for flow data');		        	
		        	}
		        });
				
				$A.enqueueAction(act);
				
			} else {
				// If we're in run mode, cue the desired flow
				cmp.set("v.OpMode", 'Run');
				helper.initialiseFlow(cmp, event, helper);
			}
						
		} catch (e) {
			helper.handleError(cmp, e);			
		}
  	},
  	
  	
  	// Note the details of any flow selected by a user in 'Prompt' operational mode
  	setFlow : function (cmp, event, helper) {
  	
  		// Locate full details of the selected flow, as stored in listing items
  		var LIs = cmp.get("v.ListingItems");
  		var selectedFlow = cmp.get("v.theFlowName");
  		
  		LIs.forEach(function(L){
  			if (L.iahelp__Identifier__c == selectedFlow) {
				if (L.iahelp__Parameters__c + '' != 'undefined') {
					cmp.set("v.theFlowParams", L.iahelp__Parameters__c);
				} else {
					cmp.set("v.theFlowParams", '');
				}
				
				cmp.set("v.theFlowLabel", L.Name);
  			}
  		});
  		
  	},
  	
  	
  	// Launch a flow selected by the user
  	cueFlow : function (cmp, event, helper) {
  		helper.initialiseFlow(cmp, event, helper);  		
  	},
  	
  	
  	// Placeholder only - limited utility
  	handleFlowStatusChange : function (cmp, event, helper) {
  	},
  	
  	
    // Handle pass throughs from sub-components etc.
    handlePassThroughs : function (cmp, event, helper) {
    
        var act = event.getParam("ActionCode");
        var parms = event.getParam("Parameters");
        var src = event.getParam("SourceComponent");
        
        // Close a modal dialogue in response to its request to do so
        if (act === 'DialogueRequestClose') {

        	// Only respond to requests from our own modal
        	if (src == cmp.get("v.ComponentId") + '_Dialogue') {

				// "Clean up" the dialogue: destroy any LUX component it contains
				try {
					var dlgComp = cmp.find("theModal");
					
					if (dlgComp + '' != 'undefined') {
						var dlgLUXComp = dlgComp.get("v.theLUXComp");
						if (dlgLUXComp + '' != 'undefined') {
						
							dlgLUXComp.set("v.body", []);
							$A.util.addClass(dlgLUXComp, 'slds-hide');
						}
					}
				} catch (e) {}
		
				// Hide the dialogue container:
		        var cnt = cmp.find('ModalContainer');
		        $A.util.addClass(cnt, 'slds-hide');

				
        	}
        	
        }
        
    },

  	
})