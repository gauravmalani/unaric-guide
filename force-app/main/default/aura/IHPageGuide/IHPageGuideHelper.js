({

	// Obtain guide step info from a reading list, if specified, or design parameters if not
	setupGuide : function (cmp, helper) {

		console.log('IH Page-level Guide: Setup Guide - entry');

		var act = cmp.get("c.getTools");
		var SkipGlobals = true;
    	var topics = '';
    	var positions = '';
    	var pages = '';
    	var RLID = cmp.get("v.ReadingListId");


		if (RLID != '' && RLID != null && RLID + '' != 'undefined') {
			// Obtain reading list entries for step topic / position info etc.
			console.log('Page Guide: a guide ID has been supplied - seeking entries...');
			
		    act.setParams({ 
		        "ToolContext" : 'NoSuch', 
		        "ActionCode" : 'ReadingListEntries',
				"IHContext" : RLID,
				"ClientComponentId" : cmp.get("v.ComponentId"),
				"Params" : '',
				"SkipGlobals" : SkipGlobals,
		    });                       
			$A.enqueueAction(act);
			
		    act.setCallback(helper, function (response, cmp){
		            
		    	// Get our "standard" tools etc. from response
		        helper.processTools(response, cmp, SkipGlobals);
		
		        var RLEs = cmp.get("v.ListingItems");
			            
		        if (RLEs.length > 0) {
			        console.log('Page Guide: specified guide (' + RLID + ') has ' + RLEs.length + ' entries...');
			        
			        RLEs.forEach(function(RLE){
			        	
			        	topics += RLE.iahelp__HelpTopic__c + ',';
			        	positions += 'R' + RLE.iahelp__DisplayRow__c + ':C' + RLE.iahelp__DisplayColumn__c +  ',';
			        	
			        	if (RLE.iahelp__NavigationType__c != '' && RLE.iahelp__NavigationType__c != null && RLE.iahelp__NavigationType__c + '' != 'undefined') {
			        		pages += RLE.iahelp__NavigationType__c + '^' + RLE.iahelp__NavigationDetails__c;
			        	}
			        	pages += ',';
			        	
			        });
			        
			        topics = topics.substring(0, topics.length - 1);
			        positions = positions.substring(0, positions.length - 1);
			        pages = pages.substring(0, pages.length - 1);
			        		        
			        helper.setupGuidePageDefintions(cmp, helper, topics, positions, pages);
			        
		        } else {
		        	// If we get no entries for any reason, we can go no further
		        	return;
		        }       
			});
			
		} else {
			// Obtain guide step info from design parameters
			console.log('Page Guide: no guide ID supplied - steps will be derived from design parameters...');	
		
			topics = cmp.get("v.Topics");
			positions = cmp.get("v.Positions");
			pages = cmp.get("v.Pages");

	        helper.setupGuidePageDefintions(cmp, helper, topics, positions, pages);
		}		
		
	},
	
	
	// Having obtained guide step instructions, translate these into step and navvigation instructions
	setupGuidePageDefintions : function (cmp, helper, topics, positions, pages) {

    	var pDef;
    	var pRef;
    	var PageDefs = [];
    	var CDefs = [];
    	var D0 = '*';
    	var i;    	
    	var compBase = 'c:IHDetail~Height¬-1|SuppressHeader¬true|SuppressFooter¬true|SuppressPoweredBy¬true|BackgroundStyle¬' + cmp.get("v.BackgroundStyle") + '|ToolContext¬PageGuide|HelpRecordId¬';


        console.log('Page Guide: setting up page definitions - topics = ' + topics);
        console.log('Page Guide: setting up page definitions - positions = ' + positions);
        console.log('Page Guide: setting up page definitions - pages = ' + pages);

    	// Set up an array of component definitions to spin up for each guide step:
    	// Each is in the form:
    	// 		[Position] [Delimiter] [Component definition]
    	
    	// ... where position is in the form:
    	// 		[Row]:[Column]
    	
    	// ... and component definition is in the form suited to component generator
    	
    	topics = topics.split(',');
    	positions = positions.split(',');

    	for (i = 0; i < topics.length; i++) {
    		CDefs.push(positions[i] + D0 + compBase + topics[i]);
    	}
    	
    	
    	// Set resulting member data based on calculations above
    	cmp.set("v.CDefs", CDefs);
		CDefs = cmp.get("v.CDefs");    	
		console.log('Setup Guide: there are now ' + CDefs.length + ' steps');
				
		
		// Likewise setup page references to which to navigate, where specified 
		// in design parameters
    	pages = pages.split(",");
    	
    	pages.forEach(function(P){

			/*
			Page definition design parameter is a CSV in the form:
				type^item
			where:
				type is one of: listview, record, custom
				item is: 
					object API name for listview
					record id for record*
					layout API name for custom page layouts
			*/
			
			
    		// Obtain navigable page reference object from string definition
    		pRef = helper.getPageReferenceFromDef(P);
    		PageDefs.push(pRef)
    	});
    	
    	cmp.set("v.PageDefs", PageDefs);
	
	},
	

	// Setup row height from design paramters and rendered height and toggle overall visibility
	toggleGrid : function (cmp, event, helper) {

		try {
	    	// Get overall height to work out row height   
	    	var RC = cmp.get("v.RowCount");	
			var outer = cmp.find("Outermost").getElement();
			var H_Calc = window.innerHeight - outer.getBoundingClientRect().top;		
			cmp.set("v.RowH", H_Calc / RC);
			
			// Toggle grid visibility
			var grid = cmp.find("grid");
			$A.util.toggleClass(grid, 'slds-hide');

		} catch (e) {
			console.log('IH Page Guide - toggle grid - error: ' + e);
		}
	},
	
	    
	// Switch a grid cell into design mode
	toggleHighlight : function (cmp, event) {
		
		var elem = event.currentTarget;
		var designId = elem.id;
		var designDef = '';

		
		$A.util.toggleClass(elem, 'ToBeHelped');
		
		// Only build a component if switching highlight on
		if ($A.util.hasClass(elem, 'ToBeHelped')) {
			designDef += 'c:IHList~';
			designDef += 'Height¬400|';
			designDef += 'SuppressHeader¬false|';
			designDef += 'SuppressFooter¬true|';
			designDef += 'ListingStyle¬Narrow|';
			designDef += 'ListingRowStyle¬Hidden|';
			designDef += 'CardConfig¬ToolsOnly|';
			designDef += 'ToolContext¬GEModeTopicSearchList|';
			designDef += 'ListingClickActionCode¬GEModeSelectStepTopic|';
			designDef += 'NoDataMessage¬Search for the desired Topic...|';
			designDef += 'ComponentId¬' + cmp.get("v.ComponentId") + '_SearchList';
			
			// Note the current cell in the design grid
			cmp.set("v.CurrentDesignCell", designId);

		} else {
			// Clear / reset knowledge of the current design cell
			cmp.set("v.CurrentDesignCell", '');
		}
		
		// Clear out components, then create a list of topics in the cell we're enabling
		var comps = cmp.find("CG");
		
		
		comps.forEach (function (CG) {
			if (CG.get("v.Id") == designId) {
				CG.set("v.ComponentDef", designDef);
				CG.reInitialise();
			} else {
				CG.set("v.ComponentDef", '');
			}
		});		
		
		
	},


	// Navigate to the next step in a page walk through
	setStep : function (cmp, event, helper) {
		
		var Step = cmp.get("v.CurrentStep");
		var CDefs = cmp.get("v.CDefs");
		var D0 = '*';
		var RC;
		var CDef;
		var comps = cmp.find("CG");
		var grid = cmp.find("grid");
		var manuallyClosed = Step > CDefs.length + 1;
		
		
		// Ensure grid is setup and 'on'
		helper.toggleGrid(cmp, event, helper);
		$A.util.removeClass(grid, 'slds-hide');		
		
		// 'Navigate' to the next step
		if (Step < CDefs.length - 1) {
			Step += 1;
		} else {
			// At end of guide, advise user and re-set
			cmp.set("v.CurrentStep", -1);
			cmp.set("v.CurrentRow", -1);
			cmp.set("v.CurrentCol", -1);
			cmp.set("v.GridVisible", false);
			
			comps.forEach (function (CG) {
				CG.set("v.ComponentDef", '');
			});		
			
			
			// Don't issue a 'finished' message in cases of manual closure
			if (! manuallyClosed) {
				var msg = helper.Internationalise(cmp, '[QAMMessageGuideStepsCompleted]');

var src = 'c:IHAlert';
var aMap = {
	"Height": -1,   
	"Title" : "",
	"Message" : msg,
	"Image" : "/resource/iahelp__IHSupportMaterials/img/StockImages/013B.svg", 
	"ToolContext" : "AlertOKOnly",
	"Style" : "Single Column",
    "ComponentId" : cmp.get("v.ComponentId")
  };

//helper.doDialogue('ttl', 'Alert', src, aMap, -1, false, false, false, cmp, false);
alert(msg);
			}
			
			$A.util.addClass(grid, 'slds-hide');	
			return;
		}		
		cmp.set("v.CurrentStep", Step);
		
		
		CDef = CDefs[Step];
		
		if (CDef != '') {
			CDef = CDef.split(D0);			
		} else {
			CDef = [];
			CDef.push('BogusId');			
		}


		// Update components in the grid
		comps.forEach (function (CG) {
			if (CG.get("v.Id") == CDef[0]) {
				CG.set("v.ComponentDef", CDef[1]);
				CG.reInitialise();
				
				// Note the current row and column in play
				RC = CDef[0].split(':');
				cmp.set("v.CurrentRow", RC[0]);
				cmp.set("v.CurrentCol", RC[1]);
				
			} else {
				CG.set("v.ComponentDef", '');
			}
		});		
		
		
		
    	var navService = cmp.find("navService");
    	var PageDefs = cmp.get("v.PageDefs");

    	var pageReference = PageDefs[Step];
        
        if (pageReference != null) {
	        event.preventDefault();
	        navService.navigate(pageReference);
        }
		
		
	},

	
})