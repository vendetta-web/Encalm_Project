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
          return true;
        }

        @AuraEnabled(cacheable=true)
        public static List<Map<String, String>> getLocation(Id accountId) {
            List<Map<String, String>> result = new List<Map<String, String>>();

            // Query child accounts
            List<Account> childAccounts = [ SELECT Id, BillingState FROM Account WHERE ParentId = :accountId AND BillingState != null ];

            if (!childAccounts.isEmpty()) {
                for (Account acc : childAccounts) {
                    result.add(new Map<String, String>{
                        'label' => acc.BillingState,
                        'value' => acc.Id
                    });
                }
            } else {
                // No children; get the parent account's billing state
                Account parentAccount = [ SELECT Id, BillingState FROM Account WHERE Id = :accountId AND BillingState != null LIMIT 1 ];

                if (parentAccount != null) {
                    result.add(new Map<String, String>{
                        'label' => parentAccount.BillingState,
                        'value' => parentAccount.Id
                    });
                }
            }

            return result;
        }

        @AuraEnabled(cacheable=true)
        public static Boolean isBusinessAccount(Id accountId) {
            if (accountId == null) {
                throw new AuraHandledException('Account Id is required.');
            }
            
            Account acc = [SELECT RecordType.DeveloperName FROM Account WHERE Id = :accountId LIMIT 1];
            return acc.RecordType != null && acc.RecordType.DeveloperName == 'Business_Account';
        }


        @AuraEnabled(cacheable=true)
        public static List<Contact> getContactsByAccount(Id accountId) {
            return [ SELECT Id, FirstName, LastName, Email FROM Contact WHERE AccountId = :accountId ];
        }

}