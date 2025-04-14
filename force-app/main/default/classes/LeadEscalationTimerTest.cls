@isTest
public class LeadEscalationTimerTest {

    @isTest
    static void testLeadEscalationLevel1() {
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
        system.runAs(associate){
        Lead testLead = new Lead(LastName = 'Test Lead', Company = 'Test Company', Email = 'testEmail@gmail.com', OwnerId = associate.Id);
        insert testLead;

        Test.startTest();
        LeadEscalationTimer timer = new LeadEscalationTimer(testLead.Id, 1);
        String cronExp = '0 0 0 1 1 ? 2099'; 
        System.schedule('Test Lead Escalation Job', cronExp, timer);
        Test.stopTest();

        Lead updatedLead = [SELECT Status, Escalation_Level__c FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals('Escalated', updatedLead.Status);
        System.assertEquals('Level 2', updatedLead.Escalation_Level__c);
        }
    }
}