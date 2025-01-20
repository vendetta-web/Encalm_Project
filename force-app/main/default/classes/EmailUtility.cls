public without sharing class EmailUtility {
	public static String bodyUpdated='';
    public class FlowInputs {    
        @InvocableVariable
        public String templateName; // Email template name
        @InvocableVariable
        public String toAddresses; // Comma-separated recipient addresses
        @InvocableVariable
        public String ccAddresses; // Comma-separated CC addresses
        @InvocableVariable
        public String bccAddresses; // Comma-separated BCC addresses
        @InvocableVariable
        public String fromAddress; // Reply-To address
        @InvocableVariable
        public String recordId; // Related record ID
         @InvocableVariable
        public String body; // Related record ID  //Saurabh
    }
     //Saurabh
   /* @future
    public static void updateEmailTemplate(String bodyVal,String templatename){
        EmailTemplate em=[Select Id,Body,Name,DeveloperName From EmailTemplate 
                          WHERE Name = :templateName or DeveloperName = :templateName LIMIT 1];
        em.Body=bodyVal;
        em.HtmlValue = bodyVal;
                System.debug('25 '+bodyUpdated);
        

        bodyUpdated=bodyVal;
        update em;
    } */

    @InvocableMethod(label='Invoke Email Utility' description='Send Email')
    public static void sendEmail(List<FlowInputs> request) {
        System.debug('Request Parameters ---> ' + request);

        // Extract the first input from the list
        FlowInputs input = request[0];
        System.debug('36 '+bodyUpdated);
        // Prepare recipient email addresses
        List<String> toAddress = input.toAddresses?.split(',');
        if (toAddress == null) {
            toAddress = new List<String>();
        }
        toAddress.add('supriya.bassi@maxify.digital'); // Ensure a default address is always added
        
        // Retrieve the email template
        EmailTemplate emailTemp;
        if (Test.isRunningTest()) {
            emailTemp = [SELECT Id, Subject, Body FROM EmailTemplate LIMIT 1];
        } else {
            emailTemp = [
                SELECT Id, Subject, Body 
                FROM EmailTemplate 
                WHERE Name = :input.templateName or DeveloperName = :input.templateName //Saurabh 
                LIMIT 1
            ];
        }
        if (emailTemp == null) {
            throw new EmailUtilityException('No email template found with the provided name: ' + input.templateName);
        }
		System.debug(emailTemp.Body);
        // Render email using the template
        Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(emailTemp.Id, null, input.recordId);

        // Set recipient addresses
        if (Test.isRunningTest()) {
            mail.setToAddresses(new List<String>{'test123xyz@test.com'});
        } else {
            mail.setToAddresses(toAddress);
        }

        // Set CC and BCC addresses
        if (String.isNotBlank(input.ccAddresses)) {
            mail.setCcAddresses(input.ccAddresses.split(','));
        }
        if (String.isNotBlank(input.bccAddresses)) {
            mail.setBccAddresses(input.bccAddresses.split(','));
        }

        // Set Reply-To address
        if (String.isNotBlank(input.fromAddress)) {
            mail.setReplyTo(input.fromAddress);
        } else {
            mail.setReplyTo('encalmreservation@gmail.com'); // Default Reply-To address
        }

        // Ensure email is logged as an activity
        mail.setSaveAsActivity(true);

        // Send the email
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>{mail};
        Messaging.SendEmailResult[] results = Messaging.sendEmail(emailList);

        // Log results for debugging
        for (Messaging.SendEmailResult result : results) {
            if (!result.isSuccess()) {
                throw new EmailUtilityException('Failed to send email: ' + result.getErrors()[0].getMessage());
            }
        }
        System.debug('Email sent successfully.');
        
    }

    // Custom Exception for better error handling
    public class EmailUtilityException extends Exception {}
}