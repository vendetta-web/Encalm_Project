@isTest
public class PackageSelectionControllerTest {
    static Id pricebookId;
    
    @testSetUp
    static void setupTestData() {
        // Setup Account
        Account acc = new Account(
            Name = 'Test Account', 
            Surcharge_waived_off__c = false,
            BillingStreet = '123 Main Street',
            BillingCity = 'Pune',
            BillingState = 'Maharashtra',
            BillingPostalCode = '411001',
            BillingCountry = 'India'
        );
        insert acc;
        
        // Setup Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            AccountId = acc.Id,
            Flight_Type__c = 'Domestic',
            Service_Type__c = 'Arrival',
            Date_of_Arrival__c = String.ValueOf(Date.today().addDays(1)),
            STA_Time__c = '10:00',
            Service_Airport__c = 'DEL'
        );
        insert opp;
        Passenger_Details__c passenger = new Passenger_Details__c(
            Title__c = 'Mr',
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            Gender__c = 'Male',
            Age__c = 35.00, // converted to String
            Designation__c = 'Manager',
            Travel_Class__c = 'Economy',
            Travel_PNR_No__c = 'PNR12345',
            Nationalities__c = 'Indian',
            Passport_Govt_Id__c = 'A12345678',
            Mobile__c = '9778803210',
            Passenger_Type__c = 'Adult',
            Show_as_Placard__c = true,
            Opportunity_ID__c = Opp.Id
        );
        insert passenger;
        Placard__c placard = new Placard__c(
            Opportunity_ID__c = opp.Id,
            Title__c = 'Mr',
            First_Name__c = 'John',
            Last_Name__c = 'Smith',
            Mobile_Number__c = '9876543210'
        );
        insert placard;
        // Setup Product and PricebookEntry
        Airport__c airport = new Airport__c(Name='Delhi', Airport_Code__c= Opp.Service_Airport__c, Type__c='International', Country__c='India', Service_Available__c=true);
        insert airport;
        
        Product2 prod = new Product2(
            Name = 'Test Product',
            Flight_Type__c = Opp.Flight_Type__c, 
            Service_Type__c = Opp.Service_Type__c, 
            Family = 'Gold', 
            Airport__c = airport.id ,
            Package_Is_For__c = 'Adult'
        );
        insert prod;
        
        Product2 prodSurcharge = new Product2(
            Name = 'Surcharge Product',
            Flight_Type__c = Opp.Flight_Type__c, 
            Service_Type__c = Opp.Service_Type__c, 
            Family = 'Surcharge', 
            Airport__c = airport.id ,
            Package_Is_For__c = 'Adult'
        );
        insert prodSurcharge;
        
        pricebookId = Test.getStandardPricebookId();
        
        /*Pricebook2 pb = [SELECT Id, IsActive FROM Pricebook2 WHERE Id = :pricebookId];
pb.IsActive = true;
update pb;*/
        
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prod.Id,
            UnitPrice = 500,
            IsActive = true
        );
        insert pbe;
        
        PricebookEntry surchargePbe = new PricebookEntry(
        Pricebook2Id = pricebookId,
        Product2Id = prodSurcharge.Id,
        UnitPrice = 50,
        IsActive = true,
        List_Price_In_Percentage__c = false
        );
        insert surchargePbe;
        // Create OpportunityLineItems
        OpportunityLineItem oli1 = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Quantity = 1,
            UnitPrice = 1000,
            PricebookEntryId = pbe.Id,
            Status__c = 'Active'
        );
        insert oli1;
    }
    @isTest
    static void testCreateOpportunityLineItems(){
        Opportunity opp = [Select Id from Opportunity Limit 1];
        Product2 prod = [Select Id From Product2 Where Name = 'Test Product'  Limit 1];
        PricebookEntry pbe = [Select Id From PricebookEntry Where UnitPrice = 500 Limit 1 ];
        // Sample productDetails map
        List<Map<String, Object>> productDetails = new List<Map<String, Object>>();
        Map<String, Object> detail = new Map<String, Object>{
            'productId' => prod.Id,
                'pricebookEntryId' => pbe.Id,
                'count' => 2,
                'unitPrice' => 500,
                'discountValue' => 100,
                'isChild' => false,
                'pickupTerminals' => new List<String>{ 'T1' },
                    'dropTerminals' => new List<String>{ 'T2' }
        };
            productDetails.add(detail);
        
        // Call the method
        Test.startTest();
        PackageSelectionController.createOpportunityLineItems(opp.Id, productDetails, 1000);
        Test.stopTest();
        
        // Assertions
        List<OpportunityLineItem> olis = [SELECT Id, OpportunityId FROM OpportunityLineItem WHERE OpportunityId = :opp.Id];
        System.assert(olis.size() > 0, 'OpportunityLineItems should be created');
        
        List<Transaction_History__c> txns = [SELECT Id FROM Transaction_History__c WHERE Booking_Id__c = :opp.Id];
        System.assert(txns.size() > 0, 'Transaction records should be created');
    }
    @isTest
    static void testCreateOpportunityLineItems2(){
        Opportunity opp = [Select Id,Departure_Service_Time__c from Opportunity Limit 1];
        Opp.Departure_Service_Time__c = '12:00';
        Opp.Date_of_Departure__c = String.ValueOf(Date.today().addDays(1));
        Opp.STA_Time__c = null;
        update Opp;
        Product2 prod = [Select Id From Product2 Where Name = 'Test Product'  Limit 1];
        PricebookEntry pbe = [Select Id From PricebookEntry Where UnitPrice = 500 Limit 1 ];
        // Sample productDetails map
        List<Map<String, Object>> productDetails = new List<Map<String, Object>>();
        Map<String, Object> detail = new Map<String, Object>{
            'productId' => prod.Id,
                'pricebookEntryId' => pbe.Id,
                'count' => 2,
                'unitPrice' => 500,
                'discountValue' => 100,
                'isChild' => false,
                'pickupTerminals' => new List<String>{  },
                    'dropTerminals' => new List<String>{  }
        };
            productDetails.add(detail);
        
        // Call the method
        Test.startTest();
        PackageSelectionController.createOpportunityLineItems(opp.Id, productDetails, 1000);
        Test.stopTest();
        
        // Assertions
        List<OpportunityLineItem> olis = [SELECT Id, OpportunityId FROM OpportunityLineItem WHERE OpportunityId = :opp.Id];
        System.assert(olis.size() > 0, 'OpportunityLineItems should be created');
        
        List<Transaction_History__c> txns = [SELECT Id FROM Transaction_History__c WHERE Booking_Id__c = :opp.Id];
        System.assert(txns.size() > 0, 'Transaction records should be created');
    }
    @isTest
    static void testGetPackages(){
        Opportunity opp = [Select Id from Opportunity Limit 1];
        
        // Call the method
        Test.startTest();
        PackageSelectionController.getPackages(opp.Id);
        
        Product2 prod = [Select Id,Package_Is_For__c,Family From Product2 Where Name = 'Test Product'  Limit 1];
        
        prod.Package_Is_For__c = 'Child';
        prod.Family = 'Gold';
        Update prod;
        PackageSelectionController.getPackages(opp.Id);
        
        prod.Package_Is_For__c = 'Infant';
        prod.Family = 'Gold';
        Update prod;
        PackageSelectionController.getPackages(opp.Id);
        
        Test.stopTest();
    }
    @isTest
    static void testGetAddons(){
        Opportunity opp = [Select Id from Opportunity Limit 1];
        
        // Call the method
        Test.startTest();
        PackageSelectionController.getAddons(opp.Id);
        Test.stopTest();
    }
    @isTest
    static void testGetFlightTerminalInfo(){
        Opportunity opp = [Select Id from Opportunity Limit 1];
        
        // Call the method
        Test.startTest();
        PackageSelectionController.getFlightTerminalInfo(opp.Id);
        Test.stopTest();
    }
    @isTest
    static void getDropTerminalInfoTest(){
        Opportunity opp = [Select Id from Opportunity Limit 1];
        
        // Call the method
        Test.startTest();
        PackageSelectionController.getDropTerminalInfo(opp.Id);
        Test.stopTest();
    }
    @isTest
    static void getOpportunityDetailsTest(){
        Opportunity opp = [Select Id from Opportunity Limit 1];
        
        // Call the method
        Test.startTest();
        PackageSelectionController.getOpportunityDetails(opp.Id);
        Test.stopTest();
    }
    @isTest
    static void getTerminalInfoTest(){
        Opportunity opp = [Select Id from Opportunity Limit 1];
        
        // Call the method
        Test.startTest();
        PackageSelectionController.getTerminalInfo(opp.Id);
        Test.stopTest();
    }
    @isTest
    static void getSavedPassengerDetailsTest(){
        Opportunity opp = [Select Id from Opportunity Limit 1];        
        // Call the method
        Test.startTest();
        PackageSelectionController.getSavedPassengerDetails(opp.Id);
        Test.stopTest();
    }
    @isTest
    static void getPlacardDetailsTest(){
        Opportunity opp = [Select Id from Opportunity Limit 1];        
        // Call the method
        Test.startTest();
        PackageSelectionController.getPlacardDetails(opp.Id);
        Test.stopTest();
    }
    @isTest
    static void updateBookingStateTest(){
        Opportunity opp = [Select Id from Opportunity Limit 1];        
        // Call the method
        Test.startTest();
        PackageSelectionController.updateBookingState(opp.Id,'Delhi');
        Test.stopTest();
    }
    @isTest
    static void updateAddonsOrderSummaryStateTest(){
        Opportunity opp = [Select Id from Opportunity Limit 1];        
        // Call the method
        Test.startTest();
        PackageSelectionController.updateAddonsOrderSummaryState(opp.Id,'Test','Test');
        Test.stopTest();
    }
    @isTest
    static void getProcessStateTest(){
        Opportunity opp = [Select Id from Opportunity Limit 1];        
        // Call the method
        Test.startTest();
        PackageSelectionController.getProcessState(opp.Id);
        Test.stopTest();
    }
    @isTest
    static void savePlacardDetailsTest(){
        Opportunity opp = [Select Id from Opportunity Limit 1];        
        
        List<Map<String, Object>> placardData = new List<Map<String, Object>>();
        placardData.add(new Map<String, Object>{
            'title' => 'Ms.',
                'firstname' => 'Jane',
                'lastname' => 'Doe',
                'phone' => '1234567890'
                });
        placardData.add(new Map<String, Object>{
            'title' => 'Dr.',
                'firstname' => 'John',
                'lastname' => 'Smith',
                'phone' => '9876543210'
                });
        
        Test.startTest();
        PackageSelectionController.savePlacardDetails(placardData, opp.Id);
        Test.stopTest();
        
        List<Placard__c> result = [SELECT First_Name__c, Last_Name__c, Mobile_Number__c FROM Placard__c WHERE Opportunity_ID__c = :opp.Id ];
        
        System.assertEquals(2, result.size(), 'Two new placards should be inserted');
        Set<String> names = new Set<String>();
        for (Placard__c p : result) {
            names.add(p.First_Name__c + ' ' + p.Last_Name__c);
        }
        System.assert(names.contains('Jane Doe'), 'Jane Doe should be inserted');
        System.assert(names.contains('John Smith'), 'John Smith should be inserted');
    }
    @isTest
    static void savePassengerDetailsTest(){
        Opportunity opp = [Select Id from Opportunity Limit 1];
        List<Map<String, Object>> passengerData = new List<Map<String, Object>>();
        
        passengerData.add(new Map<String, Object>{
            'id' => 'P001',
                'title' => 'Mr',
                'firstname' => 'John',
                'lastname' => 'Doe',
                'gender' => 'Male',
                'age' => '30',
                'designation' => 'Manager',
                'travelclass' => 'Economy',
                'travelpnrno' => 'PNR123',
                'nationality' => 'Indian',
                'passportnumber' => 'A12345678',
                'phone' => '9999999999',
                'type' => 'Adult',
                'isPlacard' => true
                });        
        // Call the method
        Test.startTest();
        PackageSelectionController.savePassengerDetails(passengerData, opp.Id);
        Test.stopTest();
        
        // Validate that passenger was inserted
        List<Passenger_Details__c> passengers = [SELECT Id, First_Name__c, Last_Name__c FROM Passenger_Details__c WHERE Opportunity_ID__c = :opp.Id];
        System.assertEquals(1, passengers.size());
        System.assertEquals('John', passengers[0].First_Name__c);
        System.assertEquals('Doe', passengers[0].Last_Name__c);
    }
    @isTest
    static void test_getSurchargeAmount() {
        
        DateTime bookingDateTime = DateTime.now();
        DateTime serviceDateTime = bookingDateTime.addHours(2);  
        
        // Parameters
        Decimal bookingAmount = 1000;
        Decimal percent = 10;  // 10% surcharge
        Decimal fixedAmount = 150;
        
        Test.startTest();
        
        // Case 1: Surcharge in Percent, within allowed hours
        Decimal percentResult = PackageSelectionController.getSurchargeAmount(
            serviceDateTime,
            bookingDateTime,
            percent,
            bookingAmount,
            true
        );
        System.assertEquals(1100, percentResult, 'Expected 10% surcharge added to booking amount');
        
        // Case 2: Surcharge in Fixed Amount, within allowed hours
        Decimal fixedResult = PackageSelectionController.getSurchargeAmount(
            serviceDateTime,
            bookingDateTime,
            fixedAmount,
            bookingAmount,
            false
        );
        System.assertEquals(fixedAmount, fixedResult, 'Expected fixed surcharge amount');
        
        // Case 3: Time exceeds allowed surcharge window — should return 0
        DateTime farFutureService = bookingDateTime.addHours(100); 
        Decimal zeroResult = PackageSelectionController.getSurchargeAmount(
            farFutureService,
            bookingDateTime,
            percent,
            bookingAmount,
            true
        );
        System.assertEquals(0, zeroResult, 'Expected no surcharge beyond allowed time window');
        
        Test.stopTest();
    }    
}