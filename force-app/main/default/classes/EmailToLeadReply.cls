global class EmailToLeadReply implements Messaging.InboundEmailHandler {

    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        
        try {
            // Debug the email body
            System.debug('Email Body: ' + email.plainTextBody);

            // Check if the email body contains the keyword 'Dear '
            if (email.plainTextBody != null && email.plainTextBody.contains('Dear ')) {
                // Extract the lead name from the email body
                String leadName = email.plainTextBody.split('Dear ')[1].split(',')[0];
                System.debug('Lead Name: ' + leadName);

                // Query the most recently modified lead with the extracted name
                List<Lead> leads = [SELECT Id FROM Lead WHERE Name = :leadName ORDER BY LastModifiedDate DESC LIMIT 1];

                if (!leads.isEmpty()) {
                    // Create a new task associated with the lead
                    Task newTask = new Task(
                        WhoId = leads[0].Id,
                        Subject = email.subject,
                        TaskSubtype = 'Email',
                        Description = email.plainTextBody
                    );

                    // Insert the new task
                    insert newTask;
                    System.debug('Task created successfully: ' + newTask.Id);
                } else {
                    System.debug('No lead found with the name: ' + leadName);
                    result.success = false;
                    result.message = 'No lead found with the name: ' + leadName;
                    return result;
                }
            } else {
                System.debug('Email body does not contain the keyword "Dear "');
                result.success = false;
                result.message = 'Email body does not contain the keyword "Dear "';
                return result;
            }

            // Set the result to success
            result.success = true;
        } catch (Exception e) {
            // Log the exception and set the result to failure
            System.debug('An error occurred: ' + e.getMessage());
            result.success = false;
            result.message = 'An error occurred: ' + e.getMessage();
        }

        return result;
    }
}