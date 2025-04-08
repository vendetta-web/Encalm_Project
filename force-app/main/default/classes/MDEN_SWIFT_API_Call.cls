global class MDEN_SWIFT_API_Call {

    global static void getOpportunity (String oppId){
        
        List<Opportunity> oppList = [SELECT Id, Service_Type__c, createddate, Jouney_Date__c, Sector__c,  Service_Airport__c, Service_Airport_Id__r.Airport_Code__c, Arriving_Airport__c, Arriving_Airport_Id__r.Airport_Code__c
                                              , Arrival_Airline__c, Departure_Airline__c , Number_of_Adults__c,Number_of_Children__c, Number_of_Infants__c,Payment_Ref_No__c,AccountId, 
                                     
                                     
                                   (SELECT Id, First_Name__c, Last_Name__c,Name,Email_Id__c,Mobile__c, Country_code__c FROM Passenger_Details__r)   
                                     FROM Opportunity Where Id =: oppId];
        Payload request = new Payload();
        if(!oppList.isEmpty()){
            
            for(Opportunity opp : oppList){
                //Payload.SaveSaleOrderPost saveSaleOrderPost  = new Payload.SaveSaleOrderPost();
                 SaveSaleOrderPost saveSaleOrderPost = new SaveSaleOrderPost();
                saveSaleOrderPost.sfa_booking_id = opp.Id ;
               // saveSaleOrderPost.sfa_booking_no = opp. ;
               // saveSaleOrderPost.itinerary_no = opp. ;
               // saveSaleOrderPost.service_type = opp. ;
                saveSaleOrderPost.booking_date = String.valueOf(opp.createddate) ;
              //  saveSaleOrderPost.service_date = opp. ;
                saveSaleOrderPost.travel_date = String.valueOf(opp.Jouney_Date__c) ;
                 saveSaleOrderPost.travel_sector = opp.Sector__c ;
                saveSaleOrderPost.service_airport = opp.Service_Airport__c;
                saveSaleOrderPost.service_airport_code = opp.Service_Airport_Id__r.Airport_Code__c ;
                saveSaleOrderPost.from_airport = opp.Departure_Airport__c ;
                saveSaleOrderPost.from_airport_code = opp.Departure_Airport_Id__r.Airport_Code__c ;
                saveSaleOrderPost.to_airport = opp.Arriving_Airport__c ;
                saveSaleOrderPost.to_airport_code = opp.Arriving_Airport_Id__r.Airport_Code__c ;
                /* saveSaleOrderPost.arrival_airline = opp.Arrival_Airline__c ;
                saveSaleOrderPost.arrival_flight = opp. ;
                saveSaleOrderPost.arrival_time = opp. ;
                saveSaleOrderPost.arrival_term = opp. ;
                saveSaleOrderPost.departure_airline = opp.Departure_Airline__c ;
                saveSaleOrderPost.departure_flight = opp. ;
                saveSaleOrderPost.departure_time = opp. ;
                 saveSaleOrderPost.departure_term = opp. ;
                saveSaleOrderPost.no_of_adult = opp.Number_of_Adults__c ;
                saveSaleOrderPost.no_of_children = opp.Number_of_Children__c ;
                saveSaleOrderPost.no_of_infants = opp.Number_of_Infants__c ;
                saveSaleOrderPost.primary_product = opp. ;
                saveSaleOrderPost.customer_sfa_id = opp. ;
                saveSaleOrderPost.customer_name = opp.AccountId.Name ;
                 saveSaleOrderPost.customer_mobile = opp.AccountId. ;
                saveSaleOrderPost.customer_email = opp.AccountId. ;
                saveSaleOrderPost.customer_tag = opp. ;
                saveSaleOrderPost.booker_name = opp. ;
                saveSaleOrderPost.booker_mobile = opp. ;
                saveSaleOrderPost.booker_email = opp. ;
                saveSaleOrderPost.salesperson_name = opp. ;
                 saveSaleOrderPost.salesperson_mobile = opp. ;
                saveSaleOrderPost.salesperson_email = opp. ;*/
                for(Passenger_Details__c ps : opp.Passenger_Details__r){ 
                  saveSaleOrderPost.placard_name = ps.Name ;
                saveSaleOrderPost.placard_title = ps.Title__c ;
                saveSaleOrderPost.placard_first_name = ps.First_Name__c ;
                saveSaleOrderPost.placard_last_name = ps.Last_Name__c ;
                saveSaleOrderPost.placard_country_code = ps.Country_code__c ;
                 saveSaleOrderPost.placard_mobile = ps.Mobile__c ;
                saveSaleOrderPost.placard_email = ps.Email_Id__c ;
                   }
               
                /*saveSaleOrderPost.instructions = opp. ;
                saveSaleOrderPost.payment_method = opp. ;
                saveSaleOrderPost.payment_ref_no = opp.Payment_Ref_No__c ;
                saveSaleOrderPost.API_KEY = opp. ;*/
              
            }
        }
        
    }    
    
    
    
    
    global class Payload {
        global SaveSaleOrderPost save_sale_order_post;
        global List<SaleOrderItemPayload> sale_order_item_payload;
        global List<SaleOrderGuestPayload> sale_order_guest_payload;
        global List<SaleOrderAvaanBookingPayload> sale_order_avaan_booking_payload;
    }

    global class SaveSaleOrderPost {
        global String sfa_booking_id;
        global String sfa_booking_no;
        global String itinerary_no;
        global String service_type;
        global String booking_date;
        global String service_date;
        global String travel_date;
        global String travel_sector;
        global String service_airport;
        global String service_airport_code;
        global String from_airport;
        global String from_airport_code;
        global String to_airport;
        global String to_airport_code;
        global String arrival_airline;
        global String arrival_flight;
        global String arrival_time;
        global String arrival_term;
        global String departure_airline;
        global String departure_flight;
        global String departure_time;
        global String departure_term;
        global Integer no_of_adult;
        global Integer no_of_children;
        global Integer no_of_infants;
        global String primary_product;
        global String customer_sfa_id;
        global String customer_name;
        global String customer_mobile;
        global String customer_email;
        global String customer_tag;
        global String booker_name;
        global String booker_mobile;
        global String booker_email;
        global String salesperson_name;
        global String salesperson_mobile;
        global String salesperson_email;
        global String placard_name;
        global String placard_title;
        global String placard_first_name;
        global String placard_last_name;
        global String placard_country_code;
        global String placard_mobile;
        global String placard_email;
        global String instructions;
        global String payment_method;
        global String payment_ref_no;
        global String API_KEY;
    }

    global class SaleOrderItemPayload {
        global Integer product_sfa_id;
        global String product_name;
        global Integer product_qty;
    }

    global class SaleOrderGuestPayload {
        global Integer guest_sfa_id;
        global String guest_name;
        global Integer guest_age;
        global String travel_class;
        global String pnr_no;
        global String passport_no;
        global String designation;
        global String preferences;
        global String country_code;
        global String mobile;
    }

    global class SaleOrderAvaanBookingPayload {
        global Integer avaan_sfa_id;
        global String avaan_booking_no;
        global String avaan_bags;
        global String avaan_weight;
        global String avaan_amount;
        global String avaan_booking_date;
    }
}