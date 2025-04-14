public class EmailMessageHandler {
    public static void updateCaseStatus(List<EmailMessage> emailMessages) {
        Set<Id> caseIds = collectCaseIds(emailMessages);
        
        if (!caseIds.isEmpty()) {
            Map<Id, Case> casesToUpdate = new Map<Id, Case>();
            
            // Query Cases and associated EmailMessages
            List<Case> cases = [SELECT Id, Status, Origin, CaseNumber,
                                (SELECT Id, Incoming, CreatedDate, Subject, Headers 
                                 FROM EmailMessages 
                                 ORDER BY CreatedDate DESC) 
                                FROM Case 
                                WHERE Id IN :caseIds];
            
            // Process each case
            for (Case c : cases) {
                processCase(c, casesToUpdate);
            }
            
            // Update cases if needed
            if (!casesToUpdate.isEmpty()) {
                updateCases(casesToUpdate);
            }
        }
    }
    
    private static Set<Id> collectCaseIds(List<EmailMessage> emailMessages) {
        Set<Id> caseIds = new Set<Id>();
        
        for (EmailMessage em : emailMessages) {
            if (em.ParentId != null && String.valueOf(em.ParentId).startsWith('500')) { // Check if related to a Case
                caseIds.add(em.ParentId);
            }
        }
        
        return caseIds;
    }
    
    private static void processCase(Case c, Map<Id, Case> casesToUpdate) {
        System.debug('Processing case with ID: ' + c.Id);
        
        if (!c.EmailMessages.isEmpty()) { // Ensure there are email messages
            EmailMessage latestEmail = c.EmailMessages[0]; // Fetch the most recent email
            
            
            if (!latestEmail.Incoming && latestEmail.Headers != null && !latestEmail.Headers.contains('auto-generated')) { 
                // Outbound email (agent sends email)
                c.Status = 'Awaiting Customer Response';
                System.debug('Updating Case ID ' + c.Id + ' to Awaiting Customer Response');
            } 
            else if (latestEmail.Incoming  && c.Status == 'Awaiting Customer Response') {
                // Inbound email (customer responds)
                c.Status = 'Customer Responded';
                System.debug('Updating Case ID ' + c.Id + ' to Customer Responded');
            }
            
            // Add the Case to the update map if it needs updating
            casesToUpdate.put(c.Id, c);
        }
    }
    
    private static void updateCases(Map<Id, Case> casesToUpdate) {
        try {
            update casesToUpdate.values();
            System.debug('Successfully updated cases: ' + casesToUpdate.keySet());
        } catch (Exception e) {
            System.debug('Error updating cases: ' + e.getMessage());
        }
    }
}