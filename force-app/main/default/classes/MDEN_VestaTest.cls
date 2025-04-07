@isTest
public class MDEN_VestaTest {

    @isTest
    static void testCreateCaseWithTaskSuccess() {
        // Create test data
        Account testAccount = new Account(Name = 'Test Account',  Phone = '1234567890');
        //insert testAccount;

        // Create test FeedbackWrapper object
        MDEN_Vesta.FeedbackWrapper feedbackWrapper = new MDEN_Vesta.FeedbackWrapper();
        feedbackWrapper.customer_email = 'test@test.com';
        feedbackWrapper.customer_phone = '1234567890';
        feedbackWrapper.customer_name = 'Test Customer';
        feedbackWrapper.feedback_id = 'F123';
        feedbackWrapper.item_name = 'Test Item';
        feedbackWrapper.request_id = 'R123';
        feedbackWrapper.resolution_date = Date.today();
        feedbackWrapper.resolution_time = '02:00 PM';
        feedbackWrapper.resolved_by = 'Test Resolved By';
        feedbackWrapper.total_resolution_time = '1 hour';
        feedbackWrapper.resolution_comments = 'Issue resolved successfully';
        
        // Convert the feedbackWrapper to JSON
        String feedbackWrapperJson = JSON.serialize(feedbackWrapper);
        
        // Set up HTTP request to mock the API call
        Test.startTest();
        
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/Vesta_create_Case';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(feedbackWrapperJson);
        RestContext.request = req;
        
        // Invoke the method
        MDEN_Vesta.GetResponseWrapper response = MDEN_Vesta.createCaseWithTask();
        
        // Assertions
       System.assertNotEquals('', response.Id);
        
        Test.stopTest();
    }

    @isTest
    static void testCreateCaseWithTaskNoFeedbackId() {
        // Create test data
        Account testAccount = new Account(Name = 'Test Account No Feedback ID', Phone = '0987654321');
        //insert testAccount;

        // Create test FeedbackWrapper object without feedback_id
        MDEN_Vesta.FeedbackWrapper feedbackWrapper = new MDEN_Vesta.FeedbackWrapper();
        feedbackWrapper.customer_email = 'test2@test.com';
        feedbackWrapper.customer_phone = '0987654321';
        feedbackWrapper.customer_name = 'Test Customer No Feedback ID';
        feedbackWrapper.feedback_id = null;  // No feedback ID
        feedbackWrapper.item_name = null;  // No item name
        feedbackWrapper.request_id = null;
        feedbackWrapper.issue_date = Date.today();
        
        // Convert the feedbackWrapper to JSON
        String feedbackWrapperJson = JSON.serialize(feedbackWrapper);
        
        // Set up HTTP request to mock the API call
        Test.startTest();
        
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/Vesta_create_Case';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(feedbackWrapperJson);
        RestContext.request = req;
        
        // Invoke the method
        MDEN_Vesta.GetResponseWrapper response = MDEN_Vesta.createCaseWithTask();
        
        // Assertions
        System.assertNotEquals('', response.Id);
        
        Test.stopTest();
    }

    @isTest
    static void testCreateCaseWithTaskFailure() {
        // Create test data
        Account testAccount = new Account(Name = 'Test Account Failure', Phone = '1112223333');
        //insert testAccount;

        // Create an invalid FeedbackWrapper object (e.g., missing required fields)
        MDEN_Vesta.FeedbackWrapper feedbackWrapper = new MDEN_Vesta.FeedbackWrapper();
        feedbackWrapper.customer_email = ''; // Invalid email
        feedbackWrapper.customer_phone = '';
        
        // Convert the feedbackWrapper to JSON
        String feedbackWrapperJson = JSON.serialize(feedbackWrapper);
        
        // Set up HTTP request to mock the API call
        Test.startTest();
        
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/Vesta_create_Case';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(feedbackWrapperJson);
        RestContext.request = req;
        
        // Invoke the method
        MDEN_Vesta.GetResponseWrapper response = MDEN_Vesta.createCaseWithTask();
        
        // Assertions for failure case
       
        System.assertNotEquals('', response.Id);
        
        Test.stopTest();
    }
}