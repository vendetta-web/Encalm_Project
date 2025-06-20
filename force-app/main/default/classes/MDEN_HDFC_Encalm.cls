/* Created by 	: Maxify Development Team
* Created Date : 14th Jan, 2025
* Input 		: None
* Purpose 		: This API class returns all the salutations
*/
global class MDEN_HDFC_Encalm {
    @Future(callout=true)
    global static void sendRequest(String OppId) {
        Payment_transaction__c ptRec = new Payment_transaction__c();

        List<Opportunity> oppList = [SELECT 
                                        (SELECT ID, Payment_Transaction__c,product2.Package_Is_For__c, OpportunityId, Quantity, Name 
                                         FROM OpportunityLineItems 
                                         WHERE product2.Package__c <> '' OR product2.Family = 'Transit'),
                                        Id, Amount, Account.isPersonAccount, StageName, Name, 
                                        Account.Name, Account.Phone, 
                                        Booker__r.Name, Booker__r.Email 
                                     FROM Opportunity 
                                     WHERE Id = :OppId 
                                     LIMIT 1];

        Opportunity opp = oppList[0];

        Map<String, Object> invoiceData = new Map<String, Object>();
        invoiceData.put('customer_name', opp.Account.isPersonAccount ? opp.Account.Name : opp.Booker__r.Name);
        invoiceData.put('bill_delivery_type', 'SMS');
        invoiceData.put('customer_mobile_no', '9999999999');
        //invoiceData.put('invoice_description', 'Test');
        invoiceData.put('currency', 'INR');
        invoiceData.put('valid_for', 3);
        invoiceData.put('valid_type', 'days');
        invoiceData.put('amount', 1);
        invoiceData.put('merchant_reference_no', opp.Name);
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
        if (requestMap != null) {
            ptRec.QR_Code__c = requestMap.Generate_Invoice_Result.qr_code;   
            ptRec.Merchant_Reference_No__c = requestMap.Generate_Invoice_Result.merchant_reference_no; 
            ptRec.Invoice_Id__c = requestMap.Generate_Invoice_Result.invoice_id;  
            ptRec.Error_Description__c = requestMap.Generate_Invoice_Result.error_desc; 
            ptRec.Error_Code__c = requestMap.Generate_Invoice_Result.error_code; 
            ptRec.Tiny_URL__c = requestMap.Generate_Invoice_Result.tiny_url; 
            ptRec.Invoice_Status__c = requestMap.Generate_Invoice_Result.invoice_status; 
            ptRec.Booking__c = OppId;
            ptRec.Payment_Type__c = 'Booking';

            if (ptRec != null) {
                try {
                    insert ptRec;
                    System.debug('ptRec inserted successfully: ' + ptRec.Id);

                    opp.StageName = 'Quotation Sent';
                    update oppList;
                    System.debug('Opportunity updated successfully.');

                    // Use nested queried OpportunityLineItems
                    List<OpportunityLineItem> lineItems = opp.OpportunityLineItems;
                    System.debug('Fetched nested OpportunityLineItems count: ' + lineItems.size());

                    // ➤ Add your OpportunityLineItem processing logic here
                    
                    for (OpportunityLineItem oli : lineItems) {
                        oli.Payment_Transaction__c = ptRec.Id;
                    }
                    update lineItems;
                    

                    //SendReceiptEmail.sendAsync(new List<Id>{ptRec.id});
                } catch (Exception e) {
                    System.debug('Error during insert/update: ' + e.getMessage());
                }
            }
        }
    }
}