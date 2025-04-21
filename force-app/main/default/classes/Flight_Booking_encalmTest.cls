/**
* @File Name : Flight_Booking_encalmTest.cls
* @Description : Test Class for Flight_Booking_encalm.cls
* @Author : Maxify Development Team
* @Created Date : April 10, 2025
**/
@isTest
public class Flight_Booking_encalmTest {
	
    @isTest
    public static void testMethod1(){
        
        // Creating Test data
        Terminal__c terminal = new Terminal__c(Name='T1', Code__c='Terminal 1');
        insert terminal;
        
        Airline__c airline = new Airline__c(Airline_Name__c	='Air India', Airline_Code__c = '001');
        insert airline;
        
        Flight_Detail__c flightDetail = new Flight_Detail__c(
            Airline_Id__c = airline.Id,
            Flight_No_Arrival__c = '871',
            Flight_No_Departure__c = '0'
        );
        insert flightDetail;
        
        Test.startTest();
        	List<Arriving_Airport__mdt> airportList = Flight_Booking_encalm.getAirport();
        	List<Flight_Detail__c> flightList = Flight_Booking_encalm.getFlightInfo(System.today());
        	boolean msg = Flight_Booking_encalm.createOpportunity('Delhi', 'Goa', System.today() , 'sector', 'FXN00' , '7', '18', '45');
        Test.stopTest();

        System.assertNotEquals(null, airportList, 'Returned list should not be null');
        System.assertNotEquals(null, flightList, 'Returned list should not be null');
    }
}