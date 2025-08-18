/*Class created to handle Partner Margins
* 
* */
public class PartnerMarginService {
    
    /*Method: createPartnerMargin
* Paremeter: Input parameter List of Opportunities and List of Opportunity Line Items.
* Is called from updateOpportunityWithARR Method of classOpportunityLineItemTriggerHandler 
* to create Partner Margin(Initial Purchase) records based on Opportunity and Opportunity Line Item. 
* Created On: 7th Nov 2023
* Created By: Shivani Thakur
* */
    public static void createPartnerMargin(List<Opportunity> oppList, List<OpportunityLineItem> oppLineList){
        List<Partner_Margin__c> pmListToInsert = new List<Partner_Margin__c>();
        Map<ID,Partner_Margin__c> mapOfInsertedPartnerMargin = new Map<ID,Partner_Margin__c>();
        Map<ID,Partner_Tier__c> partnerIdToPartnerTierMap = new Map<ID,Partner_Tier__c>();
        Map<String,Partner_Client_Relationship__c> partnerIdToPartnerClientRelMap = new Map<String,Partner_Client_Relationship__c>();
        List<Partner_Margin_Product__c> pmProductListToInsert = new List<Partner_Margin_Product__c>();
        List<OpportunityLineItem> oppProductToUpdateList = new List<OpportunityLineItem>();
        Set<ID> pmProductIDSet = new Set<Id>();
        Set<ID> partnerIdSet = new Set<ID>();
        Set<ID> OppoProductIdset = new Set<ID>();
        String PM_Type_Initial_Purchase = System.Label.PM_Type_Initial_Purchase;
        String PM_Status_Pipeline = System.Label.PM_Status_Pipeline;
        String PM_Status_Pending = System.Label.PM_Status_Pending;
        String Opp_Stage_ClosedWon = System.Label.Opp_Stage_ClosedWon;
        
        for(Opportunity opp: oppList){
            partnerIdSet.add(opp.Partner__c); 
        }
        for(Partner_Tier__c partnerTier:[Select ID,Partner_Tier_Margin__c,Partner__c,Partner_Tier__c from Partner_Tier__c where 
                                         PartnerTier_Status__c = 'Active' AND Partner__c In: partnerIdSet]){
                                             partnerIdToPartnerTierMap.put(partnerTier.Partner__c,partnerTier);    
                                         }
        for(Partner_Client_Relationship__c partnerClientRelp:[Select ID,Partner__c,Client__c,Partner_Client_Margin_Eligibility__c from Partner_Client_Relationship__c where 
                                                              Partner__c In: partnerIdSet]){
                                                                  String pcKey = (String)partnerClientRelp.Partner__c + (String)partnerClientRelp.Client__c;
                                                                  partnerIdToPartnerClientRelMap.put(pcKey,partnerClientRelp);    
                                                              }
        for(Opportunity opp: oppList){
            Partner_Margin__c pm = new Partner_Margin__c();
            pm.Opportunity__c = opp.Id;
            pm.CB_Subscription_ID__c = opp.chargebeeapps__Subscription_Id__c;
            pm.Client__c = opp.AccountId;
            pm.Partner__c = opp.Partner__c;
            pm.Partner_Billing_Type__c = opp.Partner__r.Bill_through_Partner__c;
            pm.Partner_Margin_Type__c = PM_Type_Initial_Purchase;
            pm.Enhancement_Partner_Margin_Y1__c = 15;
            if(opp.StageName == Opp_Stage_ClosedWon){
                pm.Partner_Margin_Status__c = PM_Status_Pending; 
            }else{
                pm.Partner_Margin_Status__c = PM_Status_Pipeline;
            }
            if(partnerIdToPartnerTierMap != null && partnerIdToPartnerTierMap.size()>0){
                pm.Software_Partner_Margin_Y1__c = partnerIdToPartnerTierMap.get(opp.Partner__c).Partner_Tier_Margin__c;
                pm.Partner_Tier__c = partnerIdToPartnerTierMap.get(opp.Partner__c).Partner_Tier__c;
                if(partnerIdToPartnerTierMap.get(opp.Partner__c).Partner_Tier__c == 'Bronze'){
                  pm.Enhancement_Partner_Margin_Y1__c = partnerIdToPartnerTierMap.get(opp.Partner__c).Partner_Tier_Margin__c;  
                }
            }
            
            if(partnerIdToPartnerClientRelMap != null && partnerIdToPartnerClientRelMap.size()>0){
                String patClientKey = (String)opp.Partner__c+(String)opp.AccountId;
                pm.Partner_Client_Margin_Eligibility__c = partnerIdToPartnerClientRelMap.get(patClientKey).Partner_Client_Margin_Eligibility__c;
            }
            
            mapOfInsertedPartnerMargin.put(pm.Opportunity__c,pm);
        }
        
        
        
        try{
            if(mapOfInsertedPartnerMargin != null && mapOfInsertedPartnerMargin.size()>0){
                insert mapOfInsertedPartnerMargin.values(); 
            }
            
            for(OpportunityLineItem oli: oppLineList){
                OppoProductIdset.add(oli.Id);
                if((oli.Recurring_Revenue__c || (String.isEmpty(oli.Subscription_Product_Type__c) || oli.Subscription_Product_Type__c != 'N/A')) 
                   && oli.TotalPrice > 0){
                       Partner_Margin_Product__c pmProduct = new Partner_Margin_Product__c();
                       pmProduct.Partner_Margin__c = mapOfInsertedPartnerMargin.get(oli.OpportunityId).Id;
                       pmProduct.Quantity_Original__c = oli.Quantity;
                       pmProduct.Quantity__c = oli.Quantity;
                       pmProduct.Licensing__c = oli.Licensing__c;
                       pmProduct.Perpetual_Type__c = oli.Perpetual_Type__c;    
                       pmProduct.ARR_Opp_Product_Original__c = oli.ARR_MFC__c;
                       pmProduct.Product_Name__c = oli.Product_Name__c;
                       pmProduct.Product_Code__c = oli.ProductCode;
                       pmProduct.Opportunity_Product__c = oli.Id;
                       
                       pmProductListToInsert.add(pmProduct);
                   }
            }
            
            if(pmProductListToInsert != null && pmProductListToInsert.size() > 0){
                insert pmProductListToInsert; 
            }
            if(OppoProductIdset != null && OppoProductIdset.size() > 0){
                updateOppProductWithPM(OppoProductIdset);
            }
            
        }catch(Exception exp){
            System.debug('Exception while creating Partner Margin Records: '+exp.getMessage()); 
        }
        
    }
    
    @future
    public static void updateOppProductWithPM(Set<Id> OppoProductIdSet){
        Map<Id,Partner_Margin__c> partnerIdToPMMap = new Map<Id,Partner_Margin__c>();
        Set<Id> oppIdSet = new Set<Id>();
        String PMStatusDirect = System.Label.PM_Status_Direct;
        Decimal softwarePMY1Total = 0.00;
        Decimal enhancementPMY1Total = 0.00;
        Boolean isUpdated = false;
        Map<String,Decimal> pmTotalMarginMap = new Map<String,Decimal>();
        Map<Id,Map<String,Decimal>> partnerIdToPMTotalsMap = new Map<Id,Map<String,Decimal>>();
        List<OpportunityLineItem> oppProductListToUpdate = [Select Id,Licensing__c,OpportunityId,Recurring_Revenue__c,
                                                            Opportunity.Partner__c,Partner_Payment_Opp_Product_Direct__c,Subscription_Product_Type__c 
                                                            From OpportunityLineItem WHERE ID In: OppoProductIdSet];
        
        for(OpportunityLineItem opProduct: oppProductListToUpdate){
            oppIdSet.add(opProduct.OpportunityId);
        }
        
        for(Partner_Margin__c pmObj: [Select ID,Partner__c,Opportunity__c,Software_Partner_Margin_Y1__c,Enhancement_Partner_Margin_Y1__c,
                                      Partner_Billing_Type__c FROM Partner_Margin__c where Partner_Billing_Type__c = 'Direct' AND  
                                      Opportunity__c In: oppIdSet]){
                                          if(pmObj.Software_Partner_Margin_Y1__c != null){ 
                                              softwarePMY1Total += pmObj.Software_Partner_Margin_Y1__c;
                                          }
                                          if(pmObj.Enhancement_Partner_Margin_Y1__c != null){
                                              enhancementPMY1Total += pmObj.Enhancement_Partner_Margin_Y1__c;   
                                          }
                                          pmTotalMarginMap.put('softwarePMY1Total',softwarePMY1Total);
                                          pmTotalMarginMap.put('enhancementPMY1Total',enhancementPMY1Total);
                                          partnerIdToPMTotalsMap.put(pmObj.Opportunity__c,pmTotalMarginMap);
                                          partnerIdToPMMap.put(pmObj.Opportunity__c, pmObj);
                                      }
        
        
        
        for(OpportunityLineItem opProduct: oppProductListToUpdate){
            
            if(partnerIdToPMMap != null && partnerIdToPMMap.size() > 0
               && partnerIdToPMMap.get(opProduct.OpportunityId).Partner_Billing_Type__c == 'Direct'){
                   if(opProduct.Licensing__c == System.Label.OppLine_Licensing_Subscription){
                       opProduct.Partner_Payment_Opp_Product_Direct__c = partnerIdToPMTotalsMap.get(opProduct.OpportunityId).get('softwarePMY1Total'); 
                       isUpdated = true;
                   }else if(opProduct.Licensing__c == System.Label.OppLine_Licensing_Perpetual && opProduct.Recurring_Revenue__c){
                       opProduct.Partner_Payment_Opp_Product_Direct__c =  partnerIdToPMTotalsMap.get(opProduct.OpportunityId).get('enhancementPMY1Total');
                       isUpdated = true;
                   }else if(opProduct.Licensing__c == System.Label.OppLine_Licensing_Perpetual && opProduct.Subscription_Product_Type__c != 'N/A'){ 
                       opProduct.Partner_Payment_Opp_Product_Direct__c =  partnerIdToPMTotalsMap.get(opProduct.OpportunityId).get('softwarePMY1Total');
                       isUpdated = true;
                   }
               }
            
            if((partnerIdToPMMap == null || partnerIdToPMMap.size() == 0) && !isUpdated ){
                opProduct.Partner_Payment_Opp_Product_Direct__c = 0.00; 
            }
        }
        
        try{
            update oppProductListToUpdate;
        }catch(Exception exp){
            System.Debug('Exception while updating Opportunity Product: '+exp.getMessage()); 
        }        
    }
    
    /*Method: deletePartnerMargin
* Paremeter: Input parameter Set of opportunity Ids.
* Is called from updateOpportunityWithARR Method of classOpportunityLineItemTriggerHandler
* Created On: 7th Nov 2023
* Created By: Shivani Thakur
* */
    public static void deletePartnerMargin(Set<Id> oppIdSet){
        List<Partner_Margin__c> pmListToDelete = new List<Partner_Margin__c>();
        List<Partner_Margin_Product__c> pmProductToDeleteList = new List<Partner_Margin_Product__c>();
        try{
            for(Partner_Margin__c pm : [Select ID,Name From Partner_Margin__c where Opportunity__c In: oppIdSet]){           
                pmListToDelete.add(pm);
            }
            if(pmListToDelete != null && pmListToDelete.size()>0){
                Delete pmListToDelete;  
            }
        }catch(Exception exp){
            System.debug('Exception While deleting Partner Margin records '+ exp.getMessage()); 
        }
    }
    
    @future
    public static void updatePartnerForInactiveTiers(Set<Id> acctIdSet){
        List<Account> acctList = [Select ID,Name,Active_Partner_Margin__c,Active_Partner_Tier__c From Account Where ID IN: acctIdSet];
        for(Account acct : acctList){
            acct.Active_Partner_Margin__c = 0;
            acct.Active_Partner_Tier__c = 'None';
        }
        
        update acctList;
    }
    
    @InvocableMethod(Label = 'Clone Partner Margin')
    public static List<Id> clonePartnerMargin(List<Partner_Margin__c> pmList){
        Set<Id> pmIdSet = new Set<Id>();
        List<Partner_Margin_Product__c> clonedpmProductsList = new List<Partner_Margin_Product__c>();
        for(Partner_Margin__c pm: pmList){
            pmIdSet.add(pm.Id);  
        }
        List<Id> clonedPmId = new List<Id>();
        List<Partner_Margin_Product__c> pmProductsList = [Select Id,Name,Partner_Margin__c,ARR_Opp_Product_Original__c,Notes__c,
                                                          Partial_Partner_Quantity__c,Licensing__c,Opportunity_Product__c,Total_Price_Original__c,Quantity_Original__c,
                                                          Product_Code__c,Product_Name__c,Discount__c,Quantity__c from Partner_Margin_Product__c 
                                                          Where Partner_Margin__c In: pmIdSet];
        Partner_Margin__c clonedPM = pmList[0].Clone(false,true,false,false);
        insert clonedPM;
        
        for(Partner_Margin_Product__c pmProduct: pmProductsList){
            Partner_Margin_Product__c clonedpmProduct = pmProduct.clone(false,true,false,false);
            clonedpmProduct.Partner_Margin__c = clonedPM.Id;
            clonedpmproduct.Total_Price_Original__c = pmProduct.Total_Price_Original__c;
            clonedpmproduct.Opportunity_Product__c = pmProduct.Opportunity_Product__c;
            clonedpmproduct.Partial_Partner_Quantity__c = pmProduct.Partial_Partner_Quantity__c;
            clonedpmproduct.Notes__c = pmProduct.Notes__c;   
            clonedpmProductsList.add(clonedPmProduct);
        }
        clonedPmId.add(clonedPM.Id);
        insert clonedpmProductsList;
        return clonedPmId; 
    }
    
    
    public static Partner_Margin__c mergePartnerMargin(Partner_Margin__c p1,Partner_Margin__c p2){
        String PM_Type_Initial_Purchase = System.Label.PM_Type_Initial_Purchase;
        String PM_Duration_On_Going = System.Label.PM_Duration_On_Going;
        String Sub_Status_Active = System.Label.Sub_Status_Active;
        String PM_Status_Pending = System.Label.PM_Status_Pending;
        String PM_Status_ApprovedForAP = System.Label.PM_Status_ApprovedForAP;
        String PM_Status_BillThroughPartner = System.Label.PM_Status_BillThroughPartner;
        String PMStatusDirect = System.Label.PM_Status_Direct;
        String PM_Type_Renewal = System.Label.PM_Type_Renewal;
        Partner_Margin__c mergedPM = new Partner_Margin__c();
        mergedPM.CB_Subscription_ID__c = p1.CB_Subscription_ID__c;
        if(p1.Partner_Billing_Type__c == PM_Status_BillThroughPartner){
            mergedPM.Partner_Margin_Status__c = 'Billed through Partner';
        }else{
            mergedPM.Partner_Margin_Status__c = PM_Status_Pending;    
        }
        mergedPM.Partner_Margin_Type__c = PM_Type_Renewal;
        mergedPM.Client__c = p1.Client__c;
        mergedPM.Partner__c = p1.Partner__c;
        if(p2 != null && p2.Partner_Billing_Type__c != p1.Partner_Billing_Type__c){
            mergedPM.Partner_Billing_Type__c = PMStatusDirect;
        }else{
            mergedPM.Partner_Billing_Type__c = p1.Partner_Billing_Type__c;
        }
        mergedPM.Partner_Tier__c = p1.Partner_Tier__c;
        mergedPM.Partner_Margin_Duration__c = p1.Partner_Margin_Duration__c;
        mergedPM.Software_Partner_Margin_Y1__c = p1.Software_Partner_Margin_Y1__c;
        if(p2 != null && p2.Software_Partner_Margin_Renewal__c != null && p1.Software_Partner_Margin_Renewal__c != null){
            mergedPM.Software_Partner_Margin_Renewal__c = p1.Software_Partner_Margin_Renewal__c + p2.Software_Partner_Margin_Renewal__c;
        }else{
            mergedPM.Software_Partner_Margin_Renewal__c = p1.Software_Partner_Margin_Renewal__c;
        }
        if(p2 != null && p2.Enhancement_Partner_Margin_Renewal__c != null && p1.Enhancement_Partner_Margin_Renewal__c != null){
            mergedPM.Enhancement_Partner_Margin_Renewal__c = p1.Enhancement_Partner_Margin_Renewal__c + p2.Enhancement_Partner_Margin_Renewal__c;
        }else{
            mergedPM.Enhancement_Partner_Margin_Renewal__c = p1.Enhancement_Partner_Margin_Renewal__c;
        }
        
        
        return mergedPM;  
    }
    
}