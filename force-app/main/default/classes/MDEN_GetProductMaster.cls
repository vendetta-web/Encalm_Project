/* Created by 	: Maxify Development Team
 * Created Date : 14th Jan, 2025
 * Input 		: category, airport_code, travel_date, service_time, product_id, no_of_adult etc.
 * Purpose 		: This API class returns if the product is available or not based on different input parameters
 */
@RestResource(urlMapping='/get_product_with_availablity/*')	
global class MDEN_GetProductMaster {
	@HttpGet
    global static MDEN_GetResponseWrapper getProductWithAvailablity(){
        //Initialize the response wrapper with blank status and blank message
        MDEN_GetResponseWrapper mden_responseWrapper = new MDEN_GetResponseWrapper('', '');
                
        try{
            //Uncomment below to call via Postman
            /*RestRequest request = RestContext.request;
            MDEN_GetRequestWrapper requestMap = (MDEN_GetRequestWrapper) JSON.deserialize(request.requestbody.toString(), MDEN_GetRequestWrapper.class);
            */
            
            //Uncomment below to call via Developer console using : MDEN_GetProductMaster.getProductWithAvailablity();
            String reqBody =' { ' +
                            ' "category" : "Arrival", ' +
                            ' "sector" : "Domestic", ' +
                            ' "airport_code" : "8008", ' +
                            ' "travel_date" : "2022-07-06", ' +
                            ' "service_time" : "12:15", ' +
                            ' "basetype" : "Primary", ' +
                            ' "product_id" : "0", ' +
                            ' "no_of_adult" : "2", ' +
                            ' "no_of_children" : "1", ' +
                            ' "no_of_infants" : "0"' +
            ' } ';	
            MDEN_GetRequestWrapper requestMap = (MDEN_GetRequestWrapper) JSON.deserialize(reqBody, MDEN_GetRequestWrapper.class);
			
            system.debug('requestMap==>'+requestMap);
            //Parsing data from requestMap
            String category = (String)requestMap.category; 
			String sector = (String)requestMap.sector;  
            String airport_code = (String)requestMap.airport_code;  
            Date travel_date = Date.valueOf(String.valueOf(requestMap.travel_date));  
            String product_id = (String)requestMap.product_id;  
            system.debug('requestMap.get==>'+requestMap.travel_date);
            
            system.debug('category==>'+category);
            system.debug('sector==>'+sector);
            system.debug('airport_code==>'+airport_code);
            system.debug('product_id==>'+product_id);
            system.debug('travel_date==>'+travel_date);
            
            //Fetch Products based on filter of input parameters
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
                                                        product2.Is_Available__c,
                                                        product2.isActive,
                                                        Surcharge_Amount__c  
                                                    From PricebookEntry 
                                                    Where product2.Service_Type__c = :category AND 
                                              			  product2.Sector__c = :sector AND
                                             			  product2.ProductCode = :product_id ];
                 
            
            system.debug('productPrice==>'+productPrice);
            
            //Null check
            if(productPrice != null && !productPrice.isEmpty()){
                //Initialize the wrapper with status and message
                mden_responseWrapper = new MDEN_GetResponseWrapper('true', 'data found.');
                
                List<productAvailabilityWrapper> datalist = new List<productAvailabilityWrapper>();
                for(PricebookEntry pbe: productPrice){
            		//mden_responseWrapper.status = "true";
                    //mden_responseWrapper.message = "data found.";
                    productAvailabilityWrapper paw = new productAvailabilityWrapper();
          
                    paw.id = pbe.product2.id;
                    paw.name = pbe.product2.name;
                    paw.list_price = pbe.unitPrice;
                    paw.tax_string = '(= ₹ '+pbe.Tax_Price__c+' Incl. Taxes)';
                    paw.tax_price = pbe.Tax_Price__c;
                    paw.categ_id = new List<String>{pbe.product2.ProductCode, 'Welcome and Assist / '+ pbe.product2.Service_Type__c + ' / ' + pbe.product2.Sector__c};
                    paw.description = pbe.product2.Description;
                    //paw.surcharge_applicable_hours = Integer.valueOf(surcharge_applicable_hours);
                    paw.surcharge_amount = pbe.Surcharge_Amount__c;
                    //paw.min_lead_time_booking_hrs = productPrice.Arrival_Terminal__r.Name;
                    //paw.available = pbe.product2.Is_Available__c;
                    paw.available = pbe.product2.isActive;
                    
                    datalist.add(paw);
                }
            
                mden_responseWrapper.datalist = datalist;
                //gtba.id = terminal.name;
                //gtba.name = terminal.Airport__r.name;
                //gtba.value = terminal.name;
                //gtba.code = terminal.Code__c;
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
        global List<productAvailabilityWrapper> datalist;
        global MDEN_GetResponseWrapper(String status, String message) {
            this.status = status;
            this.message = message; 
        }        
    }
    
    global class productAvailabilityWrapper{
        global string id;
        global string name;
        global Decimal list_price;
        global string tax_string;
        global List<String> categ_id;
        global string description;
        global Integer surcharge_applicable_hours;
        global Decimal surcharge_amount;
        global Integer min_lead_time_booking_hrs;
        global Integer service_delivery_time_hrs;
        //global BLOB image_1920;
        global Decimal tax_price;
        global Boolean available;
        global Boolean surcharge;
                
        global productAvailabilityWrapper(){
            
        }
    }
}