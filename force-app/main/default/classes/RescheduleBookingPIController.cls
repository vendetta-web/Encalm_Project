public class RescheduleBookingPIController {
    @AuraEnabled
    public static void createContentVersion(String recordId, String base64Data) {
        try {
            // Decode the Base64 PDF data
            Blob pdfBlob = EncodingUtil.base64Decode(base64Data);
            
            // Create ContentVersion to upload the file
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.Title = 'Generated_PDF';
            contentVersion.PathOnClient = 'Generated_PDF.pdf';
            contentVersion.VersionData = pdfBlob;
            contentVersion.IsMajorVersion = true;
            
            // Insert ContentVersion
            insert contentVersion;
            
            // Get ContentDocumentId after insert
            ContentDocument contentDocument = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :contentVersion.Id LIMIT 1];
            
            // Create ContentDocumentLink to link the file to the record
            ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
            contentDocumentLink.ContentDocumentId = contentDocument.Id;
            contentDocumentLink.LinkedEntityId = recordId;  // Link to the record (Account, Opportunity, etc.)
            contentDocumentLink.ShareType = 'V';  // 'V' for Viewer access
            contentDocumentLink.Visibility = 'AllUsers';  // Can be 'AllUsers' or 'InternalUsers'
            
            // Insert the ContentDocumentLink to associate the file with the record
            insert contentDocumentLink;
            
            System.debug('File successfully attached to record');
        } catch (Exception e) {
            System.debug('Error while creating file: ' + e.getMessage());
            throw new AuraHandledException('Error while creating file: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String generateAndSavePDF(String recordId) {
        try {
            // Call VF Page with only `recordId`
            PageReference pdfPage = Page.RescheduleBookingProformaInvoice;
            pdfPage.getParameters().put('recordId', recordId);
            System.debug('DEBUG: Calling VF Page with recordId: ' + recordId);
            
            // Generate PDF Blob
            Blob pdfBlob;
            if (Test.IsRunningTest())
            {
                pdfBlob = Blob.valueOf('UNIT.TEST');
            }
            else
            {
                pdfBlob = pdfPage.getContent();
            }
            String todayDate = System.now().format();
            
            ContentVersion cv = new ContentVersion(
                Title = 'Proforma_Invoice_' + todayDate + '.pdf',
                PathOnClient = 'Proforma_Invoice_' + todayDate + '.pdf',
                VersionData = pdfBlob,
                IsMajorVersion = true
            );
            insert cv;
            
            // Attach PDF to Opportunity
            ContentDocument contentDocument = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :cv.Id LIMIT 1];
            ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
            contentDocumentLink.ContentDocumentId = contentDocument.Id;
            contentDocumentLink.LinkedEntityId = recordId;
            contentDocumentLink.ShareType = 'V';
            contentDocumentLink.Visibility = 'AllUsers';
            insert contentDocumentLink;
            
            System.debug('PDF successfully generated and attached.');
            
            //Logic to update opportunity stage once voucher is created
            Opportunity opp = [SELECT Id, StageName FROM Opportunity WHERE Id = :recordId LIMIT 1];
            if (opp.StageName == 'Quotation' || opp.StageName == null || opp.StageName == '') {                
                opp.StageName = 'Quotation Sent';            
                // Update the Opportunity record
                update opp;
            }
            
            return opp.StageName;
            
        } catch (Exception e) {
            System.debug('ERROR: Failed to generate PDF - ' + e.getMessage());
            throw new AuraHandledException('Failed to generate PDF: ' + e.getMessage());
        }
    }
    
    public Opportunity opp { get; set; }
    Public List<Order_Request__c> orderRequestList {get; set;}
    Public List<Passenger_Details__c> passengerRecords {get; set;}
    public Decimal totalAmount { get; set; }
    public Decimal paidAmount { get; set; }
    public Decimal dueAmount { get; set; }
    public Decimal totalSGST { get; set; }
    public Decimal totalCGST { get; set; }
    public Decimal totalIGST { get; set; }
    public Decimal taxableAmount { get; set; }
    public String totalAmountInWords {get; set; }
    public String formattedTodayDate { get; set; }
    public List<orderRequestWrapper> orderRequestRecords{ get; set; }
    public List<PassengerWrapper> passengers { get; set; }
    public List<FlightDetailsWrapper> flightDetails { get; set; }
    public ServiceDetailsWrapper serviceDetails { get; set; }
    public String stateCode { get; set; } 
    public Boolean hasDiscount { get; set; }
    public Boolean hide { get; set; }
    
    
    public RescheduleBookingPIController() {
        String recordId = ApexPages.currentPage().getParameters().get('recordId');
        System.debug(' DEBUG: Received recordId in VF Controller: ' + recordId);
        hasDiscount = false;
        hide = false;
        
        Date todayDate = System.today();
        formattedTodayDate = DateTime.newInstance(todayDate.year(), todayDate.month(), todayDate.day()).format('dd-MMM-yyyy');
        
        String flightNum;
        String airline;
        String terminal;
        String flightDateTime;
        String serviceDateTime;
        String fromAirport;
        String toAirport;
        
        if (String.isNotBlank(recordId)) {
            List<String> statusList = new List<String>{'Partially Cancelled','Cancellation','Fully Cancelled'};
                opp = [SELECT Id, Name, CreatedDate, Service_Type__c, Service_Airport__c, Flight_Type__c,Service_Airport_Id__r.State__c, 
                       Flight_Number_Arrival__c, Flight_Number_Departure__c,Departure_Airport__c, Arriving_Airport__c, Date_of_Arrival__c, 
                       Date_of_Departure__c, STA_Time__c, STD_Time__c, Departure_Service_Time__c, Arrival_Service_Time__c,
                       Departure_Flight_Schedule__c, Arriving_Flight_Schedule__c, Paid_Amount__c, Total_Booking_Amount__c,
                       Account.Name, Account.BillingState, Account.BillingCountry, Account.GST__c,
                       //(SELECT Id, Name, Age__c, Travel_Class__c,Travel_PNR_No__c, Airline_PNR__c FROM Passenger_Details__r),
                       (SELECT Id, CreatedDate, Product2.Name, Product2.Package_Is_For__c, Product2.Family, Quantity, UnitPrice, TotalPrice, HSN_HAC__c, 
                        Discount_Amount__c,Invoice_Amount__c,SGST__c,CGST__c,IGST__c, Opportunity_Product__c
                        FROM OpportunityLineItems WHERE Status__c NOT IN : statusList )
                       FROM Opportunity WHERE Id = :recordId];
            
            System.debug('Successfully fetched Opportunity record.');
            stateCode = getStateCode(opp.Account.BillingState);
            orderRequestList = [SELECT Id,Status__c, Change_Type__c,Serialized_Data__c,Rescheduling_Charges__c,
                                Flight_Number_Arrival__c,Date_of_Arrival__c,STA_Time__c,Date_of_Departure__c,STD_Time__c,
                                Flight_Number_Departure__c,Service_Type__c,CreatedDate
                                FROM Order_Request__c 
                                WHERE Status__c = 'Pending' AND Change_Type__c ='Reschedule' AND Booking__c =: recordId LIMIT 1];
            //Process Opportunity Line Items
            //Map<String, List<OpportunityLineItem>> productVsOppItemList = new Map<String, List<OpportunityLineItem>>();
            //Map<Id, OpportunityLineItem> oppLineItemMap = new Map<Id, OpportunityLineItem>();
            String jsonString = orderRequestList[0].Serialized_Data__c;
            Map<String, Object> dataMap = new Map<String, Object>();
            if(!Test.isRunningTest()){
               dataMap = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
            }
            
            String arrivingFlightScheduleId = '';
            String departureFlightScheduleId = '';
            
            if (dataMap.containsKey('Arriving_Flight_Schedule__c') && dataMap.get('Arriving_Flight_Schedule__c') != null) {
                arrivingFlightScheduleId = (String) dataMap.get('Arriving_Flight_Schedule__c');
            }            
            if (dataMap.containsKey('Departure_Flight_Schedule__c') && dataMap.get('Departure_Flight_Schedule__c') != null) {
                departureFlightScheduleId = (String) dataMap.get('Departure_Flight_Schedule__c');
            }
            
            Integer sr = 0;
            String serviceType;
            Decimal hsn;
            Integer totalQty;
            Decimal totalInvoice;
            Decimal totalDiscount;
            Decimal totalUnitPrice;
            Decimal valueWithTax ;
            Set<Id> orderRequestId = new Set<Id>();
            for(Order_Request__c ordReq : orderRequestList){
                orderRequestId.add(ordReq.Id);
            }
            if(!orderRequestList.IsEmpty()){
                //hide = true;
                for (OpportunityLineItem o : opp.OpportunityLineItems) 
                {
                    if(o.HSN_HAC__c != null){
                        hsn = o.HSN_HAC__c;
                    }
                    break;					
                }
                for(Order_Request__c ord:  orderRequestList){
                    sr++ ;
                    totalSGST = 0;
                    totalCGST = 0;
                    totalIGST = 0;
                    orderRequestRecords = new List<orderRequestWrapper>();
                    Decimal gstRate = 18;  // 18% GST
                    serviceType = 'Rescheduling Charges';
                    totalDiscount = 0.0;
                    valueWithTax = ord.Rescheduling_Charges__c;//opp.Total_Booking_Amount__c - ord.Rescheduling_Charges__c;
                    totalInvoice = (valueWithTax / (1 + (gstRate / 100))).setScale(2, RoundingMode.HALF_UP); 
                    totalUnitPrice = totalInvoice;
                    orderRequestRecords.add(new orderRequestWrapper(sr, serviceType, hsn, 1, totalInvoice, totalDiscount, totalUnitPrice));
                    
                    totalAmount = valueWithTax;
                    taxableAmount = totalInvoice;
                    if(opp.Service_Airport_Id__r.State__c == opp.Account.BillingState){
                        totalSGST = (totalUnitPrice - totalInvoice)/2;
                        totalCGST = (totalUnitPrice - totalInvoice)/2;
                    }else{
                        totalIGST = totalUnitPrice - totalInvoice;
                    }
                    paidAmount = opp.Paid_Amount__c != null ? opp.Paid_Amount__c : 0;
                    dueAmount = totalAmount - paidAmount;
                    totalAmountInWords = opp.Paid_Amount__c != 0 ? NumberToWordsUtil.convertNumberToWords(dueAmount) : NumberToWordsUtil.convertNumberToWords(totalAmount);
                }
                
                /*Set<Id> orderRequestIds = new Set<Id>();
for (Order_Request__c req : orderRequestList) {
orderRequestIds.add(req.Id);
}
List<Passenger_Details__c> passengerRecords = [SELECT Id, Name, Age__c,Travel_PNR_No__c,Travel_Class__c FROM Passenger_Details__c WHERE Order_Request__c IN :orderRequestIds];*/
                
                List<Passenger_Details__c> passengerRecords  = [SELECT Id, Name, Age__c, Travel_Class__c,Travel_PNR_No__c, Airline_PNR__c FROM Passenger_Details__c WHERE Opportunity_ID__c = :recordId AND Individual_Booking_Details__r.Status__c NOT IN : statusList];
                passengers = new List<PassengerWrapper>();
                Integer counter = 1;
                for (Passenger_Details__c p : passengerRecords) {
                    passengers.add(new PassengerWrapper(counter, p));
                    counter++;
                }    
                
                Map<Id, Flight_Schedule__c> flightSchMap = new Map<Id, Flight_Schedule__c>(
                    [SELECT id, Name,Flight_Detail__r.Airline_Id__c, Flight_Detail__r.Airline_Id__r.Airline_Name__c, 
                     Arrival_Terminal__r.Name, Departure_Terminal__r.Name,Flight_Detail__r.Departure_Airport__r.Name ,
                     Flight_Detail__r.Arrival_Airport__r.Name, Flight_Detail__r.Flight_Type__c
                     FROM Flight_Schedule__c 
                     WHERE Id =: arrivingFlightScheduleId OR Id =: departureFlightScheduleId]);
                
                string serviceAirport = '';
                String flightType = '';
                flightDetails = new List<FlightDetailsWrapper>();
                if(orderRequestList[0].Service_Type__c == 'Transit' || orderRequestList[0].Service_Type__c == 'Arrival'){
                    flightNum = orderRequestList[0].Flight_Number_Arrival__c;
                    flightDateTime = orderRequestList[0].Date_of_Arrival__c +' '+ orderRequestList[0].STA_Time__c;
                    airline =  flightSchMap.get(arrivingFlightScheduleId).Flight_Detail__r.Airline_Id__c != null ? flightSchMap.get(arrivingFlightScheduleId).Flight_Detail__r.Airline_Id__r.Airline_Name__c : '';
                    terminal = flightSchMap.get(arrivingFlightScheduleId).Arrival_Terminal__r.Name;
                    flightDetails.add(new FlightDetailsWrapper(flightNum, flightDateTime, airline, terminal));
                    
                    fromAirport = flightSchMap.get(arrivingFlightScheduleId).Flight_Detail__r.Departure_Airport__r.Name;
                    toAirport = flightSchMap.get(arrivingFlightScheduleId).Flight_Detail__r.Arrival_Airport__r.Name;
                    //if(orderRequestList[0].Service_Type__c == 'Transit' || orderRequestList[0].Service_Type__c == 'Arrival')
                    serviceDateTime = orderRequestList[0].Date_of_Arrival__c +' '+ orderRequestList[0].STA_Time__c;
                    serviceAirport = flightSchMap.get(arrivingFlightScheduleId).Flight_Detail__r.Arrival_Airport__r.Name ;
                    flightType = flightSchMap.get(arrivingFlightScheduleId).Flight_Detail__r.Flight_Type__c != null ? flightSchMap.get(arrivingFlightScheduleId).Flight_Detail__r.Flight_Type__c : opp.Flight_Type__c;
                }
                if(orderRequestList[0].Service_Type__c == 'Departure'){
                    flightNum = orderRequestList[0].Flight_Number_Departure__c;
                    flightDateTime = orderRequestList[0].Date_of_Departure__c +' '+ orderRequestList[0].STD_Time__c;
                    airline =  flightSchMap.get(departureFlightScheduleId).Flight_Detail__r.Airline_Id__c != null ? flightSchMap.get(departureFlightScheduleId).Flight_Detail__r.Airline_Id__r.Airline_Name__c : '';
                    terminal = flightSchMap.get(departureFlightScheduleId).Departure_Terminal__r.Name;
                    flightDetails.add(new FlightDetailsWrapper(flightNum, flightDateTime, airline, terminal));
                    
                    fromAirport = flightSchMap.get(departureFlightScheduleId).Flight_Detail__r.Departure_Airport__r.Name;
                    toAirport = flightSchMap.get(departureFlightScheduleId).Flight_Detail__r.Arrival_Airport__r.Name;
                    //if(orderRequestList[0].Service_Type__c == 'Departure')
                    serviceDateTime = orderRequestList[0].Date_of_Departure__c +' '+ orderRequestList[0].STD_Time__c;
                    serviceAirport = flightSchMap.get(departureFlightScheduleId).Flight_Detail__r.Arrival_Airport__r.Name ;
                    flightType = flightSchMap.get(departureFlightScheduleId).Flight_Detail__r.Flight_Type__c != null ? flightSchMap.get(departureFlightScheduleId).Flight_Detail__r.Flight_Type__c : opp.Flight_Type__c;
                }
                
                serviceDetails = new ServiceDetailsWrapper(serviceDateTime, String.valueof(orderRequestList[0].CreatedDate), serviceAirport, flightType, fromAirport, toAirport);
            }
        } else {
            System.debug('ERROR: No recordId found.');
        }
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
    
    public class PassengerWrapper {
        public Integer SrNo { get; set; }
        public Passenger_Details__c Passenger { get; set; }
        
        public PassengerWrapper(Integer srNo, Passenger_Details__c passenger) {
            this.SrNo = srNo;
            this.Passenger = passenger;
        }
    }
    public class orderRequestWrapper {
        public Integer SrNo { get; set; }
        public String serviceType { get; set; }
        public Decimal hsn_hac { get; set; }
        public Integer quantity { get; set; }
        public Decimal invoiceAmt { get; set; }
        public Decimal discountAmt { get; set; }
        public Decimal unitPrice { get; set; }
        
        public orderRequestWrapper(Integer srNo, String serviceType, Decimal hsn_hac, Integer quantity, Decimal invoiceAmt, Decimal discountAmt, Decimal unitPrice) {
            this.SrNo = srNo;
            this.serviceType = serviceType;
            this.hsn_hac = hsn_hac;
            this.quantity = quantity;
            this.invoiceAmt = invoiceAmt;
            this.discountAmt = discountAmt;
            this.unitPrice = unitPrice;
        }
    }
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
    public String getDiscountColumnStyle() {
        return hasDiscount ? '' : 'display:none;';
    }
    public Boolean getIsIntraStateTax() {
        return totalSGST > 0 || totalCGST > 0;
    }
    
    public Boolean getIsInterStateTax() {
        return totalIGST > 0;
    }   
}