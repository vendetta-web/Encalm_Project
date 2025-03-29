public with sharing class PackageSelectionController {

    // Get products from the PricebookEntry for the Standard Pricebook (Gold, Silver, Elite, and Add-Ons)
    @AuraEnabled
    public static List<PackageWrapper> getPackages(String oppId) {
        Map<String,List<String>> packageToServiceMap = new Map<String,List<String>>();
        Decimal discountApplicable=0;
        Boolean isDiscountInPercent = false;
        if (String.isBlank(oppId)) {
            throw new AuraHandledException('Please link an airport');
        }
        Opportunity opp = [
            SELECT Id,Service_Airport__c,Sector__c,Service_Type__c,Flight_Type__c,AccountId
            FROM Opportunity
            WHERE Id=:oppId
            LIMIT 1
        ];
        //check if discount applicable
        if (opp.AccountId !=null) {
            List<Discount__c> discountList = [SELECT Id, Discount_Applicable__c, Is_Discount_In_Percentage__c 
                FROM Discount__c 
                WHERE Account__c=:opp.AccountId
                AND From__c <= TODAY 
                AND To__c >= TODAY 
                AND Is_Active__c = TRUE 
                LIMIT 1
            ];
            if (!discountList.isEmpty() && discountList !=null) {
                discountApplicable = discountList[0].Discount_Applicable__c;
                isDiscountInPercent = discountList[0].Is_Discount_In_Percentage__c;
            }
        }


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
            SELECT Id, Product2Id, Product2.Name, Product2.Family, Product2.Package_Is_For__c, UnitPrice, Pricebook2Id
            FROM PricebookEntry
            WHERE Pricebook2.IsActive = true
            AND Pricebook2.IsStandard = true
            AND Product2.Family IN ('Gold', 'Silver', 'Elite','Transit')
            AND product2.Airport__r.Airport_Code__c =:opp.Service_Airport__c
            AND product2.Flight_Type__c =:opp.Flight_Type__c
            AND Product2.Service_Type__c =:opp.Service_Type__c
            ORDER BY Product2.Package_Is_For__c, UnitPrice
        ];
        Map<String, ChildWrapper> adultToChildPriceBookMap = new Map<String, ChildWrapper>();
        Map<String, InfantWrapper> adultToInfantPriceBookMap = new Map<String, InfantWrapper>();
        for (PricebookEntry pbEntry : pricebookEntries) {
            
            List<String> allServices = new List<String>(packageToServiceMap.get('All'));
            List<String> specificService = new List<String>(packageToServiceMap.get(pbEntry.Product2.Family));
            List<String> combineService = new List<String>();
            combineService.addall(allServices);
            combineService.addall(specificService);
            PackageWrapper pckg = new PackageWrapper();
            
            pckg.packageName = pbEntry.Product2.Name;
            pckg.productId =  pbEntry.Product2Id;
            pckg.pricebookId = pbEntry.Pricebook2Id;
            pckg.showPackage = false;
            pckg.packageFamily = pbEntry.Product2.Family;
            if(pbEntry.Product2.Package_Is_For__c == 'Adult') {
                pckg.pricebookEntryId = pbEntry.Id;
                pckg.showPackage = true;
                pckg.priceTag = pbEntry.UnitPrice;
                adultToChildPriceBookMap.put(pbEntry.Product2.Family, null);
                adultToInfantPriceBookMap.put(pbEntry.Product2.Family,null);
            } else if(pbEntry.Product2.Package_Is_For__c == 'Child') {
                if(adultToChildPriceBookMap.containsKey(pbEntry.Product2.Family)) {
                    ChildWrapper wrp = new ChildWrapper();
                    wrp.priceBookEntryId = pbEntry.Id;
                    wrp.price = pbEntry.UnitPrice;
                    adultToChildPriceBookMap.put(pbEntry.Product2.Family,wrp);
                }
            } else if(pbEntry.Product2.Package_Is_For__c == 'Infant') {
                if(adultToInfantPriceBookMap.containsKey(pbEntry.Product2.Family)) {
                    InfantWrapper wrp = new InfantWrapper();
                    wrp.priceBookEntryId = pbEntry.Id;
                    wrp.price = pbEntry.UnitPrice;
                    adultToInfantPriceBookMap.put(pbEntry.Product2.Family,wrp);
                }
            }
            pckg.services = combineService; 
            pckg.childPackageWrapper = adultToChildPriceBookMap;
            pckg.infantPackageWrapper = adultToInfantPriceBookMap;            
            pckg.isDiscountInPercent = isDiscountInPercent;
            pckg.discountValue = discountApplicable;
            packageColumns.add(pckg);
        }     
        return packageColumns;
    }

    @AuraEnabled
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
        
        /*
        List<String> listOfTerminals = new List<String>();
        List<Terminal__c> terminals = [SELECT Id,Code__c from Terminal__c WHERE Airport__r.Airport_Code__c =:opp.Service_Airport__c];
        if (terminals!=null && terminals.size()>0) {
            for (Terminal__c terminal : terminals) {
                AddonWrapper pckg = new AddonWrapper();
                listOfTerminals.add(terminal.Code__c);
                pckg.terminals = listOfTerminals;
                addOnColumns.add(pckg);
            }
        }*/

        List<PricebookEntry> pricebookAddonEntries = [
            SELECT Id, Product2Id, Product2.Name, Product2.Family, UnitPrice, Pricebook2Id, Product2.Hide_Drop_Terminal__c
            FROM PricebookEntry
            WHERE Pricebook2.IsActive = TRUE
            AND Pricebook2.IsStandard = TRUE
            AND Product2.Family = 'Add Ons'
            AND product2.Airport__r.Airport_Code__c =:opp.Service_Airport__c
            AND product2.Flight_Type__c =:opp.Flight_Type__c
            AND Product2.Service_Type__c =:opp.Service_Type__c
            ORDER BY UnitPrice
        ];
        if(pricebookAddonEntries.size()<1){
            return null;
        }
        for (PricebookEntry pbEntry : pricebookAddonEntries) {
            AddonWrapper pckg = new AddonWrapper();
            pckg.addOnName = pbEntry.Product2.Name;
            pckg.addOnTag = pbEntry.UnitPrice;   
            pckg.productId =  pbEntry.Product2Id;
            pckg.pricebookEntryId =  pbEntry.Id; 
            pckg.pickupTerminal = getFlightTerminalInfo(oppId);
            pckg.dropTerminal = pbEntry.Product2.Hide_Drop_Terminal__c ? '' : getDropTerminalInfo(oppId);
            pckg.hideDropTerminal =  pbEntry.Product2.Hide_Drop_Terminal__c;
            addOnColumns.add(pckg);
        }      

        return addOnColumns;
    }

    @AuraEnabled
        public static List<Terminal__c> getTerminalInfo(String oppId){

            Opportunity opp = [
            SELECT Id,Service_Airport__c,Sector__c,Service_Type__c,Flight_Type__c
            FROM Opportunity
            WHERE Id=:oppId
            LIMIT 1
            ];

        List<Terminal__c> terminals = [SELECT Id,Code__c from Terminal__c WHERE Airport__r.Airport_Code__c =:opp.Service_Airport__c ORDER BY Code__c];
        
            return terminals;
        }
        @AuraEnabled
        public static String getFlightTerminalInfo(String oppId) {
            Opportunity opp = [
            SELECT Id,Arriving_Flight_Schedule__c,Departure_Flight_Schedule__c,
            Departure_Flight_Schedule__r.Departure_Terminal__c,Departure_Flight_Schedule__r.Departure_Terminal__r.Code__c,
            Arriving_Flight_Schedule__r.Arrival_Terminal__c,Arriving_Flight_Schedule__r.Arrival_Terminal__r.Code__c
            FROM Opportunity
            WHERE Id=:oppId
            LIMIT 1
            ];
            if (opp.Arriving_Flight_Schedule__c !=null && opp.Arriving_Flight_Schedule__r.Arrival_Terminal__c !=null) {
                return  opp.Arriving_Flight_Schedule__r.Arrival_Terminal__r.Code__c !=null ? opp.Arriving_Flight_Schedule__r.Arrival_Terminal__r.Code__c : '';
            } else if (opp.Departure_Flight_Schedule__c !=null && opp.Departure_Flight_Schedule__r.Departure_Terminal__c!=null){
                return  opp.Departure_Flight_Schedule__r.Departure_Terminal__r.Code__c !=null ? opp.Departure_Flight_Schedule__r.Departure_Terminal__r.Code__c : ''; 
            }
            return '';
        }
        @AuraEnabled
        public static String getDropTerminalInfo(String oppId) {
            List<Opportunity> oppList = new List<Opportunity>();
            oppList = [
            SELECT Id,Arriving_Flight_Schedule__c,Departure_Flight_Schedule__c,
            Departure_Flight_Schedule__r.Departure_Terminal__c, Departure_Flight_Schedule__r.Departure_Terminal__r.Code__c,
            Arriving_Flight_Schedule__r.Arrival_Terminal__c
            FROM Opportunity
            WHERE Id=:oppId
            AND Service_Type__c ='Transit'
            LIMIT 1
            ];
            if (!oppList.isEmpty() && oppList[0].Departure_Flight_Schedule__c !=null && oppList[0].Departure_Flight_Schedule__r.Departure_Terminal__c!=null){
                return  oppList[0].Departure_Flight_Schedule__r.Departure_Terminal__r.Code__c !=null ? oppList[0].Departure_Flight_Schedule__r.Departure_Terminal__r.Code__c : ''; 
            }
            return '';
        }

    @AuraEnabled
    public static passengerWrapper getOpportunityDetails(Id opportunityId) {
        // Fetch Opportunity record with related fields for adults, children, and infants
        Opportunity opp =  [SELECT Id, 
                       Number_of_Adults__c, 
                       Number_of_Children__c, 
                       Number_of_Infants__c,
                       Date_of_Arrival__c,
                       Date_of_Departure__c,
                       Service_Airport__c,
                       Flight_Number_Arrival__c,
                       Service_Type__c,
                       Flight_Number_Departure__c,(SELECT Id FROM OpportunityLineItems)
                FROM Opportunity 
                WHERE Id = :opportunityId 
                LIMIT 1];
        passengerWrapper pasWrp = new passengerWrapper();
        pasWrp.NoOfAdult = opp.Number_of_Adults__c;
        pasWrp.NoOfChild = opp.Number_of_Children__c;
        pasWrp.NoOfInfant = opp.Number_of_Infants__c;
        pasWrp.serviceAirport = opp.Service_Airport__c;
        pasWrp.flightNumber = opp.Service_Type__c =='Transit' ? opp.Flight_Number_Arrival__c + ' / '+ opp.Flight_Number_Departure__c : opp.Flight_Number_Arrival__c != null ? 
                                opp.Flight_Number_Arrival__c : 
                                opp.Flight_Number_Departure__c != null ?
                                opp.Flight_Number_Departure__c : '';                                
        pasWrp.flightDate = opp.Service_Type__c =='Transit' ?  opp.Date_of_Arrival__c + ' / '+ opp.Date_of_Departure__c : opp.Date_of_Arrival__c != null ? 
                                opp.Date_of_Arrival__c : 
                                opp.Date_of_Departure__c != null ?
                                opp.Date_of_Departure__c : '';
        return pasWrp;
    }

    @AuraEnabled
    public static void savePassengerDetails(List<Map<String, Object>> passengerData, Id opportunityId) {


        List<Passenger_Details__c> passengerDetailsList = new List<Passenger_Details__c>();
        // Create a Map directly from the query result
        Map<Id, String> opportunityMap = new Map<Id, String>();// Initialize a Map to store Record_Id__c as key and Description__c as value
        List<OpportunityLineItem> oliList = [SELECT Id,Product2.Package_Is_For__c 
            FROM OpportunityLineItem
            WHERE OpportunityId =:opportunityId
            AND Status__c = 'Active'
            AND Id NOT IN (
                SELECT Individual_Booking_Details__c
                FROM Passenger_Details__c
            )
            ORDER BY CreatedDate DESC];
        //Delete existing passengers and create new list if updates are made
        List<Passenger_Details__c> passengersToDelete = [SELECT Id FROM Passenger_Details__c WHERE Opportunity_ID__c=:opportunityId];
        
        if (passengersToDelete!=null && passengersToDelete.size()>0) {
            Delete passengersToDelete;
        } 
        Map<String, String> typeToOliIdMap = new Map<String, String>();
        // Create a map to store lists of passengers by their 'Valid_For' field value
        Map<String, List<Id>> oliMap = new Map<String, List<Id>>();
        // Iterate over the OpportunityLineItem object records and populate the map
        for (OpportunityLineItem oli : oliList) {
            //typeToOliIdMap.put(oli.Product2.Package_Is_For__c, oli.Id);
            if (!oliMap.containsKey(oli.Product2.Package_Is_For__c)) {
            	oliMap.put(oli.Product2.Package_Is_For__c, new List<Id>());
        	}
        	oliMap.get(oli.Product2.Package_Is_For__c).add(oli.Id);
        }
        for (Map<String, Object> guest : passengerData) {
            Passenger_Details__c passenger = new Passenger_Details__c();
            passenger.Name = (String) guest.get('firstname') + ' ' + (String) guest.get('lastname');
            passenger.Opportunity_ID__c = opportunityId;
            passenger.Title__c = (String) guest.get('title');
            passenger.First_Name__c = (String) guest.get('firstname');
            passenger.Last_Name__c = (String) guest.get('lastname');
            passenger.Gender__c = (String) guest.get('gender');
            String ageStr = (String) guest.get('age');
    		Integer age =  ageStr != null ? Integer.valueOf(ageStr) : null;  // Convert the String to Integer
   			passenger.Age__c = age;
            passenger.Designation__c = (String) guest.get('designation');
            passenger.Travel_Class__c = (String) guest.get('travelclass');
            passenger.Travel_PNR_No__c = (String) guest.get('travelpnrno');
            passenger.Designation__c = (String) guest.get('designation');
            passenger.Nationalities__c = (String) guest.get('nationality');
            passenger.Passport_Govt_Id__c = (String) guest.get('passportnumber');
            passenger.Mobile__c = (String) guest.get('phone');
            passenger.Passenger_Type__c = (String) guest.get('type');
            if(oliMap.containsKey((String) guest.get('type'))) {
               List<Id> oliIds = oliMap.get((String) guest.get('type'));
                if (!oliIds.isEmpty()) {
                // Get the first Id from the list
                Id oliId = oliIds[0];
                
                // Now, link this Passenger_Details__c record to the OpportunityLineItem
                passenger.Individual_Booking_Details__c = oliId;
                
                // Remove the used Id from the list
                oliIds.remove(0);
                
                // If the list is now empty, remove the key from the map to avoid future checks
                if (oliIds.isEmpty()) {
                    oliMap.remove((String) guest.get('type'));
                }
            }
            }
            passengerDetailsList.add(passenger);
        }
        // Insert the Opportunity Line Items
        try { 
            insert passengerDetailsList;
        } catch (Exception e) {
            System.debug('Error inserting Passenger_Details__c records: ' + e.getMessage());
            throw new AuraHandledException('Error in creating guest data, please show this message to admin');
        }
    }

    @AuraEnabled
    public static void savePlacardDetails(List<Map<String, Object>> placardData, Id opportunityId) {
        List<Placard__c> placardList = new List<Placard__c>();
        
        for (Map<String, Object> guest : placardData) {
            Placard__c plc = new Placard__c();
            plc.Name = (String) guest.get('firstname') + ' ' + (String) guest.get('lastname');
            plc.Opportunity_ID__c = opportunityId;
            plc.Title__c = (String) guest.get('title');
            plc.First_Name__c = (String) guest.get('firstname');
            plc.Last_Name__c = (String) guest.get('lastname');
            plc.Mobile_Number__c = (String) guest.get('phone');
            
            placardList.add(plc);
        }
        try { 
            insert placardList;
        } catch (Exception e) {
            System.debug('Error inserting Placard__c records: ' + e.getMessage());
            throw new AuraHandledException('Error in creating Placard data, please show this message to admin');
        }
    }

    // Method to create Opportunity Line Items
    @AuraEnabled
    public static void createOpportunityLineItems(Id opportunityId, List<Map<String, Object>> productDetails, Decimal amount) {

        //delete existing oli if any
        List<OpportunityLineItem> oliToDelete = [SELECT Id FROM OpportunityLineItem WHERE opportunityId=: opportunityId];
        Delete oliToDelete;
        //delete existing transactions if any
        List<Transaction_History__c > TransactionsToDelete = [SELECT Id FROM Transaction_History__c WHERE Booking_Id__c =: opportunityId];
        Delete TransactionsToDelete;
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
            SELECT Name,STA_Time__c,STD_Time__c,Date_of_Arrival__c,Date_of_Departure__c,Account.Surcharge_waived_off__c
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
        } else if (opp.STD_Time__c != null) {
            dateText=opp.Date_of_Departure__c;
            timeText=opp.STD_Time__c;// Ensure timeText includes seconds
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
                        oli.Status__c = 'Active';

                        totalListPrice += unitPrice;    

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
                        oli.Surcharge_Amount_Applied__c = getSurchargeAmount(serviceDateTime, DateTime.now(),pbEntry[0].UnitPrice, unitPrice,  true);
                    }

                    totalListPrice += unitPrice;  
                    // Add the OLI to the list
                    opportunityLineItemsToInsert.add(oli);
                }

        }

        // Insert the Opportunity Line Items and Transaction History
        try {
            
            //logic to create oli for surcharge if not in percentage
            if (!pbEntry.isEmpty() && pbEntry[0].UnitPrice !=null && !pbEntry[0].List_Price_In_Percentage__c  && !opp.Account.Surcharge_waived_off__c) {
                if (getSurchargeAmount(serviceDateTime, DateTime.now(),pbEntry[0].UnitPrice, 0,  false) > 0) {
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
                    transactionRec.Transaction_Type__c = 'Credit';
                    transactionRec.Order_Id__c = oli.Id; // link oli with transaction
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

    //Method for surcharge calculation if in percentage
    public static Decimal getSurchargeAmount(DateTime serviceDateTime, DateTime bookingDateTime, Decimal surchargeAmountOrPercent, Decimal bookingAmount, Boolean isAmountInPercent) {

        Long hoursDifference = serviceDateTime.getTime() - bookingDateTime.getTime();
        hoursDifference = hoursDifference / (1000 * 60 * 60);  // Convert milliseconds to hours
        
        //get the metadata for surcharge
        Booking_Validation_Parameters__mdt surchargeMetadataRecord = Booking_Validation_Parameters__mdt.getInstance('ADL_MGZjMjE0M');
        if (surchargeMetadataRecord != null &&
            surchargeMetadataRecord.Surcharge_Applicable_Hours_Within__c !=null && 
            hoursDifference < surchargeMetadataRecord.Surcharge_Applicable_Hours_Within__c) {
                if (isAmountInPercent) {
                    return bookingAmount + (bookingAmount * (surchargeAmountOrPercent/ 100));
                } else {
                    return surchargeAmountOrPercent;
                } 
        } else {
            return 0;
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
        public Id pricebookId;
        @AuraEnabled
        public Map<String, ChildWrapper> childPackageWrapper;
        @AuraEnabled
        public Map<String, InfantWrapper> infantPackageWrapper;
        @AuraEnabled
        public Boolean showPackage;
        @AuraEnabled
        public List<String> services {get;set;}
        @AuraEnabled
        public String packageFamily;
        @AuraEnabled
        public Decimal discountValue;
        @AuraEnabled
        public Boolean isDiscountInPercent;

    }
    public class ChildWrapper {
        @AuraEnabled
        public String priceBookEntryId;
        @AuraEnabled
        public Decimal price;
    }
    public class InfantWrapper {
        @AuraEnabled
        public String priceBookEntryId;
        @AuraEnabled
        public Decimal price;
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
        @AuraEnabled
        public String pickupTerminal;
        @AuraEnabled
        public String dropTerminal;
        @AuraEnabled
        public Boolean hideDropTerminal;

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