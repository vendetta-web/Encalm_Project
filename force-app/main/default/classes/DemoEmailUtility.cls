/**
* @File Name : DemoEmailUtility.cls
* @Description :
* @Author :
* @Last Modified By : ChangeMeIn@UserSettingsUnder.SFDoc
* @Last Modified On : 02-24-2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | January 29, 2025 |   | Initial Version
**/

public class DemoEmailUtility {
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
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        //   Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(emailTemp.Id, null, input.recordId);
        
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
        // if (String.isNotBlank(input.fromAddress)) {
        //     mail.setReplyTo(input.fromAddress);
        // } else {
        //     mail.setReplyTo('encalmreservation@gmail.com'); // Default Reply-To address
        // }
        
        OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'supriya.bassi@maxify.digital'];
        System.debug('owea -> ' + owea);
        if ( owea.size() > 0 ) {
            mail.setOrgWideEmailAddressId(owea.get(0).Id);
        }
        System.debug(input.Body);
        mail.setHtmlBody(input.Body);
        // Ensure email is logged as an activity
        //mail.setSaveAsActivity(true);
        
        // Set Reply-To address
        if (String.isNotBlank(input.fromAddress)) {
            mail.setReplyTo(input.fromAddress);
        } else {
            mail.setReplyTo('emailtoleadreply@j-21ftn1yqpv9fni7icpxxl2w0cz1lxtazxrtnprq8bz96pq4y1f.h3-mpwmay.cs314.apex.sandbox.salesforce.com'); // Default Reply-To address
        }
        
        // Validate recordId for WhatId
        String recordPrefix = input.recordId?.substring(0, 3);
        Boolean isValidWhatId = recordPrefix == '001' || recordPrefix == '003' || recordPrefix == '500'; //  Account, Contact, Case 
        // Set SaveAsActivity based on the validity of recordId
        System.debug('isValidWhatId '+isValidWhatId);
        
        if (isValidWhatId) {
            mail.setSaveAsActivity(true);
            mail.setWhatId(input.recordId); 
        } else if(recordPrefix == '00Q'){ //Saurabh 26/02/2025 
            System.debug('103');
            mail.setSaveAsActivity(true);
            mail.setTargetObjectId(input.recordId);
            System.debug('106');
            
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
    
    // Custom Exception for better error handling
    public class EmailUtilityException extends Exception {}
}