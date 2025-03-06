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
        system.debug('hoursDifference ->> '+hoursDifference);
        system.debug('packageName ->> '+packageName);
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
            system.debug('policy list-->> '+policy);
                if (policy.Less_Than__c &&  hoursDifference < Long.valueOf(policy.Time_Frame__c)) {
                    if (policy.Charges_in_Percentage__c) {
                        system.debug('policy ->> '+policy.Refund_Policy__c);
                        if (!checkUniqueRefundPolicy.contains(policy.Refund_Policy__c)) {
                            checkUniqueRefundPolicy.add(policy.Refund_Policy__c);
                            refundPolicy = refundPolicy + addAnd + policy.Refund_Policy__c;
                        }
                        return bookingAmount - (bookingAmount * (policy.Charges__c / 100));
                    } else {
                        system.debug('policy ->> '+policy.Refund_Policy__c);
                        if (!checkUniqueRefundPolicy.contains(policy.Refund_Policy__c)) {
                            checkUniqueRefundPolicy.add(policy.Refund_Policy__c);
                            refundPolicy = refundPolicy + addAnd + policy.Refund_Policy__c;
                        }
                        return bookingAmount - policy.Charges__c;
                    } 
                } 
                else if (policy.Greater_Than__c && Long.valueOf(policy.Time_Frame__c) < hoursDifference) {
                    if (policy.Charges_in_Percentage__c) {
                        system.debug('policy ->> '+policy.Refund_Policy__c);
                        if (!checkUniqueRefundPolicy.contains(policy.Refund_Policy__c)) {
                            checkUniqueRefundPolicy.add(policy.Refund_Policy__c);
                            refundPolicy = refundPolicy + addAnd + policy.Refund_Policy__c;
                        }
                        return bookingAmount - (bookingAmount * (policy.Charges__c / 100));
                    } else {
                        system.debug('policy ->> '+policy.Refund_Policy__c);
                        if (!checkUniqueRefundPolicy.contains(policy.Refund_Policy__c)) {
                            checkUniqueRefundPolicy.add(policy.Refund_Policy__c);
                            refundPolicy = refundPolicy + addAnd + policy.Refund_Policy__c;
                        }
                        return bookingAmount - policy.Charges__c;
                    } 
                }
                else if (policy.Time_Frame__c.contains('-')) {
                    List<String> rangeValues = policy.Time_Frame__c.split('-');
                    system.debug('rangeValues '+rangeValues);
                    Integer lowerValue = Integer.valueOf(rangeValues[0]); // First value (24)
                    Integer upperValue = Integer.valueOf(rangeValues[1]); // Second value (48)
                    system.debug('lowerValue '+lowerValue);
                    system.debug('upperValue '+upperValue);
                    if (hoursDifference > lowerValue && hoursDifference < upperValue) {
                        if (policy.Charges_in_Percentage__c) {
                            system.debug('policy ->> '+policy.Refund_Policy__c);
                            if (!checkUniqueRefundPolicy.contains(policy.Refund_Policy__c)) {
                                checkUniqueRefundPolicy.add(policy.Refund_Policy__c);
                                refundPolicy = refundPolicy + addAnd + policy.Refund_Policy__c;
                            }
                            return bookingAmount - (bookingAmount * (policy.Charges__c / 100));
                        } else {
                            system.debug('policy ->> '+policy.Refund_Policy__c);
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
                        system.debug('policy ->> '+policy.Refund_Policy__c);
                        if (!checkUniqueRefundPolicy.contains(policy.Refund_Policy__c)) {
                            checkUniqueRefundPolicy.add(policy.Refund_Policy__c);
                            refundPolicy = refundPolicy + addAnd + policy.Refund_Policy__c;
                        }
                        bookingAmount = bookingAmount - (bookingAmount * (policy.Charges__c / 100));
                    } else {
                        system.debug('policy ->> '+policy.Refund_Policy__c);
                        if (!checkUniqueRefundPolicy.contains(policy.Refund_Policy__c)) {
                            checkUniqueRefundPolicy.add(policy.Refund_Policy__c);
                            refundPolicy = refundPolicy + addAnd + policy.Refund_Policy__c;
                        }
                        bookingAmount = bookingAmount - policy.Charges__c;
                    } 
                }
            
        }
        // Default to no charge if no policy matches
        system.debug('policy ->> no policy ');
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
        List<OpportunityLineItem> oliNewList = new List<OpportunityLineItem>();
        cancellationDetailsWrapper wrp = new cancellationDetailsWrapper();
        DateTime serviceDateTime;
        String dateText;
        String timeText;
        String combinedDateTimeStr;
        // Query OpportunityLineItems based on OpportunityId
        Opportunity opp = [
            SELECT STA_Time__c,STD_Time__c,Date_of_Arrival__c,Date_of_Departure__c,Amount,
            (SELECT Id,Product2.Family,UnitPrice,PricebookEntryId FROM opportunitylineitems WHERE Status__c = 'Active') 
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
        } else if (opp.STD_Time__c != null) {
            dateText=opp.Date_of_Departure__c;
            timeText=opp.STD_Time__c;// Ensure timeText includes seconds
            if (timeText.length() == 5) {  // "HH:mm" format
                timeText += ':00';  // Append ":00" for seconds
            }
            combinedDateTimeStr=dateText + ' ' + timeText;
            serviceDateTime = DateTime.valueOf(combinedDateTimeStr);
        }

        //both scenarios of preview of cancellation and creating cancellation records for full cancellation
        if (cancelType =='fullCancel') {    
            numberOfPax = opp.opportunitylineitems.size();    
            bookingAmount = 0;  
            Decimal refundAmount = 0;   
            for (opportunitylineitem oli: opp.opportunitylineitems) {
                packageName = oli.Product2.Family;
                bookingAmount += oli.UnitPrice; 
                decimal refundAmountPerOli = getCancellationPolicyAmount(serviceDateTime, DateTime.now(), oli.UnitPrice, packageName); 
                refundAmount += refundAmountPerOli;
                // to create final cancellation records
                if(submit) {
                    oli.Status__c = 'Fully Cancelled';
                    oliList.add(oli);
                OpportunityLineItem oliNew = new OpportunityLineItem();
                oliNew.Status__c = 'Cancellation';
                oliNew.OpportunityId = opportunityId;
                oliNew.UnitPrice = refundAmountPerOli;
                oliNew.Refund_Amount__c = refundAmountPerOli;
                oliNew.Quantity = 1;
                oliNew.Amount_Deducted__c= oli.UnitPrice-refundAmountPerOli;
                oliNew.PricebookEntryId=oli.PricebookEntryId;
                oliNewList.add(oliNew); 
                }          
            }
            update oliList;            
            insert oliNewList;    
            
            //to show preview of full cancellation
            decimal afterGeneralCancellationRefund =  getGeneralCancellationPolicyAmount(serviceDateTime, DateTime.now(), refundAmount);
            wrp.bookingAmount = bookingAmount;
            wrp.refundAmount = afterGeneralCancellationRefund;
            wrp.deductedAmount = bookingAmount - afterGeneralCancellationRefund;
            wrp.refundMethod = 'Original Payment Mode';
            wrp.numberOfPaxCancelled = numberOfPax;
            wrp.refundPolicyApplicable = refundPolicy != '' ? refundPolicy : 'N/A';
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
            Decimal refundAmountWithoutGeneralCharges = 0;  
            Decimal generalDeduction = 0;
            Integer count = 0;    
            for (Map<String, Object> row : selectedOrders) {    
                system.debug('size->> '+selectedOrders.size());    
                String pckName = (String) row.get('packageName');
                Decimal perUnitPrice = (Decimal) row.get('unitPrice');
                if((Id) row.get('oliId') !=null) {
                    OpportunityLineItem oli = new OpportunityLineItem(); 
                    oli.Id = (Id) row.get('oliId');
                    oli.Status__c = 'Partially Cancelled';
                    oliList.add(oli);
                }                
                OpportunityLineItem oliNew = new OpportunityLineItem();
                decimal refundAmountPerOli = getCancellationPolicyAmount(serviceDateTime, DateTime.now(), perUnitPrice, pckName);
                refundAmountWithoutGeneralCharges += refundAmountPerOli;
                generalDeduction = refundAmountWithoutGeneralCharges;
                if (count == 0) {
                    generalDeduction =  getGeneralCancellationPolicyAmount(serviceDateTime, DateTime.now(), refundAmountWithoutGeneralCharges);
                }
                
                oliNew.Status__c = 'Cancellation';
                oliNew.OpportunityId = opportunityId;
                oliNew.UnitPrice = perUnitPrice;
                oliNew.Refund_Amount__c = refundAmountPerOli;
                oliNew.Quantity = 1;
                oliNew.Amount_Deducted__c= perUnitPrice -  refundAmountPerOli;
                oliNew.PricebookEntryId=(Id) row.get('pbenteryId');
                oliNewList.add(oliNew);    
                
                //to show preview of full cancellation
                wrp.bookingAmount = wrp.bookingAmount != null ? wrp.bookingAmount : 0;
                wrp.refundAmount = wrp.refundAmount != null ? wrp.refundAmount : 0;
                wrp.bookingAmount += perUnitPrice; 
                wrp.refundAmount = generalDeduction;
                wrp.deductedAmount = wrp.bookingAmount - wrp.refundAmount;
                wrp.refundMethod = 'Original Payment Mode';
                wrp.numberOfPaxCancelled = numberOfPax;
                wrp.refundPolicyApplicable = refundPolicy != '' ? refundPolicy : 'N/A';

                count++;
            }
            if (submit) {
                update oliList;            
                insert oliNewList;
            }
        }
        if(numberOfPax == 0) {
            return null;
        }
        return wrp;
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
            WHERE Opportunity_ID__c=:opportunityId AND Individual_Booking_Details__r.Status__c = 'Active'
        ];

        // Populate wrapper class list
        for (Passenger_Details__c pd : passengerList) {
            if(pd.Individual_Booking_Details__r.Status__c == 'Active'){  
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
    }
}