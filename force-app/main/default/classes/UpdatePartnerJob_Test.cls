@isTest
private class UpdatePartnerJob_Test {
    
    @IsTest(SeeAllData=true)
    static void testUpdatePartner() {
        RecordType acctRecordType = [Select ID,DeveloperName From RecordType where DeveloperName='Customer' limit 1];
        RecordType acctPartnerResellerRecordType = [Select ID,DeveloperName From RecordType where DeveloperName='Reseller_Partner' limit 1];
        RecordType oppRecordType = [Select ID,DeveloperName From RecordType where DeveloperName='Cloud' limit 1];
        chargebeeapps__CB_Sites__c cbSite = [Select ID From chargebeeapps__CB_Sites__c limit 1];
        List<Account> acctList = new List<Account>();
        
        Account acct = new Account();
        acct.Name = 'Test Account 1';
        acct.Type = 'Client - Direct';
        acct.RecordType = acctRecordType;
        acct.Account_Status__c = 'Satisfied';
        acct.chargebeeapps__CB_Site__c = cbSite.Id;
        acct.Enhancement_Date__c = Date.Today().addYears(2);
        insert acct;
        
        Account partnerAcct = new Account();
        partnerAcct.Name = 'Partner Account 1';
        partnerAcct.Type = 'Partner - Reseller';
        partnerAcct.RecordType = acctPartnerResellerRecordType;
        insert partnerAcct;
        acctList.add(partnerAcct);
        
        Partner_Client_Relationship__c pcr = new Partner_Client_Relationship__c();
        pcr.Client__c = acct.Id;
        pcr.Partner__c = partnerAcct.Id;
        pcr.Partner_of_Record_Status__c = 'Current';
        pcr.Margin_Start_Date__c = Date.Today();
        pcr.Partner_Client_Margin_Eligibility__c = 'Active';
        insert pcr;
        
        /*Partner_Tier__c pt = new Partner_Tier__c();
        pt.Name = 'Gold Partner Tier';
        pt.Partner_Tier__c = 'Gold';
        pt.Partner_Tier_Start_Date__c = Date.Today();
        pt.PartnerTier_Status__c = 'Active';
        pt.Partner__c = partnerAcct.Id;
        insert pt;*/
        
        Pricebook2 pb = [Select ID From Pricebook2 where isActive = true AND Name Like '%CB Standard%' Order By createdDate Desc limit 1];

        Opportunity opp = new Opportunity();
        opp.Name = 'Opp Test';
        opp.AccountId = acct.Id;
        opp.Partner__c = partnerAcct.Id;
        opp.Type = 'Existing Business';
        opp.Subtype__c = 'Add-On';
        opp.chargebeeapps__Manual_Discount__c = '[{"type":"PERCENTAGE","period_unit":null,"period":null,"percentage":null,"operation_type":"add","item_price_id":null,"isPercentageDiscount":true,"isOneTime":true,"isLineItemDiscount":false,"isInvoiceDiscount":true,"isForever":false,"isFixedDiscount":false,"id":null,"duration_type":"one_time","discountType":"PERCENTAGE","discountPercentage":"25.00","discountAmount":null,"currency_code":"USD","cbId":"D_744989","apply_on":"invoice_amount","amount":null},{"type":"FIXED_AMOUNT","period_unit":null,"period":null,"percentage":null,"operation_type":"add","item_price_id":"DPS00068-USD-Yearly","isPercentageDiscount":false,"isOneTime":true,"isLineItemDiscount":true,"isInvoiceDiscount":false,"isForever":false,"isFixedDiscount":true,"id":null,"duration_type":"one_time","discountType":"FIXED_AMOUNT","discountPercentage":null,"discountAmount":"100.00","currency_code":"USD","cbId":"D_749212","apply_on":"specific_item_price","amount":"100.00"},{"type":"PERCENTAGE","period_unit":null,"period":null,"percentage":null,"operation_type":"add","item_price_id":"DPE00001","isPercentageDiscount":true,"isOneTime":true,"isLineItemDiscount":true,"isInvoiceDiscount":false,"isForever":false,"isFixedDiscount":false,"id":null,"duration_type":"one_time","discountType":"PERCENTAGE","discountPercentage":"10.00","discountAmount":null,"currency_code":"USD","cbId":"D_128587","apply_on":"specific_item_price","amount":null}]';
        opp.StageName = 'Structure';
        opp.CloseDate = Date.Today().addMonths(3);
        opp.Opportunity_Source_Global__c = 'Customer';
        opp.Pricebook2Id = pb.Id;
        opp.RecordTypeId = oppRecordType.Id;
        opp.Is_Coupon_Applied__c = true;
        insert opp;
        chargebeeapps__CB_Item_Price__c cbItemPrice = [Select ID From chargebeeapps__CB_Item_Price__c where Name = 'AUTOMATION AGENT - SUB USD Yearly' limit 1];
        chargebeeapps__CB_Item_Price__c cbItemPrice2 = [Select ID,chargebeeapps__Period_Unit__c,chargebeeapps__Period__c From chargebeeapps__CB_Item_Price__c where Name = 'AUTOMATION AGENT ENHANCEMENT' limit 1];
        chargebeeapps__CB_Item_Price__c cbItemPrice3 = [Select ID From chargebeeapps__CB_Item_Price__c where Name = 'AUTOMATION AGENT - SPLA USD Quarterly' limit 1];
        Product2 product = [Select ID,ProductCode From Product2 where Name = 'AUTOMATION AGENT - SUB' AND IsActive=true limit 1];
        Product2 product2 = [Select ID,ProductCode From Product2 where Name = 'AUTOMATION AGENT ENHANCEMENT' AND IsActive=true limit 1];
        PricebookEntry pbEntry2 = [Select ID From PricebookEntry where Name = 'AUTOMATION AGENT ENHANCEMENT' AND IsActive=true AND 	Pricebook2Id=:pb.Id limit 1];
        PricebookEntry pbEntry3 = [Select ID From PricebookEntry where Name = 'AUTOMATION AGENT - SPLA' AND IsActive=true AND Pricebook2Id=:pb.Id limit 1];
        
        OpportunityLineItem oppProduct = new OpportunityLineItem();
        oppProduct.OpportunityId = opp.Id;
        oppProduct.Product2Id = product.Id;
        oppProduct.Quantity = 1;
        oppProduct.Discount = 25;
        oppProduct.chargebeeapps__CB_Item_Price__c =cbItemPrice.Id;
        
        OpportunityLineItem oppProduct2 = new OpportunityLineItem();
        oppProduct2.OpportunityId = opp.Id;
        oppProduct2.Product2Id = product2.Id;
        oppProduct2.Quantity = 1;
        oppProduct2.Discount = 25;
        oppProduct2.chargebeeapps__CB_Item_Price__c =cbItemPrice2.Id;
        oppProduct2.PricebookEntryId = pbEntry2.Id;
        
        OpportunityLineItem oppProduct3 = new OpportunityLineItem();
        oppProduct3.OpportunityId = opp.Id;
        oppProduct3.Product2Id = product2.Id;
        oppProduct3.Quantity = 1;
        oppProduct3.Discount = 25;
        oppProduct3.chargebeeapps__CB_Item_Price__c =cbItemPrice3.Id;
        oppProduct3.PricebookEntryId = pbEntry3.Id;
        oppProduct3.Unit_Price__c = null;
        cbItemPrice2.chargebeeapps__Period_Unit__c = 'MONTH';
        cbItemPrice2.chargebeeapps__Period__c = 3;
        update cbItemPrice2;
        
        OpportunityLineItem oppProduct4 = new OpportunityLineItem();
        oppProduct4.OpportunityId = opp.Id;
        oppProduct4.Product2Id = product2.Id;
        oppProduct4.Quantity = 1;
        oppProduct4.Discount = 25;
        oppProduct4.chargebeeapps__CB_Item_Price__c =cbItemPrice2.Id;
        oppProduct4.PricebookEntryId = pbEntry2.Id;
        oppProduct4.Unit_Price__c = 100.00;
        
        List<OpportunityLineItem> oliList = new List<OpportunityLineItem> {oppProduct, oppProduct2, oppProduct3};
        insert oliList;
        
        chargebeeapps__CB_Subscription__c cbSub = new chargebeeapps__CB_Subscription__c();
        cbSub.chargebeeapps__Subscription_Plan__c = product.Id;
        cbSub.Name = 'Test Subscription';
        cbSub.chargebeeapps__Subscription_status__c = 'ACTIVE';
        cbsub.chargebeeapps__CB_Oppurtunity__c = Opp.Id;
        //cbSub.chargebeeapps__Company_name__c = ;
        cbSub.chargebeeapps__Company__c = partnerAcct.Id;
        cbSub.chargebeeapps__Current_Term_Start__c = Date.Today();
        cbSub.chargebeeapps__Current_Term_End__c = Date.Today().addDays(30);
        cbSub.chargebeeapps__CB_Item_Price__c = cbItemPrice.Id;
        cbSub.chargebeeapps__Plan_Quantity__c = 2;
        cbSub.chargebeeapps__Plan_Amount__c = 100;
        insert cbSub;
        
        chargebeeapps__Subscription_Addon__c addOn = new chargebeeapps__Subscription_Addon__c();
        addOn.chargebeeapps__Product__c = product.Id;
        addOn.chargebeeapps__Quantity__c = 1;
        addOn.chargebeeapps__Subscription__c = cbSub.Id;
        addOn.Name = 'Test Addon';
        addOn.chargebeeapps__Code__c = 'DPS00068';
        insert addOn;
        
        Partner_Margin__c pm1 = new Partner_Margin__c();
        pm1.Name = 'Test Partner Margin';
        pm1.Client__c = acct.Id;
        pm1.Partner__c = partnerAcct.Id;
        pm1.Opportunity__c = opp.Id;
        pm1.CB_Subscription_ID__c = cbSub.Id;
        pm1.Partner_Margin_Duration__c = 'On-going';
        pm1.Partner_Margin_Status__c = 'Billed through Partner';
        pm1.Partner_Margin_Type__c = 'Initial Purchase';
        insert pm1;
        Partner_Margin_Product__c pmp1 = new Partner_Margin_Product__c();
        pmp1.Name = 'Test Partner Margin Product';
        pmp1.Product_Code__c = 'DPS00068';
        pmp1.Quantity__c = 1;
   		pmp1.Opportunity_Product__c = oppProduct4.Id;
        pmp1.Partner_Margin__c = pm1.Id;
        insert pmp1;
        test.startTest();
			UpdatePartnerJob ba= new UpdatePartnerJob();
        	Id jobid= Database.executeBatch(ba);
        	ba.execute(null);
        test.stopTest();
    }

}