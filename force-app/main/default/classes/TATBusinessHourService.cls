public with sharing class TATBusinessHourService {
    @AuraEnabled(cacheable=true)
    public static String getBusinessTimeRemaining(Id leadId) {
        try {
            Lead lead = [
                SELECT Id, TAT_deadline__c, Status, Escalation_Level__c, Owner.Profile.Name
                FROM Lead WHERE Id = :leadId LIMIT 1
            ];

            if (lead.TAT_deadline__c == null) {
                return 'NO_DEADLINE';
            }

            DateTime now = System.now();
            DateTime tatDeadline = lead.TAT_deadline__c;

            if (now >= tatDeadline) {
                return 'EXPIRED';
            }

            if (lead.Status == 'Open' && lead.Owner.Profile.Name == 'Sales') {
            BusinessHours bh = [SELECT Id FROM BusinessHours WHERE Name = 'Sales Business Hours' LIMIT 1];

            Boolean isWithin = BusinessHours.isWithin(bh.Id, now);

            // Calculate business hours remaining from now to deadline
            Long remaining = BusinessHours.diff(bh.Id, now, tatDeadline);

            if (remaining == null || remaining <= 0) {
                return 'EXPIRED';
            }

            if (!isWithin) {
                return 'PAUSED|' + String.valueOf(now.getTime() + remaining);
            }

            return 'RUNNING|' + String.valueOf(now.getTime() + remaining);
            }

            // fallback for other record types
            Long diffMs = tatDeadline.getTime() - now.getTime();
            return (diffMs <= 0) ? 'EXPIRED' : 'RUNNING|' + tatDeadline.getTime();
        } catch (Exception e) {
            return 'ERROR: ' + e.getMessage();
        }
    }
}