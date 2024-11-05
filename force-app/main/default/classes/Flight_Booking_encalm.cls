public class Flight_Booking_encalm {
    @AuraEnabled(cacheable=true)
public static List<Arriving_Airport__mdt> getAirport(){
     List<Arriving_Airport__mdt>airPortList = [SELECT Departure_Airport__c, Arival__c FROM Arriving_Airport__mdt ];
return  airPortList;

}
    
    @AuraEnabled
        public static   List<Flight_Detail__c> getFlightInfo(Date arrivalDate){
            system.debug('arrivalDate-------->'+arrivalDate);
            List<Flight_Detail__c> flightDetailList = [SELECT Id, Flight_Number__c,Flight_Date__c, STA__c  FROM  Flight_Detail__c WHERE Flight_Date__c =:arrivalDate ];
            system.debug('flightDetailList-------->'+flightDetailList);
            return flightDetailList;
        }

@AuraEnabled
        public static Boolean createOpportunity(String arrivingAirport, String departureAirport, Date dateOfArrival, String sector, String flightNumber ,String infantCount, String childCount, String adultCount){
      System.debug('---------------arrivingAirport---'+arrivingAirport);
            system.debug('----------departureAirport-------------'+departureAirport);

            system.debug('-------------------dateOfArrival----'+dateOfArrival);
            system.debug('----------sector-------------'+sector);
            system.debug('-----------------flightNumber------'+flightNumber);
            system.debug('---------------adultCount--------'+adultCount);
            system.debug('------------childCount-----------'+childCount);
            system.debug('----------------adultCount-------'+adultCount);
          return true;
        }
}