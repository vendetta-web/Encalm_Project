public class CaseTriggerHandler {
    public static void handleBeforeInsert(List<Case> newCases) {
        try {
            
            for (Case caseRecord : newCases) {               
                
                if (caseRecord.Origin == 'Email') {
                    EmailParser.parseAndSetPicklistFromEmail(caseRecord, caseRecord.Description, caseRecord.Subject);
                }
                
            }
        } catch (Exception e) {
            System.debug('Error occurred in handleBeforeInsertOrUpdate method: ' + e.getMessage());
        }
    }
    
    //Timestamp 
    public static void handleStatusChange(List<Case> newCases, Map<Id, Case> oldMap) {
        DateTime nowTime = System.now();
        
        for (Case c : newCases) {
            Case oldCase = oldMap.get(c.Id);
            
            if (c.Status != oldCase.Status) {
                // Set new status change time
                c.TAT_Start__c	 = nowTime;
                
                // Calculate TAT in hours if old timestamp exists
                if (oldCase.TAT_Start__c!= null) {
                    //Decimal tatInHours = (nowTime.getTime() - oldCase.TAT_Start__c.getTime()) / (1000 * 60 * 60);
                    //c.TAT_Hours__c = tatInHours.setScale(2);
                    Decimal tatInMinutes = (nowTime.getTime() - oldCase.TAT_Start__c.getTime()) / (1000 * 60);
                    c.TAT_Hours__c = tatInMinutes.setScale(2); 
                    
                } else {
                    c.TAT_Hours__c = 0;
                }
            }
        }
    }
    
    public static void beforeUpdateAddEntitlementOnCase(List<Case> newCases, Map<Id, Case> oldCasesMap) { // Added by Sidhant
        Set<Id> ownerIds = new Set<Id>();
        for (Case c : newCases) {
            system.debug('Testtttt');
            if (oldCasesMap != null && oldCasesMap.containsKey(c.Id)) {
                Case oldCase = oldCasesMap.get(c.Id); 
                if (c.OwnerId != oldCase.OwnerId && c.Status == 'New') {
                    system.debug('Testtttt');
                    ownerIds.add(c.OwnerId);
                }
            }
            else if (c.Status == 'New') {
                ownerIds.add(c.OwnerId);
                system.debug('Testtttt elseee');
            }
        }
        
        if (!ownerIds.isEmpty()) {
            Map<Id, String> ownerProfileMap = new Map<Id, String>();
            for (User u : [SELECT Id, Profile.Name FROM User WHERE Id IN :ownerIds]) {
                ownerProfileMap.put(u.Id, u.Profile.Name);
            }
            
            for (Case c : newCases) {
                // Case oldCase = oldCasesMap.get(c.Id);
                if (ownerProfileMap.containsKey(c.OwnerId) && ownerProfileMap.get(c.OwnerId) == 'Reservation') {
                    c.TAT_Start__c = System.now();
                    c.EntitlementId =  System.Label.EntitlementId;
                }
            }
        }
    }
    public static void afterUpdateReopenMilestone(List<Case> newCases, Map<Id, Case> oldCasesMap) { 
        Set<Id> ownerIds = new Set<Id>();
        Set<Id> caseIds = new Set<Id>(); 
        for (Case c : newCases) {
            Case oldCase = oldCasesMap.get(c.Id); 
            if ((c.Status != oldCase.Status && c.Status == 'New' || c.Status != oldCase.Status && c.Status == 'Customer Responded')) {
                ownerIds.add(c.OwnerId);
                caseIds.add(c.Id); // Add case ID for milestone query
            }
        }
        
        if (!ownerIds.isEmpty()) {
            // Query users and their profiles to check if they are 'Reservation' users
            Map<Id, String> ownerProfileMap = new Map<Id, String>();
            for (User u : [SELECT Id, Profile.Name FROM User WHERE Id IN :ownerIds]) {
                ownerProfileMap.put(u.Id, u.Profile.Name);
            }
            // Query all CaseMilestone records related to the cases whose status changed to 'New'
            List<CaseMilestone> milestonesToUpdate = [SELECT Id, CaseId, IsCompleted FROM CaseMilestone WHERE CaseId IN :caseIds AND IsCompleted = true];
            System.debug('Test 3'+ milestonesToUpdate);
            Map<Id, List<CaseMilestone>> caseMilestoneMap = new Map<Id, List<CaseMilestone>>();
            for (CaseMilestone cm : milestonesToUpdate) {
                if (!caseMilestoneMap.containsKey(cm.CaseId)) {
                    caseMilestoneMap.put(cm.CaseId, new List<CaseMilestone>());
                }
                caseMilestoneMap.get(cm.CaseId).add(cm);
            }
            // Loop through each case and reopen milestones if needed
            List<CaseMilestone> milestoneToUpdate = new List<CaseMilestone>();
            for (Case c : newCases) {
                if (ownerProfileMap.containsKey(c.OwnerId) && ownerProfileMap.get(c.OwnerId) == 'Reservation' && caseMilestoneMap.containsKey(c.Id)) {
                    milestoneToUpdate = caseMilestoneMap.get(c.Id);
                    milestoneToUpdate[0].StartDate = System.now();
                    milestoneToUpdate[0].CompletionDate = null;
                }
            }
            
            // Update the CaseMilestones to reflect the changes
            if (!milestoneToUpdate.isEmpty()) {
                update milestoneToUpdate;
            }
        }
    }
    @AuraEnabled(cacheable=true) // Added by Sidhant to show pre populate the fields while creating Lead(Booking)
    public static Case getCaseFields(Id caseId) {
        System.debug('CaseId '+ caseId);
        try {
            Case caseRecord = [SELECT Subject, Description, SuppliedPhone, SuppliedEmail, SuppliedName, caseNumber, origin FROM Case WHERE Id = :caseId LIMIT 1];
            System.debug('--------------------origin--------->'+caseRecord.origin);
            return caseRecord;
        } catch (Exception e) {
            System.debug('Error fetching case fields: ' + e.getMessage());
            return null;
        }
    }
    public static void handlePostEscalationDML(List<Case> newCases, Map<Id, Case> oldCasesMap) {
        List<Case> casesToUpdate = new List<Case>();
        
        for (Case c : newCases) {
            Case oldCase = oldCasesMap.get(c.Id);
            
            if (oldCase != null && c.Status == 'Escalated') {
                // DML-safe dummy update
                c.Description = c.Description;
                casesToUpdate.add(c);
            }
        }
        
        if (!casesToUpdate.isEmpty()) {
            update casesToUpdate;
        }
    }
    
    public static void handleBeforeUpdate(Map<Id, Case> oldMap, List<Case> newList) {
        Set<Id> newOwnerIds = new Set<Id>();

        for (Case cs : newList) {
            Case oldCase = oldMap.get(cs.Id);
            if (cs.OwnerId != oldCase.OwnerId) {
                system.debug('cs.OwnerId>>>'+cs.OwnerId);
                newOwnerIds.add(cs.OwnerId);
            }
        }

        Map<Id, Boolean> eligibilityMap = new Map<Id, Boolean>();
        for (Id userId : newOwnerIds) {
            eligibilityMap.put(userId, OmniChannelAssignmentEnforcer.isAgentEligibleCase(userId));
        }

        for (Case cs : newList) {
            system.debug('cs>>>'+cs);
            Case oldCase = oldMap.get(cs.Id);
            if (cs.OwnerId != oldCase.OwnerId && !eligibilityMap.get(cs.OwnerId)) {
                cs.OwnerId = oldCase.OwnerId;
                cs.addError('Agent already has 10 open Cases. Assignment not allowed.');
            }
        }
    }
       
    
}