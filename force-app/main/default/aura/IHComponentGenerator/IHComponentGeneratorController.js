({
	
	// Obtain translations
	Init : function (cmp, event, helper) {
		helper.getInternationalisations(cmp, event, helper);
	},  
	
	
	// Build the desired item on load
	doneRendering : function (cmp, event, helper) {
	     
    	// Do this only once
    	if (cmp.get("v.isInitialised") == true) {return;}
    	cmp.set("v.isInitialised", true);
    	helper.initialiseCmp(cmp, event, helper);
	},
	
	
    // Wrapper allowing client LUX components to cue re-building
	reInitialise : function (cmp, event, helper) {
	    return helper.initialiseCmp(cmp, event, helper);
    },
    	
	
	// If definition is blanked, destroy our component
	ComponentDefChange : function (cmp, event) {

        var ComponentDef = cmp.get("v.ComponentDef");
	
        if (ComponentDef == '' || ComponentDef == null) {
        	cmp.set("v.body", []);
        	cmp.set("v.isInitialised", true);
        }	
	},
    
    
    // Update generator's definition from any value typed directly into definition text box
    updateComponentDef : function(cmp, event, helper){

       var updateCmpDefinition = event.currentTarget.value;
       cmp.set("v.ComponentDef",updateCmpDefinition);
       helper.initialiseCmp(cmp, event, helper); 
       
    },
  
    
    // Generate component definition string from the collection of attribute / value pairs as amended via UX
    generateComponentDef : function(cmp,event,helper){
    
        var Delimiter = cmp.get("v.MyDelimiter");
        var D1 = Delimiter.substring(0,1); // ':'; For namespace before component name
        var D2 = Delimiter.substring(1,2); // '~'; For Attribute separation from component name
        var D3 = Delimiter.substring(2,3); // '¬'; For separation of Attribute name and it's value
        var D4 = Delimiter.substring(3,4); // '|'; For separation of one Attribute name value from another
        
        var attNVList = cmp.get("v.attNameValuePairList");
        
        var componentName = cmp.get("v.ComponentSelected");
    	componentName = componentName.split('^')[1];
        var cmpdef = componentName + D2;


		// Take no action unless a component has been selected
		if (componentName == '' || componentName + '' == 'undefined') {
			return;
		}

        for (let x = 0 ; x < attNVList.length ; x++) {
              cmpdef += attNVList[x].attributeName + D3 +attNVList[x].attributeValue + D4;
         }
         
        cmpdef = cmpdef.substring(0,cmpdef.length-1);
        cmp.set("v.ComponentDef",cmpdef);
		console.log('compDefString====>>',cmp.get("v.ComponentDef"));
		
        // To generate the dynamic component after generate the string.
        helper.initialiseCmp(cmp, event, helper);
        
    },
    
    
    // Show / hide help for design atributes
	toggleHelp : function (cmp, event, helper) {
		cmp.set("v.HelpExpanded", ! cmp.get("v.HelpExpanded"));
	},

    
    // Respond to change in selected component, design attribute or attribute value 
    paramChange : function(cmp, event, helper){
        
        console.log(' paramChange called!');
        
        var index; // To store index of input box
        var ops; // To store input box name - index
        var attNameValList = cmp.get("v.attNameValuePairList"); //Fetching Attribute name and value pair list
        var name = event.getSource().get("v.name"); // To store input box name
        var value = event.getSource().get("v.value");// To store entered/selected value
     
        index = name.split('_')[1];
        ops = name.split('_')[0]
        console.log('val :'+value);
        
        if(ops == 'attName'){
            attNameValList[index].attributeName =  value;
            
			// If attribute changes, look up the appropriate help info from the AttributeNames member data
			// (which holds attribute pick list entries) 
			
			var attrs = cmp.get("v.AttributeNames");
			var act = cmp.get("c.getTopicViaHTID");
			var MTID;
			var obj;
			
			for (var i=0; i<attrs.length; i++) {
				if (attrs[i].value == value) {
				
					// Need at this point to obtain help topic info for the MTID that will be provided 
					// via configuration item description (now stored as attribute "help" - see helper.populateAttributesList)
					MTID = attrs[i].help;
					        
			        attNameValList[index].attributetype = attrs[i].Type;
			        
			        if(attrs[i].Type == null){
			            attNameValList[index].attributetype = ''; 
			            
			        }else{
			            if(attrs[i].Type.includes(",")){
			                var optionsList = attrs[i].Type.split(",");
			                attNameValList[index].attributetype = 'CustomPicklist'; 
			                attNameValList[index].attributedefaultvalues = optionsList;
			                attNameValList[index].attributeValue = optionsList[0];
			            }
			        }  
			    }
			        
			}

			act.setParams({ 
				"HTID" : MTID, 
			});                       
			

			// Create a callback that is executed after the server-side action returns
			act.setCallback(helper, function (response, cmp){
			    
			    try {
			    	obj = JSON.parse(response.getReturnValue());
					attNameValList[index].attributeHelp = obj.iahelp__Summary__c;
					attNameValList[index].attributeHelpId = obj.Id;
			       
			        
			    } catch (e) {
			    	attNameValList[index].attributeHelp = '- - -';
			    	attNameValList[index].attributeHelpId = '';
			    	
			    }
			    
			    cmp.set("v.attNameValuePairList",attNameValList);
			});
			$A.enqueueAction(act);

        
        } else if (ops == 'attValue'){
            attNameValList[index].attributeValue =  value;
            cmp.set("v.attNameValuePairList",attNameValList);
        
        } else {
			cmp.set("v.ComponentSelected", value);
			console.log('Component type changed! '+value); 
			helper.getAttributes(cmp, event, helper, value);	

			// If the component Type is changed
			var previousCondition = attNameValList.splice(1,attNameValList.length-1);
			attNameValList[0].attributeValue = '';
			attNameValList[0].attributeName = '';
			attNameValList[0].attributeHelp = '';
			attNameValList[0].attributeHelpId = '';
              
			cmp.set("v.attNameValuePairList",attNameValList);           
        }
      
    },
    
    
    // Add a new row to the UX to hold a component attribute / value pair
    addComponentAttribute : function(cmp, event, helper){
        
    	var newAttNameValue = {'attributeName' : '', 'attributeValue' : '', 'attributeHelp' : '', 'attributeHelpId' : ''};        
        var attributeList = cmp.get("v.attNameValuePairList");
        
        attributeList.push(newAttNameValue);
        cmp.set("v.attNameValuePairList",attributeList);
    },
    
    
    // Clear Attribute value pair on click of '-' button 
    removeComponentAttribute : function(cmp, event, helper){
        var attIndex = event.currentTarget.dataset.value;
        var AttNameValueList = cmp.get("v.attNameValuePairList");
                
		// Do not allow removal of last attribute row
		if (AttNameValueList.length == 1) {
			return;
		}
        
        const removedAtt = AttNameValueList.splice(+attIndex,1);
        cmp.set("v.attNameValuePairList",AttNameValueList);
    },
    
   
    
    
		
})