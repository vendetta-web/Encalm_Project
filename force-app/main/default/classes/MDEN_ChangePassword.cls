/* Created by 	: Maxify Development Team
 * Created Date : 14th Jan, 2025
 * Input 		: userid and password
 * Purpose 		: This API class take userid and password to set the input password as new password for that user. It returns success or fail message.
 */
@RestResource(urlMapping = '/change_password/*')
global class MDEN_ChangePassword {
    @HttpPost
    global static MDEN_GetResponseWrapper changePassword(){
        //Initialize the response wrapper with blank status and blank message
        MDEN_GetResponseWrapper mden_responseWrapper = new MDEN_GetResponseWrapper('', '');
 		try{
            //Uncomment below code to test in Postman
            RestRequest request = RestContext.request;
            MDEN_GetRequestWrapper requestMap = (MDEN_GetRequestWrapper) JSON.deserialize(request.requestbody.toString(), MDEN_GetRequestWrapper.class);
            
            //Uncomment below to call via Developer console using : MDEN_ChangePassword.changePassword();
            /*String reqBody =' { ' +
				' "id": "amita.jain@encalm.com", '+
                ' "password": "445566" '+
            ' } ';

			MDEN_GetRequestWrapper requestMap = (MDEN_GetRequestWrapper) JSON.deserialize(reqBody, MDEN_GetRequestWrapper.class);
           */
            system.debug('requestMap==>'+requestMap);
            //Parsing data from requestMap
            String uId = requestMap.id;
            String password = requestMap.password;
			
            //Fetch the account record matching the requested username and password
            List<Account> accounts = [select id, password__c from Account Where username__c = :uId limit 1];
            
            //Null check
            if((accounts != null && !accounts.isEmpty()) && (password != null && password.trim() != '' && password != accounts[0].password__c)){
                //Initialize the wrapper with status and message
                mden_responseWrapper = new MDEN_GetResponseWrapper('true', 'Your password has been changed successfully!');
                accounts[0].password__c = password;
                update accounts[0];                
            }
            else if((accounts != null && !accounts.isEmpty())  && (password != null && password.trim() != '' && password == accounts[0].password__c) && uId != null && uId != ''){
                mden_responseWrapper = new MDEN_GetResponseWrapper('false', 'New password is exactly same as old password.');
                system.debug('mden_responseWrapper==>'+JSON.serialize(mden_responseWrapper)); 
            }else if(password == null || password.trim() == ''){
                mden_responseWrapper = new MDEN_GetResponseWrapper('false', 'You can not set a blank password.');
                system.debug('mden_responseWrapper==>'+JSON.serialize(mden_responseWrapper)); 
            }
            else if(uId == null || uId.trim() == ''|| uId == ''){
                mden_responseWrapper = new MDEN_GetResponseWrapper('false', 'User Id can not be null.');
                system.debug('mden_responseWrapper==>'+JSON.serialize(mden_responseWrapper)); 
            }
            else{
                mden_responseWrapper = new MDEN_GetResponseWrapper('false', 'User not found in the system.');
            }  		                                     
        }catch(Exception e){
            mden_responseWrapper = new MDEN_GetResponseWrapper('false', e.getMessage());
        }
        system.debug('mden_responseWrapper==>'+JSON.serialize(mden_responseWrapper));             
        
        return mden_responseWrapper;
    }	     
        
    global class MDEN_GetRequestWrapper {
        global String id; 
        global String password;
        global MDEN_GetRequestWrapper() {
        }        
    }

    global class MDEN_GetResponseWrapper {
        global String status; 
        global String message;
        global MDEN_GetResponseWrapper(String status, String message) {
            this.status = status;
            this.message = message; 
        }        
    }
    
}