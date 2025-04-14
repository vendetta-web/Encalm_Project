@isTest
public class LeadConversionControllerTest {
    
    @testSetup
    static void setupData() {
        String accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId();
        Account acc = new Account(
            Name = 'Test Account',
            RecordTypeId = accRecordTypeId,
            BillingStreet = '123 Main Street',
            BillingCity = 'Pune',
            BillingState = 'Maharashtra',
            BillingPostalCode = '411001',
            BillingCountry = 'India'                    
        );
        insert acc;
        
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Email = 'testlead@example.com',
            Status = 'Open - Not Contacted'
        );
        insert testLead;
        
        Case testCase = new Case(
            Subject = 'Test Case',
            Status = 'New',
            Origin = 'Web'
        );
        insert testCase;
    }
    
    @isTest
    static void testProcessBookingForLead() {
        Account acc = [SELECT Id FROM Account Where Name = 'Test Account' LIMIT 1];
        Lead testLead = [SELECT Id FROM Lead  Where Email = 'testlead@example.com' LIMIT 1];
        
        Map<String, Object> oppFields = new Map<String, Object>{
            'Service_Airport__c' => 'DEL',
                'Service_Type__c' => 'Meet and Greet'
                };
                    
                    Test.startTest();
        try{
            String oppId = LeadConversionController.processBooking(testLead.Id, acc.Id, oppFields);
            System.assertNotEquals(null, oppId, 'Opportunity Id should be returned');
            Opportunity opp = [SELECT Id, Name, StageName FROM Opportunity WHERE Id = :oppId];
            System.assertEquals('Quotation', opp.StageName, 'Stage should be Quotation');
            Map<String, Id> result = LeadConversionController.convertLead(testLead.Id);
        }catch(exception e){
            system.debug('exception++++=='+ e.getMessage());
        }
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testProcessBookingForCase() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        
        Map<String, Object> oppFields = new Map<String, Object>{
            'Service_Airport__c' => 'DEL',
                'Service_Type__c' => 'Meet and Greet'
                };
                    
                    Test.startTest();
        String oppId = LeadConversionController.processBooking(testCase.Id, acc.Id, oppFields);
        
        String bookingNumber = LeadConversionController.generateNewBookingNumber();
        System.assertNotEquals(null, bookingNumber, 'Booking number should be generated');
        LeadConversionController.generateNewBookingNumber();
        LeadConversionController.isNumeric('232456767');
        
        Test.stopTest();
        
        Opportunity opp = [SELECT Id, Name, StageName FROM Opportunity WHERE Id = :oppId];
        System.assertEquals('Value Proposition', opp.StageName, 'Stage should be Value Proposition');
    }
    
    @isTest
    static void testConvertLead() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        try{
            String convertedStatus = [SELECT MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1].MasterLabel;
            //Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
            
            User testUser = new User(
                Alias = 'tuser',
                Email = 'testuser@example.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'TestUser',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = p.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                UserName = 'testuser' + DateTime.now().getTime() + '@example.com'
            );
            insert testUser;
            
            //System.runAs(testUser) {
                Lead testLead = new Lead(
                    FirstName = 'EN',
                    LastName = 'Doe',
                    Company = 'Test Company',
                    Email = 'john.doe@test.com',
                    OwnerId = testUser.Id,
                    Status = convertedStatus
                );
                insert testLead;
            
            Test.startTest();
            Map<String, Id> result = LeadConversionController.convertLead(testLead.Id);
            Lead convertedLead = [SELECT IsConverted FROM Lead WHERE Id = :testLead.Id];
            System.assert(convertedLead.IsConverted, 'Lead should be converted');
            Map<String, Id> result2 = LeadConversionController.convertLead(null);
            
            Test.stopTest();    
            //}
        }catch(exception e){
            system.debug('exception>>>>'+ e.getMessage());
        }
    }
}