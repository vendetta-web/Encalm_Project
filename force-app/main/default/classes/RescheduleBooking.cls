public class RescheduleBooking {
    public static String reschedulingPolicy='';
    public static Set<String> checkUniqueRefundPolicy = new Set<String>();

    public static Decimal getPerBookingReschedulingAmount(DateTime serviceDateTime,
        DateTime ReschedulingDateTime,
        Decimal bookingAmount,
        String packageName,
        Decimal reschedulingCount) {
        List<Rescheduling__mdt> policyList = [SELECT MasterLabel, Time_Frame__c,
        Charges_in_Percentage__c, Charges__c,
        Greater_Than__c, Less_Than__c, Package__c,Policy_Applied__c,Applicable_Per_Booking__c,Charges_After_Free_Rescheduling__c
        FROM Rescheduling__mdt 
        WHERE IsActive__c = true
        AND Applicable_Per_Booking__c = true
        AND (Package__c =:packageName)
        ORDER BY Time_Frame__c];

        Long hoursDifference = serviceDateTime.getTime() - ReschedulingDateTime.getTime();
        hoursDifference = hoursDifference / (1000 * 60 * 60);  // Convert milliseconds to hours
        for (Rescheduling__mdt policy : policyList) {
            if (policy.Applicable_Per_Booking__c && policy.Time_Frame__c.contains('-')) {
                List<String> rangeValues = policy.Time_Frame__c.split('-');
                Integer lowerValue = Integer.valueOf(rangeValues[0]); // First value (24)
                Integer upperValue = Integer.valueOf(rangeValues[1]); // Second value (48)
                if (hoursDifference > lowerValue && hoursDifference < upperValue) {
                    if (policy.Charges_in_Percentage__c) {
                        if (!checkUniqueRefundPolicy.contains(policy.Policy_Applied__c)) {
                            checkUniqueRefundPolicy.add(policy.Policy_Applied__c);
                            reschedulingPolicy = policy.Policy_Applied__c;
                        }
                        return (bookingAmount * (policy.Charges__c / 100));
                    } else {
                        if (!checkUniqueRefundPolicy.contains(policy.Policy_Applied__c)) {
                            checkUniqueRefundPolicy.add(policy.Policy_Applied__c);
                            reschedulingPolicy = policy.Policy_Applied__c;
                        }
                        return policy.Charges__c;
                    } 
                }
            } else if (policy.Applicable_Per_Booking__c
                && policy.Greater_Than__c
                && hoursDifference > Long.valueOf(policy.Time_Frame__c)) {
                if (reschedulingCount == 0) {
                    if (!checkUniqueRefundPolicy.contains(policy.Policy_Applied__c)) {
                        checkUniqueRefundPolicy.add(policy.Policy_Applied__c);
                        reschedulingPolicy = policy.Policy_Applied__c;
                    }
                    return policy.Charges__c;
                } else if (reschedulingCount > 0 && policy.Charges_After_Free_Rescheduling__c !=null){
                    if (!checkUniqueRefundPolicy.contains(policy.Policy_Applied__c)) {
                        checkUniqueRefundPolicy.add(policy.Policy_Applied__c);
                        reschedulingPolicy = policy.Policy_Applied__c;
                    }
                    return policy.Charges_After_Free_Rescheduling__c;
                } 
            }
        }
        return 0;
    }

    public static Decimal getReschedulingAmount(DateTime serviceDateTime, DateTime ReschedulingDateTime, Decimal bookingAmount, String packageName) {
        // Calculate the difference in hours between the service and cancellation times
        Long hoursDifference = serviceDateTime.getTime() - reschedulingDateTime.getTime();
        hoursDifference = hoursDifference / (1000 * 60 * 60);  // Convert milliseconds to hours
        // Query the cancellation policies
        List<Rescheduling__mdt> policies = [SELECT MasterLabel, Time_Frame__c, Applicable_Per_Booking__c,
                                                   Charges_in_Percentage__c, Charges__c,
                                                   Greater_Than__c, Less_Than__c, Package__c,Policy_Applied__c
                                                   FROM Rescheduling__mdt 
                                                   WHERE IsActive__c = true
                                                   AND (Package__c =:packageName)
                                                   ORDER BY Time_Frame__c];

        // Iterate through policies to find the applicable one
        for (Rescheduling__mdt policy : policies) {
                if (!policy.Applicable_Per_Booking__c && policy.Less_Than__c &&  hoursDifference < Long.valueOf(policy.Time_Frame__c)) {
                    if (policy.Charges_in_Percentage__c) {
                        if (!checkUniqueRefundPolicy.contains(policy.Policy_Applied__c)) {
                            checkUniqueRefundPolicy.add(policy.Policy_Applied__c);
                            reschedulingPolicy = policy.Policy_Applied__c;
                        }
                        return (bookingAmount * (policy.Charges__c / 100));
                    } else {
                        if (!checkUniqueRefundPolicy.contains(policy.Policy_Applied__c)) {
                            checkUniqueRefundPolicy.add(policy.Policy_Applied__c);
                            reschedulingPolicy = policy.Policy_Applied__c;
                        }
                        return policy.Charges__c;
                    } 
                } 
                else if (!policy.Applicable_Per_Booking__c &&  policy.Greater_Than__c && Long.valueOf(policy.Time_Frame__c) < hoursDifference) {
                    if (policy.Charges_in_Percentage__c) {
                        if (!checkUniqueRefundPolicy.contains(policy.Policy_Applied__c)) {
                            checkUniqueRefundPolicy.add(policy.Policy_Applied__c);
                            reschedulingPolicy = policy.Policy_Applied__c;
                        }
                        return (bookingAmount * (policy.Charges__c / 100));
                    } else {
                        if (!checkUniqueRefundPolicy.contains(policy.Policy_Applied__c)) {
                            checkUniqueRefundPolicy.add(policy.Policy_Applied__c);
                            reschedulingPolicy = policy.Policy_Applied__c;
                        }
                        return policy.Charges__c;
                    } 
                }
                else if (policy.Applicable_Per_Booking__c &&  policy.Time_Frame__c.contains('-')) {
                    List<String> rangeValues = policy.Time_Frame__c.split('-');
                    Integer lowerValue = Integer.valueOf(rangeValues[0]); // First value (24)
                    Integer upperValue = Integer.valueOf(rangeValues[1]); // Second value (48)
                    if (hoursDifference > lowerValue && hoursDifference < upperValue) {
                        if (policy.Charges_in_Percentage__c) {
                            if (!checkUniqueRefundPolicy.contains(policy.Policy_Applied__c)) {
                                checkUniqueRefundPolicy.add(policy.Policy_Applied__c);
                                reschedulingPolicy = policy.Policy_Applied__c;
                            }
                            return (bookingAmount * (policy.Charges__c / 100));
                        } else {
                            if (!checkUniqueRefundPolicy.contains(policy.Policy_Applied__c)) {
                                checkUniqueRefundPolicy.add(policy.Policy_Applied__c);
                                reschedulingPolicy = policy.Policy_Applied__c;
                            }
                            return policy.Charges__c;
                        } 
                    }
                }
                else if (!policy.Applicable_Per_Booking__c && policy.Time_Frame__c == 'Unlimited') {
                    if (policy.Charges_in_Percentage__c) {
                        if (!checkUniqueRefundPolicy.contains(policy.Policy_Applied__c)) {
                            checkUniqueRefundPolicy.add(policy.Policy_Applied__c);
                            reschedulingPolicy = policy.Policy_Applied__c;
                        }
                        return bookingAmount = (bookingAmount * (policy.Charges__c / 100));
                    } else {
                        if (!checkUniqueRefundPolicy.contains(policy.Policy_Applied__c)) {
                            checkUniqueRefundPolicy.add(policy.Policy_Applied__c);
                            reschedulingPolicy = policy.Policy_Applied__c;
                        }
                        return bookingAmount = policy.Charges__c;
                    } 
                }
            
        }
        // Default to no charge if no policy matches
        return 0;
    }

    @AuraEnabled(cacheable=true)
    public static bookingWrapper getOpportunityDetails(Id opportunityId) {
        
        bookingWrapper bookWrp = new bookingWrapper();
        ///Check pending request
        List<Order_Request__c> orderList = [SELECT Id, Name, Booking__r.Name, Status__c, Change_Type__c, CreatedDate 
                FROM Order_Request__c 
                WHERE Status__c = 'Pending' 
                AND Booking__c =: opportunityId
                AND isSubRequest__c = false
                ORDER BY CreatedDate DESC
                LIMIT 1];
        if (orderList !=null && orderList.size()>0) {
            bookWrp.hasPendingRequest = true; 
        } else {
            // Fetch Opportunity record with related fields
            Opportunity opp =  [SELECT Id, 
            Service_Type__c,
            Number_of_Adults__c, 
            Number_of_Children__c, 
            Number_of_Infants__c,
            Date_of_Arrival__c,
            Date_of_Departure__c,
            Service_Airport__c,
            Flight_Number_Arrival__c,
            Flight_Number_Departure__c,
            Arriving_Airport__c,
            Departure_Airport__c,
            Flight_Type__c,
            STA_Time__c,
            STD_Time__c,
            Sector__c,
            Departure_Service_Time__c
            FROM Opportunity 
            WHERE Id = :opportunityId 
            LIMIT 1];       
            bookWrp.serviceType = opp.Service_Type__c;
            bookWrp.NoOfAdult = opp.Number_of_Adults__c;
            bookWrp.NoOfChild = opp.Number_of_Children__c;
            bookWrp.NoOfInfant = opp.Number_of_Infants__c;
            bookWrp.serviceAirport = opp.Service_Airport__c;
            bookWrp.arrivingAirport = opp.Arriving_Airport__c;
            bookWrp.departureAirport = opp.Departure_Airport__c;
            bookWrp.flightNumberArrival = opp.Flight_Number_Arrival__c;
            bookWrp.flightNumberDeparture = opp.Flight_Number_Departure__c;
            bookWrp.departureDate = opp.Date_of_Departure__c != null ? Date.valueOf(opp.Date_of_Departure__c) : Date.today();
            bookWrp.arrivalDate = opp.Date_of_Arrival__c != null ? Date.valueOf(opp.Date_of_Arrival__c) : Date.today();
            bookWrp.sector = opp.Flight_Type__c;
            bookWrp.staTime = opp.STA_Time__c;
            bookWrp.stdTime = opp.STD_Time__c;
            bookWrp.stdServiceTime = opp.Departure_Service_Time__c !=null ? opp.Departure_Service_Time__c : opp.STD_Time__c;
        }
        
        return bookWrp;
    }

    @AuraEnabled
    public static void saveData(String oppId, Map<String, Object> opportunityFieldValues) {
        if (String.isBlank(oppId)) {
            throw new AuraHandledException('Error in saving details');
        }

        try {
                if (opportunityFieldValues != null && !opportunityFieldValues.isEmpty()) {
                    Opportunity opp = new Opportunity(Id = oppId);
                    for (String fieldName : opportunityFieldValues.keySet()) {
                        opp.put(fieldName, opportunityFieldValues.get(fieldName));
                    }
                    update opp; // Save the updates
                }
        } catch (Exception e) {
            system.debug('Error in method RescheduleBooking.saveData-->> '+ e.getMessage());
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static ReschedulingDetailsWrapper showReschedulingCharges(
        String opportunityId,
        Boolean submit,
        Map<String, Object> OrderChangeRequest) {
        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
        List<Order_Request__c> orderRequestList = new List<Order_Request__c>();
        ReschedulingDetailsWrapper wrp = new ReschedulingDetailsWrapper();
        List<Transaction_History__c> transactionList= new List<Transaction_History__c>();
        DateTime serviceDateTime;
        String dateText;
        String timeText;
        String combinedDateTimeStr ='';
        Decimal reschedulingCount = 0;
        // Query OpportunityLineItems based on OpportunityId
        Opportunity opp = [
            SELECT STA_Time__c,STD_Time__c,Date_of_Arrival__c,Date_of_Departure__c,Amount,Account.Surcharge_waived_off__c,Account.BillingState,
            Service_Airport_Id__r.State__c,Service_Airport_Id__c,Account.GST_Registration_Type__c,Saved_State_Addons__c, Saved_State_OrderSummary__c,
            Flight_Number_Arrival__c,Flight_Number_Departure__c,Number_of_Rescheduling_Done__c,Name,Departure_Service_Time__c,
            (SELECT Id,Product2.Family,UnitPrice,PricebookEntryId FROM opportunitylineitems WHERE Product2.Family != 'Surcharge' AND (Status__c = 'Active' OR Status__c = 'Rescheduled')) 
            FROM Opportunity
            WHERE Id=:opportunityId
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
        } else if (opp.Departure_Service_Time__c != null || opp.STD_Time__c != null) {
            dateText=opp.Date_of_Departure__c;
            timeText=opp.Departure_Service_Time__c !=null ? opp.Departure_Service_Time__c : opp.STD_Time__c;// Ensure timeText includes seconds
            if (timeText.length() == 5) {  // "HH:mm" format
                timeText += ':00';  // Append ":00" for seconds
            }
            combinedDateTimeStr=dateText + ' ' + timeText;
            serviceDateTime = DateTime.valueOf(combinedDateTimeStr);
        }   

        //logic for reschduling starts   
            Decimal bookingAmount = 0;  
            Decimal totalReschedulingAmount = 0; 
            String packageName = '';  
            for (opportunitylineitem oli: opp.opportunitylineitems) {
                bookingAmount += oli.UnitPrice;
                if (oli.Product2.Family != 'Add Ons') {
                    packageName = oli.Product2.Family;
                }
            }
            reschedulingCount = opp.Number_of_Rescheduling_Done__c != null ? opp.Number_of_Rescheduling_Done__c : 0;
            totalReschedulingAmount = getPerBookingReschedulingAmount(serviceDateTime, DateTime.now(), bookingAmount, packageName, reschedulingCount);
            //added by Abhishek 
            system.debug('totalReschedulingAmount>>>>'+totalReschedulingAmount);
            Long hoursDifference = serviceDateTime.getTime() - (DateTime.now()).getTime();
            hoursDifference = hoursDifference / (1000 * 60 * 60);  // Convert milliseconds to hours
            system.debug('hoursDifference>>>>'+hoursDifference);
            List<PricebookEntry> pbEntry = [SELECT Id, Product2Id, Product2.Name, Product2.Family, UnitPrice, Pricebook2Id, List_Price_In_Percentage__c FROM PricebookEntry 
                                            WHERE Pricebook2.IsActive = true AND Pricebook2.IsStandard = true AND Product2.Family ='Surcharge' LIMIT 1];
            List<OpportunityLineItem> opportunityLineItemsToInsert = new List<OpportunityLineItem>();
            /*
            if(hoursDifference <= 12 && submit){
                OpportunityLineItem oli = new OpportunityLineItem();
                    oli.OpportunityId = opportunityId;
                    oli.Product2Id = pbEntry[0].Product2Id;
                    oli.Quantity = 1;
                    oli.UnitPrice = pbEntry[0].UnitPrice;
                    oli.PricebookEntryId = pbEntry[0].Id; 
                    oli.Status__c = 'Rescheduled';
                    
                    PackageSelectionController.calculateGstApplicable(opp, oli);
                    opportunityLineItemsToInsert.add(oli);
            }
            if(!opportunityLineItemsToInsert.isEmpty()){
                insert opportunityLineItemsToInsert;
            }*/
            // abhishek changes End
            //if per booking charge not applicable then proceed
            if (totalReschedulingAmount == 0) {                
                for (opportunitylineitem oli: opp.opportunitylineitems) { 
                        decimal reschdulingChargesPerOli = getReschedulingAmount(serviceDateTime, DateTime.now(), oli.UnitPrice, packageName); 
                        totalReschedulingAmount += reschdulingChargesPerOli;
                        // to create final cancellation records
                        /*if(submit) {
                            oli.Status__c = 'Rescheduled';
                            oli.Rescheduling_Charges__c = reschdulingChargesPerOli;
                            oliList.add(oli);
                        } */      
                }
                ///update oliList;
                //New changes for order request
                if(submit) {
                    //get old Pending request and cancell it and create new
                    List<Order_Request__c> orderList = [
                        SELECT Id FROM Order_Request__c WHERE Status__c = 'Pending'
                        AND Change_Type__c = 'Reschedule'
                        ORDER BY CreatedDate DESC
                        LIMIT 1];
                    if (orderList !=null && orderList.size()>0) {
                        orderList[0].Status__c = 'Cancelled';
                        update orderList;
                    }
                    Order_Request__c order = new Order_Request__c();
                    order.Rescheduling_Charges__c = totalReschedulingAmount;
                    order.Total_Payable_Amount__c = totalReschedulingAmount;
                    if (OrderChangeRequest != null && !OrderChangeRequest.isEmpty()) {
                        for (String fieldName : OrderChangeRequest.keySet()) {
                            order.put(fieldName, OrderChangeRequest.get(fieldName));
                        }
                        OrderRequestController.generateOrderRequestNumber(opp, order);
                    }
                    orderRequestList.add(order);
                    insert orderRequestList; 
                    System.debug('-----------orderRequestList--->'+orderRequestList);
                    //logic for email sending
                    //RescheduleBookingPIController.generateAndSavePDF(opportunityId);
                    //MDEN_PaymentLinkGenerator.sendRequest(opportunityId);
                }
            } 
            //creation of transaction record if any deductions are done

            /*
            //commented as per new order request changes
            if(submit && totalReschedulingAmount !=0) {
                Transaction_History__c transactionRec= new Transaction_History__c();
                transactionRec.Booking_Id__c = opp.Id;
                transactionRec.Rescheduling_Charges__c = totalReschedulingAmount;
                transactionRec.Name = opp.Name;
                transactionRec.Transaction_Type__c = 'Credit';
                
                transactionList.add(transactionRec);
            } 
            insert transactionList;
            */
            
            //to show preview of Resheduling
            wrp.reschedulingAmount = totalReschedulingAmount;
            //wrp.reschedulingPolicyApplicable = reschedulingPolicy != '' ? reschedulingPolicy : 'N/A';
            wrp.reschedulingPolicyApplicable =  'https://encalm.com/termsandconditions';
            wrp.existingFlightNumber = opp.Flight_Number_Arrival__c !=null ? opp.Flight_Number_Arrival__c : opp.Flight_Number_Departure__c;
            wrp.existingTravelDateTime = combinedDateTimeStr != '' ? combinedDateTimeStr.substring(0, combinedDateTimeStr.length() - 3) : '';
            wrp.existingPackage = packageName;
            wrp.countOfRescheduling = reschedulingCount;
            wrp.totalBookingAmount = bookingAmount;

        return wrp;
    }

    
    public static void updateRescheduledChanges(Map<Id, Order_Request__c> bookingToOrderRequestMap) {
        try {
            List<Transaction_History__c> transactionList= new List<Transaction_History__c>();
            Set<Id> bookingIds = bookingToOrderRequestMap.keySet();

            // Query Opportunity Line Items linked to Booking__c (Opportunity)
            List<OpportunityLineItem> lineItems = [ 
                SELECT Id, OpportunityId, Rescheduling_Charges__c, Status__c
                FROM OpportunityLineItem 
                WHERE Product2.Family != 'Surcharge' AND Product2.Family != 'Add Ons' AND (Status__c = 'Active' OR Status__c = 'Rescheduled')
                AND OpportunityId IN :bookingIds
            ];

            Map<Id, List<OpportunityLineItem>> bookingToLineItemsMap = new Map<Id, List<OpportunityLineItem>>();
            for (OpportunityLineItem item : lineItems) {
                if (!bookingToLineItemsMap.containsKey(item.OpportunityId)) {
                    bookingToLineItemsMap.put(item.OpportunityId, new List<OpportunityLineItem>());
                }
                bookingToLineItemsMap.get(item.OpportunityId).add(item);
            }

            List<OpportunityLineItem> itemsToUpdate = new List<OpportunityLineItem>();
            List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
            List<Order_Request__c> orderRequestsToUpdate = new List<Order_Request__c>();

            for (Id bookingId : bookingToOrderRequestMap.keySet()) {
                Order_Request__c orderRequest = bookingToOrderRequestMap.get(bookingId);

                if (orderRequest != null) {
                    // Update Order Request Status to 'Completed'
                    orderRequest.Status__c = 'Completed';
                    orderRequestsToUpdate.add(orderRequest);
                    // Dynamically update Opportunity fields using Serialized_Data__c
                    Opportunity opp = new Opportunity(Id = bookingId);

                    if (String.isNotEmpty(orderRequest.Serialized_Data__c)) {
                        Map<String, Object> dataMap = (Map<String, Object>) JSON.deserializeUntyped(orderRequest.Serialized_Data__c);
                        
                        for (String fieldName : dataMap.keySet()) {
                            opp.put(fieldName, dataMap.get(fieldName)); // Dynamically setting field values
                        }
                    }

                    opportunitiesToUpdate.add(opp);

                    // Distribute Total_Payable_Amount__c across OpportunityLineItems
                    List<OpportunityLineItem> associatedItems = bookingToLineItemsMap.get(bookingId);
                    if (associatedItems != null && !associatedItems.isEmpty()) {
                        Decimal amountPerItem = orderRequest.Total_Payable_Amount__c / associatedItems.size();
                        for (OpportunityLineItem item : associatedItems) {
                            item.Rescheduling_Charges__c = amountPerItem;
                            item.Status__c = 'Rescheduled'; // Updating Status
                            itemsToUpdate.add(item);
                        }
                    }
                    //Create Transaction History Record
                    Transaction_History__c transactionRec= new Transaction_History__c();
                    transactionRec.Booking_Id__c = opp.Id;
                    transactionRec.Rescheduling_Charges__c = orderRequest.Total_Payable_Amount__c;
                    transactionRec.Name = opp.Name;
                    transactionRec.Transaction_Type__c = 'Credit';
                    
                    transactionList.add(transactionRec);
                }
            }

            // Performing all DMLS
            if (!orderRequestsToUpdate.isEmpty()) {
                update orderRequestsToUpdate; // Updating Order Request Status to 'Completed'
            }

            if (!opportunitiesToUpdate.isEmpty()) {
                update opportunitiesToUpdate;
            }

            if (!itemsToUpdate.isEmpty()) {
                update itemsToUpdate;
            }

            if (!transactionList.isEmpty()) {
                insert transactionList;
            }
        }  catch (Exception e) {
            System.debug('Error occurred in updateRescheduledChanges method: ' + e.getMessage());
        }
    }
    
    public class bookingWrapper {
        @AuraEnabled
        public String serviceType;
        @AuraEnabled
        public Decimal NoOfAdult;
        @AuraEnabled
        public Decimal NoOfChild;
        @AuraEnabled
        public Decimal NoOfInfant;
        @AuraEnabled
        public String serviceAirport;
        @AuraEnabled
        public String flightNumberArrival;
        @AuraEnabled
        public String flightNumberDeparture;
        @AuraEnabled
        public Date departureDate;
        @AuraEnabled
        public Date arrivalDate;
        @AuraEnabled
        public String arrivingAirport;
        @AuraEnabled
        public String departureAirport;
        @AuraEnabled
        public String sector;
        @AuraEnabled
        public String staTime;
        @AuraEnabled
        public String stdTime;
        @AuraEnabled
        public String stdServiceTime;
        @AuraEnabled
        public Boolean hasPendingRequest = false;
    }

    public class ReschedulingDetailsWrapper {
        @AuraEnabled public String existingPackage;
        @AuraEnabled public String existingFlightNumber;
        @AuraEnabled public Decimal reschedulingAmount;
        @AuraEnabled public String reschedulingPolicyApplicable;
        @AuraEnabled public String existingTravelDateTime;
        @AuraEnabled public Decimal countOfRescheduling;
        @AuraEnabled public Decimal totalBookingAmount;
    }
}