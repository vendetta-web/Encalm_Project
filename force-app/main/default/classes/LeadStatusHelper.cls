public class LeadStatusHelper {
    public static void handleBeforeUpdate(List<Lead> newLeads, Map<Id, Lead> oldLeadMap) {
        try{
            List<Group> reservationQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'Reservation Queue' LIMIT 1];
            Id queueId = reservationQueue.isEmpty() ? null : reservationQueue[0].Id;
            
            for (Lead newLead : newLeads) {
                Lead oldLead = oldLeadMap.get(newLead.Id);
                
                if (oldLead != null && newLead.Status == 'Awaiting Customer response' && oldLead.Status != 'Awaiting Customer response') {
                    if (queueId != null) {
                        newLead.OwnerId = queueId;
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error occurred in handleBeforeUpdate method: ' + e.getMessage());
        }
    }
    
    public static void handleBeforeInsert(List<Lead> newLeadList) {
        try {
            Map<Id, String> caseIdToOrigin = new Map<Id, String>();
            
            // Collect Case IDs and their Origins
            for (Lead leadRec : newLeadList) {
                if (leadRec.Case__c != null) {
                    caseIdToOrigin.put(leadRec.Case__c, leadRec.Case__r.Origin);
                }
            }
            
            // Update LeadSource directly on newLeadList
            if (!caseIdToOrigin.isEmpty()) {
                for (Lead leadRec : newLeadList) {
                    if (caseIdToOrigin.containsKey(leadRec.Case__c)) {
                        leadRec.LeadSource = caseIdToOrigin.get(leadRec.Case__c);
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error occurred in handleBeforeInsert method: ' + e.getMessage());
        }
    }
    
}