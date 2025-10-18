({

    // Initialise some key settings from our 'parent' tree control 
    init: function (cmp, event, helper) {
        var T = cmp.get('v.TreeControl');
        cmp.set("v.GlobalSettings", T.get("v.GlobalSettings"));
        cmp.set("v.TreeControlLevelIndentation", T.get("v.LevelIndentation"));
        cmp.set("v.TreeControlPrintView", T.get("v.PrintView"));
        cmp.set("v.UXThemeColour1", T.get("v.UXThemeColour1"));
        
        // Identify parent nodes 
        var node = cmp.get("v.Node");
        var isParentNode = (cmp.get("v.Level") === 0 || 
                            !node.ParentId || 
                            node.ParentId === '' || 
                            node.ParentId === 'Root');
        cmp.set("v.isParentNode", isParentNode);
        
        // === Filter tools without modifying the original array ===
        var originalTools = cmp.get("v.ListingTools");
        var filteredTools;
        
        if (cmp.get("v.isParentNode")) {
            // For parent nodes: Exclude Delete/TreeAddPeer
            filteredTools = originalTools.filter(function(tool) {
                return tool.iahelp__ActionCode__c !== 'TreeDeleteNode' && 
                    tool.iahelp__ActionCode__c !== 'TreeAddPeer' && tool.iahelp__ActionCode__c !== 'TreeRefocus';
            });
        } else {
            // For child nodes: Use all tools
            filteredTools = originalTools;
        }
        cmp.set("v.FilteredListingTools", filteredTools); // Store filtered tools separately
        // Get safe, parsed version of any rich text for printable views
        T.set("v.sHTML", cmp.get("v.Node").IconTitle);
        cmp.set("v.PrintableNodeDescription", T.getSafeHTML());
    },


	// Initialise / re-examine listing (node) tool visibility
	doneRendering: function (cmp, event, helper) {

		try {
			if (cmp.get("v.isInitialised") == false) {
				helper.showAllowedNodeTools(cmp, event);
				cmp.set("v.isInitialised", true);
			}
		} catch (e) {
			cmp.set("v.isInitialised", true);
		}

	},


	// Expand / collapse the nodes beneath a given, clicked node
	toggle: function (cmp, event, helper) {
		cmp.set("v.Expanded", !cmp.get("v.Expanded"));

		// As we expand nodes (and they render), re-check node tool availability (by un-latching doneRendering)
		cmp.set("v.isInitialised", false);
	},


    // Raise a record selected event when a tree node is clicked 
    treeNodeClick: function (cmp, event, helper) {
        
        
        // Mark the selected node
        var marked = document.getElementsByClassName('nodeSelected');
        for (var i = 0; i < marked.length; i++) {
            $A.util.removeClass(marked[i], 'nodeSelected');
        }
        $A.util.addClass(document.getElementById(event.target.id), 'nodeSelected');
        
        
        // Fire the required event: 
        // Event depends on whether or not the tree provider specifies particular action codes...
        var nod = cmp.get("v.Node");
        var theId = event.currentTarget.id;
        var nodeId = theId.replace(/^NodeContainer_/, '').split(cmp.get('v.Delimiter'))[0];
        var D1 = cmp.get('v.Delimiter');
        var T = cmp.get('v.TreeControl');
        
        if (nod.ActionCode != '' && nod.ActionCode + '' != 'undefined') {
            // If an action code was supplied via the listing item that formed this node, raise a pass-through with those details
            
            console.log('Tree Node "' + nod.Id + '" Click - raising pass through: Action = ' + nod.ActionCode);
            
            var appEvent = $A.get("e.c:evtPassThrough");
            appEvent.setParams({ "SourceComponent": T.get("v.ComponentId") });
            appEvent.setParams({ "ActionCode": nod.ActionCode });
            appEvent.setParams({ "Parameters": nod.Id + '^' + nod.ParentId });
            appEvent.fire();
            
            
        } else {
            // If NO action code was supplied, revert to standard behaviour and issue a record select event
            
            console.log('Tree Node Click - No specific action so raising select');
            
            // Fire a record selected event: Node clickable's is in the form: 
            // [Node Id] [Delimiter] [ParentId]
            var appEvent = $A.get("e.c:selectTopic");
            
            nodeId = nodeId.split(D1);
            console.log('theId===>',nodeId);
            appEvent.setParams({ "RecordId": nodeId[0] });
            appEvent.setParams({ "SourceComponent": T.get('v.ComponentId') });
            appEvent.fire();
        }
        
        
        // In all cases, log a Tree Node click interaction
        //var act = T.get("c.logLUXInteraction");
        
        /*  act.setParams({ 
		"iTyp" : "14",
		"Description" : theId[0],
		"IHContext" : T.get("v.RootNode")
			});     */
        
        // Send action
        //	$A.enqueueAction(act);
        
        T.logLUXInteractions(cmp, 14, theId[0], T.get("v.RootNode"));
        
    },


	// Handle in-line listing tool clicks (by raising a pass-through)
	treeNodeToolClick: function (cmp, event, helper) {

		var theId = event.target.id;
		var D1 = cmp.get('v.Delimiter');
		var T = cmp.get('v.TreeControl');

		theId = theId.split(D1);

		// Click "message" (the id of the clickable) is in the form:
		// [Listing record Id] [Delimiter] [Action code] [Delimiter] [Parameters]

		// We delegate responses to tool clicks to our parent tree via a pass through
		var appEvent = $A.get("e.c:evtPassThrough");
		appEvent.setParams({ "SourceComponent": T.get('v.ComponentId') + 'TreeNodes' });
		appEvent.setParams({ "ActionCode": theId[1] });
		appEvent.setParams({ "Parameters": theId[2] });
		appEvent.fire();

	},


	// Handle pass throughs from elsewhere (e.g., Header tools)
	handlePassThroughs: function (cmp, event, helper) {

		var act = event.getParam("ActionCode");
		var src = event.getParam("SourceComponent");
		var T;

		try {
			T = cmp.get('v.TreeControl');

			// Only respond to requests from our own tree
			if (src === T.get("v.ComponentId")) {

				if (act === 'TreeExpandAll') {
					cmp.set("v.Expanded", true);
				}

				if (act === 'TreeCollapseAll') {
					cmp.set("v.Expanded", false);
				}

				if (act === 'CardBodyScroll') {
					var T = cmp.get('v.TreeControl');
					var dvPeers = T.find("PopoverPeers");
				}
			}

		} catch (e) {
			// Silent fail
		}
	},

    
    // For dragging of our own nodes, place suitable data into the drag
    doDragStart: function (cmp, event, helper) {
        var T = event.target.id;
        var D1 = cmp.get("v.Delimiter");
        var dat;
        var recordId;
        var Tree = cmp.get("v.TreeControl");
        
        event.dataTransfer.dropEffect = "move";
        
        // Send: drag type = TreeNode, dragged node ID, parent of that node:
        // As the ID of the draggable (node listing item) is already in this form, no processing required here...
        // Handle both cases:
        // 1. Direct ID (a0BAd0000063MzdMAE)
        // 2. Prefixed ID (LINarrow_a0BAd0000063MzdMAE)
        if (T.includes('_')) {
            // For prefixed IDs, split and take the last part
            var parts = T.split('_');
            recordId = parts[parts.length - 1];
        } else {
            // For direct IDs, use as is
            recordId = T;
        }
        
        // Get just the record ID part (after last underscore if present)
        dat = 'TreeNode' + D1 + recordId;
        event.dataTransfer.setData('text', dat);
        
        // D&D data is not available on drag over, so log a passthrough with this data 
        // so those dragged over know how to respond
        var appEvent = $A.get("e.c:evtPassThrough");
        appEvent.setParams({ "SourceComponent": Tree.get('v.ComponentId') + 'TreeNodes' });
        appEvent.setParams({ "ActionCode": 'DragStart' });
        appEvent.setParams({ "Parameters": dat });
        appEvent.fire();
    },



	// Advise interested parties that a D&D operation has ended
	doDragEnd: function (cmp, event, helper) {

		var Tree = cmp.get("v.TreeControl");

		// Raise a passthrough to clear drag data
		var appEvent = $A.get("e.c:evtPassThrough");
		appEvent.setParams({ "SourceComponent": Tree.get('v.ComponentId') + 'TreeNodes' });
		appEvent.setParams({ "ActionCode": 'DragEnd' });
		appEvent.fire();
	},


	// Show whether or not drop will be allowed
	doDragOver: function (cmp, event, helper) {

		if (helper.DDAllowed(cmp, event, helper) == true) {
			event.preventDefault();

			var Node = event.target;
			var Tree = cmp.get("v.TreeControl");
			var Ord = cmp.find("NodeOrdinal");

			// Do nothing further if we're the container
			if (Node.classList.contains('TreeNodeContainer')) {
				return;
			}


			try {
				// Add styling to target, as appropriate to whether or not drop onto node itself is allowed						
				if (helper.dropAllowed(cmp, event, helper) == false) {
					$A.util.addClass(Node, 'DropTargetUnavailable');

				} else {
					$A.util.addClass(Node, 'DropTargetActive');
				}

				// Show ordinal target if tree provider supports node ordering			
				if (Tree.get("v.SupportsOrder") + '' == 'true') {
					$A.util.removeClass(Ord, "slds-hide");
				}

			} catch (e) { }
		}
	},


	// Remove any drag over style hints
	doDragLeave: function (cmp, event, helper) {
		event.preventDefault();

		var Node = event.target;
		var Ord = cmp.find("NodeOrdinal");

		$A.util.removeClass(Node, 'DropTargetActive');
		$A.util.removeClass(Node, 'DropTargetUnavailable');

		// Hide ordinal if it's ordinal or overall container we're leaving
		if (Node.classList.contains('NodeOrdinal')
			|| Node.classList.contains('TreeNodeContainer')
			|| (Node.classList.contains('DropTarget') && event.offsetY > 10)
			|| (Node.classList.contains('TreeNodeClickableContainer') && event.offsetY > 10)
		) {
			$A.util.addClass(Ord, "slds-hide");
		}
	},


	// Take action when drop occurs
	doDrop: function (cmp, event, helper) {
		event.preventDefault();

		var Tree = cmp.get('v.TreeControl');
		var Node = event.target;
		var Ord = cmp.find("NodeOrdinal");
		var dat = event.dataTransfer.getData("text");
		var D1 = cmp.get("v.Delimiter");
		var newParent = [];
		var parms = [];
		var isSortOp = Node.classList.contains('NodeOrdinal');


		// Handling will be via a passthrough handled by parent tree...
		var appEvent = $A.get("e.c:evtPassThrough");
		appEvent.setParams({ "SourceComponent": Tree.get('v.ComponentId') + 'TreeNodes' });


		parms = dat.split(D1);
		newParent = Node.id.split(D1);
		newParent = newParent[0];

		console.log('TreeNodes: Dropped "' + dat + '" onto "' + event.target.id + '" - attempting to process...');


		// Remove D&D styling clues
		$A.util.removeClass(Node, 'DropTargetActive');
		$A.util.removeClass(Node, 'DropTargetUnavailable');
		$A.util.addClass(Ord, "slds-hide");


		// At this point, we need to differentiate depending on:
		// - whether drop is allowed
		// - whether sorting is allowed
		// - what data was dragged (dat - now split to parms). This will be as follows:
		// 			- Tree node dropped onto another:
		//					TreeNode [D1] [Node Id] [D1] [Node's parent Id]
		//			- List row dragged onto tree node:
		//					ListRow [D1] Topic Id
		//			- Topid summary text (from IHDetail) dragged onto tree node:
		//					DetailTitle [D1] Topic Id

		/*
		
		if drop allowed = false, end
		
		if drop allowed = true
			if this 'is a sort op', set sort order
			else, retain parms [0]
		
			'sort op' = parms [0] (source of op) = TreeNode AND tree supports sort AND operation is genuinely a SORT
		
			What is genuinely a sort??
			How do I know, if dragging onto a node, that I want to reorder (to drop target's position)
			versus reparent (so new parent = drop target)?
		
		*/

		if (helper.dropAllowed(cmp, event, helper) == false) {
			console.log('TreeNodes: drops not permitted - returning');
			return;

		} else {
			console.log('TreeNodes: drop permitted - continuing...');

			if (parms[0] == 'TreeNode' && Tree.get("v.SupportsOrder") + '' == 'true' && isSortOp == true) {
				console.log('TreeNodes: sort operation - amending op and continuing...');
				parms[0] = 'SortOrder';

			} else {
				// Retain incoming op code / parameter 0
				console.log('TreeNodes: NOT a sort operation - continuing with specified op (' + parms[0] + ')...');

			}
		}


		// Having established that we may proceed, respond according to request operation
		switch (parms[0]) {
			case 'SortOrder':

				// Need to locate the node record representing the one onto which we dropped
				// so we can obtain the desired new sort order
				var LIs = Tree.get("v.ListingItems");
				var SO;

				LIs.forEach(function (LI) {
					if (LI.Id == newParent) {
						SO = LI.SortValue;
					}
				});

				appEvent.setParams({ "ActionCode": 'TreeEditSortOrder' });

				// Child Id, desired sort order (that of the node we were dropped onto
				appEvent.setParams({ "Parameters": parms[1] + D1 + parms[2] + D1 + newParent + D1 + SO });
				console.log('TreeNodes: sort order of node ' + parms[1] + ' will be set to ' + SO);
				break;

			case 'TreeNode':
				// We're re-positioning an existing node
				appEvent.setParams({ "ActionCode": 'TreeReparentNode' });

				// Child Id, current parent id, new parent (node we were dropped onto)
				appEvent.setParams({ "Parameters": parms[1] + D1 + parms[2] + D1 + newParent });
				break;

			case 'ListRow':
			case 'DetailTitle':
				// We're adding a node by dragging from a list or topic viewer (summary text)
				appEvent.setParams({ "ActionCode": 'TreeAddChildFromExisting' });

				// New child ID, node we were dropped onto (parent to be)
				appEvent.setParams({ "Parameters": parms[1] + D1 + newParent });
				break;
		}

		appEvent.fire();

	},


	// Obtain tree levels below max depth on a just in time basis / as lower levels are expanded
	getSubTree: function (cmp, event, helper) {

		console.log('inside getsubtree');

		var T = cmp.get('v.TreeControl');
		var MaxDepth = T.get("v.MaxDepth");
		var Params = MaxDepth + '^undefined';
		var theId = cmp.get('v.Node.Id');

		console.log('theId: ' + theId);

		var treeHelper = T.get("v.helperReference");
		treeHelper.showSpinner(T);

		//Calling T.get("c.getSubTree") because ControllerLUXOps is defined as controller of Tree component
		var act = T.get("c.getSubTree");

		act.setParams({
			"IHContext": theId,
			"Params": Params
		});
		act.setCallback(this, function (response, cmp) {

			var state = response.getState();
            try{
			if (state === "SUCCESS") {
				console.log("Call to getSubTree returned: " + response.getReturnValue());

				var obj = [];
				try {
					var root;
					var listitem = [];

					obj = JSON.parse(response.getReturnValue());
					console.log(obj);
					root = obj[0].Id;

					// This is necessary to get rid of root node of sub tree
					obj.shift();
					console.log(' After popping 1st element from Obj ');
					console.log(obj);

					console.log(cmp.get("v.ListingItems"));

					listitem = cmp.get("v.ListingItems").concat(obj);
					console.log(' After concatenating listitems & obj, displaying listitems ');
					console.log(listitem);

					//Modifying node Label to get rid of unique icon
					listitem.forEach(function (v) {
						if (v.Id + '' == root) {
							if (v.Label.includes('[...]')) {
								v.Label = v.Label.replace('[...]', '');
							}
						}
					});

					cmp.set("v.ListingItems", listitem);
					var L = cmp.get("v.helperReference");
					//To make the clicked node selected & expanded
					cmp.set("v.HelpRecordId", root);
					L.setupNodes(cmp, L);
					L.hideSpinner(cmp);

				} catch (e) {
					console.log('IHTreeNodesController : error in parsing json ' + e);
				}
            }
            }
                finally {
                treeHelper.hideSpinner(T); // Always hide spinner
            }
			


		});
		$A.enqueueAction(act);
	},


})