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
    
/*
 * ───────────────────────────────────────────────────────────────────────────────────────────────
 * @purpose: Authenticates with the partner system and retrieves an access token.
 * @param :oppId The Opportunity ID used for the subsequent API call.
 * @param :actionType The action type parameter passed to the API after authentication.
 * @return: The access token if the authentication is successful, otherwise null.
 * ───────────────────────────────────────────────────────────────────────────────────────────────
 */
    public static String getAccessToken(String oppId, String actionType) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(PARTNER_AUTH_URL);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        String payload = 'username=' + EncodingUtil.urlEncode(USERNAME, 'UTF-8') + 
            '&password=' + EncodingUtil.urlEncode(PASSWORD, 'UTF-8');
        req.setBody(payload);
        System.debug('Payload Sent ====>' +payload);    
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
    
        
/*
 * ───────────────────────────────────────────────────────────────────────────────────────────────
 * @purpose: Use the access token to call another API.
 * @param : oppId The Opportunity ID used for the subsequent API call.
 * @param : actionType The action type parameter passed to the API after authentication.
 * @param : access token for callout.
 * @return: void.
 * ───────────────────────────────────────────────────────────────────────────────────────────────
 */
    public static void callApiWithToken(String accessToken, String oppId, String actionType) {
        MDEN_SWIFT_API_Call.PayloadWrapper wrapper=  MDEN_SWIFT_API_Call.getOpportunity(oppId, actionType);
        if(wrapper.payload.save_sale_order_post.action_type == 'Cancel'){
            String ENDPOINT = '/push_confirmed_bookings_cancel_full';
            String requestBody  = JSON.serialize(wrapper);
            System.debug('Serialized JSON: ' + requestBody);
            redirectUrl(ENDPOINT, accessToken, requestBody,oppId, actionType);            
        }
        if(wrapper.payload.save_sale_order_post.action_type == 'Partially Cancelled'){
            String requestBody  = JSON.serialize(wrapper);
            System.debug('Serialized JSON: ' + requestBody);
            String ENDPOINT = '/push_confirmed_bookings_cancel_partial';
            redirectUrl(ENDPOINT, accessToken, requestBody,oppId, actionType);
        } 
        if(wrapper.payload.save_sale_order_post.action_type == 'Modified/Rescheduled' ){       
            String requestBody  = JSON.serialize(wrapper);
            System.debug('Serialized JSON: ' + requestBody);
            String ENDPOINT = '/push_confirmed_bookings_modify_reschedule';
            String BASE_URL = 'https://swiftapi.digitalorder.in/v2/api';
            redirectUrl(ENDPOINT, accessToken, requestBody,oppId, actionType);          
        }
        
        if(wrapper.payload.save_sale_order_post.action_type == null || wrapper.payload.save_sale_order_post.action_type == '' ){
            String requestBody  = JSON.serialize(wrapper);
            System.debug('Serialized JSON: ' + requestBody);
            String ENDPOINT = '/push_confirmed_bookings_new';
            String BASE_URL = 'https://swiftapi.digitalorder.in/v2/api';
            redirectUrl(ENDPOINT, accessToken, requestBody,oppId, actionType);                                                                                                                       
        }    
    } 
    
/*
 * ───────────────────────────────────────────────────────────────────────────────────────────────
 * @purpose: Use to handel the redirectUrl.
 * @param : endPoint of the system. 
 * @param :accessToken.
 * @param :requestBody of the request.
 * @param : oppId The Opportunity ID used for the subsequent API call.
 * @param : actionType The action type parameter passed to the API after authentication.
 * @return: void
 * ───────────────────────────────────────────────────────────────────────────────────────────────
 */    
    public static void redirectUrl(String endPoint, String accessToken,  String requestBody, String oppId, String actionType) {    
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
                    System.debug('responseBody===>'+responseBody);
                    if (responseBody != null) {
                        try {
                            SwiftBookingResponseWrapper response = (SwiftBookingResponseWrapper) JSON.deserialize(responseBody, SwiftBookingResponseWrapper.class);
                            if(response != null ){
                                System.debug('responseBody===>'+response.status_code);
                                if(response.status_code != 200){
                                    logAndRetry(oppId, actionType, requestBody, accessToken);
                                }
                                Log_Parsing_Error__c logs = new Log_Parsing_Error__c();
                                logs.Status__c = response.status;
                                logs.Request__c = requestBody;
                                logs.Message__c = response.message;
                                logs.API_Name__c = 'SWIFT';
                                logs.Status_Code__c =  redirectRes.getStatusCode();
                                logs.Response__c = responseBody;
                                insert logs;
                                system.debug('-logs-->'+logs);
                            }
                        } catch (Exception e) {
                            SwiftBookingResponseWrapper response = (SwiftBookingResponseWrapper) JSON.deserialize(responseBody, SwiftBookingResponseWrapper.class);
                            if(response != null ){
                                Log_Parsing_Error__c logs = new Log_Parsing_Error__c();
                                logs.Status__c = response.status;
                                logs.Request__c = requestBody;
                                logs.Message__c = e.getMessage();
                                logs.API_Name__c = 'SWIFT';
                                logs.Response__c = responseBody;
                                logs.Status_Code__c =  redirectRes.getStatusCode();
                                insert logs;
                                system.debug('-logs--->'+logs);
                            }
                            System.debug('JSON Parse Error: ' + e.getMessage());
                        }
                    }
                } else {
                    logAndRetry(oppId, actionType, requestBody, accessToken);
                    System.debug('Failed after redirect: ' + redirectRes.getStatusCode());
                }
            } else {
                System.debug('Redirect location header is missing!');
            }
        } 
    }
    
/*
 * ───────────────────────────────────────────────────────────────────────────────────────────────
 * @purpose: Use to handel the failure mechanism.
 * @param : oppId The Opportunity ID used for the subsequent API call.
 * @param : actionType The action type parameter passed to the API after authentication.
 * @param :accessToken.
 * @param :requestBody of the request.
 * @return: void
 * ───────────────────────────────────────────────────────────────────────────────────────────────
 */    
    
    public static void logAndRetry(String oppId, String actionType, String requestBody, String accessToken) {
        try{
            List<Log_Parsing_Error__c> attempts = [SELECT Id, Retry_Count__c FROM Log_Parsing_Error__c WHERE OpportunityId__c = :oppId LIMIT 1];
            Log_Parsing_Error__c attempt = new Log_Parsing_Error__c();
            if (attempts.isEmpty()) {
                    attempt.OpportunityId__c = oppId;
                    attempt.ActionType__c = actionType;
                    attempt.Retry_Count__c = 1;
                    attempt.Status__c = 'Pending';
                    attempt.Last_Attempt__c = System.now();
            } else {
                attempt.Retry_Count__c += 1;
                attempt.Last_Attempt__c = System.now();
                attempt.Id = attempts[0].Id;
            }
            upsert attempt;
            if (attempt.Retry_Count__c < 3) {
                Datetime scheduleTime = Datetime.now().addMinutes(1);
                String cronExp = String.format('{0} {1} {2} {3} {4} ? {5}', new List<String>{
                    String.valueOf(scheduleTime.second()),
                        String.valueOf(scheduleTime.minute()),
                        String.valueOf(scheduleTime.hour()),
                        String.valueOf(scheduleTime.day()),
                        String.valueOf(scheduleTime.month()),
                        String.valueOf(scheduleTime.year())
                        });
                System.schedule('SwiftRetry_' + Datetime.now().getTime(), cronExp, new SwiftRetryScheduler(oppId, actionType));
                
            } else {
                sendFailureEmail(oppId, actionType, requestBody);
            }
        } catch (Exception e) {
            System.debug('Error in getOpportunity: ' + e.getMessage());
            System.debug('Error in getOpportunity: ' + e.getLineNumber());
        }
    }

/*    
 * ───────────────────────────────────────────────────────────────────────────────────────────────
 * @purpose: Use to send email if failure occurs.
 * @param : oppId The Opportunity ID used for the subsequent API call.
 * @param : actionType The action type parameter passed to the API after authentication.
 * @param :requestBody of the request.
 * @return: void
 * ───────────────────────────────────────────────────────────────────────────────────────────────
 */
    public static void sendFailureEmail(String oppId, String actionType, String requestBody) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] {Label.Error_Email});
        mail.setSubject('SWIFT API Push Failure Notification');
        mail.setPlainTextBody('The push attempt for Opportunity ' + oppId +
                              ' with Action Type "' + actionType + '" has failed after 3 retries.\nRequest: ' + requestBody);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
    
    public class SwiftBookingResponseWrapper {
        public String status;
        public String message;
        public Integer swift_booking_id;
        public Integer  status_code;
    }
}