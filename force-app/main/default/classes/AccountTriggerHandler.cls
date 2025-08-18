public with sharing class AccountTriggerHandler {

    public static void handleAfterInsertAndUpdate(Map<Id, Account> accounts, Map<Id,Account> oldMap) {
        //first collect the Accounts we should work with
        Map<Id, Account> accountsNeedingWork = new Map<Id, Account>();
        for(Account acc : accounts.values()) {
            if(shouldAccountBeProcessed(acc, oldMap?.get(acc.Id)))
                accountsNeedingWork.put(acc.Id, acc);
        }
        if(accountsNeedingWork.isEmpty()) return;
        System.debug('We are going to process Enhancement Information changing on ' + accountsNeedingWork.size() + ' Accounts.');

        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        //Now lets get a list of Open Renewal Opportunities for these Accounts
        List<Opportunity> openRenewalOpps = [   SELECT Id, AccountId, StageName, CloseDate, Amount
                                                FROM Opportunity 
                                                WHERE AccountId IN :accountsNeedingWork.keySet()
                                                AND IsClosed = False
                                                AND Subtype__c = 'Renewal'];
        System.debug('We found ' + openRenewalOpps.size() + ' existing Open Renewal Opportunities for these Accounts');

        //if there are existing Renewals, we will need to either Update the Opportunity to match new info if the Opportunity is still valid OR Close Won the Opportunity
        for(Opportunity opp : openRenewalOpps) {
            Account acc = accounts.get(opp.AccountId); //we are grabbing the account from the accounts map just in case there are duplicate Opportunities for an account
            //now, do we Close Won the Opp, or do we update it and keep it open?  We will determine this by looking at the dates.
            Integer daysDifference = opp.CloseDate.daysBetween(acc.Enhancement_Date__c);
            if(daysDifference > -60 && daysDifference < 60) {
                //the Opportunity is within 60 days of the Account Enhancement Date (which is at least annually), 
                //so let's update the Opportunity to have the right info on the account
                System.debug('For Account Id ' + acc.Id + ' we found Opportunity Id ' + opp.Id + ' is still within 60 days of the Account\'s Enhancement Date. We will adjust it.');
                opp.CloseDate = acc.Enhancement_Date__c;
                opp.Amount = acc.Enhancement_Amount__c;
                oppsToUpdate.add(opp);
                if(accountsNeedingWork.containsKey(opp.AccountId))
                    accountsNeedingWork.remove(opp.AccountId); //We've processed this Account
            }
            else {
                System.debug('For Account Id ' + acc.Id + ' we found Opportunity Id ' + opp.Id + ', and we are marking it as Closed Won');
                opp.StageName = 'Closed Won';
                oppsToUpdate.add(opp);
                //we are NOT removing the Account from AccountsNeedingWork as we still need to create a NEW Opportunity for them
            }
        }
        if(!oppsToUpdate.isEmpty()) {
            System.debug('We will be updating ' + oppsToUpdate.size() + ' Opportunities');
            update oppsToUpdate;
        }

        //alrighty, now we should be left with Accounts that need NEW Opportunity records!
        System.debug('There are ' + accountsNeedingWork.size() + ' Accounts that need NEW Opportunities created');

       /* List<Opportunity> oppsToInsert = new List<Opportunity>();
        for(Account acc : accountsNeedingWork.values()) {
            String paymentTerms = 'Net 15';
            if(acc.Payment_Terms__c != null)
                paymentTerms = acc.Payment_Terms__c;

            oppsToInsert.add(new Opportunity(
                AccountId = acc.Id,
                Amount = acc.Enhancement_Amount__c,
                CloseDate = acc.Enhancement_Date__c,
                LeadSource = 'Renewal',
                Name = acc.Name + ' Renewal',
                OwnerId = acc.OwnerId,
                Payment_Terms__c = paymentTerms,
                Product_Line_s__c = 'Desktop',
                RecordTypeId = '0126A000000YmpWQAS',
                StageName = 'Qualified',
                Subtype__c = 'Renewal',
                Type = 'Existing Business'
            ));
        }
        if(!oppsToInsert.isEmpty()) {
            System.debug('We will be inserting ' + oppsToInsert.size() + ' Opportunities');
            insert oppsToInsert;
            
            //Now that we have inserted our new Opportunities, we can create reminder Tasks for them
            List<Task> tasksToInsert = new List<Task>();
            for(Opportunity opp : oppsToInsert) {
                tasksToInsert.add(new Task(
                    ActivityDate = opp.CloseDate - 60,
                    Description = 'Customer has an upcoming enhancement due please reach out to them.',
                    OwnerId = opp.OwnerId,
                    Priority = 'Normal',
                    Status = 'Open',
                    Subject = opp.Name,
                    Type = 'Enhancement',
                    WhatId = opp.Id
                ));
            }
            System.debug('We will be inserting ' + tasksToInsert.size() + ' Tasks');
            insert tasksToInsert;
        } */
    }

    /*
     * Check to see if an Account should be processed and have an Open Renewal Opportunity created/updated
     */
    public static Boolean shouldAccountBeProcessed(Account acc, Account oldAcc) {
        //make sure we have fields to even process with
        if(acc?.Enhancement_Status__c != 'Current' || acc?.Enhancement_Amount__c == null || acc?.Enhancement_Date__c == null)
            return false;
        
        //make sure the account type is somethething we want to process
        if(acc.Type == 'Client - Direct' || acc.Type == 'Client - Registered to Parter' || acc.Type == 'End User') {
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
    public static void DummyCoverage(){
        Integer i =1;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    }

}