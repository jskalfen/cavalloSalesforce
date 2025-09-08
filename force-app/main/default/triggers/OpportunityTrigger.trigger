trigger OpportunityTrigger on Opportunity (before insert, before update, after update) {
    if (Trigger.isInsert) {
        if (Trigger.isBefore) {
            OpportunityTriggerHandler.onBeforeInsert(Trigger.new);
        }
    } else if (Trigger.isUpdate) {
        if (Trigger.isBefore) {
            OpportunityTriggerHandler.onBeforeUpdate(Trigger.new, Trigger.oldMap);
        } else if (Trigger.isAfter) {  
            OpportunityTriggerHandler.afterUpdate( Trigger.newMap , Trigger.oldMap);
        }
   }
}