({


	// Get the largely invariant, cacheable information used on cards (delegated):
	// then cue initialisation
	init : function(cmp, event, helper) {
	
		// Set up our detail designer: setting helper reference to allow internationalisation access    
		try {
			var DD = cmp.find("theDesigner");
			DD.set("v.ParentControlHelper", helper);
            cmp.set("v.DesignerCmp", DD) ;
			
		} catch (e){
			console.log('IHDetail initialisation - error configuring detail designer sub-component: ' + e);
		}
		    
    	// Differentiate topic and non-topic (autoform) tool contexts - unless default has been requested
    	if (cmp.get("v.ToolContext") == '[DEFAULT]') {
			cmp.set("v.ToolContextAF", cmp.get("v.ToolContext"));
    	} else {
			cmp.set("v.ToolContextAF", cmp.get("v.ToolContext") + '_Autoform');
    	} 
    	
		// Note whether or not the result is a custom layout being in play:
		// Although we can derive this by looking at layout info, it's easier in some circumstances
		// (eg conditionally visible tools) to have a boolean
		cmp.set("v.IsCustomLayout", cmp.get("v.LayoutInfo") + '' != '' && cmp.get("v.LayoutInfo") + '' != 'undefined');
	
		helper.initialiseGlobals(cmp, event, helper);
	},
    
    
    // Prepare editing controls and obtain additional record info where required on mouse over of details (delegated)
    initialiseEditingControls : function(cmp, event, helper) {
        
        // Make server call to obtain keyword parsed topic description, votes etc.
        //if(cmp.get("v.CachedRecordSource")!=='' && cmp.get("v.MouseOverDone")!=true){
        if(cmp.get("v.MouseOverDone") != true){
            helper.getAdditionalInfo(cmp, event, helper);
        }
		// Only obtain drop down values etc if not already done
		if (cmp.get("v.TemplatesC").length == 0) {
    		helper.initialiseEditingControls(cmp, event);
    	}
   	
		// Also, if a layout is in play, we need to nudge it back into existence!
		var DD = cmp.find("theDesigner");
		try {
			if (cmp.get("v.IsCustomLayout") == true && DD.get("v.Initialised") == false) {	
				DD.reInitialise();
			}
		} catch (e) {
			// Designer not available / in play - skip...
		}
    	
    },
    
    
	// On change of record, check media sizes (delegated) plus re-initialise any lightning templates if required (delegated)
	CurrentRecordChange : function (cmp, event, helper) {
	
		// As this seems to fire any time a FIELD is edited, as opposed to the member data / record as a whole
		// changing, only act here if we're in view mode...
		if (cmp.get("v.DataMode") == 'View') {
			helper.setMediaSizes(cmp, event);
			helper.initialiseTemplateComponents(cmp, event, helper);
			
			// Any time our current record member changes, parse any description
			// so it can be safely displayed unescaped:
			// NB: this only applies to help topics, as non-topics are not displayed unescaped 
			// (they're presented on an Autoform)
			
			if (cmp.get("v.IsHelpTopic") == true) {
				var D = helper.getSafeHTML(cmp.get("v.CurrentRecord").iahelp__Description__c);
				cmp.get("v.CurrentRecord").iahelp__Description__c = D;
			}
		}
				
	},    


	// On change of custom layout information, note whether or not the result is a custom layout being in play
	LayoutInfoChange : function (cmp, event, helper) {
		cmp.set("v.IsCustomLayout", cmp.get("v.LayoutInfo") + '' != '' && cmp.get("v.LayoutInfo") + '' != 'undefined');
	},


	// On change of topic / non-topic status, adjust our tooling, so as not to show multiple tool bars
	ObjectTypeChange : function (cmp, event, helper) {
		
		// If in non-topic mode, we'll show our autoform, which has its own tools,
		// so we should suppress certain of our own...
		cmp.set("v.SuppressBodyTools", cmp.get("v.IsNonTopic"));
	},
	

	// Respond to the "select" event (if we're listening to the source component)
    selectRecord : function (cmp, event, helper) {
                
        var theRecord = event.getParam("RecordId");
        var theOldRecord = cmp.get("v.HelpRecordId");
        var src = event.getParam("SourceComponent");        
        var doGetObjectInfo = false;
        var keyTypes = cmp.get("v.GlobalSettings.iahelp__SFObjectIds__c");
               
        console.log('IHDetail selectRecord - entry: Component Id="' + cmp.get("v.ComponentId") + '" Source ="' + src + '" Record = "' + theRecord + '" Old Record = "' + theOldRecord + '"');

		// ONLY ACT WITH A 'PROPER' RECORD:
		// Certain components (e.g., trees) may issue record selects / root changes that lead us here
		// with delimited data that only they understand. Attempts to process these messages will fail, 
		// so bail here if we encounter things that do not seem to be a record ID
		var D1 = '^';
		if (theRecord + '' == 'null') {
			console.log('IHDetail selectRecord: record ID is null - bailing...');
			return;
		}
		if (theRecord.indexOf(D1) != -1) {
			console.log('IHDetail selectRecord: illegal record ID encountered (' + theRecord + ') - bailing...');
			return;
		}
        
        
        // Only respond to events that do not emanate from ourselves / do
        // emanate from components we wish to tie to
        // 1.42+ also, respond in the same way in the case of any specialised sub-component,
        // whose component identifier will have been hard wired (see helper.initialiseTemplateComponents) unless template creator specifies otherwise...
        if (helper.eventBeingListenedTo(cmp, event) == true || event.getParam("SourceComponent") == cmp.get("v.ComponentId") + '_SpecialComp') {
        	
        	// If the record in the message we receive does not represent a change, bail / take no further action
			if (theRecord == theOldRecord) {

				var typ = cmp.get("v.IsHelpTopic") == true ? 'Topic' : 'Non-topic';
				
				console.log('IHDetail selectRecord - record appears unchanged - checking topic / non-topic status...');
				
				if ((cmp.get("v.IsHelpTopic") == true && cmp.get("v.CurrentRecord") + '' != 'null') 
							|| (cmp.get("v.IsNonTopic") == true && cmp.get("v.HelpRecordId") + '' != 'null')) {

					// Only back out if record is unchanged - and we're definitely already displaying it!
					// If current conditions match those of the "no data" message, we still need to act
					// to check whether there is something we've yet to display...

					console.log('IHDetail selectRecord - type unchanged (' + typ + ') - returning');
					return;
					
				} else {
					console.log('IHDetail selectRecord - last known type (' + typ + ') requires further processing - continuing...');
				}		
			}
			

            // Offer back-out if dirty
            if (cmp.get('v.isDirty') == true) {
        		if (confirm(helper.Internationalise(cmp, '[QAMMessageDirtyWarning]')) == false) {
                    return;
                }
            }


			// If we have a set of cached records, 'navigate' within that - assuming the
			// source of record selection is the 'cache source' set for this component
			if (src == cmp.get("v.CachedRecordSource")) {
				
				// Set a latch allowing additional topic data to be sought (once) on mouse over - see also initialiseEditingControls
                cmp.set("v.MouseOverDone", false);

/*
NEED TO CHECK HERE: IF WE CHANGE ANY FIELD AND NAVIGATE HAVING NOT SAVED (IE THIS POINT IN THE CODE)
WE NEED TO REVERT RECORD TO ORIGINAL STATE...
*/

if (cmp.get("v.isDirty") == true) {
	helper.initialiseDetails(cmp, event, helper);

	// Revert to "clean"
	cmp.set('v.isDirty', false);
}
                
				if (helper.currentRecordIsCached(cmp, event, helper, theRecord) == true) {
					console.log('IHDetail selectRecord - record "' + theRecord + '" located in cache - refreshing clickables and returning');

					// For cached records, we will not make a server call / complete re-build - so need
					// to check / deal with custom topic layouts here...
					helper.refreshLayoutDesign(cmp, event, helper);

					
					cmp.set("v.ActionCode", 'HelpTopic');
					helper.refreshClickables(cmp, event, helper, theRecord, cmp.get("v.ToolContext"), cmp.get('v.ActionCode'));
					return;
				}
			}


			// If we get here, we didn't find the requested record in the cache, 
			// so seek it via the standard server call

			// For some reason, global settings may not always have been retrieved, 
			// so try to fail safe here...
			if (keyTypes + '' != 'null') {
				keyTypes = keyTypes.split('^');
			} else {
				// If we can't check for Help record key type, arrange things
				// so we will act as for a Topic (see below)
				keyTypes = [];
				keyTypes.push(theRecord.substring(0,3));
			}


			// Action to take depends on whether the record selected is a Help Topic or not

			// ALSO CHECK FOR MASTER TOPIC IDENTIFIER...
			// How can one check to see whether what is in play (as a non-topic ID) is a
			// master identifier, or just a code for some other object (requiring an autoform / non-topic mode?)
						
			if (theRecord.substring(0,3) != keyTypes[0] && ! theRecord.startsWith('MTID:')) {		
			
				// We don't want to display any help topic configuration tools in the areas beyond the
				// reach of the Autoform (e.g., our own card header) - so reset tools here to those applicable
				// to our form's tool context: 

				// Also, if we're NOT dealing with a Help Topic, we'll show an Auto-form:
				// We cannot easily obtain record name, so set to a blank title for safety
				// Process tools will use action code to derive a default card title, so we need to
				// set action code here accordingly to one with a blank translation
				cmp.set("v.Title", "");
				cmp.set("v.ActionCode", 'ToolsOnly');
				helper.refreshClickables(cmp, event, helper, theRecord, cmp.get("v.ToolContextAF"), cmp.get("v.ActionCode"));


				// If the record being requested is for a different object type to the last
				// one in play, obtain object name information so it can be used to construct the form
				if (theRecord.length > 3 && theOldRecord.length > 3) {
					if (theRecord.substring(0,3) != theOldRecord.substring(0,3)) {
						console.log('IHDetail selectRecord - Record has changed (from "' + theOldRecord + '" to "' + theRecord + '") and so has object type: seeking object info...');				
						doGetObjectInfo = true;
					}
				}
				
				if (doGetObjectInfo == true) {
					var act = cmp.get("c.getObjectName");
					act.setParams({ 
						"RecordId" : theRecord
					});                       
					
					act.setCallback(helper, function (response, cmp){
					    if (response.getState() === "SUCCESS") {
					
					    	cmp.set("v.IsNonTopic", false);	
					    	try {
					    		cmp.set("v.HelpRecordId", theRecord);					    		
					    	} catch (e) {}
					    	
					    	cmp.set("v.sObjectName", response.getReturnValue());				
							cmp.set("v.IsHelpTopic", false);
							cmp.set("v.IsNonTopic", true);	

							console.log('IHDetail selectRecord - call to obtain object name / info returned "' + cmp.get("v.sObjectName") + '" - Object Name set');
							
						} else {
							alert('Error obtaining object information!');
						}
					});
					$A.enqueueAction(act);
				
				} else {
					// If we already know the non-help topic object type, just display the record
			    	cmp.set("v.IsNonTopic", false);	
				    	
			    	try {
			    		cmp.set("v.HelpRecordId", theRecord);
			    	} catch (e) {}
			    	
					cmp.set("v.IsHelpTopic", false);
					cmp.set("v.IsNonTopic", true);	
					
				}
				
			} else {
				// If record IS a Help Topic, note this fact and continue		
	            // In these cases, we're changing topic (server call)
	            // so show our "waiting" cues and allow update...

				// If we have a master topic identifier, not a topic id,
				// strip off the marker that will be in play: routine used
				// to obtain topic server side can deal with either identifier,
				// so long as we pass just the value...
				
				if (theRecord.startsWith('MTID:')) {
					theRecord = theRecord.substring(5);
					console.log('IHDetail Select Record: MTID was in play - adjusted to: ' + theRecord);
				}

	            
				cmp.set("v.IsNonTopic", false);	
	            helper.showSpinner(cmp);
	            cmp.set("v.HelpRecordId", theRecord);
				helper.initialiseDetails(cmp, event, helper);
	            
	            // Revert to "clean"
	            cmp.set('v.isDirty', false);
				cmp.set("v.IsHelpTopic", true);				
			}

            // Issue our own record selected event for others  
			/*
			ONLY DO THIS IF:
			RECORD HAS ACTUALLY CHANGED
			OR SOURCE IS SPECIAL COMP
			*/                              
			if (theRecord != theOldRecord || event.getParam("SourceComponent") == cmp.get("v.ComponentId") + '_SpecialComp') {
	   
	            var appEvent = $A.get("e.c:selectTopic");
	            appEvent.setParams({"RecordId" : theRecord});
	            appEvent.setParams({"SourceComponent" : cmp.get('v.ComponentId')});
	            
	            console.log('IHDetail "' + cmp.get('v.ComponentId') + '": re-raising select record event having processed the same on arrival at "' + theRecord + '"...');            
	            appEvent.fire();
	            
			} else {
			    console.log('IHDetail "' + cmp.get('v.ComponentId') + '": record "' + theRecord + '" is unchanged: no onward event raised...');            
			}

        }	// End if we're listening or source is _SpecialComp (i.e., a LUX template dynamic component or non-topic)
    },
    
    
    // Respond to (e.g., data manipulation) events passed through from our super component
    handlePassThroughs : function (cmp, event, helper) {
        
        var aCode = event.getParam("ActionCode");
        var src = event.getParam("SourceComponent");        
        var parms = event.getParam("Parameters");
        


// Use this juncture to set up our detail designer: setting helper reference to allow internationalisation access    
try {
    var DD = cmp.find("theDesigner");
	DD.set("v.ParentControlHelper", helper);
    
} catch (e){}


        
		if (aCode == 'KeywordClicked' && src == cmp.get("v.ComponentId") + '_SuggestKeywords') {
			// A suggested keyword has been clicked on the dialogue summoned by this component
			
			console.log('Details: receieved KeywordClicked event from "' + src + '" with parameters "' + parms + '"');
			
			var rec = cmp.get('v.CurrentRecord');
			rec.iahelp__Keyword__c = parms.toString();
			cmp.set("v.CurrentRecord", rec);
			cmp.set("v.isDirty", true);
		}


		// Special cases: respond to our dialogue component (should be helper.eventIsFromOurDialogue - but this isn't working!)
		if (aCode == 'DialogueRequestClose' && src == cmp.get("v.ComponentId") + '_Dialogue') {
		
			// If we're closing the upload image dialogue, refresh to reflect changes
			if (cmp.get("v.ActionCode") == 'CueUploadImage') {
				helper.initialiseDetails(cmp, event, helper);
			}
		}


		// Special cases: respond to our Autoform component - changes to data
		if (aCode == 'DataAmended' && src == cmp.get("v.ComponentId") + '_Autoform') {
		
			// Issue a "data amended" event as we would if saving a topic
		    var appEvent = $A.get("e.c:evtPassThrough");
		    appEvent.setParams({"SourceComponent" : cmp.get('v.ComponentId')});
		    appEvent.setParams({"ActionCode": "DataAmended"});
		    appEvent.setParams({"Parameters": cmp.get('v.HelpRecordId')});
			appEvent.fire();
			
		}


        // Respond only to events we're listening for from others in certain cases
        if (helper.eventBeingListenedTo(cmp, event)) {
        
        	if (aCode == 'RootNodeChange') {
        		cmp.set("v.TreeContext", parms);
        	}
        	        	
			if (aCode == 'ComponentToolsProcessed') {				
				// Respond if the source has been set as our source of cached help record data
				if (src == cmp.get("v.CachedRecordSource")) {
					var HEs = parms.get("v.HelpedElements");
					cmp.set("v.HelpedElements", HEs);	
					
					var HTs = parms.get("v.HelpTopics");
					cmp.set("v.HelpTopics", HTs);	
				}
			}
        }


        // Respond only to our own events in some cases
        if (helper.eventIsOurOwn(cmp, event)) {
                
	        switch (aCode) {

case 'refactorTopic' :
	var x = window.getSelection();
	console.log(x.toString());
	alert(x.toString());
	break;


	        	// Toggle inline edit mode on / off
				case 'InlineEdit':
					cmp.set("v.DataMode", 'InlineEdit');
					break;		
				case 'InlineView':
					cmp.set("v.DataMode", 'View');
					break;

				case 'SuggestKeywords':
					// Keyword suggestion dialogue has been requested
							
					var msgVal = '';
					var ttl = helper.Internationalise(cmp, 'ToolLabelSuggestKeywords');
					
					// Ensure we only analyse 'genuine' text (not nulls)
					var D1 = cmp.get('v.CurrentRecord.iahelp__DescriptionText1__c');
					var D2 = cmp.get('v.CurrentRecord.iahelp__DescriptionText2__c');
					var D3 = cmp.get('v.CurrentRecord.iahelp__DescriptionText3__c');
					var D4 = cmp.get('v.CurrentRecord.iahelp__DescriptionText4__c');
					var D5 = cmp.get('v.CurrentRecord.iahelp__DescriptionText5__c');
					
					if (D1 + '' == 'null'){D1 = '';}
					if (D2 + '' == 'null'){D2 = '';}
					if (D3 + '' == 'null'){D3 = '';}
					if (D4 + '' == 'null'){D4 = '';}
					if (D5 + '' == 'null'){D5 = '';}
					
					try{
						msgVal = cmp.get('v.CurrentRecord.Name') + '. ' + cmp.get('v.CurrentRecord.iahelp__Summary__c') + '. ' + D1 + ' ' + D2 + ' ' + D3 + ' ' + D4 + ' ' + D5; 
				
					} catch(e){
						console.log(e);
					}
					var dlgMap = {
				        "qualityThresholdOfKeywords" : 2,
				        "textValue" : msgVal,
					    "selectedColour1": cmp.get("v.UXThemeColour1"),
					    "Height": 485,
					    "SuppressFooter": true,
					    "SuppressPoweredBy": true,
					    "ComponentId": cmp.get("v.ComponentId")+'_SuggestKeywords',
					};
									                				                    
					helper.doDialogue(ttl, 'LUX', 'c:IHKeywords', dlgMap, 500, false, true, false, cmp, false);					
					break;

	            case 'Cancel':
	                // Cancel effectively re-gets our record
	                helper.showSpinner(cmp);
	                cmp.set('v.DataMode', 'View');
	                helper.initialiseDetails(cmp, event, helper);
	                cmp.set('v.isDirty', false);
	                break;
	        
	            case 'ComponentToolsProcessed':
	                // Component tools downloaded by Card include details of any Custom Fields in our case
	                // (This is only true of the "HelpTopic" action that we cue after rendering).
	                // Show or hide custom fields tab depending whether such fields were found...
	                var CustomTab = cmp.find('tabSelector3');
	                var CFs = cmp.get("v.CustomFields");
	                
	                if (CFs.length > 0) {
	                    $A.util.removeClass(CustomTab, 'slds-hide');
	                }
	                
	                break;
	                
	            case 'CueUploadImage':
					// Cue upload image dialogue:
					// Warn on entry that this will lose any unsaved changes, if any have been made
					// and offer backout
					if (cmp.get("v.isDirty") == true) {
						if (! confirm(helper.Internationalise(cmp, '[QAMMessageDirtyWarning]'))) {
							return;
						}
						
						// If we continue, we should remove dirty status - as we will be losing the changes
						cmp.set("v.isDirty", false);
					}


					var CRoot = cmp.get('v.CommunityRoot');
					
					// If root is 'null', this can be ignored in most cases
					if (CRoot + '' == 'null') {CRoot = '';}
					if (CRoot != '') {CRoot = '/' + CRoot;}
			
					var dlgSource = CRoot + "/apex/iahelp__IHUploadTopicImage?IHLUX=true&HTID=" + cmp.get('v.CurrentRecord.Id');        
			        helper.doDialogue(cmp.get("v.TipButtonUploadImage"), 'VF', dlgSource, null, 130, false, false, false, cmp, false);
			        
					// Need to do something here to cause control to refresh/rebuild after dialogue
					// is closed, as topic image may have been updated and we don't want to allow
					// such changes to be overwritten by subsequent edits...
					cmp.set("v.ActionCode", 'CueUploadImage');
			        
	                break;
	                
	            case 'DeleteTopic' :            				     
	            	// Delete the current topic, after local confirm message
	            	if (confirm(helper.Internationalise(cmp, 'MessageDeleteWarning'))) {
	
	    				var act = cmp.get("c.deleteTopic");
				        act.setParams({ 
				            "HelpTopicId" : cmp.get("v.HelpRecordId") 
				        });                       
		                
				        // Add callback to process returned results
				        act.setCallback(this, function (response, cmp){
				        
				        	// This should return an empty response value:
				        	var ret = response.getReturnValue();
				        	
				        	if (ret != '') {
				        		// If there are any diagnostics, assume this is an error and show them
				        		cmp.set("v.Diags", ret);
				        		
				        	} else {
				        		// Otherwise, re-set this control
				                cmp.set('v.DataMode', 'View');
				                helper.initialiseDetails(cmp, event, helper);
				                cmp.set('v.isDirty', false);
				        		
				        		// Also issue a "data amended" event for any listeners to note
				                var appEvent = $A.get("e.c:evtPassThrough");
				                appEvent.setParams({"SourceComponent" : cmp.get('v.ComponentId')});
				                appEvent.setParams({"ActionCode": "DataAmended"});
				                
				                // For deletes, don't pass record info in parameters (no point)
				                appEvent.setParams({"Parameters": ""});
	        					appEvent.fire();
				        		
				        	}
			        		
				        });
	
				        // Send action
				        $A.enqueueAction(act);
	            	}
	            	break;
	            	
	            case 'Edit':
	            case 'View':                    
                    
	                // Re-set card title (which may have changed via editor)
	                // then set specified mode
	                cmp.set('v.Title', cmp.get('v.CurrentRecord.Name'));
	                cmp.set('v.DataMode', aCode);
	                
	                if (aCode == 'View') {
		                // Initialise our sub-component - for view mode only, if required by lighting template
	                	helper.initialiseTemplateComponents(cmp, event, helper);	 
	                	
	                	// Use auto height
	                	cmp.set("v.AutoCardHeight", true);
	                	
	                } else {
	                	// In edit mode, we need height = 100% / specified, not auto
	                	cmp.set("v.AutoCardHeight", false);	                
	                }
	                
                    // Set up our detail designer: setting helper reference to allow internationalisation access  
/*                      
                    try {
                        var DD = cmp.find("theDesigner");
                    	DD.set("v.ParentControlHelper", helper);
                        
                    } catch (e){
                        console.log('IHDetail initialisation - error configuring detail designer sub-component: ' + e);
                    }
*/                    
	                break;
	                
	            case 'Save':
	            case 'QuickSave':
	                var act = cmp.get("c.saveRecord");
	                
	                // Turn current record into JSON for marshalling
	                var objectJSON = JSON.stringify(cmp.get('v.CurrentRecord'));
	                act.setParams({ 
	                    "objectJSON" : objectJSON
	                });                       
	
	                helper.showSpinner(cmp);
	                cmp.set('v.DataMode', 'View');
	
	                act.setCallback(helper, function (response, cmp) {
	                    cmp.set('v.Diags', helper.Internationalise(cmp, response.getReturnValue()));

						// Report any unusual diagnostics: this won't cover all possible error messages but...
						if (cmp.get("v.Diags").indexOf(helper.Internationalise(cmp, "MessageGenericError")) != -1
								|| cmp.get("v.Diags").indexOf('Error: ') != -1) {						
						
							helper.doNudge(cmp, helper.Internationalise(cmp, "MessageGenericError"), cmp.get("v.Diags"), 0);
						}
	    
	                    // Re-set card title (which may have changed via editor)
	                    // then set mode back to edit
	                    cmp.set('v.Title', cmp.get('v.CurrentRecord.Name'));
	                    cmp.set('v.isDirty', false);
	                    helper.hideSpinner(cmp);
	                    
		        		// Also issue a "data amended" event for any listeners to note
		                var appEvent = $A.get("e.c:evtPassThrough");
		                appEvent.setParams({"SourceComponent" : cmp.get('v.ComponentId')});
		                appEvent.setParams({"ActionCode": "DataAmended"});
		                appEvent.setParams({"Parameters": cmp.get('v.HelpRecordId')});
						appEvent.fire();
						
						// If saving (as opposed to Quick Saving) also return to View mode.
						// In doing so, we also need to update the on-screen version of the topic description:
						// When fetched from getTools etc. it will have been keyword-parsed, but we'll have to 
						// revert here to "native" (i.e., last saved) version otherwise it may look on screen
						// as if changes to description have been lost (as the old parsed version is shown)
						if (aCode == 'Save') {
			                cmp.set('v.Title', cmp.get('v.CurrentRecord.Name'));
			                cmp.set('v.DataMode', 'View');
			                
			                cmp.set("v.KeywordParsedDescription", cmp.get("v.CurrentRecord.iahelp__Description__c"));
			                
			                // View mode on detail card itself is not sufficient to 
			                // toggle the card ellipsis menu view / edit tool...
			                helper.toggleConfigTool(cmp, 'Ellipsis', 'View');
						
						} else {
							cmp.set('v.DataMode', 'Edit');
						}						


						// Initialise our sub-component, if required by lighting template
						helper.initialiseTemplateComponents(cmp, event, helper);
						
	                });
	                
	    			$A.enqueueAction(act);
	                break;
	                
	            case 'TopicAdd' :
	            	// This is, in fact, the same as adding a topic via D&D - except we don't specify
	            	// the dropped content (Topic Description). So: re-use D&D support calls here
	
					// The call will result in a "record selected" event - but we don't usually respond to these
					// when they emanate from ourselves. So: here we need to take additional action by setting
					// a "latch" to force response in these particular circumstances
					cmp.set("v.ResponseLatch", true);
					
					cmp.set('v.DataMode', 'Edit');
					
	            	helper.createNewTopic(cmp, '', false);
	            	break;
	            	
	            case 'TopicClone' :
	            	// Clone - using wrapped version of classic clone routine
	        		var numClones = prompt(helper.Internationalise(cmp, 'MessageCloneTopicNumber'), 1); 
	                var allCNames = '';
	                var allCRels = '';
	                var currentClone;
	                var sourceName = cmp.get("v.CurrentRecord.Name");
	                var i;
	                
	                // Gather clone information (desired names, clone relationships)
	                if (numClones > 0) {
	                    for(i=1; i <= numClones; i++) {
	                		currentClone = prompt(helper.Internationalise(cmp, 'MessageCloneTopicNames') + ' (' + i + '/' + numClones + '):', sourceName + ': ' + i);
	                		if (currentClone == null) {return;}
	                        allCNames += currentClone.split('^').join('') + '^';
	                        
	                        currentClone = prompt(helper.Internationalise(cmp, 'MessageCloneTopicRelationships'), 'Y');
	                		if (currentClone == null) {return;}
	                        allCRels += currentClone.split('^').join('^') + '^';                    
	                    }
	                }
	                                    
	                // Having gathered the required naming data, create the requested clones
	                if (allCNames != '') {
	
				        helper.showSpinner(cmp);
				
				        var act = cmp.get("c.cloneTopic");
				
				        act.setParams({ 
				            "HTID" : cmp.get("v.CurrentRecord.Id"),
				            "cloneNames" : allCNames,
				            "cloneRels" : allCRels 
				        });                       
				                
				        // Add callback to process returned results
				        act.setCallback(this, function (response, cmp){
				
				            var state = response.getState();
				
				            // Remove waiting cues
				            helper.hideSpinner(cmp);
				    
				            if (state === "SUCCESS") {            
				                
				                // Note return in Diags
				                cmp.set("v.Diags", helper.Internationalise(cmp, response.getReturnValue()));
				                                
				            } else {
				                cmp.set("v.Diags", "ERR!");
				            }
				            
				        }); 
				
				        // Send action
				        $A.enqueueAction(act);
	                }
	
	            	break;
	                
				case 'ViewInPortal':
                    console.log('ViewInPortal from Detail component-----');
	            	// Open current Topic in portal
					var CRoot = cmp.get('v.CommunityRoot');
					
					// If root is 'null', this can be ignored in most cases
					if (CRoot + '' == 'null') {CRoot = '';}
					if (CRoot != '') {CRoot = '/' + CRoot;}        

					var HTID = cmp.get("v.HelpRecordId");
	            	var PortalPage = cmp.get("v.PortalPage");
					
					if (CRoot != '') {
						// If we're in a community, safest thing to do is to continue with VF option
	                	window.open(CRoot + "/apex/iahelp__" + PortalPage + "?HTID=" + HTID);
						
					} else {
						// Where available, use LUX (component) override
		        		window.open(CRoot + '/' + HTID);				
					}
	                
	                break;
	                
	            default:
	                break;
	        }
        }
    },
    
    
    // Process editor tab clicks
    selectTab : function (cmp, event, helper) {

        var i;
        var currentIdx;
        var maxTabs = 100;
        var TabName = 'HelpTopicEditTab';

        try {
	        currentIdx = event.target.getAttribute("aria-controls").split(TabName).join('');
        } catch (e) {
        	// If tab click is not quite on the "right" bit of the tab...
        	return;
        }

        // Get all tab selectors & Remove selection
        for (i=0; i < maxTabs; i++) {
            $A.util.removeClass(cmp.find('tabSelector' + i), 'slds-active');
        }

        // Find the clicked tab selector and add selected
        $A.util.addClass(cmp.find('tabSelector' + currentIdx), 'slds-active');
        
        // Hide all tabs
        for (i=0; i < maxTabs; i++) {
            $A.util.removeClass(cmp.find(TabName + i), 'slds-show');
            $A.util.addClass(cmp.find(TabName + i), 'slds-hide');
        }
        
        // Find and show selected tab
        $A.util.removeClass(cmp.find(TabName + currentIdx), 'slds-hide');
        $A.util.addClass(cmp.find(TabName + currentIdx), 'slds-show');
        
        
        // If selected tab is Guides, ensure Guided Elements are populated as required
        if (currentIdx == 6) {
        	helper.lookupRelatedGElements(cmp, cmp.get("v.CurrentRecord.iahelp__GuidedLayout__c"));        
        }
    },
    
    
    // Mark current record as edited and write back field values to record where required
    setDirty : function (cmp, event, helper) {

        // This is triggered from control change - so only set this
        // if we are truly in edit mode (rather than, say, navigating in view mode)
        if (cmp.get('v.DataMode') == 'Edit') {
            cmp.set('v.isDirty', true);
        }
        
        // For select controls, we need to write the selected value back to our data
        var cmpId = event.getSource().getLocalId();
        var ctl = cmp.find(cmpId);
        var val;
        var i;


        // Custom fields require special handing 
        if (cmpId == 'CUSTOMFIELD') {
            // We can't provide a unique Aura ID as this would have to be calculated and calculations
            // are not allowed in this attribute! So: the name of the underlying field has been put
            // into label class for use below. For now, we can just get control from event source
            ctl = event.getSource();
        } 
        console.log('IHDetail - setting dirty state for: "' + cmpId + '" (' + ctl + ')');
        

        if (ctl + '' != 'undefined') {
            val = ctl.get("v.value");
            
            // Parse out any hard-coded string values used to represent nulls...
            if (val == cmp.get("v.NullValue")) {val = null;}
            console.log('IHDetail - new value: "' + val + '"');


            switch (cmpId) {
                case 'CUSTOMFIELD' :
                    // Get the name of the field that needs to be edited                    
                    var cFld = ctl.get("v.labelClass"); 

                    // Set to event value
                    cmp.get("v.CurrentRecord")[cFld] = val;
                    break;
                    
                case "CalloutMediaChoice" :
                    cmp.set("v.CurrentRecord.iahelp__CalloutMediaChoice__c", val);
                    break;
    
                case "CalloutTemplate" :
                    cmp.set("v.CurrentRecord.iahelp__CalloutTemplate__c", val);
                    
                    // On changing template, re-set callout height: this should have come
                    // down with each callout record:
                    var CTs = cmp.get("v.TemplatesC");
                    for (i=0; i<CTs.length; i++) {
                        if (CTs[i].Id == val) {
                            cmp.set("v.CurrentRecord.iahelp__CalloutHeight__c", CTs[i].iahelp__DefaultHeight__c);
                            break;
                        }
                    }
                    
                    break;

                case "CustomStyle" :
                    cmp.set("v.CurrentRecord.iahelp__CustomStyle__c", val);
                    break;

                case "GuidedElement" :
                    cmp.set("v.CurrentRecord.iahelp__GuidedElement__c", val);
                    break;

                case "GuidedLayout" :
                    cmp.set("v.CurrentRecord.iahelp__GuidedLayout__c", val);
                    helper.lookupRelatedGElements(cmp, val);
                    break;

                case "GuideStepMode" :
                    cmp.set("v.CurrentRecord.iahelp__GuideStepMode__c", val);
                    break;

                case "HelpTopicStatus" :
                    cmp.set("v.CurrentRecord.iahelp__HelpTopicStatus__c", val);
                    break;
            
                case "HelpVoteSet" :
                    cmp.set("v.CurrentRecord.iahelp__HelpVoteSet__c", val);
                    
                    // Keep track of selected vote set for use in other screen furniture
                    helper.lookupRelatedObjects(cmp, val);
                    break;

                case "LightningTemplate" :
                    cmp.set("v.CurrentRecord.iahelp__LightningTemplate__c", val);
                    break;
            
                case "Template" :
                    cmp.set("v.CurrentRecord.iahelp__Template__c", val);

					// If template has changed, we may need to amend topic layout
					helper.refreshLayoutDesign(cmp, event, helper);

                    break;

                case "Visibility" :
                    cmp.set("v.CurrentRecord.iahelp__Visibility__c", val);
                    break;
                
            }
        }
    
    },
    
       
    // Show/Hide image/video editor panel (within editor panel as a whole)
    toggleImageEdit : function (cmp, event, helper) {
        $A.util.toggleClass(cmp.find('ImgEditor'), 'slds-is-open');
        $A.util.toggleClass(cmp.find('ImgEditor_Twisty'), 'nodeExpanded');
    },
    toggleVideoEdit : function (cmp, event, helper) {
        $A.util.toggleClass(cmp.find('VidEditor'), 'slds-is-open');
        $A.util.toggleClass(cmp.find('VidEditor_Twisty'), 'nodeExpanded');
    },
    
    // Reset image / video fields to default / blank values
    resetImage : function (cmp, event, helper) {
        var x;
        x = cmp.find('txtImgURL');
        x.set('v.value', '');
        x = cmp.find('txtImgTitle');
        x.set('v.value', '');
        x = cmp.find('txtImgCaption');
        x.set('v.value', '');
        x = cmp.find('txtImgALTText');
        x.set('v.value', '');
        x = cmp.find('txtImgWidth');
        x.set('v.value', 0);
        x = cmp.find('txtImgHeight');
        x.set('v.value', 0);
        
        cmp.set('v.isDirty', true);
    },
    resetVideo : function (cmp, event, helper) {
        var x;
        x = cmp.find('txtVidURL');
        x.set('v.value', '');
        x = cmp.find('txtVidTitle');
        x.set('v.value', '');
        x = cmp.find('txtVidCaption');
        x.set('v.value', '');
        x = cmp.find('txtVidWidth');
        x.set('v.value', 0);
        x = cmp.find('txtVidHeight');
        x.set('v.value', 0);

        cmp.set('v.isDirty', true);
    },
    
    
    // Preview callout AS SAVED link
    previewCallout : function (cmp, event) {
		var CRoot = cmp.get('v.CommunityRoot');
		
		// If root is 'null', this can be ignored in most cases
		if (CRoot + '' == 'null') {CRoot = '';}
		if (CRoot != '') {CRoot = '/' + CRoot;}

        window.open(CRoot + "/apex/iahelp__IHPreviewCallout?HTID=" + cmp.get('v.CurrentRecord.Id'));
    },
    
    
    // Preview callout AS EDITED link
    previewCalloutAsEdited : function (cmp, event, helper) {
		var CRoot = cmp.get('v.CommunityRoot');

		// If root is 'null', this can be ignored in most cases
		if (CRoot + '' == 'null') {CRoot = '';}
		if (CRoot != '') {CRoot = '/' + CRoot;}

		var dlgSource = CRoot + "/apex/iahelp__IHRedirector?HTID=" + cmp.get('v.CurrentRecord.Id') + "&ShowCallout=" + cmp.get('v.CurrentRecord.iahelp__CalloutTemplate__c');        
        helper.doDialogue(cmp.get("v.ButtonPreviewCalloutAsEdited"), 'VF', dlgSource, null, cmp.get('v.CurrentRecord.iahelp__CalloutHeight__c') + 50, false, true, false, cmp, false);
    },


    // View templates link
    gotoTemplates : function (cmp, event) {
		var CRoot = cmp.get('v.CommunityRoot');
		
		// If root is 'null', this can be ignored in most cases
		if (CRoot + '' == 'null') {CRoot = '';}
		if (CRoot != '') {CRoot = '/' + CRoot;}

        window.open(CRoot + "/" + cmp.get('v.TemplateObjectId'));		
    },

    
    // Vote Sets link
    maintainVoteSets : function (cmp, event, helper) {
        
        var act = cmp.get("c.TVoteSetsLink");
        act.setCallback(helper, function (response, cmp){
            var state = response.getState();
            if (state === "SUCCESS") {
                var U = response.getReturnValue();
                
                // Behaviour needs to reflect LUX vs VF /LUX out
                if (document.location.href.indexOf('/apex/') != -1) {
	                window.open(U);
	                
                } else {
	                var urlEvent = $A.get("e.force:navigateToURL");
	                urlEvent.setParams({
	                  "url": U
	                });
	                urlEvent.fire();
                }

            } else {
            	alert(helper.Internationalise(cmp, 'MessageGenericError'));
            }
        });
        
        $A.enqueueAction(act);
    },

    
    // Log a vote-type interaction
    castVote : function (cmp, event, helper) {
    
    	var theId = event.target.id;
    	var D1 = cmp.get("v.Delimiter");
    	var parms = theId.split(D1);
    	var OptId = parms[0];
    	
    	OptId = OptId.split('link_').join('');
    	OptId = OptId.split('badge_').join('');
    	OptId = OptId.split('Icon_').join('');
    	OptId = OptId.split('IconSpan_').join('');

    	var OptLabel = parms[1];
    	var HTID = cmp.get("v.CurrentRecord.Id");
    	var Cxt = cmp.get("v.TreeContext");
    	
    //	var act = cmp.get("c.logLUXInteraction");
    	
    	// Context needs to be set to:
    	// "Context" (ID of tree if we're being viewed in conjunction with one) ^ Help Topic being voted on ^ Vote (option ID) being cast
   /* 	act.setParams({
    		"iTyp" : "8",
    		"Description" : OptLabel,
    		"IHContext" : Cxt + "^" + HTID + "^" + OptId
    	});  */
    	
     /*   act.setCallback(helper, function (response, cmp){
        
	        if (response.getState() === "SUCCESS") {
	        
	        	cmp.set("v.Diags", helper.Internationalise(cmp, response.getReturnValue()));
	        	
	        	// Upon success, mark selected vote badge
        		var badges = document.querySelectorAll('.slds-badge');
        		var selectedBadge = document.getElementById('badge_' + OptId + D1 + OptLabel);

				for (var i=0; i < badges.length; i++) {
					$A.util.removeClass(badges[i], 'slds-theme_inverse');
				}

				$A.util.addClass(selectedBadge, 'slds-theme_inverse');
      	
	        } else {
	        	cmp.set("v.Diags", "Err!");
	        }
        
        });  */
    	
        // Send action
       // $A.enqueueAction(act);
    	
			helper.logLUXInteractions(cmp, 8, OptLabel,  Cxt + "^" + HTID + "^" + OptId).then((response) => {
			if (response.getState() === "SUCCESS") {
	        
	        	cmp.set("v.Diags", helper.Internationalise(cmp, response.getReturnValue()));
	        	
	        	// Upon success, mark selected vote badge
        		var badges = document.querySelectorAll('.slds-badge');
        		var selectedBadge = document.getElementById('badge_' + OptId + D1 + OptLabel);

				for (var i=0; i < badges.length; i++) {
					$A.util.removeClass(badges[i], 'slds-theme_inverse');
				}

				$A.util.addClass(selectedBadge, 'slds-theme_inverse');
      	
	        } else {
	        	cmp.set("v.Diags", "Err!");
	        }
        
        }); 
    },


	// Handle image clicks / light-boxing
	doLightBox : function (cmp, event, helper) {
	
		var U;
		var ttl = cmp.get("v.CurrentRecord.Name");
		var M = event.target.getAttribute('data-MediaMode');
		var src;
		

		if (M == 'Image') {
			U = cmp.get("v.CurrentRecord.iahelp__ImageURL__c");

			src = '/apex/iahelp__IHLUXOutHost?NSApp=iahelp&App=appIH&NSComp=iahelp&Comp=IHImageViewer';
			src += '&Parms=Height~-1^SuppressHeader~true^MediaMode~Image^MediaWidth~100^ImageURL~' + U;

			if (cmp.get("v.CurrentRecord.iahelp__ImageTitle__c") + '' != 'null') {
				ttl += ': ' + cmp.get("v.CurrentRecord.iahelp__ImageTitle__c");
			}

		} else {
			 U = cmp.get("v.CurrentRecord.iahelp__VideoURL__c");
			 src = U;

			 if (cmp.get("v.CurrentRecord.iahelp__VideoTitle__c") + '' != 'null') {
				ttl += ': ' + cmp.get("v.CurrentRecord.iahelp__VideoTitle__c");
			 }
		}


		// 1.50.8 - replacing LUX dialogue with image viewer via lightning out in new tab:
		// LUX dialogue components do not reliably work when navigating between records (2nd use of same generator)
		// unless entire page is refreshed. 
		// Also, VF dialogue imperfect as certain tools do not work in LUX out

		window.open(src, 'IHImagePopout', 'menubar=0, resizable=1, status=0, toolbar=0, titlebar=0, location=0');
	},


	// Set the data of a record D&D operation 
	doDragStart : function(cmp, event, helper) {
	    var D = cmp.get("v.Delimiter");
	    var dat = 'DetailTitle' + D + cmp.get("v.CurrentRecord.Id");
	    
		event.dataTransfer.dropEffect = "move";
		
		// Set data to identify that a detail control record is being dragged, plus include record ID:
		event.dataTransfer.setData('text', dat);		
		
		// D&D data is not available on drag over, so log a passthrough with this data 
		// so those dragged over know how to respond
		var appEvent = $A.get("e.c:evtPassThrough");
		appEvent.setParams({"SourceComponent" : cmp.get('v.ComponentId')});
		appEvent.setParams({"ActionCode": 'DragStart'});
		appEvent.setParams({"Parameters": dat});
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

	// Allow record drags
	drag : function (cmp, event, helper) {
	    event.preventDefault();
	},


	// Show whether or not drop will be allowed
	doDragOver : function (cmp, event, helper) {
	
		if (helper.DDAllowed(cmp, event) == true) {
		    event.preventDefault();
	
		    var T = cmp.find('theTopicViewer');
    
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
		    
		    var theContainer = cmp.find('theTopicViewer');
		    var dat = event.dataTransfer.getData("text");
		    var D1 = cmp.get("v.Delimiter");    
		    var parms = [];
		
		    parms = dat.split(D1);
		    
		    // Not working here - god knows why
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
					// Set topic ID then cue a re-build through re-initialisation
			        cmp.set("v.HelpRecordId", parms[1]);
			        helper.initialiseDetails(cmp, event, helper);
					break;
		    }
	
		
		} catch (e){
			console.log('IHDetail - drop error: ' + e);
		}
	    
	},

	    
	// Expose card's HTML parser to designers etc
	getSafeHTML : function (cmp, event, helper) {
		var sHTML = cmp.get("v.sHTML");
		return helper.getSafeHTML(sHTML);
	},

	    
})