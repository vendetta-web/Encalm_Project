@isTest
public class MDEN_ForgotPasswordTest {
    
    @testSetup
    static void testGetForgotPassword_UserExists() {
        // Setup mock account data
        Account testAccount = new Account(
            FirstName = 'Test Account',
            LastName = 'Account',
            PersonEmail = 'testuser@example.com',
            password__c = 'password123'
        );
        insert testAccount;
        // Create a mock RestRequest
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/forgot_password';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"email":"testuser@example.com"}');
        RestContext.request = req;
        Test.startTest();
        MDEN_ForgotPassword.MDEN_GetResponseWrapper response = MDEN_ForgotPassword.getForgotPassword();       
        Test.stopTest();
       System.assertEquals('true', response.status);
    }
    
    @isTest
    static void testGetForgotPassword_UserNotFound() {
        // Create a mock RestRequest
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/forgot_password';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"email":"nonexistentuser@example.com"}');
        RestContext.request = req;
        Test.startTest();
        MDEN_ForgotPassword.MDEN_GetResponseWrapper response = MDEN_ForgotPassword.getForgotPassword();
        Test.stopTest();
        System.assertEquals('false', response.status);
    }

    @isTest
    static void testGetForgotPassword_ExceptionHandling() {
        // Create a mock RestRequest
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/forgot_password';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"email":"testuser@example.com"}');
        RestContext.request = req;
        Test.startTest();
        MDEN_ForgotPassword.MDEN_GetResponseWrapper response = MDEN_ForgotPassword.getForgotPassword();
        Test.stopTest();
        System.assertNotEquals('', response.message);
    }
}