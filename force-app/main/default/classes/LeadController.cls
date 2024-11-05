/**
* @File Name : LeadController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : October 22, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 22, 2024 |   | Initial Version
**/

public with sharing class LeadController {
    @AuraEnabled
    public static void updateLead(Id leadId, Map<String, String> leadData) {
        Lead leadToUpdate = [SELECT Id, FirstName, LastName, Email FROM Lead WHERE Id = :leadId LIMIT 1];

        leadToUpdate.FirstName = leadData.get('FirstName');
        leadToUpdate.LastName = leadData.get('LastName');
        leadToUpdate.Email = leadData.get('Email');
        
        update leadToUpdate; 
    }
    
     @AuraEnabled
    public static Id createLeadAndAssociateWithCase(String caseId, String firstName, String lastName, String email, String phone, String status, String description) {
        Lead newLead = new Lead();
        newLead.FirstName = firstName;
        newLead.LastName = lastName;
        newLead.Email = email;
        newLead.Phone = phone;
        newLead.Status = status;
        newLead.Description = description;
        newLead.Case__c = caseId; 

        insert newLead;

        return newLead.Id; 
    }
}