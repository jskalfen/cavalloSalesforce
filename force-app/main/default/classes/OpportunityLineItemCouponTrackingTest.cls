@isTest
public class OpportunityLineItemCouponTrackingTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = new Account(
            Name = 'Test Account',
            BillingCountry = 'United States'
        );
        insert testAccount;
        
        // Get standard pricebook
        Id pricebookId = Test.getStandardPricebookId();
        
        // Create test products
        List<Product2> testProducts = new List<Product2>();
        testProducts.add(new Product2(
            Name = 'Test Product 1',
            Family = 'DESKTOP_PRODUCTS',
            IsActive = true
        ));
        testProducts.add(new Product2(
            Name = 'Test Product 2',
            Family = 'CLOUD_PRODUCTS',
            IsActive = true
        ));
        insert testProducts;
        
        // Create pricebook entries
        List<PricebookEntry> testPricebookEntries = new List<PricebookEntry>();
        testPricebookEntries.add(new PricebookEntry(
            Product2Id = testProducts[0].Id,
            Pricebook2Id = pricebookId,
            UnitPrice = 1000,
            IsActive = true
        ));
        testPricebookEntries.add(new PricebookEntry(
            Product2Id = testProducts[1].Id,
            Pricebook2Id = pricebookId,
            UnitPrice = 500,
            IsActive = true
        ));
        insert testPricebookEntries;
        
        // Create test opportunity with explicit pricebook assignment
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Amount = 10000,
            Business_Segment__c = 'SalesPad'
        );
        insert testOpportunity;
        
        // Update opportunity with pricebook after insert
        testOpportunity.Pricebook2Id = pricebookId;
        update testOpportunity;
        
        // Create test opportunity line items
        List<OpportunityLineItem> testOlis = new List<OpportunityLineItem>();
        
        // OLI 1: With list price and quantity
        testOlis.add(new OpportunityLineItem(
            OpportunityId = testOpportunity.Id,
            PricebookEntryId = testPricebookEntries[0].Id,
            Quantity = 2,
            TotalPrice = 2000,
            Partner_Payment_OP_Bill_through__c = 0,
            Manual_Partner_Payment_Amount__c = 0,
            Chargebee_Coupon_Amount__c = 0,
            Coupon_Source__c = 'None'
        ));
        
        // OLI 2: With different values
        testOlis.add(new OpportunityLineItem(
            OpportunityId = testOpportunity.Id,
            PricebookEntryId = testPricebookEntries[1].Id,
            Quantity = 3,
            TotalPrice = 1500,
            Partner_Payment_OP_Bill_through__c = 0,
            Manual_Partner_Payment_Amount__c = 0,
            Chargebee_Coupon_Amount__c = 0,
            Coupon_Source__c = 'None'
        ));
        
        insert testOlis;
    }
    
    @isTest
    static void testTrackManualPartnerPayments_NewManualEntry() {
        // Get test data with all required fields
        List<OpportunityLineItem> testOlis = [SELECT Id, ListPrice, Quantity, Partner_Payment_OP_Bill_through__c, 
                                             Manual_Partner_Payment_Amount__c, Coupon_Source__c 
                                             FROM OpportunityLineItem LIMIT 1];
        
        // Create old map to simulate update
        Map<Id, OpportunityLineItem> oldMap = new Map<Id, OpportunityLineItem>();
        for(OpportunityLineItem oli : testOlis) {
            oldMap.put(oli.Id, oli.clone(true, true, true, true));
        }
        
        // Update partner payment to simulate manual entry
        for(OpportunityLineItem oli : testOlis) {
            oli.Partner_Payment_OP_Bill_through__c = 15; // 15% partner payment
        }
        
        Test.startTest();
        OpportunityLineItemCouponTracking.trackManualPartnerPayments(testOlis, oldMap);
        Test.stopTest();
        
        // Verify results - the field updates happen in memory, not in the database
        // due to trigger conflicts, so we test the logic directly
        System.assertEquals('Manual Entry', testOlis[0].Coupon_Source__c, 
                          'Coupon source should be set to Manual Entry');
        
        // Test the calculation logic directly
        if(testOlis[0].ListPrice != null && testOlis[0].Quantity != null) {
            Decimal expectedAmount = (testOlis[0].ListPrice * testOlis[0].Quantity * 15) / 100;
            System.assertEquals(expectedAmount, testOlis[0].Manual_Partner_Payment_Amount__c, 
                              'Manual partner payment amount should be calculated correctly');
        }
    }
    
    @isTest
    static void testTrackManualPartnerPayments_NoChange() {
        // Get test data
        List<OpportunityLineItem> testOlis = [SELECT Id, ListPrice, Quantity, Partner_Payment_OP_Bill_through__c, 
                                             Manual_Partner_Payment_Amount__c, Coupon_Source__c 
                                             FROM OpportunityLineItem LIMIT 1];
        
        // Create old map with same values
        Map<Id, OpportunityLineItem> oldMap = new Map<Id, OpportunityLineItem>();
        for(OpportunityLineItem oli : testOlis) {
            oldMap.put(oli.Id, oli.clone(true, true, true, true));
        }
        
        // Don't change any values
        Test.startTest();
        OpportunityLineItemCouponTracking.trackManualPartnerPayments(testOlis, oldMap);
        Test.stopTest();
        
        // Verify no changes
        System.assertEquals('None', testOlis[0].Coupon_Source__c, 
                          'Coupon source should remain unchanged');
    }
    
    @isTest
    static void testTrackManualPartnerPayments_ResetToZero() {
        // Get test data
        List<OpportunityLineItem> testOlis = [SELECT Id, ListPrice, Quantity, Partner_Payment_OP_Bill_through__c, 
                                             Manual_Partner_Payment_Amount__c, Coupon_Source__c, Chargebee_Coupon_Amount__c 
                                             FROM OpportunityLineItem LIMIT 1];
        
        // Set initial values
        for(OpportunityLineItem oli : testOlis) {
            oli.Partner_Payment_OP_Bill_through__c = 20;
            oli.Manual_Partner_Payment_Amount__c = 400;
            oli.Chargebee_Coupon_Amount__c = 100;
            oli.Coupon_Source__c = 'Manual Entry';
        }
        
        // Create old map with previous values
        Map<Id, OpportunityLineItem> oldMap = new Map<Id, OpportunityLineItem>();
        for(OpportunityLineItem oli : testOlis) {
            oldMap.put(oli.Id, oli.clone(true, true, true, true));
        }
        
        // Reset partner payment to 0
        for(OpportunityLineItem oli : testOlis) {
            oli.Partner_Payment_OP_Bill_through__c = 0;
        }
        
        Test.startTest();
        OpportunityLineItemCouponTracking.trackManualPartnerPayments(testOlis, oldMap);
        Test.stopTest();
        
        // Verify reset - test the in-memory changes directly
        System.assertEquals(0, testOlis[0].Manual_Partner_Payment_Amount__c, 
                          'Manual partner payment amount should be reset to 0');
        System.assertEquals(0, testOlis[0].Chargebee_Coupon_Amount__c, 
                          'Chargebee coupon amount should be reset to 0');
        System.assertEquals('None', testOlis[0].Coupon_Source__c, 
                          'Coupon source should be reset to None');
    }
    
    @isTest
    static void testTrackManualPartnerPayments_NullValues() {
        // Get test data
        List<OpportunityLineItem> testOlis = [SELECT Id, ListPrice, Quantity, Partner_Payment_OP_Bill_through__c, 
                                             Manual_Partner_Payment_Amount__c, Coupon_Source__c 
                                             FROM OpportunityLineItem LIMIT 1];
        
        // Create old map with different partner payment value
        Map<Id, OpportunityLineItem> oldMap = new Map<Id, OpportunityLineItem>();
        for(OpportunityLineItem oli : testOlis) {
            oldMap.put(oli.Id, oli.clone(true, true, true, true));
        }
        
        // Update partner payment to trigger the logic
        for(OpportunityLineItem oli : testOlis) {
            oli.Partner_Payment_OP_Bill_through__c = 10;
        }
        
        Test.startTest();
        OpportunityLineItemCouponTracking.trackManualPartnerPayments(testOlis, oldMap);
        Test.stopTest();
        
        // Verify the logic works - the field updates happen in memory
        System.assertEquals('Manual Entry', testOlis[0].Coupon_Source__c, 
                          'Coupon source should be set to Manual Entry');
    }
    
    @isTest
    static void testTrackManualPartnerPayments_NewRecord() {
        // Test with new records (oldMap is null)
        List<OpportunityLineItem> newOlis = [SELECT Id, ListPrice, Quantity, Partner_Payment_OP_Bill_through__c, 
                                            Manual_Partner_Payment_Amount__c, Coupon_Source__c 
                                            FROM OpportunityLineItem LIMIT 1];
        
        Test.startTest();
        OpportunityLineItemCouponTracking.trackManualPartnerPayments(newOlis, null);
        Test.stopTest();
        
        // Verify no changes for new records
        System.assertEquals('None', newOlis[0].Coupon_Source__c, 
                          'Coupon source should remain unchanged for new records');
    }
    
    @isTest
    static void testCalculatePartnerPaymentBreakdown_ChargebeeCoupon() {
        // Get test data
        List<OpportunityLineItem> testOlis = [SELECT Id, ListPrice, Quantity, Partner_Payment_OP_Bill_through__c, 
                                             Manual_Partner_Payment_Amount__c, Coupon_Source__c, Chargebee_Coupon_Amount__c 
                                             FROM OpportunityLineItem LIMIT 1];
        
        // Set up for Chargebee coupon scenario
        for(OpportunityLineItem oli : testOlis) {
            oli.Partner_Payment_OP_Bill_through__c = 25;
            oli.Coupon_Source__c = 'Chargebee Coupon';
            oli.Chargebee_Coupon_Amount__c = null; // This should trigger calculation
        }
        
        Test.startTest();
        OpportunityLineItemCouponTracking.calculatePartnerPaymentBreakdown(testOlis);
        Test.stopTest();
        
        // Verify calculation - test the in-memory changes directly
        if(testOlis[0].ListPrice != null && testOlis[0].Quantity != null) {
            Decimal expectedAmount = (testOlis[0].ListPrice * testOlis[0].Quantity * 25) / 100;
            System.assertEquals(expectedAmount, testOlis[0].Chargebee_Coupon_Amount__c, 
                              'Chargebee coupon amount should be calculated correctly');
        }
    }
    
    @isTest
    static void testCalculatePartnerPaymentBreakdown_ManualEntry() {
        // Get test data
        List<OpportunityLineItem> testOlis = [SELECT Id, ListPrice, Quantity, Partner_Payment_OP_Bill_through__c, 
                                             Manual_Partner_Payment_Amount__c, Coupon_Source__c, Chargebee_Coupon_Amount__c 
                                             FROM OpportunityLineItem LIMIT 1];
        
        // Set up for manual entry scenario
        for(OpportunityLineItem oli : testOlis) {
            oli.Partner_Payment_OP_Bill_through__c = 30;
            oli.Coupon_Source__c = 'Manual Entry';
            oli.Manual_Partner_Payment_Amount__c = null; // This should trigger calculation
        }
        
        Test.startTest();
        OpportunityLineItemCouponTracking.calculatePartnerPaymentBreakdown(testOlis);
        Test.stopTest();
        
        // Verify calculation - test the in-memory changes directly
        if(testOlis[0].ListPrice != null && testOlis[0].Quantity != null) {
            Decimal expectedAmount = (testOlis[0].ListPrice * testOlis[0].Quantity * 30) / 100;
            System.assertEquals(expectedAmount, testOlis[0].Manual_Partner_Payment_Amount__c, 
                              'Manual partner payment amount should be calculated correctly');
        }
    }
    
    @isTest
    static void testCalculatePartnerPaymentBreakdown_NoCalculationNeeded() {
        // Get test data
        List<OpportunityLineItem> testOlis = [SELECT Id, ListPrice, Quantity, Partner_Payment_OP_Bill_through__c, 
                                             Manual_Partner_Payment_Amount__c, Coupon_Source__c, Chargebee_Coupon_Amount__c 
                                             FROM OpportunityLineItem LIMIT 1];
        
        // Set up with existing values (no calculation needed)
        for(OpportunityLineItem oli : testOlis) {
            oli.Partner_Payment_OP_Bill_through__c = 20;
            oli.Coupon_Source__c = 'Chargebee Coupon';
            oli.Chargebee_Coupon_Amount__c = 400; // Already calculated
        }
        
        Test.startTest();
        OpportunityLineItemCouponTracking.calculatePartnerPaymentBreakdown(testOlis);
        Test.stopTest();
        
        // Verify no change - test the in-memory changes directly
        System.assertEquals(400, testOlis[0].Chargebee_Coupon_Amount__c, 
                          'Chargebee coupon amount should remain unchanged when already calculated');
    }
    
    @isTest
    static void testCalculatePartnerPaymentBreakdown_NullValues() {
        // Get test data
        List<OpportunityLineItem> testOlis = [SELECT Id, ListPrice, Quantity, Partner_Payment_OP_Bill_through__c, 
                                             Manual_Partner_Payment_Amount__c, Coupon_Source__c, Chargebee_Coupon_Amount__c 
                                             FROM OpportunityLineItem LIMIT 1];
        
        // Set up with null values - but keep Quantity since it's required
        for(OpportunityLineItem oli : testOlis) {
            oli.Partner_Payment_OP_Bill_through__c = null;
            oli.Coupon_Source__c = 'Chargebee Coupon';
            oli.Chargebee_Coupon_Amount__c = null;
        }
        
        Test.startTest();
        OpportunityLineItemCouponTracking.calculatePartnerPaymentBreakdown(testOlis);
        Test.stopTest();
        
        // Verify no calculation when required values are null
        System.assertEquals(null, testOlis[0].Chargebee_Coupon_Amount__c, 
                          'Chargebee coupon amount should remain null when required values are null');
    }
    
    @isTest
    static void testCalculatePartnerPaymentBreakdown_MultipleRecords() {
        // Get all test data
        List<OpportunityLineItem> testOlis = [SELECT Id, ListPrice, Quantity, Partner_Payment_OP_Bill_through__c, 
                                             Manual_Partner_Payment_Amount__c, Coupon_Source__c, Chargebee_Coupon_Amount__c 
                                             FROM OpportunityLineItem];
        
        // Set up different scenarios for each OLI
        for(Integer i = 0; i < testOlis.size(); i++) {
            OpportunityLineItem oli = testOlis[i];
            if(i == 0) {
                // First OLI: Chargebee coupon scenario
                oli.Partner_Payment_OP_Bill_through__c = 15;
                oli.Coupon_Source__c = 'Chargebee Coupon';
                oli.Chargebee_Coupon_Amount__c = null;
            } else {
                // Second OLI: Manual entry scenario
                oli.Partner_Payment_OP_Bill_through__c = 20;
                oli.Coupon_Source__c = 'Manual Entry';
                oli.Manual_Partner_Payment_Amount__c = null;
            }
        }
        
        Test.startTest();
        OpportunityLineItemCouponTracking.calculatePartnerPaymentBreakdown(testOlis);
        Test.stopTest();
        
        // Verify both calculations - test the in-memory changes directly
        if(testOlis[0].ListPrice != null && testOlis[0].Quantity != null) {
            Decimal expectedAmount1 = (testOlis[0].ListPrice * testOlis[0].Quantity * 15) / 100;
            System.assertEquals(expectedAmount1, testOlis[0].Chargebee_Coupon_Amount__c, 
                              'First OLI Chargebee coupon amount should be calculated correctly');
        }
        
        if(testOlis[1].ListPrice != null && testOlis[1].Quantity != null) {
            Decimal expectedAmount2 = (testOlis[1].ListPrice * testOlis[1].Quantity * 20) / 100;
            System.assertEquals(expectedAmount2, testOlis[1].Manual_Partner_Payment_Amount__c, 
                              'Second OLI manual partner payment amount should be calculated correctly');
        }
    }
}