public with sharing class PackageSelectionController {

    // Get products from the PricebookEntry for the Standard Pricebook (Gold, Silver, Elite, and Add-Ons)
    @AuraEnabled(cacheable=true)
    public static List<PackageWrapper> getPackages(String oppId) {
        Map<String,List<String>> packageToServiceMap = new Map<String,List<String>>();
        if (String.isBlank(oppId)) {
            throw new AuraHandledException('Please link an airport');
        }
        Opportunity opp = [
            SELECT Id,Arriving_Airport__c,Sector__c,Service_Type__c,Flight_Type__c
            FROM Opportunity
            WHERE Id=:oppId
            LIMIT 1
            ];
        List<PackageWrapper> packageColumns = new List<PackageWrapper>();

        List<Package__mdt> packageRecordList = 
            [SELECT  Flight_Type__c, Package_Type__c, Service__r.Service_Name__c,
            Service_Airport__r.MasterLabel, Service_Type__c
            FROM Package__mdt 
            WHERE Service_Airport__r.MasterLabel =:opp.Arriving_Airport__c
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
            AND product2.Airport__r.Airport_Code__c =:opp.Arriving_Airport__c
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
            SELECT Id,Arriving_Airport__c,Sector__c,Service_Type__c,Flight_Type__c
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
            AND product2.Airport__r.Airport_Code__c =:opp.Arriving_Airport__c
            AND product2.Flight_Type__c =:opp.Flight_Type__c
            AND Product2.Service_Type__c =:opp.Service_Type__c
            ORDER BY UnitPrice
        ];
        
        for (PricebookEntry pbEntry : pricebookAddonEntries) {
            AddonWrapper pckg = new AddonWrapper();
            pckg.addOnName = pbEntry.Product2.Name;
            pckg.addOnTag = pbEntry.UnitPrice;          

            addOnColumns.add(pckg);
        }      

        return addOnColumns;
    }
    public class PackageWrapper {
        @AuraEnabled
        public String packageName;
        @AuraEnabled
        public Decimal priceTag;
        @AuraEnabled
        public List<String> services {get;set;}
    }
    public class AddonWrapper {
        @AuraEnabled
        public String addOnName;
        @AuraEnabled
        public Decimal addOnTag;
    }
}