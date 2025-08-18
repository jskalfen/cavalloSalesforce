@isTest
public class PartnerMarginService_Test {

    @testSetup
    static void setup() {
        Account partnerAccount1 = TestUtils.createPartnerAccount();
        partnerAccount1.Name = 'Test Partner Account 1';
        update partnerAccount1;

        Account partnerAccount2 = TestUtils.createPartnerAccount();
        partnerAccount2.Name = 'Test Partner Account 2';
        update partnerAccount2;

        Account clientAccount = TestUtils.createAccount();
        
        Opportunity opp1 = TestUtils.createOpportunity(clientAccount.Id, partnerAccount1.Id);
        Opportunity opp2 = TestUtils.createOpportunity(clientAccount.Id, partnerAccount2.Id);

        Partner_Tier__c partnerTier1 = TestUtils.createPartnerTier(partnerAccount1.Id);
        Partner_Tier__c partnerTier2 = TestUtils.createPartnerTier(partnerAccount2.Id);
        partnerTier2.Partner_Tier__c = 'Silver';
        update partnerTier2;

        Partner_Client_Relationship__c partnerClientRel1 = TestUtils.createPartnerClientRelationship(partnerAccount1.Id, clientAccount.Id);
        Partner_Client_Relationship__c partnerClientRel2 = TestUtils.createPartnerClientRelationship(partnerAccount2.Id, clientAccount.Id);
        partnerClientRel2.Partner_Client_Margin_Eligibility__c = 'Inactive';
        update partnerClientRel2;

        Product2 prod = TestUtils.createProduct('Test Product');
        PricebookEntry pbe = TestUtils.createPricebookEntry(opp1.Pricebook2Id, prod.Id, 100);
        TestUtils.createOpportunityLineItem(opp1.Id, pbe.Id);
        TestUtils.createOpportunityLineItem(opp2.Id, pbe.Id);
    }

    @isTest
    static void testCreatePartnerMargin() {
        List<Opportunity> oppList = [SELECT Id, AccountId, Partner__c, StageName, chargebeeapps__Subscription_Id__c, Partner__r.Bill_through_Partner__c FROM Opportunity];
        List<OpportunityLineItem> oppLineList = [SELECT Id, OpportunityId, Quantity, TotalPrice, Recurring_Revenue__c, Subscription_Product_Type__c, Licensing__c, Perpetual_Type__c, ARR_MFC__c, ProductCode, Product_Name__c FROM OpportunityLineItem];

        Test.startTest();
        PartnerMarginService.createPartnerMargin(oppList, oppLineList);
        Test.stopTest();
    }

    @isTest
    static void testDeletePartnerMargin() {
        List<Opportunity> oppList = [SELECT Id FROM Opportunity LIMIT 1];
        Set<Id> oppIdSet = new Set<Id>();
        for (Opportunity opp : oppList) {
            oppIdSet.add(opp.Id);
        }

        Test.startTest();
        PartnerMarginService.deletePartnerMargin(oppIdSet);
        Test.stopTest();
    }

    @isTest
    static void testUpdatePartnerForInactiveTiers() {
        List<Account> partnerAccounts = [SELECT Id FROM Account WHERE Type = 'Partner - Prospective' LIMIT 2];
        Set<Id> partnerAccountIds = new Set<Id>();
        for (Account acc : partnerAccounts) {
            partnerAccountIds.add(acc.Id);
        }

        Test.startTest();
        PartnerMarginService.updatePartnerForInactiveTiers(partnerAccountIds);
        Test.stopTest();
    }

    @isTest
    static void testClonePartnerMargin() {
        List<Partner_Margin__c> partnerMargins = [SELECT Id FROM Partner_Margin__c LIMIT 1];

        Test.startTest();
        List<Id> clonedPartnerMarginIds = PartnerMarginService.clonePartnerMargin(partnerMargins);
        Test.stopTest();
    }

    @isTest
    static void testMergePartnerMargin() {
        List<Partner_Margin__c> partnerMargins = [SELECT Id, CB_Subscription_ID__c, Client__c, Partner__c, Partner_Billing_Type__c, Partner_Tier__c, Partner_Margin_Duration__c, Software_Partner_Margin_Y1__c, Software_Partner_Margin_Renewal__c, Enhancement_Partner_Margin_Renewal__c FROM Partner_Margin__c LIMIT 2];

        if (partnerMargins.size() == 2) {
            Partner_Margin__c p1 = partnerMargins[0];
            Partner_Margin__c p2 = partnerMargins[1];

            Test.startTest();
            Partner_Margin__c mergedPM = PartnerMarginService.mergePartnerMargin(p1, p2);
            Test.stopTest();
        }
    }
}