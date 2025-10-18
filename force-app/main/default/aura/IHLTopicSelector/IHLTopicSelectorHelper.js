({

    // To set the Width of input box Dynamically.
    setTextboxWidth : function(cmp, event, helper){  
        
        var val;
        
        try {
        	val = document.getElementById('TagLabel').value;
        } catch (e){
        	// Prior to input text box rendering
        	val = cmp.get("v.FieldValue");
        }
        
        // To convert the input value length to pixel unit.
        var wPixels = ((val.length + 1) * 8); 
		var wChars;
        
        console.log('wPixels: ', wPixels);
        cmp.set("v.WidthPixels", wPixels);
        cmp.set("v.FieldValue", val);
        
	    // Set input text box character width based on value
	    wChars = val.length-3;
	    if (wChars < 1) {wChars = 1;}
	    cmp.set("v.WidthChars", wChars);
        
    }


})