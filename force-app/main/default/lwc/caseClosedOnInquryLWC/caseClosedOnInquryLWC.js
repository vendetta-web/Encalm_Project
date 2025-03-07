import { LightningElement, api, wire, track } from 'lwc';
import { subscribe, unsubscribe } from 'lightning/empApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import INQUIRY_TYPE_FIELD from '@salesforce/schema/Case.Inquiry_Type__c';
import STATUS_FIELD from '@salesforce/schema/Case.Status';
import ID_FIELD from '@salesforce/schema/Case.Id';

export default class CaseClosedOnInquiryLWC extends LightningElement {
    channelName = '/data/CaseChangeEvent';
    subscription = null;
    @api recordId;
    @track openPopup = false;

    @wire(getRecord, { recordId: '$recordId', fields: [INQUIRY_TYPE_FIELD] })
    caseRecord;

    get inquiryType() {
        return this.caseRecord?.data?.fields?.Inquiry_Type__c?.value || '';
    }

    renderedCallback() {
        if (!this.subscription) {
            this.handleSubscribe();
        }
    }

    handleSubscribe() {
        const messageCallback = (response) => {
            console.log('New message received:', JSON.stringify(response));
            if( JSON.stringify(response)){
             this.openPopup = false;
            }
            this.handleMessage(response);
        };

        subscribe(this.channelName, -1, messageCallback).then(response => {
            console.log('Subscribed to:', response.channel);
            this.subscription = response;
        });
    }

    handleUnsubscribe() {
        if (this.subscription) {
            unsubscribe(this.subscription, (response) => {
                console.log('Unsubscribed:', response);
                this.subscription = null;
            });
        }
    }

    handleMessage(response) {
        if (response?.data?.payload) {
            const payload = response.data.payload;
            if (payload.Inquiry_Type__c && payload.ChangeEventHeader?.recordIds) {
                const currentRecordId = payload.ChangeEventHeader.recordIds.includes(this.recordId);
                if (currentRecordId && payload.Inquiry_Type__c !== 'Booking') {
                    this.openPopup = true;
                }
            }
        }
    }

    hideModalBox(event) {
        event.preventDefault();
        this.openPopup = false;
    }

    async handleSubmit(event) {
        event.preventDefault();
        this.openPopup = false; // **Ensure modal closes immediately**

        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[STATUS_FIELD.fieldApiName] = 'Closed';

        const recordInput = { fields };

        try {
            await updateRecord(recordInput);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Case updated successfully.',
                    variant: 'success',
                })
            );
        } catch (error) {
            console.error('Error updating case:', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error?.body?.message || 'Unknown error occurred.',
                    variant: 'error',
                })
            );
        }
    }
}