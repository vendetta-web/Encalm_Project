public class EmailMessageHandler {
    public static void processOutboundEmails(List<EmailMessage> emailMessages) {
        System.debug('Test 1');
        Set<Id> caseIdsToUpdate = new Set<Id>();
        for (EmailMessage email : emailMessages) {
            System.debug('Test 2');
            if (email.RelatedToId != null && email.RelatedToId.getSObjectType() == Case.SObjectType && email.Incoming == false && !email.Subject.contains('Case #')) {
                System.debug('Test 3');
                caseIdsToUpdate.add(email.RelatedToId);
            }
        }
        if (!caseIdsToUpdate.isEmpty()) {
            System.debug('Test 4');
            List<Case> casesToUpdate = [SELECT Id, Status FROM Case WHERE Id IN :caseIdsToUpdate];
            for (Case relatedCase : casesToUpdate) {
                System.debug('Test 5');
                if (relatedCase.Status != 'Awaiting Customer Response') {
                    relatedCase.Status = 'Awaiting Customer Response';
                }
            }
            update casesToUpdate;
        }
    }
}