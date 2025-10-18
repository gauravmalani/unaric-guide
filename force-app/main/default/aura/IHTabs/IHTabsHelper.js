({        
 
	// Obtain the list of tabs (wizard steps) we've been instructed to build 
    initialiseTabs : function(cmp, helper) {
        
    	var Stps = cmp.get("v.WizardSteps");
    	var wizName = cmp.get("v.WizardName");
    	var HTID = cmp.get("v.HelpRecordId");
        
        // If tabset is not provided in Design parameter and wizardSteps is not empty then  
        // assign it's tabset name to wizardname 
        if(wizName == '' && Stps.length > 0){
            wizName = Stps[0].iahelp__ToolContext__c;
        }
        
        var act = cmp.get("c.getTools");
        
		// Do not proceed here if we're based on our listing / related records:
		// If we were to do so, we'd over-write the related item wizard steps with
		// nothing (no tabset being in play)
		if (wizName == '' && HTID != '') {
			return;
		}
        
        act.setParams({ 
            "ToolContext" : wizName, 
            "ActionCode" : 'GetWizard',
            "ClientComponentId" : cmp.get("v.ComponentId"),
            "Params" : '',
            "SkipGlobals" : false,
        });         
        
		this.showSpinner(cmp);
		
		// Clear any existing components
		Stps.forEach(function(S) {
        	S.LeftComponent = '';
        	S.RightComponent = '';			
		});
		
        
        act.setCallback(this, function (response, cmp){

        	// Keep a copy of helper variable - as call to process tools seems to lose it!!
        	var hlpr = this;
        	
        	// Process tools - which will give us our wizard steps (tabs) etc.
            this.processTools(response, cmp);    
            
			// Set certain internationalisations
			if (cmp.get("v.TipToggleButton") == '') {
				cmp.set("v.TipToggleButton", helper.Internationalise(cmp, "TipDesignModeOn"));                
			}            
			if (cmp.get("v.TipGenericReorder") == '') {
				cmp.set("v.TipGenericReorder", helper.Internationalise(cmp, "TipGenericReorder"));                
			}              
			if (cmp.get("v.TipGenericDelete") == '') { 
				cmp.set("v.TipGenericDelete", helper.Internationalise(cmp, "TipGenericDelete"));                
			} 
			if (cmp.get("v.TipGenericAdd") == '') { 
				cmp.set("v.TipGenericAdd", helper.Internationalise(cmp, "TipGenericAdd"));                
			}     
			
			         
            // Generate tabs based on instructions in the wizard steps
            helper.generateTabContent (cmp, event, helper);
            
            // Select the first tab
			// No need to do this in utility bar mode
			if (cmp.get("v.Treatment") == 'Standard') {            
				helper.activateTab(cmp, event, helper, 0);
			}            
           
		});
				
        // Send action    
        $A.enqueueAction(act);
    
    },
    
    
    // Generate tab content based on the instructions in our wizard steps
    generateTabContent : function (cmp, event, helper) {

        // Obtain step UI parts from "support tools" config tool member data
        var Steps = cmp.get("v.WizardSteps");
        var StepComponents;
        var ComponentParams;
        var tabNum = 0;
        var aMap;
		var i;
		var tabCtls = [];
		var tabInits = [];
		var strObj;
		var obj;


		console.log('IHTabs - Generate Tab Content: entry...');
        
        // Loop around each tab (wizard step) that was specified in the set defined by the tab context 
        // (wizard) configured for this tabs control            
        Steps.forEach(function(S) {
        
        	// The contents of each tab are defined in supporting controls
        	// (just like a wizard step's body components are)
        	StepComponents = S.iahelp__SupportingControls__c;
        	console.log('IHTabs - Generate Tab Content: ' + StepComponents);
        	
        	
        	// Get some JSON we can turn into an object, below... 
        	strObj = JSON.stringify(S);
        	
        	
        	if (StepComponents != '' && StepComponents != null) {
        	
        		// The components on each tab (there may be more than 1) are ^ delimited...
            	StepComponents = StepComponents.split('^');
            	
            	// Loop around the collection of component definitions for the current tab (wizard step) 
            	for (i=0; i<StepComponents.length; i++) {
            	
            		// Create a configuration items object based on the one we stringified above:
            		// We don't need most of the attributes, but we need to set some of them 
            		// and place the resulting object into a member data collection so our markup
            		// can include an iteration for each tab AND an iteration within each of them
            		// for each component to be created thereon...
            		
            		obj = JSON.parse(strObj); 
            		
            		// The configuration item object needs its supporting controls set - so the 
            		// component on the tab can be built from it. Take the definition for this single item, split from 
            		// the whole collection for the current tab.
            		obj.iahelp__SupportingControls__c = StepComponents[i];	            		

            		
            		// Mark each component on the current tab as belonging to it - using display grouping as an identifier
            		obj.iahelp__DisplayGrouping__c = S.iahelp__DisplayOrder__c;
            		tabCtls.push(obj);
            	}
            	
            	// For each tab being created, note the fact that it has yet to be initialised
            	// (tab clicks update these values as each tab is used)
            	tabInits.push(false);    


				// If enhanced styling has been requested, set up odd / even tab colours
				if (cmp.get("v.Treatment") == 'Adopter') {
					if (tabNum % 2 == 0) {
						Steps[tabNum].iahelp__ToolClass__c = 'Even';
					} else {
						Steps[tabNum].iahelp__ToolClass__c = 'Odd';
					}
				}

            	tabNum += 1;     
            	
        	}
        });   
        
        
        // Set 'no data' message only here: one way or another, we should have tabs at this point
        // unless there was an issue - in which case we'll want the no data message:
        // 1.54+ : now set via design attribute
    	// cmp.set("v.NoDataMessage", 'No tabs found matching selected collection name or Topic'); 

		if (cmp.get("v.Treatment") == 'Adopter') {
			cmp.set("v.WizardSteps", Steps);
		}
        
        cmp.set("v.TabInitialised", tabInits);
        cmp.set("v.TabComponentDefs", tabCtls);
    
    },


   // Activate the requested tab, specified by zero-based index
    activateTab : function (cmp, event, helper, currentIdx) {

    	console.log('IHTabs - Activate Tab: ' + currentIdx);

        var i;
        var maxTabs = 100;
        var globalId = cmp.getGlobalId();        
        var TabName = globalId + 'IHTabsBody_';
        var SelectorName = globalId + 'IHTabsSelector_';
        var ctl;
		var comps = cmp.find("TComp");
		var comp;
		var inits = cmp.get("v.TabInitialised");


		// Record the index of the requested tab
		cmp.set("v.ActiveTabIndex", currentIdx);

		// Mark and show this tab
		helper.showActivatedTab (cmp, event, helper, currentIdx);

		
		// Initialise any components on the clicked tab - thereby offering lazy load.
		// Only initialise if this has not yet been done (i.e., if this is the first time
		// the tab has been clicked / activated)

		try {
			if (inits[currentIdx] == false) {

				// If there's only a single tab defined, get its component into an array, 
				// as we assume this, below, for looping etc.
				if (comps.length + '' == 'undefined') {
					comp = comps;
					comps = [];
					comps.push(comp);
					comp = null;
				}

				comps.forEach (function(C){
				
					comp = C.get("v.Id");	
					
					if (comp.replace('TabComp_', '') == '' + currentIdx) {		
						comp = C.get("v.theComponent");
						console.log('IHTabs - Activate Tab: located tab\'s generated component: ' + comp);
	
						C.set("v.isInitialised", "false");
						C.reInitialise();
					}
				});	

				inits[currentIdx] = true;

			}		

		} catch (e) {
			// Probable that underlying control not yet generated - all
			// we can do is skip / ignore
			console.log('IHTabs - Activate Tab: trapped error: ' + e);        
		}

		cmp.set("v.TabInitialised", inits);
		console.log('IHTabs - Activate Tab: done');        
    },
    
    
   // Un-hide and style as 'active' the requested tab, specified by zero-based index
    showActivatedTab : function (cmp, event, helper, currentIdx) {

		var globalId = cmp.getGlobalId();        
		var TabName = globalId + 'IHTabsBody_';
		var SelectorName = globalId + 'IHTabsSelector_';
		var i;
		var maxTabs = 100;
		var ctl;
		var previousIdx = -1;


        // Get all tab selectors & Remove selection
        for (i=0; i < maxTabs; i++) {
			ctl = document.getElementById(SelectorName + i);
			$A.util.removeClass(ctl, 'slds-active');
        }


        // Find the clicked tab selector and add selection
		ctl = document.getElementById(SelectorName + currentIdx);
		$A.util.addClass(ctl, 'slds-active');

        
        // Hide all tabs
        for (i=0; i < maxTabs; i++) {
			ctl = document.getElementById(TabName + i);
			
			// Before hiding, note whether the tab was visible: if so, log the index of the tab		
			if ($A.util.hasClass(ctl, 'slds-show')) {
				previousIdx = i;
			}	

			$A.util.removeClass(ctl, 'slds-show');
			$A.util.addClass(ctl, 'slds-hide');
        }


		// Toggle behaviour only applies to utility bar style
		if (cmp.get("v.Treatment") == 'Utility') {
			if (previousIdx == currentIdx) {
				// If the requested tab was already visible, toggle its visibility.	
				ctl = document.getElementById(TabName + previousIdx);
				$A.util.removeClass(ctl, 'slds-show');
				$A.util.addClass(ctl, 'slds-hide');
			
			} else {
			    // If a different tab was visible, carry on and just show requested tab
			    // Find and show selected tab
				ctl = document.getElementById(TabName + currentIdx);
				$A.util.removeClass(ctl, 'slds-hide');
				$A.util.addClass(ctl, 'slds-show');
			}
		
		} else {
			ctl = document.getElementById(TabName + currentIdx);
			$A.util.removeClass(ctl, 'slds-hide');
			$A.util.addClass(ctl, 'slds-show');
		}

    },
    
    
})