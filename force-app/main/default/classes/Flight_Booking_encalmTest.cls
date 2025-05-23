/**
* @File Name : Flight_Booking_encalmTest.cls
* @Description : Enhanced Test Class for Flight_Booking_encalm.cls
* @Author : Maxify Development Team
* @Created Date : April 10, 2025
**/
@isTest
public class Flight_Booking_encalmTest {
    
    @isTest
    public static void testFlightBookingMethods() {
        // Create Test Data
        Terminal__c terminal = new Terminal__c(Name='T1', Code__c='Terminal 1I');
        insert terminal;

        Airline__c airline = new Airline__c(Airline_Name__c='Air India', Airline_Code__c='001');
        insert airline;

        Flight_Detail__c flightDetail = new Flight_Detail__c(
            Airline_Id__c = airline.Id,
            Flight_No_Arrival__c = '871',
            Flight_No_Departure__c = '0'
        );
        insert flightDetail;

        Account parentAcc = new Account(Name = 'Parent Account', BillingState = 'Delhi');
        insert parentAcc;

        Account childAcc = new Account(Name = 'Child Account', ParentId = parentAcc.Id, BillingState = 'Goa');
        insert childAcc;

        Contact con = new Contact(FirstName='Test', LastName='User', Email='test@example.com', AccountId=childAcc.Id);
        insert con;

        Test.startTest();
            List<Arriving_Airport__mdt> airportList = Flight_Booking_encalm.getAirport();
            List<Flight_Detail__c> flightList = Flight_Booking_encalm.getFlightInfo(System.today());
            Boolean result = Flight_Booking_encalm.createOpportunity('Delhi', 'Goa', System.today(), 'sector', 'FXN00', '1', '1', '2');

            List<Map<String, String>> locations = Flight_Booking_encalm.getLocation(parentAcc.Id);
            Boolean isBusiness = false;

            // Assign RecordType before calling isBusinessAccount
            RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Business_Account' LIMIT 1];
            parentAcc.RecordTypeId = rt.Id;
            update parentAcc;
            isBusiness = Flight_Booking_encalm.isBusinessAccount(parentAcc.Id);
            List<Contact> contacts = Flight_Booking_encalm.getContactsByAccount(childAcc.Id);
        
        	childAcc.ParentId = null;
            update childAcc;
        	Flight_Booking_encalm.getLocation(parentAcc.Id);
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, airportList, 'Airport list should not be null');
        System.assertNotEquals(null, flightList, 'Flight list should not be null');
        System.assertEquals(true, result, 'Opportunity creation should return true');
        System.assertEquals(1, locations.size(), 'One location should be returned');
        System.assertEquals(true, isBusiness, 'Account should be recognized as Business Account');
        System.assertEquals(1, contacts.size(), 'One contact should be returned');
    }
}