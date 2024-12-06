public with sharing class PackageSelectionController {

    // Get products from the PricebookEntry for the Standard Pricebook (Gold, Silver, Elite, and Add-Ons)
    @AuraEnabled(cacheable=true)
    public static List<PackageWrapper> getPackages(String oppId) {
        Map<String,List<String>> packageToServiceMap = new Map<String,List<String>>();
        if (String.isBlank(oppId)) {
            throw new AuraHandledException('Please link an airport');
        }
        Opportunity opp = [
            SELECT Id,Service_Airport__c,Sector__c,Service_Type__c,Flight_Type__c
            FROM Opportunity
            WHERE Id=:oppId
            LIMIT 1
            ];
        List<PackageWrapper> packageColumns = new List<PackageWrapper>();

        List<Package__mdt> packageRecordList = 
            [SELECT  Flight_Type__c, Package_Type__c, Service__r.Service_Name__c,
            Service_Airport__r.MasterLabel, Service_Type__c
            FROM Package__mdt 
            WHERE Service_Airport__r.MasterLabel =:opp.Service_Airport__c
            AND (Flight_Type__c=:opp.Flight_Type__c
            OR Flight_Type__c ='Both')
            AND Service_Type__c =:opp.Service_Type__c
            ];

        // Iterate over package records and access fields
        for (Package__mdt pckg : packageRecordList) {
            if (!packageToServiceMap.containsKey(pckg.Package_Type__c)) {
                packageToServiceMap.put(pckg.Package_Type__c, new List<String>());
            }
            packageToServiceMap.get(pckg.Package_Type__c).add(pckg.Service__r.Service_Name__c);
        }

        List<PricebookEntry> pricebookEntries = [
            SELECT Id, Product2Id, Product2.Name, Product2.Family, UnitPrice, Pricebook2Id
            FROM PricebookEntry
            WHERE Pricebook2.IsActive = TRUE
            AND Pricebook2.IsStandard = TRUE
            AND Product2.Family IN ('Gold', 'Silver', 'Elite')
            AND product2.Airport__r.Airport_Code__c =:opp.Service_Airport__c
            AND product2.Flight_Type__c =:opp.Flight_Type__c
            AND Product2.Service_Type__c =:opp.Service_Type__c
            ORDER BY UnitPrice
        ];

        for (PricebookEntry pbEntry : pricebookEntries) {
            List<String> allServices = new List<String>(packageToServiceMap.get('All'));
            List<String> specificService = new List<String>(packageToServiceMap.get(pbEntry.Product2.Family));
            List<String> combineService = new List<String>();
            combineService.addall(allServices);
            combineService.addall(specificService);
            PackageWrapper pckg = new PackageWrapper();
            pckg.packageName = pbEntry.Product2.Name;
            pckg.priceTag = pbEntry.UnitPrice;
            pckg.productId =  pbEntry.Product2Id;
            pckg.pricebookEntryId =  pbEntry.Id; 
            pckg.services = combineService;           

            packageColumns.add(pckg);
        }        
        
        return packageColumns;
    }

    @AuraEnabled(cacheable=true)
    public static List<AddonWrapper> getAddons(String oppId) {
        Map<String,List<String>> packageToServiceMap = new Map<String,List<String>>();
        if (String.isBlank(oppId)) {
            throw new AuraHandledException('Please link an airport');
        }
        Opportunity opp = [
            SELECT Id,Service_Airport__c,Sector__c,Service_Type__c,Flight_Type__c
            FROM Opportunity
            WHERE Id=:oppId
            LIMIT 1
            ];
        List<AddonWrapper> addOnColumns = new List<AddonWrapper>();

        List<PricebookEntry> pricebookAddonEntries = [
            SELECT Id, Product2Id, Product2.Name, Product2.Family, UnitPrice, Pricebook2Id
            FROM PricebookEntry
            WHERE Pricebook2.IsActive = TRUE
            AND Pricebook2.IsStandard = TRUE
            AND Product2.Family = 'Add Ons'
            AND product2.Airport__r.Airport_Code__c =:opp.Service_Airport__c
            AND product2.Flight_Type__c =:opp.Flight_Type__c
            AND Product2.Service_Type__c =:opp.Service_Type__c
            ORDER BY UnitPrice
        ];
        
        for (PricebookEntry pbEntry : pricebookAddonEntries) {
            AddonWrapper pckg = new AddonWrapper();
            pckg.addOnName = pbEntry.Product2.Name;
            pckg.addOnTag = pbEntry.UnitPrice;   
            pckg.productId =  pbEntry.Product2Id;
            pckg.pricebookEntryId =  pbEntry.Id; 

            addOnColumns.add(pckg);
        }      

        return addOnColumns;
    }

    @AuraEnabled(cacheable=true)
    public static passengerWrapper getOpportunityDetails(Id opportunityId) {
        // Fetch Opportunity record with related fields for adults, children, and infants
        Opportunity opp =  [SELECT Id, 
                       Number_of_Adults__c, 
                       Number_of_Children__c, 
                       Number_of_Infants__c,
                       Date_of_Arrival__c,
                       Service_Airport__c,
                       Flight_Number__c
                FROM Opportunity 
                WHERE Id = :opportunityId 
                LIMIT 1];
        passengerWrapper pasWrp = new passengerWrapper();
        pasWrp.NoOfAdult = opp.Number_of_Adults__c;
        pasWrp.NoOfChild = opp.Number_of_Children__c;
        pasWrp.NoOfInfant = opp.Number_of_Infants__c;
        pasWrp.serviceAirport = opp.Service_Airport__c;
        pasWrp.flightNumber = opp.Flight_Number__c;
        pasWrp.flightDate = opp.Date_of_Arrival__c;
        return pasWrp;
    }

    @AuraEnabled
    public static void savePassengerDetails(List<Map<String, Object>> passengerData, Id opportunityId) {
        List<Passenger_Details__c> passengerDetailsList = new List<Passenger_Details__c>();
        for (Map<String, Object> guest : passengerData) {
            Passenger_Details__c passenger = new Passenger_Details__c();
            passenger.Opportunity_ID__c = opportunityId;
            passenger.Title__c = (String) guest.get('title');
            passenger.First_Name__c = (String) guest.get('firstName');
            passenger.Last_Name__c = (String) guest.get('lastName');
            passenger.Gender__c = (String) guest.get('gender');
            passenger.Age__c = (Integer) guest.get('age');
            passenger.Designation__c = (String) guest.get('designation');
            passenger.Travel_Class__c = (String) guest.get('travelClass');
            passenger.Travel_PNR_No__c = (String) guest.get('pnrNo');
            passenger.Passenger_Type__c = (String) guest.get('type');
            passengerDetailsList.add(passenger);
        }
        insert passengerDetailsList;
    }


    // Method to create Opportunity Line Items
    @AuraEnabled
    public static void createOpportunityLineItems(Id opportunityId, List<Map<String, Object>> productDetails, Decimal amount) {
        // Create a list to store OpportunityLineItems
        List<OpportunityLineItem> opportunityLineItemsToInsert = new List<OpportunityLineItem>();
        //update opportunity
        /*Opportunity opp = [SELECT Id,Amount,CurrencyIsoCode FROM Opportunity WHERE Id=:opportunityId LIMIT 1];
        if (opp.CurrencyIsoCode == null) {
            throw new AuraHandledException('The Opportunity does not have a valid Currency Code.');
        }
        opp.Amount = amount;
        update opp;*/
        // Loop through the productDetails array to create OLI records
        for (Map<String, Object> productDetail : productDetails) {
            // Extract the values from the map
            Id productId = (Id) productDetail.get('productId');
            Id pricebookEntry = (Id) productDetail.get('pricebookEntryId');
            Decimal quantity = (Decimal) productDetail.get('count');
            Decimal unitPrice = (Decimal) productDetail.get('unitPrice');
            
            // Get the PricebookEntry for the given productId and pricebookId
           // PricebookEntry pricebookEntry = [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :pricebookId AND Product2Id = :productId LIMIT 1];

            // Create a new Opportunity Line Item
            OpportunityLineItem oli = new OpportunityLineItem();
            oli.OpportunityId = opportunityId;
            oli.Product2Id = productId;
            oli.Quantity = quantity;
            oli.UnitPrice = unitPrice;
            oli.PricebookEntryId = pricebookEntry; // Link PricebookEntry to OLI

            // Add the OLI to the list
            opportunityLineItemsToInsert.add(oli);
        }

        // Insert the Opportunity Line Items
        try {
            insert opportunityLineItemsToInsert;
            System.debug('Opportunity Line Items created successfully.');
        } catch (Exception e) {
            System.debug('Error inserting Opportunity Line Items: ' + e.getMessage());
            throw new AuraHandledException('Error creating Opportunity Line Items: ' + e.getMessage());
        }
    }

    public class PackageWrapper {
        @AuraEnabled
        public String packageName;
        @AuraEnabled
        public Decimal priceTag;
        @AuraEnabled
        public Id productId;
        @AuraEnabled
        public Id pricebookEntryId;
        @AuraEnabled
        public List<String> services {get;set;}
    }
    public class AddonWrapper {
        @AuraEnabled
        public String addOnName;
        @AuraEnabled
        public Decimal addOnTag;
        @AuraEnabled
        public Id productId;
        @AuraEnabled
        public Id pricebookEntryId;
    }
    public class passengerWrapper {
        @AuraEnabled
        public Decimal NoOfAdult;
        @AuraEnabled
        public Decimal NoOfChild;
        @AuraEnabled
        public Decimal NoOfInfant;
        @AuraEnabled
        public String serviceAirport;
        @AuraEnabled
        public String flightNumber;
        @AuraEnabled
        public String flightDate;
    }
}