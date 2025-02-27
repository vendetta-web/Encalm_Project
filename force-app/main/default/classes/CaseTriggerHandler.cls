public class CaseTriggerHandler {
    public static void handleBeforeInsertOrUpdate(List<Case> newCases, Map<Id, Case> oldCases) {
        try {
            //Group reservationQueue = [SELECT Id FROM Group WHERE DeveloperName = 'Reservation_Queue' LIMIT 1];
            Group customerSupportWorkflowQueue = [SELECT Id FROM Group WHERE DeveloperName = 'Customer_Support_Workflow' LIMIT 1];
            
            // Fetch Queue IDs for Inquiry Types
            Map<String, Id> queueMap = new Map<String, Id>();
            for (Group g : [SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN ('Feedback', 'Query') AND Type = 'Queue']) {
                queueMap.put(g.DeveloperName, g.Id);
            }
            
            for (Case caseRecord : newCases) {
                Case oldCase = oldCases != null ? oldCases.get(caseRecord.Id) : null;
                
                // Check if the Description or Subject is not blank
                if (String.isNotBlank(caseRecord.Description) || String.isNotBlank(caseRecord.Subject)) {
                    String emailBody = caseRecord.Description;
                    String emailSubject = caseRecord.Subject;
                    
                    // Only parse and set picklist values if manual fields are not set
                    if (oldCase == null || 
                        (caseRecord.Priority == null || caseRecord.Priority == 'Low') && 
                        (caseRecord.Priority == oldCase.Priority 
                         && 
                         (String.isBlank(oldCase.Services__c) || oldCase.Services__c == caseRecord.Services__c) 
                         &&
                         (String.isBlank(oldCase.Location__c) || oldCase.Location__c == caseRecord.Location__c)
                        )) {
                            EmailParser.parseAndSetPicklistFromEmail(caseRecord, emailBody, emailSubject);
                            
                            // Remove logic setting 'Choose option(s)' or any default value
                            if (String.isBlank(caseRecord.Services__c)) {
                                caseRecord.Services__c = ''; 
                            }
                            
                            // Explicitly set to blank if no location is found
                            if (String.isBlank(caseRecord.Location__c)) {
                                caseRecord.Location__c = ''; 
                            }
                        }
                }
                
                // Assign to Customer Support Workflow Queue if criteria met
                if ((caseRecord.Origin == 'Email' || caseRecord.Origin == 'Web') && 
                    caseRecord.Status == 'New' && 
                    (oldCase == null || caseRecord.OwnerId == oldCase.OwnerId)) {
                        //caseRecord.OwnerId = reservationQueue.Id;
                         caseRecord.OwnerId = customerSupportWorkflowQueue.Id;
                    }
                
                // Reassign Closed Booking Cases to Reservation Queue
                /*if (caseRecord.Status == 'Closed' && 
                    oldCase != null && oldCase.Status != 'Closed' && 
                    caseRecord.Inquiry_Type__c == 'Booking') {
                        System.debug('Reassigning closed booking case to Reservation Queue.');
                        caseRecord.OwnerId = reservationQueue.Id;
                    } 
                else if (caseRecord.Inquiry_Type__c != null && queueMap.containsKey(caseRecord.Inquiry_Type__c)) {
                    caseRecord.OwnerId = queueMap.get(caseRecord.Inquiry_Type__c);
                }*/
            }
        } catch (Exception e) {
            System.debug('Error occurred in handleBeforeInsertOrUpdate method: ' + e.getMessage());
            LogErrorUtil.logError(e, 'CaseTriggerHandler', 'handleBeforeInsertOrUpdate');            
        }
    }
    
    public static void handleAfterInsertOrUpdate(Map<Id, Case> caseIdToCase) {
        try {
            if (caseIdToCase.isEmpty()) return;
            
            Map<Id, String> caseIdToOrigin = new Map<Id, String>();
            for (Case caseRec : caseIdToCase.values()) {
                caseIdToOrigin.put(caseRec.Id, caseRec.Origin);
            }
            
            if (!caseIdToOrigin.isEmpty()) {
                List<Lead> leadListToUpdate = new List<Lead>();
                List<Lead> listOfLead = [SELECT Id, Case__c, LeadSource FROM Lead WHERE Case__c IN :caseIdToOrigin.keySet()];
                
                for (Lead leadRec : listOfLead) {
                    if (caseIdToOrigin.containsKey(leadRec.Case__c)) {
                        Lead leadUpdate = new Lead();
                        leadUpdate.Id = leadRec.Id;
                        leadUpdate.LeadSource = caseIdToOrigin.get(leadRec.Case__c);
                        leadListToUpdate.add(leadUpdate);
                    }
                }
                
                if (!leadListToUpdate.isEmpty()) {
                    update leadListToUpdate;
                }
            }
        } catch (Exception e) {
            System.debug('Error occurred in handleAfterInsertOrUpdate method: ' + e.getMessage());
            LogErrorUtil.logError(e, 'CaseTriggerHandler', 'handleAfterInsertOrUpdate'); 
        }
    }
    
    // Method to send and process service emails
    public static void processCaseInsert(List<Case> newCases) {
        try{
            if (newCases.isEmpty()) return;  // Avoid unnecessary execution
            
            // Collect selected services from cases
            Set<String> selectedServices = new Set<String>();
            
            for (Case c : newCases) {
                if (String.isNotBlank(c.Services__c)) { 
                    selectedServices.addAll(c.Services__c.split(';')); // Handle multi-select picklist
                }
            }
            
            // Send emails if services are selected
            if (!selectedServices.isEmpty()) {
                System.debug('Sending emails for selected services: ' + selectedServices);
                sendServiceEmails(new List<String>(selectedServices));
            }
        } catch (Exception e) {
            LogErrorUtil.logError(e, 'CaseTriggerHandler', 'processCaseInsert'); 
        }
    }
    
    public static void sendServiceEmails(List<String> selectedServices) {
        System.debug('#### sendServiceEmails Method Called ####');
        System.debug('Selected Services: ' + selectedServices);
        try{
            
            if (selectedServices.isEmpty()) {
                System.debug('No services selected. Throwing exception.');
                throw new AuraHandledException('No services selected.');
            }
            
            // Fetch custom metadata records where Type = 'Service'
            System.debug('Fetching metadata records from Keyword__mdt for selected services...');
            List<Keyword__mdt> serviceMetadata = [
                SELECT MasterLabel, Service_Email__c 
                FROM Keyword__mdt 
                WHERE Type__c = 'Service' 
                AND MasterLabel IN :selectedServices
            ];
            System.debug('Fetched metadata records count: ' + serviceMetadata.size());
            
            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
            
            for (Keyword__mdt service : serviceMetadata) {
                System.debug('Processing service: ' + service.MasterLabel);
                
                if (String.isNotBlank(service.Service_Email__c)) {
                    System.debug('Found valid email for service: ' + service.MasterLabel + ' | Email: ' + service.Service_Email__c);
                    
                    // Construct email
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    
                    // Set recipient
                    List<String> recipients = new List<String>{service.Service_Email__c};
                        email.setToAddresses(recipients);
                    System.debug('Email To Addresses: ' + recipients);
                    
                    // Set subject
                    String emailSubject = 'Notification for ' + service.MasterLabel;
                    email.setSubject(emailSubject);
                    System.debug('Email Subject: ' + emailSubject);
                    
                    // Set body
                    String emailBody = 'Hello,\n\nThis is an automated email for ' + service.MasterLabel + '.\n\nThank you!';
                    email.setPlainTextBody(emailBody);
                    System.debug('Email Body: ' + emailBody);
                    
                    emails.add(email);
                    System.debug('Email added to list for: ' + service.MasterLabel);
                } else {
                    System.debug('No valid email found for service: ' + service.MasterLabel);
                }
            }
            
            // Send emails
            System.debug('===emails================>'+emails);
            if (!emails.isEmpty()) {
                System.debug('Preparing to send ' + emails.size() + ' emails...');
                Messaging.sendEmail(emails);
                System.debug('Emails sent successfully.');
            } } 
        catch (Exception e) {
            LogErrorUtil.logError(e, 'CaseTriggerHandler', 'sendServiceEmails'); 
        }
    }
}