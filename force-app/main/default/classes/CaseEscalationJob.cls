// Updated by Abhishek :- Not used anywhere, confirmed from Sidhant. April 15 2025

public class CaseEscalationJob implements Schedulable {

    private List<Case> casesToEscalate;

    // Constructor to pass the cases to the job
    public CaseEscalationJob(List<Case> cases) {
        this.casesToEscalate = cases;
    }

    // Execute method for scheduled job
    public void execute(SchedulableContext context) {
        List<Case> casesToUpdate = new List<Case>();

        for (Case c : casesToEscalate) {
            // Re-fetch the case to check its updated status after 2 minutes
            Case updatedCase = [SELECT Id, Status, OwnerId FROM Case WHERE Id = :c.Id LIMIT 1];

            if (updatedCase.Status == 'New') {
                // If the status is still 'New', update the status to 'Escalated'
                updatedCase.Status = 'Escalated';
                casesToUpdate.add(updatedCase);

                // Send an email to the Associate's manager
                sendEscalationEmail(updatedCase.OwnerId);
            }
        }

        // Update the case status to 'Escalated'
        if (!casesToUpdate.isEmpty()) {
            update casesToUpdate;
        }

        // Send second escalation email to the manager's manager after another 2 minutes
        sendSecondEscalationEmail();
    }

    // Helper method to send email to Associate's Manager
    public static void sendEscalationEmail(Id ownerId) {
        // Query the Owner's manager
        User owner = [SELECT Id, Manager.Email FROM User WHERE Id = :ownerId LIMIT 1];

        // Send email to the Manager
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setSubject('Case Escalation Notification');
      //  mail.setToAddresses(new String[]{owner.Manager.Email});
      mail.setToAddresses(new String[]{'1supersidhant@gmail.com'});
        mail.setPlainTextBody('The case has been escalated because the status was not updated within 2 minutes.');

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }

    // Helper method to send a second email to the manager's manager after another delay
    public static void sendSecondEscalationEmail() {
        // Logic to send email to manager's manager (similar to the first email)
        // You can implement a similar process for sending the email to the manager's manager
    }
}