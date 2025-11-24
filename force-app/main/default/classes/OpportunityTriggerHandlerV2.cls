public class OpportunityTriggerHandlerV2 extends TriggerHandler {

    private static final String ACCOUNT_TYPE_CLIENT = 'Client';
    private static final String STAGE_CLOSED_WON = 'Closed Won';

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
}
