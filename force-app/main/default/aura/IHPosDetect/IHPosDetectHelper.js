({
    
    
    // Issue a message to cue contextual help in listening components
    cueContextHelp: function (cmp, event, helper) {
        var eventTracker = cmp.find("eventTracker");
        // Get the summary by passing msg parameter
        var summary;
        
        var def = cmp.get("v.HelpRecordId");
        // Check for author overrides (specifying the help to show) 
        // before issuing message to cue context help
        var CmpId;
        if (cmp.get("v.PositioningRole") == 'Help Cue') {
            CmpId = cmp.get("v.PositioningGroup");
        } else {
            CmpId = cmp.get("v.ComponentId");
        }
        
        
        var act = cmp.get("c.getAuthorConfig");
        act.setParams({
            "ComponentId": CmpId,
        });
        
        console.log('Position detector "' + CmpId + '": checking Author Configurations...');
        
        act.setCallback(this, function (response, cmp) {
            
            // Set help topic if we see this in the author configuration data returned:
            // This should be in the form:
            // HelpRecordId~TopicID
            
            try {
                var retVal = response.getReturnValue();
                var D1 = '~';
                var ToolsDiv = cmp.find("PDToolsContainer");
                
                if (retVal != '') {
                    console.log('Position detector "' + CmpId + '": Author Configuration exists - processing...');
                    
                    
                    // In the Component Generator role, author override should be a complete component definition string
                    if (cmp.get("v.PositioningRole") == 'Component Generator') {
                        def = retVal;
                        
                    } else {
                        
                        // If we find an override in other PD roles, this will include the desired help topic, which we must extract
                        retVal = retVal.split(D1);
                        if (retVal[0] == 'HelpRecordId') {
                            cmp.set("v.HelpRecordId", retVal[1]);
                        }
                    }
                    
                    
                    // Add a class marking the fact that author overrides are in play - 
                    // but only for authors +
                    
                    if (cmp.get("v.isAuthor") == true) {
                        cmp.set("v.HasAuthorOverridesClass", "HasAuthorOverrides");
                        ToolsDiv = ToolsDiv.getElement();
                        $A.util.addClass(ToolsDiv, cmp.get("v.HasAuthorOverridesClass"));
                    }
                    
                    
                } else {
                    console.log('Position detector "' + CmpId + '": NO Author Configurations');
                }
                
                
                // In the Component Generator role, this means spin up a component
                if (cmp.get("v.PositioningRole") == 'Component Generator') {
                    
                    var CG = cmp.getSuper().find("theCG");
                    
                    if (CG.get("v.ComponentDef") == '') {
                        
                        // To avoid issues with header sizing (which is normally set to zero height to avoid positioning issues
                        // with hep buttons etc) we need to set an additional class on our generated component to add to its
                        // outer container: this re-sets height
                        
                        def = this.classAdjustDefinition(cmp, def);
                        
                        CG.set("v.ComponentDef", def);
                    } else {
                        CG.set("v.ComponentDef", '');
                    }
                    
                    // Initialise the component generator to 'view' mode (as opposed to edit component definition editing mode)
                    CG.set("v.ToToggle", false);
                    CG.reInitialise();
                    
                    return;
                }
                
            } catch (e) { }
            
            
            // With overridden topic (aka Help Context) set if required, issue a message to actually cue help
            if (cmp.get("v.HelpRecordId") != '') {
                
                var appEvent = $A.get("e.c:selectTopic");
                appEvent.setParams({ "RecordId": cmp.get("v.HelpRecordId") });
                appEvent.setParams({ "SourceComponent": CmpId });
                appEvent.fire();
                
                // 1.52+ Only raise an event if we have a context record, but do not make
                // the logging of a PD context log contingent on this (no such record is 
                // required in order to record the fact that a user visited a tab etc)
            }
            
            console.log('Position detector "' + cmp.get("v.PositioningGroup") + '" log interaction = ' + cmp.get("v.LogContextInteraction"));
            
            // Log a context interaction, if requested
            if (cmp.get("v.LogContextInteraction") == true) {
                
                // Ensure we do this only once
                if (cmp.get("v.ContextInteractionLogged") == false) {
                    
                    cmp.set("v.ContextInteractionLogged", true);
                    
                    //act = cmp.get("c.logLUXInteraction");
                    
                    var D1 = '^';
                    var msg = eventTracker.generateSummaryDescription(summary)+D1+ CmpId;
                    
                    //console.log("Generated Summary in cuecontext:", summary);
                    //var msg = cmp.get("v.HelpRecordId") + D1 + CmpId;
                    
                    
                    // Only do this if we have a worthwhile context to track
                    var cxt = cmp.get("v.recordId");
                    
                    if (cxt + '' == 'null') {
                        cxt = '';
                    }
                    
                    // Do not log interactions in page edit / design mode:
                    // See also init function for derivation of this logic:
                    var c = cmp.find("thePosDiv");
                    if ($A.util.hasClass(c, 'designTime')) {
                        return;
                    }
                    
                    console.log('Position Detector "' + cmp.get("v.PositioningGroup") + '" - Logging Context Interaction from Cue Context Help (context: ' + cxt + ')');
                    
                    //   act.setParams({ 
                    // "iTyp" : "19",
                    // "Description" : msg,
                    // "IHContext" : cxt
                    //   });                       
                    
                    // Send action
                    // $A.enqueueAction(act);
                    helper.logLUXInteractions(cmp, 19, msg, cxt).then((response) => {
                        //do nothing to response.
                    })
                }
            }
            
        });
        $A.enqueueAction(act);
        
    },
    
    
    // Ensure any component definitions we generate include settings which undo zeroing of
    // header height by adding a specialist class to the outer DIV of the component (which can
    // be added to any Card implementation via its 'OuterContainerClass' member)
    classAdjustDefinition: function (cmp, def) {
        
        var retVal;
        
        try {
            if (def.indexOf('OuterContainerClass') == -1) {
                var CG = cmp.getSuper().find("theCG");
                var Delimiter = CG.get("v.MyDelimiter");
                var D3 = Delimiter.substring(2, 3); // For separation of Attribute name and it's value
                var D4 = Delimiter.substring(3, 4); // For separation of one Attribute name value from another
                
                retVal = def + D4 + 'OuterContainerClass' + D3 + 'PDCGRole';
                
            } else {
                retVal = def;
            }
            
        } catch (e) {
            retVal = def;
        }
        
        return retVal;
        
    },
    
    
    // Returns true if the element (elem) passed in is "visible" - not necessarily within the viewport
    isVisible: function (cmp, event, elem) {
        
        var ID = cmp.get("v.PositioningGroup");
        
        try {
            return elem.getElement().offsetWidth != 0 && elem.getElement().offsetHeight != 0;
            
        } catch (e) {
            return false;
        }
        
    },
    
    
    //Allow CG to override default set toolcontext and actioncode by IHCard,
    // otherwise the position Detector will not initialise.
    initialisepd: function(cmp, event, helper){
        var PositioningRole;
        var cxt;
        var SkipGlobals = cmp.get("v.SkipGlobals");
        
        PositioningRole = cmp.get('v.PositioningRole');
        
        switch(PositioningRole){
            case "Component Generator":
                if (cmp.get('v.ToolContext') == 'QAM') {
                    cmp.set('v.ToolContext', 'PositionDetectorCG');
                }
                cmp.set("v.ActionCode", 'CueContextHelp');
                if(PositioningRole = 'Component Generator'){
                    cmp.set('v.ToolContext', 'PositionDetectorCG');
                }
                cxt = cmp.get('v.recordId');
                if (cxt + '' == 'null' || cxt + '' == 'undefined') {	
                    cxt = helper.getPageContextIdentifier(cmp);
                }
                break;
                
            case "Help Button":
                if (cmp.get('v.ToolContext') == 'QAM') {
                    cmp.set('v.ToolContext', 'PositionDetectorHelpButtons');
                }
                cmp.set("v.ActionCode", 'CueContextHelp');
                if(PositioningRole = 'Help Button'){
                    cmp.set('v.ToolContext', 'PositionDetectorHelpButtons');
                }
                cxt = cmp.get('v.recordId');
                if (cxt + '' == 'null' || cxt + '' == 'undefined') {	
                    cxt = helper.getPageContextIdentifier(cmp);
                }
                break;   
                
            case "Help Request":
                if (cmp.get('v.ToolContext') == 'QAM') {
                    cmp.set('v.ToolContext', 'PositionDetectorHelpRequests');
                }
                cmp.set("v.ActionCode", 'HelpRequest');
                if(PositioningRole = 'Help Request'){
                    cmp.set('v.ToolContext', 'PositionDetectorHelpRequests');
                }
                cxt = cmp.get('v.recordId');
                if (cxt + '' == 'null' || cxt + '' == 'undefined') {	
                    cxt = helper.getPageContextIdentifier(cmp);
                }
                break;       
                
        }
    },
    
    
    
})