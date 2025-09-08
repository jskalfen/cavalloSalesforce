/**
 * Trigger Handler for chargebeeapps__CB_Opportunity_Coupon__c
 * Updates the Coupon_Discount__c field on related Opportunities
 * by totaling the Discount__c values from all related coupon records
 */
public with sharing class CBOpportunityCouponTriggerHandler {
    
    /**
     * Handles after insert events
     * @param newList List of new chargebeeapps__CB_Opportunity_Coupon__c records
     */
    public static void onAfterInsert(List<chargebeeapps__CB_Opportunity_Coupon__c> newList) {
        updateOpportunityCouponDiscounts(newList);
    }
    
    /**
     * Handles after update events
     * @param newList List of updated chargebeeapps__CB_Opportunity_Coupon__c records
     * @param oldMap Map of old chargebeeapps__CB_Opportunity_Coupon__c records
     */
    public static void onAfterUpdate(List<chargebeeapps__CB_Opportunity_Coupon__c> newList, Map<Id, chargebeeapps__CB_Opportunity_Coupon__c> oldMap) {
        updateOpportunityCouponDiscounts(newList);
    }
    
    /**
     * Updates the Coupon_Discount__c field on related Opportunities
     * @param couponList List of chargebeeapps__CB_Opportunity_Coupon__c records
     */
    @TestVisible
    private static void updateOpportunityCouponDiscounts(List<chargebeeapps__CB_Opportunity_Coupon__c> couponList) {
        // Collect all opportunity IDs from the coupon records
        Set<Id> opportunityIds = new Set<Id>();
        
        for (chargebeeapps__CB_Opportunity_Coupon__c coupon : couponList) {
            if (coupon.chargebeeapps__Opportunity__c != null) {
                opportunityIds.add(coupon.chargebeeapps__Opportunity__c);
            }
        }
        
        if (opportunityIds.isEmpty()) {
            return;
        }
        
        // Query all related coupon records for the opportunities
        List<chargebeeapps__CB_Opportunity_Coupon__c> allCoupons = [
            SELECT Id, chargebeeapps__Opportunity__c, Discount__c
            FROM chargebeeapps__CB_Opportunity_Coupon__c
            WHERE chargebeeapps__Opportunity__c IN :opportunityIds
        ];
        
        // Group coupons by opportunity and calculate total discount
        Map<Id, Decimal> opportunityDiscountMap = new Map<Id, Decimal>();
        
        for (chargebeeapps__CB_Opportunity_Coupon__c coupon : allCoupons) {
            Id oppId = coupon.chargebeeapps__Opportunity__c;
            Decimal discount = coupon.Discount__c != null ? coupon.Discount__c : 0;
            
            if (opportunityDiscountMap.containsKey(oppId)) {
                opportunityDiscountMap.put(oppId, opportunityDiscountMap.get(oppId) + discount);
            } else {
                opportunityDiscountMap.put(oppId, discount);
            }
        }
        
        // Update opportunities with the calculated coupon discount totals
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        
        for (Id oppId : opportunityIds) {
            Opportunity opp = new Opportunity(Id = oppId);
            opp.Coupon_Discount__c = opportunityDiscountMap.get(oppId) != null ? opportunityDiscountMap.get(oppId) : 0;
            opportunitiesToUpdate.add(opp);
        }
        
        if (!opportunitiesToUpdate.isEmpty()) {
            try {
                update opportunitiesToUpdate;
            } catch (Exception e) {
                System.debug('Error updating opportunity coupon discounts: ' + e.getMessage());
                // Log error but don't throw to avoid breaking the trigger
            }
        }
    }
}
