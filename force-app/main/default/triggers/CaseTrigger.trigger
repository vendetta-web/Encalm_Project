trigger CaseTrigger on Case (before insert, before update, after insert, after update) {
    try {
        if (Trigger.isBefore) {
            // Iterate through all new and updated cases
            for (Case caseRecord : Trigger.new) {
                Case oldCase = Trigger.oldMap != null ? Trigger.oldMap.get(caseRecord.Id) : null;

                // Check if the Description or Subject is not blank
                if (String.isNotBlank(caseRecord.Description) || String.isNotBlank(caseRecord.Subject)) {
                    String emailBody = caseRecord.Description;
                    String emailSubject = caseRecord.Subject;

                    System.debug('Email Body: ' + emailBody);
                    System.debug('Email Subject: ' + emailSubject);

                    // Only parse and set picklist values if manual fields are not set
                    if (oldCase == null || 
                        (caseRecord.Priority == oldCase.Priority && 
                         (oldCase.Services__c == 'General Inquiry' && caseRecord.Services__c == 'General Inquiry'))) {
                        EmailParser.parseAndSetPicklistFromEmail(caseRecord, emailBody, emailSubject);

                        // Ensure Services is not reset if manually changed
                        if (String.isBlank(caseRecord.Services__c) || caseRecord.Services__c == 'General Inquiry') {
                            caseRecord.Services__c = 'General Inquiry';
                        }
                    } else {
                        System.debug('Manual values present, skipping keyword parsing');
                    }
                }

                // Assign case to Reservation_Queue if it meets criteria and OwnerId has not been manually set
            if ((caseRecord.Origin == 'Email' || caseRecord.Origin == 'Web') && 
                caseRecord.Status == 'New' && 
                (oldCase == null || caseRecord.OwnerId == oldCase.OwnerId)) {
                // Use Queue Developer Name for assigning to Queue
                caseRecord.OwnerId = [SELECT Id FROM Group WHERE DeveloperName = 'Reservation_Queue' LIMIT 1].Id;
            }
            }
        }
        
        if (Trigger.isAfter) {
            // Map to store Case Id to Origin field
            Map<Id, String> caseIdToOrigin = new Map<Id, String>();
            for (Case caseRec : Trigger.new) {
                caseIdToOrigin.put(caseRec.Id, caseRec.Origin);
            }

            if (!caseIdToOrigin.isEmpty()) {
                // L 
                List<Lead> leadListToUpdate = new List<Lead>();
                List<Lead> listOfLead = [SELECT Id, Case__c, LeadSource FROM Lead WHERE Case__c IN :caseIdToOrigin.keySet()];

                if (!listOfLead.isEmpty()) {
                    for (Lead leadRec : listOfLead) {
                        if (caseIdToOrigin.containsKey(leadRec.Case__c)) {
                            Lead leadUpdate = new Lead();
                            leadUpdate.Id = leadRec.Id;
                            leadUpdate.LeadSource = caseIdToOrigin.get(leadRec.Case__c);
                            leadListToUpdate.add(leadUpdate);
                        }
                    }

                    if (!leadListToUpdate.isEmpty()) {
                        System.debug('---leadListToUpdate---------------------' + leadListToUpdate);
                        update leadListToUpdate;
                    }
                }
            }
        }
    } catch (Exception e) {
        System.debug('Unexpected error in CaseTrigger: ' + e.getMessage());
    }
}