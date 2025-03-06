public with sharing class CustomPicklistController {
    @AuraEnabled(cacheable=true)
    public static List<String> getNationalityPicklistValues() {
        // Get the picklist values for the custom field "Nationality" on the Contact object
        List<Schema.PicklistEntry> picklistEntries = Schema.SObjectType.Passenger_Details__c.fields.Nationalities__c.getPicklistValues();
        
        // Create a list to store the values
        List<String> picklistValues = new List<String>();

        for (Schema.PicklistEntry entry : picklistEntries) {
            picklistValues.add(entry.getLabel()); // Add the label to the list
        }

        return picklistValues;
    }
}