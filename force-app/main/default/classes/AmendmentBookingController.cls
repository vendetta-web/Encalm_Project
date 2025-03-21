public class AmendmentBookingController {
    @AuraEnabled(cacheable=true)
    public static CurrentPackageDetailsWrapper getExistingPackage(String opportunityId){
        try {
            CurrentPackageDetailsWrapper wrp = new CurrentPackageDetailsWrapper();
            String packageName='';
            Decimal bookingAmount = 0;
            Opportunity opp = [
                SELECT STA_Time__c,STD_Time__c,Date_of_Arrival__c,Date_of_Departure__c,Amount,
                Flight_Number_Arrival__c,Flight_Number_Departure__c,
                (SELECT Id,Product2.Family,UnitPrice,PricebookEntryId FROM opportunitylineitems WHERE Status__c = 'Active' OR Status__c = 'Rescheduled') 
                FROM Opportunity
                WHERE Id=:opportunityId
                LIMIT 1
            ];

            for (opportunitylineitem oli: opp.opportunitylineitems) {
                if (oli.Product2.Family != 'Add Ons') {
                    packageName = oli.Product2.Family;
                    bookingAmount += oli.UnitPrice;
                }
            }
            wrp.packageName = packageName;
            wrp.totalBookingAmount = bookingAmount;
            return wrp;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class CurrentPackageDetailsWrapper {
        @AuraEnabled public String packageName;
        @AuraEnabled public Decimal totalBookingAmount;

    }

    // Method to upgrade package
    @AuraEnabled
    public static void upgradePackage(Id opportunityId, List<Map<String, Object>> productDetails) {
        // Create a list to store OpportunityLineItems
        List<OpportunityLineItem> opportunityLineItemsToInsert = new List<OpportunityLineItem>();
        
        List<OpportunityLineItem> oliListToDelete = [SELECT Id,Product2Id,UnitPrice,PricebookEntryId,Product2.Package_Is_For__c FROM OpportunityLineItem
            WHERE OpportunityId =:opportunityId
            AND (Status__c = 'Active' OR Status__c = 'Rescheduled')
            AND Product2.Family != 'Add Ons'
            ];
        Map<String, List<OpportunityLineItem>> oliMap = new Map<String, List<OpportunityLineItem>>();
        List<Passenger_Details__c> passengersToUpdate = [SELECT Id,Individual_Booking_Details__c,Passenger_Type__c
            FROM Passenger_Details__c
            WHERE Opportunity_ID__c=:opportunityId
            ];
        for (Map<String, Object> productDetail : productDetails) {
            // Extract the values from the map
            Id productId = (Id) productDetail.get('productId');
            Id pricebookEntry = (Id) productDetail.get('pricebookEntryId');
            Decimal quantity = (Boolean) productDetail.get('isChild') ? (Decimal) productDetail.get('childCount') : (Decimal) productDetail.get('count');
            Decimal unitPrice = (Decimal) productDetail.get('unitPrice');
            String pickupTerminal = (String) productDetail.get('pickup');
            String dropTerminal = (String) productDetail.get('drop'); 
            String type = (String) productDetail.get('type'); 
            for (Integer i=0; i< quantity; i++) {
                // Create a new Opportunity Line Item
                OpportunityLineItem oli = new OpportunityLineItem();
                oli.OpportunityId = opportunityId;
                oli.Product2Id = productId;
                oli.Quantity = 1;
                oli.UnitPrice = unitPrice;
                oli.PricebookEntryId = pricebookEntry; // Link PricebookEntry to OLI
                oli.Pickup_Terminal__c = pickupTerminal;
                oli.Drop_Terminal__c = dropTerminal;
                oli.Status__c = 'Active';
                if (!oliMap.containsKey(type)) {
                    oliMap.put(type, new List<OpportunityLineItem>());
                }
                oliMap.get(type).add(oli);
                // Add the OLI to the list
                opportunityLineItemsToInsert.add(oli);
            }
        }
        // Update the Opportunity Line Items
        try {

            delete oliListToDelete;
            insert opportunityLineItemsToInsert;
            for (Passenger_Details__c pass: passengersToUpdate) {
                if(oliMap.containsKey(pass.Passenger_Type__c)) {
                    List<OpportunityLineItem> oliIds = oliMap.get(pass.Passenger_Type__c);
                     if (!oliIds.isEmpty()) {
                        // Get the first record from the list
                        OpportunityLineItem oliId = oliIds[0];                    
                        pass.Individual_Booking_Details__c = oliId.Id;
                        // Remove the used record from the list
                        oliIds.remove(0);
                        
                        // If the list is now empty, remove the key from the map to avoid future checks
                        if (oliIds.isEmpty()) {
                            oliMap.remove(pass.Passenger_Type__c);
                        }
                    }
                }
            }
            update passengersToUpdate;
        } catch (Exception e) {
            System.debug('Error inserting Opportunity Line Items: ' + e.getMessage());
            throw new AuraHandledException('Error in creating order summary, please show this message to admin');
        }
    }
}