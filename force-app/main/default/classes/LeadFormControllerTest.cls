@IsTest
public class LeadFormControllerTest {
    @IsTest
    static void testSubmitForm() {
        // Create a test lead
        Lead testLead = new Lead(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'john.doe@example.com',
            Phone = '123-456-7890',
            Company = 'Test Company',
            Travel_Date__c = Date.today(),
            Number_of_Adult__c = 2
        );
        insert testLead;
        
        // Create a test case
        Case testCase = new Case(
            Status = 'New'
        );
        insert testCase;
        
        // Create a test lead form controller
        LeadFormController controller = new LeadFormController(new ApexPages.StandardController(testLead));
        controller.caseId = testCase.Id;
        controller.leadId = testLead.Id;
        
        // Call the submitForm method
        PageReference pageRef = controller.submitForm();
        
        // Verify the results
        System.assertNotEquals(null, pageRef, 'The page reference should not be null');
        System.assert(pageRef.getUrl().contains(testLead.Id), 'The page reference URL should contain the lead Id');
        
        // Verify that the lead was updated
        Lead updatedLead = [SELECT Id, FirstName, LastName, Email, Phone, Company, Travel_Date__c, Number_of_Adult__c FROM Lead WHERE Id = :testLead.Id LIMIT 1];
        System.assertEquals('John', updatedLead.FirstName, 'The first name should be updated');
        System.assertEquals('Doe', updatedLead.LastName, 'The last name should be updated');
        System.assertEquals('john.doe@example.com', updatedLead.Email, 'The email should be updated');
        System.assertEquals('123-456-7890', updatedLead.Phone, 'The phone should be updated');
        System.assertEquals('Test Company', updatedLead.Company, 'The company should be updated');
        System.assertEquals(Date.today(), updatedLead.Travel_Date__c, 'The travel date should be updated');
        System.assertEquals(2, updatedLead.Number_of_Adult__c, 'The number of adult should be updated');
        
        // Verify that the case was updated
        Case updatedCase = [SELECT Id, Status FROM Case WHERE Id = :testCase.Id LIMIT 1];
        System.assertEquals('Closed', updatedCase.Status, 'The case status should be updated to closed');
    }
    
    @IsTest
    static void testSubmitFormWithNewLead() {
        // Create a test lead
        Lead testLead = new Lead(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'john.doe@example.com',
            Phone = '123-456-7890',
            Company = 'Test Company',
            Travel_Date__c = Date.today(),
            Number_of_Adult__c = 2
        );
        
        // Create a test lead form controller
        LeadFormController controller = new LeadFormController(new ApexPages.StandardController(testLead));
        
        // Call the submitForm method
        PageReference pageRef = controller.submitForm();
        
        // Verify the results
        System.assertNotEquals(null, pageRef, 'The page reference should not be null');
        System.assert(pageRef.getUrl().contains(testLead.Id), 'The page reference URL should contain the lead Id');
        
        // Verify that the lead was inserted
        Lead insertedLead = [SELECT Id, FirstName, LastName, Email, Phone, Company, Travel_Date__c, Number_of_Adult__c FROM Lead WHERE Id = :testLead.Id LIMIT 1];
        System.assertEquals('John', insertedLead.FirstName, 'The first name should be inserted');
        System.assertEquals('Doe', insertedLead.LastName, 'The last name should be inserted');
        System.assertEquals('john.doe@example.com', insertedLead.Email, 'The email should be inserted');
        System.assertEquals('123-456-7890', insertedLead.Phone, 'The phone should be inserted');
        System.assertEquals('Test Company', insertedLead.Company, 'The company should be inserted');
        System.assertEquals(Date.today(), insertedLead.Travel_Date__c, 'The travel date should be inserted');
        System.assertEquals(2, insertedLead.Number_of_Adult__c, 'The number of adult should be inserted');
    }
    
    @IsTest
    static void testSubmitFormWithInvalidLeadId() {
        // Create a test lead
        Lead testLead = new Lead(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'john.doe@example.com',
            Phone = '123-456-7890',
            Company = 'Test Company',
            Travel_Date__c = Date.today(),
            Number_of_Adult__c = 2
        );
        
        // Create a test lead form controller
        LeadFormController controller = new LeadFormController(new ApexPages.StandardController(testLead));
        controller.leadId = '00Q2C00000INVALID';
        
        // Call the submitForm method
        PageReference pageRef = controller.submitForm();
        
        // Verify the results
        System.assertEquals(null, pageRef, 'The page reference should be null');
        System.assertEquals('Error: No lead found with the provided Id', ApexPages.getMessages()[0].getDetail(), 'The error message should match');
    }
}