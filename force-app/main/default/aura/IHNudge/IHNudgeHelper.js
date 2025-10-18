({        
	
	// Get all tags in the specified pool and select one at random to display
	initialise: function(cmp, event, helper) {
		
		var parms;
		
		// Set the pool of topics to request: if we're in fixed mode, don't bother getting these
		if (cmp.get("v.FixedMode") == false) {
			parms = cmp.get("v.RootNode");
		} else {
			parms = '[None]';
		}
		
        // NB: this action code will return all topics in the tag pool selected as 
        // the source of the nudge: one is chosen at random from these for display, below...
        cmp.set("v.ActionCode", "GetTagsForNudge"); 

        var act = cmp.get("c.getTools"); 
        act.setParams({ 
        	"ToolContext" : cmp.get("v.NudgePeriod"),
        	"ActionCode" : cmp.get("v.ActionCode"),
			"IHContext" : cmp.get("v.HelpRecordId"),
			"ClientComponentId" : cmp.get("v.ComponentId"),
			"Params" : parms,
			"SkipGlobals" : false,
        });                       
                
        // Add callback to process returned results
        act.setCallback(helper, function (response, cmp){
        	helper.processTools(response, cmp); 

			// Reflect nudge stats in diags
			cmp.set("v.Diags", (parseInt(cmp.get("v.NudgesLogged")) + 1) + '/' + cmp.get("v.MaxNudges"));

        	var lst = cmp.get('v.ListingItems');
        	if (cmp.get("v.FixedMode") == false && lst.length > 0) {
	        	
	        	// Pick a random topic from the available listing items
	        	var idx = Math.floor(Math.random() * Math.floor(lst.length));
	        	cmp.set("v.CurrentIndex", idx);
	        	cmp.set("v.CurrentHTID", lst[idx].Id);
	        	cmp.set("v.CurrentTName", lst[idx].Label);
	        	cmp.set("v.CurrentTSummary", lst[idx].Title);

	        	this.showNudge(cmp,helper);
	        	
        	} else {
	        	this.showNudge(cmp,helper);
        	}
        	
        }); 
        
        $A.enqueueAction(act);     
    },
    
    //Add new help parameter.
    showNudge : function (cmp , helper) {
    
    	var YMax = cmp.get("v.YMax");
    	var speed = cmp.get("v.AnimationSpeed");
    	var HideTime = cmp.get("v.AutoHideTime");
    	var cxt;


    	// Act only if we've not already exceeded nudge limit
		if (cmp.get("v.NudgesLogged") < cmp.get("v.MaxNudges") || cmp.get("v.MaxNudges") == 0) {
    
			// NEED TO USE A UNIQUE (AURA) ID TO AVOID ISSUE WITH SF CACHE 
			// OF MULTIPLE PAGE VERSIONS, SOME HIDDEN, AND THUS THE WRONG COPY
			// BEING ANIMATED
			//$('#' + cmp.get("v.ComponentId") + '_NudgeArea').animate({top: YMax + "px"}, speed);

			try {
/*
				var N = cmp.find("NudgeContent").getElement();
				$(N).animate({top: YMax + "px"}, speed);
*/

				window.setTimeout(
					$A.getCallback(function() {
						var N = cmp.find("NudgeContent").getElement();
						$(N).animate({top: YMax + "px"}, speed);
					}), 50
				);


		        
		        // If specified, set up auto-hide time
		        if (HideTime > 0) {
		        	window.setTimeout(
						$A.getCallback(function() {
							$('#' + cmp.get("v.ComponentId") + '_NudgeArea').animate({top: "-100px"}, 500);
						}), HideTime
					);
		        }
		        
		        
		        // Log an interaction to say that a nudge was displayed to the user
				//var act = cmp.get("c.logLUXInteraction");
				
				if (cmp.get("v.FixedMode") == true) {
			        // act.setParams({ 
					// 	"iTyp" : "20",
					// 	"Description" : 'Fixed Nudge Displayed: ' + cmp.get("v.CurrentTName") + ' - ' + cmp.get("v.CurrentTSummary"),
					// 	"IHContext" : cmp.get("v.ComponentId") + '^NULL^' + cmp.get("v.recordId"),
			        // });
					
					helper.logLUXInteractions(cmp, 20,('Fixed Nudge Displayed: ' + cmp.get("v.CurrentTName") + ' - ' + cmp.get("v.CurrentTSummary")) ,(cmp.get("v.ComponentId") + '^NULL^' + cmp.get("v.recordId"))).then((response) => {
						//do nothing to response.
					});
		
				} else {
			        // act.setParams({ 
					// 	"iTyp" : "20",
					// 	"Description" : 'Nudge Pool Topic Displayed',
					// 	"IHContext" : cmp.get("v.ComponentId") + '^' + cmp.get("v.CurrentHTID") + '^' + cmp.get("v.recordId"),
			        // });
					
					helper.logLUXInteractions(cmp, 20,'Nudge Pool Topic Displayed', cmp.get("v.ComponentId") + '^' + cmp.get("v.CurrentHTID") + '^' + cmp.get("v.recordId")).then((response) => {
						//do nothing to response.
					});
				}
		        
		        // Send action
		        //$A.enqueueAction(act);

					
	
			} catch (e){
				console.log('Error showing nudge: ' + e);
			}
	        
		}
    },
    
    
	// Hides the nudge bar (called on close click or automatically as required)
	hideNudge : function(cmp) {
		var N = cmp.find("NudgeContainer");
		$A.util.addClass(N, "slds-hide");
	},
    
    
})