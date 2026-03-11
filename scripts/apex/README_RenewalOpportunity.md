# Renewal Opportunity Creation Scripts

This folder contains Apex scripts to create renewal opportunities from existing opportunities in Salesforce.

## Files

1. **CreateRenewalOpportunity.apex** - Reusable class with methods for creating renewal opportunities
2. **create_renewal_simple.apex** - Simple anonymous Apex script for one-time execution

## Features

The script creates a new opportunity with the following specifications:

### Required Fields Set:
- **Opportunity Name**: `Original Opportunity Name + CB Subscription Name + Month/Year | Renewal`
- **Account**: Auto-populated from original opportunity
- **Record Type**: "New Business" 
- **Type**: "Renewal"
- **Opportunity Source**: "Sales"
- **Opportunity SubSource**: "Renewals"
- **Subscription ID**: Copied from original opportunity

### Additional Fields Set:
- **Owner**: Set to Account owner (not original opportunity owner)
- **Currency**: Same as original opportunity  
- **Stage**: "Prospecting" (initial stage)
- **Close Date**: Calculated based on subscription Current Term End + Remaining Billing Cycles
- **Probability**: 10% (initial probability)
- **Lead Source**: "Existing Customer - Renewal"
- **Description**: Reference to original opportunity

## Usage Options

### Option 1: Anonymous Apex (Recommended for single use)

1. Open **create_renewal_simple.apex**
2. Replace `'YOUR_OPPORTUNITY_ID_HERE'` with your actual opportunity ID
3. Execute in Developer Console or VS Code Anonymous Apex

```apex
// Example:
String opportunityId = '006XXXXXXXXXXXXXXX';
```

### Option 2: Deploy Class and Use Methods

1. Deploy **CreateRenewalOpportunity.apex** to your org
2. Use the methods in Anonymous Apex:

```apex
// Single opportunity
CreateRenewalOpportunity.createRenewal('006XXXXXXXXXXXXXXX');

// Multiple opportunities
List<String> oppIds = new List<String>{'006XXXXXXXXXXXXXXX', '006YYYYYYYYYYYYYYY'};
CreateRenewalOpportunity.createRenewals(oppIds);
```

## Prerequisites

- The original opportunity must exist and be accessible
- User must have permissions to:
  - Read opportunities and accounts
  - Create opportunities
  - Access the "New Business" record type

## Field Mapping Details

| Requirement | Field API Name | Value |
|-------------|----------------|-------|
| Record Type | RecordTypeId | New Business record type ID |
| Type | Type | 'Renewal' |
| Opportunity Source | Opportunity_Source_Global__c | 'Sales' |
| Opportunity SubSource | Opportunity_SubSource_Global__c | 'Renewals' |
| Subscription ID | chargebeeapps__Subscription_Id__c | Copied from original |
| Account | AccountId | Copied from original |

## Error Handling

The scripts include comprehensive error handling:
- Validates opportunity exists
- Handles missing fields gracefully
- Provides detailed debug output
- For batch operations, continues processing if one fails

## Debug Output

When successful, you'll see output like:
```
SUCCESS: Renewal opportunity created successfully!
Original Opportunity: ABC Corp Desktop 12/2025 (ID: 006XXXXXXXXXXXXXXX)
New Renewal Opportunity: ABC Corp Desktop 12/2025 SalesPad Cloud 01/2026 | Renewal (ID: 006YYYYYYYYYYYYYYY)
Account: ABC Corp
Record Type: New Business
Type: Renewal
Opportunity Source: Sales
Opportunity SubSource: Renewals
```

## Close Date Calculation

The close date is calculated based on the subscription's Current Term End and Remaining Billing Cycles:

- **If Current Term End = 3/1/26 and Remaining Billing Cycles = null/0**: Close Date = 3/1/26
- **If Current Term End = 3/1/26 and Remaining Billing Cycles = 1**: Close Date = 3/1/27  
- **If Current Term End = 3/1/26 and Remaining Billing Cycles = 2**: Close Date = 3/1/28
- **Fallback**: If no subscription term end date is available, defaults to 90 days from today

## Notes

- The subscription name is derived from the `Name` field on the related `chargebeeapps__CB_Subscription__c` record
- If no CB Subscription is linked or no name is specified, "Subscription" is used as default
- Month/Year format is MM/yyyy (e.g., "01/2026")
- The script sets the renewal opportunity owner to the Account owner and preserves the original opportunity's currency settings
