({


    Init : function(cmp, event, helper) { 
      	
    	console.log('IHAlert - initialising... ');
    	
        try{
	        var pageRef = cmp.get("v.pageReference");
	        var title = pageRef.state.iahelp__title;
	        var Message = pageRef.state.iahelp__Message;
	        var ToolContext = pageRef.state.iahelp__ToolContext;
	        var Image = pageRef.state.iahelp__Image;
	        var Style = pageRef.state.iahelp__Style;
	        var Height = pageRef.state.iahelp__Height;
	        var componentDef = pageRef.state.iahelp__componentDef;
            
            
	        
	        if (Style + '' == 'undefined') {Style = 'Single Column';}
	        if (Height + '' == 'undefined') {Height = -1;}
	        
	        cmp.set("v.Title", title);
	        cmp.set("v.Message", Message);
	        cmp.set("v.ToolContext", ToolContext);
	        cmp.set("v.Image", Image);
	        cmp.set("v.Style", Style);
	        cmp.set("v.Height", Height);
	        cmp.set("v.componentDef", componentDef);
	        
        } catch (e){
        	console.log('IHAlert - error setting parameters from URL parameters: ' + e);
        }
        
    	helper.reInitialiseAlert(cmp, event, helper);
   		
    },
    
    reInitialiseAlert : function(cmp, event, helper){
       console.log(' reInitialiseAlert ');
	   helper.reInitialiseAlert(cmp, event, helper);
        
    },
    
    handlePassThroughs : function (cmp, event, helper) {
        console.log(' In IHAlert pass through handler');
    },


    menuItemClick : function (cmp, event, helper) {
		var target = event.currentTarget;
        var actioncode = target.getAttribute("data-actioncode");
        	console.log(cmp.get("v.ComponentId"));
            if(actioncode == 'AlertOK'){
                //if(actioncode == 'DialogueRequestClose'){
                var appEvent = $A.get("e.c:evtPassThrough");
                    appEvent.setParams({"SourceComponent": cmp.get("v.ComponentId")});	
                   // appEvent.setParams({"SourceComponent": 'Test_Dialogue'});    
                    appEvent.setParams({"ActionCode": 'DialogueRequestClose'});
                    appEvent.setParams({"Parameters": 'ModalContainer'});
                    appEvent.fire();
            }

		}
        
     
})