({
    
    // For design time only, give this component a visual element
    // Also, initialise certain other parameters
    Init: function (cmp, event, helper) {
        
        var c = cmp.find("thePosDiv");
        try {
            console.log('Position Detector "' + cmp.get("v.PositioningGroup") + '" Initialising at: ' + window.location.pathname);
            if (window.location.pathname.indexOf('/appBuilder.app') != -1
                || window.location.pathname.indexOf('/commeditor.jsp') != -1
                || window.location.pathname.indexOf('/flexipageEditor/') != -1) {
                $A.util.addClass(c, 'designTime');
            }
        } catch (e) {
            console.log('Position Detector Initialise - error: ' + e);
        }
        
        
        // Deal with cases where our role may have been passed in via URL such that it may have been necessary
        // to supply parameters without spaces
        if (cmp.get("v.PositioningRole") == 'HelpCue') { cmp.set("v.PositioningRole", 'Help Cue'); }
        if (cmp.get("v.PositioningRole") == 'HelpButton') { cmp.set("v.PositioningRole", 'Help Button'); }
        if (cmp.get("v.PositioningRole") == 'HelpRequest') { cmp.set("v.PositioningRole", 'Help Request'); }
        if (cmp.get("v.PositioningRole") == 'ComponentGenerator') { cmp.set("v.PositioningRole", 'Component Generator'); }
        
        
        console.log('Position Detector Initialising: text = "' + cmp.get("v.HelpButtonText") + '"');
        console.log('Position Detector Initialising: size = "' + cmp.get("v.HelpButtonTextSize") + '"');
        console.log('Position Detector Initialising: role = "' + cmp.get("v.PositioningRole") + '"');
        
        
        // Button text
        var Txt = cmp.get("v.HelpButtonText");
        if (Txt == null || Txt + '' == 'undefined') {
            Txt = '';
        }
        Txt = helper.getSafeHTML(Txt);
        cmp.set("v.HelpButtonTx", Txt);
        
        
        // Button style (positioning)
        switch (cmp.get("v.HelpButtonPosition")) {
            case 'Left':
                cmp.set("v.HelpButtonStyle", 'ToolButtonLeft');
                break;
                
            case 'Right':
                cmp.set("v.HelpButtonStyle", 'ToolButtonRight');
                break;
                
            case 'Above Left':
                cmp.set("v.HelpButtonStyle", 'ToolButtonAboveLeft');
                break;
                
            case 'Above Right':
                cmp.set("v.HelpButtonStyle", 'ToolButtonAboveRight');
                break;
                
            case 'Inline':
                cmp.set("v.HelpButtonStyle", 'ToolButtonInline');
                cmp.set("v.Height", -1);
                break;
                
            default:
                cmp.set("v.HelpButtonStyle", 'ToolButtonRight');
                break;
        }
        
        
        // Button text font size
        switch (cmp.get("v.HelpButtonTextSize")) {
            case 'Small':
                cmp.set("v.HelpButtonTextSz", 0.8);
                break;
                
            case 'Medium':
                cmp.set("v.HelpButtonTextSz", 1.2);
                break;
                
            case 'Large':
                cmp.set("v.HelpButtonTextSz", 1.5);
                break;
                
            default:
                cmp.set("v.HelpButtonTextSz", 0.8);
                break;
        }
        
        
        // Button text wrap behaviour
        switch (cmp.get("v.HelpButtonTextStyle")) {
            case 'Ellipsis':
                cmp.set("v.HelpButtonTextSt", 'ToolButtonTextEllipsis');
                break;
                
            case 'Wrap fixed width':
                cmp.set("v.HelpButtonTextSt", 'ToolButtonTextWrapSetWidth');
                break;
                
            case 'Wrap 100%':
                cmp.set("v.HelpButtonTextSt", 'ToolButtonTextWrap');
                break;
                
            default:
                cmp.set("v.HelpButtonTextSt", 'ToolButtonTextEllipsis');
                break;
        }
        
        
        // Background style
        if (cmp.get("v.BackgroundStyle") == 'Transparent') {
            cmp.set("v.ToolsContainerStyle", 'ToolsContainerTransparent');
        } else {
            cmp.set("v.ToolsContainerStyle", 'ToolsContainerColoured');
        }
        
        helper.initialisepd(cmp, event, helper);
        
        //We have to obtain global settings before attempting log
        // position detector context logs with geolocation data. Otherwise Geo data will not be logged.
        
        var action = cmp.get("c.getTools");
        action.setParams({ 
            "ToolContext": cmp.get("v.ToolContext"),
            "ActionCode": cmp.get("v.ActionCode"),
            "IHContext": cmp.get("v.recordId"),
            "ClientComponentId": cmp.get("v.ComponentId"),
            "Params": cmp.get("v.HelpRecordId"),
            "SkipGlobals": cmp.get("v.SkipGlobals") 
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                console.log('Result_Pos_Detector ', response.getReturnValue());
                helper.processTools(response, cmp);
            } else if (state === "ERROR") {
                let errors = response.getError();
                console.error('Apex Error: ', errors);
            }
        }); 
        
        $A.enqueueAction(action);
        
    },
    
    
    
    // Set key attributes, obtain Configuration tools, setup context monitoring if required, cue help context where role requires
    doneRendering: function (cmp, event, helper) {
        // Set tools area width
        var globalId = cmp.getGlobalId();
        var x = document.getElementById(globalId + 'PosDiv');
        var y = document.getElementById(globalId + 'SelectorTools');
        var eventTracker = cmp.find("eventTracker");
        // Get the summary by passing msg parameter
        var summary;
        
        
        // If we're a help cue, trigger when our element's visibility changes
        if (cmp.get("v.PositioningRole") == 'Help Cue') {
            
            if (helper.isVisible(cmp, event, cmp.find('vizCheck'))) {
                
                // If we're visible at this stage, cue trigger (set to not initialised) BUT
                // only if we haven't already done so since we last became visible			
                if (cmp.get("v.HelpCueIssued") == false) {
                    
                    // Record the fact we've noted visibility then cue re-initialisation
                    cmp.set("v.HelpCueIssued", true);
                    cmp.set("v.isInitialised", false);
                }
                
            } else {
                cmp.set("v.HelpCueIssued", false);
            }
            
        }
        
        
        // Actions to take only once per initialisation run...
        if (cmp.get("v.isInitialised") == false) {
            
            // Immediately avoid repeat calls - unless we're still initialising
            
            /*
			FLOWS ISSUE:
			Log Interaction is FALSE despite being set true
			Role is UNSET despite being set to Help Cue
			Setting both values at this break point results in interaction
			*/
            
            if (cmp.get("v.PositioningRole") != 'Unset') {
                cmp.set("v.isInitialised", true);
            } else {
                console.log('Position detector "' + cmp.get("v.PositioningGroup") + '" still initialising - bailing from render code...');
                return;
            }
            
           console.log('Setting new interval with duration:', cmp.get("v.ContextCheckInterval"));
            // Setup context checking timer, if required 
            if (cmp.get("v.ContextCheckInterval") > 0) {
                
                // Only set a timer if one has not already been created
                if (cmp.get("v.ContextCheckTimer") == 0) {
                   console.log('ContextCheckTimer before:', cmp.get("v.ContextCheckTimer"));
                    
                    
                    cmp.set("v.ContextCheckTimer", window.setInterval($A.getCallback(function () {
                        
                        try {
                           console.log('ContextCheckTimer after:', cmp.get("v.ContextCheckTimer"));
                            var i = cmp.get("v.Counter");
                            var U = window.location.pathname+window.location.search;
                            var cxt;
                            var appEvent;
                            var act;
                            
                            if (U != cmp.get("v.LastURL")) {
                                
                                // Page address has changed: issue contextualisation message
                                // and log interactions as may be required
                                
                                cxt = cmp.get("v.recordId");
                                console.log('cxt'+cxt);
                                if (cxt + '' == 'null') {
                                    cxt = helper.getPageContextIdentifier(cmp);
                                }
                                
                                console.log('Position Detector "' + cmp.get("v.PositioningGroup") + '" URL change from: ' + cmp.get("v.LastURL") + ' to: ' + U);
                                
                                // Only issue a context change message if the actual, derived context (as opposed to the URL) has changed
                                if (cxt != cmp.get("v.LastContext")) {
                                    
                                    // Issue context change passthrough
                                    console.log('Position Detector "' + cmp.get("v.PositioningGroup") + '" derived context changed from: ' + cmp.get("v.LastContext") + ' to: ' + cxt + '. Issuing change passthrough...');
                                    
                                    appEvent = $A.get("e.c:evtPassThrough");
                                    appEvent.setParams({ "SourceComponent": cmp.get("v.PositioningGroup") });
                                    appEvent.setParams({ "ActionCode": "ContextChange" });
                                    appEvent.setParams({ "Parameters": cxt });
                                    appEvent.fire();
                                    
                                    
                                    // Log a context change interaction if design parameters specify this
                                    if (cmp.get("v.LogContextInteraction") == true) {
                                        
                                        //act = cmp.get("c.logLUXInteraction");
                                        
                                        // Do not log interactions in page edit / design mode:
                                        // See also init function for derivation of this logic:
                                        var c = cmp.find("thePosDiv");
                                        if ($A.util.hasClass(c, 'designTime')) {
                                            return;
                                        }
                                        
                                        var D1 = '^';
                                        //After logging a new interaction upon URL change, 
                                        //calls resetEvents on the LWC, clearing previous page's data.  
                                        if (eventTracker) {
                                            eventTracker.resetEvents();
                                        }
                                        // var msg = cmp.get("v.HelpRecordId") + D1 + cmp.get("v.PositioningGroup");
                                        var msg = eventTracker.generateSummaryDescription(summary) + D1 + cmp.get("v.PositioningGroup");
                                        
                                      //  console.log("Generated Summary in donerendering:", summary);
                                        
                                        /*act.setParams({ 
										"iTyp" : "19",
										"Description" : msg,
										"IHContext" : cxt
										});*/
                                        //act.setCallback(this, function(response) {
                                        //var state = response.getState();
                                        
                                        //Calling logLUXInteractions function in IHCard component(Because it extends IHCard) to log HelpInteraction record along with geoLocations.
                                        helper.logLUXInteractions(cmp, "19", msg, cxt).then((response) => {
                                            
                                            
                                            try {
                                            var state = response.getState();
                                            console.log('PosDetectComponent ', response.getReturnValue());
                                            if (state === "SUCCESS") {
                                            //Returning the last log record Id.
                                            let lastHelpInteractionRecId = response.getReturnValue().split('__');
                                            cmp.set("v.LastSavesHelpInteractionId", lastHelpInteractionRecId[1]);
                                            console.log('Call to LogLUXinteraction successfully returns ', lastHelpInteractionRecId[1]);
                                        }
                                                                                            
                                                                                            } catch (e) {
                                            console.log('ERROR ', e);
                                        }
                                    });
                                    // });
                                    
                                    // Send action
                                    //$A.enqueueAction(act);
                                    
                                }
                                
                                cmp.set("v.LastContext", cxt);
                                i = 0;
                            }
                            //In specific senario If you try to change the List view filter the URL get change but the 
                            //context of the URL will not change, Thus to log an interaction in that case we are call LogLUXInteractionas in else part.    
                            else{
                                // Log a context change interaction if design parameters specify this
                                if (cmp.get("v.LogContextInteraction") == true) {
                                    
                                    // Do not log interactions in page edit / design mode:
                                    // See also init function for derivation of this logic:
                                    var c = cmp.find("thePosDiv");
                                    if ($A.util.hasClass(c, 'designTime')) {
                                        return;
                                    }
                                    var D1 = '^';
                                    // var msg = cmp.get("v.HelpRecordId") + D1 + cmp.get("v.PositioningGroup");
                                    
                                    var msg = eventTracker.generateSummaryDescription(summary) + D1 + cmp.get("v.PositioningGroup");
                                    
                                    console.log("Generated Summary in done rendering:", JSON.stringify(summary));
                                    
                                    helper.logLUXInteractions(cmp, "19", msg, cxt).then((response) => {
                                        
                                        try {
                                        var state = response.getState();
                                        console.log('PosDetectComponent ', response.getReturnValue());
                                        if (state === "SUCCESS") {
                                        //Returning the last log record Id.
                                        let lastHelpInteractionRecId = response.getReturnValue().split('__');
                                        cmp.set("v.LastSavesHelpInteractionId", lastHelpInteractionRecId[1]);
                                        console.log('Call to LogLUXinteraction successfully returns ', lastHelpInteractionRecId[1]);
                                    }
                                                                                        } catch (e) {
                                        console.log('ERROR ', e);
                                    }
                                });
                            }
                        } 
                        
                    } else {
                                                                                     //If the Url has not changed we need to update the amount of time spent on the page.
                                                                                     
                                                                                     //if design parameters specify this and PositioningRole is Help Cue. 
                                                                                     if (cmp.get("v.LastSavesHelpInteractionId") != '' && cmp.get("v.LogContextInteraction") == true && cmp.get("v.PositioningRole") == 'Help Cue') {
                            var lastinteractionRecId = cmp.get("v.LastSavesHelpInteractionId");
                    
                    // Generate the latest summary from EventTracker
                    var msg = eventTracker.generateSummaryDescription(summary);
                    //console.log("Generated Summary in donerendering:", summary);
                    
                    // Update the HelpInteraction record with new summary
                    var action = cmp.get("c.updateInteractionDescription");
                    action.setParams({
                        "interactionId": lastinteractionRecId,
                        "newDescription": msg
                    });
                    
                    action.setCallback(this, function(response) {
                        var state = response.getState();
                        if (state === "SUCCESS") {
                           // console.log('Successfully updated interaction description for record:', lastinteractionRecId);
                        } else if (state === "ERROR") {
                            var errors = response.getError();
                            console.error('Error updating interaction:', errors);
                        }
                    });
                    
                    $A.enqueueAction(action);
                    
                    // commenting the code because logging it via updateInteractionDescription 
                    // to update help interaction record with departure date and description field
                    /*
                    var act = cmp.get("c.logLUXDepartureTime");
                    act.setParams({
                        "LogInteractionId": lastinteractionRecId,
                    });
                    act.setCallback(this, function (response) {
                        var state = response.getState();
                        if (state === "SUCCESS") {
                        } else {
                            console.log('ERROR ', state);
                        }
                    });
                    $A.enqueueAction(act);
                    */
                }
                
                i += 1;
            }
            
            cmp.set("v.LastURL", U);
            cmp.set("v.Counter", i);
            
        } catch (e) {
            // On failure, advise of error, clear the timer but do NOT re-set 
            // our timer member data, as we don't want to re-launch it if there's been any issue
            console.log('Position Detector context check error: ' + e);
            window.clearInterval(cmp.get("v.ContextCheckTimer"));
        }
        
    }), cmp.get("v.ContextCheckInterval")));
    
}
 } 		// End if Context check interval > 0
 
 
 
 
 // Action to take depends on role
 if (cmp.get("v.PositioningRole") == 'Help Cue') {
    
    // For automatic help cueing, issue a message to say that context has changed
    helper.cueContextHelp(cmp, event, helper);
    
} else {
    // For help cueing via button, or plain position detection:				
    // Component ID cannot be set directly - it is a function of our grouping and role
    if (cmp.get("v.PositioningRole") == 'Help Button') {
        cmp.set('v.ToolContext', 'PositionDetectorHelpButtons');
        cmp.set("v.ComponentId", cmp.get("v.PositioningGroup"));
        
        // For help requests: set Tool context           
    } else if (cmp.get("v.PositioningRole") == 'Help Request') {
        cmp.set('v.ToolContext', 'PositionDetectorHelpRequests');
        cmp.set("v.ComponentId", cmp.get("v.PositioningGroup"));
        
        // Buttons required for component generation
    } else if (cmp.get("v.PositioningRole") == 'Component Generator') {
        cmp.set('v.ToolContext', 'PositionDetectorCG');
        cmp.set("v.ComponentId", cmp.get("v.PositioningGroup"));
        
    } else {
        cmp.set('v.ToolContext', 'PositionDetector');
        cmp.set("v.ComponentId", cmp.get("v.PositioningGroup") + '.' + cmp.get("v.PositioningRole"));
    }
    
    // Obtain supporting configuration tools where required		         
    if (cmp.get("v.PositioningRole") == 'Help Button' || cmp.get("v.PositioningRole") == 'Help Request' || cmp.get("v.PositioningRole") == 'Component Generator') {
        var act = cmp.get("c.getTools");
        act.setParams({
            "ToolContext": cmp.get('v.ToolContext'),
            "ActionCode": cmp.get('v.ActionCode'),
            "ClientComponentId": cmp.get("v.ComponentId"),
            "SkipGlobals": false,
        });
        
        
        // Create a callback that is executed after the server-side action returns
        act.setCallback(helper, function (response, cmp) {
            helper.processTools(response, cmp);
        });
        
        $A.enqueueAction(act);
    }
}

}
},
    
    
    // Change handler for context cueing: issue context (delegated to helper) on change of record ID if in help cue mode
    cueContextHelp: function (cmp, event, helper) {
        if (cmp.get("v.PositioningRole") == 'Help Cue') {
            helper.cueContextHelp(cmp, event,helper);
        }
    },
        
        
        // Issue a message requesting that a guide prompt be supplied when in GE mode
        requestGuidePrompt: function (cmp, event, helper) {
            
            var appEvent = $A.get("e.c:evtPassThrough");
            appEvent.setParams({ "SourceComponent": cmp.get("v.PositioningGroup") });
            appEvent.setParams({ "ActionCode": 'RequestGuidePrompt' });
            appEvent.setParams({ "Parameters": null });
            appEvent.fire();
            
        },
            
            
            // Handle requests to provide position related services
            handlePassThroughs: function (cmp, event, helper) {
                
                var act = event.getParam("ActionCode");
                var parms = event.getParam("Parameters");
                var src = event.getParam("SourceComponent");
                var CG = cmp.getSuper().find("theCG");			// Our card's component generator implementation
                var GEDiv = cmp.find("theGEDiv");				// Div on this implementation offering visible sign we are in guide enable mode 
                
                
                // For some events, respond only to our own messages
                if (helper.eventIsOurOwn(cmp, event)) {
                    
                    
                    // In CG role, enter design mode
                    if (act == 'DesignModeOn') {
                        var CG = cmp.getSuper().find("theCG")
                        CG.set("v.ToToggle", !CG.get("v.ToToggle"));
                        
                        if (CG.get("v.ToToggle") == false) {
                            
                            var def = CG.get("v.ComponentDef");
                            def = helper.classAdjustDefinition(cmp, def);
                            CG.set("v.ComponentDef", def);
                            
                            CG.reInitialise();
                        }
                    }
                    
                    
                    // Cause contextual help to be cued in listening components
                    if (act === 'CueContextHelp') {
                        helper.cueContextHelp(cmp, event, helper);
                    }
                    
                    
                    // Log interaction for Help Request role.
                    if (act == 'HelpRequest') {
                        
                        // var HLog = cmp.get("c.logLUXInteraction");
                        
                        // Set context to record ID if present, page path if not
                        var cxt = cmp.get("v.recordId") + '';
                        if (cxt == 'null') {
                            cxt = document.location.pathname;
                        }
                        
                        // HLog.setParams({
                        // 	"iTyp": 25,
                        // 	"Description": cmp.get("v.PositioningGroup"),
                        // 	"IHContext": cxt,
                        
                        // });
                        // HLog.setCallback(this, function (response) {
                        
                        helper.logLUXInteractions(cmp, 25, cmp.get("v.PositioningGroup"), cxt).then((response) => {
                            var state = response.getState();
                            if (state === "SUCCESS") {
                            try {
                            console.log('IH Position Detector - Help Request call response: ', response.getReturnValue());
                            alert(helper.Internationalise(cmp, 'MessageRequestLogged'));
                        } catch (e) {
                            console.log('ERROR ', e);
                        }
                    }
                });
                
                // var state = response.getState();
                // if (state === "SUCCESS") {
                // console.log('IH Position Detector - Help Request call response: ', response.getReturnValue());
                
                // Would be good to use our 'branded' dialogue here - as seen on completing a Guide ('you have completed the steps in this guide' message).
                // However, seems not to work here: can we try to investigate why not?
                
                // alert(helper.Internationalise(cmp, 'MessageRequestLogged'));
                
                // Card - IHCard suppressUI is true, that's why we are not able to access Modal Container	                    
                /*
				var src = 'c:IHAlert';
				var aMap = {
					"Height": -1,   
					"Title" : helper.Internationalise(cmp, 'MessageRequestLogged'),
					"Message" : cmp.get("v.TipButtonClose"),
					"Image" : "/resource/iahelp__IHSupportMaterials/img/StockImages/009C.svg", 
					"ToolContext" : "AlertOKOnly",
					"Style" : "Two Column",
						"ComponentId" : cmp.get("v.ComponentId")
					};
				
				helper.doDialogue('ttl', 'Alert', src, aMap, -1, false, false, false, cmp, false); 
				*/
                
                // }
                // });
                // $A.enqueueAction(HLog);
            }

}


// For some events, respond only if we're listening
if (helper.eventBeingListenedTo(cmp, event)) {
    
    if (act == 'CueGuideStep') {
        
        // Show a guide step, using parameters we are given to build a prompt:				
        // Get the identifier of the element for which a guide prompt is required
        var GuidedElement = parms;
        GuidedElement = GuidedElement.split('~');	// Split off component namespace
        GuidedElement = GuidedElement[1];
        GuidedElement = GuidedElement.split('|');	// Split into component parameters
        GuidedElement = GuidedElement[0];
        GuidedElement = GuidedElement.split('¬');	// Get value of the first of these
        GuidedElement = GuidedElement[1];
        GuidedElement = GuidedElement.replace('_GuidePromptCtl', '');
        
        // Respond only if the message is for us (we are the guided element) - not some other position detector 
        // also listening to the same source.
        if (GuidedElement == cmp.get("v.PositioningGroup")) {
            
            console.log('Position Detector "' + cmp.get("v.PositioningGroup") + '" - Cue Guide Step');
            
            // Use our card's component generator to build a prompt:
            // Only re-set this to new prompt values if we don't currently
            // have a definition: if we'e already worked on this step in guide enable mode,
            // the definition will have been retained and we should simply un-hide what was built previously...
            
            if (CG.get("v.ComponentDef") == '') {
                CG.set("v.ComponentDef", parms);
                CG.reInitialise();
            }
            $A.util.removeClass(CG, 'slds-hide');
            
            
            // If we're in guide enable mode, add guided class to highlight our involvement
            if (cmp.get("v.OpMode") == 'GuideEnable') {
                $A.util.addClass(GEDiv, 'ToBeGuided');
            }
            
            // If we're in a utility bar, pop it open
            try {
                var utilityAPI = cmp.find("UtilityBar");
                if (utilityAPI + '' != 'undefined') {
                    utilityAPI.openUtility();
                }
            } catch (e) { }
            
            // Scroll prompt (the div containing the component generator, in turn forming the prompt) into view
            try {
                var P = cmp.getSuper().find("CGContainer");
                $(document).scrollTop(P.getElement().offsetTop);
            } catch (e) { }
            
            
        } else {
            // If some other element is being asked to show a prompt, we
            // should destroy ours - unless we're in guide enable mode,
            // in which case we want to hide but keep the current prompt's state...
            
            if (cmp.get("v.OpMode") != 'GuideEnable') {
                CG.set("v.ComponentDef", '');
            } else {
                $A.util.addClass(CG, 'slds-hide');
            }
        }
    }
    
    
    if (act == 'GEModeEntry') {
        
        // As we're listening to the control creating the guide, we need to enter our own 'guide enable' mode
        cmp.set("v.OpMode", 'GuideEnable');
        cmp.set("v.Height", 33);
        
        // Unhide our guide enable clickable: no 'guided' styling at this stage
        $A.util.removeClass(GEDiv, 'slds-hide');
        $A.util.removeClass(GEDiv, 'ToBeGuided');
        
        
        // In addition, we should advise the creating control of our presence - so we can be logged as an available guide element...
        var appEvent = $A.get("e.c:evtPassThrough");
        appEvent.setParams({ "SourceComponent": cmp.get("v.PositioningGroup") });
        appEvent.setParams({ "ActionCode": 'LogAvailableGuideElement' });
        appEvent.setParams({ "Parameters": CG });
        appEvent.fire();
        
    }
    
    if (act == 'MarkGuideStep') {
        
        // Advice that a particular non-autoform element is a part of the selected guide in guide enable mode:
        // Respond only if the message is for us (we are the guided element) - not some other position detector 
        // also listening to the same source.
        // When steps are marked, we know the item identifier involved, so that is supplied as the parameter
        if (parms == cmp.get("v.PositioningGroup")) {
            $A.util.addClass(GEDiv, 'ToBeGuided');
        }
    }
    
    if (act == 'UnMarkGuideStep') {
        
        // Advice that a particular non-autoform element is NO LONGER part of the selected guide in guide enable mode:
        // Respond only if the message is for us (we are the guided element) - not some other position detector 
        // also listening to the same source.
        // When steps are UN marked, we cannot be sure we know about the underlying prompt, so rely on comparison of 
        // the component generator itself
        if (parms == CG) {
            $A.util.removeClass(GEDiv, 'ToBeGuided');
            
            // This means we should hide any guide prompt in use
            $A.util.addClass(CG, 'slds-hide');
        }
    }
    
    
    if (act == 'AFModeView') {
        
        // Exit 'guide enable' mode and return to view mode
        cmp.set("v.OpMode", 'View');
        cmp.set("v.Height", 0);
        $A.util.addClass(GEDiv, 'slds-hide');
        $A.util.removeClass(GEDiv, 'ToBeGuided');
        
        // This means we should destroy any guide prompt in use
        try {
            CG.set("v.ComponentDef", '');
            CG.reInitialise();
        } catch (e) { }
        
    }
}


// Respond to any guide prompts we may have created
if ((act == 'DialogueRequestClose' || act == 'NavToGuideStep' || act == 'CloseGuide') && src.indexOf('_GuidePromptCtl') != -1) {
    
    // The NavToGuideStep action is a request issued by a prompt to show another item:
    // This may ultimately result in a CueGuideStep message from the component running the guide, but 
    // at this stage it just means close the current guide prompt - if the nav message came from ourselves...
    if (act == 'NavToGuideStep') {
        if (src.replace('_GuidePromptCtl', '') != cmp.get("v.PositioningGroup")) {
            // If NavToGuideStep message was not issued by us, take no action
            return;
        }
    }
    
    // Close if any prompt closure requests are issued - or a navigate step command is issued:
    // In the latter case, a subsequent cue guide step will arise to which we will respond if it's for us...
    // Setting our component generator to blank definition has the effect of 'closing' any prompt it created...
    try {
        CG.set("v.ComponentDef", '');
    } catch (e) { }
    
    
    // If we're in a utility bar, close it
    try {
        var utilityAPI = cmp.find("UtilityBar");
        if (utilityAPI + '' != 'undefined') {
            utilityAPI.minimizeUtility();
        }
    } catch (e) { }
    
}

},
    
    
    
    
})