/* Created by 	: Maxify Development Team
 * Created Date : 14th Jan, 2025
 * Input 		: None
 * Purpose 		: This API class returns all the salutations
 */
@RestResource(urlMapping='/get_sale_order_list_for_partner/*')	
global class MDEN_GetSaleOrdersForCustomer {
    @HttpGet
    global static MDEN_GetResponseWrapper getSaleOrdersForCustomer(){
        //Initialize the response wrapper with blank status and blank message
        MDEN_GetResponseWrapper mden_responseWrapper = new MDEN_GetResponseWrapper('', '');
        
        try{
            //MDEN_RegisterCustomer.registerCustomer();
            
            Map<String, String> flightTypeMap = new Map<String, String>{
                'Arrival' => '1', 
                    'Departure' => '2',
                    'Transit' => '3'
                    };
                        
                                                
            //Uncomment below code to test in Postman
            RestRequest request = RestContext.request;
            MDEN_GetRequestWrapper requestMap = (MDEN_GetRequestWrapper) JSON.deserialize(request.requestBody.toString(), MDEN_GetRequestWrapper.class);
            
			//Uncomment below to call via Developer console using : MDEN_GetAirportTerminalByAirport.getAiportTerminals();
            /*
            String reqBody =' { ' +
                            ' "partner_id": "006Su00000AQldRIAT" '+
                            ' } ';
            
            
            MDEN_GetRequestWrapper requestMap = (MDEN_GetRequestWrapper) JSON.deserialize(reqBody, MDEN_GetRequestWrapper.class);
            */
            
            System.debug('requestMap==>'+requestMap.partner_id);
            if(requestMap <> null && requestMap.partner_id <> null){
                List<Salutation__c> salutationList = new List<Salutation__c>();
                List<Country__c> countryList = new List<Country__c>();
                
                /********** Start : Fetching Main Data i.e. Opportunity Details **********/
                List<mainDataList> listOfMainData = new List<mainDataList>();
                
                List<Opportunity> oppList = [Select  id, 
                                             		 name, 
                                             	   	 AccountId,
                                             		 Account.name,
                                             		 Account.firstname,
                                             		 Account.lastname,	
                                             		 Account.Country__c,
                                                     Account.Country__r.name,
                                             		 Account.Phone,
                                              		 Account.PersonMobilePhone,
                                             		 Account.PersonTitle,
                                             		 Amount,
                                             	   	 StageName,
                                                   	 Number_of_Adults__c, 
                                                     Number_of_Children__c, 
                                                     Number_of_Infants__c,
                                                     Date_of_Arrival__c,
                                                     Date_of_Departure__c,
                                                     Flight_Number_Arrival__c,
                                                     Flight_Number_Departure__c,
                                                     Arriving_Airport__c,
                                                     Departure_Airport__c,
                                                     Flight_Type__c,
                                                     STA_Time__c,
                                                     STD_Time__c,
                                                     Sector__c,
                                             		 CreatedDate,
                                                     Service_Airport__c,
                                             		 Service_Category__c,
                                             		 Service_Type__c,
                                                     //Service_Airport__r.Airport_Name__c,
                                             		 //Service_Airport__r.Location_Id__c,
                                             		 Arriving_Flight_Schedule__c,
                                             		 Arriving_Flight_Schedule__r.Arrival_Terminal__c,
                                             		 Arriving_Flight_Schedule__r.Arrival_Terminal__r.name,
                                             		 Arriving_Flight_Schedule__r.Arrival_Terminal__r.Code__c,
                                             		 Arriving_Flight_Schedule__r.Arrival_Terminal__r.Airport__c, 
                                             		 Arriving_Flight_Schedule__r.Arrival_Terminal__r.Airport__r.Location_Id__c,
                                             		 Arriving_Flight_Schedule__r.Arrival_Terminal__r.Airport__r.Airport_Name__c,
                                             		 Departure_Flight_Schedule__c,
                                             		 Departure_Flight_Schedule__r.Arrival_Terminal__c,
                                             		 Departure_Flight_Schedule__r.Arrival_Terminal__r.name,
                                             		 Departure_Flight_Schedule__r.Arrival_Terminal__r.Code__c,
                                             		 Departure_Flight_Schedule__r.Arrival_Terminal__r.Airport__c, 
                                             		 Departure_Flight_Schedule__r.Arrival_Terminal__r.Airport__r.Location_Id__c,
                                             		 Departure_Flight_Schedule__r.Arrival_Terminal__r.Airport__r.Airport_Name__c,
                                             		 Arriving_Flight_Schedule__r.Flight_Detail__r.name,
                                             		 Arriving_Flight_Schedule__r.Flight_Detail__r.Flight_No_Arrival__c,
                                             		 Arriving_Flight_Schedule__r.Flight_Detail__r.Flight_Name__c,
                                             		 Arriving_Flight_Schedule__r.Flight_Detail__r.Airline_Id__r.name,
                                             		 Arriving_Flight_Schedule__r.Flight_Detail__r.Airline_Id__r.Airline_Name__c,
                                             		 Departure_Flight_Schedule__r.Flight_Detail__r.name,
                                             		 Departure_Flight_Schedule__r.Flight_Detail__r.Flight_No_Departure__c,
                                             		 Departure_Flight_Schedule__r.Flight_Detail__r.Flight_Name__c,
                                             		 Departure_Flight_Schedule__r.Flight_Detail__r.Airline_Id__r.name,
                                             		 Departure_Flight_Schedule__r.Flight_Detail__r.Airline_Id__r.Airline_Name__c
                                             From Opportunity
                                             Where id = :requestMap.partner_id];
                
                System.debug('oppList==>'+oppList);
                if(oppList <> null && !oppList.isEmpty()){
                    //Initialize the wrapper with status and message
                mden_responseWrapper = new MDEN_GetResponseWrapper('true', 'data found.');
                    if(oppList[0].Account.PersonTitle <> null)
                		salutationList = [select id, name, Salutation_Name__c from Salutation__c Where Salutation_Name__c =:oppList[0].Account.PersonTitle limit 1];
                    
                    System.debug('salutationList==>'+salutationList);
                    if(oppList[0].Account.Country__c <> null)
                		countryList = [select id, name, Country_code__c, Country_Name__c, Phone_Code__c from Country__c Where id = :oppList[0].Account.Country__c limit 1];
                    
                    System.debug('countryList==>'+countryList);
                    for(Opportunity opp : oppList){
                        mainDataList mainDataListDetails  = new mainDataList();
						mainDataListDetails.id = opp.id;
                        mainDataListDetails.name = opp.name;
                        mainDataListDetails.dates = String.valueOf(opp.CreatedDate);
                        mainDataListDetails.partner_id = new List<String>{opp.AccountId, opp.Account.name};
                        mainDataListDetails.date_order = String.valueOf(opp.CreatedDate);
                        //mainDataListDetails.airport_location_id = new List<String>{opp.Service_Airport__r.Location_Id__c, opp.Service_Airport__r.Airport_Name__c};
                        //mainDataListDetails.commitment_date = opp.name;
                        //Need Service Terminal field on Opportunity
                        mainDataListDetails.airport_terminal_id = new List<String>{opp.Arriving_Flight_Schedule__r.Arrival_Terminal__r.name, opp.Arriving_Flight_Schedule__r.Arrival_Terminal__r.Code__c};
                        mainDataListDetails.arrival_flight_id = new List<String>{opp.Arriving_Flight_Schedule__r.Flight_Detail__r.Flight_No_Arrival__c, opp.Arriving_Flight_Schedule__r.Flight_Detail__r.Flight_Name__c};
                        mainDataListDetails.departure_flight_id = new List<String>{opp.Departure_Flight_Schedule__r.Flight_Detail__r.Flight_No_Departure__c, opp.Departure_Flight_Schedule__r.Flight_Detail__r.Flight_Name__c};
                        mainDataListDetails.arrival_airline_id = new List<String>{opp.Arriving_Flight_Schedule__r.Flight_Detail__r.Airline_Id__r.name, opp.Arriving_Flight_Schedule__r.Flight_Detail__r.Airline_Id__r.Airline_Name__c};
                        mainDataListDetails.departure_airline_id = new List<String>{opp.Departure_Flight_Schedule__r.Flight_Detail__r.Airline_Id__r.name, opp.Departure_Flight_Schedule__r.Flight_Detail__r.Airline_Id__r.Airline_Name__c};
                        mainDataListDetails.service_category = opp.Service_Category__c;
                        mainDataListDetails.service_type_id = new List<String>{flightTypeMap.get(opp.Service_Type__c), opp.Service_Type__c};
                        mainDataListDetails.arrival_time = opp.STA_Time__c;
                        mainDataListDetails.departure_time = opp.STD_Time__c;
                        //mainDataListDetails.booking_made_from = opp.name;
                        mainDataListDetails.from_airport_id = new List<String>{opp.Arriving_Flight_Schedule__r.Arrival_Terminal__r.Airport__c, opp.Arriving_Flight_Schedule__r.Arrival_Terminal__r.Airport__r.Airport_Name__c};
                        mainDataListDetails.to_airport_id = new List<String>{opp.Departure_Flight_Schedule__r.Arrival_Terminal__r.Airport__c, opp.Departure_Flight_Schedule__r.Arrival_Terminal__r.Airport__r.Airport_Name__c};
                        mainDataListDetails.no_of_adult = String.valueOf(opp.Number_of_Adults__c);
                        mainDataListDetails.no_of_children = String.valueOf(opp.Number_of_Children__c);
                        mainDataListDetails.no_of_infants = String.valueOf(opp.Number_of_Infants__c);
                        //mainDataListDetails.itinerary_no = opp.name;
                        mainDataListDetails.booking_stage = opp.StageName;
                        //mainDataListDetails.pricelist_id = new List<String>{};
						//mainDataListDetails.gso_ids = new List<String>{};

                        listOfMainData.add(mainDataListDetails);
                    }
                                        
                    mden_responseWrapper.datalist = listOfMainData;
                }else{
                    mden_responseWrapper = new MDEN_GetResponseWrapper('false', 'data not found.');
                }
            }
        			system.debug('mden_responseWrapper==>'+JSON.serialize(mden_responseWrapper)); 
        }catch(Exception e){
            mden_responseWrapper = new MDEN_GetResponseWrapper('false', 'data not found.');
        }
                
        return mden_responseWrapper;
    }	 
    /*
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
        			system.debug('mden_responseWrapper==>'+JSON.serialize(mden_responseWrapper)); 
        }catch(Exception e){
            System.debug('Error Message : '+e.getMessage());
            return false;
        }
    }
    */
    
    global class MDEN_GetResponseWrapper{
        global String status;
        global String message; 
        global List<mainDataList> datalist;
        
        global MDEN_GetResponseWrapper(String status, String message){
            this.status = status;
            this.message = message; 
        }   
    } 
	
    global class mainDataList{
        global String id;
        global List<String> partner_id;
        global String name;
        global String date_order;
        global String dates;
        global List<String> airport_location_id;
        global String commitment_date;
        global List<String> airport_terminal_id;
        global List<String> arrival_flight_id;
        global List<String> departure_flight_id;
        global List<String> arrival_airline_id;
        global List<String> departure_airline_id;
        global String service_category;
        global List<String> service_type_id;
        global String arrival_time;
        global String departure_time;
        global String booking_made_from;
        global List<String> from_airport_id;
        global List<String> to_airport_id;
        global String no_of_adult;
        global String no_of_children;
        global String no_of_infants;
        global String itinerary_no;
        global String booking_stage;
        global List<String> pricelist_id;
        global List<String> gso_ids;
                
        global mainDataList(){}
    }
    
    global class MDEN_GetRequestWrapper {
        global String partner_id;
        global MDEN_GetRequestWrapper(){}        
    }
}