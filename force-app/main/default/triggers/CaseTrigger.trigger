trigger CaseTrigger on Case (before insert, before update, after insert, after update) {
 /** Edititng started by Sidhant 
     List<Case> casesToEscalate = new List<Case>();
    for (Case c : Trigger.new) {
        System.debug('Test 1 Sid'+ c.OwnerId + c.Status+ c.OwnerId.Profile.Name);
        if (c.OwnerId != null && c.Status == 'New' && c.Owner.Profile.Name == 'Reservation'){
       // if (c.OwnerId != null && c.Owner.Profile.Name == 'Reservation' && c.Status == 'New' && Trigger.oldMap.get(c.Id).OwnerId != c.OwnerId) {
            System.debug('Test 2 Sid');
            casesToEscalate.add(c);
        }
    } **/
    try {
        if (Trigger.isBefore) {
            CaseTriggerHandler.handleBeforeInsertOrUpdate(Trigger.new, Trigger.oldMap);
         // EDiting started by Sidhant
             /*if(trigger.isUpdate){
                CaseEscalationHandler.handleCaseOwnerChange(Trigger.new, Trigger.oldMap);
            }*/ // Editing ended by Sidhant
        }
        
        if (Trigger.isAfter ) {
            CaseTriggerHandler.handleAfterInsertOrUpdate(Trigger.newMap);
        /**    if(Trigger.isUpdate && !casesToEscalate.isEmpty()){
                CaseEscalationHandler.scheduleEscalation(casesToEscalate);
            }**/
        }
        
        if(Trigger.isAfter && Trigger.isInsert){
            CaseTriggerHandler.processCaseInsert(Trigger.new);
            
        }
    } catch (Exception e) {
        System.debug('Unexpected error in CaseTrigger: ' + e.getMessage());
    }
}