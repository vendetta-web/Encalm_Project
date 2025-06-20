public with sharing class BookingEmailHandler {
    
    @AuraEnabled
    public static void sendEmailWithAttachment(String opportunityId, String actionType, String paymentURL) {
        try {
            // Fetch Opportunity, Account, and Contact
            Opportunity opp = [SELECT Id, AccountId,Service_Airport_Id__r.Name,Service_Airport__c,Date_of_Arrival__c,Date_of_Departure__c FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
            if (opp == null || opp.AccountId == null) {
                throw new AuraHandledException('Opportunity or Account not found.');
            }
            String AirportName = '';
            if (opp.Service_Airport_Id__c !=null ) {
                AirportName = opp.Service_Airport_Id__r.Name;
            } else {
                AirportName = opp.Service_Airport__c;
            }
            String journeyDate = '';
            if (opp.Date_of_Arrival__c !=null) {
                journeyDate = opp.Date_of_Arrival__c;
            } else if (opp.Date_of_Departure__c !=null) {
                journeyDate = opp.Date_of_Departure__c;
            }
            String paymentLinkHtml = '';
            if (String.isNotEmpty(paymentURL)) {
                paymentLinkHtml = '<p><strong> Payment Link - </strong><a href="' + paymentURL + '" target="_blank">' + paymentURL + '</a></p>';
            }
            

            Account acc = [SELECT Id, (SELECT Email,Name,Salutation FROM Contacts LIMIT 1) FROM Account WHERE Id = :opp.AccountId LIMIT 1];
            if (acc == null || acc.Contacts.isEmpty()) {
                throw new AuraHandledException('No Contact found for this Account.');
            }

            String contactEmail = acc.Contacts[0].Email;
            STring contactName = acc.Contacts[0].Name;
            String salutation = acc.Contacts[0].Salutation;

            // Fetch the most recent PDF file from the Opportunity
            List<ContentDocumentLink> cdl = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :opportunityId ORDER BY SystemModstamp DESC LIMIT 1];
            if (cdl.size() < 1) {
                throw new AuraHandledException('No files found on the Opportunity.');
            }

            ContentVersion cv = [SELECT VersionData, Title FROM ContentVersion WHERE ContentDocumentId = :cdl[0].ContentDocumentId LIMIT 1];
            String subject = 'Booking Reserved: Atithya Services at ' + AirportName + ' for ' + salutation + contactName + ' on ' + journeyDate;
            // Create dynamic HTML email body using Opportunity fields
            String htmlBody = '<!DOCTYPE html>'
                + '<html>'
                + '<head>'
                + '    <title>Performa Invoice</title>'
                + '    <style>'
                + '        body {'
                + '            font-family: Arial, sans-serif;'
                + '            line-height: 1.6;'
                + '            color: #333;'
                + '            margin: 0;'
                + '            padding: 0;'
                + '        }'
                + '        .email-container {'
                + '            max-width: 600px;'
                + '            margin: auto;'
                + '            padding: 20px;'
                + '            background-color: #f9f9f9;'
                + '            border: 1px solid #ddd;'
                + '            border-radius: 5px;'
                + '        }'
                + '        .header {'
                + '            text-align: center;'
                + '            margin-bottom: 20px;'
                + '        }'
                + '        .header h1 {'
                + '            color: #cda45e;'
                + '        }'
                + '        .content {'
                + '            margin-bottom: 20px;'
                + '        }'
                + '        .footer {'
                + '            font-size: 0.9em;'
                + '            color: #555;'
                + '            text-align: center;'
                + '            border-top: 1px solid #ddd;'
                + '            padding-top: 15px;'
                + '        }'
                + '    </style>'
                + '</head>'
                + '<body>'
                + '    <div class="email-container">'
                + '        <div class="header">'
                + '            <h1>Thank You for Choosing Atithya</h1>'
                + '        </div>'
                + '        <div class="content">'
                + '            <p>Thank you for selecting Atithya - Welcome & Assist Services for your upcoming travel at <strong>' + AirportName + '</strong>. Please find attached the Performa Invoice.</p>'
                + '            <p>We look forward to serving you at <strong>' + AirportName + '</strong>.</p>'
                + '            <p>Feel free to call us for any query regarding the service.</p>'
                + paymentLinkHtml
                + '        </div>'
                + '        <div class="footer">'
                + '            <p>Warm Regards,<br/>'
                + '            Team Atithya,<br/>'
                + '            Encalm Hospitality Pvt. Ltd.<br/>'
                + '            IGI Airport, New Delhi<br/>'
                + '            Reservation Number: +919289366950<br/>'
                + '            Email: <a href="mailto:guest.services@encalm.com">guest.services@encalm.com</a></p>'
                + '        </div>'
                + '    </div>'
                + '</body>'
                + '</html>';

            // Create an Email
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] { contactEmail });
            email.setSubject(subject);
            email.setHtmlBody(htmlBody);
            //email.setReplyTo(System.Label.DefaultReplyToAddress);
            // Attach the file
            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            attachment.setFileName(cv.Title + '.pdf');
            attachment.setBody(cv.VersionData);
            email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });

            // Send the email
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            if(!Test.IsRunningTest()){
            	//getSWIFTTokenFuture(opportunityId, actionType); //MDEN_SWIFT.getAccessToken(opportunityId,actionType);
            }
        }  catch (Exception e) {
            system.debug('Exception in BookingEmailHandler===>'+ e.getMessage());
            throw new AuraHandledException('Error while sending email to contact with attachment. ' + e.getMessage());
        }      
    }
    
   /* @future(callout=true)
    public static void getSWIFTTokenFuture(String opportunityId, String actionType) {
        MDEN_SWIFT.getAccessToken(opportunityId, actionType);
    }*/
}