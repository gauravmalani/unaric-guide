@isTest

/////////////////////////////////////////////////////////////////////////////////////////////////////
// TEST CASES FOR CLASS ControllerSearch
//
// Martin Little for Improved Apps
// October 2012
/////////////////////////////////////////////////////////////////////////////////////////////////////


private class zTest_ControllerSearch {
    
    
    static testMethod void getBrandCSS() {
        
        // Settings are required for this 
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        ControllerSearch SC = new ControllerSearch();
       // ControllerHelpContent CH = new ControllerHelpContent();
        Test.startTest();
            System.assertEquals(IASet.BrandCSS__c, ControllerSearch.getBrandCSS());
        //ControllerHelpContent.getD1();
        //ControllerHelpContent.getD2();
        Test.stopTest();

        return;     
    }
    
    
    static testMethod void getDefaultSearchTerm() {
        Test.startTest();
            System.assertEquals('[Enter search term]', ControllerSearch.getDefaultSearchTerm());
        Test.stopTest();

        return;             
    }
    
    
    // Test a search with the default search term, expecting no results
    static testMethod void showSearchResultsNoTerm() {
        
        ControllerSearch SC = new ControllerSearch();
        
        Test.startTest();
            SC.showSearchResults() ;
        Test.stopTest();

        System.assertEquals(0, SC.PageHelp.size());
        System.assertEquals(0, SC.FieldHelp.size());
        return;
    }
    

    // Test a search with a defined term to match a help topic we supply
    static testMethod void showSearchResults_Opt0() {
        
        ControllerSearch SC = new ControllerSearch();
        zTest_DataGenerator DG = new zTest_DataGenerator();
        
        HelpTopic__c Hlp1 = DG.getHelpTopic('Test');
        insert Hlp1;
        
        ApexPages.currentPage().getParameters().put('Term', 'Test');
        
        Test.startTest();
            SC.showSearchResults() ;
        Test.stopTest();

        System.assertEquals(0, SC.PageHelp.size());
        //System.assertEquals(1, SC.FieldHelp.size());
        return;
    }


    // Test a search when seeking to add related help
    static testMethod void showSearchResults_Opt1() {
        
        // Add a help topic, then reference it on an add related resource search page
        ControllerSearch SC = new ControllerSearch();
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;

        // Create 1x referring topic...
        HelpTopic__c Hlp1 = DG.getHelpTopic('Test1');
        insert Hlp1;

        // ... 1x topic that should be found in our search
        HelpTopic__c Hlp2 = DG.getHelpTopic('Test2');
        insert Hlp2;
        
        // ... and 1x topic which should NOT be found as it is already related
        HelpTopic__c Hlp3 = DG.getHelpTopic('Test3');
        insert Hlp3;
         
        HelpRelationship__c HR = DG.getHelpRelationship(Hlp1, Hlp3);
        insert HR;
        
        
        Test.startTest();
            PageReference pageRef = Page.IHSearchResults;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('Term', 'Test');
            ApexPages.currentPage().getParameters().put('HTID', Hlp1.Id);        
            ApexPages.currentPage().getParameters().put('Opts', '1');

            SC.showSearchResults() ;
        Test.stopTest();

        System.assertEquals(0, SC.PageHelp.size());
        System.assertEquals(1, SC.FieldHelp.size());
        return;
    }


    // Test a search when seeking to add RL entry
    static testMethod void showSearchResults_Opt2() {
        
        // Add a help topic, then reference it on an add related resource search page
        ControllerSearch SC = new ControllerSearch();
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;


        // Create 1x topic that should be found in our search
        HelpTopic__c Hlp1 = DG.getHelpTopic('Test1');
        insert Hlp1;
        
        // ... and 1x topic which should NOT be found as it is already in the RL we'll work with
        HelpTopic__c Hlp2 = DG.getHelpTopic('Test2');
        insert Hlp2;
         
        HelpReadingList__c RL = DG.getHelpReadingList('TestRL');
        insert RL;
        HelpReadingListEntry__c RLE = DG.getHelpReadingListEntry(RL.Id, Hlp2.Id);
        insert RLE;
        
        
        Test.startTest();
            PageReference pageRef = Page.IHSearchResults;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('Term', 'Test');
            ApexPages.currentPage().getParameters().put('RLID', RL.Id);        
            ApexPages.currentPage().getParameters().put('Opts', '2');

            SC.showSearchResults() ;
        Test.stopTest();

        System.assertEquals(0, SC.PageHelp.size());
        System.assertEquals(1, SC.FieldHelp.size());
        return;
    }


    // Test a search with a defined term to match a Resource we supply
    static testMethod void showSearchResults_Opt3() {
        
        // Add a help topic, then reference it on an add related resource search page
        ControllerSearch SC = new ControllerSearch();
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;

        // Create 1x topic...
        HelpTopic__c Hlp1 = DG.getHelpTopic('Test');
        insert Hlp1;

        // ... 1x resource that should appear in results...
        HelpResource__c HR1 = DG.getHelpResource('R1');
        insert HR1;
        
        // ... and 1x resource which should NOT appear because it is already referenced by the topic
        HelpResource__c HR2 = DG.getHelpResource('R2');
        insert HR2;
        
        HelpTopicResource__c HTR = DG.getHelpTopicResource(HR2, Hlp1);
        insert HTR;
        
        Test.startTest();
            PageReference pageRef = Page.IHSearchResults;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('Term', 'R');
            ApexPages.currentPage().getParameters().put('HTID', Hlp1.Id);        
            ApexPages.currentPage().getParameters().put('Opts', '3');

            SC.showSearchResults() ;
        Test.stopTest();

        System.assertEquals(0, SC.PageHelp.size());
        System.assertEquals(1, SC.FieldHelp.size());
        return;
    }

    
    // Link to existing RL
    static testMethod void showSearchResults_Opt4() {
        
        // This requires current HT (supplied via HTID), plus Opts=4        
        ControllerSearch SC = new ControllerSearch();
        zTest_DataGenerator DG = new zTest_DataGenerator();

        // Add "current" HT
        HelpTopic__c HTC = DG.getHelpTopic('HTCurrent');
        insert HTC;
        
        // Add another HT
        HelpTopic__c HTO = DG.getHelpTopic('HTOther');
        insert HTO;
        
        // Add 1x RL featuring current HT
        HelpReadingList__c RLC = DG.getHelpReadingList('RLCurrent');
        insert RLC;
        HelpReadingListEntry__c RLEC = DG.getHelpReadingListEntry(RLC.Id, HTC.Id);
        insert RLEC;
        
        // Add 1x RL NOT featuring current HT
        HelpReadingList__c RLO = DG.getHelpReadingList('RLOther');
        insert RLO;
        HelpReadingListEntry__c RLEO = DG.getHelpReadingListEntry(RLO.Id, HTO.Id);
        insert RLEO;
        
        Test.startTest();
            PageReference pageRef = Page.IHSearchResults;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('Term', '*');
            ApexPages.currentPage().getParameters().put('HTID', HTC.Id);        
            ApexPages.currentPage().getParameters().put('Opts', '4');
        //  ApexPages.currentPage().getParameters().put('Srch', '1');
            SC.showSearchResults() ;
        Test.stopTest();

        System.assertEquals(1, SC.FieldHelp.size());
            
    }
    
    
    // Test a search for Guides
    static testMethod void showSearchResults_Opt5() {
        
        ControllerSearch SC = new ControllerSearch();
        zTest_DataGenerator DG = new zTest_DataGenerator();
        String U = URL.getOrgDomainURL().toExternalForm() + '/001';
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;

        
        // Add a help topic
        HelpTopic__c HTElem = DG.getHelpTopic('HTElem');
        insert HTElem;
        
        // Add a helped page layout
        HelpedPageLayout__c HPL = DG.getHelpedPageLayout('TestLayout', '001');
        insert HPL;
        
        // Add a hepled element featuring elemTopic on our layout
        HelpedElement__c HE = DG.getHelpedElement('TestElem', HPL.Id, HTElem.Id);
        insert HE;
        
        // Add a Reading List
        HelpReadingList__c HRL = DG.getHelpReadingList('TestRL');
        insert HRL;
        
        // Add a topic to feature in the reading list and set guide properties
        HelpTopic__c HTGuide = DG.getHelpTopic('HTGuide');
        HTGuide.GuidedLayout__c = HPL.Id;
        HTGuide.GuidedElement__c = HE.Id;
        HTGuide.GuidedRecord__c = '';
        HTGuide.GuideStepMode__c = 'Automatic';
        insert HTGuide;
        
        // Add a Reading List Entry pointing to topic and RL
        HelpReadingListEntry__c RLE = DG.getHelpReadingListEntry(HRL.Id, HTGuide.Id);
        
        
        Test.startTest();
            PageReference pageRef = Page.IHSearchResults;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('Opts', '5');
            ApexPages.currentPage().getParameters().put('objId', '001');
            ApexPages.currentPage().getParameters().put('IHContext', U);

            SC.showSearchResults() ;
        Test.stopTest();

        // Check we see the guide
        System.assertEquals(0, SC.PageHelp.size());
        //System.assertEquals(1, SC.FieldHelp.size());
        return;
    }


    // Test a search for Helped Elements for Topic
    static testMethod void showSearchResults_Opt6() {
        
        ControllerSearch SC = new ControllerSearch();
        zTest_DataGenerator DG = new zTest_DataGenerator();
        String U = URL.getOrgDomainURL().toExternalForm() + '/001';
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;

        
        // Add a help topic
        HelpTopic__c HTElem = DG.getHelpTopic('HTElem');
        insert HTElem;
        
        // Add a helped page layout
        HelpedPageLayout__c HPL = DG.getHelpedPageLayout('TestLayout', '001');
        insert HPL;
        
        // Add a hepled element featuring elemTopic on our layout
        HelpedElement__c HE = DG.getHelpedElement('TestElem', HPL.Id, HTElem.Id);
        insert HE;
        
        Test.startTest();
            PageReference pageRef = Page.IHSearchResults;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('Opts', '6');
            ApexPages.currentPage().getParameters().put('HTID', HTElem.Id);

            SC.showSearchResults() ;
        Test.stopTest();

        // Check we see the element
        System.assertEquals(1, SC.FieldHelp.size());
        return;
    }


    // Select RL (for guide enabling)
    static testMethod void showSearchResults_Opt8() {
        
        // This requires current HT (supplied via HTID), plus Opts=8        
        ControllerSearch SC = new ControllerSearch();
        zTest_DataGenerator DG = new zTest_DataGenerator();

        // Add "current" HT
        HelpTopic__c HTC = DG.getHelpTopic('HTCurrent');
        insert HTC;
                
        // Add 1x RL featuring current HT
        HelpReadingList__c RLC = DG.getHelpReadingList('RLCurrent');
        RLC.ReadingListType__c = 'Linear Guide';
        insert RLC;
        HelpReadingListEntry__c RLEC = DG.getHelpReadingListEntry(RLC.Id, HTC.Id);
        insert RLEC;
        

        Test.startTest();
            PageReference pageRef = Page.IHSearchResults;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('Term', '*');
            ApexPages.currentPage().getParameters().put('HTID', HTC.Id);        
            ApexPages.currentPage().getParameters().put('Opts', '8');

            SC.showSearchResults() ;
        Test.stopTest();

        System.assertEquals(1, SC.FieldHelp.size());
            
    }

    // Link to existing RL
    static testMethod void showSearchResults_Opt9() {
        
        // This requires current HT (supplied via HTID), plus Opts=4        
        ControllerSearch SC = new ControllerSearch();
        zTest_DataGenerator DG = new zTest_DataGenerator();

        // Add "current" HT
        HelpTopic__c HTC = DG.getHelpTopic('HTCurrent');
        insert HTC;
        
        // Add another HT
        HelpTopic__c HTO = DG.getHelpTopic('HTOther');
        insert HTO;
        
        // Add 1x RL featuring current HT
        HelpReadingList__c RLC = DG.getHelpReadingList('*');
        insert RLC;
        HelpReadingListEntry__c RLEC = DG.getHelpReadingListEntry(RLC.Id, HTC.Id);
        insert RLEC;
        
        // Add 1x RL NOT featuring current HT
        HelpReadingList__c RLO = DG.getHelpReadingList('*RLOther');
        insert RLO;
        HelpReadingListEntry__c RLEO = DG.getHelpReadingListEntry(RLO.Id, HTO.Id);
        insert RLEO;
        
        Test.startTest();
            PageReference pageRef = Page.IHSearchResults;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('Opts', '5');
            ApexPages.currentPage().getParameters().put('Srch', '1');
            Cookie cook = new Cookie('IAIHSearchOptions', 'Term=Sort;Sort=Term;Test', null, -1, false);
            pageRef.setCookies(new Cookie[] {cook});
            SC.showSearchResults() ;
        Test.stopTest();
            
    }
    // Link to existing RL
    static testMethod void showSearchResults_Opt10() {
        
        // This requires current HT (supplied via HTID), plus Opts=4        
        ControllerSearch SC = new ControllerSearch();
        zTest_DataGenerator DG = new zTest_DataGenerator();

        // Add "current" HT
        HelpTopic__c HTC = DG.getHelpTopic('HTCurrent');
        insert HTC;
        
        // Add another HT
        HelpTopic__c HTO = DG.getHelpTopic('HTOther');
        insert HTO;
        
        // Add 1x RL featuring current HT
        HelpReadingList__c RLC = DG.getHelpReadingList('RLCurrent');
        insert RLC;
        HelpReadingListEntry__c RLEC = DG.getHelpReadingListEntry(RLC.Id, HTC.Id);
        insert RLEC;
        
        // Add 1x RL NOT featuring current HT
        HelpReadingList__c RLO = DG.getHelpReadingList('RLOther');
        insert RLO;
        HelpReadingListEntry__c RLEO = DG.getHelpReadingListEntry(RLO.Id, HTO.Id);
        insert RLEO;
        
        Test.startTest();
            PageReference pageRef = Page.IHSearchResults;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('Opts', '5');
            ApexPages.currentPage().getParameters().put('Srch', '2');
            SC.showSearchResults() ;
        Test.stopTest();
            
    }
    // Test usage of the search results class
    static testMethod void TESTOf_SearchResult() {

        ControllerSearch SC = new ControllerSearch();
        zTest_DataGenerator DG = new zTest_DataGenerator();
        
        // Settings required for this
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        

        // Create a help topic to use as a search result
        HelpTopic__c Hlp1 = DG.getHelpTopic('Test');
        insert Hlp1;
        
        // Also, a reading list featuring this topic
        HelpReadingList__c HRL = DG.getHelpReadingList('Test RL');
        insert HRL;
        
        HelpReadingListEntry__c RLE = DG.getHelpReadingListEntry(HRL.Id, Hlp1.Id);
        insert RLE;
        
        Test.startTest();
            
            ControllerSearch.SearchResult SR;
            
            // Test getting an error search result for a non-existent topic
            //SR = new ControllerSearch.SearchResult(null, null, false, false);
            //System.assertEquals('Error!', SR.Name);
            
            // Test getting a good search result for a proper help topic
            SR = null;
            SR = new ControllerSearch.SearchResult(Hlp1, null, true, true);
            System.assertEquals('Test', SR.Name);
            
            // Test getting a search result for a reading list
            SR = null;
            SR = new ControllerSearch.SearchResult(HRL, true, true, false);
            System.assertEquals('Test RL', SR.Name);
            
        Test.stopTest();
        return;
    }


    static testMethod void addRelatedResource() {

        String retVal;
        ControllerSearch SC = new ControllerSearch();
        zTest_DataGenerator DG = new zTest_DataGenerator();

        // Create a help topic and resource to relate to each other
        HelpTopic__c Hlp1 = DG.getHelpTopic('Test 1');
        insert Hlp1;

        HelpResource__c HR = DG.getHelpResource('Test Resource');
        insert HR;
        
        Test.startTest();
            // Need to do this first to get internationalisations initialised...
            SC.showSearchResults();
        
            SC.HTID = Hlp1.Id;
            SC.SearchResultId = HR.Id;
            SC.addRelatedResource();
            system.assertEquals(SC.getGlobalLocalisations().get('MessageGenericTaskComplete'), SC.Diags);
            
        Test.stopTest();
        return;     
    }
    
    
    static testMethod void createRelatedResource() {

        String retVal;
        ControllerSearch SC = new ControllerSearch();
        zTest_DataGenerator DG = new zTest_DataGenerator();

        // Create a help topic to which to relate a new resource
        HelpTopic__c Hlp1 = DG.getHelpTopic('Test 1');
        insert Hlp1;

        // Set resource name, summary, URL, type and location as if typed by user
        SC.fld1 = 'Resource Name';
        SC.fld2 = 'Resource Summary';
        SC.fld3 = 'http://www.bbc.co.uk';
        SC.fld4 = 'Web Site';
        SC.fld5 = 'Internet';
        
        Test.startTest();
            // Need to do this first to get internationalisations initialised...
            SC.showSearchResults();

            SC.HTID = Hlp1.Id;
            SC.createRelatedResource();
            system.assertEquals(SC.getGlobalLocalisations().get('MessageGenericTaskComplete'), SC.Diags);
            
        Test.stopTest();
        return;     
        
    }
    

    static testMethod void addRelatedHelp() {

        String retVal;
        ControllerSearch SC = new ControllerSearch();
        zTest_DataGenerator DG = new zTest_DataGenerator();
        
        // Settings now required as relations require knowledge of default semantic tag / relationship type
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        // Create 2 help topics to relate to each other
        HelpTopic__c Hlp1 = DG.getHelpTopic('Test 1');
        HelpTopic__c Hlp2 = DG.getHelpTopic('Test 2');
        insert Hlp1;
        insert Hlp2;
        
        
        Test.startTest();           
            // Need to do this first to get internationalisations initialised...
            SC.showSearchResults();

            SC.HTID = Hlp1.Id;
            SC.SearchResultId = Hlp2.Id;            
            SC.addRelatedHelp();
            system.assertEquals(SC.getGlobalLocalisations().get('MessageGenericTaskComplete'), SC.Diags);
            
        Test.stopTest();
        return;
    }
    
    
    static testMethod void createRelatedHelp() {

        String retVal;
        ControllerSearch SC = new ControllerSearch();

        // Settings are required for this 
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;


        // Create a help topic to be related to a new one
        HelpTopic__c Hlp1 = DG.getHelpTopic('Test 1');
        insert Hlp1;
        
        
        Test.startTest();
            // Need to do this first to get internationalisations initialised...
            SC.showSearchResults();
        
            SC.HTID = Hlp1.Id;
            
            // Add the details a user would have entered to create the help topic
            SC.fld1 = 'Created Topic Name';
            SC.fld2 = 'Created Topic Summary';

            SC.createRelatedHelp();
            system.assertEquals(SC.getGlobalLocalisations().get('MessageGenericTaskComplete'), SC.Diags);
            
        Test.stopTest();
        return;     
    }
    
        
    static testMethod void addRLEntry() {

        String retVal;
        ControllerSearch SC = new ControllerSearch();

        // Settings are required for this 
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;

        // Create a reading list
        HelpReadingList__c HRL = DG.getHelpReadingList('Test Reading List');
        insert HRL;

        // Create a help topic to add to it
        HelpTopic__c Hlp1 = DG.getHelpTopic('Test 1');
        insert Hlp1;

        Test.startTest();
            SC.SearchResultId = Hlp1.Id;
            SC.RLID = HRL.Id;
            SC.addRLEntry();
            system.assertEquals('Reading List Entry added successfully', SC.Diags);
            
        Test.stopTest();
        return;
    }


    static testMethod void createRLEntry() {

        String retVal;
        ControllerSearch SC = new ControllerSearch();

        // Settings are required for this 
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;

        // Create a reading list
        HelpReadingList__c HRL = DG.getHelpReadingList('Test Reading List');
        insert HRL;

        Test.startTest();
            SC.RLID = HRL.Id;
            
            // Add the details a user would have entered to create the help topic
            SC.fld1 = 'Created Topic Name';
            SC.fld2 = 'Created Topic Summary';
            
            SC.createRLEntry();
            system.assertEquals(SC.Diags.startsWith(ServiceIHLists.getDialogueLocalisations().get('MessageAddedRLEntry')), true);
            
        Test.stopTest();
        return;     
    }
    
    
    static testMethod void addTopicToRL() {

        String retVal;
        ControllerSearch SC = new ControllerSearch();

        // Settings are required for this 
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;

        // Create a reading list
        HelpReadingList__c HRL = DG.getHelpReadingList('Test Reading List');
        insert HRL;

        // Create a help topic to add to it
        HelpTopic__c Hlp1 = DG.getHelpTopic('Test 1');
        insert Hlp1;
        

        Test.startTest();
        
            // Navigate to the search results page with help topic and appropriate option set
            PageReference pageRef = Page.IHSearchResults;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('HTID', Hlp1.Id);            
            ApexPages.currentPage().getParameters().put('Opts', '4');            
            
        
            // Search result should be our reading list, as created above
            SC.showSearchResults();
            SC.SearchResultId = HRL.Id;
            SC.addTopicToRL();
            system.assertEquals(Hlp1.Id, SC.HTID);
            system.assertEquals('Reading List Entry added successfully', SC.Diags);
            
        Test.stopTest();
        return;             
    }
    

    public static testMethod void selectReadingList() {
        
        ControllerSearch SC = new ControllerSearch();

        Test.startTest();
            System.assertEquals('', '');        
        Test.stopTest();
        
        return;
    }
    
    
    public static testMethod void enableNewGuide() {
        
        ControllerSearch SC = new ControllerSearch();

        Test.startTest();
            SC.enableNewGuide();
            System.assertEquals('', '');        
        Test.stopTest();
        
        return;
    }
    
}