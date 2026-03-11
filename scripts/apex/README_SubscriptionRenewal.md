# Subscription-Based Renewal Opportunity Creation Scripts

This folder contains Apex scripts to create renewal opportunities directly from CB Subscription records, even when there's no existing associated opportunity.

## Files

1. **CreateRenewalFromSubscription.apex** - Reusable class with methods for creating renewal opportunities from subscriptions
2. **create_renewal_from_subscription.apex** - Simple anonymous Apex script for one-time execution

## Use Cases

These scripts are perfect when you need to create renewal opportunities for:
- Subscriptions that don't have existing opportunities
- Bulk renewal creation for multiple subscriptions
- Account-wide renewal opportunity generation
- Automated renewal processes based on subscription data

## Features

The script creates a new opportunity with the following specifications:

### Required Fields Set:
- **Opportunity Name**: `Account Name + Subscription Name + Month/Year | Renewal`
- **Account**: Auto-populated from subscription's company
- **Record Type**: "New Business" 
- **Type**: "Renewal"
- **Opportunity Source**: "Sales"
- **Opportunity SubSource**: "Renewals"
- **Subscription ID**: Linked to the source subscription

### Additional Fields Set:
- **Owner**: Set to Account owner
- **Currency**: Inherited from account settings
- **Stage**: "Discovery" (initial stage)
- **Close Date**: Calculated based on subscription Current Term End + Remaining Billing Cycles
- **Probability**: 10% (initial probability)
- **Lead Source**: "Existing Customer - Renewal"
- **Description**: Reference to source subscription

## Close Date Calculation

The close date is calculated based on the subscription's Current Term End and Remaining Billing Cycles:

- **If Current Term End = 3/1/26 and Remaining Billing Cycles = null/0**: Close Date = 3/1/26
- **If Current Term End = 3/1/26 and Remaining Billing Cycles = 1**: Close Date = 3/1/27  
- **If Current Term End = 3/1/26 and Remaining Billing Cycles = 2**: Close Date = 3/1/28
- **Fallback**: If no subscription term end date is available, defaults to 90 days from today

## Usage Options

### Option 1: Anonymous Apex (Recommended for single use)

1. Open **create_renewal_from_subscription.apex**
2. Replace `'YOUR_SUBSCRIPTION_ID_HERE'` with your actual subscription ID
3. Execute in Developer Console or VS Code Anonymous Apex

```apex
// Example:
String subscriptionId = 'a0XXXXXXXXXXXXXXX';
```

### Option 2: Deploy Class and Use Methods

1. Deploy **CreateRenewalFromSubscription.apex** to your org
2. Use the methods in Anonymous Apex:

```apex
// Single subscription
CreateRenewalFromSubscription.createRenewalFromSubscription('a0XXXXXXXXXXXXXXX');

// Multiple subscriptions
List<String> subIds = new List<String>{'a0XXXXXXXXXXXXXXX', 'a0YYYYYYYYYYYYYYY'};
CreateRenewalFromSubscription.createRenewalsFromSubscriptions(subIds);

// All active subscriptions for an account
CreateRenewalFromSubscription.createRenewalsForAccount('001XXXXXXXXXXXXXXX');
```

## Prerequisites

- The subscription must exist and be accessible
- The subscription must be linked to a valid Account (Company)
- User must have permissions to:
  - Read CB Subscription records and accounts
  - Create opportunities
  - Access the "New Business" record type

## Field Mapping Details

| Requirement | Field API Name | Value |
|-------------|----------------|-------|
| Record Type | RecordTypeId | New Business record type ID |
| Type | Type | 'Renewal' |
| Opportunity Source | Opportunity_Source_Global__c | 'Sales' |
| Opportunity SubSource | Opportunity_SubSource_Global__c | 'Renewals' |
| Subscription ID | chargebeeapps__Subscription_Id__c | Source subscription ID |
| Account | AccountId | From subscription's Company field |

## Error Handling

The scripts include comprehensive error handling:
- Validates subscription exists
- Handles missing fields gracefully
- Provides detailed debug output
- For batch operations, continues processing if one fails

## Debug Output

When successful, you'll see output like:
```
SUCCESS: Renewal opportunity created successfully from subscription!
Subscription: SalesPad Cloud (ID: a0XXXXXXXXXXXXXXX)
New Renewal Opportunity: ABC Corp SalesPad Cloud 01/2026 | Renewal (ID: 006YYYYYYYYYYYYYYY)
Account: ABC Corp
Record Type: New Business
Type: Renewal
Opportunity Source: Sales
Opportunity SubSource: Renewals
Close Date: 2027-03-01
Owner: Account Owner
```

## Advanced Usage

### Bulk Processing for Multiple Accounts
```apex
List<String> accountIds = new List<String>{'001XXXXX', '001YYYYY', '001ZZZZZ'};
for (String accountId : accountIds) {
    CreateRenewalFromSubscription.createRenewalsForAccount(accountId);
}
```

### Filter by Subscription Status
The `createRenewalsForAccount` method automatically filters for active subscriptions only. To modify this behavior, you can customize the SOQL query in the method.

## Notes

- The subscription name is derived from the `Name` field on the `chargebeeapps__CB_Subscription__c` record
- If no subscription name is specified, "Subscription" is used as default
- Month/Year format is MM/yyyy (e.g., "01/2026")
- The script sets the renewal opportunity owner to the Account owner
- This approach is ideal for subscriptions that don't have existing opportunities or for bulk renewal generation

