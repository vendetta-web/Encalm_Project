import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import getOpportunityData from '@salesforce/apex/BookingSummaryController.getOpportunityData';
import getAllOrderRequests from '@salesforce/apex/OrderRequestController.getAllOrderRequests';
import cloneRequest from '@salesforce/apex/OrderRequestController.cloneRequest';
import cancelRequest from '@salesforce/apex/OrderRequestController.cancelRequest';
import getSerializedData from '@salesforce/apex/OrderRequestController.getSerializedData';
import getPaymentLink from '@salesforce/apex/OrderRequestController.generatePaymentLink';
import getStatusChangeDates from '@salesforce/apex/OrderRequestController.getStatusChangeDates';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

const columns = [
    { label: 'Type', fieldName: 'Change_Type__c', flexGrow: 1, minWidth: 150, wrapText: true },
    { label: 'Request Subtype', fieldName: 'Type_of_Amendment__c', flexGrow: 1, minWidth: 150, wrapText: true },
    { label: 'Status', fieldName: 'Status__c', flexGrow: 1, minWidth: 150, wrapText: true },
    { label: 'Created Date', fieldName: 'CreatedDate', type: 'date', flexGrow: 1, minWidth: 150, wrapText: true },
    { label: 'Updated Date', fieldName: 'statusChangedDate', type: 'date' },
    {
        type: 'action',
        typeAttributes: { rowActions: { fieldName: 'rowActions' } },
        initialWidth: 180
    }
];


export default class BookingSummary extends LightningElement {
    @api recordId;
    @track surchrgeCheckbox = false;
    serviceAirport='';
    flightType = '';
    flightNumber = '';
    flightDate = '';
    numberOfAdults = 0;
    numberOfChildren = 0;
    numberOfInfants = 0;

    opportunityData;
    orderSummary = [];
    guestRows = [];
    selectedPassenger;
    flightDetails;
    
    showHeader = true;
    showPreview = true;
    showGst = false;
    showCgst = false;
    showIgst = false;
    showDiscount = false;

    totalAmount = 0;
    totalNetAmount = 0;
    totalCgstAmount = 0;
    totalSgstAmount = 0;
    totalIgstAmount = 0;
    totalDiscountAmount = 0;
    totalAmountAfterDiscount = 0;
    amountMessage = 'Total Payable Amount';

    @track data = [];
    showOrderPreview = false;
    previewData = '';
    columns = columns;
    showOrders = true;
    refreshing = false;
    showModal = false;
    changeType='';
    header='';
    isAmend = false;

    // 🔄 Hook into record updates reactively
    @wire(getRecord, { recordId: '$recordId', fields: ['Opportunity.Id'] })
    wiredOpportunity({ error, data }) {
        if (data) {
            this.loadOpportunityData(); // Triggers Apex call
        } else if (error) {
            console.error('Error watching opportunity:', error);
        }
    }
    connectedCallback () {
        this.handleLoad();
    }

    handleLoad() {
        getAllOrderRequests({ opportunityId: this.recordId })
            .then(result => {
                this.allOrderRequestResult = result;
                return getStatusChangeDates({ opportunityId: this.recordId });
            })
            .then(statusResult => {
                this.statusChangeMap = statusResult || {}; // Ensure mapping is available
                this.data = this.formatData(this.allOrderRequestResult); // Now call formatData with updated statusChangeMap
            })
            .catch(error => {
                console.error('Error loading data:', error);
                this.error = error;
            });
    }

    handleRefresh() {
        this.handleLoad();
    }

    closePopupModal() {
        this.showModal = false;
    }

    handleRowAction(event) {
        const action = event.detail.action.name;
        const row = event.detail.row;
        if (row.Change_Type__c == 'Reschedule') {
            this.header = 'Rescheduling';
            this.isAmend = false;
        } else {
            this.header = 'Amendment';
            this.isAmend = true;
        }
        switch (action) {
            case 'preview':
                //this.preview(row.Id);
                this.showModal = true;
                this.selectedRecordId = row.Id;
                this.selectedMode='preview';
                break;
            case 'clone':
                //this.clone(row.Id);
                this.showModal = true;
                this.selectedRecordId = row.Id;
                this.selectedMode='clone';
                break;
            case 'cancel':
                this.cancel(row.Id);
                break;
            case 'reshare':
                this.reshare();
                break;
        }
    }
    handleClose() {
        this.showModal = false;
    }
    
    formatData(rawData) {
        const statusChangeMap = this.statusChangeMap || {};
    
        return rawData.map(row => {
            let rowActions = [];
            let statusChangedDate = statusChangeMap[row.Id] || null;
            this.changeType = row.Change_Type__c;
            if(row.Change_Type__c === 'Refund Request' && row.Status__c === 'Refund Rejected'){
                rowActions.push({ label: 'Re-Inititate', name: 'reinitiate' });
            }
            else if (row.Status__c === 'Cancelled' || row.Status__c === 'Completed') {
                rowActions.push({ label: 'Preview', name: 'preview' });
            } else {
                rowActions = [
                    { label: 'Preview', name: 'preview' },
                    { label: 'Clone', name: 'clone' },
                    { label: 'Cancel', name: 'cancel' },
                    { label: 'Reshare Payment Link', name: 'reshare' }
                ];
            }
    
            return {
                ...row,
                rowActions,
                statusChangedDate
            };
        });
    }
    
    /*
    async preview(recordId) {
        try {
            const data = await getSerializedData({ recordId });
            this.previewData = data;
            this.showPreview = true;
        } catch (e) {
            this.showToast('Error loading preview', e.body.message, 'error');
        }
    }*/

    async clone(recordId) {
        try {
            await cloneRequest({ recordId });
            this.showToast('Cloned', 'Request cloned successfully', 'success');
            return refreshApex(this.wiredChanges);
        } catch (e) {
            this.showToast('Error cloning', e.body.message, 'error');
        }
    }

    async cancel(recordId) {
        try {
            await cancelRequest({ recordId });
            this.showToast('Cancelled', 'Request cancelled', 'success');
            this.handleRefresh();
        } catch (e) {
            this.showToast('Error cancelling', e.body.message, 'error');
        }
    }

    async reshare() {
        try {
            await getPaymentLink({oppId: this.recordId });
            //await navigator.clipboard.writeText(link);
            this.showToast('Link Copied', 'Email with new payment link sent', 'success');
        } catch (e) {
            this.showToast('Error generating payment link', e.body.message, 'error');
        }
    }

    closePreview() {
        this.showOrderPreview = false;
        this.previewData = '';
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    /*
    loadPassengerData() {
        getOpportunityDetails({opportunityId: this.recordId})
        .then((result) => {
            this.serviceAirport = result.serviceAirport;
            this.flightType = result.flightType;
            this.flightNumber = result.flightNumber;
            this.flightDate = result.flightDate;
            this.numberOfAdults = result.NoOfAdult; 
            this.numberOfChildren = result.NoOfChild;
            this.numberOfInfants = result.NoOfInfant;
            this.loadOpportunityData(); // Triggers Apex call
        })
        .catch((error) => {
            console.error(error);
        });
    }*/

    loadOpportunityData() {
        getOpportunityData({ opportunityId: this.recordId })
            .then((result) => {
                this.opportunityData = result;

                this.orderSummary = result.orderSummary || [];
                this.guestRows = result.passengers || [];
                const flightDetails = result.flightDetails;
                this.surchrgeCheckbox = result.flightDetails.surcharge;
                if (flightDetails) {
                    this.flightDetails = flightDetails;
                }
                const placard = result.placard;
                if (placard) {
                    this.selectedPassenger = {
                        title: placard.title,
                        firstname: placard.firstname,
                        lastname: placard.lastname,
                        phone: placard.phone
                    };
                }

                // Calculate amounts
                this.totalAmount = this.sumByField(this.orderSummary, 'totalAmount');
                this.totalNetAmount = this.sumByField(this.orderSummary, 'netAmount');
                this.totalCgstAmount = this.sumByField(this.orderSummary, 'cgstAmount');
                this.totalSgstAmount = this.sumByField(this.orderSummary, 'sgstAmount');
                this.totalIgstAmount = this.sumByField(this.orderSummary, 'igstAmount');
                this.totalDiscountAmount = this.sumByField(this.orderSummary, 'discount');

                this.totalAmountAfterDiscount = this.totalAmount - this.totalDiscountAmount;

                if(this.totalCgstAmount > 0) {
                    this.showGst = true;
                    this.showCgst = true;
                } else if (this.totalIgstAmount > 0) {
                    this.showGst = true;
                    this.showIgst = true;
                } else if (this.totalDiscountAmount > 0) {
                    this.showDiscount = true;
                }
            })
            .catch((error) => {
                console.error('Error loading opportunity data:', error);
            });
    }

    /*sumByField(arr, fieldName) {
        return arr?.reduce((sum, item) => sum + (item[fieldName] || 0), 0);
    }*/
    sumByField(arr, fieldName) {
        const total = arr?.reduce((sum, item) => sum + (parseFloat(item[fieldName]) || 0), 0);
        return parseFloat(total.toFixed(2));
    }
}