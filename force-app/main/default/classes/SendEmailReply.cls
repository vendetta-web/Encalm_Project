/**
* @File Name : sendemailReply .cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : October 23, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 23, 2024 |   | Initial Version
**/

 public with sharing class SendEmailReply implements Messaging.InboundEmailHandler {

    // This is the required method for the Messaging.InboundEmailHandler interface
    public Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {

        // Initialize the result object
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();

        // Extract sender's email address
        String fromEmailAddress = email.fromAddress;

        // Query the Lead object using the email address from the incoming email
        List<Lead> leadList = [SELECT Id FROM Lead WHERE Email = :fromEmailAddress LIMIT 1];

        System.debug('List of Leads :::::' + leadList);

        // Check if any lead was found
        if (!leadList.isEmpty()) {
            // Prepare task details based on the incoming email
            String replyText = email.plainTextBody;
            String taskSubject = email.subject;

            Task tkObj = new Task();
            tkObj.Description = replyText;
            tkObj.Priority = 'Medium';
            tkObj.ActivityDate = System.today();
            tkObj.ReminderDateTime = System.now();
            tkObj.Subject = taskSubject;  // Optional: Set task subject to email subject
            tkObj.WhoId = leadList[0].Id; // Associate the task with the Lead

            // Insert the task
            insert tkObj;
        } else {
            // Log if no matching Lead is found
            System.debug('No matching Lead found for email: ' + fromEmailAddress);
        }

        // Return the result
        return result;
    }
}