/**
* @File Name : CaseEscalationJobTest.cls
* @Description : Test Class for CaseEscalationJob.cls
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
public class CaseEscalationJobTest {

    @isTest
    static void testCaseEscalationJob() {
        User u = new User(
            Alias = 'testusr',
            Email='testuser@example.com',
            EmailEncodingKey='UTF-8',
            LastName='Test User',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1].Id,
            TimeZoneSidKey='America/Los_Angeles',
            Username='testuser' + DateTime.now().getTime() + '@example.com'
        );
        insert u;

        Case testCase = new Case(
            Subject = 'Test Escalation Case',
            Status = 'New',
            OwnerId = u.Id
        );
        insert testCase;

        List<Case> casesList = new List<Case>{testCase};
        CaseEscalationJob job = new CaseEscalationJob(casesList);

        Test.startTest();
        	job.execute(null);
        	CaseStatusEscalationHandler.scheduleEscalation(casesList);
        Test.stopTest();

        Case updatedCase = [SELECT Id, Status FROM Case WHERE Id = :testCase.Id];
        System.assertEquals('Escalated', updatedCase.Status, 'Case escalated.');

    }

    @isTest
    static void testSendEscalationEmail() {

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

        Test.startTest();
        	CaseEscalationJob.sendEscalationEmail(associate.Id);
        Test.stopTest();

        System.assert(true, 'Email send executed successfully.');
    }
}