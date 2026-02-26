@isTest
private class LeadAutoConvertServiceTest {

    @TestSetup
    static void setup() {
        // Create an Account
        Account acc = new Account(Name = 'Existing Account');
        insert acc;

        // Create a Contact with a known email, linked to the Account
        Contact con = new Contact(
            FirstName = 'Existing',
            LastName = 'Contact',
            Email = 'existing@example.com',
            AccountId = acc.Id
        );
        insert con;
    }

    // ─── Positive Tests ────────────────────────────────────────────────

    @isTest
    static void testAutoConvert_MatchingEmail_ConvertsLeadToExistingContact() {
        Contact existingContact = [SELECT Id, AccountId FROM Contact WHERE Email = 'existing@example.com' LIMIT 1];

        Lead ld = new Lead(
            FirstName = 'New',
            LastName = 'Lead',
            Company = 'Test Company',
            Email = 'existing@example.com'
        );

        Test.startTest();
        insert ld;
        Test.stopTest();

        // Lead should be converted
        Lead converted = [SELECT IsConverted, ConvertedContactId, ConvertedAccountId, Lead_Outcome__c
                          FROM Lead WHERE Id = :ld.Id];
        System.assertEquals(true, converted.IsConverted,
            'Lead should be auto-converted when a matching contact exists');
        System.assertEquals(existingContact.Id, converted.ConvertedContactId,
            'Lead should be merged into the existing contact');
        System.assertEquals(existingContact.AccountId, converted.ConvertedAccountId,
            'Lead should be merged into the existing account');
        System.assertEquals('Converted', converted.Lead_Outcome__c,
            'Lead Outcome should be set to Converted');
    }

    @isTest
    static void testAutoConvert_NoOpportunityCreated() {
        Contact existingContact = [SELECT Id, AccountId FROM Contact WHERE Email = 'existing@example.com' LIMIT 1];

        Lead ld = new Lead(
            FirstName = 'New',
            LastName = 'Lead',
            Company = 'Test Company',
            Email = 'existing@example.com'
        );

        Test.startTest();
        insert ld;
        Test.stopTest();

        // No opportunity should have been created
        List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE AccountId = :existingContact.AccountId];
        System.assertEquals(0, opps.size(),
            'No opportunity should be created during auto-conversion');
    }

    @isTest
    static void testAutoConvert_CaseInsensitiveEmail_ConvertsLead() {
        Lead ld = new Lead(
            FirstName = 'New',
            LastName = 'Lead',
            Company = 'Test Company',
            Email = 'EXISTING@EXAMPLE.COM'
        );

        Test.startTest();
        insert ld;
        Test.stopTest();

        Lead converted = [SELECT IsConverted FROM Lead WHERE Id = :ld.Id];
        System.assertEquals(true, converted.IsConverted,
            'Lead should be auto-converted with case-insensitive email match');
    }

    // ─── Negative Tests ────────────────────────────────────────────────

    @isTest
    static void testAutoConvert_NoMatchingEmail_DoesNotConvert() {
        Lead ld = new Lead(
            FirstName = 'New',
            LastName = 'Lead',
            Company = 'Test Company',
            Email = 'nomatch@example.com'
        );

        Test.startTest();
        insert ld;
        Test.stopTest();

        Lead inserted = [SELECT IsConverted FROM Lead WHERE Id = :ld.Id];
        System.assertEquals(false, inserted.IsConverted,
            'Lead should not be auto-converted when no matching contact exists');
    }

    @isTest
    static void testAutoConvert_BlankEmail_DoesNotConvert() {
        Lead ld = new Lead(
            FirstName = 'New',
            LastName = 'Lead',
            Company = 'Test Company'
        );

        Test.startTest();
        insert ld;
        Test.stopTest();

        Lead inserted = [SELECT IsConverted FROM Lead WHERE Id = :ld.Id];
        System.assertEquals(false, inserted.IsConverted,
            'Lead should not be auto-converted when email is blank');
    }

    // ─── Bulk Test ─────────────────────────────────────────────────────

    @isTest
    static void testAutoConvert_BulkLeads_MixOfMatchAndNoMatch() {
        Contact existingContact = [SELECT Id, AccountId FROM Contact WHERE Email = 'existing@example.com' LIMIT 1];

        List<Lead> leads = new List<Lead>();

        // Lead that should be converted (matching email)
        leads.add(new Lead(
            FirstName = 'Match',
            LastName = 'Lead',
            Company = 'Company A',
            Email = 'existing@example.com'
        ));

        // Lead that should NOT be converted (different email)
        leads.add(new Lead(
            FirstName = 'NoMatch',
            LastName = 'Lead',
            Company = 'Company B',
            Email = 'different@example.com'
        ));

        // Lead that should NOT be converted (no email)
        leads.add(new Lead(
            FirstName = 'NoEmail',
            LastName = 'Lead',
            Company = 'Company C'
        ));

        Test.startTest();
        insert leads;
        Test.stopTest();

        Lead matchLead = [SELECT IsConverted, ConvertedContactId FROM Lead WHERE Id = :leads[0].Id];
        System.assertEquals(true, matchLead.IsConverted,
            'Lead with matching email should be auto-converted');
        System.assertEquals(existingContact.Id, matchLead.ConvertedContactId,
            'Lead should be merged into the existing contact');

        Lead noMatchLead = [SELECT IsConverted FROM Lead WHERE Id = :leads[1].Id];
        System.assertEquals(false, noMatchLead.IsConverted,
            'Lead without matching email should not be auto-converted');

        Lead noEmailLead = [SELECT IsConverted FROM Lead WHERE Id = :leads[2].Id];
        System.assertEquals(false, noEmailLead.IsConverted,
            'Lead without email should not be auto-converted');
    }
}

