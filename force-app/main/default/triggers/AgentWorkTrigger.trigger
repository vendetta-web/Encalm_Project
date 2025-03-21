trigger AgentWorkTrigger on AgentWork (after insert) {
    List<Case> casesToUpdate = new List<Case>();

    for (AgentWork aw : Trigger.new) {
        // Only act when the work item is assigned and opened
        System.debug('aw.Status ' + aw.Status);
        if (aw.Status == 'Assigned' && aw.WorkItemId != null) {
            // Fetch the related case
            Case c = [SELECT Id,TAT_Start__c,EntitlementId, Status FROM Case WHERE Id = :aw.WorkItemId LIMIT 1];

            if (c != null) {
                System.debug('Case assigned to agent via Omni-Channel: ' + c.Id);
                    c.TAT_Start__c = System.now();
                    c.EntitlementId =  System.Label.EntitlementId;
                casesToUpdate.add(c);
            }
        }
    }

    if (!casesToUpdate.isEmpty()) {
        update casesToUpdate;
        System.debug('Cases updated to start entitlement process');
    }
}