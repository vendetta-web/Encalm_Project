/* Created by 	: Maxify Development Team
 * Created Date : 14th Jan, 2025
 * Input 		: None
 * Purpose 		: This API class returns all the salutations
 */
@RestResource(urlMapping='/get_product_addon_list/*')	
global class MDEN_GetAddonProductMaster {
	@HttpGet
    global static MDEN_GetResponseWrapper getProductAddonList(){
        //Initialize the response wrapper with blank status and blank message
        MDEN_GetResponseWrapper mden_responseWrapper = new MDEN_GetResponseWrapper('', '');
                
        try{
            RestRequest request = RestContext.request;
            MDEN_GetRequestWrapper requestMap = (MDEN_GetRequestWrapper) JSON.deserialize(request.requestbody.toString(), MDEN_GetRequestWrapper.class);
            
            /*String reqBody =' { ' +
                            ' "category" : "Arrival", ' +
                            ' "sector" : "Domestic", ' +
                            ' "airport_code" : "8008", ' +
                            ' "travel_date" : "2022-07-06", ' +
                            ' "service_time" : "12:15", ' +
                            ' "basetype" : "Gold", ' +
                            ' "product_id" : "0" ' +
            ' } ';	
            
            MDEN_GetRequestWrapper requestMap = (MDEN_GetRequestWrapper) JSON.deserialize(reqBody, MDEN_GetRequestWrapper.class);
            */
            system.debug('requestMap==>'+requestMap);
              
            system.debug('requestMap.get==>'+requestMap.travel_date);
            
            String category = (String)requestMap.category; 
			String sector = (String)requestMap.sector;  
            String airport_code = (String)requestMap.airport_code;  
            Date travel_date = Date.valueOf(String.valueOf(requestMap.travel_date));
            String service_time = (String)requestMap.service_time; 
            String basetype = (String)requestMap.basetype;
            String product_id = (String)requestMap.product_id;  
            
            system.debug('category==>'+category);
            system.debug('sector==>'+sector);
            system.debug('airport_code==>'+airport_code);
            system.debug('travel_date==>'+travel_date);
            
            if(basetype == 'Add-On'){
                basetype = 'Add Ons';
            }
             List<PricebookEntry> productPrice = [select id, product2.name, product2.id, unitPrice, product2.ProductCode, product2.family, Tax_Price__c, product2.Description, product2.Service_Type__c, product2.Sector__c, product2.Is_Available__c  
                                                    From PricebookEntry 
                                                    Where product2.Service_Type__c = :category AND 
                                              			  product2.Sector__c = :sector AND
                                             			  product2.ProductCode = :product_id AND
                                                 		  product2.Family = :basetype];
                 
            
            system.debug('productPrice==>'+productPrice);
            
            if(productPrice != null){
                mden_responseWrapper = new MDEN_GetResponseWrapper('true', 'data found.');
                List<getProductAddonList> datalist = new List<getProductAddonList>();
                for(PricebookEntry pbe: productPrice){
            		getProductAddonList gpwa = new getProductAddonList();
          
                    gpwa.id = pbe.product2.id;
                    gpwa.name = pbe.product2.name;
                    gpwa.list_price = pbe.unitPrice;
                    gpwa.tax_string = '(= ₹ '+pbe.Tax_Price__c+' Incl. Taxes)';
                    gpwa.tax_price = pbe.Tax_Price__c;
                    gpwa.categ_id = new List<String>{pbe.product2.ProductCode, 'Welcome and Assist / '+ pbe.product2.Service_Type__c + ' / ' + pbe.product2.Sector__c};
                    gpwa.description = pbe.product2.Description;
                    
                    datalist.add(gpwa);
                }
            
                mden_responseWrapper.datalist = datalist;
                //gtba.id = terminal.name;
                //gtba.name = terminal.Airport__r.name;
                //gtba.value = terminal.name;
                //gtba.code = terminal.Code__c;
                String jsonString = JSON.serialize(mden_responseWrapper);
                system.debug('mden_responseWrapper==>'+jsonString);
            }
            else{
                mden_responseWrapper = new MDEN_GetResponseWrapper('false', 'data not found.');
            }
        }catch(Exception e){
            mden_responseWrapper = new MDEN_GetResponseWrapper('false', e.getMessage());
        }
    
    	return mden_responseWrapper;
    }	
    
    global class MDEN_GetRequestWrapper {
        global String category; 
        global String sector;
        global String airport_code; 
        global String travel_date;
        global String service_time;
        global String basetype;
        global String product_id;
        global Integer no_of_adult;
        global Integer no_of_children;
        global Integer no_of_infants;

        global MDEN_GetRequestWrapper() {
        }        
    }    
    
    global class MDEN_GetResponseWrapper {
        global String status; 
        global String message;
        global List<getProductAddonList> datalist;
        global MDEN_GetResponseWrapper(String status, String message) {
            this.status = status;
            this.message = message; 
        }        
    }
    
    global class getProductAddonList{
        global string id;
        global string name;
        global Decimal list_price;
        global string tax_string;
        global List<String> categ_id;
        global string description;
        //global BLOB image_1920;
        global Decimal tax_price;
                
        global getProductAddonList(){
            
        }
    }
}