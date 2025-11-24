public class QuoteTriggerHandlerV2 extends TriggerHandler {

    public override void beforeInsert(List<SObject> newList) {
        List<Quote> quotes = (List<Quote>) newList;
        
        Set<Id> opportunityIds = new Set<Id>();
        for(Quote quote : quotes) {
            if (quote.OpportunityId != null) {
                opportunityIds.add(quote.OpportunityId);
            }
        }
        
        setQuoteNamesFromOpportunities(quotes, opportunityIds);
    }

    private void setQuoteNamesFromOpportunities(List<Quote> quotes, Set<Id> opportunityIds) {
        if (opportunityIds.isEmpty()) {
            return;
        }

        Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>([
            SELECT Id, Name
            FROM Opportunity
            WHERE Id IN :opportunityIds
        ]);
        
        for(Quote quote : quotes) {
            if (quote.OpportunityId != null && opportunityMap.containsKey(quote.OpportunityId)) {
                quote.Name = opportunityMap.get(quote.OpportunityId).Name;
            }
        }
    }
}