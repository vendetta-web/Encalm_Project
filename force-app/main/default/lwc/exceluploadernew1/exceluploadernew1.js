import { LightningElement } from 'lwc';
import SHEETJS from '@salesforce/resourceUrl/SheetJS';
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import processAccountData from '@salesforce/apex/ExcelUploaderController.processAccountData';

export default class Exceluploadernew1 extends LightningElement {
    fileData;
    sheetjsInitialized = false;

    renderedCallback() {
        if (this.sheetjsInitialized) {
            return;
        }
        this.sheetjsInitialized = true;

        loadScript(this, SHEETJS + '/xlsx.full.min.js')
            .then(() => {
                console.log('SheetJS library loaded');
            })
            .catch(error => {
                this.showToast('Error', 'Error loading SheetJS library', 'error');
            });
    }

    handleFileUpload(event) {
        const uploadedFiles = event.detail.files;
        const file = uploadedFiles[0];

        if (file) {
            this.fileData = {
                filename: file.name,
                documentId: file.documentId
            };
        }
    }

    processFile() {
        if (this.fileData) {
            fetch(`/sfc/servlet.shepherd/document/download/${this.fileData.documentId}`)
                .then(response => response.arrayBuffer())
                .then(arrayBuffer => {
                    const data = new Uint8Array(arrayBuffer);
                    const workbook = XLSX.read(data, { type: 'array' });
                    const firstSheetName = workbook.SheetNames[0];
                    const worksheet = workbook.Sheets[firstSheetName];
                    const jsonData = XLSX.utils.sheet_to_json(worksheet);

                    // Prepare the data for Account creation
                    const accountData = jsonData.map(row => {
                        return {
                            Name: row['Account Name'],       // Assuming 'Account Name' is a column in the Excel file
                            Phone: row['Phone'],             // Assuming 'Phone' is a column in the Excel file
                            Website: row['Website'],         // Assuming 'Website' is a column in the Excel file
                            Industry: row['Industry'],       // Assuming 'Industry' is a column in the Excel file
                        };
                    });

                    // Send the data to Apex to process it
                    this.sendDataToApex(accountData);
                })
                .catch(error => {
                    this.showToast('Error', 'Error processing Excel file', 'error');
                });
        }
    }

    sendDataToApex(accountData) {
        processAccountData({ accountList: accountData })
            .then(result => {
                this.showToast('Success', 'Accounts processed successfully', 'success');
            })
            .catch(error => {
                this.showToast('Error', 'Error processing accounts', 'error');
            });
    }

    showToast(title, message, variant) {
        const toastEvent = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(toastEvent);
    }
}