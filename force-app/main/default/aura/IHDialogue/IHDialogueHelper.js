({ 
    
    // Waiting cues for dialogue
    hideDlgSpinner : function (cmp, helper) {
        var tBusy = cmp.find('IHDlgPending');
        var frm = cmp.find(helper.getContentFrame(cmp));

        $A.util.removeClass(tBusy, 'IHTipPending');
        $A.util.removeClass(frm, 'slds-hide');
    },
    showDlgSpinner : function (cmp, helper) {
        var tBusy = cmp.find('IHDlgPending');
        var frm = cmp.find(helper.getContentFrame(cmp));

        $A.util.addClass(tBusy, 'IHTipPending');
        $A.util.addClass(frm, 'slds-hide');
    },
    
    
    // Identify the component element to show (iframe or sub-component div) based on component settings
    getContentFrame : function(cmp) {
        if (cmp.get("v.FrameType") == 'VF') {
            return 'dfrm';
        } else {
            return 'ddiv';
        }
    },
    

    // For LUX dialogues, re-build the desired component, based on attribute member data supplied
    initialiseLUXDialogue : function (cmp) {
    
        this.hideDlgSpinner(cmp, this);

        console.log('Initialise LUX Dialogue: LUX component requested: ' + cmp.get("v.FrameSource"));

        // Default to header on for most types...
        cmp.set("v.ShowHeader", true);
        

        if (cmp.get("v.FrameType") === 'LUX') {                
            $A.createComponent(
                cmp.get("v.FrameSource"),
                cmp.get("v.FrameAttributes"),

                function (newComp, status, err) {
                    if(status === "SUCCESS") {

                        var dv = cmp.get('v.body');        
                        
                    	console.log('Initialise LUX Dialogue: replacing body of ' + dv.length + ' components, the first of which is: ' + dv[0]);
                    	dv = [];
                    	
						// Set a property on newly generated component that can be used (where attribute exists - i.e., card implementations only)
						// to discern that it is in a dialogue (by way of being able to examine parent's attributes - e.g., Parent.LargeMode = true)
						newComp.set("v.Parent", cmp);                    	
                	
                    	
                        dv.push(newComp);
                        cmp.set('v.body', dv);
                    	cmp.set('v.Diags', '');
                    	console.log('Initialise LUX Dialogue: reset body now has ' + dv.length + ' components, the first of which is: ' + dv[0]);

                        // Keep a record of the created component                            
                    	cmp.set("v.theLUXComp", newComp);

                        
                        // Raise an event to advise that component has been generated
			            var appEvent = $A.get("e.c:evtPassThrough");
			            appEvent.setParams({"SourceComponent": cmp.get("v.ComponentId"), "ActionCode": "ComponentToolsProcessed", "Parameters": newComp});
			            appEvent.fire();                            

                    } else {
                        cmp.set('v.Diags', err);
                    }
                }
            );
            
        } else {
            if(cmp.get("v.FrameType") === 'Alert'){
                
                var cnt = cmp.find('IHAlertCompContainer');
                var amap = cmp.get("v.FrameAttributes");
                var comp = cmp.find('IHAlertComp');

                // Obtain dialogue attributes from supplied map and set
                comp.set("v.Height", amap.Height);
                comp.set("v.Title", amap.Title);
                comp.set("v.Message", amap.Message);
                comp.set("v.Image", amap.Image);
                comp.set("v.ToolContext", amap.ToolContext);
                comp.set("v.Style", amap.Style); 
                
                // This is set for closing Dialogue
                comp.set("v.ComponentId", amap.ComponentId);
                
                // Hide Header for Alert dialogues
                cmp.set("v.ShowHeader",false);
                
                // Show the dialogue (un-hide its container)
                $A.util.removeClass(cnt, 'slds-hide');
                comp.reInitialiseAlert();
            }
        }
    
    },    

})