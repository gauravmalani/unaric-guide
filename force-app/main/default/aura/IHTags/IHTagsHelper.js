({
	
	// Get the collection of tags that are members of the selected root 
	initialise: function(cmp, event, helper) {

		helper.showSpinner(cmp);
                
        // NB: this action code will return all tags in the pool,marked with whether or not
        // they are set for the current context (Help Record Id)
        cmp.set("v.ActionCode", "GetTags"); 
 
        var act = cmp.get("c.getTools"); 
        act.setParams({ 
        	"ToolContext" : cmp.get("v.ToolContext"),
        	"ActionCode" : cmp.get("v.ActionCode"),
			"IHContext" : cmp.get("v.HelpRecordId"),
			"ClientComponentId" : cmp.get("v.ComponentId"),
			"Params" : cmp.get("v.RootNode"),
			"SkipGlobals" : false,
        });                       
                
        // Add callback to process returned results
        act.setCallback(helper, function (response, cmp){
        	helper.processTools(response, cmp); 
        	
        	// If we're in search mode, add an "un-tagged" filter option, representing
        	// items that have none of the tags in the pool set
        	var lst = cmp.get('v.ListingItems');

        	if (cmp.get('v.CardConfig') == 'Search' && lst.length > 0) {
	        	
	        	var ttl = helper.Internationalise(cmp, 'TipButtonUntaggedItems');
	        	var lbl = helper.Internationalise(cmp, 'ButtonUntaggedItems');
	        	var theIds = '';
	        	var i;
	        	
	        	// To differentiate this tool, which has the same click handler as all others, we place the IDs of ALL tags
	        	// in the pool into it as a colon separated list: this is picked up by the Apex controller action...
	        	for (i=0; i < lst.length; i++) {
	        		theIds += lst[i].Id + ':';
	        	}
	        	theIds = theIds.substring(0, theIds.length - 1);
	        	
				var strLI = '{"UntaggedOption":"TRUE","Title":"' + ttl + '","StyleClass":"IATool UnTagged UnTaggedItemsOption","RowState":null,"Parameters":"","Label":"' + lbl + '","Id":"' + theIds + '","IconTitle":"","IconLabel":"","Icon":"","ActionCode":"TagClick"}';
	        	var LI = JSON.parse(strLI);
				lst.push(LI);
				
	        	cmp.set('v.ListingItems', lst);
        	}
        	
        	// If the pool has no member tags, set no data message accordingly:
        	// Note we do this here to avoid translation codes in markup
        	if (lst.length == 0) {
        		// v1.42+ : leave message up to page owner...
        		//cmp.set("v.NoDataMessage", helper.Internationalise(cmp, "AdviceLabelNoPoolMembers"));
        	}


// If we were asked to toggle a tag on arrival at the pool, do so:
if (cmp.get("v.OnArrivalToggleNode") != '') {

	var theClickedTag = cmp.get("v.OnArrivalToggleNode");       		
	var toBeTagged = false;
	var LIs = cmp.get("v.ListingItems");
	
	// NB: here we need to check current tagged state via listing items data rather than badge styling:
	// This should amount to the same thing, but badges may not be reliably rendered at this stage...
	// Locate the desired tag in our listing items collection and check for 'selected' marker style
	
	LIs.forEach(function (L){
		if (L.Id == theClickedTag) {
			toBeTagged = L.StyleClass.indexOf('UnTagged') != -1;
		}
	});

	console.log('Card Tags - Initialise - Toggle on arrival: Set tag "' + theClickedTag + '" to ' + toBeTagged);
	
	cmp.set("v.OnArrivalToggleNode", '');        		
	helper.toggleTag(cmp, event, helper, theClickedTag, toBeTagged);      
	
}

        	
        	// Note the fact that we're initialised
        	cmp.set("v.isInitialised", true);
        	
        }); 
        
        $A.enqueueAction(act);

    },
    
    
    // Run a search when a filtering event in the UI calls for this
    cueSearch : function(cmp, event, helper) {
    
        var theTags = cmp.get("v.SelectedTags");
        var theTagMode = cmp.get("v.TagMode");
        var D1 = '^';     			
        var appEvent = $A.get("e.c:evtPassThrough");

		// Raise event to advise of new selections
		// Parameters to send should be all selected tags plus mode
        appEvent.setParams({"SourceComponent": cmp.get("v.ComponentId")});
        appEvent.setParams({"ActionCode": 'FilterToTags'});
        appEvent.setParams({"Parameters": theTags + D1 + theTagMode});       
        appEvent.fire();
    		    		
    },
    
    
	// Toggle a tag when a tag click or incoming message calls for this
	toggleTag: function(cmp, event, helper, theClickedTag, toBeTagged) {

		// If mode is "Associate", we want to toggle the selected tag on or off...
		// This can only be allowed if we have a selected topic context
		if (cmp.get("v.HelpRecordId") == '' || cmp.get("v.HelpRecordId") + '' == 'undefined') {
			cmp.set("v.Diags", helper.Internationalise(cmp, 'AdviceLabelSelectTopic'));
			return;
		}

		helper.showSpinner(cmp);
		
		var act = cmp.get("c.toggleTag");
        act.setParams({ 
			"HTID" : cmp.get("v.HelpRecordId"),
			"tagId" : theClickedTag,
			"tagged" : toBeTagged,
        });                       
            
        // Add callback to process returned results
        act.setCallback(helper, function (response, cmp){
        
            // We are setting AuthorConfigLatch value to true, when we edit tags and Author config may be in play.
            // This is to prevent incorrect help record being set at the point we add any new tag relationship:
            // this needs to be between context topic and clicked tag: author configs setting pool could result 
            // in attempt to relate pool to clicked tag...
            cmp.set("v.AuthorConfigLatch", true);
        
        	helper.processTools(response, cmp);        
        }); 
    
        $A.enqueueAction(act);

	},
	    

	// Return a value indicating whether D&D ops are allowed at all - based on permissions etc
	DDAllowed : function (cmp, event) {
	
    	var retVal = false;

		// Is user at least a Help Author?
		var isHelpAuthor = cmp.get("v.isAuthor");
		
		// Has page owner specified D&D is allowed on this page?
		var DDLayout = cmp.get("v.AllowCloudEditing");
		
		// Simple boolean operators appear NOT to work!!
		if (isHelpAuthor == true && DDLayout == true) {retVal = true};
		return retVal;
		
	},
	
	
	// Return a boolean indicating whether drop is allowed onto target based on dragged data
    dropAllowed : function (cmp, event) { 
    
    	var retVal = false;

    	try {
	    	var dat = event.dataTransfer.getData("text");
	    	var D1 = cmp.get("v.Delimiter");    
	    	var parms = [];

	        var keyTypes = cmp.get("v.GlobalSettings.iahelp__SFObjectIds__c");
	        keyTypes = keyTypes.split('^');
            
	    	parms = dat.split(D1);

	    	// For now, we can only deal with ops representing Help Topic records
	    	if (parms[1].substring(0,3) == keyTypes[0]) {
	    		retVal = true;
	    	}

    	} catch (e) {
    		//console.log('IHTags dropAllowed error: ' + e);
    	}
    	
        return retVal;
    },	
	
	
})