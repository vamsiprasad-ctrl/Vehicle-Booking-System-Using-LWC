trigger ContactTrigger on Contact (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        ContactTriggerHandler.afterInsert(Trigger.new);
    }
}