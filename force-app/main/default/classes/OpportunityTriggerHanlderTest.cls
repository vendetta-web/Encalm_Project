@isTest
public class OpportunityTriggerHanlderTest {
    
    @isTest
    static void testSTA_Present() {
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity - STA',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            Date_of_Arrival__c = String.valueOf(Date.today()),
            STA_Time__c = '14:30'
        );
        
        Test.startTest();
        OpportunityTriggerHanlder.updateServiceDateTimeFields(new List<Opportunity>{ opp });
        Test.stopTest();
    }

    @isTest
    static void testSTD_Domestic() {
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity - STD Domestic',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            Date_of_Departure__c =  String.valueOf(Date.today()),
            STd_Time__c = '01:00',
            Flight_Type__c = 'Domestic'
        );
        
        Test.startTest();
        OpportunityTriggerHanlder.updateServiceDateTimeFields(new List<Opportunity>{ opp });
        Test.stopTest();

    }

    @isTest
    static void testSTD_International() {
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity - STD Intl',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            Date_of_Departure__c =  String.valueOf(Date.today()),
            STd_Time__c = '01:00',
            Flight_Type__c = 'International'
        );
        
        Test.startTest();
        OpportunityTriggerHanlder.updateServiceDateTimeFields(new List<Opportunity>{ opp });
        Test.stopTest();

    }
}