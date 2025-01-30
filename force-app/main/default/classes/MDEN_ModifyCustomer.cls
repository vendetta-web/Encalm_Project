/* Created by 	: Maxify Development Team
 * Created Date : 14th Jan, 2025
 * Input 		: None
 * Purpose 		: This API class returns all the salutations
 */
@RestResource(urlMapping='/modify_customer/*')	
global class MDEN_ModifyCustomer {
	
    @HttpPost
    global static MDEN_GetResponseWrapper updateCustomer(){
        //Initialize the response wrapper with blank status and blank message
        MDEN_GetResponseWrapper mden_responseWrapper = new MDEN_GetResponseWrapper('', '');
        
        try{
            RestRequest request = RestContext.request;
            Customer requestMap = (Customer) JSON.deserialize(request.RequestBody.toString(), Customer.class);
            
            /*String reqBody =' { ' +
	        	' "id": "001Su00000Ez9KvIAJ", '+
                ' "title": "001", '+
                ' "first_name": "Namita", '+
                ' "last_name": "Jain", '+
                ' "email": "namita.jain@encalm.com", '+
                ' "mobile": "8888889998", '+
                ' "gender": "female", '+
                ' "dob": "1995-08-01", '+
                ' "country_code": "0001", '+
                ' "address": "Test Address", ' +
                ' "city": "gurugram", '+
                ' "state": "000002", '+
                ' "country_id": "104", '+
                ' "pincode": "122001 " '+
            ' } ';
            */
            
            //Customer requestMap = (Customer) JSON.deserialize(reqBody, Customer.class);
            system.debug('requestMap==>'+requestMap);
            //addrss addressMap = (addrss) JSON.deserialize(requestMap.address.toString(), addrss.class);
            
            system.debug('requestMap==>'+requestMap.title);
            
            Salutation__c salutation = [select Salutation_Name__c from Salutation__c Where Name =:requestMap.title limit 1];
            Country__c country = [select id, name, Country_Name__c from Country__c Where Name =:requestMap.country_code limit 1];
            State__c state = [select id, name, State_Name__c from State__c Where Name =:requestMap.state limit 1];
            Account acc = [select id, PersonTitle, firstname, lastname, PersonEmail, PersonMobilePhone, PersonGenderIdentity, PersonBirthdate, /*ClickToDial__Country_Code__c,*/ State__c, Country__c, Pin_Code__c, Password__c, BillingCity from Account Where id =:requestMap.id limit 1];
            system.debug('acc==>'+acc);
            if(acc != null){
                acc.PersonTitle = (salutation.Salutation_Name__c <> null) ? salutation.Salutation_Name__c : '';
                acc.firstname = requestMap.first_name;
                acc.lastname = requestMap.last_name;
                acc.PersonEmail = requestMap.email;
                system.debug('requestMap.mobile==>'+requestMap.mobile);
                acc.PersonMobilePhone = requestMap.mobile;
                acc.PersonGenderIdentity = requestMap.gender;
                acc.PersonBirthdate = Date.valueOf(requestMap.dob);
                //acc.ClickToDial__Country_Code__c = (country.Country_Name__c <> null) ? country.Country_Name__c : '';
                acc.BillingCity = requestMap.city;
                //acc.ShippingAddress = requestMap.address ;
				acc.State__c = state.id;
                acc.Country__c = country.id;
                acc.Pin_Code__c = requestMap.pincode;
                
                system.debug('acc==>'+acc);
                system.debug('MDEN_RegisterCustomer.checkCustomerDuplicacy(acc.PersonEmail, requestMap.id)==>'+MDEN_RegisterCustomer.checkCustomerDuplicacy(acc.PersonEmail, requestMap.id));
                if(!MDEN_RegisterCustomer.checkCustomerDuplicacy(acc.PersonEmail, requestMap.id)){
                    update acc;
                    mden_responseWrapper = new MDEN_GetResponseWrapper('true', 'data updated.');
                    mden_responseWrapper.id = 'true';
                    system.debug('mden_responseWrapper==>'+JSON.serialize(mden_responseWrapper)); 
                }else{
                    mden_responseWrapper = new MDEN_GetResponseWrapper('false', 'Customer Already Exists in the system with same email id.');
                    mden_responseWrapper.id = 'false';
                    system.debug('mden_responseWrapper==>'+JSON.serialize(mden_responseWrapper)); 
                }
            
                String response = JSON.serialize(mden_responseWrapper);
            	   system.debug('----response----'+response);
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
        //global addrss address;
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
    
    /*global class addrss{
        global String city;
        global String country;
        global String geocodeAccuracy;
        global String latitude;
        global String longitude;
        global String postalCode;
        global String state;
        global String street;
        
        global addrss() {
        }
    }  */  
}