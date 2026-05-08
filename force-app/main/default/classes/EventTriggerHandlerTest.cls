@IsTest
private class EventTriggerHandlerTest {

    @TestSetup
    static void setupTestData() {
        Account testAccount = new Account(Name = 'Event Trigger Test Account');
        insert testAccount;
    }

    @IsTest
    static void testEventInsertFiresTriggerAndUpdatesAccount() {
        Account acct = [SELECT Id FROM Account WHERE Name = 'Event Trigger Test Account' LIMIT 1];
        Id currentUserId = UserInfo.getUserId();

        EACActivityService.trackedUserIdsCache = new Set<Id>{ currentUserId };

        Event e = new Event(
            Subject = 'Customer meeting',
            OwnerId = currentUserId,
            WhatId = acct.Id,
            DurationInMinutes = 30,
            ActivityDateTime = DateTime.now()
        );

        Test.startTest();
        insert e;
        Test.stopTest();

        Account updated = [SELECT Last_Human_Contact__c, Last_Human_Contact_By__c FROM Account WHERE Id = :acct.Id];
        System.assertNotEquals(null, updated.Last_Human_Contact__c,
            'Event trigger should update Last Human Contact on Account');
        System.assertEquals(currentUserId, updated.Last_Human_Contact_By__c,
            'Event trigger should set Last Human Contact By to the event owner');
    }

    @IsTest
    static void testInvoiceEventDoesNotUpdateAccount() {
        Account acct = [SELECT Id FROM Account WHERE Name = 'Event Trigger Test Account' LIMIT 1];
        Id currentUserId = UserInfo.getUserId();

        EACActivityService.trackedUserIdsCache = new Set<Id>{ currentUserId };

        Event e = new Event(
            Subject = 'Cavallo Invoice 100000 for $10,000.00 due 12/31/2026',
            OwnerId = currentUserId,
            WhatId = acct.Id,
            DurationInMinutes = 30,
            ActivityDateTime = DateTime.now()
        );

        Test.startTest();
        insert e;
        Test.stopTest();

        Account updated = [SELECT Last_Human_Contact__c FROM Account WHERE Id = :acct.Id];
        System.assertEquals(null, updated.Last_Human_Contact__c,
            'Invoice event should not update Last Human Contact');
    }

    @IsTest
    static void testBulkEventInsert() {
        Account acct = [SELECT Id FROM Account WHERE Name = 'Event Trigger Test Account' LIMIT 1];
        Id currentUserId = UserInfo.getUserId();

        EACActivityService.trackedUserIdsCache = new Set<Id>{ currentUserId };

        List<Event> events = new List<Event>();
        for (Integer i = 0; i < 50; i++) {
            events.add(new Event(
                Subject = 'Bulk meeting ' + i,
                OwnerId = currentUserId,
                WhatId = acct.Id,
                DurationInMinutes = 30,
                ActivityDateTime = DateTime.now().addHours(i)
            ));
        }

        Test.startTest();
        insert events;
        Test.stopTest();

        Account updated = [SELECT Last_Human_Contact__c FROM Account WHERE Id = :acct.Id];
        System.assertNotEquals(null, updated.Last_Human_Contact__c,
            'Bulk event insert should update Last Human Contact');
    }
}
