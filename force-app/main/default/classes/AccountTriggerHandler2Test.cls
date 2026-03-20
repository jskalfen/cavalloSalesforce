@isTest
private class AccountTriggerHandler2Test {

    private static final String PRODUCT_A = 'SalesPad';
    private static final String PRODUCT_B = 'Inventory Manager';

    @isTest
    static void beforeInsert_blankWhitespace_leavesDateStampNull() {
        Account acc = new Account(Name = 'WS Test Blank');

        Test.startTest();
        insert acc;
        Test.stopTest();

        acc = [SELECT Whitespace_Products_Date_Stamp__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(null, acc.Whitespace_Products_Date_Stamp__c);
    }

    @isTest
    static void beforeInsert_withWhitespace_setsDateStamp() {
        Account acc = new Account(Name = 'WS Test Insert', Whitespace_Products__c = PRODUCT_A);

        Test.startTest();
        insert acc;
        Test.stopTest();

        acc = [SELECT Whitespace_Products_Date_Stamp__c FROM Account WHERE Id = :acc.Id];
        System.assertNotEquals(null, acc.Whitespace_Products_Date_Stamp__c);
    }

    @isTest
    static void beforeUpdate_addingProduct_refreshesDateStamp() {
        Account acc = new Account(Name = 'WS Test Add', Whitespace_Products__c = PRODUCT_A);
        insert acc;
        acc = [SELECT Whitespace_Products_Date_Stamp__c FROM Account WHERE Id = :acc.Id];
        Datetime firstStamp = acc.Whitespace_Products_Date_Stamp__c;

        acc.Whitespace_Products__c = PRODUCT_A + ';' + PRODUCT_B;

        Test.startTest();
        update acc;
        Test.stopTest();

        acc = [SELECT Whitespace_Products_Date_Stamp__c FROM Account WHERE Id = :acc.Id];
        System.assertNotEquals(firstStamp, acc.Whitespace_Products_Date_Stamp__c);
    }

    @isTest
    static void beforeUpdate_removingOnly_doesNotChangeDateStamp() {
        Account acc = new Account(
            Name = 'WS Test Remove',
            Whitespace_Products__c = PRODUCT_A + ';' + PRODUCT_B
        );
        insert acc;
        acc = [SELECT Whitespace_Products_Date_Stamp__c FROM Account WHERE Id = :acc.Id];
        Datetime stampAfterInsert = acc.Whitespace_Products_Date_Stamp__c;

        acc.Whitespace_Products__c = PRODUCT_A;

        Test.startTest();
        update acc;
        Test.stopTest();

        acc = [SELECT Whitespace_Products_Date_Stamp__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(stampAfterInsert, acc.Whitespace_Products_Date_Stamp__c);
    }

    @isTest
    static void beforeUpdate_noWhitespaceChange_doesNotRefreshWhitespaceStamp() {
        Account acc = new Account(Name = 'WS Test Same', Whitespace_Products__c = PRODUCT_A);
        insert acc;
        acc = [SELECT Whitespace_Products_Date_Stamp__c FROM Account WHERE Id = :acc.Id];
        Datetime stampAfterInsert = acc.Whitespace_Products_Date_Stamp__c;

        acc.Description = 'Touch unrelated field';

        Test.startTest();
        update acc;
        Test.stopTest();

        acc = [SELECT Whitespace_Products_Date_Stamp__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(stampAfterInsert, acc.Whitespace_Products_Date_Stamp__c);
    }

    @isTest
    static void payFabricMids_insertWithValue_setsStampOnly() {
        Account acc = new Account(Name = 'PF MID Insert', PayFabric_MIDs__c = '3');

        Test.startTest();
        insert acc;
        Test.stopTest();

        acc = [
            SELECT PayFabric_MIDs_Previous__c, PayFabric_MIDs_Date_Stamp__c
            FROM Account
            WHERE Id = :acc.Id
        ];
        System.assertEquals(null, acc.PayFabric_MIDs_Previous__c);
        System.assertNotEquals(null, acc.PayFabric_MIDs_Date_Stamp__c);
    }

    @isTest
    static void payFabricMids_update_setsPreviousAndRefreshesStamp() {
        Account acc = new Account(Name = 'PF MID Update', PayFabric_MIDs__c = '3');
        insert acc;
        acc = [SELECT PayFabric_MIDs_Date_Stamp__c FROM Account WHERE Id = :acc.Id];
        Datetime stampAfterInsert = acc.PayFabric_MIDs_Date_Stamp__c;

        acc.PayFabric_MIDs__c = '7';

        Test.startTest();
        update acc;
        Test.stopTest();

        acc = [
            SELECT PayFabric_MIDs_Previous__c, PayFabric_MIDs_Date_Stamp__c
            FROM Account
            WHERE Id = :acc.Id
        ];
        System.assertEquals('3', acc.PayFabric_MIDs_Previous__c);
        System.assertNotEquals(stampAfterInsert, acc.PayFabric_MIDs_Date_Stamp__c);
    }

    @isTest
    static void payFabricMids_clear_setsPreviousToLastValue() {
        Account acc = new Account(Name = 'PF MID Clear', PayFabric_MIDs__c = '5');
        insert acc;

        acc.PayFabric_MIDs__c = null;

        Test.startTest();
        update acc;
        Test.stopTest();

        acc = [
            SELECT PayFabric_MIDs_Previous__c, PayFabric_MIDs_Date_Stamp__c
            FROM Account
            WHERE Id = :acc.Id
        ];
        System.assertEquals('5', acc.PayFabric_MIDs_Previous__c);
        System.assertNotEquals(null, acc.PayFabric_MIDs_Date_Stamp__c);
    }

    @isTest
    static void squareMids_update_setsPreviousAndRefreshesStamp() {
        Account acc = new Account(Name = 'SQ MID Update', Square_MIDs__c = '1');
        insert acc;
        acc = [SELECT Square_MIDs_Date_Stamp__c FROM Account WHERE Id = :acc.Id];
        Datetime stampAfterInsert = acc.Square_MIDs_Date_Stamp__c;

        acc.Square_MIDs__c = '10';

        Test.startTest();
        update acc;
        Test.stopTest();

        acc = [
            SELECT Square_MIDs_Previous__c, Square_MIDs_Date_Stamp__c
            FROM Account
            WHERE Id = :acc.Id
        ];
        System.assertEquals('1', acc.Square_MIDs_Previous__c);
        System.assertNotEquals(stampAfterInsert, acc.Square_MIDs_Date_Stamp__c);
    }
}
