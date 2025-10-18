({

	setSize : function(cmp, helper) {
		
		// Obtain width data and set image div size accordingly
		try {
			var W = cmp.find("Sizer").getElement().offsetWidth;		
			cmp.set("v.Width", W + 'px');
			console.log('------' + W);

		} catch (e) {}
	},

    
})