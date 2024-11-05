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
    @AuraEnabled(cacheable=true)
    public static Map<String, Id> getRecordTypeIds() {
        Map<String, Id> recordTypeIds = new Map<String, Id>();
        List<RecordType> recordTypes = [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Account' AND Name IN ('Person Account', 'Business Account')];

        for (RecordType rt : recordTypes) {
            if (rt.Name == 'Business Account') {
                recordTypeIds.put('Business', rt.Id);
            } else if (rt.Name == 'Person Account') {
                recordTypeIds.put('Personal', rt.Id);
            }
        }

        return recordTypeIds;
    }
    @AuraEnabled(cacheable=true)
public static List<Account> getAccounts(String searchTerm) {
    String query = '%' + searchTerm + '%';
    return [
        SELECT Id, Name, Phone, PersonEmail 
        FROM Account 
        WHERE Name LIKE :query
        ORDER BY Name ASC
        LIMIT 10
    ];
}
}