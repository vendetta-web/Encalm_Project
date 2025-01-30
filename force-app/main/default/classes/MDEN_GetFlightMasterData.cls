/* Created by 	: Maxify Development Team
 * Created Date : 14th Jan, 2025
 * Input 		: Service type, to  & from airport, travel date etc.
 * Purpose 		: This API class returns all the salutations
 */
@RestResource(urlMapping='/get_flight_list_for_booking/*')	
global class MDEN_GetFlightMasterData {
	@HttpGet
    global static MDEN_GetResponseWrapper getFlightListForBooking(){
        //Initialize the response wrapper with blank status and blank message
        MDEN_GetResponseWrapper mden_responseWrapper = new MDEN_GetResponseWrapper('', '');
		
        try{
            //Uncomment below code to test in Postman
            /*RestRequest request = RestContext.request;
            MDEN_GetRequestWrapper requestMap = (MDEN_GetRequestWrapper) JSON.deserialize(request.requestbody.toString(), MDEN_GetRequestWrapper.class);
            */
            //Uncomment below to call via Developer console using : MDEN_GetFlightMasterData.getFlightListForBooking();
            String reqBody =' { ' +
	        ' "service_airport" : "Indira Gandhi International Airport", ' +
            ' "from_airport" : "Indira Gandhi International Airport", ' +
            ' "to_airport" : "Rajiv Gandhi International Airport", ' +
            ' "travel_date" : "2025-03-31" ' +
            ' } ';
            
            MDEN_GetRequestWrapper requestMap = (MDEN_GetRequestWrapper) JSON.deserialize(reqBody, MDEN_GetRequestWrapper.class);		
            
            system.debug('requestMap==>'+requestMap);
            //Parsing data from requestMap
            String service_airport = (String)requestMap.service_airport; 
			String from_airport = (String)requestMap.from_airport;  
            String to_airport = (String)requestMap.to_airport;  
            Date travel_date = Date.valueOf(String.valueOf(requestMap.travel_date));  
            system.debug('requestMap.get==>'+requestMap.travel_date);
            
            system.debug('service_airport==>'+service_airport);
            system.debug('from_airport==>'+from_airport);
            system.debug('to_airport==>'+to_airport);
            system.debug('travel_date==>'+travel_date);
            
            //Fetch the flight details using flight schedules object
            List<Flight_Schedule__c> flightSchedules = [Select  id,
                                                                Flight_Detail__c,
                                                                STA__c,
                                                                STD__c,
                                                                Departure_Terminal__r.Name,
                                                                Departure_Terminal__r.Airport__r.Location_Id__r.name,
                                                                Departure_Terminal__r.Airport__r.Location_Id__r.Location_Code__c,
                                                                Arrival_Terminal__r.Name,
                                                                Arrival_Terminal__r.Airport__r.Location_Id__r.name,
                                                                Arrival_Terminal__r.Airport__r.Location_Id__r.Location_Code__c,
                                                                Flight_Detail__r.id,
                                                                Flight_Detail__r.name,
                                                                Flight_Detail__r.Flight_Name__c,
                                                                Flight_Detail__r.Airline_Id__r.Airline_Code__c,
                                                                Flight_Detail__r.Flight_No_Arrival__c,
                                                                Flight_Detail__r.Flight_No_Departure__c,
                                                                Flight_Detail__r.Airline_Id__r.name,
                                                                Flight_Detail__r.Airline_Id__r.Airline_Name__c  
             	      									  From Flight_Schedule__c 
            											  Where Flight_Date__c =:travel_date AND
                                                                Departure_Terminal__r.Airport__r.Airport_Name__c =:to_airport AND                                                          
                                                                Arrival_Terminal__r.Airport__r.Airport_Name__c =:from_airport AND
                                                                (Arrival_Terminal__r.Airport__r.Airport_Name__c =:service_airport OR Departure_Terminal__r.Airport__r.Airport_Name__c =:service_airport)];
            

			system.debug('flightSchedules==>'+flightSchedules);
            
            //Null check
            if(flightSchedules != null && !flightSchedules.isEmpty()){
                //Initialize the wrapper with status and message
                mden_responseWrapper = new MDEN_GetResponseWrapper('true', 'data found.');
            
                List<FlightScheduleDetail> datalist = new List<FlightScheduleDetail>();
                
                for(Flight_Schedule__c flightSchedule: flightSchedules){
                    FlightScheduleDetail fsd = new FlightScheduleDetail();
                    fsd.id = flightSchedule.Flight_Detail__r.name;
                    fsd.flight_name = flightSchedule.Flight_Detail__r.Flight_Name__c;
                    fsd.air_design_ad = flightSchedule.Flight_Detail__r.Airline_Id__r.Airline_Code__c;
                    fsd.flt_no_arrival = String.isEmpty(flightSchedule.Flight_Detail__r.Flight_No_Arrival__c) ? 'False' : flightSchedule.Flight_Detail__r.Flight_No_Arrival__c;
                    fsd.flt_no_departure = String.isEmpty(flightSchedule.Flight_Detail__r.Flight_No_Departure__c) ? 'False' : flightSchedule.Flight_Detail__r.Flight_No_Departure__c;
                    fsd.arrival_time = String.valueOf(flightSchedule.STA__c);
                    fsd.departure_time = String.valueOf(flightSchedule.STD__c);
                    fsd.airline_id = new List<String>{flightSchedule.Flight_Detail__r.Airline_Id__r.name, flightSchedule.Flight_Detail__r.Airline_Id__r.Airline_Name__c};
                    fsd.arrival_term = flightSchedule.Arrival_Terminal__r.Name;
                    fsd.departure_term = flightSchedule.Departure_Terminal__r.Name;
                    String airport_location_code;
                    String airport_location_name;
                    if(!String.isEmpty(flightSchedule.Arrival_Terminal__r.Name)){
                        airport_location_code = flightSchedule.Arrival_Terminal__r.Airport__r.Location_Id__r.name;
                        airport_location_name = flightSchedule.Arrival_Terminal__r.Airport__r.Location_Id__r.Location_Code__c;
                    }else if(!String.isEmpty(flightSchedule.Departure_Terminal__r.Name)){
                        airport_location_code = flightSchedule.Departure_Terminal__r.Airport__r.Location_Id__r.name;
                        airport_location_name = flightSchedule.Departure_Terminal__r.Airport__r.Location_Id__r.Location_Code__c;
                    }
                    fsd.airport_location_code_id = new List<String>{airport_location_name, airport_location_code};
                        
                        //gtba.value = serviceAirport.Airport_Name__c;
                        //gtba.code = String.valueOf(serviceAirport.Location_Id__c);
                        datalist.add(fsd);
                }
                mden_responseWrapper.datalist = datalist;
                //gtba.id = terminal.name;
                //gtba.name = terminal.Airport__r.name;
                //gtba.value = terminal.name;
                //gtba.code = terminal.Code__c;
                system.debug('mden_responseWrapper==>'+JSON.serialize(mden_responseWrapper));
            }
            else{
                mden_responseWrapper = new MDEN_GetResponseWrapper('false', 'data not found.');
            }
        }catch(Exception e){
            mden_responseWrapper = new MDEN_GetResponseWrapper('false', e.getMessage());
        }
		
		return mden_responseWrapper;
    }	
    
    global class MDEN_GetRequestWrapper {
        global String service_airport; 
        global String from_airport;
        global String to_airport; 
        global String travel_date;

        global MDEN_GetRequestWrapper() {
        }        
    }    
    
    global class MDEN_GetResponseWrapper {
        global String status; 
        global String message;
        global List<FlightScheduleDetail> datalist;
        global MDEN_GetResponseWrapper(String status, String message) {
            this.status = status;
            this.message = message; 
        }        
    }
    global class FlightScheduleDetail{
        global string id;
        global string flight_name; 
        global string air_design_ad;
        global string flt_no_arrival;
        global string flt_no_departure;
        global string arrival_time;
        global string departure_time;
        global List<String> airline_id;
        global string arrival_term;
        global string departure_term;
        global List<String> airport_location_code_id;
                
        global FlightScheduleDetail(){
            
        }
    }
}