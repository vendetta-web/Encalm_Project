/* Created by 	: Maxify Development Team
 * Created Date : 14th Jan, 2025
 * Input 		: Country value in JSON format
 * Purpose 		: This API class returns all the States based on the country value passed
 */
@RestResource(urlMapping='/get_state/*')	
global class MDEN_GetStateMaster {
	@HttpGet
    global static MDEN_GetResponseWrapper getState(){
        //Initialize the response wrapper with blank status and blank message
		MDEN_GetResponseWrapper mden_responseWrapper = new MDEN_GetResponseWrapper('', '');
		
        try{
            //Uncomment below to call via Postman
            RestRequest request = RestContext.request;
            MDEN_GetRequestWrapper requestMap = (MDEN_GetRequestWrapper) JSON.deserialize(request.requestbody.toString(), MDEN_GetRequestWrapper.class);
            
            
            //Uncomment below to call via Developer console using : MDEN_GetStateMaster.getState();
            /*String reqBody =' { ' +
                            ' "country_id" : "India"' +
            ' } ';	
			MDEN_GetRequestWrapper requestMap = (MDEN_GetRequestWrapper) JSON.deserialize(reqBody, MDEN_GetRequestWrapper.class);*/
			 
            //Parsing data from requestMap
            system.debug('requestMap==>'+requestMap);
            String country_id = (String)requestMap.country_id; 
			system.debug('requestMap.get==>'+requestMap.country_id);
            
            //Fetch all States based on country value
            List<State__c> stateDetails = [Select id, name, State_Name__c 
                                             From State__c
                                             Where country__r.country_name__c = :country_id]; 
            
            system.debug('stateDetails==>'+stateDetails);
            
            //Null check
            if(stateDetails != null && stateDetails.size() > 0){
                //Initialize the wrapper with status and message
                mden_responseWrapper = new MDEN_GetResponseWrapper('true', 'data found.');
            
                List<StateWrapper> datalist = new List<StateWrapper>();
                
                //Considering that arrival and departure airport can not be same
                for(State__c sat: stateDetails){
	            	StateWrapper state = new StateWrapper(sat.name, sat.State_Name__c);
                    //stat.id = sat.name;
                    //stat.name = sat.State_Name__c;
                    
                    datalist.add(state);
                }
                
                system.debug('datalist==>'+datalist);
                    
                mden_responseWrapper.datalist = datalist;
                
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
        global String country_id; 
        
        global MDEN_GetRequestWrapper() {
        }        
    } 
    
    global class MDEN_GetResponseWrapper {
        global String status; 
        global String message;
        global List<StateWrapper> datalist;
        global MDEN_GetResponseWrapper(String status, String message) {
            this.status = status;
            this.message = message; 
        }        
    }
    global class StateWrapper{
        global string id;
        global string name;
        
        global StateWrapper(string id, string name){
            this.id = id;
            this.name = name;
        }
    }
}