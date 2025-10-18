({
    
     getLabel : function (cmp, event) {
        
    	 var state;
    	 var act = cmp.get("c.getInternationalisations");	
      
    	 act.setParams({
    		 "DlgName": 'iahelp__IHComment'
    	 });
      	         
         // Add callback to show returned results
        act.setCallback(this, function (response,cmp){
   
           state = response.getState();
            
             if (state === "SUCCESS") {
                var result = response.getReturnValue();
                var intl = [];				// Internationalisations       
                var i;
                var obj;
                 
                // Return value is JSON - parse this into objects for aura iteration...
                try {
                    obj = JSON.parse(response.getReturnValue());
                    
                } catch (e) {
                    console.log("Error parsing the following return value (" + e + "): " + response.getReturnValue());
                    return false;
                }
                 
                if ('' + obj.length === 'undefined') {
                    obj = new Array(obj);
                }
                         
                for (i = 0; i<obj.length; i++) {
                   
                    if (obj[i].ValueSet == 'Internationalisations') {
                        
                        intl.push(obj[i]);
                        
                        if (obj[i].Name == 'ButtonSubmit') {cmp.set('v.ButtonSubmit', obj[i].Value);}
                        if (obj[i].Name == 'TipButtonSubmit') {cmp.set('v.TipButtonSubmit', obj[i].Value);}
                        if (obj[i].Name == 'AdviceLabelEnterFeedback') {cmp.set('v.AdviceLabelEnterFeedback', obj[i].Value);}
                       
                    }
                }
             }//state success

        });
		// Send action
		$A.enqueueAction(act); 
        
    },
   


})