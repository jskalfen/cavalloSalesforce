@isTest
public class OpportunityTriggerHandler_Test {
    
    @TestSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;
        
        // Create test opportunity
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Business_Segment__c = 'SalesPad'
        );
        insert testOpp;
    }
    
    @isTest
    static void testUpdateManualDiscount() {
        // Get the test opportunity
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        // Test JSON data with percentage discount
        String testJsonData = '[{"type":"PERCENTAGE","period_unit":null,"period":null,"percentage":null,"operation_type":"add","item_price_id":null,"isPercentageDiscount":true,"isOneTime":true,"isLineItemDiscount":false,"isInvoiceDiscount":true,"isForever":false,"isFixedDiscount":false,"id":null,"duration_type":"one_time","discountType":"PERCENTAGE","discountPercentage":"33.40","discountAmount":null,"currency_code":"USD","cbId":"D_978527","apply_on":"invoice_amount","amount":null},{"type":"FIXED_AMOUNT","period_unit":null,"period":null,"percentage":null,"operation_type":"add","item_price_id":null,"isPercentageDiscount":false,"isOneTime":true,"isLineItemDiscount":false,"isInvoiceDiscount":true,"isForever":false,"isFixedDiscount":true,"id":null,"duration_type":"one_time","discountType":"FIXED_AMOUNT","discountPercentage":null,"discountAmount":"223.00","currency_code":"USD","cbId":"D_403513","apply_on":"invoice_amount","amount":"223.00"}]';
        
        Test.startTest();
        
        // Update the opportunity with the JSON data
        testOpp.chargebeeapps__Manual_Discount__c = testJsonData;
        update testOpp;
        
        Test.stopTest();
        
        // Verify the Manual_Discount__c field was updated
        Opportunity updatedOpp = [SELECT Id, Manual_Discount__c, chargebeeapps__Manual_Discount__c FROM Opportunity WHERE Id = :testOpp.Id];
        
        System.assertNotEquals(null, updatedOpp.Manual_Discount__c, 'Manual_Discount__c should be set');
        System.assertEquals(33.40, updatedOpp.Manual_Discount__c, 'Manual_Discount__c should be 33.40%');
    }
    
    @isTest
    static void testUpdateManualDiscountWithNoPercentageDiscount() {
        // Get the test opportunity
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        // Test JSON data with only fixed amount discount (no percentage)
        String testJsonData = '[{"type":"FIXED_AMOUNT","period_unit":null,"period":null,"percentage":null,"operation_type":"add","item_price_id":null,"isPercentageDiscount":false,"isOneTime":true,"isLineItemDiscount":false,"isInvoiceDiscount":true,"isForever":false,"isFixedDiscount":true,"id":null,"duration_type":"one_time","discountType":"FIXED_AMOUNT","discountPercentage":null,"discountAmount":"223.00","currency_code":"USD","cbId":"D_403513","apply_on":"invoice_amount","amount":"223.00"}]';
        
        Test.startTest();
        
        // Update the opportunity with the JSON data
        testOpp.chargebeeapps__Manual_Discount__c = testJsonData;
        update testOpp;
        
        Test.stopTest();
        
        // Verify the Manual_Discount__c field was not updated (no percentage discount)
        Opportunity updatedOpp = [SELECT Id, Manual_Discount__c, chargebeeapps__Manual_Discount__c FROM Opportunity WHERE Id = :testOpp.Id];
        
        System.assertEquals(null, updatedOpp.Manual_Discount__c, 'Manual_Discount__c should be null when no percentage discount');
    }
    
    @isTest
    static void testUpdateManualDiscountWithInvalidJson() {
        // Get the test opportunity
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        // Test with invalid JSON
        String invalidJsonData = 'invalid json data';
        
        Test.startTest();
        
        // Update the opportunity with invalid JSON data
        testOpp.chargebeeapps__Manual_Discount__c = invalidJsonData;
        update testOpp;
        
        Test.stopTest();
        
        // Verify the Manual_Discount__c field was not updated and no exception was thrown
        Opportunity updatedOpp = [SELECT Id, Manual_Discount__c, chargebeeapps__Manual_Discount__c FROM Opportunity WHERE Id = :testOpp.Id];
        
        System.assertEquals(null, updatedOpp.Manual_Discount__c, 'Manual_Discount__c should be null with invalid JSON');
    }

    @isTest
    static void testUpdateManualDiscountWithInvalidJson2() {
        // Get the test opportunity
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        // Test with invalid JSON
        String invalidJsonData = null;
        
        Test.startTest();
        
        // Update the opportunity with invalid JSON data
        testOpp.chargebeeapps__Manual_Discount__c = invalidJsonData;
        update testOpp;
        
        Test.stopTest();
        
        // Verify the Manual_Discount__c field was not updated and no exception was thrown
        Opportunity updatedOpp = [SELECT Id, Manual_Discount__c, chargebeeapps__Manual_Discount__c FROM Opportunity WHERE Id = :testOpp.Id];
        
        System.assertEquals(null, updatedOpp.Manual_Discount__c, 'Manual_Discount__c should be null with invalid JSON');
    }
}
