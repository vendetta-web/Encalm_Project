@isTest
public class CaseTriggerHandlerTest {

    @isTest
    static void testHandleBeforeInsertOrUpdate() {
        
        Group reservationQueue = new Group(
            Name = 'Reservation Queue',
            DeveloperName = 'Reservation_Queue',
            Type = 'Queue'
        );
        insert reservationQueue;

        // Create test Case records
        Case case1 = new Case(
            Subject = 'Test Case 1',
            Description = 'Test Description for Case 1',
            Origin = 'Email',
            Status = 'New'
        );
        
        Case case2 = new Case(
            Subject = 'Test Case 2',
            Description = 'Test Description for Case 2',
            Origin = 'Web',
            Status = 'New'
        );

        // Insert the Case records
        insert new List<Case>{ case1, case2 };

        // Now update the cases, simulating changes
        case1.Status = 'In Progress'; // Change status
        case2.Status = 'Closed'; // Change status
        update new List<Case>{ case1, case2 };

        // Re-query the Case records
        Case updatedCase1 = [SELECT Id, Status, OwnerId FROM Case WHERE Id = :case1.Id];
        Case updatedCase2 = [SELECT Id, Status, OwnerId FROM Case WHERE Id = :case2.Id];

        // Test if OwnerId was updated to the Reservation Queue for case1
        System.assertEquals(reservationQueue.Id, updatedCase1.OwnerId, 'OwnerId for Case 1 should be set to Reservation Queue.');
        
        // Test that case2 OwnerId was not changed (as the criteria did not match)
        System.assertNotEquals(reservationQueue.Id, updatedCase2.OwnerId, 'OwnerId for Case 2 should not be set to Reservation Queue.');
    }

    @isTest
    static void testHandleAfterInsertOrUpdate() {
        // Create a reservation queue group (Setup object)
        Group reservationQueue = new Group(
            Name = 'Reservation Queue',
            DeveloperName = 'Reservation_Queue',
            Type = 'Queue'
        );
        insert reservationQueue;

        // Create test Case records
        Case case1 = new Case(
            Subject = 'Test Case 1',
            Description = 'Test Description for Case 1',
            Origin = 'Email',
            Status = 'New'
        );
        
        Case case2 = new Case(
            Subject = 'Test Case 2',
            Description = 'Test Description for Case 2',
            Origin = 'Web',
            Status = 'New'
        );

        // Insert the Case records
        insert new List<Case>{ case1, case2 };

        // Create test Lead records that are linked to the Cases via Case__c field
        Lead lead1 = new Lead(
            FirstName = 'Test',
            LastName = 'Lead1',
            Case__c = case1.Id,
            LeadSource = 'Web'
        );

        Lead lead2 = new Lead(
            FirstName = 'Test',
            LastName = 'Lead2',
            Case__c = case2.Id,
            LeadSource = 'Phone'
        );

        // Insert the Lead records
        insert new List<Lead>{ lead1, lead2 };

        // Now update the cases to trigger the after update logic
        case1.Status = 'In Progress';
        case2.Status = 'Closed';
        update new List<Case>{ case1, case2 };

        // Re-query the Case and Lead records
        Lead updatedLead1 = [SELECT Id, LeadSource FROM Lead WHERE Id = :lead1.Id];
        Lead updatedLead2 = [SELECT Id, LeadSource FROM Lead WHERE Id = :lead2.Id];

        // Test if LeadSource for lead1 was updated to 'Email' based on Case's Origin
        System.assertEquals('Email', updatedLead1.LeadSource, 'LeadSource for Lead 1 should be updated to "Email".');

        // Test if LeadSource for lead2 was updated to 'Web' based on Case's Origin
        System.assertEquals('Web', updatedLead2.LeadSource, 'LeadSource for Lead 2 should be updated to "Web".');
    }
}