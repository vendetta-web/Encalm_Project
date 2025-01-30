/* Created by 	: Maxify Development Team
 * Created Date : 14th Jan, 2025
 * Input 		: None
 * Purpose 		: This API class returns the list of service airport 
 */
@RestResource(urlMapping='/get_service_airport/*')	
global class MDEN_GetServiceAirport { 
    //Call on Developer console using : MDEN_GetServiceAirport.getServiceAirport();
    @HttpGet
    global static MDEN_GetResponseWrapper getServiceAirport(){
        //Initialize the response wrapper with blank status and blank message
		MDEN_GetResponseWrapper mden_responseWrapper = new MDEN_GetResponseWrapper('', '');
		
        try{
            	//We might use custom metadata for all servicalbe airports. Please check Service_Airport__mdt
            	//Fetch list of airports from Airport__c object
                List<Airport__c>  airportList = [select id,
                                                        name,
                                                        Airport_Name__c,
                                                        Display_Name__c,
                                                        Location_Id__r.name,
                                                        Location_Id__r.Location_Code__c,
                                                        Location_Id__r.City__c,
                                                        State_Id__r.name,
                                                        State_Id__r.State_name__c,
                                                        Service_Available__c,
                                                        Country_Id__r.name,
                                                        Country_Id__r.Country_name__c
                                                 from Airport__c 
                                                 Where Service_Available__c = true];
            
            system.debug('airportList==>'+airportList);
            
            //Null check for the airport list
            if(airportList <> null && airportList.size() >= 0){
                	//Initialize the wrapper with status and message
                    mden_responseWrapper = new MDEN_GetResponseWrapper('true', 'data found.');
                    List<AirportWrapper> datalist = new List<AirportWrapper>();
                        
                    for(Airport__c airport: airportList){
                        AirportWrapper airportWrap = new AirportWrapper();
                        airportWrap.id = airport.name;
                        airportWrap.name = airport.Airport_Name__c;
                        airportWrap.airport_location_code_id = (airport.Location_Id__c <> null) ? new List<String>{airport.Location_Id__r.name, airport.Location_Id__r.Location_Code__c} : new List<String>{'', ''};
                        airportWrap.city = (airport.Location_Id__c <> null) ? airport.Location_Id__r.City__c : '';
                        airportWrap.country_id = (airport.Country_Id__c <> null) ? new List<String>{airport.Country_Id__r.name, airport.Country_Id__r.Country_name__c} : new List<String>{'', ''};
                        airportWrap.state_id = (airport.State_Id__c <> null) ? airport.State_Id__r.name : '';
                        airportWrap.display_name = airport.Display_Name__c;
                      
                        datalist.add(airportWrap);
                    }
                    mden_responseWrapper.datalist = datalist;
                    
                	system.debug('mden_responseWrapper==>'+JSON.serialize(mden_responseWrapper));
            }
            else{
                mden_responseWrapper = new MDEN_GetResponseWrapper('false', 'data not found.');
            }
        }
        catch(Exception e){
            mden_responseWrapper = new MDEN_GetResponseWrapper('false', e.getMessage());
        }
		
		return mden_responseWrapper;
    }
    
    //Response Wrapper
    global class MDEN_GetResponseWrapper {
        global String status; 
        global String message;
        global List<AirportWrapper> datalist;
        global MDEN_GetResponseWrapper(String status, String message) {
            this.status = status;
            this.message = message; 
        }        
    }
    
    //Airport wrapper
    global class AirportWrapper{
        global string id;
        global string name;
        global List<String> airport_location_code_id;
        global string city;
        global List<String> country_id;
        global string state_id;
        global string display_name;
        
        global AirportWrapper(){
            
        }
    }
}