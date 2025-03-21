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
import CASE_NUMBER from '@salesforce/schema/Case.CaseNumber';
import CASE_ORIGIN from '@salesforce/schema/Case.Origin';
import CASE_INQUIRY_TYPE from '@salesforce/schema/Case.Inquiry_Type__c';

import { CloseActionScreenEvent } from 'lightning/actions';

const FIELDS = [
    CASE_ID,
    CASE_NUMBER,
    CASE_STATUS,
    CASE_DESCRIPTION,
    CASE_SUBJECT,
    CASE_SUPPLIED_EMAIL,
    CASE_SUPPLIED_NAME,
    CASE_SUPPLIED_PHONE,
    CASE_ORIGIN,
    CASE_INQUIRY_TYPE

];

export default class CaseToLead extends NavigationMixin(LightningElement) {
    @api recordId;
     resolutionNotes = 'Converted to Lead';
    caseData;
    actionMessage = '';
    isSuccess = true;
    isNavigatingToLead = false;
    openCaseClosedScreen = false;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredCase({ error, data }) {
        if (data) {
            this.caseData = data.fields;
            if (this.caseData?.CASE_INQUIRY_TYPE?.value !== 'Booking') {

                this.updateCaseAndNavigate();
            } else {
                this.navigateToLeadWithPrefill();
            }
            // // Directly navigate to lead creation
        } else if (error) {
            this.actionMessage = 'Error fetching Case data.';
            this.isSuccess = false;
        }
    }

    updateCaseAndNavigate() {
        const fields = {};
        fields.Id = this.recordId;
        //fields.Status = 'Closed';
        fields.Resolution_Notes__c = this.resolutionNotes;

        updateRecord({ fields })
            .then(() => {
                this.navigateToLeadWithPrefill();
            })
            .catch(error => {
                console.error('Error updating case:', error);
            });
    }


    navigateToLeadWithPrefill() {
        const description = this.caseData?.Description?.value || '';
        const subject = this.caseData?.Subject?.value || '';
        const name = this.caseData?.SuppliedName?.value || '';
        const email = this.caseData?.SuppliedEmail?.value || '';
        const phone = this.caseData?.SuppliedPhone?.value || '';
        const caseId = this.caseData?.Id?.value;
        const caseNumber = this.caseData?.CaseNumber?.value;

        const [firstName, ...lastNameParts] = name.split(' ');
        const lastName = lastNameParts.join(' ') || 'Unknown';

        if (!caseId) {
            this.actionMessage = 'Case ID is missing or invalid.';
            this.isSuccess = false;
            return;
        }

        const leadDefaultValues = {
            Description__c: description,
            Subject__c: subject,
            Phone: phone,
            Email: email,
            FirstName: firstName?.trim() || 'Unknown',
            LastName: lastName?.trim(),
            Case__c: caseId,
            Case_Number__c: caseNumber,
            LeadSource: this.caseData?.Origin?.value
        };
        this.isNavigatingToLead = true;
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

    getDefaultFieldValues(defaultValues) {
        return Object.entries(defaultValues)
            .map(([field, value]) => `${field}=${encodeURIComponent(value)}`)
            .join(',');
    }
}