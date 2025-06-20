trigger CaseTrigger on Case (before insert, before update, after insert, after update) {
    try {
        if (Trigger.isBefore) {
            if(Trigger.isInsert){
                CaseTriggerHandler.handleBeforeInsert(trigger.new);
                CaseTriggerHandler.beforeUpdateAddEntitlementOnCase(Trigger.new, Trigger.oldMap); // By sidhant
            }
            if(trigger.isUpdate){
                CaseTriggerHandler.beforeUpdateAddEntitlementOnCase(Trigger.new, Trigger.oldMap); // By sidhant
                CaseTriggerHandler.handleStatusChange(Trigger.new, Trigger.oldMap); 
               // CaseTriggerHandler.handleBeforeUpdate(Trigger.oldMap, Trigger.new);
            } 
        }
        
        if (Trigger.isAfter ) {
            if(Trigger.isInsert){
                //CaseTriggerHandler.handleAfterInsert(Trigger.newMap);
                //CaseTriggerHandler.processCaseInsert(Trigger.new);
            }
            if(trigger.isUpdate){
                CaseTriggerHandler.afterUpdateReopenMilestone(Trigger.new, Trigger.oldMap);
                //CaseTriggerHandler.handlePostEscalationDML(Trigger.new, Trigger.oldMap); 
                
            }
            
        }
    } catch (Exception e) {
        System.debug('Unexpected error in CaseTrigger: ' + e.getMessage());
    }
}