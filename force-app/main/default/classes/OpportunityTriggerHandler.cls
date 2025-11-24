//Trigger Handler for Opportunity Line Item
// 2017-12-21 Ray Dehler <rdehler@square2marketing.com> created
public with sharing class OpportunityTriggerHandler {   
    public static Feature_Activation__c fa = Feature_Activation__c.getInstance();

   
    public static void onBeforeInsert(List<Opportunity> newList) {
        defaultPricebookId(newList);
    }
    
    public static void onBeforeUpdate(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        updateManualDiscount(newList, oldMap);
    }
   
    public static void afterUpdate(Map<Id,Opportunity> newOppMap, Map<Id,Opportunity> oldOppMap) {
        List<Opportunity> oppList = new List<Opportunity>();
        Set<Id> oppIdSet = new Set<Id>();
        Set<Id> oppIdSetToUpdatePM = new Set<Id>();
        Boolean isReccuringRev = false;
        List<OpportunityLineItem> oppProductList = new List<OpportunityLineItem>();
        for(Opportunity opp: newOppMap.values()){
            if(oldOppMap != null && opp.Partner__c != oldOppMap.get(opp.Id).Partner__c && opp.Partner__c != null){
                oppIdSet.add(opp.Id);
            }
            if(oldOppMap != null && opp.chargebeeapps__Subscription_Id__c != oldOppMap.get(opp.Id).chargebeeapps__Subscription_Id__c && opp.chargebeeapps__Subscription_Id__c != null){
                oppIdSetToUpdatePM.add(opp.Id);
            }
        }
        if(oppIdSet != null && oppIdSet.size() > 0){
            oppList = [SELECT ID, Name,Partner__c,StageName,AccountId,Partner__r.Active_Partner_Tier__c,Partner__r.Bill_through_Partner__c,Sales_ARR_MFC1__c,Total_ARR_Opp__c,Subscription_ARR_Opp_MFC__c,Enhancement_ARR_Opp_MFC__c,
                       Subscription_Total_Opp_Billing_MFC__c,Perpetual_Total_Opp_Billing_MFC__c,chargebeeapps__Subscription_Id__c,
                       (Select ID,Name,OpportunityId,Quantity,Recurring_Revenue__c,TotalPrice,
                        Licensing__c,ARR_MFC__c,Perpetual_Type__c,Subscription_Product_Type__c,Product_Name__c,ProductCode 
                        From OpportunityLineItems)
                       FROM Opportunity
                       WHERE Id IN :oppIDSet];
            
            for(Opportunity opp: oppList){
                oppProductList.addAll(opp.OpportunityLineItems);
                for(OpportunityLineItem oppProd: opp.OpportunityLineItems){
                    if(oppProd.Recurring_Revenue__c){
                        isReccuringRev = true; 
                    } 
                }
            }
        }
        
        if(isReccuringRev && oppList != null && oppList.size() > 0 && oppProductList != null && oppProductList.size()>0){
            PartnerMarginService.createPartnerMargin(oppList,oppProductList);
        }
        
        if(oppIdSetToUpdatePM != null && oppIdSetToUpdatePM.size() > 0){
            List<Partner_Margin__c> oppRelatedPMList = [Select ID,CB_Subscription_ID__c,
                                                        Opportunity__r.chargebeeapps__Subscription_Id__c From 
                                                        Partner_Margin__c where Opportunity__c In:oppIdSetToUpdatePM ];
            if(oppRelatedPMList != null && oppRelatedPMList.size() > 0){
                for(Partner_Margin__c pm: oppRelatedPMList){
                   pm.CB_Subscription_ID__c = pm.Opportunity__r.chargebeeapps__Subscription_Id__c; 
                }
                update oppRelatedPMList;
            }
        }
    }
   
    private static void defaultPricebookId(List<Opportunity> newList) {
        if (!fa.Default_Pricebook_Id__c) {
            return;
        }
       
        Map<String, Pricebook2> pricebookMap = new Map<String, Pricebook2>();
        Id standardPbId;
        for (Pricebook2 pb : [select Id, Name, IsStandard from Pricebook2 where IsActive = true]) {
            pricebookMap.put(pb.Name, pb);
            if (pb.IsStandard) {
                standardPbId = pb.Id;
            }
        }

        Map<Id, Account> accountMap = new Map<Id, Account>();
        for (Opportunity opp : newList) {
            accountMap.put(opp.AccountId, null);
        }        
       
        accountMap = new Map<Id, Account>([select Partner_Level__c from Account where Id in :accountMap.keySet()]);
       
        for (Opportunity opp : newList) {
            if (opp.Pricebook2Id != null) {
                continue;
            }
            opp.Pricebook2Id = standardPbId;
        }
    }
    
    /**
     * Updates the Manual_Discount__c field based on the chargebeeapps__Manual_Discount__c JSON data
     */
    private static void updateManualDiscount(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        for (Opportunity opp : newList) {
            Opportunity oldOpp = oldMap.get(opp.Id);
            
            // Check if the chargebeeapps__Manual_Discount__c field has changed
            if (opp.chargebeeapps__Manual_Discount__c != oldOpp.chargebeeapps__Manual_Discount__c && 
                opp.chargebeeapps__Manual_Discount__c != null) {
                
                try {
                    // Parse the JSON and extract the discount percentage
                    Decimal discountPercentage = parseManualDiscountPercentage(opp.chargebeeapps__Manual_Discount__c);
                    if (discountPercentage != null) {
                        opp.Manual_Discount__c = discountPercentage;
                    }
                    Decimal discountAmount = parseManualDiscountAmount(opp.chargebeeapps__Manual_Discount__c);
                    if (discountAmount != null) {
                        opp.Manual_Discount_Fixed__c = discountAmount;
                    }
                } catch (Exception e) {
                    System.debug('Error parsing manual discount JSON: ' + e.getMessage());
                    // Don't throw exception to avoid breaking the trigger
                }
            }
        }
    }
    
    /**
     * Parses the manual discount JSON string and extracts the discount percentage
     * Returns the first percentage discount found, or null if none found
     */
    private static Decimal parseManualDiscountPercentage(String jsonString) {
        try {
            List<QuoteLineDiscount> discounts = (List<QuoteLineDiscount>) JSON.deserialize(jsonString, List<QuoteLineDiscount>.class);
            
            for (QuoteLineDiscount discount : discounts) {
                // Look for percentage discounts that are invoice-level discounts
                if (discount.isPercentageDiscount != null && discount.isPercentageDiscount && 
                    discount.isInvoiceDiscount != null && discount.isInvoiceDiscount &&
                    String.isNotBlank(discount.discountPercentage)) {
                    
                    return Decimal.valueOf(discount.discountPercentage);
                }
            }
        } catch (Exception e) {
            System.debug('Error deserializing manual discount JSON: ' + e.getMessage());
        }
        
        return null;
    }

    private static Decimal parseManualDiscountAmount(String jsonString) {
        try {
            List<QuoteLineDiscount> discounts = (List<QuoteLineDiscount>) JSON.deserialize(jsonString, List<QuoteLineDiscount>.class);
            for (QuoteLineDiscount discount : discounts) {
                if (discount.isFixedDiscount != null && discount.isFixedDiscount && 
                    String.isNotBlank(discount.discountAmount)) {
                    return Decimal.valueOf(discount.discountAmount);
                }
            }
        } catch (Exception e) {
            System.debug('Error deserializing manual discount JSON: ' + e.getMessage());
        }
        return null;
    }
}