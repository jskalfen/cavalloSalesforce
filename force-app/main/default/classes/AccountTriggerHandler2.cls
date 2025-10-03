public class AccountTriggerHandler2 extends TriggerHandler {

    public override void beforeInsert(List<SObject> triggerNew) {
        List<Account> newAccounts = (List<Account>) triggerNew;
        
        for (Account newAcc : newAccounts) {
            // Set timestamp for ERP (Current) if it has a value
            if (newAcc.ERP__c != null) {
                newAcc.ERP_Time_Stamp__c = DateTime.now();
            }
            
            // Set timestamp for ERP (Future) if it has a value
            if (newAcc.ERP_Future__c != null) {
                newAcc.ERP_Future_Time_Stamp__c = DateTime.now();
            }
            
            // Set timestamp for Evaluation/Migration Date if it has a value
            if (newAcc.Evaluation_Migration_Date__c != null) {
                newAcc.Evaluation_Migration_Date_Time_Stamp__c = DateTime.now();
            }
        }
    }

    public override void beforeUpdate(List<SObject> triggerNew, Map<Id, SObject> triggerOldMap) {
        List<Account> newAccounts = (List<Account>) triggerNew;
        Map<Id, Account> oldAccounts = (Map<Id, Account>) triggerOldMap;
        
        for (Account newAcc : newAccounts) {
            Account oldAcc = oldAccounts.get(newAcc.Id);
            
            // Check if ERP (Current) field has changed
            if (newAcc.ERP__c != oldAcc.ERP__c) {
                newAcc.ERP_Time_Stamp__c = DateTime.now();
            }
            
            // Check if ERP (Future) field has changed
            if (newAcc.ERP_Future__c != oldAcc.ERP_Future__c) {
                newAcc.ERP_Future_Time_Stamp__c = DateTime.now();
            }
            
            // Check if Evaluation/Migration Date field has changed
            if (newAcc.Evaluation_Migration_Date__c != oldAcc.Evaluation_Migration_Date__c) {
                newAcc.Evaluation_Migration_Date_Time_Stamp__c = DateTime.now();
            }
        }
    }

    public override void afterInsert(List<SObject> triggerNew) {

    }

    public override void afterUpdate(List<SObject> triggerNew, Map<Id, SObject> triggerOldMap) {

    }
}