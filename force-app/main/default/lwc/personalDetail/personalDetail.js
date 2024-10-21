import { LightningElement, track } from 'lwc';
import searchAccounts from '@salesforce/apex/AccountController.searchAccounts';

export default class PersonalDetail extends LightningElement {
    @track searchKey = '';
    @track suggestions;
    @track noResults;
    @track selectedAccountId;
    @track isEditing = false; 

    suggestionColumns = [
        { label: 'Account Name', fieldName: 'Name', type: 'text' },
        { label: 'Phone', fieldName: 'Phone', type: 'text' },
        { label: 'Email', fieldName: 'PersonEmail', type: 'email' },
        {
            label: 'Action',
            type: 'button',
            typeAttributes: {
                label: 'Book',
                name: 'Book',
                variant: 'brand',
                title: 'Select Account',
                disabled: false 
            }
        }
    ];

    handleSearchKeyChange(event) {
        this.searchKey = event.target.value;
        if (this.searchKey.length >= 2) {
            this.getSuggestions();
        } else {
            this.suggestions = [];
            this.noResults = false;
        }
    }

    async getSuggestions() {
        try {
            const result = await searchAccounts({ searchKey: this.searchKey });
            this.suggestions = result.length ? result : [];
            this.noResults = result.length === 0;
        } catch (error) {
            console.error('Error fetching accounts:', error);
        }
    }

    selectAccount(event) {
        const actionName = event.detail.action.name;
        const accountId = event.detail.row.Id;

        if (actionName === 'Book') {
            this.selectedAccountId = accountId;
            this.isEditing = true;  
        }
    }

    handleCancel() {
        this.isEditing = false;  
    }

    handleSuccess(event) {
        this.isEditing = false; 
        const recordId = event.detail.id;
        console.log('Account saved with ID:', recordId);
    }
}