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
        public String Body; // Related record ID  //Saurabh
    }

    @InvocableMethod(label='Invoke Email Utility' description='Send Email')
    public static void sendEmail(List<FlowInputs> request) {
        try{
        System.debug('Request Parameters ---> ' + request);

        // Extract the first input from the list
        FlowInputs input = request[0];
            String orgWideEmail = System.Label.OrgWideEmailAddress;
        System.debug('36 '+bodyUpdated);
        // Prepare recipient email addresses
        List<String> toAddress = input.toAddresses?.split(',');
        if (toAddress == null) {
            toAddress = new List<String>();
        }
         //commented by saurabh 18March
            //toAddressList.add(System.Label.DefaultToAddress);
        
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
		System.debug('EmailTempBody'+emailTemp.Body);
        // Render email using the template
        Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(emailTemp.Id, null, input.recordId);
            
            Map<String, OrgWideEmailAddress> oweaMap = new Map<String, OrgWideEmailAddress>();

            for (OrgWideEmailAddress owea : [SELECT Id, Address FROM OrgWideEmailAddress WHERE Address = :orgWideEmail]) {

                oweaMap.put(owea.Address, owea);

            }

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
            mail.setReplyTo(String.isNotBlank(input.fromAddress) ? input.fromAddress : System.Label.DefaultReplyToAddress);
        }
		
        
       
        // Ensure email is logged as an activity
        //mail.setSaveAsActivity(true);
 
         // Validate recordId for WhatId
        String recordPrefix = input.recordId?.substring(0, 3);
        Boolean isValidWhatId = recordPrefix == '001' || recordPrefix == '003' || recordPrefix == '500' || recordPrefix == '00Q' || recordPrefix == '006'; // Account, Contact, Case, Lead, Opportunity 
       // Set SaveAsActivity based on the validity of recordId
        if (isValidWhatId) {
            mail.setSaveAsActivity(true);
            mail.setWhatId(input.recordId); 
        } else {
            mail.setSaveAsActivity(false);
        }

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
        catch (Exception e) {
            System.debug('Error occurred in sendEmail method: ' + e.getMessage());
        }        
    }
    // Custom Exception for better error handling
    public class EmailUtilityException extends Exception {}
}