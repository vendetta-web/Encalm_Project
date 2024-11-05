import { LightningElement , wire , track} from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';

import getAirport from '@salesforce/apex/Flight_Booking_encalm.getAirport';
import getFlightInfo from '@salesforce/apex/Flight_Booking_encalm.getFlightInfo';
import createOpportunity from '@salesforce/apex/Flight_Booking_encalm.createOpportunity';
export default class FlightBooking extends NavigationMixin(LightningElement) {
 airportOptions = [];
 flightNumbers = [];
 myMap = new Map();
  @track adultCount = 1;
    @track childCount = 0;
    @track infantCount = 0;
    departureDate;
    transitVia;
    arrivingFrom;
sectorOption = [
    {label : 'Domestic', value : 'Domestic'},
    {label: 'International', value : 'International'}
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


qtyVal = 0;
    //activeTab ;
    isTabOne = true;
    isTabTwo = false;
    isTabThree = false;

    // Flight details fields
    arrivingAirport = '';
    departureAirport = '';
    arrivalDate ;
    flightNumber = '';
    staTime = '';
    serviceTime = '';

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
        } if(event.target.value== 'Depature'){
          this.isTabOne = false;
              this.isTabTwo = true;
               this.isTabThree  = false;
        }
        if(event.target.value== 'Transit'){
            this.isTabOne = false;
              this.isTabTwo = false;
               this.isTabThree  = true;
        }
        console.log('this.activeTab============>')
    }

   handleArrivalDateChange(event) { 
       this.arrivalDate = event.target.value;
          getFlightInfo({arrivalDate:event.target.value})
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
      
           
        

    }

    handleFlightNumberChange(event) { 
        this.flightNumber = event.target.value;
        if( this.myMap.has(event.target.value)){
              
            
           const sta =  this.myMap.get(event.target.value);
           console.log('----------sta-----',sta);
            
           this.staTime =  this.formatTime(sta.STA__c);;
        }
        console.log('------------',this.flightNumber);
         }
 formatTime(milliseconds) {
        const date = new Date(milliseconds);
        const hours = String(date.getUTCHours()).padStart(2, '0');
        const minutes = String(date.getUTCMinutes()).padStart(2, '0');
        return `${hours}:${minutes}`; // Format as HH:MM
    }
handleSave(event){
console.log('---jjjjjjjjjjjjjjjjjjjjjjjjjjjjj--------->');
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
}




    handleArrivingAirportChange(event) { this.arrivingAirport = event.target.value; }
    handleDepartureAirportChange(event) { this.departureAirport = event.target.value; }
 

    handleStaTimeChange(event) { this.staTime = event.target.value; }
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








}