@isTest(SeeAllData=true)
public class TestUtils {

    public static Account createAccount() {
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.Type = 'Client - Direct'; 
        insert acc;
        return acc;
    }

    public static Account createPartnerAccount() {
        Account acc = new Account();
        acc.Name = 'Test Partner Account';
        acc.Type = 'Partner - Prospective';
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
        .get('Alliance_Partner').getRecordTypeId();
        acc.Active_Partner_Tier__c = 'Gold'; 
        insert acc;
        return acc;
    }

    public static Opportunity createOpportunity(Id accountId, Id partnerId) {
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opportunity';
        opp.AccountId = accountId;
        opp.Partner__c = partnerId;
        opp.StageName = 'Prospecting'; 
        opp.CloseDate = Date.today().addDays(30);
        insert opp;
        opp = [SELECT Id, Name, AccountId, Partner__c, StageName, CloseDate, Pricebook2Id FROM Opportunity WHERE Id =: opp.Id LIMIT 1];
        return opp;
    }

    public static Product2 createProduct(String productName) {
        Product2 prod = new Product2();
        prod.Name = productName;
        insert prod;
        return prod;
    }

    public static PricebookEntry createPricebookEntry(Id pricebookId, Id productId, Decimal unitPrice) {
        insert new PriceBookEntry(Product2Id=productId, Pricebook2Id=Test.getStandardPricebookId(), UnitPrice=0);

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = productId,
            UnitPrice = unitPrice,
            IsActive = true
        );

        insert pbe;
        return pbe;

    }

    public static OpportunityLineItem createOpportunityLineItem(Id opportunityId, Id pricebookEntryId) {
        OpportunityLineItem oli = new OpportunityLineItem();
        oli.OpportunityId = opportunityId;
        oli.PricebookEntryId = pricebookEntryId;
        oli.Quantity = 1;
        oli.UnitPrice = 100.00; 
        insert oli;
        return oli;
    }

    public static Partner_Margin__c createPartnerMargin(Id oppId, Id partnerId, Id acctId){
        Partner_Margin__c testPartnerMargin = new Partner_Margin__c(
            Opportunity__c = oppId,
            Partner__c = partnerId,
            Software_Partner_Margin_Y1__c = 10,
            Enhancement_Partner_Margin_Y1__c = 5,
            Partner_Billing_Type__c = 'Direct',
            Client__c = acctId,
            Partner_Tier__c = 'Gold'
        );
        insert testPartnerMargin;
        return testPartnerMargin;
    }

    public static Partner_Tier__c createPartnerTier(Id partnerId) {
        Partner_Tier__c tier = new Partner_Tier__c();
        tier.Partner__c = partnerId;
        tier.PartnerTier_Status__c = 'Active';
        tier.Partner_Tier__c = 'Gold';
        tier.Partner_Tier_Start_Date__c = System.today();
        insert tier;
        return tier;
    }    

    public static Partner_Client_Relationship__c createPartnerClientRelationship(Id partnerId, Id clientId) {
        Partner_Client_Relationship__c rel = new Partner_Client_Relationship__c();
        rel.Partner__c = partnerId;
        rel.Client__c = clientId;
        rel.Partner_Client_Margin_Eligibility__c = 'Active';
        rel.Margin_Start_Date__c = System.today();
        rel.Partner_of_Record_Status__c = 'Current';
        insert rel;
        return rel;
    }
    
}