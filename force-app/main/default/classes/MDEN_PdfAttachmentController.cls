public with sharing class MDEN_PdfAttachmentController {
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
            // 🔹 Call VF Page with only `recordId`
            PageReference pdfPage = Page.ProformaInvoicePDF;
            pdfPage.getParameters().put('recordId', recordId);
            System.debug('DEBUG: Calling VF Page with recordId: ' + recordId);

            // 🔹 Generate PDF Blob
            Blob pdfBlob = pdfPage.getContent();

            // 🔹 Save PDF as File in Salesforce
            ContentVersion cv = new ContentVersion(
                Title = 'Performa_Invoice.pdf',
                PathOnClient = 'Performa_Invoice.pdf',
                VersionData = pdfBlob,
                IsMajorVersion = true
            );
            insert cv;

            // 🔹 Attach PDF to Opportunity
            ContentDocument contentDocument = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :cv.Id LIMIT 1];
            ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
            contentDocumentLink.ContentDocumentId = contentDocument.Id;
            contentDocumentLink.LinkedEntityId = recordId;
            contentDocumentLink.ShareType = 'V';
            contentDocumentLink.Visibility = 'AllUsers';
            insert contentDocumentLink;

            System.debug('PDF successfully generated and attached.');
            return cv.Id;

        } catch (Exception e) {
            System.debug('ERROR: Failed to generate PDF - ' + e.getMessage());
            throw new AuraHandledException('Failed to generate PDF: ' + e.getMessage());
        }
    }

    public Opportunity opp { get; set; }
    public Decimal totalAmount { get; set; } 
    public String totalAmountInWords {get; set; }
    public List<OppLineItemWrapper> oppLineItems { get; set; }
    public List<PassengerWrapper> passengers { get; set; }
    public FlightDetailsWrapper flightDetails { get; set; }
    public String formattedTodayDate { get; set; }

   
    public MDEN_PdfAttachmentController() {
        String recordId = ApexPages.currentPage().getParameters().get('recordId');
        System.debug(' DEBUG: Received recordId in VF Controller: ' + recordId);

        Date todayDate = System.today();
        formattedTodayDate = DateTime.newInstance(todayDate.year(), todayDate.month(), todayDate.day()).format('dd-MMM-yyyy');

        if (String.isNotBlank(recordId)) {
            try {
                // 🔹 Fetch Opportunity Record
                opp = [SELECT Id, Name, CreatedDate, Service_Type__c, Service_Airport__c, Flight_Type__c, 
                        Flight_Number_Arrival__c, Flight_Number_Departure__c,Departure_Airport__c, Arriving_Airport__c, Date_of_Arrival__c, 
                        Date_of_Departure__c, STA_Time__c, STD_Time__c, Departure_Service_Time__c, Arrival_Service_Time__c, Service_Time__c,
                        Departure_Flight_Schedule__c, Arriving_Flight_Schedule__c,
                        Account.Name, Account.BillingState, Account.BillingCountry, Account.GST__c,
                        (SELECT Id, Name, Age__c, Travel_Class__c,Travel_PNR_No__c, Airline_PNR__c FROM Passenger_Details__r),
                        (SELECT Id, Product2.Name, Quantity, UnitPrice, TotalPrice, HSN_HAC__c FROM OpportunityLineItems)
                        FROM Opportunity WHERE Id = :recordId];

                System.debug('✅ Successfully fetched Opportunity record.');

                //Process totalAmount
                AggregateResult[] totalResult = [SELECT SUM(TotalPrice) totalAmount FROM OpportunityLineItem WHERE OpportunityId = :recordId];
                totalAmount = (totalResult.isEmpty() || totalResult[0].get('totalAmount') == null) ? 0 : (Decimal) totalResult[0].get('totalAmount');
                totalAmountInWords = NumberToWordsUtil.convertNumberToWords(totalAmount);

                // 🔹 Process Passenger Details
                passengers = new List<PassengerWrapper>();
                Integer counter = 1;
                for (Passenger_Details__c p : opp.Passenger_Details__r) {
                    passengers.add(new PassengerWrapper(counter, p));
                    counter++;
                }

                // 🔹 Process Opportunity Line Items
                oppLineItems = new List<OppLineItemWrapper>();
                counter = 1;
                for (OpportunityLineItem o : opp.OpportunityLineItems) {
                    oppLineItems.add(new OppLineItemWrapper(counter, o));
                    counter++;
                }

                // Process Flight Details
                String flightNum = opp.Service_Type__c == 'Arrival' ? opp.Flight_Number_Arrival__c : opp.Service_Type__c == 'Departure' ? opp.Flight_Number_Departure__c : '';
                System.debug('flightNum-->'+flightNum);
                String flightDate = opp.Service_Type__c == 'Arrival' ? opp.Date_of_Arrival__c : opp.Service_Type__c == 'Departure' ? opp.Date_of_Departure__c  : '';
                String flightSTA = opp.STA_Time__c;
                String flightSTD = opp.STD_Time__c;
                String flightDateTime = opp.Service_Type__c == 'Arrival' ? opp.Date_of_Arrival__c +' '+ flightSTA : opp.Service_Type__c == 'Departure' ? opp.Date_of_Departure__c +' '+ flightSTD : '';
                String flightSchId = opp.Service_Type__c == 'Arrival' ? opp.Arriving_Flight_Schedule__c : opp.Service_Type__c == 'Departure' ? opp.Departure_Flight_Schedule__c  : '';

                Flight_Detail__c flightDet = [SELECT id, Name, Arrival_Airport__r.Name, Departure_Airport__r.Name, Flight_Number__c, Airline_Id__r.Name 
                                            FROM Flight_Detail__c 
                                            WHERE Name = : flightNum order by createdDate desc LIMIT 1];

                Flight_Schedule__c flightSch = [SELECT id, Name, Flight_Date__c, STA__c, STD__c, Flight_Detail__r.Name, Arrival_Terminal__r.Name, Departure_Terminal__r.Name 
                                            FROM Flight_Schedule__c 
                                            WHERE Id =: flightSchId LIMIT 1];

                String airline = flightDet !=null && flightDet.Airline_Id__c!= null ? flightDet.Airline_Id__r.Name : null ;
                String terminal = opp.Service_Type__c == 'Arrival' ? flightSch.Arrival_Terminal__r.Name : opp.Service_Type__c == 'Departure' ? flightSch.Departure_Terminal__r.Name  : '';

                flightDetails = new FlightDetailsWrapper(flightNum, flightDateTime, airline, terminal);
            
            } catch (Exception e) {
                System.debug('⚠️ ERROR: Failed to fetch data in VF Controller - ' + e.getMessage());
            }
        } else {
            System.debug('⚠️ ERROR: No recordId found.');
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

    // Opportunity Line Item Wrapper class to add Sr. No.
    public class OppLineItemWrapper {
        public Integer SrNo { get; set; }
        public OpportunityLineItem oppLineItem { get; set; }

        public OppLineItemWrapper(Integer srNo, OpportunityLineItem oppLineItem) {
            this.SrNo = srNo;
            this.oppLineItem = oppLineItem;
        }
    }

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
}