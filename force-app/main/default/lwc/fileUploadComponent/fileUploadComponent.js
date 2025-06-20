import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';

export default class FileUploadComponent extends LightningElement {
    @track files = [];
    @track selectedFiles = [];
    @track hasFiles = false;

    acceptedFormats = ['.pdf', '.png', '.jpg', '.jpeg'];

    @api recordId; // Flow provides this
    // Output for file IDs (comma-separated string)
    _contentDocumentIds = '';
    @api
    set contentDocumentIds(val) {
        this._contentDocumentIds = val;
        //this.dispatchEvent(new FlowAttributeChangeEvent('contentDocumentIds', val));
    }

    get contentDocumentIds() {
        return this._contentDocumentIds;
    }
    columns = [
        { label: 'Title', fieldName: 'title' },
        { label: 'Created Date', fieldName: 'createdDate', type: 'date' },
        {
        type: 'button-icon',
        fixedWidth: 40,
        typeAttributes: {
            iconName: 'utility:delete',
            name: 'delete',
            title: 'Delete',
            variant: 'border-filled',
            alternativeText: 'Delete'
        }
    }
    ];

    handleUploadFinished(event) {
    const uploadedFiles = event.detail.files;

    if (uploadedFiles.length > 0) {
        const newFiles = uploadedFiles.map(file => ({
            id: file.documentId,
            title: file.name,
            createdDate: new Date().toISOString()
        }));

        // Update internal file list
        this.files = [...this.files, ...newFiles];
        this.hasFiles = this.files.length > 0;

        // Filter out any undefined or empty IDs before joining
        const validIds = this.files.map(file => file.id).filter(id => id); // Removes empty values
        this.contentDocumentIds = validIds.join(','); // Convert to string for Flow

        console.log('Updated file list:', JSON.stringify(this.files, null, 2));
        console.log('Valid ContentDocumentIds:', this.contentDocumentIds);

        this.showToast('Success', 'Files uploaded successfully', 'success');
    }
}


    handleSelection(event) {
        const selectedRows = event.detail.selectedRows;
        this.selectedFiles = selectedRows.map(row => row.id);
    }

    handleRemoveFiles() {
        this.files = this.files.filter(file => !this.selectedFiles.includes(file.id));
        this.selectedFiles = [];
        this.hasFiles = this.files.length > 0;
        this.showToast('Success', 'Selected files removed successfully', 'success');
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const rowId = event.detail.row.id;

        if (actionName === 'delete') {
            this.files = this.files.filter(file => file.id !== rowId);
            this.selectedFiles = this.selectedFiles.filter(id => id !== rowId);
            this.hasFiles = this.files.length > 0;
            const validIds = this.files.map(file => file.id).filter(id => id);
            this.contentDocumentIds = validIds.join(',');
            this.showToast('Success', 'File deleted successfully', 'success');
        }
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
}