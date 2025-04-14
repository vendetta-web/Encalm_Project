/**
* @File Name : EscalateLeadBatchTest.cls
* @Description : Test Class for EscalateLeadBatch.cls
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
public class EscalateLeadBatchTest {
    
    @isTest
    static void setupData() {
        User managerUser = new User(
            Username = 'newManager@test.com',
            Alias = 'mgr',
            Email = 'newManager@test.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/New_York',
            LastName = 'Manager'
        );
        insert managerUser;
        
        User ownerUser = new User(
            Username = 'newOwner@test.com',
            Alias = 'ownr',
            Email = 'newOwner@test.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = managerUser.ProfileId,
            TimeZoneSidKey = 'America/New_York',
            LastName = 'Owner',
            ManagerId = managerUser.Id
        );
        insert ownerUser;
        
        Lead leadWithManager = new Lead(
            LastName = 'Lead Manager',
            Company = 'Test Co',
            Status = 'Open',
            Email = 'testEmail@gmail.com'
        );        
        insert leadWithManager;
        
        Test.setCreatedDate(leadWithManager.Id, System.now().addMinutes(-40));
        leadWithManager.OwnerId = ownerUser.Id;
        update leadWithManager;
        
        Test.startTest();
        Database.executeBatch(new EscalateLeadBatch(), 200);
        Test.stopTest();
        Lead leadEscalated = [SELECT Id, Status, OwnerId FROM Lead WHERE LastName = 'Lead Manager' LIMIT 1];
        System.assertEquals('Escalated', leadEscalated.Status, 'Lead with manager should be escalated');
    }
}