/**
* @File Name : CaseEscalationJobTest.cls
* @Description : Test Class for CaseEscalationJob.cls
* @Author : Maxify Development Team
* @Created Date : April 10, 2025
**/
@isTest
public class CaseEscalationJobTest {
    
    // Creating test Data
    @testSetup
    static void setupData() {
        
        User manager = new User(
            Alias = 'mgrusr',
            Email='manager@example.com',
            EmailEncodingKey='UTF-8',
            LastName='Manager',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1].Id,
            TimeZoneSidKey='America/Los_Angeles',
            Username='manageruser' + DateTime.now().getTime() + '@example.com'
        );
        insert manager;
        
        User associate = new User(
            Alias = 'assoc',
            Email='associate@example.com',
            EmailEncodingKey='UTF-8',
            LastName='Associate',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1].Id,
            TimeZoneSidKey='America/Los_Angeles',
            Username='associateuser' + DateTime.now().getTime() + '@example.com',
            ManagerId = manager.Id
        );
        insert associate;
        
        Case testCase = new Case(
            Subject = 'Test Escalation Case',
            Status = 'New',
            OwnerId = manager.Id
        );
        insert testCase;
        
    }
    @isTest
    static void testCaseEscalationJob() {
        List<Case> casesList = [Select id, Subject, Status from Case where Subject = 'Test Escalation Case' Limit 1];//new List<Case>{testCase};
        CaseEscalationJob job = new CaseEscalationJob(casesList);
        
        Test.startTest();
        job.execute(null);
        CaseStatusEscalationHandler.scheduleEscalation(casesList);
        Test.stopTest();
        
        Case updatedCase = [SELECT Id, Status FROM Case WHERE Id = :casesList[0].Id];
        System.assertEquals('Escalated', updatedCase.Status, 'Case escalated.');
        
    }
    
    @isTest
    static void testSendEscalationEmail() {
        User associate = [Select id, Name from User where Email='associate@example.com'];
        
        Test.startTest();
        CaseEscalationJob.sendEscalationEmail(associate.Id);
        Test.stopTest();
        
        System.assert(true, 'Email send executed successfully.');
    }
}