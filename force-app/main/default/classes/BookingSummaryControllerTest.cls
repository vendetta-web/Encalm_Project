@isTest
private class BookingSummaryControllerTest {

    static Id pricebookId;

    @testSetup
    static void setupTestData() {
        // Insert Pricebook
        pricebookId = Test.getStandardPricebookId();
        
        // Insert Account
        Account acc = new Account(
            Name = 'Test Account',
                                 BillingStreet = '123 Main Street',
            BillingCity = 'Pune',
            BillingState = 'Maharashtra',
            BillingPostalCode = '411001',
            BillingCountry = 'India'
        );
        insert acc;

        // Insert Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            AccountId = acc.Id,
            Number_of_Adults__c = 2,
            Number_of_Children__c = 1,
            Number_of_Infants__c = 1,
            Service_Airport__c = 'JFK',
            Flight_Number_Arrival__c = 'AA100',
            Flight_Number_Departure__c = 'AA101',
            Service_Type__c = 'Transit',
            Flight_Type__c = 'International'
        );
        insert opp;

        // Insert Product2
        Product2 prod = new Product2(
            Name = 'Test Package',
            Family = 'Packages',
            Package_Is_For__c = 'Adult'
        );
        insert prod;

        // Insert PricebookEntry
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        // Insert OpportunityLineItem
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Quantity = 1,
            PricebookEntryId = pbe.Id,
            UnitPrice = 100,
            Invoice_Amount__c = 90,
            Discount = 10,
            CGST__c = 5,
            SGST__c = 5,
            IGST__c = 0,
            Discount_Amount__c = 10,
            Status__c = 'Active'
        );
        insert oli;

        // Insert Passenger_Details__c
        Passenger_Details__c passenger = new Passenger_Details__c(
            Opportunity_ID__c = opp.Id,
            Title__c = 'Mr',
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            Gender__c = 'Male',
            Age__c = 30,
            Designation__c = 'Manager',
            Travel_Class__c = 'Economy',
            Travel_PNR_No__c = 'PNR123',
            Nationalities__c = 'Indian',
            Passport_Govt_Id__c = 'P1234567',
            Mobile__c = '1234567890',
            Passenger_Type__c = 'Adult',
            Show_as_Placard__c = true,
            Unique_Id__c = 'UID123',
            Individual_Booking_Details__c = oli.Id            
        );
        insert passenger;
        
        // Insert Placard__c
        Placard__c placard = new Placard__c(
            Opportunity_ID__c = opp.Id,
            Title__c = 'Mr',
            First_Name__c = 'John',
            Last_Name__c = 'Doe',
            Mobile_Number__c = '1234567890'
        );
        insert placard;
    }

    @isTest
    static void testGetOpportunityData() {
        // Get the test Opportunity
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        BookingSummaryController.FullOpportunityData data = BookingSummaryController.getOpportunityData(testOpp.Id);
        Test.stopTest();

        System.assertNotEquals(null, data);
        System.assertNotEquals(null, data.orderSummary);
        System.assertNotEquals(null, data.passengers);
        System.assertNotEquals(null, data.flightDetails);
    }
}