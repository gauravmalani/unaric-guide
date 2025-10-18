({

	// Clear out / reset this control
	reInitialise : function (cmp, event, helper) {
		
		cmp.set("v.HeaderText", "");
		cmp.set("v.BodyText", "");			
		cmp.set("v.ImageURL", "");			
		cmp.set("v.VideoURL", "");	
			
		// In doing this, re-set all guide prompt controls to data "clean" state
		cmp.set("v.isDirty", false);
	},


	// Ensure that editing mode accords with user rights (i.e., prevent mismatches between op mode and allow edits)
	enforceEditingRights : function (cmp, event, helper) {
		
		// Edit mode is only allowed if the AllowEdit switch has been set
		if (cmp.get("v.AllowEdits") == false) {
			cmp.set("v.OpMode", "View");
		}		
	},
	

	// Raise a closure request for this prompt
	requestClose : function(cmp, event, helper) {
			
        var appEvent = $A.get("e.c:evtPassThrough");

        appEvent.setParams({"SourceComponent": cmp.get("v.ComponentId")});
        appEvent.setParams({"ActionCode": "DialogueRequestClose"});
        appEvent.setParams({"Parameters": 'GPrompt'});

		try {
			appEvent.fire();		
		} catch (e) {
			alert(e);        
		}
		
	},
	
	
	// Request navigation to next guide step:
	showNextStep : function (cmp, event, helper) {
		var stepNum = 0;
		var i = 0;
		var nextGuide = '';
		
		// Prevent click on navigation tools bubbling to containing controls etc.
		event.stopPropagation();
		
		
		// If in linear mode at end of steps ...
		if (cmp.get("v.ReadingListType") == 1 && parseInt(cmp.get("v.CurrentLocalStep"), 10) >= parseInt(cmp.get("v.TotalLocalSteps"), 10)) {
			
			// Check whether we are linked to another guide, which will have been noted as guide was logged...
			nextGuide = cmp.get("v.NextGuide");
			
			
			if (nextGuide != '') { 
				// If current guide has been linked to another, navigate to that guide
				console.log('IHCalloutPrompt.showNextStep: navigation to next guide requested: ' + nextGuide);
				nextGuide = nextGuide.split('^');
				
				// Generate a URL for the requested record and guide
				var pageReference = {
					type: 'standard__recordPage',
			        attributes: {
			        	recordId: nextGuide[0],
			        	actionName: 'view'
			        },
			        state: {
			        	iahelp__GID: nextGuide[1]
			        }
			    };	
			    
			    // Advise user we're about to navigate, if an advice message has been specified
			    if (nextGuide[2] != '') {
			    	alert(nextGuide[2]);
			    }
				
				// Use our LUX navigation tag to navigate
				var navService = cmp.find("navService");				
				navService.navigate(pageReference);


			} else {
				// If in linear mode and at end of steps with no onward link to further guide, advise user guide is complete	
//alert(cmp.get("v.QAMMessageGuideStepsCompleted"));

var P = cmp.get("v.Parent");

var src = 'c:IHAlert';
var aMap = {
	"Height": -1,   
	"Title" : cmp.get("v.QAMMessageGuideStepsCompleted"),
	"Message" : cmp.get("v.TipButtonClose"),
	"Image" : "/resource/iahelp__IHSupportMaterials/img/StockImages/009C.svg", 
	"ToolContext" : "AlertOKOnly",
	"Style" : "Two Column",
    "ComponentId" : P.get("v.ComponentId")
  };

P.doDialogue('ttl', 'Alert', src, aMap, -1, false, false, false, P, false);

				
				// In these cases, we should request closure of all steps etc.
				var appEvent = $A.get("e.c:evtPassThrough");
				appEvent.setParams({"SourceComponent": cmp.get("v.ComponentId")});
				appEvent.setParams({"ActionCode": "CloseGuide"});
				appEvent.setParams({"Parameters": ''});
				appEvent.fire();		
			
			}
			
		} else {			
			if (cmp.get("v.ReadingListType") == 1) {
				// Otherwise, in linear mode request next step
				stepNum = parseInt(cmp.get("v.CurrentLocalStep"), 10) + 1;

			} else {
				// In non-linear mode, request the specified step				
				var lst = cmp.find("stepList");
				var GFlds = cmp.get("v.GuidedFields");
				
				GFlds.forEach(function(F) {
					i += 1;
					if (lst.get("v.value") == F) {
						stepNum = i;
					}
				});
				
			}

			// Having arrived at a step number, raise an event to request it
			var appEvent = $A.get("e.c:evtPassThrough");
			appEvent.setParams({"SourceComponent": cmp.get("v.ComponentId")});
			appEvent.setParams({"ActionCode": "NavToGuideStep"});
			appEvent.setParams({"Parameters": stepNum});
			appEvent.fire();		
			
		}
		
	},
	
	
	// Switch between prompt view & edit modes
	toggleOpMode : function (cmp, event, helper) {
		if (cmp.get("v.OpMode") == 'View') {
			cmp.set("v.OpMode", "Edit");
		} else {
			cmp.set("v.OpMode", "View");
		}
	},
	
	
	// Ensure entered URLs are valid - once we've finished editing them
	validateVURL : function (cmp, event, helper) {
		if (cmp.get("v.OpMode") == 'View') {
			cmp.set("v.VideoURL", helper.ensureProtocol(cmp.get("v.VideoURL")));
		}
	}, 
	validateIURL : function (cmp, event, helper) {
		if (cmp.get("v.OpMode") == 'View') {
			cmp.set("v.ImageURL", helper.ensureProtocol(cmp.get("v.ImageURL")));
		}
	}, 
	VURLBlur : function (cmp, event, helper) {
		cmp.set("v.VideoURL", helper.ensureProtocol(cmp.get("v.VideoURL")));
	}, 
	IURLBlur : function (cmp, event, helper) {
		cmp.set("v.ImageURL", helper.ensureProtocol(cmp.get("v.ImageURL")));
	}, 	


    // Note the fact that data has been changed
    // Only respond to data changes once we're initialised:  Field focus is used to trap this fact
    // so that only changes in fields after form build represent genuine edits to be noted
    markInitialised : function (cmp, event, helper) {
    	cmp.set("v.isInitialised", true);
    },    
    setDirty : function (cmp, event, helper) {    	
    	if (cmp.get("v.isInitialised") == true) {
	    	cmp.set("v.isDirty", true);
	    	
	    	// Raise an event to advise interested parties we are dirty
            var appEvent = $A.get("e.c:evtPassThrough");
            appEvent.setParams({"SourceComponent": cmp.get("v.ComponentId")});
            appEvent.setParams({"ActionCode": "PromptDirty"});
            appEvent.setParams({"Parameters": cmp.get("v.Parent")});
            appEvent.fire();
  	
    	}
    },	

})