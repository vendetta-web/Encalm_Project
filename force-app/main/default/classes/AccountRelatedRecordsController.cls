public with sharing class AccountRelatedRecordsController {
    @AuraEnabled(cacheable=true)
    public static Map<String, Integer> getRelatedRecordsCount(Id accountId) {
        Map<String, Integer> relatedRecordsCount = new Map<String, Integer>();
        
        Integer totalCases = [SELECT COUNT() FROM Case WHERE AccountId = :accountId];
        Integer totalOpportunities = [SELECT COUNT() FROM Opportunity WHERE AccountId = :accountId];
        
        // Assuming there is a custom relationship field between Lead and Account
        Integer totalLeads = [SELECT COUNT() FROM Lead WHERE Account__c = :accountId];

        relatedRecordsCount.put('TotalCases', totalCases);
        relatedRecordsCount.put('TotalLeads', totalLeads);
        relatedRecordsCount.put('TotalOpportunities', totalOpportunities);

        return relatedRecordsCount;
    }
}