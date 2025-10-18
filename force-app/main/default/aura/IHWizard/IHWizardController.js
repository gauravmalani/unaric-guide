({

///////////////////////////////////////////////////////////////////////////
// Wizard framework methods
///////////////////////////////////////////////////////////////////////////

	// Obtain wizard data etc (via helper)
    doneRendering : function(cmp, event, helper) {

        // Only queue 1x action per page visit
        if (cmp.get('v.isInitialised') === true) {
            return;
        }
        cmp.set('v.isInitialised', true);
    
    	helper.initialiseWizard(cmp);
    },


	// Show desired step in the path
	setStep : function (cmp, event, helper) {
		var x = event.target.id;
		
		// Obtain step number to use from ID - which varies depending exactly what got the click event
		x = x.replace('WizPathLabel_', '');
		x = x.replace('WizPathLink_', '');
		
		// Set this step
		cmp.set("v.StepNum", parseInt(x));
	},
	

	// NOT YET IN USE: Cue a pass through 'to order' from a non-IA component
	createPassThrough : function (cmp, event, helper) {
	},


    // Respond to requests to deal with pass through clicks etc.
    handlePassThroughs : function (cmp, event, helper) {

        var act = event.getParam("ActionCode");
        var src = event.getParam("SourceComponent");
        var parms = event.getParam("Parameters");
        
        try {

			// Special cases:
			
			// Dialogues will not be 'our own' as they're not 'us' (they're a dialogue component):
			// however, if we recognise the component ID we can act: dialogues to be used in wizard steps
			// should be given a component ID of:
			//		[Wizard component ID]_[Component Gen ID]
			// ... where [Component Gen ID] is either LComp or RComp
			
			if (act === 'DialogueRequestClose' && src.startsWith(cmp.get("v.ComponentId") + '_')) {
				
				var CGID = src.split(cmp.get("v.ComponentId") + '_').join('');
				var CGs = cmp.find(CGID);
				var CG = CGs[cmp.get("v.StepNum")];	
				CG.set("v.ComponentDef", "");
				
			}


	        // Certain actions should only provoke response if they're our own (and require a Component ID)
	        if (src != '' && src != null && helper.eventIsOurOwn(cmp, event)) {
	        
	        	// 
		        if (act === 'addTopicText') {
		        	helper.addTopicText(cmp, event);
		        }	    
		        
	        	// 
		        if (act === 'setName') {
		        	helper.setName(cmp, event);
		        }	        
		            
	        	// 
		        if (act === 'setSummary') {
		        	helper.setSummary(cmp, event);
		        }	        
	
	        	// 
		        if (act === 'setDescription') {
		        	helper.setDescription(cmp, event);
		        }	        
	
	        	// 
		        if (act === 'saveAll') {
		        	helper.saveAll(cmp, event);
		        }	        
	
	        	// 
		        if (act === 'DeleteTopics') {
		        	helper.deleteTopics(cmp, event);
		        }	   
		
				// Create help context info (HPLs, elements, tree topic and rels) as requested via wizard    
				if (act === 'createHelpCxts') {
					helper.createContextHelp(cmp, event, helper);
				}		             
	
	        }
	        
	        
	        // Certain actions should only fire if we're listening
	        if (helper.eventBeingListenedTo(cmp, event)) {
	        
		        // Request to display a certain wizard (via tree selector)
		        if (act === 'SelectTree') {
		        
		        	// Tree selection message includes "provider" info - not needed here
		        	parms = parms.split('^');
		        	cmp.set("v.WizardName", parms[0]);
		        	cmp.set("v.isInitialised", false);
		        	cmp.set("v.StepNum", 0);
		        }
	        }
        
        } catch (e) {
        	alert('Error - Wizard (PassThroughs): ' + e);
        }
        

    },


///////////////////////////////////////////////////////////////////////////
// Methods specific to particular wizards
///////////////////////////////////////////////////////////////////////////

	// At Bulk topic upload wizard step 2, select the topic text to work on
	setCachedRecord : function (cmp, event, helper) {
		var x = event.target.id;
		x = x.replace('topicSelector', '');
		cmp.set("v.CachedRecNum", parseInt(x));
		
		var LC = helper.getStepComponent(cmp, -1, 'LComp');
		LC.set("v.FieldValue", cmp.get("v.CachedSelections")[cmp.get("v.CachedRecNum")]);

		// In selecting text to work on, also select the topic that is to hold it
		var ctlT = helper.getStepComponent(cmp, 1, 'RComp');
			
		ctlT.set("v.CurrentRecord", cmp.get("v.CachedRecords")[cmp.get("v.CachedRecNum")]);
		ctlT.set("v.Title", ctlT.get("v.CurrentRecord.Name"));
		ctlT.set("v.KeywordParsedDescription", ctlT.get("v.CurrentRecord.iahelp__Description__c"));		
	},
		
			
})