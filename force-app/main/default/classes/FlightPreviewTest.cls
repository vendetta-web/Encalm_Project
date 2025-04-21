/**
* @File Name : FlightPreviewTest.cls
* @Description : Test Class for FlightPreview.cls
* @Author : Maxify Development Team
* @Created Date : April 10, 2025
**/
@isTest
public class FlightPreviewTest {
    
    @testSetup
    static void setupData() {
        
        Date myDate = Date.today().addDays(5);
        DateTime dt = DateTime.newInstance(myDate, Time.newInstance(0, 0, 0, 0));
        String arrivalDate = dt.format('yyyy-MM-dd');
        
        Date myDate2 = Date.today().addDays(2);
        DateTime dt2 = DateTime.newInstance(myDate, Time.newInstance(0, 0, 0, 0));
        String departureDate = dt.format('yyyy-MM-dd');
        
        // Creating test data
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opportunity';
        opp.StageName = 'Prospecting';
        opp.CloseDate = Date.today().addDays(10);
        opp.Service_Type__c = 'Arrival';
        opp.Number_of_Adults__c = 2;
        opp.Number_of_Children__c = 1;
        opp.Number_of_Infants__c = 1;
        opp.Date_of_Arrival__c = arrivalDate;
        opp.Date_of_Departure__c = departureDate;
        opp.Service_Airport__c = 'DEL';
        opp.Arriving_Airport__c = 'BOM';
        opp.Departure_Airport__c = 'DEL';
        opp.Flight_Number_Arrival__c = 'AI101';
        opp.Flight_Number_Departure__c = 'AI202';
        opp.Flight_Type__c = 'International';
        opp.STA_Time__c = '10:00 AM';
        opp.STD_Time__c = '2:00 PM';
        opp.Sector__c = 'Sector A';
        
        insert opp;      
        
    }
    @isTest
    static void testGetOpportunityDetails() {
        
        Opportunity opp = [Select id,Number_of_Adults__c,Service_Type__c from Opportunity where Name = 'Test Opportunity' LIMIT 1];
        Map<String, Object> fieldMap = new Map<String, Object>{
            'Number_of_Adults__c' => 4,
                'Service_Type__c' => 'Departure'
                };
                    
                    Test.startTest();
        FlightPreview.bookingWrapper wrapper = FlightPreview.getOpportunityDetails(opp.Id);
        FlightPreview.saveData(opp.Id, fieldMap);
        try {
            FlightPreview.saveData(null, fieldMap);
            System.assert(false, 'Exception due to null ID');
        } catch (AuraHandledException e) {
            System.debug('e.getMessage()>>>'+e.getMessage());
        }
        Test.stopTest();
        
        System.assertEquals(2, wrapper.NoOfAdult);
        
        Opportunity updatedOpp = [SELECT Id, Number_of_Adults__c, Service_Type__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(4, updatedOpp.Number_of_Adults__c); 
    }
}