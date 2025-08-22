public with sharing class OpportunityLineItemTriggerHandler {
    public static void onAfterInsert(Map<Id, OpportunityLineItem> newMap) {
        
    }
    
    public static void updateOpportunityWithARR(
        Map<Id, OpportunityLineItem> newMap,
        Map<Id, OpportunityLineItem> oldMap
    ) {
        Set<ID> oppIDSet = new Set<ID>();
        String licensingSubscription = System.Label.OppLine_Licensing_Subscription;
        String licensingPerpetual = System.Label.OppLine_Licensing_Perpetual;
        String perpetualTypeEnhancement = System.Label.OppLine_PerpetualType_Enhancement;
        List<Opportunity> oppListToUpdate = new List<Opportunity>();
        List<Opportunity> oppListForPM = new List<Opportunity>();
        Set<ID> oppIdSetWithPartner = new Set<ID>();
        Set<ID> oppProductIdSet = new Set<ID>();
        for (OpportunityLineItem oli : newMap.values()) {
            oppIDSet.add(oli.OpportunityId);
        }
        List<Opportunity> oppList = [
            SELECT ID, Name,StageName,Partner__c,AccountId,Partner__r.Active_Partner_Tier__c,Partner__r.Bill_through_Partner__c,Sales_ARR_MFC1__c,Total_ARR_Opp__c,Subscription_ARR_Opp_MFC__c,Enhancement_ARR_Opp_MFC__c,
            Subscription_Total_Opp_Billing_MFC__c,Perpetual_Total_Opp_Billing_MFC__c,chargebeeapps__Subscription_Id__c
            FROM Opportunity
            WHERE Id IN :oppIDSet
        ];
        
        for (Opportunity opp : oppList) {
            if(oldMap == null){
                opp.Subscription_ARR_Opp_MFC__c = 0.00;
                opp.Enhancement_ARR_Opp_MFC__c = 0.00;
                opp.Subscription_Total_Opp_Billing_MFC__c = 0.00;
                opp.Perpetual_Total_Opp_Billing_MFC__c = 0.00;
                opp.Sales_ARR_MFC1__c = 0.00;
                opp.Total_ARR_Opp__c = 0.00;
                
                for (OpportunityLineItem oli : newMap.values()) {
                    oppProductIdSet.add(oli.Id);
                    if (oli.OpportunityId == opp.ID) {
                        if(oli.Licensing__c != null && oli.Licensing__c.equalsIgnoreCase(licensingSubscription)) {
                            opp.Subscription_ARR_Opp_MFC__c += oli.ARR_MFC__c;
                            opp.Subscription_Total_Opp_Billing_MFC__c += oli.TotalPrice;
                        }else if(oli.Licensing__c != null){
                            if(oli.Licensing__c.equalsIgnoreCase(licensingPerpetual)){
                                opp.Perpetual_Total_Opp_Billing_MFC__c += oli.TotalPrice;
                            }                        
                        }
                        if(oli.Perpetual_Type__c != null && oli.Perpetual_Type__c.equalsIgnoreCase(perpetualTypeEnhancement)){
                            opp.Enhancement_ARR_Opp_MFC__c += oli.ARR_MFC__c;
                        }
                        if(oli.Sales_ARR_MFC__c != null && oli.Sales_ARR_MFC__c > 0){
                            opp.Sales_ARR_MFC1__c += oli.Sales_ARR_MFC__c;
                        }
                        if(oli.ARR_MFC__c != null && oli.ARR_MFC__c > 0){
                            opp.Total_ARR_Opp__c += oli.ARR_MFC__c;
                        }
                        if(Opp.Partner__c != null){
                           oppIdSetWithPartner.add(Opp.Id);
                           oppListForPM.add(Opp);
                        }
                    }
                    
                }
                oppListToUpdate.add(opp);
            }
        }
        
        if(oldMap == null && oppIdSetWithPartner != null && oppIdSetWithPartner.size()>0){
            PartnerMarginService.deletePartnerMargin(oppIdSetWithPartner);
            
            if(oppListForPM != null){
              PartnerMarginService.createPartnerMargin(oppListForPM,newMap.values());  
            }
        }
        
        if(oppListToUpdate != null && oppListToUpdate.size()>0){
            update oppListToUpdate; 
        }
        
        if(!System.isFuture()){
        	CouponService.updateOppProductCoupons(oppProductIdSet);
        }
        
        if(oldMap != null) {
            OpportunityLineItemCouponTracking.trackManualPartnerPayments(newMap.values(), oldMap);
        }
        
    }
    
    public static void updateCBUnitPrice(
        List<OpportunityLineItem> oliList
    ) {
        Set<ID> oppIDSet = new Set<ID>();
        Set<ID> productIDSet = new Set<ID>();
        Set<ID> oppSubIDSet = new Set<ID>();
        Set<ID> cbItemPriceSet = new Set<ID>();
        Map<ID,chargebeeapps__CB_Item_Price__c> cbItemPriceMap = null;
        List<OpportunityLineItem> oliListToUpdate = new List<OpportunityLineItem>();
        Map<String,chargebeeapps__Subscription_Addon__c> subAddOnMap = new Map<String,chargebeeapps__Subscription_Addon__c>();
        
        if(oliList != null){
            for(OpportunityLineItem oli : oliList) {
                oppIDSet.add(oli.OpportunityId);
                productIDSet.add(oli.Product2Id);
                cbItemPriceSet.add(oli.chargebeeapps__CB_Item_Price__c);
            }
        }
        
        if(cbItemPriceSet != null && cbItemPriceSet.size() > 0){
            cbItemPriceMap = new Map<ID,chargebeeapps__CB_Item_Price__c>
                ([Select ID,chargebeeapps__Price__c,chargebeeapps__Period_Unit__c,chargebeeapps__Period__c From chargebeeapps__CB_Item_Price__c where ID IN: cbItemPriceSet]);   
            List<Opportunity> oppList = [
                SELECT ID, Name, chargebeeapps__Subscription_Id__c
                FROM Opportunity
                WHERE Id IN :oppIDSet
                WITH SECURITY_ENFORCED
            ];
            for(Opportunity opp:oppList){
                oppSubIDSet.add(opp.chargebeeapps__Subscription_Id__c);
            }
            if(oppSubIDSet != null && oppSubIDSet.size() > 0){
                    for(chargebeeapps__Subscription_Addon__c cbSubAddon: [Select ID,chargebeeapps__Unit_Price__c,chargebeeapps__Product__r.ProductCode From chargebeeapps__Subscription_Addon__c 
                                                                           Where chargebeeapps__Subscription__c IN: oppSubIDSet]){
                        subAddOnMap.put(cbSubAddon.chargebeeapps__Product__r.ProductCode,cbSubAddon); 
                    }
            }
        }
        List<Product2> prodList = [Select ID,ProductCode From Product2 where ID IN:productIDSet];
        Map<ID,String> productCodeMap = new Map<ID,String>();
        if(prodList != null){
            for(Product2 prod:prodList){
                productCodeMap.put(prod.ID,prod.ProductCode); 
            } 
        }
        
        for(OpportunityLineItem oli: oliList){
            String prodKey = productCodeMap.get(oli.Product2Id);
            if(subAddOnMap != null && subAddOnMap.containsKey(prodKey)){
                oli.Unit_Price__c = subAddOnMap.get(prodKey).chargebeeapps__Unit_Price__c;
            }
            Double grossARR = 0.00;
            if(cbItemPriceMap != null && cbItemPriceMap.containsKey(oli.chargebeeapps__CB_Item_Price__c)){
                oli.CB_List_Price_Custom__c = cbItemPriceMap.get(oli.chargebeeapps__CB_Item_Price__c).chargebeeapps__Price__c;
                if(oli.Recurring_Revenue__c){
                    if(oli.Unit_Price__c == null){
                        if(cbItemPriceMap.get(oli.chargebeeapps__CB_Item_Price__c).chargebeeapps__Period_Unit__c == 'YEAR'){
                            grossARR = oli.CB_List_Price_Custom__c * oli.Quantity;
                        }else if(cbItemPriceMap.get(oli.chargebeeapps__CB_Item_Price__c).chargebeeapps__Period_Unit__c == 'MONTH' &&
                                 cbItemPriceMap.get(oli.chargebeeapps__CB_Item_Price__c).chargebeeapps__Period__c == 3){
                                     grossARR = oli.CB_List_Price_Custom__c * 4 * oli.Quantity;
                                 }
                    }else{
                        if(cbItemPriceMap.get(oli.chargebeeapps__CB_Item_Price__c).chargebeeapps__Period_Unit__c == 'YEAR'){
                            grossARR = oli.Unit_Price__c * oli.Quantity;
                        }else if(cbItemPriceMap.get(oli.chargebeeapps__CB_Item_Price__c).chargebeeapps__Period_Unit__c == 'MONTH' &&
                                 cbItemPriceMap.get(oli.chargebeeapps__CB_Item_Price__c).chargebeeapps__Period__c == 3){
                                     grossARR = oli.Unit_Price__c * 4 * oli.Quantity;
                                 }  
                    }
                }
            }
            oli.Sales_Gross_ARR__c = grossARR;
        }        
    }   
}