trigger LeadTrigger on Lead (after update) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        LeadTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
    }
}