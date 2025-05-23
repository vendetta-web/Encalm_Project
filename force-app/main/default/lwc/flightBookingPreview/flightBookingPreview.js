import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getOpportunityDetails from '@salesforce/apex/FlightPreview.getOpportunityDetails';
import saveData from '@salesforce/apex/FlightPreview.saveData';

export default class FlightBookingPreview extends NavigationMixin(LightningElement) {
    @api opp;
    @api editing;
    @track adultCount = 1;
    @track childCount = 0;
    @track infantCount = 0;
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
            this.adultCount = this.previousAdultCount = result.NoOfAdult;
            this.childCount = this.previousChildCount = result.NoOfChild;
            this.infantCount = this.previousInfantCount = result.NoOfInfant;
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
        if(!this.hasDataChanged()) {
            const event = new CustomEvent('nochange', {
                detail: { message: 'No changes done' }
            });
            this.dispatchEvent(event);
        } else {            
                const guestUpdateEvent = new CustomEvent('buttonclick', {
                detail: {
                    adultCount: this.adultCount,
                    childCount: this.childCount,
                    infantCount: this.infantCount
                },
                bubbles: true,
                composed: true
            });
        
            this.dispatchEvent(guestUpdateEvent);
            
        }
    }

    hasDataChanged() {
        return (
            this.adultCount !== this.previousAdultCount ||
            this.childCount !== this.previousChildCount ||
            this.infantCount !== this.previousInfantCount
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