/**
* @File Name : TimestampChangeController .cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : March 26, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | March 26, 2025 |   | Initial Version
**/

public class TimestampChangeController  {
	@AuraEnabled(cacheable=true)
    public static List<Timestamp__c> getStatusChanges(Id caseId) {
        return [
            SELECT Id, Status__c, Change_Timestamp__c
            FROM Timestamp__c
            WHERE Case__c = :caseId
            ORDER BY Change_Timestamp__c DESC
        ];
    }
}