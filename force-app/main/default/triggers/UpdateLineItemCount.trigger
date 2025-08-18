trigger UpdateLineItemCount on QuoteLineItem (before insert) {


    public static String formatCurrency(Decimal i) {
        if (i == null) return '0.00';
 
 
        i = Decimal.valueOf(Math.roundToLong(i * 100)) / 100;
        String s = (i.setScale(2) + (i >= 0 ? 0.001 : -0.001)).format();
       
        return s.substring(0, s.length() - 1);
    }
   
    //Counter
    Integer cnt = 1;
    private static final String ENHANCEMENT_PERCENT_STRING = '22';
    private static final DOUBLE ENHANCEMENT_PERCENT = .22;
    if (Trigger.isInsert)
    {
        //List of IDs to get Quote
        List<Id> lIds = new List<Id>();
        for (QuoteLineItem qli : System.Trigger.new)
            lIds.add(qli.QuoteId);
           
        //Map to hold quote counts
        Map<Id, Integer> mapCurrCounts = new Map<Id, Integer>();
        List<Quote> lQuotes = new List<Quote>();
        lQuotes = [Select Id, LineItemCount from Quote where id = :lIds];
        for(Quote q : lQuotes)
        {
            mapCurrCounts.put(q.Id, q.LineItemCount);
            //Setting the count = to the number of lines, this only works whil editing and adding lines from a single quote
            //THIS IS A HACK
            cnt = q.LineItemCount + 1;
       
        } 
           
        //Loop through the quote lines
        for(QuoteLineItem qli : System.Trigger.new){
           
            String licensedBy = '';
 
 
            //Pull the standard pricing for the current item
            Product2 currentProduct = null;
            Id stPrId;
            PricebookEntry pbe = null;
            pricebook2 pb = null;
           
            try {          
                currentProduct = [
                    SELECT ProductCode, Name, Licensing__c, Comments__c
                    FROM Product2
                    WHERE Id = :qli.Product2Id
                ];
 
 
                pb = [
                    SELECT Id
                    FROM pricebook2
                    WHERE IsStandard = true
                    LIMIT 1
                ];
 
 
                stPrId = pb.Id;
 
 
                pbe = [
                    SELECT UnitPrice
                    FROM PriceBookEntry
                    WHERE Pricebook2Id =: stPrId
                        AND Product2Id =: qli.Product2Id
                ];
 
 
            } catch (Exception e) {
                System.debug(e);
            }
           
            if(currentProduct != null)
            {
                //Set the licensed by string
                if(currentProduct.ProductCode == 'DGP0019' || currentProduct.ProductCode == 'DGP00022' || currentProduct.ProductCode == 'DGP00012'){
                    licensedBy = 'per concurrent user';
                } else if(currentProduct.ProductCode == 'MB'){
                    licensedBy = 'per named user (two logins per user)';
                } else if(currentProduct.ProductCode == 'DGP00021' || currentProduct.ProductCode == 'CLD00003'){
                    licensedBy = 'per user per month';
                } else if(currentProduct.ProductCode == 'DGP00014'){
                    licensedBy = 'per concurrent handheld device';
                } else if(currentProduct.ProductCode == 'CLD00003'){
                    licensedBy = 'per user per year';
                } else{
                    licensedBy = 'per GP site ID';
                }    
               
                if(currentProduct.Comments__c != null){
                    qli.Comments__c = currentProduct.Comments__c;
                } else if(currentProduct.Name.contains('Enhancement')){
                    qli.Comments__c = String.Format('{0}% Annual Enhancement per concurrent user. \nProrated Enhancement from date: \nList price: $', new String[] {ENHANCEMENT_PERCENT_STRING});                   
                } else if(qli.Comments__c == null || qli.Comments__c == ''){
                    if(currentProduct.ProductCode == 'SRV00001' || currentProduct.ProductCode == 'SRV00001' || currentProduct.ProductCode.StartsWith('CST00001')){
                        qli.Comments__c = String.Format('List price: ${0} per hour. *Estimate only. Hours are billed as time and materials on a weekly basis.\nSalesPad standard Implementation timeframe:\n- 24 to 48 hours or two (2) business days to process the order\n- 5 to 15 Business Days – Initial Implementation contact', new String[] {String.valueOf(pbe.UnitPrice)});
                    } else if(currentProduct.ProductCode == 'SRV00001'){
                        qli.Comments__c = String.Format('List price: ${0} per hour. *Estimate only. Hours are billed as time and materials on a weekly basis.\nTypical implementation tasks include: \n- Overview/Kickoff \n- Basic Company Setup \n- Settings, security, user configuration \n- Workflow discovery and creation \n- Report Designer training \n- Process Consulting \n\n*These are typical tasks; the hours quoted do not guarantee SalesPad completes each task. \nSome tasks may take longer than others, depending on customer requirements. \nShould additional hours be required, a change order will be presented to the customer that will require a signature.', new String[] {String.valueOf(pbe.UnitPrice)});
                    } else if(currentProduct.ProductCode == 'CONSULTING - PAYFABRIC'){
                        qli.Comments__c = String.Format('List price: ${0} per hour. *Estimate only. Hours are billed as time/materials on a weekly basis. PayFabric enrollment form required. Reference Nodus website for additional monthly fees for subscription to PayFabric: https://www.payfabric.com/us/pricing.html', new String[] {String.valueOf(pbe.UnitPrice)});
                    } else if(currentProduct.ProductCode == 'CONSULTING - EDI'){
                        qli.Comments__c = String.Format('List price: ${0} per hour. *Estimate only. Hours are billed as time/materials on a weekly basis. This is an estimate based on the document types for your trading partner. \n(Space to list trading partners and docs)\n1.\nHours are billed as they are consumed. Should the client use the total allotment of hours and the project is still open, SalesPad will send a formal change order request for the additional hours needed. Initial installation and server connection, security configuration, business object mapping setup, EDI schedule creation (2 or less), minor workflow edits*, light data cross-reference setup (2 or less), light user training. Minor workflow edits are considered as adding the EDI plug-ins to a pre-existing workflow. Entirely new Workflow creation will need to be quoted with additional consulting hours, based upon the request. Although SalesPad will perform some basic testing, the majority of the testing is the responsibility of the client. Additional companies in Dynamics GP that need EDI setup will need to be quoted separately. Remote access to the customer environment is REQUIRED.\nPrinted form changes not included. Edits to printed forms or the creation of entirely new printed forms will require a separate quote.', new String[] {String.valueOf(pbe.UnitPrice)});
                    } else if(currentProduct.ProductCode == 'CLD00003'){
                        qli.Comments__c = 'SalesPad Cloud license seat cost per named user per month:\n1-5 users $99/month\n6-10 users $89/month';
                    } else if(currentProduct.ProductCode == 'SRV00002' || currentProduct.ProductCode == 'PM SERVICES - ALL'){
                        qli.Comments__c = '';
                    } else if(currentProduct.ProductCode == 'SPWP-RAPID'){
                        qli.Comments__c = 'WebPortal Internal offering only \n - Kickoff & Review Requirements\n - One Cal\n - Web API - Install\n - IIS Web Server Config\n - Security\n INTERNAL ONLY\n - Permission Setup\n - Workflow  Design Discussion\n - Workflow Testing/Tweaks\n - Training\n - Power User Training\n - Testing\n - Cutover Tasks\n - Go Live support';
                    } else {
                        qli.Comments__c = String.Format('List price ${0} {1}.', new String[] {formatCurrency(pbe.UnitPrice), licensedBy});
                    }   
                }
            }
           
    
            qli.Line_Number__c = cnt;
            cnt += 1;
        }
    }
   
 
 
 }