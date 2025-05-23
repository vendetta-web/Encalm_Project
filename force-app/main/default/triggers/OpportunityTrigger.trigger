trigger OpportunityTrigger on Opportunity (before insert, before update,after update) {
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
        if (Trigger.isAfter && trigger.isUpdate) {
            SurchargeWaiveoffHandler.isTriggerRunning = true;
            
            List<Opportunity> approvedOpps = new List<Opportunity>();
            for (Opportunity opp : Trigger.new) {
                Opportunity oldOpp = Trigger.oldMap.get(opp.Id);
                if (oldOpp.Surcharge_WaiveOff_Request__c != 'Approved' && opp.Surcharge_WaiveOff_Request__c == 'Approved') {
                    approvedOpps.add(opp);
                }
            }
            if (!approvedOpps.isEmpty()) {
                SurchargeWaiveoffHandler.createOpportunityLineItem(approvedOpps);
            }
            SurchargeWaiveoffHandler.isTriggerRunning = false;
        }
    }
    catch (Exception e) {
        System.debug('Unexpected error in OpportunityTrigger: ' + e.getMessage());
    }
}