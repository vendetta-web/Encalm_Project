import { LightningElement, api, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPackageDetails from '@salesforce/apex/PackageSelectionController.getPackages';
import getAddOnDetails from '@salesforce/apex/PackageSelectionController.getAddons';
import getOpportunityDetails from '@salesforce/apex/PackageSelectionController.getOpportunityDetails';
import createOpportunityLineItems from '@salesforce/apex/PackageSelectionController.createOpportunityLineItems';
import savePassengerDetails from '@salesforce/apex/PackageSelectionController.savePassengerDetails';
import createContentVersion from '@salesforce/apex/MDEN_PdfAttachmentController.createContentVersion';
import getTerminalInfo from '@salesforce/apex/PackageSelectionController.getTerminalInfo';
import jsPDFLibrary from '@salesforce/resourceUrl/jsPDFLibrary';
import { loadScript } from 'lightning/platformResourceLoader';
import { RefreshEvent } from 'lightning/refresh';

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
    terminalOptions = [];
    totalAmount=0;
    @track oliFieldValues = {};
    serviceAirport;
    flightNumber;
    flightDate;


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
        this.loadPassengerData();
    }
    getTerminals() {
        getTerminalInfo({oppId: this.recordId})
          .then(result => {
                this.terminalOptions = result.map(each => ({
                label: each.Code__c,
                value: each.Code__c
            }));
            })
            .catch(error => {
                console.error('Error fetching terminals:', error);
                
            });
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
            this.getTerminals();
            this.getAddonDetail = result; 
            this.getAddonDetail = result.map((item) => ({
                ...item, // Spread the existing properties
                buttonLabel: 'Select', // Add buttonLabel to each item
                adddOnCount: this.adddOnCount,
                class: 'btns select',
                pickupTerminal: '',
                dropTerminal: '',
                pickupDataId: `${item.addOnName}-pickup`,  // Unique data-id for pickup terminal,
                dropDataId: `${item.addOnName}-drop`,  // Unique data-id for drop terminal
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
            console.log('wrapper--> '+JSON.stringify(wrapper));
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
                    amount: wrapper.parentTochildPrice[wrapper.pricebookId] * this.numberOfChildren, // Calculate the amount
                    totalAmount: wrapper.parentTochildPrice[wrapper.pricebookId] * this.numberOfChildren,
                    productId: wrapper.productId,
                    pricebookEntryId: wrapper.parentTochildPricebookEntryId[wrapper.pricebookId],
                    unitPrice: wrapper.parentTochildPrice[wrapper.pricebookId],
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
                    count: wrapper.adddOnCount,
                    pickup: wrapper.pickup,
                    drop: wrapper.drop
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

    loadPassengerData() {
        getOpportunityDetails({opportunityId: this.recordId})
        .then((result) => {
            this.serviceAirport = result.serviceAirport;
            this.flightNumber = result.flightNumber;
            this.flightDate = result.flightDate;
            this.numberOfAdults = result.NoOfAdult; 
            this.numberOfChildren = result.NoOfChild;
            this.numberOfInfants = result.NoOfInfant;

            this.guestRows = []; 
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
                firstname: '',
                lastname: '',
                gender: '',
                age: null,
                designation: '',
                travelclass: '',
                travelpnrno: ''
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
    }

    //to get field values to save in opp record
    handleFieldChange(event) {
        const fieldName = event.target.name;
        const fieldValue = event.target.value;

        this.opportunityFieldValues[fieldName] = fieldValue;
    }

     // Handle the Save action
     handleSave() {
        savePassengerDetails({ passengerData: this.guestRows, opportunityId: this.recordId })
            .then(() => {
                // Handle success
                //this.showToast('Success', 'Passenger details saved successfully!', 'success');
                this.showPreview = true;
                this.passengerDetailPage = false;

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
        this.passengerDetailPage = true;
        this.showPreview = false;
    }
    //generate PDF file
    generatePdf() {
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
                    this.showToast('Success', 'PDF has been attached successfully', 'success');
                    this.dispatchEvent(new RefreshEvent());
                })
                .catch((error) => {
                    this.showToast('Error', 'Error while attaching PDF', 'error');
                    console.error(error);
                });
        } else {
            console.error('jsPDF library not initialised');
        }
        this.isLoading = false;
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