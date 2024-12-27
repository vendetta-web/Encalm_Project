trigger CaseTrigger on Case (before insert, before update, after insert, after update) {
    try {
        if (Trigger.isBefore) {
            CaseTriggerHandler.handleBeforeInsertOrUpdate(Trigger.new, Trigger.oldMap);
        }

        if (Trigger.isAfter) {
            CaseTriggerHandler.handleAfterInsertOrUpdate(Trigger.newMap);
        }
    } catch (Exception e) {
        System.debug('Unexpected error in CaseTrigger: ' + e.getMessage());
    }
}