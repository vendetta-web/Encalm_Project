trigger CaseTrigger on Case (before insert, before update) {
    try{
        for (Case caseRecord : Trigger.new) {
            if (String.isNotBlank(caseRecord.Description)) {
                String emailBody = caseRecord.Description;
                
                System.debug('Email Body: ' + emailBody);
                
                EmailParser.parseAndSetPicklistFromEmail(caseRecord, emailBody);
            }
        }
    }catch (Exception e) {
        System.debug('Unexpected error in parseAndSetPicklistFromEmail: ' + e.getMessage());
    }
    
    
}