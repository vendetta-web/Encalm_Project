public class TaxInvoiceRecordHandler {
    
    public static List<OpportunityLineItem> getOpportunityLineItems(String oppId, String oppStage){
        
        List<String> cancelledStatusList = new List<String>{'Partially Cancelled','Cancellation','Fully Cancelled'};
        List<OpportunityLineItem> oppLineItemList;
        
        if(oppStage == 'Service Rendered' || oppStage == 'No Show')
        {
            oppLineItemList = [SELECT Id, OpportunityId , CreatedDate, Product2.Name, Product2.Package_Is_For__c, Product2.Family, Quantity, 
                               UnitPrice, TotalPrice, HSN_HAC__c, Discount_Amount__c,Invoice_Amount__c,Amount_Deducted__c,SGST__c,CGST__c,IGST__c, Opportunity_Product__c
                               FROM OpportunityLineItem WHERE OpportunityId  =: oppId AND Status__c NOT IN : cancelledStatusList];
        }
        else if(oppStage == 'Cancelled')
        {
            oppLineItemList = [SELECT Id, OpportunityId , CreatedDate, Product2.Name, Product2.Package_Is_For__c, Product2.Family, Quantity, 
                               UnitPrice, TotalPrice, HSN_HAC__c, Discount_Amount__c,Invoice_Amount__c,Amount_Deducted__c,SGST__c,CGST__c,IGST__c, Opportunity_Product__c
                               FROM OpportunityLineItem WHERE OpportunityId  =: oppId AND Status__c IN : cancelledStatusList];
        }
        return oppLineItemList;
    }
    
    public static Tax_Invoice__c createTaxInvoiceRecord(Opportunity opp, List<OpportunityLineItem> lineItems){
       // List<OppLineItemWrapper> oppLineItems = prepareLineItemWrapper(opp, lineItems, isCancelledInvoice);
        List<OppLineItemWrapper> oppLineItems = prepareLineItemWrapper(opp, lineItems);
        
        System.debug('oppLineItems.size()-->'+oppLineItems.size());
        return(insertTaxInvoiceRecords(opp, oppLineItems));
    }
    
    public static List<OppLineItemWrapper> prepareLineItemWrapper(Opportunity opp, List<OpportunityLineItem> lineItems){
        System.debug('--ENTERED prepareLineItemWrapper--lineItems.size()-->'+lineItems.size());
        List<OppLineItemWrapper> oppLineItems = new List<OppLineItemWrapper>();
        Map<String, List<OpportunityLineItem>> productVsOppItemList = new Map<String, List<OpportunityLineItem>>();
        Map<Id, OpportunityLineItem> oppLineItemMap = new Map<Id, OpportunityLineItem>();
        Integer sr = 0;
        String description;
        Decimal hsn;
        Integer qty;
        Decimal unitPrice;
        Decimal invAmt;
        Decimal discAmt;
        Decimal cgst;
        Decimal sgst;
        Decimal igst;
        
        if(opp.StageName == 'Service Rendered' || opp.StageName == 'No Show'){
            for (OpportunityLineItem o : lineItems) 
            {
                oppLineItemMap.put(o.Id, o);
                String productUniqueCode = o.Product2.Name == 'Surcharge' ? 'Surcharge' : o.Product2.Name +'_'+ o.Product2.Family +'_'+ o.Product2.Package_Is_For__c;
                
                System.debug('productUniqueCode-->'+productUniqueCode);
                if (!productVsOppItemList.containsKey(productUniqueCode)) {
                    System.debug('productVsOppItemList.containsKey(productUniqueCode)-->'+productVsOppItemList.containsKey(productUniqueCode));
                    productVsOppItemList.put(productUniqueCode, new List<OpportunityLineItem>{o});
                }
                else if(!productVsOppItemList.get(productUniqueCode)[0].Product2.Name.contains('Surcharge')){
                    System.debug('productVsOppItemList.get(productUniqueCode)[0].Product2.Name-->'+productVsOppItemList.get(productUniqueCode)[0].Product2.Name);
                    productVsOppItemList.get(productUniqueCode).add(o);
                }
                else if(productVsOppItemList.get(productUniqueCode)[0].Product2.Name == 'Surcharge'){
                    if(productVsOppItemList.get(productUniqueCode)[0].CreatedDate < o.CreatedDate)
                    {
                        productVsOppItemList.get(productUniqueCode).remove(0);
                        productVsOppItemList.get(productUniqueCode).add(o);
                    }
                }
                else if(productVsOppItemList.get(productUniqueCode)[0].Product2.Name == 'Surcharge Waive Off'){
                    if(productVsOppItemList.get(productUniqueCode)[0].CreatedDate < o.CreatedDate)
                    {
                        productVsOppItemList.get(productUniqueCode).remove(0);
                        productVsOppItemList.get(productUniqueCode).add(o);
                    }
                }
            }
            
            for (String key : productVsOppItemList.keySet()) 
            {
                sr++;
                qty = 0;
                invAmt = 0;
                discAmt = 0;
                unitPrice = 0;
                cgst = 0;
                sgst = 0;
                igst = 0;
                for (OpportunityLineItem oli : productVsOppItemList.get(key)) 
                {
                    qty++;
                    invAmt += oli.Invoice_Amount__c != null ? oli.Invoice_Amount__c : 0;
                    discAmt += oli.Discount_Amount__c != null ? oli.Discount_Amount__c : 0;
                    cgst += oli.CGST__c != null ? oli.CGST__c : 0;
                    sgst += oli.SGST__c != null ? oli.SGST__c : 0;
                    igst += oli.IGST__c != null ? oli.IGST__c : 0;
                    unitPrice = oli.Invoice_Amount__c != null ? oli.Invoice_Amount__c : 0;
                    hsn = oli.HSN_HAC__c;
                    description = oli.Product2.Name;
                    if (oli.Product2.Package_Is_For__c == 'Adult' || oli.Product2.Package_Is_For__c == 'Child' || oli.Product2.Package_Is_For__c == 'Infant') 
                        description = oli.Product2.Name +'-'+ oli.Product2.Package_Is_For__c;
                }
                invAmt = invAmt.setScale(2, RoundingMode.HALF_UP);
                discAmt = discAmt.setScale(2, RoundingMode.HALF_UP);
                unitPrice = unitPrice.setScale(2, RoundingMode.HALF_UP);
                oppLineItems.add(new OppLineItemWrapper(sr, description, hsn, qty, invAmt, discAmt, unitPrice, cgst, sgst, igst));
                
            }
        }
        else if(opp.StageName == 'Cancelled'){
            for (OpportunityLineItem o : lineItems) 
            {
                String productUniqueCode = o.Product2.Package_Is_For__c != null ? o.Product2.Package_Is_For__c : o.Product2.Family;
                System.debug('productUniqueCode-->'+productUniqueCode);
                if (!productVsOppItemList.containsKey(productUniqueCode)) {
                    System.debug('productVsOppItemList.containsKey(productUniqueCode)-->'+productVsOppItemList.containsKey(productUniqueCode));
                    productVsOppItemList.put(productUniqueCode, new List<OpportunityLineItem>{o});
                }
                else{
                    productVsOppItemList.get(productUniqueCode).add(o);
                }
            }
            
            Decimal  totalAmount = 0;
            for(String prdt : productVsOppItemList.keySet()){
                sr++;
                qty = 0;
                invAmt = 0;
                discAmt = 0;
                unitPrice = 0;
                cgst = 0;
                sgst = 0;
                igst = 0;
                for (OpportunityLineItem oli : productVsOppItemList.get(prdt)) 
                {
                    System.debug('oli.Amount_Deducted__c-->'+oli.Amount_Deducted__c);
                    
                    qty++;
                    invAmt += oli.Invoice_Amount__c != null ? oli.Invoice_Amount__c : 0;
                    cgst += oli.CGST__c != null ? oli.CGST__c : 0;
                    sgst += oli.SGST__c != null ? oli.SGST__c : 0;
                    igst += oli.IGST__c != null ? oli.IGST__c : 0;
                    unitPrice = oli.Invoice_Amount__c != null ? oli.Invoice_Amount__c : 0;
                    hsn = oli.HSN_HAC__c;
                    description = 'Cancellation';
                }
                // taxableAmount += totalInvoice;
                invAmt = invAmt.setScale(2, RoundingMode.HALF_UP);
                unitPrice = unitPrice.setScale(2, RoundingMode.HALF_UP);
                
                oppLineItems.add(new OppLineItemWrapper(sr, description, hsn, qty, invAmt, discAmt, unitPrice, cgst, sgst, igst));
                
            }
        }
        return oppLineItems;
    }
    
    public static Tax_Invoice__c insertTaxInvoiceRecords(Opportunity opp, List<OppLineItemWrapper> oppLineItems){
        Tax_Invoice__c taxRec = new Tax_Invoice__c();
        taxRec.Opportunity__c = opp.Id;
        taxRec.Invoice_Date__c = System.Today();
        insert taxRec;
        
        List<Tax_Invoice_Item__c> taxItemListToInsert = new List<Tax_Invoice_Item__c>();
        Tax_Invoice_Item__c taxItemRec;
        for(OppLineItemWrapper lineItem : oppLineItems){
            System.debug('lineItem.serviceType-->'+lineItem.description);
            taxItemRec = new Tax_Invoice_Item__c();
            taxItemRec.Tax_Invoice__c = taxRec.Id;
            taxItemRec.HSN_Code__c = lineItem.hsn_hac;
            taxItemRec.GST_Rate__c = 18;
            taxItemRec.Product_Description__c = lineItem.description;
            taxItemRec.Quantity__c = lineItem.quantity;
            taxItemRec.Unit_Price__c = lineItem.unitPrice;
            taxItemRec.Discount__c = lineItem.discountAmt;
            taxItemRec.CGST_Amount__c = lineItem.cgst;
            taxItemRec.SGST_Amount__c = lineItem.sgst;
            taxItemRec.IGST_Amount__c = lineItem.igst;
            taxItemRec.Invoice_Amount__c = lineItem.unitPrice * lineItem.quantity;
            taxItemRec.Total_Item_Value__c = lineItem.invoiceAmt + (lineItem.invoiceAmt * 0.18);
            
            taxItemRec.CGST_Amount__c.setScale(2, RoundingMode.HALF_UP);
            taxItemRec.SGST_Amount__c.setScale(2, RoundingMode.HALF_UP);
            taxItemRec.IGST_Amount__c.setScale(2, RoundingMode.HALF_UP);
            taxItemRec.Total_Item_Value__c.setScale(2, RoundingMode.HALF_UP);
            
            taxItemListToInsert.add(taxItemRec);
        }
        if(taxItemListToInsert.size() > 0)
            insert taxItemListToInsert;
        
        return taxRec;
    }
    
    public static Tax_Invoice__c updateClearTaxResponse(Tax_Invoice__c txRec, String req, String resp){
        System.debug('--Entered --updateTaxInvoiceRecord--response-->'+resp);
        Tax_Invoice__c tx;
        List<IRNResponseWrapper.IRNResponse> responses = IRNResponseWrapper.parse(resp);
			System.debug('responses[0]--> ' + responses[0]);
        System.debug('responses[0].govt_response--> ' + responses[0].govt_response);

        if (responses != null && !responses.isEmpty()) {
            IRNResponseWrapper.IRNResponse irnData = responses[0];
           // IRNResponseWrapper.GovtResponse govtRes = responses[0].govt_response; 
            
            System.debug('irnData-->'+irnData);
            
            tx = txRec;
            tx.Transaction_ID__c = irnData.transaction_id;
            tx.Document_Status__c = irnData.document_status;
            tx.IRN__c = irnData.govt_response.Irn;
            tx.Acknowledgement_Number__c = irnData.govt_response.AckNo;
            tx.Acknowledgement_Date__c = Date.valueOf(irnData.govt_response.AckDt);
            tx.Signed_Invoice__c = irnData.govt_response.SignedInvoice;
            tx.Signed_QR_Code__c = irnData.govt_response.SignedQRCode;
            tx.EWB_Number__c = irnData.govt_response.EwbNo; 
            tx.EWB_Date__c = irnData.govt_response.EwbDt != null ? DateTime.valueOf(irnData.govt_response.EwbDt) : null; 
            tx.EWB_Valid_Till__c = irnData.govt_response.EwbValidTill != null ? DateTime.valueOf(irnData.govt_response.EwbValidTill) : null;
            tx.ClearTax_request_json__c = req;
            tx.ClearTax_response_json__c = resp;
            tx.ClearTax_Retry_Count__c = tx.ClearTax_Retry_Count__c != null ? tx.ClearTax_Retry_Count__c+1 : 1;
            update tx;
        }
        return tx; 
    }
    
    public static void updateOracleResponse(Tax_Invoice__c txRec, String req, String resp, String status){
        Tax_Invoice__c tx = txRec;
        tx.Sent_to_Oracle__c = true;
        tx.Oracle_request_json__c = req;
        tx.Oracle_response_json__c = resp;
        tx.Oracle_Status__c = status;
        tx.Oracle_Retry_Count__c = tx.Oracle_Retry_Count__c != null ? tx.Oracle_Retry_Count__c+1 : 1;
        update tx;
    }
    
    public class OppLineItemWrapper {
        public Integer SrNo { get; set; }
        public String description { get; set; }
        public Decimal hsn_hac { get; set; }
        public Integer quantity { get; set; }
        public Decimal invoiceAmt { get; set; }
        public Decimal discountAmt { get; set; }
        public Decimal unitPrice { get; set; }
        public Decimal cgst { get; set; }
        public Decimal sgst { get; set; }
        public Decimal igst { get; set; }
        
        public OppLineItemWrapper(Integer srNo, String description, Decimal hsn_hac, Integer quantity, Decimal invoiceAmt, Decimal discountAmt, Decimal unitPrice, Decimal cgst, Decimal sgst, Decimal igst) {
            this.SrNo = srNo;
            this.description = description;
            this.hsn_hac = hsn_hac;
            this.quantity = quantity;
            this.invoiceAmt = invoiceAmt;
            this.discountAmt = discountAmt;
            this.unitPrice = unitPrice;
            this.cgst = cgst;
            this.sgst = sgst;
            this.igst = igst;
        }
    }
    
}