@isTest
private class AccountTriggerHandlerTest {

    // ──────────────────────────────────────────────────────────
    // shouldAccountBeProcessed — unit tests
    // ──────────────────────────────────────────────────────────

    @isTest
    static void shouldValidateNewAccountNeedingProcessing() {
        Account acc = new Account(
            Name = 'Test Acc', Type = 'Client - Direct',
            Enhancement_Date__c = System.today(), Enhancement_Status__c = 'Current', Enhancement_Amount__c = 50);

        System.assert(AccountTriggerHandler.shouldAccountBeProcessed(acc, null));
    }

    @isTest
    static void shouldNotValidateNewAccountMissingEnhancementDate() {
        Account acc = new Account(
            Name = 'Test Acc', Type = 'Client - Direct',
            Enhancement_Status__c = 'Current', Enhancement_Amount__c = 50);

        System.assert(!AccountTriggerHandler.shouldAccountBeProcessed(acc, null));
    }

    @isTest
    static void shouldNotValidateNewAccountMissingEnhancementAmount() {
        Account acc = new Account(
            Name = 'Test Acc', Type = 'Client - Direct',
            Enhancement_Date__c = System.today(), Enhancement_Status__c = 'Current');

        System.assert(!AccountTriggerHandler.shouldAccountBeProcessed(acc, null));
    }

    @isTest
    static void shouldNotValidateNewAccountMissingEnhancementStatus() {
        Account acc = new Account(
            Name = 'Test Acc', Type = 'Client - Direct',
            Enhancement_Date__c = System.today(), Enhancement_Amount__c = 50);

        System.assert(!AccountTriggerHandler.shouldAccountBeProcessed(acc, null));
    }

    @isTest
    static void shouldValidateExistingAccountNeedingProcessing() {
        Account oldAcc = new Account(
            Name = 'Test Acc', Type = 'Client - Direct',
            Enhancement_Date__c = System.today(), Enhancement_Status__c = 'Current', Enhancement_Amount__c = 49);
        Account acc = new Account(
            Name = 'Test Acc', Type = 'Client - Direct',
            Enhancement_Date__c = System.today(), Enhancement_Status__c = 'Current', Enhancement_Amount__c = 50);

        System.assert(AccountTriggerHandler.shouldAccountBeProcessed(acc, oldAcc));
    }

    @isTest
    static void shouldNotValidateAccountUpdatedWithFieldsNotChanging() {
        Account oldAcc = new Account(
            Name = 'Test Acc', Type = 'Client - Direct',
            Enhancement_Date__c = System.today(), Enhancement_Status__c = 'Current', Enhancement_Amount__c = 49);
        Account acc = new Account(
            Name = 'Test Acc', Type = 'Client - Direct',
            Enhancement_Date__c = System.today(), Enhancement_Status__c = 'Current', Enhancement_Amount__c = 49);

        System.assert(!AccountTriggerHandler.shouldAccountBeProcessed(acc, oldAcc));
    }

    @isTest
    static void shouldNotValidateExistingAccountExEndUserCloud() {
        Account oldAcc = new Account(
            Name = 'Test Acc', Type = 'End User', Customer_Class__c = 'Ex end user Cloud',
            Enhancement_Date__c = System.today(), Enhancement_Status__c = 'Current', Enhancement_Amount__c = 49);
        Account acc = new Account(
            Name = 'Test Acc', Type = 'End User', Customer_Class__c = 'Ex end user Cloud',
            Enhancement_Date__c = System.today(), Enhancement_Status__c = 'Current', Enhancement_Amount__c = 50);

        System.assert(!AccountTriggerHandler.shouldAccountBeProcessed(acc, oldAcc));
    }

    @isTest
    static void shouldNotValidateExistingAccountExEndUserDesktop() {
        Account oldAcc = new Account(
            Name = 'Test Acc', Type = 'End User', Customer_Class__c = 'Ex end user Desktop',
            Enhancement_Date__c = System.today(), Enhancement_Status__c = 'Current', Enhancement_Amount__c = 49);
        Account acc = new Account(
            Name = 'Test Acc', Type = 'End User', Customer_Class__c = 'Ex end user Desktop',
            Enhancement_Date__c = System.today(), Enhancement_Status__c = 'Current', Enhancement_Amount__c = 50);

        System.assert(!AccountTriggerHandler.shouldAccountBeProcessed(acc, oldAcc));
    }

    @isTest
    static void shouldValidateEndUserNotExEndUser() {
        Account acc = new Account(
            Name = 'Test Acc', Type = 'End User', Customer_Class__c = 'Active end user',
            Enhancement_Date__c = System.today(), Enhancement_Status__c = 'Current', Enhancement_Amount__c = 50);

        System.assert(AccountTriggerHandler.shouldAccountBeProcessed(acc, null));
    }

    @isTest
    static void shouldValidateRegisteredToPartnerType() {
        Account acc = new Account(
            Name = 'Test Acc', Type = 'Client - Registered to Partner',
            Enhancement_Date__c = System.today(), Enhancement_Status__c = 'Current', Enhancement_Amount__c = 50);

        System.assert(AccountTriggerHandler.shouldAccountBeProcessed(acc, null));
    }

    @isTest
    static void shouldNotValidateUnsupportedAccountType() {
        Account acc = new Account(
            Name = 'Test Acc', Type = 'Other',
            Enhancement_Date__c = System.today(), Enhancement_Status__c = 'Current', Enhancement_Amount__c = 50);

        System.assert(!AccountTriggerHandler.shouldAccountBeProcessed(acc, null));
    }

    // ──────────────────────────────────────────────────────────
    // handleBeforeInsertAndUpdate — ABR timestamp tests
    // ──────────────────────────────────────────────────────────

    @isTest
    static void shouldStampABRScheduledDateSetOnInsert() {
        Account acc = new Account(
            Name = 'ABR Test', Type = 'Other',
            ABR_Scheduled_Date__c = System.today());

        Test.startTest();
        insert acc;
        Test.stopTest();

        Account result = [SELECT ABR_Scheduled_Date_Set__c FROM Account WHERE Id = :acc.Id];
        System.assertNotEquals(null, result.ABR_Scheduled_Date_Set__c,
            'ABR_Scheduled_Date_Set__c should be stamped when ABR_Scheduled_Date__c is populated on insert');
    }

    @isTest
    static void shouldStampABRHappenedSetOnInsert() {
        Account acc = new Account(
            Name = 'ABR Test', Type = 'Other',
            ABR_Happened__c = true);

        Test.startTest();
        insert acc;
        Test.stopTest();

        Account result = [SELECT ABR_Happened_Set__c FROM Account WHERE Id = :acc.Id];
        System.assertNotEquals(null, result.ABR_Happened_Set__c,
            'ABR_Happened_Set__c should be stamped when ABR_Happened__c is set to true on insert');
    }

    @isTest
    static void shouldNotStampABRFieldsWhenNotPopulatedOnInsert() {
        Account acc = new Account(Name = 'ABR Test', Type = 'Other');

        Test.startTest();
        insert acc;
        Test.stopTest();

        Account result = [SELECT ABR_Scheduled_Date_Set__c, ABR_Happened_Set__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(null, result.ABR_Scheduled_Date_Set__c,
            'ABR_Scheduled_Date_Set__c should not be stamped when ABR_Scheduled_Date__c is null');
        System.assertEquals(null, result.ABR_Happened_Set__c,
            'ABR_Happened_Set__c should not be stamped when ABR_Happened__c is false');
    }

    @isTest
    static void shouldStampABRScheduledDateSetOnUpdate() {
        Account acc = new Account(Name = 'ABR Test', Type = 'Other');
        insert acc;

        Test.startTest();
        update new Account(Id = acc.Id, ABR_Scheduled_Date__c = System.today());
        Test.stopTest();

        Account result = [SELECT ABR_Scheduled_Date_Set__c FROM Account WHERE Id = :acc.Id];
        System.assertNotEquals(null, result.ABR_Scheduled_Date_Set__c,
            'ABR_Scheduled_Date_Set__c should be stamped when ABR_Scheduled_Date__c is first populated on update');
    }

    @isTest
    static void shouldStampABRHappenedSetOnUpdate() {
        Account acc = new Account(Name = 'ABR Test', Type = 'Other');
        insert acc;

        Test.startTest();
        update new Account(Id = acc.Id, ABR_Happened__c = true);
        Test.stopTest();

        Account result = [SELECT ABR_Happened_Set__c FROM Account WHERE Id = :acc.Id];
        System.assertNotEquals(null, result.ABR_Happened_Set__c,
            'ABR_Happened_Set__c should be stamped when ABR_Happened__c is first set to true on update');
    }

    @isTest
    static void shouldNotOverwriteABRScheduledDateSetOnSubsequentUpdate() {
        Account acc = new Account(
            Name = 'ABR Test', Type = 'Other',
            ABR_Scheduled_Date__c = System.today());
        insert acc;

        Account afterInsert = [SELECT ABR_Scheduled_Date_Set__c FROM Account WHERE Id = :acc.Id];
        DateTime originalStamp = afterInsert.ABR_Scheduled_Date_Set__c;
        System.assertNotEquals(null, originalStamp);

        Test.startTest();
        update new Account(Id = acc.Id, ABR_Scheduled_Date__c = System.today() + 30);
        Test.stopTest();

        Account result = [SELECT ABR_Scheduled_Date_Set__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(originalStamp, result.ABR_Scheduled_Date_Set__c,
            'ABR_Scheduled_Date_Set__c should not change on subsequent updates');
    }

    @isTest
    static void shouldNotOverwriteABRHappenedSetOnSubsequentUpdate() {
        Account acc = new Account(
            Name = 'ABR Test', Type = 'Other',
            ABR_Happened__c = true);
        insert acc;

        Account afterInsert = [SELECT ABR_Happened_Set__c FROM Account WHERE Id = :acc.Id];
        DateTime originalStamp = afterInsert.ABR_Happened_Set__c;
        System.assertNotEquals(null, originalStamp);

        // Toggle off and back on — timestamp should remain unchanged
        update new Account(Id = acc.Id, ABR_Happened__c = false);

        Test.startTest();
        update new Account(Id = acc.Id, ABR_Happened__c = true);
        Test.stopTest();

        Account result = [SELECT ABR_Happened_Set__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(originalStamp, result.ABR_Happened_Set__c,
            'ABR_Happened_Set__c should not change when ABR_Happened__c is toggled off and back on');
    }

    @isTest
    static void shouldStampBothABRFieldsOnInsert() {
        Account acc = new Account(
            Name = 'ABR Test', Type = 'Other',
            ABR_Scheduled_Date__c = System.today(),
            ABR_Happened__c = true);

        Test.startTest();
        insert acc;
        Test.stopTest();

        Account result = [SELECT ABR_Scheduled_Date_Set__c, ABR_Happened_Set__c FROM Account WHERE Id = :acc.Id];
        System.assertNotEquals(null, result.ABR_Scheduled_Date_Set__c,
            'ABR_Scheduled_Date_Set__c should be stamped');
        System.assertNotEquals(null, result.ABR_Happened_Set__c,
            'ABR_Happened_Set__c should be stamped');
    }

    // ──────────────────────────────────────────────────────────
    // handleAfterInsertAndUpdate — Enhancement / Renewal Opp tests
    // ──────────────────────────────────────────────────────────

    @isTest
    static void shouldNotCreateOppsWhenNoCriteriaAccountsInserted() {
        List<Account> accts = new List<Account>{
            new Account(Name = 'Test Acc1', Type = 'Client - Direct',
                Enhancement_Status__c = 'Current', Enhancement_Amount__c = 50),
            new Account(Name = 'Test Acc2', Type = 'Client - Direct',
                Enhancement_Date__c = System.today(), Enhancement_Amount__c = 50),
            new Account(Name = 'Test Acc3', Type = 'Client - Direct',
                Enhancement_Date__c = System.today(), Enhancement_Status__c = 'Current'),
            new Account(Name = 'Test Acc4', Type = 'End User', Customer_Class__c = 'Ex end user Cloud',
                Enhancement_Date__c = System.today(), Enhancement_Status__c = 'Current', Enhancement_Amount__c = 50),
            new Account(Name = 'Test Acc5', Type = 'Other',
                Enhancement_Date__c = System.today(), Enhancement_Status__c = 'Current', Enhancement_Amount__c = 50)
        };

        Test.startTest();
        insert accts;
        Test.stopTest();

        List<Opportunity> results = [SELECT Id FROM Opportunity];
        System.assertEquals(0, results.size(), 'No Opportunities should be created for accounts that do not meet criteria');
    }

    @isTest
    static void shouldHandleAccountInsertMeetingCriteria() {
        Account acc = new Account(
            Name = 'Test Acc', Type = 'Client - Direct',
            Enhancement_Date__c = System.today(),
            Enhancement_Status__c = 'Current',
            Enhancement_Amount__c = 50);

        Test.startTest();
        insert acc;
        Test.stopTest();

        // After-trigger fires but no existing Renewal Opps exist to update or close
        List<Opportunity> results = [SELECT Id FROM Opportunity WHERE AccountId = :acc.Id];
        System.assertEquals(0, results.size(), 'No Opps should be created since opp creation logic is not active');
    }

    @isTest
    static void shouldUpdateRenewalOppWithinSixtyDays() {
        // Create account without enhancement fields so after-trigger skips on insert
        Account acc = new Account(Name = 'Test Acc', Type = 'Client - Direct');
        insert acc;

        // Manually create a Renewal Opportunity with a close date near our target enhancement date
        Date enhancementDate = System.today() + 30;
        Opportunity renewalOpp = new Opportunity(
            AccountId = acc.Id,
            Name = 'Test Renewal',
            StageName = 'Qualified',
            CloseDate = enhancementDate + 10,
            Amount = 100,
            Type = 'Renewal',
            Subtype__c = 'Renewal');
        insert renewalOpp;

        Test.startTest();
        update new Account(
            Id = acc.Id,
            Enhancement_Date__c = enhancementDate,
            Enhancement_Status__c = 'Current',
            Enhancement_Amount__c = 200);
        Test.stopTest();

        Opportunity result = [SELECT CloseDate, Amount, StageName FROM Opportunity WHERE Id = :renewalOpp.Id];
        System.assertEquals(enhancementDate, result.CloseDate, 'Close date should be updated to the enhancement date');
        System.assertEquals(200, result.Amount, 'Amount should be updated to the enhancement amount');
        System.assertEquals('Qualified', result.StageName, 'Stage should remain unchanged');
    }

    @isTest
    static void shouldHandleAccountUpdateWithNoExistingRenewalOpps() {
        Account acc = new Account(Name = 'Test Acc', Type = 'Client - Direct');
        insert acc;

        Test.startTest();
        update new Account(
            Id = acc.Id,
            Enhancement_Date__c = System.today(),
            Enhancement_Status__c = 'Current',
            Enhancement_Amount__c = 100);
        Test.stopTest();

        List<Opportunity> results = [SELECT Id FROM Opportunity WHERE AccountId = :acc.Id];
        System.assertEquals(0, results.size(), 'No Opps should be created when none exist and creation logic is inactive');
    }
}
