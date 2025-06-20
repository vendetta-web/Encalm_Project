/**
* @File Name : ClearTaxIRNService .cls
* @Description : This will clear tax API for E-Invoice which will fetch IRN details and QR code
* @Author : Supriya Bassi
* @Last Modified By : Siri Sowmya
* @Last Modified On : June 12, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | June 12, 2025 |   | Initial Version
**/

public with sharing class ClearTaxIRNService {
    public static Tax_Invoice__c taxRec;
    public static Opportunity opp;
    
    @InvocableMethod(label='Call ClearTax API')
    public static void callIRNAPIFlow(List<Id> oppIds) {

        List<OpportunityLineItem> oppLineItemList;
        opp = [SELECT Id, Name, StageName, CreatedDate, Service_Type__c, Service_Airport__c, Flight_Type__c, 
               Flight_Number_Arrival__c, Flight_Number_Departure__c,Departure_Airport__c, Arriving_Airport__c, Date_of_Arrival__c, 
               Date_of_Departure__c, STA_Time__c, STD_Time__c, Departure_Service_Time__c, Arrival_Service_Time__c,
               Departure_Flight_Schedule__c, Arriving_Flight_Schedule__c, Paid_Amount__c, Total_Booking_Amount__c,
               Account.Name, Account.BillingStreet, Account.BillingCity, Account.BillingState, Account.BillingCountry, Account.BillingPostalCode,
               Account.Customer_Type__c, Account.GST__c, Account.PersonEmail, Account.Legal_Entity_Name__c, Booker__r.Name
               FROM Opportunity WHERE Id = :oppIds[0]];
        
            
        System.debug('callIRNAPIFlow -- opp-->'+opp);
        oppLineItemList = TaxInvoiceRecordHandler.getOpportunityLineItems(opp.Id, opp.StageName);
        System.debug('callIRNAPIFlow -- oppLineItemList.size()-->'+oppLineItemList.size());
        taxRec = TaxInvoiceRecordHandler.createTaxInvoiceRecord(opp, oppLineItemList); 
        System.debug('callIRNAPIFlow -- taxRec-->'+taxRec);
        IRNRequestWrapper requestPayload = buildIRNRequest(opp, oppLineItemList);
        
        String requestJson = JSON.serialize(requestPayload);
        String taxRecJson = JSON.serialize(taxRec);
        callIRNAPI(requestJson, taxRecJson, oppIds[0]);
    }
    
    // Method to perform the HTTP call
    @future(callout=true)
    public static void callIRNAPI(String requestJson, String taxRecJson, String oppId) {
        System.debug('--ENTERED -- callIRNAPI--taxRec-->');
        List<IRNRequestWrapper> lstrequestPayload = new  List<IRNRequestWrapper>();
        IRNRequestWrapper requestPayload = (IRNRequestWrapper)JSON.deserialize(requestJson, IRNRequestWrapper.class);
        lstrequestPayload.add(requestPayload);
    	taxRec = (Tax_Invoice__c)JSON.deserialize(taxRecJson, Tax_Invoice__c.class);
        System.debug('taxRec-->'+taxRec);
        
        Integer maxRetries = 3;
        Integer attempts = 0;
        Boolean success = false;
        String resBody;
        Http http = new Http();
        HttpRequest req;
        HttpResponse res;
        
        while (attempts < maxRetries && !success) 
        {
            try {
                attempts++;
                
                req = new HttpRequest();
                req.setEndpoint('https://api-sandbox.clear.in/einv/v2/eInvoice/generate');
                req.setMethod('PUT'); //POST
                req.setHeader('Content-Type', 'application/json'); 
                req.setHeader('GSTIN', '07AAFCD5862R007'); 
                req.setHeader('X-Cleartax-Auth-Token', '1.641dcef3-6ac3-47c0-8135-c5fb7af1e695_a5bcf898921b577fe7be4d82ec3f452873eac11af9d92da02866be7971efee10');
                //req.setEndpoint('callout:ClearTax_Invoice');
                //req.setHeader('Authorization', 'Bearer ' + Auth.AuthToken.getAccessToken('ClearTax_External_Credential'));
                
                String jsonBody = JSON.serialize(lstrequestPayload);
                jsonBody = jsonBody.replace('transactionWrap', 'transaction');
                req.setBody(jsonBody);
                System.debug('JSON BODY______________ + ' + jsonBody);
                
                res = http.send(req);
                System.debug('res.getStatusCode()-->'+res.getStatusCode());
                if (res.getStatusCode() == 200) {
                    resBody = res.getBody();
                    Tax_Invoice__c txRec = TaxInvoiceRecordHandler.updateClearTaxResponse(taxRec, requestJson, resBody);
                    System.debug('After update txRec-->'+txRec);
                    // TaxInvoiceController.generateTaxInvoice(oppId, 'No', txRec);
                    System.enqueueJob(new TaxInvoiceGeneratorQueuable(oppId, txRec));
                }
                else {
                    Tax_Invoice__c txRec = TaxInvoiceRecordHandler.updateClearTaxResponse(taxRec, requestJson, resBody);
                    System.debug('Failed to generate IRN. Response: ' + res.getBody());
                }
            } 
            catch (System.CalloutException e) 
            {
                System.debug('Attempt ' + attempts + ' failed: ' + e.getMessage());
                
                if (attempts >= maxRetries) {
                    // Log failure or update record with error message
                    //  TaxInvoiceRecordHandler.logOracleError(txInvRec, e.getMessage());
                } else {
                    // Optional: short pause between retries (not real delay, just logging here)
                    System.debug('Retrying in 1 second... (simulated)');
                    // Note: Apex doesn't support Thread.sleep() in normal context
                }
            }
        }
    }
    
    // Method to build request payload from Opportunity and Line Items
    public static IRNRequestWrapper buildIRNRequest(Opportunity opp, List<OpportunityLineItem> lineItems) {
        Encalm_Details__mdt encalmDtls = [SELECT Id, GSTIN__c, Legal_Name__c, Address__c, State__c, Pin_Code__c 
                                          FROM Encalm_Details__mdt WHERE DeveloperName =: opp.Service_Airport__c];
        System.debug('encalmDtls-->'+encalmDtls);
        List<TaxInvoiceRecordHandler.OppLineItemWrapper> oppLineItems = TaxInvoiceRecordHandler.prepareLineItemWrapper(opp, lineItems);
            
        IRNRequestWrapper request = new IRNRequestWrapper();
        request.transactionWrap = new IRNRequestWrapper.TransactionWrapper();
        request.transactionWrap.Version = '1.1'; // Needs to confirm
        
        // Transaction details
        request.transactionWrap.TranDtls = new IRNRequestWrapper.TransactionDtls();
        request.transactionWrap.TranDtls.TaxSch = 'GST';
        request.transactionWrap.TranDtls.SupTyp = 'B2B';
        request.transactionWrap.TranDtls.RegRev = 'Y';
        request.transactionWrap.TranDtls.IgstOnIntra = oppLineItems.size() > 0  && oppLineItems[0].igst > 0 ? 'Y' : 'N'; //Optional
        
        // Document details
        request.transactionWrap.DocDtls = new IRNRequestWrapper.DocumentDtls();
        request.transactionWrap.DocDtls.Typ = 'INV'; //INV-INVOICE, CRN-CREDIT, DBN-DEBIT NOTE  
        request.transactionWrap.DocDtls.No = '242dfsff9test'; // Need to confirm
        request.transactionWrap.DocDtls.Dt = Date.today().format();
        
        // Seller details (customize)
        IRNRequestWrapper.SellerDtls seller = new IRNRequestWrapper.SellerDtls();
        seller.Gstin = encalmDtls.GSTIN__c; //'07AAFCD5862R007'; 
        seller.LglNm = encalmDtls.Legal_Name__c;
        seller.Addr1 = encalmDtls.Address__c;
        //seller.Addr2 = ''; //Optional
        seller.Loc = encalmDtls.State__c;
        seller.Pin = Integer.valueOf(encalmDtls.Pin_Code__c);
        seller.Stcd = getStateCode(encalmDtls.State__c);
        //seller.Ph = ''; //Optional
        //seller.Em = ''; //Optional
        System.debug('seller-->'+seller);
        request.transactionWrap.SellerDtls = seller;
        
        // Buyer details
        IRNRequestWrapper.BuyerDtls buyer = new IRNRequestWrapper.BuyerDtls();
        buyer.Gstin = opp.Account.GST__c;
        buyer.LglNm = opp.Account.Legal_Entity_Name__c; 
       // buyer.TrdNm = ''; //Optional
        buyer.Pos = getStateCode(opp.Service_Airport__c); 
        buyer.Addr1 = opp.Account.BillingStreet;
       // buyer.Addr2 = ''; //Optional
        buyer.Loc = opp.Account.BillingState;
        buyer.Pin = Integer.valueOf(opp.Account.BillingPostalCode);
        buyer.Stcd = getStateCode(opp.Account.BillingState);
       // buyer.Ph = ''; //Optional
       // buyer.Em = ''; //Optional
       System.debug('buyer-->'+buyer);
        request.transactionWrap.BuyerDtls = buyer;
        
        // Item list
        request.transactionWrap.ItemList = new List<IRNRequestWrapper.ItemList>();
        Integer count = 1;
        
        Decimal totalCGST = 0;
        Decimal totalSGST = 0;
        Decimal totalIGST = 0;
        Decimal totalDiscount = 0;
        Decimal totalInvValue = 0;
        Decimal totalAssValue = 0;
        
        for (TaxInvoiceRecordHandler.OppLineItemWrapper wrapItem : oppLineItems) {
            System.debug('wrapItem-->'+wrapItem);
            IRNRequestWrapper.ItemList item = new IRNRequestWrapper.ItemList();
            item.SlNo = String.valueOf(count++);
           // item.PrdDesc = wrapItem.serviceType; //Optional
            item.IsServc = 'Y';
            item.HsnCd = String.valueOf(wrapItem.hsn_hac);
            item.Qty = wrapItem.quantity;  //Optional
            //item.Unit = 'NOS'; //Conditional Mandatory
            item.UnitPrice = wrapItem.unitPrice;
            item.Discount = wrapItem.discountAmt;
            item.TotAmt = wrapItem.unitPrice * wrapItem.quantity;
            item.AssAmt = item.TotAmt - item.Discount;
            item.GstRt = 18;
            item.CgstAmt = wrapItem.cgst; //Conditional Mandatory
            item.SgstAmt = wrapItem.sgst; //Conditional Mandatory
            item.IgstAmt = wrapItem.Igst; //Conditional Mandatory
            item.TotItemVal = item.TotAmt + (item.TotAmt * 0.18);
            request.transactionWrap.ItemList.add(item);
            
            totalCGST += item.CgstAmt;
            totalSGST += item.SgstAmt;
            totalIGST += item.IgstAmt;
            totalDiscount += wrapItem.discountAmt;
            totalAssValue += item.AssAmt;
            totalInvValue += item.TotItemVal;
            
        }
        
        
        // Value details
        IRNRequestWrapper.ValueDtls val = new IRNRequestWrapper.ValueDtls();
        val.AssVal = totalAssValue;
        val.CgstVal = totalCGST; //Conditional Mandatory
        val.SgstVal = totalSGST; //Conditional Mandatory
        val.IgstVal = totalIGST; //Conditional Mandatory
        val.Discount = totalDiscount; //Optional
        val.TotInvVal = totalInvValue;
        System.debug('val-->'+val);
        request.transactionWrap.ValDtls = val;
        
        
        
        // Default/optional sections
      /*  request.transactionWrap.PayDtls = new IRNRequestWrapper.PaymentDtls();
        request.transactionWrap.RefDtls = new IRNRequestWrapper.ReferenceDtls();
        request.transactionWrap.AddlDocDtls = new List<IRNRequestWrapper.AdditionalDocDtls>();
        request.transactionWrap.ExpDtls = new IRNRequestWrapper.ExportDtls();
        request.transactionWrap.EwbDtls = new IRNRequestWrapper.EWayBillDtls();
        request.transactionWrap.DispDtls = new IRNRequestWrapper.DispatchFromDtls();
        request.transactionWrap.ShipDtls = new IRNRequestWrapper.ShipToDtls();*/
        
        // Custom fields // optional
       // request.custom_fields = new IRNRequestWrapper.CustomFields();
       // request.custom_fields.customfieldLable1 = 'Custom 1';
       // request.custom_fields.customfieldLable2 = 'Custom 2';
        String rJSON = JSON.serialize(request);
        System.debug('rJSON-->'+rJSON);
        return request;
        
        
    }
    
    public static String getStateCode(String stateName){
        Map<String, Decimal> stateMap = new Map<String, Decimal>();
        for(State_Master__mdt st : [SELECT Id, Label, State_Short_Form__c, State_Code__c FROM State_Master__mdt]){
            stateMap.put(st.Label, st.State_Code__c);
            stateMap.put(st.State_Short_Form__c, st.State_Code__c);
            if(st.Label == 'Delhi')
                stateMap.put('DEL', st.State_Code__c);
            else if(st.Label == 'Hyderabad')
                stateMap.put('HYD', st.State_Code__c);
            else if(st.Label == 'Goa')
                stateMap.put('GOX', st.State_Code__c);
        }
        return String.valueOf(stateMap.get(stateName));
    }
    
    
}