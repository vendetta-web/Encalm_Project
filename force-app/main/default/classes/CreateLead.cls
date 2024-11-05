@RestResource(urlMapping='/v1/lead/*')
global class CreateLead {
    @HttpPost
    global static ResponseWrapper getRecord() {
        try{
            RestRequest request = RestContext.request;
            Map<String, Object> requestMap = (Map<String, Object>)JSON.deserializeUntyped(request.requestbody.tostring());
            if(requestMap != null && requestMap.containsKey('email') 
               && requestMap.containsKey('lastName') 
               && requestMap.containsKey('travelDate')
               && requestMap.containsKey('numberOfAdults')
               && requestMap.containsKey('company')){
                   if([SELECT count() FROM Lead WHERE Email =: String.valueOf(requestMap.get('email'))] > 0){
                       Lead ld = new Lead();
                       ld.Id = [SELECT Id FROM Lead WHERE Email =: String.valueOf(requestMap.get('email')) LIMIT 1].Id;
                       ld.LastName = (String) requestMap.get('lastName');
                       ld.FirstName = (String) (requestMap.containsKey('firstName') != null ? requestMap.get('firstName') : null);
                       ld.Email = (String) requestMap.get('email');
                       ld.Company = (String) requestMap.get('company');
                       ld.Travel_Date__c = Date.parse((String) requestMap.get('travelDate'));
                       ld.Number_of_Adult__c = (Integer) requestMap.get('numberOfAdults');
                       update ld;
                       return new ResponseWrapper(ld.Id, true, null);
                   }else{
                       Lead ld = new Lead();
                       ld.LastName = (String) requestMap.get('lastName');
                       ld.FirstName = (String) (requestMap.containsKey('firstName') != null ? requestMap.get('firstName') : null);
                       ld.Email = (String) requestMap.get('email');
                       ld.Company = (String) requestMap.get('company');
                       ld.Travel_Date__c = Date.parse((String) requestMap.get('travelDate'));
                       ld.Number_of_Adult__c = (Integer) requestMap.get('numberOfAdults');
                       insert ld;
                       return new ResponseWrapper(ld.Id, true, null);
                   }
               }
            else{
                return new ResponseWrapper(null, false, 'Required Fields Missing');
            }
        }catch(Exception e){
            return new ResponseWrapper(null, false, e.getMessage() + ' at Line: ' + e.getLineNumber());
        }
    }
    global class ResponseWrapper {
        global String id;
        global Boolean success;
        global String errorMessage;
        global ResponseWrapper(String id, Boolean success, String errorMessage){
            this.id = id;
            this.success = success;
            this.errorMessage = errorMessage;
        }
    }
}