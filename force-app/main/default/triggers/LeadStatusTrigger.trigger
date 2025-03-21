trigger LeadStatusTrigger on Lead (before update, before insert, after insert,after update) {
    if (Trigger.isBefore) {
        if (Trigger.isUpdate) {
            LeadStatusHelper.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
            LeadStatusHelper.beforeUpdateLeadEscalation(Trigger.new, Trigger.oldMap); // Sidhant
        }
        if (Trigger.isInsert) {
           LeadStatusHelper.handleBeforeInsert(Trigger.new);
           // LeadStatusHelper.beforeUpdateLeadEscalation(Trigger.new, Trigger.oldMap); // Sidhant
        }
    }
    if(trigger.isAfter){
        if (Trigger.isInsert) {
            LeadStatusHelper.beforeUpdateLeadEscalation(Trigger.new, Trigger.oldMap); // Sidhant
        }
        if(Trigger.isUpdate){
            //LeadStatusHelper.handleAfterUpdateLeadLogic(Trigger.new, Trigger.oldMap); //Saurabh
        }
    }
}