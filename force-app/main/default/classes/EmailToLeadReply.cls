global class EmailToLeadReply implements Messaging.InboundEmailHandler {

    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        list<Attachment> attachList = new list<Attachment>();
        
        try {
            // Debug the email body
            System.debug('Email Body: ' + email.plainTextBody);

            // Check if the email body contains the keyword 'Dear '
            if (email.plainTextBody != null && email.plainTextBody.contains('Dear ')) {
                // Extract the lead name from the email body
                String leadName = email.plainTextBody.split('Dear ')[1].split(',')[0];
                System.debug('Lead Name: ' + leadName);

                // Query the most recently modified lead with the extracted name
                List<Lead> leads = [SELECT Id,Status,Department__c,OwnerId,CreatedById FROM Lead WHERE Name = :leadName ORDER BY LastModifiedDate DESC LIMIT 1];

                if (!leads.isEmpty()) {
                  //  String senderInfo = 'Email received from: ' + email.fromName + ' <' + envelope.fromAddress + '>\n\n';
                    //String fullDescription = senderInfo + email.plainTextBody;
                    // Create a new task associated with the lead
                    Task newTask = new Task(
                        WhoId = leads[0].Id,
                        Subject = email.subject,
                        TaskSubtype = 'Email',
                        Description = email.plainTextBody
                      //  Description = fullDescription

                    );

                    // Insert the new task
                    insert newTask;
                    
                    leads[0].Status='Customer Responded';
                    if(leads[0].Department__c=='Reservations'){
                    leads[0].OwnerId=leads[0].CreatedById;
                    }else if(leads[0].Department__c=='Sales'){
                        List<User> salesReps = [SELECT Id FROM User WHERE Profile.Name = 'Sales' AND UserRole.Name = 'Executive' LIMIT 1];
                            if (!salesReps.isEmpty()) {
                                leads[0].OwnerId = salesReps[0].Id;
                            }   
                    }
                    update leads;
                    List<String> subjectList = new List<String>{'Email:','Re: Sandbox:'};
                    List<Task> tskRecord = [Select id,Status,Subject FROM Task Where WhoId =: leads[0].Id AND Status = 'Open' AND Subject NOT IN : subjectList LIMIT 1];
                    if(!tskRecord.IsEmpty()){
                    tskRecord[0].Status = 'Completed';
                    update tskRecord;
                    }
                    List<RefreshEvent__e> events = new List<RefreshEvent__e>();
                    events.add(new RefreshEvent__e(LeadId__c = leads[0].Id,CaseId__c = ''));
                    if(!events.IsEmpty()){
                        EventBus.publish(events);
                    }
                    System.debug('Task created successfully: ' + newTask.Id);
                } else {
                    System.debug('No lead found with the name: ' + leadName);
                    result.success = false;
                    result.message = 'No lead found with the name: ' + leadName;
                    return result;
                }
            } else {
                System.debug('Email body does not contain the keyword "Dear "');
                result.success = false;
                result.message = 'Email body does not contain the keyword "Dear "';
                return result;
            }

            // Set the result to success
            result.success = true;
        } catch (Exception e) {
            // Log the exception and set the result to failure
            System.debug('An error occurred: ' + e.getMessage());
            result.success = false;
            result.message = 'An error occurred: ' + e.getMessage();
        }

        return result;
    }
}