global class MDEN_SWIFT_API_Call {

    global static PayloadWrapper getOpportunity (String oppId,String actionType){
        
        List<Opportunity> oppList = [SELECT Id,Pricebook2.Name,Departure_Service_Time__c,Arrival_Service_Time__c,Flight_Number_Departure__c, Flight_Number_Arrival__c,Date_of_Departure__c,Date_of_Arrival__c, Name, Arriving_Flight_Schedule__r.Arrival_Terminal__r.Name,Arriving_Flight_Schedule__r.Departure_Terminal__r.Name  ,Departure_Airport_Id__r.Airport_Code__c,Service_Type__c, createddate, Jouney_Date__c, Sector__c,  Service_Airport__c, Service_Airport_Id__r.Airport_Code__c, Arriving_Airport__c, Arriving_Airport_Id__r.Airport_Code__c
                                              , Arrival_Airline__c, Departure_Airline__c , Number_of_Adults__c,Number_of_Children__c, Number_of_Infants__c,Payment_Ref_No__c,AccountId, Account.RecordType.Name ,Account.Name,Account.Phone,Account.PersonEmail,Account.PersonTitle,Account.LastName,Account.FirstName, Departure_Airport__c, Account.PersonHomePhone,
                                   (SELECT Id,Age__c,Travel_Class__c,Travel_PNR_No__c,Passport_No__c, Designation__c, First_Name__c, Last_Name__c,Name,Email_Id__c,Mobile__c, Country_code__c,Title__c FROM Passenger_Details__r), (SELECT ID, OpportunityId, Quantity, Name FROM OpportunityLineItems)  
                                     FROM Opportunity Where Id =: oppId];
        PayloadWrapper wrapper = new PayloadWrapper();
        Payload request = new Payload();
        List<SaleOrderGuestPayload> SaleOrderGuestPayloadList = new List<SaleOrderGuestPayload>();
        List<SaleOrderAvaanBookingPayload> SaleOrderAvaanBookingPayloadList = new List<SaleOrderAvaanBookingPayload>();
        if(!oppList.isEmpty()){
           for(Opportunity opp : oppList){
                 SaveSaleOrderPost saveSaleOrderPost = new SaveSaleOrderPost();
               saveSaleOrderPost.action_type =  actionType;//'Cancel';//'Partially Cancelled';//'Modified/Rescheduled';           
                saveSaleOrderPost.sfa_booking_id = opp.Id ;
               saveSaleOrderPost.sfa_booking_no = opp.Name ;// 'D24083477';//
                saveSaleOrderPost.itinerary_no = opp.Name ;//'V61477720';//opp. ;
                saveSaleOrderPost.service_type = opp.Service_Type__c ;//'Departure';//
                saveSaleOrderPost.booking_date = String.valueOf(opp.createddate) ;
               saveSaleOrderPost.service_date = opp.Date_of_Arrival__c != null ? opp.Date_of_Arrival__c : opp.Date_of_Departure__c;//'2025-03-31 11:45:00';
                saveSaleOrderPost.travel_date = String.valueOf(opp.Jouney_Date__c) ;
                 saveSaleOrderPost.travel_sector = opp.Sector__c ;
                saveSaleOrderPost.service_airport = opp.Service_Airport__c;//'Indira Gandhi International Airport'; //opp.Service_Airport__c;
                saveSaleOrderPost.service_airport_code = opp.Service_Airport_Id__r.Airport_Code__c ;// 'DEL';
                saveSaleOrderPost.from_airport = opp.Departure_Airport__c ;
               System.debug('----------------opp.Departure_Airport_Id__r.Airport_Code__c-------------->'+opp.Departure_Airport_Id__r.Airport_Code__c);
                saveSaleOrderPost.from_airport_code = opp.Departure_Airport_Id__r.Airport_Code__c ;//'DEL';//
                saveSaleOrderPost.to_airport = opp.Arriving_Airport__c ;
                saveSaleOrderPost.to_airport_code = opp.Arriving_Airport_Id__r.Airport_Code__c ;// 'BBI';
                 saveSaleOrderPost.arrival_airline = opp.Arrival_Airline__c ;
                saveSaleOrderPost.arrival_flight = opp.Flight_Number_Arrival__c ;
                saveSaleOrderPost.arrival_time = opp.Arrival_Service_Time__c ;
               saveSaleOrderPost.arrival_term = opp.Arriving_Flight_Schedule__r.Arrival_Terminal__r.Name ;
                saveSaleOrderPost.departure_airline = opp.Departure_Airline__c ;//'Air India';//
               saveSaleOrderPost.departure_flight = opp.Flight_Number_Departure__c;//'AI 473';//opp. ;
                saveSaleOrderPost.departure_time = opp.Departure_Service_Time__c ;// '07:00';//
                 saveSaleOrderPost.departure_term = opp.Arriving_Flight_Schedule__r.Departure_Terminal__r.Name ;//'T3';//opp. ;
                saveSaleOrderPost.no_of_adult = Integer.valueOf(opp.Number_of_Adults__c) ;
                saveSaleOrderPost.no_of_children = Integer.valueOf(opp.Number_of_Children__c) ;
                saveSaleOrderPost.no_of_infants = Integer.valueOf(opp.Number_of_Infants__c) ;
                saveSaleOrderPost.primary_product = opp.Pricebook2.Name;  // 'GOLD (DOM-DEP)';//opp. ;
               if( opp.Account.RecordType.Name == 'Person Account'){
                   saveSaleOrderPost.customer_sfa_id = '12';//String.valueOf(opp.Account.Id);//'12';//opp. ;
               saveSaleOrderPost.customer_name = opp.Account.Name;//'[40083761] Petronet LNG Limited'; // ;
                 saveSaleOrderPost.customer_mobile = opp.Account.Phone ;
                saveSaleOrderPost.customer_email = opp.Account.PersonEmail ;
                saveSaleOrderPost.customer_tag = opp.Account.PersonTitle ;//'VIP1';//
                   // Contact Info
                saveSaleOrderPost.booker_name =  opp.Account.LastName+' '+opp.Account.FirstName;//'HIMANSHU MEHTA';//opp. ;
                saveSaleOrderPost.booker_mobile =   opp.Account.PersonHomePhone ;//'+919811799331';// opp. ;
                saveSaleOrderPost.booker_email =   opp.Account.PersonEmail;//'himanshumehta@petronetlng.in';//opp. ;                   
               }
               
               if( opp.Account.RecordType.Name == 'Business Account'){
                 saveSaleOrderPost.salesperson_name = opp.Account.Name; //'Smita Rajput';//opp. ;
                 saveSaleOrderPost.salesperson_mobile = opp.Account.Phone ;// '+919811799331';//opp. ;
                saveSaleOrderPost.salesperson_email =  opp.Account.BusinessEmail__c;//'himanshumehta@petronetlng.in';//opp. ; 
               }
                
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
                for(Passenger_Details__c ps : opp.Passenger_Details__r){ 
                SaleOrderGuestPayload.guest_sfa_id = 12;//Integer.valueOf(ps.Id);//12;
                SaleOrderGuestPayload.guest_name = ps.Name ;//'Mr. Alice Smith';
                 SaleOrderGuestPayload.guest_age = Integer.valueOf(ps.Age__c);//33;
                 SaleOrderGuestPayload.travel_class =  ps.Travel_Class__c;//'Economy';
                 SaleOrderGuestPayload.pnr_no =   ps.Travel_PNR_No__c;//'PNR123';
                 SaleOrderGuestPayload.passport_no = ps.Passport_No__c;//'P12345';
                 SaleOrderGuestPayload.designation =  ps.Designation__c;//'Director';
                 SaleOrderGuestPayload.preferences = 'Want Manish to attend';
                 SaleOrderGuestPayload.country_code = ps.Country_code__c;//'+91';
                  SaleOrderGuestPayload.mobile = ps.Mobile__c;//'9876543210';
                SaleOrderGuestPayloadList.add(SaleOrderGuestPayload);
                }
                system.debug('SaleOrderGuestPayloadList=============>'+SaleOrderGuestPayloadList);
                request.sale_order_guest_payload = SaleOrderGuestPayloadList;
                
               /* for now  we are not sending avaan_booking */ 
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
                request.sfa_booking_id= opp.Id; //'12';
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