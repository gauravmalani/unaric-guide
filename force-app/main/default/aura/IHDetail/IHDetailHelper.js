({

	// Get the largely invariant, cacheable information used on cards 
	// then cue initialisation
	initialiseGlobals : function(cmp, event, helper) {

		helper.showSpinner(cmp);

		var SkipGlobals = cmp.get("v.SkipGlobals");	

SkipGlobals = true;
		
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
                
					// If non-topic, raise select instead
					var keyTypes = cmp.get("v.GlobalSettings.iahelp__SFObjectIds__c");
					var theRecord = cmp.get("v.HelpRecordId");
					
					if (keyTypes + '' != 'null') {
						keyTypes = keyTypes.split('^');
					} else {
						// If we can't check for Help record key type, arrange things
						// so we will act as for a Topic (see below)
						keyTypes = [];
						
						try {
							keyTypes.push(theRecord.substring(0,3));
						} catch (e) {
							// No record for the time being - ignore here
						}
					}

					if (theRecord + '' == 'null') {
						theRecord = '';
					}

					if (theRecord != '') {
					
						// Special case for record ID: we have a detokenizer in some cases but {! curly syntax} can
						// not be used for this in page layout design attribute (as SFDC have broken this!!!)
						// Note that we have to do this BEFORE checking record type, below, hence this is outside of 
						// that IF block
						if (theRecord.toUpperCase() == '[RECORDID]') {
							theRecord = cmp.get("v.recordId");
							cmp.set("v.HelpRecordId", theRecord);
						}

					
						if (theRecord == '[None]') {
							// If [None] specified, continue as if a help topic, as this is handled
							// by the getTools action code...
							this.initialiseDetails(cmp, event, helper);
							
						} else if (theRecord.substring(0,3) != keyTypes[0]) {	
							// If a non-help topic, issue record selected event for onward handling
						    var appEvent = $A.get("e.c:selectTopic");
						    appEvent.setParams({"RecordId" : theRecord});
						    appEvent.setParams({"SourceComponent" : cmp.get('v.ComponentId') + '_SpecialComp'});
						    appEvent.fire();

						} else {     
							// For topics, continue as normal
						    this.initialiseDetails(cmp, event, helper);
							
						}
					
					} else {        
						this.initialiseDetails(cmp, event, helper);
					}
                    
                }
                
            });
            $A.enqueueAction(act);	
                
        } else {
            this.initialiseDetails(cmp, event, helper);
        }		

	},
	

    // Cue initial record
	initialiseDetails : function(cmp, event, helper) {
                        
		var HTID = helper.getURLParm(cmp, 'iahelp__HTID');
		var SkipGlobals = cmp.get("v.SkipGlobals");
        var TCxt = cmp.get("v.ToolContext");
        var act = cmp.get("c.getTools");
		

		// Check for an override selected record (HTID) in URL        
		if (HTID != '' && cmp.get("v.CheckURLParams") == true) {
			cmp.set("v.HelpRecordId", HTID);
			
			// Set latch that says we've considered URL (on page load and not thereafter)
		    cmp.set("v.CheckURLParams", false);
			
		}
        
if ((cmp.get("v.HelpRecordId") == '' || cmp.get("v.HelpRecordId") + '' == 'undefined' || cmp.get("v.HelpRecordId") + '' == 'null')
		&& (cmp.get("v.recordId") + '' == '' || cmp.get("v.recordId") + '' == 'undefined' || cmp.get("v.recordId") + '' == 'null')) {

/*	
	alert('IHDetail.initialiseDetails - record new?');
	
	// Proceed here as per new button?	
	var appEvent = $A.get("e.c:evtPassThrough");
    appEvent.setParams({"SourceComponent": cmp.get("v.ComponentId")});
    appEvent.setParams({"ActionCode": 'TopicAdd'});
    appEvent.setParams({"Parameters": ''});
    appEvent.fire();
*/
	
}


		// Allow page-author specified tool context, noted above, to override our usual defaults
		if (TCxt != '' && TCxt != '[DEFAULT]' && TCxt != 'QAM') {
			cmp.set("v.ToolContext", TCxt);
		} else {
		    cmp.set('v.ToolContext', 'CardHelpTopic');
		}           

        
        cmp.set('v.ActionCode', 'HelpTopic');
        cmp.set('v.IHContext', cmp.get("v.HelpRecordId"));

        act.setParams({ 
        	"IHContext" : cmp.get('v.recordId'), 
            "ToolContext" : cmp.get('v.ToolContext'), 
            "ActionCode" : cmp.get('v.ActionCode'),
            "ClientComponentId" : cmp.get("v.ComponentId"),
            "Params" : cmp.get("v.HelpRecordId"),
            "SkipGlobals" : SkipGlobals,
        });                       


        // Create a callback that is executed after the server-side action returns
        act.setCallback(helper, function (response, cmp){
            
            try {
            	helper.logAdvancedDiags(cmp, 'IHDetail: callback cueing process tools...');
            
                helper.processTools(response, cmp, SkipGlobals);
                
                var obj = cmp.get("v.ListingItems")[0];

                // If, for whatever reason, we have no current record, set default titles etc
                if (obj + '' === 'undefined') {
                    cmp.set("v.Title", helper.Internationalise(cmp, 'TitleNoTopicSelected'));
                    
                } else {
                
                
        			cmp.set("v.CurrentRecord", obj);
                    cmp.set('v.IHContext', obj.Id);
                    cmp.set('v.HelpRecordId', obj.Id);
                    cmp.set("v.Title", obj.Name);


					// Write the retrieved record back into our cache
					var HTs = cmp.get("v.HelpTopics");
					var i;
					
					for (i=0; i < HTs.length; i++) {
						try{
					    	if (HTs[i].Id == obj.Id) {
					    		HTs[i] = obj;
					    		break;
					    	}
						} catch (e) {}
					}
					
					cmp.set("v.HelpTopics", HTs);

                    
					// Obtain the keyword parsed version of our topic description - this is NOT the one
					// in the current record / topic itself, as this needs to be the true, "clean" version
					// in order to allow for correct edits: this should have been left in "pass through" 
					// data set...
					
                    var D = helper.getSafeHTML(cmp.get("v.PassThroughData")[0].Value);					
					cmp.set("v.KeywordParsedDescription", D);                    


                    // Topic does not set height in LUX - it's the component itself,
                    // whose height is set through designer by page author
                    //cmp.set("v.Height", obj.iahelp__HeightBeforeScrolling__c + 120);
                    
                    // Add any "recently modified" marker where relevant:
                    // Note that we are able to do this server-side for lists (where
                    // we return generic list items) whereas here we have a help topic
                    // record - which does not of itself have a recency flag...
                    
                    var hrs = cmp.get("v.GlobalSettings").iahelp__UpdateMarkerHours__c;                    
                    var dTRecenyLimit = new Date(new Date().valueOf() - hrs*60*60*1000);
                    var dTModified = new Date(obj.LastModifiedDate);

                    if (dTModified > dTRecenyLimit) {
                        cmp.set("v.RecentlyAmendedClass", "IHCollateralUpdated");
                    } else {
                        cmp.set("v.RecentlyAmendedClass", "");
                    }
                    

					// Keep track of selected vote set for use in other screen furniture
					cmp.set("v.SelectedVoteSet", obj.iahelp__HelpVoteSet__c);
					helper.lookupRelatedObjects(cmp, obj.iahelp__HelpVoteSet__c);


					// Note the ID of the Help Topic Templates object (from global settings)
					try {
						var tObj = cmp.get("v.GlobalSettings").iahelp__SFObjectIds__c;
						tObj = tObj.split('^');
						cmp.set("v.TemplateObjectId", tObj[3]);                    
					} catch (e) {
						// If for some reason we don't get global settings, there's little we can do...
					}


	                // Note some form-specific translations
	                cmp.set("v.AdviceLabelGuideSettings", this.Internationalise(cmp, 'AdviceLabelGuideSettings'));
	                cmp.set("v.AdviceLabelProperties", this.Internationalise(cmp, 'AdviceLabelProperties'));
	                cmp.set("v.TipButtonFullSizeImage", this.Internationalise(cmp, 'TipButtonFullSizeImage'));
	                cmp.set("v.TitleTabImage", this.Internationalise(cmp, 'TitleTabImage'));
	                cmp.set("v.TitleTabVideo", this.Internationalise(cmp, 'TitleTabVideo'));


					// Adopt custom topic layout / designer template, if specified:
					// NB: this can be supplied as a design parameter, or topic setting,
					// with precedence set by component attribute. 
	                helper.refreshLayoutDesign(cmp, event, helper);

					
					// Initialise our sub-component, if required by lighting template
					helper.initialiseTemplateComponents(cmp, event, helper);
					
                  
                    
					// As a rule, set auto height on our card container (exceptions set elsewhere)
					cmp.set("v.AutoCardHeight", true);


	                // Set diagnostics to all OK
                    cmp.set("v.Diags", helper.Internationalise(cmp, 'MessageGenericOK'));
                }

            } catch (e) {
                cmp.set("v.Diags", "TOPIC JSON Parsing Error: " + e + ': ' + response.getReturnValue());
                return;
            }
              //Logging geolocation for full topic 
				helper.logLUXInteractions(cmp, 4, 'Help Topic Viewed (LEX)', cmp.get('v.recordId'), cmp.get("v.HelpRecordId"));

        });                
        
        
        // Only queue 1x action per page visit
        cmp.set('v.isInitialised', true);
        helper.showSpinner(cmp);
        
        helper.logAdvancedDiags(cmp, 'IHDetail: getting tools...');            
		$A.enqueueAction(act);
                    
	},
	

	// If current record is a topic, checks whether a custom layout has
	// been specified via a template and, if so, initialises our designer
	// to display it if required
	refreshLayoutDesign : function (cmp, event, helper) {
	
		console.log('IHDetail - refreshLayoutDesign - entry');

		var LD = cmp.get("v.LayoutInfoDelimiters");
		var obj = cmp.get("v.CurrentRecord");
		var FullTemplates = cmp.get("v.TemplatesF");
	

		// Topic-specific layout is only allowed where component settings allow this:
		if (cmp.get("v.LayoutInfoPrecedence") == 'Component Definition') {
		
			// If the component's definition is preferred, this should have been set / used already,
			// so we can bail here
			console.log('IHDetail - refreshLayoutDesign - component level definition in play: returning...');
			return;
		}

	
		// This can only be undertaken where the delimiters in use in layout design instructions
		// have been specified correctly
		try {
			if (LD != '' && LD + '' != 'undefined') {
				if (LD.length == 4) {		
					LD = LD.substring(3,4);
	
					console.log('IHDetail - refreshLayoutDesign - delimiters in order - examining template...');

					if (FullTemplates.length == 0) {					

						if (obj.iahelp__Template__r.iahelp__PageURL__c.indexOf(LD) != -1) {
		
							console.log('IHDetail - refreshLayoutDesign - specified template requires custom layout - setting layout info...');
		
							cmp.set("v.LayoutInfo", obj.iahelp__Template__r.iahelp__PageURL__c);
							
							// With layout instructions amended as required, re-initialise our layout designer
							var DD = cmp.find("theDesigner");
							DD.reInitialise();
							
							// This action may have resulted in changes to the clickables that should be available: e.g., if page layout
							// did NOT specify the designer layout parameter, we will have moved from being 'standard' to 'custom' layout
							// setting, which should make design mode available.
							// So: refresh our clickable records at this point 			
							helper.refreshClickables(cmp, event, helper, cmp.get("v.HelpRecordId"), cmp.get("v.ToolContext"), cmp.get('v.ActionCode'));

						} else {
							cmp.set("v.LayoutInfo", '');				
						}
		

					} else {
						// Loop through full topic templates to get details of the one currently selected:
						// NB: do not look in topic itself for this for, whilst it has details of the last full template saved,
						// this may not be the same as that recently selected via an edit...
	
						FullTemplates.forEach(function (T){
							if (T.Id == obj.iahelp__Template__c) {
	
								if (T.iahelp__PageURL__c.indexOf(LD) != -1) {
				
									console.log('IHDetail - refreshLayoutDesign - specified template requires custom layout - setting layout info...');
				
									cmp.set("v.LayoutInfo", T.iahelp__PageURL__c);
									
									// With layout instructions amended as required, re-initialise our layout designer
									var DD = cmp.find("theDesigner");
									DD.reInitialise();
									
									// This action may have resulted in changes to the clickables that should be available: e.g., if page layout
									// did NOT specify the designer layout parameter, we will have moved from being 'standard' to 'custom' layout
									// setting, which should make design mode available.
									// So: refresh our clickable records at this point 			
									helper.refreshClickables(cmp, event, helper, cmp.get("v.HelpRecordId"), cmp.get("v.ToolContext"), cmp.get('v.ActionCode'));
						
								} else {
									// If you found a match, but it's not a layout design template, revert to 
									// a blank template definition
// ToDo: should revert to whatever design parameter was on page load
									cmp.set("v.LayoutInfo", '');
									
								}
							}
						});

					}

				}
			}
	
		} catch (e) {
			console.log('IHDetail - refreshLayoutDesign - error: ' + e);
		}	
	
	},
	
	
	// Re-obtain / refresh clickable tools, for cases where navigation may call for this
	refreshClickables : function (cmp, event, helper, theRecord, ToolContext, ActionCode) {

		var userPermLevel = 0;
			
        if (cmp.get("v.isUser") == true) userPermLevel += 1; 
        if (cmp.get("v.isAnalyst") == true) userPermLevel += 2; 
        if (cmp.get("v.isAuthor") == true) userPermLevel += 4; 
        if (cmp.get("v.isAdministrator") == true) userPermLevel += 8; 

        var act = cmp.get("c.getClickablesJSON");
        act.setParams({ 
            "ToolContext" : ToolContext, 
            "ActionCode" : ActionCode,
            "IHContext" : theRecord,
            "userPermLevel" : userPermLevel,
        });                       


        // Create a callback that is executed after the server-side action returns
        act.setCallback(helper, function (response, cmp){
            
            try {
				// Need to process globals to get internationalisations - however this will trash global settings:
				// So: obtain these prior and re-set after call
				var GS = cmp.get("v.GlobalSettings");
				helper.processTools(response, cmp, false);
				cmp.set("v.GlobalSettings", GS);
            
            } catch (e) {
            }

        });                
		$A.enqueueAction(act);
	
	},
	
	
	// Spins up any sub component requested as part of our LUX template
	initialiseTemplateComponents : function (cmp, event, helper) {
	
		var cmpDef = '';
		var obj = cmp.get("v.CurrentRecord");
		var CG = cmp.find("CGIHDetail");
		
		try {
			if (obj + '' != 'undefined') {			
				if (obj.iahelp__LightningTemplate__r + '' != 'undefined') {

					// Take the component definition in the template
					cmpDef = obj.iahelp__LightningTemplate__r.iahelp__PageURL__c;
										
					// 'De-tokenize'
					cmpDef = helper.deTokenize(cmp, cmpDef);					
					
					// Hard wire a component ID, unless one is already present
					if (cmpDef.indexOf('ComponentId¬') == -1) {
						cmpDef += '|ComponentId¬' + cmp.get("v.ComponentId") + '_SpecialComp';
					}
					
					// Ditto Help record ID
					if (cmpDef.indexOf('HelpRecordId¬') == -1) {
						cmpDef += '|HelpRecordId¬' + obj.Id;
					}

				}			
			}

			// Sub components should bear same colour scheme as parent
			CG.set("v.UXTheme", cmp.get("v.UXTheme"));
				
			CG.set("v.ComponentDef", cmpDef);	
			CG.reInitialise();
				
		} catch (e) {
			console.log('IHDetail - error creating sub components: ' + e);
		}
	
	},
	

	// On change of record, check media sizes (esp. video) and set to aspect ratio amounts where rendered size dictates
	setMediaSizes : function (cmp, event) {
	
		// Use this opportunity to adjust media sizes if required: applies to video only.
		// If specified video width is too wide for the available screen, IFRAME will actually be
		// at 100% available width, despite being styled at a larger pixel size. 
		// Therefore, check rendered IFRAME size and, if less than expected, set IFRAME height
		// by aspect ratio.
		// Alas, we need a timer as it's the only way to reliably know when we have a rendered
		// iframe with a 'real' rendered width...
	
		cmp.set("v.MediaCheckTimer", window.setInterval($A.getCallback(function() {
			
			try {
				// Only bother if we have a current record and we've viewing a help topic
				if (cmp.get("v.IsHelpTopic") == true && cmp.get("v.CurrentRecord") + '' != 'undefined') {
				
					// Only bother if we have video URL, H and W
					var vU = cmp.get("v.CurrentRecord.iahelp__VideoURL__c");
					var vW = cmp.get("v.CurrentRecord.iahelp__VideoWidth__c");
					var vH = cmp.get("v.CurrentRecord.iahelp__VideoHeight__c");
					
					
					if (vU != '' && vU + '' != 'undefined' && vW + '' != '0' && vW + '' != 'undefined' && vH + '' != '0' && vH + '' != 'undefined') {
					
						//console.log('IHDetail - sizing video for "' + cmp.get("v.ComponentId") + '" - W/H/U: ' + cmp.get("v.CurrentRecord.iahelp__VideoWidth__c") + '/' + cmp.get("v.CurrentRecord.iahelp__VideoHeight__c") + '/' + cmp.get("v.CurrentRecord.iahelp__VideoURL__c"));
					
						// Get IFRAME rendered W
						var frm = cmp.find("TopicVideoIframe");
						var renderedWidth = frm.getElement().offsetWidth;
						var ratio = parseInt(vW) / parseInt(vH);
						var ratioHeight = renderedWidth * (1 / ratio); 
						
						// If rendered width is less than topic's specified video width, set video height by ratio
						if (renderedWidth < vW) {
							
							// Ignore rendered widths of zero - means we have yet to correctly render
							if (renderedWidth == 0) {return;}
							
							console.log('IHDetail - rendered width of ' + renderedWidth + ' less than specified width of ' + vW + ': height resized to: ' + ratioHeight);					
							cmp.set("v.VideoIframeHeight", ratioHeight);
													
						} else {
							console.log('IHDetail - rendered width OK: specified height of ' + vH + ' retained');
							cmp.set("v.VideoIframeHeight", vH);
						}
						
					} else {
						//console.log('IHDetail - video not required for "' + cmp.get("v.ComponentId") + '" - W/H/U: ' + cmp.get("v.CurrentRecord.iahelp__VideoWidth__c") + '/' + cmp.get("v.CurrentRecord.iahelp__VideoHeight__c") + '/' + cmp.get("v.CurrentRecord.iahelp__VideoURL__c"));
					
						// Iframe should not be shown: set to 0 height here as belt & braces...
						cmp.set("v.VideoIframeHeight", 0);
					}
					
					// If we get here, action has been taken: clear timer
					if (cmp.get("v.MediaCheckTimer") != 0) {window.clearInterval(cmp.get("v.MediaCheckTimer"));}
					
				} else {
					// If we get here, action is not required: clear timer
					if (cmp.get("v.MediaCheckTimer") != 0) {window.clearInterval(cmp.get("v.MediaCheckTimer"));}
	
				}
				
			} catch (e) {
				// If we get here, clear timer!
				if (cmp.get("v.MediaCheckTimer") != 0) {window.clearInterval(cmp.get("v.MediaCheckTimer"));}
			}
		
		}), 500));
	
	},
	
    
    // Prepare editing controls (drop downs) as we don't bring these down as part of "tools" calls
    initialiseEditingControls : function(cmp, event) {

        this.logAdvancedDiags(cmp, 'IHDetail: Editing Controls entry...');

        var act = cmp.get("c.getTopicEditingControls");
        
        act.setCallback(this, function (response, cmp){
            
            var state = response.getState();

            if (state === "SUCCESS") {
            	this.logAdvancedDiags(cmp, 'IHDetail: editing tools callback...');

                var tC = [];        // Callout templates
                var tF = [];        // Full topic templates
                var tL = [];        // Lightning viewer templates
                var GLIDs = [];     // Guide Layouts
                var GElems = [];    // Guide Elements
                var Styles = [];    // Custom styles
                var VS = [];        // Vote Sets
                var Vis = [];       // Visibility settings
                var i;
                var obj;
                var hasAttributes = false;
    
    			// Return value is JSON - parse this into objects for aura iteration...
                try {
    				obj = JSON.parse(response.getReturnValue());
                } catch (e) {
                    cmp.set("v.Diags", "IHDetailController - processTools - Error parsing the following JSON return value: " + response.getReturnValue());
                    return;
                }

                for (i = 0; i<obj.length; i++) {
                    
                    try {
                        var s = obj[i].attributes.type;
                        hasAttributes = true;
                    } catch (e) {
                        hasAttributes = false;
                    }

                    if (hasAttributes === true) {

                        if (obj[i].attributes.type === 'iahelp__HelpTopicTemplate__c') {
                            if (obj[i].iahelp__TemplateType__c == 'Callout') {
                                tC.push(obj[i]);
                            }
            
                            if (obj[i].iahelp__TemplateType__c == 'Full Topic') {
                                tF.push(obj[i]);
                            }

                            if (obj[i].iahelp__TemplateType__c == 'Lightning Viewer') {
                                tL.push(obj[i]);
                            }
                        }
                        
                        if (obj[i].attributes.type === 'iahelp__HelpVoteSet__c') {
                            VS.push(obj[i]);
                        }
                        
                        if (obj[i].attributes.type === 'iahelp__HelpedPageLayout__c') {
                            GLIDs.push(obj[i]);
                        }

                        if (obj[i].attributes.type === 'iahelp__HelpedElement__c') {
                            GElems.push(obj[i]);
                        }

                    } else {
                        // Non-sObject types can be differentiated by a type tag that we add server side:
                        // (We're using our own "NameValuePair" class here)
                        if (obj[i].ValueSet == 'Visibilities') {
                            Vis.push(obj[i]);
                        } else {
                            Styles.push(obj[i]);
                        }
                    }
                    
                }

                this.logAdvancedDiags(cmp, 'IHDetail: setting edit tool member data...');
                
                cmp.set("v.TemplatesC", tC);
                cmp.set("v.TemplatesF", tF);
                cmp.set("v.TemplatesL", tL);
                cmp.set("v.CustomStyles", Styles);
                cmp.set("v.Visibilities", Vis);
                cmp.set("v.VoteSets", VS);
                cmp.set("v.GuidedLayouts", GLIDs);
                cmp.set("v.GuidedElements", GElems);
                
                // Reflect selected vote set for question text etc.
                this.lookupRelatedObjects(cmp, cmp.get("v.SelectedVoteSet"));

                this.logAdvancedDiags(cmp, 'IHDetail: Editing Controls complete...');
                
            } else {
                // Report failure
                //alert("Error preparing Help Topic Card: " + response.getReturnValue());
            }       
      });
        
        // Send action
        $A.enqueueAction(act);
    },
    
    
    // Note certain pick list values and use these to obtain additional info about the related records:
    // E.g., obtain details of the selected Vote Set
    lookupRelatedObjects : function (cmp, val) {
        
        var vals;
        var i;

        vals = cmp.get("v.VoteSets");
        
        for (i=0; i<vals.length; i++) {
            if (vals[i].Id === val) {
                cmp.set("v.SelectedVoteSet", vals[i]);
                break;
            }
        }
        
    },
    
    
    // Get Guide (HPL) Elements for selected Guided Layout
    lookupRelatedGElements : function (cmp, val) {

        // On change of Layout, refresh elements
        var act = cmp.get("c.getElementsForLayout");
        
        act.setParams({ 
			"LayoutId" : val
        });                       
    
        // Add callback to show returned results
        act.setCallback(this, function (response, cmp){

            if (response.getState() === "SUCCESS") {
    			// Return value is JSON - parse this into objects for aura iteration...
                try {
    				var obj = JSON.parse(response.getReturnValue());
    				cmp.set("v.GuidedElements", obj);
                } catch (e) {
                    cmp.set("v.Diags", "IHCardHelper - processTools - Error parsing the following JSON return value: (" + e + ")" + response.getReturnValue());
                }
            }
        }); 

        // Send action
        $A.enqueueAction(act);
        
    },
    

	// Attempt to locate a requested current record (by help topic ID) in this component's cache:
	// C.f. pass throughs / component tools processed where record cache is set.
	currentRecordIsCached : function (cmp, event, helper, theRecord) {
	
		var HEs = cmp.get("v.HelpedElements");
		var HTs = cmp.get("v.HelpTopics");
		var i;
		var recordLocated = false;
		var HVS;
		var act;
		
		
		// Cache may consist of helped element records (pointing to topics) or
		// actual help topics, depending on the component set as this one's cache source
		// and its method of retrieving context records: look through each collection in turn...
		
		if (HEs + '' != 'undefined') {
			for (i=0; i < HEs.length; i++) {
				try{
			    	if (HEs[i].iahelp__HelpTopic__r.Id == theRecord) {

						cmp.set("v.IsHelpTopic", true);
						cmp.set("v.IsNonTopic", false);
			    	
			    		cmp.set("v.Title", HEs[i].iahelp__HelpTopic__r.Name);
			    		cmp.set("v.HelpRecordId", HEs[i].iahelp__HelpTopic__r.Id);
		    			cmp.set("v.SelectedVoteSet", HEs[i].iahelp__HelpTopic__r.iahelp__HelpVoteSet__c);
			    		cmp.set("v.CurrentRecord", HEs[i].iahelp__HelpTopic__r);
			    		recordLocated = true;
			    		break;
			    	}
				} catch (e) {}
			}
		} 
		
		if (HTs + '' != 'undefined') {
			for (i=0; i < HTs.length; i++) {
				try{
			    	if (HTs[i].Id == theRecord) {

						cmp.set("v.IsHelpTopic", true);
						cmp.set("v.IsNonTopic", false);

			    		cmp.set("v.Title", HTs[i].Name);
			    		cmp.set("v.HelpRecordId", HTs[i].Id);
		    			cmp.set("v.SelectedVoteSet", HTs[i].iahelp__HelpVoteSet__c);
			    		cmp.set("v.CurrentRecord", HTs[i]);
			    		recordLocated = true;
			    		break;
			    	}
				} catch (e) {}
			}
		}


// 1.54.2+ If record is an inactive topic, do not allow this to be shown via cache 
// unless we are at least a help author

if (recordLocated == true) {
	var rec = cmp.get("v.CurrentRecord");
	if (rec.iahelp__Active__c == false && cmp.get("v.isAuthor") == false) {
		
		cmp.set("v.IsHelpTopic", false)
		//recordLocated = false;
	}
}
		
	
		// If we found the requested record in cache, set some key values based on it
		if (recordLocated == true) {
		
			// As topic in view mode uses keyword parsed description, set this to the description of the
			// record to which we are navigating (as located in cache): this ensures we see a description at 
			// least, pending keyword parsing when the user mouses over the details component...
			cmp.set("v.KeywordParsedDescription", cmp.get("v.CurrentRecord").iahelp__Description__c);
			
			// Get vote options plus user's last vote, if any, for the selected vote set
			this.lookupRelatedObjects(cmp, cmp.get("v.SelectedVoteSet"));
	
			// Reset options for the re-located vote set: these will not be the same and
			// need to be obtained via a server call
			cmp.set("v.VoteOptions", null);
			
		}
		
		// Advise caller or whether or not cached record was located
		return recordLocated;
	},


   // Make server call to obtain additional info, such as keyword parsed description and votes, for current topic (e.g., when cache is in play) 
	getAdditionalInfo : function (cmp, event,helper) {	 
        
		// Set a latch to ensure no further calls to this method until required
        cmp.set("v.MouseOverDone", true); 
        
        console.log('getAdditionalInfo - entry: seeking record: ' + cmp.get('v.HelpRecordId'));
		var act = cmp.get("c.getAdditionalInfoForTopic");
	    act.setParams({ 
	        "HTID" : cmp.get('v.HelpRecordId')
	    });   
            
        // Temporarily set parsed description to topic's ordinary description
        // so we see info whilst we wait
        try {
            cmp.set("v.KeywordParsedDescription", cmp.get("v.CurrentRecord").iahelp__Description__c);            
        } catch (e) {}
        

		// Create a callback that is executed after the server-side action returns
	    act.setCallback(helper, function (response, cmp){

			console.log('getAdditionalInfo - processing getAdditionalInfoForTopic return value...');
			
			var obj;
			var hasAttributes = false;
			var VOs = [];
			var customFs = [];
			var passThroughs = []; 
              
            
            try {
            	obj = JSON.parse(response.getReturnValue());
            	console.log(obj);
            	
				// Loop through objects returned
				for (var i = 0; i<obj.length; i++) {
	                          
					try {
	                    var s = obj[i].attributes.type;
	                    hasAttributes = true;
	                } catch (e) {
	                    hasAttributes = false;
	                }
	    
	                if (hasAttributes === true) {
	                    if (obj[i].attributes.type === 'iahelp__HelpVoteOption__c') {
	                      // These represent vote options applicable to an individual Help Topic:
	                      VOs.push(obj[i]);
	                    }
	                    
	                } else {
	                    if (obj[i].CustomField + '' != 'undefined') {
	                      // Help Topic custom field information
	                      customFs.push(obj[i]);
	    
	                    } else if (obj[i].ValueSet == 'VoteInfo') {
	                          // This is the user's vote
	                            cmp.set("v.theVote", obj[i].Value);
	        
	                    } else if (obj[i].ValueSet == 'ParsedContent') {
	                        // Derivatives of record values (e.g., key-word enabled Help Topic descriptions).
	                        // We have no direct need of these, but push them into our "pass through" data collection, 
	                        // for inheritors who may...
	                        passThroughs.push(obj[i]);
	                    }
	                }
	              
				}		// end loop around returned objects
	              
				console.log('getAdditionalInfo - return value processed: setting member data... ');
				
				cmp.set("v.PassThroughData", passThroughs);
				cmp.set("v.KeywordParsedDescription", cmp.get("v.PassThroughData")[0].Value);
				cmp.set("v.CustomFields", customFs);                    
				cmp.set("v.VoteOptions", VOs);

            	
            } catch (e) {
            	// Fail silently - but do log the error
            	console.log('Error processing additional topic info: ' + e);
            }
              
	    });
            
    	console.log('getAdditionalInfo - calling getAdditionalInfoForTopic...');
	    $A.enqueueAction(act);
	},

    // Return a value indicating whether D&D ops are allowed at all - based on current record status
	DDAllowed : function (cmp, event) {	
		return cmp.get("v.isDirty") == false;
	},
	
	
	// Return a boolean indicating whether drop is allowed onto target based on dragged data
    dropAllowed : function (cmp, event) { 
    
    	var retVal = false;

    	try {
	    	var dat = event.dataTransfer.getData("text");
	    	var D1 = cmp.get("v.Delimiter");    
	    	var parms = [];
	    	
	    	console.log('dropAllowed: ' + dat);

	        var keyTypes = cmp.get("v.GlobalSettings.iahelp__SFObjectIds__c");
	        keyTypes = keyTypes.split('^');
            
	    	parms = dat.split(D1);

	    	// For now, we can only deal with ops representing Help Topic records
	    	if (parms[1].substring(0,3) == keyTypes[0]) {
	    		console.log('dropAllowed: returning true');	    	
	    		retVal = true;
	    	}

    	} catch (e) {
    		//console.log('IHTags dropAllowed error: ' + e);
    	}
    	
        return retVal;
    },	
    
    
})