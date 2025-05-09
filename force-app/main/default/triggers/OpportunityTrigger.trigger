trigger OpportunityTrigger on Opportunity (before insert, before update) {
    try {
        if (Trigger.isBefore) {
            if(Trigger.isInsert){
                OpportunityTriggerHanlder.updateServiceDateTimeFields(trigger.new);
            }
            else if(trigger.isUpdate){
                List<Opportunity> changedOpps = new List<Opportunity>();
                for (Integer i = 0; i < Trigger.new.size(); i++) {
                    Opportunity oldOpp = Trigger.old[i];
                    Opportunity newOpp = Trigger.new[i];
                    
                    if (
                        oldOpp.STA_Time__c != newOpp.STA_Time__c ||
                        oldOpp.STd_Time__c != newOpp.STd_Time__c ||
                        oldOpp.Date_of_Arrival__c != newOpp.Date_of_Arrival__c ||
                        oldOpp.Date_of_Departure__c != newOpp.Date_of_Departure__c ||
                        oldOpp.Flight_Type__c != newOpp.Flight_Type__c
                    ) {
                        changedOpps.add(newOpp);
                    }
                }
                
                if (!changedOpps.isEmpty()) {
                    OpportunityTriggerHanlder.updateServiceDateTimeFields(changedOpps);
                }  
            }
        }
    }
    catch (Exception e) {
        System.debug('Unexpected error in OpportunityTrigger: ' + e.getMessage());
    }
}