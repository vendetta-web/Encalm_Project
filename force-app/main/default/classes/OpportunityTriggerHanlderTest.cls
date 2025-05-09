@isTest
public class OpportunityTriggerHanlderTest {
    
    @isTest
    static void testSTA_Present() {
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity - STA',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            Date_of_Arrival__c = Date.today().format(),
            STA_Time__c = '14:30'
        );
        
        Test.startTest();
        OpportunityTriggerHanlder.updateServiceDateTimeFields(new List<Opportunity>{ opp });
        Test.stopTest();

        System.assertEquals(Date.today(), opp.Service_Date__c);
        System.assertEquals(Time.newInstance(14, 30, 0, 0), opp.Service_Time__c);
    }

    @isTest
    static void testSTD_Domestic() {
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity - STD Domestic',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            Date_of_Departure__c =  Date.today().format(),
            STd_Time__c = '01:00',
            Flight_Type__c = 'Domestic'
        );
        
        Test.startTest();
        OpportunityTriggerHanlder.updateServiceDateTimeFields(new List<Opportunity>{ opp });
        Test.stopTest();

        DateTime expected = DateTime.newInstance(Date.newInstance(2025, 5, 24), Time.newInstance(1, 0, 0, 0)).addMinutes(-90);
        System.assertEquals(Date.today().addDays(-1), opp.Service_Date__c);
        System.assertEquals(expected.time(), opp.Service_Time__c);
    }

    @isTest
    static void testSTD_International() {
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity - STD Intl',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            Date_of_Departure__c =  Date.today().format(),
            STd_Time__c = '01:00',
            Flight_Type__c = 'International'
        );
        
        Test.startTest();
        OpportunityTriggerHanlder.updateServiceDateTimeFields(new List<Opportunity>{ opp });
        Test.stopTest();

        DateTime expected = DateTime.newInstance(Date.newInstance(2025, 5, 24), Time.newInstance(1, 0, 0, 0)).addHours(-3);
        System.assertEquals(Date.today().addDays(-1), opp.Service_Date__c);
        System.assertEquals(expected.time(), opp.Service_Time__c);
    }
}