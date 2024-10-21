import { LightningElement, track } from 'lwc';

export default class Journey extends LightningElement {
    @track flightNo = '';
    @track airport = '';
    @track sector = '';
    @track journeyDate = '';
    @track flightType = '';

    handleInputChange(event) {
        const field = event.target.dataset.id;
        this[field] = event.target.value;
    }

    previous() {
        this.dispatchEvent(new CustomEvent('previous'));
    }

    next() {
        const journeyData = {
            flightNo: this.flightNo,
            airport: this.airport,
            sector: this.sector,
            journeyDate: this.journeyDate,
            flightType: this.flightType,
        };
        this.dispatchEvent(new CustomEvent('next', { detail: journeyData }));
    }
}