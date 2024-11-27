public with sharing class PackageSelectionController {

    // Get products from the PricebookEntry for the Standard Pricebook (Gold, Silver, Elite, and Add-Ons)
    @AuraEnabled(cacheable=true)
    public static List<PricebookEntry> getPackagesAndAddons() {
        List<PricebookEntry> pricebookEntries = [
            SELECT Id, Product2Id, Product2.Name, Product2.Family, UnitPrice, Pricebook2Id
            FROM PricebookEntry
            WHERE Pricebook2.IsActive = TRUE
            AND Pricebook2.IsStandard = TRUE
            AND (Product2.Family IN ('Gold', 'Silver', 'Elite') 
                 OR Product2.Family = 'Add-On')
        ];
        return pricebookEntries;
    }
}