/* Created by 	: Maxify Development Team
 * Created Date : 14th Jan, 2025
 * Input 		: Service type and Travel sectors in JSON format
 * Purpose 		: This API class returns all the sector details
 */
@RestResource(urlMapping='/get_general_value/*')	
global class MDEN_SectorDetails {
	@HttpGet
    global static MDEN_GetResponseWrapper getSectorDetails(){
        //Initialize the response wrapper with blank status and blank message
		MDEN_GetResponseWrapper mden_responseWrapper = new MDEN_GetResponseWrapper('', '');
        try{
            //Uncomment below to call via Postman
            /*RestRequest request = RestContext.request;
            MDEN_GetRequestWrapper requestMap = (MDEN_GetRequestWrapper) JSON.deserialize(request.requestbody.toString(), MDEN_GetRequestWrapper.class);
            */
            //Uncomment below to call via Developer console using : MDEN_SectorDetails.getSectorDetails();
            String reqBody =' { ' +
                        ' "service_type" : "Transit", ' +
                        ' "arrival_airport" : "DEL-Indira Gandhi International Airport", ' +
                        ' "departure_airport" : "GOX-Manohar International Airport" ' +
                        ' } ';
            
            MDEN_GetRequestWrapper requestMap = (MDEN_GetRequestWrapper) JSON.deserialize(reqBody, MDEN_GetRequestWrapper.class);
            
            
            system.debug('requestMap==>'+requestMap);
            
            //Parsing data from requestMap
            String service_type = (String)requestMap.service_type; 
			String arrival_airport = ((String)requestMap.arrival_airport).split('-')[1];  
            String departure_airport = ((String)requestMap.departure_airport).split('-')[1]; 
            
            system.debug('service_type==>'+service_type);
            system.debug('arrival_airport==>'+arrival_airport);
            system.debug('departure_airport==>'+departure_airport);  
            
            //List including arrival and departure airports both from the requset
            List<String> airports = new List<String>{arrival_airport, departure_airport};
                
            List<Airport__c> sectorDetails = [Select id,
                                                     Sector__r.name,
                                                     Sector__r.Sector_name__c,
                                                     Sector__r.code__c,
                                                     Sector__r.value__c,
                                                     Airport_Name__c 
                                             From Airport__c 
                                             Where Airport_Name__c in :airports]; //in ('Indira Gandhi International Airport', 'Chhatrapati Shivaji Maharaj International Airport Mumbai')];
            
            system.debug('sectorDetails==>'+sectorDetails);
            
            //Null check for the airport list
            if(sectorDetails != null && sectorDetails.size() == 2){
                //Initialize the wrapper with status and message
                mden_responseWrapper = new MDEN_GetResponseWrapper('true', 'data found.');
            	
                List<SectorWrapper> datalist = new List<SectorWrapper>();
                SectorWrapper arriving_sector = new SectorWrapper();
                SectorWrapper departure_sector = new SectorWrapper();
                
                //Considering that arrival and departure airport can not be same. 
                //Check both airports given in the request parameters. Set the arrival airport under arriving Sector and similarly set the departure airport under departure sector
                for(Airport__c airport: sectorDetails){
	                if(airport.Airport_Name__c == arrival_airport){
                        arriving_sector.name = airport.Sector__r.Sector_name__c;
                        arriving_sector.id = airport.Sector__r.name;
                        arriving_sector.code = airport.Sector__r.code__c;
                        arriving_sector.value = airport.Sector__r.value__c;
                    }else if(airport.Airport_Name__c == departure_airport){
                        departure_sector.name = airport.Sector__r.Sector_name__c;
                        departure_sector.id = airport.Sector__r.name;
                        departure_sector.code = airport.Sector__r.code__c;
                        departure_sector.value = airport.Sector__r.value__c;
                    }
                }
                system.debug('arriving_sector==>'+arriving_sector);
                system.debug('departure_sector==>'+departure_sector);
                
                //Check the sector type 'Arrival'/'Departure'/'Transit' given in request parameter and the sector type of arriving and depature airports. And based on that add the sector in response
                //In case, 'Arrival' or 'Departure' sector types are given in request parameter then return either 'Domestic' or 'International' sector details
                if(service_type == 'Arrival' || service_type == 'Departure'){
                	//For example, if sector for both arriving and depature airports as given in the request parameters are Domestic then we will add the Domestice sector in the response
                    if(arriving_sector.name == 'Domestic' && departure_sector.name == 'Domestic'){
                        datalist.add(arriving_sector);
                    //For example, if sector for any of arriving and depature airports as given in the request parameters is Internation then we will add the International sector in the response
                    }else if(arriving_sector.name == 'International' || departure_sector.name == 'International'){
                        if(arriving_sector.name == 'International'){
                        	datalist.add(arriving_sector);    
                        }else if(departure_sector.name == 'International'){
                        	datalist.add(departure_sector);    
                        }
                        
                    }
                //In case of 'Transit' sector type in request parameter return sector details of both airports
                }else if(service_type == 'Transit'){
                    datalist.add(arriving_sector);
                    datalist.add(departure_sector);  
                }
                
                system.debug('datalist==>'+datalist);
                    
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
        global String service_type; 
        global String arrival_airport;
        global String departure_airport; 

        global MDEN_GetRequestWrapper() {
        }        
    } 
    
    global class MDEN_GetResponseWrapper {
        global String status; 
        global String message;
        global List<SectorWrapper> datalist;
        global MDEN_GetResponseWrapper(String status, String message) {
            this.status = status;
            this.message = message; 
        }        
    }
    global class SectorWrapper{
        global string id;
        global string name;
        global string value;
        global string code;
                
        global SectorWrapper(){
            
        }
    }
}