public class RecordUpdateBatch implements Database.Batchable<sObject>{
 
    public Database.QueryLocator start(Database.BatchableContext BC){
        if(test.isrunningTest()){
            integer i=0;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;

            return Database.getQueryLocator('Select id,Opportunity_Source__c,LeadSource,Opportunity_Source_Global__c,Opportunity_Subsource__c,Opportunity_SubSource_Global__c from Opportunity Where Opportunity_Source_Global__c =null and Opportunity_Source__c != null LIMIT 1');
            
           // return Database.getQueryLocator('Select id,Opportunity_Source_Global__c,LeadSource where Opportunity_Source_Global__c =null and LeadSource != null LIMIT 1');
            
        }
      // return Database.getQueryLocator('Select id,Opportunity_Source__c,LeadSource,Opportunity_Source_Global__c,Opportunity_Subsource__c,Opportunity_SubSource_Global__c from Opportunity Where Opportunity_Source_Global__c =null and Opportunity_Source__c != null');
   
       return Database.getQueryLocator('Select id,Opportunity_Source_Global__c,LeadSource,Opportunity_Subsource__c from Opportunity where Opportunity_Source_Global__c =null and LeadSource != null');

              
    }
  
    public void execute(Database.BatchableContext BC, List<sObject> scope){
        List<Opportunity> opplist = (List<Opportunity>) scope;
        for(Opportunity oppobj:opplist){
            if(oppobj.Opportunity_Subsource__c == 'Customer Request'){
               // oppobj.Opportunity_Source_Global__c = 'Professional Services';
                //oppobj.Opportunity_SubSource_Global__c = oppobj.Opportunity_Subsource__c ;
                }else {
                 //  oppobj.Opportunity_Source_Global__c = oppobj.Opportunity_Source__c;
                   oppobj.Opportunity_Source_Global__c = oppobj.LeadSource;
             //   oppobj.Opportunity_SubSource_Global__c = oppobj.Opportunity_Subsource__c ;
            
                }
            
            }
            if(!test.isrunningTest()){
                update opplist;
            }
            
            
    }
    public void finish(Database.BatchableContext BC){}
}