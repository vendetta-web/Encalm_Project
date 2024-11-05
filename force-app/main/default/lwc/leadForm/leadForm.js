import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class LeadForm extends LightningElement {
     @api recordId;

    handleSuccess() {
        const evt = new ShowToastEvent({
            title: 'Success',
            message: 'Lead updated successfully!',
            variant: 'success',
        });
        this.dispatchEvent(evt);
    }

    handleCancel() {
    }
}