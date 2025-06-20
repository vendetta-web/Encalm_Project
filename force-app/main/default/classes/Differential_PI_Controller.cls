public class Differential_PI_Controller {
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
            PageReference pdfPage = Page.DifferentialProformaInvoice;
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
            // Get today's date formatted as DD-MM-YYYY
            String todayDate = System.now().format();
            // Save PDF as File in Salesforce
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
    Map<String,List<Order_Request__c>> typeToOrderRequestMap { get; set; }
    
    public Differential_PI_Controller() {
        String recordId = ApexPages.currentPage().getParameters().get('recordId');
        System.debug('DEBUG: Received recordId: ' + recordId);
        
        hasDiscount = false;
        hide = false;
        formattedTodayDate = DateTime.newInstance(System.today(), Time.newInstance(0, 0, 0, 0)).format('dd-MMM-yyyy');
        
        if (String.isNotBlank(recordId)) {
            fetchOpportunity(recordId);
            typeToOrderRequestMap = fetchOrderRequests(recordId);
            if (typeToOrderRequestMap.size() == 1 && (typeToOrderRequestMap.containsKey('Upgrade Package') || typeToOrderRequestMap.containsKey('All Upgrade Package'))) {
                processPackageUpgradeOrderRequest();
            }else{
                if (typeToOrderRequestMap.size() == 1 && (typeToOrderRequestMap.containsKey('Add Add-Ons') || typeToOrderRequestMap.containsKey('All Add Add-Ons'))) {
                    processOrderRequests();
                }else{
                    fetchPassengers();
                    processOrderRequests();
                }
                
            }
            processFlightDetails();
        }
    }
    
    public Opportunity fetchOpportunity(String recordId) {
       opp = [SELECT Id, Name, Service_Type__c,Arriving_Flight_Schedule__c,Flight_Number_Arrival__c,Service_Airport__c, Flight_Type__c, Date_of_Arrival__c, 
               Date_of_Departure__c, Paid_Amount__c, Total_Booking_Amount__c, Account.Name,Arrival_Service_Time__c,Departure_Flight_Schedule__c, 
               Account.BillingState,Account.BillingCountry,Account.GST__c,Flight_Number_Departure__c,Departure_Service_Time__c,STA_Time__c,STD_Time__c,
               Departure_Airport__c,Arriving_Airport__c,CreatedDate,
               (SELECT Id, HSN_HAC__c,ListPrice,Product2.Family,Product2.Package_Is_For__c FROM OpportunityLineItems)
               FROM Opportunity WHERE Id = :recordId];
        stateCode = getStateCode(opp.Account.BillingState);
        return opp;
    }
    
    public Map<String,List<Order_Request__c>> fetchOrderRequests(String recordId) {
        orderRequestList = [SELECT Id, Status__c,SGST__c,CGST__c,IGST__c, Change_Type__c, Product__r.Name, Product__r.Package_Is_For__c,Parent_Order_Request__r.Type_of_Amendment__c, 
                            Total_List_Price__c, Invoice_Amount__c, Product__r.Package__c, Existing_Package__c,Type_of_Amendment__c,Parent_Order_Request__r.Serialized_Data__c,Total_Payable_Amount__c, 
                            Parent_Order_Request__r.Status__c
                            FROM Order_Request__c WHERE Status__c = 'Pending' AND Change_Type__c = 'Amendment' AND Booking__c = :recordId AND Product__c != NULL];
        system.debug('orderRequestList>>'+ orderRequestList);
        Map<String, List<Order_Request__c>> typeToOrderRequestMap = new Map<String, List<Order_Request__c>>();
        for (Order_Request__c req : orderRequestList) {
            String amendmentType = req.Parent_Order_Request__r.Type_of_Amendment__c;
            
            if (!typeToOrderRequestMap.containsKey(amendmentType)) {
                typeToOrderRequestMap.put(amendmentType, new List<Order_Request__c>());
            }
            
            typeToOrderRequestMap.get(amendmentType).add(req);
        }
        return typeToOrderRequestMap;
    }
    
    public void fetchPassengers() {
        Set<Id> orderRequestIds = new Set<Id>();
        for (Order_Request__c req : orderRequestList) {
            if (req.Parent_Order_Request__r.Status__c == 'Pending') {
            	orderRequestIds.add(req.Id);
            }
        }
        
        passengerRecords = [SELECT Id, Name, Age__c,Travel_PNR_No__c,Travel_Class__c FROM Passenger_Details__c WHERE Order_Request__c IN :orderRequestIds];
        passengers = new List<PassengerWrapper>();
        Integer counter = 1;
        for (Passenger_Details__c p : passengerRecords) {
            passengers.add(new PassengerWrapper(counter++, p));
        }
    }
    
    public void processOrderRequests() {
        orderRequestRecords = new List<orderRequestWrapper>();
        Map<String, List<Order_Request__c>> productVsOrdReqList = new Map<String, List<Order_Request__c>>();
        totalSGST = 0;
        totalCGST = 0;
        totalIGST = 0;
        taxableAmount = 0;
        totalAmount = 0;
        
        for (Order_Request__c req : orderRequestList) {
            if (req.Parent_Order_Request__r.Status__c == 'Pending') {
                String productCode = req.Product__r.Name == 'Surcharge' ? 'Surcharge' : req.Product__r.Name + '_' + req.Product__r.Package_Is_For__c;
                
                if (!productVsOrdReqList.containsKey(productCode)) {
                    productVsOrdReqList.put(productCode, new List<Order_Request__c>());
                }
                
                productVsOrdReqList.get(productCode).add(req);
                
                totalSGST += (req.SGST__c != null) ? req.SGST__c : 0;
                totalCGST += (req.CGST__c != null) ? req.CGST__c : 0;
                totalIGST += (req.IGST__c != null) ? req.IGST__c : 0;
                taxableAmount += (req.Invoice_Amount__c != null) ? req.Invoice_Amount__c : 0;
                totalAmount += (req.Total_List_Price__c != null) ? req.Total_List_Price__c : 0;
                totalAmountInWords = totalAmount != 0 ? NumberToWordsUtil.convertNumberToWords(totalAmount) : '';
            }
            
        }
        roundTotals();    
        
        Decimal hsn = 0;
        for (OpportunityLineItem o : opp.OpportunityLineItems) {
            if(o.HSN_HAC__c != null){
                hsn = o.HSN_HAC__c;
            }
            break;					
        }
        Integer sr = 0;
        for (String key : productVsOrdReqList.keySet()) {
            sr++;
            Integer totalQty = 0;
            Decimal totalInvoice = 0, totalDiscount = 0, totalUnitPrice = 0;
            Boolean packageUpdated = false;
            String serviceType;            
            String amendmentType = '';
            
            for (Order_Request__c req : productVsOrdReqList.get(key)) {
                totalQty++;
                system.debug('totalQty??'+totalQty);
                totalInvoice = (req.Invoice_Amount__c != null) ? req.Invoice_Amount__c : 0;
                if(req.Parent_Order_Request__r.Type_of_Amendment__c =='Add Passengers' || req.Parent_Order_Request__r.Type_of_Amendment__c =='All Add Passengers'){
                    amendmentType = 'Passenger Added';                    
                }else if(req.Parent_Order_Request__r.Type_of_Amendment__c =='Add Add-Ons' || req.Parent_Order_Request__r.Type_of_Amendment__c =='All Add Add-Ons'){
                    amendmentType = 'Add-on Added';
                }
                serviceType =  amendmentType + ' (' + req.Product__r.Name  ;
                if (req.Product__r.Package_Is_For__c == 'Adult' || req.Product__r.Package_Is_For__c == 'Child' || req.Product__r.Package_Is_For__c == 'Infant') {
                    serviceType += '-' + req.Product__r.Package_Is_For__c + ')';
                }else{
                    serviceType +=  ')';
                }
            }
            totalInvoice = totalInvoice.setScale(2, RoundingMode.HALF_UP);
            totalDiscount = totalDiscount.setScale(2, RoundingMode.HALF_UP);
            paidAmount = 0;//opp.Total_Booking_Amount__c !=null? opp.Total_Booking_Amount__c : 0;
            totalUnitPrice =  totalQty * totalInvoice;//totalUnitPrice.setScale(2, RoundingMode.HALF_UP);       
            dueAmount = 0;//(totalUnitPrice - paidAmount).setScale(2, RoundingMode.HALF_UP);
            
            orderRequestRecords.add(new orderRequestWrapper(sr, serviceType, hsn, totalQty, totalInvoice, totalDiscount, totalUnitPrice));
        }
    }
    
     public void processPackageUpgradeOrderRequest(){
        orderRequestRecords = new List<orderRequestWrapper>();
        totalSGST = 0;
        totalCGST = 0;
        totalIGST = 0;
        taxableAmount = 0;
        totalAmount = 0;
        Decimal hsn = 0;
        Decimal totalDiscount = 0;
        Decimal paidAmountOp = 0;
        for (OpportunityLineItem o : opp.OpportunityLineItems) 
        {
            if(o.HSN_HAC__c != null){
                hsn = o.HSN_HAC__c;
            }
            break;					
        }
        for (OpportunityLineItem o : opp.OpportunityLineItems) 
        {
            if (o.Product2.Package_Is_For__c == 'Adult' || o.Product2.Package_Is_For__c == 'Child' || o.Product2.Package_Is_For__c == 'Infant'){
            	paidAmountOp += (o.ListPrice != null) ? (o.ListPrice).setScale(2, RoundingMode.HALF_UP) : 0;
            }
        }
        for (Order_Request__c req : orderRequestList) {
            if (req.Parent_Order_Request__r.Status__c == 'Pending') {
                totalSGST += (req.SGST__c != null) ? (req.SGST__c).setScale(2, RoundingMode.HALF_UP) : 0;
                totalCGST += (req.CGST__c != null) ? (req.CGST__c).setScale(2, RoundingMode.HALF_UP) : 0;
                totalIGST += (req.IGST__c != null) ? (req.IGST__c).setScale(2, RoundingMode.HALF_UP) : 0;
                taxableAmount += (req.Invoice_Amount__c != null) ? (req.Invoice_Amount__c).setScale(2, RoundingMode.HALF_UP) : 0;
                totalAmount += (req.Total_List_Price__c != null) ? (req.Total_List_Price__c).setScale(2, RoundingMode.HALF_UP) : 0; 
                System.debug('req.Total_Payable_Amount__c>>>>'+ req.Total_Payable_Amount__c);
                totalAmountInWords = totalAmount != 0 ? NumberToWordsUtil.convertNumberToWords(totalAmount) : '';  
                paidAmount =  (paidAmountOp).setScale(2, RoundingMode.HALF_UP);
                dueAmount  = (totalAmount - paidAmount).setScale(2, RoundingMode.HALF_UP);
                totalDiscount = totalDiscount.setScale(2, RoundingMode.HALF_UP);
            }
            //(req.Total_Payable_Amount__c).setScale(2, RoundingMode.HALF_UP);
        }        
        //orderRequestRecords.add(new orderRequestWrapper(1, 'Amendment Charges', hsn, 1, taxableAmount, totalDiscount, totalAmount));
        orderRequestRecords.add(new orderRequestWrapper(1, 'Amendment(Package Upgrade)', hsn, 1, taxableAmount, totalDiscount, taxableAmount)); 
        roundTotals();
    }
    

    public void processFlightDetails() {
        String flightNum;
        String airline;
        String terminal;
        String flightDateTime;
        String serviceDateTime;
        String fromAirport;
        String toAirport;
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
        
        serviceDetails = new ServiceDetailsWrapper(serviceDateTime, String.valueof(opp.CreatedDate), opp.Service_Airport__c, opp.Flight_Type__c, fromAirport, toAirport);
    }    
    
   /*public void processFlightDetails() {
        flightDetails = new List<FlightDetailsWrapper>();
        if (opp.Arriving_Flight_Schedule__c != null) {
            flightDetails.add(getFlightDetails(opp.Arriving_Flight_Schedule__c, opp.Flight_Number_Arrival__c, opp.Date_of_Arrival__c, opp.Arrival_Service_Time__c));
        }
        if (opp.Departure_Flight_Schedule__c != null) {
            flightDetails.add(getFlightDetails(opp.Departure_Flight_Schedule__c, opp.Flight_Number_Departure__c, opp.Date_of_Departure__c, opp.Departure_Service_Time__c));
        }
    }
    public FlightDetailsWrapper getFlightDetails(Id flightScheduleId, String flightNum, String flightDate, String serviceTime) {
        Flight_Schedule__c flight = [SELECT Flight_Detail__r.Airline_Id__r.Airline_Name__c FROM Flight_Schedule__c WHERE Id = :flightScheduleId LIMIT 1];
        String airline = (flight.Flight_Detail__r.Airline_Id__r.Airline_Name__c != null) ? flight.Flight_Detail__r.Airline_Id__r.Airline_Name__c : '';
        return new FlightDetailsWrapper(flightNum, flightDate + ' ' + serviceTime, airline, null);
    }*/
    
    public void roundTotals() {
        totalSGST = totalSGST.setScale(2, RoundingMode.HALF_UP);
        totalCGST = totalCGST.setScale(2, RoundingMode.HALF_UP);
        totalIGST = totalIGST.setScale(2, RoundingMode.HALF_UP);
        taxableAmount = taxableAmount.setScale(2, RoundingMode.HALF_UP);
        totalAmount = totalAmount.setScale(2, RoundingMode.HALF_UP);
        //paidAmount = paidAmount.setScale(2, RoundingMode.HALF_UP);
        //dueAmount = dueAmount.setScale(2, RoundingMode.HALF_UP);
    }
    
    /*public static String extractName(String serializedData) {
String name = '';        
Pattern namePattern = Pattern.compile('"name"\\s*:\\s*"([^"]+)"');
Matcher matcher = namePattern.matcher(serializedData);

if (matcher.find()) {
name = matcher.group(1); 
}        
return name;
}*/
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