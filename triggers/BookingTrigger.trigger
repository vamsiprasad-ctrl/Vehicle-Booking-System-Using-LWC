trigger BookingTrigger on Booking__c (before insert, after insert, after update) {
    if (Trigger.isBefore && Trigger.isInsert) {
        BookingTriggerHandler.beforeInsert(Trigger.new);
    }
    if (Trigger.isAfter && Trigger.isInsert) {
        BookingTriggerHandler.afterInsert(Trigger.new);
    }
    if (Trigger.isAfter && Trigger.isUpdate) {
        BookingTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
    }
}