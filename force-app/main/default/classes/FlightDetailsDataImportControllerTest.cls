@isTest
public class FlightDetailsDataImportControllerTest {
    @testSetup
    static void setupTestData() {
        Airline__c airline = new Airline__c(Airline_Code__c = 'AI', Airline_Name__c = 'Air India');
        insert airline;

        Airport__c airport1 = new Airport__c(Airport_Code__c = 'BLR');
        Airport__c airport2 = new Airport__c(Airport_Code__c = 'IST');
        Airport__c airport3 = new Airport__c(Airport_Code__c = 'DEL');
        insert new List<Airport__c>{airport1, airport2, airport3};

        Terminal__c terminal1 = new Terminal__c(Name = 'Terminal 3I', Airport__c = airport3.Id);
        Terminal__c terminal2 = new Terminal__c(Name = 'Terminal 3D', Airport__c = airport3.Id);
        insert new List<Terminal__c>{terminal1, terminal2};

        Flight_Detail__c flightDetail = new Flight_Detail__c(
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
        insert flightDetail2;
        
        Flight_Schedule__c fsch1 = new Flight_Schedule__c(
            Flight_Detail__c = flightDetail.Id,
            Flight_Date__c = System.today(), 
            Departure_Terminal__c = terminal1.Id, 
            STD__c = Time.newInstance(2, 30, 0, 0)
        );
        insert fsch1;
        Flight_Schedule__c fsch2 = new Flight_Schedule__c(
            Flight_Detail__c = flightDetail.Id,
            Flight_Date__c = System.today(), 
            Arrival_Terminal__c = terminal2.Id, 
            STA__c = Time.newInstance(3, 30, 0, 0)
        );
        insert fsch2;
    }

    @isTest
    static void testImportCSVFile() {
        String csvData = 'FlightName, Airline,AirportCode, AirlineCode, FlightNumberArrival,FlightNumberDeparture,Acty, Seats, Frequency,Origin,Last, ArrivalTime,DepartureTime,ove, next,Destination,FromDate,ToDate,ArrivalTerminal,DepartureTerminal\n'
                       + 'test,Indigo Airlines,DEL,6E,,63,,,1234567, , , ,20:45, ,BLR,BLR,30-Mar-25,31-May-25, ,Terminal 3D\n'
                       + 'test,Indigo Airlines,DEL,6E,12,,,,1204007,IST,IST,05:00, , , , ,30-Mar-25,31-May-25,Terminal 3D, ,';

        Test.startTest();
        FlightDetailsDataImportController.importCSVFile(csvData);
        Test.stopTest();

        List<Flight_Detail__c> insertedFlights = [SELECT Id FROM Flight_Detail__c];
        System.assert(insertedFlights.size() > 0, 'Flight should be inserted');
    }
}