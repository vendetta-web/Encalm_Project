public with sharing class PackageSelectionController {

    // Get products from the PricebookEntry for the Standard Pricebook (Gold, Silver, Elite, and Add-Ons)
    @AuraEnabled
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

            packageColumns.add(pckg);
        }  
        System.debug('pack>> '+packageColumns);    
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
            pckg.dropTerminal = getDropTerminalInfo(oppId);
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
            Id terminalId;
            Opportunity opp = [
            SELECT Id,Arriving_Flight_Schedule__c,Departure_Flight_Schedule__c,
            Departure_Flight_Schedule__r.Departure_Terminal__c,
            Arriving_Flight_Schedule__r.Arrival_Terminal__c
            FROM Opportunity
            WHERE Id=:oppId
            LIMIT 1
            ];
            if (opp.Arriving_Flight_Schedule__c !=null) {
                terminalId = opp.Arriving_Flight_Schedule__r.Arrival_Terminal__c;
                Terminal__c terminal = [SELECT Id,Code__c from Terminal__c WHERE Id=: terminalId LIMIT 1];    
                return terminal.Code__c!=null ? terminal.Code__c : '';
            } else if (opp.Departure_Flight_Schedule__c !=null){
                terminalId= opp.Departure_Flight_Schedule__r.Departure_Terminal__c;
                Terminal__c terminal = [SELECT Id,Code__c from Terminal__c WHERE Id=: terminalId LIMIT 1]; 
                return terminal.Code__c!=null ? terminal.Code__c : ''; 
            }
            return '';
        }
        @AuraEnabled
        public static String getDropTerminalInfo(String oppId) {
            Id terminalId;
            Opportunity opp = [
            SELECT Id,Arriving_Flight_Schedule__c,Departure_Flight_Schedule__c,
            Departure_Flight_Schedule__r.Departure_Terminal__c,
            Arriving_Flight_Schedule__r.Arrival_Terminal__c
            FROM Opportunity
            WHERE Id=:oppId
            LIMIT 1
            ];
            if (opp.Departure_Flight_Schedule__c !=null && opp.Departure_Flight_Schedule__r.Departure_Terminal__c!=null){
                terminalId= opp.Departure_Flight_Schedule__r.Departure_Terminal__c;
                Terminal__c terminal = [SELECT Id,Code__c from Terminal__c WHERE Id=: terminalId LIMIT 1]; 
                return terminal.Code__c!=null ? terminal.Code__c : ''; 
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
        /*
        if (passengersToDelete!=null && passengersToDelete.size()>0) {
            Delete passengersToDelete;
        } */
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
        // Create a list to store OpportunityLineItems
        List<OpportunityLineItem> opportunityLineItemsToInsert = new List<OpportunityLineItem>();
        List<Transaction_History__c> transactionList= new List<Transaction_History__c>();
        Decimal totalListPrice=0;

        // Query Opportunity based on OpportunityId
        Opportunity opp = [
            SELECT Name
            FROM Opportunity
            WHERE Id=:opportunityId
            LIMIT 1
        ];

        //update opportunity
        /*
        List<OpportunityLineItem> loiToDelete = [SELECT Id,Product2Id FROM OpportunityLineItem WHERE OpportunityId =:opportunityId];
        Delete loiToDelete;
        */
        for (Map<String, Object> productDetail : productDetails) {
            // Extract the values from the map
            Id productId = (Id) productDetail.get('productId');
            Id pricebookEntry = (Id) productDetail.get('pricebookEntryId');
            Decimal quantity = (Boolean) productDetail.get('isChild') ? (Decimal) productDetail.get('childCount') : (Decimal) productDetail.get('count');
            Decimal unitPrice = (Decimal) productDetail.get('unitPrice');
            String pickupTerminal = (String) productDetail.get('pickup');
            String dropTerminal = (String) productDetail.get('drop'); 
            
            for (Integer i=0; i<quantity; i++) {
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
                totalListPrice += unitPrice;
                // Add the OLI to the list
                opportunityLineItemsToInsert.add(oli);
            }
        }
            //creation of transaction record for booking
            if(totalListPrice !=0) {
                Transaction_History__c transactionRec= new Transaction_History__c();
                transactionRec.Booking_Id__c = opportunityId;
                transactionRec.List_Price__c = totalListPrice;
                transactionRec.Name = opp.Name;
                transactionRec.Transaction_Type__c = 'Debit';
                
                transactionList.add(transactionRec);
            } 

        // Insert the Opportunity Line Items
        try {
            insert opportunityLineItemsToInsert;                
            insert transactionList;
        } catch (Exception e) {
            System.debug('Error inserting Opportunity Line Items: ' + e.getMessage());
            throw new AuraHandledException('Error in creating order summary, please show this message to admin');
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