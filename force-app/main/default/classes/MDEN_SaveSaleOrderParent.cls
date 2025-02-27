/* Created by 	: Maxify Development Team
 * Created Date : 14th Jan, 2025
 * Input 		: None
 * Purpose 		: This API class returns all the salutations
 */
@RestResource(urlMapping='/save_sale_order_parent/*')	
global class MDEN_SaveSaleOrderParent {
    @HttpPost
    global static MDEN_GetResponseWrapper saveSaleOrderParent(){
        //Initialize the response wrapper with blank status and blank message
        MDEN_GetResponseWrapper mden_responseWrapper = new MDEN_GetResponseWrapper('', '');
        try{
            Map<String, String> flightTypeMap = new Map<String, String>{
                 '1' => 'Arrival', 
                 '2' => 'Departure',
                 '3' => 'Transit'
            };
                
            //MDEN_RegisterCustomer.registerCustomer();
            //Uncomment below code to test in Postman
            RestRequest request = RestContext.request;
            Order requestMap = (Order) JSON.deserialize(request.requestBody.toString(), Order.class);
                      
            
			//Uncomment below to call via Developer console using : MDEN_GetAirportTerminalByAirport.getAiportTerminals();
            /*String reqBody =' { ' +
                ' "partner_id" : "100", '+
                ' "date_order" : "2022-07-05 13:26:22", '+
                ' "airport_location_id" : "000002", '+
                ' "travel_date" : "2025-01-31", '+
                ' "commitment_date" : "2022-07-07 14:45", '+   // not need to map now
                ' "airport_terminal_id" : "T1", '+
                ' "departure_flight_id" : "0", '+
                ' "arrival_flight_id" : "871", '+
                ' "arrival_airline_id" : "001", '+  // us in SOQL
                ' "departure_airline_id" : "0", '+
                ' "service_category" : "welcome_and_assist", '+
                ' "service_type_id" : "1", '+
                ' "arrival_time" : "1445", '+
                ' "departure_time" : null, '+
                ' "booking_made_from" : "b2c", '+
                ' "from_airport_id" : "7853", '+
                ' "to_airport_id" : "8008", '+
                ' "no_of_adult" : "1", '+
                ' "no_of_children" : "0", '+
                ' "no_of_infats" : "0", '+
                ' "terminal_id" : null, '+
                ' "length_stay" : null, '+
                ' "pricelist_id" : "1", '+
                ' "arrival_term" : "T1", '+
                ' "departure_term" : null, '+
                ' "primary_product_id" : "23" '+
                ' } ';
         
            Order requestMap = (Order) JSON.deserialize(reqBody, Order.class);*/
            
                
            system.debug('Order=partner_id=>'+requestMap.partner_id);
            
            if(requestMap != null )
            {
                mden_responseWrapper = new MDEN_GetResponseWrapper('true', 'data added.');
                List<Flight_Schedule__c> flightSchedule = new List<Flight_Schedule__c>();
                List<Terminal__c> terminalList = [select id, name, Code__c from Terminal__c where name = :requestMap.airport_terminal_id];
                
                Opportunity oppRec = new Opportunity();
                
                if( requestMap.arrival_flight_id != null){
                        flightSchedule = [SELECT Id,Departure_Terminal__r.Airport__c, Flight_Date__c,Arrival_Terminal__r.Airport__r.Id,Arrival_Terminal__r.Airport__r.Location_Id__r.Name, Arrival_Terminal__r.Name, Flight_Detail__r.Airline_Id__r.Name 
                                          FROM Flight_Schedule__c 
                                      WHERE Flight_Date__c =: requestMap.travel_date AND 
                                      		Arrival_Terminal__r.Airport__r.Location_Id__r.Name =:requestMap.airport_location_id AND 
                                      		Flight_Detail__r.Airline_Id__r.Name =:requestMap.arrival_airline_id AND  
                                      		Flight_Detail__r.Flight_No_Arrival__c =: requestMap.arrival_flight_id  /*Arrival_Terminal__r.Name*/];
                    
                }
                if(requestMap.departure_flight_id != null){
                    flightSchedule = [SELECT Id,Departure_Terminal__r.Airport__c, Flight_Date__c,Arrival_Terminal__r.Airport__c, Arrival_Terminal__r.Airport__r.Location_Id__r.Name, Arrival_Terminal__r.Name, Flight_Detail__r.Airline_Id__r.Name 
                                      FROM Flight_Schedule__c 
                                      WHERE Flight_Date__c =: requestMap.travel_date AND 
                                      		Departure_Terminal__r.Airport__r.Location_Id__r.Name =:requestMap.airport_location_id AND 
                                      		Flight_Detail__r.Airline_Id__r.Name =:requestMap.arrival_airline_id AND 
                                      		Flight_Detail__r.Flight_No_Departure__c  =: requestMap.departure_flight_id /*Arrival_Terminal__r.Name*/];
                    
                }
                //flightSchedule = [SELECT Id, Flight_Date__c,Arrival_Terminal__r.Airport__r.Location_Id__r.Name, Arrival_Terminal__r.Name, Flight_Detail__r.Airline_Id__r.Name FROM Flight_Schedule__c WHERE Flight_Date__c =: requestMap.travel_date AND Arrival_Terminal__r.Airport__r.Location_Id__r.Name =:requestMap.airport_location_id AND  Flight_Detail__r.Airline_Id__r.Name =:requestMap.arrival_airline_id /*Arrival_Terminal__r.Name*/];
                
                system.debug('flightSchedule==>'+flightSchedule);
               // List<Flight_Detail__c> flightDetail = [SELECT Id, Flight_No_Arrival__c FROM Flight_Detail__c WHERE Flight_No_Arrival__c =: requestMap.arrival_flight_id AND Flight_No_Departure__c	=:requestMap.departure_flight_id ];
                oppRec.Number_of_Adults__c = requestMap.no_of_adult ;
                oppRec.Number_of_Children__c  = requestMap.no_of_children ;
                oppRec.Number_of_Infants__c  = requestMap.no_of_infants;   
                oppRec.STD_Time__c  = requestMap.arrival_time;
                oppRec.STA_Time__c = requestMap.departure_time;                
                if(flightTypeMap.containsKey(requestMap.service_type_id)){
                    oppRec.Service_Type__c  = flightTypeMap.get(requestMap.service_type_id);
                }
                System.debug('requestMap.source;==============>'+requestMap.source);
                oppRec.Service_Duration__c = requestMap.length_stay;
                oppRec.Booking_Origin__c = requestMap.booking_made_from;
                oppRec.CloseDate = date.today();
                oppRec.StageName = 'Value Proposition';
                oppRec.Name = 'Test';
                oppRec.Source__c = requestMap.source;
                oppRec.Service_Category__c = 'Welcome And Assist';
                if(flightSchedule <> null  && !flightSchedule.isEmpty()){
                   oppRec.Flight_Number_Arrival__c = flightSchedule[0].Flight_Detail__r.Flight_No_Arrival__c ;
                   oppRec.Flight_Number_Departure__c = flightSchedule[0].Flight_Detail__r.Flight_No_Departure__c;
                   oppRec.Date_of_Arrival__c = (requestMap.arrival_flight_id != null) ? String.valueOf(flightSchedule[0].Flight_Date__c) : null; 
                   oppRec.Date_of_Departure__c = (requestMap.departure_flight_id != null) ? String.valueOf(flightSchedule[0].Flight_Date__c) : null; 
                   oppRec.Service_Airport__c = String.valueOf(flightSchedule[0].Arrival_Terminal__r.Airport__c);
                   oppRec.Arriving_Airport__c = flightSchedule[0].Arrival_Terminal__r.Airport__c;
                   oppRec.Departure_Airport__c = flightSchedule[0].Departure_Terminal__r.Airport__c;
                   oppRec.Service_Terminal__c = (oppRec.Service_Type__c == 'Arrival') ? flightSchedule[0].Arrival_Terminal__c : (oppRec.Service_Type__c == 'Departure') ? flightSchedule[0].Departure_Terminal__c: terminalList[0].id;
                  
                    //oppRec.Service_Terminal__c = ;
                }
                 
                insert oppRec;
                
                mden_responseWrapper.id = oppRec.id;
                System.debug('----oppRec----------->'+oppRec.id);
                
            }
            else{
                mden_responseWrapper = new MDEN_GetResponseWrapper('false', 'data not found.');
            }
            
            system.debug('mden_responseWrapper==>'+JSON.serialize(mden_responseWrapper)); 
        
    			system.debug('mden_responseWrapper==>'+JSON.serialize(mden_responseWrapper)); 
        }catch(Exception e){
        mden_responseWrapper = new MDEN_GetResponseWrapper('false', e.getMessage());
        system.debug('mden_responseWrapper==>'+JSON.serialize(mden_responseWrapper)); 
    }
    
    return mden_responseWrapper;
}	 

global static boolean checkCustomerDuplicacy(String email, String accId){
    Account acc = new Account();
    system.debug('email==>'+email);
    system.debug('accId==>'+accId);
    
    try{
        if(accId <> null){
            acc = [Select id from Account Where PersonEmail = :email AND id != :accId];
        }else{
            acc = [Select id from Account Where PersonEmail = :email];
        }
        system.debug('acc==>'+acc	);
        if(acc <> null){
            return true;
        }else{
            return false;
        }
    	}catch(Exception e){
        System.debug('Error Message : '+e.getMessage());
        return false;
    }
}

global class MDEN_GetResponseWrapper {
    global String status; 
    global String message;
    global String id;
    global MDEN_GetResponseWrapper(String status, String message) {
        this.status = status;
        this.message = message; 
    }        
}

global class Order{
    global String partner_id;
    global String date_order;
    global String airport_location_id;
    global Date travel_date;
    global String commitment_date;
    global String airport_terminal_id;
    global String departure_flight_id;
    global String arrival_flight_id;
    global String arrival_airline_id;
    global String departure_airline_id;
    global String service_category;
    global String service_type_id;
    global String arrival_time;
    global String departure_time;
    global String booking_made_from;
    global String from_airport_id;
    global String to_airport_id;
    global Integer no_of_adult;		
    global Integer no_of_children;
    global Integer no_of_infants; 
    global String terminal_id;
    global Time length_stay;
    global String pricelist_id; 
    global String arrival_term;
    global String departure_term;
    global String primary_product_id; 
    global String source; 
    global Order() {
    }
}
}