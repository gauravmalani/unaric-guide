({  

/*
doOwnerChange : function (cmp, event, helper) {
	//alert('to do');
	
	var actionAPI = cmp.find("quickActionAPI");
    var args = {actionName: "Lead.NewLead"};
    actionAPI.selectAction(args).then(function(result){
        //Action selected; show data and set field values
    }).catch(function(e){
        if(e.errors){
            //If the specified action isn't found on the page, show an error message in the my component
            alert(e.errors[0]);
        }
    });	
	
},
*/

 
///////////////////////////////////////////////////////////////////////////
// Form building and form data handling methods
///////////////////////////////////////////////////////////////////////////

	// Get the largely invariant, cacheable information used on cards (delegated)
	init : function(cmp, event, helper) {	
		helper.initialiseGlobals(cmp, event, helper);
	},


	// Wrapper allowing client LUX components to cue re-building
	reInitialise : function (cmp, event, helper) {
		cmp.set('v.isInitialised', false);
	    helper.init(cmp, event);
	},


	// Obtain form sizing (height) data
	doneRendering : function(cmp, event, helper) {
	
		try {
			var Acc = cmp.find("ModeTools").getElement();		
			var MyF = cmp.find("MyForm").getElement();
			
			// Only take accordion into account if it's NOT floating over the form - i.e.,
			// POTENTIALLY ignore its height in override mode, as form scrolls underneath (instead of getting pushed down the page)	
			if (helper.isLayoutOverride(cmp) == false) {
				if (Acc.offsetHeight > 0) {
					cmp.set("v.H_Accordion", Acc.offsetHeight + helper.remToPx(cmp, 0.2));
				} else {
					cmp.set("v.H_Accordion", 0);
				}
			
			} else {
				// If we are in override mode, form scrolls beneath accordion - but only with a fixed pixel height!
				// At -1 (100%) height, by definition, there is no scrolling, so accordion occupies height
				if (cmp.get("v.Height") == -1) {
					cmp.set("v.H_Accordion", Acc.offsetHeight + helper.remToPx(cmp, 0.2));
				} else {
					cmp.set("v.H_Accordion", 0);
				}
			}		
			
			
			if (MyF.offsetHeight > 0) {
				cmp.set("v.H_MyForm", MyF.offsetHeight + helper.remToPx(cmp, 1.8));
			} else {
				cmp.set("v.H_MyForm", 0);
			}
		        	
		} catch (e) {}
	
	},


    // Routine fired after loading (e.g., on mouse over) to complete building of all form sections and page furniture
	completeFormBuild : function (cmp, event, helper) {
		cmp.set("v.GuidesInUse", true);
		
		if (cmp.get("v.ListingItems") + '' != 'undefined') {
			if (cmp.get("v.ListingItems").length > 0) {
				if (cmp.get("v.ListingItems")[0].Sections + '' != 'undefined') {
					if (cmp.get("v.ListingItems")[0].Sections.length > 0) {
						cmp.set("v.InitialSections", cmp.get("v.ListingItems")[0].Sections.length);
					}
				}
			}
		}
			
	},


	// Routine fired by edit form as it loads to set any fields overridden by member data - new records only
	setOverriddenFields : function(cmp, event, helper) {
			
		var D1 = '|';
		var D2 = '¬';
		var PFs = cmp.get("v.PopulatedFields");
		var inputs = cmp.find("editCtl");
		var PF;
		var PFsOut = '';
		var i;
		var f;
		
		try {

			// Only allow override defaults for NEW records
			if (cmp.get("v.recordId") + '' == 'null' || cmp.get("v.recordId") + '' == 'undefined') {
			
				// Only proceed if there are some default values specified
				if (PFs + '' != '') {
					PFs = PFs.split(D1);
					
					for (f=0; f<inputs.length; f++) {
				
						for (i=0; i<PFs.length; i++) {
							PF = PFs[i].split(D2);
							
							if (inputs[f].get("v.fieldName") == PF[0]) {
								inputs[f].set("v.value", PF[1]);
								
								// 'Record' the fact that we've done this for the particular field,
								// by removing this field from the list of those to populate
								PFs[i] = D2 + D1;
							}
						}
						
					}
				}
				
				
				// Re-build string of fields to populate and reset member data
				for (i=0; i<PFs.length; i++) {
					PF = PFs[i].split(D2);
					if (PF[0] != '') {
						PFsOut += PF[0] + D2 + PF[1] + D1;
					}
				}
				
				cmp.set("v.PopulatedFields", PFsOut);
			
			}
			
		} catch (e) {
			console.log('AutoForm load action / Set overridden fields - error: ' + e);
		}
		
	},
	

    // Offer feedback on saving a record successfully
    reportSuccess : function (cmp, event, helper) {
    	
    	var act = cmp.get("v.OnSaveAction");
		var parms = event.getParams().response;    	

		// Re-set to view mode (allowing save button to be available again)
		cmp.set("v.OpMode", 'View');
    	
    	// Feeback to offer depends on control settings
    	switch (act) {
    		case 'Report only' :
    			// Stay put but make record ID known
		    	cmp.set("v.Diags", "SAVED: " + parms.id);    		

				// Also issue a "data amended" event for any listeners to note
				var appEvent = $A.get("e.c:evtPassThrough");
				appEvent.setParams({"SourceComponent" : cmp.get('v.ComponentId')});
				appEvent.setParams({"ActionCode": "DataAmended"});
				appEvent.setParams({"Parameters": cmp.get('v.HelpRecordId')});
				appEvent.fire();

				// Also, revert to view mode		    		
				cmp.set("v.DataMode", "View");
    			break;
    			
    		case 'Navigate to record' :
    			// Navigate to the affected record

				var navService = cmp.find("navService");
				var recId;
				var relRecId = cmp.get("v.RelRecordId");
				var pRef;
				
				
				if (relRecId != '' && relRecId + '' != 'undefined') {
					recId = relRecId;
				} else {
					recId = parms.id;
				}
				
				var pDef = 'RECORD - VIEW^' + recId;
				
				// Obtain navigable page reference object from string definition    	
				pRef = helper.getPageReferenceFromDef(pDef);
				
				if (pRef != null) {
				    event.preventDefault();
				    navService.navigate(pRef, true);
				}
    			
    			break;
    	}
    },
    
    
    // Placeholder: Offer feedback on save errors
    reportError : function (cmp, event, helper) {
    
		// Re-set to view mode (allowing save button to be available again)
		cmp.set("v.OpMode", 'View');
    
		var errors = event.getParams(); 
		console.log("Error Response", JSON.stringify(errors)); 
    },
        

    // Note the fact that data has been changed
    // Only respond to data changes once we're initialised:  Field mouse-enter is used to trap this fact
    // so that only changes in fields after form build represent genuine edits to be noted
    markInitialised : function (cmp, event, helper) {
    	cmp.set("v.isInitialised", true);
    },    
    setDirty : function (cmp, event, helper) {   
    	if (cmp.get("v.isInitialised") == true) {
    	
    		// Mark the form as a whole as dirty    		
	    	cmp.set("v.isDirty", true);


			// Mark the individual field as dirty
			var ctl = event.getSource();
			var FieldAPIName = ctl.get("v.fieldName");
			var I = helper.getIHLI(cmp, FieldAPIName);	  
			
			I.isDirty = true;
			helper.setIHLI(cmp, I);
  	
    	}

		/*
		Code to round entered number: setting of resultant value
		works only intermittently!
		*/
		
		/*
		try {
			var ctl = event.getSource();
			var newVal = Number(ctl.get("v.value"));
			console.log('setDirty change value: from ' + newVal);
			
			var DPs = 2;
			newVal = Number(Math.round(newVal+'e' + DPs)+'e-' + DPs);
		
			console.log('setDirty change value: to ' + newVal);
			ctl.set("v.value", newVal);
		
		} catch (e) {
			console.log(e);
		}
		*/


    	
		/*
		SOME EXPERIMENTS ATTEMPTING TO CHECK FIELDS FOR ERRORS:
		
		var ctl = event.getSource();         
		
		console.log(ctl);  											The LUX secure component
		console.log(ctl.get("v.fieldName"));						The correct API name
		console.log(ctl.get("v.value"));							The as-changed value
		console.log(ctl.getGlobalId());  							The unique (but DOM-useless) HTML id
		console.log(ctl.getLocalId());  							Component ID per aura:id - which can be found via cmp.find
		console.log($A.util.hasClass(ctl, 'slds-has-error'));		Class is on ctl's parent - not reachable
		console.log(ctl.isValid());									always true
		console.log(ctl.get("v.isValid"));							undefined
		console.log(ctl.get("v.isError"));							undefined
		console.log(ctl.get("v.hasError"));							undefined
		console.log(ctl.get("v.hasErrors"));						undefined
		console.log(ctl.get("v.errors"));							undefined
		console.log(event.currenttarget);							null - therefore getAttribute such as 'aria-describedby' n/a
		console.log(event.target);									null - therefore getAttribute such as 'aria-describedby' n/a
		
		*/

    },


	// Intercept form saves / submissions to add record type ID if needed
    doSubmit : function(cmp, event, helper) {

		// Set a mode marking that a save has been initiated - making save button unavailable
		// thus avoiding multiple clicks on save button
		cmp.set("v.OpMode", 'Saving');

    	try {
	        var rec = cmp.get("v.recordId");

	        // Allow this only for new records (where there is no record ID)
	        if (rec == null) {

	        	console.log('Autoform (' + cmp.get("v.ComponentId") + ') - Record ID is null on submission - continuing...');
	        
		    	// Suppress default Save and get form data
		        event.preventDefault();         
		        var flds = event.getParam("fields");
		        var rTyp = cmp.get("v.CurrentRecTypeId");
		        var dTyp = cmp.get("v.DefaultRecTypeId");


		        console.log('Autoform (' + cmp.get("v.ComponentId") + ') - Desired record type: ' + rTyp);

	                
	        	// Only act if we're aware of a record type
		        if (rTyp != '' || dTyp != '') {

		        	var currentType = flds["RecordTypeId"].value;
		        	console.log('Autoform (' + cmp.get("v.ComponentId") + ') - Form-specified record type: ' + currentType);

		        	// Only act if there is no type already specified
		        	if (currentType == null) {
		        	
		        		// Populate where required:			        			        	
						if (rTyp != '') {
							// Prefer current record type, if we found one during initialisation (from URL or design param)
							flds["RecordTypeId"] = rTyp; 
							
						} else if (dTyp != 'NULL') {
							// Otherwise, use default if not null
							flds["RecordTypeId"] = dTyp;  
						    console.log('Autoform - default record type will be used: ' + dTyp);	
						}		        		
		        	}
		        }	        	

		        // Now submit manually
		        cmp.find("recordEditForm").submit(flds);
	        }
	        
    	} catch (e) {
    		alert(helper.Internationalise(cmp, 'MessageErrorNoRecordType')); 
    		console.log('IHAutoform: doSubmit - error: ' + e);   	
    	}
    },


	// Cancel out of data edits - delegated to helper
	doCancel : function (cmp, event, helper) {
		helper.doCancel(cmp, event, helper);
	},
	

	// Inline-edit support: enter edting mode
	gotoEditMode : function (cmp, event, helper) {
	
		// Switch to edit mode
		cmp.set("v.DataMode", "Edit");
		
		// FOCUS on control whose edit pencil was clicked:
		// CANNOT YET DO ANYTHING WITH THIS (sigh!) - maybe one day!
		// Cannot use a dynamic aura:id
		// Inputfield does not support focus
		// Selecting control by NAME (which LUX does set) works via console, but not in component code...
		// THIS SHOULD BE SO SIMPLE!!!!
		var fld = event.target.getAttribute("aria-controls");
		cmp.set("v.CurrentFieldEditingControl", fld);
		
		
		/*
		var eCtls = cmp.find('editCtl');
		var i;
		var eCtl;
		
		for (i = 0; i < eCtls.length; i++) {
			eCtl = eCtls[i]; 
		
			if (eCtl.get("v.fieldName") == fld) {
				// This is the desired control - but it has no focus functionality!!!
			}
		}
		*/
		
				
		// Set a timer to adjust button bar positioning as required
		helper.setFloatCheckTimer(cmp, event, helper);
	},


///////////////////////////////////////////////////////////////////////////
// Accordion support tool support incl. additional guide logic
///////////////////////////////////////////////////////////////////////////
    
    // Expand / collapse an accordion section - part delegated
    toggleAccordionSection : function (cmp, event, helper) {
    
    	var opt = helper.toggleAccordion(cmp, event.currentTarget.id);
    	
    	if (opt == 'GuideList') {
    		// Initialise guide listing if this has not already been done
    		helper.initialiseGuideListing(cmp, false);
    	}
    	
    	if (opt == 'GuideSteps') {
			// Get available field information etc. if we haven't yet done so...						
			if (cmp.get("v.AvailableFields").length == 0) {
				helper.getFormDefTools(cmp, event);
			}						    		
    	}
    	
    },
    
    
	// Expand / collapse a form section
	toggleFormSection : function (cmp, event, helper) {
    	
    	// Do nothing if form section toggling is disabled
    	if (cmp.get("v.SuppressSectionToggles") == true) {
    		return;
    	}
    	
    	    	
		// Do nothing / disable toggle if any field in the section is dirty, as closing section
		// loses the value of any edits!
		// In edit mode only, check isDirty status of each of its child layout item objects
    	var idx = event.currentTarget.id;
    	var Lst = cmp.get("v.ListingItems");
    	var Sects = Lst[0].Sections;
    	
		if (cmp.get("v.DataMode") == 'Edit') {
			if (helper.sectionDirty(Sects[idx])) {
				return;
			}
		}

    	
    	Sects[idx].Expanded = ! Sects[idx].Expanded;
    	cmp.set("v.ListingItems", Lst);    	
    	
    	
    	// Log an interaction describing the state of all sections
    	//var act = cmp.get("c.logLUXInteraction");
		var desc = '';
		var D1 = String.fromCharCode(7);
		var D2 = String.fromCharCode(5);
		
		Sects.forEach (function (S) {
			desc += S.Section.label + D2;
			desc += S.Expanded + D1;
		});
		
		if (desc.length > 0) {
			desc = desc.substring(0, desc.length -1);
		}

        // act.setParams({ 
        // 	"iTyp" : "18",
		// 	"Description" : desc,
		// 	"IHContext" : cmp.get("v.OCode")
        // });         
        
                      
		// act.setCallback(this, function (response, cmp){ 
		// 	if (response.getState() === 'SUCCESS') {
		// 		// Do nothing if OK
		// 	} else {
		// 		console.log('Autoform - error logging section expand/collapse status');
		// 	}
		// });

        // Send action
       // $A.enqueueAction(act);
		

			helper.logLUXInteractions(cmp, 18, desc,cmp.get("v.OCode")).then((response) => {

			if (response.getState() === 'SUCCESS') {
				// Do nothing if OK
			} else {
				console.log('Autoform - error logging section expand/collapse status');
			}
		});
    	    	
    },
    
    
///////////////////////////////////////////////////////////////////////////
// "Callout" (inter-row mode specific content) handling
///////////////////////////////////////////////////////////////////////////
    
    // Issue an event advising that a field is active (so, perhaps, show help for it)
    requestHelp : function (cmp, event, helper) {	   	
    	var ctl = event.currentTarget;										    	
    	helper.requestHelp(cmp, event, helper, ctl);
    },
    
    
    // Hide waiting spinner on frame load completion
    hideTipBusy : function (cmp, event, helper) {
		var cnt = document.getElementById(cmp.get("v.CurrentFieldName") + '_CalloutContainer');
    	$A.util.removeClass(cnt, "IHTipPending");
    },
    
    
    // Hide callout on mouse out if required
    tipMouseOut : function (cmp, event, helper) {
        
        var opt = cmp.get("v.GlobalSettings").iahelp__CalloutClosureBehaviour__c;
        
        // Check required tip closure behaviour:
		// 1 = Close on element toggle only - NO mouse out behaviour
		// 2 = Close on mouse out only - NO toggle behaviour
		// 3 = Close on mouse out or element toggle
		
		if (opt != '1') {
			var cnt = document.getElementById(cmp.get("v.CurrentFieldName") + '_CalloutContainer');
            $A.util.addClass(cnt, 'slds-hide');
		}
		
    },
    

///////////////////////////////////////////////////////////////////////////
// Help enable support
///////////////////////////////////////////////////////////////////////////
    
    // Prevent the effect of bubbled click events when clicking certain controls
    nullifyStateToggle : function (cmp, event, helper) {
    
    	// As clicking a check box will bubble event to containing DIV,
    	// toggle state of the affected DIV here where necessary:
    	// This event will occur AFTER bubbled highlight toggle
    	
    	var chk = event.currentTarget;
    	var cnt = document.getElementById(chk.id.replace('_ChkDeleteTopic', '_FieldContainer'));

		// Checked or un-checked, we want "to be unhelped" mark on our container
		$A.util.addClass(cnt, 'ToBeUnhelped');

		// Ensure footer diags match our interventions
		cmp.set("v.Diags", helper.getHelpEnablingStats(cmp));
		
    },
    
    
    // Prevent the effect of bubbled click events when clicking certain controls
    nullifyClick : function (cmp, event, helper) {
    	event.stopPropagation();
    },
    
    
    // Handle clicks in the broad data input / output field area: treatment varies by mode
    formFieldAreaClick : function (cmp, event, helper) {

    	// Help enable = Toggle element to be helped / unhelped state
    	if (cmp.get("v.OpMode") == 'HelpEnable') {
	    	helper.toggleHighlight(cmp, event);
    	}
    	
    	// Guide enable = Toggle guide prompt editor
    	if (cmp.get("v.OpMode") == 'GuideEnable') {
    	
    		// Only show the editor if a guide has been selected
    		if (cmp.get("v.CurrentGuide") != '') {
		    	helper.toggleGuidePromptEditor(cmp, event, helper);
    		}
    	}
    	
    },
    

///////////////////////////////////////////////////////////////////////////
// My Form / Personal form support
///////////////////////////////////////////////////////////////////////////

    // Save changes to personal form definition
    savePersonalForm : function (cmp, event, helper) {
    	
    	// Log a "Personal Field Selection" interaction
		//var act = cmp.get("c.logLUXInteraction");
		var sels = cmp.get("v.SelectedFields");
		var desc = '';
		var D1 = '^';
		var diags;
		
		sels.forEach(function (v){
			desc += v + D1;
		});
		if (desc.length > 0) {desc = desc.substr(0, desc.length - 1);}
		
       /* act.setParams({ 
        	"iTyp" : "15",
			"Description" : desc,
			"IHContext" : cmp.get("v.OCode")
        });   */                    
	
	/*    act.setCallback(this, function (response, cmp){ 
			if (response.getState() === 'SUCCESS') {
				diags = response.getReturnValue();
				diags = helper.Internationalise(cmp, diags);
				
			} else {
				diags = 'ERR!';
			}
			
			cmp.set("v.Diags", diags);
			
			// Exit personal form design mode
			cmp.set("v.PersonalFormDef", false);
			
		});   */

        // Send action
       // $A.enqueueAction(act);

    		helper.logLUXInteractions(cmp, 15, desc, cmp.get("v.OCode")).then((response) => {
			//do nothing to response.
			if (response.getState() === 'SUCCESS') {
				diags = response.getReturnValue();
				diags = helper.Internationalise(cmp, diags);
				
			} else {
				diags = 'ERR!';
			}
			
			cmp.set("v.Diags", diags);
			
			// Exit personal form design mode
			cmp.set("v.PersonalFormDef", false);
			
		});
    },
    

///////////////////////////////////////////////////////////////////////////
// Guide enable/view support
///////////////////////////////////////////////////////////////////////////

	// Reflect selections made in guide steps list into on-screen presentation
	updateGuideSteps : function (cmp, event, helper) {
	
		// Note: as dualling list is bound, we need only amend on screen styling
		// (because effective list of selections is automatically kept)
		
		var containers = cmp.find("FieldContainer");
		var GFlds = cmp.get("v.GuidedFields");
		var prompts = cmp.find("GuidePromptEditor");		
		var elem;
		var ctl;
		var pos = 0;
		var appEvent;
		var EPCs = cmp.get("v.ExternalPromptControls");
		
		
		// Hide any prompt that no longer features in step list / has just been removed
		var doHide;
		var FName;

		prompts.forEach(function (p) {

			// Get field name of prompt
			FName = p.getElement().id.replace('_GuidePromptEditor_' + cmp.get("v.ComponentId"), '');
			
			// If this is not in list of selected fields, hide the prompt
			doHide = true;
			GFlds.forEach(function (F) {
				if (F == FName) {
					doHide = false;
				}
			});
			
			if (doHide == true) {
				
				// Hide the container DIV
				$A.util.addClass(p.getElement(), 'slds-hide');
				
				// Get and re-set the related control
				ctl = helper.getGuidePrompt(cmp, FName);
				if (ctl != null) {
					ctl.reInitialise();
				}
			}
		});		

		
		// Remove all step selected styling...
		containers.forEach(function (c) {
			$A.util.removeClass(c.getElement(), 'ToBeGuided');
		});
		
		// ... including for non-Autoform fields:
		// this must be done via a message, as we cannot directly affect their markup:
		// Remove styling from all non-autoform prompts as we can add back to those that remain in the guide, below:
		EPCs.forEach(function (Ext){
			appEvent = $A.get("e.c:evtPassThrough");
			appEvent.setParams({"SourceComponent": cmp.get("v.ComponentId")});
			appEvent.setParams({"ActionCode": 'UnMarkGuideStep'});
			appEvent.setParams({"Parameters": Ext});			
			appEvent.fire();
		});
		
		
		// Add back style for our current selections
		GFlds.forEach(function (F) {

			elem = document.getElementById(F + '_FieldContainer_' + cmp.get("v.ComponentId"));
			
			// Only do this for guide editing mode
			if (cmp.get("v.OpMode") == 'GuideEnable') {
			
				// Autoform elements
				$A.util.addClass(elem, 'ToBeGuided');
				
				// Non-autoform elements				
				appEvent = $A.get("e.c:evtPassThrough");
				appEvent.setParams({"SourceComponent": cmp.get("v.ComponentId")});
				appEvent.setParams({"ActionCode": 'MarkGuideStep'});
				appEvent.setParams({"Parameters": F});			
				appEvent.fire();
			}
			

			// Re-number steps in order
			pos += 1;
			ctl = helper.getGuidePrompt(cmp, F);
			if (ctl != null) {
				ctl.set("v.CurrentLocalStep", pos);
				ctl.set("v.TotalLocalSteps", GFlds.length);
			}
		});
		
		// Note the fact that a change has occurred to a guide if actually in guide enable mode
		if (cmp.get("v.OpMode") == 'GuideEnable') {
		
			// Only act when steps differ  from the original set
			var GFlds = cmp.get("v.GuidedFields");			// Steps currently in guide
			var OFlds = cmp.get("v.OriginalGuideEntries");	// Entries originally in guide
			var stepsCurrent = '';							// Comparison / test string
			var stepsOrig = '';								// Comparison / test string
			var PromptCtl;									// A guide prompt control
			var RLE;										// Reading list / guide entry associated with prompt
					
			OFlds.forEach(function (O) {
				stepsOrig += O.Id + '^';
			});
			
			GFlds.forEach(function (F) {
				PromptCtl = helper.getGuidePrompt(cmp, F);
				if (PromptCtl != null) {
					RLE = PromptCtl.get("v.CurrentRecord");				
					if (RLE != null) {
						stepsCurrent += RLE.Id;
					}						
				}
				
				stepsCurrent += '^';
			});
			
			// We've checked existence / order of steps for dirtiness, but must also
			// take into account changes made within existing steps which remain in the same order,
			// in which case a separate prompt dirty flag will have been set elsewhere...
			cmp.set("v.isGuideDirty", stepsOrig != stepsCurrent || cmp.get("v.isGuidePromptDirty") == true);	
		}
	},
	
	
	// Save amendments to the selected Guide - delegated to helper
	saveGuide : function (cmp, event, helper) {
		helper.saveGuide(cmp, event, helper);	
	},
	
	
	// Cancel changes to the guide
	cancelGuideChanges : function (cmp, event, helper) {
		
		// To do this, proceed effectively as per returning to view mode from GE mode
		// having first set guide dirty = false (so no backout prompt is offered)
		cmp.set("v.isGuideDirty", false);
		
        var appEvent = $A.get("e.c:evtPassThrough");
        appEvent.setParams({"SourceComponent": cmp.get("v.ComponentId")});
        appEvent.setParams({"ActionCode": 'AFModeView'});
        appEvent.setParams({"Parameters": ''});
        appEvent.fire();
		
	},
	
///////////////////////////////////////////////////////////////////////////
// Other incl. mode changes
///////////////////////////////////////////////////////////////////////////

	// Set member data that can be used to mark helped elements in various modes (instead of icons)
	setOpModeStyling : function (cmp, event, helper) {
	
		switch (cmp.get("v.OpMode")) {
			
			case 'Reconfigure':
				cmp.set("v.OpModeIconClass", 'fa-wrench');
				break;
			
			case 'Statistics':
				cmp.set("v.OpModeIconClass", 'fa-bar-chart');
				break;
				
			default:
				cmp.set("v.OpModeIconClass", 'fa-question-circle');
				break;
		}
	},

        
    // Handle pass-throughs - e.g., switch into / out of form definition editing mode
    handlePassThroughs : function (cmp, event, helper) {
    	
        var act = event.getParam("ActionCode");
        var parms = event.getParam("Parameters");
        var src = event.getParam("SourceComponent");
        var isModeChange = false;
		var GLst = cmp.find('IHAFGuideList');
		var sect = cmp.find('GuideList_Section'); 
		var twst = cmp.find('GuideList_Twisty'); 
		
		// To avoid some unwanted event propagation, we take note of whether or not we are the AF's own AF / guide listing
		var isSubForm = cmp.get("v.ComponentId").startsWith('AFSelectedGuide_');		

		console.log('Autoform "' + cmp.get("v.ComponentId") + '" (Data mode = ' + cmp.get("v.DataMode") + ') - pass through received: Source=' + src + ': Action=' + act + ': Parameters=' + parms);


		//.........................................................................
        // In certain cases, only respond to our own control:
        //.........................................................................

		if (helper.eventIsOurOwn(cmp, event)) {

        	switch (act) {

				case 'AFRecordDiags' :
					// Show a message providing some key information about the record and layout being viewed
					var msg = '';
					var CR = '  ...  ';
				
					msg += 'Object Label: ' + cmp.get("v.OLabel") + CR;
					msg += 'Object API Name: ' + cmp.get("v.OName") + CR;
					msg += 'Record ID: ' + cmp.get("v.recordId") + CR;
					msg += 'Record Type ID: ' + cmp.get("v.CurrentRecTypeId") + CR;
					msg += 'Layout Name: ' + cmp.get("v.LayoutName");
				
		            var src = 'c:IHAlert';
			        var aMap = {
			        	"Height": -1,   
			        	"Title" : "",
			        	"Message" : msg,
			        	"Image" : "/resource/iahelp__IHSupportMaterials/img/StockImages/013B.svg", 
			        	"ToolContext" : "AlertOKOnly",
			        	"Style" : "Two Column",
		                "ComponentId" : cmp.get("v.ComponentId")
				      };
				    
				    helper.doDialogue('ttl', 'Alert', src, aMap, -1, false, false, false, cmp, false);
					break;

				case 'AFPersonalFormEdit' :
					// Show panel allowing editing of personal form / favourite fields
					cmp.set("v.PersonalFormDef", true);		
					
					// Get available field information etc. if we haven't yet done so...						
					if (cmp.get("v.AvailableFields").length == 0) {
						helper.getFormDefTools(cmp, event);
					}						
					break;

/*
				case 'AFDensityComfy' :
				case 'AFDensityCompact' :					
					// Set display density as requested
					
					var DDMode;
					
					if (act == 'AFDensityComfy') {
						DDMode = 'Comfy';									
					}
					
					if (act == 'AFDensityCompact') {
						DDMode = 'Compact';		
					}
					cmp.set("v.DisplayDensity", DDMode);
					
					
			    	// Log a "Display Density" interaction
					var act = cmp.get("c.logLUXInteraction");
					var diags;
							
			        act.setParams({ 
			        	"iTyp" : "17",
						"Description" : DDMode,
						"IHContext" : cmp.get("v.OCode")
			        });                       
				
					act.setCallback(this, function (response, cmp){ 
						if (response.getState() === 'SUCCESS') {
							diags = helper.Internationalise(cmp, response.getReturnValue());
							
						} else {
							diags = 'ERR!';
						}
						
						cmp.set("v.Diags", diags);
					});
			
			        // Send action
			        $A.enqueueAction(act);					
							
					break;
*/
        	        						
				case 'AFModePersonalForm' :	
					// Toggle personal form area (as currently defined) on and off:
					// First, exit personal form design mode, if we happen to be in that mode
					cmp.set("v.PersonalFormDef", false);
					cmp.set("v.PersonalFormView", ! cmp.get("v.PersonalFormView"));			
					
			    	
					//var act = cmp.get("c.logLUXInteraction");
					var diags;
							
			     /*   act.setParams({ 
			        	"iTyp" : "16",
						"Description" : '' + cmp.get("v.PersonalFormView"),
						"IHContext" : cmp.get("v.OCode")
			        });        */                
				
				/*	act.setCallback(this, function (response, cmp){ 
						if (response.getState() === 'SUCCESS') {
							diags = response.getReturnValue();
							
						} else {
							diags = 'ERR!';
						}
						
						cmp.set("v.Diags", diags);
					}); */
			
			        // Send action
			      //  $A.enqueueAction(act);	
					
					// Log a "Personal Form Visibility" interaction
					helper.logLUXInteractions(cmp, 16, '' + cmp.get("v.PersonalFormView"),  cmp.get("v.OCode")).then((response) => {
			  			if (response.getState() === 'SUCCESS') {
							diags = response.getReturnValue();
							
						} else {
							diags = 'ERR!';
						}
						
						cmp.set("v.Diags", diags);
					});

					break;

				case 'AFModeView' :
					// Enter help view operational mode: may need to take action on doing so...	
					if (cmp.get("v.OpMode") == 'HelpEnable') {
					
						// On leaving help enable mode, check whether changes were made...
						var toHelp = [];
						var toUnhelp = [];
						var containers = cmp.find("FieldContainer");
						
						containers.forEach(function (c) {
							if ($A.util.hasClass(c.getElement(), 'ToBeHelped')) {
								toHelp.push(c.getElement());
							}
							
							if ($A.util.hasClass(c.getElement(), 'ToBeUnhelped')) {
								toUnhelp.push(c.getElement());
							}
						});
						
						var elemsC = [];
						var elemsD = [];
						var fld;
						var txtHTID;
						var chkDelTopic;
						var fAPI;
						var HTID;
						var i;		
						var D1 = cmp.get("v.Delimiter");
						var CRoot = cmp.get("v.CommunityRoot");
						
						// NOTE: here we must NOT ignore a community root that is blank / sent to us as 'null' - as we
						// need this to be part of page layout ID to differntiate from internal layouts						
						if (CRoot != '') {CRoot += '/';}
									
						// If changes were made, take special action to save them
						if (toHelp.length + toUnhelp.length > 0) {
						
							// Offer a back out of save
							var HEStats = helper.getHelpEnablingStats(cmp);
							if (! confirm(helper.Internationalise(cmp, 'MessageSaveDialogueChanges') + '\n\n' + HEStats)) {
								helper.initialiseForm(cmp, event);
								return;
							}		        				    		
							
						
							// Extract field names of elements from highlighted items:
							// NB: for this release, help is effectively for "field" type elements only
							for (i=0; i<toHelp.length; i++) {

								// This is the field API name - but we need its label (identifier)...
								fAPI = toHelp[i].id.replace('_FieldContainer_' + cmp.get("v.ComponentId"), '');

								// ... so look this up in the listing data we were supplied as the form was built							
								fld = helper.getIHLI(cmp, fAPI);
								fld = fld.FieldLabel;
								console.log('IHAutoForm: Helping ' + fld);	
								
								// Check which topic should be used - if user has specified an existing one
								txtHTID = document.getElementById(fAPI + '_txtExistingTopic');
								HTID = txtHTID.value;
								if (HTID == '') {HTID = 'null';}
								console.log('IHAutoForm: associated topic is: ' + HTID);	
								
								elemsC.push(fld + D1 + 'FIELD' + D1 + HTID);
							}


							for (i=0; i<toUnhelp.length; i++) {
								
								// This is the field API name - but we need its helped element record id... 
								// ... so look this up in the listing data we were supplied as the form was built
								// Also note associated help topic
								fAPI = toUnhelp[i].id.replace('_FieldContainer_' + cmp.get("v.ComponentId"), '');
								fld = helper.getIHLI(cmp, fAPI);
								
								// Check whether we're deleting the associated topic
								chkDelTopic = document.getElementById(fAPI + '_ChkDeleteTopic');
								
								HTID = 'null';							
								if (chkDelTopic.checked == true) {
									if (fld.Topic + '' != 'undefined') {
										HTID = fld.Topic.Id;
									}
								}

								fld = fld.Element.Id;
								elemsD.push(fld + D1 + HTID);

								console.log('IHAutoForm: Un-helping ' + fld);	
								console.log('IHAutoForm: Topic to delete: ' + HTID);	
							}

							var act = cmp.get("c.CCASaveChanges");

					        act.setParams({ 
					        	"oCode" : CRoot + cmp.get("v.OCode"),
					            "Opts" : "1", 
					            "elemsC" : elemsC,
					            "elemsD" : elemsD,
					        });                       
						                
					        // Add callback to process returned results
					        act.setCallback(this, function (response, cmp){
        
					        	// On completion, re-initialise form if successful and report results
					        	if (response.getState() == 'SUCCESS') {
					        		helper.initialiseForm(cmp, event);
									helper.reportResults(cmp, helper, response.getReturnValue());					        		
					        		
					        	} else {
					        		cmp.set("v.Diags", "ERR!");
					        	}
					        	
							});
							
				        	$A.enqueueAction(act);
						}
					}
					
					
					if (cmp.get("v.OpMode") == 'GuideEnable') {
			            // On leaving guide enable mode, offer back-out if dirty prior to switching mode, which will lose changes
			            if (cmp.get('v.isGuideDirty') == true) {
			        		if (confirm(helper.Internationalise(cmp, '[QAMMessageDirtyWarning]')) == false) {
			                    return;
			                }
			            }
					
			            // On leaving guide enable mode, hide any prompts
						var prompts = cmp.find("GuidePromptEditor");
						prompts.forEach(function (P){
							$A.util.addClass(P, 'slds-hide');
						});
							
							
						// Set all guide prompts to view mode
						var promptCtls = cmp.find("GuidePromptCtl");
						promptCtls.forEach(function (P){
							P.set("v.OpMode", "View");
						});
						

						// Re-set to no selected guide
						cmp.set("v.CurrentGuide", '');
						helper.setSelectedRow(GLst, '');		    		
						
						// Close guides accordion
						$A.util.removeClass(sect, 'slds-is-open');
						$A.util.removeClass(twst, 'nodeExpanded');


						// Revert to respecting user's choice of form section toggles		
						cmp.set("v.SuppressSectionToggles", false);


						// Re-set form
						helper.initialiseForm(cmp, event);
					}
					
					// Re-set to view mode, whether or not we had to fully re-initialise form
					helper.setViewMode(cmp, event);		
					isModeChange = true; 	
					break;

				case 'AFModeStatistics' :	
					// Enter stats operational mode
					cmp.set("v.OpMode", "Statistics");
					cmp.set("v.OpStyle", "IHHelpStats");	
					cmp.set("v.OpToolTip", helper.Internationalise(cmp, "TipStatistics"));			
					isModeChange = true;				
					break;

				case 'AFModeReconfigure' :	
					// Enter re-configure operational mode
					cmp.set("v.OpMode", "Reconfigure");
					cmp.set("v.OpStyle", "IHHelpRecon");	
					cmp.set("v.OpToolTip", helper.Internationalise(cmp, "TipReconfigure"));			
					isModeChange = true;				
					break;

				case 'AFModeHelpEnable' :	
					// Enter Help Enable operational mode
					cmp.set("v.OpMode", "HelpEnable");
					cmp.set("v.OpStyle", "HelpableSFElement");	
					cmp.set("v.OpToolTip", "");			
					isModeChange = true;				
					break;

				case 'AFModeGuideEnable' :	
					// Enter Guide Enable operational mode
					cmp.set("v.OpMode", "GuideEnable");
					cmp.set("v.OpToolTip", "");		

					// This means guides are in play, so use this as a cue to render (hidden) prompts
					cmp.set("v.GuidesInUse", true);
									
					// Set all guide prompts to allow edit mode where appropriate: also set some key translations
					var promptCtls = cmp.find("GuidePromptCtl");
					promptCtls.forEach(function (P){
						P.set("v.AllowEdits", cmp.get("v.isAuthor"));
						
						// NB: we set these in this way where NOT referenced in markup (i.e., used only in code)
						// as this reduces the weight of member data...
						P.set("v.QAMMessageGuideStepsCompleted", helper.Internationalise(cmp, '[QAMMessageGuideStepsCompleted]'));
					});


					// Initialise guide listing if this has not already been done
					helper.initialiseGuideListing(cmp, false);	
										
					// Get available field information etc. if this has not already been done						
					if (cmp.get("v.AvailableFields").length == 0) {
						helper.getFormDefTools(cmp, event);
					}				
					
					
					// Entry to guide enable mode should ignore / re-set any guide previously viewed on this screen
					cmp.set("v.CurrentGuide", '');
					helper.setSelectedRow(GLst, '');		    		
					
					// Entry to GE mode should pop guides accordion open, if not already
					$A.util.addClass(sect, 'slds-is-open');
					$A.util.addClass(twst, 'nodeExpanded');

					
					isModeChange = true;				
					break;	
					
					
			case 'AFRefreshMetadata' :
			case 'AFRefreshMetadataAllRTypes' :
				// Delete, then re-obtain, layout assignment metadata for the current context / object:
				// Do this optionally for all record types, differentiated by action code...
				
				var objSvr = '';
				var customObjId = '';
				var objSought = '';
				var recTypeSought = '';
				var currentRType;
				var obj;
				var objOut = [];
				var JSONOut;
				var deletedCount = 0;
				var i;
			
				var objInfoCall = cmp.get("c.getObjectInfo");					// Call 1: get object data for current record
				var MDCall = cmp.get("c.getAllStoredProfileLayouts");			// Call 2: get all stored metadata records
				var MDSaveCall = cmp.get("c.chunkAndStoreMetadata");			// Call 3: save amended metadata records
				
			    
			    objInfoCall.setParams({             
			        "RecordId" : cmp.get("v.recordId"),
			    });                       	
				
			
				// To do this, get details of the object we are on
				objInfoCall.setCallback(this, function (response, cmp){
				
					if (response.getState() == 'SUCCESS') {
							
						try {			
							obj = JSON.parse(response.getReturnValue());
							
							// At this stage, we have a collection of name / value pairs representing
							// object information (object API name, custom object ID, record type ID): extract these key items here...
					
							for (i=0; i < obj.length; i++) {
							
								// Object API name derived from the record ID passed to server
								// (should be the same as out sObjectName / objSought - but offered here as a cross-check)
								if (obj[i].ValueSet == 'LayoutSearchKeys' && obj[i].Name == 'CustomObjectAPIName') {
									objSvr = obj[i].Value;
								}
								
								// The custom object ID (ProfileLayout.TableEnumOrId) derived from this object name, if form is for a custom object
								if (obj[i].ValueSet == 'LayoutSearchKeys' && obj[i].Name == 'CustomObjectId') {
									customObjId = obj[i].Value;
								}
								
								// Record type
								if (obj[i].ValueSet == 'LayoutSearchKeys' && obj[i].Name == 'RecordTypeId') {
									recTypeSought = obj[i].Value;
									console.log('Auto-form metadata refresh: record type (where relevant): ' + deletedCount);

									// A return of 'NULL' means no type info was found for one of several reasons:
									// Adjust this here to resemble what we'll find in stored layout JSON
									if (recTypeSought == 'NULL') {recTypeSought = 'null';}									
								}
								
							}
							
							console.log('Autoform - metadata refresh: affected object = "' + objSvr + '"');
							console.log('Autoform - metadata refresh: custom object ID = "' + customObjId + '"');
							
										
							if (objSvr == '') {
								// If we get no info about the object we are on, we cannot refresh its metadata
								alert(helper.Internationalise(cmp, 'MessageGenericError') + ' (Autoform - metadata refresh): Info call returned no object details');
								return;
							}
							
							// When we get currently stored metadata, we will be looking to delete records for a "TableOrEnumId":
							// Set this here, depending on whether current object is custom...
							if (customObjId != '') {
								objSought = customObjId;
							} else {
								objSought = objSvr;
							}
							
			
							// If we get this far, we can continue to request all currently stored layout metadata...
						    MDCall.setCallback(this, function (response, cmp){	
						    
								if (response.getState() === 'SUCCESS') {
									
						            try {
						            	// Turn this to objects
										obj = JSON.parse(response.getReturnValue());			
										console.log('Autoform - metadata refresh: object sought in profile layouts = "' + objSought + '"');
										console.log('Autoform - metadata refresh: all stored profile layouts count = ' + obj.length);
										
										// Delete records for current object, all or only for current record type depending on requested action
										for (i=0; i < obj.length; i++) {
										
											if (obj[i].TableEnumOrId != objSought) {
												// Current metadata row is NOT for the object being refreshed: Keep this record
												objOut.push (obj[i]);
												
											} else {
												// Object metadata in this record applies to the object we're interested in
												// Check by record type if required:

												if (act == 'AFRefreshMetadataAllRTypes') {
													// If refreshing ALL types for the current object, delete with no further checks:
													// Fail to keep / mark as deleted
													deletedCount += 1;	
													
												} else {												
													// If NOT (delete only current type), check record type one is on here
													currentRType = obj[i].RecordTypeId;
													
													if (currentRType == null) {
														currentRType = 'null';
													}
													if (currentRType.length > 15) {
														currentRType = currentRType.substring(0,15);
													}
										
													if (currentRType == recTypeSought) {
														// If this is the desired record type, delete: 
														// Fail to keep / mark as deleted
														deletedCount += 1;
												
													} else {
														// Keep - add to output
														objOut.push (obj[i]);
													}
												}
											}
										}
										
										console.log('Auto-form metadata refresh: ' + deletedCount + ' rows of existing metadata removed prior to overwriting');
			
			
										// Save this JSON back
										JSONOut = JSON.stringify(objOut);
										
										MDSaveCall.setParams({             
											"MetadataJSON" : JSONOut,
											"MetadataType" : "GetSFPageLayouts",
										});                   
										
									    MDSaveCall.setCallback(this, function (response, cmp){	
									    
											if (response.getState() === 'SUCCESS') {
			
												// Then, use VF page, as above, to get and store metadata for this object
												console.log('Auto-form metadata refresh: configuration deleted - summoning VF page to recreate...');
												
												var CRoot = cmp.get('v.CommunityRoot');								// Community info, if required

												// If root is 'null', this can be ignored in most cases
												if (CRoot + '' == 'null') {CRoot = '';}
												if (CRoot != '') {CRoot = '/' + CRoot;}    	

												/*
												ADDED A FURTHER OP HERE, BASED ON EXISTING OP=1:
												IF DELETING CURRENT TYPE ONLY, CARRY ON WITH OP1
												IF DELETING ALL TYPES, OP3 MUST DIFFERENTIATE ON SERVER TO GET ALL TYPES
												*/											 	
												var src;
												if (act == 'AFRefreshMetadataAllRTypes') {
													src = CRoot + "/apex/iahelp__IHLUXOpHandler?Op=3&recordId=" + cmp.get("v.recordId");
												} else {
													src = CRoot + "/apex/iahelp__IHLUXOpHandler?Op=1&recordId=" + cmp.get("v.recordId");
												}

			
												// NB: we should already have the translation code here as this was on the tool clicked to get to this point
												helper.doDialogue('AFRefreshMetadata', 'VF', src, null, 100, false, false, false, cmp, true);
											
											} else {
												// Failure getting all stored profile layouts
												alert(helper.Internationalise(cmp, 'MessageGenericError') + ' (Autoform - metadata refresh): chunk and store call: error sending call');
							
											}
										});	// End MDSave / save updated JSON call
										$A.enqueueAction(MDSaveCall);
										
						            } catch (e) {
										// Error processing layout metadata JSON
										alert(helper.Internationalise(cmp, 'MessageGenericError') + ' (Autoform - metadata refresh): get stored profile layouts call - Error parsing the following return value (' + e + '): ' + response.getReturnValue());
			
						                return;
						            }
									
								} else {
									// Failure getting all stored profile layouts
									alert(helper.Internationalise(cmp, 'MessageGenericError') + ' (Autoform - metadata refresh): get stored profile layouts call: error sending call');
							
								}
								
						    
						    });	// End MDCall / metadata seeking callback
						    $A.enqueueAction(MDCall);
			
							
						} catch (e) {
							// Error processing return of object info call
							alert(helper.Internationalise(cmp, 'MessageGenericError') + ' (Autoform - metadata refresh): get object info call - Error parsing the following return value (' + e + '): ' + response.getReturnValue());
			
						}
					
					} else {
						// Failure getting object info
						alert(helper.Internationalise(cmp, 'MessageGenericError') + ' (Autoform - metadata refresh): get object info call: error sending call');
								
					}
				
				
				});	// end objInfo / object info callback
			    $A.enqueueAction(objInfoCall);
			    
				break; 
	
			}
			
			
			// On any mode change, hide any open callout container and "forget" current field as we'll need to 
			// navigate frame in all cases
			if (isModeChange == true) {
				helper.closeActiveCallout(cmp, event);
			}
			
		}	// End if source is ourselves
		
		
		//.........................................................................
		// In some cases, respond to our child components: individual guide prompts
		//.........................................................................
		
		if (src != null) { 
			if (src + '' != 'undefined') {
				if (src.indexOf('_GuidePromptCtl') != '-1') {
				
					switch (act) {
						case 'DialogueRequestClose' :
							// Prompt closure request - e.g., from clicking prompt's "X"
							var prompt = document.getElementById(src.replace('_GuidePromptCtl', '_GuidePromptEditor'));
							$A.util.addClass(prompt, 'slds-hide');				
							event.stopPropagation();
							
							// In "view" mode, this should mean leaving the guide altogether / remove guide styling
							if (cmp.get("v.OpMode") == 'View') {
								helper.clearAllGuideSteps(cmp);
								
								// Revert to respecting user's choice of form section toggles		
								cmp.set("v.SuppressSectionToggles", false);
							}
							
							break;
							
						case 'NavToGuideStep' :					
							// We'll have been supplied a 1-based step number: we must
							// translate this to the appropriate element (field name)
							var idx = parms -1;
							var GFlds = cmp.get("v.GuidedFields");
							var fld = GFlds[idx];
		
							helper.showGuidePrompt(cmp, helper, fld, idx);			
							break;
							
						case 'CloseGuide' :
							helper.clearAllGuideSteps(cmp);

							// Revert to respecting user's choice of form section toggles		
							cmp.set("v.SuppressSectionToggles", false);

							// Close all callouts (in cases where a step had 'show callout' checked)
							helper.hideAllCallouts(cmp, event);
		
							break;
							
						case 'PromptDirty' :
							// Make doubly sure this is one of our prompts...
										
// This should be inside a further check to make sure it was OUR callout that was dirty.
							if (parms == this || 1==1) {
								cmp.set("v.isGuideDirty", true);
								cmp.set("v.isGuidePromptDirty", true);
							}
							
							
							break;
					}			
				}
			}
		}
		
	
		//.........................................................................
		// In some cases, respond to our child components: guide selection list
		//.........................................................................
		
		if (src == 'AFGuideList_' + cmp.get("v.ComponentId")) {
			switch (act) {

			    case 'AFAddGuide':
			    	// Add a new reading list (guide) record and set this as current record
			    	helper.newGuide(cmp, event, helper);    	
			    	break;
			    	
				case 'AFDeleteGuide':
					// Delete guide whose listing tool was clicked - delegated
					if (confirm(helper.Internationalise(cmp, 'MessageDeleteWarning'))) {
						var Ps = parms.split('^');
						var GID = Ps[0];
						helper.deleteGuide(cmp, event, helper, GID); 
					}	
					break;			    	

				case 'AFShareGuide':
					// Show a share guide link - delegated
					var Ps = parms.split('^');
					var GID = Ps[0];
					helper.showShareGuideLink(cmp, event, helper, GID); 
					break;			    	
			
				case 'SelectGuideToEnable' :
					// Select the guide we wish to edit in GE mode or run in view mode
					// NB: see getTools / Guides action: parameters in these cases set to Guide Name ^ RL (Guide) Type
					// Listing click default / passthrough generation prepends row (guide) ID onto this...
					
					var Ps = parms.split('^');
					var GID = Ps[0];
					var RLType = parseInt(Ps[2]);
					var obj;
					var I;
					var fld;
					var nextGuide = '';
					var GP = cmp.find("GuideProperties");	
					var cmpDef;
					var item;
					
					// Close any open callouts
					helper.closeActiveCallout(cmp, event);
					
					
		            // Offer back-out if dirty prior to switching guides, which will lose changes
		            if (cmp.get('v.isGuideDirty') == true) {
		        		if (confirm(helper.Internationalise(cmp, '[QAMMessageDirtyWarning]')) == false) {
		                    return;
		                }
		            }
					
									
					// Set title to reflect GE mode and selected guide, where applicable
					if (cmp.get("v.OpMode") == 'GuideEnable') {
						cmp.set("v.Title", helper.Internationalise(cmp, 'ToolLabelGuideEnable') + ': ' + Ps[1]);
						
						// With a guide in play, we can allow editing of prompts if we're in GE mode
						cmp.set("v.OpStyle", "GuidableSFElement");			      
						
						// Set up guide properties tab in the tools accordion
						cmpDef = 'c:IHAutoForm~Height¬280|OpMode¬View|sObjectName¬HelpReadingList__c|SuppressHeader¬true|SuppressFooter¬true|SuppressModeTools¬true|OnSaveAction¬Report only';
						cmpDef += '|ComponentId¬AFSelectedGuide_' + cmp.get("v.ComponentId");
						
						// Fix the name of the layout we want here - avoiding additional searches
						cmpDef += '|LayoutName¬iahelp__HelpReadingList__c-iahelp__Help Reading List Layout';						
						cmpDef += '|recordId¬' + GID;
						
						GP.set("v.ComponentDef", '');
						GP.set("v.ComponentDef", cmpDef);
						GP.reInitialise();			
						
						
						// Issue a further pass-through to advise those listening
						// that guide selection occurred whilst in guide enable mode - i.e., they too may need 
						// to enter GE Mode		
						
						var appEvent = $A.get("e.c:evtPassThrough");
						appEvent.setParams({"SourceComponent": cmp.get("v.ComponentId")});
						appEvent.setParams({"ActionCode": 'GEModeEntry'});
						appEvent.fire();
						
					}
					
					// For any guide ops, we need to expand form sections, or we may not 
					// be able to find the desired guided fields
					helper.logAdvancedDiags(cmp, 'Auto-form Select Guide To Enable: expanding form sections...');
					cmp.set("v.SuppressSectionToggles", true);
				
					
					// Get details of the selected guide
					var act = cmp.get("c.getGuideSteps");

			        act.setParams({ 
			        	"GuideId" : GID,
			        });                       
						                
			        // Add callback to process returned results
			        act.setCallback(this, function (response, cmp){

			        	// On completion, re-initialise form if successful
			        	if (response.getState() == 'SUCCESS') {

		        			helper.logAdvancedDiags(cmp, 'Auto-form Select Guide To Enable: Get Guide Steps returned successfully: ' + response.getReturnValue());

			        		// Return value is JSON - parse this into objects for aura iteration...
			        		// NB: cannot use super's process tools here as handling is specialised			        	
				            try {
								obj = JSON.parse(response.getReturnValue());
				            } catch (e) {
				                cmp.set("v.Diags", "Auto-form - Error parsing the following return value (" + e + "): " + response.getReturnValue());
				                helper.logAdvancedDiags(cmp, "Auto-form - Error parsing the following return value (" + e + "): " + response.getReturnValue());
				                return;
				            }
				            
				            // Mark the selected guide in the list
				            helper.setSelectedRow(cmp, GID);
				            
				            // Keep a note of the guide in play and its type
				            cmp.set("v.CurrentGuide", GID);
				            cmp.set("v.CurrentGuideType", RLType);
				            
				            				            
				            // Keep a note of its steps in their un-edited form
				            cmp.set("v.OriginalGuideEntries", obj);
				            
				            
							// Clear out any previously marked steps etc.
							helper.clearAllGuideSteps(cmp);

		
							// Look up entries in our collection and add them to selected steps							
							obj.forEach(function (RLE){ 
							
								I = null;
								if (RLE.iahelp__HelpTopic__r + '' != 'undefined') {
									if (RLE.iahelp__HelpTopic__r.iahelp__GuidedElement__r + '' != 'undefined') {
										if (RLE.iahelp__HelpTopic__r.iahelp__GuidedElement__r.iahelp__Identifier__c + '' != 'undefined') {
											I = helper.getIHLIByLabel(cmp, RLE.iahelp__HelpTopic__r.iahelp__GuidedElement__r.iahelp__Identifier__c);
										}
									}

									
									// Check for steps that imply the need to navigate across pages / to a new guide.
									// If such steps are found, log the fact that, when all steps on this page are complete,
									// we should navigate on to complete the whole guide...									
									if (RLE.iahelp__HelpTopic__r.iahelp__GuideStepMode__c + '' != 'undefined') {
										if (RLE.iahelp__HelpTopic__r.iahelp__GuideStepMode__c == 'Automatic') {
											if (RLE.iahelp__HelpTopic__r.iahelp__GuidedRecord__c + '' != 'undefined') {
												if (RLE.iahelp__HelpTopic__r.iahelp__GuidedRecord__c + '' != '' && RLE.iahelp__HelpTopic__r.iahelp__GuidedRecord__c != null) {
												
													// Non-blank value is assumed to be instructions for next guide:
													// However, this must be in the correct form...
													if (RLE.iahelp__HelpTopic__r.iahelp__GuidedRecord__c.indexOf('^') != -1) {
														console.log('Auto-form pass throughs / SelectGuideToEnable: Non-local step: ' + RLE.iahelp__HelpTopic__r.iahelp__GuidedRecord__c);
														nextGuide = RLE.iahelp__HelpTopic__r.iahelp__GuidedRecord__c;
													}
												}
											}
										}
									}

								}
								
								if (I != null) {
									// Locate this field and mark as part of guide
									// REMEMBER: return value of callback is RL entries - NOT IHLayoutItems!
									// Our RLEs are guide step topics plus their related helped elements - which have IDENTIFIERS not field names
									// We've now looked up identifiers to link these to form elements (which have API field names).
									// We need to pass BOTH in logging guide step - to attach to a form FIELD but also to provide knowledge of prompt topic
									console.log('Autoform - Select Guide to Enable: Logging FIELD entry ' + RLE.iahelp__HelpTopic__r.iahelp__GuidedElement__r.iahelp__Identifier__c);
									helper.logGuideStepAF(cmp, I, RLE);
									
								} else {
									// If we couldn't find the field, assume it's an 'off form'
									// step and log it in that way...
									console.log('Autoform - Select Guide to Enable: Logging NON-field entry ' + RLE.iahelp__HelpTopic__r.iahelp__GuidedElement__r.iahelp__Identifier__c);
									helper.logGuideStepPD(cmp, RLE.iahelp__HelpTopic__r.iahelp__GuidedElement__r.iahelp__Identifier__c);
								}
								
							});
							

				            // Set all our guide editor controls to the correct guide mode and note total number of steps
				            // (Individual step numbering handled elsewhere)
							var promptCtls = cmp.find("GuidePromptCtl");
							
							promptCtls.forEach(function (P){
								P.set("v.ReadingListType", RLType);
								P.set("v.TotalLocalSteps", parseInt(cmp.get("v.GuidedFields").length));		
								P.set("v.QAMMessageGuideStepsCompleted", helper.Internationalise(cmp, '[QAMMessageGuideStepsCompleted]'));
								
								// Advise prompts of next guide, if relevant
								if (nextGuide != '') {
									P.set("v.NextGuide", nextGuide);
								}

								// Make sure we only show guide step editing switch when in GE mode - even if we have the 
								// rights to edit, we don't want to see this when simply viewing a guide
								if (cmp.get("v.OpMode") == 'GuideEnable') {
									P.set("v.AllowEdits", cmp.get("v.isAuthor"));	
								} else {
									P.set("v.AllowEdits", false);	
								}

							});


							// If we're viewing a guide as opposed to editing, cue the first step
							if (cmp.get("v.OpMode") == 'View') {
								var GFlds = cmp.get("v.GuidedFields");

								// DON'T KNOW WHY THIS ENDS UP BEING - BRIEFLY - UNDEFINED
								// WHEN NAVIGATING VIA NAV LUX TAG (NOT SO IF ARRIVAL IS
								// SIMPLY VIA URL!)
								if (GFlds[0] + '' != 'undefined') {
									helper.showGuidePrompt(cmp, helper, GFlds[0], 0);
								}								
								
								// Toggle accordion shut
								helper.closeAccordion(cmp, 'GuideList_Summary');
							}

			        	} else {
			        		cmp.set("v.Diags", "ERR!");
			        		helper.logAdvancedDiags(cmp, 'Auto-form Select Guide To Enable: Get Guide Steps call failed');
			        	}
			        	
					});
					
			        helper.logAdvancedDiags(cmp, 'Auto-form Select Guide To Enable: calling Get Guide Steps...');
		        	$A.enqueueAction(act);
					break;
			}
		}



		//.........................................................................
		// In some cases, respond to our child components: topic viewer
		//.........................................................................
		
		if (src == 'AFTopicViewer_' + cmp.get("v.ComponentId")) {
			switch (act) {

			    case 'BackToAF':

			    	// Hide topic viewer being used to show embedded topic / 'callout' and return to auto form
					var AFContainer = cmp.find("AFContainer");
					var TVContainer = cmp.find("TVContainer");
	
					$A.util.removeClass(AFContainer, 'slds-hide');
					$A.util.addClass(TVContainer, 'slds-hide');
			    
			    	break;
	    	}
    	}
		


		//.........................................................................
		// In some cases, respond if we've been set up to listen:
		// NOTE TO DEVELOPERS: USE THIS OPTION SPARINGLY!
		// REMEMBER THAT AF IN UTILITY1 IS PART OF IHDETAIL; THE LATTER
		// WILL BE 'TOLD' WHAT TO LISTEN TO BY THE FORMER
		//.........................................................................
		
		if (helper.eventBeingListenedTo (cmp, event)) {
			if (act == 'RecordAdded') {
				
				console.log('Autoform - RecordAdded passthrough: added record : "' + parms + '" - seeking object name based on this...');

				// Need to work out object API name from ID of record being added
				var objName = '';
				var act = cmp.get("c.getObjectName");

/*							
				act.setParams({             
				    "RecordId" : cmp.get("v.recordId"),
				});                       	
*/

				act.setParams({             
				    "RecordId" : parms,
				});                       	

	
				act.setCallback(this, function (response, cmp){
					if (response.getState() == 'SUCCESS') {
						
						objName = response.getReturnValue();
						
						cmp.set("v.DataMode", 'Edit');
						cmp.set("v.sObjectName", objName);
						cmp.set("v.OName", objName);
						cmp.set("v.CurrentRecTypeId", '');
						cmp.set("v.recordId", parms);
						cmp.set("v.LayoutName", '');

						console.log('Autoform - object name derived successfully from ID: calling reInitialise with recordId: ' + cmp.get("v.recordId") + ' and object "' + cmp.get("v.sObjectName") + '"' );
						cmp.reInitialise();
					}
				});
				$A.enqueueAction(act);

			}
		}

		
		//.........................................................................
		// In some cases, respond without initial filtering
		// This may be needed because page owner cannot make the form 'listen' 
		//.........................................................................
		
		if (act == 'RequestGuidePrompt') {
		
			// Only 'real' autoforms should respond - not sub-forms / the guides listing owned by AFs...
			if (isSubForm == true) {
				return;
			}
			
			// A non-field component (e.g., position detector) is requesting a prompt to form part of a guide
			console.log('Autoform (' + cmp.get("v.ComponentId") + ') - Guide Prompt Request from ' + src);
			
			var prompt;
			var existingStep = null;
			var GFlds = cmp.get("v.GuidedFields");			// Steps currently in guide
			var OFlds = cmp.get("v.OriginalGuideEntries");	// Entries originally in guide
			var prompts = cmp.find("GuidePromptEditor");	// Containing DIVs for GP controls on this autoform		
			var i;
			
			
			// Check whether the non-AF element requesting a prompt is associated with an existing guide entry
			// (i.e., its identifier matches the guide element specified in the relevant RL entry)
			for (i=0; i < OFlds.length; i++) {
				if (OFlds[i].iahelp__HelpTopic__r.iahelp__GuidedElement__r.iahelp__Identifier__c == src) {
					existingStep = OFlds[i];
					break;
				}
			}
			
			
			// Create instructions for building a guide prompt, whether based on existing RL entry or not
			if (existingStep != null) {
				prompt = helper.constructGuidePrompt(cmp, existingStep, src, existingStep.iahelp__ReadingOrder__c + 1, GFlds.length);
				
			} else {
				// In these cases, we're adding a step so can assume it's the last one in the current guide
				prompt = helper.constructGuidePrompt(cmp, null, src, GFlds.length, GFlds.length);
				
			}


			// Close any prompts open on our autoform, ready for the active one requested here to open
			// (External guidables respond to the CueGuideStep message below, closing themselves where relevant)
			prompts.forEach(function (p) {
				$A.util.addClass(p.getElement(), "slds-hide");
			});
					

			// Send back the constructed prompt via the usual cue guide message...
			var appEvent = $A.get("e.c:evtPassThrough");
			appEvent.setParams({"SourceComponent": cmp.get("v.ComponentId")});
			appEvent.setParams({"ActionCode": 'CueGuideStep'});
			appEvent.setParams({"Parameters": prompt});
			appEvent.fire();
			
			
			// Ensure this step is logged in the guide
			helper.logGuideStepPD(cmp, src);
		}
		
		
		// Respond to non-field elements (e.g., position detectors) who advise that they are available to participate in a guide
		if (act == 'LogAvailableGuideElement') {
			helper.logAvailableGuideElement(cmp, src, parms);
		}
		
	},
	

})