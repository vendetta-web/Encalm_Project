import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

// Fields to fetch from the Account record
const FIELDS = [
    'Account.Name',
    'Account.Phone',
    'Account.Email',
    'Account.Rating',
    'Account.Customer_Type__c',
    'Account.Total_Bookings__c',
    'Account.Baggage_Reports__c', 
    'Account.Feedback_Reports__c' 
];

export default class CustomerDetails extends LightningElement {
    @api recordId; 
    account;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredAccount({ error, data }) {
        if (data) {
            this.account = data.fields;
        } else if (error) {
            console.error('Error fetching Account record:', error);
        }
    }

    get customerName() {
        return this.account?.Name?.value;
    }

    get phone() {
        return this.account?.Phone?.value;
    }

    get email() {
        return this.account?.Email?.value;
    }

    get rating() {
        return this.account?.Rating?.value;
    }

    get customerType() {
        return this.account?.Customer_Type__c?.value;
    }

    get totalBookings() {
        return this.account?.Total_Bookings__c?.value;
    }

    get totalBaggageReports() {
        return this.account?.Baggage_Reports__c?.value;
    }

    get totalFeedbackReports() {
        return this.account?.Feedback_Reports__c?.value;
    }
}