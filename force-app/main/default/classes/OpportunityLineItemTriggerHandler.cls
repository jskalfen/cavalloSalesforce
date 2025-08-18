// Trigger Handler for Opportunity Line Item
// 2017-12-21 Ray Dehler <rdehler@square2marketing.com> created
public with sharing class OpportunityLineItemTriggerHandler {
    /*private static final String ENHANCEMENT_APPEND = ' Enhancement';
    private static final String ERROR_ON_INSERT = 'Unable to Add Enhancement Product, please contact your Administrator';
    private static final String ENHANCEMENT_PERCENT_STRING = '22';
    private static final DOUBLE ENHANCEMENT_PERCENT = .22;
    public static Feature_Activation__c fa = Feature_Activation__c.getInstance();*/
    
    public static void onAfterInsert(Map<Id, OpportunityLineItem> newMap) {
        
    }
    
    // for each of the Items being added, if there is another product
    // with Enhancement at the end, add it also
    /*private static void addEnhancementItem(Map<Id, OpportunityLineItem> newMap) {
        if (!fa.Add_Enhancement_Items__c) {
            return;
        }
        
        Map<Id, OpportunityLineItem> existingOliMap = new Map<Id, OpportunityLineItem>();
        Set<String> productNameSet = new Set<String>();
        Set<Id> pricebookIds = new Set<Id>();
        Map<String, PricebookEntry> pricebookEntryMap = new Map<String, PricebookEntry>();
        Map<Id, OpportunityLineItem> olisToAdd = new Map<Id, OpportunityLineItem>();
        Map<Id, Set<String>> oppProductSetMap = new Map<Id, Set<String>>();
        
        // fill collections
        for (Id oliId : newMap.keySet()) {
            OpportunityLineItem oli = newMap.get(oliId);
            existingOliMap.put(oli.Id, null);
        }
        
        existingOliMap = new Map<Id, OpportunityLineItem>(
            [
                SELECT
                Product2.Name,
                Product2Id,
                PricebookEntry.Pricebook2Id,
                OpportunityId,
                Quantity
                FROM OpportunityLineItem
                WHERE Id IN :existingOliMap.keySet()
            ]
        );
        
        for (Id oliId : existingOliMap.keySet()) {
            OpportunityLineItem oli = existingOliMap.get(oliId);
            productNameSet.add(oli.Product2.Name + ENHANCEMENT_APPEND);
            pricebookIds.add(oli.PricebookEntry.Pricebook2Id);
            oppProductSetMap.put(oli.OpportunityId, new Set<String>());
        }
        
        for (OpportunityLineItem oli : [
            SELECT Product2.Name, OpportunityId
            FROM OpportunityLineItem
            WHERE OpportunityId IN :oppProductSetMap.keySet()
        ]) {
            oppProductSetMap.get(oli.OpportunityId).add(oli.Product2.Name);
        }
        
        for (PricebookEntry pbe : [
            SELECT Product2.Name, Pricebook2Id, UnitPrice
            FROM PricebookEntry
            WHERE Product2.Name IN :productNameSet AND Pricebook2Id IN :pricebookIds
        ]) {
            pricebookEntryMap.put(pbe.Product2.Name + ';' + pbe.Pricebook2Id, pbe);
        }
        
        for (Id oliId : existingOliMap.keySet()) {
            OpportunityLineItem oli = existingOliMap.get(oliId);
            String key =
                oli.Product2.Name +
                ENHANCEMENT_APPEND +
                ';' +
                oli.PricebookEntry.Pricebook2Id;
            if (
                pricebookEntryMap.containsKey(key) &&
                !oppProductSetMap.get(oli.OpportunityId)
                .contains(oli.Product2.Name + ENHANCEMENT_APPEND)
            ) {
                OpportunityLineItem oliToAdd = new OpportunityLineItem();
                oliToAdd.OpportunityId = oli.OpportunityId;
                oliToAdd.PricebookEntryId = pricebookEntryMap.get(key).Id;
                oliToAdd.Product2Id = oli.Product2Id;
                oliToAdd.Quantity = oli.Quantity;
                oliToAdd.UnitPrice = pricebookEntryMap.get(key).UnitPrice;
                oliToAdd.Comments__c = String.Format(
                    '{0}% Annual Enhancement per concurrent user. \nProrated Enhancement from date: \nList price: $',
                    new List<String>{ ENHANCEMENT_PERCENT_STRING }
                );
                olisToAdd.put(oliId, oliToAdd);
            }
        }
        
        if (!olisToAdd.isEmpty()) {
            try {
                insert olisToAdd.values();
            } catch (Exception e) {
                // could segment the actual error, but let's error all for now
                for (Id oliId : olisToAdd.keySet()) {
                    newMap.get(oliId).addError(ERROR_ON_INSERT);
                }
            }
        }
    }*/
    
    public static void updateOpportunityWithARR(
        Map<Id, OpportunityLineItem> newMap,
        Map<Id, OpportunityLineItem> oldMap
    ) {
        Set<ID> oppIDSet = new Set<ID>();
        String licensingSubscription = System.Label.OppLine_Licensing_Subscription;
        String licensingSoftware = System.Label.OppLine_Licensing_Software;
        String businessLineProfessionalServices = System.Label.OppLine_BusinessLine_ProfessionalServices;
        String licensingPerpetual = System.Label.OppLine_Licensing_Perpetual;
        String perpetualTypeEnhancement = System.Label.OppLine_PerpetualType_Enhancement;
        List<Opportunity> oppListToUpdate = new List<Opportunity>();
        List<Opportunity> oppListForPM = new List<Opportunity>();
        List<OpportunityLineItem> oppProductListForPM = new List<OpportunityLineItem>();
        //Boolean createPartnerMargin = false;
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
                        system.debug('Opp Partner:::'+Opp.Partner__c);
                        //system.debug('Oli Recc Revenue:::'+oli.Recurring_Revenue__c);
                        if(Opp.Partner__c != null){
                           oppIdSetWithPartner.add(Opp.Id);
                           oppListForPM.add(Opp);
                           /*if(oli.Recurring_Revenue__c){
                           		
                               	createPartnerMargin = true; 
                           }*/
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
        
        //future call to update coupon information on Opportunity Products
        if(!System.isFuture()){
        	CouponService.updateOppProductCoupons(oppProductIdSet);
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
        
        
        //Partner_Payment_OP_Bill_through__c
        //system.debug('cbItemPriceSet::::'+cbItemPriceSet);
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
            //system.debug('oppSubIDSet::::'+oppSubIDSet);
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
            //oli.Partner_Margin_Attributable_Amount__c = oli.TotalPrice;
            /*for(chargebeeapps__CB_Opportunity_Coupon__c cbCoupon: opCbCouponMap.get(oli.OpportunityId)){
                if(cbCoupon.chargebeeapps__CB_Coupon__r.chargebeeapps__Addon_Id__c.Contains(oli.ProductCode) ||
                  cbCoupon.chargebeeapps__CB_Coupon__r.chargebeeapps__Charge_Id__c.Contains(oli.ProductCode)){
                  System.debug('....Inside If...');
                  oli.Partner_Payment_OP_Bill_through__c = cbCoupon.chargebeeapps__CB_Coupon__r.chargebeeapps__Discount_Percentage__c; 
                }
            }*/
        }        
    }   
}