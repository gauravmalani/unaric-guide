@isTest

/////////////////////////////////////////////////////////////////////////////////////////////////////
// TEST CASES FOR THE BOOKMARK INSERT TRIGGER (trgInsertHelpBookmark)
//
// Martin Little for Improved Apps
// September 2013
/////////////////////////////////////////////////////////////////////////////////////////////////////


private class zTest_trgInsertHelpBookmark {

    
    static testMethod void BeforeUpsert() {
    
        zTest_DataGenerator DG = new zTest_DataGenerator();
    
        Test.startTest();
            // Creation of 2x identical bookmarks should fire all lines of code
            HelpTopic__c HT = DG.getHelpTopic('TestTopic');
            insert HT;
            
            HelpBookmark__c B1 = DG.getHelpBookmark(HT.Id);
            insert B1;
            
            HelpBookmark__c B2 = DG.getHelpBookmark(HT.Id);
            try {
                insert B2;          
            } catch (exception e) {
                system.assert(e.getMessage().indexOf('You have already bookmarked this Help Topic') != -1);
            }
             
        Test.stopTest();
        
        return;
    }
}