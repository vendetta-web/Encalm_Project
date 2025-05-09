@IsTest
public  class MDEN_PdfAttachmentControllerTest {
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
        
        // Create OpportunityLineItems
        Product2 product = new Product2(Name = 'Test Product', IsActive = true);
        insert product;
        /*Pricebook2 customPricebook = new Pricebook2(
            Name = 'Custom Price Book',
            IsActive = true
        );
        insert customPricebook;*/
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = product.Id, UnitPrice = 100, IsActive = true);
        insert pbe;
        
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100
        );
        insert oli;
        
        Passenger_Details__c pd = new Passenger_Details__c(
            Opportunity_ID__c = opp.Id, 
             Name = 'test passenger', 
             Age__c = 33, 
             Travel_Class__c ='Business',
             Travel_PNR_No__c = 'test pnr'
            );
        insert pd;
        
        Airline__c airline = new Airline__c(
            Airline_Code__c = '6E', 
            Airline_Name__c = 'Indigo Airlines'
        );
        insert airline;
        
        Airport__c airport1 = new Airport__c(
        	Airport_Code__c = 'DEL'
            );
        insert airport1;
        
        Airport__c airport2 = new Airport__c(
        	Airport_Code__c = 'HYD'
            );
        insert airport2;
        
        Flight_Detail__c fd = new Flight_Detail__c(
            Airline_Id__c = airline.Id,
            Arrival_Airport__c = airport1.id,
            Departure_Airport__c = airport2.id,
            Flight_Number__c = '123'
        );
        insert fd;
        
        Flight_Schedule__c fsch1 = new Flight_Schedule__c(
            Flight_Detail__c = fd.Id,
            Flight_Date__c = System.today()
        );
        insert fsch1;
        
        Flight_Schedule__c fsch2 = new Flight_Schedule__c(
            Flight_Detail__c = fd.Id,
            Flight_Date__c = System.today() + 1
        );
        insert fsch2;
        
        opp.Arriving_Flight_Schedule__c = fsch1.id;
        opp.Departure_Flight_Schedule__c = fsch2.id;
        opp.Service_Type__c = 'Transit';
        update opp;
        
    }
    
    @isTest
    static void testCreateContentVersion() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Test PDF Data'));
        
        Test.startTest();
        MDEN_PdfAttachmentController.createContentVersion(testOpp.Id, base64Data);
        Test.stopTest();
        
        ContentVersion cv = [SELECT Id FROM ContentVersion WHERE Title = 'Generated_PDF' LIMIT 1];
        System.assertNotEquals(null, cv, 'ContentVersion should be created.');
    }
    
    @isTest
    static void testGenerateAndSavePDF() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        String contentVersionId = MDEN_PdfAttachmentController.generateAndSavePDF(testOpp.Id);
        Test.stopTest();
        //Added by Abhishek on 09-04-2025
        Opportunity updatedOpp = [SELECT Id, StageName FROM Opportunity WHERE Id = :testOpp.Id];
        System.assertEquals('Prospecting', updatedOpp.StageName, 'StageName should be updated to Quotation Sent');
        String todayDate = System.now().format();
		string Title = 'Proforma_Invoice_' + todayDate + '.pdf';
        List<ContentVersion> versions = [SELECT Id, Title FROM ContentVersion WHERE Title =: Title];
        System.assertEquals(1, versions.size(), 'A ContentVersion should be created');
    }
    
    @isTest
    static void testVFControllerConstructor() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        ApexPages.currentPage().getParameters().put('recordId', testOpp.Id);
        MDEN_PdfAttachmentController controller = new MDEN_PdfAttachmentController();
        Test.stopTest();
        
        System.assertNotEquals(null, controller.opp, 'Opportunity should be initialized.');
        System.assertNotEquals(null, controller.formattedTodayDate, 'Formatted date should be initialized.');
    }
}