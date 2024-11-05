global class TravelDetailsEmailHandler implements Messaging.InboundEmailHandler {
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();

        // Extract email body
        String emailBody = email.plainTextBody;
        
        system.debug('test ==>'+emailBody);
          return null;
        
    }
}