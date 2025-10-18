({ 


	// Build FIXED tabs where Wizard name has been supplied: Obtain wizard data etc (via helper)
    init : function(cmp, event, helper) {
    
		// Ensure active tab is made visible
		// No need to do this in utility bar mode
		if (cmp.get("v.Treatment") == 'Standard') {
			helper.showActivatedTab (cmp, event, helper, cmp.get("v.ActiveTabIndex"));
		}		
		
		// Suppress powered by for utiltiy mode
		if (cmp.get("v.Treatment") == 'Utility') {
			cmp.set("v.SuppressPoweredBy", 'true');
		}		

        // Only queue 1x action per page visit
        if (cmp.get('v.isInitialised') === true) {
            return;
        }
        cmp.set('v.isInitialised', true);
        
    	helper.initialiseTabs(cmp, helper);

    },

    
    // Wrapper allowing outside world to re-generate our tabs, rather than completely re-initialising
    generateTabContent : function (cmp, event, helper) {
    	helper.generateTabContent(cmp, event, helper);
    },
    

   // Process tab clicks
    clickTab : function (cmp, event, helper) {

        var currentIdx;
        var globalId = cmp.getGlobalId();        
        var TabName = globalId + 'IHTabsBody_';

        // Obtain the index of the clicked tab
        try {
	        currentIdx = event.target.getAttribute("aria-controls").split(TabName).join('');
        } catch (e) {
        	// If tab click is not quite on the "right" bit of the tab...
        	return;
        }
        // helper.generateTabContent(cmp, event, helper);
        // Activate this tab
        helper.activateTab(cmp, event, helper, currentIdx);
        
    },
    
    
    // Allow programmatic tab clicks
    selectTab : function (cmp, event, helper) {
    	
    	// Obtain index of desired tab from method parameters
        var params = event.getParam('arguments');
        if (params) {
        	
        	// Activate this tab
        	helper.activateTab(cmp, event, helper, params.tabIndex);    
        }
    },
    
    
    // Adjust tab headers in view
    shiftTabsLeft : function (cmp, event, helper) {
    	var leftMostTab = cmp.get("v.InitialTab");
    	if (leftMostTab > 0) {
    		cmp.set("v.InitialTab", leftMostTab - 1);
    	}
    },
    shiftTabsRight : function (cmp, event, helper) {
    	var leftMostTab = cmp.get("v.InitialTab");
    	var Steps = cmp.get("v.WizardSteps");
    	if (leftMostTab < Steps.length - 1) {
    		cmp.set("v.InitialTab", leftMostTab + 1);
    	}
    },
    
    
    // Build DYNAMNIC, RELATED tabs when there is no wizard name, but instead we have a topic ID etc. 
	handlePassThroughs : function (cmp, event, helper) {
	
        var aCode = event.getParam("ActionCode");
        var src = event.getParam("SourceComponent");
        var parms = event.getParam("Parameters");       
        
        // If list is ready, use its data to build tabs
        if (src == cmp.get("v.ComponentId") + '_List') {                
	        if (aCode === 'ComponentToolsProcessed') {
	        
	        	try {
		        	var lst = cmp.find("theList");
		        	var wizSteps = [];
		        	var LIs = lst.get("v.ListingItems");
		        	var tools = lst.get("v.HeaderTools");
		        	var tool;
		        	var WStep;
		        	var ctl;
		        	
		
					// We only get here if we were not provided with a tab set (Wizard Name) from which
					// to produce tabs - so we're assuming we're getting a tab for each item on a related list.
					// If this returned no rows, we'll show the no data message. In these cases,
					// tabs itself will not have processed tools - but its list will still have done so - so 
					// we can set user rights according to that of the list. This is important as it allows
					// authors to add new tabs etc via design mode (as the edit toggle only appears for authors +
					
					if (LIs.length == 0) {
						cmp.set("v.isAuthor", lst.get("v.isAuthor"));
						cmp.set("v.isAdministrator", lst.get("v.isAdministrator"));
					}       	
		        	

					// Similarly, tabs itself will not have set product edtion in these case, so 
					// set it here to that which list obtained
					cmp.set("v.ProductEdition", lst.get("v.ProductEdition"));		        	
	
		        	// Listing items are the iterables for each of which we want a tab.
		        	
		        	// Meanwhile, the list's configuration tools are [Template] 
		        	// records we can duplicate as if they were a 'wizard step' - as usually
		        	// used to generate tabs:
		        	
		        	// Our TemplateActionCode member should be used to locate the particular 
		        	// configuration tool to use as the source of the 'supporting controls'
		        	// that define the component to spin up on each tab
		        	
		        	tools.forEach(function (T) {
		        		if (T.iahelp__ActionCode__c == cmp.get("v.TemplateActionCode")) {
		        			tool = T;
		        		}
		        	});
	
	
		        	// We can only proceed if we located a template tool on which
		        	// to base tab contents:
		        	
		        	if (tool + '' == 'undefined') {
		        		console.log('IH Related Tabs: failed to locate template header tool matching requested action code (' + cmp.get("v.TemplateActionCode") + ')');
		        		
		        		// Set our no data message to suitable advice in these cases
		        		cmp.set("v.NoDataMessage", 'Specified tab template not found');
		        		
		        		return;
		        		
		        	} else {
		        		console.log('IH Related Tabs: located template header tool matching requested action code (' + cmp.get("v.TemplateActionCode") + ') - continuing...');
		        	
			        	LIs.forEach(function (LI){
			        		
			        		// 'Clone' (deep copy) the template tool
			        		WStep = JSON.parse(JSON.stringify(tool));
			        		
			        		// Now amend properties as required to create tab content instructions,
			        		// based in part on the content of our related list
			        		WStep.iahelp__Label__c = LI.Label;
			        		WStep.iahelp__TipText__c = LI.Title;
			        		WStep.iahelp__IconClass__c = LI.Icon;
			        		WStep.iahelp__ToolClass__c = LI.StyleClass;
			        		WStep.iahelp__DisplayOrder__c = wizSteps.length + 1;
	
							/*
							As we're a card, we could detokenize - BUT only to the PARENT record:
							Here, we MAY need attributes of the child (e.g., help topic ID) - but
							we cannot know for certain that this is desied. SO: add on help listing
							ID if we are given a 'clue' that this is required: by checking for this
							being at the END of the supporting controls, we can allow these parameters
							to be hard wired / not overwritten by positioning them elsewhere in the string...
							*/		        		
							
							ctl = WStep.iahelp__SupportingControls__c;
							if (ctl.endsWith('recordId¬') || ctl.endsWith('HelpRecordId¬')) {
								ctl += LI.Id;
							} 
							WStep.iahelp__SupportingControls__c = ctl;
			        		
			        		
			        		// Add the cloned and amended tool into the collection of 'wizard steps'
			        		// to pass to the tabs control
			        		wizSteps.push(WStep);
			        	});
		        	}
		        	
		        	// Once ready, set our tab control's member data and fire a re-build
					cmp.set("v.WizardSteps", wizSteps);        	
					helper.generateTabContent(cmp, event, helper);
		        	
					// Then select the first tab
					cmp.selectTab(0);
	
		        	// Having processed the listing items we can suppress the list UI altogether
		        	lst.set("v.SuppressCardUI", true);
	        
	        	} catch (e) {
	        		console.log('IHTabs - component tools processed passthru error: ' + e);
	        	}
	        	
	        }	// End if component tools processed passthru for a list
        }        		
	},
    
    
    // For switching between viewing and editing mode
    toggleEditMode : function(cmp, event, helper){

		// Validity check for isAuthor  
		// if(cmp.get("v.isAuthor")== true){
            //Toggling mode
            var editMode = cmp.get("v.editMode");
            cmp.set("v.editMode",!editMode);
            if(editMode == false){
                cmp.set("v.ToggleButton","microTool fa fa-toggle-on");  
                cmp.set("v.TipToggleButton", helper.Internationalise(cmp, "TipView"));                
              
            }
            else if(editMode == true){
                cmp.set("v.ToggleButton","microTool fa fa-toggle-off"); 
                cmp.set("v.TipToggleButton", helper.Internationalise(cmp, "TipDesignModeOn"));                
              
            }
        //} 
    },
    
    
    // For deleting Tab from the WizardSteps
    deleteTab : function(cmp , event , helper){
    
        // get the current tab index number
        var ctarget = event.currentTarget;
        var deletedTabIndex = ctarget.dataset.value;
        var tagList=[];
        var indexnumber = 0;
        var deleted;
        var DeleteTabList=[];
        
        tagList = cmp.get("V.WizardSteps");
        indexnumber = deletedTabIndex;
        deleted = tagList.splice(indexnumber,1);
        cmp.set("v.WizardSteps",tagList);
        
        // Select the first tab
        helper.activateTab(cmp, event, helper, 0);
    },
    
    
    // For adding the Tab in the WizardSteps attribute
    addTab : function(cmp, event, helper){
       
        var WZS = [];
        var WZ;
        var new_WZ;
        var NewTabList = [];
var defaultTDef = cmp.get("v.DefaultTabDef");
        
        WZS = cmp.get("v.WizardSteps");
        
        if(WZS.length > 0){
        	
        	// If we already have some tabs, clone the last of them to create a new one
            WZ = WZS[WZS.length - 1];
            new_WZ = JSON.parse(JSON.stringify(WZ));
            new_WZ.iahelp__Label__c = 'New Tab';
            new_WZ.iahelp__TipText__c = helper.Internationalise(cmp, 'AdviceLabelReadMoreLink');   
                     
//new_WZ.iahelp__SupportingControls__c ='c:IHDetail~Height¬-2';

// Provide opportunity to amend default tab programatically
if (defaultTDef != '') {
	new_WZ.iahelp__SupportingControls__c = defaultTDef;
}

            new_WZ.iahelp__DisplayOrder__c += 1;
            WZS.push(new_WZ); 
            cmp.set("v.WizardSteps",WZS);                       
        
        } else {
	        // If we have no tabs, make server call to get new one
        	var action = cmp.get("c.getNewTab");
        	action.setParams({ 
        	});

	        action.setCallback(this, function(response) {
	            var state = response.getState();
	            if (state === "SUCCESS") {
	                if(response.getReturnValue() != ""){
	                    
	                    // Return value should be JSON of a configuration item representing a tab
	                    // (i.e., a 'wizard step' as usually used for tabs)
	                    new_WZ = JSON.parse(response.getReturnValue());
	                    
// Provide opportunity to amend default tab programatically
if (defaultTDef != '') {
	new_WZ.iahelp__SupportingControls__c = defaultTDef;
}	
                    
	                    WZS.push(new_WZ); 
	                    cmp.set("v.WizardSteps",WZS);
	                    
	                    // Generate tabs based on instructions in the wizard steps
	                    helper.generateTabContent(cmp, event, helper);
	                    
	                    // Select the first tab
	                    helper.activateTab(cmp, event, helper, 0);
	                }
	            }
	        });
	        $A.enqueueAction(action);                
        }

        // Generate tabs based on instructions in the wizard steps
        helper.generateTabContent (cmp, event, helper);
        
        // Select the first tab
        helper.activateTab(cmp, event, helper, (WZS.length-1));

    },
    
    
    // For saving the Tabs
    onSaveTabs : function(cmp,event,helper){
    
        var WizardSteps = cmp.get("v.WizardSteps");
        var toolContext = WizardSteps[0].iahelp__ToolContext__c;
        var Type = WizardSteps[0].iahelp__Type__c;
        var getTabCompDefs;
        var listOfNewTabSet = [];
        var newTabSetName;
        
        
        helper.generateTabContent(cmp, event, helper);            
        getTabCompDefs = cmp.get("v.TabComponentDefs");
        
        
        // To prompt new Tabset name:
		// Prompt user until we get a non-blank tabset name or they cancel
		do {
			newTabSetName = prompt(helper.Internationalise(cmp, "MessageEnterItemName"), cmp.get("v.WizardName"));      
		} while (newTabSetName == '') 
        
        
        if(newTabSetName == null){
        	// User clicked cancel - do nothing
        	return;
        	
        } else {     
        	// Execute when new Tabset name is given.
            if(newTabSetName != cmp.get("v.WizardName")){
            	for (let x = 0 ; x < WizardSteps.length ; x++) {
                     var newTabset = JSON.parse(JSON.stringify(WizardSteps[x]));
                     newTabset.iahelp__ToolContext__c = newTabSetName;
                     newTabset.iahelp__SupportingControls__c = getTabCompDefs[x].iahelp__SupportingControls__c;
                     Object.assign(newTabset, {iahelp__SkipExport__c: true});
                     Object.assign(newTabset, {iahelp__SkipImportOverwrite__c: true});
                     delete newTabset['Id'];
                     listOfNewTabSet.push(newTabset);
            	}
                        
               // Reassigning the updated Tablist to WizardSteps for further operation. 
               cmp.set("v.WizardSteps",listOfNewTabSet);
                        
               // To save the new Tabsets as saveAs functunility. 
               var action = cmp.get("c.SaveTabs");
               action.setParams({  
                   newToolContext : newTabSetName,
                   toolType : Type,
                   stringifiedCIList : JSON.stringify(listOfNewTabSet),
               });

               action.setCallback(this, function(response) {
            	   var state = response.getState();
            	   if(state === "SUCCESS") {
            		   if(response.getReturnValue() == ""){
            			   var SuccesstoastEvent = $A.get("e.force:showToast");
            			   SuccesstoastEvent.setParams({
                                 title : helper.Internationalise(cmp, ""),
                                 message: helper.Internationalise(cmp, "MessageSaved"),
                                 duration:' 5000',
                                 type: 'success',
                                 mode: 'dismissible' 
            			   });
            			   SuccesstoastEvent.fire();

            		   } else {
            			   var errorToastEvent = $A.get("e.force:showToast");
            			   errorToastEvent.setParams({
                                  title : helper.Internationalise(cmp, "MessageGenericErrorShort"),
                               message: helper.Internationalise(cmp, "MessageGenericError")+': '+response.getReturnValue(),
                                  duration:' 5000',
                                  type: 'error',
                                  mode: 'dismissible'
            			   });
            			   errorToastEvent.fire();  
            		   }
            	   } 
                   helper.initialiseTabs(cmp, helper);
               });
               $A.enqueueAction(action);


            } else { 
            	// This will run in case of save operation
            	// Run when press OK button, if name is blank it will take current Tabset name.
                        
              	var wz; //For storing updated wizard steps
                // Removing Id(key-value pair) to perform Insertion of configuration item records because in server-side if it finds id,
                // It will try to update but since it will not have record matching with that id so it won't update
                // Since it has id it will also not insert
                // So neither insert nor update will happen    
                for(let x in WizardSteps) {
                    WizardSteps[x].iahelp__SupportingControls__c = getTabCompDefs[x].iahelp__SupportingControls__c;
                    wz = WizardSteps[x];
                    delete wz['Id'];
                }
                
                console.log(WizardSteps);
                var action = cmp.get("c.SaveTabs");
                action.setParams({  
                   "toolContext" : toolContext,
                   "toolType" : Type,
                   "stringifiedCIList" : JSON.stringify(WizardSteps)
                });
                
                action.setCallback(this, function(response) {
                	var state = response.getState();
                	if(state === "SUCCESS") {
						var EditModeType = cmp.get("v.editMode");
						cmp.set("v.editMode",!EditModeType);
						cmp.set("v.ToggleButton","fa fa-toggle-off");
						cmp.set("v.TipToggleButton", helper.Internationalise(cmp, "TipDesignModeOn"));                
						cmp.set("v.TabStatus",response.getReturnValue());

						if(response.getReturnValue() == ""){
							var SuccesstoastEvent = $A.get("e.force:showToast");
							SuccesstoastEvent.setParams({
								title : helper.Internationalise(cmp, ""),
								message: helper.Internationalise(cmp, "MessageSaved"),
								duration:' 5000',
								type: 'success',
								mode: 'dismissible'
							});
							SuccesstoastEvent.fire();
							
                       } else {
                    	   var errorToastEvent = $A.get("e.force:showToast");
                    	   errorToastEvent.setParams({
                               title : helper.Internationalise(cmp, "MessageGenericErrorShort"),
                               message: helper.Internationalise(cmp, "MessageGenericError")+' :'+response.getReturnValue(),
                               duration:' 5000',
                               type: 'error',
                               mode: 'dismissible'
                           });
                           errorToastEvent.fire(); 
                       }
                   }
                   helper.initialiseTabs(cmp, helper);
                });
                        
                $A.enqueueAction(action);
            
            }	// end if newtabsetname
        }	// end if newtabsetname = null
                   
    },
    
    
    // Revert tabs to pre-edit condition
    cancelChanges : function(cmp, event, helper){
        // Obtain internationalisations IHCard
    	var msg = helper.Internationalise(cmp, 'MessageCancelWarning');
    	
        if (confirm(msg) == true) {
        	
            //Reverting back new changes
        	helper.initialiseTabs(cmp, helper);
            
        } else {
            // Do nothing
        } 
        
    },
    
    
    // To move Tab to Left
    moveToLeft:function(cmp,event,helper){
    
        var ctarget = event.currentTarget;
        var getTabIndex = +ctarget.dataset.value;
        var WizardSteps = cmp.get("v.WizardSteps");
        var currentTag = WizardSteps[getTabIndex];
        var precedingTag = WizardSteps[getTabIndex-1]; 
        
        // Reduce the display order by one.
        currentTag.iahelp__DisplayOrder__c = currentTag.iahelp__DisplayOrder__c - 1; 
         
        // Increase the display order by one. 
        precedingTag.iahelp__DisplayOrder__c = precedingTag.iahelp__DisplayOrder__c + 1; 
        WizardSteps[getTabIndex] = precedingTag;
        WizardSteps[getTabIndex-1] = currentTag;
        
        //Setting WizardSteps 
        cmp.set("v.WizardSteps",WizardSteps);
        
    },
    
    
    // To move Tab to Right
    moveToRight:function(cmp,event,helper){
    
        var ctarget = event.currentTarget;
        var getTabIndex = +ctarget.dataset.value;
        var WizardSteps = cmp.get("v.WizardSteps");
        var currentTag = WizardSteps[getTabIndex];
        var succeedingTag = WizardSteps[getTabIndex+1];
        
        // Increase display order by one.
        currentTag.iahelp__DisplayOrder__c = currentTag.iahelp__DisplayOrder__c + 1;
        
        // Reduce display order by one.
        succeedingTag.iahelp__DisplayOrder__c = succeedingTag.iahelp__DisplayOrder__c - 1;
        WizardSteps[getTabIndex] = succeedingTag;
        WizardSteps[getTabIndex+1] = currentTag;
        
        //Setting WizardSteps
        cmp.set("v.WizardSteps",WizardSteps);
        
    },


	// Prevent Drag & Drop ops / visual cues on tabs when editing label text
	disableDD : function (cmp, event, helper) {
	    event.preventDefault();
	    return;
    },
   
})