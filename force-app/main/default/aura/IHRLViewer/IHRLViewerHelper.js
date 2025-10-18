({
 
    // Set up required listing data according to our member data / Card Configuration etc.
    initialiseList : function(cmp, event, helper) {

        // Only queue 1x action per page visit
        if (cmp.get('v.isInitialised') === true) {
            return;
        }
        
        
        // Allow CG to override tool context: only default here if no value specified.
        // We check here for the default as set by IHCard, as this will be what we see if noone has overridden
    	if (cmp.get('v.ToolContext') == 'QAM') {
    		cmp.set('v.ToolContext', 'RLViewer');
    	}
        
        
        cmp.set('v.ActionCode', 'ReadingListEntries');
        cmp.set('v.Icon', 'fa-list-ol');
        cmp.set('v.IHContext', cmp.get('v.HelpRecordId'));


        var act = cmp.get("c.getTools");
        act.setParams({ 
            "ToolContext" : cmp.get('v.ToolContext'), 
            "ActionCode" : cmp.get('v.ActionCode'),
            "IHContext" : cmp.get('v.IHContext'),
            "ClientComponentId" : cmp.get("v.ComponentId"),
            "SkipGlobals" : false,
        });                       
            
        
        // Create a callback that is executed after the server-side action returns
        act.setCallback(helper, function (response, cmp){

        	helper.processTools(response, cmp);
            
            var RLEs = cmp.get("v.ListingItems");
			var layout;	   
			var D1 = '^';    
			var idx = 0;    

            
            if (RLEs.length > 0) {
            
            	// Set card title to reading list name
	            cmp.set("v.Title", RLEs[0].iahelp__HelpReadingList__r.Name);

            	// Set reading list summary
	            cmp.set("v.RLSummary", RLEs[0].iahelp__HelpReadingList__r.iahelp__Summary__c);


				// Set presentation style - unless one has been specified
				if (cmp.get("v.RLStyle") == '') {
				
					var RLDefault = RLEs[0].iahelp__HelpReadingList__r.iahelp__LightningPresentationStyle__c;
					if (RLDefault == '' || RLDefault + '' == 'null' || RLDefault + '' == 'undefined') {RLDefault = 'Standard';}
					
// Adjust RL and RLE styles here if needed
if (RLDefault == 'Adopter - Minimal Topic') {
	cmp.set("v.RLEStyle", 'Minimal Topic');
	RLDefault = 'Adopter';
}

if (RLDefault == 'Adopter - Topic Viewer') {
	cmp.set("v.RLEStyle", 'Topic Viewer');
	RLDefault = 'Adopter';
}

					
					cmp.set("v.RLStyle", RLDefault);
					
					// In these cases, do NOT suppress card UI
					cmp.set("v.SuppressCardUI", false);
				    
				} else {    

// Adjust RL and RLE styles here if needed
var RLDefault = cmp.get("v.RLStyle");

if (RLDefault == 'Adopter - Minimal Topic') {
	cmp.set("v.RLEStyle", 'Minimal Topic');
	RLDefault = 'Adopter';
}

if (RLDefault == 'Adopter - Topic Viewer') {
	cmp.set("v.RLEStyle", 'Topic Viewer');
	RLDefault = 'Adopter';
}

cmp.set("v.RLStyle", RLDefault);

				    cmp.set("v.SuppressCardUI", cmp.get("v.RLStyle") == 'Adopter');
				}
					            
	             
	            RLEs.forEach(function (RLE){
	            
	            	// Parse entry description to ensure 'safe' HTML
	            	RLE.iahelp__HelpTopic__r.iahelp__Description__c = helper.getSafeHTML(RLE.iahelp__HelpTopic__r.iahelp__Description__c);	            	
	            	RLE.Expanded = false;
	            	RLE.Rendered = false;

					// For adopter presentation style, minimal topic display option:
					// Provide for custom layouts: extract these from topic specified templates
					// or, if these are not present, provide a default, should it be needed
					layout = RLE.iahelp__HelpTopic__r.iahelp__Template__r.iahelp__PageURL__c;
					
					// If RL entry is marked as "hidden", remove this entry from presentation
					if (layout == '[HideRLE]') {
						RLEs.splice(idx,1);
						
					} else {
						if (layout.indexOf(D1) == -1) {
							// Topic-specified template is non-custom: use the default set of layout instructions
							// specified for this component (via design parameters)
							layout = cmp.get("v.DefaultLayout");
						}
						RLE.Layout = layout;
					}

	            	idx+=1;
	            });

	            cmp.set("v.ListingItems", RLEs);


				// Set up animation if in Carousel mode
				if (cmp.get("v.RLStyle") == 'Carousel') {
					
					var i;
					var sel;	
				    var tmr;
				    var RLEs = cmp.get("v.ListingItems");
				    var globalId = cmp.getGlobalId();

				    
				    // Set designer layout info based on INITIAL record
					var DD = cmp.find("theDesigner");
					var defaultLayout = cmp.get("v.DefaultLayout");
					var LD = '^';
					
					
					DD = DD[0];
					
					if (RLEs[0].iahelp__HelpTopic__r.iahelp__Template__r.iahelp__PageURL__c.indexOf(LD) != -1) {
						// Record specifies a custom layout
						DD.set("v.LayoutInfo", RLEs[0].iahelp__HelpTopic__r.iahelp__Template__r.iahelp__PageURL__c);
					} else {
						// No topic specific custom layout specified: use default instructions
						DD.set("v.LayoutInfo", defaultLayout);
					}    	
					
					cmp.set("v.CurrentRecord", RLEs[0].iahelp__HelpTopic__r);

				    
				    tmr = window.setInterval($A.getCallback(function() {
					        
				        try {
							var curIdx = cmp.get("v.ActiveCarouselPanel");
							if (curIdx < RLEs.length - 1) {
								curIdx += 1;
							} else {
								curIdx = 0
						    }
							cmp.set("v.ActiveCarouselPanel", curIdx);
							
							// Add selected class to appropriate selector lozenge
					    	// Remove selected class from all selectors
					    	for (i = 0; i<RLEs.length; i++) {
					    		sel = document.getElementById(globalId + 'carouselSelector_' + i);
					    		$A.util.removeClass(sel, 'slds-is-active');
					    	}
					    	
					    	// Add selected class to clicked selector
					    	sel = document.getElementById(globalId + 'carouselSelector_' + curIdx);
					    	$A.util.addClass(sel, 'slds-is-active');


							// Set designer layout info based on CURRENT record
							var DD = cmp.find("theDesigner");
							var defaultLayout = cmp.get("v.DefaultLayout");
							var LD = '^';
							
							
							DD = DD[curIdx];
							
							if (RLEs[curIdx].iahelp__HelpTopic__r.iahelp__Template__r.iahelp__PageURL__c.indexOf(LD) != -1) {
								// Record specifies a custom layout
								DD.set("v.LayoutInfo", RLEs[curIdx].iahelp__HelpTopic__r.iahelp__Template__r.iahelp__PageURL__c);
							} else {
								// No topic specific custom layout specified: use default instructions
								DD.set("v.LayoutInfo", defaultLayout);
							}    	

							
							// Set the current record for use by the detail designer that displays the topic in Carousel mode
							cmp.set("v.CurrentRecord", RLEs[curIdx].iahelp__HelpTopic__r);
				            
				        } catch (e) {
				        }
				            
				    }), cmp.get("v.CarouselSpeed"));	
					
					// Take note of the timer process ID
				    cmp.set("v.CarouselTimer", tmr);
						
				}	                  
            }
        });                
        

        // Send action and note the fact that this has been done / we're initialised        
        cmp.set('v.isInitialised', true);


		// Do nothing where RL has not been supplied: 
		// selection event handling in controller will deal with any subsequent context change
		if (cmp.get("v.IHContext") == '') {
			console.log('Reading List Viewer: no RL on initialise - data will not be sought');
			return;
		}
        
        
        helper.showSpinner(cmp);        
		$A.enqueueAction(act);
                    
	},
		
	
	// Move within RL to item specified by theId and log interaction recording this
	navToItem : function (cmp, helper, theId) {
	
		var navBtn;
		var act;
		var desc;
		var LIs;
		var i;
		var GID = cmp.getGlobalId();


		try {

			var T = document.getElementById(theId).offsetTop;		
			var VAdjust = 30;
			var pos;
			
			if (cmp.get("v.Height") == -1) {
				// With no scroll bars, scroll the page: we have to use jQ here
				// as there is otherwise no element to scroll
				pos = T - VAdjust;
				$(document).scrollTop(pos);
				
			} else {
				// If we are less than 100% height / have scroll bars, scroll the tile strip containing DIV
				var strip = document.getElementById(GID + '_Tiles');
				
				if (cmp.get("v.SuppressFooter") == false) {
					VAdjust += 50;
				}
				
				pos = T - VAdjust;
				strip.scrollTop = pos;
			}
			
			// Move our navigation lozenges to our card's body tools area			
			var navBar = document.getElementById(GID + 'RLNav');
			helper.appendBodyTools(cmp, helper, navBar);					
			
			// Set scroll position (see change handler in card)
			cmp.set("v.CardBodyScrollPos", pos);

		} catch (e) {}
	    
	    
	    // Mark selected entry's nav button as active...
	    navBtn = document.getElementById('NavItem' + theId);

	    // ...noting total entries visited
	    if (! $A.util.hasClass(navBtn, 'slds-is-active')) {
	    	cmp.set("v.EntriesVisited", cmp.get("v.EntriesVisited") + 1);
	    }
	    $A.util.addClass(navBtn, 'slds-is-active');	  
	    
	      	    
	    cmp.set("v.Diags", helper.Internationalise(cmp, 'AdviceLabelItemsViewed') + ': ' + cmp.get("v.EntriesVisited") + '/' + cmp.get("v.ListingItems").length);
	    
	    
	    
	//	act = cmp.get("c.logLUXInteraction");
		
		// Get the help topic id from the RLE ID
		desc = theId.replace(cmp.getGlobalId(), '');
		LIs = cmp.get("v.ListingItems");
		for (i=0; i<LIs.length; i++) {
			if (LIs[i].Id == desc) {
				desc = LIs[i].iahelp__HelpTopic__c;
				break;
			}
		}
		/*
        act.setParams({ 
			"iTyp" : "13",
			"Description" : desc,
			"IHContext" : cmp.get('v.IHContext')
        });         */              
        

        // Send action
       // $A.enqueueAction(act);
		
        // Log a related interaction
		helper.logLUXInteractions(cmp, 13,desc,cmp.get('v.IHContext')).then((response) => {
						//do nothing to response.
					});
	},
    
    
    // Calculate media height from selected aspect ratio and rendered width, then re-size: also navigate if required
    finalInitialise : function (cmp, helper) {
    
        var LIs = cmp.get("v.ListingItems");    
        var i; 
        var vFrm;
		var medH;
		var medW;
		var AR;

		
		// Act only once listing items exist
		if (LIs.length > 0) {
			
			// Get the rendered width of our media from a "sizing" element added for this purpose
			var medW = document.getElementById(cmp.getGlobalId() + 'Sizer').offsetWidth;
			
			// Work out height from this and aspect ratio selected for component
			switch (cmp.get("v.VideoAspectRatio")) {
				case "HD (16:9)" :
					AR = 9/16;
					break;
			
				case "Monitor (4:3)" :
					AR = 3/4;
					break;
			
				case "Widescreen (5:3)" :
					AR = 3/5;
					break;
			}
			
			medH = medW * AR;
			
			// Set heights of video frames on this component
			for (i=0; i<LIs.length; i++) {
				vFrm = document.getElementById('RLEVideo' + cmp.getGlobalId() + LIs[i].Id);
				try{
					vFrm.style.height = medH + 'px';
				} catch (e){}
			}
			
			
			// Check for an override selected record (HTID) in URL
			// NOTE: despite the fact this is only configured to fire on mouse over, it seems to 
			// fire long before the DOM is seen in any case!! So: need to trap non-existence of helper...!
			if (helper + '' != 'undefined') {     
	            var theId = helper.getURLParm(cmp, 'iahelp__HTID');
	            if (theId != '' && cmp.get("v.CheckURLParams") == true) {
	            	
	            	// Need to simulate a NAV click here...
	            	// From Help Topic ID, find its RL Entry Id
	            		LIs.forEach(function(v) {
	            			if (v.iahelp__HelpTopic__c == theId) {
	            				
	            				// If you match the HTID in RLEs, navigate to it
				            	// Tack global ID onto this
				            	theId = cmp.getGlobalId() + v.Id;
				            	helper.navToItem(cmp, helper, theId);
				            	
	            			}
	            		});
	            	
				
					// Set latch that says we've considered URL (on page load and not thereafter)
				    cmp.set("v.CheckURLParams", false);
	            }
	            
			}						
		}    
    },
       
    
	// Navigate to the next step in a page walk through
	setStep : function (cmp, event, helper) {
	
		var pDef = event.currentTarget.getAttribute("data-Pdef");		
    	var navService = cmp.find("navService");
    	var pRef;

		// Obtain navigable page reference object from string definition    	
    	pRef = helper.getPageReferenceFromDef(pDef);
        
        if (pRef != null) {
	        event.preventDefault();
	        navService.navigate(pRef);
        }
        		
	},

	    
})