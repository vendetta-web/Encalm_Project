public class LeadStatusHelper {
    public static void handleBeforeUpdate(List<Lead> newLeads, Map<Id, Lead> oldLeadMap) {
        // Query the queue once and reuse it
        Group queue = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'Sales Team' LIMIT 1];
        system.debug('----queue-------' + queue);

        // Loop through all the records being updated
        for (Lead newLead : newLeads) {
            Lead oldLead = oldLeadMap.get(newLead.Id);
            
            // Check if the Lead Status is changing to 'Sent to Sales' and it wasn't already 'Sent to Sales'
            if (oldLead != null && newLead.Status == 'Sent to Sales' && oldLead.Status != 'Sent to Sales') {
                newLead.OwnerId = queue.Id;
                system.debug('----Updated OwnerId to Sales Queue: ' + newLead.OwnerId);
            }
        }
    }
}