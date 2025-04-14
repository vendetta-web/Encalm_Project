/**
* @File Name : MDEN_GetStateMasterTest.cls
* @Description : Test Class for MDEN_GetStateMaster.cls
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
public class MDEN_GetStateMasterTest {
    
    @isTest
    static void testGetStateSuccess() {
        // creating Test Data
        Country__c country = new Country__c();
        country.Country_Name__c = 'India' ;
        insert country;
        
        List<State__c> stateList = new List<State__c>();
        State__c state1 = new State__c();
        state1.State_Name__c = 'Delhi';
        state1.Country__c = country.Id;
        stateList.add(state1);
        
        State__c state2 = new State__c();
        state2.State_Name__c = 'Maharashtra';
        state2.Country__c = country.Id;        
        stateList.add(state2);
        
        insert stateList;
        // creating RestRequest
        MDEN_GetStateMaster.MDEN_GetRequestWrapper reqWrapper = new MDEN_GetStateMaster.MDEN_GetRequestWrapper();
        reqWrapper.country_id = 'India';
        String jsonReq = JSON.serialize(reqWrapper);
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/get_state/';
        req.httpMethod = 'GET';
        req.requestBody = Blob.valueOf(jsonReq);
        RestContext.request = req;
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        Test.startTest();
        MDEN_GetStateMaster.MDEN_GetResponseWrapper response = MDEN_GetStateMaster.getState();
        Test.stopTest();
        
        System.assertEquals('true', response.status);        
        System.assertEquals('data found.', response.message);        
    }
    
    @isTest
    static void testGetStateNoMatch() {
        
        MDEN_GetStateMaster.MDEN_GetRequestWrapper reqWrapper = new MDEN_GetStateMaster.MDEN_GetRequestWrapper();
        reqWrapper.country_id = 'NonExistingCountry';
        String jsonReq = JSON.serialize(reqWrapper);
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/get_state/';
        req.httpMethod = 'GET';
        req.requestBody = Blob.valueOf(jsonReq);
        RestContext.request = req;
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        Test.startTest();
        MDEN_GetStateMaster.MDEN_GetResponseWrapper response = MDEN_GetStateMaster.getState();
        Test.stopTest();
        
        System.assertEquals('false', response.status);
        System.assertEquals('data not found.', response.message);
    }
}