import { LightningElement, wire, api } from 'lwc';
import getStatusChanges from '@salesforce/apex/TimestampChangeController.getStatusChanges';

export default class Timestamp extends LightningElement {
    @api recordId; // Record ID of the Case

    statusChanges;

    @wire(getStatusChanges, { caseId: '$recordId' })
    wiredStatusChanges({ error, data }) {
        if (data) {
            this.statusChanges = data;
        } else if (error) {
            this.statusChanges = undefined;
            console.error('Error fetching status changes', error);
        }
    }
}