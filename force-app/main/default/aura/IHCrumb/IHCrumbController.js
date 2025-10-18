({

    // Prepare crumb trail on load
	init : function (cmp, event, helper) {
		helper.initialiseCrumbs(cmp, event);
	},
    
    
    // Method allowing others (e.g., a parent Tree control) to cause us to seek the crumbs applicable to current record
	initialiseCrumbs : function (cmp, event, helper) {
		helper.initialiseCrumbs(cmp, event);
	},
   
   
    // Raise a record selected event when a crumb is clicked 
    crumbClick : function (cmp, event, helper) {
    	  	
    	var provider = '';
    	var theTrails = cmp.get("v.CrumbTrails");
    	var theTrail = event.target.getAttribute("data-trailIndex");
    	var theRoot = theTrails[theTrail].Crumbs[0].Id;
    	var theCrumb = event.target.id;    	
    	console.log('crumbClick ');
    	// Issue a message advising tree of root
        var appEvent = $A.get("e.c:evtPassThrough");
        appEvent.setParams({"SourceComponent" : cmp.get('v.ComponentId')});
        appEvent.setParams({"ActionCode": "SelectTree"});
        appEvent.setParams({"Parameters": theRoot + '^' + provider});     
        appEvent.fire();
    	
    	// Tree will ignore root message if already at that root. 
    	// If it is not, root will change, firing a topic selected event on arrival
    	// which we should ignore and override with the desired topic.
    	
    	// Now change the selected item    	
        var appEvent = $A.get("e.c:selectTopic");       
        appEvent.setParams({"RecordId" : theCrumb});
        appEvent.setParams({"SourceComponent" : cmp.get('v.ComponentId')});
        appEvent.fire();
        
        // We should also re-build ourselves: if we were on a crumb that was reachable via only 1 trail, but
        // then clicked back to another crumb within it, that crumb may have more than 1 parent, which we must show...
        cmp.set("v.HelpRecordId", theCrumb);
        helper.initialiseCrumbs(cmp, event);
        
    },


	//Respond to the "select" event raised by trees (if we're listening to the source component)
    selectRecord : function (cmp, event, helper) {
        
        var theRecord = event.getParam("RecordId");        
        var theSource = event.getParam("SourceComponent");
        var listensTo = cmp.get('v.ListensTo');

        // Only respond to events that do not emanate from ourselves / do
        // emanate from the  "desired" master tree we wish to tie to
        if (listensTo != '' && listensTo + '' != 'null' && theSource == listensTo) {

            cmp.set("v.HelpRecordId", theRecord);
            helper.initialiseCrumbs(cmp, event);
            
        }
    },   
    
   
})