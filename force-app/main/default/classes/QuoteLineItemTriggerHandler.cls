// Trigger Handler for Quote Line Item
// 2017-12-21 Ray Dehler <rdehler@square2marketing.com> created
public with sharing class QuoteLineItemTriggerHandler {
    private static final String ENHANCEMENT_APPEND = ' Enhancement';
    private static final String ERROR_ON_INSERT = 'Unable to Add Enhancement Product, please contact your Administrator';
    private static final String ERROR_ON_PM_SERVICE_INSERT = 'Unable to add the PM Services Product to this quote.';
    private static final String ENHANCEMENT_PERCENT_STRING = '22';
    private static final DOUBLE ENHANCEMENT_PERCENT = .22;
    
    
    public static Feature_Activation__c fa = Feature_Activation__c.getInstance();
    private static Boolean alreadyRan = false;
    
    public static void onAfterInsert(Map<Id, QuoteLineItem> newMap) {
        if (!alreadyRan) {
            alreadyRan = true;
            addEnhancementItem(newMap);   
            addPMServicesItem(newMap);
        } else {
            System.debug('Skipped running trigger.');
        }
    }
    
    public static String formatCurrency(Decimal i) {
    if (i == null) return '0.00';
    i = Decimal.valueOf(Math.roundToLong(i * 100)) / 100;
    String s = (i.setScale(2) + (i >= 0 ? 0.001 : -0.001)).format();
    return s.substring(0, s.length() - 1);
	}
    
    // for each of the Items being added, if there is another product
    // with Enhancement at the end, add it also
    private static void addEnhancementItem(Map<Id, QuoteLineItem> newMap) {
        if (!fa.Add_Enhancement_Items__c) {
            return;
        }
        
        Map<Id, QuoteLineItem> existingQliMap = new Map<Id, QuoteLineItem>();
        Set<String> productNameSet = new Set<String>();
        Set<Id> pricebookIds = new Set<Id>();
        Map<String, PricebookEntry> pricebookEntryMap = new Map<String, PricebookEntry>();
        Map<Id, QuoteLineItem> qlisToAdd = new Map<Id, QuoteLineItem>();
        Map<Id, Set<String>> quoteProductSetMap = new Map<Id, Set<String>>();
        
        // fill collections
        for (Id qliId : newMap.keySet()) {
            QuoteLineItem qli = newMap.get(qliId);
            existingQliMap.put(qli.Id, null);
        }
        
        existingQliMap = new Map<Id, QuoteLineItem>([
            select Product2.Name, Product2Id, PricebookEntry.Pricebook2Id, QuoteId, Quantity, Line_Number__c 
            from QuoteLineItem
            where Id in :existingQliMap.keySet()]);
        
        for (Id qliId : existingQliMap.keySet()) {
            QuoteLineItem qli = existingQliMap.get(qliId);
            productNameSet.add(qli.Product2.Name + ENHANCEMENT_APPEND);
            pricebookIds.add(qli.PricebookEntry.Pricebook2Id);
            quoteProductSetMap.put(qli.QuoteId, new Set<String>());
        }

        for (QuoteLineItem qli : [
            select Product2.Name, QuoteId
            from QuoteLineItem
            where QuoteId in :quoteProductSetMap.keySet()]) {
            
            quoteProductSetMap.get(qli.QuoteId).add(qli.Product2.Name);
        }        
        for (PricebookEntry pbe : [
            select Product2.Name, Pricebook2Id, UnitPrice
            from PricebookEntry
            where Product2.Name in :productNameSet
              and Pricebook2Id in :pricebookIds]) {
              
            pricebookEntryMap.put(pbe.Product2.Name + ';' + pbe.Pricebook2Id, pbe);      
        }
        
        
        

        for (Id qliId : existingQliMap.keySet()) {
            QuoteLineItem qli = existingQliMap.get(qliId);
            update qli;
            String key = qli.Product2.Name + ENHANCEMENT_APPEND + ';' + qli.PricebookEntry.Pricebook2Id;
            if (pricebookEntryMap.containsKey(key) && !quoteProductSetMap.get(qli.QuoteId).contains(qli.Product2.Name + ENHANCEMENT_APPEND)) {
                QuoteLineItem qliToAdd = new QuoteLineItem();
                qliToAdd.QuoteId = qli.QuoteId;
                qliToAdd.PricebookEntryId = pricebookEntryMap.get(key).Id;
                qliToAdd.Product2Id = qli.Product2Id;
                qliToAdd.Quantity = qli.Quantity;
                qliToAdd.UnitPrice = pricebookEntryMap.get(key).UnitPrice;
                //qliToAdd.Line_Number__c = qli.Line_Number__c + .1;
                
                
                qliToAdd.Comments__c = String.Format('{0}% Annual Enhancement per concurrent user. \nProrated Enhancement from date: \nList price: $', new String[] {ENHANCEMENT_PERCENT_STRING});                
                qlisToAdd.put(qliId, qliToAdd);
            }
        }
        
        if (!qlisToAdd.isEmpty()) {
            try {
                insert qlisToAdd.values();
            } catch (Exception e) {
                // could segment the actual error, but let's error all for now
                for (Id qliId : qlisToAdd.keySet()) {
                    newMap.get(qliId).addError(ERROR_ON_INSERT);
                }
            }
        }
        
        
    }
    
    private static void addPMServicesItem(Map<Id, QuoteLineItem> newMap) {
        Map<Id, QuoteLineItem> existingQliMap = new Map<Id, QuoteLineItem>();
        Map<Id, QuoteStatus> existingQuotes = new Map<Id, QuoteStatus>();
        Map<String, PricebookEntry> pricebookEntryMap = new Map<String, PricebookEntry>();
        Map<Id, QuoteLineItem> qlisToAdd = new Map<Id, QuoteLineItem>();
        Map<Id, Set<String>> quoteProductSetMap = new Map<Id, Set<String>>();
        
        // Just looking for a line that matches the criteria.
        
        existingQliMap = new Map<Id, QuoteLineItem>([
            select Product2.Name, Product2Id, Product2.ProductCode, PricebookEntry.Pricebook2Id, QuoteId, Quantity, Line_Number__c 
            from QuoteLineItem
            where Id in :newMap.keySet()
        ]);

        for (QuoteLineItem line : existingQliMap.values()) {
            QuoteStatus status;
            if (!existingQuotes.containsKey(line.QuoteId)) {
                status = new QuoteStatus();
                status.QuoteId = line.QuoteId;
                existingQuotes.put(line.QuoteId, status);
            } else {
                status = existingQuotes.get(line.QuoteId);
            }
            
            if (line.Product2.Name.containsIgnoreCase('PM Services')) {
                existingQuotes.get(line.QuoteId).hasServiceLine = true; // Don't add if it's already there.
            } else if (line.Product2.ProductCode.containsIgnoreCase('Consulting')) {
                // Perfer using "PM Services" over "Solutions PM Services".
                status.hasConsultingLine = true;
                status.pricebook2Id = line.PricebookEntry.Pricebook2Id;
                status.quantity += line.Quantity;
            } else if (line.Product2.ProductCode.containsIgnoreCase('Solutions')) {
                if (!status.hasConsultingLine) {
                    status.hasSolutionsLine = true;
                    status.pricebook2Id = line.PricebookEntry.Pricebook2Id;
                }
                status.quantity += line.Quantity;
            }
        }
        
        // Load the needed services item (Name is 'PM Services' or 'Solutions PM Services')
        
        for (QuoteStatus status : existingQuotes.values()) {
            if (status.hasConsultingLine) {
                if (status.matchingServiceLine == null) {
                    status.matchingServiceLine = [SELECT Product2.Id, Product2.Name, Product2.ProductCode, Pricebook2Id, UnitPrice
                    FROM PricebookEntry
                    WHERE Product2.Name = 'PM Services'
                    AND Pricebook2Id = :status.pricebook2Id];
                }
            } else if (status.hasSolutionsLine) {
                if (status.matchingServiceLine == null) {
                    status.matchingServiceLine = [SELECT Product2.Id, Product2.Name, Product2.ProductCode, Pricebook2Id, UnitPrice
                    FROM PricebookEntry
                    WHERE Product2.Name = 'Solutions PM Services'
                    AND Pricebook2Id = :status.pricebook2Id];
                }
            }
        }

        for (QuoteStatus status : existingQuotes.values()) { 
            if (status.hasServiceLine) {
                continue;
            }
            if (status.hasConsultingLine) {
                QuoteLineItem qliToAdd = new QuoteLineItem();
                qliToAdd.QuoteId = status.quoteId;
                qliToAdd.PricebookEntryId = status.matchingServiceLine.Id;
                qliToAdd.Product2Id = status.matchingServiceLine.Product2.Id;
                qliToAdd.Quantity = status.quantity;
                qliToAdd.UnitPrice = status.matchingServiceLine.UnitPrice * .15;
                qliToAdd.Comments__c = 'An additional 15% of the total consulting hours will be billed for Basic Project management services which include involvement on the initial kickoff, creation of the initial project plan for the SalesPad product implementation, and standard schedule coordination for the SP consultant assigned.\nPM involvement on Kickoff\nInitial Project Plan for SP Implementation\nConsultant schedule coordination/task management';
                qlisToAdd.put(status.quoteId, qliToAdd);
            } else if (status.hasSolutionsLine) {
                QuoteLineItem qliToAdd = new QuoteLineItem();
                qliToAdd.QuoteId = status.quoteId;
                qliToAdd.PricebookEntryId = status.matchingServiceLine.Id;
                qliToAdd.Product2Id = status.matchingServiceLine.Product2.Id;
                qliToAdd.Quantity = status.quantity;
                qliToAdd.UnitPrice = status.matchingServiceLine.UnitPrice * .15;
                qliToAdd.Comments__c = 'An additional 15% of the total consulting hours will be billed for Basic Project management services which include involvement on the initial kickoff, creation of the initial project plan for the SalesPad product implementation, and standard schedule coordination for the SP consultant assigned.\nPM involvement on Kickoff\nInitial Project Plan for SP Implementation\nConsultant schedule coordination/task management';
                qlisToAdd.put(status.quoteId, qliToAdd);
            }
        }
        
        if (!qlisToAdd.isEmpty()) {
            insert qlisToAdd.values();
        }
    }

    private class QuoteStatus {
        public Boolean hasServiceLine;
        public Boolean hasConsultingLine;
        public Boolean hasSolutionsLine;
        public ID pricebook2Id;
        public Double quantity;
        public ID quoteId;
        public PricebookEntry matchingServiceLine;
        
        public QuoteStatus() {
            hasServiceLine = false;
            hasConsultingLine = false;
            hasSolutionsLine = false;
            quantity = 0;
        }
    }

    public static void onBefore(List<QuoteLineItem> qtlnList, List<QuoteLineItem> qtlnOldList){
        Set<ID> quoteIdSet = new Set<ID>();
        if(qtlnList != null){
            for(QuoteLineItem qtln: qtlnList){
                quoteIdSet.add(qtln.QuoteId);
            }
        }else{
           for(QuoteLineItem qtlnold: qtlnOldList){
                quoteIdSet.add(qtlnold.QuoteId);
            } 
        }
        Map<ID,Quote> quoteMap = new Map<ID,Quote>([Select ID,Status,Name From Quote where ID In: quoteIdSet]);
    	if(qtlnList != null){
            for(QuoteLineItem qtln: qtlnList){
                if(quoteMap.get(qtln.QuoteId).Status == System.Label.Quote_Status_In_Review){
                    qtln.addError(System.Label.Quote_Status_In_Review_Add_Error_Message);
                }
            }
    	}
        if(qtlnOldList != null && qtlnList == null){
            for(QuoteLineItem qtlnold: qtlnOldList){
                if(quoteMap.get(qtlnold.QuoteId).Status == System.Label.Quote_Status_In_Review){
                    qtlnold.addError(System.Label.Quote_Status_In_Review_Delete_Error_Message);
                }
            }
        }
        
    }
}