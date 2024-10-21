/**
* @File Name : PassengerEmailHandler.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : October 7, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 7, 2024 |   | Initial Version
**/

public with sharing class PassengerEmailHandler implements Messaging.InboundEmailHandler {
    public Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        
        try {
            String emailBody = email.plainTextBody;
            System.debug('Email Body: ' + emailBody);
            List<Passenger_Details__c> passengers = new List<Passenger_Details__c>();
            
            String[] lines = emailBody.split('\n');
            for (String line : lines) {
                System.debug('Processing line: ' + line);
                if (line.contains('Name:') && line.contains('Age:') && line.contains('Gender:')) {
                    Pattern p = Pattern.compile('Name:\\s*([^,]+),\\s*Age:\\s*(\\d+),\\s*Gender:\\s*([^,]+)');
                    Matcher m = p.matcher(line);
                    
                    if (m.find()) {
                        System.debug('Matched Groups: ' + m.group(1) + ', ' + m.group(2) + ', ' + m.group(3));
                        
                        String name = m.group(1).trim();
                        Integer age = Integer.valueOf(m.group(2).trim());
                        String gender = m.group(3).trim();
                        
                        Passenger_Details__c passenger = new Passenger_Details__c(
                            Name = name,
                            Age__c = age,
                            Gender__c = gender
                        );
                        passengers.add(passenger);
                        System.debug('Passenger: ' + passenger);
                    } else {
                        System.debug('No match found for line: ' + line);
                    }
                }
            }
            
            if (!passengers.isEmpty()) {
                insert passengers;
            } else {
                System.debug('No passengers found in the email.');
            }

            result.success = true;
        } catch (Exception e) {
            System.debug('Error processing email: ' + e.getMessage());
            result.success = false;
        }
        
        return result;
    }
}