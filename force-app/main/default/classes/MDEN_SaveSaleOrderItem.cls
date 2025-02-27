/* Created by 	: Maxify Development Team
 * Created Date : 14th Jan, 2025
 * Input 		: None
 * Purpose 		: This API class returns all the salutations
 */
@RestResource(urlMapping='/save_sale_order_item/*')	
global class MDEN_SaveSaleOrderItem {
    @HttpPost
    global static MDEN_GetResponseWrapper saveSaleOrderItem (){
        MDEN_GetResponseWrapper mden_responseWrapper = new MDEN_GetResponseWrapper('', '','');
        try{
            
            //Uncomment below code to test in Postman
            RestRequest request = RestContext.request;
            OrderItem requestMap = (OrderItem)JSON.deserialize(request.requestBody.toString(), OrderItem.class);
            
                    /*
        String s = '{' +
        '	"order_id": "006Su00000AQldRIAT",' +
        '	"product_id": "01tSu000005wKl3IAE",' +
        '	"name": "SILVER(INT-ARR)(Adult)",' +
        '	"product_uom_qty": 6,' +
        '	"price_unit": 2881.36,' +
        '	"price_subtotal": 2881.36' +
        '} ' ; 
        
        OrderItem requestMap = (OrderItem)JSON.deserialize(s, OrderItem.class);
        */
                    
                    
            OpportunityLineItem opLItem = new OpportunityLineItem();
            opLItem.OpportunityId = requestMap.order_id;
            opLItem.Product2Id = requestMap.product_id;
            opLItem.Quantity    = requestMap.product_uom_qty ;
            opLItem.UnitPrice    = requestMap.price_unit ;
            opLItem.Source__c = requestMap.source;
            // opLItem.Subtotal    = requestMap.price_subtotal ;
            //opLItem.PricebookEntryId = '01uSu0000013DzRIAU';
            system.debug('Order=order_id=>'+requestMap.order_id);
            insert opLItem;
            mden_responseWrapper = new MDEN_GetResponseWrapper('true', 'data found.', opLItem.Id);
            system.debug('opLItem=>'+opLItem);
            
        			system.debug('mden_responseWrapper==>'+JSON.serialize(mden_responseWrapper)); 
        }catch(Exception e){
            mden_responseWrapper = new MDEN_GetResponseWrapper('false', 'data not found.','Id');
            System.debug('Line--->'+e.getLineNumber());
        }
        return mden_responseWrapper;
    }
    
    global class MDEN_GetResponseWrapper{
        global String status;
        global String message; 
        global String id; 
        
        global MDEN_GetResponseWrapper(String status, String message, String Id){
            this.status = status;
            this.message = message; 
            this.Id = Id; 
        }   
    } 
    global class OrderItem{
        global String order_id;
        global String product_id;
        global String name;
        global Decimal product_uom_qty;
        global Decimal price_unit;
        global String price_subtotal;
        global String source;
        global OrderItem() {
        }   
    }
}