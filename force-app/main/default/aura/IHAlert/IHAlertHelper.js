({

	//Setup component
    reInitialiseAlert : function (cmp, event, helper) {
        console.log(' In Helper reInitialiseAlert');
        var rec = '';
    	var toolCxt = cmp.get("v.ToolContext");
    	var act = 'ok';
		this.refreshClickables(cmp, event, helper, rec, toolCxt, act);
        var cmpDef = '';
        try{
        cmpDef = cmp.get("v.componentDef");
        var CG = cmp.find("CGIHDetail");
		CG.set("v.ComponentDef", cmpDef);	
			CG.reInitialise();
        }catch(e){
            console.log('IHAlert : component generator error '+e);
        }
    },	
    
    // Re-obtain / refresh clickable tools, for cases where navigation may call for this
	refreshClickables : function (cmp, event, helper, theRecord, ToolContext, ActionCode) {
	

		var userPermLevel = 0;

/*			
        if (cmp.get("v.isUser") == true) userPermLevel += 1; 
        if (cmp.get("v.isAnalyst") == true) userPermLevel += 2; 
        if (cmp.get("v.isAuthor") == true) userPermLevel += 4; 
        if (cmp.get("v.isAdministrator") == true) userPermLevel += 8; 
*/

userPermLevel += 1;

        var act = cmp.get("c.getClickablesJSON");
        act.setParams({ 
            "ToolContext" : ToolContext, 
            "ActionCode" : ActionCode,
            "IHContext" : theRecord,
            "userPermLevel" : userPermLevel,
        });                       


        // Create a callback that is executed after the server-side action returns
        act.setCallback(helper, function (response, cmp){
            
            try {
            
				// Need to process globals to get internationalisations - however this will trash global settings:
				// So: obtain these prior and re-set after call

				var GS = cmp.get("v.GlobalSettings");
                var T = cmp.get("v.Title");
				helper.processTools(response, cmp, false);
                cmp.set("v.Title",T);
				cmp.set("v.GlobalSettings", GS);



            
            } catch (e) {
            }

        });                
		$A.enqueueAction(act);
	
	}
  
})