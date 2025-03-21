import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getOpportunityDetails from '@salesforce/apex/RescheduleBooking.getOpportunityDetails';
import showReschedulingCharges from '@salesforce/apex/RescheduleBooking.showReschedulingCharges';
import saveData from '@salesforce/apex/RescheduleBooking.saveData';
import getFlightDetails from '@salesforce/apex/Encalm_BookingEngine.getFlightDetails';

export default class RescheduleBooking extends NavigationMixin(LightningElement) {
    @api recordId;
    @track opportunityFieldValues = {};
    bookingData;
    isArrival=false;
    isDeparture=false;
    isTransit=false;
    flightNumber = '';
    flightNumberArrival='';
    flightNumberDeparture='';
    arrivalDate;
    showFlightNumber = false;
    showFlightNumberArrival = false;
    showFlightNumberDepart = false;
    @track filteredFlightOptions = [];
    @track filteredFlightNumberOptionsArrival = [];
    @track filteredFlightNumberOptionsDeparture = [];
    flightSchedule=[];
    flightStaMap = new Map();
    flightDtaMap = new Map();

    connectedCallback() {
        console.log('Connected this.recordId->> ',this.recordId);
        this.loadBookingData();
    }

    loadBookingData() {
        console.log('this.recordId->> ',this.recordId);
        getOpportunityDetails({opportunityId: this.recordId})
        .then((result) => {
            this.bookingData = result;
            console.log('this.bookingData.serviceType-->> ', JSON.stringify(this.bookingData.serviceType));
            if(this.bookingData.serviceType == 'Arrival') {
                this.isArrival = true;
                this.flightNumber = result.flightNumberArrival;
                this.arrivalDate= result.arrivalDate;
            } else if(this.bookingData.serviceType == 'Departure') {
                this.isDeparture = true;
                this.flightNumber = result.flightNumberDeparture;
            }else if(this.bookingData.serviceType == 'Transit') {
                this.isTransit = true;
            }
        })
        .catch((error) => {
            console.error(error);
        });
    }

    handleSave() {
        saveData({ oppId: this.recordId, opportunityFieldValues: this.opportunityFieldValues })
        .then((opportunityId) => {
           
        })
        .catch((error) => {
            console.log('error->>>>>>>'+JSON.stringify(error));
        });
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

    setStaTime(){
        if (this.flightNumber !='' && this.flightStaMap.has(this.flightNumber)) {
            this.staTime = this.formatTime(this.flightStaMap.get(this.flightNumber),0,0);
        }
        if (this.flightNumberArrival !='' && this.flightStaMap.has(this.flightNumberArrival)) {
            this.staTime = this.formatTime(this.flightStaMap.get(this.flightNumberArrival),0,0);
        }
        this.opportunityFieldValues['STA_Time__c'] = this.staTime;
    }
    setStdTime(){
        if (this.flightNumber !='' && this.flightDtaMap.has(this.flightNumber)) {
            this.stdTime = this.formatTime(this.flightDtaMap.get(this.flightNumber),1,30);
        }
        if (this.flightNumberDeparture !='' && this.flightDtaMap.has(this.flightNumberDeparture)) {
            this.stdTime = this.formatTime(this.flightDtaMap.get(this.flightNumberDeparture),1,30);
        }
        this.opportunityFieldValues['STD_Time__c'] = this.stdTime;
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
    //reset flight data
    resetFlightDetails(){
        this.flightNumber='';
        this.staTime ='';
        this.stdTime='';
    }
    //this is called when Arrival date is changed
    handleArrivalDateChange(event) { 
        this.arrivalDate = event.target.value;
        if(this.isArrival){
             this.loadFlightData(this.arrivalDate, this.bookingData.departureAirport, this.bookingData.arrivingAirport);
         }
     }
    
}