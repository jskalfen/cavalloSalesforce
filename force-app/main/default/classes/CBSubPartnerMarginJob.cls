global class CBSubPartnerMarginJob implements Schedulable,Database.Batchable<sObject> {
    global Database.QueryLocator start(Database.BatchableContext BC) {
        Integer TermEndDays = Integer.valueof(System.Label.TermEndDays);
        Set<String> NoPMForStatus = new Set<String>{'NON_RENEWING','CANCELLED'};
        
        String query = 'Select ID,Name,(Select ID,Name,Total_Price__c,chargebeeapps__Product__r.ProductCode,'+
            'chargebeeapps__Product__r.Licensing__c,chargebeeapps__Product__r.Name,'+
            'chargebeeapps__Quantity__c,chargebeeapps__Code__c,chargebeeapps__Subscription__c From '+
            'chargebeeapps__Subscription_Addons__r) '+
            'From chargebeeapps__CB_Subscription__c where chargebeeapps__Subscription_status__c Not In:NoPMForStatus AND Days_To_Term_End__c =:TermEndDays';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<chargebeeapps__CB_Subscription__c> cbSubList) {
        Set<ID> cbSubIdSet = new Set<ID>();
        Set<ID> partnerIdSet = new Set<ID>();
        List<Partner_Margin__c> mergedPMToInsertList = new List<Partner_Margin__c>();
        List<Partner_Margin_Product__c> pmpListToInsert = new List<Partner_Margin_Product__c>();
        Map<Id,List<Partner_Margin__c>> pmSubscriptionIdMap = new Map<Id,List<Partner_Margin__c>>();
        Map<String,chargebeeapps__Subscription_Addon__c> addOnMap = new Map<String,chargebeeapps__Subscription_Addon__c>();
        Map<ID,Map<String,chargebeeapps__Subscription_Addon__c>> cbSubAddOnMap = new Map<ID,Map<String,chargebeeapps__Subscription_Addon__c>>();
        Map<String,Partner_Client_Relationship__c> partnerIdToPartnerClientRelMap = new Map<String,Partner_Client_Relationship__c>();
        String PM_Type_Initial_Purchase = System.Label.PM_Type_Initial_Purchase;
        String PM_Duration_On_Going = System.Label.PM_Duration_On_Going;
        String Sub_Status_Active = System.Label.Sub_Status_Active;
        String PM_Status_Pending = System.Label.PM_Status_Pending;
        String PM_Status_ApprovedForAP = System.Label.PM_Status_ApprovedForAP;
        
        for(chargebeeapps__CB_Subscription__c cbSub:cbSubList){
            if(cbSub != null){
                cbSubIdSet.add(cbSub.Id);
                addOnMap = new Map<String,chargebeeapps__Subscription_Addon__c>();
                for(chargebeeapps__Subscription_Addon__c addOn:cbSub.chargebeeapps__Subscription_Addons__r){
                    if(addOn != null)
                        addOnMap.put(addOn.chargebeeapps__Product__r.ProductCode,addOn);
                }
                cbSubAddOnMap.put(cbSub.Id,addOnMap);
            }
        }
        List<Partner_Margin__c> pmList = [Select ID,Name,CB_Subscription_ID__c,Partner_Billing_Type__c,Partner__c,Client__c,
                                          Partner_Margin_Type__c,Approval_Status__c,Approved_for_AP_Date__c,Opportunity__c,
                                          Partner_Tier__c,Software_Partner_Margin_Y1__c,Partner_Client_Margin_Eligibility__c,
                                          Software_Partner_Margin_Renewal__c,Enhancement_Partner_Margin_Renewal__c,CB_Invoice__c,Invoice_Status__c,Invoice_Amount__c,
                                          Partner_Margin_Duration__c,Partner_Margin_Status__c, (Select ID,Name,Quantity__c,Product_Code__c,Discount__c,
                                                                                                Product_Name__c,Partner_Margin__c,Quantity_Original__c,Licensing__c,Partner_Margin__r.CB_Subscription_ID__c,Partner_Margin__r.Client__c,
                                                                                                Partner_Margin__r.Partner__c,ARR_Opp_Product_Original__c,Notes__c,Perpetual_Type__c,Partial_Partner_Quantity__c,
                                                                                                Partner_Margin__r.Partner_Billing_Type__c,Total_Price_Original__c from 
                                                                                                Partner_Margin_Products__r) From Partner_Margin__c where 
                                          CB_Subscription_ID__c In: cbSubIdSet AND Partner_Margin_Type__c =: PM_Type_Initial_Purchase 
                                          AND Partner_Margin_Duration__c = 'On-going' AND Subscription_Status__c = 'ACTIVE' 
                                          AND (Partner_Margin_Status__c = 'Billed through Partner' OR Partner_Margin_Status__c =: PM_Status_Pending OR Partner_Margin_Status__c =: PM_Status_ApprovedForAP) 
                                          ORDER BY CreatedDate DESC];
        System.debug('PM List::::'+pmList);
        
        for(Partner_Margin__c pm: pmList){
            partnerIdSet.add(pm.Partner__c);
            if (pmSubscriptionIdMap == null || !pmSubscriptionIdMap.containsKey(pm.CB_Subscription_ID__c)) {
                pmSubscriptionIdMap.put(pm.CB_Subscription_ID__c, new List<Partner_Margin__c>());
            }
            pmSubscriptionIdMap.get(pm.CB_Subscription_ID__c).add(pm);
        }
        System.debug('pmSubscriptionIdMap::::'+pmSubscriptionIdMap);
        for(Partner_Client_Relationship__c partnerClientRelp:[Select ID,Partner__c,Client__c,Partner_Client_Margin_Eligibility__c from Partner_Client_Relationship__c where 
                                                              Partner__c In: partnerIdSet]){
                                                                  String pcKey = (String)partnerClientRelp.Partner__c+(String)partnerClientRelp.Client__c;
                                                                  partnerIdToPartnerClientRelMap.put(pcKey,partnerClientRelp);    
                                                              }
        for(Id cbSubId: pmSubscriptionIdMap.keySet()){
            Partner_Margin__c mergedPm = new Partner_Margin__c();
            for(Integer i=0;i < pmSubscriptionIdMap.get(cbSubId).size();i++){
                if(i == 0){
                    Partner_Margin__c p1 = pmSubscriptionIdMap.get(cbSubId)[i];
                    mergedPm = PartnerMarginService.mergePartnerMargin(p1, null);
                }else{
                    Partner_Margin__c p2 = pmSubscriptionIdMap.get(cbSubId)[i];
                    mergedPm = PartnerMarginService.mergePartnerMargin(mergedPm,p2);
                }
            }
            if(partnerIdToPartnerClientRelMap != null && partnerIdToPartnerClientRelMap.size()>0){
                String pcKey = (String)mergedPm.Partner__c+(String)mergedPm.Client__c;
                mergedPm.Partner_Client_Margin_Eligibility__c = partnerIdToPartnerClientRelMap.get(pcKey).Partner_Client_Margin_Eligibility__c;
            }
            
            if(mergedPm.Partner_Client_Margin_Eligibility__c == 'Active'){
            mergedPMToInsertList.add(mergedPm); 
            }
        }
        
        try{
            insert mergedPMToInsertList;
            Map<ID,Set<String>> productPMIdMap = new Map<ID,Set<String>>();
            Set<Id> pmtoAddSet = new Set<Id>();
            List<Partner_Margin__c> pmListToDelete = new List<Partner_Margin__c>();
            for(Partner_Margin__c mergedPM: mergedPMToInsertList){
                
                for(Partner_Margin__c pm: pmSubscriptionIdMap.get(mergedPM.CB_Subscription_ID__c)){
                    System.debug('PM SubscriptionID::::'+pm.CB_Subscription_ID__c);		
                    for(Partner_Margin_Product__c pmp: pm.Partner_Margin_Products__r){
                        System.debug('Sub Map Contains Product Key:::'+cbSubAddOnMap.get(pm.CB_Subscription_ID__c).ContainsKey(pmp.Product_Code__c));
                        if(cbSubAddOnMap.get(pm.CB_Subscription_ID__c).get(pmp.Product_Code__c) != null &&
                           cbSubAddOnMap.get(pm.CB_Subscription_ID__c).ContainsKey(pmp.Product_Code__c) &&
                           pm.Partner__c == mergedPM.Partner__c){
                               System.debug('PMP productCode::::'+pmp.Product_Code__c);
                               System.debug('AddOn'+cbSubAddOnMap.get(pm.CB_Subscription_ID__c).get(pmp.Product_Code__c));
                               Partner_Margin_Product__c pmpcopy = new Partner_Margin_Product__c();
                               pmpcopy.Quantity_Original__c = cbSubAddOnMap.get(pm.CB_Subscription_ID__c).get(pmp.Product_Code__c).chargebeeapps__Quantity__c;
                               pmpcopy.Quantity__c = cbSubAddOnMap.get(pm.CB_Subscription_ID__c).get(pmp.Product_Code__c).chargebeeapps__Quantity__c;
                               pmpcopy.Licensing__c = cbSubAddOnMap.get(pm.CB_Subscription_ID__c).get(pmp.Product_Code__c).chargebeeapps__Product__r.Licensing__c;
                               pmpcopy.Total_Price_Original__c = cbSubAddOnMap.get(pm.CB_Subscription_ID__c).get(pmp.Product_Code__c).Total_Price__c;
                               pmpcopy.ARR_Opp_Product_Original__c = cbSubAddOnMap.get(pm.CB_Subscription_ID__c).get(pmp.Product_Code__c).Total_Price__c;
                               pmpcopy.Partial_Partner_Quantity__c = pmp.Partial_Partner_Quantity__c;
                               pmpcopy.Partner_Margin__c = mergedPM.Id; 
                               pmpcopy.Product_Name__c = pmp.Product_Name__c;
                               pmpcopy.Product_Code__c = pmp.Product_Code__c;
                               pmpcopy.Notes__c = pmp.Notes__c;
                               
                               pmpListToInsert.add(pmpcopy);
                               pmtoAddSet.add(mergedPM.Id);
                           }
                    } 
                   //break;
                }
            }
            if(pmpListToInsert != null && pmpListToInsert.size() > 0){
                insert pmpListToInsert; 
            }
            for(Partner_Margin__c mergedPM: mergedPMToInsertList){
                if(!pmtoAddSet.contains(mergedPM.Id)){
                  pmListToDelete.add(mergedPM);  
                } 
            }
            if(pmListToDelete != null && pmListToDelete.size() > 0){
               Delete pmListToDelete; 
            }
        }catch(Exception e) {
            System.debug(e.getMessage());
        }    
    }
    
    global void execute(SchedulableContext sc) {
        CBSubPartnerMarginJob b = new CBSubPartnerMarginJob(); 
        Database.executeBatch(b);
    }
    
    
    global void finish(Database.BatchableContext BC) {
        // execute any post-processing operations like sending email
    }
}