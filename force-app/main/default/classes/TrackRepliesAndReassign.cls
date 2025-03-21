public class TrackRepliesAndReassign implements Schedulable {
    private Lead leadRecd;
    
    // Constructor
    public TrackRepliesAndReassign(Lead leadRecd) {
        this.leadRecd = leadRecd;
    }
    
    // Execute method for handling the scheduled job
    public void execute(SchedulableContext context) {
        System.debug('Executing TrackRepliesAndReassign for Lead ID: ' + leadRecd);
        System.debug('Aakash------2>');
        
        try {
            // Fetch the lead record
            Lead lead = [SELECT Id, Status, OwnerId, CreatedById,LastModifiedDate, Set_Follow_up_Date_and_Time__c 
                         FROM Lead WHERE Id = :leadRecd.Id LIMIT 1];

            // Validate if Set_Follow_up_Date_and_Time__c is populated
            if (lead.Set_Follow_up_Date_and_Time__c == null) {
                System.debug('Skipping execution: Set_Follow_up_Date_and_Time__c is NULL.');
                return;
            }

            // Check if the follow-up time has passed and the lead is in 'Awaiting Customer response' status
            if (lead.Status == 'Awaiting Customer response') {

                System.debug('Checking for email replies after: ' + lead.Set_Follow_up_Date_and_Time__c);

                // Check if any email response exists
                Integer taskCount = [SELECT COUNT() 
                                     FROM Task 
                                     WHERE WhoId = :lead.Id 
                                     AND Subject LIKE '%Re: %'
                                     AND TaskSubtype = 'Email' 
                                     AND IsClosed = false 
                                     AND CreatedDate>=:lead.LastModifiedDate 
                                     AND CreatedDate<:lead.Set_Follow_up_Date_and_Time__c];

                if (taskCount == 0) { // No reply received
                    System.debug('No reply found. Updating Lead status to Open and reassigning owner.');
                    lead.Status = 'Open';

                    // Assign to creator or a default queue
                    Id defaultQueueId;
                    try {
                        defaultQueueId = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'Lead Queue' LIMIT 1].Id;
                    } catch (Exception e) {
                        System.debug('Error fetching Lead Queue: ' + e.getMessage());
                        defaultQueueId = null;
                    }

                    // Check if queue exists, else assign to creator
                    lead.OwnerId = (defaultQueueId != null) ? defaultQueueId : lead.CreatedById;

                    update lead;
                    System.debug('Lead updated successfully.');
                   
                    System.abortJob([SELECT Id FROM CronTrigger WHERE CronjobDetail.Name=:'Track Replies Job '+lead.Id].Id);
                   
                } else {
                    System.debug('Reply found. No changes needed.');
                }
            } else {
                System.debug('Skipping execution: Follow-up time not reached or Lead status is not Awaiting Customer response.');
            }
        } catch (DmlException dmlEx) {
            System.debug('DML Exception in TrackRepliesAndReassign: ' + dmlEx.getMessage());
        } 
    }
}