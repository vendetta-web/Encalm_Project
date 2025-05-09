@isTest
private class CancellationPolicyServiceTest {
    static Id pricebookId;

    @testSetup
    static void setupData() {
        // Create Account
        Account acc = new Account(
            Name = 'Test Account',
            BillingState = 'Maharashtra',
            GST_Registration_Type__c = 'Register as Normal taxpayer'
        );
        insert acc;

        // Create Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            AccountId = acc.Id,
            Date_of_Arrival__c = String.valueOf(Date.today().addDays(-1)),
            Date_of_Departure__c = String.valueOf(Date.today().addDays(-1)),
            STA_Time__c = '12:00',
            STD_Time__c = '15:00',
            Number_of_Adults__c = 2,
            Number_of_Children__c = 1,
            Number_of_Infants__c = 1
        );
        insert opp;

        pricebookId = Test.getStandardPricebookId();

        Product2 prod = new Product2(Name = 'Test Product', Family = 'Add Ons', IsActive = true);
        insert prod;

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        // Create OpportunityLineItem
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 5000,
            Status__c = 'Active'
        );
        insert oli;

        // Create Passenger_Details__c
        Passenger_Details__c pax1 = new Passenger_Details__c(
            Name = 'Pax 1',
            Passenger_Type__c = 'Adult',
            Opportunity_ID__c = opp.Id,
            Individual_Booking_Details__c = oli.Id
        );
        insert pax1;

        Passenger_Details__c pax2 = new Passenger_Details__c(
            Name = 'Pax 2',
            Passenger_Type__c = 'Adult',
            Opportunity_ID__c = opp.Id
        );
        insert pax2;

        // Create Case
        Case cse = new Case(
            Booking__c = opp.Id,
            Status = 'New'
        );
        insert cse;
    }

    @isTest
    static void testFullCancellationPreview() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];
        Test.startTest();
        CancellationPolicyService.cancellationDetailsWrapper result = CancellationPolicyService.showCancellationCharges(
            'fullCancel', null, 0, '', opp.Id, 1, false
        );
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assert(result.bookingAmount > 0);
        System.assert(result.deductedAmount >= 0);
    }

    @isTest
    static void testFullCancellationWithSubmit() {
        Opportunity opp = [SELECT Id, STA_Time__c, Date_of_Arrival__c, Departure_Service_Time__c, Date_of_Departure__c FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];
        opp.Departure_Service_Time__c = '12:00';
        opp.Date_of_Departure__c = String.valueOf(Date.today().addDays(1));
        opp.STA_Time__c = null;
        update opp;
                
        Test.startTest();
        //Test.setMock(HttpCalloutMock.class, new CancellationPolicyMock()); 
        CancellationPolicyService.cancellationDetailsWrapper result = CancellationPolicyService.showCancellationCharges(
            'fullCancel', null, 0, '', opp.Id, 1, true
        );
        Test.stopTest();

        System.assertNotEquals(null, result);
        List<OpportunityLineItem> olis = [SELECT Status__c FROM OpportunityLineItem WHERE OpportunityId = :opp.Id];
        System.assertEquals('Fully Cancelled', olis[0].Status__c);
    }

    @isTest
    static void testPartialCancellationWithSubmit() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];
        OpportunityLineItem oli = [SELECT Id, UnitPrice FROM OpportunityLineItem WHERE OpportunityId = :opp.Id LIMIT 1];

        List<Map<String, Object>> selectedOrders = new List<Map<String, Object>>();
        Map<String, Object> row = new Map<String, Object>{
            'oliId' => oli.Id,
            'unitPrice' => oli.UnitPrice,
            'packageName' => 'Package',
            'name' => 'Test Pax'
        };
        selectedOrders.add(row);

        Test.startTest();
        //Test.setMock(HttpCalloutMock.class, new CancellationPolicyMock()); 
        CancellationPolicyService.cancellationDetailsWrapper result = CancellationPolicyService.showCancellationCharges(
            'partialCancel', selectedOrders, oli.UnitPrice, 'Package', opp.Id, 1, true
        );
        Test.stopTest();

        System.assertNotEquals(null, result);
        OpportunityLineItem updatedOli = [SELECT Status__c FROM OpportunityLineItem WHERE Id = :oli.Id];
        System.assertEquals('Partially Cancelled', updatedOli.Status__c);
    }

    @isTest
    static void testGetBookingToCancel() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];

        Product2 prod = [SELECT Id, Name, Family FROM Product2 WHERE Name = 'Test Product' LIMIT 1];
        prod.Family = 'Add Ons';
        update prod;

        List<Cancellation_And_Refund__mdt> policies = [SELECT MasterLabel, Time_Frame__c,
            Charges_in_Percentage__c, Charges__c, Greater_Than__c, Less_Than__c, Package__c, Refund_Policy__c
            FROM Cancellation_And_Refund__mdt
            WHERE IsActive__c = true AND Package__c = 'Add Ons'
            ORDER BY Sort_Order__c];

        Test.startTest();
        List<CancellationPolicyService.passengerDetailsWrapper> results = CancellationPolicyService.getBookingToCancel(opp.Id);
        Test.stopTest();

        System.assertNotEquals(0, results.size(), 'Wrapper list should not be empty');
    }

    @isTest
    static void testGetCancellationPolicyAmount_WithSeeAllData() {
        List<Cancellation_And_Refund__mdt> policies = [SELECT MasterLabel, Time_Frame__c,
            Charges_in_Percentage__c, Charges__c, Greater_Than__c, Less_Than__c, Package__c, Refund_Policy__c
            FROM Cancellation_And_Refund__mdt
            WHERE IsActive__c = true
            ORDER BY Sort_Order__c];

        DateTime serviceDateTime = DateTime.now().addHours(9);
        DateTime cancellationDateTime = DateTime.now();
        Decimal bookingAmount = 1000.00;
        String packageName = 'Silver'; // Should match metadata

        Decimal refundAmount = CancellationPolicyService.getCancellationPolicyAmount(serviceDateTime, cancellationDateTime, bookingAmount, packageName);
        System.assert(refundAmount >= 0);
    }
    
    @isTest
    static void testGetCancellationPolicyAmount_WithSeeAllData1() {
        List<Cancellation_And_Refund__mdt> policies = [SELECT MasterLabel, Time_Frame__c,
            Charges_in_Percentage__c, Charges__c, Greater_Than__c, Less_Than__c, Package__c, Refund_Policy__c
            FROM Cancellation_And_Refund__mdt
            WHERE IsActive__c = true
            ORDER BY Sort_Order__c];

        DateTime serviceDateTime = DateTime.now().addHours(28);
        DateTime cancellationDateTime = DateTime.now();
        Decimal bookingAmount = 1000.00;
        String packageName = 'Silver'; // Should match metadata

        Decimal refundAmount = CancellationPolicyService.getCancellationPolicyAmount(serviceDateTime, cancellationDateTime, bookingAmount, packageName);
        System.assert(refundAmount >= 0);
    }

    @isTest
    static void testGetCancellationPolicyAmount_WithSeeAllData2() {
        List<Cancellation_And_Refund__mdt> policies = [SELECT MasterLabel, Time_Frame__c,
            Charges_in_Percentage__c, Charges__c, Greater_Than__c, Less_Than__c, Package__c, Refund_Policy__c
            FROM Cancellation_And_Refund__mdt
            WHERE IsActive__c = true AND Package__c = 'General'
            ORDER BY Sort_Order__c];

        DateTime serviceDateTime = DateTime.now().addDays(3);
        DateTime cancellationDateTime = DateTime.now();
        Decimal bookingAmount = 1000.00;
        String packageName = 'General';

        Decimal refundAmount = CancellationPolicyService.getCancellationPolicyAmount(serviceDateTime, cancellationDateTime, bookingAmount, packageName);
        Decimal generalRefund = CancellationPolicyService.getGeneralCancellationPolicyAmount(serviceDateTime, cancellationDateTime, bookingAmount);

        System.assert(refundAmount >= 0);
        System.assert(generalRefund >= 0);
    }

    @isTest
    static void testGetCancellationPolicyAmount_WithSeeAllData3() {
        List<Cancellation_And_Refund__mdt> policies = [SELECT MasterLabel, Time_Frame__c,
            Charges_in_Percentage__c, Charges__c, Greater_Than__c, Less_Than__c, Package__c, Refund_Policy__c
            FROM Cancellation_And_Refund__mdt
            WHERE IsActive__c = true AND Package__c = 'Silver' AND Less_Than__c = false
            ORDER BY Sort_Order__c];

        DateTime serviceDateTime = DateTime.now().addHours(36);
        DateTime cancellationDateTime = DateTime.now();
        Decimal bookingAmount = 1000.00;

        Decimal refundAmount = CancellationPolicyService.getGeneralCancellationPolicyAmount(serviceDateTime, cancellationDateTime, bookingAmount);
        System.assert(refundAmount >= 0);
    }
}