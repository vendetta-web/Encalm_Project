public class CaseTriggerHandler {
    public static void handleBeforeInsert(List<Case> newCases) {
        try {
            
            for (Case caseRecord : newCases) {               
                
                if (caseRecord.Origin == 'Email') {
                    EmailParser.parseAndSetPicklistFromEmail(caseRecord, caseRecord.Description, caseRecord.Subject);
                }
                
            }
        } catch (Exception e) {
            System.debug('Error occurred in handleBeforeInsertOrUpdate method: ' + e.getMessage());
        }
    }
    
    //Timestamp 
    public static void handleStatusChange(List<Case> newCases, Map<Id, Case> oldMap) {
        DateTime nowTime = System.now();
        
        for (Case c : newCases) {
            Case oldCase = oldMap.get(c.Id);
            
            if (c.Status != oldCase.Status) {
                // Set new status change time
                c.TAT_Start__c	 = nowTime;
                
                // Calculate TAT in hours if old timestamp exists
                if (oldCase.TAT_Start__c!= null) {
                    //Decimal tatInHours = (nowTime.getTime() - oldCase.TAT_Start__c.getTime()) / (1000 * 60 * 60);
                    //c.TAT_Hours__c = tatInHours.setScale(2);
                    Decimal tatInMinutes = (nowTime.getTime() - oldCase.TAT_Start__c.getTime()) / (1000 * 60);
					c.TAT_Hours__c = tatInMinutes.setScale(2); 

                } else {
                    c.TAT_Hours__c = 0;
                }
            }
        }
    }
    
    public static void beforeUpdateAddEntitlementOnCase(List<Case> newCases, Map<Id, Case> oldCasesMap) { // Added by Sidhant
        Set<Id> ownerIds = new Set<Id>();
        for (Case c : newCases) {
            system.debug('Testtttt');
            if (oldCasesMap != null && oldCasesMap.containsKey(c.Id)) {
                Case oldCase = oldCasesMap.get(c.Id); 
                if (c.OwnerId != oldCase.OwnerId && c.Status == 'New') {
                    system.debug('Testtttt');
                    ownerIds.add(c.OwnerId);
                }
            }
            else if (c.Status == 'New') {
                ownerIds.add(c.OwnerId);
                system.debug('Testtttt elseee');
            }
        }
        
        if (!ownerIds.isEmpty()) {
            Map<Id, String> ownerProfileMap = new Map<Id, String>();
            for (User u : [SELECT Id, Profile.Name FROM User WHERE Id IN :ownerIds]) {
                ownerProfileMap.put(u.Id, u.Profile.Name);
            }
            
            for (Case c : newCases) {
                // Case oldCase = oldCasesMap.get(c.Id);
               // if (ownerProfileMap.containsKey(c.OwnerId) && ownerProfileMap.get(c.OwnerId) == 'Reservation') {
                    c.TAT_Start__c = System.now();
                    c.EntitlementId =  System.Label.EntitlementId;
               // }
            }
        }
    }
    public static void afterUpdateReopenMilestone(List<Case> newCases, Map<Id, Case> oldCasesMap) { 
        Set<Id> ownerIds = new Set<Id>();
        Set<Id> caseIds = new Set<Id>(); 
        for (Case c : newCases) {
            Case oldCase = oldCasesMap.get(c.Id); 
            if (c.Status != oldCase.Status && c.Status == 'New') {
                ownerIds.add(c.OwnerId);
                caseIds.add(c.Id); // Add case ID for milestone query
            }
        }
        
        if (!ownerIds.isEmpty()) {
            // Query users and their profiles to check if they are 'Reservation' users
            Map<Id, String> ownerProfileMap = new Map<Id, String>();
            for (User u : [SELECT Id, Profile.Name FROM User WHERE Id IN :ownerIds]) {
                ownerProfileMap.put(u.Id, u.Profile.Name);
            }
            // Query all CaseMilestone records related to the cases whose status changed to 'New'
            List<CaseMilestone> milestonesToUpdate = [SELECT Id, CaseId, IsCompleted FROM CaseMilestone WHERE CaseId IN :caseIds AND IsCompleted = true];
            System.debug('Test 3'+ milestonesToUpdate);
            Map<Id, List<CaseMilestone>> caseMilestoneMap = new Map<Id, List<CaseMilestone>>();
            for (CaseMilestone cm : milestonesToUpdate) {
                if (!caseMilestoneMap.containsKey(cm.CaseId)) {
                    caseMilestoneMap.put(cm.CaseId, new List<CaseMilestone>());
                }
                caseMilestoneMap.get(cm.CaseId).add(cm);
            }
            // Loop through each case and reopen milestones if needed
            List<CaseMilestone> milestoneToUpdate = new List<CaseMilestone>();
            for (Case c : newCases) {
                if (ownerProfileMap.containsKey(c.OwnerId) && ownerProfileMap.get(c.OwnerId) == 'Reservation' && caseMilestoneMap.containsKey(c.Id)) {
                    milestoneToUpdate = caseMilestoneMap.get(c.Id);
                    milestoneToUpdate[0].StartDate = System.now();
                    milestoneToUpdate[0].CompletionDate = null;
                }
            }
            
            // Update the CaseMilestones to reflect the changes
            if (!milestoneToUpdate.isEmpty()) {
                update milestoneToUpdate;
            }
        }
    }
    @AuraEnabled(cacheable=true) // Added by Sidhant to show pre populate the fields while creating Lead(Booking)
    public static Case getCaseFields(Id caseId) {
        System.debug('CaseId '+ caseId);
        try {
            Case caseRecord = [SELECT Subject, Description, SuppliedPhone, SuppliedEmail, SuppliedName, caseNumber, origin FROM Case WHERE Id = :caseId LIMIT 1];
           System.debug('--------------------origin--------->'+caseRecord.origin);
            return caseRecord;
        } catch (Exception e) {
            System.debug('Error fetching case fields: ' + e.getMessage());
            return null;
        }
    }
    
    
    // Method to send and process service emails
    /* public static void processCaseInsert(List<Case> newCases) {
try{
if (newCases.isEmpty()) return;  // Avoid unnecessary execution

// Collect selected services from cases
Set<String> selectedServices = new Set<String>();

for (Case c : newCases) {
if (String.isNotBlank(c.Services__c)) { 
selectedServices.addAll(c.Services__c.split(';')); // Handle multi-select picklist
}
}

// Send emails if services are selected
if (!selectedServices.isEmpty()) {
System.debug('Sending emails for selected services: ' + selectedServices);
sendServiceEmails(new List<String>(selectedServices));
}
} catch (Exception e) {
}
}

public static void sendServiceEmails(List<String> selectedServices) {
System.debug('#### sendServiceEmails Method Called ####');
System.debug('Selected Services: ' + selectedServices);
try{

if (selectedServices.isEmpty()) {
System.debug('No services selected. Throwing exception.');
throw new AuraHandledException('No services selected.');
}

// Fetch custom metadata records where Type = 'Service'
System.debug('Fetching metadata records from Keyword__mdt for selected services...');
List<Keyword__mdt> serviceMetadata = [
SELECT MasterLabel, Service_Email__c 
FROM Keyword__mdt 
WHERE Type__c = 'Service' 
AND MasterLabel IN :selectedServices
];
System.debug('Fetched metadata records count: ' + serviceMetadata.size());

List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

for (Keyword__mdt service : serviceMetadata) {
System.debug('Processing service: ' + service.MasterLabel);

if (String.isNotBlank(service.Service_Email__c)) {
System.debug('Found valid email for service: ' + service.MasterLabel + ' | Email: ' + service.Service_Email__c);

// Construct email
Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

// Set recipient
List<String> recipients = new List<String>{service.Service_Email__c};
email.setToAddresses(recipients);
System.debug('Email To Addresses: ' + recipients);

// Set subject
String emailSubject = 'Notification for ' + service.MasterLabel;
email.setSubject(emailSubject);
System.debug('Email Subject: ' + emailSubject);

// Set body
String emailBody = 'Hello,\n\nThis is an automated email for ' + service.MasterLabel + '.\n\nThank you!';
email.setPlainTextBody(emailBody);
System.debug('Email Body: ' + emailBody);

emails.add(email);
System.debug('Email added to list for: ' + service.MasterLabel);
} else {
System.debug('No valid email found for service: ' + service.MasterLabel);
}
}

// Send emails
System.debug('===emails================>'+emails);
if (!emails.isEmpty()) {
System.debug('Preparing to send ' + emails.size() + ' emails...');
Messaging.sendEmail(emails);
System.debug('Emails sent successfully.');
} } 
catch (Exception e) {
}
} */
}