import { LightningElement, api, wire } from 'lwc';
import { getRecord, updateRecord  } from 'lightning/uiRecordApi';
import getRelatedCounts from '@salesforce/apex/AccountHelper.getRelatedCounts';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const FIELDS = ['Account.Name', 'Account.Phone', 'Account.Email', 'Account.Profile_Picture__c'];

export default class CustomerDetails extends LightningElement {
    @api recordId; // Account ID passed to the component
    name;
    phone;
    accountEmail;
       profilePictureUrl = '/docs/component-library/app/images/examples/avatar1.jpg';
    travelClass;
    totalBookings = 0;
    totalBaggageReports = 0;
    totalFeedbackReports = 0;

    acceptedFormats = ['.png', '.jpg', '.jpeg'];

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredAccount({ error, data }) {
        if (data) {
            this.name = data.fields.Name.value;
            this.phone = data.fields.Phone.value;
            this.accountEmail = data.fields.Email.value;
            this.profilePictureUrl = data.fields.Profile_Picture__c.value || this.profilePictureUrl;
        } else if (error) {
            console.error(error);
        }
    }

    @wire(getRelatedCounts, { accountId: '$recordId' })
    wiredCounts({ error, data }) {
        if (data) {
            this.totalBookings = data.totalBookings;
            this.totalBaggageReports = data.totalBaggageReports;
            this.totalFeedbackReports = data.totalFeedbackReports;
            this.travelClass = data.travelClass;
        } else if (error) {
            console.error(error);
        }
    }

}