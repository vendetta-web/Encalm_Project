public class OpportunityTriggerHanlder {
     public static void updateServiceDateTimeFields(List<Opportunity> oppList) {
        try 
        {            
            for (Opportunity opp : oppList) 
            {
               Date arrivalDate = opp.Date_of_Arrival__c != null ? Date.valueOf(opp.Date_of_Arrival__c) : null;
               Date departureDate = opp.Date_of_Departure__c != null ? Date.valueOf(opp.Date_of_Departure__c) : null;
               Time sta = opp.STA_Time__c != null ? parseTime(opp.STA_Time__c) : null;
               Time std = opp.STd_Time__c != null ? parseTime(opp.STd_Time__c) : null;
    
                // Transit & Arrival : When STA is present
                if (sta != null ) {
                    opp.Service_Date__c = arrivalDate;
                    opp.Service_Time__c = sta;
                }
                // Departure-Domestic : When STD is present and Flight Type is Domestic
                else if (sta == null && std != null && opp.Flight_Type__c == 'Domestic') {
                    DateTime stdDateTime = DateTime.newInstance(departureDate, std);
                    DateTime serviceDateTime = stdDateTime.addMinutes(-90); // 1.5 hours
                    opp.Service_Date__c = serviceDateTime.date();
                    opp.Service_Time__c = serviceDateTime.time();
                }
                // Departure-International : When STD is present and Flight Type is International
                else if (sta == null && std != null && opp.Flight_Type__c == 'International') {
                    DateTime stdDateTime = DateTime.newInstance(departureDate, std);
                    DateTime serviceDateTime = stdDateTime.addHours(-3);
                    opp.Service_Date__c = serviceDateTime.date();
                    opp.Service_Time__c = serviceDateTime.time();
                }
            }
        } 
         catch (Exception e) {
            System.debug('Error occurred in updateServiceDateTimeFields method: ' + e.getMessage());
        }
    }
	private static Time parseTime(String timeText) {
        if (String.isBlank(timeText) || !timeText.contains(':')) return null;
        List<String> parts = timeText.split(':');
        try {
            Integer hour = Integer.valueOf(parts[0]);
            Integer minute = Integer.valueOf(parts[1]);
            return Time.newInstance(hour, minute, 0, 0);
        } catch (Exception e) {
            return null; // avoid breaking the trigger
        }
    }
}