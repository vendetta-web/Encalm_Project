/**
* @File Name : TrackRepliesAndReassignTest.cls
* @Description : Test Class for TrackRepliesAndReassign.cls
* @Author : Maxify Development Team
* @Created Date : April 17, 2025
**/

@isTest
public class ShoppingEmailTemplateRendererTest {

    @testSetup
    static void setupData() {
        // creating test data
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'User',
            Company = 'Test Company',
            Email = 'testuser@example.com',
            Status = 'Open - Not Contacted'
        );
        insert testLead;
        
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User adminUser = new User(
            FirstName = 'Test',
            LastName = 'Admin',
            Email = 'adminuser@example.com',
            Username = 'adminuser' + DateTime.now().getTime() + '@example.com',
            Alias = 'admint',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert adminUser;

        System.runAs(adminUser) {
            EmailTemplate template = new EmailTemplate(
                Name = 'Test Lead Template',
                DeveloperName = 'Test_Lead_Template',
                TemplateType = 'text',
                Subject = 'Hello {!Lead.FirstName}',
                Body = 'Hi {!Lead.FirstName}, Welcome to our service!',
                FolderId = UserInfo.getUserId() 
            );
            insert template;
        }
    }

    @isTest
    static void testRenderTemplate() {
        
        Lead lead = [SELECT Id FROM Lead LIMIT 1];
        EmailTemplate template = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Test_Lead_Template' LIMIT 1];

        ShoppingEmailTemplateRenderer.TemplateInput input = new ShoppingEmailTemplateRenderer.TemplateInput();
        input.leadId = lead.Id;
        input.templateId = template.Id;

        List<ShoppingEmailTemplateRenderer.TemplateInput> inputs = new List<ShoppingEmailTemplateRenderer.TemplateInput>{ input };

        Test.startTest();
        List<ShoppingEmailTemplateRenderer.TemplateResult> results = ShoppingEmailTemplateRenderer.renderTemplate(inputs);
        Test.stopTest();

        System.assertNotEquals(null, results, 'Result list should not be null');
        System.assertEquals(1, results.size(), 'One result expected');
    }
}