public class PartnerMarginTriggerHandler {
    
    public static void afterTrigger(Map<Id,Partner_Margin__c> newMap,Map<Id,Partner_Margin__c> oldMap){
        Set<Id> oppIdSet = new Set<Id>();
        Set<Id> oppProductIdSet = new Set<Id>();
        Set<Id> pmIdSet = new Set<Id>();
        String PMStatusBtP = System.Label.PM_Status_BillThroughPartner;
        String PMStatusDirect = System.Label.PM_Status_Direct;
        //List<Partner_Margin__c> pmListToUpdate = new List<Partner_Margin__c>();
        //Map<ID,Partner_Tier__c> partnerIdToPartnerTierMap = new Map<ID,Partner_Tier__c>();
        for(Partner_Margin__c pm: newMap.values()){
            if(pm.Software_Partner_Margin_Y1__c != oldMap.get(pm.Id).Software_Partner_Margin_Y1__c || pm.Enhancement_Partner_Margin_Y1__c != oldMap.get(pm.Id).Enhancement_Partner_Margin_Y1__c || pm.Partner__c != oldMap.get(pm.Id).Partner__c || (pm.Partner_Billing_Type__c != oldMap.get(pm.Id).Partner_Billing_Type__c && (pm.Partner_Billing_Type__c == PMStatusDirect || oldMap.get(pm.Id).Partner_Billing_Type__c == PMStatusDirect))){
                oppIdSet.add(pm.Opportunity__c);
                pmIdSet.add(pm.Id);
            }
            if(pm.Partner_Billing_Type__c != oldMap.get(pm.Id).Partner_Billing_Type__c && pm.Partner_Billing_Type__c == PMStatusBtP){
                pmIdSet.add(pm.Id);   
            }
        }
        
        Map<Id,OpportunityLineItem> oppProductMap = new Map<Id,OpportunityLineItem>([Select ID,Name From OpportunityLineItem where OpportunityId In :oppIdSet]);
        try{
            
            if(oppIdSet != null && oppIdSet.size() > 0){
                updateRelatedOppProducts(oppIdSet);
                if(!System.isFuture()){
                    CouponService.updateOppProductCoupons(oppProductMap.keySet());
                }
            }
            if(pmIdSet != null && pmIdSet.size() > 0){
                updateRelatedPMProducts(pmIdSet);
            }
            
        }catch(Exception exp){
            System.debug('Exception: '+exp.getMessage());
        }
        
    }
    
    public static void beforeDelete(List<Partner_Margin__c> oldPmList){
        Set<Id> oppIdSet = new Set<Id>();
        for(Partner_Margin__c pm: oldPmList){
            oppIdSet.add(pm.Opportunity__c);
        }
        if(oppIdSet != null && oppIdSet.size() > 0){
            updateRelatedOppProducts(oppIdSet); 
        }
    }
    
    public static void updateRelatedOppProducts(Set<Id> oppIdSet){
        if(oppIdSet != null && oppIdSet.size() > 0){
            Map<Id,OpportunityLineItem> oppProductMap = new Map<Id,OpportunityLineItem>([Select ID from OpportunityLineItem where OpportunityId In: oppIdSet]);
            if(oppProductMap != null && oppProductMap.size() > 0){
                PartnerMarginService.updateOppProductWithPM(oppProductMap.keySet()); 
            }
        }
    }
    
    @future
    public static void updateRelatedPMProducts(Set<Id> pmIdSet){
        List<Partner_Margin_Product__c> pmProductList = new List<Partner_Margin_Product__c>();
        Set<Id> oppProductIdSet = new Set<Id>();
        Map<Id,Decimal> BtPMap = new Map<Id,Decimal>();
        String PMStatusBtP = System.Label.PM_Status_BillThroughPartner;
        String PMStatusDirect = System.Label.PM_Status_Direct;
        if(pmIdSet != null && pmIdSet.size() > 0){
            pmProductList = [
                SELECT 
                    Id,Opportunity_Product__r.TotalPrice,Total_Price_Original__c,Opportunity_Product__c,Opportunity_Product__r.Partner_Payment_OppProduct__c,
                    Partner_Margin__r.Partner_Billing_Type__c,Opportunity_Product__r.Partner_Payment_OP_Bill_through__c 
                FROM Partner_Margin_Product__c 
                WHERE Partner_Margin__c 
                IN: pmIdSet 
                AND Opportunity_Product__c != null
            ];
            for(Partner_Margin_Product__c pmProduct : pmProductList){
                if(pmProduct.Opportunity_Product__r.Partner_Payment_OP_Bill_through__c == null){                   
                    BtPMap.put(pmProduct.Id,0.00);
                } else {
                    BtPMap.put(pmProduct.Id,pmProduct.Opportunity_Product__r.Partner_Payment_OP_Bill_through__c);
                }
            }
            
            if(pmProductList != null && pmProductList.size() > 0){
                for(Partner_Margin_Product__c pmProduct : pmProductList){
                    if(pmProduct.Partner_Margin__r.Partner_Billing_Type__c == PMStatusDirect){
                        pmProduct.Total_Price_Original__c =  pmProduct.Opportunity_Product__r.TotalPrice; 
                    } else if (pmProduct.Partner_Margin__r.Partner_Billing_Type__c == PMStatusBtP){
                        pmProduct.Total_Price_Original__c = pmProduct.Opportunity_Product__r.TotalPrice + pmProduct.Opportunity_Product__r.Partner_Payment_OppProduct__c; 
                    }
                    
                }
                update pmProductList;                
            }
        }
    }
    
    public static void beforeUpdate(Map<Id,Partner_Margin__c> newMap,Map<Id,Partner_Margin__c> oldMap){
        Set<ID> partnerIdSet = new Set<ID>();
        Map<ID,Partner_Tier__c> partnerIdToPartnerTierMap = new Map<ID,Partner_Tier__c>();
        Map<String,Partner_Client_Relationship__c> partnerIdToPartnerClientRelMap = new Map<String,Partner_Client_Relationship__c>();
        
        for(Partner_Margin__c pm: newMap.values()){
            partnerIdSet.add(pm.Partner__c); 
        }
        for(Partner_Tier__c partnerTier :[SELECT Id, Partner_Tier_Margin__c, Partner__c,Partner_Tier__c FROM Partner_Tier__c WHERE 
                                         PartnerTier_Status__c = 'Active' AND Partner__c In: partnerIdSet]){
                                             partnerIdToPartnerTierMap.put(partnerTier.Partner__c,partnerTier);    
                                         }
        for(Partner_Client_Relationship__c partnerClientRelp:[Select ID,Partner__c,Client__c,Partner_Client_Margin_Eligibility__c from Partner_Client_Relationship__c where 
                                                              Partner__c In: partnerIdSet]){
                                                                  String partnerClientKey = (String)partnerClientRelp.Partner__c+(String)partnerClientRelp.Client__c;
                                                                  partnerIdToPartnerClientRelMap.put(partnerClientKey,partnerClientRelp);    
                                                              }
        for(Partner_Margin__c pm: newMap.values()){
            
            if(pm.Partner__c != oldMap.get(pm.Id).Partner__c){
                if(partnerIdToPartnerTierMap != null && partnerIdToPartnerTierMap.size()>0){
                    pm.Software_Partner_Margin_Y1__c = partnerIdToPartnerTierMap.get(pm.Partner__c).Partner_Tier_Margin__c;
                    pm.Partner_Tier__c = partnerIdToPartnerTierMap.get(pm.Partner__c).Partner_Tier__c;
                    if(partnerIdToPartnerTierMap.get(pm.Partner__c).Partner_Tier__c == 'Bronze'){
                        pm.Enhancement_Partner_Margin_Y1__c = partnerIdToPartnerTierMap.get(pm.Partner__c).Partner_Tier_Margin__c;  
                    }else{
                        pm.Enhancement_Partner_Margin_Y1__c = 15;
                    }
                }else{
                    pm.addError(System.Label.PM_MissingPartnerTierMessage);
                }
                
                if(partnerIdToPartnerClientRelMap != null && partnerIdToPartnerClientRelMap.size()>0){
                    String pmClientKey = (String)pm.Partner__c + (String)pm.Client__c;
                    pm.Partner_Client_Margin_Eligibility__c = partnerIdToPartnerClientRelMap.get(pmClientKey).Partner_Client_Margin_Eligibility__c;
                }
            }
        }
    }
}