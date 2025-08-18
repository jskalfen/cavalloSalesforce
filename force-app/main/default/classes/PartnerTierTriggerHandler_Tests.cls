@isTest
private class PartnerTierTriggerHandler_Tests {
    
    @IsTest(SeeAllData=true)
    static void testPartnerTier() {
        RecordType acctPartnerResellerRecordType = [Select ID,DeveloperName From RecordType where DeveloperName='Reseller_Partner' limit 1];
        Account partnerAcct = new Account();
        partnerAcct.Name = 'Partner Account 1';
        partnerAcct.Type = 'Partner - Reseller';
        partnerAcct.RecordType = acctPartnerResellerRecordType;
        insert partnerAcct;
        
        Account partnerAcct2 = new Account();
        partnerAcct2.Name = 'Partner Account 2';
        partnerAcct2.Type = 'Partner - Reseller';
        partnerAcct2.RecordType = acctPartnerResellerRecordType;
        insert partnerAcct2;
        
        Partner_Tier__c pt = new Partner_Tier__c();
        pt.Name = 'Test';
        pt.Partner__c = partnerAcct.Id;
        pt.Partner_Tier_Start_Date__c = Date.Today();
        pt.Partner_Tier__c = 'Silver';
        
        test.startTest();
        insert pt;
        pt.Partner__c = partnerAcct2.Id;
        update pt;
        pt.Partner_Tier_End_Date__c = Date.Today()-1;
        pt.Partner_Tier_End_Reasoning__c = 'Testing';
        update pt;
        test.stopTest();
    }

}