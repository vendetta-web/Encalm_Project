public class SendEmailExample {
    public static void sendEmail() {
        // Create a new Email object
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
         Id templateId = [SELECT Id FROM EmailTemplate WHERE id = '00XQy000007qGawMAE' LIMIT 1].Id;
        system.debug('templateId ==>'+templateId);
        // Set the email properties
        mail.setToAddresses(new String[] {'kumar127pradeep@gmail.com'}); // Recipient's email address
        mail.setSubject('Subject of the lead '); // Subject of the email
        mail.setPlainTextBody('you lead is createing succfuevvecve'); // Email body (plain text)
        mail.setTemplateId(templateId);
        
         mail.setReplyTo('traveldetailsemailhandler@1-gjxhv6t7y39wht95klon5lxns5sg54qjw5rf9mutebrwcq2k5.qy-cmomoma3.swe42.apex.salesforce.com');
        
        // Optionally, you can add other features like CC, BCC, attachments, etc.
        // mail.setCcAddresses(new String[] {'cc@example.com'});
        // mail.setBccAddresses(new String[] {'bcc@example.com'});
        
        // Send the email
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}