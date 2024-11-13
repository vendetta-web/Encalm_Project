@RestResource(urlMapping='/v1/lead/*')
global class MDEN_LeadCreationApi {
      @HttpPost
    global static MDEN_ResponseWrapper getRecord() {
        try {
            RestRequest request = RestContext.request;
            Map<String, Object> requestMap = (Map<String, Object>) JSON.deserializeUntyped(request.requestbody.toString());

            // Check if all required fields are present
            if (requestMap != null &&
                requestMap.containsKey('email') &&
                requestMap.containsKey('lastName') &&
                requestMap.containsKey('travelDate') &&
                requestMap.containsKey('numberOfAdult') &&
                requestMap.containsKey('company')) {

                // Query to check if lead already exists
                List<Lead> existingLeads = [SELECT Id FROM Lead WHERE Email = :String.valueOf(requestMap.get('email')) LIMIT 1];

                Lead ld = new Lead();
                ld.LastName = (String) requestMap.get('lastName');
                ld.FirstName = (String) requestMap.get('firstName'); 
                ld.Email = (String) requestMap.get('email');
                ld.Company = (String) requestMap.get('company');
                ld.Travel_Date__c = Date.valueOf((String) requestMap.get('travelDate'));
                ld.Number_of_Adult__c = (Integer) requestMap.get('numberOfAdult');
                    ld.Airline_PNR__c = (String) requestMap.get('airlinePNR');

                if (!existingLeads.isEmpty()) {
                    // Lead already exists, update it
                    Lead existingLead = existingLeads[0];
                    ld.Id = existingLead.Id;
                    update ld;
                    return new MDEN_ResponseWrapper(ld.Id, true, null);
                } else {
                    // Lead doesn't exist, insert new
                    insert ld;
                    return new MDEN_ResponseWrapper(ld.Id, true, null);
                }

            } else {
                // Return error if required fields are missing
                return new MDEN_ResponseWrapper(null, false, 'Required Fields Missing');
            }
        } catch (Exception e) {
            // Log exception and return error message
            return new MDEN_ResponseWrapper(null, false, 'Error: ' + e.getMessage());
        }
    }
}