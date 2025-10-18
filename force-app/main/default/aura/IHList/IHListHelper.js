({

	// Get the largely invariant, cacheable information used on cards
	// then cue initialisation
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
                    this.initialiseList(cmp, event, helper);
                }
                
            });
            $A.enqueueAction(act);	
                
        } else {
            this.initialiseList(cmp, event, helper);
        }		

	},

    
    // Set up required listing data according to our member data / Card Configuration etc.
    initialiseList : function(cmp, event, helper) {
		
        // Only queue 1x action per page visit
        if (cmp.get('v.isInitialised') === true) {
            return;
        }

        var act;
        var cxt;
        var listConfig;
        var ToolsOnlyList;		// For the "ToolsOnly" config option - to hold any pre-obtained listing to be displayed        
        var SkipGlobals = cmp.get("v.SkipGlobals");
        var TCxt = cmp.get("v.ToolContext");
		var D1 = '^';	
        
        
        // Note the card's configuration
        listConfig = cmp.get('v.CardConfig');
        
        
        // Default to removing record selection marker on list scroll - unless we've been instructed to the contrary
        if (cmp.get("v.RetainSelectionOnScroll") != true) {
	        cmp.set("v.RetainSelectionOnScroll", false);
        }


        // NOTE: 
        // When list is used stand alone, CardConfig is set by Page Author via a design parameter.
        // When list is part of another component (e.g., QAM) owner must set CardConfig.
        // We can differentiate these settings (e.g., those with spaces generally mean design parameter)
        
        // ALSO NOTE: if tool context = QAM, ControllerLUXOps logs a list type interaction - using ACTION CODE (as card config not known to it)
        // QAM Init re-sets CARD CONFIG to this ACTION CODE - hence there being 2 similar listConfig switches below... 

        switch (listConfig) {
			
            case "All Help" :
            case "AllHelp" :
            	cmp.set('v.ActionCode', 'AllHelp');
            	
            	if (listConfig == 'All Help') {
	                cmp.set('v.ToolContext', 'CardRelatedHelp');
            	}

                cmp.set('v.Icon', 'fa-list');
                cxt = cmp.get('v.recordId');

				// Respond if we don't have a record ID: seek a context via page URL
				if (cxt + '' == 'null' || cxt + '' == 'undefined') {	
					cxt = helper.getPageContextIdentifier(cmp);
				}
                break;
                
			case "AppListing" :
				cmp.set('v.ActionCode', 'AppListing');
				cxt = cmp.get('v.IHContext');
				break;
			
			case "BlankList" :
				// Do nothing - just return an empty list for population elsewhere (e.g., client side)
				cmp.set('v.isInitialised', true);
				helper.hideSpinner(cmp);
				cmp.set('v.Diags', '- - -');
				return;               

            case "Bookmarks" :
            case "HelpBookmarks" :
            	
            	if (listConfig == 'Bookmarks') {
	                cmp.set('v.ToolContext', 'CardRelatedHelp');
            	}

                cmp.set('v.ActionCode', 'HelpBookmarks');
                cmp.set('v.Icon', 'fa-bookmark');
                cxt = cmp.get('v.recordId');
                break;

            case "Child Help" :
            case "ChildHelp" :
                cmp.set('v.ToolContext', 'CardChildHelp');
                cmp.set('v.ActionCode', 'ChildHelp');
                cmp.set('v.Icon', 'fa-list');
                
                // Prioritise default help context if supplied
                if (cmp.get("v.HelpRecordId")!= '' && cmp.get("v.HelpRecordId") != null) {
                	cxt = cmp.get("v.HelpRecordId");
                } else {
	                cxt = cmp.get('v.recordId');
                }
                break;

				// Added in version 1.56
            case "Only Related Help":
            case "OnlyRelatedHelp":
                cmp.set('v.ToolContext', 'CardOnlyRelatedHelp');
                cmp.set('v.ActionCode', 'OnlyRelatedHelp');
                cmp.set('v.Icon', 'fa-list'); 
                
                // Prioritize default help context if supplied
                if (cmp.get("v.HelpRecordId") != '' && cmp.get("v.HelpRecordId") != null) {
                    cxt = cmp.get("v.HelpRecordId");
                } else {
                    cxt = cmp.get('v.recordId');
                }
                break;
                

case 'CommentsAll':
case 'CommentsTopics':
case 'CommentsRLs':
case 'CommentsHPLs':
	cmp.set('v.ActionCode', listConfig);
	break;


			case "Disambiguation" :
			     cmp.set('v.ActionCode', 'Disambiguation');
			     cmp.set('v.ToolContext', 'Disambiguation');
			     cxt = cmp.get('v.sObjectName');
			                
			    break;                

			case "Fixed Help" :
			case "FixedHelp" :
			    cmp.set('v.ToolContext', 'FixedHelp');
			    cmp.set('v.ActionCode', 'FixedHelp');
			    cmp.set('v.Icon', 'fa-list');
                cxt = cmp.get('v.sObjectName');
                break;
                
            case "Search Help" :
            case "SearchHelp" :
                cmp.set('v.ToolContext', 'SearchHelp');
                cmp.set('v.ActionCode', 'SearchHelp');
                cmp.set('v.Icon', 'fa-list');
                cxt = cmp.get('v.sObjectName');
                break;

			case "GetTaggedItems" :
			    cmp.set('v.Icon', 'fa-tags');
			    cmp.set('v.ActionCode', 'GetTaggedItems'); 
			
				if (cmp.get('v.ListingTagFilters') != '') {
					cxt = cmp.get('v.ListingTagFilters');    
				} else {
					cxt = cmp.get('v.sObjectName');
				}
				
			    break;				

			case "Guides" :
			    cmp.set('v.ActionCode', 'Guides');
			    cmp.set('v.Icon', 'fa-list');
			    cxt = cmp.get('v.recordId');
			    break;

            case "HelpComments" :
            	// SEE ALSO Comments* codes...
            	// This is the original action which was for the QAM
                cmp.set('v.ActionCode', 'HelpComments');
                cmp.set('v.Icon', 'fa-comment');
                cxt = cmp.get('v.recordId');
                break;
                			
            case "Help Notes" :
            case "HelpNotes" :
                cmp.set('v.ToolContext', 'CardStickies');
                cmp.set('v.ActionCode', 'Stickies');
                cmp.set('v.Icon', 'fa-sticky-note-o');
                cxt = cmp.get('v.IHContext');
                break;

            case "HelpEnableMode" :
                cmp.set('v.Icon', 'fa-puzzle-piece');
                break;
                            
			case "Keywords" :
			    cmp.set('v.ActionCode', 'Keywords');
			    cmp.set('v.ToolContext', 'CardRelatedHelp');    
			    cmp.set('v.Icon', 'fa-key');
			    cxt = cmp.get('v.recordId');
			    break;

            case "PopularHelp" :
                cmp.set('v.ActionCode', 'PopularHelp');
                cmp.set('v.Icon', 'fa-list');
                cxt = cmp.get('v.recordId');
                break;

            case "QuickLinks" :
                cmp.set('v.ActionCode', 'QuickLinks');
                cmp.set('v.Icon', 'fa-list-ol');
                cxt = cmp.get('v.recordId');
                break;
			            
            case "Reading Lists" :
            case "ReadingLists" :
            	if (listConfig == 'Reading Lists') {
	            	cmp.set('v.ToolContext', 'CardReadingLists');
            	}
            	
                cmp.set('v.ActionCode', 'ReadingLists');
                cmp.set('v.Icon', 'fa-list-ol');
                cxt = cmp.get('v.recordId');
                break;
                
            case "Related Help" :
            case "RelatedHelp" :
                cmp.set('v.ToolContext', 'CardRelatedHelp');
                cmp.set('v.ActionCode', 'AllRelatedHelp');
                cmp.set('v.Icon', 'fa-list');
                
                // Prioritise default help context if supplied
                if (cmp.get("v.HelpRecordId")!= '' && cmp.get("v.HelpRecordId") != null) {
                	cxt = cmp.get("v.HelpRecordId");
                } else {
	                cxt = cmp.get('v.recordId');
                }
                break;

            case "Resources" :
                cmp.set('v.ToolContext', 'CardResources');
                cmp.set('v.ActionCode', 'AllResources');
                cmp.set('v.Icon', 'fa-map-signs');

                // Prioritise default help context if supplied
                if (cmp.get("v.HelpRecordId")!= '' && cmp.get("v.HelpRecordId") != null) {
                	cxt = cmp.get("v.HelpRecordId");
                } else {
	                cxt = cmp.get('v.recordId');
                }
                break;
          
			case "SearchResources" :
			case "Search Resources" :
				// Search for an existing resource
			    cmp.set('v.ActionCode', 'SearchResources');
			    cmp.set('v.ToolContext', 'LinkResources');     
			    cxt = cmp.get('v.IHContext');
			    break;
			
			case "SearchRelatedHelp" :
				// Search for an existing topic to link
			    cmp.set('v.ActionCode', 'SearchRelatedHelp');
			    cmp.set('v.ToolContext', 'LinkTopics');     
			    cxt = cmp.get('v.recordId');
			    break;
    
            case "Search" :
                cmp.set('v.ActionCode', 'Search');
                cxt = cmp.get('v.recordId');
                break;

            case "Stickies" :
                cmp.set('v.ActionCode', 'Stickies');
                cmp.set('v.Icon', 'fa-sticky-note-o');
                cxt = cmp.get('v.recordId');
                
                // This is one of the few special cases where we want to retain record selection marking as we scroll list
                cmp.set("v.RetainSelectionOnScroll", true);
                break;
                
			case "TabListing" :
				cmp.set('v.ActionCode', 'TabListing');
				cxt = cmp.get('v.IHContext');
				break;

			case "Tagged Items" :
			case "TaggedItems" :
			    cmp.set('v.ToolContext', 'CardRelatedTags');
			    cmp.set('v.Icon', 'fa-tags');
			    cmp.set('v.ActionCode', 'GetTaggedItems'); 
			
			       
				if (cmp.get('v.ListingTagFilters') != '') {
					cxt = cmp.get('v.HelpRecordId') + '' + D1 + cmp.get('v.ListingTagFilters');    
			
				} else {
					cxt = cmp.get('v.HelpRecordId');
				}
			    break;

			case "ToolsOnly" :
				// Seek no data (as blank list) but DO obtain configuration tool information for specified context
				cmp.set("v.ActionCode", "ToolsOnly");
				
				// Keep track of any supplied listing items
				ToolsOnlyList = cmp.get("v.ListingItems");
				
				break;
            
			case "Tree Content":
			case "TreeContent":
			    cmp.set('v.ToolContext', 'CardRelatedHelp');
			    cmp.set('v.Icon', 'fa-tree');
			    cmp.set('v.ActionCode', 'TreeNodes'); 
			    
			    if (cmp.get('v.ListingClickActionCode') == '') {
			    	cmp.set('v.ListingClickActionCode', 'RelatedHelp');
			    }
			    
			    cxt = cmp.get('v.HelpRecordId');
				
				break;

            case "Unfeatured Reading Lists" :
            case "UnfeaturedReadingLists" :
            	cmp.set('v.ToolContext', 'CardReadingLists');
                cmp.set('v.ActionCode', 'ReadingListsXF');
                cmp.set('v.Icon', 'fa-list-ol');
                cxt = cmp.get('v.recordId');
                break;

            default :
                // Default to taking no action - but note this fact in diags...?
                cmp.set("v.Diags", helper.Internationalise(cmp, "AdviceLabelUnknownListing"));
                
                //... except we can't really do that - or we'll get no onward nav tools or any translations!
                cmp.set('v.ToolContext', 'QAM');
                cxt = cmp.get('v.recordId');
                break;

        }



		// Set tool context if this has not been done elsewhere above or by list owner
		if (cmp.get('v.ToolContext') == '') {
		    cmp.set('v.ToolContext', 'QAM');
		}

        
        if (cmp.get('v.CardConfig') == 'HelpEnableMode') {
            act = cmp.get("c.getHelpableElements");
            act.setParams({ 
                "IHContext" : cmp.get('v.IHContext'),
                "ObjectName" : cmp.get('v.sObjectName')
            });                       

        } else {
        
			var parms;
			if (cmp.get('v.ActionCode') == 'GetTaggedItems') {
				parms = cxt;

			} else if (cmp.get('v.ActionCode') == 'TreeNodes') {
		
				// For trees, we need to respect any 'max levels' limit that has been specified
				parms = cmp.get("v.TreeMaxDepth") + '^ServiceIHTrees.TNSHelpTopics';

			} else if (cmp.get('v.ActionCode') == 'SearchResources' || cmp.get('v.ActionCode') == 'SearchRelatedHelp') {
				// Parameter to use is the search term: retrieve this from place
				// it was stored on last search
				parms = cmp.get("v.theVote");
					
			} else {
				// Default to using parameters to set labelling approach (name only, name and type etc) specified for component
				parms = cmp.get("v.RowLabellingOption");
			}  
				                  
            
			// Allow page-author specified tool context, noted on the way in to this function,
			// to override any defaults used above
			if (TCxt != '' && TCxt != '[DEFAULT]' && TCxt != 'QAM') {
				cmp.set("v.ToolContext", TCxt);
			}         
   
            act = cmp.get("c.getTools");
            act.setParams({ 
                "ToolContext" : cmp.get('v.ToolContext'), 
                "ActionCode" : cmp.get('v.ActionCode'),
                "IHContext" : cxt,
                "ClientComponentId" : cmp.get("v.ComponentId"),
                "Params" : parms,
                "SkipGlobals" : SkipGlobals,
            });                       
            
            cmp.set("v.IHContext", cxt);
        }
        
        
        // Create a callback that is executed after the server-side action returns
        act.setCallback(helper, function (response, cmp){
      
            helper.processTools(response, cmp, SkipGlobals);

            // Complete post-processing for some special cases
			if (listConfig == 'ToolsOnly') {
				cmp.set("v.ListingItems", ToolsOnlyList);
			}   	
            
			helper.postProcess(cmp, helper);			

        });                
        

        // Send action and note the fact that this has been done / we're initialised        
        cmp.set('v.isInitialised', true);
        helper.showSpinner(cmp);
		$A.enqueueAction(act);
                    
	},	
    

	// Engage in additional setup tasks that occur after list creation / tool processing
	postProcess : function (cmp, helper) {
	
		helper.processSpecialListTypes(cmp, helper);
		helper.establishAndToggleListingDetails(cmp, helper);			
		helper.processExtraColumns(cmp, helper);	

		// Always prevent powered by for tile lists as it does not suit the look and feel
		if (cmp.get("v.ListingStyle") == 'Tile') {
			cmp.set("v.SuppressPoweredBy", true);
		}
	},

    
    // Work out which list details style should be in play and toggle to it
    establishAndToggleListingDetails : function (cmp, helper) {

        // Once tools are prepared, toggle listing to the desired style:
        // Check for personalisation setting here (overrides page designer's default):
        
        var styl = cmp.get("v.ListingRowStyle");
        var PS = cmp.get("v.PersonalisationSettings");
        var i;

        // Only really want to do this in the QAM...
        if (cmp.get("v.ComponentId") == 'theQAM') {
	        for (i=0; i<PS.length; i++) {
	            if (PS[i].iahelp__HelpInteractionType__c === 'List Detail Level') {
	                styl = PS[i].iahelp__Description__c;
	            }
	        }
        }

        this.toggleListingDetails(cmp, styl, helper);
        
    },
    
    
    // Show / hide listing full details
    toggleListingDetails : function (cmp, styl, helper)   {
        
        var i;
		var PS = cmp.get("v.PersonalisationSettings");
       
        // Ensure we record in component the style we were told to toggle
        // and also record an interaction reflecting this
        if (styl != cmp.get("v.ListingRowStyle")) {
	        cmp.set("v.ListingRowStyle", styl);
	        helper.logListState(cmp, styl);

			// Also, record this back to our "current" personalisation settings
			for (i=0; i<PS.length; i++) {
			    if (PS[i].iahelp__HelpInteractionType__c === 'List Detail Level') {
			        PS[i].iahelp__Description__c = styl;
			    }
			}
        }
        
        // Also, ensure we toggle the list style button itself 
        // (avoid "Hide Details" tool showing when ddetails are already hidden!)
        if (styl == 'Expanded') {
	        helper.toggleConfigTool(cmp, 'Ellipsis', 'ShowListingDetails');
        } else {
	        helper.toggleConfigTool(cmp, 'Ellipsis', 'HideListingDetails');
        }
        
    },
    
    
	// Process certain special listing types, whose data as returned from list-getting server call 
	// is not, at the point it is received, ready for use in the UI: eg: lists of apps and tabs obtained
	// as metadata JSON, rather than listing items (which are all a list can display)
	processSpecialListTypes : function (cmp, helper) {
	
		// Parse name/value pairs holding tabs data
		if (cmp.get("v.CardConfig") == 'TabListing') {
		
			// These will have fallen into listing items by default
			try {
				var NVPs = cmp.get("v.ListingItems");
				var AppTabs = NVPs[0].Value;	
				var AllTabs = NVPs[1].Value;	
				var LIs = [];	
				var LI;	
						
				AppTabs = JSON.parse(AppTabs);
				AllTabs = JSON.parse(AllTabs);
				
				// Get just the API names of the tabs from the App tab listing object
				AppTabs.records[0].Metadata.tabs.forEach(function (TApp){
					
					LI = {Id: TApp, Label: TApp, Icon: 'fa-table'};
					
					AllTabs.forEach(function (TAll){
						if (TAll.name == TApp) {
							LI.Label = TAll.label;
							
							// Retain table icon for tabs that represent objects, use something else for non-object tabs
							if (TAll.sobjectName != TAll.name) {
								LI.Icon = 'fa-cog';
							}
						}
					});
					
					LIs.push(LI);
				});
	
				cmp.set("v.Diags", helper.Internationalise(cmp, 'MessageGenericOK'));		
	
					
			} catch (e) {
				LIs = [];			
				cmp.set("v.Diags", helper.Internationalise(cmp, 'MessageGenericError') + ' (InitialiseList tabs post processor): ' + e);		
			}
	
			cmp.set("v.ListingItems", LIs);
		
		}   
	
	},
    
    
	// Process any data in listing items pointing to the need for more than 1 column (i.e., the 'Cols' listing item member)
	processExtraColumns : function (cmp, helper) {
	
		var LIs = cmp.get("v.ListingItems");
		var D1 = cmp.get("v.Delimiter");
		var D2 = String.fromCharCode(5);
		var i;
		var j;
		
		if (LIs.length > 0){
			for (i=0; i<LIs.length; i++) {
				if (LIs[i].Cols == '' || LIs[i].Cols + '' == 'undefined' || LIs[i].Cols + '' == 'null') {
					break;
				}
				
				// If columns specified, split the columns out
				LIs[i].Cols = LIs[i].Cols.split(D1);
				
				// For each column, split into label and tip text
				for (j=0; j<LIs[i].Cols.length; j++) {
					LIs[i].Cols[j] = LIs[i].Cols[j].split(D2);
				}
			}
		}			
		
		cmp.set("v.ListingItems", LIs);
		
	},
    
    
	// For list just-in-time rendering, set the upper number of rows of data to render for the time being
	setCurrentRows : function(cmp, event, helper){
		var i = parseInt(cmp.get("v.CurrentRows"));
		
		i += 50;
		if (i > cmp.get("v.ListingItems").length) {i = cmp.get("v.ListingItems").length;}
		cmp.set("v.CurrentRows", i);
	},

    
})