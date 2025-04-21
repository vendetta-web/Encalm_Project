import { LightningElement, api } from 'lwc';
import assignCaseToOperationSPOC from '@salesforce/apex/CaseAssignmentQuickActionController.assignCaseToOperationSPOC';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class CaseAssignmentQuickAction extends LightningElement {
    @api recordId;

    connectedCallback() {

        assignCaseToOperationSPOC({ caseId: this.recordId})
            .then(result => {
                this.showToast('Success', result, 'success');
                this.closeAction();
            })
            .catch(error => {
                const message = error.body?.message || 'Unknown error';
                this.showToast('Error', message, 'error');
                this.closeAction();
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }

    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}