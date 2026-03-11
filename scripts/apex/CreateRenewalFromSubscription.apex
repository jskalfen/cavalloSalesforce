/**
 * Class to create renewal opportunities directly from CB Subscription records
 * Usage: Execute methods in Anonymous Apex or deploy as a class
 * 
 * Example:
 * String subId = 'a0XXXXXXXXXXXXXXX'; // Replace with actual subscription ID
 * CreateRenewalFromSubscription.createRenewalFromSubscription(subId);
 */
public class CreateRenewalFromSubscription {
    
    public static void createRenewalFromSubscription(String subscriptionId) {
        try {
            // Query the CB Subscription with all required fields
            chargebeeapps__CB_Subscription__c subscription = [
                SELECT Id, Name, 
                       chargebeeapps__Company__c, 
                       chargebeeapps__Company__r.Name,
                       chargebeeapps__Company__r.OwnerId,
                       chargebeeapps__Current_Term_End__c,
                       chargebeeapps__Remaining_Billing_Cycles__c,
                       chargebeeapps__Subscription_Plan__r.Name
                FROM chargebeeapps__CB_Subscription__c 
                WHERE Id = :subscriptionId 
                LIMIT 1
            ];
            
            // Get the New Business record type ID
            Id newBusinessRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName()
                .get('New Business').getRecordTypeId();
            
            // Create the renewal opportunity
            Opportunity renewalOpp = new Opportunity();
            
            // Set the opportunity name: Account Name + Subscription Name + Month/Year | Renewal
            String subscriptionName = subscription.Name != null ? subscription.Name : 'Subscription';
            DateTime now = DateTime.now();
            String monthYear = now.format('MM/yyyy');
            renewalOpp.Name = subscription.chargebeeapps__Company__r.Name + ' ' + subscriptionName + ' ' + monthYear + ' | Renewal';
            
            // Set required fields
            renewalOpp.AccountId = subscription.chargebeeapps__Company__c; // Link to the subscription's account
            renewalOpp.RecordTypeId = newBusinessRecordTypeId; // New Business record type
            renewalOpp.Type = 'Renewal'; // Type: 'Renewal'
            renewalOpp.Opportunity_Source_Global__c = 'Sales'; // Opportunity Source: Sales
            renewalOpp.Opportunity_SubSource_Global__c = 'Renewals'; // Opportunity SubSource: Renewals
            renewalOpp.chargebeeapps__Subscription_Id__c = subscription.Id; // Link to the subscription
            
            // Calculate close date based on subscription term end and remaining billing cycles
            Date closeDate;
            if (subscription.chargebeeapps__Current_Term_End__c != null) {
                Date termEndDate = subscription.chargebeeapps__Current_Term_End__c.date();
                Decimal remainingCycles = subscription.chargebeeapps__Remaining_Billing_Cycles__c;
                
                if (remainingCycles == null || remainingCycles == 0) {
                    // If no remaining cycles, close date = current term end
                    closeDate = termEndDate;
                } else {
                    // Add years based on remaining billing cycles
                    closeDate = termEndDate.addYears(Integer.valueOf(remainingCycles));
                }
            } else {
                // Fallback if no subscription term end date
                closeDate = Date.today().addDays(90);
            }
            
            // Set other standard fields
            renewalOpp.OwnerId = subscription.chargebeeapps__Company__r.OwnerId; // Use Account owner
            renewalOpp.StageName = 'Discovery'; // Start with initial stage
            renewalOpp.CloseDate = closeDate;
            renewalOpp.Probability = 10; // Initial probability
            renewalOpp.LeadSource = 'Existing Customer - Renewal';
            renewalOpp.Description = 'Renewal opportunity created from subscription: ' + subscription.Name + ' (ID: ' + subscription.Id + ')';
            
            // Insert the renewal opportunity
            insert renewalOpp;
            
            System.debug('SUCCESS: Renewal opportunity created successfully from subscription!');
            System.debug('Subscription: ' + subscription.Name + ' (ID: ' + subscription.Id + ')');
            System.debug('New Renewal Opportunity: ' + renewalOpp.Name + ' (ID: ' + renewalOpp.Id + ')');
            System.debug('Account: ' + subscription.chargebeeapps__Company__r.Name);
            System.debug('Record Type: New Business');
            System.debug('Type: Renewal');
            System.debug('Opportunity Source: Sales');
            System.debug('Opportunity SubSource: Renewals');
            System.debug('Close Date: ' + closeDate);
            System.debug('Owner: Account Owner');
            
        } catch (Exception e) {
            System.debug('ERROR: Failed to create renewal opportunity from subscription');
            System.debug('Error Message: ' + e.getMessage());
            System.debug('Stack Trace: ' + e.getStackTraceString());
            throw e;
        }
    }
    
    /**
     * Batch method to create renewals for multiple subscriptions
     * @param subscriptionIds List of subscription IDs to create renewals for
     */
    public static void createRenewalsFromSubscriptions(List<String> subscriptionIds) {
        for (String subId : subscriptionIds) {
            try {
                createRenewalFromSubscription(subId);
            } catch (Exception e) {
                System.debug('Failed to create renewal for subscription: ' + subId);
                System.debug('Error: ' + e.getMessage());
                // Continue with next subscription instead of failing the entire batch
            }
        }
    }
    
    /**
     * Method to create renewals for all active subscriptions for a specific account
     * @param accountId The Account ID to create renewals for
     */
    public static void createRenewalsForAccount(String accountId) {
        try {
            // Query all active subscriptions for the account
            List<chargebeeapps__CB_Subscription__c> subscriptions = [
                SELECT Id 
                FROM chargebeeapps__CB_Subscription__c 
                WHERE chargebeeapps__Company__c = :accountId 
                AND chargebeeapps__Subscription_status__c = 'active'
            ];
            
            List<String> subscriptionIds = new List<String>();
            for (chargebeeapps__CB_Subscription__c sub : subscriptions) {
                subscriptionIds.add(sub.Id);
            }
            
            if (!subscriptionIds.isEmpty()) {
                createRenewalsFromSubscriptions(subscriptionIds);
                System.debug('Created renewal opportunities for ' + subscriptionIds.size() + ' active subscriptions');
            } else {
                System.debug('No active subscriptions found for account: ' + accountId);
            }
            
        } catch (Exception e) {
            System.debug('ERROR: Failed to create renewals for account subscriptions');
            System.debug('Error Message: ' + e.getMessage());
            throw e;
        }
    }
}

// USAGE EXAMPLES:
// 
// Single subscription:
// CreateRenewalFromSubscription.createRenewalFromSubscription('a0XXXXXXXXXXXXXXX');
//
// Multiple subscriptions:
// List<String> subIds = new List<String>{'a0XXXXXXXXXXXXXXX', 'a0YYYYYYYYYYYYYYY'};
// CreateRenewalFromSubscription.createRenewalsFromSubscriptions(subIds);
//
// All active subscriptions for an account:
// CreateRenewalFromSubscription.createRenewalsForAccount('001XXXXXXXXXXXXXXX');
