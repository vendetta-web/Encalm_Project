@isTest
private class MDEN_GetAirportTerminalByAirport_Test {

    // This method will create the necessary data for testing
    static void setupTestData() {
        // Creating a test Airport record
        Airport__c airport = new Airport__c(Name = 'Test Airport');
        insert airport;

        // Creating Terminal records for the test airport
        Terminal__c terminal1 = new Terminal__c(
            Name = 'T1', 
            Airport__c = airport.id, 
            Code__c = 'Terminal 1'
        );
        insert terminal1;

        Terminal__c terminal2 = new Terminal__c(
            Name = 'T2', 
            Airport__c = airport.id, 
            Code__c = 'Terminal 1'
        );
        insert terminal2;
    }

    // Test when terminal records are found
    @isTest
    static void testGetAirportTerminalsSuccess() {
        setupTestData();
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/get_terminal_by_airport/T1';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf('{"airport_code":"T1"}');
        RestContext.request = req;
        Test.startTest();
        MDEN_GetAirportTerminalByAirport.MDEN_GetResponseWrapper response = MDEN_GetAirportTerminalByAirport.getAiportTerminals();
        Test.stopTest();
        System.assertEquals('true', response.status);
        System.assertEquals('data found.', response.message);
     
    }

    // Test when no terminal records are found
    @isTest
    static void testGetAirportTerminalsNoData() {
        // Prepare the mock request
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/get_terminal_by_airport/T3';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf('{"airport_code":"T3"}');
        RestContext.request = req;
        Test.startTest();
        MDEN_GetAirportTerminalByAirport.MDEN_GetResponseWrapper response = MDEN_GetAirportTerminalByAirport.getAiportTerminals();
        Test.stopTest();
        System.assertEquals('false', response.status);
        System.assertEquals('data not found.', response.message);
    }

    // Test when an exception occurs during execution
    @isTest
    static void testGetAirportTerminalsException() {
       
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/get_terminal_by_airport/T1';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf('{"airport_code":}');
        RestContext.request = req;
        Test.startTest();
        MDEN_GetAirportTerminalByAirport.MDEN_GetResponseWrapper response = MDEN_GetAirportTerminalByAirport.getAiportTerminals();
        Test.stopTest();
        System.assertEquals('false', response.status);
        System.assertNotEquals('data not found.', response.message); 
    }
}