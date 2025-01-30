public with sharing class LeadConversionController {
    @AuraEnabled
    public static String processBooking(String recId,  String accId, Map<String, Object> opportunityFieldValues) {
        if (String.isBlank(recId)) {
            throw new AuraHandledException('Lead ID cannot be null or empty.');
        }
        if (String.isBlank(accId)) {
            throw new AuraHandledException('Please link an account');
        }

        try {
            Id recordId = recId;
            String opportunityId;
            String objectName = Schema.getGlobalDescribe().get(recordId.getSObjectType().getDescribe().getName()).getDescribe().getName();
            system.debug('objectName->> '+objectName);
            if (objectName == 'Lead') {
                Database.LeadConvert leadConvert = new Database.LeadConvert();
                leadConvert.setLeadId(recId);
                leadConvert.setAccountId(accId);
                leadConvert.setDoNotCreateOpportunity(false);
                leadConvert.setConvertedStatus(getConvertedStatus());
                
                Database.LeadConvertResult result = Database.convertLead(leadConvert);
    
                if (result.isSuccess()) {
                     opportunityId = result.getOpportunityId();
                    
                    // Update the Opportunity with custom field values
                    if (opportunityFieldValues != null && !opportunityFieldValues.isEmpty()) {
                        Opportunity opp = new Opportunity(Id = opportunityId);
                        for (String fieldName : opportunityFieldValues.keySet()) {
                            opp.put(fieldName, opportunityFieldValues.get(fieldName));
                            system.debug('opp->> '+opp);
                        }
                        update opp; // Save the updates
                    }
                } else {
                    throw new AuraHandledException('Lead conversion failed.');
                }
            } else if (objectName == 'Case') {
				// Create the Opportunity with custom field values
                    if (opportunityFieldValues != null && !opportunityFieldValues.isEmpty()) {
                        Opportunity opp = new Opportunity();
                        for (String fieldName : opportunityFieldValues.keySet()) {
                            opp.put(fieldName, opportunityFieldValues.get(fieldName));
                        }
                        opp.AccountId = accId;
                        opp.Name = 'Booking Number' + System.Now();
                        opp.StageName = 'Value Proposition';
                        opp.CloseDate = System.today().addDays(30);
                        insert opp; // create opportunity record
                        opportunityId = opp.Id;
                    }                
            }
               return opportunityId;
        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }

    private static String getConvertedStatus() {
        List<LeadStatus> statuses = [SELECT MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];
        if (statuses.isEmpty()) {
            throw new AuraHandledException('No converted status found for leads.');
        }
        return statuses[0].MasterLabel;
    }
}