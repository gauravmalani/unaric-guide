public class ServiceMessenger {
    private String Title = '';
    private String Body = '';
    private String CustomNotifApiName = '';
    public ServiceMessenger(String MessengerTitle , String MessengerBody , String CustomMessengerApiName){ 
        Title = MessengerTitle;
        Body = MessengerBody;
        CustomNotifApiName = CustomMessengerApiName;
        BellNotification(Title,Body,CustomNotifApiName);
    }
    
    Private static void BellNotification( String Title , String Body , String CustomNotifApiName){
        try{
            // Get the Id for our custom notification type
            CustomNotificationType notificationType = [SELECT Id, DeveloperName 
                                                       FROM CustomNotificationType 
                                                       WHERE DeveloperName =: CustomNotifApiName];
            system.debug('notificationType : '+notificationType);
            // My_Custom_Notification (Enter the API Name of custom notification that you have created)
            // Create a new custom notification
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            
            // Set the contents for the notification
            notification.setTitle(Title);
            notification.setBody(Body);
            
            // Set the notification type and target
            notification.setNotificationTypeId(notificationType.Id);
            notification.setTargetId(UserInfo.getUserId()); 
            
            // Actually send the notification
            try {
                notification.send(new set<string>{UserInfo.getUserId()}); 
            }
            catch (Exception e) {
                System.debug('Problem sending notification: ' + e.getMessage());
            }
        }catch(Exception ex){
            System.debug('Error : '+ex);
        }
        
    }
    
    
}