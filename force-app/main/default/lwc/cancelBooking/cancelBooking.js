import { LightningElement, api, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import getpassengerDetails from '@salesforce/apex/CancellationPolicyService.getBookingToCancel';
import cancelledSummaryPreview from '@salesforce/apex/CancellationPolicyService.showCancellationCharges';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

const COLUMNS = [
    {
        label: 'Name',
        fieldName: 'name',
        type: 'text',
        minWidth: 200,  // Set minimum width for the column
        typeAttributes: {
            name: 'select', // This name is used for the checkbox
            disabled: false,  // Allow the checkbox to be enabled
        }
    },
    {
        label: 'Package Name',
        fieldName: 'packageName',
        type: 'text',
        minWidth: 100,  // Set minimum width for the column
    },
    {
        label: 'Unit Price',
        fieldName: 'unitPrice',
        type: 'currency',
        minWidth: 100,  // Set minimum width for the column
    },
    {
        label: 'Quantity',
        fieldName: 'quantity',
        type: 'number',
        minWidth: 100,  // Set minimum width for the column
    }, {
        label: 'Type',
        fieldName: 'type',
        type: 'text',
        minWidth: 100,  // Set minimum width for the column
    },

];

export default class CancelBooking extends NavigationMixin(LightningElement) {
    @api recordId; // Record ID for the Opportunity page
    isLoading = false;
    isModalOpen = true;
    showNoBooking=false;
    selectedRows = [];
    showMultipleCancelScreen = false;
    confirmDelete = false;
    showSummary = false;
    selectedLineItems = [];  // Stores selected line item IDs
    lineItems = [];  // Data for the table
    columns = COLUMNS;
    isLoading = false;  // Indicates loading state
    totalAmount;
    selectedPassengers = 0;
    selectedPackage;
    cancellationOrder;
    noBookingFound='';
    cancelOptions = [
        { label: 'Full Cancel', value: 'fullCancel' },
        { label: 'Partial Cancel', value: 'partialCancel' }
    ];
    selectedCancelOption = ''; // Store the selected cancel option

    closeModal() {
        this.isModalOpen = false;
        // Dispatch an event to close the LWC component
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    handlePrevious() {
        this.showMultipleCancelScreen = false;
        this.isModalOpen = true;
    }
    handleSelection() {
        this.showSummary = false;
        if (this.selectedCancelOption == 'partialCancel') {
            this.showMultipleCancelScreen = true;            
            this.selectedPassengers = 0; //reset passenger selection
        } else {
            this.isModalOpen = true;
        }
    }

    handleCancelOptionChange(event) {
        this.selectedCancelOption = event.detail.value;
    }

    handleNext() {
        if (this.selectedCancelOption == ''){
            this.showToast('Error', 'Please select a cancel type', 'error');
        } else {
            if (this.selectedCancelOption == 'partialCancel') {
                this.isModalOpen = false;
                this.showMultipleCancelScreen = true;
                this.selectedPassengers = 0;    
            } else {
                this.isLoading = true;
                this.isModalOpen = false;
                this.showSummary = true;
                this.handleBookingCancellation();
            }
        }
    }

    // Wire the Apex method to get Opportunity Line Items
    @wire(getpassengerDetails, { opportunityId: '$recordId' })
    wiredOpportunityLineItems({ error, data }) {
        if (data) {
            this.isLoading = false;  // Data fetched, stop loading
            if(data.length>0) {                
                this.lineItems = data
                .map(pd => ({
                    id: pd.id,
                    oliId: pd.oliId,
                    name: pd.name,
                    packageName: pd.packageName,
                    unitPrice: pd.unitPrice,
                    quantity: pd.quantity,
                    type: pd.type,
                    pbenteryId: pd.pbenteryId
                }));
                // Check data length and modify options accordingly
            if (data.length < 2) {
                this.cancelOptions = this.cancelOptions.filter(option => option.value !== 'partialCancel');
            }
            } else {
                this.showNoBooking = true;
            }
        } else if (error) {
            this.isLoading = false;  // Stop loading even if there's an error
            console.error('Error fetching line items', error);
        }
    }
    // Handle checkbox selection
    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        this.selectedRows = selectedRows.map(pd => ({
                id: pd.id,
                oliId: pd.oliId,
                name: pd.name,
                packageName: pd.packageName,
                unitPrice: pd.unitPrice,
                quantity: pd.quantity,
                type: pd.type,
                pbenteryId: pd.pbenteryId
        }));
        // Convert Proxy objects to regular objects and capture theeach row unitPrice
        this.selectedLineItems = selectedRows.map(row => row.unitPrice);
        this.selectedPassengers = selectedRows.length;
        // Now, calculate the total of selected amounts
        const totalAmount = this.selectedLineItems.reduce((acc, amount) => acc + amount, 0);
        this.totalAmount = totalAmount;
        if (selectedRows.length > 0) {
            this.selectedPackage = selectedRows[0].packageName;  // Just picking the first package (or change to any other logic)
        }
    }

    handleCancellation() {
        //final submit
        cancelledSummaryPreview({ 
            cancelType: this.selectedCancelOption,
            selectedOrders: this.selectedRows,
            bookingAmount: this.totalAmount,
            packageName: this.selectedPackage,
            opportunityId: this.recordId,
            numberOfPax: this.selectedPassengers,
            submit: true})
            .then(result => {
                this.cancellationOrder = result;
                
            })
            .catch(error => {
                console.error('Apex Error:', error);
        });
        
        this.showToast('Success', 'Booking cancelled successfully!', 'success');
        // Redirect to Opportunity record
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Opportunity',
                actionName: 'view',
            },
        });
    }


    handleBookingCancellation() {
        if(this.selectedCancelOption == 'partialCancel' && this.selectedPassengers<1) {
            this.showToast('Error', 'Please select a booking to cancel', 'error');
        } else {// Call Apex method to process the selected options
            cancelledSummaryPreview({ 
                cancelType: this.selectedCancelOption,
                selectedOrders: this.selectedRows,
                bookingAmount: this.totalAmount,
                packageName: this.selectedPackage,
                opportunityId: this.recordId,
                numberOfPax: this.selectedPassengers,
                submit: false })
                .then(result => {
                    this.cancellationOrder = result;
                    if (this.cancellationOrder == null) {
                        this.noBookingFound = 'No booking available for cancellation';
                    } else {
                        this.noBookingFound = '';
                    }
                    this.showMultipleCancelScreen = false;
                    this.showSummary = true;
                    this.isLoading = false;
                })
                .catch(error => {
                    console.error('Apex Error:', error);
                    this.isLoading = false;
            });
        }
        
    }

    closePopupModal() {
        this.confirmDelete = false;
    }

    openModal() {
        this.confirmDelete = true;
    }

    handleFinalCancel() {
        this.confirmDelete = false;
        this.showSummary = false;
        this.handleCancellation();
        this.closeModal();
    }
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant,
        });
        this.dispatchEvent(event);
    }
}