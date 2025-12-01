public class OpportunityLineItemTriggerHandlerV2 extends TriggerHandler {

    private static Set<String> noPartnerMarginProductCodes = null;

    public override void beforeInsert(List<SObject> newList) {
        List<OpportunityLineItem> lineItems = (List<OpportunityLineItem>) newList;
        setNoPartnerMarginFlag(lineItems);
    }

    public override void beforeUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        List<OpportunityLineItem> lineItems = (List<OpportunityLineItem>) newList;
        Map<Id, OpportunityLineItem> oldLineItemsMap = (Map<Id, OpportunityLineItem>) oldMap;
        
        // Check if ProductCode changed
        List<OpportunityLineItem> lineItemsToProcess = new List<OpportunityLineItem>();
        for (OpportunityLineItem oli : lineItems) {
            OpportunityLineItem oldOli = oldLineItemsMap.get(oli.Id);
            if (oli.ProductCode != oldOli.ProductCode) {
                lineItemsToProcess.add(oli);
            }
        }
        
        if (!lineItemsToProcess.isEmpty()) {
            setNoPartnerMarginFlag(lineItemsToProcess);
        }
    }

    private void setNoPartnerMarginFlag(List<OpportunityLineItem> lineItems) {
        if (lineItems == null || lineItems.isEmpty()) {
            return;
        }

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

    private static Set<String> getNoPartnerMarginProductCodes() {
        if (noPartnerMarginProductCodes == null) {
            noPartnerMarginProductCodes = new Set<String>();
            List<No_Partner_Margin_Product_Code__mdt> metadataRecords = [
                SELECT Product_Code__c
                FROM No_Partner_Margin_Product_Code__mdt
                WHERE Product_Code__c != null
            ];

            for (No_Partner_Margin_Product_Code__mdt record : metadataRecords) {
                noPartnerMarginProductCodes.add(record.Product_Code__c);
            }
        }
        return noPartnerMarginProductCodes;
    }
}

