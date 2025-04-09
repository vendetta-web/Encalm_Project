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
        String apiEndpoint = 'https://swiftapi.digitalorder.in/v2/api/push_confirmed_bookings_new';  // Replace with actual endpoint
       String body = '"{"payload":{"save_sale_order_post":{"sfa_booking_id":"12","sfa_booking_no":"D24083477","itinerary_no":"V61477720","service_type":"Departure","booking_date":"2025-03-2110:35:00","service_date":"2025-03-3111:45:00","travel_date":"2025-03-31","travel_sector":"Domestic","service_airport":"IndiraGandhiInternationalAirport","service_airport_code":"DEL","from_airport":"IndiraGandhiInternationalAirport","from_airport_code":"DEL","to_airport":"BijuPatnaikInternationalAirport","to_airport_code":"BBI","arrival_airline":"","arrival_flight":"","arrival_time":"","arrival_term":"","departure_airline":"AirIndia","departure_flight":"AI473","departure_time":"07:00","departure_term":"T3","no_of_adult":1,"no_of_children":1,"no_of_infants":0,"primary_product":"GOLD(DOM-DEP)","customer_sfa_id":"12","customer_name":"[40083761]PetronetLNGLimited","customer_mobile":"+919811799331","customer_email":"himanshumehta@petronetlng.in","customer_tag":"VIP1","booker_name":"HIMANSHUMEHTA","booker_mobile":"+919811799331","booker_email":"himanshumehta@petronetlng.in","salesperson_name":"SmitaRajput","salesperson_mobile":"","salesperson_email":"smita.rajput@encalm.com","placard_name":"Mr.NirajJha","placard_title":"Mr.","placard_first_name":"Niraj","placard_last_name":"Jha","placard_country_code":"+91","placard_mobile":"9650814908","placard_email":"niraj@gmail.com","instructions":"Needafemaleassociate","payment_method":"Cashonaccount","payment_ref_no":"UTR2304RT34567","API_KEY":"sfa879z16Ff7XIEtyu67Sii"},"sale_order_item_payload":[{"product_sfa_id":10617,"product_name":"SILVER(INT-ARR)(Adult)","product_qty":1},{"product_sfa_id":10617,"product_name":"SILVER(INT-ARR)(Child)","product_qty":1}],"sale_order_guest_payload":[{"guest_sfa_id":12,"guest_name":"Mr.AliceSmith","guest_age":33,"travel_class":"Economy","pnr_no":"PNR123","passport_no":"P12345","designation":"Director","preferences":"WantManishtoattend","country_code":"+91","mobile":"9876543210"},{"guest_sfa_id":13,"guest_name":"Mr.BobSmith","guest_age":10,"travel_class":"Economy","pnr_no":"PNR123","passport_no":"P312345","designation":"","preferences":"","country_code":"","mobile":""}],"sale_order_avaan_booking_payload":[{"avaan_sfa_id":1012,"avaan_booking_no":"AVB00987","avaan_bags":"1","avaan_weight":"30Kg","avaan_amount":"3000","avaan_booking_date":"2025-03-3111:45"}]}}"';

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        req.setEndpoint(apiEndpoint);  
        req.setMethod('POST');
        // req.setHeader('Content-Type','application/json;charset=UTF-8');
        // req.setHeader('Content-Type','application/x-www-form-urlencoded');
        req.setBody(body);

 HttpResponse response = http.send(req);
        system.debug('responseStatus--->'+response.getStatus());
        system.debug('responseBody--->'+response.getBody());
       
       
        // Define the API endpoint you want to hit
        // Set the request headers and parameters
      /*  HttpRequest req = new HttpRequest();
        req.setEndpoint(apiEndpoint);
        req.setMethod('POST');  // Replace with POST, PUT, DELETE, etc., depending on your use case
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        req.setHeader('API_KEY', API_KEY);
           req.setBody(body);
        // Make the HTTP request
        Http http = new Http();
        HttpResponse res = http.send(req);
        // Create HTTP Request
        HttpRequest req = new HttpRequest();
        req.setEndpoint(apiEndpoint);
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        req.setHeader('Content-Type', 'application/json');
      //  req.setHeader('API_KEY', payload.save_sale_order_post.API_KEY);
        req.setBody(body);

         // Send request
        Http http = new Http();
        HttpResponse res = http.send(req);

        // Handle response
        if (res.getStatusCode() == 200) {
            System.debug('Success: ' + res.getBody());
        } else {
            System.debug('in else-----------');
            System.debug('Error: ' + res.getStatusCode() + ' → ' + res.getBody());
        }*/
    }
}