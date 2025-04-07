/* Created by: Maxify Development Team
 * Created Date: 2nd, April, 2025
 * Purpose: : The MDEN_GetAddonProductMasterTest is responsible for providing the test data to the MDEN_GetAddonProductMaster.
 */
@isTest
public class MDEN_GetAddonProductMasterTest {
    
    // Test method to verify the functionality of ProductDetailWrapper method
    @isTest
    public static void testProductDetailWrapper() {
         // Set up test data: Create a Product2 record
        Product2 product = new Product2(
            Name = 'Test Product',
            ProductCode = '0',
            Family = 'Gold',
            Description = 'Test Product Description',
            Service_Type__c = 'Arrival',
            Sector__c = 'Domestic',
            Is_Available__c = true
        );
        insert product;
        // Set up test data: Create a PricebookEntry record
        PricebookEntry pricebookEntry = new PricebookEntry(
            Product2Id = product.Id,
            UnitPrice = 100.00,
            Pricebook2Id = Test.getStandardPricebookId(),
            IsActive = true
           
        );
        insert pricebookEntry;
        
        // Create the request wrapper with required input parameters
        String reqBody = '{' +
                            '"category" : "Arrival", ' +
                            '"sector" : "Domestic", ' +
                            '"airport_code" : "8008", ' +
                            '"travel_date" : "2022-07-06", ' +
                            '"service_time" : "12:15", ' +
                            '"basetype" : "Gold", ' +
                            '"product_id" : "0" ' +
                         '}';
                         
        // Deserialize the request body to a wrapper
        MDEN_GetAddonProductMaster.MDEN_GetRequestWrapper requestWrapper = (MDEN_GetAddonProductMaster.MDEN_GetRequestWrapper)JSON.deserialize(reqBody, MDEN_GetAddonProductMaster.MDEN_GetRequestWrapper.class);
        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(reqBody);
        MDEN_GetAddonProductMaster.MDEN_GetResponseWrapper response = MDEN_GetAddonProductMaster.ProductDetailWrapper();
        MDEN_GetAddonProductMaster.ProductDetailWrapper productDetail = response.datalist[0];
        System.assertEquals(100.00, productDetail.list_price, 'Expected product list price to match');
        System.assertEquals(15.25, productDetail.tax_price, 'Expected tax price to match');
     
    }
    
    // Test case to handle scenario where no products are found
    @isTest
    public static void testNoProductsFound() {
        String reqBody = '{' +
                            '"category" : "Arrival", ' +
                            '"sector" : "International", ' +
                            '"airport_code" : "8008", ' +
                            '"travel_date" : "2022-07-06", ' +
                            '"service_time" : "12:15", ' +
                            '"basetype" : "Gold", ' +
                            '"product_id" : "0" ' +
                         '}';
        MDEN_GetAddonProductMaster.MDEN_GetRequestWrapper requestWrapper = (MDEN_GetAddonProductMaster.MDEN_GetRequestWrapper) JSON.deserialize(reqBody, MDEN_GetAddonProductMaster.MDEN_GetRequestWrapper.class);
        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(reqBody);
        MDEN_GetAddonProductMaster.MDEN_GetResponseWrapper response = MDEN_GetAddonProductMaster.ProductDetailWrapper();
        System.assertEquals('data not found.', response.message, 'Expected message to indicate no data was found');
    }
}