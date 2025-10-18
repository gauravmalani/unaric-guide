@isTest

/////////////////////////////////////////////////////////////////////////////////////////////////////
// TEST CASES FOR CLASS zTest_ServiceIntelligence
//
// Prashant Kumar for Improved Apps
// October 2022
/////////////////////////////////////////////////////////////////////////////////////////////////////


private class zTest_ServiceIntelligence {    
    
    //Test Synchronous Analyser method
    static testMethod void testSynchAnalyser(){
        zTest_DataGenerator test = new zTest_DataGenerator();
        iahelp__NoiseWords__c nw = test.getNoiseWords('a');
        insert nw;
        String inputText = 'Salesforce, Inc. is an American cloud-based software company headquartered in San Francisco, California.'+ 
                            'It provides customer relationship management (CRM) software and applications focused on sales, customer service, marketing automation, analytics, and application development.'+
                            'Founded by former Oracle executive Marc Benioff, Salesforce quickly grew into one of the largest companies in the world, making its IPO in 2004. Salesforce continued growth makes it into the first cloud computing company to reach US$1 billion in annual revenue by fiscal year 2009,[2] and the worlds largest enterprise software firm by 2022.[3]'+
                            'Today, Salesforce is one of the largest technology companies in the world, and as of September 19, 2022, is the 61st largest company in the world by market cap with a value of nearly US$153 billion.[4] Salesforce ranked 136th on the most recent edition of the Fortune 500, making US$26.5 billion in 2022.[5] Since 2020, Salesforce has also been a component of the Dow Jones Industrial Average.';
        integer qualityThreshold = 2;
        integer maxPhraseLength = 2;
        string desiredAnalyser = 'ServiceIntelligence.analyseWordCount,ServiceIntelligence.analyseCapitals,ServiceIntelligence.analyseMultiWordPhrases,ServiceIntelligence.findExisitingKeywords';
        ServiceIntelligence.analyseHelper(inputText, qualityThreshold, maxPhraseLength, desiredAnalyser);
    }
}