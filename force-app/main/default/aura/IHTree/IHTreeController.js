({

	// Get the largely invariant, cacheable information used on cards (delegated),
	// check for URL parameters, then cue initialisation
	init: function (cmp, event, helper) {

		cmp.set("v.helperReference", helper);

		// Check for an override selected topic (HTID) in URL        
		var HTID = helper.getURLParm(cmp, 'iahelp__HTID');
		if (HTID != '' && cmp.get("v.CheckURLParams") == true) {
			cmp.set("v.HelpRecordId", HTID);

			// Set latch that says we've considered URL (on page load and not thereafter)
			cmp.set("v.CheckURLParams", false);
		}

		helper.initialiseGlobals(cmp, event, helper);
	},


	// Wrapper allowing print settings to be modified before firing a re-build        
	initialiseTree: function (cmp, event, helper) {
		helper.initialiseTree(cmp, event, helper);
	},


	// Respond to change in active "tree" as fired by OUR child breadcrumbs control
	selectRecord: function (cmp, event, helper) {

		var theId = event.getParam("RecordId");
		var src = event.getParam("SourceComponent");


		// Check we got an ID
		if (theId == null || theId + '' == 'null') {
			console.log('IHTree.selectRecord: supplied record ID is null - ignoring...');
			return;
		}

		// If we're selecting by master topic identifier, as opposed to topic id,
		// this is dealt with elsewhere for the purposes of this component:
		// We should proceed by stripping off any master topic id pre-fix
		// (see Helper.initialiseTree for where this is added)

		if (theId.startsWith('MTID:')) {
			theId = theId.substring(5);
		}


		// Respond to events that emanate from our crumb control
		if (src == cmp.get("v.ComponentId") + 'Crumbs') {

			// Navigate to one of the peer trees in which a node features 
			cmp.set("v.RootNode", theId);
			cmp.set("v.IHContext", cmp.get("v.RootNode"));
			helper.initialiseTree(cmp, event, helper);
			return;
		}


		// Respond to events that emanate from one of our tree nodes: we should just set our topic id
		if (src == cmp.get("v.ComponentId")) {
			cmp.set("v.HelpRecordId", theId);
			return;
		}


		// Respond to others that we listen to:
		// NOTE: for data amendments (e.g., from a detail control) a different
		// data amended passthrough will have been raised - not a select: see elsewhere
		if (helper.eventBeingListenedTo(cmp, event)) {

			// 1.41.25+ : the select record event can be used to set current topic on the tree - but also the root in some cases:
			// See position detectors in Help Cue mode that issue select record, where either outcome may be desired.
			// Other components may issue a specific pass-through (see 'SelectTree' handling elsewhere) but position detectors issue only SelectRecord.
			// In these cases for trees, action to take depends on source naming convention (position detector's 'Positioning Group').
			// Recipient Tree must be listening to this as usual by name, where:

			// If name = 'SetRootOf_' + the component ID of our tree, set root, not current topic...
			if (src == 'SetRootOf_' + cmp.get("v.ComponentId")) {

				cmp.set("v.RootNode", theId);
				cmp.set("v.IHContext", cmp.get("v.RootNode"));
				helper.initialiseTree(cmp, event, helper);
				return;
			}

			// If not (and we are listening - e.g. listings) select the issued record on the current tree: only act if this represents a change
			if (cmp.get("v.HelpRecordId") != theId) {

				cmp.set("v.HelpRecordId", theId);

				// For certain trees, context (by way of root) should also be set to this ID
				if (cmp.get("v.NodeProvider") == 'ServiceIHTrees.TNSTagPools') {
					cmp.set("v.RootNode", theId);
				}

				// Does the requested record exist within our node data?
				if (helper.nodeExists(cmp, theId)) {
					// If so, expand & select it
					console.log('IHTree.selectRecord: Node "' + theId + '" located on the current tree...');
					helper.selectNode(cmp, helper, theId);

				} else {
					// If not, do nothing								
					console.log('IHTree.selectRecord: Node "' + theId + '" not found on the current tree - ignoring...');
				}

			}
		}

	},


	// Handle pass-throughs from our child tree node controls and others
	handlePassThroughs: function (cmp, event, helper) {


		var act = event.getParam("ActionCode");
		var parms = event.getParam("Parameters");
		var D1 = cmp.get("v.Delimiter");
		var src = event.getParam("SourceComponent");
		var dvPeers = cmp.find("PopoverPeers");
		var CRoot = cmp.get('v.CommunityRoot');

		// If root is 'null', this can be ignored in most cases
		if (CRoot + '' == 'null') { CRoot = ''; }
		if (CRoot != '') { CRoot = '/' + CRoot; }


		// In certain rare cases, just respond
		switch (act) {

			case 'DragStart':
				cmp.set("v.DragData", parms);
				break;

			case 'DragEnd':
				cmp.set("v.DragData", '');
				break;


			case 'FieldValueChange':
				// A field value has changed: if we recognise
				// the source (which will be the ID of the affected record)
				// we must update our data

				var LIs = cmp.get("v.ListingItems");
				var HTs = cmp.get("v.HelpTopics");

				LIs.forEach(function (LI) {

					if (LI.Id == src) {

						// Only topic name can be amended via tree: obtain this
						// from event parameters, which are in the form:
						// record ID ^ value (of allocated field)

						var params = parms.split('^');

						// Store the new value in our listing item label (which is where topic name goes)   		
						LI.Label = params[1];

						// Add the listing item to collection of those which have been edited
						var ELIs = cmp.get("v.EditedLIs");
						if (ELIs + '' == 'undefined') { ELIs = []; }

						ELIs.forEach(function (E) {
							if (E.Id == LI.Id) {
								// Remove any existing item copy for this record from the edited collection...
								ELIs.pop(E);
							}
						});

						// ... then add the edited item back in:
						// For this store, we want the underlying topic
						HTs.forEach(function (HT) {
							if (HT.Id == LI.Id) {
								// Remove any existing item copy for this record from the edited collection...
								HT.Name = params[1];
								ELIs.push(HT);
							}
						});

						cmp.set("v.EditedLIs", ELIs);

					}
				});

				break;


		}


		// In certain cases, respond on basis of source only: note that
		// eventIsOurOwn expects the source to be literally the same component (global ID is checked)
		// so would filter out certain events from our tree nodes
		if (src == cmp.get("v.ComponentId")) {

			switch (act) {

				case 'Edit':
				case 'View':

					// These ops are only allowed for Help Topic trees
					var keyTypes = cmp.get("v.GlobalSettings.iahelp__SFObjectIds__c");
					var root = cmp.get("v.RootNode");
					keyTypes = keyTypes.split('^');

					if (!root.startsWith(keyTypes[0])) {
						alert(helper.Internationalise(cmp, 'MessageOptionNotAllowed'));
						return;
					}

					cmp.set("v.DataMode", act);

					// If reverting to view mode, ask user if they want to save changes
					if (act == 'View') {
						var ELIs = cmp.get("v.EditedLIs");
						if (ELIs + '' == 'undefined') { ELIs = []; }

						if (ELIs.length > 0) {
							if (confirm(helper.Internationalise(cmp, 'MessageSaveDialogueChanges'))) {

								var actSave = cmp.get("c.saveTopics");
								actSave.setParams({
									"topicJSON": JSON.stringify(ELIs),
								});

								// Add callback to process returned results
								actSave.setCallback(helper, function (response, cmp) {

									var ret = response.getReturnValue() + '';
									if (ret.toUpperCase().startsWith('ERROR')) {
										alert(ret);
									}

								});
								$A.enqueueAction(actSave);
							}

							// Whether or not we saved, re-initialise
							helper.initialiseTree(cmp, event, helper);
						}
					}

					break;

				case 'TreeKeywordList':
					// Show tree's 'glossary' list of all keywords in this org

					cmp.set("v.OtherListActivated", true);
					cmp.set("v.OtherListConfig", 'Keywords');

					cmp.set("v.SuppressHeader", true);
					cmp.set("v.H_Header", 0);

					var Lst = cmp.find("OtherList");
					Lst.reInitialise();

					break;

				case 'TreeBookmarksList':
					// Show tree's bookmarks listing

					cmp.set("v.OtherListActivated", true);
					cmp.set("v.OtherListConfig", 'HelpBookmarks');

					cmp.set("v.SuppressHeader", true);
					cmp.set("v.H_Header", 0);

					var Lst = cmp.find("OtherList");
					Lst.reInitialise();

					break;

				case 'BackToTree':
					// Return from a listing to the tree

					cmp.set("v.OtherListActivated", false);
					cmp.set("v.SuppressHeader", false);
					break;

				case 'BackToTreeFromSearchList':
				case 'TreeSearchList':

					console.log('Tree "' + cmp.get("v.ComponentId") + '" - list-based tree search requested');

					var theId;
					var Lst;
					var term;
					var P = parms.split('^');
					var actI = cmp.get("c.logLUXInteraction");
					var root = cmp.get("v.RootNode");


					// Obtain (and store for reference on future calls) rendered header height for card body sizing ops
					var HH = cmp.get("v.H_Header");
					if (HH > 0) {
						cmp.set("v.hHead", HH);
					} else {
						HH = cmp.get("v.hHead");
					}


					// 'Switch on' our search list at first request
					cmp.set("v.SearchListActivated", true);


					// If, on entry to this routine, we're in search mode, get the ID of the clicked search listing
					if (cmp.get("v.SearchMode") == true) {
						Lst = cmp.find("SearchList");
						theId = Lst.get("v.HelpRecordId");
					}


					// Toggle search mode
					cmp.set("v.SearchMode", !cmp.get("v.SearchMode"));


					if (cmp.get("v.SearchMode") == true) {
						// If, having toggled, we're in search mode, we need to hide our header
						// (because the list we show will display its own):
						// Set rendered header height member data to zero, so mark-up styling calcs will size listing correctly
						cmp.set("v.SuppressHeader", true);
						cmp.set("v.H_Header", 0);

					} else {
						// On return from search mode / listing, set tree's node to that of last clicked topic
						cmp.set("v.RootNode", cmp.get("v.HomeRoot"));
						cmp.set("v.HelpRecordId", theId);

						// Re-set header rendered height member to the value we stored when it was last visible
						cmp.set("v.SuppressHeader", false);
						cmp.set("v.H_Header", HH);


						// If returning from search mode, note any search term in play		
						try {
							Lst = cmp.find("SearchList");
							var theSearchConfigTool = helper.getConfigToolForAction(Lst, 'Header', 'TreeSearchList');
							var theSearchSupportControls = helper.getSupportControlsForConfigTool(Lst, theSearchConfigTool);
							var theSearchSupportControlIdent = theSearchSupportControls[0][1];
							theSearchSupportControlIdent += Lst.get("v.UniqueIdent");
							var x = document.getElementById(theSearchSupportControlIdent);
							term = $(x).val();

						} catch (e) {
							term = '[Unknown]'
						}


						// Further actions depend on reason for returning:
						// If we clicked on a result, set a timer to cue selected help topic 
						if (act == 'BackToTreeFromSearchList') {
							window.setTimeout($A.getCallback(function () {

								// Raise record select passthrough to synch any listeners
								var appEvent = $A.get("e.c:selectTopic");
								appEvent.setParams({ "RecordId": P[0] });
								appEvent.setParams({ "SourceComponent": cmp.get('v.ComponentId') });
								appEvent.fire();

								helper.selectNode(cmp, helper, P[0]);


								// Log a tree search complete interaction
								// actI.setParams({ 
								//     "iTyp" : "23",
								//     "Description" : term,
								//     "IHContext" : root + '^' + P[0]
								// });                               

								//   actI.setCallback(this, function (response, cmp){ 
								// 	if (response.getState() === 'SUCCESS') {
								// 		// Do nothing if OK
								// 	} else {
								// 		console.log('"' + cmp.get("v.ComponentId") + '" - ERROR logging tree search interaction');
								// 	}
								// });

								// Send log interaction action
								// $A.enqueueAction(actI);

								helper.logLUXInteractions(cmp, 23, term, root + '^' + P[0]).then((response) => {
									//do nothing to response.
									if (response.getState() === 'SUCCESS') {
										// Do nothing if OK
									} else {
										console.log('"' + cmp.get("v.ComponentId") + '" - ERROR logging tree search interaction');
									}
								});

							}), 250);

						} else {
							// If returning from search mode via the cancel button, log a tree search cancelled interaction
							// actI.setParams({
							// 	"iTyp": "24",
							// 	"Description": term,
							// 	"IHContext": cmp.get("v.RootNode")
							// });

							// actI.setCallback(this, function (response, cmp) {
							// 	if (response.getState() === 'SUCCESS') {
							// 		// Do nothing if OK
							// 	} else {
							// 		console.log('"' + cmp.get("v.ComponentId") + '" - ERROR logging tree search interaction');
							// 	}
							// });

							// Send action
							// $A.enqueueAction(actI);

							helper.logLUXInteractions(cmp, 24, term, cmp.get("v.RootNode")).then((response) => {
								//do nothing to response.
								if (response.getState() === 'SUCCESS') {
									// Do nothing if OK
								} else {
									console.log('"' + cmp.get("v.ComponentId") + '" - ERROR logging tree search interaction');
								}
							});

						}

					}

					break;

				case 'TreeGetChildNodes':
					// For certain providers only: get children of a given node.
					// This is used by e.g., Schema tree via a node/row listing tool, as getting all
					// objects & fields at once would be too slow...

					var act = cmp.get("c.treeGetChildNodes");
					var P = parms.split('^');

					act.setParams({
						"Node": P[0],
						"Provider": cmp.get("v.NodeProvider")
					});

					// Add callback to process returned results
					act.setCallback(this, function (response, cmp) {

						// Add returned nodes to our "listing" (tree nodes)
						var state = response.getState();
						var obj;
						var LIs = [];
						var i;
						var nodeCheck;

						if (state === "SUCCESS") {
							try {
								obj = JSON.parse(response.getReturnValue());

								// We may have been returned zero or more fields.
								// If there are >1 total items, we have a collection to iterate. 
								// If there are 0 items, we've nothing to do.
								// If there is exactly 1 item, we need
								// to load this into an array in order for the loop that follows to work...
								if ('' + obj.length === 'undefined') {
									obj = new Array(obj);
								}

								// Parse these into our listing items
								LIs = cmp.get("v.ListingItems");

								for (i = 0; i < obj.length; i++) {

									// Need to check for duplicates here:
									// Cannot allow a given node ID to occur in the tree more than once
									nodeCheck = LIs.find(L => L.Id == obj[i].Id);
									if (nodeCheck + '' == 'undefined') {
										LIs.push(obj[i]);
									} else {

										// Additionally, only allow duplicate nodes - even once marked as such - to
										// feature once as a child of any given node: i.e., if parent already has
										// this node, do not add...

										nodeCheck = LIs.find(L => (L.Id == obj[i].Id || L.Id == obj[i].Parameters + '_' + obj[i].Id) && L.Parameters == obj[i].Parameters);
										if (nodeCheck + '' == 'undefined') {

											// If we have a duplicate Amend ID, action code and style before adding
											obj[i].Id = obj[i].Parameters + '_' + obj[i].Id;
											obj[i].ActionCode = 'NoOp';
											obj[i].StyleClass = 'DuplicateNode';

											console.log('Tree - Get Child Nodes: node ' + obj[i].Id + ' already present in tree - amending to action code: ' + obj[i].iahelp__ActionCode__c);

											LIs.push(obj[i]);
										}


									}
								}

								cmp.set("v.ListingItems", LIs);
								helper.setupNodes(cmp, helper);


								// Fire a record selected synching event: 
								var appEvent = $A.get("e.c:selectTopic");
								appEvent.setParams({ "RecordId": P[0] });
								appEvent.setParams({ "SourceComponent": cmp.get('v.ComponentId') });
								appEvent.fire();


								cmp.set("v.Diags", helper.Internationalise(cmp, 'AdviceLabelMatchingItems') + ': ' + obj.length);

							} catch (e) {
								cmp.set("v.Diags", "IHTree - TreeGetChildNodes - Error parsing the following return value (" + e + "): " + response.getReturnValue());
							}

						} else {
							cmp.set("v.Diags", "ERR!");
						}
					});

					// Send action
					$A.enqueueAction(act);
					break;

			}
		}


		// In certain cases, only respond to those we're listening to
		if (helper.eventBeingListenedTo(cmp, event)) {
			switch (act) {

				case 'ContextChange':
					// Change of context has been observed and we should respond:
					// This may mean a change in our root or selected topic - but this is not known at this stage:
					// A server call is required, passing context, to see what the 'implications' are in terms of 
					// the required changes to our state...
					// NB: as of 1.42.2 change of root only supported

					// Call server method with context
					var newRoot = '';
					var act = cmp.get("c.getRootTopicForContext");

					act.setParams({
						"IHContext": parms,
					});

					// Add callback to process returned results
					act.setCallback(helper, function (response, cmp) {
						if (response.getState() === "SUCCESS") {

							// Response should be root node topic ID
							newRoot = response.getReturnValue();

							// If we get topic ID and it has changed, set root to that:
							// NB: we can only deal with the default, help topic tree provider!

							if (newRoot == '') {
								console.log('IHTree "' + cmp.get("v.ComponentId") + '": Select Tree request failed to return a root for "' + parms + '": root remains unchanged.');

							} else if (newRoot != cmp.get("v.RootNode")) {
								cmp.set("v.NodeProvider", 'undefined');
								cmp.set("v.RootNode", newRoot);
								cmp.set("v.IHContext", cmp.get("v.RootNode"));

								// If we are changing root, this is also the selected record in these cases
								cmp.set("v.HelpRecordId", newRoot);

								console.log('IHTree "' + cmp.get("v.ComponentId") + '": re-initialising to new tree root "' + cmp.get("v.RootNode") + '"');
								helper.initialiseTree(cmp, event, helper);

							} else {
								console.log('IHTree "' + cmp.get("v.ComponentId") + '": Select Tree request ignored as "' + cmp.get("v.RootNode") + '" is already the current root');
							}


						} else {
							// Fail silently but add diagnostics
							var errors = response.getError();

							if (errors) {
								if (errors[0] && errors[0].message) {
									console.log('IHTree - error obtaining root information for context: "' + parms + '": ' + errors[0].message);
								} else {
									console.log('IHTree - error obtaining root information for context: "' + parms + '"');
								}

							} else {
								console.log('IHTree - error obtaining root information for context: "' + parms + '"');
							}

						}
					});

					$A.enqueueAction(act);
					break;

				case 'DataAmended':
					//We are setting AuthorConfigLatch value to true, when we amend the Help topic and Author config is in play.
					//This is to prevent navigation to root node.
					cmp.set("v.AuthorConfigLatch", true);

					// Select the amended record (or blank, as will be the case in deletes)
					cmp.set("v.HelpRecordId", parms);

					// Deal with roots relating to the reading list tree provider
					var root = cmp.get("v.RootNode");
					var RLMarker = 'rL_';

					if (root.startsWith(RLMarker)) {
						root = root.substring(RLMarker.length);
					}
					cmp.set("v.RootNode", root);


					// Re-query this tree so as to include amended data
					helper.initialiseTree(cmp, event, helper);
					break;

				case 'SelectTree':

					// Change in tree root requested by selection control
					// (external one, as opposed to our own crumb):
					// In doing this, change node provider to that specified in the event:
					// Parameters are in the form: root node ^ provider class name
					var Ps = parms.split('^');
					if (Ps[1] == null || Ps[1] == '' || Ps[1] + '' == 'undefined') { Ps[1] = 'undefined'; }

					// Only re-initiaise if there has actually been a change of tree
					if (Ps[0] != cmp.get("v.RootNode")) {
						cmp.set("v.NodeProvider", Ps[1]);
						cmp.set("v.RootNode", Ps[0]);
						cmp.set("v.IHContext", cmp.get("v.RootNode"));

						// If we are changing root, this is also the selected record in these cases
						cmp.set("v.HelpRecordId", Ps[0]);

						console.log('IHTree "' + cmp.get("v.ComponentId") + '": Request to Select Tree "' + cmp.get("v.RootNode") + '" being processed...');
						helper.initialiseTree(cmp, event, helper);

					} else {
						console.log('IHTree "' + cmp.get("v.ComponentId") + '": Select Tree request ignored as "' + cmp.get("v.RootNode") + '" is already the current root');
					}
					break;

				case 'SynchToContextHT':
					// Select tree node representing the record referenced by this event - 
					// e.g., a help topic selected from a list or the topic to which a sticky relates
					// Extract the help topic ID from this
					var Ps = parms.split('^');
					var HTID = Ps[1];

					// Synch to this topic
					cmp.set("v.HelpRecordId", HTID);
					helper.initialiseTree(cmp, event, helper);

					// Fire a record selected synching event: 
					var appEvent = $A.get("e.c:selectTopic");
					appEvent.setParams({ "RecordId": HTID });
					appEvent.setParams({ "SourceComponent": cmp.get('v.ComponentId') });
					appEvent.fire();

					break;

			}
		}


		// In some cases, respond to our own or those we're listening to
		if (helper.eventIsOurOwn(cmp, event) || helper.eventBeingListenedTo(cmp, event)) {

			switch (act) {
				case 'RefreshCurrentList':
					// Re-initialise the whole tree
					helper.initialiseTree(cmp, event, helper);
					break;

				case 'ReturnHome':
					// Tree viewer - home button
					var defaultNode = cmp.get("v.HomeRoot");

					if (cmp.get("v.RootNode") != defaultNode) {
						// If root has changed, just set our member data and re-initialisation will follow...
						cmp.set("v.RootNode", defaultNode);

						// If we are changing root, this is also the selected record in these cases
						cmp.set("v.HelpRecordId", defaultNode);

						helper.initialiseTree(cmp, event, helper);

					} else {
						// If root is already in play but topic changed
						var appEvent
						appEvent = $A.get("e.c:selectTopic");
						appEvent.setParams({ "SourceComponent": cmp.get("v.ComponentId") });
						appEvent.setParams({ "RecordId": defaultNode });
						appEvent.fire();

						//helper.selectNode(cmp, defaultNode);

					}
					break;
			}
		}


		// In certain cases, only respond to our own tree:
		if (helper.eventIsOurOwn(cmp, event)) {

			switch (act) {

				case 'TreeAdd':
					// Add a new help topic and set it to be our root topic
					// Obtain the desired name for a new root topic	        	
					var rootName = prompt(helper.Internationalise(cmp, 'ToolLabelTreeAdd') + ' - ' + helper.Internationalise(cmp, 'AdviceLabelListingName'), '');
					if (rootName == '' || rootName + '' == 'null') { return; }


					helper.showSpinner(cmp, helper);

					var act = cmp.get("c.dropNewTopic");
					act.setParams({
						"TopicContent": rootName,
					});

					// Add callback to process returned results
					act.setCallback(helper, function (response, cmp) {

						// Need to swap to the new root here:
						// Return value if successful should be ID of the new root topic
						if (response.getState() == 'SUCCESS') {
							cmp.set("v.RootNode", response.getReturnValue());

							// If we are changing root, this is also the selected record in these cases
							cmp.set("v.HelpRecordId", response.getReturnValue());

							helper.initialiseTree(cmp, event, helper);

						} else {
							cmp.set("v.Diags", "ERR! " + response.getReturnValue());
						}
					});

					$A.enqueueAction(act);
					break;

				case 'TreePrint':

					// Open printable view of the tree
					var U = CRoot + '/apex/iahelp__IHLUXOutHost?NSApp=iahelp&App=appIH';
					U += '&NSComp=iahelp';
					U += '&Comp=IHTree';
					U += '&Parms=PrintView~true^LevelIndentation~3^MaxDepth~' + cmp.get("v.MaxDepth") + '^RootNode~' + cmp.get("v.RootNode");
					U += '&HookMode=0';

					window.open(U, 'TreePrint');
					break;

				case 'TreeVotes':
					// Obtain and display statistics concerning clicks on the nodes forming the current tree
					helper.showSpinner(cmp);
					console.log('Inside TreeVotes Case');

					var act = cmp.get("c.getTreeVotes");
					act.setParams({
						"RootNode": cmp.get("v.RootNode")
					});

					// Add callback to process returned results
					act.setCallback(this, function (response, cmp) {

						helper.hideSpinner(cmp);

						var LIs = cmp.get("v.ListingItems");
						var obj;
						var nods = [];
						var idx;
						var styl;

						if (response.getState() === "SUCCESS") {

							try {
								obj = JSON.parse(response.getReturnValue());
							} catch (e) {
								cmp.set("v.Diags", "IHTree - Tree Stats - Error parsing the following JSON return value (" + e + "): " + response.getReturnValue());
								return;
							}


							// Now recreate our Node member data from our Listing Items (as we do on initialising)
							// but with amended "style" data for each 
							nods[undefined] = { Label: "Root", items: [] };

							LIs.forEach(function (v) {

								// Default to a white vote bar
								styl = 'ffffff';

								// If node (Topic) Id is to be found in return values - meaning a vote has been cast on the Topic...
								obj.forEach(function (o) {
									if (v.Id == o.Name) {

										// ... Adopt the style applicable to the vote option, if set
										if (o.Value != '' && o.Value != null) {
											styl = o.Value;
										}
									}
								});
								console.log(' style ' + styl);
								// Embed this style into node            
								nods[v.Id] = { Style: 'margin-right: 5px; border-right: solid 10px #' + styl + ';', Id: v.Id, ParentId: v.Parameters, Expanded: true, Label: v.Label, Title: v.Title, StyleClass: v.StyleClass, Icon: v.Icon, IconLabel: v.IconLabel, RowState: v.RowState, items: [] };

							});


							// Now loop through nodes again, adding each to the items of its parent
							try {
								LIs.forEach(function (v) {
									idx = v.Parameters;
									if (idx + '' == 'null' || idx == '') { idx = undefined; }
									nods[idx].items.push(nods[v.Id]);
								});
							} catch (e) { }


							// With node state set, we can pass this to our member data for rendering
							cmp.set("v.Nodes", nods[undefined].items);

							// Offer further information in diagnostics
							cmp.set("v.Diags", "DONE");
						}
					});

					// Send action
					$A.enqueueAction(act);
					break;


				case 'TreeStats':
					// Obtain and display statistics concerning clicks on the nodes forming the current tree
					helper.showSpinner(cmp);

					var act = cmp.get("c.getTreeStats");
					act.setParams({
						"RootNode": cmp.get("v.RootNode")
					});

					// Add callback to process returned results
					act.setCallback(this, function (response, cmp) {

						var LIs = cmp.get("v.ListingItems");
						var obj;
						var nods = [];
						var idx;
						var R;
						var ttl;
						var totalClicks = 0;
						var maxClicks = 0;
						var msg1;
						var msg2;

						helper.hideSpinner(cmp);

						if (response.getState() === "SUCCESS") {

							try {
								obj = JSON.parse(response.getReturnValue());
							} catch (e) {
								cmp.set("v.Diags", "IHTree - Tree Stats - Error parsing the following JSON return value (" + e + "): " + response.getReturnValue());
								return;
							}

							// Count total clicks based on all returned stats name/value pair objects
							obj.forEach(function (o) {
								totalClicks += Math.abs(o.Value);
								if (Math.abs(o.Value) > maxClicks) {
									maxClicks = Math.abs(o.Value);
								}
							});

							// Now recreate our Node member data from our Listing Items (as we do on initialising)
							// but with amended "style" data for each 
							nods[undefined] = { Label: "Root", items: [] };

							LIs.forEach(function (v) {

								// Set colour based on interaction statistics (total number of clicks) obtained for each node             	
								R = 0;
								obj.forEach(function (o) {
									if (v.Id == o.Name) {
										R = Math.abs(o.Value);
									}
								});

								ttl = R + ' ' + helper.Internationalise(cmp, 'AdviceLabelStatsClicks');

								// Factor R as a fraction of total views
								R = 255 - Math.floor((R / maxClicks) * 255);

								// Embed this style into node            
								nods[v.Id] = { Style: 'margin-right: 5px; border-right: solid 10px rgb(255,' + R + ',' + R + ');', Id: v.Id, ParentId: v.Parameters, Expanded: true, Label: v.Label, Title: ttl, StyleClass: v.StyleClass, Icon: v.Icon, IconLabel: v.IconLabel, RowState: v.RowState, items: [] };

							});


							// Now loop through nodes again, adding each to the items of its parent
							try {
								LIs.forEach(function (v) {
									idx = v.Parameters;
									if (idx + '' == 'null' || idx == '') { idx = undefined; }
									nods[idx].items.push(nods[v.Id]);
								});
							} catch (e) { }


							// With node state set, we can pass this to our member data for rendering
							cmp.set("v.Nodes", nods[undefined].items);

							// Offer further information in diagnostics
							msg1 = helper.Internationalise(cmp, 'MessageStatsDiags1');
							msg2 = helper.Internationalise(cmp, 'MessageStatsDiags2');
							cmp.set("v.Diags", totalClicks + ' ' + msg1 + ' "' + cmp.get("v.Title") + '". ' + msg2 + ' ' + maxClicks);
						}
					});

					// Send action
					$A.enqueueAction(act);
					break;
			}
		}


		// In certain cases, only respond to our own child tree nodes
		if (src == cmp.get("v.ComponentId") + 'TreeNodes') {

			// NOTE: tree node tool parameters are in the form:
			// Node Id , Parent Node Id 
			// (see IHTreeNode markup)

			switch (act) {

				case 'ViewRLE':
					// Raise a record select event citing the relevant reading list entry
					var params = parms.split(',');
					var LIs = cmp.get("v.ListingItems");
					var rec;

					LIs.forEach(function (LI) {
						// Parameters will be in the form [help topic Id],[reading list id]
						if (LI.Id == params[0]) {

							// RL Tree provider uses row state to store reading list ENTRY id - which is what we need
							rec = LI.RowState;
						}
					});

					var appEvent = $A.get("e.c:selectTopic");
					appEvent.setParams({ "RecordId": rec });
					appEvent.setParams({ "SourceComponent": cmp.get('v.ComponentId') });
					appEvent.fire();

					break;

				case 'RLDelete':
					// Delete the reading list whose tool was clicked
					var proceed = false;
					var params = parms.split(',');
					proceed = confirm(helper.Internationalise(cmp, 'MessageDeleteWarning'));

					if (proceed == true) {

						var act = cmp.get("c.deleteReadingList");
						act.setParams({
							"RLID": params[0]
						});

						// Add callback to process returned results
						act.setCallback(this, function (response, cmp) {

							// On completion, force re-initialise of guide listing if successful and report any diagnostics
							if (response.getState() == 'SUCCESS') {
								alert(helper.Internationalise(cmp, 'MessageGenericTaskComplete'));

								// This handler has come from a tree node click - so the root of the
								// current tree will no longer exist! Set to no root
								// and reinitialise tree

								cmp.set("v.RootNode", '[None]');
								cmp.reInitialise();

							} else {
								alert(helper.Internationalise(cmp, 'MessageGenericError'));
							}
						});
						$A.enqueueAction(act);

					}
					break;

				case 'ToggleListingTools':
					// Show / hide node listing tools collapsed to ellipsis
					helper.toggleListingTools(cmp, parms);
					break;


				case 'ReconfigureCloneElement':
				case 'ReconfigureDeleteElement':
				case 'ReconfigureAddFilter':
				case 'ReconfigureDeleteFilter':
				case 'ReconfigureAddFilterCriterion':
				case 'ReconfigureDeleteFilterCriterion':

				case 'RLBuilderAddEntry':
				case 'RLBuilderDeleteEntry':

					// Data manipulations when in reconfigure mode
					// Data manipulations when in reading list builder

					var proceed = false;
					var addingRecord = false;
					var A;
					var diags;
					var params = parms.split(',');

					// Reading list entry ops
					if (act == 'RLBuilderAddEntry') {
						A = cmp.get("c.addReadingListEntry");
						proceed = true;
						addingRecord = true;
					}
					if (act == 'RLBuilderDeleteEntry') {
						A = cmp.get("c.deleteReadingListEntry");
						proceed = confirm(helper.Internationalise(cmp, 'MessageDeleteWarning'));

						// Clickable provides a TOPIC ID - we need the underlying RL Entry ID
						// so we need to look for this here: the RLs tree node provider puts
						// entry ID into listing item's RowState member...

						var LIs = cmp.get("v.ListingItems");

						LIs.forEach(function (LI) {
							if (LI.Id == params[0]) {
								params[0] = LI.RowState;
							}
						});
					}

					// Element ops
					if (act == 'ReconfigureCloneElement') {
						A = cmp.get("c.cloneHelpedElement");
						proceed = true;
						addingRecord = true;
					}
					if (act == 'ReconfigureDeleteElement') {
						A = cmp.get("c.deleteHelpedElement");
						proceed = confirm(helper.Internationalise(cmp, 'MessageDeleteWarning'));
					}

					// Filter ops
					if (act == 'ReconfigureAddFilter') {
						A = cmp.get("c.addHelpFilter");
						proceed = true;
						addingRecord = true;
					}
					if (act == 'ReconfigureDeleteFilter') {
						A = cmp.get("c.deleteHelpFilter");
						proceed = confirm(helper.Internationalise(cmp, 'MessageDeleteWarning'));
					}

					// Criteria ops
					if (act == 'ReconfigureAddFilterCriterion') {
						A = cmp.get("c.addFilterCriterion");
						proceed = true;
						addingRecord = true;
					}
					if (act == 'ReconfigureDeleteFilterCriterion') {
						A = cmp.get("c.deleteFilterCriterion");
						proceed = confirm(helper.Internationalise(cmp, 'MessageDeleteWarning'));
					}


					if (proceed == true) {
						A.setParams({
							"SubjectId": params[0],
						});


						A.setCallback(this, function (response, cmp) {
							if (response.getState() === 'SUCCESS') {
								diags = helper.Internationalise(cmp, response.getReturnValue());

								if (diags.toUpperCase().indexOf('ERROR') == -1) {
									cmp.set("v.HelpRecordId", diags);

									// Deal with roots relating to the reading list tree provider
									var root = cmp.get("v.RootNode");
									var RLMarker = 'rL_';

									if (root.startsWith(RLMarker)) {
										root = root.substring(RLMarker.length);
									}
									cmp.set("v.RootNode", root);

									cmp.reInitialise();

									// Issue a passthrough instructing any autoform that may be listening 
									// to navigate to any new record in edit mode
									if (addingRecord == true) {
										var appEvent = $A.get("e.c:evtPassThrough");
										appEvent.setParams({ "SourceComponent": cmp.get("v.ComponentId") });
										appEvent.setParams({ "ActionCode": 'RecordAdded' });
										appEvent.setParams({ "Parameters": diags });
										appEvent.fire();
									}
								}

							} else {
								diags = 'ERR!';
							}

							cmp.set("v.Diags", diags);
						});

						// Send action
						$A.enqueueAction(A);
					}

					break;

				case 'RLBuilderMoveUp':
				case 'RLBuilderMoveDown':
				case 'TreeEditSortOrder':

					// Request to edit the sort order of a node on a sortable tree

					var A = cmp.get("c.moveReadingListEntry");
					var isHelpTopic = false;
					var LIs = cmp.get("v.ListingItems");
					var params;
					var Node;		// This is (help topic) ID as sent via event
					var RLE;		// This is reading list entry ID (which we must look up)
					var root = cmp.get("v.RootNode");

					// Deal with roots relating to the reading list tree provider						
					var RLMarker = 'rL_';

					if (root.startsWith(RLMarker)) {
						root = root.substring(RLMarker.length);
					}


					var newPos;
					var diags;
					var droppedTo;
					var parentNode; // For adding peer
					var keyTypes = cmp.get("v.GlobalSettings.iahelp__SFObjectIds__c");
					keyTypes = keyTypes.split('^');

					if (act == 'TreeEditSortOrder') {
						// Node to move and its sort order will have come directly in event parameters
						params = parms.split(D1);
						Node = params[0];
						if (params[3] + '' == 'null') {
							newPos = 0;
						} else {
							newPos = params[3];
						}
						droppedTo = params[2];

					} else {
						// For move up / down, we need to work out desired sort order from moved node
						A = cmp.get("c.moveReadingListEntry");
						params = parms.split(',');
						Node = params[0];

						LIs.forEach(function (LI) {
							if (LI.Id == Node) {
								newPos = parseInt(LI.SortValue);
							}
						});

						if (act == 'RLBuilderMoveUp') {
							newPos -= 1;
							if (newPos < 0) { newPos = 0; }
						} else {
							newPos += 1;

							// Reading list tree has 2 listing items that represent things other than entries
							// (RL name and an RLs node) so max order is length minus (2 non-entries + 1 as order is zero based)
							if (newPos >= LIs.length - 2) { newPos = LIs.length - 3; }
						}

					}

					// Clickable provides a TOPIC ID - we need the underlying RL Entry ID
					// so we need to look for this here: the RLs tree node provider puts
					// entry ID into listing item's RowState member...
					LIs.forEach(function (LI) {
						if (LI.Id == Node) {
							RLE = LI.RowState;
						}
						if (LI.Id == droppedTo) {
							parentNode = LI.Parameters;
						}
					});


					// RLE (row state) may now be a reading list entry ID (RL Tree provider) 
					// OR the row state of a topic (e.g., bookmarked, with or without peer trees etc):
					// Check here and respond accordingly...

					var RLEUC = (RLE + '').toUpperCase();
					if (RLE == '' || RLEUC.indexOf('HASPEERS') != -1 || RLEUC.indexOf('BOOKMARKED') != -1) {

						var P = parms.split(D1);
						var child = P[0];
						var oldParent = P[1];
						var newParent = parentNode;


						// new server method parameters setting
						A = cmp.get("c.reOrderTreeNodes");
						A.setParams({
							"OldReferring": oldParent,
							"NewReferring": newParent,
							"Related": child,
							"pos": newPos,
						});

					} else {
						A.setParams({
							"SubjectId": RLE,
							"newPos": newPos,
						});
					}

					// Add callback to process returned results
					A.setCallback(this, function (response, cmp) {

						// Re-query this tree so as to reflect new sort order
						// helper.initialiseTree(cmp, event, helper);

						if (response.getState() === 'SUCCESS') {
							diags = helper.Internationalise(cmp, response.getReturnValue());

							// CHECK: DOES HRID HERE NEED TO BE SET TO RL AS OPPOSED TO MOVER (NODE)?
							// IN ALL CASES, OR JUST RL MANIPULATION?

							if (diags.toUpperCase().indexOf('ERROR') == -1) {
								cmp.set("v.HelpRecordId", Node);
								cmp.set("v.RootNode", root);
								cmp.reInitialise();
							}

						} else {
							var errors = response.getError();

							if (errors) {
								if (errors[0] && errors[0].message) {
									diags = 'ERR ' + errors[0].message;
								}
							} else {
								diags = 'ERR!';
							}
						}

						cmp.set("v.Diags", diags);

					});

					// Send action
					$A.enqueueAction(A);
					break;


				case 'RLShareLink':
					// Show a link that can be used to direct a user to a particular record
					var U = document.location.origin;
					var params = parms.split(',');

					// Add RL instructions
					U += '/' + params[0];

					// Advise user	
					prompt(helper.Internationalise(cmp, 'MessageShareViaURL'), U);

					break;
                case 'Search':	
                    var src = 'c:IHList';
                    var Ttl;
                    var CCfg;
                    var TCxt;
                    var NDM = helper.Internationalise(cmp, 'AdviceLabelSearchForExistingItem');
                    const theId = [
                        "Ellipsis",
                        "RelatedHelpLink",
                        "1",
                        "0"
                    ];
                    
                    Ttl = 'Search';
                    CCfg = 'SearchRelatedHelp';
                    TCxt = 'LinkTopics';
                    
                    var aMap = {
                        "SuppressHeader": false,
                        "SuppressFooter": false,
                        "SuppressPoweredBy": true,
                        "TreeSuppressListingTools": false,
                        "Height": 400,
                        "CardConfig": CCfg,
                        "ToolContext": TCxt,
                        "NoDataMessage": NDM,
                        "ComponentId": "theNewRelDialogue",
                        "IHContext": cmp.get("v.IHContext"),
                        "recordId": cmp.get("v.IHContext"),
                        "Parent": cmp
                    };
                    
                    
                    helper.setDialogueActionCode(cmp, theId[1]);
                    helper.doDialogue(Ttl, 'LUX', src, aMap, 420, false, false, false, cmp, true);
                    
                    break;
                    
				case 'TreeRefocus':
					// Make the row this tool click applies to the root of the tree
					var P = parms.split(',');
					cmp.set("v.RootNode", P[0]);
					cmp.set("v.IHContext", cmp.get("v.RootNode"));
					helper.initialiseTree(cmp, event, helper);
					break;

				case 'TreeShowPeers':
					// List other trees a given node participates in...
					// Show the crumbs area
					$A.util.toggleClass(dvPeers, 'slds-hide');

					// Get our crumb control to show crumbs for the selected record:
					// This, the clicked Node Id, is the first of the parameters...
					var P = parms.split(',');
					var C = cmp.find("Crumbs");
					C.set("v.HelpRecordId", P[0]);
					C.initialiseCrumbs(cmp, event, helper);

					break;

				case 'TreeAddChild':
				case 'TreeAddPeer':
					// These actions come from tree listing tools - to create a new topic then relationship to it.
					// Creation of relationship to the new topic
					// is handled elsewhere (see HelpRecordChange): we take note here of the parameters (node ID, parent ID)
					// obtained via the pass through plus the desired action, for use once topic is created...
					cmp.set("v.OpsCache", act + D1 + parms);

					// Create the topic (which in turn will fire Help Record Change - below)
					helper.createNewTopic(cmp, '', false);

					break

				case 'TreeAddChildFromExisting':
					// This action comes from D&D of a listing row: dropping row onto tree node creates new parent relationship

					var act = cmp.get("c.createRelationship");
				
					// [Parameters] are in the form:
					// Node Id , Parent Node Id 

					// NOTE: relationship may or may not be a help topic relationship - depending on parent record type
					// (essentially depending on tree provider / node types in play).
					// The create relationship controller method works out which types are in play and 
					// creates records accordingly...
                    
                    var NIDs = [];
                    NIDs = parms.split(D1);
                    var childId = NIDs[0];
                    var newParentId = NIDs[1];
                    //alert for when child node is referenced with parent node creating circular relationship.
                    if (helper.isCircularReference(cmp, childId, newParentId)) {
                        var proceed = confirm(helper.Internationalise(cmp,'MessageTreeRecursionWarning'));
                        if (!proceed) {
                            return; // Block the operation if user presses Cancel
                        }
                    }
					act.setParams({
						"Referring": NIDs[1],
						"Related": NIDs[0],
						"RelationType": "Parent"
					});

					// Add callback to process returned results
					act.setCallback(this, function (response, cmp) {

						// Select the new child record 
						cmp.set("v.HelpRecordId", NIDs[0]);

						// Re-query this tree so as to include new topic
						helper.initialiseTree(cmp, event, helper);
						cmp.set("v.Diags", response.getReturnValue());
					});

					// Send action
					$A.enqueueAction(act);

					break;

				case 'TreeDeleteNode':
					// Delete the tree node (parent relationship) represented by the clicked tree listing tool

					if (confirm(helper.Internationalise(cmp, 'MessageDeleteWarning'))) {

						var act = cmp.get("c.deleteRelationship");
						var P = parms.split(',');
						var rel = P[0];
						var ref = P[1];

						act.setParams({
							"Referring": ref,
							"Related": rel,
							"RelationType": "Parent"
						});

						// Add callback to process returned results
						act.setCallback(this, function (response, cmp) {

							// Re-query this tree so as to include new topic				        	
							helper.initialiseTree(cmp, event, helper);
							cmp.set("v.Diags", response.getReturnValue());
						});

						// Send action
						$A.enqueueAction(act);
					}

					break;

				case 'TreeReparentNode':
					// Move an existing node on a tree by D&D 

					var act = cmp.get("c.reparentTreeNode");
					var P = parms.split(D1);
					var child = P[0];
					var oldParent = P[1];
					var newParent = P[2];

					act.setParams({
						"OldReferring": oldParent,
						"NewReferring": newParent,
						"Related": child
					});

					// Add callback to process returned results
					act.setCallback(this, function (response, cmp) {

						// Select the re-parented record 
						cmp.set("v.HelpRecordId", child);

						// Re-query this tree so as to include new topic
						helper.initialiseTree(cmp, event, helper);
						cmp.set("v.Diags", response.getReturnValue());
					});

					// Send action
					$A.enqueueAction(act);

					break;

				default:
					console.log('IHTree "' + cmp.get("v.ComponentId") + '" responding to passthrough from own nodes : action "' + act + '" not available in this release');
			}

		}

	},


	// Respond to changes to our Help Record Id member data - as opposed to any record selected event:
	// In certain cases, this will be the sign that part of a multi-call operation has completed and we 
	// should continue processing...
	HelpRecordChange: function (cmp, event, helper) {

		try {
			// Check Ops cache to see if we need to act: empty it as we do so
			var Op = cmp.get("v.OpsCache");
			var D1 = cmp.get("v.Delimiter");
			cmp.set("v.OpsCache", "");


			// Only respond if ops cache contained instructions, indicating work is to be done
			if (Op != '') {

				// Ops cache is in form: 
				// [Action Code][Delimiter][Parameters]
				// (See handlePassThroughs etc)
				Op = Op.split(D1);

				switch (Op[0]) {

					case 'TreeAddChild':
					case 'TreeAddPeer':

						var act = cmp.get("c.createRelationship");
						var rel = cmp.get("v.HelpRecordId");

						// [Parameters] are in the form:
						// Node Id , Parent Node Id 
						// (see IHTreeNode markup)
						var NIDs = Op[1].split(',');
						var ref;

						// Whether adding a parent or child, the relationship type is, in fact, Parent:
						// What varies is the referring topic:
						if (Op[0] == 'TreeAddChild') {
							ref = NIDs[0];		// Referrer is the Topic whose tool was clicked

						} else {
							ref = NIDs[1];		// Referrer is the parent of the Topic whose tool was clicked
						}

						act.setParams({
							"Referring": ref,
							"Related": rel,
							"RelationType": "Parent"
						});


						// Add callback to process returned results
						act.setCallback(this, function (response, cmp) {

							// Re-query this tree so as to include new topic
							helper.initialiseTree(cmp, event, helper);
							cmp.set("v.Diags", response.getReturnValue());
						});

						// Send action
						$A.enqueueAction(act);

						break;

					default:
					// Do nothing
				}
			}

		} catch (e) {
			alert('(Help Record Change): ' + e);
		}
	},


	// Respond to changes in our root node member data (delegated)
	RootNodeChange: function (cmp, event, helper) {
		helper.RootNodeChange(cmp, event, helper);
	},


	// Hide / Close our crumb trail component
	closeCrumb: function (cmp, event) {
		var dvPeers = cmp.find("PopoverPeers");
		$A.util.addClass(dvPeers, 'slds-hide');
	},


	// Expand / collapse an accordion section - delegated
	toggleAccordionSection: function (cmp, event, helper) {
		helper.toggleAccordion(cmp, event.currentTarget.id);
	},


	// Return a value indicating whether D&D ops are allowed at all - based on permissions etc
	dragAllowed: function (cmp, event, helper) {
		return helper.dragAllowed(cmp, event);
	},


	// Return a boolean indicating whether drop is allowed onto target based on dragged data
	dropAllowed: function (cmp, event) {
		return helper.dropAllowed(cmp, event);
	},


	// 'Set root' drop zone handling: Show whether or not drop will be allowed
	doDragOver: function (cmp, event, helper) {

		if (helper.dragAllowed(cmp, event) == true) {

			event.preventDefault();

			var T = event.target;

			// All the time we cannot sniff dragged data, visual clues won't really work...		    
			// ... so just style our drop zone on drag regardless - ops are prevented on drop
			// at which point the data can be sniffed...

			if (event.target.getAttribute('data-DDID') == 'DropTargetReRoot') {
				$A.util.addClass(T, 'DropTargetRootActive');
			} else {
				if (helper.dropAllowed(cmp, event) == true) {
					$A.util.addClass(T, 'DropTargetActive');
				} else {
					$A.util.addClass(T, 'DropTargetUnavailable');
				}
			}
		}
	},


	// 'Set root' drop zone handling: Remove any drag over style hints
	doDragLeave: function (cmp, event, helper) {

		event.preventDefault();
		var T = event.target;
		$A.util.removeClass(T, 'DropTargetActive');
		$A.util.removeClass(T, 'DropTargetUnavailable');
		$A.util.removeClass(T, 'DropTargetRootActive');
	},


	// 'Set root' drop zone handling: Take action when drop occurs
	doDrop: function (cmp, event, helper) {

		event.preventDefault();

		var dat = event.dataTransfer.getData("text");
		var D1 = cmp.get("v.Delimiter");
		var TNode = event.target;
		var parms = [];

		console.log('IHTree "' + cmp.get("v.ComponentId") + '" - data dropped onto root reset area: ' + dat);

		parms = dat.split(D1);

		// Remove active styling
		$A.util.removeClass(TNode, 'DropTargetRootActive');


		// Having removed visual clues, take no further action unless drop ops are allowed
		if (helper.dropAllowed(cmp, event) == false) {
			return;
		}

		// Potentially, respond according to request content
		switch (parms[0]) {
			case 'TreeNode':
			case 'ListRow':
			case 'DetailTitle':

				// In practice as of this release, all drops of topic from any source result in re-root of
				// tree with current provider
				cmp.set("v.RootNode", parms[1]);
				cmp.set("v.IHContext", cmp.get("v.RootNode"));
				helper.initialiseTree(cmp, event, helper);
				break;

		}

	},


	// Expose card's HTML parser to nodes
	getSafeHTML: function (cmp, event, helper) {
		var sHTML = cmp.get("v.sHTML");
		return helper.getSafeHTML(sHTML);
	},
        
        //log geolocation on tree node click interactions
        getlogLUXInteractions: function(cmp, event, helper) {
            
			var params = event.getParam('arguments');
			console.log('Params '+params);
            
            let iTyp = params[1];
            let description = params[2];
            let ihContext = params[3];

            helper.logLUXInteractions(cmp, iTyp, description, ihContext);
        },

})