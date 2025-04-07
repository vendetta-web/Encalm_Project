/* Created by 	: Maxify Development Team
* Created Date : 14th Jan, 2025
* Input 		: None
* Purpose 		: This API class returns all the salutations
*/
@RestResource(urlMapping='/DoWebTrans/*')	
global class MDEN_HDFC_Encalm {
   /* @HttpPost
    global static String createCaseWithTask(){
        GetResponseWrapper response = new GetResponseWrapper('');
        try{
            String caseInfo;
            RestRequest request = RestContext.request;
            System.debug('---request----------------'+request);
            
            return 'Hj';
            //return response    = new GetResponseWrapper(caseInfo); 
        }catch(Exception e){
            System.debug('----error line-------------'+e.getLineNumber());
           // return response = new GetResponseWrapper(e.getMessage());
                return 'Hj';
        }
        
    }	*/
    global class GetResponseWrapper {
        global String Id; 
        global GetResponseWrapper(String Id) {
            this.Id = Id;
            
        }        
    }    
    global static  void sendRequest() {
        // Define the API endpoint URL
        String endpoint = 'https://apitest.ccavenue.com/apis/servlet/DoWebTrans';

        // Create the HttpRequest object
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        
        // Set the request body
        String requestBody ='{"customer_name": "Prateek", ' +
                    '"bill_delivery_type": "both", ' +
                    '"customer_mobile_no": 7838103537, ' +
                    '"customer_email_id": "prateekarya70@gmail.com", ' +
                    '"customer_email_subject": "Encalm API Testing", ' +
                    '"invoice_description": "Invoice Testing", ' +
                    '"currency": "INR", ' +
                    '"valid_for": 2, ' +
                    '"valid_type": "days", ' +
                    '"amount": 1.0, ' +
                    '"merchant_reference_no": 123456987, ' +
                    '"terms_and_conditions": "terms and condition", ' +
                    '"sms_content": "Pls do the payment"}';

 // String requestBody = '{"customer_name": "Prateek","bill_delivery_type": "both","customer_mobile_no": 7838103537,"customer_email_id": "prateekarya70@gmail.com","customer_email_subject": "Encalm API Testing", "invoice_description": "Invoice Testing","currency": "INR",  "valid_for": 2, "valid_type": "days","amount": 1.0, "merchant_reference_no": 123456987,"terms_and_conditions": "terms and condition","sms_content": "Pls do the payment"}';
  // String requestBody = '{"customer_name":"Prateek","bill_delivery_type":"both","customer_mobile_no":7838103537,"customer_email_id":"prateekarya70@gmail.com","customer_email_subject":"EncalmAPITesting","invoice_description":"InvoiceTesting","currency":"INR","valid_for":2,"valid_type":"days","amount":1.0,"merchant_reference_no":123456987,"terms_and_conditions":"termsandcondition","sms_content":"Plsdothepayment"}';                          
        req.setBody(requestBody);
        req.setHeader('Content-Type', 'application/json');  // Set the content type as JSON
        
        // Send the HTTP request
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        // Capture the response
        if (res.getStatusCode() == 200) {
            // Success - parse the response if needed
            String responseBody = res.getBody();
            System.debug('responseBody---------->'+responseBody);
             InvoiceWrapper requestMap = (InvoiceWrapper)JSON.deserialize(responseBody.toString(), InvoiceWrapper.class);
             
            System.debug('Response Body: ' + responseBody);
        } else {
            // Error handling
            System.debug('---------in else---------');
            System.debug('Error:' + res.getStatusCode() + ' - ' + res.getStatus());
        }
    } 
    
    
    global class InvoiceWrapper {
    global String error_desc;
    global String invoice_id;
    global String tiny_url;
    global String qr_code;
    global Integer invoice_status;
    global String error_code;
    global String merchant_reference_no;

    // Constructor to initialize the variables if needed
    global InvoiceWrapper(String error_desc, String invoice_id, String tiny_url, String qr_code, Integer invoice_status, String error_code, String merchant_reference_no) {
        this.error_desc = error_desc;
        this.invoice_id = invoice_id;
        this.tiny_url = tiny_url;
        this.qr_code = qr_code;
        this.invoice_status = invoice_status;
        this.error_code = error_code;
        this.merchant_reference_no = merchant_reference_no;
    }
}

}