import { LightningElement, api } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';
import { wire } from 'lwc';

export default class FlightBookingDetails extends NavigationMixin(LightningElement) {
    @api recordId; // Opportunity record ID
    showModal = true;

    @wire(CurrentPageReference)
    pageRef;

    connectedCallback() {
        const queryParams = this.pageRef?.state;
        if (queryParams && queryParams.c__openModal) {
            this.showModal = true; // Open modal if the parameter is set
        }
    }

    closeModal() {
        this.showModal = false; // Close the modal
    }
}