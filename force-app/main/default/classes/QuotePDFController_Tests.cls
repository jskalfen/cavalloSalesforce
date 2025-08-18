@isTest
private class QuotePDFController_Tests {
    @IsTest(SeeAllData=true)
    static void testQuotePDF() {
        Account acct = TestUtils.createAccount();
        Opportunity opp = TestUtils.createOpportunity(acct.Id, null);

        RecordType oppRecordType = [Select ID,DeveloperName From RecordType where DeveloperName='New_Business' limit 1];
        opp.RecordTypeId = oppRecordType.Id;
        
        Pricebook2 pb = [Select ID From Pricebook2 where isActive = true AND Name Like '%CB Standard%' limit 1];
        
        Quote q = new Quote(OpportunityId = opp.Id);
        q.Name = 'Ray Test';
        insert q;
        
		Test.startTest();
        ApexPages.currentPage().getParameters().put('Id', q.Id);
        QuotePDFController con = new QuotePDFController(new ApexPages.StandardController(q));
        System.assertEquals('pdf', con.renderAs);
        System.assertEquals(Date.today().format(), con.today);
        con.saveAndOpenPDF();
        Double d = 23.40;
        String currecyStr = Utility_Class.currencyStringFormatter(d);
    }

    static testMethod void testQuotePDFSubtotal() {
        Account acct = TestUtils.createAccount();
        Opportunity opp = TestUtils.createOpportunity(acct.Id, null);

        RecordType oppRecordType = [Select ID,DeveloperName From RecordType where DeveloperName='New_Business' limit 1];
        opp.RecordTypeId = oppRecordType.Id;
        
        Quote q = new Quote(OpportunityId = opp.Id);
        q.Name = 'Ray Test';
        insert q;
        
		Test.startTest();
        ApexPages.currentPage().getParameters().put('Id', q.Id);
        QuotePDFController con = new QuotePDFController(new ApexPages.StandardController(q));
        System.assertEquals('pdf', con.renderAs);
        System.assertEquals(Date.today().format(), con.today);
        con.saveAndOpenPDFSubtotal();
        Boolean showWatermark = con.showWaterMark;
    }
}