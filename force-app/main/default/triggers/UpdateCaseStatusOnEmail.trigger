trigger UpdateCaseStatusOnEmail on EmailMessage (after insert) {
     if(trigger.isAfter){
        if (Trigger.isInsert) {
           EmailMessageHandler.updateCaseStatus(Trigger.new);
        }
    }    
}