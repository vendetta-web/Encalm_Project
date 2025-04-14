/**
* @File Name : MDEN_GetSalutationMasterTest.cls
* @Description : Test Class for MDEN_GetSalutationMaster.cls
* @Author : Abhishek
* @Last Modified By : Abhishek
* @Last Modified On : April 10, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | April 10, 2025 |  Abhishek | Initial Version
**/
@isTest
public class MDEN_GetSalutationMasterTest {
    
    @isTest
    static void testGetSalutationSuccess() {
        // Create test data
        List<Salutation__c> salutaionList = new List<Salutation__c>();
        Salutation__c sal1 = new Salutation__c();
        sal1.Salutation_Name__c = 'Mr.';
        salutaionList.add(sal1);
        
        Salutation__c sal2 = new Salutation__c();
        sal2.Salutation_Name__c = 'Mrs.';
        salutaionList.add(sal2);
        
        insert salutaionList;
        
        // Creating RestRequest
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/get_salutation/';
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
		Test.startTest();
        	MDEN_GetSalutationMaster.MDEN_GetResponseWrapper response = MDEN_GetSalutationMaster.getSalutation();
        Test.stopTest();

        System.assertEquals('true', response.status);
        System.assertEquals('data found.', response.message);
    }

    @isTest
    static void testGetSalutationEmpty() {
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/get_salutation/';
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
		Test.startTest();
        	MDEN_GetSalutationMaster.MDEN_GetResponseWrapper response = MDEN_GetSalutationMaster.getSalutation();
        Test.stopTest();

        System.assertEquals('false', response.status);
        System.assertEquals('data not found.', response.message);
    }
}