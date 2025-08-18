public without sharing class DuplicateContactFixBatch implements Database.Batchable<sObject>{

    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator('Select Id,Name from Contact where duplicate__c=false');
     }
   
     public void execute(Database.BatchableContext BC, List<sObject> contList){

        List<String> contNameList = new List<String>();
        for(Contact contObj : (List<Contact>)contList){
            contNameList.add(contObj.Name);
        }

        List<AggregateResult> contList1 =
            [
                SELECT count(id) ,name Name from Contact where duplicate__c = false AND Name IN: contNameList group by Name  having count(id) > 1 order by name desc
            ];
        List<String> contNames = new List<String>();
        for(AggregateResult contObj : contList1){
            contNames.add((String)contObj.get('Name'));
        }
        List<Contact> allContacts =
            [
                SELECT Id,Name,Duplicate__c FROM Contact  WHERE Name IN:contNames  ORDER BY Name
            ];
        for(Contact contObj : allContacts){
            contObj.Duplicate__c = true;
        }
        Database.update(allContacts,false) ;
     }
     public void finish(Database.BatchableContext BC){}
}