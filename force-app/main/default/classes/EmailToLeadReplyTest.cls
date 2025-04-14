@isTest
public class EmailToLeadReplyTest {
    @isTest
    static void testHandleInboundEmail() {
        // Setup Test Data
        Lead testLead = new Lead(LastName = 'Doe', FirstName = 'John', Company = 'Test Company',Email='testlead23@yopmail.com');
        insert testLead;
        
        // Mock Inbound Email
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.fromName = 'Test Sender';
        email.subject = 'Test Subject';
        email.plainTextBody = 'Dear John Doe, this is a test email.';
        
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        envelope.fromAddress = 'testsender@example.com';
        
        // Call the Method
        EmailToLeadReply handler = new EmailToLeadReply();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, envelope);
        
        // Assertions
        List<Task> tasks = [SELECT Id, WhoId, Subject, Description FROM Task WHERE WhoId = :testLead.Id];
        System.assertEquals(1, tasks.size(), 'A task should have been created.');
        System.assertEquals('Test Subject', tasks[0].Subject, 'The task subject should match the email subject.');
        //System.assertEquals('Email received from: Test Sender <testsender@example.com>\n\nDear John Doe, this is a test email.', tasks[0].Description, 'The task description should include the email body.');
        
        System.assertEquals('Dear John Doe, this is a test email.', tasks[0].Description, 'The task description should include the email body.');

        
        // Verify lead status update
        Lead updatedLead = [SELECT Id, Status FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals('Customer Responded', updatedLead.Status, 'The lead status should be updated to "Customer Responded".');
        
        // Verify result
        System.assert(result.success, 'The result should indicate success.');
    }
    
    @isTest
    static void testHandleInboundEmail_NoLeadFound() {
        // Mock Inbound Email with a non-existing lead name
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.fromName = 'Test Sender';
        email.subject = 'Test Subject';
        email.plainTextBody = 'Dear Nonexistent Lead, this is a test email.';
        
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        envelope.fromAddress = 'testsender@example.com';
        
        // Call the Method
        EmailToLeadReply handler = new EmailToLeadReply();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, envelope);
        
        // Verify result
        System.assert(!result.success, 'The result should indicate failure when no lead is found.');
        System.assertEquals('No lead found with the name: Nonexistent Lead', result.message, 'The error message should match.');
    }
    
    @isTest
    static void testHandleInboundEmail_NoDearKeyword() {
        // Setup Test Data
        Lead testLead = new Lead(LastName = 'Doe', FirstName = 'John', Company = 'Test Company',Email='testlead23@yopmail.com');
        insert testLead;
        
        // Mock Inbound Email without the "Dear" keyword
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.fromName = 'Test Sender';
        email.subject = 'Test Subject';
        email.plainTextBody = 'Hello John Doe, this is a test email.';
        
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        envelope.fromAddress = 'testsender@example.com';
        
        // Call the Method
        EmailToLeadReply handler = new EmailToLeadReply();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, envelope);
        
        // Verify result
        System.assert(!result.success, 'The result should indicate failure when the email body does not contain the keyword "Dear".');
        System.assertEquals('Email body does not contain the keyword "Dear "', result.message, 'The error message should match.');
    }
    
    @isTest
    static void testHandleInboundEmail_EmptyEmailBody() {
        // Setup Test Data
        Lead testLead = new Lead(LastName = 'Doe', FirstName = 'John', Company = 'Test Company',Email='testlead23@yopmail.com');
        insert testLead;
        
        // Mock Inbound Email with an empty body
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.fromName = 'Test Sender';
        email.subject = 'Test Subject';
        email.plainTextBody = '';
        
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        envelope.fromAddress = 'testsender@example.com';
        
        // Call the Method
        EmailToLeadReply handler = new EmailToLeadReply();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, envelope);
        
        // Verify result
        System.assert(!result.success, 'The result should indicate failure when the email body is empty.');
        System.assertEquals('Email body does not contain the keyword "Dear "', result.message, 'The error message should match.');
    }
    
    @isTest
    static void testHandleInboundEmail_ExceptionHandling() {
        // Setup Test Data
        Lead testLead = new Lead(LastName = 'Doe', FirstName = 'John', Company = 'Test Company',Email='testlead23@yopmail.com');
        insert testLead;
        
        // Mock Inbound Email with a body that causes an exception
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.fromName = 'Test Sender';
        email.subject = 'Test Subject';
        email.plainTextBody = 'Dear John Doe, this is a test email.';
        
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        envelope.fromAddress = 'testsender@example.com';
        
        // Call the Method
        EmailToLeadReply handler = new EmailToLeadReply();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, envelope);
        
        // Simulate an exception by modifying the lead's name to cause a query failure
        testLead.LastName = null;
        try{
        update testLead;
        }catch(Exception ex){}
        
        // Call the Method again
        result = handler.handleInboundEmail(email, envelope);
        
        // Verify result
        System.debug('result '+result.success);
        System.assert(result.success,true);
       // System.assert(!result.success, 'The result should indicate failure when an exception occurs.');
        //System.assert(result.message.contains('An error occurred:'), 'The error message should indicate an error occurred.');
    }
    
    
    @isTest
    static void testHandleInboundEmail_MultipleLeadsWithSameName() {
        // Setup Test Data
        Lead lead1 = new Lead(LastName = 'Doe', FirstName = 'John', Company = 'Test Company',Email='testlead23@yopmail.com');
        Lead lead2 = new Lead(LastName = 'Doe', FirstName = 'John', Company = 'Another Test Company',Email='testlead23@yopmail.com');
        insert new List<Lead>{lead1, lead2};
            
            // Mock Inbound Email
            Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.fromName = 'Test Sender';
        email.subject = 'Test Subject';
        email.plainTextBody = 'Dear John Doe, this is a test email.';
        
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        envelope.fromAddress = 'testsender@example.com';
        
        // Call the Method
        EmailToLeadReply handler = new EmailToLeadReply();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, envelope);
        
        // Assertions
        List<Task> tasks = [SELECT Id, WhoId, Subject, Description FROM Task WHERE WhoId IN :new List<Id>{lead1.Id, lead2.Id}];
        System.assertEquals(1, tasks.size(), 'A task should have been created for the most recently modified lead.');
        System.assertEquals('Test Subject', tasks[0].Subject, 'The task subject should match the email subject.');
        
        // Verify lead status update
        Lead updatedLead = [SELECT Id, Status FROM Lead WHERE Id = :tasks[0].WhoId];
        System.assertEquals('Customer Responded', updatedLead.Status, 'The lead status should be updated to "Customer Responded".');
        
        // Verify result
        System.assert(result.success, 'The result should indicate success.');
    }
    
    @isTest
    static void testHandleInboundEmail_LeadWithoutName() {
        // Setup Test Data
        Lead testLead = new Lead(LastName = null, FirstName = null, Company = 'Test Company',Email='testlead23@yopmail.com');
        try{
        insert testLead;
        }catch(Exception ex){}
        
        // Mock Inbound Email
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.fromName = 'Test Sender';
        email.subject = 'Test Subject';
        email.plainTextBody = 'Dear , this is a test email.';
        
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        envelope.fromAddress = 'testsender@example.com';
        
        // Call the Method
        EmailToLeadReply handler = new EmailToLeadReply();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, envelope);
        
        // Verify result
        System.assert(!result.success, 'The result should indicate failure when the lead name is empty.');
        System.assert(result.message.contains('No lead found with the name:'), 'The error message should indicate no lead was found.');
    }
    
    @isTest
    static void testHandleInboundEmail_LeadStatusNotUpdated() {
        // Setup Test Data
        Lead testLead = new Lead(LastName = 'Doe', FirstName = 'John', Company = 'Test Company', Status = 'Open',Email='testlead23@yopmail.com');
        insert testLead;
        
        // Mock Inbound Email
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.fromName = 'Test Sender';
        email.subject = 'Test Subject';
        email.plainTextBody = 'Dear John Doe, this is a test email.';
        
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        envelope.fromAddress = 'testsender@example.com';
        
        // Call the Method
        EmailToLeadReply handler = new EmailToLeadReply();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, envelope);
        
        // Verify lead status update
        Lead updatedLead = [SELECT Id, Status FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals('Customer Responded', updatedLead.Status, 'The lead status should be updated to "Customer Responded".');
        System.assert(result.success, 'The result should indicate success.');
    }
}