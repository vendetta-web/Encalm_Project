/**
* @File Name : CaseAssignmentQuickActionController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : April 15, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | April 15, 2025 | Siri Sowmya  | Initial Version
**/


public with sharing class CaseAssignmentQuickActionController {
    @AuraEnabled
    public static String assignCaseToOperationSPOC(Id caseId) {
        try {
			Group grp = [SELECT Id, Type, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Operations_SPOC' LIMIT 1];
            Case caseRecord = [SELECT Id, OwnerId FROM Case WHERE Id = :caseId LIMIT 1];
            caseRecord.OwnerId = grp.Id;
            update caseRecord;
            return 'Owner updated successfully';
        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }
}