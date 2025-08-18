public class PartnerTierTriggerHandler {
    
    public static void beforePartnerTier(List<Partner_Tier__c> newList){
        Set<Id> partnerIdSet = new Set<Id>();
        Set<Id>	partnertoUpdateSet = new Set<Id>();
        Set<ID> existingPTSet = new Set<ID>();
        String errorMessage = System.Label.PartnerTier_ErrorMessage;
        
            for(Partner_Tier__c pt: newList){
                    partnerIdSet.add(pt.Partner__c);
            }
        
        
            List<Partner_Tier__c> existingPTList = [Select ID,Name,PartnerTier_Status__c From Partner_Tier__c Where PartnerTier_Status__c = 'Active' AND Partner__c IN: partnerIdSet];    
        for(Partner_Tier__c existingpt:existingPTList){
            existingPTSet.add(existingpt.ID);
        }
        	for(Partner_Tier__c pt: newList){
                    if(existingPTList != null && existingPTList.size() > 0 && pt.PartnerTier_Status__c == 'Active' && !existingPTSet.contains(pt.ID)){
                        pt.addError(errorMessage); 
                    }
            }
    }
    
    public static void afterPartnerTier(Map<Id,Partner_Tier__c> newpartnerTierMap,Map<Id,Partner_Tier__c> oldpartnerTierMap){
        Set<Id> partnerIdSet = new Set<Id>();
        Set<Id>	partnertoUpdateSet = new Set<Id>();
        String errorMessage = System.Label.PartnerTier_ErrorMessage;
        for(Partner_Tier__c pt: newpartnerTierMap.values()){
            //if(pt.Partner_Tier_End_Date__c == null || (pt.Partner_Tier_End_Date__c != null && pt.Partner_Tier_End_Date__c > Date.Today())){
                partnerIdSet.add(pt.Partner__c);
            //}
        }
        
        
            List<Partner_Tier__c> existingPTList = [Select ID,Name,PartnerTier_Status__c From Partner_Tier__c Where PartnerTier_Status__c = 'Active' AND Partner__c IN: partnerIdSet];
            for(Partner_Tier__c pt: newpartnerTierMap.values()){
                //if(pt.PartnerTier_Status__c != oldpartnerTierMap.get(pt.Id).PartnerTier_Status__c){
                if(existingPTList == null || existingPTList.size() == 0){
                    partnertoUpdateSet.add(pt.Partner__c);
                }  
            }
        
        if(partnertoUpdateSet != null && partnertoUpdateSet.size() > 0){
            PartnerMarginService.updatePartnerForInactiveTiers(partnertoUpdateSet); 
        }
    }
}