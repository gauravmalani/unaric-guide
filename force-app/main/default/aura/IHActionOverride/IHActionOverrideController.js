({  

	    // Build the component that is to be shown in our dialogue instance (usually, an auto form)
    doDialogue : function (cmp, event, helper) {
        
        console.log('Inside ddlg');
        var dlg = cmp.find('theModal');		// The modal component - which may be part of the component passed (if the card) or its supercomponent 
        var act = cmp.get("c.getGlobals");
        var rec = cmp.get("v.recordId");
        var src;
        var aMap;
        var keyTypes;
        var isRL = false;
        var RLCode = '---';		// Object code for a reading list - defaulted to something that will 'fail' until we learn the correct value
        
        
        // We make a call to get global settings to obtain object code information...
        act.setCallback(this, function (response, cmp) {
            
            // Get details of key, known record types:
            // We're not a 'card' and don't have access to one - so we need to do
            // our own tool processing here...
            
            if (response.getState() === "SUCCESS") {
                
                var obj;
                var i;
                
                // Return value is JSON - parse this into objects for aura iteration...
                try {
                    obj = JSON.parse(response.getReturnValue());
                    
                    // We may have been returned zero or more tools and zero or more listing records.
                    // If there are >1 total items, we have a collection to iterate. 
                    // If there are 0 items, we've nothing to do.
                    // If there is exactly 1 item (could be a tool or a listing record), we need
                    // to load this into an array in order for the loop that follows to work...
                    if ('' + obj.length === 'undefined') {
                        obj = new Array(obj);
                    }		            
                    
                    for (i = 0; i<obj.length; i++) {
                        
                        // Process tools: these are true sObjects, so will have attributes including type          
                        try {
                            if (obj[i].attributes.type === 'iahelp__IASetIHOrg__c') {
                                // Global settings: set some key values:
                                keyTypes = obj[i].iahelp__SFObjectIds__c;	
                                keyTypes = keyTypes.split('^');
                                RLCode = keyTypes[1];
                            }
                        } catch (e) {}
                        
                    }
                    
                } catch (e) {
                    console.log('IH Action Override - Error processing the following globals return value (' + e + '): ' + response.getReturnValue());
                }
                
            }	// End if Globals call response successful
            
            
            // Component to spin up varies according to the record type in play:
            // Default to autoform - unless we can see that it's a reading list we've been asked to feature
            if (rec != null && rec + '' != 'null' && rec != undefined && rec + '' != 'undefined') {
                if (rec.length > 2) {
                    if (rec.substring(0,3) == RLCode) {
                        isRL = true;
                    }
                }
            }else {
                // No recordId (probably New mode), fallback to sObjectName check
                if (cmp.get("v.sObjectName") === 'iahelp__HelpReadingList__c') {
                    isRL = true;
                }
            }
            if (isRL) {
                // Determine mode (view or edit) from URL
                var currentUrl = window.location.href.toLowerCase();
                var isEditMode = currentUrl.includes('/edit');
                var isViewMode = currentUrl.includes('/view');
                var isNewMode = currentUrl.includes('/new');
                
                if (isEditMode) {
                    // Editing a reading list → with reading list root
                    var src = 'c:IHUtility1';
                    var aMap = {
                        "SuppressHeaders": false,
                        "SuppressFooters": true,
                        "HelpRecordId" : cmp.get("v.recordId"),   // use the new RL Id
                        "DataMode": "Edit",
                        "TreeSuppressListingTools": false,
                        "Height": 520,
                        "ComponentId": "theModalCmpContent",
                        "Parent": cmp,
                        "ColumnRatio": "33%",
                        "RootNode": cmp.get("v.recordId"),
                        "ToolContext": "ReadingListBuilder",
                        "TreeNodeIconStyle": "Small",
                        "MaxListingTools": -1,
                        "ExpandAllNodes": true
                    };
                } else if (isViewMode) {
                    // Viewing a reading list → Use RL Viewer
                    src = "c:IHRLViewer";
                    aMap = {
                        "ComponentId": "theModalCmpContent",
                        "Height": -2,
                        "SuppressHeader": true,
                        "SuppressFooter": true,
                        "HelpRecordId": cmp.get("v.recordId")
                    };
                }
                    else if (isNewMode) {
                        var actRL = cmp.get("c.addStandaloneReadingList");
                        actRL.setCallback(this, function (response) {
                            if (response.getState() === "SUCCESS") {
                                var RLID = response.getReturnValue();
                                if (RLID && RLID.toLowerCase().indexOf('error') === -1) {
                                    // Open new Reading List directly in RL Viewer, in Edit mode
                                    var src = 'c:IHUtility1';
                                     var aMap = {
                                        "SuppressHeaders": false,
                                        "SuppressFooters": true,
                                        "HelpRecordId" : RLID,   // use the new RL Id
                                        "DataMode": "Edit",
                                        "TreeSuppressListingTools": false,
                                        "Height": 520,
                                        "ComponentId": "theModalCmpContent",
                                        "Parent": cmp,
                                        "ColumnRatio": "33%",
                                        "RootNode": RLID,
                                        "ToolContext": "ReadingListBuilder",
                                        "TreeNodeIconStyle": "Small",
                                        "MaxListingTools": -1
                                    };
                                    
                                    // Now configure the modal
                                    dlg.set("v.FrameSource", src);
                                    dlg.set("v.FrameType", 'LUX');
                                    dlg.set("v.FrameAttributes", aMap);
                                    dlg.set("v.FrameHeight", -1);
                                    dlg.set("v.AllowScroll", true);
                                    dlg.set("v.LargeMode", true);
                                    dlg.set("v.ShowFooter", false);
                                    
                                    dlg.reInitialise();
                                } else {
                                    console.error("Error creating standalone Reading List: " + RLID);
                                }
                            } else {
                                console.error("addStandaloneReadingList failed: " + response.getError());
                            }
                        });
                        $A.enqueueAction(actRL);
                        return; // stop further dlg.set() from overriding
                    }
                
                
                        else {
                            // Fallback if mode can't be determined — treat as view
                            src = "c:IHRLViewer";
                            aMap = {
                                "ComponentId": "theModalCmpContent",
                                "Height": -2,
                                "SuppressHeader": true,
                                "SuppressFooter": true,
                                "HelpRecordId": cmp.get("v.recordId")
                            };
                        }
            } else {
                // Autoform for all other cases
                src = 'c:IHAutoForm';
                aMap = {
                    "ComponentId": "theModalCmpContent",
                    "Height": -1,
                    "SuppressHeader": false,
                    "SuppressFooter": true,
                    "SuppressModeTools": cmp.get("v.SuppressModeTools"),
                    "CalloutOption": "Topic Selected Event plus Topic view",
                    "OnSaveAction": "Navigate to record",
                    "sObjectName": cmp.get("v.sObjectName"),
                    "recordId": cmp.get("v.recordId"),
                    "DataMode": "Edit"
                };
            }
            
            
            // Set remaining dialogue attributes
            dlg.set("v.FrameSource", src);
            dlg.set("v.FrameType", 'LUX');
            dlg.set("v.FrameAttributes", aMap);
            dlg.set("v.FrameHeight", -1);				
            dlg.set("v.AllowScroll", true);
            dlg.set("v.LargeMode", true);
            dlg.set("v.ShowFooter", false);
            
            // Clear the "latch" on our dialogue component so it will re-initialise itself
            dlg.reInitialise();      
            
        });
        $A.enqueueAction(act);	
        
    },

    // Handle clicks on "our" local tools
    toolClick : function (cmp, event, helper) {
    	
    	// For consistency, re-raise as pass throughs...
    	try {
			var theId = event.currentTarget.id;
			var incomingId = theId;
			var D1 = cmp.get("v.Delimiter");
			theId = theId.split(D1);
    	
            var appEvent = $A.get("e.c:evtPassThrough");
            appEvent.setParams({"SourceComponent": "IHModal"});
            appEvent.setParams({"ActionCode": theId[1]});
            appEvent.setParams({"Parameters": incomingId});
            appEvent.fire();
            

            // Also, provide tool toggling if required...
	        if (theId[3] != '0') {
	        
	            // We need to hide the clicked item and un-hide its "next"
	        	var c1id = '' + D1 + theId[0] + D1 + theId[2] + D1 + '';
	            var c1 = document.getElementById(c1id);
	
	        	var c2id = '' + D1 + theId[0] + D1 + theId[3] + D1 + '';
	            var c2 = document.getElementById(c2id);

	            $A.util.removeClass(c1, 'fa-stack');
	            $A.util.addClass(c1, 'slds-hide');
	            $A.util.addClass(c2, 'fa-stack');
	            $A.util.removeClass(c2, 'slds-hide');
	        }            
                    
    	} catch (e) {
    		alert('Error (Tool Click): ' + e);    	
    	}                   
    },
    
    
    // Handle passthroughs - such as component processed / ready for use
    handlePassThroughs : function (cmp, event, helper) {
    	
        var act = event.getParam("ActionCode");
        var parms = event.getParam("Parameters");
        var src = event.getParam("SourceComponent");
        var dlg = cmp.find('theModal');
        var LUXC = dlg.get("v.theLUXComp");

        try {
        
	        // Set dialogue title to that of generated component plus note extension tools
	        if (act == 'ComponentToolsProcessed' && src == LUXC.get("v.ComponentId")) {        
	        	dlg.set("v.Title", decodeURI(LUXC.get("v.Title")));    
	        	dlg.set("v.TipButtonClose", LUXC.get("v.TipButtonClose"));
	        	cmp.set("v.ExtensionTools", LUXC.get("v.ExtensionTools"));	        	
	        	cmp.set("v.Delimiter", LUXC.get("v.Delimiter"));
	        }
	        
	        // Show / hide dialogue's LUX component's header area	        
	        if (act == 'AFToggleHeader') {
	        	// Toggle component's header
	        	LUXC.set("v.SuppressHeader", ! LUXC.get("v.SuppressHeader"));
	        	
	        	// Toggle DIALOGUE header to the opposite
	        	dlg.set("v.ShowHeader", LUXC.get("v.SuppressHeader"));
	        		        	
	        }
	        
	        // Handle close requests from MODAL ITSELF - not it's generated component!
	        if (act == 'DialogueRequestClose' && src == dlg.get("v.ComponentId")) {
	        
	        	if (LUXC.get("v.IHCardType") == "AutoForm") {
	        
		        	// This is passed through to our autoform
		        	LUXC.doCancel();
	        	}

				// In all cases, the override component itself needs to be hidden
				var ActOContainer = cmp.find("OvrContainer");
				var ActOTools = cmp.find("OvrTools");
				
				$A.util.addClass(ActOContainer, 'slds-hide');
				$A.util.addClass(ActOTools, 'slds-hide');
	        		        	
	        }
	        
        } catch (e) {}
    },

})