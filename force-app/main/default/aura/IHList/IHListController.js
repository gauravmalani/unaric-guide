({

	// Get the largely invariant, cacheable information used on cards (delegated)
	// then cue initialisation
	init : function(cmp, event, helper) {
    
		helper.initialiseGlobals(cmp, event, helper);
        
	},

  
    // Wrapper allowing client LUX components (such as the QAM) to configure their embedded lists and cue re-building
	reInitialise : function (cmp, event, helper) {
		cmp.set('v.isInitialised', false);
	    helper.initialiseList(cmp, event, helper);
    },
	

// MOUSE OVER / OUT METHODS RESERVED FOR POTENTIAL FUTURE USE
listingItemMouseOver : function (cmp, event, helper){
	//cmp.set("v.Diags", event.currentTarget.id);
	/*
	if (cmp.get("v.MouseoverLatch") == false) {
		cmp.set("v.MouseoverLatch", true);
		helper.doGeneratedComponent(cmp, 'c:IHDetail~SuppressHeader¬true|SuppressFooter¬true|Height¬300|OuterContainerClass¬PopupComponent');
	}
	*/
},

listingItemMouseOut : function (cmp, event, helper){
	//helper.doGeneratedComponent(cmp, '');
	//cmp.set("v.MouseoverLatch", false);
},

	
	// Respond to the "select" event raised by lists (if we're listening to the source component)
    selectRecord : function (cmp, event, helper) {
        
        var theRecord = event.getParam("RecordId");
        var cxt = cmp.get('v.ToolContext');
        var aCode = cmp.get('v.ActionCode');

       
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
				"Params" : '',
				"SkipGlobals" : false,
            });                       
            
            cmp.set("v.IHContext", theRecord);
            cmp.set("v.recordId", theRecord);
            
            // Add callback to process returned results
            act.setCallback(helper, function (response, cmp){
                helper.processTools(response, cmp);                
                helper.postProcess(cmp, helper);			                
            }); 
            
            $A.enqueueAction(act);

        }
    },
    
    
    // Respond to requests to toggle our listing size
    handlePassThroughs : function (cmp, event, helper) {

        var aCode = event.getParam("ActionCode");
        var src = event.getParam("SourceComponent");
        var parms = event.getParam("Parameters");
        
        //If ActionCode is TreeSearchList then we are setting ListingItems from Tree.
        if(cmp.get("v.listitem").length>0 || aCode === "TreeSearchList")
        {
            cmp.set("v.ListingItems", cmp.get("v.listitem"));
        }         
                 
        // Direct request to expand / collapse list
        if (aCode === 'ShowListingDetails' || aCode === 'HideListingDetails') {

            // Switch the listing row style
            if (aCode === 'ShowListingDetails') {
        		helper.toggleListingDetails(cmp, 'Expanded', helper);
                
            } else {
            	helper.toggleListingDetails(cmp, 'Hidden', helper);
            }
        }

        
        // (Card) tool processing complete: implies need to re-set list style
        if (helper.eventIsOurOwn) {                
	        if (aCode === 'ComponentToolsProcessed') {
				cmp.set("v.CurrentRows", cmp.get("v.InitialRows"));
	            helper.establishAndToggleListingDetails(cmp, helper);
	        }	        
        }        
        
        // Certain actions should only provoke response if they're our own (and require a Component ID)
        if (src != '' && src != null && helper.eventIsOurOwn(cmp, event)) {

			   if (aCode == 'LinkTopic') {
                // Relate the topic whose tool was clicked to the context / current help topic
                
                var D1 = '^';
                parms = parms.split(D1);
                var RefHTID = cmp.get("v.IHContext");
                var RelHTID = parms[0];
                
                // Check current URL
                var currentUrl = window.location.href;
                
                var act;
                if (currentUrl.includes("iahelp__HelpReadingList__c")) {
                    act = cmp.get("c.addExistingTopictoRL");
                } else {
                    act = cmp.get("c.createRelatedHelp");
                }
                
                act.setParams({ 
                    "ReferringHTID": RefHTID,
                    "RelatedHTID": RelHTID
                });                       
                
                act.setCallback(this, function (response, cmp){
                    var ret = response.getReturnValue();
                    if (ret == helper.Internationalise(cmp, 'MessageGenericTaskComplete')) {
                        // If the insertion was successful, re-query our list
                        cmp.set('v.isInitialised', false);
                        helper.initialiseList(cmp, event, helper);
                    } else {
                        // Report the unsuccessful outcome
                        alert('Error: ' + ret);
                    }
                });
                $A.enqueueAction(act);
            }
			                
			if (aCode == 'LinkResource') {
				// Add the resource whose tool was clicked to the context / current help topic
				
				var D1 = '^';     			            		
				parms = parms.split(D1);
				var HTID = cmp.get("v.IHContext");
				var ResID = parms[0];
			
			
				var act = cmp.get("c.createHelpTopicResource");
			    act.setParams({ 
			    	"ResourceId" : ResID,
			    	"HTID" : HTID
			    });                       
			
			    act.setCallback(this, function (response, cmp){
			    	
			    	var ret = response.getReturnValue();
			    	if (ret == helper.Internationalise(cmp, 'MessageGenericTaskComplete')) {
			
				    	// If the insertion was successful, re-query our list
						cmp.set('v.isInitialised', false);
					    helper.initialiseList(cmp, event, helper);
			    		
			    	} else {
			    		// Report the unsuccessful outcome
			    		alert('Error: ' + ret);
			    	}
			    	
			    });
			    $A.enqueueAction(act);
			
			}
	
	
			// Refresh the metadata about Apps in the current org
			if (aCode == 'RefreshAppListing') {
				var src = '/apex/iahelp__IHLUXOpHandler?Op=4';
			    helper.doDialogue('RefreshAppListing', 'VF', src, null, 100, false, false, false, cmp, true);	
			}
			
			
			// Refresh the metadata about tabs in the (previously selected, context) App
			if (aCode == 'RefreshTabListing') {
				var src = '/apex/iahelp__IHLUXOpHandler?Op=5&IHContext=' + cmp.get("v.IHContext");
			    helper.doDialogue('RefreshAppListing', 'VF', src, null, 100, false, false, false, cmp, true);
			}

        
        	// Allow creation of a new Sticky Note via a modal dialogue
	        if (aCode === 'NewStickyModal') {

                var src = 'c:IHNote';
                var aMap = {
            		"recordId": cmp.get("v.IHContext")
                };
                helper.doDialogue('Stickies', 'LUX', src, aMap, 500, false, false, true, cmp, true);
	        }
	        
	        
        	// Delete the current topic, after local confirm message
	        if (aCode === 'DeleteTopic') {
            	if (confirm(helper.Internationalise(cmp, 'MessageDeleteWarning'))) {
            	
            		// Parameters here (from IHCard / listing tool click) are in the passthrough form of:
            		// [Listing ID] [Delimiter] [Other source parameters]
            		// Here we just want the listing (Topic) ID
            		var D1 = '^';     			            		
            		parms = parms.split(D1);

    				var act = cmp.get("c.deleteTopic");
			        act.setParams({ 
			        	"HelpTopicId" : parms[0] 
			        });                       
	                
			        // Add callback to process returned results
			        act.setCallback(this, function (response, cmp){
			        
			        	// This should return an empty response value:
			        	var ret = response.getReturnValue();
			        	
			        	if (ret != '') {
			        		// If there are any diagnostics, assume this is an error and show them
			        		cmp.set("v.Diags", ret);
			        		
			        	} else {
			        		// If delete was successful, reflect this in diags...
			        		cmp.set("v.Diags", helper.Internationalise(cmp, 'MessageGenericTaskComplete'));
			        		
			        		// ... then update our listing to depict row deletion: add IHHelpedSFElementError class
			        		var lst = cmp.get("v.ListingItems");
			        		
			        		lst.forEach(function(L) {
			        			if (L.Id == parms[0]) {
			        				L.StyleClass = 'IHHelpedSFElementError';
			        			}
			        		});
			        		
			        		cmp.set("v.ListingItems", lst);
			        	}
		        		
			        });

			        // Send action
			        $A.enqueueAction(act);
            	}
	        }
	                
	        
	        // Save keywords identified on a "suggested keywords" dialogue
	        if (aCode == 'saveSelectedKeywords') {
	        	
	        	// Ensure there are some selections
	        	var sels = cmp.get("v.ListingSelections");
	        	var LIs = cmp.get("v.ListingItems");
	        	
	        	if (sels == '' || sels == null) {
	        		alert(helper.Internationalise(cmp, 'MessageNoSelections'));
	        		return;
	        		
	        	} else {
	        		// Ensure we're provided with a name for the tag pool
	        		var poolName = prompt(helper.Internationalise(cmp, 'MessageEnterPoolName'), '');	        		
	        		if (poolName == '') {
	        			alert(helper.Internationalise(cmp, 'MessageNoName'));
	        			return;
	        		}
	        		
	        		var act = cmp.get("c.createTagPool");
	        		
			        act.setParams({ 
			        	"PoolName" : poolName, 
			        	"PoolMembers" : sels
			        });                       
		                
			        // Add callback to process returned results
			        act.setCallback(this, function (response, cmp){
				        
			        	var ret = response.getReturnValue();
			        	
			        	// If we get an error, do nothing
			        	if (ret.indexOf('Error') != -1) {
				        	cmp.set("v.Diags", ret);
				        	return;			        	
			        	}
			        	
			        	// Otherwise, clear our selections and remove their listings from our control
			        	// (as we don't want to allow any attempt to add them to another pool - which will fail)
				        LIs.forEach(function(v) {
				        	if ($('#LINarrow_' + v.Id).hasClass('IsSelected')) {
					        	LIs.splice(LIs.indexOf(v), 1);				        	
				        	}
				        })
				        
				        cmp.set("v.ListingItems", LIs);
			        	helper.markSelectionControlledTools(cmp);
			        	
			        	// Then issue and event to say a pool was created
			        	var appEvent = $A.get("e.c:evtPassThrough");
			        	appEvent.setParams({"SourceComponent": cmp.get("v.ComponentId")});
			        	appEvent.setParams({"ActionCode": 'TagPoolCreated'});       
        				appEvent.setParams({"Parameters": ret});
        				appEvent.fire();
        				
	        		});
	        		
			        // Send action
			        $A.enqueueAction(act);
	        	}
	        }        
        }
        
        
        // Certain events should fire if our own or being listened to
        if (helper.eventBeingListenedTo(cmp, event) || 
        		(src != '' && src != null && helper.eventIsOurOwn(cmp, event))) {

	        // Re-get current component listing:
	        // CF: RefreshHelpList - handled in IHCard:
	        // This routine re-initialises the whole control (allowing for context changes etc)
	        // as opposed to simply re-getting the content listing (for a pre-established context)
	        
			if (aCode === 'RefreshCurrentList') {
				cmp.set('v.isInitialised', false);
			    helper.initialiseList(cmp, event, helper);		
			}
        }
        
        
        // Certain actions should only fire if we're listening
        if (helper.eventBeingListenedTo(cmp, event)) {
        
	        // Re-get current component listing
			if (aCode === 'DataAmended') {
				cmp.set('v.isInitialised', false);
			    helper.initialiseList(cmp, event, helper);		
			    
			    // For a data amended event, we'll want to re-select the record we were 
			    // on - in a way that does NOT fire further event cascades...
		    	helper.setSelectedRow(cmp, parms);			    		
			}
        
        
	        // Filter to a (collection of) tag(s)
	        if (aCode === 'FilterToTags') {

	        	var existingFilters = cmp.get("v.ListingTagFilters");		// The amalgamated tag filtering instructions used to produce the list
	        	var allFilters = cmp.get("v.AllFilters");					// A collection of tag filter instructions for each filtering ctl encountered
	        	var newFilters = parms;										// Incoming filter instruction from a filtering control
	        	var newMode;												// Mode from the above (ANY or ALL tags required)
	        	var D1 = '^';     	
				var aFilter;
				var logged = false;
				var i = 0;	       
	
	        	newMode = parms.split(D1);
	        	newMode = newMode[1];
	        	

				// We'll need to keep track of each filtering control we encounter, replacing
				// the filter from each independently as it comes in, then amalgamating them all for use 
				// in our ultimate listing tag filters property
				
				// Log the incoming filter, replacing any that may have existed for the particular filtering control
				console.log('Listing "' + cmp.get("v.ComponentId") + '" - Filter to tags - entry');
				console.log('Incoming filter passthru: ' + newFilters + ': Mode = ' + newMode);
				console.log('All known filters count: ' + allFilters.length);

				allFilters.forEach (function (F){
					aFilter = F.split(D1);
					
					if (aFilter[0] == src) {
						console.log('Re-setting EXISTING filter on ' + aFilter[0] + ' to ' + newFilters);
						allFilters[i] = src + D1 + newFilters;
						logged = true;
					}
					i += 1;
				});

				// If incoming filter comes from a newly encountered control (not in the 
				// list of existing filters), log it...
				if (logged == false) {
					console.log('Setting NEW filter on ' + src + ' to ' + newFilters);	
					allFilters.push(src + D1 + newFilters);
				}

				cmp.set("v.AllFilters", allFilters);
				console.log('Known filters adjusted count: ' + allFilters.length);


				// Set our active filters to the sum of logged and stored filters from all components
				newFilters = '';
				allFilters.forEach (function (F){
					aFilter = F.split(D1);
					if (aFilter[1] != '') {
						newFilters += aFilter[1] + ',';
					}
				});
				
				if (newFilters.length > 0) {
					newFilters = newFilters.substring(0, newFilters.length - 1);
				}
				newFilters += D1 + newMode;
				console.log('List tag filter will be set to: ' + newFilters);
				

	        	// Set required parameters then re-initialise
				cmp.set('v.ListingTagFilters', newFilters);
				cmp.set('v.ActionCode', 'GetTaggedItems');		
				cmp.set('v.CardConfig', 'Tagged Items');
				
				cmp.set('v.isInitialised', false);
				helper.initialiseList(cmp, event, helper);
	        }
        }

    },
    
    
    // Locate UI elements (e.g., listing rows) that represent "selected" records and visually mark them
    markSelections : function (cmp, event, helper) {
    	
		// Re-mark any selected rows (e.g., after a search that included them)
		try {
			var LSelections = cmp.get("v.ListingSelections");
			var LI;
	
			LSelections.forEach(function(v) {
				LI = document.getElementById('LINarrow_' + v);
				$A.util.addClass(LI, 'IsSelected');
				LI = document.getElementById('LIWide_' + v);
				$A.util.addClass(LI, 'IsSelected');
			})
            
			// If there are any selected rows, show this on any tools that respond to selections
			helper.markSelectionControlledTools(cmp);			
			            
		} catch (e) {}
		
    },
    
    
    doDragStart : function(cmp, event, helper) {
        var T = event.target.id;
        var D = cmp.get("v.Delimiter") || '|'; // fallback if not set
        var dat;
        var recordId;
        
        event.dataTransfer.dropEffect = "move";
        
        // Case 1: Delimiter-based format (e.g., a0B123|HelpCallout|Params)
        if (T && T.includes(D)) {
            var parms = T.split(D);
            recordId = parms[0]; // first part is record ID
        }
        // Case 2: Underscore-prefixed format (e.g., LIWide_a0B123)
        else if (T && T.includes('_')) {
            var parts = T.split('_');
            recordId = parts[parts.length - 1];
        }
        // Case 3: Plain record ID
            else {
                recordId = T;
            }
        
        // Compose drag data
        dat = 'ListRow' + D + recordId;
        event.dataTransfer.setData('text', dat);
        
        // Fire passthrough event
        var appEvent = $A.get("e.c:evtPassThrough");
        appEvent.setParams({
            "SourceComponent": cmp.get('v.ComponentId'),
            "ActionCode": 'DragStart',
            "Parameters": dat
        });
        appEvent.fire();
    },
    


	// Advise interested parties that a D&D operation has ended
	doDragEnd : function(cmp, event, helper) {
		
		// Raise a passthrough to clear drag data
		var appEvent = $A.get("e.c:evtPassThrough");
		appEvent.setParams({"SourceComponent" : cmp.get('v.ComponentId')});
		appEvent.setParams({"ActionCode": 'DragEnd'});
		appEvent.fire();
	},
	

	// Allow listing row drags
	drag : function (cmp, event, helper) {
	    event.preventDefault();
	},
    
    
	// For list just-in-time rendering, set the upper number of rows of data to render for the time being (delegated)
	setInitialRows: function(cmp, event, helper) {
		cmp.set("v.CurrentRows", cmp.get("v.InitialRows"));	
	},
	setCurrentRows: function(cmp, event, helper){
		helper.setCurrentRows(cmp, event, helper);
	},

	
})