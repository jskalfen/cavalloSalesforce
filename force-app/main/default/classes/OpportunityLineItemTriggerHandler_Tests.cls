@isTest
private class OpportunityLineItemTriggerHandler_Tests {
    
    @IsTest(SeeAllData=true)
    static void testOpportunityWithARR() {
        RecordType acctRecordType = [Select ID,DeveloperName From RecordType where DeveloperName='Customer' limit 1];
        RecordType oppRecordType = [Select ID,DeveloperName From RecordType where DeveloperName='Cloud' limit 1];
        chargebeeapps__CB_Sites__c cbSite = [Select ID From chargebeeapps__CB_Sites__c limit 1];
        Account acct = new Account();
        acct.Name = 'Test Account 1';
        acct.Type = 'Client - Direct';
        acct.RecordType = acctRecordType;
        acct.Account_Status__c = 'Satisfied';
        acct.chargebeeapps__CB_Site__c = cbSite.Id;
        acct.Enhancement_Date__c = Date.Today().addYears(2);
        
        Pricebook2 pb = [Select ID From Pricebook2 where isActive = true AND Name Like '%CB Standard%' Order By createdDate Desc limit 1];

        Opportunity opp = new Opportunity();
        opp.Name = 'Opp Test';
        opp.AccountId = acct.Id;
        opp.Type = 'Existing Business';
        opp.Subtype__c = 'Add-On';
        opp.chargebeeapps__Manual_Discount__c = '[{"type":"PERCENTAGE","period_unit":null,"period":null,"percentage":null,"operation_type":"add","item_price_id":null,"isPercentageDiscount":true,"isOneTime":true,"isLineItemDiscount":false,"isInvoiceDiscount":true,"isForever":false,"isFixedDiscount":false,"id":null,"duration_type":"one_time","discountType":"PERCENTAGE","discountPercentage":"25.00","discountAmount":null,"currency_code":"USD","cbId":"D_744989","apply_on":"invoice_amount","amount":null},{"type":"FIXED_AMOUNT","period_unit":null,"period":null,"percentage":null,"operation_type":"add","item_price_id":"DPS00068-USD-Yearly","isPercentageDiscount":false,"isOneTime":true,"isLineItemDiscount":true,"isInvoiceDiscount":false,"isForever":false,"isFixedDiscount":true,"id":null,"duration_type":"one_time","discountType":"FIXED_AMOUNT","discountPercentage":null,"discountAmount":"100.00","currency_code":"USD","cbId":"D_749212","apply_on":"specific_item_price","amount":"100.00"},{"type":"PERCENTAGE","period_unit":null,"period":null,"percentage":null,"operation_type":"add","item_price_id":"DPE00001","isPercentageDiscount":true,"isOneTime":true,"isLineItemDiscount":true,"isInvoiceDiscount":false,"isForever":false,"isFixedDiscount":false,"id":null,"duration_type":"one_time","discountType":"PERCENTAGE","discountPercentage":"10.00","discountAmount":null,"currency_code":"USD","cbId":"D_128587","apply_on":"specific_item_price","amount":null}]';
        opp.StageName = 'Structure';
        opp.CloseDate = Date.Today().addMonths(3);
        opp.Opportunity_Source_Global__c = 'Customer';
        opp.Pricebook2Id = pb.Id;
        opp.RecordTypeId = oppRecordType.Id;
        insert opp;
        chargebeeapps__CB_Item_Price__c cbItemPrice = [Select ID From chargebeeapps__CB_Item_Price__c where Name = 'AUTOMATION AGENT - SUB USD Yearly' limit 1];
        chargebeeapps__CB_Item_Price__c cbItemPrice2 = [Select ID,chargebeeapps__Period_Unit__c,chargebeeapps__Period__c From chargebeeapps__CB_Item_Price__c where Name = 'AUTOMATION AGENT ENHANCEMENT' limit 1];
        chargebeeapps__CB_Item_Price__c cbItemPrice3 = [Select ID From chargebeeapps__CB_Item_Price__c where Name = 'AUTOMATION AGENT - SPLA USD Quarterly' limit 1];
        Product2 product = [Select ID From Product2 where Name = 'AUTOMATION AGENT - SUB' AND IsActive=true limit 1];
        Product2 product2 = [Select ID From Product2 where Name = 'AUTOMATION AGENT ENHANCEMENT' AND IsActive=true limit 1];
        PricebookEntry pbEntry2 = [Select ID From PricebookEntry where Name = 'AUTOMATION AGENT ENHANCEMENT' AND IsActive=true AND 	Pricebook2Id=:pb.Id limit 1];
        PricebookEntry pbEntry3 = [Select ID From PricebookEntry where Name = 'AUTOMATION AGENT - SPLA' AND IsActive=true AND Pricebook2Id=:pb.Id limit 1];
        /*chargebeeapps__CB_Opportunity_Product__c cbOppProduct = new chargebeeapps__CB_Opportunity_Product__c();
        cbOppProduct.Name = 'CB Opp product';
        cbOppProduct.chargebeeapps__Opportunity__c = opp.Id;
        cbOppProduct.chargebeeapps__CB_Item_Price__c = cbItemPrice.Id;
        cbOppProduct.chargebeeapps__Product__c = product.Id;
        cbOppProduct.chargebeeapps__Quantity__c = 1;
        cbOppProduct.chargebeeapps__Unit_Price__c = 4000;
        insert cbOppProduct;*/
        OpportunityLineItem oppProduct = new OpportunityLineItem();
        oppProduct.OpportunityId = opp.Id;
        oppProduct.Product2Id = product.Id;
        oppProduct.Quantity = 1;
        oppProduct.Discount = 25;
        //oppProduct.ProductCode = 'DPS00068';
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
   
        test.startTest();
        insert oliList;
        //insert oppProduct2;
        //insert oppProduct3;
        product2.Business_Line__c = 'Professional Services';
        update product2;
        insert oppProduct4;
        
        test.stopTest();
    }
    
    @IsTest(SeeAllData=true)
    static void testOpportunityPartnerMargin() {
        RecordType acctRecordType = [Select ID,DeveloperName From RecordType where DeveloperName='Customer' limit 1];
        RecordType acctPartnerResellerRecordType = [Select ID,DeveloperName From RecordType where DeveloperName='Reseller_Partner' limit 1];
        RecordType oppRecordType = [Select ID,DeveloperName From RecordType where DeveloperName='Cloud' limit 1];
        chargebeeapps__CB_Sites__c cbSite = [Select ID From chargebeeapps__CB_Sites__c limit 1];
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
        
        Partner_Client_Relationship__c pcr = new Partner_Client_Relationship__c();
        pcr.Client__c = acct.Id;
        pcr.Partner__c = partnerAcct.Id;
        pcr.Partner_of_Record_Status__c = 'Current';
        pcr.Margin_Start_Date__c = Date.Today();
        pcr.Partner_Client_Margin_Eligibility__c = 'Active';
        insert pcr;
        
        Partner_Tier__c pt = new Partner_Tier__c();
        pt.Name = 'Gold Partner Tier';
        pt.Partner_Tier__c = 'Gold';
        pt.Partner_Tier_Start_Date__c = Date.Today();
        pt.Partner__c = partnerAcct.Id;
        insert pt;
        
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
        insert opp;
        chargebeeapps__CB_Item_Price__c cbItemPrice = [Select ID From chargebeeapps__CB_Item_Price__c where Name = 'AUTOMATION AGENT - SUB USD Yearly' limit 1];
        chargebeeapps__CB_Item_Price__c cbItemPrice2 = [Select ID,chargebeeapps__Period_Unit__c,chargebeeapps__Period__c From chargebeeapps__CB_Item_Price__c where Name = 'AUTOMATION AGENT ENHANCEMENT' limit 1];
        chargebeeapps__CB_Item_Price__c cbItemPrice3 = [Select ID From chargebeeapps__CB_Item_Price__c where Name = 'AUTOMATION AGENT - SPLA USD Quarterly' limit 1];
        Product2 product = [Select ID From Product2 where Name = 'AUTOMATION AGENT - SUB' AND IsActive=true limit 1];
        Product2 product2 = [Select ID From Product2 where Name = 'AUTOMATION AGENT ENHANCEMENT' AND IsActive=true limit 1];
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
   
        test.startTest();
        insert oliList;
        //insert oppProduct2;
        //insert oppProduct3;
        product2.Business_Line__c = 'Professional Services';
        update product2;
        insert oppProduct4;
        
        test.stopTest();
    }
}