global class MDEN_SWIFT_API_Call {

    global static PayloadWrapper getOpportunity (String oppId){
        
        List<Opportunity> oppList = [SELECT Id,Departure_Airport_Id__r.Airport_Code__c,Service_Type__c, createddate, Jouney_Date__c, Sector__c,  Service_Airport__c, Service_Airport_Id__r.Airport_Code__c, Arriving_Airport__c, Arriving_Airport_Id__r.Airport_Code__c
                                              , Arrival_Airline__c, Departure_Airline__c , Number_of_Adults__c,Number_of_Children__c, Number_of_Infants__c,Payment_Ref_No__c,AccountId,Departure_Airport__c, 
                                     
                                     
                                   (SELECT Id, First_Name__c, Last_Name__c,Name,Email_Id__c,Mobile__c, Country_code__c,Title__c FROM Passenger_Details__r), (SELECT ID, OpportunityId, Quantity, Name FROM OpportunityLineItems)  
                                     FROM Opportunity Where Id =: oppId];
        PayloadWrapper wrapper = new PayloadWrapper();
        Payload request = new Payload();
        List<SaleOrderGuestPayload> SaleOrderGuestPayloadList = new List<SaleOrderGuestPayload>();
        List<SaleOrderAvaanBookingPayload> SaleOrderAvaanBookingPayloadList = new List<SaleOrderAvaanBookingPayload>();
        if(!oppList.isEmpty()){
            
            for(Opportunity opp : oppList){
                //Payload.SaveSaleOrderPost saveSaleOrderPost  = new Payload.SaveSaleOrderPost();
                 SaveSaleOrderPost saveSaleOrderPost = new SaveSaleOrderPost();
               // saveSaleOrderPost.action_type =  'Cancel';//'Partially Cancelled';//'Modified/Rescheduled';
                 //saveSaleOrderPost.action_type =  'Partially Cancelled';
                saveSaleOrderPost.action_type =  'Modified/Rescheduled';
                saveSaleOrderPost.sfa_booking_id = opp.Id ;
               saveSaleOrderPost.sfa_booking_no = 'D24083477';//opp. ;
                saveSaleOrderPost.itinerary_no = 'V61477720';//opp. ;
                saveSaleOrderPost.service_type = 'Departure';//opp. ;
                saveSaleOrderPost.booking_date = String.valueOf(opp.createddate) ;
                saveSaleOrderPost.service_date = '2025-03-31 11:45:00';//opp. ;
                saveSaleOrderPost.travel_date = String.valueOf(opp.Jouney_Date__c) ;
                 saveSaleOrderPost.travel_sector = opp.Sector__c ;
                saveSaleOrderPost.service_airport = 'Indira Gandhi International Airport'; //opp.Service_Airport__c;
                saveSaleOrderPost.service_airport_code = 'DEL';///opp.Service_Airport_Id__r.Airport_Code__c ;
                saveSaleOrderPost.from_airport = opp.Departure_Airport__c ;
                saveSaleOrderPost.from_airport_code = 'DEL';//opp.Departure_Airport_Id__r.Airport_Code__c ;
                saveSaleOrderPost.to_airport = opp.Arriving_Airport__c ;
                saveSaleOrderPost.to_airport_code = 'BBI';//opp.Arriving_Airport_Id__r.Airport_Code__c ;
                 saveSaleOrderPost.arrival_airline = opp.Arrival_Airline__c ;
               // saveSaleOrderPost.arrival_flight = opp. ;
                //saveSaleOrderPost.arrival_time = opp. ;
               // saveSaleOrderPost.arrival_term = opp. ;
                saveSaleOrderPost.departure_airline = 'Air India';//opp.Departure_Airline__c ;
               saveSaleOrderPost.departure_flight = 'AI 473';//opp. ;
                saveSaleOrderPost.departure_time = '07:00';//opp. ;
                 saveSaleOrderPost.departure_term = 'T3';//opp. ;
                saveSaleOrderPost.no_of_adult = Integer.valueOf(opp.Number_of_Adults__c) ;
                saveSaleOrderPost.no_of_children = Integer.valueOf(opp.Number_of_Children__c) ;
                saveSaleOrderPost.no_of_infants = Integer.valueOf(opp.Number_of_Infants__c) ;
                saveSaleOrderPost.primary_product = 'GOLD (DOM-DEP)';//opp. ;
                saveSaleOrderPost.customer_sfa_id = '12';//opp. ;
               saveSaleOrderPost.customer_name = '[40083761] Petronet LNG Limited'; //opp.AccountId.Name ;
                 saveSaleOrderPost.customer_mobile = opp.AccountId ;
                saveSaleOrderPost.customer_email = opp.AccountId ;
                saveSaleOrderPost.customer_tag = 'VIP1';//opp. ;
                saveSaleOrderPost.booker_name = 'HIMANSHU MEHTA';//opp. ;
                saveSaleOrderPost.booker_mobile = '+919811799331';// opp. ;
                saveSaleOrderPost.booker_email = 'himanshumehta@petronetlng.in';//opp. ;
                saveSaleOrderPost.salesperson_name = 'Smita Rajput';//opp. ;
                 saveSaleOrderPost.salesperson_mobile = '+919811799331';//opp. ;
                saveSaleOrderPost.salesperson_email = 'himanshumehta@petronetlng.in';//opp. ;
                for(Passenger_Details__c ps : opp.Passenger_Details__r){ 
                  saveSaleOrderPost.placard_name = ps.Name ;
                saveSaleOrderPost.placard_title = ps.Title__c ;
                saveSaleOrderPost.placard_first_name = ps.First_Name__c ;
                saveSaleOrderPost.placard_last_name = ps.Last_Name__c ;
                saveSaleOrderPost.placard_country_code = ps.Country_code__c ;
                 saveSaleOrderPost.placard_mobile = ps.Mobile__c ;
                saveSaleOrderPost.placard_email = ps.Email_Id__c ;
                   }
                List<saleorderitempayload> saleorderitempayloadList = new  List<saleorderitempayload>();
                for(OpportunityLineItem OlItem : opp.OpportunityLineItems){
                    SaleOrderItemPayload saleorderitempayload = new SaleOrderItemPayload();
                    //SaleOrderItemPayload saleorderitempayload = SaleOrderItemPayload();
                      saleorderitempayload.product_name =  OlItem.Name;
               saleorderitempayload.product_qty=      Integer.valueOf(OlItem.Quantity);
                   saleorderitempayload.product_sfa_id = 10617;//Integer.valueOf(OlItem.Id);
                    saleorderitempayloadList.add(saleorderitempayload);
                    
                }
                //saveSaleOrderPost.instructions = opp. ;
                saveSaleOrderPost.payment_method = 'Cash on account';//opp. ;
                saveSaleOrderPost.payment_ref_no = opp.Payment_Ref_No__c ;
                saveSaleOrderPost.API_KEY = 'sfa879z16Ff7XIEtyu67Sii'; //opp. ;
                //
                //saveSaleOrderPost.sale_order_item_payload  = saleorderitempayloadList;
                request.save_sale_order_post = saveSaleOrderPost;
                request.sale_order_item_payload = saleorderitempayloadList;
               SaleOrderGuestPayload SaleOrderGuestPayload = new SaleOrderGuestPayload();
                SaleOrderGuestPayload.guest_sfa_id = 12;
                SaleOrderGuestPayload.guest_name = 'Mr. Alice Smith';
                 SaleOrderGuestPayload.guest_age = 33;
                 SaleOrderGuestPayload.travel_class = 'Economy';
                 SaleOrderGuestPayload.pnr_no = 'PNR123';
                 SaleOrderGuestPayload.passport_no = 'P12345';
                 SaleOrderGuestPayload.designation = 'Director';
                 SaleOrderGuestPayload.preferences = 'Want Manish to attend';
                 SaleOrderGuestPayload.country_code = '+91';
                  SaleOrderGuestPayload.mobile = '9876543210';
                SaleOrderGuestPayloadList.add(SaleOrderGuestPayload);
                system.debug('SaleOrderGuestPayloadList=============>'+SaleOrderGuestPayloadList);
                request.sale_order_guest_payload = SaleOrderGuestPayloadList;
                
                
                SaleOrderAvaanBookingPayload SaleOrderAvaanBookingPayloadRec = new SaleOrderAvaanBookingPayload();
                SaleOrderAvaanBookingPayloadRec.avaan_sfa_id = 1012;
                 SaleOrderAvaanBookingPayloadRec.avaan_booking_no = 'AVB00987';
                 SaleOrderAvaanBookingPayloadRec.avaan_bags = '1';
                 SaleOrderAvaanBookingPayloadRec.avaan_weight = '30 Kg';
                 SaleOrderAvaanBookingPayloadRec.avaan_amount = '3000';
                SaleOrderAvaanBookingPayloadRec.avaan_booking_date = '2025-03-31 11:45'; 
                SaleOrderAvaanBookingPayloadList.add(SaleOrderAvaanBookingPayloadRec);
                request.sale_order_avaan_booking_payload = SaleOrderAvaanBookingPayloadList;
                wrapper.payload  = request ;
                request.sfa_booking_id='12';
                 request.API_KEY = 'sfa879z16Ff7XIEtyu67Sii';
 
                String requestBody = JSON.serialize(wrapper);
                System.debug('requestBody===========>'+requestBody);
                return wrapper;
              
            }
        }
        return null;
        
    }    
    
    global class PayloadWrapper {
    global Payload payload;
   
}
    
    
    global class Payload {
         global String API_KEY ;
    global String sfa_booking_id;
        global SaveSaleOrderPost save_sale_order_post;
        global List<SaleOrderItemPayload> sale_order_item_payload;
        global List<SaleOrderGuestPayload> sale_order_guest_payload;
        global List<SaleOrderAvaanBookingPayload> sale_order_avaan_booking_payload;
    }

    global class SaveSaleOrderPost {
        global String action_type;
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