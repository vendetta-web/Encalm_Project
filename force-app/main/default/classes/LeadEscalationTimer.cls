public class LeadEscalationTimer implements Schedulable {
    private Id leadId;
    private Integer level;
    
    // Constructor
    public LeadEscalationTimer(Id leadId, Integer level) {
        this.leadId = leadId;
        this.level = level;
    }
    
    // Execute method for handling the scheduled job
    public void execute(SchedulableContext context) {
        System.debug('Executing LeadEscalationTimer for Lead ID: ' + leadId + ' at level: ' + level);
        
        Lead lead = [SELECT Status, OwnerId, Name FROM Lead WHERE Id = :leadId LIMIT 1];
        
        System.debug('Lead Status: ' + lead.Status + ', Lead OwnerId: ' + lead.OwnerId);
        
        if (level == 1) {
            // First timer logic: after 30 minutes
            if (lead.Status != 'Lead Won') {
                System.debug('Lead status is not Closed. Escalating...');
                // Escalate and send email
                lead.Status = 'Escalated';
                update lead;
                escalateLead(lead);
                
                // Schedule the second timer (30 minutes later)
                LeadEscalationTimer scheduler = new LeadEscalationTimer(leadId, 2);
                Datetime futureTime = System.now().addMinutes(2);  // 30 minutes later
                String cronExp = '0 ' + futureTime.minute() + ' ' + futureTime.hour() + ' ' + futureTime.day() + ' ' + futureTime.month() + ' ? ' + futureTime.year();
                System.schedule('Lead Timer Second Check'+ lead.id, cronExp, scheduler);
                System.debug('Second timer scheduled for Lead ID: ' + leadId);
            } else {
                System.debug('Lead status is already Closed, no escalation required.');
            }
        } else if (level == 2) {
            // Second timer logic: after another 30 minutes
            if (!(lead.Status == 'Lead Won' || lead.Status == 'Lead Lost' || lead.Status == 'Awaiting Customer response')) {
                System.debug('Lead status is still not Closed after second timer. Final escalation...');
                // Final escalation logic
                escalateLeadToManagerOfManager(lead);
            } else {
                System.debug('Lead status is Closed after second timer, no further escalation required.');
            }
        }
        
        // After completing the current job (either level 1 or level 2), cancel the job
        cancelJob(context);
    }
    
    // Helper method to cancel the job after execution
    private void cancelJob(SchedulableContext context) {
        String jobId = context.getTriggerId();
        if (jobId != null) {
            System.abortJob(jobId);  // Aborts the current job after execution
            System.debug('Job ' + jobId + ' has been aborted after execution.');
        }
    }

    // Method to escalate the lead (e.g., send an email to the owner's manager)
    private void escalateLead(Lead lead) {
        System.debug('Escalating lead with ID: ' + lead.Id);
        
        // Logic to escalate the lead, e.g., sending email to the owner's manager
        User owner = [SELECT ManagerId FROM User WHERE Id = :lead.OwnerId LIMIT 1];
        String orgBaseUrl = System.URL.getOrgDomainUrl().toExternalForm(); // Get the org's base URL
            String leadLink = orgBaseUrl + '/lightning/r/Lead/' + lead.Id + '/view';
        if (owner.ManagerId != null) {
            User manager = [SELECT Email, Name FROM User WHERE Id = :owner.ManagerId LIMIT 1];
            String emailBody = 'Dear ' + (manager != null ? manager.Name : 'Manager') + ',\n\n' +
                   'This is to inform you that Lead ' + lead.Name + ' has been escalated due to no action taken by the assigned lead owner within the required timeframe.\n\n' +
                   'Please review and take the necessary action at the earliest.\n\n' +
                   'You can view the Lead record by clicking the following link:\n' +
                   leadLink;
            
            
            System.debug('Sending escalation email to manager: ' + manager.Email);
            
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] { manager.Email, '1supersidhant@gmail.com', 'gaurav.salve@maxify.digital'});
            mail.setSubject('Lead Escalation');
            mail.setPlainTextBody(emailBody);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        } else {
            System.debug('Owner does not have a manager assigned.');
        }
    }
    
    private void escalateLeadToManagerOfManager(Lead lead) {
    System.debug('Escalating lead to manager of manager for Lead ID: ' + lead.Id);
    User owner = [SELECT ManagerId FROM User WHERE Id = :lead.OwnerId LIMIT 1];
    if (owner.ManagerId != null) {
        User manager = [SELECT ManagerId, Name, Email FROM User WHERE Id = :owner.ManagerId LIMIT 1];
        if (manager.ManagerId != null) {
            User managerOfManager = [SELECT Name, Email FROM User WHERE Id = :manager.ManagerId LIMIT 1];
            
            String orgBaseUrl = System.URL.getOrgDomainUrl().toExternalForm(); // Get the org's base URL
            String leadLink = orgBaseUrl + '/lightning/r/Lead/' + lead.Id + '/view';
            
            String emailBody = 'Dear ' + managerOfManager.Name + ',\n\n' +
                               'This is to inform you that Lead ' + lead.Name + ' has been escalated due to no action taken by the assigned lead owner and his manager within the required timeframe.\n\n' +
                               'Please review and take the necessary action at the earliest.\n\n' +
                               'You can view the Lead record by clicking the following link:\n' +
                               leadLink;
            
            
            // Step 4: Send the escalation email
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] { managerOfManager.Email, '1supersidhant@gmail.com', 'gaurav.salve@maxify.digital' });
            mail.setSubject('Final Lead Escalation');
            mail.setPlainTextBody(emailBody);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        } else {
            System.debug('Manager does not have a manager assigned.');
        }
    } else {
        System.debug('Owner does not have a manager assigned.');
    }
}

}