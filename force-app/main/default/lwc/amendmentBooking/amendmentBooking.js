import { LightningElement, track, api, wire} from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPackageDetails from '@salesforce/apex/PackageSelectionController.getPackages';
import getCurrentPackageDetails from '@salesforce/apex/AmendmentBookingController.getExistingPackage';
import upgradePackage from '@salesforce/apex/AmendmentBookingController.upgradePackage';
import getPicklistValues from '@salesforce/apex/CustomPicklistController.getNationalityPicklistValues';
import createOpportunityLineItems from '@salesforce/apex/AmendmentBookingController.createOpportunityLineItems';
import savePassengerDetails from '@salesforce/apex/AmendmentBookingController.savePassengerDetails';
import getTerminalInfo from '@salesforce/apex/PackageSelectionController.getTerminalInfo';
import getAddOnDetails from '@salesforce/apex/PackageSelectionController.getAddons';
import getOpportunityDetails from '@salesforce/apex/PackageSelectionController.getOpportunityDetails';
import sendEmailWithAttachment from '@salesforce/apex/BookingEmailHandler.sendEmailWithAttachment';
import generateAndSavePDF from '@salesforce/apex/MDEN_PdfAttachmentController.generateAndSavePDF';
import { RefreshEvent } from 'lightning/refresh';
import { CloseActionScreenEvent } from 'lightning/actions';
import { updateRecord } from 'lightning/uiRecordApi';
import NUMBER_OF_ADULTS_FIELD from '@salesforce/schema/Opportunity.Number_of_Adults__c';
import NUMBER_OF_CHILD_FIELD from '@salesforce/schema/Opportunity.Number_of_Children__c';
import NUMBER_OF_INFANTS_FIELD from '@salesforce/schema/Opportunity.Number_of_Infants__c';

export default class AmendmentBooking extends NavigationMixin(LightningElement) {
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
    totalNetAmount=0;
    totalCgstAmount=0;
    totalSgstAmount=0;
    totalIgstAmount=0;
    adddOnCount = 1;
    selectedOption = '';
    currentPackage = '';
    selectedPackage = '';
    isAddPassengers = false;
    isUpgradePackage = false;
    isAddAddOns = false;
    isAll = false;
    showOptions = true;
    passengerDetailPage = false;
    confirmAmendment = false;
    openPassengerPage = false;
    showGst = false;
    showCgst =false;
    showIgst =false;
    isLoading=false;
    isPaxAll=false;
    isPckUpgradeAll=false;
    isAddOnAll=false;
    showPaidAmount = false;
    confirmMessage ='';
    upgradeMessage = '';
    //Individual Passenger Details
    @track guestRows = [];
    @track guestRowsAll = [];
    @track orderSummary=[];
    @track orderSummaryPackageUpgrade=[];
    @track orderSummaryPackageUpgradeAll=[];
    @track previousOrderSummaryPackageAll=[];
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
            this.isAll = this.isPaxAll = this.selectedOption === 'all';
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
            const adultCount = this.adultCount - this.numberOfAdults;
            const childCount = this.childCount - this.numberOfChildren;
            const infantCount = this.infantCount - this.numberOfInfants;
            this.handlePackageSummary(this.getPackage,adultCount,childCount,infantCount);
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
            const adultCount = this.adultCount;
            const childCount = this.childCount;
            const infantCount = this.infantCount;
            this.handleFieldUpdate(this.guestRows,this.orderSummary, adultCount,childCount,infantCount); 
            this.passengerDetailPage = false;         
        } else if ( this.selectedOption === 'upgradePackage') {
            this.isUpgradePackage = false;
            this.handlePackageUpgrade(this.orderSummaryPackageUpgrade);
        } else if ( this.selectedOption === 'addAddOns') {
            this.createOlisAddons();
        } else if (this.selectedOption === 'all') {
            if (this.guestRowsAll.length > 0 && 
                this.selectedPackage =='' &&
                this.orderSummaryAddon.length == 0
            ) {
                const adultCount = this.numberOfAdultsAll;
                const childCount = this.numberOfChildrenAll;
                const infantCount = this.numberOfInfantsAll;
                this.handleFieldUpdate(this.guestRowsAll,this.orderSummaryPackageUpgradeAll, adultCount,childCount,infantCount);
            } else if (this.guestRowsAll.length == 0 &&
                this.selectedPackage !=''
            ) {
                this.handlePackageUpgrade(this.orderSummaryPackageUpgradeAll);
            } else if (this.guestRowsAll.length == 0 &&
                this.selectedPackage =='' &&
                this.orderSummaryAddon.length > 0
            ) {
                this.createOlisAddons();
            } else if (this.guestRowsAll.length > 0 && 
                this.selectedPackage !=''
            ) {
                this.handlePackageUpgradeAndSavePax(this.orderSummaryPackageUpgradeAll,this.guestRowsAll);
            } else if (this.guestRowsAll.length > 0 && 
                this.selectedPackage ==''
            ) {
                const adultCount = this.numberOfAdultsAll;
                const childCount = this.numberOfChildrenAll;
                const infantCount = this.numberOfInfantsAll;
                this.handleFieldUpdate(this.guestRowsAll,this.orderSummaryPackageUpgradeAll, adultCount,childCount,infantCount);
            }
        }
        this.showToast('Success', 'Amendments done successfully: !', 'success'); 
    }
    //update number of new passengers added on opportunity
    handleFieldUpdate(guestList,orderList, adultCount,childCount,infantCount) {
        this.isLoading= true;
        const fields = {};
        fields.Id = this.recordId;
        fields[NUMBER_OF_ADULTS_FIELD.fieldApiName] = adultCount;
        fields[NUMBER_OF_CHILD_FIELD.fieldApiName] = childCount;
        fields[NUMBER_OF_INFANTS_FIELD.fieldApiName] = infantCount;
        const recordInput = { fields };
        // Call updateRecord to save the updated values to Salesforce
        updateRecord(recordInput)
            .then(() => {
                this.createOliAndPassengerRecords(guestList,orderList);
            })
            .catch(error => {
                console.error('Error in handleFieldUpdate method->> ',error);
                this.isLoading= false;
            });
    }

    createOliAndPassengerRecords(guestList,orderList) {
        createOpportunityLineItems({ opportunityId: this.recordId, productDetails: orderList, amount: this.totalAmount })
            .then(result => {
                this.savePassengerData(guestList);
            })
            .catch(error => {
                console.error('Error creating Opportunity Line Items: ', error);
            });

        
    }
    savePassengerData(guestList) {
        savePassengerDetails({ passengerData: guestList, opportunityId: this.recordId })
            .then(() => {                
                this.generatePdf();
            })
            .catch(error => {
                // Handle error
                console.error('Error saving passenger details:', error);
                this.isLoading= false;
                this.showToast('Error', 'Error saving Passenger details', 'error');
            });
    }
    
    //upgrade the package
    handlePackageUpgrade(orderSummaryDetails) {
        this.isLoading= true;
        upgradePackage({ opportunityId: this.recordId, productDetails: orderSummaryDetails})
            .then(result => {
                this.generatePdf();
            })
            .catch(error => {
                console.error('Error upgrading package ', error);
                this.isLoading= false;
            });
    }

    //upgrade the package for all scenario
    handlePackageUpgradeAndSavePax(orderSummaryDetails,guestList) {
        this.isLoading= true;
        upgradePackage({ opportunityId: this.recordId, productDetails: orderSummaryDetails})
            .then(result => {
                this.savePassengerData(guestList);
            })
            .catch(error => {
                console.error('Error upgrading package ', error);
                this.isLoading= false;
            });
    }

    createOlisAddons() {
        this.isLoading= true;
        createOpportunityLineItems({ opportunityId: this.recordId, productDetails: this.orderSummaryAddon, amount: this.totalAddonAmount })
            .then(result => {  
                this.generatePdf();
            })
            .catch(error => {
                console.error('Error creating Opportunity Line Items: ', error);
                this.isLoading= false;
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
                showDropdown: false,
                isPlacard: false
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
            this.currentPackage = result.packageName; 
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
        if (this.currentPackage === 'Silver') {
            allowedPackages = ['Gold', 'Elite'];
        } else if (this.currentPackage === 'Gold') {
            allowedPackages = ['Elite'];
        } else if (this.currentPackage === 'Elite') {
            this.upgradeMessage = 'Existing Package is already Elite, Cannot be upgraded';
            this.filteredPackages = undefined; // No packages to show
            this.filteredPackagesAll = []; // No packages to show
            return;
        }
        
        if (this.currentPackage != 'Elite') {
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

    loadAddonData() {
        getAddOnDetails({ oppId: this.recordId })
        .then((result) => {
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
        })
        .catch((error) => {
            console.error(error);
        });
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

    handleAddOnSelect(event){
        const index = event.target.dataset.index;  // Get the index of the clicked row        

        const isValid = this.validatePicklistSelections(index);

        if (isValid) {
            this.updateButtonAddonLabels(index);        
            this.orderSummaryAddon = this.getAddonDetail
            .filter(wrapper => wrapper.buttonLabel === 'Remove') // Filter condition
            .map(wrapper => {
                return {
                    name: wrapper.addOnName+' ' +wrapper.adddOnCount+' Qty',        // Copy the 'name' value
                    amount: wrapper.addOnTag*wrapper.adddOnCount,  // Copy the 'amount' value
                    totalAmount: wrapper.addOnTag*wrapper.adddOnCount,
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
                    isChild: false,
                    isInfant: false,
                    discountValue:0
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
    handlePackageSummary(packageName,adultCount,childCount,infantCount) {
        this.orderSummaryPackageAll = this.orderSummaryPackage = packageName
        .filter(wrapper => wrapper.packageFamily == this.currentPackage && wrapper.priceTag != undefined) // Filter the existing Package
        .map(wrapper => {
            // Create an array of records based on the number of adults
            const records = [];
                if (adultCount > 0) { 
                    records.push({
                        name: wrapper.packageName + ' (' + (adultCount)  + ' Adult)', // Copy the 'name' value for adult
                        amount: wrapper.priceTag * (adultCount), // Calculate the amount 
                        totalAmount: wrapper.priceTag * (adultCount),
                        netAmount: wrapper.priceTagBeforeTax * (adultCount),
                        cgstAmount: wrapper.cgst * (adultCount),
                        sgstAmount: wrapper.sgst * (adultCount),
                        igstAmount: wrapper.igst * (adultCount),
                        productId: wrapper.productId,
                        pricebookEntryId: wrapper.pricebookEntryId,
                        unitPrice: wrapper.priceTag,
                        count: (adultCount), // Set the count, potentially modify later based on adults
                        isChild: false,
                        isInfant: false,
                        type: 'Adult',
                        discountValue:0
                    });
                }
                if (childCount > 0) {             
                    records.push({
                        name: wrapper.packageName + ' (' + (childCount) + ' child)', // Copy the 'name' value for child
                        amount: wrapper.childPackageWrapper[wrapper.packageFamily].price * (childCount), // Calculate the amount
                        totalAmount: wrapper.childPackageWrapper[wrapper.packageFamily].price * (childCount),
                        netAmount: wrapper.childPackageWrapper[wrapper.packageFamily].priceTagBeforeTax * (childCount),
                        cgstAmount: wrapper.childPackageWrapper[wrapper.packageFamily].cgst * (childCount),
                        sgstAmount: wrapper.childPackageWrapper[wrapper.packageFamily].sgst * (childCount),
                        igstAmount: wrapper.childPackageWrapper[wrapper.packageFamily].igst * (childCount),
                        productId: wrapper.childPackageWrapper[wrapper.packageFamily].productId,
                        pricebookEntryId: wrapper.childPackageWrapper[wrapper.packageFamily].priceBookEntryId,
                        unitPrice: wrapper.childPackageWrapper[wrapper.packageFamily].price,
                        count: 1, // Set the count, potentially modify later based on children
                        isChild: true,
                        type: 'Child',
                        childCount: (childCount),  //to create child oli records
                        discountValue:0
                    });
                } 
                if (infantCount > 0) {             
                    records.push({
                        name: wrapper.packageName + ' (' + (infantCount) + ' Infant)', // Copy the 'name' value for infant
                        amount: wrapper.infantPackageWrapper[wrapper.packageFamily].price * (infantCount), // Calculate the amount
                        totalAmount: wrapper.infantPackageWrapper[wrapper.packageFamily].price * (infantCount),
                        netAmount: 0,
                        cgstAmount: 0,
                        sgstAmount: 0,
                        igstAmount: 0,
                        productId: wrapper.infantPackageWrapper[wrapper.packageFamily].productId,
                        pricebookEntryId: wrapper.infantPackageWrapper[wrapper.packageFamily].priceBookEntryId,
                        unitPrice: wrapper.infantPackageWrapper[wrapper.packageFamily].price,
                        count: 1, // Set the count, potentially modify later based on children
                        isInfant: true,
                        isChild: false,
                        type: 'Infant',
                        infantCount: (infantCount), //to create infant oli records
                        discountValue:0 
                    });
                }            

            return records; // Return the array of records
        })
        .flat(); // Flatten the array to combine all the records into a single array
        
        if (this.isAll) {
            this.orderSummaryPackageUpgradeAll = [...this.orderSummaryPackageAll, ...this.orderSummaryAddon];
            this.calculateTotalPackageAll();
        } else {
            this.orderSummary = [...this.orderSummaryPackage];
            this.calculateTotalAmount();
        }
        
    }

    calculateTotalAmount() {
        this.totalAmount = this.orderSummary.reduce((sum, currentItem) => {
            return sum + currentItem.totalAmount;
        }, 0);
        this.calculateGst(this.orderSummary);
    }

    calculateTotalAddonAmount() {
        this.totalAddonAmount = this.orderSummaryAddon.reduce((sum, currentItem) => {
            return sum + currentItem.totalAmount;
        }, 0);
        this.calculateGst(this.orderSummaryAddon);
    }

    calculateGst(orderSummary) {
        let totalNetAmount = 0;
        let totalCgstAmount = 0;
        let totalSgstAmount = 0;
        let totalIgstAmount = 0;
        orderSummary.forEach(item => {
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
        } else {
            this.showGst = false;
        }
    }

    // Handle row selection for package upgrade
    handleSelect(event) {
        const index = event.target.dataset.index;  // Get the index of the clicked row
        //this.handleUnselect(event);
        this.selectedRowIndex = index;  // Update selected row
        this.currentPackage = this.filteredPackages[index].packageName;
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
                    netAmount: wrapper.priceTagBeforeTax * this.numberOfAdults,
                    cgstAmount: wrapper.cgst * this.numberOfAdults,
                    sgstAmount: wrapper.sgst * this.numberOfAdults,
                    igstAmount: wrapper.igst * this.numberOfAdults,
                    productId: wrapper.productId,
                    pricebookEntryId: wrapper.pricebookEntryId,
                    unitPrice: wrapper.priceTag,
                    count: this.numberOfAdults, // Set the count, potentially modify later based on adults
                    isChild: false,
                    isInfant: false,
                    discountValue:0 ,
                    type: 'Adult' //to create infant oli records
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
                        isChild: true,
                        childCount: this.numberOfChildren,  //to create child oli records
                        type: 'Child',
                        discountValue:0 
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
                        isInfant: true,
                        isChild: false,
                        infantCount: this.numberOfInfants,  //to create infant oli records,
                        type: 'Infant',
                        discountValue:0 
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
        this.calculateGst(this.orderSummaryPackageUpgrade);
        this.totalPackageUpgradeAmount = this.totalAmount - this.currentTotalPackageAmount;
    }

    //logic for All screen 

    // Handle row selection for package upgrade in all option
    handlePackageSelect(event) {
        const index = event.target.dataset.index;  // Get the index of the clicked row
        //this.handleUnselect(event);
        this.selectedRowIndex = index;  // Update selected row
        this.updatePackageAllButtonLabels(this.selectedRowIndex);
       // this.setOtherAllButtonLabel(this.selectedRowIndex);
        this.selectedPackage = this.filteredPackagesAll[index].packageName;
        this.selectedAmount = this.filteredPackagesAll[index].priceTag;        

        //Store previous state before updating**
        if (this.previousOrderSummaryPackageAll.length === 0 && this.guestRowsAll.length > 0) {
            this.previousOrderSummaryPackageAll = [...this.orderSummaryPackageAll];
        }
        let matchFound = false;
        //Check if any item has `buttonLabel` set to `'Remove'`**
        for (let item of this.filteredPackagesAll) {
            if (item.buttonLabel === 'Remove') {
                matchFound = true;
                break;  // Exit loop once a match is found
            }
        }

        //If no match is found, restore previous state**
        if (!matchFound) {
            this.orderSummaryPackageAll = [...this.previousOrderSummaryPackageAll];
            this.previousOrderSummaryPackageAll = []; // Clear previous state after restoring
            this.orderSummaryPackageUpgradeAll = [...this.orderSummaryPackageAll, ...this.orderSummaryAddon];
            this.selectedPackage = '';
            this.calculateTotalPackageAll();
            return; // Exit early, no need to recalculate
        }
        //continue with the package upgrade
        this.orderSummaryPackageAll = this.filteredPackagesAll
        .filter(wrapper => wrapper.buttonLabel === 'Remove') // Filter condition
        .map(wrapper => {
            const numberOfRecords = this.numberOfAdultsAll > this.numberOfChildrenAll ? this.numberOfAdultsAll : this.numberOfChildrenAll; // or any other condition to determine number of records
            // Create an array of records based on the number of adults
            const records = [];
                records.push({
                    name: wrapper.packageName + ' (' + this.numberOfAdultsAll + ' Adult)', // Copy the 'name' value for adult
                    amount: wrapper.priceTag * this.numberOfAdultsAll, // Calculate the amount 
                    totalAmount: wrapper.priceTag * this.numberOfAdultsAll,
                    netAmount: wrapper.priceTagBeforeTax * this.numberOfAdultsAll,
                    cgstAmount: wrapper.cgst * this.numberOfAdultsAll,
                    sgstAmount: wrapper.sgst * this.numberOfAdultsAll,
                    igstAmount: wrapper.igst * this.numberOfAdultsAll,
                    productId: wrapper.productId,
                    pricebookEntryId: wrapper.pricebookEntryId,
                    unitPrice: wrapper.priceTag,
                    count: this.numberOfAdultsAll, // Set the count, potentially modify later based on adults
                    isChild: false,
                    isInfant: false,
                    type: 'Adult',
                    discountValue:0 
                });
                if (this.numberOfChildrenAll > 0) {             
                    records.push({
                        name: wrapper.packageName + ' (' + this.numberOfChildrenAll + ' child)', // Copy the 'name' value for child
                        amount: wrapper.childPackageWrapper[wrapper.packageFamily].price * this.numberOfChildrenAll, // Calculate the amount
                        totalAmount: wrapper.childPackageWrapper[wrapper.packageFamily].price * this.numberOfChildrenAll,
                        netAmount: wrapper.childPackageWrapper[wrapper.packageFamily].priceTagBeforeTax * this.numberOfChildrenAll,
                        cgstAmount: wrapper.childPackageWrapper[wrapper.packageFamily].cgst * this.numberOfChildrenAll,
                        sgstAmount: wrapper.childPackageWrapper[wrapper.packageFamily].sgst * this.numberOfChildrenAll,
                        igstAmount: wrapper.childPackageWrapper[wrapper.packageFamily].igst * this.numberOfChildrenAll,
                        productId: wrapper.childPackageWrapper[wrapper.packageFamily].productId,
                        pricebookEntryId: wrapper.childPackageWrapper[wrapper.packageFamily].priceBookEntryId,
                        unitPrice: wrapper.childPackageWrapper[wrapper.packageFamily].price,
                        count: 1, // Set the count, potentially modify later based on children
                        isChild: true,
                        discountValue:0,
                        type: 'Child',
                        childCount: this.numberOfChildrenAll  //to create child oli records
                    });
                } 
                if (this.numberOfInfantsAll > 0) {             
                    records.push({
                        name: wrapper.packageName + ' (' + this.numberOfInfantsAll + ' Infant)', // Copy the 'name' value for infant
                        amount: wrapper.infantPackageWrapper[wrapper.packageFamily].price * this.numberOfInfantsAll, // Calculate the amount
                        totalAmount: wrapper.infantPackageWrapper[wrapper.packageFamily].price * this.numberOfInfantsAll,
                        netAmount: 0,
                        cgstAmount: 0,
                        sgstAmount: 0,
                        igstAmount: 0,
                        productId: wrapper.infantPackageWrapper[wrapper.packageFamily].productId,
                        pricebookEntryId: wrapper.infantPackageWrapper[wrapper.packageFamily].priceBookEntryId,
                        unitPrice: wrapper.infantPackageWrapper[wrapper.packageFamily].price,
                        count: 1, // Set the count, potentially modify later based on children
                        isInfant: true,
                        isChild: false,
                        type: 'Infant',
                        discountValue:0,
                        infantCount: this.numberOfInfantsAll  //to create infant oli records
                    });
                }            

            return records; // Return the array of records
        })
        .flat(); // Flatten the array to combine all the records into a single array
        this.orderSummaryPackageUpgradeAll = [...this.orderSummaryPackageAll, ...this.orderSummaryAddon];
        this.calculateTotalPackageAll();
        
    }
    /*
    //Method to show the order summary on adding passengers from all section
    handlePackageSummary() {
        this.orderSummaryPackage = this.getPackage
        .filter(wrapper => wrapper.packageFamily == this.currentPackage && wrapper.priceTag != undefined) // Filter the existing Package
        .map(wrapper => {
            // Create an array of records based on the number of adults
            const records = [];
                if (this.numberOfAdultsAll > 0) { 
                    records.push({
                        name: wrapper.packageName + ' (' + (this.numberOfAdultsAll)  + ' Adult)', // Copy the 'name' value for adult
                        amount: wrapper.priceTag * (this.numberOfAdultsAll), // Calculate the amount 
                        totalAmount: wrapper.priceTag * (this.numberOfAdultsAll),
                        netAmount: wrapper.priceTagBeforeTax * (this.numberOfAdultsAll),
                        cgstAmount: wrapper.cgst * (this.numberOfAdultsAll),
                        sgstAmount: wrapper.sgst * (this.numberOfAdultsAll),
                        igstAmount: wrapper.igst * (this.numberOfAdultsAll),
                        productId: wrapper.productId,
                        pricebookEntryId: wrapper.pricebookEntryId,
                        unitPrice: wrapper.priceTag,
                        count: (this.numberOfAdultsAll), // Set the count, potentially modify later based on adults
                        isChild: false,
                        isInfant: false,
                        discountValue:0
                    });
                }
                if (this.numberOfChildrenAll > 0) {             
                    records.push({
                        name: wrapper.packageName + ' (' + (this.numberOfChildrenAll) + ' child)', // Copy the 'name' value for child
                        amount: wrapper.childPackageWrapper[wrapper.packageFamily].price * (this.numberOfChildrenAll), // Calculate the amount
                        totalAmount: wrapper.childPackageWrapper[wrapper.packageFamily].price * (this.numberOfChildrenAll),
                        netAmount: wrapper.priceTagBeforeTax * (this.numberOfChildrenAll),
                        cgstAmount: wrapper.cgst * (this.numberOfChildrenAll),
                        sgstAmount: wrapper.sgst * (this.numberOfChildrenAll),
                        igstAmount: wrapper.igst * (this.numberOfChildrenAll),
                        productId: wrapper.productId,
                        pricebookEntryId: wrapper.childPackageWrapper[wrapper.packageFamily].priceBookEntryId,
                        unitPrice: wrapper.childPackageWrapper[wrapper.packageFamily].price,
                        count: 1, // Set the count, potentially modify later based on children
                        isChild: true,
                        childCount: (this.numberOfChildrenAll),  //to create child oli records
                        discountValue:0
                    });
                } 
                if (this.numberOfInfantsAll > 0) {             
                    records.push({
                        name: wrapper.packageName + ' (' + (this.numberOfInfantsAll) + ' Infant)', // Copy the 'name' value for infant
                        amount: wrapper.infantPackageWrapper[wrapper.packageFamily].price * (this.numberOfInfantsAll), // Calculate the amount
                        totalAmount: wrapper.infantPackageWrapper[wrapper.packageFamily].price * (this.numberOfInfantsAll),
                        netAmount: 0,
                        cgstAmount: 0,
                        sgstAmount: 0,
                        igstAmount: 0,
                        productId: wrapper.productId,
                        pricebookEntryId: wrapper.infantPackageWrapper[wrapper.packageFamily].priceBookEntryId,
                        unitPrice: wrapper.infantPackageWrapper[wrapper.packageFamily].price,
                        count: 1, // Set the count, potentially modify later based on children
                        isInfant: true,
                        isChild: false,
                        infantCount: (this.numberOfInfantsAll), //to create infant oli records
                        discountValue:0 
                    });
                }            

            return records; // Return the array of records
        })
        .flat(); // Flatten the array to combine all the records into a single array
        this.orderSummary = [...this.orderSummaryPackage];
        this.orderSummaryPackageUpgradeAll = [...this.orderSummaryPackageAll, ...this.orderSummaryAddon, ...this.orderSummaryPackage];
            this.calculateTotalPackageAll();
        
    }*/

    updatePackageAllButtonLabels(ind) {
        const boxElement = this.template.querySelector('.box');
        this.filteredPackagesAll = this.filteredPackagesAll.map((wrapper, index) => {
            return {
                ...wrapper, // Keep existing properties
                buttonLabel: ind == index ? wrapper.buttonLabel == 'Select' ? 'Remove' : 'Select' : 'Select'
            };
        });
    }

    
    /*
    setOtherAllButtonLabel(ind) {
        let buttonLabel = 'buttonLabel';
        // Loop through the array and update only the selected index
        this.filteredPackagesAll.forEach((item, index) => {
            if (index === ind) {
                item[buttonLabel] = 'Remove';
            } else {
                item[buttonLabel] = 'Select'; // Reset all other buttons
            }
        });
    }*/

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

    calculateTotalPackageAll() {
        this.totalAmountAll = this.orderSummaryPackageUpgradeAll.reduce((sum, currentItem) => {
            return sum + currentItem.totalAmount;
        }, 0);
        this.calculateGst(this.orderSummaryPackageUpgradeAll);
        this.totalExtraAmountAll = this.totalAmountAll - this.currentTotalPackageAmount;
        if (this.totalAmountAll > this.currentTotalPackageAmount) {
            this.showPaidAmount = true;
        }
        else{
            this.showPaidAmount = false;
        }
    }

    resetValuesOnTabChanges(){
        this.orderSummaryPackageUpgrade=[];
        this.orderSummaryPackageUpgradeAll = [];
        this.previousOrderSummaryPackageAll =[];
        this.orderSummaryAddon = [];
        this.totalAddonAmount = 0;
        this.totalExtraAmountAll = 0;
        this.totalAmount = 0;
        this.guestRowsAll = [];
        this.showGst = false;
        this.showCgst =false;
        this.showIgst =false;
        this.showPaidAmount = false;
        this.totalNetAmount = 0;
        this.totalCgstAmount = 0;
        this.totalSgstAmount = 0;
        this.totalIgstAmount = 0;
    }
    handlePassengerInformation() {
        if (this.validateAllSelection()) {
            this.isAll = false;
            this.openPassengerPage = true;
        } else {            
            this.showToast('Error', 'Please make an amendment to proceed!', 'error');
        }
    }
    validateAllSelection() {
        //check for package selection
        let matchFound = false;
        let buttonLabel = 'buttonLabel';
        for (let item of this.filteredPackagesAll) {
            // Check if the package is selected
            if (item[buttonLabel] == 'Remove') {
                matchFound = true;
                break;  // Exit loop after finding the match
            }
        }
        //check for addon selection
        let addOnmatchFound = false;
        let addOnbuttonLabel = 'buttonLabel';
        for (let item of this.getAddonDetail) {
            // Check if the addon is selected
            if (item[addOnbuttonLabel] == 'Remove') {
                addOnmatchFound = true;
                break;  // Exit loop after finding the match
            }
        }
        //validate if any option is selected
        if (this.guestRowsAll.length < 1 && !matchFound && !addOnmatchFound) {
            return false;
        } else {
            return true;
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

    validatePassengersDataAll() {
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
            return true;
        } else {
            return false;
        }
    }

    openUpgradeAllPage() {
        this.openPassengerPage = false;
        this.isAll = true;
        this.isPaxAll = true;
    }

    OpenPassengerInfo() {
        this.isPaxAll = false;
        if (this.guestRowsAll.length > 0)  {   
            //get the current package
            const adultCount = this.numberOfAdultsAll - this.numberOfAdults;
            const childCount = this.numberOfChildrenAll - this.numberOfChildren;
            const infantCount = this.numberOfInfantsAll - this.numberOfInfants;
            this.handlePackageSummary(this.getPackage,adultCount,childCount,infantCount)  ;       
            this.openPassengerPage = true;
        } else {
            this.orderSummaryPackageUpgradeAll = [];
            this.showGst = false;
            this.totalAmountAll = 0;
            this.isPckUpgradeAll = true;
        }
    }

    returnToPassengerCount() {
        this.openPassengerPage = false;
        this.isPaxAll = true;
    }

    openPackageUpgrade() {        
        if (this.guestRowsAll.length > 0)  { 
            var errorMessage = 'Please resolve all the required checks.'
            if(this.validatePassengersDataAll()) {
                this.openPassengerPage=false;
                this.isPckUpgradeAll = true;
            } else {
                this.showToast('Error', errorMessage, 'error');
            }
        } else {            
            this.openPassengerPage=false;
            this.isPckUpgradeAll = true;
        }
    }

    returnToPassengerDetail() {
        this.isPckUpgradeAll=false;
        if (this.guestRowsAll.length > 0)  { 
            this.openPassengerPage = true;
        } else {
            this.isPaxAll = true;
        }
    }

    openAddonPage() {
        this.isPckUpgradeAll=false;
        this.isAddOnAll = true;
    }

    returnToPackageUpgrade() {
        this.isAddOnAll = false;
        this.isPckUpgradeAll = true;
    }

    openSubmitConfirmation() {
        if (this.validateAllSelection()) {
            //this.openPassengerPage = true;
            this.openConfirmationPopup();  
            this.confirmAmendment = true;
        } else {            
            this.showToast('Error', 'Please make an amendment to proceed!', 'error');
        }
    }

    generatePdf() {
        // Call Apex method to generate and save PDF with the current record
        generateAndSavePDF({ recordId: this.recordId})
            .then((result) => {
                this.showToast('Success', 'Booking Voucher updated successfully', 'success');
                this.dispatchEvent(new RefreshEvent());
				this.handleSendEmail();
            })
            .catch((error) => {
                this.showToast('Error', 'Error while generating Voucher', 'error');
                console.error(error);
                this.isLoading= false;
            });
    }
    
    handleSendEmail() {
        sendEmailWithAttachment({ opportunityId: this.recordId, actionType: 'Modified/Rescheduled' })
            .then(() => {
                this.showToast('Success', 'Email sent successfully!', 'success');
                this.isLoading= false;
                // Dispatch an event to close the LWC component
                this.dispatchEvent(new CloseActionScreenEvent());
                this.handleCloseComponent();
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
                this.isLoading= false;
            });
    }
    handleCloseComponent() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view'
            }
        });
    }

}