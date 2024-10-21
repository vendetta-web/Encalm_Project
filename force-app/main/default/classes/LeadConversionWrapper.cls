global class LeadConversionWrapper {
    global String email;
    global String company ;
    global String phone;
    global String lastName;
    global String status;
    global String firstName;
    global String travelDate;
    global Integer numberofAdult;
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