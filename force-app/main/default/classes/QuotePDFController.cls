// Controller for the custom Quote PDF generation
// 2018-01-13 Ray Dehler <rdehler@square2marketing.com> created
public with sharing class QuotePDFController {
    public Quote q {get; set;}
    public List<QuoteLineDiscount> lineDiscountList {get; set;}
    private Id quoteId;
    public String totalSoftwareSP {get; set;}
    public String totalSoftwareDiscount {get; set;}
    public String totalSoftwareSubtotal {get; set;}
    public String totalServiceSP {get; set;}
    public String totalServiceDiscount {get; set;}
    public String totalServiceSubtotal {get; set;}
    // public Double doubleTotalServiceSP {get; set;}
    // public Double doubleTotalServiceDiscount {get; set;}
    // public Double doubleSubTotalService {get; set;}
    // public Double doubleTotalSoftwareSP {get; set;}
    // public Double doubleTotalSoftwareDiscount {get; set;}
    // public Double doubleSubTotalSoftware {get; set;}
    
    public String today {
        get {
            return Date.today().format();
        }
    }
    public Map<String, OpportunityLineItem__mdt> mapQuoteLines1 {get; set;}
    public List<chargebeeapps__CB_Opportunity_Coupon__c> chargebeeProds {get; set;}
    Set<String> waterMarkSet = new Set<String>{'Draft','Needs Review','In Review','Rejected'};
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
    
    public String renderAs {
        get {
            if (!ApexPages.currentPage().getParameters().containsKey('renderAs')) {
                return 'pdf';
            } else {
                return ApexPages.currentPage().getParameters().get('renderAs');
            }
        }
    }
    
    public QuotePDFController(ApexPages.StandardController sc) {
        try {
            String businessLineProfessionalServices = System.Label.OppLine_BusinessLine_ProfessionalServices;
            quoteId = sc.getId();
            q = [
                SELECT 
                    Id, QuoteNumber, Name, Status, Discount, Lead_Time__c, TotalPrice, ExpirationDate, Total_Sales_Price__c,
                    Contact.Name, Account.Name, Account.BillingStreet, Account.BillingCity, Account.BillingState,
                    Account.BillingPostalCode, Account.BillingCountry, Account.Portal_Account_Id__c, Opportunity.Payment_Terms__c,
                    Opportunity.Owner.Name,Opportunity.chargebeeapps__Manual_Discount__c, Opportunity.RecordType.Name, 
                    Number_of_Quotes_Generated__c, Software_Subtotal__c, Consulting_Subtotal__c, Payment_Terms__c,
                    Total_Service_Discount__c, Total_Service_Sales_Price__c, Total_Service_Subtotal__c, Total_Software_Discount__c,
                    Total_Software_Sales_Price__c, Total_Software_Subtotal__c,
                    (
                        SELECT 
                            PricebookEntry.Product2.Name, PricebookEntry.Product2.ProductCode, PricebookEntry.Product2.Business_Line__c, 
                            Quantity, Discount, UnitPrice, Product2Id, TotalPrice, Comments__c, Discount_price__c, 
                            Discounted_Sales_Price__c, Extended_Price__c 
                        FROM QuoteLineItems 
                        WHERE Product2Id 
                        NOT IN :quoteLineItemsToBeSkipped
                        ORDER BY Line_Number__c nulls last, LineNumber
                    )
                FROM Quote
                WHERE Id = :quoteId
            ];
            lineDiscountList = QuoteTriggerHandler.getManualDiscount(q.Opportunity.chargebeeapps__Manual_Discount__c);
            chargebeeProds = [
                SELECT Id, Name,  chargebeeapps__CB_Coupon__c, chargebeeapps__CB_Coupon__r.Name, Discount__c 
                FROM chargebeeapps__CB_Opportunity_Coupon__c 
                WHERE chargebeeapps__Opportunity__c =: q.OpportunityId
            ];
            // doubleTotalServiceSP = 0.00;
            // doubleTotalServiceDiscount = 0.00;
            // doubleSubTotalService = 0.00;
            // doubleTotalSoftwareSP = 0.00;
            // doubleTotalSoftwareDiscount = 0.00;
            // doubleSubTotalSoftware = 0.00;
            // if(q.QuoteLineItems != null && q.QuoteLineItems.size()>0){
            //     for(QuoteLineItem qli: q.QuoteLineItems){
            //         if(qli.PricebookEntry.Product2.Business_Line__c != null && qli.PricebookEntry.Product2.Business_Line__c.equalsIgnoreCase(businessLineProfessionalServices)){
            //             doubleTotalServiceSP += qli.Extended_Price__c;
            //             doubleTotalServiceDiscount += qli.Discount_price__c;
            //         }else if(qli.PricebookEntry.Product2.Business_Line__c != null && (qli.PricebookEntry.Product2.Business_Line__c == 'GP' || qli.PricebookEntry.Product2.Business_Line__c == 'BC')){
            //             doubleTotalSoftwareSP += qli.Extended_Price__c;
            //             doubleTotalSoftwareDiscount += qli.Discount_price__c;
            //         }
            //     }
            // }
            // doubleSubTotalService = doubleTotalServiceSP+doubleTotalServiceDiscount;
            // doubleSubTotalSoftware = doubleTotalSoftwareSP+doubleTotalSoftwareDiscount;
            
            totalSoftwareSP = Utility_Class.currencyStringFormatter(q.Total_Software_Sales_Price__c);
            totalSoftwareDiscount = Utility_Class.currencyStringFormatter(q.Total_Software_Discount__c);
            totalSoftwareSubtotal = Utility_Class.currencyStringFormatter(q.Total_Software_Subtotal__c);
            totalServiceSP = Utility_Class.currencyStringFormatter(q.Total_Service_Sales_Price__c);
            totalServiceDiscount = Utility_Class.currencyStringFormatter(q.Total_Service_Discount__c);
            totalServiceSubtotal = Utility_Class.currencyStringFormatter(q.Total_Service_Subtotal__c);
        }
        catch(Exception e) {
            ApexPages.addMessages(e);
        }
    }
    
    
    public PageReference saveAndOpenPDF() {
        if (String.isBlank(ApexPages.currentPage().getParameters().get('displayOnly'))) {
            Id attachmentId = savePDF();
            return openPDF(attachmentId);
        } else {
            return null;
        }
    }
    
    public PageReference saveAndOpenPDFSubtotal() {
        if (String.isBlank(ApexPages.currentPage().getParameters().get('displayOnly'))) {
            Id attachmentId = savePDFSubtotal();
            return openPDF(attachmentId);
        } else {
            return null;
        }
    }
    
    public Id savePDF() {
        Attachment attachment = new Attachment();
        attachment.ParentId = quoteId;
        Integer versionNumber = getVersionNumber()+1;
        attachment.name = 'Quote_V'+versionNumber+'.pdf';
        PageReference pdf = Page.QuotePDF;
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
        
        updateVersionNumber(versionNumber);
        
        return attachment.Id;
    }
    
    public Id savePDFSubtotal() {
        Attachment attachment = new Attachment();
        attachment.ParentId = quoteId;
        Integer versionNumber = getVersionNumber()+1;
        attachment.name = 'Quote_V'+versionNumber+'.pdf';
        PageReference pdf = Page.QuotePDFSubtotal;
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
        
        updateVersionNumber(versionNumber);
        
        return attachment.Id;
    }
    
    private void updateVersionNumber(Integer newNumber) {
        Quote updatedQuote = new Quote(Id = q.Id, Number_of_Quotes_Generated__c = newNumber);
        try {
            update updatedQuote;
        } catch(Exception e) {
            ApexPages.addMessages(e);
        }
    }
    
    private Integer getVersionNumber() {
        return q.Number_of_Quotes_Generated__c  == null ? 0 : Integer.valueOf(q.Number_of_Quotes_Generated__c);
    }
    
    public PageReference openPDF(Id attachmentId) {
        PageReference ret = new PageReference('/servlet/servlet.FileDownload?file=' + attachmentId);
        ret.setRedirect(true);
        return ret;
    }
    
    public Boolean showWaterMark {
        get{
            return waterMarkSet.contains(q.Status);
        }
    }
    
}