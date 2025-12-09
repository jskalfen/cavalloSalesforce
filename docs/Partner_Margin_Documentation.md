# Partner Margin Documentation

This document provides comprehensive documentation on the partner margin automation in Salesforce, including how the Sourced vs Influenced checkboxes work, rules for auto-populating the Partner for Margin field, and all related automation.

---

## Table of Contents
1. [Sourced vs Influenced Checkbox - How It Works](#1-sourced-vs-influenced-checkbox---how-it-works)
2. [Rules/Automation for Auto-Populating Partner for Margin Field](#2-rulesautomation-for-auto-populating-partner-for-margin-field)
3. [2025 Rosewater Partner Margin Updates](#3-2025-rosewater-partner-margin-updates)
4. [Complete List of Partner Margin Related Automation](#4-complete-list-of-partner-margin-related-automation)

---

## 1. Sourced vs Influenced Checkbox - How It Works

### Overview
There are two key checkboxes on the Opportunity object:
- **Partner Sourced** (`Partner_Sourced__c`) - Indicates the partner brought/originated the deal
- **Partner Influenced** (`Partner_Influenced__c`) - Indicates the partner influenced the deal but didn't originate it

### Partner Influenced Effect on Partner Margin

**When Partner Influenced is checked (TRUE), the partner margin percentages are HALVED (divided by 2).**

This affects both:
- `Enhancement_Partner_Margin_Y1__c` - Enhancement margin percentage
- `Software_Partner_Margin_Y1__c` - Software margin percentage

#### Automation Details

| Flow | Trigger | Action |
|------|---------|--------|
| `Partner_Margin_Before_Insert` | Partner Margin record created | If Opp > Partner Influenced = TRUE, halves both margin percentages |
| `Opportunity_After_Insert` | Opportunity created | If Partner Influenced = TRUE, retrieves and halves the related Partner Margin |
| `Opportunity_After_Update_New_Business` | Opportunity updated | If Partner Influenced changes: TRUE → halves margins, FALSE → doubles margins (restores original) |

#### Formulas Used
```
HalvedEnhancementFormula = {!$Record.Enhancement_Partner_Margin_Y1__c} / 2
HalvedSoftwareFormula = {!$Record.Software_Partner_Margin_Y1__c} / 2

DoubledEnhancementFormula = {!Partner_Margins_1_loop.Enhancement_Partner_Margin_Y1__c} * 2
DoubledSoftwareFormula = {!Partner_Margins_1_loop.Software_Partner_Margin_Y1__c} * 2
```

### Flow Logic: Partner_Margin_Before_Insert

**Location:** `force-app/main/default/flows/Partner_Margin_Before_Insert.flow-meta.xml`

**Process:**
1. Looks up most recent CB Credit Note for the CB Invoice
2. Sets Partner Billing Type from Partner's `Bill_through_Partner__c` field
3. Sets Partner Margin Duration to "On-going"
4. **Decision: Opp > Partner Influenced?**
   - If YES → Halves Enhancement and Software Partner Margin Y1 percentages
   - If NO → No changes to margins

---

## 2. Rules/Automation for Auto-Populating Partner for Margin Field

The `Partner__c` field (labeled "Partner for Margin") on Opportunity is auto-populated through multiple automation mechanisms.

### A. Opportunity Before Insert Flow

**Flow:** `Opportunity_Before_Insert.flow-meta.xml`

**Trigger:** When a new Opportunity is created

**Conditions for Auto-Population:**
1. Record Type = "New Business"
2. AND Opportunity Type is one of:
   - Expansion - Current products
   - Expansion - New products
   - Expansion - Early renewal with growth
   - Expansion - Perpetual to subscription conversion

**Logic:**
1. Looks up an Active Partner-Client Relationship (`Partner_Client_Relationship__c`) where:
   - `Client__c` = Opportunity Account
   - `Partner_Client_Margin_Eligibility__c` = "Active"
2. If found, sets:
   - `Partner__c` = Partner from the relationship
   - `Partner_Sourced__c` = TRUE

### B. PCR After Insert Flow

**Flow:** `PCR_After_Insert.flow-meta.xml`

**Trigger:** When a new Partner-Client Relationship (PCR) is created

**Conditions:**
- PCR `Partner_Client_Margin_Eligibility__c` = "Active"

**Action:** Updates all open Opportunities matching:
- Same Account (Client)
- Record Type = New Business
- `IsClosed` = FALSE
- Type is one of: New Logo, Expansion - Current products, Expansion - New products, Expansion - Early renewal with growth, Expansion - Perpetual to subscription conversion

**Sets:**
- `Partner__c` = Partner from the PCR
- `Partner_Sourced__c` = TRUE

### C. PCR After Update Flow

**Flow:** `PCR_After_Update.flow-meta.xml`

**Trigger:** When PCR `Partner_Client_Margin_Eligibility__c` is changed to "Active"

**Action:** Same as PCR After Insert - updates matching Opportunities with Partner and Partner Sourced

### D. Validation Rule

**Rule:** `Restrict_Partner_Margin_Partner_Source`

**Location:** `force-app/main/default/objects/Opportunity/validationRules/Restrict_Partner_Margin_Partner_Source.validationRule-meta.xml`

**Purpose:** Restricts who can clear the Partner for Margin and Partner Sourced fields

**Authorized Users:**
- James Williams
- Sam Klooster
- Jesse Clem
- Anne Forshee
- System Administrators

**Error Message:** "You are not authorized to clear Partner for Margin or Partner Sourced."

---

## 3. 2025 Rosewater Partner Margin Updates

Based on the git history, the following partner margin related items were created/updated in 2025:

### REV-1702 (December 2025) - No Partner Margin Product Exclusions

**New Feature:** Ability to exclude specific products from partner margin calculations

#### Components Created:

| Component | Type | Purpose |
|-----------|------|---------|
| `No_Partner_Margin_Product_Code__mdt` | Custom Metadata Type | Stores product codes that should not receive partner margin |
| `No_Partner_Margin__c` | Field (OpportunityLineItem) | Flag indicating product is excluded from partner margin |
| `OpportunityLineItemTriggerHandlerV2.cls` | Apex Class | Automatically sets the No_Partner_Margin__c flag |
| `OpportunityLineItemTriggerHandlerV2Tests.cls` | Test Class | Unit tests for the handler |

#### Custom Metadata Records Created:
- `No_Partner_Margin_Product_Code.PSS_999_901`
- `No_Partner_Margin_Product_Code.PSS_999_903`
- `No_Partner_Margin_Product_Code.PSS_999_905`

#### Logic (OpportunityLineItemTriggerHandlerV2.cls):

```apex
private void setNoPartnerMarginFlag(List<OpportunityLineItem> lineItems) {
    // Get configured Product Codes from Custom Metadata Type
    Set<String> configuredProductCodes = getNoPartnerMarginProductCodes();

    // Set No_Partner_Margin__c flag based on ProductCode
    for (OpportunityLineItem oli : lineItems) {
        if (oli.ProductCode != null) {
            if (configuredProductCodes.contains(oli.ProductCode)) {
                oli.No_Partner_Margin__c = true;
            } else {
                oli.No_Partner_Margin__c = false;
            }
        }
    }
}
```

**Triggers:**
- `beforeInsert` - Sets flag when OpportunityLineItem is created
- `beforeUpdate` - Updates flag if ProductCode changes

#### Impact on Customer Discount
When `No_Partner_Margin__c = TRUE`, the `Customer_Discount__c` formula field returns 0.

### Initial Commit (August 2025) - PCR Flows

The Partner-Client Relationship automation flows were included in the initial commit:
- `PCR_After_Insert.flow-meta.xml`
- `PCR_After_Update.flow-meta.xml`
- `PCR_backfill.flow-meta.xml`

---

## 4. Complete List of Partner Margin Related Automation

### Flows

| Flow Name | Object | Trigger Type | Purpose |
|-----------|--------|--------------|---------|
| `Partner_Margin_Before_Insert` | Partner_Margin__c | Before Create | Sets Partner Billing Type, Margin Duration, halves margins if Partner Influenced |
| `Partner_Margin_Before_Update` | Partner_Margin__c | Before Update | Various update automations |
| `Opportunity_Before_Insert` | Opportunity | Before Create | Auto-populates Partner for Margin from PCR |
| `Opportunity_After_Insert` | Opportunity | After Create | Halves margins if Partner Influenced is TRUE |
| `Opportunity_After_Update_New_Business` | Opportunity | After Update | Updates margins when Partner Influenced changes, updates PM status on close |
| `PCR_After_Insert` | Partner_Client_Relationship__c | After Create | Updates Opportunities with Partner/Partner Sourced |
| `PCR_After_Update` | Partner_Client_Relationship__c | After Update | Updates Opportunities when PCR becomes Active |
| `PCR_backfill` | Partner_Client_Relationship__c | - | Backfill utility flow |
| `Update_Partner_Client_Related_Records` | Partner_Client_Relationship__c | After Update | Updates Partner Margin eligibility |
| `Clone_Partner_Margin` | - | Invocable | Clones Partner Margin records |
| `Automate_Partner_Margin_Name` | Partner_Margin__c | After Save | Auto-populates Partner Margin name |
| `AutoPopulateName` | Partner_Margin_Product__c | After Save | Auto-populates Partner Margin Product name |
| `UpdatePartnerMargin` | - | - | Partner Margin updates |
| `UpdatePartnerMarginAccountFields` | - | - | Updates Account fields from Partner Margin |
| `Update_Opportunity_Partner_Margin` | - | - | Updates Opportunity Partner Margin |
| `Billing_Direct_Pay_Partner_Margin_Automation` | - | - | Direct pay billing automation |
| `Partner_Margin_Updates` | - | - | Partner Margin update automation |

### Apex Classes

| Class | Purpose |
|-------|---------|
| `PartnerMarginService.cls` | Creates/Deletes Partner Margin records, sets margins based on Partner Tier |
| `PartnerMarginTriggerHandler.cls` | Handles Partner Margin updates, syncs changes to Opportunity Products |
| `OpportunityLineItemTriggerHandlerV2.cls` | Sets No_Partner_Margin flag based on Product Code (2025) |
| `OpportunityLineItemTriggerHandler.cls` | Handles Partner Margin creation/deletion on Opp Product changes |
| `OpportunityTriggerHandler.cls` | Creates Partner Margin via PartnerMarginService |
| `CBSubPartnerMarginJob.cls` | Batch job for Chargebee subscription partner margins |
| `PartnerClientRepMarginJob.cls` | Batch job for PCR margin processing |
| `PartnerTierTriggerHandler.cls` | Handles Partner Tier updates |
| `UpdatePartnerJob.cls` | Batch job for updating partner records |

### Key Fields

#### Opportunity Object
| Field API Name | Label | Type | Purpose |
|----------------|-------|------|---------|
| `Partner__c` | Partner for Margin | Lookup (Account) | Identifies the partner involved in the deal |
| `Partner_Sourced__c` | Partner Sourced | Checkbox | Indicates partner originated the deal |
| `Partner_Influenced__c` | Partner Influenced | Checkbox | Indicates partner influenced (but didn't originate) the deal |

#### Partner_Margin__c Object
| Field API Name | Purpose |
|----------------|---------|
| `Software_Partner_Margin_Y1__c` | Software margin percentage for Year 1 |
| `Enhancement_Partner_Margin_Y1__c` | Enhancement margin percentage for Year 1 |
| `Software_Partner_Margin_Renewal__c` | Software margin percentage for renewals |
| `Enhancement_Partner_Margin_Renewal__c` | Enhancement margin percentage for renewals |
| `Partner_Billing_Type__c` | Direct or Bill through Partner |
| `Partner_Margin_Duration__c` | Duration of the margin agreement |
| `Partner_Margin_Status__c` | Status: Pipeline, Pending, Approved for AP, etc. |
| `Partner_Margin_Type__c` | Type: Initial Purchase, Renewal |
| `Partner_Client_Margin_Eligibility__c` | Eligibility status from PCR |
| `Partner_Tier__c` | Partner tier level |
| `Opportunity__c` | Related Opportunity |
| `Partner__c` | Related Partner Account |
| `Client__c` | Related Client Account |

#### OpportunityLineItem Object
| Field API Name | Label | Type | Purpose |
|----------------|-------|------|---------|
| `No_Partner_Margin__c` | No Partner Margin | Checkbox | Excludes product from partner margin calculations (2025) |

#### Account Object (Partner)
| Field API Name | Purpose |
|----------------|---------|
| `Active_Partner_Margin__c` | Active partner margin amount |
| `Active_Partner_Tier__c` | Current active partner tier |
| `Bill_through_Partner__c` | Billing type preference |

### Custom Metadata Types

| Metadata Type | Purpose |
|---------------|---------|
| `No_Partner_Margin_Product_Code__mdt` | Stores product codes excluded from partner margin |

### Related Objects

| Object | Purpose |
|--------|---------|
| `Partner_Margin__c` | Main Partner Margin record |
| `Partner_Margin_Product__c` | Partner Margin line items |
| `Partner_Client_Relationship__c` | Partner-Client relationship records |
| `Partner_Tier__c` | Partner tier definitions and margins |

---

## Summary

| Feature | Description |
|---------|-------------|
| **Sourced vs Influenced** | Partner Influenced = TRUE halves the margin percentages on the Partner Margin card |
| **Partner for Margin Auto-Population** | Uses Partner-Client Relationship (PCR) records with Active eligibility to auto-populate on new/updated Opportunities |
| **2025 Updates** | New "No Partner Margin" feature to exclude specific products from partner margin calculations via Custom Metadata Type configuration |

---

*Last Updated: December 2025*
*Maintained by: Rosewater Development Team*

