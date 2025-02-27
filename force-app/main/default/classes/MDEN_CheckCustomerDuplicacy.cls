/* Created by 	: Maxify Development Team
 * Created Date : 14th Jan, 2025
 * Input 		: user email id
 * Purpose 		: This API class check if user exists or not based on request user email. If user does not exist then it returns false.
 */
@RestResource(urlMapping='/get_customer_duplicacy/*')	
global class MDEN_CheckCustomerDuplicacy {
	@HttpGet
    global static MDEN_GetResponseWrapper checkCustomerDuplicacy(){
        //Initialize the response wrapper with blank status and blank message
        MDEN_GetResponseWrapper mden_responseWrapper = new MDEN_GetResponseWrapper('', ''	);
        
        try{
            //Map of salutation name as key and salutation record as value
            Map<String, Salutation__c> titleMap = new Map<String, Salutation__c>();
            //Uncomment below code to test in Postman
            RestRequest request = RestContext.request;
            MDEN_GetRequestWrapper requestMap = (MDEN_GetRequestWrapper) JSON.deserialize(request.requestBody.toString(), MDEN_GetRequestWrapper.class);
           
            //Uncomment below to call via Developer console using : MDEN_CheckCustomerDuplicacy.checkCustomerDuplicacy();
            /*String reqBody =' { ' +
	            ' "email_id": "vijay.garg@maxify.digital" '+
            ' } ';
            MDEN_GetRequestWrapper requestMap = (MDEN_GetRequestWrapper) JSON.deserialize(reqBody, MDEN_GetRequestWrapper.class);
            */
            
            
            system.debug('requestMap==>'+requestMap);
            
            if(requestMap <> null && requestMap.email_id <> null){
                List<CustomerWrapper> customerList = new List<CustomerWrapper>();
                List<Account> accounts = [Select id, 
                       		  firstname, 
                       		  lastname, 
                       		  name, 
                       		  PersonEmail, 
                       		  PersonMobilePhone,
                              PersonTitle,
                       		  PersonGenderIdentity, 
                       		  PersonBirthdate, 
                       		  /*ClickToDial__Country_Code__c, */
                       		  BillingCity, 
                       		  BillingStreet,
                       		  BillingPostalCode,
                       		  State__c,
                              State__r.name,
                              State__r.State_Name__c,
                       		  Country__c, 
                              Country__r.Country_Name__c,
                              Country__r.Country_code__c,
                              Country__r.name,
                       		  Pin_Code__c, 
                       		  Password__c,
                       	      Parent.name
                       From Account 
                       Where PersonEmail = :requestMap.email_id];
           		                
                //Get list of titles
                if(accounts <> null && !accounts.isEmpty()){
                    List<String> titleList = new List<String>();
                    
                    //List<String> countryList = new List<String>();
                    //List<String> stateList = new List<String>();
                
                    for(Account acc: accounts){
                		titleList.add(acc.PersonTitle);
                        //countryList.add(acc.Country__c);
                        //stateList.add(acc.State__c);
                    }
                    
                    List<Salutation__c> salutationList = [select name, Salutation_Name__c from Salutation__c Where Salutation_Name__c in :titleList];
                    //List<Country__c> country = [select id, name, Country_Name__c from Country__c Where Name =:requestMap.country_code limit 1];
                    //List<State__c> state = [select id, name, State_Name__c from State__c Where Name =:requestMap.state limit 1];
                    
                    for(Salutation__c salutation: salutationList){
                        titleMap.put(salutation.Salutation_Name__c, salutation);
                    }
                    
                }
                
                if(accounts <> null && !accounts.isEmpty()){
                    //Initialize the wrapper with status and message
                	mden_responseWrapper = new MDEN_GetResponseWrapper('true', 'data found.');
                	system.debug('titleMap==>'+titleMap);
                    
                    for(Account acc: accounts){
                        CustomerWrapper customer = new CustomerWrapper();
                        customer.id = acc.id;
                        customer.name = acc.name;
                        customer.first_name = acc.firstname;
                        customer.last_name = acc.lastname;
                        customer.email = acc.PersonEmail;
                        customer.mobile = acc.PersonMobilePhone;
                        customer.gender = acc.PersonGenderIdentity;
                        customer.dob = String.valueOf(acc.PersonBirthdate);
                        customer.country_id = new List<String>{acc.Country__r.name, acc.Country__r.Country_Name__c};
                        customer.parent_name = acc.Parent.name;
                        customer.title = new List<String>{(acc.PersonTitle <> null && !titleMap.isEmpty()) ? titleMap.get(acc.PersonTitle).name : '', (acc.PersonTitle <> null && !titleMap.isEmpty()) ? titleMap.get(acc.PersonTitle).Salutation_Name__c : ''};
                        customer.street2 = acc.BillingStreet;
                        customer.city = acc.BillingCity;
                        customer.state_id = new List<String>{acc.State__r.name, acc.State__r.State_Name__c};
                        customer.zip = acc.BillingPostalCode;
                        //customer.cust_type = acc.;
                        
                        customerList.add(customer);
                    }
                    
                    mden_responseWrapper.datalist = customerList;
                }else{
                    mden_responseWrapper = new MDEN_GetResponseWrapper('false', 'data not found.');
                }
                                      
            }                    			
        }catch(Exception e){
            mden_responseWrapper = new MDEN_GetResponseWrapper('false', e.getMessage());
            system.debug('mden_responseWrapper==>'+JSON.serialize(mden_responseWrapper)); 
        }
		system.debug('mden_responseWrapper==>'+JSON.serialize(mden_responseWrapper));         
        return mden_responseWrapper;
    }	     

    global class MDEN_GetRequestWrapper {
        global String email_id;
        global MDEN_GetRequestWrapper(){}        
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
        global LIst<String> title;
        global String street2;
        global String city;
        global List<String> state_id;
        global String zip;
        global String customer_type;
        
        global CustomerWrapper() {
        }
    }
}