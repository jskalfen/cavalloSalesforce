/**
 * Test class for CBOpportunityCouponTriggerHandler
 */
@IsTest
private class CBOpportunityCouponTriggerHandler_Test {
    
    @TestSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;
        
        // Create test opportunities
        List<Opportunity> testOpportunities = new List<Opportunity>();
        for (Integer i = 0; i < 3; i++) {
            testOpportunities.add(new Opportunity(
                Name = 'Test Opportunity ' + i,
                AccountId = testAccount.Id,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30),
                Business_Segment__c = 'SalesPad'
            ));
        }
        insert testOpportunities;
        
        // Create test Chargebee coupons
        List<chargebeeapps__Coupon__c> testCoupons = new List<chargebeeapps__Coupon__c>();
        for (Integer i = 0; i < 5; i++) {
            testCoupons.add(new chargebeeapps__Coupon__c(
                Name = 'Test Coupon ' + i,
                chargebeeapps__Discount_Percentage__c = 10.0 + (i * 5.0) // 10%, 15%, 20%, 25%, 30%
            ));
        }
        insert testCoupons;
    }
    
    @IsTest
    static void testAfterInsert_SingleCoupon() {
        // Get test opportunity and coupon
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        chargebeeapps__Coupon__c testCoupon = [SELECT Id FROM chargebeeapps__Coupon__c LIMIT 1];
        
        // Create test coupon using JSON to bypass field restrictions
        String couponJson = '{"chargebeeapps__Opportunity__c":"' + testOpp.Id + '","chargebeeapps__CB_Coupon__c":"' + testCoupon.Id + '"}';
        chargebeeapps__CB_Opportunity_Coupon__c testCBOppCoupon = (chargebeeapps__CB_Opportunity_Coupon__c) JSON.deserialize(couponJson, chargebeeapps__CB_Opportunity_Coupon__c.class);
        
        Test.startTest();
        insert testCBOppCoupon;
        Test.stopTest();
        
        // Verify opportunity was updated
        Opportunity updatedOpp = [SELECT Id, Coupon_Discount__c FROM Opportunity WHERE Id = :testOpp.Id];
        System.assertEquals(10.0, updatedOpp.Coupon_Discount__c, 'Coupon discount should be 10%');
    }
    
    @IsTest
    static void testAfterInsert_MultipleCouponsSameOpportunity() {
        // Get test opportunity and coupons
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        List<chargebeeapps__Coupon__c> testCoupons = [SELECT Id FROM chargebeeapps__Coupon__c LIMIT 3];
        
        // Create multiple test coupons for the same opportunity using JSON
        List<chargebeeapps__CB_Opportunity_Coupon__c> testCBOppCoupons = new List<chargebeeapps__CB_Opportunity_Coupon__c>();
        
        String couponJson1 = '{"chargebeeapps__Opportunity__c":"' + testOpp.Id + '","chargebeeapps__CB_Coupon__c":"' + testCoupons[0].Id + '"}';
        testCBOppCoupons.add((chargebeeapps__CB_Opportunity_Coupon__c) JSON.deserialize(couponJson1, chargebeeapps__CB_Opportunity_Coupon__c.class));
        
        String couponJson2 = '{"chargebeeapps__Opportunity__c":"' + testOpp.Id + '","chargebeeapps__CB_Coupon__c":"' + testCoupons[1].Id + '"}';
        testCBOppCoupons.add((chargebeeapps__CB_Opportunity_Coupon__c) JSON.deserialize(couponJson2, chargebeeapps__CB_Opportunity_Coupon__c.class));
        
        String couponJson3 = '{"chargebeeapps__Opportunity__c":"' + testOpp.Id + '","chargebeeapps__CB_Coupon__c":"' + testCoupons[2].Id + '"}';
        testCBOppCoupons.add((chargebeeapps__CB_Opportunity_Coupon__c) JSON.deserialize(couponJson3, chargebeeapps__CB_Opportunity_Coupon__c.class));
        
        Test.startTest();
        insert testCBOppCoupons;
        Test.stopTest();
        
        // Verify opportunity was updated with total discount
        Opportunity updatedOpp = [SELECT Id, Coupon_Discount__c FROM Opportunity WHERE Id = :testOpp.Id];
        System.assertEquals(45.0, updatedOpp.Coupon_Discount__c, 'Coupon discount should be 45% (10+15+20)');
    }
    
    @IsTest
    static void testAfterInsert_MultipleCouponsDifferentOpportunities() {
        // Get test opportunities and coupons
        List<Opportunity> testOpps = [SELECT Id FROM Opportunity LIMIT 2];
        List<chargebeeapps__Coupon__c> testCoupons = [SELECT Id FROM chargebeeapps__Coupon__c LIMIT 2];
        
        // Create test coupons for different opportunities using JSON
        List<chargebeeapps__CB_Opportunity_Coupon__c> testCBOppCoupons = new List<chargebeeapps__CB_Opportunity_Coupon__c>();
        
        String couponJson1 = '{"chargebeeapps__Opportunity__c":"' + testOpps[0].Id + '","chargebeeapps__CB_Coupon__c":"' + testCoupons[0].Id + '"}';
        testCBOppCoupons.add((chargebeeapps__CB_Opportunity_Coupon__c) JSON.deserialize(couponJson1, chargebeeapps__CB_Opportunity_Coupon__c.class));
        
        String couponJson2 = '{"chargebeeapps__Opportunity__c":"' + testOpps[1].Id + '","chargebeeapps__CB_Coupon__c":"' + testCoupons[1].Id + '"}';
        testCBOppCoupons.add((chargebeeapps__CB_Opportunity_Coupon__c) JSON.deserialize(couponJson2, chargebeeapps__CB_Opportunity_Coupon__c.class));
        
        Test.startTest();
        insert testCBOppCoupons;
        Test.stopTest();
        
        // Verify both opportunities were updated
        List<Opportunity> updatedOpps = [SELECT Id, Coupon_Discount__c FROM Opportunity WHERE Id IN :testOpps ORDER BY Id];
        System.assertEquals(10.0, updatedOpps[0].Coupon_Discount__c, 'First opportunity coupon discount should be 10%');
        System.assertEquals(15.0, updatedOpps[1].Coupon_Discount__c, 'Second opportunity coupon discount should be 15%');
    }
    
    @IsTest
    static void testAfterUpdate_UpdateDiscount() {
        // Get test opportunity and coupon
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        chargebeeapps__Coupon__c testCoupon = [SELECT Id FROM chargebeeapps__Coupon__c LIMIT 1];
        
        // Create test coupon using JSON
        String couponJson = '{"chargebeeapps__Opportunity__c":"' + testOpp.Id + '","chargebeeapps__CB_Coupon__c":"' + testCoupon.Id + '"}';
        chargebeeapps__CB_Opportunity_Coupon__c testCBOppCoupon = (chargebeeapps__CB_Opportunity_Coupon__c) JSON.deserialize(couponJson, chargebeeapps__CB_Opportunity_Coupon__c.class);
        insert testCBOppCoupon;
        
        // Update the coupon's discount percentage
        testCoupon.chargebeeapps__Discount_Percentage__c = 25.0;
        update testCoupon;
        
        Test.startTest();
        // Manually trigger the update logic since the trigger only fires on CB_Opportunity_Coupon updates
        CBOpportunityCouponTriggerHandler.updateOpportunityCouponDiscounts(new List<chargebeeapps__CB_Opportunity_Coupon__c>{testCBOppCoupon});
        Test.stopTest();
        
        // Verify opportunity was updated with new discount
        Opportunity updatedOpp = [SELECT Id, Coupon_Discount__c FROM Opportunity WHERE Id = :testOpp.Id];
        System.assertEquals(25.0, updatedOpp.Coupon_Discount__c, 'Coupon discount should be updated to 25%');
    }
    
    @IsTest
    static void testAfterUpdate_AddNewCoupon() {
        // Get test opportunity and coupons
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        List<chargebeeapps__Coupon__c> testCoupons = [SELECT Id FROM chargebeeapps__Coupon__c LIMIT 2];
        
        // Create initial coupon using JSON
        String initialCouponJson = '{"chargebeeapps__Opportunity__c":"' + testOpp.Id + '","chargebeeapps__CB_Coupon__c":"' + testCoupons[0].Id + '"}';
        chargebeeapps__CB_Opportunity_Coupon__c initialCBOppCoupon = (chargebeeapps__CB_Opportunity_Coupon__c) JSON.deserialize(initialCouponJson, chargebeeapps__CB_Opportunity_Coupon__c.class);
        insert initialCBOppCoupon;
        
        // Add another coupon using JSON
        String newCouponJson = '{"chargebeeapps__Opportunity__c":"' + testOpp.Id + '","chargebeeapps__CB_Coupon__c":"' + testCoupons[1].Id + '"}';
        chargebeeapps__CB_Opportunity_Coupon__c newCBOppCoupon = (chargebeeapps__CB_Opportunity_Coupon__c) JSON.deserialize(newCouponJson, chargebeeapps__CB_Opportunity_Coupon__c.class);
        
        Test.startTest();
        insert newCBOppCoupon;
        Test.stopTest();
        
        // Verify opportunity was updated with total discount
        Opportunity updatedOpp = [SELECT Id, Coupon_Discount__c FROM Opportunity WHERE Id = :testOpp.Id];
        System.assertEquals(25.0, updatedOpp.Coupon_Discount__c, 'Coupon discount should be 25% (10+15)');
    }
    
    @IsTest
    static void testAfterUpdate_DeleteCoupon() {
        // Get test opportunity and coupons
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        List<chargebeeapps__Coupon__c> testCoupons = [SELECT Id FROM chargebeeapps__Coupon__c LIMIT 2];
        
        // Create multiple coupons using JSON
        List<chargebeeapps__CB_Opportunity_Coupon__c> testCBOppCoupons = new List<chargebeeapps__CB_Opportunity_Coupon__c>();
        
        String couponJson1 = '{"chargebeeapps__Opportunity__c":"' + testOpp.Id + '","chargebeeapps__CB_Coupon__c":"' + testCoupons[0].Id + '"}';
        testCBOppCoupons.add((chargebeeapps__CB_Opportunity_Coupon__c) JSON.deserialize(couponJson1, chargebeeapps__CB_Opportunity_Coupon__c.class));
        
        String couponJson2 = '{"chargebeeapps__Opportunity__c":"' + testOpp.Id + '","chargebeeapps__CB_Coupon__c":"' + testCoupons[1].Id + '"}';
        testCBOppCoupons.add((chargebeeapps__CB_Opportunity_Coupon__c) JSON.deserialize(couponJson2, chargebeeapps__CB_Opportunity_Coupon__c.class));
        
        insert testCBOppCoupons;

        testCoupons[0].Name = 'Test Coupon 1';
        testCoupons[1].Name = 'Test Coupon 2';
        update testCBOppCoupons;
        
        // Delete one coupon
        delete testCBOppCoupons[0];
        
        Test.startTest();
        // Manually trigger the update logic to simulate what would happen after deletion
        CBOpportunityCouponTriggerHandler.updateOpportunityCouponDiscounts(new List<chargebeeapps__CB_Opportunity_Coupon__c>{testCBOppCoupons[1]});
        Test.stopTest();
        
        // Verify opportunity was updated with remaining discount
        Opportunity updatedOpp = [SELECT Id, Coupon_Discount__c FROM Opportunity WHERE Id = :testOpp.Id];
        System.assertEquals(15.0, updatedOpp.Coupon_Discount__c, 'Coupon discount should be 15% after deletion');
    }
}
