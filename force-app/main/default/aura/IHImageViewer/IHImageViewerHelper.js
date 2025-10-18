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
                    this.initialiseImg(cmp, event, helper);
                }
                
            });
            $A.enqueueAction(act);	
                
        } else {
            this.initialiseImg(cmp, event, helper);
        }		

	},


	// Prepare viewer - which means getting configuration tools:
	initialiseImg : function(cmp, event, helper) {

        // Only attempt to retrieve topic if we're given a record ID: otherwise,
        // assume we've been given an image URL and just retrieve the relevant tools (blank action code)
        if (cmp.get('v.HelpRecordId') + '' != 'undefined' && cmp.get('v.HelpRecordId') != '') {
	        cmp.set('v.ActionCode', 'HelpTopic');
        } else {
	        cmp.set('v.ActionCode', '');
        }


        cmp.set('v.ToolContext', 'ImageViewer');
        cmp.set('v.IHContext', cmp.get('v.HelpRecordId'));

        var SkipGlobals = cmp.get("v.SkipGlobals");	
        
        var act = cmp.get("c.getTools");
        act.setParams({ 
            "ToolContext" : cmp.get('v.ToolContext'), 
            "ActionCode" : cmp.get('v.ActionCode'),
            "IHContext" : cmp.get('v.IHContext'),
            "ClientComponentId" : cmp.get("v.ComponentId"),
            "Params" : cmp.get("v.HelpRecordId"), 
            "SkipGlobals" : SkipGlobals,
        });                       
            

        // Create a callback that is executed after the server-side action returns
        act.setCallback(helper, function (response, cmp){
            
            helper.processTools(response, cmp, SkipGlobals);      

			// If we got a "list" back, it means we were given a record (topic) ID, so
			// should use it as our source for media and title
			var lst = cmp.get('v.ListingItems');
			var ttl;
			
			if (lst + '' != '') {
				if (lst.length > 0) {	
				
					// Select media depending on mode
					if (cmp.get("v.MediaMode") == 'Image') {
						cmp.set("v.ImageURL", lst[0].iahelp__ImageURL__c);  
						                
						ttl = lst[0].Name;
						if (lst[0].iahelp__ImageTitle__c + '' != 'null') {
							ttl += ': ' + lst[0].iahelp__ImageTitle__c;
						}
					
					} else {
						cmp.set("v.ImageURL", lst[0].iahelp__VideoURL__c);  
						                
						ttl = lst[0].Name;
						if (lst[0].iahelp__VideoTitle__c + '' != 'null') {
							ttl += ': ' + lst[0].iahelp__VideoTitle__c;
						}
					}
									
					cmp.set('v.ImageTitle', ttl);
				}
			}
            
            cmp.set("v.Title", cmp.get('v.ImageTitle'));                  
            cmp.set("v.Diags", '...');                  
        });                
        

        // Send action and note the fact that this has been done / we're initialised        
        cmp.set('v.isInitialised', true);
        helper.showSpinner(cmp);
        
        helper.logDiagsToConsole('IHImageViewer: sending Get Tools action...');        
		$A.enqueueAction(act);

	},


})