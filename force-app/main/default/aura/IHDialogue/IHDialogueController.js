({  
    
    // Force re-building of component when desired (delegated to helper)
	reInitialise : function (cmp, evt, helper) {
        console.log(' reInitialise ');
		helper.initialiseLUXDialogue (cmp);
       
	},

    
    // Generate a request to be closed by our owner using the pass through event
    requestClose : function (cmp, evt, helper) {
        
        var dlgCmp = cmp.get("v.theLUXComp");
        var appEvent = $A.get("e.c:evtPassThrough");

        // Re-show busy cues as we close...
    	cmp.set("v.FrameSource", "");
        helper.showDlgSpinner(cmp, helper);

        appEvent.setParams({"SourceComponent": cmp.get("v.ComponentId")});
        appEvent.setParams({"ActionCode": "DialogueRequestClose"});
        appEvent.setParams({"Parameters": 'ModalContainer'});

		try {
			appEvent.fire();
		
		} catch (e) {
			alert(e);        
		}

        // "Re-set" component by destroying any dynamically added component
        if (dlgCmp != null) {
        	cmp.set("v.theLUXComp", null);
        }
        cmp.set("v.FrameType","Closed");
    },
    
    
    // Show / hide spinner as required when showing callouts
    hideDlgSpinner : function (cmp, event, helper) {
    	if (cmp.get("v.FrameSource") != "") {
	    	helper.hideDlgSpinner(cmp, helper);
    	}
    },
    
    
    // Negotiate footer tools with any instantiated LUX component
    handlePassThroughs : function (cmp, event, helper) {

        var act = event.getParam("ActionCode");
        var src = event.getParam("SourceComponent");
        var evtCmp = event.getParam("Parameters");
        var dlgCmp = cmp.get("v.theLUXComp");
        
        if (act === 'ComponentToolsProcessed') {
            if (dlgCmp != null) {
                if (dlgCmp === evtCmp) {
                    // If the component that has its tools is the one
                    // we created for our dialogue, use its footer tools
                    dlgCmp.set("v.FooterTools", evtCmp.get("v.FooterTools"));
                }
            }
        }
        
        
        // Respond in these cases only:
        // [1] where child component is known and 
        // [2] pass through comes from that (our) child
        
		if (dlgCmp != null) {
			if (src === dlgCmp.get("v.ComponentId")) {
		 
				// Image viewer modal overall width
				if (act === 'ModalDialogueWide') {
					cmp.set("v.LargeMode", true);			
				}
		
				if (act === 'ModalDialogueNarrow') {
					cmp.set("v.LargeMode", false);			
				}
			}
		}  
        
    },
    
})