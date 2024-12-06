import { LightningElement, track } from 'lwc';
import getAccounts from '@salesforce/apex/AccountController.getAccounts';
import getRecordTypeIds from '@salesforce/apex/AccountController.getRecordTypeIds';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class TestCustomLookups extends LightningElement {
    @track searchResults = [];
    @track noSearchResult = false;
    @track hasResults = false;
    @track selectedAccount = {};
    @track isOpenModal = false;
    @track showError = false;
    @track selectedAccountType = '';
    @track accountTypeOptions = [
        { label: 'Business Account', value: 'Business' },
        { label: 'Personal Account', value: 'Personal' }
    ];
    @track accountType = '';
    recordTypeId;
    businessRecordTypeId;
    personalRecordTypeId;

    connectedCallback() {
        getRecordTypeIds()
            .then((result) => {
                console.log('Record Type IDs:', result);
                // Check if record types are returned and set defaults if not
                this.businessRecordTypeId = result?.Business || null;
                this.personalRecordTypeId = result?.Personal || null;
                if (!this.businessRecordTypeId || !this.personalRecordTypeId) {
                    console.error('Record Type IDs are missing or incorrect');
                }
            })
            .catch((error) => {
                console.error('Error fetching record type IDs:', error);
            });
    }

    handleSearchInput(event) {
        const searchTerm = event.target.value?.trim();
        if (!searchTerm) {
            this.searchResults = [];
            this.hasResults = false;
            this.noSearchResult = false;
            return;
        }

        getAccounts({ searchTerm })
            .then((result) => {
                this.searchResults = result.map(account => ({
                    ...account,
                    Phone: account.Phone || 'No Phone',
                    PersonEmail: account.PersonEmail || 'No Email'
                }));

                // Handle search result state
                if (this.searchResults.length > 0) {
                    this.hasResults = true;
                    this.noSearchResult = false;
                } else {
                    this.noSearchResult = true;
                }
            })
            .catch((error) => {
                console.error('Error searching accounts:', error);
                this.searchResults = [];
                this.hasResults = false;
                this.noSearchResult = false;
            });
    }

    handleSelect(event) {
        const accountId = event.currentTarget.dataset.id;
        this.selectedAccount = this.searchResults.find(account => account.Id === accountId);
        this.hasResults = false;

        // Dispatch the selected account details
        this.dispatchEvent(new CustomEvent('accountselect', {
            detail: this.selectedAccount
        }));
    }

    openModal() {
        this.isOpenModal = true;
    }

    closeModal() {
        this.isOpenModal = false;
        this.showError = false;
    }

    handleAccountTypeChange(event) {
        this.selectedAccountType = event.detail.value;
        this.accountType = this.selectedAccountType;
        
        if (this.accountType === 'Business') {
            this.recordTypeId = this.businessRecordTypeId;
        } else if (this.accountType === 'Personal') {
            this.recordTypeId = this.personalRecordTypeId;
        }

        // Set record type dynamically
        setTimeout(() => {
            const recordEditForm = this.template.querySelector('lightning-record-edit-form');
            if (recordEditForm) {
                recordEditForm.recordTypeId = this.recordTypeId;
            }
        }, 0);
        
        console.log('Selected Account Type:', this.accountType);
        console.log('RecordTypeId set to:', this.recordTypeId);
    }

    get isBusinessAccount() {
        return this.accountType === 'Business';
    }

    get isPersonalAccount() {
        return this.accountType === 'Personal';
    }

    validateAndSave() {
        const phoneField = this.template.querySelector('lightning-input-field[data-field-name="Phone"]');
        const phoneValue = phoneField?.value || null;
        const emailField = this.template.querySelector('lightning-input-field[data-field-name="PersonEmail"]');
        const emailValue = emailField?.value || null;

        let isValid = true;

        // Validation for Business account
        if (this.accountType === 'Business' && !phoneValue) {
            console.log('ERRRRRRRRRRRR');
            this.showError = true;
            isValid = false;
        }

        // Validation for Personal account (either phone or email is required)
        if (this.accountType === 'Personal' && !phoneValue && !emailValue) {
            console.log('ERRRRRRRRRRRR');
            this.showError = true;
            isValid = false;
        }

        // Only submit if validation passes
        if (isValid) {
            const recordEditForm = this.template.querySelector('lightning-record-edit-form');
            if (recordEditForm) {
                recordEditForm.submit();
            }
        }
    }

    handleSuccess(event) {
        console.log('Account created successfully');
        const accountId = event.detail.id;
        const nameField = this.template.querySelector('lightning-input-field[data-field-name="Name"]')?.value;
        console.log('Newly created Account Id:', accountId);
        console.log('Newly created Account Name:', nameField);

        this.selectedAccount = { Id: accountId, Name: nameField };

        // Display success message
        this.dispatchEvent(new ShowToastEvent({
            title: 'Success',
            message: 'Account created successfully!',
            variant: 'success'
        }));

        // Reset states
        this.noSearchResult = false;
        this.hasResults = false;
        this.closeModal();
    }

    handleError(event) {
        console.error('Error creating account:', event.detail);
    }
}