/**
* @File Name : PassengerDetailProcessor .cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : October 8, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 8, 2024 |   | Initial Version
**/

    public class PassengerDetailProcessor {
        public static void processEmailBody(String emailBody) {
            //System.debug('Email Body: ' + emailBody);
    
            List<Passenger_Details__c> passengers = new List<Passenger_Details__c>();
            try {
                Pattern pattern = Pattern.compile('name: ([^,]+), age: ([^,]+), gender: ([^\\n]+)');
                Matcher matcher = pattern.matcher(emailBody);
    
                while (matcher.find()) {
                    //System.debug('Matched Groups: ' + matcher.group(1) + ', ' + matcher.group(2) + ', ' + matcher.group(3));
    
                    Passenger_Details__c passenger = new Passenger_Details__c();
                    passenger.Name = matcher.group(1);
                    passenger.Age__c = Integer.valueOf(matcher.group(2));
                    passenger.Gender__c = matcher.group(3);
    
                    passengers.add(passenger);
                    //System.debug('Collected Passenger: ' + passenger);
                }
    
                if (!passengers.isEmpty()) {
                    insert passengers;
                    //System.debug('Inserted Passengers: ' + passengers);
                } else {
                    System.debug('No passengers found in the email.');
                }
            } catch (Exception e) {
                System.debug('Error processing email: ' + e.getMessage());
            }
        }
    }