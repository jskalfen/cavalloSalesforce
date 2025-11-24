@isTest
private class QuoteTriggerHandler_Test {
    
    @IsTest(SeeAllData=true)
    static void testQuoteBeforeInsert(){
            RecordType acctRecordType = [Select ID,DeveloperName From RecordType where DeveloperName='Customer' limit 1];
            RecordType oppRecordType = [Select ID,DeveloperName From RecordType where DeveloperName='New_Business' limit 1];
            //chargebeeapps__CB_Sites__c cbSite = [Select ID From chargebeeapps__CB_Sites__c limit 1];
            Account acct = new Account();
            acct.Name = 'Test Account 1';
            acct.Type = 'Client - Direct';
            acct.RecordType = acctRecordType;
            acct.Account_Status__c = 'Satisfied';
            //acct.chargebeeapps__CB_Site__c = cbSite.Id;
            acct.Enhancement_Date__c = Date.Today().addYears(2);
            Pricebook2 pb = [Select ID From Pricebook2 where isActive = true AND Name Like '%CB Standard%' limit 1];
    
            Opportunity opp = new Opportunity();
            opp.Name = 'Opp Test';
            opp.AccountId = acct.Id;
            opp.Type = 'Existing Business';
            opp.chargebeeapps__Manual_Discount__c = '[{"type":"PERCENTAGE","period_unit":"year","period":"1","percentage":null,"operation_type":"add","item_price_id":"CLD00018","isPercentageDiscount":true,"isOneTime":false,"isLineItemDiscount":true,"isInvoiceDiscount":false,"isForever":false,"isFixedDiscount":false,"id":null,"duration_type":"limited_period","discountType":"PERCENTAGE","discountPercentage":"5.00","discountAmount":null,"currency_code":"USD","cbId":"D_542421","apply_on":"specific_item_price","amount":null}]';
            opp.StageName = 'Structure';
            opp.CloseDate = Date.Today().addMonths(3);
            opp.Opportunity_Source_Global__c = 'Customer';
            opp.Pricebook2Id = pb.Id;
            opp.RecordTypeId = oppRecordType.Id;
            opp.Business_Segment__c = 'SalesPad';
            insert opp;
            Quote q = new Quote(OpportunityId = opp.Id);
            q.Name = 'Ray Test';
        	QuoteLineDiscount qdiscount = new QuoteLineDiscount();
        	qdiscount.type = 'PERCENTAGE';
        	qdiscount.percentage = '25';
        	qdiscount.operation_type = 'add';
        	qdiscount.item_price_id = 'CLD00018';
        	qdiscount.isPercentageDiscount = true;
            qdiscount.isOneTime = false;
            qdiscount.isLineItemDiscount = true;
            qdiscount.isInvoiceDiscount = false;
            qdiscount.isForever = false;
            qdiscount.isFixedDiscount = false;
            qdiscount.discountPercentage = '25';
            qdiscount.discountAmount = '100';
            qdiscount.currency_code = 'USD';
            qdiscount.cbId = 'cbId1234';
            qdiscount.apply_on = 'specific_item_price';
            qdiscount.amount = '100';
        	qdiscount.id = 'discountId';
            Test.startTest();
            insert q;
            Test.stopTest();
        }
    }