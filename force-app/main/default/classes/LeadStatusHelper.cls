public class LeadStatusHelper {
    
    // Handle before update logic
    public static void handleBeforeUpdate(List<Lead> newLeads, Map<Id, Lead> oldLeadMap) {
        try {
            List<Group> reservationQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'Reservation Queue' LIMIT 1];
            Id queueId = reservationQueue.isEmpty() ? null : reservationQueue[0].Id;
            
            for (Lead newLead : newLeads) {
                System.debug('NEwLEead>>beforeUpdate>>1'+ newLead.Id);
                Lead oldLead = oldLeadMap.get(newLead.Id);
                
                if (oldLead != null && newLead.Status == 'Awaiting Customer response' && oldLead.Status != 'Awaiting Customer response') {
                    if (queueId != null) {
                        newLead.OwnerId = queueId;  
                    }
                }
                
                if (newLead.Case__c != null && newLead.LeadSource == null) {
                    Case caseRecord = [SELECT Origin FROM Case WHERE Id = :newLead.Case__c LIMIT 1];
                    if (caseRecord != null && caseRecord.Origin != null) {
                        
                        newLead.LeadSource = caseRecord.Origin;   // Set LeadSource based on Case Origin
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error occurred in handleBeforeUpdate method: ' + e.getMessage());
        }
    }
    
    // Handle before insert logic
    public static void handleBeforeInsert(List<Lead> newLeadList) {
        try {
            for (Lead leadRec : newLeadList) {
               System.debug('NEwLEead>>beforeUpdate>>2'+ leadRec);
                if (leadRec.Case__c != null && leadRec.LeadSource == null) {
                    // Query the related Case and set LeadSource based on Case's Origin field
                    Case caseRecord = [SELECT Origin FROM Case WHERE Id = :leadRec.Case__c LIMIT 1];
                    if (caseRecord != null && caseRecord.Origin != null) {
                        leadRec.LeadSource = caseRecord.Origin;  // Set LeadSource based on Case Origin
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error occurred in handleBeforeInsert method: ' + e.getMessage());
        }
    }
    public static void beforeUpdateLeadEscalation(List<Lead> newLeads, Map<Id, Lead> oldLeadsMap) { // Added by Sidhant
        for (Lead newLead : newLeads) {
            Lead oldLead = oldLeadsMap != null ? oldLeadsMap.get(newLead.Id) : null;
            if (oldLead == null) {
                if (isReservationProfile(newLead.OwnerId) && newLead.Status == 'Open') {
                    startTimer(newLead.Id, 2, 1);
                }
            } else {
                if (newLead.OwnerId != oldLead.OwnerId && isReservationProfile(newLead.OwnerId) && newLead.Status == 'Open') {
                    startTimer(newLead.Id, 2, 1); // First timer after 30 minutes
                }
                if ((oldLead.Status != 'Open' && newLead.Status == 'Open') && isReservationProfile(newLead.OwnerId)) {
                    System.debug('In beforeUpdate: Lead Status changed to Open and assigned to Reservation profile.');
                    startTimer(newLead.Id, 2, 1); // First timer after 30 minutes
                }
                
            }
        }
    }
    
    
    private static void startTimer(Id leadId, Integer minutes, Integer level) {  
        Lead ldList = [SELECT Id, Name, TAT_deadline__c, Escalation_Level__c FROM Lead Where Id = : leadId];
        
      ldList.TAT_deadline__c = System.now().addMinutes(30);
      ldList.Escalation_Level__c = 'Level 1';
        update ldList;
                
        Datetime futureTime = System.now().addMinutes(2);
        
        // Extract the components for the cron expression
        String cronExp = '0 ' + futureTime.minute() + ' ' + futureTime.hour() + ' ' + futureTime.day() + ' ' + (futureTime.month()) + ' ? ' + futureTime.year();
        System.debug('Scheduled time: ' + futureTime + ' with cron expression: ' + cronExp);
        LeadEscalationTimer scheduler = new LeadEscalationTimer(leadId, level);
        if(!Test.isRunningTest()){
            System.schedule('Lead Timer First Check' +leadId, cronExp, scheduler);
        }
    }
    
    private static Boolean isReservationProfile(Id ownerId) {
        if(String.valueOf(ownerId).startsWith('005')){
            User owner = [SELECT Profile.Name FROM User WHERE Id = :ownerId LIMIT 1];
            return owner.Profile.Name == 'Reservation'; // Adjust profile name if necessary
        }else{
            return false;
        }
        
    }
    
    // Handle before insert logic
    /* public static void handleAfterUpdateLeadLogic(List<Lead> newLeads, Map<Id, Lead> oldLeadsMap) { // Added by Saurabh
        Map<Lead,DateTime> mapLeadFollowDTtime = new Map<Lead,DateTime>();
        for (Lead newLead : newLeads) {
        System.debug('NEwLEead>>beforeUpdate>>3'+ newLead.Id);
            if(oldLeadsMap!= null  && oldLeadsMap.get(newLead.Id).Set_Follow_up_Date_and_Time__c != newLead.Set_Follow_up_Date_and_Time__c){
                 scheduleReplyCheck(newLead);
            }
        }
    }
  
    private static void scheduleReplyCheck(Lead leadRecd ) {
            if (leadRecd.Set_Follow_up_Date_and_Time__c > System.now()) {  // Only schedule if future time is valid
                String cronExp = '0 ' + leadRecd.Set_Follow_up_Date_and_Time__c.minute() + ' ' + leadRecd.Set_Follow_up_Date_and_Time__c.hour() + ' ' +leadRecd.Set_Follow_up_Date_and_Time__c.day() + ' ' +leadRecd.Set_Follow_up_Date_and_Time__c.month() + ' ? ' +leadRecd.Set_Follow_up_Date_and_Time__c.year();
                System.debug('ConExp'+cronExp);
                System.schedule('Track Replies Job ' + leadRecd.Id, cronExp, new TrackRepliesAndReassign(leadRecd));
            } else {
                System.debug('Follow-up time has already passed. No scheduling needed.');
            }
    
    } */
    

}