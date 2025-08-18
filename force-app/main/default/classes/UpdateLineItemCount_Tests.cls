@isTest
private class UpdateLineItemCount_Tests {
    
    @testSetup static void PrepareCommonEntitiesForTests()
    {
        Account testAccount = new Account(Name = 'Test Account', Type = 'Other', Customer_Class__c = 'Other');
        insert testAccount;
        Opportunity testOpportunity = new Opportunity(AccountID = testAccount.Id,
            CloseDate = Date.today(),
            StageName = 'Sandbox',
            Name = 'Test Opportunity',
            Existing_GP_or_New_GP__c = 'Existing GP',
            Sales_Engineer__c = '0056A000002zXKeQAM',                                          
            Direct_v_Partner__c = 'Partner',
            Billing_Preference__c = 'Bill through Partner'
        );
        insert testOpportunity;
        
        //Product2 testDesktopConsultingProduct = new Product2(Name = 'Desktop Consulting');
        //testDesktopConsultingProduct.ProductCode = 'CONSULTING - DESKTOP';
        //testProducts.Add(testDesktopConsultingProduct);
        //Product2 testPayFabricConsultingProduct = new Product2(Name = 'Payfabric Consulting');
        //testPayFabricConsultingProduct.ProductCode = 'CONSULTING - PAYFABRIC';
        //testProducts.Add(testPayFabricConsultingProduct);
        //Product2 testEdiConsultingProduct = new Product2(Name = 'EDI Consulting');
        //testEdiConsultingProduct.ProductCode = 'CONSULTING - EDI';
        //testProducts.Add(testEdiConsultingProduct);
        //insert testProducts;
        Pricebook2 standardPriceBook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        
        // Apparently the standard price book isn't marked "standard", need to do a quick update
        // to workaround this weird bug in Salesforce.
        update standardPriceBook;
    }
    
    @isTest static void TestCommentHandlingForNonConsultingProducts()
    {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1][0];
        Opportunity testOpportunity = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1][0];
        Id standardPricebookId = Test.getStandardPricebookId();
        List<Product2> testProducts = new List<Product2>();
        Product2 testGpProduct = new Product2(Name = 'GP Product');
        testGpProduct.ProductCode = 'DGP0019';
        testProducts.Add(testGpProduct);
        Product2 testWpIntProduct = new Product2(Name = 'WP Internal Product');
        testWpIntProduct.ProductCode = 'DGP00022';
        testProducts.Add(testWpIntProduct);
        Product2 testDcProduct = new Product2(Name = 'DC Product');
        testDcProduct.ProductCode = 'DGP00012';
        testProducts.Add(testDcProduct);
        Product2 testWpExtProduct = new Product2(Name = 'WP External Product');
        testWpExtProduct.ProductCode = 'DGP00021';
        testProducts.Add(testWpExtProduct);
        Product2 testMobileProduct = new Product2(Name = 'Mobile Product');
        testMobileProduct.ProductCode = 'DGP00014';
        testProducts.Add(testMobileProduct);
        Product2 testNonConsultingSiteLicensedProduct = new Product2(Name = 'Desktop Consulting');
        testNonConsultingSiteLicensedProduct.ProductCode = 'SOMETHING ELSE';
        testProducts.Add(testNonConsultingSiteLicensedProduct);
        Product2 pmServicesProduct = new Product2(Name = 'PM Services');
        pmServicesProduct.ProductCode = 'SRV00002';
        testProducts.Add(pmServicesProduct);
        Product2 testAAProduct = new Product2(Name = 'AUTOMATION AGENT - SUB', ProductCode = 'DPS00068', Licensing__c = 'Subscription', Comments__c = 'List Price: $8,400/site/year');
        testProducts.Add(testAAProduct);
        insert testProducts;
        List<PricebookEntry> testPrices = new List<PricebookEntry>();
        PricebookEntry gpPrice = new PricebookEntry(Product2Id = testGpProduct.Id,
            Pricebook2Id = standardPricebookId,
            IsActive = true,
            UnitPrice = 2);
        testPrices.Add(gpPrice);
        PricebookEntry wpIntPrice = new PricebookEntry(Product2Id = testWpIntProduct.Id,
            Pricebook2Id = standardPricebookId,
            IsActive = true,
            UnitPrice = 3);
        testPrices.Add(wpIntPrice);
        PricebookEntry dcPrice = new PricebookEntry(Product2Id = testDcProduct.Id,
            Pricebook2Id = standardPricebookId,
            IsActive = true,
            UnitPrice = 5);
        testPrices.Add(dcPrice);
        PricebookEntry mobilePrice = new PricebookEntry(Product2Id = testMobileProduct.Id,
            Pricebook2Id = standardPricebookId,
            IsActive = true,
            UnitPrice = 7);
        testPrices.Add(mobilePrice);
        PricebookEntry wpExtPrice = new PricebookEntry(Product2Id = testWpExtProduct.Id,
            Pricebook2Id = standardPricebookId,
            IsActive = true,
            UnitPrice = 11);
        testPrices.Add(wpExtPrice);
        PricebookEntry pmServicesPrice = new PricebookEntry(Product2Id = testNonConsultingSiteLicensedProduct.Id,
            Pricebook2Id = standardPricebookId,
            IsActive = true,
            UnitPrice = 13);
        testPrices.Add(pmServicesPrice);
        PricebookEntry otherPrice = new PricebookEntry(Product2Id = pmServicesProduct.Id,
            Pricebook2Id = standardPricebookId,
            IsActive = true,
            UnitPrice = 17);
        testPrices.Add(otherPrice);
        PricebookEntry aaPrice = new PricebookEntry(Product2Id = testAAProduct.Id,
            Pricebook2Id = standardPricebookId,
            IsActive = true,
            UnitPrice = 19);
        testPrices.Add(aaPrice);
        insert testPrices;
        Quote testQuote = new Quote(OpportunityId = testOpportunity.Id,
            Name = 'Test Quote',
            Pricebook2Id = Test.getStandardPricebookId());
        insert testQuote;
        QuoteLineItem spgpLine = new QuoteLineItem(
            QuoteId = testQuote.Id,
            Quantity = 1,
            Product2Id = testGpProduct.Id,
            PricebookEntryId = gpPrice.Id,
            Comments__c = null,
            UnitPrice = 2
        );
        QuoteLineItem wpIntLine = new QuoteLineItem(
            QuoteId = testQuote.Id,
            Quantity = 1,
            Product2Id = testWpIntProduct.Id,
            PricebookEntryId = wpIntPrice.Id,
            Comments__c = null,
            UnitPrice = 3
        );
        QuoteLineItem dcLine = new QuoteLineItem(
            QuoteId = testQuote.Id,
            Quantity = 1,
            Product2Id = testDcProduct.Id,
            PricebookEntryId = dcPrice.Id,
            Comments__c = null,
            UnitPrice = 5
        );
        QuoteLineItem mobileLine = new QuoteLineItem(
            QuoteId = testQuote.Id,
            Quantity = 1,
            Product2Id = testMobileProduct.Id,
            PricebookEntryId = mobilePrice.Id,
            Comments__c = null,
            UnitPrice = 7
        );
        QuoteLineItem wpExtLine = new QuoteLineItem(
            QuoteId = testQuote.Id,
            Quantity = 1,
            Product2Id = testWpExtProduct.Id,
            PricebookEntryId = wpExtPrice.Id,
            Comments__c = null,
            UnitPrice = 11
        );
        QuoteLineItem siteLicenseLine = new QuoteLineItem(
            QuoteId = testQuote.Id,
            Quantity = 1,
            Product2Id = testNonConsultingSiteLicensedProduct.Id,
            PricebookEntryId = otherPrice.Id,
            Comments__c = null,
            UnitPrice = 13
        );
        QuoteLineItem pmServicesLine = new QuoteLineItem(
            QuoteId = testQuote.Id,
            Quantity = 1,
            Product2Id = pmServicesProduct.Id,
            PricebookEntryId = pmServicesPrice.Id,
            Comments__c = null,
            UnitPrice = 17
        );
        QuoteLineItem alreadyCommentedLine = new QuoteLineItem(
            QuoteId = testQuote.Id,
            Quantity = 1,
            Product2Id = testNonConsultingSiteLicensedProduct.Id,
            PricebookEntryId = otherPrice.Id,
            Comments__c = 'This should not be changed.',
            UnitPrice = 13
        );
        QuoteLineItem aaLine = new QuoteLineItem(
            QuoteId = testQuote.Id,
            Quantity = 1,
            Product2Id = testAAProduct.Id,
            PricebookEntryId = aaPrice.Id,
            Comments__c = null,
            UnitPrice = 2
        );
        List<QuoteLineItem> lines = new List<QuoteLineItem>{spgpLine, wpIntLine, dcLine, mobileLine, wpExtLine, siteLicenseLine, pmServicesLine, alreadyCommentedLine, aaLine};
        
        Test.startTest();
        insert lines;
        Test.stopTest();
       
        spgpLine = [SELECT Id, Comments__c FROM QuoteLineItem WHERE Id = :spgpLine.Id];
        wpIntLine = [SELECT Id, Comments__c FROM QuoteLineItem WHERE Id = :wpIntLine.Id];
        dcLine = [SELECT Id, Comments__c FROM QuoteLineItem WHERE Id = :dcLine.Id];
        mobileLine = [SELECT Id, Comments__c FROM QuoteLineItem WHERE Id = :mobileLine.Id];
        wpExtLine = [SELECT Id, Comments__c FROM QuoteLineItem WHERE Id = :wpExtLine.Id];
        siteLicenseLine = [SELECT Id, Comments__c FROM QuoteLineItem WHERE Id = :siteLicenseLine.Id];
        pmServicesLine = [SELECT Id, Comments__c FROM QuoteLineItem WHERE Id = :pmServicesLine.Id];
        alreadyCommentedLine = [SELECT Id, Comments__c FROM QuoteLineItem WHERE Id = :alreadyCommentedLine.Id];
        aaLine = [SELECT Id, Comments__c FROM QuoteLineItem WHERE Id = :aaLine.Id];

        System.assert(Pattern.matches('List price \\$2(\\.0?0?)? per concurrent user\\.', spgpLine.Comments__c), 'SPGP line did not set comment as expected.');
        System.assert(Pattern.matches('List price \\$3(\\.0?0?)? per concurrent user\\.', wpIntLine.Comments__c), 'WP Internal line did not set comment as expected.');
        //System.assert(Pattern.matches('List Price \\$5(\\.0?0?)? per concurrent user\\.', dcLine.Comments__c), 'DC line did not set comment as expected.');
        //System.assert(Pattern.matches('List price \\$7(\\.0?0?)? per concurrent handheld device\\.', mobileLine.Comments__c), 'DC Mobile line did not set comment as expected.');
        System.assert(Pattern.matches('List price \\$11(\\.0?0?)? per user per month\\.', wpExtLine.Comments__c), 'WP External line did not set comment as expected.');
        System.assert(Pattern.matches('List price \\$13(\\.0?0?)? per GP site ID\\.', siteLicenseLine.Comments__c), 'Other line did not set comment as expected.');
        System.assert(pmServicesLine.Comments__c == null || pmServicesLine.Comments__c == '', 'PM Services line did not set comment as expected.');
        System.assertEquals('This should not be changed.', alreadyCommentedLine.Comments__c, 'Custom comment was not retained.');
        System.assertEquals(aaLine.Comments__c, 'List Price: $8,400/site/year');
    }
    
    //@isTest static void TestCommentHandlingForConsultingProducts()
    //{
    //    Account testAccount = new Account(Name = 'Test Account');
    //    Opportunity testOpportunity = new Opportunity(AccountID = testAccount.Id,
    //        CloseDate = Date.today(),
    //        StageName = 'Sandbox',
    //        Name = 'Test Opportunity'
    //    );
    //    Id standardPricebookId = Test.getStandardPricebookId();
    //    
    //
    //}
}