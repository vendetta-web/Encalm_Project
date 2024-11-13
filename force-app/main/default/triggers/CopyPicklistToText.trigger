trigger CopyPicklistToText on Lead (before insert, before update) {
    for (Lead lead : Trigger.new) {
        if (lead.Type__c != null) {
            lead.Company = lead.Type__c;
        }
    }
}