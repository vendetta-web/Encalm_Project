trigger LeadStatusTrigger on Lead (before update, before insert) {
    if (Trigger.isBefore) {
        if(Trigger.isUpdate){
            LeadStatusHelper.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
        }
        if(Trigger.isInsert){
            LeadStatusHelper.handleBeforeInsert(Trigger.new);
        }
    }
    
}