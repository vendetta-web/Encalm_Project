global class EmailServiceHandler implements Messaging.InboundEmailHandler {
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        
        // Get the Lead based on the "From" email address or subject
        List<Lead> leads = [SELECT Id FROM Lead WHERE Email = :email.fromAddress LIMIT 1];
        if (!leads.isEmpty()) {
            Lead lead = leads[0];
            
            // Create a new task or activity to store the email reply
            Task task = new Task();
            task.Subject = 'Email Reply';
            task.WhatId = lead.Id;
            task.Description = email.plainTextBody;
            insert task;
        }
        
        result.success = true;
        System.debug('==========result===>'+result);
        return result;
    }
}