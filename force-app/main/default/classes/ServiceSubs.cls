/////////////////////////////////////////////////////////////////////////////////////////////////////
// CLASS FOR CHECKING THAT VALID IMPROVED HELP SUBSCRIPTION IS IN PLACE
//
// Martin Little for Improved Apps
// January 2013
/////////////////////////////////////////////////////////////////////////////////////////////////////


public with sharing class ServiceSubs {

    // Positions of the various attributes of the Subscription within the array of info retrieved
    private static final Integer idxLicenseNumber = 0;
    private static final Integer idxExpiryY = 1;
    private static final Integer idxExpiryM = 2;
    private static final Integer idxExpiryD = 3;
    private static final Integer idxOrgId = 4;
    private static final Integer idxLicenseType = 5;
    private static final Integer idxNumSeats = 6;
    private static final Integer idxProduct = 7;

    // The Improved Apps private key
    // NB: THIS MUST BE KEPT IN LINE WITH THE ONE USED BY THE SUBSCRIPTION MANAGEMENT SERVICE!  
    // Check the default value for the PKS setting and ensure that this is so!
    private static string PKS() {
        
        // As a hierarchic setting, the following works in development & unit tests, but fails 
        // when deployed via package with "null" returned
        //IHAppSettings__c IHAS = IHAppSettings__c.getOrgDefaults();
        //return IHAS.PKS__c;
        
        // Attempted setting as a "list" type, requiring an instance row, but this also fails: cannot ship
        // any default row and attempt to create one in destination org returns a "DML not allowed" flavour error
        return 'VFFMUYJHIzxMAR5XbwPAMqxVJlPodl6IHSDGoMO1ojw';       
    }

    public enum KnownLicenseStatusCodes {
        Unknown,            
        OK,                 
        Expired,
        InvalidOrg,
        InsufficientUsers,
        Error
    }

    // The "Improved Help" docs folder (Id of the same)
    public static String LicenseFolderId {get; set;}

    public static String Diags {get; set;}                          // Diagnostics text


/////////////////////////////////////////////////////////////////////////////////////////////////////
// Class embodying the key attributes of an Improved Help Subscription
/////////////////////////////////////////////////////////////////////////////////////////////////////

    Public Class LicenseInfo {
        
        public String LicenseNumber {get; set;}                 //
        public Date ExpiryDate {get; set;}                      //
        public String ExpiryDateString {get; set;}              // Expiry date as formatted string
        public String OrgId {get; set;}                         //
        public String OrganisationName {get; set;}              // Obtained via current user info
        public String Product {get; set;}
        public String LicenseType {get; set;}                   //
        public String NumSeats {get; set;}                      // +ve Integer - or "-1" for unlimited
        public String Status {get; set;}                        // Calculated license diags based on above
        public KnownLicenseStatusCodes StatusCode {get; set;}   // Calculated based on the above
        public String LicenseDocumentLink {get; set;}           // Link to the license record in docs fldr.
        
        
        // Constructor populates fields with "safe" defaults
        public LicenseInfo() {
            
            this.LicenseNumber = '000000';
            
            // Expired in the past by default
            Date dat = Date.today();
            this.ExpiryDate = Date.newInstance(dat.year() + 1, dat.month(), dat.day());
            this.ExpiryDateString = this.ExpiryDate.format();
            
            // The Improved Apps Org Id
            this.OrgId = '[Not Set]';
            this.OrganisationName = 'Unknown';
            
            this.Product = 'TBA';
            this.LicenseType = 'Full';
            this.NumSeats = '0';
            
            this.Status = 'Subscription Initialised... ';
            this.StatusCode = KnownLicenseStatusCodes.Unknown;
            
            LicenseDocumentLink = '#';
        
        }
                
    }
    
/////////////////////////////////////////////////////////////////////////////////////////////////////
// Subs Service public interface
/////////////////////////////////////////////////////////////////////////////////////////////////////
    
    // Interface allowing clients to obtain Subscription information
    public Static LicenseInfo getLicenseInfo(String ProductName, String LicenseDocumentName) {
        
        LicenseInfo LI;         // Subscription info to return
        Blob eBlob;             // Subscription content in encrypted form
        String dFileText = '';  // Decrypted version of the same
        String[] LInfo;         // Array of values split from decrypted text
        
        // For localised error messages (finalised Status values only)
        map<string,string> mapDlgLocs = ServiceLocalisation.getDialogueLocalisations('ServiceSubs', false); 
        
        try {
            LI = new LicenseInfo();
            
            Diags = '';
            
            /*
            // Retrieve contents of Subscription file:
            // NB: if no Subscription file name specified, use Organisation Id (15 char version)
            if (LicenseDocumentName == '' || LicenseDocumentName == null) {LicenseDocumentName = UserInfo.getOrganizationId().substring(0, 15);}
            eBlob = getFileContents(ProductName, LicenseDocumentName, LI);
            if (Diags != '') {
                
                // 1.24.4
                // If the file cannot be found or, for whatever reason (e.g., permissioning in Communities) read, 
                // attempt to locate the required content via (failover) static resource...
                LI.Status += 'Subscription file could not be located - attempting to locate information in static resource... ';
                
                try {
                    StaticResource sr = [SELECT Id, Body FROM StaticResource WHERE Name = 'ImprovedHelpSubscriptionDocument' LIMIT 1];      
                    eBlob = sr.Body;
                    
                } catch (exception ex) {
                    LI.Status = mapDlgLocs.get('ValueSubscriptionUnreadable') + ' - ' + Diags;
                    LI.StatusCode = KnownLicenseStatusCodes.Error;                              
                    return LI;                  
                }               
                
            } else {
                LI.Status += 'Subscription file located and read... ';
            }
            
            
            // Decrypt file contents
            dFileText = Decrypt(eBlob);
            if (dFileText == 'ERROR') {
                LI.Status = mapDlgLocs.get('ValueSubscriptionDecryptionError') + ': ' + Diags;
                LI.StatusCode = KnownLicenseStatusCodes.Error;                              
                return LI;              
            }           
            LI.Status += 'Content decrypted... ';

            
            // Populate member data         
            LInfo = dFileText.split('\\^');         
            LI.Status += 'Subscription has been split into ' + LInfo.size() + ' components... ';
            
            LI.LicenseNumber = LInfo[idxLicenseNumber];
            LI.ExpiryDate = Date.newInstance(integer.valueof(LInfo[idxExpiryY]), integer.valueof(LInfo[idxExpiryM]), integer.valueof(LInfo[idxExpiryD]));
            LI.ExpiryDateString = LI.ExpiryDate.format();
            LI.LicenseType = LInfo[idxLicenseType];
            
            // Legacy support: we can only provide product info if this is in the Subscription file...
            if (LInfo.size() > idxProduct) {
                LI.Product = LInfo[idxProduct];             
            }
            
            LI.OrgId = LInfo[idxOrgId];
            
            // NB: "-1" seats = unlimited
            if (LInfo[idxNumSeats] == '-1') {
                LI.NumSeats = 'Unlimited';
            } else {
                LI.NumSeats = LInfo[idxNumSeats];               
            }
            

            // Run checks on the validity of this info:
            // Is the Subscription in date?
            Date dat = Date.today();
            if (LI.ExpiryDate <= dat) {
                LI.Status = mapDlgLocs.get('ValueSubscriptionExpired');
                LI.StatusCode = KnownLicenseStatusCodes.Expired;                
                return LI;  
            }
            LI.Status += 'Subscription is in date... ';
                                

            // Is Subscription for the "right" Org? We take right to mean the 
            // Org of the current user...
            // NB: the 15 or 18 character Org Id may have been used...
            if (LI.OrgId != UserInfo.getOrganizationId() && LI.OrgId != UserInfo.getOrganizationId().substring(0, 15)) {
                LI.Status = mapDlgLocs.get('ValueSubscriptionForWrongOrg') + ' (' + UserInfo.getOrganizationId() + ' - ' + UserInfo.getOrganizationName() + ')';
                LI.StatusCode = KnownLicenseStatusCodes.InvalidOrg;              
                
                // Re-set Org Id to a safe value - we don't want to give out what could potentially be 
                // someone else's ID
                LI.OrgId = '';
                LI.OrganisationName = 'Invalid';
                return LI;
                
            } else {
                LI.Status += 'Subscription is for the current Org... ';
                            
                // Org Name can be noted safely at this stage
                LI.OrganisationName = UserInfo.getOrganizationName();
            }
            
            
            // Does the number of users cover the subscriptions in use?
            if (LI.NumSeats != 'Unlimited') {
                
                // Get the number of Subscriptions in use
                integer numUsed = getNumSubscribedUsers();
                
                if (numUsed > integer.valueOf(LI.NumSeats)) {
                    LI.Status = mapDlgLocs.get('ValueSubscriptionSeatsExceeded') + ' {' + LI.NumSeats + ' - ' + numUsed + ' = -' + ((integer.valueOf(LI.NumSeats) - numUsed) * -1) + '}';
                    LI.StatusCode = KnownLicenseStatusCodes.InsufficientUsers;
                    return LI;
                }
            }
            
            
            // Is Subscription for the correct product?
            */
            
            // 1.28.1 - As of Security Review, subscription file is not (for the time being) required:
            // Set some advice messages into the license...
            LI.OrgId = '';
            LI.LicenseNumber = mapDlgLocs.get('ValueSubscriptionNotApplicable');
            LI.ExpiryDateString = mapDlgLocs.get('ValueSubscriptionNotApplicable');
            LI.OrganisationName = mapDlgLocs.get('ValueSubscriptionNotApplicable');
            LI.Product = mapDlgLocs.get('ValueSubscriptionNotApplicable');
            LI.LicenseType = mapDlgLocs.get('ValueSubscriptionNotApplicable');
            LI.NumSeats = 'Unlimited';
            
                        
            // Here we can reset our diags (Status) to OK
            LI.Status = mapDlgLocs.get('ValueSubscriptionOK');
            LI.StatusCode = KnownLicenseStatusCodes.OK;
                                    
            
        } catch (exception e) {
            LI.Status += mapDlgLocs.get('ValueSubscriptionGenericError') + ' - ' + e.getMessage();
            LI.StatusCode = KnownLicenseStatusCodes.Error;          
        }
        
        return LI;
    }
    
    
/////////////////////////////////////////////////////////////////////////////////////////////////////
// Private utility functions
/////////////////////////////////////////////////////////////////////////////////////////////////////
    

// 1.28.1: Not required for the time being (see neutered public interface, above)

/*  
    // File contents reading utility
    private static Blob getFileContents(String ProductName, String DocName, LicenseInfo LI) {
        
        Blob retVal;
        
        try {
            
            // Obtain and store details of the Improved Help Document folder
            Folder Fld = [SELECT Id FROM Folder WHERE Name=:ProductName];
            LicenseFolderId = Fld.Id;
            Diags += 'Subscription folder located... ';
            
            // Use this when locating the Subscription file
            Document Doc = [SELECT Id, Body FROM Document WHERE Name=:DocName AND FolderId=:Fld.Id];
            retVal = doc.Body;
            
            // If we found the document, we can build a link to it
            // Use community path, if relevant
            String RootUrl = ControllerSettings.getCommunityRoot();
            if (RootUrl == '') {
                RootUrl = URL.getSalesforceBaseUrl().toExternalForm();
            }           
            LI.LicenseDocumentLink = RootUrl + '/' + Doc.Id;
            
            Diags = '';
            
        } catch (exception e) {
            Diags +=  'Error getting Subscription file "' + DocName + '": ' + e.getMessage() + '... ';
        }
        
        return retVal;
        
    }
    
    
    // Returns the number of IH Subscriptions in use
    private static integer getNumSubscribedUsers() {
        integer i;
        
        try {
            // This comes from a number recorded by trigger on user updates in global settings
            i = (integer) ControllerSettings.getSettings().AllocatedSeats__c;
            
        } catch (exception e) {
            // Fail "safe"
            i = 99999999;
        }
        
        return i;
    }
    
    
    // Decryption utility
    private static String Decrypt(Blob Input) {
        
         String retVal;
         Blob bVal;      
                 
         try {
             String secret = PKS();

             // We use our hard coded private encryption key member data to encrypt and decrypt
             Blob PK = EncodingUtil.base64Decode(secret);           
             bVal = Crypto.decryptWithManagedIV('AES256', PK, Input);
             retVal = bVal.toString();
             
            Diags = '';
                    
         } catch (Exception e) {
            Diags +=  'Decryption error: ' + e.getMessage() + '... ';
            retVal = 'ERROR';
         }
         
         return retVal; 
    }
*/

    // Read boolean feature parameter
    public static boolean getFPBValue(string featureParameterName){
        try {
            boolean featureParameterValue = System.FeatureManagement.checkPackageBooleanValue(featureParameterName);
            return featureParameterValue;
            
        } catch(exception e){
             return null;
        }
    }


    // Read / write date feature parameter
    public static date getFPDValue(string featureParameterName){
        try {
            date featureParameterValue = System.FeatureManagement.checkPackageDateValue(featureParameterName);
            return featureParameterValue;
            
        } catch(exception e){
             return null;
        }
    }
    public static boolean setFPDValue(string featureParameterName, date value){
        try {
            System.FeatureManagement.setPackageDateValue(featureParameterName, value);
            return true;
            
        } catch(exception e){
            return false;
        }
    }


    // Read / write integer feature parameter
    public static integer getFPIValue(string featureParameterName){
        try {
            integer featureParameterValue = System.FeatureManagement.checkPackageIntegerValue(featureParameterName);
            return featureParameterValue;
            
        } catch(exception e){
             return -1;
        }
    }
    public static boolean setFPIValue(string featureParameterName, integer value){
        try {
            System.FeatureManagement.setPackageIntegerValue(featureParameterName, value);
            return true;
            
        } catch(exception e){
            return false;
        }
    }
    
    
    // Wrapper function to record the key stats we wish to track regarding customer use of our product
    // NB: this has to be an asynchronous method in order to work inside (eg) triggers
    @future
    public static void recordOrgMetrics() {

        try {
            AggregateResult[] AR;
            integer totalTrackedInteractions = 0;
            date orgMetricsLastLogged = ServiceSubs.getFPDValue('dS2LMetricsLogged');
            datetime H24Ago = Datetime.now().addDays(-1);
            
            
            AR = [SELECT COUNT(Id) CT FROM HelpTopic__c];
            setFPIValue('iS2LCountHelpTopics', integer.valueOf(AR[0].get('CT')));

            AR = [SELECT COUNT(Id) CT FROM HelpReadingList__c];
            setFPIValue('iS2LCountHelpReadingLists', integer.valueOf(AR[0].get('CT')));
            
            AR = [SELECT COUNT(Id) CT FROM HelpedPageLayout__c];
            setFPIValue('iS2LCountHelpedPageLayouts', integer.valueOf(AR[0].get('CT')));
            
            AR = [SELECT COUNT(Id) CT FROM HelpResource__c];
            setFPIValue('iS2LCountHelpResources', integer.valueOf(AR[0].get('CT')));

            
            AR = [
                SELECT COUNT(Id) CT, HelpInteractionType__c T
                FROM HelpInteraction__c 
                WHERE HelpInteractionType__c IN (
                        'Callout', 
                        'Comment', 
                        'Full Topic', 
                        'Position Detector Context Log', 
                        'Reading List Entry', 
                        'Resource', 
                        'Search', 
                        'Tree Node')
                GROUP BY HelpInteractionType__c
            ];
            
            
            for (AggregateResult R : AR) {
                
                if (R.get('T') == 'Callout') {
                    setFPIValue('iS2LCountHICallout', integer.valueOf(R.get('CT')));        
                    totalTrackedInteractions += integer.valueOf(R.get('CT'));           
                }
                
                if (R.get('T') == 'Comment') {
                    setFPIValue('iS2LCountHIComment', integer.valueOf(R.get('CT')));                    
                    totalTrackedInteractions += integer.valueOf(R.get('CT'));           
                }

                if (R.get('T') == 'Full Topic') {
                    setFPIValue('iS2LCountHIFullTopic', integer.valueOf(R.get('CT')));                  
                    totalTrackedInteractions += integer.valueOf(R.get('CT'));           
                }

                if (R.get('T') == 'Position Detector Context Log') {
                    setFPIValue('iS2LCountHIPDContext', integer.valueOf(R.get('CT')));                  
                    totalTrackedInteractions += integer.valueOf(R.get('CT'));           
                }

                if (R.get('T') == 'Reading List Entry') {
                    setFPIValue('iS2LCountHIRLEntry', integer.valueOf(R.get('CT')));                    
                    totalTrackedInteractions += integer.valueOf(R.get('CT'));           
                }

                if (R.get('T') == 'Resource') {
                    setFPIValue('iS2LCountHIResource', integer.valueOf(R.get('CT')));                   
                    totalTrackedInteractions += integer.valueOf(R.get('CT'));           
                }

                if (R.get('T') == 'Search') {
                    setFPIValue('iS2LCountHISearch', integer.valueOf(R.get('CT')));                 
                    totalTrackedInteractions += integer.valueOf(R.get('CT'));           
                }

                if (R.get('T') == 'Tree Node') {
                    setFPIValue('iS2LCountHITreeNode', integer.valueOf(R.get('CT')));                   
                    totalTrackedInteractions += integer.valueOf(R.get('CT'));           
                }
                
            }
            
            // Record total count of all logged help interactions
            setFPIValue('iS2LCountHITotal', totalTrackedInteractions);


// Total interactions last 24 hrs
            AR = [
                SELECT COUNT(Id) CT
                FROM HelpInteraction__c 
                WHERE CreatedDate > :H24Ago
                ALL ROWS
            ];
            setFPIValue('iS2LCountHITotalToday', integer.valueOf(AR[0].get('CT')));            


// Total interactions deleted last 24 hrs           
            AR = [
                SELECT COUNT(Id) CT
                FROM HelpInteraction__c 
                WHERE CreatedDate > :H24Ago
                AND IsDeleted = true 
                ALL ROWS
            ];
            setFPIValue('iS2LCountHITotalDelToday', integer.valueOf(AR[0].get('CT')));            
            

// PD Interactions last 24 hrs
            AR = [
                SELECT COUNT(Id) CT
                FROM HelpInteraction__c 
                WHERE CreatedDate > :H24Ago
                AND HelpInteractionType__c = 'Position Detector Context Log'
                ALL ROWS
            ];
            setFPIValue('iS2LCountHIPDContextToday', integer.valueOf(AR[0].get('CT')));            
            

// PD interactions deleted last 24 hrs
            AR = [
                SELECT COUNT(Id) CT
                FROM HelpInteraction__c 
                WHERE CreatedDate > :H24Ago
                AND HelpInteractionType__c = 'Position Detector Context Log'
                AND IsDeleted = true
                ALL ROWS
            ];
            setFPIValue('iS2LCountHIPDContextDelToday', integer.valueOf(AR[0].get('CT')));            


            // Unique Users from Interactions: all time
            AR = [
                SELECT COUNT(Id) CT, CreatedById
                FROM HelpInteraction__c 
                GROUP BY CreatedById
                ALL ROWS
            ];
            
            totalTrackedInteractions = 0;
            for (AggregateResult R : AR) {
                totalTrackedInteractions += 1;
            }
            setFPIValue('iS2LCountHIUserUnique', totalTrackedInteractions);

            
// Unique Users from Interactions: last 24 hrs         
            AR = [
                SELECT COUNT(Id) CT, CreatedById
                FROM HelpInteraction__c 
                WHERE CreatedDate > :H24Ago
                GROUP BY CreatedById
                ALL ROWS
            ];
            
            totalTrackedInteractions = 0;
            for (AggregateResult R : AR) {
                totalTrackedInteractions += 1;
            }
            setFPIValue('iS2LCountHIUserUniqueToday', totalTrackedInteractions);            
            
            
            // Record the date on which these metrics were logged
            date dat = Date.today();
            setFPDValue('dS2LMetricsLogged', dat);
            
                        
        } catch (exception e){
            system.debug('Error recording Improved Help Org Metrics: ' + e.getMessage());
        }
        
    }
    
    
}