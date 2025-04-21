// Updated by Sidhant to check owner's profile and case status

trigger AgentWorkTrigger on AgentWork (after insert) {
    List<Case> casesToUpdate = new List<Case>();

    for (AgentWork aw : Trigger.new) {
        // Only act when the work item is assigned and opened
        System.debug('aw.Status ' + aw.Status);
        if (aw.Status == 'Assigned' && aw.WorkItemId != null && Schema.Case.SObjectType == aw.WorkItemId.getSobjectType()) {
            Case c = [SELECT Id, TAT_Start__c, EntitlementId, Status, OwnerId FROM Case WHERE Id = :aw.WorkItemId LIMIT 1];

            if (c != null) {
                System.debug('Case assigned to agent via Omni-Channel: ' + c.Id);

                User caseOwner = [SELECT Profile.Name FROM User WHERE Id = :c.OwnerId LIMIT 1];
                if (caseOwner.Profile.Name == 'Reservation' && c.Status == 'New') {
                    c.TAT_Start__c = System.now();
                    c.EntitlementId = System.Label.EntitlementId;
                    casesToUpdate.add(c);
                    System.debug('Case eligible for update and added to the list.');
                } else {
                    System.debug('Case owner profile is not "Reservation" or case status is not "New".');
                }
            }
        }
    }

    if (!casesToUpdate.isEmpty()) {
        update casesToUpdate;
        System.debug('Cases updated to start entitlement process');
    } else {
        System.debug('No cases updated.');
    }
}