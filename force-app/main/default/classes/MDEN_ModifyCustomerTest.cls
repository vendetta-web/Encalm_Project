/**
* @File Name : MDEN_ModifyCustomerTest.cls
* @Description : Test Class for MDEN_ModifyCustomer.cls
* @Author : Maxify Development Team
* @Created Date : April 9, 2025
**/

@isTest
public class MDEN_ModifyCustomerTest {
    @isTest
    static void updateCustomerTestMethod(){
        
        Salutation__c salutationRecord = new Salutation__c(Salutation_Name__c = 'Mr.');
        insert salutationRecord;
        
        Country__c conRecord = new Country__c(Country_Name__c = 'India' );
        insert conRecord;
        
        State__c stateRecord = new State__c(State_Name__c = 'Delhi' , Country__c = conRecord.Id);
        insert stateRecord;
        Account accRecord = new Account(
            FirstName = 'Test',
            LastName  = 'Account',
            Phone = '1231456789',
            BillingStreet = '123 Main Street',
            BillingCity = 'New Delhi',
            BillingState = 'Delhi',
            BillingPostalCode = '110091',
            BillingCountry = 'India',
            PersonEmail = 'testemail@gmail.com'
        );
        
        insert accRecord;
        
        // Prepare customer JSON input
        MDEN_ModifyCustomer.Customer requestCustomer = new MDEN_ModifyCustomer.Customer();
        requestCustomer.id = accRecord.Id;
        requestCustomer.title = '000';
        requestCustomer.first_name = 'Test';
        requestCustomer.last_name = 'Customer Account';
        requestCustomer.email = 'testemail@gmail.com';
        requestCustomer.mobile = '2084422881';
        requestCustomer.gender = 'Male';
        requestCustomer.dob = '1995-08-01';
        requestCustomer.city = 'New Delhi';
        requestCustomer.state = '000002';
        requestCustomer.country_code = '0001';
        requestCustomer.pincode = '110091';
        requestCustomer.source = 'Website';

        String jsonReq = JSON.serialize(requestCustomer);

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/modify_customer/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonReq);
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        MDEN_ModifyCustomer.MDEN_GetResponseWrapper response = MDEN_ModifyCustomer.updateCustomer();
        Test.stopTest();
        System.assertEquals('true', response.id, 'Response should indicate success');

        Account updatedAcc = [SELECT FirstName, LastName, PersonEmail, PersonMobilePhone, BillingCity FROM Account WHERE Id = :accRecord.Id];
        System.assertEquals('Customer Account', updatedAcc.LastName);
    }
    @isTest
    static void testUpdateCustomer_RecordNotFound() {
        MDEN_ModifyCustomer.Customer requestCustomer = new MDEN_ModifyCustomer.Customer();
        requestCustomer.id = '';
        requestCustomer.title = '001';
        requestCustomer.first_name = 'Test';
        requestCustomer.last_name = 'Business Account';
        requestCustomer.email = 'testemail@gmail.com';
        requestCustomer.mobile = '2084422881';
        requestCustomer.gender = 'Male';
        requestCustomer.dob = '1995-08-01';
        requestCustomer.city = 'New Delhi';
        requestCustomer.state = '000002';
        requestCustomer.country_code = '0001';
        requestCustomer.pincode = '110091';
        requestCustomer.source = 'Website';

        String jsonReq = JSON.serialize(requestCustomer);

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/modify_customer/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonReq);
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        MDEN_ModifyCustomer.MDEN_GetResponseWrapper response = MDEN_ModifyCustomer.updateCustomer();
        Test.stopTest();
        System.assertEquals('false', response.status);
    }
    @isTest
    static void updateCustomerDuplicateCheck(){
        List<Account> accList = new List<Account>();
        for(integer i=0; i<2; i++){
            Account accRecord = new Account(
                FirstName = 'Test '+i,
                LastName  = 'Account',
                Phone = '123145678'+i,
                BillingStreet = '123 Main Street',
                BillingCity = 'New Delhi',
                BillingState = 'Delhi',
                BillingPostalCode = '110091',
                BillingCountry = 'India',
                PersonEmail = 'testEmail@gmail.com'
            );
            accList.add(accRecord);
        }
        
        insert accList;
        
        // Prepare customer JSON input
        MDEN_ModifyCustomer.Customer requestCustomer = new MDEN_ModifyCustomer.Customer();
        requestCustomer.id = accList[0].Id;
        requestCustomer.title = '000';
        requestCustomer.first_name = 'Test';
        requestCustomer.last_name = 'Business Account';
        requestCustomer.email = 'testEmail@gmail.com';
        requestCustomer.mobile = '2084422881';
        requestCustomer.gender = 'Male';
        requestCustomer.dob = '1995-08-01';
        requestCustomer.city = 'New Delhi';
        requestCustomer.state = '000002';
        requestCustomer.country_code = '0001';
        requestCustomer.pincode = '110091';
        requestCustomer.source = 'Website';

        String jsonReq = JSON.serialize(requestCustomer);

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/modify_customer/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonReq);
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        MDEN_ModifyCustomer.MDEN_GetResponseWrapper response = MDEN_ModifyCustomer.updateCustomer();
        Test.stopTest();
        System.assertEquals('false', response.status);
        System.assertEquals('Customer Already Exists in the system with same email id.', response.message);
    }
}