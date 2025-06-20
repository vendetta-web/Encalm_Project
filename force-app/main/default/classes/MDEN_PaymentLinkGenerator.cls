global with sharing class MDEN_PaymentLinkGenerator {
	 @Future(callout=true)
    global static  void sendRequest(String OppId) {
        Order_Request__c pendingRequest = OrderRequestController.getPendingRequest(OppId);
        List<Opportunity> oppList = [SELECT Id, Amount,Account.isPersonAccount, StageName,Name,Account.Name, Account.phone  FROM Opportunity where id =: OppId LIMIT 1];        
        if(oppList[0].Account.isPersonAccount)
        {
            Map<String, Object> invoiceData = new Map<String, Object>();        
            invoiceData.put('customer_name', oppList[0].Account.Name);
            invoiceData.put('bill_delivery_type', 'SMS');
            invoiceData.put('customer_mobile_no', '9999999999');
            //invoiceData.put('invoice_description', 'Test');
            invoiceData.put('currency', 'INR');
            invoiceData.put('valid_for', 3);
            invoiceData.put('valid_type', 'days');
            invoiceData.put('amount', pendingRequest !=null ? pendingRequest.Total_Payable_Amount__c : 1);
            invoiceData.put('merchant_reference_no', pendingRequest !=null ? pendingRequest.Order_Request_Number__c : oppList[0].Name);
            //invoiceData.put('merchant_reference_no1', 2);
            //invoiceData.put('merchant_reference_no2', 3);
            //invoiceData.put('merchant_reference_no3', 4);
            //invoiceData.put('merchant_reference_no4', 5);
            //invoiceData.put('terms_and_conditions', 'terms and condition');
            invoiceData.put('sms_content', 'Pls pay your LegalEntity_Name bill # Invoice_ID for Invoice_Currency Invoice_Amount online at  Pay_Link.');
            
            // Call the method
            String result = CCAvenueInvoiceService.createInvoice(invoiceData); 
            System.debug('Invoice API Response: ' + result);
            InvoiceResponseWrapper requestMap = InvoiceResponseWrapper.parse(result);
            if(requestMap != null ){
                Payment_transaction__c ptRec = new Payment_transaction__c();
                ptRec.QR_Code__c = requestMap.Generate_Invoice_Result.qr_code;   
                ptRec.Merchant_Reference_No__c = requestMap.Generate_Invoice_Result.merchant_reference_no ; 
                ptRec.Invoice_Id__c = requestMap.Generate_Invoice_Result.invoice_id ;  
                ptRec.Error_Description__c = requestMap.Generate_Invoice_Result.error_desc; 
                ptRec.Error_Code__c = requestMap.Generate_Invoice_Result.error_code ; 
                ptRec.Tiny_URL__c = requestMap.Generate_Invoice_Result.tiny_url; 
                ptRec.Invoice_Status__c = requestMap.Generate_Invoice_Result.invoice_status; 
                ptRec.Booking__c= OppId;
                ptRec.Order_Request__c = pendingRequest !=null ? pendingRequest.Id : null;
                if(ptRec != null){
                    insert ptRec;
                    String requestType = pendingRequest !=null ? pendingRequest.Change_Type__c : '';
                    BookingEmailHandler.sendEmailWithAttachment(OppId, requestType, ptRec.Tiny_URL__c);
                }
            }     
        }
        else
        {
           // oppList[0].StageName = 'Quotation Sent';
           // update oppList;
        }
    } 
}