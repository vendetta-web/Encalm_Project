public class DemoEmailUtility {
    public static String bodyUpdated = '';
    
    public class FlowInputs {
        @InvocableVariable public String templateName;
        @InvocableVariable public String toAddresses;
        @InvocableVariable public String ccAddresses;
        @InvocableVariable public String bccAddresses;
        @InvocableVariable public String fromAddress;
        @InvocableVariable public String recordId;
        @InvocableVariable public String Body;
        @InvocableVariable public String Subject;
        @InvocableVariable public String contentDocumentIds; // Updated to Text (comma-separated)
    }
    
    @InvocableMethod(label='Invoke Email Utility' description='Send Bulk Emails')
    public static void sendEmail(List<FlowInputs> requests) {
        if (requests == null || requests.isEmpty()) return;
        
        System.debug('Request Parameters ---> ' + requests);
        
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        String orgWideEmail = System.Label.OrgWideEmailAddress;
        
        Map<String, OrgWideEmailAddress> oweaMap = new Map<String, OrgWideEmailAddress>();
        for (OrgWideEmailAddress owea : [SELECT Id, Address FROM OrgWideEmailAddress WHERE Address = :orgWideEmail]) {
            oweaMap.put(owea.Address, owea);
        }
        
        Set<Id> leadId = new Set<Id>();
        for (FlowInputs input : requests) {
            if (String.isNotBlank(input.recordId)) {
                leadId.add(input.recordId);
            }
        }
        
        List<Lead> leadsToUpdate = new List<Lead>();
        Map<Id, Lead> leadMap = new Map<Id, Lead>([SELECT Id, Email_History__c,FirstMailSent__c,Status FROM Lead WHERE Id IN :leadId]);
        List<String> subjectList = new List<String>();
        List<Id> docIds = new List<Id>();
        for (FlowInputs input : requests) {
            if (input == null) continue;
            System.debug('input<<<'+ input);
            List<String> toAddressList = String.isNotBlank(input.toAddresses)
                ? input.toAddresses.split(',')
                : new List<String>();
            
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(Test.isRunningTest() ? new List<String>{'test123xyz@test.com'} : toAddressList);
            
            if (String.isNotBlank(input.ccAddresses)) {
                mail.setCcAddresses(input.ccAddresses.split(','));
            }
            if (String.isNotBlank(input.bccAddresses)) {
                mail.setBccAddresses(input.bccAddresses.split(','));
            }
            
            if (oweaMap.containsKey(orgWideEmail)) {
                mail.setOrgWideEmailAddressId(oweaMap.get(orgWideEmail).Id);
            }
            
            mail.setSubject(input.Subject);
            subjectList.add(input.Subject);
            String previousEmails = getPreviousEmails(input.recordId);
            String emailBody = input.Body + '<br><br><br>' + previousEmails;
            
            mail.setHtmlBody(emailBody);
            mail.setReplyTo(String.isNotBlank(input.fromAddress)
                            ? input.fromAddress
                            : System.Label.DefaultLeadReplyToEmail);
            
            mail.setInReplyTo('<' + input.recordId + '@yourdomain.com>');
            mail.setReferences('<' + input.recordId + '@yourdomain.com>');
            
            if (String.isNotBlank(input.recordId)) {
                String prefix = input.recordId.substring(0, 3);
                if (prefix == '001' || prefix == '003' || prefix == '500') {
                    mail.setSaveAsActivity(true);
                    mail.setWhatId(input.recordId);
                } else if (prefix == '00Q') {
                    mail.setSaveAsActivity(true);
                    mail.setTargetObjectId(input.recordId);
                } else {
                    mail.setSaveAsActivity(false);
                }
            }
            
            String profileName = [
                SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1
            ].Profile.Name;
            
            List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
            
            // 🔁 Handle uploaded ContentDocumentIds
            if (String.isNotBlank(input.contentDocumentIds)) {
                
                for (String docId : input.contentDocumentIds.split(',')) {
                    System.debug('docId>>'+  docId);
                    if (String.isNotBlank(docId)) docIds.add(docId.trim());
                }
                System.debug('docIds<<>>'+  docIds);
                System.debug('input>>' + input);
                List<ContentVersion> versions = [
                    SELECT Title, VersionData, FileExtension
                    FROM ContentVersion
                    WHERE ContentDocumentId IN :docIds
                ];
                
                for (ContentVersion cv : versions) {
                    Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                    efa.setFileName(cv.Title + '.' + cv.FileExtension);
                    efa.setBody(cv.VersionData);
                    attachments.add(efa);
                }
            }
            
            // 🔁 Attach static PDFs if profile is Reservation
            if ((profileName == 'Reservation' || profileName == 'System Administrator')  && leadMap.get(input.recordId).Status == 'Open') {
                StaticResource res1 = [SELECT Body FROM StaticResource WHERE Name = 'Shopping_Email_Price_Map'];
                StaticResource res2 = [SELECT Body FROM StaticResource WHERE Name = 'Shopping_Email_Cancellation_Policy'];
                
                Messaging.EmailFileAttachment attachment1 = new Messaging.EmailFileAttachment();
                attachment1.setFileName('Atithya Price Map.pdf');
                attachment1.setBody(res1.Body);
                attachment1.setContentType('application/pdf');
                attachments.add(attachment1);
                
                Messaging.EmailFileAttachment attachment2 = new Messaging.EmailFileAttachment();
                attachment2.setFileName('Atithya Cancellation/ Reschedule Policy.pdf');
                attachment2.setBody(res2.Body);
                attachment2.setContentType('application/pdf');
                attachments.add(attachment2);
            }
            
            mail.setFileAttachments(attachments);
            
            if (leadMap.containsKey(input.recordId)) {
                Lead leadToUpdate = leadMap.get(input.recordId);
                leadToUpdate.Email_History__c = emailBody;
                leadToUpdate.FirstMailSent__c = true;
                leadsToUpdate.add(leadToUpdate);
            }
            
            emailList.add(mail);
        }
        
        // ✅ Send emails
        if (!emailList.isEmpty()) {
            Messaging.SendEmailResult[] results = Messaging.sendEmail(emailList);
            for (Messaging.SendEmailResult result : results) {
                if (!result.isSuccess()) {
                    System.debug('Failed to send email: ' + result.getErrors()[0].getMessage());
                }
            }
        }
        
        if (!leadsToUpdate.isEmpty()) {
            update leadsToUpdate;
        }
        
        String subject = subjectList[0];
        String subjectPattern = '%' + subject.trim() + '%';
        System.debug('subjectPattern>>>'+subjectPattern);
        List<EmailMessage> emailMessages = [ SELECT Id, Subject, CreatedDate  FROM EmailMessage WHERE Subject LIKE :subjectPattern ORDER BY CreatedDate DESC LIMIT 1];
        
        if (!emailMessages.isEmpty() && !docIds.isEmpty()) {
            EmailMessage email = emailMessages[0];
            system.debug('email+++>>>>'+email);
            List<ContentDocumentLink> linksToInsert = new List<ContentDocumentLink>();
            for (String docId : docIds) {
                if (String.isNotBlank(docId)) {
                    linksToInsert.add(new ContentDocumentLink(
                        ContentDocumentId = docId.trim(),
                        LinkedEntityId = email.Id,
                        ShareType = 'V',
                        Visibility = 'AllUsers'
                    ));
                }
            }
            
            if (!linksToInsert.isEmpty()) {
                insert linksToInsert;
            }
        }
        
        
        
        System.debug('Bulk email processing completed.');
    }
    
    public static String getPreviousEmails(String leadId) {
        List<Task> emailTasks = [
            SELECT Subject, Description, CreatedDate
            FROM Task
            WHERE WhoId = :leadId AND TaskSubtype = 'Email'
            ORDER BY CreatedDate DESC
            LIMIT 5
        ];
        
        String emailHistory = '';
        for (Task t : emailTasks) {
            emailHistory += '<br><b>' + t.Subject + '</b><br>' + t.Description + '<br><small>' + t.CreatedDate + '</small><br>';
        }
        return emailHistory;
    }
    
    public class EmailUtilityException extends Exception {}
}