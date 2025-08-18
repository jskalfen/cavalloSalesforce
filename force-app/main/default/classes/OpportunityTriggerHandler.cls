//Trigger Handler for Opportunity Line Item
// 2017-12-21 Ray Dehler <rdehler@square2marketing.com> created
public with sharing class OpportunityTriggerHandler {
    private static final String PRICEBOOK_PREFIX = 'Dealer - ';
   
    public static Feature_Activation__c fa = Feature_Activation__c.getInstance();
    public String oppStageName = 'Discovery';
   
    public static void onBeforeInsert(List<Opportunity> newList) {
        defaultPricebookId(newList);
    }
   
    public static void afterUpdate(Map<Id,Opportunity> newOppMap, Map<Id,Opportunity> oldOppMap) {
        List<Opportunity> oppList = new List<Opportunity>();
        Set<Id> oppIdSet = new Set<Id>();
        Set<Id> oppIdSetToUpdatePM = new Set<Id>();
        Boolean isReccuringRev = false;
        List<OpportunityLineItem> oppProductList = new List<OpportunityLineItem>();
        for(Opportunity opp: newOppMap.values()){
            if(oldOppMap != null && opp.Partner__c != oldOppMap.get(opp.Id).Partner__c && opp.Partner__c != null){
                oppIdSet.add(opp.Id);
            }
            if(oldOppMap != null && opp.chargebeeapps__Subscription_Id__c != oldOppMap.get(opp.Id).chargebeeapps__Subscription_Id__c && opp.chargebeeapps__Subscription_Id__c != null){
                oppIdSetToUpdatePM.add(opp.Id);
            }
        }
        if(oppIdSet != null && oppIdSet.size() > 0){
            oppList = [SELECT ID, Name,Partner__c,StageName,AccountId,Partner__r.Active_Partner_Tier__c,Partner__r.Bill_through_Partner__c,Sales_ARR_MFC1__c,Total_ARR_Opp__c,Subscription_ARR_Opp_MFC__c,Enhancement_ARR_Opp_MFC__c,
                       Subscription_Total_Opp_Billing_MFC__c,Perpetual_Total_Opp_Billing_MFC__c,chargebeeapps__Subscription_Id__c,
                       (Select ID,Name,OpportunityId,Quantity,Recurring_Revenue__c,TotalPrice,
                        Licensing__c,ARR_MFC__c,Perpetual_Type__c,Subscription_Product_Type__c,Product_Name__c,ProductCode 
                        From OpportunityLineItems)
                       FROM Opportunity
                       WHERE Id IN :oppIDSet];
            
            for(Opportunity opp: oppList){
                oppProductList.addAll(opp.OpportunityLineItems);
                for(OpportunityLineItem oppProd: opp.OpportunityLineItems){
                    if(oppProd.Recurring_Revenue__c){
                        isReccuringRev = true; 
                    } 
                }
            }
        }
        
        if(isReccuringRev && oppList != null && oppList.size() > 0 && oppProductList != null && oppProductList.size()>0){
            PartnerMarginService.createPartnerMargin(oppList,oppProductList);
        }
        
        if(oppIdSetToUpdatePM != null && oppIdSetToUpdatePM.size() > 0){
            List<Partner_Margin__c> oppRelatedPMList = [Select ID,CB_Subscription_ID__c,
                                                        Opportunity__r.chargebeeapps__Subscription_Id__c From 
                                                        Partner_Margin__c where Opportunity__c In:oppIdSetToUpdatePM ];
            if(oppRelatedPMList != null && oppRelatedPMList.size() > 0){
                for(Partner_Margin__c pm: oppRelatedPMList){
                   pm.CB_Subscription_ID__c = pm.Opportunity__r.chargebeeapps__Subscription_Id__c; 
                }
                update oppRelatedPMList;
            }
        }
    }
    
    //create quotes and quote line items for opportunity with discovery stage
    /*private static void createQuotesAndLineItems(
    List<Opportunity> opps, Set<Id> accountIds) {
            List<Id> productIds = new List<Id>{'01t6A000003ngnRQAQ','01t3u000006w8RzAAI','01t3u000006w8RuAAI'};
            List<Quote> newQuotes = new List<Quote>();
            List<QuoteLineItem> newQuoteLineItems = new List<QuoteLineItem>();
            //Fetch standard price book detail
            Id standardPbId;
            Map<Id, Pricebook2> pricebookMap = new Map<Id, Pricebook2>();
            //Fetch standard price book detail
            for (Pricebook2 pb : [select Id, Name, IsStandard from Pricebook2 where IsActive = true]) {
                pricebookMap.put(pb.Id, pb);
                if (pb.IsStandard) {
                    standardPbId = pb.Id;
                }
            }
            Map<Id, List<PricebookEntry>> pbEntriesMapByPriceBook = new Map<Id, List<PricebookEntry>>();
            //Fetch price book entries for the given products
            for (PricebookEntry pbEntries : [select id,unitprice,product2id,product2.name,pricebook2id from pricebookentry where product2id IN :productIds and pricebook2id IN: pricebookMap.keyset()]) {
                if(pbEntriesMapByPriceBook.containsKey(pbEntries.pricebook2id)) {
                    pbEntriesMapByPriceBook.get(pbEntries.pricebook2id).add(pbEntries);
                } else {
                    pbEntriesMapByPriceBook.put(pbEntries.pricebook2id, new List<PricebookEntry>{pbEntries});
                }
            }
            //Fetch contact details for accounts
            List<Account> accounts = [Select Id, (Select Id from Contacts) From Account Where Id in : accountIds];
            Map<Id, Id> accountContactMap = new Map<Id, Id>();
            for (Account acc : accounts) {
                if (acc.contacts.size() > 0) {
                    accountContactMap.put(acc.Id, acc.contacts[0].Id);    
                }
            }
           //query quote record type
            Id quoteRecordtypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('Custom').getRecordTypeId();
            //create quotes for respective opportunities
            for (Opportunity opp: opps) {
                Quote newQuote = new Quote();
                newQuote.Name = opp.Name;
                newQuote.opportunityId = opp.Id;
                if (pbEntriesMapByPriceBook.containsKey(opp.PriceBook2ID)) {
                    newQuote.PriceBook2ID = opp.PriceBook2ID;
                     }
                     else {
                    newQuote.PriceBook2ID = standardPbId;
                     }
                if (accountContactMap.containsKey(opp.AccountId)) {
                    newQuote.ContactId = accountContactMap.get(opp.AccountId);
                }
                newQuote.RecordTypeId = quoteRecordtypeId;
                newQuotes.add(newQuote);
            }
            insert newQuotes;
           
            //for inserted quotes create line items for above products
            for(Quote newQuote: newQuotes) {
                if (newQuote.PriceBook2ID != null && pbEntriesMapByPriceBook.containsKey(newQuote.PriceBook2ID)) {
                    for (PricebookEntry pbDetail : pbEntriesMapByPriceBook.get(newQuote.PriceBook2ID)) {
                        QuoteLineItem qli = new QuoteLineItem();
                        qli.Product2Id = pbDetail.Id;
                        qli.quoteId = newQuote.Id;
                        qli.UnitPrice = 1;
                        qli.Quantity = 1;
                        qli.PriceBookentryid = pbDetail.pricebook2id;
                        newQuoteLineItems.add(qli);
                    }
                }

            }
            insert newQuoteLineItems;
   
    }*/
   
    private static void defaultPricebookId(List<Opportunity> newList) {
        if (!fa.Default_Pricebook_Id__c) {
            return;
        }
       
        Map<String, Pricebook2> pricebookMap = new Map<String, Pricebook2>();
        Id standardPbId;
        for (Pricebook2 pb : [select Id, Name, IsStandard from Pricebook2 where IsActive = true]) {
            pricebookMap.put(pb.Name, pb);
            if (pb.IsStandard) {
                standardPbId = pb.Id;
            }
        }

        Map<Id, Account> accountMap = new Map<Id, Account>();
        for (Opportunity opp : newList) {
            accountMap.put(opp.AccountId, null);
        }        
       
        accountMap = new Map<Id, Account>([select Partner_Level__c from Account where Id in :accountMap.keySet()]);
       
        for (Opportunity opp : newList) {
            if (opp.Pricebook2Id != null) {
                continue;
            }
            //Account acct = accountMap.get(opp.AccountId);
            //String key = PRICEBOOK_PREFIX + acct.Partner_Level__c;
            //if (pricebookMap.containsKey(key)) {
            //    opp.Pricebook2Id = pricebookMap.get(key).Id;
            //} else {
                opp.Pricebook2Id = standardPbId;
            //}
        }
    }
}