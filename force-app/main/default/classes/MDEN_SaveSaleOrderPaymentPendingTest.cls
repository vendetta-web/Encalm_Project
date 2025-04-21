/**
* @File Name : MDEN_SaveSaleOrderPaymentPendingTest.cls
* @Description : Test Class for MDEN_SaveSaleOrderPaymentPending.cls
* @Author : Maxify Development Team
* @Created Date : April 8, 2025
**/
@isTest
public class MDEN_SaveSaleOrderPaymentPendingTest {
    
    @isTest
    static void testSaveSaleOrderPaymentPending_Success() {
        
        Opportunity opp = new Opportunity(Name = 'Test Opportunity', StageName = 'New', CloseDate = Date.today() );
        insert opp;
        
        MDEN_SaveSaleOrderPaymentPending.MDEN_GetRequestWrapper reqWrapper = new MDEN_SaveSaleOrderPaymentPending.MDEN_GetRequestWrapper();
        reqWrapper.id = opp.Id;
        String jsonBody = JSON.serialize(reqWrapper);
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/save_sale_order_payment_pending/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonBody);
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        Test.startTest();
        MDEN_SaveSaleOrderPaymentPending.MDEN_GetResponseWrapper response = MDEN_SaveSaleOrderPaymentPending.saveSaleOrderPaymentPending();
        Test.stopTest();
        
        System.assertEquals('true', response.status);
        System.assertEquals('true', response.id);
    }
    
    @isTest
    static void testSaveSaleOrderPaymentPending_NoOpportunityFound() {
        
        MDEN_SaveSaleOrderPaymentPending.MDEN_GetRequestWrapper reqWrapper = new MDEN_SaveSaleOrderPaymentPending.MDEN_GetRequestWrapper();
        reqWrapper.id = '006XXXXXXXXXXXXXXX'; 
        String jsonBody = JSON.serialize(reqWrapper);
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/save_sale_order_payment_pending/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonBody);
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        Test.startTest();
        MDEN_SaveSaleOrderPaymentPending.MDEN_GetResponseWrapper response =   MDEN_SaveSaleOrderPaymentPending.saveSaleOrderPaymentPending();
        Test.stopTest();
        
        System.assertEquals('false', response.status);
        System.assertEquals('false', response.id);
    }
    @isTest
    static void testSaveSaleOrderPaymentPending_Exception() {
        RestContext.request = null;
        
        Test.startTest();
        MDEN_SaveSaleOrderPaymentPending.MDEN_GetResponseWrapper response = MDEN_SaveSaleOrderPaymentPending.saveSaleOrderPaymentPending();
        Test.stopTest();
        
        System.assertEquals('false', response.status, 'Status should be false on exception');
        System.assertNotEquals(null, response.message, 'Exception message should not be null');
    }
}