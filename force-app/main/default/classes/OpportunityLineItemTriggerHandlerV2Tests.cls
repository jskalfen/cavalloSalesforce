@isTest
public class OpportunityLineItemTriggerHandlerV2Tests {

    @isTest
    static void testBeforeInsert_WithMatchingProductCode_SetsNoPartnerMarginToTrue() {
        // Create test data inline
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Product2 testProduct = new Product2(
            Name = 'Test Product Matching',
            ProductCode = 'PSS-999-901',
            IsActive = true
        );
        insert testProduct;
        
        List<Pricebook2> standardPBs = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
        if(standardPBs.isEmpty()) {
            System.assert(true, 'No standard pricebook found');
            return;
        }
        
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPBs[0].Id,
            Product2Id = testProduct.Id,
            UnitPrice = 1000,
            IsActive = true
        );
        insert pbe;
        
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Business_Segment__c = 'SalesPad'
        );
        insert testOpp;

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = testOpp.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 1000
        );

        Test.startTest();
        insert oli;
        Test.stopTest();

        OpportunityLineItem insertedOli = [
            SELECT Id, No_Partner_Margin__c, ProductCode, Customer_Discount__c
            FROM OpportunityLineItem
            WHERE Id = :oli.Id
        ];

        System.assertEquals(true, insertedOli.No_Partner_Margin__c, 
            'No_Partner_Margin__c should be set to true for matching Product Code');
        System.assertEquals(0, insertedOli.Customer_Discount__c, 
            'Customer_Discount__c should be 0 when No_Partner_Margin__c is true');
    }

    @isTest
    static void testBeforeInsert_WithNonMatchingProductCode_SetsNoPartnerMarginToFalse() {
        // Create test data inline
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Product2 testProduct = new Product2(
            Name = 'Test Product Non-Matching',
            ProductCode = 'OTHER-CODE',
            IsActive = true
        );
        insert testProduct;
        
        List<Pricebook2> standardPBs = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
        if(standardPBs.isEmpty()) {
            System.assert(true, 'No standard pricebook found');
            return;
        }
        
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPBs[0].Id,
            Product2Id = testProduct.Id,
            UnitPrice = 1000,
            IsActive = true
        );
        insert pbe;
        
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Business_Segment__c = 'SalesPad'
        );
        insert testOpp;

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = testOpp.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 1000
        );

        Test.startTest();
        insert oli;
        Test.stopTest();

        OpportunityLineItem insertedOli = [
            SELECT Id, No_Partner_Margin__c, ProductCode
            FROM OpportunityLineItem
            WHERE Id = :oli.Id
        ];

        System.assertEquals(false, insertedOli.No_Partner_Margin__c, 
            'No_Partner_Margin__c should be set to false for non-matching Product Code');
    }

    @isTest
    static void testBeforeUpdate_ProductCodeChangedFromMatchingToNonMatching_SetsNoPartnerMarginToFalse() {
        // Create test data inline
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Product2 matchingProduct = new Product2(
            Name = 'Test Product Matching',
            ProductCode = 'PSS-999-901',
            IsActive = true
        );
        Product2 nonMatchingProduct = new Product2(
            Name = 'Test Product Non-Matching',
            ProductCode = 'OTHER-CODE',
            IsActive = true
        );
        insert new List<Product2>{ matchingProduct, nonMatchingProduct };
        
        List<Pricebook2> standardPBs = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
        if(standardPBs.isEmpty()) {
            System.assert(true, 'No standard pricebook found');
            return;
        }
        
        PricebookEntry matchingPbe = new PricebookEntry(
            Pricebook2Id = standardPBs[0].Id,
            Product2Id = matchingProduct.Id,
            UnitPrice = 1000,
            IsActive = true
        );
        PricebookEntry nonMatchingPbe = new PricebookEntry(
            Pricebook2Id = standardPBs[0].Id,
            Product2Id = nonMatchingProduct.Id,
            UnitPrice = 1000,
            IsActive = true
        );
        insert new List<PricebookEntry>{ matchingPbe, nonMatchingPbe };
        
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Business_Segment__c = 'SalesPad'
        );
        insert testOpp;

        // Insert with matching Product Code
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = testOpp.Id,
            PricebookEntryId = matchingPbe.Id,
            Quantity = 1,
            UnitPrice = 1000
        );
        insert oli;

        // Verify it was set to true
        OpportunityLineItem insertedOli = [
            SELECT Id, No_Partner_Margin__c, ProductCode
            FROM OpportunityLineItem
            WHERE Id = :oli.Id
        ];
        System.assertEquals(true, insertedOli.No_Partner_Margin__c, 
            'No_Partner_Margin__c should be true initially');

        // Update to non-matching Product Code by changing PricebookEntry
        insertedOli.PricebookEntryId = nonMatchingPbe.Id;

        Test.startTest();
        update insertedOli;
        Test.stopTest();

        OpportunityLineItem updatedOli = [
            SELECT Id, No_Partner_Margin__c, ProductCode, Customer_Discount__c
            FROM OpportunityLineItem
            WHERE Id = :oli.Id
        ];

        System.assertEquals(false, updatedOli.No_Partner_Margin__c, 
            'No_Partner_Margin__c should be set to false when Product Code changes from matching to non-matching');
    }

    @isTest
    static void testBeforeUpdate_ProductCodeChangedFromNonMatchingToMatching_SetsNoPartnerMarginToTrue() {
        // Create test data inline
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Product2 matchingProduct = new Product2(
            Name = 'Test Product Matching',
            ProductCode = 'PSS-999-901',
            IsActive = true
        );
        Product2 nonMatchingProduct = new Product2(
            Name = 'Test Product Non-Matching',
            ProductCode = 'OTHER-CODE',
            IsActive = true
        );
        insert new List<Product2>{ matchingProduct, nonMatchingProduct };
        
        List<Pricebook2> standardPBs = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
        if(standardPBs.isEmpty()) {
            System.assert(true, 'No standard pricebook found');
            return;
        }
        
        PricebookEntry matchingPbe = new PricebookEntry(
            Pricebook2Id = standardPBs[0].Id,
            Product2Id = matchingProduct.Id,
            UnitPrice = 1000,
            IsActive = true
        );
        PricebookEntry nonMatchingPbe = new PricebookEntry(
            Pricebook2Id = standardPBs[0].Id,
            Product2Id = nonMatchingProduct.Id,
            UnitPrice = 1000,
            IsActive = true
        );
        insert new List<PricebookEntry>{ matchingPbe, nonMatchingPbe };
        
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Business_Segment__c = 'SalesPad'
        );
        insert testOpp;

        // Insert with non-matching Product Code
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = testOpp.Id,
            PricebookEntryId = nonMatchingPbe.Id,
            Quantity = 1,
            UnitPrice = 1000
        );
        insert oli;

        // Verify it was set to false
        OpportunityLineItem insertedOli = [
            SELECT Id, No_Partner_Margin__c, ProductCode
            FROM OpportunityLineItem
            WHERE Id = :oli.Id
        ];
        System.assertEquals(false, insertedOli.No_Partner_Margin__c, 
            'No_Partner_Margin__c should be false initially');

        // Update to matching Product Code by changing PricebookEntry
        insertedOli.PricebookEntryId = matchingPbe.Id;

        Test.startTest();
        update insertedOli;
        Test.stopTest();

        OpportunityLineItem updatedOli = [
            SELECT Id, No_Partner_Margin__c, ProductCode, Customer_Discount__c
            FROM OpportunityLineItem
            WHERE Id = :oli.Id
        ];

        System.assertEquals(true, updatedOli.No_Partner_Margin__c, 
            'No_Partner_Margin__c should be set to true when Product Code changes from non-matching to matching');
        System.assertEquals(0, updatedOli.Customer_Discount__c, 
            'Customer_Discount__c should be 0 when No_Partner_Margin__c is true');
    }
}
