public class LeadTriggerHandler extends TriggerHandler {

    // Constants for Lead Outcome picklist values
    private static final String OUTCOME_CONVERTED = 'Converted';
    // Constants for HubSpot Lifecycle Stage and Lead Status
    private static final String HUBSPOT_SALES_ACCEPTED_LEAD = 'Sales Accepted Lead';

    public override void beforeInsert(List<SObject> newList) {
        List<Lead> leads = (List<Lead>) newList;
        for(Lead lead : leads) {
            handleLeadConversion(lead, null);
            handleHubSpotLifecycleStage(lead);
        }
    }

    private void handleHubSpotLifecycleStage(Lead lead) {
        if (lead.New_HubSpot_Lifecycle_Stage__c == HUBSPOT_SALES_ACCEPTED_LEAD) {
            lead.Status = HUBSPOT_SALES_ACCEPTED_LEAD;
        }
    }

    public override void beforeUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        List<Lead> leads = (List<Lead>) newList;
        Map<Id, Lead> oldLeadsMap = (Map<Id, Lead>) oldMap;
        
        for(Lead lead : leads) {
            Lead oldLead = oldLeadsMap.get(lead.Id);
            handleLeadConversion(lead, oldLead);
        }
    }

    public override void afterInsert(List<SObject> newList) {
    }

    public override void afterUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
    }

    private void handleLeadConversion(Lead lead, Lead oldLead) {
        if (isLeadConverted(lead, oldLead)) {
            lead.Lead_Outcome__c = OUTCOME_CONVERTED;
        }
    }

    private Boolean isLeadConverted(Lead lead, Lead oldLead) {
        if (oldLead != null) {
            return !oldLead.IsConverted && lead.IsConverted;
        }
        return lead.IsConverted;
    }
}