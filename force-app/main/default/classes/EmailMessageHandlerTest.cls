@isTest
private class EmailMessageHandlerTest {

    // 🔹 Shared test data setup
    @testSetup
    static void setupTestData() {
        // Create Cases with various statuses
        List<Case> cases = new List<Case>{
            new Case(Status = 'New', Origin = 'Email'),                      // Case 1
            new Case(Status = 'New', Origin = 'Email'),                      // Case 2
            new Case(Status = 'Awaiting Customer Response', Origin = 'Email'), // Case 3
            new Case(Status = 'Customer Responded', Origin = 'Email')        // Case 4
        };
        insert cases;

        // Create related EmailMessages (latest emails)
        List<EmailMessage> emailMessages = new List<EmailMessage>{
            new EmailMessage(Subject = 'Agent follow-up email', Incoming = false, ParentId = cases[0].Id), // Outbound
            new EmailMessage(Subject = 'Customer response', Incoming = true, ParentId = cases[1].Id),       // Inbound
            new EmailMessage(Subject = 'Customer follow-up', Incoming = true, ParentId = cases[2].Id),     // Inbound
            new EmailMessage(Subject = 'Agent reply to customer', Incoming = false, ParentId = cases[3].Id) // Outbound
        };
        insert emailMessages;
    }

    // 🔹 Test: New Case with Outgoing Email => Should update to "Awaiting Customer Response"
    @isTest
    static void givenNewCaseWithOutgoingEmail_whenUpdateCaseStatus_thenSetToAwaitingCustomerResponse() {
        List<EmailMessage> emails = [SELECT Id, ParentId, Subject, Incoming FROM EmailMessage WHERE Subject = 'Agent follow-up email'];

        Test.startTest();
        EmailMessageHandler.updateCaseStatus(emails);
        Test.stopTest();

        Case updatedCase = [SELECT Id, Status FROM Case WHERE Id = :emails[0].ParentId];
        System.assertEquals('Awaiting Customer Response', updatedCase.Status,
            'Status should be updated to Awaiting Customer Response');
    }

    // 🔹 Test: New Case with Incoming Email => Should update to "Customer Responded"
    @isTest
    static void givenNewCaseWithIncomingEmail_whenUpdateCaseStatus_thenSetToCustomerResponded() {
        List<EmailMessage> emails = [SELECT Id, ParentId, Subject, Incoming FROM EmailMessage WHERE Subject = 'Customer response'];

        Test.startTest();
        EmailMessageHandler.updateCaseStatus(emails);
        Test.stopTest();

        Case updatedCase = [SELECT Id, Status FROM Case WHERE Id = :emails[0].ParentId];
        System.assertEquals('Customer Responded', updatedCase.Status,
            'Status should be updated to Customer Responded');
    }

    // 🔹 Test: Awaiting Customer Response with Incoming Email => Should update to "Customer Responded"
    @isTest
    static void givenAwaitingResponseCaseWithIncomingEmail_whenUpdateCaseStatus_thenSetToCustomerResponded() {
        List<EmailMessage> emails = [SELECT Id, ParentId, Subject, Incoming FROM EmailMessage WHERE Subject = 'Customer follow-up'];

        Test.startTest();
        EmailMessageHandler.updateCaseStatus(emails);
        Test.stopTest();

        Case updatedCase = [SELECT Id, Status FROM Case WHERE Id = :emails[0].ParentId];
        System.assertEquals('Customer Responded', updatedCase.Status,
            'Status should be updated to Customer Responded');
    }

    // 🔹 Test: Customer Responded Case with Outgoing Email => Should update to "Awaiting Customer Response"
    @isTest
    static void givenRespondedCaseWithOutgoingEmail_whenUpdateCaseStatus_thenSetToAwaitingCustomerResponse() {
        List<EmailMessage> emails = [SELECT Id, ParentId, Subject, Incoming FROM EmailMessage WHERE Subject = 'Agent reply to customer'];

        Test.startTest();
        EmailMessageHandler.updateCaseStatus(emails);
        Test.stopTest();

        Case updatedCase = [SELECT Id, Status FROM Case WHERE Id = :emails[0].ParentId];
        System.assertEquals('Awaiting Customer Response', updatedCase.Status,
            'Status should be updated to Awaiting Customer Response');
    }

    // 🔹 Test: Email not related to Case => Should not update anything
    @isTest
    static void givenEmailWithoutCase_whenUpdateCaseStatus_thenNoChange() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        EmailMessage unrelatedEmail = new EmailMessage(Subject = 'Random Email', Incoming = true, ParentId = acc.Id);
        insert unrelatedEmail;

        Test.startTest();
        EmailMessageHandler.updateCaseStatus(new List<EmailMessage>{unrelatedEmail});
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM EmailMessage WHERE ParentId = :acc.Id],
            'Email should be unrelated and cause no updates');
    }
}