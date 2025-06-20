import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getOpportunityDetails from '@salesforce/apex/FlightPreview.getOpportunityDetails';
import saveData from '@salesforce/apex/FlightPreview.saveData';

export default class FlightBookingPreview extends NavigationMixin(LightningElement) {
    @api opp;
    @api editing;
    @api adultcounts = 1;
    @api childcounts;
    @api infantcounts;
    @track previousAdultCount = 1;
    @track previousChildCount = 0;
    @track previousInfantCount = 0;
    @track opportunityFieldValues = {};
    bookingData;
    isArrival=false;
    isDeparture=false;
    isTransit=false;
    isModalOpen = false;

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
            if(this.bookingData.serviceType == 'Arrival') {
                this.isArrival = true;
            } else if(this.bookingData.serviceType == 'Departure') {
                this.isDeparture = true;
            }else if(this.bookingData.serviceType == 'Transit') {
                this.isTransit = true;
            }
            if (!this.editing) {                    
                this.adultcounts = this.previousAdultCount = result.NoOfAdult;
                this.childcounts = this.previousChildCount = result.NoOfChild;
                this.infantcounts = this.previousInfantCount = result.NoOfInfant;
            }
        })
        .catch((error) => {
            console.error(error);
        });
    }

    incrementAdult() {
        this.adultcounts += 1;
    }

    decrementAdult() {
        if (this.adultcounts > 1) {
            this.adultcounts -= 1;
        }
    }

    incrementChild() {
        this.childcounts += 1;
    }

    decrementChild() {
        if (this.childcounts > 0) {
            this.childcounts -= 1;
        }
    }

    incrementInfant() {
        this.infantcounts += 1;
    }

    decrementInfant() {
        if (this.infantcounts > 0) {
            this.infantcounts -= 1;
        }
    }

    handleSave() {
        if(!this.hasDataChanged()) {
            const event = new CustomEvent('nochange', {
                detail: { message: 'No changes done' }
            });
            this.dispatchEvent(event);
        } if (!this.editing) {
            
            this.opportunityFieldValues['Number_of_Adults__c'] = this.adultcounts;
            this.opportunityFieldValues['Number_of_Children__c'] = this.childcounts;
            this.opportunityFieldValues['Number_of_Infants__c'] = this.infantcounts;

            saveData({ oppId: this.opp, opportunityFieldValues: this.opportunityFieldValues })
                .then(() => {
                })
                .catch((error) => {
                    console.log('error->>>>>>>' + JSON.stringify(error));
                });

                const guestUpdateEvent = new CustomEvent('buttonclick', {
                    detail: {
                        adultCount: this.adultcounts,
                        childCount: this.childcounts,
                        infantCount: this.infantcounts,
                        isEditing: false
                    },
                    bubbles: true,
                    composed: true
                });
            
                this.dispatchEvent(guestUpdateEvent);
        } 
        else {            
                const guestUpdateEvent = new CustomEvent('buttonclick', {
                detail: {
                    adultCount: this.adultcounts,
                    childCount: this.childcounts,
                    infantCount: this.infantcounts,
                    isEditing: true
                },
                bubbles: true,
                composed: true
            });
        
            this.dispatchEvent(guestUpdateEvent);
            
        }
    }

    hasDataChanged() {
        return (
            this.adultcounts !== this.previousAdultCount ||
            this.childcounts !== this.previousChildCount ||
            this.infantcounts !== this.previousInfantCount
        );
    }

    // Open the modal
    openModal() {
        this.isModalOpen = true;
    }

    // Close the modal
    closePopupModal() {
        this.isModalOpen = false;
    }
    // Handle the redirection to the list view
    handleRedirect() {
        // Close the modal first
        this.closePopupModal();
        window.location.reload();
        window.scrollTo({top: 0, behavior:'smooth'});
    }
}