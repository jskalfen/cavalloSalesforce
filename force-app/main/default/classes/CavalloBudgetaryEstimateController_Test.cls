@isTest
private class CavalloBudgetaryEstimateController_Test {
    static testMethod void testQuotePDF() {
        Account a = new Account(Name = 'Ray Test',Type = 'Other', Customer_Class__c = 'Other');
        insert a;
        
        Opportunity opp = new Opportunity(AccountId = a.Id);
        opp.Name = 'Ray Test';
        opp.CloseDate = Date.today();
        opp.StageName = 'Sandbox';
        opp.Direct_v_Partner__c = 'Partner';
        opp.Existing_GP_or_New_GP__c = 'Existing GP';
        opp.Opportunity_SubSource_Global__c = 'Blog';
        opp.Opportunity_Source_Global__c = 'Marketing';
        //opp.Sales_Engineer__c = '0056A000002zXKeQAM';
        insert opp;
        
        Quote q = new Quote(OpportunityId = opp.Id);
        q.Name = 'Ray Test';
        insert q;
        
		Test.startTest();
        ApexPages.currentPage().getParameters().put('Id', q.Id);
        CavalloBudgetaryEstimateController con = new CavalloBudgetaryEstimateController(new ApexPages.StandardController(q));
        System.assertEquals('pdf', con.renderAs);
        System.assertEquals(Date.today().format(), con.today);
        con.saveAndOpenPDF();
    }
}