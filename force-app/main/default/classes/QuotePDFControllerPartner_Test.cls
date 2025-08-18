@isTest(seeAllData=True)
private class QuotePDFControllerPartner_Test {
    private static Pricebook2 pb;
    private static Product2 prod;
    private static Product2 prod2;
    private static PricebookEntry pbe;
    private static PricebookEntry pbe2;
    public static Id newBusiness;
    
    static { 
        newBusiness = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('New_Business').getRecordTypeId();
        pb = [SELECT Id, isActive FROM Pricebook2 WHERE isStandard=true and Name='Standard Price Book'];
        
        if (!pb.isActive) {
            pb.isActive = true;
            update(pb);
        }           
        
        prod = new Product2(Name='AUTOMATION AGENT - SUB', IsActive=true, ProductCode = 'test code', Family = 'Desktop_Subscription');             
        insert(prod);
        prod2 = new Product2(Name='AUTOMATION AGENT - SUB', IsActive=true, ProductCode = 'test code', Family = 'SALESPAD_SUBSCRIPTION');             
        insert(prod2);

        pbe = new PricebookEntry(Pricebook2Id=pb.Id, Product2Id=prod.Id, IsActive=true, UnitPrice=10);
        insert(pbe);
        pbe2 =new PricebookEntry(Pricebook2Id=pb.Id, Product2Id=prod2.Id, IsActive=true, UnitPrice=10);
        insert(pbe2);                   
    }

	@isTest(seeAllData=True)
    static void testQuotePDF() {
        Account a = new Account(Name = 'Test Acct', Type = 'Other', Customer_Class__c = 'Other', Enhancement_Date__c = Date.today().addYears(2), Partner_level__c ='Gold');
        insert a;

        PricebookEntry pbEntry2 = [Select ID From PricebookEntry WHERE Name = 'AUTOMATION AGENT - SUB' AND IsActive=true AND Pricebook2Id=:pb.Id AND Product2Id=:prod.Id limit 1];
        
        Opportunity opp = new Opportunity(AccountId = a.Id);
        opp.Name = 'Test Opp';
        opp.CloseDate = Date.today();
        opp.StageName = 'Sandbox';
        opp.Direct_v_Partner__c = 'Partner';
        opp.Type='Existing Business';
        opp.Existing_GP_or_New_GP__c = 'Existing GP';
        opp.RecordTypeId = newBusiness;
        opp.Pricebook2Id = pb.Id;
        opp.Partner__c = a.Id;
        opp.chargebeeapps__Manual_Discount__c = '[{"type":"PERCENTAGE","period_unit":null,"period":null,"percentage":null,"operation_type":"add","item_price_id":null,"isPercentageDiscount":true,"isOneTime":true,"isLineItemDiscount":false,"isInvoiceDiscount":true,"isForever":false,"isFixedDiscount":false,"id":null,"duration_type":"one_time","discountType":"PERCENTAGE","discountPercentage":"25.00","discountAmount":null,"currency_code":"USD","cbId":"D_744989","apply_on":"invoice_amount","amount":null},{"type":"FIXED_AMOUNT","period_unit":null,"period":null,"percentage":null,"operation_type":"add","item_price_id":"DPS00068-USD-Yearly","isPercentageDiscount":false,"isOneTime":true,"isLineItemDiscount":true,"isInvoiceDiscount":false,"isForever":false,"isFixedDiscount":true,"id":null,"duration_type":"one_time","discountType":"FIXED_AMOUNT","discountPercentage":null,"discountAmount":"100.00","currency_code":"USD","cbId":"D_749212","apply_on":"specific_item_price","amount":"100.00"},{"type":"PERCENTAGE","period_unit":null,"period":null,"percentage":null,"operation_type":"add","item_price_id":"DPE00001","isPercentageDiscount":true,"isOneTime":true,"isLineItemDiscount":true,"isInvoiceDiscount":false,"isForever":false,"isFixedDiscount":false,"id":null,"duration_type":"one_time","discountType":"PERCENTAGE","discountPercentage":"10.00","discountAmount":null,"currency_code":"USD","cbId":"D_128587","apply_on":"specific_item_price","amount":null}]';
        opp.account = a;
        insert opp;
        
        Quote q = new Quote(OpportunityId = opp.Id);
        q.Name = 'Test Quote';
        q.Term_Length__c = 3;
        q.Contract_Start_Date__c = System.Today();
        q.Contract_End_Date__c = System.Today().addYears(2);
        q.Pricebook2Id = opp.Pricebook2Id;
        q.OpportunityId = opp.Id;
        q.Opportunity = opp;
        insert q;
        
        pbe =  [SELECT Id, Name,IsActive,UnitPrice FROM PricebookEntry WHERE IsActive=true AND Product2Id=:prod.Id AND Pricebook2Id=:opp.Pricebook2Id AND Pricebook2.isStandard=true AND Pricebook2.IsActive = true];
        QuoteLineItem qli = new QuoteLineItem(QuoteId=q.Id, Quantity=1, Discount=5, ServiceDate=System.today(),Product2=prod, Product2Id=prod.Id,PricebookEntryId=pbEntry2.Id,UnitPrice=100); 
        insert qli; 
        
        Test.startTest();
        
        ApexPages.currentPage().getParameters().put('Id', q.Id);
        QuotePDFControllerPartner con = new QuotePDFControllerPartner(new ApexPages.StandardController(q));
        System.assertEquals('pdf', con.renderAs);
        System.assertEquals(Date.today().format(), con.today);

        QuoteLinesForPDF__mdt quoteDetail = [Select ID,QuoteLineId__c,Quote_LineItem_Description__c,QuoteLineName__c From QuoteLinesForPDF__mdt where QuoteLineName__c=:prod.Name];
        quoteDetail.QuoteLineId__c = prod.Id;
        quoteDetail.Quote_LineItem_Description__c = 'Test Description';
        quoteDetail.QuoteLineName__c = prod.Name;
        con.subscriptionProductsListPriceMap = new Map<Id,Decimal>();
        con.subscriptionProductsDiscountPriceMap = new Map<Id,Decimal>();
        con.quoteLineProductsTobeConsidered.put(prod.Id,prod.Name);
        con.subscriptionProductsListPriceMap.put(q.Id,100.00);
        con.subscriptionProductsDiscountPriceMap.put(q.Id,10.00);
        con.populateLineDescription();
        con.saveAndOpenPDF();
        Map<Id, Product2> productMap = new Map<Id, Product2>();
        productMap.put(prod.Id, prod);
    }

    @isTest(seeAllData=True)
    static void testQuotePDFNewLogo() {
        Account a = new Account(Name = 'Test Acct', Type = 'Other', Customer_Class__c = 'Other', Enhancement_Date__c = Date.today().addYears(2), Partner_level__c ='Gold');
        insert a;

        PricebookEntry pbEntry2 = [Select ID From PricebookEntry WHERE Name = 'AUTOMATION AGENT - SUB' AND IsActive=true AND Pricebook2Id=:pb.Id AND Product2Id=:prod.Id limit 1];
        
        Opportunity opp = new Opportunity(AccountId = a.Id);
        opp.Name = 'Test Opp';
        opp.CloseDate = Date.today();
        opp.StageName = 'Discovery';
        opp.Direct_v_Partner__c = 'Partner';
        opp.Type='New Logo';
        opp.RecordTypeId = newBusiness;
        opp.Pricebook2Id = pb.Id;
        opp.Partner__c = a.Id;
        opp.chargebeeapps__Manual_Discount__c = '[{"type":"PERCENTAGE","period_unit":null,"period":null,"percentage":null,"operation_type":"add","item_price_id":null,"isPercentageDiscount":true,"isOneTime":true,"isLineItemDiscount":false,"isInvoiceDiscount":true,"isForever":false,"isFixedDiscount":false,"id":null,"duration_type":"one_time","discountType":"PERCENTAGE","discountPercentage":"25.00","discountAmount":null,"currency_code":"USD","cbId":"D_744989","apply_on":"invoice_amount","amount":null},{"type":"FIXED_AMOUNT","period_unit":null,"period":null,"percentage":null,"operation_type":"add","item_price_id":"DPS00068-USD-Yearly","isPercentageDiscount":false,"isOneTime":true,"isLineItemDiscount":true,"isInvoiceDiscount":false,"isForever":false,"isFixedDiscount":true,"id":null,"duration_type":"one_time","discountType":"FIXED_AMOUNT","discountPercentage":null,"discountAmount":"100.00","currency_code":"USD","cbId":"D_749212","apply_on":"specific_item_price","amount":"100.00"},{"type":"PERCENTAGE","period_unit":null,"period":null,"percentage":null,"operation_type":"add","item_price_id":"DPE00001","isPercentageDiscount":true,"isOneTime":true,"isLineItemDiscount":true,"isInvoiceDiscount":false,"isForever":false,"isFixedDiscount":false,"id":null,"duration_type":"one_time","discountType":"PERCENTAGE","discountPercentage":"10.00","discountAmount":null,"currency_code":"USD","cbId":"D_128587","apply_on":"specific_item_price","amount":null}]';
        opp.account = a;
        insert opp;
        
        Quote q = new Quote(OpportunityId = opp.Id);
        q.Name = 'Test Quote';
        q.Term_Length__c = 3;
        q.Contract_Start_Date__c = System.Today();
        q.Contract_End_Date__c = System.Today().addYears(2);
        q.Pricebook2Id = opp.Pricebook2Id;
        q.OpportunityId = opp.Id;
        q.Opportunity = opp;
        insert q;
        
        pbe =  [SELECT Id, Name,IsActive,UnitPrice FROM PricebookEntry WHERE IsActive=true AND Product2Id=:prod.Id AND Pricebook2Id=:opp.Pricebook2Id AND Pricebook2.isStandard=true AND Pricebook2.IsActive = true];
        QuoteLineItem qli = new QuoteLineItem(QuoteId=q.Id, Quantity=1, Discount=5, ServiceDate=System.today(),Product2=prod, Product2Id=prod.Id,PricebookEntryId=pbEntry2.Id,UnitPrice=100); 
        insert qli; 
        
        Test.startTest();
        
        ApexPages.currentPage().getParameters().put('Id', q.Id);
        QuotePDFControllerPartner con = new QuotePDFControllerPartner(new ApexPages.StandardController(q));
        System.assertEquals('pdf', con.renderAs);
        System.assertEquals(Date.today().format(), con.today);

    }

    @isTest(seeAllData=True)
    static void testQuotePDFExpansion() {
        Account a = new Account(Name = 'Test Acct', Type = 'Other', Customer_Class__c = 'Other', Enhancement_Date__c = Date.today().addYears(2), Partner_level__c ='Gold');
        insert a;

        PricebookEntry pbEntry2 = [Select ID From PricebookEntry WHERE Name = 'AUTOMATION AGENT - SUB' AND IsActive=true AND Pricebook2Id=:pb.Id AND Product2Id=:prod.Id limit 1];
        
        Opportunity opp = new Opportunity(AccountId = a.Id);
        opp.Name = 'Test Opp';
        opp.CloseDate = Date.today();
        opp.StageName = 'Discovery';
        opp.Direct_v_Partner__c = 'Partner';
        opp.Type='Expansion - New services';
        opp.RecordTypeId = newBusiness;
        opp.Pricebook2Id = pb.Id;
        opp.Partner__c = a.Id;
        opp.chargebeeapps__Manual_Discount__c = '[{"type":"PERCENTAGE","period_unit":null,"period":null,"percentage":null,"operation_type":"add","item_price_id":null,"isPercentageDiscount":true,"isOneTime":true,"isLineItemDiscount":false,"isInvoiceDiscount":true,"isForever":false,"isFixedDiscount":false,"id":null,"duration_type":"one_time","discountType":"PERCENTAGE","discountPercentage":"25.00","discountAmount":null,"currency_code":"USD","cbId":"D_744989","apply_on":"invoice_amount","amount":null},{"type":"FIXED_AMOUNT","period_unit":null,"period":null,"percentage":null,"operation_type":"add","item_price_id":"DPS00068-USD-Yearly","isPercentageDiscount":false,"isOneTime":true,"isLineItemDiscount":true,"isInvoiceDiscount":false,"isForever":false,"isFixedDiscount":true,"id":null,"duration_type":"one_time","discountType":"FIXED_AMOUNT","discountPercentage":null,"discountAmount":"100.00","currency_code":"USD","cbId":"D_749212","apply_on":"specific_item_price","amount":"100.00"},{"type":"PERCENTAGE","period_unit":null,"period":null,"percentage":null,"operation_type":"add","item_price_id":"DPE00001","isPercentageDiscount":true,"isOneTime":true,"isLineItemDiscount":true,"isInvoiceDiscount":false,"isForever":false,"isFixedDiscount":false,"id":null,"duration_type":"one_time","discountType":"PERCENTAGE","discountPercentage":"10.00","discountAmount":null,"currency_code":"USD","cbId":"D_128587","apply_on":"specific_item_price","amount":null}]';
        opp.account = a;
        insert opp;
        
        Quote q = new Quote(OpportunityId = opp.Id);
        q.Name = 'Test Quote';
        q.Term_Length__c = 3;
        q.Contract_Start_Date__c = System.Today();
        q.Contract_End_Date__c = System.Today().addYears(2);
        q.Pricebook2Id = opp.Pricebook2Id;
        q.OpportunityId = opp.Id;
        q.Opportunity = opp;
        insert q;
        
        pbe =  [SELECT Id, Name,IsActive,UnitPrice FROM PricebookEntry WHERE IsActive=true AND Product2Id=:prod.Id AND Pricebook2Id=:opp.Pricebook2Id AND Pricebook2.isStandard=true AND Pricebook2.IsActive = true];
        QuoteLineItem qli = new QuoteLineItem(QuoteId=q.Id, Quantity=1, Discount=5, ServiceDate=System.today(),Product2=prod, Product2Id=prod.Id,PricebookEntryId=pbEntry2.Id,UnitPrice=100); 
        insert qli; 
        
        Test.startTest();
        
        ApexPages.currentPage().getParameters().put('Id', q.Id);
        QuotePDFControllerPartner con = new QuotePDFControllerPartner(new ApexPages.StandardController(q));
        System.assertEquals('pdf', con.renderAs);
        System.assertEquals(Date.today().format(), con.today);

    }

}