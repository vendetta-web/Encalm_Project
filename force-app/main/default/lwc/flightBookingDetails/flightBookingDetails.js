import { LightningElement, api, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPackageDetails from '@salesforce/apex/PackageSelectionController.getPackages';
import getAddOnDetails from '@salesforce/apex/PackageSelectionController.getAddons';
import getOpportunityDetails from '@salesforce/apex/PackageSelectionController.getOpportunityDetails';
import createOpportunityLineItems from '@salesforce/apex/PackageSelectionController.createOpportunityLineItems';
import savePassengerDetails from '@salesforce/apex/PackageSelectionController.savePassengerDetails';
import savePlacardDetails from '@salesforce/apex/PackageSelectionController.savePlacardDetails';
//import createContentVersion from '@salesforce/apex/MDEN_PdfAttachmentController.createContentVersion';
import getTerminalInfo from '@salesforce/apex/PackageSelectionController.getTerminalInfo';
import getFlightTerminalInfo from '@salesforce/apex/PackageSelectionController.getFlightTerminalInfo';
import jsPDFLibrary from '@salesforce/resourceUrl/jsPDFLibrary';
import { loadScript } from 'lightning/platformResourceLoader';
import { RefreshEvent } from 'lightning/refresh';
import getPicklistValues from '@salesforce/apex/CustomPicklistController.getNationalityPicklistValues';
import generateAndSavePDF from '@salesforce/apex/MDEN_PdfAttachmentController.generateAndSavePDF';

export default class FlightBookingDetails extends NavigationMixin(LightningElement) {
    @api recordId; // Opportunity record ID
    showModal = true;
    showHeader = true;
    showChild = false;
    showPreview = false;
    passengerDetailPage=false;
    isModalOpen = false;
    jsPDFInitialized = false;
    isLoading = false;
    getPackage;
    isQuotationSent=false;
    bookingStage='';
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
    pickupTerminalOptions = [];
    dropTerminalOptions = [];
    totalAmount=0;
    totalDiscountAmount=0;
    totalAmountAfterDiscount=0;
    @track oliFieldValues = {};
    serviceAirport;
    flightType ='Domestic';
    flightNumber;
    flightDate;
    selectedPassenger;
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
    //Passenger Details for adults
    @track guestRowsAdults = [];
    //Passenger details for childs
    @track guestRowsChilds = [];
    //Passenger details for Infants
    @track guestRowsInfants = [];
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
        this.loadPassengerData();
    }
    //for generating PDF
    renderedCallback(){
        if(!this.jsPDFInitialized){
            this.jsPDFInitialized = true;
            loadScript(this, jsPDFLibrary).then(() => {
                console.log('jsPDF library loaded successfully');
            }).catch((error) => {
                console.log('Error loading jsPDF library', error);
            });
        }
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

    loadDetailsAfterUpdate() {
        this.showModal = true;
        this.showHeader = true;
        this.showChild = false;
        this.orderSummaryPackage=[];
        this.orderSummaryAddon=[];
        this.orderSummary=[];
        this.totalAmount=0;
        this.totalDiscountAmount = 0;
        this.totalAmountAfterDiscount = 0;
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
                        productId: wrapper.productId,
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
                        productId: wrapper.productId,
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

            this.orderSummary = [...this.orderSummaryPackage, ...this.orderSummaryAddon];
            this.calculateTotalPackage();
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
            window.scrollTo({top: 0, behavior:'smooth'});
        } else {
            this.showToast('Error', 'Please select a package: !', 'error');
        }
    }

    // Method to call Apex and create Opportunity Line Items
    createOLIs() {
        console.log('order->> ', JSON.stringify(this.orderSummary));
        createOpportunityLineItems({ opportunityId: this.recordId, productDetails: this.orderSummary, amount: this.totalAmountAfterDiscount })
            .then(result => {
                //this.showToast('Success', 'Opportunity Line Items created successfully: !', 'success');
                console.log('Opportunity Line Items created successfully: ', result);
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
            this.numberOfAdults = result.NoOfAdult; 
            this.numberOfChildren = result.NoOfChild;
            this.numberOfInfants = result.NoOfInfant;
            this.bookingStage = result.bookingStage;
            if (this.bookingStage !='' && this.bookingStage == 'Quotation Sent') {
                this.isQuotationSent = true;
            }

            this.guestRows = []; 
            this.addGuestRows('Adult', this.numberOfAdults);
            this.addGuestRows('Child', this.numberOfChildren);
            this.addGuestRows('Infant', this.numberOfInfants);
            this.isLoading = false;
        })
        .catch((error) => {
            console.error(error);
            this.isLoading = false;
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
    

    handleChange(event) {
        const field = event.target.label.toLowerCase().replace(/ /g, '');
        const value = event.target.value;
        const index = event.target.dataset.index;  // Use data attribute for index
        
        // Ensure the index exists and is valid
        if (this.guestRows[index]) {
            this.guestRows[index][field] = value;
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
        console.log('ter-->> ',JSON.stringify(this.getAddonDetail));
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
            savePassengerDetails({ passengerData: this.guestRows, opportunityId: this.recordId })
            .then(() => {
                this.showPreview = true;
                this.passengerDetailPage = false;
                this.savePlacardDetails();// save placard details
            })
            .catch(error => {
                // Handle error
                console.error('Error saving passenger details:', error);
                this.showToast('Error', 'Error saving Passenger details', 'error');
            });            
        }
        else {
            this.showToast('Error', errorMessage, 'error');
        }
        
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

    savePlacardDetails() {
        savePlacardDetails({ placardData: this.selectedPassenger, opportunityId: this.recordId })
            .then(() => {
            })
            .catch(error => {
                // Handle error
                console.error('Error saving placard details:', error);
                this.showToast('Error', 'Error saving placard details', 'error');
            });
    }
    openDetailPage(){
        this.showModal=true;
        this.passengerDetailPage = false;

    }
    // Open the modal
    openModal() {
        this.isModalOpen = true;
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
    //generate PDF file
   /* generatePdf() {
        if (this.jsPDFInitialized) {
            this.isLoading = true;
            // Make sure to correctly reference the loaded jsPDF library.
            const doc = new window.jspdf.jsPDF();

            // Set font size
            doc.setFontSize(12);
            // Iterate over the data array and add content to the PDF
            let y = 40; // starting vertical position
            doc.setFont('helvetica', 'bold');
            doc.setTextColor('#cda45e');
            doc.text('EnCalm', 10, 10);
            doc.setTextColor('black');
            doc.text('Booking Voucher', 70, 10);
            doc.text('Booking Id: NH73184373544094', 120, 10);
            
            doc.setFont('helvetica', 'normal');
            doc.text('Service At Airport : ', 10, 20);
            doc.text(this.serviceAirport, 10, 25);

            doc.text('Number of Adults : ', 70, 20);
            doc.text(this.numberOfAdults.toString(), 70, 25);
            
            if(this.numberOfChildren != undefined && this.numberOfChildren >0) {
                doc.text('Number of Childs : ', 120, 20);
                doc.text(this.numberOfChildren.toString(), 120, 25);
            }
            if(this.numberOfInfants != undefined && this.numberOfInfants >0) {
                doc.text('Number of Infants : ', 150, 20);
                doc.text(this.numberOfInfants.toString(), 120, 25);
            }
            doc.setFont('helvetica', 'bold');
            doc.text('Passenger Details : ', 10, y);

            doc.setFont('helvetica', 'normal');
            this.guestRows.forEach((item, index) => {
                doc.text(`Passenger First Name:  ${item.firstname}`, 70, y); // X, Y position
                doc.text(`Passenger Last Name:  ${item.lastname}`, 70, y + 5); // X, Y position
                doc.text(`Passenger Age:  ${item.age}`, 70, y + 10); // Y position + 5 for next line
                y += 20; // increase Y position for the next entry
            });

            y=y+10;
            
            doc.setFont('helvetica', 'bold');
            doc.text('Package Details : ', 10, y);

            doc.setFont('helvetica', 'normal');
            this.orderSummary.forEach((item, index) => {
                doc.text(`Package Name: ${item.name}`, 70, y); // X, Y position
                doc.text(`Package Amount: ${item.amount}`, 70, y + 5); // Y position + 5 for next line
               // doc.text(`PNR Number: ${item.pnrNo}`, 10, y + 10); // Y position + 10 for next line
                y += 10; // increase Y position for the next entry
            });

            doc.setFont('helvetica', 'bold');
            doc.text('Total Amount: '+ this.totalAmount, 10, y+15);

            //set border
            doc.rect(5, 15,180,y+10);

            doc.setDrawColor(0, 0, 0); // black border color

            // Set the border line width
            doc.setLineWidth(1); // 1 is the line width
            
            // Convert the generated PDF to ArrayBuffer
            const pdfArrayBuffer = doc.output('arraybuffer');

            // Convert the ArrayBuffer to Base64
            const pdfBase64 = this.arrayBufferToBase64(pdfArrayBuffer);

            // Check if the PDF is correctly generated
            if (!pdfBase64 || pdfBase64 === "") {
                console.error('PDF Base64 data is empty!');
                return;
            }

            // Call Apex method to create a ContentVersion and associate it with the current record
            createContentVersion({ recordId: this.recordId, base64Data: pdfBase64 })
                .then((result) => {
                    this.showToast('Success', 'Booking Voucher created successfully', 'success');
                    this.dispatchEvent(new RefreshEvent());
                })
                .catch((error) => {
                    this.showToast('Error', 'Error while generating Voucher', 'error');
                    console.error(error);
                });
        } else {
            console.error('jsPDF library not initialised');
        }
        this.isLoading = false;
    }*/

    generatePdf() {
        // Call Apex method to generate and save PDF with the current record
        generateAndSavePDF({ recordId: this.recordId})
            .then((result) => {
                if (result == 'Quotation Sent') {
                    this.isQuotationSent = true;
                }
                this.showToast('Success', 'Booking Voucher created successfully', 'success');
                this.dispatchEvent(new RefreshEvent());
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
        this.closeModal();

        // Redirect to the list view page
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Opportunity',  // Replace with the object you are using
                actionName: 'list'
            }
        });
    }
}