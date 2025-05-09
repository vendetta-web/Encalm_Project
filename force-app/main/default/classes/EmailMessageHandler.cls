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
            Boolean hasCustomerReplied = false;
            if (latestEmail.Incoming && latestEmail.Subject != null && latestEmail.Subject.contains(c.CaseNumber)) {
                hasCustomerReplied = true;
                system.debug('hasCustomerReplied++'+hasCustomerReplied);
            }
            if (!latestEmail.Incoming && (latestEmail.Headers == null || !latestEmail.Headers.contains('auto-generated'))) { 
                // Outbound email (agent sends email)
                c.Status = 'Awaiting Customer Response';
                c.refreshCase__c = false;
                System.debug('Updating Case ID ' + c.Id + ' to Awaiting Customer Response');
            } 
            else if (latestEmail.Incoming  && (c.Status == 'Awaiting Customer Response' || c.Status == 'New') && hasCustomerReplied) {
                // Inbound email (customer responds)
                c.Status = 'Customer Responded';
                System.debug('Updating Case ID ' + c.Id + ' to Customer Responded');
                List<String> subjectList = new List<String>{'Follow up','Updated Follow up'};
                List<Task> taskRecord = [Select id,Status,Subject FROM Task Where WhatId =: c.Id AND Status = 'Open' AND Subject IN : subjectList AND TaskSubType = 'Task' LIMIT 1 ];
                if(!taskRecord.IsEmpty()){
                    taskRecord[0].Status = 'Completed';
                    update taskRecord;
                }
                
                List<RefreshEvent__e> events = new List<RefreshEvent__e>();
                events.add(new RefreshEvent__e(CaseId__c = c.Id,LeadId__c = ''));
                if(!events.IsEmpty()){
                    EventBus.publish(events);
                }
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
    public static void sendCustomNotification(List<EmailMessage> newEmails) {
        Set<Id> caseIds = new Set<Id>();

        for (EmailMessage email : newEmails) {
            if (email.Incoming == true && email.ParentId != null && email.ParentId.getSObjectType() == Case.SObjectType) {
                caseIds.add(email.ParentId);
            }
        }

        if (caseIds.isEmpty()) return;

        Map<Id, Case> caseMap = new Map<Id, Case>([SELECT Id,CaseNumber,Contact.Name, OwnerId FROM Case WHERE Id IN :caseIds]);

        CustomNotificationType notificationType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Case_Operations_Notification' LIMIT 1 ];
        Map<Id, Set<String>> caseToRecipients = new Map<Id, Set<String>>();

        for (EmailMessage email : newEmails) {
            if (email.Incoming == true && caseMap.containsKey(email.ParentId)) {
                Case relatedCase = caseMap.get(email.ParentId);
                Id ownerId = relatedCase.OwnerId;

                if (String.valueOf(ownerId).startsWith('005')) {
                    if (!caseToRecipients.containsKey(relatedCase.Id)) {
                        caseToRecipients.put(relatedCase.Id, new Set<String>());
                    }
                    caseToRecipients.get(relatedCase.Id).add(String.valueOf(ownerId));
                }
            }
        }

        for (Id caseId : caseToRecipients.keySet()) {
            Case c = caseMap.get(caseId);
            String customerName = (c.Contact != null && c.Contact.Name != null) ? c.Contact.Name : 'Customer';
            String body = 'Received mail from ' + customerName + ' on case #'+ c.CaseNumber;
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setTitle('Email Received');
            notification.setBody(body);
            notification.setNotificationTypeId(notificationType.Id);
            notification.setTargetId(caseId);

            try {
                notification.send(caseToRecipients.get(caseId));
            } catch (Exception e) {
                System.debug('Failed to send notification: ' + e.getMessage());
            }
        }
    }
}