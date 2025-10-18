({    
	
	// On load initialisation routine - obtain clickables and initial keywords then wite up platform events
    doInit : function(cmp, event,helper) {
      	console.log('IHKeyword component "' + cmp.get("v.ComponentId") + '" initialising...');
        cmp.initialise(cmp, event, helper);
        cmp.subscribe(cmp, event, helper);
    },
    
    
    // Obtain card clickables
    initialise : function(cmp, event,helper) {
        var action = cmp.get("c.getTools");
        
        // At component initialisation (as opposed to re-initialisation to obtain keywords)
        // we only want to get tools - no keywords until we are provided text to analyse
        
        cmp.set("v.ActionCode", "ToolsOnly");		//GetKeywords
        
        action.setParams({ 

			"IHContext" : '', 
            "ToolContext" : 'CardKeywords', 
            "ActionCode" : cmp.get("v.ActionCode"),
            "ClientComponentId" : cmp.get("v.ComponentId"),
            "Params" : '',
            "SkipGlobals" : false,
        });                       


        // Create a callback that is executed after the server-side action returns
        action.setCallback(helper, function (response, cmp){
            helper.processTools(response, cmp, false);
            
            // Post process certain internationalisations etc
            cmp.set("v.AdviceLabelSentenceMode", helper.Internationalise(cmp, "AdviceLabelKeywordSentenceMode"));
            
            // Having obtained tools, obtain keywords if required
            cmp.reInitialise(cmp, event, helper);
            
    	})
       $A.enqueueAction(action);                 
    },
    
    
    // This is the 'entry point' / public method clients can use to obtain suggested keywords from the 'textValue' member data supplied
    reInitialise : function(cmp, event, helper) {
    
    	// If we have no text, bail
    	if (cmp.get("v.textValue").length == 0) {
    		console.log('IHKeywords - no content to analyse: call to obtain keywords skipped');
    		return
    	}
    	
        helper.showSpinner(cmp);
        if(cmp.get("v.textValue").length > 10000){
            cmp.set("v.operationMode",'asynchronous');
        }
        
        console.log(' operation mode is : '+cmp.get("v.operationMode"));
        
        var action = cmp.get("c.getKeywords");
        action.setParams({  
       		"InputText" : cmp.get("v.textValue"),
            "QualityThreshold" : cmp.get("v.qualityThresholdOfKeywords"),
            "MaxPhraseLength"  : cmp.get("v.MaxPhraseLength"),
            "DesiredAnalysers" : 'ServiceIntelligence.analyseWordCount,ServiceIntelligence.analyseCapitals,ServiceIntelligence.analyseMultiWordPhrases,ServiceIntelligence.findExisitingKeywords',        
            "OperationMode"    :  cmp.get("v.operationMode")
     	});   
        
        action.setCallback(this, function(a) {

            try {
                var obj = JSON.parse(a.getReturnValue());
                
                // Ensure you have suggested keywords before assuming event content is suitable!
// TO DO: need to filter to our own events here!        
                
                if (obj.length > 0) {
                	if (obj[0].ActionCode == 'SuggestedKeyword') {
			            cmp.set("v.ListingItems", obj);
                        helper.hideSpinner(cmp);
                	}
                } else {
                	// Single object?
                	console.log('GUID '+obj.MasterId);
                	if (obj.ActionCode == 'SuggestedKeyword') {
			            cmp.set("v.ListingItems", obj);
			          	helper.hideSpinner(cmp);  
                        cmp.set("v.GUID",obj.MasterId);
                	}
                }
                
                cmp.set("v.Diags", helper.Internationalise(cmp, 'MessageGenericOK'));
                
            } catch(e){
            	// Not JSON                
                console.log(e);
                cmp.set("v.Diags", helper.Internationalise(cmp, 'MessageGenericError') + ': ' + e);
                 
            }
            helper.hideSpinner(cmp);
        })
        $A.enqueueAction(action);

    },
    
    
    // This method is used to make selection and deselection of keywords and event firing
    keywordClick: function (cmp, event, helper) {
         
        var select = event.currentTarget;
        var selectedKeywordsList = [];
        var selectedKeywords;
        
        
        // Toggle 'selected' class on clicked item
        select.classList.toggle('tagged');        
        
        // Obtain all selected lozenges
        if(select.classList.contains('tagged')){
        	select.style="Background : #"+cmp.get("v.selectedColour1")+" !important";
        }else{
            select.style="Background : #"+cmp.get("v.deselectedColour")+" !important";
        }        
        selectedKeywords = $('.tagged');  
        
        
        // Record each selection in member data
        selectedKeywords.each(function(index,value) {
            try{
            	selectedKeywordsList.push(value.firstChild.nodeValue);
            }catch(e){}
		});		
        cmp.set("v.selectedKeywordsList",selectedKeywordsList);
        
        
        // If in 'sentence' mode, show sentences featuring the selected keywords
        if(cmp.get("v.SentenceMode")){
            helper.buildSentences(cmp, event, helper);
        }
        
        // In all cases, advise interested parties that keyword selections have been made
        var appEvent = $A.get("e.c:evtPassThrough");
        appEvent.setParams({"SourceComponent": cmp.get("v.ComponentId")});
        appEvent.setParams({"ActionCode": 'KeywordClicked'});
        appEvent.setParams({"Parameters": selectedKeywordsList});
        appEvent.fire();
        
    },
    
    
    // Handle pass throughs from sub-components etc.
    handlePassThroughs : function (cmp, event, helper) {    	
        
        var act = event.getParam("ActionCode");
        var src = event.getParam("SourceComponent");
        var parms = event.getParam("Parameters");
        
    	console.log('Keywords component: received passthrough: "' + act + '" from "' + src + '" with parameters "' + parms + '"');
		
		switch (act) {


            case 'MarkThisAsNoise':
            	// Record the words represented by current lozenge selections as 'noise' to be
            	// ignored in any future analyses of keywords:
            	
                console.log(" MarkThisAsNoise clicked! : "+cmp.get("v.selectedKeywordsList"));
                 try{
                     var strlist = cmp.get("v.selectedKeywordsList");
                    var action = cmp.get("c.addToNoiseList");
                    action.setParams({  
                        "strlist" : strlist
                    });   
                
                    action.setCallback(this, function(a) {
                        console.log(a.getReturnValue());
                        if(a.getReturnValue() == 'success'){
                           cmp.reInitialise(cmp, event, helper); 
                        }
                            })
                       $A.enqueueAction(action);
                     }
                     catch(e){
                         console.log(e);
                     }
                 break;
                 
             case 'ToggleSentenceView':
            	 // Switch sentence viewing mode on / off
                 cmp.set("v.SentenceMode",!cmp.get("v.SentenceMode"));
                 helper.buildSentences(cmp, event, helper);
                 break;
        }
    
    },     
    
    
    // Wire up platform events so we can respond to asynchronous keyword results
    subscribe : function(cmp, event, helper) {
    
        // Get the empApi component
        const empApi = cmp.find('empApi');
        
        // Get the channel from the input box
        const channel = cmp.get("v.channel");
        
        // Replay option to get new events
        const replayId = -1;

        // Subscribe to events
        empApi.subscribe(channel, replayId, $A.getCallback(eventReceived => {
        
            // Process event (this is called each time we receive an event)
            console.log('IHKeywords - received platform event:');            
            
            try{
	            var obj = [];
	            var jsonstring = eventReceived.data.payload.iahelp__Parameters__c; 
	            var GUID = eventReceived.data.payload.iahelp__Filter__c;    
	
	            console.log(jsonstring);
	            console.log(' Event Filter GUID = ' + GUID);

            	obj = JSON.parse(jsonstring);            	
            	
                // Ensure you have suggested keywords before assuming event content is suitable!
            	// Also, filter to our own events (by checking GUID from payload)               
                if (GUID == cmp.get("v.GUID")) {
                	if (obj[0].ActionCode == 'SuggestedKeyword') {
                	
                		// If we got keywords and they're the result of our query, set member
                		// data used to display suggestion lozenges
			            cmp.set("v.ListingItems", obj);
            			helper.hideSpinner(cmp);
                	}
                }
            	
        	}
            catch(e){
            	console.log('IHKeywords error: ' + e);
        	}
        }))
 
    },
            
            
})