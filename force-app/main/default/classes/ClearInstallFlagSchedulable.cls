//Implemented to clear the custom setting record after installation is completed to avoid overriding userpermissions

global class ClearInstallFlagSchedulable implements Schedulable {
    global void execute(SchedulableContext sc) {
        // If all jobs are completed, update the custom setting
        iahelp__OnInstall__c installSetting = iahelp__OnInstall__c.getOrgDefaults();
        if (installSetting.iahelp__isInstalling__c == true) {
            installSetting.iahelp__isInstalling__c = false;
            update installSetting;
        }
    }
}