import { LightningElement, track } from 'lwc';
import searchAccounts from '@salesforce/apex/AccountController.searchAccounts';

export default class EncalmHomeScreen extends LightningElement {
    @track searchKey = '';
    @track accounts;
    @track suggestions;
    @track noResults;
    @track error;
    
    columns = [
        { label: 'Account Name', fieldName: 'Name' },
        { label: 'Phone', fieldName: 'Phone' },
        { label: 'Email', fieldName: 'PersonEmail' }
    ];
    
    handleSearchKeyChange(event) {
        this.searchKey = event.target.value;
        if (this.searchKey.length >= 2) {
            this.getSuggestions();
        } else {
            this.suggestions = [];
            this.accounts = undefined;
        }
    }
    
    async getSuggestions() {
        try {
            const result = await searchAccounts({ searchKey: this.searchKey });
            this.suggestions = result.length ? result : [];
            this.noResults = result.length === 0;
        } catch (error) {
            this.error = error.body.message;
            this.suggestions = [];
        }
    }

    selectAccount(event) {
        const accountId = event.target.dataset.id;
        this.searchKey = event.target.innerText.split(' - ')[0];
        this.accounts = this.suggestions.filter(account => account.Id === accountId);
        this.suggestions = [];
    }
}