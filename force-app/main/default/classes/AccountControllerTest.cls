/**
* @File Name : AccountControllerTest.cls
* @Description : Test Class for AccountController.cls
* @Author : Abhishek
* @Last Modified By : Abhishek
* @Last Modified On : April 08, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | April 08, 2025 |  Abhishek | Initial Version
**/


@isTest
public class AccountControllerTest {
    
    @testSetup
    static void setupTestData() {
        String accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId();
        
        List<Account> accountsToInsert = new List<Account>();
        for (Integer i = 1; i <= 20; i++) {
            accountsToInsert.add(new Account(
                Name = 'Test Business Account ' + i,
                Phone = '123456789' + i,
                RecordTypeId = accRecordTypeId,
                BillingStreet = '123 Main Street',
                BillingCity = 'Pune',
                BillingState = 'Maharashtra',
                BillingPostalCode = '411001',
                BillingCountry = 'India'
            ));
        }
        insert accountsToInsert;
    }
    
    @isTest
    static void testSearchAccounts() {
        Test.startTest();
        List<Account> result = AccountController.searchAccounts('Test Business Account 1');
        Test.stopTest();
        
        System.assert(result.size() > 0, 'Expected to find matching Account records');
        System.assert(result.size() <= 20, 'Should return up to 20 matching records as per test data');
    }
    
    @isTest
    static void testGetRecordTypeIds() {
        Test.startTest();
        Map<String, Id> result = AccountController.getRecordTypeIds();
        Test.stopTest();
        
        System.assert(result.containsKey('Business'), 'Business record type should be present');
        System.assertNotEquals(null, result.get('Business'), 'Business record type ID should not be null');
    }
    
    @isTest
    static void testGetAccounts() {
        Test.startTest();
        List<Account> result = AccountController.getAccounts('Test Business Account 1');
        Test.stopTest();
        
        System.assert(result.size() > 0, 'Expected to retrieve some Account records');
        System.assert(result.size() <= 10, 'Should limit to 10 records as per the method logic');
    }
}