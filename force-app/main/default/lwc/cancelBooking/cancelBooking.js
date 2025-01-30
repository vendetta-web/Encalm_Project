import { LightningElement, api, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import getpassengerDetails from '@salesforce/apex/CancellationPolicyService.getBookingToCancel';
import cancelledSummaryPreview from '@salesforce/apex/CancellationPolicyService.showCancellationCharges';

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
    },{
        label: 'Type',
        fieldName: 'type',
        type: 'text',
        minWidth: 100,  // Set minimum width for the column
    },
    
];

export default class CancelBooking extends LightningElement {
    @api recordId; // Record ID for the Opportunity page
    isModalOpen = true;
    showMultipleCancelScreen = false;
    selectedLineItems = [];  // Stores selected line item IDs
    lineItems = [];  // Data for the table
    columns = COLUMNS;
    isLoading = true;  // Indicates loading state
    totalAmount;
    selectedPassengers;
    selectedPackage;
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
    handlePrevious(){
        this.showMultipleCancelScreen = false;
        this.isModalOpen = true;
    }

    handleCancelOptionChange(event) {
        this.selectedCancelOption = event.detail.value;
    }

    handleNext() {
        if (this.selectedCancelOption) {
            console.log(`Order will be cancelled with option: ${this.selectedCancelOption}`);
            this.isModalOpen = false;
            this.showMultipleCancelScreen = true;
            
        } else {
            console.log('Please select a cancel option');
        }
    }

    // Wire the Apex method to get Opportunity Line Items
    @wire(getpassengerDetails, { opportunityId: '$recordId' })
    wiredOpportunityLineItems({ error, data }) {
        if (data) {
            this.isLoading = false;  // Data fetched, stop loading
            this.lineItems = data.map(pd => ({
                id: pd.id,
                oliId: pd.oliId,
                name: pd.name,
                packageName: pd.packageName,
                unitPrice: pd.unitPrice,
                quantity: pd.quantity,
                type: pd.type
            }));
        } else if (error) {
            this.isLoading = false;  // Stop loading even if there's an error
            console.error('Error fetching line items', error);
        }
    }
    // Handle checkbox selection
     handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
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
    

    handleBookingCancellation() {
        // Call Apex method to process the selected options
        
        cancelledSummaryPreview({ bookingAmount: this.totalAmount, packageName: this.selectedPackage, opportunityId: this.recordId, numberOfPax:  this.totalAmount})
            .then(result => {
                console.log('Apex Response:', JSON.stringify(result));
            })
            .catch(error => {
                console.error('Apex Error:', error);
            });
    }
}