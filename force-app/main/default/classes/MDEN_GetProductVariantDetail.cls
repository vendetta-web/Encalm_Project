/* Created by 	: Maxify Development Team
 * Created Date : 14th Jan, 2025
 * Input 		: Product IdO
 * Purpose 		: This API class returns all the varint of a product family for requested product id
 */
@RestResource(urlMapping='/get_product_variant_details/*')	
global class MDEN_GetProductVariantDetail {
	@HttpPost
    global static MDEN_GetResponseWrapper getProductVariantDetails(){
        //Initialize the response wrapper with blank status and blank message
        MDEN_GetResponseWrapper mden_responseWrapper = new MDEN_GetResponseWrapper('', '');
        try{
            //Uncomment below to call via Postman
            RestRequest request = RestContext.request;
            MDEN_GetRequestWrapper requestMap = (MDEN_GetRequestWrapper) JSON.deserialize(request.requestBody.toString(), MDEN_GetRequestWrapper.class);
            system.debug('requestMap==>'+requestMap);
            //Parsing data from requestMap
            String id = (String)requestMap.id; 
			system.debug('requestMap.get==>'+requestMap.id);
            //Fetch the product variants
            List<PricebookEntry> productFamily = [select id, product2.family
                                                    From PricebookEntry 
                                                    Where product2.ProductCode = :id limit 1];
            
             List<PricebookEntry> productPrice = [select id,
                                                        Surcharge_Amount__c,
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
                                                    Where product2.family = :productFamily[0].product2.family ];
                 
            
            system.debug('productPrice==>'+productPrice);
            
            //Null Check
            if(productPrice != null && !productPrice.isEmpty()){
                mden_responseWrapper = new MDEN_GetResponseWrapper('true', 'data found.');
                List<ProductVariantDetail> datalist = new List<ProductVariantDetail>();
                for(PricebookEntry pbe: productPrice){
            		ProductVariantDetail pvd = new ProductVariantDetail();
          
                    pvd.id = pbe.product2.id;
                    pvd.name = pbe.product2.name;
                    pvd.list_price = pbe.unitPrice;
                    pvd.tax_string = '(= ₹ '+pbe.Tax_Price__c+' Incl. Taxes)';
                    pvd.tax_price = pbe.Tax_Price__c;
                    pvd.categ_id = new List<String>{pbe.product2.ProductCode, 'Welcome and Assist / '+ pbe.product2.Service_Type__c + ' / ' + pbe.product2.Sector__c};
                    pvd.description = pbe.product2.Description;
                    //pvd.surcharge_applicable_hours = Integer.valueOf(surcharge_applicable_hours);
                    //pvd.surcharge_amount = new List<String>{productPrice.Airline_Id__r.name, productPrice.Airline_Id__r.Airline_Name__c};
                    //pvd.min_lead_time_booking_hrs = productPrice.Arrival_Terminal__r.Name;
                     pvd.surcharge_amount = pbe.Surcharge_Amount__c;
                    datalist.add(pvd);
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