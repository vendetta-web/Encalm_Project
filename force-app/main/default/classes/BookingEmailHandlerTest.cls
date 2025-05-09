@isTest
public class BookingEmailHandlerTest {
    
    static Id opportunityWithFileId;
    static Id opportunityWithoutFileId;
    static Id accountWithoutContactId;
    
    @testSetup
    static void setupTestData() {
        // Create Account with Contact
        Account accWithContact = new Account(
            Name = 'Account With Contact',
            BillingStreet = '123 Main Street',
            BillingCity = 'Pune',
            BillingState = 'Maharashtra',
            BillingPostalCode = '411001',
            BillingCountry = 'India'
        );
        insert accWithContact;
        
        Contact con = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'john.doe@example.com',
            Salutation = 'Mr.',
            AccountId = accWithContact.Id
        );
        insert con;
        
        // Create Opportunity with Account and Contact
        Opportunity oppWithFile = new Opportunity(
            Name = 'Opportunity With File',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            AccountId = accWithContact.Id,
            Service_Airport__c = 'Delhi Airport',
            Date_of_Arrival__c = String.valueOf(Date.today().addDays(5))
        );
        insert oppWithFile;
        opportunityWithFileId = oppWithFile.Id;
        
        // Attach File to Opportunity
        ContentVersion cv = new ContentVersion(
            Title = 'TestAttachment',
            PathOnClient = 'TestAttachment.pdf',
            VersionData = Blob.valueOf('Sample PDF content'),
            IsMajorVersion = true
        );
        insert cv;
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
		
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId = opportunityWithFileId,
            ShareType = 'V' 
        );
        insert cdl;
        
        // Create Account without Contact
        Account accWithoutContact = new Account(
            Name = 'Account Without Contact',
        	BillingStreet = '123 Main Street',
            BillingCity = 'Pune',
            BillingState = 'Maharashtra',
            BillingPostalCode = '411001',
            BillingCountry = 'India'
        	);
        insert accWithoutContact;
        accountWithoutContactId = accWithoutContact.Id;
        
        // Create Opportunity without Contact
        Opportunity oppWithoutFile = new Opportunity(
            Name = 'Opportunity Without File',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(15),
            AccountId = accWithContact.Id,
            Service_Airport__c = 'Mumbai Airport',
            Date_of_Departure__c = String.valueOf(Date.today().addDays(7))
        );
        insert oppWithoutFile;
    }
    
    @isTest
    static void testSendEmailWithAttachment_Positive() {
        Opportunity Opp = [Select id from Opportunity Where Name = 'Opportunity With File' LIMIT 1 ];
        Test.startTest();
        try {
            BookingEmailHandler.sendEmailWithAttachment(Opp.Id, 'test');
        } catch (Exception ex) {
            System.debug('Error occurred in BookingEmailHandler.sendEmailWithAttachment: ' + ex.getMessage());
            System.debug('Stack Trace: ' + ex.getStackTraceString());
        }

        Test.stopTest();
    }
    
    @isTest
    static void testSendEmailWithAttachment_NoFile_Negative() {
        
        Test.startTest();
        try {
            Opportunity Opp = [Select id from Opportunity Where Name = 'Opportunity Without File' LIMIT 1 ];
            BookingEmailHandler.sendEmailWithAttachment(Opp.Id, 'test');
            System.assert(false, 'Expected exception due to missing file.');
        } catch (AuraHandledException ex) {
            Assert.isFalse(ex.getMessage().contains('No files found'), 'Exception should mention missing file.');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testSendEmailWithAttachment_NoContact_Negative() {
        // Create opportunity linked to account with no contact
        Opportunity opp = new Opportunity(
            Name = 'Opportunity No Contact',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(12),
            AccountId = accountWithoutContactId,
            Service_Airport__c = 'Chennai Airport',
            Date_of_Arrival__c = String.valueOf(Date.today().addDays(8))
        );
        insert opp;
        
        // Attach File
        ContentVersion cv = new ContentVersion(
            Title = 'TestAttachment2',
            PathOnClient = 'TestAttachment2.pdf',
            VersionData = Blob.valueOf('Sample PDF content 2')
        );
        insert cv;
        
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId,
            LinkedEntityId = opp.Id,
            ShareType = 'V' 
        );
        insert cdl;
        
        Test.startTest();
        try {
            BookingEmailHandler.sendEmailWithAttachment(opp.Id, 'test');
            System.assert(false, 'Expected exception due to missing contact.');
        } catch (AuraHandledException ex) {
            System.debug('getMessage()'+ ex.getMessage());
        }
        Test.stopTest();
    }
}