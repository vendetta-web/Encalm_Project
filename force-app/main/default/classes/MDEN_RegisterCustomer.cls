/* Created by 	: Maxify Development Team
 * Created Date : 14th Jan, 2025
 * Input 		: None
 * Purpose 		: This API class returns all the salutations
 */
@RestResource(urlMapping='/register_customer/*')	
global class MDEN_RegisterCustomer {
	@HttpPost
    global static MDEN_GetResponseWrapper registerCustomer(){
        //Initialize the response wrapper with blank status and blank message
        MDEN_GetResponseWrapper mden_responseWrapper = new MDEN_GetResponseWrapper('', '');
        try{
            //MDEN_RegisterCustomer.registerCustomer();
            RestRequest request = RestContext.request;
            Customer requestMap = (Customer) JSON.deserialize(request.requestBody.toString(), Customer.class);
            
            /*String reqBody =' { ' +
	        	' "title": "001", '+
                ' "first_name": "Namita", '+
                ' "last_name": "Jain", '+
                ' "email": "namita.jain@encalm.com", '+
                ' "mobile": "8888889999", '+
                ' "gender": "female", '+
                ' "dob": "1995-08-01", '+
                ' "country_code": "0001", '+
                ' "address": "Test Address", '+
                ' "city": "gurugram", '+
                ' "state": "000001", '+
                ' "country_id": "104", '+
                ' "pincode": "122001 ", '+
                ' "password": "123456", '+
                ' "tnc": "yes", '+
                ' "mkt_comm": "yes" '+
            ' } ';
            Customer requestMap = (Customer) JSON.deserialize(reqBody, Customer.class);
            */
            
            system.debug('requestMap==>'+requestMap.title);
            
            Map<String, Schema.RecordTypeInfo> recordTypeInfoMap = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName();
            String personAccountRecordTypeId = recordTypeInfoMap.get('PersonAccount').getRecordTypeId();
            Salutation__c salutation = [select Salutation_Name__c from Salutation__c Where Name =:requestMap.title limit 1];
            Country__c country = [select id, name, Country_Name__c from Country__c Where Name =:requestMap.country_code limit 1];
            State__c state = [select id, name, State_Name__c from State__c Where Name =:requestMap.state limit 1];
            
            Account acc = new Account();
            
            acc.recordTypeId = personAccountRecordTypeId;
            acc.PersonTitle = (salutation.Salutation_Name__c <> null) ? salutation.Salutation_Name__c : '';
            acc.firstname = requestMap.first_name;
            acc.lastname = requestMap.last_name;
            acc.PersonEmail = requestMap.email;
            acc.PersonMobilePhone = requestMap.mobile;
            acc.PersonGenderIdentity = requestMap.gender;
            acc.PersonBirthdate = Date.valueOf(requestMap.dob);
            //acc.ClickToDial__Country_Code__c = (country.Country_Name__c <> null) ? country.Country_Name__c : '';
            //acc.ShippingAddress = requestMap.address + ', ' + requestMap.city + ', ' + state.name + ', ' + country.name + ', ' + requestMap.pincode ;
            acc.BillingCity = requestMap.city;
            acc.State__c = state.id;
            acc.Country__c = country.id;
            acc.Pin_Code__c = requestMap.pincode;
            acc.Password__c = requestMap.password;
            //acc.PersonMobilePhone = requestMap.tnc;
            //acc.PersonMobilePhone = requestMap.mkt_comm;
            
          	system.debug('acc==>'+acc);
            System.debug('======>'+	checkCustomerDuplicacy(acc.PersonEmail, null));
            if(acc != null && !checkCustomerDuplicacy(acc.PersonEmail, null)){
                insert acc;
                
                mden_responseWrapper = new MDEN_GetResponseWrapper('true', 'data found.');
                mden_responseWrapper.id = acc.id;
                system.debug('mden_responseWrapper==>'+JSON.serialize(mden_responseWrapper)); 
            }
            else if(acc != null && checkCustomerDuplicacy(acc.PersonEmail, null)){
                mden_responseWrapper = new MDEN_GetResponseWrapper('false', 'Customer Already Exists in the system with same email id.');
                system.debug('mden_responseWrapper==>'+JSON.serialize(mden_responseWrapper)); 
            }
            else{
                mden_responseWrapper = new MDEN_GetResponseWrapper('false', 'data not found.');
                system.debug('mden_responseWrapper==>'+JSON.serialize(mden_responseWrapper)); 
            }
        }catch(Exception e){
            mden_responseWrapper = new MDEN_GetResponseWrapper('false', e.getMessage());
            system.debug('mden_responseWrapper==>'+JSON.serialize(mden_responseWrapper)); 
        }
        
        return mden_responseWrapper;
    }	 
    
    global static boolean checkCustomerDuplicacy(String email, String accId){
        Account acc = new Account();
        system.debug('email==>'+email);
        system.debug('accId==>'+accId);
        
        try{
            if(accId <> null){
                acc = [Select id from Account Where PersonEmail = :email AND id != :accId];
            }else{
                acc = [Select id from Account Where PersonEmail = :email];
            }
            system.debug('acc==>'+acc	);
            if(acc <> null){
                return true;
            }else{
                return false;
            }
        }catch(Exception e){
            System.debug('Error Message : '+e.getMessage());
            return false;
        }
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
    
    global class Customer{
        global String id;
        global String title;
        global String first_name;
        global String last_name;
        global String email;
        global String mobile;
        global String gender;
        global String dob;
        global String country_code;
        global String address;
        global String city;
        global String street;
        global String state;
        global String country_id;
        global String pincode;
        global String password;
        global String tnc;
        global String mkt_comm;
    	
        global Customer() {
        }
    }
}