/**
* @File Name : LeadFromCaseControllerTest.cls
* @Description : Test Class for LeadFromCaseController.cls
* @Author : Maxify Development Team
* @Created Date : April 10, 2025
**/
@isTest
public class LeadFromCaseControllerTest {
    
    @testSetup
    static void setupTestData() {
        Case testCase = new Case(
            Subject = 'Test Case',
            SuppliedEmail = 'test@example.com',
            SuppliedName = 'John Doe',
            SuppliedPhone = '1234567890',
            Status = 'New'
        );
        insert testCase;
        
        Lead testLead = new Lead(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'test@example.com',
            Phone = '1234567890',
            Case__c = testCase.Id,
            Company = 'Test Company'
        );
        insert testLead;
    }
    
    @isTest
    static void testPopulateLeadFromCaseWithExistingLead() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        
        Test.setCurrentPageReference(new PageReference('/apex/DummyPage'));
        ApexPages.currentPage().getParameters().put('caseId', testCase.Id);
        
        LeadFromCaseController controller = new LeadFromCaseController();
        System.assertEquals(testCase.Id, controller.leadRecord.Case__c);
    }
    
    @isTest
    static void testPopulateLeadFromCaseWithNoExistingLead() {
        Case newCase = new Case(
            Subject = 'New Test Case',
            SuppliedEmail = 'new@example.com',
            SuppliedName = 'Alice Smith',
            SuppliedPhone = '9876543210',
            Status = 'New'
        );
        insert newCase;
        
        Test.setCurrentPageReference(new PageReference('/apex/DummyPage'));
        ApexPages.currentPage().getParameters().put('caseId', newCase.Id);
        
        LeadFromCaseController controller = new LeadFromCaseController();
        
        System.assertEquals(newCase.SuppliedEmail, controller.leadRecord.Email);
        System.assertEquals('Smith', controller.leadRecord.LastName);
    }
    
    @isTest
    static void testSaveLeadInsertAndCloseCase() {
        Case testCase = new Case(
            Subject = 'Closing Test',
            SuppliedEmail = 'close@example.com',
            SuppliedName = 'Closing Lead',
            SuppliedPhone = '9999999999',
            Status = 'New'
        );
        insert testCase;
        
        Test.setCurrentPageReference(new PageReference('/apex/DummyPage'));
        ApexPages.currentPage().getParameters().put('caseId', testCase.Id);
        
        LeadFromCaseController controller = new LeadFromCaseController();
        controller.leadRecord.Company = 'Test Company'; 
        controller.saveLead();
        
        System.assertNotEquals(null, controller.leadRecord.Id);
        
        Case updatedCase = [SELECT Status FROM Case WHERE Id = :testCase.Id];
        System.assertEquals('Closed', updatedCase.Status);
    }
    
    @isTest
    static void testSaveLeadUpdateExistingLead() {
        Lead existingLead = [SELECT Id FROM Lead LIMIT 1];
        
        Test.setCurrentPageReference(new PageReference('/apex/DummyPage'));
        ApexPages.currentPage().getParameters().put('leadId', existingLead.Id);
        
        LeadFromCaseController controller = new LeadFromCaseController();
        controller.leadRecord.Phone = '0001112222';
        controller.saveLead();
        
        Lead updatedLead = [SELECT Phone FROM Lead WHERE Id = :existingLead.Id];
        System.assertEquals('0001112222', updatedLead.Phone);
    }
    
    @isTest
    static void testGetLeadsForCase() {
        Lead existingLead = [SELECT Case__c FROM Lead LIMIT 1];
        test.startTest();
        List<Lead> leads = LeadFromCaseController.getLeadsForCase(existingLead.Case__c);
        List<Lead> leads2 = LeadFromCaseController.getLeadsForCase(null);
        test.stoptest();
        System.assert(!leads.isEmpty(), 'Leads list should not be empty for valid Case ID.');
        
    }
    
    @isTest
    static void testSendEmailToLead() {
        Lead lead = [SELECT Id FROM Lead WHERE Email != null LIMIT 1];
        Boolean exceptionThrown = false;
        Test.startTest();
        try{
            LeadFromCaseController.sendEmailToLead(lead.Id);
            LeadFromCaseController.sendEmailToLead(null);
        }catch (AuraHandledException ex) {
            exceptionThrown = true;
            System.debug('Exception Message: ' + ex.getMessage());
        }
        System.assertEquals(true, exceptionThrown, 'Expected AuraHandledException to be thrown.');
        Test.stopTest();
        
    } 
    
    @isTest
    static void testSaveLead_CatchBlock() {
        Test.startTest();
        LeadFromCaseController controller = new LeadFromCaseController();
        controller.leadRecord.LastName = 'TestUser';
        controller.leadRecord.Company = null; 
        
        controller.saveLead();
        Test.stopTest();
        
        System.assertEquals(true, controller.isErrorMessage, 'Error message flag should be true.');
        System.assert(controller.message.startsWith('Error:'), 'Expected an error message.');
    }
    
    
}