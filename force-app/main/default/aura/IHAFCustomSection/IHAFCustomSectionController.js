({

	// Obtain metadata for the object specified by owner AF control on load
	init : function(cmp, event, helper) {
	
		var objSought = cmp.get("v.sObjectName");
		var sectSought = cmp.get("v.LookupSectionHeading");
		var lblSought = cmp.get("v.LookupItemLabel");
		var typSought = cmp.get("v.LookupItemComponentType");
		
		var obj;			// Returned JSON parsed into objects
		var recs = 0;		// Number of metadata rows returned - for checking we got a result and cueing VF page to obtain if not
		var M;				// For looping around metadata layout info records - the top level object in the data returned
		var S;				// For looping around sections in a layout record
		var LR;				// For looping around rows within a section
		var LI;				// For looping around layout items within a row
		var LC;				// For looping around layout components within a layout item
		var U;				// Custom Link URL - used to lookup actual link to supply via other metadata
		
		
		// Create a partially 'escaped' version of section name whose info is being sought:
		// this is required in order to match the apparent escaping used by SFDC to store this info:
		// the ampersand character (alone?) seems to be coded...
		var sectSoughtEscaped = sectSought;	
		try {
			sectSoughtEscaped = sectSoughtEscaped.split('&').join('&amp;');
		} catch (e){}
		
		
		// Seek stored metadata for the object passed in via member data by our owner
		var act = cmp.get("c.getLayoutContentForObject");
		act.setParams({
			"ObjectAPIName" : objSought,
		});
		
		
		act.setCallback(this, function (response, cmp){
			if (response.getState() == 'SUCCESS') {
			
				try {
					// Check we got valid JSON
					obj = JSON.parse(response.getReturnValue());				
					
		            if ('' + obj.length === 'undefined') {
		                obj = new Array(obj);
		            }
					
					recs = obj.length;				

					console.log('Autoform Custom Section: call to obtain layout content returned ' + obj.length + ' metadata eTags (record types)');	
					console.log('Autoform Custom Section: section sought is: "' + sectSought  + '"');	
					
					// Return value represents all items on all page sections: loop around these
					// to locate the one our owner asked to examine

					// Need to amend to include an extra layer of objects here - potentially 1 for each
					// record type in play 					
					for (M=0; M < obj.length; M++) {	
				
						for (S=0; S < obj[M].sections.length; S++) {

							// Correct section?
							// NB: to deal with odd characters in headings - which appear 'un-escaped' on screen
							// so will be passed as 'usual' to this component, we need to compare the metadata's section heading text
							// with the value as passed - but also a 're-escaped' version that matches what may be in the metadata...
							if (obj[M].sections[S].heading == sectSought
										|| obj[M].sections[S].heading == sectSoughtEscaped
									) {


								console.log('Autoform Custom Section: desired section (' + sectSought + ') located: examining its rows & items for ' + typSought + ' "' + lblSought + '"');	
								
								// If the section is located, loop around its rows and, within these, its items
								// to find the required artifact
	
								for (LR=0; LR < obj[M].sections[S].layoutRows.length; LR++) {
									for (LI=0; LI < obj[M].sections[S].layoutRows[LR].layoutItems.length; LI++) {
									
										// Means of checking for the item matching that specified varies depending on
										// the type of custom element we were asked to find
										
										if (typSought == 'VisualforcePage') {										
											for (LC=0; LC < obj[M].sections[S].layoutRows[LR].layoutItems[LI].layoutComponents.length; LC++) {
												
												// Correct component type?
												if (obj[M].sections[S].layoutRows[LR].layoutItems[LI].layoutComponents[LC].componentType == typSought) {

													console.log('Autoform Custom Section: Section ' + (S+1) + ' row ' + (LR+1) + ' component ' + (LC+1) + ' is of the desired type - checking label / API name...');	

													// The 'label' we've been given to seek in metadata is a VF page API name.
													// The layout item's 'label' will be a page's actual label - so will not match.
													// The layout item's 'apiName' will be the page API name - but may or may not have its namespace - so we need to check for both forms here:
													// As we don't know the namespace involved, we can only check for the form...
 
													if (obj[M].sections[S].layoutRows[LR].layoutItems[LI].layoutComponents[LC].apiName == lblSought
															|| obj[M].sections[S].layoutRows[LR].layoutItems[LI].layoutComponents[LC].apiName.endsWith('__' + lblSought)) {													

														console.log('Autoform Custom Section: located desired VF page data: ' + obj[M].sections[S].layoutRows[LR].layoutItems[LI].layoutComponents[LC].visualforceUrl);
		
														cmp.set("v.frmU", obj[M].sections[S].layoutRows[LR].layoutItems[LI].layoutComponents[LC].visualforceUrl);
														cmp.set("v.frmW", obj[M].sections[S].layoutRows[LR].layoutItems[LI].layoutComponents[LC].width);
														cmp.set("v.frmH", obj[M].sections[S].layoutRows[LR].layoutItems[LI].layoutComponents[LC].height);
														cmp.set("v.frmS", obj[M].sections[S].layoutRows[LR].layoutItems[LI].layoutComponents[LC].showScroll);											

														break;
													}														
												}
											}
							
										}	// End if type sought was VF page section
										
										
										if (typSought == 'CustomLink') {
											for (LC=0; LC < obj[M].sections[S].layoutRows[LR].layoutItems[LI].layoutComponents.length; LC++) {
	
												// Correct component type?
												if (obj[M].sections[S].layoutRows[LR].layoutItems[LI].layoutComponents[LC].componentType == typSought) {

													console.log('Autoform Custom Section: Section ' + (S+1) + ' row ' + (LR+1) + ' component ' + (LC+1) + ' is of the desired type - checking label / API name...');	
												
													// Correct layout item identifier?
													if (obj[M].sections[S].layoutRows[LR].layoutItems[LI].layoutComponents[LC].apiName == lblSought
															|| obj[M].sections[S].layoutRows[LR].layoutItems[LI].layoutComponents[LC].apiName.endsWith('__' + lblSought)) {

														console.log('Autoform Custom Section: located desired links component - continuing...');
															
														// This is the link we're after: ignore target (always use new tab) and set link text
														cmp.set("v.linkT", '_blank'); 
														cmp.set("v.linkL", obj[M].sections[S].layoutRows[LR].layoutItems[LI].layoutComponents[LC].label);
														
	
														// THE URL WE GET IS IN THE FORM:
														// 	servlet/servlet.Integration?lid=[Id of a Salesforce 'WebLink' record]&eid=ENTITY_ID&ic=1
														//Extract the ID then make calls to retrieve metadata (cached elsewhere) to seek this
	
														console.log('Autoform Custom Section: located desired custom link metadata: ' + obj[M].sections[S].layoutRows[LR].layoutItems[LI].layoutComponents[LC].customLinkUrl);
	
														U = obj[M].sections[S].layoutRows[LR].layoutItems[LI].layoutComponents[LC].customLinkUrl;
														U = U.substring(U.indexOf('?lid=') + 5);
														U = U.substring(0, U.indexOf('&'));
														
														console.log('Autoform Custom Section: extracted link record ID "' + U + '" - obtaining record...');
														
														act = cmp.get("c.getWeblinkDetails");
														
														act.setCallback(this, function (response, cmp){
															if (response.getState() == 'SUCCESS') {
																try {
																	// Check that web link call returned good JSON
																	
																	obj = JSON.parse(response.getReturnValue());				
														            if ('' + obj.length === 'undefined') {
														                obj = new Array(obj);
														            }
														            console.log('Autoform Custom Section: call to obtain web link data returned - examining...');
												           
														            for (S=0; S < obj[0].records.length; S++) {
														            
														            	if (obj[0].records[S].Id.substring(0,15) == U) {
														            		cmp.set("v.linkU", obj[0].records[S].Url);
	
														            		console.log('Autoform Custom Section: located URL for web link - ' + obj[0].records[S].Url);	
														            		break;
														            	}
														            }
														            
																} catch (e) {
																	// Error processing weblink data
																	//console.log('Autoform Custom Section: error processing web link record: ' + e);
																	
																	// NEED TO CHECK HERE FOR BLANK JSON RETURN VALUE:
																	// THIS MEANS SETTINGS CALL FROM LUXOPS RETURNED NOTHING AS NOTHING YET STORED.
																	// METADATA CALL CANNOT BE MADE FROM SERVER AS NEEDS TO BE VIA VF, SO
																	// BLANK AT THIS POINT MEANS WE NEED TO CALL VF PAGE TO OBTAIN
																	// LINKS INFO WITH NEW OP TBC TO RESULT IN Schema.GetWebLinks
																	
																	console.log('Autoform Custom Section: weblink data appears to be missing - calling VF dialogue to obtain metadata...');
																	
																	var CRoot = cmp.get('v.CommunityRoot');
																			
																	// If root is 'null', this can be ignored in most cases
																	if (CRoot + '' == 'null') {CRoot = '';}
																	if (CRoot != '') {CRoot = '/' + CRoot;}
																	
																	var src = CRoot + "/apex/iahelp__IHLUXOpHandler?Op=6";
																	var P = cmp.get("v.ParentControl");
																				
																	P.doDialogue('LayoutMetadataSought', 'VF', src, null, 100, false, false, false, cmp, true);
																	
																	return;
																																		
																}
																															
															} else {
																// Call to get web link data failed
																console.log('Autoform Custom Section: call to obtain web link record failed');															
															}
															
														});	// End weblink callback
														
														// Send call to get web link record
														$A.enqueueAction(act);
														
													}	// End if correct identified for link
												}	// End if current item was web link
											}	// Current layout item's components loop
											
											
										}	// End if type sought was web link								
									}	// Layout metadata items loop
								}	// Layout metadata rows loop				
							}	// End if correct section located						
						}	// Layout metadata sections loop
					
					}	// Layout metadata rows / eTags / layouts (by record ID where relevant)					
					
					
				} catch (e) {
					// Invalid JSON returned from get layout metadata call
					console.log('Autoform Custom Section: call to obtain layout content failed to return valid JSON: ' + e);			
				}
				
				
				// If we get NO metadata, cue VF page to seed this...
				if (recs == 0) {

					console.log('Autoform Custom Section: query failed to return layout content metadata: API call required - summoning VF page to do this...');

					var CRoot = cmp.get('v.CommunityRoot');
							
					// If root is 'null', this can be ignored in most cases
					if (CRoot + '' == 'null') {CRoot = '';}
					if (CRoot != '') {CRoot = '/' + CRoot;}
					
					var src = CRoot + "/apex/iahelp__IHLUXOpHandler?Op=2&ObjectAPIName=" + objSought;
					var P = cmp.get("v.ParentControl");
								
					P.doDialogue('LayoutMetadataSought', 'VF', src, null, 100, false, false, false, cmp, true);
				}
				
			} else {
				// Layout metadata call failed
				console.log('Autoform Custom Section: call to obtain layout content failed');			
			}
		});
		
		// Cue Get Layout Content for Object
		console.log('Autoform Custom Section: about to obtain layout content for ' + objSought);			
		$A.enqueueAction(act);

	},

    	
})