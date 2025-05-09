/**
* @File Name : Encalm_BookingEngineTest.cls
* @Description : Test Class for Encalm_BookingEngine.cls
* @Author : Maxify Development Team
* @Created Date : April 10, 2025
**/
@isTest
public class Encalm_BookingEngineTest {

    @testSetup
    static void setupTestData() {
        Airport__c dep = new Airport__c(Name='Delhi', Airport_Code__c='DEL', Type__c='International', Country__c='India', Service_Available__c=true);
        Airport__c arr = new Airport__c(Name='Mumbai', Airport_Code__c='BOM', Type__c='Domestic', Country__c='India', Service_Available__c=true);
        Airport__c transit = new Airport__c(Name='Hyderabad', Airport_Code__c='HYD', Type__c='Domestic', Country__c='India', Service_Available__c=true);
        insert new List<Airport__c>{dep, arr, transit};

        Flight_Detail__c mainFlight = new Flight_Detail__c(
            Name = 'MainFlight-101',
            Departure_Airport__c = dep.Id,
            Arrival_Airport__c = transit.Id
        );
        insert mainFlight;

        Flight_Schedule__c schedule = new Flight_Schedule__c(
            Flight_Detail__c = mainFlight.Id,
            Flight_Date__c = Date.today(),
            STA__c = Time.newInstance(14, 30, 0, 0),
            STD__c = Time.newInstance(12, 0, 0, 0)
        );
        insert schedule;

        Transit_Flight_Detail__c transitDetail = new Transit_Flight_Detail__c(
            Transit_Airport__c = transit.Id,
            Main_Flight__c = mainFlight.Id
        );
        insert transitDetail;
    }

    @isTest
    static void testGetAirportDetails() {
        Test.startTest();
        Encalm_BookingEngine.AirportWrapper wrapper = Encalm_BookingEngine.getAirportDetails();
        Test.stopTest();

        System.assert(wrapper != null, 'AirportWrapper should not be null');
        System.assert(!wrapper.baseAirportPicklist.isEmpty(), 'Base picklist should have active airports');
        System.assert(!wrapper.allAirportPicklist.isEmpty(), 'All airport picklist should have entries');
    }

    @isTest
    static void testGetFlightDetails() {
        Test.startTest();
        Encalm_BookingEngine.FlightWrapper wrap = Encalm_BookingEngine.getFlightDetails(
            Date.today(), 'DEL', 'HYD'
        );
        Test.stopTest();

        System.assert(wrap != null, 'FlightWrapper should not be null');
        System.assert(!wrap.flightPicklist.isEmpty(), 'Flight picklist should have flights');
    }

    @isTest
    static void testGetTransitFlightDetails() {
        Test.startTest();
        Encalm_BookingEngine.FlightWrapper wrap = Encalm_BookingEngine.getTransitFlightDetails(
            Date.today(), 'DEL', null, 'HYD'
        );
        Test.stopTest();

        System.assert(wrap != null, 'Transit FlightWrapper should not be null');
        System.assert(!wrap.flightPicklist.isEmpty(), 'Transit flight list should have entries');
    }
}