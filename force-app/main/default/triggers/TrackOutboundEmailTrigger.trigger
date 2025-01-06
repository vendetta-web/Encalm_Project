trigger TrackOutboundEmailTrigger on EmailMessage (after insert) {
    if(trigger.isAfter){
        if(trigger.isInsert){
            EmailMessageHandler.processOutboundEmails(Trigger.new);   
        }
    }
}