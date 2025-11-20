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
                    this.initialiseTree(cmp, event, helper);
                }
                
            });
            $A.enqueueAction(act);	
                
        } else {
            this.initialiseTree(cmp, event, helper);
        }		

	},
	

	// Request the nodes for the context with which we've been provided
	initialiseTree: function(cmp, event, helper) {
	
		// In print view mode, ignore certain potential design mode parameters and 
		// set the tree up to display minimal furniture only
				
		if (cmp.get("v.PrintView") == true) {
			cmp.set("v.SuppressHeader", true);
			cmp.set("v.SuppressFooter", true);
			cmp.set("v.SuppressListingTools", true);			
			cmp.set("v.DDAllowed", false);
			cmp.set("v.Height", -1);
			cmp.set("v.NodeProvider", 'ServiceIHTrees.TNSPrintableHelpTopics');
		}
        
        //The AUthorconfigs override the v.HelpRecordId with rootnode.
        // hence, re-referencing with newly created child node.
        var helprecordId = cmp.get("v.HelpRecordId");
        console.log('helprecordId===>',helprecordId);
        cmp.set("v.newHelprecordID",helprecordId);
        
		helper.showSpinner(cmp);
        
        var act = cmp.get("c.getTools");
		var SkipGlobals = cmp.get("v.SkipGlobals");
        
        
        // We need to advise tree building code of the max desired tree recursion depth AND the desired node provider
        // (TreeNodeSupplier implementation) if desired
        var parms = '' + cmp.get("v.MaxDepth") + '^' + cmp.get("v.NodeProvider"); 


        // Allow for override of tool context
        var cxt = cmp.get("v.ToolContext");
        if (cxt == '' || cxt == null || cxt == 'QAM' || cxt == '[DEFAULT]') {
	        cmp.set("v.ToolContext", "CardTree");
        }
        
        
		// Take note of the 'home' root specified as the component's root
		// on first initialisation - but not on any subsequent changes to the root node
		// (which will also bring us here)
		if (cmp.get("v.HomeRoot") == '' && cmp.get("v.RootNode") != '' && cmp.get("v.RootNode") != '[None]') {
			cmp.set("v.HomeRoot", cmp.get("v.RootNode"));
		}
        
        
        cmp.set("v.ActionCode", "TreeNodes");
        
		/*
		NEED TO SET CONTEXT TO HOME ROOT IN CASES RELATING TO COMPLEX PROVIDERS
		SUCH AS ServiceIHTrees.TNSHelpedPageLayouts / RECONFIGURE MODE:
		INSTEAD OF A HELPED PAGE LAYOUT ID AS CONTEXT (ROOT NODE - THE HPL WHOSE ELEMENTS
		ARE BEING STUDIED) WE WANT OBJECT CODE ^ ELEMENT IDENT - WHICH WILL FILTER TO A 
		PARTICULAR ELEMENT
		*/

		//        cmp.set("v.IHContext", cmp.get("v.RootNode"));

		var complexRoot = false;
		var RLMarker = 'rL_';
		var D1 = '^';

		if (cmp.get("v.HomeRoot") != '' && cmp.get("v.HomeRoot") + '' != 'undefined') {
			if (cmp.get("v.HomeRoot").indexOf(D1) != -1) {
				complexRoot = true;
			}
		}

		if (complexRoot == true) {
			cmp.set("v.IHContext", cmp.get("v.HomeRoot"));
		} else {
			cmp.set("v.IHContext", cmp.get("v.RootNode"));
		}        
		
		var root = cmp.get("v.IHContext");
		if (root.startsWith(RLMarker)) {
			root = root.substring(RLMarker.length);
			cmp.set("v.IHContext", root);
		}
        act.setParams({ 
            "ToolContext" : cmp.get("v.ToolContext"), 
            "ActionCode" : cmp.get("v.ActionCode"),
			"IHContext" : cmp.get("v.IHContext"),
			"ClientComponentId" : cmp.get("v.ComponentId"),
			"Params" : parms,
			"SkipGlobals" : SkipGlobals,
        });                       
                
        // Add callback to process returned results
        act.setCallback(helper, function (response, cmp){
            
            // Get our "standard" tools etc. from response
            var result= helper.processTools(response, cmp, SkipGlobals);
            if (result === false) {
                // Get current depth start at 2
                var currentDepth = cmp.get("v.MaxDepth") || 2;
                
                // Only retry if depth is greater than 1
                if (currentDepth > 1) {
                    var nextDepth = currentDepth - 1;
                    cmp.set("v.MaxDepth", nextDepth);
                    helper.initialiseTree(cmp, null, helper); // Retry with decreased depth
                    return;
                } else {
                    // Do not proceed if depth is 1 and it still fails
                    console.warn("MaxDepth reached minimum value of 1. No more retries.");
                }
                
                return; // Always exit
            }
            
            // Set up tree hierarchy from returned listing items and filter nodes as may be required
            helper.setupNodes(cmp, this);            


            // Note some form-specific translations
            cmp.set("v.ToolLabelGlobalSettings", this.Internationalise(cmp, 'ToolLabelGlobalSettings'));
            cmp.set("v.ProductPoweredBy", this.Internationalise(cmp, 'ProductPoweredBy'));
            cmp.set("v.AdviceLabelDropHereToSetRoot", this.Internationalise(cmp, 'AdviceLabelDropHereToSetRoot'));
            cmp.set("v.AdviceLabelDropToSort", this.Internationalise(cmp, 'AdviceLabelDropToSort'));


			// Note any provider-specific capabilities / supported options
			var XCaps = cmp.get("v.ExtendedCapabilities");
			
			XCaps.forEach(function (XC){
				if (XC.Name == 'JITFetching') {cmp.set("v.SupportsJIT", XC.Value);}
				if (XC.Name == 'NodeOrdering') {cmp.set("v.SupportsOrder", XC.Value);}
			});


			// Adjust our root and home root, if required, to reflect any author configurations
			if (cmp.get("v.HasAuthorOverridesClass") != '') {	
				var nods = cmp.get("v.Nodes");
				if (nods.length > 0) {
					cmp.set("v.HomeRoot", nods[0].Id);
				}
			}
        	
        	// Also, advise interested listeners of our initial root node
            helper.RootNodeChange(cmp, event, helper);     	        	
        	helper.hideSpinner(cmp);  
        	
        	
			// Also, refocus our search listing, if a search has been conducted 
			// (If search has not yet been used, there's no need as the tree is yet to render)
			if (cmp.get("v.SearchListActivated") == true) {
				var Lst = cmp.find("SearchList");
				if (Lst + '' != 'undefined') {
					Lst.reInitialise();
				}
			}    
        	
            
        	// Attend to URL parameters, where present
			try {
				var HTIDS = decodeURI(helper.getURLParm(cmp, 'iahelp__HTIDS'));
				var HTID;
				var appEvent; 
				var listensTo = cmp.get("v.ListensTo");
				
				if (HTIDS != '' && cmp.get("v.CheckURLParams") == true) {
			
					// Set latch that says we've considered URL (on page load and not thereafter)
				    cmp.set("v.CheckURLParams", false);
				
					// Split to name value pairs representing source component ID ~ Topic ID
					HTIDS = HTIDS.split('^');
						
					HTIDS.forEach(function (H){
						HTID = H.split('~');
						appEvent = $A.get("e.c:selectTopic");	
					    appEvent.setParams({"RecordId" : HTID[1]});
					    appEvent.setParams({"SourceComponent" : HTID[0]});
					    appEvent.fire();
			
					});
				}
			
			
				HTIDS = decodeURI(helper.getURLParm(cmp, 'iahelp__MTIDS'));
				
				if (HTIDS != '' && cmp.get("v.CheckURLParams") == true) {
			
					// Set latch that says we've considered URL (on page load and not thereafter)
				    cmp.set("v.CheckURLParams", false);
				
					// Split to name value pairs representing source component ID ~ Topic ID
					HTIDS = HTIDS.split('^');
						
					HTIDS.forEach(function (H){
						HTID = H.split('~');
						appEvent = $A.get("e.c:selectTopic");	
					    appEvent.setParams({"RecordId" : 'MTID:' + HTID[1]});
					    appEvent.setParams({"SourceComponent" : HTID[0]});
					    appEvent.fire();
			
					});
				}
			} catch (e) {}
        
        	               
        }); 

        $A.enqueueAction(act);
    },
    
    // Respond to changes in our root node member data:
    // Raise an event to make any listening controls aware of this, should they need this information
    RootNodeChange : function (cmp, event, helper) {

		// NEED TO TAKE CARE HERE:
		// RAISE EVENT SPECIFYING RESULTANT NODE / RECORD ID - NOT
		// ANY INCOMING PARAMETERS THAT MAY HAVE CAUSED ROOT TO CHANGE
		// BUT MAY NOT BE UNDERSTOOD OUTSIDE OF A TREE NODE PROVIDER...

		var root = cmp.get("v.RootNode");
		var HRID = cmp.get("v.HelpRecordId");
         //when addchild operation of Authorconfig layout the HRID is updated
        // with rootnode hence Overwriting it with newHelprecordID contains newly added nodeid.
        if (cmp.get("v.RootNode") === HRID) {
            HRID = cmp.get("v.newHelprecordID");
        }
        var D1 = '^';
		console.log('RootNodeChange tree aura--');


		// Take no action if root is not present
		if (root == '' || root == null || root + '' == 'undefined') {
			return;
		}
		

		// Deal with roots relating to the reading list tree provider
		var RLMarker = 'rL_';
		
		if (root.startsWith(RLMarker)) {
			root = root.substring(RLMarker.length);
		}
		
		if (HRID == '' || HRID == '[None]') {
			HRID = root;
		}	
		

		if (root.indexOf(D1) != -1) {
			
			// Root as specified is complex value for use by tree provider:
			// Amend root to present, actual value of root node
			try {
				root = cmp.get("v.Nodes")[0].Id;
			} catch (e) {
				console.log('Tree error: unable to identify correct node ID to send root node change pass through...');
				return;
			}
		}
		
		// If derived, actual root is '[None]' - indicating that no nodes were to be sought for this tree,
		// do not issue a pass through
		if (root == '[None]') {
			console.log('Tree "' + cmp.get('v.ComponentId') + '" - Root Node was [None] - no pass through will be issued');
		
		} else if (HRID == root) {
		
			console.log('Tree "' + cmp.get('v.ComponentId') + '" - Root Node changing to "' + root + '": issuing pass through and select topic...');
	       
	        var appEvent = $A.get("e.c:evtPassThrough");
	        appEvent.setParams({"SourceComponent": cmp.get("v.ComponentId")});
	        appEvent.setParams({"ActionCode": 'RootNodeChange'});
	        appEvent.setParams({"Parameters": root});    
	        appEvent.fire();    

	        appEvent = $A.get("e.c:selectTopic");
	        appEvent.setParams({"SourceComponent" : cmp.get('v.ComponentId')});
	        appEvent.setParams({"RecordId" : HRID});
	        appEvent.fire();

		} else {
	        // In these circumstances, also issue a selected record change event 
	        // (as this has essentially taken place):
	        
			// Root has changed - but the selected record may differ, if component
			// has been supplied with this info: use selected record here in preference to root, where available

			console.log('Tree "' + cmp.get('v.ComponentId') + '" - Root Node changing to "' + root + '" and Help Record changing to "' + HRID + '": issuing Select Topic event only...');
			              
	        appEvent = $A.get("e.c:selectTopic");
	        appEvent.setParams({"SourceComponent" : cmp.get('v.ComponentId')});
	        appEvent.setParams({"RecordId" : HRID});
	        appEvent.fire();

		}
    },


    // Apply a "hard" filter (not merely match highlighting) to tree's nodes
    setupNodes : function (cmp, helper) {
    
        var msg = '';  			// For diagnostics in case of error processing nodes 
        var i = 0;   			// Ditto
        var ttl = '';
        var PrintViewIconTitle;
        var nods = [];
        var LTs = cmp.get("v.ListingTools");
        var idx;
        var objCode;
        var toolBit;
        var currentRecord = cmp.get("v.HelpRecordId");
        //when addchild operation of Authorconfig layout the currentRecord is updated
        // with rootnode hence Overwriting it with newHelprecordID contains newly added nodeid.
        if (cmp.get("v.RootNode") === currentRecord) {
            currentRecord = cmp.get("v.newHelprecordID");
        }

        // Get a copy of all listing items prior to any filtering
        cmp.set("v.FilteredLIs", cmp.get("v.ListingItems"));
        var LIs = cmp.get("v.FilteredLIs");

            
        // Having done this, do some post-processing on configuration items / listing level tools 
        // to translate incoming integer tool filter into a binary, bit switch representation
        LTs.forEach(function(v){

        	// -1 means "always show" so deal with that here (as does '*' - in cases where we've been  through this code already!)
        	if (v.iahelp__ToolFilter__c + '' == '-1' || v.iahelp__ToolFilter__c + '' == '*') {
	        	v.iahelp__ToolFilter__c = '*';
        	} else {
	        	v.iahelp__ToolFilter__c = helper.DecToBin(cmp, v.iahelp__ToolFilter__c);
        	}
        	
        });



		// Loop to sort nodes by sort value here: this is necessary as, despite apex sorting, numerical
		// sort orders (i.e., when using the Order__c field as sort value) seem to arrive sorted as text
		// such that '100' is less than '9' etc.
		
		var sortables = [];
		var map;
		
		try {
			LIs.forEach(function(L){
			    map = [];
			    if (L.SortValue + '' != 'null') {
			        map.push(parseInt(L.SortValue));
			    } else {
			        map.push(-1);
			    }
			        
			    map.push(L);
			    sortables.push(map)	    
			}); 
			
			sortables.sort(function(a, b) {
			  return a[0] - b[0];
			});
			        
			    
			LIs = [];
			sortables.forEach(function(S){
			    LIs.push(S[1])
			});         
				       
		} catch (e) {
			// This may be because we're not using numeric sort - in which 
			// case skip sorting and re-set:
			LIs = cmp.get("v.FilteredLIs");	
		}        
            
            
        // Our nodes should be in the listing items
        // Add an empty 'root' node 
        nods[undefined] = { Label: "Root", items: [] };
            
        // Add a tree node for each result - with an empty set of children, 
        // plus some other locally defined meta-data
        LIs.forEach(function(v) {
        	
        	// For ease of in-row processing, store object 3-letter code in node data
        	if (v.Id.length > 2) {
        		objCode = v.Id.substring(0,3);
        	} else {
        		objCode = v.Id;
        	}
        	
        	// Also, look this up in known config tool data types: record "bit" in tool filter that should be "on" (1) for this code
        	toolBit = helper.getToolBit(cmp, objCode);
        	if (toolBit == '') {
        		toolBit = '0';
        	}
        	
        	// NOTE:
        	// - RowState 	= used to identify whether a given node participates in other trees (HasPeers)
        	// - IconLabel 	= specifies how many peer trees, if > 0  

        	if (cmp.get("v.PrintView") == true) {
        		PrintViewIconTitle = v.IconTitle;
        	} else {
        		PrintViewIconTitle = '';
        	}
        	
        	nods[v.Id] = { Id: v.Id, 
        					MasterId : v.MasterId,        	
        					Label: v.Label, 
        					Title: v.Title, 
        					ActionCode: v.ActionCode,  
        					SupportedDrops: v.SupportedDrops,  
        					SortValue: v.SortValue,    					
        					Icon: v.Icon, 
        					IconTitle: PrintViewIconTitle,
        					IconLabel: v.IconLabel, 
        					StyleClass: v.StyleClass, 
        					ParentId: v.Parameters, 
        					RowState: v.RowState, 
                            hasChilds: false,
        					ObjCode: objCode,
        					ToolBit: toolBit,
        					Expanded: cmp.get("v.ExpandAllNode"), 
        					items: [] };
        	
        	// Note overall tree title if we find it
        	if (v.Id == cmp.get("v.RootNode")) {
        		ttl = v.Label;
        	}

        	
			// Filter nodes if required
			var filt = cmp.get("v.LIFilter");
			
			if (filt != '' && filt != null) {
				// Make sure we don't filter off the top node (the one with no parent / parameters)!
				// Also, only filter the top level nodes (immediately below root) in this way...
				if (nods[v.Id].Label.substr(0, filt.length) != filt && v.Parameters != '' && v.Parameters == 'Root') {
					//console.log('--------Splice out: ' + nods[v.Id].Label + '(' + v.Id + ') at ' + LIs.indexOf(v));
					LIs.splice(LIs.indexOf(v), 1);
				}            	
			}
        	
        });
            
            
        // Now loop through nodes again, adding each to the items of its parent
        try {  
        	LIs.forEach(function(v) {
            	idx = v.Parameters;
            	if (idx + '' == 'null' || idx == '') {idx = undefined;}
            	msg += v.Id + ':' + idx + ': ' + v.Label + ' - ';
                if(v.Label.includes('[...]')){
				    var labelstr = v.Label.replace('[...]','');
					nods[v.Id].hasChilds = true;
					nods[v.Id].Label = labelstr;

				}
            	nods[idx].items.push(nods[v.Id]);
            	i +=1;
        	});

        } catch (e) {
    		alert ('Error initialising Tree "' + cmp.get("v.ComponentId") + '" (Setup Nodes): At node ' + i + ': ' + e + '\n\n' + msg);
        }            

                	
    	// Set card title to the name of the node representing our context        	
    	cmp.set("v.Title", ttl);
    	
    	
    	// Expand tree to show current record
    	if (currentRecord + '' != 'undefined' && currentRecord != '') {

			if (nods[currentRecord] + '' != 'undefined') {
				nods[currentRecord].Expanded = true;
				
				// Mark as selected
				nods[currentRecord].StyleClass = nods[currentRecord].StyleClass + ' nodeSelected'; 
				
                var visited = new Set();
				var curIdx = nods[currentRecord].ParentId;
				
                while (curIdx != '' && curIdx + '' != 'null') {
                    
                    if (nods[curIdx] + '' != 'undefined') {
                        nods[curIdx].Expanded = true;
                        curIdx = nods[curIdx].ParentId;
                    } else {
                        curIdx = '';
                    }
                    if (visited.has(curIdx)) {
                        // Circular reference detected — break the loop
                        console.log('Circular parent loop detected at: ' + curIdx);
                        var proceed = confirm(helper.Internationalise(cmp,'MessageTreeHoistWarning'));
                        if (!proceed) {
                            return; // Block the operation if user presses Cancel
                        }else{
                              var appEvent = $A.get("e.c:evtPassThrough");
                              appEvent.setParams({"SourceComponent": cmp.get("v.ComponentId")+'TreeNodes'});
                              appEvent.setParams({"ActionCode": "TreeRefocus"});
                              appEvent.setParams({"Parameters": nods[currentRecord].ParentId+","});
                              appEvent.fire();
                              
                              break;
                          } 
                      } 
                      visited.add(curIdx);
                  }
			}
    	}


    	// With node state set, we can pass this to our member data for rendering
    	cmp.set("v.Nodes", nods[undefined].items);
        
        // Added as part of RootNode setting issue fix: in cases when Author Config is play,
        // we need to positively set a root here (and not leave it at the default of '[None]'...
        try{
            cmp.set("v.RootNode", cmp.get("v.Nodes")[0].Id);
            cmp.set("v.Title", cmp.get("v.Nodes")[0].Label);
        }catch(e){
            
            //cmp.set("v.RootNode"," ");
            cmp.set("v.Title"," ");
        }
       
        
    
    },
      
    
	// Check whether our collection of nodes contains a requested record
	nodeExists : function (cmp, nodeId) {
	
		var retVal = false;
		var LIs = cmp.get("v.ListingItems");
		
		try {
			LIs.forEach(function(LI){
				if (LI.Id == nodeId || LI.MasterId == nodeId) {
					retVal = true;
				}
			});
			
		} catch (e) {}
		
		return retVal;
	},    


	// Select a given node on the tree & expand branches to show
	selectNode : function (cmp, helper, nodeId) {
		
		try {
			var LIs = cmp.get("v.ListingItems");
			var nods;
			var parents = [];
			var i;
			var currentChild = nodeId;
			var parentLocated = true;
			var currentParent;
			
			
			// Find the desired node in our listing items:
			// Listing item ID = node ID, Listing item Parameters = parent ID
			// Recurse to find the node's parents up the tree
			
			while (parentLocated == true) {			
				parentLocated = false;
				
				for (i=0; i < LIs.length; i++) {
					if (LIs[i].Id == currentChild || LIs[i].MasterId == currentChild) {
						if (LIs[i].Parameters != '' && LIs[i].Parameters + '' != 'null') {
							parents.push(LIs[i].Parameters);
							currentChild = LIs[i].Parameters;
							parentLocated = true;
						}
						break;
					}
				}
			}
			
			
			console.log('IHTree = selectNode: parents to expand are: ' + parents);		

			// Remove selected class from all nodes
			LIs.forEach (function(L) {
				try {
					if (L.StyleClass == null || L.StyleClass + '' == 'null') {L.StyleClass = '';}
					L.StyleClass = L.StyleClass.split('nodeSelected').join(' ');
				} catch (e){}
			});
			cmp.set("v.ListingItems", LIs);
			helper.setupNodes(cmp, helper);
			nods = cmp.get("v.Nodes");
	
			
			// Expand each located parent: processing the array in reverse order,
			// we will be drilling down from the root of the tree. Each parent should be 
			// in the current parent's Items (child nodes) collection
			
			// Start at the root of the tree: expand this node
			currentParent = nods[0];
			nods[0].Expanded = true;
	
			
			// Child node to expand at this stage will be the last of the parents located 
			// as we recursed UP the tree (above) from the node we intend to select
			i = parents.length - 1;		
			if (parents.length > 1) {
				currentChild = parents[i-1]
			} else {
				currentChild = nodeId;
			}
			
			
			// If there are NO parents, we must be selecting the root node
			if (parents.length == 0) {
				Nods[0].StyleClass = Nods[0].StyleClass + ' nodeSelected';
			}
			
			
			// Now we progress DOWN the tree, expanding each parent in the chain to reach the intended node
			while (i >= 0) {
				currentParent.items.forEach (function(N) {
					
					if (N.Id == currentChild) {
						N.Expanded = true;
						currentParent = N;
						
						// If we're at leaf level, add 'selected' styling to the node located
						if (i == 0) {
							N.StyleClass = N.StyleClass + ' nodeSelected';
							
						} else if (i == 1) {
							currentChild = nodeId;				
						} else {
							currentChild = parents[i-2];
						}
					}
				});
				
				i -= 1;
			}
							
			cmp.set("v.Nodes", nods);

			
		} catch (e) {
			console.log('IHTree - selectNode - Error: ' + e);	
		}
	
	},
   
    
    // Return a value indicating whether D&D ops are allowed at all - based on permissions etc
    dragAllowed : function (cmp, event) {
	
    	var retVal = false;

		// Is user at least a Help Author?
		var isHelpAuthor = cmp.get("v.isAuthor");
		
		// Has page owner specified D&D is allowed on this page?
		var DDLayout = cmp.get("v.DDAllowed");
		
		// Simple boolean operators appear NOT to work!!
		if (isHelpAuthor == true && DDLayout == true) {retVal = true};
		return retVal;
		
	},
	

	// Return a boolean indicating whether drop is allowed onto target based on dragged data
	dropAllowed : function (cmp, event) { 
    
    	var retVal = false;

    	try {
	    	var dat = event.dataTransfer.getData("text");
	    	var TNode = event.target;
	    	var D1 = cmp.get("v.Delimiter");    
	    	var parms = [];
		    var newParent = [];
            
	        var keyTypes = cmp.get("v.GlobalSettings.iahelp__SFObjectIds__c");
	        keyTypes = keyTypes.split('^');
            
	    	parms = dat.split(D1);
	    	
	    	// NB: LUX does not seem to give us access to data during drag!!
	    	// This is why we always see 'diallowed' D&D styling!
	    	//console.log('-=-=-=-=-=-=-=-=-=-=-=-=- ' + event.dataTransfer.getData("text"));


	    	// If drop target is a node, it will have an ID, otherwise not
	    	if (TNode.id) {
	            newParent = TNode.id.split(D1);
	            newParent = newParent[0];
	    	}
            
			// For now, we can only deal with ops representing Help Topic OR Reading List OR Resource records
			if (parms[1].substring(0,3) == keyTypes[0] || parms[1].substring(0,3) == keyTypes[1] || parms[1].substring(0,3) == keyTypes[2]) {
	    	
	    		// Prevent drop of nodes onto themselves
	    		if (parms[1] != newParent) {
		    		retVal = true;
                } 
	    	}

    	} catch (e) {
    		//console.log('Tree - drop Allowed error: ' + e);
    	}
        
        return retVal;
    },	
    
    // Checking for circular relationship of parent-> child-> parent
    isCircularReference: function(cmp, nodeId, parentId) {
        var LIs = cmp.get("v.ListingItems");
        var parentMap = {};
        
        // Build parent-child map
        LIs.forEach(function(LI) {
            parentMap[LI.Id] = LI.Parameters;
        });
        
        // Check if parentId is in nodeId's hierarchy
        var current = parentId;
        var visited = new Set([nodeId]);
        
        while (current && current !== "") {
            if (visited.has(current)) {
                return true; // Cycle detected
            }
            visited.add(current);
            current = parentMap[current];
        }
        
        return false;
    },
    
        
})