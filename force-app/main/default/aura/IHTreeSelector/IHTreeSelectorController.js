({


	// Setup Tree collection object member data from design parameters
	init: function (cmp, event, handler) {
		try {
			// Only act if we have Tree IDs and Names
			var TIDs = cmp.get("v.CSVTreeIDs");
			var TNames = cmp.get("v.CSVTreeNames");
			var TProviders = cmp.get("v.CSVNodeProviders");
			var i;
			var str;
			var obj = [];

			// NB : DON'T check providers here: this can be blank - if there is only a single tree option and 
			// it uses the default provider for its node ID. Ids and Labels, however, cannot be blank.
			// The subsequent check on matching numbers of Ids / Labels / Providers always applies...
			if (TIDs != '' && TIDs + '' != 'null' && TNames != '' && TNames + '' != 'null') {

				// Only act if we have the same number of names, providers and IDs
				TIDs = TIDs.split(',');
				TNames = TNames.split(',');
				TProviders = TProviders.split(',');

				if (TIDs.length != TNames.length || TNames.length != TProviders.length) {
					cmp.set('v.Diags', 'Configuration error: Please supply the same number of Tree Names, Providers & IDs');
				} else {

					str = '[';

					for (i = 0; i < TIDs.length; i++) {
						str += '{"Id":"' + TIDs[i] + '","Name":"' + TNames[i] + '","Provider":"' + TProviders[i] + '"},'
					}
					str = str.substring(0, str.length - 1);

					str += ']';

					obj = JSON.parse(str);
					cmp.set('v.Trees', obj);
				}
			}


			// With basic setup complete, obtain a unique identifier for this component
			try {
				var act = cmp.get("c.getGUID");
				act.setCallback(this, function (response, cmp) {
					cmp.set("v.UniqueIdent", response.getReturnValue());
				});
				$A.enqueueAction(act);

			} catch (e) {
				console.log("Tree Selector - error obtaining component UID: " + e);
			}


		} catch (e) {
			cmp.set('v.Diags', 'Tree Selector Initialisation Error: ' + e);
		}
	},


	// Raise a pass-through indicating that a tree has been selected
	selectTree: function (cmp, event, helper) {

		var theId = event.target.id;
		var badges = document.querySelectorAll('.slds-badge');
		var selectedBadge = document.getElementById('badge_' + theId);
		var Trees = cmp.get("v.Trees");
		var provider = '';


		console.log('Tree selector "' + cmp.get("v.ComponentId") + '": selecting badge ' + theId);

		// Loop through our tree objects to find the one selected and obtain its provider info
		Trees.forEach(function (T) {
			if (T.Id == theId) {
				provider = T.Provider;
			}
		});


		console.log('Tree selector: provider set to "' + provider + '"');

		try {
			// Fire AURA event to cue a tree on any listening component
			var appEvent = $A.get("e.c:evtPassThrough");
			appEvent.setParams({ "SourceComponent": cmp.get("v.ComponentId") });
			appEvent.setParams({ "ActionCode": "SelectTree" });
			appEvent.setParams({ "Parameters": theId + '^' + provider });
			appEvent.fire();

			console.log('Tree selector: aura event raised');

		} catch (e) {
			// Don't know why app event can be undefined if other aura components not present on page?
		}

		// Log interaction to fire LWC event with same details
		var message = { ActionCode: 'SelectTree', Parameters: theId + '^' + provider, SourceComponent: cmp.get("v.ComponentId") };
		message = JSON.stringify(message);
		//var act = cmp.get("c.logLUXInteraction");


		/*  act.setParams({ 
					"iTyp" : "0",
					"Description" : message,
					"IHContext" : cmp.get("v.UniqueIdent")
			});     */

		/*   act.setCallback(this, function (response, cmp){ 
			 if (response.getState() === 'SUCCESS') {
				 // Do nothing if OK
				 console.log('Tree Selector "' + cmp.get("v.ComponentId") + '" (' + cmp.get("v.UniqueIdent") + '): selected "' + theId + '^' + provider + '" - Platform event raised');
			 } else {
				 console.log('Tree Selector "' + cmp.get("v.ComponentId") + '" (' + cmp.get("v.UniqueIdent") + '): seletion of "' + theId + '^' + provider + '" caused Platform event ERROR');
			 }
		 }); */

		// Send action
		// $A.enqueueAction(act);

		helper.logLUXInteractions(cmp, 0, message, cmp.get("v.UniqueIdent")).then((response) => {
			//do nothing to response.
			if (response.getState() === 'SUCCESS') {
				// Do nothing if OK
				console.log('Tree Selector "' + cmp.get("v.ComponentId") + '" (' + cmp.get("v.UniqueIdent") + '): selected "' + theId + '^' + provider + '" - Platform event raised');
			} else {
				console.log('Tree Selector "' + cmp.get("v.ComponentId") + '" (' + cmp.get("v.UniqueIdent") + '): seletion of "' + theId + '^' + provider + '" caused Platform event ERROR');
			}
		});

		// Mark our selected item
		console.log('Tree selector: marking badge...');

		for (var i = 0; i < badges.length; i++) {
			$A.util.removeClass(badges[i], 'slds-theme--inverse');
		}

		$A.util.addClass(selectedBadge, 'slds-theme--inverse');
		console.log('Tree selector: marked');

	},


})