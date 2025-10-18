({

	// Process the LayoutInfo member into iterables that can be used to display topic details
	// or produce a layout editor
	setupLayout : function(cmp, event, helper) {

		console.log('IH Detail Designer - setupLayout entry');

		try {    	
	
	    	// Setup iterables based on form design member
	
	    	var def = cmp.get("v.LayoutInfo");
	    	var rec = cmp.get("v.CurrentRecord");
	    	var P = cmp.get("v.ParentControl");
	    	var Rows = [];
	    	var ColFields = [];
	    	var Cols = [];
	    	var Flds = [];
	    	var Atrs = [];
	    	var parsedFld;
	    	var lastColumnOfRow;
            var rowNumber = 0;
            
	    	var delims = cmp.get("v.Delimiters");
	    	
	    	var D1 = delims.substring(0,1); //'|';		// Row sep
	    	var D2 = delims.substring(1,2); //'¬';		// Col sep
	    	var D3 = delims.substring(2,3); //',';		// Field sep
	    	var D4 = delims.substring(3,4); //'^';		// Field attr sep
	
	    	
	    	if (def != '') {
	    		def = def.split(D1);
	    		
	    		// Rows of fields
	    		def.forEach(function(Row){
	    		
	    			// Columns in the row, each with 1+ field(s)
    				Cols = Row.split(D2);  
                    
	    			Cols.forEach(function(Col){
	    				
	    				ColFields = [];
	    				
	    				// Fields in the column
	    				Flds = Col.split(D3);
	    				
	    				Flds.forEach(function(Fld){

							// Parse each field, for safe presentation of values, should this be required
							try {
								// Only certain components provide this for now...
								if (P.get("v.IHCardType") == 'Detail') {
									P.set("v.sHTML", Fld);
									parsedFld = P.getSafeHTML();
								} else {
									parsedFld = Fld;
								}
							} catch(e){
								parsedFld = Fld;
							}
	    				
	    					Atrs = parsedFld.split(D4);
	    					
	    					if (Atrs[1] == 'Literal') {
			    				ColFields.push({Label: Atrs[0], Type: Atrs[1], Style: Atrs[2], Def: Atrs[0]});
			    				
	    					} else if (Atrs[1] == 'Component') {
	
								var lbl = Atrs[0];
								lbl = lbl.split('=').join(':');
								lbl = lbl.split('`').join('~');
								lbl = lbl.split('@').join('¬');
								lbl = lbl.split('\\').join('|');
		
			    				ColFields.push({Label: lbl, Type: Atrs[1], Style: Atrs[2], Def: Atrs[0]});
		    				
	    					} else {
			    				ColFields.push({Label: rec[Atrs[0]], Type: Atrs[1], Style: Atrs[2], Def: Atrs[0]});
	    					}
	    				});
	    				
                        Rows.push({Fields: ColFields, Columns: (12 - Cols.length) / Cols.length, RowEnd : 0, RowNumber: rowNumber});
	    			});
                    
                    //Marking Row End by setting RowEnd value of last column of row to 1
                    lastColumnOfRow = Rows.pop();
                    lastColumnOfRow.RowEnd = 1;
                    Rows.push(lastColumnOfRow);
                    console.log(lastColumnOfRow);
                    
                    rowNumber+=1;
	    		});
	    		
	    		//console.log('Rows===>>',Rows);
	    		cmp.set("v.Rows", Rows);
	    		cmp.set("v.Initialised", true);	
	    	}
	    	
		} catch (e) {
			console.log('IH Detail Designer - setupLayout error: ' + e);
		}    	

	},
	
 
 	// Returns a boolean indicating whether an event emanated from our parent component    
	eventIsOurParents : function (cmp, event) {

        var src = event.getParam("SourceComponent");
        var myParent = cmp.get("v.ParentControl");
        var myParentsID = myParent.get("v.ComponentId");
        
        return src == myParentsID;	
	},
	
	
    // Obtain internationalisations from parent detail component
    doInternationalisation : function(cmp, event, helper) {
        
    	var parent = cmp.get("v.ParentControl"); 
        var parentHelper = cmp.get("v.ParentControlHelper");
        
        try {        
	        cmp.set("v.ButtonSave", parentHelper.Internationalise(parent, 'ButtonSave'));
	        cmp.set("v.ButtonCancel", parentHelper.Internationalise(parent, 'ButtonCancel'));
	        cmp.set("v.FieldLabelDisplayType", parentHelper.Internationalise(parent, 'FieldLabelDisplayType'));
	        cmp.set("v.FieldLabelSource", parentHelper.Internationalise(parent, 'FieldLabelSource'));
	        cmp.set("v.FieldLabelComponentDefinition", parentHelper.Internationalise(parent, 'FieldLabelComponentDefinition'));
	        cmp.set("v.FieldLabelLiteralText", parentHelper.Internationalise(parent, 'FieldLabelLiteralText'));
	        cmp.set("v.FieldLabelStyleClass", parentHelper.Internationalise(parent, 'FieldLabelStyleClass'));
	        cmp.set("v.TipButtonAddColumn", parentHelper.Internationalise(parent, 'TipButtonAddColumn'));
	        cmp.set("v.TipButtonDeleteColumn", parentHelper.Internationalise(parent, 'TipButtonDeleteColumn'));
	        cmp.set("v.TipButtonAddRow", parentHelper.Internationalise(parent, 'TipButtonAddRow'));
	        cmp.set("v.TipButtonDeleteRow", parentHelper.Internationalise(parent, 'TipButtonDeleteRow'));
	        cmp.set("v.TipButtonSave", parentHelper.Internationalise(parent, 'TipButtonSave'));
	        cmp.set("v.TipGenericCancel", parentHelper.Internationalise(parent, 'TipGenericCancel'));
	        cmp.set("v.TipEdit", parentHelper.Internationalise(parent, 'TipEdit'));
	    } catch (e){}
    },
    
    
})