({ 
 
///////////////////////////////////////////////////////////////////////////
// Form building methods
///////////////////////////////////////////////////////////////////////////

	// Get the largely invariant, cacheable information used on cards 
	initialiseGlobals : function(cmp, event, helper) {

		helper.showSpinner(cmp);

		var SkipGlobals = cmp.get("v.SkipGlobals");	
		
        if (SkipGlobals == true) {		
            var act = cmp.get("c.getGlobals");
            act.setCallback(this, function (response, cmp) {
                
                // As Lightning cacheables may fire more than 1 callback (e.g., a 2nd with updated cache content)
                // we need to check here for this circumstance, as we'll want to respond to the update
                // but NOT re-initialise the whole control
                var repeatFire = cmp.get("v.GlobalSettings") + '' != 'null';		
                
                // We should be able to process the return value just as we always did,
                // as the values are a subset of what was originally in getTools:
                // Note here we need to specify that globals be processed (Skip = false)
                this.processTools(response, cmp, ! SkipGlobals);
                
                // Having done this, run the standard initialisation to obtain the non-cached card data
                // (but only if this is the first callback)
                if (repeatFire == false) {
                    this.init(cmp, event, helper);
                }
                
            });
            $A.enqueueAction(act);	
                
        } else {
            this.init(cmp, event, helper);
        }		

	},


	// Obtain the desired layout name from assignment metadata, if required, then call helper to build that layout
	init : function(cmp, event) {

		// Take note of any record type in play: this *should* be present for new records only
		// but for existing records will be empty string (not null) - so will be obtained by
		// record ID server side if record types are in play...
		
		// Only set this from the URL parameter obtained above if
		// AF caller /  client hasn't set a record type via member data...

		var RTyp = this.getURLParm(cmp, 'recordTypeId');

		if (cmp.get('v.CurrentRecTypeId') == '') {
			cmp.set("v.CurrentRecTypeId", RTyp);			
			
		} else {
			RTyp = cmp.get('v.CurrentRecTypeId');
		}			


		// Take note of any related record information supplied via SF URL
		var relInfo = this.getURLParm(cmp, 'inContextOfRef');
		
		if (relInfo != '') {
			if (relInfo.startsWith('1.')) {
				
				try {
					// If present and in a recognised format, parse this into the underlying related info object
					relInfo = relInfo.substring(2);
					relInfo = decodeURIComponent(relInfo);										
					relInfo = window.atob(relInfo);
					relInfo = JSON.parse(relInfo);
					
					// From this extract related object API name and record ID
					cmp.set("v.RelOName", relInfo.attributes.objectApiName);
					cmp.set("v.RelRecordId", relInfo.attributes.recordId);
					
					
					// Add this data to the set to be pre-populated (by standard means - c.f. Controller.setOverriddenFields) 
					if (cmp.get("v.PopulatedFields") != '') {
						cmp.set("v.PopulatedFields", '|' + cmp.get("v.RelOName") + 'Id¬' + cmp.get("v.RelRecordId"));		
					} else {
						cmp.set("v.PopulatedFields", cmp.get("v.RelOName") + 'Id¬' + cmp.get("v.RelRecordId"));		
					}
		
					console.log('Autoform initialisation: incoming related object data was present, adding to fields to pre-populate: ' + cmp.get("v.PopulatedFields"));		
		
				} catch (e) {}
				
			}
		} else {
			// Re-set key parameters if not in a related record scenario
			cmp.set("v.RelOName", '');
			cmp.set("v.RelRecordId", '');	
		}


		// ONLY ACT WITH A 'PROPER' RECORD:
		// Certain components (e.g., trees) may issue record selects / root changes that lead us here
		// with delimited data that only they understand. Attempts to process these messages will fail, 
		// so bail here if we encounter things that do not seem to be a record ID
		var D1 = '^';
		if (cmp.get("v.recordId") + '' != 'null' && cmp.get("v.recordId") != null) {
			if (cmp.get("v.recordId").indexOf(D1) != -1) {
				console.log('Autoform initialisation: illegal record ID encountered (' + cmp.get("v.recordId") + ') - bailing...');
				return;
			}
		}


		// If layout name has not been supplied, make a call to get it here
		if (cmp.get("v.LayoutName") == '' || cmp.get("v.LayoutName") == null) {
		
			var LName;
			var objSought = cmp.get("v.sObjectName");
			var objSvr;
			var customObjId;
			var profileSought;
			var currentProfile;
			var recordTypeSought;
			var defaultRecordType;
			var currentRecordType;
			var i;
			var obj;
			var hasAttributes;	
			var intl = [];												// Internationalisations
			var act = cmp.get("c.getStoredProfileLayouts");
			
						
			// We may or may not have obtained record type above, so in calling this function
			// we pass whatever we got plus record ID. Call will use the latter to get record 
			// type info if it has to
		    act.setParams({             
		        "RecordTypeId" : RTyp, 
		        "RecordId" : cmp.get("v.recordId"),
		        "ObjectName" : cmp.get("v.sObjectName"),
		    });                       	

	
			act.setCallback(this, function (response, cmp){
				if (response.getState() == 'SUCCESS') {
				
					try {
						obj = JSON.parse(response.getReturnValue());
						
						// At this stage, we have a collection of objects representing layout to profile / record type assignments.
						// We also have some name/value pairs added server side recording the profile to seek, plus record type and 
						// any custom object information: extract these key items here...
				
						for (i=0; i < obj.length; i++) {
						
							// Extract the user's profile ID 
							if (obj[i].ValueSet == 'LayoutSearchKeys' && obj[i].Name == 'UserProfile') {
								profileSought = obj[i].Value;
							}
							
							// Ditto record type in play
							if (obj[i].ValueSet == 'LayoutSearchKeys' && obj[i].Name == 'RecordTypeId') {
								recordTypeSought = obj[i].Value;
							}
							
							// Ditto DEFAULT record type for the current object type
							if (obj[i].ValueSet == 'LayoutSearchKeys' && obj[i].Name == 'DefaultRecordTypeId') {
								defaultRecordType = obj[i].Value;
							}
							
							// Ditto the object API name derived from the record ID passed to server
							// (should be the same as out sObjectName / objSought - but offered here as a cross-check)
							if (obj[i].ValueSet == 'LayoutSearchKeys' && obj[i].Name == 'CustomObjectAPIName') {
								objSvr = obj[i].Value;
							}
							
							// Ditto the custom object ID (ProfileLayout.TableOrEnumId) derived from this object name, if form is for a custom object
							if (obj[i].ValueSet == 'LayoutSearchKeys' && obj[i].Name == 'CustomObjectId') {
								customObjId = obj[i].Value;
							}
							
							// Also record our internationalisation info
							if (obj[i].ValueSet == 'Internationalisations') {
								intl.push(obj[i]);
							}							
							
						}				

						// Comparisons to be based on 15 character IDs for user profile and record type, when in play:
						if (recordTypeSought + '' != 'undefined') {						
							if (recordTypeSought.length > 14) {
								recordTypeSought = recordTypeSought.substring(0, 15);
							}
						}						

						this.logAdvancedDiags(cmp, 'Auto-form initialisation: User Profile sought: ' + profileSought);
						this.logAdvancedDiags(cmp, 'Auto-form initialisation: Client-side object name: ' + objSought);				
						this.logAdvancedDiags(cmp, 'Auto-form initialisation: Object name located on server: ' + objSvr);				
						this.logAdvancedDiags(cmp, 'Auto-form initialisation: Custom Object Id: ' + customObjId);				
						this.logAdvancedDiags(cmp, 'Auto-form initialisation: Record sought: ' + cmp.get("v.recordId"));				
						this.logAdvancedDiags(cmp, 'Auto-form initialisation: Record Type sought: ' + recordTypeSought);				
						this.logAdvancedDiags(cmp, 'Auto-form initialisation: Default Record Type for object: ' + defaultRecordType);


						cmp.set("v.DefaultRecTypeId", defaultRecordType);		
						
						// Use the default type as our current type - 1.43.17+ where relevant!

						// [1] If no other was specified via url or design params (see above - member will have been set)
						if (cmp.get('v.CurrentRecTypeId') == '') {	
						
							// AND [2] If no type was located (including NULL / no type) when sought via stored profile layouts call
							if (recordTypeSought + '' != 'undefined' && recordTypeSought != '') {
								// No need to act here - including for deliberate NULL record type
							} else {
								cmp.set("v.CurrentRecTypeId", defaultRecordType);
							}
						}
		

						// 1.41.28+ : Fix for communities where sObjectName does not get populated by SFDC!
						// If client side name is blank, use server discovered name for search					
						if (objSought == null || objSought == '' || objSought + '' == 'null' || objSought + '' == 'undefined') {
							objSought = objSvr;
							cmp.set("v.sObjectName", objSought);
							cmp.set("v.OName", objSought);
							
							this.logAdvancedDiags(cmp, 'Auto-form initialisation: Client-side object name was blank - reset to: ' + objSought);
						}
						
						
						// 1.44.1 : Fix for situations arising when 'navigating' a single autoform to different record types:
						// If server discovered name = client name plus a namespace, use it
						if (objSvr.endsWith('__' + objSought)) {
							objSought = objSvr;
							cmp.set("v.sObjectName", objSought);
							cmp.set("v.OName", objSought);
						
							this.logAdvancedDiags(cmp, 'Auto-form initialisation: server-side object name included namespace - resetting to: ' + objSought);
						}						
						
						
						// Search through configuration data records returned...
						var LayoutsChecked = false;


// v1.54.8+ : 
// For custom objects, we may (rarely) obtain >1 ID matching the custom object API name sought (eg due to objects having history enabled).
// In these cases, we'll have a comma separated list of object IDs - only 1 of which will actually be used in layout assignment records.
// So: if this is the case, split by comma and seek each

var COIDs;

if (customObjId + '' != 'undefined') {
	COIDs = customObjId.split(',');
} else {
	COIDs = [];
	COIDs.push(objSought);
}


						while (LayoutsChecked == false) {						
							for (i=0; i < obj.length; i++) {
			
				                try {
				                    var s = obj[i].attributes.type;
				                    hasAttributes = true;
				                } catch (e) {
				                    hasAttributes = false;
				                }
		
				                if (hasAttributes === true) {				
				                	currentProfile = obj[i].ProfileId;
				                	currentRecordType = obj[i].RecordTypeId;
	
				                	// Matching criteria depend on whether or not a record type is in play:
				                	// Note that, as custom objects store their layout data against a custom object ID,
				                	// whereas standard objects store theirs against their object NAME, we need to search 
				                	// below for both possibilities...

/*				                	
				                	if (recordTypeSought == 'NULL') {
		                				if ((obj[i].TableEnumOrId == objSought || objSought.endsWith('__' + obj[i].TableEnumOrId) || obj[i].TableEnumOrId == customObjId) && currentProfile.substring(0, 15) == profileSought) {
				                			LName = objSought + '-' + obj[i].Layout.Name;
											break;
										}
			
				                	} else {
				                		if (currentRecordType + '' != 'null') {
				                			if (currentRecordType.length > 14) {
				                				currentRecordType = currentRecordType.substring(0, 15);
				                			}
				                		}
				                		
				                		if ((obj[i].TableEnumOrId == objSought || objSought.endsWith('__' + obj[i].TableEnumOrId) || obj[i].TableEnumOrId == customObjId) && currentProfile.substring(0, 15) == profileSought && currentRecordType == recordTypeSought) {
				                			LName = objSought + '-' + obj[i].Layout.Name;
											break;
										}
				                	}
*/				                	


COIDs.forEach(function(CO){
	
	customObjId = CO;

	if (recordTypeSought == 'NULL') {
		if ((obj[i].TableEnumOrId == objSought || objSought.endsWith('__' + obj[i].TableEnumOrId) || obj[i].TableEnumOrId == customObjId) && currentProfile.substring(0, 15) == profileSought) {
			LName = objSought + '-' + obj[i].Layout.Name;
			//break;
		}

	} else {
		if (currentRecordType + '' != 'null') {
			if (currentRecordType.length > 14) {
				currentRecordType = currentRecordType.substring(0, 15);
			}
		}
		
		if ((obj[i].TableEnumOrId == objSought || objSought.endsWith('__' + obj[i].TableEnumOrId) || obj[i].TableEnumOrId == customObjId) && currentProfile.substring(0, 15) == profileSought && currentRecordType == recordTypeSought) {
			LName = objSought + '-' + obj[i].Layout.Name;
			//break;
		}
	}

});

if (LName + '' != 'undefined') {
	break;
}

				                	
								}
								
							}	// End of loop through returned metadata layout assignment records	


							if (LName + '' == 'undefined') {
								// If we didn't find a layout and we were seeking one for an Account, 
								// check again for layouts logged as PersonAccount
								if (objSought == 'Account') {
									objSought = 'PersonAccount';
									this.logAdvancedDiags(cmp, 'Auto-form initialisation: Account layout assignment was sought but not located: checking for PersonAccount layouts...');
									
								} else {
									this.logAdvancedDiags(cmp, 'Auto-form initialisation: Layout assignment details not located...');
									LayoutsChecked = true;
								}
								
							} else {
								// If we found a layout, stop looking
								this.logAdvancedDiags(cmp, 'Auto-form initialisation: Layout assignment details located...');		
								LayoutsChecked = true;
							}
							
						}	// End while loop used in case we need seek a person account
				
					} catch (e) {
		                console.log('Auto-form initialisation: - Error parsing known layouts JSON (' + e + '): ' + response.getReturnValue());
		                cmp.set("v.Diags", "Auto-form initialisation: - Error parsing known layouts JSON (" + e + "): " + response.getReturnValue());
					}
					
				} else {
					console.log('Auto-form initialisation: call to obtain known layouts failed');
					cmp.set("v.Diags", "ERR!");
				}
				
				// Seek layout ID and set it
				this.logAdvancedDiags(cmp, 'Auto-form initialisation: queried layout name is: ' + LName);

				if (LName + '' == 'undefined') {
					console.log('Auto-form initialisation: query failed to return a layout: API call required - summoning VF page to do this...');
					
					// We didn't find layout data, but as we're a LUX client, we're not allowed to make API calls.
					// Therefore, we show a VF page (which can make the required call) advising user that
					// layout data has been sought and they'll need to refresh their page on this 1 occasion...


					var CRoot = cmp.get('v.CommunityRoot');								// Community info, if required
					
					// If root is 'null', this can be ignored in most cases
					if (CRoot + '' == 'null') {CRoot = '';}
					if (CRoot != '') {CRoot = '/' + CRoot;}    	

					var src = CRoot + "/apex/iahelp__IHLUXOpHandler?Op=1&recordId=" + cmp.get("v.recordId");

					cmp.set("v.Internationalisations", intl);
					this.doDialogue('LayoutMetadataSought', 'VF', src, null, 100, false, false, false, cmp, true);
				}		
				cmp.set("v.LayoutName", LName);
		
				// With layout set, initialise as usual...
				this.initialiseForm(cmp, event);
			});
			
			this.logAdvancedDiags(cmp, 'Auto-form initialisation: calling stored profile layouts...');			
			$A.enqueueAction(act);
	
	
		} else {
			// If layout name was supplied, just build the form using this
			this.logAdvancedDiags(cmp, 'Auto-form initialisation: working with pre-supplied layout name...');

			this.initialiseForm(cmp, event);
		}
	
	},


	// Initialisation / form building routine
	// Obtain the desired form definition and build form
	initialiseForm : function(cmp, event) {
		
        var act = cmp.get("c.getTools");
        var SkipGlobals = cmp.get("v.SkipGlobals");
        var cxt;
        var Fs = [];
        var obj;
        var content;
        var frm = cmp.find("recordEditForm");        
    	var D1 = '^';
        var LIs;
        var selFields = [];							// Selected on editor pick list
        var allFields = [];							// All available for editor pick list
        var frmSects = [];							// Form sections
        var dvAcc = cmp.find("ModeTools");			// Containing DIV of tools accordion
        var limitFields = cmp.get("v.LimitFields");	// Instructions to display only certain fields
        
        
        this.showSpinner(cmp);
        
        // Default certain values here - if we're present on a page due to an override as opposed to 
        // being  manually added to a page layout
        if (this.isLayoutOverride(cmp) == true) {
        	// Set height to 100%
        	cmp.set("v.Height", -1);

        	// If we are in override mode, set accordion tools to float and enable related shims 
        	// (by noting the fact we're in override mode)      	
        	$A.util.addClass(dvAcc, "FixedMode");        	
    		cmp.set("v.IsLayoutOverride", true);

        } else {
        	// If not in override mode, set accordion tools to NOT float and remove shims        	
        	// (by noting the fact we're NOT in override mode)      	
        	$A.util.removeClass(dvAcc, "FixedMode");
        	cmp.set("v.IsLayoutOverride", false);
        }

        
        // Set data mode based on what we know of our record
        if (cmp.get("v.recordId") != null) {
        	// Set view mode unless we've specifically been told otherwise
        	if (cmp.get("v.DataMode") != 'Edit') {
	        	cmp.set("v.DataMode", "View");
        	}
        	
        	// Use record ID as our action context
        	cxt = cmp.get("v.recordId");
        	
        } else {
        	// No record ID can only mean new (which uses "edit" here)
        	cmp.set("v.DataMode", "Edit");
        	
        	// Use object name as our action context
        	cxt = cmp.get("v.sObjectName");
        }
        
        
        // Set some additional styling attributes on the back of data mode
        if (cmp.get("v.DataMode") == 'Edit') {
        	cmp.set("v.DataModeStyle", "forcePageBlockItemEdit");
        } else {
        	cmp.set("v.DataModeStyle", "forcePageBlockItemView");
        }
        

		// Allow a tool context to be set but default if not provided
		if (cmp.get("v.ToolContext") == 'QAM' || cmp.get("v.ToolContext") == '[DEFAULT]' || cmp.get("v.ToolContext") == '') {
			cmp.set("v.ToolContext", "CardAutoForm");
		}        	
        
        
        
        cmp.set("v.ActionCode", "GetForm");
        
        act.setParams({             
            "ToolContext" : cmp.get("v.ToolContext"), 
            "ActionCode" : cmp.get("v.ActionCode"),
            "IHContext" : cxt,
            "ClientComponentId" : cmp.get("v.ComponentId"), 
            "Params" : cmp.get("v.sObjectName") + D1 + cmp.get("v.LayoutName") + D1 + cmp.get("v.DataMode") + D1 + cmp.get("v.recordId") + D1 + cmp.get("v.DefaultSectionToggleState"),
            "SkipGlobals" : SkipGlobals,
        });                       

	                
        // Add callback to process returned results
        act.setCallback(this, function (response, cmp){

            try {
            	// Form information is returned to us as listing items, processed as usual...
            	this.processTools(response, cmp, SkipGlobals);

            	// If we've obtained our tools, we should be able to set border colour for embedded help ops...
            	cmp.set("v.FrameBorderColour", cmp.get("v.UXThemeColour2"));
            	
            	
            	// Also, details of user's personally selected fields / 'my form':
            	// These should have been collected in "pass through" data
            	var PFIs = cmp.get("v.PassThroughData");

            	if (PFIs != undefined) {
            		if (PFIs.length > 0) {
            			
            			// NOTE: user may have selected NO fields, in which case value will be null...
            			if (PFIs[0].Value != null) {
            				cmp.set("v.SelectedFields", PFIs[0].Value.split(D1));
            			}
            		}
            	}
            	
            	
            	// Check personalisations and respond as required: 
		        var PS = cmp.get("v.PersonalisationSettings");
		        var i;
		        for (i=0; i<PS.length; i++) {		        

		        	this.logAdvancedDiags(cmp, 'Auto form - personalisation settings: ' + PS[i].iahelp__HelpInteractionType__c + '=' + PS[i].iahelp__Description__c);
		        
        			// "Personal Form Visibility" interaction:
	            	// If present, show/hide the user's personal form as appropriate.
	            	// Only do this where component header is visible - to allow the facility to effectively be switched off for all			        
		            if (PS[i].iahelp__HelpInteractionType__c === 'Personal Form Visibility') {
		            	if (cmp.get("v.SuppressHeader") == false) {
			                if (PS[i].iahelp__Description__c == 'true') {
				                cmp.set("v.PersonalFormView", true);
			                }
		                }			                
		            }
		            
		            // "Display Density" interaction: amend form as required
		            if (PS[i].iahelp__HelpInteractionType__c === 'Display Density') {
		            	cmp.set("v.DisplayDensity", PS[i].iahelp__Description__c);
		            }		            
		        }            	
            	

				// Obtain object name as part of the return value: metadata listing row used for this...           	
                cmp.set("v.OName", cmp.get("v.CurrentRecordMetadata").RowState);
                frm.set("v.objectApiName", cmp.get("v.CurrentRecordMetadata").RowState);
                cmp.set("v.OLabel", cmp.get("v.CurrentRecordMetadata").Label);
                cmp.set("v.OCode", cmp.get("v.CurrentRecordMetadata").Id);
                cmp.set("v.LayoutName", cmp.get("v.CurrentRecordMetadata").Title);
                
				// Note whether or not editing is allowed for the current object
				cmp.set("v.AllowEdits", cmp.get("v.CurrentRecordMetadata").Parameters);                
                
                // Card title is a function of data mode/operation being undertaken plus object type
                if (cmp.get("v.DataMode") == 'View') {
	                cmp.set("v.Title", cmp.get("v.OLabel"));
                } else {
	                cmp.set("v.Title", cmp.get("v.OLabel") + ': ' + decodeURI(cmp.get("v.LayoutName")));
                }

                this.logAdvancedDiags(cmp, 'Auto form - Object details stored');

                // Note some component-specific translations
                cmp.set("v.AdviceLabelGEInstructions", this.Internationalise(cmp, 'AdviceLabelGEInstructions'));
                cmp.set("v.AdviceLabelProperties", this.Internationalise(cmp, 'AdviceLabelProperties'));
                cmp.set("v.AdviceLabelSteps", this.Internationalise(cmp, 'AdviceLabelSteps'));
                cmp.set("v.TipButtonCreateNewGuide", this.Internationalise(cmp, 'TipButtonCreateNewGuide'));
                cmp.set("v.TitleDialogueTitleOpt8", this.Internationalise(cmp, 'TitleDialogueTitleOpt8'));
                

				// Default to "view" operational mode (NB - as opposed to DATA mode - set above) 
				this.setViewMode(cmp, event);
                               

				// Any re-build of form will mean data changes, if any, were lost and form is now "clean"
				cmp.set("v.isDirty", false);


				// Check whether we've been asked to show only selected fields
				if (limitFields != '' && limitFields + '' != 'undefined') {
				
					// If so, we will place all fields that are to be shown in a single, pseudo section with set columns etc for display
					var lstIn = cmp.get("v.ListingItems");
					var lstOut = [];
					var lFlds = limitFields.split(',');
					var L;
					var S;
					var R;
					var Rs = [];
					var i;
					var numCols = 2;
					var currentFld = 0;
					var currentCol = 1;
					
					
					console.log('Auto form - fields to display restricted to: ' + limitFields);
					
					// For each field we were asked to show, get its layout item - the object that actually forms 
					// the granular content of each section / column / row... 
					for (i=0; i<lFlds.length; i++) {
						lFlds[i] = this.getIHLI(cmp, lFlds[i]);
					}
					
					// As we can't create new objects client-side, perloin the first section that was returned from the server:
					// Empty it out, make sure it's expanded and, as our fields may come from a variety of sections, don't show a section heading
					L = lstIn[0];
					S = L.Sections[0];
					L.Sections = [];
					S.SROOnly = false;
					S.Expanded = true;
					S.Section.detailHeading = false;
					
					
					// ... then add rows to the section as required, each containing items as gathered above:
					// Again, we can't create rows client-side, so 'clone' one of them by parsing into and out of JSON,
					// then clear its items prior to re-population. 
					R = JSON.stringify(S.Rows[0]);
					R = JSON.parse(R);
					R.Items = [];
				
					while (currentFld < lFlds.length) {
						if (currentCol <= numCols) {
							
							// This field may continue on current row:
							// Only process it if we got the underlying layout item, above (if we didn't, this suggests issues 
							// with the requested field - which may not be in the assigned layout etc)
							if (lFlds[currentFld] != null) {
								console.log('Auto form processing limited fields: R' + Rs.length + 'C' + currentCol + 'F' + currentFld + ': ' + lFlds[currentFld].FieldLabel);
								R.Items.push(lFlds[currentFld]);
								currentCol += 1;
								
							} else {
								console.log('Auto form processing limited fields: R' + Rs.length + 'C' + currentCol + 'F' + currentFld + ': field not found on current layout');
							}

							currentFld += 1;
							
							// Push last row if required
							if (currentFld == lFlds.length) {
								Rs.push(R);
							}
							
						} else {
							// Column limit reached: record the row produced, 
							// then prepare a new row by 'cloning' as above
							Rs.push(R);
							R = JSON.stringify(S.Rows[0]);
							R = JSON.parse(R);
							R.Items = [];
							currentCol = 1;			
						}
					}
					
					
					// Having built rows as required, set autoform's listing items to our limited version:
					// Pump the rows obtained into our section... 
					S.Rows = [];	
					for (i=0; i<Rs.length; i++) {
						S.Rows.push(Rs[i])
					}
					
					// ... then pump the section into the layout, layout to form and form to listing items
					L.Sections.push(S);
					lstOut.push(L);
					cmp.set("v.ListingItems", lstOut);
				}
				
				
				this.logAdvancedDiags(cmp, 'Auto form - AF specific internationalisations and view mode set - initialising...');
				cmp.set("v.isInitialised", false);
				this.logAdvancedDiags(cmp, 'Auto form - initialised');
				
                
                // Raise an event to advise that component has been generated
	            var appEvent = $A.get("e.c:evtPassThrough");
	            appEvent.setParams({"SourceComponent": cmp.get("v.ComponentId"), "ActionCode": "ComponentToolsProcessed", "Parameters": cmp});
	            appEvent.fire();         
	            
	            
				// Run a guide if requested via URL
				// See getTools / Guides action: parameters in these cases set to Guide Name ^ RL (Guide) Type	
				// HOWEVER: see override list action, as set/used in our accordion guide listing (IHAFGuideList, as
				// built on accordion click). This overrides standard guides list action to one we need to obtain steps
				// (SelectGuideToEnable). As a passthrough, this adds listing (guide) ID as parameter 0, to leave
				// the full set being:
				// [Guide ID] ^ [Guide Name] ^ [Linear / nonlinear code]    
				// All we know from A URL request is the first of these, so hard-wire the remainder for now...
				                                  
				var GID = this.getURLParm(cmp, 'iahelp__GID');

				this.logAdvancedDiags(cmp, 'Auto form - Guide on arrival = "' + GID + '"');
				
				if (GID != '' && cmp.get("v.CheckURLParams") == true) {
					
					// This means guides are in play, so use this as a cue to render (hidden) prompts
					cmp.set("v.GuidesInUse", true);
					
					// Raise event requesting guide
				    appEvent = $A.get("e.c:evtPassThrough");
					appEvent.setParams({
						"SourceComponent": 'AFGuideList_' + cmp.get("v.ComponentId"), 
						"ActionCode": "SelectGuideToEnable", 
						"Parameters": GID + '^^1'
					});
					appEvent.fire();    
				
					
					// Set latch that says we've considered URL (on page load and not thereafter)
				    cmp.set("v.CheckURLParams", false);
				}
	                               
				this.logAdvancedDiags(cmp, 'Auto form - initialise form complete');
				

            } catch (e) {
            	cmp.set("v.Diags", 'ERR! ' + e);                
            }

        });

        $A.enqueueAction(act);
	},
    

	// Pseudo-detection of whether this component is present due to layout override 
	isLayoutOverride : function (cmp) {

		// Any component that was manually added to a page layout must have a component ID
		// so its absence can be taken to mean this is an override
		// We can also detect our override component
		return cmp.get("v.ComponentId") == '' || cmp.get("v.ComponentId") == 'theModalCmpContent';
	},

	
	// Get the Improved Help Layout Item record for a given Field API name
	getIHLI : function (cmp, FieldAPIName) {
	
		var LIs = cmp.get("v.ListingItems");
		var retVal = null;
		
		LIs[0].Sections.forEach(function (S){
			S.Rows.forEach(function(R){
				R.Items.forEach(function(I){
					if (I != null) {
						if (I.Item != null) {
							if (I.Item.field != null) {
								if (I.Item.field == FieldAPIName) {
									retVal = I;
								}												
							}
						}
					}
				});
			});
		});
		
		return retVal;		
	},
	

	// Get the row, section or related details in which a layout item resides
	getIHLElement : function (cmp, IHLI, InfoRequired) {
	
		var LIs = cmp.get("v.ListingItems");
		var retVal = null;
		var rIdx = 0;
		var sIdx = 0;
		
		LIs[0].Sections.forEach(function (S){
			S.Rows.forEach(function(R){
				R.Items.forEach(function(I){
					if (I != null) {
						if (I.Item.field == IHLI.Item.field) {
						
							switch (InfoRequired) {
								case 'Row' :
									retVal = R;
									break;

								case 'RowIndex' :
									retVal = rIdx;
									break;

								case 'Section' :
									retVal = S;
									break;

								case 'SectionIndex' :
									retVal = sIdx;
									break;
									
								default :
									retVal = null;
									break;
							}
							
						}
					}
				});
				
				rIdx += 1;
			});
			
			sIdx += 1;
		});
		
		return retVal;		
	},


	// Get the Improved Help Layout Item record for a given Field label
	getIHLIByLabel : function (cmp, FieldLabel) {
	
		var LIs = cmp.get("v.ListingItems");
		var retVal = null;
		
		LIs[0].Sections.forEach(function (S){
			S.Rows.forEach(function(R){
				R.Items.forEach(function(I){
					if (I != null) {
						if (I.Item != null) {
							if (I.FieldLabel == FieldLabel) {
								retVal = I;								
							}												
						}
					}
				});
			});
		});
		
		return retVal;		
	},


	// Save an amended Improved Help Layout Item record back to the form:
	// Returns true if amendment successful, otherwise false
	setIHLI : function (cmp, IHLI) {
	
		var LIs = cmp.get("v.ListingItems");
		var i;
		var retVal = false;
		
		LIs[0].Sections.forEach(function (S){
			S.Rows.forEach(function(R){
				
				i = 0;
				R.Items.forEach(function(I){
					if (I != null) {
						if (I.Item != null) {
							if (I.Item.field != null) {
								if (I.Item.field == IHLI.Item.field) {
									
									// If you find the requested layout item (by field API name)
									// replace it and note the fact for returning success, below
									R.Items[i] = IHLI;
									retVal = true;
								}												
							}
						}
					}
					
					i += 1;					
				});
			});
		});
		
		// Save any amendments back to member data
		cmp.set("v.ListingItems", LIs);		
		return retVal;		
	},


	// Returns a boolean indicating whether any field in a section of the form is edited / dirty
	sectionDirty : function (Sect) {
		
		var retVal = false;
		
		Sect.Rows.forEach(function(R){
			R.Items.forEach(function(I){
				if (I != null) {
					if (I.isDirty == true) {
						retVal = true;
					}
				}
			});
		});
		
		return retVal;
	},


	// Removes dirty flags from all fields on the form
	resetFieldDirtyFlags : function (cmp) {
	
		var LIs = cmp.get("v.ListingItems");
		
		LIs[0].Sections.forEach(function (S){
			S.Rows.forEach(function(R){
				R.Items.forEach(function(I){
					if (I != null) {
						I.isDirty = false;
					}
				});
			});
		});
		
		// Save any amendments back to member data
		cmp.set("v.ListingItems", LIs);		

	},
	


///////////////////////////////////////////////////////////////////////////
// My Form / Personal form support
///////////////////////////////////////////////////////////////////////////

	// Get details of the fields available for user's personal form
	getFormDefTools : function(cmp, event) {
		
        var act = cmp.get("c.getPersonalFormDef");
        var LIs;
        var selFields = [];		// Selected on editor pick list
        var allFields = [];		// All available for editor pick list
        var item;
        
        
        this.showSpinner(cmp);
        
        act.setParams({             
            "IHContext" : cmp.get("v.OCode"),
        });                       
	                
        // Add callback to process returned results
        act.setCallback(this, function (response, cmp){

            try {
				// We're given back listing items - but not the ones we want for our control in general
				// So: here we must extract these items for ourselves (NOT process tools)...
            	if (response.getState() === "SUCCESS") {

					// Return value is JSON - parse this into objects for aura iteration...
		            try {
						LIs = JSON.parse(response.getReturnValue());
		            } catch (e) {
		                cmp.set("v.Diags", "IHCardHelper - processTools - Error parsing the following return value (" + e + "): " + response.getReturnValue());
		                return false;
		            }

		            // We may have been returned zero or more listing records.
		            // If there are >1 total items, we have a collection to iterate. 
		            // If there are 0 items, we've nothing to do.
		            // If there is exactly 1 item, we need
		            // to load this into an array in order for the loop that follows to work...
		            if ('' + LIs.length === 'undefined') {
		                LIs = new Array(LIs);
		            }
		            
	            	LIs.forEach(function(v) {
	            	
	            		// For the purposes of sorting (selected fields into the correct order) our labels 
	            		// will have had a 5-digit ordinal pre-pended: see listing prep for the get form def action.
	            		// Remove this here...
	            		v.Label = v.Label.substr(6, v.Label.length - 6);
	            	
	        			item = {
	        				"label": v.Label,
	        				"value": v.Id,
	        			};
	            	
	            		if (v.RowState == 'SELECTED') {            		
	            			selFields.push(v.Id);
	            		}
	            			
	            		// Available fields are all listing items - regardless of whether selected
	            		allFields.push(item);
	            		
	            	});

	            	cmp.set("v.SelectedFields", selFields);
	            	cmp.set("v.AvailableFields", allFields);
	            	cmp.set("v.Diags", "");
	            	
            	} else {
            		var errors = response.getError();

            		if (errors) {
		                if (errors[0] && errors[0].message) {
		                    strDiags = 'ERR (' + state + '): ' + errors[0].message;
		                    strDiags += ' - - - COMPONENT PARAMETERS: ActionCode=' + cmp.get('v.ActionCode') + ': ToolContext=' + cmp.get('v.ToolContext') + ': IHContext=' + cmp.get('v.IHContext');
		                }
            
		            } else {
		                strDiags = 'ERR (' + state + '): - - - COMPONENT PARAMETERS: ActionCode=' + cmp.get('v.ActionCode') + ': ToolContext=' + cmp.get('v.ToolContext') + ': IHContext=' + cmp.get('v.IHContext');
		            }
            
		        	this.logAdvancedDiags(cmp, strDiags);
		            cmp.set("v.Diags", "ERR!");
		            return false;            
            	
            	}
            	
            } catch (e) {
            	cmp.set("v.Diags", 'ERR! ' + e);                
            }
            	
            this.hideSpinner(cmp);
              
        });
        
        $A.enqueueAction(act);
	},


///////////////////////////////////////////////////////////////////////////
// Help view / enable support
///////////////////////////////////////////////////////////////////////////

    // Issue an event advising that a field is active (so, perhaps, show help for it)
    requestHelp : function (cmp, event, helper, ctl) {
    	   
    	var fld = ctl.id; 													// API Name of clicked field
		var I = helper.getIHLI(cmp, fld);									// IH Layout Item (listing iterable) responsible for this field     	
		var cls = ctl.className; 											// Its class
    	var isError = 0;													// For logging of any error / issue conditions with an element
    	var topicId;														// Associated help topic, if any
    	var Elem;															// Associated helped element (identifier)
    	var Pg;																// Topic's callout template page URL, where relevant
    	var H; 																// Topic's callout height, where relevant
    	var frm = cmp.find("AutoFormFrame").getElement();					// Our content iframe
    	var U;																// For iframe URL building
    	var dlgMap;															// For use when generating components in some dialogues etc.
		var conts = cmp.find("CalloutContainer");							// Collection of callout container DIVs on our form
    	var cnt; 															// Container for the clicked item, from the above


    	try {
	    	// Get the containing DIV for the callout area of the clicked item:
	    	// Need to ensure we're dealing with situation where there may be more than one form present!
			conts.forEach(function(C){
				if (C.getElement().id == fld + '_CalloutContainer') {
					cnt = C.getElement();
				}
			});
			// If we don't find the container for some reason, log the issue and abort
			if (cnt + '' == 'undefined') {
				console.log('Auto form - Request Help: failed to locate callout container for "' + fld + '"');
				return;
			} else {
				console.log('Auto form - Request Help for field "' + fld + '" (current field was "' + cmp.get("v.CurrentFieldName") + '")');
			}


	    	var eType;    														// For nubbin positioning	
	    	var CRoot = cmp.get('v.CommunityRoot');								// Community info, if required
	    	var HPLIdent = cmp.get('v.CommunityRoot');							// For reconfigure mode use


			// If root is 'null', this can be ignored in most cases
			// Not, however, for HPL identification in some cases (see reconfig mode, below)
			if (CRoot + '' == 'null') {CRoot = '';}
	    	if (CRoot != '') {CRoot = '/' + CRoot;}    	
			if (HPLIdent + '' != '') {HPLIdent = HPLIdent + '/';}
    	
    	
	    	// Check whether any error condition is present: note these for later use
			if ($A.util.hasClass(ctl, 'IHHelpedSFElementError')) {
				isError = 1;
			}
	    	if ($A.util.hasClass(ctl, 'IHDDFFailElement')) {
				isError = 2;
	    	} 	
    	
    	
	    	// If requested FIELD (not topic) appears to be the one we're already on, do nothing / toggle callout only.
	    	if (fld == cmp.get("v.CurrentFieldName")) {
				helper.toggleCallout(cmp, event, cnt);
				return;    		
	    	}
	
	    	
	    	// If we're in help or guide enable mode, we just need to toggle element state and this is handled elsewhere
	    	// so ignore here...
		    if (cmp.get("v.OpMode") == 'HelpEnable' || cmp.get("v.OpMode") == 'GuideEnable') {
				return;
			}
    	

	    	// Derive nubbin position from clicked item's class (which is marked as part of iteration 
	    	// with details of its column position) 
	    	cls = cls.split(' ');
	    	cls = cls[0];
	    	
	    	switch (cls) {
	    		case '1of2':
	    		case '1of3':
	    			eType = 'TL0';
	    			break;
	    			
	    		case '1of1':
	    		case '2of3':
	    			eType = 'TL1';
	    			break;
	
	    		case '2of2':
	    		case '3of3':
	    			eType = 'TR0';
	    			break;
	
	    		default:
	    			eType = 'T0';
	    			break;    			
	    	}
	    	
    	
			// Obtain topic details from layout item relating to the clicked field
	    	if (I == null) {
				// If we don't find the required details, hide callouts
				$A.util.addClass(frm, 'slds-hide');	   
				$('.CalloutContainer').addClass('slds-hide');
				$('.CalloutContainer').css('height', '0px');
			
			} else {
	    		// Only proceed if active topic has changed
	    		if (topicId == cmp.get("v.CurrentHTID")) {
	    			// If topic is already in play, toggle visibility where options require this
	    			helper.toggleCallout(cmp, event, cnt);
	    			return;
				}
						
			
				if (isError == 0) {
					// If helped element has a valid topic (not broken / in error condition) obtain details
					topicId = I.Topic.Id;
					H = I.Topic.iahelp__CalloutHeight__c;
					Pg = I.Topic.iahelp__CalloutTemplate__r.iahelp__PageURL__c;
					
					// Deal with "local" custom templates: with these, we need to remove the "c."
					// namespace (required in classic): see also jsToggleHelp.getTemplateAddress
					if(Pg.indexOf('.') != -1){
					    Pg = Pg.split('.');
					    Pg = Pg[1];
					} 
					
					Elem = I.Element.iahelp__Identifier__c;
				}
				
				if (isError == 1) {
					// Element has missing topic
					if (! confirm(helper.Internationalise(cmp, '[QAMMessageElementConfigurationIssue]'))) {
						return;
					}			
					topicId = 'ConfigIssue_' + I.Element.iahelp__Identifier__c;
					Elem = I.Element.iahelp__Identifier__c;
				}
				
				if (isError == 2) {
					// DDF fail: by definition there is no element, so use info about the underlying field from the layout item
					if (! confirm(helper.Internationalise(cmp, '[QAMMessageDDFNotMatched]'))) {
						return;
					}		
					topicId = 'DDFFail_' + I.FieldLabel;
					Elem = I.FieldLabel;
				}
	
				
				// If we proceed, record details of the relevant field
				cmp.set("v.CurrentHTID", topicId);
				cmp.set("v.CurrentFieldName", fld);
	    		
	           		
	    		// Raise a synching "topic selected" event if in view mode
	    		if (cmp.get("v.OpMode") == 'View') {
	            	var appEvent = $A.get("e.c:selectTopic");
	            	appEvent.setParams({"RecordId" : topicId});
	        		appEvent.setParams({"SourceComponent" : cmp.get('v.ComponentId')});
	        		
					// Firing this event causes issues for utility bars listening
					// to autoform for guide purposes: they cannot differentiate this message from 
					// a contextualising call from (eg) a position detector, so select the same topic
					// at every callout opening:
					// Fire only if callouts not in play on autoform					
					
					if (cmp.get("v.CalloutOption") == 'Topic Selected Event Only') {
						appEvent.fire();
					}
	    		}
	
		        		
	    		// Only show our callout if options and/or current mode require this
	    		if (cmp.get("v.CalloutOption") == 'Topic Selected Event plus Topic view' || cmp.get("v.OpMode") != 'View') {
	    			
	    			
					// If callout viewing mode calls for it, hide entire autoform
					// and show a topic viewer with back button to display help
	
	    			var cmpDef = '';
					var TV = cmp.find("TopicViewer");
	    			
					// Dynamic components only supported in View mode
					if (cmp.get("v.OpMode") == 'View') {
						
						if (cmp.get("v.CalloutStyle") == 'Full') {
							// Default component def as topic viewer callout style requested
							cmpDef += 'c:IHDetail';
							cmpDef += '~ComponentId¬AFTopicViewer_' + cmp.get("v.ComponentId");
							cmpDef += '|HelpRecordId¬' + cmp.get("v.CurrentHTID");
							cmpDef += '|ToolContext¬CardAutoForm_TopicViewer';
							cmpDef += '|SuppressHeader¬true';
							cmpDef += '|SuppressFooter¬true';
						}
						
						// Use topic specific component definition, if specified via template	
						if (I.Element + '' != 'null' && I.Element + '' != 'undefined') {
							if (I.Element.iahelp__HelpTopic__r + '' != 'null' && I.Element.iahelp__HelpTopic__r + '' != 'undefined') {
								if(I.Element.iahelp__HelpTopic__r.iahelp__CalloutTemplate__r.iahelp__PageURL__c.indexOf(':') != -1) {
									cmpDef = I.Element.iahelp__HelpTopic__r.iahelp__CalloutTemplate__r.iahelp__PageURL__c;
									
									// In these cases, we need to enforce the 'correct' tool context, and component ID
									// as it is these that offer a back button
									cmpDef += '|ComponentId¬AFTopicViewer_' + cmp.get("v.ComponentId");
cmpDef += '|HelpRecordId¬' + cmp.get("v.CurrentHTID");									
									cmpDef += '|ToolContext¬CardAutoForm_TopicViewer';
								}								
							}
						}		
					}


					// For reconfigure mode, we'll use a dialogue - as opposed to IFRAME/Url or
					// embedded, spun up component
					if (cmp.get("v.OpMode") == 'Reconfigure' || isError > 0) {
						
					
						// In these cases, we want the helped page layout tree provider, filtered
						// to a particular helped element (the one whose reconfigure icon was clicked):
						// Supply this if known:
						var root;
var homeRoot;
var D1 = '^';

// v1.51: fixing bug / simplifying: in reconfigure mode, home root
// is required, so needs to be set (via U1, which has no home root itself) via root node

/*						
						if (I.Element + '' != 'null') {
							root = I.Element.Id;
							homeRoot = cmp.get("v.OCode") + D1 + I.FieldLabel;
							
						} else {
							// If element ID is not known (e.g., DDF fails) supply HPL identifier plus helped element identifier 
							root = cmp.get("v.OCode") + D1 + I.FieldLabel;
							homeRoot = root;
						}
*/

root = cmp.get("v.OCode") + D1 + I.FieldLabel;
					
						dlgMap = {
							"PDPositioningGroup": cmp.get("v.ComponentId") + '_ReconDlgU1',
							"Height": 595,
							"ColumnRatio": "33%",
							"SuppressHeaders": true, 
							"SuppressFooters": true,
							"ToolContext": "ReconfigureMode",
							"RootNode": root,
							"TreeSuppressListingTools": false,  
							"TreeNodeIconStyle": "Small",
							"TreeNodeProvider": "ServiceIHTrees.TNSHelpedPageLayouts" 
						};
					}

				
					// If we have a component def at this stage, spin it up
					TV.set("v.ComponentDef", cmpDef);
					TV.reInitialise();
					
					// Also, add a sizing class to LUX callout containing DIV, if in play 
					if (cmpDef != '') {
						$A.util.addClass(cmp.find("TVContainer"), 'TVContainerActive');
					} else {
						$A.util.removeClass(cmp.find("TVContainer"), 'TVContainerActive');
					}
	
	    				
					// Hide any other open callouts			
					var containers = cmp.find("CalloutContainer");
					containers.forEach(function (c) {
						$A.util.addClass(c, 'slds-hide');
						
						// Belt and braces for incomprehensible issues when LUX component is in play
						var S = document.getElementById(c.getElement().id);
						$A.util.addClass(S, 'slds-hide');
					});
	
					
					// Add a waiting class to the now active callout:
					// NB - only for VF types as LUX components have their own stencils...
					if (cmpDef == '') {
						$(cnt).addClass("IHTipPending");
					}


	    			// Show required item, depending on operational mode:
					// Set frame source to desired callout and move into position...
	        		if (cmp.get("v.OpMode") == 'Statistics') {
	        			U = CRoot + '/apex/iahelp__IHStats?IHLUX=true&HTID=' + topicId;	
	        			H = 145;                        
	        			
	        		
	        		} else if (cmp.get("v.OpMode") == 'Reconfigure' || isError > 0) {		
						helper.doDialogue('HelpedElementMaintenance', 'LUX', 'c:IHUtility1', dlgMap, 600, false, true, false, cmp, true);
						return;
	        				
	        		} else {
	        			// Note parameter to force use of LUX component override in onward (read more) links:
	        			// Also, if HTID is present, controller will not attempt to use element info for interaction 
	        			// logging, so withhold that here: use HPL / Element Ident / Element id approach
	        			
						U = CRoot + '/apex/' + Pg + '?LUXCaller=true&elemType=' + eType + '&ElemId=' + encodeURIComponent(Elem);
						U += '&HPL=' + I.Element.iahelp__HelpedPageLayout__r.iahelp__PageLayoutIdentifier__c;	
						U += '&ActiveId=' +  I.Element.Id;
	        		}
	        		
	
					helper.clearAdvancedDiags(cmp);        
					helper.logAdvancedDiags(cmp, 'IHAutoForm: mode is: ' + cmp.get("v.OpMode") + ' - Frame URL: ' + U);


					// Differentiate based on whether VF or dynamic component is in play:
					if (cmpDef != '') {

						// We need to show dynamic component, not IFRAME:
						// Differentiate based on embedded in line / replace spec
						if (cmp.get("v.CalloutStyle") == 'Full') {
							helper.toggleCallout(cmp, event, null);		
							return;
							
						} else {
							var TVC = cmp.find("TVContainer").getElement();	
							TVC.parentNode.removeChild(TVC);
							cnt.appendChild(TVC);
							
							$A.util.removeClass(TVC, 'slds-hide');
							$A.util.removeClass(cnt, 'slds-hide');
	
							$(cnt).animate({height: H + "px"}, 500);
									
						}
						
					} else {
						// Otherwise, continue to show IFRAME
						// Re-set frame URL then amend position / height etc to show progress...
						frm.src = "";	        			
						frm.height = H + 'px';                        
						frm.parentNode.removeChild(frm);
						$A.util.removeClass(frm, 'slds-hide');	
						cnt.appendChild(frm);
						
						containers.forEach(function (c) {
							if (c.getElement().id == fld + '_CalloutContainer') {
								$A.util.removeClass(c, "slds-hide");
							}
						});
						   
						$(cnt).animate({height: H + "px"}, 500);        		     	
					
						// ... before finally setting required frame source
					    frm.src = U;
					    
					} // End if callout is a LUX spin-up component		        		
	    		}	// End if callout required
			}	// End if layout item info was located


		} catch (e){
			console.log('Autoform - Error requesting help: ' + e);
		}

    },
    

    // Hide all callouts
    hideAllCallouts : function (cmp, event) {

    	var containers = cmp.find("CalloutContainer");

		containers.forEach(function (c) {
			$A.util.addClass(c, "slds-hide");
		});    
    },
    

	// Switches helped element help/unhelp highlight on and off for a given clicked element 
	toggleHighlight : function (cmp, event) {
	
		var elem = event.currentTarget;

		// Check which state the element is in and proceed accordingly:		
		// Unmarked -> ToBeHelped
		if (! $A.util.hasClass(elem, 'ToBeHelped') 		&&
			! $A.util.hasClass(elem, 'ToBeUnhelped')	&&
			! $A.util.hasClass(elem, 'IHHelpedSFElement')
			) {
			
			$A.util.addClass(elem, 'ToBeHelped');
		}
		
		// ToBeHelped -> Unmarked
		else if (elem.className.indexOf('ToBeHelped') != -1) {	
			$A.util.removeClass(elem, 'ToBeHelped');
		}
		

		// Helped -> ToBeUnhelped
		else if ($A.util.hasClass(elem, 'IHHelpedSFElement') &&
			! $A.util.hasClass(elem, 'ToBeUnhelped')
			) {
			
			$A.util.addClass(elem, 'ToBeUnhelped');			
		}	

		
		// ToBeUnhelped -> Helped
		else if ($A.util.hasClass(elem, 'ToBeUnhelped')) {
			$A.util.removeClass(elem, 'ToBeUnhelped');
		}
		
		
		// Note in diags the numbers of elements to be helped / unhelped
		cmp.set("v.Diags", this.getHelpEnablingStats(cmp));
	},
	
	
	// Provide info about the number of elements currently to be helped / unhelped
	getHelpEnablingStats : function (cmp) {
	
		var retVal;
		var toHelp = 0;
		var toUnhelp = 0;
		var containers = cmp.find("FieldContainer");
	
		containers.forEach(function (c) {
			if ($A.util.hasClass(c.getElement(), 'ToBeHelped')) {
				toHelp += 1;
			}

			if ($A.util.hasClass(c.getElement(), 'ToBeUnhelped')) {
				toUnhelp += 1;
			}
		});
				
		retVal = this.Internationalise(cmp, 'TitleSubtitleCreatingElements');
		retVal += ': ' + toHelp + ' - ';
		retVal += this.Internationalise(cmp, 'TitleSubtitleDeletingElements');
		retVal += ': ' + toUnhelp;
		
		return retVal;
	},
	

///////////////////////////////////////////////////////////////////////////
// Guide enable/view support
///////////////////////////////////////////////////////////////////////////

	// Offer a share link prompt for a given guide
	// c.f. jsCalloutHost.getVIPLink for possible additional logic
	showShareGuideLink : function (cmp, event, helper, GuideId) {
		
		var U = document.location.href;
					
		// We need to replace any anchor within the address 
		U = U.replace(document.location.hash, '');
					
		// Also need to remove any existing IHVIP details
		U = U.replace(document.location.search, '');
		
		// Add guide instructions
		U += '?iahelp__GID=' + GuideId;

		// Advise user	
		prompt(helper.Internationalise(cmp, '[QAMMessageVIPLinkCopyInstructionsGuides]'), U);
		
	},
	

	// Add a new guide
	newGuide : function (cmp, event, helper) {
	
		// Ensure any previous step information from other guides are cleared out
		// (Otherwise it will look like we have existing steps to delete)
		cmp.set("v.OriginalGuideEntries", []);	
		cmp.set("v.GuidedFields", []);			
		
		// To create a new guide, we must set to "no current guide"
		cmp.set("v.CurrentGuide", "");
		
		// Now save the guide
		helper.saveGuide(cmp, event, helper);
			
	},
	
	
	// Save amendments to the selected Guide
	saveGuide : function (cmp, event, helper) {
	
		var act = cmp.get("c.CCASaveChanges");
		
		var elemsC = [];								// Step creation instructions
		var elemsD = [];								// Step deletion instructions
		var PromptCtl;									// A guide prompt control
		var RLE;										// Reading list / guide entry associated with prompt
		var GID = cmp.get("v.CurrentGuide");			// The guide in play
		var D1 = cmp.get("v.Delimiter");				// Upload info string delimiter
		var GFlds = cmp.get("v.GuidedFields");			// The steps now present in the guide
		var OFlds = cmp.get("v.OriginalGuideEntries");	// The steps present in the guide when downloaded for GE mode
		var fldRemoved;									// Boolean indicating that a step has been removed from the guide
		var isError = false;							// Error flag used to halt operations (as return seems not to do so!!!)
		var j;											// For looping / counting
		var CRoot = cmp.get("v.CommunityRoot");


		// NOTE: here we must NOT ignore a community root that is blank / sent to us as 'null' - as we
		// need this to be part of page layout ID to differntiate from internal layouts						
		if (CRoot != '') {CRoot += '/';}
		
		
		// If no guide has been selected, assume a new guide is to be created
		if (GID == '') {
			GID = 'NEW';
			
			// Create a single entry in the new guide
			// If guide step is new (hence no current record based on an existing RL Entry) we need to mark
			// it with a "new" marker (*) - see assumptions in WServices.upsertGuideSteps and its comments on related legacy JS code
			
			// We want to enable the first field that is visible on the screen we're on:
			// Available fields should have been populated on entry to GE mode...
			var AFlds = cmp.get("v.AvailableFields");
			var FName = '';
			var I;
			
			// See getFormDefTools: available fields are delivered from controller as listing items, then converted on arrival 
			// to what is required by a duelling pick list (item objects with 'label' and 'value' (field API name) data)
			for (j=0; j<AFlds.length; j++) {
			
				console.log('IHAutoForm Save Guide - checking for guidable form element: ' + AFlds[j].value);
			
				I = helper.getIHLI(cmp, AFlds[j].value);
				if (I != null) {
					FName = I.Item.field;
					break;
				}
			}
			
			// Fail if we haven't found a field		
			if (FName == '') {
				helper.doNudge(cmp, helper.Internationalise(cmp, 'MessageGenericError') + ' (Save Guide)', '', 0);
				return;
			}
			
			elemsC.push('*' + FName + D1 
					+ FName + D1
					+ "Step 1 Name" + D1 
					+ "Step 1 Summary" + D1 
					+ "1" + D1
					+ "" + D1
					+ ""
					);
					
			console.log('IHAutoForm Save Guide - new guide - creating a single entry for: ' + FName);
			
		} else {
			//EXISTING GUIDE EDITS:
			
			// Iterate around fields now selected for the guide to create the list to upsert	
			// NB: Step order is taken directly from step list in all cases
			
			j = 0;				
			GFlds.forEach(function (F) {
			
				// Step creation instructions need to be in the form:
				// RLEId [D1] Element Identifier [D1] Step Name [D1] Step Summary [D1] Step Order [D1] Image URL [D1] Video URL
				// Attempt to find the guide prompt for each specified step, using its content to seed the data for RL entry upserts

				PromptCtl = helper.getGuidePrompt(cmp, F);
				if (PromptCtl != null) {
	
					RLE = PromptCtl.get("v.CurrentRecord");
					
					if (RLE != null) {
						// Existing, Autoform-based guide step, with RL entry in place in prompt member data as a consequence
						elemsC.push(RLE.Id + D1
										+ RLE.iahelp__HelpTopic__r.iahelp__GuidedElement__r.iahelp__Identifier__c + D1 
										+ PromptCtl.get("v.HeaderText") + D1 
										+ PromptCtl.get("v.BodyText") + D1 
										+ j + D1
										+ PromptCtl.get("v.ImageURL") + D1
										+ PromptCtl.get("v.VideoURL")
										);

					} else if (PromptCtl.get("v.CurrentRecordId") != '') {
						// Existing, NON-Autoform step: no full record, but prompt was built with knowledge of its RL entry ID
						elemsC.push(PromptCtl.get("v.CurrentRecordId") + D1
										+ PromptCtl.get("v.CurrentField") + D1 
										+ PromptCtl.get("v.HeaderText") + D1 
										+ PromptCtl.get("v.BodyText") + D1 
										+ j + D1
										+ PromptCtl.get("v.ImageURL") + D1
										+ PromptCtl.get("v.VideoURL")
										);
						
					} else {
						// If guide step is new (hence no current record based on an existing RL Entry) we need to mark
						// it with a "new" marker (*) - see assumptions in WServices.upsertGuideSteps and its comments on related legacy JS code
						elemsC.push('*' + PromptCtl.get("v.CurrentField") + D1 
										+ PromptCtl.get("v.CurrentField") + D1
										+ PromptCtl.get("v.HeaderText") + D1 
										+ PromptCtl.get("v.BodyText") + D1 
										+ j + D1
										+ PromptCtl.get("v.ImageURL") + D1
										+ PromptCtl.get("v.VideoURL")
										);
					}
					
				} else {
					/*
					WHAT TO DO HERE IF THE PROMPT IS NULL? THIS WILL BE THE CASE
					FOR NON-AF PROMPTS THAT HAVE NOT BEEN INSTANTIATED (CLICKED / REQUESTED)
					IN THE CURRENT GUIDE ENABLING SESSION.
					
					If prompt control is null, attempt to use the existing record for the save...
					 */

					RLE = null;
					OFlds.forEach(function (O) {
						if (O.iahelp__HelpTopic__r.iahelp__GuidedElement__r.iahelp__Identifier__c == F) {
							RLE = O;
						}
					});

					// If the copy of original RL entry data we stored on guide selection contains the selected step,
					// populate an upsert instruction with that... 
					if (RLE != null) {		
						elemsC.push(RLE.Id + D1
										+ RLE.iahelp__HelpTopic__r.iahelp__GuidedElement__r.iahelp__Identifier__c + D1 
										+ RLE.iahelp__HelpTopic__r.Name + D1 
										+ RLE.iahelp__HelpTopic__r.iahelp__Summary__c + D1 
										+ j + D1
										+ RLE.iahelp__HelpTopic__r.iahelp__ImageURL__c + D1
										+ RLE.iahelp__HelpTopic__r.iahelp__VideoURL__c
										);
	
					} else {
					
						// If we cannot obtain step details via an edited prompt control or an existing record,
						// this is a problem (as the entry still sits in our list of guided fields in the step editor)
						// so throw an error if you reach here... 
						alert(helper.Internationalise(cmp, 'MessageGenericError') + ': Error obtaining prompt / entry information for "' + F + '"');
						isError = true;
						return;
					}

				}	// End if prompt we found for current step
				
				j += 1;
				
			});	// End loop around guided fields

			
			console.log('IHAutoForm Save Guide - elements to create: ' + elemsC);
			
	
			// For deletes, iterate around the list of those ORIGINALLY downloaded with the guide, 
			// noting any which are no longer present: elemsD needs to be just an array of these, the RLE Ids to delete
			OFlds.forEach(function (O) {

				fldRemoved = true;
				
				GFlds.forEach(function (F) {
					PromptCtl = helper.getGuidePrompt(cmp, F);
					
					if (PromptCtl != null) {
						// Autoform field or non-autoform field that has been instantiated this guide enabling session:
						// If there is a prompt, it is either newly added (so will not be in the originals list, so cannot arise here)
						// or it will have a current record Id (i.e., guide / RL entry Id)
						
						RLE = PromptCtl.get("v.CurrentRecordId");				
						if (RLE != null) {
							if (RLE == O.Id) {
								// Field still present - so it's not for deletion
								fldRemoved = false;
							}
						}	
											
					} else {
						// Non-autoform guided element that has not been instantiated this editing session:
						// Unlike autoform fields, the identifier for these is always the same as the value in the guided fields list
						// (because there is no on-screen label - only the component's identifier (e.g., position detector grouping name)
						if (O.iahelp__HelpTopic__r.iahelp__GuidedElement__r.iahelp__Identifier__c == F) {
							// Field still present - so it's not for deletion
							fldRemoved = false;
						}
					}
			
				});
				
				if (fldRemoved == true) {
					elemsD.push(O.Id);
				}
			});
			console.log('IHAutoForm Save Guide - elements to delete: ' + elemsD);
			
		}	// End if new else existing guide
		

        act.setParams({ 
        	"oCode" : CRoot + cmp.get("v.OCode"),
            "Opts" : "2", 
            "elemsC" : elemsC,
            "elemsD" : elemsD,
            "GuideId" : GID,
        });                       
						                
        // Add callback to process returned results
        act.setCallback(this, function (response, cmp){

        	// On completion, force re-initialisation of guide listing if successful
        	if (response.getState() == 'SUCCESS') {
        		this.initialiseGuideListing(cmp, true);
        		
				// Return value is a complex progress message: to simplify this, 
				// leave reporting to separarte function			
				this.reportResults(cmp, helper, response.getReturnValue());

				// Prepare to 'refresh' list of guides (takes effect via accordion section toggle, see code elsewhere)
				var Lst = cmp.find("IHAFGuideList");
				Lst.set("v.CardConfig", "");
        		
        		
        		// If we've just created a new guide, we should have been supplied with its ID via return value
        		// at then end in [brackets] - see CCASaveChanges
        		if (GID == 'NEW') {
        			GID = response.getReturnValue();
        			if (GID.indexOf ('[') != -1 && GID.endsWith(']')) {
        				GID = GID.substring(GID.lastIndexOf('[') + 1, GID.length - 1);
        				
        				// If we locate the ID of the new guide, raise an event to select it 
    					var appEvent = $A.get("e.c:evtPassThrough");
		                appEvent.setParams({"SourceComponent": Lst.get("v.ComponentId")});
		                appEvent.setParams({"ActionCode": 'SelectGuideToEnable'});
		                
		                // Only need Guide ID here - others usually present in list click not necessary
		                appEvent.setParams({"Parameters": GID + '^'});		
		                appEvent.fire();        				
        			}
        		}
        		
        	} else {
        		cmp.set("v.Diags", "ERR!");
        	}
        	
		});

        $A.enqueueAction(act);

		// Having saved, re-set guide dirty flag
		cmp.set("v.isGuideDirty", false);
		
	},

	
	// Delete the specified guide (Guide ID supplied from listing pass through or similar)
	deleteGuide : function (cmp, event, helper, GuideId) {
	
		var act = cmp.get("c.deleteReadingList");
			
		act.setParams({ 
			"RLID": GuideId
		});              
	        
	    // Add callback to process returned results
	    act.setCallback(this, function (response, cmp){
	
	    	// On completion, force re-initialise of guide listing if successful and report any diagnostics
	    	if (response.getState() == 'SUCCESS') {
	    		this.initialiseGuideListing(cmp, true);
	    		this.reportResults(cmp, helper, response.getReturnValue());    		
			}
		});
		$A.enqueueAction(act);
			
	},


	// Initialise guide listing if this has not already been done
	initialiseGuideListing : function (cmp, forceReInitialisation) {
		var Lst = cmp.find("IHAFGuideList");
		
		if (Lst.get("v.CardConfig") != "Guides" || forceReInitialisation == true) {
    		Lst.set("v.CardConfig", "Guides");
    		Lst.set("v.recordId", cmp.get("v.OCode"));
    		
    		// We want our listing to show the selected/last clicked guide as list scrolls
    		// (unlike e.g., QAM topic listings, where scroll causes callout close and marker removal)
    		Lst.set("v.RetainSelectionOnScroll", true);
    		
    		// Override standard guide listing item click functionality so we can use selection to obtain steps etc
    		Lst.set("v.ListingClickActionCode", "SelectGuideToEnable");	    		

    		Lst.reInitialise();
    		
    		// If we initialise our guide listing, by definition we no longer have any selected guide
    		cmp.set("v.CurrentGuide", '');
    		
			// In turn, this means we should clear out any previously marked steps etc. plus cache
			this.clearAllGuideSteps(cmp);
			cmp.set("v.OriginalGuideEntries", []);
			
			// Clearing steps re-sets step dirty to clean, but we need also to set guide itself dirty here
			cmp.set('v.isGuideDirty', false);
			
			// Also, with no guide in play, we can no longer allow editing of prompts if we're in GE mode
			cmp.set("v.OpStyle", "");		
		}
	},
	
	
	// Clears all guide steps from our cache of those being worked on
	clearAllGuideSteps : function (cmp) {
	
		var obj = [];	
		var containers = cmp.find("FieldContainer");		// Overall field / item area divs
		var prompts = cmp.find("GuidePromptEditor");		// Prompt areas/divs within these
		var promptCtls = cmp.find('GuidePromptCtl');		// Actual prompt controls within these
		
		// Hide all prompts
		prompts.forEach(function (p) {
			$A.util.addClass(p.getElement(), "slds-hide");
		});		
		
		// Remove step selected styling
		containers.forEach(function (c) {
			$A.util.removeClass(c.getElement(), 'ToBeGuided');
		});
		
		// Clear out list of selected steps
		cmp.set("v.GuidedFields", obj);	
		
		// Clear out prompt contents		
		promptCtls.forEach(function (P) {
			P.reInitialise();
		});
		
		// In doing this, assume guide prompts are no longer dirty - so record this fact
		cmp.set("v.isGuidePromptDirty", false);

	},
	
	
	// Logs an AUTO-FORM FIELD as being part of a guide
	logGuideStepAF : function (cmp, IHLayoutItem, RLEntry) {
	
		var FieldAPIName = IHLayoutItem.Item.field;
		var GFlds = cmp.get("v.GuidedFields");
		var GFPromptNames = cmp.get("v.GuidePromptNames");
		
		var elem = document.getElementById(FieldAPIName + '_FieldContainer_' + cmp.get("v.ComponentId"));
		var isNewStep = true;
		var prompt;
		

		// Log the step in our collection of selected guide steps:
		// Only allow a given step to be logged once
		GFlds.forEach(function (F) {
			if (F == FieldAPIName) {
				isNewStep = false;
			}
		});
		if (isNewStep == true) {
			GFlds.push(FieldAPIName);
			
			// Advise the guide prompt associated with this step (with its guided element - i.e., field) 
			// of the RL entry, so it can set prompt data accordingly...
			prompt = this.getGuidePrompt(cmp, FieldAPIName);
			
			if (prompt != null) {
				// If this step is being logged via clicking a field not saved in the guide's RL, 
				// RL Entry will be null, so ignore here as there's no need to reflect anything into the prompt
				if (RLEntry != null) {

					prompt.set("v.CurrentRecord", RLEntry);
					prompt.set("v.CurrentRecordId", RLEntry.Id);
					prompt.set("v.HeaderText", RLEntry.iahelp__HelpTopic__r.Name);
					prompt.set("v.BodyText", RLEntry.iahelp__HelpTopic__r.iahelp__Summary__c);		
					prompt.set("v.ImageURL", RLEntry.iahelp__HelpTopic__r.iahelp__ImageURL__c);		
					prompt.set("v.VideoURL", RLEntry.iahelp__HelpTopic__r.iahelp__VideoURL__c);		
					prompt.set("v.ShowCallout", RLEntry.iahelp__HelpTopic__r.iahelp__GuideCallout__c);		
					prompt.set("v.CurrentLocalStep", RLEntry.iahelp__ReadingOrder__c);	
					prompt.set("v.CurrentField", IHLayoutItem.FieldLabel);	
					
					// Keep a copy of the prompt topic names associated with each step for 
					// use in non-linear guides
					GFPromptNames.push(RLEntry.iahelp__HelpTopic__r.Name);
					
					// If we have an entry, let's assume it's best to pre-set to view mode
					prompt.set("v.OpMode", "View");	

				} else {
					// If we don't have an entry, let's assume edit mode is the best place to start
					prompt.set("v.OpMode", "Edit");							
				}
			}
		}
		
		cmp.set("v.GuidedFields", GFlds);	
		cmp.set("v.GuidePromptNames", GFPromptNames);	

		
		// Also, in guide editing mode, add a class to the element to show that it is being guided
		if (cmp.get("v.OpMode") == 'GuideEnable') {
			$A.util.addClass(elem, 'ToBeGuided');
		}
			
	},
	
	
	// Logs an element 'beyond' the autoform (e.g., a position detector) as being part of a guide	
	logGuideStepPD : function (cmp, StepElementIdentifier) {
	
		var isNewStep = true;		
		var GFlds = cmp.get("v.GuidedFields");
	
		// Log the step in our collection of selected guide steps:
		// Only allow a given step to be logged once in GE mode
		
		GFlds.forEach(function (F) {
			if (F == StepElementIdentifier) {
				isNewStep = false;
			}
		});
		
		if (isNewStep == true || cmp.get("v.OpMode") == 'View') {
			GFlds.push(StepElementIdentifier);
			cmp.set("v.GuidedFields", GFlds);
			cmp.set("v.GuidePromptNames", GFlds);	
		}
		
		// Also, in guide editing mode, add a class to the element to show that it is being guided
		// To do this to non-autoform fields (whose markup we cannot directly control)
		// we issue a message to which they should respond...
		if (cmp.get("v.OpMode") == 'GuideEnable') {
			var appEvent = $A.get("e.c:evtPassThrough");
			appEvent.setParams({"SourceComponent": cmp.get("v.ComponentId")});
			appEvent.setParams({"ActionCode": 'MarkGuideStep'});
			appEvent.setParams({"Parameters": StepElementIdentifier});			
			appEvent.fire();
		}
	},
	
	
	// Add a non-field, such as a position detector, to the list of items available to participate in a guide
	logAvailableGuideElement : function (cmp, Ident, GEPromptCtl) {
	
		var AFlds = cmp.get("v.AvailableFields");
		var XCs = cmp.get("v.ExternalPromptControls");
		var isNewStep = true;		
		var item;


		AFlds.forEach(function (F) {
			if (F.value == Ident) {
				isNewStep = false;
			}			
		});
		
		if (isNewStep == true) {
			item = {
				"label": '>Pos. Detector: ' + Ident,
				"value": Ident,
			};
			
			AFlds.push(item);
			cmp.set("v.AvailableFields", AFlds);		
			
			// As well as adding an available 'field' to the list of those that can be selected,
			// keep a copy of the prompt control that made itself available via the logging request
			XCs.push(GEPromptCtl);
			cmp.set("v.ExternalPromptControls", XCs);
		}
	
	},
	
	
	// Get the guide prompt sub-component of this auto-form that is associated with a given element (field on autoform or external item - eg position detector)
	getGuidePrompt : function (cmp, FieldAPIName) {
		
		var retVal = null;
		var promptSuffix = '_GuidePromptCtl';
		var promptCtls = cmp.find('GuidePromptCtl');
		var XCs = cmp.get("v.ExternalPromptControls");
		var X;
		var i;

		for (i=0; i < promptCtls.length; i++) {
			if (promptCtls[i].get("v.ComponentId") == FieldAPIName + promptSuffix) {
				retVal = promptCtls[i];
				break;
			}
		}
		
		// If this fails to return anything, look to non-field controls
		if (retVal == null) {
		
			console.log('Get Guide Prompt: seeking external prompt control for ' + FieldAPIName);	
		
			for (i=0; i < XCs.length; i++) {
				try {
				
					X = XCs[i].get("v.theComponent");
					console.log('Get Guide Prompt: generated component is: ' + X);
					
					if (X.get("v.ComponentId") == FieldAPIName + promptSuffix) {
		
						console.log ('Get Guide Prompt: external prompt control located for ' + FieldAPIName);
						retVal = X;
						break;
						
					} else {		
						console.log ('Get Guide Prompt: no match: ' + X.get("v.ComponentId"));
					}
					
				} catch (e){
					console.log('Get Guide Prompt: error ' + e);		
				}
			}
		}		
		
		return retVal;
	},
	
	
	// Return instructions suited to a component generator to build a guide prompt, 
	// passing in a reading list entry if this is for an existing guide step
	// or newly guided element identifier if for a new step
	// plus current step number and total if known (or -1 if not)
	constructGuidePrompt : function (cmp, RLE, newIdent, curStep, totalSteps) {
	
		console.log('Autoform - Construct Guide Prompt: ' + newIdent);	
	
		var PromptControl = 'c:IHCalloutPrompt~';
		var RLType = cmp.get("v.CurrentGuideType");
		
		try {
			if (RLE != null) {
				// Prompt for an existing step
				console.log('Construct Guide Prompt: Guide entry supplied - populating prompt');
				
				// COMPONENT ID MUST BE FIRST PARAMETER HERE! SEE (EG) POSITION DETECTORS LISTENING FOR CUE GUIDE STEP MESSAGES...
				PromptControl += 'ComponentId¬' + RLE.iahelp__HelpTopic__r.iahelp__GuidedElement__r.iahelp__Identifier__c +'_GuidePromptCtl|';
				PromptControl += 'CurrentField¬' + RLE.iahelp__HelpTopic__r.iahelp__GuidedElement__r.iahelp__Identifier__c + '|';

				// Guide type (linear / non-) : stored in member data on guide selection
				PromptControl += 'ReadingListType¬' + RLType + '|';			

				// We can't serialize in the whole record, so just supply record ID here...				
				PromptControl += 'CurrentRecordId¬' + RLE.Id +'|';
				
				PromptControl += 'HeaderText¬' + RLE.iahelp__HelpTopic__r.Name + '|';
				PromptControl += 'BodyText¬' + RLE.iahelp__HelpTopic__r.iahelp__Summary__c + '|';
				PromptControl += 'ImageURL¬' + RLE.iahelp__HelpTopic__r.iahelp__ImageURL__c + '|';
				
				if (RLE.iahelp__HelpTopic__r.iahelp__VideoURL__c != '' && RLE.iahelp__HelpTopic__r.iahelp__VideoURL__c != null && RLE.iahelp__HelpTopic__r.iahelp__VideoURL__c + '' != 'null') {
					PromptControl += 'VideoURL¬' + RLE.iahelp__HelpTopic__r.iahelp__VideoURL__c + '|';
				}
				
			} else {
				// Set up a blank guide prompt if no existing entry was supplied
				console.log('Construct Guide Prompt: No Guide entry supplied - producing blank prompt');
		
				// COMPONENT ID MUST BE FIRST PARAMETER HERE! SEE (EG) POSITION DETECTORS LISTENING FOR CUE GUIDE STEP MESSAGES...
				PromptControl += 'ComponentId¬' + newIdent +'_GuidePromptCtl|';
				PromptControl += 'CurrentField¬' + newIdent + '|';

				// Guide type (linear / non-) : stored in member data on guide selection
				PromptControl += 'ReadingListType¬' + RLType + '|';			
				
				// Leave record ID blank...				
				PromptControl += 'CurrentRecordId¬|';

				PromptControl += 'HeaderText¬|';
				PromptControl += 'BodyText¬|';
				PromptControl += 'ImageURL¬|';
				PromptControl += 'VideoURL¬|';
				
				PromptControl += 'AllowEdits¬true|';
				PromptControl += 'OpMode¬Edit|';
			}
			
			
			// Common parameters - step x of y values
			PromptControl += 'CurrentLocalStep¬' + curStep + '|';			
			if (totalSteps != -1) {
				PromptControl += 'TotalLocalSteps¬' + totalSteps + '|';
			}
						
			// Common parameters - editing rights plus resepct for current operating mode
			PromptControl += 'AllowEdits¬' + (cmp.get("v.isAuthor") == true && cmp.get("v.OpMode") == 'GuideEnable') + '|';
			
			// Common parameters - translation codes		
			PromptControl += 'AdviceLabelModified¬' + cmp.get("v.AdviceLabelModified") + '|';
			PromptControl += 'FieldLabelName¬' + cmp.get("v.FieldLabelName") + '|';
			PromptControl += 'FieldLabelSummary¬' + cmp.get("v.FieldLabelSummary") + '|';
			PromptControl += 'FieldLabelImageURL¬' + cmp.get("v.FieldLabelImageURL") + '|';
			PromptControl += 'FieldLabelVideoURL¬' + cmp.get("v.FieldLabelVideoURL") + '|';
			PromptControl += 'TipButtonClose¬' + cmp.get("v.TipButtonClose") + '|';
			PromptControl += 'TipGenericEdit¬' + cmp.get("v.TipGenericEdit") + '|';
			PromptControl += 'TipView¬' + cmp.get("v.TipView") + '|';
			PromptControl += 'QAMAdviceLabelGuideStepCounter1¬' + cmp.get("v.QAMAdviceLabelGuideStepCounter1") + '|';
			PromptControl += 'QAMAdviceLabelGuideStepCounter2¬' + cmp.get("v.QAMAdviceLabelGuideStepCounter2") + '|';
			PromptControl += 'QAMTitleButtonGotoNextStep¬' + cmp.get("v.QAMTitleButtonGotoNextStep") + '|';
			PromptControl += 'QAMButtonGotoNextStep¬' + cmp.get("v.QAMButtonGotoNextStep") + '|';
			
			// Note this item is not used in markup so set differently to reduce member data load...
			PromptControl += 'QAMMessageGuideStepsCompleted¬' + this.Internationalise(cmp, '[QAMMessageGuideStepsCompleted]') + '';
		
		} catch (e) {
			console.log('Construct Guide Prompt: Error: ' + e);
		}
		
		console.log('Construct Guide Prompt: returning prompt');		
		return PromptControl;
		
	}, 	
	
	
	// Show / hide guide prompt plus GE mode marking for a given element in response to click in guide enable mode
	toggleGuidePromptEditor : function (cmp, event, helper) {
	
		var elem = event.currentTarget;
		var fld = elem.id.replace('_FieldContainer_' + cmp.get("v.ComponentId"), '');
		var I;
		
		// Show the prompt we're in...
		this.showGuidePrompt(cmp, helper, fld, -1);
				
		// Add the prompt's element to the list of those in the guide (i.e., guide steps)
		I = this.getIHLI(cmp, fld);
		this.logGuideStepAF(cmp, I, null);
		
	},
	
	
	// Show a guide prompt without any mode styling in response to a request for a specific field's prompt
	showGuidePrompt : function (cmp, helper, FieldAPIName, StepNum) {
	
		// DON'T KNOW WE'RE SOMETIMES NOT ALWAYS GIVEN A FIELD NAME!
		// SEE ALSO SelectGuideToEnable PASS THROUGH...
		if (FieldAPIName + '' == 'undefined') {
			return;
		}	

		console.log('Autoform - Show Guide Prompt: ' + FieldAPIName);		

		var ctl = this.getGuidePrompt (cmp, FieldAPIName);
		var prompt = document.getElementById(FieldAPIName + '_GuidePromptEditor_'  + cmp.get("v.ComponentId"));
		var fieldCnt = document.getElementById(FieldAPIName + '_FieldContainer_' + cmp.get("v.ComponentId"));
		var prompts = cmp.find("GuidePromptEditor");
		var GFlds = cmp.get("v.GuidedFields");			
		var T;
		var OFlds = cmp.get("v.OriginalGuideEntries");
		var RLE = OFlds[StepNum];
		//var act = cmp.get("c.logLUXInteraction");
		var D1 = '^';


		// Need to find which section the prompt is in and expand it
		// Do nothing if form section toggling is disabled
		
		// The following code locates and opens the desired section - but the contents - including required guide prompts 
		// do not render in time to be un-hidden, below! As there is no obvious event to hook as things do render, 
		// it doesn't look like we can take a just in time approach here...
		
		/*
		if (cmp.get("v.SuppressSectionToggles") == false) {
			
			var IHLI = helper.getIHLI(cmp, FieldAPIName);
			var idx = helper.getIHLElement(cmp, IHLI, 'SectionIndex');
			
			var Lst = cmp.get("v.ListingItems");
			var Sects = Lst[0].Sections;
			
			Sects[idx].Expanded = true;
			cmp.set("v.ListingItems", Lst);    	
		
		}
		*/


		// Hide all guide prompts
		prompts.forEach(function (p) {
			$A.util.addClass(p.getElement(), "slds-hide");
		});
		
		// Show the one we're interested in...
		$A.util.removeClass(ctl, 'slds-hide');
		$A.util.removeClass(prompt, 'slds-hide');
		
		// Need to scroll prompt into view here: treatment varies by circumstance
		// NB: only do this in guide viewing (not enable) mode
		if (cmp.get("v.OpMode") == 'View') {


			// Show callout where required: only do this for 'on-form' prompts
			// I.e., those on the Autoform, not any off-form / Position Detector elements...
			if (ctl + '' != 'null') {
				if (ctl.get("v.ShowCallout") + '' == 'true') {
					
					var fldAPIName = ctl.get("v.ComponentId").split('_GuidePromptCtl').join('');
					var helpIconCtl = document.getElementById(fldAPIName);
					helper.requestHelp(cmp, event, helper, helpIconCtl);
					
				} else {
					// Close all callouts
					helper.hideAllCallouts(cmp, event);					
				}
				
			} else {
				// Close all callouts
				helper.hideAllCallouts(cmp, event);				
			}		
		
		
			// Check we got the guide prompt: we may not have if the step references
			// an element that, for whatever reason, is not on our form:
			if (ctl + '' == 'null') {

				console.log('Autoform - Show Guide Prompt: Guide prompt control not located in View mode for ' + FieldAPIName + ' - constructing...');		
			
				// If this is a deliberately logged 'non-field' step (see response to guide listing / SelectGuideToEnable),  
				// treat as a reason to issue a message requesting off-form guide step information be shown...

				// Find requested non-field entry in the steps originally logged for this guide
				prompt = helper.constructGuidePrompt(cmp, RLE, FieldAPIName, RLE.iahelp__ReadingOrder__c + 1, GFlds.length);

				if (prompt == null) {
					prompt = helper.constructGuidePrompt(cmp, null, FieldAPIName, GFlds.length, GFlds.length);
				}
				
				// NB: recipient off-autoform component is responsible for scrolling itself into view
				var appEvent = $A.get("e.c:evtPassThrough");
				appEvent.setParams({"SourceComponent": cmp.get("v.ComponentId")});
				appEvent.setParams({"ActionCode": 'CueGuideStep'});
				appEvent.setParams({"Parameters": prompt});
				appEvent.fire();
				
			} else {
				if (this.isLayoutOverride(cmp) == false) {
					// Non-overrides - component in line with page
					T = ctl.getElement().offsetTop;		
					$(document).scrollTop(T);
							
				} else {
					// Overrides / dialogue situation: scroll to field container
					// and allow for fixed/floating guide menus at top of screen (don't scroll underneath them)
					T = fieldCnt.offsetTop;		
					var CB = cmp.find("recordEditFormBody");
					$(CB.getElement()).animate({scrollTop: T-50}, 800); 
				}
			}	
			
			
			
		/*	try {
				act.setParams({ 
					"iTyp" : "21", 
					"Description" : 'Guide Prompt Viewed - Step: ' + RLE.iahelp__ReadingOrder__c,
					"IHContext" : cmp.get("v.recordId") + D1 + RLE.iahelp__HelpReadingList__c + D1 + RLE.iahelp__HelpTopic__c
				});     */    
				
				              
			/*	act.setCallback(this, function (response, cmp){ 
					if (response.getState() === 'SUCCESS') {
						// Do nothing if OK
					} else {
						console.log('Autoform - server call to log Guide Step viewed interaction failed');
					}
				});  */
				
				// Send action
				//$A.enqueueAction(act);

                // Log a guide topic viewed interaction
					helper.logLUXInteractions(cmp, 21, 'Guide Prompt Viewed - Step: ' + RLE.iahelp__ReadingOrder__c, cmp.get("v.recordId") + D1 + RLE.iahelp__HelpReadingList__c + D1 + RLE.iahelp__HelpTopic__c).then((response) => {
					if (response.getState() === 'SUCCESS') {
						// Do nothing if OK
					} else {
						console.log('Autoform - server call to log Guide Step viewed interaction failed');
					}
				});
	
		/*	} catch (e) {
				console.log('Autoform - error logging Guide Step viewed interaction: ' + e);
			}	*/		
			
			
		}	// End if in guide view mode / scrolling prompt into view
	},
	

///////////////////////////////////////////////////////////////////////////
// Other
///////////////////////////////////////////////////////////////////////////

    // Provide a means to re-set some key component attributes without the need for a full re-build
    setViewMode : function (cmp, event) {
		cmp.set("v.OpMode", "View");
		cmp.set("v.OpStyle", "");	
		cmp.set("v.OpToolTip", cmp.get("v.TitleHelpedElement"));			
		cmp.set("v.Diags", this.Internationalise(cmp, "TipGenericOK"));    
    },
    
	
	// Toggle callout open / close state
	toggleCallout : function (cmp, event, cnt) {
		
		if (cnt == null) {
			// If we're not given a container, assume full screen / dynamic component

			var AFContainer = cmp.find("AFContainer");
			var TVContainer = cmp.find("TVContainer");
			
			//$A.util.toggleClass(AFContainer, 'slds-hide');
			//$A.util.toggleClass(TVContainer, 'slds-hide');

			$A.util.addClass(AFContainer, 'slds-hide');
			$A.util.removeClass(TVContainer, 'slds-hide');
			
		} else {
			// If topic is already in play, toggle visibility where options require this
			// (Otherwise do nothing)

			var opt = cmp.get("v.GlobalSettings").iahelp__CalloutClosureBehaviour__c;
			if (opt != '2' || $A.util.hasClass(cnt, 'slds-hide')) {
				// If we are given a container, show it
				$A.util.toggleClass(cnt, 'slds-hide'); 
			}
		}
	},

	
	// Close any open callout
	closeActiveCallout : function (cmp, event) {
		var fld = cmp.get("v.CurrentFieldName");
		var cnt = document.getElementById(fld + '_CalloutContainer');	
		
		$(cnt).addClass('slds-hide');
		cmp.set("v.CurrentFieldName", "");
		cmp.set("v.CurrentHTID", "");	
	},
	
	
    // Close accordion section
    closeAccordion : function (cmp, clickedId) {
    
    	var sect = cmp.find(clickedId.replace('_Summary', '_Section')); 
    	var twst = cmp.find(clickedId.replace('_Summary', '_Twisty')); 
    	var opt = clickedId.replace('_Summary', '');

    	$A.util.removeClass(sect, 'slds-is-open');
    	$A.util.removeClass(twst, 'nodeExpanded');
    	
    },	

	
	// Cancel out of data edits made on the auto-form form (i.e., close it without any data save)
	doCancel : function (cmp, event, helper) {
		
		// Offer a back out if form is dirty
		if (cmp.get("v.isDirty") == true) {
			if (! confirm(this.Internationalise(cmp, '[QAMMessageDirtyWarning]'))) {
				return;
			}
		}	
		
		// Cancellation procedure depends on whether we have a record (editing / viewing etc as opposed to new)
		var rec = cmp.get("v.recordId");
		
		if (rec != null) {
			// If editing, return to the record that was being edited:
			// Nature of returning here depends on settings
			if (cmp.get("v.OnSaveAction") == 'Report only') {
			
				// Here, we just want to revert to view mode
				cmp.set("v.DataMode", 'View');
				
				// Revert form as a whole and individual fields to clean / unedited				
				cmp.set("v.isDirty", false);
				this.resetFieldDirtyFlags(cmp);

				cmp.set("v.isInitialised", false);				
				
			} else {
				// Here we want to navigate back to unsaved record
/*				
				var sObectEvent = $A.get("e.force:navigateToSObject");

				var recId;
				var relRecId = cmp.get("v.RelRecordId");
				
				if (relRecId != '' && relRecId + '' != 'undefined') {
					recId = relRecId;
				} else {
					recId = rec;
				}
				
				sObectEvent .setParams({
					"recordId": recId ,
				    "slideDevName": "detail"
				});

				 sObectEvent.fire();  
*/

var recId;
var relRecId = cmp.get("v.RelRecordId");

if (relRecId != '' && relRecId + '' != 'undefined') {
	recId = relRecId;
} else {
	recId = rec;
}

var navService = cmp.find("navService");

var pDef = 'RECORD - VIEW^' + recId;

// Obtain navigable page reference object from string definition    	
var pRef = helper.getPageReferenceFromDef(pDef);

if (pRef != null) {
    event.preventDefault();
    navService.navigate(pRef, true);
}


   
			}			
			         	
		} else {
			// If on a new record, return to the object listing screen
			var sObectEvent = $A.get("e.force:navigateToObjectHome");
			sObectEvent .setParams({
			    "scope": cmp.get("v.OName")
			 });
			 sObectEvent.fire();     
		}			
							
	},
	
	
	// Report appropriately on results of an operation
	reportResults : function (cmp, helper, retVal) {
	
		// In case they're needed, log complete result value
		console.log('IHAutoForm Report Results: ' + retVal);

        // Beyond this, only act if we've been passed some kind of message
        if (retVal != '' && retVal + '' != 'null') {
			var sGE = helper.Internationalise(cmp, 'MessageGenericError');
            var sNR = helper.Internationalise(cmp, 'MessageNoRights');
            var sOK = helper.Internationalise(cmp, 'MessageGenericTaskComplete');

			if (retVal.indexOf(sGE) != -1 || retVal.indexOf(sNR) != -1 || retVal.indexOf('Error ') != -1) {
                alert(retVal);
            } else {
                cmp.set("v.Diags", sOK);
                helper.doNudge(cmp, sOK, '', 6000);
            }
        }
	},
	
	
	// Provides an ongoing check of whether or not to float editing button bar (set on entry to edit mode)
	setFloatCheckTimer : function (cmp, event, helper) {
	    
	    // DISABLE FOR NOW IN MODAL SITUATIONS
	    if (helper.isLayoutOverride == true) {return;}
	    
	    
	    window.setInterval($A.getCallback(function() {
	        
	        try {
	            // Find our static 'marker' of button bar position
	            var marker = cmp.find("ButtonBarMarker").getElement();
	            
	            // Set actual button bar width based on this on ongoing basis (e.g., in case of window re-sizing)
	            cmp.set("v.FloatButtonBarW", marker.offsetWidth);
	            
	            // Get the marker's top offset
	            var YMarker = marker.getBoundingClientRect().top;
	            
	            // Get button bar rendered height
	            var bbh = cmp.find("ButtonBar").getElement().offsetHeight;
	                       
	            // Calculate the cross over point at which button bar float status should change
	            // This varies depending on whether we're entering or leaving float mode
	            // of any
	            
	            var YMax = window.innerHeight - cmp.get("v.H_UtilityBar");
	             
	            // Float if marker adjusted for button bar height is below this
	            cmp.set("v.FloatButtonBar", YMarker + bbh > YMax);
	            
	        } catch (e) {
	        }
            
        }), 500);	
		
	},
	
		
})