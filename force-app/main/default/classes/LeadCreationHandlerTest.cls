/**
* @File Name : LeadCreationHandlerTest.cls
* @Description : Test Class for LeadCreationHandler.cls
* @Author : Abhishek
* @Last Modified By : Abhishek
* @Last Modified On : April 10, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | April 10, 2025 |  Abhishek | Initial Version
**/
@isTest
private class LeadCreationHandlerTest {
    
    @isTest
    static void test_getLeadsForCase_validCaseId() {
        
        // Creating Test Data
        Case testCase = new Case(Subject = 'Test Case');
        insert testCase;
        
        List<Lead> leadList = new List<Lead>();
        Lead lead1 = new Lead(LastName = 'Test Lead 1', Company = 'TestCo',Email = 'testEmail@gmail.com', Case__c = testCase.Id);
        leadList.add(lead1);
        Lead lead2 = new Lead(LastName = 'Test Lead 2', Company = 'TestCo',Email = 'testEmail2@gmail.com', Case__c = testCase.Id);
        leadList.add(lead2);
        insert leadList;
        
        Test.startTest();
        List<Lead> leads = LeadCreationHandler.getLeadsForCase(testCase.Id);
        try {
            LeadCreationHandler.getLeadsForCase(null);
            System.assert(false, 'Method should throw exception for null Case Id.');
            delete testCase;
            LeadCreationHandler.getLeadsForCase(testCase.Id);
        } catch (IllegalArgumentException e) {
            System.assertEquals('Case ID cannot be null or empty.', e.getMessage());
        }
        Test.stopTest();
        
        System.assertEquals(2, leads.size(), '2 leads expexted');
    }
}