import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getOpportunityDetails from '@salesforce/apex/RescheduleBooking.getOpportunityDetails';
import showReschedulingCharges from '@salesforce/apex/RescheduleBooking.showReschedulingCharges';
import saveData from '@salesforce/apex/RescheduleBooking.saveData';
import getFlightDetails from '@salesforce/apex/Encalm_BookingEngine.getFlightDetails';
import getTransitFlightDetails from '@salesforce/apex/Encalm_BookingEngine.getTransitFlightDetails';
import sendEmailWithAttachment from '@salesforce/apex/BookingEmailHandler.sendEmailWithAttachment';
import generatePaymentLink from '@salesforce/apex/OrderRequestController.generatePaymentLink';
import generateAndSavePDF from '@salesforce/apex/RescheduleBookingPIController.generateAndSavePDF';
import getRescheduleOrderRequest from '@salesforce/apex/OrderRequestController.getLatestPendingRescheduleOrderRequest';
import updateDataFromOrderRequest from '@salesforce/apex/OrderRequestController.updateDataFromOrderRequest';
import { RefreshEvent } from 'lightning/refresh';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class RescheduleBookings extends NavigationMixin(LightningElement) {
    @api recordId;
    @track opportunityFieldValues = {};
    @track orderRequestFieldValues = {};
    @api orderId;
    @api oppId;
    @api mode; // 'preview' or 'clone'
    todayDate= new Date().toISOString().split('T')[0];
    bookingData;
    isArrival=false;
    isDeparture=false;
    isTransit=false;
    showSummary = false;
    isLoading = false;
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
    hasPendingReq=false;

    orderRequest;
    error;
    
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
            if (this.bookingData.hasPendingRequest) {
                this.hasPendingReq=true;
            } else if(this.bookingData.serviceType == 'Arrival') {
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
                this.transitAirport = data.serviceAirport;
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
    /*loadReschedulingSummaryData(isSubmit) {
        showReschedulingCharges({opportunityId: this.recordId, submit: isSubmit})
        .then((result) => {
            this.RescheduleSummary = result;
            this.newReschedulingCount = result.countOfRescheduling + 1;
            //Generate pdf and send email
            if(isSubmit) {
                this.generatePdf();
            }
        })
        .catch((error) => {
            console.error(error);
            this.isLoading = false;
            this.closeModal();
        });
    }*/ 
    // Above code commented and belo code added by Abhishek
    async loadReschedulingSummaryData(isSubmit, orderSummaryChanges) {        
       try { 
        const recId =  this.oppId != undefined ? this.oppId : this.recordId;
            const result  = await showReschedulingCharges({opportunityId: recId, submit: isSubmit, OrderChangeRequest: orderSummaryChanges}); 
            this.isLoading = false;       
            this.RescheduleSummary = result;
            this.newReschedulingCount = result.countOfRescheduling + 1;
            //Generate pdf and send email
            if(isSubmit) {
                ///this.generatePdf();
                if (this.orderRequest) {
                    this.closeReschedule();
                } else {
                    this.dispatchEvent(new RefreshEvent());
                    this.closeModal();
                    this.handleCloseComponent();
                }
            }
        }catch (error) {
            console.error(error);
            this.isLoading = false;
            this.closeModal();
        };
    }

    closeReschedule() {
        const closeEvt = new CustomEvent('close');
        this.dispatchEvent(closeEvt);
    }

    checkArrivalChanges() {
        if (this.orderRequest) {
            if (this.orderRequest.Date_of_Arrival__c != this.arrivalDate || this.orderRequest.Flight_Number_Arrival__c != this.flightNumber){
                return true;
            } else {
                return false;
            }
        } else {
            if (this.bookingData.arrivalDate != this.arrivalDate || this.bookingData.flightNumberArrival != this.flightNumber){
                return true;
            } else {
                return false;
            }
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
        debugger;
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
        } else if (this.orderRequest){
            if (this.isArrival && this.checkArrivalChanges()) {
                this.isArrival = false;
                this.showSummary = true;
                this.loadReschedulingSummaryData(false);
            } else if (this.orderRequest.serviceType == 'Departure' && this.checkDepartureChanges()) {
                this.isDeparture = false;
                this.showSummary = true;
                this.loadReschedulingSummaryData(false);
            } else if (this.orderRequest.serviceType == 'Transit' && this.checkTransitChanges()) {                
                //this.isTransit = false;
                this.showSummary = true;
                const departureDateTime = this.combineDateTime(this.departureDate, this.serviceTime);
                const arrivalDateTime = this.combineDateTime(this.arrivalDate, this.staTime);

                const differenceMs = Math.abs(arrivalDateTime - departureDateTime);
                const differenceHours = differenceMs / (1000 * 60 * 60);
                if (differenceHours > 8) {
                    this.showSummary = false;
                    this.showToast('Error', 'Difference should be less than 8 hours', 'error');
                }else{ 
                    this.isTransit = false;
                this.loadReschedulingSummaryData(false);
                }
            }else {
                this.showToast('Error', 'No changes found for rescheduling!', 'error');
            }
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
                //this.isTransit = false;
                this.showSummary = true;
                const departureDateTime = this.combineDateTime(this.departureDate, this.serviceTime);
                const arrivalDateTime = this.combineDateTime(this.arrivalDate, this.staTime);

                const differenceMs = Math.abs(arrivalDateTime - departureDateTime);
                const differenceHours = differenceMs / (1000 * 60 * 60);
                if (differenceHours > 8) {
                    this.showSummary = false;
                    this.showToast('Error', 'Difference should be less than 8 hours', 'error');
                }else{ 
                    this.isTransit = false;
                this.loadReschedulingSummaryData(false);
                }
            }else {
                this.showToast('Error', 'No changes found for rescheduling!', 'error');
            }
        }
    }
    combineDateTime(dateStr, timeStr) {
    try {
        // Check format of timeStr: should be HH:mm
        const [hours, minutes] = timeStr.split(':').map(Number);
        if (isNaN(hours) || isNaN(minutes)) {
            throw new Error('Invalid time format');
        }

        const date = new Date(dateStr);
        date.setHours(hours);
        date.setMinutes(minutes);
        date.setSeconds(0);
        date.setMilliseconds(0);
        return date;
    } catch (e) {
        console.error('Invalid time format:', timeStr);
        return new Date(); // Fallback to current date/time (NOT recommended for production)
    }
}
    showFirstScreen() {
        if (this.bookingData.serviceType == 'Arrival') {
            this.isArrival = true;
        } else if (this.bookingData.serviceType == 'Departure') {
            this.isDeparture = true;
        }
        else if (this.bookingData.serviceType == 'Transit') {
            this.isTransit = true;
        }
        this.showSummary = false;
    }

    async handleSave() {
        this.isLoading = true;
        //await this.loadReschedulingSummaryData(true); // added by Abhishek
        this.opportunityFieldValues['Number_of_Rescheduling_Done__c'] = this.newReschedulingCount;
        
        //order summary changes
        let serializedData = JSON.stringify(this.opportunityFieldValues); // Safe even if unknown keys
        const recId =  this.oppId != undefined ? this.oppId : this.recordId;
        this.orderRequestFieldValues['Booking__c'] = recId;
        this.orderRequestFieldValues['Serialized_Data__c'] = serializedData;
        this.orderRequestFieldValues['Change_Type__c'] = 'Reschedule';
        this.orderRequestFieldValues['Status__c'] = 'Pending';
        this.orderRequestFieldValues['Service_Type__c'] = this.bookingData != undefined ? this.bookingData.serviceType : this.orderRequest.Service_Type__c;
        await this.loadReschedulingSummaryData(true, this.orderRequestFieldValues);
        await this.generatePdf();
        if (this.RescheduleSummary.reschedulingAmount > 0){
            await this.paymentLinkHandler();
        } else {
            await this.completeOrderRequestHandler();
            await this.handleSendEmail();
        }
        ///add the method for pdf
        /*
        saveData({ oppId: this.recordId, opportunityFieldValues: this.opportunityFieldValues })
        .then((opportunityId) => {
            //Save the data on OLI
            this.loadReschedulingSummaryData(true, orderSummaryChanges);
        })
        .catch((error) => {
            console.log('error->>>>>>>'+JSON.stringify(error));
            this.closeModal();
            this.isLoading = false;
        });
        */
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
        this.orderRequestFieldValues[fieldName] = fieldValue;
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
            //this.serviceTime = this.staTime;
        }
        if (this.flightNumberArrival !='' && this.flightStaMap.has(this.flightNumberArrival)) {
            this.staTime = this.formatTime(this.flightStaMap.get(this.flightNumberArrival),0,0); 
            //this.serviceTime = this.staTime;
        }
        this.opportunityFieldValues['STA_Time__c'] = this.staTime;
        this.opportunityFieldValues['Arrival_Service_Time__c'] = this.staTime;//this.serviceTime;  
        this.orderRequestFieldValues['Arrival_Service_Time__c'] = this.staTime;//this.serviceTime;     
        this.serviceDateTime = this.arrivalDate +' ' + this.staTime;//this.serviceTime;
    }
    setStdTime(){
        if (this.flightNumber !='' && this.flightDtaMap.has(this.flightNumber)) {
            this.stdTime = this.formatTime(this.flightDtaMap.get(this.flightNumber),0,0);
            this.serviceTime = this.formatTime(this.flightDtaMap.get(this.flightNumber),1,30);
        }
        if (this.flightNumberDeparture !='' && this.flightDtaMap.has(this.flightNumberDeparture)) {
            this.stdTime = this.formatTime(this.flightDtaMap.get(this.flightNumberDeparture),0,0);
            this.serviceTime = this.formatTime(this.flightDtaMap.get(this.flightNumberDeparture),1,30);
        }
        this.opportunityFieldValues['STD_Time__c'] = this.stdTime;
        this.opportunityFieldValues['Departure_Service_Time__c'] = this.serviceTime;
        this.orderRequestFieldValues['Departure_Service_Time__c'] = this.serviceTime;
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
        if(this.orderRequest && this.isArrival) {
            this.loadFlightData(this.arrivalDate, this.orderRequest.Booking__r.Departure_Airport__c, this.orderRequest.Booking__r.Service_Airport__c);
        }
        else if(this.bookingData && this.isArrival){
             this.loadFlightData(this.arrivalDate, this.bookingData.departureAirport, this.bookingData.serviceAirport);
        }
    }

    handleDepartureDateChange(event){
        this.departureDate = event.target.value;
        if(this.orderRequest && this.isDeparture) {
            this.loadFlightData(this.departureDate, this.orderRequest.Booking__r.Service_Airport__c, this.orderRequest.Booking__r.Arriving_Airport__c);
        }
        else if(this.bookingData && this.isDeparture){
            this.loadFlightData(this.departureDate, this.bookingData.serviceAirport, this.bookingData.arrivingAirport);
        }
    }

    handleTransitArrivalDateChange(event){
        this.arrivalDate = event.target.value;
        this.flightNumberArrival = '';
        this.staTime = '';
            this.loadTransitFlightData(this.arrivalDate, this.bookingData.departureAirport, '');
    }
    handleTransitDepartureDateChange(event){
        debugger;
        this.departureDate = event.target.value;
        this.flightNumberDeparture = '';
        this.stdTime  = '';
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
    }

    closeModal() {
        this.showSummary = false;
        this.confirmRescheduling = false;
        // Dispatch an event to close the LWC component
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    async generatePdf() {
        // Call Apex method to generate and save PDF with the current record
        await generateAndSavePDF({ recordId: this.recordId})
            .then((result) => {
                this.isLoading = false;                
                this.showToast('Success', 'Booking Voucher created successfully', 'success');
            })
            .catch((error) => {
                this.showToast('Error', 'Error while generating Voucher', 'error');
                console.error(error);
                this.isLoading = false;
                this.closeModal();
            });
    }
    
    async handleSendEmail() {
        await sendEmailWithAttachment({ opportunityId: this.recordId, actionType: 'Rescheduled',   })
            .then(() => {
                this.showToast('Success', 'Email sent successfully!', 'success');
                this.isLoading = false;
                this.closeModal();
                this.handleCloseComponent();
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
                this.isLoading = false;
                this.closeModal();
            });
    }

    async paymentLinkHandler() {
        await generatePaymentLink({ oppId: this.recordId})
            .then(() => {
                this.showToast('Success', 'Email sent successfully!', 'success');
                this.isLoading = false;
                this.closeModal();
                this.handleCloseComponent();
                this.dispatchEvent(new RefreshEvent());
				//this.handleSendEmail();
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
                this.isLoading = false;
                this.closeModal();
            });
    }

    async completeOrderRequestHandler() {
        await updateDataFromOrderRequest({ opportunityIds: [this.recordId]})
            .then(() => {
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
                this.isLoading = false;
            });
    }

    handleCloseComponent() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view'
            }
        });
    }

    get isPreviewMode() {
        return this.mode === 'preview';
    }
    get isCloneMode() {
        return this.mode === 'clone';
    }

    @wire(getRescheduleOrderRequest, { orderRecId: '$orderId' })
    wiredOrderRequest({ data, error }) {
        if (data) {
            this.orderRequest = data;
            if(this.orderRequest.Service_Type__c == 'Arrival') {
                this.isArrival = true;
                this.flightNumber = this.orderRequest.Flight_Number_Arrival__c;
                this.arrivalDate= this.orderRequest.Date_of_Arrival__c;
                this.staTime = this.orderRequest.Arrival_Service_Time__c;
                this.serviceTime = this.orderRequest.Arrival_Service_Time__c;
            } else if(this.orderRequest.Service_Type__c == 'Departure') {
                this.isDeparture = true;
                this.flightNumber = this.orderRequest.Flight_Number_Departure__c;
                this.departureDate= this.orderRequest.Date_of_Departure__c;
                this.stdTime = this.orderRequest.Departure_Service_Time__c;
                this.serviceTime = this.orderRequest.Departure_Service_Time__c;
            }else if(this.orderRequest.Service_Type__c == 'Transit') {
                this.isTransit = true;
                this.flightNumberArrival = this.orderRequest.Flight_Number_Arrival__c;
                this.flightNumberDeparture = this.orderRequest.Flight_Number_Departure__c;
                this.arrivalDate= this.orderRequest.Date_of_Arrival__c;
                this.staTime = this.orderRequest.Arrival_Service_Time__c;
                this.departureDate= this.orderRequest.Date_of_Departure__c;
                this.stdTime = this.orderRequest.Departure_Service_Time__c;
                this.serviceTime = this.orderRequest.Departure_Service_Time__c;
            }
            this.error = undefined;
        } else if (error) {
            this.error = 'Error fetching order request';
            this.orderRequest = undefined;
        }
    }
    
}