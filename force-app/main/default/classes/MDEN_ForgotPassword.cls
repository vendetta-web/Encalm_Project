/* Created by 	: Maxify Development Team
 * Created Date : 14th Jan, 2025
 * Input 		: None
 * Purpose 		: This API class returns all the salutations
 */
@RestResource(urlMapping = '/forgot_password/*')
global class MDEN_ForgotPassword {
   
    @HttpPost
    global static MDEN_GetResponseWrapperWithoutData getForgotPassword(){
        MDEN_GetResponseWrapperWithoutData mden_responseWrapper = new MDEN_GetResponseWrapperWithoutData('', '');
        
 		try{
            RestRequest request = RestContext.request;
            Map<String, Object> requestMap = (Map<String, Object>) JSON.deserializeUntyped(request.requestbody.toString());
            
            String reqBody =' { ' +
				' "email": "vijay.garg@maxify.digital" '+
            ' } ';
            
            //Map<String, Object> requestMap = (Map<String, Object>) JSON.deserializeUntyped(reqBody);
            
             system.debug('requestMap==>'+requestMap.get('email'));
             
            /*
username:namita.jain@encalm.com 
password:EnEWY5 

*/ 
            String email = (String)requestMap.get('email');
            
            Account acc = [select id, PersonTitle, name, firstname, lastname, PersonEmail, PersonMobilePhone, /*PersonGenderIdentity,*/ PersonBirthdate, /*ClickToDial__Country_Code__c,*/ State__c, State__r.State_Name__c, Country__c, Country__r.Country_Name__c, Pin_Code__c, type, username__c, password__c from Account Where PersonEmail = :email /* AND password__c = :password*/ limit 1];
            system.debug('acc==>'+acc);
            system.debug('acc.password__c==>'+acc.password__c);
            system.debug('PersonTitle==>'+acc.PersonTitle);
            if(acc != null && acc.password__c != null){
                sendEmail(acc.PersonEmail, acc.password__c);
                mden_responseWrapper = new MDEN_GetResponseWrapperWithoutData('true', 'Your password has been reset successfully & sent on your registerd email id!');
            }else{
                System.debug('User not found in the system.');
                mden_responseWrapper = new MDEN_GetResponseWrapperWithoutData('false', 'User not found in the system.');
            }
        }catch(Exception e){
            mden_responseWrapper = new MDEN_GetResponseWrapperWithoutData('false', e.getMessage());
            system.debug('Getting Error==>'+e.getMessage());
        }
        
        return mden_responseWrapper;
    }	    
    
    public static void sendEmail(String toAddress, String password) {
        // Create an instance of the SingleEmailMessage class
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

        // Set the recipient (To address)
        String[] toAddresses = new String[] { toAddress };
        email.setToAddresses(toAddresses);

        // Set email subject
        email.setSubject('Subject: Password Reset Email');

        // Set email body
        email.setPlainTextBody('Your password has been reset Successfully. <br/><br/>Please find your new password : '+password);

        // Optionally, set an HTML body
        email.setHtmlBody('Your password has been reset Successfully. <br/><br/>Please find your new password : '+password);

        // Send the email
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
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