/* Created by 	: Maxify Development Team
 * Created Date : 14th Jan, 2025
 * Input 		: username and password
 * Purpose 		: This API class validate username and password in system and return the account information
 */
@RestResource(urlMapping = '/get_customer_login/*')
global class MDEN_GetCustomerLogin {
   
    @HttpGet
    global static MDEN_GetResponseWrapper getCustomerlogin(){
        //Initialize the response wrapper with blank status and blank message
        MDEN_GetResponseWrapper mden_responseWrapper = new MDEN_GetResponseWrapper('', '');
            
 		try{
            //Uncomment below code to test in Postman
            /*RestRequest request = RestContext.request;
            MDEN_GetRequestWrapper requestMap = (MDEN_GetRequestWrapper) JSON.deserialize(request.requestbody.toString(), MDEN_GetRequestWrapper.class);
            */
            
            //Uncomment below to call via Developer console using : MDEN_GetCustomerLogin.getCustomerlogin();
            String reqBody =' { ' +
	        	' "username": "amita.jain@encalm.com", '+
                ' "password": "1291" '+                
            ' } ';
            
			MDEN_GetRequestWrapper requestMap = (MDEN_GetRequestWrapper) JSON.deserialize(reqBody, MDEN_GetRequestWrapper.class);
                       
            system.debug('requestMap==>'+requestMap);
            //Parsing data from requestMap
            String username = requestMap.username;
            String password = requestMap.password;
			
            //Fetch the account record matching the requested username and password
            List<Account> accounts = [select id,
                                            BillingCity,
                                            BillingStreet,
                                            PersonTitle,
                                            name,
                                            firstname,
                                            lastname,
                                            PersonEmail,
                                            PersonMobilePhone,
                                            PersonGenderIdentity,
                                            PersonBirthdate,
                                            /*ClickToDial__Country_Code__c,
                                            */ State__c,
                                            State__r.name,
                                            State__r.State_Name__c,
                                            Country__c,
                                            Country__r.name,
                                            Country__r.Country_Name__c,
                                            Pin_Code__c,
                                            type,
                                            username__c,
                                            password__c 
                                      from Account 
                                      Where username__c = :username /*AND Id = '001Su00000Ez9KvIAJ' AND password__c = :password */ limit 1];
            system.debug('accounts==>'+accounts);
            
            //Null check
            if((accounts != null && !accounts.isEmpty()) && (password != null && password.trim() != '' && password == accounts[0].password__c)){
                //Initialize the wrapper with status and message
                mden_responseWrapper = new MDEN_GetResponseWrapper('true', 'data found.');
                
                //Get Salutation Information
                List<Salutation__c> salutation = new List<Salutation__c>();
                if(accounts[0].PersonTitle <> null)
                	salutation = [select id, name, Salutation_Name__c from Salutation__c Where Salutation_Name__c =:accounts[0].PersonTitle limit 1];
                
                List<CustomerWrapper> datalist = new List<CustomerWrapper>();
                CustomerWrapper customer = new CustomerWrapper();
                
                //Setting Customer Value
                customer.id = accounts[0].id;
                customer.title = (salutation <> null && !salutation.isEmpty()) ? new List<String>{salutation[0].name, salutation[0].Salutation_Name__c}: new List<String>{'', ''};
                customer.name = accounts[0].name;
                customer.first_name = accounts[0].firstname;
                customer.last_name = accounts[0].lastname;
                customer.email = accounts[0].PersonEmail;
                customer.mobile = accounts[0].PersonMobilePhone;
                customer.gender = accounts[0].PersonGenderIdentity;
                customer.dob = (accounts[0].PersonBirthdate <> null ? (DateTime.newInstance(accounts[0].PersonBirthdate.year(), accounts[0].PersonBirthdate.month(), accounts[0].PersonBirthdate.day()).format('yyyy-MM-dd')) : null);                    
                //customer.address = accounts[0].ShippingAddress;
                customer.state_id = (accounts[0].State__c <> null) ? new List<String>{accounts[0].State__r.name, accounts[0].State__r.State_name__c} : new List<String>{'', ''};
                customer.country_id = (accounts[0].Country__c <> null) ? new List<String>{accounts[0].Country__r.name, accounts[0].Country__r.Country_name__c} : new List<String>{'', ''};
                customer.zip = accounts[0].Pin_Code__c;
                customer.city = accounts[0].BillingCity;
                customer.street = accounts[0].BillingStreet;
                customer.customer_type = accounts[0].type;
                customer.parent_name = accounts[0].id;	
                system.debug('customer==>'+customer);
                datalist.add(customer);
                mden_responseWrapper.datalist = datalist;                
            }
            else if((accounts <> null && !accounts.isEmpty()) && (password != null && password.trim() != '' && password != accounts[0].password__c)){
                mden_responseWrapper = new MDEN_GetResponseWrapper('false', 'Username or password are incorrect.');
            }else if((accounts <> null && !accounts.isEmpty()) && (password != null && password.trim() == '')){
                mden_responseWrapper = new MDEN_GetResponseWrapper('false', 'Password can not be blank.');
            }else{
                mden_responseWrapper = new MDEN_GetResponseWrapper('false', 'User not found in the system.');              
            }
        }catch(Exception e){
            mden_responseWrapper = new MDEN_GetResponseWrapper('false', e.getMessage());
        }
        
		system.debug('mden_responseWrapper==>'+JSON.serialize(mden_responseWrapper)); 
        return mden_responseWrapper;
    }	     

    global class MDEN_GetRequestWrapper {
        global String username; 
        global String password;
        global MDEN_GetRequestWrapper() {
        }        
    }
    
    global class MDEN_GetResponseWrapper {
        global String status; 
        global String message;
        global List<CustomerWrapper> datalist;
        global MDEN_GetResponseWrapper(String status, String message) {
            this.status = status;
            this.message = message; 
        }        
    }
    
    global class CustomerWrapper{
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
        

        global CustomerWrapper() {
        }
    }    
}