import { LightningElement, api, wire, track } from 'lwc';
import { subscribe, unsubscribe } from 'lightning/empApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import INQUIRY_TYPE_FIELD from '@salesforce/schema/Case.Inquiry_Type__c';
import STATUS_FIELD from '@salesforce/schema/Case.Status';

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
            console.log('New message received: ', JSON.stringify(response));
            this.handleMessage(response);
        };
        subscribe(this.channelName, -1, messageCallback).then(response => {
            console.log('Subscribed to: ', JSON.stringify(response.channel));
            this.subscription = response;
        });
    }

    handleUnsubscribe() {
        if (this.subscription) {
            unsubscribe(this.subscription, (response) => {
                console.log('Unsubscribed: ', JSON.stringify(response));
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

    handleSubmit(event) {
    event.preventDefault();
    const fields = event.detail.fields;
    fields.Id = this.recordId;
    fields[STATUS_FIELD.fieldApiName] = 'Closed';

    // Submit form (this already updates the record)
    this.template.querySelector('lightning-record-edit-form').submit(fields);

    // Show success message only after submission
    this.dispatchEvent(
        new ShowToastEvent({
            title: 'Success',
            message: 'Case updated successfully.',
            variant: 'success',
        })
    );

    this.openPopup = false;
}

}