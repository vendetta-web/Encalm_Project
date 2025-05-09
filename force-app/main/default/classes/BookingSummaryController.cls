public with sharing class BookingSummaryController {
    
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

    public class FlightWrapper {
        @AuraEnabled
        public Decimal numberOfAdults;
        @AuraEnabled
        public Decimal numberOfChildren;
        @AuraEnabled
        public Decimal numberOfInfants;
        @AuraEnabled
        public String serviceAirport;
        @AuraEnabled
        public String flightNumber;
        @AuraEnabled
        public String flightDate;
        @AuraEnabled
        public String flightType;
    }

    public class PlacardWrapper {
        @AuraEnabled public String title;
        @AuraEnabled public String firstname;
        @AuraEnabled public String lastname;
        @AuraEnabled public String phone;
    }

    public class OrderSummaryWrapper {
        @AuraEnabled public String name;
        @AuraEnabled public Decimal count;
        @AuraEnabled public Decimal amount;
        @AuraEnabled public Decimal totalAmount;
        @AuraEnabled public Decimal netAmount;
        @AuraEnabled public Decimal cgstAmount;
        @AuraEnabled public Decimal sgstAmount;
        @AuraEnabled public Decimal igstAmount;
        @AuraEnabled public Decimal discount;
    }

    public class FullOpportunityData {
        @AuraEnabled public List<OrderSummaryWrapper> orderSummary;
        @AuraEnabled public List<PassengerWrapper> passengers;
        @AuraEnabled public PlacardWrapper placard;
        @AuraEnabled public FlightWrapper flightDetails;
    }

    @AuraEnabled(cacheable=true)
    public static FullOpportunityData getOpportunityData(Id opportunityId) {
        Map<String,Decimal> passengerTypeQtyMap = new Map<String,Decimal>();
        FullOpportunityData data = new FullOpportunityData();
        data.orderSummary = new List<OrderSummaryWrapper>(); // Initialize the list

        List<OpportunityLineItem> lineItems = [
            SELECT Id, Name, TotalPrice, Invoice_Amount__c, UnitPrice, Quantity, Discount, CGST__c, SGST__c, IGST__c, Discount_Amount__c,
                   Product2.Family, Product2.Package_Is_For__c, Product2.Name
            FROM OpportunityLineItem
            WHERE OpportunityId = :opportunityId
            AND (Status__c = 'Active' OR Status__c = 'Rescheduled')
            ORDER BY CreatedDate
        ];

        Map<String, OrderSummaryWrapper> summaryMap = new Map<String, OrderSummaryWrapper>();

        for (OpportunityLineItem oli : lineItems) {
            String packageName = oli.Product2.Name;
            String category = oli.Product2.Package_Is_For__c;
            String key;

            // **Check if it is an Add-On**
            if (oli.Product2.Family == 'Add Ons') {
                key = packageName + ' Qty';
            } else if (oli.Product2.Family == 'Surcharge') {
                key = packageName;
            } else {
                key = packageName + ' (' + category + ')'; // Group by category
            }

            if (!summaryMap.containsKey(key)) {
                OrderSummaryWrapper wrapper = new OrderSummaryWrapper();
                wrapper.name = key;
                wrapper.count = 0; // Store the total count of line items
                wrapper.amount = 0;
                wrapper.totalAmount = 0;
                wrapper.netAmount = 0;
                wrapper.cgstAmount = 0;
                wrapper.sgstAmount = 0;
                wrapper.igstAmount = 0;
                wrapper.discount = 0;
                summaryMap.put(key, wrapper);
            }

            // **Aggregate totals and count**
            OrderSummaryWrapper existingWrapper = summaryMap.get(key);
            existingWrapper.count += 1; // Since each line item has a quantity of 1, we count instances
            existingWrapper.amount += oli.TotalPrice;
            existingWrapper.totalAmount += oli.TotalPrice;
            existingWrapper.netAmount += oli.Invoice_Amount__c !=null ? oli.Invoice_Amount__c :0;
            existingWrapper.cgstAmount += oli.CGST__c !=null ? oli.CGST__c : 0;
            existingWrapper.sgstAmount += oli.SGST__c !=null ? oli.SGST__c : 0;
            existingWrapper.igstAmount += oli.IGST__c !=null ? oli.IGST__c : 0;
            existingWrapper.discount += (oli.Discount_Amount__c != null ? oli.Discount_Amount__c : 0);
        }

        // **Update the formatted name to reflect total count**
        for (String key : summaryMap.keySet()) {
            OrderSummaryWrapper wrapper = summaryMap.get(key);
            if (wrapper.name.contains('Adult') || wrapper.name.contains('Child') || wrapper.name.contains('Infant')) {
                wrapper.name = wrapper.name.replace('(', '(' + wrapper.count +  '');
            } else if (wrapper.name.contains('Qty')) {
                wrapper.name = wrapper.name.replace('Qty', wrapper.count + ' Qty');
            }
        }

        data.orderSummary = new List<OrderSummaryWrapper>(summaryMap.values()); // Assign the formatted list to the wrapper

        // 2. Load Passenger Details
        List<Passenger_Details__c> passengers = [
            SELECT Id, Title__c, First_Name__c, Last_Name__c, Gender__c, Age__c, Designation__c, 
                   Travel_Class__c, Travel_PNR_No__c, Nationalities__c, Passport_Govt_Id__c, Mobile__c, 
                   Passenger_Type__c, Individual_Booking_Details__c, Show_as_Placard__c, Unique_Id__c
            FROM Passenger_Details__c
            WHERE Opportunity_ID__c = :opportunityId
            AND (Individual_Booking_Details__r.Status__c ='Active' OR
            Individual_Booking_Details__r.Status__c ='Rescheduled' )
        ];

        data.passengers = new List<PassengerWrapper>();
        for (Passenger_Details__c p : passengers) {
            if(!passengerTypeQtyMap.containsKey(p.Passenger_Type__c)) {
                passengerTypeQtyMap.put(p.Passenger_Type__c, 0);
            }
            passengerTypeQtyMap.put(p.Passenger_Type__c, passengerTypeQtyMap.get(p.Passenger_Type__c) + 1);

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
            data.passengers.add(pw);
        }

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
        Flight_Type__c,
        StageName,
        Flight_Number_Departure__c,(SELECT Id FROM OpportunityLineItems)
        FROM Opportunity 
        WHERE Id = :opportunityId 
        LIMIT 1];
        FlightWrapper pasWrp = new FlightWrapper();
        pasWrp.flightType = opp.Flight_Type__c;
        pasWrp.numberOfAdults = passengerTypeQtyMap.containsKey('Adult') ? passengerTypeQtyMap.get('Adult') : 0;
        pasWrp.numberOfChildren = passengerTypeQtyMap.containsKey('Child') ? passengerTypeQtyMap.get('Child') : 0;
        pasWrp.numberOfInfants = passengerTypeQtyMap.containsKey('Infant') ? passengerTypeQtyMap.get('Infant') : 0;
        pasWrp.serviceAirport = opp.Service_Airport__c;
        pasWrp.flightNumber = opp.Service_Type__c =='Transit' ? opp.Flight_Number_Arrival__c + ' / '+ opp.Flight_Number_Departure__c : opp.Flight_Number_Arrival__c != null ? 
                        opp.Flight_Number_Arrival__c : 
                        opp.Flight_Number_Departure__c != null ?
                        opp.Flight_Number_Departure__c : '';                                
        pasWrp.flightDate = opp.Service_Type__c =='Transit' ?  opp.Date_of_Arrival__c + ' / '+ opp.Date_of_Departure__c : opp.Date_of_Arrival__c != null ? 
                        opp.Date_of_Arrival__c : 
                        opp.Date_of_Departure__c != null ?
                        opp.Date_of_Departure__c : '';
        data.flightDetails = pasWrp;

        //Show placard only if booking has an active passengers
        if (pasWrp.numberOfAdults >0 || pasWrp.numberOfChildren >0 || pasWrp.numberOfInfants>0) {            
            // Load Placard from Placard__c (separate object)
            List<Placard__c> placards = [
                SELECT Title__c, First_Name__c, Last_Name__c, Mobile_Number__c
                FROM Placard__c
                WHERE Opportunity_ID__c = :opportunityId
                LIMIT 1
            ];
            if (!placards.isEmpty()) {
                Placard__c placard = placards[0];
                PlacardWrapper pw = new PlacardWrapper();
                pw.title = placard.Title__c;
                pw.firstname = placard.First_Name__c;
                pw.lastname = placard.Last_Name__c;
                pw.phone = placard.Mobile_Number__c;
                data.placard = pw;
            }
        }

        return data;
    }
}