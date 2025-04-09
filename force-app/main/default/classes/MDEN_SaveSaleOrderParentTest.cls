/**
* @File Name : MDEN_SaveSaleOrderParentTest.cls
* @Description : Test Class for MDEN_SaveSaleOrderParent.cls
* @Author : Abhishek
* @Last Modified By : Abhishek
* @Last Modified On : April 08, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | April 08, 2025 |  Abhishek | Initial Version
**/

@isTest
public class MDEN_SaveSaleOrderParentTest {
    @isTest
    static void testSaveSaleOrderParent() {
        // Set up required terminal
        Terminal__c terminal = new Terminal__c(Name='T1', Code__c='Terminal 1');
        insert terminal;
        
        // Set up required airline
        Airline__c airline = new Airline__c(Airline_Name__c	='Air India', Airline_Code__c = '001');
        insert airline;
        //Airline__c arLineRecord = [Select id,Name from Airline__c where Id =: airline.Id Limit 1];
        // Set up Flight Detail
        Flight_Detail__c flightDetail = new Flight_Detail__c(
            Airline_Id__c = airline.Id,
            Flight_No_Arrival__c = '871',
            Flight_No_Departure__c = '0'
        );
        insert flightDetail;
        
        // Set up Airport Location and Airport
        Country__c conRecord = new Country__c(Country_Name__c = 'India' );
        
        Location__c loc = new Location__c(Location_Code__c = 'DEL',City__c = 'Delhi',Country_Id__c = conRecord.Id);
        insert loc;
        
        //Location__c locRecord = [Select id, Name from Location__c where Id =: loc.id Limit 1];
        
        Airport__c airport = new Airport__c(Name='Indira Gandhi International Airport', Location_Id__c=loc.Id);
        insert airport;
        
        // Set up Terminal with Airport
        Terminal__c arrivalTerminal = new Terminal__c(Name='T1', Airport__c = airport.Id);
        insert arrivalTerminal;
        
        // Set up Flight Schedule
        List<Flight_Schedule__c> flightScheduleList = new List<Flight_Schedule__c>();
        
        // Add one schedule to the list
        flightScheduleList.add(new Flight_Schedule__c(
            Flight_Date__c = Date.today(),
            Flight_Detail__c = flightDetail.Id,
            Arrival_Terminal__c = arrivalTerminal.Id,
            Departure_Terminal__c = arrivalTerminal.Id
        ));
        
        // Insert the list
        insert flightScheduleList;
        
        Flight_Schedule__c flightScheduleRecord = [SELECT Id,Departure_Terminal__r.Airport__c,Flight_Detail__r.Flight_No_Arrival__c, Flight_Date__c,Arrival_Terminal__r.Airport__r.Id,Arrival_Terminal__r.Airport__r.Location_Id__r.Name, Arrival_Terminal__r.Name, Flight_Detail__r.Airline_Id__r.Name 
                                                   FROM Flight_Schedule__c where Id =: flightScheduleList[0].Id];
        System.debug('flightScheduleRecord>>>>>>>>>>'+flightScheduleRecord);
        
        // Create the request body
        MDEN_SaveSaleOrderParent.Order requestOrder = new MDEN_SaveSaleOrderParent.Order();
        requestOrder.partner_id = '100';
        requestOrder.date_order = '2022-07-05 13:26:22';
        requestOrder.airport_location_id = loc.Name;//'000002';
        requestOrder.travel_date = flightScheduleList[0].Flight_Date__c;//Date.today();
        requestOrder.arrival_flight_id = flightDetail.Flight_No_Arrival__c;//'871';
        requestOrder.arrival_airline_id = airline.Name;//'001';
        requestOrder.departure_flight_id = flightDetail.Flight_No_Departure__c;//'0';
        requestOrder.service_category = 'welcome_and_assist';
        requestOrder.service_type_id = '1';
        requestOrder.arrival_time = '1445';
        requestOrder.departure_time = null;
        requestOrder.booking_made_from = 'b2c';
        requestOrder.no_of_adult = 1;
        requestOrder.no_of_children = 0;
        requestOrder.no_of_infants = 0;
        requestOrder.airport_terminal_id = 'T1';
        requestOrder.pricelist_id = '1';
        requestOrder.arrival_term = 'T1';
        requestOrder.source = 'TestSource';
        
        String jsonReq = JSON.serialize(requestOrder);
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/save_sale_order_parent/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonReq);
        RestContext.request = req;
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        Test.startTest();
        MDEN_SaveSaleOrderParent.MDEN_GetResponseWrapper result = MDEN_SaveSaleOrderParent.saveSaleOrderParent();
        Test.stopTest();
        
        System.assertEquals('true', result.status);
        System.assertNotEquals(null, result.id);
    }
    
    @isTest
    static void test_else_and_catch_blocks() {
        Test.startTest();        
        RestRequest req1 = new RestRequest();
        RestResponse res1 = new RestResponse();
        req1.requestUri = '/services/apexrest/save_sale_order_parent/';
        req1.httpMethod = 'POST';
        req1.requestBody = Blob.valueOf('{bad json}');
        RestContext.request = req1;
        RestContext.response = res1;
        
        MDEN_SaveSaleOrderParent.MDEN_GetResponseWrapper response2 = MDEN_SaveSaleOrderParent.saveSaleOrderParent();
        System.assertEquals('false', response2.status, 'Expected false status for catch block');
        System.assertNotEquals(null, response2.message, 'Expected error message in catch block');
        Test.stopTest();
    }
    
    
    @isTest
    static void testCheckCustomerDuplicacyTrue() {
        // Create a test account with email
        Account acc = new Account(LastName='Test', PersonEmail='test@example.com');
        insert acc;
        Boolean result = MDEN_SaveSaleOrderParent.checkCustomerDuplicacy('test@example.com', '001XXXXXXXXXXXXXXX');
        System.assertEquals(true, result);
    }
    
    @isTest
    static void testCheckCustomerDuplicacyFalse() {
        Boolean result = MDEN_SaveSaleOrderParent.checkCustomerDuplicacy('nomatch@example.com', null);
        System.assertEquals(false, result);
    }
    
}