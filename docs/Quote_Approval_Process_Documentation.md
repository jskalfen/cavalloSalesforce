# Quote Approval Process Documentation

**Prepared by:** Rosewater Solutions, LLC

---

## Overview

This document provides comprehensive documentation for the Quote Approval process in Salesforce, beginning with the Submit for Approval standard button on quotes and covering all related flows, validation rules, and automation.

## Table of Contents

1. [Process Overview](#process-overview)
2. [Submit for Approval Button](#submit-for-approval-button)
3. [Quote Status Values](#quote-status-values)
4. [Approval Process Flow](#approval-process-flow)
5. [Related Flows](#related-flows)
6. [Validation Rules](#validation-rules)
7. [Fields and Configuration](#fields-and-configuration)
8. [Process Steps and History](#process-steps-and-history)
9. [Auto-Approval Logic](#auto-approval-logic)
10. [Integration Points](#integration-points)

---

## Process Overview

The Quote Approval process is a multi-step workflow that manages quote approvals based on discount thresholds, partner margins, and business rules. The process includes:

- **Manual Submission**: Users can manually submit quotes for approval using the standard "Submit" button
- **Automatic Re-submission**: Quotes are automatically re-submitted when discount/term changes exceed thresholds
- **Auto-Approval**: Some quotes are automatically approved based on partner margin alignment
- **Status Management**: Quote status is automatically updated based on approval outcomes
- **Opportunity Integration**: Opportunity records are updated to reflect quote approval status

---

## Submit for Approval Button

### Button Configuration

The standard "Submit" button is configured in the Quote record page layout and flexipage:

**Location**: `force-app/main/default/flexipages/Quote_Record_Page_Default.flexipage-meta.xml`

```xml
<valueListItems>
    <value>Submit</value>
    <visibilityRule>
        <criteria>
            <leftValue>{!Record.Status}</leftValue>
            <operator>NE</operator>
            <rightValue>Approved</rightValue>
        </criteria>
    </visibilityRule>
</valueListItems>
```

**Visibility Rules**:
- The Submit button is visible when Quote Status ≠ "Approved"
- Hidden for already approved quotes to prevent re-submission

### Button Behavior

When clicked, the Submit button:
1. Initiates the standard Salesforce approval process
2. Triggers the `GP_Discount_Approval_Process_Updated` approval process
3. Changes quote status to "In Review"
4. Creates approval history records (ProcessSteps)

---

## Quote Status Values

The Quote object supports the following status values across different record types:

### Available Status Values
- **Draft** (default)
- **Needs Review**
- **In Review**
- **Approved**
- **Approved for Partner Margin**
- **Rejected**
- **Denied**
- **Presented**
- **Accepted**

### Status Transitions

#### Primary Approval Flow
```
Draft → Needs Review → In Review → Approved
```

#### Rejection Paths
```
In Review → Rejected
In Review → Denied
```

#### Post-Approval Flow
```
Approved → Presented → Accepted
```

#### Modification Reset
```
Approved → Draft (if discount/terms are modified after approval)
```

#### Special Status
```
Approved for Partner Margin (alternative approval status for partner-related quotes)
```

**Key Transition Rules**:
- **Draft**: Initial status, can move to "Needs Review" or directly to "In Review"
- **Needs Review**: Manual status for quotes requiring review before submission
- **In Review**: Automatically set when quote is submitted for approval
- **Approved**: Set by approval process upon final approval
- **Rejected/Denied**: Set by approval process upon rejection
- **Presented**: Manual status after quote is presented to customer
- **Accepted**: Final status when customer accepts the quote
- **Approved for Partner Margin**: Special approval status for partner scenarios

---

## Approval Process Flow

The Quote approval system consists of multiple approval processes that handle different scenarios based on opportunity record types and user roles. Here are the active approval processes:

### 1. Approval Process for Account Executives (Active)

**File**: `Quote.Approval_Process_for_Account_Executives.approvalProcess-meta.xml`
**Process Order**: 2
**Status**: Active

**Entry Criteria**:
- Opportunity Record Type = "New Business"

**Allowed Submitters**:
- Account Executive role

**Approval Steps**:

#### Level 1 GP Approval
- **Approver**: jesse.clem@cavallo.com
- **Entry Criteria**: `(Discount > 10% OR Is_Discount_Forever = True OR (Term_Length < 3 AND Type = "New Logo")) AND Auto_Approved = False`
- **If Criteria Not Met**: Auto-approve record
- **Delegation**: Allowed

#### Level 2 GP Approval  
- **Approver**: john.carrier@cavallo.com
- **Entry Criteria**: `Discount > 20% AND Auto_Approved = False`
- **Approval Method**: Unanimous
- **Delegation**: Allowed

### 2. Approval Process for Account Managers (Active)

**File**: `Quote.Approval_Process_for_Account_Managers.approvalProcess-meta.xml`
**Process Order**: 1
**Status**: Active

**Entry Criteria**:
- Opportunity Record Type = "New Business"

**Allowed Submitters**:
- Account Manager role
- Project Manager role

**Approval Steps**:

#### Level 1 GP Approval
- **Approver**: jesse.clem@cavallo.com
- **Entry Criteria**: `((Discount > 5% OR Is_Discount_Forever = True OR Discount_Term_Length > 1) AND Auto_Approved = False) AND Opportunity.Type ≠ "Expansion - Services only"`
- **If Criteria Not Met**: Auto-approve record
- **Delegation**: Allowed

#### Level 2 GP Approval
- **Approver**: john.carrier@cavallo.com  
- **Entry Criteria**: `Discount > 30% AND Auto_Approved = False`
- **Approval Method**: Unanimous
- **Delegation**: Allowed

### 3. GP Discount Approval Process Updated (Inactive)

**File**: `Quote.GP_Discount_Approval_Process_Updated.approvalProcess-meta.xml`
**Process Order**: 1
**Status**: Inactive (Referenced in flows but not active)

This process is referenced in the automation flows but is currently inactive. It contains similar logic to the active processes:

**Entry Criteria**:
- Opportunity Record Type = "New Business"

**Approval Steps**:
- **Level 1**: Discount > 10% OR Is_Discount_Forever = True OR Discount_Term_Length > 1
- **Level 2**: Discount > 20% OR Discount_Term_Length > 1 OR Is_Discount_Forever = True

### 4. BC Discount Approval Process Updated (Inactive)

**File**: `Quote.BC_Discount_Approval_Process_Updated.approvalProcess-meta.xml`
**Status**: Inactive

**Entry Criteria**:
- Opportunity Record Type = "Business Central"

**Approval Thresholds**:
- **Level 1**: Discount > 5% OR Is_Discount_Forever = True OR Discount_Term_Length > 1
- **Level 2**: Discount > 20% OR Discount_Term_Length > 1 OR Is_Discount_Forever = True

### Approval Process Configuration Details

#### Common Configuration Across All Processes

**Approval Page Fields** (displayed during approval):
- Name
- Quote Number  
- Account
- Opportunity
- Discount Term Length
- Discount %
- Is Discount Forever
- Grand Total
- Subtotal

**Email Templates**:
- GP processes: `GP_Discount_Approval_Request`
- BC processes: `BC_Discount_Approval_Request`

**Actions Triggered**:

**Initial Submission Actions**:
- Email notification: `BC_Submitted_For_Approval_Notification`
- Field update: `Initial_Submission_Status_Update` (sets status to "In Review")

**Final Approval Actions**:
- Email notification: `BC_Quote_Approved_Notification`
- Field update: `Status_Approved` (sets status to "Approved")

**Final Rejection Actions**:
- Email notification: `BC_Quote_Rejected_Notification`
- Field update: `Status_Rejected` (sets status to "Rejected")

**Security Settings**:
- Record editability during approval: Admin Only
- Mobile device access: Enabled
- Approval history: Visible
- Record lock after final approval: False
- Record lock after final rejection: False

#### Auto-Approval Logic in Processes

All approval processes include logic to automatically approve quotes when:
- `Auto_Approved__c = True` (set by Quote Before Update flow)
- Criteria are not met for manual approval steps

This creates a seamless integration between the flow-based auto-approval logic and the formal approval processes.

#### Process Selection Logic

When a quote is submitted for approval, Salesforce evaluates the active approval processes in order of their `processOrder`:

1. **Account Managers Process** (Order 1): Triggered for Account Manager and Project Manager roles
2. **Account Executives Process** (Order 2): Triggered for Account Executive role

Both processes have the same entry criteria (`Opportunity Record Type = "New Business"`), but different allowed submitters ensure the correct process is used based on the user's role.

**Key Differences Between Processes**:

| Aspect | Account Managers | Account Executives |
|--------|------------------|-------------------|
| **Level 1 Threshold** | Discount > 5% | Discount > 10% |
| **Level 2 Threshold** | Discount > 30% | Discount > 20% |
| **Special Conditions** | Excludes "Expansion - Services only" | Includes Term Length < 3 for "New Logo" |
| **Allowed Submitters** | Account Manager, Project Manager roles | Account Executive role |

---

## Related Flows

### 1. Quote Submit For Approval On Discount Increase

**File**: `force-app/main/default/flows/Quote_Submit_For_Approval_On_Discount_Increase.flow-meta.xml`

**Trigger**: Record-triggered flow (After Save) on Quote updates

**Conditions**:
- Quote Status = "Approved" OR "In Review" 
- Quote Status has changed
- Record Type = "New Business"

**Logic Flow**:
```
1. Check Record Type (New Business)
2. Lookup Partner Margin record
3. Check if Partner Billing Type = "Bill through Partner"
4. If yes, lookup CB Opportunity Coupon
5. Compare CB Opportunity Discount with Partner Margin Discount
6. Check if Discount/Term increased:
   - Discount > 10% AND increased from prior value
   - Discount Term Length > 0 AND increased
   - Is Discount Forever changed from false to true
7. If conditions met, submit for approval via GP_Approval_Process
```

**Key Decision Points**:
- **Record Type Check**: Only processes "New Business" opportunities
- **Partner Billing Check**: Special handling for "Bill through Partner" scenarios
- **Discount Threshold**: Automatic submission when discount > 10% and increased
- **Term Changes**: Monitors discount term length and "forever" discount changes

**Approval Submission**:
```xml
<actionName>submit</actionName>
<actionType>submit</actionType>
<inputParameters>
    <name>processDefinitionNameOrId</name>
    <value>GP_Discount_Approval_Process_Updated</value>
</inputParameters>
<inputParameters>
    <name>comment</name>
    <value>This quote is submitted for approval as discount or term is increased.</value>
</inputParameters>
```

**Note**: The flow references `GP_Discount_Approval_Process_Updated`, but this process is currently inactive. The active processes are:
- `Approval_Process_for_Account_Executives` (Process Order 2)
- `Approval_Process_for_Account_Managers` (Process Order 1)

The system will use the active process with the lowest process order that matches the entry criteria.

### 2. Quote Before Update

**File**: `force-app/main/default/flows/Quote_Before_Update.flow-meta.xml`

**Trigger**: Record-triggered flow (Before Save) on Quote updates

**Purpose**: Auto-approval logic and status management

**Logic Flow**:
```
1. Check Opportunity Record Type (New Business)
2. Lookup Partner Margin record
3. Check Partner Billing Type = "Bill through Partner"
4. If yes, lookup CB Opportunity Coupon
5. Compare discounts:
   - CB Opportunity Discount = Partner Margin Y1 Discount
   - CB Opportunity Discount = Quote Discount
6. Set Auto_Approved__c = true if conditions match
7. Check if approved quote was modified:
   - Status = "Approved" AND
   - (Discount changed OR Is_Discount_Forever changed OR Discount_Term_Length changed)
8. If modified after approval, reset Status to "Draft"
```

**Auto-Approval Criteria**:
- Partner billing through partner
- CB Opportunity discount matches both Partner Margin and Quote discount
- Ensures alignment across all discount values

### 3. Quote After Update

**File**: `force-app/main/default/flows/Quote_After_Update.flow-meta.xml`

**Trigger**: Record-triggered flow (After Save) on Quote updates

**Purpose**: Update related Opportunity when quote approval status changes

**Logic Flow**:
```
1. Check if Quote Status changed
2. If Status contains "Approved":
   - Update Opportunity.Is_Quote_Approved__c = true
3. If Status does not contain "Approved":
   - Update Opportunity.Is_Quote_Approved__c = false
```

### 4. Opportunity Update Is Quote Approved

**File**: `force-app/main/default/flows/Opportunity_Update_Is_Quote_Approved.flow-meta.xml`

**Purpose**: Maintains quote approval status on Opportunity records

**Logic**: Updates `Is_Quote_Approved__c` field based on related approved quotes

---

## Validation Rules

### 1. Quote Status Change Validation

**File**: `force-app/main/default/objects/Quote/validationRules/Quote_Status_Change_Validation.validationRule-meta.xml`

**Rule**: Prevents status changes until quote is approved

**Conditions**:
- Opportunity Record Type = "Cloud" OR "Business Central"
- Status is changed
- Prior Status = "Draft", "Needs Review", or "In Review"

**Error Message**: "You cannot change the status until the Quote is Approved"

**Formula**:
```
AND(
    OR(Opportunity.RecordType.DeveloperName = 'Cloud', Opportunity.RecordType.DeveloperName = 'Business Central'),
    ISCHANGED(Status),
    OR(
        (TEXT(PRIORVALUE(Status)) = "Draft"),
        (TEXT(PRIORVALUE(Status)) = "Needs Review"),
        (TEXT(PRIORVALUE(Status)) = "In Review")
    )
)
```

### 2. Quote Approved Validation (Opportunity)

**File**: `force-app/main/default/objects/Opportunity/validationRules/Quote_Approved_Validation.validationRule-meta.xml`

**Rule**: Prevents Opportunity closure without approved quote

**Conditions**:
- Stage Name changed to "Closed Won"
- Is_Quote_Approved__c = false
- Record Type = "New Business"

**Error Message**: "You cannot update the stage beyond Contractual until there is a synced and approved Quote."

---

## Fields and Configuration

### Quote Object Fields

#### Auto_Approved__c
- **Type**: Checkbox
- **Default**: false
- **Description**: Indicates if the quote will be automatically approved in an approval process
- **History Tracking**: Enabled

#### Status
- **Type**: Picklist
- **History Tracking**: Enabled
- **Values**: Draft, Needs Review, In Review, Approved, Approved for Partner Margin, Rejected, Denied, Presented, Accepted

### Opportunity Object Fields

#### Is_Quote_Approved__c
- **Type**: Checkbox
- **Default**: false
- **Description**: Used to check if related Quote is Approved
- **Updated By**: Quote After Update flow

---

## Process Steps and History

### ProcessSteps Related List

The Quote record page includes a "ProcessSteps" related list that shows:
- Approval history
- Comments from approvers
- Approval/rejection timestamps
- Current approval status

**Configuration**: Located in the Quote Record Page sidebar
```xml
<relatedListApiName>ProcessSteps</relatedListApiName>
```

### History Tracking

Both Quote Status and Auto_Approved__c fields have history tracking enabled, providing:
- Field change audit trail
- User who made changes
- Timestamps of changes
- Previous and new values

---

## Auto-Approval Logic

### Conditions for Auto-Approval

A quote is automatically approved when ALL conditions are met:

1. **Opportunity Record Type**: "New Business"
2. **Partner Billing Type**: "Bill through Partner"
3. **Discount Alignment**: 
   - CB Opportunity Coupon Discount = Partner Margin Y1 Discount
   - CB Opportunity Coupon Discount = Quote Discount
4. **Partner Margin Exists**: Valid Partner Margin record found

### Auto-Approval Process

1. **Before Save Flow**: Sets `Auto_Approved__c = true` when conditions are met
2. **Approval Process**: Recognizes auto-approved quotes and fast-tracks them
3. **Status Update**: Quote moves directly to "Approved" status
4. **Opportunity Update**: `Is_Quote_Approved__c` set to true

---

## Integration Points

### Partner Margin Integration

The approval process integrates with Partner Margin records:
- **Lookup**: Based on Opportunity.Partner__c
- **Validation**: Compares discount values for consistency
- **Billing Type**: Special handling for "Bill through Partner"

### ChargeeBee Integration

Integration with ChargeeBee for discount validation:
- **CB Opportunity Coupon**: Lookup based on Opportunity ID
- **Discount Comparison**: Ensures alignment with CB discount values
- **Product Validation**: Checks product codes and quantities

### DocuSign Integration

Quote approval status affects DocuSign workflow:
- **Status Dependency**: DocuSign sending may require approved quotes
- **Component Visibility**: DocuSign component shows based on user permissions

---

## Troubleshooting Guide

### Common Issues

1. **Submit Button Not Visible**
   - Check Quote Status (hidden if already "Approved")
   - Verify user permissions for approval processes

2. **Auto-Approval Not Working**
   - Verify Partner Margin record exists
   - Check discount value alignment
   - Confirm Partner Billing Type = "Bill through Partner"

3. **Quote Stuck in "In Review"**
   - Check approval process assignment rules
   - Verify approvers are active users
   - Review approval process criteria

4. **Status Validation Errors**
   - Ensure quote is approved before changing status
   - Check record type restrictions
   - Verify user has appropriate permissions

### Monitoring and Maintenance

1. **Flow Monitoring**: Monitor flow execution in Setup > Process Automation > Flow
2. **Approval Process Health**: Review pending approvals regularly
3. **Field History**: Use Quote History related list for audit trails
4. **Process Steps**: Monitor approval bottlenecks via ProcessSteps

---

## Technical Implementation Details

### Flow Execution Order

1. **Before Save**: Quote Before Update flow
2. **After Save**: Quote Submit For Approval On Discount Increase flow
3. **After Save**: Quote After Update flow
4. **Approval Process**: GP_Discount_Approval_Process_Updated

### Performance Considerations

- Flows use efficient SOQL queries with proper filtering
- Lookup operations are optimized with getFirstRecordOnly
- Bulk processing considerations for data loads

### Security and Permissions

- Approval processes respect user permissions
- Field-level security applies to approval fields
- Record-level access controls approval visibility

---

## Conclusion

The Quote Approval process is a comprehensive system that handles both manual and automatic approval workflows. It integrates with partner margins, ChargeeBee discounts, and opportunity management to ensure consistent and accurate quote approvals across the organization.

Key benefits:
- **Automated Processing**: Reduces manual effort through intelligent automation
- **Consistency**: Ensures discount alignment across systems
- **Audit Trail**: Comprehensive history tracking for compliance
- **Integration**: Seamless connection with partner and billing systems
- **Flexibility**: Supports various approval scenarios and business rules

For additional support or modifications to the approval process, consult with your Salesforce administrator or development team.
