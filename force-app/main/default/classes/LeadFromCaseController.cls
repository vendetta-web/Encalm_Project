public with sharing class LeadFromCaseController {
    public String caseId { get; set; }
    public Lead leadRecord { get; set; }
    public Id leadId { get; set; }
    public Boolean showForm { get; set; }
    public String message { get; set; } 
    public Boolean isErrorMessage { get; set; }

    public LeadFromCaseController() {
        caseId = ApexPages.currentPage().getParameters().get('caseId');
        leadRecord = new Lead();
        showForm = true; 
        message = ''; 
        isErrorMessage = false;
        leadId = ApexPages.currentPage().getParameters().get('leadId') != null 
            ? ApexPages.currentPage().getParameters().get('leadId') 
            : null;
        populateLeadFromCase();
    }

    public void populateLeadFromCase() {
        try {
            if (caseId != null) {
                System.debug('Case ID: ' + caseId);

                List<Lead> leads = getLeadsForCase(caseId);
                
                if (!leads.isEmpty()) {
                    leadRecord = leads[0];
                    System.debug('Populated Lead Record from Case: ' + leadRecord);
                } else {
                    Case caseRecord = [
                        SELECT Id, Subject, SuppliedEmail, SuppliedName, SuppliedPhone, Status
                        FROM Case 
                        WHERE Id = :caseId
                        LIMIT 1
                    ];
                    
                    if (caseRecord != null) {
                        leadRecord.Email = caseRecord.SuppliedEmail;
                        leadRecord.LastName = caseRecord.SuppliedName;
                        leadRecord.Phone = caseRecord.SuppliedPhone;
                        leadRecord.Case__c = caseRecord.Id;
                        
                        if (caseRecord.SuppliedName != null) {
                            String[] nameParts = caseRecord.SuppliedName.split(' ', 2);
                            if (nameParts.size() == 2) {
                                leadRecord.FirstName = nameParts[0];
                                leadRecord.LastName = nameParts[1];
                            } else {
                                leadRecord.LastName = caseRecord.SuppliedName;
                            }
                        }
                        System.debug('Mapped Lead Record: ' + leadRecord);
                    }
                }
            }

            if (leadId != null) {
                leadRecord = [
                    SELECT Id, FirstName, LastName, Email, Phone, Travel_Date__c, Number_of_Adult__c, Flight_No__c, 
                    Service_Airport__c, Journey_Type__c, Case__c, Service_Package__c,  Sector_of_Travel__c,Airline_PNR__c, 
                    Guest_Name__c, Travel_Class__c, Registered_Address__c, Additional_Request__c     
                    FROM Lead 
                    WHERE Id = :leadId 
                    LIMIT 1
                ];
                System.debug('Fetched Lead Record by Lead ID: ' + leadRecord);
            } else {
                System.debug('Lead ID is null');
            }
        } catch (Exception e) {
            System.debug('Error message: ' + e.getMessage() + ' at line number: ' + e.getLineNumber());
        }
    }

    public PageReference saveLead() {
        try {
            System.debug('Lead ID: ' + leadRecord.Id);
            System.debug('Lead Details: ' + leadRecord);

            if (leadRecord.Id != null) {
                update leadRecord;
                message = 'Details have been updated successfully.';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, message));
            } else {
                insert leadRecord;
                message = 'Details have been submitted successfully.';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, message));
                
                if (caseId != null) {
                    closeAssociatedCase(caseId);
                }
            }
            showForm = false;
        } catch (DmlException e) {
           if (e.getMessage().contains('DUPLICATES_DETECTED')) {

                message = 'Duplicate Detected: You\'re creating a duplicate record. We recommend you use an existing record instead.';
               isErrorMessage = true;

            } else {

                message = 'Error: ' + e.getMessage();
                isErrorMessage = true;

            }

            showForm = false;
            System.debug('Error: ' + e.getMessage());
        }
        return null;
    }

    // Fetch Leads associated with a Case
    @AuraEnabled(cacheable=true)
    public static List<Lead> getLeadsForCase(Id caseId) {
        if (String.isBlank(caseId)) {
            throw new IllegalArgumentException('Case ID cannot be null or empty.');
        }
        
         return [SELECT Id, Name, Case__c FROM Lead WHERE Case__c = :caseId];
    }

    // Close the associated case
    private void closeAssociatedCase(String caseId) {
        try {
            Case caseRecord = [
                SELECT Id, Status
                FROM Case 
                WHERE Id = :caseId
                LIMIT 1
            ];
            if (caseRecord != null) {
                caseRecord.Status = 'Closed';
                update caseRecord;
            }
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error closing Case: ' + e.getMessage()));
        }
    }
}