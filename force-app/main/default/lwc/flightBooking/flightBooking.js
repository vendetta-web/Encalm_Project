import { LightningElement , wire , track, api} from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAirportDetails from '@salesforce/apex/Encalm_BookingEngine.getAirportDetails';
import getFlightDetails from '@salesforce/apex/Encalm_BookingEngine.getFlightDetails';
import getAirport from '@salesforce/apex/Flight_Booking_encalm.getAirport';
import getTransitFlightDetails from '@salesforce/apex/Encalm_BookingEngine.getTransitFlightDetails';
import convertLead from '@salesforce/apex/LeadConversionController.convertLead';
import getFlightInfo from '@salesforce/apex/Flight_Booking_encalm.getFlightInfo';
import createOpportunity from '@salesforce/apex/Flight_Booking_encalm.createOpportunity';
export default class FlightBooking extends NavigationMixin(LightningElement) {
    @api recordId;
    accountId='';
 airportOptions = [];
 flightNumbers = [];
 baseAirportOptions;
 flightNumberOptions;
 flightNumberOptionsArrival;
 flightNumberOptionsDeparture;
 allAirportOptions;
 allAirportOptionsDepTo;
 allAirportOptionsArrFrom;
 flightSchedule = new Map();;
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
    transitVia;
    arrivingFrom;
sectorOption = [
    {label : 'Domestic', value : 'Domestic'},
    {label: 'International', value : 'International'},
    {label: 'Domestic to International', value : 'Domestic to International'},
    {label: 'Domestic to Domestic', value : 'Domestic to Domestic'},
    {label: 'International to Domestic', value : 'International to Domestic'},
    {label: 'International to International', value : 'International to International'},
]
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
        console.log('Data = ' ,    data );
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
            this.flightSchedule = new Map(Object.entries(result.flightPicklist));
            console.log('result->> '+JSON.stringify(result));
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
    departureAirport = '';
    transitAirport = '';
    arrivalDate ;
    departureDate;
    flightNumber = '';
    flightNumberArrival='';
    flightNumberDeparture='';
    staTime = '';
    stdTime = '';
    serviceTime = '';
    sector='';

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
       if(this.isTabOne){
        this.loadFlightData(this.arrivalDate, this.departureAirport, this.arrivingAirport);
    }
          /*getFlightInfo({arrivalDate:event.target.value})
          .then(result => {
              console.log('result------------>',result)
                this.flightNumbers = result.map(each => ({
                label: each.Flight_Number__c,
                value: each.Flight_Number__c
            }));
            result.map(each => 
            this.myMap.set(each.Flight_Number__c,each)    
            )
            })
            .catch(error => {
                console.error('Error fetching accounts:', error);
                
            });
          console.log(' this.myMap -------->', this.myMap );
      */
    }
    handleDepartureDateChange(event){
        this.departureDate = event.target.value;
        if(this.isTabTwo){
            this.loadFlightData(this.departureDate, this.arrivingAirport, this.departureAirport);
        }
    }

    handleFlightNumberChange(event) { 
        this.flightNumber = event.target.value;
        
        if(this.isTabOne){
            this.setStaTime();
            if (this.flightNumber !='' && this.flightSchedule.has(this.flightNumber)) {
                this.opportunityFieldValues['Arriving_Flight_Schedule__c'] = this.flightSchedule.get(this.flightNumber);
            }
        }else if(this.isTabTwo) {
            this.setStdTime();
            if (this.flightNumber !='' && this.flightSchedule.has(this.flightNumber)) {
                this.opportunityFieldValues['Departure_Flight_Schedule__c'] = this.flightSchedule.get(this.flightNumber);
            }
        }
        /*if( this.myMap.has(event.target.value)){
              
            
           const sta =  this.myMap.get(event.target.value);
           console.log('----------sta-----',sta);
            
           this.staTime =  this.formatTime(sta.STA__c);;
        }
        console.log('------------',this.flightNumber);*/
         }
    formatTime(milliseconds,hrs,mns) {
        const adjustedMillis = milliseconds - (hrs * 3600000) - (mns * 60000);
        const date = new Date(adjustedMillis);
        const hours = String(date.getUTCHours()).padStart(2, '0');
        const minutes = String(date.getUTCMinutes()).padStart(2, '0');
        return `${hours}:${minutes}`; // Format as HH:MM
    }
    handleSave(event){
        this.handleConvertLead();
        /*console.log('---jjjjjjjjjjjjjjjjjjjjjjjjjjjjj--------->');
        var infantCounts;
        var childCounts;
        var adultCounts;
        var arrivingAirport ;
        var departureAirport
        var sector;
        var flightNumber;
        const comboBoxes = this.template.querySelectorAll('lightning-combobox'); // Select all comboboxes
                comboBoxes.forEach(comboBox => {
                    const fieldId = comboBox.dataset.id; // Get data-id of the combobox
                    if(comboBox.dataset.id == 'arrivingAirportr'){
                    arrivingAirport = comboBox.value;
                    }
                    
                    if(comboBox.dataset.id == 'departureAirport'){
            departureAirport =  comboBox.value;
                    }
                    if(comboBox.dataset.id == 'selectSector'){
                sector = comboBox.value;
                    }
                    if(comboBox.dataset.id == 'flightNumber'){
                    flightNumber = comboBox.value;
                    }
                    console.log('--------------comboBox.dataset.id;----------',comboBox.dataset.id);
                    console.log('===========comboBox.value;=======>',comboBox.value);
                
                });


        const buttons = this.template.querySelectorAll('button'); // Select all comboboxes


        //  buttons.forEach(button => {
                
        //             console.log(' button.dataset.id------------------->', button.dataset.id);
        //             if( button.dataset.id == ''){
        //                      infantCounts  = button.value;
        //             }
        //             if( button.dataset.id == ''){
        //                        childCounts = button.value;
        //             }
        //             if( button.dataset.id == ''){
        //                    adultCounts  = button.value;
        //             }
                    
        //  });
        createOpportunity({arrivingAirport:arrivingAirport,departureAirport:departureAirport,dateOfArrival:this.arrivalDate,sector:sector,flightNumber:flightNumber,infantCount:this.infantCount,childCount:this.childCount,adultCount:this.adultCount})
                .then(result => {
                    console.log('result------------>',result)
                        
                    });
        */
    }

    handleArrivingAirportChange(event) {
        this.arrivingAirport = event.target.value;
        if(this.isTabThree){
            console.log('isTabThree->>>');
            this.setTransitSector();
        } else {
            this.setSector();
        }

    }
    handleDepartureAirportChange(event) {
        this.departureAirport = event.target.value;
        if(this.isTabThree){
            this.setTransitSector();
        } else {
            this.setSector();
        }
    }
 

    handleStaTimeChange(event) { this.staTime = event.target.value; }
    handleStdTimeChange(event) { this.stdTime = event.target.value; }
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
        this.flightNumberArrival = event.target.value; 
        this.setStaTime();
        if (this.flightNumberArrival !='' && this.flightSchedule.has(this.flightNumberArrival)) {
            this.opportunityFieldValues['Arriving_Flight_Schedule__c'] = this.flightSchedule.get(this.flightNumberArrival);
        }
    }
    handleFlightNumberChangeDeparture(event) {
        this.flightNumberDeparture = event.target.value;
        this.setStdTime();
        if (this.flightNumberDeparture !='' && this.flightSchedule.has(this.flightNumberDeparture)) {
            this.opportunityFieldValues['Departure_Flight_Schedule__c'] = this.flightSchedule.get(this.flightNumberDeparture);
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
    } else if ((tempCountryArr != tempCountryTransit) && (tempCountryTransit == tempCountryDep)){
        this.sector = 'International to Domestic';
    } else {
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
}
setStdTime(){
    if (this.flightNumber !='' && this.flightDtaMap.has(this.flightNumber)) {
        this.stdTime = this.formatTime(this.flightDtaMap.get(this.flightNumber),1,30);
    }
    if (this.flightNumberDeparture !='' && this.flightDtaMap.has(this.flightNumberDeparture)) {
        this.stdTime = this.formatTime(this.flightDtaMap.get(this.flightNumberDeparture),1,30);
    }
}
resetFlightDetails(){
    this.flightNumber='';
    this.staTime ='';
    this.stdTime='';
}
resetOnTabChange() {
    this.arrivingAirport = '';
    this.departureAirport = '';
    this.transitAirport='';
    this.flightNumberArrival='';
    this.flightNumberDeparture='';
    this.arrivalDate;  
    this.departureDate;  
    this.flightNumber = '';
    this.staTime = '';
    this.stdTime = '';
    this.serviceTime = '';
    this.sector='';
    this.flightNumberOptionsArrival;
    this.flightNumberOptionsDeparture;
    this.flightNumberOptions;
}
handleAccountRecord(event){
    this.accountId = event.detail['Id'];
}

handleConvertLead() {
    this.opportunityFieldValues['Number_of_Adults__c'] = this.adultCount;
    this.opportunityFieldValues['Number_of_Children__c'] = this.childCount;
    this.opportunityFieldValues['Number_of_Infants__c'] = this.infantCount;
    //this.opportunityFieldValues[''] = this.flightSchedule;
    convertLead({ leadId: this.recordId, accId: this.accountId, opportunityFieldValues: this.opportunityFieldValues })
        .then((opportunityId) => {
            this.showToast('Success', 'Lead converted successfully!', 'success');

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
    const fieldName = event.target.name;
    const fieldValue = event.target.value;

    this.opportunityFieldValues[fieldName] = fieldValue;
}
handleTransitAirportChange(event){
    this.transitAirport = event.target.value;
}
handleTransitArrivalDateChange(event){
    this.arrivalDate = event.target.value;
        this.loadTransitFlightData(this.arrivalDate, this.departureAirport, '');
}
handleTransitDepartureDateChange(event){
    this.departureDate = event.target.value;
        this.loadTransitFlightData(this.departureDate, '', this.arrivingAirport);
}



}