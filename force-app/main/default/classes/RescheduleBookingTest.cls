@isTest
public class RescheduleBookingTest {
    static Opportunity testOpp;
    static OpportunityLineItem testOLI;
    static Pricebook2 pb;
    static PricebookEntry pbe;
    static Product2 prod;
    
    @testSetup
    static void setupData() {
        
        prod = new Product2(
            Name = 'Test Package',
            Family = 'Gold',
            IsActive = true
        );
        insert prod;
        
        pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = prod.Id,
            UnitPrice = 1000,
            IsActive = true
        );
        insert pbe;
        
        // Insert Opportunity
        testOpp = new Opportunity(
            Name = 'Tesst',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            Service_Type__c = 'Arrival',
            Number_of_Adults__c = 2,
            Number_of_Children__c = 1,
            Number_of_Infants__c = 0,
            Date_of_Arrival__c = String.ValueOf(Date.today().addDays(-1)),
            Date_of_Departure__c = String.ValueOf(Date.today().addDays(-1)),
            Service_Airport__c = 'DXB',
            Arriving_Airport__c = 'DEL',
            Flight_Number_Arrival__c = 'EK123',
            Flight_Number_Departure__c = 'DEL123',
            Flight_Type__c = 'International',
            STA_Time__c = '00:00',
            STD_Time__c = '00:00',
            Sector__c = 'DXB-LHR'
        );
        insert testOpp;
        
        // Insert OpportunityLineItem
        testOLI = new OpportunityLineItem(
            OpportunityId = testOpp.Id,
            Quantity = 1,
            UnitPrice = 1000,
            PricebookEntryId = pbe.Id,
            Status__c = 'Active'
        );
        insert testOLI;
        List<Rescheduling__mdt> policies = [SELECT MasterLabel, Time_Frame__c, Applicable_Per_Booking__c, Charges_in_Percentage__c, Charges__c,Greater_Than__c, Less_Than__c,
                                            Package__c,Policy_Applied__c FROM Rescheduling__mdt WHERE IsActive__c = true ORDER BY Time_Frame__c];
        
    }
    
    @isTest
    static void testGetOpportunityDetails() {
        Opportunity testOpp = [SELECT Id, Flight_Number_Arrival__c, Service_Airport__c FROM Opportunity WHERE Name ='Tesst'];
        RescheduleBooking.bookingWrapper wrapper = RescheduleBooking.getOpportunityDetails(testOpp.Id);
        System.assertNotEquals(null, wrapper);
        System.assertEquals('Arrival', wrapper.serviceType);
    }
    
    @isTest
    static void testSaveData() {
        Map<String, Object> fieldsToUpdate = new Map<String, Object>();
        fieldsToUpdate.put('Flight_Number_Arrival__c', 'EK456');
        fieldsToUpdate.put('Service_Airport__c', 'AUH');
        Opportunity testOpp = [SELECT Id, Flight_Number_Arrival__c, Service_Airport__c FROM Opportunity WHERE Name ='Tesst'];
        Test.startTest();
        RescheduleBooking.saveData(testOpp.Id, fieldsToUpdate);
        Test.stopTest();
        
        Opportunity updatedOpp = [SELECT Id, Flight_Number_Arrival__c, Service_Airport__c FROM Opportunity WHERE Id = :testOpp.Id];
        System.assertEquals('EK456', updatedOpp.Flight_Number_Arrival__c);
        System.assertEquals('AUH', updatedOpp.Service_Airport__c);
    }
    
    @isTest
    static void testShowReschedulingChargesSubmitFalse() {
        Opportunity testOpp = [SELECT Id, STA_Time__c,Date_of_Arrival__c,Departure_Service_Time__c,Date_of_Departure__c,Flight_Number_Arrival__c, Service_Airport__c FROM Opportunity WHERE Name ='Tesst'];
        testOpp.Departure_Service_Time__c = '00:00';
        testOpp.Date_of_Departure__c = String.ValueOf(Date.today().addDays(-1));
        testOpp.STA_Time__c = null;
        update testOpp;
        Test.startTest();
        RescheduleBooking.ReschedulingDetailsWrapper wrapper = RescheduleBooking.showReschedulingCharges(testOpp.Id, false);
        Test.stopTest();
        
        System.assertNotEquals(null, wrapper);
        System.assert(wrapper.reschedulingAmount >= 0);
    }
    
    @isTest
    static void testShowReschedulingChargesSubmitTrue() {
        Opportunity testOpp = [SELECT Id, Flight_Number_Arrival__c, Service_Airport__c FROM Opportunity WHERE Name ='Tesst'];
        Test.startTest();
        RescheduleBooking.ReschedulingDetailsWrapper wrapper = RescheduleBooking.showReschedulingCharges(testOpp.Id, true);
        Test.stopTest();
        
        System.assertNotEquals(null, wrapper);
        System.assert(wrapper.reschedulingAmount >= 0);
        
        // Ensure Transaction record created
        List<Transaction_History__c> transactions = [SELECT Id FROM Transaction_History__c WHERE Booking_Id__c = :testOpp.Id];
        System.assert(transactions.size() > 0);
    }
    
    @isTest
    static void testGetPerBookingReschedulingAmount() {
        Decimal amount = RescheduleBooking.getPerBookingReschedulingAmount(
            DateTime.now().addHours(18),
            DateTime.now(),
            1000,
            'Gold',
            0
        );
        System.assert(amount >= 0);
    }
    
    @isTest
    static void testGetReschedulingAmount() {
        Decimal amount = RescheduleBooking.getReschedulingAmount(
            DateTime.now().addHours(24),
            DateTime.now(),
            1000,
            'TestPackage'
        );
        System.assert(amount >= 0);
    }
    @isTest
    static void testGetReschedulingAmount2() {
        Rescheduling__mdt policy = new Rescheduling__mdt(
            MasterLabel = 'MockPolicy',
            Time_Frame__c = 'Unlimited',
            Charges_in_Percentage__c = true,
            Charges__c = 100,
            Package__c = 'TestPackage',
            IsActive__c = true,
            Applicable_Per_Booking__c = true
        );
        Decimal amount2 = RescheduleBooking.getReschedulingAmount(
            DateTime.now().addHours(24),
            DateTime.now(),
            1000,
            'TestPackage'
        );
    }
    
    @isTest
    static void testSaveDataError() {
        Test.startTest();
        try {
            RescheduleBooking.saveData(null, new Map<String, Object>());
            System.assert(false); // Should not reach here
        } catch (Exception e) {
            System.debug('e.getMessage()' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest
    static void testReschedulingGold_0_12_Hours() {
        Decimal amount = RescheduleBooking.getReschedulingAmount(
            DateTime.now().addHours(6), // Inside 0-12 hour range
            DateTime.now(),
            1000,
            'Gold'
        );
        System.assertEquals(1000, amount); // 100% of booking amount should be charged
    }
    
    @isTest
    static void testReschedulingGold_12_24_Hours() {
        Decimal amount = RescheduleBooking.getReschedulingAmount(
            DateTime.now().addHours(18), // Inside 12-24 hour range
            DateTime.now(),
            1000,
            'Gold'
        );
        System.assertEquals(650, amount); // Should charge INR 650
    }
    
    @isTest
    static void testReschedulingGold_24_Hours() {
        Decimal amountFirstTime = RescheduleBooking.getReschedulingAmount(
            DateTime.now().addHours(30), // After 24 hours
            DateTime.now(),
            1000,
            'Gold'
        );
        System.assertEquals(0, amountFirstTime); // First rescheduling is free
        Decimal amountFirstTime2 = RescheduleBooking.getReschedulingAmount(
            DateTime.now().addHours(30), // After 24 hours
            DateTime.now(),
            1000,
            'Elite'
        );
        System.assertEquals(0, amountFirstTime);
        
        Decimal amountSecondTime = RescheduleBooking.getPerBookingReschedulingAmount(
            DateTime.now().addHours(30),
            DateTime.now(),
            1000,
            'Gold',
            1 // Simulating rescheduling count > 0
        );
        System.assertEquals(650, amountSecondTime); // INR 650 should apply for subsequent rescheduling
    }
    
    
    
}