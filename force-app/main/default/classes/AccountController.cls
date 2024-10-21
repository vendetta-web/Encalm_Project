/**
* @File Name : AccountController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : October 17, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 17, 2024 |   | Initial Version
**/

public with sharing class AccountController {
    @AuraEnabled(cacheable=true)
    public static List<Account> searchAccounts(String searchKey) {
        String searchPattern = '%' + searchKey + '%';
        
        return [
            SELECT Id, Name, PersonEmail, Phone
            FROM Account
            WHERE Name LIKE :searchPattern OR PersonEmail LIKE :searchPattern OR Phone LIKE :searchPattern
        ];
    }
}