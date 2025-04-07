/*
* ───────────────────────────────────────────────────────────────────────────────────────────────
* Created by: Maxify Development Team
* Created Date: 04/04/2025
* Purpose: : The MDEN_SaveBookingCancelRequestTest is responsible for providing the test data to the MDEN_SaveBookingCancelRequest.
* Owner :  Encalm
*───────────────────────────────────────────────────────────────────────────────────────────────
*/
@isTest
private class MDEN_SaveSaleGuestTest {
    
/* 
* ───────────────────────────────────────────────────────────────────────────────────────────────
* @description:This method use for creating test data
* @param: N/A
* @return: void
* ───────────────────────────────────────────────────────────────────────────────────────────────
*/
    @testsetup
    static void testSaveSaleGuestSuccess() {
        Opportunity newOpportunity = new Opportunity();
        newOpportunity.Name = 'New Opportunity Example'; 
        newOpportunity.StageName = 'Prospecting'; 
        newOpportunity.CloseDate = Date.today().addMonths(1); 
		insert newOpportunity;
        Country__c country = new Country__c( Country_Name__c = 'India');
        insert country;
        Salutation__c salutation = new Salutation__c(Salutation_Name__c = 'Mr.');
        insert salutation;
    }

/* 
* ───────────────────────────────────────────────────────────────────────────────────────────────
* @description: this method use to test scenario when no salutation found
* @param: N/A
* @return: void
* ───────────────────────────────────────────────────────────────────────────────────────────────
*/
    @isTest
    static void testSaveSaleGuestNoSalutationFound() {
        MDEN_SaveSaleGuest.MDEN_GetRequestWrapper requestWrapper = new MDEN_SaveSaleGuest.MDEN_GetRequestWrapper();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        requestWrapper.sale_id = '9477';
        requestWrapper.partner_id = '0';
        requestWrapper.parent_id = String.ValueOf(opp.Id);
        requestWrapper.title = 'Dr.'; 
        requestWrapper.first_name = 'Ajit';
        requestWrapper.last_name = 'Kumar';
        requestWrapper.gender = 'male';
        requestWrapper.dob = '1987-09-17';
        requestWrapper.age = '32';
        requestWrapper.passport_no = null;
        requestWrapper.pnr_no = '123';
        requestWrapper.class_type = 'first';
        requestWrapper.mobile = null;
        requestWrapper.country_code = 'IN';
        requestWrapper.source = 'website';
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(JSON.serialize(requestWrapper));
        RestContext.request = req;
        MDEN_SaveSaleGuest.MDEN_GetResponseWrapper response = MDEN_SaveSaleGuest.saveSaleGuest();
        System.assertEquals('false', response.status);
    }

/* 
* ───────────────────────────────────────────────────────────────────────────────────────────────
* @description:This method is used to test the negative scenario when Data found
* @param: N/A
* @return: void
* ───────────────────────────────────────────────────────────────────────────────────────────────
*/
    @isTest
    static void testSaveSaleGuest() {
    
        MDEN_SaveSaleGuest.MDEN_GetRequestWrapper requestWrapper = new MDEN_SaveSaleGuest.MDEN_GetRequestWrapper();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        requestWrapper.sale_id = '9477';
        requestWrapper.partner_id = '0';
        requestWrapper.parent_id = String.ValueOf(opp.Id);
        requestWrapper.title = 'Mr.';
        requestWrapper.first_name = 'Ajit';
        requestWrapper.last_name = 'Kumar';
        requestWrapper.gender = 'male';
        requestWrapper.dob = '1987-09-17';
        requestWrapper.age = '32';
        requestWrapper.passport_no = null;
        requestWrapper.pnr_no = '123';
        requestWrapper.class_type = 'first';
        requestWrapper.mobile = null;
        requestWrapper.country_code = 'XX';
        requestWrapper.source = 'website';
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(JSON.serialize(requestWrapper));
        RestContext.request = req;
        MDEN_SaveSaleGuest.MDEN_GetResponseWrapper response = MDEN_SaveSaleGuest.saveSaleGuest();
      
      System.assertEquals('true', response.status);
        
    }

/* 
* ───────────────────────────────────────────────────────────────────────────────────────────────
* @description:testSaveSaleGuestExceptionHandling method is used to test the exception scenario
* @param: N/A
* @return: void
* ───────────────────────────────────────────────────────────────────────────────────────────────
*/
    @isTest
    static void testSaveSaleGuestExceptionHandling() {
        MDEN_SaveSaleGuest.MDEN_GetRequestWrapper requestWrapper = new MDEN_SaveSaleGuest.MDEN_GetRequestWrapper();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        requestWrapper.sale_id = '9477';
        requestWrapper.partner_id = '0';
         requestWrapper.parent_id = String.ValueOf(opp.Id);
        requestWrapper.title = 'Mr.';
        requestWrapper.first_name = 'Ajit';
        requestWrapper.last_name = 'Kumar';
        requestWrapper.gender = 'male';
        requestWrapper.dob = 'invalid-date'; // This will trigger a Date parsing exception
        requestWrapper.age = '32';
        requestWrapper.passport_no = null;
        requestWrapper.pnr_no = '123';
        requestWrapper.class_type = 'first';
        requestWrapper.mobile = null;
        requestWrapper.country_code = 'IN';
        requestWrapper.source = 'website';
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(JSON.serialize(requestWrapper));
        RestContext.request = req;
        MDEN_SaveSaleGuest.MDEN_GetResponseWrapper response = MDEN_SaveSaleGuest.saveSaleGuest();
        System.assertEquals('Invalid date: invalid-date',response.message);
    }
}