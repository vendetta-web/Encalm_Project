public class CancellationPolicyMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"access_token": "mocked_token"}');
        res.setStatusCode(200);
        return res;
    }
}