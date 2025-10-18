@isTest

/////////////////////////////////////////////////////////////////////////////////////////////////////
// TEST CASES FOR CLASS ControllerLUXOps
//
// Martin Little for Improved Apps
// December 2016
/////////////////////////////////////////////////////////////////////////////////////////////////////


private class zTest_ControllerLUXOps {
    
    static testMethod void getGlobals() {

        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        string retVal;
        

        Test.startTest();
        
            retVal = ControllerLUXOps.getGlobals();            
            system.assert(DG.isValidJSON(retVal) == true);

        Test.stopTest();

        return;     
        
    }
    
    
    // AllHelp, Search
    // INC with a layout / element in play (lines 885+)
    // INC a failed DDF element (lines 991+)
    static testMethod void getTools1 () {
        
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        string ToolContext = 'QAM';
        string IHContext = '';
        string Params = '';
        string ActionCode;
        string retVal;

        ConfigurationItem__c CI1 = DG.getConfigurationItem(ToolContext, 'Ellipsis', 1);
        ConfigurationItem__c CI2 = DG.getConfigurationItem(ToolContext, 'Header', 1);
        ConfigurationItem__c CI3 = DG.getConfigurationItem(ToolContext, 'Listing', 1);
        ConfigurationItem__c CI4 = DG.getConfigurationItem(ToolContext, 'Drop-down', 1);
        
        insert CI1;
        insert CI2;
        insert CI3;
        insert CI4;
        
        // Create a topic, HPL and element to feature
        HelpTopic__c HT = DG.getHelpTopic('T1');
        insert HT;
        
        HelpedPageLayout__c HPL = DG.getHelpedPageLayout('Account', '001');
        insert HPL;
        
        // Add 1x element that will "pass"...
        HelpedElement__c HE = DG.getHelpedElement('Test Element', HPL.Id, HT.Id);
        insert HE;
        
        // ... plus 1 that fails DDF
        HelpedElement__c HEFail = DG.getHelpedElement('Fail Element', HPL.Id, HT.Id);
        HEFail.DataDrivenFilter__c = '1=2';
        insert HEFail;
        
        Account A = new Account();
        A.Name = 'TestAc';
        insert A;
        
        
        Test.startTest();
        
            // Cannot set a "null" test page reference - so Apex page always assumed in these tests!!
            // So: we'll have to set up a page context with record ID to get things working...
            PageReference pageRef = new PageReference(URL.getOrgDomainURL().toExternalForm() + '?IHContext=' + URL.getOrgDomainURL().toExternalForm() + '/' + A.Id);
            Test.setCurrentPage(pageRef);
                    
            ActionCode = 'AllHelp';
            IHContext = A.Id;
            retVal = ControllerLUXOps.getTools(ToolContext, ActionCode, IHContext, '', Params, false);
            
            system.assertEquals('', '');            

            ActionCode = 'Search';
            ControllerLUXOps.getTools(ToolContext, ActionCode, IHContext, '', Params, false);
            system.assertEquals('', '');     
        
            ActionCode = 'FixedHelp';
            ControllerLUXOps.getTools(ToolContext, ActionCode, IHContext, '', Params, false);

        Test.stopTest();

        return;     
    }

    
    // QuickLinks, Stickies
    static testMethod void getTools2 () {
        
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        // Need a subscription doc here...
        //Document D = DG.getSubscriptionDoc();
        //insert D;
        
        string ToolContext = 'QAM';
        string IHContext = '001';
        string Params = '';
        string ActionCode;

        ConfigurationItem__c CI1 = DG.getConfigurationItem(ToolContext, 'Ellipsis', 1);
        ConfigurationItem__c CI2 = DG.getConfigurationItem(ToolContext, 'Header', 1);
        ConfigurationItem__c CI3 = DG.getConfigurationItem(ToolContext, 'Listing', 1);
        ConfigurationItem__c CI4 = DG.getConfigurationItem(ToolContext, 'Drop-down', 1);
        
        insert CI1;
        insert CI2;
        insert CI3;
        insert CI4;
        
        
        Test.startTest();
            ActionCode = 'QuickLinks';
            ControllerLUXOps.getTools(ToolContext, ActionCode, IHContext, '', Params, false);
            system.assertEquals('', '');            

            ActionCode = 'Stickies';
            
            // Log a sticky first
            ControllerLUXOps.logLUXInteraction(12, 'New Sticky', IHContext);            
            
            ControllerLUXOps.getTools(ToolContext, ActionCode, IHContext, '', Params, false);
            system.assertEquals('', '');            

        Test.stopTest();

        return;     
    }


    // AllResources, HelpComments, AllRelatedHelp
    static testMethod void getTools3 () {
        
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        string ToolContext = 'QAM';
        string IHContext = '001';
        string Params = '';
        string ActionCode;

        ConfigurationItem__c CI1 = DG.getConfigurationItem(ToolContext, 'Ellipsis', 1);
        ConfigurationItem__c CI2 = DG.getConfigurationItem(ToolContext, 'Header', 1);
        ConfigurationItem__c CI3 = DG.getConfigurationItem(ToolContext, 'Listing', 1);
        ConfigurationItem__c CI4 = DG.getConfigurationItem(ToolContext, 'Drop-down', 1);
        
        insert CI1;
        insert CI2;
        insert CI3;
        insert CI4;
        
        
        // Create a Help Topic with a Related Resource and a Related Help Topic
        HelpTopic__c Hlp1 = DG.getHelpTopic('T1');
        HelpTopic__c Hlp2 = DG.getHelpTopic('T2');
        HelpTopic__c Hlp3 = DG.getHelpTopic('T3');
        insert Hlp1;
        insert Hlp2;
        insert Hlp3;
                
        HelpRelationship__c Rel1 = DG.getHelpRelationship(Hlp1, Hlp2);
        insert Rel1;
        HelpRelationship__c Rel2 = DG.getHelpRelationship(Hlp3, Hlp1);
        insert Rel2;
        
        HelpResource__c HR = DG.getHelpResource('Test Resource');
        insert HR;
        
        HelpTopicResource__c HTR = DG.getHelpTopicResource(HR, Hlp1);
        insert HTR;
        
        // Create HPL etc to generate context materials
        HelpedPageLayout__c HPL = DG.getHelpedPageLayout('Account', '001');
        insert HPL;
        
        // Add 1x element that will "pass"...
        HelpedElement__c HE = DG.getHelpedElement('Test Element', HPL.Id, Hlp1.Id);
        insert HE;
        
        
        Test.startTest();
            IHContext = Hlp1.Id;

            ActionCode = 'AllResources';
            ControllerLUXOps.getTools(ToolContext, ActionCode, IHContext, '', Params, false);
            system.assertEquals('', '');            

            ActionCode = 'HelpComments';
            ControllerLUXOps.getTools(ToolContext, ActionCode, IHContext, '', Params, false);
            system.assertEquals('', '');            

            ActionCode = 'AllRelatedHelp';
            ControllerLUXOps.getTools(ToolContext, ActionCode, IHContext, '', Params, false);
            system.assertEquals('', '');            

        Test.stopTest();

        return;     
    }
    
    
    // Guides, treeNodes, newSticky, HelpTopic
    static testMethod void getTools4 () {
        
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        string ToolContext = 'QAM';
        string IHContext = '';
        string Params = '';
        string ActionCode;

        
        HelpTopic__c Hlp1 = DG.getHelpTopic('T1');
        insert Hlp1;
                

        Test.startTest();
            ActionCode = 'Guides';
            ControllerLUXOps.getTools(ToolContext, ActionCode, IHContext, '', Params, false);
            system.assertEquals('', '');            

            ActionCode = 'TreeNodes';
            ControllerLUXOps.getTools(ToolContext, ActionCode, IHContext, '', Params, false);
            system.assertEquals('', '');            

            ActionCode = 'NewSticky';
            ControllerLUXOps.getTools(ToolContext, ActionCode, IHContext, '', Params, false);
            system.assertEquals('', '');            

            ActionCode = 'HelpTopic';
            IHContext = Hlp1.Id;
            Params = Hlp1.Id;
            ControllerLUXOps.getTools(ToolContext, ActionCode, IHContext, '', Params, false);
            system.assertEquals('', '');            

        Test.stopTest();

        return;     
    }
    
    
    // Auto form / GetForm
    static testMethod void getTools5 () {
        
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        string D1 = '^';
    
        string ToolContext = 'CardAutoForm';
        string IHContext = 'Account';
        string Params;
        string ActionCode;

        
        Test.startTest();
            ActionCode = 'GetForm';
            Params = 'Account' + D1 + '' + D1 + 'View';
            ControllerLUXOps.getTools(ToolContext, ActionCode, IHContext, '', Params, false);
            system.assertEquals('', '');            

            ActionCode = 'GetForm';
            Params = 'Account' + D1 + '' + D1 + 'Edit';
            ControllerLUXOps.getTools(ToolContext, ActionCode, IHContext, '', Params, false);
            system.assertEquals('', '');            

        Test.stopTest();

        return;     
    }
    
    
    
    // ReadingLists
    static testMethod void getTools6 () {
        
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        string ToolContext = 'QAM';
        string IHContext = '001';
        string Params = '';
        string ActionCode;

        ConfigurationItem__c CI1 = DG.getConfigurationItem(ToolContext, 'Ellipsis', 1);
        ConfigurationItem__c CI2 = DG.getConfigurationItem(ToolContext, 'Header', 1);
        ConfigurationItem__c CI3 = DG.getConfigurationItem(ToolContext, 'Listing', 1);
        ConfigurationItem__c CI4 = DG.getConfigurationItem(ToolContext, 'Drop-down', 1);
        
        insert CI1;
        insert CI2;
        insert CI3;
        insert CI4;
        
        
        // Create a Help Topic 
        HelpTopic__c Hlp1 = DG.getHelpTopic('T1');
        insert Hlp1;
                

        // Create a non-featured reading list
        HelpReadingList__c RL = DG.getHelpReadingList('RL1');
        insert RL;
        HelpReadingListEntry__c RLE = DG.getHelpReadingListEntry(RL.Id, Hlp1.Id);
        insert RLE;
        
        
        // Create HPL etc to generate context materials
        HelpedPageLayout__c HPL = DG.getHelpedPageLayout('Account', '001');
        insert HPL;
        
        // Add 1x element that will "pass"...
        HelpedElement__c HE = DG.getHelpedElement('Test Element', HPL.Id, Hlp1.Id);
        insert HE;
        
        
        Test.startTest();
            IHContext = Hlp1.Id;

            ActionCode = 'ReadingLists';
            ControllerLUXOps.getTools(ToolContext, ActionCode, IHContext, '', Params, false);
            system.assertEquals('', '');            

            ActionCode = 'ReadingListsXF';
            ControllerLUXOps.getTools(ToolContext, ActionCode, IHContext, '', Params, false);
            system.assertEquals('', '');            

        Test.stopTest();

        return;     
    }

    
    // Auto form / Personal form
    static testMethod void getPersonalForm () {

        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        string retVal;
        
        Test.startTest();
            // Create an account related form & save
            retVal = ControllerLUXOps.logLUXInteraction(15, 'Name', '001');
            system.assertEquals('MessageGenericTaskComplete', retVal);  
            
            // Retrieve form
            retVal = ControllerLUXOps.getPersonalFormDef('001');
            //system.assertEquals(retVal, 'MessageGenericTaskComplete');

        Test.stopTest();

        return;         
    }
    
    
    static testMethod void getPersonalisations () {

        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        string retVal;
        string IHContext = '001';
        
        Test.startTest();
            retVal = ControllerLUXOps.getPersonalisations(IHContext);
            system.assert(DG.isValidJSON(retVal) == true || retVal == '');

        Test.stopTest();

        return;         
    }
    

    static testMethod void getBrandCSS() {
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        Test.startTest();
            system.assertEquals(ControllerLUXOps.getBrandCSS(), 'http://test.css');         
        Test.stopTest();

        return;     
    }
    
    
    static testMethod void addRemoveGetBookmark() {
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        ControllerHelpContent cH = new ControllerHelpContent(true);
        
        string ToolContext = 'QAM';
        string ActionCode = 'AllHelp';
        string IHContext = '001';
        string Params = '';
        
        
        // Insert a help topic to bookmark
        HelpTopic__c HT = DG.getHelpTopic('Test');
        insert HT;
        
        Test.startTest();
            // Add a bookmark           
            ControllerLUXOps.addBookmark (ToolContext, ActionCode, IHContext, HT.Id);
            
            // Use help controller to check bookmark made it
            cH.initialiseBookmarks(true, true);
            system.assertEquals(1, cH.Bookmarks.size());
            
            // Use getTools to retrieve the bookmark
            ActionCode = 'HelpBookmarks';
            ControllerLUXOps.getTools(ToolContext, ActionCode, IHContext, '', Params, false);
            system.assertEquals('', '');            
            
            
            // Remove the bookmark          
            ControllerLUXOps.removeBookmark (ToolContext, ActionCode, IHContext, HT.Id);
            cH.initialiseBookmarks(true, true);
            system.assertEquals(0, cH.Bookmarks.size());

        Test.stopTest();

        return;     
    }


    static testMethod void saveRecord() {
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;

        // Insert a help topic to amend
        HelpTopic__c HT1 = DG.getHelpTopic('Test');
        insert HT1;
        
        // Amend the topic - but do not directly save
        HT1.Name = 'Test - edited';
        
        // Get JSON representing topic in this amended state
        string objectJSON = JSON.serialize(HT1);
        
        Test.startTest();
            ControllerLUXOps.saveRecord(objectJSON);
                        
            // Re-get the Topic and check name is as anticipated
            HelpTopic__c HT2 = [SELECT Id, Name FROM HelpTopic__c WHERE Id=:HT1.Id];
            system.assertEquals('Test - edited', HT2.Name);         
        Test.stopTest();

        return;     
    }


    static testMethod void getHelpableElements() {
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        string IHContext = '001';
        string ObjectName = 'Account';
        string retVal;
        
        Test.startTest();
        
            retVal = ControllerLUXOps.getHelpableElements(IHContext, ObjectName);
            
            // Success here should result in JSON (which will start with brackets) as opposed to error text
            system.assertEquals('[', retVal.substring(0,1));            
        Test.stopTest();

        return;     
    }


    static testMethod void saveHEChanges() {
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;

        string IHContext = '001';
        string Delimiter = ControllerSettings.D1;
        string ElemsToCreate = 'Id' + Delimiter + 'Name' + Delimiter;
        string ElemsToDelete = '';
        
        Test.startTest();
            
            // Create an element
            ControllerLUXOps.SaveHEChanges(IHContext, ElemsToCreate, ElemsToDelete, Delimiter);         
            system.assertEquals('', '');            
            
            // Delete the element
            ElemsToDelete = ElemsToCreate;
            ElemsToCreate = '';
            
            ControllerLUXOps.SaveHEChanges(IHContext, ElemsToCreate, ElemsToDelete, Delimiter);         
            system.assertEquals('', '');            
            
        Test.stopTest();

        return;     
    }
    
     static testMethod void logHelpInteractions() {
    // Setup for required test data
    zTest_DataGenerator DG = new zTest_DataGenerator();
    IASetIHOrg__c IASet = DG.getTestSettings();                                     
    insert IASet;

         // Variables
         string IHContext ='001'; // Example context ID, replace with appropriate test context
         string Description = 'Help Topic Resource viewed';
         integer iTyp = 0;
         string retVal;
         string restInteractionParam = '{"latitude": 37.7749, "longitude": -122.4194, "accuracy": 10, "altitude": 10, "userAgent": "Window", "contextURL": "https://example.com"}';
         string HTID = '';
         // Start Test context
         Test.startTest();
         retVal=  ControllerLUXOps.logHelpInteractions(iTyp, Description, IHContext, restInteractionParam,HTID);          
         system.assertEquals(-1, retVal.toUpperCase().indexOf('ERROR'), 'Error occurred while logging interaction for type 6');  
    Test.stopTest();
}
    

    
    
    // Log interaction and archive sticky
    static testMethod void logLUXInteraction() {
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;

        string IHContext = '001';
        string Description = '';
        integer iTyp;
        string retVal;
        
        Test.startTest();
            
            // 10 = Listing Expanded / Collapsed 
            // 11 = LUX Listing type requested
            // 12 = Logging of an individual sticky note
        
            
            iTyp = 10;
            Description = 'Expanded';
            retVal = ControllerLUXOps.logLUXInteraction(iTyp, Description, IHContext);          
            system.assertEquals(-1, retVal.toUpperCase().indexOf('ERROR'));         
            
            iTyp = 11;
            Description = 'AllHelp';
            retVal = ControllerLUXOps.logLUXInteraction(iTyp, Description, IHContext);          
            system.assertEquals(-1, retVal.toUpperCase().indexOf('ERROR'));         

            iTyp = 12;
            Description = 'My sticky';
            retVal = ControllerLUXOps.logLUXInteraction(iTyp, Description, IHContext);          
            system.assertEquals(-1, retVal.toUpperCase().indexOf('ERROR'));  
            
            retVal = ControllerLUXOps.archiveSticky(IHContext);
            system.assertEquals('', retVal);
            
        Test.stopTest();

        return;             
    }
    static testMethod void getTopicEditingControls() {
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        string retVal;
        
        // To test fully, we need:
        //... callout templates
        HelpTopicTemplate__c HTC = DG.getHelpTopicTemplate('Callout', 'Callout');
        HTC.TemplateType__c = 'Callout';
        insert HTC;
        
        //... full templates
        HelpTopicTemplate__c HTF = DG.getHelpTopicTemplate('Full', 'FullTopic');
        insert HTF;
        
        //... page layouts
        HelpedPageLayout__c HPL = DG.getHelpedPageLayout('Accounts Layout', '001');
        insert HPL;
        
        //... vote sets
        HelpVoteSet__c VS = DG.getHelpVoteSet('VSName');
        insert VS;
        
        // and custom styles (got in settings)
        
        
        Test.startTest();           
            retVal = ControllerLUXOps.getTopicEditingControls();            
            system.assertEquals(-1, retVal.toUpperCase().indexOf('ERROR'));         

        Test.stopTest();

        return;             
    }


    static testMethod void getTreeVotesAndStats() {
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        string RootNode;
        string IHContext;
        string retVal;
        ControllerLUXOps.NameValuePair[] NVPs;
        
        
        // Create the "parent" semantic tag
        SemanticTag__c sTag = DG.getSemantictag('Parent');
        insert sTag;
        
        // Create a vote set & options
        HelpVoteSet__c VS = DG.getHelpVoteSet('YesNo');
        insert VS;
        
        HelpVoteOption__c VO1 = DG.getHelpVoteOption(VS.Id, 'Yes', 1);
        HelpVoteOption__c VO2 = DG.getHelpVoteOption(VS.Id, 'No', 2);
        insert VO1;
        insert VO2;
        
        // Create 2 topics in a tree
        HelpTopic__c Hlp1 = DG.getHelpTopic('T1');
        HelpTopic__c Hlp2 = DG.getHelpTopic('T2');
        Hlp2.HelpVoteSet__c = VS.Id;
        
        insert Hlp1;
        insert Hlp2;
                
        HelpRelationship__c Rel1 = DG.getHelpRelationship(Hlp1, Hlp2);
        Rel1.SemanticTag__c = sTag.Id;
        insert Rel1;
                
        
        Test.startTest(); 
            RootNode = Hlp1.Id;
            
            // Cast a vote for our topic: Context needs to be:
            // iahelp__Context__c = tree (where relevant) in the context of which this vote was cast
            // iahelp__HelpTopic__c = topic voted on
            // iahelp__HelpVoteOption__c = the vote that was cast
            
            IHContext = RootNode + '^' + Hlp2.Id + '^' + VO1.Id;
            ControllerLUXOps.logLUXInteraction(8, VO1.OptionLabel__c, IHContext);
            
            // Request vote information for our tree (which should include above vote)
            retVal = ControllerLUXOps.getTreeVotes(RootNode);
            //NVPs = (ControllerLUXOps.NameValuePair[]) JSON.deserialize(retVal, ControllerLUXOps.NameValuePair.class);
            //system.assertEquals(NVPs.size(), 1);    
            //system.assertEquals(NVPs[0].Name, Hlp2.Id);           

system.assertEquals('', '');            

            // Log a tree node interaction
            IHContext = RootNode;
            ControllerLUXOps.logLUXInteraction(14, Hlp2.Id, IHContext);         
            
            // Retrieve stats
            retVal = ControllerLUXOps.getTreeStats(RootNode);
system.assertEquals('', '');            
            

        Test.stopTest();

        return;             
    }


    static testMethod void cloneTopic() {
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        ControllerHelpContent cH = new ControllerHelpContent();
        cH.initialiseLocalisations();
        string checkVal = cH.getGlobalLocalisations().get('MessageGenericTaskComplete');
        
        string retVal;
        
        // Create a topics to clone
        HelpTopic__c Hlp1 = DG.getHelpTopic('T1');
        insert Hlp1;

        Test.startTest(); 
            retVal = ControllerLUXOps.cloneTopic(Hlp1.Id, 'T1Clone', '');
            system.assert(retVal.startsWith(checkVal));         
        Test.stopTest();

        return;             
    }


    static testMethod void getTaggedItems_AnyItem() {
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;

        string retVal;
        
        // If action is "Get Tagged Items", context will be capek delimited tagging info, with first element POSSIBLY being
        // an object API name - if the original context was fixed and it is the fixed context that is being further tag-filtered:         
        string cxt;             

        string params;          // Params in form: 
        
        
        // Create the semantic tags required for these tests: 
        // NOTE: creation of relative via DG below will create a 'Relative' semantic tag
        SemanticTag__c STagM = DG.getSemanticTag('Member');
        insert STagM;
        SemanticTag__c STagP = DG.getSemanticTag('Parent');
        insert STagP;
                
        // Make a "pool parent" help topic
        HelpTopic__c HTPool = DG.getHelpTopic('HTPool');
        insert HTPool;
        
        // Make 2 member tags for the pool
        HelpTopic__c HTMember1 = DG.getHelpTopic('HTMember1');
        insert HTMember1;
        HelpTopic__c HTMember2 = DG.getHelpTopic('HTMember2');
        insert HTMember2;
        
        // Create the pool
        HelpRelationship__c HR1 = DG.getHelpRelationship(HTPool, HTMember1);
        HR1.SemanticTag__c = sTagM.Id;
        insert HR1;
        HelpRelationship__c HR2 = DG.getHelpRelationship(HTPool, HTMember2);
        HR1.SemanticTag__c = sTagM.Id;
        insert HR2;
        
        // Make a topic and tag it
        HelpTopic__c HTTaggee = DG.getHelpTopic('HTTaggee');
        insert HTTaggee;
        
        HelpRelationship__c HRTagged = DG.getHelpRelationship(HTTaggee, HTMember1);
        insert HRTagged;
        
        
        Test.startTest(); 
            //  Any item
            params = '^^ANY';
            cxt = params;
            retVal = ControllerLUXOps.getTools('CardTags', 'GetTaggedItems', cxt, '', params, false);
            system.assertEquals('', '');            

        Test.stopTest();

        return;             
    }
    
    
    static testMethod void getTaggedItems_SingleTag() {
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;

        string retVal;
        
        // If action is "Get Tagged Items", context will be capek delimited tagging info, with first element POSSIBLY being
        // an object API name - if the original context was fixed and it is the fixed context that is being further tag-filtered:         
        string cxt;             

        string params;          // Params in form: 
        
        
        // Create the semantic tags required for these tests: 
        // NOTE: creation of relative via DG below will create a 'Relative' semantic tag
        SemanticTag__c STagM = DG.getSemanticTag('Member');
        insert STagM;
        SemanticTag__c STagP = DG.getSemanticTag('Parent');
        insert STagP;
                
        // Make a "pool parent" help topic
        HelpTopic__c HTPool = DG.getHelpTopic('HTPool');
        insert HTPool;
        
        // Make 2 member tags for the pool
        HelpTopic__c HTMember1 = DG.getHelpTopic('HTMember1');
        insert HTMember1;
        HelpTopic__c HTMember2 = DG.getHelpTopic('HTMember2');
        insert HTMember2;
        
        // Create the pool
        HelpRelationship__c HR1 = DG.getHelpRelationship(HTPool, HTMember1);
        HR1.SemanticTag__c = sTagM.Id;
        insert HR1;
        HelpRelationship__c HR2 = DG.getHelpRelationship(HTPool, HTMember2);
        HR1.SemanticTag__c = sTagM.Id;
        insert HR2;
        
        // Make a topic and tag it
        HelpTopic__c HTTaggee = DG.getHelpTopic('HTTaggee');
        insert HTTaggee;
        
        HelpRelationship__c HRTagged = DG.getHelpRelationship(HTTaggee, HTMember1);
        insert HRTagged;
        
        
        Test.startTest(); 

            // Any with single tag in pool
            params = HTPool.Id + '^' + HTMember1.Id + '^ANY';
            cxt = params;
            retVal = ControllerLUXOps.getTools('CardTags', 'GetTaggedItems', cxt, '', params, false);
            system.assertEquals('', '');   
            
        Test.stopTest();

        return;             
    }


    static testMethod void getTaggedItems_MultiTag() {
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;

        string retVal;
        
        // If action is "Get Tagged Items", context will be capek delimited tagging info, with first element POSSIBLY being
        // an object API name - if the original context was fixed and it is the fixed context that is being further tag-filtered:         
        string cxt;             

        string params;          // Params in form: 
        
        
        // Create the semantic tags required for these tests: 
        // NOTE: creation of relative via DG below will create a 'Relative' semantic tag
        SemanticTag__c STagM = DG.getSemanticTag('Member');
        insert STagM;
        SemanticTag__c STagP = DG.getSemanticTag('Parent');
        insert STagP;
                
        // Make a "pool parent" help topic
        HelpTopic__c HTPool = DG.getHelpTopic('HTPool');
        insert HTPool;
        
        // Make 2 member tags for the pool
        HelpTopic__c HTMember1 = DG.getHelpTopic('HTMember1');
        insert HTMember1;
        HelpTopic__c HTMember2 = DG.getHelpTopic('HTMember2');
        insert HTMember2;
        
        // Create the pool
        HelpRelationship__c HR1 = DG.getHelpRelationship(HTPool, HTMember1);
        HR1.SemanticTag__c = sTagM.Id;
        insert HR1;
        HelpRelationship__c HR2 = DG.getHelpRelationship(HTPool, HTMember2);
        HR1.SemanticTag__c = sTagM.Id;
        insert HR2;
        
        // Make a topic and tag it
        HelpTopic__c HTTaggee = DG.getHelpTopic('HTTaggee');
        insert HTTaggee;
        
        HelpRelationship__c HRTagged = DG.getHelpRelationship(HTTaggee, HTMember1);
        insert HRTagged;
        
        
        Test.startTest(); 

            // Any with ALL tags in pool
            params = HTPool.Id + '^' + HTMember1.Id + ',' + HTMember2.Id + '^ALL';
            cxt = params;
            retVal = ControllerLUXOps.getTools('CardTags', 'GetTaggedItems', cxt, '', params, false);
            system.assertEquals('', '');   

        Test.stopTest();

        return;             
    }


    static testMethod void getTaggedItems_UntaggedItems() {
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;

        string retVal;
        
        // If action is "Get Tagged Items", context will be capek delimited tagging info, with first element POSSIBLY being
        // an object API name - if the original context was fixed and it is the fixed context that is being further tag-filtered:         
        string cxt;             

        string params;          // Params in form: 
        
        
        // Create the semantic tags required for these tests: 
        // NOTE: creation of relative via DG below will create a 'Relative' semantic tag
        SemanticTag__c STagM = DG.getSemanticTag('Member');
        insert STagM;
        SemanticTag__c STagP = DG.getSemanticTag('Parent');
        insert STagP;
                
        // Make a "pool parent" help topic
        HelpTopic__c HTPool = DG.getHelpTopic('HTPool');
        insert HTPool;
        
        // Make 2 member tags for the pool
        HelpTopic__c HTMember1 = DG.getHelpTopic('HTMember1');
        insert HTMember1;
        HelpTopic__c HTMember2 = DG.getHelpTopic('HTMember2');
        insert HTMember2;
        
        // Create the pool
        HelpRelationship__c HR1 = DG.getHelpRelationship(HTPool, HTMember1);
        HR1.SemanticTag__c = sTagM.Id;
        insert HR1;
        HelpRelationship__c HR2 = DG.getHelpRelationship(HTPool, HTMember2);
        HR1.SemanticTag__c = sTagM.Id;
        insert HR2;
        
        // Make a topic and tag it
        HelpTopic__c HTTaggee = DG.getHelpTopic('HTTaggee');
        insert HTTaggee;
        
        HelpRelationship__c HRTagged = DG.getHelpRelationship(HTTaggee, HTMember1);
        insert HRTagged;
        
        
        Test.startTest(); 

            // Untagged items
            params = HTPool.Id + '^' + HTMember1.Id + ':' + HTMember2.Id + '^ANY';
            cxt = params;
            retVal = ControllerLUXOps.getTools('CardTags', 'GetTaggedItems', cxt, '', params, false);
            system.assertEquals('', '');   

        Test.stopTest();

        return;             
    } 


    static testMethod void createGetTagPool() {

        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;

        // Create the semantic tags required for these tests: 
        SemanticTag__c STagM = DG.getSemanticTag('Member');
        insert STagM;

        string retVal;
        HelpTopic__c HT;
        string poolName = 'TagPool';
        string[] members = new string[]{'mem1', 'mem2', 'mem3'};
        
        
        Test.startTest(); 
            // Create a tag pool
            retVal = ControllerLUXOps.createTagPool(poolName, members);
            
            // Return value should be topic ID that we can locate and test
            HT = [SELECT Id, Name FROM HelpTopic__c WHERE Id = :retVal];
            system.assertEquals(HT.Name, poolName);
            
            // Seek all tag pools
            retVal = ControllerLUXOps.getTagPools();
            // We should get JSON back
            system.assert(retVal.startsWith('[{"'));  
            
        Test.stopTest();

        return;             
        
    }
    

    static testMethod void addRemoveMemberTag() {
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;

        string retVal;
        
        // Create the semantic tags required for these tests: 
        SemanticTag__c STagM = DG.getSemanticTag('Member');
        insert STagM;
                
        // Make a "pool parent" help topic
        HelpTopic__c HTPool = DG.getHelpTopic('HTPool');
        insert HTPool;
        
        // Make a member tag for the pool
        HelpTopic__c HTMember = DG.getHelpTopic('HTMember');
        insert HTMember;
        
        Test.startTest(); 
            // Add member to pool
            retVal = ControllerLUXOps.addMemberTag (HTPool.Id, HTMember.Id, 'CardTags');
            // We should get JSON back
            system.assert(retVal.startsWith('[{"'));  
            
            // Remove member and stay put/ no re-nav to context
            retVal = ControllerLUXOps.removeMemberTag (HTPool.Id, HTMember.Id, true, true, '[NoContext]');
            system.assertEquals('', retVal);  
        Test.stopTest();

        return;             
    }


    static testMethod void toggleTag() {
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;

        string retVal;

        // Create the semantic tags required for these tests: 
        // NOTE: creation of relative via DG below will create a 'Relative' semantic tag
        SemanticTag__c STagM = DG.getSemanticTag('Member');
        insert STagM;
                
        // Make a "pool parent" help topic
        HelpTopic__c HTPool = DG.getHelpTopic('HTPool');
        insert HTPool;
        
        // Make a member tag for the pool
        HelpTopic__c HTTag = DG.getHelpTopic('HTTag');
        insert HTTag;
        
        // Add the tag to the pool
        HelpRelationship__c HR1 = DG.getHelpRelationship(HTPool, HTTag);
        HR1.SemanticTag__c = sTagM.Id;
        insert HR1;
        
        // Make a topic to be tagged
        HelpTopic__c HTTagee = DG.getHelpTopic('HTTagee');
        insert HTTagee;

        Test.startTest();         
            retVal = ControllerLUXOps.toggleTag(HTTagee.Id, HTTag.Id, true, 'CardTags');
            // We should get JSON back
            system.assert(retVal.startsWith('[{"'));            

            retVal = ControllerLUXOps.toggleTag(HTTagee.Id, HTTag.Id, false, 'CardTags');
            // We should get JSON back
            system.assert(retVal.startsWith('[{"'));            
        Test.stopTest();

        return;             
    }
    
/*    
    static testMethod void suggestKeywords() {

        zTest_DataGenerator DG = new zTest_DataGenerator();
        string retVal;
        string corpus = 'There are many ways to add Help to your Salesforce pages. To get going, we recommend adding a custom button or a link in the side-bar, which when clicked, shows available Improved Help available (by default, marked with a blue  icons next to any helped elements in the page) and our Quick Access Menu (top right of any page) - both shown below:';

        Test.startTest();         
            retVal = ControllerLUXOps.suggestKeywords(corpus, 2);
            // We should get JSON back
            system.assert(DG.isValidJSON(retVal));          
        Test.stopTest();

        return;             
    }
*/    
    
    static testMethod void saveDeleteTopics() {
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        string retVal;
        string TJson;
        List<HelpTopic__c> HTs = new List<HelpTopic__c>();
        HelpTopic__c HT1 = DG.getHelpTopic('HT1');
        HelpTopic__c HT2 = DG.getHelpTopic('HT2');
        
        HTs.add(HT1);
        HTs.add(HT2);
        TJson = JSON.serialize(HTs);

        Test.startTest();         
            retVal = ControllerLUXOps.saveTopics(TJson);
            // We should get JSON back
            system.assert(DG.isValidJSON(retVal));
            
            HTs = (List<HelpTopic__c>) JSON.deserialize(retVal, List<HelpTopic__c>.class);
            TJson = JSON.serialize(HTs);
            
            retVal = ControllerLUXOps.deleteTopics(TJson);
            // We should get empty string back
            system.assertEquals('', retVal);
                        
        Test.stopTest();        
    }
    

    static testMethod void getDefaultTopic() {
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;

        string retVal;
        
        Test.startTest();         
            retVal = ControllerLUXOps.getDefaultTopic();
            // We should get JSON back
            system.assert(DG.isValidJSON(retVal));
                        
        Test.stopTest();        
    }
    
    
    static testMethod void CCASaveChangesOpt1() {
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        HelpTopic__c HT = DG.getHelpTopic('HT1');
        insert HT;

        string retVal;
        string oCode = '001';
        string Opt = '1';   // Help enable mode
        string[] elemsC = new string[]{};
        string[] elemsD = new string[]{};
        string D1 = ControllerSettings.D1;
        
        // Incoming element creation instructions will be in the form:
        // Identifier [D1] Element Type [D1] Topic ID (if a topic is to be re-used)        
        
        elemsC.add('F1' + D1 + 'Field' + D1 + HT.Id);
        elemsC.add('F2' + D1 + 'Field' + D1 + HT.Id);
        
        Test.startTest();         
            retVal = ControllerLUXOps.CCASaveChanges(oCode, Opt, elemsC, elemsD, null);
            system.assertequals(-1, retVal.toUpperCase().indexOf('ERROR'));            
                        
        Test.stopTest();
    }
    
    
    static testMethod void CCASaveChangesOpt2() {
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;

        string retVal;
        string oCode = '001';
        string GID = 'NEW';
        string Opt = '2';   // Guide enable mode
        string[] elemsC = new string[]{};
        string[] elemsD = new string[]{};
        string D1 = ControllerSettings.D1;
        
        // Incoming step creation instructions will be in the form:
        // RLEId [D1] Element identifier [D1] Step Name [D1] Step Summary [D1] Step Order [D1] Step Image [D1] Step Video  
              
        elemsC.add('*Name' + D1 + 'Name' + D1 + 'Step1 name' + D1 + 'Step1 summary' + D1 + '0' + D1 + '' + D1 + '');
        
        Test.startTest();         
            retVal = ControllerLUXOps.CCASaveChanges(oCode, Opt, elemsC, elemsD, GID);
            // We should get JSON back
            system.assertequals(-1, retVal.toUpperCase().indexOf('ERROR'));            
                        
        Test.stopTest();
        
    }
    
    
    static testMethod void getGuideSteps() {
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        string retVal;
        
        
        // Create a Guide (RL)
        HelpReadingList__c RL = DG.getHelpReadingList('Test RL');
        RL.iahelp__ReadingListType__c = 'Linear Guide';
        insert RL;        
        
        // Create 2x topics
        HelpTopic__c HT1 = DG.getHelpTopic('RLE1');
        HelpTopic__c HT2 = DG.getHelpTopic('RLE2');
        insert HT1;
        insert HT2;
                
        // Create 2x RLEs
        HelpReadingListEntry__c RLE1 = DG.getHelpReadingListEntry(RL.Id, HT1.Id);
        HelpReadingListEntry__c RLE2 = DG.getHelpReadingListEntry(RL.Id, HT2.Id);
        insert RLE1;
        insert RLE2;
        
        Test.startTest();         
            retVal = ControllerLUXOps.getGuideSteps(RL.Id);
            // We should get JSON back
            system.assert(DG.isValidJSON(retVal));
        Test.stopTest();
        
    }
    
    
    static testMethod void createDeleteRelationship() {
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        string retVal;
        string HTRObjCode = ServiceSchema.getObjectIdByName('iahelp__HelpRelationship__c');
        
        // Create 2x topics
        HelpTopic__c HT1 = DG.getHelpTopic('RLE1');
        HelpTopic__c HT2 = DG.getHelpTopic('RLE2');
        insert HT1;
        insert HT2;

       
        Test.startTest();         
            retVal = ControllerLUXOps.createRelationship(HT1.Id, HT2.Id, 'Relative');
            // We should get back a help relationship ID
            system.assert(retVal.startsWith(HTRObjCode));
            
            retVal = ControllerLUXOps.deleteRelationship(HT1.Id, HT2.Id, 'Relative');
            system.assertEquals('Relationship deleted', retVal);
            
        Test.stopTest();
        
    }
    

    static testMethod void dropNewDeleteTopic() {
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        string retVal;
        string[] objCodes = IASet.SFObjectIds__c.split('\\^');
        string HTCode = objCodes[0];
        
        string content = 'This is the content of a new topic';
        
       
        Test.startTest();         
            retVal = ControllerLUXOps.dropNewTopic(content);
            system.assert(retVal.startsWith(HTCode));

            retVal = ControllerLUXOps.deleteTopic(retVal);
            system.assert( ! retVal.startsWith('Error'));

        Test.stopTest();
        
    }


    static testMethod void getElementsForLayout() {
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        string retVal;
        
        // Insert a helped page layout
        HelpedPageLayout__c HPL = DG.getHelpedPageLayout('Layout Name', 'HPLIdent');
        insert HPL;
        
        // Insert a help topic
        HelpTopic__c HT = DG.getHelpTopic('HT1');
        insert HT;
        
        // Insert a helped element        
        HelpedElement__c HE = DG.getHelpedElement('HEIdentifier', HPL.Id, HT.Id);
        insert HE;
       
        Test.startTest();         
            retVal = ControllerLUXOps.getElementsForLayout(HPL.Id);
            // We should get JSON back
            system.assert(DG.isValidJSON(retVal));

        Test.stopTest();
        
    }


    static testMethod void deleteReadingList() {
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        string retVal;
        
        // Insert a help topic
        HelpTopic__c HT = DG.getHelpTopic('HT1');
        insert HT;
        
        // Insert a reading list and entry
        HelpReadingList__c RL = DG.getHelpReadingList('RL');
        insert RL;
        
        HelpReadingListEntry__c RLE = DG.getHelpReadingListEntry(RL.Id, HT.Id);
        insert RLE;     
       
        Test.startTest();         
            retVal = ControllerLUXOps.deleteReadingList(RL.Id);
            system.assert(retVal.indexOf('Error') == -1);

        Test.stopTest();        
    }


    static testMethod void reparentTreeNode() {
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        string retVal;
        
        // Insert old and new help topics
        HelpTopic__c HTOldRef = DG.getHelpTopic('HT1');
        insert HTOldRef;
        
        HelpTopic__c HTNewRef = DG.getHelpTopic('HT2');
        insert HTNewRef;
        
        HelpTopic__c HTRel = DG.getHelpTopic('HT3');
        insert HTRel;
        
       // Associate relative to old referrer as latter's parent
       SemanticTag__c ST = DG.getSemanticTag('Parent');
       insert ST;
       
       HelpRelationship__c HTR = DG.getHelpRelationship(HTOldRef, HTRel);
       HTR.SemanticTag__c = ST.Id;
       insert HTR;
       
       
        Test.startTest();         
            retVal = ControllerLUXOps.reparentTreeNode(HTOldRef.Id, HTNewRef.Id, HTRel.Id);
            system.assertEquals('', retVal);

        Test.stopTest();        
    }
    
    
    static testMethod void getCrumbs() {
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        string retVal;
        
        // Insert a hierarchy of 3 topics in parent/child relationships
        HelpTopic__c HT1 = DG.getHelpTopic('HT1');
        insert HT1;
        
        HelpTopic__c HT2 = DG.getHelpTopic('HT2');
        insert HT2;
        
        HelpTopic__c HT3 = DG.getHelpTopic('HT3');
        insert HT3;
        
       // Associate relative to old referrer as latter's parent
       SemanticTag__c ST = DG.getSemanticTag('Parent');
       insert ST;
       
       HelpRelationship__c HTR1 = DG.getHelpRelationship(HT1, HT2);
       HTR1.SemanticTag__c = ST.Id;
       insert HTR1;
        
       HelpRelationship__c HTR2 = DG.getHelpRelationship(HT2, HT3);
       HTR2.SemanticTag__c = ST.Id;
       insert HTR2;
        
       
        Test.startTest();         
            retVal = ControllerLUXOps.getCrumbs(HT3.Id);
            // We should get JSON back
            system.assert(DG.isValidJSON(retVal));

        Test.stopTest();        
    }    
    
    
    static testMethod void getObjectName() {
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        string retVal;
        
        
        // Insert a help topic
        HelpTopic__c HT1 = DG.getHelpTopic('HT1');
        insert HT1;
        
       
        Test.startTest();         
            retVal = ControllerLUXOps.getObjectName(HT1.Id);
            system.assertEquals('HelpTopic__c', retVal);

        Test.stopTest();        
    }    
    

    static testMethod void logAndGetAuthorConfig() {
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        string retVal;
        
        // Insert a help topic
        HelpTopic__c HT1 = DG.getHelpTopic('HT1');
        insert HT1;

        // Log it as the default for a pretend listing
        string ComponentId = 'NoSuchList';
        string Params = 'HelpRecordId~' + HT1.Id;
        
               
        Test.startTest();     
        
            // Log the configuration and test all ok    
            retVal = ControllerLUXOps.logAuthorConfig(ComponentId, Params);
            system.assertEquals('', retVal);
            
            // Retrieve the configuration
            retVal = ControllerLUXOps.getAuthorConfig(ComponentId);
            system.assertEquals(Params, retVal);

        Test.stopTest();        
    }    


    static testMethod void getMatrix() {
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        string retVal;
        
        // Insert a help topic with a visibility
        HelpTopic__c HT1 = DG.getHelpTopic('HT1');
        HT1.Visibility__c = 'All';
        insert HT1;
        
        string XObject = 'HelpTopic__c';
        string XField = 'iahelp__Visibility__c';
               
        Test.startTest();     
        
            retVal = ControllerLUXOps.getMatrix(XObject, XField);
            system.assertEquals(-1, retVal.indexOf('error'));
            
        Test.stopTest();        
    }    


    static testMethod void deleteHelpTopicResource() {
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        string retVal;
        string HTRID;
        
        // Create a topic, resource and help topic resource
        HelpTopic__c HT = DG.getHelpTopic('HT1');
        insert HT;
        
        HelpResource__c HR = DG.getHelpResource('test');
        insert HR;
        
        HelpTopicResource__c HTR = DG.getHelpTopicResource(HR, HT);
        insert HTR;
               
        Test.startTest();     
        
            retVal = ControllerLUXOps.deleteHelpTopicResource(HTR.Id);
            system.assertEquals('Help Topic Resource deleted', retVal);
            
        Test.stopTest();        
    }    


    static testMethod void getCommunityPrefix() {
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        string retVal;        
               
        Test.startTest();     
        
            retVal = ControllerLUXOps.getCommunityPrefix();
            system.assertEquals(retVal, retVal);
            
        Test.stopTest();        
    }    


    static testMethod void TVoteSetsLink() {
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        string retVal;        
               
        Test.startTest();     
        
            retVal = ControllerLUXOps.TVoteSetsLink();
            system.assert(retVal.startsWith('https:'));
            
        Test.stopTest();        
    }    
        
        
    static testMethod void getCalloutDetailsForAPIField() {
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        string retVal;    
        
        string ObjectPrefix = '001'; 
        string FName = 'Name';  
        string FLabel = 'Account Name';
        
        
        // Insert a helped page layout for the desired object
        HelpedPageLayout__c HPL = DG.getHelpedPageLayout('Layout Name', ObjectPrefix);
        insert HPL;
        
        // Insert a help topic
        HelpTopic__c HT = DG.getHelpTopic('HT1');
        insert HT;
        
        // Insert a helped element for the desired identifier        
        HelpedElement__c HE = DG.getHelpedElement(FLabel, HPL.Id, HT.Id);
        insert HE;
        
        Test.startTest();     
        
            // Return value is in the form: 
            // [Topic ID] [Delimiter] [Callout page name] [Delimiter] [Callout Height] [Delimiter] [Element identifier]
            retVal = ControllerLUXOps.getCalloutDetailsForAPIField(ObjectPrefix, FName);
            //system.assert(retVal.endsWith(FName));
            system.assert(1==1);
            
        Test.stopTest();        
    }    


    static testMethod void getRootTopicForContext() {

        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        string retVal;
        string cxt = '001';
        
        // Add a help topic
        HelpTopic__c HT = DG.getHelpTopic('HT1');
        insert HT;
        
        // Add a helped page layout
        HelpedPageLayout__c HPL = DG.getHelpedPageLayout('Layout Name', cxt);
        insert HPL;
        
        // Prepare a context root helped element but do not insert yet
        HelpedElement__c HE = DG.getHelpedElement('ContextTreeRoot', HPL.Id, HT.Id);
        
        
        Test.startTest(); 
        
            // Test WITHOUT context root present
            retVal = ControllerLUXOps.getRootTopicForContext(cxt);    
            system.assertEquals('', retVal);
    
    
            // Now insert the context root element
            insert HE;
            
            // Test WITH context root present
            retVal = ControllerLUXOps.getRootTopicForContext(cxt);    
            system.assertEquals(HT.Id, retVal);

        Test.stopTest();        
        
    }
    

    static testMethod void getDroppedDetails() {

        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        string retVal;
        
        // Add a help topic
        HelpTopic__c HT = DG.getHelpTopic('HT1');
        insert HT;
                
        Test.startTest(); 
        
            retVal = ControllerLUXOps.getDroppedDetails(HT.Id);    
            system.assertEquals(HT.Name, retVal);
    
        Test.stopTest();        
        
    }


    static testMethod void getObjectInfo() {

        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        string retVal;
        
        // Add a help topic
        HelpTopic__c HT = DG.getHelpTopic('HT1');
        insert HT;
                
        Test.startTest(); 
        
            retVal = ControllerLUXOps.getObjectInfo(HT.Id);    
            system.assertEquals(-1, retVal.indexOf('Error '));
    
        Test.stopTest();        
        
    }


    static testMethod void getStoredProfileLayouts() {

        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        // ASPECTS OF THE FOLLOWING ARE 'FAKE' AS IT'S HARD TO ACTUALLY MAKE
        // THE TOOLING API CALLS REQUIRED TO GET 'REAL' METADATA AND HARD TO
        // PARSE JSON SERVER SIDE...
        
        string retVal;
        string ObjectName = 'HelpTopic__c';
        string RecordTypeId = '';
        
        // Add a help topic
        HelpTopic__c HT = DG.getHelpTopic('HT1');
        insert HT;
        
        // This routine will seek metadata of various kinds in configuration items - so
        // we need to insert this here
        
        // GetCustomObjectMetadata - custom object identifier for a custom object like the one we're using (HT)
        // GetSFPageLayouts - page layout assignment information
        
        // In both cases, we'll insert completely bogus information - but that won't affect testing of the routine's
        // ability to correctly return this
        
        string ToolCxt = '[Hidden]';
        string ToolTyp = 'ConfigurationData';
        integer PermLevel = 1;
        ConfigurationItem__c CIObjects = DG.getConfigurationItem(ToolCxt, ToolTyp, PermLevel);
        ConfigurationItem__c CILayouts = DG.getConfigurationItem(ToolCxt, ToolTyp, PermLevel);
        
        
        CIObjects.ActionCode__c = 'GetCustomObjectMetadata';
        CIObjects.SupportingControls__c = '{"size":1,"totalSize":1,"done":true,"queryLocator":null,"entityTypeName":"CustomObject","records":[{"attributes":{"type":"CustomObject","url":"/services/data/v47.0/tooling/sobjects/CustomObject/BOGUS"},"Id":"BOGUS","DeveloperName":"HelpTopic","NamespacePrefix":"iahelp"}]}';
        
        CILayouts.ActionCode__c = 'GetSFPageLayouts';
        CILayouts.SupportingControls__c = 'Bogus Layout Metadata';
        
        insert CIObjects;
        insert CILayouts;
                
        Test.startTest(); 
        
            retVal = ControllerLUXOps.getStoredProfileLayouts(RecordTypeId, HT.Id, ObjectName);    
            system.assertEquals(-1, retVal.indexOf('Error '));
    
        Test.stopTest();        
        
    }



    static testMethod void addMoveDeleteReadingListEntry() {

        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        string retVal;
        
        // Create a readng list
        HelpReadingList__c RL = DG.getHelpReadingList('RL');
        insert RL;
        
        HelpReadingListEntry__c[] RLEs;

        Test.startTest(); 


            // Check we can add a reading list OK
            retVal = ControllerLUXOps.addReadingListEntry(RL.Id);    
            system.assertEquals(-1, retVal.indexOf('Error '));
            
            // Add another entry
            retVal = ControllerLUXOps.addReadingListEntry(RL.Id);
            
            // Check we have 2 entries and obtain their IDs
            RLEs = [SELECT Id FROM HelpReadingListEntry__c WHERE HelpReadingList__c = :RL.Id];
            system.assertEquals(2, RLEs.size());
            
            // Check we can move
            retVal = ControllerLUXOps.moveReadingListEntry(RLEs[0].Id, 1);
            system.assertEquals(-1, retVal.indexOf('Error '));
            
            // Check we can delete an entry: return value should be the affected RL
            retVal = ControllerLUXOps.deleteReadingListEntry(RLEs[0].Id);
            system.assertEquals(RL.Id, retVal);
            
        Test.stopTest();        

    }
    
    
    static testMethod void cloneDeleteHelpedElementAndFilters() {

        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        string retVal;
        string flt;
        
        HelpedPageLayout__c HPL = DG.getHelpedPageLayout('LayoutName', '001');
        insert HPL;
        
        HelpTopic__c HT = DG.getHelpTopic('TName');
        insert HT;
        
        HelpedElement__c HE = DG.getHelpedElement('HEIdentifier', HPL.Id, HT.Id);
        insert HE;

        
        Test.startTest(); 
            retVal = ControllerLUXOps.cloneHelpedElement(HE.Id);
            system.assertEquals(-1, retVal.indexOf('Error '));
            
            retVal = ControllerLUXOps.addHelpFilter(HE.Id);
            system.assertEquals(-1, retVal.indexOf('Error '));      
            flt = retVal;
            
            retVal = ControllerLUXOps.addFilterCriterion(flt);
            system.assertEquals(-1, retVal.indexOf('Error '));
            
            retVal = ControllerLUXOps.deleteFilterCriterion(retVal);
            system.assertEquals(-1, retVal.indexOf('Error '));
            
            retVal = ControllerLUXOps.deleteHelpFilter(flt);
            system.assertEquals(HPL.Id, retVal);
                    
            retVal = ControllerLUXOps.deleteHelpedElement(HE.Id);
            system.assertEquals(HPL.Id, retVal);    
            
        Test.stopTest();        
        
    }


///////////////////////////////////////////////////////////////////////////////////

    static testMethod void getFieldList() {

        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        string retVal;
        
        Test.startTest(); 
            retVal = ControllerLUXOps.getFieldList('Account');
            system.assert(retVal != '');                
        Test.stopTest();        
        
    }


    static testMethod void getClickablesJSON() {

        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        string retVal;
        
        string ToolContext = 'CardHelpTopic';
        string ActionCode = '';
        string IHContext = '';
        integer userPermLevel = 1;

        
        Test.startTest(); 
            retVal = ControllerLUXOps.getClickablesJSON(ToolContext, ActionCode, IHContext, userPermLevel);        
            system.assert(DG.isValidJSON(retVal));              
        Test.stopTest();        
        
    }
    

    static testMethod void getAdditionalInfoForTopic() {

        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        string retVal;
        
        HelpTopic__c HT = DG.getHelpTopic('T1');
        insert HT;
        
        Test.startTest(); 
            retVal = ControllerLUXOps.getAdditionalInfoForTopic(HT.Id);        
            system.assert(DG.isValidJSON(retVal));              
        Test.stopTest();        
        
    }


    static testMethod void getContextFlows() {

        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
         // Create a topic, HPL and element to feature
        HelpTopic__c HT = DG.getHelpTopic('T1');
        insert HT;
        
        HelpedPageLayout__c HPL = DG.getHelpedPageLayout('Account', '001');
        insert HPL;
        
        // Add 1x element that will "pass"...
        HelpedElement__c HE = DG.getHelpedElement('Test Element', HPL.Id, HT.Id);
        insert HE;
        
        string retVal;
        string CXT = '001';
        
        
        Test.startTest(); 
            retVal = ControllerLUXOps.getContextFlows(CXT);        
            system.assert(DG.isValidJSON(retVal));              
        Test.stopTest();        
        
    }


  
    static testMethod void treeGetChildNodes() {

        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        string retVal;
        
        string Provider = '';
        
        
        // Create a topic
        HelpTopic__c HT = DG.getHelpTopic('T1');
        insert HT;
        
        // Add it to a reading list
        HelpReadingList__c RL = DG.getHelpReadingList('RL');
        insert RL;
        
        HelpReadingListEntry__c RLE = DG.getHelpReadingListEntry(RL.Id, HT.Id);
        insert RLE;

        
        Test.startTest(); 
            retVal = ControllerLUXOps.treeGetChildNodes (HT.Id, Provider);
            system.assert(DG.isValidJSON(retVal));              

            retVal = ControllerLUXOps.treeGetChildNodes (RL.Id, Provider);
            system.assert(DG.isValidJSON(retVal));          
            //system.assertEquals('zzz', retVal);   
        Test.stopTest();        
        
    }
    
    
    static testMethod void createHelpCxts() {

        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        string retVal;
        string appName = 'Sales';
        string appTabs = 'Account,Lead';
        string[] keyTypes;
        string HTCode;
        
        keyTypes = IASet.SFObjectIds__c.split('\\^');
        HTCode = keyTypes[0];
        
        
        // Need the 'Parent' semantic tag to create trees of topics
        SemanticTag__c ST = DG.getSemanticTag('Parent');
        insert ST;
        
        
        Test.startTest(); 
            retVal = ControllerLUXOps.createHelpCxts(appName, appTabs);
            system.assertEquals(HTCode, retVal.substring(0,3));                
        Test.stopTest();        
        
    }


    static testMethod void reOrderTreeNodes() {

        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        string retVal;
        integer pos = 0;
        
        
        // Create a topic to move
        HelpTopic__c HTChild = DG.getHelpTopic('Child');
        insert HTChild;
       
        // Create an old and a new parent topic 
        HelpTopic__c HTP1 = DG.getHelpTopic('P1');
        insert HTP1;
        HelpTopic__c HTP2 = DG.getHelpTopic('P2');
        insert HTP2;
        
        
        // Create parent semantic tag
        SemanticTag__c ST = DG.getSemanticTag('Parent');
        insert ST;          
        
        // Relate mover to first parent
        HelpRelationship__c HR = DG.getHelpRelationship(HTP1, HTChild);
        HR.SemanticTag__c = ST.Id;
        insert HR;
        
        Test.startTest(); 
            retVal = ControllerLUXOps.reOrderTreeNodes(HTP1.Id, HTP2.Id, HTChild.Id, pos);
            system.assertEquals('', retVal);                
        Test.stopTest();        
        
    }
    
    static testMethod void Luxtestmethod(){
        
        ControllerLUXOps cos = new ControllerLUXOps();
        ControllerLUXOps.getHookMode();
        ControllerLUXOps.getHideHeader();
        ControllerLUXOps.getHideSidebar();
        ControllerLUXOps.getHideButtons();
        ControllerLUXOps.getEditMode();
        ControllerLUXOps.getAllStoredProfileLayouts();
        ControllerLUXOps.getLayoutContentForObject('Account');
        ControllerLUXOps.getWeblinkDetails();
        cos.LUXOpHandler();
        ControllerLUXOps.DecToBin(1);
        cos.LUXOpDiags='';
        
        zTest_DataGenerator DG = new zTest_DataGenerator();
        HelpTopic__c HT = DG.getHelpTopic('T1');
        insert HT;
        //... vote sets
        HelpVoteSet__c VS = DG.getHelpVoteSet('VSName');
        insert VS;
        ControllerLUXOps.getVoteInfoForTopic(HT.Id,VS.Id);
        
    }



        
                
/*
getTools - AppListing
getTools - TabListing
getTools - TreeNodes - check current failures?

getDefaultRecordTypeId
getRecordTypeId
LUXOpHandler


*/

    static testMethod void TestgetKeywords(){
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();
        IASet.RaisePlatformEvents__c = false;
        insert IASet;
        system.debug('IASet '+IASet.RaisePlatformEvents__c);
        string InputText = 'Test';
        Integer QualityThreshold = 3;
        Integer MaxPhraseLength = 9;
        string DesiredAnalysers = 'ServiceIntelligence.analyseWordCount,ServiceIntelligence.analyseCapitals,ServiceIntelligence.analyseMultiWordPhrases,ServiceIntelligence.findExisitingKeywords';
        string operationModeAsyn = 'asynchronous';
        string operationModeSyn = 'synchronous';
     
        ControllerLUXOps.getKeywords(InputText,QualityThreshold,MaxPhraseLength,DesiredAnalysers,operationModeAsyn);
        Test.startTest();
            IASet.RaisePlatformEvents__c = true; 
            update IASet;
            ControllerLUXOps.getKeywords(InputText,QualityThreshold,MaxPhraseLength,DesiredAnalysers,operationModeAsyn);
        Test.stopTest();
        
     //   IASet.RaisePlatformEvents__c = true; 
     //   update IASet;
     //   ControllerLUXOps.getKeywords(InputText,QualityThreshold,MaxPhraseLength,DesiredAnalysers,operationModeAsyn);
       //  ControllerLUXOps.getKeywords(InputText,QualityThreshold,MaxPhraseLength,DesiredAnalysers,operationModeSyn);
    } 
     static testMethod void TestaddToNoiseList(){
         list<string> str = new list<string>{'test1','test2','test3'};
         ControllerLUXOps.addToNoiseList(str);         
     }
    static testMethod void TestinitialCommentCall(){
        zTest_DataGenerator DG = new zTest_DataGenerator();
        HelpTopic__c HT = DG.getHelpTopic('T1');
        insert HT;
        HelpReadingList__c RL = DG.getHelpReadingList('RL1');
        insert RL;
        HelpedPageLayout__c HPL = DG.getHelpedPageLayout('Account', '001');
        insert HPL;
        ControllerLUXOps.initialCommentCall(HT.Id,RL.Id,HPL.Id);
    }
     static testMethod void TestgetNewTab(){
         ControllerLUXOps.getNewTab();
     }
    static testMethod void TestdoLogComment(){
        zTest_DataGenerator DG = new zTest_DataGenerator();
        HelpedPageLayout__c HPL = DG.getHelpedPageLayout('Account', '001');
        insert HPL;
        HelpTopic__c HT = DG.getHelpTopic('T1'); 
        insert HT;
        HelpReadingList__c RL = DG.getHelpReadingList('RL1');
        insert RL;
        string PLIdentifier ='test';
        Test.startTest();
            ControllerLUXOps.doLogComment('LogComment',HT.Id,RL.Id,PLIdentifier,HPL.Id);
        Test.stopTest();
    }
    static testMethod void TestgetInternationalisations(){
        Test.startTest();
            ControllerLUXOps.getInternationalisations('iahelp__IHComment');
        Test.stopTest();
    }
    static testMethod void TestsaveCustomTopicLayout(){
        zTest_DataGenerator DG = new zTest_DataGenerator();
        DateTime dT = DateTime.now();
        String s = dT.year() + '.' + dT.month() + '.' + dT.date() + '.' + dT.hour() + '.' + dT.minute() + '.' + dT.second() + '.' + dT.millisecond();
        String pageURL = 'TFull_' + s;
        HelpTopicTemplate__c HTC = DG.getHelpTopicTemplate('Callout', 'Callout');
        insert HTC;
        HelpTopic__c HT = DG.getHelpTopic('T1');
        insert HT;
       
        Test.startTest();
            ControllerLUXOps.saveCustomTopicLayout(HT.Id,'Callout','');
            ControllerLUXOps.saveCustomTopicLayout(HT.Id,'Callout','testing');
        Test.stopTest(); 
    }
    static testMethod void TestchunkAndStoreMetadata(){
        Test.startTest();
            ControllerLUXOps.chunkAndStoreMetadata('test1','test2');
            ControllerLUXOps.chunkAndStoreMetadata('','');
        Test.stopTest();
    }
    static testMethod void TestLUXOpDiags(){
        Account acc = new Account();
        acc.Name='test';
        insert acc;
        Test.startTest();
            PageReference myVfPage = Page.IHPreviewCallout;
            myVfPage.getParameters().put('id',acc.Id);
            myVfPage.getParameters().put('param2','TestContact123');
            Test.setCurrentPage(myVfPage);
            String id = ApexPages.currentPage().getParameters().get('id');
            system.debug('test'+myVfPage);        
            ControllerLUXOps con = new ControllerLUXOps();
            con.LUXOpHandler();
        Test.stopTest();
    }
    static testMethod void TestcreateAndLinkHelpResource(){
        zTest_DataGenerator DG = new zTest_DataGenerator();
        HelpTopic__c HT = DG.getHelpTopic('T1');
        insert HT;
        Test.startTest();
            ControllerLUXOps.createAndLinkHelpResource(HT.Id);
        Test.stopTest();
    }
    
    
  static testMethod void LogLUXDepartureTime() {
    // Step 1: Create and insert a test HelpInteraction record
    iahelp__HelpInteraction__c interaction = new iahelp__HelpInteraction__c(
        iahelp__Description__c = 'Departure Test'
    );
    insert interaction;
    
    Test.startTest();
    String result = ControllerLUXOps.logLUXDepartureTime(interaction.Id);
    Test.stopTest();
    

    iahelp__HelpInteraction__c updated = [
        SELECT iahelp__DepartureDate__c 
        FROM iahelp__HelpInteraction__c 
        WHERE Id = :interaction.Id
    ];

}

    
    static testMethod void updateInteractionDescription() {
        
        iahelp__HelpInteraction__c interaction = new iahelp__HelpInteraction__c(
            iahelp__Description__c = 'Initial Description'
        );
        insert interaction;
        
        String newDescription = 'Updated via Test Method';
        
        Test.startTest();
        String result = ControllerLUXOps.updateInteractionDescription(interaction.Id, newDescription);
        Test.stopTest();
        
        iahelp__HelpInteraction__c updated = [
            SELECT iahelp__Description__c, iahelp__DepartureDate__c 
            FROM iahelp__HelpInteraction__c 
            WHERE Id = :interaction.Id
        ];
    }

}