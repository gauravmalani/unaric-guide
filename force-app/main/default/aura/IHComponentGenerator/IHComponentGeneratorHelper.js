({

	// Rebuild the component to its current definition
	initialiseCmp : function(cmp, event, helper) {
	
        var Delimiter = cmp.get("v.MyDelimiter");
        var D1 = Delimiter.substring(0,1); // ':'; For namespace before component name
        var D2 = Delimiter.substring(1,2); // '~'; For Attribute separation from component name
        var D3 = Delimiter.substring(2,3); // '¬'; For separation of Attribute name and it's value
        var D4 = Delimiter.substring(3,4); // '|'; For separation of one Attribute name value from another
        
        // Obtain component definition from our member data
        var ComponentDef = cmp.get("v.ComponentDef");
        var aMap;
        var ComponentParams;
             
        
        // If we have no config data, do nothing here
        if (ComponentDef == '' || ComponentDef == null) {return;}
	
    	try {            

			// Definition should be in the form:
			// ns:type ~ [PARAMS]
			// ... where [PARAMS] are in the form:
			// name ¬ value |
				
			ComponentParams = ComponentDef.split(D2);
			console.log('IH Dynamic Component Generator: Definition: ' + ComponentDef);				
			console.log('IH Dynamic Component Generator: Component to create: ' + ComponentParams[0]);				
			console.log('IH Dynamic Component Generator: Parameters: ' + ComponentParams[1]);				

			// Allow for suppression of powered by branding
			if (cmp.get("v.SuppressPoweredBy") == true) {
				if (ComponentParams[1].endsWith(D4)) {
					ComponentParams[1] += 'SuppressPoweredBy'+D3+'true';
				} else {
					ComponentParams[1] += D4+'SuppressPoweredBy'+D3+'true';
				}
			}
			

			// Allow for branding to be specified by parent
			if (cmp.get("v.UXTheme") != '') {
				if (ComponentParams[1].endsWith(D4)) {
					ComponentParams[1] += 'UXTheme'+ D3 + cmp.get("v.UXTheme");
				} else {
					ComponentParams[1] += D4 + 'UXTheme'+ D3 + cmp.get("v.UXTheme");
				}
			}

	
			aMap = helper.getParmsMap(cmp, ComponentParams[1]);
			console.log('IH Dynamic Component Generator: Resulting map: ' + aMap);				
		
        	$A.createComponent(ComponentParams[0], aMap, function(newComp, status, errorMsg) {
        		if(status === 'SUCCESS') {
            		var b = cmp.get("v.body");
            		b = [];            		
            		b.push(newComp);
            		cmp.set("v.body", b);
            		
            		// Keep note of the created component
            		cmp.set("v.theComponent", newComp);
            		console.log('IH Dynamic Component Generator: Component generated: ' + newComp);
            		
            		return newComp;

        		} else {
    				console.log('IH Dynamic Component Generator: ERROR: ' + errorMsg);  
    				return '';          		
        		}
        	});

		} catch (e) {
			console.log('IH Dynamic Component Generator: ERROR: ' +  e);
			return '';
		}            	

	},
	
	
	// Convert delimited parameters (Attribute [D1] Value [D2]) into an object for use in building LUX controls
    getParmsMap : function (cmp, parms) {
    	
        var Delimiter = cmp.get("v.MyDelimiter");
        var D1 = Delimiter.substring(0,1); // ':'; For namespace before component name
        var D2 = Delimiter.substring(1,2); // '~'; For Attribute separation from component name
        var D3 = Delimiter.substring(2,3); // '¬'; For separation of Attribute name and it's value
        var D4 = Delimiter.substring(3,4); // '|'; For separation of one Attribute name value from another
        var retVal;
        var i;
        var s = '';
        var Ps;
        var parm;
        var d1 = D4;
        var d2 = D3;
		var attrRef; 
		var attrName;
		var parentComp = cmp.get("v.Parent");
                
        try {
            Ps = parms.split(d1);
                
            for (i=0; i < Ps.length; i++) {
                parm = Ps[i].split(d2);
                
                if (parm[1] == 'true' || parm[1] == 'false') {
	                // Boolean parameters need special treatment (no enclosing quotes)
                    s += '"' + decodeURI(parm[0]) + '":' + decodeURI(parm[1]) + ',';
                    
                } else {
                    s += '"' + decodeURI(parm[0]) + '":"' + decodeURI(parm[1]) + '",';
                }
            }
                   
            s = s.substring(0, s.length - 1);
            s = '{' + s + '}';
    
            // Get an initial map object
            retVal = JSON.parse(s);


			// Replace literals in object with attribute bindings to parent values where required: 
			// these will be specified as standard LUX parameters - i.e., {!v.AttributeName}

			if (retVal.value + '' != 'undefined') {
				if(retVal.value.substr(0, 4) == '{!v.') {
					
					// Extract the name of the required attribute that is to be bound to value 
					attrName = retVal.value;
					attrName = attrName.split('{').join('');
					attrName = attrName.split('!').join('');
					attrName = attrName.split('}').join('');
					
					// Get a reference to this attribute from the parent comonent
					attrRef = parentComp.getReference(attrName);
					
					// Set the value field of the map object we're returning to this reference
					retVal.value = attrRef;
				}			
			}


			if (retVal.select + '' != 'undefined') {
				if(retVal.select.substr(0, 4) == '{!c.') {
					
					// Extract the name of the required attribute that is to be bound to value 
					attrName = retVal.select;
					attrName = attrName.split('{').join('');
					attrName = attrName.split('!').join('');
					attrName = attrName.split('}').join('');
					
					// Get a reference to this attribute from the parent comonent
					attrRef = parentComp.getReference(attrName);
					
					// Set the value field of the map object we're returning to this reference
					retVal.select = attrRef;
				}		
			}

        
        } catch (e) {
            retVal = '';
        }
        
        
        return retVal;
    },

    
    // Get the design attributes available for the selected component
    getAttributes : function(cmp, event, helper, compName){
        
        var act = cmp.get("c.getClickablesJSON");
        var perms;		// Hard coding author perms to test - but this should come from actual user's help permission setting level
        var cxt;
        var idx;
        
        
        // If user has Administrator access 
        if(cmp.get("v.isAdministrator") == true){
            perms = 8;
        }
        // If user has Author access
        else if(cmp.get("v.isAuthor") == true){
            perms = 4;
        }
        cxt = compName;
        cxt = cxt.split('^');
        idx = cxt[0];		// This is the 'bit' that should be 'on' in the bit switch represented by config item's tool filter
        
        act.setParams({ 
            "ToolContext" : 'CGDesignMode', 
            "ActionCode" : 'CGDesignAttributes',
            "IHContext" : idx,
            "userPermLevel" : perms
        });                       
        
        
        // Create a callback that is executed after the server-side action returns
        act.setCallback(this, function (response, cmp){
        
            var obj;   // Drop down tools
            var toolsD = [];
            var hasAttributes = false;
            var i;
            
            console.log('Requesting attributes for selected component');
            console.log('response===>>',response.getReturnValue());
            
            try {
                obj = JSON.parse(response.getReturnValue());
            } catch (e) {
                console.log('error',e);                
            }
            
            for (i = 0; i<obj.length; i++) {
                try {
                    var s = obj[i].attributes.type;
                    hasAttributes = true;
                } catch (e) {
                    hasAttributes = false;
                }
            
                if(hasAttributes == true){
                    if (obj[i].attributes.type === 'iahelp__ConfigurationItem__c'){
                        switch (obj[i].iahelp__Type__c) {
                            case 'Drop-down':
                                toolsD.push(obj[i]);
                                break;
                        }
                    }  
                } 
                
            }    
             
            console.log('toolsD====>>>',toolsD);
            
            cmp.set("v.listItems", toolsD);
            console.log(cmp.get("v.listItems"));
            this.populateAttributesList(cmp, event, helper);
        });  
        $A.enqueueAction(act);              
    },
    
    
    // Produce the list of attributes to be made available as pick list values in the UX from the configuration tools data obtained elsewhere
    populateAttributesList : function(cmp, event, helper){
        
        var lstItems = cmp.get("v.listItems");
        var opts = [];
        var opt;
        var i;
        
        
        for(i = 0; i < lstItems.length; i++){
            opt = {
            		"label" : lstItems[i].iahelp__TipText__c, 
            		"value" : lstItems[i].iahelp__Label__c, 
            		"help" : lstItems[i].iahelp__Description__c, 
            		"Type" : lstItems[i].iahelp__SupportingControls__c
    		};

            opts.push(opt);
        }
        
        // Sort options alphabetically
        if(opts.length > 0){
        	for(i = 0; i < opts.length; i++) {    
        		for(var j = i+1; j < opts.length; j++){    
                    if(opts[j].label < opts[i].label){    
                        var temp = opts[i];    
                        opts[i] = opts[j];    
                        opts[j] = temp;     
                    }     
                }     
            }
            cmp.set("v.AttributeNames", opts);
        }
    },
    
    
    // Obtain key internationalisation codes 
    getInternationalisations : function (cmp, event, helper) {
    	    	
		// Only do this once / if codes unset
		if (cmp.get("v.AdviceLabelCGStep1") == '') {

			var act = cmp.get("c.getInternationalisations");	
			act.setParams({
				"DlgName": 'CGDesignMode'
			});
  	         
			// Add callback to show returned results
			act.setCallback(this, function (response,cmp){
   
				if (response.getState() === "SUCCESS") {
	                var result = response.getReturnValue();
	                var i;
	                var obj;
             
	                // Return value is JSON - parse this into objects for aura iteration...
	                try {
	                    obj = JSON.parse(response.getReturnValue());
	                    
	                } catch (e) {
	                    console.log("Error parsing the following return value (" + e + "): " + response.getReturnValue());
	                    
	                    // Avoid further calls
	                    cmp.set("v.AdviceLabelCGStep1", '---');
	                    return;
	                }
             
	                if ('' + obj.length === 'undefined') {
	                    obj = new Array(obj);
	                }
	                         
	                for (i = 0; i<obj.length; i++) {
               
	                	if (obj[i].ValueSet == 'Internationalisations') {
                    
							if (obj[i].Name == 'AdviceLabelCGStep1') {cmp.set("v.AdviceLabelCGStep1", obj[i].Value);}
							if (obj[i].Name == 'AdviceLabelCGStep2') {cmp.set("v.AdviceLabelCGStep2", obj[i].Value);}
							if (obj[i].Name == 'AdviceLabelCGStep3') {cmp.set("v.AdviceLabelCGStep3", obj[i].Value);}
							if (obj[i].Name == 'ButtonGenerate') {cmp.set("v.ButtonGenerate", obj[i].Value);}
							if (obj[i].Name == 'TipAttrAdd') {cmp.set("v.TipAttrAdd", obj[i].Value);}
							if (obj[i].Name == 'TipAttrDelete') {cmp.set("v.TipAttrDelete", obj[i].Value);}
							if (obj[i].Name == 'TitleSubtitleCGStep3') {cmp.set("v.TitleSubtitleCGStep3", obj[i].Value);}
							if (obj[i].Name == 'TipCueContextHelp') {cmp.set("v.TipCueContextHelp", obj[i].Value);}
							
	                	}
	                }
				}//state success

			});
			// Send action
			$A.enqueueAction(act); 

		}
    },

    
})