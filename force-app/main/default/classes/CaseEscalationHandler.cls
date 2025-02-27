public class CaseEscalationHandler {
    public static void handleCaseOwnerChange(List<Case> newCases, Map<Id, Case> oldCasesMap) {
        System.Debug('Test 1');
        Set<Id> ownerIds = new Set<Id>();
        for (Case c : newCases) {
            Case oldCase = oldCasesMap.get(c.Id); 
            if (c.OwnerId != oldCase.OwnerId && c.Status == 'New') {
                ownerIds.add(c.OwnerId);
            }
        }

        if (!ownerIds.isEmpty()) {
            Map<Id, String> ownerProfileMap = new Map<Id, String>();
            for (User u : [SELECT Id, Profile.Name FROM User WHERE Id IN :ownerIds]) {
                ownerProfileMap.put(u.Id, u.Profile.Name);
            }

            for (Case c : newCases) {
                Case oldCase = oldCasesMap.get(c.Id);
                if (c.OwnerId != oldCase.OwnerId && c.Status == 'New' &&
                    ownerProfileMap.containsKey(c.OwnerId) && ownerProfileMap.get(c.OwnerId) == 'Reservation') {
                    c.TAT_Start__c = System.now();
                }
            }
        }
    }
}