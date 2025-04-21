/*
* ───────────────────────────────────────────────────────────────────────────────────────────────
* Created by: Maxify Development Team
* Created Date: 6th, April, 2025
* Purpose: : The MDEN_SWIFT is responsible for getting the access token and making callout the data to the SWIFT service.
* Owner :  Encalm
*───────────────────────────────────────────────────────────────────────────────────────────────
*/
public class MDEN_SWIFT {
    private static final String PARTNER_AUTH_URL = 'https://swiftapi.digitalorder.in/partner_authentication';
    private static final String API_KEY = 'sfa879z16Ff7XIEtyu67Sii';
    private static final String USERNAME = 'encalm_swift_staging_user';
    private static final String PASSWORD = 'SwiftSFA_2025#2022@321';
    
    public static String getAccessToken(String oppId, String actionType) {
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
            callApiWithToken(accessToken, oppId, actionType);
            return accessToken;
        } else {
            System.debug('Error response: ' + res.getBody());
            return null;
        }
    }
    // Step 2: Use the access token to call another API
    public static void callApiWithToken(String accessToken, String oppId, String actionType) {
        MDEN_SWIFT_API_Call.PayloadWrapper wrapper=  MDEN_SWIFT_API_Call.getOpportunity(oppId, actionType);
        system.debug('-------------------------------------------'+wrapper.payload.save_sale_order_post.action_type);
        if(wrapper.payload.save_sale_order_post.action_type == 'Cancel'){
            String ENDPOINT = '/push_confirmed_bookings_cancel_full';
            String requestBody  = JSON.serialize(wrapper);
            System.debug('Serialized JSON: ' + requestBody);
            redirectUrl(ENDPOINT, accessToken, requestBody);            
        }
        if(wrapper.payload.save_sale_order_post.action_type == 'Partially Cancelled'){
            String requestBody  = JSON.serialize(wrapper);
            System.debug('Serialized JSON: ' + requestBody);
            String ENDPOINT = '/push_confirmed_bookings_cancel_partial';
            redirectUrl(ENDPOINT, accessToken, requestBody);
        } 
        if(wrapper.payload.save_sale_order_post.action_type == 'Modified/Rescheduled' ){       
            String requestBody  = JSON.serialize(wrapper);
            System.debug('Serialized JSON: ' + requestBody);
            String ENDPOINT = '/push_confirmed_bookings_modify_reschedule';
            String BASE_URL = 'https://swiftapi.digitalorder.in/v2/api';
            redirectUrl(ENDPOINT, accessToken, requestBody);           
        }
        
        if(wrapper.payload.save_sale_order_post.action_type == null || wrapper.payload.save_sale_order_post.action_type == '' ){
            String requestBody  = JSON.serialize(wrapper);
            System.debug('Serialized JSON: ' + requestBody);
            String ENDPOINT = '/push_confirmed_bookings_new';
            String BASE_URL = 'https://swiftapi.digitalorder.in/v2/api';
            redirectUrl(ENDPOINT, accessToken, requestBody);                                                                                                                       
        }    
    } 
    public static void redirectUrl(String ENDPOINT, String accessToken,  String requestBody) {    
        System.debug('Serialized JSON: ' + requestBody);
        String BASE_URL = 'https://swiftapi.digitalorder.in/v2/api';
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(BASE_URL + ENDPOINT);
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        req.setHeader('Accept', 'application/json');
        req.setBody(requestBody);      
        HttpResponse res = http.send(req);
        System.debug('Initial Status: -----------' + res.getStatusCode() + ', Body:------> ' + res.getBody());
        if (res.getStatusCode() == 307) {
            String redirectUrl = res.getHeader('location');
            System.debug('Redirecting to: ' + redirectUrl);
            for (String headerName : res.getHeaderKeys()) {
                System.debug(headerName + ': ' + res.getHeader(headerName));
            }
            if (redirectUrl != null) { 
                HttpRequest redirectReq = new HttpRequest();
                redirectReq.setEndpoint(redirectUrl);
                redirectReq.setMethod('POST'); 
                redirectReq.setHeader('Authorization', 'Bearer ' + accessToken);
                redirectReq.setHeader('Accept', 'application/json');
                redirectReq.setHeader('Content-Type', 'application/json'); 
                redirectReq.setBody(requestBody);
                HttpResponse redirectRes = http.send(redirectReq);
                System.debug('Redirect Status: ' + redirectRes.getStatusCode());
                System.debug('Redirect Response Body: ===>' + redirectRes.getBody());
                if (redirectRes.getStatusCode() == 200) {
                    String responseBody = redirectRes.getBody();
                    System.debug('responseBody=============>'+responseBody);
                    if (responseBody != null) {
                        try {
                            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                            System.debug('Parsed Response: ' + responseMap);
                        } catch (Exception e) {
                            System.debug('JSON Parse Error: ' + e.getMessage());
                        }
                    }
                } else {
                    System.debug('Failed after redirect: ' + redirectRes.getStatusCode());
                }
            } else {
                System.debug('Redirect location header is missing!');
            }
        } /*else if (res.getStatusCode() == 200) {
            try {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                System.debug('Parsed Response: ' + responseMap);
            } catch (Exception e) {
                System.debug('Error parsing JSON: ' + e.getMessage());
            }
        } else {
            System.debug('API call failed. Status: ' + res.getStatus() + ', Body: ' + res.getBody());
        }*/
    }
}