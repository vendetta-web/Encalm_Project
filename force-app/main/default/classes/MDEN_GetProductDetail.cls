/* Created by 	: Maxify Development Team
 * Created Date : 14th Jan, 2025
 * Input 		: Product id
 * Purpose 		: This API class returns the product detail for requested product id
 */
@RestResource(urlMapping='/get_product_details/*')	
global class MDEN_GetProductDetail {
	@HttpGet
    global static MDEN_GetResponseWrapper getProductDetails(){
        //Initialize the response wrapper with blank status and blank message
        MDEN_GetResponseWrapper mden_responseWrapper = new MDEN_GetResponseWrapper('', '');
                
        try{
            //Uncomment below to call via Postman
            /*RestRequest request = RestContext.request;
            MDEN_GetRequestWrapper requestMap = (MDEN_GetRequestWrapper) JSON.deserialize(request.requestBody.toString(), MDEN_GetRequestWrapper.class);
            */
            
            //Uncomment below to call via Developer console using : MDEN_GetProductDetail.getProductDetails();
            String reqBody =' { ' +
                            ' "id" : "0"' +
            ' } ';	
            
            MDEN_GetRequestWrapper requestMap = (MDEN_GetRequestWrapper) JSON.deserialize(reqBody, MDEN_GetRequestWrapper.class);
			
            system.debug('requestMap==>'+requestMap);
            //Parsing data from requestMap
            String id = (String)requestMap.id; 
			system.debug('requestMap.get==>'+requestMap.id);
            
            //Fetch all the product details for the particular product id
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
                                                        Surcharge_Amount__c  
                                                    From PricebookEntry 
                                                    Where product2.ProductCode = :id ];
                 
            
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
                    //pdw.surcharge_applicable_hours = Integer.valueOf(surcharge_applicable_hours);
                    pdw.surcharge_amount = pbe.Surcharge_Amount__c;
                    //pdw.min_lead_time_booking_hrs = productPrice.Arrival_Terminal__r.Name;
                    
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
        global String id; 

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
        global Integer surcharge_applicable_hours;
        global Decimal surcharge_amount;
        global Integer min_lead_time_booking_hrs;
        global Integer service_delivery_time_hrs;
        //global BLOB image_1920;
        global Decimal tax_price;
                
        global ProductDetailWrapper(){
            
        }
    }
}