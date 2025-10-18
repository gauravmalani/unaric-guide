({
	
	// Return a value indicating whether D&D ops are allowed at all - based on permissions etc
	DDAllowed : function (cmp, event, helper) {
	
    	var T = cmp.get('v.TreeControl');
    	var retVal = false;

		try {
			// Logic around whether D&D as a whole is allowed is controlled by our parent tree
			retVal = T.dragAllowed(cmp, event, helper);
		} catch (e) {}

		return retVal;
	},
	

    // Return a boolean indicating whether drop is allowed onto target based on dragged data
    dropAllowed : function (cmp, event, helper) { 
    
    	var retVal = false;

    	try {
	    	var dat = event.dataTransfer.getData("text");
	    	var TNode = event.target;
	    	var D1 = cmp.get("v.Delimiter");    
	    	var parms = [];
		    var newParent = [];
	    	var T = cmp.get('v.TreeControl');
            
	        var keyTypes = T.get("v.GlobalSettings.iahelp__SFObjectIds__c");
	        keyTypes = keyTypes.split('^');
            
            // If we don't get drag data (varies by browser?) obtain it from tree
            // which will have kept a copy at the point where drag began (in response to passthrough)
			if (dat + '' == 'undefined' || dat + '' == 'null' || dat == ''){
				dat = T.get("v.DragData");
			}            

	    	parms = dat.split(D1);

            newParent = TNode.id.split(D1);
            newParent = newParent[0];
            
            
			// Drop only allowed if tree says drag is allowed in general...
			if (T.dragAllowed(cmp, event, helper) == false) {
				console.log('TreeNodes: Drop not permitted - parent tree component disallows');
				
			
			// ... AND node says it can accept a drop of this kind
			} else if (helper.isPermittedChild(cmp, event, helper, parms[1]) == false) {
				console.log('TreeNodes: Drop not permitted - parent tree component allows this, but node does not support children of this type');
		

			// ... AND we're not dropping node onto itself
			} else if (parms[1] == newParent) {
            	console.log('TreeNodes: Cannot drop node onto itself');
            	
            } else {
	    		retVal = true;
            }

    	} catch (e) {
    		console.log('TreeNodes: drop error - ' + e);
    	}
    	
        return retVal;
    },	
	
	
	// Returns a boolean indicating whether our node can accept a proposed 'child' (dropped item)
	// based on what the tree provider specified via the 'Supported Drops' list item / node member
	isPermittedChild : function (cmp, event, helper, ChildId) {
		
		var retVal = false;
		
		var N = cmp.get("v.Node");
		var D1 = ',';
		var SDs = N.SupportedDrops;
		var Tree = cmp.get('v.TreeControl');
		var TNode = event.target;		
		var isSortOp = TNode.classList.contains('NodeOrdinal');

		
		// Child must be specified (parent is ourselves / the current node)
		if (ChildId != '' && ChildId + '' != 'null' && ChildId + '' != 'undefined') {
			
			// Split node's supported drop information into details of each individual type that can be dropped
			if (SDs + '' != 'undefined' && SDs + '' != 'null') {
				SDs = SDs.split(D1);
				
				SDs.forEach(function (SD){
					if (SD != '') {
						if (ChildId.startsWith(SD)) {
							retVal = true;
							//console.log('TreeNodes Helper: child "' + ChildId + '" may be dropped on node "' + N.Id + '" because it permits children of type "' + SD + '"');
						}
					}
				});
			}
			
			// Drop is also allowed if it is on to a sort ordinal and tree provider supports sort ops
			if (Tree.get("v.SupportsOrder") + '' == 'true' && isSortOp == true) {
				retVal = true;
				//console.log('TreeNodes Helper: child "' + ChildId + '" may be dropped here because target is a sort ordinal and tree provider supports sorting');
			}			
		}			
		
		return retVal;
	},
	
	
	// Show listing (node) tools appropriate to record type of node according to config item tool filter
	showAllowedNodeTools : function (cmp, event) {
	
    	// Loop through tools.
    	// Remove hidden class on any whose required tool bit matches that tool's bits
    	var LTs = cmp.get("v.ListingTools");
    	var N = cmp.get("v.Node");
    	var binFilter;
    	var currentBit;
    	var matchingRowTools;
    	var toolQualified = false;
    	var QualifyingTools = 0;
    	var i;
    	var j;
    	var bitNo;
    	
    	try {
	    	LTs.forEach(function(T) {
	    		// Get tool's tool filter bit code
	    		binFilter = T.iahelp__ToolFilter__c;
	    		
	    		// Default this tool to not qualifying
    			toolQualified = false;

    			//console.log('Tree Nodes Helper - checking allowed Node tools for ' + T.iahelp__ActionCode__c + ': tool filter = ' + binFilter);
	    		
	    		// Loop through filter to check each bit, starting at LSB (right-hand bit)
	    		for (i=binFilter.length; i>0; i--) {
	    			currentBit = binFilter.substr(i-1,1);

	    			//console.log('Bit ' + i + ' = ' + currentBit);
	    			
	    			// If bit is "on" for this tool at this position, show tools on rows requiring this bit
	    			if (currentBit == '1') {
						
						// i = POSITION IN A BINARY STRING - HIGHEST NUMBER = LOWEST SIGNIFICANT BIT
						// WE NEED THIS ADJUSTED TO REFLECT BINARY NUMBER LOGIC: EG
						// Tool filter = 32 = 100000
						// We need BIT 6 to be ON
						// However, this is position 1 in binary string (not 6)
						
						bitNo = (binFilter.length - i) + 1;
						
						// Un-hide any listing tools marked with the current (switched on) bit
						matchingRowTools = document.getElementsByClassName(T.iahelp__ActionCode__c + ' TBit' + bitNo);
	    				for (j=0; j<matchingRowTools.length; j++) {
	    					matchingRowTools[j].classList.remove('slds-hide');    				
	    				}
	    				
	    				// The above un-hides tools - but these (by virtue of how we use DOM to find them) may not be 
	    				// our own. We need to take note of whether we have matching tools so we can track how many total
	    				// tools our node is showing - in case we need to collapse to an ellipsis (MaxListingTools etc.)
	    				// Compare current tool's bit number with our node's to do this
	    				if (bitNo == N.ToolBit) {
	    					toolQualified = true;
	    				}
	    			}
	    			
	    			// If bit is on for all types (-1 translated to marker code in tree Helper.setupNodes), show  tools regardless
	    			if (currentBit == '*') {
						matchingRowTools = document.getElementsByClassName(T.iahelp__ActionCode__c + ' TBit0');
	    				console.log('IHTreeNodes - show allowed tools: For ' + T.iahelp__ActionCode__c + ', switch on ' + matchingRowTools.length + ' tools requiring bit ' + i);    		
	    				
	    				for (j=0; j<matchingRowTools.length; j++) {
	    					matchingRowTools[j].classList.remove('slds-hide');    				
	    				}
	    			}
	    		}
	    		
	    		
	    		// Increment the number of qualifying tools, where relevant
	    		if (toolQualified == true) {
	    			QualifyingTools += 1;
	    		}
	    	});
	    	
	    	
	    	// Note the total number of qualifying tools, for use in collapsing to ellipsis where max listing tools settings dictate this
	    	cmp.set("v.QualifyingListingTools", QualifyingTools);
    	
    	} catch (e) {}
	
	},	
	
})