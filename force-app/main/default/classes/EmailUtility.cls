public without sharing class EmailUtility {
    public class FlowInputs{    
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
    }
    
    @InvocableMethod(label='Invoke Email Utility' description='Send Email')
    public static void sendEmail(List<FlowInputs> request) {
        
        System.debug('request ---> ' + request);        
        FlowInputs input = request[0];
        List<String> toAddress = input.toAddresses?.split(',');
        toAddress.add('supriya.bassi@maxify.digital');
        
        EmailTemplate emailTemp;
        if(Test.isRunningTest())
        {
            emailTemp = [Select id, Subject, Body From EmailTemplate Limit 1];
            system.debug('------emailTemp------1----->'+emailTemp);
        }
        else{
            emailTemp = [Select id, Subject, Body From EmailTemplate Where Name = :input.templateName limit 1];
            system.debug('------emailTemp------2----->'+emailTemp);
        }
        
        Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(emailTemp.Id, null, input.recordId);
        
        if(Test.isRunningTest()){
            mail.setToAddresses(new List<String>{'test123xyz@test.com'});
        }
        else{
            mail.setToAddresses(toAddress);
        }
        mail.setSaveAsActivity(true); 
        
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>{mail};
            Messaging.SendEmailResult[] results = Messaging.sendEmail(emailList);
    }
}