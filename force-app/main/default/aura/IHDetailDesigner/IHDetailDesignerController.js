({
	
	// Obtain internationalisations, note initial layout info string, build layout from this
	init : function(cmp, event, helper) {
	
		//var BEL = String.fromCharCode('07');
		var BEL = '£';        
        var newDelimiter = ':~'+BEL+'#';

        console.log('IH Detail Designer - Setting Delimiter '+newDelimiter);
        cmp.set("v.MyDelimiter",newDelimiter);
        
        console.log('IH Detail Designer - Initialising with Layout Info "' + cmp.get("v.LayoutInfo") + '"');             
        
        //Holding LayoutInfo value before making amendments
        if(cmp.get("v.LayoutInfoBackup")==''){
	    	cmp.set("v.LayoutInfoBackup", cmp.get("v.LayoutInfo"));
        }
		
        //Internationalisation call
	    helper.doInternationalisation(cmp, event, helper);

		helper.setupLayout(cmp, event, helper);
	},

	
	// Respond to entry to layout design mode: get field list for
	// use populating layout editor pick lists
    handlePassThroughs : function (cmp, event, helper) {
    
        var act = event.getParam("ActionCode");
        var parms = event.getParam("Parameters");
        var src = event.getParam("SourceComponent");        
        var flag = false;
        
        console.log('IH Detail Designer - Handle Pass Through "' + act+ '" with parameters "' + parms + '"');
        
        
        if(act =='DetailDesignerAddRow' || act =='DetailDesignerDeleteRow'){

        	var Rows = cmp.get("v.Rows");
            var rIdx = 0;
            var fIdx = 0;
            var parameter = parms;
	       	var LDef = '';
            var Flds = '';
            
            // Write this change back into our layout member data:
            var delims = cmp.get("v.Delimiters");
            
            var D1 = delims.substring(0,1); //'|';		// Row sep
            var D2 = delims.substring(1,2); //'¬';		// Col sep
            var D3 = delims.substring(2,3); //',';		// Field sep
            var D4 = delims.substring(3,4); //'^';		// Field attr sep    
            
            try {
                Rows.forEach(function (R){
                    	
	                Flds = R.Fields;                       
	                Flds.forEach(function (F){
	                	if (act =='DetailDesignerAddRow') {
	                		// Retain existing definition
	                        LDef += F.Def + D4 + F.Type + D4 + F.Style;
	                        if(rIdx != parameter){
	                            if(R.RowEnd == 1){
	                                LDef += D1;        
	                            } else{
	                            	LDef += D2;  
	                            }
	                        } else {
	                        	LDef += D1;
	                        }
	                    }
                            
                            
                        if (act =='DetailDesignerDeleteRow' && R.RowNumber!=parameter){
                            // Retain existing definition
                            LDef += F.Def + D4 + F.Type + D4 + F.Style;
                            if(R.RowEnd == 1){
                            	LDef += D1;        
                            } else{
                                LDef += D2;  
                            }
                        }
                    }); 	// End loop around this row's fields
                        
                    //Adding new row after the row on which button is clicked
                 	if (act =='DetailDesignerAddRow' && rIdx == parameter) {
                    	LDef += '' + D4 + '' + D4 + '' + D1;
                    }
                        
                    rIdx += 1;
                    
                });		// End loop around rows
                
                //Removing '|' from end of the string
                LDef = LDef.substring(0,LDef.length-1);
                console.log('IH Detail Designer - new component definition will be set to: ' + LDef);
                
            } catch (e) {
                console.log('IH Detail Designer - add/delete row error: ' + e);
            }
        
			// Now re-apply the member data:
			// Set latch here to avoid recursion of on-change handlers
            cmp.set("v.isInitialised", false);
            cmp.set("v.LayoutInfo", LDef);
            helper.setupLayout(cmp, event, helper); 
        }
        
        
        if(act =='DetailDesignerAddColumn' || act =='DetailDesignerDeleteColumn'){

        	var Rows = cmp.get("v.Rows");
        	console.log(Rows);
        	
            var rIdx = 0;
            var fIdx = 0;
            var parameter = parms;
           	var LDef = '';
            var Flds = '';
        	var rowOfButtonClicked = parameter.split('_')[0];
        	var columnOfButtonClicked = parameter.split('_')[1];

            // Write this change back into our layout member data:
            var delims = cmp.get("v.Delimiters");
            
            var D1 = delims.substring(0,1); //'|';		// Row sep
            var D2 = delims.substring(1,2); //'¬';		// Col sep
            var D3 = delims.substring(2,3); //',';		// Field sep
            var D4 = delims.substring(3,4); //'^';		// Field attr sep    
            
            try {
                Rows.forEach(function (R){
			
                    Flds = R.Fields;
                    fIdx = 0
                    Flds.forEach(function (F){
                        if(rIdx+'_'+fIdx == parameter && act=='DetailDesignerDeleteColumn'){
                            //Do nothing
                       		//Removing delimiter from end of the string to add the delimiter associated with the deleted column
                            if(LDef[LDef.length-1]!='|'){
                                LDef = LDef.substring(0,LDef.length-1);
                                if(R.RowEnd == 1){
                                    LDef += D1;        
                                } else {
                                    LDef += D2;  
                                }
                            } 
                        } else {
                            // Retain existing definition
                    		LDef += F.Def + D4 + F.Type + D4 + F.Style;
                            if(R.RowEnd == 1){
                                LDef += D1;        
                            } else {
                                LDef += D2;  
                            }
                        }
                        fIdx += 1;
                        
                    });	// End loop around this row's fields
                    
                    
					if (act =='DetailDesignerAddColumn' && rIdx == parseInt(rowOfButtonClicked)+parseInt(columnOfButtonClicked)) {
                        //Removing '|' from end of the string
                        var DelimeterOfLastElement = LDef.substring(LDef.length-1,LDef.length);
                		LDef = LDef.substring(0,LDef.length-1);
                        LDef += D2 +'' + D4 + '' + D4 + '' + DelimeterOfLastElement;
                    }
				
					rIdx += 1;
					
				});		// End loop around rows
				
				
                //Removing '|' from end of the string
                LDef = LDef.substring(0,LDef.length-1);
                console.log('IH Detail Designer - new component definition will be set to: ' + LDef);
                
            } catch (e) {
                console.log('IH Detail Designer - add/delete column error: ' + e);
            }
        
			// Now re-apply the member data:
			// Set latch here to avoid recursion of on-change handlers
            cmp.set("v.isInitialised", false);
            cmp.set("v.LayoutInfo", LDef);
            helper.setupLayout(cmp, event, helper); 
        }
        
        
        if (helper.eventIsOurParents(cmp, event)) {
	        if (act == 'DesignModeOn') {
                //Internationalisation call
                helper.doInternationalisation(cmp, event, helper);
                
	        	// Obtain design attributes if not already done
	        	if (cmp.get("v.DesignerAttributes").length == 0) {
	        		
	        		var act = cmp.get("c.getFieldList");
	        		var DAs = [];
	        		var obj;
	        		var i;
	        		
			        act.setParams({ 
			            "ObjectAPIName" : "iahelp__HelpTopic__c", 
			        });                       


			        // Create a callback that is executed after the server-side action returns
			        act.setCallback(helper, function (response, cmp){

		            	if (response.getState() === "SUCCESS") {

				            try {
			            	
					            try {
									obj = JSON.parse(response.getReturnValue());
					            } catch (e) {
									//alert('Error parsing the following return value (' + e + '): ' + response.getReturnValue());
									return;				                
					            }
					            
					            if ('' + obj.length === 'undefined') {
					                obj = new Array(obj);
					            }
					
					
					            for (i = 0; i<obj.length; i++) {
									if (obj[i].ValueSet == 'FieldList') {
										DAs.push({label: obj[i].Value, value: obj[i].Name});
									}
								}
								
                                console.log('Before sorting...');
                                console.log(DAs)
                                
                              //Sorting Algorithm ----------------- Start
                                for(i = 0; i < DAs.length; i++)    
                                {    
                                  for(var j = i+1; j < DAs.length; j++)    
                                    {    
                                        if(DAs[j].label < DAs[i].label)    
                                        {    
                                            var temp = DAs[i];    
                                            DAs[i] = DAs[j];    
                                            DAs[j] = temp;     
                                        }     
                                    }     
                                }
                              //Sorting Algorithm ----------------- End 
                                console.log('After sorting...');
                                console.log(DAs);
								cmp.set("v.DesignerAttributes", DAs);
			            	
			            	} catch (e) {
			            		alert('IH Detail Designer - Error: ' + e);			            	
			            	}
		            		
		            	} else {
		            		// Server fail
		            		//alert('Server fail');			            	
		            	}
			            
	            	});
	            	
	            	$A.enqueueAction(act);
	        		
	        	}
	        	
	        	// Enter design mode
	        	cmp.set("v.DataMode", 'Design');
	        }
	
	        if (act == 'DesignModeOff') {
	        	cmp.set("v.DataMode", 'View');
	        }
        }
        
    },
    

    // In design mode, write changes to layout parameter data back to layout definition iterables
    paramChange : function (cmp, event, helper) {
    
    	// Avoid recursion / allow latch out of change handler
    	if (cmp.get("v.isInitialised") == false) {
    		return;
    	}
    	
    	var LDef;
    	var Rows = cmp.get("v.Rows");
    	var Flds;  
    	var src = event.getSource().get("v.name");
    	var NewVal = event.getSource().get("v.value");
    	var elemDef = src.split('_');
    	var RChanged = parseInt(elemDef[0]);
    	var FChanged = parseInt(elemDef[1]);
    	var ElemChanged = elemDef[2];

    	console.log('IH Detail Designer - Param change: Row ' + RChanged + ' Field ' + FChanged + ' Element ' + ElemChanged + ' changed to "' + NewVal + '"');
    	console.log(Rows);
    	
    	// Write this change back into our layout member data:
    	var delims = cmp.get("v.Delimiters");
    	
    	var D1 = delims.substring(0,1); //'|';		// Row sep
    	var D2 = delims.substring(1,2); //'¬';		// Col sep
    	var D3 = delims.substring(2,3); //',';		// Field sep
    	var D4 = delims.substring(3,4); //'^';		// Field attr sep    	
		var rIdx = 0;
		var fIdx = 0;
		LDef = '';
		
		try {
			Rows.forEach(function (R){

				Flds = R.Fields;
				fIdx = 0;
				Flds.forEach(function (F){
				
					if (rIdx == RChanged && fIdx == FChanged) {

						// Amend value in play in this field
						switch (ElemChanged) {
							case 'Type':
								LDef += F.Def + D4 + NewVal + D4 + F.Style;
								break;
								
							case 'Source':
								LDef += NewVal + D4 + F.Type + D4 + F.Style;
								break;
			
							case 'Style':
								LDef += F.Def + D4 + F.Type + D4 + NewVal;
								break;                                                          	
						}
						
						// Adding '|' at end of the string 
                        if (R.RowEnd == 1){
                            LDef += D1;
                        } else {
                            LDef += D2;
                        }
						
					} else {
						// Retain existing definition
						LDef += F.Def + D4 + F.Type + D4 + F.Style;
                        if(R.RowEnd == 1){
                            LDef += D1;        
                        } else {
                            LDef += D2;  
                        }
					}
				
					fIdx += 1;
				});		// End row's fields loop
			
				
				rIdx += 1;
                
			});		// End row loop
			
            //Removing '|' from end of the string
			LDef = LDef.substring(0,LDef.length-1);
			console.log('IH Detail Designer - new component definition will be set to: ' + LDef);
		
		} catch (e) {
			console.log('IH Detail Designer - parameter change error: ' + e);
		}

    	console.log(Rows);
    	
    	// Now re-apply the member data:
    	// Set latch here to avoid recursion of on-change handlers
    	cmp.set("v.isInitialised", false);
		cmp.set("v.LayoutInfo", LDef);
    	helper.setupLayout(cmp, event, helper);
    	 
    },
    
    
    // Handler for add / delete row / column controls: raise appropriate pass through
    handleClick : function(cmp, event, helper) {
    
        var label = event.currentTarget.name;
        var id = event.currentTarget.id;
        var appEvent = $A.get("e.c:evtPassThrough");
        var ActionCode = '';
        var parms = id;
        
        if(label == 'Add Row'){
            ActionCode = 'DetailDesignerAddRow';
        }
        else if(label == 'Delete Row'){
            ActionCode = 'DetailDesignerDeleteRow';
        }
        else if(label == 'Add Column'){
            ActionCode = 'DetailDesignerAddColumn';
        }
        else{
            ActionCode = 'DetailDesignerDeleteColumn';    
        }
        
        console.log('IH Detail Designer - button click raising passthrough action: ' + ActionCode);
        
        
		appEvent.setParams({"SourceComponent" : 'IHDetailDesigner'});
		appEvent.setParams({"ActionCode": ActionCode});
		appEvent.setParams({"Parameters": parms});
		appEvent.fire();
	},


	// Save changes to layout design
    handleSave : function(cmp, event, helper) {
           
        var CurrentRecord = cmp.get("v.CurrentRecord");
        var Parms = cmp.get("v.LayoutInfo");    
        var parent = cmp.get("v.ParentControl");
        var parentHelper = cmp.get("v.ParentControlHelper");
        var userSuppliedName;
        var defaultName = '';
        var msg = '';

        
        if (CurrentRecord != null) {
        	defaultName = CurrentRecord.iahelp__Template__r.Name;
        }

		// Prompt user until we get a non-blank template name or they cancel
		do {
        	userSuppliedName = prompt(parentHelper.Internationalise(parent, "MessageEnterItemName"), defaultName);
		} while (userSuppliedName == '') 

        
        console.log('IH Detail Designer - Handle Save: template name = "' + userSuppliedName + '"');
        console.log('IH Detail Designer - Handle Save: amended layout definition = "' + Parms + '",  CurrentRecord: ' + CurrentRecord);
        
        
        if(userSuppliedName == null){
        	// User clicked cancel - do nothing
        	return;
        }
        
        //if (isNewHTTRequired != null) {

// If supplied name is that of current template, note the fact that this is an overwrite
if (userSuppliedName == defaultName) {
	userSuppliedName = '';
}
            
            var act = cmp.get("c.saveCustomTopicLayout");
            act.setParams({ 
				"HTID": CurrentRecord.Id,
				"layoutInfo" : Parms,
				"newTemplateName" : userSuppliedName,
			});                       
                    
            // Add callback to show returned results
            act.setCallback(helper, function (response, cmp){
            	if (response.getReturnValue() == '') {                            
            		msg = parentHelper.Internationalise(parent, 'MessageSaved');
                        	
                    cmp.find('notifLib').showToast({
                        "title": userSuppliedName,
                        "message": msg
                     });
    
                } else {
                    console.log('IH Detail Designer - Error saving changes to layout design: ' +response.getReturnValue());
                    msg = parentHelper.Internationalise(parent, 'MessageGenericError') + ': ' + response.getReturnValue();

                    cmp.find('notifLib').showToast({
                        "title": userSuppliedName,
                        "message": msg
                     });
                }
                        
            }); 
                    
            // Send action
            $A.enqueueAction(act);
        //}	
    },
    
    
    // Cancel changes to layout design
    handleCancel : function(cmp, event, helper) {
    	
        var parent = cmp.get("v.ParentControl");
        var parentHelper = cmp.get("v.ParentControlHelper");
        
        // Obtain internationalisations from parent detail component
    	var msg = parentHelper.Internationalise(parent, 'MessageCancelWarning');
    	
        if (confirm(msg) == true) {
        	
        	// Revert layout to definition stored on initialisation
        	   cmp.set("v.LayoutInfo",cmp.get("v.LayoutInfoBackup"));
               helper.setupLayout(cmp, event, helper); 
            
        } else {
            // Do nothing
        } 
    },
    
    
    // Show / hide a copy of componnt generator in design mode when requested as part of detail layout design
    showComponentDesigner : function(cmp, event, helper) {
    
        var src = event.currentTarget.id;
        var idParam = src.split('_');
        var iHCompContainerId;
        var iHCompContainer;

        console.log('Detail Designer - Show Component Designer request from:  ' + src);

        // Locate and toggle visibility of the div containing the relevant component generator
        iHCompContainerId = idParam[0]+'_'+idParam[1]+'_IHCOMPContainer';
        iHCompContainer = document.getElementById(iHCompContainerId);

        console.log('Relevant containing DIV\'s ID is: ' + iHCompContainerId); 
        console.log(iHCompContainer);
        
        iHCompContainer.classList.toggle('slds-hide');
        
    },


	// Show media in new tab when clicked
	openMedia : function (cmp, event, helper) {
		
		try {
			var U = event.target.getAttribute('data-MediaURL');
			window.open(U);
		} catch (e) {
			console.log('Detail Designer - error opening full size media: ' + e);
		}
	},

     
})