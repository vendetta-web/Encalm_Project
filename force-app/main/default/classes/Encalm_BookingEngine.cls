public with sharing class Encalm_BookingEngine {
    @AuraEnabled(cacheable=true)
    public static AirportWrapper getAirportDetails() {
        List<Map<String, String>> baseValues = new List<Map<String, String>>();
        List<Map<String, String>> airportListValues = new List<Map<String, String>>();
        Map<String, String> airportCountryMap = new Map<String, String>();
        AirportWrapper wrap = new AirportWrapper();
        try {
            List<Airport__c> getAirportsWithService = [
                SELECT Id,Airport_Code__c,Name,Type__c,Country__c,Service_Available__c
                FROM Airport__c
                ORDER BY Airport_Code__c
                ];
            if(getAirportsWithService!=null) {
                for(Airport__c air: getAirportsWithService) {
                    if(air.Service_Available__c){                    
                        Map<String, String> baseValueMap = new Map<String, String>();
                        baseValueMap.put('label', air.Name);
                        baseValueMap.put('value', air.Airport_Code__c);
                        baseValues.add(baseValueMap);
                    }
                    Map<String, String> airportsValueMap = new Map<String, String>();
                    airportsValueMap.put('label', air.Name);
                    airportsValueMap.put('value', air.Airport_Code__c);
                    airportsValueMap.put(air.Airport_Code__c, air.Id);
                    airportListValues.add(airportsValueMap);
                    airportCountryMap.put(air.Airport_Code__c, air.Country__c);
                }
                wrap.baseAirportPicklist = baseValues;
                wrap.allAirportPicklist = airportListValues;
                wrap.airportToCountryMap = new Map<String, String>(airportCountryMap);
            }
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return wrap;
    }
    public class AirportWrapper {
        @AuraEnabled
        public List<Map<String, String>> baseAirportPicklist {get;set;}
        @AuraEnabled
        public List<Map<String, String>> allAirportPicklist {get;set;}
        @AuraEnabled
        public Map<String, String> airportToCountryMap {get;set;}
    }

    @AuraEnabled(cacheable=true)
    public static FlightWrapper getFlightDetails(Date flightDate, String departAirport, String arrivalAirport) {
        List<Map<String, String>> flightListValues = new List<Map<String, String>>();
        Map<String, Time> flightStaMap = new Map<String, Time>();
        Map<String, Time> flightDtaMap = new Map<String, Time>();
        FlightWrapper wrap = new FlightWrapper();
        try {
            List<Flight_Schedule__c> flightScheduleList = [
                SELECT Id,
                Flight_Detail__r.Name, STA__c, STD__c, Flight_Date__c
                FROM Flight_Schedule__c
                WHERE Flight_Date__c =: flightDate
                AND Flight_Detail__r.Arrival_Airport__r.Airport_Code__c =:arrivalAirport
                AND Flight_Detail__r.Departure_Airport__r.Airport_Code__c =:departAirport
                ];
            if(flightScheduleList!=null) {
                for(Flight_Schedule__c fly: flightScheduleList) {
                    Map<String, String> flightValueMap = new Map<String, String>();
                    flightValueMap.put('label', fly.Flight_Detail__r.Name);
                    flightValueMap.put('value', fly.Flight_Detail__r.Name);
                    flightValueMap.put(fly.Flight_Detail__r.Name,fly.Id);
                    flightListValues.add(flightValueMap);
                    flightStaMap.put(fly.Flight_Detail__r.Name, fly.STA__c);
                    flightDtaMap.put(fly.Flight_Detail__r.Name, fly.STD__c);
                }
                wrap.flightPicklist = flightListValues;
                wrap.flightNumberToStaMap = new Map<String, Time>(flightStaMap);
                wrap.flightNumberToDtaMap = new Map<String, Time>(flightDtaMap);
            }
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return wrap;
    }

    @AuraEnabled(cacheable=true)
    public static FlightWrapper getTransitFlightDetails(Date flightDate, String departAirport, String arrivalAirport, String transitAirport) {
        List<Map<String, String>> flightListValues = new List<Map<String, String>>();
        Map<String, Time> flightStaMap = new Map<String, Time>();
        Map<String, Time> flightDtaMap = new Map<String, Time>();
        List<Flight_Schedule__c> flightScheduleList = new List<Flight_Schedule__c>();
        FlightWrapper wrap = new FlightWrapper();
        try {
            if (String.isBlank(arrivalAirport)) {                
                flightScheduleList = [
                    SELECT Flight_Detail__r.Name,STA__c, STD__c
                    FROM Flight_Schedule__c
                    WHERE Flight_Date__c =:flightDate
                    AND Flight_Detail__c
                    IN (SELECT Main_Flight__c FROM Transit_Flight_Detail__c WHERE Transit_Airport__r.Airport_Code__c  =:transitAirport AND Main_Flight__r.Departure_Airport__r.Airport_Code__c =:departAirport)
                    ];
            } else if (String.isBlank(departAirport)) {                
                flightScheduleList = [
                    SELECT Flight_Detail__r.Name,STA__c, STD__c
                    FROM Flight_Schedule__c
                    WHERE Flight_Date__c =:flightDate
                    AND Flight_Detail__c
                    IN (SELECT Connecting_Flight__c FROM Transit_Flight_Detail__c WHERE Transit_Airport__r.Airport_Code__c  =:transitAirport AND Connecting_Flight__r.Arrival_Airport__r.Airport_Code__c =:arrivalAirport)
                    ];
            }  
            if(flightScheduleList!=null) {
                for(Flight_Schedule__c fly: flightScheduleList) {
                    Map<String, String> flightValueMap = new Map<String, String>();
                    flightValueMap.put('label', fly.Flight_Detail__r.Name);
                    flightValueMap.put('value', fly.Flight_Detail__r.Name);
                    flightListValues.add(flightValueMap);
                    flightStaMap.put(fly.Flight_Detail__r.Name, fly.STA__c);
                    flightDtaMap.put(fly.Flight_Detail__r.Name, fly.STD__c);
                }
                wrap.flightPicklist = flightListValues;
                wrap.flightNumberToStaMap = new Map<String, Time>(flightStaMap);
                wrap.flightNumberToDtaMap = new Map<String, Time>(flightDtaMap);
            }
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return wrap;
    }
    public class FlightWrapper {
        @AuraEnabled
        public List<Map<String, String>> flightPicklist {get;set;}
        @AuraEnabled
        public Map<String, Time> flightNumberToStaMap {get;set;}
        @AuraEnabled
        public Map<String, Time> flightNumberToDtaMap {get;set;}
    }
}