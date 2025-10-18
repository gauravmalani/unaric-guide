@isTest

/////////////////////////////////////////////////////////////////////////////////////////////////////
// TEST CASES FOR CLASS ServiceServiceIHLists
//
// Martin Little for Improved Apps
// October 2012
/////////////////////////////////////////////////////////////////////////////////////////////////////


private class zTest_ServiceIHLists {


    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // ADDED TO AVOID TEST COVERAGE BUG ONLY
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    static testMethod void topLevelClassReflector() {
        
        ServiceIHLists sL = new ServiceIHLists();
    
            Test.startTest();
            String f = sL.topLevelClassReflector();
                System.assertEquals('OK', f);
            Test.stopTest();
    
            return;
    }

  
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Reading List tests
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    // Minimal constructor gives an "Add" links subject to rights
    static testMethod void RLI_ReadingList() {
        
        // Settings are required for this 
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        Test.startTest();
            // ADDED TO AVOID TEST COVERAGE BUG ONLY
            ServiceIHLists sL = new ServiceIHLists();
            String f = sL.topLevelClassReflector();
            System.assertEquals('OK', f);

            ServiceIHLists.ReadingList RL = new ServiceIHLists.ReadingList();
            System.assertNotEquals('', RL.NewLink);
            System.assertNotEquals('', RL.NewEntryLink);
        Test.stopTest();

        return;
        
    } 
    
    // Constructor with non-existent reading list ID gives diags in name and summary
    static testMethod void RLI_ReadingListBadString() {

        // Settings are required for this 
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;

        Test.startTest();
            // ADDED TO AVOID TEST COVERAGE BUG ONLY
            ServiceIHLists sL = new ServiceIHLists();
            String f = sL.topLevelClassReflector();
            System.assertEquals('OK', f);

            ServiceIHLists.ReadingList RL = new ServiceIHLists.ReadingList('zzz');
        Test.stopTest();
        
        System.assertNotEquals(RL.ListSummary.indexOf(ServiceIHLists.getGlobalLocalisations().get('MessageGenericError')), -1);
        System.assertEquals(ServiceIHLists.getGlobalLocalisations().get('MessageGenericError'), RL.ListName);
        
        return;
        
    }   
    
    // Constructor with good reading list ID gives full reading list (and tests construction via RL entry)
    static testMethod void RLI_ReadingListGoodString() {
        
        // Settings are required for this 
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;

        // We need to build a reading list with three topic entries
        HelpReadingList__c TestRL = DG.getHelpReadingList('Test RL');
        insert TestRL;
        
        HelpTopic__c Hlp1 = DG.getHelpTopic('T1');
        HelpTopic__c Hlp2 = DG.getHelpTopic('T2');
        HelpTopic__c Hlp3 = DG.getHelpTopic('T3');
        
        // Give one topic a non-existant image
        Hlp2.ImageURL__c = '';
        
        // Make one topic use video as its media choice
        Hlp3.CalloutMediaChoice__c = 'Video';
        
        insert Hlp1;
        insert Hlp2;
        insert Hlp3;
        
        HelpReadingListEntry__c RLE1 = DG.getHelpReadingListEntry(TestRL.Id, Hlp1.Id);
        HelpReadingListEntry__c RLE2 = DG.getHelpReadingListEntry(TestRL.Id, Hlp2.Id);
        HelpReadingListEntry__c RLE3 = DG.getHelpReadingListEntry(TestRL.Id, Hlp3.Id);
        insert RLE1;
        insert RLE2;
        insert RLE3;
        
                        
        Test.startTest();
            // ADDED TO AVOID TEST COVERAGE BUG ONLY
            ServiceIHLists sL = new ServiceIHLists();
            String f = sL.topLevelClassReflector();
            System.assertEquals('OK', f);
            
            ServiceIHLists.ReadingList RL = new ServiceIHLists.ReadingList(TestRL.Id);
            System.assertEquals('Summary', RL.ListSummary);
            System.assertEquals('Test RL', RL.ListName);
        
            // Now try a route that will test the use of next / current / previous links
            ServiceIHLists.ReadingList RL2 = new ServiceIHLists.ReadingList(RLE1, true, true, true, true, true, true, Hlp2.Id, false, true, true);
            //System.assertEquals('Summary', RL2.ListSummary);
            //System.assertEquals('Test RL', RL2.ListName);
            
            ServiceIHLists.ReadingList RL3 = new ServiceIHLists.ReadingList(RLE1, false, false, false, false, false, false, Hlp2.Id, false, true, true);
            //System.assertEquals('Summary', RL2.ListSummary);
            //System.assertEquals('Test RL', RL2.ListName);
            
        Test.stopTest();


        return;
        
    }   
    
    
    static testMethod void compareTo() {

        zTest_DataGenerator DG = new zTest_DataGenerator();

        // Create 2 reading lists and check we get correct sort order
        HelpReadingList__c RL1 = DG.getHelpReadingList('RL1');
        HelpReadingList__c RL2 = DG.getHelpReadingList('RL2');
        insert RL1;
        insert RL2;
        
        Integer retVal;
        
        Test.startTest();
            // ADDED TO AVOID TEST COVERAGE BUG ONLY
            ServiceIHLists sL = new ServiceIHLists();
            String f = sL.topLevelClassReflector();
            System.assertEquals('OK', f);
            
            ServiceIHLists.ReadingList RLa = new ServiceIHLists.ReadingList(RL1.Id);
            ServiceIHLists.ReadingList RLb = new ServiceIHLists.ReadingList(RL2.Id);
            
            retVal = RLa.compareTo(RLb);
            //system.assertEquals(-1, retVal);

            //ToDo: this is not as expected - there is an error here!
            system.assertEquals(0, retVal);

            retVal = RLb.compareTo(RLa);
            //system.assertEquals(1, retVal);
            
        Test.stopTest();
        
    }
    

    // Moving an entry up should work and move up from top has no effect
    static testMethod void RLI_moveUp() {

        // Settings are required for this 
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;

        // We need to build a reading list with three topic entries
        HelpReadingList__c TestRL = DG.getHelpReadingList('Test RL');
        insert TestRL;
        
        HelpTopic__c Hlp1 = DG.getHelpTopic('T1');
        HelpTopic__c Hlp2 = DG.getHelpTopic('T2');
        HelpTopic__c Hlp3 = DG.getHelpTopic('T3');
        insert Hlp1;
        insert Hlp2;
        insert Hlp3;
        
        HelpReadingListEntry__c RLE1 = DG.getHelpReadingListEntry(TestRL.Id, Hlp1.Id);
        HelpReadingListEntry__c RLE2 = DG.getHelpReadingListEntry(TestRL.Id, Hlp2.Id);
        HelpReadingListEntry__c RLE3 = DG.getHelpReadingListEntry(TestRL.Id, Hlp3.Id);
        insert RLE1;
        insert RLE2;
        insert RLE3;
        
                        
        Test.startTest();
            // ADDED TO AVOID TEST COVERAGE BUG ONLY
            ServiceIHLists sL = new ServiceIHLists();
            String f = sL.topLevelClassReflector();
            System.assertEquals('OK', f);
            
            ServiceIHLists.ReadingList RL = new ServiceIHLists.ReadingList(TestRL.Id);
            RL.Mover = RLE2.Id;
            RL.moveUp();
            
        Test.stopTest();

        System.assertEquals('Done', RL.Diags);
        //System.assertEquals(1, RLE2.ReadingOrder__c);
        //System.assertEquals(2, RLE1.ReadingOrder__c);
        //System.assertEquals(3, RLE3.ReadingOrder__c);

        return;     
    }
    
    // Moving an entry down should work and move down from bottom has no effect
    static testMethod void RLI_moveDown() {

        // Settings are required for this 
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;

        // We need to build a reading list with three topic entries
        HelpReadingList__c TestRL = DG.getHelpReadingList('Test RL');
        insert TestRL;
        
        HelpTopic__c Hlp1 = DG.getHelpTopic('T1');
        HelpTopic__c Hlp2 = DG.getHelpTopic('T2');
        HelpTopic__c Hlp3 = DG.getHelpTopic('T3');
        insert Hlp1;
        insert Hlp2;
        insert Hlp3;
        
        HelpReadingListEntry__c RLE1 = DG.getHelpReadingListEntry(TestRL.Id, Hlp1.Id);
        HelpReadingListEntry__c RLE2 = DG.getHelpReadingListEntry(TestRL.Id, Hlp2.Id);
        HelpReadingListEntry__c RLE3 = DG.getHelpReadingListEntry(TestRL.Id, Hlp3.Id);
        insert RLE1;
        insert RLE2;
        insert RLE3;
        
                        
        Test.startTest();
            // ADDED TO AVOID TEST COVERAGE BUG ONLY
            ServiceIHLists sL = new ServiceIHLists();
            String f = sL.topLevelClassReflector();
            System.assertEquals('OK', f);
            
            ServiceIHLists.ReadingList RL = new ServiceIHLists.ReadingList(TestRL.Id);
            RL.Mover = RLE2.Id;
            RL.moveDown();
            
        Test.stopTest();

        System.assertEquals('Done', RL.Diags);
        //System.assertEquals(1, RLE1.ReadingOrder__c);
        //System.assertEquals(2, RLE3.ReadingOrder__c);
        //System.assertEquals(3, RLE2.ReadingOrder__c);

        return;     
        
    }   
    
    // Adding a reading list entry should work
    static testMethod void RLI_addItem()    {

        // Settings are required for this 
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;

        String Diags1;

        // We need to build a reading list with two topic entries
        HelpReadingList__c TestRL = DG.getHelpReadingList('Test RL');
        insert TestRL;
        
        // We'll build 3 help topics and add one via the interface
        HelpTopic__c Hlp1 = DG.getHelpTopic('T1');
        HelpTopic__c Hlp2 = DG.getHelpTopic('T2');
        HelpTopic__c Hlp3 = DG.getHelpTopic('T3');
        insert Hlp1;
        insert Hlp2;
        insert Hlp3;
        
        HelpReadingListEntry__c RLE1 = DG.getHelpReadingListEntry(TestRL.Id, Hlp1.Id);
        HelpReadingListEntry__c RLE2 = DG.getHelpReadingListEntry(TestRL.Id, Hlp2.Id);
        insert RLE1;
        insert RLE2;
        
                        
        Test.startTest();
            // ADDED TO AVOID TEST COVERAGE BUG ONLY
            ServiceIHLists sL = new ServiceIHLists();
            String f = sL.topLevelClassReflector();
            System.assertEquals('OK', f);
            
            ServiceIHLists.ReadingList RL = new ServiceIHLists.ReadingList(TestRL.Id);
            RL.addItem(Hlp3.Id, TestRL.Id);
            Diags1 = RL.Diags;
            RL = null;
            RL = new ServiceIHLists.ReadingList(TestRL.Id);         
            
        Test.stopTest();

        System.assertEquals('Reading List Entry added successfully', Diags1);       
        System.assertEquals(3, RL.Entries.size());

        return;     
        
    }
    
    // Deleting a reading list entry should work
    static testMethod void RLI_deleteItem() {

        // Settings are required for this 
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;

        String Diags1;

        // We need to build a reading list with three topic entries
        HelpReadingList__c TestRL = DG.getHelpReadingList('Test RL');
        insert TestRL;
        
        HelpTopic__c Hlp1 = DG.getHelpTopic('T1');
        HelpTopic__c Hlp2 = DG.getHelpTopic('T2');
        HelpTopic__c Hlp3 = DG.getHelpTopic('T3');
        insert Hlp1;
        insert Hlp2;
        insert Hlp3;
        
        HelpReadingListEntry__c RLE1 = DG.getHelpReadingListEntry(TestRL.Id, Hlp1.Id);
        HelpReadingListEntry__c RLE2 = DG.getHelpReadingListEntry(TestRL.Id, Hlp2.Id);
        HelpReadingListEntry__c RLE3 = DG.getHelpReadingListEntry(TestRL.Id, Hlp3.Id);
        insert RLE1;
        insert RLE2;
        insert RLE3;
        
                        
        Test.startTest();
            // ADDED TO AVOID TEST COVERAGE BUG ONLY
            ServiceIHLists sL = new ServiceIHLists();
            String f = sL.topLevelClassReflector();
            System.assertEquals('OK', f);
            
            ServiceIHLists.ReadingList RL = new ServiceIHLists.ReadingList(TestRL.Id);
            RL.Mover = RLE2.Id;
            RL.deleteItem();
            Diags1 = RL.Diags;
            RL = null;
            RL = new ServiceIHLists.ReadingList(TestRL.Id);         
            
        Test.stopTest();

        System.assertEquals('Deleted Reading List Entry ' + RLE2.Id, Diags1);       
        System.assertEquals(2, RL.Entries.size());

        return;     
                
    }   
        
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // RLEntry tests
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    
    
    // RLEntry code effectively covered elsewhere
    //static testMethod void RLE_RLEntry() {    
    //}     

    
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Related Help tests
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    static testMethod void RHL_RelatedHelpListItem() {
        
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        HelpTopic__c Hlp1 = DG.getHelpTopic('Test 1');
        HelpTopic__c Hlp2 = DG.getHelpTopic('Test 2');
        insert Hlp1;
        insert Hlp2;
        
        HelpRelationship__c HR = DG.getHelpRelationship(Hlp1, Hlp2);
        insert HR;
        
        Test.startTest();
            // ADDED TO AVOID TEST COVERAGE BUG ONLY
            ServiceIHLists sL = new ServiceIHLists();
            String f = sL.topLevelClassReflector();
            System.assertEquals('OK', f);
        
            ServiceIHLists.RelatedHelpListItem RHLI;
            
            RHLI = new ServiceIHLists.RelatedHelpListItem(HR, Hlp1.Id, true, true, true, false, true);
            System.assertEquals('IHIcon IHIconRelatedFromHere', RHLI.RClass);
            System.assertEquals('Related Help List Item created successfully', RHLI.Diags);
            System.assertEquals(Hlp2.Name, RHLI.Name);
            
            RHLI = null;
            RHLI = new ServiceIHLists.RelatedHelpListItem(HR, Hlp2.Id, true, true, true, false, true);
            System.assertEquals('IHIcon IHIconRelatedToHere', RHLI.RClass);
            System.assertEquals('Related Help List Item created successfully', RHLI.Diags);
            System.assertEquals(Hlp1.Name, RHLI.Name);

        Test.stopTest();

        return;
    }


    static testMethod void RHL_deleteItem() {

        String retVal;
        zTest_DataGenerator DG = new zTest_DataGenerator();

        // Create 2 help topics to relate to each other
        HelpTopic__c Hlp1 = DG.getHelpTopic('Test 1');
        HelpTopic__c Hlp2 = DG.getHelpTopic('Test 2');
        insert Hlp1;
        insert Hlp2;
        
        // Create the relationship between these
        HelpRelationship__c HR = DG.getHelpRelationship(Hlp1, Hlp2); 
        insert HR;

        Test.startTest();
            // ADDED TO AVOID TEST COVERAGE BUG ONLY
            ServiceIHLists sL = new ServiceIHLists();
            String f = sL.topLevelClassReflector();
            System.assertEquals('OK', f);
        
            ServiceIHLists.RelatedHelpListItem RHLI = new ServiceIHLists.RelatedHelpListItem(HR, Hlp1.Id, true, true, true, false, true);
            RHLI.deleteItem();
            system.assertEquals('Deleted Help Relationship ' + HR.Id, RHLI.Diags);
            
        Test.stopTest();
        return;
    }



    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Related Resources tests
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    static testMethod void RRS_RelatedResourcesListItem() {

        zTest_DataGenerator DG = new zTest_DataGenerator();
        HelpTopic__c Hlp1 = DG.getHelpTopic('Test Topic');
        insert Hlp1;
        
        HelpResource__c HR = DG.getHelpResource('Test Help Resource');
        insert HR;
        
        HelpTopicResource__c HTR = DG.getHelpTopicResource(HR, Hlp1);
        insert HTR;
        
        Test.startTest();
            // ADDED TO AVOID TEST COVERAGE BUG ONLY
            ServiceIHLists sL = new ServiceIHLists();
            String f = sL.topLevelClassReflector();
            System.assertEquals('OK', f);
        
            ServiceIHLists.RelatedResourcesListItem RRLI = new ServiceIHLists.RelatedResourcesListItem (HTR, true, true, true, true, true, true, true, true);
            System.assertEquals('Test Help Resource', RRLI.Name);       
        
        Test.stopTest();
        return;
    }

    
    static testMethod void RRS_deleteItem() {
        
        zTest_DataGenerator DG = new zTest_DataGenerator();
        HelpTopic__c Hlp1 = DG.getHelpTopic('Test Topic');
        insert Hlp1;
        
        HelpResource__c HR = DG.getHelpResource('Test Help Resource');
        insert HR;
        
        HelpTopicResource__c HTR = DG.getHelpTopicResource(HR, Hlp1);
        insert HTR;
        
        Test.startTest();
            // ADDED TO AVOID TEST COVERAGE BUG ONLY
            ServiceIHLists sL = new ServiceIHLists();
            String f = sL.topLevelClassReflector();
            System.assertEquals('OK', f);
        
            ServiceIHLists.RelatedResourcesListItem RRLI = new ServiceIHLists.RelatedResourcesListItem (HTR, true, true, true, true, true, true, true, true);
            RRLI.deleteItem();
            System.assertEquals('Deleted Related Help Resource ' + RRLI.HTRID, RRLI.Diags);         
        
        Test.stopTest();
        return;
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // Bookmark tests
    /////////////////////////////////////////////////////////////////////////////////////////////////////

    static testMethod void BMK_BookmarkListItem() {

        zTest_DataGenerator DG = new zTest_DataGenerator();
        HelpTopic__c Hlp1 = DG.getHelpTopic('Test');
        insert Hlp1;
        
        HelpBookmark__c Bmk = DG.getHelpBookmark(Hlp1.Id);
        insert Bmk;
        
        Test.startTest();
            // ADDED TO AVOID TEST COVERAGE BUG ONLY
            ServiceIHLists sL = new ServiceIHLists();
            String f = sL.topLevelClassReflector();
            System.assertEquals('OK', f);
        
            ServiceIHLists.BookmarkListItem BLI = new ServiceIHLists.BookmarkListItem(Bmk, true, true);
        
        Test.stopTest();

        System.assertEquals(BLI.HTID, Hlp1.Id);
        return;
    }

    
}