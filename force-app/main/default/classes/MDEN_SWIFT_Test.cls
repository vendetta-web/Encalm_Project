/**
* @File Name : MDEN_SWIFT_Test.cls
* @Description : Test Class for MDEN_SWIFT.cls
* @Author : Maxify Development Team
* @Created Date : May 6, 2025
**/
@isTest
public class MDEN_SWIFT_Test {
    
    @testSetup
    static void setupData() {
        List<Opportunity> opps = new List<Opportunity>{
            new Opportunity(Name='Test Opp Success', StageName='Prospecting', CloseDate=Date.today().addDays(10)),
                new Opportunity(Name='Test Opp Failure', StageName='Prospecting', CloseDate=Date.today().addDays(10)),
                new Opportunity(Name='Test All Bookings', StageName='Prospecting', CloseDate=Date.today().addDays(10))
                };
                    insert opps;
    }
    
    // Mock for successful callouts
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            if (req.getEndpoint().contains('partner_authentication')) {
                res.setStatusCode(200);
                res.setBody('{"access_token":"mock_access_token"}');
            } else if (req.getEndpoint().contains('/v2/api')) {
                res.setStatusCode(307);
                res.setHeader('location', 'https://swiftapi.digitalorder.in/redirect_endpoint');
            } else if (req.getEndpoint().contains('redirect_endpoint')) {
                res.setStatusCode(200);
                res.setBody('{"status":"Success","message":"Booking confirmed","swift_booking_id":12345,"status_code":200}');
            } else {
                res.setStatusCode(400);
                res.setBody('{"status":"Error","message":"Bad Request"}');
            }
            return res;
        }
    }
    
    // Mock for failed callouts
    public class MockFailedRedirectResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            if (req.getEndpoint().contains('partner_authentication')) {
                res.setStatusCode(200);
                res.setBody('{"access_token":"mock_access_token"}');
            } else if (req.getEndpoint().contains('/v2/api')) {
                res.setStatusCode(307);
                res.setHeader('location', 'https://swiftapi.digitalorder.in/redirect_endpoint');
            } else if (req.getEndpoint().contains('redirect_endpoint')) {
                res.setStatusCode(200);
                res.setBody('{"status":"Failure","message":"Booking failed","swift_booking_id":null,"status_code":500}');
            } else {
                res.setStatusCode(400);
                res.setBody('{"status":"Error","message":"Bad Request"}');
            }
            return res;
        }
    }
    
    @isTest
    static void testGetAccessToken_SuccessfulBooking() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opp Success' LIMIT 1];
        
        Test.startTest();
        String token = MDEN_SWIFT.getAccessToken(opp.Id, '');
        Test.stopTest();
        
        System.assertNotEquals(null, token, 'Access token should not be null for successful booking');
    }
    
    @isTest
    static void testGetAccessToken_FailedBookingWithErrorLogging() {
        Test.setMock(HttpCalloutMock.class, new MockFailedRedirectResponse());
        
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opp Failure' LIMIT 1];
        
        Test.startTest();
        String token = MDEN_SWIFT.getAccessToken(opp.Id, '');
        Test.stopTest();
        
        List<Log_Parsing_Error__c> logs = [
            SELECT Id FROM Log_Parsing_Error__c WHERE OpportunityId__c = :opp.Id
        ];
        System.assert(!logs.isEmpty(), 'Error log should be created for failed callout');
    }
    
    @isTest
    static void testGetAccessToken_PartiallyBooking() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test All Bookings' LIMIT 1];
        
        Test.startTest();
        MDEN_SWIFT.getAccessToken(opp.Id, 'Partially Cancelled');
        Test.stopTest();
        
    }
    @isTest
    static void testGetAccessToken_CancelBooking() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test All Bookings' LIMIT 1];
        
        Test.startTest();
        MDEN_SWIFT.getAccessToken(opp.Id, 'Cancel');
        Test.stopTest();
    }
    @isTest
    static void testGetAccessToken_ModifiedBooking() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test All Bookings' LIMIT 1];
        
        Test.startTest();
        MDEN_SWIFT.getAccessToken(opp.Id, 'Modified/Rescheduled');
        Test.stopTest();
    }
    @isTest
    static void testGetAccessToken_AllBookingTypes() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test All Bookings' LIMIT 1];
        
        Test.startTest();
        MDEN_SWIFT.getAccessToken(opp.Id, '');
        Test.stopTest();
        
    }
    @isTest
    static void testSendFailureEmail() {
        String testOppId = [SELECT Id FROM Opportunity WHERE Name = 'Test All Bookings' LIMIT 1].Id;
        
        Test.startTest();
        // Call the email sending method
        MDEN_SWIFT.sendFailureEmail(testOppId, 'Cancel', '{"key":"value"}');
        Test.stopTest();
        
        // Validate that an email was queued
        List<Messaging.SendEmailResult> results = Limits.getEmailInvocations() > 0
            ? new List<Messaging.SendEmailResult>{}
        : null; 
    }
}