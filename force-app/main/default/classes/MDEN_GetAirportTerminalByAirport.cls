/* Created by 	: Maxify Development Team
 * Created Date : 14th Jan, 2025
 * Input 		: airport code in JSON format
 * Purpose 		: This API class returns the list of all airport terminals for a particular airport code given in the request
 */
@RestResource(urlMapping='/get_terminal_by_airport/*')	
global class MDEN_GetAirportTerminalByAirport {
	@HttpGet
    global static MDEN_GetResponseWrapper getAiportTerminals(){
        //Initialize the response wrapper with blank status and blank message
        MDEN_GetResponseWrapper mden_responseWrapper = new MDEN_GetResponseWrapper('', '');
           
        try{
            //Uncomment below to call via Postman
            RestRequest request = RestContext.request;
            Map<String, Object> requestMap = (Map<String, Object>) JSON.deserializeUntyped(request.requestbody.toString());
           
            //Uncomment below to call via Developer console using : MDEN_GetAirportTerminalByAirport.getAiportTerminals();
           /* String reqBody =' { ' +
	        ' "airport_code" : "T1" ' +
            ' } ';*/
            system.debug('requestMap==>'+requestMap);
            
            //Parsing data from requestMap
            String airportCode = (String)requestMap.get('airport_code');
            system.debug('requestMap==>'+requestMap.get('airport_code'));
            
            //Fetch all the Terminals of a particular airport
            List<Terminal__c> terminals = [select name, Airport__r.name, Code__c from Terminal__c Where Name =:airportCode];
            system.debug('terminals==>'+terminals);
            
            //Null check
            if(terminals != null && !terminals.isEmpty()){
                //Initialize the wrapper with status and message
                mden_responseWrapper = new MDEN_GetResponseWrapper('true', 'data found.');
            	
                List<TerminalWrapper> datalist = new List<TerminalWrapper>();
                
                for(Terminal__c terminal: terminals){
                   TerminalWrapper terminalWrap = new TerminalWrapper(
                        terminal.name,
                        terminal.Airport__r.name,
                        terminal.name,
                        terminal.Code__c
                   ); 
                   datalist.add(terminalWrap);
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
    
    global class MDEN_GetResponseWrapper {
        global String status; 
        global String message;
        global List<TerminalWrapper> datalist;
        global MDEN_GetResponseWrapper(String status, String message) {
            this.status = status;
            this.message = message; 
        }        
    }
    global class TerminalWrapper{
        global string id;
        global string name;
        global string value;
        global string code;
        
        global TerminalWrapper(String id, String name, String value, String code) {
            this.id = id;
            this.name = name;
            this.value = value;
            this.code = code;
        }
    }
}