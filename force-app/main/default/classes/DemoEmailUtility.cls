public class DemoEmailUtility {
    public static String bodyUpdated = '';
    public class FlowInputs {    
        @InvocableVariable
        public String templateName; 
        @InvocableVariable
        public String toAddresses;
        @InvocableVariable
        public String ccAddresses;
        @InvocableVariable
        public String bccAddresses;
        @InvocableVariable
        public String fromAddress;
        @InvocableVariable
        public String recordId;
        @InvocableVariable
        public String Body;
        @InvocableVariable
        public String Subject; 
    }

    @InvocableMethod(label='Invoke Email Utility' description='Send Bulk Emails')
    public static void sendEmail(List<FlowInputs> requests) {
        if (requests == null || requests.isEmpty()) return;

        System.debug('Request Parameters ---> ' + requests);
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();

        // Fetch Org-Wide Email Address
        String orgWideEmail = System.Label.OrgWideEmailAddress;
        Map<String, OrgWideEmailAddress> oweaMap = new Map<String, OrgWideEmailAddress>();
        for (OrgWideEmailAddress owea : [SELECT Id, Address FROM OrgWideEmailAddress WHERE Address = :orgWideEmail]) {
            oweaMap.put(owea.Address, owea);
        }

        for (FlowInputs input : requests) {
            if (input == null) continue;

            List<String> toAddressList = new List<String>();
            if (String.isNotBlank(input.toAddresses)) {
                toAddressList = input.toAddresses.split(',');
            }
            //commented by saurabh 18March
            //toAddressList.add(System.Label.DefaultToAddress);

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(Test.isRunningTest() ? new List<String>{'test123xyz@test.com'} : toAddressList);

            if (String.isNotBlank(input.ccAddresses)) {
                mail.setCcAddresses(input.ccAddresses.split(','));
            }
            if (String.isNotBlank(input.bccAddresses)) {
                mail.setBccAddresses(input.bccAddresses.split(','));
            }

            // Set Org-Wide Email Address
            if (oweaMap.containsKey(orgWideEmail)) {
                mail.setOrgWideEmailAddressId(oweaMap.get(orgWideEmail).Id);
            }
			mail.setSubject(input.Subject);
            mail.setHtmlBody(input.Body);
            mail.setReplyTo(String.isNotBlank(input.fromAddress) ? input.fromAddress : System.Label.DefaultLeadReplyToEmail);

            // Determine if SaveAsActivity should be set
            if (String.isNotBlank(input.recordId)) {
                String recordPrefix = input.recordId.substring(0, 3);
                if (recordPrefix == '001' || recordPrefix == '003' || recordPrefix == '500') // Account, Contact, Case
                { 
                    mail.setSaveAsActivity(true);
                    mail.setWhatId(input.recordId);
                } else if (recordPrefix == '00Q') {  
                    mail.setSaveAsActivity(true);
                    mail.setTargetObjectId(input.recordId);
                } else {
                    mail.setSaveAsActivity(false);
                }
            }

            emailList.add(mail);
        }

        // Send all emails in a single call
        if (!emailList.isEmpty()) {
            Messaging.SendEmailResult[] results = Messaging.sendEmail(emailList);
            for (Messaging.SendEmailResult result : results) {
                if (!result.isSuccess()) {
                    System.debug('Failed to send email: ' + result.getErrors()[0].getMessage());
                }
            }
        }

        System.debug('Bulk email processing completed.');
    }

    // Custom Exception for better error handling
    public class EmailUtilityException extends Exception {}
}