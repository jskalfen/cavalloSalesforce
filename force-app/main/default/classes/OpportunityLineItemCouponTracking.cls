public class OpportunityLineItemCouponTracking {
    
    /**
     * Tracks when Partner_Payment_OP_Bill_through__c is manually updated
     * to distinguish between Chargebee coupons and manual entries
     */
    public static void trackManualPartnerPayments(List<OpportunityLineItem> newList, Map<Id, OpportunityLineItem> oldMap) {
        for(OpportunityLineItem oli : newList) {
            OpportunityLineItem oldOli = oldMap != null ? oldMap.get(oli.Id) : null;
            
            // Check if Partner_Payment_OP_Bill_through__c was manually changed
            if(oldOli != null && 
               oli.Partner_Payment_OP_Bill_through__c != oldOli.Partner_Payment_OP_Bill_through__c &&
               oli.Partner_Payment_OP_Bill_through__c != null &&
               oli.Partner_Payment_OP_Bill_through__c > 0) {
                
                // Calculate manual partner payment amount
                if(oli.ListPrice != null && oli.Quantity != null) {
                    Decimal listPriceTotal = oli.ListPrice * oli.Quantity;
                    oli.Manual_Partner_Payment_Amount__c = (listPriceTotal * oli.Partner_Payment_OP_Bill_through__c) / 100;
                }
                
                // Set source to manual entry
                oli.Coupon_Source__c = 'Manual Entry';
            }
            
            // If Partner_Payment_OP_Bill_through__c is cleared, reset tracking fields
            if(oldOli != null && 
               oli.Partner_Payment_OP_Bill_through__c == 0 && 
               oldOli.Partner_Payment_OP_Bill_through__c > 0) {
                oli.Manual_Partner_Payment_Amount__c = 0;
                oli.Chargebee_Coupon_Amount__c = 0;
                oli.Coupon_Source__c = 'None';
            }
        }
    }
    
    /**
     * Calculates the total partner payment breakdown for reporting
     */
    public static void calculatePartnerPaymentBreakdown(List<OpportunityLineItem> oliList) {
        for(OpportunityLineItem oli : oliList) {
            // Ensure we have the breakdown calculated
            if(oli.Coupon_Source__c == 'Chargebee Coupon' && oli.Chargebee_Coupon_Amount__c == null) {
                if(oli.ListPrice != null && oli.Quantity != null && oli.Partner_Payment_OP_Bill_through__c != null) {
                    Decimal listPriceTotal = oli.ListPrice * oli.Quantity;
                    oli.Chargebee_Coupon_Amount__c = (listPriceTotal * oli.Partner_Payment_OP_Bill_through__c) / 100;
                }
            }
            
            if(oli.Coupon_Source__c == 'Manual Entry' && oli.Manual_Partner_Payment_Amount__c == null) {
                if(oli.ListPrice != null && oli.Quantity != null && oli.Partner_Payment_OP_Bill_through__c != null) {
                    Decimal listPriceTotal = oli.ListPrice * oli.Quantity;
                    oli.Manual_Partner_Payment_Amount__c = (listPriceTotal * oli.Partner_Payment_OP_Bill_through__c) / 100;
                }
            }
        }
    }
}