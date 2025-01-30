/* Created by 	: Maxify Development Team
 * Created Date : 14th Jan, 2025
 * Input 		: None
 * Purpose 		: This API class returns all the Countries
 */
@RestResource(urlMapping='/get_country/*')	
global class MDEN_GetCountryMaster {
    //Call on Developer console using : MDEN_GetCountryMaster.getCountry();
	@HttpGet
    global static MDEN_GetResponseWrapper getCountry(){
        //Initialize the response wrapper with blank status and blank message
		MDEN_GetResponseWrapper mden_responseWrapper = new MDEN_GetResponseWrapper('', '');
		
        try{
            //Fetch all the countries
            List<Country__c> countryDetails = [Select id, name, Country_Name__c, Phone_Code__c 
                                             From Country__c ]; 
            
            system.debug('countryDetails==>'+countryDetails);
            
            //Null Check
            if(countryDetails != null && countryDetails.size() > 0){
                mden_responseWrapper = new MDEN_GetResponseWrapper('true', 'data found.');
            
                List<CountryWrapper> datalist = new List<CountryWrapper>();
                
                //Considering that arrival and departure airport can not be same
                for(Country__c con: countryDetails){
	            	CountryWrapper country = new CountryWrapper(con.name, con.Country_Name__c, con.Phone_Code__c);
                    datalist.add(country);
                }
                
                system.debug('datalist==>'+datalist);
                    
                mden_responseWrapper.datalist = datalist;
                system.debug('mden_responseWrapper==>'+JSON.serialize(mden_responseWrapper));
            }
            else{
                mden_responseWrapper = new MDEN_GetResponseWrapper('false', 'data not found.');
            }
        }catch(Exception e){
            mden_responseWrapper = new MDEN_GetResponseWrapper('false', e.getMessage());
        }
		
		return mden_responseWrapper;
    }	
  
    global class MDEN_GetResponseWrapper {
        global String status; 
        global String message;
        global List<CountryWrapper> datalist;
        global MDEN_GetResponseWrapper(String status, String message) {
            this.status = status;
            this.message = message; 
        }        
    }
    global class CountryWrapper{
        global string id;
        global string name;
        global String phone_code;
        
        global CountryWrapper(string id, string name, string phone_code){
            this.id = id;
            this.name = name;
            this.phone_code = phone_code;
        }
    }
}