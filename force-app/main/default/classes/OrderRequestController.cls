public with sharing class OrderRequestController {

    @AuraEnabled(cacheable=true)
    public static Boolean hasOpenRequest(String opportunityId) {
        List<Order_Request__c> orderRequests =  [SELECT Id 
                FROM Order_Request__c WHERE Booking__c = :opportunityId
                AND isSubRequest__c = false
                AND Status__c = 'Pending'];

        return orderRequests.size() > 0;
    }

    @AuraEnabled
    public static List<Order_Request__c> getAllOrderRequests(String opportunityId) {
        return [SELECT Id, Name, Booking__r.Name, Status__c,Order_Request_Number__c, Change_Type__c, CreatedDate,Type_of_Amendment__c 
                FROM Order_Request__c WHERE Booking__c = :opportunityId
                AND isSubRequest__c = false
                ORDER BY CreatedDate DESC];
    }

    @AuraEnabled(cacheable=true)
    public static Order_Request__c getPendingRequest(String opportunityId) {
        List<Order_Request__c> requestList=  [SELECT Id, Name,Total_Payable_Amount__c, Booking__r.Name, Status__c,Order_Request_Number__c, Change_Type__c, CreatedDate,Type_of_Amendment__c 
                FROM Order_Request__c WHERE Booking__c = :opportunityId
                AND isSubRequest__c = false
                AND Status__c = 'Pending'];
        if (requestList !=null && !requestList.isEmpty()) {
            return requestList[0];
        }
        return null;
    }

    @AuraEnabled
    public static Order_Request__c cloneRequest(Id recordId) {
        Order_Request__c original = [SELECT Id, Booking__c, Change_Type__c, Serialized_Data__c 
                                      FROM Order_Request__c WHERE Id = :recordId];
        Order_Request__c clone = original.clone(false, true, false, false);
        insert clone;
        return clone;
    }

    @AuraEnabled
    public static void cancelRequest(Id recordId) {
        List<Order_Request__c> childToCancel = new List<Order_Request__c>();
        Order_Request__c record = [SELECT Id,(SELECT Id, Status__c FROM Order_Request__r WHERE Parent_Order_Request__c =: recordId) FROM Order_Request__c WHERE Id = :recordId];
        record.Status__c = 'Cancelled';

        for(Order_Request__c child : record.Order_Request__r) {
            child.Status__c = 'Cancelled';
            childToCancel.add(child);
        }
        update record;
        update childToCancel;
    }

    @AuraEnabled
    public static String getSerializedData(Id recordId) {
        Order_Request__c record = [SELECT Serialized_Data__c FROM Order_Request__c WHERE Id = :recordId];
        return record.Serialized_Data__c;
    }

    @AuraEnabled
    public static String getPaymentLink(String recordId) {
        // Mock implementation – replace with your payment integration
        return 'https://payment.example.com/pay?changeId=' + recordId;
    }

    @AuraEnabled
    public static Map<Id, DateTime> getStatusChangeDates(Id opportunityId) {
        Map<Id, DateTime> statusChangeMap = new Map<Id, DateTime>();

        // Get all Order_Request__c records for the Opportunity
        List<Order_Request__c> changes = [
            SELECT Id FROM Order_Request__c WHERE Booking__c = :opportunityId
        ];

        Set<Id> changeIds = new Set<Id>();
        for (Order_Request__c c : changes) {
            changeIds.add(c.Id);
        }

        // Get all history for Status__c field (can't filter on NewValue directly)
        List<Order_Request__History> history = [
            SELECT ParentId, NewValue, CreatedDate
            FROM Order_Request__History
            WHERE Field = 'Status__c'
            AND ParentId IN :changeIds
            ORDER BY CreatedDate DESC
        ];

        for (Order_Request__History h : history) {
            if ((String.valueOf(h.NewValue) == 'Completed' || String.valueOf(h.NewValue) == 'Cancelled') &&
                !statusChangeMap.containsKey(h.ParentId)) {
                statusChangeMap.put(h.ParentId, h.CreatedDate);
            }
        }

        return statusChangeMap;
    }

    @AuraEnabled(cacheable=true)
    public static Order_Request__c getLatestPendingRescheduleOrderRequest(Id orderRecId) {
        return [SELECT Id, Arrival_Service_Time__c,Date_of_Arrival__c,Flight_Number_Arrival__c,Service_Type__c,STA_Time__c,STD_Time__c,
        Date_of_Departure__c,Departure_Service_Time__c,Flight_Number_Departure__c,Change_Type__c, Status__c, Service_Time__c,
        Booking__r.Service_Airport__c, Booking__r.Departure_Airport__c,Booking__r.Flight_Type__c, Booking__r.Arriving_Airport__c
        FROM Order_Request__c
                WHERE Id = :orderRecId
                AND Change_Type__c = 'Reschedule'
                ORDER BY CreatedDate DESC
                LIMIT 1];
    }

    public static void calculateGstApplicable(Opportunity opp, Order_Request__c orderRequest) {

        Decimal gstRate = 18;  // 18% GST
        String billingState = opp.Account.BillingState;
        String serviceAirportState = opp.Service_Airport_Id__c !=null ? opp.Service_Airport_Id__r.State__c : '';
        Boolean isNotIgst =false;
        if (opp.Account.GST_Registration_Type__c != 'Non-Resident taxable person' &&
            opp.Account.GST_Registration_Type__c != 'Special Economic Zone (SEZ) developer/unit') {
                isNotIgst = true;
            }

        //Logic for GST calculation
        Decimal invoiceAmount = orderRequest.Total_List_Price__c / (1 + (gstRate / 100)); // Invoice amount (after GST)
        Decimal totalGST = orderRequest.Total_List_Price__c - invoiceAmount; // Total GST

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
        orderRequest.Invoice_Amount__c = invoiceAmount;
        orderRequest.SGST__c = sgstAmount;
        orderRequest.CGST__c = cgstAmount;
        orderRequest.IGST__c = igstAmount;        
    }

    @AuraEnabled(cacheable=true)
    public static void generateOrderRequestNumber(Opportunity opp, Order_Request__c orderRequest) {
        List<Order_Request__c> requestList = [SELECT Id, Order_Request_Number__c, Booking__r.Name
                                            FROM Order_Request__c 
                                            WHERE Booking__c = :opp.Id 
                                            AND isSubRequest__c = false 
                                            ORDER BY CreatedDate DESC LIMIT 1];

        String newRequestNumber;
        
        if (requestList != null && !requestList.isEmpty()) {
            Order_Request__c lastRequest = requestList[0];
            if (lastRequest.Order_Request_Number__c !=null && lastRequest.Order_Request_Number__c.contains('-')) {
                
                String lastNumberStr = lastRequest.Order_Request_Number__c.split('-').get(1); 
                
                Integer lastNumber = Integer.valueOf(lastNumberStr);
                Integer newNumber = lastNumber + 1;
                String formattedNewNumber = String.valueOf(newNumber).leftPad(3, '0'); 
                
                newRequestNumber = lastRequest.Booking__r.Name + '-' + formattedNewNumber;
            } else {
                newRequestNumber = opp.Name + '-001';
            }
        } else {
            newRequestNumber = opp.Name + '-001';
        }

        orderRequest.Order_Request_Number__c = newRequestNumber;
    }

    @AuraEnabled(cacheable=true)
    public static void generatePaymentLink(String oppId) {
        MDEN_PaymentLinkGenerator.sendRequest(oppId);
    }
    @AuraEnabled
    public static void updateDataFromOrderRequest(
        List<Id> opportunityIds
        ) {
            try{    // Query related Order_Request__c records
                Map<Id, Order_Request__c> RescBookingOrderRequestMap = new Map<Id, Order_Request__c>();
                List<Order_Request__c> addPassengerOrderRequestList = new List<Order_Request__c>();
                List<Order_Request__c> upgradePackageOrderRequestList = new List<Order_Request__c>();
                List<Order_Request__c> addAddOnsOrderRequestList = new List<Order_Request__c>();
                List<Order_Request__c> orderRequests = [
                    SELECT Type_of_Amendment__c,Booking__c, Serialized_Data__c, Change_Type__c,Total_Payable_Amount__c,Status__c,
                    Number_of_Children__c,Number_of_Adults__c,Number_of_Infants__c,Product__r.Package_Is_For__c,
                    (SELECT Id,Serialized_Data__c,Booking__c,Product__r.Package_Is_For__c FROM Order_Request__r WHERE isSubRequest__c = true) 
                    FROM Order_Request__c 
                    WHERE Booking__c IN :opportunityIds
                    AND Status__c = 'Pending'
                    ORDER BY isSubRequest__c
                ];

                for (Order_Request__c order : orderRequests) {
                    if (order.Change_Type__c  == 'Reschedule') {
                        RescBookingOrderRequestMap.put(order.Booking__c, order);
                    } else if (order.Change_Type__c  == 'Amendment' && order.Order_Request__r !=null && order.Order_Request__r.size() >0) {
                        if (order.Type_of_Amendment__c == 'Add Passengers') {
                            addPassengerOrderRequestList.add(order);
                        } else if (order.Type_of_Amendment__c == 'Upgrade Package') {
                            upgradePackageOrderRequestList.add(order);
                        } else if (order.Type_of_Amendment__c == 'Add Add-Ons') {
                            addAddOnsOrderRequestList.add(order);
                        }
                    }
                }
                if (!RescBookingOrderRequestMap.isEmpty()) {
                    RescheduleBooking.updateRescheduledChanges(RescBookingOrderRequestMap);
                }
                if (!addPassengerOrderRequestList.isEmpty()) {
                    AmendmentBookingController.addPassengerAmendedOrders(addPassengerOrderRequestList);
                }
                if (!upgradePackageOrderRequestList.isEmpty()) {
                    AmendmentBookingController.packageUpgradeAmendedOrders(upgradePackageOrderRequestList);
                }
                if (!addAddOnsOrderRequestList.isEmpty()) {
                    AmendmentBookingController.AddOnsAmendedOrders(addAddOnsOrderRequestList);
                }
            } catch (Exception e) {
                System.debug('Error occurred in updateDataFromOrderRequest method: ' + e.getMessage());
            }
        }

        

    @AuraEnabled(cacheable=true)
    public static OrderRequestData getLatestAmendmentOrderRequest(Id orderRecId) {
        List<Order_Request__c> parentOrderReq = [SELECT Type_of_Amendment__c, Booking__c,Status__c,Change_Type__c,Serialized_Data__c, Number_of_Adults__c,
        Number_of_Children__c, Number_of_Infants__c,Product__c,Total_List_Price__c,
        Invoice_Amount__c,SGST__c,CGST__c,IGST__c,isSubRequest__c,Parent_Order_Request__c,Pickup_Terminal__c,
        Drop_Terminal__c,Package_Type__c,Order_Request_Number__c,Total_Payable_Amount__c
        FROM Order_Request__c
        WHERE Id = :orderRecId
        ORDER BY CreatedDate DESC
        ];
        if(parentOrderReq == null || parentOrderReq.isEmpty()) {
            return null;
        }
        OrderRequestData orderRequestData = new OrderRequestData();
        orderRequestData.parentOrderRequest = new OrderRequestWrapper();
        orderRequestData.parentOrderRequest.typeOfAmendment = parentOrderReq[0].Type_of_Amendment__c;

        // 2. Load Passenger Details
        List<Passenger_Details__c> passengers = [
            SELECT Id, Title__c, First_Name__c, Last_Name__c, Gender__c, Age__c, Designation__c, 
                   Travel_Class__c, Travel_PNR_No__c, Nationalities__c, Passport_Govt_Id__c, Mobile__c, 
                   Passenger_Type__c, Individual_Booking_Details__c, Show_as_Placard__c, Unique_Id__c
            FROM Passenger_Details__c
            WHERE Order_Request__r.Parent_Order_Request__c=:orderRecId
        ];

        orderRequestData.passengers = new List<PassengerWrapper>();

        for (Passenger_Details__c p : passengers) {

            PassengerWrapper pw = new PassengerWrapper();
            pw.id = p.Unique_Id__c;
            pw.title = p.Title__c;
            pw.firstname = p.First_Name__c;
            pw.lastname = p.Last_Name__c;
            pw.gender = p.Gender__c;
            pw.age = p.Age__c != null ? String.valueOf(p.Age__c) : null;
            pw.designation = p.Designation__c;
            pw.travelclass = p.Travel_Class__c;
            pw.travelpnrno = p.Travel_PNR_No__c;
            pw.nationality = p.Nationalities__c;
            pw.passportnumber = p.Passport_Govt_Id__c;
            pw.phone = p.Mobile__c;
            pw.type = p.Passenger_Type__c;
            orderRequestData.passengers.add(pw);
        }
        return orderRequestData;
    }

    public class OrderRequestData {
        @AuraEnabled public OrderRequestWrapper parentOrderRequest;
        @AuraEnabled public List<PassengerWrapper> passengers;
    }

    public class OrderRequestWrapper {
        @AuraEnabled public String typeOfAmendment;
    }

    public class PassengerWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String title;
        @AuraEnabled public String firstname;
        @AuraEnabled public String lastname;
        @AuraEnabled public String gender;
        @AuraEnabled public String age;
        @AuraEnabled public String designation;
        @AuraEnabled public String travelclass;
        @AuraEnabled public String travelpnrno;
        @AuraEnabled public String nationality;
        @AuraEnabled public String passportnumber;
        @AuraEnabled public String phone;
        @AuraEnabled public String type;
        @AuraEnabled public Boolean isPlacard;
    }

}