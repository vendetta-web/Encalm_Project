/* Created by 	: Maxify Development Team
* Created Date : 14th Jan, 2025
* Input 		: None
* Purpose 		: This API class returns all the salutations
*/
@RestResource(urlMapping='/Vesta_create_Case/*')	
global class MDEN_Vesta {
    @HttpPost
    global static GetResponseWrapper createCaseWithTask(){
        GetResponseWrapper response = new GetResponseWrapper('');
        try{
            String caseInfo;
            RestRequest request = RestContext.request;
            System.debug('---request----------------'+request);
            FeedbackWrapper requestMap = (FeedbackWrapper)JSON.deserialize(request.requestBody.toString(), FeedbackWrapper.class);
            System.debug('---requestMap---------21-------'+requestMap);
            if(requestMap != null){
                List<Account> accList = [SELECT Id FROM Account WHERE PersonEmail =: requestMap.customer_email AND Phone = :requestMap.customer_phone AND Name =: requestMap.customer_name  ];
                case caseRec = new case();
                caseRec.Origin = 'Vesta';
                caseRec.Status = 'New';
                if( requestMap.feedback_id != null &&  requestMap.item_name != null && requestMap.resolution_date != null && requestMap.request_id != null){
                    caseRec.Status = 'Closed';
                     caseRec.Resolution_Date__c = requestMap.resolution_date ;
                     caseRec.Resolution_Time__c =  requestMap.resolution_time;// convertedTime;//Time.valueOf(requestMap.resolution_time); //Time.(timeStr)
                     caseRec.Resolved_By__c  = requestMap.resolved_by;
                    caseRec.Total_Resolution_Time__c = requestMap.total_resolution_time;
                    caseRec.Resolution_Comments__c  = requestMap.resolution_comments;
                    caseRec.Feedback_ID__c = requestMap.feedback_id;
                   
                  
                }else{
                      caseRec.Location_Vesta__c  = requestMap.location;
                caseRec.Services_Vesta__c = requestMap.services;
                caseRec.Rating__c = requestMap.rating;
                caseRec.Issue__c = requestMap.issue;
                caseRec.Issue_Time__c = requestMap.issue_time;
                caseRec.Feedback__c	 = requestMap.feedback;
                caseRec.Category__c = requestMap.category;
                caseRec.Issue_Date__c = requestMap.issue_date;
                caseRec.Guest_Satisfaction_Level__c = requestMap.guest_satisfaction_level;
                caseRec.Feedback_ID__c = requestMap.feedback_id; 
                }
             
                upsert caseRec Feedback_ID__c ;
                caseInfo = caseRec.Id;
                system.debug('-----caseRec.Id-------------'+caseRec.Id);
                List<Item__c> itemList = new List<Item__c>();
                if(caseRec != null && requestMap.request_id != null && requestMap.item_name != null){
                    caseInfo = caseRec.Id;
                    Item__c itemRec = new  Item__c();
                    itemRec.Name = requestMap.item_name;
                    itemRec.Feedback_Id__c = requestMap.feedback_id ;
                    itemRec.Request_Id__c = requestMap.request_id;
                    itemRec.Case__c =  caseRec.Id;
                    
                    if(itemRec != null)
                    { 
                        insert  itemRec;  
                        System.debug('-----------itemRec-------'+itemRec.Id);
                    }
                    
                }
            }
            
            return response    = new GetResponseWrapper(caseInfo); 
        }catch(Exception e){
            System.debug('----error line-------------'+e.getLineNumber());
            return response = new GetResponseWrapper(e.getMessage());
            
        }
        
    }	
    global class GetResponseWrapper {
        global String Id; 
        global GetResponseWrapper(String Id) {
            this.Id = Id;
            
        }        
    }    
    global class FeedbackWrapper {
        global String location;
        global String rating;
        global String feedback;
        global String customer_name;
        global String customer_phone;
        global String customer_email;
        global String issue;
        global String category;
        global String services;
        global Date issue_date;
        global String issue_time;
        global String case_id;
        global Date resolution_date;
        global String resolution_time;
        public String resolved_by;
        global String total_resolution_time;
        global String guest_satisfaction_level;
        global String resolution_comments;
        global String feedback_id;
        global String request_id;
        global String item_name;
        
    }
    
}