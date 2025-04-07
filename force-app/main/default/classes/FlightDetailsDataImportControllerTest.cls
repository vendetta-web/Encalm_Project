@isTest
public class FlightDetailsDataImportControllerTest {
    @testSetup
    static void setupTestData() {
        Airline__c airline = new Airline__c(Airline_Code__c = 'AI', Airline_Name__c = 'Air India');
        insert airline;

        Airport__c airport1 = new Airport__c(Airport_Code__c = 'BLR');
        Airport__c airport2 = new Airport__c(Airport_Code__c = 'BOM');
        Airport__c airport3 = new Airport__c(Airport_Code__c = 'DEL');
        insert new List<Airport__c>{airport1, airport2, airport3};

        Terminal__c terminal1 = new Terminal__c(Name = 'T1', Airport__c = airport3.Id);
        Terminal__c terminal2 = new Terminal__c(Name = 'T2', Airport__c = airport3.Id);
        insert new List<Terminal__c>{terminal1, terminal2};

        /*Flight_Detail__c flightDetail = new Flight_Detail__c(
            Airline_Id__c = airline.Id,
            Flight_Number__c = 'AI101',
            Name = 'AI-101',
            Arrival_Airport__c = airport1.Id,
            Departure_Airport__c = airport2.Id
        );
        insert flightDetail;
        
        Flight_Detail__c flightDetail2 = new Flight_Detail__c(
            Airline_Id__c = airline.Id,
            Flight_Number__c = 'AI102',
            Name = 'AI-102',
            Arrival_Airport__c = airport1.Id,
            Departure_Airport__c = airport2.Id
        );
        insert flightDetail2;*/
    }

    @isTest
    static void testImportCSVFile() {
        String csvData = 'Airline,FlightNumberArrival,FlightNumberDeparture,Frequency,Origin,ArrivalTime,DepartureTime,Destination,FromDate,ToDate,ArrivalTerminal,DepartureTerminal\n'
                       + 'AI,AI101,AI102,1234567,BLR,1030,1200,BOM,01/04/2024,30/04/2024,T1,T2';
        String airportCode = 'DEL';

        Test.startTest();
        FlightDetailsDataImportController.importCSVFile(csvData, airportCode);
        Test.stopTest();

        List<Flight_Detail__c> insertedFlights = [SELECT Id FROM Flight_Detail__c WHERE Flight_Number__c = 'AI102'];
        System.assert(insertedFlights.size() > 0, 'Flight should be inserted');
    }
}