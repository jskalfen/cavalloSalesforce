/**
 * Simple Anonymous Apex Script to Create Renewal Opportunity
 * 
 * INSTRUCTIONS:
 * 1. Replace 'YOUR_OPPORTUNITY_ID_HERE' with the actual opportunity ID
 * 2. Execute this script in Anonymous Apex (Developer Console or VS Code)
 */

// REPLACE THIS WITH YOUR ACTUAL OPPORTUNITY ID
String opportunityId = 'YOUR_OPPORTUNITY_ID_HERE';

try {
    // Query the original opportunity with all required fields including CB Subscription Name and term info
    Opportunity originalOpp = [
        SELECT Id, Name, AccountId, Account.Name, Account.OwnerId, 
               chargebeeapps__Subscription_Id__c,
               chargebeeapps__Subscription_Id__r.Name,
               chargebeeapps__Subscription_Id__r.chargebeeapps__Current_Term_End__c,
               chargebeeapps__Subscription_Id__r.chargebeeapps__Remaining_Billing_Cycles__c,
               OwnerId, StageName,
               CloseDate, Probability, LeadSource,
               Description, NextStep, ForecastCategoryName
        FROM Opportunity 
        WHERE Id = :opportunityId 
        LIMIT 1
    ];
    
    // Get the New Business record type ID
    Id newBusinessRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName()
        .get('New Business').getRecordTypeId();
    
    // Create the renewal opportunity
    Opportunity renewalOpp = new Opportunity();
    
    // Set the opportunity name: Original Opp Name + Subscription Name + Month/Year | Renewal
    String subscriptionName = originalOpp.chargebeeapps__Subscription_Id__r?.Name != null ? 
                            originalOpp.chargebeeapps__Subscription_Id__r.Name : ' Subscription';
    DateTime now = DateTime.now();
    String monthYear = now.format('MM/yyyy');
    renewalOpp.Name = originalOpp.Name + ' ' + subscriptionName + ' ' + monthYear + ' | Renewal';
    
    // Set required fields
    renewalOpp.AccountId = originalOpp.AccountId; // Auto populate Account Name
    renewalOpp.RecordTypeId = newBusinessRecordTypeId; // New Business record type
    renewalOpp.Type = 'Renewal'; // Type: 'Renewal'
    renewalOpp.Opportunity_Source_Global__c = 'Sales'; // Opportunity Source: Sales
    renewalOpp.Opportunity_SubSource_Global__c = 'Renewals'; // Opportunity SubSource: Renewals
    renewalOpp.chargebeeapps__Subscription_Id__c = originalOpp.chargebeeapps__Subscription_Id__c; // SubscriptionId
    
    // Calculate close date based on subscription term end and remaining billing cycles
    Date closeDate;
    if (originalOpp.chargebeeapps__Subscription_Id__r?.chargebeeapps__Current_Term_End__c != null) {
        Date termEndDate = originalOpp.chargebeeapps__Subscription_Id__r.chargebeeapps__Current_Term_End__c.date();
        Decimal remainingCycles = originalOpp.chargebeeapps__Subscription_Id__r.chargebeeapps__Remaining_Billing_Cycles__c;
        
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
    renewalOpp.OwnerId = originalOpp.Account.OwnerId;
    renewalOpp.StageName = 'Discovery'; // Start with initial stage
    renewalOpp.CloseDate = closeDate;
    renewalOpp.Probability = 10; // Initial probability
    renewalOpp.LeadSource = 'Existing Customer - Renewal';
    renewalOpp.Description = 'Renewal opportunity created from: ' + originalOpp.Name + ' (ID: ' + originalOpp.Id + ')';
    
    // Insert the renewal opportunity
    insert renewalOpp;
    
    System.debug('SUCCESS: Renewal opportunity created successfully!');
    System.debug('Original Opportunity: ' + originalOpp.Name + ' (ID: ' + originalOpp.Id + ')');
    System.debug('New Renewal Opportunity: ' + renewalOpp.Name + ' (ID: ' + renewalOpp.Id + ')');
    System.debug('Account: ' + originalOpp.Account.Name);
    System.debug('Record Type: New Business');
    System.debug('Type: Renewal');
    System.debug('Opportunity Source: Sales');
    System.debug('Opportunity SubSource: Renewals');
    
} catch (Exception e) {
    System.debug('ERROR: Failed to create renewal opportunity');
    System.debug('Error Message: ' + e.getMessage());
    System.debug('Stack Trace: ' + e.getStackTraceString());
}
