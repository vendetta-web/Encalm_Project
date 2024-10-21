@isTest
public class PassengerDetailProcessorTest {

    @isTest
    static void testProcessEmailBody() {
        String emailBody = 'name: Vendetta Web, age: 25, gender: Male\n' +
                           'name: Shreya Awasthi, age: 35, gender: Female\n';

        Test.startTest();
        PassengerDetailProcessor.processEmailBody(emailBody);
        Test.stopTest();

        List<Passenger_Details__c> passengers = [SELECT Name, Age__c, Gender__c FROM Passenger_Details__c];
        System.assertEquals(2, passengers.size(), 'Should have inserted 2 passenger records.');

        Passenger_Details__c passenger1 = passengers[0];
        System.assertEquals('Vendetta Web', passenger1.Name);
        System.assertEquals(25, passenger1.Age__c);
        System.assertEquals('Male', passenger1.Gender__c);

        Passenger_Details__c passenger2 = passengers[1];
        System.assertEquals('Shreya Awasthi', passenger2.Name);
        System.assertEquals(35, passenger2.Age__c);
        System.assertEquals('Female', passenger2.Gender__c);
    }

    @isTest
    static void testProcessEmailBody_noPassengers() {
        String emailBody = 'No passenger data here.';

        Test.startTest();
        PassengerDetailProcessor.processEmailBody(emailBody);
        Test.stopTest();

        List<Passenger_Details__c> passengers = [SELECT Name, Age__c, Gender__c FROM Passenger_Details__c];
        System.assertEquals(0, passengers.size(), 'Should not have inserted any passenger records.');
    }

    @isTest
    static void testProcessEmailBody_invalidData() {
        String emailBody = 'name: Vendetta Web, age: twentyfive, gender: Male\n';

        Test.startTest();
        
            PassengerDetailProcessor.processEmailBody(emailBody);
            //System.assert(false, 'Exception should have been thrown for invalid data.');
        Test.stopTest();

        List<Passenger_Details__c> passengers = [SELECT Name, Age__c, Gender__c FROM Passenger_Details__c];
        System.assertEquals(0, passengers.size(), 'Should not have inserted any passenger records.');
    }
}