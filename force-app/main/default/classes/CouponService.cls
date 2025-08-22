public class CouponService {
    
    @Future
    public static void updateOppProductCoupons(Set<Id> oppProductIdSet){
        Set<Id> opportunityIdset = new Set<Id>();
        List<OpportunityLineItem> oppProductList = new List<OpportunityLineItem>();
        Map<Id,Opportunity> oppIdMap = new Map<Id,Opportunity>();
        for(OpportunityLineItem oppProduct: [Select ID,Name,ProductCode,OpportunityId,Partner_Payment_OP_Bill_through__c,
                                             ListPrice,Quantity,TotalPrice,Chargebee_Coupon_Amount__c,Coupon_Source__c
                                             From OpportunityLineItem Where Id In:oppProductIdSet]){
                                             	opportunityIdSet.add(oppProduct.OpportunityId);
                                             	oppProductList.add(oppProduct);
                                             }
        for(Opportunity opp: [Select ID,Name,Is_Coupon_Applied__c 
                                             From Opportunity Where Id In:opportunityIdSet]){
                                             oppIdMap.put(opp.Id,opp);	
                                             }
        List<chargebeeapps__CB_Opportunity_Coupon__c> cbCouponList = [Select ID,Name,chargebeeapps__Opportunity__c,
                                                                      chargebeeapps__CB_Coupon__r.chargebeeapps__Addon_Id__c,
                                                                      chargebeeapps__CB_Coupon__r.chargebeeapps__Charge_Id__c,
                                                                      Discount__c From chargebeeapps__CB_Opportunity_Coupon__c 
                                                                      Where chargebeeapps__Opportunity__c In: opportunityIdSet];
        
        if(cbCouponList != null && cbCouponList.size() > 0){
            for(chargebeeapps__CB_Opportunity_Coupon__c cbOppCoupon: cbCouponList){
                for(OpportunityLineItem oppProduct:oppProductList){
                    if((cbOppCoupon.chargebeeapps__CB_Coupon__r.chargebeeapps__Addon_Id__c != null && 
                       cbOppCoupon.chargebeeapps__CB_Coupon__r.chargebeeapps__Addon_Id__c.Contains(oppProduct.ProductCode)) || 
                       (cbOppCoupon.chargebeeapps__CB_Coupon__r.chargebeeapps__Charge_Id__c != null && 
                        cbOppCoupon.chargebeeapps__CB_Coupon__r.chargebeeapps__Charge_Id__c.Contains(oppProduct.ProductCode)))
                    {
                          oppProduct.Partner_Payment_OP_Bill_through__c =  cbOppCoupon.Discount__c;

                          if(oppProduct.ListPrice != null && oppProduct.Quantity != null && cbOppCoupon.Discount__c != null) {
                              Decimal listPriceTotal = oppProduct.ListPrice * oppProduct.Quantity;
                              oppProduct.Chargebee_Coupon_Amount__c = (listPriceTotal * cbOppCoupon.Discount__c) / 100;
                          }

                          oppProduct.Coupon_Source__c = 'Chargebee Coupon';
                          oppIdMap.get(oppProduct.OpportunityId).Is_Coupon_Applied__c = true;
                       }   
                }
            }
    	}
        update oppProductList;
        update oppIdMap.values(); 
        
    }

}