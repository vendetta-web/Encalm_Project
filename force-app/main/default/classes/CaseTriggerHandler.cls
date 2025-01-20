public class CaseTriggerHandler {
    public static void handleBeforeInsertOrUpdate(List<Case> newCases, Map<Id, Case> oldCases) {
        Group reservationQueue = [SELECT Id FROM Group WHERE DeveloperName = 'Reservation_Queue' LIMIT 1];
        for (Case caseRecord : newCases) {
            Case oldCase = oldCases != null ? oldCases.get(caseRecord.Id) : null;
            
            // Check if the Description or Subject is not blank
            if (String.isNotBlank(caseRecord.Description) || String.isNotBlank(caseRecord.Subject)) {
                String emailBody = caseRecord.Description;
                String emailSubject = caseRecord.Subject;
                
                // Only parse and set picklist values if manual fields are not set
                if (oldCase == null || 
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
            
            // Assign to Reservation Queue if criteria met
            if ((caseRecord.Origin == 'Email' || caseRecord.Origin == 'Web') && 
                caseRecord.Status == 'New' && 
                (oldCase == null || caseRecord.OwnerId == oldCase.OwnerId)) {
                    System.debug('Caserecord' + caseRecord.Origin);
                    System.debug('caseRecord.Status' + caseRecord.Status);
                    System.debug('oldCase.OwnerId' + oldCase.OwnerId);
                    caseRecord.OwnerId = reservationQueue.Id;
                    System.debug('caseRecord.OwnerId' + caseRecord.OwnerId);
                }
        }
    }
    
    public static void handleAfterInsertOrUpdate(Map<Id, Case> caseIdToCase) {
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
    }
}