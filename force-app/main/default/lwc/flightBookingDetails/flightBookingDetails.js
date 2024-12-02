import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';
import getPackageDetails from '@salesforce/apex/PackageSelectionController.getPackages';

import getAddOnDetails from '@salesforce/apex/PackageSelectionController.getAddons';

export default class FlightBookingDetails extends NavigationMixin(LightningElement) {
    @api recordId; // Opportunity record ID
    showModal = true;
    getPackage;
    getAddonDetail;
    selectedRowIndex = -1;
    selectedAddonRowIndex = -1;
    selectedPackage = '';
    selectedAmount ='';
    selectedAddon='';
    selectedAddonAmount='';
    currency ='INR ';
    adddOnCount = 1;
    orderSummaryPackage=[];
    orderSummaryAddon=[];
    orderSummary=[];
    totalAmount=0;

    @wire(CurrentPageReference)
    pageRef;

    connectedCallback() {
        const queryParams = this.pageRef?.state;
        if (queryParams && queryParams.c__openModal) {
            this.showModal = true; // Open modal if the parameter is set
        }
        this.loadPackageData();
        this.loadAddonData();
    }
    loadPackageData() {
        getPackageDetails({oppId: this.recordId})
        .then((result) => {
            this.getPackage = result; 
            this.getPackage = result.map((item) => ({
                ...item, // Spread the existing properties
                buttonLabel: 'Select' // Add buttonLabel to each item
            }));
        })
        .catch((error) => {
            console.error(error);
        });
    }

    loadAddonData() {
        getAddOnDetails({oppId: this.recordId})
        .then((result) => {
            this.getAddonDetail = result; 
            this.getAddonDetail = result.map((item) => ({
                ...item, // Spread the existing properties
                buttonLabel: 'Select', // Add buttonLabel to each item
                adddOnCount: this.adddOnCount
            }));
        })
        .catch((error) => {
            console.error(error);
        });
    }
    incrementAddOn(event) {
        const ind = event.target.dataset.index;  // Get the index of the clicked row
        this.getAddonDetail = this.getAddonDetail.map((wrapper, index) => {
            return {
                ...wrapper, 
                adddOnCount: ind == index ? wrapper.adddOnCount += 1 :  wrapper.adddOnCount
            };
        });
        //this.adddOnCount += 1;
    }

    decrementAddOn(event) {
        const ind = event.target.dataset.index;  // Get the index of the clicked row
        this.getAddonDetail = this.getAddonDetail.map((wrapper, index) => {
            return {
                ...wrapper, 
                adddOnCount: ind == index ? wrapper.adddOnCount >1 ? wrapper.adddOnCount -= 1 :  1 : wrapper.adddOnCount
            };
        });
        /*if (this.adddOnCount > 1) {
            this.adddOnCount -= 1;
        }*/
    }
    // Handle row selection
    handleSelect(event) {
        const index = event.target.dataset.index;  // Get the index of the clicked row
        //this.handleUnselect(event);
        this.selectedRowIndex = index;  // Update selected row
        this.selectedPackage = this.getPackage[index].packageName;
        this.selectedAmount = this.getPackage[index].priceTag;
        this.updateButtonPackageLabels(); // Recompute the button labels after selection
        this.orderSummaryPackage = this.getPackage
            .filter(wrapper => wrapper.buttonLabel === 'Selected') // Filter condition
            .map(wrapper => {
                return {
                    name: wrapper.packageName,        // Copy the 'name' value
                    amount: wrapper.priceTag,  // Copy the 'amount' value
                    totalAmount: wrapper.priceTag
                };
            });
            this.orderSummary = [...this.orderSummaryPackage, ...this.orderSummaryAddon];
            this.calculateTotalPackage();
        //this.orderSummary = [...this.orderSummary, (this.selectedPackage + ' '+ this.selectedAmount)];
        
    }
    handleUnselect(event) {
        //const indexToRemove = event.target.dataset.index; // Get the index from the button's dataset
        this.orderSummary = this.orderSummary.filter((value, index) => value != (this.selectedPackage + ' '+ this.selectedAmount)); // Remove the item at that index
    }
    handleAddOnSelect(event){
        const index = event.target.dataset.index;  // Get the index of the clicked row
        this.selectedAddonRowIndex = index;  // Update selected row
        this.updateButtonAddonLabels(index);
        this.selectedAddon=this.getAddonDetail[index].addOnName;
        this.selectedAddonAmount=this.getAddonDetail[index].addOnTag;
        //this.orderSummary = [...this.orderSummary, (this.selectedPackage + ' '+ this.selectedAmount)];

        this.orderSummaryAddon = this.getAddonDetail
            .filter(wrapper => wrapper.buttonLabel === 'Selected') // Filter condition
            .map(wrapper => {
                return {
                    name: wrapper.addOnName+' ' +wrapper.adddOnCount+' Qty',        // Copy the 'name' value
                    amount: wrapper.addOnTag*wrapper.adddOnCount,  // Copy the 'amount' value
                    totalAmount: wrapper.addOnTag*wrapper.adddOnCount,
                    button: true
                };
            });
            this.orderSummary = [...this.orderSummaryPackage, ...this.orderSummaryAddon];
            this.calculateTotalPackage();
    }

    // Precompute button labels for each row
    updateButtonPackageLabels() {
        this.getPackage = this.getPackage.map((wrapper, index) => {
            return {
                ...wrapper, // Keep existing properties
                buttonLabel: this.selectedRowIndex == index ? 'Selected' : 'Select' // Change label based on selection
            };
        });
    }
    updateButtonAddonLabels(ind) {
        this.getAddonDetail = this.getAddonDetail.map((wrapper, index) => {
            return {
                ...wrapper, // Keep existing properties
                buttonLabel: ind == index ? 'Selected' : wrapper.buttonLabel // Change label based on selection
            };
        });
    }
    closeModal() {
        this.showModal = false; // Close the modal
    }
    calculateTotalPackage() {
        this.totalAmount = this.orderSummary.reduce((sum, currentItem) => {
            return sum + currentItem.totalAmount;
        }, 0);
    }
}