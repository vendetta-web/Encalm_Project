/**
* @File Name : TimestampChangeControllerTest.cls
* @Description : Test Class for TimestampChangeController.cls
* @Author : Maxify Development Team
* @Created Date : April 10, 2025
**/
@isTest
public class TimestampChangeControllerTest {
    
    
    @testSetup
    static void setupData() {   
        // creating test data
        Case testCase = new Case(
            Subject = 'Test Escalation Case',
            Status = 'New'
        );
        insert testCase;
        
        Timestamp__c timeStampRecord = new Timestamp__c(
            Status__c = 'New',
            Change_Timestamp__c = System.today(),
            Case__c = testCase.Id
        );
        insert timeStampRecord;
        
        Timestamp__c timeStampRecord2 = new Timestamp__c(
            Status__c = 'Active',
            Change_Timestamp__c = System.today(),
            Case__c = testCase.Id
        );
        insert timeStampRecord2;        
    }
    @isTest
    static void getStatusChangesTest(){
        Case testCase = [Select id, Subject From Case where Subject = 'Test Escalation Case' Limit 1];
        Test.StartTest();
        List<Timestamp__c> results = TimestampChangeController.getStatusChanges(testCase.Id);
        Test.StopTest();
        
        System.assertEquals(2, results.size(), 'Expected count of Timestamp__c');
        
    }
}