@isTest
public class AgentWorkTriggerTest {
    @isTest
    static void testAgentWorkTrigger_ReservationUser_NewCase() {
        // Create 'Reservation' profile
        Profile reservationProfile = [SELECT Id FROM Profile WHERE Name = 'Reservation' LIMIT 1];

        // Create a user with the Reservation profile
        User reservationUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser' + System.currentTimeMillis() + '@test.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = reservationProfile.Id
        );
        insert reservationUser;

        // Create a test Case owned by the Reservation user
        Case testCase = new Case(
            Subject = 'Test Case for AgentWork Trigger',
            Status = 'New',
            OwnerId = reservationUser.Id
        );
        insert testCase;

        // Create a mock AgentWork record to simulate the trigger input
        AgentWork mockAW = new AgentWork(
            WorkItemId = testCase.Id
        );
        //mockAW.put('Status', 'Assigned');


        // Validate the result
        Case updatedCase = [SELECT TAT_Start__c, EntitlementId FROM Case WHERE Id = :testCase.Id];
        System.assertNotEquals(null, updatedCase.TAT_Start__c, 'TAT_Start__c should be set');
        System.assertEquals(Label.EntitlementId, updatedCase.EntitlementId, 'EntitlementId should be set from custom label');
    }

    @isTest
    static void testAgentWorkTrigger_NonReservationProfileOrWrongStatus() {
        // Get a profile that is not 'Reservation'
        Profile someOtherProfile = [SELECT Id FROM Profile WHERE Name != 'Reservation' LIMIT 1];

        User nonReservationUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'nonres@example.com',
            Username = 'nonresuser' + System.currentTimeMillis() + '@test.com',
            Alias = 'nuser',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = someOtherProfile.Id
        );
        insert nonReservationUser;

        // Create a case with wrong profile or status
        Case testCase = new Case(
            Subject = 'Invalid Trigger Case',
            Status = 'Closed', // Not 'New'
            OwnerId = nonReservationUser.Id
        );
        insert testCase;

        AgentWork mockAW = new AgentWork(
            WorkItemId = testCase.Id
        );
        //mockAW.put('Status', 'Assigned');

        

        // Verify that case fields were NOT updated
        Case result = [SELECT TAT_Start__c, EntitlementId FROM Case WHERE Id = :testCase.Id];
        System.assertEquals(null, result.TAT_Start__c, 'TAT_Start__c should not be set');
        System.assertEquals(null, result.EntitlementId, 'EntitlementId should not be set');
    }
}