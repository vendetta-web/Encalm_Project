/* Created by 	: Maxify Development Team
 * Created Date : 14th Jan, 2025
 * Input 		: Service type, to  & from airport, travel date etc.
 * Purpose 		: This API class returns all the salutations
 */
@RestResource(urlMapping='/get_surcharge_product/*')	
global class MDEN_SurchargeProduct {
	@HttpPost
    global static String getFlightListForBooking(){
		
        try{
            RestRequest request = RestContext.request;            
           String reqBody =' {"airport_code" : "DEL" }';
            
            }catch(Exception e){
        }
		
		return 'HI';
    }	
    
  
    
    
    global class ResponseWrapper {
    global Boolean status;
    global String message;
    global List<DataItem> datalist;
   }
    global class DataItem {
        global Integer id;
        global String name;
        global List<Integer> product_template_variant_value_ids;
        global Decimal lst_price;
        global String tax_string;
        global String variant;
        global Decimal tax_price;
    }

  
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
     global class MDEN_GetRequestWrapper {
        global String id; 

        global MDEN_GetRequestWrapper() {
        }        
    }    
    
    global class MDEN_GetResponseWrapper {
        global String status; 
        global String message;
        global List<ProductVariantDetail> datalist;
        global MDEN_GetResponseWrapper(String status, String message) {
            this.status = status;
            this.message = message; 
        }        
    }
    
    global class ProductVariantDetail{
        global string id;
        global string name;
        global Decimal list_price;
        global string tax_string;
        global List<String> categ_id;
        global string description;
        global List<String> product_template_variant_value_ids;
        global Integer surcharge_applicable_hours;
        global Decimal surcharge_amount;
        global Integer min_lead_time_booking_hrs;
        global Integer service_delivery_time_hrs;
        global String variant;
        global Decimal tax_price;
        global Decimal lst_price_with_surcharge;
        global Decimal tax_price_with_surcharge;
        
                
        global ProductVariantDetail(){
            
        }
    }

}