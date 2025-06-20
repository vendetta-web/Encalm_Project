global class EmailToLeadReply implements Messaging.InboundEmailHandler {
    
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        list<Attachment> attachList = new list<Attachment>();
        
        try {
            // Debug the email body
            System.debug('Email header: ' + email.headers);
            System.debug('Email HtmlBody: ' + email.HtmlBody);
            System.debug('Email Text Body: ' + email.plainTextBody);
            System.debug('Email' + email);
            System.debug('binaryAttachments' + email.binaryAttachments);
            System.debug('email.textAttachments' + email.textAttachments);
            
            String leadIdSendEmail = extractLeadId(email.headers);
            
            String body = email.HtmlBody != null ? email.HtmlBody : email.plainTextBody;
            String leadIdUtilityMail ;
            if (String.isNotBlank(body)) {
                Pattern leadIdPattern = Pattern.compile('(?i)Subject:</b>\\s*Sandbox:\\s*(00Q[0-9A-Za-z]{12,15})');
                Matcher matcher = leadIdPattern.matcher(body);
                
                if (matcher.find()) {
                    leadIdUtilityMail = matcher.group(1);
                }
            }
            System.debug('26>>>');
            String leadId = String.isNotBlank(leadIdSendEmail) ? leadIdSendEmail : leadIdUtilityMail;
            
            if (!String.isBlank(leadId)) {
                
                List<Lead> leads = [SELECT Id,Status,Department__c,OwnerId,Previous_Owner__c,CreatedById,IsConverted FROM Lead WHERE Id = :leadId ORDER BY LastModifiedDate DESC LIMIT 1];
                System.debug('32>>>');
                Task newTask = new Task(
                    WhoId = leads[0].Id,
                    Subject = email.subject,
                    TaskSubtype = 'Email',
                    Description = email.plainTextBody, 
                    ActivityDate = Date.today(),
                    //OwnerId = leads[0].Previous_Owner__c != null?leads[0].Previous_Owner__c :leads[0].CreatedById,
                    Status = 'Completed'
                );                
                insert newTask; 
                
                if (email.textAttachments != null && !email.textAttachments.isEmpty()) {
                    for (Messaging.Inboundemail.TextAttachment tAttachment : email.textAttachments) {
                        Attachment attachment = new Attachment();
                        attachment.Name = tAttachment.fileName;
                        attachment.Body = Blob.valueOf(tAttachment.body);
                        attachment.ParentId = newTask.Id;
                        insert attachment;
                    }
                }
                if (email.binaryAttachments != null && !email.binaryAttachments.isEmpty()) {
                for (Messaging.Inboundemail.BinaryAttachment bAttachment : email.binaryAttachments) {
                    Attachment attachment = new Attachment();
                    attachment.Name = bAttachment.fileName;
                    attachment.Body = bAttachment.body;
                    attachment.ParentId = newTask.Id;
                    insert attachment;
                }
                }
                
                
                
                /*EmailMessage emailMsg = new EmailMessage();
emailMsg.Subject = email.subject;
emailMsg.TextBody = email.plainTextBody;
emailMsg.HtmlBody = email.HtmlBody;
emailMsg.FromName = envelope.fromAddress;
emailMsg.Incoming = true;
emailMsg.Status = '3'; 
emailMsg.ToAddress = email.toAddresses != null && !email.toAddresses.isEmpty() ? String.join(email.toAddresses, ';') : null;
emailMsg.FromAddress = envelope.fromAddress;
emailMsg.MessageDate = System.now();

insert emailMsg;*/
                
                System.debug('42>>>>>');
                if(!leads[0].IsConverted){
                    System.debug('44>>>>');
                    leads[0].Status='Customer Responded';
                    if(leads[0].Department__c=='Reservations'){
                        leads[0].OwnerId=leads[0].CreatedById;
                    }else if(leads[0].Department__c=='Sales'){
                        List<User> salesReps = [SELECT Id FROM User WHERE Profile.Name = 'Sales' AND Id =:  leads[0].Previous_Owner__c LIMIT 1];
                        if (!salesReps.isEmpty()) {
                            leads[0].OwnerId = salesReps[0].Id;
                        }   
                    }
                    update leads;
                }
                
                List<String> subjectList = new List<String>{'Email:','Re: Sandbox:'};
                    List<Task> tskRecord = [Select id,Status,Subject FROM Task Where WhoId =: leads[0].Id AND Status = 'Open' AND Subject NOT IN : subjectList LIMIT 1];
                
                if(!tskRecord.isEmpty()){
                    tskRecord[0].Status = 'Completed';
                    update tskRecord;
                }
                List<RefreshEvent__e> events = new List<RefreshEvent__e>();
                events.add(new RefreshEvent__e(LeadId__c = leads[0].Id,CaseId__c = ''));
                if(!events.IsEmpty()){
                    EventBus.publish(events);
                }
                
                //System.debug('Task created successfully: ' + newTask.Id);
            } else {                
                System.debug('No lead found with the Id: ' + leadId);
                result.success = false;
                result.message = 'No lead found with the Id: ' + leadId;
                return result;
            }
            result.success = true;
        } catch (Exception e) {
            // Log the exception and set the result to failure
            System.debug('An error occurred: ' + e.getMessage());
            result.success = false;
            result.message = 'An error occurred: ' + e.getMessage();
        }
        
        return result;
    }
    private String extractLeadId(List<Messaging.InboundEmail.Header> headers) {
        if (headers != null && !headers.isEmpty()) {
            for (Messaging.InboundEmail.Header header : headers) {
                if (header.name.equalsIgnoreCase('In-Reply-To') || header.name.equalsIgnoreCase('References')) {
                    Pattern leadPattern = Pattern.compile('\\b00Q\\w+');
                    Matcher leadMatcher = leadPattern.matcher(header.value);
                    if (leadMatcher.find()) {
                        return leadMatcher.group(0);
                    }
                }
            }
        }
        return null;
    }
}