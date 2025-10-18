({

	//
	doInit : function(cmp, event, helper){
  
        cmp.set("v.UXThemeColour1","009eed");                  
       
        var action = cmp.get("c.getTools");
       
        cmp.set("v.ActionCode", "ToolsOnly");
        
        action.setParams({ 

			"IHContext" : '', 
            "ToolContext" : 'CardComment', 
            "ActionCode" : cmp.get("v.ActionCode"),
            "ClientComponentId" : 'theComment',
            "Params" : '',
            "SkipGlobals" : false,
        });                       


        // Create a callback that is executed after the server-side action returns
        action.setCallback(helper, function (response, cmp){
            helper.processTools(response, cmp, false);
            
            // Set some internationalisations and related furniture
            cmp.set("v.Title", helper.Internationalise(cmp, "TipCommentTopic"));
            cmp.set("v.NoDataMessage", helper.Internationalise(cmp, '[QAMValueSelectRecordStepName]'));

            cmp.set("v.ToolLabelRelatedHelp", helper.Internationalise(cmp, "ToolLabelRelatedHelp"));
            cmp.set("v.ToolLabelComment", helper.Internationalise(cmp, "ToolLabelComment"));
    	})
       $A.enqueueAction(action);   
        
        cmp.set("v.buttonIsEnable",false);
        
        helper.getLabel(cmp, event );

        // to get domain name of org.    
        var hostname = 'https://'+window.location.hostname+'/';
        cmp.set("v.pageDomain",hostname);
        
        cmp.initialiseComment(cmp, event, helper);
     },
            
            
    // This method will get called when we click on comment icon
    initialiseComment : function(cmp, event, helper){
		
		var GRId = cmp.get("v.GenRecordId");
		let src = GRId;

		if(src.search('RLID=') != -1){
		    let RLID = src.slice(src.indexOf('RLID=')+5);
		    cmp.set("v.RLId",RLID);
		    cmp.set("v.GenericId",RLID);
		    var getRLId = cmp.get("v.RLId");		
		}
            
		if(src.search('HTID=') != -1){           
			let HTID = src.slice(src.indexOf('HTID=')+5);
			cmp.set("v.HelpTopicId",HTID);
			cmp.set("v.GenericId",HTID);
			var getHelpTopicId = cmp.get("v.HelpTopicId");            
		}
            
		if(src.search('PL=') != -1){
            let PLID = src.slice(src.indexOf('PL=')+3);
            cmp.set("v.PLIdentifier",PLID);
           
            var getPLIdentifier = cmp.get("v.PLIdentifier");
		}
          
		var action = cmp.get("c.initialCommentCall");
		action.setParams({ 
			"helptopicid" : getHelpTopicId,
			"RLid" : getRLId,
			"PLIdentifier" : getPLIdentifier
		});

        action.setCallback(this, function(response){
               
            var state = response.getState();
            if(state == 'SUCCESS') {
                
                let returnData = response.getReturnValue();
                var result = returnData.split(',,');
                cmp.set("v.DialogueTitle",result[0]);
                cmp.set("v.PLId",result[1]);
                if(cmp.get("v.PLId")){
                  cmp.set("v.GenericId",result[1]); 
                }
            }
        });
        $A.enqueueAction(action);  
            
	},
    
    
    // Enable / disable submit comment button as one types
    onCommentInput:function(cmp,event,helper){
        let usercomment = cmp.get("v.commentData");
        
        if(usercomment){
            cmp.set("v.buttonIsEnable",true);
        }else{
            cmp.set("v.buttonIsEnable",false);  
            
        }
        
    },
        
        
    // Submit the comment on click of Submit Button
    submitComment:function(cmp,event,helper){
            
         var getRLIdsumit = cmp.get("v.RLId");
         var gethelptopicid = cmp.get("v.HelpTopicId");
         var getPLIdentifier = cmp.get("v.PLIdentifier");
         var userdata = cmp.get("v.commentData");
         var pageLayoutID = cmp.get("v.PLId");
            
         var act = cmp.get("c.doLogComment");
         act.setParams({ 
             "userComment" : userdata,
             "helptopicid" : gethelptopicid,
             "RLid"        : getRLIdsumit,
             "PLIdentifier": getPLIdentifier,
             "pageLayOutID": pageLayoutID
         }); 

         act.setCallback(helper, function (response, cmp){
        	 var ret = response.getReturnValue();
        	 
        	 alert(ret);
        	 
        	 // Clear comment text only on return from logging attempt
	         if(cmp.get("v.commentData")){
	        	cmp.set("v.commentData","");
	         }
          
        	 
         });
        
            //Logging interaction log for comment along with geolocation.
            helper.logLUXInteractions(cmp,2,userdata,null,gethelptopicid);
         
         // Disable comment logging button immediately
         cmp.set("v.buttonIsEnable",false);
         $A.enqueueAction(act); 
                        
    },            
     
     
    // Make comment UI screen visible and hide comment list.
    toggleComment:function(cmp,event,helper){
            if(cmp.get("v.togglelist") == true){
                cmp.set("v.togglelist",false); 
            }
            
    },
    
    
    // Make comment list visible and hide comment box.
    toggleButton:function(cmp,event,helper){
         cmp.set("v.togglelist",true);      
     },
      
    
    // Respond to our specific tools
    handlePassthroughs:function(cmp,event,helper) {
    
    	var act = event.getParam("ActionCode");
    	
    	
    	switch (act) {
    		
    		case 'ShowCommentsList':
    			// Show comment listing and set component title accordingly
	            cmp.set("v.togglelist", true);
	            cmp.set("v.Title", helper.Internationalise(cmp, "TipMyHelpComments"));
    			break;
    			
    		case 'ShowCommentUI':
    			// Show submit comment UI and set component title accordingly
                cmp.set("v.togglelist", false);                 
                cmp.set("v.Title", helper.Internationalise(cmp, "TipCommentTopic"));                
    			break;

    		case 'DisplayCommentDetails':
    			// Display details of a comment as it is clicked on the listing
				let onClickList = event.getParam("Parameters");
				let splitstring = onClickList.split("^");
				let clickdata = JSON.parse(splitstring[1]);
				Object.assign(clickdata,{commentDate:splitstring[2]});
				cmp.set("v.commentListingItem",clickdata);  
    			break;
    			
			case 'CommentsAll':
			case 'CommentsTopics':
			case 'CommentsRLs':
			case 'CommentsHPLs':

				// Show comments matching requested filter
				var lst = cmp.find("ListComponent");				
				lst.set("v.CardConfig", act);
				lst.reInitialise();
				
				break;
				
    	}
        
             
     },
     
})