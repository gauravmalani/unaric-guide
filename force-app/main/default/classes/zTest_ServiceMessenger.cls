@isTest
public class zTest_ServiceMessenger {
    @isTest
    public static void testServiceMessenger() {
        Test.startTest();
        String title = 'Test Title';
        String body = 'Test Body';
        String customApiName = 'notifPicklistValuesUpdated'; 
        String customApiNameSecond = 'Test'; 
        ServiceMessenger messenger = new ServiceMessenger(title, body, customApiName);
        ServiceMessenger messengerError = new ServiceMessenger(title, body, customApiNameSecond);
        Test.stopTest();
    }
}