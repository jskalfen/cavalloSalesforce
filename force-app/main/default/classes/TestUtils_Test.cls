@isTest
public class TestUtils_Test {

    @isTest
    static void testCreateAccount() {
        Account acc = TestUtils.createAccount();
        System.assertNotEquals(null, acc.Id, 'Account should be inserted');
    }

    @isTest
    static void testCreatePartnerAccount() {
        Account acc = TestUtils.createPartnerAccount();
        System.assertNotEquals(null, acc.Id, 'Partner Account should be inserted');
    }

    @isTest
    static void testCreateOpportunity() {
        Account acc = TestUtils.createAccount();
        Account partnerAcct = TestUtils.createAccount();
        
        Opportunity opp = TestUtils.createOpportunity(acc.Id, partnerAcct.Id);
        System.assertNotEquals(null, opp.Id, 'Opportunity should be inserted');
    }

    @isTest
    static void testCreateProduct() {
        Product2 prod = TestUtils.createProduct('Test Product');
        System.assertNotEquals(null, prod.Id, 'Product should be inserted');
    }

    @isTest
    static void testCreatePricebookEntry() {
        Account acct = TestUtils.createAccount();
        Account partnerAcct = TestUtils.createAccount();
        
        Opportunity opp = TestUtils.createOpportunity(acct.Id, partnerAcct.Id);
        Product2 prod = TestUtils.createProduct('Test Product');

        Test.startTest();
            PricebookEntry pbe = TestUtils.createPricebookEntry(opp.Pricebook2Id, prod.Id, 100.0);
        Test.stopTest();
        System.assertNotEquals(null, pbe, 'PricebookEntry should be created successfully');

    }

    @isTest
    static void testCreateOpportunityLineItem() {
        Account acc = TestUtils.createAccount();
        Account partnerAcct = TestUtils.createAccount();
        Opportunity opp = TestUtils.createOpportunity(acc.Id, partnerAcct.Id);
        Product2 prod = TestUtils.createProduct('Test Product');
        PricebookEntry pbe = TestUtils.createPricebookEntry(opp.Pricebook2Id, prod.Id, 100.0);

        OpportunityLineItem oli = TestUtils.createOpportunityLineItem(opp.Id, pbe.Id);
        System.assertNotEquals(null, oli.Id, 'Opportunity Line Item should be inserted');
    }

    @isTest
    static void testCreatePartnerTier() {
        Account partnerAcct = TestUtils.createAccount();
        Partner_Tier__c tier = TestUtils.createPartnerTier(partnerAcct.Id);
        System.assertNotEquals(null, tier.Id, 'Partner Tier should be inserted');
    }

    @isTest
    static void testCreatePartnerClientRelationship() {
        Account partnerAcct = TestUtils.createAccount();
        Account clientAcct = TestUtils.createAccount();
        Partner_Client_Relationship__c rel = TestUtils.createPartnerClientRelationship(partnerAcct.Id, clientAcct.Id);
        System.assertNotEquals(null, rel.Id, 'Partner Client Relationship should be inserted');
    }
}