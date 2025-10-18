({

    // Handle pass-throughs - obtain branding and internationalisation info when this becomes available
    handlePassThroughs : function (cmp, event, helper) {
    	
        var act = event.getParam("ActionCode");
        var parms = event.getParam("Parameters");
        var src = event.getParam("SourceComponent");
        var isModeChange = false;


        // In certain cases, only respond to our own control:
        if (src == 'Topic') {
        
        	switch (act) {
        		case 'ComponentToolsProcessed':

        			// Obtain branding info from topic component, which should have requested them
        			var ctl = cmp.find("ctlTopic");
        			
        			cmp.set("v.TBrandTitle", ctl.get("v.GlobalSettings").iahelp__BrandTitle__c);
        			cmp.set("v.TBrandSubTitle", ctl.get("v.GlobalSettings").iahelp__BrandSubTitle__c);
        			cmp.set("v.TBrandImage", ctl.get("v.GlobalSettings").iahelp__BrandImage__c);
        			cmp.set("v.TBrandToolColour", ctl.get("v.GlobalSettings").iahelp__BrandColour6__c);
        			cmp.set("v.TipButtonConfigureSettings", ctl.get("v.TipButtonConfigureSettings"));
        			cmp.set("v.TipButtonHelpHome", ctl.get("v.TipButtonHelpHome"));
        			
        			// Set these even though tabs don't seem to be able to respond!!!!
        			cmp.set("v.TitleAllRelatedHelp", ctl.get("v.TitleAllRelatedHelp"));
        			cmp.set("v.TitleReadingLists", ctl.get("v.TitleReadingLists"));
        			cmp.set("v.TitleAllResources", ctl.get("v.TitleAllResources"));
        			cmp.set("v.TitleQuickLinks", ctl.get("v.TitleQuickLinks"));
        			
        			cmp.set("v.isUser", ctl.get("v.isUser"));
        			cmp.set("v.isAnalyst", ctl.get("v.isAnalyst"));
        			cmp.set("v.isAuthor", ctl.get("v.isAuthor"));
        			cmp.set("v.isAdministrator", ctl.get("v.isAdministrator"));

        			cmp.set("v.DefaultHelpTopic", '' + ctl.get("v.GlobalSettings").iahelp__DefaultHelpTopic__c);
        			
        			break;
        	}
    	}
    	
	},

	
})