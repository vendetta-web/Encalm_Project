/*
* ───────────────────────────────────────────────────────────────────────────────────────────────
* Created by: Maxify Development Team
* Created Date: 3nd, April, 2025
* Purpose: : The MDEN_SaveBookingCancelRequestTest is responsible for providing the test data to the MDEN_SaveBookingCancelRequest.
* Owner :  Encalm
*───────────────────────────────────────────────────────────────────────────────────────────────
*/
@isTest
private class MDEN_SaveBookingCancelRequestTest {
    
/* 
* @description:testSaveBookingCancelRequest_Success method use for creating test data
* @param: N/A
* @return: void
*/
    @testsetup
    static void testSaveBookingCancelRequest_Success() {
        
        Account newAccount = new Account(
            Name = 'Sample Account',
            BillingStreet = '123 Main St',
            BillingCity = 'New York',
            BillingState = 'NY',
            BillingPostalCode = '10001',
            BillingCountry = 'USA'
        );
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = newAccount.Id
        );
        insert testOpportunity;
        MDEN_SaveBookingCancelRequest.MDEN_GetRequestWrapper requestWrapper = new MDEN_SaveBookingCancelRequest.MDEN_GetRequestWrapper();
        requestWrapper.id = testOpportunity.Id;
        Test.startTest();
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(JSON.serialize(requestWrapper));
        RestContext.request = req;
        MDEN_SaveBookingCancelRequest.MDEN_GetResponseWrapper response = MDEN_SaveBookingCancelRequest.saveBookingCancelRequest();
        Test.stopTest();
        Opportunity updatedOpportunity = [SELECT StageName FROM Opportunity WHERE Id = :testOpportunity.Id LIMIT 1];
        System.assertEquals('true', response.id, 'Response id should be true');
        System.assertEquals('', response.message, 'Response message should be empty for success');
        System.assertEquals('Cancel Order', updatedOpportunity.StageName, 'The StageName should be updated to "Cancel Order"');
    }
    
/* 
* @description:This method is used to test the negative scenario when the Opportunity is not found.
* @param: N/A
* @return: void
*/
    
    @isTest
    static void testSaveBookingCancelRequest_NoOpportunity() {
        MDEN_SaveBookingCancelRequest.MDEN_GetRequestWrapper requestWrapper = new MDEN_SaveBookingCancelRequest.MDEN_GetRequestWrapper();
        requestWrapper.id = '001000000000000AAA'; // Use a non-existent Opportunity ID
        Test.startTest();
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(JSON.serialize(requestWrapper));
        RestContext.request = req;
        MDEN_SaveBookingCancelRequest.MDEN_GetResponseWrapper response = MDEN_SaveBookingCancelRequest.saveBookingCancelRequest();
        Test.stopTest();
        System.assertEquals('false', response.id, 'Response id should be false');
        System.assertEquals('data not found.', response.message, 'Response message should indicate "data not found."');
    }
    
/* 
* @description:This method is used to test the exception scenario.
* @param: N/A
* @return: void
*/
    @isTest
    static void testSaveBookingCancelRequest_Exception() {
        MDEN_SaveBookingCancelRequest.MDEN_GetRequestWrapper requestWrapper = new MDEN_SaveBookingCancelRequest.MDEN_GetRequestWrapper();
        requestWrapper.id = '001000000000000AAA'; // Use a non-existent Opportunity ID
        Test.startTest();
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(JSON.serialize(requestWrapper));
        RestContext.request = req;
        MDEN_SaveBookingCancelRequest.MDEN_GetResponseWrapper response = MDEN_SaveBookingCancelRequest.saveBookingCancelRequest();
        Test.stopTest();
        System.assertEquals('false', response.id, 'Response id should be false');
        System.assertNotEquals('', response.message, 'Response message should contain the error');
    }
}