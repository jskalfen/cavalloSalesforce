@isTest
private class QuotePDFControllerVAR_Tests {
    @IsTest(SeeAllData=true)
    static void testQuotePDF() {
        RecordType oppRecordType = [Select ID,DeveloperName From RecordType where DeveloperName='New_Business' limit 1];
        Account a = new Account(Name = 'Ray Test',Type = 'Other', Customer_Class__c = 'Other');
        insert a;
        
        Pricebook2 pb = [Select ID From Pricebook2 where isActive = true AND Name Like '%CB Standard%' limit 1];
        
        Opportunity opp = new Opportunity();
        opp.Name = 'Opp Test';
        opp.AccountId = a.Id;
        opp.Type = 'Existing Business';
        opp.chargebeeapps__Manual_Discount__c = '[{"type":"PERCENTAGE","period_unit":null,"period":null,"percentage":null,"operation_type":"add","item_price_id":null,"isPercentageDiscount":true,"isOneTime":true,"isLineItemDiscount":false,"isInvoiceDiscount":true,"isForever":false,"isFixedDiscount":false,"id":null,"duration_type":"one_time","discountType":"PERCENTAGE","discountPercentage":"25.00","discountAmount":null,"currency_code":"USD","cbId":"D_744989","apply_on":"invoice_amount","amount":null},{"type":"FIXED_AMOUNT","period_unit":null,"period":null,"percentage":null,"operation_type":"add","item_price_id":"DPS00068-USD-Yearly","isPercentageDiscount":false,"isOneTime":true,"isLineItemDiscount":true,"isInvoiceDiscount":false,"isForever":false,"isFixedDiscount":true,"id":null,"duration_type":"one_time","discountType":"FIXED_AMOUNT","discountPercentage":null,"discountAmount":"100.00","currency_code":"USD","cbId":"D_749212","apply_on":"specific_item_price","amount":"100.00"},{"type":"PERCENTAGE","period_unit":null,"period":null,"percentage":null,"operation_type":"add","item_price_id":"DPE00001","isPercentageDiscount":true,"isOneTime":true,"isLineItemDiscount":true,"isInvoiceDiscount":false,"isForever":false,"isFixedDiscount":false,"id":null,"duration_type":"one_time","discountType":"PERCENTAGE","discountPercentage":"10.00","discountAmount":null,"currency_code":"USD","cbId":"D_128587","apply_on":"specific_item_price","amount":null}]';
        opp.StageName = 'Structure';
        opp.CloseDate = Date.Today().addMonths(3);
        opp.Opportunity_Source_Global__c = 'Customer';
        opp.Pricebook2Id = pb.Id;
        opp.RecordTypeId = oppRecordType.Id;
        insert opp;
        
        Quote q = new Quote(OpportunityId = opp.Id);
        q.Name = 'Ray Test';
        insert q;
        
        Test.startTest();
        ApexPages.currentPage().getParameters().put('Id', q.Id);
        QuotePDFControllerVAR con = new QuotePDFControllerVAR(new ApexPages.StandardController(q));
        System.assertEquals('pdf', con.renderAs);
        System.assertEquals(Date.today().format(), con.today);
        con.saveAndOpenPDF();
        Boolean showWatermark = con.showWaterMark;
    }
}