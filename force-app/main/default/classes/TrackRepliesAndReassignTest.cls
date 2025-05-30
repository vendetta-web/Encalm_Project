/**
* @File Name : TrackRepliesAndReassignTest.cls
* @Description : Test Class for TrackRepliesAndReassign.cls
* @Author : Maxify Development Team
* @Created Date : April 10, 2025
**/
@isTest
public class TrackRepliesAndReassignTest {
    
    @testSetup
    static void setupData() {
        
        Lead testLead = new Lead();
        testLead.FirstName = 'Test';
        testLead.LastName = 'Lead';
        testLead.Email = 'testEmail@gmail.com';
        testLead.Company = 'Test Company';
        testLead.Status = 'Awaiting Customer response';
        testLead.Set_Follow_up_Date_and_Time__c = System.now().addMinutes(10);
        
        insert testLead;
        
        Task tskRecord = new Task();
        tskRecord.WhoId = testLead.Id;
        tskRecord.Subject = 'Re: Send Letter';
        tskRecord.Status = 'Open';
        tskRecord.Type = 'Call';
        tskRecord.Priority = 'Normal';
        tskRecord.TaskSubtype = 'Email';
        
        insert tskRecord;
    }
    @isTest
    static void testTrackRepliesAndReassign(){
        Lead testLead = [Select id From Lead where Name = 'Test Lead' LIMIT 1];
        TrackRepliesAndReassign job = new TrackRepliesAndReassign(testLead);
        
        Test.startTest();
        String jobId = System.schedule('Test Reply Exists', '0 0 0 1 1 ? 2050', job); 
        
        Task tskRecord = [Select id,Subject FROM Task where Subject = 'Re: Send Letter'];
        tskRecord.Subject = 'Send Letter';
        update tskRecord;
        
        TrackRepliesAndReassign job2 = new TrackRepliesAndReassign(testLead);
        try {
            String jobId2 = System.schedule('Test Reply Exists', '0 0 0 1 1 ? 2050', job2);
        } catch (Exception ex) {
            System.debug('Exception occurred while scheduling job: ' + ex.getMessage());
        }
        Test.stopTest();
        
        Lead updatedLead = [SELECT Status FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals('Open', updatedLead.Status, 'Status should remain unchanged if reply is found');      
        
    }
    @isTest
    static void testTrackRepliesAndReassign2(){
        
        Lead testLead = [Select id From Lead where Name = 'Test Lead' LIMIT 1]; 
        testLead.Set_Follow_up_Date_and_Time__c = null;
        
        update testLead;
        
        TrackRepliesAndReassign job = new TrackRepliesAndReassign(testLead);
        
        Test.startTest();
        String jobId = System.schedule('Test Reply Exists', '0 0 0 1 1 ? 2050', job); 
        Test.stopTest();
    }
}