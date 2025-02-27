import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getOpportunityDetails from '@salesforce/apex/FlightPreview.getOpportunityDetails';
import saveData from '@salesforce/apex/FlightPreview.saveData';

export default class FlightBookingPreview extends NavigationMixin(LightningElement) {
    @api opp;
    @track adultCount = 1;
    @track childCount = 0;
    @track infantCount = 0;
    @track opportunityFieldValues = {};
    bookingData;
    isArrival=false;
    isDeparture=false;
    isTransit=false;

    connectedCallback() {
        window.scrollTo({top: 0, behavior:'smooth'});
        this.loadBookingData();
    }

    renderedCallback() {
        window.scrollTo({top: 0, behavior:'smooth'});
    }

    loadBookingData() {
        getOpportunityDetails({opportunityId: this.opp})
        .then((result) => {
            this.bookingData = result;
            this.adultCount = result.NoOfAdult;
            this.childCount = result.NoOfChild;
            this.infantCount = result.NoOfInfant;
            if(this.bookingData.serviceType == 'Arrival') {
                this.isArrival = true;
            } else if(this.bookingData.serviceType == 'Departure') {
                this.isDeparture = true;
            }else if(this.bookingData.serviceType == 'Transit') {
                this.isTransit = true;
            }
        })
        .catch((error) => {
            console.error(error);
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

    handleSave() {
        this.opportunityFieldValues['Number_of_Adults__c'] = this.adultCount;
        this.opportunityFieldValues['Number_of_Children__c'] = this.childCount;
        this.opportunityFieldValues['Number_of_Infants__c'] = this.infantCount;
        saveData({ oppId: this.opp, opportunityFieldValues: this.opportunityFieldValues })
        .then((opportunityId) => {
            

            const messageEvent = new CustomEvent('buttonclick', {
                detail: this.opp,  // The message sent to the parent
                bubbles: true,    // Allow the event to propagate up to the parent
                composed: true    // Allow the event to cross the shadow DOM boundary
            });            
            // Dispatch the custom event
            this.dispatchEvent(messageEvent);
        })
        .catch((error) => {
            console.log('error->>>>>>>'+JSON.stringify(error));
        });
    }
}