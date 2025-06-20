public class TaxInvoiceController {
    public static Opportunity opp { get; set; }
    public Tax_Invoice__c taxInv { get; set; } 
    public List<TaxInvoiceRecordHandler.OppLineItemWrapper> oppLineItems { get; set; }
    public List<PassengerWrapper> passengers { get; set; }
    public List<FlightDetailsWrapper> flightDetails { get; set; }
    public ServiceDetailsWrapper serviceDetails { get; set; }
    public ExtraDetailsWrapper extraDetails { get; set; } 
   /* public String irnVal { get; set; } 
    public String ackNo { get; set; } 
    public String ackDt { get; set; } */
    public String QRCodeUrl { get; set; }
        
    public TaxInvoiceController() {
        String recordId = ApexPages.currentPage().getParameters().get('recordId');
       // String isCancelledTaxInvoice = ApexPages.currentPage().getParameters().get('isCancelled');
        String taxId = ApexPages.currentPage().getParameters().get('taxInvId');
        /*irnVal = ApexPages.currentPage().getParameters().get('irn');
        ackNo = ApexPages.currentPage().getParameters().get('ackNum');
        ackDt = ApexPages.currentPage().getParameters().get('ackDate');*/
        
        
        Decimal totalSGST = 0;
        Decimal totalCGST = 0;
        Decimal totalIGST = 0;
        Decimal taxableAmount = 0;
        Decimal totalAmount = 0;
        Decimal paidAmount = 0;
        Decimal dueAmount = 0;
        String totalAmountInWords;
        Boolean hasDiscount = false;
        String formattedTodayDate;
        
        String flightNum;
        String airline;
        String terminal;
        String flightDateTime;
        String serviceDateTime;
        String fromAirport;
        String toAirport;
        List<OpportunityLineItem> oppLineItemList;
        List<Passenger_Details__c> passengerRecords;
        
        if (String.isNotBlank(recordId)) {
            //try {
            // 🔹 Fetch Opportunity Record
            List<String> statusList = new List<String>{'Partially Cancelled','Cancellation','Fully Cancelled'};
            List<Id> oppLineItemIds = new List<Id>();
            
             
            opp = [SELECT Id, Name, StageName, CreatedDate, Service_Type__c, Service_Airport__c, Flight_Type__c, 
                   Flight_Number_Arrival__c, Flight_Number_Departure__c,Departure_Airport__c, Arriving_Airport__c, Date_of_Arrival__c, 
                   Date_of_Departure__c, STA_Time__c, STD_Time__c, Departure_Service_Time__c, Arrival_Service_Time__c,
                   Departure_Flight_Schedule__c, Arriving_Flight_Schedule__c, Paid_Amount__c, Total_Booking_Amount__c,
                   Account.Name, Account.BillingStreet, Account.BillingCity, Account.BillingState, Account.BillingCountry, Account.BillingPostalCode,
                   Account.Customer_Type__c, Account.GST__c, Account.PersonEmail, Booker__r.Name
                   FROM Opportunity WHERE Id = :recordId];
            
            if(opp.StageName == 'Service Rendered' || opp.StageName == 'No Show')
            {
                oppLineItemList = TaxInvoiceRecordHandler.getOpportunityLineItems(opp.Id, opp.StageName);
                passengerRecords  = [SELECT Id, Name, Age__c, Travel_Class__c,Travel_PNR_No__c, Airline_PNR__c FROM Passenger_Details__c 
                                     WHERE Opportunity_ID__c = :recordId AND Individual_Booking_Details__r.Status__c NOT IN : statusList];
                
                for (OpportunityLineItem oli : opp.OpportunityLineItems) {
                    if (oli.Discount_Amount__c != null && oli.Discount_Amount__c != 0) {
                        hasDiscount = true;
                        break;
                    }
                }
            }
            else if(opp.StageName == 'Cancelled')
            {
                oppLineItemList = TaxInvoiceRecordHandler.getOpportunityLineItems(opp.Id, opp.StageName);
                System.debug('TaxInvoiceController -- oppLineItemList.size()--->'+oppLineItemList.size());
                 for(OpportunityLineItem oli: opp.OpportunityLineItems){
                    oppLineItemIds.add(oli.Id); 
                }
                
                passengerRecords  = [SELECT Id, Name, Age__c, Travel_Class__c,Travel_PNR_No__c, Airline_PNR__c FROM Passenger_Details__c 
                                     WHERE Opportunity_ID__c = :recordId AND Individual_Booking_Details__c IN : oppLineItemIds];
            }
            
           
          
            System.debug('Successfully fetched Opportunity record.');
            
            //Process Tax Invoice Details
            List<Tax_Invoice__c> taxInvList = [SELECT Id, Name, IRN__c, Acknowledgement_Number__c, Acknowledgement_Date__c, Signed_QR_Code__c
                                               FROM Tax_Invoice__c WHERE Id = :taxId];
            
            if (!taxInvList.isEmpty()) {
                taxInv = taxInvList[0]; 
            } 
            if(opp.Account.Customer_Type__c == 'B2B'){
                if (String.isNotEmpty(taxInv.Signed_QR_Code__c)) {
                    // Generate QR Code URL
                    String encodedJwt = EncodingUtil.urlEncode(taxInv.Signed_QR_Code__c, 'UTF-8');
                    QRCodeUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=' + encodedJwt;
                }
            }
            
            //Process Passenger Details
            passengers = new List<PassengerWrapper>();
            Integer counter = 1;
            for (Passenger_Details__c p : passengerRecords) {
                passengers.add(new PassengerWrapper(counter, p));
                counter++;
            }
            
            //Process Opportunity Line Items
            List<TaxInvoiceRecordHandler.OppLineItemWrapper> oppLineItemWrapList = new List<TaxInvoiceRecordHandler.OppLineItemWrapper>();
            Map<String, List<OpportunityLineItem>> productVsOppItemList = new Map<String, List<OpportunityLineItem>>();
            
            if(opp.StageName == 'Service Rendered' || opp.StageName == 'No Show')//if(isCancelledTaxInvoice == 'No')
            {
                System.debug('isCancelledTaxInvoice -- NO -- ENtered');
                oppLineItemWrapList = TaxInvoiceRecordHandler.prepareLineItemWrapper(opp, oppLineItemList);
                for(TaxInvoiceRecordHandler.OppLineItemWrapper wrap : oppLineItemWrapList){
                    System.debug('wrap-->'+wrap);
                    totalSGST += wrap.sgst; //o.SGST__c != null  ? o.SGST__c : 0;
                    totalCGST += wrap.cgst; //o.CGST__c != null  ? o.CGST__c : 0;
                    totalIGST += wrap.igst; //o.IGST__c != null  ? o.IGST__c : 0;
                    taxableAmount += wrap.invoiceAmt; //o.Invoice_Amount__c != null  ? o.Invoice_Amount__c : 0;
                    
                    totalSGST = totalSGST.setScale(2, RoundingMode.HALF_UP);
                    totalCGST = totalCGST.setScale(2, RoundingMode.HALF_UP);
                    totalIGST = totalIGST.setScale(2, RoundingMode.HALF_UP);
                    taxableAmount = taxableAmount.setScale(2, RoundingMode.HALF_UP);
                }
                
                totalAmount = opp.Total_Booking_Amount__c; 
                totalAmountInWords = NumberToWordsUtil.convertNumberToWords(totalAmount); 
                
            }
            else if(opp.StageName == 'Cancelled') //else if(isCancelledTaxInvoice == 'Yes')
            {
                oppLineItemWrapList = TaxInvoiceRecordHandler.prepareLineItemWrapper(opp, oppLineItemList);
                for(TaxInvoiceRecordHandler.OppLineItemWrapper wrap : oppLineItemWrapList){
                    totalSGST += wrap.sgst; //o.SGST__c != null  ? o.SGST__c : 0;
                    totalCGST += wrap.cgst; //o.CGST__c != null  ? o.CGST__c : 0;
                    totalIGST += wrap.igst; //o.IGST__c != null  ? o.IGST__c : 0;
                    taxableAmount += wrap.invoiceAmt; //totalInvoice;
                    
                    totalSGST = totalSGST.setScale(2, RoundingMode.HALF_UP);
                    totalCGST = totalCGST.setScale(2, RoundingMode.HALF_UP);
                    totalIGST = totalIGST.setScale(2, RoundingMode.HALF_UP);
                    taxableAmount = taxableAmount.setScale(2, RoundingMode.HALF_UP);
                    
                }
                totalAmount = totalIGST > 0 ? taxableAmount + totalIGST : taxableAmount + totalCGST + totalSGST;
                totalAmount = totalAmount.setScale(2, RoundingMode.HALF_UP);
                totalAmountInWords = NumberToWordsUtil.convertNumberToWords(totalAmount); 
                
            }
            oppLineItems = oppLineItemWrapList;
            
            //Process Extra Details
            String stateCode = getStateCode(opp.Account.BillingState);
            Date todayDate = System.today();
        	formattedTodayDate = DateTime.newInstance(todayDate.year(), todayDate.month(), todayDate.day()).format('dd-MMM-yyyy');
            
            String discountColumnStyle = hasDiscount ? '' : 'display:none;';
            extraDetails = new ExtraDetailsWrapper(stateCode, taxableAmount, paidAmount, dueAmount, totalSGST, totalCGST, 
                                     totalIGST, totalAmount, totalAmountInWords, formattedTodayDate, discountColumnStyle);
            
            
            // Process Flight Details
            Map<Id, Flight_Schedule__c> flightSchMap = new Map<Id, Flight_Schedule__c>(
                [SELECT id, Name,Flight_Detail__r.Airline_Id__c, Flight_Detail__r.Airline_Id__r.Airline_Name__c, 
                 Arrival_Terminal__r.Name, Departure_Terminal__r.Name 
                 FROM Flight_Schedule__c 
                 WHERE Id =: opp.Arriving_Flight_Schedule__c OR Id =: opp.Departure_Flight_Schedule__c  ]);
            
            flightDetails = new List<FlightDetailsWrapper>();
            if(opp.Arriving_Flight_Schedule__c != null){
                flightNum = opp.Flight_Number_Arrival__c;
                flightDateTime = opp.Date_of_Arrival__c +' '+ opp.STA_Time__c;
                airline =  flightSchMap.get(opp.Arriving_Flight_Schedule__c).Flight_Detail__r.Airline_Id__c != null ? flightSchMap.get(opp.Arriving_Flight_Schedule__c).Flight_Detail__r.Airline_Id__r.Airline_Name__c : '';
                terminal = flightSchMap.get(opp.Arriving_Flight_Schedule__c).Arrival_Terminal__r.Name;
                flightDetails.add(new FlightDetailsWrapper(flightNum, flightDateTime, airline, terminal));
                
                fromAirport = opp.Departure_Airport__c;
                toAirport = opp.Service_Airport__c;
                if(opp.Service_Type__c == 'Transit' || opp.Service_Type__c == 'Arrival')
                    serviceDateTime = opp.Date_of_Arrival__c +' '+ opp.Arrival_Service_Time__c;
            }
            if(opp.Departure_Flight_Schedule__c != null){
                flightNum = opp.Flight_Number_Departure__c;
                flightDateTime = opp.Date_of_Departure__c +' '+ opp.STD_Time__c;
                airline =  flightSchMap.get(opp.Departure_Flight_Schedule__c).Flight_Detail__r.Airline_Id__c != null ? flightSchMap.get(opp.Departure_Flight_Schedule__c).Flight_Detail__r.Airline_Id__r.Airline_Name__c : '';
                terminal = flightSchMap.get(opp.Departure_Flight_Schedule__c).Departure_Terminal__r.Name;
                flightDetails.add(new FlightDetailsWrapper(flightNum, flightDateTime, airline, terminal));
                
                fromAirport = opp.Service_Airport__c;
                toAirport = opp.Arriving_Airport__c;
                if(opp.Service_Type__c == 'Departure')
                    serviceDateTime = opp.Date_of_Departure__c +' '+ opp.Departure_Service_Time__c;
            }
            
            //Process Service Details
            serviceDetails = new ServiceDetailsWrapper(serviceDateTime, String.valueof(opp.CreatedDate), opp.Service_Airport__c, opp.Flight_Type__c, fromAirport, toAirport);
            
            
            /*} catch (Exception e) {
System.debug('ERROR: Failed to fetch data in VF Controller - ' + e.getMessage());
}*/
        } else {
            System.debug('ERROR: No recordId found.');
        }
    }
    
    
    @InvocableMethod(label='Generate Tax Invoice PDF')
    public static void generateInvoice(List<Id> opportunityIds)
    {
        System.debug('Entered --generateInvoice--from Flow');
        Tax_Invoice__c txInvRec = createTaxRecords(opportunityIds[0]);
        System.enqueueJob(new TaxInvoiceGeneratorQueuable(opportunityIds[0], txInvRec));
    }
    
  /*  @AuraEnabled
    public static void generateCancelledTaxInvoice(String recordId) {
        System.debug('Entered --generateCancelledTaxInvoice--from LWC');
        Tax_Invoice__c txInvRec = createTaxRecords( recordId, 'Yes');
        //generateTaxInvoice(recordId, 'Yes', txInvRec);
        System.enqueueJob(new TaxInvoiceGeneratorQueuable(recordId, 'Yes', txInvRec));
    }*/
    
    public static void generateTaxInvoice(Id oppId, Tax_Invoice__c txInvRec)
    {
        // try
        //{
        System.debug('-- ENtered generateTaxInvoice--txInv-->'+txInvRec);
        
        // Call VF Page with only `recordId`
        PageReference pdfPage = Page.TaxInvoice;
        pdfPage.getParameters().put('recordId', oppId);
      //  pdfPage.getParameters().put('isCancelled', isCancelledInvoice);
		pdfPage.getParameters().put('taxInvId', txInvRec.Id);
        
        // Generate PDF Blob
        Blob pdfBlob;
        if (Test.IsRunningTest())
            pdfBlob = Blob.valueOf('UNIT.TEST');
        else
            pdfBlob = pdfPage.getContent();
        System.debug('pdfBlob-->'+pdfBlob);
        
        String todayDate = System.now().format();
        // Save Tax invoice as File in Salesforce
        ContentVersion cv = new ContentVersion(
            Title = 'Tax_Invoice_' + todayDate + '.pdf',
            PathOnClient = 'Tax_Invoice_' + todayDate + '.pdf',
            VersionData = pdfBlob,
            IsMajorVersion = true
        );
        insert cv;
        
        // Attach Tax invoice to Opportunity
        ContentDocument contentDocument = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :cv.Id LIMIT 1];
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
        contentDocumentLink.ContentDocumentId = contentDocument.Id;
        contentDocumentLink.LinkedEntityId = oppId;
        contentDocumentLink.ShareType = 'V';
        contentDocumentLink.Visibility = 'AllUsers';
        insert contentDocumentLink;
        
        System.debug('Tax invoice successfully generated and attached.');
        
        sendTaxInvoiceEmail(pdfBlob, oppId);
        
       // if(true) //if(isCancelledInvoice == 'Yes')
         //   updateIsTaxInvoicedOnOppLineItems(oppId);
        
        
        callOracleAPI(oppId, txInvRec);
        
        
        
        /* } catch (Exception e) {
System.debug('ERROR: Failed to generate PDF - ' + e.getMessage());
throw new AuraHandledException('Failed to generate PDF: ' + e.getMessage());
}*/
    }
    
    public static void callOracleAPI(Id oppId, Tax_Invoice__c txInv){
        List<OpportunityLineItem> oppLineItemList;
        opp = [SELECT Id, Name, StageName, CreatedDate, Service_Type__c, Service_Airport__c, Flight_Type__c, 
               Flight_Number_Arrival__c, Flight_Number_Departure__c,Departure_Airport__c, Arriving_Airport__c, Date_of_Arrival__c, 
               Date_of_Departure__c, STA_Time__c, STD_Time__c, Departure_Service_Time__c, Arrival_Service_Time__c,
               Departure_Flight_Schedule__c, Arriving_Flight_Schedule__c, Paid_Amount__c, Total_Booking_Amount__c,
               Account.Name, Account.BillingStreet, Account.BillingCity, Account.BillingState, Account.BillingCountry, Account.BillingPostalCode,
               Account.Customer_Type__c, Account.GST__c, Account.PersonEmail, Booker__r.Name
               FROM Opportunity WHERE Id = :oppId];
        
        oppLineItemList = TaxInvoiceRecordHandler.getOpportunityLineItems(opp.Id, opp.StageName);
        
         System.debug('callOracleAPI--opp-->'+opp);
        System.debug('callOracleAPI--oppLineItemList.size()-->'+oppLineItemList.size());
        System.debug('txInv-->'+txInv);
        String oppStr = JSON.serialize(opp);
    	String oppLineItemStr = JSON.serialize(oppLineItemList);
        String txInvStr = JSON.serialize(txInv);
        System.debug('Before oracle calling - txInvStr-->'+txInvStr);
        
       // System.enqueueJob(new OracleInvoiceQueuableService(oppStr, oppLineItemStr, txInvStr));
        OracleInvoiceService.createInvoice(oppStr, oppLineItemStr, txInvStr);
    }
    
    
    public static Tax_Invoice__c createTaxRecords(Id oppId){
        opp = [SELECT Id, Name, StageName, CreatedDate, Service_Type__c, Service_Airport__c, Flight_Type__c, 
               Flight_Number_Arrival__c, Flight_Number_Departure__c,Departure_Airport__c, Arriving_Airport__c, Date_of_Arrival__c, 
               Date_of_Departure__c, STA_Time__c, STD_Time__c, Departure_Service_Time__c, Arrival_Service_Time__c,
               Departure_Flight_Schedule__c, Arriving_Flight_Schedule__c, Paid_Amount__c, Total_Booking_Amount__c,
               Account.Name, Account.BillingStreet, Account.BillingCity, Account.BillingState, Account.BillingCountry, Account.BillingPostalCode,
               Account.Customer_Type__c, Account.GST__c, Account.PersonEmail, Booker__r.Name
               FROM Opportunity WHERE Id = :oppId];
        
        List<OpportunityLineItem> oppLineItemList = TaxInvoiceRecordHandler.getOpportunityLineItems(opp.Id, opp.StageName);
        Tax_Invoice__c newTaxInv = TaxInvoiceRecordHandler.createTaxInvoiceRecord(opp, oppLineItemList);
        System.debug('newTaxInv-->'+newTaxInv);
        return newTaxInv;
    }
    
    
   /* public static void updateIsTaxInvoicedOnOppLineItems(Id oppId){
        List<String> statusList = new List<String>{'Partially Cancelled','Cancellation','Fully Cancelled'};
            List<OpportunityLineItem> oppLineItems = [SELECT Id,  OpportunityId, Status__c FROM OpportunityLineItem
                                                      WHERE OpportunityId =: oppId AND Status__c IN : statusList];
        for(OpportunityLineItem item : oppLineItems){
            item.is_Tax_Invoiced__c  = true; 
        }
        
        Update oppLineItems;
    }*/
    
    
    public static void sendTaxInvoiceEmail(Blob pdfBlob, Id oppRecId){
        
        Opportunity o = [SELECT Id, Account.Name, Account.PersonEmail, Account.Customer_Type__c, Booker__r.Email FROM Opportunity WHERE Id =: oppRecId];
        
        String toAddress = o.Account.Customer_Type__c == 'B2B' ? o.Booker__r.Email : o.Account.PersonEmail;
        
        Messaging.EmailFileAttachment pdfAttachment = new Messaging.EmailFileAttachment();
        pdfAttachment.setFileName('Tax_Invoice_' + System.now().format() + '.pdf');
        pdfAttachment.setBody(pdfBlob);
        pdfAttachment.setContentType('application/pdf');
        
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[] { toAddress });
        //email.setReplyTo(replyAddress); //Add the proper reply address
        email.setSubject('Tax Invoice for Your Recent Service');
        email.setPlainTextBody('Dear ' + o.Account.Name + ',\n\nPlease find attached the tax invoice for your recent service.\n\nThank you.\nENCALM HOSPITALITY');
        email.setFileAttachments(new Messaging.EmailFileAttachment[] { pdfAttachment });
        
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
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
    
    public String formattedIRN {
    get {
        if (taxInv != null && taxInv.IRN__c != null) {
            String irn = taxInv.IRN__c;
            Integer chunkSize = 30;
            String result = '';
            for (Integer i = 0; i < irn.length(); i += chunkSize) {
                Integer last = Math.min(i + chunkSize, irn.length());
                result += irn.substring(i, last) + '<br/>';
            }
            return result;
        }
        return '';
    }
}
    
    // Passenger Details Wrapper class to add Sr. No.
    public class PassengerWrapper {
        public Integer SrNo { get; set; }
        public Passenger_Details__c Passenger { get; set; }
        
        public PassengerWrapper(Integer srNo, Passenger_Details__c passenger) {
            this.SrNo = srNo;
            this.Passenger = passenger;
        }
    }
    
    // Opportunity Line Item Wrapper class
   /* public class OppLineItemWrapper {
        public Integer SrNo { get; set; }
        public String serviceType { get; set; }
        public Decimal hsn_hac { get; set; }
        public Integer quantity { get; set; }
        public Decimal invoiceAmt { get; set; }
        public Decimal discountAmt { get; set; }
        public Decimal unitPrice { get; set; }
        //public OpportunityLineItem oppLineItem { get; set; }
        
        public OppLineItemWrapper(Integer srNo, String serviceType, Decimal hsn_hac, Integer quantity, Decimal invoiceAmt, Decimal discountAmt, Decimal unitPrice) {
            this.SrNo = srNo;
            this.serviceType = serviceType;
            this.hsn_hac = hsn_hac;
            this.quantity = quantity;
            this.invoiceAmt = invoiceAmt;
            this.discountAmt = discountAmt;
            this.unitPrice = unitPrice;
            // this.oppLineItem = oppLineItem;
        }
    }*/
    
    // Flight Details Wrapper class
    public class FlightDetailsWrapper{
        public String flightNo { get; set; }
        public String flightDateTime { get; set; }
        public String airline { get; set; }
        public String terminal { get; set; }
        
        public FlightDetailsWrapper(String flightNo, String flightDateTime, String airline, String terminal) {
            System.debug('--- Entered FlightDetailsWrapper---');
            this.flightNo = flightNo;
            this.flightDateTime = flightDateTime;
            this.airline = airline;
            this.terminal = terminal;
        }
    }
    
    // Service Details Wrapper class
    public class ServiceDetailsWrapper{
        public String serviceDateTime { get; set; }
        public String bookingDateTime { get; set; }
        public String serviceAirport { get; set; }
        public String sectorOfTravel { get; set; }
        public String fromAirport { get; set; }
        public String toAirport { get; set; }
        
        public ServiceDetailsWrapper(String serviceDateTime, String bookingDateTime, String serviceAirport, String sectorOfTravel, String fromAirport, String toAirport) {
            this.serviceDateTime = serviceDateTime;
            this.bookingDateTime = bookingDateTime;
            this.serviceAirport = serviceAirport;
            this.sectorOfTravel = sectorOfTravel;
            this.fromAirport = fromAirport;
            this.toAirport = toAirport;
        }
        
    }
    
    public class ExtraDetailsWrapper{
        public String stateCode { get; set; }
        public Decimal taxableAmount { get; set; }
        public Decimal paidAmount { get; set; }
        public Decimal dueAmount { get; set; }
        public Decimal totalSGST { get; set; }
        public Decimal totalCGST { get; set; }
        public Decimal totalIGST { get; set; }
        public Decimal totalAmount { get; set; }
        public String totalAmountInWords {get; set; }
        public String formattedTodayDate { get; set; }
        public String discountColumnStyle { get; set; }
    	
        
        public ExtraDetailsWrapper(String stateCode, Decimal taxableAmount, Decimal paidAmount, Decimal dueAmount, Decimal totalSGST, Decimal totalCGST, 
                                     Decimal totalIGST, Decimal totalAmount, String totalAmountInWords, String formattedTodayDate, String discountColumnStyle) {
            this.stateCode = stateCode;
            this.taxableAmount = taxableAmount;
            this.paidAmount = paidAmount;
            this.dueAmount = dueAmount;
            this.totalSGST = totalSGST;
            this.totalCGST = totalCGST;
            this.totalIGST = totalIGST;
            this.totalAmount = totalAmount;
            this.totalAmountInWords = totalAmountInWords;
            this.formattedTodayDate = formattedTodayDate;
            this.discountColumnStyle = discountColumnStyle;
        }
    }
    
}