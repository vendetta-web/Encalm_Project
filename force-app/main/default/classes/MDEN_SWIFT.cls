public class MDEN_SWIFT {
    private static final String PARTNER_AUTH_URL = 'https://swiftapi.digitalorder.in/partner_authentication';
    private static final String API_KEY = 'sfa879z16Ff7XIEtyu67Sii';
    private static final String USERNAME = 'encalm_swift_staging_user';
    private static final String PASSWORD = 'SwiftSFA_2025#2022@321';

    public static String getAccessToken() {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(PARTNER_AUTH_URL);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');

        // Set body as form-encoded
        String payload = 'username=' + EncodingUtil.urlEncode(USERNAME, 'UTF-8') + 
                         '&password=' + EncodingUtil.urlEncode(PASSWORD, 'UTF-8');
        req.setBody(payload);
        System.debug('Payload Sent ====> ' + payload);

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            String accessToken = (String) responseMap.get('access_token');
            System.debug('Access Token ====> ' + accessToken);
            callApiWithToken(accessToken);
            return accessToken;
        } else {
            System.debug('Error response: ' + res.getBody());
            return null;
        }
    }
    // Step 2: Use the access token to call another API
   public static void callApiWithToken(String accessToken) {
        // Define the API endpoint you want to hit
        String apiEndpoint = 'https://swiftapi.digitalorder.in/v2/api/';  // Replace with actual endpoint

        // Set the request headers and parameters
        HttpRequest req = new HttpRequest();
        req.setEndpoint(apiEndpoint);
        req.setMethod('GET');  // Replace with POST, PUT, DELETE, etc., depending on your use case
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        req.setHeader('API_KEY', API_KEY);

        // Make the HTTP request
        Http http = new Http();
        HttpResponse res = http.send(req);

        // Check the response
        if (res.getStatusCode() == 200) {
            System.debug('API Response: ' + res.getBody());
        } else {
            // Handle error - logging, throwing an exception, etc.
            System.debug('Error response: ' + res.getBody());
        }
    }
}