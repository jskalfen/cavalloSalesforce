public class AccountTriggerHandler2 extends TriggerHandler {

    private static Set<String> multiselectValues(String raw) {
        Set<String> values = new Set<String>();
        if (String.isBlank(raw)) {
            return values;
        }
        for (String token : raw.split(';')) {
            if (!String.isBlank(token)) {
                values.add(token.trim());
            }
        }
        return values;
    }

    /** True when the new multiselect includes at least one value not present before (new selection). */
    private static Boolean whitespaceProductsGainedNewValue(String oldRaw, String newRaw) {
        Set<String> oldVals = multiselectValues(oldRaw);
        for (String v : multiselectValues(newRaw)) {
            if (!oldVals.contains(v)) {
                return true;
            }
        }
        return false;
    }

    /**
     * When a MID picklist value changes, stores the prior value and refreshes the change timestamp.
     * Clearing the picklist still counts as an edit (previous holds the last selected value).
     */
    private static void applyMidPicklistEdit(
        Account newAcc,
        Account oldAcc,
        Schema.SObjectField midField,
        Schema.SObjectField previousField,
        Schema.SObjectField stampField
    ) {
        String oldVal = (String) oldAcc.get(midField);
        String newVal = (String) newAcc.get(midField);
        if (newVal == oldVal) {
            return;
        }
        newAcc.put(previousField, oldVal);
        newAcc.put(stampField, DateTime.now());
    }

    public override void beforeInsert(List<SObject> triggerNew) {
        List<Account> newAccounts = (List<Account>) triggerNew;
        
        for (Account newAcc : newAccounts) {
            if (!multiselectValues(newAcc.Whitespace_Products__c).isEmpty()) {
                newAcc.Whitespace_Products_Date_Stamp__c = DateTime.now();
            }

            if (newAcc.PayFabric_MIDs__c != null) {
                newAcc.PayFabric_MIDs_Date_Stamp__c = DateTime.now();
            }
            if (newAcc.Square_MIDs__c != null) {
                newAcc.Square_MIDs_Date_Stamp__c = DateTime.now();
            }

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

            if (whitespaceProductsGainedNewValue(oldAcc.Whitespace_Products__c, newAcc.Whitespace_Products__c)) {
                newAcc.Whitespace_Products_Date_Stamp__c = DateTime.now();
            }

            applyMidPicklistEdit(
                newAcc,
                oldAcc,
                Account.PayFabric_MIDs__c,
                Account.PayFabric_MIDs_Previous__c,
                Account.PayFabric_MIDs_Date_Stamp__c
            );
            applyMidPicklistEdit(
                newAcc,
                oldAcc,
                Account.Square_MIDs__c,
                Account.Square_MIDs_Previous__c,
                Account.Square_MIDs_Date_Stamp__c
            );
            
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