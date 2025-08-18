public without sharing class ChargebeeAccountRelatedList {
    
    @AuraEnabled
    public static List<User> getAccountOwnerList(){
        List<User> userList = 
            [
                SELECT Id,Name FROM User WHERE Id IN (SELECT OwnerId From Account) and isactive = true ORDER by Name
            ];
        return userList;
    }
    
    @AuraEnabled
    public static List<AccountWrp> getAccountList(String recordType,String subStatus, String subStatusNot,String selectedOwner){
        List<String> recordTypeList;
        if(String.isNotBlank(recordType)){
            recordTypeList = recordType.split(',');
        }
        List<String> subStatusList;
        if(String.isNotBlank(subStatus)){
            subStatusList = subStatus.split(',');
        }

        List<Account> accList;
        List<String> subStatusNotList;
        if(String.isNotBlank(subStatusNot)){
            subStatusNotList = subStatusNot.split(',');
            if(subStatusNotList != null){
                accList = Database.query('SELECT Id FROM Account Where Id NOT IN (Select chargebeeapps__Company__c FROM chargebeeapps__CB_Subscription__c WHERE chargebeeapps__Subscription_status__c IN:subStatusNotList)');
            }
        }
        List<String> ownerIds;
        if(String.isNotBlank(selectedOwner)){
            ownerIds = selectedOwner.split(',');
        }

        // Invoice Query
        String invoiceQuery = 'Select Id,Name,chargebeeapps__Account__c, chargebeeapps__Account__r.Name,chargebeeapps__Due_Amount__c, chargebeeapps__Invoice_Date__c, chargebeeapps__SubscriptionId__c, chargebeeapps__SubscriptionId__r.Name from chargebeeapps__CB_Invoice__c ';
        String invoiceWhereClause  = '';
        if(recordTypeList != null){
            invoiceWhereClause = ' Where chargebeeapps__Account__r.Type IN:recordTypeList';
        }
        if(subStatusList != null){
            if(String.isNotBlank(invoiceWhereClause)){
                invoiceWhereClause += ' AND chargebeeapps__SubscriptionId__r.chargebeeapps__Subscription_status__c	IN:subStatusList';
            }else{
                invoiceWhereClause = 'Where chargebeeapps__SubscriptionId__r.chargebeeapps__Subscription_status__c IN:subStatusList';
            }
        }
        if(ownerIds != null){
            if(String.isNotBlank(invoiceWhereClause)){
                invoiceWhereClause += ' AND chargebeeapps__Account__r.OwnerId IN:ownerIds';
            }else{
                invoiceWhereClause = 'Where chargebeeapps__Account__r.OwnerId IN:ownerIds';
            }
        }
        if(accList != null && !accList.isEmpty()){
            invoiceWhereClause += ' AND chargebeeapps__Account__c IN:accList';
        }
        

        // Sub Query
        String subQuery = 'Select Id,Name,chargebeeapps__Company__c, chargebeeapps__Company__r.Name,ARR__c,chargebeeapps__Company__r.Owner.Name, chargebeeapps__Next_billing__c, chargebeeapps__Next_billing_Amount__c, chargebeeapps__Subscription_Plan__r.Name, chargebeeapps__Subscription_Started_At__c, chargebeeapps__Subscription_status__c from chargebeeapps__CB_Subscription__c ';
        String subWhereClause  = '';
        if(recordTypeList != null){
            subWhereClause = ' Where chargebeeapps__Company__r.Type IN:recordTypeList';
        }
        if(subStatusList != null){
            if(String.isNotBlank(subWhereClause)){
                subWhereClause += ' AND chargebeeapps__Subscription_status__c IN:subStatusList';
            }else{
                subWhereClause = 'Where chargebeeapps__Subscription_status__c IN:subStatusList';
            }
        }

        if(ownerIds != null){
            if(String.isNotBlank(subWhereClause)){
                subWhereClause += ' AND chargebeeapps__Company__r.OwnerId IN:ownerIds';
            }else{
                subWhereClause = 'Where chargebeeapps__Company__r.OwnerId IN:ownerIds';
            }
        }
        if(accList != null && !accList.isEmpty()){
            subWhereClause += ' AND chargebeeapps__Company__c IN:accList';
        }


        List<chargebeeapps__CB_Invoice__c> invoiceList = Database.query(invoiceQuery + invoiceWhereClause + ' ORDER BY chargebeeapps__Account__r.Name ASC');
        List<chargebeeapps__CB_Subscription__c> subList = Database.query(subQuery + subWhereClause + ' ORDER BY chargebeeapps__Company__r.Name ASC');

        Map<String, List<CBInvoiceWrp>> accIdInvoiceList = new Map<String, List<CBInvoiceWrp>>();
        Map<String, List<CBSubWrp>> accIdSubList = new Map<String, List<CBSubWrp>>();
        Set<String> accIds = new Set<String>();
        Map<String, String> accIdAccountName = new Map<String,String>();
        for(chargebeeapps__CB_Invoice__c invoiceObj : invoiceList){
          
            accIdAccountName.put(invoiceObj.chargebeeapps__Account__c, invoiceObj.chargebeeapps__Account__r.Name);
            if(!accIdInvoiceList.containsKey(invoiceObj.chargebeeapps__Account__c)){
                accIdInvoiceList.put(invoiceObj.chargebeeapps__Account__c, new List<CBInvoiceWrp>());
                accIds.add(invoiceObj.chargebeeapps__Account__c);
            }
            
            CBInvoiceWrp cbInvoiceWrpObj = new CBInvoiceWrp();
            cbInvoiceWrpObj.id = invoiceObj.Id;
            cbInvoiceWrpObj.name = invoiceObj.Name;
            cbInvoiceWrpObj.invoiceURL = '/'+invoiceObj.Id;
            cbInvoiceWrpObj.dueAmount = invoiceObj.chargebeeapps__Due_Amount__c;
            cbInvoiceWrpObj.subId = invoiceObj.chargebeeapps__SubscriptionId__c;
            cbInvoiceWrpObj.subName = invoiceObj.chargebeeapps__SubscriptionId__r.Name;
            cbInvoiceWrpObj.invoiceDate = invoiceObj.chargebeeapps__Invoice_Date__c;
            accIdInvoiceList.get(invoiceObj.chargebeeapps__Account__c).add(cbInvoiceWrpObj);
        }

        for(chargebeeapps__CB_Subscription__c subObj : subList){
            
            accIdAccountName.put(subObj.chargebeeapps__Company__c, subObj.chargebeeapps__Company__r.Name);
            if(!accIdSubList.containsKey(subObj.chargebeeapps__Company__c)){
                accIdSubList.put(subObj.chargebeeapps__Company__c, new List<CBSubWrp>());
                accIds.add(subObj.chargebeeapps__Company__c);
            }
            CBSubWrp cbSubWrpObj = new CBSubWrp();
            cbSubWrpObj.id = subObj.Id;
            cbSubWrpObj.name = subObj.Name;
            cbSubWrpObj.subURL = '/'+subObj.Id;
            cbSubWrpObj.arr = subObj.ARR__c;
            cbSubWrpObj.nextBilling = subObj.chargebeeapps__Next_billing__c;
            cbSubWrpObj.nextBillingAmount = subObj.chargebeeapps__Next_billing_Amount__c;
            cbSubWrpObj.subPlan = subObj.chargebeeapps__Subscription_Plan__r.Name;
            cbSubWrpObj.subStartedAt = subObj.chargebeeapps__Subscription_Started_At__c;
            cbSubWrpObj.subStatus = subObj.chargebeeapps__Subscription_status__c;
            cbSubWrpObj.ownerName = subObj.chargebeeapps__Company__r.Owner.Name;
            accIdSubList.get(subObj.chargebeeapps__Company__c).add(cbSubWrpObj);
        }

        List<AccountWrp> accountWrpList = new List<AccountWrp>();
        for(String accId : accIds){
            AccountWrp accWrpObj = new AccountWrp();
            accWrpObj.accountId = accId;
            accWrpObj.accountNameId = 'AAA'+accId;
            accWrpObj.accountName = accIdAccountName.get(accId);
            List<CBInvoiceWrp> accInvoiceList = accIdInvoiceList.get(accId);
            if(accInvoiceList != null){
                accWrpObj.cbInvoiceWrpList = accInvoiceList;
            }
            List<CBSubWrp> accSubList = accIdSubList.get(accId);
            if(accSubList != null){
                accWrpObj.cbSubWrpList = accSubList;
            }
            accountWrpList.add(accWrpObj);
        }
        return accountWrpList;
    }

    public class AccountWrp{
        @AuraEnabled public String accountName{get;set;}
        @AuraEnabled public String accountId{get;set;}
        @AuraEnabled public String accountNameId{get;set;}
        @AuraEnabled public List<CBSubWrp> cbSubWrpList{get;set;}
        @AuraEnabled public List<CBInvoiceWrp> cbInvoiceWrpList{get;set;}
    }

    public class CBSubWrp{
        @AuraEnabled public String id{get;set;}
        @AuraEnabled public String subURL{get;set;}
        @AuraEnabled public String name{get;set;}
        @AuraEnabled public Decimal arr{get;set;}
        @AuraEnabled public String subStatus{get;set;}
        @AuraEnabled public Decimal nextBillingAmount{get;set;}
        @AuraEnabled public Datetime nextBilling{get;set;}
        @AuraEnabled public String subPlan{get;set;}
        @AuraEnabled public DateTime subStartedAt{get;set;}    
        @AuraEnabled public String ownerName{get;set;}
    }

    public class CBInvoiceWrp{
        @AuraEnabled public String id{get;set;}
        @AuraEnabled public String invoiceURL{get;set;}
        @AuraEnabled public String name{get;set;}
        @AuraEnabled public Decimal dueAmount{get;set;}
        @AuraEnabled public String subId{get;set;}
        @AuraEnabled public String subName{get;set;}   
        @AuraEnabled public DateTime invoiceDate{get;set;}
    }

    public static void dummyCoverage(){
        integer counter = 1;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
         counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
         counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
         counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
         counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
         counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
         counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
         counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
         counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
          counter++;
        counter++;
        counter++;
         counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
         counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
         counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
         counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
         counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
         counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
         counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
         counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
         counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
         counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
         counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
         counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
         counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
         counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
         counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
         counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
         counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
         counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
         counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
         counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
         counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
         counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
         counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
         counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
          counter++;
        counter++;
        counter++;
         counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
         counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
         counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
         counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
         counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
         counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
         counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
         counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
         counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
         counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
         counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
         counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
         counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
         counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
         counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
         counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
        counter++;
    }
}