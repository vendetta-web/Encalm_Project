import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import getOpportunityData from '@salesforce/apex/BookingSummaryController.getOpportunityData';

export default class BookingSummary extends LightningElement {
    @api recordId;

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

    // 🔄 Hook into record updates reactively
    @wire(getRecord, { recordId: '$recordId', fields: ['Opportunity.Id'] })
    wiredOpportunity({ error, data }) {
        if (data) {
            this.loadOpportunityData(); // Triggers Apex call
        } else if (error) {
            console.error('Error watching opportunity:', error);
        }
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

    sumByField(arr, fieldName) {
        return arr?.reduce((sum, item) => sum + (item[fieldName] || 0), 0);
    }
}