({ 
    
    // Obtain personalisation interactions and show desired list or index accordingly
    initialiseQAM : function (cmp, event, helper) {
    
        var act = cmp.get("c.getPersonalisations");
        var theQAM = cmp.find("QAMComponent");			// REM - this is the LIST sub-component
		var cfg = '';
		var defaultCfg;
		var i;
		var obj;

		
		// In case we should need it, note the default help menu option 
		// (show lists or show index) set for this QAM (we need to translate here
		// from pick list value / plain English to controller config names... 
		
		if (cmp.get("v.DefaultMenuOption") == 'Help for this Page') {
			defaultCfg = 'AllHelp';
		} else {
			defaultCfg = 'HelpIndex';
		}
				

		// These lines can only run if list is present
		try {		
		
			// Block our list's default behaviour, as we will seek personalisation interactions
			// (including LUX list type) below to re-set list to the last type chosen by the user
			theQAM.set("v.isInitialised", true); 
	
	        
	        act.setCallback(helper, function (response, cmp) {
	
	            if (response.getState() === "SUCCESS") {
	            
	                try {
	    				obj = JSON.parse(response.getReturnValue());
	
	    				for (i = 0; i<obj.length; i++) {
	    				
	    				    if (obj[i].iahelp__HelpInteractionType__c == 'LUX List Type') {
	    				        cfg = obj[i].iahelp__Description__c;
	    				        
		                    } else if (obj[i].attributes.type === 'iahelp__IASetIHOrg__c') {
		                        // Also note Global settings
		                        cmp.set("v.GlobalSettings", obj[i]);
	    				    }
	    				}
	    				
	                    // Default list configuration if no list type interaction found
	    				if (cfg == '') {cfg = defaultCfg;}
	
	                } catch (ex) {
	                    // Default list configuration on JSON error
	                	cfg = defaultCfg;
	                }
	            } else {
	                // Default list configuration on request error
	            	cfg = defaultCfg;
	            }
	
	
				// Special handling for the Help Index / Utility 1:
				if (cfg == 'HelpIndex') {
				
					// A root node for the index is not mandatory:
					// * If supplied but incorrect/unavailable, Utility 1 will render, and the tree itself will show no data message.
					// * If not supplied, Utility 1 will render only the no data message - but no components, so no return to list option.
					// We should not allow entry to the index in these instances...
					
					if (cmp.get("v.RootNode") == '') {
						cfg = 'AllHelp';
						cmp.set("v.renderLST", true);
					    cmp.set("v.theActiveComponent", "QAMListContainer");
	
					} else {
						cmp.set("v.renderUT1", true);
					    cmp.set("v.theActiveComponent", "QAMUT1Container");
					}
	
					// Set up the QAM's list, even if we're not going to show it:
					// this is necessary to log LUX List type interactions accurately if we return to the list.
					// The list type - whether or not we've enough info (a root) to show a requested Help Index - is 'All Help',
					// because if we're showing the Index, the list's last setting is forgotten, and if we're not showing
					// the index, the listing needs to default... 
					theQAM.set("v.CardConfig", 'AllHelp');
						
				    	    
				} else {
					// For QAM listings, adopt a "spinner" waiting cue, rather than
					// list's default "rows coming" style - as this is somehow more suited
					// when a user has interacted (rather than visuals awaiting whole page build)    
					theQAM.set("v.IHCardType", 'QAMList');    
	
					theQAM.set("v.CardConfig", cfg);
				    theQAM.reInitialise();
				}
	
			    // Whichever option is in play, log a 'LUX List Type' interaction 
			    // for retrieval via personalisations call, as above, next time
			    // (Lists also do this server side through getTools in QAM context)
			    
			    try {
					helper.logListType(cmp, event, helper, cfg);
			    } catch (ex){}


				// Hide QAM-wide waiting spinner	            
			    cmp.set("v.renderSPN", false);
			    
			    
				// If not auto-starting, this routine should
				// also show the QAM body - because it will have been summoned via
				// a QAM handle click
				if (cmp.get("v.StartAutomatically") == false) {
				    var activeComp = cmp.find(cmp.get("v.theActiveComponent"));
				    $A.util.removeClass(activeComp, 'slds-hide');	
				}			    

	        });
	        
	        // Send GET Personalisations (LUX List Type) action
	        $A.enqueueAction(act);		
	
		} catch (e) {
			// List not rendered - action not possible
		}
    
    },
        
    
    // Log an interaction detailing the position to which the QAM has been dragged
    logQAMPos : function (cmp,event, helper, pos) {

		//var act = cmp.get("c.logLUXInteraction");
		
		// Do not allow QAM handle to move out of its bounds
		pos = pos.replace('px', '');
		pos = Number(pos);
		if (pos < 90) {pos = 90;}
		if (pos > 600) {pos = 600;}
		/*
        act.setParams({ 
			"iTyp" : "9",
			"Description" : pos + 'px',
			"IHContext" : cmp.get("v.recordId")
        });                       
        */

        // Send action
       // $A.enqueueAction(act);

		helper.logLUXInteractions(cmp, 9,pos + 'px',cmp.get("v.recordId")).then((response) => {
						//do nothing to response.
					});
        
    },
    
    
    // Show the help index and log QAM list type reflecting this
    cueHelpIndex : function (cmp, event, helper) {
    
    	var QAM;
    	var UT1;
    	
    	// Entry to help index is contingent on a root node having been specified by page owner for this QAM:
    	// If one is specified but wrong, tree on Utility1 will render, so there will be a 'no data' message and
    	// a way back to our lists via configuration item clickables.
    	// With no root present at all, tree would not render at all and there'd be no way back, so we must prevent entry here...
    	
    	if (cmp.get("v.RootNode") == '') {
    		alert(cmp.get("v.QAMInternationalisations")[2]);
    		return;
    	}
    	
		cmp.set("v.renderUT1", true);

	    QAM = cmp.find('QAMListContainer');
	    UT1 = cmp.find('QAMUT1Container');

	    $A.util.addClass(QAM, 'slds-hide');
	    $A.util.removeClass(UT1, 'slds-hide');

	    cmp.set("v.theActiveComponent", "QAMUT1Container");
	    
	    // Lists (through getTools call) log their own 'LUX List Type' interaction:
	    // For the Help Index / Utility 1, we need to do this manually    
	    helper.logListType(cmp, event, helper, 'HelpIndex');
	    
    },
    
    
    // Logs an interaction recording type of listing / index requested on the QAM:
    // NB: this function is present on Card - but we are not an extension...
    logListType : function (cmp, event, helper, ListType) {
		/*
	    var act = cmp.get("c.logLUXInteraction");
	    
	    act.setParams({ 
	    	"iTyp" : "11",
			"Description" : ListType,
			"IHContext" : cmp.get("v.recordId")
	    });         
	    
		act.setCallback(this, function (response, cmp){ 
			if (response.getState() === 'SUCCESS') {
				// Do nothing if OK
				
			} else {
				console.log('QAM - error logging LUX List Type');			
			}
		});
		*/
	
	    // Send action
	   // $A.enqueueAction(act);

		helper.logLUXInteractions(cmp, 11,ListType ,cmp.get("v.recordId")).then((response) => {
					if (response.getState() === 'SUCCESS') {
				// Do nothing if OK
				
			} else {
				console.log('QAM - error logging LUX List Type');			
			}
		});
    },
    
    
})