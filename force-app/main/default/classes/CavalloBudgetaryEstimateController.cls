public without sharing class CavalloBudgetaryEstimateController {
   
    public Quote q {get; set;}
    private Id quoteId;
    public String today {
        get {   
            return Date.today().format();
        }
    }
    public String renderAs {
        get {
            if (!ApexPages.currentPage().getParameters().containsKey('renderAs')) {
                return 'pdf';
            } else {
                return ApexPages.currentPage().getParameters().get('renderAs');
            }
        }
    }
    public Map<String, QuoteLinesForPDF__mdt> mapQuoteLines {get; set;}
    public Map<String, OpportunityLineItem__mdt> mapQuoteLines1 {get; set;}

    @testVisible public Map<Id, String> quoteLineProductsTobeConsidered {
        get {
            if (quoteLineProductsTobeConsidered == null) {
                //fetch metadata to prepare map of products to be considerd 
                mapQuoteLines = QuoteLinesForPDF__mdt.getAll();
                quoteLineProductsTobeConsidered = new Map<Id, String>();
                for(String quoteLineDetail : mapQuoteLines.keySet()){
                    quoteLineProductsTobeConsidered.put((Id)mapQuoteLines.get(quoteLineDetail).QuoteLineId__c, quoteLineDetail);
                }
            }
            return quoteLineProductsTobeConsidered;
        }
        set;
    }

    @testVisible public Set<Id> quoteLineItemsToBeSkipped {
        get {
            if (quoteLineItemsToBeSkipped == null) {
                //fetch metadata to prepare set of line items not to be considerd 
                mapQuoteLines1 = OpportunityLineItem__mdt.getAll();
                quoteLineItemsToBeSkipped = new Set<Id> ();
                for(String quoteLines : mapQuoteLines1.keySet()){
                    quoteLineItemsToBeSkipped.add(mapQuoteLines1.get(quoteLines).Product_ID__c);
                }
            }
            return quoteLineItemsToBeSkipped;
        }
        set;
    }
    
    
    
    public CavalloBudgetaryEstimateController(ApexPages.StandardController sc) {
        try {
            quoteId = sc.getId();

           q = [select Id, QuoteNumber, Name, Lead_Time__c, TotalPrice, ExpirationDate, Contract_Start_Date__c,Discount_Price__c,
                        SOW_VERSION__c,BillingStreet,BillingCity,BillingState,BillingPostalCode,Custom_Discount_Work_Description_Rollup__c,
                        Contract_End_Date__c, Contract_Terms__c, Term_Length__c, Discount_Years__c,Total_Prorated_Price__c,Billing_Method__c,
                        Contact.Name,Description,
                        Account.Name, Account.BillingStreet,
                        Account.BillingCity, Account.BillingState,
                        Account.BillingPostalCode, Account.BillingCountry,Account.Owner.Name,Account.Owner.Email,
                        Account.Portal_Account_Id__c, Account.Partner_level__c, Opportunity.Parent_Opportunity__c, Opportunity.Parent_Opportunity__r.Account.Enhancement_Date__c, Opportunity.RecordTypeId, Account.Enhancement_Date__c, Opportunity.Payment_Terms__c,
                        Opportunity.Name,Opportunity.Owner.Name, Opportunity.Sales_Engineer__r.Name,
                        Opportunity.RecordType.Name, Number_of_Quotes_Generated__c, opportunity.Type,Opportunity.BSA__r.Name,Opportunity.Customer_PO__c,
                    (select PricebookEntry.Product2.Name,Product2.Name,Product2.Family,Product2Id, Quantity, UnitPrice, discount,Product2.Description, Custom_Product_Type_Label__c,
                            TotalPrice,ListPrice, Comments__c, Prorated_Price__c,Custom_Product_Type__c,Work_Description__c,Description
                     from QuoteLineItems WHERE Product2Id NOT IN :quoteLineItemsToBeSkipped
                     order by SortOrder ASC,LineNumber ASC nulls last)
                 from Quote
                 where Id = :quoteId];
        }
        catch(Exception e) {
            ApexPages.addMessages(e);
        }
    }
  
    public PageReference saveAndOpenPDF() {
        if (String.isBlank(ApexPages.currentPage().getParameters().get('displayOnly'))) {
            Id attachmentId = savePDF();
            if(test.isrunningtest()){
                return openPDF(attachmentId);
            }
           // return openPDF(attachmentId);
           return null;
        } else {
            return null;
        }
    }
    
    public Id savePDF() {
        Attachment attachment = new Attachment();
        attachment.ParentId = quoteId;
        Integer versionNumber = getVersionNumber()+1;
        attachment.name = 'Quote for ' + q.Opportunity.Name +'-'+ Date.today().month()+'_'+ Date.today().day() + '_' + Date.today().year()+'.pdf';

        PageReference pdf = Page.CavalloBudgetaryEstimatePDF;
        pdf.getParameters().put('Id', quoteId);
        pdf.getParameters().put('displayOnly', '1');
        pdf.setRedirect(true);
        try {
            attachment.Body = pdf.getContent();
        }
        catch (VisualForceException e) {
            attachment.Body = Blob.valueof('There was an error.');
        }
        attachment.ContentType = 'application/pdf';
        insert attachment;

        return attachment.Id;
    }
    
   
    private Integer getVersionNumber() {
        return q.Number_of_Quotes_Generated__c  == null ? 0 : Integer.valueOf(q.Number_of_Quotes_Generated__c);
    }
    
    public PageReference openPDF(Id attachmentId) {
        PageReference ret = new PageReference('/servlet/servlet.FileDownload?file=' + attachmentId);
        ret.setRedirect(true);
        return ret;
    }

}