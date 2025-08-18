trigger PartnerTierTrigger on Partner_Tier__c (before insert, before update,after update) {
    
    if(Trigger.isBefore){
        PartnerTierTriggerHandler.beforePartnerTier(Trigger.new);
    }
    
    if(Trigger.isAfter){
       PartnerTierTriggerHandler.afterPartnerTier(Trigger.newMap,Trigger.oldMap);
    }

}