public class LeadFormController {
    public Lead lead { get; set; }
    public Id caseId { get; set; } 
    public Id leadId { get; set; } 

    public LeadFormController(ApexPages.StandardController stdController) {
        this.lead = (Lead)stdController.getRecord();
        System.debug('lead: ' + lead);
        
        this.caseId = ApexPages.currentPage().getParameters().get('caseId');
        system.debug('caseId ==>'+caseId);
        this.leadId = ApexPages.currentPage().getParameters().get('leadId');
        system.debug('leadId ==> '+leadId);
    }

    public PageReference submitForm() {

        Lead newLead = new lead (); 
        try {
            if (caseId != null) {
                // If caseId is passed, update the case and lead
                System.debug('lead: ' + lead);
                insert lead; // Insert the lead
                List<Case> cases = [SELECT Id, Status FROM Case WHERE Id = :caseId LIMIT 1];
                
                if (cases != null && !cases.isEmpty()) {
                    Case c = cases[0];
                    c.Status = 'Closed';
                    update c; 
                    
                } else {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error: No case found with the provided Id'));
                    return null;
                }
            } else if (leadId != null) {
                // If leadId is passed, update the existing lead
                List<Lead> leads = [SELECT Id, FirstName, LastName, Email, Phone, Company, Travel_Date__c, Number_of_Adult__c, Status FROM Lead WHERE Id = :leadId LIMIT 1];
                
                if (lead != null && !leads.isEmpty()) {
                    Lead ld = leads[0];
                    // Update the lead fields if the new values are not blank
                    ld.FirstName = String.isBlank(lead.FirstName) ? ld.FirstName : lead.FirstName;
                    ld.LastName = String.isBlank(lead.LastName) ? ld.LastName : lead.LastName;
                    ld.Email = String.isBlank(lead.Email) ? ld.Email : lead.Email;
                    ld.Phone = String.isBlank(lead.Phone) ? ld.Phone : lead.Phone;
                    ld.Company = String.isBlank(lead.Company) ? ld.Company : lead.Company;
                    ld.Travel_Date__c = ld.Travel_Date__c != null ? ld.Travel_Date__c : lead.Travel_Date__c;
                    ld.Number_of_Adult__c = ld.Number_of_Adult__c != null ? ld.Number_of_Adult__c : lead.Number_of_Adult__c;
                    update ld; 
                } else {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error: No lead found with the provided Id'));
                    return null;
                }
            } else {
                // If no leadId, create a new lead
                newLead = new Lead(
                    FirstName = lead.FirstName,
                    LastName = lead.LastName,
                    Email = lead.Email,
                    Phone = lead.Phone,
                    Company = lead.Company,
                    Travel_Date__c = lead.Travel_Date__c,
                    Number_of_Adult__c = lead.Number_of_Adult__c
                );
                insert newLead; 
                System.debug('newLead Id: ' + newLead.Id); 
            }

            String leadRecordUrl = '/lightning/r/Lead/' + (leadId != null ? leadId : newLead.Id) + '/view';
            
            return new PageReference(leadRecordUrl);
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error: ' + e.getMessage()));
            return null;
        }
    }
}