public with sharing class LeadCreationHandler {
    @AuraEnabled(cacheable=true)
    public static List<Lead> getLeadsForCase(Id caseId) {
        if (String.isBlank(caseId)) {
            throw new IllegalArgumentException('Case ID cannot be null or empty.');
        }

        try {
            return [
                SELECT Id, Name, Case__c 
                FROM Lead 
                WHERE Case__c = :caseId
            ];
        } catch (Exception e) {
            System.debug('Error fetching Leads for Case: ' + e.getMessage());
            throw new AuraHandledException('An error occurred while retrieving Leads. Please contact your administrator.');
        }
    }
}