import { LightningElement, wire, api } from 'lwc';
import getLatestAmendmentOrderRequest from '@salesforce/apex/OrderRequestController.getLatestAmendmentOrderRequest';

export default class PreviewAmendments extends LightningElement {
    @api orderId;
    @api oppId;
    @api mode; // 'preview' or 'clone'

    orderRequest;
    showPassenger=false; 

    @wire(getLatestAmendmentOrderRequest, { orderRecId: '$orderId' })
    wiredOrderRequest({ data, error }) {
        if (data) {
            this.orderRequest = data.parentOrderRequest || [];
            this.guestRows = data.passengers || [];
            if(this.orderRequest.typeOfAmendment == 'Add Passengers') {
                this.showPassenger = true;
            } else if(this.orderRequest.typeOfAmendment == 'Upgrade Package') {
                this.isDeparture = true;
                this.flightNumber = this.orderRequest.Flight_Number_Departure__c;
                this.departureDate= this.orderRequest.Date_of_Departure__c;
                this.stdTime = this.orderRequest.Departure_Service_Time__c;
                this.serviceTime = this.orderRequest.Departure_Service_Time__c;
            }else if(this.orderRequest.typeOfAmendment == 'Add Add-Ons') {
                this.isTransit = true;
                this.flightNumberArrival = this.orderRequest.Flight_Number_Arrival__c;
                this.flightNumberDeparture = this.orderRequest.Flight_Number_Departure__c;
                this.arrivalDate= this.orderRequest.Date_of_Arrival__c;
                this.staTime = this.orderRequest.Arrival_Service_Time__c;
                this.departureDate= this.orderRequest.Date_of_Departure__c;
                this.stdTime = this.orderRequest.Departure_Service_Time__c;
                this.serviceTime = this.orderRequest.Departure_Service_Time__c;
            }
            this.error = undefined;
        } else if (error) {
            this.error = 'Error fetching order request';
            this.orderRequest = undefined;
        }
    }

    get isPreviewMode() {
        return this.mode === 'preview';
    }
    get isCloneMode() {
        return this.mode === 'clone';
    }
}