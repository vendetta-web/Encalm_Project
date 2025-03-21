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
                caseRec.Location__c  = requestMap.location;
                caseRec.Services__c = requestMap.services;
                caseRec.Rating__c = requestMap.rating;
                caseRec.Issue__c = requestMap.issue;
                caseRec.Issue_Time__c = getTime(requestMap.issue_time);
                caseRec.Feedback__c	 = requestMap.feedback;
                caseRec.Category__c = requestMap.category;
                caseRec.Issue_Date__c = requestMap.issue_date;
                caseRec.Resolution_Time__c =  getTime(requestMap.resolution_time);// convertedTime;//Time.valueOf(requestMap.resolution_time); //Time.(timeStr)
                caseRec.Total_Resolution_Time__c = requestMap.total_resolution_time;
                caseRec.Guest_Satisfaction_Level__c = requestMap.guest_satisfaction_level;
                caseRec.Resolution_Comments__c  = requestMap.resolution_comments;
                caseRec.Resolved_By__c  = requestMap.resolved_by;
                insert caseRec;
                List<Item__c> itemList = new List<Item__c>();
                if(caseRec != null){
                    caseInfo = caseRec.Id;
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
            // mden_responseWrapper = new MDEN_GetResponseWrapper('false', 'data not found.');
            return response    = new GetResponseWrapper(caseInfo); //'Case created sucessful'+' '+caseInfo  ;
        }catch(Exception e){
            return response = new GetResponseWrapper(e.getMessage());          
        }
        
    }	


  global class GetResponseWrapper {
        global String Id; 
       global GetResponseWrapper(String Id) {
            this.Id = Id;
            
        }        
    }    global static Time getTime(String timeStr){
        List<String> timeParts = timeStr.split(' ');
        String timeValue = timeParts[0]; // "02:00"
        String amPm = timeParts[1]; // "PM"
        
        // Extract hours and minutes
        List<String> hmParts = timeValue.split(':');
        Integer hours = Integer.valueOf(hmParts[0]);
        Integer minutes = Integer.valueOf(hmParts[1]);
        
        // Convert to 24-hour format
        if (amPm == 'PM' && hours != 12) {
            hours += 12; // Convert PM hours (except 12 PM)
        } else if (amPm == 'AM' && hours == 12) {
            hours = 0; // Convert 12 AM to 00 hours
        }
        
        // Create Time object
        Time convertedTime = Time.newInstance(hours, minutes, 0, 0);
        
        System.debug('Converted Time: ' + convertedTime);
        return convertedTime;
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
        global List<ItemWrapper> items;
    }
    global class ItemWrapper {
        global String feedback_id;
        global String request_id;
        global String item_name;
        
    }
}