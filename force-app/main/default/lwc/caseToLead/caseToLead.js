import { LightningElement, api, wire } from 'lwc';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
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
    caseData;
    error;
    caseStatusMessage = '';
    actionMessage = '';

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredCase({ error, data }) {
        if (data) {
            this.caseData = data.fields;
            this.caseStatusMessage = this.getStatusMessage(this.caseData.Status.value, this.caseData.Subject.value);
            this.navigateToLeadWithPrefill();
        } else if (error) {
            this.error = error;
            this.errorMessage = error?.body?.message || 'Error fetching case data';
        }
    }

    navigateToLeadWithPrefill() {
        const description = this.caseData.Description.value || '';
        const subject = this.caseData.Subject?.value || '';
        
        const name = this.caseData.SuppliedName?.value || '';
        const email = this.caseData.SuppliedEmail?.value || '';
        const phone = this.caseData.SuppliedPhone?.value || '';

        const [firstName, ...lastNameParts] = name.split(' ');
        const lastName = lastNameParts.join(' ');

        const { Id, Status } = this.caseData;
        const leadDefaultValues = {
            Case__c: Id?.value,
            Status: Status?.value,
            Description: description,
            Subject: subject,
            Phone: phone,
            Email: email,
            FirstName: firstName ? firstName.trim() : '',
            LastName: lastName ? lastName.trim() : ''
        };

        this[NavigationMixin.Navigate]( {
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Lead',
                actionName: 'new'
            },
            state: {
                defaultFieldValues: this.getDefaultFieldValues(leadDefaultValues)
            }
        });

        setTimeout(() => {
            this.actionMessage = 'The lead creation form is still unfilled.';
            this.closeCase();
        }, 3000);
    }

    getDefaultFieldValues(defaultValues) {
        return Object.entries(defaultValues)
            .map(([field, value]) => `${field}=${encodeURIComponent(value)}`)
            .join(',');
    }

    closeCase() {
        const fields = {};
        fields[CASE_ID.fieldApiName] = this.caseData.Id.value;
        fields[CASE_STATUS.fieldApiName] = 'Closed';
        
        const recordInput = { fields };

        updateRecord(recordInput)
            .then(() => {
                this.caseStatusMessage = 'Case has been closed.';
            })
            .catch(error => {
                this.error = error;
                this.errorMessage = error?.body?.message || 'Error closing the case';
            });
    }

    getStatusMessage(status, subject) {
        if (status === 'New' && subject) {
            return `Case created successfully with subject: "${subject}"`;
        } else if (status === 'Closed') {
            return 'Case has been closed.';
        } else if (status === 'Escalated') {
            return 'Case has been escalated.';
        } else {
            return 'Case status is unknown.';
        }
    }
}