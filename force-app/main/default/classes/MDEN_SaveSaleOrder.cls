/* Created by 	: Maxify Development Team
 * Created Date : 14th Jan, 2025
 * Input 		: None
 * Purpose 		: This API class returns all the salutations
 */
@RestResource(urlMapping='/save_sale_order/*')    
global class MDEN_SaveSaleOrder {
    @HttpPost
    global static ReturnResponseWrapper saveSaleOrder() {
        RestRequest request = RestContext.request;
        System.debug('========request.requestBody.toString()====' + request.requestBody.toString());

        JSONWrapper customerPostPayload = (JSONWrapper)JSON.deserialize(request.requestBody.toString(), JSONWrapper.class);
        System.debug('======customerPostPayload===' + customerPostPayload);
         String bookingId;
         ReturnResponseWrapper response = new ReturnResponseWrapper('');
        // Validate and insert Account
        if (customerPostPayload.customer_post_payload != null) {
            Account acc = new Account(
                PersonTitle = customerPostPayload.customer_post_payload.title,
                FirstName = customerPostPayload.customer_post_payload.first_name,
                LastName = customerPostPayload.customer_post_payload.last_name,
                PersonEmail = customerPostPayload.customer_post_payload.email,
                PersonMobilePhone = customerPostPayload.customer_post_payload.mobile,
                PersonGenderIdentity = customerPostPayload.customer_post_payload.gender,
               //PersonBirthdate = customerPostPayload.customer_post_payload.dob,
                BillingCity = customerPostPayload.customer_post_payload.city,
                BillingCountry = customerPostPayload.customer_post_payload.country_id,
                Pin_Code__c = customerPostPayload.customer_post_payload.pincode
            );
            insert acc;
            System.debug('Inserted Account: ' + acc.Id);
        }

        // Validate and insert Airport record (assuming Airport__c is a custom object)
        if (customerPostPayload.save_sale_order_post != null) {
            Opportunity booking = new Opportunity(
                Name = 'ADL',
                StageName = 'Qualification',
                closeDate = date.today(),
                Service_Type__c = customerPostPayload.save_sale_order_post.service_type,
                Commitment_Date__c	= Date.valueOf(customerPostPayload.save_sale_order_post.commitment_date),
                Jouney_Date__c = Date.valueOf(customerPostPayload.save_sale_order_post.travel_date),
                Departure_Airport__c = customerPostPayload.save_sale_order_post.from_airport,
                Arriving_Airport__c = customerPostPayload.save_sale_order_post.to_airport,
                Arrival_Airline__c = customerPostPayload.save_sale_order_post.arrival_airline,
                Flight_Number_Arrival__c = customerPostPayload.save_sale_order_post.arrival_flight,
                Departure_Airline__c = customerPostPayload.save_sale_order_post.departure_airline,
                Flight_Number_Departure__c = customerPostPayload.save_sale_order_post.departure_flight,
               Sector__c = customerPostPayload.save_sale_order_post.traver_sector ,
               Arrival_Service_Time__c = customerPostPayload.save_sale_order_post.arrival_time ,
               Departure_Service_Time__c = customerPostPayload.save_sale_order_post.departure_time,
              Arrival_Terminal__c = customerPostPayload.save_sale_order_post.arrival_term,
              Departure_Terminal__c  = customerPostPayload.save_sale_order_post.departure_term,
               Number_of_Adults__c = customerPostPayload.save_sale_order_post.no_of_adult,
                Number_of_Children__c= customerPostPayload.save_sale_order_post.no_of_children,
               Number_of_Infants__c = customerPostPayload.save_sale_order_post.no_of_infants,
               Payment_Ref_No__c = customerPostPayload.save_sale_order_post.payment_ref_no
          
         );
            insert booking;
            bookingId = booking.Id;
            if(booking != null){
                Passenger_Details__c  passengerDetails = new Passenger_Details__c(
                    Title__c = customerPostPayload.save_sale_order_post.placard_title,
                    First_Name__c  = customerPostPayload.save_sale_order_post.placard_first_name,
                    Last_Name__c  = customerPostPayload.save_sale_order_post.placard_last_name,
                    Country_code__c = customerPostPayload.save_sale_order_post.placard_country_code,
                    Mobile__c   = customerPostPayload.save_sale_order_post.placard_mobile
                );
           
                if(passengerDetails != null ){
                    insert passengerDetails;
                }
            }
            System.debug('Inserted Airport: ' + booking.Id);
        }

        // Validate and insert Product records
       if (customerPostPayload.sale_order_item_payload != null && !customerPostPayload.sale_order_item_payload.isEmpty()) {
            List<OpportunityLineItem> productList = new List<OpportunityLineItem>();
            for (ItemPayload item : customerPostPayload.sale_order_item_payload) {
                OpportunityLineItem product = new OpportunityLineItem(
                   // ProductCode = item.product_id,//field not writeable
                    // Name = item.name,//field not writeable
                    OpportunityId = bookingId,
                    Product2Id = '01tH30000010y6lIAA',
                    PricebookEntryId  = '01uH3000000tc0dIAA',
                    Quantity = item.product_uom_qty,
                    UnitPrice = item.price_unit
                   // Subtotal = item.price_subtotal field not writeable
                );
                productList.add(product);
            }
            if (!productList.isEmpty()) {
                insert productList;
                System.debug('Inserted Products: ' + productList);
            }
           
           
        }
        if (customerPostPayload.sale_order_guest_payload != null && !customerPostPayload.sale_order_guest_payload.isEmpty()) {
            List<Passenger_Details__c> passengerDetailsList = new List<Passenger_Details__c>();
            for (GuestPayload guestPayload : customerPostPayload.sale_order_guest_payload) {
            
              Passenger_Details__c  passengerDetails = new Passenger_Details__c(
                  Opportunity_ID__c = bookingId,
                  Title__c = guestPayload.title,
                  First_Name__c  = guestPayload.first_name,
                  Last_Name__c  = guestPayload.last_name,
                  Country_code__c = guestPayload.country_code,
                  Mobile__c   = guestPayload.mobile,
                  Travel_Class__c = guestPayload.class_type,
                  Passport_No__c = guestPayload.passport_no,
                  Travel_PNR_No__c   = guestPayload.pnr_no,
                  Gender__c  = guestPayload.gender,
                  Age__c  = guestPayload.age
                 );
                passengerDetailsList.add(passengerDetails);
            }
            if(!passengerDetailsList.IsEmpty()){
                  insert passengerDetailsList ;
            }
         // GetResponseWrapper response = new GetResponseWrapper('');
        }
        return response    = new ReturnResponseWrapper(bookingId);
    }

    global class JSONWrapper {
        global CustomerPostPayload customer_post_payload;
        global SaveSaleOrderPost save_sale_order_post;
        global List<ItemPayload> sale_order_item_payload;
        global List<GuestPayload> sale_order_guest_payload;
    }

    global class CustomerPostPayload {
        global String partner_id;
        global String title;
        global String first_name;
        global String last_name;
        global String email;
        global String country_code;
        global String mobile;
        global String gender;
        global String dob ;
        global String address;
        global String city;
        global String state;
        global String country_id;
        global String pincode;
        global String tnc;
        global String mkt_comm;
    }

    global class SaveSaleOrderPost {
        global String service_type;
        global String commitment_date;
        global String travel_date;
        global String traver_sector;
        global String service_airport;
        global String from_airport;
        global String to_airport;
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
        global Integer primary_product_id;
        global String placard_title;
        global String placard_first_name;
        global String placard_last_name;
        global String placard_country_code;
        global String placard_mobile;
        global String payment_ref_no;
    }

    global class ItemPayload {
        global Integer product_id;
        global String name;
        global Integer product_uom_qty;
        global Decimal price_unit;
        global Decimal price_subtotal;
    }

    global class GuestPayload {
        global String title;
        global String first_name;
        global String last_name;
        global String gender;
        global Integer age;
        global String passport_no;
        global String pnr_no;
        global String class_type;
        global String mobile;
        global String country_code;
        global Integer parent_id;
    }
      global class ReturnResponseWrapper {
        global String Id; 
       global ReturnResponseWrapper(String Id) {
            this.Id = Id;
            
        }        
    }
}