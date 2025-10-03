trigger AccountTrigger on Account (before insert, before update, after insert, after update) {
    new AccountTriggerHandler2().run();
    if(Trigger.isAfter && ( Trigger.isInsert || Trigger.isUpdate ))
        AccountTriggerHandler.handleAfterInsertAndUpdate(Trigger.newMap, Trigger.oldMap);
}