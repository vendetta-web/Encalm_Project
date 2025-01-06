@isTest
public class LeadStatusHelperTest {

    @testSetup
    static void setupData() {
        Group salesQueue = new Group(
            Name = 'Sales Team',
            Type = 'Queue'
        );
        insert salesQueue;
        
        QueueSObject queueSObject = new QueueSObject(
            QueueId = salesQueue.Id,
            SObjectType = 'Lead'
        );
        insert queueSObject;
    }

    @isTest
    static void testHandleBeforeUpdate() {
        
        Group salesQueue = [SELECT Id FROM Group WHERE Name = 'Sales Team' LIMIT 1];

        Lead lead1 = new Lead(
            FirstName = 'Test',
            LastName = 'Lead1',
            Email = 'abc@gmail.com',
            Phone = '235435',
            Status = 'New'
        );
        
        Lead lead2 = new Lead(
            FirstName = 'Test',
            LastName = 'Lead2',
            Email = 'abc@gmail.com',
            Phone = '235435',
            Status = 'New'
        );
        
        insert new List<Lead>{ lead1, lead2 };

        lead1.Status = 'Sent to Sales';
        update lead1;

        Lead updatedLead1 = [SELECT Id, Status, OwnerId FROM Lead WHERE Id = :lead1.Id];
        Lead updatedLead2 = [SELECT Id, Status, OwnerId FROM Lead WHERE Id = :lead2.Id];

        System.assertEquals(salesQueue.Id, updatedLead1.OwnerId, 'Lead1 OwnerId should be updated to Sales Team Queue.');

        System.assertNotEquals(salesQueue.Id, updatedLead2.OwnerId, 'Lead2 OwnerId should not be updated.');
    }
}