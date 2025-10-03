@isTest
public class AccountTriggerHandler2Tests {

    @TestSetup
    static void setupTestData() {
        // Create test accounts for various test scenarios
        List<Account> testAccounts = new List<Account>();
        
        // Account with all fields populated
        testAccounts.add(new Account(
            Name = 'Test Account 1',
            ERP__c = 'Acumatica',
            ERP_Future__c = 'Microsoft Dynamics 365 Business Central',
            Evaluation_Migration_Date__c = Date.today().addDays(30)
        ));
        
        // Account with only ERP Current
        testAccounts.add(new Account(
            Name = 'Test Account 2',
            ERP__c = 'Oracle - Fusion'
        ));
        
        // Account with no ERP fields
        testAccounts.add(new Account(
            Name = 'Test Account 3'
        ));
        
        insert testAccounts;
    }

    @isTest
    static void testBeforeInsert_AllFieldsPopulated() {
        // Test that timestamps are set when creating records with all fields
        Account testAcc = new Account(
            Name = 'Test Insert Account',
            ERP__c = 'Epicor',
            ERP_Future__c = 'Netsuite',
            Evaluation_Migration_Date__c = Date.today().addDays(60)
        );
        
        Test.startTest();
        insert testAcc;
        Test.stopTest();
        
        // Query the inserted account
        Account insertedAcc = [SELECT ERP_Time_Stamp__c, ERP_Future_Time_Stamp__c, 
                              Evaluation_Migration_Date_Time_Stamp__c 
                              FROM Account WHERE Id = :testAcc.Id];
        
        // Verify timestamps are set
        System.assertNotEquals(null, insertedAcc.ERP_Time_Stamp__c, 'ERP timestamp should be set');
        System.assertNotEquals(null, insertedAcc.ERP_Future_Time_Stamp__c, 'ERP Future timestamp should be set');
        System.assertNotEquals(null, insertedAcc.Evaluation_Migration_Date_Time_Stamp__c, 'Evaluation/Migration Date timestamp should be set');
        
        // Verify timestamps are recent (within last minute)
        DateTime now = DateTime.now();
        System.assert(insertedAcc.ERP_Time_Stamp__c >= now.addMinutes(-1), 'ERP timestamp should be recent');
        System.assert(insertedAcc.ERP_Future_Time_Stamp__c >= now.addMinutes(-1), 'ERP Future timestamp should be recent');
        System.assert(insertedAcc.Evaluation_Migration_Date_Time_Stamp__c >= now.addMinutes(-1), 'Evaluation/Migration Date timestamp should be recent');
    }

    @isTest
    static void testBeforeInsert_PartialFieldsPopulated() {
        // Test that only timestamps for populated fields are set
        Account testAcc = new Account(
            Name = 'Test Partial Account',
            ERP__c = 'Sage Intacct'
            // ERP_Future__c and Evaluation_Migration_Date__c are null
        );
        
        Test.startTest();
        insert testAcc;
        Test.stopTest();
        
        // Query the inserted account
        Account insertedAcc = [SELECT ERP_Time_Stamp__c, ERP_Future_Time_Stamp__c, 
                              Evaluation_Migration_Date_Time_Stamp__c 
                              FROM Account WHERE Id = :testAcc.Id];
        
        // Verify only ERP timestamp is set
        System.assertNotEquals(null, insertedAcc.ERP_Time_Stamp__c, 'ERP timestamp should be set');
        System.assertEquals(null, insertedAcc.ERP_Future_Time_Stamp__c, 'ERP Future timestamp should not be set');
        System.assertEquals(null, insertedAcc.Evaluation_Migration_Date_Time_Stamp__c, 'Evaluation/Migration Date timestamp should not be set');
    }

    @isTest
    static void testBeforeInsert_NoFieldsPopulated() {
        // Test that no timestamps are set when no ERP fields are populated
        Account testAcc = new Account(
            Name = 'Test Empty Account'
        );
        
        Test.startTest();
        insert testAcc;
        Test.stopTest();
        
        // Query the inserted account
        Account insertedAcc = [SELECT ERP_Time_Stamp__c, ERP_Future_Time_Stamp__c, 
                              Evaluation_Migration_Date_Time_Stamp__c 
                              FROM Account WHERE Id = :testAcc.Id];
        
        // Verify no timestamps are set
        System.assertEquals(null, insertedAcc.ERP_Time_Stamp__c, 'ERP timestamp should not be set');
        System.assertEquals(null, insertedAcc.ERP_Future_Time_Stamp__c, 'ERP Future timestamp should not be set');
        System.assertEquals(null, insertedAcc.Evaluation_Migration_Date_Time_Stamp__c, 'Evaluation/Migration Date timestamp should not be set');
    }

    @isTest
    static void testBeforeUpdate_ERPFieldChanged() {
        // Get test account from setup
        Account testAcc = [SELECT Id, ERP__c FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        
        // Store original timestamp
        DateTime originalTimestamp = [SELECT ERP_Time_Stamp__c FROM Account WHERE Id = :testAcc.Id].ERP_Time_Stamp__c;
        
        // Update ERP field
        testAcc.ERP__c = 'Microsoft Dynamics GP';
        
        Test.startTest();
        update testAcc;
        Test.stopTest();
        
        // Query updated account
        Account updatedAcc = [SELECT ERP_Time_Stamp__c FROM Account WHERE Id = :testAcc.Id];
        
        // Verify timestamp was updated
        System.assertNotEquals(originalTimestamp, updatedAcc.ERP_Time_Stamp__c, 'ERP timestamp should be updated');
        System.assert(updatedAcc.ERP_Time_Stamp__c >= DateTime.now().addMinutes(-1), 'ERP timestamp should be recent');
    }

    @isTest
    static void testBeforeUpdate_ERPFutureFieldChanged() {
        // Get test account from setup
        Account testAcc = [SELECT Id, ERP_Future__c FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        
        // Store original timestamp
        DateTime originalTimestamp = [SELECT ERP_Future_Time_Stamp__c FROM Account WHERE Id = :testAcc.Id].ERP_Future_Time_Stamp__c;
        
        // Update ERP Future field
        testAcc.ERP_Future__c = 'Oracle - E-Business Suite (EBS)';
        
        Test.startTest();
        update testAcc;
        Test.stopTest();
        
        // Query updated account
        Account updatedAcc = [SELECT ERP_Future_Time_Stamp__c FROM Account WHERE Id = :testAcc.Id];
        
        // Verify timestamp was updated
        System.assertNotEquals(originalTimestamp, updatedAcc.ERP_Future_Time_Stamp__c, 'ERP Future timestamp should be updated');
        System.assert(updatedAcc.ERP_Future_Time_Stamp__c >= DateTime.now().addMinutes(-1), 'ERP Future timestamp should be recent');
    }

    @isTest
    static void testBeforeUpdate_EvaluationMigrationDateChanged() {
        // Get test account from setup
        Account testAcc = [SELECT Id, Evaluation_Migration_Date__c FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        
        // Store original timestamp
        DateTime originalTimestamp = [SELECT Evaluation_Migration_Date_Time_Stamp__c FROM Account WHERE Id = :testAcc.Id].Evaluation_Migration_Date_Time_Stamp__c;
        
        // Update Evaluation/Migration Date field
        testAcc.Evaluation_Migration_Date__c = Date.today().addDays(90);
        
        Test.startTest();
        update testAcc;
        Test.stopTest();
        
        // Query updated account
        Account updatedAcc = [SELECT Evaluation_Migration_Date_Time_Stamp__c FROM Account WHERE Id = :testAcc.Id];
        
        // Verify timestamp was updated
        System.assertNotEquals(originalTimestamp, updatedAcc.Evaluation_Migration_Date_Time_Stamp__c, 'Evaluation/Migration Date timestamp should be updated');
        System.assert(updatedAcc.Evaluation_Migration_Date_Time_Stamp__c >= DateTime.now().addMinutes(-1), 'Evaluation/Migration Date timestamp should be recent');
    }

    @isTest
    static void testBeforeUpdate_MultipleFieldsChanged() {
        // Get test account from setup
        Account testAcc = [SELECT Id, ERP__c, ERP_Future__c, Evaluation_Migration_Date__c FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        
        // Store original timestamps
        Account originalAcc = [SELECT ERP_Time_Stamp__c, ERP_Future_Time_Stamp__c, 
                              Evaluation_Migration_Date_Time_Stamp__c FROM Account WHERE Id = :testAcc.Id];
        
        // Update multiple fields
        testAcc.ERP__c = 'Quickbooks';
        testAcc.ERP_Future__c = 'Sage 100';
        testAcc.Evaluation_Migration_Date__c = Date.today().addDays(120);
        
        Test.startTest();
        update testAcc;
        Test.stopTest();
        
        // Query updated account
        Account updatedAcc = [SELECT ERP_Time_Stamp__c, ERP_Future_Time_Stamp__c, 
                             Evaluation_Migration_Date_Time_Stamp__c FROM Account WHERE Id = :testAcc.Id];
        
        // Verify all timestamps were updated
        System.assertNotEquals(originalAcc.ERP_Time_Stamp__c, updatedAcc.ERP_Time_Stamp__c, 'ERP timestamp should be updated');
        System.assertNotEquals(originalAcc.ERP_Future_Time_Stamp__c, updatedAcc.ERP_Future_Time_Stamp__c, 'ERP Future timestamp should be updated');
        System.assertNotEquals(originalAcc.Evaluation_Migration_Date_Time_Stamp__c, updatedAcc.Evaluation_Migration_Date_Time_Stamp__c, 'Evaluation/Migration Date timestamp should be updated');
    }

    @isTest
    static void testBeforeUpdate_NoFieldsChanged() {
        // Get test account from setup
        Account testAcc = [SELECT Id, Name FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        
        // Store original timestamps
        Account originalAcc = [SELECT ERP_Time_Stamp__c, ERP_Future_Time_Stamp__c, 
                              Evaluation_Migration_Date_Time_Stamp__c FROM Account WHERE Id = :testAcc.Id];
        
        // Update a non-ERP field
        testAcc.Name = 'Updated Test Account 1';
        
        Test.startTest();
        update testAcc;
        Test.stopTest();
        
        // Query updated account
        Account updatedAcc = [SELECT ERP_Time_Stamp__c, ERP_Future_Time_Stamp__c, 
                             Evaluation_Migration_Date_Time_Stamp__c FROM Account WHERE Id = :testAcc.Id];
        
        // Verify timestamps were NOT updated
        System.assertEquals(originalAcc.ERP_Time_Stamp__c, updatedAcc.ERP_Time_Stamp__c, 'ERP timestamp should not be updated');
        System.assertEquals(originalAcc.ERP_Future_Time_Stamp__c, updatedAcc.ERP_Future_Time_Stamp__c, 'ERP Future timestamp should not be updated');
        System.assertEquals(originalAcc.Evaluation_Migration_Date_Time_Stamp__c, updatedAcc.Evaluation_Migration_Date_Time_Stamp__c, 'Evaluation/Migration Date timestamp should not be updated');
    }

    @isTest
    static void testBeforeUpdate_FieldChangedToNull() {
        // Get test account from setup
        Account testAcc = [SELECT Id, ERP__c FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        
        // Store original timestamp
        DateTime originalTimestamp = [SELECT ERP_Time_Stamp__c FROM Account WHERE Id = :testAcc.Id].ERP_Time_Stamp__c;
        
        // Update ERP field to null
        testAcc.ERP__c = null;
        
        Test.startTest();
        update testAcc;
        Test.stopTest();
        
        // Query updated account
        Account updatedAcc = [SELECT ERP_Time_Stamp__c FROM Account WHERE Id = :testAcc.Id];
        
        // Verify timestamp was updated (field changed from value to null)
        System.assertNotEquals(originalTimestamp, updatedAcc.ERP_Time_Stamp__c, 'ERP timestamp should be updated when field changes to null');
        System.assert(updatedAcc.ERP_Time_Stamp__c >= DateTime.now().addMinutes(-1), 'ERP timestamp should be recent');
    }

    @isTest
    static void testBeforeUpdate_BulkUpdate() {
        // Test bulk update scenario
        List<Account> accountsToUpdate = [SELECT Id, ERP__c FROM Account WHERE Name LIKE 'Test Account%' LIMIT 3];
        
        // Store original timestamps
        Map<Id, DateTime> originalTimestamps = new Map<Id, DateTime>();
        for (Account acc : [SELECT Id, ERP_Time_Stamp__c FROM Account WHERE Id IN :accountsToUpdate]) {
            originalTimestamps.put(acc.Id, acc.ERP_Time_Stamp__c);
        }
        
        // Update ERP field for all accounts
        for (Account acc : accountsToUpdate) {
            acc.ERP__c = 'Infor';
        }
        
        Test.startTest();
        update accountsToUpdate;
        Test.stopTest();
        
        // Query updated accounts
        List<Account> updatedAccounts = [SELECT Id, ERP_Time_Stamp__c FROM Account WHERE Id IN :accountsToUpdate];
        
        // Verify all timestamps were updated
        for (Account updatedAcc : updatedAccounts) {
            System.assertNotEquals(originalTimestamps.get(updatedAcc.Id), updatedAcc.ERP_Time_Stamp__c, 
                                  'ERP timestamp should be updated for account ' + updatedAcc.Id);
            System.assert(updatedAcc.ERP_Time_Stamp__c >= DateTime.now().addMinutes(-1), 
                         'ERP timestamp should be recent for account ' + updatedAcc.Id);
        }
    }
}