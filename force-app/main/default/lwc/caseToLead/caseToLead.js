import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';

import getCaseFields from '@salesforce/apex/CaseTriggerHandler.getCaseFields';

export default class CaseToLead extends NavigationMixin(LightningElement) {
    @api recordId;
    isLoading = true;
    hasNavigated = false;
    isRecordIdReady = false;

    // Step 1: Wire to detect when recordId is ready
    @wire(getCaseFields, { caseId: '$recordId' })
    handleWire(response) {
        if (this.recordId && !this.isRecordIdReady) {
            console.log('RecordId received via wire:', this.recordId);
            this.isRecordIdReady = true;
            this.callNavigationLogic();
        }
    }

    connectedCallback() {
        // Check if recordId is available and no navigation has been made
        if (this.recordId && !this.hasNavigated) {
            console.log('Connected Callback Loaded');
            this.callNavigationLogic();
        }
    }

    callNavigationLogic() {
        // Fetch case data using Apex call
        getCaseFields({ caseId: this.recordId })
            .then(data => {
                console.log('Case Data:', JSON.stringify(data));

                // Encode default field values for Lead creation
                const defaultFieldValues = encodeDefaultFieldValues({
                    Subject__c: data.Subject,
                    Description__c: data.Description,
                    Phone: data.SuppliedPhone,
                    Email: data.SuppliedEmail,
                    FirstName: data.SuppliedName?.trim().split(' ')[0] || 'Unknown',
                    LastName: data.SuppliedName?.trim().split(' ').slice(1).join(' ') || 'Unknown',
                    Case__c: data.Id,
                    Case_Number__c: data.CaseNumber,
                    LeadSource: data.Origin?.trim() || 'Other', // Handle null or undefined Origin
                });

                // Ensure navigation happens only once
                this.hasNavigated = true;

                // Navigate to the new Lead creation page with default field values
                this[NavigationMixin.Navigate]({
                    type: 'standard__objectPage',
                    attributes: {
                        objectApiName: 'Lead',
                        actionName: 'new'
                    },
                    state: {
                        defaultFieldValues,   // Passing the encoded field values
                        useRecordTypeCheck: 1 // Use the record type selection screen
                    }
                });

                // Hide loading spinner once navigation starts
                this.isLoading = false;
            })
            .catch(error => {
                console.error('Error fetching Case fields:', error);
                this.isLoading = false;

                // Display an error message to the user if something goes wrong
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'There was an issue fetching the case details.',
                        variant: 'error',
                    })
                );
            });
    }
}