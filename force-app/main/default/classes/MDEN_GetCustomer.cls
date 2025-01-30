/* Created by 	: Maxify Development Team
 * Created Date : 14th Jan, 2025
 * Input 		: None
 * Purpose 		: This API class returns all the salutations
 */
@RestResource(urlMapping='/get_customer_details/*')	
global class MDEN_GetCustomer {
	@HttpGet
    global static MDEN_GetResponseWrapperWithData getCustomer(){
        MDEN_GetResponseWrapperWithData mden_responseWrapper = new MDEN_GetResponseWrapperWithData('', '');
        
        try{
            RestRequest request = RestContext.request;
            String reqBody =' { ' +
	        	' "id": "001Su00000Ez9KvIAJ" '+
                ' } ';
            
            Map<String, Object> requestMap = (Map<String, Object>) JSON.deserializeUntyped(reqBody);
            system.debug('requestMap==>'+requestMap.get('id'));
            String uId = (String)requestMap.get('id');
                         
            Account acc = [select id, PersonTitle, name, firstname, lastname, PersonEmail, PersonMobilePhone, PersonGenderIdentity, PersonBirthdate, /*ClickToDial__Country_Code__c,*/ State__r.name, State__r.State_Name__c, Country__r.name, Country__r.Country_Name__c, Pin_Code__c, type, BillingCity, BillingStreet from Account Where id =:uId limit 1];
            system.debug('acc==>'+acc);
            if(acc != null){
                Salutation__c salutation = new Salutation__c();
                if(acc.PersonTitle <> null)
                	salutation = [select id, name, Salutation_Name__c from Salutation__c Where Salutation_Name__c =:acc.PersonTitle limit 1];
                
            	mden_responseWrapper = new MDEN_GetResponseWrapperWithData('true', 'data found.');
                Customer2 datalist = new Customer2();
                
                datalist.id = acc.id;
                datalist.title = (salutation <> null) ? new List<String>{salutation.name, salutation.Salutation_Name__c}: new List<String>{};
                datalist.name = acc.name;
                datalist.first_name = acc.firstname;
                datalist.last_name = acc.lastname;
                datalist.email = acc.PersonEmail;
                datalist.mobile = acc.PersonMobilePhone;
                datalist.gender = acc.PersonGenderIdentity;
                datalist.dob = (acc.PersonBirthdate <> null ? (DateTime.newInstance(acc.PersonBirthdate.year(), acc.PersonBirthdate.month(), acc.PersonBirthdate.day()).format('yyyy-MM-dd')) : null);                    
                //datalist.address = acc.ShippingAddress;
                datalist.state_id = (acc.State__c <> null) ? new List<String>{acc.State__r.name, acc.State__r.State_name__c} : new List<String>{};
                datalist.country_id = (acc.Country__c <> null) ? new List<String>{acc.Country__r.name, acc.Country__r.Country_name__c} : new List<String>{};
                datalist.zip = acc.Pin_Code__c;
                datalist.city = acc.BillingCity;
                datalist.street = acc.BillingStreet;
                datalist.customer_type = acc.type;
                datalist.parent_name = acc.id;
                
                mden_responseWrapper.datalist = datalist;
                system.debug('mden_responseWrapper==>'+JSON.serialize(mden_responseWrapper)); 
            }
            else{
                mden_responseWrapper = new MDEN_GetResponseWrapperWithData('false', 'data not found.');
                system.debug('mden_responseWrapper==>'+JSON.serialize(mden_responseWrapper)); 
            }
        }catch(Exception e){
            mden_responseWrapper = new MDEN_GetResponseWrapperWithData('false', e.getMessage());
            system.debug('mden_responseWrapper==>'+JSON.serialize(mden_responseWrapper)); 
        }
        
        return mden_responseWrapper;
    }	 
    
    global class MDEN_GetResponseWrapperWithData {
        global String status; 
        global String message;
        global Customer2 datalist;
        global MDEN_GetResponseWrapperWithData(String status, String message) {
            this.status = status;
            this.message = message; 
        }        
    }
    
    global class Customer2{
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
        

        global Customer2() {
        }
    }        
}