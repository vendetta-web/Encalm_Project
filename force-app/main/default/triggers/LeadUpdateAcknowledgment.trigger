trigger LeadUpdateAcknowledgment on Lead (after update) {
    // List to store emails
    List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

    // Iterate through the updated leads
    for (Lead updatedLead : Trigger.new) {
        // Send an email only if the lead has an email address
        if (!String.isBlank(updatedLead.Email)) {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] { updatedLead.Email });
            email.setSubject('Thank You for Updating Your Information');
            email.setPlainTextBody(
                'Hello ' + (updatedLead.FirstName != null ? updatedLead.FirstName : '') + ' ' +
                (updatedLead.LastName != null ? updatedLead.LastName : '') + ',\n\n' +
                'Thank you for updating your information. If you have any questions, feel free to reach out.\n\n' +
                'Best regards,\nEncalm Support'
            );

            emails.add(email);
        }
    }

    // Send emails if there are any
    if (!emails.isEmpty()) {
        Messaging.sendEmail(emails);
    }
}