trigger LeadStatusTrigger on Lead (before update) {
    // Loop through all the records being updated
    for (Lead leadRecord : Trigger.new) {
        Lead oldLead = Trigger.oldMap.get(leadRecord.Id);
        
        // Check if the Lead Status is changing to 'Sales' and it wasn't already 'Sales'
        if (oldLead != null && leadRecord.Status == 'Sent to Sales' && oldLead.Status != 'Sent to Sales') {

            Group queue = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'Sales Team' LIMIT 1];
            system.debug('----queue-------'+queue);
            leadRecord.OwnerId = queue.Id;
            system.debug('------queue.Id-------->'+queue+'---- leadRecord.OwnerId----'+ leadRecord.OwnerId);
        }
    }
}