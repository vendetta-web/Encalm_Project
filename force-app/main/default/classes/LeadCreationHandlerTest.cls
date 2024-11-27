@isTest
public class LeadCreationHandlerTest {
    @isTest
    static void testGetLeadsForCase() {
        // Create a test Case
        Case testCase = new Case(
            Subject = 'Test Case',
            SuppliedEmail = 'test@example.com',
            SuppliedName = 'Test User',
            SuppliedPhone = '1234567890',
            Status = 'New'
        );
        insert testCase;

        // Create a test Lead associated with the Case
        Lead testLead = new Lead(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'john.doe@example.com',
            Phone = '9876543210',
            Company = 'Test Company',
            Case__c = testCase.Id // Ensure the Related Case lookup is set
        );
        insert testLead;

        // Perform the test
        Test.startTest();
        List<Lead> leadsForCase = LeadCreationHandler.getLeadsForCase(testCase.Id);
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, leadsForCase, 'Leads for Case should not be null');
        System.assertEquals(1, leadsForCase.size(), 'There should be one Lead associated with the Case');
        System.assertEquals(testLead.Id, leadsForCase[0].Id, 'The returned Lead ID should match the test Lead ID');
    }

    @isTest
    static void testGetLeadsForCaseWithInvalidCaseId() {
        // Perform the test with an invalid Case ID
        Test.startTest();
        try {
            List<Lead> leadsForCase = LeadCreationHandler.getLeadsForCase(null);
            System.assert(false, 'An exception should have been thrown for a null Case ID');
        } catch (IllegalArgumentException e) {
            System.assertEquals('Case ID cannot be null or empty.', e.getMessage(), 'The exception message should match');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetLeadsForCaseWithNoLeads() {
        // Create a test Case without any associated Leads
        Case testCase = new Case(
            Subject = 'Case with no Leads',
            SuppliedEmail = 'no.leads@example.com',
            Status = 'New'
        );
        insert testCase;

        // Perform the test
        Test.startTest();
        List<Lead> leadsForCase = LeadCreationHandler.getLeadsForCase(testCase.Id);
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, leadsForCase, 'Leads for Case should not be null');
        System.assertEquals(0, leadsForCase.size(), 'There should be no Leads associated with the Case');
    }
}