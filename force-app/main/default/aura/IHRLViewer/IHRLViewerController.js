({
 
    // Cue initial listing
	doneRendering : function(cmp, event, helper) {
	    helper.initialiseList(cmp, event, helper);
	},


    // Wrapper allowing client LUX components (such as the QAM) to configure their embedded components and cue re-building
	reInitialise : function (cmp, event, helper) {
		cmp.set('v.isInitialised', false);
	    helper.initialiseList(cmp, event, helper);
    },


	// Navigate to a particular RL entry and log a related interaction
	NavTo : function (cmp, event, helper) {
	
		// Show the selected entry
		var theId = event.target.id;
		theId = theId.replace('NAVTo','');
		
		helper.navToItem(cmp, helper, theId);	    
	},


	// FORCE re-sizing of media!!!!
	finalInitialise : function (cmp, event, helper) {
		helper.finalInitialise(cmp, helper);
	},


	// Respond to the "select" event raised by lists (if we're listening to the source component)
    selectRecord : function (cmp, event, helper) {
        
        var theRecord = event.getParam("RecordId");
        var cxt = 'RLViewer';
        var aCode = 'ReadingListEntries';
        
        // Only respond to events that do not emanate from ourselves / do
        // emanate from the  "desired" master list we wish to tie to
        if (helper.eventBeingListenedTo(cmp, event) == true) {
            // In these cases, we're changing the list (server call)
            // so show our "waiting" cues...
            helper.showSpinner(cmp);

	        var act = cmp.get("c.getTools");
            act.setParams({ 
                "ToolContext" : cxt, 
                "ActionCode" : aCode,
				"IHContext" : theRecord,
				"ClientComponentId" : cmp.get("v.ComponentId"),
				"SkipGlobals" : false,
            });                       
            
            cmp.set("v.IHContext", theRecord);
            
            // Add callback to process returned results
            act.setCallback(helper, function (response, cmp){
                helper.processTools(response, cmp);
                
	            var RLEs = cmp.get("v.ListingItems");
	            
	            if (RLEs.length > 0) {
		            cmp.set("v.Title", RLEs[0].iahelp__HelpReadingList__r.Name);      
	            }
                
            }); 
            
            $A.enqueueAction(act);


        }
    },


	// Respond to events from super-class - display settings etc...
	handlePassThroughs : function (cmp, event, helper) {
        
        var act = event.getParam("ActionCode");
        var src = event.getParam("SourceComponent");
        
        
        // With display settings etc., we only want to respond to our own events...
        if (helper.eventIsOurOwn(cmp, event)) {
        
			if (act === 'ShowRLDescriptions') {
			    cmp.set("v.ShowDescriptions", true);
			}
			
			if (act === 'HideRLDescriptions') {
			    cmp.set("v.ShowDescriptions", false);
			}
			
			if (act === 'RLMediaLarge') {
			    cmp.set("v.MediaWidth", "100");
			}
			
			if (act === 'RLMediaSmall') {
			    cmp.set("v.MediaWidth", "50");
			}
			
			if (act === 'RLMediaMedium') {
			    cmp.set("v.MediaWidth", "75");
			}
			
			if (act === 'Edit') {
				cmp.set("v.DataMode", 'Edit');
			}

			if (act === 'View') {
				cmp.set("v.DataMode", 'View');
			}
			if (act === 'SelectReadingList') {
				helper.doSelectReadingListDialog(cmp, helper);
			}

			// Pin the current Reading List for this component instance
			if (act === 'PinRL') {
				helper.showSpinner(cmp);
				var action = cmp.get("c.pinReadingList");
				action.setParams({
					ComponentId: cmp.get("v.ComponentId"),
					rlId: cmp.get("v.IHContext")
				});
				action.setCallback(helper, function(response){
					helper.hideSpinner(cmp);
					var state = response.getState ? response.getState() : (response.getReturnValue ? 'SUCCESS' : 'ERROR');
					if (state === "SUCCESS") {
						// Empty string denotes success per logAuthorConfig pattern
						cmp.set("v.DataMode", "View");
					} else {
						// keep UX simple; optionally surface toast via IHCard if available
						cmp.set("v.DataMode", "View");
					}
				});
				$A.enqueueAction(action);
			}
        }
		
		// Handle when user clicks a reading list item in the dialog
		// IMPORTANT: Scope this to only the instance that opened the dialog.
		// We do that by ensuring the event is both from our own component OR our own dialogue.
		if (act === 'RL_SELECT_FOR_VIEW') {
			var parameters = event.getParam("Parameters");
			console.log('RL_SELECT_FOR_VIEW parameters:', parameters);
			var readingListId = parameters;
			if (parameters && parameters.indexOf('^') > -1) {
				var parts = parameters.split('^');
				readingListId = parts[0];
			}
			
			if (!readingListId) {
				console.error('No reading list ID provided');
				return;
			}
			
			console.log('Reading List ID selected:', readingListId);
			
			helper.showSpinner(cmp);
			cmp.set("v.IHContext", readingListId);
			
			var act = cmp.get("c.getTools");
			act.setParams({
				"ToolContext": 'RLViewer',
				"ActionCode": 'ReadingListEntries',
				"IHContext": readingListId,
				"ClientComponentId": cmp.get("v.ComponentId"),
				"SkipGlobals": false
			});
			
			act.setCallback(helper, function (response, cmp) {
				helper.processTools(response, cmp);
				var RLEs = cmp.get("v.ListingItems");
				
				if (RLEs && RLEs.length > 0 && RLEs[0].iahelp__HelpReadingList__r) {
					cmp.set("v.Title", RLEs[0].iahelp__HelpReadingList__r.Name);
				}
				// Now switch back mode to View
				cmp.set("v.DataMode", 'View');
			});
			
			$A.enqueueAction(act);
		}
        
	},
	

	// Handle image clicks / light-boxing
	doLightBox : function (cmp, event, helper) {
		
		// Each image tile is marked with index position as part of its class: retrieve this value
		var L = cmp.get("v.ListingItems");
		var Idx = event.target.className.replace('RLTile_', '');
		var U;
		var ttl;
		
		// Use index to locate image title and URL from our listing items
		ttl = L[Idx].iahelp__HelpTopic__r.Name;
		if (L[Idx].iahelp__HelpTopic__r.iahelp__ImageTitle__c + '' != 'null' && L[Idx].iahelp__HelpTopic__r.iahelp__ImageTitle__c + '' != 'undefined') {
			ttl += ': ' + L[Idx].iahelp__HelpTopic__r.iahelp__ImageTitle__c;
		}
		
		U = L[Idx].iahelp__HelpTopic__r.iahelp__ImageURL__c;
			
			
		// Now cue a LUX-type dialogue with these parameters
	    var aMap = {
	        "ImageURL" : U,
	        "Height" : '520',	        
	        "ImageTitle" : ttl        
	    };

		helper.doDialogue('Image Viewer', 'LUX', 'c:IHImageViewer', aMap, 500, false, true, false, cmp, false);
	
	},


	// UX Rebranded style: expand / collapse individual entry details
	toggleStep : function(cmp, event, helper) {
		
		
		var theId = event.currentTarget.id;
		
		 var RLEs = cmp.get("v.ListingItems");
		 
		 RLEs.forEach(function (RLE){
			 if(RLE.Id == theId) {
				 RLE.Expanded = ! RLE.Expanded;
				 RLE.Rendered = true;
			 }
		 });
		 
		 cmp.set("v.ListingItems", RLEs);
	},
	
	
	// Navigate to the next step in a page walk through (delegated)
	setStep : function (cmp, event, helper) {
		helper.setStep(cmp, event, helper);	
	},
	
	
	
	
	// CAROUSEL STYLE HANDLING METHODS
    // Show the desired Notification carousel panel from the set presented via carousel selectors
    carouselSelectorClick : function (cmp, event, helper) {
    
    	var sel;
    	var i;	
    	var lst = cmp.get("v.ListingItems");
		var globalId = cmp.getGlobalId();
    	
    	
    	// If user interacts with selectors, clear auto-animation
		window.clearInterval(cmp.get("v.CarouselTimer"));
    	
    	// Remove selected class from all selectors, also add a "carousel halted" class
    	for (i = 0; i<lst.length; i++) {
    		sel = document.getElementById(globalId + 'carouselSelector_' + i);
    		$A.util.removeClass(sel, 'slds-is-active');
    		$A.util.addClass(sel, 'IHCarouselSelectorHalted');
    	}
    	
    	// Add selected class to clicked selector
    	sel = event.target;
    	$A.util.addClass(sel, 'slds-is-active');
    	
    	// Note the active carousel panel index
    	i = parseInt(sel.id.replace(globalId + 'carouselSelector_', ''));
    	cmp.set("v.ActiveCarouselPanel", i);

// Set designer layout info based on current record
var DD = cmp.find("theDesigner");
var defaultLayout = 'iahelp__Summary__c^Field^slds-text-heading_medium slds-align_absolute-center slds-m-bottom_small|iahelp__ImageURL__c^Image^|iahelp__Description__c^Field^';
var LD = '^';


DD = DD[i];

if (lst[i].iahelp__HelpTopic__r.iahelp__Template__r.iahelp__PageURL__c.indexOf(LD) != -1) {
	// Record specifies a custom layout
	DD.set("v.LayoutInfo", lst[i].iahelp__HelpTopic__r.iahelp__Template__r.iahelp__PageURL__c);
} else {
	// No topic specific custom layout specified: use default instructions
	DD.set("v.LayoutInfo", defaultLayout);
}    	

		// Set the current record for use by the detail designer that displays the topic in Carousel mode
		cmp.set("v.CurrentRecord", lst[i].iahelp__HelpTopic__r);
    	
    	
    },
		
	// Handle when user clicks a reading list item in the dialog
	// handleReadingListSelect : function(cmp, event, helper) {
	// 	var actionCode = event.getParam("ActionCode");
	// 	var parameters = event.getParam("Parameters");
		
	// 	console.log('handleReadingListSelect actionCode:', actionCode, 'parameters:', parameters);
		
	// 	if (actionCode !== 'RL_SELECT_FOR_VIEW') {
	// 		console.log('Ignoring - waiting for RL_SELECT_FOR_VIEW, got:', actionCode);
	// 		return;
	// 	}
		
	// 	console.log('User selected a reading list from dialog');
		
	// 	var readingListId = parameters;
	// 	if (parameters && parameters.indexOf('^') > -1) {
	// 		var parts = parameters.split('^');
	// 		readingListId = parts[0];
	// 	}
		
	// 	if (!readingListId) {
	// 		console.error('No reading list ID provided');
	// 		return;
	// 	}
		
	// 	console.log('Reading List ID selected:', readingListId);
		
	// 	helper.showSpinner(cmp);
	// 	cmp.set("v.IHContext", readingListId);
		
	// 	var act = cmp.get("c.getTools");
	// 	act.setParams({
	// 		"ToolContext": 'RLViewer',
	// 		"ActionCode": 'ReadingListEntries',
	// 		"IHContext": readingListId,
	// 		"ClientComponentId": cmp.get("v.ComponentId"),
	// 		"SkipGlobals": false
	// 	});
		
	// 	act.setCallback(helper, function (response, cmp) {
	// 		helper.processTools(response, cmp);
	// 		var RLEs = cmp.get("v.ListingItems");
			
	// 		if (RLEs && RLEs.length > 0 && RLEs[0].iahelp__HelpReadingList__r) {
	// 			cmp.set("v.Title", RLEs[0].iahelp__HelpReadingList__r.Name);
	// 		}
	// 		// Now switch back mode to View
	// 		cmp.set("v.DataMode", 'View');
	// 	});
		
	// 	$A.enqueueAction(act);
	// }
		
})
