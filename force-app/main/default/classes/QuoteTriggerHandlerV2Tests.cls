@isTest
public class QuoteTriggerHandlerV2Tests {

    @isTest
    static void testBeforeInsert_SetsQuoteNameFromOpportunity() {
        Account acc = new Account(
            Name = 'Test Account'
        );
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity Name',
            AccountId = acc.Id,
            StageName = 'Qualify',
            CloseDate = Date.today().addDays(30),
            Business_Segment__c = 'SalesPad'
        );
        insert opp;

        Quote quote = new Quote(
            OpportunityId = opp.Id
        );

        Test.startTest();
        insert quote;
        Test.stopTest();

        Quote insertedQuote = [SELECT Name FROM Quote WHERE Id = :quote.Id];
        System.assertEquals(opp.Name, insertedQuote.Name, 
            'Quote Name should be set to Opportunity Name');
    }
}
