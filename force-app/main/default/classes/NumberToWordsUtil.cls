/**
* @File Name : NumberToWordsUtil.cls
* @Description :
* @Author : Siri Sowmya
* @Last Modified By :
* @Last Modified On : March 20, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | March 20, 2025 | Siri Sowmya  | Initial Version
**/

public class NumberToWordsUtil {
    
    private static final String[] belowTwenty = 
        new String[]{'Zero', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine', 'Ten', 'Eleven', 'Twelve', 
                     'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'};
                     
    private static final String[] tens = 
        new String[]{'', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'};
    
    private static final String[] thousands = 
        new String[]{'', 'Thousand', 'Million', 'Billion'};

    // Main function to convert a number (including paise) to words
    public static String convertNumberToWords(Decimal num) {
        if (num == null) return 'Zero';

        Long rupees = num.longValue();  
        Long paise = Math.round((num - rupees) * 100); // Handling decimal part (paise) 

        String words = convertRupeesToWords(rupees) + ' Rupees';

        if (paise > 0) {
            words += ' and ' + convertRupeesToWords(paise) + ' Paise';
        }

        return words.trim();
    }

    private static String convertRupeesToWords(Long num) {
        if (num == 0) return 'Zero';

        String words = '';
        Integer i = 0;

        while (num > 0) {
            Integer remainder = (Integer) Math.mod(num, 1000);
            if (remainder != 0) {
                words = convertThreeDigits(remainder) + ' ' + thousands[i] + ' ' + words;
            }
            num = (Long)(Math.floor(num / 1000)); 
            i++;
        }

        return words.trim();
    }

    private static String convertThreeDigits(Long num) {
        String result = '';
        
        if (num >= 100) {
            result += belowTwenty[(Integer)(num / 100)] + ' Hundred ';
            num = Math.mod(num, 100);
        }
        
        if (num >= 20) {
            result += tens[(Integer)(num / 10)] + ' ';
            num = Math.mod(num, 10);
        }
        
        if (num > 0) {
            result += belowTwenty[(Integer)num] + ' ';
        }

        return result.trim();
    }
}