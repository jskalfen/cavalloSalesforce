global class AccountEnhancementFixScheduledJob implements Database.Batchable<sObject>, Schedulable{
    String query = 'SELECT Id, Enhancement_Status__c, Enhancement_Date__c ' +
                   'FROM Account '+
                   'WHERE Enhancement_Date__c != NULL AND Enhancement_Status__c IN (\'Expired\',\'Grace\',\'Current\') ' +
                   'AND ( '+
                   '     ( Enhancement_Date__c < LAST_N_DAYS:31 AND Enhancement_Status__c != \'Expired\' ) '+
                   '  OR ( Enhancement_Date__c >= LAST_N_DAYS:31 AND Enhancement_Date__c < TODAY AND Enhancement_Status__c != \'Grace\' ) '+
                   '  OR ( Enhancement_Date__c >= TODAY AND Enhancement_Status__c != \'Current\' ) '+
                   ')';
    Date graceThreshold = System.today() - 31;

    //Runs once a day when Triggered by when the Admin has specified this job to be scheduled
    global void execute(SchedulableContext sc) {
        System.debug('Executing Scheduled job: AccountEnhancementFixScheduledJob');
        Database.executeBatch(new AccountEnhancementFixScheduledJob());
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('Starting batch job: AccountEnhancementFixScheduledJob');
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<Account> accounts) {
        System.debug('Executing batch job: AccountEnhancementFixScheduledJob, processing ' + accounts.size() + ' records');
        List<Account> accountsNeedingUpdate = new List<Account>();

        for(Account acct : accounts) {
            //check to see if the Account SHOULD be set to Expired
            System.debug('Evaluating Account ' + acct.Id + ' with Enhancement_Date__c: ' + acct.Enhancement_Date__c + ' and current Enhancement_Status__c: ' + acct.Enhancement_Status__c);
            if(acct.Enhancement_Date__c < graceThreshold 
                    && acct.Enhancement_Status__c != 'Expired') {
                //We think the Account should be set to Expired
                System.debug('Detected Account ' + acct.Id + ' should be set to Expired as the Enhancement_Date__c is: ' 
                    + acct.Enhancement_Date__c + ' and current Enhancement_Status__c is: ' + acct.Enhancement_Status__c);
                accountsNeedingUpdate.add(new Account(Id = acct.Id, Enhancement_Status__c = 'Expired'));
            }
            else if(acct.Enhancement_Date__c >= graceThreshold 
                    && acct.Enhancement_Date__c < System.today() 
                    && acct.Enhancement_Status__c != 'Grace') {
                //We think the Account should be set to Grace
                System.debug('Detected Account ' + acct.Id + ' should be set to Grace as the Enhancement_Date__c is: ' + acct.Enhancement_Date__c + ' and current Enhancement_Status__c is: ' + acct.Enhancement_Status__c);
                accountsNeedingUpdate.add(new Account(Id = acct.Id, Enhancement_Status__c = 'Grace'));
            }
            else if(acct.Enhancement_Date__c >= System.today() 
                    && acct.Enhancement_Status__c != 'Current') {
                        //We think the Account should be set to Current
                System.debug('Detected Account ' + acct.Id + ' should be set to Current as the Enhancement_Date__c is: ' + acct.Enhancement_Date__c + ' and current Enhancement_Status__c is: ' + acct.Enhancement_Status__c);
                accountsNeedingUpdate.add(new Account(Id = acct.Id, Enhancement_Status__c = 'Current'));
            }
        }
        if(!accountsNeedingUpdate.isEmpty()) {
            System.debug('Correcting ' + accountsNeedingUpdate.size() + ' Accounts');
            update accountsNeedingUpdate;
        }
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('Finished batch job: AccountEnhancementFixScheduledJob');
    }

    global static AccountEnhancementFixScheduledJob scheduleDailyAtHour(Integer hour){
        AccountEnhancementFixScheduledJob job = new AccountEnhancementFixScheduledJob();
        if (hour == null) 
            Database.executebatch(job);
        else {
            String jobName = 'DailyAccountEnhancementFixScheduledJob - ' + Datetime.now().format();
            String cron = '0 0 ' + String.valueof(hour) + ' * * ?';
            System.schedule(jobName, cron, job);
        }
        return job;
    }
}