// Controller for the custom Quote PDF generation
// 2018-01-13 Ray Dehler <rdehler@square2marketing.com> created
public with sharing class QuotePDFController2 {
    public string subscriptionProduct = 'Desktop_Subscription';
    public string newprodFamily = 'SALESPAD_SUBSCRIPTION';
    public string newprodFamilyIntelligence = 'INTELLIGENCE';
    public String newBusiness = 'New Business';
    public String newLogo = 'New Logo';
    public String existingBusiness = 'Existing Business';
    public String expansion = 'Expansion';
    public List<QuoteLineItem> updateQuoteLines = new List<QuoteLineItem>();
    public Map<String, QuoteLinesForPDF__mdt> mapQuoteLines {get; set;}
    public Map<String, OpportunityLineItem__mdt> mapQuoteLines1 {get; set;}
    public Quote q {get; set;}
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
    public List<QuoteLineDiscount> lineDiscountList {get; set;}
    private Id quoteId;
    public String subscriptionQuoteLine {get; set;}
    Set<String> waterMarkSet = new Set<String>{'Draft','Needs Review','In Review','Rejected'};
    public String today {
        get {   
            return Date.today().format();
        }
    }

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
    
    public Id newBusinessRecTypeId {get; set;}
    public Map<Id,Decimal> subscriptionProductsListPriceMap {get; set;}
    public Map<Id,Decimal> standardProductListPriceMap{get; set;}
    public Map<Id, String> lineDescriptionMap {get;set;}
    public Boolean hasDiscount {get; set;}
    public Map<Id, Decimal> subscriptionProductsDiscountPriceMap;
    public Map<Id,Decimal> standardProductDiscountPriceMap;
    public String renderAs {
        get {
            if (!ApexPages.currentPage().getParameters().containsKey('renderAs')) {
                return 'pdf';
            } else {
                return ApexPages.currentPage().getParameters().get('renderAs');
            }
        }
    }
   public List<quotePricesPerYear> quotePricesForContractTerms{get;set;}
    
    public class quotePricesPerYear {
        public Date startDate{get;set;}
        public Date endDate{get;set;}
        public Decimal price{get;set;}
        public Decimal varPrice{get;set;}
        public Decimal discountPercentage{get;set;}
        
        public quotePricesPerYear(Date startDate, Date endDate, Decimal price, Decimal varPrice, Decimal discountPercentage) {
            this.startDate = startDate;
            this.endDate = endDate;
            this.price = price;
            this.varPrice = varPrice;
            this.discountPercentage = discountPercentage;
        }
    }
    
    public QuotePDFController2(ApexPages.StandardController sc) {
        try {
            String businessLineProfessionalServices = System.Label.OppLine_BusinessLine_ProfessionalServices;
            newBusinessRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('New_Business').getRecordTypeId();
            quoteId = sc.getId();
            hasDiscount = false;

            q = [
                SELECT 
                    Id, QuoteNumber, Name,Discount, Status, Lead_Time__c, Total_Sales_Price__c, TotalPrice, Subtotal, 
                    ExpirationDate, Contract_Start_Date__c, Contract_End_Date__c, Contract_Terms__c, Term_Length__c,
                    Discount_Years__c, Total_Prorated_Price__c, Contact.Name, Account.Name, Account.BillingStreet,
                    Account.BillingCity, Account.BillingState, Account.BillingPostalCode, Account.BillingCountry,
                    Account.Portal_Account_Id__c, Account.Partner_level__c,Opportunity.Account.Enhancement_Date__c, 
                    Opportunity.Parent_Opportunity__c, Opportunity.Parent_Opportunity__r.Account.Enhancement_Date__c, 
                    Opportunity.RecordTypeId, Account.Enhancement_Date__c, Opportunity.Payment_Terms__c,
                    Opportunity.Owner.Name,Opportunity.chargebeeapps__Manual_Discount__c, Opportunity.RecordType.Name, 
                    Number_of_Quotes_Generated__c, opportunity.Type, Total_Service_Discount__c, Total_Service_Sales_Price__c, 
                    Total_Service_Subtotal__c, Total_Software_Discount__c, Total_Software_Sales_Price__c, 
                    Total_Software_Subtotal__c,
                    (
                        SELECT 
                            PricebookEntry.Product2.Name,PricebookEntry.Product2.Business_Line__c,PricebookEntry.Product2.ProductCode,
                            Product2.Family,Product2Id,Subtotal,Discounted_Sales_Price__c,Extended_Price__c,
                            Quantity, UnitPrice,Discount_price__c, Discount,TotalPrice,ListPrice, Comments__c, Prorated_Price__c
                        FROM QuoteLineItems 
                        WHERE Product2Id 
                        NOT IN :quoteLineItemsToBeSkipped
                        ORDER BY Line_Number__c nulls last, LineNumber
                    )
                FROM Quote
                WHERE Id = :quoteId
                ];
                lineDiscountList = QuoteTriggerHandler.getManualDiscount(q.Opportunity.chargebeeapps__Manual_Discount__c);
                subscriptionProductsListPriceMap = new Map<Id, Decimal>();
                standardProductListPriceMap = new Map<Id, Decimal>();
                subscriptionProductsDiscountPriceMap = new Map<Id, Decimal>();
                standardProductDiscountPriceMap =new Map<Id, Decimal>();
                populateLineDescription();
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
  public void populateLineDescription() {
        lineDescriptionMap = new Map<Id, String>();
        newBusinessRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('New_Business').getRecordTypeId();
        //partnetOppRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Reseller').getRecordTypeId();
        
        Set<Id> quoteLineProducts = new Set<Id>();
        Decimal discountPercFromProd = 0;
        for (QuoteLineItem quoteLine : q.QuoteLineItems) {
            if (q.Opportunity.RecordTypeId == newBusinessRecTypeId) {
                quoteLineProducts.add(quoteLine.Product2Id);
                if (hasDiscount == false && quoteLine.discount != null && quoteLine.discount > 0) {
                    hasDiscount = true;    
                }
                quoteLine.Prorated_Price__c = quoteLine.TotalPrice;
                if ((q.opportunity.Type == existingBusiness || q.opportunity.Type.contains(expansion)) && (quoteLine.Product2.Family != null && (quoteLine.Product2.Family.containsIgnoreCase(subscriptionProduct) 
                            || quoteLine.Product2.Family.containsIgnoreCase(newprodFamily) || quoteLine.Product2.Family.containsIgnoreCase(newprodFamilyIntelligence)))) {
                    quoteLine.Prorated_Price__c = q.Contract_Terms__c > 0 ?  (quoteLine.TotalPrice / 365) * q.Contract_Terms__c :  quoteLine.TotalPrice;        
                }
                updateQuoteLines.add(quoteLine);
            }
        }
        Map<Id, Product2> productMap = new Map<Id, Product2>([SELECT Id, Name, ProductCode, (SELECT Id, Product2Id, Product2.Name,UnitPrice, Pricebook2.Name FROM PricebookEntries) FROM Product2 where Id IN :quoteLineProducts]);
        
        //loop through all quote line items to calculate List price of all quote line items in a quote based on opportunity record type
        for (QuoteLineItem quoteLine : q.QuoteLineItems) {
            if (q.Opportunity.RecordTypeId == newBusinessRecTypeId) {
                quoteLineProducts.add(quoteLine.Product2Id);
                if (quoteLineProductsTobeConsidered.containsKey(quoteLine.Product2Id)) {
                    system.debug('subscriptionProductsListPriceMap========='+subscriptionProductsListPriceMap);
                    if (quoteLine.Product2.Family.containsIgnoreCase(subscriptionProduct) 
                                || quoteLine.Product2.Family.containsIgnoreCase(newprodFamily) || quoteLine.Product2.Family.containsIgnoreCase(newprodFamilyIntelligence))   {
                        
                        if ((q.Discount_Years__c != null && q.Discount_Years__c.containsIgnoreCase('3')) || q.Discount_Years__c == null) {
                            if (subscriptionProductsListPriceMap != null && subscriptionProductsListPriceMap.containsKey(q.Id)) {
                                Decimal price  = subscriptionProductsListPriceMap.get(q.Id) + (quoteLine.TotalPrice) ;
                                subscriptionProductsListPriceMap.put(q.Id, price);
                            } else {
                                subscriptionProductsListPriceMap.put(q.Id, (quoteLine.TotalPrice));
                            }
                        } else {
                            if (subscriptionProductsListPriceMap != null && subscriptionProductsListPriceMap.containsKey(q.Id)) {
                                Decimal price  = subscriptionProductsListPriceMap.get(q.Id) + (quoteLine.ListPrice * quoteLine.Quantity) ;
                                subscriptionProductsListPriceMap.put(q.Id, price);
                            } else {
                                subscriptionProductsListPriceMap.put(q.Id, (quoteLine.ListPrice * quoteLine.Quantity));
                            }

                            if (q.Discount_Years__c.containsIgnoreCase('1') || q.Discount_Years__c.containsIgnoreCase('2') ) {
                                if (subscriptionProductsDiscountPriceMap.containsKey(q.Id)) {
                                    Decimal price  = subscriptionProductsDiscountPriceMap.get(q.Id) + (quoteLine.TotalPrice) ;
                                    subscriptionProductsDiscountPriceMap.put(q.Id, price);
                                } else {
                                    subscriptionProductsDiscountPriceMap.put(q.Id, quoteLine.TotalPrice);
                                }
                            }
                        }
                        
                    }
                }
            }    
        }
        
        
        
        if (q.Term_Length__c >= 1 && (q.Opportunity.RecordTypeId == newBusinessRecTypeId)) {
                quotePricesForContractTerms = new List<quotePricesPerYear>();
                if (subscriptionProductsListPriceMap != null && subscriptionProductsListPriceMap.containsKey(q.Id)) {
                    Date contractDate =  q.Contract_Start_Date__c != null ? q.Contract_Start_Date__c : Date.Today();
                    Date enhancementDate = q.Account.Enhancement_Date__c !=null ?  q.Account.Enhancement_Date__c : q.Contract_End_Date__c;
                    Decimal price =  subscriptionProductsListPriceMap.get(q.Id);
                    Decimal proratedListPrice = price > 0 ? ((price / 365)*q.Contract_Terms__c) : 0;
                    Decimal allItemsDiscountPrice = subscriptionProductsDiscountPriceMap.containsKey(q.Id) ? subscriptionProductsDiscountPriceMap.get(q.Id) : 0 ;
                    Decimal allItemsProuductDiscountPrice = 0;           
                    Decimal endListPrice = 0;
                    Decimal proratedEndListPrice = 0;
                
                    for (Integer i = 0; i < q.Term_Length__c; i++) {
                        quotePricesPerYear pricePerYear;
                        Decimal discountPercentage = 0;
                        if (String.isNotBlank(q.Account.Partner_level__c) && q.Account.Partner_level__c.containsIgnoreCase('Gold')) {
                            if ( i == 0) 
                                discountPercentage = 40;
                            else
                                discountPercentage = 30;
                        } else if (String.isNotBlank(q.Account.Partner_level__c) && q.Account.Partner_level__c.containsIgnoreCase('Silver')) {
                            if ( i == 0) 
                                discountPercentage = 30;
                            else
                                discountPercentage = 20;
                        } else if (String.isNotBlank(q.Account.Partner_level__c) && q.Account.Partner_level__c.containsIgnoreCase('Bronze')) {
                            discountPercentage = 20;
                        } else {
                            discountPercentage = 0;    
                        }
                        
                        if (i == 0) {
                            Decimal discountPrice = (q.opportunity.Type == newBusiness || q.opportunity.Type == newLogo) ? price : proratedListPrice;
                            Decimal productDiscountPrice = q.Opportunity.RecordTypeId == newBusinessRecTypeId ? 0 : proratedEndListPrice;
                            if ((q.opportunity.Type == newBusiness || q.opportunity.Type == newLogo) && q.Opportunity.RecordTypeId == newBusinessRecTypeId) {
                                productDiscountPrice = endListPrice;   
                            }
                            if (q.Discount_Years__c != null && !String.isBlank(q.Discount_Years__c) && (q.Discount_Years__c.containsIgnoreCase('1') || q.Discount_Years__c.containsIgnoreCase('2'))) {
                                productDiscountPrice = q.Opportunity.RecordTypeId == newBusinessRecTypeId ? 0 : allItemsProuductDiscountPrice;
                                if (q.opportunity.Type == newBusiness || q.opportunity.Type == newLogo) {
                                    discountPrice = allItemsDiscountPrice;
                                    productDiscountPrice = productDiscountPrice;
                                } else {
                                    discountPrice =  allItemsDiscountPrice > 0 ? ((allItemsDiscountPrice / 365) * q.Contract_Terms__c) : 0;
                                    productDiscountPrice =  productDiscountPrice > 0 ? ((productDiscountPrice / 365) * q.Contract_Terms__c) : 0; 
                                }
                                
                            } 
                            if (q.Opportunity.RecordTypeId == newBusinessRecTypeId) {
                                pricePerYear = new quotePricesPerYear(contractDate, enhancementDate, discountPrice.setScale(2), discountPrice.setScale(2), discountPercentage);
                            } else {
                                pricePerYear = new quotePricesPerYear(contractDate, enhancementDate, productDiscountPrice.setScale(2), discountPrice.setScale(2), discountPercentage);
                            }
                        } else {
                            Date startDate = enhancementDate.addYears(i-1);
                            startDate = startDate.addDays(1);
                            Decimal discountPrice = price;
                            Decimal productDiscountPrice = q.Opportunity.RecordTypeId == newBusinessRecTypeId ? 0 : endListPrice;
                            

                            if (q.Discount_Years__c != null && !String.isBlank(q.Discount_Years__c)) {
                                if ((q.Discount_Years__c.contains('2') && i == 1)) {
                                    discountPrice = allItemsDiscountPrice;
                                    productDiscountPrice = q.Opportunity.RecordTypeId == newBusinessRecTypeId ? 0 : allItemsProuductDiscountPrice;
                                } 
                            }

                            if (q.Opportunity.RecordTypeId == newBusinessRecTypeId) {
                                pricePerYear = new quotePricesPerYear(startDate , enhancementDate.addYears(i), discountPrice.setScale(2), discountPrice.setScale(2), discountPercentage);
                            }
                            else {
                                Decimal varPrice = discountPercentage > 0 ? (productDiscountPrice * (100 - discountPercentage))/100 : productDiscountPrice;
                                pricePerYear = new quotePricesPerYear(startDate , enhancementDate.addYears(i), productDiscountPrice.setScale(2), varPrice.setScale(2), discountPercentage);
                            }
                        }
                        system.debug('pricePerYear======='+pricePerYear);
                        quotePricesForContractTerms.add(pricePerYear);
                    }
                }
            }
    }
    
    // public List<String> prepareDirectLineParameters(QuoteLineItem quoteLine, Quote q) {
        
    //     List<String> parameters = new List<String>();
    //     if (q.opportunity.Type == existingBuisness) {
    //         Date contractDate =  q.Contract_Start_Date__c != null ? q.Contract_Start_Date__c : Date.Today();
    //         Date enhancementDate = q.Opportunity.Account.Enhancement_Date__c; 
    //         Decimal proratedListPrice = 0.00;
    //             if(quoteLine.TotalPrice != null){
    //                 proratedListPrice = quoteLine.TotalPrice / 365;
    //             }
    //         parameters.add(contractDate.month() + '/' + contractDate.day() + '/' + contractDate.year());   
    //         parameters.add( enhancementDate.month() + '/' + enhancementDate.day() + '/' + enhancementDate.year() );

    //         if (proratedListPrice > 0 && q.Contract_Terms__c > 0) {
    //             parameters.add('$ ' + String.valueOf((proratedListPrice * q.Contract_Terms__c).setScale(2)) + ' USD');
    //         }
    //         else
    //             parameters.add('0');
    //     } else if (q.opportunity.Type == newBuisness) {
    //         Decimal listPrice = quoteLine.TotalPrice;
    //         parameters.add('$ ' + String.valueOf(listPrice.setScale(2)) + ' USD');
    //     }
    //     system.debug('DirectLineParameters========='+parameters);
    //     return parameters;
    // }
    
//    public List<String> preparePartnerLineParameters(QuoteLineItem quoteLine, Quote q, Map<Id, Product2> productMap) {
//         List<String> parameters = new List<String>();
//         Decimal standardPrice = 0;
//         Decimal partnerPrice = 0;
//         if (productMap.containskey(quoteLine.Product2Id) ) {
//             for(PricebookEntry pb : productMap.get(quoteLine.Product2Id).PricebookEntries) {
//                 if (pb.Pricebook2.Name == 'Standard Price Book') {
//                     standardPrice = pb.unitPrice;
//                     continue;  
//                 }
//                 if(String.isNotBlank(q.Account.Partner_level__c) && pb.Pricebook2.Name.containsIgnoreCase(q.Account.Partner_level__c)) {
//                     partnerPrice = pb.unitPrice;
//                     continue;
//                 }
//             }
//         }
//         if (q.opportunity.Type == existingBuisness) {
//             Date contractDate =  q.Contract_Start_Date__c != null ? q.Contract_Start_Date__c : Date.Today();
//             Date enhancementDate = q.Opportunity.Account.Enhancement_Date__c;
//             Decimal endListPrice = 0.00;
//             if(quoteLine.ListPrice != null && quoteLine.ListPrice > 0){
//             	endListPrice = quoteLine.ListPrice * quoteLine.Quantity;
//             }
        
//             parameters.add(contractDate.month() + '/' + contractDate.day() + '/' + contractDate.year());  
//             parameters.add( enhancementDate.month() + '/' + enhancementDate.day() + '/' + enhancementDate.year() );
            
//             Decimal proratedListPrice;
            
//             if (standardPrice > 0 && q.Contract_Terms__c > 0) {
//                 proratedListPrice = (((standardPrice * quoteLine.Quantity)/ 365) * q.Contract_Terms__c).setScale(2);
//                 if (quoteLine.Discount > 0 && proratedListPrice > 0) {
//                     proratedListPrice = (proratedListPrice * (100 - quoteLine.Discount)) / 100;    
//                 } 
//             } else {
//                 proratedListPrice = 0;
//             }
//             Decimal endCusstLisDMPrice = partnerPrice > 0 &&  q.Contract_Terms__c > 0 ? (((partnerPrice*quoteLine.Quantity)/365) * q.Contract_Terms__c).setScale(2):0;
//             if (quoteLine.Discount > 0 && endCusstLisDMPrice > 0) {
//                 endCusstLisDMPrice = (endCusstLisDMPrice * (100 - quoteLine.Discount)) / 100;    
//             }
//             parameters.add('$ ' + String.valueOf(proratedListPrice.setScale(2)) + ' USD');
//             parameters.add(q.Account.Name);
//             parameters.add('$ ' + String.valueOf(endCusstLisDMPrice.setScale(2)) + ' USD');
//             //parameters.add('$ ' + String.valueOf((standardPrice * quoteLine.Quantity).setScale(2)) + ' USD');
//             //parameters.add(q.Account.Name);
//             //parameters.add('$ ' + String.valueOf((partnerPrice * quoteLine.Quantity).setScale(2)) + ' USD');
//         } else if (q.opportunity.Type == newBuisness) {
//             Decimal discountPrice = (standardPrice * quoteLine.Quantity);
//             if (quoteLine.Discount > 0 && discountPrice > 0) {
//                 discountPrice = (discountPrice * (100 - quoteLine.Discount)) / 100;    
//             }
//             Decimal discountPartnerPrice = (partnerPrice * quoteLine.Quantity);
//             if (quoteLine.Discount > 0 && discountPartnerPrice > 0) {
//                 discountPartnerPrice = (discountPartnerPrice * (100 - quoteLine.Discount)) / 100;    
//             }
//             parameters.add('$ ' + String.valueOf(discountPrice.setScale(2)) + ' USD');
//             parameters.add(q.Account.Name);
//             parameters.add('$ ' +  String.valueOf(discountPartnerPrice.setScale(2)) + ' USD');
//             //parameters.add('$ ' +  String.valueOf((standardPrice * quoteLine.Quantity).setScale(2)) + ' USD');
//             //parameters.add(q.Account.Name);
//             //parameters.add('$ ' +  String.valueOf((partnerPrice * quoteLine.Quantity).setScale(2)) + ' USD');
//         }
//         return parameters;
//     }

    public PageReference saveAndOpenPDF() {
        if (String.isBlank(ApexPages.currentPage().getParameters().get('displayOnly'))) {
            Id attachmentId = savePDF();
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
        PageReference pdf = Page.QuotePDFSubscription;
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
        If (q.Contract_Start_Date__c == null) {
            updatedQuote.Contract_Start_Date__c = Date.today();     
        }
        If (q.Contract_End_Date__c == null && q.Opportunity.Parent_Opportunity__c != null && q.Opportunity.Parent_Opportunity__r.Account != null && q.Opportunity.Parent_Opportunity__r.Account.Enhancement_Date__c != null ) {
            updatedQuote.Contract_End_Date__c = q.Opportunity.Parent_Opportunity__r.Account.Enhancement_Date__c;
        } else If (q.Contract_End_Date__c == null && q.Account != null && q.Account.Enhancement_Date__c != null) {
            updatedQuote.Contract_End_Date__c = q.Account.Enhancement_Date__c;     
        }
        if (q.Contract_End_Date__c == null && q.Account != null && q.Account.Enhancement_Date__c == null && (q.opportunity.Type == newBusiness || q.opportunity.Type == newLogo)) {
            if (q.Contract_Start_Date__c == null) {
                updatedQuote.Contract_End_Date__c = updatedQuote.Contract_Start_Date__c.addDays(365);
            } else {
                updatedQuote.Contract_End_Date__c = q.Contract_Start_Date__c.addDays(365);
            }
        }
        try {
            update updatedQuote;
            if (updateQuoteLines.size() > 0) {
             update updateQuoteLines;    
            }
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