@isTest
public class AccountRelatedRecordsControllerTest {
    
    @isTest
    static void testGetRelatedRecordsCount() {
        // Create test Account record
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Create related records (Case, Opportunity, and Lead)
        
        // Creating test Cases
        Case case1 = new Case(AccountId = testAccount.Id, Subject = 'Test Case 1');
        Case case2 = new Case(AccountId = testAccount.Id, Subject = 'Test Case 2');
        insert new List<Case>{ case1, case2 };
        
        // Creating test Opportunities
        Opportunity opp1 = new Opportunity(AccountId = testAccount.Id, Name = 'Test Opportunity 1', StageName = 'Prospecting', CloseDate = Date.today());
        Opportunity opp2 = new Opportunity(AccountId = testAccount.Id, Name = 'Test Opportunity 2', StageName = 'Prospecting', CloseDate = Date.today());
        insert new List<Opportunity>{ opp1, opp2 };
        
        // Creating test Leads
        Lead lead1 = new Lead(Account__c = testAccount.Id, LastName = 'Test Lead 1', Status = 'Open');
        Lead lead2 = new Lead(Account__c = testAccount.Id, LastName = 'Test Lead 2', Status = 'Open');
        insert new List<Lead>{ lead1, lead2 };

        // Call the method to test
        Test.startTest();
        Map<String, Integer> result = AccountRelatedRecordsController.getRelatedRecordsCount(testAccount.Id);
        Test.stopTest();
        
        // Assert that the result is as expected
        System.assertEquals(2, result.get('TotalCases'), 'TotalCases count should be 2');
        System.assertEquals(2, result.get('TotalOpportunities'), 'TotalOpportunities count should be 2');
        System.assertEquals(2, result.get('TotalLeads'), 'TotalLeads count should be 2');
    }
}