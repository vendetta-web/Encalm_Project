public with sharing class LeadFromCaseController {
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

    // Fetch Leads associated with a Case
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

    // Populate Lead from Case
    public void populateLeadFromCase() {
        try {
            if (caseId != null) {
                List<Lead> leads = getLeadsForCase(caseId);

                if (!leads.isEmpty()) {
                    // Use the first Lead from the list
                    leadRecord = leads[0];
                } else {
                    // Fetch Case to map values if no Leads are found
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
                    }
                }
            }

            if (leadId != null) {
                leadRecord = [
                    SELECT Id, FirstName, LastName, Email, Phone, Travel_Date__c, Number_of_Adult__c, Flight_No__c, 
                           Service_Airport__c, Journey_Type__c, Case__c, Service_Package__c,  Sector_of_Travel__c,Airline_PNR__c, Guest_Name__c,Travel_Class__c, Registered_Address__c,Additional_Request__c     
                    FROM Lead 
                    WHERE Id = :leadId 
                    LIMIT 1
                ];
            }
        } catch (Exception e) {
            System.debug('Error message: ' + e.getMessage() + ' at line number: ' + e.getLineNumber());
        }
    }

    // Save the Lead record
    public PageReference saveLead() {
        try {
            if (leadRecord.Id != null) {
                update leadRecord;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Lead updated successfully.'));
            } else {
                insert leadRecord;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Lead created successfully.'));

                if (caseId != null) {
                    closeAssociatedCase(caseId);
                }
            }
            /*String leadRecordUrl = '/lightning/r/Lead/' + (leadId != null ? leadId : leadRecord.Id) + '/view';
            return new PageReference(leadRecordUrl);*/
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error: ' + e.getMessage()));
        }
        return null;
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