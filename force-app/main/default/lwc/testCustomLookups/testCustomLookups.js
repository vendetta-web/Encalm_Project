import { LightningElement, track } from 'lwc';
import getAccounts from '@salesforce/apex/AccountController.getAccounts';
import getRecordTypeIds from '@salesforce/apex/AccountController.getRecordTypeIds';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class TestCustomLookups extends LightningElement {
    @track accountName = '';
    @track accountPhone = '';
    @track searchResults = [];
    @track noSearchResult = false;
    @track hasResults = false;
    @track selectedAccount = {};
    @track isOpenModal = false;
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
                this.businessRecordTypeId = result.Business;
                this.personalRecordTypeId = result.Personal;
            })
            .catch((error) => {
                console.error('Error fetching record type IDs:', error);
            });
    }

    handleSearchInput(event) {
        const searchTerm = event.target.value;
        if (!searchTerm) {
            this.searchResults = [];
            this.hasResults = false;
            this.noSearchResult = false;
            return;
        }
        if (searchTerm.length > 2) {
            this.selectedAccount = {};
            getAccounts({ searchTerm })
                .then((result) => {
                    this.searchResults = result.map(account => ({
                        ...account,
                        Phone: account.Phone || 'No Phone',
                        PersonEmail: account.PersonEmail || 'No Email'
                    }));
                    //  this.hasResults = this.searchResults.length > 0;
                    if (this.searchResults.length > 0) {
                        this.hasResults = true;
                        this.noSearchResult = false;
                    } else {
                        console.log('Okay');
                        this.noSearchResult = true;
                    }
                })
                .catch((error) => {
                    console.error('Error searching accounts:', error);
                    this.searchResults = [];
                    this.hasResults = false;
                });
        } else {
            this.searchResults = [];
            this.hasResults = false;
        }
    }

    handleSelect(event) {
        const accountId = event.currentTarget.dataset.id;
        this.selectedAccount = this.searchResults.find(account => account.Id === accountId);
        this.accountName = this.selectedAccount.Name || '';
        this.accountPhone = this.selectedAccount.Phone || '';
        this.hasResults = false;

        this.dispatchEvent(new CustomEvent('accountselect', {
            detail: this.selectedAccount
        }));
    }

    openModal() {
        this.isOpenModal = true;
        // Ensure values are set to avoid reset issues
        this.accountName = this.accountName || (this.selectedAccount.Name || '');
        this.accountPhone = this.accountPhone || (this.selectedAccount.Phone || '');
    }

    closeModal() {
        this.isOpenModal = false;
    }

    handleAccountTypeChange(event) {
        this.selectedAccountType = event.detail.value;
        this.accountType = this.selectedAccountType;

        // Set recordTypeId based on account type
        if (this.accountType === 'Business') {
            this.recordTypeId = this.businessRecordTypeId;
        } else if (this.accountType === 'Personal') {
            this.recordTypeId = this.personalRecordTypeId;
        }

        // Assign tracked values to ensure synchronization
        this.accountName = this.accountName || (this.selectedAccount.Name || '');
        this.accountPhone = this.accountPhone || (this.selectedAccount.Phone || '');

        console.log('Selected Account Type:', this.accountType);
        console.log('RecordTypeId set to:', this.recordTypeId);
    }

    handleNameChange(event) {
        this.accountName = event.target.value;
    }

    handlePhoneChange(event) {
        this.accountPhone = event.target.value;
    }


    get isBusinessAccount() {
        return this.accountType === 'Business';
    }

    get isPersonalAccount() {
        return this.accountType === 'Personal';
    }

    validateAndSave() {
        console.log('accountType', this.accountType);
        const phoneField = this.template.querySelector('lightning-input-field[data-field-name="Phone"]');
        const emailField = this.template.querySelector('lightning-input-field[data-field-name="PersonEmail"]');

        const phoneValue = phoneField ? phoneField.value : null;
        const emailValue = emailField ? emailField.value : null;
        if (!phoneValue && !emailValue && this.accountType === 'Personal') {
            this.showErrorToast('Please provide either a phone number or an email address before saving for a Person account.');
        } else if (this.accountType === 'Business' && !phoneValue) {
            this.showErrorToast('Please provide a phone number for a Bussiness account.');
        }
        else {
            const recordEditForm = this.template.querySelector('lightning-record-edit-form');
            recordEditForm.submit();
        }
    }
    showErrorToast(message) {
        const event = new ShowToastEvent({
            title: 'Error',
            message: message,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }

    handleSuccess(event) {
        const accountId = event.detail.id;
        const nameField = this.template.querySelector('lightning-input-field[data-field-name="Name"]').value;
        console.log('Newly created Account Id', accountId);
        console.log('Newly created Account Id', nameField);
        this.selectedAccount = { Id: accountId, Name: nameField };
        this.dispatchEvent(new ShowToastEvent({
            title: 'Success',
            message: 'Account created successfully!',
            variant: 'success'
        }));
        this.noSearchResult = false;
        this.hasResults = false;
        this.closeModal();

    }

    handleError(event) {
        console.error('Error creating account:', event.detail);
    }
}