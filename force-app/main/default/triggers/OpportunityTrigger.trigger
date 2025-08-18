trigger OpportunityTrigger on Opportunity (before insert, after update) {
    if (Trigger.isInsert) {
        if (Trigger.isBefore) {
            OpportunityTriggerHandler.onBeforeInsert(Trigger.new);
        }
    } else if (Trigger.isUpdate) {
         if (Trigger.isAfter) {  
             OpportunityTriggerHandler.afterUpdate( Trigger.newMap , Trigger.oldMap);
        }
   }
}