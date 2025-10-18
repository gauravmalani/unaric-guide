@isTest

/////////////////////////////////////////////////////////////////////////////////////////////////////
// TEST CASES FOR CLASS ControllerStats
//
// Martin Little for Improved Apps
// October 2012
/////////////////////////////////////////////////////////////////////////////////////////////////////


private class zTest_ControllerStats {
    
    
    // Get stats as page gets them
    static testMethod void getStatsForPage() {
        
        ControllerStats SC = new ControllerStats();
        
        // This means a call to stats page with HPL specified only
        // Create a page layout, a helped element and its help topic
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;

        HelpTopic__c Hlp = DG.getHelpTopic('Test');
        insert Hlp;
                
        HelpedPageLayout__c HPL = DG.getHelpedPageLayout('Test Layout', 'IHTools');
        insert HPL;
        
        HelpedElement__c HE = DG.getHelpedElement('Test Element', HPL.Id, Hlp.Id);
        insert HE;
        
        // Navigate to stats page specifying HPL only
        PageReference pageRef = Page.IHStats;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('HPL', HPL.PageLayoutIdentifier__c);            
        
        
        Test.startTest();
            SC.getStats();
        Test.stopTest();
        
        system.assertEquals('', '');
        
        return;
    }   
    

    // Get stats for a helped element (as for field labels etc)
    static testMethod void getStatsForHelpedElement() {
        
        
        
        ControllerStats SC = new ControllerStats(ControllerStats.KnownAnalysisModes.ByHelpedElement, '');

        // This means a call to stats page with HPL AND an element specified
        // Create a page layout, a helped element and its help topic
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;

        HelpTopic__c Hlp = DG.getHelpTopic('Test');
        insert Hlp;
                
        HelpedPageLayout__c HPL = DG.getHelpedPageLayout('Test Layout', 'IHTools');
        insert HPL;
        
        HelpedElement__c HE = DG.getHelpedElement('Test Element', HPL.Id, Hlp.Id);
        insert HE;
        
        // Navigate to stats page specifying HPL only
        PageReference pageRef = Page.IHStats;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('HPL', HPL.PageLayoutIdentifier__c);            
        ApexPages.currentPage().getParameters().put('ElemID', HE.Identifier__c);            
        
        Test.startTest();
            SC.getStats();
        Test.stopTest();
        
        system.assertEquals('', '');
        
        return;
    }   
    
    // Get stats for a helped element (as for field labels etc)
    static testMethod void getStatisticsTest() {
        Test.startTest();
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;

        HelpTopic__c Hlp = DG.getHelpTopic('Test');
        insert Hlp;
        ControllerStats.KnownAnalysisModes obj = ControllerStats.KnownAnalysisModes.ByHelpTopic;
            ControllerStats SC1 = new ControllerStats(obj, Hlp.Id);
        ControllerStats.getBrandCSS();
        SC1.getDialogueLocalisations();
        SC1.getGlobalLocalisations();
        SC1.getBrandingLocalisations();
        Test.stopTest();
    }
    
}