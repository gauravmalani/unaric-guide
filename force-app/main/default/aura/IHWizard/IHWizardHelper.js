({        

///////////////////////////////////////////////////////////////////////////
// Wizard framework methods
///////////////////////////////////////////////////////////////////////////
    
    // Set up required wizard data according to our member data / Card Configuration etc.
    initialiseWizard : function(cmp) {

        var Stps = cmp.get("v.WizardSteps");
        var act = cmp.get("c.getTools");
        
        act.setParams({ 
            "ToolContext" : cmp.get('v.WizardName'), 
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
        	
        	// Process tools - which will give us our wizard steps etc.
            this.processTools(response, cmp);    

            // Obtain step UI parts from "support tools" config tool member data
            var Steps = cmp.get("v.WizardSteps");
            var StepComponents;
            var ComponentParams;
            var aMap;

            
            Steps.forEach(function(S) {
            	// Components are ^ delimited...
            	StepComponents = S.iahelp__SupportingControls__c;
            	
            	if (StepComponents != '' && StepComponents != null) {
	            	StepComponents = StepComponents.split('^');
	            	S.LeftComponent = StepComponents[0];
	            	S.RightComponent = StepComponents[1];
            	}
            });        
          
		});
		
		
        // Send action    
        $A.enqueueAction(act);
    
    },

    
    // As we have several left & right dynamic components and these themselves contain the dynamic
    // content we may require, this function returns the inner, dynamic component of the desired item (Left or Right) specific to desired step:
    // 		stepNum 	= wizard step on which desired component appears (ZERO BASED), or -1 for current step
    // 		cmpId 		= our mark-up aura:id of the left / right dynamic components (i.e., 'LComp' or 'RComp') - regardless of the 
    // 		component IDs set dynamically in configuration tool instructions, which are applied to the resulting inner components
    getStepComponent : function(cmp, stepNum, cmpId) {
    	
    	var retVal;
    	var theStep = stepNum;
    	
    	if (theStep == -1) {theStep = cmp.get("v.StepNum");}
    	
    	try {
			var x = cmp.find(cmpId);
			if (x.length + '' != 'undefined') {x = x[theStep];}
			retVal = x.get('v.theComponent');
			
    	} catch (e){}
		
		return retVal;		
    },
    
    
    // To create safely escaped text suited to local JSON object parsing
    getJSONSafeText : function (cmp, txt) {
    	try {
    		txt = txt.split('"').join('');
	    	return txt.replace(/[\n\r]+/g, ' - ');
    	} catch (e) {
    		return '';
    	}
    },
    
    
///////////////////////////////////////////////////////////////////////////
// Methods specific to BULK TOPIC UPLOAD wizard
///////////////////////////////////////////////////////////////////////////
   
	// At step 1, add topic text (and a blank topic) for use in defining a topic at step 2
	addTopicText : function (cmp, event) {
	
		var sels = [];
		var newTs = [];

		var txt = this.getStepComponent(cmp, -1, 'LComp');
		txt = txt.get("v.SelectedText");
		
		sels = cmp.get("v.CachedSelections");
		newTs = cmp.get("v.CachedRecords");
		
		// Add current text selection to the set of selected texts
		sels.push(txt);
		cmp.set("v.CachedSelections", sels);
		
		// Locate the input text box (in which selection was made): if there are more than
		// 1 wizard steps, there will be more than 1 left component - so pick the "current" step's component
		this.getStepComponent(cmp, -1, 'LComp').focus();
		
		
		// Having focused, we can delete selection
		this.getStepComponent(cmp, -1, 'LComp').deleteSelection();

		
		// Now prepare to get a new, blank, candidate topic
		this.showSpinner(cmp);
		
		// As we add candidate topic text, get a blank, unsaved topic record to hold it
        var act = cmp.get("c.getDefaultTopic");
                
        // Add callback to process returned results
        act.setCallback(this, function (response, cmp){

            var state = response.getState();
            var obj;
            
            // Remove waiting cues
            this.hideSpinner(cmp);
    
            if (state === "SUCCESS") { 
	            try {
					obj = JSON.parse(response.getReturnValue());
	            } catch (e) {
	                cmp.set("v.Diags", "Wizard - addTopicText - Error parsing the following return value (" + e + "): " + response.getReturnValue());
	            }
	            
	            try {
					// Amend topic name for differentiation
					if (txt.length > 50) {txt = txt.substr(0,50);}
					txt = this.getJSONSafeText(cmp, txt);
					obj.Name = txt; 
					obj.iahelp__Summary__c = 'Summary ' + (newTs.length + 1); 
					
	            	newTs.push(obj);
	            	cmp.set("v.CachedRecords", newTs);		
	            	
					// Reflect these topics onto step 3 listing
					this.processCachedRecordsToList(cmp, this);

	            	// If there's only a single topic, select this on the step 2 topic viewer
	            	if (newTs.length == 1) {
            			var ctlT = this.getStepComponent(cmp, 1, 'RComp');
						ctlT.set("v.CurrentRecord", cmp.get("v.CachedRecords")[0]);
						ctlT.set("v.Title", ctlT.get("v.CurrentRecord.Name"));
						ctlT.set("v.KeywordParsedDescription", ctlT.get("v.CurrentRecord.iahelp__Description__c"));	
						
						// Also, set this as the text on step 2 input text area
						ctlT = this.getStepComponent(cmp, 1, 'LComp');
						ctlT.set("v.FieldValue", cmp.get("v.CachedSelections")[0]);
	            	}			
										
	            	cmp.set("v.Diags", ". . .");					
	            
	            } catch (e) {
	                cmp.set("v.Diags", "Wizard - addTopicText - Error creating draft topics: " + e);
	            }
            	
            } else {
            	cmp.set("v.Diags", "ERR!");
            }
                      
		});
		
        // Send action
        $A.enqueueAction(act);
		
	},
		
	
	// Process new topics as drafted in steps 1 & 2 into step 3 list
	processCachedRecordsToList : function (cmp, hlpr) {

		var LIs = [];
		var strObj;
		var obj;
		
		var lst0 = this.getStepComponent(cmp, 0, "RComp");
		var lst2 = this.getStepComponent(cmp, 2, "LComp");
		var newTs = cmp.get("v.CachedRecords");
		
		newTs.forEach(function(T) {

			strObj = '{';
			strObj += '"Title":"' + hlpr.getJSONSafeText(cmp, T.iahelp__Summary__c) + '",';					
			strObj += '"StyleClass":null,';					
			strObj += '"RowState":"NotBookmarked",';	
			
			// For convenience, store topic description in parameters: we don't need parms for other
			// reasons at this stage and description is useful elsewhere...				
			strObj += '"Parameters":"' + hlpr.getJSONSafeText(cmp, T.iahelp__Description__c) + '",';		
						
			strObj += '"Label":"' + hlpr.getJSONSafeText(cmp, T.Name) + '",';					
			strObj += '"Id":"",';					
			strObj += '"IconTitle":"",';					
			strObj += '"IconLabel":"",';					
			strObj += '"Icon":"fa-question",';					
			strObj += '"ActionCode":"HelpCallout"';					
			strObj += '}';
										
			obj = JSON.parse(strObj);
			LIs.push(obj);
		});
		
		lst0.set("v.ListingItems", LIs);
		lst2.set("v.ListingItems", LIs);
	
	},
    

	// At step 2, set topic name to text selection
	setName : function (cmp, event) {
		
		var x = this.getStepComponent(cmp, -1, 'LComp');
		x = x.get("v.SelectedText");		
		
		var ctlT = this.getStepComponent(cmp, 1, 'RComp');
		var T = ctlT.get("v.CurrentRecord");
		T.Name = x;
		ctlT.set("v.CurrentRecord", T);
		
		// Re-set focus on text area for convenience
		this.getStepComponent(cmp, 1, 'LComp').focus();
		
		// To see the change to name, we also need to set topic card title
		ctlT.set("v.Title", x);
		
		// Reflect these topics onto step 3 listing
		this.processCachedRecordsToList(cmp, this);
	},
    
    
	// At step 2, set topic summary to text selection
	setSummary : function (cmp, event) {
		
		var x = this.getStepComponent(cmp, -1, 'LComp');
		x = x.get("v.SelectedText");		
		
		var ctlT = this.getStepComponent(cmp, 1, 'RComp');
		var T = ctlT.get("v.CurrentRecord");
		T.iahelp__Summary__c = x;
		ctlT.set("v.CurrentRecord", T);
		
		// Re-set focus on text area for convenience
		this.getStepComponent(cmp, 1, 'LComp').focus();
		
		// Reflect these topics onto step 3 listing
		this.processCachedRecordsToList(cmp, this);		
	},
	
	
	// At step 2, set topic description to text selection
	setDescription : function (cmp, event) {
		
		var x = this.getStepComponent(cmp, -1, 'LComp');
		x = x.get("v.SelectedText");		
		
		var ctlT = this.getStepComponent(cmp, 1, 'RComp');
		var T = ctlT.get("v.CurrentRecord");
		T.iahelp__Description__c = x;
		ctlT.set("v.CurrentRecord", T);
		
		// Re-set focus on text area for convenience
		this.getStepComponent(cmp, 1, 'LComp').focus();
				
		// To see changes to description, we need to amend "parsed" copy of description too
		ctlT.set("v.KeywordParsedDescription", x);
		
		// Reflect these topics onto step 3 listing
		this.processCachedRecordsToList(cmp, this);		
	},
	
	
	// At step 3, save all candidate topics
	saveAll : function (cmp, event) {

        var act = cmp.get("c.saveTopics");
        var strTopics = JSON.stringify(cmp.get("v.CachedRecords"));

        act.setParams({ 
            "topicJSON" : strTopics
        });                       
        
                
        // Add callback to process returned results
        act.setCallback(this, function (response, cmp){

            var state = response.getState();
            var obj = [];
            var lst2 = this.getStepComponent(cmp, 2, 'LComp');
            var lst3 = this.getStepComponent(cmp, 3, 'LComp');
            var lst4 = this.getStepComponent(cmp, 4, 'LComp');

    
            if (state === "SUCCESS") { 

	            try {
					obj = JSON.parse(response.getReturnValue());	            	
	            } catch (e) {
	                cmp.set("v.Diags", "Save Topics - Error parsing the following return value (" + e + "): " + response.getReturnValue());
	            }
	            
	            try {
	            	lst2.set("v.ListingItems", obj);
	            	lst3.set("v.ListingItems", obj);
	            	lst4.set("v.ListingItems", obj);
	            	
	            	cmp.set("v.Diags", this.Internationalise(cmp, 'MessageSaved') + ' (' + obj.length + ')');
	            
	            } catch (e) {
	                cmp.set("v.Diags", "Save Topics - Error post processing: " + e);
	            }
            	
            } else {
            	cmp.set("v.Diags", "ERR!");
            }
            
        });
        
        // Send action
        $A.enqueueAction(act);
	},

    
    // At step 3, delete all topics
    deleteTopics : function (cmp, event) {
    
		// Delete ALL topics on the current list
		if (confirm(this.Internationalise(cmp, 'MessageDeleteWarning'))) {

	        var act = cmp.get("c.deleteTopics");
	        var lstC2 = this.getStepComponent(cmp, 2, 'LComp');        
	        var lst = lstC2.get("v.ListingItems");
	        var strTopics = JSON.stringify(lst);
	
	        act.setParams({ 
	            "topicJSON" : strTopics
	        });                       
                
	        // Add callback to process returned results
	        act.setCallback(this, function (response, cmp){

	            if (response.getState() === "SUCCESS") { 

	            	var ret = response.getReturnValue();
	            	
	        		if (ret != '') {
		        		// If there are any diagnostics, assume this is an error and show them
		        		cmp.set("v.Diags", ret);
				        		
		        	} else {
		        		// If delete was successful, reflect this in diags...
		        		cmp.set("v.Diags", this.Internationalise(cmp, 'MessageGenericTaskComplete'));
		        		
		        		// ... then update our listing to depict row deletion: add IHHelpedSFElementError class
		        		lst.forEach(function(L) {
	        				L.StyleClass = 'IHHelpedSFElementError';
		        		});
		        		
		        		lstC2.set("v.ListingItems", lst);
	        		}

	            } else {
	            	cmp.set("v.Diags", 'ERR!');
	            }
	        });
	        
	        // Send action
	        $A.enqueueAction(act);        
		}    
    },


///////////////////////////////////////////////////////////////////////////
// Methods specific to CREATE CONTEXT HELP wizard
///////////////////////////////////////////////////////////////////////////
    
    // Create the context help (helped page layouts, elements and associated topics) implied
    // by the selections the user has made in the context help creation wizard 
	createContextHelp : function (cmp, event, helper) {
	
		var aName = '';
		var aTabs = '';
		var msg;
		var tCount = 0;
	
		
		// Get the name of the selected app
		var appList = helper.getStepComponent(cmp, 0, 'RComp');
		var appId = appList.get("v.SelectedRow");
		var appLIs = appList.get("v.ListingItems");
		
		// Do this by looking up the selected ID
		appLIs.forEach(function(LI){
			if (LI.Id == appId) {
				aName = LI.Label;
			}
		});
		
			
		// Get the tabs selected from the app
		var tabList = helper.getStepComponent(cmp, 1, 'RComp');
		var tabs = tabList.get("v.ListingSelections");
		
		tabs.forEach(function(T){
			if (T != '') {
				aTabs += T + ',';
				tCount += 1;
			}
		});
		
		if (aTabs.length > 0) {
			aTabs = aTabs.substring(0, aTabs.length - 1);
			
		} else {
			// Cannot continue without tab selections
			alert(helper.Internationalise(cmp, 'MessageSelectionRequired'));
			return;
		}
		
		
		// Offer confirmation / back out
		msg = helper.Internationalise(cmp, 'MessageSaveDialogueChanges');
		msg += '\n\nApp: ' + aName;
		msg += '\nTabs: ' + tCount;
		if ( ! confirm(msg)) {
			return;
		}
		
		var act = cmp.get("c.createHelpCxts");
		
	    act.setParams({ 
	        "appName": aName,
			"appTabs": aTabs
	    });                       
		
	    act.setCallback(helper, function (response, cmp){
	        
	        if (response.getState() == 'SUCCESS') {
	        	if (response.getReturnValue().indexOf('Error') == -1) {
	        		
	        		// Report success
	        		msg = helper.Internationalise(cmp, 'MessageGenericTaskComplete') + '\n\n';
	        		msg += helper.Internationalise(cmp, 'AdviceLabelNewHelpTopicCreated') + ':\n' + response.getReturnValue();
	
					var lbl = helper.getStepComponent(cmp, -1, 'LComp');
					lbl.set("v.value", msg);
	
	        	} else {
	        		// Error - bad return value
	    			alert(helper.Internationalise(cmp, 'MessageGenericError') + ': ' + response.getReturnValue());
	        	}
	        	
	        } else {
	        	// Error - server fail
				alert(helper.Internationalise(cmp, 'MessageGenericError') + ': Unable to contact server');
	        }
	    }); 
	
	    // Send action
	    $A.enqueueAction(act);
	
	},
	    
})