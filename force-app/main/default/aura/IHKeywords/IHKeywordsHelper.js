({

	// Create listing of sentences featuring each selected keyword
	buildSentences : function (cmp, helper, elem) {
			 
		var keywordList = cmp.get("v.selectedKeywordsList");
		var inputText = cmp.get("v.textValue");
		var sentences = inputText.split('.');
		var keywordVsSentence = [];
		 
		for(var i = 0; i < keywordList.length; i++){
		    var sentenceList = [];
		    
		 	for(var j = 0; j < sentences.length; j++){
		        var sentenceText = sentences[j].toLowerCase();
		       // var textToMatch = '/[^a-zA-Z0-9]*'+keywordList[i].toLowerCase()+'[^a-zA-Z0-9]*/g';
		        var textToMatch = keywordList[i].toLowerCase();
		        
			     if(sentenceText.includes(textToMatch)){
			         sentenceList.push(sentences[j]);                             
			     }
		 	}
		 	
		 	var str = {"keyword" : keywordList[i], "sentence" : sentenceList};
		    keywordVsSentence.push(str);
		}
		 
		console.log(keywordVsSentence);
		cmp.set("v.Sentences",keywordVsSentence);
		
	},
	
})