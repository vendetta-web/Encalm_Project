import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import importCSVFile from '@salesforce/apex/FlightDetailsDataImportController.importCSVFile';

export default class FlightDetailsDataImport extends LightningElement {
    @track fileData;
    @track fileName;
    @track airportCode;
    @track disableButton = true;
    
    handleFileChange(event) {
        const file = event.target.files[0];
        let fileName = file.name;
        let fileNameWithoutExtension = fileName.split('.')[0];  // Remove the file extension (.csv)
        this.airportCode = fileNameWithoutExtension.slice(-3);  // Extract last 3 characters (assuming it's always 3 letters)
        this.disableButton = true;

        if(file.type != 'text/csv'){
            this.showToast('Error', 'Please upload the csv file', 'error');
        }
        /*else if(this.airportCode != 'HYD' && this.airportCode != 'DEL' && this.airportCode != 'GOI' && this.airportCode != 'GOX'){
            this.showToast('Error', 'File Name should end with airport code', 'error');           
        }*/
        else{
            let reader = new FileReader();
            reader.onload = () => {
                let csv = reader.result;
                this.fileData = csv;
                this.showToast('Success', fileName + ' uploaded successfully! Please click on import button.', 'success');
            };
            reader.readAsText(file);
            this.disableButton = false;
        }
    }

    handleImport() {
        if (this.fileData) {
            
            //importCSVFile({ csvString: this.fileData, airportCodeFromFileName:  this.airportCode})
            importCSVFile({ csvString: this.fileData})
                .then(result => {
                    this.showToast('Success', 'File processed successfully', 'success');
                })
                .catch(error => {
                    this.showToast('Error', error.body.message, 'error');
                });
            this.disableButton = true;
        } 
        else {
            this.showToast('Error', 'Please select a file first', 'error');
            this.disableButton = true;
        }

    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(event);
    }
}