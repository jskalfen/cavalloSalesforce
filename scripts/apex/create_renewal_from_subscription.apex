
try {
    // Query the CB Subscription with all required fields
    List<chargebeeapps__CB_Subscription__c> subscriptions = [
        SELECT Id, Name, ARR__c,
               chargebeeapps__Company__c, 
               chargebeeapps__Company__r.Name,
               chargebeeapps__Company__r.OwnerId,
               chargebeeapps__Current_Term_End__c,
               chargebeeapps__Remaining_Billing_Cycles__c,
               chargebeeapps__Subscription_Plan__r.Name,
               Renewal_Created__c
        FROM chargebeeapps__CB_Subscription__c 
        WHERE chargebeeapps__Current_Term_End__c >= 2026-05-01T00:00:00Z
        AND Renewal_Created__c = false
        LIMIT 100
    ];
    
    List<Opportunity> renewalOpportunities = new List<Opportunity>();
    for (chargebeeapps__CB_Subscription__c subscription : subscriptions) {
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
    renewalOpp.Subscription_ARR_Opp_MFC__c = subscription.ARR__c;
    renewalOpportunities.add(renewalOpp);

    // Update the subscription to mark the renewal as created
    subscription.Renewal_Created__c = true;
    }
    
    // Insert the renewal opportunity
    insert renewalOpportunities;

    update subscriptions;

    System.debug('SUCCESS: Renewal opportunities created successfully from subscriptions!');
    System.debug('Subscriptions: ' + subscriptions.size());
    System.debug('Renewal Opportunities: ' + renewalOpportunities.size());
} catch (Exception e) {
    System.debug('ERROR: Failed to create renewal opportunities from subscriptions');
    System.debug('Error Message: ' + e.getMessage());
    System.debug('Stack Trace: ' + e.getStackTraceString());
}
