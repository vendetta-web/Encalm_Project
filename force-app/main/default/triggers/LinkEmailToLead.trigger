trigger LinkEmailToLead on EmailMessage (after insert) {
    System.debug('---------> my trigger');
    for (EmailMessage email : Trigger.New) {
        // Check if the email has a Thread Identifier (this is used for email threading)
        System.debug('email.ThreadIdentifier======>'+email.ThreadIdentifier);
        System.debug('email.FromAddress======>'+email.FromAddress);
        if (email.ThreadIdentifier != null) {
            // Find the corresponding Lead based on the Thread Identifier or Subject
            List<Lead> leads = [SELECT Id, Email FROM Lead WHERE Email = :email.FromAddress LIMIT 1];
            System.debug('----leads--------------->'+leads);
            // If a Lead is found, associate the email with that Lead
            if (!leads.isEmpty()) {
                Lead lead = leads[0];
                // Update the ParentId of the email to link it with the Lead
                email.RelatedToId  = lead.Id;  // Associate the Email with the Lead
                system.debug('email=============>'+email);
            }
        }
    }
}