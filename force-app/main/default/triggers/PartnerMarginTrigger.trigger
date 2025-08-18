trigger PartnerMarginTrigger on Partner_Margin__c (before update,after update,before delete) {
    if(Trigger.isAfter){
        PartnerMarginTriggerHandler.afterTrigger(Trigger.newMap,Trigger.oldMap);
    } 
    
    if(Trigger.isDelete && Trigger.isBefore){
         PartnerMarginTriggerHandler.beforeDelete(Trigger.old);
        }
    
    if(Trigger.isUpdate && Trigger.isBefore){
       PartnerMarginTriggerHandler.beforeUpdate(Trigger.newMap,Trigger.oldMap); 
    }
}