@isTest
public class RefreshAccessTokenDocusign_Test {
    @testSetup
    public static void setupData(){
        DocusignApiKeys__c orgDefault = new DocusignApiKeys__c(
            SetupOwnerId=UserInfo.getOrganizationId(),
            AccessToken__c = '12312'
        );
        insert orgDefault;
    }
    @isTest
    public static void refreshAccessToken(){
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new RefreshAccessTokenDocusign_Mock());
        RefreshAccessTokenDocusign.asynchCall();   
        test.stopTest();
        DocusignApiKeys__c creds = DocusignApiKeys__c.getOrgDefaults();
        system.assertEquals('12312', creds.AccessToken__c);
    }
}