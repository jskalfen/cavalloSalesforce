trigger QuoteTrigger on Quote (before insert,before update) {
    new QuoteTriggerHandlerV2().run();
    QuoteTriggerHandler.beforeInsert(Trigger.New);
}