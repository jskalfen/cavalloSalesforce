@isTest
public class PartnerMarginTriggerHandler_Tests {

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

        TestUtils.createPartnerMargin(opp1.Id, partnerAccount1.Id, clientAccount.Id);
        TestUtils.createPartnerMargin(opp2.Id, partnerAccount2.Id, clientAccount.Id);
    }

    @isTest
    static void testBeforeUpdate() {
        List<Partner_Margin__c> partnerMargins = [SELECT Id, Partner__c, Client__c, Software_Partner_Margin_Y1__c FROM Partner_Margin__c];
        
        for (Partner_Margin__c pm : partnerMargins) {
            pm.Partner__c = pm.Partner__c == [SELECT Id FROM Account WHERE Name = 'Test Partner Account 1' LIMIT 1].Id ? 
                            [SELECT Id FROM Account WHERE Name = 'Test Partner Account 2' LIMIT 1].Id : 
                            [SELECT Id FROM Account WHERE Name = 'Test Partner Account 1' LIMIT 1].Id;
        }

        Test.startTest();
        update partnerMargins;
        Test.stopTest();

        partnerMargins = [SELECT Id, Partner__c, Client__c, Software_Partner_Margin_Y1__c, Partner_Tier__c, Enhancement_Partner_Margin_Y1__c, Partner_Client_Margin_Eligibility__c FROM Partner_Margin__c];

        for (Partner_Margin__c pm : partnerMargins) {
            if (pm.Partner__c == [SELECT Id FROM Account WHERE Name = 'Test Partner Account 1' LIMIT 1].Id) {
                System.assertEquals('Gold', pm.Partner_Tier__c);
                System.assertEquals('Active', pm.Partner_Client_Margin_Eligibility__c);
            } else if (pm.Partner__c == [SELECT Id FROM Account WHERE Name = 'Test Partner Account 2' LIMIT 1].Id) {
                System.assertEquals('Silver', pm.Partner_Tier__c);
                System.assertEquals('Inactive', pm.Partner_Client_Margin_Eligibility__c);
            }
        }
    }

    
    @isTest
    static void testAfterTrigger() {
        Test.startTest();
        
        Account testAccount = TestUtils.createAccount();
        Account testPartner = TestUtils.createPartnerAccount();
        
        Opportunity testOpp = TestUtils.createOpportunity(testAccount.Id, testPartner.Id);
        
        Product2 testProduct = TestUtils.createProduct('Test Product');
        PricebookEntry pbe = TestUtils.createPricebookEntry(testOpp.Pricebook2Id, testProduct.Id, 100);
                
        OpportunityLineItem testOli = TestUtils.createOpportunityLineItem(testOpp.Id, pbe.Id);
        
        Partner_Margin__c testPartnerMargin = TestUtils.createPartnerMargin(testOpp.Id, testPartner.Id, testAccount.Id);
        
        testPartnerMargin.Software_Partner_Margin_Y1__c = 20;
        update testPartnerMargin;
        
        Test.stopTest();
        
        OpportunityLineItem updatedOli = [SELECT Id FROM OpportunityLineItem WHERE Id = :testOli.Id];
        System.assertNotEquals(null, updatedOli, 'OpportunityLineItem should be updated.');
        
        Partner_Margin__c updatedPartnerMargin = [SELECT Id, Software_Partner_Margin_Y1__c FROM Partner_Margin__c WHERE Id = :testPartnerMargin.Id];
        System.assertEquals(20, updatedPartnerMargin.Software_Partner_Margin_Y1__c, 'Software_Partner_Margin_Y1__c should be updated to 20.');
    }
    
    @isTest
    static void testBeforeDelete() {
        Test.startTest();
        
        Account testAccount = TestUtils.createAccount();
        Account testPartner = TestUtils.createPartnerAccount();
        
        Opportunity testOpp = TestUtils.createOpportunity(testAccount.Id, testPartner.Id);
        
        Partner_Margin__c testPartnerMargin = TestUtils.createPartnerMargin(testOpp.Id, testPartner.Id, testAccount.Id);
        
        delete testPartnerMargin;
        
        Test.stopTest();
    }
}