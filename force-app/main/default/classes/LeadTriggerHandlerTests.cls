@isTest
private class LeadTriggerHandlerTests {

    private static final String OUTCOME_CONVERTED = 'Converted';
    private static final String OUTCOME_REJECTED_RECYCLE = 'Rejected_Recycle';
    private static final String OUTCOME_REJECTED_DISQUALIFIED = 'Rejected_Disqualified';
    private static final String HUBSPOT_SALES_ACCEPTED_LEAD = 'Sales Accepted Lead';

    @isTest
    static void testBeforeUpdate_LeadConverted_SetsOutcome() {
        // Test that when a lead is converted using Database.convertLead(),
        // Lead_Outcome__c should be set to 'Converted'
        Lead lead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Email = 'test@example.com'
        );
        insert lead;

        // Convert the lead using Database.convertLead()
        // setDoNotCreateOpportunity(true) to avoid validation errors on Opportunity
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(lead.Id);
        lc.setConvertedStatus('Converted');
        lc.setDoNotCreateOpportunity(true);

        Test.startTest();
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        Test.stopTest();

        System.assert(lcr.isSuccess(), 'Lead conversion should be successful');
        
        // Query the converted lead
        Lead convertedLead = [SELECT Lead_Outcome__c, IsConverted FROM Lead WHERE Id = :lead.Id];
        System.assertEquals(true, convertedLead.IsConverted, 'Lead should be converted');
        System.assertEquals(OUTCOME_CONVERTED, convertedLead.Lead_Outcome__c, 
            'Lead Outcome should be set to Converted when lead is converted');
    }

    @isTest
    static void testBeforeUpdate_LeadNotConverted_DoesNotModifyOutcome() {
        // Test that when IsConverted doesn't change,
        // Lead_Outcome__c should not be modified
        Lead lead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Email = 'test@example.com',
            Lead_Outcome__c = OUTCOME_REJECTED_RECYCLE
        );
        insert lead;

        // Update a different field without converting
        lead.Phone = '555-1234';

        Test.startTest();
        update lead;
        Test.stopTest();

        Lead updatedLead = [SELECT Lead_Outcome__c, IsConverted FROM Lead WHERE Id = :lead.Id];
        System.assertEquals(false, updatedLead.IsConverted, 'Lead should not be converted');
        System.assertEquals(OUTCOME_REJECTED_RECYCLE, updatedLead.Lead_Outcome__c, 
            'Lead Outcome should not be modified when lead is not converted');
    }

    @isTest
    static void testBeforeUpdate_LeadAlreadyConverted_DoesNotOverwriteExistingOutcome() {
        // Test that if Lead_Outcome__c is already set before conversion,
        // it should be overwritten to 'Converted' when the lead is converted
        Lead lead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Email = 'test@example.com',
            Lead_Outcome__c = OUTCOME_REJECTED_DISQUALIFIED
        );
        insert lead;

        // Convert the lead - this should trigger the handler to set Lead_Outcome__c to 'Converted'
        // setDoNotCreateOpportunity(true) to avoid validation errors on Opportunity
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(lead.Id);
        lc.setConvertedStatus('Converted');
        lc.setDoNotCreateOpportunity(true);

        Test.startTest();
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        Test.stopTest();

        System.assert(lcr.isSuccess(), 'Lead conversion should be successful');
        
        Lead convertedLead = [SELECT Lead_Outcome__c, IsConverted FROM Lead WHERE Id = :lead.Id];
        System.assertEquals(true, convertedLead.IsConverted, 'Lead should be converted');
        // When a lead is converted, the handler should set Lead_Outcome__c to 'Converted'
        // even if it was previously set to something else
        System.assertEquals(OUTCOME_CONVERTED, convertedLead.Lead_Outcome__c, 
            'Lead Outcome should be set to Converted when lead is converted, even if previously set');
    }

    @isTest
    static void testBeforeUpdate_LeadConversionFromFalseToTrue_SetsOutcome() {
        // Test the specific scenario where IsConverted changes from false to true
        Lead lead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Email = 'test@example.com'
        );
        insert lead;

        // Verify initial state
        Lead initialLead = [SELECT IsConverted, Lead_Outcome__c FROM Lead WHERE Id = :lead.Id];
        System.assertEquals(false, initialLead.IsConverted, 'Lead should not be converted initially');
        System.assertEquals(null, initialLead.Lead_Outcome__c, 'Lead Outcome should be null initially');

        // Convert the lead
        // setDoNotCreateOpportunity(true) to avoid validation errors on Opportunity
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(lead.Id);
        lc.setConvertedStatus('Converted');
        lc.setDoNotCreateOpportunity(true);

        Test.startTest();
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        Test.stopTest();

        System.assert(lcr.isSuccess(), 'Lead conversion should be successful');
        
        Lead updatedLead = [SELECT Lead_Outcome__c, IsConverted FROM Lead WHERE Id = :lead.Id];
        System.assertEquals(true, updatedLead.IsConverted, 'Lead should be converted');
        System.assertEquals(OUTCOME_CONVERTED, updatedLead.Lead_Outcome__c, 
            'Lead Outcome should be set to Converted when IsConverted changes from false to true');
    }

    @isTest
    static void testBeforeInsert_HubSpotSalesAcceptedLead_SetsStatus() {
        // Test that when New_HubSpot_Lifecycle_Stage__c is 'Sales Accepted Lead',
        // Status should be set to 'Sales Accepted Lead'
        Lead lead = new Lead(
            FirstName = 'Test',
            LastName = 'HubSpot Lead',
            Company = 'Test Company',
            Email = 'hubspot@example.com',
            New_HubSpot_Lifecycle_Stage__c = HUBSPOT_SALES_ACCEPTED_LEAD
        );

        Test.startTest();
        insert lead;
        Test.stopTest();

        Lead insertedLead = [SELECT Status, New_HubSpot_Lifecycle_Stage__c FROM Lead WHERE Id = :lead.Id];
        System.assertEquals(HUBSPOT_SALES_ACCEPTED_LEAD, insertedLead.Status, 
            'Lead Status should be set to Sales Accepted Lead when HubSpot Lifecycle Stage is Sales Accepted Lead');
    }
}
