global class EmailToLeadReply implements Messaging.InboundEmailHandler {
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email,Messaging.InboundEnvelope envelope){
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        System.debug('test email body'+email.plainTextBody.contains('Dear '));
        if(email.plainTextBody.contains('Dear ')){
            String leadName=email.plainTextBody.split('Dear ')[1].split(',')[0];
            System.debug('Lead name '+leadName);
            System.debug('test email subj'+email.subject);
            Task savenewTask = new Task(whoId=[Select Id From Lead Where Name=:leadName 
                                               ORDER By LastModifiedById DESC Limit 1].Id
                                        ,Subject=email.subject,TaskSubtype='Email',Description=email.plainTextBody);
            insert savenewTask;
        }
        result.success = true;
        return result;
    }
}