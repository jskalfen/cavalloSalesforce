@IsTest
private class AccountActivityTrackerControllerTest {

    @TestSetup
    static void setupTestData() {
        // ARR__c is a rollup summary formula so it defaults to 0 in tests.
        // These tests verify method execution, query structure, and wrapper population.
        List<Account> accounts = new List<Account>();

        accounts.add(new Account(
            Name = 'Stale Account 90 Days',
            Last_Human_Contact__c = DateTime.now().addDays(-95)
        ));
        accounts.add(new Account(
            Name = 'Stale Account 60 Days',
            Last_Human_Contact__c = DateTime.now().addDays(-65)
        ));
        accounts.add(new Account(
            Name = 'Stale Account 30 Days',
            Last_Human_Contact__c = DateTime.now().addDays(-35)
        ));
        accounts.add(new Account(
            Name = 'Recent Account',
            Last_Human_Contact__c = DateTime.now().addDays(-5)
        ));
        accounts.add(new Account(
            Name = 'Never Contacted Account'
        ));

        insert accounts;
    }

    @IsTest
    static void testGetStaleAccounts30Days() {
        EACActivityService.trackedUserIdsCache = new Set<Id>{ UserInfo.getUserId() };

        Test.startTest();
        AccountActivityTrackerController.ActivityResult result =
            AccountActivityTrackerController.getStaleAccounts('30', 'ALL');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.accounts, 'Accounts list should not be null');
    }

    @IsTest
    static void testGetStaleAccounts60Days() {
        EACActivityService.trackedUserIdsCache = new Set<Id>{ UserInfo.getUserId() };

        Test.startTest();
        AccountActivityTrackerController.ActivityResult result =
            AccountActivityTrackerController.getStaleAccounts('60', 'ALL');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.accounts, 'Accounts list should not be null');
    }

    @IsTest
    static void testGetStaleAccounts90Days() {
        EACActivityService.trackedUserIdsCache = new Set<Id>{ UserInfo.getUserId() };

        Test.startTest();
        AccountActivityTrackerController.ActivityResult result =
            AccountActivityTrackerController.getStaleAccounts('90', 'ALL');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.accounts, 'Accounts list should not be null');
    }

    @IsTest
    static void testGetStaleAccountsNeverTab() {
        EACActivityService.trackedUserIdsCache = new Set<Id>{ UserInfo.getUserId() };

        Test.startTest();
        AccountActivityTrackerController.ActivityResult result =
            AccountActivityTrackerController.getStaleAccounts('NEVER', 'ALL');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.accounts, 'Accounts list should not be null');
    }

    @IsTest
    static void testGetStaleAccountsDefaultFilter() {
        EACActivityService.trackedUserIdsCache = new Set<Id>{ UserInfo.getUserId() };

        Test.startTest();
        AccountActivityTrackerController.ActivityResult result =
            AccountActivityTrackerController.getStaleAccounts('INVALID', null);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @IsTest
    static void testGetStaleAccountsWithUserFilter() {
        Id currentUserId = UserInfo.getUserId();
        EACActivityService.trackedUserIdsCache = new Set<Id>{ currentUserId };

        Test.startTest();
        AccountActivityTrackerController.ActivityResult result =
            AccountActivityTrackerController.getStaleAccounts('30', String.valueOf(currentUserId));
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.accounts, 'Accounts list should not be null');
    }

    @IsTest
    static void testGetStaleAccountsEmptyTrackedUsers() {
        EACActivityService.trackedUserIdsCache = new Set<Id>();

        Test.startTest();
        AccountActivityTrackerController.ActivityResult result =
            AccountActivityTrackerController.getStaleAccounts('30', 'ALL');
        Test.stopTest();

        System.assertEquals(0, result.totalCount,
            'Should return zero accounts when no tracked users configured');
    }

    @IsTest
    static void testActivityResultWrapper() {
        AccountActivityTrackerController.ActivityResult result = new AccountActivityTrackerController.ActivityResult();
        result.accounts = new List<AccountActivityTrackerController.AccountWrapper>();
        result.trackedUsers = new List<AccountActivityTrackerController.TrackedUserOption>();
        result.isAdmin = false;
        result.totalCount = 0;

        System.assertEquals(false, result.isAdmin);
        System.assertEquals(0, result.totalCount);
        System.assertEquals(0, result.trackedUsers.size());
    }

    @IsTest
    static void testAccountWrapper() {
        AccountActivityTrackerController.AccountWrapper w = new AccountActivityTrackerController.AccountWrapper();
        w.accountId = 'test123';
        w.accountName = 'Test Account';
        w.accountOwnerName = 'Test User';
        w.lastHumanContact = DateTime.now();
        w.lastHumanContactByName = 'Contact User';
        w.daysSinceLastContact = 45;

        System.assertEquals('test123', w.accountId);
        System.assertEquals('Test Account', w.accountName);
        System.assertEquals('Test User', w.accountOwnerName);
        System.assertEquals('Contact User', w.lastHumanContactByName);
        System.assertEquals(45, w.daysSinceLastContact);
    }

    @IsTest
    static void testTrackedUserOptionWrapper() {
        AccountActivityTrackerController.TrackedUserOption opt = new AccountActivityTrackerController.TrackedUserOption();
        opt.value = 'someId';
        opt.label = 'Test User';

        System.assertEquals('someId', opt.value);
        System.assertEquals('Test User', opt.label);
    }
}
