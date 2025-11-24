@isTest
public class OpportunityTriggerHandlerV2Tests {

    private static final String ACCOUNT_TYPE_CLIENT = 'Client';
    private static final String ACCOUNT_TYPE_PROSPECT = 'Prospect';
    private static final String STAGE_CLOSED_WON = 'Closed Won';
    private static final String STAGE_QUALIFY = 'Qualify';

    @isTest
    static void testAfterUpdate_OpportunityClosedWon_SetsAccountTypeToClient() {
        Account acc = new Account(
            Name = 'Test Account',
            Type = ACCOUNT_TYPE_PROSPECT
        );
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            StageName = STAGE_QUALIFY,
            CloseDate = Date.today().addDays(30)
        );
        insert opp;

        opp.StageName = STAGE_CLOSED_WON;

        Test.startTest();
        update opp;
        Test.stopTest();

        Account updatedAccount = [SELECT Type FROM Account WHERE Id = :acc.Id];
        System.assertEquals(ACCOUNT_TYPE_CLIENT, updatedAccount.Type, 
            'Account Type should be set to Client when opportunity is closed won');
    }

    @isTest
    static void testAfterUpdate_AccountAlreadyClient_DoesNotUpdate() {
        Account acc = new Account(
            Name = 'Test Account',
            Type = ACCOUNT_TYPE_CLIENT
        );
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            StageName = STAGE_QUALIFY,
            CloseDate = Date.today().addDays(30)
        );
        insert opp;

        opp.StageName = STAGE_CLOSED_WON;

        Test.startTest();
        update opp;
        Test.stopTest();

        Account updatedAccount = [SELECT Type FROM Account WHERE Id = :acc.Id];
        System.assertEquals(ACCOUNT_TYPE_CLIENT, updatedAccount.Type, 
            'Account Type should remain Client when already set');
    }
}
