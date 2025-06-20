trigger TrackOutboundEmailTrigger on EmailMessage (after insert, before insert) {
    if(trigger.isAfter){
        if(trigger.isInsert){
            EmailMessageHandler.updateCaseStatus(Trigger.new);   
            //EmailMessageHandler.updateLeadStatus(Trigger.new);  
            EmailMessageHandler.sendCustomNotification(Trigger.new); 
            //EmailMessageHandler.updateLeadOnSendEmail(Trigger.new);
            EmailMessageHandler.updateEmailMessage(Trigger.new);
            //EmailMessageHandler.handleAfterInsert(Trigger.new);
        }
    }
    if(trigger.isBefore){
        if(trigger.isInsert){
          //EmailMessageHandler.updateBodyWithMailHistory(Trigger.new);   
        }
    }
}