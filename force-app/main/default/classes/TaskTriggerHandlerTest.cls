@IsTest
private class TaskTriggerHandlerTest {

    @TestSetup
    static void setupTestData() {
        Account testAccount = new Account(Name = 'Task Trigger Test Account');
        insert testAccount;
    }

    @IsTest
    static void testTaskInsertFiresTriggerAndUpdatesAccount() {
        Account acct = [SELECT Id FROM Account WHERE Name = 'Task Trigger Test Account' LIMIT 1];
        Id currentUserId = UserInfo.getUserId();

        EACActivityService.trackedUserIdsCache = new Set<Id>{ currentUserId };

        Task t = new Task(
            Subject = 'Email to customer',
            OwnerId = currentUserId,
            WhatId = acct.Id,
            Status = 'Completed'
        );

        Test.startTest();
        insert t;
        Test.stopTest();

        Account updated = [SELECT Last_Human_Contact__c, Last_Human_Contact_By__c FROM Account WHERE Id = :acct.Id];
        System.assertNotEquals(null, updated.Last_Human_Contact__c,
            'Task trigger should update Last Human Contact on Account');
        System.assertEquals(currentUserId, updated.Last_Human_Contact_By__c,
            'Task trigger should set Last Human Contact By to the task owner');
    }

    @IsTest
    static void testInvoiceTaskDoesNotUpdateAccount() {
        Account acct = [SELECT Id FROM Account WHERE Name = 'Task Trigger Test Account' LIMIT 1];
        Id currentUserId = UserInfo.getUserId();

        EACActivityService.trackedUserIdsCache = new Set<Id>{ currentUserId };

        Task t = new Task(
            Subject = 'Cavallo Invoice 999999 for $5,000.00 due 01/01/2027',
            OwnerId = currentUserId,
            WhatId = acct.Id,
            Status = 'Completed'
        );

        Test.startTest();
        insert t;
        Test.stopTest();

        Account updated = [SELECT Last_Human_Contact__c FROM Account WHERE Id = :acct.Id];
        System.assertEquals(null, updated.Last_Human_Contact__c,
            'Invoice task should not update Last Human Contact');
    }

    @IsTest
    static void testBulkTaskInsert() {
        Account acct = [SELECT Id FROM Account WHERE Name = 'Task Trigger Test Account' LIMIT 1];
        Id currentUserId = UserInfo.getUserId();

        EACActivityService.trackedUserIdsCache = new Set<Id>{ currentUserId };

        List<Task> tasks = new List<Task>();
        for (Integer i = 0; i < 50; i++) {
            tasks.add(new Task(
                Subject = 'Bulk call ' + i,
                OwnerId = currentUserId,
                WhatId = acct.Id,
                Status = 'Completed'
            ));
        }

        Test.startTest();
        insert tasks;
        Test.stopTest();

        Account updated = [SELECT Last_Human_Contact__c FROM Account WHERE Id = :acct.Id];
        System.assertNotEquals(null, updated.Last_Human_Contact__c,
            'Bulk task insert should update Last Human Contact');
    }
}
