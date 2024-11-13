@RestResource(urlMapping='/Create_Lead/*')
global class LeadConversion {
    @HttpPost
    global static LeadConversionWrapper leadConversion() {
        LeadConversionWrapper responseWrapper = new LeadConversionWrapper();
        
        try {
            RestRequest req = RestContext.request;
            String reqBody = req.requestBody.toString();
            LeadConversionWrapper reqBean = (LeadConversionWrapper) JSON.deserialize(reqBody, LeadConversionWrapper.class);
            System.debug('Request received: ' + reqBean);

            Lead newLead = new Lead();
            newLead.Company = reqBean.company;
            newLead.Travel_Date__c = Date.valueOf(reqBean.travelDate);
            newLead.Email = reqBean.email;
            newLead.Phone = reqBean.phone;
            newLead.LastName = reqBean.lastName;
            newLead.FirstName = reqBean.firstName;
            newLead.Number_of_Adult__c = reqBean.numberofAdult;
            insert newLead;
            responseWrapper.leadId = newLead.Id;

            if (newLead != null && !reqBean.addOnServices.isEmpty()) {
                List<Add_On__c> addOnList = new List<Add_On__c>();
                for (LeadConversionWrapper.AddOnServices rec : reqBean.addOnServices) {
                    Add_On__c addonRec = new Add_On__c();
                    addonRec.Name = rec.name;
                    addonRec.Lead_ID__c = newLead.Id;
                    addonRec.AddOnServiceQty__c = rec.addOnServiceQty != null ? Decimal.valueOf(rec.addOnServiceQty) : null;
                    addonRec.AddOnService__c = rec.addOnService;
                    addOnList.add(addonRec);
                }
                if (!addOnList.isEmpty()) {
                    insert addOnList;
                }
            }

            if (newLead != null && !reqBean.passengerDetails.isEmpty()) {
                List<Passenger_Details__c> passengerDetailsList = new List<Passenger_Details__c>();
                for (LeadConversionWrapper.PassengerDetails rec : reqBean.passengerDetails) {
                    Passenger_Details__c passengerDetailsRec = new Passenger_Details__c();
                    passengerDetailsRec.Name = rec.name;
                    passengerDetailsRec.Lead_ID__c = newLead.Id;
                    passengerDetailsRec.Airline_PNR__c = newLead.Id;
                    passengerDetailsList.add(passengerDetailsRec);

                    // Debugging information for each passenger detail
                    System.debug('Passenger detail added: ' + passengerDetailsRec);
                }
                if (!passengerDetailsList.isEmpty()) {
                    insert passengerDetailsList;
                } else {
                    System.debug('No passenger details to insert.');
                }
            } else {
                System.debug('No passenger details provided or Lead creation failed.');
            }

            responseWrapper.success = true;
            responseWrapper.message = 'Lead created successfully!';
        } catch (Exception e) {
            System.debug('Error in leadConversion: ' + e.getMessage());
            responseWrapper.success = false;
            responseWrapper.message = 'Error occurred: ' + e.getMessage();
        }

        return responseWrapper;
    }
}