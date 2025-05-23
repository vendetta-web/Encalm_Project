public class CancellationPolicyService {
    public static Set<String> checkUniqueRefundPolicy = new Set<String>();    
    public static String refundPolicy='';
    public static String addAnd =' & ';

    public static Decimal getGeneralCancellationPolicyAmount(DateTime serviceDateTime, DateTime cancellationDateTime, Decimal bookingAmount) {
        if (refundPolicy != '') {
            addAnd = ' & ';
        } else {
            addAnd = '';
        }

        Long hoursDifference = serviceDateTime.getTime() - cancellationDateTime.getTime();
        hoursDifference = hoursDifference / (1000 * 60 * 60);  // Convert milliseconds to hours
        Cancellation_And_Refund__mdt generalMetadataRecord = Cancellation_And_Refund__mdt.getInstance('Cancellation_General_Bank_Charges');
        if (generalMetadataRecord != null &&
            generalMetadataRecord.Less_Than__c && 
            hoursDifference < Long.valueOf(generalMetadataRecord.Time_Frame__c)) {
                if (generalMetadataRecord.Charges_in_Percentage__c) {
                    if (!checkUniqueRefundPolicy.contains(generalMetadataRecord.Refund_Policy__c)) {
                        checkUniqueRefundPolicy.add(generalMetadataRecord.Refund_Policy__c);
                        refundPolicy = refundPolicy + addAnd + generalMetadataRecord.Refund_Policy__c;
                    }
                    return bookingAmount = bookingAmount - (bookingAmount * (generalMetadataRecord.Charges__c / 100));
                } else {
                    if (!checkUniqueRefundPolicy.contains(generalMetadataRecord.Refund_Policy__c)) {
                        checkUniqueRefundPolicy.add(generalMetadataRecord.Refund_Policy__c);
                        refundPolicy = refundPolicy + addAnd + generalMetadataRecord.Refund_Policy__c;
                    }
                    return bookingAmount = bookingAmount - generalMetadataRecord.Charges__c;
                } 
        } else if (generalMetadataRecord != null &&
            generalMetadataRecord.Greater_Than__c && 
            Long.valueOf(generalMetadataRecord.Time_Frame__c) < hoursDifference) {
            if (generalMetadataRecord.Charges_in_Percentage__c) {
                if (!checkUniqueRefundPolicy.contains(generalMetadataRecord.Refund_Policy__c)) {
                    checkUniqueRefundPolicy.add(generalMetadataRecord.Refund_Policy__c);
                    refundPolicy = refundPolicy + addAnd + generalMetadataRecord.Refund_Policy__c;
                }
                return bookingAmount = bookingAmount - (bookingAmount * (generalMetadataRecord.Charges__c / 100));
            } else {
                if (!checkUniqueRefundPolicy.contains(generalMetadataRecord.Refund_Policy__c)) {
                    checkUniqueRefundPolicy.add(generalMetadataRecord.Refund_Policy__c);
                    refundPolicy = refundPolicy + addAnd + generalMetadataRecord.Refund_Policy__c;
                }
                return bookingAmount = bookingAmount - generalMetadataRecord.Charges__c;
            } 
        }
        return bookingAmount;
    }

    public static Decimal getCancellationPolicyAmount(DateTime serviceDateTime, DateTime cancellationDateTime, Decimal bookingAmount, String packageName) {
        // Calculate the difference in hours between the service and cancellation times
        Long hoursDifference = serviceDateTime.getTime() - cancellationDateTime.getTime();
        hoursDifference = hoursDifference / (1000 * 60 * 60);  // Convert milliseconds to hours
        if (refundPolicy != '') {
            addAnd = ' & ';
        } else {
            addAnd = '';
        }
        // Query the cancellation policies
        List<Cancellation_And_Refund__mdt> policies = [SELECT MasterLabel, Time_Frame__c,
                                                   Charges_in_Percentage__c, Charges__c,
                                                   Greater_Than__c, Less_Than__c, Package__c,Refund_Policy__c
                                                   FROM Cancellation_And_Refund__mdt 
                                                   WHERE IsActive__c = true
                                                   AND (Package__c =:packageName)
                                                   ORDER BY Sort_Order__c];

        // Iterate through policies to find the applicable one
        for (Cancellation_And_Refund__mdt policy : policies) {
                if (policy.Less_Than__c &&  hoursDifference < Long.valueOf(policy.Time_Frame__c)) {
                    if (policy.Charges_in_Percentage__c) {
                        if (!checkUniqueRefundPolicy.contains(policy.Refund_Policy__c)) {
                            checkUniqueRefundPolicy.add(policy.Refund_Policy__c);
                            refundPolicy = refundPolicy + addAnd + policy.Refund_Policy__c;
                        }
                        return bookingAmount - (bookingAmount * (policy.Charges__c / 100));
                    } else {
                        if (!checkUniqueRefundPolicy.contains(policy.Refund_Policy__c)) {
                            checkUniqueRefundPolicy.add(policy.Refund_Policy__c);
                            refundPolicy = refundPolicy + addAnd + policy.Refund_Policy__c;
                        }
                        return bookingAmount - policy.Charges__c;
                    } 
                } 
                else if (policy.Greater_Than__c && Long.valueOf(policy.Time_Frame__c) < hoursDifference) {
                    if (policy.Charges_in_Percentage__c) {
                        if (!checkUniqueRefundPolicy.contains(policy.Refund_Policy__c)) {
                            checkUniqueRefundPolicy.add(policy.Refund_Policy__c);
                            refundPolicy = refundPolicy + addAnd + policy.Refund_Policy__c;
                        }
                        return bookingAmount - (bookingAmount * (policy.Charges__c / 100));
                    } else {
                        if (!checkUniqueRefundPolicy.contains(policy.Refund_Policy__c)) {
                            checkUniqueRefundPolicy.add(policy.Refund_Policy__c);
                            refundPolicy = refundPolicy + addAnd + policy.Refund_Policy__c;
                        }
                        return bookingAmount - policy.Charges__c;
                    } 
                }
                else if (policy.Time_Frame__c.contains('-')) {
                    List<String> rangeValues = policy.Time_Frame__c.split('-');
                    Integer lowerValue = Integer.valueOf(rangeValues[0]); // First value (24)
                    Integer upperValue = Integer.valueOf(rangeValues[1]); // Second value (48)
                    if (hoursDifference > lowerValue && hoursDifference < upperValue) {
                        if (policy.Charges_in_Percentage__c) {
                            if (!checkUniqueRefundPolicy.contains(policy.Refund_Policy__c)) {
                                checkUniqueRefundPolicy.add(policy.Refund_Policy__c);
                                refundPolicy = refundPolicy + addAnd + policy.Refund_Policy__c;
                            }
                            return bookingAmount - (bookingAmount * (policy.Charges__c / 100));
                        } else {
                            if (!checkUniqueRefundPolicy.contains(policy.Refund_Policy__c)) {
                                checkUniqueRefundPolicy.add(policy.Refund_Policy__c);
                                refundPolicy = refundPolicy + addAnd + policy.Refund_Policy__c;
                            }
                            return bookingAmount - policy.Charges__c;
                        } 
                    }
                }
                else if (policy.Time_Frame__c == 'Unlimited') {
                    if (policy.Charges_in_Percentage__c) {
                        if (!checkUniqueRefundPolicy.contains(policy.Refund_Policy__c)) {
                            checkUniqueRefundPolicy.add(policy.Refund_Policy__c);
                            refundPolicy = refundPolicy + addAnd + policy.Refund_Policy__c;
                        }
                        bookingAmount = bookingAmount - (bookingAmount * (policy.Charges__c / 100));
                    } else {
                        if (!checkUniqueRefundPolicy.contains(policy.Refund_Policy__c)) {
                            checkUniqueRefundPolicy.add(policy.Refund_Policy__c);
                            refundPolicy = refundPolicy + addAnd + policy.Refund_Policy__c;
                        }
                        bookingAmount = bookingAmount - policy.Charges__c;
                    } 
                }
            
        }
        // Default to no charge if no policy matches
        return bookingAmount;
    }

    @AuraEnabled
    public static cancellationDetailsWrapper showCancellationCharges(String cancelType,
    List<Map<String, Object>> selectedOrders,
        Decimal bookingAmount,
        String packageName,
        String opportunityId,
        Integer numberOfPax,
        Boolean submit) {
        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();        
        Set<Id> cancelledOli = new Set<Id>();
        cancellationDetailsWrapper wrp = new cancellationDetailsWrapper();
        List<Transaction_History__c> transactionList= new List<Transaction_History__c>();
        List<Case> caseList = new List<Case>();
        DateTime requestDateTime;
        DateTime serviceDateTime;
        String dateText;
        String timeText;
        String combinedDateTimeStr;
        
        // Query OpportunityLineItems based on OpportunityId
        Opportunity opp = [
            SELECT STA_Time__c,STD_Time__c,Date_of_Arrival__c,Date_of_Departure__c,Amount,Name,Number_of_Adults__c,Number_of_Children__c,Number_of_Infants__c,
            Account.BillingState, Service_Airport_Id__r.State__c,Service_Airport_Id__c,Account.GST_Registration_Type__c,Departure_Service_Time__c,
            (SELECT Id,Product2.Family,UnitPrice,PricebookEntryId FROM opportunitylineitems WHERE Status__c = 'Active' OR Status__c = 'Rescheduled') 
            FROM Opportunity
            WHERE Id=:opportunityId
            LIMIT 1
        ];

        Decimal gstRate = 0.18;  // 18% GST
        String billingState = opp.Account.BillingState;
        String serviceAirportState = opp.Service_Airport_Id__c !=null ? opp.Service_Airport_Id__r.State__c : '';
        Boolean isNotIgst =false;
        if (opp.Account.GST_Registration_Type__c != null &&
            opp.Account.GST_Registration_Type__c != 'Non-Resident taxable person' &&
            opp.Account.GST_Registration_Type__c != 'Special Economic Zone (SEZ) developer/unit') {
                isNotIgst = true;
            }

        caseList = [
            SELECT Id, CreatedDate
            FROM Case
            WHERE Booking__c =:opportunityId
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        if (!caseList.isEmpty() && caseList !=null) {
            requestDateTime = caseList[0].CreatedDate;
        } else {
            requestDateTime = DateTime.now();
        }
        
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
            timeText= opp.Departure_Service_Time__c !=null ? opp.Departure_Service_Time__c : opp.STD_Time__c;// Ensure timeText includes seconds
            if (timeText.length() == 5) {  // "HH:mm" format
                timeText += ':00';  // Append ":00" for seconds
            }
            combinedDateTimeStr=dateText + ' ' + timeText;
            serviceDateTime = DateTime.valueOf(combinedDateTimeStr);
        }
        //both scenarios of preview of cancellation and creating cancellation records for full cancellation
        if (cancelType =='fullCancel') {  
            numberOfPax=0;   
            bookingAmount = 0;  
            Decimal refundAmount = 0;   
            for (opportunitylineitem oli: opp.opportunitylineitems) {
                if (oli.Product2.Family != 'Surcharge') {   
                    numberOfPax = numberOfPax + 1;
                }
                packageName = oli.Product2.Family;
                bookingAmount += oli.UnitPrice; 
                decimal refundAmountPerOli = getCancellationPolicyAmount(serviceDateTime, requestDateTime, oli.UnitPrice, packageName); 
                refundAmountPerOli =  getGeneralCancellationPolicyAmount(serviceDateTime, requestDateTime, refundAmountPerOli);
                refundAmount += refundAmountPerOli;
                // to create final cancellation records
                if(submit) {
                    oli.Status__c = 'Fully Cancelled';
                    oli.Refund_Amount__c = refundAmountPerOli;
                    oli.Amount_Deducted__c= oli.UnitPrice-refundAmountPerOli;
                    //Logic for GST calculation
                    Decimal totalGST = oli.Amount_Deducted__c * gstRate; // Total GST
                    Decimal invoiceAmount = oli.Amount_Deducted__c - totalGST; // Invoice amount (after GST)

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
                    oliList.add(oli);
                    //update opportunity fields
                    opp.Number_of_Adults__c=0;
                    opp.Number_of_Children__c=0;
                    opp.Number_of_Infants__c=0;
                    update opp;
                    if(!Test.IsRunningTest()){
                    	getSWIFTTokenFuture(opportunityId,'Cancel'); //MDEN_SWIFT.getAccessToken(opportunityId,'Cancel');
                    }
                }          
            }
            update oliList;  
            
            //to show preview of full cancellation
            //decimal afterGeneralCancellationRefund =  getGeneralCancellationPolicyAmount(serviceDateTime, requestDateTime, refundAmount);
            wrp.bookingAmount = bookingAmount;
            wrp.refundAmount = refundAmount;
            wrp.deductedAmount = bookingAmount - refundAmount;
            wrp.refundMethod = 'Original Payment Mode';
            wrp.numberOfPaxCancelled = numberOfPax;
            wrp.refundPolicyApplicable = refundPolicy != '' ? refundPolicy : 'N/A';

            
            //creation of transaction record if any refund is done for full cancellation
            if(submit && refundAmount !=0) {
                Transaction_History__c transactionRec= new Transaction_History__c();
                transactionRec.Booking_Id__c = opportunityId;
                transactionRec.Cancellation_Charges__c = bookingAmount - refundAmount;
                transactionRec.Refund_Charges__c = refundAmount;
                transactionRec.Name = opp.Name;
                transactionRec.Transaction_Type__c = 'Debit';
                
                transactionList.add(transactionRec);
                
                insert transactionList;
            } 
        }

        /*
        //to show the preview for partial cancel
        if (cancelType !='fullCancel') {
            decimal afterCancellationRefundAmount = getCancellationPolicyAmount(serviceDateTime, DateTime.now(), bookingAmount, packageName);
            decimal afterGeneralCancellationRefund =  getGeneralCancellationPolicyAmount(serviceDateTime, DateTime.now(), afterCancellationRefundAmount);
            wrp.bookingAmount = bookingAmount;
            wrp.refundAmount = afterGeneralCancellationRefund;
            wrp.deductedAmount = bookingAmount - afterGeneralCancellationRefund;
            wrp.refundMethod = 'Original Payment Mode';
            wrp.numberOfPaxCancelled = numberOfPax;
            wrp.refundPolicyApplicable = refundPolicy;
        }*/

        //to create final cancellation record for partial cancel
        if (cancelType !='fullCancel') {      
            //Decimal refundAmountWithoutGeneralCharges = 0;  
            Decimal generalDeduction = 0;
            Integer count = 0;  
            String paxNames = ''; 
            Decimal partialBookingAmount=0;
            Decimal partialRefundAmount=0; 
            for (Map<String, Object> row : selectedOrders) {      
                String pckName = (String) row.get('packageName');
                Decimal perUnitPrice = (Decimal) row.get('unitPrice');               
                decimal refundAmountPerOli = getCancellationPolicyAmount(serviceDateTime, requestDateTime, perUnitPrice, pckName);
                
                refundAmountPerOli =  getGeneralCancellationPolicyAmount(serviceDateTime, requestDateTime, refundAmountPerOli);
                //refundAmountWithoutGeneralCharges += refundAmountPerOli;
                //generalDeduction = refundAmountWithoutGeneralCharges;
                if (count == 0) {
                    paxNames = (String) row.get('name') !=null ? (String) row.get('name') : '';
                } else {
                    paxNames = paxNames + ', ' + (String) row.get('name');
                } 
                if((Id) row.get('oliId') !=null) {
                    OpportunityLineItem oli = new OpportunityLineItem(); 
                    oli.Id = (Id) row.get('oliId');
                    cancelledOli.add(oli.Id);
                    oli.Status__c = 'Partially Cancelled';
                    oli.Refund_Amount__c = refundAmountPerOli;
                    oli.Amount_Deducted__c= perUnitPrice -  refundAmountPerOli;
                    //Logic for GST calculation
                    Decimal totalGST = oli.Amount_Deducted__c * gstRate; // Total GST
                    Decimal invoiceAmount = oli.Amount_Deducted__c - totalGST; // Invoice amount (after GST)

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
                    oliList.add(oli);
                }  
                count++;
                partialBookingAmount += perUnitPrice;
                partialRefundAmount += refundAmountPerOli;
            }
            //to show preview of partial cancellation

            wrp.bookingAmount = partialBookingAmount;
            wrp.refundAmount = partialRefundAmount;
            
            wrp.deductedAmount = wrp.bookingAmount - wrp.refundAmount;
            wrp.refundMethod = 'Original Payment Mode';
            wrp.numberOfPaxCancelled = numberOfPax;
            wrp.refundPolicyApplicable = refundPolicy != '' ? refundPolicy : 'N/A';
            wrp.paxNames = paxNames != '' ? paxNames : '';

            if (submit) {
                update oliList;  
                //creation of transaction record if any refund is done for partial cancellation
                if(wrp.refundAmount !=0) {
                    Transaction_History__c transactionRec= new Transaction_History__c();
                    transactionRec.Booking_Id__c = opportunityId;
                    transactionRec.Cancellation_Charges__c = wrp.deductedAmount;
                    transactionRec.Refund_Charges__c = wrp.refundAmount;
                    transactionRec.Name = opp.Name;
                    transactionRec.Transaction_Type__c = 'Debit';
                    
                    transactionList.add(transactionRec);
                } 
                insert transactionList;
                
                /*if (!cancelledOli.isEmpty()) {
                    List<Passenger_Details__c> deletePassenger = [ SELECT Id FROM Passenger_Details__c WHERE Opportunity_ID__c =:opportunityId 
                                                                    AND Individual_Booking_Details__c IN: cancelledOli];                

                    if(!deletePassenger.IsEmpty()){
                        delete deletePassenger;
                    }
                }*/

                List<Passenger_Details__c> updatePaxList = [
                SELECT Id,Passenger_Type__c FROM Passenger_Details__c 
                WHERE Opportunity_ID__c =:opportunityId 
                AND Individual_Booking_Details__c NOT IN: cancelledOli];

                Decimal adultCount = 0;
                Decimal childCount = 0;
                Decimal infantCount = 0;

                if(updatePaxList != null && updatePaxList.size() > 0) {
                    for (Passenger_Details__c pax: updatePaxList) {
                        switch on pax.Passenger_Type__c {
                            when 'Adult' {
                                adultCount++;
                            }
                            when 'Child' {
                                childCount++;
                            }
                            when 'Infant' {
                                infantCount++;
                            }
                        }
                    }
                    opp.Number_of_Adults__c=adultCount;
                    opp.Number_of_Children__c=childCount;
                    opp.Number_of_Infants__c=infantCount;
                    update opp;
                }
                if(!Test.IsRunningTest()){
                	getSWIFTTokenFuture(opportunityId,'Partially Cancelled'); //MDEN_SWIFT.getAccessToken(opportunityId,'Partially Cancelled');
                }
                
            }
        }
        if(numberOfPax == 0) {
            return null;
        }
        return wrp;
    }
    
    @future(callout=true)
    public static void getSWIFTTokenFuture(String opportunityId, String actionType) {
        MDEN_SWIFT.getAccessToken(opportunityId, actionType);
    }
    
    @AuraEnabled(cacheable=true)
    public static List<passengerDetailsWrapper> getBookingToCancel(String opportunityId) {
        List<passengerDetailsWrapper> pdList = new List<passengerDetailsWrapper>();

        // Query OpportunityLineItems based on OpportunityId
        List<Passenger_Details__c> passengerList = [
            SELECT Id,Name, Individual_Booking_Details__r.UnitPrice, Individual_Booking_Details__c,
            Passenger_Type__c, Individual_Booking_Details__r.Product2.Family, Individual_Booking_Details__r.PricebookEntryId,
            Individual_Booking_Details__r.Status__c
            FROM Passenger_Details__c
            WHERE Opportunity_ID__c=:opportunityId AND (Individual_Booking_Details__r.Status__c = 'Active'
            OR Individual_Booking_Details__r.Status__c = 'Rescheduled')
        ];

        // Populate wrapper class list
        for (Passenger_Details__c pd : passengerList) {
            if(pd.Individual_Booking_Details__r.Status__c == 'Active'|| pd.Individual_Booking_Details__r.Status__c == 'Rescheduled'){  
                passengerDetailsWrapper passenger = new passengerDetailsWrapper();
                passenger.id = pd.Id;
                passenger.oliId = pd.Individual_Booking_Details__c;
                passenger.name = pd.Name;
                passenger.packageName = pd.Individual_Booking_Details__r.Product2.Family;
                passenger.unitPrice = pd.Individual_Booking_Details__r.UnitPrice;
                passenger.quantity = 1;
                passenger.type = pd.Passenger_Type__c;
                passenger.pbenteryId =pd.Individual_Booking_Details__r.PricebookEntryId;                              
                pdList.add(passenger);
            }
        }

        List<OpportunityLineItem> oliAddOnList = [SELECT Id,Product2.Family,PricebookEntryId,Status__c,Product2.Name,UnitPrice,Quantity
                                            FROM OpportunityLineItem
                                            WHERE Status__c = 'Active' AND Product2.Family='Add Ons' AND OpportunityId=:opportunityId];
        if (oliAddOnList != null) {
            for (OpportunityLineItem oli: oliAddOnList) {
                passengerDetailsWrapper wrap = new passengerDetailsWrapper();
                wrap.oliId = oli.Id;
                wrap.name = oli.Product2.Name;
                wrap.packageName = oli.Product2.Family;
                wrap.unitPrice = oli.UnitPrice;
                wrap.quantity = Integer.valueOf(oli.Quantity);
                wrap.type = oli.Product2.Family;
                wrap.pbenteryId = oli.PricebookEntryId;
                pdList.add(wrap);
            }
        }
        return pdList;
    }

    // Wrapper class to hold passengerDetails fields
    public class passengerDetailsWrapper {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String oliId { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String packageName { get; set; }
        @AuraEnabled public Decimal unitPrice { get; set; }
        @AuraEnabled public Integer quantity { get; set; }
        @AuraEnabled public String type { get; set; }
        @AuraEnabled public String pbenteryId { get; set; }
    }

    public class cancellationDetailsWrapper {
        @AuraEnabled public Decimal bookingAmount;
        @AuraEnabled public Decimal refundAmount;
        @AuraEnabled public Decimal deductedAmount;
        @AuraEnabled public String refundMethod;
        @AuraEnabled public Integer numberOfPaxCancelled;
        @AuraEnabled public String refundPolicyApplicable;
        @AuraEnabled public String paxNames;
    }
}