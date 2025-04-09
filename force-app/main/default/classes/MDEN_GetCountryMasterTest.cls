/**
* @File Name : MDEN_GetCountryMasterTest.cls
* @Description : Test Class for MDEN_GetCountryMaster.cls
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
public class MDEN_GetCountryMasterTest {
    
    @isTest
    static void test_getCountry_withData() {
        // Insert test Country__c data
        Country__c country1 = new Country__c( Country_Name__c = 'India', Phone_Code__c = '+91');
        Country__c country2 = new Country__c( Country_Name__c = 'United States', Phone_Code__c = '+1');
        insert new List<Country__c>{country1, country2};
            
            Test.startTest();
        MDEN_GetCountryMaster.MDEN_GetResponseWrapper response = MDEN_GetCountryMaster.getCountry();
        Test.stopTest();
        
        System.assertEquals('true', response.status, 'Expected status to be true');
        System.assertEquals('data found.', response.message, 'Expected data found message');
        System.assertEquals(2, response.datalist.size(), 'Expected 2 country records in datalist');
    }
    
    @isTest
    static void test_getCountry_noData() {
        
        Test.startTest();
        MDEN_GetCountryMaster.MDEN_GetResponseWrapper response = MDEN_GetCountryMaster.getCountry();
        Test.stopTest();
        
        System.assertEquals('false', response.status, 'Expected status to be false');
        System.assertEquals('data not found.', response.message, 'Expected message for no data');
        System.assertEquals(null, response.datalist, 'Expected null datalist');
    }
}