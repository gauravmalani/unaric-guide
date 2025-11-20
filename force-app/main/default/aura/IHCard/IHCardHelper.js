({

    //DRAGGABLE TESTS - DISABLED AS AT 1.55
    /*
    setupJQUI : function (cmp, event, helper) {
	
        try {
            var DDGridX = 50;
            var DDGridY = 20;
        	
	
                $('.DragMe').draggable({
                    grid: [DDGridX, DDGridY],
                	
                    start: function(event, ui) {
                        console.log('Drag start logged via CARD');
                    	
                        // Log draggable's original co-ordinates
                        console.log('X:' + ui.originalPosition.left + ' Y:' + ui.originalPosition.top);    			
                        cmp.set("v.DraggedItemOriginalPosition", ui.originalPosition);
                    }
            });    
	
          
            $('.DragMe').addClass('Ready');
            	
                $('.DropTarget').droppable({
                    drop: function( event, ui ) {
                        var parms; 
                        var src;
                    	
                            // ui = draggable object
                            // ui.draggable = target dragged object
                            // event.target = drop event
                        	
                            parms = ui;  //.draggable[0].getAttribute('data-id');
                            src = event.target.getAttribute("data-DropType")
                    	
                                var appEvent = $A.get("e.c:evtPassThrough");
                                appEvent.setParams({"SourceComponent": src});
                                appEvent.setParams({"ActionCode": 'DDrop'});
                                appEvent.setParams({"Parameters": parms});
                                appEvent.fire();
                    	
                    }
                });	  
            	
                console.log('setupJQUI - done');
    	
        } catch (e) {
            console.log('setupJQUI - ERROR: ' + e);
        }
    	
    },
    */


    // Move an element (e.g., a reading list viewer's navigation lozenges) from their 
    // original location (e.g., somewhere within the card implementation mark up) to
    // parent card's body tools area
    appendBodyTools: function (cmp, helper, elem) {

        var GID = cmp.getGlobalId();
        var newParent = document.getElementById(GID + 'microTools');

        elem.parentNode.removeChild(elem);
        newParent.appendChild(elem);

    },


    // Check for presence of utility bar and adjust certain settings dependent on this
    initialiseUB: function (cmp, event, helper) {

        console.log(cmp.get("v.ComponentId") + ': Initialising Utility Bar integration');

        try {
            var utilityAPI = cmp.find("UtilityBar");

            if (utilityAPI + '' != 'undefined') {
                utilityAPI.getAllUtilityInfo().then(function (response) {
                    if (response && response.length > 0) {
                        console.log(cmp.get("v.ComponentId") + ': Utility Bar is present');

                        cmp.set('v.hasUtilityBar', true);
                        cmp.set("v.H_UtilityBar", 2.5 * parseFloat(getComputedStyle(document.documentElement).fontSize));

                    } else {
                        console.log(cmp.get("v.ComponentId") + ': Utility Bar NOT present');

                        cmp.set('v.hasUtilityBar', false);
                        cmp.set("v.H_UtilityBar", 0);
                    }
                });

            } else {
                console.log(cmp.get("v.ComponentId") + ': Utility Bar API unavailable');

                cmp.set('v.hasUtilityBar', false);
                cmp.set("v.H_UtilityBar", 0);
            }

        } catch (e) {
            cmp.set('v.hasUtilityBar', false);
            cmp.set("v.H_UtilityBar", 0);
        }
    },


    // Initiate periodic component element sizing / height calculation checks, returning timer reference
    // NB: this code will run at least once on load - see Init
    setSizingTimer: function (cmp, event, helper) {

        return window.setInterval($A.getCallback(function () {

            /*
            A timer is required to obtain correct header / body tools / footer sizing if:
            Header is visible and height obtained when last examined was zero OR
            Footer is visible and height obtained when last examined was zero OR
            Body tools exist and height obtained when last examined was zero
            */
            try {

                // Note existence of visible body tools
                var BTs = cmp.get("v.BodyTools");
                var BTCount = 0;
                try {
                    BTCount = BTs.length;
                } catch (e) { }

                if (BTCount > 0 && cmp.get("v.SuppressBodyTools") == false) {
                    cmp.set("v.HasVisibleBodyTools", true);
                }


                if ((cmp.get("v.SuppressHeader") == false && cmp.get("v.H_Header") == 0)
                    || (cmp.get("v.SuppressFooter") == false && cmp.get("v.H_Footer") == 0)
                    || (cmp.get("v.SuppressBodyTools") == false && cmp.get("v.H_BodyTools") == 0 && BTCount > 0)) {

                    // Timed check is still required
                    var H = cmp.find("IHCardHeader").getElement();
                    var F = cmp.find("IHCardFooter").getElement();


                    cmp.set("v.H_Header", H.offsetHeight);
                    cmp.set("v.H_Footer", F.offsetHeight);

                    // Body tools requires slightly different handling as its DIV may not be rendered at all
                    if (cmp.get("v.SuppressBodyTools") == false) {

                        var B = cmp.find("IHBodyTools").getElement();
                        cmp.set("v.H_BodyTools", B.offsetHeight);

                    }

                } else {
                    // Header / footer sizes are set: retain timer only if Viewport height was requested,
                    // as this requires ongoing response to window re-sizing etc.
                    if (cmp.get("v.ViewportHeightRequested") == false && cmp.get("v.Height") != -2) {

                        window.clearInterval(cmp.get("v.SizingTimer"));
                        cmp.set("v.SizingTimer", 0);
                    }
                }

                // Check / calculate VP responsive height at least once...
                helper.setHeightToVP(cmp);
            } catch (e) {
                //console.log('Card - Sizing timer - error: ' + e);
            }

        }), 500);

    },


    // Hide product strapline as and when required
    hidePoweredBy: function (cmp) {
        // Hide powered by logo...
        var PB = cmp.find("PoweredBy");
        if (PB + '' != 'undefined') {
            try {
                $A.util.removeClass(PB.getElement(), "IHCardFooterLogoExpanded");
            } catch (e) { }
        }
    },


    // Report the overall height of this component in pixels via a platform event
    reportRenderedHeight: function (cmp, event, helper) {

        // Only fire this event once per component impression / when latch is set
        if (cmp.get("v.RenderedHeightReported") == false) {

            try {
                // NB: for now we are publishing this via platform event only - as 
                // the immediate reason for broadcast is for sizing of aura lightning template components
                // being consumed by LWC via component generator iframe...
                var compH;
                var comp = cmp.find("IHCardOutermostReachable").getElement();
                compH = Math.ceil(comp.getBoundingClientRect().height);

                var message = { ActionCode: 'RenderedHeight', Parameters: compH, SourceComponent: cmp.get("v.ComponentId") };
                message = JSON.stringify(message);


                //cmp.find("geoLocation").getCurrentLocation().then((location) => {
                // alert('position IN Aura latitude ' + location.latitude + '  ' + 'position IN Aura longitude ' + location.longitude + '  ' + 'position IN Aura altitude ' + location.altitude + '  ' + 'position IN Aura accuracy ' + location.accuracy);
                //console.log('position IN Aura latitude ', location.latitude);
                //console.log('position IN Aura longitude ', location.longitude);
                //console.log('position IN Aura altitude ', location.altitude);
                //console.log('position IN Aura accuracy ', location.accuracy);

                //For passing the location coordinates through the pre defined "logLUXInteraction" perameters
                //I am adding the coordinates in key value format to the end of the "IHContext" with a
                //delimeter 'String.fromCharCode(7)'{A unprintable delemeter} which will be then split out when
                //pass to the server method to take out the coordinates and the remaining string will be
                //work as it is previously functioning.

                //var D7 = String.fromCharCode(7);
                //var position = { "latitude": location.latitude, "longitude": location.longitude, "altitude": location.altitude, "accuracy": location.accuracy };

                helper.logLUXInteractions(cmp, 0, message, cmp.get("v.UniqueIdent")).then((response) => {
                    //Do nothing
                });
                /*var act = cmp.get("c.logLUXInteraction");

                act.setParams({
                    "iTyp": "0",
                    "Description": message,
                    "IHContext": cmp.get("v.UniqueIdent") + D7 + JSON.stringify(position)
                });

                act.setCallback(this, function (response, cmp) {
                    if (response.getState() === 'SUCCESS') {
                        // Do nothing if OK
                        console.log('"' + cmp.get("v.ComponentId") + '" Broadcasting VP height (' + compH + ') - Platform event raised');
                    } else {
                        console.log('"' + cmp.get("v.ComponentId") + '" Broadcasting VP height (' + compH + ') - Platform event ERROR');
                    }
                });

                // Send action
                $A.enqueueAction(act);*/
                //});

                //   var act = cmp.get("c.logLUXInteraction");

                //   act.setParams({ 
                //       "iTyp" : "0",
                //       "Description" : message,
                //       "IHContext" : cmp.get("v.UniqueIdent")
                //   });                               

                //   act.setCallback(this, function (response, cmp){ 
                // 	if (response.getState() === 'SUCCESS') {
                // 		// Do nothing if OK
                // 		console.log('"' + cmp.get("v.ComponentId") + '" Broadcasting VP height (' + compH + ') - Platform event raised');
                // 	} else {
                // 		console.log('"' + cmp.get("v.ComponentId") + '" Broadcasting VP height (' + compH + ') - Platform event ERROR');
                // 	}
                // });

                //   // Send action
                //   $A.enqueueAction(act);


            } catch (ex) { }
        }

    },


    // Intercept special sizing instructions: -2 can be used to set size to available screen height
    setHeightToVP: function (cmp) {

        try {

            if (cmp.get("v.Height") == -2) {
                // If viewport height requested, note this
                cmp.set("v.ViewportHeightRequested", true);
            }


            if (cmp.get("v.ViewportHeightRequested") == true) {

                var H_Calc = 400;
                var H_Padding = 3;
                var H_UBar = cmp.get("v.H_UtilityBar");

                try {
                    var comp = cmp.find("IHCardOutermostReachable").getElement();
                    H_Calc = window.innerHeight - comp.getBoundingClientRect().top - H_Padding - H_UBar;

                    // Adjust for rebranding / footer border
                    var H_Brand = 10;
                    H_Calc -= H_Brand;

                } catch (ex) {
                    // Disable log for now - too 'busy' in the console...
                    //console.log('Card - set viewport height - error getting outer container: ' + ex);
                }

                // Only set height if page scroll is at top - otherwise card will 'grow'
                // as we scroll down				
                if ($(document).scrollTop() == 0) {
                    cmp.set("v.Height", H_Calc);
                }

            }

        } catch (e) {
            console.log('Card - set viewport height - error: ' + e);
        }
    },


    // Show / hide drop down menu
    toggleDropDownTools: function (cmp) {
        var ctl = cmp.find('toolsDropDown');
        $A.util.toggleClass(ctl, 'slds-dropdown');
        $A.util.toggleClass(ctl, 'slds-hide');
    },


    // Expand / collapse an accordion section
    toggleAccordion: function (cmp, clickedId) {

        var sect = cmp.find(clickedId.replace('_Summary', '_Section'));
        var twst = cmp.find(clickedId.replace('_Summary', '_Twisty'));
        var opt = clickedId.replace('_Summary', '');

        $A.util.toggleClass(sect, 'slds-is-open');
        $A.util.toggleClass(twst, 'nodeExpanded');

        return opt;

    },


    // Show / Hide the history navigation area
    toggleHistory: function (cmp, event, helper) {
        var HC = cmp.find("HistoryContainer");
        $A.util.toggleClass(HC, 'slds-hide');
    },


    // Toggle visibility of listing / node tools collapsed to ellipsis
    toggleListingTools: function (cmp, listingId) {

        var blocks;
        var LItems = document.querySelectorAll("div[class*='ListingToolsBlock_']");
        for (var i = 0; i < LItems.length; i++) {

            if (!$A.util.hasClass(LItems[i], 'ListingToolsBlock_' + listingId)) {
                $A.util.addClass(LItems[i], 'slds-hide');
            }
        }

        // TOGGLE the tool area representing the clicked tool ellipsis
        LItems = document.querySelectorAll('div.ListingToolsBlock_' + listingId);

        for (var i = 0; i < LItems.length; i++) {
            $A.util.toggleClass(LItems[i], 'slds-hide');
        }


        // For the expanded tools area, show its ellipsis button as "in use"
        LItems = document.querySelectorAll("span[class*='ListingToolsBlockMaster_']");
        for (var i = 0; i < LItems.length; i++) {
            $A.util.removeClass(LItems[i], 'Inactive');
            $A.util.removeClass(LItems[i], 'Dark');
        }

        LItems = document.querySelectorAll('div.ListingToolsBlock_' + listingId);
        blocks = document.querySelectorAll('span.ListingToolsBlockMaster_' + listingId);

        for (var i = 0; i < LItems.length; i++) {
            for (var j = 0; j < blocks.length; j++) {
                if ($A.util.hasClass(LItems[i], 'slds-hide')) {
                    $A.util.removeClass(blocks[j], 'Inactive');
                    $A.util.removeClass(blocks[j], 'Dark');
                } else {
                    $A.util.addClass(blocks[j], 'Inactive');
                    $A.util.addClass(blocks[j], 'Dark');
                }
            }
        }


    },


    // Waiting cues for card as a whole   
    showSpinner: function (cmp) {
        cmp.set('v.Diags', cmp.get('v.AdviceLabelWorking'));

        // Mark-up logic reflects this setting by showing / hiding spinner
        cmp.set("v.isBusy", true);
    },
    hideSpinner: function (cmp) {
        cmp.set("v.isBusy", false);
    },

    // Waiting cues for callouts
    toggleTipBusy: function (cmp) {

        var globalId = cmp.getGlobalId();
        var tBusy = document.getElementById(globalId + 'IHTipPending');
        var cnt = document.getElementById(globalId + 'CalloutContainer');
        var frm = document.getElementById(globalId + 'tfrm');

        if ($A.util.hasClass(cnt, 'slds-hide')) {
            $A.util.addClass(tBusy, 'IHTipPending');
            $A.util.addClass(frm, 'slds-hide');

        } else {
            $A.util.removeClass(tBusy, 'IHTipPending');
            $A.util.removeClass(frm, 'slds-hide');
        }

    },


    // Clear advanced diagnostics messages
    clearAdvancedDiags: function (cmp) {
        cmp.set("v.AdvancedDiags", '');
    },


    // Log a diagnostics message in our advanced diags 
    logAdvancedDiags: function (cmp, Msg) {

        var D = cmp.get("v.AdvancedDiags");

        var dt = new Date();
        var H = dt.getHours();
        var M = dt.getMinutes();
        var S = dt.getSeconds();

        if (H < 10) { H = '0' + H; }
        if (M < 10) { M = '0' + M; }
        if (S < 10) { S = '0' + S; }

        // Limit the amount of text in the console as 
        // all will be available in diags div if required...
        if (Msg.length > 500) {
            console.log(H + ':' + M + ':' + S + ' - ' + Msg.substr(0, 500) + ' [truncated]');
        } else {
            console.log(H + ':' + M + ':' + S + ' - ' + Msg);
        }

        D += '... ' + H + ':' + M + ':' + S + ' - ' + Msg;
        cmp.set("v.AdvancedDiags", D);

    },


    // Log a diagnostics message with timestamp to console 
    logDiagsToConsole: function (Msg) {

        var dt = new Date();
        var H = dt.getHours();
        var M = dt.getMinutes();
        var S = dt.getSeconds();

        if (H < 10) { H = '0' + H; }
        if (M < 10) { M = '0' + M; }
        if (S < 10) { S = '0' + S; }

        Msg = H + ':' + M + ':' + S + ' - ' + Msg;
        console.log(Msg);

    },


    // Handle interactions with menus etc:
    // This is a callback for the"getTools" Apex controller function, processing returned
    // JSON into JS arrays that can be iterated by components to produce menus, listings and their tools

    // Pass SkipGlobals = true to avoid processing readily cached data, such as internationalisations, which can
    // be obtained via a (cacheable) call to getGlobals, so improving performance    
    processTools: function (response, cmp, SkipGlobals) {

        var state = response.getState();
        var strDiags = '';
		    console.log("Response State:", state);
    console.log("Full Response Object:", response);
        // Remove waiting cues
        this.hideSpinner(cmp);


        if (state === "SUCCESS") {

            var toolsE = [];            // Ellipsis tools
            var toolsD = [];            // Drop down tools
            var toolsH = [];            // Header tools
            var HSCs = [];              // Header tool support controls
            var toolsB = [];			// Body tools
            var toolsF = [];            // Footer tools
            var toolsL = [];            // Listing tools
            var toolsW = [];            // Wizard steps
            var toolsWB = [];           // Wizard step body tools
            var toolsX = [];            // Extension tools
            var TAM;					// The 'active' marker for a toggling tool
            var D1 = '|';				// Delimiters encountered in the same
            var D2 = '¬';				// Delimiters encountered in the same
            var VOs = [];				// Vote Options
            var listItems = [];         // Listing records
            var GS;                     // A global settings object
            var PS = [];                // Personalisation settings
            var XtnCaps = [];			// Info about extended capabilities (e.g., supported operations for trees)
            var intl = [];				// Internationalisations
            var cfgFilterInfo = [];		// Configuration item tool filter support info
            var recordMeta;             // Details of data state for the current row of data
            var customFs = [];          // Details of any custom fields
            var passThroughs = [];		// Other records for inheriting components
            var ttl = '';				// Card title returned from server logic, if supplied

            var minform = 1;			// The specified minimum form factor for an individual configuration tool
            var device = cmp.get("v.BrowserFormFactor");	// User's device 'size' (See Init)
            var formfactorvalue = 0; 	// The form factor (S/M/L size) derivedd from the user's device                                                        

            var i;
            var hasAttributes = false;
            var obj;

            // Derive form factor numeric value from user's device
            formfactorvalue = cmp.get('v.FormFactorVal');

            // In all cases, keep the raw return value in case we need the diagnostics
            var strDiags = 'IHCardHelper.processTools : entry... - - - - - - COMPONENT PARAMETERS: - - - ';
            strDiags += 'ComponentId=' + cmp.get('v.ComponentId') + ': ';
            strDiags += 'ActionCode=' + cmp.get('v.ActionCode') + ': ';
            strDiags += 'ToolContext=' + cmp.get('v.ToolContext') + ': ';
            strDiags += 'IHContext=' + cmp.get('v.IHContext');
            strDiags += ' - - - - - - RETURN VALUE: - - - ';
            strDiags += response.getReturnValue();
            this.clearAdvancedDiags(cmp);
            this.logAdvancedDiags(cmp, strDiags);
            strDiags = '';

            // Return value is JSON - parse this into objects for aura iteration...
            try {
                obj = JSON.parse(response.getReturnValue());
            } catch (e) {
                cmp.set("v.Diags", "IHCardHelper - processTools - Error parsing the following return value (" + e + "): " + response.getReturnValue());
                return false;
            }


            // We may have been returned zero or more tools and zero or more listing records.
            // If there are >1 total items, we have a collection to iterate. 
            // If there are 0 items, we've nothing to do.
            // If there is exactly 1 item (could be a tool or a listing record), we need
            // to load this into an array in order for the loop that follows to work...
            if ('' + obj.length === 'undefined') {
                obj = new Array(obj);
            }


            for (i = 0; i < obj.length; i++) {

                // Process tools: these are true sObjects, so will have attributes including type          
                try {
                    var s = obj[i].attributes.type;
                    hasAttributes = true;
                } catch (e) {
                    hasAttributes = false;
                }

                if (hasAttributes === true) {

                    if (obj[i].attributes.type === 'iahelp__ConfigurationItem__c') {

                        // Added as part of Mobile enhancement:
                        // Only add tools that are suited to the user's device (i.e., where their
                        // screen form factor is at least as large as that specified for the clickable)

                        minform = parseInt(obj[i].iahelp__MinimumFormFactor__c, 10);

                        // We need to allow for tools whose minimum form factor has not been set (perhaps
                        // because they were added locally before mobile enhancements)
                        if (Number.isNaN(minform)) { minform = 1; }

                        if (formfactorvalue >= minform) {

                            // For all configuration item types, consider 'active' marker for toggling tools:
                            // Process the 'toggle active marker' and set the correct tool as the one to show on arrival.
                            TAM = obj[i].iahelp__ToggleActiveMarker__c;

                            if (TAM != '' && TAM != null) {

                                // Some active markers relate to record state (e.g., bookmarked or not): these should not be touched.
                                // Only those containing component attribute data are in play here. As with component generator instructions etc.
                                // these will be in the form:

                                // Attribute [D2] Value [D1]

                                if (TAM.indexOf(D2) != -1) {

                                    var attr;
                                    var val;
                                    var pass = true;
                                    var comp;

                                    TAM = TAM.split(D1);

                                    TAM.forEach(function (TAMClause) {
                                        console.log('IHCard: Processing Tool with Active Marker: - ' + obj[i].iahelp__Label__c + ' (' + obj[i].iahelp__ActionCode__c + ')... ');

                                        TAMClause = TAMClause.split(D2);

                                        try {
                                            // Component attribute data can be sought from current component or its parent
                                            if (TAMClause[0].startsWith('Parent.')) {
                                                comp = cmp.get("v.Parent");
                                                TAMClause[0] = TAMClause[0].substr(7);
                                            } else {
                                                comp = cmp;
                                            }

                                            if (comp.get("v." + TAMClause[0]) + '' == TAMClause[1]) {
                                                // No need to act
                                            } else {
                                                console.log('IHCard: Active Marker comparison NOT met - ' + TAMClause[0] + ' != ' + TAMClause[1] + ' (' + comp.get("v." + TAMClause[0]) + ')');

                                                pass = false;
                                            }
                                        } catch (e) {
                                            console.log('IHCard: Active Marker comparison error - ' + e);

                                            pass = false;
                                        }
                                    });


                                    // If ALL conditions of the active marker were met (above) mark this configuration
                                    // tool as a 'pass' for initial display in toggle scenarios
                                    if (pass == true) {
                                        obj[i].iahelp__ToggleActiveMarker__c = 'ComponentConditionsMatch';
                                        console.log('IHCard: Processing Tools - ' + obj[i].iahelp__Label__c + ' (' + obj[i].iahelp__ActionCode__c + ') passes active toggle');
                                    }

                                }

                            }	// End if TAM was present / process toggle active markers


                            // Add clickable to relevant collection based on type
                            switch (obj[i].iahelp__Type__c) {

                                case 'Ellipsis':
                                    toolsE.push(obj[i]);
                                    break;

                                case 'Drop-down':
                                    toolsD.push(obj[i]);
                                    break;

                                case 'Header':
                                    toolsH.push(obj[i]);

                                    // For header tools, we need to take note of supporting controls:
                                    // Each header tool record may include details of 0+ supporting controls.
                                    // If any are found, the call below marks the object we store in the supporting 
                                    // controls array with details of the header tool to which it applies.
                                    var HSCRecs = this.getSupportControlsForConfigTool(cmp, obj[i]);
                                    var j;

                                    if (HSCRecs != null) {
                                        for (j = 0; j < HSCRecs.length; j++) {
                                            HSCs.push(HSCRecs[j]);
                                        }
                                    }

                                    break;

                                case 'Body':
                                    toolsB.push(obj[i]);
                                    break;

                                case 'Footer':
                                    toolsF.push(obj[i]);
                                    break;

                                case 'Listing':
                                    toolsL.push(obj[i]);
                                    break;

                                case 'Extension':
                                    toolsX.push(obj[i]);
                                    break;

                                case 'WizardStep':
                                    toolsW.push(obj[i]);
                                    break;

                                case 'WizardStepBodyTool':
                                    toolsWB.push(obj[i]);
                                    break;


                            }		// End tool type switch                        
                        }		// End if user's screen meets minimum form factor


                    } else if (obj[i].attributes.type === 'iahelp__IASetIHOrg__c') {
                        // Global settings: set some key values:
                        GS = obj[i];

                    } else if (obj[i].attributes.type === 'iahelp__HelpInteraction__c') {
                        // These represent personalisation settings:
                        PS.push(obj[i]);

                    } else if (obj[i].attributes.type === 'iahelp__HelpVoteOption__c') {
                        // These represent vote options applicable to an individual Help Topic:
                        VOs.push(obj[i]);

                    } else {
                        // Non-config items should also be treated as data ("list" items)
                        // NOTE: a Details card / Help Topic will place a single record here:
                        listItems.push(obj[i]);
                    }

                } else {
                    // Process untyped items: these have no type as they are class instances, not sObjects
                    // Objects may be plain listings, or, if marked in a particular way, 
                    // represent other special data

                    if (obj[i].CustomField + '' != 'undefined') {
                        // Help Topic custom field information
                        customFs.push(obj[i]);

                    } else if (obj[i].ActionCode == '[RecordMetadata]') {
                        // Information about the state of the "current" record
                        recordMeta = obj[i];

                        // BRAND SUPPRESSION - as of 1.53 controlled via FEATURE MANAGEMENT	
                        // cf Controller.reportRenderedHeight  
                        // cf ControllerLUXOps NVPs					
                    } else if (obj[i].ValueSet == 'BrandingInfo') {

                        // If this config item is 'marked', suppress brand
                        if (obj[i].Name == 'BrandSuppressed') {
                            if (obj[i].Value == 'true') {
                                cmp.set("v.BrandSuppressed", true);
                            }
                        }


                    } else if (obj[i].ValueSet == 'PerformanceInfo') {
                        // Diagnostic server-side timestamps
                        console.log('---Server Side Performance Info--- ' + obj[i].Value);

                    } else if (obj[i].ValueSet == 'CardTitle') {
                        // Title, if specified in server logic: note for later use
                        ttl = obj[i].Value;

                    } else if (obj[i].ValueSet == 'AuthorOverrides') {

                        // Two sets of data are returned in this value set:
                        // [1] The fact that author overrides were applied at the server
                        // [2] The author override settings themselves

                        if (obj[i].Name == 'AuthorOverrides') {
                            // Card configuration has been impacted by author overrides and we're being informed of this - mark this fact.
                            // NB: controller returns this info for authors+ only...
                            cmp.set("v.HasAuthorOverridesClass", "HasAuthorOverrides");
                        }


                        if (obj[i].Name == 'OverrideParams') {
                            // This item represents the actual overrides settings that were obtained from config item data:
                            // This is a delimited string in the form:

                            // [Attribute 1] ~ [Value 1] ^  [Attribute 2] ~ [Value 2] ^ etc.

                            // We are able to respond to certain of these attribute settings here...

                            var cfgPs = obj[i].Value;
                            var cfgP;

                            try {
                                cfgPs = cfgPs.split('^');
                                cfgPs.forEach(function (P) {
                                    cfgP = P.split('~');

                                    if (cfgP[1].toUpperCase() == 'TRUE') { cfgP[1] = true; }
                                    if (cfgP[1].toUpperCase() == 'FALSE') { cfgP[1] = false; }

                                    // Q: How can we avoid responding to author config here in cases where we have other, 'overriding' instructions:
                                    // EG: If we've just edited a topic (so received a 'DataAmended' passthrough, we want to re-select the edited topic
                                    // - not the one specified by config!)            

                                    if (cmp.get("v.AuthorConfigLatch") == false) {

                                        // Need to filter out author configurations that are for use by position detector in component generation role:
                                        // This is because the 'instructions' in the configuration item do not amount to an attribute that can simply
                                        // be set in the way undertaken here. Attempting to set will NOT throw a trappable error here, but will cause
                                        // possible GACKs.
                                        // SO: check the format of the parameters: for CG instructions, these begin with namespace : component name
                                        // (See IHPosDetect Helper / cueContextHelp for expected format and actual processing of these overrides).

                                        if (cfgP[0].indexOf(':') == -1) {
                                            cmp.set("v." + cfgP[0], cfgP[1]);
                                        }

                                    }
                                    cmp.set("v.AuthorConfigLatch", false);

                                });

                            } catch (e) {
                                console.log('Process Tools - error setting author overrides: ' + e);
                            }
                        }

                    } else if (obj[i].ValueSet == 'CommunityRoot') {
                        // Community may be in play: note the community root
                        cmp.set("v.CommunityRoot", obj[i].Value);

                    } else if (obj[i].ValueSet == 'PortalPage') {
                        // "Home" portal page could be one of several assets - this setting tells us which
                        cmp.set("v.PortalPage", obj[i].Value);

                    } else if (obj[i].ValueSet == 'VoteInfo') {
                        // Details of last vote that was cast
                        cmp.set("v.theVote", obj[i].Value);

                    } else if (obj[i].ValueSet == 'TimesNudged') {
                        // Number of nudge interactions logged by current user from client nudge component
                        cmp.set("v.NudgesLogged", obj[i].Value);


                    } else if (obj[i].ValueSet == 'BrandCSS') {
                        // Contents of the brand CSS file (which may be at a location we cannot directly
                        // reach from LUX, so has to be brought down as a style block/text, 
                        // rather than a path to include)
                        cmp.set("v.BrandCSS", obj[i].Value);

                    } else if (obj[i].ValueSet == 'MyForm') {
                        // Fields in a user's personal form settings: 
                        // We have no direct need of these, but push them into our "pass through" data collection, 
                        // for inheritors who may...
                        passThroughs.push(obj[i]);



                    } else if (obj[i].ValueSet == 'MatrixColumnLabels') {
                        // TESTING MATRIX CONTROL: 
                        // We have no direct need of these, but push them into our "pass through" data collection, 
                        // for inheritors who may...
                        passThroughs.push(obj[i]);



                    } else if (obj[i].ValueSet == 'HelpedElements') {
                        // Full element info for record caching when navigating lists / trees etc
                        try {
                            var HEs = JSON.parse(obj[i].Value);
                            cmp.set("v.HelpedElements", HEs);
                        } catch (e) { }

                    } else if (obj[i].ValueSet == 'HelpTopics') {
                        // Full topic info for record caching when navigating lists / trees etc
                        try {
                            var HTs = JSON.parse(obj[i].Value);
                            cmp.set("v.HelpTopics", HTs);
                        } catch (e) { }

                    } else if (obj[i].ValueSet == 'ParsedContent') {
                        // Derivatives of record values (e.g., key-word enabled Help Topic descriptions).
                        // We have no direct need of these, but push them into our "pass through" data collection, 
                        // for inheritors who may...
                        passThroughs.push(obj[i]);

                    } else if (obj[i].ValueSet == 'Permissions') {
                        // User permissions - special string to boolean handling required, it seems...
                        var bln = obj[i].Value;
                        if (bln + '' == 'true') {
                            bln = true;
                        } else {
                            bln = false;
                        }

                        if (obj[i].Name == 'isUser') { cmp.set('v.isUser', bln); }
                        if (obj[i].Name == 'isAnalyst') { cmp.set('v.isAnalyst', bln); }
                        if (obj[i].Name == 'isAuthor') { cmp.set('v.isAuthor', bln); }
                        if (obj[i].Name == 'isAdministrator') { cmp.set('v.isAdministrator', bln); }
                        if (obj[i].Name == 'isGeoEnabled') { cmp.set('v.isGeoEnabled', bln); }


                    } else if (obj[i].ValueSet == 'EditionInfo') {
                        if (obj[i].Name == 'Edition') {

                            // Need to abstract the incoming edition value in some cases so we
                            // can enable / disable functionality on the basis of (eg) card type
                            var iEd = parseInt(obj[i].Value);

                            switch (iEd) {

                                case 1:
                                    // Usage tracker only edition: disable
                                    // all cards apart from position detector, which differentiates further 
                                    // for its own purposes

                                    if (cmp.get("v.IHCardType") != 'PosDetect') {

                                        // If we're NOT a position detector, act as if we're 'all off' edition
                                        iEd = 0;
                                    }

                                    break;

                                default:
                                    // Do nothing / unrecognised edition / leave as is
                                    break;
                            }


                            // Known edition values:
                            //		-2 	= Unset / component is initialising
                            //		-1 	= Full edition - everything enabled
                            //		 0 	= All off - no functionality provided
                            //		 1 	= Usage tracker edition:
                            //					- Allows position detector in Help Cue / context logging mode
                            //					- 1.55+ Also allows help request interactions

                            cmp.set('v.ProductEdition', iEd);

                        }

                    } else if (obj[i].ValueSet == 'Identifiers') {
                        // A unique component identifier for use filtering events to which to respond:
                        // Set this only if not set already:
                        if (obj[i].Name == 'UniqueId') {
                            if (cmp.get("v.UniqueIdent") == '') {
                                cmp.set('v.UniqueIdent', obj[i].Value);
                            }
                        }

                    } else if (obj[i].ValueSet == 'ConfigToolFilterInfo') {
                        // Mappings of configuration item tool filters to object codes
                        // (as can be found in 1st 3 chars of most listing rows)
                        cfgFilterInfo.push(obj[i]);

                    } else if (obj[i].ValueSet == 'SupportedTreeOps') {
                        // Add any supported tree operations to known extended capabilities
                        XtnCaps.push(obj[i]);

                    } else if (obj[i].ValueSet == 'Internationalisations') {
                        // Internationalisations: these are brought down as a single 'Internationalisation' name/value pair set.
                        intl.push(obj[i]);

                        // For non-config item tools, we're going to need to record the translation in
                        // specific internationalisation variables: we'll need these in mark up as we can't 
                        // run a formula of any kind within mark-up

                        // Globals
                        if (obj[i].Name == 'ButtonCancel') { cmp.set('v.ButtonCancel', obj[i].Value); }
                        if (obj[i].Name == 'ButtonGotoTemplates') { cmp.set('v.ButtonGotoTemplates', obj[i].Value); }
                        if (obj[i].Name == 'ButtonSave') { cmp.set('v.ButtonSave', obj[i].Value); }
                        if (obj[i].Name == 'FieldLabelAvailable') { cmp.set('v.FieldLabelAvailable', obj[i].Value); }
                        if (obj[i].Name == 'FieldLabelCreatedBy') { cmp.set('v.FieldLabelCreatedBy', obj[i].Value); }
                        if (obj[i].Name == 'FieldLabelCreatedByDT') { cmp.set('v.FieldLabelCreatedByDT', obj[i].Value); }
                        if (obj[i].Name == 'FieldLabelModifiedBy') { cmp.set('v.FieldLabelModifiedBy', obj[i].Value); }
                        if (obj[i].Name == 'FieldLabelModifiedByDT') { cmp.set('v.FieldLabelModifiedByDT', obj[i].Value); }
                        if (obj[i].Name == 'FieldLabelSelected') { cmp.set('v.FieldLabelSelected', obj[i].Value); }
                        if (obj[i].Name == 'MessageGenericTaskComplete') { cmp.set('v.MessageGenericTaskComplete', obj[i].Value); }
                        if (obj[i].Name == 'MessageValueRequired') { cmp.set('v.MessageValueRequired', obj[i].Value); }
                        if (obj[i].Name == 'TipButtonCompactView') { cmp.set('v.TipButtonCompactView', obj[i].Value); }
                        if (obj[i].Name == 'TipButtonGotoTemplates') { cmp.set('v.TipButtonGotoTemplates', obj[i].Value); }
                        if (obj[i].Name == 'TipButtonHelpHome') { cmp.set('v.TipButtonHelpHome', obj[i].Value); }
                        if (obj[i].Name == 'TipButtonQuickSave') { cmp.set('v.ButtonQuickSave', obj[i].Value); }
                        if (obj[i].Name == 'TipButtonClose') { cmp.set('v.TipButtonClose', obj[i].Value); }
                        if (obj[i].Name == 'TipButtonConfigureSettings') { cmp.set('v.TipButtonConfigureSettings', obj[i].Value); }
                        if (obj[i].Name == 'TipButtonUploadImage') { cmp.set('v.TipButtonUploadImage', obj[i].Value); }
                        if (obj[i].Name == 'TipGenericCancel') { cmp.set('v.TipGenericCancel', obj[i].Value); }
                        if (obj[i].Name == 'TipGenericDelete') { cmp.set('v.TipGenericDelete', obj[i].Value); }
                        if (obj[i].Name == 'TipGenericEdit') { cmp.set('v.TipGenericEdit', obj[i].Value); }
                        if (obj[i].Name == 'TipGenericOK') { cmp.set('v.TipGenericOK', obj[i].Value); }
                        if (obj[i].Name == 'TipGoto') { cmp.set('v.TipGoto', obj[i].Value); }
                        if (obj[i].Name == 'TipReadMoreLinkUsers') { cmp.set('v.TipReadMoreLinkUsers', obj[i].Value); }
                        if (obj[i].Name == 'TipVote') { cmp.set('v.TipVote', obj[i].Value); }
                        if (obj[i].Name == 'TitleHelpedElement') { cmp.set('v.TitleHelpedElement', obj[i].Value); }

                        // LUXComponents
                        if (obj[i].Name == 'AdviceLabelGenericTextPlaceholder') { cmp.set('v.AdviceLabelGenericTextPlaceholder', obj[i].Value); }
                        if (obj[i].Name == 'AdviceLabelTagMode') { cmp.set('v.AdviceLabelTagMode', obj[i].Value); }
                        if (obj[i].Name == 'AdviceLabelSelectFields') { cmp.set('v.AdviceLabelSelectFields', obj[i].Value); }
                        if (obj[i].Name == 'FieldLabelSaveFormAs') { cmp.set('v.FieldLabelSaveFormAs', obj[i].Value); }
                        if (obj[i].Name == 'FieldLabelTagModeAny') { cmp.set('v.FieldLabelTagModeAny', obj[i].Value); }
                        if (obj[i].Name == 'FieldLabelTagModeAll') { cmp.set('v.FieldLabelTagModeAll', obj[i].Value); }
                        if (obj[i].Name == 'FieldLabelTagModeAll') { cmp.set('v.FieldLabelTagModeAll', obj[i].Value); }
                        if (obj[i].Name == 'FieldLabelTreePrintIndentationLevel') { cmp.set('v.FieldLabelTreePrintIndentationLevel', obj[i].Value); }
                        if (obj[i].Name == 'AdviceLabelModified') { cmp.set('v.AdviceLabelModified', obj[i].Value); }
                        if (obj[i].Name == 'AdviceLabelWorking') { cmp.set('v.AdviceLabelWorking', obj[i].Value); }
                        if (obj[i].Name == 'AdviceLabelTools') { cmp.set('v.AdviceLabelTools', obj[i].Value); }
                        if (obj[i].Name == 'FieldLabelMyNotes') { cmp.set('v.FieldLabelMyNotes', obj[i].Value); }
                        if (obj[i].Name == 'TipButtonSettings') { cmp.set('v.TipButtonSettings', obj[i].Value); }
                        if (obj[i].Name == 'TipView') { cmp.set('v.TipView', obj[i].Value); }
                        if (obj[i].Name == 'TitleTabVisible') { cmp.set('v.TitleTabVisible', obj[i].Value); }
                        if (obj[i].Name == 'TitleSelectFields') { cmp.set('v.TitleSelectFields', obj[i].Value); }
                        if (obj[i].Name == 'TitleAllRelatedHelp') { cmp.set('v.TitleAllRelatedHelp', obj[i].Value); }
                        if (obj[i].Name == 'TitleReadingLists') { cmp.set('v.TitleReadingLists', obj[i].Value); }
                        if (obj[i].Name == 'TitleAllResources') { cmp.set('v.TitleAllResources', obj[i].Value); }
                        if (obj[i].Name == 'TitleQuickLinks') { cmp.set('v.TitleQuickLinks', obj[i].Value); }

                        // IHTools
                        if (obj[i].Name == 'ButtonGotoVoteSets') { cmp.set('v.ButtonGotoVoteSets', obj[i].Value); }
                        if (obj[i].Name == 'ButtonPreviewCallout') { cmp.set('v.ButtonPreviewCallout', obj[i].Value); }
                        if (obj[i].Name == 'ButtonPreviewCalloutAsEdited') { cmp.set('v.ButtonPreviewCalloutAsEdited', obj[i].Value); }
                        if (obj[i].Name == 'FieldLabelName') { cmp.set('v.FieldLabelName', obj[i].Value); }
                        if (obj[i].Name == 'FieldLabelSummary') { cmp.set('v.FieldLabelSummary', obj[i].Value); }
                        if (obj[i].Name == 'FieldLabelActive') { cmp.set('v.FieldLabelActive', obj[i].Value); }
                        if (obj[i].Name == 'FieldLabelCalloutHeight') { cmp.set('v.FieldLabelCalloutHeight', obj[i].Value); }
                        if (obj[i].Name == 'FieldLabelCalloutMediaChoice') { cmp.set('v.FieldLabelCalloutMediaChoice', obj[i].Value); }
                        if (obj[i].Name == 'FieldLabelCalloutTemplate') { cmp.set('v.FieldLabelCalloutTemplate', obj[i].Value); }
                        if (obj[i].Name == 'FieldLabelCustomStyle') { cmp.set('v.FieldLabelCustomStyle', obj[i].Value); }
                        if (obj[i].Name == 'FieldLabelFullTemplate') { cmp.set('v.FieldLabelFullTemplate', obj[i].Value); }
                        if (obj[i].Name == 'FieldLabelHeightBeforeScrolling') { cmp.set('v.FieldLabelHeightBeforeScrolling', obj[i].Value); }
                        if (obj[i].Name == 'FieldLabelImageALTText') { cmp.set('v.FieldLabelImageALTText', obj[i].Value); }
                        if (obj[i].Name == 'FieldLabelImageCaption') { cmp.set('v.FieldLabelImageCaption', obj[i].Value); }
                        if (obj[i].Name == 'FieldLabelImageHeight') { cmp.set('v.FieldLabelImageHeight', obj[i].Value); }
                        if (obj[i].Name == 'FieldLabelImageTitle') { cmp.set('v.FieldLabelImageTitle', obj[i].Value); }
                        if (obj[i].Name == 'FieldLabelImageURL') { cmp.set('v.FieldLabelImageURL', obj[i].Value); }
                        if (obj[i].Name == 'FieldLabelImageWidth') { cmp.set('v.FieldLabelImageWidth', obj[i].Value); }
                        if (obj[i].Name == 'FieldLabelKeywords') { cmp.set('v.FieldLabelKeywords', obj[i].Value); }
                        if (obj[i].Name == 'FieldLabelLightningTemplate') { cmp.set('v.FieldLabelLightningTemplate', obj[i].Value); }
                        if (obj[i].Name == 'FieldLabelMasterTopicIdentifier') { cmp.set('v.FieldLabelMasterTopicIdentifier', obj[i].Value); }
                        if (obj[i].Name == 'FieldLabelSFHelpURL') { cmp.set('v.FieldLabelSFHelpURL', obj[i].Value); }
                        if (obj[i].Name == 'FieldLabelShowCallout') { cmp.set('v.FieldLabelShowCallout', obj[i].Value); }
                        if (obj[i].Name == 'FieldLabelShowReadMore') { cmp.set('v.FieldLabelShowReadMore', obj[i].Value); }
                        if (obj[i].Name == 'FieldLabelShowReferringTopics') { cmp.set('v.FieldLabelShowReferringTopics', obj[i].Value); }
                        if (obj[i].Name == 'FieldLabelStatus') { cmp.set('v.FieldLabelStatus', obj[i].Value); }
                        if (obj[i].Name == 'FieldLabelStepContext') { cmp.set('v.FieldLabelStepContext', obj[i].Value); }
                        if (obj[i].Name == 'FieldLabelStepElement') { cmp.set('v.FieldLabelStepElement', obj[i].Value); }
                        if (obj[i].Name == 'FieldLabelStepLayout') { cmp.set('v.FieldLabelStepLayout', obj[i].Value); }
                        if (obj[i].Name == 'FieldLabelStepMode') { cmp.set('v.FieldLabelStepMode', obj[i].Value); }
                        if (obj[i].Name == 'FieldLabelVideoCaption') { cmp.set('v.FieldLabelVideoCaption', obj[i].Value); }
                        if (obj[i].Name == 'FieldLabelVideoHeight') { cmp.set('v.FieldLabelVideoHeight', obj[i].Value); }
                        if (obj[i].Name == 'FieldLabelVideoTitle') { cmp.set('v.FieldLabelVideoTitle', obj[i].Value); }
                        if (obj[i].Name == 'FieldLabelVideoURL') { cmp.set('v.FieldLabelVideoURL', obj[i].Value); }
                        if (obj[i].Name == 'FieldLabelVideoWidth') { cmp.set('v.FieldLabelVideoWidth', obj[i].Value); }
                        if (obj[i].Name == 'FieldLabelVisibility') { cmp.set('v.FieldLabelVisibility', obj[i].Value); }
                        if (obj[i].Name == 'FieldLabelVoteInfo') { cmp.set('v.FieldLabelVoteInfo', obj[i].Value); }
                        if (obj[i].Name == 'TipButtonPreviewCallout') { cmp.set('v.TipButtonPreviewCallout', obj[i].Value); }
                        if (obj[i].Name == 'TipButtonPreviewCalloutAsEdited') { cmp.set('v.TipButtonPreviewCalloutAsEdited', obj[i].Value); }
                        if (obj[i].Name == 'TipButtonResetImage') { cmp.set('v.TipButtonResetImage', obj[i].Value); }
                        if (obj[i].Name == 'TipButtonResetVideo') { cmp.set('v.TipButtonResetVideo', obj[i].Value); }
                        if (obj[i].Name == 'TitleGuides') { cmp.set('v.TitleGuides', obj[i].Value); }
                        if (obj[i].Name == 'TitleTabCustom') { cmp.set('v.TitleTabCustom', obj[i].Value); }
                        if (obj[i].Name == 'TitleTabGeneral') { cmp.set('v.TitleTabGeneral', obj[i].Value); }
                        if (obj[i].Name == 'TitleTabGuides') { cmp.set('v.TitleTabGuides', obj[i].Value); }
                        if (obj[i].Name == 'TitleTabStatus') { cmp.set('v.TitleTabStatus', obj[i].Value); }
                        if (obj[i].Name == 'TitleTabText') { cmp.set('v.TitleTabText', obj[i].Value); }

                        // IHConfirmActions
                        if (obj[i].Name == 'ColumnLabelDeleteAssociatedTopic') { cmp.set('v.ColumnLabelDeleteAssociatedTopic', obj[i].Value); }
                        if (obj[i].Name == 'ColumnLabelUseExistingTopic') { cmp.set('v.ColumnLabelUseExistingTopic', obj[i].Value); }
                        if (obj[i].Name == 'TipButtonSave') { cmp.set('v.TipButtonSave', obj[i].Value); }

                        // ClientSide (QAM)
                        if (obj[i].Name == '[QAMAdviceLabelGuideStepCounter1]') { cmp.set('v.QAMAdviceLabelGuideStepCounter1', obj[i].Value); }
                        if (obj[i].Name == '[QAMAdviceLabelGuideStepCounter2]') { cmp.set('v.QAMAdviceLabelGuideStepCounter2', obj[i].Value); }
                        if (obj[i].Name == '[QAMTitleButtonGotoNextStep]') { cmp.set('v.QAMTitleButtonGotoNextStep', obj[i].Value); }
                        if (obj[i].Name == '[QAMButtonGotoNextStep]') { cmp.set('v.QAMButtonGotoNextStep', obj[i].Value); }


                    } else {
                        // If none of the above, untyped items are our "list item" class - so represent listings
                        listItems.push(obj[i]);
                    }
                }

            }


            this.logAdvancedDiags(cmp, 'Return value process loop complete - internationalising');

            if (SkipGlobals + '' == 'false' || SkipGlobals + '' == 'undefined') {

                // For all configuration tools, internationalise labels and tips
                cmp.set("v.Internationalisations", intl);

                for (i = 0; i < toolsE.length; i++) {
                    toolsE[i].iahelp__Label__c = this.Internationalise(cmp, 'ToolLabel' + toolsE[i].iahelp__Label__c);
                    toolsE[i].iahelp__TipText__c = this.Internationalise(cmp, 'Tip' + toolsE[i].iahelp__TipText__c);
                }

                for (i = 0; i < toolsD.length; i++) {
                    // EXCEPTION for the "page help" drop down item: this won't have a direct translation. 
                    if (toolsD[i].iahelp__ActionCode__c == 'PageHelpLinkHelp') {
                        toolsD[i].iahelp__Label__c = this.Internationalise(cmp, 'ToolLabelPageHelp') + ': ' + toolsD[i].iahelp__Label__c;

                    } else {
                        toolsD[i].iahelp__Label__c = this.Internationalise(cmp, 'ToolLabel' + toolsD[i].iahelp__Label__c);
                    }
                    toolsD[i].iahelp__TipText__c = this.Internationalise(cmp, 'Tip' + toolsD[i].iahelp__TipText__c);
                }

                for (i = 0; i < toolsH.length; i++) {
                    toolsH[i].iahelp__Label__c = this.Internationalise(cmp, 'ToolLabel' + toolsH[i].iahelp__Label__c);
                    toolsH[i].iahelp__TipText__c = this.Internationalise(cmp, 'Tip' + toolsH[i].iahelp__TipText__c);
                }

                for (i = 0; i < toolsB.length; i++) {
                    toolsB[i].iahelp__TipText__c = this.Internationalise(cmp, 'Tip' + toolsB[i].iahelp__TipText__c);
                }

                for (i = 0; i < toolsF.length; i++) {
                    toolsF[i].iahelp__Label__c = this.Internationalise(cmp, 'ToolLabel' + toolsF[i].iahelp__Label__c);
                    toolsF[i].iahelp__TipText__c = this.Internationalise(cmp, 'Tip' + toolsF[i].iahelp__TipText__c);
                }

                for (i = 0; i < toolsX.length; i++) {
                    toolsX[i].iahelp__Label__c = this.Internationalise(cmp, 'ToolLabel' + toolsX[i].iahelp__Label__c);
                    toolsX[i].iahelp__TipText__c = this.Internationalise(cmp, 'Tip' + toolsX[i].iahelp__TipText__c);
                }

                for (i = 0; i < toolsL.length; i++) {
                    toolsL[i].iahelp__Label__c = this.Internationalise(cmp, 'ToolLabel' + toolsL[i].iahelp__Label__c);
                    toolsL[i].iahelp__TipText__c = this.Internationalise(cmp, 'Tip' + toolsL[i].iahelp__TipText__c);
                }


                // Internationalise static furniture where possible
                cmp.set("v.AdviceLabelWorking", this.Internationalise(cmp, 'AdviceLabelWorking'));
                cmp.set("v.AdviceLabelTools", this.Internationalise(cmp, 'AdviceLabelTools'));
                cmp.set("v.AdviceLabelModified", this.Internationalise(cmp, 'AdviceLabelModified'));
                cmp.set("v.FieldLabelMyNotes", this.Internationalise(cmp, 'FieldLabelMyNotes'));

            } else {
                //alert('Skipping Globals as we were passed: ' + SkipGlobals);			
            }

            this.logAdvancedDiags(cmp, 'Internationalising loop complete - setting remaining member data');

            cmp.set("v.WizardSteps", toolsW);
            cmp.set("v.WizardStepBodyTools", toolsWB);
            cmp.set("v.EllipsisTools", toolsE);
            cmp.set("v.DropDownTools", toolsD);
            cmp.set("v.HeaderTools", toolsH);
            cmp.set("v.HeaderToolSupportControls", HSCs);
            cmp.set("v.BodyTools", toolsB);
            cmp.set("v.FooterTools", toolsF);
            cmp.set("v.ExtensionTools", toolsX);
            cmp.set("v.ListingTools", toolsL);

            cmp.set("v.VoteOptions", VOs);
            cmp.set("v.ListingItems", listItems);
            cmp.set("v.PassThroughData", passThroughs);
            cmp.set("v.Delimiter", String.fromCharCode(7));
            cmp.set("v.CurrentRecordMetadata", recordMeta);
            cmp.set("v.CustomFields", customFs);


            if (SkipGlobals + '' == 'false' || SkipGlobals + '' == 'undefined') {

                // Only set global settings if the processing call returned a value for these
                // (as there are cases - eg refresh clickables - where no settings will be sought)

                if (GS != null && GS + '' != 'undefined') {
                    cmp.set("v.GlobalSettings", GS);

                    // Once we have global settings, set branding colours etc:
                    // Use global default unless individual card has specified otherwise
                    if (cmp.get("v.UXTheme") == '') {
                        cmp.set("v.UXTheme", GS.iahelp__BrandColour1Text__c);
                    }

                    var theme = cmp.get("v.UXTheme");

                    if (theme == 'Light') {
                        cmp.set("v.UXThemeColour1", GS.iahelp__BrandColour4__c);
                        cmp.set("v.UXThemeColour2", GS.iahelp__BrandColour1__c);
                        cmp.set("v.UXThemeColour3", GS.iahelp__BrandColour7__c);
                        cmp.set("v.UXMenuBackgroundColour", 'ffffff');
                        cmp.set("v.UXMenuFontColour", cmp.get("v.UXThemeColour1"));

                    } else {
                        cmp.set("v.UXThemeColour1", GS.iahelp__BrandColour5__c);
                        cmp.set("v.UXThemeColour2", GS.iahelp__BrandColour2__c);
                        cmp.set("v.UXThemeColour3", GS.iahelp__BrandColour8__c);
                        cmp.set("v.UXMenuBackgroundColour", cmp.get("v.UXThemeColour3"));
                        cmp.set("v.UXMenuFontColour", 'ffffff');
                    }

                    // Body background colour depends additionally on transparency setting
                    if (cmp.get("v.BackgroundStyle") == 'Transparent') {
                        cmp.set("v.UXBodyBackgroundColour", 'transparent');

                    } else {
                        cmp.set("v.UXBodyBackgroundColour", '#' + cmp.get("v.UXThemeColour2"));
                    }

                } 	// End if we got some settings returned
            } 	// End if we were to obtain (not skip) getting globals


            cmp.set("v.PersonalisationSettings", PS);
            cmp.set("v.ConfigToolFilterInfo", cfgFilterInfo);

            cmp.set("v.ExtendedCapabilities", XtnCaps);
            console.log('ExtendedCapabilities');

            // Assume title based on action code, unless specifics returned in call:
            // An example where title is set is tag operations (when looking at a pool of tags: card title = pool topic name)
            if (ttl != '') {
                cmp.set("v.Title", ttl);

            } else {
                // 1.39.12 / 1.40+: If we've been given a specific title, e.g., via mark up or LUX out parameters, 
                // we should use that, reverting to action code based title only as a default
                ttl = cmp.get("v.Title");
                if (ttl == "Improved Help" || ttl == '- - -' || ttl == '') {
                    cmp.set("v.Title", this.Internationalise(cmp, 'Title' + cmp.get('v.ActionCode')));
                }
            }


            // Ensure any "lower level" diags are kept
            if (cmp.get("v.Diags").toUpperCase().indexOf('ERROR') != -1) {
                cmp.set("v.Diags", cmp.get("v.Diags") + ': ' + this.Internationalise(cmp, 'AdviceLabelMatchingItems') + ': ' + listItems.length);
            } else {
                cmp.set("v.Diags", this.Internationalise(cmp, 'AdviceLabelMatchingItems') + ': ' + listItems.length);
            }


            // Raise a passthrough event to state our tools have been processed
            this.logAdvancedDiags(cmp, 'IHCardHelper.processTools - raising ComponentToolsProcessed pass-through...');

            var appEvent = $A.get("e.c:evtPassThrough");
            appEvent.setParams({ "SourceComponent": cmp.get("v.ComponentId"), "ActionCode": "ComponentToolsProcessed", "Parameters": cmp });
            appEvent.fire();

            this.logAdvancedDiags(cmp, 'IHCardHelper.processTools - complete');


            // If we've arrived at an 'all off' product edition position for this component, set a permissions specific advice message
            if (cmp.get("v.ProductEdition") == 0) {
                if (cmp.get("v.isAdministrator") == true) {
                    cmp.set("v.ProductEditionMessage", 'This option is not supported in your edition of ' + this.Internationalise(cmp, 'ProductName') + '. Please contact your ' + this.Internationalise(cmp, 'ProductSupplier') + ' Account Manager for further information.');
                } else {
                    cmp.set("v.ProductEditionMessage", 'This option is not supported in your edition of ' + this.Internationalise(cmp, 'ProductName') + '. Please contact your System Administrator for further information.');
                }
            } else {
                cmp.set("v.ProductEditionMessage", '');
            }



            return true;

        } else {
            var errors = response.getError();

            if (errors) {
                if (errors[0] && errors[0].message) {
                    strDiags = 'ERR (' + state + '): ' + errors[0].message;
                    strDiags += ' - - - COMPONENT PARAMETERS: ActionCode=' + cmp.get('v.ActionCode') + ': ToolContext=' + cmp.get('v.ToolContext') + ': IHContext=' + cmp.get('v.IHContext');
                }

            } else {
                strDiags = 'ERR (' + state + '): - - - COMPONENT PARAMETERS: ActionCode=' + cmp.get('v.ActionCode') + ': ToolContext=' + cmp.get('v.ToolContext') + ': IHContext=' + cmp.get('v.IHContext');
            }

            this.logAdvancedDiags(cmp, strDiags);
            cmp.set("v.Diags", "ERR!");
            return false;
        }

    },


    // Generic calls for opening and closing of modal dialogues:
    // NOTE: Scroll parameter applies to VF (iframed page) dialogue type ONLY - no impact in LUX (component) types.
    doDialogue: function (dlgTitle, dlgType, dlgSource, dlgAttrs, frmHeight, allowScroll, largeMode, showFooter, cmp, translateTitle) {

        // Find the modal component - which may be part of the component passed (if the card) or its supercomponent...

        var dlg = cmp.find('theModal');
        if (dlg + '' == 'undefined') {
            cmp = cmp.getSuper();
            dlg = cmp.find('theModal');

        }

        console.log('In doDialogue : Before setting Frame source ');
        // Title may or may not need translation
        if (translateTitle == true) {
            dlg.set("v.Title", this.Internationalise(cmp, 'Title' + dlgTitle));
        } else {
            dlg.set("v.Title", dlgTitle);
        }

        // Set remaining dialogue attributes
        dlg.set("v.FrameSource", dlgSource);
        dlg.set("v.FrameType", dlgType);
        dlg.set("v.FrameAttributes", dlgAttrs);
        dlg.set("v.FrameHeight", frmHeight);
        dlg.set("v.AllowScroll", allowScroll);
        dlg.set("v.LargeMode", largeMode);
        dlg.set("v.ShowFooter", showFooter);
        dlg.set("v.ShowHeader", false);
        // Show the dialogue (un-hide its container)
        var cnt = cmp.find('ModalContainer');
        $A.util.removeClass(cnt, 'slds-hide');

        console.log('Card Helper: Dialogue requested by component "' + cmp.get("v.ComponentId") + '"');
        dlg.reInitialise();

    },
    closeDialogue: function (cmp, dlgId, helper) {

        // Handle any actions that need to happen on closing of a particular dialogue
        helper.postProcessDialogue(cmp, event, helper);


        // "Clean up" the dialogue: destroy any LUX component it contains
        try {
            var dlgComp = cmp.find("theModal");
            if (dlgComp + '' != 'undefined') {
                var dlgLUXComp = dlgComp.get("v.theLUXComp");
                if (dlgLUXComp + '' != 'undefined' && dlgLUXComp != null) {

                    dlgLUXComp.set("v.body", []);
                    $A.util.addClass(dlgLUXComp, 'slds-hide');
                }
            }
        } catch (e) { }

        // Hide the dialogue container
        var cnt = cmp.find(dlgId);
        $A.util.addClass(cnt, 'slds-hide');
    },


    // Make a note of the action code that summoned a dialogue, where caller requests this
    setDialogueActionCode: function (cmp, aCode) {

        try {
            var dlg = cmp.find('theModal');
            if (dlg + '' == 'undefined') {
                cmp = cmp.getSuper();
                dlg = cmp.find('theModal');

            }

            dlg.set("v.DialogueActionCode", aCode);

        } catch (e) { }

    },


    // Respond to dialogue closures by completing any routines specific to the action that opened it
    postProcessDialogue: function (cmp, event, helper) {

        var ourModal;
        var dAct;

        try {
            ourModal = cmp.find("theModal");
            dAct = ourModal.get("v.DialogueActionCode");


            // In all cases, re-set dialogue action - any future dialogue should set if it needs
            ourModal.set("v.DialogueActionCode", '');
            console.log('Component ID "' + cmp.get("v.ComponentId") + '" postProcessDialogue - dialogue action was: ' + dAct);


            switch (dAct) {
                case 'NewResourceLink':

                    var HTID = cmp.get("v.recordId");
                    var HRID = ourModal.get("v.theLUXComp").get("v.recordId");

                    console.log('postProcessDialogue - New Resource Link: Topic "' + HTID + '" to Resource "' + HRID + '" - about to set usage notes...');

                    var act = cmp.get("c.setUsageNotesForNewHTR");

                    act.setParams({
                        "HTID": HTID,
                        "HRID": HRID,
                    });

                    act.setCallback(this, function (response, cmp) {

                        var state = response.getState();
                        var retVal;

                        if (response.getState() === 'SUCCESS') {

                            retVal = response.getReturnValue();

                            // Return value should be empty string
                            if (retVal == '') {
                                // OK
                                console.log('postProcessDialogue - Help Topic Resource usage notes amended successfully');

                                // Refresh resource list
                                var appEvent = $A.get("e.c:evtPassThrough");
                                appEvent.setParams({ "SourceComponent": cmp.get("v.ComponentId") });
                                appEvent.setParams({ "ActionCode": "RefreshCurrentList" });
                                appEvent.setParams({ "Parameters": "" });
                                appEvent.fire();

                            } else {
                                alert(retVal);
                            }

                        } else {
                            console.log('postProcessDialogue - Error amending Help Topic Resource usage notes');
                        }
                    });

                    // Send action
                    $A.enqueueAction(act);

                    break;


                case 'RelatedHelpLink':
                case 'RelatedResourceLink':
                case 'ReadingListProperties':

                    // Refresh resource list
                    var appEvent = $A.get("e.c:evtPassThrough");
                    appEvent.setParams({ "SourceComponent": cmp.get("v.ComponentId") });
                    appEvent.setParams({ "ActionCode": "RefreshCurrentList" });
                    appEvent.setParams({ "Parameters": "" });
                    appEvent.fire();
                    break;

            case 'HelpTopicsPicker':

                // Step 1: Collect selected Help Topic Ids using DOM, avoiding Proxy issues
                try {
                    var helpTopicIds = [];
                    console.log('IHContext HelpTopicsPicker : ' ,cmp.get('v.IHContext'));
                    // Prefer elements that explicitly carry data-id attributes
                    var selectedWithData = document.querySelectorAll('.IsSelected[data-id], .IsSelected [data-id]');
                    for (var i = 0; i < selectedWithData.length; i++) {
                        var dataId = selectedWithData[i].getAttribute('data-id');
                        if (dataId) {
                            helpTopicIds.push(dataId);
                        }
                    }
                    // Also scan selected rows by id patterns LINarrow_<Id> / LIWide_<Id>
                    var selectedElems = document.querySelectorAll('.IsSelected');
                    for (var j = 0; j < selectedElems.length; j++) {
                        var el = selectedElems[j];

                        var elId = el.id || (el.closest('[id]') ? el.closest('[id]').id : null);
                        if (elId && (elId.indexOf('LINarrow_') === 0 || elId.indexOf('LIWide_') === 0)) {
                            var parts = elId.split('_');
                            if (parts.length > 1) {
                                var candidate = parts.slice(1).join('_');
                                if (candidate && helpTopicIds.indexOf(candidate) === -1) {
                                    helpTopicIds.push(candidate);
                                }
                            }
                        }
                    }
                   
                    // Step 2: Resolve Reading List Id (prefer inner modal component recordId, fallback to current card recordId)
                    var readingListId = null;
                    try {
                        var inner = ourModal.get("v.theLUXComp");
                        if (inner) {
                            readingListId = inner.get("v.recordId");
                        }
                    } catch (e) { /* ignore */ }
                    if (!readingListId) {
                        // Try current card's recordId
                        readingListId = cmp.get("v.recordId");
                    }
                    if (!readingListId) {
                        // Try HelpRecordId as an additional fallback used elsewhere in card logic
                        readingListId = cmp.get("v.HelpRecordId");
                    }

                    if (!readingListId) {
                        alert('Error: Reading List Id not found.');
                        break;
                    }
                    if (!helpTopicIds.length) {
                        alert('No topics selected.');
                        break;
                    }

                    // Step 3: Create RLEs for each selected Help Topic by invoking Apex createHelpReadingListEntry
                    var remainingTopicCount = helpTopicIds.length;
                    var hadErrors = false;
                    var errorMsgs = [];

                    helpTopicIds.forEach(function (htId) {
                        var act = cmp.get("c.createHelpReadingListEntry");
                        act.setParams({
                            readingListId: readingListId,
                            helpTopicId: htId
                        });
                        act.setCallback(this, function (response) {
                            var state = response.getState();
                            if (state === 'SUCCESS') {
                                var ret = response.getReturnValue();
                                if (ret && ret.indexOf('Error') === 0) {
                                    hadErrors = true;
                                    errorMsgs.push(ret);
                                }
                            } else {
                                hadErrors = true;
                                var errs = response.getError();
                                var err = (errs && errs[0] && errs[0].message) ? errs[0].message : 'Unknown error';
                                errorMsgs.push(err);
                            }

                            remainingTopicCount -= 1;
                            if (remainingTopicCount === 0) {
                                // Optional: clear selection highlights
                                var sel = document.querySelectorAll('.IsSelected');
                                for (var k = 0; k < sel.length; k++) {
                                    sel[k].classList.remove('IsSelected');
                                }

                                if (hadErrors) {
                                    alert('Some items could not be added:\n' + errorMsgs.join('\n'));
                                } 

                                //Step 4: Refresh Reading List view/listing
                                var appEvent = $A.get("e.c:evtPassThrough");
                                appEvent.setParams({
                                "SourceComponent": cmp.get("v.ComponentId"),
                                "ActionCode": "RefreshCurrentList",
                                "Parameters": "",
                                });
                                appEvent.fire();
                            }
                        });
                        $A.enqueueAction(act);
                    });

                } catch (ex) {
                    console.error('HelpTopicsPicker post-processing failed: ', ex);
                    alert('Error adding topics to reading list: ' + ex);
                }
                break;

                default:
                    console.log('postProcessDialogue - no processing required for specified sction');
                    break;
            }

        } catch (e) {
            console.log('postProcessDialogue - Error: ' + e);

        }

    },


    // Use our component generator to display a message via a nudge component
    doNudge: function (cmp, Title, Subtitle, AutoHideTime) {

        // Find and re-set the component generator
        var CG = cmp.find("theCG");
        if (CG + '' == 'undefined') {
            cmp = cmp.getSuper();
            CG = cmp.find('theCG');
        }
        CG.set("v.ComponentDef", '');

        // Now use the same generator to make a nudge
        CG.set("v.ComponentDef", "c:IHNudge~ComponentId¬CGNudge_" + cmp.get("v.ComponentId") + "|CurrentTName¬" + Title + "|CurrentTSummary¬" + Subtitle + "|AutoHideTime¬" + AutoHideTime);
        CG.reInitialise();
    },


    // Offer a generic means of spinning up a component using our generator
    doGeneratedComponent: function (cmp, Def) {

        // Find and re-set the component generator
        var CG = cmp.find("theCG");
        if (CG + '' == 'undefined') {
            cmp = cmp.getSuper();
            CG = cmp.find('theCG');
        }
        CG.set("v.ComponentDef", '');

        // Now use the same generator to make a nudge
        CG.set("v.ComponentDef", Def);
        CG.reInitialise();
    },


    // Hide any open callout
    hideCallout: function (cmp) {
        var globalId = cmp.getGlobalId();
        var cnt = document.getElementById(globalId + 'CalloutContainer');

        $A.util.addClass(cnt, 'slds-hide');

        // Remove record selected styling from all items (list rows):
        // Don't do this where retention of selection marking has been requested, e.g., for the stickies list 
        // (where we want to retain knowledge of the item applicable to current context)

        //if (cmp.get("v.CardConfig") != 'Stickies') {
        if (cmp.get("v.RetainSelectionOnScroll") != true) {

            var LItems = document.querySelectorAll('li.HelpListingItem, tr.HelpListingItem');
            for (var i = 0; i < LItems.length; i++) {
                $A.util.removeClass(LItems[i], 'SelectedRecord');
            }
        }

    },


    // Obtain the configuration control record representing a particular Action Code
    getConfigToolForAction: function (cmp, ToolType, ActionCode) {

        var retVal = null;
        var i;
        var CTs;

        switch (ToolType) {
            case 'Body':
                CTs = cmp.get("v.BodyTools");
                break;

            case 'Drop-down':
                CTs = cmp.get("v.DropDownTools");
                break;

            case 'Ellipsis':
                CTs = cmp.get("v.EllipsisTools");
                break;

            case 'Extension':
                CTs = cmp.get("v.ExtensionTools");
                break;

            case 'Footer':
                CTs = cmp.get("v.FooterTools");
                break;

            case 'Header':
                CTs = cmp.get("v.HeaderTools");
                break;

            case 'Listing':
                CTs = cmp.get("v.ListingTools");
                break;

            default:
                // Do not attempt to obtain an unknown type
                return null;
        }

        for (i = 0; i < CTs.length; i++) {
            if (CTs[i].iahelp__ActionCode__c == ActionCode) {
                retVal = CTs[i];
                break;
            }
        }

        return retVal;
    },


    // Obtain the set of Header Tool Support Controls metadata (an array) for a particular configuration tool record
    getSupportControlsForConfigTool: function (cmp, ConfigTool) {

        // Configuration tools records have support control info in the form:
        // Support control ID {D1} Data type {D1} Label {D1} Placeholder text {D1} Value text {D2}
        // We pre-pend the action code onto this and split into an array for each HSC

        var retVal = null;

        if (ConfigTool.iahelp__SupportingControls__c != '' && ConfigTool.iahelp__SupportingControls__c != null) {

            var D1 = '~';
            var D2 = '^';
            var j;
            var HSCRecs = ConfigTool.iahelp__SupportingControls__c.split(D2);
            var HSC;
            var HSCs = [];

            for (j = 0; j < HSCRecs.length; j++) {

                // Tack the action code this tool related to onto the supporting control
                // definition: action code is present in the configuration tool row, but is not
                // part of the support definition
                HSCRecs[j] = ConfigTool.iahelp__ActionCode__c + D1 + HSCRecs[j];
                HSC = HSCRecs[j].split(D1);
                HSCs.push(HSC);
            }

            retVal = HSCs;
        }

        return retVal;
    },


    // Get the value (typically search text) present in the support control of a given clickable (identified by action code)
    getHeaderSupportControlValue: function (cmp, helper, ActionCode) {

        var retVal = '';

        try {

            // Get the search configuration tool record
            var theSearchConfigTool = helper.getConfigToolForAction(cmp, 'Header', ActionCode);

            // From this, get the support controls applicable to the search tool
            var theSearchSupportControls = helper.getSupportControlsForConfigTool(cmp, theSearchConfigTool);

            // Get the identifier used for search text box: this should be the first (and only) support control.
            // Whatever the support control definition states, we need to add our controls unique ID to it
            var theSearchSupportControlIdent = theSearchSupportControls[0][1];
            theSearchSupportControlIdent += cmp.get("v.UniqueIdent");

            // Get this tool's value from the collection of header support controls
            var SupportCtls = document.getElementById(theSearchSupportControlIdent);

            if (SupportCtls + '' != 'undefined') {
                retVal = SupportCtls.value;
            }

        } catch (e) { }

        return retVal;

    },


    // Toggle a specified configuration tool to its next state
    toggleConfigTool: function (cmp, ToolType, ActionCode) {

        try {
            var cfgToolRec = this.getConfigToolForAction(cmp, ToolType, ActionCode);
            var D1 = cmp.get('v.Delimiter');

            // We need to hide the requested item and un-hide its "next"
            var c1id = cmp.get('v.ToolContext') + D1 + ToolType + D1 + cfgToolRec.iahelp__DisplayOrder__c + D1 + cmp.get("v.ComponentId");
            var c1 = document.getElementById(c1id);

            var c2id = cmp.get('v.ToolContext') + D1 + ToolType + D1 + cfgToolRec.iahelp__ToggleNext__c + D1 + cmp.get("v.ComponentId");
            var c2 = document.getElementById(c2id);

            $A.util.removeClass(c1, 'toggleOn');
            $A.util.addClass(c1, 'toggleOff');
            $A.util.addClass(c2, 'toggleOn');
            $A.util.removeClass(c2, 'toggleOff');

        } catch (e) {
            // Nothing useful we can do on error
        }
    },


    // Log an interaction recording list state (expaneded / collapsed details) 
    logListState: function (cmp, styl) {


        //cmp.find("geoLocation").getCurrentLocation().then((location) => {

        //console.log('position IN Aura latitude ', location.latitude);
        //console.log('position IN Aura longitude ', location.longitude);
        //console.log('position IN Aura altitude ', location.altitude);
        //console.log('position IN Aura accuracy ', location.accuracy);

        //For passing the location coordinates through the pre defined "logLUXInteraction" perameters
        //I am adding the coordinates in key value format to the end of the "IHContext" with a
        //delimeter 'String.fromCharCode(7)'{A unprintable delemeter} which will be then split out when
        //pass to the server method to take out the coordinates and the remaining string will be
        //work as it is previously functioning.
        //
        this.logLUXInteractions(cmp, 10, styl, cmp.get("v.recordId")).then((response) => {
            //Do nothing
        });
        /*var D7 = String.fromCharCode(7);
        var position = { "latitude": location.latitude, "longitude": location.longitude, "altitude": location.altitude, "accuracy": location.accuracy };

        var act = cmp.get("c.logLUXInteraction");

        act.setParams({
            "iTyp": "10",
            "Description": state,
            "IHContext": cmp.get("v.recordId") + D7 + JSON.stringify(position)
        });

        // Send action
        $A.enqueueAction(act);*/
        //});

        // var act = cmp.get("c.logLUXInteraction");

        // act.setParams({
        // 	"iTyp": "10",
        // 	"Description": state,
        // 	"IHContext": cmp.get("v.recordId")
        // });

        // // Send action
        // $A.enqueueAction(act);
    },


    // Log an interaction recording which list is in use (LUX List type - e.g., set on QAM)
    logListType: function (cmp, event, helper, ListType) {


        //cmp.find("geoLocation").getCurrentLocation().then((location) => {

        //console.log('position IN Aura latitude ', location.latitude);
        //console.log('position IN Aura longitude ', location.longitude);
        //console.log('position IN Aura altitude ', location.altitude);
        //console.log('position IN Aura accuracy ', location.accuracy);
        //For passing the location coordinates through the pre defined "logLUXInteraction" perameters
        //I am adding the coordinates in key value format to the end of the "IHContext" with a
        //delimeter 'String.fromCharCode(7)'{A unprintable delemeter} which will be then split out when
        //pass to the server method to take out the coordinates and the remaining string will be
        //work as it is previously functioning.
        helper.logLUXInteractions(cmp, 11, ListType, cmp.get("v.recordId")).then((response) => {
            //Do nothing
        });
        /*var D7 = String.fromCharCode(7);
        var position = { "latitude": location.latitude, "longitude": location.longitude, "altitude": location.altitude, "accuracy": location.accuracy };

        var act = cmp.get("c.logLUXInteraction");

        act.setParams({
            "iTyp": "11",
            "Description": ListType,
            "IHContext": cmp.get("v.recordId") + D7 + JSON.stringify(position)
        });

        act.setCallback(this, function (response, cmp) {
            if (response.getState() === 'SUCCESS') {
                // Do nothing if OK

            } else {
                console.log('IH Card - error logging LUX List Type');
            }
        });

        // Send action
        $A.enqueueAction(act);*/
        //});

        // var act = cmp.get("c.logLUXInteraction");

        // act.setParams({
        // 	"iTyp": "11",
        // 	"Description": ListType,
        // 	"IHContext": cmp.get("v.recordId")
        // });

        // act.setCallback(this, function (response, cmp) {
        // 	if (response.getState() === 'SUCCESS') {
        // 		// Do nothing if OK

        // 	} else {
        // 		console.log('IH Card - error logging LUX List Type');
        // 	}
        // });

        // // Send action
        // $A.enqueueAction(act);

    },


    // Return the translation of a given message string
    Internationalise: function (cmp, val) {

        // Look for value in internationalisations
        var retVal = val;
        var x = cmp.get("v.Internationalisations");

        for (var i = 0; i < x.length; i++) {
            if (x[i].Name === val) {
                retVal = x[i].Value;
                break;
            }
        }

        return retVal;
    },


    // Return bit number that should be "on" (1) for a given, known object data type
    getToolBit: function (cmp, val) {

        // Look for value in config item known data types
        var retVal = '';
        var x = cmp.get("v.ConfigToolFilterInfo");

        for (var i = 0; i < x.length; i++) {

            if (x[i].Value == val) {
                retVal = x[i].Name;
                break;
            }
        }

        return retVal;
    },


    // Return the binary string representation of an integer
    DecToBin: function (cmp, val) {

        var retVal = '';
        var wrk = 0;
        var i;
        var Num;


        try {
            Num = parseInt(val);

            if (Num != 0) {
                while (Num > Math.pow(2, wrk)) {
                    wrk++;
                }
            } else {
                wrk = 0;
            }


            for (i = wrk; i >= 0; i--) {
                if (Math.pow(2, i) <= Num) {
                    retVal += '1';
                    Num -= Math.pow(2, i);
                } else {
                    if (i != wrk) { retVal += '0'; }
                }
            }

        } catch (e) {
            retVal = 'ERR';
        }

        return retVal;


    },


    // Cue a search operation via D&D
    dropSearch: function (cmp, event) {

        var x = event.target;
        var data = event.dataTransfer.getData("Text");
        event.preventDefault();

        // In these cases, we're changing the list (server call)
        // so show our "waiting" cues...
        this.showSpinner(cmp);

        // Re-set (clear) UI filter
        cmp.set('v.UIFilter', 'AllHelp');

        // Set card title as this too should change with list type
        cmp.set("v.Title", this.Internationalise(cmp, 'Search') + ': ' + data);

        // Call action to get required listing
        var act = cmp.get("c.getTools");
        cmp.set("v.ActionCode", 'Search');
        act.setParams({
            "ToolContext": "QAM",
            "ActionCode": 'Search',
            "IHContext": cmp.get("v.recordId"),
            "ClientComponentId": cmp.get("v.ComponentId"),
            "Params": data,
            "SkipGlobals": false,
        });

        // Add callback to process returned results
        act.setCallback(this, function (response, cmp) {
            this.processTools(response, cmp);
        });

        // Send action
        $A.enqueueAction(act);

    },


    // Wrapper to createNewTopic - Cue creation of a topic via D&D
    dropNewTopic: function (cmp, event) {

        var x = event.target;
        var data = event.dataTransfer.getData("Text");
        event.preventDefault();
        this.createNewTopic(cmp, data, true);

    },


    // Cue creation of a topic with specified content, navigating directly to it on creation if desired (reNav = true)
    createNewTopic: function (cmp, content, reNav) {

        // In these cases, we're changing the list (server call)
        // so show our "waiting" cues...
        this.showSpinner(cmp);

        // Call action to get required listing
        var act = cmp.get("c.dropNewTopic");

        act.setParams({
            "TopicContent": content,
        });

        //var latch = cmp.get("v.ResponseLatch");

        // Add callback to process returned results
        act.setCallback(this, function (response, cmp, latch) {

            var state = response.getState();

            // Remove waiting cues
            this.hideSpinner(cmp);

            if (state === "SUCCESS") {

                //cmp.set("v.ResponseLatch", latch);

                // Fire topic select event with return value
                var appEvent = $A.get("e.c:selectTopic");
                appEvent.setParams({ "RecordId": response.getReturnValue() });
                appEvent.setParams({ "SourceComponent": cmp.get('v.ComponentId') });
                appEvent.fire();

                // Note return in Diags
                cmp.set("v.Diags", this.Internationalise(cmp, 'AdviceLabelNewHelpTopicCreated') + ': ' + response.getReturnValue());

                // Set current record to newly created topic
                cmp.set("v.HelpRecordId", response.getReturnValue());


                /*
                FOLLOWING LINES WORK IN NAVIGATING TO NEWLY CREATED TOPIC - BUT AS THIS CALL IS ALSO
                MADE BY TREE CHILD/PEER CREATION WE MUST NOT CALL THEM IN THESE CIRCUMSTANCES, 
                BECAUSE HAVING CREATED THE TOPIC WE WANT THE NEXT ACTION TO BE CREATE PARENT RELATIONSHIP (NOT NAV!)
                */

                if (reNav == true) {
                    var parms = response.getReturnValue();
                    parms += cmp.get("v.Delimiter");

                    // Treat the new topic like a listing "selection" / selected item, so that
                    // a call to getTools will include it. By adding in this way, we can repeat this
                    // call (e.g., by dropping more new topic content) and see all topics created in a session... 
                    var LIs = [];
                    LIs = cmp.get("v.ListingSelections");
                    LIs.push(response.getReturnValue());
                    cmp.set("v.ListingSelections", LIs);
                    parms += cmp.get("v.ListingSelections");

                    act = cmp.get("c.getTools");
                    cmp.set("v.ActionCode", "Search");
                    act.setParams({
                        "ToolContext": cmp.get("v.ToolContext"),
                        "ActionCode": "Search",
                        "IHContext": cmp.get("v.recordId"),
                        "ClientComponentId": cmp.get("v.ComponentId"),
                        "Params": parms,
                        "SkipGlobals": false,
                    });

                    // Add callback to process returned results
                    act.setCallback(this, function (response, cmp) {
                        this.processTools(response, cmp);
                    });
                    // Send search action to select this topic
                    this.showSpinner(cmp);
                    $A.enqueueAction(act);
                }

            } else {
                cmp.set("v.Diags", "ERR!");
            }


        });

        // Send New Topic action
        $A.enqueueAction(act);


    },


    // Returns a boolean indicating whether an event emanated from the component that calls this method     
    eventIsOurOwn: function (cmp, event) {

        try {
            var src = event.getParam("SourceComponent");
            var ourId = cmp.get("v.ComponentId");
            return src == ourId && event.getSource().getGlobalId() == cmp.getGlobalId();

        } catch (e) {
            // Fail safe
            return false;
        }
    },


    // Returns a boolean indicating whether an event emanated from a card implementation's dialogue component:
    // This will only work where the dialogue is invoked in LUX mode and that component is a card implementation
    // and its parameter map included setting of the parent parameter
    eventIsFromOurDialogue: function (cmp) {

        var isMine = false;

        try {
            var dlgComp = cmp.find("theModal");
            if (dlgComp + '' != 'undefined') {
                var dlgLUXComp = dlgComp.get("v.theLUXComp");
                if (dlgLUXComp + '' != 'undefined' && dlgLUXComp != null) {
                    var dlgLUXCompParent = dlgLUXComp.get("v.Parent");
                    if (dlgLUXCompParent + '' != 'undefined') {
                        isMine = dlgLUXCompParent == cmp;
                    }
                }
                else {
                    // This is temporarily done to close Dialogue
                    if (dlgComp.get("v.ComponentId") == cmp.get("v.ComponentId") + '_Dialogue') {
                        isMine = true;
                    }
                }
            }
        } catch (e) { }

        return isMine;
    },


    // Returns a boolean indicating whether or not a control should respond to an event based on source / listens to:
    // This is designed to allow responses for controls we're listening to - NOT messages emanating from ourselves...
    eventBeingListenedTo: function (cmp, event) {

        var doResponse = false;

        try {
            var theSource = event.getParam("SourceComponent");
            var listensTo = cmp.get('v.ListensTo');
            var latch = cmp.get('v.ResponseLatch');
            var i;


            // Only respond to events that do not emanate from ourselves / do
            // emanate from the  "desired" master component(s) we wish to tie to: 
            // In addition, respond in any case where an override "response latch" has been set...

            if (latch == true) {
                // Re-set any latch
                cmp.set("v.ResponseLatch", false);
                doResponse = true;

            } else if (listensTo != '' && listensTo + '' != 'null') {
                // Listens To member data can be specified as a comma separated list
                listensTo = listensTo.split(' ').join('');
                listensTo = listensTo.split(',');

                for (i = 0; i < listensTo.length; i++) {
                    if (theSource == listensTo[i]) {
                        doResponse = true;
                        break;
                    }
                }
            }

        } catch (e) {
            // Fail safe
            doResponse = false;
        }

        return doResponse;
    },


    // Visually style the "current" record in a list
    setSelectedRow: function (cmp, rowId) {

        try {

            var marked = cmp.find("HelpListingItem");

            for (var i = 0; i < marked.length; i++) {

                // Iterate to initially remove selected style...
                $A.util.removeClass(marked[i].getElement(), 'SelectedRecord');

                // ... then add style back to the desired row
                if (cmp.get("v.ListingStyle") == 'Narrow') {

                    if (marked[i].getElement().id == 'LINarrow_' + rowId) {
                        $A.util.addClass(marked[i].getElement(), 'SelectedRecord');
                    }
                }
                if (cmp.get("v.ListingStyle") == 'Wide') {
                    if (marked[i].getElement().id == 'LIWide_' + rowId) {
                        $A.util.addClass(marked[i].getElement(), 'SelectedRecord');
                    }
                }
                if (cmp.get("v.ListingStyle") == 'Tile') {
                    // No selected style for tile mode
                }

                // Keep a record in member data of selected row
                cmp.set("v.SelectedRow", rowId);
            }

        } catch (e) { }

    },


    // Note any rows that have the selection marker and record their IDs in member data
    markSelectionControlledTools: function (cmp) {

        var LIs = cmp.get("v.ListingItems");								// All listing items on this control
        var LI = document.querySelectorAll('.IsSelected');					// All listing items visually marked as selected
        var SCTools = document.querySelectorAll('.SelectionControlled');	// All configuration tools marked as being responsive to selections 
        var rowIds = '';													// CSV of Record IDs of selected listings
        var hasSelections = false;
        var selectionCount = 0;

        // Record the selected rows
        LIs.forEach(function (v) {
            if ($('#LINarrow_' + v.Id).hasClass('IsSelected') || $('#LIWide_' + v.Id).hasClass('IsSelected')) {
                rowIds += v.Id + ',';
                selectionCount += 1;
            }
        })
        if (rowIds.length > 0) {
            hasSelections = true;
            rowIds = rowIds.substring(0, rowIds.length - 1);
        }

        rowIds = rowIds.split(',');
        cmp.set("v.ListingSelections", rowIds);

        // Mark controls responding to selections
        for (var i = 0; i < SCTools.length; i++) {
            if (hasSelections == true) {
                $A.util.addClass(SCTools[i], 'HasSelections');
            } else {
                $A.util.removeClass(SCTools[i], 'HasSelections');
            }
        }

        // Note the number of selections
        if (selectionCount > 0) {
            cmp.set("v.Diags", this.Internationalise(cmp, 'AdviceLabelSelected') + ': ' + selectionCount + '/' + LIs.length);

        } else {
            // 1.49.n: Safest to re-set to 'no diags' (avoids clashes with tree search needs etc)
            cmp.set("v.Diags", '');
        }

    },


    // Obtain a URL query parameter (or empty string if param not present)
    getURLParm: function (cmp, PName) {

        try {
            var results = new RegExp('[?&]' + PName + '=([^&#]*)').exec(window.location.href);
            return results[1] || 0;
        } catch (e) {
            return '';
        }

    },


    // Derive a page layout identifier client-side from page address (eg., where record ID not present)
    getPageContextIdentifier: function (cmp) {

        var cxt = '';

        try {
            cxt = window.location.pathname;

            cxt = cxt.replace("/lightning/", "");
            if (cxt.startsWith("page/")) {
                cxt = cxt.replace("page/", "");
            }
            else {
                // Assuming an address in the form:
                // [root]/lightning/[single character]/[object or page name]/[further path]

                cxt = cxt.substring(2);
                if (cxt.indexOf('/') != -1) {
                    cxt = cxt.substring(0, cxt.indexOf('/'));
                }
            }

            // Add a marker to show server object identification code that this is a client
            // side derivation of a LUX page address (as these are otherwise hard to differentiate from 
            // other alphanumerics in the absence of APEX or JSP markers etc)			
            cxt = '__LUX__' + cxt;
            console.log('IHCard Helper - derived page context for "' + cmp.get("v.ComponentId") + '" is: "' + cxt + '"');

        } catch (e) {
            console.log('IHCard Helper - error deriving page context: ' + e);
        }

        return cxt;

    },


    // Validate a URL string, ensuring it begins with a valid protocol (http or https)
    ensureProtocol: function (U) {

        var retVal = U;
        if (retVal == null) retVal = '';

        if (retVal != '') {
            try {
                if (!(retVal.toUpperCase().startsWith('HTTP://') || retVal.toUpperCase().startsWith('HTTPS://'))) {
                    retVal = 'https://' + retVal;
                }
            } catch (e) {
            }
        }

        return retVal;
    },


    // Get the Pixel equivalent value of a number of style REMs
    remToPx: function (cmp, val) {

        var retVal;
        try {
            retVal = val * parseFloat(getComputedStyle(document.documentElement).fontSize);
        } catch (e) {
            retVal = 0;
        }
        return retVal;
    },


    // Parse (a limited number of known) tokens in strings into the values they represent
    deTokenize: function (cmp, val) {

        var retVal = val;

        try {
            // {!Tokens} come from member data - general
            retVal = retVal.split('{!recordId}').join(cmp.get("v.recordId"));
            retVal = retVal.split('{!HelpRecordId}').join(cmp.get("v.HelpRecordId"));


            // {!Tokens} come from member data - special current record handling
            if (retVal.indexOf('{!CurrentRecord.') != -1) {

                try {

                    var i = 0;
                    var rec = cmp.get("v.CurrentRecord");
                    var fld;
                    var fldName;
                    var rest;

                    // This operation requires there to be a current record
                    if (rec + '' != 'undefined') {

                        retVal = retVal.split('{!CurrentRec');
                        while (i < retVal.length) {

                            // Process each split clause:
                            if (retVal[i].startsWith('ord.')) {
                                // If current clause start with the remainder of a current record token, obtain the field
                                fldName = retVal[i].substring(4, retVal[i].indexOf('}'));
                                rest = retVal[i].substring(retVal[i].indexOf('}') + 1);

                                fld = rec[fldName];
                                retVal[i] = fld + rest;

                            } else {
                                // If clause does not start with remainder, leave as is
                            }

                            i += 1;
                        }
                        retVal = retVal.join('');
                    }

                } catch (e) {
                    retVal = 'Card Detokenizer Error (position ' + i + ' of ' + retVal.length + '): ' + e;
                }

            }


            // Explicitly specify parent's record ID only
            if (retVal.indexOf('{!Parent.') != -1) {
                try {
                    var P = cmp.get("v.Parent");

                    // This operation requires there to be a current record
                    if (P + '' != 'undefined' && P + '' != '') {
                        retVal = retVal.split('{!Parent.recordId}').join(P.get("v.recordId"));
                        retVal = retVal.split('{!Parent.recordIdOrOwn}').join(P.get("v.recordId"));

                    } else {
                        // If there is no parent, failover to data from current object, if requested
                        retVal = retVal.split('{!Parent.recordId}').join('');
                        retVal = retVal.split('{!Parent.recordIdOrOwn}').join(cmp.get("v.recordId"));

                    }

                } catch (e) {
                    retVal = 'Card Detokenizer Error (Parent token): ' + e;
                }
            }


            // {Tokens} (NO exclamation mark) are global / non-member data
            retVal = retVal.split('{CurrentRoot}').join(location.host);

        } catch (e) {
            retVal = 'Error (Detokenize): ' + e;
        }

        return retVal;
    },


    // Ensure any values to be presented unescaped are safe / script free prior to use
    getSafeHTML: function (sHTML) {

        try {
            var HTML_CONTROL = /[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F]/g;
            var str = String(sHTML);

            if (str == 'null' || str == 'undefined') { str = ''; }
            str = str.replace(HTML_CONTROL, ' ');

            // Replace script tags
            var stripScripts = function (a, b, c) {
                b = new Option;
                b.innerHTML = a;
                for (a = b.getElementsByTagName('script'); c = a[0];) c.parentNode.removeChild(c);
                return b.innerHTML;
            }

            str = stripScripts(str);

        } catch (e) { }

        return str;
    },


    // Obtain a page definition object / structure from a definition in the form: type ^ parameters
    getPageReferenceFromDef: function (pDef) {

        var pRef = null;

        try {
            pDef = pDef.split('^');

            switch (pDef[0].toUpperCase()) {
                case 'LISTVIEW':
                    pRef = {
                        type: 'standard__objectPage',
                        attributes: {
                            objectApiName: pDef[1],
                            actionName: 'home'
                        }
                    };
                    break;

                case 'RECORD - VIEW':
                    pRef = {
                        type: 'standard__recordPage',
                        attributes: {
                            recordId: pDef[1],
                            actionName: 'view'
                        }
                    };
                    break;

                case 'RECORD - EDIT':
                    pRef = {
                        type: 'standard__recordPage',
                        attributes: {
                            recordId: pDef[1],
                            actionName: 'edit'
                        }
                    };
                    break;

                case 'RECORD - NEW':
                    pRef = {
                        type: 'standard__objectPage',
                        attributes: {
                            objectApiName: pDef[1],
                            actionName: 'new'
                        },
                        state: {
                        }
                    };
                    break;

                case 'CUSTOM':
                    pRef = {
                        type: 'standard__navItemPage',
                        attributes: {
                            apiName: pDef[1]
                        }
                    };
                    break;

                // named page (home)
                case 'STANDARD TAB':
                    pRef = {
                        type: 'standard__namedPage',
                        attributes: {
                            pageName: pDef[1]
                        }
                    };
                    break;

                default:
                    pRef = null;
            }

        } catch (e) {
            console.log('Error obtaining page reference from definition "' + pDef + '": ' + e);
        }

        return pRef;
    },


    // Process a custom extension action
    processExtensionAction: function (cmp, event, helper, provider, action, cxt, parms) {

        try {

            var obj;
            var act = cmp.get("c.doExtensionAction");

            act.setParams({
                "providerClassName": provider,
                "ActionCode": action,
                "IHContext": cxt,
                "Params": parms
            });

            // Add callback to show returned results
            act.setCallback(helper, function (response, cmp) {
                if (response.getReturnValue() != '') {

                    try {
                        obj = JSON.parse(response.getReturnValue());

                        console.log(obj);

                        if (obj.CompletedSuccessfully == true) {
                            alert(obj.CompletionMessage);

                            // Process any onward navigation the extension tool requests
                            if (obj.PostActionNavigationDef != '' && obj.PostActionNavigationDef + '' != 'null') {

                                var navService = cmp.find("navService");

                                // Only act if we have a navigation service
                                if (navService + '' != 'undefined') {

                                    // Only act if we derive a page reference from the available instructions
                                    var pRef = helper.getPageReferenceFromDef(obj.PostActionNavigationDef);

                                    if (pRef != null) {
                                        event.preventDefault();
                                        navService.navigate(pRef, true);
                                    }
                                }
                            }

                        } else {
                            alert('This custom action reported an error as follows: ' + obj.CompletionMessage);
                        }

                    } catch (e) {
                        console.log("Error parsing the following extension action return value (" + e + "): " + response.getReturnValue());
                    }

                }
            });

            // Send action
            $A.enqueueAction(act);


        } catch (ex) {
            console.log(ex);
        }

    },

    // promise will return the restparams if global settings is enabled.
    logLUXInteractions: function (cmp, iTyp, Description, IHContext, HTID) {
        //Return After getting the Locations and loging the Interaction.
        return new Promise((resolve, reject) => {
            try {
                var locationTracking = cmp.get("v.GlobalSettings").iahelp__Location_Tracking__c;
                var userLocationTrackingCheck = cmp.get("v.isGeoEnabled");
                var enableHighAccuracy = cmp.get("v.GlobalSettings").iahelp__Geo_EnableHighAccuracy__c;
                var geoTimeout = cmp.get("v.GlobalSettings").iahelp__Geo_Timeout__c;

                if (locationTracking && userLocationTrackingCheck) {

                    cmp.getSuper().find("geoLocation").getCurrentLocation({
                        iahelp__Geo_EnableHighAccuracy__c: enableHighAccuracy,
                        iahelp__Geo_Timeout__c: geoTimeout
                    }).then((location) => {

                        var userAgent = cmp.getSuper().find("geoLocation").getisUserAgent();
                        // The Rest perameter JSON structure passing this in stringify format.       
                        var restparam = {
                            latitude: location.latitude, //Datatype to change Double
                            longitude: location.longitude, //Datatype to change Double
                            accuracy: location.accuracy, //Datatype to change Double
                            altitude: location.altitude,//Datatype to change Double //location.altitude
                            userAgent: userAgent,
                            contextURL: window.location.pathname + window.location.search //Datatype to change String

                        }

                        var HLog = cmp.get("c.logHelpInteractions");
                        HLog.setParams({
                            iTyp: +iTyp,//Interaction Type which can range between 0 to 24.
                            Description: Description,
                            IHContext: IHContext,//Context from URL eg(IF in list view of the object fetch the name of the object).
                            restInteractionParam: JSON.stringify(restparam),
                            HTID: HTID

                        });
                        HLog.setCallback(this, function (response) {
                            console.log('IHCARD STATUS in if device geolocation is on', response.getState());
                            resolve(response);//Passing the response from call back of server call to the component which is calling the help Interaction to log.
                        });
                        $A.enqueueAction(HLog);
                    });

                } else {
                    // The Rest perameter JSON structure passing this in stringify format. 
                    var userAgent = cmp.getSuper().find("geoLocation").getisUserAgent();

                    var restparam = {
                        latitude: null, //Datatype to change Double
                        longitude: null, //Datatype to change Double
                        accuracy: null, //Datatype to change Double
                        altitude: null,//Datatype to change Double
                        userAgent: userAgent,
                        contextURL: window.location.pathname + window.location.search //Datatype to change String
                    }

                    console.log('JSON.stringify(restparam)==>' + JSON.stringify(restparam));
                    var HLog = cmp.get("c.logHelpInteractions");
                    HLog.setParams({
                        iTyp: +iTyp,//Interaction Type which can range between 0 to 24.
                        Description: Description,
                        IHContext: IHContext,//Context from URL eg(IF in list view of the object fetch the name of the object).
                        restInteractionParam: JSON.stringify(restparam), //Passing the Rest parameter, Add any new Parameter here for the future scope. 
                        HTID: HTID
                    });
                    HLog.setCallback(this, function (response) {
                        console.log('IHCARD STATUS in else', response.getState());
                        resolve(response);//Passing the response from call back of server call to the component which is calling the help Interaction to log.
                    });
                    $A.enqueueAction(HLog);
                }
            }
            catch (e) {
                console.log('ERROR  Interaction Type ' + iTyp + ' Description ' + Description + ' Context To Log ' + IHContext + e);
                // reject(e); 

                // For Presentation purpose Only
                // The Rest perameter JSON structure passing this in stringify format.     
                var restparam = {
                    latitude: null, //Datatype to change Double
                    longitude: null, //Datatype to change Double
                    accuracy: null, //Datatype to change Double
                    altitude: null,//Datatype to change Double
                    userAgent: null,
                    contextURL: window.location.pathname + window.location.search
                };

                console.error('ERROR in loghelpInteractions:', e);
                var HLog = cmp.get("c.logHelpInteractions");

                HLog.setParams({
                    iTyp: +iTyp, //Interaction Type which can range between 0 to 24.
                    Description: Description,
                    IHContext: IHContext, //Context from URL eg(IF in list view of the object fetch the name of the object).
                    restInteractionParam: JSON.stringify(restparam), //Passing the Rest parameter, Add any new Parameter here for the future scope. 
                    HTID: HTID
                });

                HLog.setCallback(this, function (response) {
                    console.log('IHCARD STATUS in catch', response.getState());
                    resolve(response);//Passing the response from call back of server call to the component which is calling the help Interaction to log.
                });
                $A.enqueueAction(HLog);

            }
        });
    }
        

})