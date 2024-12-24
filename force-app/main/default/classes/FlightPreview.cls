public with sharing class FlightPreview {
    @AuraEnabled
    public static bookingWrapper getOpportunityDetails(Id opportunityId) {
        // Fetch Opportunity record with related fields for adults, children, and infants
        Opportunity opp =  [SELECT Id, 
                       Service_Type__c,
                       Number_of_Adults__c, 
                       Number_of_Children__c, 
                       Number_of_Infants__c,
                       Date_of_Arrival__c,
                       Date_of_Departure__c,
                       Service_Airport__c,
                       Flight_Number_Arrival__c,
                       Flight_Number_Departure__c,
                       Arriving_Airport__c,
                       Departure_Airport__c,
                       Flight_Type__c,
                       STA_Time__c,
                       STD_Time__c,
                       Sector__c
                FROM Opportunity 
                WHERE Id = :opportunityId 
                LIMIT 1];
                bookingWrapper bookWrp = new bookingWrapper();
        bookWrp.serviceType = opp.Service_Type__c;
        bookWrp.NoOfAdult = opp.Number_of_Adults__c;
        bookWrp.NoOfChild = opp.Number_of_Children__c;
        bookWrp.NoOfInfant = opp.Number_of_Infants__c;
        bookWrp.serviceAirport = opp.Service_Airport__c;
        bookWrp.arrivingAirport = opp.Arriving_Airport__c;
        bookWrp.departureAirport = opp.Departure_Airport__c;
        bookWrp.flightNumberArrival = opp.Flight_Number_Arrival__c;
        bookWrp.flightNumberDeparture = opp.Flight_Number_Departure__c;
        bookWrp.departureDate = opp.Date_of_Departure__c != null ? Date.valueOf(opp.Date_of_Departure__c) : Date.today();
        bookWrp.arrivalDate = opp.Date_of_Arrival__c != null ? Date.valueOf(opp.Date_of_Arrival__c) : Date.today();
        bookWrp.sector = opp.Flight_Type__c;
        bookWrp.staTime = opp.STA_Time__c;
        bookWrp.stdTime = opp.STD_Time__c;
        return bookWrp;
    }

    @AuraEnabled
    public static void saveData(String oppId, Map<String, Object> opportunityFieldValues) {
        if (String.isBlank(oppId)) {
            throw new AuraHandledException('Error in saving details');
        }

        try {
                if (opportunityFieldValues != null && !opportunityFieldValues.isEmpty()) {
                    Opportunity opp = new Opportunity(Id = oppId);
                    for (String fieldName : opportunityFieldValues.keySet()) {
                        opp.put(fieldName, opportunityFieldValues.get(fieldName));
                    }
                    update opp; // Save the updates
                }
        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }
    
    public class bookingWrapper {
        @AuraEnabled
        public String serviceType;
        @AuraEnabled
        public Decimal NoOfAdult;
        @AuraEnabled
        public Decimal NoOfChild;
        @AuraEnabled
        public Decimal NoOfInfant;
        @AuraEnabled
        public String serviceAirport;
        @AuraEnabled
        public String flightNumberArrival;
        @AuraEnabled
        public String flightNumberDeparture;
        @AuraEnabled
        public Date departureDate;
        @AuraEnabled
        public Date arrivalDate;
        @AuraEnabled
        public String arrivingAirport;
        @AuraEnabled
        public String departureAirport;
        @AuraEnabled
        public String sector;
        @AuraEnabled
        public String staTime;
        @AuraEnabled
        public String stdTime;
    }
}