public class LeadFromCaseController {
    public String caseId { get; set; }
    public Lead leadRecord { get; set; }
     public Id leadId { get; set; }
    
    public LeadFromCaseController() {
        caseId = ApexPages.currentPage().getParameters().get('caseId');
        leadRecord = new Lead();
        leadId = ApexPages.currentPage().getParameters().get('leadId') != null 
                 ? ApexPages.currentPage().getParameters().get('leadId') 
                 : null;
        populateLeadFromCase();
    }
    
    // Fetch Case record and map values to Lead
    public void populateLeadFromCase() {
        try {
            if (caseId != null) {
                Case caseRecord = [
                    SELECT Id, Subject, SuppliedEmail, SuppliedName,SuppliedPhone
                    FROM Case 
                    WHERE Id = :caseId
                    LIMIT 1
                ];
                
                // Map values from Case to Lead
                if (caseRecord != null) {
                    leadRecord.Email = caseRecord.SuppliedEmail;
                    leadRecord.LastName = caseRecord.SuppliedName;
                    //leadRecord.Company = caseRecord.Subject;
                    leadRecord.phone = caseRecord.SuppliedPhone;
                }
            }
              if (leadId != null) {
                leadRecord = [SELECT Id, FirstName, LastName, Email,Travel_Date__c,Number_of_Adult__c FROM Lead WHERE Id = :leadId LIMIT 1];
            }
        } catch (Exception e) {
            system.debug('error message '+e.getMessage() +' line number '+e.getLineNumber());
        }
        
    }
    
    // Save the Lead record
    public PageReference saveLead() {
        try {
           if (leadRecord.Id != null) {
                // Update the existing Lead if ID is present
                update leadRecord;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Lead updated successfully.'));
            } else {
                // Insert a new Lead if no ID exists
                insert leadRecord;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Lead created successfully.'));
            }
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error: ' + e.getMessage()));
        }
        return null;
    }
}