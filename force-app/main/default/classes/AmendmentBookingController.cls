public class AmendmentBookingController {
    @AuraEnabled(cacheable=true)
    public static CurrentPackageDetailsWrapper getExistingPackage(String opportunityId){
        try {
            CurrentPackageDetailsWrapper wrp = new CurrentPackageDetailsWrapper();
            String packageName='';
            Decimal bookingAmount = 0;
            Opportunity opp = [
                SELECT STA_Time__c,STD_Time__c,Date_of_Arrival__c,Date_of_Departure__c,Amount,Departure_Service_Time__c,
                Flight_Number_Arrival__c,Flight_Number_Departure__c,
                (SELECT Id,Product2.Family,UnitPrice,PricebookEntryId FROM opportunitylineitems WHERE Status__c = 'Active' OR Status__c = 'Rescheduled') 
                FROM Opportunity
                WHERE Id=:opportunityId
                LIMIT 1
            ];

            for (opportunitylineitem oli: opp.opportunitylineitems) {
                if (oli.Product2.Family != 'Add Ons' && oli.Product2.Family != 'Surcharge') {
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
        // Query Opportunity based on OpportunityId
        Opportunity opp = [
            SELECT Name,STA_Time__c,STD_Time__c,Date_of_Arrival__c,Date_of_Departure__c,Account.Surcharge_waived_off__c,
            Account.BillingState, Service_Airport_Id__r.State__c,Service_Airport_Id__c,Account.GST_Registration_Type__c,Departure_Service_Time__c
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];
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
                // GST Calculation Logic
                calculateGstApplicable(opp, oli);
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

    
    // Method to create Opportunity Line Items
    @AuraEnabled
    public static void createOpportunityLineItems(Id opportunityId, List<Map<String, Object>> productDetails, Decimal amount) {

        // Create a list to store OpportunityLineItems
        List<OpportunityLineItem> opportunityLineItemsToInsert = new List<OpportunityLineItem>();
        List<Transaction_History__c> transactionList = new List<Transaction_History__c>();
        List<PricebookEntry> pbEntry = new List<PricebookEntry>();
        Decimal totalListPrice = 0;
        DateTime serviceDateTime;
        String dateText;
        String timeText;
        String combinedDateTimeStr;

        // Query Opportunity based on OpportunityId
        Opportunity opp = [
            SELECT Name,STA_Time__c,STD_Time__c,Date_of_Arrival__c,Date_of_Departure__c,Account.Surcharge_waived_off__c,
            Account.BillingState, Service_Airport_Id__r.State__c,Service_Airport_Id__c,Account.GST_Registration_Type__c,Departure_Service_Time__c
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];

        if (opp.STA_Time__c != null) {
            dateText=opp.Date_of_Arrival__c;
            timeText=opp.STA_Time__c;
            // Ensure timeText includes seconds
            if (timeText.length() == 5) {  // "HH:mm" format
                timeText += ':00';  // Append ":00" for seconds
            }
            combinedDateTimeStr=dateText + ' ' + timeText;
            serviceDateTime = DateTime.valueOf(combinedDateTimeStr);
        } else if (opp.Departure_Service_Time__c != null) {
            dateText=opp.Date_of_Departure__c;
            timeText=opp.Departure_Service_Time__c;// Ensure timeText includes seconds
            if (timeText.length() == 5) {  // "HH:mm" format
                timeText += ':00';  // Append ":00" for seconds
            }
            combinedDateTimeStr=dateText + ' ' + timeText;
            serviceDateTime = DateTime.valueOf(combinedDateTimeStr);
        }

        pbEntry = [
            SELECT Id, Product2Id, Product2.Name, Product2.Family, UnitPrice, Pricebook2Id, List_Price_In_Percentage__c
            FROM PricebookEntry
            WHERE Pricebook2.IsActive = true
            AND Pricebook2.IsStandard = true
            AND Product2.Family ='Surcharge'
            LIMIT 1
        ];

        for (Map<String, Object> productDetail : productDetails) {
            // Extract the values from the map
            Id productId = (Id) productDetail.get('productId');
            Id pricebookEntry = (Id) productDetail.get('pricebookEntryId');
            Decimal quantity = (Boolean) productDetail.get('isChild') ? (Decimal) productDetail.get('childCount') : (Decimal) productDetail.get('count');
            Decimal unitPrice = (Decimal) productDetail.get('unitPrice');
            Decimal discountAmount = (Decimal) productDetail.get('discountValue');

            // Safely extract pickup and drop terminals
            List<String> pickupTerminals = new List<String>();
            List<String> dropTerminals = new List<String>();

            // Safely extract and cast pickupTerminals
            if (productDetail.containsKey('pickupTerminals') && productDetail.get('pickupTerminals') != null) {
                List<Object> tempPickupTerminals = (List<Object>) productDetail.get('pickupTerminals');
                for (Object obj : tempPickupTerminals) {
                    pickupTerminals.add((String) obj); // Explicitly cast each item to String
                }
            }

            // Safely extract and cast dropTerminals
            if (productDetail.containsKey('dropTerminals') && productDetail.get('dropTerminals') != null) {
                List<Object> tempDropTerminals = (List<Object>) productDetail.get('dropTerminals');
                for (Object obj : tempDropTerminals) {
                    dropTerminals.add((String) obj); // Explicitly cast each item to String
                }
            }
            // Handle null pickupTerminals and dropTerminals by initializing as empty lists
            if (pickupTerminals == null) {
                pickupTerminals = new List<String>();
            }
            if (dropTerminals == null) {
                dropTerminals = new List<String>();
            }

            // Loop through quantity to handle multiple OLI for each product detail
                if (Math.max(pickupTerminals.size(), dropTerminals.size()) < 1) {
                    // Loop through quantity to handle multiple OLI for each product detail
                    for (Integer i = 0; i < quantity; i++) {
                        // Create a new Opportunity Line Item for packages
                        OpportunityLineItem oli = new OpportunityLineItem();
                        oli.OpportunityId = opportunityId;
                        oli.Product2Id = productId;
                        oli.Quantity = 1;
                        oli.UnitPrice = unitPrice;
                        oli.PricebookEntryId = pricebookEntry; // Link PricebookEntry to OLI
                        oli.Discount_Amount__c = discountAmount/quantity;
                        oli.Status__c = 'Active';

                        totalListPrice += unitPrice;    
                        calculateGstApplicable(opp, oli);
                        // Add the OLI to the list
                        opportunityLineItemsToInsert.add(oli);    
                    }                
                }
                String pickupTerminal ='';
                String dropTerminal='';
                for (Integer j = 0; j < Math.max(pickupTerminals.size(), dropTerminals.size()); j++) {
                    // Ensure we don't access out of bounds in case the arrays are of different lengths
                    pickupTerminal = (j < pickupTerminals.size()) ? pickupTerminals.get(j) : pickupTerminal;
                    dropTerminal = (j < dropTerminals.size()) ? dropTerminals.get(j) : dropTerminal;

                    // Create a new Opportunity Line Item for 
                    OpportunityLineItem oli = new OpportunityLineItem();
                    oli.OpportunityId = opportunityId;
                    oli.Product2Id = productId;
                    oli.Quantity = 1;
                    oli.UnitPrice = unitPrice;
                    oli.PricebookEntryId = pricebookEntry; // Link PricebookEntry to OLI
                    oli.Pickup_Terminal__c = pickupTerminal;
                    oli.Drop_Terminal__c = dropTerminal;
                    oli.Status__c = 'Active';
                    if(!pbEntry.isEmpty() && pbEntry[0].UnitPrice !=null && pbEntry[0].List_Price_In_Percentage__c && !opp.Account.Surcharge_waived_off__c) {
                        oli.Surcharge_Amount_Applied__c = PackageSelectionController.getSurchargeAmount(serviceDateTime, DateTime.now(),pbEntry[0].UnitPrice, unitPrice,  true);
                    }

                    totalListPrice += unitPrice;  
                    calculateGstApplicable(opp, oli);
                    // Add the OLI to the list
                    opportunityLineItemsToInsert.add(oli);
                }

        }

        // Insert the Opportunity Line Items and Transaction History
        try {
            
            //logic to create oli for surcharge if not in percentage
            if (!pbEntry.isEmpty() && pbEntry[0].UnitPrice !=null && !pbEntry[0].List_Price_In_Percentage__c  && !opp.Account.Surcharge_waived_off__c) {
                if (PackageSelectionController.getSurchargeAmount(serviceDateTime, DateTime.now(),pbEntry[0].UnitPrice, 0,  false) > 0) {
                    OpportunityLineItem oli = new OpportunityLineItem();
                    oli.OpportunityId = opportunityId;
                    oli.Product2Id = pbEntry[0].Product2Id;
                    oli.Quantity = 1;
                    oli.UnitPrice = pbEntry[0].UnitPrice;
                    oli.PricebookEntryId = pbEntry[0].Id; // Link PricebookEntry to OLI
                    oli.Status__c = 'Active';
                    opportunityLineItemsToInsert.add(oli);
                }
            }

            insert opportunityLineItemsToInsert;
            // Now that the records are inserted, their Ids are populated
            for (OpportunityLineItem oli : opportunityLineItemsToInsert) {
                if (oli.UnitPrice != 0) {
                    // Create the transaction record for booking
                    Transaction_History__c transactionRec = new Transaction_History__c();
                    transactionRec.Booking_Id__c = opportunityId;
                    transactionRec.List_Price__c = oli.UnitPrice;
                    transactionRec.Name = opp.Name;
                    transactionRec.Transaction_Type__c = 'Credit'; //credit when amount is received by Encalm
                    transactionRec.Order_Id__c = oli.Id; // link oli with transaction
                    transactionRec.Discount_Amount__c = oli.Discount_Amount__c; // set discount amount
                    transactionList.add(transactionRec);
                }
            }

            // Finally, insert the transaction history records
            insert transactionList;
        } catch (Exception e) {
            System.debug('Error inserting Opportunity Line Items: ' + e.getMessage());
            throw new AuraHandledException('Error in creating order summary, please show this message to admin');
        }
    }

    public static void calculateGstApplicable(Opportunity opp, OpportunityLineItem oli) {

        Decimal gstRate = 0.18;  // 18% GST
        String billingState = opp.Account.BillingState;
        String serviceAirportState = opp.Service_Airport_Id__c !=null ? opp.Service_Airport_Id__r.State__c : '';
        Boolean isNotIgst =false;
        if (opp.Account.GST_Registration_Type__c != 'Non-Resident taxable person' &&
            opp.Account.GST_Registration_Type__c != 'Special Economic Zone (SEZ) developer/unit') {
                isNotIgst = true;
            }

        //Logic for GST calculation
        Decimal totalGST = oli.UnitPrice * gstRate; // Total GST
        Decimal invoiceAmount = oli.UnitPrice - totalGST; // Invoice amount (after GST)

        // Intra-State or Inter-State logic based on Account's Billing State and Service Airport's State
        Decimal sgstAmount = 0;
        Decimal cgstAmount = 0;
        Decimal igstAmount = 0;
        
        if (billingState != null && serviceAirportState != null) {
            if (billingState.equalsIgnoreCase(serviceAirportState) && isNotIgst)  {
                // Intra-state: Split GST into SGST and CGST
                sgstAmount = totalGST / 2;
                cgstAmount = totalGST / 2;
            } else {
                // Inter-state: Apply IGST
                igstAmount = totalGST;
            }
        }
        // Set the calculated GST values on the Opportunity Line Item
        oli.Invoice_Amount__c = invoiceAmount;
        oli.SGST__c = sgstAmount;
        oli.CGST__c = cgstAmount;
        oli.IGST__c = igstAmount;        
    }
}