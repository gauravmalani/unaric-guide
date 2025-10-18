({

	// Set sizing parameters based on incoming size setting
	Init : function(cmp, event, helper) {
	    //var coloo = cmp.get("v.UXThemeTileColour1");
        //cmp.set("v.Tileheddercolour",'background-color:#'+coloo);
        //var coloo1 = cmp.get("v.UXThemeTileColour2");
        //var coloo2 = cmp.get("v.UXThemeTileColour3");
        //var coloo3 = cmp.get("v.UXMenuBackgroundColourTile");
        //var coloo4 = cmp.get("v.UXMenuFontColourTile");
       //console.log('coloo');
      // console.log(coloo,coloo1,coloo2,coloo3,coloo4);
        
		switch (cmp.get("v.Size")) {
			case 'Smallest':
				cmp.set("v.IconSize", 'lg');
                cmp.set("v.heightclass",'height: 140px;');
                cmp.set("v.iconesize",'xx-small');
				break;
			
			case 'Small':
				cmp.set("v.IconSize", '3x');
                cmp.set("v.heightclass",'height: 225px;');
                cmp.set("v.iconesize",'small');
				break;

			case 'Medium':
				cmp.set("v.IconSize", '5x');
                cmp.set("v.heightclass",'height:265px;');
                cmp.set("v.iconesize",'medium');
				break;

			case 'Large':
				cmp.set("v.IconSize", '7x');
                cmp.set("v.heightclass",'height: 360px;');
                cmp.set("v.iconesize",'large');
				break;
				
			default:
				cmp.set("v.IconSize", '5x');
				break;
		}
		
	},
	
})