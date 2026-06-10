trigger TestDriveTrigger on Test_Drive__c (after update) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        TestDriveTriggerHandler.afterUpdate(
            Trigger.new,
            Trigger.oldMap
        );
    }
}