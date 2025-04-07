/*
* ───────────────────────────────────────────────────────────────────────────────────────────────
* Created by: Maxify Development Team
* Created Date: 04/04/2025
* Purpose: : The MDEN_SaveSaleOrderItemTest is responsible for providing the test data to the MDEN_SaveSaleOrderItem.
* Owner :  Encalm
*───────────────────────────────────────────────────────────────────────────────────────────────
*/

@isTest
private class MDEN_SaveSaleOrderItemTest {

/* 
* ───────────────────────────────────────────────────────────────────────────────────────────────
* @description:This method use for creating test data
* @param: N/A
* @return: void
* ───────────────────────────────────────────────────────────────────────────────────────────────
*/    
    @isTest
    static void testSaveSaleOrderItemSuccess() {
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addMonths(1)
        );
        insert testOpportunity;
        Product2 newProduct = new Product2(
            Name = 'SILVER(INT-ARR)(Adult)', 
            ProductCode = 'INT-ARR-001', 
            Family = 'Accessories',
            Description = 'Silver product for international arrival (adult)',
            IsActive = true
        );
        insert newProduct;
        MDEN_SaveSaleOrderItem.OrderItem orderItem = new MDEN_SaveSaleOrderItem.OrderItem();
        orderItem.order_id = testOpportunity.Id; 
        orderItem.product_id = string.valueOf(newProduct.Id); 
        orderItem.name = 'SILVER(INT-ARR)(Adult)';
        orderItem.product_uom_qty = 6;
        orderItem.price_unit = 2881.36;
        orderItem.price_subtotal = '2881.36';
        orderItem.source = 'website';
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(JSON.serialize(orderItem));
        RestContext.request = req;
        MDEN_SaveSaleOrderItem.MDEN_GetResponseWrapper response = MDEN_SaveSaleOrderItem.saveSaleOrderItem();
        System.assertEquals('false', response.status);
    }
/* 
* ───────────────────────────────────────────────────────────────────────────────────────────────
* @description: method is used to test the exception scenario
* @param: N/A
* @return: void
* ───────────────────────────────────────────────────────────────────────────────────────────────
*/    
    
    @isTest
    static void testSaveSaleOrderItemExceptionHandling() {
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addMonths(1)
        );
        insert testOpportunity;
        MDEN_SaveSaleOrderItem.OrderItem orderItem = new MDEN_SaveSaleOrderItem.OrderItem();
        orderItem.order_id = testOpportunity.Id;
        orderItem.product_id = '';
        orderItem.name = 'SILVER(INT-ARR)(Adult)';
        orderItem.product_uom_qty = 6;
        orderItem.price_unit = 2881.36;
        orderItem.price_subtotal = '2881.36';
        orderItem.source = 'website';
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(JSON.serialize(orderItem));
        RestContext.request = req;   
        MDEN_SaveSaleOrderItem.MDEN_GetResponseWrapper response = MDEN_SaveSaleOrderItem.saveSaleOrderItem();
        System.assertEquals('false', response.status);
    }
    
/* 
* ───────────────────────────────────────────────────────────────────────────────────────────────
* @description:this method use to test scenario when request is Invalid
* @param: N/A
* @return: void
* ───────────────────────────────────────────────────────────────────────────────────────────────
*/    
    @isTest
    static void testSaveSaleOrderItemInvalidRequest() {
        // Create test data for Opportunity (required for OpportunityLineItem)
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addMonths(1)
        );
        insert testOpportunity;
        MDEN_SaveSaleOrderItem.OrderItem orderItem = new MDEN_SaveSaleOrderItem.OrderItem();
        orderItem.order_id = testOpportunity.Id;
        orderItem.product_id = 'InvalidProductId';
        orderItem.name = 'SILVER(INT-ARR)(Adult)';
        orderItem.product_uom_qty = 6;
        orderItem.price_unit = 2881.36;
        orderItem.price_subtotal = '2881.36';
        orderItem.source = 'website';
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(JSON.serialize(orderItem));
        RestContext.request = req;
        MDEN_SaveSaleOrderItem.MDEN_GetResponseWrapper response = MDEN_SaveSaleOrderItem.saveSaleOrderItem();
        System.assertEquals('data not found.', response.message);
    }
}