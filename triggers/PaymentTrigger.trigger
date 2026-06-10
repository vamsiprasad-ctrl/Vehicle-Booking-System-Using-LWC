trigger PaymentTrigger on Payment__c (after insert, after update) {
    if (Trigger.isAfter && Trigger.isInsert) {
        PaymentTriggerHandler.afterInsertUpdate(Trigger.new, null);
    }
    if (Trigger.isAfter && Trigger.isUpdate) {
        PaymentTriggerHandler.afterInsertUpdate(Trigger.new, Trigger.oldMap);
    }
}