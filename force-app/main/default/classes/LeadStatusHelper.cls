public class LeadStatusHelper {
    public static void handleBeforeUpdate(List<Lead> newLeads, Map<Id, Lead> oldLeadMap) {
        // Query the Reservation Queue once and reuse it
        Group reservationQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'Reservation Queue' LIMIT 1];
        System.debug('----Reservation Queue ID: ' + reservationQueue.Id);
        
          // Query the Customer Support Workflow Queue once and reuse it
         //Group customerSupportWorkflowQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'Customer Support Workflow' LIMIT 1];
        //System.debug('----Customer Support Workflow Queue ID: ' + customerSupportWorkflowQueue.Id);

        // Loop through all the records being updated
        for (Lead newLead : newLeads) {
            Lead oldLead = oldLeadMap.get(newLead.Id);

            // Check if the Lead Status is changing to 'Follow-Up Complete' and it wasn't already 'Follow-Up Complete'
            if (oldLead != null && newLead.Status == 'Awaiting Customer response' && oldLead.Status != 'Awaiting Customer response') {
                newLead.OwnerId = reservationQueue.Id;
                //newLead.OwnerId = customerSupportWorkflowQueue.Id;
                System.debug('----Updated OwnerId to Customer Support Workflow Queue: ' + newLead.OwnerId);
            }
        }
    }
}