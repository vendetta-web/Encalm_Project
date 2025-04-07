import { LightningElement, track, api, wire} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPackageDetails from '@salesforce/apex/PackageSelectionController.getPackages';
import getCurrentPackageDetails from '@salesforce/apex/AmendmentBookingController.getExistingPackage';
import upgradePackage from '@salesforce/apex/AmendmentBookingController.upgradePackage';
import getPicklistValues from '@salesforce/apex/CustomPicklistController.getNationalityPicklistValues';
import createOpportunityLineItems from '@salesforce/apex/PackageSelectionController.createOpportunityLineItems';
import savePassengerDetails from '@salesforce/apex/PackageSelectionController.savePassengerDetails';
import getTerminalInfo from '@salesforce/apex/PackageSelectionController.getTerminalInfo';
import getAddOnDetails from '@salesforce/apex/PackageSelectionController.getAddons';
import getOpportunityDetails from '@salesforce/apex/PackageSelectionController.getOpportunityDetails';
import { CloseActionScreenEvent } from 'lightning/actions';
import { updateRecord } from 'lightning/uiRecordApi';
import NUMBER_OF_ADULTS_FIELD from '@salesforce/schema/Opportunity.Number_of_Adults__c';
import NUMBER_OF_CHILD_FIELD from '@salesforce/schema/Opportunity.Number_of_Children__c';
import NUMBER_OF_INFANTS_FIELD from '@salesforce/schema/Opportunity.Number_of_Infants__c';

export default class AmendmentBooking extends LightningElement {
    options = [
        { label: 'Add Passengers', value: 'addPassengers' },
        { label: 'Upgrade Package', value: 'upgradePackage' },
        { label: 'Add Add-Ons', value: 'addAddOns' },
        { label: 'All', value: 'all' }
    ];
    @api recordId;
    adultCount = 0;
    childCount = 0;
    infantCount = 0;
    totalAmount=0;
    totalAddonAmount=0;
    totalAmountAll = 0;
    adddOnCount = 1;
    selectedOption = '';
    selectedPackage = '';
    isAddPassengers = false;
    isUpgradePackage = false;
    isAddAddOns = false;
    isAll = false;
    showOptions = true;
    passengerDetailPage = false;
    confirmAmendment = false;
    openPassengerPage = false;
    confirmMessage ='';
    upgradeMessage = '';
    //Individual Passenger Details
    @track guestRows = [];
    @track guestRowsAll = [];
    @track orderSummary=[];
    @track orderSummaryPackageUpgrade=[];
    @track orderSummaryPackageUpgradeAll=[];
    @track orderSummaryPackage=[];
    @track orderSummaryPackageAll=[];
    @track orderSummaryAddon=[];
    @track getPackage;
    @track nationalityOptions = [];
    @track filteredNationalityOptions = [];
    @track selectedNationality;
    @track getAddonDetail;
    @track pickupTerminalOptions = [];
    @track dropTerminalOptions = [];
    @track filteredPackages = [];
    @track filteredPackagesAll = [];
    @track numberOfAdults = 0;
    @track numberOfChildren = 0;
    @track numberOfInfants = 0;
    @track numberOfAdultsAll = 0;
    @track numberOfChildrenAll = 0;
    @track numberOfInfantsAll = 0;
    currentTotalPackageAmount = 0;
    totalPackageUpgradeAmount = 0;
    totalExtraAmountAll = 0;
    selectedRowIndex = -1;
    selectedPackage = '';
    selectedAmount ='';
    flightType ='Domestic';

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

    @wire(getPicklistValues)
        wiredPicklistValues({ error, data }) {
            if (data) {
                // Map the string values to the required object format for the nationality
                this.nationalityOptions = data.map((value) => ({
                    label: value,
                    value: value
                }));
            } else if (error) {
                console.error('Error fetching nationality values: ', error);
            }
        }

    handleSelection(event) {
        this.selectedOption = event.detail.value;
        this.loadPackageData();
        this.loadCurrentPackageData();
        this.loadAddonData();
    }

    handleNext() {   
        if(this.selectedOption == '') {
            this.showToast('Error', 'Please select an option to proceed', 'error');
        } else {
            this.showOptions = false;     
            this.isAddPassengers = this.selectedOption === 'addPassengers';
            this.isUpgradePackage = this.selectedOption === 'upgradePackage';
            this.isAddAddOns = this.selectedOption === 'addAddOns';
            this.isAll = this.selectedOption === 'all';
            this.loadFilterPackages();
            this.loadOpportunityData();
        }
    }

    loadOpportunityData() {
        getOpportunityDetails({opportunityId: this.recordId})
        .then((result) => {
            this.flightType = result.flightType;
            this.numberOfAdults = result.NoOfAdult; 
            this.numberOfChildren = result.NoOfChild;
            this.numberOfInfants = result.NoOfInfant;
            //for add passenger
            this.adultCount = result.NoOfAdult;
            this.childCount = result.NoOfChild;
            this.infantCount = result.NoOfInfant;
            //for all upgrade
            this.numberOfAdultsAll = result.NoOfAdult; 
            this.numberOfChildrenAll = result.NoOfChild;
            this.numberOfInfantsAll = result.NoOfInfant;
        })
        .catch((error) => {
            console.error(error);
        });
    }

    openFirstPage() {
        this.showOptions = true;
        this.isAddPassengers = false;
        this.isUpgradePackage = false;
        this.isAddAddOns = false;
        this.isAll = false;
        this.resetValuesOnTabChanges();
    }

    openPassengersPage() {        
        if(this.guestRows.length < 1) {
            this.showToast('Error', 'Please add atleast one passenger!', 'error');
        } else {
            this.isAddPassengers = false;
            this.passengerDetailPage = true;
            this.handlePackageSummary();
        }
    }

    openConfirmationPopup () {
        if ( this.selectedOption === 'addPassengers') {
            this.confirmMessage = 'Are you sure to update the passengers?';
        } else if ( this.selectedOption === 'upgradePackage') {
            this.confirmMessage = 'Are you sure to upgrade the package?';
        } else if ( this.selectedOption === 'addAddOns') {
            this.confirmMessage = 'Are you sure to add the Add-Ons?';
        } else if ( this.selectedOption === 'all') {
            this.confirmMessage = 'Are you sure to amend all the changes?';
        }

    }

    closePopupModal() {
        this.confirmAmendment = false;
    }

    confirmPackageUpgrade() {
        let matchFound = false;
        let buttonLabel = 'buttonLabel';
        for (let item of this.filteredPackages) {
            // Check if the package is selected
            if (item[buttonLabel] == 'Selected') {
                matchFound = true;
                break;  // Exit loop after finding the match
            }
        }
        if(matchFound) {  
        this.openConfirmationPopup();   
        this.confirmAmendment = true;
        } else {
            this.showToast('Error', 'Please select a package to upgrade: !', 'error');
        }
    }

    confirmPassengerSave() {       
        var errorMessage = 'Please resolve all the required checks.'
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
        if (All_Input_Valid && All_Compobox_Valid) {
            this.openConfirmationPopup();   
            this.confirmAmendment = true;
        } else {
            this.showToast('Error', errorMessage, 'error');
        }        
    }

    confirmAddOnSave() {
        if(this.isAddAddOns) {         
            let matchFound = false;
            let buttonLabel = 'buttonLabel';
            for (let item of this.getAddonDetail) {
                // Check if the package is selected
                if (item[buttonLabel] == 'Remove') {
                    matchFound = true;
                    break;  // Exit loop after finding the match
                }
            }
            if (matchFound) {                
                var errorMessage = 'Please resolve all the required checks.'
                const All_Input_Valid = [...this.template.querySelectorAll('lightning-input')]
                    .reduce((validSoFar, input_Field_Reference) => {
                        input_Field_Reference.reportValidity();
                        return validSoFar && input_Field_Reference.checkValidity();
                    }, true);

                if(All_Input_Valid) {
                    this.openConfirmationPopup();   
                    this.confirmAmendment = true;
                } else {
                    this.showToast('Error', errorMessage, 'error');
                }
            } else {
                this.showToast('Error', 'Please select at least one Add-On', 'error');
            }
        }

    }
    //after confirmation update records
    handleFinalSubmit() {
        this.confirmAmendment = false;
        if( this.selectedOption === 'addPassengers') {
            this.handleFieldUpdate(); 
            this.passengerDetailPage = false;         
        } else if ( this.selectedOption === 'upgradePackage') {
            this.isUpgradePackage = false;
            this.handlePackageUpgrade();
        } else if ( this.selectedOption === 'addAddOns') {
            this.createOlisAddons();
        }
        this.showToast('Success', 'Amendments done successfully: !', 'success');
        // Dispatch an event to close the LWC component
        this.dispatchEvent(new CloseActionScreenEvent()); 
    }
    //update number of new passengers added on opportunity
    handleFieldUpdate() {
        const fields = {};
        fields.Id = this.recordId;
        fields[NUMBER_OF_ADULTS_FIELD.fieldApiName] = this.adultCount;
        fields[NUMBER_OF_CHILD_FIELD.fieldApiName] = this.childCount;
        fields[NUMBER_OF_INFANTS_FIELD.fieldApiName] = this.infantCount;
        const recordInput = { fields };
        // Call updateRecord to save the updated values to Salesforce
        updateRecord(recordInput)
            .then(() => {
                this.createOliAndPassengerRecords();
            })
            .catch(error => {
                console.error('Error in handleFieldUpdate method->> ',error);
            });
    }

    createOliAndPassengerRecords() {
        createOpportunityLineItems({ opportunityId: this.recordId, productDetails: this.orderSummary, amount: this.totalAmount })
            .then(result => {
                console.log('Opportunity Line Items created successfully: ', result);
            })
            .catch(error => {
                console.error('Error creating Opportunity Line Items: ', error);
            });

        savePassengerDetails({ passengerData: this.guestRows, opportunityId: this.recordId })
            .then(() => {
                console.log('Passenger created successfully: ', result);
            })
            .catch(error => {
                // Handle error
                console.error('Error saving passenger details:', error);
                this.showToast('Error', 'Error saving Passenger details', 'error');
            });
    }
    //upgrade the package
    handlePackageUpgrade() {
        upgradePackage({ opportunityId: this.recordId, productDetails: this.orderSummaryPackageUpgrade})
            .then(result => {
            })
            .catch(error => {
                console.error('Error upgrading package ', error);
            });
    }

    createOlisAddons() {
        createOpportunityLineItems({ opportunityId: this.recordId, productDetails: this.orderSummaryAddon, amount: this.totalAddonAmount })
            .then(result => {  
            })
            .catch(error => {
                console.error('Error creating Opportunity Line Items: ', error);
            });
    }

    openPassengerAddPage() {
        this.passengerDetailPage = false;
        this.isAddPassengers = true;
    }

    incrementAdult() {
        //for All scenario
        if (this.isAll)   {
            this.numberOfAdultsAll += 1;
            this.addGuestRowsAll('Adult', 1);
        } else {
            this.adultCount += 1;
            this.addGuestRows('Adult', 1);
        }
    }

    decrementAdult() {
        //for All scenario
        if (this.isAll)   {
            if (this.numberOfAdultsAll > this.numberOfAdults) {
                this.numberOfAdultsAll -= 1;
                this.removeLastGuestRowAll('Adult'); 
            }
        } else {
            if (this.adultCount > this.numberOfAdults) {
                this.adultCount -= 1;
                this.removeLastGuestRow('Adult'); 
            }
        }     
    }

    incrementChild() {
        if (this.isAll)   {
            this.numberOfChildrenAll += 1;
            this.addGuestRowsAll('Child', 1);
        } else {
            this.childCount += 1;        
            this.addGuestRows('Child', 1);
        }
    }

    decrementChild() { 
        if (this.isAll)   {
            if (this.numberOfChildrenAll > this.numberOfChildren) {
                this.numberOfChildrenAll -= 1;
                this.removeLastGuestRowAll('Child');            
            }
        } else {
            if (this.childCount > this.numberOfChildren) {
                this.childCount -= 1;
                this.removeLastGuestRow('Child');            
            } 
        }
    }

    incrementInfant() {
        if (this.isAll)   {
            this.numberOfInfantsAll += 1;
            this.addGuestRowsAll('Infant', 1);
        } else {
            this.infantCount += 1;
            this.addGuestRows('Infant', 1);
        }
    }

    decrementInfant() {
        if (this.isAll)   {
            if (this.numberOfInfantsAll > this.numberOfInfants) {
                this.numberOfInfantsAll -= 1;
                this.removeLastGuestRowAll('Infant');
            }
        }  else {
            if (this.infantCount > this.numberOfInfants) {
                this.infantCount -= 1;
                this.removeLastGuestRow('Infant');
            } 
        }     
    }
    //passenger data
    handleChange(event) {
        const field = event.target.label.toLowerCase().replace(/ /g, '');
        const value = event.target.value;
        const index = event.target.dataset.index;  // Use data attribute for index  
        if(this.openPassengerPage) {      
            // Ensure the index exists and is valid
            if (this.guestRowsAll[index]) {
                this.guestRowsAll[index][field] = value;
            }    
        } else {
            // Ensure the index exists and is valid
            if (this.guestRows[index]) {
                this.guestRows[index][field] = value;
            } 
        }    
    }

    //check for nationality only if international
    get isNationalityRequired() {
        return this.flightType?.toLowerCase().includes("international");
    }
    //check for domestic and international
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

    handleNationalityChange(event) {
        const index = event.target.dataset.index;    
        // Logic for searching the key in the picklist for Nationality
        const searchKey = event.target.value.toLowerCase();
        // Filter nationality options based on the searchKey
        this.filteredNationalityOptions = this.nationalityOptions.filter(option =>
            option.label.toLowerCase().includes(searchKey)
        );
        if(this.openPassengerPage) {
            // Create a shallow copy of the guests array
            const updatedGuestsAll = [...this.guestRowsAll];
            // Update the nationality for the specific guest in the copy
            updatedGuestsAll[index].nationality = event.target.value;
            // Reassign the modified array to trigger reactivity in LWC
            this.guestRowsAll = updatedGuestsAll;
        } else {
            // Create a shallow copy of the guests array
            const updatedGuests = [...this.guestRows];
            // Update the nationality for the specific guest in the copy
            updatedGuests[index].nationality = event.target.value;
            // Reassign the modified array to trigger reactivity in LWC
            this.guestRows = updatedGuests;
        }
    }

    handleNationalityDropdownOpen(event) {
        const index = event.target.dataset.index;
        if(this.openPassengerPage) {
            // Create a shallow copy of the guestRows array
            const updatedGuestRowsForAll = [...this.guestRowsAll];
            // Update showDropdown for the correct guest based on the index
            updatedGuestRowsForAll.forEach((guest, i) => {
                if (i === parseInt(index)) {
                    guest.nationality = '';
                    guest.showDropdown = true;  // Open the dropdown for this guest
                } else {
                    guest.showDropdown = false;  // Close dropdowns for all other guests
                }
            });

            // Reassign updatedGuestRowsForAll back to guestRows (this triggers reactivity)
            this.guestRowsAll = updatedGuestRowsForAll;
        } else {            
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
        }

        this.filteredNationalityOptions = this.nationalityOptions;
    }

    handleDropDownClose(event) {
        const index = event.target.dataset.index;
        if(this.openPassengerPage) {
            // Create a shallow copy of the guestRows array
            const updatedGuestRowsForAll = [...this.guestRowsAll];
            // Update showDropdown to false for the specific guest
            updatedGuestRowsForAll.forEach((guest, i) => {
                if (i === parseInt(index)) {
                    guest.showDropdown = false;  // Close the dropdown for this guest
                }
            });
            // Reassign updatedGuestRowsForAll back to guestRows (this triggers reactivity)
            this.guestRowsAll = updatedGuestRowsForAll;
        } else {                
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
            this.handleNationalityCheck(event);
        }
    }

    handleNationalityOptionSelect(event) {
        const selectedValue = event.target.dataset.value;
        const index = event.target.dataset.index;        
        if (this.openPassengerPage) {            
            // Create a shallow copy of the guestRows array
            const updatedGuestRowsForAll = [...this.guestRowsAll];
            // Update the nationality for the selected guest
            updatedGuestRowsForAll[index].nationality = selectedValue;
            // Close the dropdown after selection
            updatedGuestRowsForAll[index].showDropdown = false;
            // Reassign updatedGuestRowsForAll back to guestRows (this triggers reactivity)
            this.guestRowsAll = updatedGuestRowsForAll;
        } else {
            // Create a shallow copy of the guestRows array
            const updatedGuestRows = [...this.guestRows];
            // Update the nationality for the selected guest
            updatedGuestRows[index].nationality = selectedValue;
            // Close the dropdown after selection
            updatedGuestRows[index].showDropdown = false;
            // Reassign updatedGuestRows back to guestRows (this triggers reactivity)
            this.guestRows = updatedGuestRows;
        }   
    }
    
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant,
        });
        this.dispatchEvent(event);
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
                showDropdown: false
            });
        }
    }

    // Method to remove the last row dynamically
    removeLastGuestRow(type) {
        const index = this.guestRows.findLastIndex(row => row.type === type);
        if (index > -1) {
            this.guestRows.splice(index, 1); // Remove the last row
        }
    }
    // get all packages
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

    // get current packages
    loadCurrentPackageData() {
        getCurrentPackageDetails({opportunityId: this.recordId})
        .then((result) => {
            this.selectedPackage = result.packageName; 
            this.currentTotalPackageAmount = result.totalBookingAmount;
        })
        .catch((error) => {
            console.error(error);
        });
    }

    loadFilterPackages() {
        // Reset upgradeMessage
        this.upgradeMessage = '';
        // Define upgrade path rules
        let allowedPackages = [];
        if (this.selectedPackage === 'Silver') {
            allowedPackages = ['Gold', 'Elite'];
        } else if (this.selectedPackage === 'Gold') {
            allowedPackages = ['Elite'];
        } else if (this.selectedPackage === 'Elite') {
            this.upgradeMessage = 'Existing Package is already Elite, Cannot be upgraded';
            this.filteredPackages = undefined; // No packages to show
            this.filteredPackagesAll = []; // No packages to show
            return;
        }
        
        if (this.selectedPackage != 'Elite') {
            // Filter the packages based on the allowed package families
            this.filteredPackages = this.getPackage.filter(pkg =>
                allowedPackages.includes(pkg.packageFamily)
            );
        }
        this.filteredPackagesAll = [...this.filteredPackages]; // copy filtered data
    }

    loadAddonData() {
        getAddOnDetails({oppId: this.recordId})
        .then((result) => {
            this.getAddonDetail = result; 
            this.getAddonDetail = result.map((item) => ({
                ...item, // Spread the existing properties
                buttonLabel: 'Select', // Add buttonLabel to each item
                adddOnCount: this.adddOnCount,
                class: 'btns select',
                pickupDataId: `${item.addOnName}-pickup`,  // Unique data-id for pickup terminal,
                dropDataId: `${item.addOnName}-drop`,  // Unique data-id for drop terminal
            }));
            this.getTerminals();
        })
        .catch((error) => {
            console.error(error);
        });
    }

    getTerminals() {
        getTerminalInfo({oppId: this.recordId})
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

    handleTerminalChange(event) {
        const id = event.target.dataset.id.split('-')[0];  // Extract the unique id from the data-id
        const value = event.target.value;    // Get the selected value
        const field = event.target.name;     // Get the picklist name (drop or pickup)

        // Find the item in the array and update the corresponding field (drop or pickup)
        const item = this.getAddonDetail.find(item => item.addOnName == id);
        if (item) {
            item[field] = value;
        }
        // Update the value for pack.dropTerminal or pack.pickupTerminal
        if (field === 'drop') {
            item.dropTerminal = value; // Update the dropTerminal in the pack
        } else if (field === 'pickup') {
            item.pickupTerminal = value; // Update the pickupTerminal in the pack
        }
    }

    incrementAddOn(event) {
        const ind = event.target.dataset.index;  // Get the index of the clicked row
        this.getAddonDetail = this.getAddonDetail.map((wrapper, index) => {
            return {
                ...wrapper, 
                adddOnCount: ind == index ? wrapper.adddOnCount += 1 :  wrapper.adddOnCount
            };
        });
    }

    decrementAddOn(event) {
        const ind = event.target.dataset.index;  // Get the index of the clicked row
        this.getAddonDetail = this.getAddonDetail.map((wrapper, index) => {
            return {
                ...wrapper, 
                adddOnCount: ind == index ? wrapper.adddOnCount >1 ? wrapper.adddOnCount -= 1 :  1 : wrapper.adddOnCount
            };
        });
    }

    handleAddOnSelect(event){
        const index = event.target.dataset.index;  // Get the index of the clicked row
        // Get the data-id values for pickup and drop terminals based on the selected index
        const pickupDataId = this.getAddonDetail[index].pickupDataId;
        const dropDataId = this.getAddonDetail[index].dropDataId;

        // Target the comboboxes for the selected index using the data-id attributes
        const pickupCombobox = this.template.querySelector(`[data-id="${pickupDataId}"]`);
        const dropCombobox = this.template.querySelector(`[data-id="${dropDataId}"]`);

        // Validate pickup and drop terminals for the selected index
        const All_Compobox_Valid = [pickupCombobox, dropCombobox].reduce((validSoFar, input_Field_Reference) => {
            input_Field_Reference.reportValidity();
            return validSoFar && input_Field_Reference.checkValidity();
        }, true);

        if (All_Compobox_Valid) {
            this.updateButtonAddonLabels(index);        
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
                    count: wrapper.adddOnCount,
                    pickup: wrapper.pickup,
                    drop: wrapper.drop,
                    isChild: false,
                    isInfant: false
                };
            });   
            if (this.isAll) {
                this.orderSummaryPackageUpgradeAll = [...this.orderSummaryPackageAll, ...this.orderSummaryAddon];
                this.calculateTotalPackageAll();
            } else {
                this.calculateTotalAddonAmount();
            }  
        } else {
            this.showToast('Error', 'Please select terminals', 'error');
        }        
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

    //Method to show the order summary on adding passengers
    handlePackageSummary() {
        console.log('getPackage',JSON.stringify(this.getPackage));
        this.orderSummaryPackage = this.getPackage
        .filter(wrapper => wrapper.packageFamily == this.selectedPackage && wrapper.priceTag != undefined) // Filter the existing Package
        .map(wrapper => {
            // Create an array of records based on the number of adults
            const records = [];
                if (this.adultCount - this.numberOfAdults > 0) { 
                    records.push({
                        name: wrapper.packageName + ' (' + (this.adultCount - this.numberOfAdults)  + ' Adult)', // Copy the 'name' value for adult
                        amount: wrapper.priceTag * (this.adultCount - this.numberOfAdults), // Calculate the amount 
                        totalAmount: wrapper.priceTag * (this.adultCount - this.numberOfAdults),
                        productId: wrapper.productId,
                        pricebookEntryId: wrapper.pricebookEntryId,
                        unitPrice: wrapper.priceTag,
                        count: (this.adultCount - this.numberOfAdults), // Set the count, potentially modify later based on adults
                        isChild: false,
                        isInfant: false
                    });
                }
                if (this.childCount - this.numberOfChildren > 0) {             
                    records.push({
                        name: wrapper.packageName + ' (' + (this.childCount - this.numberOfChildren) + ' child)', // Copy the 'name' value for child
                        amount: wrapper.childPackageWrapper[wrapper.packageFamily].price * (this.childCount - this.numberOfChildren), // Calculate the amount
                        totalAmount: wrapper.childPackageWrapper[wrapper.packageFamily].price * (this.childCount - this.numberOfChildren),
                        productId: wrapper.productId,
                        pricebookEntryId: wrapper.childPackageWrapper[wrapper.packageFamily].priceBookEntryId,
                        unitPrice: wrapper.childPackageWrapper[wrapper.packageFamily].price,
                        count: 1, // Set the count, potentially modify later based on children
                        isChild: true,
                        childCount: (this.childCount - this.numberOfChildren)  //to create child oli records
                    });
                } 
                if (this.infantCount - this.numberOfInfants > 0) {             
                    records.push({
                        name: wrapper.packageName + ' (' + (this.infantCount - this.numberOfInfants) + ' Infant)', // Copy the 'name' value for infant
                        amount: wrapper.infantPackageWrapper[wrapper.packageFamily].price * (this.infantCount - this.numberOfInfants), // Calculate the amount
                        totalAmount: wrapper.infantPackageWrapper[wrapper.packageFamily].price * (this.infantCount - this.numberOfInfants),
                        productId: wrapper.productId,
                        pricebookEntryId: wrapper.infantPackageWrapper[wrapper.packageFamily].priceBookEntryId,
                        unitPrice: wrapper.infantPackageWrapper[wrapper.packageFamily].price,
                        count: 1, // Set the count, potentially modify later based on children
                        isInfant: true,
                        isChild: false,
                        infantCount: (this.infantCount - this.numberOfInfants)  //to create infant oli records
                    });
                }            

            return records; // Return the array of records
        })
        .flat(); // Flatten the array to combine all the records into a single array
        this.orderSummary = [...this.orderSummaryPackage];
        this.calculateTotalAmount();
        
    }

    calculateTotalAmount() {
        this.totalAmount = this.orderSummary.reduce((sum, currentItem) => {
            return sum + currentItem.totalAmount;
        }, 0);
    }

    calculateTotalAddonAmount() {
        this.totalAddonAmount = this.orderSummaryAddon.reduce((sum, currentItem) => {
            return sum + currentItem.totalAmount;
        }, 0);
    }

    // Handle row selection for package upgrade
    handleSelect(event) {
        const index = event.target.dataset.index;  // Get the index of the clicked row
        //this.handleUnselect(event);
        this.selectedRowIndex = index;  // Update selected row
        this.selectedPackage = this.filteredPackages[index].packageName;
        this.selectedAmount = this.filteredPackages[index].priceTag;
        this.updateButtonPackageLabels(); // Recompute the button labels after selection
        this.orderSummaryPackage = this.filteredPackages
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
                    isChild: false,
                    isInfant: false,
                    type: 'Adult'
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
                        isChild: true,
                        childCount: this.numberOfChildren,  //to create child oli records
                        type: 'Child'
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
                        isInfant: true,
                        isChild: false,
                        infantCount: this.numberOfInfants,  //to create infant oli records,
                        type: 'Infant'
                    });
                }            

            return records; // Return the array of records
        })
        .flat(); // Flatten the array to combine all the records into a single array

            this.orderSummaryPackageUpgrade = [...this.orderSummaryPackage];
            this.calculateTotalPackage();
        
    }
    // Precompute button labels for each row
    updateButtonPackageLabels() {
        this.filteredPackages = this.filteredPackages.map((wrapper, index) => {
            return {
                ...wrapper, // Keep existing properties
                buttonLabel: this.selectedRowIndex == index ? 'Selected' : 'Select' // Change label based on selection
            };
        });
    }

    calculateTotalPackage() {
        this.totalAmount = this.orderSummaryPackageUpgrade.reduce((sum, currentItem) => {
            return sum + currentItem.totalAmount;
        }, 0);
        this.totalPackageUpgradeAmount = this.totalAmount - this.currentTotalPackageAmount;
    }

    //logic for All screen 

    // Handle row selection for package upgrade in all option
    handlePackageSelect(event) {
        const index = event.target.dataset.index;  // Get the index of the clicked row
        //this.handleUnselect(event);
        this.selectedRowIndex = index;  // Update selected row
        this.selectedPackage = this.filteredPackagesAll[index].packageName;
        this.selectedAmount = this.filteredPackagesAll[index].priceTag;
        this.updateButtonPackageLabelsAll(); // Recompute the button labels after selection
        this.orderSummaryPackageAll = this.filteredPackagesAll
        .filter(wrapper => wrapper.buttonLabel === 'Selected') // Filter condition
        .map(wrapper => {
            const numberOfRecords = this.numberOfAdultsAll > this.numberOfChildrenAll ? this.numberOfAdultsAll : this.numberOfChildrenAll; // or any other condition to determine number of records
            // Create an array of records based on the number of adults
            const records = [];
                records.push({
                    name: wrapper.packageName + ' (' + this.numberOfAdultsAll + ' Adult)', // Copy the 'name' value for adult
                    amount: wrapper.priceTag * this.numberOfAdultsAll, // Calculate the amount 
                    totalAmount: wrapper.priceTag * this.numberOfAdultsAll,
                    productId: wrapper.productId,
                    pricebookEntryId: wrapper.pricebookEntryId,
                    unitPrice: wrapper.priceTag,
                    count: this.numberOfAdultsAll, // Set the count, potentially modify later based on adults
                    isChild: false,
                    isInfant: false
                });
                if (this.numberOfChildrenAll > 0) {             
                    records.push({
                        name: wrapper.packageName + ' (' + this.numberOfChildrenAll + ' child)', // Copy the 'name' value for child
                        amount: wrapper.childPackageWrapper[wrapper.packageFamily].price * this.numberOfChildrenAll, // Calculate the amount
                        totalAmount: wrapper.childPackageWrapper[wrapper.packageFamily].price * this.numberOfChildrenAll,
                        productId: wrapper.productId,
                        pricebookEntryId: wrapper.childPackageWrapper[wrapper.packageFamily].priceBookEntryId,
                        unitPrice: wrapper.childPackageWrapper[wrapper.packageFamily].price,
                        count: 1, // Set the count, potentially modify later based on children
                        isChild: true,
                        childCount: this.numberOfChildrenAll  //to create child oli records
                    });
                } 
                if (this.numberOfInfantsAll > 0) {             
                    records.push({
                        name: wrapper.packageName + ' (' + this.numberOfInfantsAll + ' Infant)', // Copy the 'name' value for infant
                        amount: wrapper.infantPackageWrapper[wrapper.packageFamily].price * this.numberOfInfantsAll, // Calculate the amount
                        totalAmount: wrapper.infantPackageWrapper[wrapper.packageFamily].price * this.numberOfInfantsAll,
                        productId: wrapper.productId,
                        pricebookEntryId: wrapper.infantPackageWrapper[wrapper.packageFamily].priceBookEntryId,
                        unitPrice: wrapper.infantPackageWrapper[wrapper.packageFamily].price,
                        count: 1, // Set the count, potentially modify later based on children
                        isInfant: true,
                        isChild: false,
                        infantCount: this.numberOfInfantsAll  //to create infant oli records
                    });
                }            

            return records; // Return the array of records
        })
        .flat(); // Flatten the array to combine all the records into a single array

            this.orderSummaryPackageUpgradeAll = [...this.orderSummaryPackageAll, ...this.orderSummaryAddon];
            this.calculateTotalPackageAll();
        
    }

    // Add rows for a specific type of guest (Adult/Child/Infant)
    addGuestRowsAll(type, count) {
        for (let i = 0; i < count; i++) {
            this.guestRowsAll.push({
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
                showDropdown: false
            });
        }
    }

    // Method to remove the last row dynamically
    removeLastGuestRowAll(type) {
        const index = this.guestRowsAll.findLastIndex(row => row.type === type);
        if (index > -1) {
            this.guestRowsAll.splice(index, 1); // Remove the last row
        }
    }

    // Precompute button labels for each row for all scenario
    updateButtonPackageLabelsAll() {
        this.filteredPackagesAll = this.filteredPackagesAll.map((wrapper, index) => {
            return {
                ...wrapper, // Keep existing properties
                buttonLabel: this.selectedRowIndex == index ? 'Selected' : 'Select' // Change label based on selection
            };
        });
    }

    calculateTotalPackageAll() {
        this.totalAmountAll = this.orderSummaryPackageUpgradeAll.reduce((sum, currentItem) => {
            return sum + currentItem.totalAmount;
        }, 0);
        this.totalExtraAmountAll = this.totalAmountAll - this.currentTotalPackageAmount;
    }

    resetValuesOnTabChanges(){
        this.orderSummaryPackageUpgrade=[];
        this.orderSummaryPackageUpgradeAll = [];
        this.orderSummaryAddon = [];
        this.totalAddonAmount = 0;
        this.totalExtraAmountAll = 0;
        this.totalAmount = 0;
        this.guestRowsAll = [];
    }
    handlePassengerInformation() {
        if(this.guestRowsAll.length < 1) {
            this.showToast('Error', 'Please add atleast one passenger!', 'error');
        } else {
            let matchFound = false;
            let buttonLabel = 'buttonLabel';
            for (let item of this.filteredPackagesAll) {
                // Check if the package is selected
                if (item[buttonLabel] == 'Selected') {
                    matchFound = true;
                    break;  // Exit loop after finding the match
                }
            }
            if(matchFound) { 
                let addOnmatchFound = false;
                let buttonLabel = 'buttonLabel';
                for (let item of this.getAddonDetail) {
                    // Check if the addon is selected
                    if (item[buttonLabel] == 'Remove') {
                        addOnmatchFound = true;
                        break;  // Exit loop after finding the match
                    }
                }
                if (addOnmatchFound) {
                    this.isAll = false;
                    this.openPassengerPage = true;
                } else {
                    this.showToast('Error', 'Please select an Add-On!', 'error');
                }
            } else {
                this.showToast('Error', 'Please select a package to upgrade!', 'error');
            }

        }
    }
    confirmAllUpgrade() {
        var errorMessage = 'Please resolve all the required checks.'
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
        if(All_Input_Valid && All_Compobox_Valid) {
            this.openConfirmationPopup();   
            this.confirmAmendment = true;
        } else {
            this.showToast('Error', errorMessage, 'error');
        }
    }

    openUpgradeAllPage() {
        this.openPassengerPage = false;
        this.isAll = true;
    }
    

}