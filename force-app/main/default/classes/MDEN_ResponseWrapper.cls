global class MDEN_ResponseWrapper {
    
    global Boolean success; 
    global String message; 
    global Id leadId;
     public String id;
    global String email;
    global String company ;
    global String phone;
    global String lastName;
    global String status;
    global String firstName;
    global String travelDate;
    global Integer numberofAdult;
    global String airlinePNR;
    public MDEN_ResponseWrapper(String id, Boolean success, String message) {
        this.id = id;
        this.success = success;
        this.message = message;
    }
    global List<AddOnServices> addOnServices;
    global List<PassengerDetails> passengerDetails;  
    global class AddOnServices {
       global String Name;
        global String addOnServiceQty;
        global String leadID;
        global String addOnService;
    }
    global class PassengerDetails {
        global String  name;
        global String firstName;
        global String lastName;
        global String age;
        global String numberofAdult;
        global String numberofChildren;
        global String numberofInfants;
        global String gender;
        global String contactNumber;
        global String emailId;
        global String lead;
        global String opportunity;
        global String airlinePNR;
    }
}