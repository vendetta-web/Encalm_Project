import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import CASE_ID from '@salesforce/schema/Case.Id';
import CASE_STATUS from '@salesforce/schema/Case.Status';
import CASE_DESCRIPTION from '@salesforce/schema/Case.Description';
import CASE_SUBJECT from '@salesforce/schema/Case.Subject';
import CASE_SUPPLIED_EMAIL from '@salesforce/schema/Case.SuppliedEmail';
import CASE_SUPPLIED_NAME from '@salesforce/schema/Case.SuppliedName';
import CASE_SUPPLIED_PHONE from '@salesforce/schema/Case.SuppliedPhone';

const FIELDS = [CASE_ID, CASE_STATUS, CASE_DESCRIPTION, CASE_SUBJECT, CASE_SUPPLIED_EMAIL, CASE_SUPPLIED_NAME, CASE_SUPPLIED_PHONE];

export default class CaseToLead extends NavigationMixin(LightningElement) {
    @api recordId;
    @track name = '';
    @track age = '';
    @track gender = '';
    caseData;

 @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredCase({ error, data }) {
        if (data) {
            this.caseData = data.fields;
            this.navigateToLeadWithPrefill();
        } else if (error) {
            console.error('Error fetching case data:', error?.body?.message || error);
        }
    }

    navigateToLeadWithPrefill() {
        const description = this.caseData.Description.value || '';
        const subject = this.caseData.Subject?.value || '';
        const nameString = this.extractValue(description, 'Name:');

        const extractedEmail = this.extractValue(description, 'Email:');
        const extractedPhone = this.extractValue(description, 'Phone:');

        const email = this.caseData.SuppliedEmail?.value || extractedEmail;
        const phone = this.caseData.SuppliedPhone?.value || extractedPhone;

        const [firstName, ...lastNameParts] = nameString.split(' ');
        const lastName = lastNameParts.join(' ');

        const { Id, Status } = this.caseData;
        const leadDefaultValues = {
            Case_Id__c: Id?.value,
            Status: Status?.value,
            Description: description,
            Subject: subject,
            Phone: phone,
            Email: email,
            FirstName: firstName ? firstName.trim() : '',
            LastName: lastName ? lastName.trim() : ''
        };

        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Lead',
                actionName: 'new'
            },
            state: {
                defaultFieldValues: this.getDefaultFieldValues(leadDefaultValues)
            }
        });
    }

    extractValue(description, label) {
        const regex = new RegExp(`${label}\\s*([^\\n]*)`, 'i');
        const match = description.match(regex);
        return match ? match[1].trim() : '';
    }

    getDefaultFieldValues(defaultValues) {
        return Object.entries(defaultValues)
            .map(([field, value]) => `${field}=${encodeURIComponent(value)}`)
            .join(',');
    }
}