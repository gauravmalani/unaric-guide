({
	 afterRender: function(component, helper) {
       console.log(' afterRender ');
         var c = document.getElementsByClassName("DialogueContainer")[0];
        console.log(c);
    },
})