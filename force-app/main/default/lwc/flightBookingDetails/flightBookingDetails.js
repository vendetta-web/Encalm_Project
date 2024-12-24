import { LightningElement, api, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPackageDetails from '@salesforce/apex/PackageSelectionController.getPackages';
import getAddOnDetails from '@salesforce/apex/PackageSelectionController.getAddons';
import getOpportunityDetails from '@salesforce/apex/PackageSelectionController.getOpportunityDetails';
import createOpportunityLineItems from '@salesforce/apex/PackageSelectionController.createOpportunityLineItems';
import savePassengerDetails from '@salesforce/apex/PackageSelectionController.savePassengerDetails';

export default class FlightBookingDetails extends NavigationMixin(LightningElement) {
    @api recordId; // Opportunity record ID
    showModal = true;
    showHeader = true;
    showChild = false;
    passengerDetailPage=false;
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
    @track oliFieldValues = {};
    serviceAirport;
    flightNumber;
    flightDate;


    //Passenger Details
    @track guestRows = [];
    genderOptions = [
        { label: 'Male', value: 'Male' },
        { label: 'Female', value: 'Female' },
        { label: 'Other', value: 'Other' }
    ];
    travelClassOptions = [
        { label: 'First', value: 'First' },
        { label: 'Business', value: 'Business' },
        { label: 'Economy', value: 'Economy' },
        { label: 'Premium Economy', value: 'Premium Economy' }
    ];
     // Title options for the picklist
     titleOptions = [
        { label: 'Mr.', value: 'Mr.' },
        { label: 'Ms.', value: 'Ms.' },
        { label: 'Mrs.', value: 'Mrs.' },
        { label: 'Dr.', value: 'Dr.' },
        { label: 'Prof.', value: 'Prof.' },
        { label: 'Other', value: 'Other' }
    ];

    @track numberOfAdults = 0;
    @track numberOfChildren = 0;
    @track numberOfInfants = 0;
    firstName='';
    lastName='';
    mobile;
    title='';
    @track opportunityFieldValues = {};


    connectedCallback() {
        this.showModal = true;
        this.showHeader = true;
        this.showChild = false;
        this.loadPackageData();
        this.loadAddonData();
        this.loadPssengerData();
    }

    loadDetailsAfterUpdate() {
        this.showModal = true;
        this.showHeader = true;
        this.showChild = false;
        this.orderSummaryPackage=[];
        this.orderSummaryAddon=[];
        this.orderSummary=[];
        this.totalAmount=0;
        this.loadPackageData();
        this.loadAddonData();
        this.loadPssengerData();
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

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant,
        });
        this.dispatchEvent(event);
    }

    loadAddonData() {
        getAddOnDetails({oppId: this.recordId})
        .then((result) => {
            this.getAddonDetail = result; 
            this.getAddonDetail = result.map((item) => ({
                ...item, // Spread the existing properties
                buttonLabel: 'Select', // Add buttonLabel to each item
                adddOnCount: this.adddOnCount,
                class: 'btns select'
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
            const numberOfRecords = this.numberOfAdults > this.numberOfChildren ? this.numberOfAdults : this.numberOfChildren; // or any other condition to determine number of records

            // Create an array of records based on the number of adults
            const records = [];
                records.push({
                    name: wrapper.packageName + ' (' + this.numberOfAdults + ' Adult)', // Copy the 'name' value for adult
                    amount: wrapper.priceTag * this.numberOfAdults, // Calculate the amount 
                    totalAmount: wrapper.priceTag * this.numberOfAdults,
                    productId: wrapper.productId,
                    pricebookEntryId: wrapper.pricebookEntryId,
                    unitPrice: wrapper.priceTag,
                    count: 1 // Set the count, potentially modify later based on adults/children
                });
                if (this.numberOfChildren > 0) {                    
                records.push({
                    name: wrapper.packageName + ' (' + this.numberOfChildren + ' child)', // Copy the 'name' value for child
                    amount: (wrapper.priceTag -  wrapper.priceTag * (30 / 100))*this.numberOfChildren, // Calculate the amount
                    totalAmount: (wrapper.priceTag -  wrapper.priceTag * (30 / 100))*this.numberOfChildren,
                    productId: wrapper.productId,
                    pricebookEntryId: wrapper.pricebookEntryId,
                    unitPrice: wrapper.priceTag,
                    count: 1 // Set the count, potentially modify later based on adults/children
                });
            }            

            return records; // Return the array of records
        })
        .flat(); // Flatten the array to combine all the records into a single array

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
            .filter(wrapper => wrapper.buttonLabel === 'Remove') // Filter condition
            .map(wrapper => {
                return {
                    name: wrapper.addOnName+' ' +wrapper.adddOnCount+' Qty',        // Copy the 'name' value
                    amount: wrapper.addOnTag*wrapper.adddOnCount,  // Copy the 'amount' value
                    totalAmount: wrapper.addOnTag*wrapper.adddOnCount,
                    button: true,
                    productId: wrapper.productId,
                    pricebookEntryId: wrapper.pricebookEntryId,
                    unitPrice: wrapper.addOnTag,
                    count: wrapper.adddOnCount
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
        const boxElement = this.template.querySelector('.box');
        this.getAddonDetail = this.getAddonDetail.map((wrapper, index) => {
            return {
                ...wrapper, // Keep existing properties
                buttonLabel: ind == index ? wrapper.buttonLabel == 'Select' ? 'Remove' : 'Select' : wrapper.buttonLabel, // Change label based on selection
                class: ind == index ? wrapper.buttonLabel == 'Select' ? 'btns remove' : 'btns select' : wrapper.class
            };
        });
    }
    closeModal() {
        this.showModal = false; // Close the modal
        this.passengerDetailPage = false;
        this.showHeader = false;
        this.showChild =true;
    }
    calculateTotalPackage() {
        this.totalAmount = this.orderSummary.reduce((sum, currentItem) => {
            return sum + currentItem.totalAmount;
        }, 0);
    }
    openPassengerPage() {
        let matchFound = false;
        let buttonLabel = 'buttonLabel';
        for (let item of this.getPackage) {
            // Check if the package is selected
            if (item[buttonLabel] == 'Selected') {
                matchFound = true;
                break;  // Exit loop after finding the match
            }
        }
        if(matchFound) {            
            this.createOLIs();
            this.showModal=false;
            this.passengerDetailPage = true;
        } else {
            this.showToast('Error', 'Please select a package: !', 'error');
        }
    }

    // Method to call Apex and create Opportunity Line Items
    createOLIs() {
        createOpportunityLineItems({ opportunityId: this.recordId, productDetails: this.orderSummary, amount: this.totalAmount })
            .then(result => {
                this.showToast('Success', 'Opportunity Line Items created successfully: !', 'success');
                //console.log('Opportunity Line Items created successfully: ', result);
            })
            .catch(error => {
                console.error('Error creating Opportunity Line Items: ', error);
            });
    }

    loadPssengerData() {
        getOpportunityDetails({opportunityId: this.recordId})
        .then((result) => {
            this.serviceAirport = result.serviceAirport;
            this.flightNumber = result.flightNumber;
            this.flightDate = result.flightDate;
            this.numberOfAdults = result.NoOfAdult; 
            this.numberOfChildren = result.NoOfChild;
            this.numberOfInfants = result.NoOfInfant;

                
            this.addGuestRows('Adult', this.numberOfAdults);
            this.addGuestRows('Child', this.numberOfChildren);
            this.addGuestRows('Infant', this.numberOfInfants);
        })
        .catch((error) => {
            console.error(error);
        });
    }

     // Add rows for a specific type of guest (Adult/Child/Infant)
    addGuestRows(type, count) {
        for (let i = 0; i < count; i++) {
            this.guestRows.push({
                id: `${type}-${i}`,
                pass: type,
                type: type,
                title: '',
                firstName: '',
                lastName: '',
                gender: '',
                age: null,
                designation: '',
                travelClass: '',
                pnrNo: ''
            });
        }
    }

    handleChange(event) {
        const field = event.target.label.toLowerCase().replace(/ /g, '');
        const value = event.target.value;
        const index = event.target.closest('.guest-row').dataset.index;  // Use data attribute for index
        
        // Ensure the index exists and is valid
        if (this.guestRows[index]) {
            this.guestRows[index][field] = value;
        }
    }

    //to get field values to save in opp record
    handleFieldChange(event) {
        const fieldName = event.target.name;
        const fieldValue = event.target.value;

        this.opportunityFieldValues[fieldName] = fieldValue;
    }

     // Handle the Save action
     handleSave() {
        savePassengerDetails({ passengerData: this.guestRows, opportunityId: this.opportunityId })
            .then(() => {
                // Handle success
                this.showToast('Success', 'Passenger details saved successfully!', 'success');
                console.log('Passenger details saved successfully');
            })
            .catch(error => {
                // Handle error
                console.error('Error saving passenger details:', error);
            });
    }
    openDetailPage(){
        this.showModal=true;
        this.passengerDetailPage = false;

    }
}