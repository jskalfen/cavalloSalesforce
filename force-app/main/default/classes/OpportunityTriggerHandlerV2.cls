public class OpportunityTriggerHandlerV2 extends TriggerHandler {

    private static final String ACCOUNT_TYPE_CLIENT = 'Client';
    private static final String STAGE_CLOSED_WON = 'Closed Won';
    private static final String RECORD_TYPE_NEW_BUSINESS = 'New_Business';
    private static final String OPPORTUNITY_TYPE_RENEWAL = 'Renewal';

    public override void beforeInsert(List<SObject> newList) {
        List<Opportunity> opportunities = (List<Opportunity>) newList;

        Id newBusinessRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
            .get(RECORD_TYPE_NEW_BUSINESS).getRecordTypeId();

        List<Opportunity> renewalOpps = new List<Opportunity>();
        for (Opportunity opp : opportunities) {
            if (isEligibleForRenewalEstimatedValue(opp, newBusinessRecTypeId)) {
                renewalOpps.add(opp);
            }
        }

        if (!renewalOpps.isEmpty()) {
            calculateRenewalEstimatedValue(renewalOpps);
        }
    }

    public override void beforeUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        List<Opportunity> opportunities = (List<Opportunity>) newList;

        Id newBusinessRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
            .get(RECORD_TYPE_NEW_BUSINESS).getRecordTypeId();

        List<Opportunity> renewalOpps = new List<Opportunity>();
        for (Opportunity opp : opportunities) {
            if (isEligibleForRenewalEstimatedValue(opp, newBusinessRecTypeId)) {
                renewalOpps.add(opp);
            }
        }

        if (!renewalOpps.isEmpty()) {
            calculateRenewalEstimatedValue(renewalOpps);
        }
    }

    public override void afterUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        List<Opportunity> opportunities = (List<Opportunity>) newList;
        Map<Id, Opportunity> oldOpportunitiesMap = (Map<Id, Opportunity>) oldMap;
        
        Set<Id> accountIdsToCheck = new Set<Id>();
        
        for(Opportunity opp : opportunities) {
            Opportunity oldOpp = oldOpportunitiesMap.get(opp.Id);
            if (isOpportunityClosedWon(opp, oldOpp)) {
                if (opp.AccountId != null) {
                    accountIdsToCheck.add(opp.AccountId);
                }
            }
        }
        
        updateAccountsToClient(accountIdsToCheck);
    }

    private void updateAccountsToClient(Set<Id> accountIds) {
        if (accountIds.isEmpty()) {
            return;
        }
        
        List<Account> accounts = [
            SELECT Id, Type
            FROM Account
            WHERE Id IN :accountIds
            AND Type != :ACCOUNT_TYPE_CLIENT
        ];
        
        if (accounts.isEmpty()) {
            return;
        }
        
        for (Account acc : accounts) {
            acc.Type = ACCOUNT_TYPE_CLIENT;
        }
        
        update accounts;
    }

    private Boolean isOpportunityClosedWon(Opportunity opp, Opportunity oldOpp) {
        Boolean isNowClosedWon = opp.IsWon == true || opp.StageName == STAGE_CLOSED_WON;
        Boolean wasClosedWon = oldOpp != null && (oldOpp.IsWon == true || oldOpp.StageName == STAGE_CLOSED_WON);
        
        return isNowClosedWon && !wasClosedWon;
    }

    private Boolean isEligibleForRenewalEstimatedValue(Opportunity opp, Id newBusinessRecTypeId) {
        return opp.RecordTypeId == newBusinessRecTypeId &&
            opp.Type == OPPORTUNITY_TYPE_RENEWAL &&
            opp.chargebeeapps__Subscription_Id__c != null &&
            (opp.Year_One__c != null || opp.Year_Two__c != null || opp.Year_Three__c != null);
    }

    /**
     * Calculates Estimated Value ARR for Renewal-type opportunities on the New Business record type.
     * Formula: MAX(0, (Subscription MRR * 12) - (sum of years > 0 / count of years > 0))
     */
    private void calculateRenewalEstimatedValue(List<Opportunity> renewalOpps) {
        Map<Id, List<Opportunity>> subIdToOpps = new Map<Id, List<Opportunity>>();
        for (Opportunity opp : renewalOpps) {
            if (!subIdToOpps.containsKey(opp.chargebeeapps__Subscription_Id__c)) {
                subIdToOpps.put(opp.chargebeeapps__Subscription_Id__c, new List<Opportunity>());
            }
            subIdToOpps.get(opp.chargebeeapps__Subscription_Id__c).add(opp);
        }

        Map<Id, Decimal> subIdToMrr = new Map<Id, Decimal>();
        for (chargebeeapps__CB_Subscription__c sub : [
            SELECT Id, chargebeeapps__MRR__c
            FROM chargebeeapps__CB_Subscription__c
            WHERE Id IN :subIdToOpps.keySet()
        ]) {
            subIdToMrr.put(sub.Id, sub.chargebeeapps__MRR__c != null ? sub.chargebeeapps__MRR__c : 0);
        }

        for (Id subId : subIdToOpps.keySet()) {
            Decimal mrr = subIdToMrr.containsKey(subId) ? subIdToMrr.get(subId) : 0;
            Decimal subscriptionArr = mrr * 12;

            for (Opportunity opp : subIdToOpps.get(subId)) {
                Decimal yearOne   = (opp.Year_One__c   != null && opp.Year_One__c   > 0) ? opp.Year_One__c   : 0;
                Decimal yearTwo   = (opp.Year_Two__c   != null && opp.Year_Two__c   > 0) ? opp.Year_Two__c   : 0;
                Decimal yearThree = (opp.Year_Three__c != null && opp.Year_Three__c > 0) ? opp.Year_Three__c : 0;

                Integer yearCount = (yearOne > 0 ? 1 : 0) + (yearTwo > 0 ? 1 : 0) + (yearThree > 0 ? 1 : 0);
                Decimal average = yearCount > 0 ? (yearOne + yearTwo + yearThree) / yearCount : 0;
                Decimal estimatedValue = subscriptionArr - average;

                opp.Estimated_Value__c = estimatedValue < 0 ? 0 : estimatedValue;
            }
        }
    }
}
