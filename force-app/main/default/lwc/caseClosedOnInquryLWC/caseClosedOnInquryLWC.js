import { LightningElement, api } from 'lwc';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CaseClosedOnInquryLWC extends LightningElement {
    channelName = '/data/CaseChangeEvent';
    subscription = {};
    @api recordId;

    subscribed;
    openPopup = false;

    // Tracks changes to channelName text field
    handleChannelName(event) {
        this.channelName = event.target.value;
    }

    renderedCallback() {
        if (!this.subscribed) {
            this.handleSubscribe();
            this.subscribed = true;
        }
    }

    // Initializes the component
    connectedCallback() {
        // Register error listener
        this.registerErrorListener();

    }

    // Handles subscribe button click
    handleSubscribe() {
        // Callback invoked whenever a new event message is received
        const messageCallback = (response) => {
            console.log('New message received: ', JSON.stringify(response));
            // Response contains the payload of the new message received
            this.handleMessage(response);
        };

        // Invoke subscribe method of empApi. Pass reference to messageCallback
        subscribe(this.channelName, -1, messageCallback).then(response => {
            // Response contains the subscription information on subscribe call
            console.log('Subscription request sent to: ', JSON.stringify(response.channel));
            this.subscription = response;
        });
    }

    // Handles unsubscribe button click
    handleUnsubscribe() {
        // Invoke unsubscribe method of empApi
        unsubscribe(this.subscription, (response) => {
            this.openPopup = false;

            console.log('unsubscribe() response: ', JSON.stringify(response));
            // Response is true for successful unsubscribe
        });
    }

    registerErrorListener() {
        // Invoke onError empApi method
        onError((error) => {
            this.openPopup = false;

            console.log('Received error from server: ', JSON.stringify(error));
            // Error contains the server-side error
        });
    }
    hideModalBox(event) {
        event.preventDefault();
        //event.stopPropagation(); 
        this.openPopup = false;
    }

    handleMessage(response) {
        if (response) {
            if (response.hasOwnProperty('data')) {
                let responsePayload = response.data.payload;
                if (responsePayload.hasOwnProperty('Inquiry_Type__c') && responsePayload.hasOwnProperty('ChangeEventHeader')) {
                    if (responsePayload.ChangeEventHeader.hasOwnProperty('recordIds') && responsePayload.Inquiry_Type__c !== null) {
                        let currentRecordId = responsePayload.ChangeEventHeader.recordIds.find(element => element == this.recordId);
                        console.log('80 currentRecordId', currentRecordId + ' responsePayload.Inquiry_Type__c ' + responsePayload.Inquiry_Type__c);
                        console.log('responsePayload.Inquiry_Type__c ' + responsePayload.Inquiry_Type__c !== 'Booking');
                        if (currentRecordId && responsePayload.Inquiry_Type__c !== 'Booking') {
                            console.log('82 currentRecordId', currentRecordId);

                            this.openPopup = true;
                            console.log('85 openPopup', this.openPopup);

                        }
                    }

                }
            }
        }

    }

    /* handleMessage(response) {
     if (response && response.hasOwnProperty('data')) {
         let responsePayload = response.data.payload;
 
         if (responsePayload.hasOwnProperty('Inquiry_Type__c') && responsePayload.hasOwnProperty('ChangeEventHeader')) {
             if (responsePayload.ChangeEventHeader.hasOwnProperty('recordIds') && responsePayload.Inquiry_Type__c !== null) {
                 let currentRecordId = responsePayload.ChangeEventHeader.recordIds.find(element => element == this.recordId);
                 
                 console.log('currentRecordId:', currentRecordId);
                 console.log('Inquiry_Type__c:', responsePayload.Inquiry_Type__c);
 
                 // Check if Inquiry_Type__c is either 'Feedback' or 'Query'
                 if (currentRecordId && (responsePayload.Inquiry_Type__c === 'Feedback' || responsePayload.Inquiry_Type__c === 'Query')) {
                     this.openPopup = true;
                     console.log('Popup Opened:', this.openPopup);
                 } else {
                     this.openPopup = false; // Ensure popup does not open for other values
                 }
             }
         }
     }
 } */

    handleSubmit(event) {
        event.preventDefault();
        // Get data from submitted form
        const fields = event.detail.fields;
        // Here you can execute any logic before submit
        // and set or modify existing fields
        fields.Status = 'Closed';

        // You need to submit the form after modifications
        this.template
            .querySelector('lightning-record-edit-form').submit(fields);
        this.openPopup = false;

    }

    handleError(event) {
        console.log("handleError event");
        console.log(JSON.stringify(event.detail));
    }
}