/* Created by 	: Maxify Development Team
 * Created Date : 14th Jan, 2025
 * Input 		: None
 * Purpose 		: This API class returns all the salutations
 */
@RestResource(urlMapping = '/change_password/*')
global class MDEN_ChangePassword {
    @HttpPost
    global static MDEN_GetResponseWrapperWithoutData changePassword(){
        MDEN_GetResponseWrapperWithoutData mden_responseWrapper = new MDEN_GetResponseWrapperWithoutData('', '');
 		try{
            //MDEN_ChangePassword.changePassword();
            
            //Uncomment below to test from Postman
            RestRequest request = RestContext.request;
            Map<String, Object> requestMap = (Map<String, Object>) JSON.deserializeUntyped(request.requestbody.toString());
            
            
            //Uncomment below to test from Dev Console
            /*
            String reqBody =' { ' +
				' "id": "hgdhdhdfdfd", '+
                ' "password": "4455" '+
            ' } ';

			Map<String, Object> requestMap = (Map<String, Object>) JSON.deserializeUntyped(reqBody);
            */

            String uId = (String)requestMap.get('id');
            String password = (String)requestMap.get('password');
            Account acc;
            List<Account> accList = [select id, password__c from Account Where username__c = :uId limit 1];
            if(!accList.isEmpty()){
                acc = accList[0];
            }
            system.debug('acc==>'+acc);
            system.debug('password==>'+password);
            
           if(acc != null && (password != null && password.trim() != '' && password != acc.password__c)){
                mden_responseWrapper = new MDEN_GetResponseWrapperWithoutData('true', 'Your password has been changed successfully!');
                acc.password__c = password;
                update acc;                
            }
            else if(acc != null && (password != null && password.trim() != '' && password == acc.password__c) && uId != null && uId != ''){
                mden_responseWrapper = new MDEN_GetResponseWrapperWithoutData('false', 'New password is exactly same as old password.');
                system.debug('mden_responseWrapper==>'+JSON.serialize(mden_responseWrapper)); 
            }else if(password == null || password.trim() == ''){
                mden_responseWrapper = new MDEN_GetResponseWrapperWithoutData('false', 'You can not set a blank password.');
                system.debug('mden_responseWrapper==>'+JSON.serialize(mden_responseWrapper)); 
            }
            
            else if(uId == null || uId.trim() == ''|| uId == ''){
                mden_responseWrapper = new MDEN_GetResponseWrapperWithoutData('false', 'User Id can not be null.');
                system.debug('mden_responseWrapper==>'+JSON.serialize(mden_responseWrapper)); 
            }
            else{
                mden_responseWrapper = new MDEN_GetResponseWrapperWithoutData('false', 'User not found in the system.');
                system.debug('mden_responseWrapper==>'+JSON.serialize(mden_responseWrapper)); 
            }  		                                     
        }catch(Exception e){
            mden_responseWrapper = new MDEN_GetResponseWrapperWithoutData('false', e.getMessage());
            system.debug('mden_responseWrapper==>'+JSON.serialize(mden_responseWrapper));             
        }
        
        return mden_responseWrapper;
    }	     
        
    global class MDEN_GetResponseWrapperWithoutData {
        global String status; 
        global String message;
        global MDEN_GetResponseWrapperWithoutData(String status, String message) {
            this.status = status;
            this.message = message; 
        }        
    }
    
}