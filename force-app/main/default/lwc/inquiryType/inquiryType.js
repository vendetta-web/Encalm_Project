import { LightningElement, api, wire, track } from 'lwc';
import sendEmailToLead from '@salesforce/apex/LeadFromCaseController.sendEmailToLead';
import { CurrentPageReference } from 'lightning/navigation';

export default class InquiryType extends LightningElement {
    @api recordId;
    @track leadData;
    message = '';
    isSuccess = false;
    isConfirmVisible = true;
    isLoading = false;

    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
            console.log('recordId : ', this.recordId);
        } else {
            this.displayMessage('Record Id is not available.', false);
        }
    }

    confirmSendEmail() {
        this.isConfirmVisible = false;
        //this.isLoading = true;
        this.sendEmail();
    }

    cancelSendEmail() {
        this.isConfirmVisible = false;
        this.displayMessage('Email not sent.', false); // Show message if the user cancels
    }

    sendEmail() {
        sendEmailToLead({ leadId: this.recordId })
            .then(() => {
                this.isLoading = false;
                this.displayMessage('Email sent successfully', true);
            })
            .catch((error) => {
                this.isLoading = false;
                this.displayMessage(error.body.message || 'An error occurred while sending the email.', false);
            });
    }

    displayMessage(message, success) {
        this.message = message;
        this.isSuccess = success;
    }

    // Getter to return class dynamically based on success/failure
    get messageClass() {
        return this.isSuccess ? 'success-message slds-box slds-m-bottom_medium slds-p-around_small' :
            'error-message slds-box slds-m-bottom_medium slds-p-around_small';
    }

    // Dynamically set the icon name based on success or failure
    get iconName() {
        return this.isSuccess ? 'utility:success' : 'utility:error';
    }
}