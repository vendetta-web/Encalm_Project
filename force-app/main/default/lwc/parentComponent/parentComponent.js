import { LightningElement, track } from 'lwc';

export default class ParentComponent extends LightningElement {
    @track isModalOpen = false;
    @track isPersonalDetails = true;
    @track isServices = false;
    @track isJourney = false;
    @track isPassengerDetails = false;

    openModal() {
        this.isModalOpen = true;
    }

    handleNext(event) {
        const detailData = event.detail;

        if (this.isPersonalDetails) {
            this.isPersonalDetails = false;
            this.isServices = true;
        } else if (this.isServices) {
            this.isServices = false;
            this.isJourney = true;
        } else if (this.isJourney) {
            this.isJourney = false;
            this.isPassengerDetails = true;
        }
    }

    handlePrevious(event) {
        if (this.isPassengerDetails) {
            this.isPassengerDetails = false;
            this.isJourney = true;
        } else if (this.isJourney) {
            this.isJourney = false;
            this.isServices = true;
        } else if (this.isServices) {
            this.isServices = false;
            this.isPersonalDetails = true;
        }
    }

    handleClose() {
        this.isModalOpen = false;
        this.resetSteps();
    }

    resetSteps() {
        this.isPersonalDetails = true;
        this.isServices = false;
        this.isJourney = false;
        this.isPassengerDetails = false;
    }
}