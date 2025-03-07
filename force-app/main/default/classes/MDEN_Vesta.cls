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
            RestRequest request = RestContext.request;
            System.debug('---request----------------'+request);
            FeedbackWrapper requestMap = (FeedbackWrapper)JSON.deserialize(request.requestBody.toString(), FeedbackWrapper.class);
            System.debug('---requestMap---------21-------'+requestMap);
            if(requestMap != null){
                List<Account> accList = [SELECT Id FROM Account WHERE PersonEmail =: requestMap.customer_email AND Phone = :requestMap.customer_phone AND Name =: requestMap.customer_name  ];
                case caseRec = new case();
                caseRec.Location__c  = requestMap.location;
                caseRec.Services__c = requestMap.services;
                insert caseRec;
                List<Item__c> itemList = new List<Item__c>();
                if(caseRec != null){
                    for(ItemWrapper item: requestMap.items){
                        Item__c itemRec = new  Item__c();
                        itemRec.Name = item.item_name ;
                        itemRec.Feedback_Id__c = item.feedback_id ;
                        itemRec.Request_Id__c = item.request_id;
                        itemRec.Case__c =  caseRec.Id;
                        itemList.add(itemRec);
                    }
                    
                    if(!itemList.isEmpty()){
                        insert itemList;
                        system.debug('----itemList-----------------'+itemList);
                    }
                }
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