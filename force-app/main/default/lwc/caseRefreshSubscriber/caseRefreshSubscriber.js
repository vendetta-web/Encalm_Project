import { LightningElement, wire, api } from 'lwc';
import { subscribe } from 'lightning/empApi';
import { MessageContext } from 'lightning/messageService';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import REFRESH_FIELD from '@salesforce/schema/Case.refreshCase__c'; 
import CASE_ID_FIELD from '@salesforce/schema/Case.Id';
import LEAD_ID_FIELD from '@salesforce/schema/Lead.Id'
import REFRESH_LEAD from '@salesforce/schema/Lead.refreshLead__c';
import { updateRecord } from 'lightning/uiRecordApi';

export default class CaseRefreshSubscriber extends LightningElement {
    @wire(MessageContext)
    messageContext;

    @api recordId;
    channelName = '/event/RefreshEvent__e';
    subscription = null;

    connectedCallback() {
        console.log('Component initialized with recordId:', this.recordId);
        this.subscribeToPlatformEvent();
    }

    subscribeToPlatformEvent() {
        if (!this.messageContext) {
            console.error('MessageContext is not ready');
            return;
        }

        console.log('Subscribing to platform event:', this.channelName);

        subscribe(this.channelName, -1, (event) => {
            const caseId = event.data.payload.CaseId__c ? event.data.payload.CaseId__c : '';
            const leadId = event.data.payload.LeadId__c ? event.data.payload.LeadId__c : '';
            if (caseId === this.recordId && caseId != null) {
                    this.updateRefreshField();
            } 
            else if(leadId === this.recordId && leadId != null){
                    this.updateLeadField();
            }else {
                console.log('Case ID does not match. No action taken.');
            }
        })
        .then(response => {
            console.log('Subscription successful:', response);
            this.subscription = response;
        })
        .catch(error => {
            console.error('Subscription failed:', error);
        });
    }
    updateRefreshField() {
        const fields = {};
        fields[CASE_ID_FIELD.fieldApiName] = this.recordId;
        fields[REFRESH_FIELD.fieldApiName] = true;

        updateRecord({ fields })
            .then(() => {
                console.log('Case field updated successfully.');
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Success",
                        message: "Email received.",
                        variant: "success"
                    })
                );
            })
            .catch(error => {
                console.error('Error updating case field:', error);
            });
    }
    updateLeadField() {
        const fields = {};
        fields[LEAD_ID_FIELD.fieldApiName] = this.recordId;
        fields[REFRESH_LEAD.fieldApiName] = true;

        updateRecord({ fields })
            .then(() => {
                console.log('Lead field updated successfully.');
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Success",
                        message: "Email received.",
                        variant: "success"
                    })
                );
            })
            .catch(error => {
                console.error('Error updating case field:', error);
            });
    }
}