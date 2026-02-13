trigger AccountTrigger on Account (before insert, before update, after insert, after update) {
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate))
        AccountTriggerHandler.handleBeforeInsertAndUpdate(Trigger.new, Trigger.oldMap);
    if(Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate))
        AccountTriggerHandler.handleAfterInsertAndUpdate(Trigger.newMap, Trigger.oldMap);
}
