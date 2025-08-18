@isTest
global class RefreshAccessTokenDocusign_Mock implements HttpCalloutMock {
	global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
       	res.setBody('{"access_token":"12312","refresh_token":"12312"}');
        return res;
    }
}