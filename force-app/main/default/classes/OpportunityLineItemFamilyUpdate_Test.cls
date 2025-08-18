@isTest
public class OpportunityLineItemFamilyUpdate_Test {
    @isTest
	static void testAddEnhancementItem() {
                
        Account a = new Account(Name = 'Ray test', Type = 'Other', Customer_Class__c = 'Other');
        insert a;
        
        Opportunity opp = new Opportunity(AccountId = a.Id,
                                          CloseDate = Date.today(),
                                          StageName = 'Sandbox',
                                          Name = 'Ray Test',
                                          Direct_v_Partner__c = 'Partner',
                                          Existing_GP_or_New_GP__c = 'Existing GP'
                                         
                                         );
        insert opp;
        
        Product2 prod1 = new Product2(Name = 'Ray Test',ProductCode='Product abc');
        Product2 prod2 = new Product2(Name = 'Ray Test Enhancement',ProductCode='Product ab1c');
        insert new List<Product2> {prod1, prod2};
            
        PricebookEntry pbe1 = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(),
                                                 Product2Id = prod1.Id,
                                                 UnitPrice = 1,
                                                 IsActive = true);
        PricebookEntry pbe2 = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(),
                                                 Product2Id = prod2.Id,
                                                 UnitPrice = 1,
                                                 IsActive = true);
        insert new List<PricebookEntry> {pbe1, pbe2};
            
        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = opp.Id,
                                                          PricebookEntryId = pbe1.Id,
                                                          Quantity = 1,
                                                          UnitPrice = 1);
        Test.startTest();
        insert oli;
        Test.stopTest();
        
        //System.assertEquals(2, [select count() from OpportunityLineItem where OpportunityId = :opp.Id]);
    }
}