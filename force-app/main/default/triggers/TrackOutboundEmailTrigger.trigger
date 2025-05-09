trigger TrackOutboundEmailTrigger on EmailMessage (after insert) {
    if(trigger.isAfter){
        if(trigger.isInsert){
            EmailMessageHandler.updateCaseStatus(Trigger.new);   
            //EmailMessageHandler.updateLeadStatus(Trigger.new);  
            EmailMessageHandler.sendCustomNotification(Trigger.new); 
        }
    }
}