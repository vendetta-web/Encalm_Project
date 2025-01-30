public class CancellationPolicyService {

    public static Decimal getCancellationPolicyAmount(DateTime serviceDateTime, DateTime cancellationDateTime, Decimal bookingAmount, String packageName) {
        // Calculate the difference in hours between the service and cancellation times
        Long hoursDifference = serviceDateTime.getTime() - cancellationDateTime.getTime();
        hoursDifference = hoursDifference / (1000 * 60 * 60);  // Convert milliseconds to hours
        
        // Query the cancellation policies
        List<Cancellation_And_Refund__mdt> policies = [SELECT MasterLabel, Time_Frame__c,
                                                   Charges_in_Percentage__c, Charges__c,
                                                   Greater_Than__c, Less_Than__c, Package__c
                                                   FROM Cancellation_And_Refund__mdt 
                                                   WHERE IsActive__c = true
                                                   AND (Package__c =:packageName OR Package__c='General')
                                                   ORDER BY Sort_Order__c];

        // Iterate through policies to find the applicable one
        for (Cancellation_And_Refund__mdt policy : policies) {
            if (policy.Package__c == 'General' && policy.Less_Than__c &&  hoursDifference < Long.valueOf(policy.Time_Frame__c)) {
                if (policy.Charges_in_Percentage__c) {
                    bookingAmount = bookingAmount - (bookingAmount * (policy.Charges__c / 100));
                } else {
                    bookingAmount = bookingAmount - policy.Charges__c;
                } 
            } 
            if (policy.Package__c == 'General' && policy.Greater_Than__c && Long.valueOf(policy.Time_Frame__c) < hoursDifference) {
                if (policy.Charges_in_Percentage__c) {
                    bookingAmount = bookingAmount - (bookingAmount * (policy.Charges__c / 100));
                } else {
                    bookingAmount = bookingAmount - policy.Charges__c;
                } 
            }
            if (policy.Less_Than__c &&  hoursDifference < Long.valueOf(policy.Time_Frame__c)) {
                if (policy.Charges_in_Percentage__c) {
                    return bookingAmount - (bookingAmount * (policy.Charges__c / 100));
                } else {
                    return bookingAmount - policy.Charges__c;
                } 
            } 
            else if (policy.Greater_Than__c && Long.valueOf(policy.Time_Frame__c) < hoursDifference) {
                if (policy.Charges_in_Percentage__c) {
                    return bookingAmount - (bookingAmount * (policy.Charges__c / 100));
                } else {
                    return bookingAmount - policy.Charges__c;
                } 
            }
            else if (policy.Time_Frame__c.contains('-')) {
                List<String> rangeValues = policy.Time_Frame__c.split('-');
                Integer lowerValue = Integer.valueOf(rangeValues[0]); // First value (24)
                Integer upperValue = Integer.valueOf(rangeValues[1]); // Second value (48)
                if (hoursDifference > lowerValue && hoursDifference < upperValue) {
                    if (policy.Charges_in_Percentage__c) {
                        return bookingAmount - (bookingAmount * (policy.Charges__c / 100));
                    } else {
                        return bookingAmount - policy.Charges__c;
                    } 
                }
            }
        }
        // Default to no charge if no policy matches
        return 0;
    }

    @AuraEnabled(cacheable=true)
    public static cancellationDetailsWrapper showCancellationCharges(Decimal bookingAmount, String packageName, String opportunityId ,Integer numberOfPax) {
        cancellationDetailsWrapper wrp = new cancellationDetailsWrapper();
        DateTime serviceDateTime;
        String dateText;
        String timeText;
        String combinedDateTimeStr;
        // Query OpportunityLineItems based on OpportunityId
        Opportunity opp = [
            SELECT STA_Time__c,STD_Time__c,Date_of_Arrival__c,Date_of_Departure__c,Amount
            FROM Opportunity
            WHERE Id=:opportunityId
            LIMIT 1
        ];
        if (opp.STA_Time__c != null) {
            dateText=opp.Date_of_Arrival__c;
            timeText=opp.STA_Time__c;
            // Ensure timeText includes seconds
            if (timeText.length() == 5) {  // "HH:mm" format
                timeText += ':00';  // Append ":00" for seconds
            }
            combinedDateTimeStr=dateText + ' ' + timeText;
            serviceDateTime = DateTime.valueOf(combinedDateTimeStr);
        } else if (opp.STD_Time__c != null) {
            dateText=opp.Date_of_Departure__c;
            timeText=opp.STD_Time__c;
            combinedDateTimeStr=dateText + ' ' + timeText;
            serviceDateTime = DateTime.valueOf(combinedDateTimeStr);
        }
        decimal refundAmount = getCancellationPolicyAmount(serviceDateTime, DateTime.now(), opp.Amount, packageName);
        wrp.bookingAmount = opp.Amount;
        wrp.refundAmount = refundAmount;
        wrp.deductedAmount = opp.Amount - refundAmount;
        wrp.refundMethod = 'Original Payment Mode';
        wrp.numberOfPaxCancelled = numberOfPax;

        return wrp;
    }

    @AuraEnabled(cacheable=true)
    public static List<passengerDetailsWrapper> getBookingToCancel(String opportunityId) {
        List<passengerDetailsWrapper> pdList = new List<passengerDetailsWrapper>();

        // Query OpportunityLineItems based on OpportunityId
        List<Passenger_Details__c> passengerList = [
            SELECT Id,Name, Individual_Booking_Details__r.UnitPrice, Individual_Booking_Details__c,
            Passenger_Type__c, Individual_Booking_Details__r.Product2.Family
            FROM Passenger_Details__c
            WHERE Opportunity_ID__c=:opportunityId
        ];

        // Populate wrapper class list
        for (Passenger_Details__c pd : passengerList) {
            pdList.add(new passengerDetailsWrapper(pd));
        }

        return pdList;
    }

    // Wrapper class to hold passengerDetails fields
    public class passengerDetailsWrapper {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String oliId { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String packageName { get; set; }
        @AuraEnabled public Decimal unitPrice { get; set; }
        @AuraEnabled public Integer quantity { get; set; }
        @AuraEnabled public String type { get; set; }

        public passengerDetailsWrapper(Passenger_Details__c pd) {
            this.id = pd.Id;
            this.oliId = pd.Individual_Booking_Details__c;
            this.name = pd.Name;
            this.packageName = pd.Individual_Booking_Details__r.Product2.Family;
            this.unitPrice = pd.Individual_Booking_Details__r.UnitPrice;
            this.quantity = 1;
            this.type = pd.Passenger_Type__c;

        }
    }

    public class cancellationDetailsWrapper {
        @AuraEnabled public Decimal bookingAmount;
        @AuraEnabled public Decimal refundAmount;
        @AuraEnabled public Decimal deductedAmount;
        @AuraEnabled public String refundMethod;
        @AuraEnabled public Integer numberOfPaxCancelled;
    }
}