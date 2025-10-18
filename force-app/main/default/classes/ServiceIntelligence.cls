/////////////////////////////////////////////////////////////////////////////////////////////////////
// CLASS OFFERING INTELLIGENT CONTENT ANALYSIS SERVICES
//
// Prashant Kumar for Improved Apps
// October 2022
/////////////////////////////////////////////////////////////////////////////////////////////////////

global with sharing class ServiceIntelligence {

    // An interface that contracts to analyse bodies of supplied text
    global interface SemanticAnalyser{
         map<string, integer> Analyse(list<string> InputTextWords, integer QualityThreshold, integer MaxPhraseLength);
    }
   
    public static list<string> refinedWordList = new list<string>();
    public static map<string,string> mapOfWordVsAnalyser = new map<string,string>();
    public static string actualText = '';
    public static Set<String> avoidList = New Set<String>();
              
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////    
    // Asynchronous mode handler
    /////////////////////////////////////////////////////////////////////////////////////////////////////    

    @future
    public static void asynchAnalyser(String InputText, integer QualityThreshold, integer MaxPhraseLength, string DesiredAnalysers, string GUID) {   

        // Use helper method to perform operations common to synchronous & asynchronous modes
        string retVal = analyseHelper(InputText, QualityThreshold, MaxPhraseLength, DesiredAnalysers);
        
        // Advise callers of asynch operation completion via platform event
        iahelp__LWC_Aura_Interaction_Event__e pfEvent = new iahelp__LWC_Aura_Interaction_Event__e();
        pfEvent.iahelp__Filter__c = GUID;
        pfEvent.iahelp__Parameters__c = retVal;
        Database.SaveResult result1 = EventBus.publish(pfEvent);
            
        // Inspect publishing result for each event
        if (result1.isSuccess()) {
            System.debug('Successfully published event.');
            
        } else {
            ServiceIHLists.ListingItem LI2 = new ServiceIHLists.ListingItem();
            
            // Obtain advice message re long running job...
            map<string,string> mapDlgLocs = ServiceLocalisation.getDialogueLocalisations('Globals', false);
            string msg = mapDlgLocs.get('MessageGenericError');

            
            for(Database.Error err : result1.getErrors()) {
                System.debug('Error returned: ' +
                            err.getStatusCode() +
                            ' - ' +
                            err.getMessage());                        
                
                LI2.Id = 'Error returned: ' +
                            err.getStatusCode() +
                            ' - ' +
                            err.getMessage();

                LI2.Label = msg;
                LI2.ActionCode = 'Error';
                LI2.Parameters = 'error';
                LI2.StyleClass = 'error';
            }
            
            string errorRet = JSON.serialize(LI2);
            
            iahelp__LWC_Aura_Interaction_Event__e pfEvent2 = new iahelp__LWC_Aura_Interaction_Event__e();
            pfEvent2.iahelp__Filter__c = GUID;
            pfEvent2.iahelp__Parameters__c = errorRet;
           
            // Call method to publish events
            Database.SaveResult result2 = EventBus.publish(pfEvent2);
        }       
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////    
    // Analyser implementations
    /////////////////////////////////////////////////////////////////////////////////////////////////////    
    
    // An implementation of analyser that scores words based on their frequency of occurrence
    global class analyseWordCount implements SemanticAnalyser {
        
        public map<string, integer> Analyse(list<string> InputTextWords, integer QualityThreshold, integer MaxPhraseLength) {
            
            map<string,integer> retVal = new map<string,integer>();
            
            try {
                //Creating a set of unique words
                  set<string> setOfUniqueWords = new set<string>();
                  for(String strObj : InputTextWords){
                    strObj.trim();         
                    String firstChar;
                    try{
                        firstChar = strObj.substring(0,1).toLowerCase();
                    }catch(exception e){
                        firstChar = '';
                        system.debug(e);
                    }
                    if(firstChar.isAlpha()){
                        strObj = strObj.replaceAll('^[^a-zA-Z0-9\\s+]+|[^a-zA-Z0-9\\s+]+$','');
                        
                    //Checking if set already contains this word in any other case.  
                        if(!setOfUniqueWords.contains(strObj.toLowerCase()) && !setOfUniqueWords.contains(strObj.toUpperCase()) && !setOfUniqueWords.contains(strObj.capitalize())){
                            setOfUniqueWords.add(strObj);
                        }
                   }
                }
                
              
                //Creating listingItem data
                system.debug('Start--> Analyse method after updateNoiseWord method call timestamp '+DateTime.now());    
                // This Block is taking maximum time of execution 
               
                list<string> keywordList = new list<string>();        
                    for(string word : setOfUniqueWords){
                        
                        if(word !='' && word != null){
                            integer count = 0; 
                            
                            for(string actualword : InputTextWords){
                                if(word.replaceAll('^[^a-zA-Z0-9\\s+]+|[^a-zA-Z0-9\\s+]+$','') == actualword.replaceAll('^[^a-zA-Z0-9\\s+]+|[^a-zA-Z0-9\\s+]+$','')){
                               // if(word == actualword){
                                     
                                    ++count;
                                }
                            }
                            if(count >= QualityThreshold){
                                retVal.put(word.toLowerCase(),count); 
                                mapOfWordVsAnalyser.put(word,'ServiceIntelligence.analyseWordCount');
                            }
                        }
                    } 
                
            } catch (exception e) {}
            
            system.debug(' retVal :'+retVal);           
            return retVal;
        }
    }
    

    // An implementation of analyser that scores words based on capitalisation
    global class analyseCapitals implements SemanticAnalyser {
        
        public map<string, integer> Analyse(list<string> InputTextWords, integer QualityThreshold, integer MaxPhraseLength) {
            
            map<string, integer> retVal = new map<string, integer>();
            
            try {
                // Your capitals checking code
                System.debug('analyseCapitals '+InputTextWords);
                boolean flag = false;
                
                 for(string str : InputTextWords){
                    string keyword = str;
                    flag = false;
                    
                    if(keyword.isAllUpperCase()){
                       flag = true;
                    } else {
                        if(keyword.contains('.')){
                            if((keyword.replaceAll('[.]+','')).isAllUpperCase()){
                                flag = true;
                            }                            
                        }                           
                    }
                    
                    if(flag == true){
                        retVal.put(keyword.toLowerCase(),999);
                        mapOfWordVsAnalyser.put(keyword,'ServiceIntelligence.analyseCapitals');
                    }
                }
                
            } catch (exception e) {}
            return retVal;
        }
    }
    
    
    // An implementation of analyser that scores words based on capitalisation
    global class analyseMultiWordPhrases  implements SemanticAnalyser {
        
        public map<string, integer> Analyse(list<string> InputTextWords, integer QualityThreshold, integer MaxPhraseLength) {
            
            system.debug('MaxPhraseLength : '+MaxPhraseLength);
            
            string actualText = ServiceIntelligence.actualText;
            actualText = actualText.toLowerCase();
            map<string, integer> retVal = new map<string, integer>();
            integer numberOfMatches;
            
            if(QualityThreshold > 1 && MaxPhraseLength > 1){                
                try {
                    for(integer i = 0; i < InputTextWords.size() - 1; i++){
                        string textToMatch = '';
                        for(integer j = 1; j <= MaxPhraseLength; j++){
                            textToMatch += InputTextWords[i+(j-1)].toLowerCase() +' ';
                            system.debug('textToMatch :'+textToMatch);
                           //This is the method to check the number of matches
                            string trimmedText = textToMatch.trim();
                            numberOfMatches = actualText.countMatches(trimmedText);
                            system.debug('numberOfMatches :'+numberOfMatches);
                            if(numberOfMatches >= QualityThreshold){
                                if(!retVal.keySet().contains(trimmedText)){
                                    retVal.put(trimmedText,numberOfMatches);
                                    mapOfWordVsAnalyser.put(trimmedText,'ServiceIntelligence.analyseMultiWordPhrases');
                                }
                            }
                        }
                    }
                    
                } catch (exception e) {
                    
                }
            }
            system.debug('retVal : '+retVal);
            return retVal;
        }
    }

    
   // An implementation of analyser that scores words based on existing keywords list
    global class findExisitingKeywords implements SemanticAnalyser {
        
        public map<string, integer> Analyse(list<string> InputTextWords, integer QualityThreshold, integer MaxPhraseLength) {
            
            map<string, integer> retVal = new map<string, integer>();
            list<string> keywordsList = new list<string>();
            list<HelpTopic__c> HTS = [SELECT Id, iahelp__Keyword__c FROM iahelp__HelpTopic__c where iahelp__Keyword__c !=null];
            
            for(HelpTopic__c HT : HTS){
                keywordsList.add(HT.iahelp__Keyword__c);
            }
            system.debug('keywordList : '+keywordsList);
            
            for(string str : InputTextWords){
                if(keywordsList.contains(str)){
                    if(!retVal.keySet().contains(str)){
                           retVal.put(str.toLowerCase(),999);
                           mapOfWordVsAnalyser.put(str,'ServiceIntelligence.findExisitingKeywords');
                    }
                }
            }
            
            system.debug('retVal : '+retVal);
            return retVal;
        }
    }
    

    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Internal support functions
    /////////////////////////////////////////////////////////////////////////////////////////////////////    

    // Helper method to perform common operations of Asynchronous & Synchronous call
    public static string analyseHelper(String InputText, integer QualityThreshold, integer MaxPhraseLength, string DesiredAnalysers) {
            
        String[] Analysers = DesiredAnalysers.split(',');       // Analyses to perform (analyser class names)
        SemanticAnalyser Analyser;                              // An individual instance
        Type t;                                                 // Used in creating instance
        string InputTxt;                                        // Input text for analysis (modified if required)
        map<string, integer> result;                            // Results of an analysis
        map<string, integer> allResults;                        // Results union of all analyses
        ServiceIHLists.ListingItem LI;                          // A listing item representing an individual analysis result 
        List<ServiceIHLists.ListingItem> LIs = new List<ServiceIHLists.ListingItem> (); // Collection of the same   
        result = new map<string, integer>();                    //
        list<String> listOfWords = new list<String>();          // This will store list of clean words (noise words are removed).
        string retVal;                                          // JSON to return
        

        ServiceIntelligence.actualText = InputText;
        
        
        //Remove noise words from the input text
        try{
            listOfWords = InputText.split(' ');
        }
        catch(exception e){}
        listOfWords = RemoveNoiseWords(listOfWords);
        

        // For each desired analyser, create an instance of that class and call its Analyse method
        for (string A : Analysers) {
            
            map<string, integer> tempResult;
            t = Type.forName(A); 
            Analyser = (SemanticAnalyser)t.newInstance();           
            tempResult = Analyser.Analyse(listOfWords, QualityThreshold, MaxPhraseLength);
            
            system.debug(A +'result :'+result);
            system.debug(A +'tempResult :'+tempResult);
            
            // Create union of all results, de-duplicating if required
            result.putAll(tempResult);
            system.debug(A +'result :'+result);     
        }
        
        
        //Sorting final list that's why conversion is needed from set to list
        system.debug('Result :'+result);
        List<String> resultKeys = new List<String>(result.keySet());
        resultKeys.sort();
        
        for(string key : resultKeys){
            LI = new ServiceIHLists.ListingItem();
            LI.Id = key;
            LI.Label = key;
            LI.ActionCode = 'SuggestedKeyword';            
            LI.Parameters = result.get(key)+'';
            if(mapOfWordVsAnalyser.containsKey(key)){
                LI.StyleClass = mapOfWordVsAnalyser.get(key).replace('.', '_');
            }
            else{
                LI.StyleClass = '';
            }
            LIs.add(LI);
        }

        // Return JSON string version of the output collection
        retVal = JSON.serialize(LIs);
        return retVal;
    }
    

    // Remove noise / irrelevant content from materials to be analysed
    private static list<string> RemoveNoiseWords(list<string> strlist){
        
        list<iahelp__NoiseWords__c> noiseList = [select name from iahelp__NoiseWords__c];       
        list<string> avoidList = new list<string>();
        list<string> filteredList = new list<string>();
        
        //Creating list of noise words
        for(iahelp__NoiseWords__c nl : noiseList){          
            avoidList.add(nl.Name);
        }
        
        system.debug('avoidList: '+avoidList); 
        
        for(string str : strlist){
            str = str.replaceAll('^[^a-zA-Z0-9\\s+]+|[^a-zA-Z0-9\\s+]+$','');
            if(!avoidList.contains(str.toLowerCase())){
                filteredList.add(str);
            }
        }
        system.debug('filteredList '+filteredList.size());
        return filteredList;
    }
    
}