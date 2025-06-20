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
    public static void upgradePackage(Id opportunityId, List<Map<String, Object>> productDetails, String primaryPackage) {
        // Create a list to store OpportunityLineItems
        List<Order_Request__c> orderRequestToInsert = new List<Order_Request__c>();

        Map<String, List<Order_Request__c>> orderRequestMap = new Map<String, List<Order_Request__c>>();
        List<Passenger_Details__c> passengersToUpdate = [SELECT Id,Order_Request__c,Individual_Booking_Details__c,Passenger_Type__c
            FROM Passenger_Details__c
            WHERE Opportunity_ID__c=:opportunityId
            ];
        
            Decimal totalUnitPrice = (Decimal) [SELECT SUM(UnitPrice) sumUnitPrice FROM OpportunityLineItem 
            WHERE (Status__c = 'Active' OR Status__c = 'Rescheduled') 
            AND Product2.Family != 'Add Ons' 
            AND Product2.Family != 'Surcharge'
            AND OpportunityId =:opportunityId]
            .get(0).get('sumUnitPrice'); 


        // Query Opportunity based on OpportunityId
        Opportunity opp = [
            SELECT Name,STA_Time__c,STD_Time__c,Date_of_Arrival__c,Date_of_Departure__c,Account.Surcharge_waived_off__c,
            Account.BillingState, Service_Airport_Id__r.State__c,Service_Airport_Id__c,Account.GST_Registration_Type__c,Departure_Service_Time__c
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];
        decimal totalAmount = 0;
        Order_Request__c parentOrderRequest = new Order_Request__c();
        String jsonString = JSON.serialize(productDetails);
        parentOrderRequest.Serialized_Data__c = jsonString;
        parentOrderRequest.Type_of_Amendment__c = 'Upgrade Package';
        parentOrderRequest.Status__c = 'Pending';
        parentOrderRequest.Change_Type__c = 'Amendment';
        parentOrderRequest.Booking__c = opportunityId;
        OrderRequestController.generateOrderRequestNumber(opp, parentOrderRequest);

        insert parentOrderRequest;

        for (Map<String, Object> productDetail : productDetails) {
            // Extract the values from the map
            Id productId = (Id) productDetail.get('productId');
            //Id pricebookEntry = (Id) productDetail.get('pricebookEntryId');
            Decimal quantity = (Boolean) productDetail.get('isChild') ? (Decimal) productDetail.get('childCount') : (Decimal) productDetail.get('count');
            Decimal unitPrice = (Decimal) productDetail.get('unitPrice');
            String pickupTerminal = (String) productDetail.get('pickup');
            String dropTerminal = (String) productDetail.get('drop'); 
            String type = (String) productDetail.get('type'); 
            String packageFamily = (String) productDetail.get('family');
            for (Integer i=0; i< quantity; i++) {
                // Create a new order request
                Order_Request__c orderRequest = new Order_Request__c();
                orderRequest.Product__c = productId;
                orderRequest.Total_List_Price__c = unitPrice;
                totalAmount += unitPrice;
               // orderRequest.PricebookEntryId = pricebookEntry; // Link PricebookEntry to OLI
                orderRequest.Pickup_Terminal__c = pickupTerminal;
                orderRequest.Drop_Terminal__c = dropTerminal;
                orderRequest.Status__c = 'Pending';
                orderRequest.Change_Type__c = 'Amendment';
                orderRequest.Booking__c = opportunityId;
                orderRequest.isSubRequest__c = true;
                orderRequest.Parent_Order_Request__c = parentOrderRequest.Id;
                if (!orderRequestMap.containsKey(type)) {
                    orderRequestMap.put(type, new List<Order_Request__c>());
                }
                orderRequestMap.get(type).add(orderRequest);
                // GST Calculation Logic
                OrderRequestController.calculateGstApplicable(opp, orderRequest);
                // Add the OLI to the list
                orderRequestToInsert.add(orderRequest);
            }
        }
        // Update the Opportunity Line Items
        try {
            insert orderRequestToInsert;
            for (Passenger_Details__c pass: passengersToUpdate) {
                if(orderRequestMap.containsKey(pass.Passenger_Type__c)) {
                    List<Order_Request__c> orderRequests = orderRequestMap.get(pass.Passenger_Type__c);
                     if (!orderRequests.isEmpty()) {
                        // Get the first record from the list
                        Order_Request__c orderRequestId = orderRequests[0];                    
                        pass.Order_Request__c = orderRequestId.Id;
                        // Remove the used record from the list
                        orderRequests.remove(0);
                        // If the list is now empty, remove the key from the map to avoid future checks
                        if (orderRequests.isEmpty()) {
                            orderRequestMap.remove(pass.Passenger_Type__c);
                        }
                    }
                }
            }
            update passengersToUpdate;
            Order_Request__c updateOrderReqDiffAmount = new Order_Request__c(Id = parentOrderRequest.Id);
            updateOrderReqDiffAmount.Total_Payable_Amount__c = totalAmount - totalUnitPrice;
            update updateOrderReqDiffAmount;
        } catch (Exception e) {
            System.debug('Error upgrading package: ' + e.getMessage());
            throw new AuraHandledException('Error in creating order summary, please show this message to admin');
        }

    }

    public static void calculateGstApplicable(Opportunity opp, OpportunityLineItem oli) {

        Decimal gstRate = 18;  // 18% GST
        String billingState = opp.Account.BillingState;
        String serviceAirportState = opp.Service_Airport_Id__c !=null ? opp.Service_Airport_Id__r.State__c : '';
        Boolean isNotIgst =false;
        if (opp.Account.GST_Registration_Type__c != 'Non-Resident taxable person' &&
            opp.Account.GST_Registration_Type__c != 'Special Economic Zone (SEZ) developer/unit') {
                isNotIgst = true;
            }

        //Logic for GST calculation
        Decimal invoiceAmount = oli.UnitPrice / (1 + (gstRate / 100)); // Invoice amount (after GST)
        Decimal totalGST = oli.UnitPrice - invoiceAmount; // Total GST

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
        }else if (billingState == null && serviceAirportState != null){
            sgstAmount = totalGST / 2;
            cgstAmount = totalGST / 2;
        }
        // Set the calculated GST values on the Opportunity Line Item
        oli.Invoice_Amount__c = invoiceAmount;
        oli.SGST__c = sgstAmount;
        oli.CGST__c = cgstAmount;
        oli.IGST__c = igstAmount;        
    }

    @AuraEnabled
    public static void savePassengerDetails(List<Map<String, Object>> passengerData, Id opportunityId) {


        List<Passenger_Details__c> passengerDetailsList = new List<Passenger_Details__c>();
        // Create a Map directly from the query result
        Map<Id, String> opportunityMap = new Map<Id, String>();// Initialize a Map to store Record_Id__c as key and Description__c as value
            List<Order_Request__c> oliList = [SELECT Id,Product__r.Package_Is_For__c 
                FROM Order_Request__c
                WHERE Booking__c =:opportunityId
                AND Status__c = 'Pending'
                AND Change_Type__c = 'Amendment'
                AND isSubRequest__c = true
                AND Id NOT IN (
                    SELECT Order_Request__c
                    FROM Passenger_Details__c
                )
                ORDER BY CreatedDate DESC];
        Map<String, String> typeToOliIdMap = new Map<String, String>();
        // Create a map to store lists of passengers by their 'Valid_For' field value
        Map<String, List<Id>> oliMap = new Map<String, List<Id>>();
        // Iterate over the Order_Request__c object records and populate the map
        for (Order_Request__c orderRequest : oliList) {
            //typeToOliIdMap.put(orderRequest.Product2.Package_Is_For__c, orderRequest.Id);
            if (!oliMap.containsKey(orderRequest.Product__r.Package_Is_For__c)) {
            	oliMap.put(orderRequest.Product__r.Package_Is_For__c, new List<Id>());
        	}
        	oliMap.get(orderRequest.Product__r.Package_Is_For__c).add(orderRequest.Id);
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
            passenger.Show_as_Placard__c = false;
            passenger.Unique_Id__c = (String) guest.get('id');

            passenger.Passenger_Type__c = (String) guest.get('type');
            if(oliMap.containsKey((String) guest.get('type'))) {
               List<Id> orderRequestIds = oliMap.get((String) guest.get('type'));
                if (!orderRequestIds.isEmpty()) {
                    // Get the first Id from the list
                    Id orderRequestId = orderRequestIds[0];
                    
                    // Now, link this Passenger_Details__c record to the OpportunityLineItem
                    passenger.Order_Request__c = orderRequestId;
                    
                    // Remove the used Id from the list
                    orderRequestIds.remove(0);
                    
                    // If the list is now empty, remove the key from the map to avoid future checks
                    if (orderRequestIds.isEmpty()) {
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

    // Method to create Opportunity Line Items
    @AuraEnabled
    public static void createOrderRequests(String opportunityId,
        List<Map<String, Object>> orderRequestDetails,
        Map<String, Object> OrderChangeRequest
        ) {
        // Create a list to store OpportunityLineItems
        List<Order_Request__c> orderRequestList = new List<Order_Request__c>();
        Decimal totalAmount= 0;

        // Query Opportunity based on OpportunityId
        Opportunity opp = [
            SELECT Name,STA_Time__c,STD_Time__c,Date_of_Arrival__c,Date_of_Departure__c,Account.Surcharge_waived_off__c,
            Account.BillingState, Service_Airport_Id__r.State__c,Service_Airport_Id__c,Account.GST_Registration_Type__c,Departure_Service_Time__c
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];

        Order_Request__c order = new Order_Request__c();
        if (OrderChangeRequest != null && !OrderChangeRequest.isEmpty()) {
            for (String fieldName : OrderChangeRequest.keySet()) {
                order.put(fieldName, OrderChangeRequest.get(fieldName));
            }
            order.Type_of_Amendment__c = 'Add Passengers';
            OrderRequestController.generateOrderRequestNumber(opp, order);
        }
        orderRequestList.add(order);
        insert orderRequestList;
        

        List<Order_Request__c> orderRequestToInsert = new List<Order_Request__c>();
        for (Map<String, Object> productDetail : orderRequestDetails) {
            system.debug('productDetail<<<<<' + JSON.serialize(productDetail));
            // Extract the values from the map
            Id productId = (Id) productDetail.get('productId');
            Id pricebookEntry = (Id) productDetail.get('pricebookEntryId');
            Decimal quantity = (Boolean) productDetail.get('isChild') ? (Decimal) productDetail.get('childCount') : (Boolean) productDetail.get('isInfant') ? (Decimal) productDetail.get('infantCount') : (Decimal) productDetail.get('count');
            Decimal unitPrice = (Decimal) productDetail.get('unitPrice');
            Decimal discountAmount = (Decimal) productDetail.get('discountValue');
            String packageFamily = (String) productDetail.get('family');

            // Create a new Opportunity Line Item for packages
            Order_Request__c orderRequest = new Order_Request__c();
            orderRequest.Parent_Order_Request__c = orderRequestList !=null && !orderRequestList.isEmpty() ? orderRequestList[0].Id : null;
            orderRequest.Product__c = productId;
            orderRequest.Total_List_Price__c = unitPrice;
            totalAmount += unitPrice;
            //orderRequest.Total_Payable_Amount__c = unitPrice;
            //orderRequest.PricebookEntryId = pricebookEntry; // Link PricebookEntry to OLI
            ///orderRequest.Discount_Amount__c = discountAmount/quantity;
            orderRequest.Status__c = 'Pending';
            orderRequest.Change_Type__c = 'Amendment';
            orderRequest.Booking__c = opportunityId;
            orderRequest.isSubRequest__c = true;
            OrderRequestController.calculateGstApplicable(opp, orderRequest);
            // Add the order to the list
            orderRequestToInsert.add(orderRequest); 
        }

        // Insert the Opportunity Line Items and Transaction History
        try {

            insert orderRequestToInsert;
            
            Order_Request__c updateOrderReqDiffAmount = new Order_Request__c(Id = orderRequestList[0].Id);
            updateOrderReqDiffAmount.Total_Payable_Amount__c = totalAmount;
            update updateOrderReqDiffAmount;

        } catch (Exception e) {
            System.debug('Error inserting Opportunity Line Items: ' + e.getMessage());
            throw new AuraHandledException('Error in creating order summary, please show this message to admin');
        }
    }

    // Method to create Opportunity Line Items
    @AuraEnabled
    public static void createAddonsOrderRequest(Id opportunityId, List<Map<String, Object>> productDetails, Map<String, Object> OrderChangeRequest) {
        // Create a list to store Order request
        List<Order_Request__c> subOrderReqToInsert = new List<Order_Request__c>();
        List<Order_Request__c> OrderReqToInsert = new List<Order_Request__c>();
        List<Transaction_History__c> transactionList = new List<Transaction_History__c>();
        Decimal totalListPrice = 0;
        DateTime serviceDateTime;
        String dateText;
        String timeText;
        String combinedDateTimeStr;
        Decimal totalAmount=0;
        // Query Opportunity based on OpportunityId
        Opportunity opp = [
            SELECT Name,STA_Time__c,STD_Time__c,Date_of_Arrival__c,Date_of_Departure__c,Account.Surcharge_waived_off__c,
            Account.BillingState, Service_Airport_Id__r.State__c,Service_Airport_Id__c,Account.GST_Registration_Type__c,Departure_Service_Time__c
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];

        Order_Request__c order = new Order_Request__c();
        if (OrderChangeRequest != null && !OrderChangeRequest.isEmpty()) {
            for (String fieldName : OrderChangeRequest.keySet()) {
                order.put(fieldName, OrderChangeRequest.get(fieldName));
            }
            order.Type_of_Amendment__c = 'Add Add-Ons';
            OrderRequestController.generateOrderRequestNumber(opp, order);
        }
        OrderReqToInsert.add(order);
        insert OrderReqToInsert;

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

        for (Map<String, Object> productDetail : productDetails) {
            // Extract the values from the map
            Id productId = (Id) productDetail.get('productId');
            Decimal quantity = (Boolean) productDetail.get('isChild') ? (Decimal) productDetail.get('childCount') : (Boolean) productDetail.get('isInfant') ? (Decimal) productDetail.get('infantCount') : (Decimal) productDetail.get('count');
            Decimal unitPrice = (Decimal) productDetail.get('unitPrice');
            //Decimal discountAmount = (Decimal) productDetail.get('discountValue');
            String packageFamily = (String) productDetail.get('family');
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

                String pickupTerminal ='';
                String dropTerminal='';
                for (Integer j = 0; j < Math.max(pickupTerminals.size(), dropTerminals.size()); j++) {
                    // Ensure we don't access out of bounds in case the arrays are of different lengths
                    pickupTerminal = (j < pickupTerminals.size()) ? pickupTerminals.get(j) : pickupTerminal;
                    dropTerminal = (j < dropTerminals.size()) ? dropTerminals.get(j) : dropTerminal;

                    // Create a new Opportunity Line Item for 
                    Order_Request__c orderRequest = new Order_Request__c();
                    orderRequest.Product__c = productId;
                    orderRequest.Total_List_Price__c = unitPrice;
                    totalAmount += unitPrice;
                    //orderRequest.Total_Payable_Amount__c = unitPrice; // Link PricebookEntry to OLI
                    orderRequest.Pickup_Terminal__c = pickupTerminal;
                    orderRequest.Drop_Terminal__c = dropTerminal;
                    orderRequest.Status__c = 'Pending';
                    orderRequest.Change_Type__c = 'Amendment';
                    orderRequest.Booking__c = opportunityId;
                    orderRequest.isSubRequest__c = true;
                    orderRequest.Package_Type__c = packageFamily;
                    orderRequest.Parent_Order_Request__c = OrderReqToInsert !=null && !OrderReqToInsert.isEmpty() ? OrderReqToInsert[0].Id : null;

                    OrderRequestController.calculateGstApplicable(opp, orderRequest);
                    // Add the OLI to the list
                    subOrderReqToInsert.add(orderRequest);
                }

        }

        
        try {
            // Insert order request (child requests)
            insert subOrderReqToInsert;

            Order_Request__c updateOrderReqDiffAmount = new Order_Request__c(Id = OrderReqToInsert[0].Id);
            updateOrderReqDiffAmount.Total_Payable_Amount__c = totalAmount;
            update updateOrderReqDiffAmount;
        } catch (Exception e) {
            System.debug('Error inserting Opportunity Line Items: ' + e.getMessage());
            throw new AuraHandledException('Error in creating order summary, please show this message to admin');
        }
    }

    public static void createNewOpportunityLineItems(Id opportunityId, List<Map<String, Object>> productDetails) {

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
            Decimal quantity = (Boolean) productDetail.get('isChild') ? (Decimal) productDetail.get('childCount') : (Boolean) productDetail.get('isInfant') ? (Decimal) productDetail.get('infantCount') : (Decimal) productDetail.get('count');
            Decimal unitPrice = (Decimal) productDetail.get('unitPrice');
            Decimal discountAmount = (Decimal) productDetail.get('discountValue');
            String packageFamily = (String) productDetail.get('family');
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
                        oli.Package__C = packageFamily;
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
                    calculateGstApplicable(opp, oli);//added by Abhishek 
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

    public static void addPassengerAmendedOrders(List<Order_Request__c> orderRequestList) {
        try {
            Set<Id> oppIds = new Set<Id>();
            List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
            Map<Id, List<Map<String, Object>>> opportunityProductDetailsMap = new Map<Id, List<Map<String, Object>>>();
            List<Order_Request__c> orderRequestsToUpdate = new List<Order_Request__c>();
            List<Order_Request__c> childOrders = new List<Order_Request__c>();
            // Step 1: Update Opportunity fields & prepare ProductDetails for creating Opportunity Line Items
            for (Order_Request__c mainOrderRequest : orderRequestList) {
                List<Order_Request__c> childOrderRequests = mainOrderRequest.Order_Request__r;

                // Mark Order Request & Its Child Records as Completed
                mainOrderRequest.Status__c = 'Completed';
                orderRequestsToUpdate.add(mainOrderRequest);
                
                oppIds.add(mainOrderRequest.Booking__c);
                for (Order_Request__c childOrder : childOrderRequests) {
                    childOrder.Status__c = 'Completed';
                    orderRequestsToUpdate.add(childOrder);
                    childOrders.add(childOrder);
                }

                // Updating Opportunity fields
                Opportunity opp = new Opportunity(Id = mainOrderRequest.Booking__c);
                opp.Number_of_Children__c = mainOrderRequest.Number_of_Children__c !=null ? mainOrderRequest.Number_of_Children__c : 0;
                opp.Number_of_Adults__c = mainOrderRequest.Number_of_Adults__c !=null ? mainOrderRequest.Number_of_Adults__c : 0;
                opp.Number_of_Infants__c = mainOrderRequest.Number_of_Infants__c !=null ?  mainOrderRequest.Number_of_Infants__c : 0;
                opportunitiesToUpdate.add(opp);

                // Parse Serialized_Data__c for product details
                if (String.isNotEmpty(mainOrderRequest.Serialized_Data__c)) {
                    Object rawData = JSON.deserializeUntyped(mainOrderRequest.Serialized_Data__c);
                
                    if (rawData instanceOf List<Object>) {
                        List<Object> rawList = (List<Object>) rawData;
                        List<Map<String, Object>> productDetails = new List<Map<String, Object>>();
                
                        for (Object obj : rawList) {
                            productDetails.add((Map<String, Object>) obj);
                        }
                
                        opportunityProductDetailsMap.put(mainOrderRequest.Booking__c, productDetails);
                    }
                }                
            }

            // Step 2: Call existing method to create Opportunity Line Items
            for (Id opportunityId : opportunityProductDetailsMap.keySet()) {
                List<Map<String, Object>> productDetails = opportunityProductDetailsMap.get(opportunityId);
                createNewOpportunityLineItems(opportunityId, productDetails);
            }

            List<Order_Request__c> queriedChildOrders = [
                SELECT Id,Product__r.Package_Is_For__c, 
                    (SELECT Id, Individual_Booking_Details__c FROM Passenger_Details__r)
                FROM Order_Request__c 
                WHERE Id IN :childOrders
            ];
            
            //Link `Individual_Booking_Details__c` in Passenger_Details__c to Opportunity Line Items based on `Package_Is_For__c`
            Map<Id, String> orderProductMap = new Map<Id, String>();
            Map<Id, Id> passengerDetailMap = new Map<Id, Id>(); // Map Order_Request__c to corresponding OpportunityLineItem

            // Store mappings of Order_Request__c's `Product__r.Package_Is_For__c`
            for (Order_Request__c order : queriedChildOrders) {
                orderProductMap.put(order.Id, order.Product__r.Package_Is_For__c);
            }

            // Query Opportunity Line Items with `Package_Is_For__c`
            List<OpportunityLineItem> lineItemsToUpdate = [
                SELECT Id,Product2.Package_Is_For__c 
                FROM OpportunityLineItem
                WHERE OpportunityId IN :oppIds
                AND Status__c = 'Active'
                AND Id NOT IN (
                    SELECT Individual_Booking_Details__c
                    FROM Passenger_Details__c
                )
                ORDER BY CreatedDate DESC
            ];

            

            // Create mapping of OpportunityLineItem IDs for matching `Package_Is_For__c`
            Map<String, Id> lineItemProductMap = new Map<String, Id>();
            for (OpportunityLineItem item : lineItemsToUpdate) {
                lineItemProductMap.put(item.Product2.Package_Is_For__c, item.Id);
            }

            // Now update Passenger_Details__c to link the correct OpportunityLineItem
            List<Passenger_Details__c> passengerDetailsToUpdate = new List<Passenger_Details__c>();

            for (Order_Request__c order : queriedChildOrders) {
                for (Passenger_Details__c passenger : order.Passenger_Details__r) {
                    String packageIsFor = orderProductMap.get(order.Id);
                    if (lineItemProductMap.containsKey(packageIsFor)) {
                        passenger.Individual_Booking_Details__c = lineItemProductMap.get(packageIsFor);
                        passengerDetailsToUpdate.add(passenger);
                    }
                }
            }


            if (!orderRequestsToUpdate.isEmpty()) {
                update orderRequestsToUpdate; // Updating Order Request & Child Records to 'Completed'
            }

            if (!opportunitiesToUpdate.isEmpty()) {
                update opportunitiesToUpdate;
            }

            if (!lineItemsToUpdate.isEmpty()) {
                update lineItemsToUpdate;
            }

            if (!passengerDetailsToUpdate.isEmpty()) {
                update passengerDetailsToUpdate; // Updating Passenger_Details__c with linked OpportunityLineItems
            }
        }   catch (Exception e) {
            System.debug('Error occurred in addPassengerAmendedOrders method: ' + e.getMessage());
        }
    }

    public static void packageUpgradeAmendedOrders(List<Order_Request__c> orderRequestList) {
        try {
            Set<Id> oppIds = new Set<Id>();
            Map<Id, List<Map<String, Object>>> opportunityProductDetailsMap = new Map<Id, List<Map<String, Object>>>();
            List<Order_Request__c> orderRequestsToUpdate = new List<Order_Request__c>();
            List<Order_Request__c> childOrders = new List<Order_Request__c>();
            // Step 1: Update Opportunity fields & prepare ProductDetails for creating Opportunity Line Items
            for (Order_Request__c mainOrderRequest : orderRequestList) {
                List<Order_Request__c> childOrderRequests = mainOrderRequest.Order_Request__r;

                // Mark Order Request & Its Child Records as Completed
                mainOrderRequest.Status__c = 'Completed';
                orderRequestsToUpdate.add(mainOrderRequest);
                
                oppIds.add(mainOrderRequest.Booking__c);
                for (Order_Request__c childOrder : childOrderRequests) {
                    childOrder.Status__c = 'Completed';
                    orderRequestsToUpdate.add(childOrder);
                    childOrders.add(childOrder);
                }

                // Parse Serialized_Data__c for product details
                if (String.isNotEmpty(mainOrderRequest.Serialized_Data__c)) {
                    Object rawData = JSON.deserializeUntyped(mainOrderRequest.Serialized_Data__c);
                
                    if (rawData instanceOf List<Object>) {
                        List<Object> rawList = (List<Object>) rawData;
                        List<Map<String, Object>> productDetails = new List<Map<String, Object>>();
                
                        for (Object obj : rawList) {
                            productDetails.add((Map<String, Object>) obj);
                        }
                
                        opportunityProductDetailsMap.put(mainOrderRequest.Booking__c, productDetails);
                    }
                }                
            }

            // Step 2: Call existing method to create Opportunity Line Items
            for (Id opportunityId : opportunityProductDetailsMap.keySet()) {
                List<Map<String, Object>> productDetails = opportunityProductDetailsMap.get(opportunityId);
                upgradePackageFromOrderRequest(opportunityId, productDetails);
            }

            List<Order_Request__c> queriedChildOrders = [
                SELECT Id,Product__r.Package_Is_For__c, 
                    (SELECT Id, Individual_Booking_Details__c FROM Passenger_Details__r)
                FROM Order_Request__c 
                WHERE Id IN :childOrders
            ];
            
            //Link `Individual_Booking_Details__c` in Passenger_Details__c to Opportunity Line Items based on `Package_Is_For__c`
            Map<Id, String> orderProductMap = new Map<Id, String>();
            Map<Id, Id> passengerDetailMap = new Map<Id, Id>(); // Map Order_Request__c to corresponding OpportunityLineItem

            // Store mappings of Order_Request__c's `Product__r.Package_Is_For__c`
            for (Order_Request__c order : queriedChildOrders) {
                orderProductMap.put(order.Id, order.Product__r.Package_Is_For__c);
            }

            // Query Opportunity Line Items with `Package_Is_For__c`
            List<OpportunityLineItem> lineItemsToUpdate = [
                SELECT Id,Product2.Package_Is_For__c 
                FROM OpportunityLineItem
                WHERE OpportunityId IN :oppIds
                AND Status__c = 'Active'
                AND Id NOT IN (
                    SELECT Individual_Booking_Details__c
                    FROM Passenger_Details__c
                )
                ORDER BY CreatedDate DESC
            ];

            

            // Create mapping of OpportunityLineItem IDs for matching `Package_Is_For__c`
            Map<String, Id> lineItemProductMap = new Map<String, Id>();
            for (OpportunityLineItem item : lineItemsToUpdate) {
                lineItemProductMap.put(item.Product2.Package_Is_For__c, item.Id);
            }

            // Now update Passenger_Details__c to link the correct OpportunityLineItem
            List<Passenger_Details__c> passengerDetailsToUpdate = new List<Passenger_Details__c>();

            for (Order_Request__c order : queriedChildOrders) {
                for (Passenger_Details__c passenger : order.Passenger_Details__r) {
                    String packageIsFor = orderProductMap.get(order.Id);
                    if (lineItemProductMap.containsKey(packageIsFor)) {
                        passenger.Individual_Booking_Details__c = lineItemProductMap.get(packageIsFor);
                        passengerDetailsToUpdate.add(passenger);
                    }
                }
            }


            if (!orderRequestsToUpdate.isEmpty()) {
                update orderRequestsToUpdate; // Updating Order Request & Child Records to 'Completed'
            }

            if (!lineItemsToUpdate.isEmpty()) {
                update lineItemsToUpdate;
            }

            if (!passengerDetailsToUpdate.isEmpty()) {
                update passengerDetailsToUpdate; // Updating Passenger_Details__c with linked OpportunityLineItems
            }
        }   catch (Exception e) {
            System.debug('Error occurred in addPassengerAmendedOrders method: ' + e.getMessage());
        }
    }

    // Method to upgrade package
    @AuraEnabled
    public static void upgradePackageFromOrderRequest(Id opportunityId, List<Map<String, Object>> productDetails) {
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

        List<OpportunityLineItem> existingOliListToUpdate = [SELECT Id,Product2Id,UnitPrice,PricebookEntryId,Product2.Package_Is_For__c FROM OpportunityLineItem
            WHERE OpportunityId =:opportunityId
            AND (Status__c = 'Active' OR Status__c = 'Rescheduled')
            AND Product2.Family != 'Add Ons' AND Product2.Family != 'Surcharge' 
            ];
        for (OpportunityLineItem oli : existingOliListToUpdate) {
                oli.Status__c = 'Amended';
        }
        update existingOliListToUpdate;
        Map<String, List<OpportunityLineItem>> oliMap = new Map<String, List<OpportunityLineItem>>();
        List<Passenger_Details__c> passengersToUpdate = [SELECT Id,Individual_Booking_Details__c,Passenger_Type__c
            FROM Passenger_Details__c
            WHERE Opportunity_ID__c=:opportunityId
            ];
        for (Map<String, Object> productDetail : productDetails) {
            // Extract the values from the map
            Id productId = (Id) productDetail.get('productId');
            Id pricebookEntry = (Id) productDetail.get('pricebookEntryId');
            //Decimal quantity = (Boolean) productDetail.get('isChild') ? (Decimal) productDetail.get('childCount') : (Decimal) productDetail.get('count');
            Decimal quantity = (Boolean) productDetail.get('isChild') ? (Decimal) productDetail.get('childCount') : (Boolean) productDetail.get('isInfant') ? (Decimal) productDetail.get('infantCount') : (Decimal) productDetail.get('count');
            Decimal unitPrice = (Decimal) productDetail.get('unitPrice');
            String pickupTerminal = (String) productDetail.get('pickup');
            String dropTerminal = (String) productDetail.get('drop'); 
            String type = (String) productDetail.get('type'); 
            String packageFamily = (String) productDetail.get('family');
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
                oli.Package__c = packageFamily;
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
            insert opportunityLineItemsToInsert;
        } catch (Exception e) {
            System.debug('Error inserting Opportunity Line Items: ' + e.getMessage());
            throw new AuraHandledException('Error in creating order summary, please show this message to admin');
        }

    }

    public static void AddOnsAmendedOrders(List<Order_Request__c> orderRequestList) {
        try {
            Set<Id> oppIds = new Set<Id>();
            Map<Id, List<Map<String, Object>>> opportunityProductDetailsMap = new Map<Id, List<Map<String, Object>>>();
            List<Order_Request__c> orderRequestsToUpdate = new List<Order_Request__c>();
            List<Order_Request__c> childOrders = new List<Order_Request__c>();
            // Step 1: Update Opportunity fields & prepare ProductDetails for creating Opportunity Line Items
            for (Order_Request__c mainOrderRequest : orderRequestList) {
                List<Order_Request__c> childOrderRequests = mainOrderRequest.Order_Request__r;

                // Mark Order Request & Its Child Records as Completed
                mainOrderRequest.Status__c = 'Completed';
                orderRequestsToUpdate.add(mainOrderRequest);
                
                oppIds.add(mainOrderRequest.Booking__c);
                for (Order_Request__c childOrder : childOrderRequests) {
                    childOrder.Status__c = 'Completed';
                    orderRequestsToUpdate.add(childOrder);
                    childOrders.add(childOrder);
                }

                // Parse Serialized_Data__c for product details
                if (String.isNotEmpty(mainOrderRequest.Serialized_Data__c)) {
                    Object rawData = JSON.deserializeUntyped(mainOrderRequest.Serialized_Data__c);
                
                    if (rawData instanceOf List<Object>) {
                        List<Object> rawList = (List<Object>) rawData;
                        List<Map<String, Object>> productDetails = new List<Map<String, Object>>();
                
                        for (Object obj : rawList) {
                            productDetails.add((Map<String, Object>) obj);
                        }
                
                        opportunityProductDetailsMap.put(mainOrderRequest.Booking__c, productDetails);
                    }
                }                
            }

            // Step 2: Call existing method to create Opportunity Line Items
            for (Id opportunityId : opportunityProductDetailsMap.keySet()) {
                List<Map<String, Object>> productDetails = opportunityProductDetailsMap.get(opportunityId);
                createAddOnsFromOrderRequest(opportunityId, productDetails);
            }
            if (!orderRequestsToUpdate.isEmpty()) {
                update orderRequestsToUpdate; // Updating Order Request & Child Records to 'Completed'
            }
        }   catch (Exception e) {
            System.debug('Error occurred in addPassengerAmendedOrders method: ' + e.getMessage());
        }
    }

    
    public static void createAddOnsFromOrderRequest(Id opportunityId, List<Map<String, Object>> productDetails) {
        // Create a list to store OpportunityLineItems
        List<OpportunityLineItem> opportunityLineItemsToInsert = new List<OpportunityLineItem>();
        List<Transaction_History__c> transactionList = new List<Transaction_History__c>();
        List<PricebookEntry> pbEntry = new List<PricebookEntry>();
        Decimal totalListPrice = 0;

        // Query Opportunity based on OpportunityId
        Opportunity opp = [
            SELECT Name,STA_Time__c,STD_Time__c,Date_of_Arrival__c,Date_of_Departure__c,Account.Surcharge_waived_off__c,
            Account.BillingState, Service_Airport_Id__r.State__c,Service_Airport_Id__c,Account.GST_Registration_Type__c,Departure_Service_Time__c
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];

        for (Map<String, Object> productDetail : productDetails) {
            // Extract the values from the map
            Id productId = (Id) productDetail.get('productId');
            Id pricebookEntry = (Id) productDetail.get('pricebookEntryId');
            Decimal quantity = (Boolean) productDetail.get('isChild') ? (Decimal) productDetail.get('childCount') : (Boolean) productDetail.get('isInfant') ? (Decimal) productDetail.get('infantCount') : (Decimal) productDetail.get('count');
            Decimal unitPrice = (Decimal) productDetail.get('unitPrice');
            Decimal discountAmount = (Decimal) productDetail.get('discountValue');
            String packageFamily = (String) productDetail.get('family');
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
                    totalListPrice += unitPrice;  
                    calculateGstApplicable(opp, oli);
                    // Add the OLI to the list
                    opportunityLineItemsToInsert.add(oli);
                }

        }

        // Insert the Opportunity Line Items and Transaction History
        try {

            insert opportunityLineItemsToInsert;
            // Now that the records are inserted, their Ids are populated
            for (OpportunityLineItem oli : opportunityLineItemsToInsert) {
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

            // Finally, insert the transaction history records
            insert transactionList;
        } catch (Exception e) {
            System.debug('Error adding new Add-Ons: ' + e.getMessage());
            throw new AuraHandledException('Error in Adding Add-Ons, please show this message to admin');
        }
    }
}