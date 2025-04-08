/**
* @File Name : AmendmentBookingControllerTest.cls
* @Description : Test Class for AmendmentBookingController.cls
* @Author : Abhishek
* @Last Modified By : Abhishek
* @Last Modified On : April 08, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | April 08, 2025 |  Abhishek | Initial Version
**/

@isTest
public class AmendmentBookingControllerTest {
    
    @testSetup
    static void setupData() {
         
        // Create Products
        Product2 prod1 = new Product2(Name = 'Test Package', Family = 'Standard Package', isActive = true);
        Product2 prod2 = new Product2(Name = 'Test Add-On', Family = 'Add Ons', isActive = true);
        insert new List<Product2>{prod1, prod2};
            
            // Create Pricebook Entries
            PricebookEntry pbe1 = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = prod1.Id,
                UnitPrice = 1000,
                IsActive = true,
                UseStandardPrice = false
            );
        PricebookEntry pbe2 = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = prod2.Id,
            UnitPrice = 200,
            IsActive = true,
            UseStandardPrice = false
        );
        insert new List<PricebookEntry>{pbe1, pbe2};
            
            // Create Opportunity
            Opportunity opp = new Opportunity(
                Name = 'Test Opp',
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(10),
                Amount = 1000
            );
        insert opp;
        
        // Create OpportunityLineItems
        OpportunityLineItem oli1 = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Quantity = 1,
            UnitPrice = 1000,
            PricebookEntryId = pbe1.Id,
            Status__c = 'Active'
        );
        insert oli1;
        
        // Create Passenger record
        Passenger_Details__c pass = new Passenger_Details__c(
            Opportunity_ID__c = opp.Id,
            Passenger_Type__c = 'Adult'
        );
        insert pass;
    }
    
    @isTest
    static void testGetExistingPackage() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        AmendmentBookingController.CurrentPackageDetailsWrapper result = AmendmentBookingController.getExistingPackage(opp.Id);
        try {
            AmendmentBookingController.getExistingPackage(null);
            System.assert(false, 'Expected an exception to be thrown');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage() != null, 'Exception message should not be null');
            System.debug('Caught expected exception: ' + e.getMessage());
        }
        Test.stopTest();
        
        System.assertNotEquals(null, result);
        System.assertNotEquals(null, result.packageName);
        System.assert(result.totalBookingAmount > 0);
    }
    
    @isTest
    static void testUpgradePackage() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Product2 product = [SELECT Id FROM Product2 WHERE Name = 'Test Package' LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2Id = :product.Id LIMIT 1];
        
        List<Map<String, Object>> productDetails = new List<Map<String, Object>>();
        Map<String, Object> prodDetail = new Map<String, Object>{
            'productId' => product.Id,
                'pricebookEntryId' => pbe.Id,
                'count' => 1,
                'unitPrice' => 1200,
                'pickup' => 'Terminal A',
                'drop' => 'Terminal B',
                'type' => 'Adult',
                'isChild' => false
                };
                    productDetails.add(prodDetail);
        
        Test.startTest();
        AmendmentBookingController.upgradePackage(opp.Id, productDetails);
        try {
            AmendmentBookingController.upgradePackage(null, productDetails);
            System.assert(false, 'Expected an exception to be thrown');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage() != null, 'Exception message should not be null');
            System.debug('Caught expected exception: ' + e.getMessage());
        }
        Test.stopTest();
        
        List<OpportunityLineItem> oliList = [SELECT Id, OpportunityId FROM OpportunityLineItem WHERE OpportunityId = :opp.Id];
        System.assert(!oliList.isEmpty(), 'OLIs should be created after upgrade');
        
        List<Passenger_Details__c> passengers = [SELECT Id, Individual_Booking_Details__c FROM Passenger_Details__c WHERE Opportunity_ID__c = :opp.Id];
        System.assertNotEquals(null, passengers[0].Individual_Booking_Details__c, 'Booking details should be linked');
    }
}