trigger CBOpportunityCouponTrigger on chargebeeapps__CB_Opportunity_Coupon__c (after insert, after update) {
    if (Trigger.isInsert) {
        if (Trigger.isAfter) {
            CBOpportunityCouponTriggerHandler.onAfterInsert(Trigger.new);
        }
    } else if (Trigger.isUpdate) {
        if (Trigger.isAfter) {
            CBOpportunityCouponTriggerHandler.onAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}
