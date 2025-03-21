/* Created by 	: Maxify Development Team
 * Created Date : 14th Jan, 2025
 * Input 		: category, airport_code, travel_date, service_time, product_id etc.
 * Purpose 		: This API class returns all the product of category addOn with the filter of input parameters
 */
@RestResource(urlMapping='/get_product_addon_list/*')	
global class MDEN_GetAddonProductMaster {
	@HttpGet
    global static MDEN_GetResponseWrapper ProductDetailWrapper(){
        //Initialize the response wrapper with blank status and blank message
        MDEN_GetResponseWrapper mden_responseWrapper = new MDEN_GetResponseWrapper('', '');
                
        try{
            //Uncomment below to call via Postman
            /*RestRequest request = RestContext.request;
            MDEN_GetRequestWrapper requestMap = (MDEN_GetRequestWrapper) JSON.deserialize(request.requestbody.toString(), MDEN_GetRequestWrapper.class);
			*/
            
            //Uncomment below to call via Developer console using : MDEN_GetAddonProductMaster.ProductDetailWrapper();
            String reqBody =' { ' +
                            ' "category" : "Arrival", ' +
                            ' "sector" : "Domestic", ' +
                            ' "airport_code" : "8008", ' +
                            ' "travel_date" : "2022-07-06", ' +
                            ' "service_time" : "12:15", ' +
                            ' "basetype" : "Gold", ' +
                            ' "product_id" : "0" ' +
            ' } ';	
            
            MDEN_GetRequestWrapper requestMap = (MDEN_GetRequestWrapper) JSON.deserialize(reqBody, MDEN_GetRequestWrapper.class);
            
            system.debug('requestMap==>'+requestMap);
            
            //Parsing data from requestMap
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
            
            //Reseting the 'Add-On' value to the 'Add Ons' as it is the correct product category value for Add Ons under product table
            if(basetype == 'Add-On'){
                basetype = 'Add Ons';
            }
             List<PricebookEntry> productPrice = [select id,
                                                        product2.name,
                                                        product2.id,
                                                        unitPrice,
                                                        product2.ProductCode,
                                                        product2.family,
                                                        Tax_Price__c,
                                                        product2.Description,
                                                        product2.Service_Type__c,
                                                        product2.Sector__c,
                                                        product2.Is_Available__c  
                                                    From PricebookEntry 
                                                    Where product2.Service_Type__c = :category AND 
                                              			  product2.Sector__c = :sector AND
                                             			  product2.ProductCode = :product_id AND
                                                 		  product2.Family = :basetype];
                 
            
            system.debug('productPrice==>'+productPrice);
            
            //Null check
            if(productPrice != null && !productPrice.isEmpty()){
                //Initialize the wrapper with status and message
                mden_responseWrapper = new MDEN_GetResponseWrapper('true', 'data found.');
                
                List<ProductDetailWrapper> datalist = new List<ProductDetailWrapper>();
                
                for(PricebookEntry pbe: productPrice){
            		ProductDetailWrapper pdw = new ProductDetailWrapper();
          
                    pdw.id = pbe.product2.id;
                    pdw.name = pbe.product2.name;
                    pdw.list_price = pbe.unitPrice;
                    pdw.tax_string = '(= ₹ '+pbe.Tax_Price__c+' Incl. Taxes)';
                    pdw.tax_price = pbe.Tax_Price__c;
                    pdw.categ_id = new List<String>{pbe.product2.ProductCode, 'Welcome and Assist / '+ pbe.product2.Service_Type__c + ' / ' + pbe.product2.Sector__c};
                    pdw.description = pbe.product2.Description;
                    
                    datalist.add(pdw);
                }
            
                mden_responseWrapper.datalist = datalist;
            }
            else{
                mden_responseWrapper = new MDEN_GetResponseWrapper('false', 'data not found.');
            }
            system.debug('mden_responseWrapper==>'+JSON.serialize(mden_responseWrapper));   
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
        global List<ProductDetailWrapper> datalist;
        global MDEN_GetResponseWrapper(String status, String message) {
            this.status = status;
            this.message = message; 
        }        
    }
    
    global class ProductDetailWrapper{
        global string id;
        global string name;
        global Decimal list_price;
        global string tax_string;
        global List<String> categ_id;
        global string description;
        //global BLOB image_1920;
        global Decimal tax_price;
                
        global ProductDetailWrapper(){
            
        }
    }
}