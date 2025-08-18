@isTest
class DocusignOppContollerTest {
    @isTest
    static void testDocusignOppContoller() {

        DocusignApiKeys__c orgDefault = new DocusignApiKeys__c(
            SetupOwnerId=UserInfo.getOrganizationId(),
            AccessToken__c = '12312'
        );
        insert orgDefault;
        Account acc = new Account();
        acc.Name = 'Test account';
        acc.BillingCountry = 'United States';
        acc.Billingstreet = '1 Wall Street';
        acc.BillingCity = 'New York';
        acc.BillingState = 'New York';
        acc.BillingPostalCode = '10005';        
        insert acc;

        Contact rec = new Contact();
        rec.LastName = 'Doe';
        rec.FirstName = 'Mary';
        rec.Email = 'Mary.Doe@test.com.partner';
        insert rec;

        Opportunity opportunityToCreate = new Opportunity();
        // Do you recognize these fields?
        opportunityToCreate.StageName = 'Prospecting';
        opportunityToCreate.CloseDate = Date.today();
        opportunityToCreate.AccountId = acc.id;
        opportunityToCreate.Name = 'Test Opportunity';
        insert opportunityToCreate;

        Pricebook2 pb22 = new Pricebook2(Name='testDIE');
        insert pb22;

        Product2 pro2 = new Product2(Name='BXCD', isActive=true);
        insert pro2;

        PricebookEntry pbe1 =new PricebookEntry(unitprice=0.01,Product2Id=pro2.Id,Pricebook2Id=Test.getStandardPricebookId(),
                                                isActive=true,UseStandardPrice = false);
        insert pbe1;

        PricebookEntry pbe2 =new PricebookEntry(unitprice=0.01,Product2Id=pro2.Id,Pricebook2Id=pb22.Id,
                                                isActive=true,UseStandardPrice = false);
        insert pbe2;

        OpportunityLineItem OPplineitem2 = new OpportunityLineItem (Quantity=2, OpportunityId=opportunityToCreate.Id,UnitPrice=0.01,PriceBookEntryId=pbe2.Id
                                            );
        insert OPplineitem2;

        Quote quttest = new Quote (Name = 'qoutetest' , contactId=rec.Id, OpportunityId = opportunityToCreate.id , Pricebook2Id = pb22.id );
        insert quttest ;

        Attachment attach=new Attachment();   	
    	attach.Name='Unit Test Attachment';
    	Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
    	attach.body=bodyBlob;
        attach.parentId=quttest.id;
        insert attach;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new RefreshAccessTokenDocusign_Mock());
        DocusignOppContoller.sendDocusign(new List<String>{opportunityToCreate.Id});
        Test.stopTest();
    }
}