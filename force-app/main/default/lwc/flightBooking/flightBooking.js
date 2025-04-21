import { LightningElement , wire , track, api} from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAirportDetails from '@salesforce/apex/Encalm_BookingEngine.getAirportDetails';
import getFlightDetails from '@salesforce/apex/Encalm_BookingEngine.getFlightDetails';
import getAirport from '@salesforce/apex/Flight_Booking_encalm.getAirport';
import getTransitFlightDetails from '@salesforce/apex/Encalm_BookingEngine.getTransitFlightDetails';
import processBooking from '@salesforce/apex/LeadConversionController.processBooking';
import getFlightInfo from '@salesforce/apex/Flight_Booking_encalm.getFlightInfo';
import createOpportunity from '@salesforce/apex/Flight_Booking_encalm.createOpportunity';
// Define the fields for both Lead and Case (AccountId and Account Name)
const LEAD_FIELDS = ['Lead.ConvertedAccountId', 'Lead.ConvertedAccount.Name', 'Lead.IsConverted', 'Lead.Account__c', 'Lead.Account__r.Name'];
const CASE_FIELDS = ['Case.AccountId', 'Case.Account.Name'];

export default class FlightBooking extends NavigationMixin(LightningElement) {
    @api recordId;
    isLoading = false;
    accountId='';
    selectedAccount;
    todayDate= new Date().toISOString().split('T')[0];
 airportOptions = [];
 flightNumbers = [];
 baseAirportOptions;
 flightNumberOptions;
 flightNumberOptionsArrival;
 flightNumberOptionsDeparture;
 allAirportOptions;
 allAirportOptionsDepTo;
 allAirportOptionsArrFrom;
 flightSchedule=[];
 allAirportIds=[];
 countryMap = new Map();
 flightStaMap = new Map();
 flightDtaMap = new Map();
 arrivalFlighId;
 departureFlightId;
 @track opportunityFieldValues = {};
 myMap = new Map();
@track adultCount = 1;
@track childCount = 0;
@track infantCount = 0;
errorMessage ='';
errorMessageDep='';
errorMessageArr='';
transitVia;
arrivingFrom;
showOtherDropdown = false;
showServiceDropdown = false;
showFlightNumber = false;
showTransitDepDropdown = false;
showTransitArrDropdown = false;
showFlightNumberArrival = false;
showFlightNumberDepart = false;
@track filteredOtherOptions = [];
@track filteredServiceOptions = [];
@track filteredFlightOptions = [];
@track filteredAirportOptionsArrFrom = [];
@track filteredAirportOptionsDepTo = [];
@track filteredFlightNumberOptionsArrival = [];
@track filteredFlightNumberOptionsDeparture = [];
sectorOption = [
    {label : 'Domestic', value : 'Domestic'},
    {label: 'International', value : 'International'},
    {label: 'Domestic to International', value : 'Domestic to International'},
    {label: 'Domestic to Domestic', value : 'Domestic to Domestic'},
    {label: 'International to Domestic', value : 'International to Domestic'},
    {label: 'International to International', value : 'International to International'},
]   

    // Use wire to get the record dynamically based on the record type (Lead or Case)
    @wire(getRecord, { recordId: '$recordId', fields: '$fields' })
    record({ error, data }) {
        if (data) {
            let accountId = null;
            let accountName = null;

            // Handle Lead object
            if (this.recordId && this.recordId.startsWith('00Q')) { // Check if it’s a Lead record (Leads start with '00Q')
                const isConverted = data.fields.IsConverted.value;

                // If the Lead is converted, use the ConvertedAccountId and ConvertedAccount
                if (isConverted) {
                    accountId = data.fields.ConvertedAccountId ? data.fields.ConvertedAccountId.value : null;
                    accountName = data.fields.ConvertedAccount && data.fields.ConvertedAccount.displayValue
                        ? data.fields.ConvertedAccount.displayValue
                        : null;
                }
                // If the Lead is not converted, use the Account__c lookup field
                else {
                    accountId = data.fields.Account__c ? data.fields.Account__c.value : null;
                    accountName = data.fields.Account__r && data.fields.Account__r.displayValue
                        ? data.fields.Account__r.displayValue
                        : null ; // Use fallback value if Account__r.Name is not available
                }
            }

            // Handle Case object
            if (this.recordId && this.recordId.startsWith('500')) { // Check if it’s a Case record (Cases start with '500')
                accountId = data.fields.AccountId ? data.fields.AccountId.value : null;
                // Ensure Account is not undefined before accessing Name
                accountName = data.fields.Account && data.fields.Account.displayValue 
                                ? data.fields.Account.displayValue 
                                : null;
            }

            // If AccountId and AccountName are available, create the selectedAccount object
            if (accountId && accountName) {
                this.selectedAccount = { Id: accountId, Name: accountName };
                this.accountId = this.selectedAccount.Id ? this.selectedAccount.Id : '';
            } else {
                this.selectedAccount = null;
            }
        } else if (error) {
            console.error('Error fetching record data:', error);
        }
    }

    // Dynamically assign the fields based on whether the record is Lead or Case
    get fields() {
        return this.recordId && this.recordId.startsWith('00Q') // If it's a Lead (Lead records have a '00Q' prefix)
            ? LEAD_FIELDS
            : CASE_FIELDS; // If it's a Case
    }


  @wire(getAirport)
    wiredLocations({ error, data }) {
   
    console.log('value of result = ' ,    this.airportOptions );
        if (data) {
         console.log('-----data---12---',data);
            console.log('-----------',data);
            this.airportOptions = data.map(element => ({
                label: element.Departure_Airport__c,
                value: element.Departure_Airport__c
            }));
        } else if (error) {
            console.error(error);
        }
    }

    @wire(getAirportDetails, {})
    // Define a wired property for Airport picklist values
    wiredAirportPicklistValues({ error, data }) {
        // If data is returned from the wire function
        if (data) {
            // Map the data to an array of base airport options
            this.baseAirportOptions = data.baseAirportPicklist.map(option => {
                return {
                    label: option.label,
                    value: option.value
                };
            });
            // Map the data to an array of all airport options
            this.allAirportOptions = this.allAirportOptionsArrFrom = this.allAirportOptionsDepTo = data.allAirportPicklist.map(option => {
                return {
                    label: option.label,
                    value: option.value
                };
            });
            this.allAirportIds = data.allAirportPicklist;
            this.countryMap = new Map(Object.entries(data.airportToCountryMap));
        }
        // If there is an error
        else if (error) {
            // Log the error to the console
            console.error(error);
            console.log('error');
        }
    }

    loadFlightData(flightDate,firstAirport,secondAirport) {
        this.resetFlightDetails();
        getFlightDetails({flightDate: flightDate, departAirport: firstAirport, arrivalAirport: secondAirport})
        .then((result) => {
            this.flightNumberOptions = result.flightPicklist.map(option => {
            return {
                label: option.label,
                value: option.value
                };
            }); 
            this.flightSchedule = result.flightPicklist;
            this.flightStaMap = new Map(Object.entries(result.flightNumberToStaMap));
            this.flightDtaMap = new Map(Object.entries(result.flightNumberToDtaMap));
            
        })
        .catch((error) => {
            console.error(error);
        });
    }

    loadTransitFlightData(flightDate,firstAirport,secondAirport) {
        var tempFlightNumberOptions;
        getTransitFlightDetails({flightDate: flightDate, departAirport: firstAirport, arrivalAirport: secondAirport, transitAirport:this.transitAirport})
        .then((result) => {
            tempFlightNumberOptions = result.flightPicklist.map(option => {
            return {
                label: option.label,
                value: option.value
                };
            });  
            if (secondAirport == '') {
                this.flightNumberOptionsArrival = tempFlightNumberOptions;
                this.flightStaMap = new Map(Object.entries(result.flightNumberToStaMap));
            } else if (firstAirport == '') {
                this.flightNumberOptionsDeparture = tempFlightNumberOptions;
                this.flightDtaMap = new Map(Object.entries(result.flightNumberToDtaMap));
            }
            this.flightSchedule = result.flightPicklist;
            
        })
        .catch((error) => {
            console.error(error);
        });
    }


qtyVal = 0;
    //activeTab ;
    isTabOne = true;
    isTabTwo = false;
    isTabThree = false;

    // Flight details fields
    arrivingAirport = '';
    arrivingAirportLabel = '';
    departureAirport = '';
    departureAirportLabel = '';
    transitAirport = '';
    transitAirportLabel='';
    arrivalDate ;
    departureDate;
    flightNumber = '';
    flightNumberArrival='';
    flightNumberDeparture='';
    staTime = '';
    stdTime = '';
    depServiceTime='';
    serviceTime = '';
    @track sector='';

    // Passenger details fields for Tab 2
    firstName = '';
    lastName = '';
    phone = '';
    dateOfBirth = '';

    // Passenger details fields for Tab 3 (multiple passengers)
    firstName1 = '';
    lastName1 = '';
    phone1 = '';
    dateOfBirth1 = '';

    firstName2 = '';
    lastName2 = '';
    phone2 = '';
    dateOfBirth2 = '';

handleNewLead() {
        // Navigate to the 'New Lead' record page
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Lead', // Specify the object
                actionName: 'new' // Action to create a new record
            }
        });
    }



    incrementAdult() {
        this.adultCount += 1;
    }

    decrementAdult() {
        if (this.adultCount > 1) {
            this.adultCount -= 1;
        }
    }

    incrementChild() {
        this.childCount += 1;
    }

    decrementChild() {
        if (this.childCount > 0) {
            this.childCount -= 1;
        }
    }

    incrementInfant() {
        this.infantCount += 1;
    }

    decrementInfant() {
        if (this.infantCount > 0) {
            this.infantCount -= 1;
        }
    }

handleTabChange(event) {
        if(event.target.value == 'Arrival'){
             this.isTabOne = true;
              this.isTabTwo = false;
               this.isTabThree  = false;
               this.opportunityFieldValues['Service_Type__c'] = 'Arrival';
               this.resetOnTabChange();
        } if(event.target.value== 'Departure'){
            this.isTabOne = false;
              this.isTabTwo = true;
               this.isTabThree  = false;
               this.opportunityFieldValues['Service_Type__c'] = 'Departure';
               this.resetOnTabChange();
        }
        if(event.target.value== 'Transit'){
            this.isTabOne = false;
              this.isTabTwo = false;
               this.isTabThree  = true;
               this.opportunityFieldValues['Service_Type__c'] = 'Transit';
               this.resetOnTabChange();
        }
    }

   handleArrivalDateChange(event) { 
       this.arrivalDate = event.target.value;
       event.target.blur();
       if(this.isTabOne){
            this.loadFlightData(this.arrivalDate, this.departureAirport, this.arrivingAirport);
        }
    }
    handleDepartureDateChange(event){
        this.departureDate = event.target.value;
        event.target.blur();
        if(this.isTabTwo){
            this.loadFlightData(this.departureDate, this.arrivingAirport, this.departureAirport);
        }
    }

    handleFlightNumberChange(event) { 
        //logic for search key in picklist for flight number
        const searchKey = event.target.value.toLowerCase();
        this.filteredFlightOptions = this.flightNumberOptions.filter(option =>
            option.label.toLowerCase().includes(searchKey)
        );
        this.showFlightNumber = this.flightNumberOptions.length > 0;

        // Validate if the entered value matches one of the picklist options
        const isValid = this.filteredFlightOptions.some(option => option.value === this.flightNumber);

        if (!isValid) {
            this.errorMessage = 'Please select a valid value from the picklist.';
        } else {
            this.errorMessage = ''; // Clear error if valid
        }
    }

    handleFlightOptionSelect(event) {
        const selectedValue = event.currentTarget.getAttribute('data-value');
        this.showFlightNumber = false;
        this.flightNumber = selectedValue;        
        if(this.isTabOne){
            this.setStaTime();
            this.opportunityFieldValues['Arriving_Flight_Schedule__c']=this.getFlightId(this.flightNumber);
        }else if(this.isTabTwo) {
            this.setStdTime();
            this.opportunityFieldValues['Departure_Flight_Schedule__c']=this.getFlightId(this.flightNumber);
        }
        this.errorMessage = '';
    }

    handleArrivalFlightOptionSelect(event) {
        const selectedValue = event.currentTarget.getAttribute('data-value');
        this.showFlightNumberArrival = false;
        this.flightNumberArrival = selectedValue;
        this.setStaTime();
        this.opportunityFieldValues['Arriving_Flight_Schedule__c'] = this.getFlightId(this.flightNumberArrival);
        this.errorMessageArr = '';
    }

    handleDepartureFlightOptionSelect(event) {
        const selectedValue = event.currentTarget.getAttribute('data-value');
        this.showFlightNumberDepart = false;
        this.flightNumberDeparture = selectedValue;
        this.setStdTime();
        this.opportunityFieldValues['Departure_Flight_Schedule__c'] = this.getFlightId(this.flightNumberDeparture);
        this.errorMessageDep='';
    }

    // Method to retrieve flight ID based on flight number
    getFlightId(flightNumber) {
        // Iterate through the flightPicklist
        let flightScheduleId = null;
        this.flightSchedule.forEach(item => {
        if (item.value == flightNumber) {
                // Extract the record ID associated with "flight number"
                flightScheduleId= item[flightNumber];
            }
        });
        return flightScheduleId;
    }

    // Method to retrieve Airport Id based on Airport code
    getAirportId(airportCode) {
        // Iterate through the airports
        let airportId = null;
        this.allAirportIds.forEach(item => {
        if (item.value == airportCode) {
                // Extract the record ID associated with "airport code"
                airportId= item[airportCode];
            }
        });
        return airportId;
    }
    
    formatTime(milliseconds,hrs,mns) {
        const adjustedMillis = milliseconds - (hrs * 3600000) - (mns * 60000);
        const date = new Date(adjustedMillis);
        const hours = String(date.getUTCHours()).padStart(2, '0');
        const minutes = String(date.getUTCMinutes()).padStart(2, '0');
        return `${hours}:${minutes}`; // Format as HH:MM
    }

    // Subtract Departure time based on sector
    adjustServiceTime() {
        const [hours, minutes] = this.stdTime.split(':').map(Number);
        const originalMillis = (hours * 3600000) + (minutes * 60000);
        let adjustedMillis;

        if (this.sector === 'Domestic') {
            // Subtract 1 hour and 30 minutes for Domestic
            adjustedMillis = originalMillis - (1 * 3600000) - (30 * 60000);
        } else if (this.sector === 'International') {
            // Subtract 3 hours for International
            adjustedMillis = originalMillis - (3 * 3600000);
        } else {
            // Default case: No adjustment
            adjustedMillis = originalMillis;
        }

        const date = new Date(adjustedMillis);
        const adjustedHours = String(date.getUTCHours()).padStart(2, '0');
        const adjustedMinutes = String(date.getUTCMinutes()).padStart(2, '0');
        return `${adjustedHours}:${adjustedMinutes}`;
    }
    handleSave(){
        const All_Input_Valid = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, input_Field_Reference) => {
                input_Field_Reference.reportValidity();
                return validSoFar && input_Field_Reference.checkValidity();
            }, true);
        const All_Compobox_Valid = [...this.template.querySelectorAll('lightning-combobox')]
            .reduce((validSoFar, input_Field_Reference) => {
                input_Field_Reference.reportValidity();
                return validSoFar && input_Field_Reference.checkValidity();
            }, true);
        var errorMessage = 'Please fill the mandatory fields.'
        // Check validity of the fields
        if (!All_Input_Valid || !All_Compobox_Valid || this.errorMessage !='' || this.errorMessageArr !='' || this.errorMessageDep !='') {
            // If any of the fields are invalid, don't proceed with submission
            this.showToast('Error', errorMessage, 'error');
            return;
        }else {
            this.handleBooking();
        }
    }

    // Handle selection of an option for other airport
    handleOtherOptionSelect(event) {
        const selectedValue = event.currentTarget.getAttribute('data-value');
        const selectedLabel = event.currentTarget.getAttribute('data-label');
        this.departureAirport = selectedValue;
        this.departureAirportLabel = selectedLabel;
        if(this.isTabThree){
            this.showTransitDepDropdown = false;
            this.setTransitSector();
            this.opportunityFieldValues['Departure_Airport_Id__c'] = this.getAirportId(this.departureAirport);
            this.opportunityFieldValues['Departure_Airport__c'] = this.departureAirport;
        } else {
            this.showOtherDropdown = false;
            this.setSector();
            this.resetflightNumber();
            if (this.isTabOne){
                this.opportunityFieldValues['Departure_Airport_Id__c'] = this.getAirportId(this.departureAirport);
                this.loadFlightData(this.arrivalDate, this.departureAirport, this.arrivingAirport);
                this.opportunityFieldValues['Departure_Airport__c'] = this.departureAirport;
            } else {                
                this.opportunityFieldValues['Arriving_Airport_Id__c'] = this.getAirportId(this.departureAirport);
                this.loadFlightData(this.departureDate, this.arrivingAirport, this.departureAirport);
                this.opportunityFieldValues['Arriving_Airport__c'] = this.departureAirport;
            }
        }
    }

    handleTransitDepToSelect(event) {        
        const selectedValue = event.currentTarget.getAttribute('data-value');
        const selectedLabel = event.currentTarget.getAttribute('data-label');
        this.arrivingAirport = selectedValue;
        this.arrivingAirportLabel = selectedLabel;
        this.showTransitArrDropdown = false;
            this.setTransitSector();
            this.opportunityFieldValues['Arriving_Airport_Id__c'] = this.getAirportId(this.arrivingAirport);
            this.opportunityFieldValues['Arriving_Airport__c'] = this.arrivingAirport;
    }

    // Handle selection of service airport option
    handleServiceOptionSelect(event) {
        const selectedValue = event.currentTarget.getAttribute('data-value');
        const selectedLabel = event.currentTarget.getAttribute('data-label');
        this.showServiceDropdown = false;
        if(this.isTabThree){
            this.transitAirport = selectedValue;
            this.transitAirportLabel=selectedLabel;
            this.setTransitSector();
            this.opportunityFieldValues['Service_Airport_Id__c'] = this.getAirportId(this.transitAirport);
            this.opportunityFieldValues['Service_Airport__c'] = this.transitAirport;
        } else {            
            this.arrivingAirport = selectedValue;
            this.arrivingAirportLabel = selectedLabel;
            this.setSector();
            this.opportunityFieldValues['Service_Airport_Id__c'] = this.getAirportId(this.arrivingAirport);
            this.resetflightNumber();
            this.opportunityFieldValues['Service_Airport__c'] = this.arrivingAirport;
            if(this.isTabOne){
                this.loadFlightData(this.arrivalDate, this.departureAirport, this.arrivingAirport);
            }else if(this.isTabTwo){
                this.loadFlightData(this.departureDate, this.arrivingAirport, this.departureAirport);
            }
        }
    }

    handleArrivingAirportChange(event) {
        if(this.isTabThree){           
            //logic for search key in picklist for Service airport
            /*const searchKey = event.target.value.toLowerCase();
            this.filteredAirportOptionsDepTo = this.allAirportOptionsDepTo.filter(option =>
                option.label.toLowerCase().includes(searchKey)
            );
            this.showTransitArrDropdown = this.allAirportOptionsDepTo.length > 0;*/

            const searchKey = event.target.value.toLowerCase();
            // Debounce logic
            clearTimeout(this.debounceTimeout);
            this.debounceTimeout = setTimeout(() => {
                // Filter the list with limited results
                this.filteredAirportOptionsDepTo = this.allAirportOptionsDepTo
                    .filter(option => {
                        // Log each option to verify if the filter is working as expected
                        return option.label.toLowerCase().includes(searchKey);
                    })
                    .slice(0, 10); // Limit to top 10 results
                // Show dropdown if we have results
                this.showTransitArrDropdown = this.filteredAirportOptionsDepTo.length > 0;
            }, 300); // Adjust debounce delay as needed
        } else {
            //logic for search key in picklist for Service airport
            const searchKey = event.target.value.toLowerCase();
            this.filteredServiceOptions = this.baseAirportOptions.filter(option =>
                option.label.toLowerCase().includes(searchKey)
            );
            this.showServiceDropdown = this.baseAirportOptions.length > 0;
        }
    }
    handleDepartureAirportChange(event) {
        if (this.isTabThree) {
            //logic for search key in picklist for Service airport
            /*const searchKey = event.target.value.toLowerCase();
            this.filteredAirportOptionsArrFrom = this.allAirportOptionsArrFrom.filter(option =>
                option.label.toLowerCase().includes(searchKey)
            );
            this.showTransitDepDropdown = this.allAirportOptionsArrFrom.length > 0;
            */
            const searchKey = event.target.value.toLowerCase();
            // Debounce logic
            clearTimeout(this.debounceTimeout);
            this.debounceTimeout = setTimeout(() => {
                // Filter the list with limited results
                this.filteredAirportOptionsArrFrom = this.allAirportOptionsArrFrom
                    .filter(option => {
                        // Log each option to verify if the filter is working as expected
                        return option.label.toLowerCase().includes(searchKey);
                    })
                    .slice(0, 10); // Limit to top 10 results
                // Show dropdown if we have results
                this.showTransitDepDropdown = this.filteredAirportOptionsArrFrom.length > 0;
            }, 300); // Adjust debounce delay as needed

        } else {
            const searchKey = event.target.value.toLowerCase();
            // Debounce logic
            clearTimeout(this.debounceTimeout);
            this.debounceTimeout = setTimeout(() => {
                // Filter the list with limited results
                this.filteredOtherOptions = this.allAirportOptions
                    .filter(option => {
                        // Log each option to verify if the filter is working as expected
                        return option.label.toLowerCase().includes(searchKey);
                    })
                    .slice(0, 10); // Limit to top 10 results
                // Show dropdown if we have results
                this.showOtherDropdown = this.filteredOtherOptions.length > 0;
            }, 300); // Adjust debounce delay as needed
        }
    }

    handleOtherdropdownOpen() {
        this.departureAirportLabel = '';
        this.showOtherDropdown = true;
        this.filteredOtherOptions = this.allAirportOptions;
    }

    handleArrFrmdropdownOpen() {
        this.departureAirportLabel = '';
        this.showTransitDepDropdown = true;
        this.filteredAirportOptionsArrFrom = this.allAirportOptionsArrFrom;
    }

    handleDepTodropdownOpen() {
        this.arrivingAirportLabel = '';
        this.showTransitArrDropdown = true;
        this.filteredAirportOptionsDepTo = this.allAirportOptionsDepTo;
    }

    handleServicedropdownOpen() {
        this.arrivingAirportLabel = '';
        this.transitAirportLabel = '';
        this.showServiceDropdown = true;
        this.filteredServiceOptions = this.baseAirportOptions;
    }

    handleFlightDropdownOpen() {
        this.flightNumber = '';
        this.showFlightNumber = true;
        this.filteredFlightOptions = this.flightNumberOptions;
        if (this.flightNumberOptions != undefined && this.flightNumberOptions.length === 0) {
            this.errorMessage = 'No flights found for the selected date'; // Display error message
        } else {
            this.errorMessage = ''; // Clear error message if options are available
        }
    }

    handleArrivalFlightDropdownOpen() {
        this.flightNumberArrival = '';
        this.showFlightNumberArrival = true;
        this.filteredFlightNumberOptionsArrival = this.flightNumberOptionsArrival;
        if (this.flightNumberOptionsArrival != undefined && this.flightNumberOptionsArrival.length === 0) {
            this.errorMessageArr = 'No flights found for the selected date'; // Display error message
        } else {
            this.errorMessageArr = ''; // Clear error message if options are available
        }
    }

    handleDepartureFlightDropdownOpen() {
        this.flightNumberDeparture = '';
        this.showFlightNumberDepart = true;
        this.filteredFlightNumberOptionsDeparture = this.flightNumberOptionsDeparture;
        if (this.flightNumberOptionsDeparture != undefined && this.flightNumberOptionsDeparture.length === 0) {
            this.errorMessageDep = 'No flights found for the selected date'; // Display error message
        } else {
            this.errorMessageDep = ''; // Clear error message if options are available
        }
    }

    resetflightNumber(){
        this.flightNumber = undefined;
    }
 

    handleStaTimeChange(event) { 
        this.staTime = event.target.value;
        this.staTime = this.staTime.split(':').slice(0, 2).join(':');
        this.opportunityFieldValues['Arrival_Service_Time__c'] = this.staTime;
    }
    handleStdTimeChange(event) { 
        this.stdTime = event.target.value; 
        this.depServiceTime = this.adjustServiceTime();
        this.stdTime = this.stdTime.split(':').slice(0, 2).join(':');
        this.opportunityFieldValues['STD_Time__c'] = this.stdTime;
        this.opportunityFieldValues['Departure_Service_Time__c'] = this.depServiceTime;
    }
    handledepServiceTimeChange(event){
        this.depServiceTime = event.target.value; 
        this.opportunityFieldValues['Departure_Service_Time__c'] = this.depServiceTime;
    }
    handleServiceTimeChange(event) { this.serviceTime = event.target.value; }

    handleFirstNameChange(event) { this.firstName = event.target.value; }
    handleLastNameChange(event) { this.lastName = event.target.value; }
    handlePhoneChange(event) { this.phone = event.target.value; }
    handleDobChange(event) { this.dateOfBirth = event.target.value; }

    handleFirstNameChange1(event) { this.firstName1 = event.target.value; }
    handleLastNameChange1(event) { this.lastName1 = event.target.value; }
    handlePhoneChange1(event) { this.phone1 = event.target.value; }
    handleDobChange1(event) { this.dateOfBirth1 = event.target.value; }

    handleFirstNameChange2(event) { this.firstName2 = event.target.value; }
    handleLastNameChange2(event) { this.lastName2 = event.target.value; }
    handlePhoneChange2(event) { this.phone2 = event.target.value; }
    handleDobChange2(event) { this.dateOfBirth2 = event.target.value; }
    handleFlightNumberChangeArrival(event) {
        //logic for search key in picklist for flight number
        const searchKey = event.target.value.toLowerCase();
        this.filteredFlightNumberOptionsArrival = this.flightNumberOptionsArrival.filter(option =>
            option.label.toLowerCase().includes(searchKey)
        );
        this.showFlightNumberArrival = this.flightNumberOptionsArrival.length > 0;
        // Validate if the entered value matches one of the picklist options
        const isValid = this.filteredFlightNumberOptionsArrival.some(option => option.value === this.flightNumberArrival);

        if (!isValid) {
            this.errorMessageArr = 'Please select a valid value from the picklist.';
        } else {
            this.errorMessageArr = ''; // Clear error if valid
        }
    }
    handleFlightNumberChangeDeparture(event) {
        //logic for search key in picklist for flight number
        const searchKey = event.target.value.toLowerCase();
        this.filteredFlightNumberOptionsDeparture = this.flightNumberOptionsDeparture.filter(option =>
            option.label.toLowerCase().includes(searchKey)
        );
        this.showFlightNumberDepart = this.flightNumberOptionsDeparture.length > 0;
        // Validate if the entered value matches one of the picklist options
        const isValid = this.filteredFlightNumberOptionsDeparture.some(option => option.value === this.flightNumberDeparture);

        if (!isValid) {
            this.errorMessageDep = 'Please select a valid value from the picklist.';
        } else {
            this.errorMessageDep = ''; // Clear error if valid
        }
    }


   


setIncrementCounter(event){
       this.qtyVal++;
}

setDecrementCounter(event){
    console.log('------------------',this.qtyVal);
    if(this.qtyVal != 0 )
    {
 this.qtyVal--;
    }

}

setSector(){
    var tempCountryArr='';
    var tempCountryDep='';
    if (this.arrivingAirport !='' && this.countryMap.has(this.arrivingAirport)) {
        tempCountryArr = this.countryMap.get(this.arrivingAirport);
    }
    if (this.departureAirport !='' && this.countryMap.has(this.departureAirport)) {
        tempCountryDep = this.countryMap.get(this.departureAirport);
    }
    if(tempCountryArr =='' || tempCountryDep =='') {
        this.sector = '';
    }else if(tempCountryArr == tempCountryDep) {
        this.sector = 'Domestic';
        this.opportunityFieldValues['Flight_Type__c'] = 'Domestic';
    } else {
        this.sector = 'International';
        this.opportunityFieldValues['Flight_Type__c'] = 'International';
    }
}
setTransitSector(){
    var tempCountryTransit='';
    var tempCountryArr='';
    var tempCountryDep='';
    
    if (this.transitAirport !='' && this.countryMap.has(this.transitAirport)) {
        tempCountryTransit = this.countryMap.get(this.transitAirport);
    }
    if (this.arrivingAirport !='' && this.countryMap.has(this.arrivingAirport)) {        
        tempCountryArr = this.countryMap.get(this.arrivingAirport);
    }
    if (this.departureAirport !='' && this.countryMap.has(this.departureAirport)) {
        tempCountryDep = this.countryMap.get(this.departureAirport);
    }
    if(tempCountryTransit =='') {
        this.sector = '';
    }else if((tempCountryDep == tempCountryTransit) && tempCountryArr == '') {
        this.sector = 'Domestic to International';
    }else if((tempCountryTransit == tempCountryArr) && tempCountryDep=='') {
        this.sector = 'International to Domestic';
    }else if((tempCountryTransit == tempCountryDep) &&  (tempCountryTransit== tempCountryArr)) {
        this.sector = 'Domestic to Domestic';
    } else if ((tempCountryTransit == tempCountryDep) && (tempCountryArr != tempCountryTransit)){
        this.sector = 'Domestic to International';
    } else if ((tempCountryTransit != tempCountryDep) && (tempCountryArr == tempCountryTransit)){
        this.sector = 'International to Domestic';
    }else {
        this.sector = 'International to International';
    }
    this.opportunityFieldValues['Flight_Type__c'] = this.sector;
}

setStaTime(){
    if (this.flightNumber !='' && this.flightStaMap.has(this.flightNumber)) {
        this.staTime = this.formatTime(this.flightStaMap.get(this.flightNumber),0,0);
    }
    if (this.flightNumberArrival !='' && this.flightStaMap.has(this.flightNumberArrival)) {
        this.staTime = this.formatTime(this.flightStaMap.get(this.flightNumberArrival),0,0);
    }
    this.opportunityFieldValues['STA_Time__c'] = this.staTime;
    this.opportunityFieldValues['Arrival_Service_Time__c'] = this.staTime;
}
setStdTime(){
    if (this.flightNumber !='' && this.flightDtaMap.has(this.flightNumber)) {
        this.stdTime = this.formatTime(this.flightDtaMap.get(this.flightNumber),0,0);
    }
    if (this.flightNumberDeparture !='' && this.flightDtaMap.has(this.flightNumberDeparture)) {
        this.stdTime = this.formatTime(this.flightDtaMap.get(this.flightNumberDeparture),0,0);
    }
    this.opportunityFieldValues['STD_Time__c'] = this.stdTime;
    // Calculate Service Time dynamically based on sector
    this.depServiceTime = this.adjustServiceTime();
    this.opportunityFieldValues['Departure_Service_Time__c'] = this.depServiceTime;
}
resetFlightDetails(){
    this.flightNumber='';
    this.staTime ='';
    this.stdTime='';
    this.depServiceTime='';
}
resetOnTabChange() {
    this.errorMessage='';
    this.errorMessageDep='';
    this.errorMessageArr='';
    this.arrivingAirport = '';
    this.departureAirport = '';
    this.departureAirportLabel = '';
    this.arrivingAirportLabel = '';
    this.transitAirport='';
    this.transitAirportLabel='';
    this.flightNumberArrival='';
    this.flightNumberDeparture='';
    this.arrivalDate=undefined;  
    this.departureDate=undefined;  
    this.flightNumber = '';
    this.staTime = '';
    this.depServiceTime='';
    this.stdTime = '';
    this.serviceTime = '';
    this.sector='';
    this.flightNumberOptionsArrival;
    this.flightNumberOptionsDeparture;
    this.flightNumberOptions;
    this.opportunityFieldValues['Arriving_Flight_Schedule__c']=null;
    this.opportunityFieldValues['Departure_Flight_Schedule__c']=null;
    this.opportunityFieldValues['Arriving_Airport_Id__c']=null;
    this.opportunityFieldValues['Departure_Airport_Id__c']=null;
    this.opportunityFieldValues['Departure_Service_Time__c'] = null;
    this.opportunityFieldValues['STD_Time__c'] = null;
    this.opportunityFieldValues['Arrival_Service_Time__c'] = null;
    this.opportunityFieldValues['STA_Time__c'] = null;
}
handleAccountRecord(event){
    this.accountId = event.detail['Id'];
}

handleBooking() {

    this.opportunityFieldValues['Number_of_Adults__c'] = this.adultCount;
    this.opportunityFieldValues['Number_of_Children__c'] = this.childCount;
    this.opportunityFieldValues['Number_of_Infants__c'] = this.infantCount;
    this.isLoading = true;
    //this.opportunityFieldValues[''] = this.flightSchedule;
    processBooking({ recId: this.recordId, accId: this.accountId, opportunityFieldValues: this.opportunityFieldValues })
        .then((opportunityId) => {
            //this.showToast('Success', 'Lead converted successfully!', 'success');

            // Redirect to Opportunity record
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: opportunityId,
                    objectApiName: 'Opportunity',
                    actionName: 'view',
                },
            });
        })
        .catch((error) => {
            this.showToast('Error', error.body.message, 'error');
            this.isLoading = false;
        });
}

showToast(title, message, variant) {
    const event = new ShowToastEvent({
        title,
        message,
        variant,
    });
    this.dispatchEvent(event);
}

//to get field values to save in opp record
handleFieldChange(event) {
    // Delay the blur event to ensure option selection works
    setTimeout(() => {
        this.showFlightNumber = false;
        this.showFlightNumberArrival = false;
        this.showFlightNumberDepart = false;
    }, 200);
    const fieldName = event.target.name;
    const fieldValue = event.target.value;

    this.opportunityFieldValues[fieldName] = fieldValue;
}
handleDropDownClose() {
    // Delay the blur event to ensure option selection works
    setTimeout(() => {
        this.showOtherDropdown = false;
        this.showServiceDropdown = false;
        this.showTransitDepDropdown = false;
        this.showTransitArrDropdown = false;
    }, 200);
}
handleTransitAirportChange(event){
    //logic for search key in picklist for Service airport
    const searchKey = event.target.value.toLowerCase();
    this.filteredServiceOptions = this.baseAirportOptions.filter(option =>
        option.label.toLowerCase().includes(searchKey)
    );
    this.showServiceDropdown = this.baseAirportOptions.length > 0;   
}
handleTransitArrivalDateChange(event){
    this.arrivalDate = event.target.value;
    event.target.blur();
    this.loadTransitFlightData(this.arrivalDate, this.departureAirport, '');
}
handleTransitDepartureDateChange(event){
    this.departureDate = event.target.value;
    event.target.blur();
    this.loadTransitFlightData(this.departureDate, '', this.arrivingAirport);
}




}