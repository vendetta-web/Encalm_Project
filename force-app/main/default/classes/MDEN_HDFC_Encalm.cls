/* Created by 	: Maxify Development Team
* Created Date : 14th Jan, 2025
* Input 		: None
* Purpose 		: This API class returns all the salutations
*/
global class MDEN_HDFC_Encalm {
    
    global static  void sendRequest() {
        List<Opportunity> oppList = [SELECT Id,Amount, Account.Name, Account.BusinessEmail__c  FROM Opportunity LIMIT 1];        
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://apitest.ccavenue.com/apis/servlet/DoWebTrans');
        req.setMethod('POST');
        // Properly formatted form data request_type
        String requestBody = 
            '&command=generateQuickInvoice' +  // Example required param
            '&access_code=201'+
            '&request_type=STRING'+
            '&customer_name=Prateek' +
            '&bill_delivery_type=both' +
            '&customer_mobile_no=7838103537' +
            '&customer_email_id=prateekarya70@gmail.com' +
            '&customer_email_subject=Encalm API Testing' +
            '&invoice_description=Invoice Testing' +
            '&currency=INR' +
            '&valid_for=2' +
            '&valid_type=days' +
            '&amount=1.0' +
            '&merchant_reference_no=123456987' +
            '&terms_and_conditions=terms and condition' +
            '&sms_content=Pls do the payment';        
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setBody(requestBody);        
        Http http = new Http();
        HttpResponse res = http.send(req);        
        System.debug('Response status: ' + res.getStatus());
        System.debug('Response body: ' + res.getBody());
        //MDEN_HDFC_Encalm.InvoiceWrapper requestMap = new MDEN_HDFC_Encalm.InvoiceWrapper();
        InvoiceWrapper requestMap = (InvoiceWrapper)JSON.deserialize(res.getBody().toString(), InvoiceWrapper.class);        
        if(requestMap != null ){
            Payment_transaction__c ptRec = new Payment_transaction__c();
            ptRec.Name = 'Test';
            ptRec.QR_Code__c = requestMap.qr_code;   
            ptRec.Merchant_Reference_No__c = requestMap.merchant_reference_no ; 
            ptRec.Invoice_Id__c = requestMap.invoice_id ;  
            ptRec.Error_Description__c = requestMap.error_desc; 
            ptRec.Error_Code__c = requestMap.error_code ; 
            ptRec.Tiny_URL__c = requestMap.tiny_url; 
            ptRec.Invoice_Status__c = requestMap.invoice_status; 
            if(ptRec != null){
                insert ptRec;
            }
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