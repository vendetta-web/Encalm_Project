/* Created by 	: Maxify Development Team
 * Created Date : 14th Jan, 2025
 * Input 		: None
 * Purpose 		: This API class returns all the salutations
 */
@RestResource(urlMapping='/get_customer_duplicacy/*')	
global class MDEN_CheckCustomerDuplicacy {
	@HttpGet
    global static MDEN_GetResponseWrapper checkCustomerDuplicacy(){
        //Initialize the response wrapper with blank status and blank message
        MDEN_GetResponseWrapper mden_responseWrapper = new MDEN_GetResponseWrapper('', '');
        
        try{
            Map<String, Salutation__c> titleMap = new Map<String, Salutation__c>();
            
            //MDEN_RegisterCustomer.registerCustomer();
            RestRequest request = RestContext.request;
            MDEN_GetRequestWrapper requestMap = (MDEN_GetRequestWrapper) JSON.deserialize(request.requestBody.toString(), MDEN_GetRequestWrapper.class);
            
            /*String reqBody =' { ' +
	            ' "email_id": "namita.jain@encalm.com", '+
            ' } ';
            Customer requestMap = (Customer) JSON.deserialize(reqBody, Customer.class);
            */
            
            
            system.debug('requestMap==>'+requestMap);
            
            if(requestMap <> null && requestMap.email_id <> null){
                List<Customer> customerList = new List<Customer>();
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
           		                
                //Get map of titles, countries and states
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
                    mden_responseWrapper = new MDEN_GetResponseWrapper('true', 'data found.');
                	system.debug('titleMap==>'+titleMap);
                    for(Account acc: accounts){
                        Customer cust = new Customer();
                        cust.id = acc.id;
                        cust.name = acc.name;
                        cust.first_name = acc.firstname;
                        cust.last_name = acc.lastname;
                        cust.email = acc.PersonEmail;
                        cust.mobile = acc.PersonMobilePhone;
                        cust.gender = acc.PersonGenderIdentity;
                        cust.dob = String.valueOf(acc.PersonBirthdate);
                        cust.country_id = new List<String>{acc.Country__r.name, acc.Country__r.Country_Name__c};
                        cust.parent_name = acc.Parent.name;
                        cust.title = new List<String>{(acc.PersonTitle <> null && !titleMap.isEmpty()) ? titleMap.get(acc.PersonTitle).name : '', (acc.PersonTitle <> null && !titleMap.isEmpty()) ? titleMap.get(acc.PersonTitle).Salutation_Name__c : ''};
                        cust.street2 = acc.BillingStreet;
                        cust.city = acc.BillingCity;
                        cust.state_id = new List<String>{acc.State__r.name, acc.State__r.State_Name__c};
                        cust.zip = acc.BillingPostalCode;
                        //cust.cust_type = acc.;
                        
                        customerList.add(cust);
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
        
        return mden_responseWrapper;
    }	     

    global class MDEN_GetRequestWrapper {
        global String email_id;
        global MDEN_GetRequestWrapper(){}        
    }
    
    global class MDEN_GetResponseWrapper {
        global String status; 
        global String message;
        global List<Customer> datalist;
        global MDEN_GetResponseWrapper(String status, String message) {
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
        global LIst<String> title;
        global String street2;
        global String city;
        global List<String> state_id;
        global String zip;
        global String customer_type;
        
        global Customer() {
        }
    }
}