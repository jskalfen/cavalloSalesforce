trigger QuoteLineItemTrigger on QuoteLineItem (after insert,before insert,before update,before delete) {
    if (Trigger.isInsert) {
        if (Trigger.isAfter) {
            QuoteLineItemTriggerHandler.onAfterInsert(Trigger.newMap);
        }
    }
    if (Trigger.isBefore) {
        QuoteLineItemTriggerHandler.onBefore(Trigger.New,Trigger.Old);
    }
}