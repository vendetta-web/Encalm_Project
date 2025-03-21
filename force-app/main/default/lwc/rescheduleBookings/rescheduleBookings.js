import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getOpportunityDetails from '@salesforce/apex/RescheduleBooking.getOpportunityDetails';
import showReschedulingCharges from '@salesforce/apex/RescheduleBooking.showReschedulingCharges';
import saveData from '@salesforce/apex/RescheduleBooking.saveData';
import getFlightDetails from '@salesforce/apex/Encalm_BookingEngine.getFlightDetails';
import getTransitFlightDetails from '@salesforce/apex/Encalm_BookingEngine.getTransitFlightDetails';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class RescheduleBookings extends LightningElement {
    @api recordId;
    @track opportunityFieldValues = {};
    bookingData;
    isArrival=false;
    isDeparture=false;
    isTransit=false;
    showSummary = false;
    flightNumber = '';
    flightNumberArrival='';
    flightNumberDeparture='';
    arrivalDate;
    departureDate;
    showFlightNumber = false;
    showFlightNumberArrival = false;
    showFlightNumberDepart = false;
    @track filteredFlightOptions = [];
    @track filteredFlightNumberOptionsArrival = [];
    @track filteredFlightNumberOptionsDeparture = [];
    flightSchedule=[];
    flightStaMap = new Map();
    flightDtaMap = new Map();
    RescheduleSummary;
    serviceDateTime='';
    staTime = '';
    stdTime = '';
    serviceTime = '';
    noBookingFound='';
    confirmRescheduling = false;
    newReschedulingCount = 0;
    
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant,
        });
        this.dispatchEvent(event);
    }

    // Wire the Apex method to get Opportunity Line Items
    @wire(getOpportunityDetails, { opportunityId: '$recordId' })
    wiredOpportunityLineItems({ error, data }) {
        if (data) {
            console.log('Data-> ', JSON.stringify(data));
            this.bookingData = data;
            if(this.bookingData.serviceType == 'Arrival') {
                this.isArrival = true;
                this.flightNumber = data.flightNumberArrival;
                this.arrivalDate= data.arrivalDate;
                this.staTime = data.staTime;
                this.serviceTime = data.staTime;
            } else if(this.bookingData.serviceType == 'Departure') {
                this.isDeparture = true;
                this.flightNumber = data.flightNumberDeparture;
                this.departureDate= data.departureDate;
                this.stdTime = data.stdTime;
                this.serviceTime = data.stdServiceTime;
            }else if(this.bookingData.serviceType == 'Transit') {
                this.isTransit = true;
                this.flightNumberArrival = data.flightNumberArrival;
                this.flightNumberDeparture = data.flightNumberDeparture;
                this.arrivalDate= data.arrivalDate;
                this.staTime = data.staTime;
                this.departureDate= data.departureDate;
                this.stdTime = data.stdTime;
                this.serviceTime = data.stdServiceTime;
            }
        } else if (error) {
            console.error('Error fetching line items', JSON.stringify(error));
        }
    }

    loadReschedulingSummaryData(isSubmit) {
        showReschedulingCharges({opportunityId: this.recordId, submit: isSubmit})
        .then((result) => {
            this.RescheduleSummary = result;
            this.newReschedulingCount = result.countOfRescheduling + 1;
        })
        .catch((error) => {
            console.error(error);
        });
    }

    checkArrivalChanges() {
        if (this.bookingData.arrivalDate != this.arrivalDate || this.bookingData.flightNumberArrival != this.flightNumber){
            return true;
        } else {
            return false;
        }
    }

    checkDepartureChanges() {
        if (this.bookingData.departureDate != this.departureDate || this.bookingData.flightNumberDeparture != this.flightNumber){
            return true;
        } else {
            return false;
        }
    }

    checkTransitChanges() {
        if (this.bookingData.departureDate != this.departureDate || this.bookingData.flightNumberDeparture != this.flightNumberDeparture || this.bookingData.arrivalDate != this.arrivalDate || this.bookingData.flightNumberArrival != this.flightNumberArrival){
            return true;
        } else {
            return false;
        }
    }

    handleNext() {
        const All_Input_Valid = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, input_Field_Reference) => {
                input_Field_Reference.reportValidity();
                return validSoFar && input_Field_Reference.checkValidity();
            }, true);
            var errorMessage = 'Please fill the mandatory fields.'
        // Check validity of the fields
        if (!All_Input_Valid) {
            // If any of the fields are invalid, don't proceed with submission
            this.showToast('Error', errorMessage, 'error');
            return;
        } else {
            if (this.bookingData.serviceType == 'Arrival' && this.checkArrivalChanges()) {
                this.isArrival = false;
                this.showSummary = true;
                this.loadReschedulingSummaryData(false);
            } else if (this.bookingData.serviceType == 'Departure' && this.checkDepartureChanges()) {
                this.isDeparture = false;
                this.showSummary = true;
                this.loadReschedulingSummaryData(false);
            } else if (this.bookingData.serviceType == 'Transit' && this.checkTransitChanges()) {
                this.isDeparture = false;
                this.showSummary = true;
                this.loadReschedulingSummaryData(false);
            }else {
                this.showToast('Error', 'No changes found for rescheduling!', 'error');
            }
        }
    }

    showFirstScreen() {
        if (this.bookingData.serviceType == 'Arrival') {
            this.isArrival = true;
        } else if (this.bookingData.serviceType == 'Departure') {
            this.isDeparture = true;
        }
        this.showSummary = false;
    }

    handleSave() {
        this.opportunityFieldValues['Number_of_Rescheduling_Done__c'] = this.newReschedulingCount;
        saveData({ oppId: this.recordId, opportunityFieldValues: this.opportunityFieldValues })
        .then((opportunityId) => {
        
        })
        .catch((error) => {
            console.log('error->>>>>>>'+JSON.stringify(error));
        });
        this.loadReschedulingSummaryData(true);
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
    //logic to search flight number by typing
    handleFlightNumberChange(event) { 
        //logic for search key in picklist for flight number
        const searchKey = event.target.value.toLowerCase();
        this.filteredFlightOptions = this.flightNumberOptions.filter(option =>
            option.label.toLowerCase().includes(searchKey)
        );
        this.showFlightNumber = this.flightNumberOptions.length > 0;
    }
    //to show dropdown for flight in arrival and departure
    handleFlightDropdownOpen() {
        this.flightNumber = '';
        this.showFlightNumber = true;
        this.filteredFlightOptions = this.flightNumberOptions;
    }

    handleArrivalFlightDropdownOpen() {
        this.flightNumberArrival = '';
        this.showFlightNumberArrival = true;
        this.filteredFlightNumberOptionsArrival = this.flightNumberOptionsArrival;
    }

    handleDepartureFlightDropdownOpen() {
        this.flightNumberDeparture = '';
        this.showFlightNumberDepart = true;
        this.filteredFlightNumberOptionsDeparture = this.flightNumberOptionsDeparture;
    }

    handleFlightNumberChangeArrival(event) {
        //logic for search key in picklist for flight number
        const searchKey = event.target.value.toLowerCase();
        this.filteredFlightNumberOptionsArrival = this.flightNumberOptionsArrival.filter(option =>
            option.label.toLowerCase().includes(searchKey)
        );
        this.showFlightNumberArrival = this.flightNumberOptionsArrival.length > 0;
    }
    handleFlightNumberChangeDeparture(event) {
        //logic for search key in picklist for flight number
        const searchKey = event.target.value.toLowerCase();
        this.filteredFlightNumberOptionsDeparture = this.flightNumberOptionsDeparture.filter(option =>
            option.label.toLowerCase().includes(searchKey)
        );
        this.showFlightNumberDepart = this.flightNumberOptionsDeparture.length > 0;
    }

    handleFlightOptionSelect(event) {
        const selectedValue = event.currentTarget.getAttribute('data-value');
        this.showFlightNumber = false;
        this.flightNumber = selectedValue;        
        if(this.isArrival){
            this.setStaTime();
            this.opportunityFieldValues['Arriving_Flight_Schedule__c']=this.getFlightId(this.flightNumber);
        }else if(this.isDeparture) {
            this.setStdTime();
            this.opportunityFieldValues['Departure_Flight_Schedule__c']=this.getFlightId(this.flightNumber);
        }
    }

    handleArrivalFlightOptionSelect(event) {
        const selectedValue = event.currentTarget.getAttribute('data-value');
        this.showFlightNumberArrival = false;
        this.flightNumberArrival = selectedValue;
        this.setStaTime();
        this.opportunityFieldValues['Arriving_Flight_Schedule__c'] = this.getFlightId(this.flightNumberArrival);
    }

    handleDepartureFlightOptionSelect(event) {
        const selectedValue = event.currentTarget.getAttribute('data-value');
        this.showFlightNumberDepart = false;
        this.flightNumberDeparture = selectedValue;
        this.setStdTime();
        this.opportunityFieldValues['Departure_Flight_Schedule__c'] = this.getFlightId(this.flightNumberDeparture);
    }

    setStaTime(){
        if (this.flightNumber !='' && this.flightStaMap.has(this.flightNumber)) {
            this.staTime = this.formatTime(this.flightStaMap.get(this.flightNumber),0,0);
            this.serviceTime = this.staTime;
        }
        if (this.flightNumberArrival !='' && this.flightStaMap.has(this.flightNumberArrival)) {
            this.staTime = this.formatTime(this.flightStaMap.get(this.flightNumberArrival),0,0); 
            this.serviceTime = this.staTime;
        }
        this.opportunityFieldValues['STA_Time__c'] = this.staTime;
        this.opportunityFieldValues['Arrival_Service_Time__c'] = this.serviceTime;       
        this.serviceDateTime = this.arrivalDate +' ' + this.serviceTime;
    }
    setStdTime(){
        if (this.flightNumber !='' && this.flightDtaMap.has(this.flightNumber)) {
            this.stdTime = this.formatTime(this.flightDtaMap.get(this.flightNumber),0,0);
            this.serviceTime = this.formatTime(this.flightDtaMap.get(this.flightNumber),1,30);
        }
        if (this.flightNumberDeparture !='' && this.flightDtaMap.has(this.flightNumberDeparture)) {
            this.stdTime = this.formatTime(this.flightDtaMap.get(this.flightNumberDeparture),0,0);
            this.serviceTime = this.formatTime(this.flightDtaMap.get(this.flightNumber),1,30);
        }
        this.opportunityFieldValues['STD_Time__c'] = this.stdTime;
        this.opportunityFieldValues['Departure_Service_Time__c'] = this.serviceTime;
        this.serviceDateTime = this.departureDate +' ' + this.serviceTime;
    }
    formatTime(milliseconds,hrs,mns) {
        const adjustedMillis = milliseconds - (hrs * 3600000) - (mns * 60000);
        const date = new Date(adjustedMillis);
        const hours = String(date.getUTCHours()).padStart(2, '0');
        const minutes = String(date.getUTCMinutes()).padStart(2, '0');
        return `${hours}:${minutes}`; // Format as HH:MM
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

    //reset flight data
    resetFlightDetails(){
        this.flightNumber='';
        this.staTime ='';
        this.stdTime='';
        this.serviceTime = '';
    }
    //this is called when Arrival date is changed
    handleArrivalDateChange(event) { 
        this.arrivalDate = event.target.value;
        if(this.isArrival){
             this.loadFlightData(this.arrivalDate, this.bookingData.departureAirport, this.bookingData.serviceAirport);
         }
    }

    handleDepartureDateChange(event){
        this.departureDate = event.target.value;
        if(this.isDeparture){
            this.loadFlightData(this.departureDate, this.bookingData.serviceAirport, this.bookingData.arrivingAirport);
        }
    }

    handleTransitArrivalDateChange(event){
        this.arrivalDate = event.target.value;
            this.loadTransitFlightData(this.arrivalDate, this.bookingData.departureAirport, '');
    }
    handleTransitDepartureDateChange(event){
        this.departureDate = event.target.value;
            this.loadTransitFlightData(this.departureDate, '', this.bookingData.arrivingAirport);
    }

    openConfirmationModal() {
        this.confirmRescheduling = true;
    }

    closePopupModal() {
        this.confirmRescheduling = false;
    }

    handleFinalSubmit() {
        this.handleSave();
        this.closeModal();
    }

    closeModal() {
        this.showSummary = false;
        this.confirmRescheduling = false;
        // Dispatch an event to close the LWC component
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}