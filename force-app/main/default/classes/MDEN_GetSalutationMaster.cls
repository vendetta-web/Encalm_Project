/* Created by 	: Maxify Development Team
 * Created Date : 14th Jan, 2025
 * Input 		: None
 * Purpose 		: This API class returns all the salutations
 */
@RestResource(urlMapping='/get_salutation/*')	
global class MDEN_GetSalutationMaster {
    //Call on Developer console using : MDEN_GetSalutationMaster.getSalutation();
	@HttpGet
    global static MDEN_GetResponseWrapper getSalutation(){
        //Initialize the response wrapper with blank status and blank message
		MDEN_GetResponseWrapper mden_responseWrapper = new MDEN_GetResponseWrapper('', '');
		
        try{
            //Fetch all the salutations
            List<Salutation__c> salutationDetails = [Select id, name, Salutation_Name__c 
                                             From Salutation__c ]; 
            
            system.debug('salutationDetails==>'+salutationDetails);
            
            //Null Check
            if(salutationDetails != null && salutationDetails.size() > 0){
                //Initialize the response wrapper with status and message
                mden_responseWrapper = new MDEN_GetResponseWrapper('true', 'data found.');
            
                List<SalutationWrapper> datalist = new List<SalutationWrapper>();
                
                for(Salutation__c sal: salutationDetails){
	            	SalutationWrapper salutation = new SalutationWrapper(sal.name, sal.Salutation_Name__c);
                    //salutation.id = sal.name;
                    //salutation.name = sal.Salutation_Name__c;
                    
                    datalist.add(salutation);
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
        global List<SalutationWrapper> datalist;
        global MDEN_GetResponseWrapper(String status, String message) {
            this.status = status;
            this.message = message; 
        }        
    }
    global class SalutationWrapper{
        global string id;
        global string name;
        
        global SalutationWrapper(string id, string name){
            this.id = id;
            this.name = name;
        }
    }
}