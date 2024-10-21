import { LightningElement, track } from 'lwc';

export default class CreateLeadFromCase extends LightningElement {
    @track showModal = false;

    openModal() {
        this.showModal = true;
    }

    closeModal() {
        this.showModal = false;
    }

    handleSuccess(event) {
        this.closeModal();
        // Optionally, show a toast notification or refresh the view
        const leadId = event.detail.id;
        console.log('Lead created with Id: ' + leadId);
        // Optionally add logic to refresh data or show a success message
    }

    handleError(event) {
        console.error('Error creating Lead: ', event.detail);
        // Optionally show a toast message for the error
    }
}