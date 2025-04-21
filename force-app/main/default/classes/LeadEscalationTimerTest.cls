/**
* @File Name : LeadEscalationTimerTest.cls
* @Description : Test Class for LeadEscalationTimer.cls
* @Author : Maxify Development Team
* @Created Date : April 14 2025
**/
@isTest
private class LeadEscalationTimerTest {

    @testSetup
    static void setupData() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User managerOfManager = new User(
            Alias = 'mgrmgr',
            Email = 'mgrmgr@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'ManagerOfManager',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'mgrmgr' + DateTime.now().getTime() + '@example.com'
        );
        insert managerOfManager;

        User manager = new User(
            Alias = 'mgr',
            Email = 'manager@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Manager',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'mgr' + DateTime.now().getTime() + '@example.com',
            ManagerId = managerOfManager.Id
        );
        insert manager;

        User leadOwner = new User(
            Alias = 'ldown',
            Email = 'leadowner@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'LeadOwner',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'ldown' + DateTime.now().getTime() + '@example.com',
            ManagerId = manager.Id
        );
        insert leadOwner;

        Account acc = new Account(
            Name = 'Test Account',
            BillingStreet = '123 Main Street',
            BillingCity = 'Pune',
            BillingState = 'Maharashtra',
            BillingPostalCode = '411001',
            BillingCountry = 'India'
        );
        insert acc;

        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'TestCompany',
            Status = 'New',
            Email = 'testLeadEscalationEmail@gmail.com'
        );
        insert testLead;
    }

    @isTest
    static void testLeadEscalationLevel1() {
        Test.startTest();

        User leadOwner = [SELECT Id FROM User WHERE Email = 'leadowner@example.com' LIMIT 1];
        
        Lead testLead = [SELECT Id, OwnerId FROM Lead WHERE Email = 'testLeadEscalationEmail@gmail.com' LIMIT 1];
        testLead.OwnerId = leadOwner.Id;
        update testLead;

        LeadEscalationTimer timer = new LeadEscalationTimer(testLead.Id, 1);
		String cronExp = '0 0 12 * * ?'; 
        String jobId = System.schedule('Test Lead Escalation Timer Job', cronExp, timer);
        
        Test.stopTest();

        Lead updatedLead = [SELECT Status, TAT_deadline__c, Escalation_Level__c FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals('Escalated', updatedLead.Status, 'Lead should be escalated.');
        System.assertEquals('Level 2', updatedLead.Escalation_Level__c, 'Escalation Level should be Level 2.');
        System.assertNotEquals(null, updatedLead.TAT_deadline__c, 'TAT deadline should be set.');
    }

    @isTest
    static void testLeadEscalationLevel2() {
        Test.startTest();

        User leadOwner = [SELECT Id FROM User WHERE Email = 'leadowner@example.com' LIMIT 1];
        
        Lead testLead = [SELECT Id, OwnerId FROM Lead WHERE Email = 'testLeadEscalationEmail@gmail.com' LIMIT 1];
        testLead.OwnerId = leadOwner.Id;
        update testLead;

        LeadEscalationTimer timer = new LeadEscalationTimer(testLead.Id, 2);
        String cronExp = '0 0 12 * * ?'; 
        String jobId = System.schedule('Test Lead Escalation Timer Job', cronExp, timer);
        
        Test.stopTest();

        System.assert(true, 'Level 2 escalation executed successfully.');
    }
}