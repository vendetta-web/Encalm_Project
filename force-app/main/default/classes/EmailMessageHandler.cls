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
                //updateEmailMessage(new List<EmailMessage>{latestEmail});
                system.debug('hasCustomerReplied++'+hasCustomerReplied);
            }
            if (!latestEmail.Incoming && latestEmail.Headers != null && !latestEmail.Headers.contains('auto-generated')) { 
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
    public static void updateEmailMessage(List<EmailMessage> emailMessageList) {
        Set<Id> caseIds = new Set<Id>();
        
        for (EmailMessage em : emailMessageList) {
            if (em.Incoming && em.ParentId != null && em.ParentId.getSObjectType() == Case.SObjectType) {
                caseIds.add(em.ParentId);
            }
        }
        
        if (caseIds.isEmpty()) return;
        
        Map<Id, Case> closedCaseMap = new Map<Id, Case>([SELECT Id FROM Case WHERE Id IN :caseIds AND IsClosed = true]);
        
        if (closedCaseMap.isEmpty()) return;
        
        Map<Id, Id> caseToLeadMap = new Map<Id, Id>();
        for (Lead lead : [SELECT Id, Case__c FROM Lead WHERE Case__c IN :closedCaseMap.keySet()]) {
            caseToLeadMap.put(lead.Case__c, lead.Id);
        }
        
        if (caseToLeadMap.isEmpty()) return;
        
        List<EmailMessage> emailsToUpdate = new List<EmailMessage>();
        for (EmailMessage em : emailMessageList) {
            Id leadId = caseToLeadMap.get(em.ParentId);
            EmailMessage emailToUpdate = new EmailMessage(
                Id = em.Id,
                LeadId__c = leadId
            );
            emailsToUpdate.add(emailToUpdate);
        }
        
        if (!emailsToUpdate.isEmpty()) {
            update emailsToUpdate;
        }
    }
    
    public static void updateLeadOnSendEmail(List<EmailMessage> newEmails) {
        Set<String> identifiersToMatch = new Set<String>();
        Map<String, Id> caseNumberToCaseId = new Map<String, Id>();
        Map<String, Lead> leadIdToLead = new Map<String, Lead>();
        List<Lead> leadsToUpdate = new List<Lead>();
        Map<Id, Id> emailToTaskMap = new Map<Id, Id>(); // Store EmailMessage → Task ID mapping
        
        // Extract Case Numbers or Lead IDs from Email Subjects
        for (EmailMessage em : newEmails) {
            system.debug('Processing Email: ' + em.Subject);
            if (!em.Incoming) {
                String identifier = caseNumberOrLeadId(em.Subject);
                if (identifier != null) {
                    identifiersToMatch.add(identifier);
                }
            }
        } 
        
        if (identifiersToMatch.isEmpty()) {
            system.debug('No Case or Lead Found.');
            return;
        }
        
        // Retrieve Case IDs Matching the Extracted Case Numbers
        for (Case c : [SELECT Id, CaseNumber FROM Case WHERE CaseNumber IN :identifiersToMatch]) {
            caseNumberToCaseId.put(c.CaseNumber, c.Id);
        }
        
        // Retrieve Leads Matching the Extracted Lead IDs
        for (Lead l : [SELECT Id FROM Lead WHERE Id IN :identifiersToMatch]) {
            leadIdToLead.put(l.Id, l);
        }
        
        // Ensure we have either Cases or Leads to process
        if (caseNumberToCaseId.isEmpty() && leadIdToLead.isEmpty()) {
            system.debug('No Matching Cases or Leads Found.');
            return;
        }
        List<Lead> leadList = [SELECT Id, Email_History__c, Status FROM Lead WHERE Case__c IN :caseNumberToCaseId.values() OR Id IN :leadIdToLead.KeySet()];
        // Retrieve Leads Associated with These Cases
        for (Lead l : leadList) {
            // Log Email as an Activity
            for (EmailMessage em : newEmails) {
                String identifier = caseNumberOrLeadId(em.Subject);
                system.debug('identifier>>>' + identifier);                
                system.debug('leadIdToLead???'+ leadIdToLead);
                if (identifier != null) {
                    String idNormalized = (identifier.length() == 15) ? String.valueOf(Id.valueOf(identifier)) : identifier;
                    if (caseNumberToCaseId.containsKey(idNormalized) || leadIdToLead.containsKey(idNormalized)) {
                        Id taskId = logEmailAsActivity(l.Id, em.Subject, em.TextBody,em.FromAddress,em.ToAddress,em.CreatedDate);
                        emailToTaskMap.put(em.Id, taskId);
                    }
                }
                //l.Email_History__c = em.TextBody;
            }
            //String previousHistory = String.isNotBlank(l.Email_History__c) ? l.Email_History__c : '';
            l.Email_History__c = getPreviousEmails(l.Id);
            
            if (l.Status != 'Awaiting Customer response') {
                l.Status = 'Awaiting Customer response';
            }            
            leadsToUpdate.add(l);
        }
        if (!leadsToUpdate.isEmpty()) {
            update leadsToUpdate;
            system.debug('Updated ' + leadsToUpdate.size() + ' Leads.');
        }        
        
    }
    
    Public static string caseNumberOrLeadId(string subject){
        
        Pattern leadPattern = Pattern.compile('\\b00Q\\w+'); 
        Matcher leadMatcher = leadPattern.matcher(subject);            
        if (leadMatcher.find()) {
            return leadMatcher.group(0).trim();
        }
        String caseNumberPattern = '\\d+'; 
        Matcher caseMatcher = Pattern.compile(caseNumberPattern).matcher(subject);
        if (caseMatcher.find()) {
            return caseMatcher.group(0).trim();
        }
        
        return null;
    } 
    // Method to Log Email as an Activity on Lead and Return Task ID
    public static Id logEmailAsActivity(Id leadId, String subject, String body , String fromAddress, String toAddress, DateTime createdDate) {
        
        //String taskDescription = 'From:' + fromAddress + '\n' + 'Sent:' + createdDate.format('EEEE, MMMM d, yyyy h:mm a') + '\n'
        //  						+ 'To:' + toAddress + '\n' + 'Subject:' + subject + '\n\n' + body + '\n';
        
        String taskDescription =  'From:' + fromAddress + '<br/>' + 'Sent: ' + createdDate.format('EEEE, MMMM d, yyyy h:mm a') + '<br/>' + 'To:' + toAddress + '<br/>' +
            'Subject:' + subject + '<br/><br/>' +  body + '<br/><hr/><br/>';
        Task emailTask = new Task(
            WhoId = leadId,
            Subject = 'Email: ' + subject,
            Description = taskDescription, 
            ActivityDate = Date.today(),
            Status = 'Completed',
            Priority = 'Normal',
            TaskSubtype = 'Email'
        );
        
        insert emailTask;
        return emailTask.Id; // Return the Task ID
    }
    public static void updateBodyWithMailHistory(List<EmailMessage> newEmails) {
        Set<String> identifiers = new Set<String>();
        
        // Step 1: Extract identifiers from email subjects
        for (EmailMessage em : newEmails) {
            if (!em.Incoming) {
                String id = caseNumberOrLeadId(em.Subject);
                if (id != null) {
                    identifiers.add(id);
                }
            }
        }
        
        if (identifiers.isEmpty()) return;
        
        // Step 2: Map Case Numbers to Case Ids
        Map<String, Id> caseMap = new Map<String, Id>();
        for (Case c : [SELECT Id, CaseNumber FROM Case WHERE CaseNumber IN :identifiers]) {
            caseMap.put(c.CaseNumber, c.Id);
        }
        
        // Step 3: Map Leads by Id or their related Case__c
        Map<Id, Lead> leadMap = new Map<Id, Lead>();
        for (Lead l : [SELECT Id, Case__c, Email_History__c FROM Lead WHERE Id IN :identifiers OR Case__c IN :caseMap.values()]) {
            leadMap.put(l.Id, l);
        }
        
        // Step 4: Append Email History to email body if Lead is matched
        for (EmailMessage em : newEmails) {
            if (!em.Incoming) {
                String identifier = caseNumberOrLeadId(em.Subject);
                //if (identifier == null) continue;
                String idNormalized = (identifier.length() == 15) ? String.valueOf(Id.valueOf(identifier)) : identifier;
                
                Lead matchedLead;
                if (idNormalized.startsWith('00Q')) {
                    matchedLead = leadMap.get(idNormalized);
                } else{
                    // It's a CaseNumber
                    Id caseId = caseMap.get(idNormalized);
                    for (Lead l : leadMap.values()) {
                        if (l.Case__c == caseId) {
                            matchedLead = l;
                            break;
                        }
                    }
                }
                
                if (matchedLead != null) {
                    String existingBody = em.TextBody != null ? em.TextBody : '';
                    String history = getPreviousEmails(matchedLead.Id);//matchedLead.Email_History__c != null ? matchedLead.Email_History__c : '';
                    system.debug('history>>>>'+ history);
                    em.TextBody = existingBody + '\n\n--- Previous Email History ---\n\n' + history;
                }
            }
        }
    }
    
    
    public static String getPreviousEmails(String leadId) {
        List<Task> emailTasks = [SELECT Subject, Description, CreatedDate FROM Task 
                                 WHERE WhoId = :leadId AND TaskSubtype = 'Email' 
                                 ORDER BY CreatedDate DESC LIMIT 5];
        
        String emailHistory = '';
        for (Task emailTask : emailTasks) {
            emailHistory += '\n\n' + emailTask.Description + '\n\n';
        }
        return emailHistory;
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
    public static void handleAfterInsert(List<EmailMessage> newEmails) {
        Map<Id, EmailMessage> emailMap = new Map<Id, EmailMessage>();
        Set<Id> leadIds = new Set<Id>();
        Map<Id, Id> emailToLeadMap = new Map<Id, Id>();
        
        for (EmailMessage em : newEmails) {
            System.debug('em>>>>>'+ em);
            if (!em.Incoming && String.isNotBlank(em.Headers)){                
                String header = em.Headers;            
                Pattern pattern = Pattern.compile('\\b(00Q\\w{15})\\b');
                Matcher matcher = pattern.matcher(header);                
                if (matcher.find()) {
                    String leadId = matcher.group(1);
                    leadIds.add(leadId);
                    emailToLeadMap.put(em.Id, leadId);
                }
            }
        }
        
        if (leadIds.isEmpty()) return;
        
        List<ContentDocumentLink> leadLinks = [SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :leadIds ];
        
        Map<Id, List<ContentDocumentLink>> leadToLinks = new Map<Id, List<ContentDocumentLink>>();
        for (ContentDocumentLink cdl : leadLinks) {
            if (!leadToLinks.containsKey(cdl.LinkedEntityId)) {
                leadToLinks.put(cdl.LinkedEntityId, new List<ContentDocumentLink>());
            }
            leadToLinks.get(cdl.LinkedEntityId).add(cdl);
        }
        List<ContentDocumentLink> newLinks = new List<ContentDocumentLink>();
        
        for (EmailMessage em : newEmails) {
            Id leadId = emailToLeadMap.get(em.Id);
            if (leadToLinks.containsKey(leadId)) {
                for (ContentDocumentLink oldLink : leadToLinks.get(leadId)) {
                    newLinks.add(new ContentDocumentLink(
                        ContentDocumentId = oldLink.ContentDocumentId,
                        LinkedEntityId = em.Id,
                        ShareType = 'V',
                        Visibility = 'AllUsers'
                    ));
                }
            }
        }
        
        if (!newLinks.isEmpty()) {
            insert newLinks;
        }
    }
}