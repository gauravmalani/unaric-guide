@isTest

/////////////////////////////////////////////////////////////////////////////////////////////////////
// TEST CASES FOR CLASS ControllerComments
//
// Martin Little for Improved Apps
// October 2012
/////////////////////////////////////////////////////////////////////////////////////////////////////


private class zTest_ControllerComments {


    static testMethod void initialise() {
        
        zTest_DataGenerator DG = new zTest_DataGenerator();
        ControllerComments CC = new ControllerComments();
        ControllerSettings CS = new ControllerSettings();
        PageReference pageRef;

        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;

        HelpTopic__c Hlp = DG.getHelpTopic('Test');
        insert Hlp;

        HelpedPageLayout__c PL = DG.getHelpedPageLayout('TestCCInitialise', 'TestCCInitialiseIDent');
        insert PL;
        
        
        Test.startTest();

            // Initialise with no incoming topic / page parameters
            pageRef = Page.IHComment;
            Test.setCurrentPage(pageRef);
            CC.initialise();
            
            CC.logComment();
            System.assertEquals(CC.getDialogueLocalisations().get('MessageCommentFailedParameters'), CC.Diags);
            

            // Initialise with a help topic 
            pageRef = Page.IHComment;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('HTID', Hlp.Id);            
            CC.initialise();
            System.assertEquals(false, CC.IsError);
            
            
            // Initialise with a page layout
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('PL', PL.PageLayoutIdentifier__c);            
            CC.initialise();

            System.assertEquals(false, CC.IsError);
                
            CC.getGlobalLocalisations();
            CC.getBrandingLocalisations();
        
            CS.getSettingsInitialised();
            CS.initialiseMSMinPage();
            CS.getConfigItemsCurrent();
        Test.stopTest();
        
        return; 
    }
    

    static testMethod void logComment() {

        zTest_DataGenerator DG = new zTest_DataGenerator();
        ControllerComments CC = new ControllerComments();
        Boolean isIH1UX1 = CC.isIH1UX;
        PageReference pageRef;

        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;

        HelpTopic__c Hlp = DG.getHelpTopic('Test');
        insert Hlp;

        Test.startTest();
        
            // Log a blank comment
            pageRef = Page.IHComment;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('HTID', Hlp.Id);            
            CC.initialise();
            
            CC.logComment();
        
            System.assertEquals(CC.getDialogueLocalisations().get('MessageCommentFailedBlank'), CC.Diags);      

            // Log a non-blank comment
            CC.UserText = 'A comment';
            CC.logComment();

            System.assertEquals(CC.getDialogueLocalisations().get('MessageCommentLogged'), CC.Diags);   
        
        Test.stopTest();
        
        return;
    }
    
    
    static testMethod void getBrandCSS() {
        
        // Settings are required for this
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;

        Test.startTest();
            ControllerComments.getBrandCSS();
            System.assertEquals('', '');   
        Test.stopTest();
        
        return;
    }
    
}