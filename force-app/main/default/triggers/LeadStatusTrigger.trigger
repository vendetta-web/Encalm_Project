trigger LeadStatusTrigger on Lead (before update) {
    LeadStatusHelper.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
}