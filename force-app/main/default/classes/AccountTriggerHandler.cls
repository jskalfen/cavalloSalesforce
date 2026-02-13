public with sharing class AccountTriggerHandler {

    public static void handleBeforeInsertAndUpdate(List<Account> accounts, Map<Id, Account> oldMap) {
        for(Account acc : accounts) {
            Account oldAcc = oldMap?.get(acc.Id);

            // If ABR Scheduled Date is being populated for the first time, stamp the datetime
            if(acc.ABR_Scheduled_Date__c != null && oldAcc?.ABR_Scheduled_Date__c == null && acc.ABR_Scheduled_Date_Set__c == null) {
                acc.ABR_Scheduled_Date_Set__c = DateTime.now();
            }

            // If ABR Happened is being set to true for the first time, stamp the datetime
            if(acc.ABR_Happened__c == true && oldAcc?.ABR_Happened__c != true && acc.ABR_Happened_Set__c == null) {
                acc.ABR_Happened_Set__c = DateTime.now();
            }
        }
    }

    public static void handleAfterInsertAndUpdate(Map<Id, Account> accounts, Map<Id,Account> oldMap) {
        //first collect the Accounts we should work with
        Map<Id, Account> accountsNeedingWork = new Map<Id, Account>();
        for(Account acc : accounts.values()) {
            if(shouldAccountBeProcessed(acc, oldMap?.get(acc.Id)))
                accountsNeedingWork.put(acc.Id, acc);
        }
        if(accountsNeedingWork.isEmpty()) return;

        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        //Now lets get a list of Open Renewal Opportunities for these Accounts
        List<Opportunity> openRenewalOpps = [   SELECT Id, AccountId, StageName, CloseDate, Amount
                                                FROM Opportunity 
                                                WHERE AccountId IN :accountsNeedingWork.keySet()
                                                AND IsClosed = False
                                                AND Subtype__c = 'Renewal'];

        //if there are existing Renewals, we will need to either Update the Opportunity to match new info if the Opportunity is still valid OR Close Won the Opportunity
        for(Opportunity opp : openRenewalOpps) {
            Account acc = accounts.get(opp.AccountId); //we are grabbing the account from the accounts map just in case there are duplicate Opportunities for an account
            //now, do we Close Won the Opp, or do we update it and keep it open?  We will determine this by looking at the dates.
            Integer daysDifference = opp.CloseDate.daysBetween(acc.Enhancement_Date__c);
            if(daysDifference > -60 && daysDifference < 60) {
                //the Opportunity is within 60 days of the Account Enhancement Date (which is at least annually), 
                //so let's update the Opportunity to have the right info on the account
                opp.CloseDate = acc.Enhancement_Date__c;
                opp.Amount = acc.Enhancement_Amount__c;
                oppsToUpdate.add(opp);
                if(accountsNeedingWork.containsKey(opp.AccountId))
                    accountsNeedingWork.remove(opp.AccountId); //We've processed this Account
            }
            else {
                opp.StageName = 'Closed Won';
                oppsToUpdate.add(opp);
                //we are NOT removing the Account from AccountsNeedingWork as we still need to create a NEW Opportunity for them
            }
        }
        if(!oppsToUpdate.isEmpty()) {
            update oppsToUpdate;
        }
    }

    public static Boolean shouldAccountBeProcessed(Account acc, Account oldAcc) {
        //make sure we have fields to even process with
        if(acc?.Enhancement_Status__c != 'Current' || acc?.Enhancement_Amount__c == null || acc?.Enhancement_Date__c == null)
            return false;
        
        //make sure the account type is something we want to process
        if(acc.Type == 'Client - Direct' || acc.Type == 'Client - Registered to Partner' || acc.Type == 'End User') {
            //ok these are good types
            if(acc.Type == 'End User' && (acc.Customer_Class__c == 'Ex end user Cloud' || acc.Customer_Class__c == 'Ex end user Desktop'))
                return false; //we don't want End User IF they are Ex end users
        }
        else //the Account is NOT one of the 3 Account Types we care about
            return false;

        //lets see if the values changed
        if(oldAcc != null) {
            if(acc.Enhancement_Amount__c == oldAcc.Enhancement_Amount__c &&
                    acc.Enhancement_Date__c == oldAcc.Enhancement_Date__c &&
                    acc.Enhancement_Status__c == oldAcc.Enhancement_Status__c)
                return false; //None of the Enhancement Fields changed
        }

        //ok, looks like we passed all of our validations to see if this Account should be processed!
        return true;
    }
}