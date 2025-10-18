@isTest

/////////////////////////////////////////////////////////////////////////////////////////////////////
// DATA GENERATION ROUTINES FOR USE IN TEST CASES
//
// Martin Little for Improved Apps
// October 2012
/////////////////////////////////////////////////////////////////////////////////////////////////////


global with sharing class zTest_DataGenerator implements HttpCalloutMock{
    
    public boolean isValidJSON (string J) {
        
        boolean retVal;
        
        try {
            //JSON.createParser(J);
            if (J.startsWith('[{"') || J.startsWith('{"')) {
                retVal = true;
            } else {
                retVal = false;             
            }
        } catch (exception e) {
            retVal = false;
        }
        
        return retVal;
    }
    
    public IASetIHOrg__c getTestSettings() {
        
        // Get a unique factor to add to template names
        DateTime dT = DateTime.now();
        String s = dT.year() + '.' + dT.month() + '.' + dT.date() + '.' + dT.hour() + '.' + dT.minute() + '.' + dT.second() + '.' + dT.millisecond();
        
        // Create 1x full and 1x callout template, so we have "good" ids in whatever org
        HelpTopicTemplate__c TF = new HelpTopicTemplate__c();
        TF.DefaultHeight__c = 300;
        TF.Description__c = 'Full Template description';
        TF.PageURL__c = 'TFull_' + s;
        TF.TemplateType__c = 'Full Topic';
        
        insert TF;
        String TFID = TF.Id;
        
        HelpTopicTemplate__c TC = new HelpTopicTemplate__c();
        TC.DefaultHeight__c = 300;
        TC.Description__c = 'Callout Template description';
        TC.PageURL__c = 'TCall_' + s;
        TC.TemplateType__c = 'Callout';
        
        insert TC;
        String TCID = TC.Id;
        
        // Build a string of this Org's key object 3 letter Id codes:
        // This should be in the form:
        // Topic code^Element code^Relationship code^Template code
        HelpTopic__c HT1 = getStubTopic('HT1');
        HT1.CalloutTemplate__c = TCID;
        HT1.Template__c = TFID;
        insert HT1;
        
        HelpTopic__c HT2 = getStubTopic('HT2');
        HT2.CalloutTemplate__c = TCID;
        HT2.Template__c = TFID;
        insert HT2;
        
        HelpedPageLayout__c HPL = this.getHelpedPageLayout('Test Layout', 'zzz');
        insert HPL;
        HelpedElement__c HE = this.getHelpedElement('Test Element', HPL.Id, HT1.Id);
        insert HE;
        
        HelpRelationship__c HR = this.getHelpRelationship(HT1, HT2);

        // Ensure we have a semantic tag for the relationship
        SemanticTag__c ST;
        try {
            ST = [SELECT Id FROM SemanticTag__c WHERE Name = 'Relative'];
        } catch (exception e) {
            ST = getSemanticTag('Relative');
        }
        upsert ST;
        
        HR.SemanticTag__c = ST.Id;
        insert HR;
        
        
        String objIds;
        objIds = ServiceSchema.getObjectIdByName('iahelp__HelpTopic__c') + '^';
        objIds += ServiceSchema.getObjectIdByName('iahelp__HelpReadingList__c') + '^';
        objIds += ServiceSchema.getObjectIdByName('iahelp__HelpResource__c') + '^';
        objIds += ServiceSchema.getObjectIdByName('iahelp__HelpTopicTemplate__c') + '^';
        objIds += ServiceSchema.getObjectIdByName('iahelp__HelpableSignature__c') + '^';
        objIds += ServiceSchema.getObjectIdByName('iahelp__HelpVoteSet__c') + '^';
        objIds += ServiceSchema.getObjectIdByName('iahelp__HelpInteraction__c');

        
        IASetIHOrg__c IASet = new IASetIHOrg__c (
            //UserAdviceMissingTopic__c = 'Err Missing Topic', 
            //UserAdviceMissingTemplate__c = 'Err Missing Template', 
            //UserAdviceMissingElement__c = 'Err Missing Element', 
            //UserAdvicePrintShelfLife__c = 'Warning: Print Warning',
            
            TrackInteractions__c = true, 
            TrackErrors__c = true, 
            TrackDaysTopics__c = 5, 
            TrackDaysErrors__c = 5, 
            TrackDaysComments__c = 5, 
            TrackDaysCallouts__c = 5, 
            TrackDaysResources__c = 5, 
            TrackDaysSearches__c = 5, 
            TrackDaysVotes__c = 5, 
            TrackDaysLUXOps__c = 5, 
            
            AllowLayoutComments__c = true,
            ReviewWithinDays__c = 90, 
            
            QuickTip5__c = 'Link 5', 
            QuickTip4__c = 'Link 4', 
            QuickTip3__c = 'Link 3',
            QuickTip2__c = 'Link 2', 
            QuickTip1__c = 'Link 1', 
            QuickText5__c = 'L5', 
            QuickText4__c = 'L4', 
            QuickText3__c = 'L3', 
            QuickText2__c = 'L2', 
            QuickText1__c = 'L1', 
            QuickLink5__c = 'http://www.bbc.co.uk', 
            QuickLink4__c = 'http://www.bbc.co.uk', 
            QuickLink3__c = 'http://www.bbc.co.uk', 
            QuickLink2__c = 'http://www.bbc.co.uk', 
            QuickLink1__c = 'http://www.bbc.co.uk', 
            
            Name = 'EnabledElements', 
            
            EnableImprovedTableHelp__c = true, 
            EnableImprovedRelatedListHelp__c = true, 
            EnableImprovedPageHelp__c = true, 
            EnableImprovedObjectHelp__c = true, 
            EnableImprovedFieldHelp__c = true, 
            EnableImprovedDetailsHelp__c = true, 
            EnableImprovedButtonHelp__c = true, 
            EnableImprovedLinkHelp__c = true, 
            
            jQNCMode__c = 'true',
            
            RLShowNextPrev__c = true,
            ShowReferringTopics__c = true,
            ShowGuidesLinks__c = '0',
            
            ConsoleResourceLinkTarget__c = '1',
            
            DefaultHelpTopicTemplate__c = TFID, 
            DefaultHelpCalloutTemplate__c = TCID, 
            DefaultGuideTemplate__c = TFID,
            DefaultHelpActiveStatus__c = true, 
            DefaultHelpTopic__c = '',
            DefaultRelationshipSemanticTag__c = HR.SemanticTag__c,
            
            BrandTitle__c = 'Brand Title', 
            BrandSubTitle__c = 'Brand Sub-title', 
            BrandImage__c = 'http://resource/IHResources/img/LogoToolsPage.png',
            BrandCSS__c = 'http://test.css',
            BrandUXOption__c = '1',
            CustomStyles__c = 'CS1,CS2,CS3',
            
            ImageUploadFolder__c = 'ImageUploadFolder',
            
            SFObjectIds__c = objIds,
            SFPod__c = 'na14' 
        );
                
        return IASet;       
    }
    
    public iahelp__NoiseWords__c getNoiseWords(string noise){
        iahelp__NoiseWords__c nw = new iahelp__NoiseWords__c();
        nw.Name = noise;
        return nw;
    }
    public HelpTopic__c getHelpTopic(String TName) {
        HelpedPageLayout__c Hpl = getHelpedPageLayout('test layout','zzz');
        insert Hpl;
        IASetIHOrg__c  stg = getTestSettings();
        HelpTopic__c Hlp = getStubTopic(TName);
        Hlp.Callouttemplate__c = stg.DefaultHelpCalloutTemplate__c;
        Hlp.Template__c = stg.DefaultHelpTopicTemplate__c;
        Hlp.iahelp__GuidedLayout__c = Hpl.Id;        
        
        return Hlp; 
    }
    private HelpTopic__c getStubTopic(String TName) {
        HelpTopic__c Hlp = new HelpTopic__c(
            Name = TName,
            Active__c = true,
            CalloutHeight__c = 50,
            Description__c = 'Help Topic Detail',
            HeightBeforeScrolling__c = 400,
            ImageAltText__c = 'No ALT Text',
            ImageCaption__c = 'Image Caption',
            ImageHeight__c = 60,
            ImageTitle__c = 'Image Title',
            ImageURL__c = '',
            ImageWidth__c = 100,
            CalloutMediaChoice__c = 'Image',
            SalesForceHelpURL__c = '',
            Summary__c = 'Help Topic Summary',
            VideoCaption__c = 'Video Caption',
            VideoHeight__c = 60,
            VideoWidth__c = 100,
            VideoTitle__c = 'Video Title',
            VideoURL__c = ''
        );
        
        return Hlp;         
    }
    

    public HelpReadingList__c getHelpReadingList(String RLName){
        
        HelpReadingList__c RL = new HelpReadingList__c();
        
        RL.ReadingListType__c = 'Linear Guide';
        RL.Active__c = true;
        RL.Name = RLName;
        RL.Description__c = 'Description of ' + RLName;
        RL.Summary__c = 'Summary';
        
        return RL;
    }
    
    
    public HelpReadingListEntry__c getHelpReadingListEntry(String RLID, String HTID) {
        
        HelpReadingListEntry__c RLE = new HelpReadingListEntry__c();
        
        RLE.HelpReadingList__c = RLID;
        RLE.HelpTopic__c = HTID;
        RLE.ReadingOrder__c = 0;
        
        return RLE;
    }


    public HelpedElement__c getHelpedElement(String HEIdentifier, String HelpedPageLayoutId, String HelpTopicId) {
        
        HelpedElement__c HE = new HelpedElement__c();
        
        HE.ElementType__c = 'Field';
        HE.HelpedPageLayout__c = HelpedPageLayoutId;
        HE.HelpTopic__c = HelpTopicId;
        HE.Identifier__c = HEIdentifier;
        HE.Visibility__c = 'All';
        HE.DataDrivenFilter__c = '';
        
        return HE;
    }


    public HelpedPageLayout__c getHelpedPageLayout(String LayoutName, String LayoutIdentifier) {
        
        HelpedPageLayout__c HPL = new HelpedPageLayout__c();
        
        HPL.Name = LayoutName;
        HPL.PageLayoutIdentifier__c = LayoutIdentifier;
        HPL.PageType__c = 'Standard';
        
        return HPL;
    }
    
    public SemanticTag__c getSemanticTag (string STName) {
        
        SemanticTag__c ST = new SemanticTag__c();
        
        ST.Name = STName;
        ST.Tag__c = 'is ' + STName;
        ST.Obverse__c = 'is not ' + STName;
        ST.ShortObverse__c = 'Not ' + STName;
        ST.CollectiveTag__c = STName + 's';
        ST.CollectiveObverse__c = 'Not ' + STName + 's';
        
        return ST;
    }


    public HelpRelationship__c getHelpRelationship(HelpTopic__c ReferringHT, HelpTopic__c RelatedHT) {
        
        HelpRelationship__c HR = new HelpRelationship__c();
        
        // Create a semantic tag if required
        SemanticTag__c ST;
        
        try {
            ST = [SELECT Id, Name, Tag__c, Obverse__c, ShortObverse__c, CollectiveTag__c, CollectiveObverse__c 
                FROM SemanticTag__c 
                WHERE Name = 'Relative'
                LIMIT 1];
        } catch (exception e) {
            ST = getSemanticTag('Relative');
            insert ST;          
        }
        
        HR.ReferringTopic__c = ReferringHT.Id;
        HR.RelatedHelpTopic__c = RelatedHT.Id;
        HR.SemanticTag__c = ST.Id;
        
        HR.ReferringTopic__r = ReferringHT;
        HR.RelatedHelpTopic__r = RelatedHT;
        
        return HR;
    }

    public HelpTopicTemplate__c getHelpTopicTemplate(String TemplateName, String TemplatePageURL){
        
        HelpTopicTemplate__c HT = new HelpTopicTemplate__c();
        
        HT.Name = TemplateName;
        HT.PageURL__c = TemplatePageURL;
        HT.TemplateType__c = 'Full Topic';
        HT.DefaultHeight__c = 55;
        
        return HT;
    }

    public HelpBookmark__c getHelpBookmark(String HTID) {
        
        HelpBookmark__c Bmk = new HelpBookmark__c();
        
        Bmk.HelpTopic__c = HTID;
        Bmk.TopicURL__c = URL.getOrgDomainURL().toExternalForm() + '/apex/IHTools?HTID=' + HTID;
        
        return Bmk;
    }
    
    public HelpResource__c getHelpResource(String RName) {
        
        HelpResource__c HR = new HelpResource__c();
        
        HR.ResourceURL__c = 'http://www.TestResourceLocation.zzz';
        HR.Location__c = 'Test Resource Location';
        HR.Name = RName;
        HR.ResourceType__c = 'Web-page';
        HR.Summary__c = 'Help Resource Summary';
        
        return HR;
    }
    
    public HelpTopicResource__c getHelpTopicResource(HelpResource__c HR, HelpTopic__c HT) {
        
        HelpTopicResource__c HTR = new HelpTopicResource__c();
        
        HTR.HelpResource__c = HR.Id;
        HTR.HelpTopic__c = HT.Id;
        
        HTR.HelpResource__r = HR;
        HTR.HelpTopic__r = HT;
        
        return HTR;
    }
    
    
    public HelpFilter__c getHelpFilter(string FilteredObject, string FilteredObjectIdent, String Logic, String Ident) {
        HelpFilter__c HF = new HelpFilter__c();
        
        HF.FilteredObject__c = FilteredObject;
        HF.FilteredObjectIdentifier__c = FilteredObjectIdent;
        HF.FilterLogic__c = Logic;
        HF.FilterIdentifier__c = Ident;
        
        return HF;
    }
    
    
    public HelpFilterCriterion__c getHelpFilterCriterion(HelpFilter__c HF, Integer FNumber, String FField, String FType, String FOperator, String FValue) {
        HelpFilterCriterion__c HFC = new HelpFilterCriterion__c();
        
        HFC.HelpFilter__c = HF.Id;
        HFC.CriterionNumber__c = FNumber; 
        HFC.FilteredField__c = FField;
        HFC.FilteredFieldType__c = FType;
        HFC.Operator__c = FOperator;
        HFC.FilterValue__c = FValue;
        
        return HFC;
    }
    
 
    public HelpVoteSet__c getHelpVoteSet(string VSName) {
        HelpVoteSet__c HVS = new HelpVoteSet__c();
        HVS.Name = VSName;
        HVS.ImageClass__c = 'VSImage';
        HVS.QuestionText__c = 'Vote Question Text';
        return HVS;
    }
    
    
    public HelpVoteOption__c getHelpVoteOption(string VoteSetId, string Label, integer DisplayOrder) {
        HelpVoteOption__c HVO = new HelpVoteOption__c();
        HVO.HelpVoteSet__c = VoteSetId;
        HVO.OptionLabel__c = Label;
        HVO.DisplayOrder__c = DisplayOrder;
        return HVO;
    }
    
    public ConfigurationItem__c getConfigurationItem(string ToolCxt, string ToolTyp, integer PermLevel) {
        
        ConfigurationItem__c CI = new ConfigurationItem__c();
        
        CI.PermissionLevel__c = PermLevel;
        CI.ToolContext__c = ToolCxt;
        CI.Type__c = ToolTyp;
        
        CI.ActionCode__c = 'act';   
        CI.IconClass__c = 'fa-cog';
        CI.Label__c = 'Tool Label';
        CI.TipText__c = 'Tool tip';
        CI.Description__c = 'Description';  
        CI.DisplayGrouping__c = 'DG1';  
        CI.DisplayOrder__c = 1;
        CI.HasDivider__c = false;
        CI.IconContent__c = '';
        CI.ToolClass__c = '';
        CI.ToolFilter__c = -1;
        CI.ToggleActiveMarker__c = '';
        CI.ToggleNext__c = 0;
        CI.TogglePrev__c = 0;
        CI.SkipImportOverwrite__c = false;
        
        return CI;
    }
    public ConfigurationItem__c getConfigurationItem2(string ToolCxt, string ToolTyp, integer PermLevel) {
        
        ConfigurationItem__c CI = new ConfigurationItem__c();
        
        CI.PermissionLevel__c = PermLevel;
        CI.ToolContext__c = ToolCxt;
        CI.Type__c = ToolTyp;
        
        CI.ActionCode__c = 'GetSFPageLayouts';   
        CI.IconClass__c = 'fa-cog';
        CI.Label__c = 'Tool Label';
        CI.TipText__c = 'Tool tip';
        CI.Description__c = 'Description';  
        CI.DisplayGrouping__c = 'DG1';  
        CI.DisplayOrder__c = 1;
        CI.HasDivider__c = false;
        CI.IconContent__c = '';
        CI.ToolClass__c = '';
        CI.ToolFilter__c = -1;
        CI.ToggleActiveMarker__c = '';
        CI.ToggleNext__c = 0;
        CI.TogglePrev__c = 0;
        CI.SkipImportOverwrite__c = false;
        
        return CI;
    }
    public ConfigurationItem__c getConfigurationItem3() {
        
        ConfigurationItem__c CI = new ConfigurationItem__c();
        
        CI.Type__c = 'ConfigurationData';      
        CI.ActionCode__c = 'GetWhitelistedDomains';   
        CI.SupportingControls__c = 'com,com2';       
        CI.SkipImportOverwrite__c = false;
        CI.IconClass__c = 'fa-cog';
        CI.Label__c = 'Tool Label';
        CI.TipText__c = 'Tool tip';
        CI.Description__c = 'Description';        
        
        return CI;
    }

    public Document getConfigurationJSONDoc() {

        // Document to return
        Document d = new Document();
            
        // JSON to embed in the doc
        string theJSON;
        ConfigurationItem__c CI = getConfigurationItem('TextCxt', 'Ellipsis', 1);
        theJSON = JSON.serialize(CI);
        
        Folder Fld = [SELECT Id FROM Folder WHERE Name='Improved Help Documents'];
                                
        d.FolderId = Fld.Id;
        d.Name = 'TestConfigJSON';
        
        // Now we need to complete the details of the Subscription and place these (encrypted) in the body
        d.Body = Blob.valueOf(theJSON);
        
        return d;
        
    }

    
    public Document getSubscriptionDoc() {
        
        // Document to return
        Document d = new Document();
        
        // Org Id to use in Subscription
        String OrgId = UserInfo.getOrganizationId().substring(0, 15);

        // Unencrypted version of our Subscriptoin
        String SubsText = '000000^2099^2^6^' + OrgId + '^Full^-1^Improved Help';                                
        
        // We need to associate this doc with our Improved Help folder:
        // The Subscription service "knows" where this is - we make a call here to ensure
        // this folder is set - so we can use it  even if the actual call to get a Subscription will fail...
        ServiceSubs.getLicenseInfo('Improved Help Documents', 'zzz');
                        
        d.FolderId = ServiceSubs.LicenseFolderId;
        d.Name = OrgId;
        
        // Now we need to complete the details of the Subscription and place these (encrypted) in the body
        d.Body = Encrypt(SubsText);
        
        return d;
    }
    
    
    public zTest_DataGenerator() {
        // Need to create an App settings (secrets) object here, so its PKS 
        // element can get populated with default (encryption secret) value
        
        IHAppSettings__c IHAS = IHAppSettings__c.getOrgDefaults(); 
        
        if (IHAS.PKS__c == null) {
            IHAS = new IHAppSettings__c();
            IHAS.SetupOwnerId = Userinfo.getOrganizationId();
            insert IHAS;
        }
        
    }
    
    
    // Our private key
    // NB: THIS MUST BE KEPT IN LINE WITH THE ONE USED BY ServiceSubs - HERE AND IN IMPROVED HELP!
    private static final String PKS = 'VFFMUYJHIzxMAR5XbwPAMqxVJlPodl6IHSDGoMO1ojw';
    private Blob Encrypt(String Input) {
         
         Blob retVal;
                         
         try {
             // We use our hard coded private encryption key member data to encrypt and decrypt
             Blob PK = EncodingUtil.base64Decode(PKS);
             retVal = Crypto.encryptWithManagedIV('AES256', PK, Blob.valueOf(Input));
                    
         } catch (Exception e) {
            //Diags +=  'Encryption error: ' + e.getMessage() + '... ';
         }
         
         return retVal;
    }
    
    
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
        // Optionally, only send a mock response for a specific endpoint
        // and method.
        String baseURL = URL.getOrgDomainURL().toExternalForm();
        string query='SELECT id, url from weblink';
        string url=baseURL + '/services/data/' + 'v53.0' + '/tooling/query?q='+ (query.replace(' ', '+'));
     //   System.assertEquals(url, req.getEndpoint());
    //    System.assertEquals('GET', req.getMethod());
        
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"size":1063,"totalSize":1063,"done":false,"nextRecordsUrl":"/services/data/v53.0/tooling/query/01g4R00009nCjfoQAC-200","queryLocator":"01g4R00009nCjfoQAC-200","entityTypeName":"WebLink","records":[{"attributes":{"type":"WebLink","url":"/services/data/v53.0/tooling/sobjects/WebLink/00b4R0000028rRMQAY"},"Id":"00b4R0000028rRMQAY","Url":null},{"Url":"http://www.google.com","Id":"00b6T000001uSvZQAU","attributes":{"url":"/services/data/v53.0/tooling/sobjects/WebLink/00b6T000001uSvZQAU","type":"WebLink"}}]}');
           
        res.setStatusCode(200);
        return res;
    }
    
    global HTTPResponse getAllProfileLayoutrespond() {
        
         // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"size":3315,"totalSize":3315,"done":false,"nextRecordsUrl":"/services/data/v53.0/tooling/query/01g6T0000BA8cArQQJ-2000","queryLocator":"01g6T0000BA8cArQQJ-2000","entityTypeName":"ProfileLayout","records":[{"attributes":{"type":"ProfileLayout","url":"/services/data/v53.0/tooling/sobjects/ProfileLayout/01Gd000000Y481MEAR"},"LayoutId":""}]}');
        
        res.setStatusCode(200);
        return res;
    }
    

}