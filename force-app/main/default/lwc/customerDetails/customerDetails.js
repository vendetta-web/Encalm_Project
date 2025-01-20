import { LightningElement, wire, api } from 'lwc';
import PortfolioAssets from '@salesforce/resourceUrl/PortfolioAssets'
import getRelatedRecordsCount from '@salesforce/apex/AccountRelatedRecordsController.getRelatedRecordsCount';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi'
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import ACCOUNT_NAME_FIELD from '@salesforce/schema/Account.Name';
import ACCOUNT_PHONE_FIELD from '@salesforce/schema/Account.Phone';
import ACCOUNT_EMAIL_FIELD from '@salesforce/schema/Account.PersonEmail';
export default class CustomerDetails extends LightningElement {

    userPic = `${PortfolioAssets}/PortfolioAssets/userPic.jpeg`
    cert_logo = `${PortfolioAssets}/PortfolioAssets/cert_logo.png`
    badge = `${PortfolioAssets}/PortfolioAssets/badge.png`
    accountData;
    error;
    totalCases = 'N/A';
    totalLeads = 'N/A';
    totalOpportunities = 'N/A';
    @api recordId;
    @wire(getRecord, { recordId: '$recordId', fields: [ACCOUNT_NAME_FIELD, ACCOUNT_PHONE_FIELD, ACCOUNT_EMAIL_FIELD] })
    wiredAccount({ error, data }) {
        if (data) {
            this.accountData = data; this.error = undefined;
        } else if (error) {
            this.accountData = undefined;
            this.error = error;
        }
    }

    @wire(getRelatedRecordsCount, { accountId: '$recordId' })
    wiredRelatedRecordsCount({ error, data }) {
        if (data) {
            this.totalCases = data.TotalCases;
            this.totalOpportunities = data.TotalOpportunities;
            this.totalLeads = data.TotalLeads; 
        } else if (error) { this.error = error; }
    }



    get accountName() {
        return this.accountData && this.accountData.fields.Name ? this.accountData.fields.Name.value : '';
    }
    get accountPhone() {
        return this.accountData && this.accountData.fields.Phone ? this.accountData.fields.Phone.value : '';
    }
    get accountEmail() {
        return this.accountData && this.accountData.fields.PersonEmail ? this.accountData.fields.PersonEmail.value : '';
    }
}