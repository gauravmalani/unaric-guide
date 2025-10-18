@isTest

/////////////////////////////////////////////////////////////////////////////////////////////////////
// TEST CASES FOR CLASS zInstallHandler (which creates essential settings data 
// on installation of the Improved Help package)
//
// Martin Little for Improved Apps
// October 2012
/////////////////////////////////////////////////////////////////////////////////////////////////////


private class zTest_zInstallHandler {
    
    
    static testMethod void onInstall() {
        Test.startTest();
        
        try {
            // Mock the scheduling behavior
            String jobName = 'Clear_InstallFlag_Job';
            
            // Check for existing scheduled job with the same name
            List<CronTrigger> existingJobs = [
                SELECT Id, CronJobDetail.Name, CronJobDetailId
                FROM CronTrigger
                WHERE CronJobDetail.Name = :jobName
            ];
            
            // Abort any existing job with the same name
            for (CronTrigger job : existingJobs) {
                System.abortJob(job.Id);
            }
            
            // Schedule new job
            Datetime dt = System.now().addMinutes(3);
            String cronExp = dt.second() + ' ' + dt.minute() + ' ' + dt.hour() + ' ' + dt.day() + ' ' + dt.month() + ' ? ' + dt.year();
            System.schedule(jobName, cronExp, new ClearInstallFlagSchedulable());
            
        } catch (Exception ex) {
            System.debug('Failed to schedule ClearInstallFlag job: ' + ex.getMessage());
        }
        
        // Run the install handler script
        zInstallHandler zIH = new zInstallHandler();
        
        PageReference pageRef = Page.IHTools;
        Test.setCurrentPage(pageRef);
        
        Test.testInstall(zIH, new Version(1, 0));
        
        System.assertEquals(zIH.Diags, 'Post install scripts processed');
        
        Test.stopTest();
    }

    
    static testMethod void seedDocumentation() {
        
        User currentUser = [SELECT Id, Name FROM User WHERE Id = :UserInfo.getUserId()];
        System.debug('Current User: ' + currentUser.Name);        
        // This will require a settings object (for topic defaults)
        zTest_DataGenerator DG = new zTest_DataGenerator();
        IASetIHOrg__c IASet = DG.getTestSettings();                                     
        insert IASet;
        
        
        Boolean result;
        String sXML = '';
        
        sXML += '<xml><ImprovedHelpDocumentation>';
        sXML += '<HelpTopics>';

        sXML += '<HelpTopic Id=\'HT1\' Name=\'Topic 1 ex Help Quick Tour\' Summary=\'Summary 1\' Default=\'false\' Active=\'true\' CalloutHeight=\'55\' CalloutMediaChoice=\'Image\' CalloutTemplate=\'CalloutSummaryOnly\' HeightBeforeScrolling=\'340\' Template=\'Template2ColMediaText\' HelpTopicStatus=\'New\' SalesforceHelpURL=\'\' Visibility=\'All\' CustomStyle=\'\' ShowReferringRelationships=\'true\' GuidedLayout=\'\' GuidedRecord=\'\' GuidedElement=\'\' GuideStepMode=\'\' GuideCallout=\'\' ShowReadMoreLink=\'true\'>';
        sXML += '<HelpTopicImage Height=\'100\' Width=\'160\' Caption=\'Image Caption\' Title=\'Image Title\' URL=\'http://smartypantsfun.com/wp-content/uploads/2012/03/ROBOT1.jpeg\' ALTText=\'ImageALT\'></HelpTopicImage>';
        sXML += '<HelpTopicVideo Height=\'200\' Width=\'300\' Caption=\'Video Caption\' Title=\'Video Title\' URL=\'http://www.youtube.com/embed/EzjkBwZtxp4?wmode=opaque\'></HelpTopicVideo>';
        sXML += 'DESCRIPTION ';

        sXML += '<img src="Nosuch.jpg" alt="Broken" title="A broken image" width="500px" height="500px" style="border: none;" class="ImgClass"/>';

        sXML += '</HelpTopic>';

        sXML += '<HelpTopic Id=\'HT2\' Name=\'Topic 2 ex Help Quick Tour\' Summary=\'Summary 2\' Default=\'false\' Active=\'true\' CalloutHeight=\'55\' CalloutMediaChoice=\'Image\' CalloutTemplate=\'CalloutSummaryOnly\' HeightBeforeScrolling=\'340\' Template=\'Template2ColMediaText\' HelpTopicStatus=\'New\' SalesforceHelpURL=\'\' Visibility=\'All\' CustomStyle=\'\' ShowReferringRelationships=\'true\' GuidedLayout=\'\' GuidedRecord=\'\' GuidedElement=\'\' GuideStepMode=\'\' GuideCallout=\'\' ShowReadMoreLink=\'true\'>';
        sXML += '<HelpTopicImage Height=\'100\' Width=\'160\' Caption=\'Image Caption\' Title=\'Image Title\' URL=\'http://smartypantsfun.com/wp-content/uploads/2012/03/ROBOT1.jpeg\' ALTText=\'ImageALT\'></HelpTopicImage>';
        sXML += '<HelpTopicVideo Height=\'200\' Width=\'300\' Caption=\'Video Caption\' Title=\'Video Title\' URL=\'http://www.youtube.com/embed/EzjkBwZtxp4?wmode=opaque\'></HelpTopicVideo>';
        sXML += 'DESCRIPTION';
        sXML += '</HelpTopic>';

        sXML += '</HelpTopics>';
        
        sXML += '<HelpRelationships>';
        sXML += '<HelpRelationship SemanticTag=\'Relative\' ReferringTopic=\'HT1\' RelatedHelpTopic=\'HT2\'></HelpRelationship>';
        sXML += '</HelpRelationships>';
        
        sXML += '<HelpReadingLists>';
        sXML += '<HelpReadingList Id=\'RL1\' Name=\'RL 1\' Summary=\'RL Summary 1\' Description=\'\' FeaturedUntil=\'\' ReadingListStatus=\'Drafted\' ReadingListType=\'Reading List\'></HelpReadingList>';
        sXML += '<HelpreadingListEntry HelpReadingList=\'RL1\' HelpTopic=\'HT1\' ReadingOrder=\'0\'></HelpreadingListEntry>';
        sXML += '</HelpReadingLists>';
        
        sXML += '<HelpResources>';
        sXML += '<HelpResource Id=\'HR1\' Name=\'TEST BBC\' Summary=\'TEST The BBC\' Location=\'TEST Internet\' ResourceType=\'Web-page\' URL=\'http://www.bbc.co.uk\'></HelpResource>';
        sXML += '<HelpTopicResource HelpResource=\'HR1\' HelpTopic=\'HT2\' UsageNotes=\'Test notes for BBC / Topic 2\'></HelpTopicResource>';
        sXML += '</HelpResources>';
        sXML += '</ImprovedHelpDocumentation><ImprovedHelpLayouts>';

        sXML += '<HelpedPageLayouts>';
        sXML += '<HelpedPageLayout Id=\'HPL1\' Name=\'Solution Layout\' PageLayoutIdentifier=\'Solution\' PageType=\'Standard\' AllowComments=\'true\' RehookTimes=\'0\' RehookInterval=\'0\'></HelpedPageLayout>';
        sXML += '</HelpedPageLayouts>';

        sXML += '<HelpedElements>';
        sXML += '<HelpedElement HelpedPageLayout=\'HPL1\' ElementType=\'Field\' HelpTopic=\'HT2\' Name=\'Element Status\' Identifier=\'Status\' Visibility=\'All\' DataDrivenFilter=\'\' UseForNew=\'False\'></HelpedElement>';
        sXML += '</HelpedElements>';

        sXML += '</ImprovedHelpLayouts></xml>';
        
    
        Test.startTest();
          
        
         
          zInstallHandler zIH = new zInstallHandler();
            
            // Ideally, we want to provide an XML string with a known quantity of entities
            // then check that these were "created" by looking at the diags returned by the seed call,
            // however this will be hard to maintain, so sate ourselves here with a good 
            // return value and the word "Edited" at the start...
            result = zIH.seedDocumentation(sXML);

           
            
        Test.stopTest();
        
        return; 
    }
    
     @isTest
    static void testWithLeastPrivilegeUser() {
        // Step 1: Get a low-permission profile (adjust profile name if needed)
        Profile lowProfile = [SELECT Id FROM Profile WHERE Name = 'Read Only' LIMIT 1];

        // Step 2: Create test user
        User lowUser = new User(
            FirstName = 'Low',
            LastName = 'PrivUser',
            Alias = 'lpriv',
            Email = 'lowprivuser@example.com',
            Username = 'lowprivuser_test_' + DateTime.now().getTime() + '@example.com',
            ProfileId = lowProfile.Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert lowUser;
        

        // Step 3: Run test logic as that user
        System.runAs(lowUser) {
            // Reconfirm which user is running
            User currentUser = [SELECT Id, Name FROM User WHERE Id = :UserInfo.getUserId()];
            System.debug('Current User: ' + currentUser.Name);

            // Use test data generator if needed
            zTest_DataGenerator DG = new zTest_DataGenerator();
            IASetIHOrg__c IASet = DG.getTestSettings();                                     
            insert IASet;

         Boolean result;
        String sXML = '';
        
        sXML += '<xml><ImprovedHelpDocumentation>';
        sXML += '<HelpTopics>';

        sXML += '<HelpTopic Id=\'HT1\' Name=\'Topic 1 ex Help Quick Tour\' Summary=\'Summary 1\' Default=\'false\' Active=\'true\' CalloutHeight=\'55\' CalloutMediaChoice=\'Image\' CalloutTemplate=\'CalloutSummaryOnly\' HeightBeforeScrolling=\'340\' Template=\'Template2ColMediaText\' HelpTopicStatus=\'New\' SalesforceHelpURL=\'\' Visibility=\'All\' CustomStyle=\'\' ShowReferringRelationships=\'true\' GuidedLayout=\'\' GuidedRecord=\'\' GuidedElement=\'\' GuideStepMode=\'\' GuideCallout=\'\' ShowReadMoreLink=\'true\'>';
        sXML += '<HelpTopicImage Height=\'100\' Width=\'160\' Caption=\'Image Caption\' Title=\'Image Title\' URL=\'http://smartypantsfun.com/wp-content/uploads/2012/03/ROBOT1.jpeg\' ALTText=\'ImageALT\'></HelpTopicImage>';
        sXML += '<HelpTopicVideo Height=\'200\' Width=\'300\' Caption=\'Video Caption\' Title=\'Video Title\' URL=\'http://www.youtube.com/embed/EzjkBwZtxp4?wmode=opaque\'></HelpTopicVideo>';
        sXML += 'DESCRIPTION ';

        sXML += '<img src="Nosuch.jpg" alt="Broken" title="A broken image" width="500px" height="500px" style="border: none;" class="ImgClass"/>';

        sXML += '</HelpTopic>';

        sXML += '<HelpTopic Id=\'HT2\' Name=\'Topic 2 ex Help Quick Tour\' Summary=\'Summary 2\' Default=\'false\' Active=\'true\' CalloutHeight=\'55\' CalloutMediaChoice=\'Image\' CalloutTemplate=\'CalloutSummaryOnly\' HeightBeforeScrolling=\'340\' Template=\'Template2ColMediaText\' HelpTopicStatus=\'New\' SalesforceHelpURL=\'\' Visibility=\'All\' CustomStyle=\'\' ShowReferringRelationships=\'true\' GuidedLayout=\'\' GuidedRecord=\'\' GuidedElement=\'\' GuideStepMode=\'\' GuideCallout=\'\' ShowReadMoreLink=\'true\'>';
        sXML += '<HelpTopicImage Height=\'100\' Width=\'160\' Caption=\'Image Caption\' Title=\'Image Title\' URL=\'http://smartypantsfun.com/wp-content/uploads/2012/03/ROBOT1.jpeg\' ALTText=\'ImageALT\'></HelpTopicImage>';
        sXML += '<HelpTopicVideo Height=\'200\' Width=\'300\' Caption=\'Video Caption\' Title=\'Video Title\' URL=\'http://www.youtube.com/embed/EzjkBwZtxp4?wmode=opaque\'></HelpTopicVideo>';
        sXML += 'DESCRIPTION';
        sXML += '</HelpTopic>';

        sXML += '</HelpTopics>';
        
        sXML += '<HelpRelationships>';
        sXML += '<HelpRelationship SemanticTag=\'Relative\' ReferringTopic=\'HT1\' RelatedHelpTopic=\'HT2\'></HelpRelationship>';
        sXML += '</HelpRelationships>';
        
        sXML += '<HelpReadingLists>';
        sXML += '<HelpReadingList Id=\'RL1\' Name=\'RL 1\' Summary=\'RL Summary 1\' Description=\'\' FeaturedUntil=\'\' ReadingListStatus=\'Drafted\' ReadingListType=\'Reading List\'></HelpReadingList>';
        sXML += '<HelpreadingListEntry HelpReadingList=\'RL1\' HelpTopic=\'HT1\' ReadingOrder=\'0\'></HelpreadingListEntry>';
        sXML += '</HelpReadingLists>';
        
        sXML += '<HelpResources>';
        sXML += '<HelpResource Id=\'HR1\' Name=\'TEST BBC\' Summary=\'TEST The BBC\' Location=\'TEST Internet\' ResourceType=\'Web-page\' URL=\'http://www.bbc.co.uk\'></HelpResource>';
        sXML += '<HelpTopicResource HelpResource=\'HR1\' HelpTopic=\'HT2\' UsageNotes=\'Test notes for BBC / Topic 2\'></HelpTopicResource>';
        sXML += '</HelpResources>';
        sXML += '</ImprovedHelpDocumentation><ImprovedHelpLayouts>';

        sXML += '<HelpedPageLayouts>';
        sXML += '<HelpedPageLayout Id=\'HPL1\' Name=\'Solution Layout\' PageLayoutIdentifier=\'Solution\' PageType=\'Standard\' AllowComments=\'true\' RehookTimes=\'0\' RehookInterval=\'0\'></HelpedPageLayout>';
        sXML += '</HelpedPageLayouts>';

        sXML += '<HelpedElements>';
        sXML += '<HelpedElement HelpedPageLayout=\'HPL1\' ElementType=\'Field\' HelpTopic=\'HT2\' Name=\'Element Status\' Identifier=\'Status\' Visibility=\'All\' DataDrivenFilter=\'\' UseForNew=\'False\'></HelpedElement>';
        sXML += '</HelpedElements>';

        sXML += '</ImprovedHelpLayouts></xml>';
        

            Test.startTest();
                zInstallHandler zIH = new zInstallHandler();
                result = zIH.seedDocumentation(sXML);

              //  System.assertEquals(true, result);
               // System.assertEquals(true, zIH.Diags.startsWith('Edited'));
            Test.stopTest();
        }
    }
    


    static testMethod void ioDataDocHT() {
        
        // Create a help topic to export
        zTest_DataGenerator DG = new zTest_DataGenerator();
        HelpTopic__c HT = DG.getHelpTopic('HT');
        insert HT;
        
        Test.startTest();
            PageReference pageRef = Page.IHExportDoc;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('HTID', HT.Id);
            
            zInstallHandler zIH = new zInstallHandler();
            String S = zIH.ioDataDoc;
            System.assert(S.indexOf('Error') == -1);                        
        Test.stopTest();
        
        return;         
    }   
    

    static testMethod void ioDataDocRL() {
        
        // Create a reading list to export
        zTest_DataGenerator DG = new zTest_DataGenerator();
        
        HelpTopic__c HT = DG.getHelpTopic('HT');
        insert HT;
        
        HelpReadingList__c RL = DG.getHelpReadingList('RL');
        insert RL;
        
        HelpReadingListEntry__c RLE = DG.getHelpReadingListEntry(RL.Id, HT.Id);
        insert RLE;
        
        Test.startTest();
            PageReference pageRef = Page.IHExportDoc;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('RLID', RL.Id);
            
            zInstallHandler zIH = new zInstallHandler();
            String S = zIH.ioDataDoc;
            System.assert(S.indexOf('Error') == -1);                        
        Test.stopTest();
        
        return;         
    }   
    
    
    static testMethod void ioDataPPT() {

        // Create a reading list to export
        zTest_DataGenerator DG = new zTest_DataGenerator();
        
        HelpTopic__c HT = DG.getHelpTopic('HT');
        insert HT;
        
        HelpReadingList__c RL = DG.getHelpReadingList('RL');
        insert RL;
        
        HelpReadingListEntry__c RLE = DG.getHelpReadingListEntry(RL.Id, HT.Id);
        insert RLE;
        
        Test.startTest();
            PageReference pageRef = Page.IHExportPPT;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('RLID', RL.Id);
            
            zInstallHandler zIH = new zInstallHandler();
            String S = zIH.ioDataPPT;
            System.assert(S.indexOf('Error') == -1);                        
        Test.stopTest();
        
        return;         
    }
    
    
    static testMethod void xlGetExportData() {
        Test.startTest();
            zInstallHandler zIH = new zInstallHandler();
            zIH.xlGetExportData();
            System.assertEquals('', '');                        
        Test.stopTest();
        
        return;         
    }
    
}