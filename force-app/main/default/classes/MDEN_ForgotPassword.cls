/* Created by 	: Maxify Development Team
 * Created Date : 14th Jan, 2025
 * Input 		: User email
 * Purpose 		: This API class reset the password and send it over user email
 */
@RestResource(urlMapping = '/forgot_password/*')
global class MDEN_ForgotPassword {
   
    @HttpPost
    global static MDEN_GetResponseWrapper getForgotPassword(){
        //Initialize the response wrapper with blank status and blank message
        MDEN_GetResponseWrapper mden_responseWrapper = new MDEN_GetResponseWrapper('', '');
        
 		try{
            //Uncomment below code to test in Postman
           RestRequest request = RestContext.request;
            Map<String, Object> requestMap = (Map<String, Object>) JSON.deserializeUntyped(request.requestbody.toString());
            //Uncomment below to call via Developer console using : MDEN_ForgotPassword.getForgotPassword();
            /*String reqBody =' { ' +
				' "email": "vijay.garg@maxify.digital" '+
            ' } ';*/
            system.debug('requestMap==>'+requestMap.get('email'));
			//Parsing data from requestMap
            String email = (String)requestMap.get('email');
            System.debug('=======email=========='+email);
            //Fetch Account detail based on filter of input parameters
            List<Account> accounts = [select id,
                                           PersonTitle,
                                           name,
                                           firstname,
                                           lastname,
                                           PersonEmail,
                                           PersonMobilePhone,
                                           /*PersonGenderIdentity,
                                            */ PersonBirthdate,
                                           /*ClickToDial__Country_Code__c,
                                            */ State__c,
                                           State__r.State_Name__c,
                                           Country__c,
                                           Country__r.Country_Name__c,
                                           Pin_Code__c,
                                           type,
                                           username__c,
                                           password__c
                                   From Account 
                                   Where PersonEmail = :email /* AND password__c = :password*/ limit 1];
            system.debug('acc==>'+accounts);
            system.debug('accounts[0].password__c==>'+accounts[0].password__c);
            system.debug('PersonTitle==>'+accounts[0].PersonTitle);
            
            //Null Check
            if((accounts != null && !accounts.isEmpty()) && (accounts[0].password__c != null && accounts[0].password__c.trim() != '')){
                //Send Email with existing password of the user
                sendEmail(accounts[0].PersonEmail, accounts[0].password__c);
                mden_responseWrapper = new MDEN_GetResponseWrapper('true', 'Your password has been reset successfully & sent on your registerd email id!');
            }else{
                System.debug('User not found in the system.');
                mden_responseWrapper = new MDEN_GetResponseWrapper('false', 'User not found in the system.');
            }
        }catch(Exception e){
            mden_responseWrapper = new MDEN_GetResponseWrapper('false', e.getMessage());
            system.debug('Getting Error==>'+e.getMessage());
        }
        
        system.debug('mden_responseWrapper==>'+JSON.serialize(mden_responseWrapper)); 
        
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
    
    global class MDEN_GetResponseWrapper {
        global String status; 
        global String message;
        global MDEN_GetResponseWrapper(String status, String message) {
            this.status = status;
            this.message = message; 
        }        
    }
}