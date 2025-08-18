@isTest
private class QuoteLineItemTriggerHandler_Tests {
    static testMethod void testAddEnhancementItem() {
        QuoteLineItemTriggerHandler.fa.Add_Enhancement_Items__c = true; 
        
        Account a = new Account(Name = 'Ray test', Type = 'Other', Customer_Class__c = 'Other');
        insert a;
        
        Opportunity opp = new Opportunity(AccountId = a.Id,
                                          CloseDate = Date.today(),
                                          StageName = 'Sandbox',
                                          Name = 'Ray Test',
                                          Existing_GP_or_New_GP__c = 'Existing GP',
                                          Direct_v_Partner__c = 'Partner');
        insert opp;
        
        Quote q = new Quote(OpportunityId = opp.Id,
                            Name = 'Ray Test',
                            Pricebook2Id = Test.getStandardPricebookId());
        insert q;
        
        Product2 prod1 = new Product2(Name = 'CONSULTING - PM SERVICES', ProductCode= 'RayTest Consulting');
        Product2 prod2 = new Product2(Name = 'Solutions PM Services', ProductCode = 'Solutions PM Services');
        Product2 prod3 = new Product2(Name = 'PM Services', ProductCode = 'Consulting PM Services');
        //insert new List<Product2> {prod1, prod2};
        insert prod1;
        insert prod2;
        insert prod3;
       
        Pricebook2 pb = new Pricebook2(Name = 'Test Standard Book', IsActive = true, Description = 'test standard book');
        insert pb;
            
        PricebookEntry pbe1 = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(),
                                                 Product2Id = prod1.Id,
                                                 UnitPrice = 1,
                                                 IsActive = true);
        PricebookEntry pbe2 = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(),
                                                 Product2Id = prod2.Id,
                                                 UnitPrice = 1,
                                                 IsActive = true);
        PricebookEntry pbe3 = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(),
                                                 Product2Id = prod3.Id,
                                                 UnitPrice = 1,
                                                 IsActive = true);
        insert new List<PricebookEntry> {pbe1, pbe2, pbe3};
            
        QuoteLineItem qli = new QuoteLineItem(QuoteId = q.Id,
                                              PricebookEntryId = pbe1.Id,
                                              Quantity = 1,
                                              UnitPrice = 1);
        
        QuoteLineItem qli2 = new QuoteLineItem(QuoteId = q.Id,
                                              PricebookEntryId = pbe2.Id,
                                              Quantity = 1,
                                              UnitPrice = 1);
        QuoteLineItem qli3 = new QuoteLineItem(QuoteId = q.Id,
                                              PricebookEntryId = pbe3.Id,
                                              Quantity = 1,
                                              UnitPrice = 1);
        List<QuoteLineItem> qliList = new List<QuoteLineItem>{qli,qli2,qli3};
        Test.startTest();
        QuoteLineItemTriggerHandler.formatCurrency(100);
        /*insert qli;
        update qli;
        insert qli2;
        insert qli3;*/
        insert qliList;
        Test.stopTest();
        
        System.assertEquals(3, [select count() from QuoteLineItem where QuoteId = :q.Id]);
    }
    
    static testMethod void testAddEnhancementItem2() {
        QuoteLineItemTriggerHandler.fa.Add_Enhancement_Items__c = true; 
        
        Account a = new Account(Name = 'Ray test', Type = 'Other', Customer_Class__c = 'Other');
        insert a;
        
        Opportunity opp = new Opportunity(AccountId = a.Id,
                                          CloseDate = Date.today(),
                                          StageName = 'Sandbox',
                                          Name = 'Ray Test',
                                          Existing_GP_or_New_GP__c = 'Existing GP',
                                          Direct_v_Partner__c = 'Partner');
        insert opp;
        
        
        Quote q = new Quote(OpportunityId = opp.Id,
                            Name = 'Ray Test',
                            Pricebook2Id = Test.getStandardPricebookId());
        insert q;
        
        Product2 prod1 = new Product2(Name = 'CONSULTING', ProductCode= 'RayTest Consulting');
        Product2 prod2 = new Product2(Name = 'PM Services', ProductCode = 'RayTest Consulting');
        Product2 prod3 = new Product2(Name = 'Solutions PM Services', ProductCode = 'Solutions PM Services');
        Product2 prod4 = new Product2(Name = 'Solutions', ProductCode = 'Solutions PM Services');
        //insert new List<Product2> {prod1, prod2};
        insert prod1;
        insert prod2;
        insert prod3;
        insert prod4;
       
        Pricebook2 pb = new Pricebook2(Name = 'Test Standard Book', IsActive = true, Description = 'test standard book');
        insert pb;
        
        
        PricebookEntry pbe1 = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(),
                                                 Product2Id = prod1.Id,
                                                 UnitPrice = 1,
                                                 IsActive = true);
        PricebookEntry pbe2 = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(),
                                                 Product2Id = prod2.Id,
                                                 UnitPrice = 1,
                                                 IsActive = true);
        PricebookEntry pbe3 = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(),
                                                 Product2Id = prod3.Id,
                                                 UnitPrice = 1,
                                                 IsActive = true);
        PricebookEntry pbe4 = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(),
                                                 Product2Id = prod4.Id,
                                                 UnitPrice = 1,
                                                 IsActive = true);
        insert new List<PricebookEntry> {pbe1, pbe2, pbe3, pbe4};
            
        
        QuoteLineItem qli1 = new QuoteLineItem(QuoteId = q.Id,
                                              PricebookEntryId = pbe1.Id,
                                              Quantity = 1,
                                              UnitPrice = 1);
        QuoteLineItem qli2 = new QuoteLineItem(QuoteId = q.Id,
                                              PricebookEntryId = pbe2.Id,
                                              Quantity = 1,
                                              UnitPrice = 1);
       QuoteLineItem qli3 = new QuoteLineItem(QuoteId = q.Id,
                                              PricebookEntryId = pbe3.Id,
                                              Quantity = 1,
                                              UnitPrice = 1);
        QuoteLineItem qli4 = new QuoteLineItem(QuoteId = q.Id,
                                              PricebookEntryId = pbe4.Id,
                                              Quantity = 1,
                                              UnitPrice = 1);
        List<QuoteLineItem> qliList = new List<QuoteLineItem>{qli1, qli2, qli3, qli4};
        Test.startTest(); 
        QuoteLineItemTriggerHandler.formatCurrency(100);
        insert qliList; 
        update qliList;
        Test.stopTest();
        
        System.assertEquals(4, [select count() from QuoteLineItem where QuoteId = :q.Id]);
    }
    
    static testMethod void testAddEnhancementItem3() {
        QuoteLineItemTriggerHandler.fa.Add_Enhancement_Items__c = true; 
        
        Account a = new Account(Name = 'Ray test', Type = 'Other', Customer_Class__c = 'Other');
        insert a;
        
        Opportunity opp = new Opportunity(AccountId = a.Id,
                                          CloseDate = Date.today(),
                                          StageName = 'Sandbox',
                                          Name = 'Ray Test',
                                          Existing_GP_or_New_GP__c = 'Existing GP',
                                          Direct_v_Partner__c = 'Partner');
        insert opp;
        
        
        Quote q = new Quote(OpportunityId = opp.Id,
                            Name = 'Ray Test',
                            Pricebook2Id = Test.getStandardPricebookId());
        insert q;
        
        Product2 prod3 = new Product2(Name = 'Solutions', ProductCode = 'Solutions PM Services');
        Product2 prod4 = new Product2(Name = 'Solutions PM Services', ProductCode = 'Solutions PM Services');
        //insert new List<Product2> {prod1, prod2};
        
        insert prod3;
        insert prod4;
       
        Pricebook2 pb = new Pricebook2(Name = 'Test Standard Book', IsActive = true, Description = 'test standard book');
        insert pb;
        
        
        
        PricebookEntry pbe3 = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(),
                                                 Product2Id = prod3.Id,
                                                 UnitPrice = 1,
                                                 IsActive = true);
        PricebookEntry pbe4 = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(),
                                                 Product2Id = prod4.Id,
                                                 UnitPrice = 1,
                                                 IsActive = true);
        insert new List<PricebookEntry> {pbe3, pbe4};  
        
       QuoteLineItem qli3 = new QuoteLineItem(QuoteId = q.Id,
                                              PricebookEntryId = pbe3.Id,
                                              Quantity = 1,
                                              UnitPrice = 1);
        /*QuoteLineItem qli4 = new QuoteLineItem(QuoteId = q.Id,
                                              PricebookEntryId = pbe4.Id,
                                              Quantity = 1,
                                              UnitPrice = 1);*/
        List<QuoteLineItem> qliList = new List<QuoteLineItem>{qli3};
        Test.startTest(); 
        QuoteLineItemTriggerHandler.formatCurrency(100);
        insert qliList; 
        update qliList;
        Test.stopTest();
        
        System.assertEquals(2, [select count() from QuoteLineItem where QuoteId = :q.Id]);
    }
    
    static testMethod void testAddEnhancementItem4() {
        QuoteLineItemTriggerHandler.fa.Add_Enhancement_Items__c = true; 
        
        Account a = new Account(Name = 'Ray test', Type = 'Other', Customer_Class__c = 'Other');
        insert a;
        
        Opportunity opp = new Opportunity(AccountId = a.Id,
                                          CloseDate = Date.today(),
                                          StageName = 'Sandbox',
                                          Name = 'Ray Test',
                                          Existing_GP_or_New_GP__c = 'Existing GP',
                                          Direct_v_Partner__c = 'Partner');
        insert opp;
        
        
        Quote q = new Quote(OpportunityId = opp.Id,
                            Name = 'Ray Test',
                            Pricebook2Id = Test.getStandardPricebookId());
        insert q;
        
        Product2 prod1 = new Product2(Name = 'CONSULTING', ProductCode= 'RayTest Consulting');
        Product2 prod2 = new Product2(Name = 'PM Services', ProductCode = 'RayTest Consulting');
        
        //insert new List<Product2> {prod1, prod2};
        insert prod1;
        insert prod2;
               
        Pricebook2 pb = new Pricebook2(Name = 'Test Standard Book', IsActive = true, Description = 'test standard book');
        insert pb;
        
        
        PricebookEntry pbe1 = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(),
                                                 Product2Id = prod1.Id,
                                                 UnitPrice = 1,
                                                 IsActive = true);
        PricebookEntry pbe2 = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(),
                                                 Product2Id = prod2.Id,
                                                 UnitPrice = 1,
                                                 IsActive = true);
        
        insert new List<PricebookEntry> {pbe1, pbe2};
            
        
        QuoteLineItem qli1 = new QuoteLineItem(QuoteId = q.Id,
                                              PricebookEntryId = pbe1.Id,
                                              Quantity = 1,
                                              UnitPrice = 1);
        
        List<QuoteLineItem> qliList = new List<QuoteLineItem>{qli1};
        Test.startTest(); 
        QuoteLineItemTriggerHandler.formatCurrency(100);
        insert qliList; 
        update qliList;
        Test.stopTest();
        
        System.assertEquals(2, [select count() from QuoteLineItem where QuoteId = :q.Id]);
    }
}