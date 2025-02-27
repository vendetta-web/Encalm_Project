/* Created by 	: Maxify Development Team
 * Created Date : 14th Jan, 2025
 * Input 		: User Id
 * Purpose 		: This API class returns the user details based on requested user id
 */
@RestResource(urlMapping='/get_customer_details/*')	
global class MDEN_GetCustomer {
	@HttpGet
    global static MDEN_GetResponseWrapperWithData getCustomer(){
        //Initialize the response wrapper with blank status and blank message
        MDEN_GetResponseWrapperWithData mden_responseWrapper = new MDEN_GetResponseWrapperWithData('', '');
        
        try{
            //Uncomment below code to test in Postman
           RestRequest request = RestContext.request;
            Map<String, Object> requestMap = (Map<String, Object>) JSON.deserializeUntyped(request.requestBody.toString());
           
            //Uncomment below to call via Developer console using : MDEN_GetCustomer.getCustomer();
            /*String reqBody =' { ' +
	        	' "id": "001H30000082myoIAA" '+
                ' } '/
            Map<String, Object> requestMap = (Map<String, Object>) JSON.deserializeUntyped(reqBody);*/
            
            system.debug('requestMap==>'+requestMap.get('id'));
            //Parsing data from requestMap
            String uId = (String)requestMap.get('id');
            
            //Fetch account details based on user id
            List<Account> accounts = [select id,
                                            PersonTitle,
                                            name,
                                            firstname,
                                            lastname,
                                            PersonEmail,
                                            PersonMobilePhone,
                                            PersonGenderIdentity,
                                            PersonBirthdate,
                                            /*ClickToDial__Country_Code__c,
                                            */ State__r.name,
                                            State__r.State_Name__c,
                                            Country__r.name,
                                            Country__r.Country_Name__c,
                                            Pin_Code__c,
                                            type,
                                            BillingCity,
                                            BillingStreet 
                                      from Account 
                                      Where id =:uId limit 1];
            system.debug('acc==>'+accounts);
            
            //Null Check
            if(accounts != null && !accounts.isEmpty()){
                //Initialize the wrapper with status and message 
            	mden_responseWrapper = new MDEN_GetResponseWrapperWithData('true', 'data found.');
                
                //Fetch Salutation related information
                List<Salutation__c> salutation = new List<Salutation__c>();
               
                if(accounts[0].PersonTitle <> null)
                	salutation = [select id, name, Salutation_Name__c from Salutation__c Where Salutation_Name__c =:accounts[0].PersonTitle limit 1];
                
                CustomerWrapper datalist = new CustomerWrapper();
                
                datalist.id = accounts[0].id;
                datalist.title = (salutation <> null && !salutation.isEmpty()) ? new List<String>{salutation[0].name, salutation[0].Salutation_Name__c}: new List<String>{'', ''};
                datalist.name = accounts[0].name;
                datalist.first_name = accounts[0].firstname;
                datalist.last_name = accounts[0].lastname;
                datalist.email = accounts[0].PersonEmail;
                datalist.mobile = accounts[0].PersonMobilePhone;
                datalist.gender = accounts[0].PersonGenderIdentity;
                datalist.dob = (accounts[0].PersonBirthdate <> null ? (DateTime.newInstance(accounts[0].PersonBirthdate.year(), accounts[0].PersonBirthdate.month(), accounts[0].PersonBirthdate.day()).format('yyyy-MM-dd')) : null);                    
                //datalist.address = accounts[0].ShippingAddress;
                datalist.state_id = (accounts[0].State__c <> null) ? new List<String>{accounts[0].State__r.name, accounts[0].State__r.State_name__c} : new List<String>{};
                datalist.country_id = (accounts[0].Country__c <> null) ? new List<String>{accounts[0].Country__r.name, accounts[0].Country__r.Country_name__c} : new List<String>{};
                datalist.zip = accounts[0].Pin_Code__c;
                datalist.city = accounts[0].BillingCity;
                datalist.street = accounts[0].BillingStreet;
                datalist.customer_type = accounts[0].type;
                datalist.parent_name = accounts[0].id;
                
                mden_responseWrapper.datalist = datalist;
            }
            else{
                mden_responseWrapper = new MDEN_GetResponseWrapperWithData('false', 'data not found.');
            }
        }catch(Exception e){
            mden_responseWrapper = new MDEN_GetResponseWrapperWithData('false', e.getMessage());
        }
		system.debug('mden_responseWrapper==>'+JSON.serialize(mden_responseWrapper));         
        return mden_responseWrapper;
    }	 
    
    global class MDEN_GetResponseWrapperWithData {
        global String status; 
        global String message;
        global CustomerWrapper datalist;
        global MDEN_GetResponseWrapperWithData(String status, String message) {
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