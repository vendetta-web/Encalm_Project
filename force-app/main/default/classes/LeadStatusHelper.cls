public class LeadStatusHelper {
    
    // Handle before update logic
    public static void handleBeforeUpdate(List<Lead> newLeads, Map<Id, Lead> oldLeadMap) {
        try {
            List<Group> queues = [SELECT Id,Name FROM Group WHERE Type = 'Queue' AND Name IN ('Reservation Queue', 'Sales Team')];
            //Id queueId = reservationQueue.isEmpty() ? null : reservationQueue[0].Id;
            
            Map<String, Id> queueNameToIdMap = new Map<String, Id>();
            for (Group g : queues) {
                queueNameToIdMap.put(g.Name, g.Id);
            }
            for (Lead newLead : newLeads) {
                System.debug('NEwLEead>>beforeUpdate>>1'+ newLead.Id);
                Lead oldLead = oldLeadMap.get(newLead.Id);
                
                if (oldLead != null && newLead.Status == 'Awaiting Customer response' && oldLead.Status != 'Awaiting Customer response' && newLead.Department__c != null) {
                    if (newLead.Department__c == 'Reservations' && queueNameToIdMap.containsKey('Reservation Queue')) {
                        newLead.OwnerId = queueNameToIdMap.get('Reservation Queue');
                    } else if (newLead.Department__c == 'Sales' && queueNameToIdMap.containsKey('Sales Team')) {
                        newLead.OwnerId = queueNameToIdMap.get('Sales Team');
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
        Id salesBHId;
        List<BusinessHours> bhList = [SELECT Id FROM BusinessHours WHERE Name = 'Sales Business Hours' LIMIT 1];
        if (!bhList.isEmpty()) {
            salesBHId = bhList[0].Id;
        }
        
        // Pre-fetch Record Types
        Map<Id, String> recordTypeIdToDevName = new Map<Id, String>();
        for (RecordType rt : [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Lead']) {
            recordTypeIdToDevName.put(rt.Id, rt.DeveloperName);
        }
        
        for (Lead newLead : newLeads) {
            Lead oldLead = oldLeadsMap != null ? oldLeadsMap.get(newLead.Id) : null;
            if (oldLead == null) {
                if (isTargettedProfile(newLead.OwnerId) && newLead.Status == 'Open') {
                    startTimer(newLead, 2, 1, recordTypeIdToDevName, salesBHId);
                }
            } else {
                if (newLead.OwnerId != oldLead.OwnerId && isTargettedProfile(newLead.OwnerId) && newLead.Status == 'Open') {
                    startTimer(newLead, 2, 1, recordTypeIdToDevName, salesBHId); // First timer after 30 minutes
                }
                if ((oldLead.Status != 'Open' && newLead.Status == 'Open') && isTargettedProfile(newLead.OwnerId)) {
                    startTimer(newLead, 2, 1, recordTypeIdToDevName, salesBHId); // First timer after 30 minutes
                }
                if (newLead.Status == 'Customer Responded' && isTargettedProfile(newLead.OwnerId) && recordTypeIdToDevName.get(newLead.RecordTypeId) != 'Sales') {
                    abortLeadEscationScheduledJob(newLead.Id);
                    startTimer(newLead, 2, 1, null, null);
                }
                if (newLead.Status == 'Awaiting Customer response' && recordTypeIdToDevName.get(newLead.RecordTypeId) == 'Sales') {
                    abortLeadEscationScheduledJob(newLead.Id);
                }              
            }
        }
    }
    //added by Abhishek
    private static void abortLeadEscationScheduledJob(string LeadId){
        String cronName = 'Lead Timer First Check' + leadId;
        String cronName2 = 'Lead Timer Second Check' + leadId;
        List<String> cronNameList = new List<String>{cronName,cronName2};
            system.debug('cronName>>>'+cronName);        
        List<CronTrigger> cronJobs = [SELECT Id, CronJobDetail.Name, State FROM CronTrigger WHERE CronJobDetail.Name IN :cronNameList AND State = 'WAITING' LIMIT 1];
        
        if (!cronJobs.isEmpty()) {
            System.abortJob(cronJobs[0].Id);
            System.debug('Aborted job: ' + cronJobs[0].CronJobDetail.Name);
        } else {
            System.debug('No scheduled job found for lead: ' + leadId);
        }
        
    }
    
    private static void startTimer(Lead lead, Integer minutes, Integer level, Map<Id, String> recordTypeMap, Id salesBHId) { 
        Datetime deadline = System.now().addMinutes(30); // Default
        
        if (lead.Status == 'Open' && recordTypeMap.containsKey(lead.RecordTypeId) && recordTypeMap.get(lead.RecordTypeId) == 'Sales' && salesBHId != null) 
        {
            deadline = BusinessHours.add(salesBHId, System.now(), 9 * 60 * 60 * 1000); // 9 business hours
        }
        
        lead.TAT_deadline__c = deadline; //System.now().addMinutes(30);
        lead.Escalation_Level__c = 'Level 1';
        Datetime futureTime = deadline; //System.now().addMinutes(30);
        
        // Extract the components for the cron expression
        String cronExp = '0 ' + futureTime.minute() + ' ' + futureTime.hour() + ' ' + futureTime.day() + ' ' + (futureTime.month()) + ' ? ' + futureTime.year();
        System.debug('Scheduled time: ' + futureTime + ' with cron expression: ' + cronExp);
        
        LeadEscalationTimer scheduler = new LeadEscalationTimer(lead.Id, level);
        if(!Test.isRunningTest()){
            System.schedule('Lead Timer First Check' +lead.Id, cronExp, scheduler);
        }
    }
    
    public static void updateEmailMessageRecords(List<Lead> leadList){
        Set<Id> caseId = new Set<Id>();
        Map<Id,Lead> caseToLeadMap = new Map<Id,Lead>();
        List<EmailMessage> updateEmailMessage = new List<EmailMessage>();
        for(Lead ld : leadList){
            caseId.add(ld.Case__c);
            caseToLeadMap.put(ld.Case__c,ld);
        }
        if(!caseId.IsEmpty()){
            List<EmailMessage> emailMessageRecords = [Select Id,LeadId__c,ParentId  From EmailMessage Where ParentId IN : caseId];
            for(EmailMessage em : emailMessageRecords){
                Id leadId = caseToLeadMap.get(em.ParentId).Id;
                if(leadId != null){
                    em.LeadId__c = leadId;
                    updateEmailMessage.add(em);
                }
            }}
        
        if(!updateEmailMessage.isEmpty()){
            update updateEmailMessage;
        }
    }
    
    private static Boolean isTargettedProfile(Id ownerId) {
        if(String.valueOf(ownerId).startsWith('005')){
            User owner = [SELECT Profile.Name FROM User WHERE Id = :ownerId LIMIT 1];
            return owner.Profile.Name == 'Reservation' || owner.Profile.Name == 'Sales'; // Adjust profile name if necessary
        }else{
            return false;
        }
        
    }
    
    private static Map<Id, String> getUserProfiles(Set<Id> userIds) {
        Map<Id, String> userProfileMap = new Map<Id, String>();
        for (User u : [SELECT Id, Profile.Name FROM User WHERE Id IN :userIds]) {
            userProfileMap.put(u.Id, u.Profile.Name);
        }
        return userProfileMap;
    }
    
    public static void updateOwnerChangedDate(List<Lead> newLeads, Map<Id, Lead> oldLeadMap) {
        Set<Id> newUserOwnerIds = new Set<Id>();
        
        for (Lead newLead : newLeads) {
            if (newLead.OwnerId != null && String.valueOf(newLead.OwnerId).startsWith('005')) {
                newUserOwnerIds.add(newLead.OwnerId);
            }
        }
        
        Map<Id, String> ownerProfileMap = getUserProfiles(newUserOwnerIds);
        
        for (Lead newLead : newLeads) {
            Lead oldLead = oldLeadMap.get(newLead.Id);
            
            if (newLead.OwnerId != oldLead.OwnerId) {
                //Boolean wasQueue = oldLead.OwnerId != null && String.valueOf(oldLead.OwnerId).startsWith('00G');
                Boolean isNowUser = newLead.OwnerId != null && String.valueOf(newLead.OwnerId).startsWith('005');
                String profileName = ownerProfileMap.get(newLead.OwnerId);
                if (isNowUser && profileName == 'Sales') {
                    newLead.Target_Closure_Date__c = System.now();
                }
            }
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