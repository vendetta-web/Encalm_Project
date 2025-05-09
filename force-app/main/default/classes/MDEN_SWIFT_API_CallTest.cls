/**
* @File Name : MDEN_SWIFT_API_CallTest.cls
* @Description : Test Class for MDEN_SWIFT_API_Call.cls
* @Author : Maxify Development Team
* @Created Date : May 6, 2025
**/
@isTest
private class MDEN_SWIFT_API_CallTest {

    private static Id oppId;
    
    @testSetup
    static void setupData() {
        // Create Pricebook
        String pb = Test.getStandardPricebookId();
        // Create Product
        Product2 prod = new Product2(Name = 'Test Product', isActive = true);
        insert prod;

        // Create PricebookEntry
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pb,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        // Create Person Account
        Account acc = new Account(
            RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND Name = 'Person Account' LIMIT 1].Id,
            FirstName = 'John',
            LastName = 'Doe',
            PersonEmail = 'john.doe@example.com',
            PersonHomePhone = '1234567890',
            PersonTitle = 'VIP1',
            Phone = '9999999999'
        );
        insert acc;

        // Create Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            AccountId = acc.Id,
            Pricebook2Id = pb,
            Service_Type__c = 'Departure',
            Flight_Type__c = 'Domestic',
            Date_of_Departure__c = String.valueOf(Date.today().addDays(5)),
            Date_of_Arrival__c = String.valueOf(Date.today().addDays(6)),
            Number_of_Adults__c = 2,
            Number_of_Children__c = 1,
            Number_of_Infants__c = 1,
            Payment_Ref_No__c = 'PAY1234'
        );
        insert opp;

        // Store for later reference
        oppId = opp.Id;

        // Create OpportunityLineItem
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Quantity = 1,
            PricebookEntryId = pbe.Id,
            TotalPrice = 100
        );
        insert oli;

        // Create Passenger Detail
        Passenger_Details__c passenger = new Passenger_Details__c(
            Opportunity_ID__c = opp.Id,
            Name = 'Mr. Alice Smith',
            First_Name__c = 'Alice',
            Last_Name__c = 'Smith',
            Age__c = 33,
            Travel_Class__c = 'Economy',
            Travel_PNR_No__c = 'PNR123',
            Passport_No__c = 'P12345',
            Designation__c = 'Director',
            Country_code__c = '+91',
            Mobile__c = '9876543210',
            Email_Id__c = 'alice@example.com',
            Title__c = 'Mr'
        );
        insert passenger;
    }

    @isTest
    static void testGetOpportunity() {
        // Fetch Opportunity Id created in setup
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        // Call method under test
        Test.startTest();
        MDEN_SWIFT_API_Call.PayloadWrapper result = MDEN_SWIFT_API_Call.getOpportunity(opp.Id, 'Cancel');
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, result);
        System.assertNotEquals(null, result.payload);
        System.assertEquals(opp.Id, result.payload.sfa_booking_id);
        System.assertEquals('Cancel', result.payload.save_sale_order_post.action_type);
        System.assertEquals('Cash on account', result.payload.save_sale_order_post.payment_method);
    }
}