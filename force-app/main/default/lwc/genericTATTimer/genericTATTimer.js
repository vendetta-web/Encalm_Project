import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import getBusinessTimeRemaining from '@salesforce/apex/TATBusinessHourService.getBusinessTimeRemaining';

import STATUS_FIELD from '@salesforce/schema/Lead.Status';
import ESCALATION_LEVEL_FIELD from '@salesforce/schema/Lead.Escalation_Level__c';
import RECORDTYPE_FIELD from '@salesforce/schema/Lead.RecordType.DeveloperName';

export default class GenericTATTimer extends LightningElement {
    @api recordId;
    @track status = '';
    @track escalationLevel = '';
    @track recordType = '';
    @track remaining = 'Loading...';
    @track hideTat = true;

    intervalId;
    serverPollId;
    deadlineTime = null;
    paused = false;
    frozenDiffMs = null;

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [STATUS_FIELD, ESCALATION_LEVEL_FIELD, RECORDTYPE_FIELD]
    })
    loadLead({ data, error }) {
        if (data) {
            clearInterval(this.intervalId);
            clearInterval(this.serverPollId);

            this.status = data.fields.Status?.value;
            const escalationLevel = data.fields.Escalation_Level__c?.value;
            this.recordType = data.fields.RecordType?.value?.fields?.DeveloperName?.value;

            this.hideTat = true;

            if (escalationLevel === 'Level 1') {
                this.escalationLevel = 'Agent Escalation - Escalated to manager due to no action taken';
                if (this.status === 'Open' || (this.status === 'Customer Responded' && this.recordType != 'Sales')) {
                    this.hideTat = false;
                    this.startCountdown();
                }
            } else if (escalationLevel === 'Level 2') {
                this.escalationLevel = 'Executive Escalation - Escalated to manager due to no action taken';
                if (this.status === 'Escalated') {
                    this.hideTat = false;
                    this.startCountdown();
                }
            }
        } else if (error) {
            this.remaining = 'Error loading lead';
            console.error('Error loading lead:', error);
        }
    }

    startCountdown() {
        this.fetchRemainingTime(); // Initial server sync

        // Client-side display tick every second
        this.intervalId = setInterval(() => {
            if (this.paused) {
                // Show the same frozen time (don’t update)
                if (this.frozenDiffMs !== null) {
                    this.updateDisplay(this.frozenDiffMs);
                }
                return;
            }

            if (!this.deadlineTime) return;

            const diffMs = this.deadlineTime - Date.now();
            if (diffMs <= 0) {
                this.remaining = 'TAT Expired';
                clearInterval(this.intervalId);
                clearInterval(this.serverPollId);
                return;
            }

            this.updateDisplay(diffMs);
        }, 1000);

        // Server-side sync every 15 seconds
        this.serverPollId = setInterval(() => {
            this.fetchRemainingTime();
        }, 15000);
    }

    async fetchRemainingTime() {
        try {
            const result = await getBusinessTimeRemaining({ leadId: this.recordId });

            if (result.startsWith('PAUSED')) {
                const [_, timestampStr] = result.split('|');
                const pausedDeadline = parseInt(timestampStr, 10);

                this.paused = true;

                // ✅ Cache frozen time difference ONCE during pause
                if (this.frozenDiffMs === null) {
                    this.frozenDiffMs = pausedDeadline - Date.now();
                }

                // ⏸️ Display frozen time only (doesn't decrease)
                this.updateDisplay(this.frozenDiffMs);
            }

            else if (result.startsWith('RUNNING')) {
                const [_, timestampStr] = result.split('|');
                this.deadlineTime = parseInt(timestampStr, 10);
                this.paused = false;

                // ✅ Clear any cached frozen time when resuming
                this.frozenDiffMs = null;

                const diffMs = this.deadlineTime - Date.now();
                this.updateDisplay(diffMs);
            }

            else if (result === 'NO_DEADLINE') {
                this.remaining = 'No TAT deadline set';
                clearInterval(this.intervalId);
                clearInterval(this.serverPollId);
            }

            else if (result === 'EXPIRED') {
                this.remaining = 'TAT Expired';
                clearInterval(this.intervalId);
                clearInterval(this.serverPollId);
            }

            else if (result.startsWith('ERROR')) {
                this.remaining = result;
                clearInterval(this.intervalId);
                clearInterval(this.serverPollId);
            }

        } catch (e) {
            this.remaining = 'Error';
            clearInterval(this.intervalId);
            clearInterval(this.serverPollId);
            console.error(e);
        }
    }

    updateDisplay(diffMs) {
        if (diffMs <= 0) {
            this.remaining = 'TAT Expired';
            return;
        }

        const hours = Math.floor(diffMs / 1000 / 60 / 60);
        const minutes = Math.floor((diffMs / 1000 / 60) % 60);
        const seconds = Math.floor((diffMs / 1000) % 60);

        this.remaining = `${hours.toString().padStart(2, '0')}:${minutes
            .toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')} remaining`;
    }

    disconnectedCallback() {
        clearInterval(this.intervalId);
        clearInterval(this.serverPollId);
    }
}