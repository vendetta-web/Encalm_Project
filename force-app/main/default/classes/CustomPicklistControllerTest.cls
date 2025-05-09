/**
* @File Name : CustomPicklistControllerTest.cls
* @Description : Test Class for CustomPicklistController.cls
* @Author : Maxify Development Team
* @Created Date : April 17, 2025
**/
@isTest
public class CustomPicklistControllerTest {

    @isTest
    static void testGetNationalityPicklistValues() {
        Test.startTest();

        // Call the method
        List<String> result = CustomPicklistController.getNationalityPicklistValues();

        Test.stopTest();

        // Assert the result is not null
        System.assertNotEquals(null, result, 'Result should not be null');

        // Log the values for confirmation
        System.debug('Nationality Picklist Values: ' + result);
    }
}