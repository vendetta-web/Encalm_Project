/**
* @File Name : LeadCreationHandlerTest.cls
* @Description : Test Class for LeadCreationHandler.cls
* @Author : Maxify Development Team
* @Created Date : April 10, 2025
**/
@isTest
private class LeadCreationHandlerTest {
    
    @testSetup
    static void setupData() {
        
        // Creating Test Data
        Case testCase = new Case(Subject = 'Test Case');
        insert testCase;
        
        List<Lead> leadList = new List<Lead>();
        Lead lead1 = new Lead(LastName = 'Test Lead 1', Company = 'TestCo',Email = 'testEmail@gmail.com', Case__c = testCase.Id);
        leadList.add(lead1);
        Lead lead2 = new Lead(LastName = 'Test Lead 2', Company = 'TestCo',Email = 'testEmail2@gmail.com', Case__c = testCase.Id);
        leadList.add(lead2);
        insert leadList;
    }
    
    @isTest
    static void test_getLeadsForCase_validCaseId() {
        Case testCase = [Select Id from Case Where Subject = 'Test Case' Limit 1];
        List<Lead> leadList = [Select Id, Name, Email,Company,Case__c From Lead Where Case__c =: testCase.Id];
        Test.startTest();
        List<Lead> leads = LeadCreationHandler.getLeadsForCase(testCase.Id);
        try {
            LeadCreationHandler.getLeadsForCase(null);
            System.assert(false, 'Method should throw exception for null Case Id.');
            
            delete leadList;
            LeadCreationHandler.getLeadsForCase(testCase.Id);
        } catch (IllegalArgumentException e) {
            System.assertEquals('Case ID cannot be null or empty.', e.getMessage());
        }
        Test.stopTest();
        
        System.assertEquals(2, leads.size(), '2 leads expexted');
    }    
}