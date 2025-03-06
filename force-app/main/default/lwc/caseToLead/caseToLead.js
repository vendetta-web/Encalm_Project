import { LightningElement, api, wire } from 'lwc';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
//import getLeadsForCase from '@salesforce/apex/LeadFromCaseController.getLeadsForCase';
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
    caseData;
    actionMessage = '';
    isSuccess = true;
    isNavigatingToLead = false;
    openCaseClosedScreen = false;
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredCase({ error, data }) {
        if (data) {
            console.log('DataLine36 : ', JSON.stringify(data));
            this.caseData = data.fields;
            //this.checkIfLeadExists(); 
            console.log('42 ' + this.caseData?.CASE_INQUIRY_TYPE?.value);
            if (this.caseData?.CASE_INQUIRY_TYPE?.value !== 'Booking') {

                console.log('45 ' + this.caseData?.CASE_INQUIRY_TYPE?.value);
                this.openCaseClosedScreenStart();
            } else {
                console.log('49 ' + this.caseData?.CASE_INQUIRY_TYPE?.value);

                this.navigateToLeadWithPrefill();
            }
            // // Directly navigate to lead creation
        } else if (error) {
            this.actionMessage = 'Error fetching Case data.';
            this.isSuccess = false;
        }
    }

    
    openCaseClosedScreenStart() {
        this.openCaseClosedScreen = true;
    }
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
        this.openCaseClosedScreen = false;
        this.navigateToLeadWithPrefill();

    }

    handleError(event) {
        console.log("handleError event");
        console.log(JSON.stringify(event.detail));
    }
    hideModalBox(event) {
        event.preventDefault();
        //event.stopPropagation(); 
        this.openCaseClosedScreen = false;
        this.dispatchEvent(new CloseActionScreenEvent());

    }

   
    // renderedCallback() {
    //     // Insert HTML for success messages
    //     if (this.isSuccess && this.actionMessage) {
    //         const container = this.template.querySelector('.message-container');
    //         if (container) {
    //             container.innerHTML = this.actionMessage;
    //         }
    //     }
    // }

    /*checkIfLeadExists() {
        getLeadsForCase({ caseId: this.caseData.Id.value })
            .then((leads) => {
                if (leads.length > 0) {
                    const leadId = leads[0].Id;
                    this.actionMessage = `A Lead is already created for this Case. Click <a href="/${leadId}" target="_blank">here</a> to view the Lead.`;
                    this.isSuccess = true;
                } else {
                    // If no Lead exists, proceed to navigation
                    this.navigateToLeadWithPrefill();
                }
            })
            .catch((error) => {
                console.error('Error checking Leads:', error);
                this.actionMessage = 'Error checking for existing Leads.';
                this.isSuccess = false;
            });
    }*/

    navigateToLeadWithPrefill() {
        const description = this.caseData?.Description?.value || '';
        const subject = this.caseData?.Subject?.value || '';
        const name = this.caseData?.SuppliedName?.value || '';
        const email = this.caseData?.SuppliedEmail?.value || '';
        const phone = this.caseData?.SuppliedPhone?.value || '';
        const caseId = this.caseData?.Id?.value;
        const caseNumber = this.caseData?.CaseNumber?.value;

        console.log('Navigating to Lead with Case ID:', caseId);
        console.log('Case Number:', caseNumber);

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
        console.log('isNavigatingToLead : ', this.isNavigatingToLead);
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

        // Update Case status to Closed
        // this.updateCaseStatus(caseId);
    }

    // updateCaseStatus(caseId) {
    //     const fields = {};
    //     fields[CASE_ID.fieldApiName] = caseId;
    //     fields[CASE_STATUS.fieldApiName] = 'Closed';

    //     const recordInput = { fields };

    //     updateRecord(recordInput)
    //         .then(() => {
    //             console.log('Case status updated to Closed');
    //             this.actionMessage = 'Case status updated to Closed.';
    //             this.isSuccess = true;
    //         })
    //         .catch(error => {
    //             console.error('Error updating Case status:', error);
    //             this.actionMessage = 'Error updating Case status.';
    //             this.isSuccess = false;
    //         });
    // }

    getDefaultFieldValues(defaultValues) {
        return Object.entries(defaultValues)
            .map(([field, value]) => `${field}=${encodeURIComponent(value)}`)
            .join(',');
    }
}