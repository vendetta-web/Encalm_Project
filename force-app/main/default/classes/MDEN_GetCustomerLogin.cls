/* Created by 	: Maxify Development Team
 * Created Date : 14th Jan, 2025
 * Input 		: None
 * Purpose 		: This API class returns all the salutations
 */
@RestResource(urlMapping = '/get_customer_login/*')
global class MDEN_GetCustomerLogin {
   
    @HttpGet
    global static MDEN_GetResponseWrapperWithData getCustomerlogin(){
        MDEN_GetResponseWrapperWithData mden_responseWrapper = new MDEN_GetResponseWrapperWithData('', '');
            
 		try{
            RestRequest request = RestContext.request;
            Map<String, Object> requestMap = (Map<String, Object>) JSON.deserializeUntyped(request.requestbody.toString());
            
            /*
            String reqBody =' { ' +
	        	' "username": "amita.jain@encalm.com", '+
                ' "password": "1291" '+                
            ' } ';
            
            Map<String, Object> requestMap = (Map<String, Object>) JSON.deserializeUntyped(reqBody);
            */
            
            String username = (String)requestMap.get('username');
            String password = (String)requestMap.get('password');

            system.debug('requestMap==>'+requestMap.get('password'));
            system.debug('requestMap==>'+requestMap.get('username'));

            Account acc = [select id, BillingCity, BillingStreet, PersonTitle, name, firstname, lastname, PersonEmail, PersonMobilePhone, PersonGenderIdentity, PersonBirthdate, /*ClickToDial__Country_Code__c,*/ State__c, State__r.name, State__r.State_Name__c, Country__c, Country__r.name, Country__r.Country_Name__c, Pin_Code__c, type, username__c, password__c from Account Where username__c = :username AND Id = '001Su00000Ez9KvIAJ' /* AND password__c = :password*/ limit 1];
            system.debug('acc==>'+acc);
            system.debug('acc.password__c==>'+acc.password__c);
            system.debug('PersonTitle==>'+acc.PersonTitle);
            if(acc != null && (password != null && password.trim() != '' && password == acc.password__c)){
                mden_responseWrapper = new MDEN_GetResponseWrapperWithData('true', 'data found.');
                List<Customer> datalist = new List<Customer>();
                Customer data = new Customer();
                
                //Get Salutation Information
                Salutation__c salutation = new Salutation__c();
                if(acc.PersonTitle <> null)
                	salutation = [select id, name, Salutation_Name__c from Salutation__c Where Salutation_Name__c =:acc.PersonTitle limit 1];
                system.debug('salutation==>'+salutation);
                system.debug('acc.PersonBirthdate.year()==>'+acc.PersonBirthdate.year());
                system.debug('salutation==>'+acc.PersonBirthdate.month());
                system.debug('salutation==>'+acc.PersonBirthdate.day());
                            	
                data.id = acc.id;
                data.title = (salutation <> null) ? new List<String>{salutation.name, salutation.Salutation_Name__c}: new List<String>{};
                data.name = acc.name;
                data.first_name = acc.firstname;
                data.last_name = acc.lastname;
                data.email = acc.PersonEmail;
                data.mobile = acc.PersonMobilePhone;
                data.gender = acc.PersonGenderIdentity;
                data.dob = (acc.PersonBirthdate <> null ? (DateTime.newInstance(acc.PersonBirthdate.year(), acc.PersonBirthdate.month(), acc.PersonBirthdate.day()).format('yyyy-MM-dd')) : null);                    
                //data.address = acc.ShippingAddress;
                data.state_id = (acc.State__c <> null) ? new List<String>{acc.State__r.name, acc.State__r.State_name__c} : new List<String>{};
                data.country_id = (acc.Country__c <> null) ? new List<String>{acc.Country__r.name, acc.Country__r.Country_name__c} : new List<String>{};
                data.zip = acc.Pin_Code__c;
                data.city = acc.BillingCity;
                data.street = acc.BillingStreet;
                data.customer_type = acc.type;
                data.parent_name = acc.id;	
                system.debug('data==>'+data);
                datalist.add(data);
                mden_responseWrapper.datalist = datalist;
                system.debug('mden_responseWrapper==>'+JSON.serialize(mden_responseWrapper)); 
            }
            else if(acc != null && (password != null && password.trim() != '' && password != acc.password__c)){
                mden_responseWrapper = new MDEN_GetResponseWrapperWithData('false', 'Username or password are incorrect.');
                system.debug('mden_responseWrapper==>'+JSON.serialize(mden_responseWrapper)); 
            }else if(acc != null && (password != null && password.trim() == '')){
                mden_responseWrapper = new MDEN_GetResponseWrapperWithData('false', 'Password can not be blank.');
                system.debug('mden_responseWrapper==>'+JSON.serialize(mden_responseWrapper)); 
            }else{
                mden_responseWrapper = new MDEN_GetResponseWrapperWithData('false', 'User not found in the system.');
                system.debug('mden_responseWrapper==>'+JSON.serialize(mden_responseWrapper)); 
            }
        }catch(Exception e){
            mden_responseWrapper = new MDEN_GetResponseWrapperWithData('false', e.getMessage());
            system.debug('mden_responseWrapper==>'+JSON.serialize(mden_responseWrapper));             
        }
        
         String jsonString = JSON.serialize(mden_responseWrapper);
         system.debug('jsonString==>'+jsonString); 
        return mden_responseWrapper;
    }	     

    global class MDEN_GetResponseWrapperWithData {
        global String status; 
        global String message;
        global List<Customer> datalist;
        global MDEN_GetResponseWrapperWithData(String status, String message) {
            this.status = status;
            this.message = message; 
        }        
    }
    
    global class Customer{
        global String id;
        global String name;
        global String first_name;
        global String last_name;
        global String email;
        global String mobile;
        global String gender;
        global String dob;
        global List<String> country_id;
        global String parent_name;
        global List<String> title;
        global String street;
        global String city;
        global List<String> state_id;
        global String zip;
        global String customer_type;
        

        global Customer() {
        }
    }    
}