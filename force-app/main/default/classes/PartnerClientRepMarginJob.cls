global class PartnerClientRepMarginJob implements Schedulable,Database.Batchable<sObject> {
    global Database.QueryLocator start(Database.BatchableContext BC) {
        //Needs to run Monthly
        Set<String> PMStatus = new Set<String>{'Approved for AP','Billed through Partner','Historical'};
        String PMType = 'Initial Purchase';
        Set<Integer> pmLast3YearSet = new Set<Integer>{System.today().year(),System.today().year()-1,System.today().year()-2};
        
        String query = 'Select ID,Name,Partner_Margin_Status__c,Partner__c,Client__c, '+
            '(Select ID,Name,Licensing__c,Perpetual_Type__c,Total_Price__c From Partner_Margin_Products__r) '+
            'From Partner_Margin__c where Partner_Margin_Status__c In:PMStatus AND Partner_Margin_Type__c =: PMType '+
            'AND CALENDAR_YEAR(CreatedDate) In: pmLast3YearSet';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Partner_Margin__c> pmList) {
        Set<Id> partnerIdSet = new Set<Id>();
        Map<String,Decimal> pmpTotalMap = new Map<String,Decimal>();
        for(Partner_Margin__c pm : pmList){
          String partnerClientKey = (String)pm.Partner__c+(String)pm.Client__c;
           partnerIdSet.add(pm.Partner__c);
            Decimal pmpTotal = 0.00;
           for(Partner_Margin_Product__c pmp: pm.Partner_Margin_Products__r){
                            if(pmp.Total_Price__c != null && (pmp.Licensing__c == 'Subscription' || pmp.Perpetual_Type__c == 'License')){
                                pmpTotal += pmp.Total_Price__c;
                            } 
                        }
            if(pmpTotalMap == null || !pmpTotalMap.containskey(partnerClientKey)){
            	pmpTotalMap.put(partnerClientKey,pmpTotal);
            }else{
               pmpTotalMap.put(partnerClientKey, pmpTotalMap.get(partnerClientKey)+pmpTotal);
            }
        } 
        
        List<Partner_Client_Relationship__c> partnerClientList = [Select ID,Name,Partner__c,Client__c,License_Sales_Last_3_Years__c From Partner_Client_Relationship__c 
                                                                 Where Partner__c In: partnerIdSet];
        
        try{
            if(partnerClientList != null && partnerClientList.size() > 0){
                for(Partner_Client_Relationship__c pcRep: partnerClientList){
                   String pcRepPartClientKey = (String)pcRep.Partner__c+(String)pcRep.Client__c;
                    if(pmpTotalMap.containsKey(pcRepPartClientKey)){
                   		pcRep.License_Sales_Last_3_Years__c = pmpTotalMap.get(pcRepPartClientKey);
                    }
                } 
                update partnerClientList;
            }
            
        }catch(Exception e) {
            System.debug(e.getMessage());
        }    
    }
    
    global void execute(SchedulableContext sc) {
        PartnerClientRepMarginJob b = new PartnerClientRepMarginJob(); 
        Database.executeBatch(b);
    }
    
    
    global void finish(Database.BatchableContext BC) {
        // execute any post-processing operations like sending email
    }
}