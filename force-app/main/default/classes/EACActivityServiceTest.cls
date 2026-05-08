@IsTest
private class EACActivityServiceTest {

    @TestSetup
    static void setupTestData() {
        Account testAccount = new Account(Name = 'EAC Test Account');
        insert testAccount;
    }

    @IsTest
    static void testTrackedUserTaskUpdatesAccount() {
        Account acct = [SELECT Id FROM Account WHERE Name = 'EAC Test Account' LIMIT 1];
        Id currentUserId = UserInfo.getUserId();

        EACActivityService.trackedUserIdsCache = new Set<Id>{ currentUserId };

        Task t = new Task(
            Subject = 'Call with customer',
            OwnerId = currentUserId,
            WhatId = acct.Id,
            Status = 'Completed'
        );

        Test.startTest();
        insert t;
        Test.stopTest();

        Account updated = [SELECT Last_Human_Contact__c, Last_Human_Contact_By__c FROM Account WHERE Id = :acct.Id];
        System.assertNotEquals(null, updated.Last_Human_Contact__c,
            'Last Human Contact should be populated after tracked user activity');
        System.assertEquals(currentUserId, updated.Last_Human_Contact_By__c,
            'Last Human Contact By should be the tracked user');
    }

    @IsTest
    static void testNonTrackedUserTaskDoesNotUpdateAccount() {
        Account acct = [SELECT Id FROM Account WHERE Name = 'EAC Test Account' LIMIT 1];

        EACActivityService.trackedUserIdsCache = new Set<Id>();

        Task t = new Task(
            Subject = 'Call with customer',
            OwnerId = UserInfo.getUserId(),
            WhatId = acct.Id,
            Status = 'Completed'
        );

        Test.startTest();
        insert t;
        Test.stopTest();

        Account updated = [SELECT Last_Human_Contact__c FROM Account WHERE Id = :acct.Id];
        System.assertEquals(null, updated.Last_Human_Contact__c,
            'Last Human Contact should remain null for non-tracked user');
    }

    @IsTest
    static void testInvoiceSubjectTaskIsExcluded() {
        Account acct = [SELECT Id FROM Account WHERE Name = 'EAC Test Account' LIMIT 1];
        Id currentUserId = UserInfo.getUserId();

        EACActivityService.trackedUserIdsCache = new Set<Id>{ currentUserId };

        Task t = new Task(
            Subject = 'Cavallo Invoice 405266 for $161,771.26 due 05/20/2026',
            OwnerId = currentUserId,
            WhatId = acct.Id,
            Status = 'Completed'
        );

        Test.startTest();
        insert t;
        Test.stopTest();

        Account updated = [SELECT Last_Human_Contact__c FROM Account WHERE Id = :acct.Id];
        System.assertEquals(null, updated.Last_Human_Contact__c,
            'Last Human Contact should remain null for invoice activity');
    }

    @IsTest
    static void testEventUpdatesAccount() {
        Account acct = [SELECT Id FROM Account WHERE Name = 'EAC Test Account' LIMIT 1];
        Id currentUserId = UserInfo.getUserId();

        EACActivityService.trackedUserIdsCache = new Set<Id>{ currentUserId };

        Event e = new Event(
            Subject = 'Meeting with customer',
            OwnerId = currentUserId,
            WhatId = acct.Id,
            DurationInMinutes = 60,
            ActivityDateTime = DateTime.now()
        );

        Test.startTest();
        insert e;
        Test.stopTest();

        Account updated = [SELECT Last_Human_Contact__c, Last_Human_Contact_By__c FROM Account WHERE Id = :acct.Id];
        System.assertNotEquals(null, updated.Last_Human_Contact__c,
            'Last Human Contact should be populated after tracked user event');
        System.assertEquals(currentUserId, updated.Last_Human_Contact_By__c,
            'Last Human Contact By should be the tracked user');
    }

    @IsTest
    static void testTaskWithoutAccountIsIgnored() {
        Id currentUserId = UserInfo.getUserId();

        EACActivityService.trackedUserIdsCache = new Set<Id>{ currentUserId };

        Task t = new Task(
            Subject = 'Standalone task',
            OwnerId = currentUserId,
            Status = 'Completed'
        );

        Test.startTest();
        insert t;
        Test.stopTest();

        Account acct = [SELECT Last_Human_Contact__c FROM Account WHERE Name = 'EAC Test Account' LIMIT 1];
        System.assertEquals(null, acct.Last_Human_Contact__c,
            'Account should not be updated when task has no WhatId');
    }

    @IsTest
    static void testNewerActivityOverwritesOlder() {
        Account acct = [SELECT Id FROM Account WHERE Name = 'EAC Test Account' LIMIT 1];
        Id currentUserId = UserInfo.getUserId();

        acct.Last_Human_Contact__c = DateTime.now().addDays(-10);
        acct.Last_Human_Contact_By__c = currentUserId;
        update acct;

        EACActivityService.trackedUserIdsCache = new Set<Id>{ currentUserId };

        Task t = new Task(
            Subject = 'Follow-up call',
            OwnerId = currentUserId,
            WhatId = acct.Id,
            Status = 'Completed'
        );

        Test.startTest();
        insert t;
        Test.stopTest();

        Account updated = [SELECT Last_Human_Contact__c FROM Account WHERE Id = :acct.Id];
        System.assert(updated.Last_Human_Contact__c > DateTime.now().addDays(-1),
            'Last Human Contact should be updated to the newer activity date');
    }

    @IsTest
    static void testGetTrackedUserIdsReturnsCache() {
        Set<Id> testSet = new Set<Id>{ UserInfo.getUserId() };
        EACActivityService.trackedUserIdsCache = testSet;

        Test.startTest();
        Set<Id> result = EACActivityService.getTrackedUserIds();
        Test.stopTest();

        System.assertEquals(testSet, result, 'Should return cached user Ids');
    }

    @IsTest
    static void testGetTrackedUserIdsFromMetadata() {
        EACActivityService.trackedUserIdsCache = null;

        Test.startTest();
        Set<Id> result = EACActivityService.getTrackedUserIds();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return a set even if empty');
    }
}
