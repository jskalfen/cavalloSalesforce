@IsTest
private class PaidInvoiceModalControllerTest {

    @TestSetup
    static void setupTestData() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        List<chargebeeapps__CB_Invoice__c> invoices = new List<chargebeeapps__CB_Invoice__c>();
        for (Integer i = 0; i < 5; i++) {
            invoices.add(new chargebeeapps__CB_Invoice__c(
                chargebeeapps__InvoiceID__c = 'INV-TEST-' + i,
                chargebeeapps__Account__c   = testAccount.Id,
                chargebeeapps__Status__c    = 'paid',
                Checked_Invoice__c          = false,
                chargebeeapps__Paid_On__c   = DateTime.now()
            ));
        }

        invoices.add(new chargebeeapps__CB_Invoice__c(
            chargebeeapps__InvoiceID__c = 'INV-TEST-CHECKED',
            chargebeeapps__Account__c   = testAccount.Id,
            chargebeeapps__Status__c    = 'paid',
            Checked_Invoice__c          = true,
            chargebeeapps__Paid_On__c   = DateTime.now()
        ));

        insert invoices;
    }

    @IsTest
    static void testGetPaidInvoicesThisMonth() {
        Test.startTest();
        PaidInvoiceModalController.InvoiceResult result =
            PaidInvoiceModalController.getPaidInvoices('THIS_MONTH');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.invoices, 'Invoices list should not be null');
        System.assertNotEquals(null, result.userRoleType, 'User role type should be populated');
    }

    @IsTest
    static void testGetPaidInvoicesLastMonth() {
        Test.startTest();
        PaidInvoiceModalController.InvoiceResult result =
            PaidInvoiceModalController.getPaidInvoices('LAST_MONTH');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.invoices, 'Invoices list should not be null');
    }

    @IsTest
    static void testGetPaidInvoicesThisQuarter() {
        Test.startTest();
        PaidInvoiceModalController.InvoiceResult result =
            PaidInvoiceModalController.getPaidInvoices('THIS_QUARTER');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.invoices, 'Invoices list should not be null');
    }

    @IsTest
    static void testGetPaidInvoicesDefaultFilter() {
        Test.startTest();
        PaidInvoiceModalController.InvoiceResult result =
            PaidInvoiceModalController.getPaidInvoices('INVALID_FILTER');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @IsTest
    static void testMarkInvoiceChecked() {
        chargebeeapps__CB_Invoice__c invoice = [
            SELECT Id, Checked_Invoice__c
            FROM chargebeeapps__CB_Invoice__c
            WHERE Checked_Invoice__c = false
            LIMIT 1
        ];
        System.assertEquals(false, invoice.Checked_Invoice__c, 'Invoice should start unchecked');

        Test.startTest();
        PaidInvoiceModalController.markInvoiceChecked(invoice.Id);
        Test.stopTest();

        invoice = [
            SELECT Checked_Invoice__c
            FROM chargebeeapps__CB_Invoice__c
            WHERE Id = :invoice.Id
        ];
        System.assertEquals(true, invoice.Checked_Invoice__c, 'Invoice should be checked after update');
    }

    @IsTest
    static void testMarkInvoiceCheckedBlankId() {
        Test.startTest();
        Boolean caughtException = false;
        try {
            PaidInvoiceModalController.markInvoiceChecked('');
        } catch (AuraHandledException e) {
            caughtException = true;
        }
        Test.stopTest();
        System.assert(caughtException, 'Expected AuraHandledException for blank Id');
    }

    @IsTest
    static void testMarkInvoiceCheckedNullId() {
        Test.startTest();
        Boolean caughtException = false;
        try {
            PaidInvoiceModalController.markInvoiceChecked(null);
        } catch (AuraHandledException e) {
            caughtException = true;
        }
        Test.stopTest();
        System.assert(caughtException, 'Expected AuraHandledException for null Id');
    }

    @IsTest
    static void testInvoiceResultWrapper() {
        PaidInvoiceModalController.InvoiceResult result = new PaidInvoiceModalController.InvoiceResult();
        result.invoices = new List<PaidInvoiceModalController.InvoiceWrapper>();
        result.isAdmin = false;
        result.userRoleType = 'Account Manager';
        result.totalCount = 0;

        System.assertEquals(false, result.isAdmin);
        System.assertEquals('Account Manager', result.userRoleType);
        System.assertEquals(0, result.totalCount);
    }

    @IsTest
    static void testInvoiceWrapper() {
        PaidInvoiceModalController.InvoiceWrapper w = new PaidInvoiceModalController.InvoiceWrapper();
        w.invoiceId = 'test123';
        w.invoiceName = 'INV-001';
        w.accountName = 'Test Account';
        w.accountOwnerName = 'Test User';
        w.status = 'paid';
        w.checkedInvoice = false;
        w.paidOn = Date.today();

        System.assertEquals('test123', w.invoiceId);
        System.assertEquals('INV-001', w.invoiceName);
        System.assertEquals('Test Account', w.accountName);
        System.assertEquals('Test User', w.accountOwnerName);
        System.assertEquals('paid', w.status);
        System.assertEquals(false, w.checkedInvoice);
        System.assertEquals(Date.today(), w.paidOn);
    }
}
