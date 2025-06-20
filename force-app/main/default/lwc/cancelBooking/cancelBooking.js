import { LightningElement, api, wire,track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import getpassengerDetails from '@salesforce/apex/CancellationPolicyService.getBookingToCancel';
import cancelledSummaryPreview from '@salesforce/apex/CancellationPolicyService.showCancellationCharges';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import sendEmailWithAttachment from '@salesforce/apex/BookingEmailHandler.sendEmailWithAttachment';
import generateAndSavePDF from '@salesforce/apex/MDEN_PdfAttachmentController.generateAndSavePDF';
import createRefundRequest from '@salesforce/apex/RefundRequestController.createRefundRequest';
//import generateCancelledTaxInvoice from '@salesforce/apex/TaxInvoiceController.generateCancelledTaxInvoice';
import { RefreshEvent } from 'lightning/refresh';
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
    isModalOpen = true;
    showNoBooking=false;
    selectedRows = [];
    showMultipleCancelScreen = false;
    confirmDelete = false;
    showSummary = false;
    selectedLineItems = [];  // Stores selected line item IDs
    lineItems = [];  // Data for the table
    @track remainingItems = [];
    @track allowCancellation = false;
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
    @track actionType = '';
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
                this.actionType = 'Partially Cancelled'  
            } else {
                this.isLoading = true;
                this.isModalOpen = false;
                this.showSummary = true;
                this.allowCancellation = true;
                this.actionType = 'Cancel';
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
        const selectedIds = selectedRows.map(row => row.id);
        this.remainingItems  = this.lineItems.filter(item => !selectedIds.includes(item.id));
        console.log('Remaining Items:------->', this.remainingItems);

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
                this.showToast('Success', 'Booking cancelled successfully!', 'success');               
                console.log('175>>>');
                this.cancellationOrder = result;
                this.generatePdf();
                console.log('179>>>');
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: this.recordId,
                        objectApiName: 'Opportunity',
                        actionName: 'view',
                    },
        }, true);
                this.isLoading = false;             
            })
            .catch(error => {
                console.error('Apex Error:', error);
                this.isLoading = false;
        });
        
        //this.showToast('Success', 'Booking cancelled successfully!', 'success');
        // Redirect to Opportunity record
        /*this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Opportunity',
                actionName: 'view',
            },
        }, true);*/
    }
    generatePdf() {
        debugger;
        // Call Apex method to generate and save PDF with the current record
        generateAndSavePDF({ recordId: this.recordId})
            .then((result) => {
                this.showToast('Success', 'Booking Voucher updated successfully', 'success');
                this.dispatchEvent(new RefreshEvent());
				this.handleSendEmail();
            })
            .catch((error) => {
                this.showToast('Error', error.body.message, 'error');
                this.isLoading = false;
            });

            // Call Apex method to insert Refund Request(order request) records for cancelled lineItems
        createRefundRequest({ oppId: this.recordId})
            .then((result) => {
                this.showToast('Success', 'Refund Request Initiated successfully', 'success');
                this.dispatchEvent(new RefreshEvent());
            })
            .catch((error) => {
                this.showToast('Error', error.body.message, 'error');
                this.isLoading = false;
            });
        // Call Apex method to generate Cancellation TaxInvoice with the current opp record
        /*    generateCancelledTaxInvoice({ recordId: this.recordId})
            .then((result) => {
               // this.showToast('Success', 'Tax Invoice', 'success');
                })
            .catch((error) => {
                this.showToast('Error', error.body.message, 'error');
                this.isLoading = false;
            });*/
    }
    handleSendEmail() {
        sendEmailWithAttachment({ opportunityId: this.recordId, actionType: this.actionType, paymentURL: ''})//'Modified/Rescheduled'  })
            .then(() => {
                this.showToast('Success', 'Email sent successfully!', 'success');
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
                this.isLoading = false;
            });
    }

    handleBookingCancellation() {
        if(this.selectedCancelOption == 'partialCancel' && this.selectedPassengers<1) {
            this.showToast('Error', 'Please select a booking to cancel', 'error');
        } else {
            
            console.log('Remaining Items:', JSON.stringify(this.remainingItems));
            if(this.selectedCancelOption == 'partialCancel'){
                this.allowCancellation = Array.isArray(this.remainingItems) &&  this.remainingItems.some(item => item.type === 'Adult');
            }
            if(this.allowCancellation){
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
            }else{
                this.showToast('Error', 'Atleast One Adult be There', 'error');
                this.isLoading = false;
            }
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