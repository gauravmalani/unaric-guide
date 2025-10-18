({

	// METHODS FOR TEXT AREA TYPE

	// Note the text a user has selected in our text area in accessible member data
	recordTextSelection : function (cmp, event, helper) {
		
		var val;
		var txt;
		
		try {
			txt = cmp.find("theTextArea").getElement();
			val = txt.value.substring(txt.selectionStart, txt.selectionEnd);
			
			cmp.set("v.SelectedText", val);

		} catch (e) {
			cmp.set("v.SelectedText", val + ': ' + e);
		}
		
	},
	
	
	// Set focus on our text area
	activateTextArea : function (cmp, event, helper) {
		cmp.find("theTextArea").getElement().focus();
	},
	
	
	// Set our Value member data in response to text change
	setValue : function (cmp, event, helper) {
		try {
			var txt = cmp.find("theTextArea").getElement();
			cmp.set("v.FieldValue", txt.value);
			
		} catch (e) {
			console.log('Improved Help text area - error (setValue): ' + e);
		}
	},
	 
	
	// Delete the currently selected text from our text area
	deleteSelection : function (cmp, event, helper) {
		
		var txt;
		var selStart;
		var selEnd;
		var txtIn;
		var txtOut;
		
		try {
			txt = cmp.find("theTextArea").getElement();
			selStart = txt.selectionStart;
			selEnd = txt.selectionEnd;
			txtIn = cmp.get("v.FieldValue");

			txtOut = txtIn.substring(0, selStart);
			txtOut += txtIn.substring(selEnd, txtIn.length);

			cmp.set("v.FieldValue", txtOut);

		} catch (e) {
			console.log('Improved Help text area - error (deleteSelection): ' + e);
		}
		
	},


	// METHODS FOR INPUT TYPE

	// Switch between editing and viewing on control click
	toggleMode : function (cmp, event, helper) {
		
		if (cmp.get("v.Mode") == 'View') {
			cmp.set("v.Mode", 'Edit');
			
			// On entry to label editing, set input text box width
			helper.setTextboxWidth(cmp, event, helper);
		} else {
			cmp.set("v.Mode", 'View');
		}
	},
	
	
	// Announce the fact that our field value has changed (so client components can save or take note)
	fieldValueChange : function (cmp, event, helper) {
	
		var rec = cmp.get("v.recordId");
		var fld = cmp.get("v.FieldName");
		var val = cmp.get("v.FieldValue");
		
	    var appEvent = $A.get("e.c:evtPassThrough");
	    appEvent.setParams({"SourceComponent": rec});
	    appEvent.setParams({"ActionCode": 'FieldValueChange'});
	    appEvent.setParams({"Parameters": fld + '^' + val});
	    appEvent.fire();
	    
	    
	},
	
	
    // To set the Width of input box Dynamically.
    setTextboxWidth : function(cmp, event, helper){  
        helper.setTextboxWidth(cmp, event, helper);        
    }

})