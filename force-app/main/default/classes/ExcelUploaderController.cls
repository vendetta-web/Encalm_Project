/**
* @File Name : ExcelUploaderController .cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : October 15, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 15, 2024 |   | Initial Version
**/

public class ExcelUploaderController  {
	  @AuraEnabled
    public static void processAccountData(List<Account> accountList) {
        try {
            // Perform an upsert operation to either create or update Account records
            upsert accountList;
        } catch (Exception e) {
            throw new AuraHandledException('Error processing accounts: ' + e.getMessage());
        }
    }
}