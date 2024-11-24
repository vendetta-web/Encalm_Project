public with sharing class LeadConversionController {
    @AuraEnabled
    public static String convertLead(String leadId,  String accId, Map<String, Object> opportunityFieldValues) {
        if (String.isBlank(leadId)) {
            throw new AuraHandledException('Lead ID cannot be null or empty.');
        }
        if (String.isBlank(accId)) {
            throw new AuraHandledException('Please link an account');
        }

        try {
            Database.LeadConvert leadConvert = new Database.LeadConvert();
            leadConvert.setLeadId(leadId);
            leadConvert.setAccountId(accId);
            leadConvert.setDoNotCreateOpportunity(false);
            leadConvert.setConvertedStatus(getConvertedStatus());
            
            Database.LeadConvertResult result = Database.convertLead(leadConvert);

            if (result.isSuccess()) {
                String opportunityId = result.getOpportunityId();
                
                // Update the Opportunity with custom field values
                if (opportunityFieldValues != null && !opportunityFieldValues.isEmpty()) {
                    Opportunity opp = new Opportunity(Id = opportunityId);
                    for (String fieldName : opportunityFieldValues.keySet()) {
                        opp.put(fieldName, opportunityFieldValues.get(fieldName));
                    }
                    update opp; // Save the updates
                }
                return opportunityId;
            } else {
                throw new AuraHandledException('Lead conversion failed.');
            }
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