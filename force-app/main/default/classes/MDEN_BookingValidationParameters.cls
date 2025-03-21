/* Created by 	: Maxify Development Team
 * Created Date : 18th March, 2025
 * Input 		: None
 * Purpose 		: This API class returns all the salutations
 */
@RestResource(urlMapping='/get_booking_validation_parameters/*')	
global class MDEN_BookingValidationParameters {
    @HttpPost
    global static ResponseWrapper getBookingValidationParameters() {
             RestRequest request = RestContext.request;
            MDEN_GetRequestWrapper requestMap = (MDEN_GetRequestWrapper) JSON.deserialize(request.requestBody.toString(), MDEN_GetRequestWrapper.class);
            system.debug('requestMap==>'+requestMap);
        // Initialize response wrapper
        // String id = (String)requestMap.key; 
			system.debug('requestMap.get==>'+requestMap.key);
        ResponseWrapper response = new ResponseWrapper();
        response.status = false;  // Default status
        response.message = 'No data found.';
        response.datalist = new DataList();

        try {
            // Query custom metadata (Flight_Info__mdt)
            Booking_Validation_Parameters__mdt flightInfo = [SELECT Key__c,
                Dep_Dom_Service_Time__c, 
                Dep_Int_Service_Time__c, 
                Booking_Threshold_Hr__c, 
                Transit_Min_Flight_Gap_Hr__c, 
                Transit_Max_Flight_Gap_Hr__c
                FROM Booking_Validation_Parameters__mdt WHERE Key__c =: requestMap.key LIMIT 1];

            if (flightInfo != null) {
                response.status = true;
                response.message = 'Data found.';
                response.datalist = new DataList();
                
                // Mapping metadata values to wrapper fields
                response.datalist.Dep_Dom_Service_Time = flightInfo.Dep_Dom_Service_Time__c;
                response.datalist.Dep_Int_Service_Time = flightInfo.Dep_Int_Service_Time__c;
                response.datalist.Booking_Threshold_Hr = flightInfo.Booking_Threshold_Hr__c;
                response.datalist.Transit_Min_Flight_Gap_Hr =flightInfo.Transit_Min_Flight_Gap_Hr__c;
                response.datalist.Transit_Max_Flight_Gap_Hr = flightInfo.Transit_Max_Flight_Gap_Hr__c;
            }
        } catch (Exception e) {
            response.status = false;
            response.message = 'Error: ' + e.getMessage();
        }

        // Return JSON response
        System.debug('response======'+JSON.serialize(response));
        return response;
    }
    global class MDEN_GetRequestWrapper {
        global String key; 

        global MDEN_GetRequestWrapper() {
        }        
    } 
    // Response Wrapper Class
    global class ResponseWrapper {
        global Boolean status;
        global String message;
        global DataList datalist;
    }

    // Data List Wrapper Class
    global class DataList {
        global String Dep_Dom_Service_Time;
        global String Dep_Int_Service_Time;
        global String Booking_Threshold_Hr;
        global String Transit_Min_Flight_Gap_Hr;
        global String Transit_Max_Flight_Gap_Hr;
    }
    
}