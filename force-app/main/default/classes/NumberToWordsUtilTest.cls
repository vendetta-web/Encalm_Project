/**
* @File Name : TrackRepliesAndReassignTest.cls
* @Description : Test Class for TrackRepliesAndReassign.cls
* @Author : Maxify Development Team
* @Created Date : April 17, 2025
**/

@isTest
public class NumberToWordsUtilTest {

    @isTest
    static void testConvertNumberToWords() {
        Test.startTest();

        // Case 1: Null input
        String result1 = NumberToWordsUtil.convertNumberToWords(null);
        System.assertEquals('Zero', result1, 'Null input should return "Zero"');

        // Case 2: Whole number (No Paise)
        String result2 = NumberToWordsUtil.convertNumberToWords(Decimal.valueOf(1234));
        System.debug('Output for 1234: ' + result2);
        System.assert(result2.contains('Rupees'), 'Output should contain "Rupees"');
        System.assert(!result2.contains('Paise'), 'There should be no "Paise" for whole numbers');

        // Case 3: Number with paise
        String result3 = NumberToWordsUtil.convertNumberToWords(1234.56);
        System.debug('Output for 1234.56: ' + result3);
        System.assert(result3.contains('and'), 'Output should include "and" for paise');
        System.assert(result3.contains('Paise'), 'Output should include "Paise" for decimal part');

        // Case 4: Zero value
        String result4 = NumberToWordsUtil.convertNumberToWords(0);
        System.assertEquals('Zero Rupees', result4, 'Zero input should return "Zero Rupees"');

        // Case 5: Small decimal value (Only Paise)
        String result5 = NumberToWordsUtil.convertNumberToWords(0.75);
        System.debug('Output for 0.75: ' + result5);
        System.assertEquals('Zero Rupees and Seventy Five Paise', result5, 'Only paise should return correct format');

        // Case 6: Large number
        String result6 = NumberToWordsUtil.convertNumberToWords(1000000.99);
        System.debug('Output for 1000000.99: ' + result6);
        System.assert(result6.contains('Million'), 'Output should contain "Million" for large numbers');
        System.assert(result6.contains('Paise'), 'Output should include "Paise" for decimals');

        Test.stopTest();
    }
}