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
        if (searchTerm.length > 0) {
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
        this.hasResults = false;

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
        setTimeout(() => {
        const recordEditForm = this.template.querySelector('lightning-record-edit-form');
        recordEditForm.recordTypeId = this.recordTypeId;
        },0);
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
const phoneValue = phoneField ? phoneField.value : null;
    const emailField = this.template.querySelector('lightning-input-field[data-field-name="PersonEmail"]');
    const emailValue = emailField ? emailField.value : null;
    
    let isValid = true;

    // Validate phone field for Business account
 if (this.accountType === 'Business' && !phoneValue) {
    console.log('ERRRRRRRRRRRR');
       this.showError = true;
        isValid = false;
    }
    if (this.accountType === 'Personal' && !phoneValue && !emailValue) {
    console.log('ERRRRRRRRRRRR');
       this.showError = true;
        isValid = false;
    }

    // Only submit if all validations pass
    if (isValid) {
        const recordEditForm = this.template.querySelector('lightning-record-edit-form');
        recordEditForm.submit();
    }
}

    handleSuccess(event) {
        console.log('Testtttttttttttttt');
        const accountId = event.detail.id;
       const nameField = this.template.querySelector('lightning-input-field[data-field-name="Name"]').value;
        console.log('Newly created Account Id',accountId);
        console.log('Newly created Account Id',nameField);
      this.selectedAccount = { Id: accountId, Name:nameField};
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