import { LightningElement, track } from 'lwc';

export default class Services extends LightningElement {
    @track packageValue = '';
    @track addOnServices = '';
    @track noOfAdults = '';
    @track noOfChildren = '';
    @track noOfInfants = '';

    handleInputChange(event) {
        const field = event.target.dataset.id;
        this[field] = event.target.value;
    }

    handleNumberOfAdults(event) {
        this.noOfAdults = event.target.value;
    }

    previous() {
        this.dispatchEvent(new CustomEvent('previous'));
    }

    createLead() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    next() {
        const serviceData = {
            packageValue: this.packageValue,
            addOnServices: this.addOnServices,
            noOfAdults: this.noOfAdults,
            noOfChildren: this.noOfChildren,
            noOfInfants: this.noOfInfants,
        };
        this.dispatchEvent(new CustomEvent('next', { detail: serviceData }));
    }
}