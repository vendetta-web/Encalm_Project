@IsTest
public class RescheduleBookingPIControllerTest {
    
    @testSetup
    static void setupTestData() {
        // Create an Account
        Account acc = new Account(
            Name = 'Test Account',
            BillingStreet = '123 Test Street',
            BillingCity = 'Test City',
            BillingState = 'Test State',
            BillingPostalCode = '12345',
            BillingCountry = 'Test Country'
        );
        insert acc;
        
        // Create an Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = System.today().addDays(10),
            AccountId = acc.Id
        );
        insert opp;
        
        // Create Product
        Product2 product = new Product2(Name = 'Test Product', IsActive = true);
        insert product;
        
        // Create PricebookEntry
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = product.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;
        
        // Create OpportunityLineItem
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100
        );
        insert oli;
        
        // Passenger
        Passenger_Details__c pd = new Passenger_Details__c(
            Opportunity_ID__c = opp.Id, 
            Name = 'test passenger', 
            Age__c = 33, 
            Travel_Class__c = 'Business',
            Travel_PNR_No__c = 'test pnr'
        );
        insert pd;
        
        // Airline and Airports
        Airline__c airline = new Airline__c(
            Airline_Code__c = '6E',
            Airline_Name__c = 'Indigo Airlines'
        );
        insert airline;
        
        Airport__c airport1 = new Airport__c(Airport_Code__c = 'DEL');
        insert airport1;
        
        Airport__c airport2 = new Airport__c(Airport_Code__c = 'HYD');
        insert airport2;
        
        // Flight Details
        Flight_Detail__c fd = new Flight_Detail__c(
            Airline_Id__c = airline.Id,
            Arrival_Airport__c = airport1.Id,
            Departure_Airport__c = airport2.Id,
            Flight_Number__c = '123'
        );
        insert fd;
        
        // Flight Schedules
        Flight_Schedule__c fsch1 = new Flight_Schedule__c(
            Flight_Detail__c = fd.Id,
            Flight_Date__c = System.today()
        );
        insert fsch1;
        
        Flight_Schedule__c fsch2 = new Flight_Schedule__c(
            Flight_Detail__c = fd.Id,
            Flight_Date__c = System.today().addDays(1)
        );
        insert fsch2;
        
        // Update Opportunity with Flight Schedules
        opp.Arriving_Flight_Schedule__c = fsch1.Id;
        opp.Departure_Flight_Schedule__c = fsch2.Id;
        opp.Service_Type__c = 'Transit';
        update opp;
        
        // Create Order Request
        String jsonString = '[{"name":"Elite - Arrival (1 Adult)","amount":4500,"totalAmount":4500,"netAmount":3813.56,"cgstAmount":0,"sgstAmount":0,"igstAmount":686.44,"productId":"01tH30000010y6gIAA","pricebookEntryId":"01uH3000000tc0YIAQ","unitPrice":4500,"count":1,"isChild":false,"isInfant":false,"type":"Adult","discountValue":0}]';
        
        Order_Request__c orderReq = new Order_Request__c( Status__c = 'Pending',Change_Type__c = 'Amendment',Booking__c = opp.Id,Serialized_Data__c = jsonString,
            											  Rescheduling_Charges__c = 100.0,Flight_Number_Arrival__c = 'AI202',Date_of_Arrival__c = String.valueOf(Date.today().addDays(2)),
            											  STA_Time__c = '20:30',Date_of_Departure__c = String.valueOf(Date.today().addDays(2)),STD_Time__c = '10:30',
            											  Flight_Number_Departure__c = 'AI201',Service_Type__c = 'Arrival',Product__c = product.Id
                                                        );
        insert orderReq;
        Order_Request__c orderReq2 = new Order_Request__c( Status__c = 'Pending',Change_Type__c = 'Reschedule',Booking__c = opp.Id,Serialized_Data__c = jsonString,
            											  Rescheduling_Charges__c = 100.0,Flight_Number_Arrival__c = 'AI202',Date_of_Arrival__c = String.valueOf(Date.today().addDays(2)),
            											  STA_Time__c = '20:30',Date_of_Departure__c = String.valueOf(Date.today().addDays(2)),STD_Time__c = '10:30',
            											  Flight_Number_Departure__c = 'AI201',Service_Type__c = 'Arrival',Product__c = product.Id
                                                        );
        insert orderReq2;
    }
    
    @isTest
    static void testCreateContentVersion() {
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Test PDF Data'));
        
        Test.startTest();
        Differential_PI_Controller.createContentVersion(testOpp.Id, base64Data);
        RescheduleBookingPIController.createContentVersion(testOpp.Id, base64Data);
        Test.stopTest();
        
        ContentVersion cv = [SELECT Id FROM ContentVersion WHERE Title = 'Generated_PDF' LIMIT 1];
        System.assertNotEquals(null, cv, 'ContentVersion should be created.');
    }
    
    @isTest
    static void testGenerateAndSavePDF() {
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        
        Test.startTest();
        String contentVersionId = Differential_PI_Controller.generateAndSavePDF(testOpp.Id);
        String contentVersionReschudleId = RescheduleBookingPIController.generateAndSavePDF(testOpp.Id);
        Test.stopTest();
        
        // Check opportunity update
        Opportunity updatedOpp = [SELECT Id, StageName FROM Opportunity WHERE Id = :testOpp.Id];
        System.assertEquals('Prospecting', updatedOpp.StageName, 'StageName should remain as Prospecting or updated as per logic');
        
        // Check PDF file generation
        String todayDate = System.now().format();
        String title = 'Proforma_Invoice_' + todayDate + '.pdf';
        List<ContentVersion> versions = [SELECT Id, Title FROM ContentVersion WHERE Title = :title];
        System.assertEquals(2, versions.size(), 'A ContentVersion should be created');
    }
    
    @isTest
    static void testVFControllerConstructor() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        ApexPages.currentPage().getParameters().put('recordId', testOpp.Id);
        Differential_PI_Controller controller = new Differential_PI_Controller();
        RescheduleBookingPIController controller2 = new RescheduleBookingPIController();
        Test.stopTest();
        System.assertNotEquals(null, controller.formattedTodayDate, 'Formatted date should be initialized.');
    }
    
}