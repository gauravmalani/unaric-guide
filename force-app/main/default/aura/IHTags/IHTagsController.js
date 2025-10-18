({

	
	// Get the cloud of tags associated with our root node member data
	init: function(cmp, event, helper) {
	
		// Check for an override selected topic (HTID) in URL        
		var HTID = helper.getURLParm(cmp, 'iahelp__HTID');
		if (HTID != '' && cmp.get("v.CheckURLParams") == true) {
			cmp.set("v.HelpRecordId", HTID);
			cmp.set("v.IHContext", HTID);
			
			// Set latch that says we've considered URL (on page load and not thereafter)
		    cmp.set("v.CheckURLParams", false);
		}
		  
		if (cmp.get("v.isInitialised") == false) {
			helper.initialise(cmp, event, helper);
		}
    },
    
    
    // Force re-build (not full re-init / URL checks) if initialisation member
    // is amended to request this
    reInitialise: function (cmp, event, helper) {
		if (cmp.get("v.isInitialised") + '' == 'false') {
			helper.initialise(cmp, event, helper);
		}
    },
    
    
    // Respond to record selected event from control to which we're listening
    selectRecord : function (cmp, event, helper) {
        
        // In our case, a change in record implies we need to show tags set on that record - if required
        // (this only applies in "Associate" mode)
        var theRecord = event.getParam("RecordId");
               
        // Only respond to events that do not emanate from ourselves / do
        // emanate from the  "desired" master list(s) we wish to tie to
        if (helper.eventBeingListenedTo(cmp, event) == true) {

            // In these cases, we're changing topic (server call)
            // so show our "waiting" cues and allow update...
            cmp.set("v.HelpRecordId", theRecord);
            cmp.set("v.IHContext", theRecord);
            
            
// We are setting AuthorConfigLatch value to true, when contextualizing to a record and Author config may be in play.
// This is to prevent incorrect help record being set at the point we add any new tag relationship:
// this needs to be between context topic and clicked tag: author configs setting pool could result 
// in attempt to relate pool to clicked tag...
cmp.set("v.AuthorConfigLatch", true);
            
            helper.initialise(cmp, event, helper);
            
        }
    },
    
    
    // Respond to clicks on our tag lozenges
    tagClick : function (cmp, event, helper) {
    	
		var theClickedTag = event.target.id;
		var badge = document.getElementById(cmp.getGlobalId() + 'badge_' + theClickedTag);
        var theTags = cmp.get("v.SelectedTags");
		var theTagsNew = [];

   	
    	// Action to take depends on mode:
    	if (cmp.get("v.CardConfig") == 'Search') {

    		// If mode is search, on tag click toggle selected style...
    		$A.util.toggleClass(badge, 'Tagged');
    		$A.util.toggleClass(badge, 'UnTagged');
    		
    		
    		// ... note selections ...
    		if ($A.util.hasClass(badge, 'Tagged')) {
		        // Add the just-clicked tag to the set of our tags
    			theTagsNew = theTags;
		        theTagsNew.push(theClickedTag);
		        
    		} else {
    			// Remove the just clicked tag from our set
    			theTags.forEach(function(T) {
    				if (T != theClickedTag) {
    					theTagsNew.push(T);
    				}
    			});
    		}
    		cmp.set("v.SelectedTags", theTagsNew);
    		
			
	    	// ... then cue a search in response
	    	helper.cueSearch(cmp, event, helper);
    		    		
    		    		
    	} else {
    		// Get the current state of this tag from its badge    		
    		var toBeTagged = $A.util.hasClass(badge, 'UnTagged');
    		helper.toggleTag(cmp, event, helper, theClickedTag, toBeTagged);
    	}
    },
    
    
    // Handle lozenge delete icon clicks
    tagDeleteClick : function (cmp, event, helper) {
    	    	
    	var theClickedTag = event.target.id;
    	var theTopicId = theClickedTag.replace(cmp.getGlobalId() + 'badgeRemover_', '');    
    	var deleteTopic;	
    	var deletePool;
    	var LIs = cmp.get("v.ListingItems");
    	
    	// Offer a back out
    	if (confirm(helper.Internationalise(cmp, 'MessageDeleteWarning'))) {
    	
    		// Check whether user wants to delete help topic as well as member relationship
    		deleteTopic = prompt(helper.Internationalise(cmp, 'MessageDeleteMemberTopic'), 'N');
    	    		
    		if (deleteTopic == 'Y') {
    			deleteTopic = true;
    		} else {
    			deleteTopic = false;
    		}
    	
    		// If deleting the last member, offer to delete the pool topic
    		if (LIs.length == 1) {
    			deletePool = prompt(helper.Internationalise(cmp, 'MessageDeleteTagPoolTopic'), 'N');
    	    		
	    		if (deletePool == 'Y') {
	    			deletePool = true;
	    		} else {
	    			deletePool = false;
	    		}
    		}
    		
	    	helper.showSpinner(cmp);
	    	
			var act = cmp.get("c.removeMemberTag");
	        act.setParams({ 
				"root" : cmp.get("v.RootNode"),
				"member" : theTopicId,
				"deleteMember" : deleteTopic,
				"deleteRoot" : deletePool,
				"ToolContext" : cmp.get("v.ToolContext")
	        });                       
	            
	        // Add callback to process returned results
	        act.setCallback(helper, function (response, cmp){
	        	helper.processTools(response, cmp);        
	        }); 
	    
	        $A.enqueueAction(act);
    	}
    },
    
    
    // Respond to pass-throughs
    handlePassThroughs : function (cmp, event, helper) {
    
        var act = event.getParam("ActionCode");
        var parms = event.getParam("Parameters");
        var src = event.getParam("SourceComponent");
        
        // For certain events, only listen to our own messages
        if (helper.eventIsOurOwn(cmp, event) || src == cmp.get("v.ComponentId") + '_DLG') {
        	
        	// Go to portal focussed on the "root" tag topic set for this control
	        if (act === 'ViewTags') {
				var CRoot = cmp.get('v.CommunityRoot');

				// If root is 'null', this can be ignored in most cases
				if (CRoot + '' == 'null') {CRoot = '';}
				if (CRoot != '') {CRoot = '/' + CRoot;}        

				var HTID = cmp.get("v.RootNode");
            	var PortalPage = cmp.get("v.PortalPage");
				
                window.open(CRoot + "/apex/iahelp__" + PortalPage + "?HTID=" + HTID);
	            return;
	        }  
	        

			// Add a new pool with current topic as founder member
			if (act == 'AddTagPool') {
	
	        	// Allowed only where component settings allow this (regardless of tool appearance)
	        	if (cmp.get("v.AllowCloudEditing") == false) {
	        		alert(helper.Internationalise(cmp, 'MessageOptionNotAllowed'));
	        		return;
	        	}

	        	// Only continue if a "current" topic has been identified
	        	if (cmp.get("v.HelpRecordId") == '') {
	        		alert(helper.Internationalise(cmp, 'MessageAddMemberUnavailable'));
	        		return;
	        	}
	        	
	        	
	        	// Obtain the desired name for a new pool topic	        	
	        	var poolName = prompt(helper.Internationalise(cmp, 'ToolLabelAddTagPool') + ' - ' + helper.Internationalise(cmp, 'AdviceLabelListingName'), '');	
				if (poolName == '' || poolName + '' == 'null') {return;}  


	        	helper.showSpinner(cmp, helper);
	        		        	
		        var act = cmp.get("c.createTagPool"); 
		        act.setParams({ 
		        	"PoolName" : poolName,
					"PoolMembers" : cmp.get("v.HelpRecordId"),
		        });                       
		                
		        // Add callback to process returned results
		        act.setCallback(helper, function (response, cmp){

					// Need to swap to the new pool here:
					// Return value if successful should be ID of the new pool topic
					if (response.getState() == 'SUCCESS') {
						cmp.set("v.RootNode", response.getReturnValue());
						helper.initialise(cmp, event, helper);
						
					} else {
						cmp.set("v.Diags", "ERR! " + response.getReturnValue());
					}
				});

		        $A.enqueueAction(act);
			}	
			        
	        
	        // Add current topic to tag pool
	        if (act == 'AddMemberTag') {

	        	// Allowed only where component settings allow this (regardless of tool appearance)
	        	if (cmp.get("v.AllowCloudEditing") == false) {
	        		alert(helper.Internationalise(cmp, 'MessageOptionNotAllowed'));
	        		return;
	        	}
	        	
	        	// Only continue if a "current" topic has been identified
	        	if (cmp.get("v.HelpRecordId") == '') {
	        		alert(helper.Internationalise(cmp, 'MessageAddMemberUnavailable'));
	        		return;
	        	}
	        	
	        	// Offer a back-out
        		if (confirm(helper.Internationalise(cmp, 'MessageAddMemberTag') + ' : ' + cmp.get("v.Title")) == false) {
                    return;
                }
	        	
	        	helper.showSpinner(cmp, helper);
	        		        	
		        var act = cmp.get("c.addMemberTag"); 
		        act.setParams({ 
		        	"root" : cmp.get("v.RootNode"),
					"member" : cmp.get("v.HelpRecordId"),
					"ToolContext" : cmp.get("v.ToolContext")
		        });                       
		                
		        // Add callback to process returned results
		        act.setCallback(helper, function (response, cmp){
		        	helper.processTools(response, cmp); 
				});

		        $A.enqueueAction(act);

	        } 
	        
	        // Cue selection of the tag pool to view [1 of 2]: show dialogue of available pools
	        if (act == 'SelectTagPool') {
	        
	        	// Allowed only where component settings allow this (regardless of tool appearance)
	        	if (cmp.get("v.AllowCloudSelection") == false) {
	        		alert(helper.Internationalise(cmp, 'MessageOptionNotAllowed'));
	        		return;
	        	}
	        	
	        	// Prompt user for pool
	        	var act = cmp.get("c.getTagPools"); 
	                
		        // Add callback to process returned results
		        act.setCallback(this, function (response, cmp){
			        
		        	var ret = response.getReturnValue();
		        	var obj;
		        	
		        	// This should be in the form of listing items JSON...
		            try {
						obj = JSON.parse(response.getReturnValue());
						
		            } catch (e) {
		                cmp.set("v.Diags", "IHList - Select Tag Pool - Error parsing the following return value (" + e + "): " + response.getReturnValue());
		                return;		                
		            }
		            
		            // If we get listing items, display them...
		            var src = 'c:IHList';
	                var aMap = {
	            		"ComponentId": cmp.get("v.ComponentId") + '_DLG',
	                    "CardConfig": "ToolsOnly",
	                    "SuppressHeader": "true",
	                    "SuppressFooter": "true",
	                    "IHContext" : "",
	                    "ToolContext" : "",
	                    "Height" : -1,	                    
	                    "ListingItems" : obj
	                };

                	helper.doDialogue('SelectTagPool', 'LUX', src, aMap, 410, false, false, true, cmp, true);
            	});

		        $A.enqueueAction(act);
	        }   
	        
	        
	        // Cue selection of the tag pool to view [2 of 2]: respond to selection of desired pool from list dialogue
	        if (act == 'TagPoolSelected') {
	        	// This should have come to us via a listing row click -> listing click pass through.
	        	// Parameters are therefore:
	        	// Listing ID [Delimiter] Parameters
	        	var Ps = parms.split('^');
	        	
        		// Set our tag pool to the one chosen
        		cmp.set("v.RootNode", Ps[0]);
        		helper.initialise(cmp, event, helper);	        	
	        } 
	        
        }        
        
        // For certain events, listen only if we're supposed to be listening
        if (helper.eventBeingListenedTo(cmp, event)) {
        
        	// A new tag pool has been created (e.g., via the 'saveSelectedKeywords' list action)
        	if (act == 'TagPoolCreated') {

        		// Set our tag pool to the newly created one
        		cmp.set("v.RootNode", parms);
        		helper.initialise(cmp, event, helper);
        	}
        	
        	
			// Cue selection of the tag pool to view
			if (act == 'TagPoolSelected') {
			
				// Parameters are similar to list tag click:
				// Clicked item / tag ID [Delimiter] Parent
				// In this case, clicked item is the desired pool, 'parent' is irrelevant / ignored
				var Ps = parms.split('^');
				
				// Set our tag pool to the one chosen
				cmp.set("v.RootNode", Ps[0]);
			
				helper.initialise(cmp, event, helper);	        	
			} 
			
			
			// Toggle a tag on / off
			if (act == 'ToggleTag') {
			
				// Clicked item / tag ID [Delimiter] Parent (pool ID)
				var Ps = parms.split('^');
				var thePool = Ps[1];
				var theClickedTag = Ps[0];
				var badge = document.getElementById(cmp.getGlobalId() + 'badge_' + theClickedTag);
				var toBeTagged = $A.util.hasClass(badge, 'UnTagged');
			
			    // Ensure correct pool is selected before attempting a tag toggle
			    if (thePool != cmp.get("v.RootNode")) {
			        
			        // If root is not that of the selected tag, change
			        // to the tag's pool, leaving a note first to toggle tag on arrival
			        // Set our tag pool to the one chosen
			        cmp.set("v.RootNode", thePool);
			        cmp.set("v.OnArrivalToggleNode", theClickedTag);
			        helper.initialise(cmp, event, helper);	        	
			        
			    } else { 
			        helper.toggleTag(cmp, event, helper, theClickedTag, toBeTagged);        	
			    } 
				
			} 
			       	
        }

    },
    
    
    // Respond to change in filtering mode
    selectTagMode : function (cmp, event, helper) {
    	
    	// Note tag filtering mode
    	cmp.set("v.TagMode", event.getSource().get("v.text"));
    	
    	// Cue a search in response
    	helper.cueSearch(cmp, event, helper);
    },
    
    
	// Set the data of a tag D&D operation 
	doDragStart : function(cmp, event, helper) {
	    var T = event.target.id;
	    var D = cmp.get("v.Delimiter");
		event.dataTransfer.dropEffect = "move";
		
		// Set data to identify that a tag lozenge is being dragged, plus include record ID:
		event.dataTransfer.setData('text', 'Tag' + D + T);
	},

    
	// Show whether or not drop will be allowed
	doDragOver : function (cmp, event, helper) {
	
		if (helper.DDAllowed(cmp, event) == true) {
		    event.preventDefault();
	
		    var T = cmp.find('theTagPoolContainer');
		    
		    if (helper.dropAllowed(cmp, event) == true) {
			    $A.util.addClass(T, 'DropTargetActive');
		    } else {
			    $A.util.addClass(T, 'DropTargetUnavailable');
		    }
		}
	},


	// Remove any drag over style hints
	doDragLeave : function (cmp, event, helper) {
	    event.preventDefault();
	    var T = event.target;
	    $A.util.removeClass(T, 'DropTargetActive');
	    $A.util.removeClass(T, 'DropTargetUnavailable');
	},    
    
    
	// Take action when drop occurs
	doDrop : function (cmp, event, helper) {
	
		try {
		    event.preventDefault();
		    
		    var theContainer = cmp.find('theTagPoolContainer');
		    var dat = event.dataTransfer.getData("text");
		    var D1 = cmp.get("v.Delimiter");    
		    var parms = [];
		
		    parms = dat.split(D1);
		    
		    // Remove visual cues
		    $A.util.removeClass(theContainer, 'DropTargetActive');
		    $A.util.removeClass(theContainer, 'DropTargetUnavailable');

		    
		    // Having removed visual clues, take no further action unless drop ops are allowed
		    if (helper.dropAllowed(cmp, event) == false) {
		    	return;
		    }
		    
		    // Respond according to request operation
		    
		    switch (parms[0]) {   
		    	case 'Tag' :
				case 'ListRow' :	
				case 'DetailTitle' :
			        // We delegate responses to tool clicks to our parent tree via a pass through:
			        // In this case, we need to set context help topic to the dragegd  item
			        cmp.set("v.HelpRecordId", parms[1]);
			        
			        var appEvent = $A.get("e.c:evtPassThrough");
			        appEvent.setParams({"SourceComponent" : cmp.get('v.ComponentId')});
			        appEvent.setParams({"ActionCode": 'AddMemberTag'});			        
			        appEvent.setParams({"Parameters": ""});
			        appEvent.fire();
					
					break;
		    }
	
		
		} catch (e){
			console.log('IHTags - drop error: ' + e);
		}
	    
	},


})