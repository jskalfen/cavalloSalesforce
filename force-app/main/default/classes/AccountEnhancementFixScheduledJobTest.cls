@isTest
private class AccountEnhancementFixScheduledJobTest {
    
    @isTest
    static void shouldProcessAccounts() {
        //arrange
        List<Account> testAccounts = new List<Account>();
        testAccounts.add(new Account(Name='Test 1 - Should Be Expired', Enhancement_Date__c = System.today() - 32, Enhancement_Status__c='Current'));
        testAccounts.add(new Account(Name='Test 2 - Should Be Grace',   Enhancement_Date__c = System.today() - 28, Enhancement_Status__c='Current'));
        testAccounts.add(new Account(Name='Test 3 - Should Be Current', Enhancement_Date__c = System.today() +  5, Enhancement_Status__c='Expired'));
        insert testAccounts;

        //act
        Test.startTest();
            AccountEnhancementFixScheduledJob.scheduleDailyAtHour(null);
        Test.stopTest();

        //arrange
        List<Account> results = [SELECT Id, Name, Enhancement_Date__c, Enhancement_Status__c FROM Account];
        System.assertEquals(3, results.size());

        for(Account result : results) {
            if(result.Name == 'Test 1 - Should Be Expired') {
                System.assertEquals('Expired', result.Enhancement_Status__c);
            }
            else if(result.Name == 'Test 2 - Should Be Grace') {
                System.assertEquals('Grace', result.Enhancement_Status__c);
            }
            else if(result.Name == 'Test 3 - Should Be Current') {
                System.assertEquals('Current', result.Enhancement_Status__c);
            }
            else {
                System.assert(false, 'Something changed the name of the account on us, causing this test to break');
            }
        }
    }
    
    @isTest
    static void shouldNotProcessAccounts() {
        //arrange
        List<Account> testAccounts = new List<Account>();
        testAccounts.add(new Account(Name='Test 1 - Should Not Be Expired', Enhancement_Date__c = System.today() - 32, Enhancement_Status__c='Needs Attention'));
        testAccounts.add(new Account(Name='Test 2 - Should Not Be Grace',   Enhancement_Date__c = System.today() - 28, Enhancement_Status__c='Needs Attention'));
        testAccounts.add(new Account(Name='Test 3 - Should Not Be Current', Enhancement_Date__c = System.today() +  5, Enhancement_Status__c='Needs Attention'));
        insert testAccounts;

        //act
        Test.startTest();
            AccountEnhancementFixScheduledJob.scheduleDailyAtHour(null);
        Test.stopTest();

        //arrange
        List<Account> results = [SELECT Id, Name, Enhancement_Date__c, Enhancement_Status__c FROM Account];
        System.assertEquals(3, results.size());

        for(Account result : results) {
            if(result.Name == 'Test 1 - Should Not Be Expired') {
                System.assertEquals('Needs Attention', result.Enhancement_Status__c);
            }
            else if(result.Name == 'Test 2 - Should Not Be Grace') {
                System.assertEquals('Needs Attention', result.Enhancement_Status__c);
            }
            else if(result.Name == 'Test 3 - Should Not Be Current') {
                System.assertEquals('Needs Attention', result.Enhancement_Status__c);
            }
            else {
                System.assert(false, 'Something changed the name of the account on us, causing this test to break');
            }
        }
    }
}