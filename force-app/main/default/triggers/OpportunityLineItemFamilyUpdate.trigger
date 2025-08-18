trigger OpportunityLineItemFamilyUpdate on OpportunityLineItem (before insert, before update) {
    
	String OpportunityLineItemFamilyUpdateEnabled = System.Label.OpportunityLineItemFamilyUpdateEnabled;
    if(OpportunityLineItemFamilyUpdateEnabled == 'False'){
        return;
    }
    List<String> productIds = new List<String>();
    for (OpportunityLineItem oli : trigger.new) {
        productIds.add(oli.Product2Id);
    }
    Map<Id,Product2> productIdObMap = 
       new Map<Id, Product2>([
            SELECT
                Id,
                Family
            FROM Product2
            WHERE Id IN: productIds
        ]);
    for (OpportunityLineItem oli : trigger.new) {
        Product2 prouctObj = productIdObMap.get(oli.Product2Id);
        oli.Product_Family__c = prouctObj.Family;
    }

}