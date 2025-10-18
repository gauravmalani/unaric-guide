({ 

	// Get the largely invariant, cacheable information used on cards (delegated)
	// then cue initialisation
	init : function(cmp, event, helper) {
		
		// Video mode requires different container sizing
		cmp.set("v.AutoCardHeight", cmp.get("v.MediaMode") == 'Image');
	
		helper.initialiseGlobals(cmp, event, helper);
	},


	// Respond to the "select" event raised by lists (if we're listening to the source component)
    selectRecord : function (cmp, event, helper) {
        
        var theRecord = event.getParam("RecordId");

        // Only respond to events that do not emanate from ourselves / do
        // emanate from the  "desired" master list(s) we wish to tie to
        if (helper.eventBeingListenedTo(cmp, event) == true) {
            helper.showSpinner(cmp);
            cmp.set("v.ListingItems", null);
            cmp.set("v.HelpRecordId", theRecord);
            
            console.log('Image Viewer "' + cmp.get("v.ComponentId") + '" responding to a change in record to: ' + theRecord);            
            helper.initialiseImg(cmp, event, helper);
        }
    },


	// Respond to events from super-class - display settings etc...
	handlePassThroughs : function (cmp, event, helper) {
        
        var act = event.getParam("ActionCode");
        var src = event.getParam("SourceComponent");
        
        
        // With display settings, we only want to respond to our own events...
        if (helper.eventIsOurOwn(cmp, event)) {
        	
        	// Image relative width
			if (act === 'ImgVMediaLarge') {
			    cmp.set("v.MediaWidth", "100");
			}
			
			if (act === 'ImgVMediaSmall') {
			    cmp.set("v.MediaWidth", "50");
			}
			
			if (act === 'ImgVMediaMedium') {
			    cmp.set("v.MediaWidth", "75");
			}
			
			
			// Pop out
			if (act === 'ImgVPopOut') {
				window.open(cmp.get("v.ImageURL"), 'IHImagePopout', 'menubar=0, resizable=1, status=0, toolbar=0, titlebar=0, location=0');
			}

        }
        
	},
    

})