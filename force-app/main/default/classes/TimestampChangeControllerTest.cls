/**
* @File Name : TimestampChangeControllerTest.cls
* @Description : Test Class for TimestampChangeController.cls
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
public class TimestampChangeControllerTest {
	
    @isTest
    public static void getStatusChangesTest(){
        
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
         
        Test.StartTest();
        	List<Timestamp__c> results = TimestampChangeController.getStatusChanges(testCase.Id);
        Test.StopTest();
        
        System.assertEquals(2, results.size(), 'Expected count of Timestamp__c');
        
    }
}