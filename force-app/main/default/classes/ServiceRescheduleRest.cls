@RestResource(urlMapping='/serviceReschedule')
global with sharing class ServiceRescheduleRest {

    @HttpPost
    global static void  handleReschedule() {
        try {
            RestRequest req = RestContext.request;
            String reqBody = req.requestBody.toString();
            System.debug('--- Raw Request Body ---\n' + reqBody);

            RequestWrapper inputData = (RequestWrapper) JSON.deserialize(reqBody, RequestWrapper.class);
            System.debug('--- Deserialized inputData --- ' + inputData);
            System.debug('--- Booking__c: ' + inputData.booking);

            Map<String, Object> inputMap = new Map<String, Object>();
            inputMap.put('Arrival_Service_Time__c', inputData.arrivalServiceTime);
            inputMap.put('Booking__c', inputData.booking);
            inputMap.put('Change_Type__c', inputData.changeType);
            inputMap.put('Date_of_Arrival__c', inputData.dateOfArrival);
            inputMap.put('Flight_Number_Arrival__c', inputData.flightNumberArrival);
            inputMap.put('Service_Type__c', inputData.serviceType);
            inputMap.put('Status__c', inputData.status);

            if (inputData.serializedData != null) {
                Map<String, Object> serializedDataMap = new Map<String, Object>();
                serializedDataMap.put('Date_of_Arrival__c', inputData.serializedData.dateOfArrival);
                serializedDataMap.put('STA_Time__c', inputData.serializedData.staTime);
                serializedDataMap.put('Arrival_Service_Time__c', inputData.serializedData.arrivalServiceTime);
                serializedDataMap.put('Arriving_Flight_Schedule__c', inputData.serializedData.arrivingFlightSchedule);
                serializedDataMap.put('Flight_Number_Arrival__c', inputData.serializedData.flightNumberArrival);
                serializedDataMap.put('Number_of_Rescheduling_Done__c', inputData.serializedData.numberOfReschedulingDone);
                inputMap.put('Serialized_Data__c', serializedDataMap);
            }

            String bookingId = inputData.booking;
            if (String.isBlank(bookingId)) {
                throw new AuraHandledException('Booking__c (Opportunity Id) is required.');
            }

           
             System.debug('----------------inputMap---------------------'+inputMap);
            RescheduleBooking.ReschedulingDetailsWrapper result = RescheduleBooking.showReschedulingCharges(bookingId, true, inputMap);
             
            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(result));
            //RestContext.response.responseBody = Blob.valueOf(JSON.serialize(result));

        } catch (Exception ex) {
            System.debug('--- ERROR --- ' + ex.getMessage());
            RestContext.response.statusCode = 500;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(
                new Map<String, String>{ 'error' => ex.getMessage() }
            ));
        }
    }

    // === Request Wrapper ===
    global class RequestWrapper {
        public String arrivalServiceTime;
        public String booking;
        public String changeType;
        public String dateOfArrival;
        public String flightNumberArrival;
        public SerializedData serializedData;
        public String serviceType;
        public String status;
    }

    // === Nested Wrapper ===
    global class SerializedData {
        public String dateOfArrival;
        public String staTime;
        public String arrivalServiceTime;
        public String arrivingFlightSchedule;
        public String flightNumberArrival;
        public Integer numberOfReschedulingDone;
    }

}