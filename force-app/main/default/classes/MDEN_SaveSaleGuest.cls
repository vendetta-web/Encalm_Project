/* Created by 	: Maxify Development Team
 * Created Date : 14th Jan, 2025
 * Input 		: None
 * Purpose 		: This API class returns all the salutations
 */
@RestResource(urlMapping='/save_sale_guest/*')	
global class MDEN_SaveSaleGuest {
    @HttpPost
    global static MDEN_GetResponseWrapper saveSaleGuest(){
        //Initialize the response wrapper with blank status and blank message
        MDEN_GetResponseWrapper mden_responseWrapper = new MDEN_GetResponseWrapper('', '');
        try{
            //MDEN_SaveSaleGuest.saveSaleGuest();
            
            //Uncomment below code to test in Postman            
            RestRequest request = RestContext.request;
            MDEN_GetRequestWrapper requestMap = (MDEN_GetRequestWrapper) JSON.deserialize(request.requestBody.toString(), MDEN_GetRequestWrapper.class);
            
            //Uncomment below to call via Developer console using : MDEN_GetAirportTerminalByAirport.getAiportTerminals();
            /*
            String reqBody =' { ' +
                ' "sale_id" : "9477", '+
                ' "partner_id" : "0", '+
                ' "parent_id" : "006Su000009qUKzIAM", '+
                ' "title" : "001", '+
                ' "first_name" : "Ajit", '+
                ' "last_name" : "Kumar", '+
                ' "gender" : "male", '+
                ' "dob"	 : "1987-09-17", '+
                ' "age" : "32", '+
                ' "passport_no" : null, '+
                ' "pnr_no" : "123", '+
                ' "class_type" : "first", '+
                ' "mobile" : null, '+
                ' "country_code" : "0001" '+
                ' } ';
            
            MDEN_GetRequestWrapper requestMap = (MDEN_GetRequestWrapper) JSON.deserialize(reqBody, MDEN_GetRequestWrapper.class);
            */
            
            
            System.debug('requestMap==>'+requestMap);
            
            //Map<String, Schema.RecordTypeInfo> recordTypeInfoMap = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName();
            //String personAccountRecordTypeId = recordTypeInfoMap.get('PersonAccount').getRecordTypeId();
            List<Salutation__c> salutation = [select Salutation_Name__c from Salutation__c Where Name =:requestMap.title limit 1];
            List<Country__c> country = [select id, name, Country_Name__c from Country__c Where Name =:requestMap.country_code limit 1];
            
            Passenger_Details__c passenger = new Passenger_Details__c();
                
            if(requestMap != null )
            {
                //passenger.recordTypeId = personAccountRecordTypeId;
            	passenger.Opportunity_ID__c = requestMap.parent_id;
                passenger.Title__c  = (salutation[0].Salutation_Name__c <> null) ? salutation[0].Salutation_Name__c : '';
                passenger.First_Name__c  = requestMap.first_name;   
                passenger.Last_Name__c  = requestMap.last_name;
                passenger.Gender__c = requestMap.gender;
                Date dob = Date.valueOf(requestMap.dob);
                passenger.dob__c = (dob <> null) ? dob : null;
                passenger.Age__c = (requestMap.age <> null) ? Decimal.valueOf(requestMap.age) : null;
                passenger.Passport_No__c = requestMap.passport_no;
                passenger.Travel_PNR_No__c = requestMap.pnr_no;
                passenger.Travel_Class__c = requestMap.class_type;
                passenger.Mobile__c = requestMap.mobile;
                //passenger.country = (country[0].Country_Name__c <> null) ? country[0].Country_Name__c : '';
            }
            system.debug('passenger==>'+passenger);
            if(passenger != null){ // && !checkCustomerDuplicacy(acc.PersonEmail, null)){
            	insert passenger;    
            	mden_responseWrapper = new MDEN_GetResponseWrapper('true', 'data found.');
                mden_responseWrapper.id = passenger.id;
                system.debug('mden_responseWrapper==>'+JSON.serialize(mden_responseWrapper)); 
            }
            /*else if(passenger != null && checkCustomerDuplicacy(acc.PersonEmail, null)){
                mden_responseWrapper = new MDEN_GetResponseWrapper('false', 'Customer Already Exists in the system with same email id.');
                system.debug('mden_responseWrapper==>'+JSON.serialize(mden_responseWrapper)); 
            }*/
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
    /*
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
    */
    global class MDEN_GetResponseWrapper {
        global String status; 
        global String message;
        global String id;
        global MDEN_GetResponseWrapper(String status, String message) {
            this.status = status;
            this.message = message; 
        }        
    }
    
    global class MDEN_GetRequestWrapper{
        global String sale_id;
        global String partner_id;
        global String parent_id;
        global String title;
        global String first_name;
        global String last_name;
        global String gender;
        global String dob;
        global String age;
        global String passport_no;
        global String pnr_no;
        global String class_type;
        global String mobile;
        global String country_code;
        
        global MDEN_GetRequestWrapper() {
        }
    }
}