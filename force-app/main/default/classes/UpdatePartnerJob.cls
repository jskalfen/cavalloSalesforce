global class UpdatePartnerJob implements Schedulable,Database.Batchable<sObject> {
global Database.QueryLocator start(Database.BatchableContext BC) {
    
    //To Run Monthly
    RecordType acctPartnerResellerRecordType = [Select ID,DeveloperName From RecordType where DeveloperName='Reseller_Partner' limit 1];
    ID recordType = acctPartnerResellerRecordType.Id;
    String query = 'Select ID,Name,(Select ID,Name From Partner_Margins2__r) From Account where RecordTypeId=:recordType Limit 200';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Account> partnerList) {
        Map<Id,Partner_Margin__c> partnerPMMap = new Map<Id,Partner_Margin__c>();
        try{
            for(Account partner:partnerList){
                for(Partner_Margin__c pm: partner.Partner_Margins2__r){
                    partnerPMMap.put(partner.Id,pm);
                } 
            }
            
            update partnerPMMap.values();
            
        }catch(Exception e) {
            System.debug(e.getMessage());
        }    
    }
    
    global void execute(SchedulableContext sc) {
        UpdatePartnerJob b = new UpdatePartnerJob(); 
        Database.executeBatch(b);
    }
    
    
    global void finish(Database.BatchableContext BC) {
        // execute any post-processing operations like sending email
    }

}