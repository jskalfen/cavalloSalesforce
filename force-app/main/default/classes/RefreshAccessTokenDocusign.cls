global class RefreshAccessTokenDocusign implements Schedulable, Database.AllowsCallouts {
    public class AccessCredentials{
        public String accesToken1;
        public String accesToken2;
        public String accesToken3;
        public String refreshToken1;
        public String refreshToken2;
        public String refreshToken3;
        public AccessCredentials(String accessToken, String refreshToken){
            this.accesToken1 = accessToken.length()>255? accessToken.substring(0,255) : accessToken;
            this.accesToken2 =  accessToken.length()>255 ? accessToken.substring(255,510):'';
            this.accesToken3 = accessToken.length()>510 ? accessToken.substring(510,accessToken.length()):'';
            this.refreshToken1 = refreshToken.length()>255? refreshToken.substring(0,255): refreshToken;
            this.refreshToken2 = refreshToken.length()>255? refreshToken.substring(255,510) : '';
            this.refreshToken3 = refreshToken.length()>510 ? refreshToken.substring(510,refreshToken.length()):'';
        }
    }
    global void execute(SchedulableContext sc)
    {
		asynchCall();  
    }
	@future(callout=true)    
    public static void asynchCall (){
        DocusignApiKeys__c creds = DocusignApiKeys__c.getOrgDefaults();
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint(creds.Auth_URL__c+'/oauth/token?refresh_token='+creds.RefreshToken__c+''+creds.RefreshToken2__c+''+creds.RefreshToken3__c+'&grant_type=refresh_token');
        //req.setEndpoint('https://account-d.docusign.com/oauth/token?refresh_token='+creds.RefreshToken__c+''+creds.RefreshToken2__c+''+creds.RefreshToken3__c+'&grant_type=refresh_token');
        req.setHeader('Content-Type','application/x-www-form-urlencoded');
        req.setHeader('Content-Length', '0');
        req.setHeader('Authorization','Basic '+encodingUtil.base64Encode(blob.valueOf(creds.IntegrationKey__c+':'+creds.SecretKey__c)));
        HttpResponse res = new Http().send(req);
        system.debug(res.getStatusCode());
        system.debug(res.getBody());
        Map<String, Object> accessInfo = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
        AccessCredentials accCreds = new AccessCredentials((String)accessInfo.get('access_token'), (String)accessInfo.get('refresh_token'));
        creds.AccessToken__c = accCreds.accesToken1;
        creds.AccessToken2__c = accCreds.accesToken2;
        creds.AccessToken3__c = accCreds.accesToken3;
        creds.RefreshToken__c = accCreds.refreshToken1;
        creds.RefreshToken2__c = accCreds.refreshToken2;
        creds.RefreshToken3__c = accCreds.refreshToken3;
        update creds;
    }
}