public class CouponService {
    
    @Future
    public static void updateOppProductCoupons(Set<Id> oppProductIdSet){
        Set<Id> opportunityIdset = new Set<Id>();
        List<OpportunityLineItem> oppProductList = new List<OpportunityLineItem>();
        Map<Id,Opportunity> oppIdMap = new Map<Id,Opportunity>();
        for(OpportunityLineItem oppProduct: [Select ID,Name,ProductCode,OpportunityId,Partner_Payment_OP_Bill_through__c 
                                             From OpportunityLineItem Where Id In:oppProductIdSet]){
                                             	opportunityIdSet.add(oppProduct.OpportunityId);
                                             	oppProductList.add(oppProduct);
                                             }
        for(Opportunity opp: [Select ID,Name,Is_Coupon_Applied__c 
                                             From Opportunity Where Id In:opportunityIdSet]){
                                             oppIdMap.put(opp.Id,opp);	
                                             }
        System.debug('oppProductList::::'+oppProductList);
        List<chargebeeapps__CB_Opportunity_Coupon__c> cbCouponList = [Select ID,Name,chargebeeapps__Opportunity__c,
                                                                      chargebeeapps__CB_Coupon__r.chargebeeapps__Addon_Id__c,
                                                                      chargebeeapps__CB_Coupon__r.chargebeeapps__Charge_Id__c,
                                                                      Discount__c From chargebeeapps__CB_Opportunity_Coupon__c 
                                                                      Where chargebeeapps__Opportunity__c In: opportunityIdSet];
        
        System.debug('cbCouponList::::'+cbCouponList);
        if(cbCouponList != null && cbCouponList.size() > 0){
            for(chargebeeapps__CB_Opportunity_Coupon__c cbOppCoupon: cbCouponList){
                for(OpportunityLineItem oppProduct:oppProductList){
                    if((cbOppCoupon.chargebeeapps__CB_Coupon__r.chargebeeapps__Addon_Id__c != null && 
                       cbOppCoupon.chargebeeapps__CB_Coupon__r.chargebeeapps__Addon_Id__c.Contains(oppProduct.ProductCode)) || 
                       (cbOppCoupon.chargebeeapps__CB_Coupon__r.chargebeeapps__Charge_Id__c != null && 
                        cbOppCoupon.chargebeeapps__CB_Coupon__r.chargebeeapps__Charge_Id__c.Contains(oppProduct.ProductCode))){
                          oppProduct.Partner_Payment_OP_Bill_through__c =  cbOppCoupon.Discount__c;
                           System.debug('Opp Product OP Bill through::'+oppProduct.Partner_Payment_OP_Bill_through__c);
                          oppIdMap.get(oppProduct.OpportunityId).Is_Coupon_Applied__c = true;
                       }   
                }
            }
    	}
        update oppProductList;
        update oppIdMap.values(); 
        
    }

}