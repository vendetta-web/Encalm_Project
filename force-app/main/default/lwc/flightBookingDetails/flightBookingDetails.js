import { LightningElement, api, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPackageDetails from '@salesforce/apex/PackageSelectionController.getPackages';
import getAddOnDetails from '@salesforce/apex/PackageSelectionController.getAddons';
import getOpportunityDetails from '@salesforce/apex/PackageSelectionController.getOpportunityDetails';
import createOpportunityLineItems from '@salesforce/apex/PackageSelectionController.createOpportunityLineItems';
import savePassengerDetails from '@salesforce/apex/PackageSelectionController.savePassengerDetails';
import getSavedPassengerDetails  from '@salesforce/apex/PackageSelectionController.getSavedPassengerDetails';
import savePlacardDetails from '@salesforce/apex/PackageSelectionController.savePlacardDetails';
import getSavedPlacardDetails from '@salesforce/apex/PackageSelectionController.getPlacardDetails';
import getProcessState from '@salesforce/apex/PackageSelectionController.getProcessState';
import updateBookingState from '@salesforce/apex/PackageSelectionController.updateBookingState';
import updateAddonsOrderSummaryState from '@salesforce/apex/PackageSelectionController.updateAddonsOrderSummaryState';
import getCurrentPackageDetails from '@salesforce/apex/AmendmentBookingController.getExistingPackage';
import sendEmailWithAttachment from '@salesforce/apex/BookingEmailHandler.sendEmailWithAttachment';
//import createContentVersion from '@salesforce/apex/MDEN_PdfAttachmentController.createContentVersion';
import getTerminalInfo from '@salesforce/apex/PackageSelectionController.getTerminalInfo';
import getFlightTerminalInfo from '@salesforce/apex/PackageSelectionController.getFlightTerminalInfo';
import jsPDFLibrary from '@salesforce/resourceUrl/jsPDFLibrary';
import { loadScript } from 'lightning/platformResourceLoader';
import { RefreshEvent } from 'lightning/refresh';
import getPicklistValues from '@salesforce/apex/CustomPicklistController.getNationalityPicklistValues';
import generateAndSavePDF from '@salesforce/apex/MDEN_PdfAttachmentController.generateAndSavePDF';
import submitForSurchargeApproval from '@salesforce/apex/PackageSelectionController.submitForSurchargeApproval';
import loadSurcharge from '@salesforce/apex/PackageSelectionController.loadSurcharge';
import saveData from '@salesforce/apex/FlightPreview.saveData';

export default class FlightBookingDetails extends NavigationMixin(LightningElement) {
    @api recordId; // Opportunity record ID
    @track editSurcharge = ''
    showModal = false;
    showHeader = true;
    showChild = false;
    showPreview = false;
    showGst = false;
    showCgst = false;
    showIgst = false;
    passengerDetailPage=false;
    isModalOpen = false;
    jsPDFInitialized = false;
    isLoading = false;
    isPaxIncreased = false;
    getPackage;
    isQuotationSent=false;
    isEditing = false;
    @track surchargeApplicable = false;
    @track bookerApplicable = false;
    bookingStage='';
    processState = '';
    showPayment
    @track getAddonDetail;
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
    orderSummaryBeforeEdit=[];
    pickupTerminalOptions = [];
    dropTerminalOptions = [];
    totalAmount=0;
    totalNetAmount=0;
    totalCgstAmount=0;
    totalSgstAmount=0;
    totalIgstAmount=0;
    totalDiscountAmount=0;
    totalAmountAfterDiscount=0;
    @track oliFieldValues = {};
    serviceAirport;
    flightType ='Domestic';
    flightNumber;
    flightDate;
    selectedPassenger;
    selectedPassengerBeforeEdit;
    nationalityOptions = [];
    filteredNationalityOptions = [];
    selectedNationality;
    // Variables to track error classes
    pickupErrorClass = '';
    dropErrorClass = '';
    //variable to show error for phone
    showPhoneErrorMessage = false;
    showDiscount = false;
    amountMessage = 'Final Amount';


    //Individual Passenger Details
    @track guestRows = [];
    @track guestRowsBeforeEdit=[];
    //Passenger Details for adults
    @track guestRowsAdults = [];
    //Passenger details for childs
    @track guestRowsChilds = [];
    //Passenger details for Infants
    @track guestRowsInfants = [];
    newGuestType = 'Adult';
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
    //to add new row on passenger page
    guestTypeOptions = [
        { label: 'Adult', value: 'Adult' },
        { label: 'Child', value: 'Child' },
        { label: 'Infant', value: 'Infant' }
    ];

    @track numberOfAdults = 0;
    @track numberOfChildren = 0;
    @track numberOfInfants = 0;
    @track numberOfAdultsBeforeUpdate = 0;
    @track numberOfChildrenBeforeUpdate = 0;
    @track numberOfInfantsBeforeUpdate = 0;
    firstName='';
    lastName='';
    mobile;
    title='';
    @track opportunityFieldValues = {};
    @track location;
    @track booker;
    @track surcharge = false;
    bookerBeforeEdit;
    locationBeforeEdit;
    @track disableSurchargeWaiveOffInput = false;
    @track checkSurcharge = false;
    connectedCallback() {        
        this.loadPackageData();
        this.loadAddonData();
        this.loadPassengerData();
        //this.fetchProcessState();
    }

    @wire(getPicklistValues)
    wiredPicklistValues({ error, data }) {
        if (data) {
            // Map the string values to the required object format for the combobox
            this.nationalityOptions = data.map((value) => ({
                label: value,
                value: value
            }));
        } else if (error) {
            console.error('Error fetching picklist values: ', error);
        }
    }

    fetchProcessState() {
        getProcessState({ opportunityId: this.recordId })
            .then((result) => {
                this.processState = result.Process_State__c !=null ? result.Process_State__c : '';
                this.getAddonDetail = result.Saved_State_Addons__c != null ? JSON.parse(result.Saved_State_Addons__c) : this.getAddonDetail;
                this.orderSummary = result.Saved_State_OrderSummary__c !=null ? JSON.parse(result.Saved_State_OrderSummary__c) : this.orderSummary;
                this.showSelectedAddons();
                this.handleUIBasedOnState();
            })
            .catch((error) => {
                console.error('Error fetching process state:', error);
            });
    }

    // Update the process state when the user moves to the next screen
    updateProcesses() {
        updateAddonsOrderSummaryState({ opportunityId: this.recordId, 
            processAddons: JSON.stringify(this.getAddonDetail), 
            processOrderSummary: JSON.stringify(this.orderSummary)})
            .then(() => {
            })
            .catch((error) => {
                console.error('Error updating process state:', error);
            });
    }

    showPackageSelectionScreen() {
        this.showModal = true;
        this.showHeader = true;
        this.showChild = false;
    }

    // Handle the UI elements based on the current state
    handleUIBasedOnState() {
        if (this.processState === '') {            
            this.showModal = true;
            this.showHeader = true;
            this.showChild = false;
        } else if (this.isPaxIncreased) {            
            this.showModal = true;
            this.showHeader = true;
            this.showChild = false;
            this.showPackageSelection();  
            this.calculateTotalPackage(); 
            this.getSavedPassengerData();
            this.getSavedPlacardData();
            this.showSavedDiscountAndGst();
        }else if (this.processState === 'Package Selection') {
            // package selection was completed
            this.showPackageSelection(); 
            this.calculateTotalPackage();
            this.showModal=false;
            this.passengerDetailPage = true;
            this.showSavedDiscountAndGst();
        } else if (this.processState === 'Passenger Details') {
            // Passenget details were filled
            this.showPackageSelection();   
            this.calculateTotalPackage();
            this.getSavedPassengerData();
            this.getSavedPlacardData();
            this.showPreview = true;
            this.showModal=false;
            this.passengerDetailPage = false;
            this.showSavedDiscountAndGst();
        } else if (this.processState === 'Preview') {
            // Preview screen was viewed
            this.showPackageSelection();  
            this.calculateTotalPackage(); 
            this.getSavedPassengerData();
            this.getSavedPlacardData();
            this.showPreview = true;
            this.showModal=false;
            this.passengerDetailPage = false;
            this.isQuotationSent = true;
            this.showSavedDiscountAndGst();
        }
    }

    showSavedDiscountAndGst() {
        if (this.orderSummary) {
            this.orderSummary.forEach(item => {
                if (item.cgstAmount > 0) {
                    this.showGst = true;
                    this.showCgst = true;
                }
                if (item.igstAmount > 0) {
                    this.showGst = true;
                    this.showIgst = true;
                }
                if (item.discountValue > 0) {
                    this.showDiscount = true;
                }
            });
        }            
    }

    loadDetailsAfterUpdate(event) {
        this.isPaxIncreased =true;
        this.numberOfAdults = event.detail.adultCount;
        this.numberOfChildren = event.detail.childCount;
        this.numberOfInfants = event.detail.infantCount;
        this.loadPackageData();
        this.loadAddonData();
        this.loadPassengerData();
    }
    getTerminals() {
        getTerminalInfo({oppId: this.recordId})
        /*
          .then(result => {
                this.terminalOptions = result.map(each => ({
                label: each.Code__c,
                value: each.Code__c
            }));
            })*/
            .then(result => {
                // Create a list of all terminals as options
                const allTerminals = result.map(each => ({
                    label: each.Code__c,
                    value: each.Code__c
                }));
        
                // Initialize the options for pickup and drop terminals
                this.pickupTerminalOptions = [...allTerminals];
                this.dropTerminalOptions = [...allTerminals];
        
                // For each addon, remove the pickupTerminal from dropTerminalOptions and dropTerminal from pickupTerminalOptions
                this.getAddonDetail.forEach(item => {
                    if (item.pickupTerminal) {
                        // Remove pickupTerminal value from dropTerminalOptions
                        this.dropTerminalOptions = this.dropTerminalOptions.filter(option => option.value !== item.pickupTerminal);
                    }
                    if (item.dropTerminal) {
                        // Remove dropTerminal value from pickupTerminalOptions
                        this.pickupTerminalOptions = this.pickupTerminalOptions.filter(option => option.value !== item.dropTerminal);
                    }
                });
        
            })
            .catch(error => {
                console.error('Error fetching terminals:', error);
                
            });
        }
    loadPackageData() {
        getPackageDetails({oppId: this.recordId})
        .then((result) => {
            this.isLoading = true;
            this.getPackage = result; 
            this.getPackage = result.map((item) => ({
                ...item, // Spread the existing properties
                buttonLabel: 'Select', // Add buttonLabel to each item
                class: 'selectbtn'
            }));
            this.isLoading = false;
        })
        .catch((error) => {
            this.isLoading = false;
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
        getAddOnDetails({ oppId: this.recordId })
        .then((result) => {
            this.isLoading = true;
            if (result) {                
                this.getAddonDetail = result.map((item) => ({
                    ...item, // Spread the existing properties
                    buttonLabel: 'Select', // Button label for the add-ons
                    adddOnCount: 1, // Default count
                    class: 'btns select', // Default class
                    disablePickup: item.pickupTerminal ? true : false, // Disable pickup if it has a value
                    disableDrop: item.dropTerminal ? true : false, // Disable drop if it has a value
                    pickupTerminals: [
                        { id: 'Pickup Terminal 1', value: item.pickupTerminal || '' } // Initialize Pickup Terminal
                    ],
                    dropTerminals: [
                        { id: 'Drop Terminal 1', value: item.dropTerminal || '' } // Initialize Drop Terminal
                    ],
                }));
                this.getTerminals();
            }
            this.isLoading = false;
        })
        .catch((error) => {
            this.isLoading = false;
            console.error(error);
        });
    }
    
    incrementAddOn(event) {
        const ind = event.target.dataset.index; // Get the index of the clicked row
        this.getAddonDetail = this.getAddonDetail.map((wrapper, index) => {
            if (ind == index) {
                // Check if the adddOnCount is less than 5 before incrementing
                if (wrapper.adddOnCount < 5) {
                    // Increment count
                    wrapper.adddOnCount += 1;
                }
    
                // Ensure arrays are initialized
                wrapper.pickupTerminals = wrapper.pickupTerminals || [];
                wrapper.dropTerminals = wrapper.dropTerminals || [];
    
                // Check if Pickup Terminal has a value
                if (wrapper.pickupTerminals.some(terminal => terminal.value !== '')) {
                    // Only add to Drop Terminals if it doesn't exceed max limit (5)
                    if (wrapper.dropTerminals.length < 5) {
                        wrapper.dropTerminals.push({
                            id: `Drop Terminal ${wrapper.dropTerminals.length + 1}`,
                            value: '' // Default to empty value
                        });
                    }
                } else {
                    // Only add to Pickup Terminals if it doesn't exceed max limit (5)
                    if (wrapper.pickupTerminals.length < 5) {
                        wrapper.pickupTerminals.push({
                            id: `Pickup Terminal ${wrapper.pickupTerminals.length + 1}`,
                            value: '' // Default to empty value
                        });
                    }
                }
            }
            return wrapper;
        });
    }
    
    

    decrementAddOn(event) {
        const ind = event.target.dataset.index; // Get the index of the clicked row
        this.getAddonDetail = this.getAddonDetail.map((wrapper, index) => {
        if (ind == index && wrapper.adddOnCount > 1) {
            // Decrement count
            wrapper.adddOnCount -= 1;

            // Remove the last Drop Terminal if more than one exists
            if (wrapper.dropTerminals.length > 1) {
                wrapper.dropTerminals.pop();
            }

            // Remove the last Pickup Terminal if more than one exists
            if (wrapper.pickupTerminals.length > 1) {
                wrapper.pickupTerminals.pop();
            }
        }
        return wrapper;
        });
    }
    // Handle row selection
    handleSelect(eventOrIndex) {
        const index = typeof eventOrIndex === 'number' ? eventOrIndex : eventOrIndex.target.dataset.index;  
        this.selectedRowIndex = index;
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
                    totalAmount: wrapper.priceTag * this.numberOfAdults, // Calculate the amount 
                    netAmount: wrapper.priceTagBeforeTax * this.numberOfAdults,
                    cgstAmount: wrapper.cgst * this.numberOfAdults,
                    sgstAmount: wrapper.sgst * this.numberOfAdults,
                    igstAmount: wrapper.igst * this.numberOfAdults,
                    productId: wrapper.productId,
                    pricebookEntryId: wrapper.pricebookEntryId,
                    unitPrice: wrapper.priceTag,
                    count: this.numberOfAdults, // Set the count, potentially modify later based on adults
                    discountValue: this.calculateDiscount(wrapper.priceTag * this.numberOfAdults, wrapper.discountValue, wrapper.isDiscountInPercent),
                    isChild: false,
                    isInfant: false
                });
                if (this.numberOfChildren > 0) {             
                    records.push({
                        name: wrapper.packageName + ' (' + this.numberOfChildren + ' child)', // Copy the 'name' value for child
                        amount: wrapper.childPackageWrapper[wrapper.packageFamily].price * this.numberOfChildren, // Calculate the amount
                        totalAmount: wrapper.childPackageWrapper[wrapper.packageFamily].price * this.numberOfChildren,
                        netAmount: wrapper.childPackageWrapper[wrapper.packageFamily].priceTagBeforeTax * this.numberOfChildren,
                        cgstAmount: wrapper.childPackageWrapper[wrapper.packageFamily].cgst * this.numberOfChildren,
                        sgstAmount: wrapper.childPackageWrapper[wrapper.packageFamily].sgst * this.numberOfChildren,
                        igstAmount: wrapper.childPackageWrapper[wrapper.packageFamily].igst * this.numberOfChildren,
                        productId: wrapper.childPackageWrapper[wrapper.packageFamily].productId,
                        pricebookEntryId: wrapper.childPackageWrapper[wrapper.packageFamily].priceBookEntryId,
                        unitPrice: wrapper.childPackageWrapper[wrapper.packageFamily].price,
                        count: 1, // Set the count, potentially modify later based on children
                        discountValue: this.calculateDiscount( wrapper.childPackageWrapper[wrapper.packageFamily].price * this.numberOfChildren, wrapper.discountValue, wrapper.isDiscountInPercent),
                        isChild: true,
                        childCount: this.numberOfChildren  //to create child oli records
                    });
                } 
                if (this.numberOfInfants > 0) {             
                    records.push({
                        name: wrapper.packageName + ' (' + this.numberOfInfants + ' Infant)', // Copy the 'name' value for infant
                        amount: wrapper.infantPackageWrapper[wrapper.packageFamily].price * this.numberOfInfants, // Calculate the amount
                        totalAmount: wrapper.infantPackageWrapper[wrapper.packageFamily].price * this.numberOfInfants,
                        netAmount: 0,
                        cgstAmount: 0,
                        sgstAmount: 0,
                        igstAmount: 0,
                        productId: wrapper.infantPackageWrapper[wrapper.packageFamily].productId,
                        pricebookEntryId: wrapper.infantPackageWrapper[wrapper.packageFamily].priceBookEntryId,
                        unitPrice: wrapper.infantPackageWrapper[wrapper.packageFamily].price,
                        count: 1, // Set the count, potentially modify later based on children
                        discountValue: 0,
                        isInfant: true,
                        isChild: false,
                        infantCount: this.numberOfInfants  //to create infant oli records
                    });
                }            

            return records; // Return the array of records
        })
        .flat(); // Flatten the array to combine all the records into a single array

            const surcharge = this.surchargePackage;
            console.log('>>>surcharge',surcharge);
            if (surcharge.surchargeApplicable) {
                this.orderSummaryPackage.push({
                    name: surcharge.packageName || 'Surcharge',
                    amount: surcharge.price,
                    totalAmount: surcharge.price,
                    netAmount: surcharge.priceTagBeforeTax,
                    cgstAmount: surcharge.cgst,
                    sgstAmount: surcharge.sgst,
                    igstAmount: surcharge.igst,
                    productId: surcharge.productId,
                    pricebookEntryId: surcharge.priceBookEntryId,
                    unitPrice: surcharge.price,
                    isChild : false, 
                    isInfant : false,
                    count: 1,
                    discountValue: 0,
                    isSurcharge: true // Optional flag for clarity
                });
            }
            this.orderSummary = [...this.orderSummaryPackage, ...this.orderSummaryAddon];
            this.calculateTotalPackage();
            console.log('orderSummary inside --->>> ',JSON.stringify(this.orderSummary));
        //this.orderSummary = [...this.orderSummary, (this.selectedPackage + ' '+ this.selectedAmount)];
        
    }
    //logic to calculate discount amount
    calculateDiscount(amount, discountValue, isDiscountInPercent) {
        // Ensure inputs are valid
        if (isNaN(amount) || isNaN(discountValue) || amount <= 0 || discountValue < 0) {
            return 0;
        }
    
        let finalDiscountValue;
        
        if (isDiscountInPercent) {
            // If discount is in percent, calculate the discount value
            finalDiscountValue = (amount * discountValue) / 100;
        } else {
            // If discount is a fixed value, use it directly
            finalDiscountValue = discountValue;
        }
    
        // Ensure the discount doesn't exceed the total amount
        if (finalDiscountValue > amount) {
            return amount;
        }    
        // Calculate final amount after applying discount
        //const discountedAmount = amount - finalDiscountValue;    
        return finalDiscountValue; //round off to 2 decimal places
    }

    handleUnselect(event) {
        //const indexToRemove = event.target.dataset.index; // Get the index from the button's dataset
        this.orderSummary = this.orderSummary.filter((value, index) => value != (this.selectedPackage + ' '+ this.selectedAmount)); // Remove the item at that index
    }

    // Method to handle validation of terminals
    validatePicklistSelections(index) {
        let isValid = true;
        const item = this.getAddonDetail[index]; // Get the specific item based on the passed index
    
        // If buttonLabel is 'Remove', skip validation for this item
        if (item.buttonLabel === 'Remove' || item.hideDropTerminal) {
            return true; // Skip validation for this item
        }
    
        // Initialize error classes for the specific item
        let pickupErrorClass = ''; 
        let dropErrorClass = '';
    
        // Validate Pickup Terminals
        item.pickupTerminals.forEach((terminal) => {
            if (!terminal.value) {
                isValid = false;
                pickupErrorClass = 'slds-has-error'; // Apply error class for pickup terminal
            }
        });
    
        // Validate Drop Terminals
        item.dropTerminals.forEach((terminal) => {
            if (!terminal.value) {
                isValid = false;
                dropErrorClass = 'slds-has-error'; // Apply error class for drop terminal
            }
        });
    
        // Update the error classes for the item
        item.pickupErrorClass = pickupErrorClass;
        item.dropErrorClass = dropErrorClass;
    
        return isValid;
    }
    
    
    

    handleAddOnSelect(event) {
        const index = event.target.dataset.index;  // Get the index of the clicked row
        const isValid = this.validatePicklistSelections(index);  // Pass the index to validate only the clicked add-on
    
        if (isValid) {
            this.selectedAddonRowIndex = index;  // Update selected row
            this.updateButtonAddonLabels(index);
            this.selectedAddon = this.getAddonDetail[index].addOnName;
            this.selectedAddonAmount = this.getAddonDetail[index].addOnTag;    
            this.orderSummaryAddon = this.getAddonDetail
                .filter(wrapper => wrapper.buttonLabel === 'Remove') // Filter condition
                .map(wrapper => {
                    return {
                        name: wrapper.addOnName + ' ' + wrapper.adddOnCount + ' Qty',
                        amount: wrapper.addOnTag * wrapper.adddOnCount,
                        totalAmount: wrapper.addOnTag * wrapper.adddOnCount,
                        netAmount: wrapper.priceTagBeforeTax * wrapper.adddOnCount,
                        cgstAmount: wrapper.cgst * wrapper.adddOnCount,
                        sgstAmount: wrapper.sgst * wrapper.adddOnCount,
                        igstAmount: wrapper.igst * wrapper.adddOnCount,
                        button: true,
                        productId: wrapper.productId,
                        pricebookEntryId: wrapper.pricebookEntryId,
                        unitPrice: wrapper.addOnTag,
                        count: wrapper.adddOnCount,
                        pickupTerminals: wrapper.pickupTerminals.map(terminal => terminal.value),
                        dropTerminals: wrapper.dropTerminals.map(terminal => terminal.value),
                        discountValue: 0,
                        isChild: false,
                        isInfant: false
                    };
                });
    
            this.orderSummary = [...this.orderSummaryPackage, ...this.orderSummaryAddon];
            this.calculateTotalPackage();
            console.log('orderSummary-->> ', JSON.stringify(this.orderSummary));
        } else {
            this.showToast('Error', 'Please select terminals', 'error');
        }
    }
    

    // Precompute button labels for each row
    updateButtonPackageLabels() {
        this.getPackage = this.getPackage.map((wrapper, index) => {
            return {
                ...wrapper, // Keep existing properties
                buttonLabel: this.selectedRowIndex == index ? 'Selected' : 'Select', // Change label based on selection
                class: this.selectedRowIndex == index ? 'encalmbg' : 'selectbtn' //change the class as per selection
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
        this.calculateTotalGst();
        this.calculateTotalPackageDiscount();
        this.totalAmountAfterDiscount = this.totalAmount - this.totalDiscountAmount;
    }
    calculateTotalPackageDiscount() {
        this.totalDiscountAmount = this.orderSummary.reduce((sum, currentItem) => {
            return sum + currentItem.discountValue;
        }, 0); 
        //to show the amount in order summary  
        if (this.totalDiscountAmount>0) {
            this.showDiscount = true;
            this.amountMessage = 'Final Amount After Discount';
        }  else {
            this.showDiscount = false;
            this.amountMessage = 'Final Amount';
        }  
    }
    calculateTotalGst() {
        let totalNetAmount = 0;
        let totalCgstAmount = 0;
        let totalSgstAmount = 0;
        let totalIgstAmount = 0;
        this.orderSummary.forEach(item => {
            totalNetAmount += item.netAmount || 0;
            totalCgstAmount += item.cgstAmount || 0;
            totalSgstAmount += item.sgstAmount || 0;
            totalIgstAmount += item.igstAmount || 0;
        });
        this.totalNetAmount = totalNetAmount;
        this.totalCgstAmount = totalCgstAmount;
        this.totalSgstAmount = totalSgstAmount;
        this.totalIgstAmount = totalIgstAmount;
        if (this.totalCgstAmount !=0 && this.totalSgstAmount!=0) {
            this.showGst = true;
            this.showCgst =true;
        } else if (this.totalIgstAmount !=0) {
            this.showGst = true;
            this.showIgst = true;
        }
    }
    async openPassengerPage() {
        let matchFound = false;
        let buttonLabel = 'buttonLabel';
        for (let item of this.getPackage) {
            // Check if the package is selected
            if (item[buttonLabel] == 'Selected') {
                matchFound = true;
                break;  // Exit loop after finding the match
            }
        }
        if (matchFound && this.processState != 'Preview') {            
            await this.createOLIs();
            this.showModal=false;
            this.passengerDetailPage = true;
            this.updateBookingCurrentState('Package Selection');
            window.scrollTo({top: 0, behavior:'smooth'});            
            this.updateProcesses();
        } else if (matchFound && this.processState == 'Preview') { //scenario for edit button
            this.showModal=false;
            this.passengerDetailPage = true;            
            this.addnewPassengerOnUpdate();
            window.scrollTo({top: 0, behavior:'smooth'});
        } else {
            this.showToast('Error', 'Please select a package: !', 'error');
        }
    }
    //Method to update the Booking current state
    updateBookingCurrentState(processState) {
        updateBookingState({ opportunityId: this.recordId, getProcessState: processState})
            .then(result => {
            })
            .catch(error => {
                console.error('Error creating Opportunity Line Items: ', error);
                this.showToast('Error', error, 'error');
            });
    }

    // Method to call Apex and create Opportunity Line Items
    async createOLIs() {
        await createOpportunityLineItems({ opportunityId: this.recordId, productDetails: this.orderSummary, amount: this.totalAmountAfterDiscount })
            .then(result => {
            })
            .catch(error => {
                console.error('Error creating Opportunity Line Items: ', error);
                this.showToast('Error', error, 'error');
            });
    }

    loadPassengerData() {
        getOpportunityDetails({opportunityId: this.recordId})
        .then((result) => {
            this.isLoading = true;
            this.serviceAirport = result.serviceAirport;
            this.flightType = result.flightType;
            this.flightNumber = result.flightNumber;
            this.flightDate = result.flightDate;
            this.numberOfAdults = this.numberOfAdults != 0 ? this.numberOfAdults : result.NoOfAdult; 
            this.numberOfChildren = this.numberOfChildren != 0 ? this.numberOfChildren : result.NoOfChild;
            this.numberOfInfants = this.numberOfInfants !=0 ? this.numberOfInfants : result.NoOfInfant;
            this.bookingStage = result.bookingStage;
            this.checkSurcharge = result.checkSurcharge;
            this.surcharge = result.checkSurcharge;
            this.editSurcharge = result.surchargeRequestStatus;
            if(this.surcharge)
            this.disableSurchargeWaiveOffInput = true;
            //Added by Abhishek
            this.booker = result.booker;
            this.location = result.location;
            if(result.booker != null && result.booker != undefined && result.booker != ''){
                this.bookerApplicable = true;
            }
            this.guestRows = []; 
            this.addGuestRows('Adult', this.numberOfAdults);
            this.addGuestRows('Child', this.numberOfChildren);
            this.addGuestRows('Infant', this.numberOfInfants);
            this.fetchProcessState();

            /*const created = new Date(result.createdDate);
            const service = new Date(result.serviceDateTime);
            const diffMs = service.getTime() - created.getTime(); // difference in milliseconds
            const twelveHoursInMs = 12 * 60 * 60 * 1000;
            if (diffMs < twelveHoursInMs) {
                this.surchargeApplicable = true;
            }*/
            this.surchargeDataLoad();
            this.isLoading = false;
        })
        .catch((error) => {
            console.error(error);
            this.isLoading = false;
        });
    }
    surchargeDataLoad() {
    loadSurcharge({opportunityId: this.recordId})
    .then((result) => {
            this.surchargePackage = result;
            console.log('this.surchargePackage>>>',this.surchargePackage);
            const surcharge = this.surchargePackage;
            console.log('>>>surcharge',surcharge);
            

        }).catch((error) => {
            console.error(error);
            this.isLoading = false;
        });
    }
    //check if passenger row is not a last row
    get canDelete() {
        return this.guestRows.length > 1; // Only show delete button if there's more than one row
    }
    //handle guest row delete
    handleDelete(event) {
        if (this.guestRows.length > 1) {
            const index = event.target.dataset.index;
            this.guestRows.splice(index, 1);
            this.guestRows = [...this.guestRows]; // Ensures reactivity
        }        
        // Recalculate counts based on the updated guestRows array
        this.updateGuestCounts();
    }
    //to select new row for passenger
    handleGuestTypeChange(event) {
        this.newGuestType = event.target.value;
    }

    handleAddGuest() {
        // Add new guest row dynamically based on selected type
        this.guestRows.push({
            id: `${this.newGuestType}-${this.guestRows.length}`,
            pass: this.newGuestType,
            type: this.newGuestType,
            title: '',
            firstname: '',
            lastname: '',
            gender: '',
            age: null,
            designation: '',
            travelclass: '',
            travelpnrno: '',
            nationality: '',
            passportnumber: '',
            phone: '',
            showDropdown: false,
            isPlacard: this.guestRows.length === 0 && this.newGuestType === 'Adult' ? true : false
        });

        this.guestRows = [...this.guestRows]; // Ensuring reactivity
        this.updateGuestCounts(); // Update the guest counts
    }
     // Add rows for a specific type of guest (Adult/Child/Infant)
    addGuestRows(type, count) {
        for (let i = 0; i < count; i++) {
            this.guestRows.push({
                id: `${type}-${i}`,
                pass: type,
                type: type,
                title: '',
                firstname: '',
                lastname: '',
                gender: '',
                age: null,
                designation: '',
                travelclass: '',
                travelpnrno: '',
                nationality: '',
                passportnumber: '',
                phone: '',
                showDropdown: false,
                isPlacard: i==0 && type == 'Adult' ? true : false
            });
        }
        if (type == 'Adult') {
            this.guestRowsAdults = [...this.guestRows];
        } else if (type == 'Child') {
            this.guestRowsChilds = [...this.guestRows];
        } else {
            this.guestRowsInfants = [...this.guestRows];
        }
    }
    
    @track minAgeValaue
    @track maxAgeValaue
    @track minimumAgeError
    @track maxAgeError

    handleChange(event) {
        debugger;
        const field = event.target.label.toLowerCase().replace(/ /g, '');
        const value = event.target.value;
        const index = event.target.dataset.index;  // Use data attribute for index
        console.log('value',value);
        // Ensure the index exists and is valid
        if (this.guestRows[index]) {
            this.guestRows[index][field] = value;
        }
        const guestType = this.guestRows[index]['pass'];
        const ageInput = event.target;
        const numericValue = parseFloat(value);
        // Clear any previous error
        ageInput.setCustomValidity('');

        // --- Validation Logic ---
        if (field === 'age') {
            if (guestType === 'Adult' && numericValue < 12) {
                ageInput.setCustomValidity('Age must be 12 or more for Adults.');
            } else if (guestType === 'Child' && (numericValue < 2 || numericValue > 11)) {
                ageInput.setCustomValidity('Age for Children must be between 2 and 11.');
            } else if (guestType === 'Infant' && numericValue > 1) {
                ageInput.setCustomValidity('Age for Infants must be less Than 2.');
            }
            ageInput.reportValidity();
        }
        if(field == 'phone'){
            const phoneValue = value.trim();
            // Check if phone is made up of only zeros (e.g., '0000000000')
            if (/^0+$/.test(phoneValue)) {
                event.target.setCustomValidity('Phone number cannot contain only zeros.');
            } else {
                event.target.setCustomValidity('');
            }
            ageInput.reportValidity();
        }
        
        // Find the selected passenger with isPlacard === true
        const selectedGuest = this.guestRows.find(guest => guest.isPlacard);
        if (selectedGuest) {
            // Only update selectedPassenger if the user is editing guest details
            this.selectedPassenger = { ...selectedGuest };
        }
         // Validate after each change (onblur event)
         this.validatePhoneNumbers();
        
    }
    //check for nationality only if internation
    get isNationalityRequired() {
        return this.flightType?.toLowerCase().includes("international");
    }

    handleNationalityChange(event) {
        const index = event.target.dataset.index;    
        // Logic for searching the key in the picklist for Nationality
        const searchKey = event.target.value.toLowerCase();
        // Filter nationality options based on the searchKey
        this.filteredNationalityOptions = this.nationalityOptions.filter(option =>
            option.label.toLowerCase().includes(searchKey)
        );
        // Create a shallow copy of the guests array
        const updatedGuests = [...this.guestRows];
        // Update the nationality for the specific guest in the copy
        updatedGuests[index].nationality = event.target.value;
        // Reassign the modified array to trigger reactivity in LWC
        this.guestRows = updatedGuests;
    }

    handleNationalityDropdownOpen(event) {
        const index = event.target.dataset.index;
        // Create a shallow copy of the guestRows array
        const updatedGuestRows = [...this.guestRows];

        // Update showDropdown for the correct guest based on the index
        updatedGuestRows.forEach((guest, i) => {
            if (i === parseInt(index)) {
                guest.nationality = '';
                guest.showDropdown = true;  // Open the dropdown for this guest
            } else {
                guest.showDropdown = false;  // Close dropdowns for all other guests
            }
        });

        // Reassign updatedGuestRows back to guestRows (this triggers reactivity)
        this.guestRows = updatedGuestRows;
        this.filteredNationalityOptions = this.nationalityOptions;
    }

    handleDropDownClose(event) {
        const index = event.target.dataset.index;
        // Create a shallow copy of the guestRows array
        const updatedGuestRows = [...this.guestRows];
        // Update showDropdown to false for the specific guest
        updatedGuestRows.forEach((guest, i) => {
            if (i === parseInt(index)) {
                guest.showDropdown = false;  // Close the dropdown for this guest
            }
        });
        // Reassign updatedGuestRows back to guestRows (this triggers reactivity)
        this.guestRows = updatedGuestRows;
        this.handleBlur();
        this.handleNationalityCheck(event);
    }

    handleNationalityOptionSelect(event) {
        const selectedValue = event.target.dataset.value;
        const index = event.target.dataset.index;

        // Create a shallow copy of the guestRows array
        const updatedGuestRows = [...this.guestRows];

        // Update the nationality for the selected guest
        updatedGuestRows[index].nationality = selectedValue;

        // Close the dropdown after selection
        updatedGuestRows[index].showDropdown = false;

        // Reassign updatedGuestRows back to guestRows (this triggers reactivity)
        this.guestRows = updatedGuestRows;
    }

    handlePlacardRadioButtonChange(event) {
        const selectedPassengerId = event.target.value;  
        // Update guestRows: set isPlacard to true for selected passenger, false for others
        this.guestRows = this.guestRows.map(guest => {
            // If the guest is the selected one, set isPlacard to true, else false
            guest.isPlacard = guest.id === selectedPassengerId;
            return guest;
        });     
         // Find the new selected guest and update placard details
        this.selectedPassenger = { ...this.guestRows.find(guest => guest.isPlacard) };
    }
    @track showConfirmationPopup = false
    handleSurcharge(event) {
        //this.surcharge = event.target.checked; // This will be true when selected
        //this.updateSurchargeOnBooking();
        if( event.target.checked){
        this.showConfirmationPopup = event.target.checked;
        event.target.checked = false;
        }
    }
    confirmSurcharge(){
        /*const checkbox = this.template.querySelector('lightning-input[type="checkbox"]');
        if (checkbox) {
            checkbox.checked = true;
        }*/
        this.surcharge = true; 
        this.updateSurchargeOnBooking();
        this.disableSurchargeWaiveOffInput = true;
        this.showConfirmationPopup = false;
        this.showToast('Success', 'Surcharge Waive off request submitted successfully', 'success');
    }
    closePopup(){
        //this.surcharge = false;
        this.showConfirmationPopup = false;
    }

    handleTerminalChange(event) {
        const id = event.target.dataset.id.split('-')[0];  // Extract the unique id from the data-id
        const value = event.target.value;    // Get the selected value
        const field = event.target.name;     // Get the picklist name (drop or pickup)
        const index = event.target.dataset.index; // Get the index for the terminal (if applicable)
    
        // Find the item in the array by matching the addOnName (unique ID)
        const item = this.getAddonDetail.find(item => item.addOnName == id);
    
        if (item) {
            // Determine which terminal we are updating (pickup or drop)
            if (field === 'pickup') {
                // Update the corresponding pickup terminal at the correct index
                item.pickupTerminals[index].value = value;
                // Also update the record field (pickupTerminal) if necessary
                item.pickupTerminal = value;
            } else if (field === 'drop') {
                // Update the corresponding drop terminal at the correct index
                item.dropTerminals[index].value = value;
                // Also update the record field (dropTerminal) if necessary
                item.dropTerminal = value;
            }
        }
    }
    
    

    //to get field values to save in opp record
    handleFieldChange(event) {
        const fieldName = event.target.name;
        const fieldValue = event.target.value;

        this.opportunityFieldValues[fieldName] = fieldValue;
    }
    handleTitleChange(event) {
        this.selectedPassenger.title = event.target.value;
    }
    handleFirstNameChange(event) {
        this.selectedPassenger.firstname = event.target.value;
    }
    handleLastNameChange(event) {
        this.selectedPassenger.lastname = event.target.value;
    }
    handleMobChange(event) {
        this.selectedPassenger.phone = event.target.value;
    }

     // Handle the Save action
     handleSave() {
        if (!this.hasDataChanged()) {
            this.showPreview = true;
            this.passengerDetailPage = false;
            this.isQuotationSent = true;
            this.disableSurchargeWaiveOffInput = true;
        } else {
            this.showPackageSelection();   
            this.disableSurchargeWaiveOffInput = this.editSurcharge == 'Approved' ? true :false;
            this.surcharge = this.editSurcharge == 'Approved' ? true :false; 
            const All_Input_Valid = [...this.template.querySelectorAll('lightning-input')]
                .reduce((validSoFar, input_Field_Reference) => {
                    input_Field_Reference.reportValidity();
                    return validSoFar && input_Field_Reference.checkValidity();
                }, true);
            const All_Compobox_Valid = [...this.template.querySelectorAll('lightning-combobox')]
            .reduce((validSoFar, input_Field_Reference) => {
                input_Field_Reference.reportValidity();
                return validSoFar && input_Field_Reference.checkValidity();
            }, true);
            var errorMessage = 'Please resolve all the required checks.'
            //var validationMessage = this.guestRows.length < 2 ? 'Please enter the contact number' : 'Please enter phone number of minimum 1 adult passenger';
            
            if(All_Input_Valid && All_Compobox_Valid && !this.showPhoneErrorMessage) {
                // if (this.processState == 'Preview') {
                //     this.createOLIs();
                // }
                
                this.handleUpdatedGUestRows();
                console.log('guests->>> ',JSON.stringify(this.guestRows));
                setTimeout(() => {
                    console.log('orderSummary->>> ',JSON.stringify(this.orderSummary));
                createOpportunityLineItems({ opportunityId: this.recordId, productDetails: this.orderSummary, amount: this.totalAmountAfterDiscount })
                .then(result => {
                })
                .catch(error => {
                    console.error('Error creating Opportunity Line Items: ', error);
                    this.showToast('Error', error, 'error');
                });
                savePassengerDetails({ passengerData: this.guestRows, opportunityId: this.recordId })
                .then(() => {
                    this.showPreview = true;
                    this.passengerDetailPage = false;
                    this.updateBookingCurrentState('Passenger Details');
                    //this.updateSurchargeOnBooking();
                    this.handlePlacardDetails();// save placard details
                })
                .catch(error => {
                    // Handle error
                    console.error('Error saving passenger details:', error);
                    this.showToast('Error', 'Error saving Passenger details', 'error');
                });  
                }, 2000); // Simulate processing delay
                          
            }
            else {
                this.showToast('Error', errorMessage, 'error');
            }
        }
        
    }
    updateSurchargeOnBooking(){
            submitForSurchargeApproval({ surcharge : this.surcharge, opportunityId: this.recordId })
                .then(() => {
                    
                })
                .catch(error => {
                    // Handle error
                    console.error('Error saving surcharge details:', error);
                    this.showToast('Error', 'Error saving surcharge details', 'error');
                }); 
    }
    checkPhoneNumber() {
        // Check if at least one adult has a filled phone
        let isValid = false;
        for (let guest of this.guestRows) {
            if (guest.type == 'Adult' && guest.phone != '') {
                isValid = true;
                break; // Exit the loop as soon as one adult has a phone
            }
        }
        if (isValid) {
            return true;
        } else {
            return false;
        }
    }

    // Validate the phone fields and check if all required fields are filled
    validatePhoneNumbers() {
        let allRequiredFieldsFilled = true;
        let isPhoneValid = false;

        // Check if all required fields are filled
        this.guestRows.forEach(guest => {
            if (
                !guest.title || !guest.firstname || !guest.lastname || !guest.gender || (!guest.nationality && this.isNationalityRequired)
            ) {
                allRequiredFieldsFilled = false;
            }
            // Check if at least one phone number is entered
            if (guest.phone && guest.phone.trim() !== '') {
                isPhoneValid = true;
            }
        });

        // If all required fields are filled and no phone number is entered, show error
        this.showPhoneErrorMessage = allRequiredFieldsFilled && !isPhoneValid;

        return allRequiredFieldsFilled && isPhoneValid;
    }
    

    // Handle the blur event to trigger validation when a required field loses focus
    handleBlur() {
        this.validatePhoneNumbers();
    }

    handleNationalityCheck(event){
        const field = event.target.label.toLowerCase().replace(/ /g, '');
        const value = event.target.value;
        const index = event.target.dataset.index;

        if (this.guestRows[index]) {
            this.guestRows[index][field] = value;
        }

        // Perform validation only if Nationality is required
        if (field === 'nationality' && this.isNationalityRequired && !value) {
            event.target.setCustomValidity("Nationality is required for international flights.");
        } else {
            event.target.setCustomValidity("");
        }

        event.target.reportValidity();
    }

    handlePlacardDetails() {
        if (this.selectedPassenger) {
            // Serialize the single passenger object and wrap it into an array
            const serializedPassenger = JSON.parse(JSON.stringify([this.selectedPassenger])); // Wrap in []
    
            savePlacardDetails({ placardData: serializedPassenger, opportunityId: this.recordId })
                .then(() => {
                    
                })
                .catch(error => {
                    // Handle error
                    console.error('Error saving placard details:', error);
                    this.showToast('Error', 'Error saving placard details', 'error');
                });
        } else {
            this.showToast('Error', 'No passenger selected to save', 'error');
        }
    }
    openDetailPage(){
        window.scrollTo({top: 0, behavior:'smooth'});
        this.showModal=true;
        this.passengerDetailPage = false;

    }
    // Open the modal
    openModal() {
        this.isModalOpen = true;
    }

    handleUpdatedGUestRows() {
        this.updateGuestCounts(); // Ensure the latest counts before saving
    
        this.opportunityFieldValues['Number_of_Adults__c'] = this.numberOfAdults;
        this.opportunityFieldValues['Number_of_Children__c'] = this.numberOfChildren;
        this.opportunityFieldValues['Number_of_Infants__c'] = this.numberOfInfants;
    
        saveData({ oppId: this.recordId, opportunityFieldValues: this.opportunityFieldValues })
            .then(() => {
            })
            .catch((error) => {
                console.log('error->>>>>>>' + JSON.stringify(error));
            });
    }
    

    // Close the modal
    closePopupModal() {
        this.isModalOpen = false;
    }
    //open passenger page
    //on previous button click from final preview page
    openPassengerDetailPage() {
        window.scrollTo({top: 0, behavior:'smooth'});
        this.passengerDetailPage = true;
        this.showPreview = false;
    }

    generatePdf() {
        // Call Apex method to generate and save PDF with the current record
        generateAndSavePDF({ recordId: this.recordId})
            .then((result) => {
                if (result == 'Quotation Sent') {
                    this.isQuotationSent = true;
                }
                this.showToast('Success', 'Booking Voucher created successfully', 'success');
                this.dispatchEvent(new RefreshEvent());
				this.handleSendEmail();
                this.updateBookingCurrentState('Preview');
                this.disableSurchargeWaiveOffInput = true;
            })
            .catch((error) => {
                this.showToast('Error', 'Error while generating Voucher', 'error');
                console.error(error);
            });
    }

    // Helper function to convert ArrayBuffer to Base64
    arrayBufferToBase64(buffer) {
        const binary = String.fromCharCode.apply(null, new Uint8Array(buffer));
        return window.btoa(binary);
    }

    // Handle the redirection to the list view
    handleRedirect() {
        // Close the modal first
        this.closePopupModal();
        window.location.reload();
        window.scrollTo({top: 0, behavior:'smooth'});
    }
	
	handleSendEmail() {
        sendEmailWithAttachment({ opportunityId: this.recordId , actionType: '' })
            .then(() => {
                this.showToast('Success', 'Email sent successfully!', 'success');
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
            });
    }
    
    // logic to maintain the state of the selected packages
    showPackageSelection() {
        getCurrentPackageDetails({opportunityId: this.recordId})
        .then((result) => {
            this.selectedPackage = result.packageName; 
            this.currentTotalPackageAmount = result.totalBookingAmount;
            const index = this.updateButtonLabels();
            
            if (index !== -1) {
                this.handleSelect(index); // Use it with your existing methods
            } else {
                console.log('No matching package found');
            }
        })
        .catch((error) => {
            console.error(error);
        });
    }

    updateButtonLabels() {
        let matchingIndex = -1; // Initialize a variable to store the index
    
        // Ensure the `index` parameter is explicitly provided in the `forEach` callback
        this.getPackage.forEach((wrapper, index) => {
            // Check if showPackage is true and the packageFamily matches condition
            if (wrapper.showPackage === true && wrapper.packageFamily === this.selectedPackage) {
                wrapper.buttonLabel = 'Selected'; // Update the button label
                matchingIndex = index; // Store the index of the matching package
            } else {
                wrapper.buttonLabel = 'Select';
            }
        });
        this.getPackage = [...this.getPackage];
        return matchingIndex; // Return the index
    }

    showSelectedAddons() {
        if(this.getAddonDetail) {            
            this.orderSummaryAddon = this.getAddonDetail
            .filter(wrapper => wrapper.buttonLabel === 'Remove') // Filter condition
            .map(wrapper => {
                return {
                    name: wrapper.addOnName + ' ' + wrapper.adddOnCount + ' Qty',
                    amount: wrapper.addOnTag * wrapper.adddOnCount,
                    totalAmount: wrapper.addOnTag * wrapper.adddOnCount,
                    button: true,
                    productId: wrapper.productId,
                    pricebookEntryId: wrapper.pricebookEntryId,
                    unitPrice: wrapper.addOnTag,
                    count: wrapper.adddOnCount,
                    pickupTerminals: wrapper.pickupTerminals.map(terminal => terminal.value),
                    dropTerminals: wrapper.dropTerminals.map(terminal => terminal.value),
                    discountValue: 0,
                    isChild: false,
                    isInfant: false
                };
            });
        }
    }

    // logic to maintain the state of the selected packages
    getSavedPassengerData() {
        getSavedPassengerDetails({opportunityId: this.recordId})
        .then((result) => {
            try {
                // Populate guestRows with the retrieved data
                this.guestRows = result.map((guest, index) => {
                    return {
                        id: guest.id,
                        pass: guest.type,
                        type: guest.type,
                        title: guest.title,
                        firstname: guest.firstname,
                        lastname: guest.lastname,
                        gender: guest.gender,
                        age: guest.age,
                        designation: guest.designation,
                        travelclass: guest.travelclass,
                        travelpnrno: guest.travelpnrno,
                        nationality: guest.nationality,
                        passportnumber: guest.passportnumber,
                        phone: guest.phone,
                        showDropdown: false,
                        isPlacard: guest.isPlacard
                    };
                });
                console.log('Retrieved guestRows:', this.guestRows);
            } catch (e) {
                console.error('Error processing retrieved data:', e);
            }
        })
        .catch((error) => {
            console.error(error);
        });
    }

    // logic to maintain the state of the selected packages
    getSavedPlacardData() {
        getSavedPlacardDetails({opportunityId: this.recordId})
        .then((result) => {
            try {
                // Process and populate placardRows
                this.selectedPassenger = result;
            } catch (e) {
                console.error('Error processing retrieved data:', e);
            }
        })
        .catch((error) => {
            console.error(error);
        });
    }
    //edit booking 
    editBooking() {
        this.copyDataBeforeEdit();
        this.showModal = true;
        this.showHeader = true;
        this.showChild = false;
        this.showPreview = false;
        this.passengerDetailPage = false;
        this.isQuotationSent = false;
        this.isEditing = true;
        this.disableSurchargeWaiveOffInput = false;
        window.scrollTo({top: 0, behavior:'smooth'});
    }

    copyDataBeforeEdit() {
        this.orderSummaryBeforeEdit = [...this.orderSummary];
        this.guestRowsBeforeEdit=[...this.guestRows];
        this.selectedPassengerBeforeEdit = { ...this.selectedPassenger };
        this.locationBeforeEdit = this.location;
        this.bookerBeforeEdit = this.booker;
        this.numberOfAdultsBeforeUpdate = this.numberOfAdults;
        this.numberOfChildrenBeforeUpdate = this.numberOfChildren;
        this.numberOfInfantsBeforeUpdate = this.numberOfInfants;
    }

    hasDataChanged() {
        return (
            JSON.stringify(this.orderSummaryBeforeEdit) !== JSON.stringify(this.orderSummary) ||
            JSON.stringify(this.guestRowsBeforeEdit) !== JSON.stringify(this.guestRows) ||
            JSON.stringify(this.selectedPassengerBeforeEdit) !== JSON.stringify(this.selectedPassenger) ||
            this.locationBeforeEdit !== this.location ||
            this.bookerBeforeEdit !== this.booker
        );
    }

    addnewPassengerOnUpdate() {
        this.addGuestRows('Adult', this.numberOfAdults- this.numberOfAdultsBeforeUpdate);
        this.addGuestRows('Child', this.numberOfChildren- this.numberOfChildrenBeforeUpdate);
        this.addGuestRows('Infant', this.numberOfInfants - this.numberOfInfantsBeforeUpdate);
    }

    updateGuestCounts() {
        this.numberOfAdults = this.guestRows.filter(guest => guest.type === 'Adult').length;
        this.numberOfChildren = this.guestRows.filter(guest => guest.type === 'Child').length;
        this.numberOfInfants = this.guestRows.filter(guest => guest.type === 'Infant').length;
    }
    
}