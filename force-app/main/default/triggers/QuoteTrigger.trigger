trigger QuoteTrigger on Quote (before insert,before update) {
    QuoteTriggerHandler.beforeInsert(Trigger.New);
}