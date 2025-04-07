/* Created by 	: Maxify Development Team
 * Created Date : 14th Jan, 2025
 * Input 		: None
 * Purpose 		: This API class returns all the salutations
 */
@RestResource(urlMapping='/save_booking_cancel_request/*')	
global class MDEN_SaveBookingCancelRequest {
    @HttpPost
    global static MDEN_GetResponseWrapper saveBookingCancelRequest(){
        //Initialize the response wrapper with blank status and blank message
        MDEN_GetResponseWrapper mden_responseWrapper = new MDEN_GetResponseWrapper('', '');
        try{
            RestRequest request = RestContext.request;
            MDEN_GetRequestWrapper requestMap = (MDEN_GetRequestWrapper)JSON.deserialize(request.requestBody.toString(), MDEN_GetRequestWrapper.class);
            
            
            //Uncomment below to call via Developer console using : MDEN_GetAirportTerminalByAirport.getAiportTerminals();
            /*
            String reqBody =' { ' +
                                ' "id" : "006Su00000AOxScIAL" '+
                            ' } ';
                        
            MDEN_GetRequestWrapper requestMap = (MDEN_GetRequestWrapper) JSON.deserialize(reqBody, MDEN_GetRequestWrapper.class);
            */
            
            System.debug('requestMap==>'+requestMap);
            
            List<Opportunity> oppList = [Select id, StageName From Opportunity Where id = :requestMap.id];
                
            if(oppList != null & !oppList.isEmpty())
            {
                //Initialize the wrapper with status and message
                mden_responseWrapper.id = 'true';
                oppList[0].StageName = 'Cancel Order';

				update oppList[0];                
            }    
            else{
                mden_responseWrapper = new MDEN_GetResponseWrapper('false', 'data not found.');
                mden_responseWrapper.id = 'false';
                system.debug('mden_responseWrapper==>'+JSON.serialize(mden_responseWrapper)); 
            }
        			system.debug('mden_responseWrapper==>'+JSON.serialize(mden_responseWrapper)); 
        }catch(Exception e){
            mden_responseWrapper = new MDEN_GetResponseWrapper('false', e.getMessage());
            mden_responseWrapper.id = 'false';
            system.debug('mden_responseWrapper==>'+JSON.serialize(mden_responseWrapper)); 
        }
        
        return mden_responseWrapper;
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
    
    global class MDEN_GetRequestWrapper{
        global String id;
        
        global MDEN_GetRequestWrapper() {
        }
    }
}