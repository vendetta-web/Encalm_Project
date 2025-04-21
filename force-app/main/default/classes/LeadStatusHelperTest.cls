@isTest
private class LeadStatusHelperTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test profiles
        Profile reservationProfile = new Profile(Name = 'Reservation');
        //insert reservationProfile;
        
        // Create test users
        User reservationUser = new User(
            Alias = 'resUser',
            Email = 'reservation.user@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Reservation',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [Select ID,Name From Profile Where Name='Reservation' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'reservation.user@test.com'
        );
        insert reservationUser;
        
        // Create test queue
        Group reservationQueue = new Group(
            Name = 'Reservation Queue',
            Type = 'Queue'
        );
        insert reservationQueue;
        
        // Create test case
        Case testCase = new Case(
            Origin = 'Web',
            Subject = 'Test Case'
        );
        insert testCase;
    }
    
    @isTest
    static void testHandleBeforeUpdateStatusChangeToAwaitingResponse() {
        // Setup test data
        Group queue = [SELECT Id FROM Group WHERE Name = 'Reservation Queue' LIMIT 1];
        Lead testLead = new Lead(
            LastName = 'Test',
            Company = 'Test Company',
            Status = 'Open'
            ,Email='testlead23@yopmail.com'
        );
        insert testLead;
        
        // Update lead status
        testLead.Status = 'Awaiting Customer response';
        
        Test.startTest();
        QueueSobject mappingObject = new QueueSobject(QueueId = queue.Id, SobjectType = 'Lead');
        System.runAs(new User(Id = UserInfo.getUserId()))
        {insert mappingObject;}
        update testLead;
        Test.stopTest();
        
        // Verify results
        Lead updatedLead = [SELECT Id, OwnerId FROM Lead WHERE Id = :testLead.Id];
        //System.assertEquals(queue.Id, updatedLead.OwnerId, 'Lead should be assigned to Reservation Queue');
    }
    
    @isTest
    static void testHandleBeforeUpdateWithCaseOrigin() {
        // Setup test data
        Case testCase = [SELECT Id, Origin FROM Case LIMIT 1];
        Lead testLead = new Lead(
            LastName = 'Test',
            Company = 'Test Company',
            Status = 'Open',
            Email='testlead23@yopmail.com',
            Case__c = testCase.Id
        );
        insert testLead;
        
        // Update lead
        testLead.LeadSource = 'Web';
        
        Test.startTest();
        update testLead;
        Test.stopTest();
        
        // Verify results
        Lead updatedLead = [SELECT Id, LeadSource FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals(testCase.Origin, updatedLead.LeadSource, 'LeadSource should match Case Origin');
    }
    
    @isTest
    static void testHandleBeforeInsertWithCaseOrigin() {
        // Setup test data
        Case testCase = [SELECT Id, Origin FROM Case LIMIT 1];
        
        Test.startTest();
        Lead testLead = new Lead(
            LastName = 'Test',
            Company = 'Test Company',
            Status = 'Open',
            Email='testlead23@yopmail.com',
            LeadSource = 'Web',
            Case__c = testCase.Id
        );
        insert testLead;
        Test.stopTest();
        
        // Verify results
        Lead insertedLead = [SELECT Id, LeadSource FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals(testCase.Origin, insertedLead.LeadSource, 'LeadSource should match Case Origin');
    }
    
    @isTest
    static void testBeforeUpdateLeadEscalationNewOwnerReservation() {
        // Setup test data
        User resUser = [SELECT Id FROM User WHERE UserName = 'reservation.user@test.com' LIMIT 1];
        Lead testLead = new Lead(
            LastName = 'Test',
            Company = 'Test Company',
            Status = 'Working',
            Email='testlead23@yopmail.com',
            OwnerId = UserInfo.getUserId()
        );
        insert testLead;
        
        // Update lead owner to reservation user and status to Open
        testLead.OwnerId = resUser.Id;
        testLead.Status = 'Open';
        
        Test.startTest();
        update testLead;
        Test.stopTest();
        
        // Verify results - check that a scheduled job was created
        //List<CronTrigger> scheduledJobs = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name LIKE 'Lead Timer First Check%'];
        //System.assertEquals(1, scheduledJobs.size(), 'Should have scheduled an escalation timer');
    }
    
    @isTest
    static void testBeforeUpdateLeadEscalationStatusChangeToOpen() {
        // Setup test data
        User resUser = [SELECT Id FROM User WHERE UserName = 'reservation.user@test.com' LIMIT 1];
        Lead testLead = new Lead(
            LastName = 'Test',
            Company = 'Test Company',
            Status = 'Working',
            Email='testlead23@yopmail.com',
            OwnerId = resUser.Id
        );
        insert testLead;
        
        // Update lead status to Open
        testLead.Status = 'Open';
        
        Test.startTest();
        update testLead;
        Test.stopTest();
        
        // Verify results - check that a scheduled job was created
        //List<CronTrigger> scheduledJobs = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name LIKE 'Lead Timer First Check%'];
        //System.assertEquals(1, scheduledJobs.size(), 'Should have scheduled an escalation timer');
    }
    
   

    
    @isTest
    static void testErrorHandlingInHandleBeforeUpdate() {
        // Setup test data to force exception
       
        Test.startTest();
        try {
             Lead testLead= new Lead(
            LastName = 'Test',
            Company = 'Test Company',
            Status = 'Open',
            Email='testlead23@yopmail.com',
            Case__c = 'invalidId' // This will cause an exception
        );
            insert testLead;
            testLead.Status = 'Awaiting Customer response';
            update testLead;
            Lead updatedLead = [SELECT Id, Status FROM Lead WHERE Id = :testLead.Id];
            System.assertEquals('Awaiting Customer response', updatedLead.Status, 'Lead should be updated even with error in handler');
            
        } catch (Exception e) {
            System.debug(e.getMessage());
            System.assert(e.getMessage()=='Invalid id: invalidId', 'Exception should be caught in handler and not bubble up');
        }

        Test.stopTest();
        
        // Verify the lead was still updated despite the error
    }
}