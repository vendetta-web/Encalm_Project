@isTest
public class MDEN_ConfirmSaleOrderTest  {
    
    @isTest
    static void test_confirmSaleOrder_success() {
        
        // Setup test Opportunity
        List<Opportunity> oppList = new List<Opportunity>();
        oppList.add( new Opportunity(
            Name = 'Test Opp',
            CloseDate = Date.today().addDays(5),
            StageName = 'Prospecting'
        ));
        insert oppList;
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/services/apexrest/confirm_sale_order/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"id" : "' + oppList[0].Id + '"}');
        //req.requestBody = Blob.valueOf('{"id" : "' + '006Su00000AOxScIAL' + '"}');
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        MDEN_ConfirmSaleOrder.MDEN_GetResponseWrapper response = MDEN_ConfirmSaleOrder.confirmSaleOrder();
        Test.stopTest();

        //System.assertEquals('true', response.id, 'Expected id to be true for valid Opportunity');
    }

    @isTest
    static void test_confirmSaleOrder_opportunityNotFound() {
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/services/apexrest/confirm_sale_order/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"id" : "006XXXXXXXXXXXXXXX"}');
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        MDEN_ConfirmSaleOrder.MDEN_GetResponseWrapper response = MDEN_ConfirmSaleOrder.confirmSaleOrder();
        Test.stopTest();

        System.assertEquals('false', response.id);
        System.assertEquals('data not found.', response.message);
    }

    @isTest
    static void test_confirmSaleOrder_invalidJson_catchBlock() {
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/services/apexrest/confirm_sale_order/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{invalid_json}');
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        MDEN_ConfirmSaleOrder.MDEN_GetResponseWrapper response = MDEN_ConfirmSaleOrder.confirmSaleOrder();
        Test.stopTest();

        System.assertEquals('false', response.status);
        System.assertNotEquals(null, response.message);
    }
}