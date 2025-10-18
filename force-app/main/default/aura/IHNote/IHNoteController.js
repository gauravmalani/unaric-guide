({
    
    // Get or create the sticky note for this context
    doneRendering : function (cmp, evt, helper) {
        
        if (cmp.get('v.isInitialised') === true) {
            return;
        }
        
        helper.showSpinner(cmp);
        
        // Get or create the sticky record
        var act = cmp.get("c.getTools");
        
        act.setParams({ 
            "ToolContext" : "NewSticky", 
            "ActionCode" : "NewSticky",
            "IHContext" : cmp.get("v.recordId"),
            "ClientComponentId" : cmp.get("v.ComponentId"),
            "Params" : "",
            "SkipGlobals" : false,
        });               

        cmp.set("v.ActionCode", "NewSticky");
            
        act.setCallback(helper, function (response, cmp){
        
            helper.processTools(response, cmp);
            
            // The sticky will have come to us as a "personalisation" record (being an interaction - see processTools)
            var i;
            var Ps = cmp.get("v.PersonalisationSettings");
            
            for (i=0; i<Ps.length; i++) {
                if (Ps[i].iahelp__HelpInteractionType__c == 'Sticky') {
                    cmp.set("v.CurrentRecord", Ps[i]);
                    break;
                }
            }
            
            // Internationalise any sticky title that's been supplied
            cmp.set("v.StickyTitle", helper.Internationalise(cmp, cmp.get("v.StickyTitle")));
        });                
        
		$A.enqueueAction(act);
        cmp.set('v.isInitialised', true);
        
    },


    // Mark current record as edited
    setDirty : function (cmp, event, helper) {
        cmp.set('v.isDirty', true);
    },


    // Respond to record selected event from control to which we're listening
    selectRecord : function (cmp, event, helper) {
        
        var theRecord = event.getParam("RecordId");
               
        // Only respond to events that emanate from the  "desired" master(s) we wish to tie to
        if (helper.eventBeingListenedTo(cmp, event) == true) {

            // In these cases, we're changing topic (server call)
            // so show our "waiting" cues and allow update...
            cmp.set("v.recordId", theRecord);
            cmp.set("v.isInitialised", false);            
        }
    },
    
    
    // Save sticky as requested and close sticky "dialogue"
    handlePassThroughs : function (cmp, event, helper) {

        var act = event.getParam("ActionCode");

        // Only respond to our own events
        if (helper.eventIsOurOwn(cmp, event)) {

	        if (act === 'NewStickySave') {
	                    
	            // Save the sticky - if changes have been made
	            if (cmp.get("v.isDirty") == true) {
	                
	                
	
	            /*    var actS = cmp.get("c.logLUXInteraction");
	                actS.setParams({ 
	                    "iTyp" : "12",
	                    "Description" : cmp.get("v.CurrentRecord.iahelp__Description__c"),
	                    "IHContext" : cmp.get("v.recordId")
	                });    */                   
	    
	            /*    actS.setCallback(helper, function (response, cmp) {
	                    cmp.set('v.Diags', helper.Internationalise(cmp, response.getReturnValue()));
	                    cmp.set('v.isDirty', false);
	                    
	                    // Raise a separate event requesting notes list refresh
			            var appEvent = $A.get("e.c:evtPassThrough");
			            appEvent.setParams({"SourceComponent": cmp.get("v.ComponentId")});
			            appEvent.setParams({"ActionCode": "RefreshCurrentList"});
			            appEvent.setParams({"Parameters": ""});
			            
			            appEvent.fire();
	                    
	                });  */
	                    
	    			//$A.enqueueAction(actS);

                       // We could amend the existing sticky - but let's try just
	                // logging a new interaction - effectively giving us "version control" over our stickies                    
                    	helper.logLUXInteractions(cmp, 12, cmp.get("v.CurrentRecord.iahelp__Description__c"), cmp.get("v.recordId")).then((response) => {
			            cmp.set('v.Diags', helper.Internationalise(cmp, response.getReturnValue()));
	                    cmp.set('v.isDirty', false);
	                    
	                    // Raise a separate event requesting notes list refresh
			            var appEvent = $A.get("e.c:evtPassThrough");
			            appEvent.setParams({"SourceComponent": cmp.get("v.ComponentId")});
			            appEvent.setParams({"ActionCode": "RefreshCurrentList"});
			            appEvent.setParams({"Parameters": ""});
			            
			            appEvent.fire();
	                    
	                });

					
	            }
	    
	
	            // Request that we be "closed"
	            var appEvent = $A.get("e.c:evtPassThrough");
	            appEvent.setParams({"SourceComponent": cmp.get("v.ComponentId")});
	            appEvent.setParams({"ActionCode": "DialogueRequestClose"});
	            appEvent.setParams({"Parameters": "QAMStickyContainer"});
	            
	            appEvent.fire();
	        }
        }
    },
    

})