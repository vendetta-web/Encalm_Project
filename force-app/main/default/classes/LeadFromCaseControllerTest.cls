@IsTest
public class LeadFromCaseControllerTest {
    
    @testSetup
    static void setupTestData() {
        // Create a test Case record
        Case testCase = new Case(
            Subject = 'Test Subject',
            SuppliedName = 'John Doe',
            SuppliedEmail = 'john.doe@example.com',
            SuppliedPhone = '123-456-7890'
        );
        insert testCase;
        
        // Create a test Lead record
        Lead testLead = new Lead(
            FirstName = 'Jane',
            LastName = 'Doe',
            Email = 'jane.doe@example.com',
            Company = 'Test Company',
            Phone = '987-654-3210'
        );
        insert testLead;
    }
    
    @IsTest
    static void testLeadFromCaseController() {
        // Fetch the test Case record
        Case testCase = [SELECT Id FROM Case WHERE Subject = 'Test Subject' LIMIT 1];
        
        // Instantiate the LeadFromCaseController
        LeadFromCaseController controller = new LeadFromCaseController();
        
        // Set the caseId parameter
        ApexPages.currentPage().getParameters().put('caseId', testCase.Id);
        
        // Call the populateLeadFromCase method
        controller.populateLeadFromCase();
        
        // Verify that the Lead record is populated correctly
        System.assertEquals('john.doe@example.com', controller.leadRecord.Email);
        System.assertEquals('Doe', controller.leadRecord.LastName);
        //System.assertEquals('Test Subject', controller.leadRecord.Company);
        System.assertEquals('123-456-7890', controller.leadRecord.Phone);
        
        // Save the Lead record
        controller.saveLead();
        
        // Verify that the Lead record is saved successfully
        Lead savedLead = [SELECT Id, Email, LastName, Phone FROM Lead WHERE Email = 'john.doe@example.com' LIMIT 1];
        System.assertNotEquals(null, savedLead);
        System.assertEquals('john.doe@example.com', savedLead.Email);
        System.assertEquals('Doe', savedLead.LastName);
        System.assertEquals('123-456-7890', savedLead.Phone);
    }
    
    @IsTest
    static void testLeadFromCaseControllerWithLeadId() {
        // Fetch the test Lead record
        Lead testLead = [SELECT Id FROM Lead WHERE Email = 'jane.doe@example.com' LIMIT 1];
        
        // Instantiate the LeadFromCaseController
        LeadFromCaseController controller = new LeadFromCaseController();
        
        // Set the leadId parameter
        ApexPages.currentPage().getParameters().put('leadId', testLead.Id);
        
        // Call the populateLeadFromCase method
        controller.populateLeadFromCase();
        
        // Verify that the Lead record is populated correctly
        System.assertEquals('jane.doe@example.com', controller.leadRecord.Email);
        System.assertEquals('Doe', controller.leadRecord.LastName);
        //System.assertEquals('Test Company', controller.leadRecord.Company);
        System.assertEquals('987-654-3210', controller.leadRecord.Phone);
        
        // Save the Lead record
        controller.saveLead();
        
        // Verify that the Lead record is saved successfully
        Lead savedLead = [SELECT Id, Email, LastName, Phone FROM Lead WHERE Email = 'jane.doe@example.com' LIMIT 1];
        System.assertNotEquals(null, savedLead);
        System.assertEquals('jane.doe@example.com', savedLead.Email);
        System.assertEquals('Doe', savedLead.LastName);
        System.assertEquals('987-654-3210', savedLead.Phone);
    }
}