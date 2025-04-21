// tatTimer.js
import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import TAT_DEADLINE_FIELD from '@salesforce/schema/Lead.TAT_deadline__c';
import CREATED_DATE_FIELD from '@salesforce/schema/Lead.CreatedDate';
import STATUS_FIELD from '@salesforce/schema/Lead.Status';
import ESCALATION_LEVEL_FIELD from '@salesforce/schema/Lead.Escalation_Level__c';

export default class GenericTATTimer extends LightningElement {
    @api recordId;
    tatStart;
    //tatDeadline;
    deadline;
    status = '';
    @track escalationLevel = '';  
    @track remaining = '0';

    @wire(getRecord, { recordId: '$recordId', fields: [TAT_DEADLINE_FIELD,ESCALATION_LEVEL_FIELD,CREATED_DATE_FIELD,STATUS_FIELD] })
    loadLead({ data,error }) {

        if (data) {
            clearInterval(this.intervalId);
            const rawDate = data.fields?.TAT_deadline__c?.value;
            const status = data.fields.Status?.value;
            this.deadline = new Date(rawDate);
            console.log("this.deadline" +  rawDate);
            if (this.deadline) {                
               
                const escalationLevel = data.fields.Escalation_Level__c?.value;
                if(escalationLevel == "Level 1"){
                    this.escalationLevel = "Agent Escalation - Escalated to manager due to no action taken"; 
                    if(status == 'Open')
                        this.startCountdown();
                }
                else if(escalationLevel == "Level 2"){
                    this.escalationLevel = "Executive Escalation - Escalated to manager due to no action taken";
                    if(status == 'Escalated')
                    this.startCountdown();
                }

                
            }
            else {
                this.remaining = 'No TAT deadline set';
            }

            if(status != 'Open' && this.escalationLevel == 'Level 1'){
                this.remaining = 'TAT Completed';
            }
        } else if (error) {
            console.error('Error loading lead:', error);
            this.remaining = 'Error loading TAT';
        }
    }

    startCountdown() {
        this.intervalId = setInterval(() => {
            const now = new Date();
            const diffMs = this.deadline - now;

            if (diffMs <= 0) {
                this.remaining = 'TAT Expired';
                clearInterval(this.intervalId);
            } else {
                const minutes = Math.floor((diffMs / 1000 / 60) % 60);
                const hours = Math.floor((diffMs / 1000 / 60 / 60));
                const seconds = Math.floor((diffMs / 1000) % 60);
                this.remaining = `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')} remaining`;
            }
        }, 1000);
    }

}