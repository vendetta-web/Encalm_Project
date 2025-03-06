/* Created by 	: Maxify Development Team
 * Created Date : 14th Jan, 2025
 * Input 		: None
 * Purpose 		: This API class returns all the salutations
 */
@RestResource(urlMapping='/Vesta_create_Case/*')	
global class MDEN_Vesta {
    @HttpPost
    global static String createCaseWithTask(){
        //Initialize the response wrapper with blank status and blank message
      
        try{
            //MDEN_SaveBookingCancelRequest.saveBookingCancelRequest();
            
            //Uncomment below code to test in Postman
            
            //Uncomment below code to test in Postman
            RestRequest request = RestContext.request;
            System.debug('---request----------------'+request);
            FeedbackWrapper requestMap = (FeedbackWrapper)JSON.deserialize(request.requestBody.toString(), FeedbackWrapper.class);
             System.debug('---requestMap---------21-------'+requestMap);
            if(requestMap != null){
                
           case caseRec = new case();
                caseRec.Location__c  = requestMap.location;
               // caseRec.
            }
          
           return 'Sucess';
           
        }catch(Exception e){
                   //return e.message;
            
        }
        return null;
        

    }	     
   global class FeedbackWrapper {
    global String location;
    global Decimal rating;
    global String feedback;
    global String customer_name;
    global String customer_phone;
    global String customer_email;
    global String issue;
    global String category;
    global String services;
    global String issue_date;
    global String issue_time;
    global String case_id;
    global String resolution_date;
    global String resolution_time;
    public String resolved_by;
    global String total_resolution_time;
    global String guest_satisfaction_level;
    global String resolution_comments;
    global List<ItemWrapper> items;

    
}
global class ItemWrapper {
        global String feedback_id;
        global String request_id;
        global String item_name;
    }
}