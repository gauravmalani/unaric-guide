({  
    
    // Load QAM content (delegated) if settings require this on load
    Init : function(cmp, event, helper) {
    
    	// Respond to starts automatically setting    
    	if (cmp.get("v.StartAutomatically") == true) {
    		cmp.set("v.renderLST", true);    		
    		helper.initialiseQAM(cmp, event, helper);
    	}
    	
    },
    
    
    // Re-set QAM position based on last user settings plus set up internationalisations
    doneRendering : function (cmp, event, helper) {
        
        // Do this only once per page visit
        if (cmp.get("v.isInitialised") == false) {

			// Set some default internationalisations
            var QIs = [];
            QIs.push("Expand Help Quick Access Menu...");
            QIs.push("Collapse Help Quick Access Menu...");
            QIs.push("The Help Index has not been configured for this page...");


			// Find current QAM handle centre-line position and move waiting spinner accordingly
			if (cmp.get("v.renderSPN") == true) {
				var QH = cmp.find("QAMH").getElement();
				var QS = cmp.find("QAMSpinnerContainer").getElement();
	
				if (QH + '' != 'null') {
					var QAMPos = QH.offsetTop + 21.0;
					QS.style.top = QAMPos + 'px';
				}
			}
			
			
	        // Only continue to set QAM handle position if we auto-start: if we're just in time,
	        // we don't want our position to change as user opens QAM!
	        if (cmp.get("v.StartAutomatically") == true) {
	        
	        	try {
		            var Q = cmp.find("QAMComponent");			// REM - this is the LIST sub-component
		            var PS = Q.get("v.PersonalisationSettings");
		            var x = Q.get("v.Internationalisations");
		            var i;
		            
		            // Set QAM to personalised position
		            if (PS + '' != '') {
		                for (i=0; i<PS.length; i++) {
		                    if (PS[i].iahelp__HelpInteractionType__c === 'QAM Drag') {
		                    	try{
		                    		$('#QAM').animate({
		                    			top: PS[i].iahelp__Description__c
		                    		});
		                    	} catch (e) {}                    
		
		                    }
		                }
		                cmp.set("v.isInitialised", true);
		            }
		
		
		            // Update internationalisation with correct translations now they're available
		            for (i=0; i < x.length; i++) {
		            	if (x[i].Name === 'TipQAMHandleOpen') {
		            		QIs[0] = x[i].Value;
		            	}
		            	if (x[i].Name === 'TipQAMHandleClose') {
		            		QIs[1] = x[i].Value;
		            	}
		            	if (x[i].Name === 'MessageHelpIndexRootNotSpecified') {
		            		QIs[2] = x[i].Value;
		            	}
		            }
		                        
	        	} catch (e) {}
	        	
	        } else {
	        	cmp.set("v.isInitialised", true);
	        	
	        }	// End if starting automatically

	        // Set internationalisations required in mark up (as opposed to scripted translation calls)
            cmp.set("v.QAMInternationalisations", QIs);
            cmp.set("v.QAMHandleTip", cmp.get("v.QAMInternationalisations")[0]);
	        
        }	// End if already initialised

    },
    
    
    // Show / hide QAM on handle click
	toggleQAM : function(cmp, event, helper) {
	
		var SPN;			// QAM-wide spinner containing DIV
		var QH;				// The QAM handle
		var QAMPos;			// QAM Handle's top co-ordinate
		var contLST;		// Containing DIV - List
		var contUT1;		// Containing DIV - Utility 1
		var contSTK;		// Containing DIV - Sticky
		var contRLV;		// Containing DIV - RL Viewer		
		var activeComp;		// The sub-component of the QAM (list, Utility 1 etc) currently in use
		 

		// Show QAM-wide waiting spinner in case it's needed:
		// Whilst we unhide its DIV, the DIV itself will be non-rendered where
		// underlying components and their individual spinners are available
		SPN = cmp.find("QAMSpinnerContainer");
		$A.util.removeClass(SPN, 'slds-hide');
		

		// If we have yet to render any components (which can only mean we're not 
		// starting automatically, as this would have made at least one item load)
		// we need to initialise
		
		if (cmp.get("v.renderLST") == false) {
			cmp.set("v.renderLST", "true");	
			helper.initialiseQAM(cmp, event, helper);

			// Adjust for QAM label if required
			if (cmp.get("v.QAMHandleLabel") != '') {
				contLST = cmp.find("QAMListContainer");
				$A.util.addClass(contLST, 'QAMWithLabel');
			}
				
		} else {				
			// On any click, allow all components to initialise
			cmp.set("v.renderLST", true);
			cmp.set("v.renderSTK", true);
			cmp.set("v.renderRLV", true);
			cmp.set("v.renderUT1", true);
	
	
		    // Find current QAM handle centre-line position and move component containers accordingly
			try {
				QH = cmp.find("QAMH").getElement();
				QAMPos = QH.offsetTop + 21.0;
				
				contLST = cmp.find("QAMListContainer");
				contUT1 = cmp.find("QAMUT1Container");
				contSTK = cmp.find("QAMStickyContainer");
				contRLV = cmp.find("QAMRLVContainer");
				
				contLST.getElement().style.top = QAMPos + 'px';
				contUT1.getElement().style.top = QAMPos + 'px';
				contSTK.getElement().style.top = QAMPos + 'px';
				contRLV.getElement().style.top = QAMPos + 'px';

				// Adjust for QAM label if required
				if (cmp.get("v.QAMHandleLabel") != '') {
				
					$A.util.addClass(contLST, 'QAMWithLabel');
					$A.util.addClass(contStickies, 'QAMWithLabel');
					$A.util.addClass(contRLV, 'QAMWithLabel');
					$A.util.addClass(contUT1, 'QAMWithLabel');
					
				}
				
			} catch (e) {}
			
	
			// Toggle visibility of the component currently in play on the QAM
	        activeComp = cmp.find(cmp.get("v.theActiveComponent"));
	        $A.util.toggleClass(activeComp, 'slds-hide');
	        

	        // Set QAM Handle title based on open / closed state
	        if ($A.util.hasClass(activeComp, 'slds-hide')) {
	            cmp.set("v.QAMHandleTip", cmp.get("v.QAMInternationalisations")[0]);
	        } else {
	            cmp.set("v.QAMHandleTip", cmp.get("v.QAMInternationalisations")[1]);
	        }

		}	// End if NO component had been initialised
        
	},
	
	
	// Respond to the "select" event raised by lists (if we're listening to the source component)
    selectRecord : function (cmp, event, helper) {
        
        // For this event for the QAM, we listen ONLY to our own list
        var listensTo = 'theQAM';
        var theSource = event.getParam("SourceComponent");
        var theRecord = event.getParam("RecordId");
        
        // We also only want to respond when QAM component has be told to "in-source" certain lists
        // into itself, as opposed to using external, full-screen modals
        
        try {
	        var overrideCallouts = cmp.find("QAMComponent").get("v.CalloutOptionSelectiveOverride");
	        
	        // We also only want to respond to certain list TYPES at this stage
	        var listAct = cmp.find("QAMComponent").get("v.ActionCode");
	        
	        if (theSource == listensTo 
			        	&& overrideCallouts == true
			        	&& listAct == 'ReadingLists') {


				// In these cases, we need to ensure RL viewer is in play and set its member data
				cmp.set("v.renderRLV", true);

	                        
	            var QAM = cmp.find('QAMListContainer');
	            var RLVC = cmp.find('QAMRLVContainer');
	            var RLV = cmp.find('QAMRLViewer');
	            
/*	            
	            // Prep the component with the context from our QAM
	            // Set the selected reading list by raising an event signed with the component ID  
	            // that our RL viewer component is hard-wired to listen for            
	            var appEvent = $A.get("e.c:selectTopic");
	            appEvent.setParams({"RecordId" : theRecord});
	            appEvent.setParams({"SourceComponent" : "theQAMRLVMaster"});
	            appEvent.fire();
*/

				// Use member data to set reading list directly, rather than via event
				RLV.set("v.HelpRecordId", theRecord);
				RLV.reInitialise();

	            
	            // Show the RL viewer and note the fact
	            $A.util.addClass(QAM, 'slds-hide');
	            $A.util.removeClass(RLVC, 'slds-hide');
	            cmp.set("v.theActiveComponent", "QAMRLVContainer");
	        }
	        
        } catch (e) {
        	// It may be that our list did not exist when select record event
        	// (fired by some other component) occurred 
        }
    },
    	
	
	// Respond to events from our constituent components 
	handlePassThroughs : function (cmp, event, helper) {
        
        var act = event.getParam("ActionCode");
        var parms = event.getParam("Parameters");
        var src = event.getParam("SourceComponent");
        
    	var Q = cmp.find("QAMComponent");
        var STC = cmp.find('QAMSticky');
        
        // Parse configuration tools for those to be "negotiated":
        // Note that we only accept tools from our own list (with the ID that we hard wire)
        // Also, only if we've been told to "show shortcuts" (negotiate tools)

        try {        
	        if (act === 'ComponentToolsProcessed' && src === Q.get('v.ComponentId') && cmp.get("v.NegotiateToolbars") === true) {
	        
	        	var negTs = [];								// Tools to negotiate into our QAM handle
	        	var hdrTs = Q.get("v.HeaderTools");			// Our QAM list control's un-modified Header tools
	        	var modHdrTs = [];							// Modified header tools - less negotiated items - to pass back to QAM
	        	var ellTs = Q.get("v.EllipsisTools");		// Our QAM list control's un-modified Ellipsis tools
	        	var modEllTs = [];							// Modified ellipsis tools - less negotiated items - to pass back to QAM
	        	var cmpList;
	        	var cmpStickies;
	        	var cmpRLV;
	        	var cmpUT1;
	        	
	        	cmp.set("v.QAMDelimiter", Q.get("v.Delimiter"));
	        	cmp.set("v.QAMToolContext", Q.get("v.ToolContext"));
	        	cmp.set("v.QAMCurrentRecordMetadata", Q.get("v.CurrentRecordMetadata"));
	        	
	        	hdrTs.forEach(function(T) {
	        		// Accept only tools that are at our negotiation level, or above
		        	if (T.iahelp__NegotiateToolbarLevel__c >= cmp.get("v.NegotiatedLevel")) {
		        		negTs.push(T);
		        	} else {
		        		modHdrTs.push(T);
		        	}
	        	});
	
	        	ellTs.forEach(function(T) {
	        		// Accept only tools that are at our negotiation level, or above
		        	if (T.iahelp__NegotiateToolbarLevel__c >= cmp.get("v.NegotiatedLevel")) {
		        		negTs.push(T);
		        	} else {
		        		modEllTs.push(T);
		        	}
	        	});
	        	
	        	
	        	// Set our negotiated tools, then re-set modified (minus negotiated) tools in our QAM
	        	cmp.set("v.NegotiatedTools", negTs);
	        	Q.set("v.EllipsisTools", modEllTs);        	
	        	Q.set("v.HeaderTools", modHdrTs);        	
	        	
	        	// If there are any negotiated tools, re-style QAM body to allow space for them
	        	if (negTs.length > 0) {
	        		cmpList = cmp.find('QAMListContainer');
	        		cmpStickies = cmp.find('QAMStickyContainer');
	        		cmpRLV = cmp.find('QAMRLVContainer');
	        		cmpUT1 = cmp.find('QAMUT1Container');
	        		
	        		$A.util.addClass(cmpList, 'QAMWithNegTools');
	        		$A.util.addClass(cmpStickies, 'QAMWithNegTools');
	        		$A.util.addClass(cmpRLV, 'QAMWithNegTools');
	        		$A.util.addClass(cmpUT1, 'QAMWithNegTools');
	        	}
	        }
		} catch (e) {}       
        
                
    	// Make QAM - handle and body - draggable
        if (act === 'ScriptsAvailable') {
        
        	try {
	            $('#QAM').draggable({
	                axis: "y",
	                opacity : 0.5,
	                distance: 10,
	                scrollSensitivity: 100,
	                scrollSpeed: 10,
	                containment : [0,90,,600],
	                
					drag: function(){
						event.stopPropagation();
						$('#QAM').css('cursor','move');
					},
					
					stop: function(){					
					    // Reset cursor on stop and log QAM position
						$('#QAM').css('cursor','pointer');
						helper.logQAMPos(cmp, $('#QAM').css('top'));
					}
	            
	            });

        	} catch (e) {}
        }
        

		// Show our Utility1 'Help Index' component - delegated to helper        
		if (act === 'HelpIndex') {
			helper.cueHelpIndex(cmp, event, helper);
		}        
		
		
		// Return from Utility1 to our 'standard' QAM listings
		if (act === 'ReturnToHelpListings') {
		
		    var QAM = cmp.find('QAMListContainer');
		    var UT1 = cmp.find('QAMUT1Container');
		
		    $A.util.addClass(UT1, 'slds-hide');
		    $A.util.removeClass(QAM, 'slds-hide');
		    
		    cmp.set("v.theActiveComponent", "QAMListContainer"); 

			if (Q.get("v.GlobalSettings") + '' == 'undefined' || Q.get("v.GlobalSettings") + '' == 'null'){
				Q.reInitialise();
			}
		    
		    // Log the relevant list type as having been requested
			helper.logListType(cmp, event, helper, Q.get("v.CardConfig"));       
		}        

        
        // Show new sticky detail control (hiding our list component)
        if (act === 'NewSticky' || act == 'Sticky') {
        
			// If stickies component is not defined, make sure we've 'enabled' it:
			// to give it time to spin up, switch it on then return (a second click
			// will be required to complete this action). This issue arises if we've only
			// toggled the QAM open once: see toggleQAM where we attempt to lazy load 
			// components for performance reasons...
			if (STC + '' == 'undefined') {
				cmp.set("v.renderSTK", true);
				return;
			}

        
            var QAM = cmp.find('QAMListContainer');
            var STK = cmp.find('QAMStickyContainer');
            var lst = cmp.find('QAMComponent');
            var LIs = lst.get("v.ListingItems");
            var ListContext = lst.get("v.IHContext");
            
           
            // Prep the sticky component with the required record context (sticky to obtain)
            if (act == 'Sticky') {
            	// Pass through parameters are in the form:
            	// [Listing ID] [Delimiter] [Context]
            	// Listing in this case is an interaction, and the context is its context - i.e., the one we need
            	var Ps = parms.split('^');
	            STC.set("v.recordId", Ps[1]);
	                      
            } else {
            	// For the "new" action, sticky context should be our list's current context
            	STC.set("v.recordId", ListContext);
            }
            
            // Get the label of the relevant listing item to use as a sticky title
            ListContext = STC.get("v.recordId");
            LIs.forEach(function(v) {
            	if (v.Parameters == ListContext) {
		            STC.set("v.StickyTitle", v.Label);
            	}
            });
            
            STC.set("v.isInitialised", false);  
            
            // Swap visibility of our list and sticky component
            $A.util.addClass(QAM, 'slds-hide');
            $A.util.removeClass(STK, 'slds-hide');
            
            cmp.set("v.theActiveComponent", "QAMStickyContainer");
        }
        
        
        // Dialogue closure request - Only respond for our sticky editing dialogue
        if (act === 'DialogueRequestClose') {
        
            if (event.getParam("Parameters") == 'QAMStickyContainer') {

            	//alert('QAM - DialogueRequestClose - for our sticky container: continuing');        
                
                var QAM = cmp.find('QAMListContainer');
                var STK = cmp.find('QAMStickyContainer');
                
                $A.util.addClass(STK, 'slds-hide');
                $A.util.removeClass(QAM, 'slds-hide');
                
                cmp.set("v.theActiveComponent", "QAMListContainer");                
            }
        }
        
        
        // Re-get current QAM component listing: we expect this only from our notes component
		if (act === 'RefreshCurrentList' && src === STC.get('v.ComponentId')) {
			var theQAM = cmp.find("QAMComponent");
		    theQAM.reInitialise();
			return;
		}
        
        
        // Return to RL list from viewer
        if (act === 'ReturnToRLs') {
        	
        	// ISSUE: we should really filter here to ensure we only listen to "our" ListenTo component - not easy here... 
            var QAM = cmp.find('QAMListContainer');
            var RLVC = cmp.find('QAMRLVContainer');
            
            $A.util.addClass(RLVC, 'slds-hide');
            $A.util.removeClass(QAM, 'slds-hide');
            
            cmp.set("v.theActiveComponent", "QAMListContainer");        	
        }
        
	},
	
	
	// Raise pass through events for the relevant control when a negotiated tool is clicked
	menuItemClick : function (cmp, event, helper) {
		
        // Click "message" (the id of the clickable) is in the form:
        // [Menu (tool) type] [Delimiter] [Action code] [Delimiter] [Display Order] [Delimiter] [Toggle Next #]
        // This is passed straight back as parameters
        
        // We set a source for message filtering - but also the Target component that (we believe) requested 
        // the negotiation: member data on this control (not cmp / ourselves) may be needed to process the click... 
		
		var src = 'negQAM';
		var parms = event.currentTarget.id;
		var Q = cmp.find("QAMComponent");
		
		// Header tools only for now - so it's a menu item click...
        var appEvent = $A.get("e.c:evtNegMenuClick");
        
        appEvent.setParams({"SourceComponent": src});
        appEvent.setParams({"Parameters": parms});
        appEvent.setParams({"Target": Q});
        
        appEvent.fire();
		
	},
	
})