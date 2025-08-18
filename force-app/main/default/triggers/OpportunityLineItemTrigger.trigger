trigger OpportunityLineItemTrigger on OpportunityLineItem (before insert,after insert, after update) {
    if (Trigger.isInsert) {
        if (Trigger.isAfter) {
            OpportunityLineItemTriggerHandler.onAfterInsert(Trigger.newMap);
        }
    }
    if(Trigger.isAfter){
        OpportunityLineItemTriggerHandler.updateOpportunityWithARR(Trigger.newMap,Trigger.oldMap);
    }
    if(Trigger.isBefore){
        OpportunityLineItemTriggerHandler.updateCBUnitPrice(Trigger.new);
    }
}