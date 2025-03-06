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
            String EncalmCode='EN';
            String airportCode='';
            String serviceTypeCode='';
            String combineCode= '';
            if (objectName == 'Lead') {
                Database.LeadConvert leadConvert = new Database.LeadConvert();
                leadConvert.setLeadId(recId);
                leadConvert.setAccountId(accId);
                leadConvert.setDoNotCreateOpportunity(false);
                leadConvert.setConvertedStatus(getConvertedStatus());
                
                Database.LeadConvertResult result = Database.convertLead(leadConvert);
    
                if (result.isSuccess()) {
                     opportunityId = result.getOpportunityId();
                     // Retrieve the Opportunity to ensure you can update the Name field
                    Opportunity opp = [SELECT Id, Name FROM Opportunity WHERE Id = :opportunityId LIMIT 1];

                    // Update the Opportunity with custom field values
                    if (opportunityFieldValues != null && !opportunityFieldValues.isEmpty()) {
                        for (String fieldName : opportunityFieldValues.keySet()) {
                            opp.put(fieldName, opportunityFieldValues.get(fieldName));
                            if (fieldName == 'Service_Airport__c') {
                                airportCode = String.valueOf(opportunityFieldValues.get(fieldName));
                            }
                            if (fieldName == 'Service_Type__c') {
                                serviceTypeCode = String.valueOf(opportunityFieldValues.get(fieldName));
                            }
                        }
                    }
                    combineCode = EncalmCode + airportCode + getServiceCode(serviceTypeCode) + generateNewBookingNumber();
                    opp.Name = combineCode;
                    update opp; // Save the updates
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

    private static String getServiceCode(String serviceTypeCode) {
        // Check if the string is not null or empty
        if (String.isNotEmpty(serviceTypeCode)) {
            // Get the first two letters and convert them to uppercase
            return serviceTypeCode.substring(0, 2).toUpperCase();
        }// Return an empty string if the input is null or empty
        return '';
    }

    public static String generateNewBookingNumber() {
        List<Opportunity> lastOpp = new List<Opportunity>();
        // Query the last Opportunity created, ordered by CreatedDate descending, limit to 1 result
        lastOpp = [SELECT Name FROM Opportunity WHERE Name LIKE 'EN%' ORDER BY CreatedDate DESC LIMIT 1];

        // Check if a last Opportunity exists
        if (lastOpp != null && !lastOpp.isEmpty() && lastOpp[0].Name != null) {
            String lastOppName = lastOpp[0].Name;
            // Ensure the format is correct before extracting the numeric part
            if (lastOppName.length() == 17) {
                String numericPart = lastOppName.substring(7); // Extract the numeric part after 'Numeric part'
                // Validate if the numeric part is a valid number
                if (isNumeric(numericPart)) {
                    // Convert the numeric part to a long and increment it
                    Long nextNumber = Long.valueOf(numericPart) + 1;
                    // Convert the number to a string and pad with leading zeros
                    String nextNumberString = String.valueOf(nextNumber);
                    // Ensure the next number is always 16 digits long (pad with leading zeros if needed)
                    while (nextNumberString.length() < 10) {
                        nextNumberString = '0' + nextNumberString;
                    }
                    // Construct and return the new Opportunity name
                    return nextNumberString;
                } else {
                    // If the numeric part is invalid, handle accordingly
                    return '0000000001';  // Default or fallback value
                }
            }
        }

        // If no Opportunity exists, return the starting name
        return '0000000001';
    }

    // Helper method to check if a string is a valid number
    public static Boolean isNumeric(String str) {
        try {
            Long.valueOf(str);  // Try to convert to Long
            return true;
        } catch (Exception e) {
            return false;
        }
    }
}