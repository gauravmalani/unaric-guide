({

	// Use incoming flow name and optional flow parameters to launch the desired flow
	initialiseFlow : function (cmp, event, helper) {
	
		try {
			var flow;									// Our flow component, if in 'In Place' dialogue mode
			var CG;										// Our component generator, if in 'LightBox' dialogue mode
			var parms = cmp.get("v.theFlowParams");		// Input parameters collection, supplied as delimited string
			var D1 = '|';								// Delimiter between each input parameter
			var D2 = '¬';								// Delimiter for name/type/value within each parameter in the collection
			var parm;									// An individual parameter, split into its name/type/value parts
			var i;										// For looping
			var inputVars = [];							// Collection of maps to build and supply to the flow
			var inputVar;								// Individual map within this collection
			var onwardParms = '';						// Parameters to pass forward if not launching in place
			
			
			// Whatever dialogue mode proved relevant, below, we now need to switch to 'run' operational mode
			cmp.set("v.OpMode", 'Run');

			
			if (parms != '') {
				// Flow input parameters are optional: process them if supplied
				parms = parms.split(D1);
				
				for (i=0; i<parms.length; i++) {			
					parm = parms[i].split(D2);	
					
					// Ensure parameters are in correct format:
					// Should be as follows:
					
					// [Input Variable Def] {D1} [Input Variable Def]
					// With each [Input Variable Def] in the form:
					// [Input parameter name] {D2} [Data type] {D2} [Value] 
					
					if (parm.length != 3) {
						helper.handleError(cmp, 'Parameter ' + i + ' (' + parms[i] + ') is not in the required format.');
						return;
						
					} else {
					
						// If we are provided with a 'target' parameter, use this to 
						// set the way the flow will display
						if (parm[0] == 'DialogueMode') {
							
							switch (parm[2]) {
								case 'NewTab':
									cmp.set("v.DialogueMode", 'NewTab');
									break;
									
								case 'LightBox':
									cmp.set("v.DialogueMode", 'LightBox');
									break;
									
								default:
									cmp.set("v.DialogueMode", 'InPlace');
									flow = cmp.find("theFlow");	
									break;
							}
						
						} else {
							// All parameters EXCEPT targetting info get sent directly to the flow

							// Need to de-tokenize parameter values:
							// How best to do this - given that we're not a card!
							// We can only offer some simplified detokenizing at this stage...
							parm[2] = parm[2].split('{!recordId}').join(cmp.get("v.recordId"));

							inputVar = {name: parm[0], type: parm[1], value: parm[2]};
							inputVars.push(inputVar);	
							
							// Also keep a version of parameters with dialogue mode parsed out
							onwardParms += parm[0] + D2 + parm[1] + D2 + parm[2] + D1;
						}
											
					}		
				}
				if (onwardParms.length > 0) {onwardParms = onwardParms.substring(0, onwardParms.length - 1);}


				// Having processed any parameters, start the flow in the specified manner
				switch (cmp.get("v.DialogueMode")) {

					case 'NewTab':
						var src = '';
						var CRoot = cmp.get('v.CommunityRoot');

						// If root is 'null', this can be ignored in most cases
						if (CRoot + '' == 'null') {CRoot = '';}
						if (CRoot != '') {CRoot = '/' + CRoot;}
												
						src += CRoot + '/apex/iahelp__IHLUXOutHost?NSApp=iahelp&NSComp=iahelp&App=appIH&Comp=IHFlowLauncher';
						src += '&Parms=theFlowName~' + cmp.get("v.theFlowName");
						
						// We mustn't forward our dialogue mode parameters - so use the version with these parsed out here...
						src += '^theFlowParams~' + onwardParms;

						
						window.open(src);
						break;
									
					case 'LightBox':
						var dlg = cmp.find('theModal');

						dlg.set("v.FrameSource", 'c:IHFlowLauncher');
        				dlg.set("v.FrameType", 'LUX');
						dlg.set("v.Title", cmp.get("v.theFlowLabel"));
        				dlg.set("v.FrameHeight", 600);
        				dlg.set("v.AllowScroll", true);
    					dlg.set("v.LargeMode", true);
    					dlg.set("v.ShowFooter", true);

    					// We mustn't forward our dialogue mode parameters - so use the version with these parsed out here...
		                var aMap = {
		                	"theFlowName": cmp.get("v.theFlowName"),
		                	"theFlowParams": onwardParms,        
		                };
                		dlg.set("v.FrameAttributes", aMap);

    					dlg.reInitialise();
						break;
									
					default:
						flow = cmp.find("theFlow");	
						flow.startFlow(cmp.get("v.theFlowName"), inputVars);
						break;
	
				}

				
			} else {
				// If no input parameters were supplied, just start the flow (with no inputs)
				cmp.set("v.DialogueMode", 'InPlace');
				flow = cmp.find("theFlow");	
				flow.startFlow(cmp.get("v.theFlowName"));
			}

		} catch (e) {
			helper.handleError(cmp, e);			
		}
  	},
  	 	   
	
	// Error reporting utility
	handleError : function (cmp, msg) {
		msg = 'IHFlowLauncher - initialisation error: ' + msg;
		console.log(msg);			
		cmp.set("v.Diags", msg);
		cmp.set("v.isError", true);
	},
	
})