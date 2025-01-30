/* Created by 	: Maxify Development Team
 * Created Date : 14th Jan, 2025
 * Input 		: None
 * Purpose 		: This API class returns all the salutations
 */
@RestResource(urlMapping='/get_product_details/*')	
global class MDEN_GetProductDetail {
	@HttpGet
    global static MDEN_GetResponseWrapper getProductDetails(){
        //Initialize the response wrapper with blank status and blank message
        MDEN_GetResponseWrapper mden_responseWrapper = new MDEN_GetResponseWrapper('', '');
                
        try{
            RestRequest request = RestContext.request;
            MDEN_GetRequestWrapper requestMap = (MDEN_GetRequestWrapper) JSON.deserialize(request.requestBody.toString(), MDEN_GetRequestWrapper.class);
            
            /*String reqBody =' { ' +
                            ' "id" : "0"' +
            ' } ';	
            
            MDEN_GetRequestWrapper requestMap = (MDEN_GetRequestWrapper) JSON.deserialize(reqBody, MDEN_GetRequestWrapper.class);
			*/
            system.debug('requestMap==>'+requestMap);
            String id = (String)requestMap.id; 
			system.debug('requestMap.get==>'+requestMap.id);
            
            system.debug('id==>'+id);
            
             List<PricebookEntry> productPrice = [select id, product2.name, product2.id, unitPrice, product2.ProductCode, product2.family, Tax_Price__c, product2.Description, product2.Service_Type__c, product2.Sector__c, product2.Is_Available__c, Surcharge_Amount__c  
                                                    From PricebookEntry 
                                                    Where product2.ProductCode = :id ];
                 
            
            system.debug('productPrice==>'+productPrice);
            
            if(productPrice != null){
                mden_responseWrapper = new MDEN_GetResponseWrapper('true', 'data found.');
                List<get_product_details> datalist = new List<get_product_details>();
                for(PricebookEntry pbe: productPrice){
            		//mden_responseWrapper.status = "true";
                    //mden_responseWrapper.message = "data found.";
                    get_product_details gpwa = new get_product_details();
          
                    gpwa.id = pbe.product2.id;
                    gpwa.name = pbe.product2.name;
                    gpwa.list_price = pbe.unitPrice;
                    gpwa.tax_string = '(= ₹ '+pbe.Tax_Price__c+' Incl. Taxes)';
                    gpwa.tax_price = pbe.Tax_Price__c;
                    gpwa.categ_id = new List<String>{pbe.product2.ProductCode, 'Welcome and Assist / '+ pbe.product2.Service_Type__c + ' / ' + pbe.product2.Sector__c};
                    gpwa.description = pbe.product2.Description;
                    //gpwa.surcharge_applicable_hours = Integer.valueOf(surcharge_applicable_hours);
                    gpwa.surcharge_amount = pbe.Surcharge_Amount__c;
                    //gpwa.min_lead_time_booking_hrs = productPrice.Arrival_Terminal__r.Name;
                    
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
        global String id; 

        global MDEN_GetRequestWrapper() {
        }        
    }    
    
    global class MDEN_GetResponseWrapper {
        global String status; 
        global String message;
        global List<get_product_details> datalist;
        global MDEN_GetResponseWrapper(String status, String message) {
            this.status = status;
            this.message = message; 
        }        
    }
    
    global class get_product_details{
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
                
        global get_product_details(){
            
        }
    }
}