/**
* @File Name : AccountHelper.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : December 3, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | December 3, 2024 |   | Initial Version
**/

public with sharing class AccountHelper {
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getRelatedCounts(Id accountId) {
        Map<String, Object> counts = new Map<String, Object>();
        
        counts.put('totalBookings', [
            SELECT COUNT() 
            FROM Opportunity 
            WHERE AccountId = :accountId
        ]);

        counts.put('totalBaggageReports', [
            SELECT COUNT() 
            FROM Case 
            WHERE AccountId = :accountId
        ]);

        counts.put('totalFeedbackReports', [
            SELECT COUNT() 
            FROM Lead 
            WHERE Account__c = :accountId
        ]);

        // Fetch Travel Class from a related Lead
        Lead lead = [SELECT Travel_Class__c	 FROM Lead WHERE Account__c = :accountId LIMIT 1];
        counts.put('travelClass', lead.Travel_Class__c);

        return counts;
    }
}